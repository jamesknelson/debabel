Local = new Meteor.Collection null

Meteor.Router.add
  '/': 'dashboard'

  '/patterns': ->
    Session.set 'patternCollection', false
    Session.set 'patternId', false
    'patterns'

  '/patterns/new': ->
    Local.insert {
        slices: [
          {
            pronunciation: ''
            spelling: ''
          }
        ]
      }, (err, id) -> 
        Session.set 'patternCollection', 'Local'
        Session.set 'patternId', id
    'patterns'

  '/patterns/:id': (id) ->
    Session.set 'patternCollection', 'Patterns'
    Session.set 'patternId', id
    'patterns'

  '/transforms': 'transforms'

  '/transforms/new': ->
    Session.set('transformId', 'new')
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