
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

    pln_off = function(el) {
        var width = el.offsetWidth,
            height = el.offsetHeight,
            top = 0, left = 0,
            rect = false, w = window, d = document, de = d.documentElement, b = d.body;
        if (el.getBoundingClientRect) {
            try {
                rect = el.getBoundingClientRect();
                top = ~~(rect.top) + Math.max(w.pageYOffset||0,de.scrollTop,b.scrollTop,0) - Math.max(de.clientTop,b.clientTop,0);
                left = ~~(rect.left) + Math.max(w.pageXOffset||0,de.scrollLeft,b.scrollLeft,0) - Math.max(de.clientLeft,b.clientLeft,0);
            } catch(e){ rect = false; top = 0; left = 0; }
        }
        if (!rect) {
            do {
                top += el.offsetTop;
                left += el.offsetLeft;
            } while ((el = el.offsetParent));
        }
        return {
            top: top,
            t : top,
            bottom: top+height,
            b : top+height,
            left: left,
            l : left,
            right: left + width,
            r : left + width,
            height: height,
            h : height,
            width: width,
            w : width
        };
    };

    reposition = function() {
        jQuery.each(valid_images, function(indx, image) {
            if (indx != 0)
                return

            indx = indx + 1;
            var off_d = pln_off(image)

            console.log(off_d)

            var img_h = off_d.height - 100
            var off_top = off_d.top + img_h

            var ratio = 970/img_width
            ad_height = 400/ratio

            var exp_img_h = off_d.height - ad_height
            var exp_off_top = off_d.top + exp_img_h

            console.log(exp_off_top)
            console.log(pln_frame_expanded)

//            var ratio = 970/img_width
//            ad_height = 400/ratio

            if (pln_frame_expanded == true)
            {
                jQuery(".plannto_in_image_ad_1").css({"width":off_d.width+"px", "height":ad_height+"px", "top":exp_off_top+"px", "left":off_d.left+"px"})
            }
            else if (pln_frame_closed == false)
            {
                jQuery(".plannto_in_image_ad_1").css({"top":off_top+"px","left":off_d.left+"px","width":off_d.width+"px", "height":"100px"})
            }
            else
            {
                jQuery(".plannto_in_image_ad_1").css({"top":off_top+"px","left":off_d.left+"px","width":off_d.width+"px", "height":"100px"})
            }
        });
    }

    /******** Main function ********/
    function main() {

        jQuery(document).ready(function(jQuery) {
            url = getScriptUrl();
            var doc_title =  jQuery(document).title;
            var pathname = getParam(url,"ref_url");
            var visited = getParam(url,"visited");
            var item_ids = getParam(url,"item_ids");
            var expand_type = getParam(url,"expand_type");
            var only_flash = getParam(url,"only_flash");
            console.log("----------------------------------")
            console.log(visited == "1")
            var images = jQuery("img")
            pln_frame_closed = false;
            pln_frame_expanded = false;

            jQuery(window).bind('resize', reposition);

            sto = setInterval(reposition, 1000);

            valid_images = []

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
                img_width = jQuery(image).width()
                img_height = jQuery(image).height()

//                var off_d = pln_off(image)
                off_d = pln_off(image)

                var img_h = off_d.height - 100
                var off_top = off_d.top + img_h

                console.log(img_width)
                console.log(img_height)

                jQuery('<style type="text/css" id="plannto_style_'+indx+'"> ' +
                    'a { outline: none; }' +
                    '.plannto_iframe { height:100px;width:100%;overflow:hidden;} ' +
                    '.plannto_hint_button {background: rgba(0, 0, 0, 0) url("http://cdn1.plannto.com/static/images/plannto_overlay_images.png") no-repeat scroll -158px -2px;cursor: pointer !important;height: 70px;opacity: 1;position: absolute;top: 11px;transition: margin-top 0.6s ease 0s;width: 26px;}'+
                    '.expand_plannto_iframe {cursor: pointer;opacity: 1;position: absolute;width: 12px;text-decoration:none;color:black;}' +
                    '.close_plannto_iframe {background-image:url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAMAAABhEH5lAAAAZlBMVEUAAAAAAAAXFxcWFhYZGRkaGhoAAAAAAAALCwsNDQ0ODg7k5OTo6OjV1dXZ2dnj4+Pm5ubAwMDCwsLZ2dna2trQ0NC/v7/Dw8PHx8fNzc3R0dHS0tLq6uru7u7y8vL29vb6+vr9/f2tB0eZAAAAHHRSTlMzNDc4ODlTVVhYWLS6vL29vb/AxsbIy83Nzc3Nu0nGLwAAAFpJREFUeNq9yEcSgCAMAMAECxIpVsBC8f+f9JoHOO5x4Q+jFgBCj6y2ZxJielZWdFXn6kmskI5SDkJguj3nveHT2hRjsi0rcwelwm1YLX5AVH5m1UsEQNnD116VFgP50TblxgAAAABJRU5ErkJggg==");cursor: pointer;height: 19px;opacity: 1;position: absolute;width: 20px;left: '+(img_width - 20)+'px;' +
                    '.plannto_iframe:hover { width: '+img_width+'px;} ' +
                    '</style>').appendTo("head");

                var height = jQuery(image).height() - 63
                console.log(image)

                url = 'http://'+domain+'/advertisments/image_show_ads.json?item_id='+ item_ids +'&ads_id=7&size='+ img_width +'*80&exp_size='+ img_width +'*'+ img_height +'&more_vendors=true&ad_as_widget=true&ref_url='+pathname+'&visited='+visited+'&expand_type='+expand_type+'&only_flash='+only_flash
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
//                            jQuery(image).parent().css({"position":"relative"})

                            jQuery("body").append('<div class="plan_ad_image_1" style="padding: 0px; margin: 0px; border: medium none; background: transparent none repeat scroll 0px 0px; position: static;"> ' +
                                '<div class="plannto_in_image_ad_1" style="margin: 0px; top: '+ off_top +'px; right: 0px; height: 100px; left: '+ off_d.left +'px; overflow: hidden; padding: 0px; position: absolute; visibility: visible; width: '+ off_d.width +'px; z-index: 100;"><div class="plannto_iframe" style="position: relative; height: 100%; width: 100%; background: transparent none repeat scroll 0% 0%; color: inherit; font: 12px/0.5 Arial; margin-top: 0px; opacity: 1; bottom: 0px;"><span style="width:20px;float:right;display:block;height:20px;"><a href="#" class="close_plannto_iframe"></a></span>' +
                                '<span class="plannto_ad_tag" style="float: right;float: right;margin-right: 5px;font-weight: 600;color: #808080;font-family: sans-serif;font-size: 11px;padding-top: 7px;height:13px;"><a style="text-decoration:none;font-weight: 600;color: #808080;font-family: sans-serif;font-size: 11px;" href="http://www.plannto.com" target="_blank">PlannTo Ads</a></span> <iframe id="plannto_ad_frame" src="" style="border:medium none;position:absolute;z-index:-1;bottom:0px;" height="80px" width="'+img_width+'px"> </iframe><iframe id="exp_plannto_ad_frame" src="" style="border:medium none;display: none;" height="80px" width="'+img_width+'px"> </iframe></div><div class="plannto_hint_button plannto_hint_button'+indx+'"></div></div></div>')


                            jQuery("#plannto_ad_frame").attr("src","data:text/html;charset=utf-8," + encodeURI(data.html))

//                            jQuery('.close_plannto_iframe').hide()

                            if (visited == "1")
                            {
                                jQuery(".plannto_hint_button").hide()
                                page_visited = true
                            }
                            else
                            {
                                jQuery(".plannto_iframe").css("width", img_width+"px")
                                jQuery(".plannto_iframe").css("width", img_width+"px")
                            }

//                            var iframe_body = jQuery("#plannto_ad_frame").contents().find("body")
//                            console.log(iframe_body)
//                            jQuery(iframe_body).css({"width":"500px", "height":"100px", "overflow": "hidden"})

                            expanded_html = "data:text/html;charset=utf-8," + encodeURI(data.expanded_html)

                            if (expand_type == "")
                            {
//                                jQuery(".expand_plannto_iframe").hide()
                                expand_plannto_iframe_key = false
                            }
                        }
                    }
                });

                jQuery(".close_plannto_iframe").live("click", function(event)
                {
                    pln_frame_closed = true
                    pln_frame_expanded = false

                    reposition()

                    jQuery('.close_plannto_iframe').hide()

                    jQuery("#exp_plannto_ad_frame").attr("src", "")
                    jQuery("#exp_plannto_ad_frame").hide()
                    jQuery(".plannto_iframe").css({"height":"100px"})
//                    jQuery(".plannto_in_image_ad_1").css({"height":"100px"})
                    jQuery("#plannto_ad_frame").show()

                    jQuery(".plannto_iframe").animate({width: "0px"}, "slow", function() { jQuery(".plannto_hint_button").show(); })

//                    jQuery(".plannto_hint_button").show()

//                    jQuery(".plan_ad_image_1").css({"bottom":"110px"})

                    return false;

                    event.preventDefault()
                })


//                jQuery(".expand_plannto_iframe").live("click", function(event)
                jQuery(".plannto_iframe").live("click", function(event)
                {
                    var ratio = 970/img_width
                    ad_height = 400/ratio

                    pln_frame_expanded = true
                    reposition()
                    console.log(jQuery(this).attr("class"))

                    console.log(impression_id)
                    jQuery('.close_plannto_iframe').show()

                    jQuery(".plannto_iframe").animate({height: ad_height+"px"}, "slow")
//                    jQuery(".plan_ad_image_1").css({"bottom":img_height})
                    jQuery(".plannto_iframe").css({"position":"absolute"})


                    jQuery("#exp_plannto_ad_frame").attr("src", expanded_html)

                    jQuery("#plannto_ad_frame").hide()
                    jQuery("#exp_plannto_ad_frame").css({"width":img_width, "height": ad_height+"px"})
                    jQuery("#exp_plannto_ad_frame").show()

                    expanded = true

//                    jQuery(".plannto_in_image_ad_1").css({"width":off_d.width+"px", "height":off_d.height+"px", "top":off_d.top+"px"})

//                    jQuery("#exp_swiffycontainer").css({"width":img_width, "height":img_height})

                    return false;
                })

                jQuery(".plannto_hint_button").live("mouseenter", function(event)
                {

                    pln_frame_closed = false
                    pln_frame_expanded = false

                    jQuery("#exp_plannto_ad_frame").hide()
                    jQuery("#exp_plannto_ad_frame").attr("src", "")
                    jQuery("#plannto_ad_frame").show()

                    console.log(expand_type)

//                    if (expand_type != "")
//                    {
//                        jQuery(".expand_plannto_iframe").show()
//                    }

                    jQuery(".plannto_iframe").animate({width: img_width+"px"}, "slow")
                    jQuery(".plannto_hint_button").hide()
                    jQuery(".close_plannto_iframe").show()

                    if (page_visited == false)
                    {
                        jQuery.post('http://'+domain+'/advertisements/ads_visited', {"impression_id": impression_id, "visited": "1"})
                        page_visited = true
                    }

                    return false;
                })

                jQuery(".plannto_ad_tag").live("click", function()
                {
                    window.open("https://www.plannto.com", "_blank")
                    return false;
                })
            })

        });
    }


    return PlannTo;

})(window);
