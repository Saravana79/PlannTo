$(function(){
    $('#reviewSmallDiv textarea').click(function(){
        $(this).parent().hide();
        $('#reviewDiv').show();
        $('#reviewDiv textarea').focus();
    });

/*
    $('#reviewDiv #save_review').click(function(){
         $.post(root_url + "/reviews/create",function(){
            alert('success' );
         });
         return false;
    });
*/
    $('#testfoo').click(function(){
        var ser = $('#new_review').serialize();
        console.log(ser);
        return false;
//        $.ajax({
//         type: "POST",
//         url: "/reviews/create",
//         data: { translation : { source : 'Example', output: 'Ejemplo', lang: 'Spanish'} }
//         });
    });


$('#rating').raty({
  starOff:	'assets/star-off.png',
  starOn:	'assets/star2.gif',
  scoreName:    'rating',
  start:        ''
});
    
});
