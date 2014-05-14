
if(scriptCount == undefined)
{
  var scriptCount = 0;
  
}

var PlannTo = (function(window,undefined) {

var PlannTo ={};
var SubPath="/where_to_buy_items.js"
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
        var item_id =  PlannTo.jQuery(obj).val();
        var show_details = moredetails;
        var element_id = PlannTo.jQuery(obj).parent().parent().parent().next();
        parentDiv = element_id.parent().parent().parent().parent().parent().parent().parent().attr('id');
        planntowtbdivcreation (item_id,show_details,"onchange",element_id,parentDiv,"pathname","","");
        event.preventDefault();
    
  }

    PlannTo.onclick_function = function onclick_function(id, obj,moredetails)
    {
        var item_id =  id;
        var show_details = moredetails;
        PlannTo.jQuery(".nav-tabs li").removeClass('active')
        PlannTo.jQuery(obj).parent().addClass('active')
        var element_id = PlannTo.jQuery("#where_to_buy_items_onchange")
        parentDiv = "where_to_buy_items1"
        planntowtbdivcreation (item_id,show_details,"onchange",element_id,parentDiv,"pathname","","");
        event.preventDefault();

    }


    PlannTo.wheretobuytabclick = function wheretobuytabclick(obj,moredetails,item_ids)
  {
        var show_details = moredetails;
        var element_id = PlannTo.jQuery(obj).parent().parent().parent().parent().next().children()
        parentDiv = PlannTo.jQuery(obj).parent().parent().parent().parent().parent().parent().parent().attr('id');
        planntowtbdivcreation (item_ids,show_details,"wheretobuytab",element_id,parentDiv,"","","");
        event.preventDefault();
    
  } 

    PlannTo.offertabclick = function offertabclick(obj,moredetails,item_ids)
  {
        var doc_title =  PlannTo.jQuery(document).title;
        var pathname = PlannTo.jQuery(document).referrer;
        var show_details = moredetails;
        var element_id = PlannTo.jQuery(obj).parent().parent().parent().parent().next().children()
        parentDiv = PlannTo.jQuery(obj).parent().parent().parent().parent().parent().parent().parent().attr('id');
        url = "http://"+domain + "/product_offers.js" + "?item_ids="+item_ids+"&price_full_details="+show_details+ "&path=" + "offer" +"&ref_url="+pathname+"&doc_title-"+doc_title+"&callback=?";          
          jQuery.getJSON(url, function (data) {            
            element_id.html(data.html);            
            jQuery(jQuery("#"+parentDiv).children().children().children().children().children().children()[0]).removeClass();
            jQuery(jQuery("#"+parentDiv).children().children().children().children().children().children()[0]).addClass("unselected");
            jQuery(jQuery("#"+parentDiv).children().children().children().children().children().children()[1]).removeClass();
            jQuery(jQuery("#"+parentDiv).children().children().children().children().children().children()[1]).addClass("selected");
            jQuery(".navigate_offer").live("click", function(e){
              show = jQuery(this).attr("href");              
              jQuery(this).closest("tr").parent().parent().parent().parent().hide();
              jQuery("#"+show).show();
              event.preventDefault()
            })
          });
    event.preventDefault();    
  } 

    function planntowtbdivcreation(item_ids,show_details,path, element_id, parentdivid,pathname,show_price,show_offer)
    {
            var doc_title =  PlannTo.jQuery(document).title;
           
          url = "http://"+domain + SubPath + "?item_ids="+item_ids+"&price_full_details="+show_details+"&show_offer="+show_offer+"&show_price="+show_price+ "&path=" + path + "&ref_url="+pathname+"&doc_title-"+doc_title+"&callback=?"

            jQuery.getJSON(url, function (data) {
                element_id.html(data.html);                
                 jQuery(jQuery("#"+parentdivid).children().children().children().children().children().children()[1]).removeClass();
                 jQuery(jQuery("#"+parentdivid).children().children().children().children().children().children()[1]).addClass("unselected");
                 jQuery(jQuery("#"+parentdivid).children().children().children().children().children().children()[0]).removeClass();
                 jQuery(jQuery("#"+parentdivid).children().children().children().children().children().children()[0]).addClass("selected");
                if(show_details.toString() == "true" && jQuery("#"+ parentdivid).width() < 300)
                    {
                      jQuery("#" + parentdivid +" table tr td:nth-child(3)").css("display","none");
                      /*jQuery("#" + parentdivid +" table tr td:nth-child(4)").css("display","none");*/
                      tr = jQuery("#" + parentdivid +" table tr:eq(9)");
                      if(tr.children()[0].colSpan ==3)
                      {                
                          tr.children()[0].colSpan =2                
                      }
                      //tr.children()[0].children().innerText = "View more";
                    }
                if(show_price.toString() == "false")
                {
                    jQuery(".navigate_offer").live("click", function(e){
                    show = jQuery(this).attr("href");              
                    jQuery(this).closest("tr").parent().parent().parent().parent().hide();
                    jQuery("#"+show).show();
                    event.preventDefault()
                  })
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
        var show_offer = getParam(url,"show_offer");
        
        var show_price = getParam(url,"show_price");
        var ads = getParam(url,"advertisement");
        var element_id = getParam(url,"element_id");
        if (ads == "")
        {
          if(element_id == undefined || element_id == "")
          {
            element_id = "where_to_buy_items";
          }
          element = jQuery("#"+element_id)
         planntowtbdivcreation (item_id,show_details,"wheretobuymain",element,element_id,pathname,show_price,show_offer)

       }
       else
       {
      
      if(element_id == undefined || element_id == "")
        {
          element_id = "advertisement";
        }
        url = "http://"+ domain +"/advertisement.js?item_ids="+item_id+"&price_full_details="+show_details+"&ref_url="+pathname+"&doc_title-"+doc_title+"&callback=?"
        jQuery.getJSON(url, function (data) {
            jQuery("#"+element_id).html(data.html);           
        });
      }

      jQuery("#product_offers").live("click", function(){
          
        });

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
