# planetarium.gd
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
extends Reference

# This file modifies init values in IVGlobal and classes in IVProjectBuilder.
#
# As of v0.0.10, the Planetarium is mainly being developed as a Progressive Web
# App (PWA). However, it should be exportable to other, non-HTML5 platforms.
#
# In Godot 3.x, HTML5 export should use GLES2.
# Godot 3.4.2+ supports multithreading in HTML5 exports. But we are keeping
# single thread for maximum browser compatibility.

const EXTENSION_NAME := "Planetarium"
const EXTENSION_VERSION := "0.0.13-DEV"
const EXTENSION_VERSION_YMD := 20220803
const DEBUG_BUILD := "" # ymd + this displayed when version ends with "-DEV"

const USE_THREADS := true # set false for debugging
const NO_THREADS_IF_HTML5 := true # can override above


func _extension_init() -> void:
	prints(EXTENSION_NAME, EXTENSION_VERSION, str(EXTENSION_VERSION_YMD) + DEBUG_BUILD)
	if NO_THREADS_IF_HTML5 and IVGlobal.is_html5:
		IVGlobal.use_threads = false
	else:
		IVGlobal.use_threads = USE_THREADS
	print("HTML5 = %s, GLES2 = %s, threads = %s" % \
			[IVGlobal.is_html5, IVGlobal.is_gles2, IVGlobal.use_threads])
	IVGlobal.connect("project_objects_instantiated", self, "_on_program_objects_instantiated")
	IVGlobal.connect("project_nodes_added", self, "_on_project_nodes_added")
	IVGlobal.connect("simulator_started", self, "_on_simulator_started")
	IVProjectBuilder.prog_builders.erase("_SaveBuilder_")
	IVProjectBuilder.prog_nodes.erase("_SaveManager_")
	IVProjectBuilder.gui_nodes.erase("_SaveDialog_")
	IVProjectBuilder.gui_nodes.erase("_LoadDialog_")
	IVProjectBuilder.gui_nodes.erase("_SplashScreen_")
	IVProjectBuilder.gui_nodes.erase("_MainMenuPopup_")
	IVProjectBuilder.gui_nodes.erase("_MainProgBar_")
	IVProjectBuilder.gui_nodes.erase("_CreditsPopup_")
	IVProjectBuilder.prog_nodes._ViewCacher_ = ViewCacher # planetarium/view_cacher.gd
	IVProjectBuilder.gui_nodes._ProjectGUI_ = GUITop # planetarium/gui/gui_top.gd
	IVProjectBuilder.gui_nodes._BootScreen_ = BootScreen # added on top; self-frees
	IVGlobal.project_name = EXTENSION_NAME
	IVGlobal.project_version = EXTENSION_VERSION
	IVGlobal.project_version_ymd = EXTENSION_VERSION_YMD
	IVGlobal.enable_save_load = false
	IVGlobal.allow_real_world_time = true
	IVGlobal.allow_time_reversal = true
	IVGlobal.home_view_from_user_time_zone = true
	IVGlobal.disable_pause = true
	IVGlobal.skip_splash_screen = true
	IVGlobal.disable_exit = true
	IVGlobal.enable_wiki = true
	IVGlobal.popops_can_stop_sim = false
	if IVGlobal.is_html5:
		IVProjectBuilder.gui_nodes.erase("_MainProgBar_")
		IVGlobal.disable_quit = true
		IVGlobal.vertecies_per_orbit = 200


func _on_program_objects_instantiated() -> void:
	var model_builder: IVModelBuilder = IVGlobal.program.ModelBuilder
	model_builder.max_lazy = 10
	var timekeeper: IVTimekeeper = IVGlobal.program.Timekeeper
	timekeeper.start_real_world_time = true
	var huds_manager: IVHUDsManager = IVGlobal.program.HUDsManager
	huds_manager.show_names = true
	huds_manager.show_orbits = true
	var quantity_formatter: IVQuantityFormatter = IVGlobal.program.QuantityFormatter
	quantity_formatter.exp_str = " x 10^"
	var theme_manager: IVThemeManager = IVGlobal.program.ThemeManager
	theme_manager.main_menu_font = "gui_main"
	var window_manager: IVWindowManager = IVGlobal.program.WindowManager
	window_manager.add_menu_button = true
	var hotkeys_popup: IVHotkeysPopup = IVGlobal.program.HotkeysPopup
	hotkeys_popup.remove_item("toggle_all_gui")
	hotkeys_popup.add_item("cycle_next_panel", "LABEL_CYCLE_NEXT_PANEL", "LABEL_GUI")
	hotkeys_popup.add_item("cycle_prev_panel", "LABEL_CYCLE_LAST_PANEL", "LABEL_GUI")
	var options_popup: IVOptionsPopup = IVGlobal.program.OptionsPopup
	options_popup.remove_item("starmap") # web assets only have 8k starmap
	var settings_manager: IVSettingsManager = IVGlobal.program.SettingsManager
	var default_settings := settings_manager.defaults
	if IVGlobal.is_html5:
		default_settings.gui_size = IVEnums.GUISize.GUI_LARGE
		var view_cacher: ViewCacher = IVGlobal.program.ViewCacher
		view_cacher.cache_interval = 1.0
	if IVGlobal.is_gles2:
		# try to compensate for Gles2 color differences
		default_settings.planet_orbit_color =  Color(0.6,0.6,0.2)
		default_settings.dwarf_planet_orbit_color = Color(0.1,0.9,0.2)
		default_settings.moon_orbit_color = Color(0.3,0.3,0.9)
		default_settings.minor_moon_orbit_color = Color(0.6,0.2,0.6)


func _on_project_nodes_added() -> void:
	pass


func _on_simulator_started() -> void:
	if DEBUG_BUILD or EXTENSION_VERSION.ends_with("-DEV"):
		var project_gui: Control = IVGlobal.program.ProjectGUI
		var version_label = project_gui.find_node("VersionLabel")
		version_label.set_version_label("Planetarium", false, true, " ", "",
				"\n" + str(EXTENSION_VERSION_YMD) + DEBUG_BUILD)
	if IVGlobal.is_html5:
		if JavaScript.pwa_needs_update():
			_on_pwa_update_available()
		else:
			JavaScript.connect("pwa_update_available", self, "_on_pwa_update_available")


func _on_pwa_update_available() -> void:
	print("PWA update available!")
	IVOneUseConfirm.new("TXT_PWA_UPDATE_AVAILABLE", self, "_update_pwa", [], false,
			"LABEL_UPDATE_RESTART_Q", "BUTTON_UPDATE", "BUTTON_CONTINUE")


func _update_pwa() -> void:
	print("Updating PWA!")
	JavaScript.pwa_update()


