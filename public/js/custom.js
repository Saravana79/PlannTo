(function($) {

	// Scroll back to top
	$('#btop').click(function(){
		$.smoothScroll({
			scrollTarget: '.top',
			 speed: 1000
		});
		return false;
	});
	// Conditional display	
	$(window).scroll(function () {
		if ($(this).scrollTop() > 400) {
			$('#btop').fadeIn('slow');
		} else {
			$('#btop').fadeOut('slow');
		}
	});
	
})( jQuery );
