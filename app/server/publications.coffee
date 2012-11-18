Meteor.publish "patterns", ->
  Patterns.find published: true
