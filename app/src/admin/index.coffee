derby = require 'derby'
{get, view, ready} = derby.createApp module
derby.use(require 'derby-ui-boot')
derby.use(require '../../ui')

{render} = require './shared'

## ROUTES ##
get '/admin', (page, model) ->
  render 'dashboard', page

get '/admin/dictionary', (page, model) -> 
  render 'dictionary', page

get '/admin/sentences', (page, model) ->
  render 'sentences', page

#get '/people' -> (page, model)
#  model.subscribe('people', 'conf.main.directoryIds', function(err, people) {
#    model.refList('_people', people, 'conf.main.directoryIds')
#    render('people', page)
#  })
#)

## CONTROLLER FUNCTIONS ##

exports.toggle = ->


exports._clickMenu = ->
  

ready (model) ->
  history = app.view.history

