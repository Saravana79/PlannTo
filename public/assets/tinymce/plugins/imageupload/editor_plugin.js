(function(){tinymce.create("tinymce.plugins.ImageUploadPlugin",{init:function(a,b){a.addCommand("mceImageUpload",function(){a.windowManager.open({file:b+"/dialog.htm",width:320+parseInt(a.getLang("imageupload.delta_width",0)),height:120+parseInt(a.getLang("imageupload.delta_height",0)),inline:1},{plugin_url:b})});a.addButton("imageupload",{title:"Image Upload",cmd:"mceImageUpload",image:b+"/img/imageupload.gif"});a.onNodeChange.add(function(a,b,c){b.setActive("imageupload",c.nodeName=="IMG")})},createControl:function(a,b){return null},getInfo:function(){return{longname:"Simple Image Upload for Rails 3",author:"Vivek Aditya",authorurl:"http://tinymce.moxiecode.com",infourl:"",version:"1.0"}}});tinymce.PluginManager.add("imageupload",tinymce.plugins.ImageUploadPlugin)})()



$(document).ready(function()
  { 
    var m = document.getElementsByTagName('meta');

        for(var i in m)
          if(m[i].name == 'csrf-token')
            alert("pppppppp");
            $("#authenticity_token").val("uuuuuuu");


 });





