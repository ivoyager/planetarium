# body_finder.gd
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
class_name BodyFinder
extends RefCounted

## Finds bodies by the words a user calls them, for the user's assistant.
##
## A body's name in the app is a key ("MOON_GANYMEDE"), and the GUI shows its
## translation. A model hearing "Ganymede" calls [method find_bodies] for the
## key that selecting the body, its data and its views take. The assistant's
## tool, addressed by its role "BodyFinder" (preinitializer.gd adds it to the
## program); the GUI has no use for it.

const AUTOMATION_USER_METHODS: Array[StringName] = [&"find_bodies"]


## Returns up to [param max_results] bodies whose name contains [param text],
## in the user's language or as a key, the closest matches first: each
## [code]{"name": key, "display_name": ..., "parent": ...}[/code], where
## [code]parent[/code] is the display name of the body it orbits. Returns an
## empty array if none matches.
func find_bodies(text: String, max_results := 5) -> Array[Dictionary]:
	var query := text.strip_edges().to_lower()
	if !query:
		return []
	var ranked: Array[Array] = [] # [rank, name length, body]; rank 0 for an exact match
	for body: IVBody in IVBody.bodies.values():
		var display_name := tr(body.name).to_lower()
		var key := String(body.name).to_lower()
		var rank := -1
		if display_name == query or key == query:
			rank = 0
		elif display_name.begins_with(query):
			rank = 1
		elif display_name.contains(query) or key.contains(query):
			rank = 2
		if rank != -1:
			ranked.append([rank, display_name.length(), body])
	ranked.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var results: Array[Dictionary] = []
	for i in mini(ranked.size(), max_results):
		var body: IVBody = ranked[i][2]
		var result := {"name": String(body.name), "display_name": tr(body.name)}
		if body.parent:
			result["parent"] = tr(body.parent.name)
		results.append(result)
	return results
