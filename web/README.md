# Progressive Web App (PWA) Deployment

These files are referenced in export_presets.config and used to generate the HTML5 export:
* godot.html - Custom Html Shell used to generate our loading page.
* jupiter-xxx.png - Icon images (3 sizes) included in PWA export.

We've opted not to set Boot Splash in Project Settings because if forces us to use a .png file, which is slow to load in web browsers. Instead, we add the following file manually to the web server directory **AND** to planetarium.service.worker.js CACHED_FILES array.
* pale_blue_dot_453x614.jpg

File to remove from export:
* planetarium.png - Boot splash is off in Project Settings and isn't referenced anywhere in the export.

#### Notes
Server must be set up to use .htaccess file! Add .htaccess with these lines:
```
Header set Cross-Origin-Opener-Policy: same-origin
Header set Cross-Origin-Embedder-Policy: require-corp
```

Above requirement was supposed to have been fixed in 4.5.x, but it didn't work in first attempt to run without .htaccess file.

Shadows are disabled for Compatibility renderer (this affects web export). See comments in ivoyager_core/tree/dynamic_light.gd.

#### Export Settings
* Resources/Filters to export... `*.ivbinary, *.cfg` (for any export!)
* Options/HTML/Export Icon `On`
* Options/HTML/Custom HTML Shell `res://web/godot.html`
* Options/HTML/Canvas Resize Policy `Adaptive`
* Options/HTML/Focus Canvas on Start `On`
* Options/Progressive Web App/Enabled `On`
* Options/Progressive Web App/Ensure Cross Origin Isolation Headers `On`
* Options/Progressive Web App/Display `Standalone`
* Options/Progressive Web App/Orientation `Any`
* Options/Progressive Web App/Icon 144x144 `res://web/jupiter-144.png`
* Options/Progressive Web App/Icon 180x180 `res://web/jupiter-180.png`
* Options/Progressive Web App/Icon 512x512 `res://web/jupiter-512.png`
* Options/Progressive Web App/Background Color `<Black>`
