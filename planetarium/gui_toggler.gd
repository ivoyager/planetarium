# gui_toggler.gd
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
class_name GUIToggler
extends Node


signal all_gui_toggled(is_visible)


var hidden_panels := []


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_all_gui"):
		all_gui_toggled.emit(!hidden_panels.is_empty())
		get_viewport().set_input_as_handled()


func register_visibility(panel: Control, is_visible: bool) -> void:
	if is_visible:
		hidden_panels.erase(panel)
	elif !hidden_panels.has(panel):
		hidden_panels.append(panel)

