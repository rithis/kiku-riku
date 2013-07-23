w = require "when"


module.exports = class Loader
  constructor: (@container, @logger) ->

  load: ->
    w.map @.__proto__.constructor.modules, @loadModule.bind @

  loadModule: (Module) ->
    m = new Module @container, @logger
    m.load()
