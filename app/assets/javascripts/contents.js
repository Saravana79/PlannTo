var running = false;


$(function(){

  $('ul.navdrop a').live("click",function(){

    $(this).parent().toggleClass('selected');
    var guide = $(this).data('guide');
    var content = $(this).closest('ul.navdrop').data('content');
    $.ajaxSetup({
      'beforeSend':function(xhr){xhr.setRequestHeader("Accept","text/javascript")}
    });

    $.post('/contents/update_guide',{'content' : content, 'guide' : guide });

  });
  });
  
   $('ul.item_drop a').live("click",function(){
    $(this).parent().toggleClass('selected');
     var sort_by = $("span#sortBy a.link_active").text();
    $("div#Filterby div.Filternav ul").find('li').removeClass('Currentfilter');
    $("li.feed_filter").addClass("Currentfilter")
    var types = [];
    $("ul.item_drop li.selected a").each(function() {
  types.push($(this).data('type'))
});
    
   $.ajaxSetup({
      'beforeSend':function(xhr){xhr.setRequestHeader("Accept","text/javascript")}
    });

    $.get('/my_feeds',{'item_types' :types,'type': "category",'search_type': $("#search_type").val(), 'sort_by': sort_by });
    });



//for tabs
$("ul#Newtabs li a").live('click', function(){
    $("ul#Newtabs").find('li').removeClass('tab_active');
        $(this).closest('li').addClass("tab_active");
        $(".main-content-section").hide();
        var activeTab = $(this).attr("href");
        $("div" + activeTab).show();
        return false;

  });
 function setActiveTab(id){
  	$("ul#Newtabs").find('li').removeClass('tab_active');
  	$('li#all_variant').addClass('tab_active');
  	$('div#all_variants').show();  
  	$('div#overview').hide();	
  } 
  
  
  
    function contentSearchFilterAction(action, sub_type, items, filter_page_no, itemtype_id, sort_by, guide){
     
  	 $.ajax({url : "/contents/" + action , dataType:'script',type: "get",data: 'sub_type=' + sub_type + '&items=' + items + '&page=' + filter_page_no + '&itemtype_id=' + itemtype_id + '&sort_by=' + sort_by + '&search_type=' + $("#search_type").val() + '&guide=' + guide,before:$('#spinner1').show(),success: function(data){$('#spinner1').hide();
 }});    
 }
  	
   function find_sub_type(id){
   	switch(id){
            case 'All' :  var sub_type = "All";break;
            case 'HowTo': var sub_type = "HowTo/Guide";break;
            case 'HowTo/Tips': var sub_type = "HowTo/Guide";break;
            case 'Q&A': var sub_type = "QandA";break;
            default:  var sub_type = id;
          }
          return sub_type
   }
   
   function triggerScrollFunction(sub_type, items, itemtype_id, guide){
   	$(window).scroll(function () {		
      lnk = $('#content_next');
      if (!running && lnk && $(window).scrollTop() >= $('#content_all').height() - $(window).height()) {     
        running = true;
        if ($("#content_search_search").val().toString() == ""){       	
        	var sub_type = find_sub_type($("div#Filterby div.Filternav ul li.Currentfilter").text()) 
          	var filter_page_no = $("#filter_page_no").val()
          	var sort_by = $("span#sortBy a.link_active").text();
          	var action = "feeds"
          	contentSearchFilterAction(action, sub_type, items, filter_page_no, itemtype_id, sort_by, guide);        
        	return false
      	}
        else
      {
      	$("#contentSearchForm").bind('ajax:complete', function() { running = false});
    	$("#contentSearchForm").submit()    	
    	 return false     	 
      }
      }    
    });
   }
  
  
  function triggerScrollFunctionMyfeeds(sub_type, items, itemtype_id, guide){
   	$(window).scroll(function () {		
      lnk = $('#content_next');
      if (!running && lnk && $(window).scrollTop() >= $('#content_all').height() - $(window).height()) {     
        running = true;
        if ($("#content_search_search").val().toString() == ""){       	
        	var sub_type = find_sub_type($("div#Filterby div.Filternav ul li.Currentfilter").text()) 
          	var filter_page_no = $("#filter_page_no").val()
          	var sort_by = $("span#sortBy a.link_active").text();
          	var itemtype_id = $("#item_types").val();
            var items =  $("#items").val();
          	var action = "feeds"
          	contentSearchFilterAction(action, sub_type, "", filter_page_no, itemtype_id, sort_by, guide);        
        	return false
      	}
        else
      {
      	$("#contentSearchForm").bind('ajax:complete', function() { running = false});
    	$("#contentSearchForm").submit()    	
    	 return false     	 
      }
      }    
    });
   }  
   
  function autoPlayVideo(vcode,content){
     $('#youtube_image' + content).html('<iframe type="text/html" width="640" height="385" src="https://www.youtube.com/embed/'+vcode+'?autoplay=1&loop=1&rel=0&wmode=transparent" frameborder="0" allowfullscreen wmode="Opaque"></iframe>');
  } 

 

