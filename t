[1mdiff --git a/app.rb b/app.rb[m
[1mindex 52fe389..a777f9b 100644[m
[1m--- a/app.rb[m
[1m+++ b/app.rb[m
[36m@@ -1,6 +1,7 @@[m
 require 'sinatra/base'[m
 require 'sinatra/activerecord'[m
 require 'sinatra/namespace'[m
[32m+[m[32mrequire 'sinatra/config_file'[m
 require 'rest_client'[m
 require 'pony'[m
 require 'bcrypt'[m
[36m@@ -10,17 +11,19 @@[m [mrequire 'faye/websocket'[m
 require 'resque'[m
 require 'mail'[m
 require 'sinatra/redis'[m
[31m-require 'week_of_month'[m
[32m+[m[32mrequire 'sinatra/config_file'[m
 require 'json'[m
 [m
 Faye::WebSocket.load_adapter('thin')[m
 [m
 class App < Sinatra::Base[m
[32m+[m[32m  register Sinatra::ConfigFile[m
[32m+[m
[32m+[m[32m  config_file './config/platform.yml'[m
 [m
   configure :production do[m
     set :script_url, '/platform/_assets/main.js'[m
     set :css_url, '/platform/_assets/main.css'[m
[31m-    set :platform_url, 'www.rhinobird.workslan/platform'[m
 [m
     redis_url = ENV['REDISCLOUD_URL'] || ENV['OPENREDIS_URL'] || ENV['REDISGREEN_URL'] || ENV['REDISTOGO_URL'][m
     uri = URI.parse(redis_url)[m
[36m@@ -32,7 +35,6 @@[m [mclass App < Sinatra::Base[m
   configure :development do[m
     set :script_url, 'http://localhost:2992/_assets/main.js'[m
     set :css_url, ''[m
[31m-    set :platform_url, 'localhost:8000/platform'[m
 [m
     redis_url = 'redis://localhost:6379'[m
     uri = URI.parse(redis_url)[m
[1mdiff --git a/routes/calendar.rb b/routes/calendar.rb[m
[1mindex 8850b9b..e745db2 100644[m
[1m--- a/routes/calendar.rb[m
[1m+++ b/routes/calendar.rb[m
[36m@@ -2,11 +2,12 @@[m
 require 'erb'[m
 [m
 class EventToComeEmailContent[m
[31m-  attr_reader :user, :event[m
[32m+[m[32m  attr_reader :user, :event, :url[m
 [m
[31m-  def initialize(user, event)[m
[32m+[m[32m  def initialize(user, event, url)[m
     @user = user[m
     @event = event[m
[32m+[m[32m    @url = url[m
   end[m
 [m
   def get_binding[m
[36m@@ -63,7 +64,7 @@[m [mdef send_event_notifications(e, dashboard_message, dashboard_link, notification_[m
     notify = notification.to_json(:except => [:user_id])[m
 [m
 [m
[31m-    controller = EventToComeEmailContent.new(u, e)[m
[32m+[m[32m    controller = EventToComeEmailContent.new(u, e, settings.url)[m
     notify([m
         u,[m
         notify,[m
[1mdiff --git a/views/email/event_created.erb b/views/email/event_created.erb[m
[1mindex ca824c7..cda7267 100644[m
[1m--- a/views/email/event_created.erb[m
[1m+++ b/views/email/event_created.erb[m
[36m@@ -13,35 +13,35 @@[m
   <div style="font-size: 1.2em">[m
     <strong><%= creator.realname %></strong> invited you to event[m
     <a style="color: rgb(255, 64, 129); font-weight: 600;"[m
[31m-       href='<%= "#{request.env['rack.url_scheme']}://#{settings.platform_url}"%>/calendar/events/<%= event.id %>/1'><%= event.title %></a>.[m
[31m-    <hr/>[m
[31m-    <table>[m
[31m-      <tbody>[m
[31m-        <tr>[m
[31m-          <td class="title">Time</td>[m
[31m-          <td><%= event.time_summary %></td>[m
[31m-        </tr>[m
[31m-        <tr>[m
[31m-          <td class="title">Details</td>[m
[31m-          <td><%= event.description %></td>[m
[31m-        </tr>[m
[31m-        <tr>[m
[31m-          <td class="title">Participants</td>[m
[31m-          <td><%= event.participants_summary %></td>[m
[31m-        </tr>[m
[31m-        <%[m
[31m-           if event.repeated[m
[31m-        %>[m
[32m+[m[32m       href='<%= "#{request.env['rack.url_scheme']}://#{settings.url}"%>/calendar/events/<%= event.id %>/1'><%= event.title %></a>.[m
[32m+[m[32m  </div>[m
[32m+[m[32m  <br/>[m
[32m+[m[32m  <table>[m
[32m+[m[32m    <tbody>[m
[32m+[m[32m    <tr>[m
[32m+[m[32m      <td class="title">Time</td>[m
[32m+[m[32m      <td><%= event.time_summary %></td>[m
[32m+[m[32m    </tr>[m
[32m+[m[32m    <tr>[m
[32m+[m[32m      <td class="title">Details</td>[m
[32m+[m[32m      <td><%= event.description %></td>[m
[32m+[m[32m    </tr>[m
[32m+[m[32m    <tr>[m
[32m+[m[32m      <td class="title">Participants</td>[m
[32m+[m[32m      <td><%= event.participants_summary %></td>[m
[32m+[m[32m    </tr>[m
[32m+[m[32m    <%[m
[32m+[m[32m       if event.repeated[m
[32m+[m[32m    %>[m
         <tr>[m
           <td class="title">Will Repeat</td>[m
           <td><%= event.get_repeated_summary %></td>[m
         </tr>[m
[31m-        <%[m
[31m-           end[m
[31m-        %>[m
[31m-      </tbody>[m
[31m-    </table>[m
[31m-    <hr>[m
[31m-    <p style="text-align: center;">Made by ATE-Shanghai, © Works Applications Co.,Ltd.</p>[m
[31m-  </div>[m
[32m+[m[32m    <%[m
[32m+[m[32m       end[m
[32m+[m[32m    %>[m
[32m+[m[32m    </tbody>[m
[32m+[m[32m  </table>[m
[32m+[m[32m  <hr>[m
[32m+[m[32m  <p style="text-align: center;">Made by ATE-Shanghai, © Works Applications Co.,Ltd.</p>[m
 </div>[m
[1mdiff --git a/views/email/event_to_come.erb b/views/email/event_to_come.erb[m
[1mindex 327b8b3..c85ccdb 100644[m
[1m--- a/views/email/event_to_come.erb[m
[1m+++ b/views/email/event_to_come.erb[m
[36m@@ -1,5 +1,6 @@[m
 <style>[m
 	table tr td {[m
[32m+[m		[32mfont-size: 0.9em;[m
 		padding: 4px 8px;[m
 	}[m
 	table tr td.title {[m
[36m@@ -12,7 +13,7 @@[m
   <div style="font-size: 1.2em">[m
 	Your event[m
 	  <a style="color: rgb(255, 64, 129); font-weight: 600;"[m
[31m-					 href='http://www.rhinobird.workslan/platform/calendar/events/<%= event.id %>/<%= event.repeated_number %>'>[m
[32m+[m					[32m href='http://<%= url%>/calendar/events/<%= event.id %>/<%= event.repeated_number %>'>[m
 		<%= event.title %>[m
 	  </a>[m
 	  will begin within 30 minutes.[m
