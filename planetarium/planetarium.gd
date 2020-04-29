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
# This extension can run either the standalone Planetarium "app" or web-based
# planetarium. In production HTML5 export, the web version is triggered by
# presence of ivoyager_assets_web and absence of ivoyager_assets. However, the
# web version can also be forced by setting FORCE_WEB_BUILD = true.
#
# For functional HTML5 export, you must set GLES2!

extends Reference

const EXTENSION_NAME := "Planetarium"
const EXTENSION_VERSION := "0.0.5"
const EXTENSION_VERSION_YMD := 20200129

const USE_PLANETARIUM_GUI := true
const FORCE_WEB_BUILD := false # for dev only; production uses assets detection

var _is_web_build := false
var _use_web_assets := false
var _loading_message: Label # used for web build only

func extension_init() -> void:
	ProjectBuilder.connect("project_objects_instantiated", self, "_on_project_objects_instantiated")
	Global.connect("environment_created", self, "_on_environment_created")
	Global.connect("about_to_start_simulator", self, "_on_about_to_start_simulator")
	var has_base_assets := FileUtils.is_valid_dir("res://ivoyager_assets")
	var has_web_assets := FileUtils.is_valid_dir("res://ivoyager_assets_web")
	_is_web_build = FORCE_WEB_BUILD or (!has_base_assets and has_web_assets)
	_use_web_assets = _is_web_build and has_web_assets
	print("is_web_build = ", _is_web_build, "; use_web_assets = ", _use_web_assets)
	if USE_PLANETARIUM_GUI:
		ProjectBuilder.gui_controls._ProjectGUI_ = PlanetariumGUI
	ProjectBuilder.gui_controls.erase("_LoadDialog_")
	ProjectBuilder.gui_controls.erase("_SaveDialog_")
	ProjectBuilder.program_references.erase("_SaverLoader_")
	Global.project_name = "I, Voyager Planetarium"
	Global.enable_save_load = false
	Global.allow_real_world_time = true
	Global.allow_time_reversal = true
	Global.skip_splash_screen = true
	Global.disable_exit = true
	Global.enable_wiki = true
	ProjectBuilder.gui_controls.erase("_SplashScreen_")
	if _is_web_build:
		ProjectBuilder.gui_controls.erase("_MainProgBar_")
		Global.use_threads = false
		Global.disable_quit = true
		Global.vertecies_per_orbit = 200
	if _use_web_assets:
		Global.asset_replacement_dir = "ivoyager_assets_web"
		Global.asset_paths.starfield = "res://ivoyager_assets/starfields/starmap_8k.jpg"

func _on_project_objects_instantiated() -> void:
	var main_menu: MainMenu = Global.program.MainMenu
	main_menu.planetarium_mode = true
	var help_text := "Planetarium " + EXTENSION_VERSION + "\n" + tr("TXT_PLANETARIUM_HELP")
	main_menu.make_button("BUTTON_HELP", 1000, true, true, Global, "emit_signal",
			["rich_text_popup_requested", "LABEL_HELP", help_text])
	var timekeeper: Timekeeper = Global.program.Timekeeper
	timekeeper.start_real_world_time = true
	var tree_manager: TreeManager = Global.program.TreeManager
	tree_manager.show_labels = true
	tree_manager.show_orbits = true
	var qty_strings: QtyStrings = Global.program.QtyStrings
	qty_strings.exp_str = " x 10^"
	var settings_manager: SettingsManager = Global.program.SettingsManager
	var default_settings := settings_manager.defaults
	# planetarium adds
	default_settings.lock_navigator = true
	default_settings.lock_time = true
	default_settings.lock_selection = true
	default_settings.lock_range = true
	default_settings.lock_info = true
	default_settings.lock_controls = false
	# changes
	default_settings.gui_size = SettingsManager.GUISizes.GUI_LARGE
	if _is_web_build:
		default_settings.planet_orbit_color =  Color(0.6,0.6,0.2)
		default_settings.dwarf_planet_orbit_color = Color(0.1,0.9,0.2)
		default_settings.moon_orbit_color = Color(0.3,0.3,0.9)
		default_settings.minor_moon_orbit_color = Color(0.6,0.2,0.6)
		# loading message for web deployment
		_loading_message = Label.new()
		_loading_message.align = Label.ALIGN_CENTER
		_loading_message.text = "TXT_WEB_PLANETARIUM_LOADING"
		Global.program.universe.add_child(_loading_message)
		_loading_message.set_anchors_and_margins_preset(Control.PRESET_CENTER)

func _on_environment_created(environment: Environment, _is_world_env: bool) -> void:
	if _is_web_build:
		# GLES2 lighting is different than GLES3!
		environment.background_energy = 1.0
		environment.ambient_light_energy = 0.1

func _on_about_to_start_simulator(_is_loaded_game: bool) -> void:
	if _is_web_build:
		_loading_message.queue_free()
