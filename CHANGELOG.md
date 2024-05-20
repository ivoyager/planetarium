# Changelog

This file documents changes to the Planetarium "shell" project only. For changes to the core simulator code, go [here](https://github.com/ivoyager/ivoyager_core/blob/master/CHANGELOG.md).

File format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

See cloning and downloading instructions [here](https://www.ivoyager.dev/developers/).

## [v0.0.19] - Not Released

Under development using Godot 4.2.2.

### Changed
* Updated plugin 'ivoyager_core' to v0.0.19.dev.
* Updated plugin 'ivoyager_table_importer' to v0.0.8.dev.
* Updated plugin 'ivoyager_tree_saver' to v0.0.2.dev.


## [v0.0.18] - 2024-03-15

Developmed using Godot 4.2.1. _Has backward breaking changes!_

**NEW!** ivoyager_core editor plugin will download and add (or replace) assets for you. Just press 'Download' if prompted.

### Changed
* Gets project version from project.godot.
* Updated plugin 'ivoyager_core' to v0.0.18.
* Updated plugin 'ivoyager_table_importer' to v0.0.7.

## [v0.0.17] - 2023-10-03

Developed for Godot 4.1.1.

Requires non-Git-tracked **ivoyager_assets-0.0.17**. Download from ivoyager_core [releases](https://github.com/ivoyager/ivoyager_core/releases) and add as res://addons/ivoyager_assets.

### Changed
* Replaced submodule [ivoyager](https://github.com/ivoyager/ivoyager) with addons/[ivoyager_core](https://github.com/ivoyager/ivoyager_core), which now operates as an editor plugin.
* All code now expects ivoyager_assets to be in the 'addons' directory.


## [v0.0.16] - 2023-09-25

**We've migrated to Godot 4!**

Developed for Godot 4.1.1.

Requires non-Git-tracked **ivoyager_assets-0.0.16**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases).

### Added
* Table Reader [ivoyager_table_reader](https://github.com/ivoyager/ivoyager_table_importer) added as editor plugin. (Functionality was previously in core 'ivoyager'.)

### Changed
* Many migration changes. See core ivoyager [migration changes](https://github.com/ivoyager/ivoyager/blob/master/CHANGELOG.md).

## [v0.0.15] - 2023-07-24

Developed for Godot 3.5.2. **This is the final release using Godot 3.x!**

Requires non-Git-tracked **ivoyager_assets-0.0.14**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases).

### Changed
* Updated submodule 'ivoyager' to v0.0.15.

## [v0.0.14] - 2023-03-15

Developed for Godot 3.5.2.

Requires non-Git-tracked **ivoyager_assets-0.0.14**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases).

### Changed
* Overhauled GUI to interact with new content and systems in core ivoyager.
* Updated submodule 'ivoyager' to v0.0.14.

### Fixed
* Excessive calls to _resize() causing info_panel.gd crash (visible as info display corruption)

## [v0.0.13] - 2022-09-28

Developed for Godot 3.5.1.

Requires non-Git-tracked **ivoyager_assets-0.0.10**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases).

### Added
* Added ViewCacher to Planetarium (moved from 'ivoyager' submodule)
* Added dialog for Progressive Web App version update.

### Changed
* Cached view now includes HUDs visibility states (orbits, names, icons, and asteroid points).
* Updated submodule 'ivoyager' to v0.0.13.

## [v0.0.12] - 2022-01-20

Developed using Godot 3.4.2.stable AND a custom Godot build that fixes PWA caching (Faless' [3.x_pwa_prefer_cache branch](https://github.com/godotengine/godot/compare/3.x...Faless:js/3.x_pwa_prefer_cache), commit bf61f9c).

Requires non-Git-tracked **ivoyager_assets-0.0.10**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases).

### Added
* Update in ivoyager v0.0.12 allows caching of time info (time, speed, reverse time) when not in 'present' time.

### Changed
* Updated submodule 'ivoyager' to v0.0.12.

### Fixed
* Update in ivoyager v0.0.12 fixes GUI for cached body start. 

## [v0.0.11] - 2022-01-19

Developed using Godot 3.4.2.stable AND a custom Godot build that fixes PWA caching (Faless' [3.x_pwa_prefer_cache branch](https://github.com/godotengine/godot/compare/3.x...Faless:js/3.x_pwa_prefer_cache), commit bf61f9c).

Requires non-Git-tracked **ivoyager_assets-0.0.10**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases).

### Added
* (Re-)Enabled view caching. Caches current camera view every 1 sec (for HTML5 export) or on quit (all other platforms).

### Changed
* Added project-level si_base_unit.gd static class and removed universe.tscn & universe.gd to support 'ivoyager' submodule changes.
* Removed FullScreenManager from planetarium. Moved functionality to new IVWindowManager in core ivoyager.
* Updated submodule 'ivoyager' to v0.0.11.

## [v0.0.10] - 2022-01-09

Planetarium v0.0.10 is now deployed as a [Progressive Web App (PWA)!](https://godotengine.org/article/godot-web-progress-report-8) Try it at https://ivoyager.dev/planetarium!

Developed using Godot 3.4.2.stable AND a custom Godot build that fixes PWA caching (Faless' [3.x_pwa_prefer_cache branch](https://github.com/godotengine/godot/compare/3.x...Faless:js/3.x_pwa_prefer_cache), commit bf61f9c).

Requires non-Git-tracked **ivoyager_assets-0.0.10**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases). For web deployment we use the "-web" version.

### Added
* Project-level 'web' directory containing assets for PWA deployment. See [web/README.md](https://github.com/ivoyager/planetarium/tree/master/web).
* A project-level CHANGELOG.md!

### Changed
* 'Boot' scene greatly simplified; previous content is now in html loading page.
* Updated submodule 'ivoyager' to v0.0.10.


[v0.0.19]: https://github.com/ivoyager/planetarium/compare/v0.0.18...HEAD
[v0.0.18]: https://github.com/ivoyager/planetarium/compare/v0.0.17...v0.0.18
[v0.0.17]: https://github.com/ivoyager/planetarium/compare/v0.0.16...v0.0.17
[v0.0.16]: https://github.com/ivoyager/planetarium/compare/v0.0.15...v0.0.16
[v0.0.15]: https://github.com/ivoyager/planetarium/compare/v0.0.14...v0.0.15
[v0.0.14]: https://github.com/ivoyager/planetarium/compare/v0.0.13...v0.0.14
[v0.0.13]: https://github.com/ivoyager/planetarium/compare/v0.0.12...v0.0.13
[v0.0.12]: https://github.com/ivoyager/planetarium/compare/v0.0.11...v0.0.12
[v0.0.11]: https://github.com/ivoyager/planetarium/compare/v0.0.10...v0.0.11
[v0.0.10]: https://github.com/ivoyager/planetarium/compare/v0.0.9-alpha...v0.0.10
