# Progressive Web App (PWA) Deployment

These files are referenced in export_presets.cfg and used to generate the HTML5 export:
* godot.html - Custom Html Shell used to generate our loading page.
* jupiter-xxx.png - Icon images (3 sizes) included in PWA export.

These are used after export:
* pale_blue_dot_453x614.jpg - Our splash image, shown by godot.html while the app loads. We've opted not to set Boot Splash in Project Settings because it forces us to use a .png file, which is slow to load in web browsers.
* post_export.py - Prepares an export for upload (below).

#### Deploying
1. Export the Web preset to `export/planetarium.html`, or to `export/planetarium-dev.html` for a dev build (settings below). Keep a copy of the `.htaccess` below in `export/`.
2. From the project directory, run the post-export script, adding `-dev` for a dev build:
   ```
   python web/post_export.py
   python web/post_export.py -dev
   ```
   It first checks that `export/` has every file the upload needs, the `.htaccess` included; if any is missing, it lists them and changes nothing. Then it:
   * copies in pale_blue_dot_453x614.jpg and adds it to `CACHED_FILES` in `planetarium.service.worker.js`, which otherwise caches only the files Godot writes, so the installed app shows the splash image offline too;
   * replaces `planetarium.wasm` and `planetarium.pck` with gzipped `planetarium.wasm.gz` and `planetarium.pck.gz`, cutting a first visit's download from about 400 MB to 240 MB;
   * deletes `planetarium.png`, the boot splash that Godot writes but godot.html never shows;
   * zips the upload, `.htaccess` included, as `export/app.zip`.

   With `-dev`, each of those names takes the suffix: `planetarium-dev.*` and `app-dev.zip`. Running it twice does no harm. To get the uncompressed files back, re-export.
3. Upload the zip to the app's directory on the server, `app/` or `app-dev/`, and extract it there. The first time, also delete the old uncompressed `.wasm` and `.pck` there; they are never sent again.
4. Check that the server sends the gzipped files under the original names, here for the dev build:
   ```
   curl -sI https://www.ivoyager.dev/app-dev/planetarium-dev.wasm
   curl -sI https://www.ivoyager.dev/app-dev/planetarium-dev.pck
   ```
   Each should answer `200 OK` with `Content-Encoding: gzip` and a `Content-Type` of `application/wasm` or `application/octet-stream`. Otherwise the app can't load: flush SiteGround's cache and check again before suspecting the `.htaccess`.

#### .htaccess
The server must be set up to use .htaccess files. Each app directory on the server needs this one:
```apache
# I, Voyager Planetarium web app. See web/README.md in the Planetarium repository.

Header set Cross-Origin-Opener-Policy: same-origin
Header set Cross-Origin-Embedder-Policy: require-corp

# The .wasm and .pck are uploaded only gzipped, as .wasm.gz and .pck.gz. Send each
# for a request of the original name, with the original's type and gzip encoding.
AddType application/wasm .wasm
AddType application/octet-stream .pck
RemoveType .gz
AddEncoding gzip .gz
RewriteEngine On
RewriteCond %{REQUEST_FILENAME}.gz -f
RewriteRule ^(.+\.(?:wasm|pck))$ $1.gz [L]
```

The two `Header` lines were supposed to be unnecessary from Godot 4.5.x, but the app didn't run without them in our first attempt.

The rest answers a request for `<name>.wasm` or `<name>.pck` with `<name>.wasm.gz` or `<name>.pck.gz` whenever that file exists, labeled with the original's `Content-Type` and with `Content-Encoding: gzip`, so the browser unpacks it as it arrives. Godot's loader, its progress bar and the service worker all see the original bytes, and every browser that can run the app accepts gzip. `RemoveType` and `AddEncoding` are what make that work: by default Apache labels a `.gz` as a gzip file to download, which the browser won't unpack.

#### Notes
Shadows are disabled for Compatibility renderer (this affects web export). See comments in ivoyager_core/tree/dynamic_light.gd.

#### TODO
* **Re-export and test before the next upload: the v0.2.1.dev1 export does not load.** Chrome compiles WebGL shaders on Windows through ANGLE and FXC, where one atmosphere-limb program took 74-85 s against Chrome's 30 s GPU watchdog, so the app never got past "Building the Solar System...". Since 2026-09-27 an atmosphere shader's whole first draw, five programs, takes 9-18 s on the development laptop, so an export should now load, though no browser has confirmed it yet. A first visit still spends about a minute and a half of that laptop's CPU compiling at the fitted Min tier, and more on a slower one. See *The web export* and *What a first run costs* in `ivoyager_core/GRAPHICS_PROFILING.md`.
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
