var User = require('./models.js').User;

User.findOrCreate({where : { id : 1}}).then(function(users) {
  users[0].getChannels().then(function(channels){
    console.log(channels[0]);
  });

});