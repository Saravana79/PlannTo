$(function(){


$('#new_review_content #rating').each(function(){
    $(this).raty({
      starOff:	'assets/star-off.png',
      starOn:	'assets/star2.gif',
      scoreName:    'review_content[rating]',
      width: 	'200px'
      // start:        $(this).attr('data-rating'),
      // readOnly:     true,
    });
});
	
})