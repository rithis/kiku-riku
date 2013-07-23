module.exports = (container) ->  
  container.set "loader", (Loader, container, logger) ->
    new Loader container, logger
