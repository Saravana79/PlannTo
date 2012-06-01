

$(function(){
    $('#add_new_comment').click(function(){
            $('#reviewSmallDiv').hide();
            $('.new_comment_form_wrapper').show();
        });
        
    //$('textarea.comment_box').autoResize();

    $('.invokecomment').click(function(){
        $(this).hide();
        $(this).next().show();
    });
    
})


// $(function(){
// 	$('#comment_this_content').click(function(){
// 		$('#new_comment_block').toggle();
// 	});
// });