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
# 
# TODO: A lot of new work and GUI changes in ivoyager_web is appropriate for
# the Planetarium. The base GUI is kind of "gamey".


extends Reference

const EXTENSION_NAME := "Planetarium"
const EXTENSION_VERSION := "0.0.2+ dev"
const EXTENSION_VERSION_YMD := 20191109

const FORCE_WEB_BUILD := false # for development; leave false for production
var is_web_build := false
var use_web_assets := false

func extension_init():
	var has_base_assets := FileHelper.is_valid_dir("res://ivoyager_assets")
	var has_web_assets := FileHelper.is_valid_dir("res://ivoyager_assets_web")
	is_web_build = FORCE_WEB_BUILD or (!has_base_assets and has_web_assets)
	use_web_assets = is_web_build and has_web_assets
	print("is_web_build=", is_web_build, "; use_web_assets=", use_web_assets)
	
	ProjectBuilder.connect("project_objects_instantiated", self, "_on_project_objects_instantiated")
	Global.connect("gui_entered_tree", self, "_on_gui_entered_tree")
	Global.project_name = "I, Voyager Planetarium"
	Global.enable_save_load = false
	Global.allow_time_reversal = true

func _on_project_objects_instantiated() -> void:
	pass

func _on_gui_entered_tree(_gui_panel: Control) -> void:
	pass
