# planetarium.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright (c) 2017-2021 Charlie Whitfield
# "I, Voyager" is a registered trademark of Charlie Whitfield
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
#  3. Electron app: GLES2, HTML5 export w/ ivoyager_assets; drop the exported 
#     project into our "electron app" (github.com/ivoyager/electron_app) and
#     run with npm start, or deploy that project with electron-forge. This
#     integrates the planetarium with its own browser.
#
# Note: In Godot 3.x, HTML5 export should use GLES2.

extends Reference

const EXTENSION_NAME := "Planetarium"
const EXTENSION_VERSION := "0.0.8-dev"
const EXTENSION_VERSION_YMD := 20210123

const USE_THREADS := true # false for debugging; HTML5 overrides to false
const IS_ELECTRON_APP := false

var _is_html5: bool = OS.has_feature('JavaScript')
var _is_gles2: bool = ProjectSettings.get_setting("rendering/quality/driver/driver_name") == "GLES2"
var _use_web_assets := FileUtils.is_valid_dir("res://ivoyager_assets_web")


func extension_init() -> void:
	ProjectBuilder.connect("project_objects_instantiated", self, "_on_project_objects_instantiated")
	ProjectBuilder.connect("project_inited", self, "_on_project_inited")
	Global.connect("simulator_started", self, "_on_simulator_started")
	print("HTML5 ", _is_html5, "; GLES2 ", _is_gles2, "; Web Assets ", _use_web_assets)
	ProjectBuilder.program_nodes._ViewCaching_ = ViewCaching
	ProjectBuilder.program_nodes._FullScreenManager_ = FullScreenManager
	ProjectBuilder.gui_controls._ProjectGUI_ = PltmGUI # replacement
	ProjectBuilder.gui_controls.erase("_MainMenuPopup_")
	ProjectBuilder.gui_controls.erase("_LoadDialog_")
	ProjectBuilder.gui_controls.erase("_SaveDialog_")
	ProjectBuilder.program_references.erase("_SaverLoader_")
	Global.is_electron_app = IS_ELECTRON_APP
	Global.use_threads = USE_THREADS
	Global.project_name = "I, Voyager Planetarium"
	Global.enable_save_load = false
	Global.allow_real_world_time = true
	Global.allow_time_reversal = true
	Global.home_view_from_user_time_zone = true
	Global.disable_pause = true
	Global.skip_splash_screen = true
	Global.disable_exit = true
	Global.enable_wiki = true
	ProjectBuilder.gui_controls.erase("_SplashScreen_")
	if _is_html5:
		Global.use_threads = false
		ProjectBuilder.gui_controls.erase("_MainProgBar_")
	if _is_html5 and !IS_ELECTRON_APP:
		Global.disable_quit = true
	if _use_web_assets:
		Global.vertecies_per_orbit = 200
		Global.asset_replacement_dir = "ivoyager_assets_web"

func _on_project_objects_instantiated() -> void:
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
	var credits_popup: CreditsPopup = Global.program.CreditsPopup
	credits_popup.stop_sim = false
	var hotkeys_popup: HotkeysPopup = Global.program.HotkeysPopup
	hotkeys_popup.stop_sim = false
	hotkeys_popup.remove_item("toggle_all_gui")
	hotkeys_popup.add_item("cycle_next_panel", "LABEL_CYCLE_NEXT_PANEL", "LABEL_GUI")
	hotkeys_popup.add_item("cycle_prev_panel", "LABEL_CYCLE_LAST_PANEL", "LABEL_GUI")
	var options_popup: OptionsPopup = Global.program.OptionsPopup
	options_popup.stop_sim = false
	var settings_manager: SettingsManager = Global.program.SettingsManager
	var default_settings := settings_manager.defaults
	if _is_html5:
		default_settings.gui_size = Enums.GUISize.GUI_LARGE
	if _is_html5 and !IS_ELECTRON_APP:
		var view_caching: ViewCaching = Global.program.ViewCaching
		view_caching.cache_interval = 5.0
	if _use_web_assets:
		options_popup.remove_item("starmap")
	if _is_gles2:
		# try to compensate for Gles2 color differences
		default_settings.planet_orbit_color =  Color(0.6,0.6,0.2)
		default_settings.dwarf_planet_orbit_color = Color(0.1,0.9,0.2)
		default_settings.moon_orbit_color = Color(0.3,0.3,0.9)
		default_settings.minor_moon_orbit_color = Color(0.6,0.2,0.6)

func _on_project_inited() -> void:
	if _is_html5:
		print("Loading HTML5 Boot Screen")
		var boot_res: PackedScene = load("res://ivoyager/gui_admin/html5_boot_screen.tscn")
		var boot := boot_res.instance()
		Global.program.universe.add_child(boot)
		Global.connect("gui_refresh_requested", boot, "queue_free")

func _on_simulator_started() -> void:
	pass
	# Scheduler test below
#	var scheduler: Scheduler = Global.program.Scheduler
#	scheduler.interval_connect(1.0 * UnitDefs.HOUR, self, "_print", ["1.0 hr"])
#	scheduler.interval_connect(2.0 * UnitDefs.HOUR, self, "_print", ["2.0 hr"])
#	scheduler.interval_connect(4.0 * UnitDefs.HOUR, self, "_print", ["4.0 hr"])
#	scheduler.interval_connect(3.0 * UnitDefs.HOUR, self, "_print", ["3.0 hr Oneshot"], CONNECT_ONESHOT)
#	scheduler.interval_connect(5.0 * UnitDefs.HOUR, self, "_print", ["5.0 hr Oneshot"], CONNECT_ONESHOT)
#
#func _print(text: String) -> void:
#	if text == "4.0 hr":
#		Global.program.Scheduler.interval_disconnect(4.0 * UnitDefs.HOUR, self, "_print")
#	print(text)
