Meteor.subscribe("patterns");

Meteor.Router.add
  '/': 'welcome'
  '/study': 'study'

  '/admin': 'admin::dashboard'

  '/admin/patterns': 'admin::patterns'
  '/admin/patterns/new': ->
    # turn on edit dialog
    'admin::patterns::editor'
  '/admin/patterns/:id': (id) ->
    Session.set('admin::patterns::editor::id', id)
    'admin::patterns::editor'

Meteor.Router.filters
  requireLogin: (page) ->
    username = Session.get 'username'
    if username
      page
    #else 
      #'sign_in'
#Meteor.Router.filter 'requireLogin', except: 'welcome'