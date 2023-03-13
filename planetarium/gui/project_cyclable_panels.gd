# project_cyclable_panels.gd
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
class_name IVProjectCyclablePanels
extends Node

# FIXME: Accessiblity is all messed up. Needs overhaul.


# Add to top level GUI parent if you want user to be able to cycle through
# child PanelContainers. Cycled PanelContainer will become visible (if hidden)
# and a focusable control will be grabbed (if any).
#
# You will need to define initial hotkeys. In your extension file, add code:
#
# func _on_project_objects_instantiated() -> void:
#	var hotkeys_popup: IVHotkeysPopup = IVGlobal.program.HotkeysPopup
#	hotkeys_popup.add_item("cycle_next_panel", "LABEL_CYCLE_NEXT_PANEL", "LABEL_GUI")
#	hotkeys_popup.add_item("cycle_prev_panel", "LABEL_CYCLE_PREV_PANEL", "LABEL_GUI")
#
# To select which control will have focus when cycled, a PanelContainer can
# have member "first_focus_control" with a focusable control; otherwise it will
# be the first focusable control found.
#
# This GUI mod is used in the Planetarium.

const FOCUS_NONE := Control.FOCUS_NONE

var _last_panel_container: PanelContainer
var _last_panel_container_was_hidden: bool
var _child_idx := -1

onready var _tree: SceneTree = get_tree()
onready var _parent: Control = get_parent()


func _unhandled_key_input(event):
	if event.is_action_pressed("cycle_next_panel"):
		_cycle(1)
	elif event.is_action_pressed("cycle_prev_panel"):
		_cycle(-1)
	else:
		return # input NOT handled!
	_tree.set_input_as_handled()


func _cycle(incr: int) -> void:
	if _last_panel_container and _last_panel_container_was_hidden:
		_last_panel_container.hide()
	var panel_container := _get_panel_container(incr)
	if !panel_container:
		return
	_last_panel_container = panel_container
	_last_panel_container_was_hidden = !panel_container.visible
	panel_container.show()
	if "first_focus_control" in panel_container:
		var focus_control: Control = panel_container.first_focus_control
		if focus_control.focus_mode != FOCUS_NONE:
			focus_control.grab_focus()
			return
	_grab_any_focus_recursive(panel_container)


func _get_panel_container(incr: int) -> PanelContainer:
	var child_count := _parent.get_child_count()
	var loop_counter := 0
	while loop_counter < child_count:
		_child_idx += incr
		if _child_idx < 0:
			_child_idx = child_count - 1
		elif _child_idx >= child_count:
			_child_idx = 0
		var panel_container := _parent.get_child(_child_idx) as PanelContainer
		if panel_container:
			return panel_container
		loop_counter += 1
	return null


func _grab_any_focus_recursive(control: Control) -> bool:
	if control.focus_mode != FOCUS_NONE and control.is_visible_in_tree():
		control.grab_focus()
		return true
	for child in control.get_children():
		if child is Control:
			if _grab_any_focus_recursive(child):
				return true
	return false
