# info_panel.gd
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
# Dynamically resizes to not grow bigger than data and not cover other panels.

extends PanelContainer

const MIN_DATA_SIZE := 80.0
const UNDER_DATA_MARGIN := 20.0

onready var _selection_data: VBoxContainer = find_node("SelectionData")
onready var _data_scroll: ScrollContainer = find_node("DataScroll")
var _other_panels := [] # resize to not cover these
var _suppress_resize := false

func _ready():
	# widget mods
	var date_time_label := find_node("DateTimeLabel")
	date_time_label.clock_hms_format = "  %02d:%02d:%02d UT"
	date_time_label.clock_hm_format = "  %02d:%02d UT"
	var track_orbit_ground_ckbxs := find_node("TrackOrbitGroudCkbxs")
	track_orbit_ground_ckbxs.remove_track_label()
	$ControlDraggable.default_sizes = [
		Vector2(315.0, 0.0), #, 870.0), # GUI_SMALL
		Vector2(375.0, 0.0), #, 1150.0), # GUI_MEDIUM
		Vector2(455.0, 0.0), #, 1424.0), # GUI_LARGE
	]
	# y-axis resizing
	_other_panels.append(get_parent().find_node("NavPanel"))
	for other_panel in _other_panels:
		other_panel.connect("item_rect_changed", self, "_resize")
	connect("item_rect_changed", self, "_resize")
	Global.connect("simulator_started", self, "_resize")
	_selection_data.connect("resized", self, "_resize")
	get_viewport().connect("size_changed", self, "_resize")

func _resize() -> void:
	if _suppress_resize:
		return
	_suppress_resize = true
	var data_size := _selection_data.rect_size.y
	var data_top := _data_scroll.get_global_rect().position.y
	var above_data_size := data_top - rect_position.y
	var bottom_limit := INF
	var rect := get_rect()
	for other_panel in _other_panels:
		var other_rect: Rect2 = other_panel.get_rect()
		if rect.end.x < other_rect.position.x:
			continue
		if rect.position.x > other_rect.end.x:
			continue
		if bottom_limit > other_rect.position.y:
			bottom_limit = other_rect.position.y
	if bottom_limit == INF:
		bottom_limit = get_viewport_rect().end.y
	if data_size + data_top > bottom_limit: # grow to external limits, unless too small
		var min_size := bottom_limit - rect_position.y
		if min_size < above_data_size + MIN_DATA_SIZE:
			min_size = above_data_size + MIN_DATA_SIZE
		rect_min_size.y = min_size
	else: # shrink to content
		rect_min_size.y = data_size + above_data_size + UNDER_DATA_MARGIN
	rect_size.y = rect_min_size.y
	_suppress_resize = false
