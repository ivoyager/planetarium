# gui_top.gd
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
class_name GUITop
extends Control
const SCENE := "res://planetarium/gui/gui_top.tscn"

# Scenes instanced by IVProjectBuilder need SCENE constant above.
#
# An IVSelectionManager instance manages our current selection. To find this
# instanace, various GUI widgets search up their ancestor tree for the first
# node that has a "selection_manager" member.

var selection_manager: IVSelectionManager

onready var _SelectionManager_: Script = IVGlobal.script_classes._SelectionManager_


func _project_init() -> void:
	IVGlobal.connect("project_builder_finished", self, "_on_project_builder_finished")
	IVGlobal.connect("system_tree_built_or_loaded", self, "_on_system_tree_built_or_loaded")
	IVGlobal.connect("simulator_exited", self, "_on_simulator_exited")
	hide()


func _ready():
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = Color(1.0, 1.0, 1.0, 0.05) # almost transparent
	for child in get_children():
		var panel_container := child as PanelContainer
		if !panel_container:
			continue
		panel_container.set("custom_styles/panel", style_box)
	var set_date_time: Button = find_node("SetDateTime")
	set_date_time.connect("pressed", $TimeSetPopup, "popup")
	get_parent().add_child(IVSmallBodiesLabel.new())


func _on_project_builder_finished() -> void:
	theme = IVGlobal.themes.main


func _on_system_tree_built_or_loaded(is_new_game: bool) -> void:
	if is_new_game:
		selection_manager = _SelectionManager_.new()
		add_child(selection_manager)
	show()


func _on_simulator_exited() -> void:
	hide()
