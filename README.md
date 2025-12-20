# Planetarium

I, Voyager's free, open-source software planetarium built on the free, open-source [Godot Engine](https://godotengine.org).

Runnable Windows and Web apps can be accessed from our [Planetarium](https://www.ivoyager.dev/planetarium/) page.

I, Voyager software is designed to be improved, modified and extended by the community. See [About](https://www.ivoyager.dev/about/), [News](https://www.ivoyager.dev/), [Developers](https://www.ivoyager.dev/developers/), and [Forum](https://github.com/orgs/ivoyager/discussions).


### Installation

Find detailed instructions at our [Developers](https://www.ivoyager.dev/developers/) page.

This repository uses submodules! To clone using git:

`git clone --recursive git://github.com/ivoyager/planetarium.git`

The editor plugin will manage assets download and version updates (assets are not Git-tracked). Just press 'Download' at the editor prompt.

After above steps, your addons directory will contain three subdirectories: `ivoyager_assets`, `ivoyager_core`, `ivoyager_tables` and `ivoyager_units`.

### Screen captures!

![](https://www.ivoyager.dev/wp-content/uploads/2020/01/europa-jupiter-io-ivoyager.jpg)
Jupiter and Io viewed from Europa. Also featured in our [homepage](https://www.ivoyager.dev/) header.

![](https://www.ivoyager.dev/wp-content/uploads/2025/03/saturn-rings-shadows-ivoyager-0.0.24.jpg)
Saturn and its rings. **New!** Just in time for our beta release, we have shadows! Semi-transparent shadows from Saturn’s rings are visible here. After considerable effort, we have shadows working at both planetary and spacecraft distance scales (see ISS below).

![](https://www.ivoyager.dev/wp-content/uploads/2025/03/iss-shadows-ivoyager-0.0.24.jpg)
The International Space Station. This is one of three spacecraft at this time. We would like to add more with historical flight paths or representative orbits. We [need more 3D models](https://github.com/ivoyager/ivoyager_core/issues/2) to do that…

![](https://www.ivoyager.dev/wp-content/uploads/2025/09/ivoyager-planetarium-gui-0.1.jpg)
The Planetarium’s user interface provides easy navigation and tons of information. Links in the panels open Wikepedia.org pages for more than a hundred solar system bodies and dozens of astronomy concepts.

![](https://www.ivoyager.dev/wp-content/uploads/2025/10/ivoyager-asteroids-0.1.jpg)
Positions of ~70,000 asteroids. Here, the Main Belt asteroids are cyan, with the Hilda subset in yellow. The Trojans at Jupiter’s L4 and L5 are magenta. (For programmers: Each point is a GPU vertex shader that knows its own orbital elements and calculates its own position.)

![](https://t2civ.com/wp-content/uploads/2023/03/astropolis-abstract.jpg)
Asteroid orbits. Or is it an abstract painting? The “wheel” at the center are the Trojans (yellow) encompassing the Main Belt (reddish). The outer orbit lines are the sparse Centaurs (cyan) and Trans-Neptune Objects (orangish).

![](https://www.ivoyager.dev/wp-content/uploads/2020/01/uranus-moons-ivoyager.jpg)
Uranus’ moons are an interesting cast of characters (literally). The planet’s 98° axial tilt puts the inner solar system almost due south in this image.

![](https://www.ivoyager.dev/wp-content/uploads/2020/01/solar-system-pluto-flyby-ivoyager.jpg)
Here’s the solar system on July 14, 2015, the day New Horizons flew by the dwarf planet Pluto (♇). Not coincidentally, Pluto was near the plane of the ecliptic at this time.

![](https://www.ivoyager.dev/wp-content/uploads/2020/01/pluto-charon-ivoyager.jpg)
Pluto and its moon Charon. Both are tidally locked so their facing sides never change.

![](https://www.ivoyager.dev/wp-content/uploads/2025/10/ivoyager-widgets-0.1.jpg)
For developers, you can quickly build GUI from a [large set of widgets](https://github.com/ivoyager/ivoyager_core/tree/master/ui_widgets). These widgets communicate with simulator internals and in some cases build themselves from simulator data (e.g., the planet/moon navigator widget above/left). See also the Planetarium GUI above, which is composed entirely of existing widgets in the Core plugin.
