/*!
 * Author : Vivek Aditya Gudapuri
 * jQuery YouTube Player Plugin
 * inspired from 
 * http://lab.abhinayrathore.com/jquery_youtube/
 */
(function ($) {
    var methods = {
        //initialize plugin
        init: function (options) {
            options = $.extend({}, $.fn.youtube.defaults, options);

            return this.each(function () {
                var obj = $(this);
                var data = obj.data('youtube');
                if (!data) { //check if event is already assigned
                    obj.data('youtube', { target: obj, 'active': true });
                    $(obj).bind('click.youtube', function () {
                        var youtubeId = options.youtubeId;
                        if ($.trim(youtubeId) == '') youtubeId = obj.attr(options.idAttribute);
                        var videoTitle = options.title;
                        if ($.trim(videoTitle) == '') videoTitle = obj.attr('title');

                        //Format url
                        var url = "http://www.youtube.com/embed/" + youtubeId + "?rel=0&showsearch=0&autohide=" + options.autohide;
                        url += "&autoplay=" + options.autoplay + "&color1=" + options.color1 + "&color2=" + options.color2;
                        url += "&controls=" + options.controls + "&fs=" + options.fullscreen + "&loop=" + options.loop;
                        url += "&hd=" + options.hd + "&showinfo=" + options.showinfo + "&color=" + options.color + "&theme=" + options.theme;

                        //Setup Container
						container = $('<div></div>').css({ padding: 0 });
                        container.html(getEmbeddedPlayer(url,options.title, options.width, options.height));
						obj.before(container);
						obj.hide();

                        return false;
                    });
                }
            });
        },
        destroy: function () {
            return this.each(function () {
                $(this).unbind(".youtube");
                $(this).removeData('youtube');
            });
        }
    };

    function getEmbeddedPlayer(URL, title, width, height) {
        var player = '<iframe title="'+title+'" style="margin:0; padding:0;" width="' + width + '" ';
        player += 'height="' + height + '" src="' + URL + '" frameborder="0" allowfullscreen></iframe>';
        return player;
    }

    $.fn.youtube = function (method) {
        if (methods[method]) {
            return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
        } else if (typeof method === 'object' || !method) {
            return methods.init.apply(this, arguments);
        } else {
            $.error('Method ' + method + ' does not exist on jQuery.youtube');
        }
    };

    //default configuration
    $.fn.youtube.defaults = {
		'youtubeId': '',
		'title': 'Youtube',
		'idAttribute': 'rel',
		'draggable': false,
		'modal': true,
		'width': 500,
		'height': 400,
		'autoplay': 1,
		'color': 'red',
		'color1': 'FFFFFF',
		'color2': 'FFFFFF',
		'controls': 1,
		'fullscreen': 1,
		'loop': 0,
		'hd': 1,
		'showinfo': 0,
		'theme': 'light'
    };
})(jQuery);