# Planetarium

[Homepage](https://www.ivoyager.dev)  
[Forum](https://www.ivoyager.dev/forum)  
[Issues](https://github.com/ivoyager/ivoyager/issues)

### What is I, Voyager?
I, Voyager is
1. an open-source software planetarium 
2. a development platform for creating games and educational software in a realistic solar system.

It is designed to be improved, modified and extended by the community. I, Voyager runs on the open-source [Godot Engine](https://godotengine.org) and primarily uses Godot’s easy-to-learn [GDScript](http://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_basics.html#doc-gdscript) (similar to Python). It can be extended into an independent free-standing project (a game or other software product) using GDScript, C# or C++.

If you are interested in our future development, see our official [Roadmap!](https://www.ivoyager.dev/forum/index.php?p=/discussion/41/roadmap)

### What does I, Voyager cost?
I, Voyager is free to use and distribute under the permissive [Apache License 2.0](https://en.wikipedia.org/wiki/Apache_License). Projects built with I, Voyager are owned by their creators. You are free to give away or sell what you make. There are no royalties or fees.

### How do I contribute to I, Voyager development?
Help us grow the community by following us on [Twitter](https://twitter.com/IVoygr) and [Facebook](https://www.facebook.com/IVoygr/). Exchange ideas and give and receive help on our [Forum](https://www.ivoyager.dev/forum). Report bugs or astronomical inaccuracies at our issue tracker [here](https://github.com/ivoyager/issues). Or contribute to code development via pull requests to our repositories at [github.com/ivoyager](https://github.com/ivoyager).

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

### Screen captures!

Our site header for [ivoyager.dev](https://www.ivoyager.dev) is also from the Planetarium!

![](https://www.ivoyager.dev/wp-content/uploads/2020/01/europa-jupiter-io-ivoyager.jpg)
Jupiter and Io viewed from Europa. We've hidden the interface for one of the best views in the solar system.

![](https://www.ivoyager.dev/wp-content/uploads/2019/10/moons-of-jupiter.jpg)
Jupiter and the four Galilean moons – Io, Europa, Ganymede and Callisto – embedded in the orbital paths of many smaller moons.

![](https://www.ivoyager.dev/wp-content/uploads/2019/12/saturn-rings-moons-ivoyager.jpg)
Saturn's rings and its close-orbiting moons.

![](https://www.ivoyager.dev/wp-content/uploads/2020/01/uranus-moons-ivoyager.jpg)
Uranus' moons are an interesting cast of characters (literally). The planet's 98° axial tilt puts the inner solar system almost directly to the south in this image.

![](https://www.ivoyager.dev/wp-content/uploads/2020/01/solar-system-pluto-flyby-ivoyager.jpg)
Here's the solar system on July 14, 2015, the day of New Horizon's flyby of the dwarf planet Pluto (♇). Not coincidentally, Pluto was near the plane of the ecliptic at this time.

![](https://www.ivoyager.dev/wp-content/uploads/2020/01/pluto-charon-ivoyager.jpg)
Pluto and its moon Charon to scale. Both are tidally locked so their facing sides never change.

![](https://www.ivoyager.dev/wp-content/uploads/2020/01/asteroids-ivoyager-1.jpg)
Jupiter (♃) is the shepherd of the Solar System, as is evident in the orbits of asteroids (64,738 shown here). The [Main Belt](https://en.wikipedia.org/wiki/Asteroid_belt) (the ring) and [Trojans](https://en.wikipedia.org/wiki/Jupiter_trojan) (the two lobes leading and lagging Jupiter by 60°) are the most obvious features here. [Hildas](https://en.wikipedia.org/wiki/Hilda_asteroid) are also visible. I, Voyager has orbital data for >600,000 asteroids (numbered and multiposition) but can run with a reduced set filtered by magnitude.
 
![](https://www.ivoyager.dev/wp-content/uploads/2020/01/asteroids-ivoyager-2.jpg)
Main Belt and Trojans viewed from the side. We use the GPU to calculate and update asteroid positions (each asteroid is a shader vertex that knows its own orbital parameters).

![](https://www.ivoyager.dev/wp-content/uploads/2021/02/ivoyager-planetarium-gui.jpg)
The Planetarium has easy-to-use interface panels that can be hidden.

![](https://www.ivoyager.dev/wp-content/uploads/2021/02/ivoyager-gui-widgets.jpg)
For developers, we have a large set of GUI widgets that know how to talk to the simulator. These can be easily dropped into Containers to make your custom GUI however you like.

![](https://www.ivoyager.dev/wp-content/uploads/2021/02/template-gui.jpg)
Here's our "starter GUI" in the Project Template to get you going on game development.
