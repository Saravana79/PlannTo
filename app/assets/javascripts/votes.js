$(function(){
    $('.midcol a:first-child').click(function(){
        var upvote =  $(this);
        var parent = upvote.parent();
        var downvote = parent.children().last();
        
        parent.toggleClass('likes');
        parent.removeClass('dislikes',!parent.hasClass('dislikes'));
        parent.toggleClass('unvoted',!parent.hasClass('likes'));

        upvote.toggleClass('up upmod');
        if(downvote.hasClass('downmod')){
            downvote.removeClass('downmod');
            downvote.addClass('down');
        }        
    });

    $('.midcol a:last-child').click(function(){
        var downvote =  $(this);
        var parent = downvote.parent();
        var upvote = parent.children().first();

        parent.toggleClass('dislikes');
        parent.removeClass('likes',!parent.hasClass('likes'));
        parent.toggleClass('unvoted',!parent.hasClass('dislikes'));

        downvote.toggleClass('down downmod');
        if(upvote.hasClass('upmod')){
            upvote.removeClass('upmod');
            upvote.addClass('up');
        }
    });

});
