!function(){return tinymce.PluginManager.requireLangPack("uploadimage"),tinymce.create("tinymce.plugins.UploadImagePlugin",{init:function(e,n){return e.addCommand("mceUploadImage",function(){return e.windowManager.open({file:n+"/dialog.html",width:320+parseInt(e.getLang("uploadimage.delta_width",0)),height:180+parseInt(e.getLang("uploadimage.delta_height",0)),inline:1},{plugin_url:n})}),e.addButton("uploadimage",{title:"uploadimage.desc",cmd:"mceUploadImage",image:n+"/img/uploadimage.png"}),e.onNodeChange.add(function(e,n,a){return n.setActive("uploadimage","IMG"===a.nodeName)})},createControl:function(e,n){return null},getInfo:function(){return{longname:"UploadImage plugin",author:"Per Christian B. Viken (borrows heavily from work done by Peter Shoukry of 77effects.com)",authorurl:"eastblue.org/oss",infourl:"eastblue.org/oss",version:"1.0"}}}),tinymce.PluginManager.add("uploadimage",tinymce.plugins.UploadImagePlugin)}();