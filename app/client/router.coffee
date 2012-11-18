Meteor.Router.add
  '/': 'welcome'
  '/study': 'study'

Meteor.Router.filters
  requireLogin: (page) ->
    username = Session.get 'username'
    if username
      page
    #else 
      #'sign_in'
#Meteor.Router.filter 'requireLogin', except: 'welcome'