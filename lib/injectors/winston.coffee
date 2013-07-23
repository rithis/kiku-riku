winston = require "winston"


module.exports = (container) ->
  container.set "winston", winston

  container.set "logger", (winston) ->
    new winston.Logger
      transports: [
        new winston.transports.Console
          level: "debug"
          colorize: true
          timestamp: true
          stripColors: true
      ]
