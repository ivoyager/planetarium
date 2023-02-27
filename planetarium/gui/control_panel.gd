# control_panel.gd
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
class_name ControlPanel
extends PanelContainer

signal time_set_requested()


func _ready():
	$"%SetDateTime".connect("pressed", self, "emit_signal", ["time_set_requested"])
	$ControlDraggable.max_default_screen_proportions = Vector2(0.55, 0.45)
	
	# widget mods
	$"%DateTimeLabel".clock_hms_format = "  %02d:%02d:%02d UT"
	$"%DateTimeLabel".clock_hm_format = "  %02d:%02d UT"
	$ControlDraggable.default_sizes = [
		Vector2(435.0, 0.0), # , 139.0), # GUI_SMALL
		Vector2(575.0, 0.0), # , 168.0), # GUI_MEDIUM
		Vector2(712.0, 0.0), # , 200.0), # GUI_LARGE
	]

