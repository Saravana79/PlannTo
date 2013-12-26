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
       jQuery = window.jQuery.noConflict();
        PlannTo.jQuery = jQuery;
        // Call our main function
        if (window.jQuery.ui === undefined)
        {
            jQuery.getScript('http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.6/jquery-ui.min.js', function() {
                     jQuery.noConflict(true);
            });
        }
        main();
        
    }


    /******** Main function ********/
    function main() {
        // return if jQuery("#planto_search_items").length <= 0
        jQuery(document).ready(function (jQuery) {
        	iframe = jQuery("<iframe>");
        url = 
        iframe.attr("src", "http://" + domain + "/get_item_item_advertisment?callback=?");
        jQuery("#advt_planto_item").html(iframe)
        });


    }


    return PlannTo;

})(window);