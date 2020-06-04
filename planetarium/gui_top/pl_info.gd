# pl_info.gd
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

var col1_width := 170
var col2_width := 170

onready var mouse_trigger: Control = self
onready var mouse_visible := [] # dynamic

onready var time_items := [$TimeBox/DateTime]
onready var selection_items := [$SelectionBox/SelectionWiki]
onready var range_items := [$CoordsBox/RangeLabel]
onready var info_items := [$InfoScroll]
onready var control_items := [$TimeBox/TimeControl, $SelectionBox/ViewButtons]

func _ready():
	Global.connect("about_to_start_simulator", self, "_on_about_to_start_simulator", [],
			CONNECT_ONESHOT)
	Global.connect("setting_changed", self, "_settings_listener")
	var time_control: Control = $TimeBox/TimeControl
	time_control.include_game_speed_label = false
	time_control.include_pause_button = false
	var real_time_button: Button = $TimeBox/TimeControl/Real
	time_control.move_child(real_time_button, 0)
	real_time_button.text = "BUTTON_NOW"
	var view_buttons: Control = $SelectionBox/ViewButtons
	view_buttons.use_small_txt = true
	var selection_data: Control = $InfoScroll/SelectionData
	selection_data.enable_wiki_links = true
	selection_data.labels_width = col1_width
	selection_data.values_width = col2_width
	var settings: Dictionary = Global.settings
	_change_mouse_vis_control(settings.lock_time, time_items)
	_change_mouse_vis_control(settings.lock_selection, selection_items)
	_change_mouse_vis_control(settings.lock_range, range_items)
	_change_mouse_vis_control(settings.lock_info, info_items)
	_change_mouse_vis_control(settings.lock_controls, control_items)
	for gui in control_items:
		gui.hide() # these are malformed at this time

func _on_about_to_start_simulator(_is_new_game: bool) -> void:
	# Show everything (whether locked or not) until user moves mouse
	for array in [time_items, selection_items, range_items, info_items, control_items]:
		for gui in array:
			gui.show()

func _change_mouse_vis_control(is_locked: bool, guis: Array) -> void:
	if is_locked:
		for gui in guis:
			gui.show()
			mouse_visible.erase(gui)
	else:
		for gui in guis:
			gui.hide()
			if !mouse_visible.has(gui):
				mouse_visible.append(gui)

func _settings_listener(setting: String, value) -> void:
	match setting:
		"lock_time":
			_change_mouse_vis_control(value, time_items)
		"lock_selection":
			_change_mouse_vis_control(value, selection_items)
		"lock_range":
			_change_mouse_vis_control(value, range_items)
		"lock_info":
			_change_mouse_vis_control(value, info_items)
		"lock_controls":
			_change_mouse_vis_control(value, control_items)
