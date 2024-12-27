# units.gd
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
extends Node

## Planetarium's IVUnits singleton
##
## This file replaces the plugin template file at addons/ivoyager_units/units.gd.
## It's mostly unchanged except for sim scale (const METER) and a few added
## units. See the class file for comments about scale in project exports.[br][br]

# As of Godot 4.2.beta4, there are lighting bugs related to scale that are
# platform specific. We have to manually update METER here for export platform.
#
# Windows:
#   METER = 1.0 works great.
#   METER = 1e-3 looks ok for all existing bodies.
#   METER = 1e-4 causes 'lights out' when approaching smallest object (Juno).
#   METER = 1e-10 caues 'lights out' for Moon & smaller.
#
# HTML5:
#   METER = 1.0 causes unlit everywhere with irregular light 'patches'.
#   METER = 1e-3 causes above but only when at larger planets.
#   METER = 1e-4 causes shadow edge issue at larger planets. (But no hint of Windows issue above.)
#   METER = 1e-5 as above but less. Self-shadowing artifact?
#   METER = 1e-7 lighting ok for all tested. (Harsh shadow border? Need to compare w/ below.)
#   METER = 1e-10 lighting ok for all tested.
#
# Godot 4.3 update. Problems for HTML5 as above. However, Windows now appears
# ok at 1e-10. Perhaps smaller value should be our base value (again)?

# SI base units
const SECOND := 1.0
const METER := 1e-7 # see notes above
const KG := 1.0
const AMPERE := 1.0
const KELVIN := 1.0
const CANDELA := 1.0

# derived units & constants
const DEG := PI / 180.0 # radians
const MINUTE := 60.0 * SECOND
const HOUR := 3600.0 * SECOND
const DAY := 86400.0 * SECOND # exact Julian day
const YEAR := 365.25 * DAY # exact Julian year
const CENTURY := 36525.0 * DAY
const MM := 1e-3 * METER
const CM := 1e-2 * METER
const KM := 1e3 * METER
const AU := 149597870700.0 * METER
const PARSEC := 648000.0 * AU / PI
const SPEED_OF_LIGHT := 299792458.0 * METER / SECOND
const LIGHT_YEAR := SPEED_OF_LIGHT * YEAR
const STANDARD_GRAVITY := 9.80665 * METER / SECOND ** 2
const GRAM := 1e-3 * KG
const TONNE := 1e3 * KG
const HECTARE := 1e4 * METER ** 2
const LITER := 1e-3 * METER ** 3
const NEWTON := KG * METER / SECOND ** 2
const PASCAL := NEWTON / METER ** 2
const BAR := 1e5 * PASCAL
const ATM := 101325.0 * PASCAL
const JOULE := NEWTON * METER
const ELECTRONVOLT := 1.602176634e-19 * JOULE
const WATT := NEWTON / SECOND
const VOLT := WATT / AMPERE
const COULOMB := SECOND * AMPERE
const WEBER := VOLT * SECOND
const TESLA := WEBER / METER ** 2
const GRAVITATIONAL_CONSTANT := 6.67430e-11 * METER ** 3 / (KG * SECOND ** 2)

# Unit symbols below mostly follow:
# https://en.wikipedia.org/wiki/International_System_of_Units
#
# IVConvert.convert_quantity() can convert compound units such as 'm/s^2'.
# However, dictionary lookup is faster so consider adding commonly used
# compound units as keys in unit_multipliers. 
#
# We look for unit symbol first in unit_multipliers and then in unit_lambdas.

var unit_multipliers := {
	# Duplicated symbols have leading underscore.
	# See IVQFormat for unit display strings.
	
	# time
	&"s" : SECOND,
	&"min" : MINUTE,
	&"h" : HOUR,
	&"d" : DAY,
	&"a" : YEAR, # Julian year symbol
	&"y" : YEAR,
	&"yr" : YEAR,
	&"Cy" : CENTURY,
	# length
	&"mm" : MM,
	&"cm" : CM,
	&"m" : METER,
	&"km" : KM,
	&"au" : AU,
	&"AU" : AU,
	&"ly" : LIGHT_YEAR,
	&"pc" : PARSEC,
	&"Mpc" : 1e6 * PARSEC,
	# mass
	&"g" : GRAM,
	&"kg" : KG,
	&"t" : TONNE,
	# angle
	&"rad" : 1.0,
	&"deg" : DEG,
	# temperature
	&"K" : KELVIN,
	# frequency
	&"Hz" : 1.0 / SECOND,
	&"1/Cy" : 1.0 / CENTURY,
	# area
	&"m^2" : METER ** 2,
	&"km^2" : KM ** 2,
	&"ha" : HECTARE,
	# volume
	&"l" : LITER,
	&"L" : LITER,
	&"m^3" : METER ** 3,
	# velocity
	&"m/s" : METER / SECOND,
	&"km/s" : KM / SECOND,
	&"au/Cy" : AU / CENTURY,
	&"c" : SPEED_OF_LIGHT,
	# acceleration/gravity
	&"m/s^2" : METER / SECOND ** 2,
	&"_g" : STANDARD_GRAVITY,
	# angular velocity
	&"rad/s" : 1.0 / SECOND, 
	&"deg/d" : DEG / DAY,
	&"deg/Cy" : DEG / CENTURY,
	# particle density
	&"m^-3" : 1.0 / METER ** 3,
	# density
	&"g/cm^3" : GRAM / CM ** 3,
	# force
	&"N" : NEWTON,
	# pressure
	&"Pa" : PASCAL,
	&"bar" : BAR,
	&"atm" : ATM,
	# energy
	&"J" : JOULE,
	&"kJ" : 1e3 * JOULE,
	&"MJ" : 1e6 * JOULE,
	&"GJ" : 1e9 * JOULE,
	&"Wh" : WATT * HOUR,
	&"kWh" : 1e3 * WATT * HOUR,
	&"MWh" : 1e6 * WATT * HOUR,
	&"GWh" : 1e9 * WATT * HOUR,
	&"eV" : ELECTRONVOLT,
	# power
	&"W" : WATT,
	&"kW" : 1e3 * WATT,
	&"MW" : 1e6 * WATT,
	&"GW" : 1e9 * WATT,
	# luminous intensity / luminous flux
	&"cd" : CANDELA,
	&"lm" : CANDELA, # 1 lm = 1 cd·sr, but sr is dimensionless
	# luminance
	&"cd/m^2" : CANDELA / METER ** 2,
	# electric potential
	&"V" : VOLT,
	# electric charge
	&"C" :  COULOMB,
	# magnetic flux
	&"Wb" : WEBER,
	# magnetic flux density
	&"T" : TESLA,
	# information
	&"bit" : 1.0,
	&"B" : 8.0,
	# information (base 10)
	&"kbit" : 1e3,
	&"Mbit" : 1e6,
	&"Gbit" : 1e9,
	&"Tbit" : 1e12,
	&"kB" : 8e3,
	&"MB" : 8e6,
	&"GB" : 8e9,
	&"TB" : 8e12,
	# information (base 2)
	&"Kibit" : 1024.0,
	&"Mibit" : 1024.0 ** 2,
	&"Gibit" : 1024.0 ** 3,
	&"Tibit" : 1024.0 ** 4,
	&"KiB" : 8.0 * 1024.0,
	&"MiB" : 8.0 * 1024.0 ** 2,
	&"GiB" : 8.0 * 1024.0 ** 3,
	&"TiB" : 8.0 * 1024.0 ** 4,
}

var unit_lambdas := {
	&"degC" : func convert_celsius(x: float, to_internal := true) -> float:
		return x + 273.15 if to_internal else x - 273.15,
	&"degF" : func convert_fahrenheit(x: float, to_internal := true) -> float:
		return  (x + 459.67) / 1.8 if to_internal else x * 1.8 - 459.67,
}
