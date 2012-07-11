// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require_tree .
//= require tinymce
//= require jquery.remotipart
//= require_self


$(document).ready(function() { 
  $('a.fbpopup').click(function(e) {
    console.log('here');
    var width = 600, height = 400;
    var left = (screen.width / 2) - (width / 2);
    var top = (screen.height / 2) - (2 * height / 3);
    var features = 'menubar=no,toolbar=no,status=no,width=' + width + ',height=' + height + ',toolbar=no,left=' + left + ',top=' + top;
    var loginWindow = window.open($(this).attr("href"), '_blank', features);
    loginWindow.focus();
    e.preventDefault();
    return false;
  });
  
  $(".invite").live('click', function(){
    id = $(this).attr('id');
    $('#invitation_follow_type').val(id);
    $("#dialog-invite-form").dialog({height: 500,
      width: 550,
      modal: true});
  });
});

