var plannto_popup_login_id = "";
var login_flag = "";
var click_type = "";

function openLoginPopup(clickable_link_id, c_type){
    if (login_flag != true){
        plannto_popup_login_id = clickable_link_id;
        click_type = c_type;

        $('#login-feed').bPopup({
          closeClass:'Closebut',
          modalClose: false,
          position: [(screen.width / 2) - (270 /2), $(window).scrollTop() + 150],
          follow: [false, false]
        });
        //$('.Close_dialog').show();
        //$('.ui-dialog-titlebar').hide();
    }
    
}


function closeLoginPopup(){
    login_flag = true;
    $('#login-feed').dialog('close');
    $("" + plannto_popup_login_id).trigger(click_type);
    
}
