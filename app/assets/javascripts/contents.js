//for tabs
$("ul#Newtabs li a").live('click', function(){
    $("ul#Newtabs").find('li').removeClass('tab_active');
        $(this).closest('li').addClass("tab_active");
        $(".main-content-section").hide();
        var activeTab = $(this).attr("href");
        $("div" + activeTab).show();
        return false;

  })
  
  
  function setActiveTab(id){
  	$("ul#Newtabs").find('li').removeClass('tab_active');
  	$('li#all_variant').addClass('tab_active');
  	$('div#all_variants').show();  	
  }
