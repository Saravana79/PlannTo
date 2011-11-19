// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require_tree .


function removeCompare(obj){
      $(obj).parents('.compare-view').remove();
      key = $(obj).attr('rel') ;
      $.cookie(key,null);
      $('#add_to_compare_' + key ).attr('checked',false);
      var url = $('#compare-items a').attr('href')
      idsPrt = url.split('=');
      idsStr = idsPrt[1];
      var url = url.split('=')[0];
      idsArr = idsStr.split(',');
      ids = jQuery.grep(idsArr,function(a){return a != key } );
      idsStr = ids.join(',')
      $.cookie('allItems',idsStr)
      url = $('#compare-items a').attr('href',url + '=' + idsStr)
      if($('#compare-list .compare-view').length > 1){
        $('#compare-items').show();
      }else{
        $('#compare-items').hide();
      }
      if($('#compare-list div.compare-view').length == 0){
        $('#compare-list').hide();
      }
      return false;
  };