Space = require('workspace').Space

module.exports =
	index: index
	edit: edit

index = 
	init: (params) ->
		this.model.subscribe 'words', (err, words) ->
    		this.context.ref '_words', words
    		this.render()

edit = 
	# Equivalent to component.init
	# this.model is application model
	# this.context is model scoped for this particular instance of
	#   this particular space
	init: (params) ->
		id = params.id
		if id === 'new'
			this.model.async.incr 'peopleCount', (err, count) ->
				id = count.toString()
				this._subscribeWordAndRender id
		else
			this._subscribeWordAndRender id

	save: (e, el) ->
		# Save things
		this.redirect '..'

	_subscribeWordAndRender: (id) ->
	  	this.model.subscribe 'words.'+id, (err, word) ->
	    	this.context.ref '_word', word
	    	this.render()
