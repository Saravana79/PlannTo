$(function(){

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


