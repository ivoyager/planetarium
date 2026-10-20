# boot_screen.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield
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
class_name BootScreen
extends ColorRect

## Self-freeing boot screen hides messy node construction and reports the shader
## warm-up while it runs. In the web app, notes for the visitor follow the report.

var _report := &"TXT_BUILDING_SOLAR_SYSTEM"
var _report_args: Array[int] = []

@onready var _label: Label = $BootLabel


func _ready() -> void:
	IVStateManager.core_initialized.connect(_on_core_initialized)
	IVStateManager.state_changed.connect(_on_state_changed)
	_update_label()


func _notification(what: int) -> void:
	# The screen is up in the system language before IVLanguageManager sets the user's.
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_update_label()


func _on_core_initialized() -> void:
	var warmup: IVShaderWarmup = IVGlobal.program.get(&"ShaderWarmup")
	if warmup:
		warmup.progress_changed.connect(_on_warmup_progress)


func _on_state_changed() -> void:
	if !IVStateManager.show_splash_screen:
		queue_free()


func _on_warmup_progress(index: int, count: int, _step_name: StringName) -> void:
	_report = &"TXT_COMPILING_SHADERS_CONSTRUCTOR"
	_report_args = [index + 1, count]
	_update_label()


func _update_label() -> void:
	var text := tr(_report) % _report_args if _report_args else tr(_report)
	if OS.has_feature("web"):
		text += tr(&"TXT_WEB_BOOT_NOTE")
	_label.text = text
