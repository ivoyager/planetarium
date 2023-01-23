# huds_panel.gd
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
extends PanelContainer


func _ready():
	$ControlDraggable.default_sizes = [
		# shrink to content
		Vector2.ZERO, # GUI_SMALL
		Vector2.ZERO, # GUI_MEDIUM
		Vector2.ZERO, # GUI_LARGE
	]
	$ControlDraggable.max_default_screen_proportions = Vector2(0.55, 0.45)
	IVGlobal.connect("update_gui_requested", self, "_resize")
	IVGlobal.connect("setting_changed", self, "_settings_listener")


func _resize() -> void:
	pass
#	rect_size = Vector2.ZERO


func _settings_listener(setting: String, _value) -> void:
	if setting == "gui_size":
		_resize()
