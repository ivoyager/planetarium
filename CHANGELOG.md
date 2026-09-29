# Changelog

This file documents changes to the Planetarium "shell" project only. For changes to the core simulator code, go [here](https://github.com/ivoyager/ivoyager_core/blob/master/CHANGELOG.md).

File format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

See cloning and downloading instructions [here](https://www.ivoyager.dev/developers/).


## [v0.2.1] - UNRELEASED

Under development using Godot 4.7.2.

### Added
* Shader warm-up on the boot screen: registers the Core plugin's new IVShaderWarmup, and the boot screen now stays up through it, reporting *Compiling shaders (n of N)*. This moves the Compatibility renderer's shader compiles, which dominate a cold start and were hanging the camera mid-flight, onto the boot screen.
* Added the Core plugin's new `IVExposureControl` widget to the Camera & Views panel.
* Enabled the Core plugin's new physical-light system (`IVCoreSettings.enable_physical_light`): physically calibrated sunlight, sky and ambient with a software compensating camera. A "Physical Light" row appears in Options (default on).
* The web page offers a reload with the recommended graphics settings when the browser drops the WebGL context, and a URL ending `#reset-graphics` asks for the same, through the Core plugin's new `--reset-graphics` argument (`web/godot.html`). The web-app update now records its start as finished before it reloads, so the Core plugin's new graphics rescue doesn't take it for a failed start.
* Post-export script `web/post_export.py`, which adds the splash image to the web export's service worker `CACHED_FILES`, gzips its `.wasm` and `.pck`, and zips the upload. `web/README.md` gives the `.htaccess` that serves them and the whole deployment.

### Changed
* GUI rebuilt around the view (`gui/focus_gui.tscn`): a selection card with optional Details at top left, a time bar at bottom center, and a grid of buttons at top right for Hide GUI, Full Screen, Options, Hotkeys and the Navigation, HUDs, Camera & Views and Info panels, which open at bottom right one at a time (hotkeys 1-5), Navigation at start. The Menu panel is gone: Info holds its links and the version, Ctrl+Q quits, and Options and Hotkeys are non-`modal` popups that open one at a time as the panels do (`gui/popup_group.gd`) and leave the view usable. Panels no longer overlap at any window or GUI Size, and the GUI fades while the view is dragged and when idle (both in Options).
* Turned off `IVCoreSettings.apply_gl_compatibility_shadows`, so the Compatibility renderer — and with it the web export — takes one unshadowed light instead of the shadowed multi-light stack. This cuts each lit shader from four GL programs to one, which is a large part of the cold-start shader compile the boot screen reports; what it costs is local shadow maps, in practice the ISS shadowing itself. The analytic ring, eclipse and transit shadows are unaffected.
* Turned on the Core plugin's new `IVCoreSettings.apply_empty_shadow_pass_skip`, which drops the local shadow passes in any view with no spacecraft or local scene near the camera — 27-30 ms of a frame on weak integrated graphics. With `apply_gl_compatibility_shadows` off above, this acts on desktop Forward+ only.
* Graphics defaults are fitted to each machine's GPU and screen through the Core plugin's new `IVSettingsManager.graphics_target`, set to `BROAD_HARDWARE`, which starts integrated graphics, the web and dense screens with lighter settings.
* Enabled the Core plugin's new "Renderer" Option by naming `user://override.cfg` as the project settings override. Forward+ is the default wherever it runs.
* Intel graphics run the Compatibility renderer through ANGLE's Direct3D 11 path: `rendering/gl_compatibility/force_angle_on_devices` adds every Intel GPU to Godot's own list. ANGLE draws Saturn's rings, which Intel's OpenGL driver does not, and the atmosphere views faster; see *Open questions* in the Core plugin's GRAPHICS_PROFILING.md.
* Removed the 59 fps cap (`application/run/max_fps`), a workaround for the Core plugin's old SubViewport IVFragmentIdentifier that no longer exists. The Core plugin's new "Frame Rate Cap" Option now sets the rate, uncapped by default.
* The web export no longer defaults GUI Size to Large, which stood in for the screen scale that the Core plugin's new display scale now applies on every platform.
* Rearranged the Options and Hotkeys columns (`preinitializer.gd`).
* Panel margins, separations and spacers follow GUI Size, through the Core plugin's new IVControlModSpacing and its IVControlModResizable.
* Attribution docs restructured: `IVOYAGER_WORKS.md` is retired and replaced by `IVOYAGER_ASSETS.md`, which documents every distributed asset individually with its own copyright and license; `3RD_PARTY.md` becomes a clean list by copyright holder. README.md updated to match.
* [Dev ongoing] Sync attribution docs with assets and Core submodule.
* [Dev ongoing] Updating plugin ivoyager_core with v0.2.1.dev.
* [Dev ongoing] Updating plugin ivoyager_tables with v0.2.1.dev.
* [Dev ongoing] Updating plugin ivoyager_assistant with v0.0.3.dev.
* [Dev ongoing] Updating submodule tools (unversioned).


## [v0.2] - 2026-08-01

Released using Godot 4.7.1.

### Changed
* Sync 3RD_PARTY.md, IVOYAGER_WORKS.md and CREDITS.md with assets and Core submodule.
* Added IVStarsVisual to scene tree (required by Core plugin changes).
* Added IVScreenshotDialog to scene tree (required by Core plugin changes).
* Set METER := 1.0 (was 1e-3). Core plugin changes cured the scale sensitivity that forced the smaller value.
* Updated plugin ivoyager_core to v0.2.
* Updated plugin ivoyager_assistant to v0.0.2.
* Moved directory /tools and TRAJECTORIES.md into new submodule addons/tools. Its README.md indexes our asset generation and data conversion pipelines.


## [v0.1.2] - 2025-06-29

Released using Godot 4.7.

### Added
* IVOYAGER_WORKS.md now documents *our* derived works (compliments existing 3RD_PARTY.md).
* Directory /tools has python scripts needed for real-spacecraft trajectory development. See Core submodule IVTrajectory addition.
* Plugin ivoyager_assistant v0.0.1.dev. Under development to allow AI tests and (eventually) AI assistance for accessibility (e.g., voice navigation).

### Changed
* Removed IVFragmentIdentifier from scene tree. (New system in Core.)
* Updated plugin ivoyager_core to v0.1.2.
* Updated plugin ivoyager_tables to v0.1.2.
* Updated plugin ivoyager_units to v0.1.2.
* Completed doc comments in all files.


## [v0.1.1] - 2026-02-09

Released using Godot 4.6.

### Changed
* Removed unneeded/unmaintained website text in README.md.
* Updated plugin ivoyager_core to v0.1.1.
* Updated plugin ivoyager_tables to v0.1.1.
* Updated plugin ivoyager_units to v0.1.1.


## [v0.1] - 2025-12-13

Beta release!

Released using Godot 4.5.1.

### Changed
* Updated GUI for new Core plugin widgets.
* Replaced 3RD_PARTY.txt with updated and more human-readable 3RD_PARTY.md, and updated CREDITS.md.
* Code updates for plugin API changes.
* Updated plugin ivoyager_core to v0.1.
* Updated plugin ivoyager_tables to v0.1.
* Updated plugin ivoyager_units to v0.1.

## [v0.0.25] - 2025-06-12

Released using Godot 4.4.1.

### Changed
* Updated plugin ivoyager_core to v0.0.25.
* Updated plugin ivoyager_tables to v0.0.4.
* Updated plugin ivoyager_units to v0.0.4.

## [v0.0.24] - 2025-03-31

Released using Godot 4.4.

### Changed
* Changed scale and various Rendering settings to support shadows.
* Updated plugin ivoyager_core to v0.0.24.
* Updated plugin ivoyager_tables to v0.0.3.
* Updated plugin ivoyager_units to v0.0.3.

## [v0.0.23] - 2025-03-20

Released using Godot 4.4.

### Changed
* Typed all dictionaries.
* Many code updates for plugin changes.
* Updated plugin ivoyager_core to v0.0.23.
* Updated plugin ivoyager_tables to v0.0.2.
* Updated plugin ivoyager_units to v0.0.2.

## [v0.0.22] - 2025-03-07

Released using Godot 4.3. **We will update to 4.4 in the next release!**

### Changed
* Updated plugin "ivoyager_core" to v0.0.22. This moves game save/load functionality out to a separate plugin, which doesn't affect the Planetarium except to remove unused code.


## [v0.0.21] - 2025-01-07

Released using Godot 4.3.

### Changed
* Updated plugin 'ivoyager_core' to v0.0.21.
* Replaced depreciated plugin 'ivoyager_table_importer' with two plugins from split: 'ivoyager_tables' and 'ivoyager_units' (both v0.0.1).

## [v0.0.20] - 2024-12-20

Released using Godot 4.3.

### Changed
* Updated custom godot.html shell using Godot 4.3's current master.
* Updated plugin 'ivoyager_core' to v0.0.20.
* Updated plugin 'ivoyager_table_importer' to v0.0.9.

## [v0.0.19] - 2024-12-16

Released using Godot 4.3.

### Changed
* Updated plugin 'ivoyager_core' to v0.0.19.
* Updated plugin 'ivoyager_table_importer' to v0.0.8.


## [v0.0.18] - 2024-03-15

Released using Godot 4.2.1. _Has backward breaking changes!_

**NEW!** ivoyager_core editor plugin will download and add (or replace) assets for you. Just press 'Download' if prompted.

### Changed
* Gets project version from project.godot.
* Updated plugin 'ivoyager_core' to v0.0.18.
* Updated plugin 'ivoyager_table_importer' to v0.0.7.

## [v0.0.17] - 2023-10-03

Released using Godot 4.1.1.

Requires non-Git-tracked **ivoyager_assets-0.0.17**. Download from ivoyager_core [releases](https://github.com/ivoyager/ivoyager_core/releases) and add as res://addons/ivoyager_assets.

### Changed
* Replaced submodule [ivoyager](https://github.com/ivoyager/ivoyager) with addons/[ivoyager_core](https://github.com/ivoyager/ivoyager_core), which now operates as an editor plugin.
* All code now expects ivoyager_assets to be in the 'addons' directory.


## [v0.0.16] - 2023-09-25

**We've migrated to Godot 4!**

Released using Godot 4.1.1.

Requires non-Git-tracked **ivoyager_assets-0.0.16**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases).

### Added
* Table Reader [ivoyager_table_reader](https://github.com/ivoyager/ivoyager_table_importer) added as editor plugin. (Functionality was previously in core 'ivoyager'.)

### Changed
* Many migration changes. See core ivoyager [migration changes](https://github.com/ivoyager/ivoyager/blob/master/CHANGELOG.md).

## [v0.0.15] - 2023-07-24

Released using Godot 3.5.2. **This is the final release using Godot 3.x!**

Requires non-Git-tracked **ivoyager_assets-0.0.14**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases).

### Changed
* Updated submodule 'ivoyager' to v0.0.15.

## [v0.0.14] - 2023-03-15

Released using Godot 3.5.2.

Requires non-Git-tracked **ivoyager_assets-0.0.14**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases).

### Changed
* Overhauled GUI to interact with new content and systems in core ivoyager.
* Updated submodule 'ivoyager' to v0.0.14.

### Fixed
* Excessive calls to _resize() causing info_panel.gd crash (visible as info display corruption)

## [v0.0.13] - 2022-09-28

Released using Godot 3.5.1.

Requires non-Git-tracked **ivoyager_assets-0.0.10**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases).

### Added
* Added ViewCacher to Planetarium (moved from 'ivoyager' submodule)
* Added dialog for Progressive Web App version update.

### Changed
* Cached view now includes HUDs visibility states (orbits, names, icons, and asteroid points).
* Updated submodule 'ivoyager' to v0.0.13.

## [v0.0.12] - 2022-01-20

Released using Godot 3.4.2.stable AND a custom Godot build that fixes PWA caching (Faless' [3.x_pwa_prefer_cache branch](https://github.com/godotengine/godot/compare/3.x...Faless:js/3.x_pwa_prefer_cache), commit bf61f9c).

Requires non-Git-tracked **ivoyager_assets-0.0.10**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases).

### Added
* Update in ivoyager v0.0.12 allows caching of time info (time, speed, reverse time) when not in 'present' time.

### Changed
* Updated submodule 'ivoyager' to v0.0.12.

### Fixed
* Update in ivoyager v0.0.12 fixes GUI for cached body start. 

## [v0.0.11] - 2022-01-19

Released using Godot 3.4.2.stable AND a custom Godot build that fixes PWA caching (Faless' [3.x_pwa_prefer_cache branch](https://github.com/godotengine/godot/compare/3.x...Faless:js/3.x_pwa_prefer_cache), commit bf61f9c).

Requires non-Git-tracked **ivoyager_assets-0.0.10**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases).

### Added
* (Re-)Enabled view caching. Caches current camera view every 1 sec (for HTML5 export) or on quit (all other platforms).

### Changed
* Added project-level si_base_unit.gd static class and removed universe.tscn & universe.gd to support 'ivoyager' submodule changes.
* Removed FullScreenManager from planetarium. Moved functionality to new IVWindowManager in core ivoyager.
* Updated submodule 'ivoyager' to v0.0.11.

## [v0.0.10] - 2022-01-09

Planetarium v0.0.10 is now deployed as a [Progressive Web App (PWA)!](https://godotengine.org/article/godot-web-progress-report-8) Try it at https://ivoyager.dev/planetarium!

Released using Godot 3.4.2.stable AND a custom Godot build that fixes PWA caching (Faless' [3.x_pwa_prefer_cache branch](https://github.com/godotengine/godot/compare/3.x...Faless:js/3.x_pwa_prefer_cache), commit bf61f9c).

Requires non-Git-tracked **ivoyager_assets-0.0.10**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases). For web deployment we use the "-web" version.

### Added
* Project-level 'web' directory containing assets for PWA deployment. See [web/README.md](https://github.com/ivoyager/planetarium/tree/master/web).
* A project-level CHANGELOG.md!

### Changed
* 'Boot' scene greatly simplified; previous content is now in html loading page.
* Updated submodule 'ivoyager' to v0.0.10.


[v0.2]: https://github.com/ivoyager/planetarium/compare/v0.1.2...v0.2
[v0.1.2]: https://github.com/ivoyager/planetarium/compare/v0.1.1...v0.1.2
[v0.1.1]: https://github.com/ivoyager/planetarium/compare/v0.1...v0.1.1
[v0.1]: https://github.com/ivoyager/planetarium/compare/v0.0.25...v0.1
[v0.0.25]: https://github.com/ivoyager/planetarium/compare/v0.0.24...v0.0.25
[v0.0.24]: https://github.com/ivoyager/planetarium/compare/v0.0.23...v0.0.24
[v0.0.23]: https://github.com/ivoyager/planetarium/compare/v0.0.22...v0.0.23
[v0.0.22]: https://github.com/ivoyager/planetarium/compare/v0.0.21...v0.0.22
[v0.0.21]: https://github.com/ivoyager/planetarium/compare/v0.0.20...v0.0.21
[v0.0.20]: https://github.com/ivoyager/planetarium/compare/v0.0.19...v0.0.20
[v0.0.19]: https://github.com/ivoyager/planetarium/compare/v0.0.18...v0.0.19
[v0.0.18]: https://github.com/ivoyager/planetarium/compare/v0.0.17...v0.0.18
[v0.0.17]: https://github.com/ivoyager/planetarium/compare/v0.0.16...v0.0.17
[v0.0.16]: https://github.com/ivoyager/planetarium/compare/v0.0.15...v0.0.16
[v0.0.15]: https://github.com/ivoyager/planetarium/compare/v0.0.14...v0.0.15
[v0.0.14]: https://github.com/ivoyager/planetarium/compare/v0.0.13...v0.0.14
[v0.0.13]: https://github.com/ivoyager/planetarium/compare/v0.0.12...v0.0.13
[v0.0.12]: https://github.com/ivoyager/planetarium/compare/v0.0.11...v0.0.12
[v0.0.11]: https://github.com/ivoyager/planetarium/compare/v0.0.10...v0.0.11
[v0.0.10]: https://github.com/ivoyager/planetarium/compare/v0.0.9-alpha...v0.0.10
