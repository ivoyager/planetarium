# initializer.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright 2017-2023 Charlie Whitfield
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

# This file modifies ivoyager_core settings and classes.
#
# As of v0.0.10, the Planetarium is mainly being developed as a Progressive Web
# App (PWA). However, it should be exportable to other, non-HTML5 platforms.
#
# Godot 3.4.2+ supports multithreading in HTML5 exports. But we are keeping
# single thread for maximum browser compatibility.

const VERSION := "v0.0.17-dev"

const USE_THREADS := true # set false for debugging
const NO_THREADS_IF_HTML5 := true # overrides above

const VERBOSE_GLOBAL_SIGNALS := false
const VERBOSE_STATEMANAGER_SIGNALS := false


func _init() -> void:
	
	print("Planetarium %s - https://ivoyager.dev" % VERSION)
	
	if VERBOSE_GLOBAL_SIGNALS and OS.is_debug_build:
		IVDebug.signal_verbosely_all(IVGlobal, "Global")
	
	IVGlobal.project_objects_instantiated.connect(_on_program_objects_instantiated)
	IVGlobal.project_nodes_added.connect(_on_project_nodes_added)
	IVGlobal.simulator_started.connect(_on_simulator_started)
	
	if NO_THREADS_IF_HTML5 and IVGlobal.is_html5:
		IVCoreSettings.use_threads = false
	else:
		IVCoreSettings.use_threads = USE_THREADS
	print("HTML5 = %s, threads = %s" % [IVGlobal.is_html5, IVCoreSettings.use_threads])
	
	IVCoreSettings.project_name = "Planetarium"
	IVCoreSettings.project_version = VERSION
	
	IVCoreSettings.enable_save_load = false
	IVCoreSettings.allow_time_setting = true
	IVCoreSettings.allow_time_reversal = true
	IVCoreSettings.pause_only_stops_time = true
	IVCoreSettings.skip_splash_screen = true
	IVCoreSettings.disable_exit = true
	IVCoreSettings.enable_wiki = true
	IVCoreSettings.enable_precisions = true
	IVCoreSettings.popops_can_stop_sim = false
	
	var time_zone := Time.get_time_zone_from_system()
	if time_zone and time_zone.has("bias"):
		IVCoreSettings.home_longitude = time_zone.bias * TAU / 1440.0
	
	if IVGlobal.is_html5:
		IVCoreInitializer.gui_nodes.erase("_MainProgBar_")
		IVCoreSettings.disable_quit = true
		IVCoreSettings.vertecies_per_orbit = 200
		
	# class changes
	IVCoreInitializer.program_refcounteds.erase("_SaveBuilder_")
	IVCoreInitializer.program_nodes.erase("_SaveManager_")
	IVCoreInitializer.gui_nodes.erase("_SaveDialog_")
	IVCoreInitializer.gui_nodes.erase("_LoadDialog_")
	IVCoreInitializer.gui_nodes.erase("_SplashScreen_")
	IVCoreInitializer.gui_nodes.erase("_MainMenuPopup_")
	IVCoreInitializer.gui_nodes.erase("_MainProgBar_")
	IVCoreInitializer.gui_nodes.erase("_CreditsPopup_")
	IVCoreInitializer.gui_nodes.erase("_GameGUI_")
	IVCoreInitializer.gui_nodes.erase("_SplashScreen_")
	IVCoreInitializer.program_nodes._GUIToggler_ = GUIToggler
	IVCoreInitializer.program_nodes._ViewCacher_ = ViewCacher
	IVCoreInitializer.gui_nodes._PlanetariumGUI_ = PlanetariumGUI
	IVCoreInitializer.gui_nodes._BootScreen_ = BootScreen # added on top; self-frees
	
	# static class changes
	IVQFormat.exponent_str = " x 10^"


func _on_program_objects_instantiated() -> void:
	
	if OS.is_debug_build and VERBOSE_STATEMANAGER_SIGNALS:
		var state_manager: IVStateManager = IVGlobal.program.StateManager
		IVDebug.signal_verbosely_all(state_manager, "StateManager")
	
	IVGlobal.get_viewport().gui_embed_subwindows = true # root default is true, contrary to docs
	
	var timekeeper: IVTimekeeper = IVGlobal.program.Timekeeper
	timekeeper.start_real_world_time = true
	var view_defaults: IVViewDefaults = IVGlobal.program.ViewDefaults
	view_defaults.move_home_at_start = false # ViewCacher does initial camera move
	var theme_manager: IVThemeManager = IVGlobal.program.ThemeManager
	theme_manager.main_menu_font = "gui_main"
	var window_manager: IVWindowManager = IVGlobal.program.WindowManager
	window_manager.add_menu_button = true
#	var hotkeys_popup: IVHotkeysPopup = IVGlobal.program.HotkeysPopup
#	hotkeys_popup.add_item("cycle_next_panel", "LABEL_CYCLE_NEXT_PANEL", "LABEL_GUI")
#	hotkeys_popup.add_item("cycle_prev_panel", "LABEL_CYCLE_LAST_PANEL", "LABEL_GUI")
#	var options_popup: IVOptionsPopup = IVGlobal.program.OptionsPopup
#	options_popup.remove_item("starmap") # web assets only have 8k starmap

#	var settings_manager: IVSettingsManager = IVGlobal.program.SettingsManager
#	var default_settings := settings_manager.defaults
#
#	if IVGlobal.is_html5:
#		var view_cacher: ViewCacher = IVGlobal.program.ViewCacher
#		view_cacher.cache_interval = 2.0
#		default_settings.gui_size = IVEnums.GUISize.GUI_LARGE



func _on_project_nodes_added() -> void:
	IVCoreInitializer.move_top_gui_child_to_sibling(&"PlanetariumGUI", &"MouseTargetLabel", false)


# progressive web app (PWA) updating

func _on_simulator_started() -> void:
	# FIXME GODOT4 MIGRATION: PWA function after we have HTML5 export
	pass
#	if IVGlobal.is_html5:
#		if JavaScript.pwa_needs_update():
#			_on_pwa_update_available()
#		else:
#			JavaScript.connect("pwa_update_available", Callable(self, "_on_pwa_update_available"))


func _on_pwa_update_available() -> void:
	# FIXME GODOT4 MIGRATION: PWA function after we have HTML5 export
	pass
#	print("PWA update available!")
#	IVGlobal.confirmation_requested.emit("TXT_PWA_UPDATE_AVAILABLE", _update_pwa, true,
#			"LABEL_UPDATE_RESTART_Q", "BUTTON_UPDATE", "BUTTON_RUN_WITHOUT_UPDATE")


func _update_pwa() -> void:
	# FIXME GODOT4 MIGRATION: PWA function after we have HTML5 export
	pass
#	print("Updating PWA!")
#	JavaScript.pwa_update()

