#!/usr/bin/env python3
# orbital.py
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
"""Two-body orbital mechanics for the trajectory pipeline (stdlib only).

All quantities SI-flavored for HORIZONS' KM-S units: distances km, speeds km/s,
time seconds, gravitational parameter km^3/s^2, angles radians. Vectors are
3-tuples in the ecliptic-of-J2000 frame (the same frame HORIZONS ELEMENTS /
VECTORS use with REF_PLANE=ECLIPTIC, and the frame IVOrbit reconstructs for
REFERENCE_PLANE_ECLIPTIC). Handles elliptic and hyperbolic conics; parabolic
(e == 1) is not used by spacecraft trajectories and is not supported.

Used to: propagate an anchored flyby conic to its segment boundaries
([elements_to_state]); fit a cruise conic through two boundary positions in a
given time of flight ([lambert]); and turn the resulting state back into the
Keplerian elements orbits.tsv stores ([state_to_elements]).
"""

import math

_TWO_PI = 2.0 * math.pi


def _sub(a, b): return (a[0] - b[0], a[1] - b[1], a[2] - b[2])
def _scale(a, s): return (a[0] * s, a[1] * s, a[2] * s)
def _dot(a, b): return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
def _cross(a, b): return (a[1] * b[2] - a[2] * b[1],
                          a[2] * b[0] - a[0] * b[2],
                          a[0] * b[1] - a[1] * b[0])
def _norm(a): return math.sqrt(_dot(a, a))
def _clamp_unit(x): return max(-1.0, min(1.0, x))


def _perifocal_to_ecliptic(vec, lan, inc, argp):
    """Rotate a perifocal vector to the ecliptic frame: R = Rz(lan)·Rx(inc)·Rz(argp)."""
    cos_lan, sin_lan = math.cos(lan), math.sin(lan)
    cos_inc, sin_inc = math.cos(inc), math.sin(inc)
    cos_argp, sin_argp = math.cos(argp), math.sin(argp)
    r11 = cos_lan * cos_argp - sin_lan * sin_argp * cos_inc
    r12 = -cos_lan * sin_argp - sin_lan * cos_argp * cos_inc
    r13 = sin_lan * sin_inc
    r21 = sin_lan * cos_argp + cos_lan * sin_argp * cos_inc
    r22 = -sin_lan * sin_argp + cos_lan * cos_argp * cos_inc
    r23 = -cos_lan * sin_inc
    r31 = sin_argp * sin_inc
    r32 = cos_argp * sin_inc
    r33 = cos_inc
    x, y, z = vec
    return (r11 * x + r12 * y + r13 * z,
            r21 * x + r22 * y + r23 * z,
            r31 * x + r32 * y + r33 * z)


def elements_to_state(p, e, inc, lan, argp, time_periapsis, gm, t):
    """Propagate Keplerian elements to a (position, velocity) state at time [t].

    [p] is the semi-parameter (km), [time_periapsis] absolute (s). Returns
    (r_vec, v_vec) in km and km/s, ecliptic frame."""
    semi_major_axis = p / (1.0 - e * e)
    if e < 1.0:
        mean_motion = math.sqrt(gm / semi_major_axis ** 3)
        mean_anomaly = mean_motion * (t - time_periapsis)
        mean_anomaly = (mean_anomaly + math.pi) % _TWO_PI - math.pi
        eccentric_anomaly = mean_anomaly if e < 0.8 else math.pi
        for _ in range(100):
            delta = ((eccentric_anomaly - e * math.sin(eccentric_anomaly) - mean_anomaly)
                     / (1.0 - e * math.cos(eccentric_anomaly)))
            eccentric_anomaly -= delta
            if abs(delta) < 1e-14:
                break
        true_anomaly = 2.0 * math.atan2(
            math.sqrt(1.0 + e) * math.sin(eccentric_anomaly / 2.0),
            math.sqrt(1.0 - e) * math.cos(eccentric_anomaly / 2.0))
    else:
        mean_motion = math.sqrt(gm / (-semi_major_axis) ** 3)
        mean_anomaly = mean_motion * (t - time_periapsis)
        hyper_anomaly = math.asinh(mean_anomaly / e) if mean_anomaly != 0.0 else 0.0
        for _ in range(100):
            delta = ((e * math.sinh(hyper_anomaly) - hyper_anomaly - mean_anomaly)
                     / (e * math.cosh(hyper_anomaly) - 1.0))
            hyper_anomaly -= delta
            if abs(delta) < 1e-14:
                break
        true_anomaly = 2.0 * math.atan2(
            math.sqrt(e + 1.0) * math.sinh(hyper_anomaly / 2.0),
            math.sqrt(e - 1.0) * math.cosh(hyper_anomaly / 2.0))

    radius = p / (1.0 + e * math.cos(true_anomaly))
    sqrt_gm_p = math.sqrt(gm / p)
    r_pf = (radius * math.cos(true_anomaly), radius * math.sin(true_anomaly), 0.0)
    v_pf = (-sqrt_gm_p * math.sin(true_anomaly),
            sqrt_gm_p * (e + math.cos(true_anomaly)), 0.0)
    return (_perifocal_to_ecliptic(r_pf, lan, inc, argp),
            _perifocal_to_ecliptic(v_pf, lan, inc, argp))


def state_to_elements(r_vec, v_vec, gm, t):
    """Convert a (position, velocity) state at time [t] to Keplerian elements.

    Returns {p, e, inc, lan, argp, time_periapsis} (km, radians, seconds)."""
    radius = _norm(r_vec)
    speed = _norm(v_vec)
    h_vec = _cross(r_vec, v_vec)
    h = _norm(h_vec)
    node_vec = _cross((0.0, 0.0, 1.0), h_vec)
    node = _norm(node_vec)
    e_vec = _scale(_sub(_scale(r_vec, speed * speed - gm / radius),
                        _scale(v_vec, _dot(r_vec, v_vec))), 1.0 / gm)
    e = _norm(e_vec)
    inc = math.acos(_clamp_unit(h_vec[2] / h))

    if node > 1e-9:
        lan = math.acos(_clamp_unit(node_vec[0] / node))
        if node_vec[1] < 0.0:
            lan = _TWO_PI - lan
        argp = math.acos(_clamp_unit(_dot(node_vec, e_vec) / (node * e)))
        if e_vec[2] < 0.0:
            argp = _TWO_PI - argp
    else:                                    # equatorial: node undefined
        lan = 0.0
        argp = math.atan2(e_vec[1], e_vec[0])

    true_anomaly = math.acos(_clamp_unit(_dot(e_vec, r_vec) / (e * radius)))
    if _dot(r_vec, v_vec) < 0.0:
        true_anomaly = _TWO_PI - true_anomaly

    p = h * h / gm
    semi_major_axis = p / (1.0 - e * e)
    if e < 1.0:
        eccentric_anomaly = 2.0 * math.atan2(
            math.sqrt(1.0 - e) * math.sin(true_anomaly / 2.0),
            math.sqrt(1.0 + e) * math.cos(true_anomaly / 2.0))
        mean_anomaly = eccentric_anomaly - e * math.sin(eccentric_anomaly)
        mean_motion = math.sqrt(gm / semi_major_axis ** 3)
    else:
        hyper_anomaly = 2.0 * math.atanh(
            math.sqrt((e - 1.0) / (e + 1.0)) * math.tan(true_anomaly / 2.0))
        mean_anomaly = e * math.sinh(hyper_anomaly) - hyper_anomaly
        mean_motion = math.sqrt(gm / (-semi_major_axis) ** 3)
    return {"p": p, "e": e, "inc": inc, "lan": lan, "argp": argp,
            "time_periapsis": t - mean_anomaly / mean_motion}


def _stumpff(z):
    if z > 1e-6:
        sqrt_z = math.sqrt(z)
        return (1.0 - math.cos(sqrt_z)) / z, (sqrt_z - math.sin(sqrt_z)) / sqrt_z ** 3
    if z < -1e-6:
        sqrt_z = math.sqrt(-z)
        return (1.0 - math.cosh(sqrt_z)) / z, (math.sinh(sqrt_z) - sqrt_z) / sqrt_z ** 3
    return 0.5, 1.0 / 6.0


def lambert(r1_vec, r2_vec, tof, gm, prograde=True):
    """Solve Lambert's problem: the conic from [r1_vec] to [r2_vec] in [tof] seconds.

    Universal-variable formulation (Vallado). Returns (v1_vec, v2_vec) km/s. Raises
    if the geometry is degenerate or it fails to converge."""
    r1 = _norm(r1_vec)
    r2 = _norm(r2_vec)
    cos_dnu = _clamp_unit(_dot(r1_vec, r2_vec) / (r1 * r2))
    transfer_normal_z = _cross(r1_vec, r2_vec)[2]
    direction = 1.0 if (transfer_normal_z >= 0.0) == prograde else -1.0
    a_geom = direction * math.sqrt(r1 * r2 * (1.0 + cos_dnu))
    if a_geom == 0.0:
        raise ValueError("Lambert: transfer geometry degenerate (A = 0)")

    def dt_and_y(psi):
        # Universal-variable TOF for trial psi, or (None, _) when psi is invalid:
        # y < 0 (psi below the valid floor when a_geom > 0) or the Stumpff terms
        # degenerate/overflow. Bisection treats None as "psi too low".
        try:
            c2, c3 = _stumpff(psi)
        except OverflowError:
            return None, -1.0
        if c2 <= 0.0:
            return None, -1.0
        y_local = r1 + r2 + a_geom * (psi * c3 - 1.0) / math.sqrt(c2)
        if y_local < 0.0:
            return None, y_local
        chi = math.sqrt(y_local / c2)
        return (chi ** 3 * c3 + a_geom * math.sqrt(y_local)) / math.sqrt(gm), y_local

    # TOF rises monotonically with psi over the zero-rev range (-inf, 4*pi^2);
    # c2 = 0 exactly at 4*pi^2 so cap just below it, and since TOF -> inf there
    # no upward expansion is needed. Only extend the hyperbolic floor downward
    # if the transfer is faster than psi_low allows.
    psi_low = -4.0 * math.pi ** 2
    psi_up = 4.0 * math.pi ** 2 - 1e-6
    for _ in range(60):
        dt_low, _ = dt_and_y(psi_low)
        if dt_low is None or dt_low <= tof:
            break
        psi_low *= 2.0

    y = None
    for _ in range(200):
        psi = 0.5 * (psi_low + psi_up)
        dt, y = dt_and_y(psi)
        if dt is None or dt < tof:
            psi_low = psi
        else:
            psi_up = psi
        if dt is not None and abs(dt - tof) < 1e-3:
            break
    if y is None or y < 0.0:
        raise ValueError("Lambert: failed to converge")

    f = 1.0 - y / r1
    g = a_geom * math.sqrt(y / gm)
    g_dot = 1.0 - y / r2
    v1 = _scale(_sub(r2_vec, _scale(r1_vec, f)), 1.0 / g)
    v2 = _scale(_sub(_scale(r2_vec, g_dot), r1_vec), 1.0 / g)
    return v1, v2


# *****************************************************************************
# self-test: round-trip the math against itself for an elliptic and a
# hyperbolic orbit, and confirm Lambert recovers a known orbit's velocity.


def _selftest():
    gm_sun = 1.32712440018e11  # km^3/s^2
    max_err = 0.0
    for label, elems in (
        ("elliptic", {"p": 2.0e8 * (1 - 0.3 ** 2), "e": 0.3, "inc": math.radians(15.0),
                      "lan": math.radians(40.0), "argp": math.radians(70.0),
                      "time_periapsis": 1.0e7}),
        ("hyperbolic", {"p": 7.7e8 * (1 + 2.25), "e": 2.25, "inc": math.radians(35.0),
                        "lan": math.radians(180.0), "argp": math.radians(338.0),
                        "time_periapsis": 0.0}),
    ):
        p = abs(elems["p"])
        t1, t2 = 5.0e6, 5.0e6 + 60.0 * 86400.0
        r1, v1 = elements_to_state(p, elems["e"], elems["inc"], elems["lan"],
                                   elems["argp"], elems["time_periapsis"], gm_sun, t1)
        r2, v2 = elements_to_state(p, elems["e"], elems["inc"], elems["lan"],
                                   elems["argp"], elems["time_periapsis"], gm_sun, t2)

        # (a) state -> elements recovers the inputs
        back = state_to_elements(r1, v1, gm_sun, t1)
        for key in ("e", "inc", "lan", "argp"):
            max_err = max(max_err, abs(back[key] - elems[key]))
        max_err = max(max_err, abs(back["p"] - p) / p)

        # (b) Lambert(r1, r2, tof) recovers v1
        v1_lambert, _ = lambert(r1, r2, t2 - t1, gm_sun)
        rel_v = _norm(_sub(v1_lambert, v1)) / _norm(v1)
        max_err = max(max_err, rel_v)
        print(f"{label:11} state->elem ok, Lambert v1 rel-err = {rel_v:.2e}")

    print(f"max error = {max_err:.2e}  ->  {'PASS' if max_err < 1e-6 else 'FAIL'}")
    return max_err < 1e-6


if __name__ == "__main__":
    import sys
    sys.exit(0 if _selftest() else 1)
