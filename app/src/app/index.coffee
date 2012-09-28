derby = require 'derby'
i18n = require 'derby-i18n'
{get, view, ready} = app = i18n.localize derby.createApp(module),
  availableLocales: ['en', 'ja'],
  urlScheme: 'path'
derby.use(require '../../ui')
derby.use(require 'derby-ui-boot')

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

