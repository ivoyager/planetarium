# probe_exposure_suite.gd
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
extends IVAssistantTestSuite

## Assistant API for measuring the physical-light chain in a running simulator.
##
## Reports [IVExposureManager] state, derived photometry and the per-body metering
## table, and drives the levers a photometric investigation needs: a shell's visibility
## and its shader parameters, a body's exposure ceilings, the limb ring's per-sample
## breakdown, and the engine's own unprojection of a limb circle.[br][br]
##
## A measuring instrument rather than a test -- nothing here asserts. Its callers are
## Python drivers in the private assets build tree, reached over the
## [code]ivoyager_assistant[/code] TCP server, and what they measure is written up there
## and in [code]addons/ivoyager_core/PHOTOMETRIC_MODEL.md[/code]. That document's TODO
## list is the standing reason this suite is here.[br][br]
##
## Register it in [code]ivoyager_override2.cfg[/code] under
## [code][assistant_test_suites][/code]. It reads private members of
## [IVExposureManager] and [IVShellsModel] -- deliberately, since a probe exists to
## reach what the public API does not expose, but a rename in Core breaks it here and
## nothing else will report it.[br][br]
##
## It lives in this project because the work driving it does, not because it is
## Planetarium-specific. Whether to code it for general use is open -- another project
## needing an asset pipeline would want this rather than its own copy.


var _lights: Array[IVDynamicLight] = []
var _world_environment: WorldEnvironment
var _stars_visual: IVStarsVisual
var _sun_disc_material: ShaderMaterial


func _on_simulator_started() -> void:
	_lights.clear()
	_world_environment = IVGlobal.program.get(&"WorldEnvironment")
	_collect(IVGlobal.get_tree().root)


func _on_about_to_free() -> void:
	_lights.clear()
	_world_environment = null
	_sun_disc_material = null


func get_method_names() -> Array[String]:
	return ["get_rings_geometry", "get_ring_frame", "set_rings",
			"get_exposure_state", "get_photometry", "get_metering_table", "set_physical_light",
			"get_body_debug", "set_ambient_energy", "set_reflected_light", "list_lights",
			"poke_sky_radiance", "get_shadow_receivers", "set_exposure_ceiling",
			"get_limb_samples", "set_limb_meter", "set_ring_meter", "set_exposure",
			"project_limb_circle", "list_saved_views", "apply_saved_view", "get_render_time",
			"set_shell_visible", "set_shell_param", "set_glow", "set_psf_settings",
			"get_exposure_skips", "set_exposure_skips", "get_shadow_skips", "set_shadow_skips"]


func get_method_summaries() -> Dictionary:
	return {
		"get_exposure_state": "Report exposure statics, light energies, and managed scene values.",
		"get_photometry": "Report the manager's tuning members and derived calibration.",
		"get_metering_table": "Report per-body metering rows (mirrors manager math; no parent shadow).",
		"get_rings_geometry": "Report each ring system's camera and sun elevation above its plane, and the phase angle.",
		"set_rings": "Show, hide or re-parameterize a ring system at runtime ({\"visible\": bool, \"param\": String, \"value\": float}; omit a key to keep it). Decomposes a rendered pixel into ring against globe, and sweeps a photometric candidate in ONE app run.",
		"get_ring_frame": "The camera's own projection and transform beside each ring plane's frame and its planet's figure, all in km ({}). Enough to turn any screen pixel into the ring radius it looks at, offline - which is what a rendered ring artifact has to be identified by.",
		"set_physical_light": "Set the physical_light user setting ({\"enabled\": bool}).",
		"get_body_debug": "Report an IVBody's metering-relevant state ({\"name\": entity_name}).",
		"set_ambient_energy": "Override Environment.ambient_light_energy ({\"energy\": float}).",
		"set_reflected_light": "Set Environment.reflected_light_source ({\"disabled\": bool}).",
		"list_lights": "List every Light3D in the tree with energy/visibility.",
		"poke_sky_radiance": "Rewrite the sky material's energy_multiplier to trigger a radiance rebake.",
		"get_shadow_receivers": "Report per-body analytic-occlusion opt-in, visual layers, and parent-shadow fraction.",
		"set_limb_meter": "Override the limb ramp at runtime ({\"start\": float, \"full\": float, \"edge\": float}; omit a key to keep it).",
		"set_ring_meter": "Override the ring openness ramp at runtime ({\"onset\": float, \"full\": float}; omit a key to keep it); sweeps the edge-on release in ONE app run.",
		"set_exposure": "Freeze or release auto exposure ({\"auto\": bool, \"manual_ev\": float}; omit a key to keep it). A frozen exposure is what separates a render change from a metering change.",
		"list_saved_views": "List the user's cached views by collection ({}); apply_view covers table views only.",
		"apply_saved_view": "Apply one cached view ({\"name\": String, \"collection\": String}).",
		"get_render_time": "Last frame's measured viewport render times ({}); enables measurement on first call, so poll and average.",
		"project_limb_circle": "Screen positions of a body's silhouette circle at a given altitude ({\"name\": entity_name, \"altitude_km\": float, \"samples\": int}); the projection is the engine's own, so it holds off axis, where a sphere's silhouette is an ellipse and a circle fit is meaningless.",
		"get_limb_samples": "Per-sample breakdown of one body's limb ring ({\"name\": entity_name}).",
		"set_shell_param": "Set one shader parameter on one shell's material ({\"name\": entity_name, \"shell\": int, \"param\": String, \"value\": float}); sweeps a candidate in ONE app run instead of one run per value.",
		"set_shell_visible": "Show or hide one IVShellsModel shell ({\"name\": entity_name, \"shell\": int, \"visible\": bool}); shell 0 is the surface, 1..N its overlays. Decomposes a rendered pixel into the shells that built it.",
		"set_psf_settings": "Set IVPSFSettings values at runtime ({\"psf_sigma\": float, \"intensity_scale\": float, \"intensity_gamma\": float, \"intensity_faint_mag\": float, \"color_saturation\": float, \"fov_compensation\": float, \"glare_scale\": float, \"glare_gamma\": float, \"glare_max_px\": float}; omit a key to keep it). One object feeds the catalog field and every body's PSF quad, so a sweep moves them together. Reports every value back.",
		"set_glow": "Set Environment glow properties at runtime ({\"enabled\": bool, \"intensity\": float, \"strength\": float, \"bloom\": float, \"hdr_threshold\": float, \"hdr_scale\": float, \"hdr_luminance_cap\": float, \"blend_mode\": int, \"levels\": [float x 7]}; omit a key to keep it). Levels are as authored for the reference height, which IVWorldEnvironment shifts to the render height from the next frame. Reports every glow property back (levels as applied, authored_levels as set), so a sweep records the state it measured.",
		"set_exposure_ceiling": "Override a body's shells.tsv exposure_ceiling / limb_exposure_ceiling cells at runtime ({\"name\": entity_name, \"ceiling\": float, \"limb_only\": bool}); 0.0 removes them.",
		"get_exposure_skips": "Report what the exposure-driven skips are dropping ({}): the sky pass, and every star magnitude bin with its star count, brightest magnitude, peak sky density and current visibility. A zero-pixel A/B proves nothing unless the mechanism actually fired, and this is what says whether it did.",
		"set_exposure_skips": "Turn either exposure-driven skip off or on ({\"sky\": bool, \"stars\": bool, \"capture_height\": float}; omit a key to keep it). Off is the un-culled render an A/B diffs against, in ONE app run and so at ONE exposure. capture_height stands in for IVScreenshotManager's off-screen render height, which is otherwise unreachable from a driver; 0.0 clears it. Reports the state back.",
		"get_shadow_skips": "Report the empty-shadow-pass decision per IVDynamicLight ({}): each light's table intent, live shadow_enabled, reach, cull mask and idle frame count, beside every registered local-shadow participant with its layers, visibility and surface distance. Says whether the mechanism actually fired, which a zero-pixel A/B cannot.",
		"set_shadow_skips": "Turn the empty-shadow-pass skip off or on for every light ({\"enabled\": bool}); off restores each light's table shadow_enabled, which is the un-skipped render an A/B diffs against, in ONE app run at ONE pose. Reports the state back.",
	}


func dispatch(method: String, params: Dictionary) -> Variant:
	match method:
		"set_rings":
			return _set_rings(params)
		"get_ring_frame":
			return _get_ring_frame()
		"get_exposure_state":
			return _get_exposure_state()
		"get_photometry":
			return _get_photometry()
		"get_metering_table":
			return _get_metering_table()
		"set_physical_light":
			return _set_physical_light(params)
		"get_body_debug":
			return _get_body_debug(params)
		"set_ambient_energy":
			return _set_ambient_energy(params)
		"set_reflected_light":
			return _set_reflected_light(params)
		"list_lights":
			return _list_lights()
		"poke_sky_radiance":
			return _poke_sky_radiance()
		"get_shadow_receivers":
			return _get_shadow_receivers()
		"set_exposure_ceiling":
			return _set_exposure_ceiling(params)
		"get_limb_samples":
			return _get_limb_samples(params)
		"set_limb_meter":
			return _set_limb_meter(params)
		"set_ring_meter":
			return _set_ring_meter(params)
		"set_exposure":
			return _set_exposure(params)
		"project_limb_circle":
			return _project_limb_circle(params)
		"list_saved_views":
			return _list_saved_views()
		"apply_saved_view":
			return _apply_saved_view(params)
		"get_render_time":
			return _get_render_time()
		"set_shell_visible":
			return _set_shell_visible(params)
		"set_glow":
			return _set_glow(params)
		"set_psf_settings":
			return _set_psf_settings(params)
		"set_shell_param":
			return _set_shell_param(params)
		"get_rings_geometry":
			return _get_rings_geometry()
		"get_exposure_skips":
			return _get_exposure_skips()
		"set_exposure_skips":
			return _set_exposure_skips(params)
		"get_shadow_skips":
			return _get_shadow_skips()
		"set_shadow_skips":
			return _set_shadow_skips(params)
	return {"_error": {"code": ERR_UNKNOWN_METHOD, "message": "Unknown method: %s" % method}}


# Every IVRings node's geometry in the two angles that decide how a ring system looks:
# the camera's and the sun's elevation above the ring PLANE, plus the phase angle. A
# caller outside the app cannot derive these -- IVCamera's view_position latitude is an
# ECLIPTIC latitude, and a ring plane sits at the body's own obliquity to that, so posing
# by latitude sweeps an axis that is neither of them (measured: camera latitude -26 deg
# put Saturn's rings edge-on and latitude 0 left them 26 deg open). Report what the
# renderer itself uses, so a rig can solve for the elevation it wants.
#
# Sign convention: elevations are signed against the SAME plane normal, so
# camera_elevation and sun_elevation sharing a sign means the camera sees the lit face.
# IVRings flips its own node to keep +y sunward, so the node basis cannot be read for
# this -- the normal here is taken before that flip by keying on the sun.
func _get_rings_geometry() -> Variant:
	var camera := IVGlobal.get_tree().root.get_camera_3d()
	if !camera:
		return {"_error": {"code": ERR_NOT_STARTED, "message": "No camera"}}
	var camera_position := camera.global_position
	var rows: Array[Dictionary] = []
	for rings: IVRings in _find_rings(IVGlobal.get_tree().root):
		# IVRings is not necessarily a direct child of its IVBody; walk up for it.
		var body: IVBody = null
		var ancestor := rings.get_parent()
		while ancestor:
			var candidate := ancestor as IVBody
			if candidate:
				body = candidate
				break
			ancestor = ancestor.get_parent()
		var star: IVBody = IVBody.bodies.get(rings.illuminating_star)
		if !body or !star:
			continue
		var normal := rings.global_basis.y.normalized()
		var center := rings.global_position
		var to_sun := (star.global_position - center)
		var to_camera := (camera_position - center)
		# Take the normal on the sun's side, so both elevations are signed consistently.
		if normal.dot(to_sun) < 0.0:
			normal = -normal
		var sun_distance := to_sun.length()
		var camera_distance := to_camera.length()
		var sun_elevation := asin(clampf(normal.dot(to_sun) / sun_distance, -1.0, 1.0))
		var camera_elevation := asin(clampf(normal.dot(to_camera) / camera_distance, -1.0, 1.0))
		var phase := acos(clampf(to_sun.normalized().dot(to_camera.normalized()), -1.0, 1.0))
		# The plane/point crossfade, both ends of it, and the quad it hands over to.
		var material := rings.get_surface_override_material(0) as ShaderMaterial
		var plane_fraction: Variant = (material.get_shader_parameter(
				&"plane_light_fraction") if material else null)
		# Read through get() so this suite still runs against a build without the
		# plane-to-point handoff -- which is exactly the build an A/B compares to.
		var flux_factor: Variant = body.get(&"rings_psf_flux_factor")
		# Render-buffer pixels, as IVRings decides the crossfade in: the taller of the
		# window's and the one a capture has registered (through get(), as above). Taken
		# from the window's own pixels, which a display scale makes finer than its visible
		# rect; inline rather than IVGraphicsManager.get_render_size(), which an older
		# build lacks.
		var window := IVGlobal.get_window()
		var render_height := floorf(window.size.y * window.scaling_3d_scale)
		var capture_height_variant: Variant = rings.get(&"capture_render_height")
		if typeof(capture_height_variant) == TYPE_FLOAT:
			var capture_height: float = capture_height_variant
			render_height = maxf(render_height, capture_height)
		var pixel_angle := 2.0 / maxf(render_height
				* absf(camera.get_camera_projection().y.y), 1e-9)
		var profile_variant: Variant = rings.get(&"_psf_tau")
		var profile_bins := -1
		if typeof(profile_variant) == TYPE_PACKED_FLOAT64_ARRAY:
			var profile: PackedFloat64Array = profile_variant
			profile_bins = profile.size()
		var psf_magnitude := NAN
		var body_psf := body.get_node_or_null(^"BodyPSF") as MeshInstance3D
		if body_psf:
			var psf_material := body_psf.material_override as ShaderMaterial
			if psf_material:
				psf_magnitude = psf_material.get_shader_parameter(&"apparent_magnitude")
		rows.append({
			"rings": String(rings.name),
			"body": String(body.name),
			"camera_elevation_deg": rad_to_deg(camera_elevation),
			"sun_elevation_deg": rad_to_deg(sun_elevation),
			"phase_deg": rad_to_deg(phase),
			"lit_face": camera_elevation >= 0.0,
			"camera_distance_m": camera_distance,
			"camera_distance_outer_radii": camera_distance / rings.outer_radius,
			"inner_radius_m": rings.inner_radius,
			"outer_radius_m": rings.outer_radius,
			"texture_inner_radius_m": rings.texture_inner_radius,
			"texture_outer_radius_m": rings.texture_outer_radius,
			"render_height": render_height,
			"outer_pixels": rings.outer_radius / (camera_distance * pixel_angle),
			"plane_light_fraction": plane_fraction,
			"psf_flux_factor": flux_factor,
			"psf_profile_bins": profile_bins,
			"body_psf_magnitude": psf_magnitude,
		})
	return {"rows": rows}


# Show, hide or re-parameterize every ring system. Hiding one separates what the ring
# draws from what the globe behind it draws, which a screenshot alone cannot.
func _set_rings(params: Dictionary) -> Variant:
	var found := _find_rings(IVGlobal.get_tree().root)
	if found.is_empty():
		return {"_error": {"code": ERR_DOES_NOT_EXIST, "message": "no IVRings in the tree"}}
	var parameter: String = params.get("param", "")
	var rows: Array[Dictionary] = []
	for rings: IVRings in found:
		if params.has("visible"):
			var wanted_visible: bool = params["visible"]
			rings.visible = wanted_visible
		var material := rings.get_surface_override_material(0) as ShaderMaterial
		if parameter and material:
			if params.has("value"):
				var value: float = params["value"]
				material.set_shader_parameter(StringName(parameter), value)
			rows.append({"rings": String(rings.name), "visible": rings.visible,
					"param": parameter,
					"value": material.get_shader_parameter(StringName(parameter))})
		else:
			rows.append({"rings": String(rings.name), "visible": rings.visible})
	return {"ok": true, "rings": rows}


# The camera's projection and transform, each ring plane's own frame, and the planet's
# figure -- everything a Python driver needs to intersect a screen ray with the ring plane
# offline. Screen positions are unaffected by the farwarp depth remap, so the engine's own
# projection matrix describes them exactly.
func _get_ring_frame() -> Variant:
	var camera := IVGlobal.get_viewport().get_camera_3d()
	if !camera:
		return {"_error": {"code": ERR_NOT_STARTED, "message": "No camera"}}
	var km := IVUnits.KM
	var view_size := camera.get_viewport().get_visible_rect().size
	var projection := camera.get_camera_projection()
	var basis := camera.global_basis
	var rows: Array[Dictionary] = []
	for rings: IVRings in _find_rings(IVGlobal.get_tree().root):
		var body: IVBody = null
		var ancestor := rings.get_parent()
		while ancestor:
			var candidate := ancestor as IVBody
			if candidate:
				body = candidate
				break
			ancestor = ancestor.get_parent()
		var star: IVBody = IVBody.bodies.get(rings.illuminating_star)
		if !body or !star:
			continue
		var rings_basis := rings.global_basis
		rows.append({
			"rings": String(rings.name),
			"body": String(body.name),
			"center_km": _vector(rings.global_position, km),
			"normal": _vector(rings_basis.y.normalized(), 1.0),
			"axis_x": _vector(rings_basis.x.normalized(), 1.0),
			"axis_z": _vector(rings_basis.z.normalized(), 1.0),
			"plane_radius_km": rings_basis.x.length() / km,
			"inner_radius_km": rings.inner_radius / km,
			"outer_radius_km": rings.outer_radius / km,
			"texture_inner_radius_km": rings.texture_inner_radius / km,
			"texture_outer_radius_km": rings.texture_outer_radius / km,
			"body_center_km": _vector(body.global_position, km),
			"body_equatorial_radius_km": body.get_equatorial_radius() / km,
			"body_polar_radius_km": body.get_polar_radius() / km,
			"body_pole": _vector(body.basis.y.normalized(), 1.0),
			"star_center_km": _vector(star.global_position, km),
			"star_radius_km": star.mean_radius / km,
		})
	return {
		"view_size": [view_size.x, view_size.y],
		"camera_origin_km": _vector(camera.global_position, km),
		"camera_basis_x": _vector(basis.x, 1.0),
		"camera_basis_y": _vector(basis.y, 1.0),
		"camera_basis_z": _vector(basis.z, 1.0),
		"projection": [[projection.x.x, projection.x.y, projection.x.z, projection.x.w],
				[projection.y.x, projection.y.y, projection.y.z, projection.y.w],
				[projection.z.x, projection.z.y, projection.z.z, projection.z.w],
				[projection.w.x, projection.w.y, projection.w.z, projection.w.w]],
		"rings": rows,
	}


func _vector(value: Vector3, unit: float) -> Array:
	return [value.x / unit, value.y / unit, value.z / unit]


func _find_rings(node: Node) -> Array[IVRings]:
	var found: Array[IVRings] = []
	var rings := node as IVRings
	if rings:
		found.append(rings)
	for child in node.get_children():
		found.append_array(_find_rings(child))
	return found


# Show or hide one IVShellsModel shell of a body ({"name", "shell", "visible"}), so a
# rendered pixel can be decomposed into the shells that built it. Shell 0 is the surface
# and the orchestrator; 1..N are its child shells (a cloud deck, an atmosphere limb).
func _set_shell_visible(params: Dictionary) -> Variant:
	var name_string: String = params.get("name", "")
	var body: IVBody = IVBody.bodies.get(StringName(name_string))
	if !body:
		return {"_error": {"code": ERR_DOES_NOT_EXIST, "message": "no body"}}
	var wanted: int = params.get("shell", 1)
	var wanted_visible: bool = params.get("visible", true)
	var found: Array[int] = []
	var hit := false
	for shell in _find_shells(body):
		var index := shell._shell
		found.append(index)
		if index == wanted:
			shell.visible = wanted_visible
			hit = true
	if not hit:
		return {"_error": {"code": ERR_DOES_NOT_EXIST,
				"message": "no shell %d; body has %s" % [wanted, found]}}
	return {"body": String(body.name), "shell": wanted, "visible": wanted_visible,
			"shells": found}


func _set_shell_param(params: Dictionary) -> Variant:
	var name_string: String = params.get("name", "")
	var body: IVBody = IVBody.bodies.get(StringName(name_string))
	if !body:
		return {"_error": {"code": ERR_DOES_NOT_EXIST, "message": "no body"}}
	var wanted: int = params.get("shell", 1)
	var param_string: String = params.get("param", "")
	var param := StringName(param_string)
	var value: Variant = params.get("value")
	for shell in _find_shells(body):
		if shell._shell != wanted:
			continue
		var material := shell.get_surface_override_material(0) as ShaderMaterial
		if !material:
			return {"_error": {"code": ERR_UNAVAILABLE, "message": "shell has no ShaderMaterial"}}
		material.set_shader_parameter(param, value)
		return {"shell": wanted, "param": param_string,
				"read_back": material.get_shader_parameter(param)}
	return {"_error": {"code": ERR_DOES_NOT_EXIST, "message": "no shell %d" % wanted}}


# Callers read IVShellsModel._shell, a private member -- a rename in Core breaks them here.
func _find_shells(node: Node) -> Array[IVShellsModel]:
	var out: Array[IVShellsModel] = []
	var shell := node as IVShellsModel
	if shell:
		out.append(shell)
	for child in node.get_children():
		out.append_array(_find_shells(child))
	return out


func _get_render_time() -> Variant:
	# viewport_get_measured_render_time_* report the LAST measured frame, and measurement
	# starts only when enabled -- so the first call returns zeros and the caller polls.
	var viewport := IVGlobal.get_viewport()
	var rid := viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	return {
		"cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(rid),
		"gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(rid),
	}


func _set_exposure_ceiling(params: Dictionary) -> Variant:
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return {"_error": {"code": ERR_NOT_ALLOWED,
				"message": "No ExposureManager (enable_physical_light off?)"}}
	var manager: IVExposureManager = manager_var
	var name_var: Variant = params.get("name", "")
	if typeof(name_var) != TYPE_STRING:
		return {"_error": {"code": ERR_INVALID_PARAMS, "message": "Missing 'name' string"}}
	var name_string: String = name_var
	var body_name := StringName(name_string)
	var ceiling_var: Variant = params.get("ceiling")
	if typeof(ceiling_var) != TYPE_FLOAT:
		return {"_error": {"code": ERR_INVALID_PARAMS, "message": "Missing 'ceiling' float"}}
	var ceiling: float = ceiling_var
	# "limb_only": leave the body's own shell ceilings alone. Neutralising Earth's surface
	# cell along with its limb one uncaps its city lights, which then clip and are counted
	# as a blown limb by anything measuring the frame.
	var limb_only: bool = params.get("limb_only", false)
	var has_shell := !limb_only and manager._exposure_ceilings.has(body_name)
	var has_limb := manager._limb_ceilings.has(body_name)
	if !has_shell and !has_limb:
		return {"_error": {"code": ERR_DOES_NOT_EXIST, "message": "No ceiling shell for %s"
				% body_name}}
	var out: Array[Vector2] = []
	if has_shell:
		var shells: Array = manager._exposure_ceilings[body_name]
		for shell: Vector2 in shells:
			out.append(Vector2(shell.x, ceiling))
		if ceiling > 0.0:
			manager._exposure_ceilings[body_name] = out
		else:
			manager._exposure_ceilings.erase(body_name)
	if has_limb:
		if ceiling > 0.0:
			manager._limb_ceilings[body_name] = ceiling
		else:
			manager._limb_ceilings.erase(body_name)
	return {"name": String(body_name), "ceiling": ceiling, "shells": out.size(),
			"limb": has_limb}


func _set_ambient_energy(params: Dictionary) -> Variant:
	if !_world_environment or !_world_environment.environment:
		return {"_error": {"code": ERR_UNAVAILABLE, "message": "No WorldEnvironment"}}
	var energy_var: Variant = params.get("energy")
	if typeof(energy_var) != TYPE_FLOAT:
		return {"_error": {"code": ERR_INVALID_PARAMS, "message": "Missing 'energy' float"}}
	var energy: float = energy_var
	_world_environment.environment.ambient_light_energy = energy
	return {"ok": true, "ambient_light_energy": energy}


func _set_reflected_light(params: Dictionary) -> Variant:
	if !_world_environment or !_world_environment.environment:
		return {"_error": {"code": ERR_UNAVAILABLE, "message": "No WorldEnvironment"}}
	var disabled: bool = params.get("disabled", true)
	_world_environment.environment.reflected_light_source = (
			Environment.REFLECTION_SOURCE_DISABLED if disabled
			else Environment.REFLECTION_SOURCE_BG)
	return {"ok": true, "disabled": disabled}


func _list_lights() -> Variant:
	var rows: Array[Dictionary] = []
	for node in IVGlobal.get_tree().root.find_children("*", "Light3D", true, false):
		var light: Light3D = node
		rows.append({
			"name": String(light.name),
			"class": light.get_class(),
			"visible_in_tree": light.is_visible_in_tree(),
			"light_energy": light.light_energy,
			"parent": String(light.get_parent().name) if light.get_parent() else "",
		})
	return {"lights": rows}


func _poke_sky_radiance() -> Variant:
	if !_world_environment or !_world_environment.environment:
		return {"_error": {"code": ERR_UNAVAILABLE, "message": "No WorldEnvironment"}}
	var sky := _world_environment.environment.sky
	if !sky or not sky.sky_material is ShaderMaterial:
		return {"_error": {"code": ERR_UNAVAILABLE, "message": "No shader sky"}}
	var sky_material: ShaderMaterial = sky.sky_material
	var energy_var: Variant = sky_material.get_shader_parameter(&"energy_multiplier")
	sky_material.set_shader_parameter(&"energy_multiplier", energy_var)
	return {"ok": true, "energy_multiplier": energy_var}


func _get_body_debug(params: Dictionary) -> Variant:
	var name_string: String = params.get("name", "")
	var body: IVBody = IVBody.bodies.get(StringName(name_string))
	if !body:
		return {"_error": {"code": ERR_DOES_NOT_EXIST,
				"message": "No IVBody '%s' in IVBody.bodies" % name_string}}
	var camera := IVGlobal.get_viewport().get_camera_3d()
	var camera_distance := -1.0
	if camera:
		camera_distance = (body.global_position - camera.global_position).length()
	var view_size := Vector2.ZERO
	var fov := 0.0
	if camera:
		view_size = camera.get_viewport().get_visible_rect().size
		fov = camera.fov
	return {
		"visible": body.visible,
		"mean_radius": body.mean_radius,
		"camera_distance": camera_distance,
		"fov": fov,
		"fps": Engine.get_frames_per_second(),
		"view_size": [view_size.x, view_size.y],
		"flags": body.flags,
		"albedo_characteristic": body.characteristics.get(&"albedo"),
		"meter_albedo_characteristic": body.characteristics.get(&"meter_albedo"),
		"child_count": body.get_child_count(),
	}


func _collect(node: Node) -> void:
	if node is IVDynamicLight:
		var light: IVDynamicLight = node
		_lights.append(light)
	elif node is IVStarsVisual:
		var stars_visual: IVStarsVisual = node
		_stars_visual = stars_visual
	for child in node.get_children():
		_collect(child)


func _find_sun_disc_material() -> void:
	if _sun_disc_material:
		return
	var star: IVBody = IVBody.bodies.get(&"STAR_SUN")
	if !star:
		return
	for node in star.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node
		if mesh_instance.get_surface_override_material_count() < 1:
			continue
		var material := mesh_instance.get_surface_override_material(0)
		if material is ShaderMaterial:
			var shader_material: ShaderMaterial = material
			if shader_material.get_shader_parameter(&"brightness") != null:
				_sun_disc_material = shader_material
				return


func _get_starmap_energy() -> float:
	if !_world_environment or !_world_environment.environment:
		return NAN
	var sky := _world_environment.environment.sky
	if !sky:
		return NAN
	var sky_material := sky.sky_material
	if sky_material is ShaderMaterial:
		var shader_material: ShaderMaterial = sky_material
		var energy_var: Variant = shader_material.get_shader_parameter(&"energy_multiplier")
		if typeof(energy_var) == TYPE_FLOAT:
			var energy: float = energy_var
			return energy
	return NAN


func _get_exposure_state() -> Dictionary:
	_find_sun_disc_material()
	var light_names: Array[String] = []
	var light_energies: Array[float] = []
	for light in _lights:
		light_names.append(light.name)
		light_energies.append(light.light_energy)
	var result := {
		"physical_active": IVExposureManager.physical_active,
		"exposure": IVExposureManager.exposure,
		"gain": IVExposureManager.gain,
		"sky_energy": IVExposureManager.sky_energy,
		"setting_physical_light": IVSettingsManager.get_setting(&"physical_light"),
		"light_names": light_names,
		"light_energies": light_energies,
		"starmap_energy": _get_starmap_energy(),
		"camera_sun_visible_fraction": IVSunOcclusionManager.camera_sun_visible_fraction,
	}
	if _world_environment and _world_environment.environment:
		var environment := _world_environment.environment
		result["ambient_light_energy"] = environment.ambient_light_energy
		result["tonemap_exposure"] = environment.tonemap_exposure
	if _sun_disc_material:
		var brightness_var: Variant = _sun_disc_material.get_shader_parameter(&"brightness")
		result["sun_disc_brightness"] = brightness_var
		result["sun_handoff_low"] = _sun_disc_material.get_shader_parameter(&"handoff_low")
		result["sun_handoff_high"] = _sun_disc_material.get_shader_parameter(&"handoff_high")
	return result


func _get_photometry() -> Dictionary:
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return {"_error": {"code": ERR_NOT_ALLOWED,
				"message": "No ExposureManager (enable_physical_light off?)"}}
	var manager: IVExposureManager = manager_var
	return {
		"background_peak_magnitude_per_arcsec2": manager.background_peak_magnitude_per_arcsec2,
		"metering_key": manager.metering_key,
		"meter_fraction_start": manager.meter_fraction_start,
		"meter_fraction_full": manager.meter_fraction_full,
		"adapt_darken_ev_per_second": manager.adapt_darken_ev_per_second,
		"adapt_brighten_ev_per_second": manager.adapt_brighten_ev_per_second,
		"snap_ev_threshold": manager.snap_ev_threshold,
		"default_albedo": manager.default_albedo,
		"exposure_max_ev": manager.exposure_max_ev,
		"meter_transition_exponent": manager.meter_transition_exponent,
		"nightside_onset_lit_fraction": manager.nightside_onset_lit_fraction,
		"nightside_full_lit_fraction": manager.nightside_full_lit_fraction,
		"nightside_twilight_angle": manager.nightside_twilight_angle,
		"star_meter_fraction_start": manager.star_meter_fraction_start,
		"star_meter_fraction_full": manager.star_meter_fraction_full,
		"limb_meter_fraction_start": manager.limb_meter_fraction_start,
		"limb_meter_fraction_full": manager.limb_meter_fraction_full,
		"limb_meter_edge_fraction": manager.limb_meter_edge_fraction,
		"meter_edge_fraction": manager.meter_edge_fraction,
		"ambient_starlight_illuminance": manager.ambient_starlight_illuminance,
		"mag0_illuminance": IVPhotometry.MAG0_ILLUMINANCE,
		"sb0_luminance": IVPhotometry.SB0_LUMINANCE,
		"gain": IVExposureManager.gain,
		"sky_energy": IVExposureManager.sky_energy,
	}


# Hand-mirrors IVExposureManager._get_metering_target so tests can inspect
# per-candidate rows (lit/dark/star: screen fraction, weight, view factor,
# luminance, candidate exposure). Parent-shadow term omitted. Scaffolding
# only; keep in sync by hand.
func _get_metering_table() -> Dictionary:
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return {"_error": {"code": ERR_NOT_ALLOWED,
				"message": "No ExposureManager (enable_physical_light off?)"}}
	var manager: IVExposureManager = manager_var
	var camera := IVGlobal.get_viewport().get_camera_3d()
	var star: IVBody = IVBody.bodies.get(&"STAR_SUN")
	if !camera or !star:
		return {"_error": {"code": ERR_UNAVAILABLE, "message": "No camera or star"}}
	var magnitude_var: Variant = star.characteristics.get(&"absolute_magnitude")
	if typeof(magnitude_var) != TYPE_FLOAT:
		return {"_error": {"code": ERR_UNAVAILABLE, "message": "No star absolute_magnitude"}}
	var star_absolute_magnitude: float = magnitude_var
	var view_size := camera.get_viewport().get_visible_rect().size
	var tan_half_fov := tan(deg_to_rad(camera.fov) * 0.5)
	var aspect := view_size.x / view_size.y
	var fraction_per_theta_sq := PI / (4.0 * tan_half_fov * tan_half_fov * aspect)
	var star_position := star.global_position
	var camera_position := camera.global_position
	var gain := IVExposureManager.gain
	var rest_exposure := 2.0 ** manager.exposure_max_ev
	var log_rest := log(rest_exposure)
	var rows: Array[Dictionary] = []
	for body_name: StringName in IVBody.bodies:
		var body := IVBody.bodies[body_name]
		if !body.visible or body.mean_radius <= 0.0 or gain <= 0.0:
			continue
		var camera_vector := body.global_position - camera_position
		var camera_distance := camera_vector.length()
		if camera_distance <= 0.0:
			continue
		var angular_radius := minf(body.mean_radius / camera_distance, 1.0)
		var screen_fraction := fraction_per_theta_sq * angular_radius * angular_radius
		var view_factor := _view_factor(camera, manager, body.global_position, angular_radius,
				view_size, tan_half_fov, aspect)
		# The DISC's gate, and only its own candidates ride it; a ring or a shell reaching
		# outside the disc carries a gate of its own. Mirrors _get_metering_target().
		if view_factor <= 0.0 and !manager._wide_candidate_bodies.has(body.name):
			continue
		if (body.flags & IVBody.BodyFlags.BODYFLAGS_STAR) != 0:
			if body != star:
				continue
			screen_fraction *= IVSunOcclusionManager.camera_sun_visible_fraction
			var star_weight := view_factor * _ramp_weight(screen_fraction,
					manager.star_meter_fraction_start, manager.star_meter_fraction_full)
			if star_weight <= 0.0:
				continue
			var disc_luminance := IVPhotometry.get_star_disc_luminance(
					star_absolute_magnitude, body.mean_radius)
			rows.append({
				"name": String(body_name), "candidate": "star",
				"screen_fraction": screen_fraction, "weight": star_weight,
				"view_factor": view_factor, "luminance": disc_luminance,
				"candidate_exposure": _candidate_exposure(manager, disc_luminance,
						star_weight, log_rest, rest_exposure),
			})
			continue
		var star_vector := star_position - body.global_position
		var star_distance := star_vector.length()
		if star_distance <= 0.0:
			continue
		var phase_cos := -star_vector.dot(camera_vector) / (star_distance * camera_distance)
		var lit_visible := (1.0 + phase_cos) * 0.5
		var phase_angle := acos(clampf(phase_cos, -1.0, 1.0))
		var lit_visible_cutoff := PI / 2.0 + acos(clampf(
				body.mean_radius / camera_distance, 0.0, 1.0))
		var horizon_factor := 1.0 - smoothstep(
				lit_visible_cutoff - manager.nightside_twilight_angle,
				lit_visible_cutoff, phase_angle)
		lit_visible = clampf(lit_visible * horizon_factor, 0.0, 1.0)
		var albedo := manager.default_albedo
		# meter_albedo ahead of albedo, mirroring IVExposureManager._get_albedo(); this
		# table is a second copy of that math and reports the old number without it.
		for field: StringName in [&"meter_albedo", &"albedo"]:
			var albedo_var: Variant = body.characteristics.get(field)
			if typeof(albedo_var) != TYPE_FLOAT:
				continue
			var albedo_value: float = albedo_var
			if albedo_value > 0.0: # empty cell imports non-positive; mirror manager
				albedo = albedo_value
				break
		var apparent_magnitude := IVPhotometry.get_apparent_magnitude(
				star_absolute_magnitude, star_distance)
		var illuminance := IVPhotometry.get_illuminance_from_apparent_magnitude(
				apparent_magnitude)
		var lit_luminance := albedo * (illuminance
				+ manager.ambient_starlight_illuminance) / PI
		var dark_luminance := albedo * manager.ambient_starlight_illuminance / PI
		var lit_hold := _ramp_weight(lit_visible, manager.nightside_full_lit_fraction,
				manager.nightside_onset_lit_fraction)
		var candidates := [
			["lit", screen_fraction * lit_visible, lit_luminance, lit_hold],
			["dark", screen_fraction * (1.0 - lit_visible), dark_luminance, 1.0],
		]
		for candidate_var: Array in candidates:
			var tag: String = candidate_var[0]
			var candidate_fraction: float = candidate_var[1]
			var luminance: float = candidate_var[2]
			var hold: float = candidate_var[3]
			var weight: float = view_factor * hold * _ramp_weight(candidate_fraction,
					manager.meter_fraction_start, manager.meter_fraction_full)
			if weight <= 0.0 or luminance <= 0.0:
				continue
			rows.append({
				"name": String(body_name), "candidate": tag,
				"screen_fraction": candidate_fraction, "weight": weight,
				"view_factor": view_factor, "lit_visible": lit_visible,
				"horizon_factor": horizon_factor, "phase_cos": phase_cos, "albedo": albedo,
				"luminance": luminance,
				"candidate_exposure": _candidate_exposure(manager, luminance, weight,
						log_rest, rest_exposure),
			})
		var ring_row := _get_ring_row(manager, body, camera_vector, camera_distance,
				star_vector, star_distance, illuminance, fraction_per_theta_sq, view_size,
				log_rest, rest_exposure)
		if !ring_row.is_empty():
			rows.append(ring_row)
		for ceiling_row in _get_ceiling_rows(manager, camera, body, camera_distance,
				fraction_per_theta_sq, view_size, tan_half_fov, aspect, log_rest, rest_exposure):
			rows.append(ceiling_row)
		var limb_row := _get_limb_ceiling_row(manager, camera, body, camera_vector,
				camera_distance, star_vector, star_distance, fraction_per_theta_sq, view_size,
				log_rest, rest_exposure)
		if !limb_row.is_empty():
			rows.append(limb_row)
	return {
		"exposure": IVExposureManager.exposure,
		"rest_exposure": rest_exposure,
		"rows": rows,
	}


# Mirrors IVExposureManager._get_view_factor.
func _view_factor(camera: Camera3D, manager: IVExposureManager, global_position: Vector3,
		angular_radius: float, view_size: Vector2, tan_half_fov: float, aspect: float) -> float:
	if camera.is_position_behind(global_position):
		return 0.0
	var screen_position := camera.unproject_position(global_position)
	var radius_fraction_y := angular_radius / (2.0 * tan_half_fov)
	var radius_fraction_x := radius_fraction_y / aspect
	var position_x := screen_position.x / view_size.x
	var position_y := screen_position.y / view_size.y
	var penetration_x := minf(position_x, 1.0 - position_x) + radius_fraction_x
	var penetration_y := minf(position_y, 1.0 - position_y) + radius_fraction_y
	var penetration := minf(penetration_x, penetration_y)
	if penetration <= 0.0:
		return 0.0
	return smoothstep(0.0, maxf(manager.meter_edge_fraction, 1e-4), penetration)


# Mirrors IVExposureManager._get_ring_candidate_exposure (parent shadow omitted,
# like the body rows). Returns {} when the ring doesn't meter.
func _get_ring_row(manager: IVExposureManager, body: IVBody,
		camera_vector: Vector3, camera_distance: float, star_vector: Vector3,
		star_distance: float, illuminance: float, fraction_per_theta_sq: float,
		view_size: Vector2, log_rest: float, rest_exposure: float) -> Dictionary:
	var row := IVTableData.db_find_in_array(&"rings", &"bodies", body.name)
	if row == -1:
		return {}
	var inner_radius := IVTableData.get_db_float(&"rings", &"inner_radius", row)
	var outer_radius := IVTableData.get_db_float(&"rings", &"outer_radius", row)
	var back_phase := IVTableData.get_db_float(&"rings", &"back_phase", row)
	var forward_phase := IVTableData.get_db_float(&"rings", &"forward_phase", row)
	var forward_level := IVTableData.get_db_float(&"rings", &"forward_level", row)
	var opposition_surge := IVTableData.get_db_float(&"rings", &"opposition_surge", row)
	var opposition_width := IVTableData.get_db_float(&"rings", &"opposition_width", row)
	var clumping := IVTableData.get_db_float(&"rings", &"clumping", row)
	var axis := body.rotation_axis
	var sin_camera_elevation := -camera_vector.dot(axis) / camera_distance
	var sin_sun_elevation := star_vector.dot(axis) / star_distance
	var mu := absf(sin_camera_elevation)
	var mu0 := absf(sin_sun_elevation)
	var annulus_theta_sq := (outer_radius * outer_radius - inner_radius * inner_radius) \
			* mu / (camera_distance * camera_distance)
	var visible_fraction: float = manager._get_ring_visible_fraction(body,
			Vector2(inner_radius, outer_radius), camera_vector, camera_distance, view_size)
	var ring_fraction := fraction_per_theta_sq * annulus_theta_sq * visible_fraction
	var openness_hold := _ramp_weight(mu, manager.ring_meter_full_openness,
			manager.ring_meter_onset_openness)
	var ring_weight := openness_hold * _ramp_weight(ring_fraction,
			manager.meter_fraction_start, manager.meter_fraction_full)
	if ring_weight <= 0.0:
		return {}
	var lit_face := sin_camera_elevation * sin_sun_elevation > 0.0
	var geometry: float
	var ring_albedo: float
	if lit_face:
		geometry = mu0 / maxf(mu + mu0, 1e-6) # the slab term's saturated limit
		ring_albedo = manager.ring_meter_albedo
	else:
		geometry = manager._get_ring_transmission_peak(mu, mu0, clumping)
		ring_albedo = manager.ring_meter_unlit_albedo
	var to_sun := (star_vector + camera_vector).normalized()
	var phase := acos(clampf(to_sun.dot(-camera_vector / camera_distance), -1.0, 1.0))
	var phase_fraction := (phase - back_phase) / maxf(forward_phase - back_phase, 1e-4)
	var level := maxf(forward_level, 1e-6) ** phase_fraction
	level *= 1.0 + opposition_surge * exp(-phase / maxf(opposition_width, 1e-6))
	var ring_luminance := ring_albedo * geometry * level \
			* (illuminance + manager.ambient_starlight_illuminance) / PI
	if ring_luminance <= 0.0:
		return {}
	return {
		"name": String(body.name), "candidate": "rings",
		"screen_fraction": ring_fraction, "weight": ring_weight,
		"visible_fraction": visible_fraction, "openness_hold": openness_hold,
		"sin_camera_elevation": sin_camera_elevation,
		"sin_sun_elevation": sin_sun_elevation, "phase_deg": rad_to_deg(phase),
		"lit_face": lit_face, "slab_geometry": geometry,
		"phase_level": level, "luminance": ring_luminance,
		"candidate_exposure": _candidate_exposure(manager, ring_luminance, ring_weight,
				log_rest, rest_exposure),
	}



# Mirrors IVExposureManager._get_ceiling_candidate_exposure: one row per shell of this body
# that asserts an exposure_ceiling in shells.tsv.
func _get_ceiling_rows(manager: IVExposureManager, camera: Camera3D, body: IVBody,
		camera_distance: float, fraction_per_theta_sq: float, view_size: Vector2,
		tan_half_fov: float, aspect: float, log_rest: float,
		rest_exposure: float) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var ceilings: Array = manager._exposure_ceilings.get(body.name, [])
	for shell: Vector2 in ceilings:
		var angular_radius := minf(shell.x / camera_distance, 1.0)
		var shell_fraction := fraction_per_theta_sq * angular_radius * angular_radius
		var view_factor := _view_factor(camera, manager, body.global_position, angular_radius,
				view_size, tan_half_fov, aspect)
		var weight := view_factor * _ramp_weight(shell_fraction, manager.meter_fraction_start,
				manager.meter_fraction_full)
		if weight <= 0.0:
			continue
		var shaped := 1.0 - (1.0 - weight) ** manager.meter_transition_exponent
		rows.append({
			"name": String(body.name), "candidate": "ceiling",
			"screen_fraction": shell_fraction, "weight": weight, "view_factor": view_factor,
			"shell_radius_km": shell.x / IVUnits.KM, "ceiling": shell.y,
			"candidate_exposure": exp(lerpf(log_rest, log(minf(shell.y, rest_exposure)), shaped)),
		})
	return rows


# Mirrors IVExposureManager._get_limb_ceiling_candidate_exposure: the lit, in-frame share of
# the limb sampled at the disc's silhouette (its foot), and what it holds of that shell's
# limb_exposure_ceiling.
func _get_limb_ceiling_row(manager: IVExposureManager, camera: Camera3D, body: IVBody,
		camera_vector: Vector3, camera_distance: float, star_vector: Vector3,
		star_distance: float, fraction_per_theta_sq: float, view_size: Vector2,
		log_rest: float, rest_exposure: float) -> Dictionary:
	const RING_SAMPLES := 32
	if !manager._limb_ceilings.has(body.name):
		return {}
	var ceiling: float = manager._limb_ceilings[body.name]
	var limb: Vector2 = manager._limb_geometry[body.name]
	var disc_radius := limb.x
	var shell_radius := limb.y
	var limb_height := shell_radius - disc_radius
	if limb_height <= 0.0 or camera_distance <= disc_radius:
		return {}
	var camera_position := body.global_position - camera_vector
	var to_camera := -camera_vector / camera_distance
	var to_star := star_vector / star_distance
	var ring_radius := disc_radius * sqrt(maxf(1.0 - disc_radius * disc_radius
			/ (camera_distance * camera_distance), 0.0))
	var ring_center := body.global_position + to_camera * (disc_radius * disc_radius
			/ camera_distance)
	var sunward_axis := to_star - to_camera * to_star.dot(to_camera)
	if sunward_axis.length_squared() < 1e-12:
		sunward_axis = to_camera.cross(Vector3.UP if absf(to_camera.y) < 0.9 else Vector3.RIGHT)
	sunward_axis = sunward_axis.normalized()
	var crosswise_axis := to_camera.cross(sunward_axis)
	var lit_samples := 0.0
	var visible_lit := 0.0
	for i in RING_SAMPLES:
		var azimuth := TAU * (i + 0.5) / RING_SAMPLES
		var point := ring_center + (sunward_axis * cos(azimuth)
				+ crosswise_axis * sin(azimuth)) * ring_radius
		var solar_cosine := (point - body.global_position).dot(to_star) / disc_radius
		var lit := 1.0
		if solar_cosine < 0.0:
			var sin_zenith := sqrt(maxf(1.0 - solar_cosine * solar_cosine, 1e-12))
			lit = clampf((shell_radius - disc_radius / sin_zenith) / limb_height, 0.0, 1.0)
		var to_viewer := (camera_position - point).normalized()
		lit *= maxf(-to_star.dot(to_viewer), 0.0)
		if lit <= 0.0:
			continue
		lit_samples += lit
		if camera.is_position_behind(point):
			continue
		var screen_position := camera.unproject_position(point)
		var position_x := screen_position.x / view_size.x
		var position_y := screen_position.y / view_size.y
		var penetration := minf(minf(position_x, 1.0 - position_x),
				minf(position_y, 1.0 - position_y))
		if penetration <= 0.0:
			continue
		visible_lit += lit * smoothstep(0.0, maxf(manager.limb_meter_edge_fraction, 1e-4),
				penetration)
	var angular_radius := minf(shell_radius / camera_distance, 1.0)
	var ring_fraction := fraction_per_theta_sq * angular_radius * angular_radius
	var limb_fraction := ring_fraction * visible_lit / RING_SAMPLES
	var weight := _ramp_weight(limb_fraction, manager.limb_meter_fraction_start,
			manager.limb_meter_fraction_full)
	var shaped := 1.0 - (1.0 - weight) ** manager.meter_transition_exponent
	return {
		"name": String(body.name), "candidate": "limb_ceiling",
		"screen_fraction": limb_fraction, "weight": weight,
		"lit_ring_fraction": lit_samples / RING_SAMPLES,
		"visible_lit_ring_fraction": visible_lit / RING_SAMPLES,
		"shell_radius_km": shell_radius / IVUnits.KM, "ceiling": ceiling,
		"candidate_exposure": exp(lerpf(log_rest, log(minf(ceiling, rest_exposure)), shaped)),
	}


func _ramp_weight(screen_fraction: float, fraction_start: float, fraction_full: float) -> float:
	if screen_fraction <= fraction_start:
		return 0.0
	var log_span := log(fraction_full / fraction_start)
	if log_span <= 0.0:
		return 1.0
	return smoothstep(0.0, 1.0, log(screen_fraction / fraction_start) / log_span)


func _candidate_exposure(manager: IVExposureManager, luminance: float, weight: float,
		log_rest: float, rest_exposure: float) -> float:
	var full_exposure := minf(manager.metering_key / (luminance * IVExposureManager.gain),
			rest_exposure)
	var shaped_weight := 1.0 - (1.0 - weight) ** manager.meter_transition_exponent
	return exp(lerpf(log_rest, log(full_exposure), shaped_weight))


func _set_physical_light(params: Dictionary) -> Variant:
	var enabled_var: Variant = params.get("enabled")
	if typeof(enabled_var) != TYPE_BOOL:
		return {"_error": {"code": ERR_INVALID_PARAMS,
				"message": "Missing or invalid 'enabled' parameter"}}
	var enabled: bool = enabled_var
	IVSettingsManager.change_setting(&"physical_light", enabled)
	return {"ok": true, "enabled": enabled}


# Reports whether each visible body's visual actually receives the analytic sun
# occlusion (IVSunOcclusionManager registers a ShaderMaterial only when it is a
# surface override declaring occluder_data_a), alongside the light layer that
# lights it and the CPU parent-shadow fraction the exposure manager meters with.
func _get_shadow_receivers() -> Dictionary:
	var star: IVBody = IVBody.bodies.get(&"STAR_SUN")
	var rows: Array[Dictionary] = []
	for body_name: StringName in IVBody.bodies:
		var body := IVBody.bodies[body_name]
		if !body.visible or !body.body_visual:
			continue
		var counts := _count_materials(body.body_visual)
		rows.append({
			"name": String(body_name),
			"mean_radius_km": body.mean_radius / IVUnits.KM,
			"mesh_instances": counts[0],
			"override_shader_materials": counts[1],
			"occlusion_opt_ins": counts[2],
			"material_classes": counts[3],
			"layers": counts[4],
			"parent_shadow_fraction": _parent_shadow_fraction(body, star),
		})
	return {"exposure": IVExposureManager.exposure, "rows": rows}


func _count_materials(node: Node) -> Array:
	var mesh_instances := 0
	var override_shader_materials := 0
	var occlusion_opt_ins := 0
	var material_classes: Array[String] = []
	var layers := 0
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = child
		mesh_instances += 1
		layers |= mesh_instance.layers
		var material: Material = mesh_instance.get_surface_override_material(0)
		var from_mesh := false
		if !material:
			var mesh := mesh_instance.mesh
			if mesh and mesh.get_surface_count() > 0:
				material = mesh.surface_get_material(0)
				from_mesh = true
		if !material:
			material_classes.append("<none>")
			continue
		material_classes.append(material.get_class() + ("@mesh" if from_mesh else "@override"))
		var shader_material := material as ShaderMaterial
		if !shader_material or !shader_material.shader:
			continue
		if !from_mesh:
			override_shader_materials += 1
		for uniform: Dictionary in shader_material.shader.get_shader_uniform_list():
			if uniform[&"name"] == "occluder_data_a":
				if !from_mesh:
					occlusion_opt_ins += 1
				break
	return [mesh_instances, override_shader_materials, occlusion_opt_ins, material_classes, layers]


# Mirrors IVExposureManager._get_parent_shadow_fraction.
func _parent_shadow_fraction(body: IVBody, star: IVBody) -> float:
	if !star:
		return 1.0
	var parent := body.get_parent() as IVBody
	if !parent or parent == star:
		return 1.0
	var star_vector := star.global_position - body.global_position
	var star_distance := star_vector.length()
	var parent_vector := parent.global_position - body.global_position
	var parent_distance := parent_vector.length()
	if parent_distance <= 0.0 or parent.mean_radius <= 0.0 or star_distance <= 0.0:
		return 1.0
	var star_angular_radius := star.mean_radius / star_distance
	var parent_angular_radius := parent.mean_radius / parent_distance
	var cos_separation := star_vector.dot(parent_vector) / (star_distance * parent_distance)
	var separation := acos(clampf(cos_separation, -1.0, 1.0))
	return IVSunOcclusionManager.get_two_disc_visible_fraction(star_angular_radius,
			parent_angular_radius, separation)


# Per-sample breakdown of the limb ring for one body: what each azimuth sample's solar
# zenith, lit measure and frame penetration are, so a steep or early transition can be
# attributed to a sample rather than inferred from the total.
func _get_limb_samples(params: Dictionary) -> Variant:
	const RING_SAMPLES := 32
	const SHADOW_SOFTNESS := 0.05
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return {"_error": {"code": ERR_NOT_ALLOWED, "message": "no ExposureManager"}}
	var manager: IVExposureManager = manager_var
	var name_string: String = params.get("name", "MOON_TITAN")
	var body_name := StringName(name_string)
	if !manager._limb_ceilings.has(body_name) or !IVBody.bodies.has(body_name):
		return {"_error": {"code": ERR_DOES_NOT_EXIST, "message": "no limb row for %s" % body_name}}
	var body: IVBody = IVBody.bodies[body_name]
	var camera := IVGlobal.get_viewport().get_camera_3d()
	var star: IVBody = IVBody.bodies[&"STAR_SUN"]
	var view_size := camera.get_viewport().get_visible_rect().size
	var camera_vector := body.global_position - camera.global_position
	var camera_distance := camera_vector.length()
	var star_vector := star.global_position - body.global_position
	var star_distance := star_vector.length()
	var limb: Vector2 = manager._limb_geometry[body_name]
	var disc_radius := limb.x
	var shell_radius := limb.y
	var to_camera := -camera_vector / camera_distance
	var to_star := star_vector / star_distance
	var ring_radius := disc_radius * sqrt(maxf(1.0 - disc_radius * disc_radius
			/ (camera_distance * camera_distance), 0.0))
	var ring_center := body.global_position + to_camera * (disc_radius * disc_radius
			/ camera_distance)
	var sunward_axis := to_star - to_camera * to_star.dot(to_camera)
	if sunward_axis.length_squared() < 1e-12:
		sunward_axis = to_camera.cross(Vector3.UP if absf(to_camera.y) < 0.9 else Vector3.RIGHT)
	sunward_axis = sunward_axis.normalized()
	var crosswise_axis := to_camera.cross(sunward_axis)
	# What the retired test asked: one point at the SHELL radius, in or out of the cylinder.
	var shadow_cosine := -sqrt(maxf(1.0 - disc_radius * disc_radius
			/ (shell_radius * shell_radius), 0.0))
	var samples: Array = []
	for i in RING_SAMPLES:
		var azimuth := TAU * (i + 0.5) / RING_SAMPLES
		var point := ring_center + (sunward_axis * cos(azimuth)
				+ crosswise_axis * sin(azimuth)) * ring_radius
		var solar_cosine := (point - body.global_position).dot(to_star) / disc_radius
		var lit := smoothstep(shadow_cosine - SHADOW_SOFTNESS,
				shadow_cosine + SHADOW_SOFTNESS, solar_cosine)
		# What it asks now: how much of the limb's height above this foot stands above the
		# shadow (1 at the terminator, 0 where the shadow tops the shell).
		var graded := 1.0
		if solar_cosine < 0.0:
			var sin_zenith := sqrt(maxf(1.0 - solar_cosine * solar_cosine, 1e-12))
			var shadow_radius := disc_radius / sin_zenith
			graded = clampf((shell_radius - shadow_radius) / maxf(shell_radius - disc_radius,
					1e-12), 0.0, 1.0)
		var to_viewer := ((body.global_position - camera_vector) - point).normalized()
		var forward := maxf(-to_star.dot(to_viewer), 0.0)
		var behind := camera.is_position_behind(point)
		var screen_position := Vector2.ZERO
		var penetration := -1.0
		if !behind:
			screen_position = camera.unproject_position(point)
			penetration = minf(minf(screen_position.x / view_size.x,
					1.0 - screen_position.x / view_size.x),
					minf(screen_position.y / view_size.y, 1.0 - screen_position.y / view_size.y))
		samples.append({
			"i": i, "azimuth_deg": rad_to_deg(azimuth),
			"solar_zenith_deg": rad_to_deg(acos(clampf(solar_cosine, -1.0, 1.0))),
			"lit": lit, "graded": graded, "forward": forward,
			"credit": graded * forward, "behind": behind,
			"screen_x": screen_position.x / view_size.x,
			"screen_y": screen_position.y / view_size.y,
			"penetration": penetration,
			"edge_weight": 0.0 if penetration <= 0.0 else smoothstep(0.0,
					maxf(manager.limb_meter_edge_fraction, 1e-4), penetration),
		})
	return {
		"body": String(body_name), "camera_distance_km": camera_distance / IVUnits.KM,
		"disc_radius_km": disc_radius / IVUnits.KM,
		"shell_radius_km": shell_radius / IVUnits.KM,
		"ring_radius_km": ring_radius / IVUnits.KM,
		"shadow_cutoff_zenith_deg": rad_to_deg(acos(clampf(shadow_cosine, -1.0, 1.0))),
		"phase_deg": rad_to_deg(acos(clampf(-star_vector.dot(camera_vector)
				/ (star_distance * camera_distance), -1.0, 1.0))),
		"samples": samples,
	}


# The assistant's apply_view reaches table views only; a view the maintainer saved in the app
# lives in IVViewManager.cached_views, keyed "<name>.<collection>".
func _list_saved_views() -> Variant:
	var manager_var: Variant = IVGlobal.program.get(&"ViewManager")
	if not manager_var is IVViewManager:
		return {"_error": {"code": ERR_NOT_ALLOWED, "message": "no ViewManager"}}
	var manager: IVViewManager = manager_var
	var keys: Array = []
	for key: StringName in manager.cached_views:
		keys.append(String(key))
	return {"cached": keys}


func _apply_saved_view(params: Dictionary) -> Variant:
	var manager_var: Variant = IVGlobal.program.get(&"ViewManager")
	if not manager_var is IVViewManager:
		return {"_error": {"code": ERR_NOT_ALLOWED, "message": "no ViewManager"}}
	var manager: IVViewManager = manager_var
	var view_name: String = params.get("name", "")
	var collection: String = params.get("collection", "view_cacher")
	if !manager.has_view(view_name, collection, true):
		return {"_error": {"code": ERR_DOES_NOT_EXIST,
				"message": "no cached view '%s.%s'" % [view_name, collection]}}
	manager.set_view(view_name, collection, true, true)
	return {"ok": true, "name": view_name, "collection": collection}


# Where a body's silhouette at some altitude above its disc lands on screen. A sphere seen off
# axis silhouettes as an ELLIPSE, so a circle fit to the projected points is meaningless there
# (measured: 1079 px of residual at 45 deg of yaw) -- this asks the engine's own camera instead,
# which holds at any orientation and is what makes a limb profile measurable at the camera floor.
func _project_limb_circle(params: Dictionary) -> Variant:
	var name_string: String = params.get("name", "MOON_TITAN")
	var body_name := StringName(name_string)
	if !IVBody.bodies.has(body_name):
		return {"_error": {"code": ERR_DOES_NOT_EXIST, "message": "no body %s" % body_name}}
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return {"_error": {"code": ERR_NOT_ALLOWED, "message": "no ExposureManager"}}
	var manager: IVExposureManager = manager_var
	if !manager._limb_geometry.has(body_name):
		return {"_error": {"code": ERR_DOES_NOT_EXIST, "message": "no limb row for %s" % body_name}}
	var body: IVBody = IVBody.bodies[body_name]
	var camera := IVGlobal.get_viewport().get_camera_3d()
	var view_size := camera.get_viewport().get_visible_rect().size
	var altitude: float = params.get("altitude_km", 0.0) * IVUnits.KM
	var count: int = params.get("samples", 64)
	var limb: Vector2 = manager._limb_geometry[body_name]
	var radius := limb.x + altitude
	var camera_vector := body.global_position - camera.global_position
	var camera_distance := camera_vector.length()
	if radius >= camera_distance:
		return {"_error": {"code": ERR_INVALID_PARAMETER, "message": "radius exceeds distance"}}
	var to_camera := -camera_vector / camera_distance
	var star: IVBody = IVBody.bodies[&"STAR_SUN"]
	var to_star := (star.global_position - body.global_position).normalized()
	var ring_radius := radius * sqrt(maxf(1.0 - radius * radius
			/ (camera_distance * camera_distance), 0.0))
	var ring_center := body.global_position + to_camera * (radius * radius / camera_distance)
	var sunward_axis := to_star - to_camera * to_star.dot(to_camera)
	if sunward_axis.length_squared() < 1e-12:
		sunward_axis = to_camera.cross(Vector3.UP if absf(to_camera.y) < 0.9 else Vector3.RIGHT)
	sunward_axis = sunward_axis.normalized()
	var crosswise_axis := to_camera.cross(sunward_axis)
	var points: Array = []
	for i in count:
		var azimuth := TAU * (i + 0.5) / count
		var point := ring_center + (sunward_axis * cos(azimuth)
				+ crosswise_axis * sin(azimuth)) * ring_radius
		var behind := camera.is_position_behind(point)
		var screen_position := Vector2.ZERO if behind else camera.unproject_position(point)
		points.append({
			"azimuth_deg": rad_to_deg(azimuth), "behind": behind,
			"solar_zenith_deg": rad_to_deg(acos(clampf(
					(point - body.global_position).dot(to_star) / radius, -1.0, 1.0))),
			"screen_x": screen_position.x / view_size.x,
			"screen_y": screen_position.y / view_size.y,
		})
	return {
		"body": String(body_name), "altitude_km": altitude / IVUnits.KM,
		"disc_radius_km": limb.x / IVUnits.KM, "shell_radius_km": limb.y / IVUnits.KM,
		"camera_distance_km": camera_distance / IVUnits.KM,
		"view_size": [view_size.x, view_size.y], "points": points,
	}


# Runtime override of the limb ramp, so a to-taste value can be swept in one app run rather
# than one run per candidate.
func _set_ring_meter(params: Dictionary) -> Variant:
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return {"_error": {"code": ERR_NOT_ALLOWED, "message": "no ExposureManager"}}
	var manager: IVExposureManager = manager_var
	if params.has("onset"):
		var onset: float = params["onset"]
		manager.ring_meter_onset_openness = onset
	if params.has("full"):
		var full: float = params["full"]
		manager.ring_meter_full_openness = full
	return {
		"ring_meter_onset_openness": manager.ring_meter_onset_openness,
		"ring_meter_full_openness": manager.ring_meter_full_openness,
	}


func _set_exposure(params: Dictionary) -> Variant:
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return {"_error": {"code": ERR_NOT_ALLOWED, "message": "no ExposureManager"}}
	var manager: IVExposureManager = manager_var
	if params.has("manual_ev"):
		var manual_ev: float = params["manual_ev"]
		manager.manual_exposure_ev = manual_ev
	if params.has("auto"):
		var auto: bool = params["auto"]
		manager.auto = auto
	return {
		"auto": manager.auto,
		"manual_exposure_ev": manager.manual_exposure_ev,
		"auto_exposure_ev": IVExposureManager.auto_exposure_ev,
		"exposure_adjustment_ev": manager.exposure_adjustment_ev,
		"exposure": IVExposureManager.exposure,
	}


func _set_limb_meter(params: Dictionary) -> Variant:
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return {"_error": {"code": ERR_NOT_ALLOWED, "message": "no ExposureManager"}}
	var manager: IVExposureManager = manager_var
	if params.has("start"):
		var start: float = params["start"]
		manager.limb_meter_fraction_start = start
	if params.has("full"):
		var full: float = params["full"]
		manager.limb_meter_fraction_full = full
	if params.has("edge"):
		var edge: float = params["edge"]
		manager.limb_meter_edge_fraction = edge
	return {
		"limb_meter_fraction_start": manager.limb_meter_fraction_start,
		"limb_meter_fraction_full": manager.limb_meter_fraction_full,
		"limb_meter_edge_fraction": manager.limb_meter_edge_fraction,
	}


func _set_glow(params: Dictionary) -> Variant:
	if !_world_environment or !_world_environment.environment:
		return {"_error": {"code": ERR_UNAVAILABLE, "message": "No WorldEnvironment"}}
	var environment := _world_environment.environment
	var enabled_var: Variant = params.get("enabled")
	if enabled_var != null:
		if typeof(enabled_var) != TYPE_BOOL:
			return {"_error": {"code": ERR_INVALID_PARAMS, "message": "'enabled' must be a bool"}}
		environment.glow_enabled = enabled_var
	var floats: Dictionary[String, StringName] = {
		"intensity": &"glow_intensity",
		"strength": &"glow_strength",
		"bloom": &"glow_bloom",
		"mix": &"glow_mix",
		"hdr_threshold": &"glow_hdr_threshold",
		"hdr_scale": &"glow_hdr_scale",
		"hdr_luminance_cap": &"glow_hdr_luminance_cap",
	}
	for key: String in floats:
		var value_var: Variant = params.get(key)
		if value_var == null:
			continue
		if typeof(value_var) != TYPE_FLOAT and typeof(value_var) != TYPE_INT:
			return {"_error": {"code": ERR_INVALID_PARAMS,
					"message": "'%s' must be a number" % key}}
		var value: float = value_var
		environment.set(floats[key], value)
	var blend_var: Variant = params.get("blend_mode")
	if blend_var != null:
		if typeof(blend_var) != TYPE_INT:
			return {"_error": {"code": ERR_INVALID_PARAMS, "message": "'blend_mode' must be an int"}}
		environment.glow_blend_mode = blend_var
	var levels_var: Variant = params.get("levels")
	if levels_var != null:
		if typeof(levels_var) != TYPE_ARRAY:
			return {"_error": {"code": ERR_INVALID_PARAMS,
					"message": "'levels' must be an array of 7 numbers"}}
		var levels: Array = levels_var
		if levels.size() != 7:
			return {"_error": {"code": ERR_INVALID_PARAMS,
					"message": "'levels' must have 7 entries"}}
		var new_levels: Array[float] = []
		for i in 7:
			var level_var: Variant = levels[i]
			if typeof(level_var) != TYPE_FLOAT and typeof(level_var) != TYPE_INT:
				return {"_error": {"code": ERR_INVALID_PARAMS,
						"message": "'levels' entries must be numbers"}}
			var level: float = level_var
			new_levels.append(level)
		# IVWorldEnvironment shifts its authored levels by render height and would overwrite a
		# direct write the next time the height changed.
		if _world_environment is IVWorldEnvironment:
			var iv_world_environment: IVWorldEnvironment = _world_environment
			iv_world_environment.set_glow_levels(new_levels)
		else:
			# Environment's own index is 0-based (MAX_GLOW_LEVELS = 7), where the inspector
			# labels the same levels 1-7; i + 1 here errored on the last one and skipped the
			# first.
			for i in 7:
				environment.set_glow_level(i, new_levels[i])
	var reported_levels := []
	for i in 7:
		reported_levels.append(environment.get_glow_level(i))
	var authored_levels: Array = reported_levels
	if _world_environment is IVWorldEnvironment:
		var iv_world_environment: IVWorldEnvironment = _world_environment
		authored_levels = iv_world_environment.get_glow_levels()
	return {
		"ok": true,
		"enabled": environment.glow_enabled,
		"intensity": environment.glow_intensity,
		"strength": environment.glow_strength,
		"bloom": environment.glow_bloom,
		"mix": environment.glow_mix,
		"hdr_threshold": environment.glow_hdr_threshold,
		"hdr_scale": environment.glow_hdr_scale,
		"hdr_luminance_cap": environment.glow_hdr_luminance_cap,
		"blend_mode": environment.glow_blend_mode,
		"levels": reported_levels,
		"authored_levels": authored_levels,
	}


func _set_psf_settings(params: Dictionary) -> Variant:
	var psf_settings: IVPSFSettings = IVGlobal.program.get(&"PSFSettings")
	if !psf_settings:
		return {"_error": {"code": ERR_UNAVAILABLE, "message": "No PSFSettings"}}
	var names: Array[StringName] = [&"psf_sigma", &"intensity_faint_mag", &"intensity_gamma",
			&"intensity_scale", &"color_saturation", &"fov_reference_deg", &"fov_compensation",
			&"glare_scale", &"glare_gamma", &"glare_max_px"]
	for name in names:
		var value_var: Variant = params.get(String(name))
		if value_var == null:
			continue
		if typeof(value_var) != TYPE_FLOAT and typeof(value_var) != TYPE_INT:
			return {"_error": {"code": ERR_INVALID_PARAMS,
					"message": "'%s' must be a number" % name}}
		var value: float = value_var
		psf_settings.set(name, value)
	var report := {"ok": true}
	for name in names:
		report[String(name)] = psf_settings.get(name)
	return report


# What IVWorldEnvironment and IVStarsVisual are currently NOT drawing because the
# compensating camera has metered it below one display code, plus the per-bin numbers the
# cull decides on. Reads their private members on purpose: a probe exists to reach what the
# public API does not expose, and a rename in Core breaks this and nothing else reports it.
func _get_exposure_skips() -> Variant:
	var sky := {}
	if _world_environment is IVWorldEnvironment:
		var world_environment: IVWorldEnvironment = _world_environment
		sky = {
			"enabled": world_environment.skip_invisible_starmap,
			"skipped": world_environment._starmap_skipped,
			"background_mode": world_environment.environment.background_mode,
		}
	var stars := {}
	if _stars_visual:
		var bins := []
		var i := 0
		var n_bins := _stars_visual.get_bin_count()
		while i < n_bins:
			var bin_visual := _stars_visual._bin_visuals[i]
			bins.append({
				"name": String(bin_visual.name),
				"stars": _stars_visual._bin_star_counts[i],
				"brightest_magnitude": _stars_visual._bin_brightest_magnitudes[i],
				"peak_density_per_steradian": _stars_visual._bin_peak_densities[i],
				"visible": bin_visual.visible,
			})
			i += 1
		stars = {
			"enabled": _stars_visual.cull_invisible_bins,
			"drawn_bins": _stars_visual.get_drawn_bin_count(),
			"capture_render_height": IVStarsVisual.capture_render_height,
			"bins": bins,
		}
	return {
		"one_display_code_linear": IVPhotometry.ONE_DISPLAY_CODE_LINEAR,
		"exposure": IVExposureManager.exposure,
		"physical_active": IVExposureManager.physical_active,
		"sky": sky,
		"stars": stars,
	}


func _set_exposure_skips(params: Dictionary) -> Variant:
	var sky_var: Variant = params.get("sky")
	if typeof(sky_var) == TYPE_BOOL:
		if not _world_environment is IVWorldEnvironment:
			return {"_error": {"code": ERR_UNAVAILABLE, "message": "No IVWorldEnvironment"}}
		var world_environment: IVWorldEnvironment = _world_environment
		var sky_enabled: bool = sky_var
		world_environment.skip_invisible_starmap = sky_enabled
	var stars_var: Variant = params.get("stars")
	if typeof(stars_var) == TYPE_BOOL:
		if !_stars_visual:
			return {"_error": {"code": ERR_UNAVAILABLE, "message": "No IVStarsVisual"}}
		var stars_enabled: bool = stars_var
		_stars_visual.cull_invisible_bins = stars_enabled
	# Standing in for IVScreenshotManager, which sets this around an off-screen capture and
	# clears it after -- a window is the only render height a driver can otherwise reach.
	var capture_var: Variant = params.get("capture_height")
	if typeof(capture_var) == TYPE_FLOAT:
		var capture_height: float = capture_var
		IVStarsVisual.capture_render_height = capture_height
	return _get_exposure_skips()


func _get_shadow_skips() -> Variant:
	const KM := IVUnits.KM
	var lights := []
	for light in _lights:
		lights.append({
			"name": String(light.name),
			"shadow_capable": light._shadow_capable,
			"skip_enabled": light._skip_empty_shadow_passes,
			"shadow_enabled": light.shadow_enabled,
			"reach_km": light.directional_shadow_max_distance / KM,
			"light_cull_mask": light.light_cull_mask,
			"idle_shadow_frames": light._idle_shadow_frames,
			"shared": light._shared.duplicate(),
		})
	var camera := IVGlobal.get_tree().root.get_camera_3d()
	var participants := []
	for node3d: Node3D in IVDynamicLight._local_shadow_layers:
		var extent_radius: float = IVDynamicLight._local_shadow_radii[node3d]
		var distance := INF
		if camera:
			distance = (node3d.global_position - camera.global_position).length() - extent_radius
		participants.append({
			"name": String(node3d.get_parent().name) if node3d.get_parent() else String(node3d.name),
			"visual_layers": IVDynamicLight._local_shadow_layers[node3d],
			"visible": node3d.is_visible_in_tree(),
			"surface_distance_km": distance / KM,
		})
	return {
		"setting": IVCoreSettings.apply_empty_shadow_pass_skip,
		"participants": participants,
		"farwarp_start_km": IVFarwarpManager.farwarp_start / KM,
		"lights": lights,
	}


func _set_shadow_skips(params: Dictionary) -> Variant:
	var enabled_var: Variant = params.get("enabled")
	if typeof(enabled_var) == TYPE_BOOL:
		var enabled: bool = enabled_var
		for light in _lights:
			light._skip_empty_shadow_passes = enabled and light._process_shadow_distances
			if !enabled:
				light.shadow_enabled = light._shadow_capable
				light._idle_shadow_frames = 0
	return _get_shadow_skips()
