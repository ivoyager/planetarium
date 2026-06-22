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
    "@999": "PLANET_PLUTO",
}

# Row values are assembled as {column_name: value} dicts (see internal_to_cols and the
# per-craft spacecraft_row); the WRITER reads each table's column order from its header
# at run time (read_table_columns / build_row) -- the same name-based mapping the GDScript
# table reader uses. So a column reorder or insertion in a .tsv needs no change here, and a
# column this script writes that goes missing fails loudly (naming it) instead of silently
# shifting every value into the wrong column. No hardcoded column list to keep in sync.

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
#   begin/end    segment validity window, 'YYYY-MM-DD' or 'YYYY-MM-DDTHH:MM:SS' (see
#                date_to_jd). A bare date pins the boundary to midnight; add a time where
#                day-granularity is too coarse -- a join in a fast planet-moon frame. The
#                first segment's begin is launch day (the emitted segment_begin is
#                overridden to that conic's periapsis, see generate); the last end is the horizon.
#   sample       epoch to sample HORIZONS osculating elements for the conic (closest
#                approach for a flyby; mid-leg for a cruise). Unused for cruise legs
#                under --pre-fix, which Lambert-fits them instead.
#
# Flyby window bounds are approximate sphere-of-influence crossings -- seeded by
# hand from the known encounter dates and refined after viewing in-sim.
# ----------------------------------------------------------------------------
CRAFT = {
    "voyager_1": {
        "command": "-31",
        "segments": [
            ("DEPARTURE", "@399", "1977-09-05", "1977-09-07", "1977-09-06"),
            ("CRUISE_1",  "@10",  "1977-09-07", "1979-02-20", "1978-06-01"),
            ("JUPITER",   "@599", "1979-02-20", "1979-03-20", "1979-03-05"),
            ("CRUISE_2",  "@10",  "1979-03-20", "1980-10-28", "1980-01-01"),
            ("SATURN",    "@699", "1980-10-28", "1980-11-27", "1980-11-12"),
            ("CRUISE_3",  "@10",  "1980-11-27", "2100-01-01", "1990-01-01"),
        ],
        # spacecrafts.tsv registration (non-default fields only). No Voyager .glb
        # asset yet -> file_prefix falls back gracefully; add a model + hud_name later.
        "spacecraft_row": {
            "name": "VOYAGER_1",
            "sleep": "FALSE",
            "file_prefix": "Voyager",
            "en.wikipedia": "Voyager_1",
            "show_in_nav_panel": "x",
            "parent": "PLANET_EARTH",
            "orbit": "SEG_VOYAGER_1_DEPARTURE",
            "mean_radius": "5",          # meters; IVBody requires > 0 (model/HUD scale)
            "trajectory": "VOYAGER_1",
        },
        # Placeholder spacecraft rows to drop now that real data exists.
        "retire_spacecraft": ["TEST_PROBE_EARTH_MOON", "TEST_PROBE_INTERPLANETARY"],
    },
    "voyager_2": {
        "command": "-32",
        # Grand Tour: Jupiter -> Saturn -> Uranus -> Neptune. Flyby windows are
        # closest-approach +/-15 d (approx SOI residence); cruise windows fill the
        # gaps so each join time is shared with its neighbor anchor.
        "segments": [
            ("DEPARTURE", "@399", "1977-08-20", "1977-08-22", "1977-08-21"),
            ("CRUISE_1",  "@10",  "1977-08-22", "1979-06-24", "1978-06-01"),
            ("JUPITER",   "@599", "1979-06-24", "1979-07-24", "1979-07-09"),
            ("CRUISE_2",  "@10",  "1979-07-24", "1981-08-10", "1980-08-01"),
            ("SATURN",    "@699", "1981-08-10", "1981-09-09", "1981-08-25"),
            ("CRUISE_3",  "@10",  "1981-09-09", "1986-01-09", "1983-11-01"),
            ("URANUS",    "@799", "1986-01-09", "1986-02-08", "1986-01-24"),
            ("CRUISE_4",  "@10",  "1986-02-08", "1989-08-10", "1987-11-01"),
            ("NEPTUNE",   "@899", "1989-08-10", "1989-09-09", "1989-08-25"),
            ("CRUISE_5",  "@10",  "1989-09-09", "2100-01-01", "1995-01-01"),
        ],
        "spacecraft_row": {
            "name": "VOYAGER_2",
            "sleep": "FALSE",
            "file_prefix": "Voyager",
            "en.wikipedia": "Voyager_2",
            "show_in_nav_panel": "x",
            "parent": "PLANET_EARTH",
            "orbit": "SEG_VOYAGER_2_DEPARTURE",
            "mean_radius": "5",          # meters; IVBody requires > 0 (model/HUD scale)
            "trajectory": "VOYAGER_2",
        },
    },
    "pioneer_10": {
        "command": "-23",
        # A single Jupiter flyby, then solar-system escape (no further encounters).
        # HORIZONS solution is DE118-era -- lower fidelity than the Voyager refits;
        # the patched-conic joins still close, but absolute accuracy is weaker.
        "segments": [
            ("DEPARTURE", "@399", "1972-03-03", "1972-03-05", "1972-03-04"),
            ("CRUISE_1",  "@10",  "1972-03-05", "1973-11-18", "1973-01-01"),
            ("JUPITER",   "@599", "1973-11-18", "1973-12-18", "1973-12-03"),
            ("CRUISE_2",  "@10",  "1973-12-18", "2100-01-01", "1985-01-01"),
        ],
        "spacecraft_row": {
            "name": "PIONEER_10",
            "sleep": "FALSE",
            "file_prefix": "Pioneer",
            "en.wikipedia": "Pioneer_10",
            "show_in_nav_panel": "x",
            "parent": "PLANET_EARTH",
            "orbit": "SEG_PIONEER_10_DEPARTURE",
            "mean_radius": "5",          # meters; IVBody requires > 0 (model/HUD scale)
            "trajectory": "PIONEER_10",
        },
    },
    "juno": {
        "command": "-61",
        # Earth -> heliocentric DSM loop -> Earth gravity assist -> Jupiter capture,
        # then one representative orbit per post-capture period era.
        #  * The Earth->Earth cruise is a ~1-revolution loop -- more than the zero-rev
        #    Lambert gap-fixer can fit as one leg -- so it is split at the 2012 deep-space
        #    maneuver into two sub-revolution fix_gaps cruises (CRUISE_1A/1B). Consecutive
        #    fix_gaps cruises chain correctly: the new-game fix runs in order, anchoring
        #    each leg's start at its predecessor's freshly-fixed endpoint, so every join
        #    closes (see "Capture orbits and multi-revolution cruises" in TRAJECTORIES.md).
        #  * The Jupiter capture orbit and its successors are "visual_orbit" legs (optional
        #    6th segment element = flag set): drawn as local orbits (visual_orbits in
        #    trajectories.tsv), not the trajectory polyline. Their segment windows tile
        #    contiguously but the orbits are independent snapshots (period 53.5 -> 43 -> 38
        #    -> 33 d across the moon-flyby eras); the body jumps between them, which is fine
        #    -- we don't model the changes faithfully.
        #  * JUPITER_APPROACH is the pre-JOI inbound hyperbola -- a normal flyby-style anchor
        #    drawn in the polyline. CRUISE_2 closes onto its SOI-side entry (~15 d out), and
        #    it ends at perijove (JOI), where the capture ellipse takes over. JUPITER_CAPTURE
        #    is sampled just after JOI so its time_periapsis IS that perijove, keeping the
        #    hyperbola->ellipse handoff tight; a later sample lands Tp a period away, which
        #    projects back to JOI a few RJ off at perijove speed.
        # Earth-flyby and JOI boundaries get explicit times (fast planet-centric frames).
        "segments": [
            ("DEPARTURE",        "@399", "2011-08-05", "2011-08-07", "2011-08-06"),
            ("CRUISE_1A",        "@10",  "2011-08-07", "2012-09-03", "2012-02-01"),
            ("CRUISE_1B",        "@10",  "2012-09-03", "2013-10-08T19:21:25", "2013-04-01"),
            ("EARTH",            "@399", "2013-10-08T19:21:25", "2013-10-10T19:21:25", "2013-10-09T19:21:25"),
            ("CRUISE_2",         "@10",  "2013-10-10T19:21:25", "2016-06-20", "2015-01-01"),
            ("JUPITER_APPROACH", "@599", "2016-06-20", "2016-07-05T02:30:00", "2016-07-04"),
            ("JUPITER_CAPTURE",  "@599", "2016-07-05T02:30:00", "2021-06-07", "2016-07-10", {"visual_orbit"}),
            ("JUPITER_43D",      "@599", "2021-06-07", "2022-09-29", "2022-01-01", {"visual_orbit"}),
            ("JUPITER_38D",      "@599", "2022-09-29", "2024-02-03", "2023-06-01", {"visual_orbit"}),
            ("JUPITER_33D",      "@599", "2024-02-03", "2100-01-01", "2024-09-01", {"visual_orbit"}),
        ],
        # Convert the placeholder single-orbit Juno into a trajectory craft. Keep its
        # identity fields (model, wiki, HUD name, radius); repoint parent/orbit/trajectory
        # and set sleep FALSE (a trajectory craft must run _process to swap segments). The
        # old Jupiter "tidally_locked" rotation hack is dropped (it suited only the static
        # orbit). 'begin' is injected in main() = the departure segment_begin.
        "spacecraft_row": {
            "name": "JUNO",
            "sleep": "FALSE",
            "file_prefix": "Juno",
            "en.wikipedia": "Juno_(spacecraft)",
            "show_in_nav_panel": "x",
            "parent": "PLANET_EARTH",
            "orbit": "SEG_JUNO_DEPARTURE",
            "mean_radius": "5",          # meters; IVBody requires > 0 (model/HUD scale)
            "trajectory": "JUNO",
        },
        # The placeholder single representative orbit, now superseded by the trajectory.
        "retire_orbits": ["SPACECRAFT_JUNO"],
    },
    "new_horizons": {
        "command": "-98",
        # Earth -> Jupiter gravity assist -> Pluto-Charon flyby -> Kuiper Belt escape.
        # The fastest launch ever (a direct Earth-escape hyperbola, C3 ~ 158 km^2/s^2), so the
        # departure leg is a very hot hyperbola. Flyby windows are closest-approach +/- a SOI
        # residence: +/-15 d at Jupiter (the distant 2.3e6 km / 32-RJ pass is still deep inside
        # the ~48e6 km SOI), but only +/-2 d at Pluto -- its SOI is ~3e6 km (tiny GM out at 33 AU)
        # and the ~14 km/s encounter speed crosses it in days. The Pluto sample takes the explicit
        # closest-approach instant (fast planet-centric frame) so its time_periapsis is the real
        # perijove. Post-Pluto is one escape cruise to the 2100 horizon (Voyager/Pioneer pattern):
        # the 2019 Arrokoth flyby is NOT an anchor -- Arrokoth is modeled only as a massless
        # asteroid (no SOI), and it barely perturbed the heliocentric escape trajectory.
        "segments": [
            ("DEPARTURE", "@399", "2006-01-19", "2006-01-21", "2006-01-20"),
            ("CRUISE_1",  "@10",  "2006-01-21", "2007-02-13", "2006-08-01"),
            ("JUPITER",   "@599", "2007-02-13", "2007-03-15", "2007-02-28"),
            ("CRUISE_2",  "@10",  "2007-03-15", "2015-07-12", "2011-01-01"),
            ("PLUTO",     "@999", "2015-07-12", "2015-07-16", "2015-07-14T11:49:57"),
            ("CRUISE_3",  "@10",  "2015-07-16", "2100-01-01", "2018-01-01"),
        ],
        "spacecraft_row": {
            "name": "NEW_HORIZONS",
            "sleep": "FALSE",
            "file_prefix": "New_Horizons",
            "en.wikipedia": "New_Horizons",
            "show_in_nav_panel": "x",
            "parent": "PLANET_EARTH",
            "orbit": "SEG_NEW_HORIZONS_DEPARTURE",
            "mean_radius": "5",          # meters; IVBody requires > 0 (model/HUD scale)
            "trajectory": "NEW_HORIZONS",
        },
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
    """Julian Day from an ISO date with optional time-of-day: 'YYYY-MM-DD' (midnight)
    or 'YYYY-MM-DD[T| ]HH[:MM[:SS[.fff]]]'. A date alone pins a boundary to the day,
    which is invisible across a slow heliocentric join but misplaces it by up to half a
    day in a fast frame (a planet-moon system); give a time there. See the config note."""
    date_part, _, time_part = date_str.replace("T", " ").partition(" ")
    year, month, day = (int(field) for field in date_part.split("-"))
    hour = minute = 0
    second = 0.0
    if time_part:
        time_fields = time_part.split(":")
        hour = int(time_fields[0])
        minute = int(time_fields[1]) if len(time_fields) > 1 else 0
        second = float(time_fields[2]) if len(time_fields) > 2 else 0.0
    return gregorian_to_jd(year, month, day, hour, minute, second)


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


def internal_to_cols(name, parent, internal, segment_begin, segment_end, fix_gaps):
    """Internal elements -> orbits.tsv columns. Open-conic form (semi_parameter +
    time_periapsis) is valid for any eccentricity; the builder mods elliptic ones.
    [fix_gaps] marks a cruise leg for the engine's runtime gap-fix ('x' = true)."""
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
        "fix_gaps": "x" if fix_gaps else "",
    }


def generate(config, craft_name, godot, project, refresh=False, pre_fix=False):
    """Build all segment conics; return (orbit_cols, segment_names).

    Default: each segment is HORIZONS osculating elements at its sample epoch, and
    cruise legs are flagged fix_gaps so the engine closes the joins at new-game. With
    [pre_fix]: cruise legs are instead Lambert-fitted offline to the flyby endpoints
    using the running sim's planet positions (gap-free as shipped, no engine fix
    needed), which requires launching the sim."""
    command = config["command"]
    prefix = "SEG_" + craft_name.upper() + "_"

    # Per-segment scaffold. Flyby/departure anchors -- and, in the default path, cruise
    # legs too -- get HORIZONS osculating elements at the sample epoch.
    segments = []
    for entry in config["segments"]:
        suffix, center, begin, end, sample = entry[:5]
        flags = set(entry[5]) if len(entry) > 5 else set()
        seg = {
            "suffix": suffix, "parent": CENTER_BODY[center],
            "t_begin": jd_to_sim_seconds(date_to_jd(begin)),
            "t_end": jd_to_sim_seconds(date_to_jd(end)),
            "is_flyby": center != "@10",
            # Planet-centric leg drawn as a local orbit (visual_orbits), not the polyline.
            "visual_orbit": "visual_orbit" in flags,
        }
        if seg["is_flyby"] or not pre_fix:
            seg["internal"] = horizons_to_internal(
                parse_first_element_record(query_elements(command, center, sample)))
        segments.append(seg)

    if pre_fix:
        _pre_fix_cruises(segments, command, godot, project, refresh)

    orbit_cols, segment_names, visual_orbits = [], [], []
    print(f"# {craft_name}  (HORIZONS COMMAND='{command}')" + ("  [pre-fixed]" if pre_fix else ""))
    print(f"# {'segment':<26}{'primary':<15}{'e':>9}{'incl':>9}{'q(AU)':>10}{'fix_gaps':>9}{'visual':>8}")
    for index, seg in enumerate(segments):
        name = prefix + seg["suffix"]
        fix_gaps = not seg["is_flyby"]
        # The first segment is the Earth-departure hyperbola. Its rounded launch-date
        # begin sits tens of Earth diameters up the incoming asymptote (the trajectory
        # would be drawn arriving from deep space before launch). Begin it at periapsis
        # instead -- the synthetic near-surface departure point, a few hundred km up.
        segment_begin = seg["t_begin"]
        if index == 0 and seg["is_flyby"]:
            segment_begin = seg["internal"]["time_periapsis"]
        cols = internal_to_cols(name, seg["parent"], seg["internal"],
                                segment_begin, seg["t_end"], fix_gaps)
        orbit_cols.append(cols)
        segment_names.append(name)
        if seg["visual_orbit"]:
            visual_orbits.append(index)
        periapsis_au = seg["internal"]["p"] / (1.0 + seg["internal"]["e"]) / KM_PER_AU
        print(f"# {name:<26}{seg['parent']:<15}{seg['internal']['e']:>9.4f}"
              f"{math.degrees(seg['internal']['inc']):>9.3f}{periapsis_au:>10.4f}"
              f"{('x' if fix_gaps else ''):>9}{('orbit' if seg['visual_orbit'] else ''):>8}")
    return orbit_cols, segment_names, visual_orbits


def _pre_fix_cruises(segments, command, godot, project, refresh):
    """--pre-fix path: Lambert-fit each cruise leg to the adjacent flyby endpoints,
    using the running sim's planet positions, so shipped data is gap-free without the
    engine's runtime fix. Mutates each cruise seg['internal']. (The default path skips
    this entirely -- the engine closes the gaps at new-game.)"""
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

    # Each cruise = the heliocentric conic through its two boundary points in its TOF.
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


# *****************************************************************************
# TSV output


def fmt(value):
    if isinstance(value, float):
        return f"{value:.12g}"
    return str(value)


def read_table_columns(path):
    """Ordered column names from an ivoyager TSV header (its first non-comment row),
    so the writer can place values by name regardless of the table's current column
    order. Field 0 -- the unnamed entity column -- is reported as 'name', the key the
    row dicts use for the entity. Raises if the file has no header row."""
    with open(path, encoding="utf-8", newline="") as handle:
        for raw_line in handle:
            line = raw_line.rstrip("\r\n")
            if line and not line.startswith("#"):
                return ["name"] + line.split("\t")[1:]
    raise ValueError(f"{path}: no header row found")


def build_row(header_columns, cols):
    """Render [cols] ({column_name: value}) as a TSV data row in the table's own
    column order [header_columns]. Raises if a value in [cols] has no destination
    column -- a loud failure naming the orphan, rather than silently dropping the
    value (the symptom of a column this script writes being renamed or removed)."""
    known = set(header_columns)
    orphans = sorted(key for key, value in cols.items()
                     if value not in ("", None) and key not in known)
    if orphans:
        raise ValueError(f"no column for {', '.join(orphans)} in this table header "
                         f"(renamed/removed?); header has: "
                         f"{', '.join(filter(None, header_columns))}")
    return "\t".join(fmt(cols.get(column, "")) for column in header_columns)


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
    with open(path, encoding="utf-8", newline="") as handle:  # newline="" -> no EOL translation
        raw = handle.read()
    newline = "\r\n" if "\r\n" in raw else "\n"
    lines = raw.split(newline)

    # Secondary guard: build_row already emits the header's column count, so a new row
    # matching the existing data rows' field count confirms the header and data agree on
    # width. A mismatch means the table's header and data rows disagree (a malformed .tsv).
    counts = [line.count("\t") + 1 for line in lines if _is_data_line(line)]
    if counts:
        expected = max(set(counts), key=counts.count)
        for name, row in rows:
            actual = row.count("\t") + 1
            if actual != expected:
                raise ValueError(f"{path.name}: row '{name}' has {actual} fields, "
                                 f"expected {expected} (header/data column-count mismatch)")

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

    with open(path, "w", encoding="utf-8", newline="") as handle:
        handle.write(newline.join(out))
    return replaced, appended, removed


def main():
    parser = argparse.ArgumentParser(description="Generate ivoyager trajectory table rows from HORIZONS")
    parser.add_argument("craft", nargs="?", default="voyager_1")
    parser.add_argument("--write", action="store_true", help="upsert rows into the tables")
    parser.add_argument("--refresh", action="store_true", help="re-query cached sim data (--pre-fix)")
    parser.add_argument("--pre-fix", action="store_true",
                        help="Lambert-fit cruise legs offline (launches the sim); default emits "
                             "natural cruises + fix_gaps for the engine to close at runtime")
    parser.add_argument("--godot", default=None, help="path to the Godot console executable")
    parser.add_argument("--project", default=str(TABLES_DIR.parent.parent.parent))
    args = parser.parse_args()
    if args.craft not in CRAFT:
        sys.exit(f"Unknown craft '{args.craft}'. Known: {', '.join(CRAFT)}")
    config = CRAFT[args.craft]

    godot = args.godot
    if args.pre_fix and godot is None:
        sys.path.insert(0, str(ASSISTANT_TOOLS))
        from orbit_accuracy_test import find_godot_executable
        godot = find_godot_executable(args.project)
        if not godot:
            sys.exit("No Godot console executable found; pass --godot PATH")

    orbit_cols, segment_names, visual_orbits = generate(config, args.craft, godot, args.project,
                                                        args.refresh, args.pre_fix)

    orbit_columns = read_table_columns(TABLES_DIR / "orbits.tsv")
    orbit_rows = [(cols["name"], build_row(orbit_columns, cols)) for cols in orbit_cols]
    traj_name = args.craft.upper()
    traj_cols = {"name": traj_name, "orbits": ";".join(segment_names)}
    if visual_orbits:  # ARRAY[INT] of segment indexes drawn as local orbits, not the polyline
        traj_cols["visual_orbits"] = ";".join(str(index) for index in visual_orbits)
    traj_row = (traj_name, build_row(read_table_columns(TABLES_DIR / "trajectories.tsv"), traj_cols))
    spacecraft = config.get("spacecraft_row")
    if spacecraft is not None:
        # Body 'begin' (start of life) = the departure segment's segment_begin (its synthetic
        # perigee), so the craft appears exactly when its trajectory starts.
        spacecraft = dict(spacecraft, begin=orbit_cols[0]["segment_begin"])
    spacecraft_row = ((spacecraft["name"],
                       build_row(read_table_columns(TABLES_DIR / "spacecrafts.tsv"), spacecraft))
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
    report("orbits.tsv", upsert_table(TABLES_DIR / "orbits.tsv", orbit_rows,
           remove_names=config.get("retire_orbits", ())))
    report("trajectories.tsv", upsert_table(TABLES_DIR / "trajectories.tsv", [traj_row]))
    if spacecraft_row:
        report("spacecrafts.tsv", upsert_table(TABLES_DIR / "spacecrafts.tsv",
               [spacecraft_row], remove_names=config.get("retire_spacecraft", ())))


if __name__ == "__main__":
    main()
