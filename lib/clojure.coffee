ClojureDocView = require './clojure-doc-view'
nreplClient = require 'nrepl-client'
async = require 'async'
url = require 'url'
fs = require 'fs'
{spawn} = require 'child_process'

docBaseUri = "atom://clojure-doc/"
docview = null

getMetaCmd = (prop, word) -> "(:#{prop} (meta (ns-resolve *ns* (symbol '#{word}))))"

fileInProject = (name) ->
  atom.project.resolve(name)

projectFile = ->
  fileInProject('project.clj')

replPortFile = ->
  fileInProject('.nrepl-port')

inClojureProject = (cb) ->
  fs.exists projectFile(), (exists) ->
    cb() if exists

withReplPort = (cb) ->
  async.waterfall [
    (next) ->
      fs.exists replPortFile(), (exists) ->
        if not exists
          console.log 'spawning repl'
          lein = spawn('lein', ['repl'], { cwd: atom.project.getPath() })
          lein.stdout.on 'data', (data) ->
            console.log 'got data', data.toString()
            next() if data.toString().search('=>') >= 0
        else
          console.log 'repl running'
          next()
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
          docview = new ClojureDocView(url.parse(uri).pathname.replace(/^\//, ''))

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
                  docview.setDoc(arglists + "\n\n" + doc);
                  next()
              ], (err, result) ->
                throw err if err
                repl.end()
