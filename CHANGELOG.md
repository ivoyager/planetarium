# Changelog

This file documents changes to the Planetarium project only. For changes to the core submodule (ivoyager) and core assets (ivoyager_assets directory), see [ivoyager/CHANGELOG.md](https://github.com/ivoyager/ivoyager/blob/master/CHANGELOG.md).

File format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

See cloning and downloading instructions [here](https://www.ivoyager.dev/download/).

## [Unreleased v0.0.10] - TBD

The main goal for v0.0.10 is to deploy the Planetarium as a [Progressive Web App (PWA)](https://godotengine.org/article/godot-web-progress-report-8). 

Under development using Godot 3.4.2.stable AND a custom Godot build that fixes PWA caching (Faless' [3.x_pwa_prefer_cache branch](https://github.com/godotengine/godot/compare/3.x...Faless:js/3.x_pwa_prefer_cache), commit bf61f9c).

Requires non-Git-tracked [development assets from 2021-12-28](https://github.com/ivoyager/non_release_assets/releases/tag/2021-12-28).

### Added
* A project level CHANGELOG.md!
* Top level 'planetarium_assets' directory with PWA icon assets. Because there aren't many non-core assets here, we are allowing these to be Git tracked.

### Changed
* For web deployment, a custom html loading page provides content previously in a "boot" Godot scene. See new project-level directory `web/` containing 'godot.html' (the Custom Html Shell) and pale-blue-dot-512.jpeg (to be added to HTML5 export).

##
*Older project-level changes are documented in* [ivoyager/CHANGELOG.md](https://github.com/ivoyager/ivoyager/blob/master/CHANGELOG.md).

[Unreleased v0.0.10]: https://github.com/ivoyager/planetarium/compare/v0.0.9-alpha...HEAD
