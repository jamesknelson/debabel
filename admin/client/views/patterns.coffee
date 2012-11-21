Template.patternEditor.showEditor = ->
  !!(Session.get "patternId")

Template.patternEditor.events =
  'click .save': (event, template) ->
    
  'click .cancel': ->
    Meteor.Router.to('/patterns')