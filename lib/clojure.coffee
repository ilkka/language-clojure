# {BufferedProcess} = require 'atom'
ClojureDocView = require './clojure-doc-view'
Repl = require './clojure-repl'

docUri = "atom://clojure-doc"

module.exports =
  activate: (state) ->
    atom.project.registerOpener (uri) =>
      if uri is docUri
        if not @docView
          @docView = new ClojureDocView if uri is docUri
        else
          @docView

    @repl = new Repl

    atom.workspaceView.eachPane (pane) =>
      pane.command 'language-clojure:doc-for-symbol', =>
        editor = atom.workspace.getActiveEditor()
        editor.selectWord() if editor.getSelectedBufferRange().isEmpty()
        atom.workspace.open(docUri, split: 'right')
        @repl.showDoc(editor.getSelectedText(), @docView)
        
