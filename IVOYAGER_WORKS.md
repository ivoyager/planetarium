# I, Voyager Original Works and Source-Data Attribution

This document catalogs files whose **content originates with I, Voyager** — created by Charlie Whitfield rather than obtained from a third party — together with attribution of the public-domain source data from which they were derived. It also documents I, Voyager-generated derivative outputs (the 2D body icons and the cube-face reprojections), whose copyright and license follow their source, documented in [3RD_PARTY.md](3RD_PARTY.md) where that source is third-party.

A third party's image remains that party's work even after I, Voyager processes it, and is documented in [3RD_PARTY.md](3RD_PARTY.md). General acknowledgments are in [CREDITS.md](CREDITS.md).

The master version of this file is maintained [here](https://github.com/ivoyager/asset_downloads/blob/master/IVOYAGER_WORKS.md).

**Contact:** Charlie Whitfield (mail@ivoyager.dev)

Unless a specific entry below states otherwise, the files in this document are:

- **Copyright:** © Charlie Whitfield (I, Voyager); any underlying source data is U.S. Government / public domain.
- **License:** [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0) (see [LICENSE.txt](LICENSE.txt)); Public Domain for the underlying source data.

These files are distributed from [this repository](https://github.com/ivoyager/asset_downloads) in two packages: `ivoyager_assets`, which installs at `/addons/ivoyager_assets/` in project development builds, and `ivoyager_originated_extras`, which carries the I, Voyager-originated equirectangular map masters from which the corresponding cubemaps are baked.

---

## Europa

The Europa surface map is an I, Voyager original, built from public-domain imagery. It ships as an equirectangular master in `ivoyager_originated_extras` and as the `/cubemaps/Europa.albedo.2048.png` cubemap baked from it in `ivoyager_assets`. Its detail comes from the USGS controlled Voyager/Galileo mosaics of Europa (Bland et al., 2021, released CC0) and the earlier global 500 m monochrome mosaic (Becker et al., 2010), both reprojected from NASA/JPL Galileo SSI and Voyager data. Björn Jónsson's global color map, published by [The Planetary Society](https://www.planetary.org/space-images/color-global-map-of-europa), and his [account of making it](https://www.planetary.org/articles/0218-mapping-europa) guided our method — in particular his technique of carrying low-resolution filter color on a high-resolution grayscale intensity layer.

We build the map from the public-domain data directly. Surface detail is the 500 m controlled monochrome mosaic. No public-domain global *color* map of Europa exists — Galileo's color coverage is sparse, and where it exists it carries little usable per-pixel structure — so we set the color to Europa's true disk average from published photometry: a pale warm-white, linear RGB 1.05 : 1.00 : 0.87, derived from Cassini ISS geometric albedos (Mayorga et al., 2021) and cross-checked against Jupiter's color indices and a Cassini image of the two bodies together. Onto that average we add a gentle reddening of the darker chaos and lineae — physically expected, but finer than the color data resolves, and so an honest reconstruction rather than a measurement. The unimaged south-polar region is left a flat average color.

---

## Body models and surface-relief maps

The 3D body models and surface-relief maps in this section are original works created for I, Voyager. They are not third-party works. They are listed here to attribute the public-domain source data from which they were derived — chiefly NASA mission data (governed by the [NASA Images and Media Usage Guidelines](https://www.nasa.gov/nasa-brand-center/images-and-media/)), plus the NOAA ETOPO 2022 global relief model for the Earth maps. Each custom model directory also contains a NASA albedo (diffuse) texture (the `*_diff.jpg` file) embedded in the model; those textures are public-domain NASA imagery documented in [3RD_PARTY.md](3RD_PARTY.md) under "Embedded maps in I, Voyager models," not I, Voyager works. Everything else in these directories (the `.glb` model and any baked normal map) is an I, Voyager work.

### Custom body models (`.glb`)

- `/models/ceres/*` — derived from the Dawn Framing Camera HAMO global Digital Terrain Model (Preusker et al., 2016; NASA/JPL-Caltech/UCLA/MPS/DLR/IDA).
- `/models/charon/*` — derived from the New Horizons LORRI/MVIC global Digital Elevation Model (Schenk et al., 2018; NASA/Johns Hopkins APL/SwRI).
- `/models/iapetus/*` — an idealized figure based on the published triaxial radii of Thomas et al. (2007); no global Iapetus elevation model is publicly available.
- `/models/phoebe/*` — derived from the Gaskell stereophotoclinometry shape model (R. Gaskell, Cassini ISS; PDS Small Bodies Node dataset CO-SA-ISSNA-5-PHOEBESHAPE-V2.0).

### Surface-normal (bump) maps

For shaded relief on the shared spheroid mesh:

- `/cubemaps/Moon.normal.1024.png` — derived from LRO LOLA topography (NASA Scientific Visualization Studio, CGI Moon Kit).
- `/cubemaps/Mercury.normal.512.png` — derived from MESSENGER global topography (NASA/JHUAPL/Carnegie Institution of Washington; USGS Astrogeology DEM).
- `/cubemaps/Mars.normal.1024.png` — derived from MGS MOLA global topography (NASA/JPL/GSFC MOLA Science Team; USGS Astrogeology DEM).
- `/cubemaps/Enceladus.normal.512.png` — derived from Cassini ISS global topography (Schenk, 2024; NASA/JPL-Caltech/Space Science Institute).
- `/cubemaps/Earth.normal.1024.png` — derived from the NOAA ETOPO 2022 global relief model (60 arc-second ice surface; NOAA National Centers for Environmental Information), with ocean bathymetry flattened to sea level.

### Surface roughness map

For the specular Sun-glint on open water (smooth water; matte land, ice and snow):

- `/cubemaps/Earth.roughness.1024.png` — a land/sea mask derived from the `Earth.normal` relief map (NOAA ETOPO 2022, ocean flattened to sea level) and the `Earth.albedo` ocean color (NASA Blue Marble Next Generation): open water reads smooth (specular), land and ice matte.

---

## Other original assets

- `/cubemaps/Titan.albedo.512.png` — original I, Voyager surface map for Titan.
- `/cubemaps/Uranus.albedo.256.png` — original I, Voyager surface map for Uranus. Voyager 2 resolved almost no detail on Uranus and no third party publishes a global map of it, so this is a synthesized latitudinal gradient rather than a reprojection of imagery.
- `/fallbacks/*` — fallback textures and models; original I, Voyager works.
- `/asteroid_binaries/*` — asteroid orbital-data binaries generated from asteroid proper-element data downloaded from the [Asteroids Dynamic Site (AstDyS)](https://newton.spacedys.com/astdys). Please attribute Asteroids Dynamic Site (AstDyS) as the source of the underlying data.
- `/starmaps/hipparcos_stars.*.ivbinary` — star point-cloud binaries generated by I, Voyager from the [ESA Hipparcos Catalogue](https://www.cosmos.esa.int/web/hipparcos) (ESA, 1997; ESA SP-1200). Please attribute ESA / the Hipparcos mission as the source of the underlying star data (positions, magnitudes and B-V colors).
- `/rings/*` — Saturn ring shader-sampler textures generated from Saturn ring light-data created by [Björn Jónsson](https://bjj.mmedia.is/data/s_rings/index.html). Please attribute Björn Jónsson as the source of the underlying ring data.

---

## Derived cube-face reprojections

The `/cubemaps/` directory holds every world map the simulator uses, stored as a six-face cube-face strip rather than an equirectangular image so that it can be sampled by direction. Each strip was reprojected by I, Voyager from an equirectangular source image and resampled to the stored face size.

A reprojection is mechanical — a change of coordinates plus resampling — so **each cubemap carries the copyright and license of the source image it was reprojected from**:

- I, Voyager's Apache 2.0 license, for the surface-relief maps, the roughness map and `Titan.albedo` listed above;
- Public Domain, for maps built from public-domain NASA data;
- the source map's license, for maps from third-party sources (see [3RD_PARTY.md](3RD_PARTY.md) — e.g. the Björn Jónsson and James Hastings-Trew maps).

They are documented as a group rather than individually because the reprojection changes nothing about the license already documented for each source map. Editorial changes to those source maps — color adjustment, added grid lines, size reduction — are noted where the map itself is documented.

---

## Derived 2D body icons

The `/bodies_2d/` directory contains one small flat-image icon per body (`<Body>.256.png`), used in the GUI. Each icon is rendered by I, Voyager from that body's 3D model or surface map, so — as a derivative work — **each icon carries the same copyright and license as the source body asset it was rendered from**:

- Public Domain, for bodies built from public-domain NASA data;
- the source map's license, for bodies textured from third-party maps (see [3RD_PARTY.md](3RD_PARTY.md) — e.g. the Björn Jónsson and James Hastings-Trew maps);
- I, Voyager's Apache 2.0 license, for bodies built from the I, Voyager original models and maps listed above.

They are documented as a group rather than individually because each simply inherits the license already documented for its source body.
