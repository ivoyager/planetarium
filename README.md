# Planetarium

Homepage: https://ivoyager.dev

Issues: https://github.com/ivoyager/ivoyager/issues

Forum: https://ivoyager.dev/forum

### What is I, Voyager?
I, Voyager is
1. an open-source software planetarium 
2. a development platform for creating games and educational software in a realistic solar system.

It is designed to be improved, modified and extended by the community. I, Voyager runs on the open-source [Godot Engine](https://godotengine.org) and primarily uses Godot’s easy-to-learn [GDScript](http://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html#doc-gdscript) (similar to Python). It can be extended into an independent free-standing project (a game or other software product) using GDScript, C# or C++.

If you are interested in our future development, see our official [Roadmap!](https://ivoyager.dev/forum/index.php?p=/discussion/41/roadmap)

### What does I, Voyager cost?
I, Voyager is free to use and distribute under the permissive [Apache License 2.0](https://en.wikipedia.org/wiki/Apache_License). Projects built with I, Voyager are owned by their creators. You are free to give away or sell what you make. There are no royalties or fees.

### How do I contribute to I, Voyager development?
Help us grow the community by following us on [Twitter](https://twitter.com/IVoygr) and [Facebook](https://www.facebook.com/IVoygr/). Exchange ideas and give and receive help on our [Forum](https://ivoyager.dev/forum). Report bugs or astronomical inaccuracies at our issue tracker [here](https://github.com/ivoyager/issues). Or contribute to code development via pull requests to our repositories at https://github.com/ivoyager.

### How can I support this effort financially?
Please visit our [GitHub Sponsors page!](https://github.com/sponsors/charliewhitfield) Become a Mercury Patron for $2 per month! Or, if you are a company, please consider sponsoring us as a Saturn or Jupiter Patron. Goal #1: Make I, Voyager into a non-profit entity. This will shield us from tax liability, allow us to apply for grants, and secure our existence as a collaborative open-source project into the future.

### Where did I, Voyager come from?
Creator and lead programmer Charlie Whitfield stumbled into the Godot Engine in November, 2017. By December there were TestCubes orbiting bigger TestCubes orbiting one really big TestCube*. The name "I, Voyager" is a play on "Voyager 1," the spacecraft that captured an image of Earth from 6.4 billion kilometers away (the [Pale Blue Dot](https://www.planetary.org/explore/space-topics/earth/pale-blue-dot.html)). I, Voyager became an open-source project on Carl Sagan's birthday, November 9, 2019.

(* Godot devs, bring back the [TestCube](https://docs.godotengine.org/en/2.1/classes/class_testcube.html)!)

### Authors, credits and legal
I, Voyager is possible due to public interest in space exploration and funding of government agencies like NASA and ESA, and the scientists and engineers that they employ. I, Voyager is also possible due to open-source software developers, and especially [Godot Engine's creators and contributors](https://github.com/godotengine/godot/blob/master/AUTHORS.md). I, Voyager is copyright (c) 2017-2021 Charlie Whitfield. I, Voyager is a registered trademark of Charlie Whitfield. For up-to-date lists of authors, credits, and license information, see files in our code repository [here](https://github.com/ivoyager/ivoyager) or follow these links:
* [AUTHORS.md](https://github.com/ivoyager/ivoyager/blob/master/AUTHORS.md) - contributors to I, Voyager code and assets.
* [CREDITS.md](https://github.com/ivoyager/ivoyager/blob/master/CREDITS.md) - individuals and organizations whose efforts made I, Voyager possible.  
* [LICENSE.txt](https://github.com/ivoyager/ivoyager/blob/master/LICENSE.txt) - the I, Voyager license.
* [3RD_PARTY.txt](https://github.com/ivoyager/ivoyager/blob/master/3RD_PARTY.txt) - copyright and license information for 3rd-party assets distributed in I, Voyager.

### A tour in screen captures:
![](https://ivoyager.dev/wp-content/uploads/2020/01/europa-jupiter-io-ivoyager.jpg)
Jupiter and Io viewed from Europa. We've hidden all interface here for one of the best views in the solar system.

![](https://ivoyager.dev/wp-content/uploads/2019/10/moons-of-jupiter.jpg)
Jupiter and the four Galilean moons – Io, Europa, Ganymede and Callisto – embedded in the orbital paths of many smaller moons.

![](https://ivoyager.dev/wp-content/uploads/2019/12/saturn-rings-moons-ivoyager.jpg)
Saturn's rings and its close-orbiting moons.

![](https://ivoyager.dev/wp-content/uploads/2020/01/uranus-moons-ivoyager.jpg)
Uranus' moons are an interesting cast of characters (literally). The planet's 98° axial tilt puts the inner solar system almost directly to the south in this image.

![](https://ivoyager.dev/wp-content/uploads/2020/01/solar-system-pluto-flyby-ivoyager.jpg)
Here's the solar system on July 14, 2015, the day of New Horizon's flyby of the dwarf planet Pluto (♇). Not coincidentally, Pluto was near the plane of the ecliptic at this time.

![](https://ivoyager.dev/wp-content/uploads/2020/01/pluto-charon-ivoyager.jpg)
Pluto and its moon Charon to scale. Both are tidally locked so their facing sides never change. (Um... I'm not sure we have the facing sides correct. If anyone can help with that, it would be most appreciated!)

![](https://ivoyager.dev/wp-content/uploads/2020/01/asteroids-ivoyager-1.jpg)
 Jupiter (♃) is the shepherd of the solar system. Shown here are 64,738 asteroids, the vast majority in the  Main Belt (the ring inside Jupiter’s orbit) but quite a few in the two Trojan groups (the "lobes" 60° ahead of and 60° behind Jupiter). The Hildas are also evident in this image. I, Voyager has orbital data for >600,000 asteroids (numbered and multiposition) but can run with a reduced set filtered by magnitude.
 
![](https://ivoyager.dev/wp-content/uploads/2020/01/asteroids-ivoyager-2.jpg)
Asteroids viewed from the side. We use the GPU to calculate asteroid positions; each asteroid is a shader vertex that knows its own orbital parameters.

![](https://ivoyager.dev/wp-content/uploads/2020/01/ivoyager-planetarium-gui.jpg)
The Planetarium has an easy-to-use interface that is mostly hidden during use; individual elements show when the mouse moves to the relevant screen zone.

![](https://ivoyager.dev/wp-content/uploads/2020/01/ivoyager-template-gui.jpg)
The Project Template has a "starter" GUI intended for game development. I, Voyager provides various GUI widgets (a system navigator, date-time display, etc.) that can be arranged into panels or however you need for your own project.
