#!/usr/bin/env coffee
path = require "path"
kr = require ".."


loaderPath = process.argv[2]

unless loaderPath
  process.stderr.write "usage: kr loaderPath\n"
  process.exit 1

kr require path.resolve loaderPath
