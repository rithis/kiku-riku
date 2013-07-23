express = require "express"
path = require "path"
i = do require "i"


module.exports = (container) ->
  container.set "express", ->
    express

  container.set "port", 3000

  container.set "app", (express) ->
    app = express()
    app.use express.bodyParser()
    app

  container.set "listener", (app, port, logger) ->
    listen: ->
      logger.info "listen", port: port
      app.listen port

  container.set "router", (app, container, logger) ->
    controllers: {}

    add: (url, controller, action, method, model) ->
      @controllers[controller] ||= {}
      @controllers[controller][action] = [method, url, model]

    load: (controllersDirectory) ->
      for controllerName, actions of @controllers
        file = path.join controllersDirectory, controllerName
        logger.debug "load controller", path: file
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

  container.set "resource", (router, logger) ->
    (name) ->
      logger.debug "define resource", name: name
      collectionUrl = "/" + name
      documentUrl = collectionUrl + "/:_id"
      collectionSuffix = i.camelize name
      documentSuffix = i.singularize collectionSuffix
      model = documentSuffix
      router.add collectionUrl, name, "get" + collectionSuffix, "get", model
      router.add collectionUrl, name, "post" + collectionSuffix, "post", model
      router.add collectionUrl, name, "put" + collectionSuffix, "put", model
      router.add collectionUrl, name, "delete" + collectionSuffix, "delete", model
      router.add documentUrl, name, "get" + documentSuffix, "get", model
      router.add documentUrl, name, "post" + documentSuffix, "post", model
      router.add documentUrl, name, "put" + documentSuffix, "put", model
      router.add documentUrl, name, "delete" + documentSuffix, "delete", model
