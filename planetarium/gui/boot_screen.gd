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
	IVStateManager.about_to_build_system_tree.connect(_on_about_to_build_system_tree)


func _on_about_to_build_system_tree(_is_new_game: bool) -> void:
	# Program nodes exist by now. With a shader warm-up registered the screen
	# stays up until it finishes, which is after the simulator starts.
	var warmup: IVShaderWarmup = IVGlobal.program.get(&"ShaderWarmup")
	if warmup:
		warmup.progress_changed.connect(_on_warmup_progress)
		warmup.finished.connect(queue_free)
	else:
		IVStateManager.simulator_started.connect(queue_free)


func _on_warmup_progress(index: int, count: int, _shader_name: StringName) -> void:
	_label.text = WARMUP_TEXT % [index + 1, count]
