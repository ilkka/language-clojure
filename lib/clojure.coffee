# {BufferedProcess} = require 'atom'
{spawn} = require 'child_process'
ClojureDocView = require './clojure-doc-view'

leinCmd = '/usr/local/bin/lein'
leinReplArgs = ['repl']

docUri = "atom://clojure-doc"

module.exports =
  activate: (state) ->
    atom.project.registerOpener (uri) =>
      if uri is docUri
        if not @docView
          @docView = new ClojureDocView if uri is docUri
        else
          @docView

    @repl = makeRepl()

    atom.workspaceView.eachPane (pane) =>
      pane.command 'language-clojure:doc-for-symbol', =>
        editor = atom.workspace.getActiveEditor()
        atom.workspace.open(docUri, split: 'right')
        @docView.clear()
        @repl.stdout.removeAllListeners('data')
        @repl.stdout.on 'data', (data) =>
          @docView.addLine(data)
        editor.selectWord() if editor.getSelectedBufferRange().isEmpty()
        command = "(doc #{editor.getSelectedText()})\n"
        @repl.stdin.write(command)

makeRepl = ->
  repl = spawn(
    leinCmd,
    leinReplArgs,
    {
      cwd: atom.project.getPath()
      stdio: 'pipe'
    }
  )
  repl.stderr.setEncoding 'utf8'
  repl.stderr.on 'data', (data) ->
    console.err(data)
  repl.stdout.setEncoding 'utf8'
  repl
