
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
//var domain = "localhost:3000";
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
            console.log("----------------------------------")
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

                indx = indx + 1;
//                var image = jQuery("img")[0]
//            var image = jQuery(".storyimg_mar10")
                console.log(image)

                var height = jQuery(image).height() - 63
                console.log(image)

                jQuery(image).parent().css({"position":"relative", "z-index":"1"})

                jQuery(image).parent().append('<div class="plan_ad_image_1" style="position: absolute; top: '+ height +'px; z-index: 2;"> <a href="#" class="close_plannto_iframe">x</a> <iframe id="plannto_ad_frame" src="http://www.plannto.com/advertisments/show_ads?item_id=&ads_id=17&size=300*60&more_vendors=true&ad_as_widget=true&ref_url=&is_test=true" width="300px" height="60px" style="border: medium none;"></iframe></div>')


                jQuery(".close_plannto_iframe").live("click", function(event)
                {
                    jQuery(this).parent().hide()
                    return false;
                })
            })




//            var image = jQuery("img")[0]
////            var image = jQuery(".storyimg_mar10")
//            console.log(image)
//
//            var height = jQuery(image).height() - 60
//            console.log(image)
//
//            jQuery(image).css({"position":"absolute", "top":"25px", "z-index":"1"})
//
//            jQuery(image).parent().append('<div class="plan_ad_image_1" style="position: absolute; top: '+ height +'px; z-index: 2;"> <a href="#" class="close_plannto_iframe">x</a> <iframe id="plannto_ad_frame" src="http://www.plannto.com/advertisments/show_ads?item_id=&ads_id=17&size=300*60&more_vendors=true&ad_as_widget=true&ref_url=&is_test=true" width="300px" height="60px" style="border: medium none;"></iframe></div>')
//
//
//            jQuery(".close_plannto_iframe").live("click", function(event)
//            {
//                jQuery(this).parent().hide()
//                return false;
//            })



//            var doc_title =  jQuery(document).title;
//            var pathname = getParam(url,"ref_url");
//            var item_id = getParam(url,"item_id");
//            var show_details = getParam(url,"show_details");
//            var show_offer = getParam(url,"show_offer");
//
//            var show_price = getParam(url,"show_price");
//            var ads = getParam(url,"advertisement");
//            var element_id = getParam(url,"element_id");
//            is_test = getParam(url,"is_test");
//            page_type = getParam(url,"page_type");
//

//            if (ads == "")
//            {
//                if(element_id == undefined || element_id == "")
//                {
//                    element_id = "where_to_buy_items";
//                }
//                element = jQuery("#"+element_id)
//                planntowtbdivcreation (item_id,show_details,"wheretobuymain",element,element_id,pathname,show_price,show_offer,false)
//
//            }
//            else
//            {
//
//                if(element_id == undefined || element_id == "")
//                {
//                    element_id = "advertisement";
//                }
//                url = "http://"+ domain +"/advertisement.js?item_ids="+item_id+"&price_full_details="+show_details+"&ref_url="+pathname+"&doc_title-"+doc_title+"&callback=?"
//                jQuery.getJSON(url, function (data) {
//                    jQuery("#"+element_id).html(data.html);
//                });
//            }

            /*  jQuery("#where_to_buy_items_a").live("click", function(){
             SubPath = "/where_to_buy_items.js"
             url = url = "http://"+domain + SubPath + "?item_ids="+item_id+"&price_full_details="+show_details+"&ref_url="+pathname+"&doc_title-"+doc_title+"&callback=?";
             element_id = "where_to_buy_items1"
             jQuery.getJSON(url, function (data) {
             jQuery("#"+element_id).html(data.html);
             });
             })
             */
            //url = "http://www.plannto.com/where_to_buy_items.js?item_ids="+item_id+"&price_full_details="+show_details+"&ref_url="+pathname+"&doc_title-"+doc_title+"&callback=?"

        });
    }


    return PlannTo;

})(window);
