var User = require('../db/models.js').User
  , Message = require('../db/models.js').Message
  , Channel = require('../db/models.js').Channel;

var async = require('async');

// export function for listening to the socket
module.exports = function (socket) {
  var defaultChannel = 'lobby';
  var userId = 'unknow';
  var self = this;

  socket.on('init', function (data, callback) {
    userId = data.userId;

    console.log(data);

    Channel.find({where : { name : data.channelName}}).then(function(channel) {
      socket.join(channel.id);
      // notify other clients that a new user has joined
      socket.broadcast.to(channel.id).emit('user:join', {
        userId: userId
      });

      // callback(channel);
    });
  });

  // broadcast a user's message to other users
  socket.on('send:message', function (data, callback) {
    Channel.find(data.channelId).then(function (channel) {
      Message.create({message: data.message, 
                      UserId: userId, 
                      ChannelId: channel.id}).then(function (afterCreate) {
        socket.broadcast.to(data.channelId).emit('send:message', {
          userId: userId,
          text: data.message
        });
        var message = {};
        message.userId = userId;
        message.guid = data.guid;
        message.id = afterCreate.dataValues.id;
        callback(message); 
      });
    });
  });

  socket.on('change:room', function (room) {
    if (room.previousRoom !== room.newRoom) {
      socket.broadcast.to(room.previousRoom).emit('user:left', {
        userId: userId
      });
      socket.leave(room.previousRoom);
      socket.broadcast.to(room.newRoom).emit('user:join', {
        userId: userId
      });
      socket.join(room.newRoom);
      console.log('user ' + userId + ' join ' + room.newRoom );
    }
  });

  // clean up when a user leaves, and broadcast it to other users
  socket.on('disconnect', function (data) {
    User.find(data.userId).then(function (user) {
      if (user) {
        user.getChannels().then(function (channels) {
          channels.forEach(function (channel) {
            socket.broadcast.to(channel.dataValues.name).emit('user:left', {
              userId: userId
            });
          });
        });
      }
    });
  });
};
