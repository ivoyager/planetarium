# full_screen_manager.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright 2017-2022 Charlie Whitfield
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
# Note: "ObjectDB leaked at exit" errors occur on quit if this is a Reference
# as of Godot 3.2.3; these result from passing self to MainMenuManager. This
# shouldn't happen, but changing to Node and adding via
# ProjectBuider.prog_nodes fixes the problem for now.

extends Node # See Note
class_name FullScreenManager

var _tree: SceneTree = Global.get_tree()
var _main_menu_manager: MainMenuManager = Global.program.MainMenuManager
var _is_screen_size_testing := false
var _is_fullscreen := false

func _project_init() -> void:
	_main_menu_manager.make_button("BUTTON_FULL_SCREEN", 1001, false, true, self,
			"_change_fullscreen")
	_main_menu_manager.make_button("BUTTON_MINIMIZE", 1002, false, true, self,
			"_change_fullscreen", [], _main_menu_manager.HIDDEN)
	Global.connect("update_gui_needed", self, "_update_buttons")
	_tree.connect("screen_resized", self, "_on_screen_resized")

func _change_fullscreen() -> void:
	OS.window_fullscreen = !OS.window_fullscreen

func _update_buttons() -> void:
	if _is_fullscreen == OS.window_fullscreen:
		return
	_is_fullscreen = !_is_fullscreen
	if _is_fullscreen:
		_main_menu_manager.change_button_state("BUTTON_FULL_SCREEN", _main_menu_manager.HIDDEN)
		_main_menu_manager.change_button_state("BUTTON_MINIMIZE", _main_menu_manager.ACTIVE)
	else:
		_main_menu_manager.change_button_state("BUTTON_FULL_SCREEN", _main_menu_manager.ACTIVE)
		_main_menu_manager.change_button_state("BUTTON_MINIMIZE", _main_menu_manager.HIDDEN)

func _on_screen_resized() -> void:
	# In electron_app this takes a while to give correct result. Possibly other
	# browsers have this problem. So we keep checking for a while.
	if _is_screen_size_testing:
		return
	_is_screen_size_testing = true
	_update_buttons()
	var i := 0
	while i < 20:
		yield(_tree, "idle_frame")
		_update_buttons()
		i += 1
	_is_screen_size_testing = false
