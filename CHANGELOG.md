# Changelog

This file documents changes to the Planetarium project only. For changes to the core submodule (ivoyager) and core assets (ivoyager_assets directory), see [ivoyager/CHANGELOG.md](https://github.com/ivoyager/ivoyager/blob/master/CHANGELOG.md).

File format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

See cloning and downloading instructions [here](https://www.ivoyager.dev/devs/).

## [v0.0.10] - 2022-01-09

Planetarium v0.0.10 is now deployed as a [Progressive Web App (PWA)!](https://godotengine.org/article/godot-web-progress-report-8) Try it at https://ivoyager.dev/planetarium!

Developed using Godot 3.4.2.stable AND a custom Godot build that fixes PWA caching (Faless' [3.x_pwa_prefer_cache branch](https://github.com/godotengine/godot/compare/3.x...Faless:js/3.x_pwa_prefer_cache), commit bf61f9c).

Requires non-Git-tracked **ivoyager_assets-0.0.10**; find in [ivoyager releases](https://github.com/ivoyager/ivoyager/releases). For web deployment we use the "-web" version.

### Added
* Project-level 'web' directory containing assets for PWA deployment. See [web/README.md](https://github.com/ivoyager/planetarium/tree/master/web).
* A project-level CHANGELOG.md!

### Changed
* 'Boot' scene greatly simplified; previous content is now in html loading page.

##
*Older project-level changes are documented in* [ivoyager/CHANGELOG.md](https://github.com/ivoyager/ivoyager/blob/master/CHANGELOG.md).

[v0.0.10]: https://github.com/ivoyager/planetarium/compare/v0.0.9-alpha...v0.0.10-alpha
