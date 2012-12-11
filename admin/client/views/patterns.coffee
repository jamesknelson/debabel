#$(document).on
#	'input': ->
#		
#	, '[contenteditable]'

Template.patternEditor.showEditor = ->
	!!(Session.get "patternId")

Template.patternEditor.pattern = ->
	collection = Session.get "patternCollection"
	pattern = Local.findOne Session.get "patternId"
	
Template.patternEditor.events =
	'click .save': (event, template) ->
		
	'click .cancel': ->
		Meteor.Router.to('/patterns')

	'click .slice-button': (event, template) ->

		# XXX Store collection and id instead of actual pattern,
		# then update the pattern in the collection when 
		# this is called.

		Local.update({_id: Session.get "patternId"}, {$push: {slices: 
			{
				pronunciation: '',
				spelling: ''
			}
		}});