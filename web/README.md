# Progressive Web App (PWA) Deployment

Godot 3.4.1 introduced [PWA](https://web.dev/what-are-pwas/) functionality, but it's still a little rough to deploy as of Godot 3.4.2.
 
First, Godot 3.4.2.official does not use an offline first approach (see [issue 56103](https://github.com/godotengine/godot/issues/56103)). To fix that, you need a custom Godot build from Faless' branch [3.x_pwa_prefer_cache](https://github.com/Faless/godot/tree/js/3.x_pwa_prefer_cache) commit bf61f9c. Please contact us if you need the pre-built binaries.

godot.html is the Custom Html Shell used to generate our loading page. This and the three jupiter-xxx.png icons are referenced in export_presets.config and are automatically included in HTML5 export (with PWA enabled). 
 
HOWEVER, pale-blue-dot-512.jpg (used by the loading page) must be added to the HTML5 export manually! To do this:
* Add the pale-blue-dot-512.jpg file to the web server directory with the other export files.
* Open the exported *.service.worker.js file and add "pale-blue-dot-512.jpg" to CACHED_FILES.
 



