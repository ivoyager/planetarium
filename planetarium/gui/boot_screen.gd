# boot_screen.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright 2017-2025 Charlie Whitfield
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

var primary_font_path := "res://addons/ivoyager_assets/fonts/Roboto-NotoSansSymbols-merged.ttf"


func _ready() -> void:
	IVGlobal.simulator_started.connect(_free, CONNECT_ONE_SHOT)
	@warning_ignore("unsafe_method_access")
	var font: FontFile = load(primary_font_path)
	font.fixed_size = 26
	var boot_label: Label = find_child(&"BootLabel")
	boot_label.set(&"theme_override_fonts/font", font)

func _free() -> void:
	IVGlobal.program.erase(&"BootScreen")
	queue_free()
