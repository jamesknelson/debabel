derby = require 'derby'
{get, view, ready} = derby.createApp module
derby.use(require '../../ui')

i18n = require 'i18next'
i18n.init saveMissing: true, lng: "en-AU", preload: ['jp']

view.fn 't', i18n.t
view.fn 'locale', i18n.lng

pages = [
  {url: '/', title: 'Debabel'}
  {url: '/study', title: 'Study'}
  {url: '/about', title: 'About'}
]


## ROUTES ##

render = (name, page) -> 
  ctx = 
    pages: pages
    activeUrl: page.params.url
  
  page.render name, ctx

get '/', (page, model) -> 
  console.log " === GOT REQUEST FOR MAIN PAGE === "
  render 'splash', page
get '/study', (page, model) ->
  render 'study', page
get '/about', (page, model) ->
  render 'about', page

#get '/people' -> (page, model)
#  model.subscribe('people', 'conf.main.directoryIds', function(err, people) {
#    model.refList('_people', people, 'conf.main.directoryIds')
#    render('people', page)
#  })
#)

## CONTROLLER FUNCTIONS ##

ready (model) ->
  history = app.view.history

