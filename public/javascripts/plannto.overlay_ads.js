
if(scriptCount == undefined)
{
    var scriptCount = 0;

}

var PlannTo = (function(window,undefined) {

    var PlannTo ={};
//    var SubPath="/price_vendor_details.js"
//for production
    var domain = "www.plannto.com";
//for development
//    var domain = "localhost:3000";
// Localize jQuery variable
//    var jQuery;

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

        jQuery(document).ready(function(jQuery) {
            url = getScriptUrl();
            var doc_title =  jQuery(document).title;
            var pathname = getParam(url,"ref_url");
            var item_ids = getParam(url,"item_ids");
            var only_flash = getParam(url,"only_flash");
            console.log("----------------------------------")
            pln_frame_closed = false;
            pln_frame_expanded = false;
            n_ad_height = 80
            n_ad_height_w_close_btn = 182
            e_ad_height = 300
            e_ad_height_w_close_btn = 500


            pln_off = function(el) {
                var width = el.offsetWidth,
                    height = el.offsetHeight,
                    top = 0, left = 0,
                    rect = false, w = window, d = document, de = d.documentElement, b = d.body;

                var org_height = jQuery(el).height()
                var org_width = jQuery(el).width()

                if (org_height > height)
                {
                    org_height = height
                }
                if (org_width > width)
                {
                    org_width = width
                }

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
                    w : width,
                    org_width: org_width,
                    ow : org_width,
                    org_height: org_height,
                    oh : org_height
                };
            };

            reposition = function() {
                jQuery.each(valid_images, function(indx, image) {
                    if (indx != 0)
                        return

                    indx = indx + 1;
                    var off_d = pln_off(image)

//                    console.log(off_d)
//                    console.log(n_ratio)
//                    console.log(e_ratio)

                    n_ad_height_w_close_btn = n_ad_height + 20
                    e_ad_height_w_close_btn = e_ad_height + 20

//                    if (n_ratio != 0.0)
//                    {
//                        n_ad_height = Math.round(off_d.width / n_ratio)
//                        n_ad_height_w_close_btn = n_ad_height + 20
//                        console.log(n_ad_height)
//                    }

                    var img_h = off_d.height - n_ad_height_w_close_btn
                    var off_top = off_d.top + img_h

//                    if (e_ratio != 0.0)
//                    {
//                        e_ad_height = Math.round(off_d.width / e_ratio)
//                        e_ad_height_w_close_btn = e_ad_height + 20
//                        console.log(n_ad_height)
//                    }

//                    console.log(33333333333)
//                    console.log(off_d)
//                    console.log(e_ad_height_w_close_btn)
                    var exp_img_h = off_d.height - e_ad_height_w_close_btn
                    if (exp_img_h < 0)
                    {
                        var exp_off_top = off_d.top
                    }
                    else
                    {
                        var exp_off_top = off_d.top + exp_img_h
                    }

//                    console.log(exp_off_top)

//                    if (exp_off_top < off_d.top)
//                    {
                        var extra_top = off_d.height - off_d.org_height
                        if (extra_top > 0)
                        {
                            extra_top = off_d.top + extra_top
                        }
//                    }


                    if (exp_off_top < extra_top)
                    {
                        exp_off_top = extra_top
                    }

                    if (pln_frame_expanded == true)
                    {
                        jQuery(".plannto_in_image_ad_1").css({"width":off_d.width+"px", "height": e_ad_height_w_close_btn+"px", "top":exp_off_top+"px", "left":off_d.left+"px"})
                    }
                    else if (pln_frame_closed == false)
                    {
                        jQuery(".plannto_in_image_ad_1").css({"top":off_top+"px","left":off_d.left+"px","width":off_d.width+"px", "height": n_ad_height_w_close_btn+"px"})
                    }
                    else
                    {
                        jQuery(".plannto_in_image_ad_1").css({"top":off_top+"px","left":off_d.left+"px","width":off_d.width+"px", "height": n_ad_height_w_close_btn+"px"})
                    }
                });
            }

            function getImageSize(img, callback){
                img = jQuery(img);

                var wait = setInterval(function(){
                    var w = img.width(),
                        h = img.height();

                    if(w && h){
                        done(w, h);
                    }
                }, 0);

                var onLoad;
                img.on('load', onLoad = function(){
                    done(img.width(), img.height());
                });


                var isDone = false;
                function done(){
                    if(isDone){
                        return;
                    }
                    isDone = true;

                    clearInterval(wait);
                    img.off('load', onLoad);

                    callback.apply(this, arguments);
                }
            }

            get_valid_images = function()
            {
                images = jQuery("img")
                valid_images = []
                jQuery.each(images, function(inx, val){
                    getImageSize(jQuery(val), function(width, height){
                        console.log(images.length)
                        console.log(inx+1)

                        if ((parseInt(width) > 400) && (parseInt(height) > 200))
                        {
                            var class_val = jQuery(val).attr("class")
                            if ((class_val == undefined) || (class_val.match(/background/g) == null))
                            {
                                valid_images.push(val)
                            }
                        }

                        if (images.length == (inx+1))
                        {
                            create_image_ad_process()
                        }
                    });
                });
            }

            create_image_ad_process = function()
            {
                console.log("started creating ad")
                console.log(valid_images)
                jQuery.each(valid_images, function(indx, image){
                    if (indx != 0)
                        return
//                    n_ratio = 0
//                    e_ratio = 0
                    var page_visited = false;
                    var z_index = -1
//                    var z_index = ""

                    indx = indx + 1;
                    img_width = jQuery(image).width()
                    img_height = jQuery(image).height()

                    exp_img_height = img_height - 20
                    console.log(exp_img_height)

                    off_d = pln_off(image)

                    jQuery('<style type="text/css" id="plannto_style_'+indx+'"> ' +
                        'a { outline: none; }' +
                        '.plannto_iframe { height:'+ n_ad_height_w_close_btn +'px;max-height:'+ img_height +'px;width:100%;overflow:hidden;cursor:pointer} ' +
                        '.plannto_hint_button {background: rgba(0, 0, 0, 0) url("http://cdn1.plannto.com/static/images/plannto_overlay_images.png") no-repeat scroll -158px -2px;cursor: pointer !important;height: 70px;opacity: 1;position: absolute;top: 11px;transition: margin-top 0.6s ease 0s;width: 26px;}'+
                        '.expand_plannto_iframe {cursor: pointer;opacity: 1;position: absolute;width: 12px;text-decoration:none;color:black;}' +
                        '.close_plannto_iframe {background-image:url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABIAAAASCAMAAABhEH5lAAAAZlBMVEUAAAAAAAAXFxcWFhYZGRkaGhoAAAAAAAALCwsNDQ0ODg7k5OTo6OjV1dXZ2dnj4+Pm5ubAwMDCwsLZ2dna2trQ0NC/v7/Dw8PHx8fNzc3R0dHS0tLq6uru7u7y8vL29vb6+vr9/f2tB0eZAAAAHHRSTlMzNDc4ODlTVVhYWLS6vL29vb/AxsbIy83Nzc3Nu0nGLwAAAFpJREFUeNq9yEcSgCAMAMAECxIpVsBC8f+f9JoHOO5x4Q+jFgBCj6y2ZxJielZWdFXn6kmskI5SDkJguj3nveHT2hRjsi0rcwelwm1YLX5AVH5m1UsEQNnD116VFgP50TblxgAAAABJRU5ErkJggg==");cursor: pointer;height: 19px;opacity: 1;position: absolute;width: 20px;left: '+(img_width - 20)+'px;' +
                        '.plannto_iframe:hover { width: '+img_width+'px;} ' +
                        '</style>').appendTo("head");

                    var height = jQuery(image).height() - 63

                    url = 'http://'+domain+'/advertisments/image_show_ads.json?item_id='+ item_ids +'&ads_id=&size='+ img_width +'*'+ n_ad_height +'&exp_size='+ img_width +'*'+ img_height +'&more_vendors=true&ad_as_widget=true&exp_img_height='+ exp_img_height +'&ref_url='+pathname
                    var impression_id = ""
                    jQuery.ajax({
                        url : url,
                        type: "get",
                        dataType:"json",
                        success:function(data)
                        {
                            if (data.success == true)
                            {
//                                n_ratio = data.n_ratio
//                                e_ratio = data.e_ratio
                                n_ad_height = data.n_ad_height
                                e_ad_height = data.e_ad_height
                                expand_type = data.expand_type
                                expand_on = data.expand_on
                                need_close_btn = data.need_close_btn
                                viewable = data.viewable
                                impression_id = data.impression_id;

                                n_ad_height_w_close_btn = n_ad_height + 20
                                e_ad_height_w_close_btn = e_ad_height + 20

                                if (expand_type == "none")
                                {
                                    z_index = ''
                                }

                                if (expand_on == '')
                                {
                                    expand_on = "click"
                                }

                                var img_h = off_d.height - n_ad_height_w_close_btn
                                var off_top = off_d.top + img_h

                                jQuery("body").append('<div class="plan_main_div_image_1" style="padding: 0px; margin: 0px; border: medium none; background: transparent none repeat scroll 0px 0px; position: static;"> ' +
                                    '<div class="plannto_in_image_ad_1" style="margin: 0px; top: '+ off_top +'px; right: 0px; height: '+ n_ad_height_w_close_btn +'px; left: '+ off_d.left +'px; overflow: hidden; padding: 0px; position: absolute; visibility: visible;width:'+ off_d.width+'px;z-index: 10000;max-width:'+img_width+'px;max-height:'+img_height+'px;"><div class="plannto_iframe" style="position: relative; height: 100%; width: 100%; background: transparent none repeat scroll 0% 0%; color: inherit; font: 12px/0.5 Arial; margin-top: 0px; opacity: 1; bottom: 0px;"><span style="width:20px;float:right;display:block;height:20px;"><a href="#" class="close_plannto_iframe"></a></span>' +
                                    '<span class="plannto_ad_tag" style="margin-right:5px;font-weight:600;color:#808080;font-family:sans-serif;font-size:11px;padding-top:7px;height:13px;right:24px;position:absolute;"><a style="text-decoration:none;font-weight: 600;color: #808080;font-family: sans-serif;font-size: 11px;" href="http://www.plannto.com" target="_blank">Ads By PlannTo</a></span> <div id="plannto_ad_frame" style="border:medium none;position:absolute;z-index:'+ z_index +';bottom:0px;background-color:white;width:'+img_width+'px;height:'+n_ad_height+'px;max-width:'+img_width+'px"> </div><div id="exp_plannto_ad_frame" style="z-index:-1;border:medium none;position:absolute;bottom:0px;display:none;width:'+img_width+'px;max-height:'+exp_img_height+'px;background-color:black;" height='+e_ad_height+'px> </div></div><div class="plannto_hint_button plannto_hint_button'+indx+'"></div></div></div>')

                                if (!need_close_btn)
                                {
                                    jQuery(".close_plannto_iframe").hide()
                                }

                                jQuery("#plannto_ad_frame").html(data.html)

                                if (viewable)
                                {
                                    jQuery(".plannto_hint_button").hide()
                                    page_visited = true
                                }
                                else
                                {
                                    jQuery(".plannto_iframe").css("width", "0px")
                                }

//                                if (visited == "1")
//                                {
//
//                                }
//                                else
//                                {
//                                    jQuery(".plannto_iframe").css("width", img_width+"px")
//                                }


                                expanded_html = data.expanded_html

                                if (expand_type == "none")
                                {
                                    expand_plannto_iframe_key = false
                                }

                                if (expand_on == "hover")
                                {
                                    var delay = 2000, setTimeoutConst;

                                    jQuery(".plannto_iframe").hover(function()
                                    {
                                        setTimeoutConst = setTimeout(function(){
                                            if (expand_type != "none")
                                            {
                                                if (pln_frame_expanded == false)
                                                {
                                                    pln_frame_expanded = true
                                                    reposition()
                                                    jQuery('.close_plannto_iframe').show()
                                                    jQuery(".plannto_iframe").animate({height: e_ad_height_w_close_btn+"px"}, "slow")
                                                    jQuery(".plannto_iframe").css({"position":"absolute"})
                                                    jQuery("#exp_plannto_ad_frame").html(expanded_html)

                                                    var video = jQuery("#exp_plannto_ad_frame").find("video")

                                                    if (video.length > 0)
                                                    {
                                                        jQuery(video).css("max-height", exp_img_height+"px")
                                                        jQuery("#exp_plannto_ad_frame").css("z-index", "")
                                                        jQuery("#exp_plannto_ad_frame").find(".plannto-advertisement").css("max-height", exp_img_height+"px")
                                                    }

                                                    jQuery("#plannto_ad_frame").hide()
                                                    jQuery("#exp_plannto_ad_frame").show()
                                                    expanded = true

                                                    return false;
                                                }
                                            }
                                        }, delay);
                                    }, function(){
                                        clearTimeout(setTimeoutConst );
                                    });

                                    jQuery(".plannto_iframe").live("click", function(event)
                                    {
                                        if (expand_type != "none")
                                        {
                                            if (pln_frame_expanded == false)
                                            {
                                                return false;
                                            }
                                            else
                                            {
                                                var expanded_view_a = jQuery(".plannto_iframe").find("#expanded_view a")
                                                var expanded_view_href = jQuery(expanded_view_a).attr("href")
                                                window.open(expanded_view_href, '_blank');
                                                return false;
                                            }
                                        }
                                    })
                                }
                                else
                                {
                                    jQuery(".plannto_iframe").live(expand_on, function(event)
                                    {
                                        if (expand_type != "none")
                                        {
                                            if (pln_frame_expanded == false)
                                            {
                                                pln_frame_expanded = true
                                                reposition()
                                                jQuery('.close_plannto_iframe').show()
                                                jQuery(".plannto_iframe").animate({height: e_ad_height_w_close_btn+"px"}, "slow")

                                                jQuery(".plannto_iframe").css({"position":"absolute"})

                                                jQuery("#exp_plannto_ad_frame").html(expanded_html)

                                                var video = jQuery("#exp_plannto_ad_frame").find("video")

                                                if (video.length > 0)
                                                {
                                                    jQuery(video).css("max-height", exp_img_height+"px")
                                                    jQuery("#exp_plannto_ad_frame").css("z-index", "")
                                                    jQuery("#exp_plannto_ad_frame").find(".plannto-advertisement").css("max-height", exp_img_height+"px")
                                                }

                                                jQuery("#plannto_ad_frame").hide()
                                                jQuery("#exp_plannto_ad_frame").show()
                                                expanded = true

                                                return false;
                                            }
                                            else
                                            {
                                                var expanded_view_a = jQuery(".plannto_iframe").find("#expanded_view a")
                                                var expanded_view_href = jQuery(expanded_view_a).attr("href")
                                                window.open(expanded_view_href, '_blank');
                                                return false;
                                            }
                                        }
                                    })
                                }
                            }
                        },
                        error: function (data) {
                            alert("Local error callback.");
                        }
                    });

                    jQuery(".close_plannto_iframe").live("hover", function(event)
                    {
                        return false;
                        event.preventDefault()
                    })

                    jQuery(".close_plannto_iframe").live("click", function(event)
                    {
                        pln_frame_closed = true
                        pln_frame_expanded = false

                        reposition()

                        jQuery('.close_plannto_iframe').hide()

                        jQuery("#exp_plannto_ad_frame").html("")
                        jQuery("#exp_plannto_ad_frame").hide()
                        jQuery(".plannto_iframe").css({"height": n_ad_height_w_close_btn+"px"})
                        jQuery("#plannto_ad_frame").show()
                        jQuery(".plannto_iframe").animate({width: "0px"}, "slow", function() { jQuery(".plannto_hint_button").show(); })

                        return false;

                        event.preventDefault()
                    })

                    jQuery(".plannto_hint_button").live("mouseenter", function(event)
                    {

                        pln_frame_closed = false
                        pln_frame_expanded = false

                        jQuery("#exp_plannto_ad_frame").hide()
                        jQuery("#exp_plannto_ad_frame").html("")
                        jQuery("#plannto_ad_frame").show()

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
            }

            jQuery(window).bind('resize', reposition);

//            sto = setInterval(reposition, 1000);

            valid_images = []

            get_valid_images()

            console.log(valid_images)
        });
    }


    return PlannTo;

})(window);
