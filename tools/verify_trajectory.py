#!/usr/bin/env python3
# verify_trajectory.py
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
"""In-sim verification for a generated spacecraft trajectory (companion to
horizons_trajectory.py).

Launches the Planetarium, then via the Assistant TCP server confirms that the
craft loaded and that its patched-conic trajectory swaps to the correct
gravitational primary in each segment. Expected primaries and sample epochs are
read from the same hand-maintained config used to generate the data, so the two
stay in lock-step.

Checks per craft:
  1. The SPACECRAFT_<NAME> body exists; retired placeholder rows are gone.
  2. At each segment's sample epoch, set_time then read the body's parent ->
     must equal the segment's configured primary (the runtime segment swap).
  3. get_body_position at each sample epoch is finite, and heliocentric-cruise
     distances dwarf planet-flyby distances (scale-free geometry sanity).
  4. No errors/leaks in the Godot console at quit.

Usage (refresh table imports first; headless runs use cached table data):
    <godot-console> --path . --editor --headless --quit
    python tools/verify_trajectory.py voyager_1 --launch
"""

import argparse
import math
import pathlib
import sys
import time as time_module

from horizons_trajectory import CRAFT, CENTER_BODY, date_to_jd, jd_to_sim_seconds

# Reuse the assistant plugin's launcher + TCP client (its tools dir isn't a package).
ASSISTANT_TOOLS = (pathlib.Path(__file__).resolve().parent.parent
                   / "addons" / "ivoyager_assistant" / "tools")
sys.path.insert(0, str(ASSISTANT_TOOLS))
from assistant_test import AssistantClient, GodotLauncher          # noqa: E402
from orbit_accuracy_test import find_godot_executable              # noqa: E402

CONSOLE_ERROR_MARKERS = ("SCRIPT ERROR", "ERROR:", "Assertion failed",
                         "Trajectory segment", "not found in IVBody.bodies")


def checkpoints(craft_name):
    """(sample_seconds, expected_parent, label) per segment, from the config."""
    points = []
    for suffix, center, _begin, _end, sample in CRAFT[craft_name]["segments"]:
        seconds = jd_to_sim_seconds(date_to_jd(sample))
        points.append((seconds, CENTER_BODY[center], suffix))
    return points


def wait_until_ready(client, attempts=60):
    for _ in range(attempts):
        if "result" in client.call("list_bodies", {"filter": "all"}):
            return True
        time_module.sleep(1.0)
    return False


def vector_length(vec):
    return math.sqrt(sum(component * component for component in vec))


def vector_sub(a, b):
    return [a[i] - b[i] for i in range(3)]


def heliocentric(client, body, seconds, parent):
    """Spacecraft heliocentric position at [seconds], using whichever segment is
    active there (parent-relative position + the parent's heliocentric position).
    Returns None on query failure."""
    sc = client.call("get_body_position",
                     {"name": body, "time": seconds}).get("result", {}).get("position")
    if not sc:
        return None
    if parent == "STAR_SUN":
        return sc
    planet = client.call("get_body_position",
                         {"name": parent, "time": seconds}).get("result", {}).get("position")
    if not planet:
        return None
    return [sc[i] + planet[i] for i in range(3)]


def main():
    parser = argparse.ArgumentParser(description="Verify a spacecraft trajectory in-sim")
    parser.add_argument("craft", nargs="?", default="voyager_1")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=29071)
    parser.add_argument("--launch", action="store_true")
    parser.add_argument("--godot", default=None)
    parser.add_argument("--project", default=".")
    args = parser.parse_args()
    if args.craft not in CRAFT:
        sys.exit(f"Unknown craft '{args.craft}'. Known: {', '.join(CRAFT)}")

    body = "SPACECRAFT_" + args.craft.upper()
    points = checkpoints(args.craft)
    failures = []

    launcher = None
    if args.launch:
        godot = args.godot or find_godot_executable(args.project)
        if not godot:
            sys.exit("No Godot console executable found; use --godot PATH")
        print(f"Launching: {godot} --path {args.project}")
        launcher = GodotLauncher(godot, args.project)
        launcher.start()

    client = AssistantClient(host=args.host, port=args.port)
    try:
        print(f"Connecting to {args.host}:{args.port}...")
        client.connect()
        if not wait_until_ready(client):
            failures.append("simulator never reached ready state")
            raise RuntimeError("not ready")

        info = client.call("get_project_info").get("result", {})
        capabilities = info.get("capabilities", [])
        can_set_time = "set_time" in capabilities

        spacecraft = client.call("list_bodies", {"filter": "spacecraft"}).get("result", {})
        names = spacecraft.get("bodies", [])
        print(f"spacecraft bodies: {names}")
        if body not in names:
            failures.append(f"{body} not present in spacecraft list")
        for retired in ("SPACECRAFT_TEST_PROBE_EARTH_MOON", "SPACECRAFT_TEST_PROBE_INTERPLANETARY"):
            if retired in names:
                failures.append(f"retired placeholder {retired} still present")

        if "error" in client.call("get_body_info", {"name": body}):
            failures.append(f"get_body_info failed for {body}")

        print(f"\n{'segment':<12} {'expected parent':<16} {'set_time parent':<16} "
              f"{'|pos| (sim)':>14}  result")
        print("-" * 72)
        distances = {}
        for seconds, expected_parent, label in points:
            # Geometry at the explicit sample epoch (correct per-segment evaluation).
            position = client.call("get_body_position",
                                   {"name": body, "time": seconds}).get("result", {}).get("position")
            length = vector_length(position) if position else float("nan")
            distances[label] = length

            # Runtime parent swap: move the clock there, let a frame run, read parent.
            swap_parent = "n/a"
            if can_set_time:
                client.call("set_time", {"time": seconds})
                client.call("get_state")  # advance one frame so _process can swap
                swap_parent = client.call("get_body_info",
                                          {"name": body}).get("result", {}).get("parent", "?")

            ok = (math.isfinite(length) and length > 0.0
                  and (not can_set_time or swap_parent == expected_parent))
            if not ok:
                failures.append(f"{label}: parent {swap_parent} (expected {expected_parent}), "
                                f"|pos|={length}")
            print(f"{label:<12} {expected_parent:<16} {swap_parent:<16} "
                  f"{length:>14.3e}  {'PASS' if ok else 'FAIL'}")

        # Scale-free sanity: cruise (heliocentric) distances should dwarf flyby
        # (planet-relative) distances. Compare the smallest cruise leg to the
        # largest flyby leg.
        cruise = [distances[c] for _, parent, c in points if parent == "STAR_SUN"]
        flyby = [distances[c] for _, parent, c in points if parent != "STAR_SUN"]
        if cruise and flyby and min(cruise) <= max(flyby) * 10.0:
            failures.append(f"geometry: cruise distances ({min(cruise):.2e}) not >> "
                            f"flyby distances ({max(flyby):.2e})")

        # Continuity: at each interior boundary the heliocentric position from the
        # two adjacent segments must coincide. Sample 1 s inside each side; a torn
        # join reads ~1e6 km, a connected one ~1e2 km (the float32 path floor).
        segments = CRAFT[args.craft]["segments"]
        print(f"\n{'boundary':<26}{'gap (km)':>13}  result")
        print("-" * 48)
        for k in range(len(segments) - 1):
            t_boundary = jd_to_sim_seconds(date_to_jd(segments[k][3]))
            before = heliocentric(client, body, t_boundary - 1.0, CENTER_BODY[segments[k][1]])
            after = heliocentric(client, body, t_boundary + 1.0, CENTER_BODY[segments[k + 1][1]])
            label = f"{segments[k][0]} -> {segments[k + 1][0]}"
            if before is None or after is None:
                failures.append(f"continuity {label}: query failed")
                continue
            gap = vector_length(vector_sub(after, before))
            ok = gap < 1.0e4
            if not ok:
                failures.append(f"continuity {label}: gap {gap:.3e} km")
            print(f"{label:<26}{gap:>13.3e}  {'PASS' if ok else 'FAIL'}")

    except Exception as exc:
        failures.append(f"exception: {exc}")
    finally:
        try:
            client.call("quit", {"force": True})
        except Exception:
            pass
        client.close()
        if launcher:
            launcher.shutdown_and_report()
            captured = getattr(launcher, "_captured", [])
            error_lines = [line.rstrip() for line in captured
                           if any(marker in line for marker in CONSOLE_ERROR_MARKERS)]
            if error_lines:
                print("\n--- console error lines ---")
                for line in error_lines[:20]:
                    print(line)
            output = "\n".join(captured)
            for marker in CONSOLE_ERROR_MARKERS:
                if marker in output:
                    failures.append(f"console contains '{marker}'")
            if getattr(launcher, "leaks", None):
                failures.append("Godot reported leaks at exit")

    if failures:
        print(f"\n{len(failures)} FAILURE(S):")
        for failure in failures:
            print(f"  - {failure}")
        sys.exit(1)
    print(f"\n{body}: trajectory verified — all segments swap to the correct primary.")
    sys.exit(0)


if __name__ == "__main__":
    main()
