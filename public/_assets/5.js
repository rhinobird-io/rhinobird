webpackJsonp([5],{661:function(e,t,n){"use strict";var r=n(337);n(662);var i=n(300),o=n(554);$.mockjax&&$.mockjax({url:"/api/signup",type:"POST",responseText:{company:"Works Applications",name:"Admin",role:"operator"}}),e.exports=r.createClass({displayName:"index",mixins:[r.addons.LinkedStateMixin],contextTypes:{router:r.PropTypes.func.isRequired},getInitialState:function(){return{email:"",name:"",uniqueName:"",password:"",confirmPassword:"",passwordMatch:!0}},componentWillMount:function(){this.props.setTitle("RhinoBird")},_signup:function(e){var t=this;return e.preventDefault(),this.state.password!==this.state.confirmPassword?void this.setState({passwordMatch:!1}):(this.setState({error:!1,passwordMatch:!0}),void $.post("/api/signup",{email:this.state.email,name:this.state.name,uniqueName:this.state.name,password:this.state.password}).then(function(e){o.updateLogin(e),t.context.router.transitionTo(t.context.router.getCurrentQuery().target||"/")}).fail(function(){o.updateLogin(void 0),t.setState({error:!0})}))},render:function(){return r.createElement(i.Paper,{zDepth:1,className:"loginForm",rounded:!1},r.createElement("form",{className:"container",onSubmit:this._login},r.createElement("div",{className:"mui-font-style-title"},"Sign up"),r.createElement(i.TextField,{hintText:"Email",valueLink:this.linkState("email"),autofocus:!0}),r.createElement("div",{className:"uniqueNameField"},r.createElement("span",{className:"mui-font-style-caption"},"@"),r.createElement(i.TextField,{className:"textField",hintText:"Unique name",valueLink:this.linkState("uniqueName")})),r.createElement(i.TextField,{hintText:"Display name",valueLink:this.linkState("name")}),r.createElement(i.TextField,{hintText:"Password",type:"password",valueLink:this.linkState("password")}),r.createElement(i.TextField,{hintText:"Confirm password",type:"password",valueLink:this.linkState("confirmPassword"),errorText:this.state.passwordMatch?void 0:"Password do not match."}),r.createElement("div",{className:"rightButton"},r.createElement(i.RaisedButton,{label:"Sign up",primary:!0,onClick:this._signup,type:"submit"}))))}})},662:function(e,t,n){var r=n(663);"string"==typeof r&&(r=[[e.id,r,""]]);n(415)(r,{})},663:function(e,t,n){t=e.exports=n(414)(),t.push([e.id,".loginForm{position:absolute;width:300px;top:100px;left:50%;margin-left:-150px;background-color:#fafafa}.loginForm .container{padding:1.5em}.rightButton{margin-top:1em;text-align:right}.uniqueNameField{position:relative}.uniqueNameField .mui-text-field-hint,.uniqueNameField input{padding-left:1em}.uniqueNameField span{position:absolute;top:8px;font-size:16px!important}",""])}});