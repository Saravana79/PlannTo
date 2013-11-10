
if(scriptCount == undefined)
{
  var scriptCount = 0;
  
}

var PlannTo = (function(window,undefined) {

var PlannTo ={};
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
      
      if (src.indexOf(domain+"/javascripts/plannto.widget.js") != -1)
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

PlannTo.onchange_function = function onchange_function(obj,moredetails)
  {
        url = getScriptUrl();
        var doc_title =  PlannTo.jQuery(document).title;
        var pathname = PlannTo.jQuery(document).referrer;
        var item_id =  PlannTo.jQuery(obj).val();
        var show_details = moredetails;

        var element_id = PlannTo.jQuery(obj).parent().parent().parent().next();
        url = "http://"+domain +"/where_to_buy_items.js?item_ids="+item_id+"&price_full_details="+show_details+ "&onchange=" + "true" + "&ref_url="+pathname+"&doc_title-"+doc_title+"&callback=?"
        PlannTo.jQuery.getJSON(url, function (data) {          
            element_id.html(data.html);
            parentDiv = element_id.parent().parent().parent().parent().parent().parent().parent();
             if(moredetails == true && parentDiv.width() < 300)
                {
                  jQuery("#" + parentDiv.attr('id') +" table tr td:nth-child(3)").css("display","none");
                  tr = jQuery("#" + parentDiv.attr('id') +" table tr:eq(9)");
                  tr.children()[0].colSpan =2                
                }
        });
  }  


/******** Main function ********/
function main() { 
    
    jQuery(document).ready(function(jQuery) { 
        url = getScriptUrl();
        var doc_title =  jQuery(document).title;
        var pathname = getParam(url,"ref_url");        
        var item_id = getParam(url,"item_id");
        var show_details = getParam(url,"show_details");
        var ads = getParam(url,"advertisement");
        var element_id = getParam(url,"element_id");
        if (ads == "")
        {
        if(element_id == undefined || element_id == "")
        {
          element_id = "where_to_buy_items";
        }
       url = "http://"+domain +"/where_to_buy_items.js?item_ids="+item_id+"&price_full_details="+show_details+"&ref_url="+pathname+"&doc_title-"+doc_title+"&callback=?"
       }
       else
       {
      
      if(element_id == undefined || element_id == "")
        {
          element_id = "advertisement";
        }
       url = "http://"+ domain +"/advertisement.js?item_ids="+item_id+"&price_full_details="+show_details+"&ref_url="+pathname+"&doc_title-"+doc_title+"&callback=?"
      }
       
        //url = "http://www.plannto.com/where_to_buy_items.js?item_ids="+item_id+"&price_full_details="+show_details+"&ref_url="+pathname+"&doc_title-"+doc_title+"&callback=?"
		    jQuery.getJSON(url, function (data) {
	        	jQuery("#"+element_id).html(data.html);
            if(show_details == "true" && jQuery("#"+element_id).width() < 300)
                {
                  jQuery("#" + element_id +" table tr td:nth-child(3)").css("display","none");
                  tr = jQuery("#" + element_id +" table tr:eq(9)");
                  tr.children()[0].colSpan =2
                  //tr.children()[0].children().innerText = "View more";
                }
	      });
      });
    }
 
 
  return PlannTo;
  
  })(window);
