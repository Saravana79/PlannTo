(function(){tinymce.create("tinymce.plugins.FeatureAtPlugin",{init:function(a,b){a.addCommand("mceFeatureAt",function(){a.windowManager.open({file:b+"/dialog.htm",width:500+parseInt(a.getLang("feature_at.delta_width",0)),height:100+parseInt(a.getLang("feature_at.delta_height",0)),inline:1},{plugin_url:b})});a.onKeyDown.add(function(a,b){if(b.keyCode==50&&b.shiftKey)tinyMCE.activeEditor.execCommand("mceFeatureAt");b.preventDefault});a.addButton("feature_at",{title:"@",image:b+"/img/at-sign.png",cmd:"mceFeatureAt"});a.onNodeChange.add(function(a,b,c){b.setActive("feature_at",c.nodeName=="IMG")})},createControl:function(a,b){return null},getInfo:function(){return{longname:"Example plugin",author:"Some author",authorurl:"http://tinymce.moxiecode.com",infourl:"http://wiki.moxiecode.com/index.php/TinyMCE:Plugins/example",version:"1.0"}}});tinymce.PluginManager.add("feature_at",tinymce.plugins.FeatureAtPlugin)})()


