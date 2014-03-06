ClojureDocView = require './clojure-doc-view'
nreplClient = require 'nrepl-client'
async = require 'async'
url = require 'url'
fs = require 'fs'
{spawn} = require 'child_process'

docBaseUri = "atom://clojure-doc/"
docview = null

getMetaCmd = (prop, word) ->
  "(:#{prop} (meta (ns-resolve *ns* (symbol '#{word}))))"

fileInProject = (name) ->
  atom.project.resolve(name)

projectFile = ->
  fileInProject('project.clj')

replPortFile = ->
  fileInProject('.nrepl-port')

inClojureProject = (cb) ->
  fs.exists projectFile(), (exists) ->
    cb() if exists

waitForPortNumber = (cb) ->
  fs.writeFile replPortFile(), '', {mode:0o640}, (err) ->
    cb(err) if err
    watcher = fs.watch replPortFile(), (evt, fn) ->
      console.log evt, fn
      fs.stat replPortFile(), (err, stats) ->
        cb(err) if err
        if stats.isFile() and stats.size > 0
          watcher.close()
          cb()

launchReplIfNotRunning = (cb) ->
  fs.exists replPortFile(), (exists) ->
    if not exists
      console.log 'spawning repl'
      spawn('lein', ['repl'], { cwd: atom.project.getPath() })
      waitForPortNumber(cb)
    else
      console.log 'repl running'
      cb()

withReplPort = (cb) ->
  async.waterfall [
    (next) ->
      launchReplIfNotRunning(next)
    (next) ->
      fs.readFile replPortFile(), next
    (data, next) ->
      next(null, data.toString().trim())
  ], (err, result) ->
    throw err if err
    cb(result)

module.exports =
  activate: (state) ->
    inClojureProject ->
      atom.project.registerOpener (uri) ->
        if url.parse(uri).host is 'clojure-doc'
          docword = url.parse(uri).pathname.replace(/^\//, '')
          docview = new ClojureDocView(docword)

      atom.workspaceView.eachPane (pane) ->
        pane.command 'language-clojure:doc-for-symbol', ->
          editor = atom.workspace.getActiveEditor()
          editor.selectWord() if editor.getSelectedBufferRange().isEmpty()
          word = editor.getSelectedText()
          atom.workspace.open(url.resolve(docBaseUri, word), split: 'right')
          withReplPort (port) ->
            repl = nreplClient.connect({port: port})
            repl.once 'connect', ->
              console.log('connected!')
              async.waterfall [
                (next) ->
                  repl.eval getMetaCmd('doc', word), (err, res) ->
                    next(err, res.replace(/\\n\s+/g, ' ').replace(/^"|"$/g, ''))
                (doc, next) ->
                  repl.eval getMetaCmd('arglists', word), (err, res) ->
                    next(err, doc, res)
                (doc, arglists, next) ->
                  docview.clear()
                  docview.setDoc(arglists + "\n\n" + doc)
                  next()
              ], (err, result) ->
                throw err if err
                repl.end()
