module.exports =
  activate: (state) ->
    atom.workspaceView.eachPane (pane) ->
      pane.command 'language-clojure:doc-for-symbol', ->
        return
