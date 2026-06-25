# make_iapetus_dem.py
# This file is part of I, Voyager (https://ivoyager.dev)
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield
# Licensed under the Apache License, Version 2.0 (the "License").
# *****************************************************************************
"""Generate an IDEALIZED synthetic DEM for Iapetus (equirectangular, meters above
a reference sphere) for use with build_body_model.py.

This is NOT measured topography. No public global DEM of Iapetus exists; this
encodes only Iapetus's two well-published large-scale shape features as a
data-grounded generalization:

  1. The oblate "fossil bulge": a triaxial figure ~745.7 x 745.7 x 712.1 km
     (Thomas 2010), i.e. ~4.6% flattening.
  2. The equatorial ridge: an idealized smooth ridge (published dimensions:
     up to ~20 km tall, ~70-100 km wide, ~1300 km long within Cassini Regio).
     It is auto-placed at the darkest equatorial longitude of the albedo map,
     which is the center of dark Cassini Regio that the real ridge runs through.

Fine relief (craters, individual peaks) is deliberately absent and left smooth.

Usage: python make_iapetus_dem.py <albedo.jpg> <out_dem.tif>
"""

import sys
import numpy as np
import tifffile
from PIL import Image

Image.MAX_IMAGE_PIXELS = None

A_EQ = 745.7      # km, equatorial radius (Thomas 2010)
C_POL = 712.1     # km, polar radius
REF = 734.4       # km, reference sphere (= moons.tsv mean_radius)
RIDGE_PEAK_M = 19000.0          # idealized ridge height (near the measured ~20 km peaks)
RIDGE_LAT_SIGMA_DEG = 1.6       # gaussian half-width in latitude (~70 km base)
RIDGE_LON_HALFWIDTH_DEG = 60.0  # ridge spans ~120 deg of longitude (Cassini Regio)
RIDGE_LON_TAPER_DEG = 25.0      # soft longitudinal taper at each end
W, H = 2048, 1024


def main():
    albedo_path, out_path = sys.argv[1], sys.argv[2]

    lon = (np.arange(W) + 0.5) / W * 360.0           # 0..360 deg, col 0 = lon 0
    lat = (0.5 - (np.arange(H) + 0.5) / H) * 180.0   # +90 (top) .. -90 (bottom)
    LON, LAT = np.meshgrid(lon, lat)
    latr = np.radians(LAT)

    # 1. oblate figure: geocentric ellipsoid radius at each latitude
    r_ell = A_EQ * C_POL / np.sqrt((C_POL * np.cos(latr)) ** 2 + (A_EQ * np.sin(latr)) ** 2)
    height_m = (r_ell - REF) * 1000.0

    # 2. ridge longitude: darkest equatorial column of the albedo (Cassini Regio center)
    img = np.asarray(Image.open(albedo_path).convert("L"), float)
    ih, iw = img.shape
    eq = img[int(ih * 0.45):int(ih * 0.55)].mean(axis=0)
    k = max(1, iw // 36)
    pad = np.r_[eq[-k:], eq, eq[:k]]
    eqs = np.convolve(pad, np.ones(2 * k + 1) / (2 * k + 1), "same")[k:-k]
    lon_dark = (np.argmin(eqs) + 0.5) / iw * 360.0

    # idealized ridge: gaussian in latitude, smooth plateau+taper in longitude
    dlon = (LON - lon_dark + 180.0) % 360.0 - 180.0
    win = np.clip((RIDGE_LON_HALFWIDTH_DEG - np.abs(dlon)) / RIDGE_LON_TAPER_DEG, 0.0, 1.0)
    win = 0.5 - 0.5 * np.cos(np.pi * win)                 # smoothstep
    ridge = RIDGE_PEAK_M * np.exp(-(LAT / RIDGE_LAT_SIGMA_DEG) ** 2) * win
    height_m = height_m + ridge

    tifffile.imwrite(out_path, height_m.astype(np.float32))
    print(f"dark Cassini Regio center ~ {lon_dark:.0f} deg lon")
    print(f"height range {height_m.min():.0f} .. {height_m.max():.0f} m  (ref {REF} km)")
    print(f"wrote {out_path}")


if __name__ == "__main__":
    main()
