{ScrollView} = require 'atom'

module.exports =
  class ClojureDocView extends ScrollView
    constructor: ->
      super()
      @text = ""

    @content: ->
      @pre =>
        @code class: 'output'

    getTitle: -> "Clojure documentation"

    clear: ->
      @find(".output").empty()
      @text = ""

    addLine: (line) ->
      @text += line
      @find(".output").text(@text)
