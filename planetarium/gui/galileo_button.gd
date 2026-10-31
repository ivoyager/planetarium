# galileo_button.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright 2019-2026 Charlie Whitfield
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
class_name GalileoButton
extends IVPanelButton

## The button that shows and hides Galileo's chat panel.
##
## Galileo is experimental. Until the user connects it to a model, the button
## is there to open [member chat_box]'s setup offer, unless the user has
## dismissed the offer for good; dismissing it hides this button and, with
## [member IVPanelButton.close_panel_when_hidden] set, the panel. Connecting
## shows the button and opens the panel, and so does disconnecting, which brings
## the offer back.

@export var chat_box: IVAssistantChatBox


func _ready() -> void:
	super()
	var connections := IVAssistant.connections
	if !connections:
		hide()
		return
	connections.connection_changed.connect(_on_connection_changed)
	chat_box.setup_dismissed.connect(hide)
	if connections.connection:
		return
	visible = IVAssistant.has_setup_wizard() and !connections.is_setup_declined


func _on_connection_changed() -> void:
	show()
	button_pressed = true
