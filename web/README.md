# Progressive Web App (PWA) Deployment

Godot 3.4.1 introduced [PWA](https://web.dev/what-are-pwas/) functionality, but it's still a little rough to deploy as of Godot 3.4.2.
 
PWA exported with Godot 3.4.2.official does not use an offline-first approach (see [issue 56103](https://github.com/godotengine/godot/issues/56103)). To fix this, you need a custom Godot build from Faless' branch [3.x_pwa_prefer_cache](https://github.com/Faless/godot/tree/js/3.x_pwa_prefer_cache) commit bf61f9c. Please contact us if you need the pre-built binaries.

These files are referenced in export_presets.config and used to generate the HTML5 export:
* godot.html - Custom Html Shell used to generate our loading page.
* jupiter-xxx.png - Icon images (3 sizes) included in PWA export.

We've opted not to set Boot Splash in Project Settings because if forces us to use a .png file, which is slow to load in web browsers. Instead, we add the following file manually to the web server directory **AND** to planetarium.service.worker.js CACHED_FILES array.
* pale_blue_dot_453x614.jpg

File to remove from export:
* planetarium.png - Godot boot splash isn't referenced anywhere (boot is off in Project Settings)
