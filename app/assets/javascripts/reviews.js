$(function(){

 /* $('#new_review_content #rating').raty({
      starOff:  'assets/star-off.png',
      starOn: 'assets/star-on.png',
      scoreName:    'review_content[rating]',
      width:  '200px'
  });*/
//below rating is conflicting with product page rating.
  /*$('.displayRating').each(function(){
      $(this).raty({
        readOnly: true,
        starOff:  'assets/star-off.png',
        starOn: 'assets/star-on.png',
        starHalf:   'assets/star-half.png',
        start:  $(this).attr('data-rating')
      });
  });*/


  $('.review_tabs ul li').click(function(){
    if($(this).hasClass('clicked')){ return;}
    $('#textarea_review_div').hide();
    var previous_tab = $('.review_tabs ul li.clicked');
    var previous_div = previous_tab.attr('data-div');
    var current_div  = $(this).attr('data-div');

    previous_tab.children('a').removeClass('active_tabs').addClass('review_tabs');
    $(this).children('a').removeClass('review_tabs').addClass('active_tabs');
    previous_tab.removeClass('clicked');
    $('#' + previous_div + 'Div').hide();
    $('#' + current_div + 'Div').show();
    $(this).addClass('clicked');
  });
  
});


