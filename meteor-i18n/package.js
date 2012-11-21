Package.describe({
  summary: "Basic i18n for Meteor"
});

Package.on_use(function (api, where) {
  api.use('yaml', ['client', 'server']);
  api.use('coffeescript', 'server');

  api.add_files('client.coffee', 'client');
  api.add_files('server.coffee', 'server');
});


Package.on_test(function (api) {
	
});
