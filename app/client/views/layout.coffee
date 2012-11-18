Template.sign_in.events =
  'submit form': (e) ->
    e.preventDefault()
    Session.set('username', $(e.target).find('[name=username]').val())

Template.welcome.username = -> Session.get 'username'
Template.welcome.events =
  'submit form': (e, template) -> 
    e.preventDefault()
    Meteor.Router.to('/posts/' + template.find('#post_name').value)

  'click .logout': (e) ->
    e.preventDefault()
    Session.set 'username', false
