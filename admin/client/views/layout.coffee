Template.layoutNavbar.activeness = (page) ->
  Meteor.Router.page() == page && "active"