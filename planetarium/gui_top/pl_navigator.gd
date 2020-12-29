# pl_navigator.gd
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

extends VBoxContainer

var system_navigator_min_height_presets := [215.0, 265.0, 320.0]
var left_truncates := [33.0, 42.0, 51.0]

onready var mouse_trigger: Control = self
onready var mouse_visible := [self]

var _settings: Dictionary = Global.settings
onready var _settings_manager: SettingsManager = Global.program.SettingsManager

func _ready() -> void:
	Global.connect("about_to_start_simulator", self, "_on_about_to_start_simulator", [],
			CONNECT_ONESHOT)
	Global.connect("setting_changed", self, "_settings_listener")
	$SystemNavigator.widget_min_height_presets = system_navigator_min_height_presets
	var settings: Dictionary = Global.settings
	_change_mouse_vis_control(settings.lock_navigator)
	hide() # hide until sim start

func _on_about_to_start_simulator(_is_new_game: bool) -> void:
	var gui_size: int = Global.settings.gui_size
	_refit_to_corner(gui_size)
	show() # show until mouse movement (if not locked)

func _refit_to_corner(gui_size: int) -> void:
	set_anchors_and_margins_preset(PRESET_BOTTOM_LEFT, PRESET_MODE_MINSIZE)
	var left_truncate: int = left_truncates[gui_size]
	rect_position.x -= left_truncate

func _change_mouse_vis_control(is_locked: bool) -> void:
	if is_locked:
		show()
		mouse_visible.erase(self)
	else:
		hide()
		if !mouse_visible.has(self):
			mouse_visible.append(self)

func _settings_listener(setting: String, value) -> void:
	match setting:
		"lock_navigator":
			_change_mouse_vis_control(value)
		"gui_size":
			yield(get_tree(), "idle_frame")
			_refit_to_corner(value)
