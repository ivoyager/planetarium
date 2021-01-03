# view_cacher.gd
# This file is part of I, Voyager (https://ivoyager.dev)
# *****************************************************************************
# Copyright (c) 2017-2020 Charlie Whitfield
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
# TODO: Rename to StateCacher and cache speed and time

class_name ViewCacher

var cache_file_name := "view.vbinary"

var _cache_dir: String = Global.cache_dir
var _camera: VygrCamera

func project_init() -> void:
	Global.connect("camera_ready", self, "_on_camera_ready")
	Global.connect("about_to_quit", self, "_on_about_to_quit")
	var dir = Directory.new()
	if dir.open(_cache_dir) != OK:
		dir.make_dir(_cache_dir)

func _on_camera_ready(camera: VygrCamera) -> void:
	_camera = camera
	var file := _get_file(File.READ)
	if !file:
		return
	var view_dict: Dictionary = file.get_var()
	var view: View = dict2inst(view_dict)
	camera.cache_view = view

func _on_about_to_quit() -> void:
	var file := _get_file(File.WRITE)
	if !file:
		return
	var view := _camera.create_view()
	var view_dict := inst2dict(view)
	file.store_var(view_dict)

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
