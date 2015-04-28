# encoding: utf-8
class App < Sinatra::Base
  namespace '/api' do
    get '/teams' do
      Team.all.to_json
    end

    get '/teams/:teamId' do
      Team.find(params[:teamId]).to_json
    end

    get '/teams/:teamId/snapshot' do
      team = Team.find(params[:teamId])
      team.team_snapshots.all.to_json
    end

    post '/teams' do
      team = Team.create!(@body)
      snapshot = TeamSnapshot.create!({:event_type => "create"})
      team.team_snapshots << snapshot
    end

    def get_all_users(team_id)
      result = []

      team = Team.find(team_id)
      result = result | team.users
      member_teams = TeamsRelation.where(:parent_team_id => team_id).pluck(:team_id)
      member_teams.each do |id|
        result = result | get_all_users(id)
      end

      result
    end

    post '/teams/:teamId/delete' do
      Team.delete(params[:teamId])
      200
    end

    #create team with initial users
    post '/teams/users' do
      team = Team.create!(@body["team"])
      snapshot = TeamSnapshot.create!({:event_type => "create"})
      team.team_snapshots << snapshot
      from_user = User.find(@userid)
      from_user.dashboard_records.create!(:content => "You have created a new team : " + team.name, :from_user_id => from_user.id)

      @body["user"].each do |userId|
        user = User.find(userId)
        team.users << user

        snapshot = TeamSnapshot.create!({:event_type => "add_user", :member_user_id => user.id})
        team.team_snapshots << snapshot

        unless userId.equal?(from_user.id)
          user.dashboard_records.create!(:content => from_user.realname + " has added you to team : " + team.name, :from_user_id => from_user.id)
          notification = user.notifications.create!(:content => from_user.realname + " has added you to team : " + team.name, :from_user_id => from_user.id)
          notify = notification.to_json(:except => [:user_id])
          unless settings.sockets[user.id].nil?
            EM.next_tick { settings.sockets[user.id].send(notify) }
          end
        end
      end
      team.to_json
    end

    #get all users in a team
    get '/teams/:teamId/users' do
      # Team.find(params[:teamId]).users.to_json
      get_all_users(params[:teamId]).to_json
    end

    #get all members in a team
    get '/teams/:teamId/members' do

      teams = []
      member_teams = TeamsRelation.where(parent_team_id: params[:teamId]).pluck(:team_id)
      member_teams.each do |team_id|
        teams << Team.find(team_id)
      end

      result = {:users => Team.find(params[:teamId]).users, :teams => teams}
      result.to_json
    end

    post '/teams/:parentTeamId/teams/:teamId' do
      TeamsRelation.create!(:parent_team_id => params[:parentTeamId], :team_id => params[:teamId])
      parent_team = Team.find(params[:parentTeamId])
      snapshot = TeamSnapshot.create!({:event_type => "add team", :member_team_id => params[:teamId]})
      parent_team.team_snapshots << snapshot
    end

    # add a user to a team
    post '/teams/:teamId/users/:userId' do
      team = Team.find(params[:teamId])
      user = User.find(params[:userId])
      team.users << user

      snapshot = TeamSnapshot.create!({:event_type => "add_user", :member_user_id => user.id})
      team.team_snapshots << snapshot
      200
    end

    #add multiple user to a team
    post '/teams/:teamId/users' do
      team = Team.find(params[:teamId])
      @body.each do |userId|
        user = User.find(userId)
        team.users << user

        snapshot = TeamSnapshot.create!({:event_type => "add_user", :member_user_id => user.id})
        team.team_snapshots << snapshot
      end
      200
    end

    #add multiple users and teams to a team
    post '/teams/:teamId/members' do

      teams = @body["teams"]
      users = @body["users"]

      team = Team.find(params[:teamId])

      # add all direct users
      unless users.nil?
        users.each do |userId|
          user = User.find(userId)
          team.users << user

          snapshot = TeamSnapshot.create!({:event_type => "add_user", :member_user_id => userId})
          team.team_snapshots << snapshot
        end
      end

      # add all teams as whole
      unless teams.nil?
        teams.each do |team_id|
          TeamsRelation.create!(:parent_team_id => params[:teamId], :team_id => team_id)
          snapshot = TeamSnapshot.create!({:event_type => "add_team", :member_team_id => team_id})
          team.team_snapshots << snapshot
        end
      end

      200
    end

    #remove a user from team( or a user leaves a team)
    post '/teams/:teamId/users/:userId/remove' do
      team = Team.find(params[:teamId])
      team.users.delete(params[:userId])

      snapshot = TeamSnapshot.create!({:event_type => "remove_user", :member_user_id => params[:userId]})
      team.team_snapshots << snapshot

      user = User.find(params[:userId])
      user.dashboard_records.create!(:content => "You have left team : " + team.name, :from_user_id => params[:userId])

      team.users.each do |member|
        member.dashboard_records.create!(:content => user.realname + " has left team : " + team.name, :from_user_id => params[:userId])
        notification = member.notifications.create!(:content => user.realname + " has left team : " + team.name, :from_user_id => params[:userId])
        notify = notification.to_json(:except => [:user_id])
        unless settings.sockets[member.id].nil?
          EM.next_tick { settings.sockets[member.id].send(notify) }
        end
      end

      200
    end

    get '/profile' do
      profile = {}
      profile["user"] = User.find(@userid)
    end

    get '/users' do
      User.all.to_json(except: [:encrypted_password, :created_at, :updated_at])
    end

    get '/user/invitation/:inviteId' do
      Invitation.find(params[:inviteId]).to_json
    end

    post '/user/invite' do
      email = @body["email"]
      user = User.find(@userid)
      if @body["initial_team_id"].nil?
        invitation = Invitation.create({:email => email, :from_user_id => @userid, :initial_team_id => -1})
        initial_team = "none"
      else
        invitation = Invitation.create({:email => email, :from_user_id => @userid, :initial_team_id => @body["initial_team_id"]})
        initial_team = Team.find(@body["initial_team_id"]).name
      end

      Pony.mail({
                    :to => email,
                    :subject => user.realname + ' invited you to join teamwork',
                    :headers => {'Content-Type' => 'text/html'},
                    :body => 'Hi there, ' + user.realname + ' invited you to join teamwork' +
                        '<br></br><a href="' + 'http://www.team.work' + '/platform/login?invitation=' + invitation.id.to_s + '">Join now</a>' +
                        '<br><pre>(Please add host record 172.26.142.85 www.team.work)</pre>',
                    :via => :smtp,
                    :via_options => {
                        :address => 'smtp.gmail.com',
                        :port => '25',
                        :user_name => 'teamwork.ate@gmail.com',
                        :password => 'ateshanghai',
                        :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
                        :domain => "localhost.localdomain" # the HELO domain provided by the client to the server
                    }
                })

      user.dashboard_records.create!(:content => "You have sent an invitation to " + email + " with initial team : " + initial_team, :from_user_id => user.id)
    end

    get '/user/valid_name/:name' do
      if User.where(name: params[:name]).take.nil?
        "valid"
      else
        "inValid"
      end
    end

    get '/user/valid_email/:email' do
      p User.where(email: params[:email])
      if User.where(email: params[:email]).take.nil?
        "valid"
      else
        "inValid"
      end
    end

    post '/users' do
      if @body["initial_team_id"].nil?
        User.create!(@body)
      else
        team = Team.find(@body["initial_team_id"])
        user_obj = {name: @body['name'], realname: @body['realname'], email: @body['email'], password: @body['password']}
        user = User.create!(user_obj)
        team.users << user

        snapshot = TeamSnapshot.create!({:event_type => "create"})
        team.team_snapshots << snapshot
      end
      200
    end

    #change password
    post '/user/password' do
      user = User.find(@userid)
      if user.password == @body["password"]
        new_password = Password.create(@body["newPassword"])
        User.update(@userid, :encrypted_password => new_password)
        user.dashboard_records.create!(:content => "Your password has been successfully changed", :from_user_id => user.id)
        200
      else
        401
      end
    end

    #update user realname
    post '/user/realname/:new_name' do
      User.update(@userid, :realname => params[:new_name])
      200
    end

    # post '/user/:userId' do
    #   User.update(params[:userId], @body)
    # end

    get '/teams_users' do
      teams_users = []
      teams = Team.all
      teams.each do |team|
        member = {:created_at => team.created_at, :updated_at => team.updated_at, :id => team.id, :name => team.name, :users => get_all_users(team.id)}
        teams_users << member
      end

      teams_users.to_json
    end

    #get all team the user attend
    get '/users/:userId/teams' do
      result = []
      teams = User.find(params[:userId]).teams
      teams.each do |team|
        result = result | [Team.find(team.id)]
        parent_teams = TeamsRelation.where(team_id: team.id).pluck(:parent_team_id)
        parent_teams.each do |parent_id|
          result = result | [Team.find(parent_id)]
        end
      end

      result.to_json
    end
  end
end