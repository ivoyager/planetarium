# planetarium_gui.gd
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
# Constructor and parent for Planetarium-style GUIs.

extends Control
class_name PlanetariumGUI
const SCENE := "res://planetarium/gui_top/planetarium_gui.tscn"

const MOUSE_ON_CONTROL_MARGIN := 15.0
const INFO_NAV_GAP := 20.0
const MENU_OPTIONS_GAP := 10.0
const OPTIONS_MARGIN := 10.0

var selection_manager: SelectionManager

onready var _SelectionManager_: Script = Global.script_classes._SelectionManager_
onready var _info: Control = $PlInfo
onready var _navigator: Control = $PlNavigator
onready var _options: Control = $PlOptions
var _main_menu: Control

var _is_mouse_button_pressed := false
var _homepage_link := RichTextLabel.new()
var _supportus_link := RichTextLabel.new()
var _is_running := false

func project_init() -> void:
	Global.connect("project_builder_finished", self, "_on_project_builder_finished",
			[], CONNECT_ONESHOT)
	Global.connect("system_tree_built_or_loaded", self, "_on_system_tree_built_or_loaded",
			[], CONNECT_ONESHOT)
	Global.connect("run_state_changed", self, "_on_run_state_changed")

func _ready() -> void:
	Global.connect("gui_refresh_requested", self, "_reset_controls")
	get_tree().connect("screen_resized", self, "_reset_controls")
	_navigator.connect("visibility_changed", self, "_reset_info_control")

func _on_project_builder_finished() -> void:
	theme = Global.themes.main
	_main_menu = Global.program.MainMenu
	_main_menu.connect("visibility_changed", self, "_reset_options_control")
	_add_main_menu_links()
	_reparent_main_menu()

func _add_main_menu_links() -> void:
	var spacer := Control.new()
	spacer.rect_min_size = Vector2(120.0, 10.0)
	_main_menu.add_child(spacer)
	_homepage_link.bbcode_enabled = true
	_homepage_link.bbcode_text = "[center][url]I, Voyager[/url][/center]"
	_homepage_link.meta_underlined = true
	_homepage_link.scroll_active = false
	_homepage_link.rect_min_size = Vector2(120.0, 30.0)
	_homepage_link.connect("meta_clicked", self, "_on_homepage_clicked")
	_main_menu.add_child(_homepage_link)
	_supportus_link.bbcode_enabled = true
	_supportus_link.bbcode_text = "[center][url]Support Us![/url][/center]"
	_supportus_link.meta_underlined = true
	_supportus_link.scroll_active = false
	_supportus_link.rect_min_size = Vector2(120.0, 30.0)
	_supportus_link.connect("meta_clicked", self, "_on_supportus_clicked")
	_main_menu.add_child(_supportus_link)
	_main_menu.set_anchors_and_margins_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)

func _reparent_main_menu() -> void:
	# So this node controls its visibility with mouse location
	_main_menu.get_parent().remove_child(_main_menu)
	add_child(_main_menu)

func _on_system_tree_built_or_loaded(_is_new_game: bool) -> void:
	selection_manager = _SelectionManager_.new()
	var registrar: Registrar = Global.program.Registrar
	var start_selection: SelectionItem = registrar.selection_items[Global.start_body_name]
	selection_manager.select(start_selection)

func _reset_controls() -> void:
	_reset_info_control()
	_reset_options_control()

func _reset_info_control() -> void:
	var info_size_y: float
	if _navigator.visible:
		info_size_y = _navigator.rect_position.y - INFO_NAV_GAP
	else:
		info_size_y = get_viewport().size.y - INFO_NAV_GAP
	_info.rect_min_size.y = info_size_y
	_info.rect_size.y = 0.0 # triggers resize

func _reset_options_control() -> void:
	_options.rect_size = Vector2.ZERO # resets
	var lr_corner := get_viewport().size
	var pos_y_limit := _main_menu.rect_position.y + _main_menu.rect_size.y + MENU_OPTIONS_GAP
	var size_y_limit := lr_corner.y - pos_y_limit - OPTIONS_MARGIN
	var size_y: float = _options.get_content_height()
	var pos_y: float
	if size_y > size_y_limit:
		size_y = size_y_limit
		pos_y = pos_y_limit
	else:
		pos_y = lr_corner.y - size_y - OPTIONS_MARGIN
	_options.set_height(size_y)
	var size_x := _options.rect_size.x
	var pos_x := lr_corner.x - size_x - OPTIONS_MARGIN
#	_options.rect_position.x = pos_x
	_options.rect_position = Vector2(pos_x, pos_y)

func _on_run_state_changed(is_running: bool) -> void:
	_is_running = is_running

func _input(event: InputEvent) -> void:
	if !_is_running:
		return
	# This node controls visibility of its children by mouse position. By
	# default, the whole child node is shown/hidden. More specific control is
	# possible if child has members mouse_trigger & mouse_visible.
	if event is InputEventMouseMotion:
		if _is_mouse_button_pressed:
			return # we are in the middle of a mouse drag!
		var mouse_pos: Vector2 = event.position
		for child in get_children():
			if not "mouse_trigger" in child:
				var is_visible := _is_mouse_on_control(mouse_pos, child)
				if is_visible == child.visible:
					continue
				child.visible = is_visible
				child.mouse_filter = MOUSE_FILTER_PASS if is_visible else MOUSE_FILTER_IGNORE
			else:
				var mouse_visible: Array = child.mouse_visible
				if !mouse_visible:
					continue
				var mouse_trigger: Control = child.mouse_trigger
				var is_visible := _is_mouse_on_control(mouse_pos, mouse_trigger)
				if is_visible == mouse_visible[0].visible:
					continue
				for gui in mouse_visible:
					gui.visible = is_visible
					gui.mouse_filter = MOUSE_FILTER_PASS if is_visible else MOUSE_FILTER_IGNORE
	elif event is InputEventMouseButton:
		_is_mouse_button_pressed = event.pressed # don't show/hide GUIs during mouse drag

func _is_mouse_on_control(mouse_pos: Vector2, trigger: Control) -> bool:
	var trigger_rect := trigger.get_global_rect().grow(MOUSE_ON_CONTROL_MARGIN)
	return trigger_rect.has_point(mouse_pos)

func _on_homepage_clicked(_meta: String) -> void:
	OS.shell_open("https://ivoyager.dev")

func _on_supportus_clicked(_meta: String) -> void:
	OS.shell_open("https://github.com/sponsors/charliewhitfield")
