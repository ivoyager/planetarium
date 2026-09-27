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

#### TODO
* **Re-export and test before the next upload: the v0.2.1.dev1 export does not load.** Chrome compiles WebGL shaders on Windows through ANGLE and FXC, where one atmosphere-limb program took 74-85 s against Chrome's 30 s GPU watchdog, so the app never got past "Building the Solar System...". Since 2026-09-27 an atmosphere shader's whole first draw, five programs, takes 11-25 s on the development laptop, so an export should now load, though no browser has confirmed it yet. A first visit still spends about two minutes of that laptop's CPU compiling, and more on a slower one. See *The v0.2.1 dev build* and *The atmosphere's structure* in `ivoyager_core/SHADER_COMPILE_PROFILING.md`.
* **Export a release build for the public site.** The dev export was a debug build: its page title reads "(DEBUG)".
* **Serve `.wasm` and `.pck` compressed and typed.** The host sends both uncompressed and with no `Content-Type`. Gzip at level 6 takes the wasm from 37.9 to 10.1 MB and the pck from 361 to 231 MB, cutting a first visit's download from 399 MB to 241 MB. For a file this size, serve pre-compressed copies rather than compressing on every request. Add `AddType application/wasm .wasm` to the `.htaccess`.
* **Retire the manual `CACHED_FILES` edit.** Inlining `pale_blue_dot_453x614.jpg` into `godot.html` as a data URI would put the splash image in the cached HTML itself, so neither the service-worker edit nor the separate upload would be needed.
* **Test the export in real Chrome and Firefox, never in the Claude desktop app's built-in browser.** That browser shares a renderer and a GPU process with the app's own UI, and a long shader compile freezes the whole app.

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
