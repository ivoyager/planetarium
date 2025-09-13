# preinitializer.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright 2017-2025 Charlie Whitfield
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

# This file modifies operation if plugins ivoyager_core & ivoyager_units.

const USE_THREADS := true # set false for debugging
const DISABLE_THREADS_IF_WEB := true # override for browser compatibility
const VERBOSE_GLOBAL_SIGNALS := false
const VERBOSE_STATEMANAGER_SIGNALS := false


func _init() -> void:
	
	var version: String = ProjectSettings.get_setting("application/config/version")
	print("Planetarium %s - https://ivoyager.dev" % version)
	
	if VERBOSE_GLOBAL_SIGNALS and OS.is_debug_build:
		IVDebug.signal_verbosely_all(IVGlobal, "Global")
	
	IVGlobal.project_objects_instantiated.connect(_on_program_objects_instantiated)
	IVGlobal.project_nodes_added.connect(_on_project_nodes_added)
	IVGlobal.simulator_started.connect(_on_simulator_started)
	var is_web := OS.has_feature("web")
	IVCoreSettings.use_threads = USE_THREADS and !(is_web and DISABLE_THREADS_IF_WEB)
	print("web = %s, threads = %s" % [is_web, IVCoreSettings.use_threads])
	
	IVCoreSettings.project_name = "Planetarium"
	IVCoreSettings.project_version = version
	IVCoreSettings.allow_time_setting = true
	IVCoreSettings.allow_time_reversal = true
	IVCoreSettings.pause_only_stops_time = true
	IVCoreSettings.skip_splash_screen = true
	IVCoreSettings.disable_exit = true
	IVCoreSettings.enable_precisions = true
	IVCoreSettings.popops_can_stop_sim = false
	
	var time_zone := Time.get_time_zone_from_system()
	if time_zone and time_zone.has("bias"):
		IVCoreSettings.home_longitude = time_zone.bias * TAU / 1440.0
	
	if is_web:
		IVCoreInitializer.gui_nodes.erase("MainProgBar")
		IVCoreSettings.disable_quit = true
		IVCoreSettings.vertecies_per_orbit = 200
		IVSettingsManager.defaults[&"gui_size"] = IVGlobal.GUISize.GUI_LARGE
		
	# class changes
	IVCoreInitializer.program_refcounteds["WikiManager"] = IVWikiManager
	IVCoreInitializer.gui_nodes.erase("MainMenuPopup")
	IVCoreInitializer.gui_nodes.erase("MainProgBar")
	IVCoreInitializer.program_nodes["GUIToggler"] = GUIToggler
	IVCoreInitializer.program_nodes["ViewCacher"] = ViewCacher
	IVCoreInitializer.gui_nodes["PlanetariumGUI"] = PlanetariumGUI
	IVCoreInitializer.gui_nodes["BootScreen"] = BootScreen # added on top; self-frees
	
	# other singleton changes
	IVQFormat.exponent_str = " x 10^"
	
	# static class changes
	IVTableInitializer.wiki_page_title_fields.append(&"en.wikipedia")


func _on_program_objects_instantiated() -> void:
	
	if OS.is_debug_build and VERBOSE_STATEMANAGER_SIGNALS:
		var state_manager: IVStateManager = IVGlobal.program[&"StateManager"]
		IVDebug.signal_verbosely_all(state_manager, "StateManager")
	
	IVGlobal.get_viewport().gui_embed_subwindows = true # root default is true, contrary to docs
	
	var timekeeper: IVTimekeeper = IVGlobal.program[&"Timekeeper"]
	timekeeper.start_real_world_time = true
	var view_manager: IVViewManager = IVGlobal.program[&"ViewManager"]
	view_manager.move_home_at_start = false # ViewCacher does initial camera move
	var table_orbit_builder: IVTableOrbitBuilder = IVGlobal.program[&"TableOrbitBuilder"]
	table_orbit_builder.use_real_planet_orbits = true
	var wiki_manager: IVWikiManager = IVGlobal.program[&"WikiManager"]
	wiki_manager.open_external_page = true
	
	if OS.has_feature("web"):
		var view_cacher: ViewCacher = IVGlobal.program.ViewCacher
		view_cacher.cache_interval = 2.0


func _on_project_nodes_added() -> void:
	IVCoreInitializer.move_top_gui_child_to_sibling(&"PlanetariumGUI", &"MouseTargetLabel", false)


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
	IVGlobal.confirmation_requested.emit("TXT_PWA_UPDATE_AVAILABLE", _update_pwa, true,
			"LABEL_UPDATE_RESTART_Q", "BUTTON_UPDATE", "BUTTON_RUN_WITHOUT_UPDATE")


func _update_pwa() -> void:
	print("Updating PWA!")
	JavaScriptBridge.pwa_update()
