# info_panel.gd
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
extends PanelContainer

# Dynamically resizes to not grow bigger than data and not cover other panels.

const MIN_DATA_SIZE := 80.0
const UNDER_DATA_MARGIN := 20.0

var _world_targeting: Array = IVGlobal.world_targeting
var _other_panels := [] # resize to not cover these
var _suppress_resize := true

onready var _selection_data: VBoxContainer = find_node("SelectionData")
onready var _data_scroll: ScrollContainer = find_node("DataScroll")


func _ready():
	IVGlobal.connect("simulator_started", self, "_on_simulator_started")
	$ControlDraggable.default_sizes = [
		Vector2(315.0, 0.0), #, 870.0), # GUI_SMALL
		Vector2(375.0, 0.0), #, 1150.0), # GUI_MEDIUM
		Vector2(455.0, 0.0), #, 1424.0), # GUI_LARGE
	]
	# limit panel bottom for other gui
	for child in get_parent().get_children():
		var control := child as Control
		if !control or control == self:
			continue
		_other_panels.append(control)
		control.connect("item_rect_changed", self, "_resize_vertical")
	connect("item_rect_changed", self, "_resize_vertical")
	_selection_data.connect("resized", self, "_resize_vertical")
	get_viewport().connect("size_changed", self, "_resize_vertical")


func _on_simulator_started() -> void:
	_suppress_resize = false
	_resize_vertical()


func _resize_vertical() -> void:
	if _suppress_resize:
		return
	_suppress_resize = true
	var data_size := _selection_data.rect_size.y
	var data_top := _data_scroll.get_global_rect().position.y
	var above_data_size := data_top - rect_position.y
	var rect := get_rect()
	var bottom_limit: float = _world_targeting[1] # Viewport height
	for control in _other_panels:
		var other_rect: Rect2 = control.get_rect()
		if rect.end.x < other_rect.position.x:
			continue
		if rect.position.x > other_rect.end.x:
			continue
		var other_top: float = other_rect.position.y
		if bottom_limit > other_top:
			bottom_limit = other_top
	if data_size + data_top > bottom_limit: # grow to external limits, unless too small
		var min_size := bottom_limit - rect_position.y
		if min_size < above_data_size + MIN_DATA_SIZE:
			min_size = above_data_size + MIN_DATA_SIZE
		rect_min_size.y = min_size
	else: # shrink to content
		rect_min_size.y = data_size + above_data_size + UNDER_DATA_MARGIN
	rect_size.y = rect_min_size.y
	_suppress_resize = false
