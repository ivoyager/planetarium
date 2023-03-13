# planetarium.gd
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
extends Reference

# This file modifies init values in IVGlobal and classes in IVProjectBuilder.
#
# As of v0.0.10, the Planetarium is mainly being developed as a Progressive Web
# App (PWA). However, it should be exportable to other, non-HTML5 platforms.
#
# In Godot 3.x, HTML5 export should use GLES2.
# Godot 3.4.2+ supports multithreading in HTML5 exports. But we are keeping
# single thread for maximum browser compatibility.

const EXTENSION_NAME := "Planetarium"
const EXTENSION_VERSION := "0.0.14"
const EXTENSION_BUILD := ""
const EXTENSION_STATE := "dev" # 'dev', 'alpha', 'beta', 'rc', ''
const EXTENSION_YMD := 20230312 # displayed if EXTENSION_STATE = 'dev'

const USE_THREADS := false # set false for debugging
const NO_THREADS_IF_HTML5 := true # overrides above


func _extension_init() -> void:
	
	print("%s %s%s-%s %s" % [EXTENSION_NAME, EXTENSION_VERSION, EXTENSION_BUILD, EXTENSION_STATE,
			str(EXTENSION_YMD)])
			
	IVGlobal.connect("project_objects_instantiated", self, "_on_program_objects_instantiated")
	IVGlobal.connect("project_nodes_added", self, "_on_project_nodes_added")
	IVGlobal.connect("simulator_started", self, "_on_simulator_started")
	
	if NO_THREADS_IF_HTML5 and IVGlobal.is_html5:
		IVGlobal.use_threads = false
	else:
		IVGlobal.use_threads = USE_THREADS
	print("HTML5 = %s, GLES2 = %s, threads = %s"
			% [IVGlobal.is_html5, IVGlobal.is_gles2, IVGlobal.use_threads])
	
	IVGlobal.project_name = EXTENSION_NAME
	IVGlobal.project_version = EXTENSION_VERSION
	IVGlobal.project_build = EXTENSION_BUILD
	IVGlobal.project_state = EXTENSION_STATE
	IVGlobal.project_ymd = EXTENSION_YMD
	
	IVGlobal.enable_save_load = false
	IVGlobal.allow_time_setting = true
	IVGlobal.allow_time_reversal = true
	IVGlobal.pause_only_stops_time = true
	IVGlobal.skip_splash_screen = true
	IVGlobal.disable_exit = true
	IVGlobal.enable_wiki = true
	IVGlobal.popops_can_stop_sim = false
	
	var time_zone := Time.get_time_zone_from_system()
	if time_zone and time_zone.has("bias"):
		IVGlobal.home_longitude = time_zone.bias * TAU / 1440.0
	
	
	if IVGlobal.is_html5:
		IVProjectBuilder.gui_nodes.erase("_MainProgBar_")
		IVGlobal.disable_quit = true
		IVGlobal.vertecies_per_orbit = 200
		
	# class changes
	IVProjectBuilder.prog_refs.erase("_SaveBuilder_")
	IVProjectBuilder.prog_nodes.erase("_SaveManager_")
	IVProjectBuilder.gui_nodes.erase("_SaveDialog_")
	IVProjectBuilder.gui_nodes.erase("_LoadDialog_")
	IVProjectBuilder.gui_nodes.erase("_SplashScreen_")
	IVProjectBuilder.gui_nodes.erase("_MainMenuPopup_")
	IVProjectBuilder.gui_nodes.erase("_MainProgBar_")
	IVProjectBuilder.gui_nodes.erase("_CreditsPopup_")
	IVProjectBuilder.gui_nodes.erase("_GameGUI_")
	IVProjectBuilder.gui_nodes.erase("_SplashScreen_")
	IVProjectBuilder.prog_nodes._GUIToggler_ = GUIToggler
	IVProjectBuilder.prog_nodes._ViewCacher_ = ViewCacher
	IVProjectBuilder.gui_nodes._PlanetariumGUI_ = PlanetariumGUI
	IVProjectBuilder.gui_nodes._BootScreen_ = BootScreen # added on top; self-frees


func _on_program_objects_instantiated() -> void:
	var timekeeper: IVTimekeeper = IVGlobal.program.Timekeeper
	timekeeper.start_real_world_time = true
	var quantity_formatter: IVQuantityFormatter = IVGlobal.program.QuantityFormatter
	quantity_formatter.exp_str = " x 10^"
	var theme_manager: IVThemeManager = IVGlobal.program.ThemeManager
	theme_manager.main_menu_font = "gui_main"
	var window_manager: IVWindowManager = IVGlobal.program.WindowManager
	window_manager.add_menu_button = true
#	var hotkeys_popup: IVHotkeysPopup = IVGlobal.program.HotkeysPopup
#	hotkeys_popup.add_item("cycle_next_panel", "LABEL_CYCLE_NEXT_PANEL", "LABEL_GUI")
#	hotkeys_popup.add_item("cycle_prev_panel", "LABEL_CYCLE_LAST_PANEL", "LABEL_GUI")
	var options_popup: IVOptionsPopup = IVGlobal.program.OptionsPopup
	options_popup.remove_item("starmap") # web assets only have 8k starmap

	var settings_manager: IVSettingsManager = IVGlobal.program.SettingsManager
	var default_settings := settings_manager.defaults
	if IVGlobal.is_html5:
		var view_cacher: ViewCacher = IVGlobal.program.ViewCacher
		view_cacher.cache_interval = 2.0
		default_settings.gui_size = IVEnums.GUISize.GUI_LARGE
	if IVGlobal.is_gles2:
		# try to compensate for Gles2 color differences
		pass
#		default_settings.planet_orbit_color =  Color(0.6,0.6,0.2)
#		default_settings.dwarf_planet_orbit_color = Color(0.1,0.9,0.2)
#		default_settings.moon_orbit_color = Color(0.3,0.3,0.9)
#		default_settings.minor_moon_orbit_color = Color(0.6,0.2,0.6)


func _on_project_nodes_added() -> void:
	IVProjectBuilder.move_top_gui_child_to_sibling("PlanetariumGUI", "MouseTargetLabel", false)


func _on_simulator_started() -> void:
	if IVGlobal.is_html5:
		if JavaScript.pwa_needs_update():
			_on_pwa_update_available()
		else:
			JavaScript.connect("pwa_update_available", self, "_on_pwa_update_available")


func _on_pwa_update_available() -> void:
	print("PWA update available!")
	IVOneUseConfirm.new("TXT_PWA_UPDATE_AVAILABLE", self, "_update_pwa", [], false,
			"LABEL_UPDATE_RESTART_Q", "BUTTON_UPDATE", "BUTTON_CONTINUE")


func _update_pwa() -> void:
	print("Updating PWA!")
	JavaScript.pwa_update()


