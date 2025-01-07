# nav_panel.gd
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
class_name NavPanel
extends PanelContainer


func _ready() -> void:
	# widgets
	($"%AsteroidsHScroll" as IVBodyHScroll).add_bodies_from_table(&"asteroids")
	($"%SpacecraftHScroll" as IVBodyHScroll).add_bodies_from_table(&"spacecrafts")
	
	var mod: IVControlDraggable = $ControlMod
	mod.init_min_size(IVEnums.GUISize.GUI_SMALL, Vector2(435.0, 278.0))
	mod.init_min_size(IVEnums.GUISize.GUI_MEDIUM, Vector2(575.0, 336.0))
	mod.init_min_size(IVEnums.GUISize.GUI_LARGE, Vector2(712.0, 400.0))
	mod.max_default_screen_proportions = Vector2(0.55, 0.45)
