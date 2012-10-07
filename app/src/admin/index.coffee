root = require('derby-workspace').createApp module,
	# derby-workspace options
	base: '/admin'

	# derby-i18n options
  urlScheme: 'path'
  availableLocales: ['en', 'ja']

#
# Routes
#

#root.index redirect: 'dashboard'
root.page 'dashboard', module: require('./dashboard')

root.section 'words', module: require('./words'), (words) ->
	words.index t: 'browse', (browse) ->
		browse.modal 'add', space: 'edit', params: { id: 'new' }
		browse.modal ':id', space: 'edit'

#root.section 'sentences', module: require('./sentences'), (sentences) ->
#	sentences.index t: 'browse', (browse,) ->
#		browse.modal 'add',
#		browse.modal ':id', space: 'edit'
#	sentences.page 'polish'
