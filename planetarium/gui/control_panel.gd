# control_panel.gd
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
class_name ControlPanel
extends PanelContainer


const ViewFlags := IVView.ViewFlags

var reserved_view_names: Array[StringName] = [
	&"BUTTON_ZOOM",
	&"BUTTON_45_DEG",
	&"BUTTON_TOP",
	&"BUTTON_HOME",
	&"BUTTON_CISLUNAR",
	&"BUTTON_SYSTEM",
	&"BUTTON_ASTEROIDS",
]


func _ready() -> void:
	var mod: IVControlDraggable = $ControlMod
	mod.init_min_size(IVGlobal.GUISize.GUI_SMALL, Vector2(435.0, 0.0))
	mod.init_min_size(IVGlobal.GUISize.GUI_MEDIUM, Vector2(575.0, 0.0))
	mod.init_min_size(IVGlobal.GUISize.GUI_LARGE, Vector2(712.0, 0.0))
	mod.max_default_screen_proportions = Vector2(0.55, 0.45)
	
	# widget mods

	
	var view_save_button: IVViewSaveButton = $"%ViewSaveButton"
	var view_save_flow: IVViewSaveFlow = $"%ViewSaveFlow"
	view_save_flow.init(view_save_button, &"LABEL_VIEW1", &"PL", true,
			ViewFlags.VIEWFLAGS_ALL, ViewFlags.VIEWFLAGS_ALL_CAMERA, reserved_view_names)
	view_save_flow.resized.connect(_reset_size)


func _reset_size() -> void:
	size = Vector2.ZERO
