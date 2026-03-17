# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

I, Voyager Planetarium — an open-source 3D solar system simulator built on **Godot Engine 4.6+** using **GDScript**. Displays accurate orbital mechanics for planets, moons, spacecraft, and ~70k asteroids. Runs as a Windows desktop app or Progressive Web App.

## Running the Project

Open in Godot Editor and press Play. No external build system — Godot handles everything.

**First-time setup:** Clone with `--recursive` for submodules. The editor plugin auto-downloads assets (~216 MiB) on first run — press "Download" when prompted.

**Export targets** (defined in `export_presets.cfg`):
- Web: `export/planetarium-rc.html` (PWA with SharedArrayBuffer threading)
- Windows: `export/Planetarium-v0.1.exe` (x86_64)

There is no test framework or linter beyond Godot's built-in GDScript warnings.

### GDScript Warning Preferences

All GDScript code should compile with **zero warnings**. Apply these strategies:

- **UNSAFE_CALL_ARGUMENT / UNSAFE_METHOD_ACCESS / UNSAFE_PROPERTY_ACCESS** — Fix by editing code. For built-in types, assign the Variant to a properly typed intermediate variable before passing it to a typed function parameter or constructor (e.g., `int()` requires `int`/`float`/`bool`, not `Variant`). Note: `as ClassName` generates UNSAFE_CAST — avoid it; direct assignment from `Object`-typed dictionary `.get()` to a typed member variable does not warn.
- **UNUSED_VARIABLE** — Prefix with `_` (e.g., `for _k in count:`).
- **INTEGER_DIVISION** — Suppress with `@warning_ignore("integer_division")` where integer division is intentional.
- **SHADOWED_VARIABLE** — Suppress with `@warning_ignore("shadowed_variable")` only in static functions where shadowing the instance variable is expected. In all other cases, rename the variable to avoid shadowing.

## Architecture

### Plugin System (Git Submodules)

The core simulation lives in three plugins under `addons/`, each a git submodule:

- **ivoyager_core** — Orbital simulation engine, 3D rendering, camera, UI widgets, singletons
- **ivoyager_tables** — CSV-based data table import system (planet/moon/asteroid data)
- **ivoyager_units** — Unit conversion system (template replaced by `planetarium/units.gd`)

A fourth directory, `addons/ivoyager_assets/`, holds 3D models and textures (not Git-tracked, downloaded by the editor plugin).

### Planetarium Shell (`planetarium/`)

This repo is a thin "shell" that configures and extends the core plugins:

- `universe.gd` / `universe.tscn` — Main scene root (extends `Node3D`)
- `preinitializer.gd` — Primary configuration entry point: sets `IVCoreSettings`, registers program objects, configures timekeeper and speed manager
- `units.gd` — Replaces the default `IVUnits` singleton (critical `METER = 1e-3` scale constant)
- `view_cacher.gd` — Caches/restores camera positions
- `gui/` — GUI panels composed from `ivoyager_core/ui_widgets/`

### Initialization Pipeline

1. `ivoyager_override.cfg` tells the core plugin to use custom `units.gd` and `preinitializer.gd`
2. `preinitializer.gd._init()` configures `IVCoreSettings` and registers program objects
3. `IVCoreInitializer` instantiates singletons and program objects
4. `IVStateManager` fires ordered signals: `core_init_program_objects_instantiated` → `system_tree_built` → `simulator_started`
5. Solar system tree is procedurally built from table data

### Key Singletons (Autoloads)

`IVGlobal`, `IVStateManager`, `IVCoreInitializer`, `IVCoreSettings`, `IVAstronomy`, `IVSettingsManager`, `IVUnits`, `IVQConvert`, `IVQFormat`, `IVTableData`

### Signal-Based Communication

Components are decoupled via signals on `IVStateManager` and `IVGlobal`. Hook into state transitions (e.g., `simulator_started`) rather than polling.

## Critical: Scale and Lighting

The `METER` constant in `planetarium/units.gd` controls world scale. It is set to `1e-3` for Godot 4.5+ to support shadows at both planetary and spacecraft scales. **Changing this value breaks lighting/shadows** in platform-specific ways. See the extensive comments in that file before modifying.

## Branching

- `master` — stable releases
- `develop` — active development

## Testing with the Assistant Plugin

When running the Planetarium for testing:

- **Godot executable:** Find the most recent `Godot_v*_console.exe` (or `godot*.console.exe`) in the parent directory of this project (i.e., `../`). Use the `_console` variant to see stdout. If no Godot executable is found there, ask the user for the path.
- **Launch command:** `"<godot_console_exe>" --path "<project_dir>" --windowed --position 0,0 --resolution 1920x1080`
- **TCP interface:** The `AssistantServer` listens on `127.0.0.1:29071` after the simulator starts. Use `addons/ivoyager_assistant/tools/assistant_client.sh` to send JSON-RPC commands.
- **Quit step:** Always call `quit` with `{"force":true}` as the **last test step**. This calls `IVStateManager.quit(true)` which performs a clean shutdown and reveals errors such as orphan nodes in the Godot console output.

## License

Apache License 2.0. All source files carry the standard I, Voyager copyright header.
