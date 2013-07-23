kantaina = require "kantaina"
Core = require "./core"
w = require "when"


module.exports = (applicationDirectory) ->
  deffered = w.defer()

  container = new kantaina.Container
  core = new Core container

  container.inject([
    require "./modules/mongoose"
    require "./modules/express"
  ])
  .then ->
    core.loadApplication applicationDirectory
  .then ->
    deffered.resolve core
    core.run()
  .then null, (err) ->
    process.stderr.write err.toString()
    process.stderr.write "\n"
    process.exit 1

  deffered.promise
