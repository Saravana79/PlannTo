
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

            if (src.indexOf(domain+"/javascripts/plannto.adv_widget.js") != -1)
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
            var element_id = getParam(url,"element_id");
            var size = getParam(url,"ad_size");
            var wo_ads_id = getParam(url,"wo_ads_id");
            var url_arr = url.split("/");
            url_protocol = url_arr[0]

            if (element_id == undefined || element_id == "")
            {
                element_id = "PlannTo_adv_div";
            }
            element = jQuery("#"+element_id)

            console.log("----------------------------------")

            console.log("started creating ad")


//            url = url_protocol + "//"+ domain +"/advertisements/get_adv_id.json?item_ids="+item_ids+"&ref_url="+pathname
            var adv_url = url_protocol + "//"+ domain+'/advertisements/show_ads?item_id='+ item_ids +'&ads_id=&size='+ size +'&wo_ads_id=true&format=json&ref_url='+pathname

            jQuery.ajax({
                url: adv_url,
                type: "get",
                dataType: "json",
                success: function (data) {
                    if (data.success == true)
                    {
                        if (size != "" && size != undefined)
                        {
                            if (size.indexOf("x") >= 0)
                            {
                                iframe_width = size.split("x")[0]
                                iframe_height = size.split("x")[1]
                            }
                            else if (size.indexOf("*") >= 0)
                            {
                                iframe_width = size.split("*")[0]
                                iframe_height = size.split("*")[1]
                            }
                        }

                        element.html(data.html)

//                        element.append("<iframe src="+adv_url +" width="+iframe_width+"px height="+iframe_height+"px style='border: medium none;'></iframe>")
                    }
                }
            });


//            url = url_protocol + "//"+ domain +"/advertisements/get_adv_id.json?item_ids="+item_ids+"&ref_url="+pathname
//
//            jQuery.ajax({
//                url: url,
//                type: "get",
//                dataType: "json",
//                success: function (data) {
//                    if (data.success == "true")
//                    {
//                        console.log(data)
//                        console.log(data.ad_id)
//
//                        var adv_url = url_protocol + "//"+ domain+'/advertisements/show_ads?item_id='+ item_ids +'&ads_id='+data.ad_id+'&size='+ size +'&ad_as_widget=&ref_url='+pathname
//                        console.log(adv_url)
//
//                        if (size != "" && size != undefined)
//                        {
//                            if (size.indexOf("x") >= 0)
//                            {
//                                iframe_width = size.split("x")[0]
//                                iframe_height = size.split("x")[1]
//                            }
//                            else if (size.indexOf("*") >= 0)
//                            {
//                                iframe_width = size.split("*")[0]
//                                iframe_height = size.split("*")[1]
//                            }
//                        }
//
//                        element.append("<iframe src="+adv_url +" width="+iframe_width+"px height="+iframe_height+"px style='border: medium none;'></iframe>")
//                    }
//                }
//            });

        });
    }


    return PlannTo;

})(window);
