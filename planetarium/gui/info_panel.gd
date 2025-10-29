# info_panel.gd
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
class_name InfoPanel
extends PanelContainer

# This panel changes its own vertical size in response to SelectionData size
# changes. Note that $ControlModResizable will override this an truncate y
# if there is a PanelContainer below (from panel_under_spacing).

const NONDATA_BASE_SIZE := 95.0

var _settings := IVGlobal.settings
var _gui_size_multipliers := IVCoreSettings.gui_size_multipliers
var _data_height := 0.0
var _suppress_resize := false


@onready var _selection_data: VBoxContainer = %SelectionData



func _ready() -> void:
	_selection_data.resized.connect(_resize)


func _resize() -> void:
	if _suppress_resize:
		return
	if _data_height == _selection_data.size.y:
		return
	_suppress_resize = true
	_data_height = _selection_data.size.y
	var gui_size: int = _settings[&"gui_size"]
	var nondata_height := NONDATA_BASE_SIZE * _gui_size_multipliers[gui_size]
	size.y = _data_height + nondata_height
	_suppress_resize = false
