# menu_panel.gd
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
class_name MenuPanel
extends PanelContainer


func _ready():
	var credits = find_node("Credits")
	credits.set_hyperlink("Credits", "https://github.com/ivoyager/ivoyager/blob/master/CREDITS.md")
	var feedback = find_node("Feedback")
	feedback.set_hyperlink("Feedback", "https://www.ivoyager.dev/forum/")
	var support_us = find_node("SupportUs")
	support_us.set_hyperlink("Support Us!", "https://github.com/sponsors/ivoyager")
	
	$ControlMod.init_min_size(IVEnums.GUISize.GUI_SMALL, Vector2(75.0, 0.0))
	$ControlMod.init_min_size(IVEnums.GUISize.GUI_MEDIUM, Vector2(100.0, 0.0))
	$ControlMod.init_min_size(IVEnums.GUISize.GUI_LARGE, Vector2(125.0, 0.0))

