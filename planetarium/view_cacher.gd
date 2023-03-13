# view_cacher.gd
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
class_name ViewCacher
extends Timer

# Caches current View (camera, HUDs and time state) and restores on start.
#
# We don't currently have a way to intercept app quit for HTML5 export. Hence,
# set cache_interval for HTML5 exports.
#
# For non-HTML5 exports, cache will be written on quit and cache_interval
# should not be set. The Timer functionality will not be used.

var cache_interval := 0.0 # s; set >0.0 to enable Timer (HTML5 only!)
var cache_name := "current"
var cach_set := "view_cacher"
var view_flags := IVView.ALL

var _view_manager: IVViewManager


func _project_init() -> void:
	_view_manager = IVGlobal.program.ViewManager
	IVGlobal.connect("about_to_start_simulator", self, "_on_about_to_start_simulator")
	IVGlobal.connect("about_to_stop_before_quit", self, "_cache_now")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_QUIT_REQUEST: # does NOT work for HTML5 export!
		if IVGlobal.state.is_started_or_about_to_start:
			_cache_now()


func _on_about_to_start_simulator(_is_new_game: bool) -> void:
	if cache_interval > 0.0:
		connect("timeout", self, "_on_timeout")
		wait_time = cache_interval
		start()
	else:
		paused = true
	if _view_manager.has_view(cache_name, cach_set, true):
		_view_manager.set_view(cache_name, cach_set, true, true)
	else:
		var view_defaults: IVViewDefaults = IVGlobal.program.ViewDefaults
		view_defaults.set_view("Home", true)


func _on_timeout() -> void:
	_cache_now()
	start()


func _cache_now() -> void:
	_view_manager.save_view(cache_name, cach_set, true, view_flags)

