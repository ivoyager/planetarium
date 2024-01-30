# Progressive Web App (PWA) Deployment

Godot 3.4.1 introduced [PWA](https://web.dev/what-are-pwas/) functionality, but it's still a little rough to deploy as of Godot 4.2.1.

These files are referenced in export_presets.config and used to generate the HTML5 export:
* godot.html - Custom Html Shell used to generate our loading page.
* jupiter-xxx.png - Icon images (3 sizes) included in PWA export.

We've opted not to set Boot Splash in Project Settings because if forces us to use a .png file, which is slow to load in web browsers. Instead, we add the following file manually to the web server directory **AND** to planetarium.service.worker.js CACHED_FILES array.
* pale_blue_dot_453x614.jpg

File to remove from export:
* planetarium.png - Godot boot splash isn't referenced anywhere (boot is off in Project Settings)

#### Godot 4.x Notes:
Server must be set up to use .htaccess file! Add .htaccess with these lines:
```
Header set Cross-Origin-Opener-Policy: same-origin
Header set Cross-Origin-Embedder-Policy: require-corp
```

Lighting is all screwed up in HTML5 export using normal world scale (METER = 1.0) as of Godot 4.2.1. See notes and change this value in res://planetarium/units.gd. METER = 1e-8 seem to work ok for HTML5 export (but this value screws up lighting in editor run or Windows export).

#### Export Settings
Resources/Filters to export... `*.ivbinary, *.cfg` (for any export!)
Options/HTML/Export Icon `On`
Options/HTML/Custom HTML Shell `res://web/godot.html`
Options/HTML/Canvas Resize Policy `Adaptive`
Options/HTML/Focus Canvas on Start `On`
Options/Progressive Web App/Enabled `On`
Options/Progressive Web App/Display `Standalone`
Options/Progressive Web App/Orientation `Any`
Options/Progressive Web App/Icon 144x144 `res://web/jupiter-144.png`
Options/Progressive Web App/Icon 180x180 `res://web/jupiter-180.png`
Options/Progressive Web App/Icon 512x512 `res://web/jupiter-512.png`
Options/Progressive Web App/Background Color `<Black>`
