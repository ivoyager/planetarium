# menu_panel.gd
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
class_name MenuPanel
extends PanelContainer


func _ready() -> void:
	var homepage: IVLinkLabel = %HomePage
	homepage.set_hyperlink("I, Voyager", "https://ivoyager.dev")
	var credits: IVLinkLabel = %Credits
	credits.set_hyperlink("Credits", "https://github.com/ivoyager/ivoyager/blob/master/CREDITS.md")
	var feedback: IVLinkLabel = %Feedback
	feedback.set_hyperlink("Feedback", "https://github.com/orgs/ivoyager/discussions")
	var support_us: IVLinkLabel = %SupportUs
	support_us.set_hyperlink("Support Us!", "https://github.com/sponsors/ivoyager")
	
	var mod: IVControlDraggable = $ControlMod
	mod.init_min_size(IVGlobal.GUISize.GUI_SMALL, Vector2(75.0, 0.0))
	mod.init_min_size(IVGlobal.GUISize.GUI_MEDIUM, Vector2(100.0, 0.0))
	mod.init_min_size(IVGlobal.GUISize.GUI_LARGE, Vector2(125.0, 0.0))
	
	prints('OS.has_feature("web")', OS.has_feature("web"))
	
	if OS.has_feature("web"):
		%QuitButton.queue_free()
