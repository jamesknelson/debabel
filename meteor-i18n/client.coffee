# Internationalization translate helper
Handlebars.registerHelper 't', (key, options) ->
	path = ['locales', 'en'].concat(key.split('.'))
	data = YAML.data
	for element in path
		unless data = data[element]
			data = key
			break
	data