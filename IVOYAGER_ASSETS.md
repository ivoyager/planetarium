# I, Voyager Assets

This document describes every file I, Voyager distributes as an asset: what it is, what it was
made from, and what we did to make it. It is the detailed record. [3RD_PARTY.md](3RD_PARTY.md)
is the short one — third-party content listed by copyright holder and license, with the license
texts in full — and [CREDITS.md](CREDITS.md) acknowledges the agencies, catalogs and published
measurements our work rests on that never become a file.

Entries are grouped by what a file **is** — a surface map, a mesh, an icon — not by who owns it.
Each entry ends with its own copyright and license. Many files blend third-party content with
I, Voyager content, and those entries say which part is which.

The master version of this file is maintained [here](https://github.com/ivoyager/asset_downloads/blob/master/IVOYAGER_ASSETS.md).

**Contact:** Charlie Whitfield (mail@ivoyager.dev)

## The two distributions

Both are distributed from [this repository](https://github.com/ivoyager/asset_downloads).

- **`ivoyager_assets`** installs at `/addons/ivoyager_assets/` in project development builds and
  holds everything the simulator loads. Paths below beginning with `/` are relative to it.
- **`ivoyager_originated_extras`** carries the I, Voyager-originated equirectangular map masters
  from which the corresponding cubemaps are baked. Nothing needs it to run.

---

## How the surface maps are stored

Four things are true of every map in `/cubemaps/` and are not repeated in the entries below.

**Cube-face strips.** Each map is stored as a six-face cube-face strip rather than as an
equirectangular image, mainly to keep the poles free of the artifacts an equirectangular
projection produces there. Reprojecting is a change of coordinates plus a resample; it does not
alter the copyright or license of the underlying image. The number in a file name — `.512.`,
`.1024.`, `.2048.` — is the stored face size in texels.

**Latitude.** The renderer indexes a body's map on a unit sphere and applies flattening as a
scale, so for the oblate planets the reprojection also resamples latitude, taking a map drawn on
the planet's flattened figure onto the sphere the renderer uses. The correction reaches about 3°
on Saturn and 2° on Jupiter, and is below a fifth of a degree on Earth and Mars.

**Level.** Each map is scaled in linear light so that its solid-angle-weighted sphere-averaged
reflectance equals the body's V-band geometric albedo — the convention I, Voyager's physically
calibrated lighting meters against. A catalog geometric albedo is a zero-phase quantity, so a map
carries its own body's opposition surge as a level, and the brightest icy moons legitimately
exceed reflectance 1.0. Some downloaded maps are drawn with more brightness contrast than their
body has reflectance range, so scaling alone would drive ordinary terrain past white; those have
their luminance compressed by a power law, chosen as the least compression that reaches the
level, with each pixel's color left untouched. **Earth** is the one map still well below its
published albedo — its source is a land product whose ocean is a painted placeholder. Both the
scaling and the power law are noted in the entries where they matter.

**Range tags.** Where a file name carries trailing letter-and-digit groups such as
`.l01489.lg01953.lb00596.h19227.hg17805.hb15788`, the image is stored scaled into the range of
reflectance it actually covers, and those groups name that range so the renderer restores the
original values exactly. It is a storage convention and nothing else: it buys code density on a
map that occupies only part of the scale, and it is the only way to store reflectance above 1.0
at all. A tagged file does not look like what it renders.

---

## Surface albedo maps

One entry per body. A body whose map rides a custom mesh is sampled by surface direction rather
than wrapped on a sphere; its mesh and relief map are documented under *Body meshes* below.

### Ariel — `/cubemaps/Ariel.albedo.512.png`

Paul Schenk's controlled Voyager 2 global mosaic of Ariel, from the Lunar and Planetary
Institute. We interpolated away the Voyager camera's réseau marks, trimmed the ragged
frame-coverage fringe and the terminator fade at the data edge, and filled the hemisphere Voyager
never imaged with a flat tone taken from the body's own average. The mosaic is monochrome, so we
applied Ariel's true disk-average color, linear RGB 1.0230 : 0.9970 : 0.9623, integrated against
the CIE 1931 observer from the ground-based optical reflectance spectra of Cartwright et al.
Level is Ariel's V geometric albedo of 0.53, reached by luminance compression.

- **Third-party:** the mosaic's detail and luminance — Paul Schenk, Lunar and Planetary
  Institute; underlying imagery NASA/JPL. No license asserted; please cite Schenk & Moore (2020).
- **I, Voyager:** the disk-average color and the photometric level. No separate copyright is
  asserted over them.

### Callisto — `/cubemaps/Callisto.albedo.512.png`

Björn Jónsson's global map of Callisto, assembled and color-corrected by him from spacecraft
frames. Reprojected and otherwise unchanged: its level already matched Callisto's V geometric
albedo of 0.17. No public-domain global *color* map of Callisto exists, and a flat tint over the
public greyscale mosaic would erase real surface color.

- **Third-party:** the whole image — © Björn Jónsson, used under his notice (see
  [3RD_PARTY.md](3RD_PARTY.md)). Please credit Björn Jónsson.

### Ceres — `/cubemaps/Ceres.albedo.512.png`

A true-color composite built from four public-domain Dawn Framing Camera HAMO mosaics (Roatsch et
al., NASA Planetary Data System): the clear-filter mosaic supplies luminance and detail, and the
F7/F2/F8 filters at 653/555/438 nm supply per-pixel hue through the CIE color-matching functions,
after the method of Schröder et al. (2017). Ceres has real visible color variation — blue fresh
craters against faintly red terrain — so it earns a per-pixel build rather than a flat tint.
Within the unimaged south-polar gap in the F8 mosaic the blue channel is synthesized from the
global blue/green ratio. The south pole itself sat in seasonal shadow throughout the Dawn mission
and is filled with a flat tone at the body's own average. Level is Ceres' V geometric albedo of
0.090. Rides a custom mesh.

- **Third-party:** all image content — Public Domain (NASA/JPL-Caltech/UCLA/MPS/DLR/IDA); please
  cite Roatsch et al.
- **I, Voyager:** the recombination and calibration. No separate copyright is asserted — every
  value derives from the Dawn mosaics.

### Charon — `/cubemaps/Charon.albedo.512.png`

The New Horizons global color map embedded in the NASA 3D Resources Charon model — the encounter
hemisphere plus the reddish Mordor Macula north polar cap. Only one hemisphere was well imaged by
the 2015 flyby and the remainder carries a neutral grey fill. One unimaged pocket near 35°S was
left black in the download with cartographic grid lines drawn across it; we extended the flat
fill over both, and flattened the relief map to match so that no terrain is shaded over ground
the albedo no longer claims. The imaged terrain is otherwise unchanged. Level is Charon's V
geometric albedo of 0.38. Rides a custom mesh.

- **Third-party:** the imagery — Public Domain (NASA/Johns Hopkins APL/Southwest Research
  Institute).

### Deimos — `/cubemaps/Deimos.albedo.512.png`

Philip Stooke's controlled global Viking Orbiter / Mars Reconnaissance Orbiter mosaic, from the
NASA PDS. Stooke notes that where images of opposing illumination meet, artistic blending was
applied to appearance though not to map geometry. We divided out the residual latitudinal
illumination the mosaic carries, referenced to the illumination-free relative albedo of the Ernst
et al. (2023) stereophotoclinometry solution, and applied the true disk-average color shared with
Phobos: linear RGB 1.021 : 1.005 : 0.887, a warm grey-brown, integrated against the CIE 1931
observer from Phobos' published per-filter HRSC geometric albedos at 440/530/750 nm (Fernando et
al. 2024). Level is Deimos' V geometric albedo of 0.068. Rides a custom mesh.

- **Third-party:** the mosaic's detail and luminance — Public Domain (NASA PDS); please cite
  Stooke.
- **I, Voyager:** the illumination correction, the disk-average color and the level. No separate
  copyright is asserted over them.

### Dione — `/cubemaps/Dione.albedo.1024.l01489.lg01953.lb00596.h19227.hg17805.hb15788.png`

The first global color mosaic of Dione, assembled from Cassini's first ten years at Saturn and
released as PIA18434. NASA's caption records that "image selection, radiometric calibration,
geographic registration and photometric correction, as well as mosaic selection and assembly were
performed by Paul Schenk at the Lunar and Planetary Institute."

The released mosaic's color is enhanced relative to human vision, and what is enhanced is
measurable: it is a per-channel contrast stretch in which blue's response to brightness runs
about seven times its natural rate, so the darker the terrain the less blue survives it. We undid
it — each channel's hue-versus-brightness spread compressed until it matches the statistics of
natural color, then every texel given the color of the smooth reflectance spectrum with its own
red/blue ratio, which keeps the map's per-texel spectral slope and discards only a residual green
that no smooth spectrum can produce. The remaining warmth is kept as measured, implying a
reflectance slope of +0.117 per 100 nm. Level is Dione's V geometric albedo of 0.998; most of the
surface then exceeds reflectance 1.0, which is what the range tag carries.

- **Third-party:** the imagery — Public Domain. Please credit NASA/JPL-Caltech/Space Science
  Institute/Lunar and Planetary Institute.
- **I, Voyager:** the color correction and the level. No separate copyright is asserted — the
  correction removes an enhancement rather than adding content.

### Earth — `/cubemaps/Earth.albedo.2048.png`

Blue Marble Next Generation, July 2004, from the NASA Earth Observatory (imagery by Reto
Stöckli). Blue Marble is a MODIS *land* product: its ocean is a painted placeholder — one flat
near-black triple over 58 % of the map — rather than measured water color. The water (ocean and
inland alike, the latter located with the help of Natural Earth's public-domain lake polygons)
is raised by a fixed offset in linear light to sRGB (12, 23, 42), a level derived from the
water-leaving surface reflectance of clear ocean water, so the ocean is the same kind of
quantity as the atmospherically corrected land beside it. Every real deviation the source
carries — shelf seas, polar waters, turbid lakes and river plumes — rides through the offset
unchanged, and a coastal texel takes the offset in proportion to its unmixed water fraction.
Land, ice, sea ice and bright shallows are as downloaded. The map still sits below the
sphere-mean level convention; Earth's exposure is instead anchored to its cloudless continents.

- **Third-party:** the imagery — Public Domain (NASA Earth Observatory).
- **I, Voyager:** the ocean level and its coastal blending. No separate copyright is asserted —
  the correction supplies a single derived color value, not content.

### Enceladus — `/cubemaps/Enceladus.albedo.1024.h26435.png`

The first global color mosaic of Enceladus, from the same Cassini ten-year release as Dione,
issued as PIA18435. Unlike the other mosaics in that release this one carries no measurable color
enhancement and no brightness stretch, so its imagery is unaltered. Enceladus is the brightest
surface in the solar system and its zero-phase geometric albedo of 1.375 exceeds 1, so the level
correction is a pure gain that no ordinary 8-bit image can hold; it is carried entirely by the
range tag, and the stored file is the downloaded imagery's own values.

- **Third-party:** the imagery — Public Domain. Please credit NASA/JPL-Caltech/Space Science
  Institute/Lunar and Planetary Institute.

### Europa — `/cubemaps/Europa.albedo.2048.png`

Surface detail is the USGS controlled 500 m global monochrome mosaic of Europa (Becker et al.,
2010) with the later photogrammetrically controlled Voyager/Galileo mosaics (Bland et al., 2021),
both reprojected from NASA/JPL Galileo SSI and Voyager data.

The color is ours. No public-domain global *color* map of Europa exists — Galileo's color
coverage is sparse, and where it exists it carries little usable per-pixel structure — so we set
the color to Europa's true disk average from published photometry: a pale warm-white, linear RGB
1.05 : 1.00 : 0.87, derived from Cassini ISS geometric albedos (Mayorga et al., 2021) and
cross-checked against Jupiter's color indices and a Cassini image of the two bodies together.
Onto that average we add a gentle reddening of the darker chaos and lineae — physically expected,
but finer than the color data resolves, and so an honest reconstruction rather than a
measurement. The unimaged south-polar region is left a flat average color. Level is Europa's V
geometric albedo of 0.67. Björn Jónsson's published account of making his own Europa map guided
the method — in particular carrying low-resolution filter color on a high-resolution grayscale
intensity layer — but no pixel of his map is in ours.

The equirectangular master ships in `ivoyager_originated_extras` as `Europa.albedo.8192.png`.

- **Third-party:** the monochrome detail and luminance — Public Domain; the 2021 controlled
  mosaics are released CC0 (Bland, M. T., Weller, L. A., Archinal, B. A., Smith, E., Wheeler,
  B. H. (2021), *Photogrammetrically Controlled Galileo Image Mosaics of Europa*, U.S. Geological
  Survey data release, doi:10.5066/P9VKKK7C). Please cite the USGS Astrogeology Science Center.
- **I, Voyager:** the color — © Charlie Whitfield, [Apache 2.0](LICENSE.txt).

### Ganymede — `/cubemaps/Ganymede.albedo.512.png`

Björn Jónsson's global map of Ganymede, assembled and color-corrected by him from spacecraft
frames. Reprojected, with luminance compressed by a power law to reach Ganymede's V geometric
albedo of 0.43; his color is untouched. The public USGS color mosaic of Ganymede was evaluated as
a higher-resolution replacement and declined: it puts a 991 nm near-infrared band in the red
channel, which reads dark exactly where fresh water ice is bright, and its per-frame color
balance leaves visible tinted footprints. Jónsson's map carries neither.

- **Third-party:** the whole image — © Björn Jónsson, used under his notice (see
  [3RD_PARTY.md](3RD_PARTY.md)). Please credit Björn Jónsson.
- **I, Voyager:** the luminance compression and the level. No separate copyright is asserted over
  them.

### Iapetus — `/cubemaps/Iapetus.albedo.512.png`

The first global color mosaic of Iapetus, from the Cassini ten-year release, issued as PIA18436.
The imagery is unaltered. Level is Iapetus' V geometric albedo of 0.25, which is a disk average
across the body's extreme leading/trailing dichotomy. Rides a custom mesh.

- **Third-party:** the imagery — Public Domain. Please credit NASA/JPL-Caltech/Space Science
  Institute/Lunar and Planetary Institute.

### Io — `/cubemaps/Io.albedo.1024.lr00679.lg00562.h13169.hg10775.hb10724.png`

Björn Jónsson's global map of Io, assembled and color-corrected by him from spacecraft frames.
Reprojected, with luminance compressed by a power law to reach Io's V geometric albedo of 0.63.
Io is the one map whose level cannot be held in ordinary 8-bit sRGB without spending its color:
at that level the most saturated terrain needs red above 100 % reflectance, and 5.5 % of the
sphere would have to be desaturated to fit under white. The range tag stores those values
instead, so his color survives intact and no texel in the map is clipped at maximum red.

The public USGS mosaic was evaluated as a replacement and declined: its 11445-pixel grid
interpolates data ranging from 1.3 to 21 km per pixel, so over the Jupiter-facing hemisphere it
delivers less real detail than Jónsson's smaller map at the shipped face size.

- **Third-party:** the whole image — © Björn Jónsson, used under his notice (see
  [3RD_PARTY.md](3RD_PARTY.md)). Please credit Björn Jónsson.
- **I, Voyager:** the luminance compression, the level, and the desaturation of the over-unity
  remainder. No separate copyright is asserted over them.

### Jupiter — `/cubemaps/Jupiter.albedo.2048.png`

Björn Jónsson's merged Cassini and Juno map of Jupiter, published by The Planetary Society. His
color and his detail as downloaded. Level is set toward Jupiter's V geometric albedo of 0.538,
reaching 97 % of it before the map's bright tail runs out of headroom. The reprojection resamples
latitude from planetographic, about 2° at mid-latitudes — a correction confirmed against the
Great Red Spot's published planetographic latitude, which ranks it decisively against the other
two conventions.

- **Third-party:** the whole image — © Björn Jónsson. License:
  [CC-BY-3.0](3RD_PARTY.md#cc-by-30), which requires attribution. Please credit
  **NASA/JPL-Caltech/SSI/SwRI/MSSS/ASI/INAF/JIRAM/Björn Jónsson**.
- **I, Voyager:** the level and the latitude resample. No separate copyright is asserted over
  them.

### Mars — `/cubemaps/Mars.albedo.2048.png`

Detail and luminance are the USGS Viking Colorized Global Mosaic 232m (MDIM 2.1; originator NASA
Ames, publisher USGS Astrogeology) — 4,600 controlled Viking Orbiter frames.

The downloaded mosaic's color is not a measurement. USGS give its purpose as making "an
artistically colorized version" of the controlled monochrome mosaic, and it renders the dark
regions blue-dominant, which Mars is not. We kept its luminance and replaced its chromaticity
with Mars' measured true color: a spectrum fitted to the twelve published geometric albedos of
Mallama, Krobusek and Pavlov (2017) — seven Johnson-Cousins bands and five Sloan — then
integrated against the CIE 1931 observer, giving chromaticity xy (0.3925, 0.3867) and reproducing
Mars' published B−V of 1.37. Level is the same work's V geometric albedo of 0.170. The residual
polar caps are held neutral, as water and CO2 frost are across the visible, while the seasonal
frost around them — which the mosaic's source frames caught but which is gone by each pole's
summer — carries a partial ice tone instead of the full cap.

- **Third-party:** the mosaic's detail and luminance — Public Domain. Please cite the USGS
  Astrogeology Science Center.
- **I, Voyager:** the chromaticity and the level — © Charlie Whitfield, [Apache 2.0](LICENSE.txt).

### Mercury — `/cubemaps/Mercury.albedo.1024.png`

Surface detail is the USGS MESSENGER MDIS low-incidence global monochrome basemap (the "LOI"
basemap; MESSENGER Team, ASU, Johns Hopkins APL, Carnegie Institution of Washington; via USGS
Astrogeology), chosen over the shaded morphology basemap so that the albedo carries no baked
lighting — relief comes from the engine and from `Mercury.normal`.

The color is ours. No public-domain true-color global map of Mercury exists; the released
MESSENGER color mosaics are false color, either near-infrared or principal-component composites.
We set the color to Mercury's true disk-average tint, linear RGB 1.139 : 0.982 : 0.772 — a warm
tan-grey — calibrated by integrating the disk-median MDIS visible-band spectrum (the 480/560/630
nm filters, from the public-domain MDIS multispectral records) against the CIE 1931 observer
under an equal-energy illuminant. A single flat tint is the honest choice: measured local
true-color variation across Mercury is below the perceptual threshold, so surface units — rays,
plains, low-reflectance material — read through the grayscale brightness and not through color.
The permanently shadowed polar craters and the small never-imaged polar gaps are inpainted from
surrounding sunlit terrain, on the cube rather than in the equirectangular master, so the repair
leaves no polar pinch. Level is Mercury's V geometric albedo of 0.142.

The equirectangular master, with the polar repair reprojected back into it, ships in
`ivoyager_originated_extras` as `Mercury.albedo.9216.png`.

- **Third-party:** the monochrome detail and luminance — Public Domain (MESSENGER Team, ASU,
  Johns Hopkins APL, Carnegie Institution of Washington). Please cite the USGS Astrogeology
  Science Center.
- **I, Voyager:** the color and the polar reconstruction — © Charlie Whitfield,
  [Apache 2.0](LICENSE.txt).

### Mimas — `/cubemaps/Mimas.albedo.1024.lr00591.lg00784.h17892.hg17089.hb16328.png`

The first global color mosaic of Mimas, assembled from Cassini's first ten years at Saturn and
released as PIA18437 at 200 m per pixel. NASA's caption records that "image selection,
radiometric calibration, geographic registration and photometric correction, as well as mosaic
selection and assembly were performed by Paul Schenk at the Lunar and Planetary Institute."

The released mosaic's color is enhanced relative to human vision, and what is enhanced is
measurable: it is a per-channel contrast stretch in which blue's response to brightness runs
about seven times its natural rate, so the darker the terrain the less blue survives it. We undid
it — each channel's hue-versus-brightness spread compressed until it matches the statistics of
natural color, then every texel given the color of the smooth reflectance spectrum with its own
red/blue ratio, which keeps the map's per-texel spectral slope and discards only a residual green
that no smooth spectrum can produce. The remaining warmth is kept as measured, implying a
reflectance slope of +0.068 per 100 nm — shallower than Tethys and Dione (+0.12) and Rhea
(+0.17), and steeper only than Enceladus, which is the ordering E-ring ice implies. Level is Mimas' V geometric
albedo of 0.962; more than half the surface then exceeds reflectance 1.0, which is what the range
tag carries. Rides a custom mesh.

- **Third-party:** the imagery — Public Domain. Please credit NASA/JPL-Caltech/Space Science
  Institute/Lunar and Planetary Institute.
- **I, Voyager:** the color correction and the level. No separate copyright is asserted — the
  correction removes an enhancement rather than adding content.

### Miranda — `/cubemaps/Miranda.albedo.512.png`

Paul Schenk's controlled Voyager 2 global mosaic of Miranda, from the Lunar and Planetary
Institute, given the same treatment as Ariel: réseau marks interpolated away, coverage fringe and
terminator fade trimmed, unimaged hemisphere filled flat. Miranda is too faint and too close to
Uranus for ground-based optical spectroscopy, so it carries Ariel's measured tint — its nearest
neighbour in orbit and in surface character, and in any case the four measured family tints lie
within ΔE 2.3 of one another. Level is Miranda's V geometric albedo of 0.32. Rides a custom mesh.

- **Third-party:** the mosaic's detail and luminance — Paul Schenk, Lunar and Planetary
  Institute; underlying imagery NASA/JPL. No license asserted; please cite Schenk & Moore (2020).
- **I, Voyager:** the disk-average color and the photometric level. No separate copyright is
  asserted over them.

### Moon — `/cubemaps/Moon.albedo.1024.png`

The LROC WAC color mosaic in the NASA Scientific Visualization Studio CGI Moon Kit. We toned it
toward true color, restoring the terrae/mare hue differentiation that the Kit's eye-matched
balance flattened, using the public-domain LROC WAC Hapke-normalized 415/566/643 nm mosaic bands.
The Kit leaves its polar caps uncolored; we rebuilt them on the cube from the LROC WAC
polar-stereographic mosaics (WAC_GLOBAL_P900N and P900S), filling the permanently shadowed
remainder from the same kit's co-registered LOLA topography. Level is the Moon's V geometric
albedo of 0.136.

- **Third-party:** all image content — Public Domain. Color body: NASA SVS CGI Moon Kit, LROC WAC
  color. Color differentiation and polar imagery: LROC Team / Arizona State University.
- **I, Voyager:** the toning and the polar rebuild. No separate copyright is asserted — every
  value derives from LROC data.

### Oberon — `/cubemaps/Oberon.albedo.512.png`

The Uranus moon texture published in NASA 3D Resources, credited to USGS/Tammy Becker and
JPL/Caltech. The download is neutral greyscale — the faint tan seen in some copies is JPEG chroma
artifacting on neutral data, not real color — and leaves the hemisphere Voyager 2 never imaged as
plain black. We filled that black with a flat body-average tone, feathered, and applied Oberon's
measured disk-average tint, linear RGB 1.0318 : 0.9962 : 0.9436. Oberon's imaged terrain is the
most brightness-stretched in the shipped set, so its luminance is compressed harder than the
level alone would require, bringing its bright southern mid-latitude patches into line with the
neighbouring moons. Level is Oberon's V geometric albedo of 0.31 (Karkoschka 2001).

- **Third-party:** the greyscale imagery — Public Domain (USGS/Tammy Becker; JPL/Caltech).
- **I, Voyager:** the unimaged fill, the disk-average color, the luminance compression and the
  level. No separate copyright is asserted over them.

### Phobos — `/cubemaps/Phobos.albedo.512.png`

Philip Stooke's controlled global mosaic of Phobos — the DLR-controlled Viking Orbiter mosaic,
redistributed at 5 m/pixel by USGS Astrogeology — given the same treatment as Deimos: residual
latitudinal illumination divided out against the Ernst et al. (2023) stereophotoclinometry
albedo, and the shared true disk-average color, linear RGB 1.021 : 1.005 : 0.887, applied. Level
is Phobos' V geometric albedo of 0.071. Rides a custom mesh.

- **Third-party:** the mosaic's detail and luminance — Public Domain (NASA PDS); please cite
  Stooke.
- **I, Voyager:** the illumination correction, the disk-average color and the level. No separate
  copyright is asserted over them.

### Phoebe — `/cubemaps/Phoebe.albedo.512.png`

The stereophotoclinometry relative-albedo map of John R. Weirich (2023), solved over Robert
Gaskell's Cassini ISS shape model and archived at the PDS Small Bodies Node. About 27 % of the
downloaded map is unimaged black; we filled those regions with the imaged mean grey, feathered,
while leaving the small crater-floor shadows alone so real craters keep their relief. Level is
Phoebe's V geometric albedo of 0.10. Rides a custom mesh.

- **Third-party:** the albedo map — Public Domain (NASA PDS); please cite Weirich (2023).
- **I, Voyager:** the unimaged fill and the level. No separate copyright is asserted over them.

### Pluto — `/cubemaps/Pluto.albedo.1024.l00323.lg00174.lb00052.h17335.hg16561.hb16557.png`

The Pluto Global Color Map from New Horizons' Ralph/MVIC instrument, three filters, published by
NASA. That product is an enhanced-color rendering rather than a natural-color one — its own
publication, Olkin et al. (2017), describes it as "enhanced color (not natural color as perceived
by the human eye)" — and its red channel carries a near-infrared band the eye cannot see.

We kept its brightness structure, which is the real one, and rebuilt its color against what the
same camera recorded in natural color on the same flyby, measured from NASA's own
refined-calibration view of Pluto. Both how red each terrain is and how its green tracks that
redness are measured from that view rather than assumed from a spectrum, which is what keeps
Pluto's dark equatorial terrain the deep red-brown it is rather than the olive a simpler model
gives it. The relation is measured rather than fitted to a straight line: across the lower two
thirds of the map the source carries no color information the eye could use, and only above that
does color climb with it. Where the source cannot rank a terrain's color at all, the
natural-color view's own large-scale color differences are carried across directly as a stored
field — which is what preserves the yellow streaks running down from the northern polar region
and the faint tint that sets Sputnik Planitia apart from the other bright terrain.

Level is set from Pluto's published normal reflectances of 0.08 to 1.0 (Buratti et al. 2017), the
widest range of any body we ship — that is what lets its dark equatorial terrain read as dark
rather than merely brown, and it is why the map is stored range-tagged. Pluto keeps the reddish
tholin coloring it is known for, at the strength the calibrated data supports. The region New
Horizons never imaged, about a fifth of the sphere, is filled with a flat tone at the body's own
average.

- **Third-party:** the mosaic's brightness structure and detail — Public Domain (NASA/Johns
  Hopkins University Applied Physics Laboratory/Southwest Research Institute). The natural-color
  reference view is credited NASA/Johns Hopkins University Applied Physics Laboratory/Southwest
  Research Institute/Alex Parker.
- **I, Voyager:** the color reconstruction and the level — © Charlie Whitfield,
  [Apache 2.0](LICENSE.txt).

### Rhea — `/cubemaps/Rhea.albedo.1024.l01454.lg01458.lb00825.h17769.hg16166.hb13469.png`

The first global color mosaic of Rhea, from the Cassini ten-year release, issued as PIA18438. We
interpolated across the Cassini camera's réseau marks and trimmed the mosaic at its small data
gaps, then undid the color enhancement by the same method as Dione. Rhea is the family's
calibration: Björn Jónsson publishes a map of it built from genuine Cassini RGB composites, and
the corrected result agrees with his to 8 % in implied spectral slope (+0.170 against +0.156 per
100 nm). Level is Rhea's V geometric albedo of 0.949, carried by the range tag.

- **Third-party:** the imagery — Public Domain. Please credit NASA/JPL-Caltech/Space Science
  Institute/Lunar and Planetary Institute.
- **I, Voyager:** the réseau repair, the color correction and the level. No separate copyright is
  asserted over them.

### Saturn — `/cubemaps/Saturn.albedo.1024.l03864.lg03094.lb01682.h08149.hb05395.png`

Björn Jónsson's global map of Saturn, assembled and color-corrected by him from spacecraft
frames; its north polar region is Voyager 2 data from 1981, which is where the polar hexagon was
discovered. His color and his detail as downloaded, scaled to Saturn's V geometric albedo of
0.499. The reprojection resamples latitude from planetographic, about 3° at mid-latitudes — the
largest such correction in the set. Stored range-tagged, per channel: Saturn's blue occupies a
much narrower part of the scale than its red, and giving each channel its own range cuts the
error of the renderer's VRAM texture compression by more than a quarter in physical
reflectance.

- **Third-party:** the whole image — © Björn Jónsson, used under his notice (see
  [3RD_PARTY.md](3RD_PARTY.md)). Please credit Björn Jónsson.
- **I, Voyager:** the level and the latitude resample. No separate copyright is asserted over
  them.

### Tethys — `/cubemaps/Tethys.albedo.1024.h24013.hg21812.hb19627.png`

The first global color mosaic of Tethys, from the Cassini ten-year release, issued as PIA18439,
with its color enhancement undone by the same method as Dione. Level is Tethys' V geometric
albedo of 1.229. The range tag here buys almost no code density and is present for a different
reason: at that level 90 % of the map's texels exceed reflectance 1.0 and would otherwise be
clipped.

- **Third-party:** the imagery — Public Domain. Please credit NASA/JPL-Caltech/Space Science
  Institute/Lunar and Planetary Institute.
- **I, Voyager:** the color correction and the level. No separate copyright is asserted over them.

### Titania — `/cubemaps/Titania.albedo.512.png`

Paul Schenk's controlled Voyager 2 global mosaic of Titania, from the Lunar and Planetary
Institute, given the same treatment as Ariel. Its measured disk-average tint, linear RGB
1.0453 : 0.9923 : 0.9429, is the warmest of the classical Uranian moons. Luminance is compressed
by a power law to reach Titania's V geometric albedo of 0.35.

- **Third-party:** the mosaic's detail and luminance — Paul Schenk, Lunar and Planetary
  Institute; underlying imagery NASA/JPL. No license asserted; please cite Schenk & Moore (2020).
- **I, Voyager:** the disk-average color, the luminance compression and the level. No separate
  copyright is asserted over them.

### Triton — `/cubemaps/Triton.albedo.1024.l03094.lg03005.lb02462.hg09216.hb08880.png`

The USGS Voyager 2 Global Color Mosaic 600m (originators NASA, JPL and Dr. Paul Schenk; publisher
USGS Astrogeology; released as PIA18668).

The downloaded mosaic's three channels are Voyager's orange, violet and ultraviolet filters shown
as red, green and blue, which is not what the eye would see — violet light is displayed as green,
and the blue channel is light outside the visible range altogether. We discarded the ultraviolet
channel, restored the inter-filter calibration from Voyager's own disk-integrated photometry
(Nelson et al. 1990: geometric albedo 0.68 at 0.41 µm rising to 0.81 at 0.56 µm), and rebuilt
per-pixel true color by integrating the resulting spectral slope against the CIE 1931 observer,
carried on the orange band's luminance. We imposed only the disk average, so the south polar cap
keeps its real reddening against the fresher equatorial deposits. The region Voyager never imaged
is filled with a flat tone at the body's own average. Level is Triton's V geometric albedo of
0.76; the map's brightness contrast is compressed to reach it, landing within 6 % of the surface
reflectance range Hillier et al. (1994) published and which the solver never saw. Stored
range-tagged, per channel.

- **Third-party:** the mosaic's detail and luminance — Public Domain. Please cite the USGS
  Astrogeology Science Center.
- **I, Voyager:** the true-color reconstruction and the level — © Charlie Whitfield,
  [Apache 2.0](LICENSE.txt).

### Umbriel — `/cubemaps/Umbriel.albedo.512.png`

The Uranus moon texture published in NASA 3D Resources, credited to USGS/Tammy Becker and
JPL/Caltech, given the same treatment as Oberon: the unimaged hemisphere's plain black filled
with a flat body-average tone, feathered, and the moon's measured disk-average tint applied —
linear RGB 1.0089 : 1.0003 : 0.9706, the most neutral of the classical Uranian moons. Level is
Umbriel's V geometric albedo of 0.26 (Karkoschka 2001).

- **Third-party:** the greyscale imagery — Public Domain (USGS/Tammy Becker; JPL/Caltech).
- **I, Voyager:** the unimaged fill, the disk-average color and the level. No separate copyright
  is asserted over them.

### Vesta — `/cubemaps/Vesta.albedo.512.png`

A true-color composite built from the public-domain Dawn Framing Camera HAMO mosaics (Roatsch et
al., NASA PDS) by the same method as Ceres — clear-filter luminance and detail, per-pixel hue
from the F7/F2/F8 filters through the CIE color-matching functions. Dawn observed Vesta in
southern summer, so its clear-filter mosaic carries that illumination as well as albedo; we
divided out the latitudinal trend and compressed the residual shadow and glare. The north polar
cap was in polar winter throughout the mission and is filled with a flat tone at the body's own
average. Level is set toward Vesta's V geometric albedo of 0.4228, reaching 97 % of it before the
map's bright tail runs out of headroom. Rides a custom mesh.

- **Third-party:** all image content — Public Domain (NASA PDS; Roatsch et al., DLR).
- **I, Voyager:** the recombination, the illumination correction and the level. No separate
  copyright is asserted — every value derives from the Dawn mosaics.
---

## Cloud and emission overlays

### Earth clouds — `/cubemaps/Earth.clouds.albedo.2048.png`

Satellite cloud retrievals for 2019 September 23 and 24, carried as a translucent shell above
the surface map. The shell's two channels are the two independent quantities a translucent deck
needs, and both are measured rather than assumed. Alpha is MODIS's own cloud FRACTION — the
share of each 5 km box that its cloud mask calls cloudy, Terra everywhere it looked and Aqua
in the lens-shaped gaps between Terra's equatorial swaths, together 99 % of the globe. Rgb is
the reflectance of the cloud that is there, from retrieved cloud OPTICAL THICKNESS through the
standard conservative two-stream relation at a reference incidence of 60°, with ice and water
clouds taking their own scattering asymmetry. Keeping the two apart is what lets a texel half
covered by opaque cloud behave differently from one wholly covered by thin cloud, which they do
at every sun angle: the first passes full sunlight through its clear part and the second dims
it.

Optical thickness is retrieved only where the mask calls a 1 km pixel confidently overcast, so
no one satellite has much of it. Four contribute: MODIS on Terra and Aqua, and VIIRS on Suomi
NPP and NOAA-20, whose wider swath leaves no equatorial gap. Averaged, they reach 82 % of the
cloudy area, and each platform's own granule-to-granule differences average down with them.
The thickness channel is then carried as a regional field with the retrieved detail riding on
top of it, faded out over about 25 km wherever the retrieval thins — so what is measured is
shown at full detail, what is not takes its surroundings' level, and there is no boundary
between the two. An equinox date holds the region that gets no daylight retrieval at all to
about 1 % of the sphere, at the two poles.

Cloud fraction is reported over 5 km boxes, and a 5 km box is 5 km only directly beneath the
satellite: the scan stretches it to some 24 by 10 km at the edge of the swath, so the coverage
channel resolves about 10 km of ground where the map's own texel is 4.9 km, and the boxes
arrive as a mosaic lying in the satellite's frame rather than the map's. The box edges carry no
information and are dissolved, and the texel-scale structure they cannot hold is taken from
three further products of the same overpass, each of which sees cloud where the others cannot:
corrected-reflectance true colour at 250 m, band 31 brightness temperature at 1 km, and the
optical-thickness retrieval's own footprint. They are combined at weights solved separately in
each region against the cloud fraction itself, so a product contributes only where it really
does predict it — the reflectance over ocean and forest, the thermal band over desert, the
retrieval over ice, and none of them where there is no cloud to see. Together they account for
29 % of the structure the fraction still resolves; what is left is filled with a fractal field
carrying the fraction's own measured statistics, and the local mean is restored afterward, so
the coverage the retrieval actually reported is unchanged and only the structure inside a box
is new.

An instrument in a sun-synchronous orbit passes over every place at the same local time of day,
so going once around the world its observations gain a whole day: any global picture built from
one satellite has a join in it somewhere, and no processing removes that. Two consecutive days
let us choose where the join falls. It is put along the path where the two days' cloud fields
agree most closely, which wanders 155 degrees of longitude and lands where they differ by 8 % of
the global average — rather than down a meridian, where it would draw a perfectly straight line.
Global mean cloud fraction 0.62, against a published MODIS value near 0.67.

- **Third-party:** the retrievals — Public Domain (NASA).

### Neptune clouds — `/cubemaps/Neptune.clouds.albedo.512.l03864.lr02738.h09663.hg11302.hb09756.png`

Cut from Björn Jónsson's global map of Neptune. We did not use the whole map: only its light
clouds and dark spots are cut into this translucent overlay, and the banding pattern beneath it
is generated in shader code, taking his map and Voyager 2 images as references and Irwin et al.
(2024) for true color.

An overlay shell reproduces the surface beneath it only if it carries the same photometric law
and the same level, so this deck is given Neptune's lunar-Lambert disc photometry and is
re-levelled to sit against the surface it covers; the level rides in the range tag, since the
correction takes the deck's green above reflectance 1.0, which no untagged 8-bit sRGB file can
hold. It is baked with the planet's half-degree latitude warp, matching the banding it was cut
as a deviation from.

- **Third-party:** the cloud and spot imagery — © Björn Jónsson, used under his notice (see
  [3RD_PARTY.md](3RD_PARTY.md)). Please credit Björn Jónsson.
- **I, Voyager:** the extraction, the photometric level and the latitude resample. No separate
  copyright is asserted over them.

### Earth night lights — `/cubemaps/Earth.emission.1024.png`

The Black Marble 2016 grayscale (lights-only) release from the NASA Earth Observatory. We applied
a uniform warm tint — a 3000 K blackbody color — in linear light, and downsampled in linear light
so that city brightness is preserved. The grayscale product's dark regions are genuinely zero and
we subtracted no floor, so faint real sources — villages, gas flares, fishing fleets — remain.

Black Marble is assembled from ten-degree tiles and carries a small mark on each tile corner,
which the night side renders as a regular lattice of lights over open ocean; we cleared those
marks, but only where nothing else is lit anywhere near them, so no real light source is touched.
This map is imported without VRAM compression: point sources on true black are exactly the case
block compression handles worst, producing visible blocking and colored speckle that the emission
gain then amplifies.

- **Third-party:** the imagery — Public Domain (NASA Earth Observatory).
- **I, Voyager:** the tint, the resampling and the tile-mark repair. No separate copyright is
  asserted over them.

---

## Surface-relief maps

Object-space normal maps for shaded relief on the shared spheroid mesh, each computed from a
published elevation model. The relief maps that belong to the custom-mesh bodies are documented
with their meshes in the next section.

All but Io's are built from public-domain elevation data and are I, Voyager works. Unless an
entry says otherwise:

- **Copyright:** © Charlie Whitfield (I, Voyager). **License:** [Apache 2.0](LICENSE.txt). The
  underlying elevation data is public domain, cited per entry.

### `/cubemaps/Earth.normal.1024.png`

Derived from the NOAA ETOPO 2022 global relief model (60 arc-second ice surface; NOAA National
Centers for Environmental Information, released CC0), with ocean bathymetry flattened to sea
level so that only land relief is shaded.

### `/cubemaps/Enceladus.normal.512.png`

Derived from the Cassini Global DEM 200m of Schenk & McKinnon (2024), distributed by USGS
Astrogeology (NASA/JPL-Caltech/Space Science Institute).

### `/cubemaps/Io.normal.512.png`

Derived from Björn Jónsson's Io DEM, which he describes as largely fictional: a grayscale version
of his Io map processed into height, with the known mountains painted in from a catalog. We
scaled it as he recommends — black at −5 km, white at +10 km — and converted it to surface
normals. That conversion is mechanical and his height field is the map's whole content, so the
map stays his.

- **Third-party:** the whole map — © Björn Jónsson, used under his notice (see
  [3RD_PARTY.md](3RD_PARTY.md)). Please credit Björn Jónsson.

### `/cubemaps/Mars.normal.2048.png`

Derived from MGS MOLA global topography (NASA/JPL/GSFC MOLA Science Team; USGS Astrogeology DEM).

### `/cubemaps/Mercury.normal.512.png`

Derived from MESSENGER global topography (NASA/JHUAPL/Carnegie Institution of Washington; USGS
Astrogeology DEM).

### `/cubemaps/Moon.normal.1024.png`

Derived from LRO LOLA topography (NASA Scientific Visualization Studio, CGI Moon Kit).

---

## Surface roughness map

### `/cubemaps/Earth.roughness.1024.png`

A land/sea mask that gives open water a specular Sun-glint and leaves land, ice and snow matte.
Water — the ocean with its bays and estuaries, and the significant lakes — is taken from Natural
Earth's public-domain 1:10m ocean and lake polygons, rasterized and area-averaged so the
coastline carries a fractional smooth-to-matte transition about one texel wide. Sea ice, ice
shelves and dry salt flats stay matte where the `Earth.albedo` source (NASA Blue Marble Next
Generation) images them bright.

- **Copyright:** © Charlie Whitfield (I, Voyager). **License:** [Apache 2.0](LICENSE.txt).
  Underlying data public domain.

---

## Body meshes

Eight bodies whose real figure a scaled sphere cannot carry — an oblate or triaxial shape, an
equatorial ridge, a battered small-body silhouette — ship a geometry-only mesh, `/meshes/<Body>.obj`,
together with two cubemaps sampled by surface direction: the albedo documented above, and an
object-space normal cubemap for relief. Sampling by direction is what keeps them free of polar
artifacts: a direction lookup has no pole and no ±180° seam.

In each entry the mesh and its normal cubemap are one product of one elevation or shape model,
and both are I, Voyager works:

- **Copyright:** © Charlie Whitfield (I, Voyager). **License:** [Apache 2.0](LICENSE.txt). The
  underlying shape and elevation data is public domain except where an entry says otherwise, and
  is cited per entry. The albedo cubemap that accompanies each is a separate work, documented
  above.

### Ceres — `/meshes/Ceres.obj` + `/cubemaps/Ceres.normal.512.png`

Derived from the Dawn Framing Camera HAMO global Digital Terrain Model (Preusker et al., 2016;
NASA/JPL-Caltech/UCLA/MPS/DLR/IDA).

### Charon — `/meshes/Charon.obj` + `/cubemaps/Charon.normal.512.png`

Derived from the New Horizons LORRI/MVIC global Digital Elevation Model (Schenk et al., 2018;
NASA/Johns Hopkins APL/SwRI). The normal cubemap is flat wherever the albedo carries the unimaged
fill, so no relief is shaded over ground the map does not claim.

### Deimos — `/meshes/Deimos.obj` + `/cubemaps/Deimos.normal.512.png`

Derived from the Deimos stereophotoclinometry shape model of Ernst et al. (2023), 20 m ground
sample distance — the first shape model to resolve Deimos' geology. C. M. Ernst, R. W. Gaskell et
al., *High-resolution shape models of Phobos and Deimos from stereophotoclinometry*, Earth,
Planets and Space 75:103, doi:10.1186/s40623-023-01814-7; built from Viking Orbiter, Mars Global
Surveyor, Mars Express and Mars Reconnaissance Orbiter imaging and distributed through the Small
Body Mapping Tool, Johns Hopkins APL. No license asserted; please cite the paper.

### Iapetus — `/meshes/Iapetus.obj` + `/cubemaps/Iapetus.normal.512.png`

An idealized figure based on the published triaxial radii of Thomas et al. (2007); no global
Iapetus elevation model is publicly available.

### Mimas — `/meshes/Mimas.obj` + `/cubemaps/Mimas.normal.512.png`

Derived from the Gaskell stereophotoclinometry shape model (R. Gaskell, Cassini ISS and Voyager
1; PDS Small Bodies Node dataset CO-SA-ISSNA-5-MIMASSHAPE-V2.0), whose facets are about 0.6 km
across — one texel of the normal cubemap. As for Phoebe, the shape is an irregular
stereophotoclinometry tessellation rather than a latitude/longitude grid, so the normal cubemap
is ray-cast against it directly. The shipped mesh carries the silhouette alone and is decimated
to 2 % of the published facet count, which moves the modelled surface by 0.03 km rms.

### Miranda — `/meshes/Miranda.obj` + `/cubemaps/Miranda.normal.512.png`

The triaxial figure of Thomas (1988), 240.4 × 234.2 × 232.9 km, carrying Paul Schenk's controlled
Voyager 2 digital elevation model over the imaged hemisphere and relaxing to the bare ellipsoid
over the unimaged one (Schenk, P. and Moore, J. (2020), *Philosophical Transactions of the Royal
Society A* 378, 20200102; distributed by the Lunar and Planetary Institute, no license asserted;
underlying imagery NASA/JPL).

### Phobos — `/meshes/Phobos.obj` + `/cubemaps/Phobos.normal.512.png`

Derived from the Phobos stereophotoclinometry shape model of Ernst et al. (2023), 36 m ground
sample distance — same publication and distribution as Deimos above; built from Viking Orbiter,
Phobos 2, Mars Global Surveyor, Mars Express and Mars Reconnaissance Orbiter imaging.

### Phoebe — `/meshes/Phoebe.obj` + `/cubemaps/Phoebe.normal.512.png`

Derived from the Gaskell stereophotoclinometry shape model (R. Gaskell, Cassini ISS; PDS Small
Bodies Node dataset CO-SA-ISSNA-5-PHOEBESHAPE-V2.0). Phoebe's shape is an irregular
stereophotoclinometry tessellation rather than a latitude/longitude grid, so its normal cubemap
is ray-cast against the mesh directly.

### Vesta — `/meshes/Vesta.obj` + `/cubemaps/Vesta.normal.512.png`

Derived from the Dawn Framing Camera HAMO global stereophotogrammetric Digital Terrain Model
(Preusker et al., 2016; NASA/JPL-Caltech/UCLA/MPS/DLR/IDA).

---

## Shape meshes for unmapped small moons

Fourteen small moons have a published shape model but no map worth shipping. They carry a
geometry mesh and no textures at all, so they render in their surface class's flat gray and the
silhouette alone tells them apart — which is also what marks them as bodies no spacecraft has
imaged closely. The meshes are I, Voyager works: each published shape is placed in the engine's
authoring frame and decimated to about 2000 triangles, a reduction that moves the modelled
surface by 0.1–0.2 % of the body's mean radius. The four Voyager-era shapes are additionally
scaled to each moon's currently accepted mean radius, which their own scale predates. A moon with
only a measured *ellipsoid* ships no asset at all — its three semi-axes live in the Core plugin's
data tables.

- **Copyright:** © Charlie Whitfield (I, Voyager). **License:** [Apache 2.0](LICENSE.txt).
  Underlying shape data public domain, cited below.

### Cassini-era shapes

`/meshes/Pan.obj`, `/meshes/Daphnis.obj`, `/meshes/Atlas.obj`, `/meshes/Prometheus.obj`,
`/meshes/Pandora.obj`, `/meshes/Epimetheus.obj`, `/meshes/Janus.obj`, `/meshes/Telesto.obj`,
`/meshes/Calypso.obj`, `/meshes/Helene.obj` — derived from the Cassini ISS shape models of
P. Thomas, J. Joseph and T. Ansty (*Saturn Small Moon Shape Models V1.0*, NASA Planetary Data
System, 2018, doi:10.26033/ewy3-jy61), solved from control-point stereogrammetry with limb and
terminator constraints after Thomas et al. (2013).

### Voyager-era shapes

`/meshes/Amalthea.obj`, `/meshes/Thebe.obj`, `/meshes/Larissa.obj`, `/meshes/Proteus.obj` —
derived from the Voyager shape models of P. Stooke (*Stooke Small Bodies Shape Models V1.0*, NASA
Planetary Data System, 2025, doi:10.26033/yt84-5y91). Stooke's satellite longitudes are positive
west, the IAU satellite convention, and are converted on import.

---

## Packed 3D models

`/models/<name>/` subdirectories hold 3D models downloaded from
[NASA 3D Resources](https://science.nasa.gov/3d-resources/) — each the downloaded file, usually
`.glb`, plus the files Godot's importer extracts from it. They are used as downloaded, with three
exceptions, the first two on the **body** models alone. Their files are renamed to carry the
model's own unit scale — `Eros.1_10.glb` is 10 m per glb unit, `Hyperion.1_1000.glb` 1000 —
since a downloaded model is authored at whatever scale its author chose and the shipped body must
render at its catalogued size. And their embedded base-color textures were rescaled in linear
light toward the same level convention as the surface maps. A packed model carries its level in
that texture and nowhere else, so a body whose reflectance does not fit under white cannot be held
on this path at all; Mimas, at a V-band geometric albedo of 0.962, is built as a mesh and cubemaps
instead. Last, five models — Hubble, the ISS, Arrokoth, Bennu and Hyperion — have an all-zero
`emissiveFactor` removed from their materials: glTF defines it as no emission, but Godot's
importer turns emission on for any factor it finds, so the change is to import metadata and to
nothing rendered.

- **Bodies:** `/models/arrokoth/*`, `/models/bennu/*`, `/models/eros/*`, `/models/hyperion/*`,
  `/models/itokawa/*`
- **Spacecraft:** `/models/hubble/*`, `/models/iss/*`, `/models/juno/*`, `/models/jwst/*`,
  `/models/new_horizons/*`, `/models/pioneer_10/*`, `/models/voyager/*`
- **Copyright:** Public Domain. **License:** Public Domain; see
  [NASA Images and Media Usage Guidelines](https://www.nasa.gov/nasa-brand-center/images-and-media/).
---

## Sky background

### Milky Way background — `/starmaps/milkyway_background.4096.png`

Derived from Deep Star Maps 2020 (NASA Scientific Visualization Studio,
https://svs.gsfc.nasa.gov/4851/) — specifically the "Milky Way background in galactic coordinates
... that omits the bright (Hipparcos and Tycho) stars", since I, Voyager draws the discrete stars
separately in shader code from the Hipparcos catalogue.

We built the shipped 4K PNG from the 64K EXR rather than from the smaller EXR the same release
offers, and it is a **linear radiance map**: `DN = 255 · srgb_encode(linear / 0.0410765)`, with
no tone curve of any kind, so the file carries radiance and the renderer supplies the exposure.
The source is shot-noise limited — its faint sky is largely star-catalog speckle — so it is
smoothed by an amount that scales with local brightness rather than uniformly, and rare isolated
bright pixels are capped at the level where they stop being individually visible, with the flux
they lose returned as a wide diffuse layer so that nothing is destroyed. Real compact objects are
exempted from that cap by a test for the extended halo they sit on, which is what keeps 47
Tucanae, M22 and the core of M31. The two polar caps are rebuilt on a pole-tangent gnomonic grid
running the identical steps, so that no processing is done in the equirectangular projection's
pole singularity, and are feathered back into the body of the map. The file is imported without
VRAM compression.

- **Third-party:** the sky imagery — Public Domain (NASA Scientific Visualization Studio).
- **I, Voyager:** the radiance scaling and the noise treatment. No separate copyright is asserted
  over them.

---

## Data binaries and textures

These files are essentially data distributions. Each is a conversion of published catalog or
model data into a form the renderer can sample, and we make no claim on their content.

### `/starmaps/stars.*.ivbinary`

Directions, distances, magnitudes and B−V colors for 2,551,210 stars, from the
[ESA Hipparcos Catalogue](https://www.cosmos.esa.int/web/hipparcos) (ESA, 1997; ESA SP-1200) and
the [Tycho-2 Catalogue](https://www.cosmos.esa.int/web/hipparcos/tycho-2) (Høg et al. 2000,
A&A 355, L27), both products of the ESA Hipparcos mission. Hipparcos supplies the measured V,
B−V and parallax for its own 118,000 stars; Tycho-2 and its supplement supply the remaining 2.43
million, which carry no parallax and sit on a 1 kpc shell, with Johnson V and B−V derived from
Tycho B<sub>T</sub>/V<sub>T</sub> by the catalogue's own stated relation. The set is 99 %
complete to V 11.0.

Twenty-four files, each a half-magnitude bucket named for its faint end, so a project can trade
star count against download size by shipping only the buckets its own field of view can use.
Each star occupies ten bytes: a 16-bit direction per axis (5.5 arcsec), a 16-bit parallax, and
one byte each of magnitude and color index.

### `/rings/*`

Saturn ring light-scattering data created by
[Björn Jónsson](https://bjj.mmedia.is/data/s_rings/index.html), converted to a shader-sampler
texture: one half-float image carrying his three radial brightness profiles as layers —
backscattered light, forward-scattered light at a phase angle of 139°, and the unlit side —
paired with his transparency profile as the fraction of the background each radius occludes. His profiles are measured in Voyager images over the Voyager
stellar occultation optical depth, sampled every 5 km from 74,510 to 140,390 km from Saturn's
centre. The file holds them in linear light with each one's own observing geometry divided out,
so that what it carries is the ring's scattering strength and the shader can re-apply the
geometry at the angles it is rendering.

The colour is ours, and both halves of it are measured. How it varies with radius comes from
Cassini's Visual and Infrared Mapping Spectrometer: that instrument's two visible spectral
slopes, published as radial profiles by Hedman et al. (2013), describe a reflectance spectrum
every 20 km, and integrating each of those against the CIE colour-matching functions gives its
radius a colour. The A and B rings come out distinctly red, the C ring and the Cassini Division
much less so, and the C ring reddens steadily outward across its whole width. How red the
system is overall comes instead from disc-integrated photometry, which no spectrometer scan can
supply: Mallama, Krobusek and Pavlov (2017) model Saturn's magnitude against ring opening angle
and solar phase in each of U, B, V, R and I, and at zero opening the rings are edge-on and the
model is the globe alone, so the difference between the two is the ring system's own light, band
by band. That gives a colour index of B−V 0.93 — tan, and less red than the planet it circles.
The two determinations share no instrument and no method, and they agree on the system's mean
colour to 6%.

The unlit side is given the same colour as the lit side, at its own luminance. Its light is the
same particles seen through the layer rather than off it, so its scattering strength has their
spectrum; over every radius the unlit-side scan reaches, its measured colour is within 5% of the
lit-side scan's.

- **Third-party:** the three brightness profiles and the transparency profile, wholly — please
  credit Björn Jónsson. The radial colour is derived from Cassini VIMS data
  (NASA/JPL-Caltech/University of Arizona; please cite Hedman et al. 2013).
- **I, Voyager:** the colour of the tint. No separate copyright is asserted over it.

### `/asteroid_binaries/*`

Asteroid proper orbital elements from the
[Asteroids Dynamic Site (AstDyS)](https://newton.spacedys.com/astdys), packed by orbital group
and magnitude limit. Asteroid names and discovery designations are from NASA/JPL's
[Small-Body Database](https://ssd.jpl.nasa.gov/tools/sbdb_query.html).

---

## 2D body icons

### `/bodies_2d/<Body>.256.png` and `/bodies_2d/Sun_slice.128x1024.png`

One small flat-image icon per body, plus the Sun's slice texture, used in the GUI. Each is
rendered by I, Voyager from that body's 3D model, surface map or surface shader. A rendering of
an asset is a derivative of it, so **each icon carries the same copyright and license as the body
asset it was rendered from**:

- Public Domain, for bodies built from public-domain data;
- the source map's license, for bodies textured from third-party maps — for example the Björn
  Jónsson maps;
- © Charlie Whitfield (I, Voyager), [Apache 2.0](LICENSE.txt), for bodies whose map or model is
  an I, Voyager work, and for the Sun, whose icons derive from its procedural surface shader.

### `/fallbacks/blank_grid_2d_globe.256.png`

A plain graticule globe, used as the 2D icon for any body that has none of its own. An I, Voyager
work.

- **Copyright:** © Charlie Whitfield (I, Voyager). **License:** [Apache 2.0](LICENSE.txt).

---

## Fonts

### `/fonts/Roboto-NotoSansSymbols-merged.ttf`

A merge of Roboto and Noto Sans Symbols, both [Google Fonts](https://fonts.google.com/).

- **Copyright:** Google LLC. **License:**
  [SIL OPEN FONT LICENSE Version 1.1](3RD_PARTY.md#sil-open-font-license-version-11).
