sequence = require "when/sequence"
nodefn = require "when/node/function"
path = require "path"
fs = require "fs"
i = do require "i"
w = require "when"


module.exports = class Core
  constructor: (@container) ->

  loadModule: (moduleId) ->
    @loadApplication path.dirname require.resolve moduleId

  loadApplication: (applicationDirectory) ->
    configDirectory = path.join applicationDirectory, "config"
    controllersDirectory = path.join applicationDirectory, "controllers"
    modelsDirectory = path.join applicationDirectory, "models"

    routerConfigFile = path.join configDirectory, "router.coffee"
    diConfigFile = path.join configDirectory, "di.coffee"

    sequence [
      loadDi.bind @, diConfigFile
      loadModels.bind @, modelsDirectory
      loadRouter.bind @, routerConfigFile, controllersDirectory
    ]

  run: ->
    @container.inject (app) ->
      app.listen 3000

  loadDi = (diConfigFile) ->
    @container.inject require diConfigFile

  loadModels = (modelsDirectory) ->
    nodefn.call(fs.readdir, modelsDirectory)
    .then (files) ->
      files.filter (file) ->
        /\.(js|coffee)$/.test file

    .then (files) ->
      files.map (file) ->
        path.join modelsDirectory, file

    .then (files) =>
      w.map files, (file) =>
        modelName = path.basename file, path.extname file
        modelKey = i.singularize(i.titleize(modelName)).replace /\ /g, ""
        schemaKey = modelName + "Schema"

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
    @container.inject(require routerConfigFile)
    .then =>
      @container.get "router"
    .then (router) ->
      router.load controllersDirectory
