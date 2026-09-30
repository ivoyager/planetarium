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
## warm-up while it runs.

const WARMUP_TEXT := "Compiling shaders (%d of %d)..."

@onready var _label: Label = $BootLabel


func _ready() -> void:
	IVStateManager.core_initialized.connect(_on_core_initialized)
	IVStateManager.state_changed.connect(_on_state_changed)


func _on_core_initialized() -> void:
	var warmup: IVShaderWarmup = IVGlobal.program.get(&"ShaderWarmup")
	if warmup:
		warmup.progress_changed.connect(_on_warmup_progress)


func _on_state_changed() -> void:
	if !IVStateManager.show_splash_screen:
		queue_free()


func _on_warmup_progress(index: int, count: int, _shader_name: StringName) -> void:
	_label.text = WARMUP_TEXT % [index + 1, count]
