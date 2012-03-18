// To make this work on localhost
document.domain = /(\w+)(.\w+)?$/.exec(location.hostname)[0];
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
function reinitialiseVotingPoshyTip(){   
    $('.btn_dislike_positive').poshytip('destroy')

    $('.btn_like_positive').poshytip('destroy')

    $('.btn_like_default').poshytip('destroy')

    $('.btn_dislike_default').poshytip('destroy')

    $('.btn_like_negative').poshytip('destroy')
    $('.btn_dislike_negative').poshytip('destroy')


    $('.btn_dislike_positive').poshytip({
        content: 'Dislike It',
        className: 'tip-darkgray',
        bgImageFrameSize: 11,
        offsetX: -25
    });
    $('.btn_like_positive').poshytip({
        content: 'Already Liked It, click to cancel it',
        className: 'tip-darkgray',
        bgImageFrameSize: 11,
        offsetX: -25
    });
    $('.btn_like_default').poshytip({
        content: 'Like It',
        className: 'tip-darkgray',
        bgImageFrameSize: 11,
        offsetX: -25
    });
    $('.btn_dislike_default').poshytip({
        content: 'Dislike It',
        className: 'tip-darkgray',
        bgImageFrameSize: 11,
        offsetX: -25
    });
    $('.btn_like_negative').poshytip({
        content: 'Like It',
        className: 'tip-darkgray',
        bgImageFrameSize: 11,
        offsetX: -25
    });
    $('.btn_dislike_negative').poshytip({
        content: 'Alread Disliked it, click to cancel',
        className: 'tip-darkgray',
        bgImageFrameSize: 11,
        offsetX: -25
    });
}

$(document).ready(function(){
    reinitialiseVotingPoshyTip();

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
                length: 5, // The length of each line
                width: 4, // The line thickness
                radius: 5, // The radius of the inner circle
                color: '#2EFE9A', // #rgb or #rrggbb
                speed: 1, // Rounds per second
                trail: 50, // Afterglow percentage
                shadow: true, // Whether to render a shadow
                hwaccel: false // Whether to use hardware acceleration
            };
            var target = document.getElementById('plannToSearchSpan');
            var spinner = new Spinner(opts).spin(target);
            $.ajax(
            {
                url: "/search/autocomplete_items",
                data: {
                    term: request.term,
                    search_type: $("#plannto_search_type").val()
                },
                type: "POST",
                dataType: "json",
                success: function( data )
                {
                    response( $.map( data, function( item )
                    {
                        return{
                            id: item.id,
                            value: item.value,
                            imgsrc: item.imgsrc,
                            type: item.type,
                            url: item.url
                        }
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
    $("#plannToSearch").data("autocomplete")._renderItem = function(ul, item, index) {
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


    $("#search_car").autocomplete({
        minLength:2,
        format:"js",
        // source: "/search/autocomplete_items?search_type=" + $("#plannto_search_type").val() ,
        source:function (request, response) {
            var opts = {
                lines:12, // The number of lines to draw
                length:5, // The length of each line
                width:4, // The line thickness
                radius:5, // The radius of the inner circle
                color:'#2EFE9A', // #rgb or #rrggbb
                speed:1, // Rounds per second
                trail:50, // Afterglow percentage
                shadow:true, // Whether to render a shadow
                hwaccel:false // Whether to use hardware acceleration
            };
            //       var target = document.getElementById('search_car');
            //       var spinner = new Spinner(opts).spin(target);
            $.ajax(
            {
                url:"/search/autocomplete_items",
                data:{
                    term:$("#search_car").val(),
                    search_type:$("#category").val(),
                    authenticity_token: window._token,
                    from_profile: true
                },
                type:"POST",
                dataType:"json",
                success:function (data) {
                    response($.map(data, function (item) {
                        return{
                            id:item.id,
                            value:item.value,
                            imgsrc:item.imgsrc,
                            type:item.type,
                            url:item.url
                        }
                    }));
                //           spinner.stop();
                }
            });
        },
        focus:function (e, ui) {
            return false
        },
        select: function( event, ui ) {
            $.ajax(
            {
                url:"/items/"+ui.item.id+"/follow_item_type?button_class=&follow_type="+$("#types").val()+"&authenticity_token="+window._token,
                type:"GET",
                dataType:"script",
                complete:function (data) {
                    location.reload();
                //           spinner.stop();
                }
            });
        }
    })
/*  $("#search_car").data("autocomplete")._renderItem = function (ul, item, index) {
        if (index == -1) {
            return $("<li></li>")
                .data("item.autocomplete", item)
                .append("<a class='searchMore'>" + item.value + "" + "</a>")
                .appendTo(ul);
        }
        else {
            return $("<li></li>")
                .data("item.autocomplete", item)
                .append('<a>' + "<div style='margin-left:5px;float:left'><img width='40' height='40' src='" + item.imgsrc + "' /></div>" + "<div style='margin-left:53px;'><span class='atext'>" + item.value + "</span><br/><span class ='atext'>" + item.type + "</span></div></a>")
                .appendTo(ul);
        }
    }*/


});

  
$(document).ready(function() {
        
    $('a.youtube').youtube();
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