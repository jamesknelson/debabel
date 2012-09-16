#!/usr/bin/env coffee

fs = require("fs")
redis = require("redis").createClient()
argv = require("optimist")
	.boolean('reset')
	.boolean('import')
	.usage("Usage: $0 [--reset] [--import]")
	.argv;


redis.on "error", (err) ->
    console.log "Redis Error: " + err

console.log "Loaded Redis"

importLines = (cb) ->
	remaining = ''
	linesRead = 0
	corpus = fs.createReadStream "corpus.txt"

	addLine = (line) ->
		redis.sadd 'lines', line
		linesRead += 1

	corpus.on 'data', (data) ->
		remaining += data
		index = remaining.indexOf '\n'
		last = 0
		while index > -1
			line = remaining.substring last, index
			last = index + 1
			
			# Add line to redis
			addLine line

			index = remaining.indexOf '\n', last
		remaining = remaining.substring last

	await corpus.on 'end', defer()

	if remaining.length > 0
		addLine remaining

	cb(linesRead)

# Process Options

if argv.reset
	console.log "Resetting Database..."
	await redis.flushdb defer()
	console.log "Done"

if argv.import
	console.log "Adding lines to Redis... "
	begin = Date.now()
	await importLines defer linesRead
	console.log "Added %d lines in %d seconds", linesRead, (Date.now() - begin)/1000

# Close the app
redis.quit()
