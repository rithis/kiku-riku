module.exports = (container) ->
  container.set "calculator", ->
    require "../lib/calculator"
