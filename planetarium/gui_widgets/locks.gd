# plntrm_info.gd
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

extends VBoxContainer

onready var _settings_manager: SettingsManager = Global.program.SettingsManager


func _ready():
	var settings: Dictionary = Global.settings
	$Locks1/LkTimeCkBx.pressed = settings.lock_time
	$Locks1/LkSelectionCkBx.pressed = settings.lock_selection
	$Locks2/LkControlsCkBx.pressed = settings.lock_controls
	$Locks2/LkRangeCkBx.pressed = settings.lock_range
	$Locks3/LkInfoCkBx.pressed = settings.lock_info
	$Locks3/LkNavCkBx.pressed = settings.lock_navigator
	$Locks1/LkTimeCkBx.connect("toggled", self, "_lock_toggled", ["lock_time"])
	$Locks1/LkSelectionCkBx.connect("toggled", self, "_lock_toggled", ["lock_selection"])
	$Locks2/LkControlsCkBx.connect("toggled", self, "_lock_toggled", ["lock_controls"])
	$Locks2/LkRangeCkBx.connect("toggled", self, "_lock_toggled", ["lock_range"])
	$Locks3/LkInfoCkBx.connect("toggled", self, "_lock_toggled", ["lock_info"])
	$Locks3/LkNavCkBx.connect("toggled", self, "_lock_toggled", ["lock_navigator"])
	
func _lock_toggled(pressed: bool, setting_name: String):
	_settings_manager.change_current(setting_name, pressed)
	
