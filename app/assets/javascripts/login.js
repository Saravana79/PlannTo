var plannto_popup_login_id = "";
var login_flag = "";
var click_type = "";

function openLoginPopup(clickable_link_id, c_type){
    if (login_flag != true){
        plannto_popup_login_id = clickable_link_id;
        click_type = c_type;

        $('#plannto_signin_box').dialog({
            modal: true,
            height: 600,
            width: 350
        });
        $('.plannto_Close_dialog').show();
        $('.ui-dialog-titlebar').hide();
    }
}


function closeLoginPopup(){
    login_flag = true;
    $('#plannto_signin_box').dialog('close');
    $("" + plannto_popup_login_id).trigger(click_type);
    
}