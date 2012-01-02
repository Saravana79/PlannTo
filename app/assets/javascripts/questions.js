$(function() {
	$('select#question-sort').change(function() {
		var sort_order = $(this).find('option:selected').val();
		jQuery.ajaxSetup({
			'beforeSend' : function(xhr) {
				xhr.setRequestHeader("Accept", "text/javascript")
			}
		});
		$.get('/questions/', {
			sort_option : sort_order
		}, function(response) {
			// render your template on the page here
		});
	});
})