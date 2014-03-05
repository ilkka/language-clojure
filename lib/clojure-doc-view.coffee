{ScrollView} = require 'atom'

module.exports =
  class ClojureDocView extends ScrollView
    constructor: (word) ->
      super
      @word = word
      @title = "(doc #{word})"

    @content: ->
      @pre =>
        @code class: 'output'

    getTitle: -> @title

    clear: ->
      @find(".output").empty()

    setDoc: (text) ->
      @find(".output").text(text)
