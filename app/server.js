var derby = require('derby');
derby.io.configure(function () { 
  derby.io.set("transports", []); 
  derby.io.set("polling duration", 10); 
});
derby.run(__dirname + '/src/bootstrap');
