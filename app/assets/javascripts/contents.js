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
  }


