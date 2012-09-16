derby = require 'derby'
{get, view, ready} = derby.createApp module
derby.use(require '../../ui')

## ROUTES ##

pages = [
  {url: '/admin/words', title: 'Words'}
]

render = (name, page) -> 
  ctx = 
    pages: pages
    activeUrl: page.params.url
  
  page.render name, ctx

get '/admin/words', (page, model) -> 
  render 'words', page 

#get '/people' -> (page, model)
#  model.subscribe('people', 'conf.main.directoryIds', function(err, people) {
#    model.refList('_people', people, 'conf.main.directoryIds')
#    render('people', page)
#  })
#)

## CONTROLLER FUNCTIONS ##

ready (model) ->
  history = app.view.history

