mongoose = require "mongoose"
w = require "when"


module.exports = (container) ->
  container.set "mongoose", mongoose

  container.set "connectionString", "mongodb://localhost/test"

  container.set "connection", (mongoose, connectionString) ->
      deffered = w.defer()

      connection = mongoose.createConnection()
      connection.open connectionString, (err) ->
        return deffered.reject err if err
        deffered.resolve connection

      deffered.promise
