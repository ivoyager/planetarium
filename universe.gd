# universe.gd
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
#
#             Developers! The place to start is:
#                ivoyager/singletons/project_builder.gd
#                ivoyager/singletons/global.gd
#
# *****************************************************************************
# Universe is outside of the ivoyager submodule so projects can easily build
# scenes under the simulator root node. (E.g., our Planetarium adds a boot
# screen.) Note however that the simulator root node can be changed at init by
# setting the "universe" property in ProjectBuilder. Constants below also are
# externalized so projects can modify, in particular METER which determines
# simulator scale. 

extends Spatial
class_name Universe

# SI base units - all internal sim values derived from these!
const METER := 1e-13 # engine length units per meter; see Notes below
const SECOND := 1.0
const KG := 1.0
const AMPERE := 1.0
const KELVIN := 1.0
const CANDELA := 1.0

# Notes on base SI units:
#
# See ivoyager/static/UnitDefs.gd for conversion of base SI units to derived
# units. These affect internal float representation of quantities, but not
# physics or display. Values here don't matter *in theory* because *everything*
# is converted. E.g., if you double METER here, then the gravitational constant
# will be appropriately increased by eight-fold. 
#
# However, in practice, proper visual display is sensitive to METER. This works
# in conjunction with dynamic changes in Camera.near and .far (see
# ivoyager/tree_nodes/vygr_camera.gd) to show extreems of close (asteroid-sized
# objects) to extreems of far (200 AU solar system view).
# For Godot 3.2.2 and before, 1e-9 or smaller worked well. With Godot 3.2.3, we
# needed to decrease to 1e-13 to eliminate visual glitches. These problems most
# likely arise from inconsistency of double versus single precision floats in
# different parts of the Godot Engine. (Rendering of course, but also things
# like AABB and other built-ins, I believe.)
