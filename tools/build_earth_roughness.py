# build_earth_roughness.py
# This file is part of I, Voyager (https://ivoyager.dev)
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield
# Licensed under the Apache License, Version 2.0 (the "License").
# *****************************************************************************
"""Build Earth's surface roughness map (a land/sea specular mask) from shipped maps.

Open water is smooth -> a low PBR roughness that reflects the Sun as a glint; land,
ice and snow are matte -> high roughness. The only real per-pixel roughness signal on
a natural solar-system body is this liquid-water boundary, so the map is essentially a
land/sea mask quantized to two roughness levels (StandardMaterial3D multiplies it by
the material's roughness scalar, which is left at the Godot default 1.0 for Earth).

Reproducible from data already in the repo (no external download), so the coastline
tracks the existing maps exactly. Water = flat-normal AND blue-dark-albedo:
  - Earth.normal.4096.png  ocean was flattened to sea level when this was built
    (build_body_model.py --clamp-min-m 0), so ocean reads as flat tangent-normal
    (~127,127,255) while land keeps relief. Derived from NOAA ETOPO 2022.
  - Earth.albedo.8192.jpg   ocean is blue-dominant and dark; this disambiguates flat
    land (deserts and plains also quantize flat) from sea. NASA Blue Marble NG.

Output is LINEAR roughness in an 8-bit grayscale PNG. Import it as a NON-sRGB data
texture: compress/channel_pack=1 (Optimized) so the VRAM format is linear, not sRGB
(the body materials bind textures at runtime, so Godot's editor "Detect 3D" pass that
would otherwise fix this never fires). See Earth.roughness.<res>.png.import.
"""

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

Image.MAX_IMAGE_PIXELS = None  # planetary maps exceed Pillow's decompression guard

MAPS = Path("addons/ivoyager_assets/maps")


def build(normal_path, albedo_path, ocean_roughness, land_roughness,
          feather_px, flat_tol, lum_max):
    norm = np.asarray(Image.open(normal_path).convert("RGB"))
    height, width = norm.shape[:2]
    nr = norm[..., 0].astype(int)
    ng = norm[..., 1].astype(int)
    # ocean was clamped flat, so its tangent X/Y sit at the neutral midpoint (~127)
    flat = (np.abs(nr - 127) <= flat_tol) & (np.abs(ng - 127) <= flat_tol)

    albedo = Image.open(albedo_path).convert("RGB").resize((width, height), Image.BILINEAR)
    albedo = np.asarray(albedo).astype(int)
    ar, ag, ab = albedo[..., 0], albedo[..., 1], albedo[..., 2]
    luminance = ar * 0.299 + ag * 0.587 + ab * 0.114
    blue_dark = (ab > ar) & (ab > ag - 6) & (luminance < lum_max)

    water = flat & blue_dark
    roughness = np.where(water, ocean_roughness, land_roughness).astype(np.float32)
    image = Image.fromarray((np.clip(roughness, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8), "L")
    if feather_px > 0:
        # soften the coastline so the specular cutoff is anti-aliased, not a hard ring
        image = image.filter(ImageFilter.GaussianBlur(feather_px))
    print(f"  {width}x{height}: water = {water.mean() * 100:.1f}% of pixels; "
          f"roughness ocean={ocean_roughness} land={land_roughness}")
    return image, width


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--normal", default=str(MAPS / "Earth.normal.4096.png"))
    p.add_argument("--albedo", default=str(MAPS / "Earth.albedo.8192.jpg"))
    p.add_argument("--out-dir", default=str(MAPS))
    p.add_argument("--ocean-roughness", type=float, default=0.35)
    p.add_argument("--land-roughness", type=float, default=0.95)
    p.add_argument("--feather-px", type=float, default=1.5, help="coastline Gaussian blur radius")
    p.add_argument("--flat-tol", type=int, default=2, help="tangent-normal tolerance for 'flat'")
    p.add_argument("--lum-max", type=float, default=120.0, help="max albedo luminance counted as sea")
    args = p.parse_args()

    image, width = build(args.normal, args.albedo, args.ocean_roughness,
                         args.land_roughness, args.feather_px, args.flat_tol, args.lum_max)
    out_path = Path(args.out_dir) / f"Earth.roughness.{width}.png"
    image.save(out_path, "PNG", optimize=True)
    print(f"wrote {out_path}  ({out_path.stat().st_size / 1024:.0f} KB)")


if __name__ == "__main__":
    main()
