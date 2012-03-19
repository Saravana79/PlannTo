$(document).ready(function() {
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
});