kantaina = require "kantaina"
Core = require "./core"
w = require "when"


createCore = (container) ->
  new Core container


runCore = (applicationDirectory, core) ->
  deffered = w.defer()

  core.loadApplication(applicationDirectory)
  .then (core) ->
    deffered.resolve core
    core.run()

  deffered.promise


module.exports = (applicationDirectory, makeContainer = containerFactory) ->
  deffered = w.defer()

  makeContainer()
  .then(createCore)
  .then(runCore.bind null, applicationDirectory)
  .then null, (err) ->
    process.stderr.write err.toString()
    process.stderr.write "\n"
    process.exit 1


module.exports.containerFactory = containerFactory = ->
  container = new kantaina.Container

  container.inject([
    require "./modules/mongoose"
    require "./modules/express"
  ]).then ->
    container
