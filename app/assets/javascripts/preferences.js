//$(document).ready(function() {
$(document).on("keyup.autocomplete", '#search_car', function(){ $(this).autocomplete({
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
                type:"GET",
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
                url:"/preferences/plan_to_buy?item_id="+ui.item.id+"&follow_type="+ "Buyer&buying_plan_id=" + $("#buying_plan_id").val() + "&per_page=" + $("#per_page_value").val(),
                type:"GET",
                dataType:"script"
            });
        }
    })
    if ($("#search_car").index() != -1) {
        $("#search_car").data("autocomplete")._renderItem = function (ul, item, index) {
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
        }
    }

    $('#plantobuyPaginate div.pagination a').click(function() {
    //$('#plantobuyPaginate div.pagination a').live('click', function(){
        var page = $(this).text()
        var current = $('em.current').text();
        if (page == "← Previous"){
            page = parseInt(current) -1
        }
        else if (page == "Next →"){
            page = parseInt(current) + 1
        }

        $.ajax(
        {
            url:"/preferences/plan_to_buy?follow_type=" + ""+ "&buying_plan_id=" + $("#buying_plan_id").val() + "&page=" + page + "&per_page=" + $("#per_page_value").val(),
            type:"GET",
            dataType:"script"
        });
        
        return false;
    })

});


////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////


$(document).on("keyup.autocomplete", '#search_buying_car', function(){ $(this).autocomplete({
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
                    term:$("#search_buying_car").val(),                    
                    authenticity_token: window._token,
                    from_profile: true,
                    search_type: $("#category").val(),
                },
                type:"GET",
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
                url:"/preferences/plan_to_buy?item_id="+ui.item.id+"&follow_type="+ "Buyer&buying_plan_id=" + $("#buying_plan_id").val() + "&per_page=" + $("#per_page_value").val() + "&display_type=" + "popup",
                type:"GET",
                dataType:"script"
            });
        }
    })
    if ($("#search_buying_car").index() != -1) {
        $("#search_buying_car").data("autocomplete")._renderItem = function (ul, item, index) {
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
        }
    }



});


