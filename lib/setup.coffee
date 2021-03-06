{ API_URL, NODE_ENV, REDIS_URL, ASSET_PATH, API_KEY } = require "../config"
express = require "express"
Backbone = require "backbone"
sharify = require "sharify"
path = require "path"
{ flushall, client } = require './cache'


# Inject some constant data into sharify
sd = sharify.data =
  API_URL: API_URL
  ASSET_PATH: ASSET_PATH
  JS_EXT: (if "production" is NODE_ENV then ".min.js" else ".js")
  CSS_EXT: (if "production" is NODE_ENV then ".min.css" else ".css")

module.exports = (app) ->

  # Override Backbone to use server-side sync
  Backbone.sync = require "backbone-super-sync"
  Backbone.sync.cacheClient = client

  if API_KEY
    Backbone.sync.editRequest = (req) -> req.set('X-AUTH-TOKEN': API_KEY)

  # Mount sharify
  app.use sharify

  # Development only
  if "development" is NODE_ENV
    # Compile assets on request in development
    app.use require("stylus").middleware
      src: path.resolve(__dirname, "../")
      dest: path.resolve(__dirname, "../public")
    app.use require("browserify-dev-middleware")
      src: path.resolve(__dirname, "../")
      transforms: [require("jadeify"), require('caching-coffeeify')]

  # Test only
  if "test" is NODE_ENV
    # Mount fake API server
    app.use "/__api", require("../test/helpers/integration.coffee").api

  # Mount apps
  app.use require "../apps/index"
  app.use require "../apps/show"
  app.use require "../apps/clear"

  # More general middleware
  app.use express.static(path.resolve __dirname, "../public")