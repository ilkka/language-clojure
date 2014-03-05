ClojureDocView = require './clojure-doc-view'
nreplClient = require 'nrepl-client'
async = require 'async'
url = require 'url'
fs = require 'fs'

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
  fs.readFile replPortFile(), (err, data) ->
    throw err if err
    cb(data.toString().trim())

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
              async.series [
                (next) ->
                  repl.eval getMetaCmd('doc', word), (err, result) ->
                    console.log("Result: #{result}")
                    docview.clear()
                    docview.setDoc(result.replace(/\\n\s+/g, ' '));
                    next()
              ], (err) ->
                console.log('done!')
                repl.end()
