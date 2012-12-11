adminOnly = (fn) ->	if !!Meteor.user then fn else {}

Meteor.publish "patterns", adminOnly ->
	{} #Pattern.find()
Meteor.publish "transforms", adminOnly ->
	Transforms.find()