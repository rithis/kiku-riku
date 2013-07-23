sequence = require "when/sequence"
kantaina = require "kantaina"


module.exports = (Loader) ->
  container = new kantaina.Container

  container.set "Loader", ->
    Loader

  container.inject([
    require "./injectors/express"
    require "./injectors/loader"
    require "./injectors/mongoose"
    require "./injectors/winston"
  ])
  .then ->
    container.get "loader"
  .then (loader) ->
    loader.load()
  .then ->
    container.get "listener"
  .then (listener) ->
    listener.listen()
  .then null, (err) ->
    process.stderr.write err.stack
    process.stderr.write "\n"
    process.exit 1
