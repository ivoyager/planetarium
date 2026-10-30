# galileo_chat_box.gd
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
class_name GalileoChatBox
extends IVAssistantChatBox

## Galileo's chat box, which shows the tools Galileo calls only with the user's
## option "Show API Commands" (setting [code]galileo_show_api_commands[/code]).


func _ready() -> void:
	super()
	if IVStateManager.initialized_core:
		_configure_after_core_inited()
	else:
		IVStateManager.core_initialized.connect(_configure_after_core_inited, CONNECT_ONE_SHOT)


func _configure_after_core_inited() -> void:
	IVSettingsManager.changed.connect(_settings_listener)
	show_tool_calls = IVSettingsManager.get_setting(&"galileo_show_api_commands")


func _settings_listener(setting: StringName, value: Variant) -> void:
	if setting == &"galileo_show_api_commands":
		show_tool_calls = value
