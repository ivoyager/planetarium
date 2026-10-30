# external_links.gd
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
class_name ExternalLinks
extends RefCounted

## Opens the external pages the GUI links to, for the user's assistant.
##
## The Info panel links to the I, Voyager site, its credits, license, feedback
## and more, each an [IVLinkLabel]. A model asked for one calls
## [method open_link] with the link's text, which opens it as a click does. The
## assistant's tool, addressed by its role "ExternalLinks" (preinitializer.gd
## adds it to the program); a body's Wikipedia page is
## [method IVWikiManager.open_page].

const AUTOMATION_USER_METHODS: Array[StringName] = [&"get_link_names", &"open_link"]

var _url_regex := RegEx.create_from_string('\\[url="?([^"\\]]+)"?\\](.*?)\\[/url\\]')


## Returns the text of each external link the GUI shows, in the user's
## language, such as "Credits".
func get_link_names() -> Array[String]:
	var link_names: Array[String] = []
	link_names.assign(_get_links().keys())
	return link_names


## Opens the page of the GUI's external link [param link_name] in the user's
## browser, as clicking the link does. Returns false, doing nothing, if no link
## has that text ([method get_link_names] lists them).
func open_link(link_name: String) -> bool:
	var query := link_name.strip_edges().to_lower()
	var links := _get_links()
	for link_text in links:
		if link_text.to_lower() != query:
			continue
		var link_label: IVLinkLabel = links[link_text][0]
		var url: String = links[link_text][1]
		link_label.meta_clicked.emit(url)
		return true
	return false


# Returns [link_label, url] by link text.
func _get_links() -> Dictionary[String, Array]:
	var links: Dictionary[String, Array] = {}
	var root := IVGlobal.get_tree().root
	for node in root.find_children("*", "IVLinkLabel", true, false):
		var link_label: IVLinkLabel = node
		if !link_label.open_external_url:
			continue
		var bbcode := link_label.atr(link_label.text)
		for url_match in _url_regex.search_all(bbcode):
			links[url_match.get_string(2)] = [link_label, url_match.get_string(1)]
	return links
