# boot_screen.gd
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
class_name BootScreen
extends ColorRect
const SCENE := "res://planetarium/gui/boot_screen.tscn"

# Self-freeing boot screen hides messy node construction.

func _ready() -> void:
	IVGlobal.simulator_started.connect(_free, CONNECT_ONE_SHOT)
	var font_data: FontFile = IVGlobal.assets.primary_font_data
	var font := FontFile.new()
	font.font_data = font_data
	font.fixed_size = 26
	var boot_label: Label = find_child("BootLabel")
	boot_label.set("theme_override_fonts/font", font)

func _free() -> void:
	IVGlobal.program.erase("BootScreen")
	queue_free()

