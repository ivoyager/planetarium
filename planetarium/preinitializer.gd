# preinitializer.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield
# I, Voyager is a registered trademark of Charlie Whitfield in the US
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *****************************************************************************
extends RefCounted

## Primary initialization entry point for the Planetarium shell.
##
## Configures [IVCoreSettings], registers program objects via
## [IVCoreInitializer], and sets up [IVTimekeeper] / [IVSpeedManager] / view
## state once core init signals fire. Hooked in via
## [code]res://ivoyager_override.cfg[/code]'s [code]preinitializer[/code]
## key, which causes the core plugin to instantiate this RefCounted before
## any other program object.[br][br]
##
## On desktop, a run whose renderer differs from the [code]renderer[/code] user
## setting (e.g. the first run on integrated graphics, which defaults to
## Compatibility) restarts itself into it before the rest of init; see [constant
## KEEP_RENDERER_ARG] to prevent that.

## Whether to use threads for sim work. Set [code]false[/code] for debugging.
const USE_THREADS := true # set false for debugging
## When [code]true[/code], threads are disabled in web exports for browser
## compatibility (overrides [constant USE_THREADS] when running in a browser).
const DISABLE_THREADS_IF_WEB := true # override for browser compatibility
## Command-line user argument (after [code]++[/code]) that keeps the renderer a run
## started with. The renderer restart passes it, so a restarted run never restarts
## again. Pass it for a run that picks its GPU on the command line, e.g.
## [code]--gpu-index[/code] for an integrated GPU under Forward+: without it, that
## run restarts into Compatibility and leaves Compatibility for every later run.
const KEEP_RENDERER_ARG := "--keep-renderer"
## Default key and Hotkeys-list label of each panel button action in
## [code]gui/focus_gui.tscn[/code].
const PANEL_ACTIONS: Dictionary[StringName, Array] = {
	&"toggle_selection_details" : [KEY_1, &"LABEL_SHOW_HIDE_SELECTION_DETAILS"],
	&"toggle_navigation_panel" : [KEY_2, &"LABEL_SHOW_HIDE_NAVIGATION_PANEL"],
	&"toggle_huds_panel" : [KEY_3, &"LABEL_SHOW_HIDE_HUDS_PANEL"],
	&"toggle_view_panel" : [KEY_4, &"LABEL_SHOW_HIDE_VIEW_PANEL"],
	&"toggle_info_panel" : [KEY_5, &"LABEL_SHOW_HIDE_INFO_PANEL"],
}
#const VERBOSE_GLOBAL_SIGNALS := false
#const VERBOSE_STATEMANAGER_SIGNALS := false


func _init() -> void:
	
	var version: String = ProjectSettings.get_setting("application/config/version")
	print("Planetarium v%s - https://ivoyager.dev" % version)
	
	#if VERBOSE_GLOBAL_SIGNALS and OS.is_debug_build:
		#IVDebug.signal_verbosely_all(IVGlobal, "Global")
	
	IVStateManager.core_init_program_objects_instantiated.connect(
			_on_core_init_program_objects_instantiated)
	IVStateManager.simulator_started.connect(_on_simulator_started)
	var is_web := OS.has_feature("web")
	IVCoreSettings.use_threads = USE_THREADS and !(is_web and DISABLE_THREADS_IF_WEB)
	print("web = %s, threads = %s" % [is_web, IVCoreSettings.use_threads])
	
	IVCoreSettings.allow_fullscreen_toggle = true
	IVCoreSettings.allow_time_setting = true
	IVCoreSettings.allow_time_reversal = true
	IVCoreSettings.disable_exit = true
	IVCoreSettings.enable_precisions = true
	IVCoreSettings.popops_can_stop_sim = false
	IVCoreSettings.manage_engine_time_scale = false
	IVCoreSettings.stroboscope_frames_per_second = 4.5
	IVCoreSettings.enable_physical_light = true # user Options toggle "Physical Light"
	IVCoreSettings.apply_gl_compatibility_shadows = false # only ISS self-shadowing. No big loss.
	# With the line above false there are no shadow maps under Compatibility, so this acts
	# only on Forward+ - which is where the empty passes cost 20-25 ms a frame.
	IVCoreSettings.apply_empty_shadow_pass_skip = true
	
	if is_web:
		IVCoreSettings.disable_quit = true
		#IVCoreSettings.vertecies_per_orbit = 200
	
	# On an integrated GPU, Compatibility runs 1.4-8x faster than Forward+, and the limb
	# shell is 75-95% of a frame with air, which the Reduced tier cuts by a quarter to a
	# third for no visible change (GRAPHICS_PROFILING.md in the Core plugin). A discrete
	# GPU keeps Forward+ and Normal, in either renderer. A GPU of unknown type is taken
	# as weak: only a Compatibility run can fail to know it, which on the desktop means
	# one that has never run Forward+ here, and on the web means every run.
	var video_adapter_type := IVGlobal.video_adapter_type
	if (video_adapter_type == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU
			or (video_adapter_type == RenderingDevice.DEVICE_TYPE_OTHER
			and IVGlobal.is_gl_compatibility)):
		IVSettingsManager.set_default(&"atmosphere_quality", 1) # reduced
		IVSettingsManager.set_default(&"renderer", 1) # compatibility
	if IVGraphicsManager.can_set_renderer():
		IVSettingsManager.initialized.connect(_restart_into_renderer_setting)

	# class changes
	IVCoreInitializer.program_nodes["FullScreenManager"] = IVFullScreenManager
	IVCoreInitializer.program_refcounteds["WikiManager"] = IVWikiManager
	IVCoreInitializer.program_nodes["ViewCacher"] = ViewCacher
	IVCoreInitializer.program_nodes["ShaderWarmup"] = IVShaderWarmup
	
	# other singleton changes
	IVQFormat.exponent_str = " ×10^"
	
	# static class changes
	IVTableInitializer.wiki_page_title_fields.append(&"en.wikipedia")
	IVTranslationImporter.translations.append(
			"res://planetarium/text/planetarium_text.en.translation")

	# User settings/options
	IVSettingsManager.set_default(&"terrestrial_time_clock", false)
	var options_popup: IVOptionsPopup = IVGlobal.get_node("/root/Universe/TopUI/OptionsPopup")
	options_popup.layout = [
		[&"LABEL_GUI_AND_HUD", &"LABEL_TIME"],
		[&"LABEL_CAMERA", &"LABEL_SCREENSHOTS"],
		[&"LABEL_GRAPHICS_PERFORMANCE"],
	]
	options_popup.section_content[&"LABEL_TIME"] = []
	options_popup.add_option(&"LABEL_TIME", &"LABEL_TERRESTRIAL_TIME_CLOCK",
			&"terrestrial_time_clock")
	options_popup.option_tooltips[&"terrestrial_time_clock"] = &"HINT_TERRESTRIAL_TIME_CLOCK"
	# The GUI's IVControlModFade reads these two.
	options_popup.add_option(&"LABEL_GUI_AND_HUD", &"LABEL_FADE_GUI_WHILE_DRAGGING",
			&"gui_fade_while_dragging", 2)
	options_popup.add_option(&"LABEL_GUI_AND_HUD", &"LABEL_FADE_GUI_WHEN_IDLE",
			&"gui_fade_when_idle", 3)
	options_popup.option_tooltips[&"gui_fade_while_dragging"] = &"HINT_FADE_GUI_WHILE_DRAGGING"
	options_popup.option_tooltips[&"gui_fade_when_idle"] = &"HINT_FADE_GUI_WHEN_IDLE"

	# User hotkeys
	var hotkeys_popup: IVHotkeysPopup = IVGlobal.get_node("/root/Universe/TopUI/HotkeysPopup")
	hotkeys_popup.layout = [
		[&"LABEL_ADMIN", &"LABEL_GUI"],
		[&"LABEL_TIME", &"LABEL_SELECTION"],
		[&"LABEL_CAMERA", &"LABEL_SCREENSHOTS"],
	]
	var gui_hotkeys: Array = hotkeys_popup.section_content[&"LABEL_GUI"]
	for action in PANEL_ACTIONS:
		var action_data := PANEL_ACTIONS[action]
		var keycode: Key = action_data[0]
		var label: StringName = action_data[1]
		var event_dict := {&"event_class" : &"InputEventKey", &"keycode" : keycode}
		IVInputMapManager.defaults[action] = [event_dict]
		IVInputMapManager.action_texts[action] = label
		gui_hotkeys.append(action)


# Godot fixes the renderer at engine start, so a run whose renderer setting has come to
# differ -- above all a first run whose default the adapter test changed -- restarts into
# it, before init builds anything.
func _restart_into_renderer_setting() -> void:
	if KEEP_RENDERER_ARG in OS.get_cmdline_user_args():
		return
	var running_method := RenderingServer.get_current_rendering_method()
	var configured_method: String = ProjectSettings.get_setting_with_override(
			&"rendering/renderer/rendering_method")
	if running_method != configured_method:
		return # the command line, or the engine's own fallback, chose this renderer
	var renderer: int = IVSettingsManager.get_setting(&"renderer")
	var rendering_method := IVGraphicsManager.get_rendering_method(renderer)
	if rendering_method == running_method:
		return
	var error := IVGraphicsManager.write_rendering_method(rendering_method)
	if error != OK:
		push_error("Could not write the renderer to the project settings override: "
				+ error_string(error))
		return
	print("Restarting with renderer %s" % rendering_method)
	IVCoreInitializer.init_sequence.clear() # ends init after this step
	var arguments := OS.get_cmdline_args()
	if !OS.has_feature("template"):
		# The engine consumes --path, but a run that isn't an export needs it back.
		arguments.append("--path")
		arguments.append(ProjectSettings.globalize_path("res://"))
	arguments.append("++")
	arguments.append_array(OS.get_cmdline_user_args())
	arguments.append(KEEP_RENDERER_ARG)
	OS.set_restart_on_exit(true, arguments)
	IVGlobal.get_tree().quit()


func _on_core_init_program_objects_instantiated() -> void:
	
	#if OS.is_debug_build and VERBOSE_STATEMANAGER_SIGNALS:
		#var state_manager: IVStateManager = IVGlobal.program[&"StateManager"]
		#IVDebug.signal_verbosely_all(state_manager, "StateManager")
	
	# FIXME: ?????
	IVGlobal.get_viewport().gui_embed_subwindows = true # root default is true, contrary to docs
	
	var timekeeper: IVTimekeeper = IVGlobal.program[&"Timekeeper"]
	timekeeper.operating_system_time_sync = true
	timekeeper.terrestrial_time_clock_user_setting = true
	timekeeper.recalculate_universal_time_offset = true
	
	var speed_manager: IVSpeedManager = IVGlobal.program[&"SpeedManager"]
	speed_manager.ease_curve = -1.5
	speed_manager.ease_seconds = 0.5
	speed_manager.speeds = [
		IVUnits.SECOND,
		IVUnits.SECOND * 10,
		IVUnits.SECOND * 100,
		IVUnits.SECOND * 1e3,
		IVUnits.SECOND * 1e4,
		IVUnits.SECOND * 1e5,
		IVUnits.SECOND * 1e6,
		IVUnits.SECOND * 1e7,
		IVUnits.SECOND * 1e8,
	]
	speed_manager.speed_names = [
		&"1x",
		&"10x",
		&"100x",
		&"1000x",
		&"10,000x",
		&"100,000x",
		&"1,000,000x",
		&"10,000,000x",
		&"100,000,000x",
	]
	
	var view_manager: IVViewManager = IVGlobal.program[&"ViewManager"]
	view_manager.set_view_on_start = &"" # ViewCacher does initial camera move
	var table_orbit_builder: IVTableOrbitBuilder = IVGlobal.program[&"TableOrbitBuilder"]
	table_orbit_builder.use_real_planet_orbits = true
	var wiki_manager: IVWikiManager = IVGlobal.program[&"WikiManager"]
	wiki_manager.open_external_page = true
	
	if OS.has_feature("web"):
		var view_cacher: ViewCacher = IVGlobal.program.ViewCacher
		view_cacher.cache_interval = 2.0


func _on_simulator_started() -> void:
	if OS.has_feature("web"):
		# progressive web app (PWA) updating
		var pwa_needs_update := JavaScriptBridge.pwa_needs_update()
		print("PWA nees update: ", pwa_needs_update)
		if pwa_needs_update:
			_on_pwa_update_available()
			return
		JavaScriptBridge.pwa_update_available.connect(_on_pwa_update_available)


func _on_pwa_update_available() -> void:
	print("PWA update available!")
	IVGlobal.confirmation_required.emit("TXT_PWA_UPDATE_AVAILABLE", _update_pwa, true,
			"LABEL_UPDATE_RESTART_Q", "BUTTON_UPDATE", "BUTTON_RUN_WITHOUT_UPDATE")


func _update_pwa() -> void:
	print("Updating PWA!")
	JavaScriptBridge.pwa_update()
