# boot.gd
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
extends ColorRect

# Self-freeing boot screen (hides messy node construction).

func _ready() -> void:
	IVGlobal.connect("translations_imported", self, "_set_labels")
	IVGlobal.connect("simulator_started", self, "queue_free", [], CONNECT_ONESHOT)


func _set_labels() -> void:
	var font_data: DynamicFontData = IVGlobal.assets.primary_font_data
	var font := DynamicFont.new()
	font.font_data = font_data
	font.size = 26
	var boot_label: Label = find_node("BootLabel")
	boot_label.set("custom_fonts/font", font)
