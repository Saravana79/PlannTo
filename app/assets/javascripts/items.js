//$(document).ready(function(){
    //$('span.Openclosebut a#wizardbutton').click(function() {
    $('div.Homepopupgraybox div.Boxtopblock span.Openclosebut a#wizardbutton').live('click', function(){
        $("#wizardbutton").toggleClass('Close Open');
        $(this).text(function(i,text) {
            return_text =  (text == 'Close') ? 'Open' : 'Close';
        });
       $("span.Openclosebut a#wizardbutton").text(return_text);   
        $("div.Grayboxmid").toggle();
        return false;
    })
//});