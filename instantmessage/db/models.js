var Sequelize = require('sequelize')
  , sequelize = new Sequelize('database', 'username', 'password', {
    dialect: "sqlite",
    storage: "./im.db",
    pool: {
      max: 5,
      min: 0,
      idle: 10000
    }
  })
  , async = require('async');

var User = sequelize.define('User', {
  id: {
    type: Sequelize.INTEGER,
    unique: true,
    primaryKey: true
  },
  name : Sequelize.STRING
});

var Channel = sequelize.define('Channel', {
  name: {
    type: Sequelize.STRING,
    unique: true
  },
  teamId : Sequelize.INTEGER,
  'private': Sequelize.BOOLEAN
});

var Message = sequelize.define('Message', {
  message: Sequelize.TEXT, 
  guid: Sequelize.UUID
});

User.belongsToMany(Channel);
Channel.belongsToMany(User);

Message.belongsTo(User);
Message.belongsTo(Channel);


module.exports = {
  User: User,
  Message: Message,
  Channel: Channel,

  sync: function () {
    return sequelize.sync({force: true}).then(function () {
      console.log('finish sync');
    });
  },

  /**
   * inject some data into database
   */
  populate: function () {

    return User.bulkCreate([
      {id: 1, name: 'Curry'},
      {id: 2, name: 'Chad'},
      {id: 6, name: 'Tom'}
    ]).then(function () {
      var channels = [];
      async.series([
        function (callback) {
          Channel.create({name: 'lobby', teamId:1, 'private': false}).then(function (channel) {
            callback(null, channel);
          });
        },
        function (callback) {
          Channel.create({name: 'ate', teamId:1, 'private': false}).then(function (channel) {
            callback(null, channel);
          });
        },
        function (callback) {
          Channel.create({name: 'cws', teamId:1, 'private': false}).then(function (channel) {
            callback(null, channel);
          });
        },
        function (callback) {
          Channel.create({name: '1:2', teamId:-1, 'private': true}).then(function (channel) {
            callback(null, channel);
          });
        }
      ], function (err, results) {
        User.find(1).then(function (user) {
          results.forEach(function (channel) {
            user.addChannel(channel).then(function () {
              console.log('channel ' + channel.dataValues.name + ' add to ' + user.dataValues.id);
            });
          });
        });

        User.find(2).then(function (user) {
          user.addChannel(results[0]).then(function () {
            console.log('channel ' + results[0].dataValues.name + ' add to ' + user.dataValues.id);
          });
          user.addChannel(results[3]);
        });
      });
    })
  }
};