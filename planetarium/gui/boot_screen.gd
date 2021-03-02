# boot_screen.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright (c) 2017-2021 Charlie Whitfield
# I, Voyager is a registered trademark of Charlie Whitfield
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
# Self-freeing boot screen.

extends ColorRect

func _ready() -> void:
	Global.connect("translations_imported", self, "_set_labels")
	Global.connect("simulator_started", self, "queue_free", [], CONNECT_ONESHOT)

func _set_labels() -> void:
	var font_data: DynamicFontData = Global.assets.primary_font_data
	var font := DynamicFont.new()
	font.font_data = font_data
	font.size = 26
	if Global.is_html5:
		var load_label: Label = $SideVBox/LoadLabel
		load_label.set("custom_fonts/font", font)
		load_label.text = "TXT_HTML5_LOADING"
	var pbd_label: Label = $SideVBox/PBDLabel
	pbd_label.set("custom_fonts/font", font)
	pbd_label.set("custom_colors/font_color", Color.lightskyblue)
#	pbd_label.set("custom_colors/font_color", Color(0.740906, 0.828778, 0.953125))
	pbd_label.text = "TXT_PBD_SHORT"
