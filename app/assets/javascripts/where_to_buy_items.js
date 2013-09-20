
(function() {

// Localize jQuery variable
var jQuery;

/******** Load jQuery if not present *********/
if (window.jQuery === undefined || window.jQuery.fn.jquery !== '1.4.2') {
    var script_tag = document.createElement('script');
    script_tag.setAttribute("type","text/javascript");
    script_tag.setAttribute("src",
        "http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js");
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
    main();
}

/******** Called once jQuery has loaded ******/
function scriptLoadHandler() {
    // Restore jQuery and window.jQuery to their previous values and store the
    // new jQuery in our local jQuery variable
    jQuery = window.jQuery.noConflict(true);
    // Call our main function
    main(); 
}

/******** Our main function ********/
function main() { 
    jQuery(document).ready(function(jQuery) { 
        url = "http://0.0.0.0:3000/products/where_to_buy_items/"+jQuery("#where_to_buy_items").attr("item")+".js?callback=?"
		jQuery.getJSON(url, function (data) {
			console.log(data)
	        	widget = build_widget(data.html, jQuery);
	        	jQuery("#where_to_buy_items").html(widget);
	    });
    });
}

})();



function build_widget(data, jQuery){
   var table = jQuery('<table>')
   jQuery(data).each(function( index ) {
   	  tr = jQuery("<tr>");

   	  td1 = jQuery("<td>");
   	  td1.html(this.image_url);
	  jQuery(td1).appendTo(jQuery(tr));
	  td1 = jQuery("<td>");
   	  td1.html(this.display_price);
	  jQuery(td1).appendTo(jQuery(tr));
	  td1 = jQuery("<td>");
   	  td1.html(this.history_detail);
	  jQuery(td1).appendTo(jQuery(tr));
	  jQuery(tr).appendTo(table);
	});
   return jQuery(table);
}
