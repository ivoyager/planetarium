# dialog_rig_probe.gd
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
class_name DialogRigProbe
extends RefCounted

## Renders a body through [IVBody2DCaptureDialog]'s own path, for automated measurement.
##
## Drives [IVBody2DCapturer] through the sequence the dialog uses -- stage on the body's
## own camera radius, reset pose, [code]solve_fit_zoom[/code], [code]capture_image[/code]
## -- so the dialog-only half of the capturer, the fit and the readback conversion, can be
## measured headlessly. Neither is reached by
## [code]addons/tools/body_2d_icon_capture.gd[/code], which captures the shipped icons; the
## two are one rig, and this is what shows they have not drifted apart.[br][br]
##
## A client calls these members through the [code]ivoyager_assistant[/code] plugin's
## [code]call[/code], addressing this object by its role, "DialogRigProbe"
## ([code]ivoyager_override2.cfg[/code] adds it to the program); both wait for the
## simulator to start. Rendering needs frames, so a capture cannot answer within one call:
## [method capture_dialog_icon] starts one and returns immediately, and
## [method poll_dialog_icon] returns the result once it lands.[br][br]
##
## Companion to [code]planetarium/exposure_probe.gd[/code]; the note there on where
## these two live, and on coding them for general use, applies here too.

const AUTOMATION_METHODS: Array[StringName] = [
	&"capture_dialog_icon",
	&"poll_dialog_icon",
]

const RIG_SIZE := IVBody2DCapturer.ICON_SIZE * IVBody2DCapturer.SUPERSAMPLE

var _capturer: IVBody2DCapturer
var _viewport: SubViewport
var _camera: Camera3D
var _key_light: DirectionalLight3D
var _fill_light: DirectionalLight3D
var _yaw_pivot: Node3D
var _pitch_pivot: Node3D
var _model_holder: Node3D


var _running := false
var _result: Dictionary


## Whether an automation client may use [param _member] now: both members wait for the
## simulator to start.
func is_automation_available(_member: StringName) -> bool:
	return IVStateManager.started


## Starts one render of body [param name] through the dialog's own path, saved to
## [param out_path] where one is given, and returns at once; poll
## [method poll_dialog_icon] for the result.
func capture_dialog_icon(name: String, out_path := "") -> Dictionary:
	if _running:
		return {"error": "already running"}
	_running = true
	_result = {}
	# A render needs frames, so the capture runs on and publishes through _result and
	# _running for poll_dialog_icon to collect.
	_capture(StringName(name), out_path)
	return {"started": true}


## The running render's result once it has landed, with [code]done[/code] true; until then
## only [code]{"done": false}[/code].
func poll_dialog_icon() -> Dictionary:
	if _running:
		return {"done": false}
	var result := _result
	_result = {}
	result["done"] = true
	return result


func _capture(body_name: StringName, out_path: String) -> void:
	if !IVBody.bodies.has(body_name):
		_finish({"error": "no body %s" % body_name})
		return
	_build_rig()
	var body: IVBody = IVBody.bodies[body_name]
	var visual := body.make_body_visual()
	if !visual:
		_free_rig()
		_finish({"error": "%s has no model" % body_name})
		return
	# The dialog's own staging: a reference radius except for a packed craft model.
	var asset_preloader: IVAssetPreloader = IVGlobal.program[&"AssetPreloader"]
	var reference_radius := 0.0
	if !asset_preloader.get_body_packed_model(body_name):
		reference_radius = body.get_camera_radius()
	var aabb := _capturer.stage_visual(visual, reference_radius)
	var key_dir := IVBody2DCapturer.KEY_DIR
	if _capturer.get_staged_model() is IVShellsModel:
		key_dir = IVBody2DCapturer.SHELLS_KEY_DIR
	var azimuth_elevation := IVBody2DCapturer.direction_to_azimuth_elevation(key_dir)
	_capturer.set_key_light(azimuth_elevation.x, azimuth_elevation.y)
	_capturer.set_brightness(IVBody2DCapturer.DEFAULT_BRIGHTNESS)
	_capturer.set_ambient(0.0)
	var zoom := 1.0
	_capturer.frame_camera(aabb, IVBody2DCapturer.DEFAULT_YAW, IVBody2DCapturer.DEFAULT_PITCH,
			zoom, Vector2.ZERO)
	var fit_msec := Time.get_ticks_msec()
	for _iteration in 2:
		zoom = await _capturer.solve_fit_zoom(zoom)
		_capturer.frame_camera(aabb, IVBody2DCapturer.DEFAULT_YAW, IVBody2DCapturer.DEFAULT_PITCH,
				zoom, Vector2.ZERO)
	fit_msec = Time.get_ticks_msec() - fit_msec
	var image := await _capturer.capture_image()
	var result := {"body": String(body_name), "zoom": zoom, "fit_msec": fit_msec,
			"reference_radius": reference_radius}
	if image:
		if !out_path.is_empty():
			result["save_error"] = image.save_png(out_path)
			result["path"] = out_path
		result["silhouette"] = str(IVBody2DCapturer.get_silhouette_rect(image))
	else:
		result["error"] = "no image"
	_capturer.clear_visual()
	_free_rig()
	_finish(result)


func _finish(result: Dictionary) -> void:
	_result = result
	_running = false


func _build_rig() -> void:
	_free_rig()
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(RIG_SIZE, RIG_SIZE)
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.msaa_3d = Viewport.MSAA_4X
	IVGlobal.get_tree().root.add_child(_viewport)
	_camera = Camera3D.new()
	_camera.current = true
	_viewport.add_child(_camera)
	_key_light = DirectionalLight3D.new()
	_viewport.add_child(_key_light)
	_fill_light = DirectionalLight3D.new()
	_viewport.add_child(_fill_light)
	_yaw_pivot = Node3D.new()
	_viewport.add_child(_yaw_pivot)
	_pitch_pivot = Node3D.new()
	_yaw_pivot.add_child(_pitch_pivot)
	_model_holder = Node3D.new()
	_pitch_pivot.add_child(_model_holder)
	_capturer = IVBody2DCapturer.new()
	_capturer.bind_nodes(_viewport, _camera, _key_light, _fill_light, _yaw_pivot, _pitch_pivot,
			_model_holder)


func _free_rig() -> void:
	if _viewport:
		_viewport.queue_free()
		_viewport = null
	_capturer = null
