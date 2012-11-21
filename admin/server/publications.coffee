adminOnly = (fn) ->	if !!Meteor.user then fn else {}

Meteor.publish "patterns", adminOnly ->
	Patterns.find()
Meteor.publish "transforms", adminOnly ->
	Transforms.find()