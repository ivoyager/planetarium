# pl_help_popup.gd
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

extends PopupPanel
class_name PlHelpPopup
const SCENE := "res://planetarium/gui_top/pl_help_popup.tscn"

var _state_manager: StateManager
onready var _header: Label = $VBox/Header
onready var _rtlabel: RichTextLabel = $VBox/RTLabel
onready var _close_button: Button = $VBox/Close

func project_init() -> void:
	connect("ready", self, "_on_ready")
	connect("popup_hide", self, "_on_popup_hide")
	Global.connect("help_requested", self, "_open")
	_state_manager = Global.program.StateManager
	var main_menu: MainMenu = Global.program.get("MainMenu")
	if main_menu:
		main_menu.make_button("BUTTON_HELP", 1500, true, false, self, "_open")

func _on_ready() -> void:
	theme = Global.themes.main
	set_process_unhandled_key_input(false)
	_rtlabel.bbcode_enabled = true
	_rtlabel.connect("meta_clicked", self, "_on_meta_clicked")
	_close_button.connect("pressed", self, "hide")
	var version: String = load("res://planetarium/planetarium.gd").EXTENSION_VERSION
	_header.text = "Help - v" + version

func _open() -> void:
	set_process_unhandled_key_input(true)
	_state_manager.require_stop(self)
#	var version: String = load("res://planetarium/planetarium.gd").EXTENSION_VERSION
#	var help_text := "Planetarium " + version + "\n" + tr("TXT_PLANETARIUM_HELP")
	_rtlabel.bbcode_text = tr("TXT_PLANETARIUM_HELP")
	popup()
	set_anchors_and_margins_preset(PRESET_CENTER, PRESET_MODE_MINSIZE)

func _on_popup_hide() -> void:
	set_process_unhandled_key_input(false)
	_state_manager.allow_run(self)


func _unhandled_key_input(event: InputEventKey) -> void:
	_on_unhandled_key_input(event)
	
func _on_unhandled_key_input(event: InputEventKey) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().set_input_as_handled()
		hide()

func _on_meta_clicked(meta: String) -> void:
	if meta == tr("LABEL_IVOYAGER_FORUM"):
		OS.shell_open("https://ivoyager.dev/forum/")
	elif meta == "GitHub Sponsors":
		OS.shell_open("https://github.com/sponsors/charliewhitfield")
