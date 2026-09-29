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
## any other program object.

## Whether to use threads for sim work. Set [code]false[/code] for debugging.
const USE_THREADS := true # set false for debugging
## When [code]true[/code], threads are disabled in web exports for browser
## compatibility (overrides [constant USE_THREADS] when running in a browser).
const DISABLE_THREADS_IF_WEB := true # override for browser compatibility
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
	var graphics_tier: String = IVGraphicsManager.GraphicsTier.keys()[
			IVGraphicsManager.get_graphics_tier()]
	print("web = %s, threads = %s, graphics tier = %s"
			% [is_web, IVCoreSettings.use_threads, graphics_tier])
	
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
	IVSettingsManager.graphics_target = IVSettingsManager.GraphicsTarget.BROAD_HARDWARE
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
	# The reload can come before the start's check does, and would count as a failed start.
	IVSettingsManager.mark_start_finished()
	await IVGlobal.get_tree().process_frame # Godot saves user:// to IndexedDB between frames
	JavaScriptBridge.pwa_update()
