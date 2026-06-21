#!/usr/bin/env python3
# horizons_trajectory.py
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield
# I, Voyager is a registered trademark of Charlie Whitfield in the US
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *****************************************************************************
"""Generate patched-conic trajectory table rows for ivoyager from JPL HORIZONS.

HORIZONS (NASA/JPL Solar System Dynamics) is the authoritative source; it serves
the official reconstructed-trajectory SPICE SPK kernels (NASA NAIF) as osculating
Keplerian elements about any chosen primary. See the "Spacecraft Trajectory &
Ephemeris Data" section of the project CLAUDE.md for source rationale and the
field mapping.

Continuity strategy (so the patched-conic joins meet, not just approximate):

  * FLYBY segments are ANCHORS: their conic is HORIZONS osculating elements
    sampled at closest approach, where a single planet-centric conic best fits.
  * CRUISE segments are FITTED: each is the conic through its two boundary points
    in the segment's time of flight (a Lambert solve about the Sun, see orbital.py).
    Interior boundary points are the adjacent flyby conics' endpoints; the open
    ends (launch, escape) anchor to the real HORIZONS heliocentric position.

  IVTrajectory draws each segment in its primary's frame (a flyby point is
  `flyby_conic(t) + the sim's planet position at t`). So a cruise must target the
  flyby endpoint computed with the SIM's planet position, not HORIZONS'. We query
  the running sim for those planet positions (and the bodies' GMs) so the joins
  coincide to float precision in the drawn frame. Results are cached in
  SIM_CACHE; pass --refresh to re-query (e.g. after editing planet orbits).

Segmentation is HAND-MAINTAINED: CRAFT[<name>]["segments"] is the ordered conic
list (primary, [begin, end] window, sample epoch). Boundaries are approximate
sphere-of-influence crossings, refined after viewing in-sim.

Usage:
    python horizons_trajectory.py voyager_1            # dry run (prints rows)
    python horizons_trajectory.py voyager_1 --write    # upsert into the tables
"""

import argparse
import json
import math
import pathlib
import re
import sys
import time
import urllib.request
from datetime import datetime, timedelta, timezone

from orbital import elements_to_state, lambert, state_to_elements

HORIZONS_API = "https://ssd.jpl.nasa.gov/api/horizons.api"
J2000_JD = 2451545.0       # Julian Day at J2000 (= internal sim time 0)
DAY_SECONDS = 86400.0
YEAR_SECONDS = 365.25 * DAY_SECONDS
KM_PER_AU = 1.495978707e8
ESCAPE_LAMBERT_YEARS = 5.0  # far-point baseline for the open escape cruise's Lambert

# Reuse the assistant plugin's launcher + TCP client (its tools dir isn't a package).
ASSISTANT_TOOLS = (pathlib.Path(__file__).resolve().parent.parent
                   / "addons" / "ivoyager_assistant" / "tools")
SIM_CACHE = pathlib.Path(__file__).resolve().parent / ".sim_data_cache.json"

# HORIZONS CENTER code -> ivoyager parent body name (orbits.tsv 'parent' column).
# "@10" (the Sun) marks a heliocentric cruise; any other center marks a flyby.
CENTER_BODY = {
    "@10": "STAR_SUN",
    "@399": "PLANET_EARTH",
    "@599": "PLANET_JUPITER",
    "@699": "PLANET_SATURN",
    "@799": "PLANET_URANUS",
    "@899": "PLANET_NEPTUNE",
}

# orbits.tsv column order (index 0 is the unnamed entity-name column).
ORBIT_COLUMNS = [
    "name", "parent", "epoch_jd", "reference_plane_type",
    "orbit_right_ascension", "orbit_declination",
    "eccentricity", "inclination", "longitude_ascending_node", "argument_periapsis",
    "semi_major_axis", "semi_parameter", "mean_anomaly_at_epoch", "time_periapsis",
    "mean_motion", "orbit_gravitational_parameter",
    "longitude_ascending_node_rate", "argument_periapsis_rate",
    "#nodal_period", "#apsidal_period", "real_planet_orbit",
    "semi_major_axis_rate", "eccentricity_rate", "inclination_rate",
    "mean_anomaly_correction_b", "mean_anomaly_correction_c",
    "mean_anomaly_correction_s", "mean_anomaly_correction_f",
    "validity_begin", "validity_end", "segment_begin", "segment_end",
]

# spacecrafts.tsv column order. Index 0 ("name") is the unnamed entity-name
# column; "spacecraft" is a separate BOOL field (data column 1), NOT the entity.
SPACECRAFT_COLUMNS = [
    "name", "spacecraft", "use_pitch_yaw", "lazy_model", "sleep", "file_prefix",
    "en.wikipedia", "hud_name", "symbol", "show_in_nav_panel", "parent",
    "orbit", "body_class", "model_type", "tidally_locked", "axis_locked",
    "#rotation_period", "right_ascension", "declination", "gravitational_parameter",
    "mean_radius", "mean_density", "magnitude", "albedo", "trajectory",
]

# trajectories.tsv column order (index 0 is the unnamed entity-name column).
TRAJECTORY_COLUMNS = ["name", "orbits", "begin_orbit", "end_orbit", "end_remove"]

# Tables live in the ivoyager_core submodule, two levels up from this script.
TABLES_DIR = (pathlib.Path(__file__).resolve().parent.parent
              / "addons" / "ivoyager_core" / "tables")

# First-field values that mark a non-data (header/meta) line in an ivoyager table.
META_FIRST_FIELDS = {"", "Type", "Default", "Unit"}

# ----------------------------------------------------------------------------
# Hand-maintained segment config.
#
# Each segment is (suffix, center, begin_date, end_date, sample_date):
#   suffix       appended to "SEG_<CRAFT>_" to name the orbits.tsv row.
#   center       HORIZONS CENTER code (key of CENTER_BODY) = the segment primary;
#                "@10" (Sun) is a cruise leg, anything else is a flyby leg.
#   begin/end    segment validity window ('YYYY-MM-DD'); the first segment's begin
#                is launch, the last segment's end is the chosen horizon.
#   sample       flyby: closest-approach epoch to anchor the conic. (Unused for
#                cruise legs, which are fitted by Lambert -- left at the CA-ish date.)
#
# Flyby window bounds are approximate sphere-of-influence crossings -- seeded by
# hand from the known encounter dates and refined after viewing in-sim.
# ----------------------------------------------------------------------------
CRAFT = {
    "voyager_1": {
        "command": "-31",
        "segments": [
            ("CRUISE_1", "@10",  "1977-09-05", "1979-02-20", "1978-06-01"),
            ("JUPITER",  "@599", "1979-02-20", "1979-03-20", "1979-03-05"),
            ("CRUISE_2", "@10",  "1979-03-20", "1980-10-28", "1980-01-01"),
            ("SATURN",   "@699", "1980-10-28", "1980-11-27", "1980-11-12"),
            ("CRUISE_3", "@10",  "1980-11-27", "2100-01-01", "1990-01-01"),
        ],
        # spacecrafts.tsv registration (non-default fields only). No Voyager .glb
        # asset yet -> file_prefix falls back gracefully; add a model + hud_name later.
        "spacecraft_row": {
            "name": "VOYAGER_1",
            "sleep": "FALSE",
            "file_prefix": "Voyager",
            "en.wikipedia": "Voyager_1",
            "show_in_nav_panel": "x",
            "parent": "STAR_SUN",
            "orbit": "SEG_VOYAGER_1_CRUISE_1",
            "mean_radius": "5",          # meters; IVBody requires > 0 (model/HUD scale)
            "trajectory": "VOYAGER_1",
        },
        # Placeholder spacecraft rows to drop now that real data exists.
        "retire_spacecraft": ["TEST_PROBE_EARTH_MOON", "TEST_PROBE_INTERPLANETARY"],
    },
}


# *****************************************************************************
# time / vector helpers


def gregorian_to_jd(year, month, day, hour=0, minute=0, second=0.0):
    """Julian Day from a proleptic-Gregorian calendar date (uniform days; no
    leap-second / TT-UTC correction, which is sub-minute and irrelevant here)."""
    a = (14 - month) // 12
    y = year + 4800 - a
    m = month + 12 * a - 3
    jdn = day + (153 * m + 2) // 5 + 365 * y + y // 4 - y // 100 + y // 400 - 32045
    return jdn + (hour - 12) / 24.0 + minute / 1440.0 + second / DAY_SECONDS


def date_to_jd(date_str):
    parts = [int(x) for x in date_str.split("-")]
    return gregorian_to_jd(parts[0], parts[1], parts[2])


def jd_to_sim_seconds(jd):
    """Internal sim time: Terrestrial Time, J2000 epoch, in seconds."""
    return (jd - J2000_JD) * DAY_SECONDS


def sim_seconds_to_date(seconds):
    """Sim seconds -> 'YYYY-MM-DD' (Fliegel-Van Flandern), for HORIZONS queries."""
    jdn = int(math.floor(J2000_JD + seconds / DAY_SECONDS + 0.5))
    l = jdn + 68569
    n = (4 * l) // 146097
    l -= (146097 * n + 3) // 4
    year = (4000 * (l + 1)) // 1461001
    l += 31 - (1461 * year) // 4
    month = (80 * l) // 2447
    day = l - (2447 * month) // 80
    l = month // 11
    month += 2 - 12 * l
    year = 100 * (n - 49) + year + l
    return f"{year:04d}-{month:02d}-{day:02d}"


def _add(a, b): return (a[0] + b[0], a[1] + b[1], a[2] + b[2])
def _sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def _norm(a): return math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])


# *****************************************************************************
# HORIZONS queries


def _horizons(params):
    url = HORIZONS_API + "?" + "&".join(f"{k}={v}" for k, v in params)
    with urllib.request.urlopen(url, timeout=60) as response:
        return response.read().decode("utf-8")


def _ephem_window(date):
    """A 2-day window starting at [date] with a 1-day step (we take record 0)."""
    stop = (datetime.fromisoformat(date).replace(tzinfo=timezone.utc)
            + timedelta(days=2)).strftime("%Y-%m-%d")
    return [("START_TIME", f"'{date}'"), ("STOP_TIME", f"'{stop}'"), ("STEP_SIZE", "'1d'")]


def query_elements(command, center, date):
    """Raw HORIZONS ELEMENTS text for one epoch (the record at [date])."""
    return _horizons([
        ("format", "text"), ("COMMAND", f"'{command}'"), ("OBJ_DATA", "'NO'"),
        ("MAKE_EPHEM", "'YES'"), ("EPHEM_TYPE", "'ELEMENTS'"), ("CENTER", f"'{center}'"),
        ("REF_PLANE", "'ECLIPTIC'"), ("REF_SYSTEM", "'ICRF'"), ("OUT_UNITS", "'KM-S'"),
    ] + _ephem_window(date))


def query_helio_position(command, seconds):
    """Heliocentric position (km, ecliptic-J2000) of [command] at sim time [seconds],
    via HORIZONS VECTORS about the Sun. Used for cruise open-end anchors."""
    text = _horizons([
        ("format", "text"), ("COMMAND", f"'{command}'"), ("OBJ_DATA", "'NO'"),
        ("MAKE_EPHEM", "'YES'"), ("EPHEM_TYPE", "'VECTORS'"), ("CENTER", "'@10'"),
        ("REF_PLANE", "'ECLIPTIC'"), ("REF_SYSTEM", "'ICRF'"), ("VEC_TABLE", "'1'"),
        ("OUT_UNITS", "'KM-S'"),
    ] + _ephem_window(sim_seconds_to_date(seconds)))
    start, end = text.find("$$SOE"), text.find("$$EOE")
    if start == -1 or end == -1:
        raise RuntimeError("No $$SOE/$$EOE in VECTORS response:\n" + text[-1500:])
    block = text[start:end]
    axis = [float(re.search(rf"{c}\s*=\s*([-+0-9.Ee]+)", block).group(1)) for c in "XYZ"]
    return tuple(axis)


def parse_first_element_record(text):
    """Parse the first element record. Returns {EC, QR, IN, OM, W, Tp, ...} floats."""
    start, end = text.find("$$SOE"), text.find("$$EOE")
    if start == -1 or end == -1:
        raise RuntimeError("No $$SOE/$$EOE data block in HORIZONS response:\n"
                           + text[-1500:])
    block = text[start + len("$$SOE"):end].strip()
    record_lines = []
    epoch_headers = 0
    for line in block.splitlines():
        if re.match(r"^\s*\d{7,}\.\d+\s*=", line):
            epoch_headers += 1
            if epoch_headers == 2:
                break
        record_lines.append(line)
    record = "\n".join(record_lines)
    fields = {}
    for match in re.finditer(r"\b([A-Za-z]{1,2})\s*=\s*([-+0-9.Ee]+)", record):
        fields[match.group(1)] = float(match.group(2))
    return fields


def horizons_to_internal(fields):
    """HORIZONS ELEMENTS fields -> internal Keplerian elements (km, radians, s)."""
    e = fields["EC"]
    return {
        "p": fields["QR"] * (1.0 + e),            # semi-parameter = periapsis*(1+e), km
        "e": e,
        "inc": math.radians(fields["IN"]),
        "lan": math.radians(fields["OM"]),
        "argp": math.radians(fields["W"]),
        "time_periapsis": jd_to_sim_seconds(fields["Tp"]),
    }


# *****************************************************************************
# sim data (the sim's own GMs + planet positions, for exact drawn-frame continuity)


def _pos_key(body, seconds):
    return f"{body}|{seconds!r}"


def get_sim_data(gm_bodies, pos_queries, godot, project, refresh=False):
    """Return {'gm': {body: km^3/s^2}, 'pos': {(body, t): (x,y,z) km}}.

    Reads the running sim's own body GMs and positions (so cruise endpoints match
    the flyby endpoints as actually drawn). Cached in SIM_CACHE; only launches
    Godot for keys not already cached (or all keys when [refresh])."""
    cache = {"gm": {}, "pos": {}}
    if SIM_CACHE.exists() and not refresh:
        cache.update(json.loads(SIM_CACHE.read_text(encoding="utf-8")))
    missing_gm = [b for b in gm_bodies if b not in cache["gm"]]
    missing_pos = [(b, t) for (b, t) in pos_queries if _pos_key(b, t) not in cache["pos"]]

    if missing_gm or missing_pos:
        sys.path.insert(0, str(ASSISTANT_TOOLS))
        from assistant_test import AssistantClient, GodotLauncher
        print(f"# querying sim: {len(missing_gm)} GM, {len(missing_pos)} positions "
              f"(launching {pathlib.Path(godot).name})...")
        launcher = GodotLauncher(godot, project)
        launcher.start()
        client = AssistantClient()
        try:
            client.connect()
            for _ in range(60):
                if "result" in client.call("list_bodies", {"filter": "all"}):
                    break
                time.sleep(1.0)
            for body in missing_gm:
                result = client.call("get_body_info", {"name": body})["result"]
                cache["gm"][body] = result["gravitational_parameter"]
            for body, seconds in missing_pos:
                result = client.call("get_body_position",
                                     {"name": body, "time": seconds})["result"]
                cache["pos"][_pos_key(body, seconds)] = result["position"]
        finally:
            try:
                client.call("quit", {"force": True})
            except Exception:
                pass
            client.close()
            launcher.shutdown_and_report()
        SIM_CACHE.write_text(json.dumps(cache, indent=2), encoding="utf-8")

    return {
        "gm": {b: cache["gm"][b] for b in gm_bodies},
        "pos": {(b, t): tuple(cache["pos"][_pos_key(b, t)]) for (b, t) in pos_queries},
    }


# *****************************************************************************
# trajectory assembly


def _state_position(internal, gm, t):
    return elements_to_state(internal["p"], internal["e"], internal["inc"],
                             internal["lan"], internal["argp"],
                             internal["time_periapsis"], gm, t)[0]


def internal_to_cols(name, parent, internal, segment_begin, segment_end):
    """Internal elements -> orbits.tsv columns. Open-conic form (semi_parameter +
    time_periapsis) is valid for any eccentricity; the builder mods elliptic ones."""
    return {
        "name": name,
        "parent": parent,
        "eccentricity": internal["e"],
        "inclination": math.degrees(internal["inc"]),
        "longitude_ascending_node": math.degrees(internal["lan"]) % 360.0,
        "argument_periapsis": math.degrees(internal["argp"]) % 360.0,
        "semi_parameter": internal["p"],
        "time_periapsis": internal["time_periapsis"],
        "segment_begin": segment_begin,
        "segment_end": segment_end,
    }


def generate(config, craft_name, godot, project, refresh=False):
    """Build all segment conics; return (orbit_cols, segment_names)."""
    command = config["command"]
    prefix = "SEG_" + craft_name.upper() + "_"

    # Per-segment scaffold; anchor each flyby on HORIZONS osculating elements at CA.
    segments = []
    for suffix, center, begin, end, sample in config["segments"]:
        seg = {
            "suffix": suffix, "parent": CENTER_BODY[center],
            "t_begin": jd_to_sim_seconds(date_to_jd(begin)),
            "t_end": jd_to_sim_seconds(date_to_jd(end)),
            "is_flyby": center != "@10",
        }
        if seg["is_flyby"]:
            seg["internal"] = horizons_to_internal(
                parse_first_element_record(query_elements(command, center, sample)))
        segments.append(seg)

    # Sim's GMs (Sun + each flyby primary) and each flyby primary's position at the
    # flyby boundary times -- needed to express flyby endpoints heliocentrically.
    gm_bodies = {"STAR_SUN"} | {s["parent"] for s in segments if s["is_flyby"]}
    pos_queries = [(s["parent"], t) for s in segments if s["is_flyby"]
                   for t in (s["t_begin"], s["t_end"])]
    sim = get_sim_data(gm_bodies, pos_queries, godot, project, refresh)
    gm_sun = sim["gm"]["STAR_SUN"]

    # Flyby endpoints in heliocentric coordinates = planet-relative conic + sim planet.
    for seg in segments:
        if seg["is_flyby"]:
            gm_planet = sim["gm"][seg["parent"]]
            seg["entry_helio"] = _add(_state_position(seg["internal"], gm_planet, seg["t_begin"]),
                                      sim["pos"][(seg["parent"], seg["t_begin"])])
            seg["exit_helio"] = _add(_state_position(seg["internal"], gm_planet, seg["t_end"]),
                                     sim["pos"][(seg["parent"], seg["t_end"])])

    # Cruise legs: the heliocentric conic through both boundary points (Lambert),
    # anchored to the adjacent flyby endpoints at the shared boundary times. Each
    # endpoint carries its own time; the conic is valid across the whole segment.
    for index, seg in enumerate(segments):
        if seg["is_flyby"]:
            continue
        if index > 0:                           # join the previous flyby's exit
            start_pos, t_start = segments[index - 1]["exit_helio"], seg["t_begin"]
        else:                                   # launch: a day in (no pre-launch ephemeris)
            t_start = seg["t_begin"] + DAY_SECONDS
            start_pos = query_helio_position(command, t_start)
        if index < len(segments) - 1:           # join the next flyby's entry
            end_pos, t_target = segments[index + 1]["entry_helio"], seg["t_end"]
        else:                                   # open escape: fit a near-future real point
            t_target = seg["t_begin"] + ESCAPE_LAMBERT_YEARS * YEAR_SECONDS
            end_pos = query_helio_position(command, t_target)
        velocity, _ = lambert(start_pos, end_pos, t_target - t_start, gm_sun)
        seg["internal"] = state_to_elements(start_pos, velocity, gm_sun, t_start)

    orbit_cols, segment_names = [], []
    print(f"# {craft_name}  (HORIZONS COMMAND='{command}')")
    print(f"# {'segment':<24}{'primary':<15}{'e':>9}{'incl':>9}{'periapsis(AU)':>15}")
    for seg in segments:
        name = prefix + seg["suffix"]
        cols = internal_to_cols(name, seg["parent"], seg["internal"],
                                seg["t_begin"], seg["t_end"])
        orbit_cols.append(cols)
        segment_names.append(name)
        periapsis_au = seg["internal"]["p"] / (1.0 + seg["internal"]["e"]) / KM_PER_AU
        kind = "" if seg["is_flyby"] else "  (lambert)"
        print(f"# {name:<24}{seg['parent']:<15}{seg['internal']['e']:>9.4f}"
              f"{math.degrees(seg['internal']['inc']):>9.3f}{periapsis_au:>15.4f}{kind}")
    return orbit_cols, segment_names


# *****************************************************************************
# TSV output


def fmt(value):
    if isinstance(value, float):
        return f"{value:.12g}"
    return str(value)


def build_tsv(columns, cols):
    return "\t".join(fmt(cols.get(column, "")) for column in columns)


def _is_data_line(line):
    if not line.strip():
        return False
    first = line.split("\t", 1)[0]
    if first.startswith("#") or first.startswith("Prefix/"):
        return False
    return first not in META_FIRST_FIELDS


def upsert_table(path, rows, remove_names=()):
    """Insert-or-replace data rows in an ivoyager TSV, preserving everything else.

    rows is a list of (name, tab_row); a row replaces an existing data line with
    the same entity name (column 0) or is appended after the last data line (so
    it lands before any trailing comment/blank lines). Names in remove_names are
    deleted. Idempotent. Returns (replaced, appended, removed) name lists."""
    raw = path.read_text(encoding="utf-8", newline="")     # newline="" -> no EOL translation
    newline = "\r\n" if "\r\n" in raw else "\n"
    lines = raw.split(newline)

    # Guard against column misalignment: a new row must have the same field count
    # as the existing data rows, or a silent off-by-one corrupts the whole table.
    counts = [line.count("\t") + 1 for line in lines if _is_data_line(line)]
    if counts:
        expected = max(set(counts), key=counts.count)
        for name, row in rows:
            actual = row.count("\t") + 1
            if actual != expected:
                raise ValueError(f"{path.name}: row '{name}' has {actual} fields, "
                                 f"expected {expected} (column-list misalignment)")

    new_by_name = dict(rows)
    remove = set(remove_names)
    out = []
    replaced, removed = [], []
    for line in lines:
        if _is_data_line(line):
            name = line.split("\t", 1)[0]
            if name in remove:
                removed.append(name)
                continue
            if name in new_by_name:
                out.append(new_by_name[name])
                replaced.append(name)
                continue
        out.append(line)

    appended = [name for name, _ in rows if name not in replaced]
    if appended:
        insert_at = next((i + 1 for i in range(len(out) - 1, -1, -1)
                          if _is_data_line(out[i])), len(out))
        out[insert_at:insert_at] = [new_by_name[name] for name in appended]

    path.write_text(newline.join(out), encoding="utf-8", newline="")
    return replaced, appended, removed


def main():
    parser = argparse.ArgumentParser(description="Generate ivoyager trajectory table rows from HORIZONS")
    parser.add_argument("craft", nargs="?", default="voyager_1")
    parser.add_argument("--write", action="store_true", help="upsert rows into the tables")
    parser.add_argument("--refresh", action="store_true", help="re-query cached sim data")
    parser.add_argument("--godot", default=None, help="path to the Godot console executable")
    parser.add_argument("--project", default=str(TABLES_DIR.parent.parent.parent))
    args = parser.parse_args()
    if args.craft not in CRAFT:
        sys.exit(f"Unknown craft '{args.craft}'. Known: {', '.join(CRAFT)}")
    config = CRAFT[args.craft]

    godot = args.godot
    if godot is None:
        sys.path.insert(0, str(ASSISTANT_TOOLS))
        from orbit_accuracy_test import find_godot_executable
        godot = find_godot_executable(args.project)
        if not godot:
            sys.exit("No Godot console executable found; pass --godot PATH")

    orbit_cols, segment_names = generate(config, args.craft, godot, args.project, args.refresh)

    orbit_rows = [(cols["name"], build_tsv(ORBIT_COLUMNS, cols)) for cols in orbit_cols]
    traj_name = args.craft.upper()
    traj_row = (traj_name, build_tsv(TRAJECTORY_COLUMNS,
                {"name": traj_name, "orbits": ";".join(segment_names)}))
    spacecraft = config.get("spacecraft_row")
    spacecraft_row = ((spacecraft["name"], build_tsv(SPACECRAFT_COLUMNS, spacecraft))
                      if spacecraft else None)

    if not args.write:
        print("\n# ---- orbits.tsv rows ----")
        for _, row in orbit_rows:
            print(row)
        print("\n# ---- trajectories.tsv row ----")
        print(traj_row[1])
        if spacecraft_row:
            print("\n# ---- spacecrafts.tsv row ----")
            print(spacecraft_row[1])
        print("\n# (dry run; pass --write to upsert into the tables)")
        return

    def report(filename, result):
        replaced, appended, removed = result
        parts = []
        if appended:
            parts.append(f"+{len(appended)} added")
        if replaced:
            parts.append(f"~{len(replaced)} replaced")
        if removed:
            parts.append(f"-{len(removed)} removed ({', '.join(removed)})")
        print(f"# {filename:<20} {', '.join(parts) or 'no change'}")

    print(f"\n# ---- writing to {TABLES_DIR} ----")
    report("orbits.tsv", upsert_table(TABLES_DIR / "orbits.tsv", orbit_rows))
    report("trajectories.tsv", upsert_table(TABLES_DIR / "trajectories.tsv", [traj_row]))
    if spacecraft_row:
        report("spacecrafts.tsv", upsert_table(TABLES_DIR / "spacecrafts.tsv",
               [spacecraft_row], remove_names=config.get("retire_spacecraft", ())))


if __name__ == "__main__":
    main()
