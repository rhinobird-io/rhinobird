/**
 * Module dependencies.
 */

var express = require('express'),
  socket = require('./routes/socket.js')
  , User = require('./db/models.js').User
  , Message = require('./db/models.js').Message
  , Channel = require('./db/models.js').Channel
  , ogp = require("open-graph")
  , _ = require('lodash');

var async = require('async');


var app = module.exports = express.createServer();

// Hook Socket.io into Express
var io = require('socket.io').listen(app);


var allowCrossDomain = function (req, res, next) {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Content-Length, X-Requested-With');

  // intercept OPTIONS method
  if ('OPTIONS' == req.method) {
    res.send(200);
  }
  else {
    next();
  }
};

// Configuration

app.configure(function () {
  app.use(allowCrossDomain);
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(express.static(__dirname + '/public'));
  app.use(app.router);
});

app.configure('development', function () {
  app.use(express.errorHandler({dumpExceptions: true, showStack: true}));
});

app.configure('production', function () {
  app.use(express.errorHandler());
});

// Routes
app.get('/api/users/:userId/channels', function (req, res) {
  User.find(req.params.userId).then(function (user) {
    if (user) {
      user.getChannels().then(function (channels) {
        res.json(channels);
      });
    }
  });
});

app.get('/api/channels/:channelId/messages', function (req, res) {
  var offset = 0;
  var limit = 10;
  if (req.query.offset) {
    offset = req.query.offset;
  }
  if (req.query.limit) {
    limit = req.query.limit;
  }
  Message.findAndCountAll({
    where: {channelId: req.params.channelId}, order: 'createdAt DESC, id DESC', offset: offset, limit: limit
  }).then(function (messages) {
    res.json(_(messages.rows).reverse().value());
  });
});

app.get('/api/channels/:channelId/users', function (req, res) {
  Channel.find(req.params.channelId).then(function (channel) {
    channel.getUsers().then(function (users) {
      res.json(users);
    });
  });
});

app.post('/api/channels/:channelId/users', function (req, res) {
  var userId = req.body.userId;
  Channel.find(req.params.channelId).then(function (channel) {
    User.find(userId).then(function (user) {
      channel.addUser(user).then(function () {
        channel.getUsers().then(function (users) {
          res.json(users);
        });
      });
    });
  });
});


app.get('/api/channels', function (req, res) {
  var isPrivate = req.query.isPrivate === 'true';
  var userId = req.query.from;
  var channelName = req.query.name;

  if (isPrivate) {
    User.find({where: {name: channelName.substr(1)}}).then(function (user) {
      if (!user) {
        console.log('user ' + channelName.substr(1) + ' is not in the im db');
        res.json(null);
        return;
      }
      var minId = user.id > userId ? userId : user.id;
      var maxId = user.id > userId ? user.id : userId;
      Channel.findOrCreate({where: {name: '' + minId + ':' + maxId, 'isPrivate': true}}).then(function (channels) {
        var channel = channels[0];
        async.parallel([
          function (callback) {
            User.find(minId).then(function (user) {
              channel.addUser(user);
              callback(user);
            })
          },
          function (callback) {
            User.find(maxId).then(function (user) {
              channel.addUser(user);
              callback(user);
            })
          }
        ], function (err, results) {
          res.json(channel);
        });
      });
    });
  } else {
    Channel.find({where: {name: channelName}}).then(function (channel) {
      res.json(channel);
    });
  }
});

app.post('/api/channels', function (req, res) {
  var isPrivate = (req.body.isPrivate === 'true');
  var userId = req.body.from;
  var channelName = req.body.name;
  var teamId = req.body.teamId;
  if (isPrivate) {
    User.find({where: {name: channelName.substr(1)}}).then(function (user) {
      var minId = user.id > userId ? userId : user.id;
      var maxId = user.id > userId ? user.id : userId;
      Channel.findOrCreate({where: {name: '' + minId + ':' + maxId, 'isPrivate': true}}).then(function (channels) {
        var channel = channels[0];
        async.parallel([
          function (callback) {
            User.find(minId).then(function (user) {
              channel.addUser(user);
              callback(user);
            })
          },
          function (callback) {
            User.find(maxId).then(function (user) {
              channel.addUser(user);
              callback(user);
            })
          }
        ], function (err, results) {
          res.json(channel);
        });
      });
    });
  } else {
    Channel.count({where: {teamId: teamId}}).then(function (channelCount) {
      if (0 === channelCount) {
        // create this team
        Channel.create({name: channelName, teamId: teamId, 'isPrivate': false}).then(function (channel) {
          console.log('create channel : ' + channel);
          res.json(channel);
        });
      } else {
        Channel.find({ where : {teamId: teamId, 'isPrivate': false} }).then(function (channel) {
          console.log('found channel : ' + channel);
          res.json(channel);
        });
      }
    });
  }
});


app.post('/api/users', function (req, res) {
  var userId = req.body.id;
  var name = req.body.name;
  User.count({where: {id: userId}}).then(function (count) {
    if (count === 0) {
      // create a new user
      User.create({name: name, id: userId}).then(function (user) {
        res.json(user);
      });
    } else {
      User.find(userId).then(function (user) {
        res.json(user);
      });
    }
  });
});

app.get('/api/urlMetadata', function (req, res) {
  ogp(req.query['url'], function (error, data) {
    if (error) {
      return;
    }
    res.send(data);
  });
});

app.get('*', function (req, res) {
  res.sendfile('index.html', {root: __dirname + '/public'});
});


// Socket.io Communication

io.sockets.on('connection', socket);

// Start server

app.listen(3000, function () {
  console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);
});
