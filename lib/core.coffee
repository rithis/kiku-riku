callbacks = require "when/callbacks"
sequence = require "when/sequence"
nodefn = require "when/node/function"
path = require "path"
fs = require "fs"
i = do require "i"
w = require "when"


module.exports = class Core
  constructor: (@container, @logger) ->

  loadModule: (moduleId) ->
    @loadApplication path.dirname require.resolve moduleId

  loadApplication: (applicationDirectory) ->
    @logger.debug "load application", path: applicationDirectory
    configDirectory = path.join applicationDirectory, "config"
    controllersDirectory = path.join applicationDirectory, "controllers"
    modelsDirectory = path.join applicationDirectory, "models"

    routerConfigFile = path.join configDirectory, "router.coffee"
    diConfigFile = path.join configDirectory, "di.coffee"

    sequence([
      loadDi.bind @, diConfigFile
      loadModels.bind @, modelsDirectory
      loadRouter.bind @, routerConfigFile, controllersDirectory
    ])
    .then =>
      @

  run: ->
    @container.inject (app, port, logger) ->
      logger.info "listen", port: port
      app.listen port

  loadDi = (diConfigFile) ->
    callbacks.call(fs.exists, diConfigFile)
    .then (exists) =>
      return unless exists
      @logger.debug "configure di", path: diConfigFile
      @container.inject require diConfigFile

  loadModels = (modelsDirectory) ->
    callbacks.call(fs.exists, modelsDirectory)
    .then (exists) =>
      return unless exists

      nodefn.call(fs.readdir, modelsDirectory)
      .then (files) ->
        files.filter (file) ->
          path.extname(file) in Object.keys require.extensions

      .then (files) ->
        files.map (file) ->
          path.join modelsDirectory, file

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

  loadRouter = (routerConfigFile, controllersDirectory) ->
    callbacks.call(fs.exists, routerConfigFile)
    .then (exists) =>
      return unless exists

      @logger.debug "configure routing", path: routerConfigFile

      @container.inject(require routerConfigFile)
      .then =>
        @container.get "router"
      .then (router) ->
        router.load controllersDirectory
