{ScrollView} = require 'atom'

module.exports =
  class ClojureDocView extends ScrollView
    @content: ->
      @div class: 'clojuredoc', tabindex: -1, =>
        @div class: 'output'

    getTitle: -> "Clojure documentation"

    addLine: (line) ->
      console.log(line)
      @find("div.output").append("<pre class='line'>#{line}</pre>")
