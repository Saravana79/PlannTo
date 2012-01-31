// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery_ujs
//= require jquery-ui
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
    ids = jQuery.grep(idsArr,function(a){
        return a != key
    } );
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









//##################################### ADDED BY GANESH #####################################
$(document).ready(function(){

$("#ui-active-menuitem").mouseout(function() {
    $("#ui-active-menuitem").hide();
});

$('#plannToSearch').focus(function(){
    $(this).val('');
    $(this).keydown();
});


  $.ui.autocomplete.prototype._renderMenu = function(ul, items) {
    var self = this;
    $.each(items, function(index, item) {
        self._renderItem(ul, item, index);
    });
    item = {
        value: "Search more items...",
        id: "0",
        imgsrc: ""
    }
    self._renderItem(ul, item, -1);
};

$("#plannToSearch").autocomplete({
    minLength: 2,
    format: "js",
    // source: "/search/autocomplete_items?search_type=" + $("#plannto_search_type").val() ,
    source: function( request, response )
    {
      var opts = {
        lines: 12, // The number of lines to draw
        length: 7, // The length of each line
        width: 4, // The line thickness
        radius: 4, // The radius of the inner circle
        color: '#000', // #rgb or #rrggbb
        speed: 1, // Rounds per second
        trail: 60, // Afterglow percentage
        shadow: false, // Whether to render a shadow
        hwaccel: false // Whether to use hardware acceleration
    };
  var target = document.getElementById('plannToSearchSpan');
  var spinner = new Spinner(opts).spin(target);
    $.ajax(
    {
        url: "/search/autocomplete_items",
        data: { term: request.term, search_type: $("#plannto_search_type").val() },
        type: "POST",
        dataType: "json",
        success: function( data )
        {
        response( $.map( data, function( item )
        {
            return{ id: item.id, value: item.value, imgsrc: item.imgsrc, type: item.type, url: item.url }
            }));
            spinner.stop();
        }
        });
    },
    focus:function(e, ui) {
    return false
    },
    select: function( event, ui ) {
    if (ui.item.id  == 0){
    location.href = "/search/search_items?q=" + $("#plannToSearch").val();
    // return false;
    }
    else{
    location.href = "" + ui.item.url
    // return false;
    }
    // return false;
    }
    })
.data("autocomplete")._renderItem = function(ul, item, index) {
    if (index == -1) {
        return $("<li></li>")
        .data("item.autocomplete", item)
        .append("<a class='searchMore'>" + item.value + "" + "</a>")
        .appendTo(ul);
    }
    else {
        return $("<li></li>")
        .data("item.autocomplete", item)
        .append("<a>" + "<div style='margin-left:5px;float:left'><img width='40' height='40' src='" + item.imgsrc + "' /></div>" + "<div style='margin-left:53px;'><span class='atext'>" + item.value + "</span><br/><span class ='atext'>" + item.type + "</span></div></a>")
        .appendTo(ul);
    }
};

});

  
$(document).ready(function() {
        
  $('span.buttonLink a#youtube_form').click(function() {
          $("#image_share").hide();
          $("#article_share").hide();
          $("#youtube").toggle(2000);
//          alert('Handler for .click() called.');
          return false;
        });


  $('span.buttonLink a#image_form').click(function() {
          $("#article_share").hide();
          $("#youtube").hide(); 
          $("#image_share").toggle(2000);
          return false;
        });


  $('span.buttonLink a#article_form').click(function() {
          $("#youtube").hide(); 
          $("#image_share").hide();
          $("#article_share").toggle(2000);
          return false;
        });

});

$("#share_an_article").click(function(){
        $("share_an_article_form").show();
    }
);