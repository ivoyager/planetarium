# planetarium_gui.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright 2017-2025 Charlie Whitfield
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
class_name PlanetariumGUI
extends Control
const SCENE := "res://planetarium/gui/planetarium_gui.tscn"

# Scenes instanced by IVCoreInitializer need SCENE constant above.


func _ready() -> void:
	IVGlobal.system_tree_built_or_loaded.connect(_on_system_tree_built_or_loaded)
	IVGlobal.simulator_exited.connect(_on_simulator_exited)
	hide()


func _on_system_tree_built_or_loaded(_is_new_game: bool) -> void:
	show()


func _on_simulator_exited() -> void:
	hide()
