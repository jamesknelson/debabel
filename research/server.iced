express = require 'express'

app = express.createServer()

app.get '/', (req, res) ->
	res.send 'Hi'

app.listen 8080
console.log "Listening on port 8080..."