//var derby = require('derby');
//derby.io.configure(function () { 
//  derby.io.set("transports", ["xhr-polling"]); 
//  derby.io.set("polling duration", 10); 
//});
//derby.run(__dirname + '/src/bootstrap');

var port = process.env.PORT || 3000;
module.exports = server = require('./src/bootstrap').listen(port);
console.log("Debabel listening on port %d", server.address().port);
