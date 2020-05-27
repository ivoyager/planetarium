# pl_options.gd
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

var _points_manager: PointsManager = Global.program.PointsManager
onready var _tree_manager: TreeManager = Global.program.TreeManager
onready var _orbits_checkbox: CheckBox = $Orbits/CheckBox
onready var _names_checkbox: CheckBox = $NamesSymbols/CheckBox1
onready var _symbols_checkbox: CheckBox = $NamesSymbols/CheckBox2
onready var _fullscreen_button: Button = $FullScreen/Button

onready var _asteroid_checkboxes := {
	all_asteroids = $AllAsteroids/CheckBox,
	NE = $NearEarth/CheckBox,
	MC = $MarsCrossers/CheckBox,
	MB = $MainBelt/CheckBox,
	JT4 = $JupiterTrojans/CheckBoxL4,
	JT5 = $JupiterTrojans/CheckBoxL5,
	CE = $Centaurs/CheckBox,
	TN = $TransNeptunian/CheckBox
}

onready var _asteroid_labels := {
	LABEL_ALL_ASTEROIDS = $AllAsteroids/RTLabel,
	LABEL_NEAR_EARTH = $NearEarth/RTLabel,
	LABEL_MARS_CROSSERS = $MarsCrossers/RTLabel,
	LABEL_MAIN_BELT = $MainBelt/RTLabel,
	LABEL_JUPITER_TROJANS = $JupiterTrojans/RTLabel,
	LABEL_CENTAURS = $Centaurs/RTLabel,
	LABEL_TRANS_NEPTUNIAN = $TransNeptunian/RTLabel
}

func _ready() -> void:
	Global.connect("about_to_start_simulator", self, "_on_about_to_start_simulator", [], CONNECT_ONESHOT)
	Global.connect("gui_refresh_requested", self, "_on_screen_resized")
	get_tree().connect("screen_resized", self, "_on_screen_resized")
	_orbits_checkbox.connect("pressed", self, "_show_hide_orbits")
	_names_checkbox.connect("pressed", self, "_show_hide_names")
	_symbols_checkbox.connect("pressed", self, "_show_hide_symbols")
	_fullscreen_button.connect("pressed", self, "_change_fullscreen")
	_tree_manager.connect("show_orbits_changed", self, "_update_show_orbits")
	_tree_manager.connect("show_names_changed", self, "_update_show_names")
	_tree_manager.connect("show_symbols_changed", self, "_update_show_symbols")
	for key in _asteroid_checkboxes:
		_asteroid_checkboxes[key].connect("pressed", self, "_select_asteroids", [key])
	_points_manager.connect("show_points_changed", self, "_update_asteroids_selected")
	for key in _asteroid_labels:
		var rt_label: RichTextLabel = _asteroid_labels[key]
		rt_label.bbcode_text = "[url]" + tr(key) + "[/url]"
		rt_label.connect("meta_clicked", self, "_on_meta_clicked", [key])
	hide()

func _on_about_to_start_simulator(_is_new_game: bool) -> void:
	_resize_and_reposition()
	show()

func _on_screen_resized() -> void:
	yield(get_tree(), "idle_frame")
	_fullscreen_button.text = "BUTTON_OFF" if OS.window_fullscreen else "BUTTON_ON"

func _change_fullscreen() -> void:
	OS.window_fullscreen = !OS.window_fullscreen

func _show_hide_orbits() -> void:
	_tree_manager.set_show_orbits(_orbits_checkbox.pressed)

func _show_hide_names() -> void:
	_tree_manager.set_show_names(_names_checkbox.pressed)

func _show_hide_symbols() -> void:
	_tree_manager.set_show_symbols(_symbols_checkbox.pressed)

func _update_show_orbits(is_show: bool) -> void:
	_orbits_checkbox.pressed = is_show

func _update_show_names(is_show: bool) -> void:
	_names_checkbox.pressed = is_show

func _update_show_symbols(is_show: bool) -> void:
	_symbols_checkbox.pressed = is_show

func _select_asteroids(group_or_category: String) -> void:
	var pressed: bool = _asteroid_checkboxes[group_or_category].pressed
	_points_manager.show_points(group_or_category, pressed)

func _update_asteroids_selected(group_or_category: String, is_show: bool) -> void:
	_asteroid_checkboxes[group_or_category].pressed = is_show
	if group_or_category == "all_asteroids":
		return
	if !is_show:
		_asteroid_checkboxes.all_asteroids.pressed = false
		return
	for key in _asteroid_checkboxes:
		if key != "all_asteroids" and !_asteroid_checkboxes[key].pressed:
			_asteroid_checkboxes.all_asteroids.pressed = false
			return
	_asteroid_checkboxes.all_asteroids.pressed = true

func _on_meta_clicked(_meta: String, key: String) -> void:
	var wiki_page: String
	match key:
		"LABEL_ALL_ASTEROIDS":
			wiki_page = "Asteroid"
		"LABEL_NEAR_EARTH":
			wiki_page = "Near-Earth_object"
		"LABEL_MARS_CROSSERS":
			wiki_page = "List_of_Mars-crossing_minor_planets"
		"LABEL_MAIN_BELT":
			wiki_page = "Asteroid_belt"
		"LABEL_JUPITER_TROJANS":
			wiki_page = "Jupiter_trojan"
		"LABEL_CENTAURS":
			wiki_page = "Centaur_(small_Solar_System_body)"
		"LABEL_TRANS_NEPTUNIAN":
			wiki_page = "Trans-Neptunian_object"
	if wiki_page:
		OS.shell_open("https://en.wikipedia.org/wiki/" + wiki_page)

func _resize_and_reposition() -> void:
	set_anchors_and_margins_preset(PRESET_BOTTOM_RIGHT, PRESET_MODE_MINSIZE)
	rect_position.x -= 15
	rect_position.y -= 15
