# pltm_nav_panel.gd
# This file is part of I, Voyager (https://ivoyager.dev)
# *****************************************************************************
# Copyright (c) 2017-2021 Charlie Whitfield
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

func _ready():
	# widget mods
	var date_time_label := find_node("DateTimeLabel")
	date_time_label.clock_hms_format = "  %02d:%02d:%02d UT"
	date_time_label.clock_hm_format = "  %02d:%02d UT"
	var track_orbit_ground_ckbxs := find_node("TrackOrbitGroudCkbxs")
	track_orbit_ground_ckbxs.remove_track_label()
	var selection_data = find_node("SelectionData")
	selection_data.enable_wiki_links = true
	$ContainerDraggable.default_sizes = [
		Vector2(315.0, 870.0), # GUI_SMALL
		Vector2(375.0, 1150.0), # GUI_MEDIUM
		Vector2(455.0, 1424.0), # GUI_LARGE
	]
	$ContainerDraggable.max_default_screen_proportions = Vector2(0.33, 0.55)
