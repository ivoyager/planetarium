# planetarium.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright (c) 2017-2021 Charlie Whitfield
# I, Voyager is a registered trademark of Charlie Whitfield
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
# This extension works in three different "platforms":
#  1. The native app: Windows (or whatever) export w/ ivoyager_assets.
#  2. Web deployment: GLES2; HTML5 export w/ ivoyager_assets_web; running from
#     a web server.
#  3. [DEPRECIATE]
#     Electron app: GLES2, HTML5 export w/ ivoyager_assets; drop the exported 
#     project into our "electron app" (github.com/ivoyager/electron_app) and
#     run with npm start, or deploy that project with electron-forge. This
#     integrates the planetarium with its own browser.
#  3. [TODO] Native apps w/ lightweight browser (maybe Electron) with
#     restricted access to Wiki, NASA, etc.
#
# Note: In Godot 3.x, HTML5 export should use GLES2.

const EXTENSION_NAME := "Planetarium"
const EXTENSION_VERSION := "0.0.9-dev"
const EXTENSION_VERSION_YMD := 20210302

const USE_THREADS := true # false for debugging; HTML5 overrides to false


func _extension_init() -> void:
	printt("%s (HTML5 = %s, GLES2 = %s)" % [EXTENSION_NAME, Global.is_html5, Global.is_gles2])
	Global.connect("project_objects_instantiated", self, "_on_program_objects_instantiated")
	Global.connect("project_inited", self, "_on_project_inited")
	Global.connect("simulator_started", self, "_on_simulator_started")
	ProjectBuilder.program_builders.erase("_SaveBuilder_")
	ProjectBuilder.program_nodes.erase("_SaveManager_")
	ProjectBuilder.gui_controls.erase("_SaveDialog_")
	ProjectBuilder.gui_controls.erase("_LoadDialog_")
	ProjectBuilder.gui_controls.erase("_SplashScreen_")
	ProjectBuilder.gui_controls.erase("_MainMenuPopup_")
	ProjectBuilder.gui_controls.erase("_MainProgBar_")
	ProjectBuilder.program_nodes._ViewCaching_ = ViewCaching
	ProjectBuilder.program_nodes._FullScreenManager_ = FullScreenManager
	ProjectBuilder.gui_controls._ProjectGUI_ = GUITop
	Global.use_threads = USE_THREADS
	Global.project_name = "Planetarium"
	Global.enable_save_load = false
	Global.allow_real_world_time = true
	Global.allow_time_reversal = true
	Global.home_view_from_user_time_zone = true
	Global.disable_pause = true
	Global.skip_splash_screen = true
	Global.disable_exit = true
	Global.enable_wiki = true
	Global.popops_can_stop_sim = false
	if Global.is_html5:
		Global.use_threads = false
		ProjectBuilder.gui_controls.erase("_MainProgBar_")
		Global.disable_quit = true
		Global.vertecies_per_orbit = 200

func _on_program_objects_instantiated() -> void:
	var model_builder: ModelBuilder = Global.program.ModelBuilder
	model_builder.max_lazy = 10
	var timekeeper: Timekeeper = Global.program.Timekeeper
	timekeeper.start_real_world_time = true
	var huds_manager: HUDsManager = Global.program.HUDsManager
	huds_manager.show_names = true
	huds_manager.show_orbits = true
	var qty_strings: QtyStrings = Global.program.QtyStrings
	qty_strings.exp_str = " x 10^"
	var theme_manager: ThemeManager = Global.program.ThemeManager
	theme_manager.main_menu_font = "gui_main"
	var hotkeys_popup: HotkeysPopup = Global.program.HotkeysPopup
	hotkeys_popup.remove_item("toggle_all_gui")
	hotkeys_popup.add_item("cycle_next_panel", "LABEL_CYCLE_NEXT_PANEL", "LABEL_GUI")
	hotkeys_popup.add_item("cycle_prev_panel", "LABEL_CYCLE_LAST_PANEL", "LABEL_GUI")
	var options_popup: OptionsPopup = Global.program.OptionsPopup
	options_popup.remove_item("starmap")
	var settings_manager: SettingsManager = Global.program.SettingsManager
	var default_settings := settings_manager.defaults
	if Global.is_html5:
		default_settings.gui_size = Enums.GUISize.GUI_LARGE
		var view_caching: ViewCaching = Global.program.ViewCaching
		view_caching.cache_interval = 5.0
	if Global.is_gles2:
		# try to compensate for Gles2 color differences
		default_settings.planet_orbit_color =  Color(0.6,0.6,0.2)
		default_settings.dwarf_planet_orbit_color = Color(0.1,0.9,0.2)
		default_settings.moon_orbit_color = Color(0.3,0.3,0.9)
		default_settings.minor_moon_orbit_color = Color(0.6,0.2,0.6)

func _on_project_inited() -> void:
	pass

func _on_simulator_started() -> void:
	pass
