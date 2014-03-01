{ScrollView} = require 'atom'

module.exports =
  class ClojureDocView extends ScrollView
    @content: ->
      @div class: 'clojuredoc', tabindex: -1, =>
        @pre =>
          @code class: 'output'

    getTitle: -> "Clojure documentation"

    clear: ->
      @find(".output").empty()

    addLine: (line) ->
      console.log(line)
      @find(".output").append(line)
