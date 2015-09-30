
if(scriptCount == undefined)
{
    var scriptCount = 0;

}

var PlannTo = (function(window,undefined) {

    var PlannTo ={};
//    var SubPath="/price_vendor_details.js"
//for production
//    var domain = "www.plannto.com";
//for development
var domain = "localhost:3000";
// Localize jQuery variable
    var jQuery;

    /******** Load jQuery if not present *********/
    if (window.jQuery === undefined || window.jQuery.fn.jquery !== '1.7.1') {
        var script_tag = document.createElement('script');
        script_tag.setAttribute("type","text/javascript");
        script_tag.setAttribute("src",
            "https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js");
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

    function getParam (url, sname )
    {
        var a = document.createElement('a');
        a.href = url;
        params = a.search.substr(a.search.indexOf("?")+1);
        sval = "";
        params = params.split("&");
        // split param and value into individual pieces
        for (var i=0; i<params.length; i++)
        {
            temp = params[i].split("=");
            if ( [temp[0]] == sname ) { sval = temp[1]; }
        }

        return sval;
    }

    function getScriptUrl() {
        var scripts = document.getElementsByTagName('script');
        var element;
        var src;
        var count = 0;
        for (var i = 0; i < scripts.length; i++)
        {
            element = scripts[i];
            src = element.src;

            if (src.indexOf(domain+"/javascripts/plannto.overlay_ads.js") != -1)
            {
                if (count >= scriptCount)
                {
                    scriptCount= scriptCount + 1;
                    return src;
                }
                else
                {
                    count = count +1 ;
                }
            }
        }
        return null;
    }

    /******** Main function ********/
    function main() {

//        jQuery(document).ready(function(jQuery) {
            url = getScriptUrl();
            var doc_title =  jQuery(document).title;
            var pathname = getParam(url,"ref_url");
            var visited = getParam(url,"visited");
            var item_ids = getParam(url,"item_ids");
            var expand_type = getParam(url,"expand_type");
            console.log("----------------------------------")
            console.log(visited == "1")
            var images = jQuery("img")

            var valid_images = []

            jQuery.each(images, function(inx, val){
                if ((parseInt(jQuery(val).width()) > 400) && (parseInt(jQuery(val).height()) > 200))
                {
                    var class_val = jQuery(val).attr("class")
                    if ((class_val == undefined) || (class_val.match(/background/g) == null))
                    {
                      valid_images.push(val)
                    }
                }

            });

            console.log(valid_images)

            jQuery.each(valid_images, function(indx, image){
                if (indx != 0)
                return
                var page_visited = false;
                var expanded = false;

                indx = indx + 1;
                var img_width = jQuery(image).width()
                var img_height = jQuery(image).height()

                console.log(img_width)
                console.log(img_height)

                jQuery('<style type="text/css" id="plannto_style_'+indx+'"> ' +
                'a { outline: none; }' +
                '.plannto_iframe { position:absolute;width:100%;overflow:hidden;} ' +
                '.plannto_hint_button {background: rgba(0, 0, 0, 0) url("http://cdn1.plannto.com/static/images/plannto_overlay_images.png") no-repeat scroll -158px -2px;cursor: pointer !important;height: 70px;opacity: 1;position: absolute;top: 11px;transition: margin-top 0.6s ease 0s;width: 26px;z-index: 5 !important;}'+
                '.expand_plannto_iframe {cursor: pointer;opacity: 1;position: absolute;width: 12px;z-index: 5;text-decoration:none;color:black;}' +
                '.close_plannto_iframe {background-image:url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAMAAABhEH5lAAAAZlBMVEUAAAAAAAAXFxcWFhYZGRkaGhoAAAAAAAALCwsNDQ0ODg7k5OTo6OjV1dXZ2dnj4+Pm5ubAwMDCwsLZ2dna2trQ0NC/v7/Dw8PHx8fNzc3R0dHS0tLq6uru7u7y8vL29vb6+vr9/f2tB0eZAAAAHHRSTlMzNDc4ODlTVVhYWLS6vL29vb/AxsbIy83Nzc3Nu0nGLwAAAFpJREFUeNq9yEcSgCAMAMAECxIpVsBC8f+f9JoHOO5x4Q+jFgBCj6y2ZxJielZWdFXn6kmskI5SDkJguj3nveHT2hRjsi0rcwelwm1YLX5AVH5m1UsEQNnD116VFgP50TblxgAAAABJRU5ErkJggg==");cursor: pointer;height: 19px;opacity: 1;position: absolute;width: 20px;z-index: 5;left: '+(img_width - 20)+'px;' +
                '.plannto_iframe:hover { width: '+img_width+'px;} ' +
                '</style>').appendTo("head");

                var height = jQuery(image).height() - 63
                console.log(image)

                url = 'http://'+domain+'/advertisments/image_show_ads.json?item_id='+ item_ids +'&ads_id=7&size='+ img_width +'*80&more_vendors=true&ad_as_widget=true&ref_url='+pathname+'&visited='+visited
                var impression_id = ""
                jQuery.ajax({
                    url : url,
                    type: "get",
                    dataType:"json",
                    success:function(data)
                    {
                        if (data.success == true)
                        {
                            impression_id = data.impression_id;
                            jQuery(image).parent().css({"position":"relative", "z-index":"1"})

                         jQuery(image).parent().append('<div class="plan_ad_image_1" style="position: absolute; bottom: 100px; z-index:2;width:100%;"> ' +
                                '<div class="plannto_iframe" style="width:'+img_width+'px"><div style="width:100%;""><span style="width:20px;float:right;display:block;height:20px;"><a href="#" class="close_plannto_iframe"></a></span>' +
                                '<span style="float: right;width:12px;display:block;height:20px;"><a href="#" class="expand_plannto_iframe">E</a></span><span style="float: right;float: right;margin-right: 5px;font-weight: 600;color: #808080;font-family: sans-serif;font-size: 11px;padding-top: 4px;"><a style="text-decoration:none;font-weight: 600;color: #808080;font-family: sans-serif;font-size: 11px;" href="http://www.plannto.com" target="_blank">PlannTo Ads</a></span></div> <iframe id="plannto_ad_frame" src="" style="border:medium none;" height="80px" width="'+img_width+'px"> </iframe><iframe id="exp_plannto_ad_frame" src="" style="border:medium none;display: none;" height="80px" width="'+img_width+'px"> </iframe></div>' +
                                '<div class="plannto_hint_button plannto_hint_button'+indx+'"></div>' +
                                '</div>')


                            jQuery("#plannto_ad_frame").attr("src","data:text/html;charset=utf-8," + encodeURI(data.html))

                            if (visited == "1")
                            {
                                jQuery(".plannto_hint_button").hide()
                                page_visited = true
                            }
                            else
                            {
                                jQuery(".plannto_iframe").css("width", img_width+"px")
                            }

                            var iframe_body = jQuery("#plannto_ad_frame").contents().find("body")
                            console.log(iframe_body)
                            jQuery(iframe_body).css({"width":"500px", "height":"100px", "overflow": "hidden"})

                            if (expand_type == "")
                            {
                                jQuery(".expand_plannto_iframe").hide()
                            }
                        }
                    }
                });

                jQuery(".close_plannto_iframe").live("click", function(event)
                {
//                    var expanded_view = jQuery("#plannto_ad_frame").contents().find("#expanded_view")
//                    jQuery(expanded_view).hide()
//
//                    var normal_view = jQuery("#plannto_ad_frame").contents().find("#normal_view")
//                    jQuery(normal_view).show()
//                    jQuery(".expand_plannto_iframe").show()

                    jQuery("#exp_plannto_ad_frame").attr("src", "")
                    jQuery("#exp_plannto_ad_frame").hide()
                    jQuery("#plannto_ad_frame").show()

                    jQuery(".plannto_iframe").animate({width: "0px"}, "slow", function() { jQuery(".plannto_hint_button").show() })

                    jQuery(".plan_ad_image_1").css({"bottom":"100px"})
//
//                    jQuery(".expand_plannto_iframe").show();

                    return false;
                })

//                jQuery(".plannto_hint_button").live("hover", function(event)
//                {
////                    if (expanded == true)
////                    {
////                        jQuery("#plannto_ad_frame").css({"width":img_width, "height": img_height + 4})
////                        jQuery(".plan_ad_image_1").css({"bottom":img_height})
////
////                        jQuery("#plannto_ad_frame").attr("src", expanded_html)
////                    }
//
//                    jQuery("#plannto_ad_frame").show()
//                    jQuery("#exp_plannto_ad_frame").hide()
//                });

                jQuery(".expand_plannto_iframe").live("click", function(event)
                {
                    console.log(impression_id)
                    jQuery(".plannto_iframe").animate({height: img_height+4+"px"}, "slow")
//                    jQuery("#plannto_ad_frame").hide()
                    jQuery(".plan_ad_image_1").css({"bottom":img_height})

//                    var swf = '<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="https://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,40,0" id="plannto-flash-ad" name="plannto-ad" width="300" height="60"> <param name="plannto-flash-movie" value="http://cdn1.plannto.com/static/video_ads/Flipkart 300x60.swf"> <param name="wmode" value="opaque"> <param name="allowscriptaccess" value="always"> <object type="application/x-shockwave-flash" data="http://cdn1.plannto.com/static/video_ads/Flipkart 300x60.swf" width="300" height="60"> <param name="FlashVars" value="clickTag=shop_now_url"> <param name="wmode" value="opaque"> <param name="allowscriptaccess" value="always"> </object></object>'

                    if (expanded == false)
                    {
                        var expanded_url = 'http://'+domain+'/advertisments/image_show_ads.json?item_id='+ item_ids +'&ads_id=7&size='+ img_width +'*'+ img_height +'&more_vendors=true&ad_as_widget=true&ref_url='+pathname+'&visited='+visited+'&expanded=1'+'&impression_id='+impression_id+'&expand_type='+expand_type
                        jQuery.ajax({
                            url : expanded_url,
                            type: "get",
                            dataType:"json",
                            success:function(data)
                            {
                                if (data.success == true)
                                {
                                    expanded_html = "data:text/html;charset=utf-8," + encodeURI(data.html)
                                    jQuery("#exp_plannto_ad_frame").attr("src", expanded_html)

                                    jQuery("#plannto_ad_frame").hide()
                                    jQuery("#exp_plannto_ad_frame").css({"width":img_width, "height": img_height + 4})
                                    jQuery("#exp_plannto_ad_frame").show()

//                                    var normal_view = jQuery("#plannto_ad_frame").contents().find("#normal_view")
//                                    jQuery(normal_view).hide()
//
//                                    var expanded_view = jQuery("#plannto_ad_frame").contents().find("#expanded_view")
//                                    jQuery(expanded_view).html(data.html)
//                                    jQuery(expanded_view).show()
                                }
                            }
                        });


//                        jQuery.post('http://'+domain+'/advertisements/ads_visited', {"impression_id": impression_id, "expanded": "1"})
                        expanded = true
                    }
                    else
                    {
//                        jQuery("#plannto_ad_frame").attr("src", expanded_html)

                        jQuery("#plannto_ad_frame").hide()
                        jQuery("#exp_plannto_ad_frame").attr("src", expanded_html)
                        jQuery("#exp_plannto_ad_frame").show()

//                        var normal_view = jQuery("#plannto_ad_frame").contents().find("#normal_view")
//                        jQuery(normal_view).hide()
//
//                        var expanded_view = jQuery("#plannto_ad_frame").contents().find("#expanded_view")
//                        jQuery(expanded_view).show()
//                        jQuery(".expand_plannto_iframe").hide()
//
//                        var my_videos = jQuery("#plannto_ad_frame").contents().find(".plannto-advertisement video");
//
//                        if (my_videos.length != 0)
//                        {
//                            var my_video = my_videos[0]
//                            my_video.play();
//                        }
                    }
                    jQuery(this).hide()

                    return false;
                })

                jQuery(".plannto_hint_button").live("mouseenter", function(event)
                {
                    jQuery("#exp_plannto_ad_frame").hide()
                    jQuery("#exp_plannto_ad_frame").attr("src", "")
                    jQuery("#plannto_ad_frame").show()

                    console.log(expand_type)

                    if (expand_type != "")
                    {
                        jQuery(".expand_plannto_iframe").show()
                    }

                    jQuery(".plannto_iframe").animate({width: img_width+"px"}, "slow")
                    jQuery(".plannto_hint_button").hide()

                    if (page_visited == false)
                    {
                        jQuery.post('http://'+domain+'/advertisements/ads_visited', {"impression_id": impression_id, "visited": "1"})
                        page_visited = true
                    }

                    return false;
                })
            })
//        });
    }


    return PlannTo;

})(window);
