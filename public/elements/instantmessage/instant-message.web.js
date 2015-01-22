var hostname = window.location.hostname;
var serverUrl = 'http://' + hostname + ':3000';
var defaultChannel = 'default';


Polymer({
  boxTapped: function () {
    this.$.textInput.focus();
  },
  messages: [],
  connectinStatus: "connecting",

  ready: function () {
    // Init the plugin name
    this.pluginName = 'instantmessage';

    // the users in this room
    this.users = [];

    this.scrollToBottom(100);

    var self = this;

    window.onkeypress = function (event) {
      if (event.keyCode === 13 && self.message === '') {
        event.preventDefault();
        return;
      }
      if (event.shiftKey && event.keyCode === 13) {
        return;
      }
      if (!event.shiftKey && event.keyCode === 13) {
        self.sendMessage();
        event.preventDefault();
        return;
      }
      self.$.textInput.focus();
    }
  },

  /**
   * Only in domReady the userId is filled
   */
  domReady: function () {

    var self = this;

    $.get('/platform/loggedOnUser').fail(function () {
      document.querySelector('app-router').go('/');
      callback('not login');
      return;
    }).done(function (user) {

      self.currentUser = user;

      $.post(serverUrl + '/api/users', {
        id: self.currentUser.id,
        name: self.currentUser.name
      }).done(function (user) {
        async.waterfall([
          /**
           * load socket.io.js
           * @param callback
           */
            function (callback) {
            $.getScript(serverUrl + '/socket.io/socket.io.js').done(function () {
              callback();
            }).fail(function () {
              self.connectinStatus = "Cannot connect to server. Please refresh.";
              callback(self.connectinStatus);
            });
          },

          /**
           * load the channels current user has
           * @param callback
           */
            function (callback) {
            self.loadChannels().done(function () {
              if (self.group.length === 0 ) {
                // ask administrator
                self.$.noGroupDlg.open();
                callback('no groups found for current user');
                return;
              } else if (self.channelName === defaultChannel) {
                // by default using the default setting, later use localstorage
                self.channelName = self.group[0].name;
                document.querySelector('app-router').go('/' + self.pluginName + '/channels/' + self.channelName);
              } else {
                callback();
              }
            });
          },

          /**
           * try to initialize current channel (if it is private, it might not be created in db)
           * @param callback
           */
            function (callback) {
            callback();
          },

          /**
           * get current channel
           * @param callback
           */
            function (callback) {
            self.getChannel(self.channelName, self.currentUser.id, self.channelName.indexOf('@') === 0).done(function (channel) {
              if (!channel) {
                // the channel not exists
                callback('the channel not exists');
                return;
              }
              self.channel = channel;

              callback(null, channel);

            });
          },

          /**
           * extra operation if the channel is private
           * @param channel
           * @param callback
           */
            function (channel, callback) {
            if (!channel.isPrivate) {
              console.log('current channel is not private');
              callback();
            } else {
              console.log('current channel is private');
              // if this channel is not in the direct message group, just add it
              if (!_.find(self.private, {id: channel.id})) {
                self.private.splice(0, 0, channel);

                // and get its displayname
                self.loadChannelUsers(channel.id).done(function (users) {
                  users.forEach(function (user) {
                    if (user.id !== self.currentUser.id) {
                      channel.displayName = user.name;
                    }
                  });
                  callback();
                });

              } else {
                callback();
              }
            }
          },

          /**
           * load history
           * @param callback
           */
            function (callback) {
            self.loadHistory(self.channel.id).done(function () {
              callback();
            });
          },

          /**
           * init socket
           * @param callback
           */
            function (callback) {
            self.$.connectingDialog.open();
            self.initSocket();
            callback();
          }

        ], function (err, result) {
          if (err) {
            console.log('Error : ' + err);
          }
        });
      });
    });
  },

  initSocket: function () {
    var self = this;
    self.socket = io(serverUrl).connect();
    self.socket.on('connect', function () {
      self.$.connectingDialog.close();
      self.socket.emit('init', {
        userId: self.currentUser.id,
        channelName: self.channel.name
      });
    });

    self.socket.on('send:message', function (message) {
      if (self.messages.length > 0){
        message.hideMemberElement = 
          self.isHideMemberElement(self.messages[self.messages.length -1], message);
      }
      self.messages.push(message);
      self.$.messageInput.update();
      var objDiv = self.$.history;
      self.scrollToBottom(100);
    });

    self.socket.on('user:join', function (data) {
      // do some other things
    });

    self.socket.on('user:left', function (data) {
      self.messages.push({
        text: 'User ' + data.userId + ' has left.'
      });
    });
    self.socket.on('disconnect', function () {
      self.$.connectingDialog.open();
      self.connectinStatus = "disconnected.";
    });

    self.socket.on('reconnecting', function (number) {
      self.$.connectingDialog.open();
      self.connectinStatus = "reconnecting... (" + number + ")";
    });
    self.socket.on('reconnecting_failed', function () {
      self.$.connectingDialog.open();
      self.connectinStatus = "reconnecting failed.";
    });
    self.socket.on('reconnect', function () {
      self.$.connectingDialog.open();
      self.connectinStatus = "connected";
    });
  },

  showTeamMemberDialog: function (event, detail, target) {
    var self = this;
    var channel = target.templateInstance.model.g;
    $.get('/platform/teams/' + channel.teamId + '/users').done(function(users) {
      self.teamMembers = users;
    }).done(function() {
      target.querySelector('paper-dialog')&&target.querySelector('paper-dialog').open();
    });

  },

  positionTeamMemberDialog : function(event, detail, target) {
    target.dimensions.position = { v : 'top', h : 'left'};

    var rect = target.parentElement.getBoundingClientRect();
    target.style.top = '' + rect.top + 'px';
    target.style.left = '' + (rect.left - 200) + 'px';
  },

  talkDirect : function(event, detail, target) {
    target.parentElement&&target.parentElement.close();
    document.querySelector('app-router').go('/' + this.pluginName + '/channels/@' + target.templateInstance.model.u.name);
  },

  loadChannels: function () {
    var self = this;
    return $.get(serverUrl + '/api/users/' + self.currentUser.id + '/channels').done(function (channels) {
      self.private = [];
      self.group = [];
      channels.forEach(function (channel) {
        if (channel.isPrivate) {
          self.loadChannelUsers(channel.id).done(function (users) {
            users.forEach(function (user) {
              if (user.id !== self.currentUser.id) {
                channel.displayName = user.name;
              }
            })
          });
          self.private.push(channel);
        } else {
          self.group.push(channel);
        }
      });
    });
  },

  isHideMemberElement: function(lastMessage, newMessage){
    if (!lastMessage || ! newMessage){
      return false;
    }
    var lastUserId = lastMessage.UserId;
    if (!lastUserId){
      lastUserId = lastMessage.userId;
    }
    var newUserId = newMessage.UserId;
    if (!newUserId){
      newUserId = newMessage.userId;
    }
    if (!lastMessage || !lastUserId || !newUserId || 
      !newMessage.updatedAt || !lastMessage.updatedAt){
      return false;
    }
    if (lastUserId === newUserId && 
      new Date(newMessage.updatedAt).getTime() - new Date(lastMessage.updatedAt).getTime() < 60*1000){
      return true;
    } 
    return false;
  },
  historyLimit: 10,
  noMoreHistory: false,

  reachedTop: function (event){
    if (this.noMoreHistory){
      return;
    }
    if (this.messages.length < 1){
      return;
    }
    if (this.messages[0].id == null){
      return;
    }
    var self = this;
    return $.get(serverUrl + '/api/channels/' + self.channel.id + 
      '/messages?beforeId='+this.messages[0].id+
      '&limit=' + this.historyLimit).done(function (messages) {
        self.historyOffset += self.historyLimit;
        if (messages.length < self.historyLimit){
          self.noMoreHistory = true;
        }
        var temp = [];
        var lastMessage = null;
        messages.forEach(function (message) {
          temp.push({
                     id: message.id,
                     userId: message.UserId, 
                     text: message.message, 
                     updatedAt: message.updatedAt, 
                     disableLoadedEvent: true, 
                     disableReadyEvent: true, 
                     hideMemberElement: self.isHideMemberElement(lastMessage, message)});
          lastMessage = message;
        });
        self.messages = temp.concat(self.messages);

    });
  },

  loadHistory: function (roomId) {
    var self = this;

    return $.get(serverUrl + '/api/channels/' + self.channel.id + '/messages?limit=30').done(function (messages) {
      var temp = [];
      var lastMessage = null;
      messages.forEach(function (message) {
        temp.push({
                   id: message.id,
                   userId: message.UserId, 
                   text: message.message, 
                   updatedAt: message.updatedAt,
                   hideMemberElement: self.isHideMemberElement(lastMessage, message)});
        lastMessage = message;
      });
      self.messages = temp.concat(self.messages);

      self.scrollToBottom(100);
    }).done(function(){
      setTimeout(function(){
        self.$.infiniteScroll.startObserve();
      }, 1000);
    });
  },

  loadChannelUsers: function (channelId) {
    var self = this;
    return $.get(serverUrl + '/api/channels/' + channelId + '/users');
  },

  getChannel: function (channelName, fromUserId, isPrivate, teamId) {
    return $.get(serverUrl + '/api/channels?name=' + channelName + '&from=' + fromUserId + '&isPrivate=' + isPrivate);
  },

  goToDefaultChannel: function () {
    var querySelector = this.$.groupChannel.querySelector('paper-item');
    if (querySelector) {
      querySelector.click()
    }
  },

  goToConfig : function() {
    document.querySelector('app-router').go('/' + this.pluginName + '/config');
  },

  goToIndex : function() {
    document.querySelector('app-router').go('/dashboard');
  },

  handleChannelSelect: function (event, detail, target) {
    // exit current room
    var self = this;

    if (target.templateInstance.model.g.id === self.channel.id) {
      return;
    }

    var hash = target.attributes['hash'].value;
    document.querySelector('app-router').go('/' + this.pluginName + '/channels/' + hash);

    this.socket.emit('change:room', {
      newRoom: target.templateInstance.model.g.id,
      previousRoom: self.channel.id
    });
  },
  keyDown: function (event, detail, target) {
    var history = this.$.history;
    target.atBottom = history.scrollTop == history.scrollHeight - history.clientHeight;
  },
  inputChanging: function (event, detail, target) {
    var history = this.$.history;
    // if already bottom
    if (target.atBottom) {
      history.scrollTop = history.scrollHeight;
    }
  },
  scrollToBottom: function (delay) {
    var self = this;
    setTimeout(function () {
      self.$.history.scrollTop = self.$.history.scrollHeight;
    }, delay);
  },
  sendMessage: function () {
    var self = this;
    var uuid = this.guid();
    // add the message to our model locally
    this.messages.push({
      userId: self.currentUser.id,
      text: self.message,
      guid: uuid,
      messageStatus: 'unsend', 
      hideMemberElement: true
    });
    this.scrollToBottom(100);
    this.socket.emit('send:message', {
      message: self.message,
      channelId: self.channel.id,
      guid: uuid
    }, function (message) {
      for (var i = self.messages.length - 1; i >= 0; i--) {
        if (self.messages[i].guid === message.guid) {
          self.messages[i] = message;
          if (i -1 >=0){
            self.messages[i].hideMemberElement  = 
              self.isHideMemberElement(self.messages[i-1], message);
          }
          break;
        }
      }
    });
    this.message = '';
    this.$.messageInput.update();

  },
  guid: function () {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
      var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  },

  messageReady: function (event) {
    this.scrollToBottom(100);
  },

  messageLoaded: function (event) {
    this.scrollToBottom(100);
  },

  roomId: ''
});

