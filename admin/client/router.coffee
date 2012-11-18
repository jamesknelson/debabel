Meteor.Router.add
  '/': 'dashboard'

  '/patterns': 'patterns'

  '/patterns/new': ->
    Session.set('patternId', 'new')
    'patterns'

  '/patterns/:id': (id) ->
    Session.set('patternId', id)
    'patterns'

  '/transforms': 'transforms'

  '/transforms/new': ->
    Session.set('patternId', 'new')
    'transforms'

  '/transforms/:id': (id) ->
    Session.set('transformId', id)
    'transforms'

Meteor.Router.filters
  requireLogin: (page) ->
    username = Session.get 'username'
    if username
      page
    else 
      'sign_in'

#Meteor.Router.filter 'requireLogin'