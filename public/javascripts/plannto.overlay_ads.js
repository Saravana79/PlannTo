
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

        jQuery(document).ready(function(jQuery) {
            url = getScriptUrl();
            var doc_title =  jQuery(document).title;
            var pathname = getParam(url,"ref_url");
            var visible = getParam(url,"visible");
            console.log("----------------------------------")
            console.log(visible == "true")
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
                var visited = false

                indx = indx + 1;
                var width = jQuery(image).width()

                jQuery('<style type="text/css" id="plannto_style_'+indx+'"> ' +
                    'a { outline: none; }' +
                    '.plannto_iframe { position:absolute;width:100%;overflow:hidden;} ' +
                    '.plannto_hint_button {background: rgba(0, 0, 0, 0) url("http://cdn1.plannto.com/static/assets/cbolaSprite.png") no-repeat scroll -158px -2px;cursor: pointer !important;height: 70px;opacity: 1;position: absolute;top: 11px;transition: margin-top 0.6s ease 0s;width: 26px;z-index: 5 !important;}'+
                    '.close_plannto_iframe {background: rgba(0, 0, 0, 0) url("http://cdn1.plannto.com/static/assets/cbolaSprite.png") no-repeat scroll -50px -24px;cursor: pointer;height: 19px;opacity: 1;position: absolute;width: 20px;z-index: 5;left: '+(width - 20)+'px;' +
                    '.plannto_iframe:hover { width: '+width+'px;} ' +
                    '</style>').appendTo("head");

                var height = jQuery(image).height() - 63
                console.log(image)

                url = 'http://'+domain+'/advertisments/image_show_ads.json?item_id=&ads_id=62&size=&more_vendors=true&ad_as_widget=true&ref_url='+pathname+'&visible='+visible
                var impression_id = ""
                jQuery.ajax({
                    url : url,
                    type: "get",
                    dataType:"json",
                    success:function(data)
                    {
                        if (data.success == true)
                        {
                            impression_id = data.impression_id
                            jQuery(image).parent().css({"position":"relative", "z-index":"1"})

                            jQuery(image).parent().append('<div class="plan_ad_image_1" style="position: absolute; bottom: 90px; z-index: 2;width:100%;"> ' +
                                '<div class="plannto_iframe"><a href="#" class="close_plannto_iframe"></a> <iframe id="plannto_ad_frame" src="" style="border:medium none;" height="90px" width="'+width+'px"> </iframe></div>' +
                                '<div class="plannto_hint_button plannto_hint_button'+indx+'"></div>' +
                                '</div>')

                            jQuery("#plannto_ad_frame").attr("src","data:text/html;charset=utf-8," + encodeURI(data.html))

                            if (visible == "true")
                            {
                                jQuery(".plannto_hint_button").hide()
                                visited = true
                            }
                            else
                            {
                                jQuery(".plannto_iframe").css("width", "0px")
                            }

                            var iframe_body = jQuery("#plannto_ad_frame").contents().find("body")
                            console.log(iframe_body)
                            jQuery(iframe_body).css({"width":"500px", "height":"90px", "overflow": "hidden"})
                        }
                    }
                });

                jQuery(".close_plannto_iframe").live("click", function(event)
                {
                    jQuery(".plannto_iframe").animate({width: "0px"}, "slow", function() { jQuery(".plannto_hint_button").show() })
                    return false;
                })

                jQuery(".plannto_hint_button").live("mouseenter", function(event)
                {
                    jQuery(".plannto_iframe").animate({width: width+"px"}, "slow")
                    jQuery(".plannto_hint_button").hide()

                    if (visited == false)
                    {
                        jQuery.post('http://'+domain+'/advertisements/ads_visited', {"impression_id": impression_id})
                        visited = true
                    }

                    return false;
                })
            })
        });
    }


    return PlannTo;

})(window);
