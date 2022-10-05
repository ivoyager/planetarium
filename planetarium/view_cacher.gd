# view_cacher.gd
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
class_name ViewCacher
extends Timer

# Caches current camera view and time.
#
# We don't currently have a way to intercept app quit for HTML5 export. Hence,
# set cache_interval for HTML5 exports. For non-HTML5 exports, cache will be
# written on quit and cache_interval should not be set.

const CACHE_VERSION := 5 # be careful not to crash older versions!

var cache_interval := 0.0 # s; set >0.0 to enable Timer
var cache_file_name := "view.vbinary"
var is_time_cache := true

var _cache_dir: String = IVGlobal.cache_dir
var _camera: IVCamera

onready var _timekeeper: IVTimekeeper = IVGlobal.program.Timekeeper


func _project_init() -> void:
	var dir = Directory.new()
	if dir.open(_cache_dir) != OK:
		dir.make_dir(_cache_dir)
	if cache_interval > 0.0:
		wait_time = cache_interval
	else:
		paused = true # start() order won't do anything


func _ready() -> void:
	IVGlobal.connect("camera_ready", self, "_set_camera")
	IVGlobal.connect("about_to_start_simulator", self, "_on_about_to_start_simulator")
	IVGlobal.connect("simulator_started", self, "start") # start if not paused
	IVGlobal.connect("about_to_free_procedural_nodes", self, "_clear")
	IVGlobal.connect("about_to_quit", self, "_write_cache") # app quit button
	connect("timeout", self, "_write_cache")


func _notification(what: int) -> void:
	# This should work for all desktop exports; does NOT work for HTML5 export.
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		_write_cache()


func _clear() -> void:
	_camera = null
	stop()


func _set_camera(camera: IVCamera) -> void:
	_camera = camera


func _on_about_to_start_simulator(_is_new_game: bool) -> void:
	if !_camera:
		return
	var cache := _read_cache()
	if !cache:
		print("Missing or obsolete view cache!")
		return
	var view: IVView = cache[1]
	var selection_name := view.selection_name
	var has_time_cache := is_time_cache and cache.size() > 2
	var project_gui: Control = IVGlobal.program.ProjectGUI
	var selection_manager: IVSelectionManager = project_gui.selection_manager
	if !selection_manager:
		return
	print("Moving camera to cached view", " and setting cached time" if has_time_cache else "")
	selection_manager.erase_history()
	# Select to set selection history & GUI, then move camera to view
	selection_manager.select_by_name(selection_name)
	_camera.move_to_view(view, true)
	if has_time_cache:
		_timekeeper.set_time(cache[2])
		_timekeeper.change_speed(0, cache[3])
		_timekeeper.set_time_reversed(cache[4])


func _read_cache() -> Array:
	# return cache array if current version
	var file := _get_file(File.READ)
	if !file:
		return []
	var untyped_cache = file.get_var()
	if typeof(untyped_cache) != TYPE_ARRAY: # was dictionary pre-v0.0.12
		return []
	var cache := untyped_cache as Array
	if !cache or cache[0] != CACHE_VERSION:
		return []
	cache[1] = dict2inst(cache[1]) # IVView
	return cache


func _write_cache() -> void:
	if !_camera:
		return
	var file := _get_file(File.WRITE)
	if !file:
		return
	var view := _camera.create_view()
	var view_dict := inst2dict(view)
	var cache := [CACHE_VERSION, view_dict]
	if is_time_cache and !_timekeeper.is_real_world_time:
		# cache.size() > 2
		cache.append(_timekeeper.time)
		cache.append(_timekeeper.speed_index)
		cache.append(_timekeeper.is_reversed)
	file.store_var(cache)


func _get_file(flags: int) -> File:
	var file_path := _cache_dir.plus_file(cache_file_name)
	var file := File.new()
	if file.open(file_path, flags) != OK:
		if flags == File.WRITE:
			print("ERROR! Could not open ", file_path, " for write!")
		else:
			print("Could not open ", file_path, " for read (expected if no changes)")
		return null
	return file
