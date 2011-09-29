$(function(){
    $('#reviewSmallDiv textarea').click(function(){
        $(this).parent().hide();
        $('#reviewDiv').show();
        $('#reviewDiv textarea').focus();
    });

    $('#reviewDiv #save_review').click(function(){
         $.post(root_url + "/reviews/create",function(){
            alert('success' );
         });
         return false;
    });
});
