var port = process.env.PORT || 3000;

if (process.env.NODE_ENV === 'production') {
  module.exports = server = require('./src/bootstrap');
  server.listen(port);
} else {
  require('derby').run('./src/bootstrap', port);
}