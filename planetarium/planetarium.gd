# planetarium.gd
# This file is part of I, Voyager (https://ivoyager.dev)
# *****************************************************************************
# Copyright (c) 2017-2020 Charlie Whitfield
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
const EXTENSION_VERSION := "0.0.7-alpha dev"
const EXTENSION_VERSION_YMD := 20200519

# dev settings
const USE_THREADS := false
const FORCE_WEB_BUILD := true
const FORCE_WEB_ASSETS := false

var _is_gles2: bool = ProjectSettings.get_setting("rendering/quality/driver/driver_name") == "GLES2"
var _has_web_assets := FileUtils.is_valid_dir("res://ivoyager_assets_web")
var _is_web_build := FORCE_WEB_BUILD or (_is_gles2 and _has_web_assets) # no threads, etc.
var _use_web_assets := FORCE_WEB_ASSETS or (_is_gles2 and _has_web_assets)
var _is_html5: bool = OS.has_feature('JavaScript')

func extension_init() -> void:
	ProjectBuilder.connect("project_objects_instantiated", self, "_on_project_objects_instantiated")
	ProjectBuilder.connect("project_inited", self, "_on_project_inited")
	print("Planetarium extension initing...")
	print("Web build: ", _is_web_build, "; web assets: ", _use_web_assets, "; GLES2: ", _is_gles2)
	ProjectBuilder.gui_controls._ProjectGUI_ = PlanetariumGUI # replacement
	ProjectBuilder.gui_controls._PlntrmHelpPopup_ = PlntrmHelpPopup # addition
	ProjectBuilder.gui_controls.erase("_LoadDialog_")
	ProjectBuilder.gui_controls.erase("_SaveDialog_")
	ProjectBuilder.program_references.erase("_SaverLoader_")
	Global.use_threads = USE_THREADS
	Global.project_name = "I, Voyager Planetarium"
	Global.enable_save_load = false
	Global.allow_real_world_time = true
	Global.allow_time_reversal = true
	Global.disable_pause = true
	Global.skip_splash_screen = true
	Global.disable_exit = true
	Global.enable_wiki = true
	ProjectBuilder.gui_controls.erase("_SplashScreen_")
	if _is_web_build:
		ProjectBuilder.gui_controls.erase("_MainProgBar_")
		Global.use_threads = false
		Global.vertecies_per_orbit = 200
	if _use_web_assets:
		Global.asset_replacement_dir = "ivoyager_assets_web"

func _on_project_objects_instantiated() -> void:
	var main_menu: MainMenu = Global.program.MainMenu
	main_menu.planetarium_mode = true
	var model_builder: ModelBuilder = Global.program.ModelBuilder
	model_builder.max_lazy = 10
	var timekeeper: Timekeeper = Global.program.Timekeeper
	timekeeper.start_real_world_time = true
	var tree_manager: TreeManager = Global.program.TreeManager
	tree_manager.show_names = true
	tree_manager.show_orbits = true
	var qty_strings: QtyStrings = Global.program.QtyStrings
	qty_strings.exp_str = " x 10^"
	var theme_manager: ThemeManager = Global.program.ThemeManager
	theme_manager.main_menu_font = "gui_main"
	var hotkeys_popup: HotkeysPopup = Global.program.HotkeysPopup
	hotkeys_popup.remove_item("toggle_full_screen")
	hotkeys_popup.remove_item("obtain_gui_focus")
	hotkeys_popup.remove_item("release_gui_focus")
	var settings_manager: SettingsManager = Global.program.SettingsManager
	var default_settings := settings_manager.defaults
	default_settings.lock_navigator = true # add
	default_settings.lock_time = true # add
	default_settings.lock_selection = true # add
	default_settings.lock_range = true # add
	default_settings.lock_info = true # add
	default_settings.lock_controls = false # add
	default_settings.gui_size = Enums.GUISizes.GUI_LARGE # change
	var options_popup: OptionsPopup = Global.program.OptionsPopup
	if _is_web_build:
		options_popup.remove_item("starmap")
	if _is_gles2:
		default_settings.planet_orbit_color =  Color(0.6,0.6,0.2)
		default_settings.dwarf_planet_orbit_color = Color(0.1,0.9,0.2)
		default_settings.moon_orbit_color = Color(0.3,0.3,0.9)
		default_settings.minor_moon_orbit_color = Color(0.6,0.2,0.6)

func _on_project_inited() -> void:
	if _is_html5 or _is_web_build:
		LoadingMessage.new()


class LoadingMessage extends Label:

	func _init() -> void:
		set("custom_fonts/font", Global.fonts.medium)
		align = ALIGN_CENTER
		text = "TXT_WEB_PLANETARIUM_LOADING"
		Global.program.universe.add_child(self)
		Global.connect("gui_refresh_requested", self, "queue_free")
		set_anchors_and_margins_preset(PRESET_CENTER)
