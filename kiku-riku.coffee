kantaina = require "kantaina"
mongoose = require "mongoose"
express = require "express"
inflect = do require "i"
nodefn = require "when/node/function"
path = require "path"
fs = require "fs"
w = require "when"


container = kantaina()


loadModule = (module) ->
  applicationDirectory = path.dirname require.resolve module

  loadModels(applicationDirectory)
  .then ->
    loadRouter applicationDirectory


loadModels = (applicationDirectory) ->
  modelsDirectory = path.join applicationDirectory, "models"

  container.set "mongoose", mongoose
  container.set "connectionString", "mongodb://localhost/test"
  container.set "connection", (mongoose, connectionString) ->
      deffered = w.defer()

      connection = mongoose.createConnection()
      connection.open connectionString, (err) ->
        return deffered.reject err if err
        deffered.resolve connection

      deffered.promise

  nodefn.call(fs.readdir, modelsDirectory)
  .then (files) ->
    files.filter (file) ->
      /\.coffee$/.test file
  .then (files) ->
    files.map (file) ->
      path.join modelsDirectory, file
  .then (files) ->
    w.map files, (file) ->
      modelName = path.basename file, path.extname file
      modelKey = inflect.singularize(inflect.titleize(modelName)).replace /\ /g, ""
      schemaKey = modelName + "Schema"

      container.set schemaKey, require file

      container.set modelKey, (container, connection) ->
        container.get(schemaKey)
        .then (schema) ->
          model = connection.model modelName, schema

          # ALERT: patch model
          originalCreate = model.create
          model.create = ->
            nodefn.apply originalCreate.bind(@), arguments

          model


loadRouter = (applicationDirectory) ->
  controllersDirectory = path.join applicationDirectory, "controllers"
  configDirectory = path.join applicationDirectory, "config"

  container.set "express", ->
    express
  
  container.set "app", (express) ->
    app = express()
    app.use express.bodyParser()
    app

  container.set "router", (app) ->
    controllers: {}

    add: (url, controller, action, method, model) ->
      @controllers[controller] ||= {}
      @controllers[controller][action] = [method, url, model]

    load: ->
      for controllerName, actions of @controllers
        file = path.join controllersDirectory, controllerName
        controller = require file

        for action, url of actions
          [method, url, model] = url
          if controller[action]
            ctrl = controller[action]
            do (ctrl, method, url, model) ->
              app[method] url, (req, res) ->
                container.get(model)
                .then (model) ->
                  ctrl model, req, res
                .then (result) ->
                  res.send 200, result unless res.complete
                .then null, (err) ->
                  console.log "err", err
                  res.send 500 unless res.complete
          else
            app[method] url, (req, res) ->
              res.send 405

  container.set "resource", (router) ->
    (name) ->
      collectionUrl = "/" + name
      documentUrl = collectionUrl + "/:_id"
      collectionSuffix = inflect.camelize name
      documentSuffix = inflect.singularize collectionSuffix
      model = documentSuffix
      router.add collectionUrl, name, "get" + collectionSuffix, "get", model
      router.add collectionUrl, name, "post" + collectionSuffix, "post", model
      router.add collectionUrl, name, "put" + collectionSuffix, "put", model
      router.add collectionUrl, name, "delete" + collectionSuffix, "delete", model
      router.add documentUrl, name, "get" + documentSuffix, "get", model
      router.add documentUrl, name, "post" + documentSuffix, "post", model
      router.add documentUrl, name, "put" + documentSuffix, "put", model
      router.add documentUrl, name, "delete" + documentSuffix, "delete", model

  container.inject(require path.join(configDirectory, "router.coffee"))
  .then ->
    container.get "router"
  .then (router) ->
    router.load()
  .then ->
    container.get "app"
  .then (app) ->
    app.listen 3000


loadModule("./index")
.then null, (err) ->
  process.stderr.write err.toString()
  process.stderr.write "\n"
  process.exit 1
