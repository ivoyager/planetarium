# build_body_model.py
# This file is part of I, Voyager (https://ivoyager.dev)
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield
# Licensed under the Apache License, Version 2.0 (the "License").
# *****************************************************************************
"""Build a custom body model (.glb) from an equirectangular DEM + albedo map.

Produces a displaced ellipsoid mesh whose vertices are in kilometers (so the
model drops into ivoyager at model_scale = 1000 m, exactly like the existing
NASA-derived models, e.g. Mimas.1_1000.glb), with the albedo and a DEM-derived
tangent-space normal map embedded in the glb material.

Frame conventions (matched to ivoyager_core):
  - Mesh authored Y-up (north pole = +Y). IVPhysicalBody applies rotX(+90 deg),
    sending +Y -> +Z (the engine's north). See physical_body.gd.
  - The generic spheroid additionally gets rotY(-90 deg - map_offset); we bake
    that same longitude rotation into the mesh so a built model reproduces the
    known-correct spheroid orientation. map_offset defaults to 0.
  - Albedo and DEM are both sampled by the same horizontal UV (u -> longitude),
    so displacement always aligns with the albedo regardless of the geometric
    seam; only the body's physical longitude depends on the seam (verify in-app).

Honest missing data: DEM nodata samples produce zero displacement, leaving that
region on the reference sphere -- matching the grey-grid / featureless albedo of
unimaged hemispheres (Pluto, Charon, Voyager-era moons).

Modes:
  mesh    displaced mesh + a *detail* normal map (high-frequency residual the
          tessellation can't carry), embedded in the glb. The default build.
  normal  emit only a *full* equirectangular normal map (all topographic scales)
          for the deferred "generic spheroid + normal map" phase; no mesh.
"""

import argparse
import io
import math
import struct
import sys
from pathlib import Path

import numpy as np
from PIL import Image
import tifffile
import pygltflib as gl

Image.MAX_IMAGE_PIXELS = None  # planetary maps exceed Pillow's decompression guard


# ----------------------------------------------------------------------------- DEM

def read_dem(path, max_width, nodata=None):
    """Return (dem, nodata_mask). dem is float64 height-in-DN-units above the
    reference sphere, north-up rows; nodata samples are set to 0 (reference) BEFORE
    downsampling so unimaged regions stay on the reference sphere and the data edge
    ramps cleanly. nodata_mask is a bool array (True = unimaged) at the same
    downsampled resolution, or None. Block-mean downsampled to max_width."""
    arr = tifffile.imread(path)
    if arr.ndim == 3:
        arr = arr[..., 0]
    arr = np.asarray(arr)
    mask = (arr == nodata) if nodata is not None else None
    if mask is not None:
        arr = np.where(mask, 0, arr)  # unimaged -> reference sphere (spherical)
    h, w = arr.shape
    if w > max_width:
        factor = int(math.ceil(w / max_width))
        h2, w2 = (h // factor) * factor, (w // factor) * factor
        blocks = arr[:h2, :w2].reshape(h2 // factor, factor, w2 // factor, factor)
        # Block-mean via a float64 sum-reduce rather than arr.astype(float64).mean():
        # the latter first materializes a full-size float64 copy (~8.5 GB for the 2 GB
        # Mars MOLA DEM) and can OOM. sum(dtype=float64) accumulates straight into the
        # small downsampled output and works for int or float source DEMs alike.
        arr = blocks.sum(axis=(1, 3), dtype=np.float64) / (factor * factor)
        if mask is not None:
            mblocks = mask[:h2, :w2].reshape(h2 // factor, factor, w2 // factor, factor)
            mask = mblocks.sum(axis=(1, 3)) > (factor * factor) / 2.0
    return arr.astype(np.float64), mask


def bilinear_equirect(img, lon01, lat01):
    """Sample img (north-up, [H,W]) at fractional longitude lon01 in [0,1)
    (wraps) and latitude lat01 in [0,1] (0=north). Vectorized."""
    h, w = img.shape
    fx = (lon01 % 1.0) * w - 0.5
    fy = np.clip(lat01 * (h - 1), 0, h - 1)
    x0 = np.floor(fx).astype(int)
    y0 = np.floor(fy).astype(int)
    tx = fx - x0
    ty = fy - y0
    x0m = x0 % w
    x1m = (x0 + 1) % w
    y0c = np.clip(y0, 0, h - 1)
    y1c = np.clip(y0 + 1, 0, h - 1)
    top = img[y0c, x0m] * (1 - tx) + img[y0c, x1m] * tx
    bot = img[y1c, x0m] * (1 - tx) + img[y1c, x1m] * tx
    return top * (1 - ty) + bot * ty


# ----------------------------------------------------------------------------- normal map

def make_normal_map(height_m, ref_radius_m, out_w, invert_y, detail_blur_px):
    """Tangent-space OpenGL normal map (R=east slope, G=north slope, B=up) from
    a height field in meters on a sphere of ref_radius_m. If detail_blur_px > 0,
    high-pass the height first so the map carries only detail finer than the
    mesh tessellation (avoids double-counting displaced relief)."""
    # resample height to the requested normal-map resolution
    hh, hw = height_m.shape
    out_h = out_w // 2
    yy = np.linspace(0, 1, out_h)
    xx = np.linspace(0, 1, out_w, endpoint=False)
    gx, gy = np.meshgrid(xx, yy)
    H = bilinear_equirect(height_m, gx, gy)
    if detail_blur_px and detail_blur_px > 1:
        H = H - _box_blur_wrap(H, int(detail_blur_px))
    lat = (0.5 - yy) * math.pi  # +pi/2 north .. -pi/2 south
    coslat = np.clip(np.cos(lat), 1e-4, None)[:, None]
    # metric pixel spacing (meters)
    dx = (2.0 * math.pi * ref_radius_m * coslat) / out_w   # east, per column
    dy = (math.pi * ref_radius_m) / out_h                  # north, per row
    dHdx = (np.roll(H, -1, 1) - np.roll(H, 1, 1)) / (2 * dx)
    dHdy = np.empty_like(H)
    dHdy[1:-1] = (H[2:] - H[:-2]) / (2 * dy)
    dHdy[0] = (H[1] - H[0]) / dy
    dHdy[-1] = (H[-1] - H[-2]) / dy
    nx = -dHdx
    ny = dHdy if invert_y else -dHdy  # image v increases southward
    nz = np.ones_like(H)
    inv = 1.0 / np.sqrt(nx * nx + ny * ny + nz * nz)
    rgb = np.empty((out_h, out_w, 3), np.uint8)
    rgb[..., 0] = np.clip((nx * inv) * 0.5 + 0.5, 0, 1) * 255
    rgb[..., 1] = np.clip((ny * inv) * 0.5 + 0.5, 0, 1) * 255
    rgb[..., 2] = np.clip((nz * inv) * 0.5 + 0.5, 0, 1) * 255
    return Image.fromarray(rgb, "RGB")


def _box_blur_wrap(a, r):
    """Separable box blur; wraps in x (longitude), clamps in y (latitude)."""
    k = 2 * r + 1
    # x (wrap): prefix sums with a leading zero column keep the output width = W
    pad = np.concatenate([a[:, -r:], a, a[:, :r]], axis=1)
    c = np.zeros((a.shape[0], pad.shape[1] + 1))
    c[:, 1:] = np.cumsum(pad, axis=1)
    a = (c[:, k:] - c[:, :-k]) / k
    # y (clamp at poles)
    pad = np.concatenate([np.repeat(a[:1], r, 0), a, np.repeat(a[-1:], r, 0)], axis=0)
    c = np.zeros((pad.shape[0] + 1, a.shape[1]))
    c[1:, :] = np.cumsum(pad, axis=0)
    return (c[k:] - c[:-k]) / k


# ----------------------------------------------------------------------------- mesh

def build_mesh(dem, ref_radius_km, vert_unit_km, add_km,
               lon_seg, lat_seg, exaggeration, phi0, u_dir):
    """Equirectangular UV sphere (north +Y), displaced to true radius in km.
    Returns positions(km), uvs, faces, and per-vertex radius stats."""
    js = np.arange(lon_seg + 1)
    iss = np.arange(lat_seg + 1)
    u = js / lon_seg                       # 0..1 longitude (seam duplicated)
    v = iss / lat_seg                       # 0..1, 0=north
    U, V = np.meshgrid(u, v)               # [rows, cols]

    if dem is not None:
        dn = bilinear_equirect(dem, U, V)
        height_km = dn * vert_unit_km + add_km
        radius = ref_radius_km + height_km * exaggeration
    else:
        radius = np.full(U.shape, ref_radius_km)

    theta = math.pi * V                    # 0 north .. pi south
    phi = phi0 + u_dir * (2 * math.pi) * U
    sin_t = np.sin(theta)
    dirx = sin_t * np.cos(phi)
    diry = np.cos(theta)
    dirz = sin_t * np.sin(phi)
    pos = np.stack([dirx * radius, diry * radius, dirz * radius], -1).reshape(-1, 3)
    uv = np.stack([U, V], -1).reshape(-1, 2)

    # grid faces (two tris per quad); drop degenerate tris at the poles
    cols = lon_seg + 1
    i0 = (iss[:-1, None] * cols + js[None, :-1]).ravel()
    i1 = i0 + 1
    i2 = i0 + cols
    i3 = i2 + 1
    # CCW when viewed from outside (glTF/Godot front-face convention) so that
    # back-face culling keeps the outer surface and computed normals point out.
    faces = np.concatenate([np.stack([i0, i3, i2], -1),
                            np.stack([i0, i1, i3], -1)], 0)
    a, b, c = pos[faces[:, 0]], pos[faces[:, 1]], pos[faces[:, 2]]
    area = np.linalg.norm(np.cross(b - a, c - a), axis=1)
    faces = faces[area > 1e-9]
    return pos.astype(np.float32), uv.astype(np.float32), faces.astype(np.uint32), radius


def vertex_normals(pos, faces):
    n = np.zeros(pos.shape, np.float64)
    a, b, c = pos[faces[:, 0]], pos[faces[:, 1]], pos[faces[:, 2]]
    fn = np.cross(b - a, c - a)            # area-weighted
    for k in range(3):
        np.add.at(n, faces[:, k], fn)
    ln = np.linalg.norm(n, axis=1, keepdims=True)
    bad = (ln[:, 0] < 1e-12)
    n[bad] = pos[bad]                       # fall back to radial (poles)
    ln = np.linalg.norm(n, axis=1, keepdims=True)
    return (n / np.clip(ln, 1e-12, None)).astype(np.float32)


# ----------------------------------------------------------------------------- glb

def _pad(b):
    return b + b"\x00" * ((4 - len(b) % 4) % 4)


def write_glb(path, pos, nrm, uv, faces, albedo_png_bytes, albedo_mime,
              normal_png_bytes, metallic, roughness, name):
    blobs, views, accessors = [], [], []
    offset = 0

    def add_view(data, target=None):
        nonlocal offset
        data = _pad(data)
        views.append(gl.BufferView(buffer=0, byteOffset=offset,
                                   byteLength=len(data), target=target))
        blobs.append(data)
        offset += len(data)
        return len(views) - 1

    # vertex attributes
    pv = add_view(pos.tobytes(), gl.ARRAY_BUFFER)
    accessors.append(gl.Accessor(bufferView=pv, componentType=gl.FLOAT, count=len(pos),
                                 type=gl.VEC3, min=pos.min(0).tolist(), max=pos.max(0).tolist()))
    nv = add_view(nrm.tobytes(), gl.ARRAY_BUFFER)
    accessors.append(gl.Accessor(bufferView=nv, componentType=gl.FLOAT, count=len(nrm), type=gl.VEC3))
    tv = add_view(uv.tobytes(), gl.ARRAY_BUFFER)
    accessors.append(gl.Accessor(bufferView=tv, componentType=gl.FLOAT, count=len(uv), type=gl.VEC2))
    iv = add_view(faces.ravel().tobytes(), gl.ELEMENT_ARRAY_BUFFER)
    accessors.append(gl.Accessor(bufferView=iv, componentType=gl.UNSIGNED_INT,
                                 count=faces.size, type=gl.SCALAR))
    POS, NRM, UV, IDX = 0, 1, 2, 3

    images, textures = [], []
    pbr = gl.PbrMetallicRoughness(baseColorFactor=[1, 1, 1, 1],
                                  metallicFactor=metallic, roughnessFactor=roughness)
    material = gl.Material(name=f"{name}_mat", pbrMetallicRoughness=pbr,
                           doubleSided=False)
    sampler = gl.Sampler(wrapS=gl.REPEAT, wrapT=gl.CLAMP_TO_EDGE,
                         magFilter=gl.LINEAR, minFilter=gl.LINEAR_MIPMAP_LINEAR)
    if albedo_png_bytes is not None:
        bvi = add_view(albedo_png_bytes)
        images.append(gl.Image(bufferView=bvi, mimeType=albedo_mime, name=f"{name}_diff"))
        textures.append(gl.Texture(source=len(images) - 1, sampler=0))
        pbr.baseColorTexture = gl.TextureInfo(index=len(textures) - 1)
    if normal_png_bytes is not None:
        bvi = add_view(normal_png_bytes)
        images.append(gl.Image(bufferView=bvi, mimeType="image/png", name=f"{name}_norm"))
        textures.append(gl.Texture(source=len(images) - 1, sampler=0))
        material.normalTexture = gl.NormalMaterialTexture(index=len(textures) - 1)

    prim = gl.Primitive(attributes=gl.Attributes(POSITION=POS, NORMAL=NRM, TEXCOORD_0=UV),
                        indices=IDX, material=0)
    g = gl.GLTF2(
        asset=gl.Asset(version="2.0", generator="ivoyager build_body_model.py"),
        scenes=[gl.Scene(nodes=[0])], scene=0,
        nodes=[gl.Node(mesh=0, name=name)],
        meshes=[gl.Mesh(primitives=[prim], name=name)],
        materials=[material], textures=textures, images=images, samplers=[sampler],
        accessors=accessors, bufferViews=views,
        buffers=[gl.Buffer(byteLength=offset)],
    )
    g.set_binary_blob(b"".join(blobs))
    g.save_binary(path)


def _fill_unimaged_albedo(path, nodata_mask):
    """Fill unimaged (DEM-nodata) albedo pixels with a uniform color = the mean of
    the imaged pixels. Standard treatment for partial-coverage bodies: unimaged
    regions read as a neutral grey from the imaged terrain, not grid lines or black.
    Returns (jpeg_bytes, mime)."""
    im = np.asarray(Image.open(path).convert("RGB"), np.float64)
    h, w = im.shape[:2]
    mimg = Image.fromarray((nodata_mask.astype(np.uint8) * 255)).resize((w, h), Image.NEAREST)
    m = np.asarray(mimg) > 127
    fill = im[~m].mean(axis=0)
    im[m] = fill
    out = Image.fromarray(np.clip(im, 0, 255).astype(np.uint8), "RGB")
    buf = io.BytesIO(); out.save(buf, "JPEG", quality=92)
    print(f"  grey-filled {m.mean()*100:.0f}% unimaged albedo with rgb {fill.round().astype(int).tolist()}")
    return buf.getvalue(), "image/jpeg"


# ----------------------------------------------------------------------------- main

def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--name", required=True, help="Body file prefix, e.g. Ceres")
    p.add_argument("--dem", help="Equirectangular DEM GeoTIFF (north-up)")
    p.add_argument("--albedo", help="Equirectangular albedo image to embed")
    p.add_argument("--ref-radius-km", type=float, help="DEM reference sphere radius (km)")
    p.add_argument("--dem-vert-unit-m", type=float, default=1.0,
                   help="meters per DEM DN unit (default 1.0)")
    p.add_argument("--dem-add-m", type=float, default=0.0, help="meters added to DN")
    p.add_argument("--nodata", type=float, default=None,
                   help="DEM nodata DN -> no displacement (stays spherical)")
    p.add_argument("--clamp-min-m", type=float, default=None,
                   help="clamp DEM heights below this many meters up to it (e.g. 0 flattens "
                        "ocean/bathymetry to a flat sea-level surface)")
    p.add_argument("--lon-seg", type=int, default=1024)
    p.add_argument("--lat-seg", type=int, default=512)
    p.add_argument("--exaggeration", type=float, default=1.0)
    p.add_argument("--mode", choices=["mesh", "normal"], default="mesh")
    p.add_argument("--normal-res", type=int, default=4096, help="normal map width")
    p.add_argument("--normal-content", choices=["full", "detail", "auto"], default="auto")
    p.add_argument("--no-normal", action="store_true",
                   help="skip the normal map (smooth/idealized models where relief is all in the mesh)")
    p.add_argument("--fill-nodata-albedo", action="store_true",
                   help="fill unimaged (nodata) albedo regions with a uniform grey = mean of imaged pixels")
    p.add_argument("--metallic", type=float, default=0.0)
    p.add_argument("--roughness", type=float, default=0.9)
    p.add_argument("--map-offset-deg", type=float, default=0.0)
    p.add_argument("--u-dir", type=int, choices=[1, -1], default=1)
    p.add_argument("--invert-normal-y", action="store_true")
    p.add_argument("--model-scale", type=int, default=1000,
                   help="for filename Name.1_<N>.glb and the file_adjustments row (m)")
    p.add_argument("--max-proc-width", type=int, default=8192)
    p.add_argument("--out-dir", default=None)
    args = p.parse_args()

    name = args.name
    out_dir = Path(args.out_dir) if args.out_dir else Path(
        "addons/ivoyager_assets/models") / name.lower()

    dem = None
    nodata_mask = None
    if args.dem:
        print(f"reading DEM {args.dem} ...")
        dem, nodata_mask = read_dem(args.dem, args.max_proc_width, args.nodata)
        print(f"  DEM {dem.shape} DN range [{dem.min():.0f}, {dem.max():.0f}]")
        if args.clamp_min_m is not None:
            # Flatten everything below the threshold (e.g. ocean-floor bathymetry) to a
            # single level so it generates no slope — a mirror-flat sea for an ocean world.
            clamp_dn = (args.clamp_min_m - args.dem_add_m) / args.dem_vert_unit_m
            dem = np.maximum(dem, clamp_dn)
            print(f"  clamped to >= {args.clamp_min_m} m -> DN range [{dem.min():.0f}, {dem.max():.0f}]")

    phi0 = math.pi - math.radians(args.map_offset_deg)
    content = args.normal_content
    if content == "auto":
        content = "detail" if args.mode == "mesh" else "full"

    # normal map
    normal_png = None
    if dem is not None and args.ref_radius_km and not args.no_normal:
        ref_m = args.ref_radius_km * 1000.0
        height_m = dem * args.dem_vert_unit_m + args.dem_add_m
        blur_px = 0
        if content == "detail":
            blur_px = max(2, args.normal_res // args.lon_seg)  # ~ mesh footprint
        print(f"building {content} normal map {args.normal_res}x{args.normal_res // 2} "
              f"(blur={blur_px}px) ...")
        nimg = make_normal_map(height_m, ref_m, args.normal_res,
                               args.invert_normal_y, blur_px)
        buf = io.BytesIO(); nimg.save(buf, "PNG", optimize=True)
        normal_png = buf.getvalue()

    if args.mode == "normal":
        # normal-only is the deliverable for "spheroid + normal" bodies: the map rides
        # the shared sphere mesh, so it lands in maps/ as Name.normal.<res>.png (the
        # asset_preloader searches "<file_prefix>.normal"). In mesh mode the normal map
        # is embedded in the glb instead, so no sidecar is written.
        if normal_png is None:
            sys.exit("normal mode requires --dem and --ref-radius-km")
        normal_dir = Path(args.out_dir) if args.out_dir else Path(
            "addons/ivoyager_assets/maps")
        normal_dir.mkdir(parents=True, exist_ok=True)
        out_path = normal_dir / f"{name}.normal.{args.normal_res}.png"
        out_path.write_bytes(normal_png)
        print(f"normal-only mode -> {out_path}  ({len(normal_png) / 1048576:.1f} MB)")
        return

    # albedo bytes (embed as-is if jpeg/png)
    albedo_bytes, albedo_mime = None, "image/png"
    if args.albedo:
        ext = Path(args.albedo).suffix.lower()
        if args.fill_nodata_albedo and nodata_mask is not None:
            albedo_bytes, albedo_mime = _fill_unimaged_albedo(args.albedo, nodata_mask)
        elif ext in (".jpg", ".jpeg"):
            albedo_bytes = Path(args.albedo).read_bytes(); albedo_mime = "image/jpeg"
        else:
            im = Image.open(args.albedo).convert("RGB")
            buf = io.BytesIO(); im.save(buf, "PNG"); albedo_bytes = buf.getvalue()

    if args.ref_radius_km is None:
        sys.exit("--ref-radius-km required for mesh mode")
    print(f"building mesh {args.lon_seg}x{args.lat_seg} ...")
    pos, uv, faces, radius = build_mesh(
        dem, args.ref_radius_km, args.dem_vert_unit_m / 1000.0, args.dem_add_m / 1000.0,
        args.lon_seg, args.lat_seg, args.exaggeration, phi0, args.u_dir)
    nrm = vertex_normals(pos.astype(np.float64), faces)

    relief = radius - radius.mean()
    print(f"  verts={len(pos)} faces={len(faces)} radius_km "
          f"[{radius.min():.2f}, {radius.max():.2f}] mean={radius.mean():.2f} "
          f"relief_std={relief.std():.3f}km")

    out_dir.mkdir(parents=True, exist_ok=True)
    out_glb = out_dir / f"{name}.1_{args.model_scale}.glb"
    write_glb(str(out_glb), pos, nrm, uv, faces, albedo_bytes, albedo_mime,
              normal_png, args.metallic, args.roughness, name)
    mb = out_glb.stat().st_size / 1048576
    print(f"\nwrote {out_glb}  ({mb:.1f} MB)")
    print("\nAdd this row to addons/ivoyager_core/tables/file_adjustments.tsv:")
    print(f"\t{out_glb.name}\t\t{args.model_scale}\t")


if __name__ == "__main__":
    main()
