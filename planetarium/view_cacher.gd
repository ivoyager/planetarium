# view_cacher.gd
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
class_name ViewCacher
extends Timer

# Caches current View (camera, HUDs and time state) and restores on start.
#
# We don't currently have a way to intercept app quit for HTML5 export. Hence,
# set cache_interval for HTML5 exports.
#
# For non-HTML5 exports, cache will be written on quit and cache_interval
# should not be set. The Timer functionality will not be used.

const ViewFlags := IVView.ViewFlags

var cache_interval := 0.0 # s; set >0.0 to enable Timer (HTML5 only!)
var cache_name := &"current"
var cach_set := &"view_cacher"
var view_flags := ViewFlags.VIEWFLAGS_ALL

var _view_manager: IVViewManager


func _ready() -> void:
	_view_manager = IVGlobal.program[&"ViewManager"]
	IVGlobal.about_to_start_simulator.connect(_on_about_to_start_simulator)
	IVGlobal.about_to_stop_before_quit.connect(_cache_now.bind(false))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: # desktop only!
		if IVGlobal.state.is_started_or_about_to_start:
			_cache_now(false)


func _on_about_to_start_simulator(_is_new_game: bool) -> void:
	if cache_interval > 0.0:
		timeout.connect(_on_timeout)
		wait_time = cache_interval
		start()
	else:
		paused = true
	if _view_manager.has_view(cache_name, cach_set, true):
		_view_manager.set_view(cache_name, cach_set, true, true)
	else:
		_view_manager.set_table_view(&"VIEW_HOME", true)


func _on_timeout() -> void:
	_cache_now()
	start()


func _cache_now(allow_threaded_cache_write := true) -> void:
	_view_manager.save_view(cache_name, cach_set, true, view_flags, allow_threaded_cache_write)
