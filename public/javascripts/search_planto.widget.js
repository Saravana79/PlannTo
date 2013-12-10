if (scriptCount == undefined) {
    var scriptCount = 0;

}

var PlannTo = (function (window, undefined) {

    var PlannTo = {};
    var SubPath = "/search_planto.js"
    //for production
    var domain = "www.plannto.com";
    //for development
    // var domain = "localhost:3000";
    // Localize jQuery variable
    var jQuery;

    /******** Load jQuery if not present *********/
    if (window.jQuery === undefined || window.jQuery.fn.jquery !== '1.7.1') {
        var script_tag = document.createElement('script');
        script_tag.setAttribute("type", "text/javascript");
        script_tag.setAttribute("src",
            "http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js");


        if (script_tag.readyState) {
            script_tag.onreadystatechange = function () { // For old versions of IE
                if (this.readyState == 'complete' || this.readyState == 'loaded') {
                    scriptLoadHandler();
                }
            };
        } else { // Other browsers
            script_tag.onload = scriptLoadHandler;
        }
        // Try to find the head, otherwise default to the documentElement
        (document.getElementsByTagName("head")[0] || document.documentElement).appendChild(script_tag);
        var script_tag = document.createElement('script');
        script_tag.setAttribute("type", "text/javascript");
        script_tag.setAttribute("src",
            "http://code.jquery.com/ui/1.10.3/jquery-ui.js");
        if (script_tag.readyState) {
            script_tag.onreadystatechange = function () { // For old versions of IE
                if (this.readyState == 'complete' || this.readyState == 'loaded') {
                    scriptLoadHandler();
                }
            };
        } else { // Other browsers
            script_tag.onload = scriptLoadHandler;
        }

        (document.getElementsByTagName("head")[0] || document.documentElement).appendChild(script_tag);


    } else {
        // The jQuery version on the window is the one we want to use
        jQuery = window.jQuery;
        PlannTo.jQuery = jQuery;

        main();
        return PlannTo;
    }

    /******** Called once jQuery has loaded ******/
    function scriptLoadHandler() {
        // Restore jQuery and window.jQuery to their previous values and store the
        // new jQuery in our local jQuery variable
        jQuery = window.jQuery.noConflict(true);
        PlannTo.jQuery = jQuery;
        // Call our main function

        main();
    }

    function getParam(url, sname) {
        var a = document.createElement('a');
        a.href = url;
        params = a.search.substr(a.search.indexOf("?") + 1);
        sval = "";
        params = params.split("&");
        // split param and value into individual pieces
        for (var i = 0; i < params.length; i++) {
            temp = params[i].split("=");
            if ([temp[0]] == sname) {
                sval = temp[1];
            }
        }

        return sval;
    }

    function getScriptUrl() {
        var scripts = document.getElementsByTagName('script');
        var element;
        var src;
        var count = 0;
        for (var i = 0; i < scripts.length; i++) {
            element = scripts[i];
            src = element.src;

            if (src.indexOf(domain + "/javascripts/search_planto.widget.js") != -1) {
                if (count >= scriptCount) {
                    scriptCount = scriptCount + 1;
                    return src;
                } else {
                    count = count + 1;
                }
            }
        }
        return null;
    }

    function where_to_buy(item_id, show_details, element_id, parentdivid, pathname) {
        var doc_title = PlannTo.jQuery(document).title;

        url = "http://" + domain + "/get_item_for_widget.js?item_id=" + item_id + "&price_full_details=" + show_details + "&ref_url=" + pathname + "&doc_title-" + doc_title + "&callback=?"

        jQuery.getJSON(url, function (data) {
            console.log(data)
            jQuery("#display_search_item").html(data.html);

        });
    }


    function planntowtbdivcreation(item_ids, show_details, element_id, parentdivid, pathname) {
        var doc_title = PlannTo.jQuery(document).title;

        url = "http://" + domain + SubPath + "?q=" + item_ids + "&price_full_details=" + show_details + "&ref_url=" + pathname + "&doc_title-" + doc_title + "&callback=?"

        jQuery.getJSON(url, function (data) {


            jQuery("#planto_search_items").html(data.html);
            jQuery(".where_to_buy_searched").live("click", function () {
                where_to_buy(jQuery(this).attr("id"), show_details, element_id, parentdivid, pathname)
            })
            autoComplete()


        });
    }



    function autoComplete() {

        url = getScriptUrl();
        var doc_title = PlannTo.jQuery(document).title;
        var doc_title = jQuery(document).title;
        var pathname = getParam(url, "ref_url");
        // var item_id = jQuery("#planto_search_widget_auto_item").val();
        var show_details = getParam(url, "show_details");
        var ads = getParam(url, "advertisement");
        var element_id = "#content";

        element = jQuery("#display_search_item").val()


        jQuery("#planto_search_widget_auto_item").autocomplete({

            source: function (request, response) {

                jQuery.ajax({
                    url: "http://" + domain + "/product_autocomplete",
                    data: {
                        q: request.term
                    },
                    type: "GET",
                    jsonp: "callback",

                    // tell jQuery we're expecting JSONP
                    dataType: "jsonp",
                    success: function (data) {
                        {
                            response(jQuery.map(data, function (item) {
                                return {
                                    id: item.id,
                                    value: item.value,
                                    imgsrc: item.imgsrc,
                                    type: item.type,
                                    url: item.url
                                }
                            }));
                        }
                    }

                });
            },




            minLength: 2,
            select: function (event, ui) {
              console.log(ui.item.id)
              where_to_buy(ui.item.id, show_details, element, element_id, pathname); 
            },
            create: function () {
            jQuery(this).data('ui-autocomplete')._renderItem = function (ul, item) {
                return jQuery('<li>')
                    .append('<a>' + item.label + '<br>' + item.value + '</a>')
                    .appendTo(ul);
            };
        }

        })

        // $(ul).append("<div class='myFooter'>some footer text</div>");

        // console.log(jQuery("#planto_search_widget_auto_item"))

    }

    /******** Main function ********/
    function main() {

        jQuery(document).ready(function (jQuery) {
            url = getScriptUrl();
            var doc_title = PlannTo.jQuery(document).title;
            var doc_title = jQuery(document).title;
            var pathname = getParam(url, "ref_url");
            // var item_id = jQuery("#planto_search_widget_auto_item").val();
            var show_details = getParam(url, "show_details");
            var ads = getParam(url, "advertisement");
            var element_id = "#content";

            element = jQuery("#display_search_item").val()


            url = "http://" + domain + SubPath + "?price_full_details=" + show_details + "&ref_url=" + pathname + "&doc_title-" + doc_title + "&callback=?"

            jQuery.getJSON(url, function (data) {


                jQuery("#planto_search_items").html(data.html);

                jQuery(".where_to_buy_searched").live("click", function () {
                    where_to_buy(jQuery(this).attr("id"), show_details, element, element_id, pathname)
                })
                autoComplete()

            });
            jQuery("#search_from_widget").live("click", function (e) {
                url = getScriptUrl();
                var doc_title = jQuery(document).title;
                var pathname = getParam(url, "ref_url");
                var item_id = jQuery("#planto_search_widget_auto_item").val();
                var show_details = getParam(url, "show_details");
                var ads = getParam(url, "advertisement");
                var element_id = "#display_search_item";

                element = jQuery("#display_search_item").val()
                // if(item_id.length > 3){
                console.log(element_id)
                planntowtbdivcreation(item_id, show_details, element, element_id, pathname);

                // }

            });

        });


    }


    return PlannTo;

})(window);