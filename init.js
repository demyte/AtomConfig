(function() {
  atom.workspaceView.eachEditorView(function(editorView) {
    var editor;
    editor = editorView.getEditor();
    console.log(editor);
    editor.setSoftTabs(false);
    return editor.setTabLength(4);
  });

}).call(this);
