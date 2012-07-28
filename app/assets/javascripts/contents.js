
$(function(){
  $('select.content_guide').dropdownchecklist({
      width: 150,
      onComplete: function(selector){
        var values = "";
        var content = "";
          for( i=0; i < selector.options.length; i++ ) {
              if (selector.options[i].selected && (selector.options[i].value != "")) {
                  if ( values != "" ) values += ";";
                  values += selector.options[i].value;
              }
          }
        $.ajaxSetup({
            'beforeSend':function(xhr){xhr.setRequestHeader("Accept","text/javascript")}
        });

        $.post('/contents/update_guide',{'content' : $('#' + selector.id).data('content'), 'guide' : values });

    }
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


