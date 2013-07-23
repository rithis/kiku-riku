callbacks = require "when/callbacks"
sequence = require "when/sequence"
nodefn = require "when/node/function"
path = require "path"
fs = require "fs"
i = do require "i"
w = require "when"


module.exports = class Module
  constructor: (@container, @logger) ->
    @directory = @.__proto__.constructor.directory
    @configDirectory = path.join @directory, "config"
    @controllersDirectory = path.join @directory, "controllers"
    @modelsDirectory = path.join @directory, "models"
    @diConfigurationFile = path.join @configDirectory, "di"
    @routerConfigurationFile = path.join @configDirectory, "router"

  load: ->
    @logger.debug "load module", path: @directory

    sequence [
      => @configureContainer()
      => @loadModels()
      => @configureRouter()
    ]

  configureContainer: ->
    try
      module = require @diConfigurationFile
      @logger.debug "configure container", path: @diConfigurationFile
      @container.inject module
    catch
      undefined

  loadModels: ->
    callbacks.call(fs.exists, @modelsDirectory)
    .then (exists) =>
      return unless exists

      nodefn.call(fs.readdir, @modelsDirectory)
      .then (files) ->
        files.filter (file) ->
          path.extname(file) in Object.keys require.extensions

      .then (files) =>
        files.map (file) =>
          path.join @modelsDirectory, path.basename file, path.extname file

      .then (files) =>
        w.map files, (file) =>
          modelName = path.basename file, path.extname file
          modelKey = i.singularize(i.titleize(modelName)).replace /\ /g, ""
          schemaKey = modelName + "Schema"

          @logger.debug "load model", path: file, key: modelKey

          @container.set schemaKey, require file

          @container.set modelKey, (container, connection) ->
            container.get(schemaKey)
            .then (schema) ->
              model = connection.model modelName, schema

              # ALERT: patch model
              originalCreate = model.create
              model.create = ->
                nodefn.apply originalCreate.bind(@), arguments

              model

  configureRouter: ->
    try
      module = require @routerConfigurationFile
      @logger.debug "configure routing", path: @routerConfigurationFile
      @container.inject(module)
      .then =>
        @container.get "router"
      .then (router) =>
        router.load @controllersDirectory
    catch
      undefined
