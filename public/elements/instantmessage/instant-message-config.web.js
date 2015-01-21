var hostname = window.location.hostname;
var serverUrl = 'http://' + hostname + ':3000';

Polymer({

  ready: function () {
    this.pluginName = 'instantmessage';
    var self = this;
    async.waterfall(
      [
        // load all teams
        function (callback) {

          $.get('/platform/teams').done(function (teams) {
            callback(null, teams);
          });
        },

        /**
         * create each team in im db and return all the channels
         * @param teams
         * @param callback
         */
          function (teams, callback) {
          $.ajax({
            url: serverUrl + '/api/channels',
            type: 'PUT',
            data: {
              teams: teams
            },
            dataType: 'json',
            success: function (channels) {
              callback(null, channels);
            },
            error: function () {
              callback('error happen in creating channels');
              return;
            }
          });
        },

        /**
         * for each channel, load its users and insert them into db
         * @param channels
         * @param callback
         */
          function (channels, callback) {
          async.eachSeries(channels, function (channel, cb) {
            $.get('/platform/teams/' + channel.teamId + '/users').done(function (users) {
              $.ajax({
                url: serverUrl + '/api/channels/' + channel.id + '/users',
                type: 'PUT',
                data: {
                  users: users
                },
                dataType: 'json',
                success: function (channels) {
                  debugger;
                  cb(null);
                },
                error: function () {
                  callback('error happen in appending users to channels');
                  return;
                }
              });
            });
          }, function (err) {
            callback();
          });
        }
      ],
      function (err, results) {
        document.querySelector('app-router').go('/' + self.pluginName + '/channels/default');
      }
    );
  }
});
