# Your init script
#
# Atom will evaluate this file each time a new window is opened. It is run
# after packages are loaded/activated and after the previous editor state
# has been restored.
#
# An example hack to make opened Markdown files always be soft wrapped:
#
# path = require 'path'
#
atom.workspaceView.eachEditorView (editorView) ->
	# console.log Date.now()
	# editorView.toggleSoftTabs()
	# editor = editorView.getEditor()
	# editor.softTabs = false
	# editor.setSoftTabs false
	# console.log editorView
	# console.log editor
	# atom.beep()
