{spawn} = require 'child_process'

leinCmd = '/usr/bin/env'
leinReplArgs = ['lein', 'repl']

module.exports =
  class Repl
    constructor: ->
      @repl = spawn(
        leinCmd,
        leinReplArgs,
        {
          cwd: atom.project.getPath()
          stdio: 'pipe'
        }
      )
      @repl.stderr.setEncoding 'utf8'
      @repl.stderr.on 'data', (data) ->
        console.err(data)
      @repl.stdout.setEncoding 'utf8'

    showDoc: (word, docView) ->
      docView.clear()
      @repl.stdout.removeAllListeners('data')
      @repl.stdout.on 'data', (data) =>
        docView.addLine(data)
      command = "(doc #{word})\n"
      @repl.stdin.write(command)
