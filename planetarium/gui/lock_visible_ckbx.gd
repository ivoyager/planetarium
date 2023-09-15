# lock_visible_ckbx.gd
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
class_name LockVisibleCkbx
extends CheckBox

# Owning PanelContainer can be locked visible (toggle on) or visible on mouse-
# over only (toggle off).
# 
# Call set_ckbx_hidden() to hide the checkbox and make panel always visible on
# mouse-over only.
#
# Target control will be the first PanelContainer in this widget's ancestor
# tree unless set otherwise by explicit call to set_panel_container().
#
# This widget is used in Planetarium.

var detection_margins := Vector2(50.0, 50.0)

var _detection_rect := Rect2()
var _is_running := false
var _is_mouse_button_pressed := false
var _is_panel_visible := true

var _panel_container: PanelContainer

@onready var _gui_toggler: GUIToggler = IVGlobal.program[&"GUIToggler"]


func _ready():
	IVGlobal.run_state_changed.connect(_on_run_state_changed)
	IVGlobal.setting_changed.connect(_settings_listener)
	_gui_toggler.all_gui_toggled.connect(set_pressed)
	_set_ancestor_panel_container()
	if _panel_container:
		_panel_container.item_rect_changed.connect(_adjust_detection_rect)
	toggled.connect(_on_toggled)
	set_process_input(false)


func _input(event: InputEvent) -> void:
	# We process input only when in mouse-over mode
	if !_is_running:
		return
	var mouse_event := event as InputEventMouse
	if !mouse_event:
		return
	var mouse_button_event := mouse_event as InputEventMouseButton
	if mouse_button_event:
		_is_mouse_button_pressed = mouse_button_event.pressed # don't show/hide GUIs during mouse drag
		return
	if _is_mouse_button_pressed:
		return # don't show/hide during mouse drag!
	var new_visible := _detection_rect.has_point(mouse_event.position)
	if _is_panel_visible != new_visible:
		_is_panel_visible = new_visible
		_panel_container.visible = new_visible


func set_ckbx_hidden():
	hide()
	set_process_input(true)


func set_panel_container(panel_container: PanelContainer):
	if _panel_container:
		_panel_container.item_rect_changed.disconnect(_adjust_detection_rect)
	_panel_container = panel_container
	_panel_container.item_rect_changed.connect(_adjust_detection_rect)


func _on_run_state_changed(is_running: bool) -> void:
	_is_running = is_running


func _set_ancestor_panel_container() -> void:
	var parent: Node = get_parent()
	var panel_container := parent as PanelContainer
	while !panel_container:
		parent = parent.get_parent() as Control
		if !parent:
			return
		panel_container = parent as PanelContainer
	_panel_container = panel_container


func _adjust_detection_rect() -> void:
	_detection_rect.position = _panel_container.position - detection_margins
	_detection_rect.size = _panel_container.size + 2.0 * detection_margins


func _on_toggled(toggle_pressed: bool) -> void:
	if toggle_pressed:
		set_process_input(false)
		_panel_container.show()
		_gui_toggler.register_visibility(self, true)
	else:
		set_process_input(true)
		_panel_container.hide()
		_gui_toggler.register_visibility(self, false)


func _temp_show_for_resize() -> void:
	if _panel_container.visible:
		return
	# Container mods need up to 2 frames to resize
	_panel_container.show()
	await get_tree().process_frame
	await get_tree().process_frame
	_panel_container.hide()


func _settings_listener(setting: StringName, _value: Variant) -> void:
	if setting == &"gui_size":
		_temp_show_for_resize()

