derby = require 'derby'

module.exports = (root) ->
  staticPages = derby.createStatic root

  return (req, res) ->
    # respond with html
    if req.accepts 'html'
      staticPages.render '404', res, {url: req.url}, 404
      return

    # respond with json
    if req.accepts 'json'
      res.send error: 'Not found'
      return

    # default to plain-text. send()
    res.type('txt').send('Not found')