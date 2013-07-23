kr = require ".."

module.exports = class Example extends kr.Loader
  @modules = [
    require "./index"
  ]
