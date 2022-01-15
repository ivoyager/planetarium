# menu_panel.gd
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


func _ready():
	var version_label = find_node("VersionLabel")
	version_label.set_version_label("Planetarium", false, true)
	var feedback = find_node("FeedbackLinkLabel")
	feedback.set_hyperlink("Feedback", "https://www.ivoyager.dev/forum/")
	var support_us = find_node("SupportUsLinkLabel")
	support_us.set_hyperlink("Support Us!", "https://github.com/sponsors/charliewhitfield")
	
	$ControlDraggable.default_sizes = [
		# Zeros allow panel to shrink to content, but we need some width here
		# so our "Support Us!" RichTextLabel doesn't wrap.
		Vector2(75.0, 0.0), # GUI_SMALL
		Vector2(100.0, 0.0), # GUI_MEDIUM
		Vector2(125.0, 0.0), # GUI_LARGE
	]
