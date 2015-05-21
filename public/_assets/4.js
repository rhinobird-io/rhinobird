webpackJsonp([4],{570:function(e,t,n){"use strict";var r=function(e){return e&&e.__esModule?e["default"]:e},i=r(n(93)),o=r(n(97));e.exports={updateUserData:function(){i.dispatch({type:o.ActionTypes.USER_UPDATE})}}},655:function(e,t,n){"use strict";var r=n(111),i=n(260),o=n(300),a=(n(464),n(390)),s=i.Link,u=(i.Navigation,n(441).Selector,n(391)),c=(n(656),n(437).MemberSelect),l=n(92),p=n(570);n(658),e.exports=r.createClass({displayName:"index",mixins:[r.addons.LinkedStateMixin],contextTypes:{router:r.PropTypes.func.isRequired},errorMsg:{titleRequired:"Event title is required.",descriptionRequired:"Event description is required."},componentDidMount:function(){this.refs.teamName.focus()},getInitialState:function(){return{}},render:function(){({repeated:{overflow:"hidden",transition:"all 500ms",opacity:this.state.editRepeated?1:0,width:this.state.editRepeated?"552px":"0",height:"100%"}});return r.createElement(u,{style:{height:"100%",position:"relative"}},r.createElement(a.Layout,{horizontal:!0,centerJustified:!0,wrap:!0},r.createElement("form",{onSubmit:this._handleSubmit},r.createElement(o.Paper,{zDepth:3,className:"create-team"},r.createElement("div",{style:{padding:24,width:400}},r.createElement("h3",null,"Create Team"),r.createElement(o.TextField,{ref:"teamName",hintText:"Team name",floatingLabelText:"Name",errorText:this.state.nameError,valueLink:this.linkState("name"),className:"create-team-textfield"}),r.createElement(c,{label:"Parent teams",errorText:this.state.graphError,valueLink:this.linkState("parentTeams"),user:!1,className:"create-team-textfield"}),r.createElement(c,{label:"Subsidiary teams",errorText:this.state.graphError,valueLink:this.linkState("subTeams"),user:!1,className:"create-team-textfield"}),r.createElement(c,{label:"Direct members",valueLink:this.linkState("members"),team:!1,className:"create-team-textfield"}),r.createElement(a.Layout,{horizontal:!0,justified:!0},r.createElement(s,{to:"team"},r.createElement(o.RaisedButton,{label:"Cancel"})),r.createElement(o.RaisedButton,{type:"submit",label:"Create Team",primary:!0})))))))},_handleSubmit:function(e){var t=this;return e.preventDefault(),this.setState({nameError:void 0,graphError:void 0}),this.state.name?l.checkDAG({parentTeams:this.state.parentTeams,teams:this.state.subTeams})?void $.post("/platform/api/teams",{name:this.state.name,parentTeams:this.state.parentTeams,teams:this.state.subTeams,members:this.state.members}).then(function(){p.updateUserData(),t.context.router.transitionTo("/platform/team")}).fail(function(){}):void this.setState({graphError:"Cyclic team structure detected"}):void this.setState({nameError:"Name should not be empty"})}})},656:function(e,t,n){"use strict";var r=n(93),i=n(97).CalendarActionTypes;n(657),e.exports={receive:function(e){$.get("/platform/api/events").done(function(t){r.dispatch({type:i.RECEIVE_EVENTS,data:t}),e&&"function"==typeof e&&e()}).fail(function(e){console.error(e)})},receiveSingle:function(e,t){$.get("/platform/api/events/"+e+"/"+t).done(function(e){r.dispatch({type:i.RECEIVE_EVENT,data:e})}).fail(function(e){console.error(e)})},loadMoreOlderEvents:function(e,t,n){$.get("/platform/api/events/before/"+e).done(function(e){r.dispatch({type:i.LOAD_MORE_OLDER_EVENTS,data:e}),t&&"function"==typeof t&&t()}).fail(function(e){console.error(e)})},loadMoreNewerEvents:function(e,t,n){$.get("/platform/api/events/after/"+e).done(function(e){r.dispatch({type:i.LOAD_MORE_NEWER_EVENTS,data:e})}).fail(function(e){404==e.status})},create:function(e,t,n){var o={},a=new Date(e.fromTime),s=new Date(e.toTime);o.title=e.title,o.description=e.description,o.full_day=e.fullDay,o.full_day||(a.setHours(e.fromHour),a.setMinutes(e.fromMinute)),e.isPeriod?(o.period=!0,s.setHours(e.toHour),s.setMinutes(e.toMinute)):(o.period=!1,s=a),o.from_time=a.toISOString(),o.to_time=s.toISOString(),o.participants=e.participants,e.repeated?(o.repeated=!0,o.repeated_type=e.repeatedType,o.repeated_frequency=e.repeatedFrequency,o.repeated_on=e.repeatedOn,o.repeated_by=e.repeatedBy,o.repeated_times=e.repeatedTimes,o.repeated_end_type=e.repeatedEndType,o.repeated_end_date=e.repeatedEndDate):o.repeated=!1,$.post("/platform/api/events",o).done(function(e){r.dispatch({type:i.CREATE_EVENT,data:e}),t&&"function"==typeof t&&t()}).fail(function(e){console.error(e)})}}},657:function(e,t,n){"use strict";e.exports=function(){if(!$.mockjax)return!1;var e="/platform/api";$.mockjax({url:e+"/events",type:"GET",responseText:[{from_time:"2015-03-12T07:18:33.540Z",repeated:!1,id:38,title:"B",full_day:!1,period:!0,description:null,created_at:"2015-03-12T07:16:37.068Z",updated_at:"2015-03-12T07:16:37.068Z",creator_id:6,to_time:"2015-03-12T07:18:33.540Z",repeated_type:null,repeated_frequency:null,repeated_on:null,repeated_by:null,repeated_times:null,repeated_end_type:null,repeated_end_date:null,repeated_number:1,participants:[],team_participants:[{id:8}]},{from_time:"2015-04-27T07:52:20.632Z",repeated:!0,repeated_end_type:0,repeated_type:"Daily",repeated_frequency:1,id:39,title:"Repeated Test",full_day:!1,period:!0,description:null,created_at:"2015-03-12T07:50:23.269Z",updated_at:"2015-03-12T07:50:23.269Z",creator_id:6,to_time:"2015-05-06T07:52:20.632Z",repeated_on:'["Thu"]',repeated_by:"Month",repeated_times:10,repeated_end_date:null,repeated_number:56,participants:[{id:6}],team_participants:[]},{from_time:"2015-03-03T07:52:20.632Z",repeated:!0,repeated_end_type:0,repeated_type:"Daily",repeated_frequency:1,to_time:"2015-03-12T07:52:20.632Z",id:39,title:"Repeated Test",full_day:!1,period:!0,description:null,created_at:"2015-03-12T07:50:23.269Z",updated_at:"2015-03-12T07:50:23.269Z",creator_id:6,repeated_on:'["Thu"]',repeated_by:"Month",repeated_times:10,repeated_end_date:null,repeated_number:1,participants:[{id:6}],team_participants:[]},{from_time:"2015-04-27T02:00:00.000Z",repeated:!0,repeated_end_type:0,repeated_type:"Daily",repeated_frequency:1,id:35,title:"Stand up meeting",full_day:!1,period:!0,description:"ATE Stand up meeting",created_at:"2015-03-12T02:32:44.369Z",updated_at:"2015-03-12T02:32:44.369Z",creator_id:1,to_time:"2015-04-27T02:15:00.000Z",repeated_on:'["Thu"]',repeated_by:"Week",repeated_times:10,repeated_end_date:"2015-04-11T02:34:46.789Z",repeated_number:47,participants:[],team_participants:[{id:2}]},{from_time:"2015-03-12T02:00:00.000Z",repeated:!0,repeated_end_type:0,repeated_type:"Daily",repeated_frequency:1,to_time:"2015-03-12T02:15:00.000Z",id:35,title:"Stand up meeting",full_day:!1,period:!0,description:"ATE Stand up meeting",created_at:"2015-03-12T02:32:44.369Z",updated_at:"2015-03-12T02:32:44.369Z",creator_id:1,repeated_on:'["Thu"]',repeated_by:"Week",repeated_times:10,repeated_end_date:"2015-04-11T02:34:46.789Z",repeated_number:1,participants:[],team_participants:[{id:2}]}]}),$.mockjax({url:e+"/events/before",type:"GET",responseText:[{from_time:"2015-02-05T04:00:00.000Z",id:4,title:"Discuss about 0.2 release",full_day:!1,period:!0,description:'Discuss the tasks we should do on 0.2 release.\n\nEspecially about "task & issue tracking" function. Also about remaining IM issues and the priority.\n\nEveryone, please prepare your remaining ticket list before the meeting.\n\nWe can use PC to access Gitlab and check our issues.',created_at:"2015-02-05T02:54:05.356Z",updated_at:"2015-02-05T02:54:05.356Z",creator_id:1,to_time:"2015-02-05T05:00:00.000Z",repeated:!1,repeated_type:null,repeated_frequency:null,repeated_on:null,repeated_by:null,repeated_times:null,repeated_end_type:null,repeated_end_date:null,participants:[{id:2},{id:1},{id:3},{id:4},{id:5},{id:6},{id:10}],team_participants:[]},{from_time:"2015-02-06T07:00:00.000Z",id:12,title:"Division of work for v0.2-alpha",full_day:!1,period:!0,description:"",created_at:"2015-02-06T04:32:42.970Z",updated_at:"2015-02-06T04:32:42.970Z",creator_id:1,to_time:"2015-02-06T08:00:00.000Z",repeated:!1,repeated_type:null,repeated_frequency:null,repeated_on:null,repeated_by:null,repeated_times:null,repeated_end_type:null,repeated_end_date:null,participants:[{id:2},{id:1},{id:3},{id:4},{id:5},{id:6},{id:10},{id:12}],team_participants:[]},{from_time:"2015-02-27T08:26:00.000Z",id:14,title:"test",full_day:!1,period:!0,description:null,created_at:"2015-02-27T08:13:59.671Z",updated_at:"2015-02-27T08:13:59.671Z",creator_id:6,to_time:"2015-02-27T08:26:00.000Z",repeated:!1,repeated_type:null,repeated_frequency:null,repeated_on:null,repeated_by:null,repeated_times:null,repeated_end_type:null,repeated_end_date:null,participants:[{id:6}],team_participants:[]},{from_time:"2015-02-27T08:27:00.000Z",id:15,title:"aaaa123123123",full_day:!1,period:!0,description:null,created_at:"2015-02-27T08:14:42.313Z",updated_at:"2015-02-27T08:14:42.313Z",creator_id:6,to_time:"2015-02-27T08:27:00.000Z",repeated:!1,repeated_type:null,repeated_frequency:null,repeated_on:null,repeated_by:null,repeated_times:null,repeated_end_type:null,repeated_end_date:null,participants:[{id:6}],team_participants:[]},{from_time:"2015-02-28T03:08:41.205Z",id:16,title:"123123",full_day:!1,period:!0,description:"123123",created_at:"2015-02-28T03:07:06.816Z",updated_at:"2015-02-28T03:07:06.816Z",creator_id:6,to_time:"2015-02-28T03:08:41.205Z",repeated:!1,repeated_type:null,repeated_frequency:null,repeated_on:null,repeated_by:null,repeated_times:null,repeated_end_type:null,repeated_end_date:null,participants:[{id:6}],team_participants:[]}]}),$.mockjax({url:e+"/events/after",type:"GET",responseText:[]}),$.mockjax({url:e+"/events",type:"POST",responseText:[]})}()},658:function(e,t,n){var r=n(659);"string"==typeof r&&(r=[[e.id,r,""]]);n(415)(r,{})},659:function(e,t,n){t=e.exports=n(414)(),t.push([e.id,".create-team{padding:0;margin:20px}.create-team-textfield{width:100%!important}",""])}});