 $('div.Boxtopblock span.Openclosebut a').live('click', function(){
    $("#wizardbutton").toggleClass('Close Open');
    $(this).text(function(i,text) { return (text == 'Close') ? 'Open' : 'Close'; });
    $("div.Grayboxmid").toggle();
    return false;
  })