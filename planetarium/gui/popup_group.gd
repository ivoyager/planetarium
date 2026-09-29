# popup_group.gd
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
class_name PopupGroup
extends Node

## Opens its popups one at a time and shows each one's button pressed while it's open.
##
## Does for [IVOptionsPopup] and [IVHotkeysPopup] what a shared [ButtonGroup] does
## for [IVPanelButton] panels, however a popup opens: opening one closes the open
## one as its Cancel button would. If that asks whether to discard changes, the new
## popup opens once they are discarded, or not at all.

## Popups with a [code]toggle()[/code] method, as [IVOptionsPopup] and
## [IVHotkeysPopup] have.
@export var popups: Array[Window] = []
@export var buttons: Array[Button] = [] ## Each popup's button, in the same order.
@export var confirmation_dialog: ConfirmationDialog ## Where a popup asks to discard changes.

var _waiting_popup: Window # opens when the popup asking to discard its changes closes


func _ready() -> void:
	assert(buttons.size() == popups.size(), "PopupGroup needs one button for each popup")
	for i in popups.size():
		var popup := popups[i]
		var button := buttons[i]
		assert(popup.has_method(&"toggle"), "PopupGroup popups need a toggle() method")
		button.toggle_mode = true
		# A click flips the button whether or not the popup then opens or closes.
		button.pressed.connect(_sync_button.bind(popup, button))
		popup.visibility_changed.connect(_on_popup_visibility_changed.bind(popup, button))
	confirmation_dialog.canceled.connect(_on_confirmation_canceled)


func _sync_button(popup: Window, button: Button) -> void:
	button.set_pressed_no_signal(popup.visible)


func _on_popup_visibility_changed(popup: Window, button: Button) -> void:
	button.set_pressed_no_signal(popup.visible)
	if !popup.visible:
		if _waiting_popup and _waiting_popup != popup:
			var waiting_popup := _waiting_popup
			_waiting_popup = null
			waiting_popup.call(&"toggle")
		return
	for other_popup in popups:
		if other_popup == popup or !other_popup.visible:
			continue
		other_popup.call(&"toggle")
		if other_popup.visible: # asking whether to discard its changes
			_waiting_popup = popup
			popup.call(&"toggle")
		return


func _on_confirmation_canceled() -> void:
	_waiting_popup = null
