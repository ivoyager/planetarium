# planetarium.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# Copyright (c) 2017-2019 Charlie Whitfield
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
const EXTENSION_VERSION := "0.0.2+ dev"
const EXTENSION_VERSION_YMD := 20191109

const USE_PLANETARIUM_GUI := true
const FORCE_WEB_BUILD := false # for dev only; production uses assets detection

var _is_web_build := false
var _use_web_assets := false

func extension_init() -> void:
	ProjectBuilder.connect("project_objects_instantiated", self, "_on_project_objects_instantiated")
	Global.connect("gui_entered_tree", self, "_on_gui_entered_tree")
	var has_base_assets := FileHelper.is_valid_dir("res://ivoyager_assets")
	var has_web_assets := FileHelper.is_valid_dir("res://ivoyager_assets_web")
	_is_web_build = FORCE_WEB_BUILD or (!has_base_assets and has_web_assets)
	_use_web_assets = _is_web_build and has_web_assets
	print("is_web_build = ", _is_web_build, "; use_web_assets = ", _use_web_assets)
	if USE_PLANETARIUM_GUI:
		ProjectBuilder.gui_top_nodes._ProjectGUI_ = PlanetariumGUI
	ProjectBuilder.gui_top_nodes.erase("_LoadDialog_")
	ProjectBuilder.gui_top_nodes.erase("_SaveDialog_")
	ProjectBuilder.program_references.erase("_SaverLoader_")
	Global.project_name = "I, Voyager Planetarium"
	Global.enable_save_load = false
	Global.allow_time_reversal = true
	if _is_web_build:
		_extension_init_web()
	else:
		_extension_init_app()
	if _use_web_assets:
		Global.asset_replacement_dir = "ivoyager_assets_web"

func _extension_init_app() -> void:
	pass

func _extension_init_web() -> void:
	ProjectBuilder.gui_top_nodes.erase("_SplashScreen_")
	ProjectBuilder.gui_top_nodes.erase("_MainMenu_")
	ProjectBuilder.gui_top_nodes.erase("_MainProgBar_")
	Global.use_threads = false
	Global.skip_splash_screen = true
	Global.asteroid_mag_cutoff_override = 14.0
	Global.vertecies_per_orbit = 200

func _on_project_objects_instantiated() -> void:
	var tree_manager: TreeManager = Global.objects.TreeManager
	tree_manager.show_labels = true
	tree_manager.show_orbits = true
	if _is_web_build:
		_on_project_objects_instantiated_web()
	else:
		_on_project_objects_instantiated_app()

func _on_project_objects_instantiated_app() -> void:
	Global.objects.ProjectGUI.hide()

func _on_project_objects_instantiated_web() -> void:
	var input_map_manager: InputMapManager = Global.objects.InputMapManager
	# warning-ignore:unused_variable
	var default_map := input_map_manager.defaults
	var settings_manager: SettingsManager = Global.objects.SettingsManager
	settings_manager.defaults.gui_size = SettingsManager.GUISizes.GUI_LARGE

func _on_gui_entered_tree(_gui_panel: Control) -> void:
	pass
