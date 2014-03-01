# {BufferedProcess} = require 'atom'
{spawn} = require 'child_process'

LEIN_CMD = '/usr/local/bin/lein'
LEIN_REPL_ARGS = ['repl']

module.exports =
  activate: (state) ->
    @repl = spawn(
      LEIN_CMD,
      LEIN_REPL_ARGS,
      {
        cwd: atom.project.getPath()
        stdio: 'pipe'
      }
    )
    @repl.stderr.setEncoding 'utf8'
    @repl.stderr.on 'data', (data) ->
      stdout(data)
    @repl.stdout.setEncoding 'utf8'
    @repl.stdout.on 'data', (data) ->
      stdout(data)
    atom.workspaceView.eachPane (pane) =>
      pane.command 'language-clojure:doc-for-symbol', =>
        @repl.stdin.write("(doc defn)\n")

stdout = (output) -> console.log(output)
