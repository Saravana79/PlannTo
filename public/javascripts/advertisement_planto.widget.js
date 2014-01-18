if (scriptCount == undefined) {
    var scriptCount = 0;

}

var PlannTo = (function (window, undefined) {

    var PlannTo = {};
    // var SubPath = "/search_planto.js"
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
            "http://localhost:3000/assets/jquery.js?body=1");
        
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
            "http://localhost:3000/assets/jquery-ui.js?body=1");
        
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
            "http://localhost:3000/assets/jquery.jcarousel.min.js?body=1");
        
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
        
        // jQuery.getScript('http://localhost:3000/assets/jquery-ui.js', function() {
        //              jQuery.noConflict(true);
        //     });
        //     jQuery.getScript('http://localhost:3000/assets/jquery.jcarousel.min.js', function() {
        //              jQuery.noConflict(true);
        //     });
            


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
        // if (window.jQuery.jcarousel === undefined)
        // {
            // jQuery.getScript('http://localhost:3000/assets/jquery-ui.js', function() {
            //          jQuery.noConflict(true);
            // });
            // jQuery.getScript('http://localhost:3000/assets/jquery.jcarousel.min.js', function() {
            //          jQuery.noConflict(true);
            // });
            alert(jQuery)
        // }
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
        for (var i = 0; i < scripts.length; i++) {
            element = scripts[i];
            src = element.src;

            if (src.indexOf(domain + "/javascripts/advertisement_planto.widget.js") != -1) {
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




    /******** Main function ********/
    function main() {
        // return if jQuery("#planto_search_items").length <= 0
        jQuery(document).ready(function (jQuery) {
            url = getScriptUrl();
            var dynamic = getParam(url, "dynamic");
            var height = getParam(url, "height");
            var width = getParam(url, "width");
            alert(url)
            if(dynamic){
                url = "http://" + domain + "/get_item_item_advertisment?dynamic="+dynamic+"&height="+height+"&width="+width+"&callback=?"

                jQuery.getJSON(url, function (data) {


                    jQuery("#advt_planto_item").replaceWith(data.html);
                    jQuery('.jcarousel').jcarousel({wrap: 1});
                    // jQuery(".where_to_buy_searched,.productinwizard").bind("click", function () {
                    //     item_id = parseInt(jQuery(this).attr("id").replace("product", ""));
                    //     where_to_buy(jQuery(this).attr("id"), show_details, element, element_id, pathname, url)
                    // })
                    // autoComplete()
                   event.preventDefault()     
                });
         
            }else{
        	   iframe = jQuery("<iframe>");
                iframe.attr("src", url);
                jQuery("#advt_planto_item").html(iframe);
                
            }
        
        });


    }


    return PlannTo;

})(window);