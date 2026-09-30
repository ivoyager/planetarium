# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

I, Voyager Planetarium — an open-source 3D solar system simulator built on **Godot Engine 4.7+** using **GDScript**. Displays accurate orbital mechanics for planets, moons, spacecraft, and ~70k asteroids. Runs as a Windows desktop app or Progressive Web App.

## Running the Project

Open in Godot Editor and press Play. No external build system — Godot handles everything.

**First-time setup:** Clone with `--recursive` for submodules. The editor plugin auto-downloads assets (~216 MiB) on first run — press "Download" when prompted.

**Export targets** (defined in `export_presets.cfg`):
- Web: `export/planetarium-rc.html` (PWA, single-threaded). `variant/thread_support` is off and
  stays off: SharedArrayBuffer needs cross-origin isolation headers, which is more than we will
  ask of a host. Don't propose threading as a fix for anything.
- Windows: `export/Planetarium-v0.1.exe` (x86_64)

There is no test framework or linter beyond Godot's built-in GDScript warnings.

**Shader compile time is the dominant first-run cost on the Compatibility renderer, and so in
the web export** — a cold start through ANGLE spends about a minute and a half compiling on the
development laptop, nearly all of it behind the boot screen via the Core plugin's
`IVShaderWarmup`.

`addons/ivoyager_core/GRAPHICS_PROFILING.md` is the measured record of what the graphics cost a
weak machine, on each render path this project's reference laptop gives: per frame, what each
graphics option and each automatic saving buys back and what it costs on screen, and what the
fitted defaults deliver; and once, what each shader costs to compile and what drives it (the GL
compiler unrolling constant-bound loops, and FXC inlining every call, which is why
`_atmosphere.gdshaderinc` reaches each heavy function from one call site — THE STRUCTURE in its
header), what editing a given `.gdshaderinc` costs, where the shader caches live and how to
measure it all again. Read it before touching a shader, hand-unrolling anything, or proposing,
adding or retuning a graphics option. The compile-timing harness is
`addons/tools/time_shader_compiles.py`, run from this directory.

### GDScript Warning Preferences

All GDScript code should compile with **zero warnings**. Apply these strategies:

- **UNSAFE_CALL_ARGUMENT / UNSAFE_METHOD_ACCESS / UNSAFE_PROPERTY_ACCESS** — Fix by editing code. For built-in types, assign the Variant to a properly typed intermediate variable before passing it to a typed function parameter or constructor (e.g., `int()` requires `int`/`float`/`bool`, not `Variant`). Note: `as ClassName` generates UNSAFE_CAST — avoid it; direct assignment from `Object`-typed dictionary `.get()` to a typed member variable does not warn.
- **UNUSED_VARIABLE** — Prefix with `_` (e.g., `for _k in count:`).
- **INTEGER_DIVISION** — Suppress with `@warning_ignore("integer_division")` where integer division is intentional.
- **SHADOWED_VARIABLE** — Suppress with `@warning_ignore("shadowed_variable")` only in static functions where shadowing the instance variable is expected. In all other cases, rename the variable to avoid shadowing.

## Architecture

### Design documents

Three documents in `addons/ivoyager_core/` describe the simulation at the level of logic and
invariants, each with its own TODO list. Read the relevant one before changing that subsystem:

- `PHYSICAL_MODEL.md` — the objective simulation: bodies, orbits as an element coordinate
  system, trajectories, rotation, time, units and scale, small-body groups, the persisted
  state and what a multiplayer sync would need.
- `VISUAL_MODEL.md` — how that double-precision truth renders through a float32 pipeline:
  parenting, origin shifting, farwarp, the shadow systems, culling, orbit lines, point fields,
  mouse picking.
- `PHOTOMETRIC_MODEL.md` — physically calibrated light: the calibration chain, the
  compensating camera, surfaces, atmospheres, rings, stars, renderer parity.

**These are what a code comment points AT, not something a code comment restates.** A file
header says what the file is, how to use it and what will bite a caller; the model behind it —
the derivation, the measurements, the alternatives weighed, the defect that motivated a term —
belongs in one of these documents, and the header names the section. Two copies of one fact
means the code copy is the one that goes stale, because nobody re-reads a shader header. When a
mechanism or a value changes, grep for everything that describes it.

`addons/ivoyager_core/IVBody_REDESIGN_v0.3.md` is the living plan for the IVBody rework;
`PHYSICAL_MODEL.md` and `VISUAL_MODEL.md` link to it. When the redesign lands and that file
goes away, remove those links.

### Plugin System (Git Submodules)

The core simulation lives in three plugins under `addons/`, each a git submodule:

- **ivoyager_core** — Orbital simulation engine, 3D rendering, camera, UI widgets, singletons
- **ivoyager_tables** — CSV-based data table import system (planet/moon/asteroid data)
- **ivoyager_units** — Unit conversion system (template replaced by `planetarium/units.gd`)

Two more submodules support development:

- **ivoyager_assistant** — In-sim TCP/JSON-RPC server for AI-driven testing (see *Testing with the Assistant Plugin*)
- **tools** — Python asset-generation and data-conversion scripts; not a Godot plugin (see *Asset & Data Pipelines*)

A further directory, `addons/ivoyager_assets/`, holds 3D models and textures (not Git-tracked, downloaded by the editor plugin). It is also the deploy target of a separate private build tree — see *Changing a distributed asset* below before writing anything into it.

### Planetarium Shell (`planetarium/`)

This repo is a thin "shell" that configures and extends the core plugins:

- `universe.gd` / `universe.tscn` — Main scene root (extends `Node3D`)
- `preinitializer.gd` — Primary configuration entry point: sets `IVCoreSettings`, registers program objects, configures timekeeper and speed manager
- `units.gd` — Replaces the default `IVUnits` singleton (sets the `METER` sim scale constant)
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

The `METER` constant in `planetarium/units.gd` controls world scale. Lighting and shadows have historically been extremely sensitive to it, in ways that varied by Godot version and export platform. As of Godot 4.7 with the ivoyager_core 0.2.dev shadow system, that sensitivity appears resolved — `METER = 1.0` (current) and `1e-3` both look correct in Forward+ and Compatibility, though HTML5 export is untested at the current value. That file keeps the running record of scale issues per version; read it before changing the constant, and add findings there.

## Asset & Data Pipelines

Body models, texture maps, star binaries and generated table data are all produced by Python scripts in the **`addons/tools/`** submodule. **`addons/tools/README.md` indexes every pipeline** — go there to find the script for an existing one, or to add a new one. It also carries the conventions they share: run from the project directory, where outputs go, the attribution entry a new asset needs, and the reimport step required after writing a `.tsv` or an asset. Each script's module docstring is its full specification.

Spacecraft trajectory and ephemeris work has its own reference, **`addons/tools/TRAJECTORIES.md`** (the patched-conic model, the NASA/JPL HORIZONS source and query pipeline, the HORIZONS → `orbits.tsv` mapping, gap closing/segmentation, time base, and known imprecisions). Read it only when creating or working with spacecraft trajectories.

### Changing a distributed asset

`addons/ivoyager_assets/` is the **deploy target** of `C:/godot/ivoyager_assets_build/`, a separate private repository holding the original source imagery, the repair inputs, the correction parameters and the provenance record for every map, mesh and model we ship. Most asset work belongs there, not here; that repo's `CLAUDE.md` is its specification.

If you add, replace, re-level, rename or retire anything under `addons/ivoyager_assets/`, two steps are required from this side and neither is optional:

- **Read `C:/godot/ivoyager_assets_build/ATTRIBUTION_MIRRORS.md`, then update the attribution documents.** Every distributed asset needs an entry in `IVOYAGER_ASSETS.md`, plus a listing in `3RD_PARTY.md` if any part of its content is third-party. `CREDITS.md` takes the acknowledgments the other two do not carry. All three are mastered in `C:/godot/asset_downloads/` and mirrored byte-identical into seven locations — three of them inside this repository (the project root, `addons/ivoyager_core/` and `addons/ivoyager_assets/`) — so editing only the copy in front of you leaves the set silently divergent. That file specifies what belongs in which document, how a copyright claim is decided, where every copy lives, and the hash sweep that verifies them.
- **Record the work in `C:/godot/ivoyager_assets_build/records/<Body>.md`** — what the source is, why it was chosen over the alternatives, every defect found, and every modification applied with its parameters. Write it as the work happens. That private record is what makes the public attribution documents writable months later, and the documents themselves are forbidden to carry history, so anything not written down there is lost.

Neither step applies to a change confined to this repository — a shader, a table value, a scene.

## Branching

- `master` — stable releases
- `develop` — active development

## Testing with the Assistant Plugin

When running the Planetarium for testing:

- **Godot executable:** Find the most recent `Godot_v*_console.exe` (or `godot*.console.exe`) in the parent directory of this project (i.e., `../`). Use the `_console` variant to see stdout. If no Godot executable is found there, ask the user for the path.
- **Launch command:** `"<godot_console_exe>" --path "<project_dir>" --windowed --position 0,0 --resolution 1920x1080`
- **TCP interface:** The `AssistantServer` listens on `127.0.0.1:29071` after the simulator starts. Use `addons/ivoyager_assistant/tools/assistant_client.sh` to send JSON-RPC commands.
- **Get a clean frame before judging a render, and confirm it rather than assume it.** `screenshot`'s `hide_gui` hides the 2D GUI and nothing else: orbit lines, body names, symbols and the small-body point cloud all keep drawing over the subject, and they are the first thing to remove when the question is what a body or a shader actually looks like. Call `set_huds` with `{"visible": false}` — it is **absolute**, where the `toggle_*` actions are toggles whose result depends on the state the session started in, so pressing `toggle_orbits` on a session that already hides them turns them ON. Read the flags it returns back. Restore with `{"visible": true}` when the run is about the GUI.
- **`move_camera`'s `view_position` is measured in whatever frame the camera is TRACKING, and the default is not body-relative.** Pass `tracking: "ground"` to pose relative to the target's own equator — that is the mode in which latitude is a latitude *on the body*, and so the only one in which "20 degrees above the ring plane" or "over the north pole" means what it says. `"orbit"` (the default) and `"ecliptic"` measure latitude in a frame the body's obliquity is tilted from: on Saturn, ecliptic latitude 0 leaves the rings ~26 degrees open and −26 puts them edge-on. Whatever you pose, **measure the geometry back** from the app rather than trusting the number you sent.
- **The user's cached views are staging you should reuse, not re-derive.** `list_cached_views` and `apply_cached_view` reproduce a framing (and its HUD state) that the maintainer set up and saved by hand; check for one before hunting for a pose with `move_camera`.
- **Quit step:** Always call `quit` with `{"force":true}` as the **last test step**. This calls `IVStateManager.quit(true)` which performs a clean shutdown and reveals errors such as orphan nodes in the Godot console output.

## License

Apache License 2.0. All source files carry the standard I, Voyager copyright header.

This does **not** extend to `addons/ivoyager_assets/`. Those files are licensed individually — many are third-party, several are public domain, and only some are I, Voyager works under Apache 2.0. `IVOYAGER_ASSETS.md` states the copyright and license of each one; `3RD_PARTY.md` lists the third-party content by holder and license, with the license texts in full.
