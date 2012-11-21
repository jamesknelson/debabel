Meteor.Router.add
  '/': 'dashboard'

  '/patterns': ->
    Session.set('patternId', false)
    'patterns'

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
    if Meteor.userId()
      page
    else 
      'accountsSignIn'

Meteor.Router.filter 'requireLogin'