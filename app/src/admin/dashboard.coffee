Space = require('workspace').Space

module.exports =
	dashboard: dashboard

dashboard =
	# Called each time a user requests the page
	render: (template, model) ->
		template.render

	# Called the first time the whole app loads in the app ready
	# callback.
	ready: (model) ->
