var running = false;


$(function(){
  $('ul.navdrop a').click(function(){
    
    $(this).parent().toggleClass('selected');
    var guide = $(this).data('guide');
    var content = $(this).closest('ul.navdrop').data('content');
    $.ajaxSetup({
      'beforeSend':function(xhr){xhr.setRequestHeader("Accept","text/javascript")}
    });

    $.post('/contents/update_guide',{'content' : content, 'guide' : guide });

  });
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
  
  
  
   function contentSearchFilterAction(action, sub_type, items, filter_page_no, itemtype_id, sort_by){
  	 $.get("/contents/" + action ,
  	 {sub_type: sub_type, items: items, page: filter_page_no, itemtype_id: itemtype_id, sort_by: sort_by},
     
          function(data, status, xhr)
          {
            running = false;
          }
        );  
       }
       
   function find_sub_type(id){
   	switch(id){
            case 'All' :  var sub_type = "All";break;
            case 'HowTo': var sub_type = "HowTo/Guide";break;
            case 'Q&A': var sub_type = "QandA";break;
            default:  var sub_type = id;
          }
          return sub_type
   }
  


