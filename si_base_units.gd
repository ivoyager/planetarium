# si_base_units.gd
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
class_name SIBaseUnits
extends Object

# We keep this static class outside of the 'ivoyager' submodule so projects can
# modify, if needed. 

# SI base units - all internal sim values derived from these!
const METER := 1.0 # engine length units per meter; see Notes below
const SECOND := 1.0
const KG := 1.0
const AMPERE := 1.0
const KELVIN := 1.0
const CANDELA := 1.0

# Notes on base SI units:
#
# See ivoyager/static/units.gd for conversion of base SI units to derived
# units. These affect internal float representation of quantities, but not
# physics or display. Values here don't matter *in theory* because *everything*
# is converted. E.g., if you double METER here, then the gravitational constant
# will be appropriately increased by eight-fold. 
#
# In past Godot versions (3.2.x and before) it was necessary to reduce METER
# to 1e-13 to elimitate visual glitches. I guess this might have been due to
# inconsistent implementation of double floats or conversion to single floats
# for the GPU. This seems to be fixed as of 3.5.1.

