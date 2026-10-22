# exposure_probe.gd
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
class_name ExposureProbe
extends RefCounted

## Probes and levers for measuring the physical-light chain in a running simulator.
##
## Reports [IVExposureManager] state, derived photometry and the per-body metering
## table, and drives the levers a photometric investigation needs: a shell's visibility
## and its shader parameters, a body's exposure ceilings, the limb ring's per-sample
## breakdown, and the engine's own unprojection of a limb circle.[br][br]
##
## A measuring instrument rather than a test -- nothing here asserts. Its callers are
## Python drivers in the private assets build tree, which call these members through the
## [code]ivoyager_assistant[/code] plugin's [code]call[/code], addressing this object by
## its role, "ExposureProbe" ([code]ivoyager_override2.cfg[/code] adds it to the program).
## What they measure is written up there and in
## [code]addons/ivoyager_core/PHOTOMETRIC_MODEL.md[/code]. That document's TODO list is
## the standing reason this probe is here.[br][br]
##
## Every member waits for the simulator to start. An argument a member says it keeps when
## null may be omitted. A member given something it can't act on, such as a body that
## doesn't exist, answers with an error rather than a result.[br][br]
##
## It reads private members of [IVExposureManager] and [IVShellsModel] -- deliberately,
## since a probe exists to reach what the public API does not expose, but a rename in Core
## breaks it here and nothing else will report it.[br][br]
##
## It lives in this project because the work driving it does, not because it is
## Planetarium-specific. Whether to code it for general use is open -- another project
## needing an asset pipeline would want this rather than its own copy.

const AUTOMATION_METHODS: Array[StringName] = [
	&"get_exposure_state",
	&"get_photometry",
	&"get_metering_table",
	&"get_rings_geometry",
	&"get_ring_frame",
	&"get_body_debug",
	&"list_lights",
	&"get_shadow_receivers",
	&"get_limb_samples",
	&"project_limb_circle",
	&"get_render_time",
	&"get_exposure_skips",
	&"get_shadow_skips",
	&"set_exposure",
	&"set_limb_meter",
	&"set_ring_meter",
	&"set_physical_light",
	&"set_ambient_energy",
	&"set_reflected_light",
	&"poke_sky_radiance",
	&"set_exposure_ceiling",
	&"set_shell_visible",
	&"set_shell_param",
	&"set_rings",
	&"set_glow",
	&"set_psf_settings",
	&"set_exposure_skips",
	&"set_shadow_skips",
]

# The Assistant's error codes (its SPECIFICATION.md section 3.3).
const ERR_INVALID_PARAMS := 2
const ERR_NOT_FOUND := 3
const ERR_NOT_ALLOWED := 5


## Whether an automation client may use [param _member] now: every member waits for the
## simulator to start.
func is_automation_available(_member: StringName) -> bool:
	return IVStateManager.started


## Exposure statics, light energies and the managed scene values.
func get_exposure_state() -> Dictionary:
	var sun_disc_material := _find_sun_disc_material()
	var light_names: Array[String] = []
	var light_energies: Array[float] = []
	for light in _get_lights():
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
	var environment := _get_environment()
	if environment:
		result["ambient_light_energy"] = environment.ambient_light_energy
		result["tonemap_exposure"] = environment.tonemap_exposure
	if sun_disc_material:
		var brightness_var: Variant = sun_disc_material.get_shader_parameter(&"brightness")
		result["sun_disc_brightness"] = brightness_var
		result["sun_handoff_low"] = sun_disc_material.get_shader_parameter(&"handoff_low")
		result["sun_handoff_high"] = sun_disc_material.get_shader_parameter(&"handoff_high")
	return result


## The exposure manager's tuning members and the derived calibration.
func get_photometry() -> Dictionary:
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return _error(ERR_NOT_ALLOWED, "No ExposureManager (enable_physical_light off?)")
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


## Per-body metering rows: each candidate (lit, dark, star, rings, ceiling, limb_ceiling)
## with its screen fraction, weight, view factor, luminance and candidate exposure. Mirrors
## the exposure manager's own math, without its parent-shadow term.
func get_metering_table() -> Dictionary:
	# A hand-kept copy of IVExposureManager._get_metering_target; keep it in sync.
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return _error(ERR_NOT_ALLOWED, "No ExposureManager (enable_physical_light off?)")
	var manager: IVExposureManager = manager_var
	var camera := IVGlobal.get_viewport().get_camera_3d()
	var star: IVBody = IVBody.bodies.get(&"STAR_SUN")
	if !camera or !star:
		return _error(ERR_NOT_FOUND, "No camera or star")
	var magnitude_var: Variant = star.characteristics.get(&"absolute_magnitude")
	if typeof(magnitude_var) != TYPE_FLOAT:
		return _error(ERR_NOT_FOUND, "No star absolute_magnitude")
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


## Each ring system's camera and sun elevation above its PLANE, and the phase angle. A
## caller outside the app cannot derive these -- IVCamera's view_position latitude is an
## ECLIPTIC latitude, and a ring plane sits at the body's own obliquity to that, so posing
## by latitude sweeps an axis that is neither of them (measured: camera latitude -26 deg
## put Saturn's rings edge-on and latitude 0 left them 26 deg open). This reports what the
## renderer itself uses, so a rig can solve for the elevation it wants.[br][br]
##
## Elevations are signed against the SAME plane normal, so camera_elevation and
## sun_elevation sharing a sign means the camera sees the lit face.
func get_rings_geometry() -> Dictionary:
	# IVRings flips its own node to keep +y sunward, so the node basis cannot be read for
	# the sign -- the normal here is taken before that flip by keying on the sun.
	var camera := IVGlobal.get_tree().root.get_camera_3d()
	if !camera:
		return _error(ERR_NOT_FOUND, "No camera")
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
		# Read through get() so this probe still runs against a build without the
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


## The camera's own projection and transform beside each ring plane's frame and its
## planet's figure, all in km: everything a driver needs to intersect a screen ray with the
## ring plane offline, and so to turn any screen pixel into the ring radius it looks at --
## which is what a rendered ring artifact has to be identified by. Screen positions are
## unaffected by the farwarp depth remap, so the engine's own projection matrix describes
## them exactly.
func get_ring_frame() -> Dictionary:
	var camera := IVGlobal.get_viewport().get_camera_3d()
	if !camera:
		return _error(ERR_NOT_FOUND, "No camera")
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


## Body [param name]'s metering-relevant state.
func get_body_debug(name: String) -> Dictionary:
	var body: IVBody = IVBody.bodies.get(StringName(name))
	if !body:
		return _error(ERR_NOT_FOUND, "No IVBody '%s' in IVBody.bodies" % name)
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


## Every Light3D in the tree, with its energy and visibility.
func list_lights() -> Dictionary:
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


## Whether each visible body's visual actually receives the analytic sun occlusion,
## alongside the light layer that lights it and the CPU parent-shadow fraction the exposure
## manager meters with.
func get_shadow_receivers() -> Dictionary:
	# IVSunOcclusionManager registers a ShaderMaterial only when it is a surface override
	# declaring occluder_data_a.
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


## Per-sample breakdown of body [param name]'s limb ring: each azimuth sample's solar
## zenith, lit measure and frame penetration, so a steep or early transition can be
## attributed to a sample rather than inferred from the total.
func get_limb_samples(name := "MOON_TITAN") -> Dictionary:
	const RING_SAMPLES := 32
	const SHADOW_SOFTNESS := 0.05
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return _error(ERR_NOT_ALLOWED, "no ExposureManager")
	var manager: IVExposureManager = manager_var
	var body_name := StringName(name)
	if !manager._limb_ceilings.has(body_name) or !IVBody.bodies.has(body_name):
		return _error(ERR_NOT_FOUND, "no limb row for %s" % body_name)
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


## Screen positions of body [param name]'s silhouette circle at [param altitude_km] above
## its disc, in [param samples] points. A sphere seen off axis silhouettes as an ELLIPSE, so
## a circle fit to projected points is meaningless there (measured: 1079 px of residual at
## 45 deg of yaw); the projection here is the engine's own, which holds at any orientation
## and is what makes a limb profile measurable at the camera floor.
func project_limb_circle(name := "MOON_TITAN", altitude_km := 0.0, samples := 64) -> Dictionary:
	var body_name := StringName(name)
	if !IVBody.bodies.has(body_name):
		return _error(ERR_NOT_FOUND, "no body %s" % body_name)
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return _error(ERR_NOT_ALLOWED, "no ExposureManager")
	var manager: IVExposureManager = manager_var
	if !manager._limb_geometry.has(body_name):
		return _error(ERR_NOT_FOUND, "no limb row for %s" % body_name)
	var body: IVBody = IVBody.bodies[body_name]
	var camera := IVGlobal.get_viewport().get_camera_3d()
	var view_size := camera.get_viewport().get_visible_rect().size
	var altitude := altitude_km * IVUnits.KM
	var count := samples
	var limb: Vector2 = manager._limb_geometry[body_name]
	var radius := limb.x + altitude
	var camera_vector := body.global_position - camera.global_position
	var camera_distance := camera_vector.length()
	if radius >= camera_distance:
		return _error(ERR_INVALID_PARAMS, "radius exceeds distance")
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


## Last frame's measured viewport render times. Measurement starts at the first call, which
## reports zeros, so poll and average.
func get_render_time() -> Dictionary:
	# viewport_get_measured_render_time_* report the LAST measured frame.
	var viewport := IVGlobal.get_viewport()
	var rid := viewport.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	return {
		"cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(rid),
		"gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(rid),
	}


## What IVWorldEnvironment and IVStarsVisual are dropping because the compensating camera
## has metered it below one display code: the sky pass, and every star magnitude bin with
## its star count, brightest magnitude, peak sky density and current visibility. A
## zero-pixel A/B proves nothing unless the mechanism actually fired, and this is what says
## whether it did.
func get_exposure_skips() -> Dictionary:
	# Reads their private members on purpose: a probe exists to reach what the public API
	# does not expose, and a rename in Core breaks this and nothing else reports it.
	var sky := {}
	var world_environment_node := _get_world_environment()
	if world_environment_node is IVWorldEnvironment:
		var world_environment: IVWorldEnvironment = world_environment_node
		sky = {
			"enabled": world_environment.skip_invisible_starmap,
			"skipped": world_environment._starmap_skipped,
			"background_mode": world_environment.environment.background_mode,
		}
	var stars := {}
	var stars_visual := _find_stars_visual(IVGlobal.get_tree().root)
	if stars_visual:
		var bins := []
		var i := 0
		var n_bins := stars_visual.get_bin_count()
		while i < n_bins:
			var bin_visual := stars_visual._bin_visuals[i]
			bins.append({
				"name": String(bin_visual.name),
				"stars": stars_visual._bin_star_counts[i],
				"brightest_magnitude": stars_visual._bin_brightest_magnitudes[i],
				"peak_density_per_steradian": stars_visual._bin_peak_densities[i],
				"visible": bin_visual.visible,
			})
			i += 1
		stars = {
			"enabled": stars_visual.cull_invisible_bins,
			"drawn_bins": stars_visual.get_drawn_bin_count(),
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


## The empty-shadow-pass decision per IVDynamicLight: each light's table intent, live
## shadow_enabled, reach, cull mask and idle frame count, beside every registered
## local-shadow participant with its layers, visibility and surface distance. Says whether
## the mechanism actually fired, which a zero-pixel A/B cannot.
func get_shadow_skips() -> Dictionary:
	const KM := IVUnits.KM
	var lights := []
	for light in _get_lights():
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


## Freezes or releases auto exposure: [param auto] (bool) and [param manual_ev] (float);
## null keeps each. A frozen exposure is what separates a render change from a metering
## change. Reports the exposure state; call with neither to read it.
func set_exposure(auto: Variant = null, manual_ev: Variant = null) -> Dictionary:
	if auto != null and typeof(auto) != TYPE_BOOL:
		return _error(ERR_INVALID_PARAMS, "'auto' must be a bool")
	if manual_ev != null and !_is_number(manual_ev):
		return _error(ERR_INVALID_PARAMS, "'manual_ev' must be a number")
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return _error(ERR_NOT_ALLOWED, "no ExposureManager")
	var manager: IVExposureManager = manager_var
	if manual_ev != null:
		var manual_ev_value: float = manual_ev
		manager.manual_exposure_ev = manual_ev_value
	if auto != null:
		var is_auto: bool = auto
		manager.auto = is_auto
	return {
		"auto": manager.auto,
		"manual_exposure_ev": manager.manual_exposure_ev,
		"auto_exposure_ev": IVExposureManager.auto_exposure_ev,
		"exposure_adjustment_ev": manager.exposure_adjustment_ev,
		"exposure": IVExposureManager.exposure,
	}


## Overrides the limb ramp at runtime, [param start], [param full] and [param edge]
## (floats; null keeps each), so a to-taste value can be swept in ONE app run rather than
## one run per candidate. Reports all three.
func set_limb_meter(start: Variant = null, full: Variant = null, edge: Variant = null
		) -> Dictionary:
	for value: Variant in [start, full, edge]:
		if value != null and !_is_number(value):
			return _error(ERR_INVALID_PARAMS, "'start', 'full' and 'edge' must be numbers")
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return _error(ERR_NOT_ALLOWED, "no ExposureManager")
	var manager: IVExposureManager = manager_var
	if start != null:
		var start_value: float = start
		manager.limb_meter_fraction_start = start_value
	if full != null:
		var full_value: float = full
		manager.limb_meter_fraction_full = full_value
	if edge != null:
		var edge_value: float = edge
		manager.limb_meter_edge_fraction = edge_value
	return {
		"limb_meter_fraction_start": manager.limb_meter_fraction_start,
		"limb_meter_fraction_full": manager.limb_meter_fraction_full,
		"limb_meter_edge_fraction": manager.limb_meter_edge_fraction,
	}


## Overrides the ring openness ramp at runtime, [param onset] and [param full] (floats;
## null keeps each), so the edge-on release can be swept in ONE app run rather than one
## run per candidate. Reports both.
func set_ring_meter(onset: Variant = null, full: Variant = null) -> Dictionary:
	for value: Variant in [onset, full]:
		if value != null and !_is_number(value):
			return _error(ERR_INVALID_PARAMS, "'onset' and 'full' must be numbers")
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return _error(ERR_NOT_ALLOWED, "no ExposureManager")
	var manager: IVExposureManager = manager_var
	if onset != null:
		var onset_value: float = onset
		manager.ring_meter_onset_openness = onset_value
	if full != null:
		var full_value: float = full
		manager.ring_meter_full_openness = full_value
	return {
		"ring_meter_onset_openness": manager.ring_meter_onset_openness,
		"ring_meter_full_openness": manager.ring_meter_full_openness,
	}


## Sets the physical_light user setting, which is written to the settings file.
func set_physical_light(enabled: bool) -> Dictionary:
	IVSettingsManager.change_setting(&"physical_light", enabled)
	return {"ok": true, "enabled": enabled}


## Overrides the WorldEnvironment's [member Environment.ambient_light_energy].
func set_ambient_energy(energy: float) -> Dictionary:
	var environment := _get_environment()
	if !environment:
		return _error(ERR_NOT_FOUND, "No WorldEnvironment")
	environment.ambient_light_energy = energy
	return {"ok": true, "ambient_light_energy": energy}


## Disables the WorldEnvironment's reflected light, or restores it to the background.
func set_reflected_light(disabled := true) -> Dictionary:
	var environment := _get_environment()
	if !environment:
		return _error(ERR_NOT_FOUND, "No WorldEnvironment")
	environment.reflected_light_source = (Environment.REFLECTION_SOURCE_DISABLED if disabled
			else Environment.REFLECTION_SOURCE_BG)
	return {"ok": true, "disabled": disabled}


## Rewrites the sky material's energy_multiplier with its own value, to trigger a radiance
## rebake.
func poke_sky_radiance() -> Dictionary:
	var environment := _get_environment()
	if !environment:
		return _error(ERR_NOT_FOUND, "No WorldEnvironment")
	var sky := environment.sky
	if !sky or not sky.sky_material is ShaderMaterial:
		return _error(ERR_NOT_FOUND, "No shader sky")
	var sky_material: ShaderMaterial = sky.sky_material
	var energy_var: Variant = sky_material.get_shader_parameter(&"energy_multiplier")
	sky_material.set_shader_parameter(&"energy_multiplier", energy_var)
	return {"ok": true, "energy_multiplier": energy_var}


## Overrides body [param name]'s shells.tsv exposure_ceiling and limb_exposure_ceiling cells
## at runtime; a [param ceiling] of 0.0 removes them. [param limb_only] leaves the body's
## own shell ceilings alone: neutralising Earth's surface cell along with its limb one
## uncaps its city lights, which then clip and are counted as a blown limb by anything
## measuring the frame.
func set_exposure_ceiling(name: String, ceiling: float, limb_only := false) -> Dictionary:
	var manager_var: Variant = IVGlobal.program.get(&"ExposureManager")
	if not manager_var is IVExposureManager:
		return _error(ERR_NOT_ALLOWED, "No ExposureManager (enable_physical_light off?)")
	var manager: IVExposureManager = manager_var
	var body_name := StringName(name)
	var has_shell := !limb_only and manager._exposure_ceilings.has(body_name)
	var has_limb := manager._limb_ceilings.has(body_name)
	if !has_shell and !has_limb:
		return _error(ERR_NOT_FOUND, "No ceiling shell for %s" % body_name)
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


## Shows or hides one IVShellsModel shell of body [param name], so a rendered pixel can be
## decomposed into the shells that built it. Shell 0 is the surface and the orchestrator;
## 1..N are its child shells (a cloud deck, an atmosphere limb).
func set_shell_visible(name: String, shell := 1, visible := true) -> Dictionary:
	var body: IVBody = IVBody.bodies.get(StringName(name))
	if !body:
		return _error(ERR_NOT_FOUND, "no body")
	var found: Array[int] = []
	var hit := false
	for shells_model in _find_shells(body):
		var index := shells_model._shell
		found.append(index)
		if index == shell:
			shells_model.visible = visible
			hit = true
	if not hit:
		return _error(ERR_NOT_FOUND, "no shell %d; body has %s" % [shell, found])
	return {"body": String(body.name), "shell": shell, "visible": visible, "shells": found}


## Sets shader parameter [param param] to [param value] on one shell's material, shell 0
## the surface (as [method set_shell_visible]); sweeps a candidate in ONE app run instead
## of one run per value. Reports the value read back.
func set_shell_param(name: String, param: String, value: float, shell := 1) -> Dictionary:
	var body: IVBody = IVBody.bodies.get(StringName(name))
	if !body:
		return _error(ERR_NOT_FOUND, "no body")
	var parameter := StringName(param)
	for shells_model in _find_shells(body):
		if shells_model._shell != shell:
			continue
		var material := shells_model.get_surface_override_material(0) as ShaderMaterial
		if !material:
			return _error(ERR_NOT_FOUND, "shell has no ShaderMaterial")
		material.set_shader_parameter(parameter, value)
		return {"shell": shell, "param": param,
				"read_back": material.get_shader_parameter(parameter)}
	return _error(ERR_NOT_FOUND, "no shell %d" % shell)


## Shows, hides or re-parameterizes every ring system: [param visible] (bool), and shader
## parameter [param param] set to [param value] (float); null keeps each. Hiding one
## separates what the ring draws from what the globe behind it draws, which a screenshot
## alone cannot, and a parameter sweeps a photometric candidate in ONE app run. Reports
## each ring's visibility, and [param param]'s value where one is named.
func set_rings(visible: Variant = null, param := "", value: Variant = null) -> Dictionary:
	if visible != null and typeof(visible) != TYPE_BOOL:
		return _error(ERR_INVALID_PARAMS, "'visible' must be a bool")
	if value != null and !_is_number(value):
		return _error(ERR_INVALID_PARAMS, "'value' must be a number")
	var found := _find_rings(IVGlobal.get_tree().root)
	if found.is_empty():
		return _error(ERR_NOT_FOUND, "no IVRings in the tree")
	var rows: Array[Dictionary] = []
	for rings: IVRings in found:
		if visible != null:
			var wanted_visible: bool = visible
			rings.visible = wanted_visible
		var material := rings.get_surface_override_material(0) as ShaderMaterial
		if param and material:
			if value != null:
				var parameter_value: float = value
				material.set_shader_parameter(StringName(param), parameter_value)
			rows.append({"rings": String(rings.name), "visible": rings.visible,
					"param": param,
					"value": material.get_shader_parameter(StringName(param))})
		else:
			rows.append({"rings": String(rings.name), "visible": rings.visible})
	return {"ok": true, "rings": rows}


## Sets the WorldEnvironment's glow at runtime: [param enabled] (bool); [param intensity],
## [param strength], [param bloom], [param mix], [param hdr_threshold], [param hdr_scale]
## and [param hdr_luminance_cap] (floats); [param blend_mode] (an
## [enum Environment.GlowBlendMode] int); and [param levels] (7 floats). Null keeps each.
## Levels are as authored for the reference height, which IVWorldEnvironment shifts to the
## render height from the next frame. Reports every glow property back, levels as applied
## and authored_levels as set, so a sweep records the state it measured.
func set_glow(enabled: Variant = null, intensity: Variant = null, strength: Variant = null,
		bloom: Variant = null, mix: Variant = null, hdr_threshold: Variant = null,
		hdr_scale: Variant = null, hdr_luminance_cap: Variant = null,
		blend_mode: Variant = null, levels: Variant = null) -> Dictionary:
	var world_environment := _get_world_environment()
	if !world_environment or !world_environment.environment:
		return _error(ERR_NOT_FOUND, "No WorldEnvironment")
	var environment := world_environment.environment
	if enabled != null:
		if typeof(enabled) != TYPE_BOOL:
			return _error(ERR_INVALID_PARAMS, "'enabled' must be a bool")
		var is_enabled: bool = enabled
		environment.glow_enabled = is_enabled
	var floats: Dictionary[String, Array] = {
		"intensity": [&"glow_intensity", intensity],
		"strength": [&"glow_strength", strength],
		"bloom": [&"glow_bloom", bloom],
		"mix": [&"glow_mix", mix],
		"hdr_threshold": [&"glow_hdr_threshold", hdr_threshold],
		"hdr_scale": [&"glow_hdr_scale", hdr_scale],
		"hdr_luminance_cap": [&"glow_hdr_luminance_cap", hdr_luminance_cap],
	}
	for key: String in floats:
		var property: StringName = floats[key][0]
		var value_var: Variant = floats[key][1]
		if value_var == null:
			continue
		if !_is_number(value_var):
			return _error(ERR_INVALID_PARAMS, "'%s' must be a number" % key)
		var value: float = value_var
		environment.set(property, value)
	if blend_mode != null:
		if typeof(blend_mode) != TYPE_INT:
			return _error(ERR_INVALID_PARAMS, "'blend_mode' must be an int")
		var blend_mode_value: Environment.GlowBlendMode = blend_mode
		environment.glow_blend_mode = blend_mode_value
	if levels != null:
		if typeof(levels) != TYPE_ARRAY:
			return _error(ERR_INVALID_PARAMS, "'levels' must be an array of 7 numbers")
		var level_values: Array = levels
		if level_values.size() != 7:
			return _error(ERR_INVALID_PARAMS, "'levels' must have 7 entries")
		var new_levels: Array[float] = []
		for i in 7:
			var level_var: Variant = level_values[i]
			if !_is_number(level_var):
				return _error(ERR_INVALID_PARAMS, "'levels' entries must be numbers")
			var level: float = level_var
			new_levels.append(level)
		# IVWorldEnvironment shifts its authored levels by render height and would overwrite a
		# direct write the next time the height changed.
		if world_environment is IVWorldEnvironment:
			var iv_world_environment: IVWorldEnvironment = world_environment
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
	if world_environment is IVWorldEnvironment:
		var iv_world_environment: IVWorldEnvironment = world_environment
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


## Sets IVPSFSettings values at runtime, each a float, null keeping it. One object feeds
## the catalog field and every body's PSF quad, so a sweep moves them together. Reports
## every value back.
func set_psf_settings(psf_sigma: Variant = null, intensity_faint_mag: Variant = null,
		intensity_gamma: Variant = null, intensity_scale: Variant = null,
		color_saturation: Variant = null, fov_reference_deg: Variant = null,
		fov_compensation: Variant = null, glare_scale: Variant = null,
		glare_gamma: Variant = null, glare_max_px: Variant = null) -> Dictionary:
	var psf_settings: IVPSFSettings = IVGlobal.program.get(&"PSFSettings")
	if !psf_settings:
		return _error(ERR_NOT_FOUND, "No PSFSettings")
	var values: Dictionary[StringName, Variant] = {
		&"psf_sigma": psf_sigma,
		&"intensity_faint_mag": intensity_faint_mag,
		&"intensity_gamma": intensity_gamma,
		&"intensity_scale": intensity_scale,
		&"color_saturation": color_saturation,
		&"fov_reference_deg": fov_reference_deg,
		&"fov_compensation": fov_compensation,
		&"glare_scale": glare_scale,
		&"glare_gamma": glare_gamma,
		&"glare_max_px": glare_max_px,
	}
	for property in values:
		var value_var: Variant = values[property]
		if value_var == null:
			continue
		if !_is_number(value_var):
			return _error(ERR_INVALID_PARAMS, "'%s' must be a number" % property)
		var value: float = value_var
		psf_settings.set(property, value)
	var report := {"ok": true}
	for property in values:
		report[String(property)] = psf_settings.get(property)
	return report


## Turns either exposure-driven skip off or on, [param sky] and [param stars] (bools), and
## sets [param capture_height] (float), which stands in for IVScreenshotManager's
## off-screen render height and is otherwise unreachable from a driver; 0.0 clears it.
## Null keeps each. Off is the un-culled render an A/B diffs against, in ONE app run and
## so at ONE exposure. Reports the state back, as [method get_exposure_skips].
func set_exposure_skips(sky: Variant = null, stars: Variant = null,
		capture_height: Variant = null) -> Dictionary:
	for value: Variant in [sky, stars]:
		if value != null and typeof(value) != TYPE_BOOL:
			return _error(ERR_INVALID_PARAMS, "'sky' and 'stars' must be bools")
	if capture_height != null and !_is_number(capture_height):
		return _error(ERR_INVALID_PARAMS, "'capture_height' must be a number")
	if sky != null:
		var world_environment_node := _get_world_environment()
		if not world_environment_node is IVWorldEnvironment:
			return _error(ERR_NOT_FOUND, "No IVWorldEnvironment")
		var world_environment: IVWorldEnvironment = world_environment_node
		var sky_enabled: bool = sky
		world_environment.skip_invisible_starmap = sky_enabled
	if stars != null:
		var stars_visual := _find_stars_visual(IVGlobal.get_tree().root)
		if !stars_visual:
			return _error(ERR_NOT_FOUND, "No IVStarsVisual")
		var stars_enabled: bool = stars
		stars_visual.cull_invisible_bins = stars_enabled
	# IVScreenshotManager sets this around an off-screen capture and clears it after.
	if capture_height != null:
		var render_height: float = capture_height
		IVStarsVisual.capture_render_height = render_height
	return get_exposure_skips()


## Turns the empty-shadow-pass skip off or on for every light, [param enabled] (bool; null
## keeps it). Off restores each light's table shadow_enabled, which is the un-skipped render
## an A/B diffs against, in ONE app run at ONE pose. Reports the state back, as
## [method get_shadow_skips].
func set_shadow_skips(enabled: Variant = null) -> Dictionary:
	if enabled != null and typeof(enabled) != TYPE_BOOL:
		return _error(ERR_INVALID_PARAMS, "'enabled' must be a bool")
	if enabled != null:
		var is_enabled: bool = enabled
		for light in _get_lights():
			light._skip_empty_shadow_passes = is_enabled and light._process_shadow_distances
			if !is_enabled:
				light.shadow_enabled = light._shadow_capable
				light._idle_shadow_frames = 0
	return get_shadow_skips()


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


# Callers read IVShellsModel._shell, a private member -- a rename in Core breaks them here.
func _find_shells(node: Node) -> Array[IVShellsModel]:
	var out: Array[IVShellsModel] = []
	var shell := node as IVShellsModel
	if shell:
		out.append(shell)
	for child in node.get_children():
		out.append_array(_find_shells(child))
	return out


func _get_world_environment() -> WorldEnvironment:
	var world_environment: WorldEnvironment = IVGlobal.program.get(&"WorldEnvironment")
	return world_environment


func _get_environment() -> Environment:
	var world_environment := _get_world_environment()
	if !world_environment:
		return null
	return world_environment.environment


func _get_lights() -> Array[IVDynamicLight]:
	var lights: Array[IVDynamicLight] = []
	_collect_lights(IVGlobal.get_tree().root, lights)
	return lights


func _collect_lights(node: Node, lights: Array[IVDynamicLight]) -> void:
	var light := node as IVDynamicLight
	if light:
		lights.append(light)
	for child in node.get_children():
		_collect_lights(child, lights)


func _find_stars_visual(node: Node) -> IVStarsVisual:
	var stars_visual := node as IVStarsVisual
	if stars_visual:
		return stars_visual
	for child in node.get_children():
		stars_visual = _find_stars_visual(child)
		if stars_visual:
			return stars_visual
	return null


func _find_sun_disc_material() -> ShaderMaterial:
	var star: IVBody = IVBody.bodies.get(&"STAR_SUN")
	if !star:
		return null
	for node in star.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node
		if mesh_instance.get_surface_override_material_count() < 1:
			continue
		var material := mesh_instance.get_surface_override_material(0)
		if material is ShaderMaterial:
			var shader_material: ShaderMaterial = material
			if shader_material.get_shader_parameter(&"brightness") != null:
				return shader_material
	return null


func _get_starmap_energy() -> float:
	var environment := _get_environment()
	if !environment:
		return NAN
	var sky := environment.sky
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


func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT


func _error(code: int, message: String) -> Dictionary:
	return {"_error": {"code": code, "message": message}}
