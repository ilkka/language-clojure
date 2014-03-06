{ScrollView} = require 'atom'

module.exports =
  class ClojureDocView extends ScrollView
    initialize: (word) ->
      super
      @word = word
      @title = "(doc #{word})"

    @content: ->
      @div class: 'clojure-doc-view', tabindex: -1, =>
        @div class: 'clojure-doc-container', =>
          @pre =>
            @code outlet: 'code'

    getTitle: -> @title

    clear: ->
      @code.empty()

    setDoc: (text) ->
      @code.text(text)
