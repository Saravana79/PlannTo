$(function(){

  $('#new_review_content #rating').raty({
      starOff:  'assets/star-off.png',
      starOn: 'assets/star2.gif',
      scoreName:    'review_content[rating]',
      width:  '200px'
  });

  $('.displayRating').each(function(){
      $(this).raty({
        readOnly: true,
        starOff:  'assets/star-off.png',
        starOn: 'assets/star2.gif',
        start:  $(this).attr('data-rating')
      });
  });

  
});


