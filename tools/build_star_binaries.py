#!/usr/bin/env python3
# build_star_binaries.py
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
"""Build I, Voyager star point-cloud binaries from the ESA Hipparcos Catalogue.

Reads the Hipparcos Main Catalogue `hip_main.dat` (ESA 1997; VizieR I/239) and
writes magnitude-binned `.ivbinary` files consumed by IVStarsVisual. Each star
contributes an ecliptic-frame Cartesian position (SI meters), a Johnson V
magnitude, and a B-V color index.

Positions apply the J2000 obliquity rotation (see IVAstronomy
`get_ecliptic_unit_vector_from_equatorial_angles`) so stars land in the sim's
ecliptic world frame, sharing the planets' coordinates. Distance is 1/parallax
when the parallax is positive and its signal-to-noise clears a threshold, else a
far shell (default 1 kpc). Distance barely matters for a backdrop, but a true
distance gives the correct (tiny) parallax for the nearest stars.

Binary format (little-endian; consumed by stars_visual.gd):
  Header:  magic b"IVST" (uint32 0x54535649), version (uint32), count (uint32)
  Block A: count * (x, y, z) float32    ecliptic position, SI meters
  Block B: count * (Vmag, B_V) float32

The raw layout (not Godot store_var) keeps the baker pure-Python and lets the
loader bulk-read with FileAccess.get_buffer().to_float32_array().

Usage:
    python build_star_binaries.py                 # source_data/hip_main.dat -> assets/starmaps
    python build_star_binaries.py --dry-run       # parse + report counts, write nothing
"""

import argparse
import array
import math
import os
import struct
import sys

# Length constants; match planetarium/units.gd and IVAstronomy.
AU_M = 149597870700.0
PARSEC_M = 648000.0 * AU_M / math.pi
OBLIQUITY = math.radians(23.4392911)  # IVAstronomy.OBLIQUITY_OF_THE_ECLIPTIC (J2000)
COS_OBL = math.cos(OBLIQUITY)
SIN_OBL = math.sin(OBLIQUITY)

MAGIC = b"IVST"
VERSION = 1

# Bin upper edges (Vmag). MUST match IVStarsVisual.BINARY_FILE_MAGNITUDES. A star
# goes in the first bin whose edge >= its Vmag; the final 99.9 bin catches the
# faint tail. The loader loads bins up to a magnitude_cutoff.
BIN_EDGES = [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 99.9]

# hip_main.dat pipe-delimited field indices (VizieR I/239 "hip_main").
F_VMAG = 5    # Johnson V magnitude
F_RADEG = 8   # RA degrees, ICRS epoch J1991.25
F_DEDEG = 9   # Dec degrees
F_PLX = 11    # Trigonometric parallax (mas)
F_E_PLX = 16  # Standard error on parallax (mas)
F_BV = 37     # Johnson B-V color index


def parse_float(text):
    text = text.strip()
    if not text:
        return None
    try:
        return float(text)
    except ValueError:
        return None


def ecliptic_position_m(ra_deg, dec_deg, dist_pc):
    # Equatorial (ICRS) angles -> ecliptic Cartesian unit vector -> scale by
    # distance. Rotation matches IVAstronomy exactly so stars align with bodies.
    ra = math.radians(ra_deg)
    dec = math.radians(dec_deg)
    cos_dec = math.cos(dec)
    x_eq = cos_dec * math.cos(ra)
    y_eq = cos_dec * math.sin(ra)
    z_eq = math.sin(dec)
    x = x_eq
    y = y_eq * COS_OBL + z_eq * SIN_OBL
    z = -y_eq * SIN_OBL + z_eq * COS_OBL
    r = dist_pc * PARSEC_M
    return x * r, y * r, z * r


def bin_index(vmag):
    for i, edge in enumerate(BIN_EDGES):
        if vmag <= edge:
            return i
    return len(BIN_EDGES) - 1


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    parser = argparse.ArgumentParser(description="Build Hipparcos star binaries for IVStarsVisual.")
    parser.add_argument("--source", default=os.path.join(here, "source_data", "hip_main.dat"),
            help="hip_main.dat path (VizieR I/239)")
    parser.add_argument("--out-dir",
            default=os.path.normpath(os.path.join(here, "..", "addons", "ivoyager_assets", "starmaps")),
            help="output directory for .ivbinary files")
    parser.add_argument("--prefix", default="hipparcos_stars", help="output file basename prefix")
    parser.add_argument("--parallax-snr", type=float, default=5.0,
            help="min parallax/error for a true distance; below this a star uses the far shell")
    parser.add_argument("--shell-pc", type=float, default=1000.0,
            help="far-shell distance (pc) for stars with unreliable parallax")
    parser.add_argument("--default-bv", type=float, default=0.5,
            help="B-V assigned to stars lacking a color index")
    parser.add_argument("--dry-run", action="store_true", help="parse and report, write no files")
    args = parser.parse_args()

    positions = [array.array("f") for _ in BIN_EDGES]  # x,y,z interleaved
    photom = [array.array("f") for _ in BIN_EDGES]     # vmag,bv interleaved
    n_total = n_shell = n_parallax = n_skipped = 0

    with open(args.source, "r", encoding="latin-1") as source:
        for line in source:
            fields = line.split("|")
            if len(fields) <= F_BV:
                continue
            vmag = parse_float(fields[F_VMAG])
            ra_deg = parse_float(fields[F_RADEG])
            dec_deg = parse_float(fields[F_DEDEG])
            if vmag is None or ra_deg is None or dec_deg is None:
                n_skipped += 1
                continue
            parallax = parse_float(fields[F_PLX])
            e_parallax = parse_float(fields[F_E_PLX])
            b_v = parse_float(fields[F_BV])
            if b_v is None:
                b_v = args.default_bv
            if (parallax is not None and parallax > 0.0 and e_parallax is not None
                    and e_parallax > 0.0 and parallax / e_parallax >= args.parallax_snr):
                dist_pc = 1000.0 / parallax
                n_parallax += 1
            else:
                dist_pc = args.shell_pc
                n_shell += 1
            x, y, z = ecliptic_position_m(ra_deg, dec_deg, dist_pc)
            index = bin_index(vmag)
            positions[index].extend((x, y, z))
            photom[index].extend((vmag, b_v))
            n_total += 1

    print("Parsed %s stars (%s true-parallax, %s far-shell); skipped %s without V/RA/Dec."
            % (n_total, n_parallax, n_shell, n_skipped))
    if not args.dry_run:
        os.makedirs(args.out_dir, exist_ok=True)
    for index, edge in enumerate(BIN_EDGES):
        count = len(photom[index]) // 2
        name = "%s.%s.ivbinary" % (args.prefix, format(edge, ".1f"))
        print("  %-28s %7d stars" % (name, count))
        if args.dry_run or count == 0:
            continue
        if sys.byteorder == "big":  # array.tofile writes native order; every target is LE
            positions[index].byteswap()
            photom[index].byteswap()
        with open(os.path.join(args.out_dir, name), "wb") as out:
            out.write(MAGIC)
            out.write(struct.pack("<II", VERSION, count))
            positions[index].tofile(out)
            photom[index].tofile(out)
    if not args.dry_run:
        print("Wrote binaries to %s" % args.out_dir)


if __name__ == "__main__":
    main()
