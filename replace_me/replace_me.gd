# replace_me.gd
# *****************************************************************************
# This is an example "extension" file that changes some init values and shows
# how to extend an existing class or add a new class (these are commented out).
#
# Requirements:
#    1. This file must have the same name as its directory (+".gd")
#    2. Must have the 3 constants below
#    3. Must have function extension_init()
#
# This file could extend a Node if you want, but it would have to add itself to
# the tree.

extends Reference

const EXTENSION_NAME := "Replace Me!"
const EXTENSION_VERSION := "dev"
const EXTENSION_VERSION_YMD := 20191109 # can test for addon requirement by date


func extension_init():
	ProjectBuilder.connect("project_objects_instantiated", self, "_on_project_objects_instantiated")
	Global.connect("gui_entered_tree", self, "_on_gui_entered_tree")
	
	# Change global init values...
	Global.save_file_extension = "TemplateSave"
	Global.save_file_extension_name = "Template Save"
	Global.allow_time_reversal = false
	
	# You can extend and replace an existing class. For example, if MyExtendedBody
	# extends Body, then this line would cause MyExtendedBody to be used instead
	# of Body in the solar system build...
	# ProjectBuilder.procedural_classes._Body_ = MyExtendedBody
	
	# "Program nodes" and "program reerences" are classes instantiated by
	# ProjectBuider. This line would add one of your own...
	# ProjectBuilder.program_nodes._MyProgramNode_ = MyProgramNode

func _on_project_objects_instantiated() -> void:
	# Here you can access and change init values for program nodes and
	# program references (for nodes, before they are added to the tree).
	var settings_manager: SettingsManager = Global.objects.SettingsManager
	settings_manager.defaults.save_base_name = "Template"

func _on_gui_entered_tree(gui_panel: Control) -> void:
	# Here you can access and change init values for GUI classes not defined in
	# ProjectBuilder (i.e., SelectionPanel, InfoPanel, NavigationPanel) before
	# they are added to the tree.
	if gui_panel is InfoPanel:
		# For example, you could add 2 of your own InfoPanel "subpanels" before
		# the Wiki subpanel (so there would be 3 buttons on the InfoPanel)...
		gui_panel.subpanel_classes = [
			# MySubpanel1,
			# MySubpanel2,
			InfoSubpanelWiki,
		]
