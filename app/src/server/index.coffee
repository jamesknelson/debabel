http = require 'http'
path = require 'path'
express = require 'express'
gzippo = require 'gzippo'
derby = require 'derby'

app = require '../app'
admin = require '../admin'

serverError = require './serverError'
error404 = require './error404'

## RACER CONFIGURATION ##

racer = require 'derby/node_modules/racer'
racer.io.set('transports', ['xhr-polling'])
unless process.env.NODE_ENV == 'production'
  racer.use(racer.logPlugin)
  derby.use(derby.logPlugin)

## SERVER CONFIGURATION ##

expressApp = express()
server = module.exports = http.createServer expressApp
store = derby.createStore listen: server


ONE_YEAR = 1000 * 60 * 60 * 24 * 365
root = path.dirname path.dirname __dirname
publicPath = path.join root, 'public'

expressApp
#  .use(express.logger())
  .use(express.favicon())

  # Gzip static files and serve from memory
  .use(gzippo.staticGzip publicPath, maxAge: ONE_YEAR)
#  .use(express.static(publicPath))

  # Gzip dynamically rendered content
  .use(express.compress())

  # Uncomment to add form data parsing support
  .use(express.bodyParser())
  .use(express.methodOverride())

  # Uncomment and supply secret to add Derby session handling
  # Derby session middleware creates req.session and socket.io sessions
  # .use(express.cookieParser())
  # .use(store.sessionMiddleware
  #   secret: process.env.SESSION_SECRET || 'YOUR SECRET HERE'
  #   cookie: {maxAge: ONE_YEAR}
  # )

  # Adds req.getModel method
  .use(store.modelMiddleware())

  # Creates an express middleware from the app's routes
  .use(admin.router())
  .use(app.router())
  .use(expressApp.router)
  .use(serverError root)


## SERVER ONLY ROUTES ##
expressApp.all '*', error404(root)
