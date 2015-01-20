
var hostname = window.location.hostname;
var serverUrl = 'http://' + hostname + ':3000';

Polymer({

  ready: function () {
    this.pluginName = 'instantmessage';
    var self = this;
    // Init the plugin name
    $.get('/platform/loggedOnUser').done(function (user) {
      self.currentUser = user;
      // update user info in the im database
      $.post(serverUrl + '/api/users', {
        id: self.currentUser.id,
        name: self.currentUser.name
      }).done(function (user) {
        $.get('/platform/users/' + user.id + '/teams').done(function (teams) {


          async.each(teams, function (team, callback) {
            $.post(serverUrl + '/api/channels', {
              isPrivate: 'false',
              name: team.name,
              teamId: team.id
            }).done(function (channel) {
              // after channel is added, add user to this channel
              $.post(serverUrl + '/api/channels/' + channel.id + '/users', {userId: self.currentUser.id}).done(function (users) {
                // users store the user in this channel
                callback();
              });
            });
          }, function (err) {
            if (err) {
              console.log(err);
            } else {
              document.querySelector('app-router').go( '/' + self.pluginName + '/channels/' + teams[0].name);
            }
          });

        });
      });
    });
  }
});
