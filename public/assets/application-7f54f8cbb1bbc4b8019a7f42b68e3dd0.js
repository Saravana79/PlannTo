/*!
 * jQuery UI 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI
 */

(function( $, undefined ) {

// prevent duplicate loading
// this is only a problem because we proxy existing functions
// and we don't want to double proxy them
$.ui = $.ui || {};
if ( $.ui.version ) {
	return;
}

$.extend( $.ui, {
	version: "1.8.14",

	keyCode: {
		ALT: 18,
		BACKSPACE: 8,
		CAPS_LOCK: 20,
		COMMA: 188,
		COMMAND: 91,
		COMMAND_LEFT: 91, // COMMAND
		COMMAND_RIGHT: 93,
		CONTROL: 17,
		DELETE: 46,
		DOWN: 40,
		END: 35,
		ENTER: 13,
		ESCAPE: 27,
		HOME: 36,
		INSERT: 45,
		LEFT: 37,
		MENU: 93, // COMMAND_RIGHT
		NUMPAD_ADD: 107,
		NUMPAD_DECIMAL: 110,
		NUMPAD_DIVIDE: 111,
		NUMPAD_ENTER: 108,
		NUMPAD_MULTIPLY: 106,
		NUMPAD_SUBTRACT: 109,
		PAGE_DOWN: 34,
		PAGE_UP: 33,
		PERIOD: 190,
		RIGHT: 39,
		SHIFT: 16,
		SPACE: 32,
		TAB: 9,
		UP: 38,
		WINDOWS: 91 // COMMAND
	}
});

// plugins
$.fn.extend({
	_focus: $.fn.focus,
	focus: function( delay, fn ) {
		return typeof delay === "number" ?
			this.each(function() {
				var elem = this;
				setTimeout(function() {
					$( elem ).focus();
					if ( fn ) {
						fn.call( elem );
					}
				}, delay );
			}) :
			this._focus.apply( this, arguments );
	},

	scrollParent: function() {
		var scrollParent;
		if (($.browser.msie && (/(static|relative)/).test(this.css('position'))) || (/absolute/).test(this.css('position'))) {
			scrollParent = this.parents().filter(function() {
				return (/(relative|absolute|fixed)/).test($.curCSS(this,'position',1)) && (/(auto|scroll)/).test($.curCSS(this,'overflow',1)+$.curCSS(this,'overflow-y',1)+$.curCSS(this,'overflow-x',1));
			}).eq(0);
		} else {
			scrollParent = this.parents().filter(function() {
				return (/(auto|scroll)/).test($.curCSS(this,'overflow',1)+$.curCSS(this,'overflow-y',1)+$.curCSS(this,'overflow-x',1));
			}).eq(0);
		}

		return (/fixed/).test(this.css('position')) || !scrollParent.length ? $(document) : scrollParent;
	},

	zIndex: function( zIndex ) {
		if ( zIndex !== undefined ) {
			return this.css( "zIndex", zIndex );
		}

		if ( this.length ) {
			var elem = $( this[ 0 ] ), position, value;
			while ( elem.length && elem[ 0 ] !== document ) {
				// Ignore z-index if position is set to a value where z-index is ignored by the browser
				// This makes behavior of this function consistent across browsers
				// WebKit always returns auto if the element is positioned
				position = elem.css( "position" );
				if ( position === "absolute" || position === "relative" || position === "fixed" ) {
					// IE returns 0 when zIndex is not specified
					// other browsers return a string
					// we ignore the case of nested elements with an explicit value of 0
					// <div style="z-index: -10;"><div style="z-index: 0;"></div></div>
					value = parseInt( elem.css( "zIndex" ), 10 );
					if ( !isNaN( value ) && value !== 0 ) {
						return value;
					}
				}
				elem = elem.parent();
			}
		}

		return 0;
	},

	disableSelection: function() {
		return this.bind( ( $.support.selectstart ? "selectstart" : "mousedown" ) +
			".ui-disableSelection", function( event ) {
				event.preventDefault();
			});
	},

	enableSelection: function() {
		return this.unbind( ".ui-disableSelection" );
	}
});

$.each( [ "Width", "Height" ], function( i, name ) {
	var side = name === "Width" ? [ "Left", "Right" ] : [ "Top", "Bottom" ],
		type = name.toLowerCase(),
		orig = {
			innerWidth: $.fn.innerWidth,
			innerHeight: $.fn.innerHeight,
			outerWidth: $.fn.outerWidth,
			outerHeight: $.fn.outerHeight
		};

	function reduce( elem, size, border, margin ) {
		$.each( side, function() {
			size -= parseFloat( $.curCSS( elem, "padding" + this, true) ) || 0;
			if ( border ) {
				size -= parseFloat( $.curCSS( elem, "border" + this + "Width", true) ) || 0;
			}
			if ( margin ) {
				size -= parseFloat( $.curCSS( elem, "margin" + this, true) ) || 0;
			}
		});
		return size;
	}

	$.fn[ "inner" + name ] = function( size ) {
		if ( size === undefined ) {
			return orig[ "inner" + name ].call( this );
		}

		return this.each(function() {
			$( this ).css( type, reduce( this, size ) + "px" );
		});
	};

	$.fn[ "outer" + name] = function( size, margin ) {
		if ( typeof size !== "number" ) {
			return orig[ "outer" + name ].call( this, size );
		}

		return this.each(function() {
			$( this).css( type, reduce( this, size, true, margin ) + "px" );
		});
	};
});

// selectors
function focusable( element, isTabIndexNotNaN ) {
	var nodeName = element.nodeName.toLowerCase();
	if ( "area" === nodeName ) {
		var map = element.parentNode,
			mapName = map.name,
			img;
		if ( !element.href || !mapName || map.nodeName.toLowerCase() !== "map" ) {
			return false;
		}
		img = $( "img[usemap=#" + mapName + "]" )[0];
		return !!img && visible( img );
	}
	return ( /input|select|textarea|button|object/.test( nodeName )
		? !element.disabled
		: "a" == nodeName
			? element.href || isTabIndexNotNaN
			: isTabIndexNotNaN)
		// the element and all of its ancestors must be visible
		&& visible( element );
}

function visible( element ) {
	return !$( element ).parents().andSelf().filter(function() {
		return $.curCSS( this, "visibility" ) === "hidden" ||
			$.expr.filters.hidden( this );
	}).length;
}

$.extend( $.expr[ ":" ], {
	data: function( elem, i, match ) {
		return !!$.data( elem, match[ 3 ] );
	},

	focusable: function( element ) {
		return focusable( element, !isNaN( $.attr( element, "tabindex" ) ) );
	},

	tabbable: function( element ) {
		var tabIndex = $.attr( element, "tabindex" ),
			isTabIndexNaN = isNaN( tabIndex );
		return ( isTabIndexNaN || tabIndex >= 0 ) && focusable( element, !isTabIndexNaN );
	}
});

// support
$(function() {
	var body = document.body,
		div = body.appendChild( div = document.createElement( "div" ) );

	$.extend( div.style, {
		minHeight: "100px",
		height: "auto",
		padding: 0,
		borderWidth: 0
	});

	$.support.minHeight = div.offsetHeight === 100;
	$.support.selectstart = "onselectstart" in div;

	// set display to none to avoid a layout bug in IE
	// http://dev.jquery.com/ticket/4014
	body.removeChild( div ).style.display = "none";
});





// deprecated
$.extend( $.ui, {
	// $.ui.plugin is deprecated.  Use the proxy pattern instead.
	plugin: {
		add: function( module, option, set ) {
			var proto = $.ui[ module ].prototype;
			for ( var i in set ) {
				proto.plugins[ i ] = proto.plugins[ i ] || [];
				proto.plugins[ i ].push( [ option, set[ i ] ] );
			}
		},
		call: function( instance, name, args ) {
			var set = instance.plugins[ name ];
			if ( !set || !instance.element[ 0 ].parentNode ) {
				return;
			}
	
			for ( var i = 0; i < set.length; i++ ) {
				if ( instance.options[ set[ i ][ 0 ] ] ) {
					set[ i ][ 1 ].apply( instance.element, args );
				}
			}
		}
	},
	
	// will be deprecated when we switch to jQuery 1.4 - use jQuery.contains()
	contains: function( a, b ) {
		return document.compareDocumentPosition ?
			a.compareDocumentPosition( b ) & 16 :
			a !== b && a.contains( b );
	},
	
	// only used by resizable
	hasScroll: function( el, a ) {
	
		//If overflow is hidden, the element might have extra content, but the user wants to hide it
		if ( $( el ).css( "overflow" ) === "hidden") {
			return false;
		}
	
		var scroll = ( a && a === "left" ) ? "scrollLeft" : "scrollTop",
			has = false;
	
		if ( el[ scroll ] > 0 ) {
			return true;
		}
	
		// TODO: determine which cases actually cause this to happen
		// if the element doesn't have the scroll set, see if it's possible to
		// set the scroll
		el[ scroll ] = 1;
		has = ( el[ scroll ] > 0 );
		el[ scroll ] = 0;
		return has;
	},
	
	// these are odd functions, fix the API or move into individual plugins
	isOverAxis: function( x, reference, size ) {
		//Determines when x coordinate is over "b" element axis
		return ( x > reference ) && ( x < ( reference + size ) );
	},
	isOver: function( y, x, top, left, height, width ) {
		//Determines when x, y coordinates is over "b" element
		return $.ui.isOverAxis( y, top, height ) && $.ui.isOverAxis( x, left, width );
	}
});

})( jQuery );
/*!
 * jQuery UI Widget 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Widget
 */
(function( $, undefined ) {

// jQuery 1.4+
if ( $.cleanData ) {
	var _cleanData = $.cleanData;
	$.cleanData = function( elems ) {
		for ( var i = 0, elem; (elem = elems[i]) != null; i++ ) {
			$( elem ).triggerHandler( "remove" );
		}
		_cleanData( elems );
	};
} else {
	var _remove = $.fn.remove;
	$.fn.remove = function( selector, keepData ) {
		return this.each(function() {
			if ( !keepData ) {
				if ( !selector || $.filter( selector, [ this ] ).length ) {
					$( "*", this ).add( [ this ] ).each(function() {
						$( this ).triggerHandler( "remove" );
					});
				}
			}
			return _remove.call( $(this), selector, keepData );
		});
	};
}

$.widget = function( name, base, prototype ) {
	var namespace = name.split( "." )[ 0 ],
		fullName;
	name = name.split( "." )[ 1 ];
	fullName = namespace + "-" + name;

	if ( !prototype ) {
		prototype = base;
		base = $.Widget;
	}

	// create selector for plugin
	$.expr[ ":" ][ fullName ] = function( elem ) {
		return !!$.data( elem, name );
	};

	$[ namespace ] = $[ namespace ] || {};
	$[ namespace ][ name ] = function( options, element ) {
		// allow instantiation without initializing for simple inheritance
		if ( arguments.length ) {
			this._createWidget( options, element );
		}
	};

	var basePrototype = new base();
	// we need to make the options hash a property directly on the new instance
	// otherwise we'll modify the options hash on the prototype that we're
	// inheriting from
//	$.each( basePrototype, function( key, val ) {
//		if ( $.isPlainObject(val) ) {
//			basePrototype[ key ] = $.extend( {}, val );
//		}
//	});
	basePrototype.options = $.extend( true, {}, basePrototype.options );
	$[ namespace ][ name ].prototype = $.extend( true, basePrototype, {
		namespace: namespace,
		widgetName: name,
		widgetEventPrefix: $[ namespace ][ name ].prototype.widgetEventPrefix || name,
		widgetBaseClass: fullName
	}, prototype );

	$.widget.bridge( name, $[ namespace ][ name ] );
};

$.widget.bridge = function( name, object ) {
	$.fn[ name ] = function( options ) {
		var isMethodCall = typeof options === "string",
			args = Array.prototype.slice.call( arguments, 1 ),
			returnValue = this;

		// allow multiple hashes to be passed on init
		options = !isMethodCall && args.length ?
			$.extend.apply( null, [ true, options ].concat(args) ) :
			options;

		// prevent calls to internal methods
		if ( isMethodCall && options.charAt( 0 ) === "_" ) {
			return returnValue;
		}

		if ( isMethodCall ) {
			this.each(function() {
				var instance = $.data( this, name ),
					methodValue = instance && $.isFunction( instance[options] ) ?
						instance[ options ].apply( instance, args ) :
						instance;
				// TODO: add this back in 1.9 and use $.error() (see #5972)
//				if ( !instance ) {
//					throw "cannot call methods on " + name + " prior to initialization; " +
//						"attempted to call method '" + options + "'";
//				}
//				if ( !$.isFunction( instance[options] ) ) {
//					throw "no such method '" + options + "' for " + name + " widget instance";
//				}
//				var methodValue = instance[ options ].apply( instance, args );
				if ( methodValue !== instance && methodValue !== undefined ) {
					returnValue = methodValue;
					return false;
				}
			});
		} else {
			this.each(function() {
				var instance = $.data( this, name );
				if ( instance ) {
					instance.option( options || {} )._init();
				} else {
					$.data( this, name, new object( options, this ) );
				}
			});
		}

		return returnValue;
	};
};

$.Widget = function( options, element ) {
	// allow instantiation without initializing for simple inheritance
	if ( arguments.length ) {
		this._createWidget( options, element );
	}
};

$.Widget.prototype = {
	widgetName: "widget",
	widgetEventPrefix: "",
	options: {
		disabled: false
	},
	_createWidget: function( options, element ) {
		// $.widget.bridge stores the plugin instance, but we do it anyway
		// so that it's stored even before the _create function runs
		$.data( element, this.widgetName, this );
		this.element = $( element );
		this.options = $.extend( true, {},
			this.options,
			this._getCreateOptions(),
			options );

		var self = this;
		this.element.bind( "remove." + this.widgetName, function() {
			self.destroy();
		});

		this._create();
		this._trigger( "create" );
		this._init();
	},
	_getCreateOptions: function() {
		return $.metadata && $.metadata.get( this.element[0] )[ this.widgetName ];
	},
	_create: function() {},
	_init: function() {},

	destroy: function() {
		this.element
			.unbind( "." + this.widgetName )
			.removeData( this.widgetName );
		this.widget()
			.unbind( "." + this.widgetName )
			.removeAttr( "aria-disabled" )
			.removeClass(
				this.widgetBaseClass + "-disabled " +
				"ui-state-disabled" );
	},

	widget: function() {
		return this.element;
	},

	option: function( key, value ) {
		var options = key;

		if ( arguments.length === 0 ) {
			// don't return a reference to the internal hash
			return $.extend( {}, this.options );
		}

		if  (typeof key === "string" ) {
			if ( value === undefined ) {
				return this.options[ key ];
			}
			options = {};
			options[ key ] = value;
		}

		this._setOptions( options );

		return this;
	},
	_setOptions: function( options ) {
		var self = this;
		$.each( options, function( key, value ) {
			self._setOption( key, value );
		});

		return this;
	},
	_setOption: function( key, value ) {
		this.options[ key ] = value;

		if ( key === "disabled" ) {
			this.widget()
				[ value ? "addClass" : "removeClass"](
					this.widgetBaseClass + "-disabled" + " " +
					"ui-state-disabled" )
				.attr( "aria-disabled", value );
		}

		return this;
	},

	enable: function() {
		return this._setOption( "disabled", false );
	},
	disable: function() {
		return this._setOption( "disabled", true );
	},

	_trigger: function( type, event, data ) {
		var callback = this.options[ type ];

		event = $.Event( event );
		event.type = ( type === this.widgetEventPrefix ?
			type :
			this.widgetEventPrefix + type ).toLowerCase();
		data = data || {};

		// copy original event properties over to the new event
		// this would happen if we could call $.event.fix instead of $.Event
		// but we don't have a way to force an event to be fixed multiple times
		if ( event.originalEvent ) {
			for ( var i = $.event.props.length, prop; i; ) {
				prop = $.event.props[ --i ];
				event[ prop ] = event.originalEvent[ prop ];
			}
		}

		this.element.trigger( event, data );

		return !( $.isFunction(callback) &&
			callback.call( this.element[0], event, data ) === false ||
			event.isDefaultPrevented() );
	}
};

})( jQuery );
/*!
 * jQuery UI Mouse 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Mouse
 *
 * Depends:
 *	jquery.ui.widget.js
 */
(function( $, undefined ) {

var mouseHandled = false;
$(document).mousedown(function(e) {
	mouseHandled = false;
});

$.widget("ui.mouse", {
	options: {
		cancel: ':input,option',
		distance: 1,
		delay: 0
	},
	_mouseInit: function() {
		var self = this;

		this.element
			.bind('mousedown.'+this.widgetName, function(event) {
				return self._mouseDown(event);
			})
			.bind('click.'+this.widgetName, function(event) {
				if (true === $.data(event.target, self.widgetName + '.preventClickEvent')) {
				    $.removeData(event.target, self.widgetName + '.preventClickEvent');
					event.stopImmediatePropagation();
					return false;
				}
			});

		this.started = false;
	},

	// TODO: make sure destroying one instance of mouse doesn't mess with
	// other instances of mouse
	_mouseDestroy: function() {
		this.element.unbind('.'+this.widgetName);
	},

	_mouseDown: function(event) {
		// don't let more than one widget handle mouseStart
		if(mouseHandled) {return};

		// we may have missed mouseup (out of window)
		(this._mouseStarted && this._mouseUp(event));

		this._mouseDownEvent = event;

		var self = this,
			btnIsLeft = (event.which == 1),
			elIsCancel = (typeof this.options.cancel == "string" ? $(event.target).closest(this.options.cancel).length : false);
		if (!btnIsLeft || elIsCancel || !this._mouseCapture(event)) {
			return true;
		}

		this.mouseDelayMet = !this.options.delay;
		if (!this.mouseDelayMet) {
			this._mouseDelayTimer = setTimeout(function() {
				self.mouseDelayMet = true;
			}, this.options.delay);
		}

		if (this._mouseDistanceMet(event) && this._mouseDelayMet(event)) {
			this._mouseStarted = (this._mouseStart(event) !== false);
			if (!this._mouseStarted) {
				event.preventDefault();
				return true;
			}
		}

		// Click event may never have fired (Gecko & Opera)
		if (true === $.data(event.target, this.widgetName + '.preventClickEvent')) {
			$.removeData(event.target, this.widgetName + '.preventClickEvent');
		}

		// these delegates are required to keep context
		this._mouseMoveDelegate = function(event) {
			return self._mouseMove(event);
		};
		this._mouseUpDelegate = function(event) {
			return self._mouseUp(event);
		};
		$(document)
			.bind('mousemove.'+this.widgetName, this._mouseMoveDelegate)
			.bind('mouseup.'+this.widgetName, this._mouseUpDelegate);

		event.preventDefault();
		
		mouseHandled = true;
		return true;
	},

	_mouseMove: function(event) {
		// IE mouseup check - mouseup happened when mouse was out of window
		if ($.browser.msie && !(document.documentMode >= 9) && !event.button) {
			return this._mouseUp(event);
		}

		if (this._mouseStarted) {
			this._mouseDrag(event);
			return event.preventDefault();
		}

		if (this._mouseDistanceMet(event) && this._mouseDelayMet(event)) {
			this._mouseStarted =
				(this._mouseStart(this._mouseDownEvent, event) !== false);
			(this._mouseStarted ? this._mouseDrag(event) : this._mouseUp(event));
		}

		return !this._mouseStarted;
	},

	_mouseUp: function(event) {
		$(document)
			.unbind('mousemove.'+this.widgetName, this._mouseMoveDelegate)
			.unbind('mouseup.'+this.widgetName, this._mouseUpDelegate);

		if (this._mouseStarted) {
			this._mouseStarted = false;

			if (event.target == this._mouseDownEvent.target) {
			    $.data(event.target, this.widgetName + '.preventClickEvent', true);
			}

			this._mouseStop(event);
		}

		return false;
	},

	_mouseDistanceMet: function(event) {
		return (Math.max(
				Math.abs(this._mouseDownEvent.pageX - event.pageX),
				Math.abs(this._mouseDownEvent.pageY - event.pageY)
			) >= this.options.distance
		);
	},

	_mouseDelayMet: function(event) {
		return this.mouseDelayMet;
	},

	// These are placeholder methods, to be overriden by extending plugin
	_mouseStart: function(event) {},
	_mouseDrag: function(event) {},
	_mouseStop: function(event) {},
	_mouseCapture: function(event) { return true; }
});

})(jQuery);
/*
 * jQuery UI Draggable 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Draggables
 *
 * Depends:
 *	jquery.ui.core.js
 *	jquery.ui.mouse.js
 *	jquery.ui.widget.js
 */
(function( $, undefined ) {

$.widget("ui.draggable", $.ui.mouse, {
	widgetEventPrefix: "drag",
	options: {
		addClasses: true,
		appendTo: "parent",
		axis: false,
		connectToSortable: false,
		containment: false,
		cursor: "auto",
		cursorAt: false,
		grid: false,
		handle: false,
		helper: "original",
		iframeFix: false,
		opacity: false,
		refreshPositions: false,
		revert: false,
		revertDuration: 500,
		scope: "default",
		scroll: true,
		scrollSensitivity: 20,
		scrollSpeed: 20,
		snap: false,
		snapMode: "both",
		snapTolerance: 20,
		stack: false,
		zIndex: false
	},
	_create: function() {

		if (this.options.helper == 'original' && !(/^(?:r|a|f)/).test(this.element.css("position")))
			this.element[0].style.position = 'relative';

		(this.options.addClasses && this.element.addClass("ui-draggable"));
		(this.options.disabled && this.element.addClass("ui-draggable-disabled"));

		this._mouseInit();

	},

	destroy: function() {
		if(!this.element.data('draggable')) return;
		this.element
			.removeData("draggable")
			.unbind(".draggable")
			.removeClass("ui-draggable"
				+ " ui-draggable-dragging"
				+ " ui-draggable-disabled");
		this._mouseDestroy();

		return this;
	},

	_mouseCapture: function(event) {

		var o = this.options;

		// among others, prevent a drag on a resizable-handle
		if (this.helper || o.disabled || $(event.target).is('.ui-resizable-handle'))
			return false;

		//Quit if we're not on a valid handle
		this.handle = this._getHandle(event);
		if (!this.handle)
			return false;
		
		$(o.iframeFix === true ? "iframe" : o.iframeFix).each(function() {
			$('<div class="ui-draggable-iframeFix" style="background: #fff;"></div>')
			.css({
				width: this.offsetWidth+"px", height: this.offsetHeight+"px",
				position: "absolute", opacity: "0.001", zIndex: 1000
			})
			.css($(this).offset())
			.appendTo("body");
		});

		return true;

	},

	_mouseStart: function(event) {

		var o = this.options;

		//Create and append the visible helper
		this.helper = this._createHelper(event);

		//Cache the helper size
		this._cacheHelperProportions();

		//If ddmanager is used for droppables, set the global draggable
		if($.ui.ddmanager)
			$.ui.ddmanager.current = this;

		/*
		 * - Position generation -
		 * This block generates everything position related - it's the core of draggables.
		 */

		//Cache the margins of the original element
		this._cacheMargins();

		//Store the helper's css position
		this.cssPosition = this.helper.css("position");
		this.scrollParent = this.helper.scrollParent();

		//The element's absolute position on the page minus margins
		this.offset = this.positionAbs = this.element.offset();
		this.offset = {
			top: this.offset.top - this.margins.top,
			left: this.offset.left - this.margins.left
		};

		$.extend(this.offset, {
			click: { //Where the click happened, relative to the element
				left: event.pageX - this.offset.left,
				top: event.pageY - this.offset.top
			},
			parent: this._getParentOffset(),
			relative: this._getRelativeOffset() //This is a relative to absolute position minus the actual position calculation - only used for relative positioned helper
		});

		//Generate the original position
		this.originalPosition = this.position = this._generatePosition(event);
		this.originalPageX = event.pageX;
		this.originalPageY = event.pageY;

		//Adjust the mouse offset relative to the helper if 'cursorAt' is supplied
		(o.cursorAt && this._adjustOffsetFromHelper(o.cursorAt));

		//Set a containment if given in the options
		if(o.containment)
			this._setContainment();

		//Trigger event + callbacks
		if(this._trigger("start", event) === false) {
			this._clear();
			return false;
		}

		//Recache the helper size
		this._cacheHelperProportions();

		//Prepare the droppable offsets
		if ($.ui.ddmanager && !o.dropBehaviour)
			$.ui.ddmanager.prepareOffsets(this, event);

		this.helper.addClass("ui-draggable-dragging");
		this._mouseDrag(event, true); //Execute the drag once - this causes the helper not to be visible before getting its correct position
		
		//If the ddmanager is used for droppables, inform the manager that dragging has started (see #5003)
		if ( $.ui.ddmanager ) $.ui.ddmanager.dragStart(this, event);
		
		return true;
	},

	_mouseDrag: function(event, noPropagation) {

		//Compute the helpers position
		this.position = this._generatePosition(event);
		this.positionAbs = this._convertPositionTo("absolute");

		//Call plugins and callbacks and use the resulting position if something is returned
		if (!noPropagation) {
			var ui = this._uiHash();
			if(this._trigger('drag', event, ui) === false) {
				this._mouseUp({});
				return false;
			}
			this.position = ui.position;
		}

		if(!this.options.axis || this.options.axis != "y") this.helper[0].style.left = this.position.left+'px';
		if(!this.options.axis || this.options.axis != "x") this.helper[0].style.top = this.position.top+'px';
		if($.ui.ddmanager) $.ui.ddmanager.drag(this, event);

		return false;
	},

	_mouseStop: function(event) {

		//If we are using droppables, inform the manager about the drop
		var dropped = false;
		if ($.ui.ddmanager && !this.options.dropBehaviour)
			dropped = $.ui.ddmanager.drop(this, event);

		//if a drop comes from outside (a sortable)
		if(this.dropped) {
			dropped = this.dropped;
			this.dropped = false;
		}
		
		//if the original element is removed, don't bother to continue if helper is set to "original"
		if((!this.element[0] || !this.element[0].parentNode) && this.options.helper == "original")
			return false;

		if((this.options.revert == "invalid" && !dropped) || (this.options.revert == "valid" && dropped) || this.options.revert === true || ($.isFunction(this.options.revert) && this.options.revert.call(this.element, dropped))) {
			var self = this;
			$(this.helper).animate(this.originalPosition, parseInt(this.options.revertDuration, 10), function() {
				if(self._trigger("stop", event) !== false) {
					self._clear();
				}
			});
		} else {
			if(this._trigger("stop", event) !== false) {
				this._clear();
			}
		}

		return false;
	},
	
	_mouseUp: function(event) {
		if (this.options.iframeFix === true) {
			$("div.ui-draggable-iframeFix").each(function() { 
				this.parentNode.removeChild(this); 
			}); //Remove frame helpers
		}
		
		//If the ddmanager is used for droppables, inform the manager that dragging has stopped (see #5003)
		if( $.ui.ddmanager ) $.ui.ddmanager.dragStop(this, event);
		
		return $.ui.mouse.prototype._mouseUp.call(this, event);
	},
	
	cancel: function() {
		
		if(this.helper.is(".ui-draggable-dragging")) {
			this._mouseUp({});
		} else {
			this._clear();
		}
		
		return this;
		
	},

	_getHandle: function(event) {

		var handle = !this.options.handle || !$(this.options.handle, this.element).length ? true : false;
		$(this.options.handle, this.element)
			.find("*")
			.andSelf()
			.each(function() {
				if(this == event.target) handle = true;
			});

		return handle;

	},

	_createHelper: function(event) {

		var o = this.options;
		var helper = $.isFunction(o.helper) ? $(o.helper.apply(this.element[0], [event])) : (o.helper == 'clone' ? this.element.clone().removeAttr('id') : this.element);

		if(!helper.parents('body').length)
			helper.appendTo((o.appendTo == 'parent' ? this.element[0].parentNode : o.appendTo));

		if(helper[0] != this.element[0] && !(/(fixed|absolute)/).test(helper.css("position")))
			helper.css("position", "absolute");

		return helper;

	},

	_adjustOffsetFromHelper: function(obj) {
		if (typeof obj == 'string') {
			obj = obj.split(' ');
		}
		if ($.isArray(obj)) {
			obj = {left: +obj[0], top: +obj[1] || 0};
		}
		if ('left' in obj) {
			this.offset.click.left = obj.left + this.margins.left;
		}
		if ('right' in obj) {
			this.offset.click.left = this.helperProportions.width - obj.right + this.margins.left;
		}
		if ('top' in obj) {
			this.offset.click.top = obj.top + this.margins.top;
		}
		if ('bottom' in obj) {
			this.offset.click.top = this.helperProportions.height - obj.bottom + this.margins.top;
		}
	},

	_getParentOffset: function() {

		//Get the offsetParent and cache its position
		this.offsetParent = this.helper.offsetParent();
		var po = this.offsetParent.offset();

		// This is a special case where we need to modify a offset calculated on start, since the following happened:
		// 1. The position of the helper is absolute, so it's position is calculated based on the next positioned parent
		// 2. The actual offset parent is a child of the scroll parent, and the scroll parent isn't the document, which means that
		//    the scroll is included in the initial calculation of the offset of the parent, and never recalculated upon drag
		if(this.cssPosition == 'absolute' && this.scrollParent[0] != document && $.ui.contains(this.scrollParent[0], this.offsetParent[0])) {
			po.left += this.scrollParent.scrollLeft();
			po.top += this.scrollParent.scrollTop();
		}

		if((this.offsetParent[0] == document.body) //This needs to be actually done for all browsers, since pageX/pageY includes this information
		|| (this.offsetParent[0].tagName && this.offsetParent[0].tagName.toLowerCase() == 'html' && $.browser.msie)) //Ugly IE fix
			po = { top: 0, left: 0 };

		return {
			top: po.top + (parseInt(this.offsetParent.css("borderTopWidth"),10) || 0),
			left: po.left + (parseInt(this.offsetParent.css("borderLeftWidth"),10) || 0)
		};

	},

	_getRelativeOffset: function() {

		if(this.cssPosition == "relative") {
			var p = this.element.position();
			return {
				top: p.top - (parseInt(this.helper.css("top"),10) || 0) + this.scrollParent.scrollTop(),
				left: p.left - (parseInt(this.helper.css("left"),10) || 0) + this.scrollParent.scrollLeft()
			};
		} else {
			return { top: 0, left: 0 };
		}

	},

	_cacheMargins: function() {
		this.margins = {
			left: (parseInt(this.element.css("marginLeft"),10) || 0),
			top: (parseInt(this.element.css("marginTop"),10) || 0),
			right: (parseInt(this.element.css("marginRight"),10) || 0),
			bottom: (parseInt(this.element.css("marginBottom"),10) || 0)
		};
	},

	_cacheHelperProportions: function() {
		this.helperProportions = {
			width: this.helper.outerWidth(),
			height: this.helper.outerHeight()
		};
	},

	_setContainment: function() {

		var o = this.options;
		if(o.containment == 'parent') o.containment = this.helper[0].parentNode;
		if(o.containment == 'document' || o.containment == 'window') this.containment = [
			o.containment == 'document' ? 0 : $(window).scrollLeft() - this.offset.relative.left - this.offset.parent.left,
			o.containment == 'document' ? 0 : $(window).scrollTop() - this.offset.relative.top - this.offset.parent.top,
			(o.containment == 'document' ? 0 : $(window).scrollLeft()) + $(o.containment == 'document' ? document : window).width() - this.helperProportions.width - this.margins.left,
			(o.containment == 'document' ? 0 : $(window).scrollTop()) + ($(o.containment == 'document' ? document : window).height() || document.body.parentNode.scrollHeight) - this.helperProportions.height - this.margins.top
		];

		if(!(/^(document|window|parent)$/).test(o.containment) && o.containment.constructor != Array) {
		        var c = $(o.containment);
			var ce = c[0]; if(!ce) return;
			var co = c.offset();
			var over = ($(ce).css("overflow") != 'hidden');

			this.containment = [
				(parseInt($(ce).css("borderLeftWidth"),10) || 0) + (parseInt($(ce).css("paddingLeft"),10) || 0),
				(parseInt($(ce).css("borderTopWidth"),10) || 0) + (parseInt($(ce).css("paddingTop"),10) || 0),
				(over ? Math.max(ce.scrollWidth,ce.offsetWidth) : ce.offsetWidth) - (parseInt($(ce).css("borderLeftWidth"),10) || 0) - (parseInt($(ce).css("paddingRight"),10) || 0) - this.helperProportions.width - this.margins.left - this.margins.right,
				(over ? Math.max(ce.scrollHeight,ce.offsetHeight) : ce.offsetHeight) - (parseInt($(ce).css("borderTopWidth"),10) || 0) - (parseInt($(ce).css("paddingBottom"),10) || 0) - this.helperProportions.height - this.margins.top  - this.margins.bottom
			];
			this.relative_container = c;

		} else if(o.containment.constructor == Array) {
			this.containment = o.containment;
		}

	},

	_convertPositionTo: function(d, pos) {

		if(!pos) pos = this.position;
		var mod = d == "absolute" ? 1 : -1;
		var o = this.options, scroll = this.cssPosition == 'absolute' && !(this.scrollParent[0] != document && $.ui.contains(this.scrollParent[0], this.offsetParent[0])) ? this.offsetParent : this.scrollParent, scrollIsRootNode = (/(html|body)/i).test(scroll[0].tagName);

		return {
			top: (
				pos.top																	// The absolute mouse position
				+ this.offset.relative.top * mod										// Only for relative positioned nodes: Relative offset from element to offset parent
				+ this.offset.parent.top * mod											// The offsetParent's offset without borders (offset + border)
				- ($.browser.safari && $.browser.version < 526 && this.cssPosition == 'fixed' ? 0 : ( this.cssPosition == 'fixed' ? -this.scrollParent.scrollTop() : ( scrollIsRootNode ? 0 : scroll.scrollTop() ) ) * mod)
			),
			left: (
				pos.left																// The absolute mouse position
				+ this.offset.relative.left * mod										// Only for relative positioned nodes: Relative offset from element to offset parent
				+ this.offset.parent.left * mod											// The offsetParent's offset without borders (offset + border)
				- ($.browser.safari && $.browser.version < 526 && this.cssPosition == 'fixed' ? 0 : ( this.cssPosition == 'fixed' ? -this.scrollParent.scrollLeft() : scrollIsRootNode ? 0 : scroll.scrollLeft() ) * mod)
			)
		};

	},

	_generatePosition: function(event) {

		var o = this.options, scroll = this.cssPosition == 'absolute' && !(this.scrollParent[0] != document && $.ui.contains(this.scrollParent[0], this.offsetParent[0])) ? this.offsetParent : this.scrollParent, scrollIsRootNode = (/(html|body)/i).test(scroll[0].tagName);
		var pageX = event.pageX;
		var pageY = event.pageY;

		/*
		 * - Position constraining -
		 * Constrain the position to a mix of grid, containment.
		 */

		if(this.originalPosition) { //If we are not dragging yet, we won't check for options
		         var containment;
		         if(this.containment) {
				 if (this.relative_container){
				     var co = this.relative_container.offset();
				     containment = [ this.containment[0] + co.left,
						     this.containment[1] + co.top,
						     this.containment[2] + co.left,
						     this.containment[3] + co.top ];
				 }
				 else {
				     containment = this.containment;
				 }

				if(event.pageX - this.offset.click.left < containment[0]) pageX = containment[0] + this.offset.click.left;
				if(event.pageY - this.offset.click.top < containment[1]) pageY = containment[1] + this.offset.click.top;
				if(event.pageX - this.offset.click.left > containment[2]) pageX = containment[2] + this.offset.click.left;
				if(event.pageY - this.offset.click.top > containment[3]) pageY = containment[3] + this.offset.click.top;
			}

			if(o.grid) {
				//Check for grid elements set to 0 to prevent divide by 0 error causing invalid argument errors in IE (see ticket #6950)
				var top = o.grid[1] ? this.originalPageY + Math.round((pageY - this.originalPageY) / o.grid[1]) * o.grid[1] : this.originalPageY;
				pageY = containment ? (!(top - this.offset.click.top < containment[1] || top - this.offset.click.top > containment[3]) ? top : (!(top - this.offset.click.top < containment[1]) ? top - o.grid[1] : top + o.grid[1])) : top;

				var left = o.grid[0] ? this.originalPageX + Math.round((pageX - this.originalPageX) / o.grid[0]) * o.grid[0] : this.originalPageX;
				pageX = containment ? (!(left - this.offset.click.left < containment[0] || left - this.offset.click.left > containment[2]) ? left : (!(left - this.offset.click.left < containment[0]) ? left - o.grid[0] : left + o.grid[0])) : left;
			}

		}

		return {
			top: (
				pageY																// The absolute mouse position
				- this.offset.click.top													// Click offset (relative to the element)
				- this.offset.relative.top												// Only for relative positioned nodes: Relative offset from element to offset parent
				- this.offset.parent.top												// The offsetParent's offset without borders (offset + border)
				+ ($.browser.safari && $.browser.version < 526 && this.cssPosition == 'fixed' ? 0 : ( this.cssPosition == 'fixed' ? -this.scrollParent.scrollTop() : ( scrollIsRootNode ? 0 : scroll.scrollTop() ) ))
			),
			left: (
				pageX																// The absolute mouse position
				- this.offset.click.left												// Click offset (relative to the element)
				- this.offset.relative.left												// Only for relative positioned nodes: Relative offset from element to offset parent
				- this.offset.parent.left												// The offsetParent's offset without borders (offset + border)
				+ ($.browser.safari && $.browser.version < 526 && this.cssPosition == 'fixed' ? 0 : ( this.cssPosition == 'fixed' ? -this.scrollParent.scrollLeft() : scrollIsRootNode ? 0 : scroll.scrollLeft() ))
			)
		};

	},

	_clear: function() {
		this.helper.removeClass("ui-draggable-dragging");
		if(this.helper[0] != this.element[0] && !this.cancelHelperRemoval) this.helper.remove();
		//if($.ui.ddmanager) $.ui.ddmanager.current = null;
		this.helper = null;
		this.cancelHelperRemoval = false;
	},

	// From now on bulk stuff - mainly helpers

	_trigger: function(type, event, ui) {
		ui = ui || this._uiHash();
		$.ui.plugin.call(this, type, [event, ui]);
		if(type == "drag") this.positionAbs = this._convertPositionTo("absolute"); //The absolute position has to be recalculated after plugins
		return $.Widget.prototype._trigger.call(this, type, event, ui);
	},

	plugins: {},

	_uiHash: function(event) {
		return {
			helper: this.helper,
			position: this.position,
			originalPosition: this.originalPosition,
			offset: this.positionAbs
		};
	}

});

$.extend($.ui.draggable, {
	version: "1.8.14"
});

$.ui.plugin.add("draggable", "connectToSortable", {
	start: function(event, ui) {

		var inst = $(this).data("draggable"), o = inst.options,
			uiSortable = $.extend({}, ui, { item: inst.element });
		inst.sortables = [];
		$(o.connectToSortable).each(function() {
			var sortable = $.data(this, 'sortable');
			if (sortable && !sortable.options.disabled) {
				inst.sortables.push({
					instance: sortable,
					shouldRevert: sortable.options.revert
				});
				sortable.refreshPositions();	// Call the sortable's refreshPositions at drag start to refresh the containerCache since the sortable container cache is used in drag and needs to be up to date (this will ensure it's initialised as well as being kept in step with any changes that might have happened on the page).
				sortable._trigger("activate", event, uiSortable);
			}
		});

	},
	stop: function(event, ui) {

		//If we are still over the sortable, we fake the stop event of the sortable, but also remove helper
		var inst = $(this).data("draggable"),
			uiSortable = $.extend({}, ui, { item: inst.element });

		$.each(inst.sortables, function() {
			if(this.instance.isOver) {

				this.instance.isOver = 0;

				inst.cancelHelperRemoval = true; //Don't remove the helper in the draggable instance
				this.instance.cancelHelperRemoval = false; //Remove it in the sortable instance (so sortable plugins like revert still work)

				//The sortable revert is supported, and we have to set a temporary dropped variable on the draggable to support revert: 'valid/invalid'
				if(this.shouldRevert) this.instance.options.revert = true;

				//Trigger the stop of the sortable
				this.instance._mouseStop(event);

				this.instance.options.helper = this.instance.options._helper;

				//If the helper has been the original item, restore properties in the sortable
				if(inst.options.helper == 'original')
					this.instance.currentItem.css({ top: 'auto', left: 'auto' });

			} else {
				this.instance.cancelHelperRemoval = false; //Remove the helper in the sortable instance
				this.instance._trigger("deactivate", event, uiSortable);
			}

		});

	},
	drag: function(event, ui) {

		var inst = $(this).data("draggable"), self = this;

		var checkPos = function(o) {
			var dyClick = this.offset.click.top, dxClick = this.offset.click.left;
			var helperTop = this.positionAbs.top, helperLeft = this.positionAbs.left;
			var itemHeight = o.height, itemWidth = o.width;
			var itemTop = o.top, itemLeft = o.left;

			return $.ui.isOver(helperTop + dyClick, helperLeft + dxClick, itemTop, itemLeft, itemHeight, itemWidth);
		};

		$.each(inst.sortables, function(i) {
			
			//Copy over some variables to allow calling the sortable's native _intersectsWith
			this.instance.positionAbs = inst.positionAbs;
			this.instance.helperProportions = inst.helperProportions;
			this.instance.offset.click = inst.offset.click;
			
			if(this.instance._intersectsWith(this.instance.containerCache)) {

				//If it intersects, we use a little isOver variable and set it once, so our move-in stuff gets fired only once
				if(!this.instance.isOver) {

					this.instance.isOver = 1;
					//Now we fake the start of dragging for the sortable instance,
					//by cloning the list group item, appending it to the sortable and using it as inst.currentItem
					//We can then fire the start event of the sortable with our passed browser event, and our own helper (so it doesn't create a new one)
					this.instance.currentItem = $(self).clone().removeAttr('id').appendTo(this.instance.element).data("sortable-item", true);
					this.instance.options._helper = this.instance.options.helper; //Store helper option to later restore it
					this.instance.options.helper = function() { return ui.helper[0]; };

					event.target = this.instance.currentItem[0];
					this.instance._mouseCapture(event, true);
					this.instance._mouseStart(event, true, true);

					//Because the browser event is way off the new appended portlet, we modify a couple of variables to reflect the changes
					this.instance.offset.click.top = inst.offset.click.top;
					this.instance.offset.click.left = inst.offset.click.left;
					this.instance.offset.parent.left -= inst.offset.parent.left - this.instance.offset.parent.left;
					this.instance.offset.parent.top -= inst.offset.parent.top - this.instance.offset.parent.top;

					inst._trigger("toSortable", event);
					inst.dropped = this.instance.element; //draggable revert needs that
					//hack so receive/update callbacks work (mostly)
					inst.currentItem = inst.element;
					this.instance.fromOutside = inst;

				}

				//Provided we did all the previous steps, we can fire the drag event of the sortable on every draggable drag, when it intersects with the sortable
				if(this.instance.currentItem) this.instance._mouseDrag(event);

			} else {

				//If it doesn't intersect with the sortable, and it intersected before,
				//we fake the drag stop of the sortable, but make sure it doesn't remove the helper by using cancelHelperRemoval
				if(this.instance.isOver) {

					this.instance.isOver = 0;
					this.instance.cancelHelperRemoval = true;
					
					//Prevent reverting on this forced stop
					this.instance.options.revert = false;
					
					// The out event needs to be triggered independently
					this.instance._trigger('out', event, this.instance._uiHash(this.instance));
					
					this.instance._mouseStop(event, true);
					this.instance.options.helper = this.instance.options._helper;

					//Now we remove our currentItem, the list group clone again, and the placeholder, and animate the helper back to it's original size
					this.instance.currentItem.remove();
					if(this.instance.placeholder) this.instance.placeholder.remove();

					inst._trigger("fromSortable", event);
					inst.dropped = false; //draggable revert needs that
				}

			};

		});

	}
});

$.ui.plugin.add("draggable", "cursor", {
	start: function(event, ui) {
		var t = $('body'), o = $(this).data('draggable').options;
		if (t.css("cursor")) o._cursor = t.css("cursor");
		t.css("cursor", o.cursor);
	},
	stop: function(event, ui) {
		var o = $(this).data('draggable').options;
		if (o._cursor) $('body').css("cursor", o._cursor);
	}
});

$.ui.plugin.add("draggable", "opacity", {
	start: function(event, ui) {
		var t = $(ui.helper), o = $(this).data('draggable').options;
		if(t.css("opacity")) o._opacity = t.css("opacity");
		t.css('opacity', o.opacity);
	},
	stop: function(event, ui) {
		var o = $(this).data('draggable').options;
		if(o._opacity) $(ui.helper).css('opacity', o._opacity);
	}
});

$.ui.plugin.add("draggable", "scroll", {
	start: function(event, ui) {
		var i = $(this).data("draggable");
		if(i.scrollParent[0] != document && i.scrollParent[0].tagName != 'HTML') i.overflowOffset = i.scrollParent.offset();
	},
	drag: function(event, ui) {

		var i = $(this).data("draggable"), o = i.options, scrolled = false;

		if(i.scrollParent[0] != document && i.scrollParent[0].tagName != 'HTML') {

			if(!o.axis || o.axis != 'x') {
				if((i.overflowOffset.top + i.scrollParent[0].offsetHeight) - event.pageY < o.scrollSensitivity)
					i.scrollParent[0].scrollTop = scrolled = i.scrollParent[0].scrollTop + o.scrollSpeed;
				else if(event.pageY - i.overflowOffset.top < o.scrollSensitivity)
					i.scrollParent[0].scrollTop = scrolled = i.scrollParent[0].scrollTop - o.scrollSpeed;
			}

			if(!o.axis || o.axis != 'y') {
				if((i.overflowOffset.left + i.scrollParent[0].offsetWidth) - event.pageX < o.scrollSensitivity)
					i.scrollParent[0].scrollLeft = scrolled = i.scrollParent[0].scrollLeft + o.scrollSpeed;
				else if(event.pageX - i.overflowOffset.left < o.scrollSensitivity)
					i.scrollParent[0].scrollLeft = scrolled = i.scrollParent[0].scrollLeft - o.scrollSpeed;
			}

		} else {

			if(!o.axis || o.axis != 'x') {
				if(event.pageY - $(document).scrollTop() < o.scrollSensitivity)
					scrolled = $(document).scrollTop($(document).scrollTop() - o.scrollSpeed);
				else if($(window).height() - (event.pageY - $(document).scrollTop()) < o.scrollSensitivity)
					scrolled = $(document).scrollTop($(document).scrollTop() + o.scrollSpeed);
			}

			if(!o.axis || o.axis != 'y') {
				if(event.pageX - $(document).scrollLeft() < o.scrollSensitivity)
					scrolled = $(document).scrollLeft($(document).scrollLeft() - o.scrollSpeed);
				else if($(window).width() - (event.pageX - $(document).scrollLeft()) < o.scrollSensitivity)
					scrolled = $(document).scrollLeft($(document).scrollLeft() + o.scrollSpeed);
			}

		}

		if(scrolled !== false && $.ui.ddmanager && !o.dropBehaviour)
			$.ui.ddmanager.prepareOffsets(i, event);

	}
});

$.ui.plugin.add("draggable", "snap", {
	start: function(event, ui) {

		var i = $(this).data("draggable"), o = i.options;
		i.snapElements = [];

		$(o.snap.constructor != String ? ( o.snap.items || ':data(draggable)' ) : o.snap).each(function() {
			var $t = $(this); var $o = $t.offset();
			if(this != i.element[0]) i.snapElements.push({
				item: this,
				width: $t.outerWidth(), height: $t.outerHeight(),
				top: $o.top, left: $o.left
			});
		});

	},
	drag: function(event, ui) {

		var inst = $(this).data("draggable"), o = inst.options;
		var d = o.snapTolerance;

		var x1 = ui.offset.left, x2 = x1 + inst.helperProportions.width,
			y1 = ui.offset.top, y2 = y1 + inst.helperProportions.height;

		for (var i = inst.snapElements.length - 1; i >= 0; i--){

			var l = inst.snapElements[i].left, r = l + inst.snapElements[i].width,
				t = inst.snapElements[i].top, b = t + inst.snapElements[i].height;

			//Yes, I know, this is insane ;)
			if(!((l-d < x1 && x1 < r+d && t-d < y1 && y1 < b+d) || (l-d < x1 && x1 < r+d && t-d < y2 && y2 < b+d) || (l-d < x2 && x2 < r+d && t-d < y1 && y1 < b+d) || (l-d < x2 && x2 < r+d && t-d < y2 && y2 < b+d))) {
				if(inst.snapElements[i].snapping) (inst.options.snap.release && inst.options.snap.release.call(inst.element, event, $.extend(inst._uiHash(), { snapItem: inst.snapElements[i].item })));
				inst.snapElements[i].snapping = false;
				continue;
			}

			if(o.snapMode != 'inner') {
				var ts = Math.abs(t - y2) <= d;
				var bs = Math.abs(b - y1) <= d;
				var ls = Math.abs(l - x2) <= d;
				var rs = Math.abs(r - x1) <= d;
				if(ts) ui.position.top = inst._convertPositionTo("relative", { top: t - inst.helperProportions.height, left: 0 }).top - inst.margins.top;
				if(bs) ui.position.top = inst._convertPositionTo("relative", { top: b, left: 0 }).top - inst.margins.top;
				if(ls) ui.position.left = inst._convertPositionTo("relative", { top: 0, left: l - inst.helperProportions.width }).left - inst.margins.left;
				if(rs) ui.position.left = inst._convertPositionTo("relative", { top: 0, left: r }).left - inst.margins.left;
			}

			var first = (ts || bs || ls || rs);

			if(o.snapMode != 'outer') {
				var ts = Math.abs(t - y1) <= d;
				var bs = Math.abs(b - y2) <= d;
				var ls = Math.abs(l - x1) <= d;
				var rs = Math.abs(r - x2) <= d;
				if(ts) ui.position.top = inst._convertPositionTo("relative", { top: t, left: 0 }).top - inst.margins.top;
				if(bs) ui.position.top = inst._convertPositionTo("relative", { top: b - inst.helperProportions.height, left: 0 }).top - inst.margins.top;
				if(ls) ui.position.left = inst._convertPositionTo("relative", { top: 0, left: l }).left - inst.margins.left;
				if(rs) ui.position.left = inst._convertPositionTo("relative", { top: 0, left: r - inst.helperProportions.width }).left - inst.margins.left;
			}

			if(!inst.snapElements[i].snapping && (ts || bs || ls || rs || first))
				(inst.options.snap.snap && inst.options.snap.snap.call(inst.element, event, $.extend(inst._uiHash(), { snapItem: inst.snapElements[i].item })));
			inst.snapElements[i].snapping = (ts || bs || ls || rs || first);

		};

	}
});

$.ui.plugin.add("draggable", "stack", {
	start: function(event, ui) {

		var o = $(this).data("draggable").options;

		var group = $.makeArray($(o.stack)).sort(function(a,b) {
			return (parseInt($(a).css("zIndex"),10) || 0) - (parseInt($(b).css("zIndex"),10) || 0);
		});
		if (!group.length) { return; }
		
		var min = parseInt(group[0].style.zIndex) || 0;
		$(group).each(function(i) {
			this.style.zIndex = min + i;
		});

		this[0].style.zIndex = min + group.length;

	}
});

$.ui.plugin.add("draggable", "zIndex", {
	start: function(event, ui) {
		var t = $(ui.helper), o = $(this).data("draggable").options;
		if(t.css("zIndex")) o._zIndex = t.css("zIndex");
		t.css('zIndex', o.zIndex);
	},
	stop: function(event, ui) {
		var o = $(this).data("draggable").options;
		if(o._zIndex) $(ui.helper).css('zIndex', o._zIndex);
	}
});

})(jQuery);
/*
 * jQuery UI Droppable 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Droppables
 *
 * Depends:
 *	jquery.ui.core.js
 *	jquery.ui.widget.js
 *	jquery.ui.mouse.js
 *	jquery.ui.draggable.js
 */
(function( $, undefined ) {

$.widget("ui.droppable", {
	widgetEventPrefix: "drop",
	options: {
		accept: '*',
		activeClass: false,
		addClasses: true,
		greedy: false,
		hoverClass: false,
		scope: 'default',
		tolerance: 'intersect'
	},
	_create: function() {

		var o = this.options, accept = o.accept;
		this.isover = 0; this.isout = 1;

		this.accept = $.isFunction(accept) ? accept : function(d) {
			return d.is(accept);
		};

		//Store the droppable's proportions
		this.proportions = { width: this.element[0].offsetWidth, height: this.element[0].offsetHeight };

		// Add the reference and positions to the manager
		$.ui.ddmanager.droppables[o.scope] = $.ui.ddmanager.droppables[o.scope] || [];
		$.ui.ddmanager.droppables[o.scope].push(this);

		(o.addClasses && this.element.addClass("ui-droppable"));

	},

	destroy: function() {
		var drop = $.ui.ddmanager.droppables[this.options.scope];
		for ( var i = 0; i < drop.length; i++ )
			if ( drop[i] == this )
				drop.splice(i, 1);

		this.element
			.removeClass("ui-droppable ui-droppable-disabled")
			.removeData("droppable")
			.unbind(".droppable");

		return this;
	},

	_setOption: function(key, value) {

		if(key == 'accept') {
			this.accept = $.isFunction(value) ? value : function(d) {
				return d.is(value);
			};
		}
		$.Widget.prototype._setOption.apply(this, arguments);
	},

	_activate: function(event) {
		var draggable = $.ui.ddmanager.current;
		if(this.options.activeClass) this.element.addClass(this.options.activeClass);
		(draggable && this._trigger('activate', event, this.ui(draggable)));
	},

	_deactivate: function(event) {
		var draggable = $.ui.ddmanager.current;
		if(this.options.activeClass) this.element.removeClass(this.options.activeClass);
		(draggable && this._trigger('deactivate', event, this.ui(draggable)));
	},

	_over: function(event) {

		var draggable = $.ui.ddmanager.current;
		if (!draggable || (draggable.currentItem || draggable.element)[0] == this.element[0]) return; // Bail if draggable and droppable are same element

		if (this.accept.call(this.element[0],(draggable.currentItem || draggable.element))) {
			if(this.options.hoverClass) this.element.addClass(this.options.hoverClass);
			this._trigger('over', event, this.ui(draggable));
		}

	},

	_out: function(event) {

		var draggable = $.ui.ddmanager.current;
		if (!draggable || (draggable.currentItem || draggable.element)[0] == this.element[0]) return; // Bail if draggable and droppable are same element

		if (this.accept.call(this.element[0],(draggable.currentItem || draggable.element))) {
			if(this.options.hoverClass) this.element.removeClass(this.options.hoverClass);
			this._trigger('out', event, this.ui(draggable));
		}

	},

	_drop: function(event,custom) {

		var draggable = custom || $.ui.ddmanager.current;
		if (!draggable || (draggable.currentItem || draggable.element)[0] == this.element[0]) return false; // Bail if draggable and droppable are same element

		var childrenIntersection = false;
		this.element.find(":data(droppable)").not(".ui-draggable-dragging").each(function() {
			var inst = $.data(this, 'droppable');
			if(
				inst.options.greedy
				&& !inst.options.disabled
				&& inst.options.scope == draggable.options.scope
				&& inst.accept.call(inst.element[0], (draggable.currentItem || draggable.element))
				&& $.ui.intersect(draggable, $.extend(inst, { offset: inst.element.offset() }), inst.options.tolerance)
			) { childrenIntersection = true; return false; }
		});
		if(childrenIntersection) return false;

		if(this.accept.call(this.element[0],(draggable.currentItem || draggable.element))) {
			if(this.options.activeClass) this.element.removeClass(this.options.activeClass);
			if(this.options.hoverClass) this.element.removeClass(this.options.hoverClass);
			this._trigger('drop', event, this.ui(draggable));
			return this.element;
		}

		return false;

	},

	ui: function(c) {
		return {
			draggable: (c.currentItem || c.element),
			helper: c.helper,
			position: c.position,
			offset: c.positionAbs
		};
	}

});

$.extend($.ui.droppable, {
	version: "1.8.14"
});

$.ui.intersect = function(draggable, droppable, toleranceMode) {

	if (!droppable.offset) return false;

	var x1 = (draggable.positionAbs || draggable.position.absolute).left, x2 = x1 + draggable.helperProportions.width,
		y1 = (draggable.positionAbs || draggable.position.absolute).top, y2 = y1 + draggable.helperProportions.height;
	var l = droppable.offset.left, r = l + droppable.proportions.width,
		t = droppable.offset.top, b = t + droppable.proportions.height;

	switch (toleranceMode) {
		case 'fit':
			return (l <= x1 && x2 <= r
				&& t <= y1 && y2 <= b);
			break;
		case 'intersect':
			return (l < x1 + (draggable.helperProportions.width / 2) // Right Half
				&& x2 - (draggable.helperProportions.width / 2) < r // Left Half
				&& t < y1 + (draggable.helperProportions.height / 2) // Bottom Half
				&& y2 - (draggable.helperProportions.height / 2) < b ); // Top Half
			break;
		case 'pointer':
			var draggableLeft = ((draggable.positionAbs || draggable.position.absolute).left + (draggable.clickOffset || draggable.offset.click).left),
				draggableTop = ((draggable.positionAbs || draggable.position.absolute).top + (draggable.clickOffset || draggable.offset.click).top),
				isOver = $.ui.isOver(draggableTop, draggableLeft, t, l, droppable.proportions.height, droppable.proportions.width);
			return isOver;
			break;
		case 'touch':
			return (
					(y1 >= t && y1 <= b) ||	// Top edge touching
					(y2 >= t && y2 <= b) ||	// Bottom edge touching
					(y1 < t && y2 > b)		// Surrounded vertically
				) && (
					(x1 >= l && x1 <= r) ||	// Left edge touching
					(x2 >= l && x2 <= r) ||	// Right edge touching
					(x1 < l && x2 > r)		// Surrounded horizontally
				);
			break;
		default:
			return false;
			break;
		}

};

/*
	This manager tracks offsets of draggables and droppables
*/
$.ui.ddmanager = {
	current: null,
	droppables: { 'default': [] },
	prepareOffsets: function(t, event) {

		var m = $.ui.ddmanager.droppables[t.options.scope] || [];
		var type = event ? event.type : null; // workaround for #2317
		var list = (t.currentItem || t.element).find(":data(droppable)").andSelf();

		droppablesLoop: for (var i = 0; i < m.length; i++) {

			if(m[i].options.disabled || (t && !m[i].accept.call(m[i].element[0],(t.currentItem || t.element)))) continue;	//No disabled and non-accepted
			for (var j=0; j < list.length; j++) { if(list[j] == m[i].element[0]) { m[i].proportions.height = 0; continue droppablesLoop; } }; //Filter out elements in the current dragged item
			m[i].visible = m[i].element.css("display") != "none"; if(!m[i].visible) continue; 									//If the element is not visible, continue

			if(type == "mousedown") m[i]._activate.call(m[i], event); //Activate the droppable if used directly from draggables

			m[i].offset = m[i].element.offset();
			m[i].proportions = { width: m[i].element[0].offsetWidth, height: m[i].element[0].offsetHeight };

		}

	},
	drop: function(draggable, event) {

		var dropped = false;
		$.each($.ui.ddmanager.droppables[draggable.options.scope] || [], function() {

			if(!this.options) return;
			if (!this.options.disabled && this.visible && $.ui.intersect(draggable, this, this.options.tolerance))
				dropped = dropped || this._drop.call(this, event);

			if (!this.options.disabled && this.visible && this.accept.call(this.element[0],(draggable.currentItem || draggable.element))) {
				this.isout = 1; this.isover = 0;
				this._deactivate.call(this, event);
			}

		});
		return dropped;

	},
	dragStart: function( draggable, event ) {
		//Listen for scrolling so that if the dragging causes scrolling the position of the droppables can be recalculated (see #5003)
		draggable.element.parentsUntil( "body" ).bind( "scroll.droppable", function() {
			if( !draggable.options.refreshPositions ) $.ui.ddmanager.prepareOffsets( draggable, event );
		});
	},
	drag: function(draggable, event) {

		//If you have a highly dynamic page, you might try this option. It renders positions every time you move the mouse.
		if(draggable.options.refreshPositions) $.ui.ddmanager.prepareOffsets(draggable, event);

		//Run through all droppables and check their positions based on specific tolerance options
		$.each($.ui.ddmanager.droppables[draggable.options.scope] || [], function() {

			if(this.options.disabled || this.greedyChild || !this.visible) return;
			var intersects = $.ui.intersect(draggable, this, this.options.tolerance);

			var c = !intersects && this.isover == 1 ? 'isout' : (intersects && this.isover == 0 ? 'isover' : null);
			if(!c) return;

			var parentInstance;
			if (this.options.greedy) {
				var parent = this.element.parents(':data(droppable):eq(0)');
				if (parent.length) {
					parentInstance = $.data(parent[0], 'droppable');
					parentInstance.greedyChild = (c == 'isover' ? 1 : 0);
				}
			}

			// we just moved into a greedy child
			if (parentInstance && c == 'isover') {
				parentInstance['isover'] = 0;
				parentInstance['isout'] = 1;
				parentInstance._out.call(parentInstance, event);
			}

			this[c] = 1; this[c == 'isout' ? 'isover' : 'isout'] = 0;
			this[c == "isover" ? "_over" : "_out"].call(this, event);

			// we just moved out of a greedy child
			if (parentInstance && c == 'isout') {
				parentInstance['isout'] = 0;
				parentInstance['isover'] = 1;
				parentInstance._over.call(parentInstance, event);
			}
		});

	},
	dragStop: function( draggable, event ) {
		draggable.element.parentsUntil( "body" ).unbind( "scroll.droppable" );
		//Call prepareOffsets one final time since IE does not fire return scroll events when overflow was caused by drag (see #5003)
		if( !draggable.options.refreshPositions ) $.ui.ddmanager.prepareOffsets( draggable, event );
	}
};

})(jQuery);
/*
 * jQuery UI Resizable 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Resizables
 *
 * Depends:
 *	jquery.ui.core.js
 *	jquery.ui.mouse.js
 *	jquery.ui.widget.js
 */
(function( $, undefined ) {

$.widget("ui.resizable", $.ui.mouse, {
	widgetEventPrefix: "resize",
	options: {
		alsoResize: false,
		animate: false,
		animateDuration: "slow",
		animateEasing: "swing",
		aspectRatio: false,
		autoHide: false,
		containment: false,
		ghost: false,
		grid: false,
		handles: "e,s,se",
		helper: false,
		maxHeight: null,
		maxWidth: null,
		minHeight: 10,
		minWidth: 10,
		zIndex: 1000
	},
	_create: function() {

		var self = this, o = this.options;
		this.element.addClass("ui-resizable");

		$.extend(this, {
			_aspectRatio: !!(o.aspectRatio),
			aspectRatio: o.aspectRatio,
			originalElement: this.element,
			_proportionallyResizeElements: [],
			_helper: o.helper || o.ghost || o.animate ? o.helper || 'ui-resizable-helper' : null
		});

		//Wrap the element if it cannot hold child nodes
		if(this.element[0].nodeName.match(/canvas|textarea|input|select|button|img/i)) {

			//Opera fix for relative positioning
			if (/relative/.test(this.element.css('position')) && $.browser.opera)
				this.element.css({ position: 'relative', top: 'auto', left: 'auto' });

			//Create a wrapper element and set the wrapper to the new current internal element
			this.element.wrap(
				$('<div class="ui-wrapper" style="overflow: hidden;"></div>').css({
					position: this.element.css('position'),
					width: this.element.outerWidth(),
					height: this.element.outerHeight(),
					top: this.element.css('top'),
					left: this.element.css('left')
				})
			);

			//Overwrite the original this.element
			this.element = this.element.parent().data(
				"resizable", this.element.data('resizable')
			);

			this.elementIsWrapper = true;

			//Move margins to the wrapper
			this.element.css({ marginLeft: this.originalElement.css("marginLeft"), marginTop: this.originalElement.css("marginTop"), marginRight: this.originalElement.css("marginRight"), marginBottom: this.originalElement.css("marginBottom") });
			this.originalElement.css({ marginLeft: 0, marginTop: 0, marginRight: 0, marginBottom: 0});

			//Prevent Safari textarea resize
			this.originalResizeStyle = this.originalElement.css('resize');
			this.originalElement.css('resize', 'none');

			//Push the actual element to our proportionallyResize internal array
			this._proportionallyResizeElements.push(this.originalElement.css({ position: 'static', zoom: 1, display: 'block' }));

			// avoid IE jump (hard set the margin)
			this.originalElement.css({ margin: this.originalElement.css('margin') });

			// fix handlers offset
			this._proportionallyResize();

		}

		this.handles = o.handles || (!$('.ui-resizable-handle', this.element).length ? "e,s,se" : { n: '.ui-resizable-n', e: '.ui-resizable-e', s: '.ui-resizable-s', w: '.ui-resizable-w', se: '.ui-resizable-se', sw: '.ui-resizable-sw', ne: '.ui-resizable-ne', nw: '.ui-resizable-nw' });
		if(this.handles.constructor == String) {

			if(this.handles == 'all') this.handles = 'n,e,s,w,se,sw,ne,nw';
			var n = this.handles.split(","); this.handles = {};

			for(var i = 0; i < n.length; i++) {

				var handle = $.trim(n[i]), hname = 'ui-resizable-'+handle;
				var axis = $('<div class="ui-resizable-handle ' + hname + '"></div>');

				// increase zIndex of sw, se, ne, nw axis
				//TODO : this modifies original option
				if(/sw|se|ne|nw/.test(handle)) axis.css({ zIndex: ++o.zIndex });

				//TODO : What's going on here?
				if ('se' == handle) {
					axis.addClass('ui-icon ui-icon-gripsmall-diagonal-se');
				};

				//Insert into internal handles object and append to element
				this.handles[handle] = '.ui-resizable-'+handle;
				this.element.append(axis);
			}

		}

		this._renderAxis = function(target) {

			target = target || this.element;

			for(var i in this.handles) {

				if(this.handles[i].constructor == String)
					this.handles[i] = $(this.handles[i], this.element).show();

				//Apply pad to wrapper element, needed to fix axis position (textarea, inputs, scrolls)
				if (this.elementIsWrapper && this.originalElement[0].nodeName.match(/textarea|input|select|button/i)) {

					var axis = $(this.handles[i], this.element), padWrapper = 0;

					//Checking the correct pad and border
					padWrapper = /sw|ne|nw|se|n|s/.test(i) ? axis.outerHeight() : axis.outerWidth();

					//The padding type i have to apply...
					var padPos = [ 'padding',
						/ne|nw|n/.test(i) ? 'Top' :
						/se|sw|s/.test(i) ? 'Bottom' :
						/^e$/.test(i) ? 'Right' : 'Left' ].join("");

					target.css(padPos, padWrapper);

					this._proportionallyResize();

				}

				//TODO: What's that good for? There's not anything to be executed left
				if(!$(this.handles[i]).length)
					continue;

			}
		};

		//TODO: make renderAxis a prototype function
		this._renderAxis(this.element);

		this._handles = $('.ui-resizable-handle', this.element)
			.disableSelection();

		//Matching axis name
		this._handles.mouseover(function() {
			if (!self.resizing) {
				if (this.className)
					var axis = this.className.match(/ui-resizable-(se|sw|ne|nw|n|e|s|w)/i);
				//Axis, default = se
				self.axis = axis && axis[1] ? axis[1] : 'se';
			}
		});

		//If we want to auto hide the elements
		if (o.autoHide) {
			this._handles.hide();
			$(this.element)
				.addClass("ui-resizable-autohide")
				.hover(function() {
					if (o.disabled) return;
					$(this).removeClass("ui-resizable-autohide");
					self._handles.show();
				},
				function(){
					if (o.disabled) return;
					if (!self.resizing) {
						$(this).addClass("ui-resizable-autohide");
						self._handles.hide();
					}
				});
		}

		//Initialize the mouse interaction
		this._mouseInit();

	},

	destroy: function() {

		this._mouseDestroy();

		var _destroy = function(exp) {
			$(exp).removeClass("ui-resizable ui-resizable-disabled ui-resizable-resizing")
				.removeData("resizable").unbind(".resizable").find('.ui-resizable-handle').remove();
		};

		//TODO: Unwrap at same DOM position
		if (this.elementIsWrapper) {
			_destroy(this.element);
			var wrapper = this.element;
			wrapper.after(
				this.originalElement.css({
					position: wrapper.css('position'),
					width: wrapper.outerWidth(),
					height: wrapper.outerHeight(),
					top: wrapper.css('top'),
					left: wrapper.css('left')
				})
			).remove();
		}

		this.originalElement.css('resize', this.originalResizeStyle);
		_destroy(this.originalElement);

		return this;
	},

	_mouseCapture: function(event) {
		var handle = false;
		for (var i in this.handles) {
			if ($(this.handles[i])[0] == event.target) {
				handle = true;
			}
		}

		return !this.options.disabled && handle;
	},

	_mouseStart: function(event) {

		var o = this.options, iniPos = this.element.position(), el = this.element;

		this.resizing = true;
		this.documentScroll = { top: $(document).scrollTop(), left: $(document).scrollLeft() };

		// bugfix for http://dev.jquery.com/ticket/1749
		if (el.is('.ui-draggable') || (/absolute/).test(el.css('position'))) {
			el.css({ position: 'absolute', top: iniPos.top, left: iniPos.left });
		}

		//Opera fixing relative position
		if ($.browser.opera && (/relative/).test(el.css('position')))
			el.css({ position: 'relative', top: 'auto', left: 'auto' });

		this._renderProxy();

		var curleft = num(this.helper.css('left')), curtop = num(this.helper.css('top'));

		if (o.containment) {
			curleft += $(o.containment).scrollLeft() || 0;
			curtop += $(o.containment).scrollTop() || 0;
		}

		//Store needed variables
		this.offset = this.helper.offset();
		this.position = { left: curleft, top: curtop };
		this.size = this._helper ? { width: el.outerWidth(), height: el.outerHeight() } : { width: el.width(), height: el.height() };
		this.originalSize = this._helper ? { width: el.outerWidth(), height: el.outerHeight() } : { width: el.width(), height: el.height() };
		this.originalPosition = { left: curleft, top: curtop };
		this.sizeDiff = { width: el.outerWidth() - el.width(), height: el.outerHeight() - el.height() };
		this.originalMousePosition = { left: event.pageX, top: event.pageY };

		//Aspect Ratio
		this.aspectRatio = (typeof o.aspectRatio == 'number') ? o.aspectRatio : ((this.originalSize.width / this.originalSize.height) || 1);

	    var cursor = $('.ui-resizable-' + this.axis).css('cursor');
	    $('body').css('cursor', cursor == 'auto' ? this.axis + '-resize' : cursor);

		el.addClass("ui-resizable-resizing");
		this._propagate("start", event);
		return true;
	},

	_mouseDrag: function(event) {

		//Increase performance, avoid regex
		var el = this.helper, o = this.options, props = {},
			self = this, smp = this.originalMousePosition, a = this.axis;

		var dx = (event.pageX-smp.left)||0, dy = (event.pageY-smp.top)||0;
		var trigger = this._change[a];
		if (!trigger) return false;

		// Calculate the attrs that will be change
		var data = trigger.apply(this, [event, dx, dy]), ie6 = $.browser.msie && $.browser.version < 7, csdif = this.sizeDiff;

		// Put this in the mouseDrag handler since the user can start pressing shift while resizing
		this._updateVirtualBoundaries(event.shiftKey);
		if (this._aspectRatio || event.shiftKey)
			data = this._updateRatio(data, event);

		data = this._respectSize(data, event);

		// plugins callbacks need to be called first
		this._propagate("resize", event);

		el.css({
			top: this.position.top + "px", left: this.position.left + "px",
			width: this.size.width + "px", height: this.size.height + "px"
		});

		if (!this._helper && this._proportionallyResizeElements.length)
			this._proportionallyResize();

		this._updateCache(data);

		// calling the user callback at the end
		this._trigger('resize', event, this.ui());

		return false;
	},

	_mouseStop: function(event) {

		this.resizing = false;
		var o = this.options, self = this;

		if(this._helper) {
			var pr = this._proportionallyResizeElements, ista = pr.length && (/textarea/i).test(pr[0].nodeName),
				soffseth = ista && $.ui.hasScroll(pr[0], 'left') /* TODO - jump height */ ? 0 : self.sizeDiff.height,
				soffsetw = ista ? 0 : self.sizeDiff.width;

			var s = { width: (self.helper.width()  - soffsetw), height: (self.helper.height() - soffseth) },
				left = (parseInt(self.element.css('left'), 10) + (self.position.left - self.originalPosition.left)) || null,
				top = (parseInt(self.element.css('top'), 10) + (self.position.top - self.originalPosition.top)) || null;

			if (!o.animate)
				this.element.css($.extend(s, { top: top, left: left }));

			self.helper.height(self.size.height);
			self.helper.width(self.size.width);

			if (this._helper && !o.animate) this._proportionallyResize();
		}

		$('body').css('cursor', 'auto');

		this.element.removeClass("ui-resizable-resizing");

		this._propagate("stop", event);

		if (this._helper) this.helper.remove();
		return false;

	},

    _updateVirtualBoundaries: function(forceAspectRatio) {
        var o = this.options, pMinWidth, pMaxWidth, pMinHeight, pMaxHeight, b;

        b = {
            minWidth: isNumber(o.minWidth) ? o.minWidth : 0,
            maxWidth: isNumber(o.maxWidth) ? o.maxWidth : Infinity,
            minHeight: isNumber(o.minHeight) ? o.minHeight : 0,
            maxHeight: isNumber(o.maxHeight) ? o.maxHeight : Infinity
        };

        if(this._aspectRatio || forceAspectRatio) {
            // We want to create an enclosing box whose aspect ration is the requested one
            // First, compute the "projected" size for each dimension based on the aspect ratio and other dimension
            pMinWidth = b.minHeight * this.aspectRatio;
            pMinHeight = b.minWidth / this.aspectRatio;
            pMaxWidth = b.maxHeight * this.aspectRatio;
            pMaxHeight = b.maxWidth / this.aspectRatio;

            if(pMinWidth > b.minWidth) b.minWidth = pMinWidth;
            if(pMinHeight > b.minHeight) b.minHeight = pMinHeight;
            if(pMaxWidth < b.maxWidth) b.maxWidth = pMaxWidth;
            if(pMaxHeight < b.maxHeight) b.maxHeight = pMaxHeight;
        }
        this._vBoundaries = b;
    },

	_updateCache: function(data) {
		var o = this.options;
		this.offset = this.helper.offset();
		if (isNumber(data.left)) this.position.left = data.left;
		if (isNumber(data.top)) this.position.top = data.top;
		if (isNumber(data.height)) this.size.height = data.height;
		if (isNumber(data.width)) this.size.width = data.width;
	},

	_updateRatio: function(data, event) {

		var o = this.options, cpos = this.position, csize = this.size, a = this.axis;

		if (isNumber(data.height)) data.width = (data.height * this.aspectRatio);
		else if (isNumber(data.width)) data.height = (data.width / this.aspectRatio);

		if (a == 'sw') {
			data.left = cpos.left + (csize.width - data.width);
			data.top = null;
		}
		if (a == 'nw') {
			data.top = cpos.top + (csize.height - data.height);
			data.left = cpos.left + (csize.width - data.width);
		}

		return data;
	},

	_respectSize: function(data, event) {

		var el = this.helper, o = this._vBoundaries, pRatio = this._aspectRatio || event.shiftKey, a = this.axis,
				ismaxw = isNumber(data.width) && o.maxWidth && (o.maxWidth < data.width), ismaxh = isNumber(data.height) && o.maxHeight && (o.maxHeight < data.height),
					isminw = isNumber(data.width) && o.minWidth && (o.minWidth > data.width), isminh = isNumber(data.height) && o.minHeight && (o.minHeight > data.height);

		if (isminw) data.width = o.minWidth;
		if (isminh) data.height = o.minHeight;
		if (ismaxw) data.width = o.maxWidth;
		if (ismaxh) data.height = o.maxHeight;

		var dw = this.originalPosition.left + this.originalSize.width, dh = this.position.top + this.size.height;
		var cw = /sw|nw|w/.test(a), ch = /nw|ne|n/.test(a);

		if (isminw && cw) data.left = dw - o.minWidth;
		if (ismaxw && cw) data.left = dw - o.maxWidth;
		if (isminh && ch)	data.top = dh - o.minHeight;
		if (ismaxh && ch)	data.top = dh - o.maxHeight;

		// fixing jump error on top/left - bug #2330
		var isNotwh = !data.width && !data.height;
		if (isNotwh && !data.left && data.top) data.top = null;
		else if (isNotwh && !data.top && data.left) data.left = null;

		return data;
	},

	_proportionallyResize: function() {

		var o = this.options;
		if (!this._proportionallyResizeElements.length) return;
		var element = this.helper || this.element;

		for (var i=0; i < this._proportionallyResizeElements.length; i++) {

			var prel = this._proportionallyResizeElements[i];

			if (!this.borderDif) {
				var b = [prel.css('borderTopWidth'), prel.css('borderRightWidth'), prel.css('borderBottomWidth'), prel.css('borderLeftWidth')],
					p = [prel.css('paddingTop'), prel.css('paddingRight'), prel.css('paddingBottom'), prel.css('paddingLeft')];

				this.borderDif = $.map(b, function(v, i) {
					var border = parseInt(v,10)||0, padding = parseInt(p[i],10)||0;
					return border + padding;
				});
			}

			if ($.browser.msie && !(!($(element).is(':hidden') || $(element).parents(':hidden').length)))
				continue;

			prel.css({
				height: (element.height() - this.borderDif[0] - this.borderDif[2]) || 0,
				width: (element.width() - this.borderDif[1] - this.borderDif[3]) || 0
			});

		};

	},

	_renderProxy: function() {

		var el = this.element, o = this.options;
		this.elementOffset = el.offset();

		if(this._helper) {

			this.helper = this.helper || $('<div style="overflow:hidden;"></div>');

			// fix ie6 offset TODO: This seems broken
			var ie6 = $.browser.msie && $.browser.version < 7, ie6offset = (ie6 ? 1 : 0),
			pxyoffset = ( ie6 ? 2 : -1 );

			this.helper.addClass(this._helper).css({
				width: this.element.outerWidth() + pxyoffset,
				height: this.element.outerHeight() + pxyoffset,
				position: 'absolute',
				left: this.elementOffset.left - ie6offset +'px',
				top: this.elementOffset.top - ie6offset +'px',
				zIndex: ++o.zIndex //TODO: Don't modify option
			});

			this.helper
				.appendTo("body")
				.disableSelection();

		} else {
			this.helper = this.element;
		}

	},

	_change: {
		e: function(event, dx, dy) {
			return { width: this.originalSize.width + dx };
		},
		w: function(event, dx, dy) {
			var o = this.options, cs = this.originalSize, sp = this.originalPosition;
			return { left: sp.left + dx, width: cs.width - dx };
		},
		n: function(event, dx, dy) {
			var o = this.options, cs = this.originalSize, sp = this.originalPosition;
			return { top: sp.top + dy, height: cs.height - dy };
		},
		s: function(event, dx, dy) {
			return { height: this.originalSize.height + dy };
		},
		se: function(event, dx, dy) {
			return $.extend(this._change.s.apply(this, arguments), this._change.e.apply(this, [event, dx, dy]));
		},
		sw: function(event, dx, dy) {
			return $.extend(this._change.s.apply(this, arguments), this._change.w.apply(this, [event, dx, dy]));
		},
		ne: function(event, dx, dy) {
			return $.extend(this._change.n.apply(this, arguments), this._change.e.apply(this, [event, dx, dy]));
		},
		nw: function(event, dx, dy) {
			return $.extend(this._change.n.apply(this, arguments), this._change.w.apply(this, [event, dx, dy]));
		}
	},

	_propagate: function(n, event) {
		$.ui.plugin.call(this, n, [event, this.ui()]);
		(n != "resize" && this._trigger(n, event, this.ui()));
	},

	plugins: {},

	ui: function() {
		return {
			originalElement: this.originalElement,
			element: this.element,
			helper: this.helper,
			position: this.position,
			size: this.size,
			originalSize: this.originalSize,
			originalPosition: this.originalPosition
		};
	}

});

$.extend($.ui.resizable, {
	version: "1.8.14"
});

/*
 * Resizable Extensions
 */

$.ui.plugin.add("resizable", "alsoResize", {

	start: function (event, ui) {
		var self = $(this).data("resizable"), o = self.options;

		var _store = function (exp) {
			$(exp).each(function() {
				var el = $(this);
				el.data("resizable-alsoresize", {
					width: parseInt(el.width(), 10), height: parseInt(el.height(), 10),
					left: parseInt(el.css('left'), 10), top: parseInt(el.css('top'), 10),
					position: el.css('position') // to reset Opera on stop()
				});
			});
		};

		if (typeof(o.alsoResize) == 'object' && !o.alsoResize.parentNode) {
			if (o.alsoResize.length) { o.alsoResize = o.alsoResize[0]; _store(o.alsoResize); }
			else { $.each(o.alsoResize, function (exp) { _store(exp); }); }
		}else{
			_store(o.alsoResize);
		}
	},

	resize: function (event, ui) {
		var self = $(this).data("resizable"), o = self.options, os = self.originalSize, op = self.originalPosition;

		var delta = {
			height: (self.size.height - os.height) || 0, width: (self.size.width - os.width) || 0,
			top: (self.position.top - op.top) || 0, left: (self.position.left - op.left) || 0
		},

		_alsoResize = function (exp, c) {
			$(exp).each(function() {
				var el = $(this), start = $(this).data("resizable-alsoresize"), style = {}, 
					css = c && c.length ? c : el.parents(ui.originalElement[0]).length ? ['width', 'height'] : ['width', 'height', 'top', 'left'];

				$.each(css, function (i, prop) {
					var sum = (start[prop]||0) + (delta[prop]||0);
					if (sum && sum >= 0)
						style[prop] = sum || null;
				});

				// Opera fixing relative position
				if ($.browser.opera && /relative/.test(el.css('position'))) {
					self._revertToRelativePosition = true;
					el.css({ position: 'absolute', top: 'auto', left: 'auto' });
				}

				el.css(style);
			});
		};

		if (typeof(o.alsoResize) == 'object' && !o.alsoResize.nodeType) {
			$.each(o.alsoResize, function (exp, c) { _alsoResize(exp, c); });
		}else{
			_alsoResize(o.alsoResize);
		}
	},

	stop: function (event, ui) {
		var self = $(this).data("resizable"), o = self.options;

		var _reset = function (exp) {
			$(exp).each(function() {
				var el = $(this);
				// reset position for Opera - no need to verify it was changed
				el.css({ position: el.data("resizable-alsoresize").position });
			});
		};

		if (self._revertToRelativePosition) {
			self._revertToRelativePosition = false;
			if (typeof(o.alsoResize) == 'object' && !o.alsoResize.nodeType) {
				$.each(o.alsoResize, function (exp) { _reset(exp); });
			}else{
				_reset(o.alsoResize);
			}
		}

		$(this).removeData("resizable-alsoresize");
	}
});

$.ui.plugin.add("resizable", "animate", {

	stop: function(event, ui) {
		var self = $(this).data("resizable"), o = self.options;

		var pr = self._proportionallyResizeElements, ista = pr.length && (/textarea/i).test(pr[0].nodeName),
					soffseth = ista && $.ui.hasScroll(pr[0], 'left') /* TODO - jump height */ ? 0 : self.sizeDiff.height,
						soffsetw = ista ? 0 : self.sizeDiff.width;

		var style = { width: (self.size.width - soffsetw), height: (self.size.height - soffseth) },
					left = (parseInt(self.element.css('left'), 10) + (self.position.left - self.originalPosition.left)) || null,
						top = (parseInt(self.element.css('top'), 10) + (self.position.top - self.originalPosition.top)) || null;

		self.element.animate(
			$.extend(style, top && left ? { top: top, left: left } : {}), {
				duration: o.animateDuration,
				easing: o.animateEasing,
				step: function() {

					var data = {
						width: parseInt(self.element.css('width'), 10),
						height: parseInt(self.element.css('height'), 10),
						top: parseInt(self.element.css('top'), 10),
						left: parseInt(self.element.css('left'), 10)
					};

					if (pr && pr.length) $(pr[0]).css({ width: data.width, height: data.height });

					// propagating resize, and updating values for each animation step
					self._updateCache(data);
					self._propagate("resize", event);

				}
			}
		);
	}

});

$.ui.plugin.add("resizable", "containment", {

	start: function(event, ui) {
		var self = $(this).data("resizable"), o = self.options, el = self.element;
		var oc = o.containment,	ce = (oc instanceof $) ? oc.get(0) : (/parent/.test(oc)) ? el.parent().get(0) : oc;
		if (!ce) return;

		self.containerElement = $(ce);

		if (/document/.test(oc) || oc == document) {
			self.containerOffset = { left: 0, top: 0 };
			self.containerPosition = { left: 0, top: 0 };

			self.parentData = {
				element: $(document), left: 0, top: 0,
				width: $(document).width(), height: $(document).height() || document.body.parentNode.scrollHeight
			};
		}

		// i'm a node, so compute top, left, right, bottom
		else {
			var element = $(ce), p = [];
			$([ "Top", "Right", "Left", "Bottom" ]).each(function(i, name) { p[i] = num(element.css("padding" + name)); });

			self.containerOffset = element.offset();
			self.containerPosition = element.position();
			self.containerSize = { height: (element.innerHeight() - p[3]), width: (element.innerWidth() - p[1]) };

			var co = self.containerOffset, ch = self.containerSize.height,	cw = self.containerSize.width,
						width = ($.ui.hasScroll(ce, "left") ? ce.scrollWidth : cw ), height = ($.ui.hasScroll(ce) ? ce.scrollHeight : ch);

			self.parentData = {
				element: ce, left: co.left, top: co.top, width: width, height: height
			};
		}
	},

	resize: function(event, ui) {
		var self = $(this).data("resizable"), o = self.options,
				ps = self.containerSize, co = self.containerOffset, cs = self.size, cp = self.position,
				pRatio = self._aspectRatio || event.shiftKey, cop = { top:0, left:0 }, ce = self.containerElement;

		if (ce[0] != document && (/static/).test(ce.css('position'))) cop = co;

		if (cp.left < (self._helper ? co.left : 0)) {
			self.size.width = self.size.width + (self._helper ? (self.position.left - co.left) : (self.position.left - cop.left));
			if (pRatio) self.size.height = self.size.width / o.aspectRatio;
			self.position.left = o.helper ? co.left : 0;
		}

		if (cp.top < (self._helper ? co.top : 0)) {
			self.size.height = self.size.height + (self._helper ? (self.position.top - co.top) : self.position.top);
			if (pRatio) self.size.width = self.size.height * o.aspectRatio;
			self.position.top = self._helper ? co.top : 0;
		}

		self.offset.left = self.parentData.left+self.position.left;
		self.offset.top = self.parentData.top+self.position.top;

		var woset = Math.abs( (self._helper ? self.offset.left - cop.left : (self.offset.left - cop.left)) + self.sizeDiff.width ),
					hoset = Math.abs( (self._helper ? self.offset.top - cop.top : (self.offset.top - co.top)) + self.sizeDiff.height );

		var isParent = self.containerElement.get(0) == self.element.parent().get(0),
		    isOffsetRelative = /relative|absolute/.test(self.containerElement.css('position'));

		if(isParent && isOffsetRelative) woset -= self.parentData.left;

		if (woset + self.size.width >= self.parentData.width) {
			self.size.width = self.parentData.width - woset;
			if (pRatio) self.size.height = self.size.width / self.aspectRatio;
		}

		if (hoset + self.size.height >= self.parentData.height) {
			self.size.height = self.parentData.height - hoset;
			if (pRatio) self.size.width = self.size.height * self.aspectRatio;
		}
	},

	stop: function(event, ui){
		var self = $(this).data("resizable"), o = self.options, cp = self.position,
				co = self.containerOffset, cop = self.containerPosition, ce = self.containerElement;

		var helper = $(self.helper), ho = helper.offset(), w = helper.outerWidth() - self.sizeDiff.width, h = helper.outerHeight() - self.sizeDiff.height;

		if (self._helper && !o.animate && (/relative/).test(ce.css('position')))
			$(this).css({ left: ho.left - cop.left - co.left, width: w, height: h });

		if (self._helper && !o.animate && (/static/).test(ce.css('position')))
			$(this).css({ left: ho.left - cop.left - co.left, width: w, height: h });

	}
});

$.ui.plugin.add("resizable", "ghost", {

	start: function(event, ui) {

		var self = $(this).data("resizable"), o = self.options, cs = self.size;

		self.ghost = self.originalElement.clone();
		self.ghost
			.css({ opacity: .25, display: 'block', position: 'relative', height: cs.height, width: cs.width, margin: 0, left: 0, top: 0 })
			.addClass('ui-resizable-ghost')
			.addClass(typeof o.ghost == 'string' ? o.ghost : '');

		self.ghost.appendTo(self.helper);

	},

	resize: function(event, ui){
		var self = $(this).data("resizable"), o = self.options;
		if (self.ghost) self.ghost.css({ position: 'relative', height: self.size.height, width: self.size.width });
	},

	stop: function(event, ui){
		var self = $(this).data("resizable"), o = self.options;
		if (self.ghost && self.helper) self.helper.get(0).removeChild(self.ghost.get(0));
	}

});

$.ui.plugin.add("resizable", "grid", {

	resize: function(event, ui) {
		var self = $(this).data("resizable"), o = self.options, cs = self.size, os = self.originalSize, op = self.originalPosition, a = self.axis, ratio = o._aspectRatio || event.shiftKey;
		o.grid = typeof o.grid == "number" ? [o.grid, o.grid] : o.grid;
		var ox = Math.round((cs.width - os.width) / (o.grid[0]||1)) * (o.grid[0]||1), oy = Math.round((cs.height - os.height) / (o.grid[1]||1)) * (o.grid[1]||1);

		if (/^(se|s|e)$/.test(a)) {
			self.size.width = os.width + ox;
			self.size.height = os.height + oy;
		}
		else if (/^(ne)$/.test(a)) {
			self.size.width = os.width + ox;
			self.size.height = os.height + oy;
			self.position.top = op.top - oy;
		}
		else if (/^(sw)$/.test(a)) {
			self.size.width = os.width + ox;
			self.size.height = os.height + oy;
			self.position.left = op.left - ox;
		}
		else {
			self.size.width = os.width + ox;
			self.size.height = os.height + oy;
			self.position.top = op.top - oy;
			self.position.left = op.left - ox;
		}
	}

});

var num = function(v) {
	return parseInt(v, 10) || 0;
};

var isNumber = function(value) {
	return !isNaN(parseInt(value, 10));
};

})(jQuery);
/*
 * jQuery UI Selectable 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Selectables
 *
 * Depends:
 *	jquery.ui.core.js
 *	jquery.ui.mouse.js
 *	jquery.ui.widget.js
 */
(function( $, undefined ) {

$.widget("ui.selectable", $.ui.mouse, {
	options: {
		appendTo: 'body',
		autoRefresh: true,
		distance: 0,
		filter: '*',
		tolerance: 'touch'
	},
	_create: function() {
		var self = this;

		this.element.addClass("ui-selectable");

		this.dragged = false;

		// cache selectee children based on filter
		var selectees;
		this.refresh = function() {
			selectees = $(self.options.filter, self.element[0]);
			selectees.each(function() {
				var $this = $(this);
				var pos = $this.offset();
				$.data(this, "selectable-item", {
					element: this,
					$element: $this,
					left: pos.left,
					top: pos.top,
					right: pos.left + $this.outerWidth(),
					bottom: pos.top + $this.outerHeight(),
					startselected: false,
					selected: $this.hasClass('ui-selected'),
					selecting: $this.hasClass('ui-selecting'),
					unselecting: $this.hasClass('ui-unselecting')
				});
			});
		};
		this.refresh();

		this.selectees = selectees.addClass("ui-selectee");

		this._mouseInit();

		this.helper = $("<div class='ui-selectable-helper'></div>");
	},

	destroy: function() {
		this.selectees
			.removeClass("ui-selectee")
			.removeData("selectable-item");
		this.element
			.removeClass("ui-selectable ui-selectable-disabled")
			.removeData("selectable")
			.unbind(".selectable");
		this._mouseDestroy();

		return this;
	},

	_mouseStart: function(event) {
		var self = this;

		this.opos = [event.pageX, event.pageY];

		if (this.options.disabled)
			return;

		var options = this.options;

		this.selectees = $(options.filter, this.element[0]);

		this._trigger("start", event);

		$(options.appendTo).append(this.helper);
		// position helper (lasso)
		this.helper.css({
			"left": event.clientX,
			"top": event.clientY,
			"width": 0,
			"height": 0
		});

		if (options.autoRefresh) {
			this.refresh();
		}

		this.selectees.filter('.ui-selected').each(function() {
			var selectee = $.data(this, "selectable-item");
			selectee.startselected = true;
			if (!event.metaKey) {
				selectee.$element.removeClass('ui-selected');
				selectee.selected = false;
				selectee.$element.addClass('ui-unselecting');
				selectee.unselecting = true;
				// selectable UNSELECTING callback
				self._trigger("unselecting", event, {
					unselecting: selectee.element
				});
			}
		});

		$(event.target).parents().andSelf().each(function() {
			var selectee = $.data(this, "selectable-item");
			if (selectee) {
				var doSelect = !event.metaKey || !selectee.$element.hasClass('ui-selected');
				selectee.$element
					.removeClass(doSelect ? "ui-unselecting" : "ui-selected")
					.addClass(doSelect ? "ui-selecting" : "ui-unselecting");
				selectee.unselecting = !doSelect;
				selectee.selecting = doSelect;
				selectee.selected = doSelect;
				// selectable (UN)SELECTING callback
				if (doSelect) {
					self._trigger("selecting", event, {
						selecting: selectee.element
					});
				} else {
					self._trigger("unselecting", event, {
						unselecting: selectee.element
					});
				}
				return false;
			}
		});

	},

	_mouseDrag: function(event) {
		var self = this;
		this.dragged = true;

		if (this.options.disabled)
			return;

		var options = this.options;

		var x1 = this.opos[0], y1 = this.opos[1], x2 = event.pageX, y2 = event.pageY;
		if (x1 > x2) { var tmp = x2; x2 = x1; x1 = tmp; }
		if (y1 > y2) { var tmp = y2; y2 = y1; y1 = tmp; }
		this.helper.css({left: x1, top: y1, width: x2-x1, height: y2-y1});

		this.selectees.each(function() {
			var selectee = $.data(this, "selectable-item");
			//prevent helper from being selected if appendTo: selectable
			if (!selectee || selectee.element == self.element[0])
				return;
			var hit = false;
			if (options.tolerance == 'touch') {
				hit = ( !(selectee.left > x2 || selectee.right < x1 || selectee.top > y2 || selectee.bottom < y1) );
			} else if (options.tolerance == 'fit') {
				hit = (selectee.left > x1 && selectee.right < x2 && selectee.top > y1 && selectee.bottom < y2);
			}

			if (hit) {
				// SELECT
				if (selectee.selected) {
					selectee.$element.removeClass('ui-selected');
					selectee.selected = false;
				}
				if (selectee.unselecting) {
					selectee.$element.removeClass('ui-unselecting');
					selectee.unselecting = false;
				}
				if (!selectee.selecting) {
					selectee.$element.addClass('ui-selecting');
					selectee.selecting = true;
					// selectable SELECTING callback
					self._trigger("selecting", event, {
						selecting: selectee.element
					});
				}
			} else {
				// UNSELECT
				if (selectee.selecting) {
					if (event.metaKey && selectee.startselected) {
						selectee.$element.removeClass('ui-selecting');
						selectee.selecting = false;
						selectee.$element.addClass('ui-selected');
						selectee.selected = true;
					} else {
						selectee.$element.removeClass('ui-selecting');
						selectee.selecting = false;
						if (selectee.startselected) {
							selectee.$element.addClass('ui-unselecting');
							selectee.unselecting = true;
						}
						// selectable UNSELECTING callback
						self._trigger("unselecting", event, {
							unselecting: selectee.element
						});
					}
				}
				if (selectee.selected) {
					if (!event.metaKey && !selectee.startselected) {
						selectee.$element.removeClass('ui-selected');
						selectee.selected = false;

						selectee.$element.addClass('ui-unselecting');
						selectee.unselecting = true;
						// selectable UNSELECTING callback
						self._trigger("unselecting", event, {
							unselecting: selectee.element
						});
					}
				}
			}
		});

		return false;
	},

	_mouseStop: function(event) {
		var self = this;

		this.dragged = false;

		var options = this.options;

		$('.ui-unselecting', this.element[0]).each(function() {
			var selectee = $.data(this, "selectable-item");
			selectee.$element.removeClass('ui-unselecting');
			selectee.unselecting = false;
			selectee.startselected = false;
			self._trigger("unselected", event, {
				unselected: selectee.element
			});
		});
		$('.ui-selecting', this.element[0]).each(function() {
			var selectee = $.data(this, "selectable-item");
			selectee.$element.removeClass('ui-selecting').addClass('ui-selected');
			selectee.selecting = false;
			selectee.selected = true;
			selectee.startselected = true;
			self._trigger("selected", event, {
				selected: selectee.element
			});
		});
		this._trigger("stop", event);

		this.helper.remove();

		return false;
	}

});

$.extend($.ui.selectable, {
	version: "1.8.14"
});

})(jQuery);
/*
 * jQuery UI Sortable 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Sortables
 *
 * Depends:
 *	jquery.ui.core.js
 *	jquery.ui.mouse.js
 *	jquery.ui.widget.js
 */
(function( $, undefined ) {

$.widget("ui.sortable", $.ui.mouse, {
	widgetEventPrefix: "sort",
	options: {
		appendTo: "parent",
		axis: false,
		connectWith: false,
		containment: false,
		cursor: 'auto',
		cursorAt: false,
		dropOnEmpty: true,
		forcePlaceholderSize: false,
		forceHelperSize: false,
		grid: false,
		handle: false,
		helper: "original",
		items: '> *',
		opacity: false,
		placeholder: false,
		revert: false,
		scroll: true,
		scrollSensitivity: 20,
		scrollSpeed: 20,
		scope: "default",
		tolerance: "intersect",
		zIndex: 1000
	},
	_create: function() {

		var o = this.options;
		this.containerCache = {};
		this.element.addClass("ui-sortable");

		//Get the items
		this.refresh();

		//Let's determine if the items are being displayed horizontally
		this.floating = this.items.length ? o.axis === 'x' || (/left|right/).test(this.items[0].item.css('float')) || (/inline|table-cell/).test(this.items[0].item.css('display')) : false;

		//Let's determine the parent's offset
		this.offset = this.element.offset();

		//Initialize mouse events for interaction
		this._mouseInit();

	},

	destroy: function() {
		this.element
			.removeClass("ui-sortable ui-sortable-disabled")
			.removeData("sortable")
			.unbind(".sortable");
		this._mouseDestroy();

		for ( var i = this.items.length - 1; i >= 0; i-- )
			this.items[i].item.removeData("sortable-item");

		return this;
	},

	_setOption: function(key, value){
		if ( key === "disabled" ) {
			this.options[ key ] = value;
	
			this.widget()
				[ value ? "addClass" : "removeClass"]( "ui-sortable-disabled" );
		} else {
			// Don't call widget base _setOption for disable as it adds ui-state-disabled class
			$.Widget.prototype._setOption.apply(this, arguments);
		}
	},

	_mouseCapture: function(event, overrideHandle) {

		if (this.reverting) {
			return false;
		}

		if(this.options.disabled || this.options.type == 'static') return false;

		//We have to refresh the items data once first
		this._refreshItems(event);

		//Find out if the clicked node (or one of its parents) is a actual item in this.items
		var currentItem = null, self = this, nodes = $(event.target).parents().each(function() {
			if($.data(this, 'sortable-item') == self) {
				currentItem = $(this);
				return false;
			}
		});
		if($.data(event.target, 'sortable-item') == self) currentItem = $(event.target);

		if(!currentItem) return false;
		if(this.options.handle && !overrideHandle) {
			var validHandle = false;

			$(this.options.handle, currentItem).find("*").andSelf().each(function() { if(this == event.target) validHandle = true; });
			if(!validHandle) return false;
		}

		this.currentItem = currentItem;
		this._removeCurrentsFromItems();
		return true;

	},

	_mouseStart: function(event, overrideHandle, noActivation) {

		var o = this.options, self = this;
		this.currentContainer = this;

		//We only need to call refreshPositions, because the refreshItems call has been moved to mouseCapture
		this.refreshPositions();

		//Create and append the visible helper
		this.helper = this._createHelper(event);

		//Cache the helper size
		this._cacheHelperProportions();

		/*
		 * - Position generation -
		 * This block generates everything position related - it's the core of draggables.
		 */

		//Cache the margins of the original element
		this._cacheMargins();

		//Get the next scrolling parent
		this.scrollParent = this.helper.scrollParent();

		//The element's absolute position on the page minus margins
		this.offset = this.currentItem.offset();
		this.offset = {
			top: this.offset.top - this.margins.top,
			left: this.offset.left - this.margins.left
		};

		// Only after we got the offset, we can change the helper's position to absolute
		// TODO: Still need to figure out a way to make relative sorting possible
		this.helper.css("position", "absolute");
		this.cssPosition = this.helper.css("position");

		$.extend(this.offset, {
			click: { //Where the click happened, relative to the element
				left: event.pageX - this.offset.left,
				top: event.pageY - this.offset.top
			},
			parent: this._getParentOffset(),
			relative: this._getRelativeOffset() //This is a relative to absolute position minus the actual position calculation - only used for relative positioned helper
		});

		//Generate the original position
		this.originalPosition = this._generatePosition(event);
		this.originalPageX = event.pageX;
		this.originalPageY = event.pageY;

		//Adjust the mouse offset relative to the helper if 'cursorAt' is supplied
		(o.cursorAt && this._adjustOffsetFromHelper(o.cursorAt));

		//Cache the former DOM position
		this.domPosition = { prev: this.currentItem.prev()[0], parent: this.currentItem.parent()[0] };

		//If the helper is not the original, hide the original so it's not playing any role during the drag, won't cause anything bad this way
		if(this.helper[0] != this.currentItem[0]) {
			this.currentItem.hide();
		}

		//Create the placeholder
		this._createPlaceholder();

		//Set a containment if given in the options
		if(o.containment)
			this._setContainment();

		if(o.cursor) { // cursor option
			if ($('body').css("cursor")) this._storedCursor = $('body').css("cursor");
			$('body').css("cursor", o.cursor);
		}

		if(o.opacity) { // opacity option
			if (this.helper.css("opacity")) this._storedOpacity = this.helper.css("opacity");
			this.helper.css("opacity", o.opacity);
		}

		if(o.zIndex) { // zIndex option
			if (this.helper.css("zIndex")) this._storedZIndex = this.helper.css("zIndex");
			this.helper.css("zIndex", o.zIndex);
		}

		//Prepare scrolling
		if(this.scrollParent[0] != document && this.scrollParent[0].tagName != 'HTML')
			this.overflowOffset = this.scrollParent.offset();

		//Call callbacks
		this._trigger("start", event, this._uiHash());

		//Recache the helper size
		if(!this._preserveHelperProportions)
			this._cacheHelperProportions();


		//Post 'activate' events to possible containers
		if(!noActivation) {
			 for (var i = this.containers.length - 1; i >= 0; i--) { this.containers[i]._trigger("activate", event, self._uiHash(this)); }
		}

		//Prepare possible droppables
		if($.ui.ddmanager)
			$.ui.ddmanager.current = this;

		if ($.ui.ddmanager && !o.dropBehaviour)
			$.ui.ddmanager.prepareOffsets(this, event);

		this.dragging = true;

		this.helper.addClass("ui-sortable-helper");
		this._mouseDrag(event); //Execute the drag once - this causes the helper not to be visible before getting its correct position
		return true;

	},

	_mouseDrag: function(event) {

		//Compute the helpers position
		this.position = this._generatePosition(event);
		this.positionAbs = this._convertPositionTo("absolute");

		if (!this.lastPositionAbs) {
			this.lastPositionAbs = this.positionAbs;
		}

		//Do scrolling
		if(this.options.scroll) {
			var o = this.options, scrolled = false;
			if(this.scrollParent[0] != document && this.scrollParent[0].tagName != 'HTML') {

				if((this.overflowOffset.top + this.scrollParent[0].offsetHeight) - event.pageY < o.scrollSensitivity)
					this.scrollParent[0].scrollTop = scrolled = this.scrollParent[0].scrollTop + o.scrollSpeed;
				else if(event.pageY - this.overflowOffset.top < o.scrollSensitivity)
					this.scrollParent[0].scrollTop = scrolled = this.scrollParent[0].scrollTop - o.scrollSpeed;

				if((this.overflowOffset.left + this.scrollParent[0].offsetWidth) - event.pageX < o.scrollSensitivity)
					this.scrollParent[0].scrollLeft = scrolled = this.scrollParent[0].scrollLeft + o.scrollSpeed;
				else if(event.pageX - this.overflowOffset.left < o.scrollSensitivity)
					this.scrollParent[0].scrollLeft = scrolled = this.scrollParent[0].scrollLeft - o.scrollSpeed;

			} else {

				if(event.pageY - $(document).scrollTop() < o.scrollSensitivity)
					scrolled = $(document).scrollTop($(document).scrollTop() - o.scrollSpeed);
				else if($(window).height() - (event.pageY - $(document).scrollTop()) < o.scrollSensitivity)
					scrolled = $(document).scrollTop($(document).scrollTop() + o.scrollSpeed);

				if(event.pageX - $(document).scrollLeft() < o.scrollSensitivity)
					scrolled = $(document).scrollLeft($(document).scrollLeft() - o.scrollSpeed);
				else if($(window).width() - (event.pageX - $(document).scrollLeft()) < o.scrollSensitivity)
					scrolled = $(document).scrollLeft($(document).scrollLeft() + o.scrollSpeed);

			}

			if(scrolled !== false && $.ui.ddmanager && !o.dropBehaviour)
				$.ui.ddmanager.prepareOffsets(this, event);
		}

		//Regenerate the absolute position used for position checks
		this.positionAbs = this._convertPositionTo("absolute");

		//Set the helper position
		if(!this.options.axis || this.options.axis != "y") this.helper[0].style.left = this.position.left+'px';
		if(!this.options.axis || this.options.axis != "x") this.helper[0].style.top = this.position.top+'px';

		//Rearrange
		for (var i = this.items.length - 1; i >= 0; i--) {

			//Cache variables and intersection, continue if no intersection
			var item = this.items[i], itemElement = item.item[0], intersection = this._intersectsWithPointer(item);
			if (!intersection) continue;

			if(itemElement != this.currentItem[0] //cannot intersect with itself
				&&	this.placeholder[intersection == 1 ? "next" : "prev"]()[0] != itemElement //no useless actions that have been done before
				&&	!$.ui.contains(this.placeholder[0], itemElement) //no action if the item moved is the parent of the item checked
				&& (this.options.type == 'semi-dynamic' ? !$.ui.contains(this.element[0], itemElement) : true)
				//&& itemElement.parentNode == this.placeholder[0].parentNode // only rearrange items within the same container
			) {

				this.direction = intersection == 1 ? "down" : "up";

				if (this.options.tolerance == "pointer" || this._intersectsWithSides(item)) {
					this._rearrange(event, item);
				} else {
					break;
				}

				this._trigger("change", event, this._uiHash());
				break;
			}
		}

		//Post events to containers
		this._contactContainers(event);

		//Interconnect with droppables
		if($.ui.ddmanager) $.ui.ddmanager.drag(this, event);

		//Call callbacks
		this._trigger('sort', event, this._uiHash());

		this.lastPositionAbs = this.positionAbs;
		return false;

	},

	_mouseStop: function(event, noPropagation) {

		if(!event) return;

		//If we are using droppables, inform the manager about the drop
		if ($.ui.ddmanager && !this.options.dropBehaviour)
			$.ui.ddmanager.drop(this, event);

		if(this.options.revert) {
			var self = this;
			var cur = self.placeholder.offset();

			self.reverting = true;

			$(this.helper).animate({
				left: cur.left - this.offset.parent.left - self.margins.left + (this.offsetParent[0] == document.body ? 0 : this.offsetParent[0].scrollLeft),
				top: cur.top - this.offset.parent.top - self.margins.top + (this.offsetParent[0] == document.body ? 0 : this.offsetParent[0].scrollTop)
			}, parseInt(this.options.revert, 10) || 500, function() {
				self._clear(event);
			});
		} else {
			this._clear(event, noPropagation);
		}

		return false;

	},

	cancel: function() {

		var self = this;

		if(this.dragging) {

			this._mouseUp({ target: null });

			if(this.options.helper == "original")
				this.currentItem.css(this._storedCSS).removeClass("ui-sortable-helper");
			else
				this.currentItem.show();

			//Post deactivating events to containers
			for (var i = this.containers.length - 1; i >= 0; i--){
				this.containers[i]._trigger("deactivate", null, self._uiHash(this));
				if(this.containers[i].containerCache.over) {
					this.containers[i]._trigger("out", null, self._uiHash(this));
					this.containers[i].containerCache.over = 0;
				}
			}

		}

		if (this.placeholder) {
			//$(this.placeholder[0]).remove(); would have been the jQuery way - unfortunately, it unbinds ALL events from the original node!
			if(this.placeholder[0].parentNode) this.placeholder[0].parentNode.removeChild(this.placeholder[0]);
			if(this.options.helper != "original" && this.helper && this.helper[0].parentNode) this.helper.remove();

			$.extend(this, {
				helper: null,
				dragging: false,
				reverting: false,
				_noFinalSort: null
			});

			if(this.domPosition.prev) {
				$(this.domPosition.prev).after(this.currentItem);
			} else {
				$(this.domPosition.parent).prepend(this.currentItem);
			}
		}

		return this;

	},

	serialize: function(o) {

		var items = this._getItemsAsjQuery(o && o.connected);
		var str = []; o = o || {};

		$(items).each(function() {
			var res = ($(o.item || this).attr(o.attribute || 'id') || '').match(o.expression || (/(.+)[-=_](.+)/));
			if(res) str.push((o.key || res[1]+'[]')+'='+(o.key && o.expression ? res[1] : res[2]));
		});

		if(!str.length && o.key) {
			str.push(o.key + '=');
		}

		return str.join('&');

	},

	toArray: function(o) {

		var items = this._getItemsAsjQuery(o && o.connected);
		var ret = []; o = o || {};

		items.each(function() { ret.push($(o.item || this).attr(o.attribute || 'id') || ''); });
		return ret;

	},

	/* Be careful with the following core functions */
	_intersectsWith: function(item) {

		var x1 = this.positionAbs.left,
			x2 = x1 + this.helperProportions.width,
			y1 = this.positionAbs.top,
			y2 = y1 + this.helperProportions.height;

		var l = item.left,
			r = l + item.width,
			t = item.top,
			b = t + item.height;

		var dyClick = this.offset.click.top,
			dxClick = this.offset.click.left;

		var isOverElement = (y1 + dyClick) > t && (y1 + dyClick) < b && (x1 + dxClick) > l && (x1 + dxClick) < r;

		if(	   this.options.tolerance == "pointer"
			|| this.options.forcePointerForContainers
			|| (this.options.tolerance != "pointer" && this.helperProportions[this.floating ? 'width' : 'height'] > item[this.floating ? 'width' : 'height'])
		) {
			return isOverElement;
		} else {

			return (l < x1 + (this.helperProportions.width / 2) // Right Half
				&& x2 - (this.helperProportions.width / 2) < r // Left Half
				&& t < y1 + (this.helperProportions.height / 2) // Bottom Half
				&& y2 - (this.helperProportions.height / 2) < b ); // Top Half

		}
	},

	_intersectsWithPointer: function(item) {

		var isOverElementHeight = $.ui.isOverAxis(this.positionAbs.top + this.offset.click.top, item.top, item.height),
			isOverElementWidth = $.ui.isOverAxis(this.positionAbs.left + this.offset.click.left, item.left, item.width),
			isOverElement = isOverElementHeight && isOverElementWidth,
			verticalDirection = this._getDragVerticalDirection(),
			horizontalDirection = this._getDragHorizontalDirection();

		if (!isOverElement)
			return false;

		return this.floating ?
			( ((horizontalDirection && horizontalDirection == "right") || verticalDirection == "down") ? 2 : 1 )
			: ( verticalDirection && (verticalDirection == "down" ? 2 : 1) );

	},

	_intersectsWithSides: function(item) {

		var isOverBottomHalf = $.ui.isOverAxis(this.positionAbs.top + this.offset.click.top, item.top + (item.height/2), item.height),
			isOverRightHalf = $.ui.isOverAxis(this.positionAbs.left + this.offset.click.left, item.left + (item.width/2), item.width),
			verticalDirection = this._getDragVerticalDirection(),
			horizontalDirection = this._getDragHorizontalDirection();

		if (this.floating && horizontalDirection) {
			return ((horizontalDirection == "right" && isOverRightHalf) || (horizontalDirection == "left" && !isOverRightHalf));
		} else {
			return verticalDirection && ((verticalDirection == "down" && isOverBottomHalf) || (verticalDirection == "up" && !isOverBottomHalf));
		}

	},

	_getDragVerticalDirection: function() {
		var delta = this.positionAbs.top - this.lastPositionAbs.top;
		return delta != 0 && (delta > 0 ? "down" : "up");
	},

	_getDragHorizontalDirection: function() {
		var delta = this.positionAbs.left - this.lastPositionAbs.left;
		return delta != 0 && (delta > 0 ? "right" : "left");
	},

	refresh: function(event) {
		this._refreshItems(event);
		this.refreshPositions();
		return this;
	},

	_connectWith: function() {
		var options = this.options;
		return options.connectWith.constructor == String
			? [options.connectWith]
			: options.connectWith;
	},
	
	_getItemsAsjQuery: function(connected) {

		var self = this;
		var items = [];
		var queries = [];
		var connectWith = this._connectWith();

		if(connectWith && connected) {
			for (var i = connectWith.length - 1; i >= 0; i--){
				var cur = $(connectWith[i]);
				for (var j = cur.length - 1; j >= 0; j--){
					var inst = $.data(cur[j], 'sortable');
					if(inst && inst != this && !inst.options.disabled) {
						queries.push([$.isFunction(inst.options.items) ? inst.options.items.call(inst.element) : $(inst.options.items, inst.element).not(".ui-sortable-helper").not('.ui-sortable-placeholder'), inst]);
					}
				};
			};
		}

		queries.push([$.isFunction(this.options.items) ? this.options.items.call(this.element, null, { options: this.options, item: this.currentItem }) : $(this.options.items, this.element).not(".ui-sortable-helper").not('.ui-sortable-placeholder'), this]);

		for (var i = queries.length - 1; i >= 0; i--){
			queries[i][0].each(function() {
				items.push(this);
			});
		};

		return $(items);

	},

	_removeCurrentsFromItems: function() {

		var list = this.currentItem.find(":data(sortable-item)");

		for (var i=0; i < this.items.length; i++) {

			for (var j=0; j < list.length; j++) {
				if(list[j] == this.items[i].item[0])
					this.items.splice(i,1);
			};

		};

	},

	_refreshItems: function(event) {

		this.items = [];
		this.containers = [this];
		var items = this.items;
		var self = this;
		var queries = [[$.isFunction(this.options.items) ? this.options.items.call(this.element[0], event, { item: this.currentItem }) : $(this.options.items, this.element), this]];
		var connectWith = this._connectWith();

		if(connectWith) {
			for (var i = connectWith.length - 1; i >= 0; i--){
				var cur = $(connectWith[i]);
				for (var j = cur.length - 1; j >= 0; j--){
					var inst = $.data(cur[j], 'sortable');
					if(inst && inst != this && !inst.options.disabled) {
						queries.push([$.isFunction(inst.options.items) ? inst.options.items.call(inst.element[0], event, { item: this.currentItem }) : $(inst.options.items, inst.element), inst]);
						this.containers.push(inst);
					}
				};
			};
		}

		for (var i = queries.length - 1; i >= 0; i--) {
			var targetData = queries[i][1];
			var _queries = queries[i][0];

			for (var j=0, queriesLength = _queries.length; j < queriesLength; j++) {
				var item = $(_queries[j]);

				item.data('sortable-item', targetData); // Data for target checking (mouse manager)

				items.push({
					item: item,
					instance: targetData,
					width: 0, height: 0,
					left: 0, top: 0
				});
			};
		};

	},

	refreshPositions: function(fast) {

		//This has to be redone because due to the item being moved out/into the offsetParent, the offsetParent's position will change
		if(this.offsetParent && this.helper) {
			this.offset.parent = this._getParentOffset();
		}

		for (var i = this.items.length - 1; i >= 0; i--){
			var item = this.items[i];

			//We ignore calculating positions of all connected containers when we're not over them
			if(item.instance != this.currentContainer && this.currentContainer && item.item[0] != this.currentItem[0])
				continue;

			var t = this.options.toleranceElement ? $(this.options.toleranceElement, item.item) : item.item;

			if (!fast) {
				item.width = t.outerWidth();
				item.height = t.outerHeight();
			}

			var p = t.offset();
			item.left = p.left;
			item.top = p.top;
		};

		if(this.options.custom && this.options.custom.refreshContainers) {
			this.options.custom.refreshContainers.call(this);
		} else {
			for (var i = this.containers.length - 1; i >= 0; i--){
				var p = this.containers[i].element.offset();
				this.containers[i].containerCache.left = p.left;
				this.containers[i].containerCache.top = p.top;
				this.containers[i].containerCache.width	= this.containers[i].element.outerWidth();
				this.containers[i].containerCache.height = this.containers[i].element.outerHeight();
			};
		}

		return this;
	},

	_createPlaceholder: function(that) {

		var self = that || this, o = self.options;

		if(!o.placeholder || o.placeholder.constructor == String) {
			var className = o.placeholder;
			o.placeholder = {
				element: function() {

					var el = $(document.createElement(self.currentItem[0].nodeName))
						.addClass(className || self.currentItem[0].className+" ui-sortable-placeholder")
						.removeClass("ui-sortable-helper")[0];

					if(!className)
						el.style.visibility = "hidden";

					return el;
				},
				update: function(container, p) {

					// 1. If a className is set as 'placeholder option, we don't force sizes - the class is responsible for that
					// 2. The option 'forcePlaceholderSize can be enabled to force it even if a class name is specified
					if(className && !o.forcePlaceholderSize) return;

					//If the element doesn't have a actual height by itself (without styles coming from a stylesheet), it receives the inline height from the dragged item
					if(!p.height()) { p.height(self.currentItem.innerHeight() - parseInt(self.currentItem.css('paddingTop')||0, 10) - parseInt(self.currentItem.css('paddingBottom')||0, 10)); };
					if(!p.width()) { p.width(self.currentItem.innerWidth() - parseInt(self.currentItem.css('paddingLeft')||0, 10) - parseInt(self.currentItem.css('paddingRight')||0, 10)); };
				}
			};
		}

		//Create the placeholder
		self.placeholder = $(o.placeholder.element.call(self.element, self.currentItem));

		//Append it after the actual current item
		self.currentItem.after(self.placeholder);

		//Update the size of the placeholder (TODO: Logic to fuzzy, see line 316/317)
		o.placeholder.update(self, self.placeholder);

	},

	_contactContainers: function(event) {
		
		// get innermost container that intersects with item 
		var innermostContainer = null, innermostIndex = null;		
		
		
		for (var i = this.containers.length - 1; i >= 0; i--){

			// never consider a container that's located within the item itself 
			if($.ui.contains(this.currentItem[0], this.containers[i].element[0]))
				continue;

			if(this._intersectsWith(this.containers[i].containerCache)) {

				// if we've already found a container and it's more "inner" than this, then continue 
				if(innermostContainer && $.ui.contains(this.containers[i].element[0], innermostContainer.element[0]))
					continue;

				innermostContainer = this.containers[i]; 
				innermostIndex = i;
					
			} else {
				// container doesn't intersect. trigger "out" event if necessary 
				if(this.containers[i].containerCache.over) {
					this.containers[i]._trigger("out", event, this._uiHash(this));
					this.containers[i].containerCache.over = 0;
				}
			}

		}
		
		// if no intersecting containers found, return 
		if(!innermostContainer) return; 

		// move the item into the container if it's not there already
		if(this.containers.length === 1) {
			this.containers[innermostIndex]._trigger("over", event, this._uiHash(this));
			this.containers[innermostIndex].containerCache.over = 1;
		} else if(this.currentContainer != this.containers[innermostIndex]) { 

			//When entering a new container, we will find the item with the least distance and append our item near it 
			var dist = 10000; var itemWithLeastDistance = null; var base = this.positionAbs[this.containers[innermostIndex].floating ? 'left' : 'top']; 
			for (var j = this.items.length - 1; j >= 0; j--) { 
				if(!$.ui.contains(this.containers[innermostIndex].element[0], this.items[j].item[0])) continue; 
				var cur = this.items[j][this.containers[innermostIndex].floating ? 'left' : 'top']; 
				if(Math.abs(cur - base) < dist) { 
					dist = Math.abs(cur - base); itemWithLeastDistance = this.items[j]; 
				} 
			} 

			if(!itemWithLeastDistance && !this.options.dropOnEmpty) //Check if dropOnEmpty is enabled 
				return; 

			this.currentContainer = this.containers[innermostIndex]; 
			itemWithLeastDistance ? this._rearrange(event, itemWithLeastDistance, null, true) : this._rearrange(event, null, this.containers[innermostIndex].element, true); 
			this._trigger("change", event, this._uiHash()); 
			this.containers[innermostIndex]._trigger("change", event, this._uiHash(this)); 

			//Update the placeholder 
			this.options.placeholder.update(this.currentContainer, this.placeholder); 
		
			this.containers[innermostIndex]._trigger("over", event, this._uiHash(this)); 
			this.containers[innermostIndex].containerCache.over = 1;
		} 
	
		
	},

	_createHelper: function(event) {

		var o = this.options;
		var helper = $.isFunction(o.helper) ? $(o.helper.apply(this.element[0], [event, this.currentItem])) : (o.helper == 'clone' ? this.currentItem.clone() : this.currentItem);

		if(!helper.parents('body').length) //Add the helper to the DOM if that didn't happen already
			$(o.appendTo != 'parent' ? o.appendTo : this.currentItem[0].parentNode)[0].appendChild(helper[0]);

		if(helper[0] == this.currentItem[0])
			this._storedCSS = { width: this.currentItem[0].style.width, height: this.currentItem[0].style.height, position: this.currentItem.css("position"), top: this.currentItem.css("top"), left: this.currentItem.css("left") };

		if(helper[0].style.width == '' || o.forceHelperSize) helper.width(this.currentItem.width());
		if(helper[0].style.height == '' || o.forceHelperSize) helper.height(this.currentItem.height());

		return helper;

	},

	_adjustOffsetFromHelper: function(obj) {
		if (typeof obj == 'string') {
			obj = obj.split(' ');
		}
		if ($.isArray(obj)) {
			obj = {left: +obj[0], top: +obj[1] || 0};
		}
		if ('left' in obj) {
			this.offset.click.left = obj.left + this.margins.left;
		}
		if ('right' in obj) {
			this.offset.click.left = this.helperProportions.width - obj.right + this.margins.left;
		}
		if ('top' in obj) {
			this.offset.click.top = obj.top + this.margins.top;
		}
		if ('bottom' in obj) {
			this.offset.click.top = this.helperProportions.height - obj.bottom + this.margins.top;
		}
	},

	_getParentOffset: function() {


		//Get the offsetParent and cache its position
		this.offsetParent = this.helper.offsetParent();
		var po = this.offsetParent.offset();

		// This is a special case where we need to modify a offset calculated on start, since the following happened:
		// 1. The position of the helper is absolute, so it's position is calculated based on the next positioned parent
		// 2. The actual offset parent is a child of the scroll parent, and the scroll parent isn't the document, which means that
		//    the scroll is included in the initial calculation of the offset of the parent, and never recalculated upon drag
		if(this.cssPosition == 'absolute' && this.scrollParent[0] != document && $.ui.contains(this.scrollParent[0], this.offsetParent[0])) {
			po.left += this.scrollParent.scrollLeft();
			po.top += this.scrollParent.scrollTop();
		}

		if((this.offsetParent[0] == document.body) //This needs to be actually done for all browsers, since pageX/pageY includes this information
		|| (this.offsetParent[0].tagName && this.offsetParent[0].tagName.toLowerCase() == 'html' && $.browser.msie)) //Ugly IE fix
			po = { top: 0, left: 0 };

		return {
			top: po.top + (parseInt(this.offsetParent.css("borderTopWidth"),10) || 0),
			left: po.left + (parseInt(this.offsetParent.css("borderLeftWidth"),10) || 0)
		};

	},

	_getRelativeOffset: function() {

		if(this.cssPosition == "relative") {
			var p = this.currentItem.position();
			return {
				top: p.top - (parseInt(this.helper.css("top"),10) || 0) + this.scrollParent.scrollTop(),
				left: p.left - (parseInt(this.helper.css("left"),10) || 0) + this.scrollParent.scrollLeft()
			};
		} else {
			return { top: 0, left: 0 };
		}

	},

	_cacheMargins: function() {
		this.margins = {
			left: (parseInt(this.currentItem.css("marginLeft"),10) || 0),
			top: (parseInt(this.currentItem.css("marginTop"),10) || 0)
		};
	},

	_cacheHelperProportions: function() {
		this.helperProportions = {
			width: this.helper.outerWidth(),
			height: this.helper.outerHeight()
		};
	},

	_setContainment: function() {

		var o = this.options;
		if(o.containment == 'parent') o.containment = this.helper[0].parentNode;
		if(o.containment == 'document' || o.containment == 'window') this.containment = [
			0 - this.offset.relative.left - this.offset.parent.left,
			0 - this.offset.relative.top - this.offset.parent.top,
			$(o.containment == 'document' ? document : window).width() - this.helperProportions.width - this.margins.left,
			($(o.containment == 'document' ? document : window).height() || document.body.parentNode.scrollHeight) - this.helperProportions.height - this.margins.top
		];

		if(!(/^(document|window|parent)$/).test(o.containment)) {
			var ce = $(o.containment)[0];
			var co = $(o.containment).offset();
			var over = ($(ce).css("overflow") != 'hidden');

			this.containment = [
				co.left + (parseInt($(ce).css("borderLeftWidth"),10) || 0) + (parseInt($(ce).css("paddingLeft"),10) || 0) - this.margins.left,
				co.top + (parseInt($(ce).css("borderTopWidth"),10) || 0) + (parseInt($(ce).css("paddingTop"),10) || 0) - this.margins.top,
				co.left+(over ? Math.max(ce.scrollWidth,ce.offsetWidth) : ce.offsetWidth) - (parseInt($(ce).css("borderLeftWidth"),10) || 0) - (parseInt($(ce).css("paddingRight"),10) || 0) - this.helperProportions.width - this.margins.left,
				co.top+(over ? Math.max(ce.scrollHeight,ce.offsetHeight) : ce.offsetHeight) - (parseInt($(ce).css("borderTopWidth"),10) || 0) - (parseInt($(ce).css("paddingBottom"),10) || 0) - this.helperProportions.height - this.margins.top
			];
		}

	},

	_convertPositionTo: function(d, pos) {

		if(!pos) pos = this.position;
		var mod = d == "absolute" ? 1 : -1;
		var o = this.options, scroll = this.cssPosition == 'absolute' && !(this.scrollParent[0] != document && $.ui.contains(this.scrollParent[0], this.offsetParent[0])) ? this.offsetParent : this.scrollParent, scrollIsRootNode = (/(html|body)/i).test(scroll[0].tagName);

		return {
			top: (
				pos.top																	// The absolute mouse position
				+ this.offset.relative.top * mod										// Only for relative positioned nodes: Relative offset from element to offset parent
				+ this.offset.parent.top * mod											// The offsetParent's offset without borders (offset + border)
				- ($.browser.safari && this.cssPosition == 'fixed' ? 0 : ( this.cssPosition == 'fixed' ? -this.scrollParent.scrollTop() : ( scrollIsRootNode ? 0 : scroll.scrollTop() ) ) * mod)
			),
			left: (
				pos.left																// The absolute mouse position
				+ this.offset.relative.left * mod										// Only for relative positioned nodes: Relative offset from element to offset parent
				+ this.offset.parent.left * mod											// The offsetParent's offset without borders (offset + border)
				- ($.browser.safari && this.cssPosition == 'fixed' ? 0 : ( this.cssPosition == 'fixed' ? -this.scrollParent.scrollLeft() : scrollIsRootNode ? 0 : scroll.scrollLeft() ) * mod)
			)
		};

	},

	_generatePosition: function(event) {

		var o = this.options, scroll = this.cssPosition == 'absolute' && !(this.scrollParent[0] != document && $.ui.contains(this.scrollParent[0], this.offsetParent[0])) ? this.offsetParent : this.scrollParent, scrollIsRootNode = (/(html|body)/i).test(scroll[0].tagName);

		// This is another very weird special case that only happens for relative elements:
		// 1. If the css position is relative
		// 2. and the scroll parent is the document or similar to the offset parent
		// we have to refresh the relative offset during the scroll so there are no jumps
		if(this.cssPosition == 'relative' && !(this.scrollParent[0] != document && this.scrollParent[0] != this.offsetParent[0])) {
			this.offset.relative = this._getRelativeOffset();
		}

		var pageX = event.pageX;
		var pageY = event.pageY;

		/*
		 * - Position constraining -
		 * Constrain the position to a mix of grid, containment.
		 */

		if(this.originalPosition) { //If we are not dragging yet, we won't check for options

			if(this.containment) {
				if(event.pageX - this.offset.click.left < this.containment[0]) pageX = this.containment[0] + this.offset.click.left;
				if(event.pageY - this.offset.click.top < this.containment[1]) pageY = this.containment[1] + this.offset.click.top;
				if(event.pageX - this.offset.click.left > this.containment[2]) pageX = this.containment[2] + this.offset.click.left;
				if(event.pageY - this.offset.click.top > this.containment[3]) pageY = this.containment[3] + this.offset.click.top;
			}

			if(o.grid) {
				var top = this.originalPageY + Math.round((pageY - this.originalPageY) / o.grid[1]) * o.grid[1];
				pageY = this.containment ? (!(top - this.offset.click.top < this.containment[1] || top - this.offset.click.top > this.containment[3]) ? top : (!(top - this.offset.click.top < this.containment[1]) ? top - o.grid[1] : top + o.grid[1])) : top;

				var left = this.originalPageX + Math.round((pageX - this.originalPageX) / o.grid[0]) * o.grid[0];
				pageX = this.containment ? (!(left - this.offset.click.left < this.containment[0] || left - this.offset.click.left > this.containment[2]) ? left : (!(left - this.offset.click.left < this.containment[0]) ? left - o.grid[0] : left + o.grid[0])) : left;
			}

		}

		return {
			top: (
				pageY																// The absolute mouse position
				- this.offset.click.top													// Click offset (relative to the element)
				- this.offset.relative.top												// Only for relative positioned nodes: Relative offset from element to offset parent
				- this.offset.parent.top												// The offsetParent's offset without borders (offset + border)
				+ ($.browser.safari && this.cssPosition == 'fixed' ? 0 : ( this.cssPosition == 'fixed' ? -this.scrollParent.scrollTop() : ( scrollIsRootNode ? 0 : scroll.scrollTop() ) ))
			),
			left: (
				pageX																// The absolute mouse position
				- this.offset.click.left												// Click offset (relative to the element)
				- this.offset.relative.left												// Only for relative positioned nodes: Relative offset from element to offset parent
				- this.offset.parent.left												// The offsetParent's offset without borders (offset + border)
				+ ($.browser.safari && this.cssPosition == 'fixed' ? 0 : ( this.cssPosition == 'fixed' ? -this.scrollParent.scrollLeft() : scrollIsRootNode ? 0 : scroll.scrollLeft() ))
			)
		};

	},

	_rearrange: function(event, i, a, hardRefresh) {

		a ? a[0].appendChild(this.placeholder[0]) : i.item[0].parentNode.insertBefore(this.placeholder[0], (this.direction == 'down' ? i.item[0] : i.item[0].nextSibling));

		//Various things done here to improve the performance:
		// 1. we create a setTimeout, that calls refreshPositions
		// 2. on the instance, we have a counter variable, that get's higher after every append
		// 3. on the local scope, we copy the counter variable, and check in the timeout, if it's still the same
		// 4. this lets only the last addition to the timeout stack through
		this.counter = this.counter ? ++this.counter : 1;
		var self = this, counter = this.counter;

		window.setTimeout(function() {
			if(counter == self.counter) self.refreshPositions(!hardRefresh); //Precompute after each DOM insertion, NOT on mousemove
		},0);

	},

	_clear: function(event, noPropagation) {

		this.reverting = false;
		// We delay all events that have to be triggered to after the point where the placeholder has been removed and
		// everything else normalized again
		var delayedTriggers = [], self = this;

		// We first have to update the dom position of the actual currentItem
		// Note: don't do it if the current item is already removed (by a user), or it gets reappended (see #4088)
		if(!this._noFinalSort && this.currentItem.parent().length) this.placeholder.before(this.currentItem);
		this._noFinalSort = null;

		if(this.helper[0] == this.currentItem[0]) {
			for(var i in this._storedCSS) {
				if(this._storedCSS[i] == 'auto' || this._storedCSS[i] == 'static') this._storedCSS[i] = '';
			}
			this.currentItem.css(this._storedCSS).removeClass("ui-sortable-helper");
		} else {
			this.currentItem.show();
		}

		if(this.fromOutside && !noPropagation) delayedTriggers.push(function(event) { this._trigger("receive", event, this._uiHash(this.fromOutside)); });
		if((this.fromOutside || this.domPosition.prev != this.currentItem.prev().not(".ui-sortable-helper")[0] || this.domPosition.parent != this.currentItem.parent()[0]) && !noPropagation) delayedTriggers.push(function(event) { this._trigger("update", event, this._uiHash()); }); //Trigger update callback if the DOM position has changed
		if(!$.ui.contains(this.element[0], this.currentItem[0])) { //Node was moved out of the current element
			if(!noPropagation) delayedTriggers.push(function(event) { this._trigger("remove", event, this._uiHash()); });
			for (var i = this.containers.length - 1; i >= 0; i--){
				if($.ui.contains(this.containers[i].element[0], this.currentItem[0]) && !noPropagation) {
					delayedTriggers.push((function(c) { return function(event) { c._trigger("receive", event, this._uiHash(this)); };  }).call(this, this.containers[i]));
					delayedTriggers.push((function(c) { return function(event) { c._trigger("update", event, this._uiHash(this));  }; }).call(this, this.containers[i]));
				}
			};
		};

		//Post events to containers
		for (var i = this.containers.length - 1; i >= 0; i--){
			if(!noPropagation) delayedTriggers.push((function(c) { return function(event) { c._trigger("deactivate", event, this._uiHash(this)); };  }).call(this, this.containers[i]));
			if(this.containers[i].containerCache.over) {
				delayedTriggers.push((function(c) { return function(event) { c._trigger("out", event, this._uiHash(this)); };  }).call(this, this.containers[i]));
				this.containers[i].containerCache.over = 0;
			}
		}

		//Do what was originally in plugins
		if(this._storedCursor) $('body').css("cursor", this._storedCursor); //Reset cursor
		if(this._storedOpacity) this.helper.css("opacity", this._storedOpacity); //Reset opacity
		if(this._storedZIndex) this.helper.css("zIndex", this._storedZIndex == 'auto' ? '' : this._storedZIndex); //Reset z-index

		this.dragging = false;
		if(this.cancelHelperRemoval) {
			if(!noPropagation) {
				this._trigger("beforeStop", event, this._uiHash());
				for (var i=0; i < delayedTriggers.length; i++) { delayedTriggers[i].call(this, event); }; //Trigger all delayed events
				this._trigger("stop", event, this._uiHash());
			}
			return false;
		}

		if(!noPropagation) this._trigger("beforeStop", event, this._uiHash());

		//$(this.placeholder[0]).remove(); would have been the jQuery way - unfortunately, it unbinds ALL events from the original node!
		this.placeholder[0].parentNode.removeChild(this.placeholder[0]);

		if(this.helper[0] != this.currentItem[0]) this.helper.remove(); this.helper = null;

		if(!noPropagation) {
			for (var i=0; i < delayedTriggers.length; i++) { delayedTriggers[i].call(this, event); }; //Trigger all delayed events
			this._trigger("stop", event, this._uiHash());
		}

		this.fromOutside = false;
		return true;

	},

	_trigger: function() {
		if ($.Widget.prototype._trigger.apply(this, arguments) === false) {
			this.cancel();
		}
	},

	_uiHash: function(inst) {
		var self = inst || this;
		return {
			helper: self.helper,
			placeholder: self.placeholder || $([]),
			position: self.position,
			originalPosition: self.originalPosition,
			offset: self.positionAbs,
			item: self.currentItem,
			sender: inst ? inst.element : null
		};
	}

});

$.extend($.ui.sortable, {
	version: "1.8.14"
});

})(jQuery);
/*
 * jQuery UI Effects 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Effects/
 */
;jQuery.effects || (function($, undefined) {

$.effects = {};



/******************************************************************************/
/****************************** COLOR ANIMATIONS ******************************/
/******************************************************************************/

// override the animation for color styles
$.each(['backgroundColor', 'borderBottomColor', 'borderLeftColor',
	'borderRightColor', 'borderTopColor', 'borderColor', 'color', 'outlineColor'],
function(i, attr) {
	$.fx.step[attr] = function(fx) {
		if (!fx.colorInit) {
			fx.start = getColor(fx.elem, attr);
			fx.end = getRGB(fx.end);
			fx.colorInit = true;
		}

		fx.elem.style[attr] = 'rgb(' +
			Math.max(Math.min(parseInt((fx.pos * (fx.end[0] - fx.start[0])) + fx.start[0], 10), 255), 0) + ',' +
			Math.max(Math.min(parseInt((fx.pos * (fx.end[1] - fx.start[1])) + fx.start[1], 10), 255), 0) + ',' +
			Math.max(Math.min(parseInt((fx.pos * (fx.end[2] - fx.start[2])) + fx.start[2], 10), 255), 0) + ')';
	};
});

// Color Conversion functions from highlightFade
// By Blair Mitchelmore
// http://jquery.offput.ca/highlightFade/

// Parse strings looking for color tuples [255,255,255]
function getRGB(color) {
		var result;

		// Check if we're already dealing with an array of colors
		if ( color && color.constructor == Array && color.length == 3 )
				return color;

		// Look for rgb(num,num,num)
		if (result = /rgb\(\s*([0-9]{1,3})\s*,\s*([0-9]{1,3})\s*,\s*([0-9]{1,3})\s*\)/.exec(color))
				return [parseInt(result[1],10), parseInt(result[2],10), parseInt(result[3],10)];

		// Look for rgb(num%,num%,num%)
		if (result = /rgb\(\s*([0-9]+(?:\.[0-9]+)?)\%\s*,\s*([0-9]+(?:\.[0-9]+)?)\%\s*,\s*([0-9]+(?:\.[0-9]+)?)\%\s*\)/.exec(color))
				return [parseFloat(result[1])*2.55, parseFloat(result[2])*2.55, parseFloat(result[3])*2.55];

		// Look for #a0b1c2
		if (result = /#([a-fA-F0-9]{2})([a-fA-F0-9]{2})([a-fA-F0-9]{2})/.exec(color))
				return [parseInt(result[1],16), parseInt(result[2],16), parseInt(result[3],16)];

		// Look for #fff
		if (result = /#([a-fA-F0-9])([a-fA-F0-9])([a-fA-F0-9])/.exec(color))
				return [parseInt(result[1]+result[1],16), parseInt(result[2]+result[2],16), parseInt(result[3]+result[3],16)];

		// Look for rgba(0, 0, 0, 0) == transparent in Safari 3
		if (result = /rgba\(0, 0, 0, 0\)/.exec(color))
				return colors['transparent'];

		// Otherwise, we're most likely dealing with a named color
		return colors[$.trim(color).toLowerCase()];
}

function getColor(elem, attr) {
		var color;

		do {
				color = $.curCSS(elem, attr);

				// Keep going until we find an element that has color, or we hit the body
				if ( color != '' && color != 'transparent' || $.nodeName(elem, "body") )
						break;

				attr = "backgroundColor";
		} while ( elem = elem.parentNode );

		return getRGB(color);
};

// Some named colors to work with
// From Interface by Stefan Petre
// http://interface.eyecon.ro/

var colors = {
	aqua:[0,255,255],
	azure:[240,255,255],
	beige:[245,245,220],
	black:[0,0,0],
	blue:[0,0,255],
	brown:[165,42,42],
	cyan:[0,255,255],
	darkblue:[0,0,139],
	darkcyan:[0,139,139],
	darkgrey:[169,169,169],
	darkgreen:[0,100,0],
	darkkhaki:[189,183,107],
	darkmagenta:[139,0,139],
	darkolivegreen:[85,107,47],
	darkorange:[255,140,0],
	darkorchid:[153,50,204],
	darkred:[139,0,0],
	darksalmon:[233,150,122],
	darkviolet:[148,0,211],
	fuchsia:[255,0,255],
	gold:[255,215,0],
	green:[0,128,0],
	indigo:[75,0,130],
	khaki:[240,230,140],
	lightblue:[173,216,230],
	lightcyan:[224,255,255],
	lightgreen:[144,238,144],
	lightgrey:[211,211,211],
	lightpink:[255,182,193],
	lightyellow:[255,255,224],
	lime:[0,255,0],
	magenta:[255,0,255],
	maroon:[128,0,0],
	navy:[0,0,128],
	olive:[128,128,0],
	orange:[255,165,0],
	pink:[255,192,203],
	purple:[128,0,128],
	violet:[128,0,128],
	red:[255,0,0],
	silver:[192,192,192],
	white:[255,255,255],
	yellow:[255,255,0],
	transparent: [255,255,255]
};



/******************************************************************************/
/****************************** CLASS ANIMATIONS ******************************/
/******************************************************************************/

var classAnimationActions = ['add', 'remove', 'toggle'],
	shorthandStyles = {
		border: 1,
		borderBottom: 1,
		borderColor: 1,
		borderLeft: 1,
		borderRight: 1,
		borderTop: 1,
		borderWidth: 1,
		margin: 1,
		padding: 1
	};

function getElementStyles() {
	var style = document.defaultView
			? document.defaultView.getComputedStyle(this, null)
			: this.currentStyle,
		newStyle = {},
		key,
		camelCase;

	// webkit enumerates style porperties
	if (style && style.length && style[0] && style[style[0]]) {
		var len = style.length;
		while (len--) {
			key = style[len];
			if (typeof style[key] == 'string') {
				camelCase = key.replace(/\-(\w)/g, function(all, letter){
					return letter.toUpperCase();
				});
				newStyle[camelCase] = style[key];
			}
		}
	} else {
		for (key in style) {
			if (typeof style[key] === 'string') {
				newStyle[key] = style[key];
			}
		}
	}
	
	return newStyle;
}

function filterStyles(styles) {
	var name, value;
	for (name in styles) {
		value = styles[name];
		if (
			// ignore null and undefined values
			value == null ||
			// ignore functions (when does this occur?)
			$.isFunction(value) ||
			// shorthand styles that need to be expanded
			name in shorthandStyles ||
			// ignore scrollbars (break in IE)
			(/scrollbar/).test(name) ||

			// only colors or values that can be converted to numbers
			(!(/color/i).test(name) && isNaN(parseFloat(value)))
		) {
			delete styles[name];
		}
	}
	
	return styles;
}

function styleDifference(oldStyle, newStyle) {
	var diff = { _: 0 }, // http://dev.jquery.com/ticket/5459
		name;

	for (name in newStyle) {
		if (oldStyle[name] != newStyle[name]) {
			diff[name] = newStyle[name];
		}
	}

	return diff;
}

$.effects.animateClass = function(value, duration, easing, callback) {
	if ($.isFunction(easing)) {
		callback = easing;
		easing = null;
	}

	return this.queue(function() {
		var that = $(this),
			originalStyleAttr = that.attr('style') || ' ',
			originalStyle = filterStyles(getElementStyles.call(this)),
			newStyle,
			className = that.attr('class');

		$.each(classAnimationActions, function(i, action) {
			if (value[action]) {
				that[action + 'Class'](value[action]);
			}
		});
		newStyle = filterStyles(getElementStyles.call(this));
		that.attr('class', className);

		that.animate(styleDifference(originalStyle, newStyle), {
			queue: false,
			duration: duration,
			easing: easing,
			complete: function() {
				$.each(classAnimationActions, function(i, action) {
					if (value[action]) { that[action + 'Class'](value[action]); }
				});
				// work around bug in IE by clearing the cssText before setting it
				if (typeof that.attr('style') == 'object') {
					that.attr('style').cssText = '';
					that.attr('style').cssText = originalStyleAttr;
				} else {
					that.attr('style', originalStyleAttr);
				}
				if (callback) { callback.apply(this, arguments); }
				$.dequeue( this );
			}
		});
	});
};

$.fn.extend({
	_addClass: $.fn.addClass,
	addClass: function(classNames, speed, easing, callback) {
		return speed ? $.effects.animateClass.apply(this, [{ add: classNames },speed,easing,callback]) : this._addClass(classNames);
	},

	_removeClass: $.fn.removeClass,
	removeClass: function(classNames,speed,easing,callback) {
		return speed ? $.effects.animateClass.apply(this, [{ remove: classNames },speed,easing,callback]) : this._removeClass(classNames);
	},

	_toggleClass: $.fn.toggleClass,
	toggleClass: function(classNames, force, speed, easing, callback) {
		if ( typeof force == "boolean" || force === undefined ) {
			if ( !speed ) {
				// without speed parameter;
				return this._toggleClass(classNames, force);
			} else {
				return $.effects.animateClass.apply(this, [(force?{add:classNames}:{remove:classNames}),speed,easing,callback]);
			}
		} else {
			// without switch parameter;
			return $.effects.animateClass.apply(this, [{ toggle: classNames },force,speed,easing]);
		}
	},

	switchClass: function(remove,add,speed,easing,callback) {
		return $.effects.animateClass.apply(this, [{ add: add, remove: remove },speed,easing,callback]);
	}
});



/******************************************************************************/
/*********************************** EFFECTS **********************************/
/******************************************************************************/

$.extend($.effects, {
	version: "1.8.14",

	// Saves a set of properties in a data storage
	save: function(element, set) {
		for(var i=0; i < set.length; i++) {
			if(set[i] !== null) element.data("ec.storage."+set[i], element[0].style[set[i]]);
		}
	},

	// Restores a set of previously saved properties from a data storage
	restore: function(element, set) {
		for(var i=0; i < set.length; i++) {
			if(set[i] !== null) element.css(set[i], element.data("ec.storage."+set[i]));
		}
	},

	setMode: function(el, mode) {
		if (mode == 'toggle') mode = el.is(':hidden') ? 'show' : 'hide'; // Set for toggle
		return mode;
	},

	getBaseline: function(origin, original) { // Translates a [top,left] array into a baseline value
		// this should be a little more flexible in the future to handle a string & hash
		var y, x;
		switch (origin[0]) {
			case 'top': y = 0; break;
			case 'middle': y = 0.5; break;
			case 'bottom': y = 1; break;
			default: y = origin[0] / original.height;
		};
		switch (origin[1]) {
			case 'left': x = 0; break;
			case 'center': x = 0.5; break;
			case 'right': x = 1; break;
			default: x = origin[1] / original.width;
		};
		return {x: x, y: y};
	},

	// Wraps the element around a wrapper that copies position properties
	createWrapper: function(element) {

		// if the element is already wrapped, return it
		if (element.parent().is('.ui-effects-wrapper')) {
			return element.parent();
		}

		// wrap the element
		var props = {
				width: element.outerWidth(true),
				height: element.outerHeight(true),
				'float': element.css('float')
			},
			wrapper = $('<div></div>')
				.addClass('ui-effects-wrapper')
				.css({
					fontSize: '100%',
					background: 'transparent',
					border: 'none',
					margin: 0,
					padding: 0
				});

		element.wrap(wrapper);
		wrapper = element.parent(); //Hotfix for jQuery 1.4 since some change in wrap() seems to actually loose the reference to the wrapped element

		// transfer positioning properties to the wrapper
		if (element.css('position') == 'static') {
			wrapper.css({ position: 'relative' });
			element.css({ position: 'relative' });
		} else {
			$.extend(props, {
				position: element.css('position'),
				zIndex: element.css('z-index')
			});
			$.each(['top', 'left', 'bottom', 'right'], function(i, pos) {
				props[pos] = element.css(pos);
				if (isNaN(parseInt(props[pos], 10))) {
					props[pos] = 'auto';
				}
			});
			element.css({position: 'relative', top: 0, left: 0, right: 'auto', bottom: 'auto' });
		}

		return wrapper.css(props).show();
	},

	removeWrapper: function(element) {
		if (element.parent().is('.ui-effects-wrapper'))
			return element.parent().replaceWith(element);
		return element;
	},

	setTransition: function(element, list, factor, value) {
		value = value || {};
		$.each(list, function(i, x){
			unit = element.cssUnit(x);
			if (unit[0] > 0) value[x] = unit[0] * factor + unit[1];
		});
		return value;
	}
});


function _normalizeArguments(effect, options, speed, callback) {
	// shift params for method overloading
	if (typeof effect == 'object') {
		callback = options;
		speed = null;
		options = effect;
		effect = options.effect;
	}
	if ($.isFunction(options)) {
		callback = options;
		speed = null;
		options = {};
	}
        if (typeof options == 'number' || $.fx.speeds[options]) {
		callback = speed;
		speed = options;
		options = {};
	}
	if ($.isFunction(speed)) {
		callback = speed;
		speed = null;
	}

	options = options || {};

	speed = speed || options.duration;
	speed = $.fx.off ? 0 : typeof speed == 'number'
		? speed : speed in $.fx.speeds ? $.fx.speeds[speed] : $.fx.speeds._default;

	callback = callback || options.complete;

	return [effect, options, speed, callback];
}

function standardSpeed( speed ) {
	// valid standard speeds
	if ( !speed || typeof speed === "number" || $.fx.speeds[ speed ] ) {
		return true;
	}
	
	// invalid strings - treat as "normal" speed
	if ( typeof speed === "string" && !$.effects[ speed ] ) {
		return true;
	}
	
	return false;
}

$.fn.extend({
	effect: function(effect, options, speed, callback) {
		var args = _normalizeArguments.apply(this, arguments),
			// TODO: make effects take actual parameters instead of a hash
			args2 = {
				options: args[1],
				duration: args[2],
				callback: args[3]
			},
			mode = args2.options.mode,
			effectMethod = $.effects[effect];
		
		if ( $.fx.off || !effectMethod ) {
			// delegate to the original method (e.g., .show()) if possible
			if ( mode ) {
				return this[ mode ]( args2.duration, args2.callback );
			} else {
				return this.each(function() {
					if ( args2.callback ) {
						args2.callback.call( this );
					}
				});
			}
		}
		
		return effectMethod.call(this, args2);
	},

	_show: $.fn.show,
	show: function(speed) {
		if ( standardSpeed( speed ) ) {
			return this._show.apply(this, arguments);
		} else {
			var args = _normalizeArguments.apply(this, arguments);
			args[1].mode = 'show';
			return this.effect.apply(this, args);
		}
	},

	_hide: $.fn.hide,
	hide: function(speed) {
		if ( standardSpeed( speed ) ) {
			return this._hide.apply(this, arguments);
		} else {
			var args = _normalizeArguments.apply(this, arguments);
			args[1].mode = 'hide';
			return this.effect.apply(this, args);
		}
	},

	// jQuery core overloads toggle and creates _toggle
	__toggle: $.fn.toggle,
	toggle: function(speed) {
		if ( standardSpeed( speed ) || typeof speed === "boolean" || $.isFunction( speed ) ) {
			return this.__toggle.apply(this, arguments);
		} else {
			var args = _normalizeArguments.apply(this, arguments);
			args[1].mode = 'toggle';
			return this.effect.apply(this, args);
		}
	},

	// helper functions
	cssUnit: function(key) {
		var style = this.css(key), val = [];
		$.each( ['em','px','%','pt'], function(i, unit){
			if(style.indexOf(unit) > 0)
				val = [parseFloat(style), unit];
		});
		return val;
	}
});



/******************************************************************************/
/*********************************** EASING ***********************************/
/******************************************************************************/

/*
 * jQuery Easing v1.3 - http://gsgd.co.uk/sandbox/jquery/easing/
 *
 * Uses the built in easing capabilities added In jQuery 1.1
 * to offer multiple easing options
 *
 * TERMS OF USE - jQuery Easing
 *
 * Open source under the BSD License.
 *
 * Copyright 2008 George McGinley Smith
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list of
 * conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list
 * of conditions and the following disclaimer in the documentation and/or other materials
 * provided with the distribution.
 *
 * Neither the name of the author nor the names of contributors may be used to endorse
 * or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
*/

// t: current time, b: begInnIng value, c: change In value, d: duration
$.easing.jswing = $.easing.swing;

$.extend($.easing,
{
	def: 'easeOutQuad',
	swing: function (x, t, b, c, d) {
		//alert($.easing.default);
		return $.easing[$.easing.def](x, t, b, c, d);
	},
	easeInQuad: function (x, t, b, c, d) {
		return c*(t/=d)*t + b;
	},
	easeOutQuad: function (x, t, b, c, d) {
		return -c *(t/=d)*(t-2) + b;
	},
	easeInOutQuad: function (x, t, b, c, d) {
		if ((t/=d/2) < 1) return c/2*t*t + b;
		return -c/2 * ((--t)*(t-2) - 1) + b;
	},
	easeInCubic: function (x, t, b, c, d) {
		return c*(t/=d)*t*t + b;
	},
	easeOutCubic: function (x, t, b, c, d) {
		return c*((t=t/d-1)*t*t + 1) + b;
	},
	easeInOutCubic: function (x, t, b, c, d) {
		if ((t/=d/2) < 1) return c/2*t*t*t + b;
		return c/2*((t-=2)*t*t + 2) + b;
	},
	easeInQuart: function (x, t, b, c, d) {
		return c*(t/=d)*t*t*t + b;
	},
	easeOutQuart: function (x, t, b, c, d) {
		return -c * ((t=t/d-1)*t*t*t - 1) + b;
	},
	easeInOutQuart: function (x, t, b, c, d) {
		if ((t/=d/2) < 1) return c/2*t*t*t*t + b;
		return -c/2 * ((t-=2)*t*t*t - 2) + b;
	},
	easeInQuint: function (x, t, b, c, d) {
		return c*(t/=d)*t*t*t*t + b;
	},
	easeOutQuint: function (x, t, b, c, d) {
		return c*((t=t/d-1)*t*t*t*t + 1) + b;
	},
	easeInOutQuint: function (x, t, b, c, d) {
		if ((t/=d/2) < 1) return c/2*t*t*t*t*t + b;
		return c/2*((t-=2)*t*t*t*t + 2) + b;
	},
	easeInSine: function (x, t, b, c, d) {
		return -c * Math.cos(t/d * (Math.PI/2)) + c + b;
	},
	easeOutSine: function (x, t, b, c, d) {
		return c * Math.sin(t/d * (Math.PI/2)) + b;
	},
	easeInOutSine: function (x, t, b, c, d) {
		return -c/2 * (Math.cos(Math.PI*t/d) - 1) + b;
	},
	easeInExpo: function (x, t, b, c, d) {
		return (t==0) ? b : c * Math.pow(2, 10 * (t/d - 1)) + b;
	},
	easeOutExpo: function (x, t, b, c, d) {
		return (t==d) ? b+c : c * (-Math.pow(2, -10 * t/d) + 1) + b;
	},
	easeInOutExpo: function (x, t, b, c, d) {
		if (t==0) return b;
		if (t==d) return b+c;
		if ((t/=d/2) < 1) return c/2 * Math.pow(2, 10 * (t - 1)) + b;
		return c/2 * (-Math.pow(2, -10 * --t) + 2) + b;
	},
	easeInCirc: function (x, t, b, c, d) {
		return -c * (Math.sqrt(1 - (t/=d)*t) - 1) + b;
	},
	easeOutCirc: function (x, t, b, c, d) {
		return c * Math.sqrt(1 - (t=t/d-1)*t) + b;
	},
	easeInOutCirc: function (x, t, b, c, d) {
		if ((t/=d/2) < 1) return -c/2 * (Math.sqrt(1 - t*t) - 1) + b;
		return c/2 * (Math.sqrt(1 - (t-=2)*t) + 1) + b;
	},
	easeInElastic: function (x, t, b, c, d) {
		var s=1.70158;var p=0;var a=c;
		if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
		if (a < Math.abs(c)) { a=c; var s=p/4; }
		else var s = p/(2*Math.PI) * Math.asin (c/a);
		return -(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;
	},
	easeOutElastic: function (x, t, b, c, d) {
		var s=1.70158;var p=0;var a=c;
		if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
		if (a < Math.abs(c)) { a=c; var s=p/4; }
		else var s = p/(2*Math.PI) * Math.asin (c/a);
		return a*Math.pow(2,-10*t) * Math.sin( (t*d-s)*(2*Math.PI)/p ) + c + b;
	},
	easeInOutElastic: function (x, t, b, c, d) {
		var s=1.70158;var p=0;var a=c;
		if (t==0) return b;  if ((t/=d/2)==2) return b+c;  if (!p) p=d*(.3*1.5);
		if (a < Math.abs(c)) { a=c; var s=p/4; }
		else var s = p/(2*Math.PI) * Math.asin (c/a);
		if (t < 1) return -.5*(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;
		return a*Math.pow(2,-10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )*.5 + c + b;
	},
	easeInBack: function (x, t, b, c, d, s) {
		if (s == undefined) s = 1.70158;
		return c*(t/=d)*t*((s+1)*t - s) + b;
	},
	easeOutBack: function (x, t, b, c, d, s) {
		if (s == undefined) s = 1.70158;
		return c*((t=t/d-1)*t*((s+1)*t + s) + 1) + b;
	},
	easeInOutBack: function (x, t, b, c, d, s) {
		if (s == undefined) s = 1.70158;
		if ((t/=d/2) < 1) return c/2*(t*t*(((s*=(1.525))+1)*t - s)) + b;
		return c/2*((t-=2)*t*(((s*=(1.525))+1)*t + s) + 2) + b;
	},
	easeInBounce: function (x, t, b, c, d) {
		return c - $.easing.easeOutBounce (x, d-t, 0, c, d) + b;
	},
	easeOutBounce: function (x, t, b, c, d) {
		if ((t/=d) < (1/2.75)) {
			return c*(7.5625*t*t) + b;
		} else if (t < (2/2.75)) {
			return c*(7.5625*(t-=(1.5/2.75))*t + .75) + b;
		} else if (t < (2.5/2.75)) {
			return c*(7.5625*(t-=(2.25/2.75))*t + .9375) + b;
		} else {
			return c*(7.5625*(t-=(2.625/2.75))*t + .984375) + b;
		}
	},
	easeInOutBounce: function (x, t, b, c, d) {
		if (t < d/2) return $.easing.easeInBounce (x, t*2, 0, c, d) * .5 + b;
		return $.easing.easeOutBounce (x, t*2-d, 0, c, d) * .5 + c*.5 + b;
	}
});

/*
 *
 * TERMS OF USE - EASING EQUATIONS
 *
 * Open source under the BSD License.
 *
 * Copyright 2001 Robert Penner
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list of
 * conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list
 * of conditions and the following disclaimer in the documentation and/or other materials
 * provided with the distribution.
 *
 * Neither the name of the author nor the names of contributors may be used to endorse
 * or promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

})(jQuery);
/*
 * jQuery UI Effects Blind 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Effects/Blind
 *
 * Depends:
 *	jquery.effects.core.js
 */
(function( $, undefined ) {

$.effects.blind = function(o) {

	return this.queue(function() {

		// Create element
		var el = $(this), props = ['position','top','bottom','left','right'];

		// Set options
		var mode = $.effects.setMode(el, o.options.mode || 'hide'); // Set Mode
		var direction = o.options.direction || 'vertical'; // Default direction

		// Adjust
		$.effects.save(el, props); el.show(); // Save & Show
		var wrapper = $.effects.createWrapper(el).css({overflow:'hidden'}); // Create Wrapper
		var ref = (direction == 'vertical') ? 'height' : 'width';
		var distance = (direction == 'vertical') ? wrapper.height() : wrapper.width();
		if(mode == 'show') wrapper.css(ref, 0); // Shift

		// Animation
		var animation = {};
		animation[ref] = mode == 'show' ? distance : 0;

		// Animate
		wrapper.animate(animation, o.duration, o.options.easing, function() {
			if(mode == 'hide') el.hide(); // Hide
			$.effects.restore(el, props); $.effects.removeWrapper(el); // Restore
			if(o.callback) o.callback.apply(el[0], arguments); // Callback
			el.dequeue();
		});

	});

};

})(jQuery);
/*
 * jQuery UI Effects Bounce 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Effects/Bounce
 *
 * Depends:
 *	jquery.effects.core.js
 */
(function( $, undefined ) {

$.effects.bounce = function(o) {

	return this.queue(function() {

		// Create element
		var el = $(this), props = ['position','top','bottom','left','right'];

		// Set options
		var mode = $.effects.setMode(el, o.options.mode || 'effect'); // Set Mode
		var direction = o.options.direction || 'up'; // Default direction
		var distance = o.options.distance || 20; // Default distance
		var times = o.options.times || 5; // Default # of times
		var speed = o.duration || 250; // Default speed per bounce
		if (/show|hide/.test(mode)) props.push('opacity'); // Avoid touching opacity to prevent clearType and PNG issues in IE

		// Adjust
		$.effects.save(el, props); el.show(); // Save & Show
		$.effects.createWrapper(el); // Create Wrapper
		var ref = (direction == 'up' || direction == 'down') ? 'top' : 'left';
		var motion = (direction == 'up' || direction == 'left') ? 'pos' : 'neg';
		var distance = o.options.distance || (ref == 'top' ? el.outerHeight({margin:true}) / 3 : el.outerWidth({margin:true}) / 3);
		if (mode == 'show') el.css('opacity', 0).css(ref, motion == 'pos' ? -distance : distance); // Shift
		if (mode == 'hide') distance = distance / (times * 2);
		if (mode != 'hide') times--;

		// Animate
		if (mode == 'show') { // Show Bounce
			var animation = {opacity: 1};
			animation[ref] = (motion == 'pos' ? '+=' : '-=') + distance;
			el.animate(animation, speed / 2, o.options.easing);
			distance = distance / 2;
			times--;
		};
		for (var i = 0; i < times; i++) { // Bounces
			var animation1 = {}, animation2 = {};
			animation1[ref] = (motion == 'pos' ? '-=' : '+=') + distance;
			animation2[ref] = (motion == 'pos' ? '+=' : '-=') + distance;
			el.animate(animation1, speed / 2, o.options.easing).animate(animation2, speed / 2, o.options.easing);
			distance = (mode == 'hide') ? distance * 2 : distance / 2;
		};
		if (mode == 'hide') { // Last Bounce
			var animation = {opacity: 0};
			animation[ref] = (motion == 'pos' ? '-=' : '+=')  + distance;
			el.animate(animation, speed / 2, o.options.easing, function(){
				el.hide(); // Hide
				$.effects.restore(el, props); $.effects.removeWrapper(el); // Restore
				if(o.callback) o.callback.apply(this, arguments); // Callback
			});
		} else {
			var animation1 = {}, animation2 = {};
			animation1[ref] = (motion == 'pos' ? '-=' : '+=') + distance;
			animation2[ref] = (motion == 'pos' ? '+=' : '-=') + distance;
			el.animate(animation1, speed / 2, o.options.easing).animate(animation2, speed / 2, o.options.easing, function(){
				$.effects.restore(el, props); $.effects.removeWrapper(el); // Restore
				if(o.callback) o.callback.apply(this, arguments); // Callback
			});
		};
		el.queue('fx', function() { el.dequeue(); });
		el.dequeue();
	});

};

})(jQuery);
/*
 * jQuery UI Effects Clip 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Effects/Clip
 *
 * Depends:
 *	jquery.effects.core.js
 */
(function( $, undefined ) {

$.effects.clip = function(o) {

	return this.queue(function() {

		// Create element
		var el = $(this), props = ['position','top','bottom','left','right','height','width'];

		// Set options
		var mode = $.effects.setMode(el, o.options.mode || 'hide'); // Set Mode
		var direction = o.options.direction || 'vertical'; // Default direction

		// Adjust
		$.effects.save(el, props); el.show(); // Save & Show
		var wrapper = $.effects.createWrapper(el).css({overflow:'hidden'}); // Create Wrapper
		var animate = el[0].tagName == 'IMG' ? wrapper : el;
		var ref = {
			size: (direction == 'vertical') ? 'height' : 'width',
			position: (direction == 'vertical') ? 'top' : 'left'
		};
		var distance = (direction == 'vertical') ? animate.height() : animate.width();
		if(mode == 'show') { animate.css(ref.size, 0); animate.css(ref.position, distance / 2); } // Shift

		// Animation
		var animation = {};
		animation[ref.size] = mode == 'show' ? distance : 0;
		animation[ref.position] = mode == 'show' ? 0 : distance / 2;

		// Animate
		animate.animate(animation, { queue: false, duration: o.duration, easing: o.options.easing, complete: function() {
			if(mode == 'hide') el.hide(); // Hide
			$.effects.restore(el, props); $.effects.removeWrapper(el); // Restore
			if(o.callback) o.callback.apply(el[0], arguments); // Callback
			el.dequeue();
		}});

	});

};

})(jQuery);
/*
 * jQuery UI Effects Drop 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Effects/Drop
 *
 * Depends:
 *	jquery.effects.core.js
 */
(function( $, undefined ) {

$.effects.drop = function(o) {

	return this.queue(function() {

		// Create element
		var el = $(this), props = ['position','top','bottom','left','right','opacity'];

		// Set options
		var mode = $.effects.setMode(el, o.options.mode || 'hide'); // Set Mode
		var direction = o.options.direction || 'left'; // Default Direction

		// Adjust
		$.effects.save(el, props); el.show(); // Save & Show
		$.effects.createWrapper(el); // Create Wrapper
		var ref = (direction == 'up' || direction == 'down') ? 'top' : 'left';
		var motion = (direction == 'up' || direction == 'left') ? 'pos' : 'neg';
		var distance = o.options.distance || (ref == 'top' ? el.outerHeight({margin:true}) / 2 : el.outerWidth({margin:true}) / 2);
		if (mode == 'show') el.css('opacity', 0).css(ref, motion == 'pos' ? -distance : distance); // Shift

		// Animation
		var animation = {opacity: mode == 'show' ? 1 : 0};
		animation[ref] = (mode == 'show' ? (motion == 'pos' ? '+=' : '-=') : (motion == 'pos' ? '-=' : '+=')) + distance;

		// Animate
		el.animate(animation, { queue: false, duration: o.duration, easing: o.options.easing, complete: function() {
			if(mode == 'hide') el.hide(); // Hide
			$.effects.restore(el, props); $.effects.removeWrapper(el); // Restore
			if(o.callback) o.callback.apply(this, arguments); // Callback
			el.dequeue();
		}});

	});

};

})(jQuery);
/*
 * jQuery UI Effects Explode 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Effects/Explode
 *
 * Depends:
 *	jquery.effects.core.js
 */
(function( $, undefined ) {

$.effects.explode = function(o) {

	return this.queue(function() {

	var rows = o.options.pieces ? Math.round(Math.sqrt(o.options.pieces)) : 3;
	var cells = o.options.pieces ? Math.round(Math.sqrt(o.options.pieces)) : 3;

	o.options.mode = o.options.mode == 'toggle' ? ($(this).is(':visible') ? 'hide' : 'show') : o.options.mode;
	var el = $(this).show().css('visibility', 'hidden');
	var offset = el.offset();

	//Substract the margins - not fixing the problem yet.
	offset.top -= parseInt(el.css("marginTop"),10) || 0;
	offset.left -= parseInt(el.css("marginLeft"),10) || 0;

	var width = el.outerWidth(true);
	var height = el.outerHeight(true);

	for(var i=0;i<rows;i++) { // =
		for(var j=0;j<cells;j++) { // ||
			el
				.clone()
				.appendTo('body')
				.wrap('<div></div>')
				.css({
					position: 'absolute',
					visibility: 'visible',
					left: -j*(width/cells),
					top: -i*(height/rows)
				})
				.parent()
				.addClass('ui-effects-explode')
				.css({
					position: 'absolute',
					overflow: 'hidden',
					width: width/cells,
					height: height/rows,
					left: offset.left + j*(width/cells) + (o.options.mode == 'show' ? (j-Math.floor(cells/2))*(width/cells) : 0),
					top: offset.top + i*(height/rows) + (o.options.mode == 'show' ? (i-Math.floor(rows/2))*(height/rows) : 0),
					opacity: o.options.mode == 'show' ? 0 : 1
				}).animate({
					left: offset.left + j*(width/cells) + (o.options.mode == 'show' ? 0 : (j-Math.floor(cells/2))*(width/cells)),
					top: offset.top + i*(height/rows) + (o.options.mode == 'show' ? 0 : (i-Math.floor(rows/2))*(height/rows)),
					opacity: o.options.mode == 'show' ? 1 : 0
				}, o.duration || 500);
		}
	}

	// Set a timeout, to call the callback approx. when the other animations have finished
	setTimeout(function() {

		o.options.mode == 'show' ? el.css({ visibility: 'visible' }) : el.css({ visibility: 'visible' }).hide();
				if(o.callback) o.callback.apply(el[0]); // Callback
				el.dequeue();

				$('div.ui-effects-explode').remove();

	}, o.duration || 500);


	});

};

})(jQuery);
/*
 * jQuery UI Effects Fade 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Effects/Fade
 *
 * Depends:
 *	jquery.effects.core.js
 */
(function( $, undefined ) {

$.effects.fade = function(o) {
	return this.queue(function() {
		var elem = $(this),
			mode = $.effects.setMode(elem, o.options.mode || 'hide');

		elem.animate({ opacity: mode }, {
			queue: false,
			duration: o.duration,
			easing: o.options.easing,
			complete: function() {
				(o.callback && o.callback.apply(this, arguments));
				elem.dequeue();
			}
		});
	});
};

})(jQuery);
/*
 * jQuery UI Effects Fold 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Effects/Fold
 *
 * Depends:
 *	jquery.effects.core.js
 */
(function( $, undefined ) {

$.effects.fold = function(o) {

	return this.queue(function() {

		// Create element
		var el = $(this), props = ['position','top','bottom','left','right'];

		// Set options
		var mode = $.effects.setMode(el, o.options.mode || 'hide'); // Set Mode
		var size = o.options.size || 15; // Default fold size
		var horizFirst = !(!o.options.horizFirst); // Ensure a boolean value
		var duration = o.duration ? o.duration / 2 : $.fx.speeds._default / 2;

		// Adjust
		$.effects.save(el, props); el.show(); // Save & Show
		var wrapper = $.effects.createWrapper(el).css({overflow:'hidden'}); // Create Wrapper
		var widthFirst = ((mode == 'show') != horizFirst);
		var ref = widthFirst ? ['width', 'height'] : ['height', 'width'];
		var distance = widthFirst ? [wrapper.width(), wrapper.height()] : [wrapper.height(), wrapper.width()];
		var percent = /([0-9]+)%/.exec(size);
		if(percent) size = parseInt(percent[1],10) / 100 * distance[mode == 'hide' ? 0 : 1];
		if(mode == 'show') wrapper.css(horizFirst ? {height: 0, width: size} : {height: size, width: 0}); // Shift

		// Animation
		var animation1 = {}, animation2 = {};
		animation1[ref[0]] = mode == 'show' ? distance[0] : size;
		animation2[ref[1]] = mode == 'show' ? distance[1] : 0;

		// Animate
		wrapper.animate(animation1, duration, o.options.easing)
		.animate(animation2, duration, o.options.easing, function() {
			if(mode == 'hide') el.hide(); // Hide
			$.effects.restore(el, props); $.effects.removeWrapper(el); // Restore
			if(o.callback) o.callback.apply(el[0], arguments); // Callback
			el.dequeue();
		});

	});

};

})(jQuery);
/*
 * jQuery UI Effects Highlight 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Effects/Highlight
 *
 * Depends:
 *	jquery.effects.core.js
 */
(function( $, undefined ) {

$.effects.highlight = function(o) {
	return this.queue(function() {
		var elem = $(this),
			props = ['backgroundImage', 'backgroundColor', 'opacity'],
			mode = $.effects.setMode(elem, o.options.mode || 'show'),
			animation = {
				backgroundColor: elem.css('backgroundColor')
			};

		if (mode == 'hide') {
			animation.opacity = 0;
		}

		$.effects.save(elem, props);
		elem
			.show()
			.css({
				backgroundImage: 'none',
				backgroundColor: o.options.color || '#ffff99'
			})
			.animate(animation, {
				queue: false,
				duration: o.duration,
				easing: o.options.easing,
				complete: function() {
					(mode == 'hide' && elem.hide());
					$.effects.restore(elem, props);
					(mode == 'show' && !$.support.opacity && this.style.removeAttribute('filter'));
					(o.callback && o.callback.apply(this, arguments));
					elem.dequeue();
				}
			});
	});
};

})(jQuery);
/*
 * jQuery UI Effects Pulsate 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Effects/Pulsate
 *
 * Depends:
 *	jquery.effects.core.js
 */
(function( $, undefined ) {

$.effects.pulsate = function(o) {
	return this.queue(function() {
		var elem = $(this),
			mode = $.effects.setMode(elem, o.options.mode || 'show');
			times = ((o.options.times || 5) * 2) - 1;
			duration = o.duration ? o.duration / 2 : $.fx.speeds._default / 2,
			isVisible = elem.is(':visible'),
			animateTo = 0;

		if (!isVisible) {
			elem.css('opacity', 0).show();
			animateTo = 1;
		}

		if ((mode == 'hide' && isVisible) || (mode == 'show' && !isVisible)) {
			times--;
		}

		for (var i = 0; i < times; i++) {
			elem.animate({ opacity: animateTo }, duration, o.options.easing);
			animateTo = (animateTo + 1) % 2;
		}

		elem.animate({ opacity: animateTo }, duration, o.options.easing, function() {
			if (animateTo == 0) {
				elem.hide();
			}
			(o.callback && o.callback.apply(this, arguments));
		});

		elem
			.queue('fx', function() { elem.dequeue(); })
			.dequeue();
	});
};

})(jQuery);
/*
 * jQuery UI Effects Scale 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Effects/Scale
 *
 * Depends:
 *	jquery.effects.core.js
 */
(function( $, undefined ) {

$.effects.puff = function(o) {
	return this.queue(function() {
		var elem = $(this),
			mode = $.effects.setMode(elem, o.options.mode || 'hide'),
			percent = parseInt(o.options.percent, 10) || 150,
			factor = percent / 100,
			original = { height: elem.height(), width: elem.width() };

		$.extend(o.options, {
			fade: true,
			mode: mode,
			percent: mode == 'hide' ? percent : 100,
			from: mode == 'hide'
				? original
				: {
					height: original.height * factor,
					width: original.width * factor
				}
		});

		elem.effect('scale', o.options, o.duration, o.callback);
		elem.dequeue();
	});
};

$.effects.scale = function(o) {

	return this.queue(function() {

		// Create element
		var el = $(this);

		// Set options
		var options = $.extend(true, {}, o.options);
		var mode = $.effects.setMode(el, o.options.mode || 'effect'); // Set Mode
		var percent = parseInt(o.options.percent,10) || (parseInt(o.options.percent,10) == 0 ? 0 : (mode == 'hide' ? 0 : 100)); // Set default scaling percent
		var direction = o.options.direction || 'both'; // Set default axis
		var origin = o.options.origin; // The origin of the scaling
		if (mode != 'effect') { // Set default origin and restore for show/hide
			options.origin = origin || ['middle','center'];
			options.restore = true;
		}
		var original = {height: el.height(), width: el.width()}; // Save original
		el.from = o.options.from || (mode == 'show' ? {height: 0, width: 0} : original); // Default from state

		// Adjust
		var factor = { // Set scaling factor
			y: direction != 'horizontal' ? (percent / 100) : 1,
			x: direction != 'vertical' ? (percent / 100) : 1
		};
		el.to = {height: original.height * factor.y, width: original.width * factor.x}; // Set to state

		if (o.options.fade) { // Fade option to support puff
			if (mode == 'show') {el.from.opacity = 0; el.to.opacity = 1;};
			if (mode == 'hide') {el.from.opacity = 1; el.to.opacity = 0;};
		};

		// Animation
		options.from = el.from; options.to = el.to; options.mode = mode;

		// Animate
		el.effect('size', options, o.duration, o.callback);
		el.dequeue();
	});

};

$.effects.size = function(o) {

	return this.queue(function() {

		// Create element
		var el = $(this), props = ['position','top','bottom','left','right','width','height','overflow','opacity'];
		var props1 = ['position','top','bottom','left','right','overflow','opacity']; // Always restore
		var props2 = ['width','height','overflow']; // Copy for children
		var cProps = ['fontSize'];
		var vProps = ['borderTopWidth', 'borderBottomWidth', 'paddingTop', 'paddingBottom'];
		var hProps = ['borderLeftWidth', 'borderRightWidth', 'paddingLeft', 'paddingRight'];

		// Set options
		var mode = $.effects.setMode(el, o.options.mode || 'effect'); // Set Mode
		var restore = o.options.restore || false; // Default restore
		var scale = o.options.scale || 'both'; // Default scale mode
		var origin = o.options.origin; // The origin of the sizing
		var original = {height: el.height(), width: el.width()}; // Save original
		el.from = o.options.from || original; // Default from state
		el.to = o.options.to || original; // Default to state
		// Adjust
		if (origin) { // Calculate baseline shifts
			var baseline = $.effects.getBaseline(origin, original);
			el.from.top = (original.height - el.from.height) * baseline.y;
			el.from.left = (original.width - el.from.width) * baseline.x;
			el.to.top = (original.height - el.to.height) * baseline.y;
			el.to.left = (original.width - el.to.width) * baseline.x;
		};
		var factor = { // Set scaling factor
			from: {y: el.from.height / original.height, x: el.from.width / original.width},
			to: {y: el.to.height / original.height, x: el.to.width / original.width}
		};
		if (scale == 'box' || scale == 'both') { // Scale the css box
			if (factor.from.y != factor.to.y) { // Vertical props scaling
				props = props.concat(vProps);
				el.from = $.effects.setTransition(el, vProps, factor.from.y, el.from);
				el.to = $.effects.setTransition(el, vProps, factor.to.y, el.to);
			};
			if (factor.from.x != factor.to.x) { // Horizontal props scaling
				props = props.concat(hProps);
				el.from = $.effects.setTransition(el, hProps, factor.from.x, el.from);
				el.to = $.effects.setTransition(el, hProps, factor.to.x, el.to);
			};
		};
		if (scale == 'content' || scale == 'both') { // Scale the content
			if (factor.from.y != factor.to.y) { // Vertical props scaling
				props = props.concat(cProps);
				el.from = $.effects.setTransition(el, cProps, factor.from.y, el.from);
				el.to = $.effects.setTransition(el, cProps, factor.to.y, el.to);
			};
		};
		$.effects.save(el, restore ? props : props1); el.show(); // Save & Show
		$.effects.createWrapper(el); // Create Wrapper
		el.css('overflow','hidden').css(el.from); // Shift

		// Animate
		if (scale == 'content' || scale == 'both') { // Scale the children
			vProps = vProps.concat(['marginTop','marginBottom']).concat(cProps); // Add margins/font-size
			hProps = hProps.concat(['marginLeft','marginRight']); // Add margins
			props2 = props.concat(vProps).concat(hProps); // Concat
			el.find("*[width]").each(function(){
				child = $(this);
				if (restore) $.effects.save(child, props2);
				var c_original = {height: child.height(), width: child.width()}; // Save original
				child.from = {height: c_original.height * factor.from.y, width: c_original.width * factor.from.x};
				child.to = {height: c_original.height * factor.to.y, width: c_original.width * factor.to.x};
				if (factor.from.y != factor.to.y) { // Vertical props scaling
					child.from = $.effects.setTransition(child, vProps, factor.from.y, child.from);
					child.to = $.effects.setTransition(child, vProps, factor.to.y, child.to);
				};
				if (factor.from.x != factor.to.x) { // Horizontal props scaling
					child.from = $.effects.setTransition(child, hProps, factor.from.x, child.from);
					child.to = $.effects.setTransition(child, hProps, factor.to.x, child.to);
				};
				child.css(child.from); // Shift children
				child.animate(child.to, o.duration, o.options.easing, function(){
					if (restore) $.effects.restore(child, props2); // Restore children
				}); // Animate children
			});
		};

		// Animate
		el.animate(el.to, { queue: false, duration: o.duration, easing: o.options.easing, complete: function() {
			if (el.to.opacity === 0) {
				el.css('opacity', el.from.opacity);
			}
			if(mode == 'hide') el.hide(); // Hide
			$.effects.restore(el, restore ? props : props1); $.effects.removeWrapper(el); // Restore
			if(o.callback) o.callback.apply(this, arguments); // Callback
			el.dequeue();
		}});

	});

};

})(jQuery);
/*
 * jQuery UI Effects Shake 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Effects/Shake
 *
 * Depends:
 *	jquery.effects.core.js
 */
(function( $, undefined ) {

$.effects.shake = function(o) {

	return this.queue(function() {

		// Create element
		var el = $(this), props = ['position','top','bottom','left','right'];

		// Set options
		var mode = $.effects.setMode(el, o.options.mode || 'effect'); // Set Mode
		var direction = o.options.direction || 'left'; // Default direction
		var distance = o.options.distance || 20; // Default distance
		var times = o.options.times || 3; // Default # of times
		var speed = o.duration || o.options.duration || 140; // Default speed per shake

		// Adjust
		$.effects.save(el, props); el.show(); // Save & Show
		$.effects.createWrapper(el); // Create Wrapper
		var ref = (direction == 'up' || direction == 'down') ? 'top' : 'left';
		var motion = (direction == 'up' || direction == 'left') ? 'pos' : 'neg';

		// Animation
		var animation = {}, animation1 = {}, animation2 = {};
		animation[ref] = (motion == 'pos' ? '-=' : '+=')  + distance;
		animation1[ref] = (motion == 'pos' ? '+=' : '-=')  + distance * 2;
		animation2[ref] = (motion == 'pos' ? '-=' : '+=')  + distance * 2;

		// Animate
		el.animate(animation, speed, o.options.easing);
		for (var i = 1; i < times; i++) { // Shakes
			el.animate(animation1, speed, o.options.easing).animate(animation2, speed, o.options.easing);
		};
		el.animate(animation1, speed, o.options.easing).
		animate(animation, speed / 2, o.options.easing, function(){ // Last shake
			$.effects.restore(el, props); $.effects.removeWrapper(el); // Restore
			if(o.callback) o.callback.apply(this, arguments); // Callback
		});
		el.queue('fx', function() { el.dequeue(); });
		el.dequeue();
	});

};

})(jQuery);
/*
 * jQuery UI Effects Slide 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Effects/Slide
 *
 * Depends:
 *	jquery.effects.core.js
 */
(function( $, undefined ) {

$.effects.slide = function(o) {

	return this.queue(function() {

		// Create element
		var el = $(this), props = ['position','top','bottom','left','right'];

		// Set options
		var mode = $.effects.setMode(el, o.options.mode || 'show'); // Set Mode
		var direction = o.options.direction || 'left'; // Default Direction

		// Adjust
		$.effects.save(el, props); el.show(); // Save & Show
		$.effects.createWrapper(el).css({overflow:'hidden'}); // Create Wrapper
		var ref = (direction == 'up' || direction == 'down') ? 'top' : 'left';
		var motion = (direction == 'up' || direction == 'left') ? 'pos' : 'neg';
		var distance = o.options.distance || (ref == 'top' ? el.outerHeight({margin:true}) : el.outerWidth({margin:true}));
		if (mode == 'show') el.css(ref, motion == 'pos' ? (isNaN(distance) ? "-" + distance : -distance) : distance); // Shift

		// Animation
		var animation = {};
		animation[ref] = (mode == 'show' ? (motion == 'pos' ? '+=' : '-=') : (motion == 'pos' ? '-=' : '+=')) + distance;

		// Animate
		el.animate(animation, { queue: false, duration: o.duration, easing: o.options.easing, complete: function() {
			if(mode == 'hide') el.hide(); // Hide
			$.effects.restore(el, props); $.effects.removeWrapper(el); // Restore
			if(o.callback) o.callback.apply(this, arguments); // Callback
			el.dequeue();
		}});

	});

};

})(jQuery);
/*
 * jQuery UI Effects Transfer 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Effects/Transfer
 *
 * Depends:
 *	jquery.effects.core.js
 */
(function( $, undefined ) {

$.effects.transfer = function(o) {
	return this.queue(function() {
		var elem = $(this),
			target = $(o.options.to),
			endPosition = target.offset(),
			animation = {
				top: endPosition.top,
				left: endPosition.left,
				height: target.innerHeight(),
				width: target.innerWidth()
			},
			startPosition = elem.offset(),
			transfer = $('<div class="ui-effects-transfer"></div>')
				.appendTo(document.body)
				.addClass(o.options.className)
				.css({
					top: startPosition.top,
					left: startPosition.left,
					height: elem.innerHeight(),
					width: elem.innerWidth(),
					position: 'absolute'
				})
				.animate(animation, o.duration, o.options.easing, function() {
					transfer.remove();
					(o.callback && o.callback.apply(elem[0], arguments));
					elem.dequeue();
				});
	});
};

})(jQuery);
/*
 * jQuery UI Accordion 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Accordion
 *
 * Depends:
 *	jquery.ui.core.js
 *	jquery.ui.widget.js
 */
(function( $, undefined ) {

$.widget( "ui.accordion", {
	options: {
		active: 0,
		animated: "slide",
		autoHeight: true,
		clearStyle: false,
		collapsible: false,
		event: "click",
		fillSpace: false,
		header: "> li > :first-child,> :not(li):even",
		icons: {
			header: "ui-icon-triangle-1-e",
			headerSelected: "ui-icon-triangle-1-s"
		},
		navigation: false,
		navigationFilter: function() {
			return this.href.toLowerCase() === location.href.toLowerCase();
		}
	},

	_create: function() {
		var self = this,
			options = self.options;

		self.running = 0;

		self.element
			.addClass( "ui-accordion ui-widget ui-helper-reset" )
			// in lack of child-selectors in CSS
			// we need to mark top-LIs in a UL-accordion for some IE-fix
			.children( "li" )
				.addClass( "ui-accordion-li-fix" );

		self.headers = self.element.find( options.header )
			.addClass( "ui-accordion-header ui-helper-reset ui-state-default ui-corner-all" )
			.bind( "mouseenter.accordion", function() {
				if ( options.disabled ) {
					return;
				}
				$( this ).addClass( "ui-state-hover" );
			})
			.bind( "mouseleave.accordion", function() {
				if ( options.disabled ) {
					return;
				}
				$( this ).removeClass( "ui-state-hover" );
			})
			.bind( "focus.accordion", function() {
				if ( options.disabled ) {
					return;
				}
				$( this ).addClass( "ui-state-focus" );
			})
			.bind( "blur.accordion", function() {
				if ( options.disabled ) {
					return;
				}
				$( this ).removeClass( "ui-state-focus" );
			});

		self.headers.next()
			.addClass( "ui-accordion-content ui-helper-reset ui-widget-content ui-corner-bottom" );

		if ( options.navigation ) {
			var current = self.element.find( "a" ).filter( options.navigationFilter ).eq( 0 );
			if ( current.length ) {
				var header = current.closest( ".ui-accordion-header" );
				if ( header.length ) {
					// anchor within header
					self.active = header;
				} else {
					// anchor within content
					self.active = current.closest( ".ui-accordion-content" ).prev();
				}
			}
		}

		self.active = self._findActive( self.active || options.active )
			.addClass( "ui-state-default ui-state-active" )
			.toggleClass( "ui-corner-all" )
			.toggleClass( "ui-corner-top" );
		self.active.next().addClass( "ui-accordion-content-active" );

		self._createIcons();
		self.resize();
		
		// ARIA
		self.element.attr( "role", "tablist" );

		self.headers
			.attr( "role", "tab" )
			.bind( "keydown.accordion", function( event ) {
				return self._keydown( event );
			})
			.next()
				.attr( "role", "tabpanel" );

		self.headers
			.not( self.active || "" )
			.attr({
				"aria-expanded": "false",
				"aria-selected": "false",
				tabIndex: -1
			})
			.next()
				.hide();

		// make sure at least one header is in the tab order
		if ( !self.active.length ) {
			self.headers.eq( 0 ).attr( "tabIndex", 0 );
		} else {
			self.active
				.attr({
					"aria-expanded": "true",
					"aria-selected": "true",
					tabIndex: 0
				});
		}

		// only need links in tab order for Safari
		if ( !$.browser.safari ) {
			self.headers.find( "a" ).attr( "tabIndex", -1 );
		}

		if ( options.event ) {
			self.headers.bind( options.event.split(" ").join(".accordion ") + ".accordion", function(event) {
				self._clickHandler.call( self, event, this );
				event.preventDefault();
			});
		}
	},

	_createIcons: function() {
		var options = this.options;
		if ( options.icons ) {
			$( "<span></span>" )
				.addClass( "ui-icon " + options.icons.header )
				.prependTo( this.headers );
			this.active.children( ".ui-icon" )
				.toggleClass(options.icons.header)
				.toggleClass(options.icons.headerSelected);
			this.element.addClass( "ui-accordion-icons" );
		}
	},

	_destroyIcons: function() {
		this.headers.children( ".ui-icon" ).remove();
		this.element.removeClass( "ui-accordion-icons" );
	},

	destroy: function() {
		var options = this.options;

		this.element
			.removeClass( "ui-accordion ui-widget ui-helper-reset" )
			.removeAttr( "role" );

		this.headers
			.unbind( ".accordion" )
			.removeClass( "ui-accordion-header ui-accordion-disabled ui-helper-reset ui-state-default ui-corner-all ui-state-active ui-state-disabled ui-corner-top" )
			.removeAttr( "role" )
			.removeAttr( "aria-expanded" )
			.removeAttr( "aria-selected" )
			.removeAttr( "tabIndex" );

		this.headers.find( "a" ).removeAttr( "tabIndex" );
		this._destroyIcons();
		var contents = this.headers.next()
			.css( "display", "" )
			.removeAttr( "role" )
			.removeClass( "ui-helper-reset ui-widget-content ui-corner-bottom ui-accordion-content ui-accordion-content-active ui-accordion-disabled ui-state-disabled" );
		if ( options.autoHeight || options.fillHeight ) {
			contents.css( "height", "" );
		}

		return $.Widget.prototype.destroy.call( this );
	},

	_setOption: function( key, value ) {
		$.Widget.prototype._setOption.apply( this, arguments );
			
		if ( key == "active" ) {
			this.activate( value );
		}
		if ( key == "icons" ) {
			this._destroyIcons();
			if ( value ) {
				this._createIcons();
			}
		}
		// #5332 - opacity doesn't cascade to positioned elements in IE
		// so we need to add the disabled class to the headers and panels
		if ( key == "disabled" ) {
			this.headers.add(this.headers.next())
				[ value ? "addClass" : "removeClass" ](
					"ui-accordion-disabled ui-state-disabled" );
		}
	},

	_keydown: function( event ) {
		if ( this.options.disabled || event.altKey || event.ctrlKey ) {
			return;
		}

		var keyCode = $.ui.keyCode,
			length = this.headers.length,
			currentIndex = this.headers.index( event.target ),
			toFocus = false;

		switch ( event.keyCode ) {
			case keyCode.RIGHT:
			case keyCode.DOWN:
				toFocus = this.headers[ ( currentIndex + 1 ) % length ];
				break;
			case keyCode.LEFT:
			case keyCode.UP:
				toFocus = this.headers[ ( currentIndex - 1 + length ) % length ];
				break;
			case keyCode.SPACE:
			case keyCode.ENTER:
				this._clickHandler( { target: event.target }, event.target );
				event.preventDefault();
		}

		if ( toFocus ) {
			$( event.target ).attr( "tabIndex", -1 );
			$( toFocus ).attr( "tabIndex", 0 );
			toFocus.focus();
			return false;
		}

		return true;
	},

	resize: function() {
		var options = this.options,
			maxHeight;

		if ( options.fillSpace ) {
			if ( $.browser.msie ) {
				var defOverflow = this.element.parent().css( "overflow" );
				this.element.parent().css( "overflow", "hidden");
			}
			maxHeight = this.element.parent().height();
			if ($.browser.msie) {
				this.element.parent().css( "overflow", defOverflow );
			}

			this.headers.each(function() {
				maxHeight -= $( this ).outerHeight( true );
			});

			this.headers.next()
				.each(function() {
					$( this ).height( Math.max( 0, maxHeight -
						$( this ).innerHeight() + $( this ).height() ) );
				})
				.css( "overflow", "auto" );
		} else if ( options.autoHeight ) {
			maxHeight = 0;
			this.headers.next()
				.each(function() {
					maxHeight = Math.max( maxHeight, $( this ).height( "" ).height() );
				})
				.height( maxHeight );
		}

		return this;
	},

	activate: function( index ) {
		// TODO this gets called on init, changing the option without an explicit call for that
		this.options.active = index;
		// call clickHandler with custom event
		var active = this._findActive( index )[ 0 ];
		this._clickHandler( { target: active }, active );

		return this;
	},

	_findActive: function( selector ) {
		return selector
			? typeof selector === "number"
				? this.headers.filter( ":eq(" + selector + ")" )
				: this.headers.not( this.headers.not( selector ) )
			: selector === false
				? $( [] )
				: this.headers.filter( ":eq(0)" );
	},

	// TODO isn't event.target enough? why the separate target argument?
	_clickHandler: function( event, target ) {
		var options = this.options;
		if ( options.disabled ) {
			return;
		}

		// called only when using activate(false) to close all parts programmatically
		if ( !event.target ) {
			if ( !options.collapsible ) {
				return;
			}
			this.active
				.removeClass( "ui-state-active ui-corner-top" )
				.addClass( "ui-state-default ui-corner-all" )
				.children( ".ui-icon" )
					.removeClass( options.icons.headerSelected )
					.addClass( options.icons.header );
			this.active.next().addClass( "ui-accordion-content-active" );
			var toHide = this.active.next(),
				data = {
					options: options,
					newHeader: $( [] ),
					oldHeader: options.active,
					newContent: $( [] ),
					oldContent: toHide
				},
				toShow = ( this.active = $( [] ) );
			this._toggle( toShow, toHide, data );
			return;
		}

		// get the click target
		var clicked = $( event.currentTarget || target ),
			clickedIsActive = clicked[0] === this.active[0];

		// TODO the option is changed, is that correct?
		// TODO if it is correct, shouldn't that happen after determining that the click is valid?
		options.active = options.collapsible && clickedIsActive ?
			false :
			this.headers.index( clicked );

		// if animations are still active, or the active header is the target, ignore click
		if ( this.running || ( !options.collapsible && clickedIsActive ) ) {
			return;
		}

		// find elements to show and hide
		var active = this.active,
			toShow = clicked.next(),
			toHide = this.active.next(),
			data = {
				options: options,
				newHeader: clickedIsActive && options.collapsible ? $([]) : clicked,
				oldHeader: this.active,
				newContent: clickedIsActive && options.collapsible ? $([]) : toShow,
				oldContent: toHide
			},
			down = this.headers.index( this.active[0] ) > this.headers.index( clicked[0] );

		// when the call to ._toggle() comes after the class changes
		// it causes a very odd bug in IE 8 (see #6720)
		this.active = clickedIsActive ? $([]) : clicked;
		this._toggle( toShow, toHide, data, clickedIsActive, down );

		// switch classes
		active
			.removeClass( "ui-state-active ui-corner-top" )
			.addClass( "ui-state-default ui-corner-all" )
			.children( ".ui-icon" )
				.removeClass( options.icons.headerSelected )
				.addClass( options.icons.header );
		if ( !clickedIsActive ) {
			clicked
				.removeClass( "ui-state-default ui-corner-all" )
				.addClass( "ui-state-active ui-corner-top" )
				.children( ".ui-icon" )
					.removeClass( options.icons.header )
					.addClass( options.icons.headerSelected );
			clicked
				.next()
				.addClass( "ui-accordion-content-active" );
		}

		return;
	},

	_toggle: function( toShow, toHide, data, clickedIsActive, down ) {
		var self = this,
			options = self.options;

		self.toShow = toShow;
		self.toHide = toHide;
		self.data = data;

		var complete = function() {
			if ( !self ) {
				return;
			}
			return self._completed.apply( self, arguments );
		};

		// trigger changestart event
		self._trigger( "changestart", null, self.data );

		// count elements to animate
		self.running = toHide.size() === 0 ? toShow.size() : toHide.size();

		if ( options.animated ) {
			var animOptions = {};

			if ( options.collapsible && clickedIsActive ) {
				animOptions = {
					toShow: $( [] ),
					toHide: toHide,
					complete: complete,
					down: down,
					autoHeight: options.autoHeight || options.fillSpace
				};
			} else {
				animOptions = {
					toShow: toShow,
					toHide: toHide,
					complete: complete,
					down: down,
					autoHeight: options.autoHeight || options.fillSpace
				};
			}

			if ( !options.proxied ) {
				options.proxied = options.animated;
			}

			if ( !options.proxiedDuration ) {
				options.proxiedDuration = options.duration;
			}

			options.animated = $.isFunction( options.proxied ) ?
				options.proxied( animOptions ) :
				options.proxied;

			options.duration = $.isFunction( options.proxiedDuration ) ?
				options.proxiedDuration( animOptions ) :
				options.proxiedDuration;

			var animations = $.ui.accordion.animations,
				duration = options.duration,
				easing = options.animated;

			if ( easing && !animations[ easing ] && !$.easing[ easing ] ) {
				easing = "slide";
			}
			if ( !animations[ easing ] ) {
				animations[ easing ] = function( options ) {
					this.slide( options, {
						easing: easing,
						duration: duration || 700
					});
				};
			}

			animations[ easing ]( animOptions );
		} else {
			if ( options.collapsible && clickedIsActive ) {
				toShow.toggle();
			} else {
				toHide.hide();
				toShow.show();
			}

			complete( true );
		}

		// TODO assert that the blur and focus triggers are really necessary, remove otherwise
		toHide.prev()
			.attr({
				"aria-expanded": "false",
				"aria-selected": "false",
				tabIndex: -1
			})
			.blur();
		toShow.prev()
			.attr({
				"aria-expanded": "true",
				"aria-selected": "true",
				tabIndex: 0
			})
			.focus();
	},

	_completed: function( cancel ) {
		this.running = cancel ? 0 : --this.running;
		if ( this.running ) {
			return;
		}

		if ( this.options.clearStyle ) {
			this.toShow.add( this.toHide ).css({
				height: "",
				overflow: ""
			});
		}

		// other classes are removed before the animation; this one needs to stay until completed
		this.toHide.removeClass( "ui-accordion-content-active" );
		// Work around for rendering bug in IE (#5421)
		if ( this.toHide.length ) {
			this.toHide.parent()[0].className = this.toHide.parent()[0].className;
		}

		this._trigger( "change", null, this.data );
	}
});

$.extend( $.ui.accordion, {
	version: "1.8.14",
	animations: {
		slide: function( options, additions ) {
			options = $.extend({
				easing: "swing",
				duration: 300
			}, options, additions );
			if ( !options.toHide.size() ) {
				options.toShow.animate({
					height: "show",
					paddingTop: "show",
					paddingBottom: "show"
				}, options );
				return;
			}
			if ( !options.toShow.size() ) {
				options.toHide.animate({
					height: "hide",
					paddingTop: "hide",
					paddingBottom: "hide"
				}, options );
				return;
			}
			var overflow = options.toShow.css( "overflow" ),
				percentDone = 0,
				showProps = {},
				hideProps = {},
				fxAttrs = [ "height", "paddingTop", "paddingBottom" ],
				originalWidth;
			// fix width before calculating height of hidden element
			var s = options.toShow;
			originalWidth = s[0].style.width;
			s.width( parseInt( s.parent().width(), 10 )
				- parseInt( s.css( "paddingLeft" ), 10 )
				- parseInt( s.css( "paddingRight" ), 10 )
				- ( parseInt( s.css( "borderLeftWidth" ), 10 ) || 0 )
				- ( parseInt( s.css( "borderRightWidth" ), 10) || 0 ) );

			$.each( fxAttrs, function( i, prop ) {
				hideProps[ prop ] = "hide";

				var parts = ( "" + $.css( options.toShow[0], prop ) ).match( /^([\d+-.]+)(.*)$/ );
				showProps[ prop ] = {
					value: parts[ 1 ],
					unit: parts[ 2 ] || "px"
				};
			});
			options.toShow.css({ height: 0, overflow: "hidden" }).show();
			options.toHide
				.filter( ":hidden" )
					.each( options.complete )
				.end()
				.filter( ":visible" )
				.animate( hideProps, {
				step: function( now, settings ) {
					// only calculate the percent when animating height
					// IE gets very inconsistent results when animating elements
					// with small values, which is common for padding
					if ( settings.prop == "height" ) {
						percentDone = ( settings.end - settings.start === 0 ) ? 0 :
							( settings.now - settings.start ) / ( settings.end - settings.start );
					}

					options.toShow[ 0 ].style[ settings.prop ] =
						( percentDone * showProps[ settings.prop ].value )
						+ showProps[ settings.prop ].unit;
				},
				duration: options.duration,
				easing: options.easing,
				complete: function() {
					if ( !options.autoHeight ) {
						options.toShow.css( "height", "" );
					}
					options.toShow.css({
						width: originalWidth,
						overflow: overflow
					});
					options.complete();
				}
			});
		},
		bounceslide: function( options ) {
			this.slide( options, {
				easing: options.down ? "easeOutBounce" : "swing",
				duration: options.down ? 1000 : 200
			});
		}
	}
});

})( jQuery );
/*
 * jQuery UI Autocomplete 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Autocomplete
 *
 * Depends:
 *	jquery.ui.core.js
 *	jquery.ui.widget.js
 *	jquery.ui.position.js
 */
(function( $, undefined ) {

// used to prevent race conditions with remote data sources
var requestIndex = 0;

$.widget( "ui.autocomplete", {
	options: {
		appendTo: "body",
		autoFocus: false,
		delay: 300,
		minLength: 1,
		position: {
			my: "left top",
			at: "left bottom",
			collision: "none"
		},
		source: null
	},

	pending: 0,

	_create: function() {
		var self = this,
			doc = this.element[ 0 ].ownerDocument,
			suppressKeyPress;

		this.element
			.addClass( "ui-autocomplete-input" )
			.attr( "autocomplete", "off" )
			// TODO verify these actually work as intended
			.attr({
				role: "textbox",
				"aria-autocomplete": "list",
				"aria-haspopup": "true"
			})
			.bind( "keydown.autocomplete", function( event ) {
				if ( self.options.disabled || self.element.attr( "readonly" ) ) {
					return;
				}

				suppressKeyPress = false;
				var keyCode = $.ui.keyCode;
				switch( event.keyCode ) {
				case keyCode.PAGE_UP:
					self._move( "previousPage", event );
					break;
				case keyCode.PAGE_DOWN:
					self._move( "nextPage", event );
					break;
				case keyCode.UP:
					self._move( "previous", event );
					// prevent moving cursor to beginning of text field in some browsers
					event.preventDefault();
					break;
				case keyCode.DOWN:
					self._move( "next", event );
					// prevent moving cursor to end of text field in some browsers
					event.preventDefault();
					break;
				case keyCode.ENTER:
				case keyCode.NUMPAD_ENTER:
					// when menu is open and has focus
					if ( self.menu.active ) {
						// #6055 - Opera still allows the keypress to occur
						// which causes forms to submit
						suppressKeyPress = true;
						event.preventDefault();
					}
					//passthrough - ENTER and TAB both select the current element
				case keyCode.TAB:
					if ( !self.menu.active ) {
						return;
					}
					self.menu.select( event );
					break;
				case keyCode.ESCAPE:
					self.element.val( self.term );
					self.close( event );
					break;
				default:
					// keypress is triggered before the input value is changed
					clearTimeout( self.searching );
					self.searching = setTimeout(function() {
						// only search if the value has changed
						if ( self.term != self.element.val() ) {
							self.selectedItem = null;
							self.search( null, event );
						}
					}, self.options.delay );
					break;
				}
			})
			.bind( "keypress.autocomplete", function( event ) {
				if ( suppressKeyPress ) {
					suppressKeyPress = false;
					event.preventDefault();
				}
			})
			.bind( "focus.autocomplete", function() {
				if ( self.options.disabled ) {
					return;
				}

				self.selectedItem = null;
				self.previous = self.element.val();
			})
			.bind( "blur.autocomplete", function( event ) {
				if ( self.options.disabled ) {
					return;
				}

				clearTimeout( self.searching );
				// clicks on the menu (or a button to trigger a search) will cause a blur event
				self.closing = setTimeout(function() {
					self.close( event );
					self._change( event );
				}, 150 );
			});
		this._initSource();
		this.response = function() {
			return self._response.apply( self, arguments );
		};
		this.menu = $( "<ul></ul>" )
			.addClass( "ui-autocomplete" )
			.appendTo( $( this.options.appendTo || "body", doc )[0] )
			// prevent the close-on-blur in case of a "slow" click on the menu (long mousedown)
			.mousedown(function( event ) {
				// clicking on the scrollbar causes focus to shift to the body
				// but we can't detect a mouseup or a click immediately afterward
				// so we have to track the next mousedown and close the menu if
				// the user clicks somewhere outside of the autocomplete
				var menuElement = self.menu.element[ 0 ];
				if ( !$( event.target ).closest( ".ui-menu-item" ).length ) {
					setTimeout(function() {
						$( document ).one( 'mousedown', function( event ) {
							if ( event.target !== self.element[ 0 ] &&
								event.target !== menuElement &&
								!$.ui.contains( menuElement, event.target ) ) {
								self.close();
							}
						});
					}, 1 );
				}

				// use another timeout to make sure the blur-event-handler on the input was already triggered
				setTimeout(function() {
					clearTimeout( self.closing );
				}, 13);
			})
			.menu({
				focus: function( event, ui ) {
					var item = ui.item.data( "item.autocomplete" );
					if ( false !== self._trigger( "focus", event, { item: item } ) ) {
						// use value to match what will end up in the input, if it was a key event
						if ( /^key/.test(event.originalEvent.type) ) {
							self.element.val( item.value );
						}
					}
				},
				selected: function( event, ui ) {
					var item = ui.item.data( "item.autocomplete" ),
						previous = self.previous;

					// only trigger when focus was lost (click on menu)
					if ( self.element[0] !== doc.activeElement ) {
						self.element.focus();
						self.previous = previous;
						// #6109 - IE triggers two focus events and the second
						// is asynchronous, so we need to reset the previous
						// term synchronously and asynchronously :-(
						setTimeout(function() {
							self.previous = previous;
							self.selectedItem = item;
						}, 1);
					}

					if ( false !== self._trigger( "select", event, { item: item } ) ) {
						self.element.val( item.value );
					}
					// reset the term after the select event
					// this allows custom select handling to work properly
					self.term = self.element.val();

					self.close( event );
					self.selectedItem = item;
				},
				blur: function( event, ui ) {
					// don't set the value of the text field if it's already correct
					// this prevents moving the cursor unnecessarily
					if ( self.menu.element.is(":visible") &&
						( self.element.val() !== self.term ) ) {
						self.element.val( self.term );
					}
				}
			})
			.zIndex( this.element.zIndex() + 1 )
			// workaround for jQuery bug #5781 http://dev.jquery.com/ticket/5781
			.css({ top: 0, left: 0 })
			.hide()
			.data( "menu" );
		if ( $.fn.bgiframe ) {
			 this.menu.element.bgiframe();
		}
	},

	destroy: function() {
		this.element
			.removeClass( "ui-autocomplete-input" )
			.removeAttr( "autocomplete" )
			.removeAttr( "role" )
			.removeAttr( "aria-autocomplete" )
			.removeAttr( "aria-haspopup" );
		this.menu.element.remove();
		$.Widget.prototype.destroy.call( this );
	},

	_setOption: function( key, value ) {
		$.Widget.prototype._setOption.apply( this, arguments );
		if ( key === "source" ) {
			this._initSource();
		}
		if ( key === "appendTo" ) {
			this.menu.element.appendTo( $( value || "body", this.element[0].ownerDocument )[0] )
		}
		if ( key === "disabled" && value && this.xhr ) {
			this.xhr.abort();
		}
	},

	_initSource: function() {
		var self = this,
			array,
			url;
		if ( $.isArray(this.options.source) ) {
			array = this.options.source;
			this.source = function( request, response ) {
				response( $.ui.autocomplete.filter(array, request.term) );
			};
		} else if ( typeof this.options.source === "string" ) {
			url = this.options.source;
			this.source = function( request, response ) {
				if ( self.xhr ) {
					self.xhr.abort();
				}
				self.xhr = $.ajax({
					url: url,
					data: request,
					dataType: "json",
					autocompleteRequest: ++requestIndex,
					success: function( data, status ) {
						if ( this.autocompleteRequest === requestIndex ) {
							response( data );
						}
					},
					error: function() {
						if ( this.autocompleteRequest === requestIndex ) {
							response( [] );
						}
					}
				});
			};
		} else {
			this.source = this.options.source;
		}
	},

	search: function( value, event ) {
		value = value != null ? value : this.element.val();

		// always save the actual value, not the one passed as an argument
		this.term = this.element.val();

		if ( value.length < this.options.minLength ) {
			return this.close( event );
		}

		clearTimeout( this.closing );
		if ( this._trigger( "search", event ) === false ) {
			return;
		}

		return this._search( value );
	},

	_search: function( value ) {
		this.pending++;
		this.element.addClass( "ui-autocomplete-loading" );

		this.source( { term: value }, this.response );
	},

	_response: function( content ) {
		if ( !this.options.disabled && content && content.length ) {
			content = this._normalize( content );
			this._suggest( content );
			this._trigger( "open" );
		} else {
			this.close();
		}
		this.pending--;
		if ( !this.pending ) {
			this.element.removeClass( "ui-autocomplete-loading" );
		}
	},

	close: function( event ) {
		clearTimeout( this.closing );
		if ( this.menu.element.is(":visible") ) {
			this.menu.element.hide();
			this.menu.deactivate();
			this._trigger( "close", event );
		}
	},
	
	_change: function( event ) {
		if ( this.previous !== this.element.val() ) {
			this._trigger( "change", event, { item: this.selectedItem } );
		}
	},

	_normalize: function( items ) {
		// assume all items have the right format when the first item is complete
		if ( items.length && items[0].label && items[0].value ) {
			return items;
		}
		return $.map( items, function(item) {
			if ( typeof item === "string" ) {
				return {
					label: item,
					value: item
				};
			}
			return $.extend({
				label: item.label || item.value,
				value: item.value || item.label
			}, item );
		});
	},

	_suggest: function( items ) {
		var ul = this.menu.element
			.empty()
			.zIndex( this.element.zIndex() + 1 );
		this._renderMenu( ul, items );
		// TODO refresh should check if the active item is still in the dom, removing the need for a manual deactivate
		this.menu.deactivate();
		this.menu.refresh();

		// size and position menu
		ul.show();
		this._resizeMenu();
		ul.position( $.extend({
			of: this.element
		}, this.options.position ));

		if ( this.options.autoFocus ) {
			this.menu.next( new $.Event("mouseover") );
		}
	},

	_resizeMenu: function() {
		var ul = this.menu.element;
		ul.outerWidth( Math.max(
			ul.width( "" ).outerWidth(),
			this.element.outerWidth()
		) );
	},

	_renderMenu: function( ul, items ) {
		var self = this;
		$.each( items, function( index, item ) {
			self._renderItem( ul, item );
		});
	},

	_renderItem: function( ul, item) {
		return $( "<li></li>" )
			.data( "item.autocomplete", item )
			.append( $( "<a></a>" ).text( item.label ) )
			.appendTo( ul );
	},

	_move: function( direction, event ) {
		if ( !this.menu.element.is(":visible") ) {
			this.search( null, event );
			return;
		}
		if ( this.menu.first() && /^previous/.test(direction) ||
				this.menu.last() && /^next/.test(direction) ) {
			this.element.val( this.term );
			this.menu.deactivate();
			return;
		}
		this.menu[ direction ]( event );
	},

	widget: function() {
		return this.menu.element;
	}
});

$.extend( $.ui.autocomplete, {
	escapeRegex: function( value ) {
		return value.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&");
	},
	filter: function(array, term) {
		var matcher = new RegExp( $.ui.autocomplete.escapeRegex(term), "i" );
		return $.grep( array, function(value) {
			return matcher.test( value.label || value.value || value );
		});
	}
});

}( jQuery ));

/*
 * jQuery UI Menu (not officially released)
 * 
 * This widget isn't yet finished and the API is subject to change. We plan to finish
 * it for the next release. You're welcome to give it a try anyway and give us feedback,
 * as long as you're okay with migrating your code later on. We can help with that, too.
 *
 * Copyright 2010, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Menu
 *
 * Depends:
 *	jquery.ui.core.js
 *  jquery.ui.widget.js
 */
(function($) {

$.widget("ui.menu", {
	_create: function() {
		var self = this;
		this.element
			.addClass("ui-menu ui-widget ui-widget-content ui-corner-all")
			.attr({
				role: "listbox",
				"aria-activedescendant": "ui-active-menuitem"
			})
			.click(function( event ) {
				if ( !$( event.target ).closest( ".ui-menu-item a" ).length ) {
					return;
				}
				// temporary
				event.preventDefault();
				self.select( event );
			});
		this.refresh();
	},
	
	refresh: function() {
		var self = this;

		// don't refresh list items that are already adapted
		var items = this.element.children("li:not(.ui-menu-item):has(a)")
			.addClass("ui-menu-item")
			.attr("role", "menuitem");
		
		items.children("a")
			.addClass("ui-corner-all")
			.attr("tabindex", -1)
			// mouseenter doesn't work with event delegation
			.mouseenter(function( event ) {
				self.activate( event, $(this).parent() );
			})
			.mouseleave(function() {
				self.deactivate();
			});
	},

	activate: function( event, item ) {
		this.deactivate();
		if (this.hasScroll()) {
			var offset = item.offset().top - this.element.offset().top,
				scroll = this.element.scrollTop(),
				elementHeight = this.element.height();
			if (offset < 0) {
				this.element.scrollTop( scroll + offset);
			} else if (offset >= elementHeight) {
				this.element.scrollTop( scroll + offset - elementHeight + item.height());
			}
		}
		this.active = item.eq(0)
			.children("a")
				.addClass("ui-state-hover")
				.attr("id", "ui-active-menuitem")
			.end();
		this._trigger("focus", event, { item: item });
	},

	deactivate: function() {
		if (!this.active) { return; }

		this.active.children("a")
			.removeClass("ui-state-hover")
			.removeAttr("id");
		this._trigger("blur");
		this.active = null;
	},

	next: function(event) {
		this.move("next", ".ui-menu-item:first", event);
	},

	previous: function(event) {
		this.move("prev", ".ui-menu-item:last", event);
	},

	first: function() {
		return this.active && !this.active.prevAll(".ui-menu-item").length;
	},

	last: function() {
		return this.active && !this.active.nextAll(".ui-menu-item").length;
	},

	move: function(direction, edge, event) {
		if (!this.active) {
			this.activate(event, this.element.children(edge));
			return;
		}
		var next = this.active[direction + "All"](".ui-menu-item").eq(0);
		if (next.length) {
			this.activate(event, next);
		} else {
			this.activate(event, this.element.children(edge));
		}
	},

	// TODO merge with previousPage
	nextPage: function(event) {
		if (this.hasScroll()) {
			// TODO merge with no-scroll-else
			if (!this.active || this.last()) {
				this.activate(event, this.element.children(".ui-menu-item:first"));
				return;
			}
			var base = this.active.offset().top,
				height = this.element.height(),
				result = this.element.children(".ui-menu-item").filter(function() {
					var close = $(this).offset().top - base - height + $(this).height();
					// TODO improve approximation
					return close < 10 && close > -10;
				});

			// TODO try to catch this earlier when scrollTop indicates the last page anyway
			if (!result.length) {
				result = this.element.children(".ui-menu-item:last");
			}
			this.activate(event, result);
		} else {
			this.activate(event, this.element.children(".ui-menu-item")
				.filter(!this.active || this.last() ? ":first" : ":last"));
		}
	},

	// TODO merge with nextPage
	previousPage: function(event) {
		if (this.hasScroll()) {
			// TODO merge with no-scroll-else
			if (!this.active || this.first()) {
				this.activate(event, this.element.children(".ui-menu-item:last"));
				return;
			}

			var base = this.active.offset().top,
				height = this.element.height();
				result = this.element.children(".ui-menu-item").filter(function() {
					var close = $(this).offset().top - base + height - $(this).height();
					// TODO improve approximation
					return close < 10 && close > -10;
				});

			// TODO try to catch this earlier when scrollTop indicates the last page anyway
			if (!result.length) {
				result = this.element.children(".ui-menu-item:first");
			}
			this.activate(event, result);
		} else {
			this.activate(event, this.element.children(".ui-menu-item")
				.filter(!this.active || this.first() ? ":last" : ":first"));
		}
	},

	hasScroll: function() {
		return this.element.height() < this.element[ $.fn.prop ? "prop" : "attr" ]("scrollHeight");
	},

	select: function( event ) {
		this._trigger("selected", event, { item: this.active });
	}
});

}(jQuery));
/*
 * jQuery UI Button 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Button
 *
 * Depends:
 *	jquery.ui.core.js
 *	jquery.ui.widget.js
 */
(function( $, undefined ) {

var lastActive, startXPos, startYPos, clickDragged,
	baseClasses = "ui-button ui-widget ui-state-default ui-corner-all",
	stateClasses = "ui-state-hover ui-state-active ",
	typeClasses = "ui-button-icons-only ui-button-icon-only ui-button-text-icons ui-button-text-icon-primary ui-button-text-icon-secondary ui-button-text-only",
	formResetHandler = function() {
		var buttons = $( this ).find( ":ui-button" );
		setTimeout(function() {
			buttons.button( "refresh" );
		}, 1 );
	},
	radioGroup = function( radio ) {
		var name = radio.name,
			form = radio.form,
			radios = $( [] );
		if ( name ) {
			if ( form ) {
				radios = $( form ).find( "[name='" + name + "']" );
			} else {
				radios = $( "[name='" + name + "']", radio.ownerDocument )
					.filter(function() {
						return !this.form;
					});
			}
		}
		return radios;
	};

$.widget( "ui.button", {
	options: {
		disabled: null,
		text: true,
		label: null,
		icons: {
			primary: null,
			secondary: null
		}
	},
	_create: function() {
		this.element.closest( "form" )
			.unbind( "reset.button" )
			.bind( "reset.button", formResetHandler );

		if ( typeof this.options.disabled !== "boolean" ) {
			this.options.disabled = this.element.attr( "disabled" );
		}

		this._determineButtonType();
		this.hasTitle = !!this.buttonElement.attr( "title" );

		var self = this,
			options = this.options,
			toggleButton = this.type === "checkbox" || this.type === "radio",
			hoverClass = "ui-state-hover" + ( !toggleButton ? " ui-state-active" : "" ),
			focusClass = "ui-state-focus";

		if ( options.label === null ) {
			options.label = this.buttonElement.html();
		}

		if ( this.element.is( ":disabled" ) ) {
			options.disabled = true;
		}

		this.buttonElement
			.addClass( baseClasses )
			.attr( "role", "button" )
			.bind( "mouseenter.button", function() {
				if ( options.disabled ) {
					return;
				}
				$( this ).addClass( "ui-state-hover" );
				if ( this === lastActive ) {
					$( this ).addClass( "ui-state-active" );
				}
			})
			.bind( "mouseleave.button", function() {
				if ( options.disabled ) {
					return;
				}
				$( this ).removeClass( hoverClass );
			})
			.bind( "click.button", function( event ) {
				if ( options.disabled ) {
					event.preventDefault();
					event.stopImmediatePropagation();
				}
			});

		this.element
			.bind( "focus.button", function() {
				// no need to check disabled, focus won't be triggered anyway
				self.buttonElement.addClass( focusClass );
			})
			.bind( "blur.button", function() {
				self.buttonElement.removeClass( focusClass );
			});

		if ( toggleButton ) {
			this.element.bind( "change.button", function() {
				if ( clickDragged ) {
					return;
				}
				self.refresh();
			});
			// if mouse moves between mousedown and mouseup (drag) set clickDragged flag
			// prevents issue where button state changes but checkbox/radio checked state
			// does not in Firefox (see ticket #6970)
			this.buttonElement
				.bind( "mousedown.button", function( event ) {
					if ( options.disabled ) {
						return;
					}
					clickDragged = false;
					startXPos = event.pageX;
					startYPos = event.pageY;
				})
				.bind( "mouseup.button", function( event ) {
					if ( options.disabled ) {
						return;
					}
					if ( startXPos !== event.pageX || startYPos !== event.pageY ) {
						clickDragged = true;
					}
			});
		}

		if ( this.type === "checkbox" ) {
			this.buttonElement.bind( "click.button", function() {
				if ( options.disabled || clickDragged ) {
					return false;
				}
				$( this ).toggleClass( "ui-state-active" );
				self.buttonElement.attr( "aria-pressed", self.element[0].checked );
			});
		} else if ( this.type === "radio" ) {
			this.buttonElement.bind( "click.button", function() {
				if ( options.disabled || clickDragged ) {
					return false;
				}
				$( this ).addClass( "ui-state-active" );
				self.buttonElement.attr( "aria-pressed", true );

				var radio = self.element[ 0 ];
				radioGroup( radio )
					.not( radio )
					.map(function() {
						return $( this ).button( "widget" )[ 0 ];
					})
					.removeClass( "ui-state-active" )
					.attr( "aria-pressed", false );
			});
		} else {
			this.buttonElement
				.bind( "mousedown.button", function() {
					if ( options.disabled ) {
						return false;
					}
					$( this ).addClass( "ui-state-active" );
					lastActive = this;
					$( document ).one( "mouseup", function() {
						lastActive = null;
					});
				})
				.bind( "mouseup.button", function() {
					if ( options.disabled ) {
						return false;
					}
					$( this ).removeClass( "ui-state-active" );
				})
				.bind( "keydown.button", function(event) {
					if ( options.disabled ) {
						return false;
					}
					if ( event.keyCode == $.ui.keyCode.SPACE || event.keyCode == $.ui.keyCode.ENTER ) {
						$( this ).addClass( "ui-state-active" );
					}
				})
				.bind( "keyup.button", function() {
					$( this ).removeClass( "ui-state-active" );
				});

			if ( this.buttonElement.is("a") ) {
				this.buttonElement.keyup(function(event) {
					if ( event.keyCode === $.ui.keyCode.SPACE ) {
						// TODO pass through original event correctly (just as 2nd argument doesn't work)
						$( this ).click();
					}
				});
			}
		}

		// TODO: pull out $.Widget's handling for the disabled option into
		// $.Widget.prototype._setOptionDisabled so it's easy to proxy and can
		// be overridden by individual plugins
		this._setOption( "disabled", options.disabled );
		this._resetButton();
	},

	_determineButtonType: function() {

		if ( this.element.is(":checkbox") ) {
			this.type = "checkbox";
		} else if ( this.element.is(":radio") ) {
			this.type = "radio";
		} else if ( this.element.is("input") ) {
			this.type = "input";
		} else {
			this.type = "button";
		}

		if ( this.type === "checkbox" || this.type === "radio" ) {
			// we don't search against the document in case the element
			// is disconnected from the DOM
			var ancestor = this.element.parents().filter(":last"),
				labelSelector = "label[for=" + this.element.attr("id") + "]";
			this.buttonElement = ancestor.find( labelSelector );
			if ( !this.buttonElement.length ) {
				ancestor = ancestor.length ? ancestor.siblings() : this.element.siblings();
				this.buttonElement = ancestor.filter( labelSelector );
				if ( !this.buttonElement.length ) {
					this.buttonElement = ancestor.find( labelSelector );
				}
			}
			this.element.addClass( "ui-helper-hidden-accessible" );

			var checked = this.element.is( ":checked" );
			if ( checked ) {
				this.buttonElement.addClass( "ui-state-active" );
			}
			this.buttonElement.attr( "aria-pressed", checked );
		} else {
			this.buttonElement = this.element;
		}
	},

	widget: function() {
		return this.buttonElement;
	},

	destroy: function() {
		this.element
			.removeClass( "ui-helper-hidden-accessible" );
		this.buttonElement
			.removeClass( baseClasses + " " + stateClasses + " " + typeClasses )
			.removeAttr( "role" )
			.removeAttr( "aria-pressed" )
			.html( this.buttonElement.find(".ui-button-text").html() );

		if ( !this.hasTitle ) {
			this.buttonElement.removeAttr( "title" );
		}

		$.Widget.prototype.destroy.call( this );
	},

	_setOption: function( key, value ) {
		$.Widget.prototype._setOption.apply( this, arguments );
		if ( key === "disabled" ) {
			if ( value ) {
				this.element.attr( "disabled", true );
			} else {
				this.element.removeAttr( "disabled" );
			}
			return;
		}
		this._resetButton();
	},

	refresh: function() {
		var isDisabled = this.element.is( ":disabled" );
		if ( isDisabled !== this.options.disabled ) {
			this._setOption( "disabled", isDisabled );
		}
		if ( this.type === "radio" ) {
			radioGroup( this.element[0] ).each(function() {
				if ( $( this ).is( ":checked" ) ) {
					$( this ).button( "widget" )
						.addClass( "ui-state-active" )
						.attr( "aria-pressed", true );
				} else {
					$( this ).button( "widget" )
						.removeClass( "ui-state-active" )
						.attr( "aria-pressed", false );
				}
			});
		} else if ( this.type === "checkbox" ) {
			if ( this.element.is( ":checked" ) ) {
				this.buttonElement
					.addClass( "ui-state-active" )
					.attr( "aria-pressed", true );
			} else {
				this.buttonElement
					.removeClass( "ui-state-active" )
					.attr( "aria-pressed", false );
			}
		}
	},

	_resetButton: function() {
		if ( this.type === "input" ) {
			if ( this.options.label ) {
				this.element.val( this.options.label );
			}
			return;
		}
		var buttonElement = this.buttonElement.removeClass( typeClasses ),
			buttonText = $( "<span></span>" )
				.addClass( "ui-button-text" )
				.html( this.options.label )
				.appendTo( buttonElement.empty() )
				.text(),
			icons = this.options.icons,
			multipleIcons = icons.primary && icons.secondary,
			buttonClasses = [];  

		if ( icons.primary || icons.secondary ) {
			if ( this.options.text ) {
				buttonClasses.push( "ui-button-text-icon" + ( multipleIcons ? "s" : ( icons.primary ? "-primary" : "-secondary" ) ) );
			}

			if ( icons.primary ) {
				buttonElement.prepend( "<span class='ui-button-icon-primary ui-icon " + icons.primary + "'></span>" );
			}

			if ( icons.secondary ) {
				buttonElement.append( "<span class='ui-button-icon-secondary ui-icon " + icons.secondary + "'></span>" );
			}

			if ( !this.options.text ) {
				buttonClasses.push( multipleIcons ? "ui-button-icons-only" : "ui-button-icon-only" );

				if ( !this.hasTitle ) {
					buttonElement.attr( "title", buttonText );
				}
			}
		} else {
			buttonClasses.push( "ui-button-text-only" );
		}
		buttonElement.addClass( buttonClasses.join( " " ) );
	}
});

$.widget( "ui.buttonset", {
	options: {
		items: ":button, :submit, :reset, :checkbox, :radio, a, :data(button)"
	},

	_create: function() {
		this.element.addClass( "ui-buttonset" );
	},
	
	_init: function() {
		this.refresh();
	},

	_setOption: function( key, value ) {
		if ( key === "disabled" ) {
			this.buttons.button( "option", key, value );
		}

		$.Widget.prototype._setOption.apply( this, arguments );
	},
	
	refresh: function() {
		var ltr = this.element.css( "direction" ) === "ltr";
		
		this.buttons = this.element.find( this.options.items )
			.filter( ":ui-button" )
				.button( "refresh" )
			.end()
			.not( ":ui-button" )
				.button()
			.end()
			.map(function() {
				return $( this ).button( "widget" )[ 0 ];
			})
				.removeClass( "ui-corner-all ui-corner-left ui-corner-right" )
				.filter( ":first" )
					.addClass( ltr ? "ui-corner-left" : "ui-corner-right" )
				.end()
				.filter( ":last" )
					.addClass( ltr ? "ui-corner-right" : "ui-corner-left" )
				.end()
			.end();
	},

	destroy: function() {
		this.element.removeClass( "ui-buttonset" );
		this.buttons
			.map(function() {
				return $( this ).button( "widget" )[ 0 ];
			})
				.removeClass( "ui-corner-left ui-corner-right" )
			.end()
			.button( "destroy" );

		$.Widget.prototype.destroy.call( this );
	}
});

}( jQuery ) );
/*
 * jQuery UI Datepicker 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Datepicker
 *
 * Depends:
 *	jquery.ui.core.js
 */
(function( $, undefined ) {

$.extend($.ui, { datepicker: { version: "1.8.14" } });

var PROP_NAME = 'datepicker';
var dpuuid = new Date().getTime();
var instActive;

/* Date picker manager.
   Use the singleton instance of this class, $.datepicker, to interact with the date picker.
   Settings for (groups of) date pickers are maintained in an instance object,
   allowing multiple different settings on the same page. */

function Datepicker() {
	this.debug = false; // Change this to true to start debugging
	this._curInst = null; // The current instance in use
	this._keyEvent = false; // If the last event was a key event
	this._disabledInputs = []; // List of date picker inputs that have been disabled
	this._datepickerShowing = false; // True if the popup picker is showing , false if not
	this._inDialog = false; // True if showing within a "dialog", false if not
	this._mainDivId = 'ui-datepicker-div'; // The ID of the main datepicker division
	this._inlineClass = 'ui-datepicker-inline'; // The name of the inline marker class
	this._appendClass = 'ui-datepicker-append'; // The name of the append marker class
	this._triggerClass = 'ui-datepicker-trigger'; // The name of the trigger marker class
	this._dialogClass = 'ui-datepicker-dialog'; // The name of the dialog marker class
	this._disableClass = 'ui-datepicker-disabled'; // The name of the disabled covering marker class
	this._unselectableClass = 'ui-datepicker-unselectable'; // The name of the unselectable cell marker class
	this._currentClass = 'ui-datepicker-current-day'; // The name of the current day marker class
	this._dayOverClass = 'ui-datepicker-days-cell-over'; // The name of the day hover marker class
	this.regional = []; // Available regional settings, indexed by language code
	this.regional[''] = { // Default regional settings
		closeText: 'Done', // Display text for close link
		prevText: 'Prev', // Display text for previous month link
		nextText: 'Next', // Display text for next month link
		currentText: 'Today', // Display text for current month link
		monthNames: ['January','February','March','April','May','June',
			'July','August','September','October','November','December'], // Names of months for drop-down and formatting
		monthNamesShort: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'], // For formatting
		dayNames: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'], // For formatting
		dayNamesShort: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'], // For formatting
		dayNamesMin: ['Su','Mo','Tu','We','Th','Fr','Sa'], // Column headings for days starting at Sunday
		weekHeader: 'Wk', // Column header for week of the year
		dateFormat: 'mm/dd/yy', // See format options on parseDate
		firstDay: 0, // The first day of the week, Sun = 0, Mon = 1, ...
		isRTL: false, // True if right-to-left language, false if left-to-right
		showMonthAfterYear: false, // True if the year select precedes month, false for month then year
		yearSuffix: '' // Additional text to append to the year in the month headers
	};
	this._defaults = { // Global defaults for all the date picker instances
		showOn: 'focus', // 'focus' for popup on focus,
			// 'button' for trigger button, or 'both' for either
		showAnim: 'fadeIn', // Name of jQuery animation for popup
		showOptions: {}, // Options for enhanced animations
		defaultDate: null, // Used when field is blank: actual date,
			// +/-number for offset from today, null for today
		appendText: '', // Display text following the input box, e.g. showing the format
		buttonText: '...', // Text for trigger button
		buttonImage: '', // URL for trigger button image
		buttonImageOnly: false, // True if the image appears alone, false if it appears on a button
		hideIfNoPrevNext: false, // True to hide next/previous month links
			// if not applicable, false to just disable them
		navigationAsDateFormat: false, // True if date formatting applied to prev/today/next links
		gotoCurrent: false, // True if today link goes back to current selection instead
		changeMonth: false, // True if month can be selected directly, false if only prev/next
		changeYear: false, // True if year can be selected directly, false if only prev/next
		yearRange: 'c-10:c+10', // Range of years to display in drop-down,
			// either relative to today's year (-nn:+nn), relative to currently displayed year
			// (c-nn:c+nn), absolute (nnnn:nnnn), or a combination of the above (nnnn:-n)
		showOtherMonths: false, // True to show dates in other months, false to leave blank
		selectOtherMonths: false, // True to allow selection of dates in other months, false for unselectable
		showWeek: false, // True to show week of the year, false to not show it
		calculateWeek: this.iso8601Week, // How to calculate the week of the year,
			// takes a Date and returns the number of the week for it
		shortYearCutoff: '+10', // Short year values < this are in the current century,
			// > this are in the previous century,
			// string value starting with '+' for current year + value
		minDate: null, // The earliest selectable date, or null for no limit
		maxDate: null, // The latest selectable date, or null for no limit
		duration: 'fast', // Duration of display/closure
		beforeShowDay: null, // Function that takes a date and returns an array with
			// [0] = true if selectable, false if not, [1] = custom CSS class name(s) or '',
			// [2] = cell title (optional), e.g. $.datepicker.noWeekends
		beforeShow: null, // Function that takes an input field and
			// returns a set of custom settings for the date picker
		onSelect: null, // Define a callback function when a date is selected
		onChangeMonthYear: null, // Define a callback function when the month or year is changed
		onClose: null, // Define a callback function when the datepicker is closed
		numberOfMonths: 1, // Number of months to show at a time
		showCurrentAtPos: 0, // The position in multipe months at which to show the current month (starting at 0)
		stepMonths: 1, // Number of months to step back/forward
		stepBigMonths: 12, // Number of months to step back/forward for the big links
		altField: '', // Selector for an alternate field to store selected dates into
		altFormat: '', // The date format to use for the alternate field
		constrainInput: true, // The input is constrained by the current date format
		showButtonPanel: false, // True to show button panel, false to not show it
		autoSize: false // True to size the input for the date format, false to leave as is
	};
	$.extend(this._defaults, this.regional['']);
	this.dpDiv = bindHover($('<div id="' + this._mainDivId + '" class="ui-datepicker ui-widget ui-widget-content ui-helper-clearfix ui-corner-all"></div>'));
}

$.extend(Datepicker.prototype, {
	/* Class name added to elements to indicate already configured with a date picker. */
	markerClassName: 'hasDatepicker',
	
	//Keep track of the maximum number of rows displayed (see #7043)
	maxRows: 4,

	/* Debug logging (if enabled). */
	log: function () {
		if (this.debug)
			console.log.apply('', arguments);
	},
	
	// TODO rename to "widget" when switching to widget factory
	_widgetDatepicker: function() {
		return this.dpDiv;
	},

	/* Override the default settings for all instances of the date picker.
	   @param  settings  object - the new settings to use as defaults (anonymous object)
	   @return the manager object */
	setDefaults: function(settings) {
		extendRemove(this._defaults, settings || {});
		return this;
	},

	/* Attach the date picker to a jQuery selection.
	   @param  target    element - the target input field or division or span
	   @param  settings  object - the new settings to use for this date picker instance (anonymous) */
	_attachDatepicker: function(target, settings) {
		// check for settings on the control itself - in namespace 'date:'
		var inlineSettings = null;
		for (var attrName in this._defaults) {
			var attrValue = target.getAttribute('date:' + attrName);
			if (attrValue) {
				inlineSettings = inlineSettings || {};
				try {
					inlineSettings[attrName] = eval(attrValue);
				} catch (err) {
					inlineSettings[attrName] = attrValue;
				}
			}
		}
		var nodeName = target.nodeName.toLowerCase();
		var inline = (nodeName == 'div' || nodeName == 'span');
		if (!target.id) {
			this.uuid += 1;
			target.id = 'dp' + this.uuid;
		}
		var inst = this._newInst($(target), inline);
		inst.settings = $.extend({}, settings || {}, inlineSettings || {});
		if (nodeName == 'input') {
			this._connectDatepicker(target, inst);
		} else if (inline) {
			this._inlineDatepicker(target, inst);
		}
	},

	/* Create a new instance object. */
	_newInst: function(target, inline) {
		var id = target[0].id.replace(/([^A-Za-z0-9_-])/g, '\\\\$1'); // escape jQuery meta chars
		return {id: id, input: target, // associated target
			selectedDay: 0, selectedMonth: 0, selectedYear: 0, // current selection
			drawMonth: 0, drawYear: 0, // month being drawn
			inline: inline, // is datepicker inline or not
			dpDiv: (!inline ? this.dpDiv : // presentation div
			bindHover($('<div class="' + this._inlineClass + ' ui-datepicker ui-widget ui-widget-content ui-helper-clearfix ui-corner-all"></div>')))};
	},

	/* Attach the date picker to an input field. */
	_connectDatepicker: function(target, inst) {
		var input = $(target);
		inst.append = $([]);
		inst.trigger = $([]);
		if (input.hasClass(this.markerClassName))
			return;
		this._attachments(input, inst);
		input.addClass(this.markerClassName).keydown(this._doKeyDown).
			keypress(this._doKeyPress).keyup(this._doKeyUp).
			bind("setData.datepicker", function(event, key, value) {
				inst.settings[key] = value;
			}).bind("getData.datepicker", function(event, key) {
				return this._get(inst, key);
			});
		this._autoSize(inst);
		$.data(target, PROP_NAME, inst);
	},

	/* Make attachments based on settings. */
	_attachments: function(input, inst) {
		var appendText = this._get(inst, 'appendText');
		var isRTL = this._get(inst, 'isRTL');
		if (inst.append)
			inst.append.remove();
		if (appendText) {
			inst.append = $('<span class="' + this._appendClass + '">' + appendText + '</span>');
			input[isRTL ? 'before' : 'after'](inst.append);
		}
		input.unbind('focus', this._showDatepicker);
		if (inst.trigger)
			inst.trigger.remove();
		var showOn = this._get(inst, 'showOn');
		if (showOn == 'focus' || showOn == 'both') // pop-up date picker when in the marked field
			input.focus(this._showDatepicker);
		if (showOn == 'button' || showOn == 'both') { // pop-up date picker when button clicked
			var buttonText = this._get(inst, 'buttonText');
			var buttonImage = this._get(inst, 'buttonImage');
			inst.trigger = $(this._get(inst, 'buttonImageOnly') ?
				$('<img/>').addClass(this._triggerClass).
					attr({ src: buttonImage, alt: buttonText, title: buttonText }) :
				$('<button type="button"></button>').addClass(this._triggerClass).
					html(buttonImage == '' ? buttonText : $('<img/>').attr(
					{ src:buttonImage, alt:buttonText, title:buttonText })));
			input[isRTL ? 'before' : 'after'](inst.trigger);
			inst.trigger.click(function() {
				if ($.datepicker._datepickerShowing && $.datepicker._lastInput == input[0])
					$.datepicker._hideDatepicker();
				else
					$.datepicker._showDatepicker(input[0]);
				return false;
			});
		}
	},

	/* Apply the maximum length for the date format. */
	_autoSize: function(inst) {
		if (this._get(inst, 'autoSize') && !inst.inline) {
			var date = new Date(2009, 12 - 1, 20); // Ensure double digits
			var dateFormat = this._get(inst, 'dateFormat');
			if (dateFormat.match(/[DM]/)) {
				var findMax = function(names) {
					var max = 0;
					var maxI = 0;
					for (var i = 0; i < names.length; i++) {
						if (names[i].length > max) {
							max = names[i].length;
							maxI = i;
						}
					}
					return maxI;
				};
				date.setMonth(findMax(this._get(inst, (dateFormat.match(/MM/) ?
					'monthNames' : 'monthNamesShort'))));
				date.setDate(findMax(this._get(inst, (dateFormat.match(/DD/) ?
					'dayNames' : 'dayNamesShort'))) + 20 - date.getDay());
			}
			inst.input.attr('size', this._formatDate(inst, date).length);
		}
	},

	/* Attach an inline date picker to a div. */
	_inlineDatepicker: function(target, inst) {
		var divSpan = $(target);
		if (divSpan.hasClass(this.markerClassName))
			return;
		divSpan.addClass(this.markerClassName).append(inst.dpDiv).
			bind("setData.datepicker", function(event, key, value){
				inst.settings[key] = value;
			}).bind("getData.datepicker", function(event, key){
				return this._get(inst, key);
			});
		$.data(target, PROP_NAME, inst);
		this._setDate(inst, this._getDefaultDate(inst), true);
		this._updateDatepicker(inst);
		this._updateAlternate(inst);
		inst.dpDiv.show();
	},

	/* Pop-up the date picker in a "dialog" box.
	   @param  input     element - ignored
	   @param  date      string or Date - the initial date to display
	   @param  onSelect  function - the function to call when a date is selected
	   @param  settings  object - update the dialog date picker instance's settings (anonymous object)
	   @param  pos       int[2] - coordinates for the dialog's position within the screen or
	                     event - with x/y coordinates or
	                     leave empty for default (screen centre)
	   @return the manager object */
	_dialogDatepicker: function(input, date, onSelect, settings, pos) {
		var inst = this._dialogInst; // internal instance
		if (!inst) {
			this.uuid += 1;
			var id = 'dp' + this.uuid;
			this._dialogInput = $('<input type="text" id="' + id +
				'" style="position: absolute; top: -100px; width: 0px; z-index: -10;"/>');
			this._dialogInput.keydown(this._doKeyDown);
			$('body').append(this._dialogInput);
			inst = this._dialogInst = this._newInst(this._dialogInput, false);
			inst.settings = {};
			$.data(this._dialogInput[0], PROP_NAME, inst);
		}
		extendRemove(inst.settings, settings || {});
		date = (date && date.constructor == Date ? this._formatDate(inst, date) : date);
		this._dialogInput.val(date);

		this._pos = (pos ? (pos.length ? pos : [pos.pageX, pos.pageY]) : null);
		if (!this._pos) {
			var browserWidth = document.documentElement.clientWidth;
			var browserHeight = document.documentElement.clientHeight;
			var scrollX = document.documentElement.scrollLeft || document.body.scrollLeft;
			var scrollY = document.documentElement.scrollTop || document.body.scrollTop;
			this._pos = // should use actual width/height below
				[(browserWidth / 2) - 100 + scrollX, (browserHeight / 2) - 150 + scrollY];
		}

		// move input on screen for focus, but hidden behind dialog
		this._dialogInput.css('left', (this._pos[0] + 20) + 'px').css('top', this._pos[1] + 'px');
		inst.settings.onSelect = onSelect;
		this._inDialog = true;
		this.dpDiv.addClass(this._dialogClass);
		this._showDatepicker(this._dialogInput[0]);
		if ($.blockUI)
			$.blockUI(this.dpDiv);
		$.data(this._dialogInput[0], PROP_NAME, inst);
		return this;
	},

	/* Detach a datepicker from its control.
	   @param  target    element - the target input field or division or span */
	_destroyDatepicker: function(target) {
		var $target = $(target);
		var inst = $.data(target, PROP_NAME);
		if (!$target.hasClass(this.markerClassName)) {
			return;
		}
		var nodeName = target.nodeName.toLowerCase();
		$.removeData(target, PROP_NAME);
		if (nodeName == 'input') {
			inst.append.remove();
			inst.trigger.remove();
			$target.removeClass(this.markerClassName).
				unbind('focus', this._showDatepicker).
				unbind('keydown', this._doKeyDown).
				unbind('keypress', this._doKeyPress).
				unbind('keyup', this._doKeyUp);
		} else if (nodeName == 'div' || nodeName == 'span')
			$target.removeClass(this.markerClassName).empty();
	},

	/* Enable the date picker to a jQuery selection.
	   @param  target    element - the target input field or division or span */
	_enableDatepicker: function(target) {
		var $target = $(target);
		var inst = $.data(target, PROP_NAME);
		if (!$target.hasClass(this.markerClassName)) {
			return;
		}
		var nodeName = target.nodeName.toLowerCase();
		if (nodeName == 'input') {
			target.disabled = false;
			inst.trigger.filter('button').
				each(function() { this.disabled = false; }).end().
				filter('img').css({opacity: '1.0', cursor: ''});
		}
		else if (nodeName == 'div' || nodeName == 'span') {
			var inline = $target.children('.' + this._inlineClass);
			inline.children().removeClass('ui-state-disabled');
			inline.find("select.ui-datepicker-month, select.ui-datepicker-year").
				removeAttr("disabled");
		}
		this._disabledInputs = $.map(this._disabledInputs,
			function(value) { return (value == target ? null : value); }); // delete entry
	},

	/* Disable the date picker to a jQuery selection.
	   @param  target    element - the target input field or division or span */
	_disableDatepicker: function(target) {
		var $target = $(target);
		var inst = $.data(target, PROP_NAME);
		if (!$target.hasClass(this.markerClassName)) {
			return;
		}
		var nodeName = target.nodeName.toLowerCase();
		if (nodeName == 'input') {
			target.disabled = true;
			inst.trigger.filter('button').
				each(function() { this.disabled = true; }).end().
				filter('img').css({opacity: '0.5', cursor: 'default'});
		}
		else if (nodeName == 'div' || nodeName == 'span') {
			var inline = $target.children('.' + this._inlineClass);
			inline.children().addClass('ui-state-disabled');
			inline.find("select.ui-datepicker-month, select.ui-datepicker-year").
				attr("disabled", "disabled");
		}
		this._disabledInputs = $.map(this._disabledInputs,
			function(value) { return (value == target ? null : value); }); // delete entry
		this._disabledInputs[this._disabledInputs.length] = target;
	},

	/* Is the first field in a jQuery collection disabled as a datepicker?
	   @param  target    element - the target input field or division or span
	   @return boolean - true if disabled, false if enabled */
	_isDisabledDatepicker: function(target) {
		if (!target) {
			return false;
		}
		for (var i = 0; i < this._disabledInputs.length; i++) {
			if (this._disabledInputs[i] == target)
				return true;
		}
		return false;
	},

	/* Retrieve the instance data for the target control.
	   @param  target  element - the target input field or division or span
	   @return  object - the associated instance data
	   @throws  error if a jQuery problem getting data */
	_getInst: function(target) {
		try {
			return $.data(target, PROP_NAME);
		}
		catch (err) {
			throw 'Missing instance data for this datepicker';
		}
	},

	/* Update or retrieve the settings for a date picker attached to an input field or division.
	   @param  target  element - the target input field or division or span
	   @param  name    object - the new settings to update or
	                   string - the name of the setting to change or retrieve,
	                   when retrieving also 'all' for all instance settings or
	                   'defaults' for all global defaults
	   @param  value   any - the new value for the setting
	                   (omit if above is an object or to retrieve a value) */
	_optionDatepicker: function(target, name, value) {
		var inst = this._getInst(target);
		if (arguments.length == 2 && typeof name == 'string') {
			return (name == 'defaults' ? $.extend({}, $.datepicker._defaults) :
				(inst ? (name == 'all' ? $.extend({}, inst.settings) :
				this._get(inst, name)) : null));
		}
		var settings = name || {};
		if (typeof name == 'string') {
			settings = {};
			settings[name] = value;
		}
		if (inst) {
			if (this._curInst == inst) {
				this._hideDatepicker();
			}
			var date = this._getDateDatepicker(target, true);
			var minDate = this._getMinMaxDate(inst, 'min');
			var maxDate = this._getMinMaxDate(inst, 'max');
			extendRemove(inst.settings, settings);
			// reformat the old minDate/maxDate values if dateFormat changes and a new minDate/maxDate isn't provided
			if (minDate !== null && settings['dateFormat'] !== undefined && settings['minDate'] === undefined)
				inst.settings.minDate = this._formatDate(inst, minDate);
			if (maxDate !== null && settings['dateFormat'] !== undefined && settings['maxDate'] === undefined)
				inst.settings.maxDate = this._formatDate(inst, maxDate);
			this._attachments($(target), inst);
			this._autoSize(inst);
			this._setDate(inst, date);
			this._updateAlternate(inst);
			this._updateDatepicker(inst);
		}
	},

	// change method deprecated
	_changeDatepicker: function(target, name, value) {
		this._optionDatepicker(target, name, value);
	},

	/* Redraw the date picker attached to an input field or division.
	   @param  target  element - the target input field or division or span */
	_refreshDatepicker: function(target) {
		var inst = this._getInst(target);
		if (inst) {
			this._updateDatepicker(inst);
		}
	},

	/* Set the dates for a jQuery selection.
	   @param  target   element - the target input field or division or span
	   @param  date     Date - the new date */
	_setDateDatepicker: function(target, date) {
		var inst = this._getInst(target);
		if (inst) {
			this._setDate(inst, date);
			this._updateDatepicker(inst);
			this._updateAlternate(inst);
		}
	},

	/* Get the date(s) for the first entry in a jQuery selection.
	   @param  target     element - the target input field or division or span
	   @param  noDefault  boolean - true if no default date is to be used
	   @return Date - the current date */
	_getDateDatepicker: function(target, noDefault) {
		var inst = this._getInst(target);
		if (inst && !inst.inline)
			this._setDateFromField(inst, noDefault);
		return (inst ? this._getDate(inst) : null);
	},

	/* Handle keystrokes. */
	_doKeyDown: function(event) {
		var inst = $.datepicker._getInst(event.target);
		var handled = true;
		var isRTL = inst.dpDiv.is('.ui-datepicker-rtl');
		inst._keyEvent = true;
		if ($.datepicker._datepickerShowing)
			switch (event.keyCode) {
				case 9: $.datepicker._hideDatepicker();
						handled = false;
						break; // hide on tab out
				case 13: var sel = $('td.' + $.datepicker._dayOverClass + ':not(.' + 
									$.datepicker._currentClass + ')', inst.dpDiv);
						if (sel[0])
							$.datepicker._selectDay(event.target, inst.selectedMonth, inst.selectedYear, sel[0]);
						else
							$.datepicker._hideDatepicker();
						return false; // don't submit the form
						break; // select the value on enter
				case 27: $.datepicker._hideDatepicker();
						break; // hide on escape
				case 33: $.datepicker._adjustDate(event.target, (event.ctrlKey ?
							-$.datepicker._get(inst, 'stepBigMonths') :
							-$.datepicker._get(inst, 'stepMonths')), 'M');
						break; // previous month/year on page up/+ ctrl
				case 34: $.datepicker._adjustDate(event.target, (event.ctrlKey ?
							+$.datepicker._get(inst, 'stepBigMonths') :
							+$.datepicker._get(inst, 'stepMonths')), 'M');
						break; // next month/year on page down/+ ctrl
				case 35: if (event.ctrlKey || event.metaKey) $.datepicker._clearDate(event.target);
						handled = event.ctrlKey || event.metaKey;
						break; // clear on ctrl or command +end
				case 36: if (event.ctrlKey || event.metaKey) $.datepicker._gotoToday(event.target);
						handled = event.ctrlKey || event.metaKey;
						break; // current on ctrl or command +home
				case 37: if (event.ctrlKey || event.metaKey) $.datepicker._adjustDate(event.target, (isRTL ? +1 : -1), 'D');
						handled = event.ctrlKey || event.metaKey;
						// -1 day on ctrl or command +left
						if (event.originalEvent.altKey) $.datepicker._adjustDate(event.target, (event.ctrlKey ?
									-$.datepicker._get(inst, 'stepBigMonths') :
									-$.datepicker._get(inst, 'stepMonths')), 'M');
						// next month/year on alt +left on Mac
						break;
				case 38: if (event.ctrlKey || event.metaKey) $.datepicker._adjustDate(event.target, -7, 'D');
						handled = event.ctrlKey || event.metaKey;
						break; // -1 week on ctrl or command +up
				case 39: if (event.ctrlKey || event.metaKey) $.datepicker._adjustDate(event.target, (isRTL ? -1 : +1), 'D');
						handled = event.ctrlKey || event.metaKey;
						// +1 day on ctrl or command +right
						if (event.originalEvent.altKey) $.datepicker._adjustDate(event.target, (event.ctrlKey ?
									+$.datepicker._get(inst, 'stepBigMonths') :
									+$.datepicker._get(inst, 'stepMonths')), 'M');
						// next month/year on alt +right
						break;
				case 40: if (event.ctrlKey || event.metaKey) $.datepicker._adjustDate(event.target, +7, 'D');
						handled = event.ctrlKey || event.metaKey;
						break; // +1 week on ctrl or command +down
				default: handled = false;
			}
		else if (event.keyCode == 36 && event.ctrlKey) // display the date picker on ctrl+home
			$.datepicker._showDatepicker(this);
		else {
			handled = false;
		}
		if (handled) {
			event.preventDefault();
			event.stopPropagation();
		}
	},

	/* Filter entered characters - based on date format. */
	_doKeyPress: function(event) {
		var inst = $.datepicker._getInst(event.target);
		if ($.datepicker._get(inst, 'constrainInput')) {
			var chars = $.datepicker._possibleChars($.datepicker._get(inst, 'dateFormat'));
			var chr = String.fromCharCode(event.charCode == undefined ? event.keyCode : event.charCode);
			return event.ctrlKey || event.metaKey || (chr < ' ' || !chars || chars.indexOf(chr) > -1);
		}
	},

	/* Synchronise manual entry and field/alternate field. */
	_doKeyUp: function(event) {
		var inst = $.datepicker._getInst(event.target);
		if (inst.input.val() != inst.lastVal) {
			try {
				var date = $.datepicker.parseDate($.datepicker._get(inst, 'dateFormat'),
					(inst.input ? inst.input.val() : null),
					$.datepicker._getFormatConfig(inst));
				if (date) { // only if valid
					$.datepicker._setDateFromField(inst);
					$.datepicker._updateAlternate(inst);
					$.datepicker._updateDatepicker(inst);
				}
			}
			catch (event) {
				$.datepicker.log(event);
			}
		}
		return true;
	},

	/* Pop-up the date picker for a given input field.
	   @param  input  element - the input field attached to the date picker or
	                  event - if triggered by focus */
	_showDatepicker: function(input) {
		input = input.target || input;
		if (input.nodeName.toLowerCase() != 'input') // find from button/image trigger
			input = $('input', input.parentNode)[0];
		if ($.datepicker._isDisabledDatepicker(input) || $.datepicker._lastInput == input) // already here
			return;
		var inst = $.datepicker._getInst(input);
		if ($.datepicker._curInst && $.datepicker._curInst != inst) {
			if ( $.datepicker._datepickerShowing ) {
				$.datepicker._triggerOnClose($.datepicker._curInst);
			}
			$.datepicker._curInst.dpDiv.stop(true, true);
		}
		var beforeShow = $.datepicker._get(inst, 'beforeShow');
		extendRemove(inst.settings, (beforeShow ? beforeShow.apply(input, [input, inst]) : {}));
		inst.lastVal = null;
		$.datepicker._lastInput = input;
		$.datepicker._setDateFromField(inst);
		if ($.datepicker._inDialog) // hide cursor
			input.value = '';
		if (!$.datepicker._pos) { // position below input
			$.datepicker._pos = $.datepicker._findPos(input);
			$.datepicker._pos[1] += input.offsetHeight; // add the height
		}
		var isFixed = false;
		$(input).parents().each(function() {
			isFixed |= $(this).css('position') == 'fixed';
			return !isFixed;
		});
		if (isFixed && $.browser.opera) { // correction for Opera when fixed and scrolled
			$.datepicker._pos[0] -= document.documentElement.scrollLeft;
			$.datepicker._pos[1] -= document.documentElement.scrollTop;
		}
		var offset = {left: $.datepicker._pos[0], top: $.datepicker._pos[1]};
		$.datepicker._pos = null;
		//to avoid flashes on Firefox
		inst.dpDiv.empty();
		// determine sizing offscreen
		inst.dpDiv.css({position: 'absolute', display: 'block', top: '-1000px'});
		$.datepicker._updateDatepicker(inst);
		// fix width for dynamic number of date pickers
		// and adjust position before showing
		offset = $.datepicker._checkOffset(inst, offset, isFixed);
		inst.dpDiv.css({position: ($.datepicker._inDialog && $.blockUI ?
			'static' : (isFixed ? 'fixed' : 'absolute')), display: 'none',
			left: offset.left + 'px', top: offset.top + 'px'});
		if (!inst.inline) {
			var showAnim = $.datepicker._get(inst, 'showAnim');
			var duration = $.datepicker._get(inst, 'duration');
			var postProcess = function() {
				var cover = inst.dpDiv.find('iframe.ui-datepicker-cover'); // IE6- only
				if( !! cover.length ){
					var borders = $.datepicker._getBorders(inst.dpDiv);
					cover.css({left: -borders[0], top: -borders[1],
						width: inst.dpDiv.outerWidth(), height: inst.dpDiv.outerHeight()});
				}
			};
			inst.dpDiv.zIndex($(input).zIndex()+1);
			$.datepicker._datepickerShowing = true;
			if ($.effects && $.effects[showAnim])
				inst.dpDiv.show(showAnim, $.datepicker._get(inst, 'showOptions'), duration, postProcess);
			else
				inst.dpDiv[showAnim || 'show']((showAnim ? duration : null), postProcess);
			if (!showAnim || !duration)
				postProcess();
			if (inst.input.is(':visible') && !inst.input.is(':disabled'))
				inst.input.focus();
			$.datepicker._curInst = inst;
		}
	},

	/* Generate the date picker content. */
	_updateDatepicker: function(inst) {
		var self = this;
		self.maxRows = 4; //Reset the max number of rows being displayed (see #7043)
		var borders = $.datepicker._getBorders(inst.dpDiv);
		instActive = inst; // for delegate hover events
		inst.dpDiv.empty().append(this._generateHTML(inst));
		var cover = inst.dpDiv.find('iframe.ui-datepicker-cover'); // IE6- only
		if( !!cover.length ){ //avoid call to outerXXXX() when not in IE6
			cover.css({left: -borders[0], top: -borders[1], width: inst.dpDiv.outerWidth(), height: inst.dpDiv.outerHeight()})
		}
		inst.dpDiv.find('.' + this._dayOverClass + ' a').mouseover();
		var numMonths = this._getNumberOfMonths(inst);
		var cols = numMonths[1];
		var width = 17;
		inst.dpDiv.removeClass('ui-datepicker-multi-2 ui-datepicker-multi-3 ui-datepicker-multi-4').width('');
		if (cols > 1)
			inst.dpDiv.addClass('ui-datepicker-multi-' + cols).css('width', (width * cols) + 'em');
		inst.dpDiv[(numMonths[0] != 1 || numMonths[1] != 1 ? 'add' : 'remove') +
			'Class']('ui-datepicker-multi');
		inst.dpDiv[(this._get(inst, 'isRTL') ? 'add' : 'remove') +
			'Class']('ui-datepicker-rtl');
		if (inst == $.datepicker._curInst && $.datepicker._datepickerShowing && inst.input &&
				// #6694 - don't focus the input if it's already focused
				// this breaks the change event in IE
				inst.input.is(':visible') && !inst.input.is(':disabled') && inst.input[0] != document.activeElement)
			inst.input.focus();
		// deffered render of the years select (to avoid flashes on Firefox) 
		if( inst.yearshtml ){
			var origyearshtml = inst.yearshtml;
			setTimeout(function(){
				//assure that inst.yearshtml didn't change.
				if( origyearshtml === inst.yearshtml && inst.yearshtml ){
					inst.dpDiv.find('select.ui-datepicker-year:first').replaceWith(inst.yearshtml);
				}
				origyearshtml = inst.yearshtml = null;
			}, 0);
		}
	},

	/* Retrieve the size of left and top borders for an element.
	   @param  elem  (jQuery object) the element of interest
	   @return  (number[2]) the left and top borders */
	_getBorders: function(elem) {
		var convert = function(value) {
			return {thin: 1, medium: 2, thick: 3}[value] || value;
		};
		return [parseFloat(convert(elem.css('border-left-width'))),
			parseFloat(convert(elem.css('border-top-width')))];
	},

	/* Check positioning to remain on screen. */
	_checkOffset: function(inst, offset, isFixed) {
		var dpWidth = inst.dpDiv.outerWidth();
		var dpHeight = inst.dpDiv.outerHeight();
		var inputWidth = inst.input ? inst.input.outerWidth() : 0;
		var inputHeight = inst.input ? inst.input.outerHeight() : 0;
		var viewWidth = document.documentElement.clientWidth + $(document).scrollLeft();
		var viewHeight = document.documentElement.clientHeight + $(document).scrollTop();

		offset.left -= (this._get(inst, 'isRTL') ? (dpWidth - inputWidth) : 0);
		offset.left -= (isFixed && offset.left == inst.input.offset().left) ? $(document).scrollLeft() : 0;
		offset.top -= (isFixed && offset.top == (inst.input.offset().top + inputHeight)) ? $(document).scrollTop() : 0;

		// now check if datepicker is showing outside window viewport - move to a better place if so.
		offset.left -= Math.min(offset.left, (offset.left + dpWidth > viewWidth && viewWidth > dpWidth) ?
			Math.abs(offset.left + dpWidth - viewWidth) : 0);
		offset.top -= Math.min(offset.top, (offset.top + dpHeight > viewHeight && viewHeight > dpHeight) ?
			Math.abs(dpHeight + inputHeight) : 0);

		return offset;
	},

	/* Find an object's position on the screen. */
	_findPos: function(obj) {
		var inst = this._getInst(obj);
		var isRTL = this._get(inst, 'isRTL');
        while (obj && (obj.type == 'hidden' || obj.nodeType != 1 || $.expr.filters.hidden(obj))) {
            obj = obj[isRTL ? 'previousSibling' : 'nextSibling'];
        }
        var position = $(obj).offset();
	    return [position.left, position.top];
	},

	/* Trigger custom callback of onClose. */
	_triggerOnClose: function(inst) {
		var onClose = this._get(inst, 'onClose');
		if (onClose)
			onClose.apply((inst.input ? inst.input[0] : null),
						  [(inst.input ? inst.input.val() : ''), inst]);
	},

	/* Hide the date picker from view.
	   @param  input  element - the input field attached to the date picker */
	_hideDatepicker: function(input) {
		var inst = this._curInst;
		if (!inst || (input && inst != $.data(input, PROP_NAME)))
			return;
		if (this._datepickerShowing) {
			var showAnim = this._get(inst, 'showAnim');
			var duration = this._get(inst, 'duration');
			var postProcess = function() {
				$.datepicker._tidyDialog(inst);
				this._curInst = null;
			};
			if ($.effects && $.effects[showAnim])
				inst.dpDiv.hide(showAnim, $.datepicker._get(inst, 'showOptions'), duration, postProcess);
			else
				inst.dpDiv[(showAnim == 'slideDown' ? 'slideUp' :
					(showAnim == 'fadeIn' ? 'fadeOut' : 'hide'))]((showAnim ? duration : null), postProcess);
			if (!showAnim)
				postProcess();
			$.datepicker._triggerOnClose(inst);
			this._datepickerShowing = false;
			this._lastInput = null;
			if (this._inDialog) {
				this._dialogInput.css({ position: 'absolute', left: '0', top: '-100px' });
				if ($.blockUI) {
					$.unblockUI();
					$('body').append(this.dpDiv);
				}
			}
			this._inDialog = false;
		}
	},

	/* Tidy up after a dialog display. */
	_tidyDialog: function(inst) {
		inst.dpDiv.removeClass(this._dialogClass).unbind('.ui-datepicker-calendar');
	},

	/* Close date picker if clicked elsewhere. */
	_checkExternalClick: function(event) {
		if (!$.datepicker._curInst)
			return;
		var $target = $(event.target);
		if ($target[0].id != $.datepicker._mainDivId &&
				$target.parents('#' + $.datepicker._mainDivId).length == 0 &&
				!$target.hasClass($.datepicker.markerClassName) &&
				!$target.hasClass($.datepicker._triggerClass) &&
				$.datepicker._datepickerShowing && !($.datepicker._inDialog && $.blockUI))
			$.datepicker._hideDatepicker();
	},

	/* Adjust one of the date sub-fields. */
	_adjustDate: function(id, offset, period) {
		var target = $(id);
		var inst = this._getInst(target[0]);
		if (this._isDisabledDatepicker(target[0])) {
			return;
		}
		this._adjustInstDate(inst, offset +
			(period == 'M' ? this._get(inst, 'showCurrentAtPos') : 0), // undo positioning
			period);
		this._updateDatepicker(inst);
	},

	/* Action for current link. */
	_gotoToday: function(id) {
		var target = $(id);
		var inst = this._getInst(target[0]);
		if (this._get(inst, 'gotoCurrent') && inst.currentDay) {
			inst.selectedDay = inst.currentDay;
			inst.drawMonth = inst.selectedMonth = inst.currentMonth;
			inst.drawYear = inst.selectedYear = inst.currentYear;
		}
		else {
			var date = new Date();
			inst.selectedDay = date.getDate();
			inst.drawMonth = inst.selectedMonth = date.getMonth();
			inst.drawYear = inst.selectedYear = date.getFullYear();
		}
		this._notifyChange(inst);
		this._adjustDate(target);
	},

	/* Action for selecting a new month/year. */
	_selectMonthYear: function(id, select, period) {
		var target = $(id);
		var inst = this._getInst(target[0]);
		inst._selectingMonthYear = false;
		inst['selected' + (period == 'M' ? 'Month' : 'Year')] =
		inst['draw' + (period == 'M' ? 'Month' : 'Year')] =
			parseInt(select.options[select.selectedIndex].value,10);
		this._notifyChange(inst);
		this._adjustDate(target);
	},

	/* Restore input focus after not changing month/year. */
	_clickMonthYear: function(id) {
		var target = $(id);
		var inst = this._getInst(target[0]);
		if (inst.input && inst._selectingMonthYear) {
			setTimeout(function() {
				inst.input.focus();
			}, 0);
		}
		inst._selectingMonthYear = !inst._selectingMonthYear;
	},

	/* Action for selecting a day. */
	_selectDay: function(id, month, year, td) {
		var target = $(id);
		if ($(td).hasClass(this._unselectableClass) || this._isDisabledDatepicker(target[0])) {
			return;
		}
		var inst = this._getInst(target[0]);
		inst.selectedDay = inst.currentDay = $('a', td).html();
		inst.selectedMonth = inst.currentMonth = month;
		inst.selectedYear = inst.currentYear = year;
		this._selectDate(id, this._formatDate(inst,
			inst.currentDay, inst.currentMonth, inst.currentYear));
	},

	/* Erase the input field and hide the date picker. */
	_clearDate: function(id) {
		var target = $(id);
		var inst = this._getInst(target[0]);
		this._selectDate(target, '');
	},

	/* Update the input field with the selected date. */
	_selectDate: function(id, dateStr) {
		var target = $(id);
		var inst = this._getInst(target[0]);
		dateStr = (dateStr != null ? dateStr : this._formatDate(inst));
		if (inst.input)
			inst.input.val(dateStr);
		this._updateAlternate(inst);
		var onSelect = this._get(inst, 'onSelect');
		if (onSelect)
			onSelect.apply((inst.input ? inst.input[0] : null), [dateStr, inst]);  // trigger custom callback
		else if (inst.input)
			inst.input.trigger('change'); // fire the change event
		if (inst.inline)
			this._updateDatepicker(inst);
		else {
			this._hideDatepicker();
			this._lastInput = inst.input[0];
			if (typeof(inst.input[0]) != 'object')
				inst.input.focus(); // restore focus
			this._lastInput = null;
		}
	},

	/* Update any alternate field to synchronise with the main field. */
	_updateAlternate: function(inst) {
		var altField = this._get(inst, 'altField');
		if (altField) { // update alternate field too
			var altFormat = this._get(inst, 'altFormat') || this._get(inst, 'dateFormat');
			var date = this._getDate(inst);
			var dateStr = this.formatDate(altFormat, date, this._getFormatConfig(inst));
			$(altField).each(function() { $(this).val(dateStr); });
		}
	},

	/* Set as beforeShowDay function to prevent selection of weekends.
	   @param  date  Date - the date to customise
	   @return [boolean, string] - is this date selectable?, what is its CSS class? */
	noWeekends: function(date) {
		var day = date.getDay();
		return [(day > 0 && day < 6), ''];
	},

	/* Set as calculateWeek to determine the week of the year based on the ISO 8601 definition.
	   @param  date  Date - the date to get the week for
	   @return  number - the number of the week within the year that contains this date */
	iso8601Week: function(date) {
		var checkDate = new Date(date.getTime());
		// Find Thursday of this week starting on Monday
		checkDate.setDate(checkDate.getDate() + 4 - (checkDate.getDay() || 7));
		var time = checkDate.getTime();
		checkDate.setMonth(0); // Compare with Jan 1
		checkDate.setDate(1);
		return Math.floor(Math.round((time - checkDate) / 86400000) / 7) + 1;
	},

	/* Parse a string value into a date object.
	   See formatDate below for the possible formats.

	   @param  format    string - the expected format of the date
	   @param  value     string - the date in the above format
	   @param  settings  Object - attributes include:
	                     shortYearCutoff  number - the cutoff year for determining the century (optional)
	                     dayNamesShort    string[7] - abbreviated names of the days from Sunday (optional)
	                     dayNames         string[7] - names of the days from Sunday (optional)
	                     monthNamesShort  string[12] - abbreviated names of the months (optional)
	                     monthNames       string[12] - names of the months (optional)
	   @return  Date - the extracted date value or null if value is blank */
	parseDate: function (format, value, settings) {
		if (format == null || value == null)
			throw 'Invalid arguments';
		value = (typeof value == 'object' ? value.toString() : value + '');
		if (value == '')
			return null;
		var shortYearCutoff = (settings ? settings.shortYearCutoff : null) || this._defaults.shortYearCutoff;
		shortYearCutoff = (typeof shortYearCutoff != 'string' ? shortYearCutoff :
				new Date().getFullYear() % 100 + parseInt(shortYearCutoff, 10));
		var dayNamesShort = (settings ? settings.dayNamesShort : null) || this._defaults.dayNamesShort;
		var dayNames = (settings ? settings.dayNames : null) || this._defaults.dayNames;
		var monthNamesShort = (settings ? settings.monthNamesShort : null) || this._defaults.monthNamesShort;
		var monthNames = (settings ? settings.monthNames : null) || this._defaults.monthNames;
		var year = -1;
		var month = -1;
		var day = -1;
		var doy = -1;
		var literal = false;
		// Check whether a format character is doubled
		var lookAhead = function(match) {
			var matches = (iFormat + 1 < format.length && format.charAt(iFormat + 1) == match);
			if (matches)
				iFormat++;
			return matches;
		};
		// Extract a number from the string value
		var getNumber = function(match) {
			var isDoubled = lookAhead(match);
			var size = (match == '@' ? 14 : (match == '!' ? 20 :
				(match == 'y' && isDoubled ? 4 : (match == 'o' ? 3 : 2))));
			var digits = new RegExp('^\\d{1,' + size + '}');
			var num = value.substring(iValue).match(digits);
			if (!num)
				throw 'Missing number at position ' + iValue;
			iValue += num[0].length;
			return parseInt(num[0], 10);
		};
		// Extract a name from the string value and convert to an index
		var getName = function(match, shortNames, longNames) {
			var names = $.map(lookAhead(match) ? longNames : shortNames, function (v, k) {
				return [ [k, v] ];
			}).sort(function (a, b) {
				return -(a[1].length - b[1].length);
			});
			var index = -1;
			$.each(names, function (i, pair) {
				var name = pair[1];
				if (value.substr(iValue, name.length).toLowerCase() == name.toLowerCase()) {
					index = pair[0];
					iValue += name.length;
					return false;
				}
			});
			if (index != -1)
				return index + 1;
			else
				throw 'Unknown name at position ' + iValue;
		};
		// Confirm that a literal character matches the string value
		var checkLiteral = function() {
			if (value.charAt(iValue) != format.charAt(iFormat))
				throw 'Unexpected literal at position ' + iValue;
			iValue++;
		};
		var iValue = 0;
		for (var iFormat = 0; iFormat < format.length; iFormat++) {
			if (literal)
				if (format.charAt(iFormat) == "'" && !lookAhead("'"))
					literal = false;
				else
					checkLiteral();
			else
				switch (format.charAt(iFormat)) {
					case 'd':
						day = getNumber('d');
						break;
					case 'D':
						getName('D', dayNamesShort, dayNames);
						break;
					case 'o':
						doy = getNumber('o');
						break;
					case 'm':
						month = getNumber('m');
						break;
					case 'M':
						month = getName('M', monthNamesShort, monthNames);
						break;
					case 'y':
						year = getNumber('y');
						break;
					case '@':
						var date = new Date(getNumber('@'));
						year = date.getFullYear();
						month = date.getMonth() + 1;
						day = date.getDate();
						break;
					case '!':
						var date = new Date((getNumber('!') - this._ticksTo1970) / 10000);
						year = date.getFullYear();
						month = date.getMonth() + 1;
						day = date.getDate();
						break;
					case "'":
						if (lookAhead("'"))
							checkLiteral();
						else
							literal = true;
						break;
					default:
						checkLiteral();
				}
		}
		if (iValue < value.length){
			throw "Extra/unparsed characters found in date: " + value.substring(iValue);
		}
		if (year == -1)
			year = new Date().getFullYear();
		else if (year < 100)
			year += new Date().getFullYear() - new Date().getFullYear() % 100 +
				(year <= shortYearCutoff ? 0 : -100);
		if (doy > -1) {
			month = 1;
			day = doy;
			do {
				var dim = this._getDaysInMonth(year, month - 1);
				if (day <= dim)
					break;
				month++;
				day -= dim;
			} while (true);
		}
		var date = this._daylightSavingAdjust(new Date(year, month - 1, day));
		if (date.getFullYear() != year || date.getMonth() + 1 != month || date.getDate() != day)
			throw 'Invalid date'; // E.g. 31/02/00
		return date;
	},

	/* Standard date formats. */
	ATOM: 'yy-mm-dd', // RFC 3339 (ISO 8601)
	COOKIE: 'D, dd M yy',
	ISO_8601: 'yy-mm-dd',
	RFC_822: 'D, d M y',
	RFC_850: 'DD, dd-M-y',
	RFC_1036: 'D, d M y',
	RFC_1123: 'D, d M yy',
	RFC_2822: 'D, d M yy',
	RSS: 'D, d M y', // RFC 822
	TICKS: '!',
	TIMESTAMP: '@',
	W3C: 'yy-mm-dd', // ISO 8601

	_ticksTo1970: (((1970 - 1) * 365 + Math.floor(1970 / 4) - Math.floor(1970 / 100) +
		Math.floor(1970 / 400)) * 24 * 60 * 60 * 10000000),

	/* Format a date object into a string value.
	   The format can be combinations of the following:
	   d  - day of month (no leading zero)
	   dd - day of month (two digit)
	   o  - day of year (no leading zeros)
	   oo - day of year (three digit)
	   D  - day name short
	   DD - day name long
	   m  - month of year (no leading zero)
	   mm - month of year (two digit)
	   M  - month name short
	   MM - month name long
	   y  - year (two digit)
	   yy - year (four digit)
	   @ - Unix timestamp (ms since 01/01/1970)
	   ! - Windows ticks (100ns since 01/01/0001)
	   '...' - literal text
	   '' - single quote

	   @param  format    string - the desired format of the date
	   @param  date      Date - the date value to format
	   @param  settings  Object - attributes include:
	                     dayNamesShort    string[7] - abbreviated names of the days from Sunday (optional)
	                     dayNames         string[7] - names of the days from Sunday (optional)
	                     monthNamesShort  string[12] - abbreviated names of the months (optional)
	                     monthNames       string[12] - names of the months (optional)
	   @return  string - the date in the above format */
	formatDate: function (format, date, settings) {
		if (!date)
			return '';
		var dayNamesShort = (settings ? settings.dayNamesShort : null) || this._defaults.dayNamesShort;
		var dayNames = (settings ? settings.dayNames : null) || this._defaults.dayNames;
		var monthNamesShort = (settings ? settings.monthNamesShort : null) || this._defaults.monthNamesShort;
		var monthNames = (settings ? settings.monthNames : null) || this._defaults.monthNames;
		// Check whether a format character is doubled
		var lookAhead = function(match) {
			var matches = (iFormat + 1 < format.length && format.charAt(iFormat + 1) == match);
			if (matches)
				iFormat++;
			return matches;
		};
		// Format a number, with leading zero if necessary
		var formatNumber = function(match, value, len) {
			var num = '' + value;
			if (lookAhead(match))
				while (num.length < len)
					num = '0' + num;
			return num;
		};
		// Format a name, short or long as requested
		var formatName = function(match, value, shortNames, longNames) {
			return (lookAhead(match) ? longNames[value] : shortNames[value]);
		};
		var output = '';
		var literal = false;
		if (date)
			for (var iFormat = 0; iFormat < format.length; iFormat++) {
				if (literal)
					if (format.charAt(iFormat) == "'" && !lookAhead("'"))
						literal = false;
					else
						output += format.charAt(iFormat);
				else
					switch (format.charAt(iFormat)) {
						case 'd':
							output += formatNumber('d', date.getDate(), 2);
							break;
						case 'D':
							output += formatName('D', date.getDay(), dayNamesShort, dayNames);
							break;
						case 'o':
							output += formatNumber('o',
								Math.round((new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime() - new Date(date.getFullYear(), 0, 0).getTime()) / 86400000), 3);
							break;
						case 'm':
							output += formatNumber('m', date.getMonth() + 1, 2);
							break;
						case 'M':
							output += formatName('M', date.getMonth(), monthNamesShort, monthNames);
							break;
						case 'y':
							output += (lookAhead('y') ? date.getFullYear() :
								(date.getYear() % 100 < 10 ? '0' : '') + date.getYear() % 100);
							break;
						case '@':
							output += date.getTime();
							break;
						case '!':
							output += date.getTime() * 10000 + this._ticksTo1970;
							break;
						case "'":
							if (lookAhead("'"))
								output += "'";
							else
								literal = true;
							break;
						default:
							output += format.charAt(iFormat);
					}
			}
		return output;
	},

	/* Extract all possible characters from the date format. */
	_possibleChars: function (format) {
		var chars = '';
		var literal = false;
		// Check whether a format character is doubled
		var lookAhead = function(match) {
			var matches = (iFormat + 1 < format.length && format.charAt(iFormat + 1) == match);
			if (matches)
				iFormat++;
			return matches;
		};
		for (var iFormat = 0; iFormat < format.length; iFormat++)
			if (literal)
				if (format.charAt(iFormat) == "'" && !lookAhead("'"))
					literal = false;
				else
					chars += format.charAt(iFormat);
			else
				switch (format.charAt(iFormat)) {
					case 'd': case 'm': case 'y': case '@':
						chars += '0123456789';
						break;
					case 'D': case 'M':
						return null; // Accept anything
					case "'":
						if (lookAhead("'"))
							chars += "'";
						else
							literal = true;
						break;
					default:
						chars += format.charAt(iFormat);
				}
		return chars;
	},

	/* Get a setting value, defaulting if necessary. */
	_get: function(inst, name) {
		return inst.settings[name] !== undefined ?
			inst.settings[name] : this._defaults[name];
	},

	/* Parse existing date and initialise date picker. */
	_setDateFromField: function(inst, noDefault) {
		if (inst.input.val() == inst.lastVal) {
			return;
		}
		var dateFormat = this._get(inst, 'dateFormat');
		var dates = inst.lastVal = inst.input ? inst.input.val() : null;
		var date, defaultDate;
		date = defaultDate = this._getDefaultDate(inst);
		var settings = this._getFormatConfig(inst);
		try {
			date = this.parseDate(dateFormat, dates, settings) || defaultDate;
		} catch (event) {
			this.log(event);
			dates = (noDefault ? '' : dates);
		}
		inst.selectedDay = date.getDate();
		inst.drawMonth = inst.selectedMonth = date.getMonth();
		inst.drawYear = inst.selectedYear = date.getFullYear();
		inst.currentDay = (dates ? date.getDate() : 0);
		inst.currentMonth = (dates ? date.getMonth() : 0);
		inst.currentYear = (dates ? date.getFullYear() : 0);
		this._adjustInstDate(inst);
	},

	/* Retrieve the default date shown on opening. */
	_getDefaultDate: function(inst) {
		return this._restrictMinMax(inst,
			this._determineDate(inst, this._get(inst, 'defaultDate'), new Date()));
	},

	/* A date may be specified as an exact value or a relative one. */
	_determineDate: function(inst, date, defaultDate) {
		var offsetNumeric = function(offset) {
			var date = new Date();
			date.setDate(date.getDate() + offset);
			return date;
		};
		var offsetString = function(offset) {
			try {
				return $.datepicker.parseDate($.datepicker._get(inst, 'dateFormat'),
					offset, $.datepicker._getFormatConfig(inst));
			}
			catch (e) {
				// Ignore
			}
			var date = (offset.toLowerCase().match(/^c/) ?
				$.datepicker._getDate(inst) : null) || new Date();
			var year = date.getFullYear();
			var month = date.getMonth();
			var day = date.getDate();
			var pattern = /([+-]?[0-9]+)\s*(d|D|w|W|m|M|y|Y)?/g;
			var matches = pattern.exec(offset);
			while (matches) {
				switch (matches[2] || 'd') {
					case 'd' : case 'D' :
						day += parseInt(matches[1],10); break;
					case 'w' : case 'W' :
						day += parseInt(matches[1],10) * 7; break;
					case 'm' : case 'M' :
						month += parseInt(matches[1],10);
						day = Math.min(day, $.datepicker._getDaysInMonth(year, month));
						break;
					case 'y': case 'Y' :
						year += parseInt(matches[1],10);
						day = Math.min(day, $.datepicker._getDaysInMonth(year, month));
						break;
				}
				matches = pattern.exec(offset);
			}
			return new Date(year, month, day);
		};
		var newDate = (date == null || date === '' ? defaultDate : (typeof date == 'string' ? offsetString(date) :
			(typeof date == 'number' ? (isNaN(date) ? defaultDate : offsetNumeric(date)) : new Date(date.getTime()))));
		newDate = (newDate && newDate.toString() == 'Invalid Date' ? defaultDate : newDate);
		if (newDate) {
			newDate.setHours(0);
			newDate.setMinutes(0);
			newDate.setSeconds(0);
			newDate.setMilliseconds(0);
		}
		return this._daylightSavingAdjust(newDate);
	},

	/* Handle switch to/from daylight saving.
	   Hours may be non-zero on daylight saving cut-over:
	   > 12 when midnight changeover, but then cannot generate
	   midnight datetime, so jump to 1AM, otherwise reset.
	   @param  date  (Date) the date to check
	   @return  (Date) the corrected date */
	_daylightSavingAdjust: function(date) {
		if (!date) return null;
		date.setHours(date.getHours() > 12 ? date.getHours() + 2 : 0);
		return date;
	},

	/* Set the date(s) directly. */
	_setDate: function(inst, date, noChange) {
		var clear = !date;
		var origMonth = inst.selectedMonth;
		var origYear = inst.selectedYear;
		var newDate = this._restrictMinMax(inst, this._determineDate(inst, date, new Date()));
		inst.selectedDay = inst.currentDay = newDate.getDate();
		inst.drawMonth = inst.selectedMonth = inst.currentMonth = newDate.getMonth();
		inst.drawYear = inst.selectedYear = inst.currentYear = newDate.getFullYear();
		if ((origMonth != inst.selectedMonth || origYear != inst.selectedYear) && !noChange)
			this._notifyChange(inst);
		this._adjustInstDate(inst);
		if (inst.input) {
			inst.input.val(clear ? '' : this._formatDate(inst));
		}
	},

	/* Retrieve the date(s) directly. */
	_getDate: function(inst) {
		var startDate = (!inst.currentYear || (inst.input && inst.input.val() == '') ? null :
			this._daylightSavingAdjust(new Date(
			inst.currentYear, inst.currentMonth, inst.currentDay)));
			return startDate;
	},

	/* Generate the HTML for the current state of the date picker. */
	_generateHTML: function(inst) {
		var today = new Date();
		today = this._daylightSavingAdjust(
			new Date(today.getFullYear(), today.getMonth(), today.getDate())); // clear time
		var isRTL = this._get(inst, 'isRTL');
		var showButtonPanel = this._get(inst, 'showButtonPanel');
		var hideIfNoPrevNext = this._get(inst, 'hideIfNoPrevNext');
		var navigationAsDateFormat = this._get(inst, 'navigationAsDateFormat');
		var numMonths = this._getNumberOfMonths(inst);
		var showCurrentAtPos = this._get(inst, 'showCurrentAtPos');
		var stepMonths = this._get(inst, 'stepMonths');
		var isMultiMonth = (numMonths[0] != 1 || numMonths[1] != 1);
		var currentDate = this._daylightSavingAdjust((!inst.currentDay ? new Date(9999, 9, 9) :
			new Date(inst.currentYear, inst.currentMonth, inst.currentDay)));
		var minDate = this._getMinMaxDate(inst, 'min');
		var maxDate = this._getMinMaxDate(inst, 'max');
		var drawMonth = inst.drawMonth - showCurrentAtPos;
		var drawYear = inst.drawYear;
		if (drawMonth < 0) {
			drawMonth += 12;
			drawYear--;
		}
		if (maxDate) {
			var maxDraw = this._daylightSavingAdjust(new Date(maxDate.getFullYear(),
				maxDate.getMonth() - (numMonths[0] * numMonths[1]) + 1, maxDate.getDate()));
			maxDraw = (minDate && maxDraw < minDate ? minDate : maxDraw);
			while (this._daylightSavingAdjust(new Date(drawYear, drawMonth, 1)) > maxDraw) {
				drawMonth--;
				if (drawMonth < 0) {
					drawMonth = 11;
					drawYear--;
				}
			}
		}
		inst.drawMonth = drawMonth;
		inst.drawYear = drawYear;
		var prevText = this._get(inst, 'prevText');
		prevText = (!navigationAsDateFormat ? prevText : this.formatDate(prevText,
			this._daylightSavingAdjust(new Date(drawYear, drawMonth - stepMonths, 1)),
			this._getFormatConfig(inst)));
		var prev = (this._canAdjustMonth(inst, -1, drawYear, drawMonth) ?
			'<a class="ui-datepicker-prev ui-corner-all" onclick="DP_jQuery_' + dpuuid +
			'.datepicker._adjustDate(\'#' + inst.id + '\', -' + stepMonths + ', \'M\');"' +
			' title="' + prevText + '"><span class="ui-icon ui-icon-circle-triangle-' + ( isRTL ? 'e' : 'w') + '">' + prevText + '</span></a>' :
			(hideIfNoPrevNext ? '' : '<a class="ui-datepicker-prev ui-corner-all ui-state-disabled" title="'+ prevText +'"><span class="ui-icon ui-icon-circle-triangle-' + ( isRTL ? 'e' : 'w') + '">' + prevText + '</span></a>'));
		var nextText = this._get(inst, 'nextText');
		nextText = (!navigationAsDateFormat ? nextText : this.formatDate(nextText,
			this._daylightSavingAdjust(new Date(drawYear, drawMonth + stepMonths, 1)),
			this._getFormatConfig(inst)));
		var next = (this._canAdjustMonth(inst, +1, drawYear, drawMonth) ?
			'<a class="ui-datepicker-next ui-corner-all" onclick="DP_jQuery_' + dpuuid +
			'.datepicker._adjustDate(\'#' + inst.id + '\', +' + stepMonths + ', \'M\');"' +
			' title="' + nextText + '"><span class="ui-icon ui-icon-circle-triangle-' + ( isRTL ? 'w' : 'e') + '">' + nextText + '</span></a>' :
			(hideIfNoPrevNext ? '' : '<a class="ui-datepicker-next ui-corner-all ui-state-disabled" title="'+ nextText + '"><span class="ui-icon ui-icon-circle-triangle-' + ( isRTL ? 'w' : 'e') + '">' + nextText + '</span></a>'));
		var currentText = this._get(inst, 'currentText');
		var gotoDate = (this._get(inst, 'gotoCurrent') && inst.currentDay ? currentDate : today);
		currentText = (!navigationAsDateFormat ? currentText :
			this.formatDate(currentText, gotoDate, this._getFormatConfig(inst)));
		var controls = (!inst.inline ? '<button type="button" class="ui-datepicker-close ui-state-default ui-priority-primary ui-corner-all" onclick="DP_jQuery_' + dpuuid +
			'.datepicker._hideDatepicker();">' + this._get(inst, 'closeText') + '</button>' : '');
		var buttonPanel = (showButtonPanel) ? '<div class="ui-datepicker-buttonpane ui-widget-content">' + (isRTL ? controls : '') +
			(this._isInRange(inst, gotoDate) ? '<button type="button" class="ui-datepicker-current ui-state-default ui-priority-secondary ui-corner-all" onclick="DP_jQuery_' + dpuuid +
			'.datepicker._gotoToday(\'#' + inst.id + '\');"' +
			'>' + currentText + '</button>' : '') + (isRTL ? '' : controls) + '</div>' : '';
		var firstDay = parseInt(this._get(inst, 'firstDay'),10);
		firstDay = (isNaN(firstDay) ? 0 : firstDay);
		var showWeek = this._get(inst, 'showWeek');
		var dayNames = this._get(inst, 'dayNames');
		var dayNamesShort = this._get(inst, 'dayNamesShort');
		var dayNamesMin = this._get(inst, 'dayNamesMin');
		var monthNames = this._get(inst, 'monthNames');
		var monthNamesShort = this._get(inst, 'monthNamesShort');
		var beforeShowDay = this._get(inst, 'beforeShowDay');
		var showOtherMonths = this._get(inst, 'showOtherMonths');
		var selectOtherMonths = this._get(inst, 'selectOtherMonths');
		var calculateWeek = this._get(inst, 'calculateWeek') || this.iso8601Week;
		var defaultDate = this._getDefaultDate(inst);
		var html = '';
		for (var row = 0; row < numMonths[0]; row++) {
			var group = '';
			this.maxRows = 4;
			for (var col = 0; col < numMonths[1]; col++) {
				var selectedDate = this._daylightSavingAdjust(new Date(drawYear, drawMonth, inst.selectedDay));
				var cornerClass = ' ui-corner-all';
				var calender = '';
				if (isMultiMonth) {
					calender += '<div class="ui-datepicker-group';
					if (numMonths[1] > 1)
						switch (col) {
							case 0: calender += ' ui-datepicker-group-first';
								cornerClass = ' ui-corner-' + (isRTL ? 'right' : 'left'); break;
							case numMonths[1]-1: calender += ' ui-datepicker-group-last';
								cornerClass = ' ui-corner-' + (isRTL ? 'left' : 'right'); break;
							default: calender += ' ui-datepicker-group-middle'; cornerClass = ''; break;
						}
					calender += '">';
				}
				calender += '<div class="ui-datepicker-header ui-widget-header ui-helper-clearfix' + cornerClass + '">' +
					(/all|left/.test(cornerClass) && row == 0 ? (isRTL ? next : prev) : '') +
					(/all|right/.test(cornerClass) && row == 0 ? (isRTL ? prev : next) : '') +
					this._generateMonthYearHeader(inst, drawMonth, drawYear, minDate, maxDate,
					row > 0 || col > 0, monthNames, monthNamesShort) + // draw month headers
					'</div><table class="ui-datepicker-calendar"><thead>' +
					'<tr>';
				var thead = (showWeek ? '<th class="ui-datepicker-week-col">' + this._get(inst, 'weekHeader') + '</th>' : '');
				for (var dow = 0; dow < 7; dow++) { // days of the week
					var day = (dow + firstDay) % 7;
					thead += '<th' + ((dow + firstDay + 6) % 7 >= 5 ? ' class="ui-datepicker-week-end"' : '') + '>' +
						'<span title="' + dayNames[day] + '">' + dayNamesMin[day] + '</span></th>';
				}
				calender += thead + '</tr></thead><tbody>';
				var daysInMonth = this._getDaysInMonth(drawYear, drawMonth);
				if (drawYear == inst.selectedYear && drawMonth == inst.selectedMonth)
					inst.selectedDay = Math.min(inst.selectedDay, daysInMonth);
				var leadDays = (this._getFirstDayOfMonth(drawYear, drawMonth) - firstDay + 7) % 7;
				var curRows = Math.ceil((leadDays + daysInMonth) / 7); // calculate the number of rows to generate
				var numRows = (isMultiMonth ? this.maxRows > curRows ? this.maxRows : curRows : curRows); //If multiple months, use the higher number of rows (see #7043)
				this.maxRows = numRows;
				var printDate = this._daylightSavingAdjust(new Date(drawYear, drawMonth, 1 - leadDays));
				for (var dRow = 0; dRow < numRows; dRow++) { // create date picker rows
					calender += '<tr>';
					var tbody = (!showWeek ? '' : '<td class="ui-datepicker-week-col">' +
						this._get(inst, 'calculateWeek')(printDate) + '</td>');
					for (var dow = 0; dow < 7; dow++) { // create date picker days
						var daySettings = (beforeShowDay ?
							beforeShowDay.apply((inst.input ? inst.input[0] : null), [printDate]) : [true, '']);
						var otherMonth = (printDate.getMonth() != drawMonth);
						var unselectable = (otherMonth && !selectOtherMonths) || !daySettings[0] ||
							(minDate && printDate < minDate) || (maxDate && printDate > maxDate);
						tbody += '<td class="' +
							((dow + firstDay + 6) % 7 >= 5 ? ' ui-datepicker-week-end' : '') + // highlight weekends
							(otherMonth ? ' ui-datepicker-other-month' : '') + // highlight days from other months
							((printDate.getTime() == selectedDate.getTime() && drawMonth == inst.selectedMonth && inst._keyEvent) || // user pressed key
							(defaultDate.getTime() == printDate.getTime() && defaultDate.getTime() == selectedDate.getTime()) ?
							// or defaultDate is current printedDate and defaultDate is selectedDate
							' ' + this._dayOverClass : '') + // highlight selected day
							(unselectable ? ' ' + this._unselectableClass + ' ui-state-disabled': '') +  // highlight unselectable days
							(otherMonth && !showOtherMonths ? '' : ' ' + daySettings[1] + // highlight custom dates
							(printDate.getTime() == currentDate.getTime() ? ' ' + this._currentClass : '') + // highlight selected day
							(printDate.getTime() == today.getTime() ? ' ui-datepicker-today' : '')) + '"' + // highlight today (if different)
							((!otherMonth || showOtherMonths) && daySettings[2] ? ' title="' + daySettings[2] + '"' : '') + // cell title
							(unselectable ? '' : ' onclick="DP_jQuery_' + dpuuid + '.datepicker._selectDay(\'#' +
							inst.id + '\',' + printDate.getMonth() + ',' + printDate.getFullYear() + ', this);return false;"') + '>' + // actions
							(otherMonth && !showOtherMonths ? '&#xa0;' : // display for other months
							(unselectable ? '<span class="ui-state-default">' + printDate.getDate() + '</span>' : '<a class="ui-state-default' +
							(printDate.getTime() == today.getTime() ? ' ui-state-highlight' : '') +
							(printDate.getTime() == currentDate.getTime() ? ' ui-state-active' : '') + // highlight selected day
							(otherMonth ? ' ui-priority-secondary' : '') + // distinguish dates from other months
							'" href="#">' + printDate.getDate() + '</a>')) + '</td>'; // display selectable date
						printDate.setDate(printDate.getDate() + 1);
						printDate = this._daylightSavingAdjust(printDate);
					}
					calender += tbody + '</tr>';
				}
				drawMonth++;
				if (drawMonth > 11) {
					drawMonth = 0;
					drawYear++;
				}
				calender += '</tbody></table>' + (isMultiMonth ? '</div>' + 
							((numMonths[0] > 0 && col == numMonths[1]-1) ? '<div class="ui-datepicker-row-break"></div>' : '') : '');
				group += calender;
			}
			html += group;
		}
		html += buttonPanel + ($.browser.msie && parseInt($.browser.version,10) < 7 && !inst.inline ?
			'<iframe src="javascript:false;" class="ui-datepicker-cover" frameborder="0"></iframe>' : '');
		inst._keyEvent = false;
		return html;
	},

	/* Generate the month and year header. */
	_generateMonthYearHeader: function(inst, drawMonth, drawYear, minDate, maxDate,
			secondary, monthNames, monthNamesShort) {
		var changeMonth = this._get(inst, 'changeMonth');
		var changeYear = this._get(inst, 'changeYear');
		var showMonthAfterYear = this._get(inst, 'showMonthAfterYear');
		var html = '<div class="ui-datepicker-title">';
		var monthHtml = '';
		// month selection
		if (secondary || !changeMonth)
			monthHtml += '<span class="ui-datepicker-month">' + monthNames[drawMonth] + '</span>';
		else {
			var inMinYear = (minDate && minDate.getFullYear() == drawYear);
			var inMaxYear = (maxDate && maxDate.getFullYear() == drawYear);
			monthHtml += '<select class="ui-datepicker-month" ' +
				'onchange="DP_jQuery_' + dpuuid + '.datepicker._selectMonthYear(\'#' + inst.id + '\', this, \'M\');" ' +
				'onclick="DP_jQuery_' + dpuuid + '.datepicker._clickMonthYear(\'#' + inst.id + '\');"' +
			 	'>';
			for (var month = 0; month < 12; month++) {
				if ((!inMinYear || month >= minDate.getMonth()) &&
						(!inMaxYear || month <= maxDate.getMonth()))
					monthHtml += '<option value="' + month + '"' +
						(month == drawMonth ? ' selected="selected"' : '') +
						'>' + monthNamesShort[month] + '</option>';
			}
			monthHtml += '</select>';
		}
		if (!showMonthAfterYear)
			html += monthHtml + (secondary || !(changeMonth && changeYear) ? '&#xa0;' : '');
		// year selection
		if ( !inst.yearshtml ) {
			inst.yearshtml = '';
			if (secondary || !changeYear)
				html += '<span class="ui-datepicker-year">' + drawYear + '</span>';
			else {
				// determine range of years to display
				var years = this._get(inst, 'yearRange').split(':');
				var thisYear = new Date().getFullYear();
				var determineYear = function(value) {
					var year = (value.match(/c[+-].*/) ? drawYear + parseInt(value.substring(1), 10) :
						(value.match(/[+-].*/) ? thisYear + parseInt(value, 10) :
						parseInt(value, 10)));
					return (isNaN(year) ? thisYear : year);
				};
				var year = determineYear(years[0]);
				var endYear = Math.max(year, determineYear(years[1] || ''));
				year = (minDate ? Math.max(year, minDate.getFullYear()) : year);
				endYear = (maxDate ? Math.min(endYear, maxDate.getFullYear()) : endYear);
				inst.yearshtml += '<select class="ui-datepicker-year" ' +
					'onchange="DP_jQuery_' + dpuuid + '.datepicker._selectMonthYear(\'#' + inst.id + '\', this, \'Y\');" ' +
					'onclick="DP_jQuery_' + dpuuid + '.datepicker._clickMonthYear(\'#' + inst.id + '\');"' +
					'>';
				for (; year <= endYear; year++) {
					inst.yearshtml += '<option value="' + year + '"' +
						(year == drawYear ? ' selected="selected"' : '') +
						'>' + year + '</option>';
				}
				inst.yearshtml += '</select>';
				
				html += inst.yearshtml;
				inst.yearshtml = null;
			}
		}
		html += this._get(inst, 'yearSuffix');
		if (showMonthAfterYear)
			html += (secondary || !(changeMonth && changeYear) ? '&#xa0;' : '') + monthHtml;
		html += '</div>'; // Close datepicker_header
		return html;
	},

	/* Adjust one of the date sub-fields. */
	_adjustInstDate: function(inst, offset, period) {
		var year = inst.drawYear + (period == 'Y' ? offset : 0);
		var month = inst.drawMonth + (period == 'M' ? offset : 0);
		var day = Math.min(inst.selectedDay, this._getDaysInMonth(year, month)) +
			(period == 'D' ? offset : 0);
		var date = this._restrictMinMax(inst,
			this._daylightSavingAdjust(new Date(year, month, day)));
		inst.selectedDay = date.getDate();
		inst.drawMonth = inst.selectedMonth = date.getMonth();
		inst.drawYear = inst.selectedYear = date.getFullYear();
		if (period == 'M' || period == 'Y')
			this._notifyChange(inst);
	},

	/* Ensure a date is within any min/max bounds. */
	_restrictMinMax: function(inst, date) {
		var minDate = this._getMinMaxDate(inst, 'min');
		var maxDate = this._getMinMaxDate(inst, 'max');
		var newDate = (minDate && date < minDate ? minDate : date);
		newDate = (maxDate && newDate > maxDate ? maxDate : newDate);
		return newDate;
	},

	/* Notify change of month/year. */
	_notifyChange: function(inst) {
		var onChange = this._get(inst, 'onChangeMonthYear');
		if (onChange)
			onChange.apply((inst.input ? inst.input[0] : null),
				[inst.selectedYear, inst.selectedMonth + 1, inst]);
	},

	/* Determine the number of months to show. */
	_getNumberOfMonths: function(inst) {
		var numMonths = this._get(inst, 'numberOfMonths');
		return (numMonths == null ? [1, 1] : (typeof numMonths == 'number' ? [1, numMonths] : numMonths));
	},

	/* Determine the current maximum date - ensure no time components are set. */
	_getMinMaxDate: function(inst, minMax) {
		return this._determineDate(inst, this._get(inst, minMax + 'Date'), null);
	},

	/* Find the number of days in a given month. */
	_getDaysInMonth: function(year, month) {
		return 32 - this._daylightSavingAdjust(new Date(year, month, 32)).getDate();
	},

	/* Find the day of the week of the first of a month. */
	_getFirstDayOfMonth: function(year, month) {
		return new Date(year, month, 1).getDay();
	},

	/* Determines if we should allow a "next/prev" month display change. */
	_canAdjustMonth: function(inst, offset, curYear, curMonth) {
		var numMonths = this._getNumberOfMonths(inst);
		var date = this._daylightSavingAdjust(new Date(curYear,
			curMonth + (offset < 0 ? offset : numMonths[0] * numMonths[1]), 1));
		if (offset < 0)
			date.setDate(this._getDaysInMonth(date.getFullYear(), date.getMonth()));
		return this._isInRange(inst, date);
	},

	/* Is the given date in the accepted range? */
	_isInRange: function(inst, date) {
		var minDate = this._getMinMaxDate(inst, 'min');
		var maxDate = this._getMinMaxDate(inst, 'max');
		return ((!minDate || date.getTime() >= minDate.getTime()) &&
			(!maxDate || date.getTime() <= maxDate.getTime()));
	},

	/* Provide the configuration settings for formatting/parsing. */
	_getFormatConfig: function(inst) {
		var shortYearCutoff = this._get(inst, 'shortYearCutoff');
		shortYearCutoff = (typeof shortYearCutoff != 'string' ? shortYearCutoff :
			new Date().getFullYear() % 100 + parseInt(shortYearCutoff, 10));
		return {shortYearCutoff: shortYearCutoff,
			dayNamesShort: this._get(inst, 'dayNamesShort'), dayNames: this._get(inst, 'dayNames'),
			monthNamesShort: this._get(inst, 'monthNamesShort'), monthNames: this._get(inst, 'monthNames')};
	},

	/* Format the given date for display. */
	_formatDate: function(inst, day, month, year) {
		if (!day) {
			inst.currentDay = inst.selectedDay;
			inst.currentMonth = inst.selectedMonth;
			inst.currentYear = inst.selectedYear;
		}
		var date = (day ? (typeof day == 'object' ? day :
			this._daylightSavingAdjust(new Date(year, month, day))) :
			this._daylightSavingAdjust(new Date(inst.currentYear, inst.currentMonth, inst.currentDay)));
		return this.formatDate(this._get(inst, 'dateFormat'), date, this._getFormatConfig(inst));
	}
});

/*
 * Bind hover events for datepicker elements.
 * Done via delegate so the binding only occurs once in the lifetime of the parent div.
 * Global instActive, set by _updateDatepicker allows the handlers to find their way back to the active picker.
 */ 
function bindHover(dpDiv) {
	var selector = 'button, .ui-datepicker-prev, .ui-datepicker-next, .ui-datepicker-calendar td a';
	return dpDiv.bind('mouseout', function(event) {
			var elem = $( event.target ).closest( selector );
			if ( !elem.length ) {
				return;
			}
			elem.removeClass( "ui-state-hover ui-datepicker-prev-hover ui-datepicker-next-hover" );
		})
		.bind('mouseover', function(event) {
			var elem = $( event.target ).closest( selector );
			if ($.datepicker._isDisabledDatepicker( instActive.inline ? dpDiv.parent()[0] : instActive.input[0]) ||
					!elem.length ) {
				return;
			}
			elem.parents('.ui-datepicker-calendar').find('a').removeClass('ui-state-hover');
			elem.addClass('ui-state-hover');
			if (elem.hasClass('ui-datepicker-prev')) elem.addClass('ui-datepicker-prev-hover');
			if (elem.hasClass('ui-datepicker-next')) elem.addClass('ui-datepicker-next-hover');
		});
}

/* jQuery extend now ignores nulls! */
function extendRemove(target, props) {
	$.extend(target, props);
	for (var name in props)
		if (props[name] == null || props[name] == undefined)
			target[name] = props[name];
	return target;
};

/* Determine whether an object is an array. */
function isArray(a) {
	return (a && (($.browser.safari && typeof a == 'object' && a.length) ||
		(a.constructor && a.constructor.toString().match(/\Array\(\)/))));
};

/* Invoke the datepicker functionality.
   @param  options  string - a command, optionally followed by additional parameters or
                    Object - settings for attaching new datepicker functionality
   @return  jQuery object */
$.fn.datepicker = function(options){
	
	/* Verify an empty collection wasn't passed - Fixes #6976 */
	if ( !this.length ) {
		return this;
	}
	
	/* Initialise the date picker. */
	if (!$.datepicker.initialized) {
		$(document).mousedown($.datepicker._checkExternalClick).
			find('body').append($.datepicker.dpDiv);
		$.datepicker.initialized = true;
	}

	var otherArgs = Array.prototype.slice.call(arguments, 1);
	if (typeof options == 'string' && (options == 'isDisabled' || options == 'getDate' || options == 'widget'))
		return $.datepicker['_' + options + 'Datepicker'].
			apply($.datepicker, [this[0]].concat(otherArgs));
	if (options == 'option' && arguments.length == 2 && typeof arguments[1] == 'string')
		return $.datepicker['_' + options + 'Datepicker'].
			apply($.datepicker, [this[0]].concat(otherArgs));
	return this.each(function() {
		typeof options == 'string' ?
			$.datepicker['_' + options + 'Datepicker'].
				apply($.datepicker, [this].concat(otherArgs)) :
			$.datepicker._attachDatepicker(this, options);
	});
};

$.datepicker = new Datepicker(); // singleton instance
$.datepicker.initialized = false;
$.datepicker.uuid = new Date().getTime();
$.datepicker.version = "1.8.14";

// Workaround for #4055
// Add another global to avoid noConflict issues with inline event handlers
window['DP_jQuery_' + dpuuid] = $;

})(jQuery);
/*
 * jQuery UI Dialog 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Dialog
 *
 * Depends:
 *	jquery.ui.core.js
 *	jquery.ui.widget.js
 *  jquery.ui.button.js
 *	jquery.ui.draggable.js
 *	jquery.ui.mouse.js
 *	jquery.ui.position.js
 *	jquery.ui.resizable.js
 */
(function( $, undefined ) {

var uiDialogClasses =
		'ui-dialog ' +
		'ui-widget ' +
		'ui-widget-content ' +
		'ui-corner-all ',
	sizeRelatedOptions = {
		buttons: true,
		height: true,
		maxHeight: true,
		maxWidth: true,
		minHeight: true,
		minWidth: true,
		width: true
	},
	resizableRelatedOptions = {
		maxHeight: true,
		maxWidth: true,
		minHeight: true,
		minWidth: true
	},
	// support for jQuery 1.3.2 - handle common attrFn methods for dialog
	attrFn = $.attrFn || {
		val: true,
		css: true,
		html: true,
		text: true,
		data: true,
		width: true,
		height: true,
		offset: true,
		click: true
	};

$.widget("ui.dialog", {
	options: {
		autoOpen: true,
		buttons: {},
		closeOnEscape: true,
		closeText: 'close',
		dialogClass: '',
		draggable: true,
		hide: null,
		height: 'auto',
		maxHeight: false,
		maxWidth: false,
		minHeight: 150,
		minWidth: 150,
		modal: false,
		position: {
			my: 'center',
			at: 'center',
			collision: 'fit',
			// ensure that the titlebar is never outside the document
			using: function(pos) {
				var topOffset = $(this).css(pos).offset().top;
				if (topOffset < 0) {
					$(this).css('top', pos.top - topOffset);
				}
			}
		},
		resizable: true,
		show: null,
		stack: true,
		title: '',
		width: 300,
		zIndex: 1000
	},

	_create: function() {
		this.originalTitle = this.element.attr('title');
		// #5742 - .attr() might return a DOMElement
		if ( typeof this.originalTitle !== "string" ) {
			this.originalTitle = "";
		}

		this.options.title = this.options.title || this.originalTitle;
		var self = this,
			options = self.options,

			title = options.title || '&#160;',
			titleId = $.ui.dialog.getTitleId(self.element),

			uiDialog = (self.uiDialog = $('<div></div>'))
				.appendTo(document.body)
				.hide()
				.addClass(uiDialogClasses + options.dialogClass)
				.css({
					zIndex: options.zIndex
				})
				// setting tabIndex makes the div focusable
				// setting outline to 0 prevents a border on focus in Mozilla
				.attr('tabIndex', -1).css('outline', 0).keydown(function(event) {
					if (options.closeOnEscape && event.keyCode &&
						event.keyCode === $.ui.keyCode.ESCAPE) {
						
						self.close(event);
						event.preventDefault();
					}
				})
				.attr({
					role: 'dialog',
					'aria-labelledby': titleId
				})
				.mousedown(function(event) {
					self.moveToTop(false, event);
				}),

			uiDialogContent = self.element
				.show()
				.removeAttr('title')
				.addClass(
					'ui-dialog-content ' +
					'ui-widget-content')
				.appendTo(uiDialog),

			uiDialogTitlebar = (self.uiDialogTitlebar = $('<div></div>'))
				.addClass(
					'ui-dialog-titlebar ' +
					'ui-widget-header ' +
					'ui-corner-all ' +
					'ui-helper-clearfix'
				)
				.prependTo(uiDialog),

			uiDialogTitlebarClose = $('<a href="#"></a>')
				.addClass(
					'ui-dialog-titlebar-close ' +
					'ui-corner-all'
				)
				.attr('role', 'button')
				.hover(
					function() {
						uiDialogTitlebarClose.addClass('ui-state-hover');
					},
					function() {
						uiDialogTitlebarClose.removeClass('ui-state-hover');
					}
				)
				.focus(function() {
					uiDialogTitlebarClose.addClass('ui-state-focus');
				})
				.blur(function() {
					uiDialogTitlebarClose.removeClass('ui-state-focus');
				})
				.click(function(event) {
					self.close(event);
					return false;
				})
				.appendTo(uiDialogTitlebar),

			uiDialogTitlebarCloseText = (self.uiDialogTitlebarCloseText = $('<span></span>'))
				.addClass(
					'ui-icon ' +
					'ui-icon-closethick'
				)
				.text(options.closeText)
				.appendTo(uiDialogTitlebarClose),

			uiDialogTitle = $('<span></span>')
				.addClass('ui-dialog-title')
				.attr('id', titleId)
				.html(title)
				.prependTo(uiDialogTitlebar);

		//handling of deprecated beforeclose (vs beforeClose) option
		//Ticket #4669 http://dev.jqueryui.com/ticket/4669
		//TODO: remove in 1.9pre
		if ($.isFunction(options.beforeclose) && !$.isFunction(options.beforeClose)) {
			options.beforeClose = options.beforeclose;
		}

		uiDialogTitlebar.find("*").add(uiDialogTitlebar).disableSelection();

		if (options.draggable && $.fn.draggable) {
			self._makeDraggable();
		}
		if (options.resizable && $.fn.resizable) {
			self._makeResizable();
		}

		self._createButtons(options.buttons);
		self._isOpen = false;

		if ($.fn.bgiframe) {
			uiDialog.bgiframe();
		}
	},

	_init: function() {
		if ( this.options.autoOpen ) {
			this.open();
		}
	},

	destroy: function() {
		var self = this;
		
		if (self.overlay) {
			self.overlay.destroy();
		}
		self.uiDialog.hide();
		self.element
			.unbind('.dialog')
			.removeData('dialog')
			.removeClass('ui-dialog-content ui-widget-content')
			.hide().appendTo('body');
		self.uiDialog.remove();

		if (self.originalTitle) {
			self.element.attr('title', self.originalTitle);
		}

		return self;
	},

	widget: function() {
		return this.uiDialog;
	},

	close: function(event) {
		var self = this,
			maxZ, thisZ;
		
		if (false === self._trigger('beforeClose', event)) {
			return;
		}

		if (self.overlay) {
			self.overlay.destroy();
		}
		self.uiDialog.unbind('keypress.ui-dialog');

		self._isOpen = false;

		if (self.options.hide) {
			self.uiDialog.hide(self.options.hide, function() {
				self._trigger('close', event);
			});
		} else {
			self.uiDialog.hide();
			self._trigger('close', event);
		}

		$.ui.dialog.overlay.resize();

		// adjust the maxZ to allow other modal dialogs to continue to work (see #4309)
		if (self.options.modal) {
			maxZ = 0;
			$('.ui-dialog').each(function() {
				if (this !== self.uiDialog[0]) {
					thisZ = $(this).css('z-index');
					if(!isNaN(thisZ)) {
						maxZ = Math.max(maxZ, thisZ);
					}
				}
			});
			$.ui.dialog.maxZ = maxZ;
		}

		return self;
	},

	isOpen: function() {
		return this._isOpen;
	},

	// the force parameter allows us to move modal dialogs to their correct
	// position on open
	moveToTop: function(force, event) {
		var self = this,
			options = self.options,
			saveScroll;

		if ((options.modal && !force) ||
			(!options.stack && !options.modal)) {
			return self._trigger('focus', event);
		}

		if (options.zIndex > $.ui.dialog.maxZ) {
			$.ui.dialog.maxZ = options.zIndex;
		}
		if (self.overlay) {
			$.ui.dialog.maxZ += 1;
			self.overlay.$el.css('z-index', $.ui.dialog.overlay.maxZ = $.ui.dialog.maxZ);
		}

		//Save and then restore scroll since Opera 9.5+ resets when parent z-Index is changed.
		//  http://ui.jquery.com/bugs/ticket/3193
		saveScroll = { scrollTop: self.element.attr('scrollTop'), scrollLeft: self.element.attr('scrollLeft') };
		$.ui.dialog.maxZ += 1;
		self.uiDialog.css('z-index', $.ui.dialog.maxZ);
		self.element.attr(saveScroll);
		self._trigger('focus', event);

		return self;
	},

	open: function() {
		if (this._isOpen) { return; }

		var self = this,
			options = self.options,
			uiDialog = self.uiDialog;

		self.overlay = options.modal ? new $.ui.dialog.overlay(self) : null;
		self._size();
		self._position(options.position);
		uiDialog.show(options.show);
		self.moveToTop(true);

		// prevent tabbing out of modal dialogs
		if (options.modal) {
			uiDialog.bind('keypress.ui-dialog', function(event) {
				if (event.keyCode !== $.ui.keyCode.TAB) {
					return;
				}

				var tabbables = $(':tabbable', this),
					first = tabbables.filter(':first'),
					last  = tabbables.filter(':last');

				if (event.target === last[0] && !event.shiftKey) {
					first.focus(1);
					return false;
				} else if (event.target === first[0] && event.shiftKey) {
					last.focus(1);
					return false;
				}
			});
		}

		// set focus to the first tabbable element in the content area or the first button
		// if there are no tabbable elements, set focus on the dialog itself
		$(self.element.find(':tabbable').get().concat(
			uiDialog.find('.ui-dialog-buttonpane :tabbable').get().concat(
				uiDialog.get()))).eq(0).focus();

		self._isOpen = true;
		self._trigger('open');

		return self;
	},

	_createButtons: function(buttons) {
		var self = this,
			hasButtons = false,
			uiDialogButtonPane = $('<div></div>')
				.addClass(
					'ui-dialog-buttonpane ' +
					'ui-widget-content ' +
					'ui-helper-clearfix'
				),
			uiButtonSet = $( "<div></div>" )
				.addClass( "ui-dialog-buttonset" )
				.appendTo( uiDialogButtonPane );

		// if we already have a button pane, remove it
		self.uiDialog.find('.ui-dialog-buttonpane').remove();

		if (typeof buttons === 'object' && buttons !== null) {
			$.each(buttons, function() {
				return !(hasButtons = true);
			});
		}
		if (hasButtons) {
			$.each(buttons, function(name, props) {
				props = $.isFunction( props ) ?
					{ click: props, text: name } :
					props;
				var button = $('<button type="button"></button>')
					.click(function() {
						props.click.apply(self.element[0], arguments);
					})
					.appendTo(uiButtonSet);
				// can't use .attr( props, true ) with jQuery 1.3.2.
				$.each( props, function( key, value ) {
					if ( key === "click" ) {
						return;
					}
					if ( key in attrFn ) {
						button[ key ]( value );
					} else {
						button.attr( key, value );
					}
				});
				if ($.fn.button) {
					button.button();
				}
			});
			uiDialogButtonPane.appendTo(self.uiDialog);
		}
	},

	_makeDraggable: function() {
		var self = this,
			options = self.options,
			doc = $(document),
			heightBeforeDrag;

		function filteredUi(ui) {
			return {
				position: ui.position,
				offset: ui.offset
			};
		}

		self.uiDialog.draggable({
			cancel: '.ui-dialog-content, .ui-dialog-titlebar-close',
			handle: '.ui-dialog-titlebar',
			containment: 'document',
			start: function(event, ui) {
				heightBeforeDrag = options.height === "auto" ? "auto" : $(this).height();
				$(this).height($(this).height()).addClass("ui-dialog-dragging");
				self._trigger('dragStart', event, filteredUi(ui));
			},
			drag: function(event, ui) {
				self._trigger('drag', event, filteredUi(ui));
			},
			stop: function(event, ui) {
				options.position = [ui.position.left - doc.scrollLeft(),
					ui.position.top - doc.scrollTop()];
				$(this).removeClass("ui-dialog-dragging").height(heightBeforeDrag);
				self._trigger('dragStop', event, filteredUi(ui));
				$.ui.dialog.overlay.resize();
			}
		});
	},

	_makeResizable: function(handles) {
		handles = (handles === undefined ? this.options.resizable : handles);
		var self = this,
			options = self.options,
			// .ui-resizable has position: relative defined in the stylesheet
			// but dialogs have to use absolute or fixed positioning
			position = self.uiDialog.css('position'),
			resizeHandles = (typeof handles === 'string' ?
				handles	:
				'n,e,s,w,se,sw,ne,nw'
			);

		function filteredUi(ui) {
			return {
				originalPosition: ui.originalPosition,
				originalSize: ui.originalSize,
				position: ui.position,
				size: ui.size
			};
		}

		self.uiDialog.resizable({
			cancel: '.ui-dialog-content',
			containment: 'document',
			alsoResize: self.element,
			maxWidth: options.maxWidth,
			maxHeight: options.maxHeight,
			minWidth: options.minWidth,
			minHeight: self._minHeight(),
			handles: resizeHandles,
			start: function(event, ui) {
				$(this).addClass("ui-dialog-resizing");
				self._trigger('resizeStart', event, filteredUi(ui));
			},
			resize: function(event, ui) {
				self._trigger('resize', event, filteredUi(ui));
			},
			stop: function(event, ui) {
				$(this).removeClass("ui-dialog-resizing");
				options.height = $(this).height();
				options.width = $(this).width();
				self._trigger('resizeStop', event, filteredUi(ui));
				$.ui.dialog.overlay.resize();
			}
		})
		.css('position', position)
		.find('.ui-resizable-se').addClass('ui-icon ui-icon-grip-diagonal-se');
	},

	_minHeight: function() {
		var options = this.options;

		if (options.height === 'auto') {
			return options.minHeight;
		} else {
			return Math.min(options.minHeight, options.height);
		}
	},

	_position: function(position) {
		var myAt = [],
			offset = [0, 0],
			isVisible;

		if (position) {
			// deep extending converts arrays to objects in jQuery <= 1.3.2 :-(
	//		if (typeof position == 'string' || $.isArray(position)) {
	//			myAt = $.isArray(position) ? position : position.split(' ');

			if (typeof position === 'string' || (typeof position === 'object' && '0' in position)) {
				myAt = position.split ? position.split(' ') : [position[0], position[1]];
				if (myAt.length === 1) {
					myAt[1] = myAt[0];
				}

				$.each(['left', 'top'], function(i, offsetPosition) {
					if (+myAt[i] === myAt[i]) {
						offset[i] = myAt[i];
						myAt[i] = offsetPosition;
					}
				});

				position = {
					my: myAt.join(" "),
					at: myAt.join(" "),
					offset: offset.join(" ")
				};
			} 

			position = $.extend({}, $.ui.dialog.prototype.options.position, position);
		} else {
			position = $.ui.dialog.prototype.options.position;
		}

		// need to show the dialog to get the actual offset in the position plugin
		isVisible = this.uiDialog.is(':visible');
		if (!isVisible) {
			this.uiDialog.show();
		}
		this.uiDialog
			// workaround for jQuery bug #5781 http://dev.jquery.com/ticket/5781
			.css({ top: 0, left: 0 })
			.position($.extend({ of: window }, position));
		if (!isVisible) {
			this.uiDialog.hide();
		}
	},

	_setOptions: function( options ) {
		var self = this,
			resizableOptions = {},
			resize = false;

		$.each( options, function( key, value ) {
			self._setOption( key, value );
			
			if ( key in sizeRelatedOptions ) {
				resize = true;
			}
			if ( key in resizableRelatedOptions ) {
				resizableOptions[ key ] = value;
			}
		});

		if ( resize ) {
			this._size();
		}
		if ( this.uiDialog.is( ":data(resizable)" ) ) {
			this.uiDialog.resizable( "option", resizableOptions );
		}
	},

	_setOption: function(key, value){
		var self = this,
			uiDialog = self.uiDialog;

		switch (key) {
			//handling of deprecated beforeclose (vs beforeClose) option
			//Ticket #4669 http://dev.jqueryui.com/ticket/4669
			//TODO: remove in 1.9pre
			case "beforeclose":
				key = "beforeClose";
				break;
			case "buttons":
				self._createButtons(value);
				break;
			case "closeText":
				// ensure that we always pass a string
				self.uiDialogTitlebarCloseText.text("" + value);
				break;
			case "dialogClass":
				uiDialog
					.removeClass(self.options.dialogClass)
					.addClass(uiDialogClasses + value);
				break;
			case "disabled":
				if (value) {
					uiDialog.addClass('ui-dialog-disabled');
				} else {
					uiDialog.removeClass('ui-dialog-disabled');
				}
				break;
			case "draggable":
				var isDraggable = uiDialog.is( ":data(draggable)" );
				if ( isDraggable && !value ) {
					uiDialog.draggable( "destroy" );
				}
				
				if ( !isDraggable && value ) {
					self._makeDraggable();
				}
				break;
			case "position":
				self._position(value);
				break;
			case "resizable":
				// currently resizable, becoming non-resizable
				var isResizable = uiDialog.is( ":data(resizable)" );
				if (isResizable && !value) {
					uiDialog.resizable('destroy');
				}

				// currently resizable, changing handles
				if (isResizable && typeof value === 'string') {
					uiDialog.resizable('option', 'handles', value);
				}

				// currently non-resizable, becoming resizable
				if (!isResizable && value !== false) {
					self._makeResizable(value);
				}
				break;
			case "title":
				// convert whatever was passed in o a string, for html() to not throw up
				$(".ui-dialog-title", self.uiDialogTitlebar).html("" + (value || '&#160;'));
				break;
		}

		$.Widget.prototype._setOption.apply(self, arguments);
	},

	_size: function() {
		/* If the user has resized the dialog, the .ui-dialog and .ui-dialog-content
		 * divs will both have width and height set, so we need to reset them
		 */
		var options = this.options,
			nonContentHeight,
			minContentHeight,
			isVisible = this.uiDialog.is( ":visible" );

		// reset content sizing
		this.element.show().css({
			width: 'auto',
			minHeight: 0,
			height: 0
		});

		if (options.minWidth > options.width) {
			options.width = options.minWidth;
		}

		// reset wrapper sizing
		// determine the height of all the non-content elements
		nonContentHeight = this.uiDialog.css({
				height: 'auto',
				width: options.width
			})
			.height();
		minContentHeight = Math.max( 0, options.minHeight - nonContentHeight );
		
		if ( options.height === "auto" ) {
			// only needed for IE6 support
			if ( $.support.minHeight ) {
				this.element.css({
					minHeight: minContentHeight,
					height: "auto"
				});
			} else {
				this.uiDialog.show();
				var autoHeight = this.element.css( "height", "auto" ).height();
				if ( !isVisible ) {
					this.uiDialog.hide();
				}
				this.element.height( Math.max( autoHeight, minContentHeight ) );
			}
		} else {
			this.element.height( Math.max( options.height - nonContentHeight, 0 ) );
		}

		if (this.uiDialog.is(':data(resizable)')) {
			this.uiDialog.resizable('option', 'minHeight', this._minHeight());
		}
	}
});

$.extend($.ui.dialog, {
	version: "1.8.14",

	uuid: 0,
	maxZ: 0,

	getTitleId: function($el) {
		var id = $el.attr('id');
		if (!id) {
			this.uuid += 1;
			id = this.uuid;
		}
		return 'ui-dialog-title-' + id;
	},

	overlay: function(dialog) {
		this.$el = $.ui.dialog.overlay.create(dialog);
	}
});

$.extend($.ui.dialog.overlay, {
	instances: [],
	// reuse old instances due to IE memory leak with alpha transparency (see #5185)
	oldInstances: [],
	maxZ: 0,
	events: $.map('focus,mousedown,mouseup,keydown,keypress,click'.split(','),
		function(event) { return event + '.dialog-overlay'; }).join(' '),
	create: function(dialog) {
		if (this.instances.length === 0) {
			// prevent use of anchors and inputs
			// we use a setTimeout in case the overlay is created from an
			// event that we're going to be cancelling (see #2804)
			setTimeout(function() {
				// handle $(el).dialog().dialog('close') (see #4065)
				if ($.ui.dialog.overlay.instances.length) {
					$(document).bind($.ui.dialog.overlay.events, function(event) {
						// stop events if the z-index of the target is < the z-index of the overlay
						// we cannot return true when we don't want to cancel the event (#3523)
						if ($(event.target).zIndex() < $.ui.dialog.overlay.maxZ) {
							return false;
						}
					});
				}
			}, 1);

			// allow closing by pressing the escape key
			$(document).bind('keydown.dialog-overlay', function(event) {
				if (dialog.options.closeOnEscape && event.keyCode &&
					event.keyCode === $.ui.keyCode.ESCAPE) {
					
					dialog.close(event);
					event.preventDefault();
				}
			});

			// handle window resize
			$(window).bind('resize.dialog-overlay', $.ui.dialog.overlay.resize);
		}

		var $el = (this.oldInstances.pop() || $('<div></div>').addClass('ui-widget-overlay'))
			.appendTo(document.body)
			.css({
				width: this.width(),
				height: this.height()
			});

		if ($.fn.bgiframe) {
			$el.bgiframe();
		}

		this.instances.push($el);
		return $el;
	},

	destroy: function($el) {
		var indexOf = $.inArray($el, this.instances);
		if (indexOf != -1){
			this.oldInstances.push(this.instances.splice(indexOf, 1)[0]);
		}

		if (this.instances.length === 0) {
			$([document, window]).unbind('.dialog-overlay');
		}

		$el.remove();
		
		// adjust the maxZ to allow other modal dialogs to continue to work (see #4309)
		var maxZ = 0;
		$.each(this.instances, function() {
			maxZ = Math.max(maxZ, this.css('z-index'));
		});
		this.maxZ = maxZ;
	},

	height: function() {
		var scrollHeight,
			offsetHeight;
		// handle IE 6
		if ($.browser.msie && $.browser.version < 7) {
			scrollHeight = Math.max(
				document.documentElement.scrollHeight,
				document.body.scrollHeight
			);
			offsetHeight = Math.max(
				document.documentElement.offsetHeight,
				document.body.offsetHeight
			);

			if (scrollHeight < offsetHeight) {
				return $(window).height() + 'px';
			} else {
				return scrollHeight + 'px';
			}
		// handle "good" browsers
		} else {
			return $(document).height() + 'px';
		}
	},

	width: function() {
		var scrollWidth,
			offsetWidth;
		// handle IE
		if ( $.browser.msie ) {
			scrollWidth = Math.max(
				document.documentElement.scrollWidth,
				document.body.scrollWidth
			);
			offsetWidth = Math.max(
				document.documentElement.offsetWidth,
				document.body.offsetWidth
			);

			if (scrollWidth < offsetWidth) {
				return $(window).width() + 'px';
			} else {
				return scrollWidth + 'px';
			}
		// handle "good" browsers
		} else {
			return $(document).width() + 'px';
		}
	},

	resize: function() {
		/* If the dialog is draggable and the user drags it past the
		 * right edge of the window, the document becomes wider so we
		 * need to stretch the overlay. If the user then drags the
		 * dialog back to the left, the document will become narrower,
		 * so we need to shrink the overlay to the appropriate size.
		 * This is handled by shrinking the overlay before setting it
		 * to the full document size.
		 */
		var $overlays = $([]);
		$.each($.ui.dialog.overlay.instances, function() {
			$overlays = $overlays.add(this);
		});

		$overlays.css({
			width: 0,
			height: 0
		}).css({
			width: $.ui.dialog.overlay.width(),
			height: $.ui.dialog.overlay.height()
		});
	}
});

$.extend($.ui.dialog.overlay.prototype, {
	destroy: function() {
		$.ui.dialog.overlay.destroy(this.$el);
	}
});

}(jQuery));
/*
 * jQuery UI Position 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Position
 */
(function( $, undefined ) {

$.ui = $.ui || {};

var horizontalPositions = /left|center|right/,
	verticalPositions = /top|center|bottom/,
	center = "center",
	_position = $.fn.position,
	_offset = $.fn.offset;

$.fn.position = function( options ) {
	if ( !options || !options.of ) {
		return _position.apply( this, arguments );
	}

	// make a copy, we don't want to modify arguments
	options = $.extend( {}, options );

	var target = $( options.of ),
		targetElem = target[0],
		collision = ( options.collision || "flip" ).split( " " ),
		offset = options.offset ? options.offset.split( " " ) : [ 0, 0 ],
		targetWidth,
		targetHeight,
		basePosition;

	if ( targetElem.nodeType === 9 ) {
		targetWidth = target.width();
		targetHeight = target.height();
		basePosition = { top: 0, left: 0 };
	// TODO: use $.isWindow() in 1.9
	} else if ( targetElem.setTimeout ) {
		targetWidth = target.width();
		targetHeight = target.height();
		basePosition = { top: target.scrollTop(), left: target.scrollLeft() };
	} else if ( targetElem.preventDefault ) {
		// force left top to allow flipping
		options.at = "left top";
		targetWidth = targetHeight = 0;
		basePosition = { top: options.of.pageY, left: options.of.pageX };
	} else {
		targetWidth = target.outerWidth();
		targetHeight = target.outerHeight();
		basePosition = target.offset();
	}

	// force my and at to have valid horizontal and veritcal positions
	// if a value is missing or invalid, it will be converted to center 
	$.each( [ "my", "at" ], function() {
		var pos = ( options[this] || "" ).split( " " );
		if ( pos.length === 1) {
			pos = horizontalPositions.test( pos[0] ) ?
				pos.concat( [center] ) :
				verticalPositions.test( pos[0] ) ?
					[ center ].concat( pos ) :
					[ center, center ];
		}
		pos[ 0 ] = horizontalPositions.test( pos[0] ) ? pos[ 0 ] : center;
		pos[ 1 ] = verticalPositions.test( pos[1] ) ? pos[ 1 ] : center;
		options[ this ] = pos;
	});

	// normalize collision option
	if ( collision.length === 1 ) {
		collision[ 1 ] = collision[ 0 ];
	}

	// normalize offset option
	offset[ 0 ] = parseInt( offset[0], 10 ) || 0;
	if ( offset.length === 1 ) {
		offset[ 1 ] = offset[ 0 ];
	}
	offset[ 1 ] = parseInt( offset[1], 10 ) || 0;

	if ( options.at[0] === "right" ) {
		basePosition.left += targetWidth;
	} else if ( options.at[0] === center ) {
		basePosition.left += targetWidth / 2;
	}

	if ( options.at[1] === "bottom" ) {
		basePosition.top += targetHeight;
	} else if ( options.at[1] === center ) {
		basePosition.top += targetHeight / 2;
	}

	basePosition.left += offset[ 0 ];
	basePosition.top += offset[ 1 ];

	return this.each(function() {
		var elem = $( this ),
			elemWidth = elem.outerWidth(),
			elemHeight = elem.outerHeight(),
			marginLeft = parseInt( $.curCSS( this, "marginLeft", true ) ) || 0,
			marginTop = parseInt( $.curCSS( this, "marginTop", true ) ) || 0,
			collisionWidth = elemWidth + marginLeft +
				( parseInt( $.curCSS( this, "marginRight", true ) ) || 0 ),
			collisionHeight = elemHeight + marginTop +
				( parseInt( $.curCSS( this, "marginBottom", true ) ) || 0 ),
			position = $.extend( {}, basePosition ),
			collisionPosition;

		if ( options.my[0] === "right" ) {
			position.left -= elemWidth;
		} else if ( options.my[0] === center ) {
			position.left -= elemWidth / 2;
		}

		if ( options.my[1] === "bottom" ) {
			position.top -= elemHeight;
		} else if ( options.my[1] === center ) {
			position.top -= elemHeight / 2;
		}

		// prevent fractions (see #5280)
		position.left = Math.round( position.left );
		position.top = Math.round( position.top );

		collisionPosition = {
			left: position.left - marginLeft,
			top: position.top - marginTop
		};

		$.each( [ "left", "top" ], function( i, dir ) {
			if ( $.ui.position[ collision[i] ] ) {
				$.ui.position[ collision[i] ][ dir ]( position, {
					targetWidth: targetWidth,
					targetHeight: targetHeight,
					elemWidth: elemWidth,
					elemHeight: elemHeight,
					collisionPosition: collisionPosition,
					collisionWidth: collisionWidth,
					collisionHeight: collisionHeight,
					offset: offset,
					my: options.my,
					at: options.at
				});
			}
		});

		if ( $.fn.bgiframe ) {
			elem.bgiframe();
		}
		elem.offset( $.extend( position, { using: options.using } ) );
	});
};

$.ui.position = {
	fit: {
		left: function( position, data ) {
			var win = $( window ),
				over = data.collisionPosition.left + data.collisionWidth - win.width() - win.scrollLeft();
			position.left = over > 0 ? position.left - over : Math.max( position.left - data.collisionPosition.left, position.left );
		},
		top: function( position, data ) {
			var win = $( window ),
				over = data.collisionPosition.top + data.collisionHeight - win.height() - win.scrollTop();
			position.top = over > 0 ? position.top - over : Math.max( position.top - data.collisionPosition.top, position.top );
		}
	},

	flip: {
		left: function( position, data ) {
			if ( data.at[0] === center ) {
				return;
			}
			var win = $( window ),
				over = data.collisionPosition.left + data.collisionWidth - win.width() - win.scrollLeft(),
				myOffset = data.my[ 0 ] === "left" ?
					-data.elemWidth :
					data.my[ 0 ] === "right" ?
						data.elemWidth :
						0,
				atOffset = data.at[ 0 ] === "left" ?
					data.targetWidth :
					-data.targetWidth,
				offset = -2 * data.offset[ 0 ];
			position.left += data.collisionPosition.left < 0 ?
				myOffset + atOffset + offset :
				over > 0 ?
					myOffset + atOffset + offset :
					0;
		},
		top: function( position, data ) {
			if ( data.at[1] === center ) {
				return;
			}
			var win = $( window ),
				over = data.collisionPosition.top + data.collisionHeight - win.height() - win.scrollTop(),
				myOffset = data.my[ 1 ] === "top" ?
					-data.elemHeight :
					data.my[ 1 ] === "bottom" ?
						data.elemHeight :
						0,
				atOffset = data.at[ 1 ] === "top" ?
					data.targetHeight :
					-data.targetHeight,
				offset = -2 * data.offset[ 1 ];
			position.top += data.collisionPosition.top < 0 ?
				myOffset + atOffset + offset :
				over > 0 ?
					myOffset + atOffset + offset :
					0;
		}
	}
};

// offset setter from jQuery 1.4
if ( !$.offset.setOffset ) {
	$.offset.setOffset = function( elem, options ) {
		// set position first, in-case top/left are set even on static elem
		if ( /static/.test( $.curCSS( elem, "position" ) ) ) {
			elem.style.position = "relative";
		}
		var curElem   = $( elem ),
			curOffset = curElem.offset(),
			curTop    = parseInt( $.curCSS( elem, "top",  true ), 10 ) || 0,
			curLeft   = parseInt( $.curCSS( elem, "left", true ), 10)  || 0,
			props     = {
				top:  (options.top  - curOffset.top)  + curTop,
				left: (options.left - curOffset.left) + curLeft
			};
		
		if ( 'using' in options ) {
			options.using.call( elem, props );
		} else {
			curElem.css( props );
		}
	};

	$.fn.offset = function( options ) {
		var elem = this[ 0 ];
		if ( !elem || !elem.ownerDocument ) { return null; }
		if ( options ) { 
			return this.each(function() {
				$.offset.setOffset( this, options );
			});
		}
		return _offset.call( this );
	};
}

}( jQuery ));
/*
 * jQuery UI Progressbar 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Progressbar
 *
 * Depends:
 *   jquery.ui.core.js
 *   jquery.ui.widget.js
 */
(function( $, undefined ) {

$.widget( "ui.progressbar", {
	options: {
		value: 0,
		max: 100
	},

	min: 0,

	_create: function() {
		this.element
			.addClass( "ui-progressbar ui-widget ui-widget-content ui-corner-all" )
			.attr({
				role: "progressbar",
				"aria-valuemin": this.min,
				"aria-valuemax": this.options.max,
				"aria-valuenow": this._value()
			});

		this.valueDiv = $( "<div class='ui-progressbar-value ui-widget-header ui-corner-left'></div>" )
			.appendTo( this.element );

		this.oldValue = this._value();
		this._refreshValue();
	},

	destroy: function() {
		this.element
			.removeClass( "ui-progressbar ui-widget ui-widget-content ui-corner-all" )
			.removeAttr( "role" )
			.removeAttr( "aria-valuemin" )
			.removeAttr( "aria-valuemax" )
			.removeAttr( "aria-valuenow" );

		this.valueDiv.remove();

		$.Widget.prototype.destroy.apply( this, arguments );
	},

	value: function( newValue ) {
		if ( newValue === undefined ) {
			return this._value();
		}

		this._setOption( "value", newValue );
		return this;
	},

	_setOption: function( key, value ) {
		if ( key === "value" ) {
			this.options.value = value;
			this._refreshValue();
			if ( this._value() === this.options.max ) {
				this._trigger( "complete" );
			}
		}

		$.Widget.prototype._setOption.apply( this, arguments );
	},

	_value: function() {
		var val = this.options.value;
		// normalize invalid value
		if ( typeof val !== "number" ) {
			val = 0;
		}
		return Math.min( this.options.max, Math.max( this.min, val ) );
	},

	_percentage: function() {
		return 100 * this._value() / this.options.max;
	},

	_refreshValue: function() {
		var value = this.value();
		var percentage = this._percentage();

		if ( this.oldValue !== value ) {
			this.oldValue = value;
			this._trigger( "change" );
		}

		this.valueDiv
			.toggle( value > this.min )
			.toggleClass( "ui-corner-right", value === this.options.max )
			.width( percentage.toFixed(0) + "%" );
		this.element.attr( "aria-valuenow", value );
	}
});

$.extend( $.ui.progressbar, {
	version: "1.8.14"
});

})( jQuery );
/*
 * jQuery UI Slider 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Slider
 *
 * Depends:
 *	jquery.ui.core.js
 *	jquery.ui.mouse.js
 *	jquery.ui.widget.js
 */
(function( $, undefined ) {

// number of pages in a slider
// (how many times can you page up/down to go through the whole range)
var numPages = 5;

$.widget( "ui.slider", $.ui.mouse, {

	widgetEventPrefix: "slide",

	options: {
		animate: false,
		distance: 0,
		max: 100,
		min: 0,
		orientation: "horizontal",
		range: false,
		step: 1,
		value: 0,
		values: null
	},

	_create: function() {
		var self = this,
			o = this.options,
			existingHandles = this.element.find( ".ui-slider-handle" ).addClass( "ui-state-default ui-corner-all" ),
			handle = "<a class='ui-slider-handle ui-state-default ui-corner-all' href='#'></a>",
			handleCount = ( o.values && o.values.length ) || 1,
			handles = [];

		this._keySliding = false;
		this._mouseSliding = false;
		this._animateOff = true;
		this._handleIndex = null;
		this._detectOrientation();
		this._mouseInit();

		this.element
			.addClass( "ui-slider" +
				" ui-slider-" + this.orientation +
				" ui-widget" +
				" ui-widget-content" +
				" ui-corner-all" +
				( o.disabled ? " ui-slider-disabled ui-disabled" : "" ) );

		this.range = $([]);

		if ( o.range ) {
			if ( o.range === true ) {
				if ( !o.values ) {
					o.values = [ this._valueMin(), this._valueMin() ];
				}
				if ( o.values.length && o.values.length !== 2 ) {
					o.values = [ o.values[0], o.values[0] ];
				}
			}

			this.range = $( "<div></div>" )
				.appendTo( this.element )
				.addClass( "ui-slider-range" +
				// note: this isn't the most fittingly semantic framework class for this element,
				// but worked best visually with a variety of themes
				" ui-widget-header" + 
				( ( o.range === "min" || o.range === "max" ) ? " ui-slider-range-" + o.range : "" ) );
		}

		for ( var i = existingHandles.length; i < handleCount; i += 1 ) {
			handles.push( handle );
		}

		this.handles = existingHandles.add( $( handles.join( "" ) ).appendTo( self.element ) );

		this.handle = this.handles.eq( 0 );

		this.handles.add( this.range ).filter( "a" )
			.click(function( event ) {
				event.preventDefault();
			})
			.hover(function() {
				if ( !o.disabled ) {
					$( this ).addClass( "ui-state-hover" );
				}
			}, function() {
				$( this ).removeClass( "ui-state-hover" );
			})
			.focus(function() {
				if ( !o.disabled ) {
					$( ".ui-slider .ui-state-focus" ).removeClass( "ui-state-focus" );
					$( this ).addClass( "ui-state-focus" );
				} else {
					$( this ).blur();
				}
			})
			.blur(function() {
				$( this ).removeClass( "ui-state-focus" );
			});

		this.handles.each(function( i ) {
			$( this ).data( "index.ui-slider-handle", i );
		});

		this.handles
			.keydown(function( event ) {
				var ret = true,
					index = $( this ).data( "index.ui-slider-handle" ),
					allowed,
					curVal,
					newVal,
					step;
	
				if ( self.options.disabled ) {
					return;
				}
	
				switch ( event.keyCode ) {
					case $.ui.keyCode.HOME:
					case $.ui.keyCode.END:
					case $.ui.keyCode.PAGE_UP:
					case $.ui.keyCode.PAGE_DOWN:
					case $.ui.keyCode.UP:
					case $.ui.keyCode.RIGHT:
					case $.ui.keyCode.DOWN:
					case $.ui.keyCode.LEFT:
						ret = false;
						if ( !self._keySliding ) {
							self._keySliding = true;
							$( this ).addClass( "ui-state-active" );
							allowed = self._start( event, index );
							if ( allowed === false ) {
								return;
							}
						}
						break;
				}
	
				step = self.options.step;
				if ( self.options.values && self.options.values.length ) {
					curVal = newVal = self.values( index );
				} else {
					curVal = newVal = self.value();
				}
	
				switch ( event.keyCode ) {
					case $.ui.keyCode.HOME:
						newVal = self._valueMin();
						break;
					case $.ui.keyCode.END:
						newVal = self._valueMax();
						break;
					case $.ui.keyCode.PAGE_UP:
						newVal = self._trimAlignValue( curVal + ( (self._valueMax() - self._valueMin()) / numPages ) );
						break;
					case $.ui.keyCode.PAGE_DOWN:
						newVal = self._trimAlignValue( curVal - ( (self._valueMax() - self._valueMin()) / numPages ) );
						break;
					case $.ui.keyCode.UP:
					case $.ui.keyCode.RIGHT:
						if ( curVal === self._valueMax() ) {
							return;
						}
						newVal = self._trimAlignValue( curVal + step );
						break;
					case $.ui.keyCode.DOWN:
					case $.ui.keyCode.LEFT:
						if ( curVal === self._valueMin() ) {
							return;
						}
						newVal = self._trimAlignValue( curVal - step );
						break;
				}
	
				self._slide( event, index, newVal );
	
				return ret;
	
			})
			.keyup(function( event ) {
				var index = $( this ).data( "index.ui-slider-handle" );
	
				if ( self._keySliding ) {
					self._keySliding = false;
					self._stop( event, index );
					self._change( event, index );
					$( this ).removeClass( "ui-state-active" );
				}
	
			});

		this._refreshValue();

		this._animateOff = false;
	},

	destroy: function() {
		this.handles.remove();
		this.range.remove();

		this.element
			.removeClass( "ui-slider" +
				" ui-slider-horizontal" +
				" ui-slider-vertical" +
				" ui-slider-disabled" +
				" ui-widget" +
				" ui-widget-content" +
				" ui-corner-all" )
			.removeData( "slider" )
			.unbind( ".slider" );

		this._mouseDestroy();

		return this;
	},

	_mouseCapture: function( event ) {
		var o = this.options,
			position,
			normValue,
			distance,
			closestHandle,
			self,
			index,
			allowed,
			offset,
			mouseOverHandle;

		if ( o.disabled ) {
			return false;
		}

		this.elementSize = {
			width: this.element.outerWidth(),
			height: this.element.outerHeight()
		};
		this.elementOffset = this.element.offset();

		position = { x: event.pageX, y: event.pageY };
		normValue = this._normValueFromMouse( position );
		distance = this._valueMax() - this._valueMin() + 1;
		self = this;
		this.handles.each(function( i ) {
			var thisDistance = Math.abs( normValue - self.values(i) );
			if ( distance > thisDistance ) {
				distance = thisDistance;
				closestHandle = $( this );
				index = i;
			}
		});

		// workaround for bug #3736 (if both handles of a range are at 0,
		// the first is always used as the one with least distance,
		// and moving it is obviously prevented by preventing negative ranges)
		if( o.range === true && this.values(1) === o.min ) {
			index += 1;
			closestHandle = $( this.handles[index] );
		}

		allowed = this._start( event, index );
		if ( allowed === false ) {
			return false;
		}
		this._mouseSliding = true;

		self._handleIndex = index;

		closestHandle
			.addClass( "ui-state-active" )
			.focus();
		
		offset = closestHandle.offset();
		mouseOverHandle = !$( event.target ).parents().andSelf().is( ".ui-slider-handle" );
		this._clickOffset = mouseOverHandle ? { left: 0, top: 0 } : {
			left: event.pageX - offset.left - ( closestHandle.width() / 2 ),
			top: event.pageY - offset.top -
				( closestHandle.height() / 2 ) -
				( parseInt( closestHandle.css("borderTopWidth"), 10 ) || 0 ) -
				( parseInt( closestHandle.css("borderBottomWidth"), 10 ) || 0) +
				( parseInt( closestHandle.css("marginTop"), 10 ) || 0)
		};

		if ( !this.handles.hasClass( "ui-state-hover" ) ) {
			this._slide( event, index, normValue );
		}
		this._animateOff = true;
		return true;
	},

	_mouseStart: function( event ) {
		return true;
	},

	_mouseDrag: function( event ) {
		var position = { x: event.pageX, y: event.pageY },
			normValue = this._normValueFromMouse( position );
		
		this._slide( event, this._handleIndex, normValue );

		return false;
	},

	_mouseStop: function( event ) {
		this.handles.removeClass( "ui-state-active" );
		this._mouseSliding = false;

		this._stop( event, this._handleIndex );
		this._change( event, this._handleIndex );

		this._handleIndex = null;
		this._clickOffset = null;
		this._animateOff = false;

		return false;
	},
	
	_detectOrientation: function() {
		this.orientation = ( this.options.orientation === "vertical" ) ? "vertical" : "horizontal";
	},

	_normValueFromMouse: function( position ) {
		var pixelTotal,
			pixelMouse,
			percentMouse,
			valueTotal,
			valueMouse;

		if ( this.orientation === "horizontal" ) {
			pixelTotal = this.elementSize.width;
			pixelMouse = position.x - this.elementOffset.left - ( this._clickOffset ? this._clickOffset.left : 0 );
		} else {
			pixelTotal = this.elementSize.height;
			pixelMouse = position.y - this.elementOffset.top - ( this._clickOffset ? this._clickOffset.top : 0 );
		}

		percentMouse = ( pixelMouse / pixelTotal );
		if ( percentMouse > 1 ) {
			percentMouse = 1;
		}
		if ( percentMouse < 0 ) {
			percentMouse = 0;
		}
		if ( this.orientation === "vertical" ) {
			percentMouse = 1 - percentMouse;
		}

		valueTotal = this._valueMax() - this._valueMin();
		valueMouse = this._valueMin() + percentMouse * valueTotal;

		return this._trimAlignValue( valueMouse );
	},

	_start: function( event, index ) {
		var uiHash = {
			handle: this.handles[ index ],
			value: this.value()
		};
		if ( this.options.values && this.options.values.length ) {
			uiHash.value = this.values( index );
			uiHash.values = this.values();
		}
		return this._trigger( "start", event, uiHash );
	},

	_slide: function( event, index, newVal ) {
		var otherVal,
			newValues,
			allowed;

		if ( this.options.values && this.options.values.length ) {
			otherVal = this.values( index ? 0 : 1 );

			if ( ( this.options.values.length === 2 && this.options.range === true ) && 
					( ( index === 0 && newVal > otherVal) || ( index === 1 && newVal < otherVal ) )
				) {
				newVal = otherVal;
			}

			if ( newVal !== this.values( index ) ) {
				newValues = this.values();
				newValues[ index ] = newVal;
				// A slide can be canceled by returning false from the slide callback
				allowed = this._trigger( "slide", event, {
					handle: this.handles[ index ],
					value: newVal,
					values: newValues
				} );
				otherVal = this.values( index ? 0 : 1 );
				if ( allowed !== false ) {
					this.values( index, newVal, true );
				}
			}
		} else {
			if ( newVal !== this.value() ) {
				// A slide can be canceled by returning false from the slide callback
				allowed = this._trigger( "slide", event, {
					handle: this.handles[ index ],
					value: newVal
				} );
				if ( allowed !== false ) {
					this.value( newVal );
				}
			}
		}
	},

	_stop: function( event, index ) {
		var uiHash = {
			handle: this.handles[ index ],
			value: this.value()
		};
		if ( this.options.values && this.options.values.length ) {
			uiHash.value = this.values( index );
			uiHash.values = this.values();
		}

		this._trigger( "stop", event, uiHash );
	},

	_change: function( event, index ) {
		if ( !this._keySliding && !this._mouseSliding ) {
			var uiHash = {
				handle: this.handles[ index ],
				value: this.value()
			};
			if ( this.options.values && this.options.values.length ) {
				uiHash.value = this.values( index );
				uiHash.values = this.values();
			}

			this._trigger( "change", event, uiHash );
		}
	},

	value: function( newValue ) {
		if ( arguments.length ) {
			this.options.value = this._trimAlignValue( newValue );
			this._refreshValue();
			this._change( null, 0 );
			return;
		}

		return this._value();
	},

	values: function( index, newValue ) {
		var vals,
			newValues,
			i;

		if ( arguments.length > 1 ) {
			this.options.values[ index ] = this._trimAlignValue( newValue );
			this._refreshValue();
			this._change( null, index );
			return;
		}

		if ( arguments.length ) {
			if ( $.isArray( arguments[ 0 ] ) ) {
				vals = this.options.values;
				newValues = arguments[ 0 ];
				for ( i = 0; i < vals.length; i += 1 ) {
					vals[ i ] = this._trimAlignValue( newValues[ i ] );
					this._change( null, i );
				}
				this._refreshValue();
			} else {
				if ( this.options.values && this.options.values.length ) {
					return this._values( index );
				} else {
					return this.value();
				}
			}
		} else {
			return this._values();
		}
	},

	_setOption: function( key, value ) {
		var i,
			valsLength = 0;

		if ( $.isArray( this.options.values ) ) {
			valsLength = this.options.values.length;
		}

		$.Widget.prototype._setOption.apply( this, arguments );

		switch ( key ) {
			case "disabled":
				if ( value ) {
					this.handles.filter( ".ui-state-focus" ).blur();
					this.handles.removeClass( "ui-state-hover" );
					this.handles.attr( "disabled", "disabled" );
					this.element.addClass( "ui-disabled" );
				} else {
					this.handles.removeAttr( "disabled" );
					this.element.removeClass( "ui-disabled" );
				}
				break;
			case "orientation":
				this._detectOrientation();
				this.element
					.removeClass( "ui-slider-horizontal ui-slider-vertical" )
					.addClass( "ui-slider-" + this.orientation );
				this._refreshValue();
				break;
			case "value":
				this._animateOff = true;
				this._refreshValue();
				this._change( null, 0 );
				this._animateOff = false;
				break;
			case "values":
				this._animateOff = true;
				this._refreshValue();
				for ( i = 0; i < valsLength; i += 1 ) {
					this._change( null, i );
				}
				this._animateOff = false;
				break;
		}
	},

	//internal value getter
	// _value() returns value trimmed by min and max, aligned by step
	_value: function() {
		var val = this.options.value;
		val = this._trimAlignValue( val );

		return val;
	},

	//internal values getter
	// _values() returns array of values trimmed by min and max, aligned by step
	// _values( index ) returns single value trimmed by min and max, aligned by step
	_values: function( index ) {
		var val,
			vals,
			i;

		if ( arguments.length ) {
			val = this.options.values[ index ];
			val = this._trimAlignValue( val );

			return val;
		} else {
			// .slice() creates a copy of the array
			// this copy gets trimmed by min and max and then returned
			vals = this.options.values.slice();
			for ( i = 0; i < vals.length; i+= 1) {
				vals[ i ] = this._trimAlignValue( vals[ i ] );
			}

			return vals;
		}
	},
	
	// returns the step-aligned value that val is closest to, between (inclusive) min and max
	_trimAlignValue: function( val ) {
		if ( val <= this._valueMin() ) {
			return this._valueMin();
		}
		if ( val >= this._valueMax() ) {
			return this._valueMax();
		}
		var step = ( this.options.step > 0 ) ? this.options.step : 1,
			valModStep = (val - this._valueMin()) % step;
			alignValue = val - valModStep;

		if ( Math.abs(valModStep) * 2 >= step ) {
			alignValue += ( valModStep > 0 ) ? step : ( -step );
		}

		// Since JavaScript has problems with large floats, round
		// the final value to 5 digits after the decimal point (see #4124)
		return parseFloat( alignValue.toFixed(5) );
	},

	_valueMin: function() {
		return this.options.min;
	},

	_valueMax: function() {
		return this.options.max;
	},
	
	_refreshValue: function() {
		var oRange = this.options.range,
			o = this.options,
			self = this,
			animate = ( !this._animateOff ) ? o.animate : false,
			valPercent,
			_set = {},
			lastValPercent,
			value,
			valueMin,
			valueMax;

		if ( this.options.values && this.options.values.length ) {
			this.handles.each(function( i, j ) {
				valPercent = ( self.values(i) - self._valueMin() ) / ( self._valueMax() - self._valueMin() ) * 100;
				_set[ self.orientation === "horizontal" ? "left" : "bottom" ] = valPercent + "%";
				$( this ).stop( 1, 1 )[ animate ? "animate" : "css" ]( _set, o.animate );
				if ( self.options.range === true ) {
					if ( self.orientation === "horizontal" ) {
						if ( i === 0 ) {
							self.range.stop( 1, 1 )[ animate ? "animate" : "css" ]( { left: valPercent + "%" }, o.animate );
						}
						if ( i === 1 ) {
							self.range[ animate ? "animate" : "css" ]( { width: ( valPercent - lastValPercent ) + "%" }, { queue: false, duration: o.animate } );
						}
					} else {
						if ( i === 0 ) {
							self.range.stop( 1, 1 )[ animate ? "animate" : "css" ]( { bottom: ( valPercent ) + "%" }, o.animate );
						}
						if ( i === 1 ) {
							self.range[ animate ? "animate" : "css" ]( { height: ( valPercent - lastValPercent ) + "%" }, { queue: false, duration: o.animate } );
						}
					}
				}
				lastValPercent = valPercent;
			});
		} else {
			value = this.value();
			valueMin = this._valueMin();
			valueMax = this._valueMax();
			valPercent = ( valueMax !== valueMin ) ?
					( value - valueMin ) / ( valueMax - valueMin ) * 100 :
					0;
			_set[ self.orientation === "horizontal" ? "left" : "bottom" ] = valPercent + "%";
			this.handle.stop( 1, 1 )[ animate ? "animate" : "css" ]( _set, o.animate );

			if ( oRange === "min" && this.orientation === "horizontal" ) {
				this.range.stop( 1, 1 )[ animate ? "animate" : "css" ]( { width: valPercent + "%" }, o.animate );
			}
			if ( oRange === "max" && this.orientation === "horizontal" ) {
				this.range[ animate ? "animate" : "css" ]( { width: ( 100 - valPercent ) + "%" }, { queue: false, duration: o.animate } );
			}
			if ( oRange === "min" && this.orientation === "vertical" ) {
				this.range.stop( 1, 1 )[ animate ? "animate" : "css" ]( { height: valPercent + "%" }, o.animate );
			}
			if ( oRange === "max" && this.orientation === "vertical" ) {
				this.range[ animate ? "animate" : "css" ]( { height: ( 100 - valPercent ) + "%" }, { queue: false, duration: o.animate } );
			}
		}
	}

});

$.extend( $.ui.slider, {
	version: "1.8.14"
});

}(jQuery));
/*
 * jQuery UI Tabs 1.8.14
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Tabs
 *
 * Depends:
 *	jquery.ui.core.js
 *	jquery.ui.widget.js
 */
(function( $, undefined ) {

var tabId = 0,
	listId = 0;

function getNextTabId() {
	return ++tabId;
}

function getNextListId() {
	return ++listId;
}

$.widget( "ui.tabs", {
	options: {
		add: null,
		ajaxOptions: null,
		cache: false,
		cookie: null, // e.g. { expires: 7, path: '/', domain: 'jquery.com', secure: true }
		collapsible: false,
		disable: null,
		disabled: [],
		enable: null,
		event: "click",
		fx: null, // e.g. { height: 'toggle', opacity: 'toggle', duration: 200 }
		idPrefix: "ui-tabs-",
		load: null,
		panelTemplate: "<div></div>",
		remove: null,
		select: null,
		show: null,
		spinner: "<em>Loading&#8230;</em>",
		tabTemplate: "<li><a href='#{href}'><span>#{label}</span></a></li>"
	},

	_create: function() {
		this._tabify( true );
	},

	_setOption: function( key, value ) {
		if ( key == "selected" ) {
			if (this.options.collapsible && value == this.options.selected ) {
				return;
			}
			this.select( value );
		} else {
			this.options[ key ] = value;
			this._tabify();
		}
	},

	_tabId: function( a ) {
		return a.title && a.title.replace( /\s/g, "_" ).replace( /[^\w\u00c0-\uFFFF-]/g, "" ) ||
			this.options.idPrefix + getNextTabId();
	},

	_sanitizeSelector: function( hash ) {
		// we need this because an id may contain a ":"
		return hash.replace( /:/g, "\\:" );
	},

	_cookie: function() {
		var cookie = this.cookie ||
			( this.cookie = this.options.cookie.name || "ui-tabs-" + getNextListId() );
		return $.cookie.apply( null, [ cookie ].concat( $.makeArray( arguments ) ) );
	},

	_ui: function( tab, panel ) {
		return {
			tab: tab,
			panel: panel,
			index: this.anchors.index( tab )
		};
	},

	_cleanup: function() {
		// restore all former loading tabs labels
		this.lis.filter( ".ui-state-processing" )
			.removeClass( "ui-state-processing" )
			.find( "span:data(label.tabs)" )
				.each(function() {
					var el = $( this );
					el.html( el.data( "label.tabs" ) ).removeData( "label.tabs" );
				});
	},

	_tabify: function( init ) {
		var self = this,
			o = this.options,
			fragmentId = /^#.+/; // Safari 2 reports '#' for an empty hash

		this.list = this.element.find( "ol,ul" ).eq( 0 );
		this.lis = $( " > li:has(a[href])", this.list );
		this.anchors = this.lis.map(function() {
			return $( "a", this )[ 0 ];
		});
		this.panels = $( [] );

		this.anchors.each(function( i, a ) {
			var href = $( a ).attr( "href" );
			// For dynamically created HTML that contains a hash as href IE < 8 expands
			// such href to the full page url with hash and then misinterprets tab as ajax.
			// Same consideration applies for an added tab with a fragment identifier
			// since a[href=#fragment-identifier] does unexpectedly not match.
			// Thus normalize href attribute...
			var hrefBase = href.split( "#" )[ 0 ],
				baseEl;
			if ( hrefBase && ( hrefBase === location.toString().split( "#" )[ 0 ] ||
					( baseEl = $( "base" )[ 0 ]) && hrefBase === baseEl.href ) ) {
				href = a.hash;
				a.href = href;
			}

			// inline tab
			if ( fragmentId.test( href ) ) {
				self.panels = self.panels.add( self.element.find( self._sanitizeSelector( href ) ) );
			// remote tab
			// prevent loading the page itself if href is just "#"
			} else if ( href && href !== "#" ) {
				// required for restore on destroy
				$.data( a, "href.tabs", href );

				// TODO until #3808 is fixed strip fragment identifier from url
				// (IE fails to load from such url)
				$.data( a, "load.tabs", href.replace( /#.*$/, "" ) );

				var id = self._tabId( a );
				a.href = "#" + id;
				var $panel = self.element.find( "#" + id );
				if ( !$panel.length ) {
					$panel = $( o.panelTemplate )
						.attr( "id", id )
						.addClass( "ui-tabs-panel ui-widget-content ui-corner-bottom" )
						.insertAfter( self.panels[ i - 1 ] || self.list );
					$panel.data( "destroy.tabs", true );
				}
				self.panels = self.panels.add( $panel );
			// invalid tab href
			} else {
				o.disabled.push( i );
			}
		});

		// initialization from scratch
		if ( init ) {
			// attach necessary classes for styling
			this.element.addClass( "ui-tabs ui-widget ui-widget-content ui-corner-all" );
			this.list.addClass( "ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all" );
			this.lis.addClass( "ui-state-default ui-corner-top" );
			this.panels.addClass( "ui-tabs-panel ui-widget-content ui-corner-bottom" );

			// Selected tab
			// use "selected" option or try to retrieve:
			// 1. from fragment identifier in url
			// 2. from cookie
			// 3. from selected class attribute on <li>
			if ( o.selected === undefined ) {
				if ( location.hash ) {
					this.anchors.each(function( i, a ) {
						if ( a.hash == location.hash ) {
							o.selected = i;
							return false;
						}
					});
				}
				if ( typeof o.selected !== "number" && o.cookie ) {
					o.selected = parseInt( self._cookie(), 10 );
				}
				if ( typeof o.selected !== "number" && this.lis.filter( ".ui-tabs-selected" ).length ) {
					o.selected = this.lis.index( this.lis.filter( ".ui-tabs-selected" ) );
				}
				o.selected = o.selected || ( this.lis.length ? 0 : -1 );
			} else if ( o.selected === null ) { // usage of null is deprecated, TODO remove in next release
				o.selected = -1;
			}

			// sanity check - default to first tab...
			o.selected = ( ( o.selected >= 0 && this.anchors[ o.selected ] ) || o.selected < 0 )
				? o.selected
				: 0;

			// Take disabling tabs via class attribute from HTML
			// into account and update option properly.
			// A selected tab cannot become disabled.
			o.disabled = $.unique( o.disabled.concat(
				$.map( this.lis.filter( ".ui-state-disabled" ), function( n, i ) {
					return self.lis.index( n );
				})
			) ).sort();

			if ( $.inArray( o.selected, o.disabled ) != -1 ) {
				o.disabled.splice( $.inArray( o.selected, o.disabled ), 1 );
			}

			// highlight selected tab
			this.panels.addClass( "ui-tabs-hide" );
			this.lis.removeClass( "ui-tabs-selected ui-state-active" );
			// check for length avoids error when initializing empty list
			if ( o.selected >= 0 && this.anchors.length ) {
				self.element.find( self._sanitizeSelector( self.anchors[ o.selected ].hash ) ).removeClass( "ui-tabs-hide" );
				this.lis.eq( o.selected ).addClass( "ui-tabs-selected ui-state-active" );

				// seems to be expected behavior that the show callback is fired
				self.element.queue( "tabs", function() {
					self._trigger( "show", null,
						self._ui( self.anchors[ o.selected ], self.element.find( self._sanitizeSelector( self.anchors[ o.selected ].hash ) )[ 0 ] ) );
				});

				this.load( o.selected );
			}

			// clean up to avoid memory leaks in certain versions of IE 6
			// TODO: namespace this event
			$( window ).bind( "unload", function() {
				self.lis.add( self.anchors ).unbind( ".tabs" );
				self.lis = self.anchors = self.panels = null;
			});
		// update selected after add/remove
		} else {
			o.selected = this.lis.index( this.lis.filter( ".ui-tabs-selected" ) );
		}

		// update collapsible
		// TODO: use .toggleClass()
		this.element[ o.collapsible ? "addClass" : "removeClass" ]( "ui-tabs-collapsible" );

		// set or update cookie after init and add/remove respectively
		if ( o.cookie ) {
			this._cookie( o.selected, o.cookie );
		}

		// disable tabs
		for ( var i = 0, li; ( li = this.lis[ i ] ); i++ ) {
			$( li )[ $.inArray( i, o.disabled ) != -1 &&
				// TODO: use .toggleClass()
				!$( li ).hasClass( "ui-tabs-selected" ) ? "addClass" : "removeClass" ]( "ui-state-disabled" );
		}

		// reset cache if switching from cached to not cached
		if ( o.cache === false ) {
			this.anchors.removeData( "cache.tabs" );
		}

		// remove all handlers before, tabify may run on existing tabs after add or option change
		this.lis.add( this.anchors ).unbind( ".tabs" );

		if ( o.event !== "mouseover" ) {
			var addState = function( state, el ) {
				if ( el.is( ":not(.ui-state-disabled)" ) ) {
					el.addClass( "ui-state-" + state );
				}
			};
			var removeState = function( state, el ) {
				el.removeClass( "ui-state-" + state );
			};
			this.lis.bind( "mouseover.tabs" , function() {
				addState( "hover", $( this ) );
			});
			this.lis.bind( "mouseout.tabs", function() {
				removeState( "hover", $( this ) );
			});
			this.anchors.bind( "focus.tabs", function() {
				addState( "focus", $( this ).closest( "li" ) );
			});
			this.anchors.bind( "blur.tabs", function() {
				removeState( "focus", $( this ).closest( "li" ) );
			});
		}

		// set up animations
		var hideFx, showFx;
		if ( o.fx ) {
			if ( $.isArray( o.fx ) ) {
				hideFx = o.fx[ 0 ];
				showFx = o.fx[ 1 ];
			} else {
				hideFx = showFx = o.fx;
			}
		}

		// Reset certain styles left over from animation
		// and prevent IE's ClearType bug...
		function resetStyle( $el, fx ) {
			$el.css( "display", "" );
			if ( !$.support.opacity && fx.opacity ) {
				$el[ 0 ].style.removeAttribute( "filter" );
			}
		}

		// Show a tab...
		var showTab = showFx
			? function( clicked, $show ) {
				$( clicked ).closest( "li" ).addClass( "ui-tabs-selected ui-state-active" );
				$show.hide().removeClass( "ui-tabs-hide" ) // avoid flicker that way
					.animate( showFx, showFx.duration || "normal", function() {
						resetStyle( $show, showFx );
						self._trigger( "show", null, self._ui( clicked, $show[ 0 ] ) );
					});
			}
			: function( clicked, $show ) {
				$( clicked ).closest( "li" ).addClass( "ui-tabs-selected ui-state-active" );
				$show.removeClass( "ui-tabs-hide" );
				self._trigger( "show", null, self._ui( clicked, $show[ 0 ] ) );
			};

		// Hide a tab, $show is optional...
		var hideTab = hideFx
			? function( clicked, $hide ) {
				$hide.animate( hideFx, hideFx.duration || "normal", function() {
					self.lis.removeClass( "ui-tabs-selected ui-state-active" );
					$hide.addClass( "ui-tabs-hide" );
					resetStyle( $hide, hideFx );
					self.element.dequeue( "tabs" );
				});
			}
			: function( clicked, $hide, $show ) {
				self.lis.removeClass( "ui-tabs-selected ui-state-active" );
				$hide.addClass( "ui-tabs-hide" );
				self.element.dequeue( "tabs" );
			};

		// attach tab event handler, unbind to avoid duplicates from former tabifying...
		this.anchors.bind( o.event + ".tabs", function() {
			var el = this,
				$li = $(el).closest( "li" ),
				$hide = self.panels.filter( ":not(.ui-tabs-hide)" ),
				$show = self.element.find( self._sanitizeSelector( el.hash ) );

			// If tab is already selected and not collapsible or tab disabled or
			// or is already loading or click callback returns false stop here.
			// Check if click handler returns false last so that it is not executed
			// for a disabled or loading tab!
			if ( ( $li.hasClass( "ui-tabs-selected" ) && !o.collapsible) ||
				$li.hasClass( "ui-state-disabled" ) ||
				$li.hasClass( "ui-state-processing" ) ||
				self.panels.filter( ":animated" ).length ||
				self._trigger( "select", null, self._ui( this, $show[ 0 ] ) ) === false ) {
				this.blur();
				return false;
			}

			o.selected = self.anchors.index( this );

			self.abort();

			// if tab may be closed
			if ( o.collapsible ) {
				if ( $li.hasClass( "ui-tabs-selected" ) ) {
					o.selected = -1;

					if ( o.cookie ) {
						self._cookie( o.selected, o.cookie );
					}

					self.element.queue( "tabs", function() {
						hideTab( el, $hide );
					}).dequeue( "tabs" );

					this.blur();
					return false;
				} else if ( !$hide.length ) {
					if ( o.cookie ) {
						self._cookie( o.selected, o.cookie );
					}

					self.element.queue( "tabs", function() {
						showTab( el, $show );
					});

					// TODO make passing in node possible, see also http://dev.jqueryui.com/ticket/3171
					self.load( self.anchors.index( this ) );

					this.blur();
					return false;
				}
			}

			if ( o.cookie ) {
				self._cookie( o.selected, o.cookie );
			}

			// show new tab
			if ( $show.length ) {
				if ( $hide.length ) {
					self.element.queue( "tabs", function() {
						hideTab( el, $hide );
					});
				}
				self.element.queue( "tabs", function() {
					showTab( el, $show );
				});

				self.load( self.anchors.index( this ) );
			} else {
				throw "jQuery UI Tabs: Mismatching fragment identifier.";
			}

			// Prevent IE from keeping other link focussed when using the back button
			// and remove dotted border from clicked link. This is controlled via CSS
			// in modern browsers; blur() removes focus from address bar in Firefox
			// which can become a usability and annoying problem with tabs('rotate').
			if ( $.browser.msie ) {
				this.blur();
			}
		});

		// disable click in any case
		this.anchors.bind( "click.tabs", function(){
			return false;
		});
	},

    _getIndex: function( index ) {
		// meta-function to give users option to provide a href string instead of a numerical index.
		// also sanitizes numerical indexes to valid values.
		if ( typeof index == "string" ) {
			index = this.anchors.index( this.anchors.filter( "[href$=" + index + "]" ) );
		}

		return index;
	},

	destroy: function() {
		var o = this.options;

		this.abort();

		this.element
			.unbind( ".tabs" )
			.removeClass( "ui-tabs ui-widget ui-widget-content ui-corner-all ui-tabs-collapsible" )
			.removeData( "tabs" );

		this.list.removeClass( "ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all" );

		this.anchors.each(function() {
			var href = $.data( this, "href.tabs" );
			if ( href ) {
				this.href = href;
			}
			var $this = $( this ).unbind( ".tabs" );
			$.each( [ "href", "load", "cache" ], function( i, prefix ) {
				$this.removeData( prefix + ".tabs" );
			});
		});

		this.lis.unbind( ".tabs" ).add( this.panels ).each(function() {
			if ( $.data( this, "destroy.tabs" ) ) {
				$( this ).remove();
			} else {
				$( this ).removeClass([
					"ui-state-default",
					"ui-corner-top",
					"ui-tabs-selected",
					"ui-state-active",
					"ui-state-hover",
					"ui-state-focus",
					"ui-state-disabled",
					"ui-tabs-panel",
					"ui-widget-content",
					"ui-corner-bottom",
					"ui-tabs-hide"
				].join( " " ) );
			}
		});

		if ( o.cookie ) {
			this._cookie( null, o.cookie );
		}

		return this;
	},

	add: function( url, label, index ) {
		if ( index === undefined ) {
			index = this.anchors.length;
		}

		var self = this,
			o = this.options,
			$li = $( o.tabTemplate.replace( /#\{href\}/g, url ).replace( /#\{label\}/g, label ) ),
			id = !url.indexOf( "#" ) ? url.replace( "#", "" ) : this._tabId( $( "a", $li )[ 0 ] );

		$li.addClass( "ui-state-default ui-corner-top" ).data( "destroy.tabs", true );

		// try to find an existing element before creating a new one
		var $panel = self.element.find( "#" + id );
		if ( !$panel.length ) {
			$panel = $( o.panelTemplate )
				.attr( "id", id )
				.data( "destroy.tabs", true );
		}
		$panel.addClass( "ui-tabs-panel ui-widget-content ui-corner-bottom ui-tabs-hide" );

		if ( index >= this.lis.length ) {
			$li.appendTo( this.list );
			$panel.appendTo( this.list[ 0 ].parentNode );
		} else {
			$li.insertBefore( this.lis[ index ] );
			$panel.insertBefore( this.panels[ index ] );
		}

		o.disabled = $.map( o.disabled, function( n, i ) {
			return n >= index ? ++n : n;
		});

		this._tabify();

		if ( this.anchors.length == 1 ) {
			o.selected = 0;
			$li.addClass( "ui-tabs-selected ui-state-active" );
			$panel.removeClass( "ui-tabs-hide" );
			this.element.queue( "tabs", function() {
				self._trigger( "show", null, self._ui( self.anchors[ 0 ], self.panels[ 0 ] ) );
			});

			this.load( 0 );
		}

		this._trigger( "add", null, this._ui( this.anchors[ index ], this.panels[ index ] ) );
		return this;
	},

	remove: function( index ) {
		index = this._getIndex( index );
		var o = this.options,
			$li = this.lis.eq( index ).remove(),
			$panel = this.panels.eq( index ).remove();

		// If selected tab was removed focus tab to the right or
		// in case the last tab was removed the tab to the left.
		if ( $li.hasClass( "ui-tabs-selected" ) && this.anchors.length > 1) {
			this.select( index + ( index + 1 < this.anchors.length ? 1 : -1 ) );
		}

		o.disabled = $.map(
			$.grep( o.disabled, function(n, i) {
				return n != index;
			}),
			function( n, i ) {
				return n >= index ? --n : n;
			});

		this._tabify();

		this._trigger( "remove", null, this._ui( $li.find( "a" )[ 0 ], $panel[ 0 ] ) );
		return this;
	},

	enable: function( index ) {
		index = this._getIndex( index );
		var o = this.options;
		if ( $.inArray( index, o.disabled ) == -1 ) {
			return;
		}

		this.lis.eq( index ).removeClass( "ui-state-disabled" );
		o.disabled = $.grep( o.disabled, function( n, i ) {
			return n != index;
		});

		this._trigger( "enable", null, this._ui( this.anchors[ index ], this.panels[ index ] ) );
		return this;
	},

	disable: function( index ) {
		index = this._getIndex( index );
		var self = this, o = this.options;
		// cannot disable already selected tab
		if ( index != o.selected ) {
			this.lis.eq( index ).addClass( "ui-state-disabled" );

			o.disabled.push( index );
			o.disabled.sort();

			this._trigger( "disable", null, this._ui( this.anchors[ index ], this.panels[ index ] ) );
		}

		return this;
	},

	select: function( index ) {
		index = this._getIndex( index );
		if ( index == -1 ) {
			if ( this.options.collapsible && this.options.selected != -1 ) {
				index = this.options.selected;
			} else {
				return this;
			}
		}
		this.anchors.eq( index ).trigger( this.options.event + ".tabs" );
		return this;
	},

	load: function( index ) {
		index = this._getIndex( index );
		var self = this,
			o = this.options,
			a = this.anchors.eq( index )[ 0 ],
			url = $.data( a, "load.tabs" );

		this.abort();

		// not remote or from cache
		if ( !url || this.element.queue( "tabs" ).length !== 0 && $.data( a, "cache.tabs" ) ) {
			this.element.dequeue( "tabs" );
			return;
		}

		// load remote from here on
		this.lis.eq( index ).addClass( "ui-state-processing" );

		if ( o.spinner ) {
			var span = $( "span", a );
			span.data( "label.tabs", span.html() ).html( o.spinner );
		}

		this.xhr = $.ajax( $.extend( {}, o.ajaxOptions, {
			url: url,
			success: function( r, s ) {
				self.element.find( self._sanitizeSelector( a.hash ) ).html( r );

				// take care of tab labels
				self._cleanup();

				if ( o.cache ) {
					$.data( a, "cache.tabs", true );
				}

				self._trigger( "load", null, self._ui( self.anchors[ index ], self.panels[ index ] ) );
				try {
					o.ajaxOptions.success( r, s );
				}
				catch ( e ) {}
			},
			error: function( xhr, s, e ) {
				// take care of tab labels
				self._cleanup();

				self._trigger( "load", null, self._ui( self.anchors[ index ], self.panels[ index ] ) );
				try {
					// Passing index avoid a race condition when this method is
					// called after the user has selected another tab.
					// Pass the anchor that initiated this request allows
					// loadError to manipulate the tab content panel via $(a.hash)
					o.ajaxOptions.error( xhr, s, index, a );
				}
				catch ( e ) {}
			}
		} ) );

		// last, so that load event is fired before show...
		self.element.dequeue( "tabs" );

		return this;
	},

	abort: function() {
		// stop possibly running animations
		this.element.queue( [] );
		this.panels.stop( false, true );

		// "tabs" queue must not contain more than two elements,
		// which are the callbacks for the latest clicked tab...
		this.element.queue( "tabs", this.element.queue( "tabs" ).splice( -2, 2 ) );

		// terminate pending requests from other tabs
		if ( this.xhr ) {
			this.xhr.abort();
			delete this.xhr;
		}

		// take care of tab labels
		this._cleanup();
		return this;
	},

	url: function( index, url ) {
		this.anchors.eq( index ).removeData( "cache.tabs" ).data( "load.tabs", url );
		return this;
	},

	length: function() {
		return this.anchors.length;
	}
});

$.extend( $.ui.tabs, {
	version: "1.8.14"
});

/*
 * Tabs Extensions
 */

/*
 * Rotate
 */
$.extend( $.ui.tabs.prototype, {
	rotation: null,
	rotate: function( ms, continuing ) {
		var self = this,
			o = this.options;

		var rotate = self._rotate || ( self._rotate = function( e ) {
			clearTimeout( self.rotation );
			self.rotation = setTimeout(function() {
				var t = o.selected;
				self.select( ++t < self.anchors.length ? t : 0 );
			}, ms );
			
			if ( e ) {
				e.stopPropagation();
			}
		});

		var stop = self._unrotate || ( self._unrotate = !continuing
			? function(e) {
				if (e.clientX) { // in case of a true click
					self.rotate(null);
				}
			}
			: function( e ) {
				t = o.selected;
				rotate();
			});

		// start rotation
		if ( ms ) {
			this.element.bind( "tabsshow", rotate );
			this.anchors.bind( o.event + ".tabs", stop );
			rotate();
		// stop rotation
		} else {
			clearTimeout( self.rotation );
			this.element.unbind( "tabsshow", rotate );
			this.anchors.unbind( o.event + ".tabs", stop );
			delete this._rotate;
			delete this._unrotate;
		}

		return this;
	}
});

})( jQuery );
(function() {

}).call(this);
(function() {

}).call(this);
$(function(){
	$('.invokeanswers').click(function(){
        $(this).hide();
        $(this).next().show();
    });
    
});
(function() {

}).call(this);
(function() {

}).call(this);
(function() {

}).call(this);


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
/**
 * @author SaravanaK
 */

function toggle(div_id) {
	var el = document.getElementById(div_id);
	if ( el.style.display == 'none' ) {	el.style.display = 'block';}
	else {el.style.display = 'none';}
}
function blanket_size(popUpDivVar) {
	if (typeof window.innerWidth != 'undefined') {
		viewportheight = window.innerHeight;
	} else {
		viewportheight = document.documentElement.clientHeight;
	}
	if ((viewportheight > document.body.parentNode.scrollHeight) && (viewportheight > document.body.parentNode.clientHeight)) {
		blanket_height = viewportheight;
	} else {
		if (document.body.parentNode.clientHeight > document.body.parentNode.scrollHeight) {
			blanket_height = document.body.parentNode.clientHeight;
		} else {
			blanket_height = document.body.parentNode.scrollHeight;
		}
	}
	var blanket = document.getElementById('blanket');
	blanket.style.height = blanket_height + 'px';
	var popUpDiv = document.getElementById(popUpDivVar);
	popUpDiv_height=blanket_height/2-150;//150 is half popup's height
	
	/*popUpDiv.style.top = popUpDiv_height + 'px';*/
}
function window_pos(popUpDivVar) {
	if (typeof window.innerWidth != 'undefined') {
		viewportwidth = window.innerHeight;
	} else {
		viewportwidth = document.documentElement.clientHeight;
	}
	if ((viewportwidth > document.body.parentNode.scrollWidth) && (viewportwidth > document.body.parentNode.clientWidth)) {
		window_width = viewportwidth;
	} else {
		if (document.body.parentNode.clientWidth > document.body.parentNode.scrollWidth) {
			window_width = document.body.parentNode.clientWidth;
		} else {
			window_width = document.body.parentNode.scrollWidth;
		}
	}
	var popUpDiv = document.getElementById(popUpDivVar);
	window_width=window_width/2-150;//150 is half popup's width
	/*popUpDiv.style.left = window_width + 'px';*/
}
function popup(windowname) {
	blanket_size(windowname);
	window_pos(windowname);
	toggle('blanket');
	toggle(windowname);		
}
;
//for tabs
$("ul#Newtabs li a").live('click', function(){
    $("ul#Newtabs").find('li').removeClass('tab_active');
        $(this).closest('li').addClass("tab_active");
        $(".main-content-section").hide();
        var activeTab = $(this).attr("href");
        $(activeTab).show();
        return false;

  })
;
(function() {

}).call(this);
(function() {

}).call(this);
(function() {

}).call(this);
(function() {

}).call(this);
(function() {

}).call(this);
$(document).ready(function(){
    $('div.Homepopupgraybox div.Boxtopblock span.Openclosebut a#wizardbutton').click(function() {
    //$('div.Homepopupgraybox div.Boxtopblock span.Openclosebut a#wizardbutton').live('click', function(){
        $("#wizardbutton").toggleClass('Close Open');
        $(this).text(function(i,text) {
            return_text =  (text == 'Close') ? 'Open' : 'Close';
        });
       $("#wizardbutton").text(return_text);   
        $("div.Grayboxmid").toggle();
        return false;
    })
});
/*!
 * jQuery Raty - A Star Rating Plugin - http://wbotelhos.com/raty
 * ---------------------------------------------------------------------------------
 *
 * jQuery Raty is a plugin that generates a customizable star rating automatically.
 *
 * Licensed under The MIT License
 *
 * @version			1.4.3
 * @since			06.11.2010
 * @author			Washington Botelho dos Santos
 * @documentation	http://wbotelhos.com/raty
 * @twitter			http://twitter.com/wbotelhos
 * @license			http://opensource.org/licenses/mit-license.php
 * @package			jQuery Plugins
 *
 * Usage with default values:
 * ---------------------------------------------------------------------------------
 * $('#star').raty();
 *
 * <div id="star"></div>
 *
 * $('.star').raty();
 *
 * <div class="star"></div>
 * <div class="star"></div>
 * <div class="star"></div>
 *
 */


;(function($) {

	$.fn.raty = function(settings) {

		if (this.length == 0) {
			debug('Selector invalid or missing!');
			return;
		} else if (this.length > 1) {
			return this.each(function() {
				$.fn.raty.apply($(this), [settings]);
			});
		}

		var opt		= $.extend({}, $.fn.raty.defaults, settings),
			$this	= $(this),
			id		= $this.attr('id'),
			width	= (opt.width) ? opt.width : (opt.number * opt.size + opt.number * 4) ;

		if (id === undefined || id == '') {
			id = 'raty-' + $this.index();
			$this.attr('id', id); 
		}

		$this.data('options', opt);

		if (opt.number > 20) {
			opt.number = 20;
		} else if (opt.number < 0) {
			opt.number = 0;
		}

		if (opt.path.substring(opt.path.length - 1, opt.path.length) != '/') {
			opt.path += '/';
		}

		var isValidStart	= !isNaN(parseInt(opt.start, 10)),
			start			= '';

		if (isValidStart) {
			start = (opt.start > opt.number) ? opt.number : opt.start;
		}

		var starFile	= opt.starOn,
			hint		= '';

		for (var i = 1; i <= opt.number; i++) {
			starFile = (start < i) ? opt.starOff : opt.starOn;

			hint = (i <= opt.hintList.length && opt.hintList[i - 1] !== null) ? opt.hintList[i - 1] : i;

			$this.append('<img id="' + id + '-' + i + '" src="' + opt.path + starFile + '" alt="' + i + '" title="' + hint + '" class="' + id + '"/>');

			if (opt.space) {
				$this.append((i < opt.number) ? '&nbsp;' : '');
			}
		}

		if (opt.iconRange && isValidStart) {
			fillStar($this, start);	
		}

		if (opt.halfShow) {
			roundStar($this, start);
		}

		setTarget(start, opt);

		var $score = $('<input/>', {
			id:		id + '-score',
			type:	'hidden',
			name:	opt.scoreName
		}).appendTo($this);

		if (isValidStart) {
			$score.val(start);
		}

		if (!opt.readOnly) {
			if (opt.cancel) {
				var stars	= $this.children('img.' + id),
					cancel	= '<img src="' + opt.path + opt.cancelOff + '" alt="x" title="' + opt.cancelHint + '" class="button-cancel"/>';

				if (opt.cancelPlace == 'left') {
					$this.prepend(cancel + '&nbsp;');
				} else {
					$this.append('&nbsp;').append(cancel);
				}

				$this.children('img.button-cancel').mouseenter(function() {
					$(this).attr('src', opt.path + opt.cancelOn);

					stars.attr('src', opt.path + opt.starOff);

					setTarget(null, opt);
				}).mouseleave(function() {
					$(this).attr('src', opt.path + opt.cancelOff);

					$this.mouseout();
				}).click(function(evt) {
					$score.removeAttr('value');

					if (opt.click) {
			          opt.click.apply($this, [null, evt]);
			        }
				});

				$this.css('width', width + opt.size + 4);
			} else {
				$this.css('width', width);
			}

			$this.css('cursor', 'pointer');

			bindAll($this, opt);
		} else {
			$this.css('cursor', 'default');
			fixHint($this, start);
		}

		return $this;
	};
	
	function bindAll(context, opt) {
		var id		= context.attr('id'),
			$score	= $('input#' + id + '-score'),
			$stars	= context.children('img.' + id);

		context.mouseleave(function() {
			initialize(context, $score.val());
			setTarget($score.val(), opt, !opt.targetKeep);
		});

		$stars.bind(((opt.half) ? 'mousemove' : 'mouseover'), function(e) {
			var value = parseInt(this.alt, 10);

			if (opt.half) {
				var position	= parseFloat((e.pageX - $(this).offset().left) / opt.size),
					diff		= (position > .5) ? 1 : .5;

				value = parseFloat(this.alt) - 1 + diff;

				fillStar(context, value);

				roundStar(context, value);

				if (opt.precision) {
					value = (value - diff + position).toFixed(1);

					setTarget(value, opt);
				}

				context.data('score', value);
			} else {
				fillStar(context, value);
				setTarget(value, opt);
			}
		}).click(function(evt) {
			$score.val((opt.half || opt.precision) ? context.data('score') : this.alt);

			if (opt.click) {
				opt.click.apply(context, [$score.val(), evt]);
			}
		});
	};

	function setTarget(value, opt, isClear) {
		if (opt.target) {
			var $target = $(opt.target);

			if ($target.length == 0) {
				debug(id + ': target selector invalid or missing!');
			} else {
				if (isClear) {
					value = opt.targetOutValue;
				} else {
					if (opt.targetType == 'hint') {
						if (value === null && opt.cancel) {
							value = opt.cancelHint;
						} else {
							value = opt.hintList[Math.ceil(value - 1)];
						}
					}
				}

				if (isField($target)) {
					$target.val(value);
				} else {
					$target.html(value);
				}
			}
		}
	};

	function fillStar(context, score) {
		var opt		= context.data('options'),
			id		= context.attr('id'),
			qtyStar	= context.children('img.' + id).length,
			item	= 0,
			$stars	,
			icon	,
			star	;

		for (var i = 1; i <= qtyStar; i++) {
			$stars = context.children('img#' + id + '-' + i);

			if (opt.iconRange && opt.iconRange.length > item) {
				star = opt.iconRange[item];
				icon = (i <= score) ? star.on : star.off;

				if (!icon) {
					icon = opt.starOff;
				}

				if (i <= star.range) {
					$stars.attr('src', opt.path + icon);
				}

				if (i == star.range) {
					item++;
				}
			} else {
				icon = (i <= score) ? opt.starOn : opt.starOff;
				$stars.attr('src', opt.path + icon);
			}
		}
	};

	function fixHint(context, score) {
		var opt		= context.data('options'),
			hint	= '';

		if (score != 0) {
			score = parseInt(score, 10);
			hint = (score > 0 && opt.number <= opt.hintList.length && opt.hintList[score - 1] !== null) ? opt.hintList[score - 1] : score;
		} else {
			hint = opt.noRatedMsg;
		}

		context.attr('title', hint).children('img').attr('title', hint);
	};

	function isField(target) {
		return target.is('input') || target.is('select') || target.is('textarea');
	};

	function initialize(context, score) {
		var opt	= context.data('options'),
			id	= context.attr('id');

		if (isNaN(parseInt(score, 10))) {
			context.children('img.' + id).attr('src', opt.path + opt.starOff);
			$('input#' + id + '-score').removeAttr('value');
			return;
		}

		if (score < 0) {
			score = 0;
		} else if (score > opt.number) {
			score = opt.number;
		}

		fillStar(context, score);

		if (opt.halfShow) {
			roundStar(context, score);
		}

		$('input#' + id + '-score').val(score);

		if (opt.readOnly || context.css('cursor') == 'default') {
			fixHint(context, score);
		}
	};

	function roundStar(context, score) {
		var diff = (score - Math.floor(score)).toFixed(2);

		if (diff > .25) {
			var opt		= context.data('options'),
				icon	= opt.starOn;			// Rounded up: [x.76 ... x.99]

			if (diff < .76 && (opt.half || opt.halfShow)) {	// Half star: [x.26 ... x.75]
				icon = opt.starHalf;
			}

			$('img#' + context.attr('id') + '-' + Math.ceil(score)).attr('src', opt.path + icon);
		}										// Rounded down: [x.00 ... x.25]
	};

	$.fn.raty.cancel = function(idOrClass, isClickIn) {
		var isClick = (isClickIn === undefined) ? false : true;

		if (isClick) {
			return $.fn.raty.click('', idOrClass, 'cancel');
		} else {
			return $.fn.raty.start('', idOrClass, 'cancel');
		}
	};

	$.fn.raty.click = function(score, idOrClass) {
		var context = getContext(score, idOrClass, 'click');

		if (idOrClass.indexOf('.') >= 0) {
			return;
		}

		initialize(context, score);

		var opt = $(idOrClass).data('options');

		setTarget(score, opt);

		if (opt.click) {
			opt.click.apply(context, [score]);
		} else {
			debug(idOrClass + ': you must add the "click: function(score, evt) { }" callback.');
		}

		return context;
	};

	$.fn.raty.readOnly = function(boo, idOrClass) {
		var context	= getContext(boo, idOrClass, 'readOnly');

		if (idOrClass.indexOf('.') >= 0) {
			return;
		}

		var cancel = context.children('img.button-cancel');

		if (cancel[0]) {
			(boo) ? cancel.hide() : cancel.show();
		}

		if (boo) {
			$('img.' + context.attr('id')).unbind();
			context.css('cursor', 'default').unbind();
		} else {
			var options = $(idOrClass).data('options');

			bindAll(context, options);
			context.css('cursor', 'pointer');
		}

		return context;
	};

	$.fn.raty.start = function(score, idOrClass) {
		var context = getContext(score, idOrClass, 'start');

		if (idOrClass.indexOf('.') >= 0) {
			return;
		}

		initialize(context, score);

		var opt = $(idOrClass).data('options');

		setTarget(score, opt);

		return context;
	};

	function getContext(value, idOrClass, name) {
		var context = undefined;

		if (idOrClass == undefined) {
			debug('Specify an ID or class to be the target of the action.');
			return;
		}

		if (idOrClass) {
			if (idOrClass.indexOf('.') >= 0) {
				var idEach;

				return $(idOrClass).each(function() {
					idEach = '#' + $(this).attr('id');

					if (name == 'start') {
						$.fn.raty.start(value, idEach);
					} else if (name == 'click') {
						$.fn.raty.click(value, idEach);
					} else if (name == 'readOnly') {
						$.fn.raty.readOnly(value, idEach);
					}
				});
			}

			context = $(idOrClass);

			if (!context.length) {
				debug('"' + idOrClass + '" is a invalid identifier for the public funtion $.fn.raty.' + name + '().');
				return;
			}
		}

		return context;
	};

	function debug(message) {
		if (window.console && window.console.log) {
			window.console.log(message);
		}
	};

	$.fn.raty.defaults = {
		cancel:			false,
		cancelHint:		'cancel this rating!',
		cancelOff:		'cancel-off.png',
		cancelOn:		'cancel-on.png',
		cancelPlace:	'left',
		click:			null,
		half:			false,
		halfShow:		true,
		hintList:		['bad', 'poor', 'regular', 'good', 'gorgeous'],
		iconRange:		undefined,
		noRatedMsg:		'not rated yet',
		number:			5,
		path:			'',
		precision:		false,
		readOnly:		false,
		scoreName:		'score',
		size:			16,
		space:			true,
		starHalf:		'star-half.png',
		starOff:		'star-off.png',
		starOn:			'star-on.png',
		start:			0,
		target:			null,
		targetKeep:		false,
		targetOutValue:	'',
		targetType:		'hint',
		width:			null
	};

})(jQuery);
/*
 * jQuery Plugin: Tokenizing Autocomplete Text Entry
 * Version 1.5.0
 *
 * Copyright (c) 2009 James Smith (http://loopj.com)
 * Licensed jointly under the GPL and MIT licenses,
 * choose which one suits your project best!
 *
 */
/*
(function ($) {
// Default settings
var DEFAULT_SETTINGS = {
    hintText: "Type in a search term",
    noResultsText: "No results",
    searchingText: "Searching...",
    deleteText: "&times;",
    searchDelay: 300,
    minChars: 1,
    tokenLimit: null,
    jsonContainer: null,
    method: "GET",
    contentType: "json",
    queryParam: "q",
    tokenDelimiter: ",",
    preventDuplicates: false,
    prePopulate: null,
    processPrePopulate: false,
    animateDropdown: true,
    onResult: null,
    onAdd: null,
    onDelete: null,
    idPrefix: "token-input-"
};

// Default classes to use when theming
var DEFAULT_CLASSES = {
    tokenList: "token-input-list",
    token: "token-input-token",
    tokenDelete: "token-input-delete-token",
    selectedToken: "token-input-selected-token",
    highlightedToken: "token-input-highlighted-token",
    dropdown: "token-input-dropdown",
    dropdownItem: "token-input-dropdown-item",
    dropdownItem2: "token-input-dropdown-item2",
    selectedDropdownItem: "token-input-selected-dropdown-item",
    inputToken: "token-input-input-token"
};

// Input box position "enum"
var POSITION = {
    BEFORE: 0,
    AFTER: 1,
    END: 2
};

// Keys "enum"
var KEY = {
    BACKSPACE: 8,
    TAB: 9,
    ENTER: 13,
    ESCAPE: 27,
    SPACE: 32,
    PAGE_UP: 33,
    PAGE_DOWN: 34,
    END: 35,
    HOME: 36,
    LEFT: 37,
    UP: 38,
    RIGHT: 39,
    DOWN: 40,
    NUMPAD_ENTER: 108,
    COMMA: 188
};

// Additional public (exposed) methods
var methods = {
    init: function(url_or_data_or_function, options) {
        var settings = $.extend({}, DEFAULT_SETTINGS, options || {});

        return this.each(function () {
            $(this).data("tokenInputObject", new $.TokenList(this, url_or_data_or_function, settings));
        });
    },
    clear: function() {
        this.data("tokenInputObject").clear();
        return this;
    },
    add: function(item) {
        this.data("tokenInputObject").add(item);
        return this;
    },
    remove: function(item) {
        this.data("tokenInputObject").remove(item);
        return this;
    }
}

// Expose the .tokenInput function to jQuery as a plugin
$.fn.tokenInput = function (method) {
    // Method calling and initialization logic
    if(methods[method]) {
        return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
    } else {
        return methods.init.apply(this, arguments);
    }
};

// TokenList class for each input
$.TokenList = function (input, url_or_data, settings) {
    //
    // Initialization
    //

    // Configure the data source
    if(typeof(url_or_data) === "string") {
        // Set the url to query against
        settings.url = url_or_data;

        // Make a smart guess about cross-domain if it wasn't explicitly specified
        if(settings.crossDomain === undefined) {
            if(settings.url.indexOf("://") === -1) {
                settings.crossDomain = false;
            } else {
                settings.crossDomain = (location.href.split(/\/+/g)[1] !== settings.url.split(/\/+/g)[1]);
            }
        }
    } else if(typeof(url_or_data) === "object") {
        // Set the local data to search through
        settings.local_data = url_or_data;
    }

    // Build class names
    if(settings.classes) {
        // Use custom class names
        settings.classes = $.extend({}, DEFAULT_CLASSES, settings.classes);
    } else if(settings.theme) {
        // Use theme-suffixed default class names
        settings.classes = {};
        $.each(DEFAULT_CLASSES, function(key, value) {
            settings.classes[key] = value + "-" + settings.theme;
        });
    } else {
        settings.classes = DEFAULT_CLASSES;
    }


    // Save the tokens
    var saved_tokens = [];

    // Keep track of the number of tokens in the list
    var token_count = 0;

    // Basic cache to save on db hits
    var cache = new $.TokenList.Cache();

    // Keep track of the timeout, old vals
    var timeout;
    var input_val;

    // Create a new text input an attach keyup events
    var input_box = $("<input type=\"text\"  autocomplete=\"off\">")
        .css({
            outline: "none"
        })
        .attr("id", settings.idPrefix + input.id)
        .focus(function () {
            if (settings.tokenLimit === null || settings.tokenLimit !== token_count) {
                show_dropdown_hint();
            }
        })
        .blur(function () {
            hide_dropdown();
            $(this).val("");
        })
        .bind("keyup keydown blur update", resize_input)
        .keydown(function (event) {
            var previous_token;
            var next_token;

            switch(event.keyCode) {
                case KEY.LEFT:
                case KEY.RIGHT:
                case KEY.UP:
                case KEY.DOWN:
                    if(!$(this).val()) {
                        previous_token = input_token.prev();
                        next_token = input_token.next();

                        if((previous_token.length && previous_token.get(0) === selected_token) || (next_token.length && next_token.get(0) === selected_token)) {
                            // Check if there is a previous/next token and it is selected
                            if(event.keyCode === KEY.LEFT || event.keyCode === KEY.UP) {
                                deselect_token($(selected_token), POSITION.BEFORE);
                            } else {
                                deselect_token($(selected_token), POSITION.AFTER);
                            }
                        } else if((event.keyCode === KEY.LEFT || event.keyCode === KEY.UP) && previous_token.length) {
                            // We are moving left, select the previous token if it exists
                            select_token($(previous_token.get(0)));
                        } else if((event.keyCode === KEY.RIGHT || event.keyCode === KEY.DOWN) && next_token.length) {
                            // We are moving right, select the next token if it exists
                            select_token($(next_token.get(0)));
                        }
                    } else {
                        var dropdown_item = null;

                        if(event.keyCode === KEY.DOWN || event.keyCode === KEY.RIGHT) {
                            dropdown_item = $(selected_dropdown_item).next();
                        } else {
                            dropdown_item = $(selected_dropdown_item).prev();
                        }

                        if(dropdown_item.length) {
                            select_dropdown_item(dropdown_item);
                        }
                        return false;
                    }
                    break;

                case KEY.BACKSPACE:
                    previous_token = input_token.prev();

                    if(!$(this).val().length) {
                        if(selected_token) {
                            delete_token($(selected_token));
                        } else if(previous_token.length) {
                            select_token($(previous_token.get(0)));
                        }

                        return false;
                    } else if($(this).val().length === 1) {
                        hide_dropdown();
                    } else {
                        // set a timeout just long enough to let this function finish.
                        setTimeout(function(){do_search();}, 5);
                    }
                    break;

                case KEY.TAB:
                case KEY.ENTER:
                case KEY.NUMPAD_ENTER:
                case KEY.COMMA:
                  if(selected_dropdown_item) {
                    add_token($(selected_dropdown_item).data("tokeninput"));
                    return false;
                  }
                  break;

                case KEY.ESCAPE:
                  hide_dropdown();
                  return true;

                default:
                    if(String.fromCharCode(event.which)) {
                        // set a timeout just long enough to let this function finish.
                        setTimeout(function(){do_search();}, 5);
                    }
                    break;
            }
        });

    // Keep a reference to the original input box
    var hidden_input = $(input)
                           .hide()
                           .val("")
                           .focus(function () {
                               input_box.focus();
                           })
                           .blur(function () {
                               input_box.blur();
                           });

    // Keep a reference to the selected token and dropdown item
    var selected_token = null;
    var selected_token_index = 0;
    var selected_dropdown_item = null;

    // The list to store the token items in
    var token_list = $("<ul />")
        .addClass(settings.classes.tokenList)
        .click(function (event) {
            var li = $(event.target).closest("li");
            if(li && li.get(0) && $.data(li.get(0), "tokeninput")) {
                toggle_select_token(li);
            } else {
                // Deselect selected token
                if(selected_token) {
                    deselect_token($(selected_token), POSITION.END);
                }

                // Focus input box
                input_box.focus();
            }
        })
        .mouseover(function (event) {
            var li = $(event.target).closest("li");
            if(li && selected_token !== this) {
                li.addClass(settings.classes.highlightedToken);
            }
        })
        .mouseout(function (event) {
            var li = $(event.target).closest("li");
            if(li && selected_token !== this) {
                li.removeClass(settings.classes.highlightedToken);
            }
        })
        .insertBefore(hidden_input);

    // The token holding the input box
    var input_token = $("<li />")
        .addClass(settings.classes.inputToken)
        .appendTo(token_list)
        .append(input_box);

    // The list to store the dropdown items in
    var dropdown = $("<div>")
        .addClass(settings.classes.dropdown)
        .appendTo("body")
        .hide();

    // Magic element to help us resize the text input
    var input_resizer = $("<tester/>")
        .insertAfter(input_box)
        .css({
            position: "absolute",
            top: -9999,
            left: -9999,
            width: "auto",
            fontSize: input_box.css("fontSize"),
            fontFamily: input_box.css("fontFamily"),
            fontWeight: input_box.css("fontWeight"),
            letterSpacing: input_box.css("letterSpacing"),
            whiteSpace: "nowrap"
        });

    // Pre-populate list if items exist
    hidden_input.val("");
    var li_data = settings.prePopulate || hidden_input.data("pre");
    if(settings.processPrePopulate && $.isFunction(settings.onResult)) {
        li_data = settings.onResult.call(hidden_input, li_data);
    }
    if(li_data && li_data.length) {
        $.each(li_data, function (index, value) {
            insert_token(value);
            checkTokenLimit();
        });
    }


    //
    // Public functions
    //

    this.clear = function() {
        token_list.children("li").each(function() {
            if ($(this).children("input").length === 0) {
                delete_token($(this));
            }
        });
    }

    this.add = function(item) {
        add_token(item);
    }

    this.remove = function(item) {
        token_list.children("li").each(function() {
            if ($(this).children("input").length === 0) {
                var currToken = $(this).data("tokeninput");
                var match = true;
                for (var prop in item) {
                    if (item[prop] !== currToken[prop]) {
                        match = false;
                        break;
                    }
                }
                if (match) {
                    delete_token($(this));
                }
            }
        });
    }

    //
    // Private functions
    //

    function checkTokenLimit() {
        if(settings.tokenLimit !== null && token_count >= settings.tokenLimit) {
            input_box.hide();
            hide_dropdown();
            return;
        } else {
            input_box.focus();
        }
    }

    function resize_input() {
        if(input_val === (input_val = input_box.val())) {return;}

        // Enter new content into resizer and resize input accordingly
        var escaped = input_val.replace(/&/g, '&amp;').replace(/\s/g,' ').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        input_resizer.html(escaped);
        input_box.width(input_resizer.width() + 30);
    }

    function is_printable_character(keycode) {
        return ((keycode >= 48 && keycode <= 90) ||     // 0-1a-z
                (keycode >= 96 && keycode <= 111) ||    // numpad 0-9 + - / * .
                (keycode >= 186 && keycode <= 192) ||   // ; = , - . / ^
                (keycode >= 219 && keycode <= 222));    // ( \ ) '
    }

    // Inner function to a token to the list
    function insert_token(item) {
        var this_token = $("<li><p>"+ item.name +"</p></li>")
          .addClass(settings.classes.token)
          .insertBefore(input_token);

        // The 'delete token' button
        $("<span>" + settings.deleteText + "</span>")
            .addClass(settings.classes.tokenDelete)
            .appendTo(this_token)
            .click(function () {
                delete_token($(this).parent());
                return false;
            });

        // Store data on the token
        var token_data = {"id": item.id, "name": item.name};
        $.data(this_token.get(0), "tokeninput", item);

        // Save this token for duplicate checking
        saved_tokens = saved_tokens.slice(0,selected_token_index).concat([token_data]).concat(saved_tokens.slice(selected_token_index));
        selected_token_index++;

        // Update the hidden input
        var token_ids = $.map(saved_tokens, function (el) {
            return el.id;
        });
        hidden_input.val(token_ids.join(settings.tokenDelimiter));

        token_count += 1;

        return this_token;
    }

    // Add a token to the token list based on user input
    function add_token (item) {
        var callback = settings.onAdd;

        // See if the token already exists and select it if we don't want duplicates
        if(token_count > 0 && settings.preventDuplicates) {
            var found_existing_token = null;
            token_list.children().each(function () {
                var existing_token = $(this);
                var existing_data = $.data(existing_token.get(0), "tokeninput");
                if(existing_data && existing_data.id === item.id) {
                    found_existing_token = existing_token;
                    return false;
                }
            });

            if(found_existing_token) {
                select_token(found_existing_token);
                input_token.insertAfter(found_existing_token);
                input_box.focus();
                return;
            }
        }

        // Insert the new tokens
        insert_token(item);
        checkTokenLimit();

        // Clear input box
        input_box.val("");

        // Don't show the help dropdown, they've got the idea
        hide_dropdown();

        // Execute the onAdd callback if defined
        if($.isFunction(callback)) {
            callback.call(hidden_input,item);
        }
    }

    // Select a token in the token list
    function select_token (token) {
        token.addClass(settings.classes.selectedToken);
        selected_token = token.get(0);

        // Hide input box
        input_box.val("");

        // Hide dropdown if it is visible (eg if we clicked to select token)
        hide_dropdown();
    }

    // Deselect a token in the token list
    function deselect_token (token, position) {
        token.removeClass(settings.classes.selectedToken);
        selected_token = null;

        if(position === POSITION.BEFORE) {
            input_token.insertBefore(token);
            selected_token_index--;
        } else if(position === POSITION.AFTER) {
            input_token.insertAfter(token);
            selected_token_index++;
        } else {
            input_token.appendTo(token_list);
            selected_token_index = token_count;
        }

        // Show the input box and give it focus again
        input_box.focus();
    }

    // Toggle selection of a token in the token list
    function toggle_select_token(token) {
        var previous_selected_token = selected_token;

        if(selected_token) {
            deselect_token($(selected_token), POSITION.END);
        }

        if(previous_selected_token === token.get(0)) {
            deselect_token(token, POSITION.END);
        } else {
            select_token(token);
        }
    }

    // Delete a token from the token list
    function delete_token (token) {
        // Remove the id from the saved list
        var token_data = $.data(token.get(0), "tokeninput");
        var callback = settings.onDelete;

        var index = token.prevAll().length;
        if(index > selected_token_index) index--;

        // Delete the token
        token.remove();
        selected_token = null;

        // Show the input box and give it focus again
        input_box.focus();

        // Remove this token from the saved list
        saved_tokens = saved_tokens.slice(0,index).concat(saved_tokens.slice(index+1));
        if(index < selected_token_index) selected_token_index--;

        // Update the hidden input
        var token_ids = $.map(saved_tokens, function (el) {
            return el.id;
        });
        hidden_input.val(token_ids.join(settings.tokenDelimiter));

        token_count -= 1;

        if(settings.tokenLimit !== null) {
            input_box
                .show()
                .val("")
                .focus();
        }

        // Execute the onDelete callback if defined
        if($.isFunction(callback)) {
            callback.call(hidden_input,token_data);
        }
    }

    // Hide and clear the results dropdown
    function hide_dropdown () {
        dropdown.hide().empty();
        selected_dropdown_item = null;
    }

    function show_dropdown() {
        dropdown
            .css({
                position: "absolute",
                top: $(token_list).offset().top + $(token_list).outerHeight(),
                left: $(token_list).offset().left,
                zindex: 999
            })
            .show();
    }

    function show_dropdown_searching () {
        if(settings.searchingText) {
            dropdown.html("<p>"+settings.searchingText+"</p>");
            show_dropdown();
        }
    }

    function show_dropdown_hint () {
        if(settings.hintText) {
            dropdown.html("<p>"+settings.hintText+"</p>");
            show_dropdown();
        }
    }

    // Highlight the query part of the search term
    function highlight_term(value, term) {
        return value.replace(new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + term + ")(?![^<>]*>)(?![^&;]+;)", "gi"), "<b>$1</b>");
    }

    // Populate the results dropdown with some results
    function populate_dropdown (query, results) {
        if(results && results.length) {
            dropdown.empty();
            var dropdown_ul = $("<ul>")
                .appendTo(dropdown)
                .mouseover(function (event) {
                    select_dropdown_item($(event.target).closest("li"));
                })
                .mousedown(function (event) {
                    add_token($(event.target).closest("li").data("tokeninput"));
                    return false;
                })
                .hide();

            $.each(results, function(index, value) {
                var this_li = $("<li>" + highlight_term(value.name, query) + "</li>")
                                  .appendTo(dropdown_ul);

                if(index % 2) {
                    this_li.addClass(settings.classes.dropdownItem);
                } else {
                    this_li.addClass(settings.classes.dropdownItem2);
                }

                if(index === 0) {
                    select_dropdown_item(this_li);
                }

                $.data(this_li.get(0), "tokeninput", value);
            });

            show_dropdown();

            if(settings.animateDropdown) {
                dropdown_ul.slideDown("fast");
            } else {
                dropdown_ul.show();
            }
        } else {
            if(settings.noResultsText) {
                dropdown.html("<p>"+settings.noResultsText+"</p>");
                show_dropdown();
            }
        }
    }

    // Highlight an item in the results dropdown
    function select_dropdown_item (item) {
        if(item) {
            if(selected_dropdown_item) {
                deselect_dropdown_item($(selected_dropdown_item));
            }

            item.addClass(settings.classes.selectedDropdownItem);
            selected_dropdown_item = item.get(0);
        }
    }

    // Remove highlighting from an item in the results dropdown
    function deselect_dropdown_item (item) {
        item.removeClass(settings.classes.selectedDropdownItem);
        selected_dropdown_item = null;
    }

    // Do a search and show the "searching" dropdown if the input is longer
    // than settings.minChars
    function do_search() {
        var query = input_box.val().toLowerCase();

        if(query && query.length) {
            if(selected_token) {
                deselect_token($(selected_token), POSITION.AFTER);
            }

            if(query.length >= settings.minChars) {
                show_dropdown_searching();
                clearTimeout(timeout);

                timeout = setTimeout(function(){
                    run_search(query);
                }, settings.searchDelay);
            } else {
                hide_dropdown();
            }
        }
    }

    // Do the actual search
    function run_search(query) {
        var cached_results = cache.get(query);
        if(cached_results) {
            populate_dropdown(query, cached_results);
        } else {
            // Are we doing an ajax search or local data search?
            if(settings.url) {
                // Extract exisiting get params
                var ajax_params = {};
                ajax_params.data = {};
                if(settings.url.indexOf("?") > -1) {
                    var parts = settings.url.split("?");
                    ajax_params.url = parts[0];

                    var param_array = parts[1].split("&");
                    $.each(param_array, function (index, value) {
                        var kv = value.split("=");
                        ajax_params.data[kv[0]] = kv[1];
                    });
                } else {
                    ajax_params.url = settings.url;
                }

                // Prepare the request
                ajax_params.data[settings.queryParam] = query;
                ajax_params.type = settings.method;
                ajax_params.dataType = settings.contentType;
                if(settings.crossDomain) {
                    ajax_params.dataType = "jsonp";
                }

                // Attach the success callback
                ajax_params.success = function(results) {
                  if($.isFunction(settings.onResult)) {
                      results = settings.onResult.call(hidden_input, results);
                  }
                  cache.add(query, settings.jsonContainer ? results[settings.jsonContainer] : results);

                  // only populate the dropdown if the results are associated with the active search query
                  if(input_box.val().toLowerCase() === query) {
                      populate_dropdown(query, settings.jsonContainer ? results[settings.jsonContainer] : results);
                  }
                };

                // Make the request
                $.ajax(ajax_params);
            } else if(settings.local_data) {
                // Do the search through local data
                var results = $.grep(settings.local_data, function (row) {
                    return row.name.toLowerCase().indexOf(query.toLowerCase()) > -1;
                });

                if($.isFunction(settings.onResult)) {
                    results = settings.onResult.call(hidden_input, results);
                }
                cache.add(query, results);
                populate_dropdown(query, results);
            }
        }
    }
};

// Really basic cache for the results
$.TokenList.Cache = function (options) {
    var settings = $.extend({
        max_size: 500
    }, options);

    var data = {};
    var size = 0;

    var flush = function () {
        data = {};
        size = 0;
    };

    this.add = function (query, results) {
        if(size > settings.max_size) {
            flush();
        }

        if(!data[query]) {
            size += 1;
        }

        data[query] = results;
    };

    this.get = function (query) {
        return data[query];
    };
};
}(jQuery));*/

;
(function() {

}).call(this);
(function() {

}).call(this);
(function() {

}).call(this);
(function() {

}).call(this);
/*
 * jQuery autoResize (textarea auto-resizer)
 * @copyright James Padolsey http://james.padolsey.com
 * @version 1.04
 */
/*
(function(a){a.fn.autoResize=function(j){var b=a.extend({onResize:function(){},animate:true,animateDuration:150,animateCallback:function(){},extraSpace:20,limit:1000},j);this.filter('textarea').each(function(){var c=a(this).css({resize:'none','overflow-y':'hidden'}),k=c.height(),f=(function(){var l=['height','width','lineHeight','textDecoration','letterSpacing'],h={};a.each(l,function(d,e){h[e]=c.css(e)});return c.clone().removeAttr('id').removeAttr('name').css({position:'absolute',top:0,left:-9999}).css(h).attr('tabIndex','-1').insertBefore(c)})(),i=null,g=function(){f.height(0).val(a(this).val()).scrollTop(10000);var d=Math.max(f.scrollTop(),k)+b.extraSpace,e=a(this).add(f);if(i===d){return}i=d;if(d>=b.limit){a(this).css('overflow-y','');return}b.onResize.call(this);b.animate&&c.css('display')==='block'?e.stop().animate({height:d},b.animateDuration,b.animateCallback):e.height(d)};c.unbind('.dynSiz').bind('keyup.dynSiz',g).bind('keydown.dynSiz',g).bind('change.dynSiz',g)});return this}})(jQuery);
 */
;
/*
 * jQuery Plugin: Tokenizing Autocomplete Text Entry
 * Version 1.6.0
 *
 * Copyright (c) 2009 James Smith (http://loopj.com)
 * Licensed jointly under the GPL and MIT licenses,
 * choose which one suits your project best!
 *
 */
/*
(function ($) {
// Default settings
var DEFAULT_SETTINGS = {
	// Search settings
    method: "GET",
    contentType: "json",
    queryParam: "q",
    searchDelay: 300,
    minChars: 1,
    propertyToSearch: "name",
    jsonContainer: null,

	// Display settings
    hintText: "Type in a search term",
    noResultsText: "No results",
    searchingText: "Searching...",
    deleteText: "&times;",
    animateDropdown: true,

	// Tokenization settings
    tokenLimit: null,
    tokenDelimiter: ",",
    preventDuplicates: false,

	// Output settings
    tokenValue: "id",

	// Prepopulation settings
    prePopulate: null,
    processPrePopulate: false,

	// Manipulation settings
    idPrefix: "token-input-",

	// Formatters
    resultsFormatter: function(item){ return "<li>" + item[this.propertyToSearch]+ "</li>" },
    tokenFormatter: function(item) { return "<li><p>" + item[this.propertyToSearch] + "</p></li>" },

	// Callbacks
    onResult: null,
    onAdd: null,
    onDelete: null,
    onReady: null
};

// Default classes to use when theming
var DEFAULT_CLASSES = {
    tokenList: "token-input-list",
    token: "token-input-token",
    tokenDelete: "token-input-delete-token",
    selectedToken: "token-input-selected-token",
    highlightedToken: "token-input-highlighted-token",
    dropdown: "token-input-dropdown",
    dropdownItem: "token-input-dropdown-item",
    dropdownItem2: "token-input-dropdown-item2",
    selectedDropdownItem: "token-input-selected-dropdown-item",
    inputToken: "token-input-input-token"
};

// Input box position "enum"
var POSITION = {
    BEFORE: 0,
    AFTER: 1,
    END: 2
};

// Keys "enum"
var KEY = {
    BACKSPACE: 8,
    TAB: 9,
    ENTER: 13,
    ESCAPE: 27,
    SPACE: 32,
    PAGE_UP: 33,
    PAGE_DOWN: 34,
    END: 35,
    HOME: 36,
    LEFT: 37,
    UP: 38,
    RIGHT: 39,
    DOWN: 40,
    NUMPAD_ENTER: 108,
    COMMA: 188
};

// Additional public (exposed) methods
var methods = {
    init: function(url_or_data_or_function, options) {
        var settings = $.extend({}, DEFAULT_SETTINGS, options || {});

        return this.each(function () {
            $(this).data("tokenInputObject", new $.TokenList(this, url_or_data_or_function, settings));
        });
    },
    clear: function() {
        this.data("tokenInputObject").clear();
        return this;
    },
    add: function(item) {
        this.data("tokenInputObject").add(item);
        return this;
    },
    remove: function(item) {
        this.data("tokenInputObject").remove(item);
        return this;
    },
    get: function() {
    	return this.data("tokenInputObject").getTokens();
   	}
}

// Expose the .tokenInput function to jQuery as a plugin
$.fn.tokenInput = function (method) {
    // Method calling and initialization logic
    if(methods[method]) {
        return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
    } else {
        return methods.init.apply(this, arguments);
    }
};

// TokenList class for each input
$.TokenList = function (input, url_or_data, settings) {
    //
    // Initialization
    //

    // Configure the data source
    if($.type(url_or_data) === "string" || $.type(url_or_data) === "function") {
        // Set the url to query against
        settings.url = url_or_data;

        // If the URL is a function, evaluate it here to do our initalization work
        var url = computeURL();

        // Make a smart guess about cross-domain if it wasn't explicitly specified
        if(settings.crossDomain === undefined) {
            if(url.indexOf("://") === -1) {
                settings.crossDomain = false;
            } else {
                settings.crossDomain = (location.href.split(/\/+/g)[1] !== url.split(/\/+/g)[1]);
            }
        }
    } else if(typeof(url_or_data) === "object") {
        // Set the local data to search through
        settings.local_data = url_or_data;
    }

    // Build class names
    if(settings.classes) {
        // Use custom class names
        settings.classes = $.extend({}, DEFAULT_CLASSES, settings.classes);
    } else if(settings.theme) {
        // Use theme-suffixed default class names
        settings.classes = {};
        $.each(DEFAULT_CLASSES, function(key, value) {
            settings.classes[key] = value + "-" + settings.theme;
        });
    } else {
        settings.classes = DEFAULT_CLASSES;
    }


    // Save the tokens
    var saved_tokens = [];

    // Keep track of the number of tokens in the list
    var token_count = 0;

    // Basic cache to save on db hits
    var cache = new $.TokenList.Cache();

    // Keep track of the timeout, old vals
    var timeout;
    var input_val;

    // Create a new text input an attach keyup events
    var input_box = $("<input type=\"text\"  autocomplete=\"off\">")
        .css({
            outline: "none"
        })
        .attr("id", settings.idPrefix + input.id)
        .focus(function () {
            if (settings.tokenLimit === null || settings.tokenLimit !== token_count) {
                show_dropdown_hint();
            }
        })
        .blur(function () {
            hide_dropdown();
            $(this).val("");
        })
        .bind("keyup keydown blur update", resize_input)
        .keydown(function (event) {
            var previous_token;
            var next_token;

            switch(event.keyCode) {
                case KEY.LEFT:
                case KEY.RIGHT:
                case KEY.UP:
                case KEY.DOWN:
                    if(!$(this).val()) {
                        previous_token = input_token.prev();
                        next_token = input_token.next();

                        if((previous_token.length && previous_token.get(0) === selected_token) || (next_token.length && next_token.get(0) === selected_token)) {
                            // Check if there is a previous/next token and it is selected
                            if(event.keyCode === KEY.LEFT || event.keyCode === KEY.UP) {
                                deselect_token($(selected_token), POSITION.BEFORE);
                            } else {
                                deselect_token($(selected_token), POSITION.AFTER);
                            }
                        } else if((event.keyCode === KEY.LEFT || event.keyCode === KEY.UP) && previous_token.length) {
                            // We are moving left, select the previous token if it exists
                            select_token($(previous_token.get(0)));
                        } else if((event.keyCode === KEY.RIGHT || event.keyCode === KEY.DOWN) && next_token.length) {
                            // We are moving right, select the next token if it exists
                            select_token($(next_token.get(0)));
                        }
                    } else {
                        var dropdown_item = null;

                        if(event.keyCode === KEY.DOWN || event.keyCode === KEY.RIGHT) {
                            dropdown_item = $(selected_dropdown_item).next();
                        } else {
                            dropdown_item = $(selected_dropdown_item).prev();
                        }

                        if(dropdown_item.length) {
                            select_dropdown_item(dropdown_item);
                        }
                        return false;
                    }
                    break;

                case KEY.BACKSPACE:
                    previous_token = input_token.prev();

                    if(!$(this).val().length) {
                        if(selected_token) {
                            delete_token($(selected_token));
                            hidden_input.change();
                        } else if(previous_token.length) {
                            select_token($(previous_token.get(0)));
                        }

                        return false;
                    } else if($(this).val().length === 1) {
                        hide_dropdown();
                    } else {
                        // set a timeout just long enough to let this function finish.
                        setTimeout(function(){do_search();}, 5);
                    }
                    break;

                case KEY.TAB:
                case KEY.ENTER:
                case KEY.NUMPAD_ENTER:
                case KEY.COMMA:
                  if(selected_dropdown_item) {
                    add_token($(selected_dropdown_item).data("tokeninput"));
                    hidden_input.change();
                    return false;
                  }
                  break;

                case KEY.ESCAPE:
                  hide_dropdown();
                  return true;

                default:
                    if(String.fromCharCode(event.which)) {
                        // set a timeout just long enough to let this function finish.
                        setTimeout(function(){do_search();}, 5);
                    }
                    break;
            }
        });

    // Keep a reference to the original input box
    var hidden_input = $(input)
                           .hide()
                           .val("")
                           .focus(function () {
                               input_box.focus();
                           })
                           .blur(function () {
                               input_box.blur();
                           });

    // Keep a reference to the selected token and dropdown item
    var selected_token = null;
    var selected_token_index = 0;
    var selected_dropdown_item = null;

    // The list to store the token items in
    var token_list = $("<ul />")
        .addClass(settings.classes.tokenList)
        .click(function (event) {
            var li = $(event.target).closest("li");
            if(li && li.get(0) && $.data(li.get(0), "tokeninput")) {
                toggle_select_token(li);
            } else {
                // Deselect selected token
                if(selected_token) {
                    deselect_token($(selected_token), POSITION.END);
                }

                // Focus input box
                input_box.focus();
            }
        })
        .mouseover(function (event) {
            var li = $(event.target).closest("li");
            if(li && selected_token !== this) {
                li.addClass(settings.classes.highlightedToken);
            }
        })
        .mouseout(function (event) {
            var li = $(event.target).closest("li");
            if(li && selected_token !== this) {
                li.removeClass(settings.classes.highlightedToken);
            }
        })
        .insertBefore(hidden_input);

    // The token holding the input box
    var input_token = $("<li />")
        .addClass(settings.classes.inputToken)
        .appendTo(token_list)
        .append(input_box);

    // The list to store the dropdown items in
    var dropdown = $("<div>")
        .addClass(settings.classes.dropdown)
        .appendTo("body")
        .hide();

    // Magic element to help us resize the text input
    var input_resizer = $("<tester/>")
        .insertAfter(input_box)
        .css({
            position: "absolute",
            top: -9999,
            left: -9999,
            width: "auto",
            fontSize: input_box.css("fontSize"),
            fontFamily: input_box.css("fontFamily"),
            fontWeight: input_box.css("fontWeight"),
            letterSpacing: input_box.css("letterSpacing"),
            whiteSpace: "nowrap"
        });

    // Pre-populate list if items exist
    hidden_input.val("");
    var li_data = settings.prePopulate || hidden_input.data("pre");
    if(settings.processPrePopulate && $.isFunction(settings.onResult)) {
        li_data = settings.onResult.call(hidden_input, li_data);
    }
    if(li_data && li_data.length) {
        $.each(li_data, function (index, value) {
            insert_token(value);
            checkTokenLimit();
        });
    }

    // Initialization is done
    if($.isFunction(settings.onReady)) {
        settings.onReady.call();
    }

    //
    // Public functions
    //

    this.clear = function() {
        token_list.children("li").each(function() {
            if ($(this).children("input").length === 0) {
                delete_token($(this));
            }
        });
    }

    this.add = function(item) {
        add_token(item);
    }

    this.remove = function(item) {
        token_list.children("li").each(function() {
            if ($(this).children("input").length === 0) {
                var currToken = $(this).data("tokeninput");
                var match = true;
                for (var prop in item) {
                    if (item[prop] !== currToken[prop]) {
                        match = false;
                        break;
                    }
                }
                if (match) {
                    delete_token($(this));
                }
            }
        });
    }
    
    this.getTokens = function() {
   		return saved_tokens;
   	}

    //
    // Private functions
    //

    function checkTokenLimit() {
        if(settings.tokenLimit !== null && token_count >= settings.tokenLimit) {
            input_box.hide();
            hide_dropdown();
            return;
        }
    }

    function resize_input() {
        if(input_val === (input_val = input_box.val())) {return;}

        // Enter new content into resizer and resize input accordingly
        var escaped = input_val.replace(/&/g, '&amp;').replace(/\s/g,' ').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        input_resizer.html(escaped);
        input_box.width(input_resizer.width() + 30);
    }

    function is_printable_character(keycode) {
        return ((keycode >= 48 && keycode <= 90) ||     // 0-1a-z
                (keycode >= 96 && keycode <= 111) ||    // numpad 0-9 + - / * .
                (keycode >= 186 && keycode <= 192) ||   // ; = , - . / ^
                (keycode >= 219 && keycode <= 222));    // ( \ ) '
    }

    // Inner function to a token to the list
    function insert_token(item) {
        var this_token = settings.tokenFormatter(item);
        this_token = $(this_token)
          .addClass(settings.classes.token)
          .insertBefore(input_token);

        // The 'delete token' button
        $("<span>" + settings.deleteText + "</span>")
            .addClass(settings.classes.tokenDelete)
            .appendTo(this_token)
            .click(function () {
                delete_token($(this).parent());
                hidden_input.change();
                return false;
            });

        // Store data on the token
        var token_data = {"id": item.id};
        token_data[settings.propertyToSearch] = item[settings.propertyToSearch];
        $.data(this_token.get(0), "tokeninput", item);

        // Save this token for duplicate checking
        saved_tokens = saved_tokens.slice(0,selected_token_index).concat([token_data]).concat(saved_tokens.slice(selected_token_index));
        selected_token_index++;

        // Update the hidden input
        update_hidden_input(saved_tokens, hidden_input);

        token_count += 1;

        // Check the token limit
        if(settings.tokenLimit !== null && token_count >= settings.tokenLimit) {
            input_box.hide();
            hide_dropdown();
        }

        return this_token;
    }

    // Add a token to the token list based on user input
    function add_token (item) {
        var callback = settings.onAdd;

        // See if the token already exists and select it if we don't want duplicates
        if(token_count > 0 && settings.preventDuplicates) {
            var found_existing_token = null;
            token_list.children().each(function () {
                var existing_token = $(this);
                var existing_data = $.data(existing_token.get(0), "tokeninput");
                if(existing_data && existing_data.id === item.id) {
                    found_existing_token = existing_token;
                    return false;
                }
            });

            if(found_existing_token) {
                select_token(found_existing_token);
                input_token.insertAfter(found_existing_token);
                input_box.focus();
                return;
            }
        }

        // Insert the new tokens
        if(settings.tokenLimit == null || token_count < settings.tokenLimit) {
            insert_token(item);
            checkTokenLimit();
        }

        // Clear input box
        input_box.val("");

        // Don't show the help dropdown, they've got the idea
        hide_dropdown();

        // Execute the onAdd callback if defined
        if($.isFunction(callback)) {
            callback.call(hidden_input,item);
        }
    }

    // Select a token in the token list
    function select_token (token) {
        token.addClass(settings.classes.selectedToken);
        selected_token = token.get(0);

        // Hide input box
        input_box.val("");

        // Hide dropdown if it is visible (eg if we clicked to select token)
        hide_dropdown();
    }

    // Deselect a token in the token list
    function deselect_token (token, position) {
        token.removeClass(settings.classes.selectedToken);
        selected_token = null;

        if(position === POSITION.BEFORE) {
            input_token.insertBefore(token);
            selected_token_index--;
        } else if(position === POSITION.AFTER) {
            input_token.insertAfter(token);
            selected_token_index++;
        } else {
            input_token.appendTo(token_list);
            selected_token_index = token_count;
        }

        // Show the input box and give it focus again
        input_box.focus();
    }

    // Toggle selection of a token in the token list
    function toggle_select_token(token) {
        var previous_selected_token = selected_token;

        if(selected_token) {
            deselect_token($(selected_token), POSITION.END);
        }

        if(previous_selected_token === token.get(0)) {
            deselect_token(token, POSITION.END);
        } else {
            select_token(token);
        }
    }

    // Delete a token from the token list
    function delete_token (token) {
        // Remove the id from the saved list
        var token_data = $.data(token.get(0), "tokeninput");
        var callback = settings.onDelete;

        var index = token.prevAll().length;
        if(index > selected_token_index) index--;

        // Delete the token
        token.remove();
        selected_token = null;

        // Show the input box and give it focus again
        input_box.focus();

        // Remove this token from the saved list
        saved_tokens = saved_tokens.slice(0,index).concat(saved_tokens.slice(index+1));
        if(index < selected_token_index) selected_token_index--;

        // Update the hidden input
        update_hidden_input(saved_tokens, hidden_input);

        token_count -= 1;

        if(settings.tokenLimit !== null) {
            input_box
                .show()
                .val("")
                .focus();
        }

        // Execute the onDelete callback if defined
        if($.isFunction(callback)) {
            callback.call(hidden_input,token_data);
        }
    }

    // Update the hidden input box value
    function update_hidden_input(saved_tokens, hidden_input) {
        var token_values = $.map(saved_tokens, function (el) {
            return el[settings.tokenValue];
        });
        hidden_input.val(token_values.join(settings.tokenDelimiter));

    }

    // Hide and clear the results dropdown
    function hide_dropdown () {
        dropdown.hide().empty();
        selected_dropdown_item = null;
    }

    function show_dropdown() {
        dropdown
            .css({
                position: "absolute",
                top: $(token_list).offset().top + $(token_list).outerHeight(),
                left: $(token_list).offset().left,
                zindex: 999
            })
            .show();
    }

    function show_dropdown_searching () {
        if(settings.searchingText) {
            dropdown.html("<p>"+settings.searchingText+"</p>");
            show_dropdown();
        }
    }

    function show_dropdown_hint () {
        if(settings.hintText) {
            dropdown.html("<p>"+settings.hintText+"</p>");
            show_dropdown();
        }
    }

    // Highlight the query part of the search term
    function highlight_term(value, term) {
        return value.replace(new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + term + ")(?![^<>]*>)(?![^&;]+;)", "gi"), "<b>$1</b>");
    }
    
    function find_value_and_highlight_term(template, value, term) {
        return template.replace(new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + value + ")(?![^<>]*>)(?![^&;]+;)", "g"), highlight_term(value, term));
    }

    // Populate the results dropdown with some results
    function populate_dropdown (query, results) {
        if(results && results.length) {
            dropdown.empty();
            var dropdown_ul = $("<ul>")
                .appendTo(dropdown)
                .mouseover(function (event) {
                    select_dropdown_item($(event.target).closest("li"));
                })
                .mousedown(function (event) {
                    add_token($(event.target).closest("li").data("tokeninput"));
                    hidden_input.change();
                    return false;
                })
                .hide();

            $.each(results, function(index, value) {
                var this_li = settings.resultsFormatter(value);
                
                this_li = find_value_and_highlight_term(this_li ,value[settings.propertyToSearch], query);            
                
                this_li = $(this_li).appendTo(dropdown_ul);
                
                if(index % 2) {
                    this_li.addClass(settings.classes.dropdownItem);
                } else {
                    this_li.addClass(settings.classes.dropdownItem2);
                }

                if(index === 0) {
                    select_dropdown_item(this_li);
                }

                $.data(this_li.get(0), "tokeninput", value);
            });

            show_dropdown();

            if(settings.animateDropdown) {
                dropdown_ul.slideDown("fast");
            } else {
                dropdown_ul.show();
            }
        } else {
            if(settings.noResultsText) {
                dropdown.html("<p>"+settings.noResultsText+"</p>");
                show_dropdown();
            }
        }
    }

    // Highlight an item in the results dropdown
    function select_dropdown_item (item) {
        if(item) {
            if(selected_dropdown_item) {
                deselect_dropdown_item($(selected_dropdown_item));
            }

            item.addClass(settings.classes.selectedDropdownItem);
            selected_dropdown_item = item.get(0);
        }
    }

    // Remove highlighting from an item in the results dropdown
    function deselect_dropdown_item (item) {
        item.removeClass(settings.classes.selectedDropdownItem);
        selected_dropdown_item = null;
    }

    // Do a search and show the "searching" dropdown if the input is longer
    // than settings.minChars
    function do_search() {
        var query = input_box.val().toLowerCase();

        if(query && query.length) {
            if(selected_token) {
                deselect_token($(selected_token), POSITION.AFTER);
            }

            if(query.length >= settings.minChars) {
                show_dropdown_searching();
                clearTimeout(timeout);

                timeout = setTimeout(function(){
                    run_search(query);
                }, settings.searchDelay);
            } else {
                hide_dropdown();
            }
        }
    }

    // Do the actual search
    function run_search(query) {
        var cache_key = query + computeURL();
        var cached_results = cache.get(cache_key);
        if(cached_results) {
            populate_dropdown(query, cached_results);
        } else {
            // Are we doing an ajax search or local data search?
            if(settings.url) {
                var url = computeURL();
                // Extract exisiting get params
                var ajax_params = {};
                ajax_params.data = {};
                if(url.indexOf("?") > -1) {
                    var parts = url.split("?");
                    ajax_params.url = parts[0];

                    var param_array = parts[1].split("&");
                    $.each(param_array, function (index, value) {
                        var kv = value.split("=");
                        ajax_params.data[kv[0]] = kv[1];
                    });
                } else {
                    ajax_params.url = url;
                }

                // Prepare the request
                ajax_params.data[settings.queryParam] = query;
                ajax_params.type = settings.method;
                ajax_params.dataType = settings.contentType;
                if(settings.crossDomain) {
                    ajax_params.dataType = "jsonp";
                }

                // Attach the success callback
                ajax_params.success = function(results) {
                  if($.isFunction(settings.onResult)) {
                      results = settings.onResult.call(hidden_input, results);
                  }
                  cache.add(cache_key, settings.jsonContainer ? results[settings.jsonContainer] : results);

                  // only populate the dropdown if the results are associated with the active search query
                  if(input_box.val().toLowerCase() === query) {
                      populate_dropdown(query, settings.jsonContainer ? results[settings.jsonContainer] : results);
                  }
                };

                // Make the request
                $.ajax(ajax_params);
            } else if(settings.local_data) {
                // Do the search through local data
                var results = $.grep(settings.local_data, function (row) {
                    return row[settings.propertyToSearch].toLowerCase().indexOf(query.toLowerCase()) > -1;
                });

                if($.isFunction(settings.onResult)) {
                    results = settings.onResult.call(hidden_input, results);
                }
                cache.add(cache_key, results);
                populate_dropdown(query, results);
            }
        }
    }

    // compute the dynamic URL
    function computeURL() {
        var url = settings.url;
        if(typeof settings.url == 'function') {
            url = settings.url.call();
        }
        return url;
    }
};

// Really basic cache for the results
$.TokenList.Cache = function (options) {
    var settings = $.extend({
        max_size: 500
    }, options);

    var data = {};
    var size = 0;

    var flush = function () {
        data = {};
        size = 0;
    };

    this.add = function (query, results) {
        if(size > settings.max_size) {
            flush();
        }

        if(!data[query]) {
            size += 1;
        }

        data[query] = results;
    };

    this.get = function (query) {
        return data[query];
    };
};
}(jQuery)); */

;
//fgnass.github.com/spin.js#v1.2.2
(function(a,b,c){function n(a){var b={x:a.offsetLeft,y:a.offsetTop};while(a=a.offsetParent)b.x+=a.offsetLeft,b.y+=a.offsetTop;return b}function m(a){for(var b=1;b<arguments.length;b++){var d=arguments[b];for(var e in d)a[e]===c&&(a[e]=d[e])}return a}function l(a,b){for(var c in b)a.style[k(a,c)||c]=b[c];return a}function k(a,b){var e=a.style,f,g;if(e[b]!==c)return b;b=b.charAt(0).toUpperCase()+b.slice(1);for(g=0;g<d.length;g++){f=d[g]+b;if(e[f]!==c)return f}}function j(a,b,c,d){var g=["opacity",b,~~(a*100),c,d].join("-"),h=.01+c/d*100,j=Math.max(1-(1-a)/b*(100-h),a),k=f.substring(0,f.indexOf("Animation")).toLowerCase(),l=k&&"-"+k+"-"||"";e[g]||(i.insertRule("@"+l+"keyframes "+g+"{"+"0%{opacity:"+j+"}"+h+"%{opacity:"+a+"}"+(h+.01)+"%{opacity:1}"+(h+b)%100+"%{opacity:"+a+"}"+"100%{opacity:"+j+"}"+"}",0),e[g]=1);return g}function h(a,b,c){c&&!c.parentNode&&h(a,c),a.insertBefore(b,c||null);return a}function g(a,c){var d=b.createElement(a||"div"),e;for(e in c)d[e]=c[e];return d}var d=["webkit","Moz","ms","O"],e={},f,i=function(){var a=g("style");h(b.getElementsByTagName("head")[0],a);return a.sheet||a.styleSheet}(),o=function r(a){if(!this.spin)return new r(a);this.opts=m(a||{},r.defaults,p)},p=o.defaults={lines:12,length:7,width:5,radius:10,color:"#000",speed:1,trail:100,opacity:.25,fps:20},q=o.prototype={spin:function(a){this.stop();var b=this,c=b.el=l(g(),{position:"relative"}),d,e;a&&(e=n(h(a,c,a.firstChild)),d=n(c),l(c,{left:(a.offsetWidth>>1)-d.x+e.x+"px",top:(a.offsetHeight>>1)-d.y+e.y+"px"})),c.setAttribute("aria-role","progressbar"),b.lines(c,b.opts);if(!f){var i=b.opts,j=0,k=i.fps,m=k/i.speed,o=(1-i.opacity)/(m*i.trail/100),p=m/i.lines;(function q(){j++;for(var a=i.lines;a;a--){var d=Math.max(1-(j+a*p)%m*o,i.opacity);b.opacity(c,i.lines-a,d,i)}b.timeout=b.el&&setTimeout(q,~~(1e3/k))})()}return b},stop:function(){var a=this.el;a&&(clearTimeout(this.timeout),a.parentNode&&a.parentNode.removeChild(a),this.el=c);return this}};q.lines=function(a,b){function e(a,d){return l(g(),{position:"absolute",width:b.length+b.width+"px",height:b.width+"px",background:a,boxShadow:d,transformOrigin:"left",transform:"rotate("+~~(360/b.lines*c)+"deg) translate("+b.radius+"px"+",0)",borderRadius:(b.width>>1)+"px"})}var c=0,d;for(;c<b.lines;c++)d=l(g(),{position:"absolute",top:1+~(b.width/2)+"px",transform:"translate3d(0,0,0)",opacity:b.opacity,animation:f&&j(b.opacity,b.trail,c,b.lines)+" "+1/b.speed+"s linear infinite"}),b.shadow&&h(d,l(e("#000","0 0 4px #000"),{top:"2px"})),h(a,h(d,e(b.color,"0 0 1px rgba(0,0,0,.1)")));return a},q.opacity=function(a,b,c){b<a.childNodes.length&&(a.childNodes[b].style.opacity=c)},function(){var a=l(g("group"),{behavior:"url(#default#VML)"}),b;if(!k(a,"transform")&&a.adj){for(b=4;b--;)i.addRule(["group","roundrect","fill","stroke"][b],"behavior:url(#default#VML)");q.lines=function(a,b){function k(a,d,i){h(f,h(l(e(),{rotation:360/b.lines*a+"deg",left:~~d}),h(l(g("roundrect",{arcsize:1}),{width:c,height:b.width,left:b.radius,top:-b.width>>1,filter:i}),g("fill",{color:b.color,opacity:b.opacity}),g("stroke",{opacity:0}))))}function e(){return l(g("group",{coordsize:d+" "+d,coordorigin:-c+" "+ -c}),{width:d,height:d})}var c=b.length+b.width,d=2*c,f=e(),i=~(b.length+b.radius+b.width)+"px",j;if(b.shadow)for(j=1;j<=b.lines;j++)k(j,-2,"progid:DXImageTransform.Microsoft.Blur(pixelradius=2,makeshadow=1,shadowopacity=.3)");for(j=1;j<=b.lines;j++)k(j);return h(l(a,{margin:i+" 0 0 "+i,zoom:1}),f)},q.opacity=function(a,b,c,d){var e=a.firstChild;d=d.shadow&&d.lines||0,e&&b+d<e.childNodes.length&&(e=e.childNodes[b+d],e=e&&e.firstChild,e=e&&e.firstChild,e&&(e.opacity=c))}}else f=k(a,"animation")}(),a.Spinner=o})(window,document);
//$(document).ready(function() {
$(document).on("keyup.autocomplete", '#search_car', function(){ $(this).autocomplete({
        minLength:2,
        format:"js",
        // source: "/search/autocomplete_items?search_type=" + $("#plannto_search_type").val() ,
        source:function (request, response) {
            var opts = {
                lines:12, // The number of lines to draw
                length:5, // The length of each line
                width:4, // The line thickness
                radius:5, // The radius of the inner circle
                color:'#2EFE9A', // #rgb or #rrggbb
                speed:1, // Rounds per second
                trail:50, // Afterglow percentage
                shadow:true, // Whether to render a shadow
                hwaccel:false // Whether to use hardware acceleration
            };
            //       var target = document.getElementById('search_car');
            //       var spinner = new Spinner(opts).spin(target);
            $.ajax(
            {
                url:"/search/autocomplete_items",
                data:{
                    term:$("#search_car").val(),
                    search_type:$("#category").val(),
                    authenticity_token: window._token,
                    from_profile: true
                },
                type:"GET",
                dataType:"json",
                success:function (data) {
                    response($.map(data, function (item) {
                        return{
                            id:item.id,
                            value:item.value,
                            imgsrc:item.imgsrc,
                            type:item.type,
                            url:item.url
                        }
                    }));
                //           spinner.stop();
                }
            });
        },
        focus:function (e, ui) {
            return false
        },
        select: function( event, ui ) {
            $.ajax(
            {
                url:"/preferences/plan_to_buy?item_id="+ui.item.id+"&follow_type="+ "Buyer&buying_plan_id=" + $("#buying_plan_id").val() + "&per_page=" + $("#per_page_value").val(),
                type:"GET",
                dataType:"script"
            });
        }
    })
    if ($("#search_car").index() != -1) {
        $("#search_car").data("autocomplete")._renderItem = function (ul, item, index) {
            if (index == -1) {
                return $("<li></li>")
                .data("item.autocomplete", item)
                .append("<a class='searchMore'>" + item.value + "" + "</a>")
                .appendTo(ul);
            }
            else {
                return $("<li></li>")
                .data("item.autocomplete", item)
                .append('<a>' + "<div style='margin-left:5px;float:left'><img width='40' height='40' src='" + item.imgsrc + "' /></div>" + "<div style='margin-left:53px;'><span class='atext'>" + item.value + "</span><br/><span class ='atext'>" + item.type + "</span></div></a>")
                .appendTo(ul);
            }
        }
    }

    $('#plantobuyPaginate div.pagination a').click(function() {
    //$('#plantobuyPaginate div.pagination a').live('click', function(){
        var page = $(this).text()
        var current = $('em.current').text();
        if (page == "← Previous"){
            page = parseInt(current) -1
        }
        else if (page == "Next →"){
            page = parseInt(current) + 1
        }

        $.ajax(
        {
            url:"/preferences/plan_to_buy?follow_type=" + ""+ "&buying_plan_id=" + $("#buying_plan_id").val() + "&page=" + page + "&per_page=" + $("#per_page_value").val(),
            type:"GET",
            dataType:"script"
        });
        
        return false;
    })

});


(function() {
  var root;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  root = typeof exports !== "undefined" && exports !== null ? exports : this;
  root.Product = {
    load_buyer: function(item_id, medium, message, follow_message) {
      var buy_href_follow, follow_href_follow;
      $("#plan_to_buy" + item_id).removeClass().addClass("plan_to_buy_icon_selected" + medium);
      $("#plan_to_buy_span" + item_id).removeClass().addClass("action_btns_selected" + medium);
      $("#plan_to_buy" + item_id).attr("title", message);
      $("#plan_to_follow" + item_id).attr("title", follow_message);
      $("#plan_to_follow" + item_id).removeClass().addClass("plan_to_follow_icon_selected" + medium);
      $("#plan_to_follow_span" + item_id).removeClass().addClass("action_btns_selected" + medium);
      $("#plan_to_own" + item_id).removeClass().addClass("plan_to_own_icon" + medium);
      $("#plan_to_own_span" + item_id).removeClass().addClass("action_btns" + medium);
      buy_href_follow = $("#plan_to_buy" + item_id).attr("href");
      $("#plan_to_buy" + item_id).attr("href", buy_href_follow + '&unfollow=true');
      follow_href_follow = $("#plan_to_follow" + item_id).attr("href");
      return $("#plan_to_follow" + item_id).attr("href", buy_href_follow + '&unfollow=true');
    },
    load_owner: function(item_id, medium, message, follow_message) {
      var follow_href_follow, own_href_follow;
      $("#plan_to_own" + item_id).removeClass().addClass("plan_to_own_icon_selected" + medium);
      $("#plan_to_own_span" + item_id).removeClass().addClass("action_btns_selected" + medium);
      $("#plan_to_own" + item_id).attr("title", message);
      $("#plan_to_follow" + item_id).attr("title", follow_message);
      $("#plan_to_follow" + item_id).removeClass().addClass("plan_to_follow_icon_selected" + medium);
      $("#plan_to_follow_span" + item_id).removeClass().addClass("action_btns_selected" + medium);
      own_href_follow = $("#plan_to_own" + item_id).attr("href");
      $("#plan_to_own" + item_id).attr("href", own_href_follow + '&unfollow=true');
      follow_href_follow = $("#plan_to_follow" + item_id).attr("href");
      $("#plan_to_follow" + item_id).attr("href", follow_href_follow + '&unfollow=true');
      $("#plan_to_buy_span" + item_id).removeClass();
      $("#plan_to_buy" + item_id).removeClass().addClass("plan_to_buy_icon" + medium);
      return $("#plan_to_buy_span" + item_id).addClass("action_btns" + medium);
    },
    load_follow: function(item_id, medium, follow_message) {
      var follow_href_follow;
      $("#plan_to_follow" + item_id).removeClass();
      $("#plan_to_follow" + item_id).removeClass().addClass("plan_to_follow_icon_selected" + medium);
      $("#plan_to_follow_span" + item_id).removeClass().addClass("action_btns_selected" + medium);
      $("#plan_to_follow" + item_id).attr("title", follow_message);
      $("#plan_to_buy" + item_id).removeClass().addClass("plan_to_buy_icon" + medium);
      $("#plan_to_buy_span" + item_id).removeClass().addClass("action_btns" + medium);
      $("#plan_to_own_span" + item_id).removeClass().addClass("action_btns" + medium);
      $("#plan_to_own" + item_id).removeClass().addClass("plan_to_own_icon" + medium);
      follow_href_follow = $("#plan_to_follow" + item_id).attr("href");
      return $("#plan_to_follow" + item_id).attr("href", follow_href_follow + '&unfollow=true');
    },
    unload_buyer: __bind(function(item_id, medium, message, follow_message) {
      var buy_href_follow, follow_href_follow;
      $("#plan_to_buy" + item_id).removeClass().addClass("plan_to_buy_icon" + medium);
      $("#plan_to_buy_span" + item_id).removeClass().addClass("action_btns" + medium);
      $("#plan_to_buy" + item_id).attr("title", message);
      $("#plan_to_follow" + item_id).attr("title", follow_message);
      $("#plan_to_follow" + item_id).removeClass().addClass("plan_to_follow_icon" + medium);
      $("#plan_to_follow_span" + item_id).removeClass().addClass("action_btns" + medium);
      follow_href_follow = $("#plan_to_follow" + item_id).attr("href");
      $("#plan_to_follow" + item_id).attr("href", Product.remove_unfollow_query_string(follow_href_follow, "Follow"));
      buy_href_follow = $("#plan_to_buy" + item_id).attr("href");
      return $("#plan_to_buy" + item_id).attr("href", Product.remove_unfollow_query_string(buy_href_follow, "Buyer"));
    }, this),
    unload_owner: function(item_id, medium, message, follow_message) {
      var follow_href_follow, own_href_follow;
      $("#plan_to_own" + item_id).removeClass().addClass("plan_to_own_icon" + medium);
      $("#plan_to_own_span" + item_id).removeClass().addClass("action_btns" + medium);
      $("#plan_to_own" + item_id).attr("title", message);
      $("#plan_to_follow" + item_id).attr("title", follow_message);
      $("#plan_to_follow" + item_id).removeClass().addClass("plan_to_follow_icon" + medium);
      $("#plan_to_follow_span" + item_id).removeClass().addClass("action_btns" + medium);
      own_href_follow = $("#plan_to_own" + item_id).attr("href");
      $("#plan_to_own" + item_id).attr("href", Product.remove_unfollow_query_string(own_href_follow, "Owner"));
      follow_href_follow = $("#plan_to_follow" + item_id).attr("href");
      return $("#plan_to_follow" + item_id).attr("href", Product.remove_unfollow_query_string(follow_href_follow, "Follow"));
    },
    unload_follow: function(item_id, medium, follow_message) {
      var follow_href_follow;
      $("#plan_to_follow" + item_id).removeClass().addClass("plan_to_follow_icon" + medium);
      $("#plan_to_follow_span" + item_id).removeClass().addClass("action_btns" + medium);
      $("#plan_to_buy" + item_id).removeClass().addClass("plan_to_buy_icon" + medium);
      $("#plan_to_buy_span" + item_id).removeClass().addClass("action_btns" + medium);
      $("#plan_to_own" + item_id).removeClass().addClass("plan_to_own_icon" + medium);
      $("#plan_to_own_span" + item_id).removeClass().addClass("action_btns" + medium);
      $("#plan_to_follow" + item_id).attr("title", follow_message);
      follow_href_follow = $("#plan_to_follow" + item_id).attr("href");
      return $("#plan_to_follow" + item_id).attr("href", Product.remove_unfollow_query_string(follow_href_follow, "Follow"));
    },
    remove_unfollow_query_string: function(url_path, follow_type) {
      var pars, urlparts;
      urlparts = url_path.split('?');
      pars = urlparts[1].split(/[&;]/g);
      pars.pop();
      return urlparts[0] + "?" + pars.join('&');
    },
    hover_follow_but: function(but_object, from_message, to_message) {
      return $(but_object).hover((function() {
        return $(this).html(to_message);
      }), function() {
        return $(this).html(from_message);
      });
    },
    related_products: function(related_product_url) {
      return $(document).ready(function() {
        return $.ajax({
          url: related_product_url,
          dataType: "html",
          success: function(data) {
            return $("#uisideRelatedProduct").html(data);
          }
        });
      });
    },
    load_signout_user_link: function() {
      return $("#plan_to_buy_select").attr("data-url", "javascript:void(0)");
    },
    login_dialog: function() {
      return $("#dialog-form").dialog({
        autoOpen: false,
        height: 600,
        width: 350,
        modal: true,
        close: function() {
          return allFields.val("").removeClass("ui-state-error");
        }
      });
    },
    show_login_dialog: function(dom_elements) {
      return $(dom_elements).click(function() {
        $(".Close_dialog").show();
        $(".ui-dialog-titlebar").hide();
        return $("#dialog-form").dialog("open");
      });
    },
    show_login_dialog_change: function(dom_elements) {
      return $(dom_elements).change(function() {
        return $("#dialog-form").dialog("open");
      });
    },
    hide_login_dialog: function() {
      return $("#dialog-form").hide();
    },
    detailed_specification: function() {
      return $("#detailed_specification").click(function() {
        $("#usual2 ul").idTabs("tabs5");
        $("#specification").trigger("click");
        return $("#specification").closest("ul").find("li").each(function(index) {
          if ($(this).hasClass("tab_active")) {
            $(this).removeClass("tab_active");
          }
          return $("#specification").closest("li").addClass("tab_active");
        });
      });
    },
    show_notice: function(flash_message) {
      return $("#comment-notice").html('<div class="flash notice">' + flash_message + '</div>').effect("highlight", {}, 3000);
    },
    invite_dialog: function() {
      return $("#dialog-invite-form").dialog({
        autoOpen: false,
        height: 300,
        width: 350,
        modal: true,
        title: "Invite",
        buttons: {
          "Send": function() {
            var bValid;
            bValid = true;
            if (bValid) {
              return $("#new_invitation").submit();
            }
          },
          Cancel: function() {
            return $(this).dialog("close");
          }
        },
        close: function() {
          return $(this).find(":input").val("").removeClass("ui-state-error");
        }
      });
    },
    show_invite_dialog: function(dom_elements) {
      return $(dom_elements).click(function() {
        var id;
        id = $(this).attr('id');
        if (id === 'invite_buy') {
          $('#invitation_follow_type').val(0);
        } else if (id === 'invite_own') {
          $('#invitation_follow_type').val(1);
        } else {
          $('#invitation_follow_type').val(2);
        }
        return $("#dialog-invite-form").dialog("open");
      });
    }
  };
}).call(this);
$(function(){
	$('#answer_this_question').click(function(){
		$('#new_answer_content_block').toggle();
	});
});
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
;
(function() {

}).call(this);
/*$(function(){


$('#new_review_content #rating').each(function(){
	console.log($(this).attr('class'));
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
*/

;
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


var SEARCH_URL = '/search';
var checkBoxIds= "";

function showSearchPack(){
    if ($(".search_category").find("li").length == 0){
        $(".searchPack").slideDown();
    }
}

function showClearTag(){
    if ($(".search_category").find("li").length == 0){
        $("#clearTag").show();
    }
}

function validateSearchField(fieldVal1, fieldVal2){
    if ((fieldVal1 == "")|| (fieldVal2 == "")){
        alert("Please select a search criteria.");
        return false
    }
}
function hideSearchPack(){
    if ($(".search_category").find("li").length == 0){
        $(".searchPack").slideUp();
    }
}


function searchData(fieldName){

var opts = {
        lines: 12, // The number of lines to draw
        length: 4, // The length of each line
        width: 4, // The line thickness
        radius: 8, // The radius of the inner circle
       // color: '#2EFE9A', // #rgb or #rrggbb
        color: '#000',
        speed: 1, // Rounds per second
        trail: 60, // Afterglow percentage
        shadow: true, // Whether to render a shadow
        hwaccel: false // Whether to use hardware acceleration
    };
    var target = document.getElementById(fieldName);
    var spinner = new Spinner(opts).spin(target);
    $.get(SEARCH_URL,$("#searchForm").serialize(),null,"script").success(function() {
        spinner.stop();
    })
}

function removeAllTags(){
    $(".search_category").find("li").remove();
    $(".box").show()
}

function hideClearTag(){
    if ($(".search_category").find("li").length == 0){
        $("#clearTag").hide();
    }
}

function hidePreferenceTag(){
    if ($(".search_category").find("li").length == 0){
        $("#addPreferenceTag").hide();
    }
}

function hideGetAdviceTag(){
    if ($(".search_category").find("li").length == 0){
        $("#getAdviceTag").hide();
    }
}

function store_info_div(type, sender){
    var value_selector = "#" + type +""

    if ($(value_selector).text() == "") {
        var ids = [];
    } else {
        var ids = $(value_selector).text().split(",");
    }
    var add = true
    $.each(ids, function(index, value) {
        if (value.toString() == sender.value.toString())  {
            add = false;
        }
    });
    if (add == true){
        ids.push(sender.value);
    }
    $(value_selector).text(ids.toString());
}

function store_ids(type, sender) {

    var value_selector = "#" + type +""

    if ($(value_selector).val() == "") {
        var ids = [];
    } else {
        var ids = $(value_selector).val().split(",");
    }
    var add = true
    $.each(ids, function(index, value) {
        if (value.toString() == sender.value.toString())  {
            add = false;
        }
    });
    if (add == true){
        ids.push(sender.value);
    }
    $(value_selector).val(ids.toString());
};

function resetForm(form_id){

    $(':input','#' + form_id + '')
    .not(':button, :submit, :reset, :hidden')
    .val('')
    .removeAttr('checked')
    .removeAttr('selected');

}

function openInfoBox(displayInfo, attr_name, elem){
    var searchCriteriaFieldId = $(elem).attr('id');
    resetUnwantedFormFields();
    $( "#searchCriteriaLabel" ).html(" ")
    $( "#criteriaHeading" ).html(" ")
    $("#which_attribute").val($(elem).attr('id'));
    $("#which_form_field").val(attr_name);
    $("#which_type").val(displayInfo.vth);
    $("#which_unit").val(displayInfo.ut);    
    $(".ui-autocomplete").hide();
    $("#criteriaPopup #autocompleteField").hide();
    $(".jslider").hide()
    if (displayInfo.vt == "Between"){
        var min_v;
        var max_v;
        min_v = $( "#min_" + attr_name ).val() == "" ? displayInfo.min_v : $( "#min_" + attr_name ).val()
        max_v = $( "#max_" + attr_name ).val() == "" ? displayInfo.max_v : $( "#max_" + attr_name ).val()
        $("#which_type").val('Between');
        var position = $("#" + searchCriteriaFieldId).position();
        $("#criteriaPopup").hide();
        $("#criteriaPopup").css({
            "position": "absolute",
            "top": (position.top -15)+ "px",
            "left":(position.left+210) + "px"
        }).show();
        $( "#criteriaHeading" ).html(displayInfo.adn)
        var  rangeVal = displayInfo.range.split(",")
        var heteroVal1 = "25/" + rangeVal[1]
        var heteroVal2 = "50/" + rangeVal[2]
        var heteroVal3 = "75/" + rangeVal[3]
        $( "#Slider" + attr_name).val( "" +displayInfo.min_v + ";" + displayInfo.max_v + "");
        if ($('#Slider' + attr_name).next(".jslider").length == 0){
            jQuery("#Slider" + attr_name).slider({
                from: parseFloat(displayInfo.min_v),
                to: parseFloat(displayInfo.max_v),
                step: displayInfo.step,
                round: 0,
                dimension: "&nbsp;" + displayInfo.ut,
                heterogeneity: [heteroVal1, heteroVal2, heteroVal3],
                scale: [rangeVal[0], '|', rangeVal[1], '|', rangeVal[2], '|', rangeVal[3], '|', rangeVal[4]],
                skin: "plastic",
                calculate: function(value){
                    return value
                },
                onstatechange: function(value) {
                    var  sliderVal = value.split(";")
                    $("#form_field_val").val(value);
                    var searchCriteria = $("#which_type").val() + " "  + sliderVal[ 0 ] + " " + $("#which_unit").val() + " - " + sliderVal[ 1 ] + " "  + $("#which_unit").val()
                    $("#searchCriteriaLabel").html(searchCriteria)
                }
            });
        }
        else{
            $('#Slider' + attr_name).next(".jslider").show()
            $('#Slider' + attr_name).slider( "value", parseFloat(displayInfo.min_v), parseFloat(displayInfo.max_v) )
            //$( "#Slider" + attr_name).val( "" +parseFloat(displayInfo.min_v) + ";" + parseFloat(displayInfo.max_v) + "");
            var searchCriteria = $("#which_type").val() + " "  + min_v + " " + $("#which_unit").val() + " - " + max_v + " "  + $("#which_unit").val()
            $("#searchCriteriaLabel").html(searchCriteria)
        }
        return false;
    }
    else if ((displayInfo.vt == "GreaterThan") || (displayInfo.vt == "LessThen")){
        var actual_value;
        if (displayInfo.vt == "GreaterThan"){
            actual_value = $( "#" + attr_name ).val() == "" ? parseFloat(displayInfo.av) : parseFloat($( "#" + attr_name ).val())
        }
        else{
            actual_value = $( "#" + attr_name ).val() == "" ? parseFloat(displayInfo.max_v) : parseFloat($( "#" + attr_name ).val())
        }

        var position = $("#" + searchCriteriaFieldId).position();
        $("#criteriaPopup").css({
            "position": "absolute",
            "top": (position.top -15)+ "px",
            "left":(position.left+210) + "px"
        }).show();
        $( "#criteriaHeading" ).html(displayInfo.adn)

        //$("#dialog").dialog({title: displayInfo.adn});
        var  rangeVal = displayInfo.range.split(",")
        var heteroVal1 = "25/" + rangeVal[1]
        var heteroVal2 = "50/" + rangeVal[2]
        var heteroVal3 = "75/" + rangeVal[3]

        $( "#Slider" +attr_name ).val( actual_value );
        if ($('#Slider' + attr_name).next(".jslider").length == 0){
            jQuery("#Slider" + attr_name).slider({
                from: parseFloat(displayInfo.min_v),
                to: parseFloat(displayInfo.max_v),
                step: displayInfo.step,
                round: 1,
                dimension: "&nbsp;" + displayInfo.ut,
                heterogeneity: [heteroVal1, heteroVal2, heteroVal3],
                scale: [rangeVal[0], '|', rangeVal[1], '|', rangeVal[2], '|', rangeVal[3], '|', rangeVal[4]],
                skin: "plastic",
                calculate: function(value){
                    return parseFloat(value)
                },
                onstatechange: function(value) {
                    var  sliderVal = value
                    $( "#form_field_val").val( sliderVal );
                    var searchCriteria = $("#which_type").val() + " "  + sliderVal + " " + $("#which_unit").val()
                    $("#searchCriteriaLabel").html(searchCriteria)
                }
            });
        }
        else{
            $('#Slider' + attr_name).next(".jslider").show()
            var searchCriteria = $("#which_type").val() + " "  + actual_value + " " + $("#which_unit").val();
            $('#Slider' + attr_name).slider( "value", actual_value )
            $("#searchCriteriaLabel").html(searchCriteria)
            $( "#form_field_val" ).val( actual_value );
        }
        return false;
    }
    else if (displayInfo.vt == "Click"){
        showSearchPack()
        showClearTag();
        showPreferenceTag();
        showGetAdviceTag();
        var booleanObject = jQuery.parseJSON(attr_name);
        $("#which_form_field").val(booleanObject.field_id);
        var tagId = $("#which_attribute").val() + "_tag"
        //if this attribute already has a different tag then lets remove it.
        removeMultipleAttributeInstance(booleanObject.field_id, tagId);

        var list = "<li id='" + tagId + "'" + " class='middlebg'  style= 'height:40px;'><span class='title_txt'>" + booleanObject.display_name + "<a id= 'deleteTag' class='icon_close'></a></span></li>" ;
        $(list).appendTo('.search_category');
        $("#" + $("#which_attribute").val()).hide();
        $( "#" + booleanObject.field_id ).val( booleanObject.value );
        $("#page").val(1)
        searchData('spinner')
        //$.get('/search',$("#searchForm").serialize(),null,"script");
        return false
    }
    else if (displayInfo.vt == "ListOfValues"){
        var position = $("#" + searchCriteriaFieldId).position();
        $("#criteriaPopup").css({
            "position": "absolute",
            "top": (position.top -15)+ "px",
            "left":(position.left+210) + "px"
        }).show();
        $( "#criteriaHeading" ).html(displayInfo.adn)
        $("#searchCriteriaLabel").text('');
        $("#" + attr_name).val('');
        if ($("#criteriaPopup #autocompleteField").size() > 0){
            var typeList =loadTypes();
            $( "#criteriaPopup #autocompleteField" ).autocomplete({
                minLength: 0,
                minChars: 0,
                max:10,
                source: typeList,
                focus:function(e,ui) {
                    return false
                },
                select: function( event, ui ) {
                    //store_info_div("searchCriteriaLabel", ui.item)
                    store_ids(attr_name, ui.item)
                    $("#criteriaPopup #autocompleteField").val('');
                    setUpLOV(attr_name);
                    return false;
                }
            })
            $.ui.autocomplete.prototype._renderMenu = function( ul, items ) {
                var self = this;
                $.each( items, function( index, item ) {
                    if (index < 10)
                    {
                        self._renderItem( ul, item );
                    }
                });
            }
            //.data( "autocomplete" )._renderItem = function( ul, item ) {
            //			return $( "<li></li>" )
            //				.data( "item.autocomplete", item )
            //				.append( "<a>" + item.label + "<br>" + item.desc + "</a>" )
            //				.appendTo( ul );
            //		};
            $( "#criteriaPopup #autocompleteField" ).show();
            $("#autocompleteField").select();
            $("#autocompleteField").autocomplete('search','')

        }
    }
    return false
//  });
}
function setUpLOV(attr_name){
    var selectedList = $("#" + attr_name).val().split(',')
    var anchorId
    var spanId = 'removableListofValues' + attr_name
    var updatedSearchList= [];
    $.each(selectedList, function(index, value) {
        anchorId = "removeThis_" + index + "_" + attr_name
        updatedSearchList.push( value + "<a id='" + anchorId + "' class='removablePopupList'> x </a>")
    })
    $("#searchCriteriaLabel").html("<span id='" + spanId + "'>" + updatedSearchList.toString() + "</span>")
}

function openManufacturerBox(attr_name,elem){
    $(".jslider").hide()
    $("#which_attribute").val($(elem).attr('id'));
    $("#which_form_field").val("manufacturer");
    $("#which_type").val("manufacturer");
    $("#" + $("#which_form_field").val()).val('');
    $(".ui-autocomplete").hide();
    $("#searchCriteriaLabel").text('');
    var position = $("#" + $(elem).attr('id')).position();
    $("#criteriaPopup").css({
        "position": "absolute",
        "top": (position.top -15)+ "px",
        "left":(position.left+210) + "px"
    }).show();
    $( "#criteriaHeading" ).html("Manufacturer")
    //$("#criteriaPopup").dialog({title: "Manufacturer"});
    if ($("#criteriaPopup #autocompleteField").size() > 0){
        var manufacturerList = loadManufacturers();
        $( "#criteriaPopup #autocompleteField" ).autocomplete({
            minLength: 0,
            cacheLength:5,
            max:5,
            minChars: 0,
            source: manufacturerList,
            focus:function(e,ui) {
                return false
            },
            select: function( event, ui ) {
                //store_info_div("searchCriteriaLabel", ui.item)
                store_ids("manufacturer", ui.item)
                $("#criteriaPopup #autocompleteField").val('');
                setUpLOV("manufacturer");
                //$("#autocompleteField").autocomplete('search','')
                //$('#maincontainer').unbind('mouseover').unbind('mouseenter').unbind('mouseleave');
                return false;
            }
        })
        $.ui.autocomplete.prototype._renderMenu = function( ul, items ) {
            var self = this;
            $.each( items, function( index, item ) {
                if (index < 10)
                {
                    self._renderItem( ul, item );
                }
            });
        }
        //.data( "autocomplete" )._renderItem = function( ul, item ) {
        //			return $( "<li></li>" )
        //				.data( "item.autocomplete", item )
        //				.append( "<a>" + item.label + "<br>" + item.desc + "</a>" )
        //				.appendTo( ul );
        //		};
        $( "#criteriaPopup #autocompleteField" ).show();
        $("#autocompleteField").select();
        $("#autocompleteField").autocomplete('search','')

    }

}


$(document).click(function(e) {
    if((!$(e.target).parents().andSelf().is('.box')) && (!$(e.target).parents().andSelf().is('.ui-autocomplete'))){
        if (!$(e.target).parents().andSelf().is('#criteriaPopup')) {
            $("#criteriaPopup").hide();
            $(".ui-autocomplete").hide();
        }
    }
});


  
$(document).ready(function(){
    $('#search_sort_by').live('change',function(){
        if ($(this).val()){
            $("#sort_by").val($(this).val())
            $("#page").val(1)
            searchData("spinner")
        //$.get(SEARCH_URL,$("#searchForm").serialize(),null,"script");
        }
        return false;
    })
  
    $('#searchItemsPaginate div.pagination a').live('click', function(){
        var page = $(this).text()
        var current = $('em.current').text();
        if (page == "← Previous"){
            page = parseInt(current) -1
        }
        else if (page == "Next →"){
            page = parseInt(current) + 1
        }
        $("#page").val(page)
        searchData("spinner")
        //$.get(SEARCH_URL,$("#searchForm").serialize(),null,"script");
        return false;
    })

    $('#clearTag').live('click', function(){
        removeAllTags();
        resetFormData();
        hideClearTag()
        hidePreferenceTag();
        hideGetAdviceTag();
        hideSearchPack()
        searchData("spinner");
    });

    $('#addPreferenceTag').live('click', function(){
        if(confirm("This will remove your old preference for this type, Are you sure?")){
            $.post('/preferences/add_preference',$("#searchForm").serialize(),null,"script");
            return false;
        } else {
            return false;
        }
    });

    $('#getAdviceTag').live('click', function(){
        $.get('/preferences/get_advice',$("#searchForm").serialize(),null,"script");
    })

    $('#criteriaSubmit').click(function() {
        var tagId = $("#which_attribute").val() + "_tag"
        showSearchPack();
        showClearTag();
        showPreferenceTag();
        showGetAdviceTag();
        if ($(".search_category").find("#" + tagId).length > 0){
            $("#" +tagId).remove();
        }
        var fieldId = $("#which_form_field").val()
        if ($("#which_type").val() == "Between"){
            var  sliderVal = $("#form_field_val").val().split(";")
            $("#min_" + fieldId).val(sliderVal[0])
            $("#max_" + fieldId).val(sliderVal[1])
            var minValue = $( "#min_" + fieldId ).val()
            var maxValue = $("#max_" + fieldId).val()
            if ((minValue == "")|| (maxValue == "")){
                alert("Please select a search criteria.");
                return false
            }
            var value = "" + $("#which_type").val() + " "  + minValue + " " + $("#which_unit").val() + " - " + maxValue + " "  + $("#which_unit").val() + ""
            var searchCriteria = "<span class='txt_subcategories'>" + value +"</span>"
        }
        else if (($("#which_type").val() == "Greater than") || ($("#which_type").val() == "Less then"))
        {
            $("#" + fieldId).val($("#form_field_val").val())
            var selectedValue = $("#" + fieldId).val()
            if (selectedValue == ""){
                alert("Please select a search criteria.");
                return false
            }
            var value = "" + $("#which_type").val() + " "  + selectedValue + " " + $("#which_unit").val() +  ""
            var searchCriteria = "<span class='txt_subcategories'>" + value +"</span>"

        }
        else{
            var selectedValue = $("#" + fieldId).val()
            if (selectedValue == ""){
                alert("Please select a search criteria.");
                return false
            }
            var value = " ( " + selectedValue + " " +  ") "
            var searchCriteria = "<span class='txt_subcategories'>" + value +"</span>"
        }
        if (($("#which_type").val() == "List of values") || ($("#which_type").val() == "manufacturer"))
        {

            var selectedList = selectedValue.split(',')
            var formFieldId = $("#which_form_field").val();
            var searchCriteria = "" // + selectedValue + " " +  ")"
            var anchorId
            var spanId = 'removableListofValues' + formFieldId
            searchCriteria = searchCriteria +  "<span id='" + spanId + "'>"
            var anchorId;
            var spanHTML = ""
            $.each(selectedList, function(index, value) {
                anchorId = "removeThis_" + index + "_" + formFieldId
                spanHTML = spanHTML + "<span class='txt_subcategories'>" + value + "<a class='icon_close1 removableList' id='" + anchorId + "' href='#'></a></span>"
            })
            searchCriteria = searchCriteria + spanHTML
            var className = "middlebg"
        }
        else{
            var className = "middlebg attributeTag"
        }
        var list = "<li id='" + tagId + "'" + " class='" + className +"'><span class='title_txt'>" +$("#criteriaHeading").text()+ "<a id= 'deleteTag' class='icon_close'></a></span>" +searchCriteria + "</li>" ;
        $(list).appendTo('.search_category');

        $("#page").val(1)
        searchData("spinner")
        //$.get(SEARCH_URL,$("#searchForm").serialize(),null,"script");
        $("#criteriaPopup").hide();
        $("#" + $("#which_attribute").val()).hide();

    });

    //$('.attributeTag').live('click', function(){
    //    var tagId = $(this).attr('id');
    //   var attributeId = tagId.substring(0, tagId.indexOf("_tag"));
    //   $('#' + attributeId).trigger('click');
    //    return false;
    // })

    $('.removableList').live('click', function(){
        var deleteId = $(this).attr('id').replace("removeThis_",'');
        var indexArray  = deleteId.split("_")
        var removableIndex = indexArray[0]
        var formId = indexArray[1]
        var formVal = $("#" + formId).val()
        var formValArray = formVal.split(",")
        formVal  = ""
        if(formValArray.length == 1){
            var tagId = $(this).closest('li').attr('id');
            var attributeId = tagId.substring(0, tagId.indexOf("_tag"));
            $("#" + attributeId).show();
            $(this).closest('li').remove()
            $("#" + formId).val("")
        }
        else{
            var updatedFormList = [];
            $.each(formValArray, function(index, value) {
                if(index != removableIndex){
                    updatedFormList.push(value)
                }
            })
            var anchorId;
            //var updatedSearchList= [];
            var spanHTML = ""
            $.each(updatedFormList, function(index, value) {
                anchorId = "removeThis_" + index + "_" + formId
                //updatedSearchList.push( value + "<a id='" + anchorId + "' class='removableList'> x </a>")
                spanHTML = spanHTML + "<span class='txt_subcategories'>" + value + "<a class='icon_close1 removableList' id='" + anchorId + "' href='#'></a></span>"
            })

            var listSpanId = "removableListofValues" + formId
            $("span#" + listSpanId).html(spanHTML)
            $("#" + formId).val("" + updatedFormList.toString() + "")

        }
        $("#page").val(1)
        searchData("spinner")
        //$.get(SEARCH_URL,$("#searchForm").serialize(),null,"script");
        return false;
    });


    $('.removablePopupList').live('click', function(){
        var deleteId = $(this).attr('id').replace("removeThis_",'');
        var indexArray  = deleteId.split("_")
        var removableIndex = indexArray[0]
        var formId = indexArray[1]
        var formVal = $("#" + formId).val()
        var formValArray = formVal.split(",")
        formVal  = ""

        var updatedFormList = [];
        $.each(formValArray, function(index, value) {
            if(index != removableIndex){
                updatedFormList.push(value)
            }
        })
        var anchorId;
        var updatedSearchList= [];
        $.each(updatedFormList, function(index, value) {
            anchorId = "removeThis_" + index + "_" + formId
            updatedSearchList.push( value + "<a id='" + anchorId + "' class='removablePopupList'> x </a>")
        })
        $("#searchCriteriaLabel").html("" +updatedSearchList.toString())
        $("#" + formId).val("" + updatedFormList.toString() + "")
        return false;
    });

    $(".boxClick").mouseenter(function(){
        enableDocumentMouseOverEvent()
        $("#criteriaPopup").hide();
    })

    $('.boxClick').live('click', function(){
        enableDocumentMouseOverEvent()
        $("#criteriaPopup").hide();
    });
  
    $(".box").mouseover(function() {
        enableDocumentMouseOverEvent()
        $(this).click();
    })

    $('#autocompleteField').mouseenter(function() {
        //$("#maincontainer").disabled = true;
        }).mouseout(function() {
        $(document).unbind('mouseover').unbind('mouseenter').unbind('mouseleave');
    });

    ///////////////////////COMPARE ITEMS FEATURE //////////////////////////////////////

    $("a.btn_selected_compare").live("click", function(){
        var ids = checkBoxIds.split(",");
        if (ids.length < 2){
            alert("You must select atleast two items to compare.")
            return
        }
        location.href = "/items/compare?ids=" + ids.toString();
    })
    $("input[name='Compare']").live("click",function(){
        store_checkbox_ids(this)        
    });

//////////////////////COMPARE ITEMS FEATURE ENDS ///////////////////////////////

});

function setUpCompareButton(id){
    if (id){
        var searchItem = "input[value='" + id + "']"
        if ($(searchItem).closest("div").find('a.txt_compare').hasClass("btn_selected_compare"))
        {
            $(searchItem).closest("div").find('a.txt_compare').removeClass("btn_selected_compare")
        }
        else
        {
            $(searchItem).closest("div").find('a.txt_compare').addClass("btn_selected_compare")
        }
    }
}

function setCompareCheckBox(){
    var ids = checkBoxIds.split(",")
    $.each( ids, function( index, item ) {
        $("input[value='" + item +"']").attr("checked",true)
        setUpCompareButton(item)
    });
}
function store_checkbox_ids(sender) {
    if (checkBoxIds == "") {
        var ids = [];
    } else {
        var ids = checkBoxIds.split(",");
    }
    if(sender.checked) {
        if (ids.length == 4){
            alert("You can only select 4 items to compare.")
            $("input[value='" + sender.value +"']").attr("checked",false)
            return
        }
        ids.push(sender.value);

    } else {
        var unchecked_value = sender.value;
        ids = $.grep(ids, function(val) {
            return val != unchecked_value;
        })
    }
    checkBoxIds = ids.toString();
    setUpCompareButton(sender.value)
};

function enableDocumentMouseOverEvent(){
    $(document).mouseover(function(e) {
        if((!$(e.target).parents().andSelf().is('.box')) && (!$(e.target).parents().andSelf().is('.ui-autocomplete'))){
            if (!$(e.target).parents().andSelf().is('#criteriaPopup')) {
                $("#criteriaPopup").hide();
                $(".ui-autocomplete").hide();
            }
        }
    });
}
;
(function() {

}).call(this);
//fgnass.github.com/spin.js#v1.2.2
(function(window, document, undefined) {

/**
 * Copyright (c) 2011 Felix Gnass [fgnass at neteye dot de]
 * Licensed under the MIT license
 */

  var prefixes = ['webkit', 'Moz', 'ms', 'O'], /* Vendor prefixes */
      animations = {}, /* Animation rules keyed by their name */
      useCssAnimations;

  /**
   * Utility function to create elements. If no tag name is given,
   * a DIV is created. Optionally properties can be passed.
   */
  function createEl(tag, prop) {
    var el = document.createElement(tag || 'div'),
        n;

    for(n in prop) {
      el[n] = prop[n];
    }
    return el;
  }

  /**
   * Inserts child1 before child2. If child2 is not specified,
   * child1 is appended. If child2 has no parentNode, child2 is
   * appended first.
   */
  function ins(parent, child1, child2) {
    if(child2 && !child2.parentNode) ins(parent, child2);
    parent.insertBefore(child1, child2||null);
    return parent;
  }

  /**
   * Insert a new stylesheet to hold the @keyframe or VML rules.
   */
  var sheet = (function() {
    var el = createEl('style');
    ins(document.getElementsByTagName('head')[0], el);
    return el.sheet || el.styleSheet;
  })();

  /**
   * Creates an opacity keyframe animation rule and returns its name.
   * Since most mobile Webkits have timing issues with animation-delay,
   * we create separate rules for each line/segment.
   */
  function addAnimation(alpha, trail, i, lines) {
    var name = ['opacity', trail, ~~(alpha*100), i, lines].join('-'),
        start = 0.01 + i/lines*100,
        z = Math.max(1-(1-alpha)/trail*(100-start) , alpha),
        prefix = useCssAnimations.substring(0, useCssAnimations.indexOf('Animation')).toLowerCase(),
        pre = prefix && '-'+prefix+'-' || '';

    if (!animations[name]) {
      sheet.insertRule(
        '@' + pre + 'keyframes ' + name + '{' +
        '0%{opacity:'+z+'}' +
        start + '%{opacity:'+ alpha + '}' +
        (start+0.01) + '%{opacity:1}' +
        (start+trail)%100 + '%{opacity:'+ alpha + '}' +
        '100%{opacity:'+ z + '}' +
        '}', 0);
      animations[name] = 1;
    }
    return name;
  }

  /**
   * Tries various vendor prefixes and returns the first supported property.
   **/
  function vendor(el, prop) {
    var s = el.style,
        pp,
        i;

    if(s[prop] !== undefined) return prop;
    prop = prop.charAt(0).toUpperCase() + prop.slice(1);
    for(i=0; i<prefixes.length; i++) {
      pp = prefixes[i]+prop;
      if(s[pp] !== undefined) return pp;
    }
  }

  /**
   * Sets multiple style properties at once.
   */
  function css(el, prop) {
    for (var n in prop) {
      el.style[vendor(el, n)||n] = prop[n];
    }
    return el;
  }

  /**
   * Fills in default values.
   */
  function merge(obj) {
    for (var i=1; i < arguments.length; i++) {
      var def = arguments[i];
      for (var n in def) {
        if (obj[n] === undefined) obj[n] = def[n];
      }
    }
    return obj;
  }

  /**
   * Returns the absolute page-offset of the given element.
   */
  function pos(el) {
    var o = {x:el.offsetLeft, y:el.offsetTop};
    while((el = el.offsetParent)) {
      o.x+=el.offsetLeft;
      o.y+=el.offsetTop;
    }
    return o;
  }

  /** The constructor */
  var Spinner = function Spinner(o) {
    if (!this.spin) return new Spinner(o);
    this.opts = merge(o || {}, Spinner.defaults, defaults);
  },
  defaults = Spinner.defaults = {
    lines: 12, // The number of lines to draw
    length: 7, // The length of each line
    width: 5, // The line thickness
    radius: 10, // The radius of the inner circle
    color: '#000', // #rgb or #rrggbb
    speed: 1, // Rounds per second
    trail: 100, // Afterglow percentage
    opacity: 1/4,
    fps: 20
  },
  proto = Spinner.prototype = {
    spin: function(target) {
      this.stop();
      var self = this,
          el = self.el = css(createEl(), {position: 'relative'}),
          ep, // element position
          tp; // target position

      if (target) {
        tp = pos(ins(target, el, target.firstChild));
        ep = pos(el);
        css(el, {
          left: (target.offsetWidth >> 1) - ep.x+tp.x + 'px',
          top: (target.offsetHeight >> 1) - ep.y+tp.y + 'px'
        });
      }
      el.setAttribute('aria-role', 'progressbar');
      self.lines(el, self.opts);
      if (!useCssAnimations) {
        // No CSS animation support, use setTimeout() instead
        var o = self.opts,
            i = 0,
            fps = o.fps,
            f = fps/o.speed,
            ostep = (1-o.opacity)/(f*o.trail / 100),
            astep = f/o.lines;

        (function anim() {
          i++;
          for (var s=o.lines; s; s--) {
            var alpha = Math.max(1-(i+s*astep)%f * ostep, o.opacity);
            self.opacity(el, o.lines-s, alpha, o);
          }
          self.timeout = self.el && setTimeout(anim, ~~(1000/fps));
        })();
      }
      return self;
    },
    stop: function() {
      var el = this.el;
      if (el) {
        clearTimeout(this.timeout);
        if (el.parentNode) el.parentNode.removeChild(el);
        this.el = undefined;
      }
      return this;
    }
  };
  proto.lines = function(el, o) {
    var i = 0,
        seg;

    function fill(color, shadow) {
      return css(createEl(), {
        position: 'absolute',
        width: (o.length+o.width) + 'px',
        height: o.width + 'px',
        background: color,
        boxShadow: shadow,
        transformOrigin: 'left',
        transform: 'rotate(' + ~~(360/o.lines*i) + 'deg) translate(' + o.radius+'px' +',0)',
        borderRadius: (o.width>>1) + 'px'
      });
    }
    for (; i < o.lines; i++) {
      seg = css(createEl(), {
        position: 'absolute',
        top: 1+~(o.width/2) + 'px',
        transform: 'translate3d(0,0,0)',
        opacity: o.opacity,
        animation: useCssAnimations && addAnimation(o.opacity, o.trail, i, o.lines) + ' ' + 1/o.speed + 's linear infinite'
      });
      if (o.shadow) ins(seg, css(fill('#000', '0 0 4px ' + '#000'), {top: 2+'px'}));
      ins(el, ins(seg, fill(o.color, '0 0 1px rgba(0,0,0,.1)')));
    }
    return el;
  };
  proto.opacity = function(el, i, val) {
    if (i < el.childNodes.length) el.childNodes[i].style.opacity = val;
  };

  /////////////////////////////////////////////////////////////////////////
  // VML rendering for IE
  /////////////////////////////////////////////////////////////////////////

  /**
   * Check and init VML support
   */
  (function() {
    var s = css(createEl('group'), {behavior: 'url(#default#VML)'}),
        i;

    if (!vendor(s, 'transform') && s.adj) {

      // VML support detected. Insert CSS rules ...
      for (i=4; i--;) sheet.addRule(['group', 'roundrect', 'fill', 'stroke'][i], 'behavior:url(#default#VML)');

      proto.lines = function(el, o) {
        var r = o.length+o.width,
            s = 2*r;

        function grp() {
          return css(createEl('group', {coordsize: s +' '+s, coordorigin: -r +' '+-r}), {width: s, height: s});
        }

        var g = grp(),
            margin = ~(o.length+o.radius+o.width)+'px',
            i;

        function seg(i, dx, filter) {
          ins(g,
            ins(css(grp(), {rotation: 360 / o.lines * i + 'deg', left: ~~dx}),
              ins(css(createEl('roundrect', {arcsize: 1}), {
                  width: r,
                  height: o.width,
                  left: o.radius,
                  top: -o.width>>1,
                  filter: filter
                }),
                createEl('fill', {color: o.color, opacity: o.opacity}),
                createEl('stroke', {opacity: 0}) // transparent stroke to fix color bleeding upon opacity change
              )
            )
          );
        }

        if (o.shadow) {
          for (i = 1; i <= o.lines; i++) {
            seg(i, -2, 'progid:DXImageTransform.Microsoft.Blur(pixelradius=2,makeshadow=1,shadowopacity=.3)');
          }
        }
        for (i = 1; i <= o.lines; i++) {
          seg(i);
        }
        return ins(css(el, {
          margin: margin + ' 0 0 ' + margin,
          zoom: 1
        }), g);
      };
      proto.opacity = function(el, i, val, o) {
        var c = el.firstChild;
        o = o.shadow && o.lines || 0;
        if (c && i+o < c.childNodes.length) {
          c = c.childNodes[i+o]; c = c && c.firstChild; c = c && c.firstChild;
          if (c) c.opacity = val;
        }
      };
    }
    else {
      useCssAnimations = vendor(s, 'animation');
    }
  })();

  window.Spinner = Spinner;

})(window, document);
//fgnass.github.com/spin.js#v1.2.2
(function(a,b,c){function n(a){var b={x:a.offsetLeft,y:a.offsetTop};while(a=a.offsetParent)b.x+=a.offsetLeft,b.y+=a.offsetTop;return b}function m(a){for(var b=1;b<arguments.length;b++){var d=arguments[b];for(var e in d)a[e]===c&&(a[e]=d[e])}return a}function l(a,b){for(var c in b)a.style[k(a,c)||c]=b[c];return a}function k(a,b){var e=a.style,f,g;if(e[b]!==c)return b;b=b.charAt(0).toUpperCase()+b.slice(1);for(g=0;g<d.length;g++){f=d[g]+b;if(e[f]!==c)return f}}function j(a,b,c,d){var g=["opacity",b,~~(a*100),c,d].join("-"),h=.01+c/d*100,j=Math.max(1-(1-a)/b*(100-h),a),k=f.substring(0,f.indexOf("Animation")).toLowerCase(),l=k&&"-"+k+"-"||"";e[g]||(i.insertRule("@"+l+"keyframes "+g+"{"+"0%{opacity:"+j+"}"+h+"%{opacity:"+a+"}"+(h+.01)+"%{opacity:1}"+(h+b)%100+"%{opacity:"+a+"}"+"100%{opacity:"+j+"}"+"}",0),e[g]=1);return g}function h(a,b,c){c&&!c.parentNode&&h(a,c),a.insertBefore(b,c||null);return a}function g(a,c){var d=b.createElement(a||"div"),e;for(e in c)d[e]=c[e];return d}var d=["webkit","Moz","ms","O"],e={},f,i=function(){var a=g("style");h(b.getElementsByTagName("head")[0],a);return a.sheet||a.styleSheet}(),o=function r(a){if(!this.spin)return new r(a);this.opts=m(a||{},r.defaults,p)},p=o.defaults={lines:12,length:7,width:5,radius:10,color:"#000",speed:1,trail:100,opacity:.25,fps:20},q=o.prototype={spin:function(a){this.stop();var b=this,c=b.el=l(g(),{position:"relative"}),d,e;a&&(e=n(h(a,c,a.firstChild)),d=n(c),l(c,{left:(a.offsetWidth>>1)-d.x+e.x+"px",top:(a.offsetHeight>>1)-d.y+e.y+"px"})),c.setAttribute("aria-role","progressbar"),b.lines(c,b.opts);if(!f){var i=b.opts,j=0,k=i.fps,m=k/i.speed,o=(1-i.opacity)/(m*i.trail/100),p=m/i.lines;(function q(){j++;for(var a=i.lines;a;a--){var d=Math.max(1-(j+a*p)%m*o,i.opacity);b.opacity(c,i.lines-a,d,i)}b.timeout=b.el&&setTimeout(q,~~(1e3/k))})()}return b},stop:function(){var a=this.el;a&&(clearTimeout(this.timeout),a.parentNode&&a.parentNode.removeChild(a),this.el=c);return this}};q.lines=function(a,b){function e(a,d){return l(g(),{position:"absolute",width:b.length+b.width+"px",height:b.width+"px",background:a,boxShadow:d,transformOrigin:"left",transform:"rotate("+~~(360/b.lines*c)+"deg) translate("+b.radius+"px"+",0)",borderRadius:(b.width>>1)+"px"})}var c=0,d;for(;c<b.lines;c++)d=l(g(),{position:"absolute",top:1+~(b.width/2)+"px",transform:"translate3d(0,0,0)",opacity:b.opacity,animation:f&&j(b.opacity,b.trail,c,b.lines)+" "+1/b.speed+"s linear infinite"}),b.shadow&&h(d,l(e("#000","0 0 4px #000"),{top:"2px"})),h(a,h(d,e(b.color,"0 0 1px rgba(0,0,0,.1)")));return a},q.opacity=function(a,b,c){b<a.childNodes.length&&(a.childNodes[b].style.opacity=c)},function(){var a=l(g("group"),{behavior:"url(#default#VML)"}),b;if(!k(a,"transform")&&a.adj){for(b=4;b--;)i.addRule(["group","roundrect","fill","stroke"][b],"behavior:url(#default#VML)");q.lines=function(a,b){function k(a,d,i){h(f,h(l(e(),{rotation:360/b.lines*a+"deg",left:~~d}),h(l(g("roundrect",{arcsize:1}),{width:c,height:b.width,left:b.radius,top:-b.width>>1,filter:i}),g("fill",{color:b.color,opacity:b.opacity}),g("stroke",{opacity:0}))))}function e(){return l(g("group",{coordsize:d+" "+d,coordorigin:-c+" "+ -c}),{width:d,height:d})}var c=b.length+b.width,d=2*c,f=e(),i=~(b.length+b.radius+b.width)+"px",j;if(b.shadow)for(j=1;j<=b.lines;j++)k(j,-2,"progid:DXImageTransform.Microsoft.Blur(pixelradius=2,makeshadow=1,shadowopacity=.3)");for(j=1;j<=b.lines;j++)k(j);return h(l(a,{margin:i+" 0 0 "+i,zoom:1}),f)},q.opacity=function(a,b,c,d){var e=a.firstChild;d=d.shadow&&d.lines||0,e&&b+d<e.childNodes.length&&(e=e.childNodes[b+d],e=e&&e.firstChild,e=e&&e.firstChild,e&&(e.opacity=c))}}else f=k(a,"animation")}(),a.Spinner=o})(window,document);
$.textAutocomplete = function(fieldId, taggingField, options){
    $(document).unbind('mouseover').unbind('mouseenter').unbind('mouseleave');
    $.ui.autocomplete.prototype._renderMenu = function(ul, items) {
        var self = this;
        $.each( items, function( index, item ) {
            self._renderItem( ul, item, index );
        });
    };

    var
    defaults = {
        background: '#e3e3e3',
        url: '',
        editMode: false,
        addNew: false,
        close: true,
        search_type_array: [],
        addButton: true,
        color: 'black',
        multiple: true,
        rounded: false,
        image: false,
        hidden_field: "",
        addFunctionName: "",
        editFunctionName: "",
        xCrsfToken: "",
        deleteFunctionName: ""
    },
    settings = $.extend({}, defaults, options);
    $("#"+ fieldId).each(function(){
        $(this).bind('keypress', function(e) {
            if(e.keyCode==13){
        }
        });
    });

    $.setMode(fieldId, taggingField, settings.editMode);
    $.ui.autocomplete.prototype._renderMenu = function(ul, items) {
        var self = this;
        $.each(items, function(index, item) {
            self._renderItem(ul, item, index);
        });
    };
    $( "#" + fieldId ).autocomplete({
        minLength: 0,
        format: "js",
        source: function( request, response )
        {
        $.ajax(
        {
            //headers: {
            //'X-CSRF-Token': settings.xCrsfToken
            //},
            url: settings.url,
            data: {
            term: request.term,
            search_type: settings.search_type_array
            },
            type: "GET",
            dataType: "json",
            success: function( data )
            {
            response( $.map( data, function( item )
            {
                return{
                id: item.id,
                value: item.value,
                imgsrc: item.imgsrc,
                type: item.type,
                url: item.url
                }
                }));
            }
            });
        },
        focus: function( event, ui ) {
        return false;
        },
        select: function( event, ui ) {
        $.selectEvent(ui.item, settings.addfunctionName)
        if (settings.hidden_field != "")
        {
        $.addIdToField(settings.hidden_field, ui.item.id)
        }
        $.addTag(fieldId, taggingField, settings, ui.item.value, ui.item.id);
        $("#" + fieldId).val("");
        return false;
        }
        })
    .data("autocomplete")._renderItem = function(ul, item, index) {
        if (settings.image == true)
            return $("<li></li>")
            .data("item.autocomplete", item)

            .append("<a>" + "<div style='margin-left:5px;float:left'><img width='40' height='40' src='" + item.imgsrc + "' /></div>" + "<div style='margin-left:53px;'><span class='atext'>" + item.value + "</span><br/><span class ='atext'>" + item.type + "</span></div></a>")
            .appendTo(ul);
        else
        {
            return $("<li></li>")
            .data("item.autocomplete", item)

            .append("<a>" + item.value + "</a>")
            .appendTo(ul);
        }
    };

    $('#deleteTag').live('click', function(){
        if (settings.hidden_field != ""){
            var deleteId = $(this).closest('li').attr('id').replace("textTaggers",'');
            $.removeIdFromField(settings.hidden_field, deleteId);
        }
        $(this).closest('li').remove();
        if (settings.deleteFunctionName){
            data = new Object()
            data.id = deleteId;
            $.selectEvent(data, settings.deleteFunctionName)
        }
        return false;
    })
}   


;
/* -------------EXAMPLE -------------------------
 * <input type="text" name="textfield" value="" id="recommendation"/> // AUTOCOMPLETE FIELD
 *
 * <ul id="recommendation_list"></ul> // ul where the tags are added
 *
 * $(document).ready(function(){
    $.textTagger("recommendation",
    "recommendation_list",
    {close:true, addButton: false, url: "/search/preference_items", editMode: true, multiple: true, hidden_field: "recommendations_item_id", search_type_array: ["Mobile", "Car"]}
  );
  });

    //SAMPLE RENDER FORMAT
    results = @items.collect{|item|
       {:id => item.id, :value => "#{item.name}", :imgsrc =>image_url, :type => type, :url => url }
    }
    render :json => results
=======================NOTES=======================================

1) First param will be the id of the autocomplete field.
2) Second params will be the id of the ul list where tags will be added.
3) Third params will be the hash of params where different options are added to the  tagger plugin
    a)close : true/false, true - there will close link for the tags, false - no close links for the tags
    b)addButton: Ignore for now.
    c)url: Url from where the data will be fetched.
    d)editMode: true/false, true - there will be an edit button on click of which autocomplete field will be displayed
        and then "Add" and "Done" field will be displayed along with autocomplete field will be displayed. On select of
        any item from the autocomplete list then tags are added with an option to delete the tag. When the user clicks on "Done" button
        then tags will go to read only mode.
        false- autocomplete field will be displayed on load and delete link will be provided depending on close: true/false.
    e) multiple - true/false true - user can add multiple tags, false - user can add only one tag.
    f) hidden_field -  id of the hidden field where selected item ids should be added as array.
    g) search_type_array - Array of class names from where search should happen. If not provided then search will happen from everywhere.
    h)addFunctionName: "addSelect" - Name of the function you want to trigger on autocomplete select
    i)deleteFunctionName: "removeSelect" - Name of the function you want to trigger on remove tag.
 *
 *
 */


$(document).ready(function(){
    $.textTagger = function(fieldId, taggingField, options){
        $(document).unbind('mouseover').unbind('mouseenter').unbind('mouseleave');
        $.ui.autocomplete.prototype._renderMenu = function(ul, items) {
            var self = this;
            //if (settings.addNew){
            //  item = {value: "Create New Tag", id: "0"}
            //  self._renderItem( ul, item, "New" );
            //}
            $.each( items, function( index, item ) {
                self._renderItem( ul, item, index );
            });
        };

        var
        defaults = {
            background: '#e3e3e3',
            url: '',
            editMode: false,
            addNew: false,
            close: true,
            search_type_array: [],
            addButton: true,
            color: 'black',
            has_parent: false,
            multiple: true,
            rounded: false,
            hidden_field: "",
            addFunctionName: "",
            editFunctionName: "",
            deleteFunctionName: ""
        },
        settings = $.extend({}, defaults, options);
       
        $(""+ fieldId).each(function(){
            $(this).bind('keypress', function(e) {
                if(e.keyCode==13){            
            }
            });
        });
        if (settings.addButton){
            var tagButton = "<button id='addTag'> Add </button>"
            $(tagButton).insertAfter(""+ fieldId);
            var doneButton = "<button id='doneButton'> Done </button>"
            $(doneButton).insertAfter("#addTag");
        }
        else
        {
        // $("#" + fieldId).hide();
        }
        $.setMode(fieldId, taggingField, settings.editMode);
        $.ui.autocomplete.prototype._renderMenu = function(ul, items) {
            var self = this;
            $.each(items, function(index, item) {
                self._renderItem(ul, item, index);
            });
        // item = {
        //     value: "Search more items...",
        //     id: "0",
        //     imgsrc: ""
        // }
        // self._renderItem(ul, item, -1);
        };

        if (settings.has_parent == false){
           fieldId = "#" + fieldId;
        }
        $( "" + fieldId ).autocomplete({
            minLength: 0,
            format: "js",
            source: function( request, response )
            {
            $.ajax(
            {
                url: settings.url,
                data: {
                term: request.term,
                search_type: settings.search_type_array
                },
                type: "GET",
                dataType: "json",
                success: function( data )
                {
                response( $.map( data, function( item )
                {
                    return{
                    id: item.id,
                    value: item.value,
                    imgsrc: item.imgsrc,
                    type: item.type,
                    url: item.url
                    }
                    }));
                }
                });
            },
            focus: function( event, ui ) {
            //$( "#project" ).val( ui.item.label );
            return false;
            },
            select: function( event, ui ) {
            $.selectEvent(ui.item, settings.addfunctionName)
            if (settings.hidden_field != "")
            {
            $.addIdToField(settings.hidden_field, ui.item.id, settings.has_parent)
            }
            $.addTag(fieldId, taggingField, settings, ui.item.value, ui.item.id, settings.has_parent);
            $("" + fieldId).val("");
            return false;
            }
            })
            if ($( "" + fieldId ).index() != -1) {
        $( "" + fieldId ).data("autocomplete")._renderItem = function(ul, item, index) {
            // if (index == -1) {
            //     return $("<li></li>")
            //     .data("item.autocomplete", item)
            //     .append("<a class='searchMore'>" + item.value + "" + "</a>")
            //     .appendTo(ul);
            // }
            // else {
            return $("<li></li>")
            .data("item.autocomplete", item)
            .append("<a>" + "<div style='margin-left:5px;float:left'><img width='40' height='40' src='" + item.imgsrc + "' /></div>" + "<div style='margin-left:53px;'><span class='atext'>" + item.value + "</span><br/><span class ='atext'>" + item.type + "</span></div></a>")
            .appendTo(ul);
        //  }
        }
            }

        $('#addTag').live( 'click', function(){
            $.addTag(fieldId, taggingField, settings, $("" + fieldId).val(), '', settings.has_parent);
        })

        $('#textTaggers').live('click', function(){
            })

        $('#deleteTag').live('click', function(){
            if (settings.hidden_field != ""){
                var deleteId = $(this).closest('li').attr('id').replace("textTaggers",'');
                $.removeIdFromField(settings.hidden_field, deleteId, settings.has_parent);
            }
            $(this).closest('li').remove();
            if (settings.deleteFunctionName){
                data = new Object()
                data.id = deleteId;
                $.selectEvent(data, settings.deleteFunctionName)
            }
            return false;
        })

        $('#doneButton').live( 'click', function(){
            settings.addButton = false;
            var hideField = "ul#" +taggingField + " li span a.icon_close"
            $(hideField).hide();
            $.doneEvent(fieldId, taggingField, settings.editMode);
        })

        $('#editTag').click(function() {
            $(this).hide();
            var hideField = "ul#" +taggingField + " li span a.icon_close"
            $(hideField).show();
            settings.addButton = true;
            $.editTag(fieldId, taggingField, settings.addButton);
        });
    }

    jQuery.selectEvent = function(data, functionName){
        var fn = window[functionName];
        if(typeof fn == 'function') {
            fn(data);
        }
    }
    
    jQuery.addIdToField = function(hidden_field, id, has_parent){
        if (has_parent == false){
           hidden_field = "#" + hidden_field
        }
        var formVal = $("" + hidden_field).val();
        //alert(hidden_field + "this" +formVal)
        var formValArray = formVal == "" ? [] : formVal.split(",")
        var add = true
        $.each(formValArray, function(index, value) {
            if (value.toString() == id.toString())  {
                add = false;
            }
        })
        if (add == true){
            formValArray.push(id)
        }
        $("" + hidden_field).val(formValArray.toString())
    }

    jQuery.removeIdFromField = function(hidden_field, deleteId, has_parent){
        if (has_parent == false){
            hidden_field = "#" + hidden_field
        }
        var formVal = $("" + hidden_field).val();
        var formValArray =  formVal == "" ?  [] : formVal.split(",")
        var idList = [];
        $.each(formValArray, function(index, value) {
            if (value.toString() != deleteId.toString())  {
                idList.push(value);
            }
        })
        $("" + hidden_field).val(idList);
    }
    jQuery.doneEvent = function(fieldId, taggingField, editMode){
        if(editMode){
            $("" + fieldId).hide();
            $("#addTag").hide();
            $("#doneButton").hide();
            $("#editTag").show();
        }
    }

    jQuery.setMode = function(fieldId, taggingField, editMode){
        if(editMode){
            var tagButton = "<button id='editTag'>Edit</button>"
            $(tagButton).insertAfter("#"+ taggingField);
            $("" + fieldId).hide();
            var hideField = "ul#" +taggingField + " li span a.icon_close";
            $(hideField).show();
        }
        else
        {
            var hideField = "ul#" +taggingField + " li span a.icon_close";
            $(hideField).hide();
        }
    }

    jQuery.editTag = function(fieldId, taggingField, addButton) {
        if(addButton)
        {
            $("" + fieldId).val("")
            $("" + fieldId).show();
            if (!$('#addTag').length) {
                var tagButton = "<button id=" + '"' +"addTag" + '"' + "> Add </button>"
                $(tagButton).insertAfter(""+ fieldId);
            }
            else{
                $("#addTag").show();
            }
            if (!$('#doneButton').length) {
                var doneButton = "<button id='doneButton'> Done </button>"
                $(doneButton).insertAfter("#addTag");
            }
            else{
                $("#doneButton").show();
            }
        }
    }

    jQuery.addTag = function(fieldId, taggingField, settings, value, id, has_parent) {
        var text = value;
        var add = true;
        if (has_parent == false){
            taggingField = "#" + taggingField
        }
        $("" + taggingField).find("li").each(function(index) {
            if ($(this).text().toString() == text.toString())  {
                add = false;
            }
        });
        if ((text != "") && add == true)
        {
            if (settings.multiple == false){
                $(""+ taggingField).find("li").remove();
            }
            var listTagId = 'textTaggers' + id
            var list = "<li id='" + listTagId + "'" + " class='taggingmain'><span><a class='txt_tagging'>" + value + "</a><a id= 'deleteTag' class='icon_close_tagging' href='#'></a></span></li>" ;
             $('' + taggingField).addClass("tagging");
             
            $(list).appendTo('' + taggingField);
            $("" + fieldId).val("")
            $('' + fieldId).autocomplete("enable");
            if (settings.editMode || settings.close){
                if (settings.has_parent == false){
                var hideField = "ul" +taggingField + " li span a.icon_close"
                }
                else{
                    var hideField = "" +taggingField + " li span a.icon_close"
                }
                $(hideField).show();
            }
            else{
                if (settings.has_parent == false){
                var hideField = "ul" +taggingField + " li span a.icon_close"
                }
                else{
                    var hideField = "" +taggingField + " li span a.icon_close"
                }
                var hideField = "ul#" +taggingField + " li span a.icon_close"
                $(hideField).hide();
            }
        }
        $(""+ fieldId).val("");
    }

});
(function() {

}).call(this);
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
window.tinyMCEPreInit = window.tinyMCEPreInit || {
  base:   '/assets/tinymce',
  query:  '3.4.8',
  suffix: ''
};
(function(d){var a=/^\s*|\s*$/g,e,c="B".replace(/A(.)|B/,"$1")==="$1";var b={majorVersion:"3",minorVersion:"4.8",releaseDate:"2012-02-02",_init:function(){var s=this,q=document,o=navigator,g=o.userAgent,m,f,l,k,j,r;s.isOpera=d.opera&&opera.buildNumber;s.isWebKit=/WebKit/.test(g);s.isIE=!s.isWebKit&&!s.isOpera&&(/MSIE/gi).test(g)&&(/Explorer/gi).test(o.appName);s.isIE6=s.isIE&&/MSIE [56]/.test(g);s.isIE7=s.isIE&&/MSIE [7]/.test(g);s.isIE8=s.isIE&&/MSIE [8]/.test(g);s.isIE9=s.isIE&&/MSIE [9]/.test(g);s.isGecko=!s.isWebKit&&/Gecko/.test(g);s.isMac=g.indexOf("Mac")!=-1;s.isAir=/adobeair/i.test(g);s.isIDevice=/(iPad|iPhone)/.test(g);s.isIOS5=s.isIDevice&&g.match(/AppleWebKit\/(\d*)/)[1]>=534;if(d.tinyMCEPreInit){s.suffix=tinyMCEPreInit.suffix;s.baseURL=tinyMCEPreInit.base;s.query=tinyMCEPreInit.query;return}s.suffix="";f=q.getElementsByTagName("base");for(m=0;m<f.length;m++){if(r=f[m].href){if(/^https?:\/\/[^\/]+$/.test(r)){r+="/"}k=r?r.match(/.*\//)[0]:""}}function h(i){if(i.src&&/tiny_mce(|_gzip|_jquery|_prototype|_full)(_dev|_src)?.js/.test(i.src)){if(/_(src|dev)\.js/g.test(i.src)){s.suffix="_src"}if((j=i.src.indexOf("?"))!=-1){s.query=i.src.substring(j+1)}s.baseURL=i.src.substring(0,i.src.lastIndexOf("/"));if(k&&s.baseURL.indexOf("://")==-1&&s.baseURL.indexOf("/")!==0){s.baseURL=k+s.baseURL}return s.baseURL}return null}f=q.getElementsByTagName("script");for(m=0;m<f.length;m++){if(h(f[m])){return}}l=q.getElementsByTagName("head")[0];if(l){f=l.getElementsByTagName("script");for(m=0;m<f.length;m++){if(h(f[m])){return}}}return},is:function(g,f){if(!f){return g!==e}if(f=="array"&&(g.hasOwnProperty&&g instanceof Array)){return true}return typeof(g)==f},makeMap:function(f,j,h){var g;f=f||[];j=j||",";if(typeof(f)=="string"){f=f.split(j)}h=h||{};g=f.length;while(g--){h[f[g]]={}}return h},each:function(i,f,h){var j,g;if(!i){return 0}h=h||i;if(i.length!==e){for(j=0,g=i.length;j<g;j++){if(f.call(h,i[j],j,i)===false){return 0}}}else{for(j in i){if(i.hasOwnProperty(j)){if(f.call(h,i[j],j,i)===false){return 0}}}}return 1},map:function(g,h){var i=[];b.each(g,function(f){i.push(h(f))});return i},grep:function(g,h){var i=[];b.each(g,function(f){if(!h||h(f)){i.push(f)}});return i},inArray:function(g,h){var j,f;if(g){for(j=0,f=g.length;j<f;j++){if(g[j]===h){return j}}}return -1},extend:function(k,j){var h,g,f=arguments;for(h=1,g=f.length;h<g;h++){j=f[h];b.each(j,function(i,l){if(i!==e){k[l]=i}})}return k},trim:function(f){return(f?""+f:"").replace(a,"")},create:function(o,f,j){var n=this,g,i,k,l,h,m=0;o=/^((static) )?([\w.]+)(:([\w.]+))?/.exec(o);k=o[3].match(/(^|\.)(\w+)$/i)[2];i=n.createNS(o[3].replace(/\.\w+$/,""),j);if(i[k]){return}if(o[2]=="static"){i[k]=f;if(this.onCreate){this.onCreate(o[2],o[3],i[k])}return}if(!f[k]){f[k]=function(){};m=1}i[k]=f[k];n.extend(i[k].prototype,f);if(o[5]){g=n.resolve(o[5]).prototype;l=o[5].match(/\.(\w+)$/i)[1];h=i[k];if(m){i[k]=function(){return g[l].apply(this,arguments)}}else{i[k]=function(){this.parent=g[l];return h.apply(this,arguments)}}i[k].prototype[k]=i[k];n.each(g,function(p,q){i[k].prototype[q]=g[q]});n.each(f,function(p,q){if(g[q]){i[k].prototype[q]=function(){this.parent=g[q];return p.apply(this,arguments)}}else{if(q!=k){i[k].prototype[q]=p}}})}n.each(f["static"],function(p,q){i[k][q]=p});if(this.onCreate){this.onCreate(o[2],o[3],i[k].prototype)}},walk:function(i,h,j,g){g=g||this;if(i){if(j){i=i[j]}b.each(i,function(k,f){if(h.call(g,k,f,j)===false){return false}b.walk(k,h,j,g)})}},createNS:function(j,h){var g,f;h=h||d;j=j.split(".");for(g=0;g<j.length;g++){f=j[g];if(!h[f]){h[f]={}}h=h[f]}return h},resolve:function(j,h){var g,f;h=h||d;j=j.split(".");for(g=0,f=j.length;g<f;g++){h=h[j[g]];if(!h){break}}return h},addUnload:function(j,i){var h=this;j={func:j,scope:i||this};if(!h.unloads){function g(){var f=h.unloads,l,m;if(f){for(m in f){l=f[m];if(l&&l.func){l.func.call(l.scope,1)}}if(d.detachEvent){d.detachEvent("onbeforeunload",k);d.detachEvent("onunload",g)}else{if(d.removeEventListener){d.removeEventListener("unload",g,false)}}h.unloads=l=f=w=g=0;if(d.CollectGarbage){CollectGarbage()}}}function k(){var l=document;if(l.readyState=="interactive"){function f(){l.detachEvent("onstop",f);if(g){g()}l=0}if(l){l.attachEvent("onstop",f)}d.setTimeout(function(){if(l){l.detachEvent("onstop",f)}},0)}}if(d.attachEvent){d.attachEvent("onunload",g);d.attachEvent("onbeforeunload",k)}else{if(d.addEventListener){d.addEventListener("unload",g,false)}}h.unloads=[j]}else{h.unloads.push(j)}return j},removeUnload:function(i){var g=this.unloads,h=null;b.each(g,function(j,f){if(j&&j.func==i){g.splice(f,1);h=i;return false}});return h},explode:function(f,g){return f?b.map(f.split(g||","),b.trim):f},_addVer:function(g){var f;if(!this.query){return g}f=(g.indexOf("?")==-1?"?":"&")+this.query;if(g.indexOf("#")==-1){return g+f}return g.replace("#",f+"#")},_replace:function(h,f,g){if(c){return g.replace(h,function(){var l=f,j=arguments,k;for(k=0;k<j.length-2;k++){if(j[k]===e){l=l.replace(new RegExp("\\$"+k,"g"),"")}else{l=l.replace(new RegExp("\\$"+k,"g"),j[k])}}return l})}return g.replace(h,f)}};b._init();d.tinymce=d.tinyMCE=b})(window);tinymce.create("tinymce.util.Dispatcher",{scope:null,listeners:null,Dispatcher:function(a){this.scope=a||this;this.listeners=[]},add:function(a,b){this.listeners.push({cb:a,scope:b||this.scope});return a},addToTop:function(a,b){this.listeners.unshift({cb:a,scope:b||this.scope});return a},remove:function(a){var b=this.listeners,c=null;tinymce.each(b,function(e,d){if(a==e.cb){c=a;b.splice(d,1);return false}});return c},dispatch:function(){var f,d=arguments,e,b=this.listeners,g;for(e=0;e<b.length;e++){g=b[e];f=g.cb.apply(g.scope,d.length>0?d:[g.scope]);if(f===false){break}}return f}});(function(){var a=tinymce.each;tinymce.create("tinymce.util.URI",{URI:function(e,g){var f=this,i,d,c,h;e=tinymce.trim(e);g=f.settings=g||{};if(/^([\w\-]+):([^\/]{2})/i.test(e)||/^\s*#/.test(e)){f.source=e;return}if(e.indexOf("/")===0&&e.indexOf("//")!==0){e=(g.base_uri?g.base_uri.protocol||"http":"http")+"://mce_host"+e}if(!/^[\w-]*:?\/\//.test(e)){h=g.base_uri?g.base_uri.path:new tinymce.util.URI(location.href).directory;e=((g.base_uri&&g.base_uri.protocol)||"http")+"://mce_host"+f.toAbsPath(h,e)}e=e.replace(/@@/g,"(mce_at)");e=/^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@\/]*):?([^:@\/]*))?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/.exec(e);a(["source","protocol","authority","userInfo","user","password","host","port","relative","path","directory","file","query","anchor"],function(b,j){var k=e[j];if(k){k=k.replace(/\(mce_at\)/g,"@@")}f[b]=k});if(c=g.base_uri){if(!f.protocol){f.protocol=c.protocol}if(!f.userInfo){f.userInfo=c.userInfo}if(!f.port&&f.host=="mce_host"){f.port=c.port}if(!f.host||f.host=="mce_host"){f.host=c.host}f.source=""}},setPath:function(c){var b=this;c=/^(.*?)\/?(\w+)?$/.exec(c);b.path=c[0];b.directory=c[1];b.file=c[2];b.source="";b.getURI()},toRelative:function(b){var c=this,d;if(b==="./"){return b}b=new tinymce.util.URI(b,{base_uri:c});if((b.host!="mce_host"&&c.host!=b.host&&b.host)||c.port!=b.port||c.protocol!=b.protocol){return b.getURI()}d=c.toRelPath(c.path,b.path);if(b.query){d+="?"+b.query}if(b.anchor){d+="#"+b.anchor}return d},toAbsolute:function(b,c){var b=new tinymce.util.URI(b,{base_uri:this});return b.getURI(this.host==b.host&&this.protocol==b.protocol?c:0)},toRelPath:function(g,h){var c,f=0,d="",e,b;g=g.substring(0,g.lastIndexOf("/"));g=g.split("/");c=h.split("/");if(g.length>=c.length){for(e=0,b=g.length;e<b;e++){if(e>=c.length||g[e]!=c[e]){f=e+1;break}}}if(g.length<c.length){for(e=0,b=c.length;e<b;e++){if(e>=g.length||g[e]!=c[e]){f=e+1;break}}}if(f==1){return h}for(e=0,b=g.length-(f-1);e<b;e++){d+="../"}for(e=f-1,b=c.length;e<b;e++){if(e!=f-1){d+="/"+c[e]}else{d+=c[e]}}return d},toAbsPath:function(e,f){var c,b=0,h=[],d,g;d=/\/$/.test(f)?"/":"";e=e.split("/");f=f.split("/");a(e,function(i){if(i){h.push(i)}});e=h;for(c=f.length-1,h=[];c>=0;c--){if(f[c].length==0||f[c]=="."){continue}if(f[c]==".."){b++;continue}if(b>0){b--;continue}h.push(f[c])}c=e.length-b;if(c<=0){g=h.reverse().join("/")}else{g=e.slice(0,c).join("/")+"/"+h.reverse().join("/")}if(g.indexOf("/")!==0){g="/"+g}if(d&&g.lastIndexOf("/")!==g.length-1){g+=d}return g},getURI:function(d){var c,b=this;if(!b.source||d){c="";if(!d){if(b.protocol){c+=b.protocol+"://"}if(b.userInfo){c+=b.userInfo+"@"}if(b.host){c+=b.host}if(b.port){c+=":"+b.port}}if(b.path){c+=b.path}if(b.query){c+="?"+b.query}if(b.anchor){c+="#"+b.anchor}b.source=c}return b.source}})})();(function(){var a=tinymce.each;tinymce.create("static tinymce.util.Cookie",{getHash:function(d){var b=this.get(d),c;if(b){a(b.split("&"),function(e){e=e.split("=");c=c||{};c[unescape(e[0])]=unescape(e[1])})}return c},setHash:function(j,b,g,f,i,c){var h="";a(b,function(e,d){h+=(!h?"":"&")+escape(d)+"="+escape(e)});this.set(j,h,g,f,i,c)},get:function(i){var h=document.cookie,g,f=i+"=",d;if(!h){return}d=h.indexOf("; "+f);if(d==-1){d=h.indexOf(f);if(d!=0){return null}}else{d+=2}g=h.indexOf(";",d);if(g==-1){g=h.length}return unescape(h.substring(d+f.length,g))},set:function(i,b,g,f,h,c){document.cookie=i+"="+escape(b)+((g)?"; expires="+g.toGMTString():"")+((f)?"; path="+escape(f):"")+((h)?"; domain="+h:"")+((c)?"; secure":"")},remove:function(e,b){var c=new Date();c.setTime(c.getTime()-1000);this.set(e,"",c,b,c)}})})();(function(){function serialize(o,quote){var i,v,t;quote=quote||'"';if(o==null){return"null"}t=typeof o;if(t=="string"){v="\bb\tt\nn\ff\rr\"\"''\\\\";return quote+o.replace(/([\u0080-\uFFFF\x00-\x1f\"\'\\])/g,function(a,b){if(quote==='"'&&a==="'"){return a}i=v.indexOf(b);if(i+1){return"\\"+v.charAt(i+1)}a=b.charCodeAt().toString(16);return"\\u"+"0000".substring(a.length)+a})+quote}if(t=="object"){if(o.hasOwnProperty&&o instanceof Array){for(i=0,v="[";i<o.length;i++){v+=(i>0?",":"")+serialize(o[i],quote)}return v+"]"}v="{";for(i in o){if(o.hasOwnProperty(i)){v+=typeof o[i]!="function"?(v.length>1?","+quote:quote)+i+quote+":"+serialize(o[i],quote):""}}return v+"}"}return""+o}tinymce.util.JSON={serialize:serialize,parse:function(s){try{return eval("("+s+")")}catch(ex){}}}})();tinymce.create("static tinymce.util.XHR",{send:function(g){var a,e,b=window,h=0;g.scope=g.scope||this;g.success_scope=g.success_scope||g.scope;g.error_scope=g.error_scope||g.scope;g.async=g.async===false?false:true;g.data=g.data||"";function d(i){a=0;try{a=new ActiveXObject(i)}catch(c){}return a}a=b.XMLHttpRequest?new XMLHttpRequest():d("Microsoft.XMLHTTP")||d("Msxml2.XMLHTTP");if(a){if(a.overrideMimeType){a.overrideMimeType(g.content_type)}a.open(g.type||(g.data?"POST":"GET"),g.url,g.async);if(g.content_type){a.setRequestHeader("Content-Type",g.content_type)}a.setRequestHeader("X-Requested-With","XMLHttpRequest");a.send(g.data);function f(){if(!g.async||a.readyState==4||h++>10000){if(g.success&&h<10000&&a.status==200){g.success.call(g.success_scope,""+a.responseText,a,g)}else{if(g.error){g.error.call(g.error_scope,h>10000?"TIMED_OUT":"GENERAL",a,g)}}a=null}else{b.setTimeout(f,10)}}if(!g.async){return f()}e=b.setTimeout(f,10)}}});(function(){var c=tinymce.extend,b=tinymce.util.JSON,a=tinymce.util.XHR;tinymce.create("tinymce.util.JSONRequest",{JSONRequest:function(d){this.settings=c({},d);this.count=0},send:function(f){var e=f.error,d=f.success;f=c(this.settings,f);f.success=function(h,g){h=b.parse(h);if(typeof(h)=="undefined"){h={error:"JSON Parse error."}}if(h.error){e.call(f.error_scope||f.scope,h.error,g)}else{d.call(f.success_scope||f.scope,h.result)}};f.error=function(h,g){if(e){e.call(f.error_scope||f.scope,h,g)}};f.data=b.serialize({id:f.id||"c"+(this.count++),method:f.method,params:f.params});f.content_type="application/json";a.send(f)},"static":{sendRPC:function(d){return new tinymce.util.JSONRequest().send(d)}}})}());(function(a){a.VK={DELETE:46,BACKSPACE:8,ENTER:13,TAB:9,SPACEBAR:32,UP:38,DOWN:40,modifierPressed:function(b){return b.shiftKey||b.ctrlKey||b.altKey}}})(tinymce);(function(l){var j=l.VK,k=j.BACKSPACE,h=j.DELETE;function c(n){var p=n.dom,o=n.selection;n.onKeyDown.add(function(r,v){var q,x,t,u,s;s=v.keyCode==h;if((s||v.keyCode==k)&&!j.modifierPressed(v)){v.preventDefault();q=o.getRng();x=p.getParent(q.startContainer,p.isBlock);if(s){x=p.getNext(x,p.isBlock)}if(x){t=x.firstChild;while(t&&t.nodeType==3&&t.nodeValue.length==0){t=t.nextSibling}if(t&&t.nodeName==="SPAN"){u=t.cloneNode(false)}}r.getDoc().execCommand(s?"ForwardDelete":"Delete",false,null);x=p.getParent(q.startContainer,p.isBlock);l.each(p.select("span.Apple-style-span,font.Apple-style-span",x),function(y){var z=o.getBookmark();if(u){p.replace(u.cloneNode(false),y,true)}else{p.remove(y,true)}o.moveToBookmark(z)})}})}function d(n){n.onKeyUp.add(function(o,q){var p=q.keyCode;if(p==h||p==k){if(o.dom.isEmpty(o.getBody())){o.setContent("",{format:"raw"});o.nodeChanged();return}}})}function b(n){n.dom.bind(n.getDoc(),"focusin",function(){n.selection.setRng(n.selection.getRng())})}function e(n){n.onKeyDown.add(function(o,r){if(r.keyCode===k){if(o.selection.isCollapsed()&&o.selection.getRng(true).startOffset===0){var q=o.selection.getNode();var p=q.previousSibling;if(p&&p.nodeName&&p.nodeName.toLowerCase()==="hr"){o.dom.remove(p);l.dom.Event.cancel(r)}}}})}function g(n){if(!Range.prototype.getClientRects){n.onMouseDown.add(function(p,q){if(q.target.nodeName==="HTML"){var o=p.getBody();o.blur();setTimeout(function(){o.focus()},0)}})}}function f(n){n.onClick.add(function(o,p){p=p.target;if(/^(IMG|HR)$/.test(p.nodeName)){o.selection.getSel().setBaseAndExtent(p,0,p,1)}if(p.nodeName=="A"&&o.dom.hasClass(p,"mceItemAnchor")){o.selection.select(p)}o.nodeChanged()})}function i(n){n.onKeyDown.add(function(o,p){function q(r){var s=r.selection.getNode();var t="h1,h2,h3,h4,h5,h6";return r.dom.is(s,t)||r.dom.getParent(s,t)!==null}if(p.keyCode===j.ENTER&&!j.modifierPressed(p)&&q(o)){setTimeout(function(){var r=o.selection.getNode();if(o.dom.is(r,"p")){o.dom.setAttrib(r,"style",null);o.execCommand("mceCleanup")}},0)}})}function m(n){var p,o;n.dom.bind(n.getDoc(),"selectionchange",function(){if(o){clearTimeout(o);o=0}o=window.setTimeout(function(){var q=n.selection.getRng();if(!p||!l.dom.RangeUtils.compareRanges(q,p)){n.nodeChanged();p=q}},50)})}function a(n){document.body.setAttribute("role","application")}l.create("tinymce.util.Quirks",{Quirks:function(n){if(l.isWebKit){c(n);d(n);b(n);f(n);if(l.isIDevice){m(n)}}if(l.isIE){e(n);d(n);a(n);i(n)}if(l.isGecko){e(n);g(n)}}})})(tinymce);(function(j){var a,g,d,k=/[&<>\"\u007E-\uD7FF\uE000-\uFFEF]|[\uD800-\uDBFF][\uDC00-\uDFFF]/g,b=/[<>&\u007E-\uD7FF\uE000-\uFFEF]|[\uD800-\uDBFF][\uDC00-\uDFFF]/g,f=/[<>&\"\']/g,c=/&(#x|#)?([\w]+);/g,i={128:"\u20AC",130:"\u201A",131:"\u0192",132:"\u201E",133:"\u2026",134:"\u2020",135:"\u2021",136:"\u02C6",137:"\u2030",138:"\u0160",139:"\u2039",140:"\u0152",142:"\u017D",145:"\u2018",146:"\u2019",147:"\u201C",148:"\u201D",149:"\u2022",150:"\u2013",151:"\u2014",152:"\u02DC",153:"\u2122",154:"\u0161",155:"\u203A",156:"\u0153",158:"\u017E",159:"\u0178"};g={'"':"&quot;","'":"&#39;","<":"&lt;",">":"&gt;","&":"&amp;"};d={"&lt;":"<","&gt;":">","&amp;":"&","&quot;":'"',"&apos;":"'"};function h(l){var m;m=document.createElement("div");m.innerHTML=l;return m.textContent||m.innerText||l}function e(m,p){var n,o,l,q={};if(m){m=m.split(",");p=p||10;for(n=0;n<m.length;n+=2){o=String.fromCharCode(parseInt(m[n],p));if(!g[o]){l="&"+m[n+1]+";";q[o]=l;q[l]=o}}return q}}a=e("50,nbsp,51,iexcl,52,cent,53,pound,54,curren,55,yen,56,brvbar,57,sect,58,uml,59,copy,5a,ordf,5b,laquo,5c,not,5d,shy,5e,reg,5f,macr,5g,deg,5h,plusmn,5i,sup2,5j,sup3,5k,acute,5l,micro,5m,para,5n,middot,5o,cedil,5p,sup1,5q,ordm,5r,raquo,5s,frac14,5t,frac12,5u,frac34,5v,iquest,60,Agrave,61,Aacute,62,Acirc,63,Atilde,64,Auml,65,Aring,66,AElig,67,Ccedil,68,Egrave,69,Eacute,6a,Ecirc,6b,Euml,6c,Igrave,6d,Iacute,6e,Icirc,6f,Iuml,6g,ETH,6h,Ntilde,6i,Ograve,6j,Oacute,6k,Ocirc,6l,Otilde,6m,Ouml,6n,times,6o,Oslash,6p,Ugrave,6q,Uacute,6r,Ucirc,6s,Uuml,6t,Yacute,6u,THORN,6v,szlig,70,agrave,71,aacute,72,acirc,73,atilde,74,auml,75,aring,76,aelig,77,ccedil,78,egrave,79,eacute,7a,ecirc,7b,euml,7c,igrave,7d,iacute,7e,icirc,7f,iuml,7g,eth,7h,ntilde,7i,ograve,7j,oacute,7k,ocirc,7l,otilde,7m,ouml,7n,divide,7o,oslash,7p,ugrave,7q,uacute,7r,ucirc,7s,uuml,7t,yacute,7u,thorn,7v,yuml,ci,fnof,sh,Alpha,si,Beta,sj,Gamma,sk,Delta,sl,Epsilon,sm,Zeta,sn,Eta,so,Theta,sp,Iota,sq,Kappa,sr,Lambda,ss,Mu,st,Nu,su,Xi,sv,Omicron,t0,Pi,t1,Rho,t3,Sigma,t4,Tau,t5,Upsilon,t6,Phi,t7,Chi,t8,Psi,t9,Omega,th,alpha,ti,beta,tj,gamma,tk,delta,tl,epsilon,tm,zeta,tn,eta,to,theta,tp,iota,tq,kappa,tr,lambda,ts,mu,tt,nu,tu,xi,tv,omicron,u0,pi,u1,rho,u2,sigmaf,u3,sigma,u4,tau,u5,upsilon,u6,phi,u7,chi,u8,psi,u9,omega,uh,thetasym,ui,upsih,um,piv,812,bull,816,hellip,81i,prime,81j,Prime,81u,oline,824,frasl,88o,weierp,88h,image,88s,real,892,trade,89l,alefsym,8cg,larr,8ch,uarr,8ci,rarr,8cj,darr,8ck,harr,8dl,crarr,8eg,lArr,8eh,uArr,8ei,rArr,8ej,dArr,8ek,hArr,8g0,forall,8g2,part,8g3,exist,8g5,empty,8g7,nabla,8g8,isin,8g9,notin,8gb,ni,8gf,prod,8gh,sum,8gi,minus,8gn,lowast,8gq,radic,8gt,prop,8gu,infin,8h0,ang,8h7,and,8h8,or,8h9,cap,8ha,cup,8hb,int,8hk,there4,8hs,sim,8i5,cong,8i8,asymp,8j0,ne,8j1,equiv,8j4,le,8j5,ge,8k2,sub,8k3,sup,8k4,nsub,8k6,sube,8k7,supe,8kl,oplus,8kn,otimes,8l5,perp,8m5,sdot,8o8,lceil,8o9,rceil,8oa,lfloor,8ob,rfloor,8p9,lang,8pa,rang,9ea,loz,9j0,spades,9j3,clubs,9j5,hearts,9j6,diams,ai,OElig,aj,oelig,b0,Scaron,b1,scaron,bo,Yuml,m6,circ,ms,tilde,802,ensp,803,emsp,809,thinsp,80c,zwnj,80d,zwj,80e,lrm,80f,rlm,80j,ndash,80k,mdash,80o,lsquo,80p,rsquo,80q,sbquo,80s,ldquo,80t,rdquo,80u,bdquo,810,dagger,811,Dagger,81g,permil,81p,lsaquo,81q,rsaquo,85c,euro",32);j.html=j.html||{};j.html.Entities={encodeRaw:function(m,l){return m.replace(l?k:b,function(n){return g[n]||n})},encodeAllRaw:function(l){return(""+l).replace(f,function(m){return g[m]||m})},encodeNumeric:function(m,l){return m.replace(l?k:b,function(n){if(n.length>1){return"&#"+(((n.charCodeAt(0)-55296)*1024)+(n.charCodeAt(1)-56320)+65536)+";"}return g[n]||"&#"+n.charCodeAt(0)+";"})},encodeNamed:function(n,l,m){m=m||a;return n.replace(l?k:b,function(o){return g[o]||m[o]||o})},getEncodeFunc:function(l,o){var p=j.html.Entities;o=e(o)||a;function m(r,q){return r.replace(q?k:b,function(s){return g[s]||o[s]||"&#"+s.charCodeAt(0)+";"||s})}function n(r,q){return p.encodeNamed(r,q,o)}l=j.makeMap(l.replace(/\+/g,","));if(l.named&&l.numeric){return m}if(l.named){if(o){return n}return p.encodeNamed}if(l.numeric){return p.encodeNumeric}return p.encodeRaw},decode:function(l){return l.replace(c,function(n,m,o){if(m){o=parseInt(o,m.length===2?16:10);if(o>65535){o-=65536;return String.fromCharCode(55296+(o>>10),56320+(o&1023))}else{return i[o]||String.fromCharCode(o)}}return d[n]||a[n]||h(n)})}}})(tinymce);tinymce.html.Styles=function(d,f){var k=/rgb\s*\(\s*([0-9]+)\s*,\s*([0-9]+)\s*,\s*([0-9]+)\s*\)/gi,h=/(?:url(?:(?:\(\s*\"([^\"]+)\"\s*\))|(?:\(\s*\'([^\']+)\'\s*\))|(?:\(\s*([^)\s]+)\s*\))))|(?:\'([^\']+)\')|(?:\"([^\"]+)\")/gi,b=/\s*([^:]+):\s*([^;]+);?/g,l=/\s+$/,m=/rgb/,e,g,a={},j;d=d||{};j="\\\" \\' \\; \\: ; : \uFEFF".split(" ");for(g=0;g<j.length;g++){a[j[g]]="\uFEFF"+g;a["\uFEFF"+g]=j[g]}function c(n,q,p,i){function o(r){r=parseInt(r).toString(16);return r.length>1?r:"0"+r}return"#"+o(q)+o(p)+o(i)}return{toHex:function(i){return i.replace(k,c)},parse:function(r){var y={},p,n,v,q,u=d.url_converter,x=d.url_converter_scope||this;function o(C,F){var E,B,A,D;E=y[C+"-top"+F];if(!E){return}B=y[C+"-right"+F];if(E!=B){return}A=y[C+"-bottom"+F];if(B!=A){return}D=y[C+"-left"+F];if(A!=D){return}y[C+F]=D;delete y[C+"-top"+F];delete y[C+"-right"+F];delete y[C+"-bottom"+F];delete y[C+"-left"+F]}function t(B){var C=y[B],A;if(!C||C.indexOf(" ")<0){return}C=C.split(" ");A=C.length;while(A--){if(C[A]!==C[0]){return false}}y[B]=C[0];return true}function z(C,B,A,D){if(!t(B)){return}if(!t(A)){return}if(!t(D)){return}y[C]=y[B]+" "+y[A]+" "+y[D];delete y[B];delete y[A];delete y[D]}function s(A){q=true;return a[A]}function i(B,A){if(q){B=B.replace(/\uFEFF[0-9]/g,function(C){return a[C]})}if(!A){B=B.replace(/\\([\'\";:])/g,"$1")}return B}if(r){r=r.replace(/\\[\"\';:\uFEFF]/g,s).replace(/\"[^\"]+\"|\'[^\']+\'/g,function(A){return A.replace(/[;:]/g,s)});while(p=b.exec(r)){n=p[1].replace(l,"").toLowerCase();v=p[2].replace(l,"");if(n&&v.length>0){if(n==="font-weight"&&v==="700"){v="bold"}else{if(n==="color"||n==="background-color"){v=v.toLowerCase()}}v=v.replace(k,c);v=v.replace(h,function(B,A,E,D,F,C){F=F||C;if(F){F=i(F);return"'"+F.replace(/\'/g,"\\'")+"'"}A=i(A||E||D);if(u){A=u.call(x,A,"style")}return"url('"+A.replace(/\'/g,"\\'")+"')"});y[n]=q?i(v,true):v}b.lastIndex=p.index+p[0].length}o("border","");o("border","-width");o("border","-color");o("border","-style");o("padding","");o("margin","");z("border","border-width","border-style","border-color");if(y.border==="medium none"){delete y.border}}return y},serialize:function(p,r){var o="",n,q;function i(t){var x,u,s,v;x=f.styles[t];if(x){for(u=0,s=x.length;u<s;u++){t=x[u];v=p[t];if(v!==e&&v.length>0){o+=(o.length>0?" ":"")+t+": "+v+";"}}}}if(r&&f&&f.styles){i("*");i(r)}else{for(n in p){q=p[n];if(q!==e&&q.length>0){o+=(o.length>0?" ":"")+n+": "+q+";"}}}return o}}};(function(m){var h={},j,l,g,f,c={},b,e,d=m.makeMap,k=m.each;function i(o,n){return o.split(n||",")}function a(r,q){var o,p={};function n(s){return s.replace(/[A-Z]+/g,function(t){return n(r[t])})}for(o in r){if(r.hasOwnProperty(o)){r[o]=n(r[o])}}n(q).replace(/#/g,"#text").replace(/(\w+)\[([^\]]+)\]\[([^\]]*)\]/g,function(v,t,s,u){s=i(s,"|");p[t]={attributes:d(s),attributesOrder:s,children:d(u,"|",{"#comment":{}})}});return p}l="h1,h2,h3,h4,h5,h6,hr,p,div,address,pre,form,table,tbody,thead,tfoot,th,tr,td,li,ol,ul,caption,blockquote,center,dl,dt,dd,dir,fieldset,noscript,menu,isindex,samp,header,footer,article,section,hgroup";l=d(l,",",d(l.toUpperCase()));h=a({Z:"H|K|N|O|P",Y:"X|form|R|Q",ZG:"E|span|width|align|char|charoff|valign",X:"p|T|div|U|W|isindex|fieldset|table",ZF:"E|align|char|charoff|valign",W:"pre|hr|blockquote|address|center|noframes",ZE:"abbr|axis|headers|scope|rowspan|colspan|align|char|charoff|valign|nowrap|bgcolor|width|height",ZD:"[E][S]",U:"ul|ol|dl|menu|dir",ZC:"p|Y|div|U|W|table|br|span|bdo|object|applet|img|map|K|N|Q",T:"h1|h2|h3|h4|h5|h6",ZB:"X|S|Q",S:"R|P",ZA:"a|G|J|M|O|P",R:"a|H|K|N|O",Q:"noscript|P",P:"ins|del|script",O:"input|select|textarea|label|button",N:"M|L",M:"em|strong|dfn|code|q|samp|kbd|var|cite|abbr|acronym",L:"sub|sup",K:"J|I",J:"tt|i|b|u|s|strike",I:"big|small|font|basefont",H:"G|F",G:"br|span|bdo",F:"object|applet|img|map|iframe",E:"A|B|C",D:"accesskey|tabindex|onfocus|onblur",C:"onclick|ondblclick|onmousedown|onmouseup|onmouseover|onmousemove|onmouseout|onkeypress|onkeydown|onkeyup",B:"lang|xml:lang|dir",A:"id|class|style|title"},"script[id|charset|type|language|src|defer|xml:space][]style[B|id|type|media|title|xml:space][]object[E|declare|classid|codebase|data|type|codetype|archive|standby|width|height|usemap|name|tabindex|align|border|hspace|vspace][#|param|Y]param[id|name|value|valuetype|type][]p[E|align][#|S]a[E|D|charset|type|name|href|hreflang|rel|rev|shape|coords|target][#|Z]br[A|clear][]span[E][#|S]bdo[A|C|B][#|S]applet[A|codebase|archive|code|object|alt|name|width|height|align|hspace|vspace][#|param|Y]h1[E|align][#|S]img[E|src|alt|name|longdesc|width|height|usemap|ismap|align|border|hspace|vspace][]map[B|C|A|name][X|form|Q|area]h2[E|align][#|S]iframe[A|longdesc|name|src|frameborder|marginwidth|marginheight|scrolling|align|width|height][#|Y]h3[E|align][#|S]tt[E][#|S]i[E][#|S]b[E][#|S]u[E][#|S]s[E][#|S]strike[E][#|S]big[E][#|S]small[E][#|S]font[A|B|size|color|face][#|S]basefont[id|size|color|face][]em[E][#|S]strong[E][#|S]dfn[E][#|S]code[E][#|S]q[E|cite][#|S]samp[E][#|S]kbd[E][#|S]var[E][#|S]cite[E][#|S]abbr[E][#|S]acronym[E][#|S]sub[E][#|S]sup[E][#|S]input[E|D|type|name|value|checked|disabled|readonly|size|maxlength|src|alt|usemap|onselect|onchange|accept|align][]select[E|name|size|multiple|disabled|tabindex|onfocus|onblur|onchange][optgroup|option]optgroup[E|disabled|label][option]option[E|selected|disabled|label|value][]textarea[E|D|name|rows|cols|disabled|readonly|onselect|onchange][]label[E|for|accesskey|onfocus|onblur][#|S]button[E|D|name|value|type|disabled][#|p|T|div|U|W|table|G|object|applet|img|map|K|N|Q]h4[E|align][#|S]ins[E|cite|datetime][#|Y]h5[E|align][#|S]del[E|cite|datetime][#|Y]h6[E|align][#|S]div[E|align][#|Y]ul[E|type|compact][li]li[E|type|value][#|Y]ol[E|type|compact|start][li]dl[E|compact][dt|dd]dt[E][#|S]dd[E][#|Y]menu[E|compact][li]dir[E|compact][li]pre[E|width|xml:space][#|ZA]hr[E|align|noshade|size|width][]blockquote[E|cite][#|Y]address[E][#|S|p]center[E][#|Y]noframes[E][#|Y]isindex[A|B|prompt][]fieldset[E][#|legend|Y]legend[E|accesskey|align][#|S]table[E|summary|width|border|frame|rules|cellspacing|cellpadding|align|bgcolor][caption|col|colgroup|thead|tfoot|tbody|tr]caption[E|align][#|S]col[ZG][]colgroup[ZG][col]thead[ZF][tr]tr[ZF|bgcolor][th|td]th[E|ZE][#|Y]form[E|action|method|name|enctype|onsubmit|onreset|accept|accept-charset|target][#|X|R|Q]noscript[E][#|Y]td[E|ZE][#|Y]tfoot[ZF][tr]tbody[ZF][tr]area[E|D|shape|coords|href|nohref|alt|target][]base[id|href|target][]body[E|onload|onunload|background|bgcolor|text|link|vlink|alink][#|Y]");j=d("checked,compact,declare,defer,disabled,ismap,multiple,nohref,noresize,noshade,nowrap,readonly,selected,autoplay,loop,controls");g=d("area,base,basefont,br,col,frame,hr,img,input,isindex,link,meta,param,embed,source");f=m.extend(d("td,th,iframe,video,audio,object"),g);b=d("pre,script,style,textarea");e=d("colgroup,dd,dt,li,options,p,td,tfoot,th,thead,tr");m.html.Schema=function(r){var A=this,n={},o={},y=[],q,p;r=r||{};if(r.verify_html===false){r.valid_elements="*[*]"}if(r.valid_styles){q={};k(r.valid_styles,function(C,B){q[B]=m.explode(C)})}p=r.whitespace_elements?d(r.whitespace_elements):b;function z(B){return new RegExp("^"+B.replace(/([?+*])/g,".$1")+"$")}function t(I){var H,D,W,S,X,C,F,R,U,N,V,Z,L,G,T,B,P,E,Y,aa,M,Q,K=/^([#+-])?([^\[\/]+)(?:\/([^\[]+))?(?:\[([^\]]+)\])?$/,O=/^([!\-])?(\w+::\w+|[^=:<]+)?(?:([=:<])(.*))?$/,J=/[*?+]/;if(I){I=i(I);if(n["@"]){P=n["@"].attributes;E=n["@"].attributesOrder}for(H=0,D=I.length;H<D;H++){C=K.exec(I[H]);if(C){T=C[1];N=C[2];B=C[3];U=C[4];L={};G=[];F={attributes:L,attributesOrder:G};if(T==="#"){F.paddEmpty=true}if(T==="-"){F.removeEmpty=true}if(P){for(aa in P){L[aa]=P[aa]}G.push.apply(G,E)}if(U){U=i(U,"|");for(W=0,S=U.length;W<S;W++){C=O.exec(U[W]);if(C){R={};Z=C[1];V=C[2].replace(/::/g,":");T=C[3];Q=C[4];if(Z==="!"){F.attributesRequired=F.attributesRequired||[];F.attributesRequired.push(V);R.required=true}if(Z==="-"){delete L[V];G.splice(m.inArray(G,V),1);continue}if(T){if(T==="="){F.attributesDefault=F.attributesDefault||[];F.attributesDefault.push({name:V,value:Q});R.defaultValue=Q}if(T===":"){F.attributesForced=F.attributesForced||[];F.attributesForced.push({name:V,value:Q});R.forcedValue=Q}if(T==="<"){R.validValues=d(Q,"?")}}if(J.test(V)){F.attributePatterns=F.attributePatterns||[];R.pattern=z(V);F.attributePatterns.push(R)}else{if(!L[V]){G.push(V)}L[V]=R}}}}if(!P&&N=="@"){P=L;E=G}if(B){F.outputName=N;n[B]=F}if(J.test(N)){F.pattern=z(N);y.push(F)}else{n[N]=F}}}}}function v(B){n={};y=[];t(B);k(h,function(D,C){o[C]=D.children})}function s(C){var B=/^(~)?(.+)$/;if(C){k(i(C),function(G){var E=B.exec(G),F=E[1]==="~",H=F?"span":"div",D=E[2];o[D]=o[H];c[D]=H;if(!F){l[D]={}}k(o,function(I,J){if(I[H]){I[D]=I[H]}})})}}function u(C){var B=/^([+\-]?)(\w+)\[([^\]]+)\]$/;if(C){k(i(C),function(G){var F=B.exec(G),D,E;if(F){E=F[1];if(E){D=o[F[2]]}else{D=o[F[2]]={"#comment":{}}}D=o[F[2]];k(i(F[3],"|"),function(H){if(E==="-"){delete D[H]}else{D[H]={}}})}})}}function x(B){var D=n[B],C;if(D){return D}C=y.length;while(C--){D=y[C];if(D.pattern.test(B)){return D}}}if(!r.valid_elements){k(h,function(C,B){n[B]={attributes:C.attributes,attributesOrder:C.attributesOrder};o[B]=C.children});k(i("strong/b,em/i"),function(B){B=i(B,"/");n[B[1]].outputName=B[0]});n.img.attributesDefault=[{name:"alt",value:""}];k(i("ol,ul,sub,sup,blockquote,span,font,a,table,tbody,tr"),function(B){n[B].removeEmpty=true});k(i("p,h1,h2,h3,h4,h5,h6,th,td,pre,div,address,caption"),function(B){n[B].paddEmpty=true})}else{v(r.valid_elements)}s(r.custom_elements);u(r.valid_children);t(r.extended_valid_elements);u("+ol[ul|ol],+ul[ul|ol]");if(!x("span")){t("span[!data-mce-type|*]")}if(r.invalid_elements){m.each(m.explode(r.invalid_elements),function(B){if(n[B]){delete n[B]}})}A.children=o;A.styles=q;A.getBoolAttrs=function(){return j};A.getBlockElements=function(){return l};A.getShortEndedElements=function(){return g};A.getSelfClosingElements=function(){return e};A.getNonEmptyElements=function(){return f};A.getWhiteSpaceElements=function(){return p};A.isValidChild=function(B,D){var C=o[B];return !!(C&&C[D])};A.getElementRule=x;A.getCustomElements=function(){return c};A.addValidElements=t;A.setValidElements=v;A.addCustomElements=s;A.addValidChildren=u};m.html.Schema.boolAttrMap=j;m.html.Schema.blockElementsMap=l})(tinymce);(function(a){a.html.SaxParser=function(c,e){var b=this,d=function(){};c=c||{};b.schema=e=e||new a.html.Schema();if(c.fix_self_closing!==false){c.fix_self_closing=true}a.each("comment cdata text start end pi doctype".split(" "),function(f){if(f){b[f]=c[f]||d}});b.parse=function(D){var n=this,g,F=0,H,A,z=[],M,P,B,q,y,r,L,G,N,u,m,k,s,Q,o,O,E,R,K,f,I,l,C,J,h,v=0,j=a.html.Entities.decode,x,p;function t(S){var U,T;U=z.length;while(U--){if(z[U].name===S){break}}if(U>=0){for(T=z.length-1;T>=U;T--){S=z[T];if(S.valid){n.end(S.name)}}z.length=U}}l=new RegExp("<(?:(?:!--([\\w\\W]*?)-->)|(?:!\\[CDATA\\[([\\w\\W]*?)\\]\\]>)|(?:!DOCTYPE([\\w\\W]*?)>)|(?:\\?([^\\s\\/<>]+) ?([\\w\\W]*?)[?/]>)|(?:\\/([^>]+)>)|(?:([^\\s\\/<>]+)((?:\\s+[^\"'>]+(?:(?:\"[^\"]*\")|(?:'[^']*')|[^>]*))*|\\/)>))","g");C=/([\w:\-]+)(?:\s*=\s*(?:(?:\"((?:\\.|[^\"])*)\")|(?:\'((?:\\.|[^\'])*)\')|([^>\s]+)))?/g;J={script:/<\/script[^>]*>/gi,style:/<\/style[^>]*>/gi,noscript:/<\/noscript[^>]*>/gi};L=e.getShortEndedElements();I=e.getSelfClosingElements();G=e.getBoolAttrs();u=c.validate;r=c.remove_internals;x=c.fix_self_closing;p=a.isIE;o=/^:/;while(g=l.exec(D)){if(F<g.index){n.text(j(D.substr(F,g.index-F)))}if(H=g[6]){H=H.toLowerCase();if(p&&o.test(H)){H=H.substr(1)}t(H)}else{if(H=g[7]){H=H.toLowerCase();if(p&&o.test(H)){H=H.substr(1)}N=H in L;if(x&&I[H]&&z.length>0&&z[z.length-1].name===H){t(H)}if(!u||(m=e.getElementRule(H))){k=true;if(u){O=m.attributes;E=m.attributePatterns}if(Q=g[8]){y=Q.indexOf("data-mce-type")!==-1;if(y&&r){k=false}M=[];M.map={};Q.replace(C,function(T,S,X,W,V){var Y,U;S=S.toLowerCase();X=S in G?S:j(X||W||V||"");if(u&&!y&&S.indexOf("data-")!==0){Y=O[S];if(!Y&&E){U=E.length;while(U--){Y=E[U];if(Y.pattern.test(S)){break}}if(U===-1){Y=null}}if(!Y){return}if(Y.validValues&&!(X in Y.validValues)){return}}M.map[S]=X;M.push({name:S,value:X})})}else{M=[];M.map={}}if(u&&!y){R=m.attributesRequired;K=m.attributesDefault;f=m.attributesForced;if(f){P=f.length;while(P--){s=f[P];q=s.name;h=s.value;if(h==="{$uid}"){h="mce_"+v++}M.map[q]=h;M.push({name:q,value:h})}}if(K){P=K.length;while(P--){s=K[P];q=s.name;if(!(q in M.map)){h=s.value;if(h==="{$uid}"){h="mce_"+v++}M.map[q]=h;M.push({name:q,value:h})}}}if(R){P=R.length;while(P--){if(R[P] in M.map){break}}if(P===-1){k=false}}if(M.map["data-mce-bogus"]){k=false}}if(k){n.start(H,M,N)}}else{k=false}if(A=J[H]){A.lastIndex=F=g.index+g[0].length;if(g=A.exec(D)){if(k){B=D.substr(F,g.index-F)}F=g.index+g[0].length}else{B=D.substr(F);F=D.length}if(k&&B.length>0){n.text(B,true)}if(k){n.end(H)}l.lastIndex=F;continue}if(!N){if(!Q||Q.indexOf("/")!=Q.length-1){z.push({name:H,valid:k})}else{if(k){n.end(H)}}}}else{if(H=g[1]){n.comment(H)}else{if(H=g[2]){n.cdata(H)}else{if(H=g[3]){n.doctype(H)}else{if(H=g[4]){n.pi(H,g[5])}}}}}}F=g.index+g[0].length}if(F<D.length){n.text(j(D.substr(F)))}for(P=z.length-1;P>=0;P--){H=z[P];if(H.valid){n.end(H.name)}}}}})(tinymce);(function(d){var c=/^[ \t\r\n]*$/,e={"#text":3,"#comment":8,"#cdata":4,"#pi":7,"#doctype":10,"#document-fragment":11};function a(k,l,j){var i,h,f=j?"lastChild":"firstChild",g=j?"prev":"next";if(k[f]){return k[f]}if(k!==l){i=k[g];if(i){return i}for(h=k.parent;h&&h!==l;h=h.parent){i=h[g];if(i){return i}}}}function b(f,g){this.name=f;this.type=g;if(g===1){this.attributes=[];this.attributes.map={}}}d.extend(b.prototype,{replace:function(g){var f=this;if(g.parent){g.remove()}f.insert(g,f);f.remove();return f},attr:function(h,l){var f=this,g,j,k;if(typeof h!=="string"){for(j in h){f.attr(j,h[j])}return f}if(g=f.attributes){if(l!==k){if(l===null){if(h in g.map){delete g.map[h];j=g.length;while(j--){if(g[j].name===h){g=g.splice(j,1);return f}}}return f}if(h in g.map){j=g.length;while(j--){if(g[j].name===h){g[j].value=l;break}}}else{g.push({name:h,value:l})}g.map[h]=l;return f}else{return g.map[h]}}},clone:function(){var g=this,n=new b(g.name,g.type),h,f,m,j,k;if(m=g.attributes){k=[];k.map={};for(h=0,f=m.length;h<f;h++){j=m[h];if(j.name!=="id"){k[k.length]={name:j.name,value:j.value};k.map[j.name]=j.value}}n.attributes=k}n.value=g.value;n.shortEnded=g.shortEnded;return n},wrap:function(g){var f=this;f.parent.insert(g,f);g.append(f);return f},unwrap:function(){var f=this,h,g;for(h=f.firstChild;h;){g=h.next;f.insert(h,f,true);h=g}f.remove()},remove:function(){var f=this,h=f.parent,g=f.next,i=f.prev;if(h){if(h.firstChild===f){h.firstChild=g;if(g){g.prev=null}}else{i.next=g}if(h.lastChild===f){h.lastChild=i;if(i){i.next=null}}else{g.prev=i}f.parent=f.next=f.prev=null}return f},append:function(h){var f=this,g;if(h.parent){h.remove()}g=f.lastChild;if(g){g.next=h;h.prev=g;f.lastChild=h}else{f.lastChild=f.firstChild=h}h.parent=f;return h},insert:function(h,f,i){var g;if(h.parent){h.remove()}g=f.parent||this;if(i){if(f===g.firstChild){g.firstChild=h}else{f.prev.next=h}h.prev=f.prev;h.next=f;f.prev=h}else{if(f===g.lastChild){g.lastChild=h}else{f.next.prev=h}h.next=f.next;h.prev=f;f.next=h}h.parent=g;return h},getAll:function(g){var f=this,h,i=[];for(h=f.firstChild;h;h=a(h,f)){if(h.name===g){i.push(h)}}return i},empty:function(){var g=this,f,h,j;if(g.firstChild){f=[];for(j=g.firstChild;j;j=a(j,g)){f.push(j)}h=f.length;while(h--){j=f[h];j.parent=j.firstChild=j.lastChild=j.next=j.prev=null}}g.firstChild=g.lastChild=null;return g},isEmpty:function(k){var f=this,j=f.firstChild,h,g;if(j){do{if(j.type===1){if(j.attributes.map["data-mce-bogus"]){continue}if(k[j.name]){return false}h=j.attributes.length;while(h--){g=j.attributes[h].name;if(g==="name"||g.indexOf("data-")===0){return false}}}if((j.type===3&&!c.test(j.value))){return false}}while(j=a(j,f))}return true},walk:function(f){return a(this,null,f)}});d.extend(b,{create:function(g,f){var i,h;i=new b(g,e[g]||1);if(f){for(h in f){i.attr(h,f[h])}}return i}});d.html.Node=b})(tinymce);(function(b){var a=b.html.Node;b.html.DomParser=function(g,h){var f=this,e={},d=[],i={},c={};g=g||{};g.validate="validate" in g?g.validate:true;g.root_name=g.root_name||"body";f.schema=h=h||new b.html.Schema();function j(m){var o,p,x,v,z,n,q,l,t,u,k,s,y,r;s=b.makeMap("tr,td,th,tbody,thead,tfoot,table");k=h.getNonEmptyElements();for(o=0;o<m.length;o++){p=m[o];if(!p.parent){continue}v=[p];for(x=p.parent;x&&!h.isValidChild(x.name,p.name)&&!s[x.name];x=x.parent){v.push(x)}if(x&&v.length>1){v.reverse();z=n=f.filterNode(v[0].clone());for(t=0;t<v.length-1;t++){if(h.isValidChild(n.name,v[t].name)){q=f.filterNode(v[t].clone());n.append(q)}else{q=n}for(l=v[t].firstChild;l&&l!=v[t+1];){r=l.next;q.append(l);l=r}n=q}if(!z.isEmpty(k)){x.insert(z,v[0],true);x.insert(p,z)}else{x.insert(p,v[0],true)}x=v[0];if(x.isEmpty(k)||x.firstChild===x.lastChild&&x.firstChild.name==="br"){x.empty().remove()}}else{if(p.parent){if(p.name==="li"){y=p.prev;if(y&&(y.name==="ul"||y.name==="ul")){y.append(p);continue}y=p.next;if(y&&(y.name==="ul"||y.name==="ul")){y.insert(p,y.firstChild,true);continue}p.wrap(f.filterNode(new a("ul",1)));continue}if(h.isValidChild(p.parent.name,"div")&&h.isValidChild("div",p.name)){p.wrap(f.filterNode(new a("div",1)))}else{if(p.name==="style"||p.name==="script"){p.empty().remove()}else{p.unwrap()}}}}}}f.filterNode=function(m){var l,k,n;if(k in e){n=i[k];if(n){n.push(m)}else{i[k]=[m]}}l=d.length;while(l--){k=d[l].name;if(k in m.attributes.map){n=c[k];if(n){n.push(m)}else{c[k]=[m]}}}return m};f.addNodeFilter=function(k,l){b.each(b.explode(k),function(m){var n=e[m];if(!n){e[m]=n=[]}n.push(l)})};f.addAttributeFilter=function(k,l){b.each(b.explode(k),function(m){var n;for(n=0;n<d.length;n++){if(d[n].name===m){d[n].callbacks.push(l);return}}d.push({name:m,callbacks:[l]})})};f.parse=function(v,m){var n,H,A,z,C,B,x,r,E,K,y,o,D,J=[],t,k,s,p,u,q;m=m||{};i={};c={};o=b.extend(b.makeMap("script,style,head,html,body,title,meta,param"),h.getBlockElements());u=h.getNonEmptyElements();p=h.children;y=g.validate;q="forced_root_block" in m?m.forced_root_block:g.forced_root_block;s=h.getWhiteSpaceElements();D=/^[ \t\r\n]+/;t=/[ \t\r\n]+$/;k=/[ \t\r\n]+/g;function F(){var L=H.firstChild,l,M;while(L){l=L.next;if(L.type==3||(L.type==1&&L.name!=="p"&&!o[L.name]&&!L.attr("data-mce-type"))){if(!M){M=I(q,1);H.insert(M,L);M.append(L)}else{M.append(L)}}else{M=null}L=l}}function I(l,L){var M=new a(l,L),N;if(l in e){N=i[l];if(N){N.push(M)}else{i[l]=[M]}}return M}function G(M){var N,l,L;for(N=M.prev;N&&N.type===3;){l=N.value.replace(t,"");if(l.length>0){N.value=l;N=N.prev}else{L=N.prev;N.remove();N=L}}}n=new b.html.SaxParser({validate:y,fix_self_closing:!y,cdata:function(l){A.append(I("#cdata",4)).value=l},text:function(M,l){var L;if(!s[A.name]){M=M.replace(k," ");if(A.lastChild&&o[A.lastChild.name]){M=M.replace(D,"")}}if(M.length!==0){L=I("#text",3);L.raw=!!l;A.append(L).value=M}},comment:function(l){A.append(I("#comment",8)).value=l},pi:function(l,L){A.append(I(l,7)).value=L;G(A)},doctype:function(L){var l;l=A.append(I("#doctype",10));l.value=L;G(A)},start:function(l,T,M){var R,O,N,L,P,U,S,Q;N=y?h.getElementRule(l):{};if(N){R=I(N.outputName||l,1);R.attributes=T;R.shortEnded=M;A.append(R);Q=p[A.name];if(Q&&p[R.name]&&!Q[R.name]){J.push(R)}O=d.length;while(O--){P=d[O].name;if(P in T.map){E=c[P];if(E){E.push(R)}else{c[P]=[R]}}}if(o[l]){G(R)}if(!M){A=R}}},end:function(l){var P,M,O,L,N;M=y?h.getElementRule(l):{};if(M){if(o[l]){if(!s[A.name]){for(P=A.firstChild;P&&P.type===3;){O=P.value.replace(D,"");if(O.length>0){P.value=O;P=P.next}else{L=P.next;P.remove();P=L}}for(P=A.lastChild;P&&P.type===3;){O=P.value.replace(t,"");if(O.length>0){P.value=O;P=P.prev}else{L=P.prev;P.remove();P=L}}}P=A.prev;if(P&&P.type===3){O=P.value.replace(D,"");if(O.length>0){P.value=O}else{P.remove()}}}if(M.removeEmpty||M.paddEmpty){if(A.isEmpty(u)){if(M.paddEmpty){A.empty().append(new a("#text","3")).value="\u00a0"}else{if(!A.attributes.map.name){N=A.parent;A.empty().remove();A=N;return}}}}A=A.parent}}},h);H=A=new a(m.context||g.root_name,11);n.parse(v);if(y&&J.length){if(!m.context){j(J)}else{m.invalid=true}}if(q&&H.name=="body"){F()}if(!m.invalid){for(K in i){E=e[K];z=i[K];x=z.length;while(x--){if(!z[x].parent){z.splice(x,1)}}for(C=0,B=E.length;C<B;C++){E[C](z,K,m)}}for(C=0,B=d.length;C<B;C++){E=d[C];if(E.name in c){z=c[E.name];x=z.length;while(x--){if(!z[x].parent){z.splice(x,1)}}for(x=0,r=E.callbacks.length;x<r;x++){E.callbacks[x](z,E.name,m)}}}}return H};if(g.remove_trailing_brs){f.addNodeFilter("br",function(n,m){var r,q=n.length,o,u=h.getBlockElements(),k=h.getNonEmptyElements(),s,p,t;u.body=1;for(r=0;r<q;r++){o=n[r];s=o.parent;if(u[o.parent.name]&&o===s.lastChild){p=o.prev;while(p){t=p.name;if(t!=="span"||p.attr("data-mce-type")!=="bookmark"){if(t!=="br"){break}if(t==="br"){o=null;break}}p=p.prev}if(o){o.remove();if(s.isEmpty(k)){elementRule=h.getElementRule(s.name);if(elementRule){if(elementRule.removeEmpty){s.remove()}else{if(elementRule.paddEmpty){s.empty().append(new b.html.Node("#text",3)).value="\u00a0"}}}}}}}})}}})(tinymce);tinymce.html.Writer=function(e){var c=[],a,b,d,f,g;e=e||{};a=e.indent;b=tinymce.makeMap(e.indent_before||"");d=tinymce.makeMap(e.indent_after||"");f=tinymce.html.Entities.getEncodeFunc(e.entity_encoding||"raw",e.entities);g=e.element_format=="html";return{start:function(m,k,p){var n,j,h,o;if(a&&b[m]&&c.length>0){o=c[c.length-1];if(o.length>0&&o!=="\n"){c.push("\n")}}c.push("<",m);if(k){for(n=0,j=k.length;n<j;n++){h=k[n];c.push(" ",h.name,'="',f(h.value,true),'"')}}if(!p||g){c[c.length]=">"}else{c[c.length]=" />"}if(p&&a&&d[m]&&c.length>0){o=c[c.length-1];if(o.length>0&&o!=="\n"){c.push("\n")}}},end:function(h){var i;c.push("</",h,">");if(a&&d[h]&&c.length>0){i=c[c.length-1];if(i.length>0&&i!=="\n"){c.push("\n")}}},text:function(i,h){if(i.length>0){c[c.length]=h?i:f(i)}},cdata:function(h){c.push("<![CDATA[",h,"]]>")},comment:function(h){c.push("<!--",h,"-->")},pi:function(h,i){if(i){c.push("<?",h," ",i,"?>")}else{c.push("<?",h,"?>")}if(a){c.push("\n")}},doctype:function(h){c.push("<!DOCTYPE",h,">",a?"\n":"")},reset:function(){c.length=0},getContent:function(){return c.join("").replace(/\n$/,"")}}};(function(a){a.html.Serializer=function(c,d){var b=this,e=new a.html.Writer(c);c=c||{};c.validate="validate" in c?c.validate:true;b.schema=d=d||new a.html.Schema();b.writer=e;b.serialize=function(h){var g,i;i=c.validate;g={3:function(k,j){e.text(k.value,k.raw)},8:function(j){e.comment(j.value)},7:function(j){e.pi(j.name,j.value)},10:function(j){e.doctype(j.value)},4:function(j){e.cdata(j.value)},11:function(j){if((j=j.firstChild)){do{f(j)}while(j=j.next)}}};e.reset();function f(k){var t=g[k.type],j,o,s,r,p,u,n,m,q;if(!t){j=k.name;o=k.shortEnded;s=k.attributes;if(i&&s&&s.length>1){u=[];u.map={};q=d.getElementRule(k.name);for(n=0,m=q.attributesOrder.length;n<m;n++){r=q.attributesOrder[n];if(r in s.map){p=s.map[r];u.map[r]=p;u.push({name:r,value:p})}}for(n=0,m=s.length;n<m;n++){r=s[n].name;if(!(r in u.map)){p=s.map[r];u.map[r]=p;u.push({name:r,value:p})}}s=u}e.start(k.name,s,o);if(!o){if((k=k.firstChild)){do{f(k)}while(k=k.next)}e.end(j)}}else{t(k)}}if(h.type==1&&!c.inner){f(h)}else{g[11](h)}return e.getContent()}}})(tinymce);(function(h){var f=h.each,e=h.is,d=h.isWebKit,b=h.isIE,c=h.html.Entities,a=/^([a-z0-9],?)+$/i,g=h.html.Schema.blockElementsMap,i=/^[ \t\r\n]*$/;h.create("tinymce.dom.DOMUtils",{doc:null,root:null,files:null,pixelStyles:/^(top|left|bottom|right|width|height|borderWidth)$/,props:{"for":"htmlFor","class":"className",className:"className",checked:"checked",disabled:"disabled",maxlength:"maxLength",readonly:"readOnly",selected:"selected",value:"value",id:"id",name:"name",type:"type"},DOMUtils:function(o,m){var l=this,j,k;l.doc=o;l.win=window;l.files={};l.cssFlicker=false;l.counter=0;l.stdMode=!h.isIE||o.documentMode>=8;l.boxModel=!h.isIE||o.compatMode=="CSS1Compat"||l.stdMode;l.hasOuterHTML="outerHTML" in o.createElement("a");l.settings=m=h.extend({keep_values:false,hex_colors:1},m);l.schema=m.schema;l.styles=new h.html.Styles({url_converter:m.url_converter,url_converter_scope:m.url_converter_scope},m.schema);if(h.isIE6){try{o.execCommand("BackgroundImageCache",false,true)}catch(n){l.cssFlicker=true}}if(b&&m.schema){("abbr article aside audio canvas details figcaption figure footer header hgroup mark menu meter nav output progress section summary time video").replace(/\w+/g,function(p){o.createElement(p)});for(k in m.schema.getCustomElements()){o.createElement(k)}}h.addUnload(l.destroy,l)},getRoot:function(){var j=this,k=j.settings;return(k&&j.get(k.root_element))||j.doc.body},getViewPort:function(k){var l,j;k=!k?this.win:k;l=k.document;j=this.boxModel?l.documentElement:l.body;return{x:k.pageXOffset||j.scrollLeft,y:k.pageYOffset||j.scrollTop,w:k.innerWidth||j.clientWidth,h:k.innerHeight||j.clientHeight}},getRect:function(m){var l,j=this,k;m=j.get(m);l=j.getPos(m);k=j.getSize(m);return{x:l.x,y:l.y,w:k.w,h:k.h}},getSize:function(m){var k=this,j,l;m=k.get(m);j=k.getStyle(m,"width");l=k.getStyle(m,"height");if(j.indexOf("px")===-1){j=0}if(l.indexOf("px")===-1){l=0}return{w:parseInt(j)||m.offsetWidth||m.clientWidth,h:parseInt(l)||m.offsetHeight||m.clientHeight}},getParent:function(l,k,j){return this.getParents(l,k,j,false)},getParents:function(u,p,l,s){var k=this,j,m=k.settings,q=[];u=k.get(u);s=s===undefined;if(m.strict_root){l=l||k.getRoot()}if(e(p,"string")){j=p;if(p==="*"){p=function(o){return o.nodeType==1}}else{p=function(o){return k.is(o,j)}}}while(u){if(u==l||!u.nodeType||u.nodeType===9){break}if(!p||p(u)){if(s){q.push(u)}else{return u}}u=u.parentNode}return s?q:null},get:function(j){var k;if(j&&this.doc&&typeof(j)=="string"){k=j;j=this.doc.getElementById(j);if(j&&j.id!==k){return this.doc.getElementsByName(k)[1]}}return j},getNext:function(k,j){return this._findSib(k,j,"nextSibling")},getPrev:function(k,j){return this._findSib(k,j,"previousSibling")},select:function(l,k){var j=this;return h.dom.Sizzle(l,j.get(k)||j.get(j.settings.root_element)||j.doc,[])},is:function(l,j){var k;if(l.length===undefined){if(j==="*"){return l.nodeType==1}if(a.test(j)){j=j.toLowerCase().split(/,/);l=l.nodeName.toLowerCase();for(k=j.length-1;k>=0;k--){if(j[k]==l){return true}}return false}}return h.dom.Sizzle.matches(j,l.nodeType?[l]:l).length>0},add:function(m,q,j,l,o){var k=this;return this.run(m,function(s){var r,n;r=e(q,"string")?k.doc.createElement(q):q;k.setAttribs(r,j);if(l){if(l.nodeType){r.appendChild(l)}else{k.setHTML(r,l)}}return !o?s.appendChild(r):r})},create:function(l,j,k){return this.add(this.doc.createElement(l),l,j,k,1)},createHTML:function(r,j,p){var q="",m=this,l;q+="<"+r;for(l in j){if(j.hasOwnProperty(l)){q+=" "+l+'="'+m.encode(j[l])+'"'}}if(typeof(p)!="undefined"){return q+">"+p+"</"+r+">"}return q+" />"},remove:function(j,k){return this.run(j,function(m){var n,l=m.parentNode;if(!l){return null}if(k){while(n=m.firstChild){if(!h.isIE||n.nodeType!==3||n.nodeValue){l.insertBefore(n,m)}else{m.removeChild(n)}}}return l.removeChild(m)})},setStyle:function(m,j,k){var l=this;return l.run(m,function(p){var o,n;o=p.style;j=j.replace(/-(\D)/g,function(r,q){return q.toUpperCase()});if(l.pixelStyles.test(j)&&(h.is(k,"number")||/^[\-0-9\.]+$/.test(k))){k+="px"}switch(j){case"opacity":if(b){o.filter=k===""?"":"alpha(opacity="+(k*100)+")";if(!m.currentStyle||!m.currentStyle.hasLayout){o.display="inline-block"}}o[j]=o["-moz-opacity"]=o["-khtml-opacity"]=k||"";break;case"float":b?o.styleFloat=k:o.cssFloat=k;break;default:o[j]=k||""}if(l.settings.update_styles){l.setAttrib(p,"data-mce-style")}})},getStyle:function(m,j,l){m=this.get(m);if(!m){return}if(this.doc.defaultView&&l){j=j.replace(/[A-Z]/g,function(n){return"-"+n});try{return this.doc.defaultView.getComputedStyle(m,null).getPropertyValue(j)}catch(k){return null}}j=j.replace(/-(\D)/g,function(o,n){return n.toUpperCase()});if(j=="float"){j=b?"styleFloat":"cssFloat"}if(m.currentStyle&&l){return m.currentStyle[j]}return m.style?m.style[j]:undefined},setStyles:function(m,n){var k=this,l=k.settings,j;j=l.update_styles;l.update_styles=0;f(n,function(o,p){k.setStyle(m,p,o)});l.update_styles=j;if(l.update_styles){k.setAttrib(m,l.cssText)}},removeAllAttribs:function(j){return this.run(j,function(m){var l,k=m.attributes;for(l=k.length-1;l>=0;l--){m.removeAttributeNode(k.item(l))}})},setAttrib:function(l,m,j){var k=this;if(!l||!m){return}if(k.settings.strict){m=m.toLowerCase()}return this.run(l,function(q){var p=k.settings;var n=q.getAttribute(m);if(j!==null){switch(m){case"style":if(!e(j,"string")){f(j,function(r,s){k.setStyle(q,s,r)});return}if(p.keep_values){if(j&&!k._isRes(j)){q.setAttribute("data-mce-style",j,2)}else{q.removeAttribute("data-mce-style",2)}}q.style.cssText=j;break;case"class":q.className=j||"";break;case"src":case"href":if(p.keep_values){if(p.url_converter){j=p.url_converter.call(p.url_converter_scope||k,j,m,q)}k.setAttrib(q,"data-mce-"+m,j,2)}break;case"shape":q.setAttribute("data-mce-style",j);break}}if(e(j)&&j!==null&&j.length!==0){q.setAttribute(m,""+j,2)}else{q.removeAttribute(m,2)}if(tinyMCE.activeEditor&&n!=j){var o=tinyMCE.activeEditor;o.onSetAttrib.dispatch(o,q,m,j)}})},setAttribs:function(k,l){var j=this;return this.run(k,function(m){f(l,function(o,p){j.setAttrib(m,p,o)})})},getAttrib:function(o,p,l){var j,k=this,m;o=k.get(o);if(!o||o.nodeType!==1){return l===m?false:l}if(!e(l)){l=""}if(/^(src|href|style|coords|shape)$/.test(p)){j=o.getAttribute("data-mce-"+p);if(j){return j}}if(b&&k.props[p]){j=o[k.props[p]];j=j&&j.nodeValue?j.nodeValue:j}if(!j){j=o.getAttribute(p,2)}if(/^(checked|compact|declare|defer|disabled|ismap|multiple|nohref|noshade|nowrap|readonly|selected)$/.test(p)){if(o[k.props[p]]===true&&j===""){return p}return j?p:""}if(o.nodeName==="FORM"&&o.getAttributeNode(p)){return o.getAttributeNode(p).nodeValue}if(p==="style"){j=j||o.style.cssText;if(j){j=k.serializeStyle(k.parseStyle(j),o.nodeName);if(k.settings.keep_values&&!k._isRes(j)){o.setAttribute("data-mce-style",j)}}}if(d&&p==="class"&&j){j=j.replace(/(apple|webkit)\-[a-z\-]+/gi,"")}if(b){switch(p){case"rowspan":case"colspan":if(j===1){j=""}break;case"size":if(j==="+0"||j===20||j===0){j=""}break;case"width":case"height":case"vspace":case"checked":case"disabled":case"readonly":if(j===0){j=""}break;case"hspace":if(j===-1){j=""}break;case"maxlength":case"tabindex":if(j===32768||j===2147483647||j==="32768"){j=""}break;case"multiple":case"compact":case"noshade":case"nowrap":if(j===65535){return p}return l;case"shape":j=j.toLowerCase();break;default:if(p.indexOf("on")===0&&j){j=h._replace(/^function\s+\w+\(\)\s+\{\s+(.*)\s+\}$/,"$1",""+j)}}}return(j!==m&&j!==null&&j!=="")?""+j:l},getPos:function(s,m){var k=this,j=0,q=0,o,p=k.doc,l;s=k.get(s);m=m||p.body;if(s){if(s.getBoundingClientRect){s=s.getBoundingClientRect();o=k.boxModel?p.documentElement:p.body;j=s.left+(p.documentElement.scrollLeft||p.body.scrollLeft)-o.clientTop;q=s.top+(p.documentElement.scrollTop||p.body.scrollTop)-o.clientLeft;return{x:j,y:q}}l=s;while(l&&l!=m&&l.nodeType){j+=l.offsetLeft||0;q+=l.offsetTop||0;l=l.offsetParent}l=s.parentNode;while(l&&l!=m&&l.nodeType){j-=l.scrollLeft||0;q-=l.scrollTop||0;l=l.parentNode}}return{x:j,y:q}},parseStyle:function(j){return this.styles.parse(j)},serializeStyle:function(k,j){return this.styles.serialize(k,j)},loadCSS:function(j){var l=this,m=l.doc,k;if(!j){j=""}k=l.select("head")[0];f(j.split(","),function(n){var o;if(l.files[n]){return}l.files[n]=true;o=l.create("link",{rel:"stylesheet",href:h._addVer(n)});if(b&&m.documentMode&&m.recalc){o.onload=function(){if(m.recalc){m.recalc()}o.onload=null}}k.appendChild(o)})},addClass:function(j,k){return this.run(j,function(l){var m;if(!k){return 0}if(this.hasClass(l,k)){return l.className}m=this.removeClass(l,k);return l.className=(m!=""?(m+" "):"")+k})},removeClass:function(l,m){var j=this,k;return j.run(l,function(o){var n;if(j.hasClass(o,m)){if(!k){k=new RegExp("(^|\\s+)"+m+"(\\s+|$)","g")}n=o.className.replace(k," ");n=h.trim(n!=" "?n:"");o.className=n;if(!n){o.removeAttribute("class");o.removeAttribute("className")}return n}return o.className})},hasClass:function(k,j){k=this.get(k);if(!k||!j){return false}return(" "+k.className+" ").indexOf(" "+j+" ")!==-1},show:function(j){return this.setStyle(j,"display","block")},hide:function(j){return this.setStyle(j,"display","none")},isHidden:function(j){j=this.get(j);return !j||j.style.display=="none"||this.getStyle(j,"display")=="none"},uniqueId:function(j){return(!j?"mce_":j)+(this.counter++)},setHTML:function(l,k){var j=this;return j.run(l,function(n){if(b){while(n.firstChild){n.removeChild(n.firstChild)}try{n.innerHTML="<br />"+k;n.removeChild(n.firstChild)}catch(m){n=j.create("div");n.innerHTML="<br />"+k;f(n.childNodes,function(p,o){if(o){n.appendChild(p)}})}}else{n.innerHTML=k}return k})},getOuterHTML:function(l){var k,j=this;l=j.get(l);if(!l){return null}if(l.nodeType===1&&j.hasOuterHTML){return l.outerHTML}k=(l.ownerDocument||j.doc).createElement("body");k.appendChild(l.cloneNode(true));return k.innerHTML},setOuterHTML:function(m,k,n){var j=this;function l(p,o,r){var s,q;q=r.createElement("body");q.innerHTML=o;s=q.lastChild;while(s){j.insertAfter(s.cloneNode(true),p);s=s.previousSibling}j.remove(p)}return this.run(m,function(p){p=j.get(p);if(p.nodeType==1){n=n||p.ownerDocument||j.doc;if(b){try{if(b&&p.nodeType==1){p.outerHTML=k}else{l(p,k,n)}}catch(o){l(p,k,n)}}else{l(p,k,n)}}})},decode:c.decode,encode:c.encodeAllRaw,insertAfter:function(j,k){k=this.get(k);return this.run(j,function(m){var l,n;l=k.parentNode;n=k.nextSibling;if(n){l.insertBefore(m,n)}else{l.appendChild(m)}return m})},isBlock:function(k){var j=k.nodeType;if(j){return !!(j===1&&g[k.nodeName])}return !!g[k]},replace:function(p,m,j){var l=this;if(e(m,"array")){p=p.cloneNode(true)}return l.run(m,function(k){if(j){f(h.grep(k.childNodes),function(n){p.appendChild(n)})}return k.parentNode.replaceChild(p,k)})},rename:function(m,j){var l=this,k;if(m.nodeName!=j.toUpperCase()){k=l.create(j);f(l.getAttribs(m),function(n){l.setAttrib(k,n.nodeName,l.getAttrib(m,n.nodeName))});l.replace(k,m,1)}return k||m},findCommonAncestor:function(l,j){var m=l,k;while(m){k=j;while(k&&m!=k){k=k.parentNode}if(m==k){break}m=m.parentNode}if(!m&&l.ownerDocument){return l.ownerDocument.documentElement}return m},toHex:function(j){var l=/^\s*rgb\s*?\(\s*?([0-9]+)\s*?,\s*?([0-9]+)\s*?,\s*?([0-9]+)\s*?\)\s*$/i.exec(j);function k(m){m=parseInt(m).toString(16);return m.length>1?m:"0"+m}if(l){j="#"+k(l[1])+k(l[2])+k(l[3]);return j}return j},getClasses:function(){var n=this,j=[],m,o={},p=n.settings.class_filter,l;if(n.classes){return n.classes}function q(r){f(r.imports,function(s){q(s)});f(r.cssRules||r.rules,function(s){switch(s.type||1){case 1:if(s.selectorText){f(s.selectorText.split(","),function(t){t=t.replace(/^\s*|\s*$|^\s\./g,"");if(/\.mce/.test(t)||!/\.[\w\-]+$/.test(t)){return}l=t;t=h._replace(/.*\.([a-z0-9_\-]+).*/i,"$1",t);if(p&&!(t=p(t,l))){return}if(!o[t]){j.push({"class":t});o[t]=1}})}break;case 3:q(s.styleSheet);break}})}try{f(n.doc.styleSheets,q)}catch(k){}if(j.length>0){n.classes=j}return j},run:function(m,l,k){var j=this,n;if(j.doc&&typeof(m)==="string"){m=j.get(m)}if(!m){return false}k=k||this;if(!m.nodeType&&(m.length||m.length===0)){n=[];f(m,function(p,o){if(p){if(typeof(p)=="string"){p=j.doc.getElementById(p)}n.push(l.call(k,p,o))}});return n}return l.call(k,m)},getAttribs:function(k){var j;k=this.get(k);if(!k){return[]}if(b){j=[];if(k.nodeName=="OBJECT"){return k.attributes}if(k.nodeName==="OPTION"&&this.getAttrib(k,"selected")){j.push({specified:1,nodeName:"selected"})}k.cloneNode(false).outerHTML.replace(/<\/?[\w:\-]+ ?|=[\"][^\"]+\"|=\'[^\']+\'|=[\w\-]+|>/gi,"").replace(/[\w:\-]+/gi,function(l){j.push({specified:1,nodeName:l})});return j}return k.attributes},isEmpty:function(m,k){var r=this,o,n,q,j,l,p;m=m.firstChild;if(m){j=new h.dom.TreeWalker(m);k=k||r.schema?r.schema.getNonEmptyElements():null;do{q=m.nodeType;if(q===1){if(m.getAttribute("data-mce-bogus")){continue}l=m.nodeName.toLowerCase();if(k&&k[l]){p=m.parentNode;if(l==="br"&&r.isBlock(p)&&p.firstChild===m&&p.lastChild===m){continue}return false}n=r.getAttribs(m);o=m.attributes.length;while(o--){l=m.attributes[o].nodeName;if(l==="name"||l==="data-mce-bookmark"){return false}}}if((q===3&&!i.test(m.nodeValue))){return false}}while(m=j.next())}return true},destroy:function(k){var j=this;if(j.events){j.events.destroy()}j.win=j.doc=j.root=j.events=null;if(!k){h.removeUnload(j.destroy)}},createRng:function(){var j=this.doc;return j.createRange?j.createRange():new h.dom.Range(this)},nodeIndex:function(n,o){var j=0,l,m,k;if(n){for(l=n.nodeType,n=n.previousSibling,m=n;n;n=n.previousSibling){k=n.nodeType;if(o&&k==3){if(k==l||!n.nodeValue.length){continue}}j++;l=k}}return j},split:function(n,m,q){var s=this,j=s.createRng(),o,l,p;function k(x){var u,t=x.childNodes,v=x.nodeType;function y(B){var A=B.previousSibling&&B.previousSibling.nodeName=="SPAN";var z=B.nextSibling&&B.nextSibling.nodeName=="SPAN";return A&&z}if(v==1&&x.getAttribute("data-mce-type")=="bookmark"){return}for(u=t.length-1;u>=0;u--){k(t[u])}if(v!=9){if(v==3&&x.nodeValue.length>0){var r=h.trim(x.nodeValue).length;if(!s.isBlock(x.parentNode)||r>0||r==0&&y(x)){return}}else{if(v==1){t=x.childNodes;if(t.length==1&&t[0]&&t[0].nodeType==1&&t[0].getAttribute("data-mce-type")=="bookmark"){x.parentNode.insertBefore(t[0],x)}if(t.length||/^(br|hr|input|img)$/i.test(x.nodeName)){return}}}s.remove(x)}return x}if(n&&m){j.setStart(n.parentNode,s.nodeIndex(n));j.setEnd(m.parentNode,s.nodeIndex(m));o=j.extractContents();j=s.createRng();j.setStart(m.parentNode,s.nodeIndex(m)+1);j.setEnd(n.parentNode,s.nodeIndex(n)+1);l=j.extractContents();p=n.parentNode;p.insertBefore(k(o),n);if(q){p.replaceChild(q,m)}else{p.insertBefore(m,n)}p.insertBefore(k(l),n);s.remove(n);return q||m}},bind:function(n,j,m,l){var k=this;if(!k.events){k.events=new h.dom.EventUtils()}return k.events.add(n,j,m,l||this)},unbind:function(m,j,l){var k=this;if(!k.events){k.events=new h.dom.EventUtils()}return k.events.remove(m,j,l)},_findSib:function(m,j,k){var l=this,n=j;if(m){if(e(n,"string")){n=function(o){return l.is(o,j)}}for(m=m[k];m;m=m[k]){if(n(m)){return m}}}return null},_isRes:function(j){return/^(top|left|bottom|right|width|height)/i.test(j)||/;\s*(top|left|bottom|right|width|height)/i.test(j)}});h.DOM=new h.dom.DOMUtils(document,{process_html:0})})(tinymce);(function(a){function b(c){var N=this,e=c.doc,S=0,E=1,j=2,D=true,R=false,U="startOffset",h="startContainer",P="endContainer",z="endOffset",k=tinymce.extend,n=c.nodeIndex;k(N,{startContainer:e,startOffset:0,endContainer:e,endOffset:0,collapsed:D,commonAncestorContainer:e,START_TO_START:0,START_TO_END:1,END_TO_END:2,END_TO_START:3,setStart:q,setEnd:s,setStartBefore:g,setStartAfter:I,setEndBefore:J,setEndAfter:u,collapse:A,selectNode:x,selectNodeContents:F,compareBoundaryPoints:v,deleteContents:p,extractContents:H,cloneContents:d,insertNode:C,surroundContents:M,cloneRange:K});function q(V,t){B(D,V,t)}function s(V,t){B(R,V,t)}function g(t){q(t.parentNode,n(t))}function I(t){q(t.parentNode,n(t)+1)}function J(t){s(t.parentNode,n(t))}function u(t){s(t.parentNode,n(t)+1)}function A(t){if(t){N[P]=N[h];N[z]=N[U]}else{N[h]=N[P];N[U]=N[z]}N.collapsed=D}function x(t){g(t);u(t)}function F(t){q(t,0);s(t,t.nodeType===1?t.childNodes.length:t.nodeValue.length)}function v(Y,t){var ab=N[h],W=N[U],aa=N[P],V=N[z],Z=t.startContainer,ad=t.startOffset,X=t.endContainer,ac=t.endOffset;if(Y===0){return G(ab,W,Z,ad)}if(Y===1){return G(aa,V,Z,ad)}if(Y===2){return G(aa,V,X,ac)}if(Y===3){return G(ab,W,X,ac)}}function p(){m(j)}function H(){return m(S)}function d(){return m(E)}function C(Y){var V=this[h],t=this[U],X,W;if((V.nodeType===3||V.nodeType===4)&&V.nodeValue){if(!t){V.parentNode.insertBefore(Y,V)}else{if(t>=V.nodeValue.length){c.insertAfter(Y,V)}else{X=V.splitText(t);V.parentNode.insertBefore(Y,X)}}}else{if(V.childNodes.length>0){W=V.childNodes[t]}if(W){V.insertBefore(Y,W)}else{V.appendChild(Y)}}}function M(V){var t=N.extractContents();N.insertNode(V);V.appendChild(t);N.selectNode(V)}function K(){return k(new b(c),{startContainer:N[h],startOffset:N[U],endContainer:N[P],endOffset:N[z],collapsed:N.collapsed,commonAncestorContainer:N.commonAncestorContainer})}function O(t,V){var W;if(t.nodeType==3){return t}if(V<0){return t}W=t.firstChild;while(W&&V>0){--V;W=W.nextSibling}if(W){return W}return t}function l(){return(N[h]==N[P]&&N[U]==N[z])}function G(X,Z,V,Y){var aa,W,t,ab,ad,ac;if(X==V){if(Z==Y){return 0}if(Z<Y){return -1}return 1}aa=V;while(aa&&aa.parentNode!=X){aa=aa.parentNode}if(aa){W=0;t=X.firstChild;while(t!=aa&&W<Z){W++;t=t.nextSibling}if(Z<=W){return -1}return 1}aa=X;while(aa&&aa.parentNode!=V){aa=aa.parentNode}if(aa){W=0;t=V.firstChild;while(t!=aa&&W<Y){W++;t=t.nextSibling}if(W<Y){return -1}return 1}ab=c.findCommonAncestor(X,V);ad=X;while(ad&&ad.parentNode!=ab){ad=ad.parentNode}if(!ad){ad=ab}ac=V;while(ac&&ac.parentNode!=ab){ac=ac.parentNode}if(!ac){ac=ab}if(ad==ac){return 0}t=ab.firstChild;while(t){if(t==ad){return -1}if(t==ac){return 1}t=t.nextSibling}}function B(V,Y,X){var t,W;if(V){N[h]=Y;N[U]=X}else{N[P]=Y;N[z]=X}t=N[P];while(t.parentNode){t=t.parentNode}W=N[h];while(W.parentNode){W=W.parentNode}if(W==t){if(G(N[h],N[U],N[P],N[z])>0){N.collapse(V)}}else{N.collapse(V)}N.collapsed=l();N.commonAncestorContainer=c.findCommonAncestor(N[h],N[P])}function m(ab){var aa,X=0,ad=0,V,Z,W,Y,t,ac;if(N[h]==N[P]){return f(ab)}for(aa=N[P],V=aa.parentNode;V;aa=V,V=V.parentNode){if(V==N[h]){return r(aa,ab)}++X}for(aa=N[h],V=aa.parentNode;V;aa=V,V=V.parentNode){if(V==N[P]){return T(aa,ab)}++ad}Z=ad-X;W=N[h];while(Z>0){W=W.parentNode;Z--}Y=N[P];while(Z<0){Y=Y.parentNode;Z++}for(t=W.parentNode,ac=Y.parentNode;t!=ac;t=t.parentNode,ac=ac.parentNode){W=t;Y=ac}return o(W,Y,ab)}function f(Z){var ab,Y,X,aa,t,W,V;if(Z!=j){ab=e.createDocumentFragment()}if(N[U]==N[z]){return ab}if(N[h].nodeType==3){Y=N[h].nodeValue;X=Y.substring(N[U],N[z]);if(Z!=E){N[h].deleteData(N[U],N[z]-N[U]);N.collapse(D)}if(Z==j){return}ab.appendChild(e.createTextNode(X));return ab}aa=O(N[h],N[U]);t=N[z]-N[U];while(t>0){W=aa.nextSibling;V=y(aa,Z);if(ab){ab.appendChild(V)}--t;aa=W}if(Z!=E){N.collapse(D)}return ab}function r(ab,Y){var aa,Z,V,t,X,W;if(Y!=j){aa=e.createDocumentFragment()}Z=i(ab,Y);if(aa){aa.appendChild(Z)}V=n(ab);t=V-N[U];if(t<=0){if(Y!=E){N.setEndBefore(ab);N.collapse(R)}return aa}Z=ab.previousSibling;while(t>0){X=Z.previousSibling;W=y(Z,Y);if(aa){aa.insertBefore(W,aa.firstChild)}--t;Z=X}if(Y!=E){N.setEndBefore(ab);N.collapse(R)}return aa}function T(Z,Y){var ab,V,aa,t,X,W;if(Y!=j){ab=e.createDocumentFragment()}aa=Q(Z,Y);if(ab){ab.appendChild(aa)}V=n(Z);++V;t=N[z]-V;aa=Z.nextSibling;while(t>0){X=aa.nextSibling;W=y(aa,Y);if(ab){ab.appendChild(W)}--t;aa=X}if(Y!=E){N.setStartAfter(Z);N.collapse(D)}return ab}function o(Z,t,ac){var W,ae,Y,aa,ab,V,ad,X;if(ac!=j){ae=e.createDocumentFragment()}W=Q(Z,ac);if(ae){ae.appendChild(W)}Y=Z.parentNode;aa=n(Z);ab=n(t);++aa;V=ab-aa;ad=Z.nextSibling;while(V>0){X=ad.nextSibling;W=y(ad,ac);if(ae){ae.appendChild(W)}ad=X;--V}W=i(t,ac);if(ae){ae.appendChild(W)}if(ac!=E){N.setStartAfter(Z);N.collapse(D)}return ae}function i(aa,ab){var W=O(N[P],N[z]-1),ac,Z,Y,t,V,X=W!=N[P];if(W==aa){return L(W,X,R,ab)}ac=W.parentNode;Z=L(ac,R,R,ab);while(ac){while(W){Y=W.previousSibling;t=L(W,X,R,ab);if(ab!=j){Z.insertBefore(t,Z.firstChild)}X=D;W=Y}if(ac==aa){return Z}W=ac.previousSibling;ac=ac.parentNode;V=L(ac,R,R,ab);if(ab!=j){V.appendChild(Z)}Z=V}}function Q(aa,ab){var X=O(N[h],N[U]),Y=X!=N[h],ac,Z,W,t,V;if(X==aa){return L(X,Y,D,ab)}ac=X.parentNode;Z=L(ac,R,D,ab);while(ac){while(X){W=X.nextSibling;t=L(X,Y,D,ab);if(ab!=j){Z.appendChild(t)}Y=D;X=W}if(ac==aa){return Z}X=ac.nextSibling;ac=ac.parentNode;V=L(ac,R,D,ab);if(ab!=j){V.appendChild(Z)}Z=V}}function L(t,Y,ab,ac){var X,W,Z,V,aa;if(Y){return y(t,ac)}if(t.nodeType==3){X=t.nodeValue;if(ab){V=N[U];W=X.substring(V);Z=X.substring(0,V)}else{V=N[z];W=X.substring(0,V);Z=X.substring(V)}if(ac!=E){t.nodeValue=Z}if(ac==j){return}aa=t.cloneNode(R);aa.nodeValue=W;return aa}if(ac==j){return}return t.cloneNode(R)}function y(V,t){if(t!=j){return t==E?V.cloneNode(D):V}V.parentNode.removeChild(V)}}a.Range=b})(tinymce.dom);(function(){function a(d){var b=this,h=d.dom,c=true,f=false;function e(i,j){var k,t=0,q,n,m,l,o,r,p=-1,s;k=i.duplicate();k.collapse(j);s=k.parentElement();if(s.ownerDocument!==d.dom.doc){return}while(s.contentEditable==="false"){s=s.parentNode}if(!s.hasChildNodes()){return{node:s,inside:1}}m=s.children;q=m.length-1;while(t<=q){r=Math.floor((t+q)/2);l=m[r];k.moveToElementText(l);p=k.compareEndPoints(j?"StartToStart":"EndToEnd",i);if(p>0){q=r-1}else{if(p<0){t=r+1}else{return{node:l}}}}if(p<0){if(!l){k.moveToElementText(s);k.collapse(true);l=s;n=true}else{k.collapse(false)}k.setEndPoint(j?"EndToStart":"EndToEnd",i);if(k.compareEndPoints(j?"StartToStart":"StartToEnd",i)>0){k=i.duplicate();k.collapse(j);o=-1;while(s==k.parentElement()){if(k.move("character",-1)==0){break}o++}}o=o||k.text.replace("\r\n"," ").length}else{k.collapse(true);k.setEndPoint(j?"StartToStart":"StartToEnd",i);o=k.text.replace("\r\n"," ").length}return{node:l,position:p,offset:o,inside:n}}function g(){var i=d.getRng(),r=h.createRng(),l,k,p,q,m,j;l=i.item?i.item(0):i.parentElement();if(l.ownerDocument!=h.doc){return r}k=d.isCollapsed();if(i.item){r.setStart(l.parentNode,h.nodeIndex(l));r.setEnd(r.startContainer,r.startOffset+1);return r}function o(A){var u=e(i,A),s,y,z=0,x,v,t;s=u.node;y=u.offset;if(u.inside&&!s.hasChildNodes()){r[A?"setStart":"setEnd"](s,0);return}if(y===v){r[A?"setStartBefore":"setEndAfter"](s);return}if(u.position<0){x=u.inside?s.firstChild:s.nextSibling;if(!x){r[A?"setStartAfter":"setEndAfter"](s);return}if(!y){if(x.nodeType==3){r[A?"setStart":"setEnd"](x,0)}else{r[A?"setStartBefore":"setEndBefore"](x)}return}while(x){t=x.nodeValue;z+=t.length;if(z>=y){s=x;z-=y;z=t.length-z;break}x=x.nextSibling}}else{x=s.previousSibling;if(!x){return r[A?"setStartBefore":"setEndBefore"](s)}if(!y){if(s.nodeType==3){r[A?"setStart":"setEnd"](x,s.nodeValue.length)}else{r[A?"setStartAfter":"setEndAfter"](x)}return}while(x){z+=x.nodeValue.length;if(z>=y){s=x;z-=y;break}x=x.previousSibling}}r[A?"setStart":"setEnd"](s,z)}try{o(true);if(!k){o()}}catch(n){if(n.number==-2147024809){m=b.getBookmark(2);p=i.duplicate();p.collapse(true);l=p.parentElement();if(!k){p=i.duplicate();p.collapse(false);q=p.parentElement();q.innerHTML=q.innerHTML}l.innerHTML=l.innerHTML;b.moveToBookmark(m);i=d.getRng();o(true);if(!k){o()}}else{throw n}}return r}this.getBookmark=function(m){var j=d.getRng(),o,i,l={};function n(u){var u,t,p,s,r,q=[];t=u.parentNode;p=h.getRoot().parentNode;while(t!=p&&t.nodeType!==9){s=t.children;r=s.length;while(r--){if(u===s[r]){q.push(r);break}}u=t;t=t.parentNode}return q}function k(q){var p;p=e(j,q);if(p){return{position:p.position,offset:p.offset,indexes:n(p.node),inside:p.inside}}}if(m===2){if(!j.item){l.start=k(true);if(!d.isCollapsed()){l.end=k()}}else{l.start={ctrl:true,indexes:n(j.item(0))}}}return l};this.moveToBookmark=function(k){var j,i=h.doc.body;function m(o){var r,q,n,p;r=h.getRoot();for(q=o.length-1;q>=0;q--){p=r.children;n=o[q];if(n<=p.length-1){r=p[n]}}return r}function l(r){var n=k[r?"start":"end"],q,p,o;if(n){q=n.position>0;p=i.createTextRange();p.moveToElementText(m(n.indexes));offset=n.offset;if(offset!==o){p.collapse(n.inside||q);p.moveStart("character",q?-offset:offset)}else{p.collapse(r)}j.setEndPoint(r?"StartToStart":"EndToStart",p);if(r){j.collapse(true)}}}if(k.start){if(k.start.ctrl){j=i.createControlRange();j.addElement(m(k.start.indexes));j.select()}else{j=i.createTextRange();l(true);l();j.select()}}};this.addRange=function(i){var n,l,k,p,s,q,r=d.dom.doc,m=r.body;function j(z){var u,y,t,x,v;t=h.create("a");u=z?k:s;y=z?p:q;x=n.duplicate();if(u==r||u==r.documentElement){u=m;y=0}if(u.nodeType==3){u.parentNode.insertBefore(t,u);x.moveToElementText(t);x.moveStart("character",y);h.remove(t);n.setEndPoint(z?"StartToStart":"EndToEnd",x)}else{v=u.childNodes;if(v.length){if(y>=v.length){h.insertAfter(t,v[v.length-1])}else{u.insertBefore(t,v[y])}x.moveToElementText(t)}else{t=r.createTextNode("\uFEFF");u.appendChild(t);x.moveToElementText(t.parentNode);x.collapse(c)}n.setEndPoint(z?"StartToStart":"EndToEnd",x);h.remove(t)}}k=i.startContainer;p=i.startOffset;s=i.endContainer;q=i.endOffset;n=m.createTextRange();if(k==s&&k.nodeType==1&&p==q-1){if(p==q-1){try{l=m.createControlRange();l.addElement(k.childNodes[p]);l.select();return}catch(o){}}}j(true);j();n.select()};this.getRangeAt=g}tinymce.dom.TridentSelection=a})();(function(){var p=/((?:\((?:\([^()]+\)|[^()]+)+\)|\[(?:\[[^\[\]]*\]|['"][^'"]*['"]|[^\[\]'"]+)+\]|\\.|[^ >+~,(\[\\]+)+|[>+~])(\s*,\s*)?((?:.|\r|\n)*)/g,j=0,d=Object.prototype.toString,o=false,i=true;[0,0].sort(function(){i=false;return 0});var b=function(v,e,z,A){z=z||[];e=e||document;var C=e;if(e.nodeType!==1&&e.nodeType!==9){return[]}if(!v||typeof v!=="string"){return z}var x=[],s,E,H,r,u=true,t=b.isXML(e),B=v,D,G,F,y;do{p.exec("");s=p.exec(B);if(s){B=s[3];x.push(s[1]);if(s[2]){r=s[3];break}}}while(s);if(x.length>1&&k.exec(v)){if(x.length===2&&f.relative[x[0]]){E=h(x[0]+x[1],e)}else{E=f.relative[x[0]]?[e]:b(x.shift(),e);while(x.length){v=x.shift();if(f.relative[v]){v+=x.shift()}E=h(v,E)}}}else{if(!A&&x.length>1&&e.nodeType===9&&!t&&f.match.ID.test(x[0])&&!f.match.ID.test(x[x.length-1])){D=b.find(x.shift(),e,t);e=D.expr?b.filter(D.expr,D.set)[0]:D.set[0]}if(e){D=A?{expr:x.pop(),set:a(A)}:b.find(x.pop(),x.length===1&&(x[0]==="~"||x[0]==="+")&&e.parentNode?e.parentNode:e,t);E=D.expr?b.filter(D.expr,D.set):D.set;if(x.length>0){H=a(E)}else{u=false}while(x.length){G=x.pop();F=G;if(!f.relative[G]){G=""}else{F=x.pop()}if(F==null){F=e}f.relative[G](H,F,t)}}else{H=x=[]}}if(!H){H=E}if(!H){b.error(G||v)}if(d.call(H)==="[object Array]"){if(!u){z.push.apply(z,H)}else{if(e&&e.nodeType===1){for(y=0;H[y]!=null;y++){if(H[y]&&(H[y]===true||H[y].nodeType===1&&b.contains(e,H[y]))){z.push(E[y])}}}else{for(y=0;H[y]!=null;y++){if(H[y]&&H[y].nodeType===1){z.push(E[y])}}}}}else{a(H,z)}if(r){b(r,C,z,A);b.uniqueSort(z)}return z};b.uniqueSort=function(r){if(c){o=i;r.sort(c);if(o){for(var e=1;e<r.length;e++){if(r[e]===r[e-1]){r.splice(e--,1)}}}}return r};b.matches=function(e,r){return b(e,null,null,r)};b.find=function(y,e,z){var x;if(!y){return[]}for(var t=0,s=f.order.length;t<s;t++){var v=f.order[t],u;if((u=f.leftMatch[v].exec(y))){var r=u[1];u.splice(1,1);if(r.substr(r.length-1)!=="\\"){u[1]=(u[1]||"").replace(/\\/g,"");x=f.find[v](u,e,z);if(x!=null){y=y.replace(f.match[v],"");break}}}}if(!x){x=e.getElementsByTagName("*")}return{set:x,expr:y}};b.filter=function(C,B,F,u){var s=C,H=[],z=B,x,e,y=B&&B[0]&&b.isXML(B[0]);while(C&&B.length){for(var A in f.filter){if((x=f.leftMatch[A].exec(C))!=null&&x[2]){var r=f.filter[A],G,E,t=x[1];e=false;x.splice(1,1);if(t.substr(t.length-1)==="\\"){continue}if(z===H){H=[]}if(f.preFilter[A]){x=f.preFilter[A](x,z,F,H,u,y);if(!x){e=G=true}else{if(x===true){continue}}}if(x){for(var v=0;(E=z[v])!=null;v++){if(E){G=r(E,x,v,z);var D=u^!!G;if(F&&G!=null){if(D){e=true}else{z[v]=false}}else{if(D){H.push(E);e=true}}}}}if(G!==undefined){if(!F){z=H}C=C.replace(f.match[A],"");if(!e){return[]}break}}}if(C===s){if(e==null){b.error(C)}else{break}}s=C}return z};b.error=function(e){throw"Syntax error, unrecognized expression: "+e};var f=b.selectors={order:["ID","NAME","TAG"],match:{ID:/#((?:[\w\u00c0-\uFFFF\-]|\\.)+)/,CLASS:/\.((?:[\w\u00c0-\uFFFF\-]|\\.)+)/,NAME:/\[name=['"]*((?:[\w\u00c0-\uFFFF\-]|\\.)+)['"]*\]/,ATTR:/\[\s*((?:[\w\u00c0-\uFFFF\-]|\\.)+)\s*(?:(\S?=)\s*(['"]*)(.*?)\3|)\s*\]/,TAG:/^((?:[\w\u00c0-\uFFFF\*\-]|\\.)+)/,CHILD:/:(only|nth|last|first)-child(?:\((even|odd|[\dn+\-]*)\))?/,POS:/:(nth|eq|gt|lt|first|last|even|odd)(?:\((\d*)\))?(?=[^\-]|$)/,PSEUDO:/:((?:[\w\u00c0-\uFFFF\-]|\\.)+)(?:\((['"]?)((?:\([^\)]+\)|[^\(\)]*)+)\2\))?/},leftMatch:{},attrMap:{"class":"className","for":"htmlFor"},attrHandle:{href:function(e){return e.getAttribute("href")}},relative:{"+":function(x,r){var t=typeof r==="string",v=t&&!/\W/.test(r),y=t&&!v;if(v){r=r.toLowerCase()}for(var s=0,e=x.length,u;s<e;s++){if((u=x[s])){while((u=u.previousSibling)&&u.nodeType!==1){}x[s]=y||u&&u.nodeName.toLowerCase()===r?u||false:u===r}}if(y){b.filter(r,x,true)}},">":function(x,r){var u=typeof r==="string",v,s=0,e=x.length;if(u&&!/\W/.test(r)){r=r.toLowerCase();for(;s<e;s++){v=x[s];if(v){var t=v.parentNode;x[s]=t.nodeName.toLowerCase()===r?t:false}}}else{for(;s<e;s++){v=x[s];if(v){x[s]=u?v.parentNode:v.parentNode===r}}if(u){b.filter(r,x,true)}}},"":function(t,r,v){var s=j++,e=q,u;if(typeof r==="string"&&!/\W/.test(r)){r=r.toLowerCase();u=r;e=n}e("parentNode",r,s,t,u,v)},"~":function(t,r,v){var s=j++,e=q,u;if(typeof r==="string"&&!/\W/.test(r)){r=r.toLowerCase();u=r;e=n}e("previousSibling",r,s,t,u,v)}},find:{ID:function(r,s,t){if(typeof s.getElementById!=="undefined"&&!t){var e=s.getElementById(r[1]);return e?[e]:[]}},NAME:function(s,v){if(typeof v.getElementsByName!=="undefined"){var r=[],u=v.getElementsByName(s[1]);for(var t=0,e=u.length;t<e;t++){if(u[t].getAttribute("name")===s[1]){r.push(u[t])}}return r.length===0?null:r}},TAG:function(e,r){return r.getElementsByTagName(e[1])}},preFilter:{CLASS:function(t,r,s,e,x,y){t=" "+t[1].replace(/\\/g,"")+" ";if(y){return t}for(var u=0,v;(v=r[u])!=null;u++){if(v){if(x^(v.className&&(" "+v.className+" ").replace(/[\t\n]/g," ").indexOf(t)>=0)){if(!s){e.push(v)}}else{if(s){r[u]=false}}}}return false},ID:function(e){return e[1].replace(/\\/g,"")},TAG:function(r,e){return r[1].toLowerCase()},CHILD:function(e){if(e[1]==="nth"){var r=/(-?)(\d*)n((?:\+|-)?\d*)/.exec(e[2]==="even"&&"2n"||e[2]==="odd"&&"2n+1"||!/\D/.test(e[2])&&"0n+"+e[2]||e[2]);e[2]=(r[1]+(r[2]||1))-0;e[3]=r[3]-0}e[0]=j++;return e},ATTR:function(u,r,s,e,v,x){var t=u[1].replace(/\\/g,"");if(!x&&f.attrMap[t]){u[1]=f.attrMap[t]}if(u[2]==="~="){u[4]=" "+u[4]+" "}return u},PSEUDO:function(u,r,s,e,v){if(u[1]==="not"){if((p.exec(u[3])||"").length>1||/^\w/.test(u[3])){u[3]=b(u[3],null,null,r)}else{var t=b.filter(u[3],r,s,true^v);if(!s){e.push.apply(e,t)}return false}}else{if(f.match.POS.test(u[0])||f.match.CHILD.test(u[0])){return true}}return u},POS:function(e){e.unshift(true);return e}},filters:{enabled:function(e){return e.disabled===false&&e.type!=="hidden"},disabled:function(e){return e.disabled===true},checked:function(e){return e.checked===true},selected:function(e){e.parentNode.selectedIndex;return e.selected===true},parent:function(e){return !!e.firstChild},empty:function(e){return !e.firstChild},has:function(s,r,e){return !!b(e[3],s).length},header:function(e){return(/h\d/i).test(e.nodeName)},text:function(e){return"text"===e.type},radio:function(e){return"radio"===e.type},checkbox:function(e){return"checkbox"===e.type},file:function(e){return"file"===e.type},password:function(e){return"password"===e.type},submit:function(e){return"submit"===e.type},image:function(e){return"image"===e.type},reset:function(e){return"reset"===e.type},button:function(e){return"button"===e.type||e.nodeName.toLowerCase()==="button"},input:function(e){return(/input|select|textarea|button/i).test(e.nodeName)}},setFilters:{first:function(r,e){return e===0},last:function(s,r,e,t){return r===t.length-1},even:function(r,e){return e%2===0},odd:function(r,e){return e%2===1},lt:function(s,r,e){return r<e[3]-0},gt:function(s,r,e){return r>e[3]-0},nth:function(s,r,e){return e[3]-0===r},eq:function(s,r,e){return e[3]-0===r}},filter:{PSEUDO:function(s,y,x,z){var e=y[1],r=f.filters[e];if(r){return r(s,x,y,z)}else{if(e==="contains"){return(s.textContent||s.innerText||b.getText([s])||"").indexOf(y[3])>=0}else{if(e==="not"){var t=y[3];for(var v=0,u=t.length;v<u;v++){if(t[v]===s){return false}}return true}else{b.error("Syntax error, unrecognized expression: "+e)}}}},CHILD:function(e,t){var x=t[1],r=e;switch(x){case"only":case"first":while((r=r.previousSibling)){if(r.nodeType===1){return false}}if(x==="first"){return true}r=e;case"last":while((r=r.nextSibling)){if(r.nodeType===1){return false}}return true;case"nth":var s=t[2],A=t[3];if(s===1&&A===0){return true}var v=t[0],z=e.parentNode;if(z&&(z.sizcache!==v||!e.nodeIndex)){var u=0;for(r=z.firstChild;r;r=r.nextSibling){if(r.nodeType===1){r.nodeIndex=++u}}z.sizcache=v}var y=e.nodeIndex-A;if(s===0){return y===0}else{return(y%s===0&&y/s>=0)}}},ID:function(r,e){return r.nodeType===1&&r.getAttribute("id")===e},TAG:function(r,e){return(e==="*"&&r.nodeType===1)||r.nodeName.toLowerCase()===e},CLASS:function(r,e){return(" "+(r.className||r.getAttribute("class"))+" ").indexOf(e)>-1},ATTR:function(v,t){var s=t[1],e=f.attrHandle[s]?f.attrHandle[s](v):v[s]!=null?v[s]:v.getAttribute(s),x=e+"",u=t[2],r=t[4];return e==null?u==="!=":u==="="?x===r:u==="*="?x.indexOf(r)>=0:u==="~="?(" "+x+" ").indexOf(r)>=0:!r?x&&e!==false:u==="!="?x!==r:u==="^="?x.indexOf(r)===0:u==="$="?x.substr(x.length-r.length)===r:u==="|="?x===r||x.substr(0,r.length+1)===r+"-":false},POS:function(u,r,s,v){var e=r[2],t=f.setFilters[e];if(t){return t(u,s,r,v)}}}};var k=f.match.POS,g=function(r,e){return"\\"+(e-0+1)};for(var m in f.match){f.match[m]=new RegExp(f.match[m].source+(/(?![^\[]*\])(?![^\(]*\))/.source));f.leftMatch[m]=new RegExp(/(^(?:.|\r|\n)*?)/.source+f.match[m].source.replace(/\\(\d+)/g,g))}var a=function(r,e){r=Array.prototype.slice.call(r,0);if(e){e.push.apply(e,r);return e}return r};try{Array.prototype.slice.call(document.documentElement.childNodes,0)[0].nodeType}catch(l){a=function(u,t){var r=t||[],s=0;if(d.call(u)==="[object Array]"){Array.prototype.push.apply(r,u)}else{if(typeof u.length==="number"){for(var e=u.length;s<e;s++){r.push(u[s])}}else{for(;u[s];s++){r.push(u[s])}}}return r}}var c;if(document.documentElement.compareDocumentPosition){c=function(r,e){if(!r.compareDocumentPosition||!e.compareDocumentPosition){if(r==e){o=true}return r.compareDocumentPosition?-1:1}var s=r.compareDocumentPosition(e)&4?-1:r===e?0:1;if(s===0){o=true}return s}}else{if("sourceIndex" in document.documentElement){c=function(r,e){if(!r.sourceIndex||!e.sourceIndex){if(r==e){o=true}return r.sourceIndex?-1:1}var s=r.sourceIndex-e.sourceIndex;if(s===0){o=true}return s}}else{if(document.createRange){c=function(t,r){if(!t.ownerDocument||!r.ownerDocument){if(t==r){o=true}return t.ownerDocument?-1:1}var s=t.ownerDocument.createRange(),e=r.ownerDocument.createRange();s.setStart(t,0);s.setEnd(t,0);e.setStart(r,0);e.setEnd(r,0);var u=s.compareBoundaryPoints(Range.START_TO_END,e);if(u===0){o=true}return u}}}}b.getText=function(e){var r="",t;for(var s=0;e[s];s++){t=e[s];if(t.nodeType===3||t.nodeType===4){r+=t.nodeValue}else{if(t.nodeType!==8){r+=b.getText(t.childNodes)}}}return r};(function(){var r=document.createElement("div"),s="script"+(new Date()).getTime();r.innerHTML="<a name='"+s+"'/>";var e=document.documentElement;e.insertBefore(r,e.firstChild);if(document.getElementById(s)){f.find.ID=function(u,v,x){if(typeof v.getElementById!=="undefined"&&!x){var t=v.getElementById(u[1]);return t?t.id===u[1]||typeof t.getAttributeNode!=="undefined"&&t.getAttributeNode("id").nodeValue===u[1]?[t]:undefined:[]}};f.filter.ID=function(v,t){var u=typeof v.getAttributeNode!=="undefined"&&v.getAttributeNode("id");return v.nodeType===1&&u&&u.nodeValue===t}}e.removeChild(r);e=r=null})();(function(){var e=document.createElement("div");e.appendChild(document.createComment(""));if(e.getElementsByTagName("*").length>0){f.find.TAG=function(r,v){var u=v.getElementsByTagName(r[1]);if(r[1]==="*"){var t=[];for(var s=0;u[s];s++){if(u[s].nodeType===1){t.push(u[s])}}u=t}return u}}e.innerHTML="<a href='#'></a>";if(e.firstChild&&typeof e.firstChild.getAttribute!=="undefined"&&e.firstChild.getAttribute("href")!=="#"){f.attrHandle.href=function(r){return r.getAttribute("href",2)}}e=null})();if(document.querySelectorAll){(function(){var e=b,s=document.createElement("div");s.innerHTML="<p class='TEST'></p>";if(s.querySelectorAll&&s.querySelectorAll(".TEST").length===0){return}b=function(x,v,t,u){v=v||document;if(!u&&v.nodeType===9&&!b.isXML(v)){try{return a(v.querySelectorAll(x),t)}catch(y){}}return e(x,v,t,u)};for(var r in e){b[r]=e[r]}s=null})()}(function(){var e=document.createElement("div");e.innerHTML="<div class='test e'></div><div class='test'></div>";if(!e.getElementsByClassName||e.getElementsByClassName("e").length===0){return}e.lastChild.className="e";if(e.getElementsByClassName("e").length===1){return}f.order.splice(1,0,"CLASS");f.find.CLASS=function(r,s,t){if(typeof s.getElementsByClassName!=="undefined"&&!t){return s.getElementsByClassName(r[1])}};e=null})();function n(r,x,v,A,y,z){for(var t=0,s=A.length;t<s;t++){var e=A[t];if(e){e=e[r];var u=false;while(e){if(e.sizcache===v){u=A[e.sizset];break}if(e.nodeType===1&&!z){e.sizcache=v;e.sizset=t}if(e.nodeName.toLowerCase()===x){u=e;break}e=e[r]}A[t]=u}}}function q(r,x,v,A,y,z){for(var t=0,s=A.length;t<s;t++){var e=A[t];if(e){e=e[r];var u=false;while(e){if(e.sizcache===v){u=A[e.sizset];break}if(e.nodeType===1){if(!z){e.sizcache=v;e.sizset=t}if(typeof x!=="string"){if(e===x){u=true;break}}else{if(b.filter(x,[e]).length>0){u=e;break}}}e=e[r]}A[t]=u}}}b.contains=document.compareDocumentPosition?function(r,e){return !!(r.compareDocumentPosition(e)&16)}:function(r,e){return r!==e&&(r.contains?r.contains(e):true)};b.isXML=function(e){var r=(e?e.ownerDocument||e:0).documentElement;return r?r.nodeName!=="HTML":false};var h=function(e,y){var t=[],u="",v,s=y.nodeType?[y]:y;while((v=f.match.PSEUDO.exec(e))){u+=v[0];e=e.replace(f.match.PSEUDO,"")}e=f.relative[e]?e+"*":e;for(var x=0,r=s.length;x<r;x++){b(e,s[x],t)}return b.filter(u,t)};window.tinymce.dom.Sizzle=b})();(function(d){var f=d.each,c=d.DOM,b=d.isIE,e=d.isWebKit,a;d.create("tinymce.dom.EventUtils",{EventUtils:function(){this.inits=[];this.events=[]},add:function(m,p,l,j){var g,h=this,i=h.events,k;if(p instanceof Array){k=[];f(p,function(o){k.push(h.add(m,o,l,j))});return k}if(m&&m.hasOwnProperty&&m instanceof Array){k=[];f(m,function(n){n=c.get(n);k.push(h.add(n,p,l,j))});return k}m=c.get(m);if(!m){return}g=function(n){if(h.disabled){return}n=n||window.event;if(n&&b){if(!n.target){n.target=n.srcElement}d.extend(n,h._stoppers)}if(!j){return l(n)}return l.call(j,n)};if(p=="unload"){d.unloads.unshift({func:g});return g}if(p=="init"){if(h.domLoaded){g()}else{h.inits.push(g)}return g}i.push({obj:m,name:p,func:l,cfunc:g,scope:j});h._add(m,p,g);return l},remove:function(l,m,k){var h=this,g=h.events,i=false,j;if(l&&l.hasOwnProperty&&l instanceof Array){j=[];f(l,function(n){n=c.get(n);j.push(h.remove(n,m,k))});return j}l=c.get(l);f(g,function(o,n){if(o.obj==l&&o.name==m&&(!k||(o.func==k||o.cfunc==k))){g.splice(n,1);h._remove(l,m,o.cfunc);i=true;return false}});return i},clear:function(l){var j=this,g=j.events,h,k;if(l){l=c.get(l);for(h=g.length-1;h>=0;h--){k=g[h];if(k.obj===l){j._remove(k.obj,k.name,k.cfunc);k.obj=k.cfunc=null;g.splice(h,1)}}}},cancel:function(g){if(!g){return false}this.stop(g);return this.prevent(g)},stop:function(g){if(g.stopPropagation){g.stopPropagation()}else{g.cancelBubble=true}return false},prevent:function(g){if(g.preventDefault){g.preventDefault()}else{g.returnValue=false}return false},destroy:function(){var g=this;f(g.events,function(j,h){g._remove(j.obj,j.name,j.cfunc);j.obj=j.cfunc=null});g.events=[];g=null},_add:function(h,i,g){if(h.attachEvent){h.attachEvent("on"+i,g)}else{if(h.addEventListener){h.addEventListener(i,g,false)}else{h["on"+i]=g}}},_remove:function(i,j,h){if(i){try{if(i.detachEvent){i.detachEvent("on"+j,h)}else{if(i.removeEventListener){i.removeEventListener(j,h,false)}else{i["on"+j]=null}}}catch(g){}}},_pageInit:function(h){var g=this;if(g.domLoaded){return}g.domLoaded=true;f(g.inits,function(i){i()});g.inits=[]},_wait:function(i){var g=this,h=i.document;if(i.tinyMCE_GZ&&tinyMCE_GZ.loaded){g.domLoaded=1;return}if(h.attachEvent){h.attachEvent("onreadystatechange",function(){if(h.readyState==="complete"){h.detachEvent("onreadystatechange",arguments.callee);g._pageInit(i)}});if(h.documentElement.doScroll&&i==i.top){(function(){if(g.domLoaded){return}try{h.documentElement.doScroll("left")}catch(j){setTimeout(arguments.callee,0);return}g._pageInit(i)})()}}else{if(h.addEventListener){g._add(i,"DOMContentLoaded",function(){g._pageInit(i)})}}g._add(i,"load",function(){g._pageInit(i)})},_stoppers:{preventDefault:function(){this.returnValue=false},stopPropagation:function(){this.cancelBubble=true}}});a=d.dom.Event=new d.dom.EventUtils();a._wait(window);d.addUnload(function(){a.destroy()})})(tinymce);(function(a){a.dom.Element=function(f,d){var b=this,e,c;b.settings=d=d||{};b.id=f;b.dom=e=d.dom||a.DOM;if(!a.isIE){c=e.get(b.id)}a.each(("getPos,getRect,getParent,add,setStyle,getStyle,setStyles,setAttrib,setAttribs,getAttrib,addClass,removeClass,hasClass,getOuterHTML,setOuterHTML,remove,show,hide,isHidden,setHTML,get").split(/,/),function(g){b[g]=function(){var h=[f],j;for(j=0;j<arguments.length;j++){h.push(arguments[j])}h=e[g].apply(e,h);b.update(g);return h}});a.extend(b,{on:function(i,h,g){return a.dom.Event.add(b.id,i,h,g)},getXY:function(){return{x:parseInt(b.getStyle("left")),y:parseInt(b.getStyle("top"))}},getSize:function(){var g=e.get(b.id);return{w:parseInt(b.getStyle("width")||g.clientWidth),h:parseInt(b.getStyle("height")||g.clientHeight)}},moveTo:function(g,h){b.setStyles({left:g,top:h})},moveBy:function(g,i){var h=b.getXY();b.moveTo(h.x+g,h.y+i)},resizeTo:function(g,i){b.setStyles({width:g,height:i})},resizeBy:function(g,j){var i=b.getSize();b.resizeTo(i.w+g,i.h+j)},update:function(h){var g;if(a.isIE6&&d.blocker){h=h||"";if(h.indexOf("get")===0||h.indexOf("has")===0||h.indexOf("is")===0){return}if(h=="remove"){e.remove(b.blocker);return}if(!b.blocker){b.blocker=e.uniqueId();g=e.add(d.container||e.getRoot(),"iframe",{id:b.blocker,style:"position:absolute;",frameBorder:0,src:'javascript:""'});e.setStyle(g,"opacity",0)}else{g=e.get(b.blocker)}e.setStyles(g,{left:b.getStyle("left",1),top:b.getStyle("top",1),width:b.getStyle("width",1),height:b.getStyle("height",1),display:b.getStyle("display",1),zIndex:parseInt(b.getStyle("zIndex",1)||0)-1})}}})}})(tinymce);(function(c){function e(f){return f.replace(/[\n\r]+/g,"")}var b=c.is,a=c.isIE,d=c.each;c.create("tinymce.dom.Selection",{Selection:function(i,h,g){var f=this;f.dom=i;f.win=h;f.serializer=g;d(["onBeforeSetContent","onBeforeGetContent","onSetContent","onGetContent"],function(j){f[j]=new c.util.Dispatcher(f)});if(!f.win.getSelection){f.tridentSel=new c.dom.TridentSelection(f)}if(c.isIE&&i.boxModel){this._fixIESelection()}c.addUnload(f.destroy,f)},setCursorLocation:function(h,i){var f=this;var g=f.dom.createRng();g.setStart(h,i);g.setEnd(h,i);f.setRng(g);f.collapse(false)},getContent:function(g){var f=this,h=f.getRng(),l=f.dom.create("body"),j=f.getSel(),i,k,m;g=g||{};i=k="";g.get=true;g.format=g.format||"html";g.forced_root_block="";f.onBeforeGetContent.dispatch(f,g);if(g.format=="text"){return f.isCollapsed()?"":(h.text||(j.toString?j.toString():""))}if(h.cloneContents){m=h.cloneContents();if(m){l.appendChild(m)}}else{if(b(h.item)||b(h.htmlText)){l.innerHTML="<br>"+(h.item?h.item(0).outerHTML:h.htmlText);l.removeChild(l.firstChild)}else{l.innerHTML=h.toString()}}if(/^\s/.test(l.innerHTML)){i=" "}if(/\s+$/.test(l.innerHTML)){k=" "}g.getInner=true;g.content=f.isCollapsed()?"":i+f.serializer.serialize(l,g)+k;f.onGetContent.dispatch(f,g);return g.content},setContent:function(g,i){var n=this,f=n.getRng(),j,k=n.win.document,m,l;i=i||{format:"html"};i.set=true;g=i.content=g;if(!i.no_events){n.onBeforeSetContent.dispatch(n,i)}g=i.content;if(f.insertNode){g+='<span id="__caret">_</span>';if(f.startContainer==k&&f.endContainer==k){k.body.innerHTML=g}else{f.deleteContents();if(k.body.childNodes.length==0){k.body.innerHTML=g}else{if(f.createContextualFragment){f.insertNode(f.createContextualFragment(g))}else{m=k.createDocumentFragment();l=k.createElement("div");m.appendChild(l);l.outerHTML=g;f.insertNode(m)}}}j=n.dom.get("__caret");f=k.createRange();f.setStartBefore(j);f.setEndBefore(j);n.setRng(f);n.dom.remove("__caret");try{n.setRng(f)}catch(h){}}else{if(f.item){k.execCommand("Delete",false,null);f=n.getRng()}if(/^\s+/.test(g)){f.pasteHTML('<span id="__mce_tmp">_</span>'+g);n.dom.remove("__mce_tmp")}else{f.pasteHTML(g)}}if(!i.no_events){n.onSetContent.dispatch(n,i)}},getStart:function(){var g=this.getRng(),h,f,j,i;if(g.duplicate||g.item){if(g.item){return g.item(0)}j=g.duplicate();j.collapse(1);h=j.parentElement();f=i=g.parentElement();while(i=i.parentNode){if(i==h){h=f;break}}return h}else{h=g.startContainer;if(h.nodeType==1&&h.hasChildNodes()){h=h.childNodes[Math.min(h.childNodes.length-1,g.startOffset)]}if(h&&h.nodeType==3){return h.parentNode}return h}},getEnd:function(){var g=this,h=g.getRng(),i,f;if(h.duplicate||h.item){if(h.item){return h.item(0)}h=h.duplicate();h.collapse(0);i=h.parentElement();if(i&&i.nodeName=="BODY"){return i.lastChild||i}return i}else{i=h.endContainer;f=h.endOffset;if(i.nodeType==1&&i.hasChildNodes()){i=i.childNodes[f>0?f-1:f]}if(i&&i.nodeType==3){return i.parentNode}return i}},getBookmark:function(r,s){var v=this,m=v.dom,g,j,i,n,h,o,p,l="\uFEFF",u;function f(x,y){var t=0;d(m.select(x),function(A,z){if(A==y){t=z}});return t}if(r==2){function k(){var x=v.getRng(true),t=m.getRoot(),y={};function z(C,H){var B=C[H?"startContainer":"endContainer"],G=C[H?"startOffset":"endOffset"],A=[],D,F,E=0;if(B.nodeType==3){if(s){for(D=B.previousSibling;D&&D.nodeType==3;D=D.previousSibling){G+=D.nodeValue.length}}A.push(G)}else{F=B.childNodes;if(G>=F.length&&F.length){E=1;G=Math.max(0,F.length-1)}A.push(v.dom.nodeIndex(F[G],s)+E)}for(;B&&B!=t;B=B.parentNode){A.push(v.dom.nodeIndex(B,s))}return A}y.start=z(x,true);if(!v.isCollapsed()){y.end=z(x)}return y}if(v.tridentSel){return v.tridentSel.getBookmark(r)}return k()}if(r){return{rng:v.getRng()}}g=v.getRng();i=m.uniqueId();n=tinyMCE.activeEditor.selection.isCollapsed();u="overflow:hidden;line-height:0px";if(g.duplicate||g.item){if(!g.item){j=g.duplicate();try{g.collapse();g.pasteHTML('<span data-mce-type="bookmark" id="'+i+'_start" style="'+u+'">'+l+"</span>");if(!n){j.collapse(false);g.moveToElementText(j.parentElement());if(g.compareEndPoints("StartToEnd",j)==0){j.move("character",-1)}j.pasteHTML('<span data-mce-type="bookmark" id="'+i+'_end" style="'+u+'">'+l+"</span>")}}catch(q){return null}}else{o=g.item(0);h=o.nodeName;return{name:h,index:f(h,o)}}}else{o=v.getNode();h=o.nodeName;if(h=="IMG"){return{name:h,index:f(h,o)}}j=g.cloneRange();if(!n){j.collapse(false);j.insertNode(m.create("span",{"data-mce-type":"bookmark",id:i+"_end",style:u},l))}g.collapse(true);g.insertNode(m.create("span",{"data-mce-type":"bookmark",id:i+"_start",style:u},l))}v.moveToBookmark({id:i,keep:1});return{id:i}},moveToBookmark:function(n){var r=this,l=r.dom,i,h,f,q,j,s,o,p;if(n){if(n.start){f=l.createRng();q=l.getRoot();function g(z){var t=n[z?"start":"end"],v,x,y,u;if(t){y=t[0];for(x=q,v=t.length-1;v>=1;v--){u=x.childNodes;if(t[v]>u.length-1){return}x=u[t[v]]}if(x.nodeType===3){y=Math.min(t[0],x.nodeValue.length)}if(x.nodeType===1){y=Math.min(t[0],x.childNodes.length)}if(z){f.setStart(x,y)}else{f.setEnd(x,y)}}return true}if(r.tridentSel){return r.tridentSel.moveToBookmark(n)}if(g(true)&&g()){r.setRng(f)}}else{if(n.id){function k(A){var u=l.get(n.id+"_"+A),z,t,x,y,v=n.keep;if(u){z=u.parentNode;if(A=="start"){if(!v){t=l.nodeIndex(u)}else{z=u.firstChild;t=1}j=s=z;o=p=t}else{if(!v){t=l.nodeIndex(u)}else{z=u.firstChild;t=1}s=z;p=t}if(!v){y=u.previousSibling;x=u.nextSibling;d(c.grep(u.childNodes),function(B){if(B.nodeType==3){B.nodeValue=B.nodeValue.replace(/\uFEFF/g,"")}});while(u=l.get(n.id+"_"+A)){l.remove(u,1)}if(y&&x&&y.nodeType==x.nodeType&&y.nodeType==3&&!c.isOpera){t=y.nodeValue.length;y.appendData(x.nodeValue);l.remove(x);if(A=="start"){j=s=y;o=p=t}else{s=y;p=t}}}}}function m(t){if(l.isBlock(t)&&!t.innerHTML){t.innerHTML=!a?'<br data-mce-bogus="1" />':" "}return t}k("start");k("end");if(j){f=l.createRng();f.setStart(m(j),o);f.setEnd(m(s),p);r.setRng(f)}}else{if(n.name){r.select(l.select(n.name)[n.index])}else{if(n.rng){r.setRng(n.rng)}}}}}},select:function(k,j){var i=this,l=i.dom,g=l.createRng(),f;if(k){f=l.nodeIndex(k);g.setStart(k.parentNode,f);g.setEnd(k.parentNode,f+1);if(j){function h(m,o){var n=new c.dom.TreeWalker(m,m);do{if(m.nodeType==3&&c.trim(m.nodeValue).length!=0){if(o){g.setStart(m,0)}else{g.setEnd(m,m.nodeValue.length)}return}if(m.nodeName=="BR"){if(o){g.setStartBefore(m)}else{g.setEndBefore(m)}return}}while(m=(o?n.next():n.prev()))}h(k,1);h(k)}i.setRng(g)}return k},isCollapsed:function(){var f=this,h=f.getRng(),g=f.getSel();if(!h||h.item){return false}if(h.compareEndPoints){return h.compareEndPoints("StartToEnd",h)===0}return !g||h.collapsed},collapse:function(f){var h=this,g=h.getRng(),i;if(g.item){i=g.item(0);g=h.win.document.body.createTextRange();g.moveToElementText(i)}g.collapse(!!f);h.setRng(g)},getSel:function(){var g=this,f=this.win;return f.getSelection?f.getSelection():f.document.selection},getRng:function(l){var g=this,h,i,k,j=g.win.document;if(l&&g.tridentSel){return g.tridentSel.getRangeAt(0)}try{if(h=g.getSel()){i=h.rangeCount>0?h.getRangeAt(0):(h.createRange?h.createRange():j.createRange())}}catch(f){}if(c.isIE&&i&&i.setStart&&j.selection.createRange().item){k=j.selection.createRange().item(0);i=j.createRange();i.setStartBefore(k);i.setEndAfter(k)}if(!i){i=j.createRange?j.createRange():j.body.createTextRange()}if(g.selectedRange&&g.explicitRange){if(i.compareBoundaryPoints(i.START_TO_START,g.selectedRange)===0&&i.compareBoundaryPoints(i.END_TO_END,g.selectedRange)===0){i=g.explicitRange}else{g.selectedRange=null;g.explicitRange=null}}return i},setRng:function(i){var h,g=this;if(!g.tridentSel){h=g.getSel();if(h){g.explicitRange=i;try{h.removeAllRanges()}catch(f){}h.addRange(i);g.selectedRange=h.rangeCount>0?h.getRangeAt(0):null}}else{if(i.cloneRange){g.tridentSel.addRange(i);return}try{i.select()}catch(f){}}},setNode:function(g){var f=this;f.setContent(f.dom.getOuterHTML(g));return g},getNode:function(){var h=this,g=h.getRng(),i=h.getSel(),l,k=g.startContainer,f=g.endContainer;if(!g){return h.dom.getRoot()}if(g.setStart){l=g.commonAncestorContainer;if(!g.collapsed){if(g.startContainer==g.endContainer){if(g.endOffset-g.startOffset<2){if(g.startContainer.hasChildNodes()){l=g.startContainer.childNodes[g.startOffset]}}}if(k.nodeType===3&&f.nodeType===3){function j(p,m){var o=p;while(p&&p.nodeType===3&&p.length===0){p=m?p.nextSibling:p.previousSibling}return p||o}if(k.length===g.startOffset){k=j(k.nextSibling,true)}else{k=k.parentNode}if(g.endOffset===0){f=j(f.previousSibling,false)}else{f=f.parentNode}if(k&&k===f){return k}}}if(l&&l.nodeType==3){return l.parentNode}return l}return g.item?g.item(0):g.parentElement()},getSelectedBlocks:function(o,g){var m=this,j=m.dom,l,k,h,i=[];l=j.getParent(o||m.getStart(),j.isBlock);k=j.getParent(g||m.getEnd(),j.isBlock);if(l){i.push(l)}if(l&&k&&l!=k){h=l;var f=new c.dom.TreeWalker(l,j.getRoot());while((h=f.next())&&h!=k){if(j.isBlock(h)){i.push(h)}}}if(k&&l!=k){i.push(k)}return i},normalize:function(){var g=this,f,i;if(c.isIE){return}function h(p){var k,o,n,m=g.dom,j=m.getRoot(),l;k=f[(p?"start":"end")+"Container"];o=f[(p?"start":"end")+"Offset"];if(k.nodeType===9){k=k.body;o=0}if(k===j){if(k.hasChildNodes()){k=k.childNodes[Math.min(!p&&o>0?o-1:o,k.childNodes.length-1)];o=0;if(k.hasChildNodes()){l=k;n=new c.dom.TreeWalker(k,j);do{if(l.nodeType===3){o=p?0:l.nodeValue.length-1;k=l;i=true;break}if(/^(BR|IMG)$/.test(l.nodeName)){o=m.nodeIndex(l);k=l.parentNode;if(l.nodeName=="IMG"&&!p){o++}i=true;break}}while(l=(p?n.next():n.prev()))}}}if(i){f["set"+(p?"Start":"End")](k,o)}}f=g.getRng();h(true);if(!f.collapsed){h()}if(i){g.setRng(f)}},destroy:function(g){var f=this;f.win=null;if(!g){c.removeUnload(f.destroy)}},_fixIESelection:function(){var g=this.dom,m=g.doc,h=m.body,j,n,f;m.documentElement.unselectable=true;function i(o,r){var p=h.createTextRange();try{p.moveToPoint(o,r)}catch(q){p=null}return p}function l(p){var o;if(p.button){o=i(p.x,p.y);if(o){if(o.compareEndPoints("StartToStart",n)>0){o.setEndPoint("StartToStart",n)}else{o.setEndPoint("EndToEnd",n)}o.select()}}else{k()}}function k(){var o=m.selection.createRange();if(n&&!o.item&&o.compareEndPoints("StartToEnd",o)===0){n.select()}g.unbind(m,"mouseup",k);g.unbind(m,"mousemove",l);n=j=0}g.bind(m,["mousedown","contextmenu"],function(o){if(o.target.nodeName==="HTML"){if(j){k()}f=m.documentElement;if(f.scrollHeight>f.clientHeight){return}j=1;n=i(o.x,o.y);if(n){g.bind(m,"mouseup",k);g.bind(m,"mousemove",l);g.win.focus();n.select()}}})}})})(tinymce);(function(a){a.dom.Serializer=function(e,i,f){var h,b,d=a.isIE,g=a.each,c;if(!e.apply_source_formatting){e.indent=false}i=i||a.DOM;f=f||new a.html.Schema(e);e.entity_encoding=e.entity_encoding||"named";e.remove_trailing_brs="remove_trailing_brs" in e?e.remove_trailing_brs:true;h=new a.util.Dispatcher(self);b=new a.util.Dispatcher(self);c=new a.html.DomParser(e,f);c.addAttributeFilter("src,href,style",function(k,j){var o=k.length,l,q,n="data-mce-"+j,p=e.url_converter,r=e.url_converter_scope,m;while(o--){l=k[o];q=l.attributes.map[n];if(q!==m){l.attr(j,q.length>0?q:null);l.attr(n,null)}else{q=l.attributes.map[j];if(j==="style"){q=i.serializeStyle(i.parseStyle(q),l.name)}else{if(p){q=p.call(r,q,j,l.name)}}l.attr(j,q.length>0?q:null)}}});c.addAttributeFilter("class",function(j,k){var l=j.length,m,n;while(l--){m=j[l];n=m.attr("class").replace(/\s*mce(Item\w+|Selected)\s*/g,"");m.attr("class",n.length>0?n:null)}});c.addAttributeFilter("data-mce-type",function(j,l,k){var m=j.length,n;while(m--){n=j[m];if(n.attributes.map["data-mce-type"]==="bookmark"&&!k.cleanup){n.remove()}}});c.addNodeFilter("script,style",function(k,l){var m=k.length,n,o;function j(p){return p.replace(/(<!--\[CDATA\[|\]\]-->)/g,"\n").replace(/^[\r\n]*|[\r\n]*$/g,"").replace(/^\s*((<!--)?(\s*\/\/)?\s*<!\[CDATA\[|(<!--\s*)?\/\*\s*<!\[CDATA\[\s*\*\/|(\/\/)?\s*<!--|\/\*\s*<!--\s*\*\/)\s*[\r\n]*/gi,"").replace(/\s*(\/\*\s*\]\]>\s*\*\/(-->)?|\s*\/\/\s*\]\]>(-->)?|\/\/\s*(-->)?|\]\]>|\/\*\s*-->\s*\*\/|\s*-->\s*)\s*$/g,"")}while(m--){n=k[m];o=n.firstChild?n.firstChild.value:"";if(l==="script"){n.attr("type",(n.attr("type")||"text/javascript").replace(/^mce\-/,""));if(o.length>0){n.firstChild.value="// <![CDATA[\n"+j(o)+"\n// ]]>"}}else{if(o.length>0){n.firstChild.value="<!--\n"+j(o)+"\n-->"}}}});c.addNodeFilter("#comment",function(j,k){var l=j.length,m;while(l--){m=j[l];if(m.value.indexOf("[CDATA[")===0){m.name="#cdata";m.type=4;m.value=m.value.replace(/^\[CDATA\[|\]\]$/g,"")}else{if(m.value.indexOf("mce:protected ")===0){m.name="#text";m.type=3;m.raw=true;m.value=unescape(m.value).substr(14)}}}});c.addNodeFilter("xml:namespace,input",function(j,k){var l=j.length,m;while(l--){m=j[l];if(m.type===7){m.remove()}else{if(m.type===1){if(k==="input"&&!("type" in m.attributes.map)){m.attr("type","text")}}}}});if(e.fix_list_elements){c.addNodeFilter("ul,ol",function(k,l){var m=k.length,n,j;while(m--){n=k[m];j=n.parent;if(j.name==="ul"||j.name==="ol"){if(n.prev&&n.prev.name==="li"){n.prev.append(n)}}}})}c.addAttributeFilter("data-mce-src,data-mce-href,data-mce-style",function(j,k){var l=j.length;while(l--){j[l].attr(k,null)}});return{schema:f,addNodeFilter:c.addNodeFilter,addAttributeFilter:c.addAttributeFilter,onPreProcess:h,onPostProcess:b,serialize:function(o,m){var l,p,k,j,n;if(d&&i.select("script,style,select,map").length>0){n=o.innerHTML;o=o.cloneNode(false);i.setHTML(o,n)}else{o=o.cloneNode(true)}l=o.ownerDocument.implementation;if(l.createHTMLDocument){p=l.createHTMLDocument("");g(o.nodeName=="BODY"?o.childNodes:[o],function(q){p.body.appendChild(p.importNode(q,true))});if(o.nodeName!="BODY"){o=p.body.firstChild}else{o=p.body}k=i.doc;i.doc=p}m=m||{};m.format=m.format||"html";if(!m.no_events){m.node=o;h.dispatch(self,m)}j=new a.html.Serializer(e,f);m.content=j.serialize(c.parse(m.getInner?o.innerHTML:a.trim(i.getOuterHTML(o),m),m));if(!m.cleanup){m.content=m.content.replace(/\uFEFF|\u200B/g,"")}if(!m.no_events){b.dispatch(self,m)}if(k){i.doc=k}m.node=null;return m.content},addRules:function(j){f.addValidElements(j)},setRules:function(j){f.setValidElements(j)}}}})(tinymce);(function(a){a.dom.ScriptLoader=function(h){var c=0,k=1,i=2,l={},j=[],f={},d=[],g=0,e;function b(m,v){var x=this,q=a.DOM,s,o,r,n;function p(){q.remove(n);if(s){s.onreadystatechange=s.onload=s=null}v()}function u(){if(typeof(console)!=="undefined"&&console.log){console.log("Failed to load: "+m)}}n=q.uniqueId();if(a.isIE6){o=new a.util.URI(m);r=location;if(o.host==r.hostname&&o.port==r.port&&(o.protocol+":")==r.protocol&&o.protocol.toLowerCase()!="file"){a.util.XHR.send({url:a._addVer(o.getURI()),success:function(y){var t=q.create("script",{type:"text/javascript"});t.text=y;document.getElementsByTagName("head")[0].appendChild(t);q.remove(t);p()},error:u});return}}s=q.create("script",{id:n,type:"text/javascript",src:a._addVer(m)});if(!a.isIE){s.onload=p}s.onerror=u;if(!a.isOpera){s.onreadystatechange=function(){var t=s.readyState;if(t=="complete"||t=="loaded"){p()}}}(document.getElementsByTagName("head")[0]||document.body).appendChild(s)}this.isDone=function(m){return l[m]==i};this.markDone=function(m){l[m]=i};this.add=this.load=function(m,q,n){var o,p=l[m];if(p==e){j.push(m);l[m]=c}if(q){if(!f[m]){f[m]=[]}f[m].push({func:q,scope:n||this})}};this.loadQueue=function(n,m){this.loadScripts(j,n,m)};this.loadScripts=function(m,q,p){var o;function n(r){a.each(f[r],function(s){s.func.call(s.scope)});f[r]=e}d.push({func:q,scope:p||this});o=function(){var r=a.grep(m);m.length=0;a.each(r,function(s){if(l[s]==i){n(s);return}if(l[s]!=k){l[s]=k;g++;b(s,function(){l[s]=i;g--;n(s);o()})}});if(!g){a.each(d,function(s){s.func.call(s.scope)});d.length=0}};o()}};a.ScriptLoader=new a.dom.ScriptLoader()})(tinymce);tinymce.dom.TreeWalker=function(a,c){var b=a;function d(i,f,e,j){var h,g;if(i){if(!j&&i[f]){return i[f]}if(i!=c){h=i[e];if(h){return h}for(g=i.parentNode;g&&g!=c;g=g.parentNode){h=g[e];if(h){return h}}}}}this.current=function(){return b};this.next=function(e){return(b=d(b,"firstChild","nextSibling",e))};this.prev=function(e){return(b=d(b,"lastChild","previousSibling",e))}};(function(a){a.dom.RangeUtils=function(c){var b="\uFEFF";this.walk=function(d,s){var i=d.startContainer,l=d.startOffset,t=d.endContainer,m=d.endOffset,j,g,o,h,r,q,e;e=c.select("td.mceSelected,th.mceSelected");if(e.length>0){a.each(e,function(u){s([u])});return}function f(u){var v;v=u[0];if(v.nodeType===3&&v===i&&l>=v.nodeValue.length){u.splice(0,1)}v=u[u.length-1];if(m===0&&u.length>0&&v===t&&v.nodeType===3){u.splice(u.length-1,1)}return u}function p(x,v,u){var y=[];for(;x&&x!=u;x=x[v]){y.push(x)}return y}function n(v,u){do{if(v.parentNode==u){return v}v=v.parentNode}while(v)}function k(x,v,y){var u=y?"nextSibling":"previousSibling";for(h=x,r=h.parentNode;h&&h!=v;h=r){r=h.parentNode;q=p(h==x?h:h[u],u);if(q.length){if(!y){q.reverse()}s(f(q))}}}if(i.nodeType==1&&i.hasChildNodes()){i=i.childNodes[l]}if(t.nodeType==1&&t.hasChildNodes()){t=t.childNodes[Math.min(m-1,t.childNodes.length-1)]}if(i==t){return s(f([i]))}j=c.findCommonAncestor(i,t);for(h=i;h;h=h.parentNode){if(h===t){return k(i,j,true)}if(h===j){break}}for(h=t;h;h=h.parentNode){if(h===i){return k(t,j)}if(h===j){break}}g=n(i,j)||i;o=n(t,j)||t;k(i,g,true);q=p(g==i?g:g.nextSibling,"nextSibling",o==t?o.nextSibling:o);if(q.length){s(f(q))}k(t,o)};this.split=function(e){var h=e.startContainer,d=e.startOffset,i=e.endContainer,g=e.endOffset;function f(j,k){return j.splitText(k)}if(h==i&&h.nodeType==3){if(d>0&&d<h.nodeValue.length){i=f(h,d);h=i.previousSibling;if(g>d){g=g-d;h=i=f(i,g).previousSibling;g=i.nodeValue.length;d=0}else{g=0}}}else{if(h.nodeType==3&&d>0&&d<h.nodeValue.length){h=f(h,d);d=0}if(i.nodeType==3&&g>0&&g<i.nodeValue.length){i=f(i,g).previousSibling;g=i.nodeValue.length}}return{startContainer:h,startOffset:d,endContainer:i,endOffset:g}}};a.dom.RangeUtils.compareRanges=function(c,b){if(c&&b){if(c.item||c.duplicate){if(c.item&&b.item&&c.item(0)===b.item(0)){return true}if(c.isEqual&&b.isEqual&&b.isEqual(c)){return true}}else{return c.startContainer==b.startContainer&&c.startOffset==b.startOffset}}return false}})(tinymce);(function(b){var a=b.dom.Event,c=b.each;b.create("tinymce.ui.KeyboardNavigation",{KeyboardNavigation:function(e,f){var p=this,m=e.root,l=e.items,n=e.enableUpDown,i=e.enableLeftRight||!e.enableUpDown,k=e.excludeFromTabOrder,j,h,o,d,g;f=f||b.DOM;j=function(q){g=q.target.id};h=function(q){f.setAttrib(q.target.id,"tabindex","-1")};d=function(q){var r=f.get(g);f.setAttrib(r,"tabindex","0");r.focus()};p.focus=function(){f.get(g).focus()};p.destroy=function(){c(l,function(q){f.unbind(f.get(q.id),"focus",j);f.unbind(f.get(q.id),"blur",h)});f.unbind(f.get(m),"focus",d);f.unbind(f.get(m),"keydown",o);l=f=m=p.focus=j=h=o=d=null;p.destroy=function(){}};p.moveFocus=function(u,r){var q=-1,t=p.controls,s;if(!g){return}c(l,function(x,v){if(x.id===g){q=v;return false}});q+=u;if(q<0){q=l.length-1}else{if(q>=l.length){q=0}}s=l[q];f.setAttrib(g,"tabindex","-1");f.setAttrib(s.id,"tabindex","0");f.get(s.id).focus();if(e.actOnFocus){e.onAction(s.id)}if(r){a.cancel(r)}};o=function(y){var u=37,t=39,x=38,z=40,q=27,s=14,r=13,v=32;switch(y.keyCode){case u:if(i){p.moveFocus(-1)}break;case t:if(i){p.moveFocus(1)}break;case x:if(n){p.moveFocus(-1)}break;case z:if(n){p.moveFocus(1)}break;case q:if(e.onCancel){e.onCancel();a.cancel(y)}break;case s:case r:case v:if(e.onAction){e.onAction(g);a.cancel(y)}break}};c(l,function(s,q){var r;if(!s.id){s.id=f.uniqueId("_mce_item_")}if(k){f.bind(s.id,"blur",h);r="-1"}else{r=(q===0?"0":"-1")}f.setAttrib(s.id,"tabindex",r);f.bind(f.get(s.id),"focus",j)});if(l[0]){g=l[0].id}f.setAttrib(m,"tabindex","-1");f.bind(f.get(m),"focus",d);f.bind(f.get(m),"keydown",o)}})})(tinymce);(function(c){var b=c.DOM,a=c.is;c.create("tinymce.ui.Control",{Control:function(f,e,d){this.id=f;this.settings=e=e||{};this.rendered=false;this.onRender=new c.util.Dispatcher(this);this.classPrefix="";this.scope=e.scope||this;this.disabled=0;this.active=0;this.editor=d},setAriaProperty:function(f,e){var d=b.get(this.id+"_aria")||b.get(this.id);if(d){b.setAttrib(d,"aria-"+f,!!e)}},focus:function(){b.get(this.id).focus()},setDisabled:function(d){if(d!=this.disabled){this.setAriaProperty("disabled",d);this.setState("Disabled",d);this.setState("Enabled",!d);this.disabled=d}},isDisabled:function(){return this.disabled},setActive:function(d){if(d!=this.active){this.setState("Active",d);this.active=d;this.setAriaProperty("pressed",d)}},isActive:function(){return this.active},setState:function(f,d){var e=b.get(this.id);f=this.classPrefix+f;if(d){b.addClass(e,f)}else{b.removeClass(e,f)}},isRendered:function(){return this.rendered},renderHTML:function(){},renderTo:function(d){b.setHTML(d,this.renderHTML())},postRender:function(){var e=this,d;if(a(e.disabled)){d=e.disabled;e.disabled=-1;e.setDisabled(d)}if(a(e.active)){d=e.active;e.active=-1;e.setActive(d)}},remove:function(){b.remove(this.id);this.destroy()},destroy:function(){c.dom.Event.clear(this.id)}})})(tinymce);tinymce.create("tinymce.ui.Container:tinymce.ui.Control",{Container:function(c,b,a){this.parent(c,b,a);this.controls=[];this.lookup={}},add:function(a){this.lookup[a.id]=a;this.controls.push(a);return a},get:function(a){return this.lookup[a]}});tinymce.create("tinymce.ui.Separator:tinymce.ui.Control",{Separator:function(b,a){this.parent(b,a);this.classPrefix="mceSeparator";this.setDisabled(true)},renderHTML:function(){return tinymce.DOM.createHTML("span",{"class":this.classPrefix,role:"separator","aria-orientation":"vertical",tabindex:"-1"})}});(function(d){var c=d.is,b=d.DOM,e=d.each,a=d.walk;d.create("tinymce.ui.MenuItem:tinymce.ui.Control",{MenuItem:function(g,f){this.parent(g,f);this.classPrefix="mceMenuItem"},setSelected:function(f){this.setState("Selected",f);this.setAriaProperty("checked",!!f);this.selected=f},isSelected:function(){return this.selected},postRender:function(){var f=this;f.parent();if(c(f.selected)){f.setSelected(f.selected)}}})})(tinymce);(function(d){var c=d.is,b=d.DOM,e=d.each,a=d.walk;d.create("tinymce.ui.Menu:tinymce.ui.MenuItem",{Menu:function(h,g){var f=this;f.parent(h,g);f.items={};f.collapsed=false;f.menuCount=0;f.onAddItem=new d.util.Dispatcher(this)},expand:function(g){var f=this;if(g){a(f,function(h){if(h.expand){h.expand()}},"items",f)}f.collapsed=false},collapse:function(g){var f=this;if(g){a(f,function(h){if(h.collapse){h.collapse()}},"items",f)}f.collapsed=true},isCollapsed:function(){return this.collapsed},add:function(f){if(!f.settings){f=new d.ui.MenuItem(f.id||b.uniqueId(),f)}this.onAddItem.dispatch(this,f);return this.items[f.id]=f},addSeparator:function(){return this.add({separator:true})},addMenu:function(f){if(!f.collapse){f=this.createMenu(f)}this.menuCount++;return this.add(f)},hasMenus:function(){return this.menuCount!==0},remove:function(f){delete this.items[f.id]},removeAll:function(){var f=this;a(f,function(g){if(g.removeAll){g.removeAll()}else{g.remove()}g.destroy()},"items",f);f.items={}},createMenu:function(g){var f=new d.ui.Menu(g.id||b.uniqueId(),g);f.onAddItem.add(this.onAddItem.dispatch,this.onAddItem);return f}})})(tinymce);(function(e){var d=e.is,c=e.DOM,f=e.each,a=e.dom.Event,b=e.dom.Element;e.create("tinymce.ui.DropMenu:tinymce.ui.Menu",{DropMenu:function(h,g){g=g||{};g.container=g.container||c.doc.body;g.offset_x=g.offset_x||0;g.offset_y=g.offset_y||0;g.vp_offset_x=g.vp_offset_x||0;g.vp_offset_y=g.vp_offset_y||0;if(d(g.icons)&&!g.icons){g["class"]+=" mceNoIcons"}this.parent(h,g);this.onShowMenu=new e.util.Dispatcher(this);this.onHideMenu=new e.util.Dispatcher(this);this.classPrefix="mceMenu"},createMenu:function(j){var h=this,i=h.settings,g;j.container=j.container||i.container;j.parent=h;j.constrain=j.constrain||i.constrain;j["class"]=j["class"]||i["class"];j.vp_offset_x=j.vp_offset_x||i.vp_offset_x;j.vp_offset_y=j.vp_offset_y||i.vp_offset_y;j.keyboard_focus=i.keyboard_focus;g=new e.ui.DropMenu(j.id||c.uniqueId(),j);g.onAddItem.add(h.onAddItem.dispatch,h.onAddItem);return g},focus:function(){var g=this;if(g.keyboardNav){g.keyboardNav.focus()}},update:function(){var i=this,j=i.settings,g=c.get("menu_"+i.id+"_tbl"),l=c.get("menu_"+i.id+"_co"),h,k;h=j.max_width?Math.min(g.clientWidth,j.max_width):g.clientWidth;k=j.max_height?Math.min(g.clientHeight,j.max_height):g.clientHeight;if(!c.boxModel){i.element.setStyles({width:h+2,height:k+2})}else{i.element.setStyles({width:h,height:k})}if(j.max_width){c.setStyle(l,"width",h)}if(j.max_height){c.setStyle(l,"height",k);if(g.clientHeight<j.max_height){c.setStyle(l,"overflow","hidden")}}},showMenu:function(p,n,r){var z=this,A=z.settings,o,g=c.getViewPort(),u,l,v,q,i=2,k,j,m=z.classPrefix;z.collapse(1);if(z.isMenuVisible){return}if(!z.rendered){o=c.add(z.settings.container,z.renderNode());f(z.items,function(h){h.postRender()});z.element=new b("menu_"+z.id,{blocker:1,container:A.container})}else{o=c.get("menu_"+z.id)}if(!e.isOpera){c.setStyles(o,{left:-65535,top:-65535})}c.show(o);z.update();p+=A.offset_x||0;n+=A.offset_y||0;g.w-=4;g.h-=4;if(A.constrain){u=o.clientWidth-i;l=o.clientHeight-i;v=g.x+g.w;q=g.y+g.h;if((p+A.vp_offset_x+u)>v){p=r?r-u:Math.max(0,(v-A.vp_offset_x)-u)}if((n+A.vp_offset_y+l)>q){n=Math.max(0,(q-A.vp_offset_y)-l)}}c.setStyles(o,{left:p,top:n});z.element.update();z.isMenuVisible=1;z.mouseClickFunc=a.add(o,"click",function(s){var h;s=s.target;if(s&&(s=c.getParent(s,"tr"))&&!c.hasClass(s,m+"ItemSub")){h=z.items[s.id];if(h.isDisabled()){return}k=z;while(k){if(k.hideMenu){k.hideMenu()}k=k.settings.parent}if(h.settings.onclick){h.settings.onclick(s)}return a.cancel(s)}});if(z.hasMenus()){z.mouseOverFunc=a.add(o,"mouseover",function(x){var h,t,s;x=x.target;if(x&&(x=c.getParent(x,"tr"))){h=z.items[x.id];if(z.lastMenu){z.lastMenu.collapse(1)}if(h.isDisabled()){return}if(x&&c.hasClass(x,m+"ItemSub")){t=c.getRect(x);h.showMenu((t.x+t.w-i),t.y-i,t.x);z.lastMenu=h;c.addClass(c.get(h.id).firstChild,m+"ItemActive")}}})}a.add(o,"keydown",z._keyHandler,z);z.onShowMenu.dispatch(z);if(A.keyboard_focus){z._setupKeyboardNav()}},hideMenu:function(j){var g=this,i=c.get("menu_"+g.id),h;if(!g.isMenuVisible){return}if(g.keyboardNav){g.keyboardNav.destroy()}a.remove(i,"mouseover",g.mouseOverFunc);a.remove(i,"click",g.mouseClickFunc);a.remove(i,"keydown",g._keyHandler);c.hide(i);g.isMenuVisible=0;if(!j){g.collapse(1)}if(g.element){g.element.hide()}if(h=c.get(g.id)){c.removeClass(h.firstChild,g.classPrefix+"ItemActive")}g.onHideMenu.dispatch(g)},add:function(i){var g=this,h;i=g.parent(i);if(g.isRendered&&(h=c.get("menu_"+g.id))){g._add(c.select("tbody",h)[0],i)}return i},collapse:function(g){this.parent(g);this.hideMenu(1)},remove:function(g){c.remove(g.id);this.destroy();return this.parent(g)},destroy:function(){var g=this,h=c.get("menu_"+g.id);if(g.keyboardNav){g.keyboardNav.destroy()}a.remove(h,"mouseover",g.mouseOverFunc);a.remove(c.select("a",h),"focus",g.mouseOverFunc);a.remove(h,"click",g.mouseClickFunc);a.remove(h,"keydown",g._keyHandler);if(g.element){g.element.remove()}c.remove(h)},renderNode:function(){var i=this,j=i.settings,l,h,k,g;g=c.create("div",{role:"listbox",id:"menu_"+i.id,"class":j["class"],style:"position:absolute;left:0;top:0;z-index:200000;outline:0"});if(i.settings.parent){c.setAttrib(g,"aria-parent","menu_"+i.settings.parent.id)}k=c.add(g,"div",{role:"presentation",id:"menu_"+i.id+"_co","class":i.classPrefix+(j["class"]?" "+j["class"]:"")});i.element=new b("menu_"+i.id,{blocker:1,container:j.container});if(j.menu_line){c.add(k,"span",{"class":i.classPrefix+"Line"})}l=c.add(k,"table",{role:"presentation",id:"menu_"+i.id+"_tbl",border:0,cellPadding:0,cellSpacing:0});h=c.add(l,"tbody");f(i.items,function(m){i._add(h,m)});i.rendered=true;return g},_setupKeyboardNav:function(){var i,h,g=this;i=c.get("menu_"+g.id);h=c.select("a[role=option]","menu_"+g.id);h.splice(0,0,i);g.keyboardNav=new e.ui.KeyboardNavigation({root:"menu_"+g.id,items:h,onCancel:function(){g.hideMenu()},enableUpDown:true});i.focus()},_keyHandler:function(g){var h=this,i;switch(g.keyCode){case 37:if(h.settings.parent){h.hideMenu();h.settings.parent.focus();a.cancel(g)}break;case 39:if(h.mouseOverFunc){h.mouseOverFunc(g)}break}},_add:function(j,h){var i,q=h.settings,p,l,k,m=this.classPrefix,g;if(q.separator){l=c.add(j,"tr",{id:h.id,"class":m+"ItemSeparator"});c.add(l,"td",{"class":m+"ItemSeparator"});if(i=l.previousSibling){c.addClass(i,"mceLast")}return}i=l=c.add(j,"tr",{id:h.id,"class":m+"Item "+m+"ItemEnabled"});i=k=c.add(i,q.titleItem?"th":"td");i=p=c.add(i,"a",{id:h.id+"_aria",role:q.titleItem?"presentation":"option",href:"javascript:;",onclick:"return false;",onmousedown:"return false;"});if(q.parent){c.setAttrib(p,"aria-haspopup","true");c.setAttrib(p,"aria-owns","menu_"+h.id)}c.addClass(k,q["class"]);g=c.add(i,"span",{"class":"mceIcon"+(q.icon?" mce_"+q.icon:"")});if(q.icon_src){c.add(g,"img",{src:q.icon_src})}i=c.add(i,q.element||"span",{"class":"mceText",title:h.settings.title},h.settings.title);if(h.settings.style){c.setAttrib(i,"style",h.settings.style)}if(j.childNodes.length==1){c.addClass(l,"mceFirst")}if((i=l.previousSibling)&&c.hasClass(i,m+"ItemSeparator")){c.addClass(l,"mceFirst")}if(h.collapse){c.addClass(l,m+"ItemSub")}if(i=l.previousSibling){c.removeClass(i,"mceLast")}c.addClass(l,"mceLast")}})})(tinymce);(function(b){var a=b.DOM;b.create("tinymce.ui.Button:tinymce.ui.Control",{Button:function(e,d,c){this.parent(e,d,c);this.classPrefix="mceButton"},renderHTML:function(){var f=this.classPrefix,e=this.settings,d,c;c=a.encode(e.label||"");d='<a role="button" id="'+this.id+'" href="javascript:;" class="'+f+" "+f+"Enabled "+e["class"]+(c?" "+f+"Labeled":"")+'" onmousedown="return false;" onclick="return false;" aria-labelledby="'+this.id+'_voice" title="'+a.encode(e.title)+'">';if(e.image&&!(this.editor&&this.editor.forcedHighContrastMode)){d+='<img class="mceIcon" src="'+e.image+'" alt="'+a.encode(e.title)+'" />'+c}else{d+='<span class="mceIcon '+e["class"]+'"></span>'+(c?'<span class="'+f+'Label">'+c+"</span>":"")}d+='<span class="mceVoiceLabel mceIconOnly" style="display: none;" id="'+this.id+'_voice">'+e.title+"</span>";d+="</a>";return d},postRender:function(){var c=this,e=c.settings,d;if(b.isIE&&c.editor){b.dom.Event.add(c.id,"mousedown",function(f){d=c.editor.selection.getBookmark()})}b.dom.Event.add(c.id,"click",function(f){if(!c.isDisabled()){if(b.isIE&&c.editor&&d){b.activeEditor.selection.moveToBookmark(d)}return e.onclick.call(e.scope,f)}});b.dom.Event.add(c.id,"keyup",function(f){if(!c.isDisabled()&&f.keyCode==b.VK.SPACEBAR){return e.onclick.call(e.scope,f)}})}})})(tinymce);(function(d){var c=d.DOM,b=d.dom.Event,e=d.each,a=d.util.Dispatcher;d.create("tinymce.ui.ListBox:tinymce.ui.Control",{ListBox:function(i,h,f){var g=this;g.parent(i,h,f);g.items=[];g.onChange=new a(g);g.onPostRender=new a(g);g.onAdd=new a(g);g.onRenderMenu=new d.util.Dispatcher(this);g.classPrefix="mceListBox"},select:function(h){var g=this,j,i;if(h==undefined){return g.selectByIndex(-1)}if(h&&h.call){i=h}else{i=function(f){return f==h}}if(h!=g.selectedValue){e(g.items,function(k,f){if(i(k.value)){j=1;g.selectByIndex(f);return false}});if(!j){g.selectByIndex(-1)}}},selectByIndex:function(f){var h=this,i,j,g;if(f!=h.selectedIndex){i=c.get(h.id+"_text");g=c.get(h.id+"_voiceDesc");j=h.items[f];if(j){h.selectedValue=j.value;h.selectedIndex=f;c.setHTML(i,c.encode(j.title));c.setHTML(g,h.settings.title+" - "+j.title);c.removeClass(i,"mceTitle");c.setAttrib(h.id,"aria-valuenow",j.title)}else{c.setHTML(i,c.encode(h.settings.title));c.setHTML(g,c.encode(h.settings.title));c.addClass(i,"mceTitle");h.selectedValue=h.selectedIndex=null;c.setAttrib(h.id,"aria-valuenow",h.settings.title)}i=0}},add:function(i,f,h){var g=this;h=h||{};h=d.extend(h,{title:i,value:f});g.items.push(h);g.onAdd.dispatch(g,h)},getLength:function(){return this.items.length},renderHTML:function(){var i="",f=this,g=f.settings,j=f.classPrefix;i='<span role="listbox" aria-haspopup="true" aria-labelledby="'+f.id+'_voiceDesc" aria-describedby="'+f.id+'_voiceDesc"><table role="presentation" tabindex="0" id="'+f.id+'" cellpadding="0" cellspacing="0" class="'+j+" "+j+"Enabled"+(g["class"]?(" "+g["class"]):"")+'"><tbody><tr>';i+="<td>"+c.createHTML("span",{id:f.id+"_voiceDesc","class":"voiceLabel",style:"display:none;"},f.settings.title);i+=c.createHTML("a",{id:f.id+"_text",tabindex:-1,href:"javascript:;","class":"mceText",onclick:"return false;",onmousedown:"return false;"},c.encode(f.settings.title))+"</td>";i+="<td>"+c.createHTML("a",{id:f.id+"_open",tabindex:-1,href:"javascript:;","class":"mceOpen",onclick:"return false;",onmousedown:"return false;"},'<span><span style="display:none;" class="mceIconOnly" aria-hidden="true">\u25BC</span></span>')+"</td>";i+="</tr></tbody></table></span>";return i},showMenu:function(){var g=this,i,h=c.get(this.id),f;if(g.isDisabled()||g.items.length==0){return}if(g.menu&&g.menu.isMenuVisible){return g.hideMenu()}if(!g.isMenuRendered){g.renderMenu();g.isMenuRendered=true}i=c.getPos(h);f=g.menu;f.settings.offset_x=i.x;f.settings.offset_y=i.y;f.settings.keyboard_focus=!d.isOpera;if(g.oldID){f.items[g.oldID].setSelected(0)}e(g.items,function(j){if(j.value===g.selectedValue){f.items[j.id].setSelected(1);g.oldID=j.id}});f.showMenu(0,h.clientHeight);b.add(c.doc,"mousedown",g.hideMenu,g);c.addClass(g.id,g.classPrefix+"Selected")},hideMenu:function(g){var f=this;if(f.menu&&f.menu.isMenuVisible){c.removeClass(f.id,f.classPrefix+"Selected");if(g&&g.type=="mousedown"&&(g.target.id==f.id+"_text"||g.target.id==f.id+"_open")){return}if(!g||!c.getParent(g.target,".mceMenu")){c.removeClass(f.id,f.classPrefix+"Selected");b.remove(c.doc,"mousedown",f.hideMenu,f);f.menu.hideMenu()}}},renderMenu:function(){var g=this,f;f=g.settings.control_manager.createDropMenu(g.id+"_menu",{menu_line:1,"class":g.classPrefix+"Menu mceNoIcons",max_width:150,max_height:150});f.onHideMenu.add(function(){g.hideMenu();g.focus()});f.add({title:g.settings.title,"class":"mceMenuItemTitle",onclick:function(){if(g.settings.onselect("")!==false){g.select("")}}});e(g.items,function(h){if(h.value===undefined){f.add({title:h.title,role:"option","class":"mceMenuItemTitle",onclick:function(){if(g.settings.onselect("")!==false){g.select("")}}})}else{h.id=c.uniqueId();h.role="option";h.onclick=function(){if(g.settings.onselect(h.value)!==false){g.select(h.value)}};f.add(h)}});g.onRenderMenu.dispatch(g,f);g.menu=f},postRender:function(){var f=this,g=f.classPrefix;b.add(f.id,"click",f.showMenu,f);b.add(f.id,"keydown",function(h){if(h.keyCode==32){f.showMenu(h);b.cancel(h)}});b.add(f.id,"focus",function(){if(!f._focused){f.keyDownHandler=b.add(f.id,"keydown",function(h){if(h.keyCode==40){f.showMenu();b.cancel(h)}});f.keyPressHandler=b.add(f.id,"keypress",function(i){var h;if(i.keyCode==13){h=f.selectedValue;f.selectedValue=null;b.cancel(i);f.settings.onselect(h)}})}f._focused=1});b.add(f.id,"blur",function(){b.remove(f.id,"keydown",f.keyDownHandler);b.remove(f.id,"keypress",f.keyPressHandler);f._focused=0});if(d.isIE6||!c.boxModel){b.add(f.id,"mouseover",function(){if(!c.hasClass(f.id,g+"Disabled")){c.addClass(f.id,g+"Hover")}});b.add(f.id,"mouseout",function(){if(!c.hasClass(f.id,g+"Disabled")){c.removeClass(f.id,g+"Hover")}})}f.onPostRender.dispatch(f,c.get(f.id))},destroy:function(){this.parent();b.clear(this.id+"_text");b.clear(this.id+"_open")}})})(tinymce);(function(d){var c=d.DOM,b=d.dom.Event,e=d.each,a=d.util.Dispatcher;d.create("tinymce.ui.NativeListBox:tinymce.ui.ListBox",{NativeListBox:function(g,f){this.parent(g,f);this.classPrefix="mceNativeListBox"},setDisabled:function(f){c.get(this.id).disabled=f;this.setAriaProperty("disabled",f)},isDisabled:function(){return c.get(this.id).disabled},select:function(h){var g=this,j,i;if(h==undefined){return g.selectByIndex(-1)}if(h&&h.call){i=h}else{i=function(f){return f==h}}if(h!=g.selectedValue){e(g.items,function(k,f){if(i(k.value)){j=1;g.selectByIndex(f);return false}});if(!j){g.selectByIndex(-1)}}},selectByIndex:function(f){c.get(this.id).selectedIndex=f+1;this.selectedValue=this.items[f]?this.items[f].value:null},add:function(j,g,f){var i,h=this;f=f||{};f.value=g;if(h.isRendered()){c.add(c.get(this.id),"option",f,j)}i={title:j,value:g,attribs:f};h.items.push(i);h.onAdd.dispatch(h,i)},getLength:function(){return this.items.length},renderHTML:function(){var g,f=this;g=c.createHTML("option",{value:""},"-- "+f.settings.title+" --");e(f.items,function(h){g+=c.createHTML("option",{value:h.value},h.title)});g=c.createHTML("select",{id:f.id,"class":"mceNativeListBox","aria-labelledby":f.id+"_aria"},g);g+=c.createHTML("span",{id:f.id+"_aria",style:"display: none"},f.settings.title);return g},postRender:function(){var g=this,h,i=true;g.rendered=true;function f(k){var j=g.items[k.target.selectedIndex-1];if(j&&(j=j.value)){g.onChange.dispatch(g,j);if(g.settings.onselect){g.settings.onselect(j)}}}b.add(g.id,"change",f);b.add(g.id,"keydown",function(k){var j;b.remove(g.id,"change",h);i=false;j=b.add(g.id,"blur",function(){if(i){return}i=true;b.add(g.id,"change",f);b.remove(g.id,"blur",j)});if(d.isWebKit&&(k.keyCode==37||k.keyCode==39)){return b.prevent(k)}if(k.keyCode==13||k.keyCode==32){f(k);return b.cancel(k)}});g.onPostRender.dispatch(g,c.get(g.id))}})})(tinymce);(function(c){var b=c.DOM,a=c.dom.Event,d=c.each;c.create("tinymce.ui.MenuButton:tinymce.ui.Button",{MenuButton:function(g,f,e){this.parent(g,f,e);this.onRenderMenu=new c.util.Dispatcher(this);f.menu_container=f.menu_container||b.doc.body},showMenu:function(){var g=this,j,i,h=b.get(g.id),f;if(g.isDisabled()){return}if(!g.isMenuRendered){g.renderMenu();g.isMenuRendered=true}if(g.isMenuVisible){return g.hideMenu()}j=b.getPos(g.settings.menu_container);i=b.getPos(h);f=g.menu;f.settings.offset_x=i.x;f.settings.offset_y=i.y;f.settings.vp_offset_x=i.x;f.settings.vp_offset_y=i.y;f.settings.keyboard_focus=g._focused;f.showMenu(0,h.clientHeight);a.add(b.doc,"mousedown",g.hideMenu,g);g.setState("Selected",1);g.isMenuVisible=1},renderMenu:function(){var f=this,e;e=f.settings.control_manager.createDropMenu(f.id+"_menu",{menu_line:1,"class":this.classPrefix+"Menu",icons:f.settings.icons});e.onHideMenu.add(function(){f.hideMenu();f.focus()});f.onRenderMenu.dispatch(f,e);f.menu=e},hideMenu:function(g){var f=this;if(g&&g.type=="mousedown"&&b.getParent(g.target,function(h){return h.id===f.id||h.id===f.id+"_open"})){return}if(!g||!b.getParent(g.target,".mceMenu")){f.setState("Selected",0);a.remove(b.doc,"mousedown",f.hideMenu,f);if(f.menu){f.menu.hideMenu()}}f.isMenuVisible=0},postRender:function(){var e=this,f=e.settings;a.add(e.id,"click",function(){if(!e.isDisabled()){if(f.onclick){f.onclick(e.value)}e.showMenu()}})}})})(tinymce);(function(c){var b=c.DOM,a=c.dom.Event,d=c.each;c.create("tinymce.ui.SplitButton:tinymce.ui.MenuButton",{SplitButton:function(g,f,e){this.parent(g,f,e);this.classPrefix="mceSplitButton"},renderHTML:function(){var i,f=this,g=f.settings,e;i="<tbody><tr>";if(g.image){e=b.createHTML("img ",{src:g.image,role:"presentation","class":"mceAction "+g["class"]})}else{e=b.createHTML("span",{"class":"mceAction "+g["class"]},"")}e+=b.createHTML("span",{"class":"mceVoiceLabel mceIconOnly",id:f.id+"_voice",style:"display:none;"},g.title);i+="<td >"+b.createHTML("a",{role:"button",id:f.id+"_action",tabindex:"-1",href:"javascript:;","class":"mceAction "+g["class"],onclick:"return false;",onmousedown:"return false;",title:g.title},e)+"</td>";e=b.createHTML("span",{"class":"mceOpen "+g["class"]},'<span style="display:none;" class="mceIconOnly" aria-hidden="true">\u25BC</span>');i+="<td >"+b.createHTML("a",{role:"button",id:f.id+"_open",tabindex:"-1",href:"javascript:;","class":"mceOpen "+g["class"],onclick:"return false;",onmousedown:"return false;",title:g.title},e)+"</td>";i+="</tr></tbody>";i=b.createHTML("table",{role:"presentation","class":"mceSplitButton mceSplitButtonEnabled "+g["class"],cellpadding:"0",cellspacing:"0",title:g.title},i);return b.createHTML("div",{id:f.id,role:"button",tabindex:"0","aria-labelledby":f.id+"_voice","aria-haspopup":"true"},i)},postRender:function(){var e=this,g=e.settings,f;if(g.onclick){f=function(h){if(!e.isDisabled()){g.onclick(e.value);a.cancel(h)}};a.add(e.id+"_action","click",f);a.add(e.id,["click","keydown"],function(h){var k=32,m=14,i=13,j=38,l=40;if((h.keyCode===32||h.keyCode===13||h.keyCode===14)&&!h.altKey&&!h.ctrlKey&&!h.metaKey){f();a.cancel(h)}else{if(h.type==="click"||h.keyCode===l){e.showMenu();a.cancel(h)}}})}a.add(e.id+"_open","click",function(h){e.showMenu();a.cancel(h)});a.add([e.id,e.id+"_open"],"focus",function(){e._focused=1});a.add([e.id,e.id+"_open"],"blur",function(){e._focused=0});if(c.isIE6||!b.boxModel){a.add(e.id,"mouseover",function(){if(!b.hasClass(e.id,"mceSplitButtonDisabled")){b.addClass(e.id,"mceSplitButtonHover")}});a.add(e.id,"mouseout",function(){if(!b.hasClass(e.id,"mceSplitButtonDisabled")){b.removeClass(e.id,"mceSplitButtonHover")}})}},destroy:function(){this.parent();a.clear(this.id+"_action");a.clear(this.id+"_open");a.clear(this.id)}})})(tinymce);(function(d){var c=d.DOM,a=d.dom.Event,b=d.is,e=d.each;d.create("tinymce.ui.ColorSplitButton:tinymce.ui.SplitButton",{ColorSplitButton:function(i,h,f){var g=this;g.parent(i,h,f);g.settings=h=d.extend({colors:"000000,993300,333300,003300,003366,000080,333399,333333,800000,FF6600,808000,008000,008080,0000FF,666699,808080,FF0000,FF9900,99CC00,339966,33CCCC,3366FF,800080,999999,FF00FF,FFCC00,FFFF00,00FF00,00FFFF,00CCFF,993366,C0C0C0,FF99CC,FFCC99,FFFF99,CCFFCC,CCFFFF,99CCFF,CC99FF,FFFFFF",grid_width:8,default_color:"#888888"},g.settings);g.onShowMenu=new d.util.Dispatcher(g);g.onHideMenu=new d.util.Dispatcher(g);g.value=h.default_color},showMenu:function(){var f=this,g,j,i,h;if(f.isDisabled()){return}if(!f.isMenuRendered){f.renderMenu();f.isMenuRendered=true}if(f.isMenuVisible){return f.hideMenu()}i=c.get(f.id);c.show(f.id+"_menu");c.addClass(i,"mceSplitButtonSelected");h=c.getPos(i);c.setStyles(f.id+"_menu",{left:h.x,top:h.y+i.clientHeight,zIndex:200000});i=0;a.add(c.doc,"mousedown",f.hideMenu,f);f.onShowMenu.dispatch(f);if(f._focused){f._keyHandler=a.add(f.id+"_menu","keydown",function(k){if(k.keyCode==27){f.hideMenu()}});c.select("a",f.id+"_menu")[0].focus()}f.isMenuVisible=1},hideMenu:function(g){var f=this;if(f.isMenuVisible){if(g&&g.type=="mousedown"&&c.getParent(g.target,function(h){return h.id===f.id+"_open"})){return}if(!g||!c.getParent(g.target,".mceSplitButtonMenu")){c.removeClass(f.id,"mceSplitButtonSelected");a.remove(c.doc,"mousedown",f.hideMenu,f);a.remove(f.id+"_menu","keydown",f._keyHandler);c.hide(f.id+"_menu")}f.isMenuVisible=0;f.onHideMenu.dispatch()}},renderMenu:function(){var p=this,h,k=0,q=p.settings,g,j,l,o,f;o=c.add(q.menu_container,"div",{role:"listbox",id:p.id+"_menu","class":q.menu_class+" "+q["class"],style:"position:absolute;left:0;top:-1000px;"});h=c.add(o,"div",{"class":q["class"]+" mceSplitButtonMenu"});c.add(h,"span",{"class":"mceMenuLine"});g=c.add(h,"table",{role:"presentation","class":"mceColorSplitMenu"});j=c.add(g,"tbody");k=0;e(b(q.colors,"array")?q.colors:q.colors.split(","),function(m){m=m.replace(/^#/,"");if(!k--){l=c.add(j,"tr");k=q.grid_width-1}g=c.add(l,"td");var i={href:"javascript:;",style:{backgroundColor:"#"+m},title:p.editor.getLang("colors."+m,m),"data-mce-color":"#"+m};if(!d.isIE){i.role="option"}g=c.add(g,"a",i);if(p.editor.forcedHighContrastMode){g=c.add(g,"canvas",{width:16,height:16,"aria-hidden":"true"});if(g.getContext&&(f=g.getContext("2d"))){f.fillStyle="#"+m;f.fillRect(0,0,16,16)}else{c.remove(g)}}});if(q.more_colors_func){g=c.add(j,"tr");g=c.add(g,"td",{colspan:q.grid_width,"class":"mceMoreColors"});g=c.add(g,"a",{role:"option",id:p.id+"_more",href:"javascript:;",onclick:"return false;","class":"mceMoreColors"},q.more_colors_title);a.add(g,"click",function(i){q.more_colors_func.call(q.more_colors_scope||this);return a.cancel(i)})}c.addClass(h,"mceColorSplitMenu");new d.ui.KeyboardNavigation({root:p.id+"_menu",items:c.select("a",p.id+"_menu"),onCancel:function(){p.hideMenu();p.focus()}});a.add(p.id+"_menu","mousedown",function(i){return a.cancel(i)});a.add(p.id+"_menu","click",function(i){var m;i=c.getParent(i.target,"a",j);if(i&&i.nodeName.toLowerCase()=="a"&&(m=i.getAttribute("data-mce-color"))){p.setColor(m)}return a.cancel(i)});return o},setColor:function(f){this.displayColor(f);this.hideMenu();this.settings.onselect(f)},displayColor:function(g){var f=this;c.setStyle(f.id+"_preview","backgroundColor",g);f.value=g},postRender:function(){var f=this,g=f.id;f.parent();c.add(g+"_action","div",{id:g+"_preview","class":"mceColorPreview"});c.setStyle(f.id+"_preview","backgroundColor",f.value)},destroy:function(){this.parent();a.clear(this.id+"_menu");a.clear(this.id+"_more");c.remove(this.id+"_menu")}})})(tinymce);(function(b){var d=b.DOM,c=b.each,a=b.dom.Event;b.create("tinymce.ui.ToolbarGroup:tinymce.ui.Container",{renderHTML:function(){var f=this,i=[],e=f.controls,j=b.each,g=f.settings;i.push('<div id="'+f.id+'" role="group" aria-labelledby="'+f.id+'_voice">');i.push("<span role='application'>");i.push('<span id="'+f.id+'_voice" class="mceVoiceLabel" style="display:none;">'+d.encode(g.name)+"</span>");j(e,function(h){i.push(h.renderHTML())});i.push("</span>");i.push("</div>");return i.join("")},focus:function(){var e=this;d.get(e.id).focus()},postRender:function(){var f=this,e=[];c(f.controls,function(g){c(g.controls,function(h){if(h.id){e.push(h)}})});f.keyNav=new b.ui.KeyboardNavigation({root:f.id,items:e,onCancel:function(){if(b.isWebKit){d.get(f.editor.id+"_ifr").focus()}f.editor.focus()},excludeFromTabOrder:!f.settings.tab_focus_toolbar})},destroy:function(){var e=this;e.parent();e.keyNav.destroy();a.clear(e.id)}})})(tinymce);(function(a){var c=a.DOM,b=a.each;a.create("tinymce.ui.Toolbar:tinymce.ui.Container",{renderHTML:function(){var m=this,f="",j,k,n=m.settings,e,d,g,l;l=m.controls;for(e=0;e<l.length;e++){k=l[e];d=l[e-1];g=l[e+1];if(e===0){j="mceToolbarStart";if(k.Button){j+=" mceToolbarStartButton"}else{if(k.SplitButton){j+=" mceToolbarStartSplitButton"}else{if(k.ListBox){j+=" mceToolbarStartListBox"}}}f+=c.createHTML("td",{"class":j},c.createHTML("span",null,"<!-- IE -->"))}if(d&&k.ListBox){if(d.Button||d.SplitButton){f+=c.createHTML("td",{"class":"mceToolbarEnd"},c.createHTML("span",null,"<!-- IE -->"))}}if(c.stdMode){f+='<td style="position: relative">'+k.renderHTML()+"</td>"}else{f+="<td>"+k.renderHTML()+"</td>"}if(g&&k.ListBox){if(g.Button||g.SplitButton){f+=c.createHTML("td",{"class":"mceToolbarStart"},c.createHTML("span",null,"<!-- IE -->"))}}}j="mceToolbarEnd";if(k.Button){j+=" mceToolbarEndButton"}else{if(k.SplitButton){j+=" mceToolbarEndSplitButton"}else{if(k.ListBox){j+=" mceToolbarEndListBox"}}}f+=c.createHTML("td",{"class":j},c.createHTML("span",null,"<!-- IE -->"));return c.createHTML("table",{id:m.id,"class":"mceToolbar"+(n["class"]?" "+n["class"]:""),cellpadding:"0",cellspacing:"0",align:m.settings.align||"",role:"presentation",tabindex:"-1"},"<tbody><tr>"+f+"</tr></tbody>")}})})(tinymce);(function(b){var a=b.util.Dispatcher,c=b.each;b.create("tinymce.AddOnManager",{AddOnManager:function(){var d=this;d.items=[];d.urls={};d.lookup={};d.onAdd=new a(d)},get:function(d){if(this.lookup[d]){return this.lookup[d].instance}else{return undefined}},dependencies:function(e){var d;if(this.lookup[e]){d=this.lookup[e].dependencies}return d||[]},requireLangPack:function(e){var d=b.settings;if(d&&d.language&&d.language_load!==false){b.ScriptLoader.add(this.urls[e]+"/langs/"+d.language+".js")}},add:function(f,e,d){this.items.push(e);this.lookup[f]={instance:e,dependencies:d};this.onAdd.dispatch(this,f,e);return e},createUrl:function(d,e){if(typeof e==="object"){return e}else{return{prefix:d.prefix,resource:e,suffix:d.suffix}}},addComponents:function(f,d){var e=this.urls[f];b.each(d,function(g){b.ScriptLoader.add(e+"/"+g)})},load:function(j,f,d,h){var g=this,e=f;function i(){var k=g.dependencies(j);b.each(k,function(m){var l=g.createUrl(f,m);g.load(l.resource,l,undefined,undefined)});if(d){if(h){d.call(h)}else{d.call(b.ScriptLoader)}}}if(g.urls[j]){return}if(typeof f==="object"){e=f.prefix+f.resource+f.suffix}if(e.indexOf("/")!=0&&e.indexOf("://")==-1){e=b.baseURL+"/"+e}g.urls[j]=e.substring(0,e.lastIndexOf("/"));if(g.lookup[j]){i()}else{b.ScriptLoader.add(e,i,h)}}});b.PluginManager=new b.AddOnManager();b.ThemeManager=new b.AddOnManager()}(tinymce));(function(j){var g=j.each,d=j.extend,k=j.DOM,i=j.dom.Event,f=j.ThemeManager,b=j.PluginManager,e=j.explode,h=j.util.Dispatcher,a,c=0;j.documentBaseURL=window.location.href.replace(/[\?#].*$/,"").replace(/[\/\\][^\/]+$/,"");if(!/[\/\\]$/.test(j.documentBaseURL)){j.documentBaseURL+="/"}j.baseURL=new j.util.URI(j.documentBaseURL).toAbsolute(j.baseURL);j.baseURI=new j.util.URI(j.baseURL);j.onBeforeUnload=new h(j);i.add(window,"beforeunload",function(l){j.onBeforeUnload.dispatch(j,l)});j.onAddEditor=new h(j);j.onRemoveEditor=new h(j);j.EditorManager=d(j,{editors:[],i18n:{},activeEditor:null,init:function(q){var n=this,p,l=j.ScriptLoader,u,o=[],m;function r(x,y,t){var v=x[y];if(!v){return}if(j.is(v,"string")){t=v.replace(/\.\w+$/,"");t=t?j.resolve(t):0;v=j.resolve(v)}return v.apply(t||this,Array.prototype.slice.call(arguments,2))}q=d({theme:"simple",language:"en"},q);n.settings=q;i.add(document,"init",function(){var s,v;r(q,"onpageload");switch(q.mode){case"exact":s=q.elements||"";if(s.length>0){g(e(s),function(x){if(k.get(x)){m=new j.Editor(x,q);o.push(m);m.render(1)}else{g(document.forms,function(y){g(y.elements,function(z){if(z.name===x){x="mce_editor_"+c++;k.setAttrib(z,"id",x);m=new j.Editor(x,q);o.push(m);m.render(1)}})})}})}break;case"textareas":case"specific_textareas":function t(y,x){return x.constructor===RegExp?x.test(y.className):k.hasClass(y,x)}g(k.select("textarea"),function(x){if(q.editor_deselector&&t(x,q.editor_deselector)){return}if(!q.editor_selector||t(x,q.editor_selector)){u=k.get(x.name);if(!x.id&&!u){x.id=x.name}if(!x.id||n.get(x.id)){x.id=k.uniqueId()}m=new j.Editor(x.id,q);o.push(m);m.render(1)}});break}if(q.oninit){s=v=0;g(o,function(x){v++;if(!x.initialized){x.onInit.add(function(){s++;if(s==v){r(q,"oninit")}})}else{s++}if(s==v){r(q,"oninit")}})}})},get:function(l){if(l===a){return this.editors}return this.editors[l]},getInstanceById:function(l){return this.get(l)},add:function(m){var l=this,n=l.editors;n[m.id]=m;n.push(m);l._setActive(m);l.onAddEditor.dispatch(l,m);return m},remove:function(n){var m=this,l,o=m.editors;if(!o[n.id]){return null}delete o[n.id];for(l=0;l<o.length;l++){if(o[l]==n){o.splice(l,1);break}}if(m.activeEditor==n){m._setActive(o[0])}n.destroy();m.onRemoveEditor.dispatch(m,n);return n},execCommand:function(r,p,o){var q=this,n=q.get(o),l;switch(r){case"mceFocus":n.focus();return true;case"mceAddEditor":case"mceAddControl":if(!q.get(o)){new j.Editor(o,q.settings).render()}return true;case"mceAddFrameControl":l=o.window;l.tinyMCE=tinyMCE;l.tinymce=j;j.DOM.doc=l.document;j.DOM.win=l;n=new j.Editor(o.element_id,o);n.render();if(j.isIE){function m(){n.destroy();l.detachEvent("onunload",m);l=l.tinyMCE=l.tinymce=null}l.attachEvent("onunload",m)}o.page_window=null;return true;case"mceRemoveEditor":case"mceRemoveControl":if(n){n.remove()}return true;case"mceToggleEditor":if(!n){q.execCommand("mceAddControl",0,o);return true}if(n.isHidden()){n.show()}else{n.hide()}return true}if(q.activeEditor){return q.activeEditor.execCommand(r,p,o)}return false},execInstanceCommand:function(p,o,n,m){var l=this.get(p);if(l){return l.execCommand(o,n,m)}return false},triggerSave:function(){g(this.editors,function(l){l.save()})},addI18n:function(n,q){var l,m=this.i18n;if(!j.is(n,"string")){g(n,function(r,p){g(r,function(t,s){g(t,function(v,u){if(s==="common"){m[p+"."+u]=v}else{m[p+"."+s+"."+u]=v}})})})}else{g(q,function(r,p){m[n+"."+p]=r})}},_setActive:function(l){this.selectedInstance=this.activeEditor=l}})})(tinymce);(function(n){var o=n.DOM,k=n.dom.Event,f=n.extend,l=n.util.Dispatcher,i=n.each,a=n.isGecko,b=n.isIE,e=n.isWebKit,d=n.is,h=n.ThemeManager,c=n.PluginManager,p=n.inArray,m=n.grep,g=n.explode,j=n.VK;n.create("tinymce.Editor",{Editor:function(u,r){var q=this;q.id=q.editorId=u;q.execCommands={};q.queryStateCommands={};q.queryValueCommands={};q.isNotDirty=false;q.plugins={};i(["onPreInit","onBeforeRenderUI","onPostRender","onLoad","onInit","onRemove","onActivate","onDeactivate","onClick","onEvent","onMouseUp","onMouseDown","onDblClick","onKeyDown","onKeyUp","onKeyPress","onContextMenu","onSubmit","onReset","onPaste","onPreProcess","onPostProcess","onBeforeSetContent","onBeforeGetContent","onSetContent","onGetContent","onLoadContent","onSaveContent","onNodeChange","onChange","onBeforeExecCommand","onExecCommand","onUndo","onRedo","onVisualAid","onSetProgressState","onSetAttrib"],function(s){q[s]=new l(q)});q.settings=r=f({id:u,language:"en",docs_language:"en",theme:"simple",skin:"default",delta_width:0,delta_height:0,popup_css:"",plugins:"",document_base_url:n.documentBaseURL,add_form_submit_trigger:1,submit_patch:1,add_unload_trigger:1,convert_urls:1,relative_urls:1,remove_script_host:1,table_inline_editing:0,object_resizing:1,cleanup:1,accessibility_focus:1,custom_shortcuts:1,custom_undo_redo_keyboard_shortcuts:1,custom_undo_redo_restore_selection:1,custom_undo_redo:1,doctype:n.isIE6?'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">':"<!DOCTYPE>",visual_table_class:"mceItemTable",visual:1,font_size_style_values:"xx-small,x-small,small,medium,large,x-large,xx-large",font_size_legacy_values:"xx-small,small,medium,large,x-large,xx-large,300%",apply_source_formatting:1,directionality:"ltr",forced_root_block:"p",hidden_input:1,padd_empty_editor:1,render_ui:1,init_theme:1,force_p_newlines:1,indentation:"30px",keep_styles:1,fix_table_elements:1,inline_styles:1,convert_fonts_to_spans:true,indent:"simple",indent_before:"p,h1,h2,h3,h4,h5,h6,blockquote,div,title,style,pre,script,td,ul,li,area,table,thead,tfoot,tbody,tr",indent_after:"p,h1,h2,h3,h4,h5,h6,blockquote,div,title,style,pre,script,td,ul,li,area,table,thead,tfoot,tbody,tr",validate:true,entity_encoding:"named",url_converter:q.convertURL,url_converter_scope:q,ie7_compat:true},r);q.documentBaseURI=new n.util.URI(r.document_base_url||n.documentBaseURL,{base_uri:tinyMCE.baseURI});q.baseURI=n.baseURI;q.contentCSS=[];q.execCallback("setup",q)},render:function(u){var v=this,x=v.settings,y=v.id,q=n.ScriptLoader;if(!k.domLoaded){k.add(document,"init",function(){v.render()});return}tinyMCE.settings=x;if(!v.getElement()){return}if(n.isIDevice&&!n.isIOS5){return}if(!/TEXTAREA|INPUT/i.test(v.getElement().nodeName)&&x.hidden_input&&o.getParent(y,"form")){o.insertAfter(o.create("input",{type:"hidden",name:y}),y)}if(n.WindowManager){v.windowManager=new n.WindowManager(v)}if(x.encoding=="xml"){v.onGetContent.add(function(s,t){if(t.save){t.content=o.encode(t.content)}})}if(x.add_form_submit_trigger){v.onSubmit.addToTop(function(){if(v.initialized){v.save();v.isNotDirty=1}})}if(x.add_unload_trigger){v._beforeUnload=tinyMCE.onBeforeUnload.add(function(){if(v.initialized&&!v.destroyed&&!v.isHidden()){v.save({format:"raw",no_events:true})}})}n.addUnload(v.destroy,v);if(x.submit_patch){v.onBeforeRenderUI.add(function(){var s=v.getElement().form;if(!s){return}if(s._mceOldSubmit){return}if(!s.submit.nodeType&&!s.submit.length){v.formElement=s;s._mceOldSubmit=s.submit;s.submit=function(){n.triggerSave();v.isNotDirty=1;return v.formElement._mceOldSubmit(v.formElement)}}s=null})}function r(){if(x.language&&x.language_load!==false){q.add(n.baseURL+"/langs/"+x.language+".js")}if(x.theme&&x.theme.charAt(0)!="-"&&!h.urls[x.theme]){h.load(x.theme,"themes/"+x.theme+"/editor_template"+n.suffix+".js")}i(g(x.plugins),function(t){if(t&&!c.urls[t]){if(t.charAt(0)=="-"){t=t.substr(1,t.length);var s=c.dependencies(t);i(s,function(A){var z={prefix:"plugins/",resource:A,suffix:"/editor_plugin"+n.suffix+".js"};var A=c.createUrl(z,A);c.load(A.resource,A)})}else{if(t=="safari"){return}c.load(t,{prefix:"plugins/",resource:t,suffix:"/editor_plugin"+n.suffix+".js"})}}});q.loadQueue(function(){if(!v.removed){v.init()}})}r()},init:function(){var v,I=this,J=I.settings,F,B,E=I.getElement(),r,q,G,z,D,H,A,x=[];n.add(I);J.aria_label=J.aria_label||o.getAttrib(E,"aria-label",I.getLang("aria.rich_text_area"));if(J.theme){J.theme=J.theme.replace(/-/,"");r=h.get(J.theme);I.theme=new r();if(I.theme.init&&J.init_theme){I.theme.init(I,h.urls[J.theme]||n.documentBaseURL.replace(/\/$/,""))}}function C(K){var L=c.get(K),t=c.urls[K]||n.documentBaseURL.replace(/\/$/,""),s;if(L&&n.inArray(x,K)===-1){i(c.dependencies(K),function(u){C(u)});s=new L(I,t);I.plugins[K]=s;if(s.init){s.init(I,t);x.push(K)}}}i(g(J.plugins.replace(/\-/g,"")),C);if(J.popup_css!==false){if(J.popup_css){J.popup_css=I.documentBaseURI.toAbsolute(J.popup_css)}else{J.popup_css=I.baseURI.toAbsolute("themes/"+J.theme+"/skins/"+J.skin+"/dialog.css")}}if(J.popup_css_add){J.popup_css+=","+I.documentBaseURI.toAbsolute(J.popup_css_add)}I.controlManager=new n.ControlManager(I);if(J.custom_undo_redo){I.onBeforeExecCommand.add(function(t,K,u,L,s){if(K!="Undo"&&K!="Redo"&&K!="mceRepaint"&&(!s||!s.skip_undo)){I.undoManager.beforeChange()}});I.onExecCommand.add(function(t,K,u,L,s){if(K!="Undo"&&K!="Redo"&&K!="mceRepaint"&&(!s||!s.skip_undo)){I.undoManager.add()}})}I.onExecCommand.add(function(s,t){if(!/^(FontName|FontSize)$/.test(t)){I.nodeChanged()}});if(a){function y(s,t){if(!t||!t.initial){I.execCommand("mceRepaint")}}I.onUndo.add(y);I.onRedo.add(y);I.onSetContent.add(y)}I.onBeforeRenderUI.dispatch(I,I.controlManager);if(J.render_ui){F=J.width||E.style.width||E.offsetWidth;B=J.height||E.style.height||E.offsetHeight;I.orgDisplay=E.style.display;H=/^[0-9\.]+(|px)$/i;if(H.test(""+F)){F=Math.max(parseInt(F)+(r.deltaWidth||0),100)}if(H.test(""+B)){B=Math.max(parseInt(B)+(r.deltaHeight||0),100)}r=I.theme.renderUI({targetNode:E,width:F,height:B,deltaWidth:J.delta_width,deltaHeight:J.delta_height});I.editorContainer=r.editorContainer}if(document.domain&&location.hostname!=document.domain){n.relaxedDomain=document.domain}o.setStyles(r.sizeContainer||r.editorContainer,{width:F,height:B});if(J.content_css){n.each(g(J.content_css),function(s){I.contentCSS.push(I.documentBaseURI.toAbsolute(s))})}B=(r.iframeHeight||B)+(typeof(B)=="number"?(r.deltaHeight||0):"");if(B<100){B=100}I.iframeHTML=J.doctype+'<html><head xmlns="http://www.w3.org/1999/xhtml">';if(J.document_base_url!=n.documentBaseURL){I.iframeHTML+='<base href="'+I.documentBaseURI.getURI()+'" />'}if(J.ie7_compat){I.iframeHTML+='<meta http-equiv="X-UA-Compatible" content="IE=7" />'}else{I.iframeHTML+='<meta http-equiv="X-UA-Compatible" content="IE=edge" />'}I.iframeHTML+='<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />';for(A=0;A<I.contentCSS.length;A++){I.iframeHTML+='<link type="text/css" rel="stylesheet" href="'+I.contentCSS[A]+'" />'}z=J.body_id||"tinymce";if(z.indexOf("=")!=-1){z=I.getParam("body_id","","hash");z=z[I.id]||z}D=J.body_class||"";if(D.indexOf("=")!=-1){D=I.getParam("body_class","","hash");D=D[I.id]||""}I.iframeHTML+='</head><body id="'+z+'" class="mceContentBody '+D+'" onload="window.parent.tinyMCE.get(\''+I.id+"').onLoad.dispatch();\"><br></body></html>";if(n.relaxedDomain&&(b||(n.isOpera&&parseFloat(opera.version())<11))){G='javascript:(function(){document.open();document.domain="'+document.domain+'";var ed = window.parent.tinyMCE.get("'+I.id+'");document.write(ed.iframeHTML);document.close();ed.setupIframe();})()'}v=o.add(r.iframeContainer,"iframe",{id:I.id+"_ifr",src:G||'javascript:""',frameBorder:"0",allowTransparency:"true",title:J.aria_label,style:{width:"100%",height:B,display:"block"}});I.contentAreaContainer=r.iframeContainer;o.get(r.editorContainer).style.display=I.orgDisplay;o.get(I.id).style.display="none";o.setAttrib(I.id,"aria-hidden",true);if(!n.relaxedDomain||!G){I.setupIframe()}E=v=r=null},setupIframe:function(){var r=this,x=r.settings,y=o.get(r.id),z=r.getDoc(),v,q;if(!b||!n.relaxedDomain){z.open();z.write(r.iframeHTML);z.close();if(n.relaxedDomain){z.domain=n.relaxedDomain}}q=r.getBody();q.disabled=true;if(!x.readonly){q.contentEditable=true}q.disabled=false;r.schema=new n.html.Schema(x);r.dom=new n.dom.DOMUtils(r.getDoc(),{keep_values:true,url_converter:r.convertURL,url_converter_scope:r,hex_colors:x.force_hex_style_colors,class_filter:x.class_filter,update_styles:1,fix_ie_paragraphs:1,schema:r.schema});r.parser=new n.html.DomParser(x,r.schema);if(!r.settings.allow_html_in_named_anchor){r.parser.addAttributeFilter("name",function(s,t){var B=s.length,D,A,C,E;while(B--){E=s[B];if(E.name==="a"&&E.firstChild){C=E.parent;D=E.lastChild;do{A=D.prev;C.insert(D,E);D=A}while(D)}}})}r.parser.addAttributeFilter("src,href,style",function(s,t){var A=s.length,C,E=r.dom,D,B;while(A--){C=s[A];D=C.attr(t);B="data-mce-"+t;if(!C.attributes.map[B]){if(t==="style"){C.attr(B,E.serializeStyle(E.parseStyle(D),C.name))}else{C.attr(B,r.convertURL(D,t,C.name))}}}});r.parser.addNodeFilter("script",function(s,t){var A=s.length,B;while(A--){B=s[A];B.attr("type","mce-"+(B.attr("type")||"text/javascript"))}});r.parser.addNodeFilter("#cdata",function(s,t){var A=s.length,B;while(A--){B=s[A];B.type=8;B.name="#comment";B.value="[CDATA["+B.value+"]]"}});r.parser.addNodeFilter("p,h1,h2,h3,h4,h5,h6,div",function(t,A){var B=t.length,C,s=r.schema.getNonEmptyElements();while(B--){C=t[B];if(C.isEmpty(s)){C.empty().append(new n.html.Node("br",1)).shortEnded=true}}});r.serializer=new n.dom.Serializer(x,r.dom,r.schema);r.selection=new n.dom.Selection(r.dom,r.getWin(),r.serializer);r.formatter=new n.Formatter(this);r.formatter.register({alignleft:[{selector:"p,h1,h2,h3,h4,h5,h6,td,th,div,ul,ol,li",styles:{textAlign:"left"}},{selector:"img,table",collapsed:false,styles:{"float":"left"}}],aligncenter:[{selector:"p,h1,h2,h3,h4,h5,h6,td,th,div,ul,ol,li",styles:{textAlign:"center"}},{selector:"img",collapsed:false,styles:{display:"block",marginLeft:"auto",marginRight:"auto"}},{selector:"table",collapsed:false,styles:{marginLeft:"auto",marginRight:"auto"}}],alignright:[{selector:"p,h1,h2,h3,h4,h5,h6,td,th,div,ul,ol,li",styles:{textAlign:"right"}},{selector:"img,table",collapsed:false,styles:{"float":"right"}}],alignfull:[{selector:"p,h1,h2,h3,h4,h5,h6,td,th,div,ul,ol,li",styles:{textAlign:"justify"}}],bold:[{inline:"strong",remove:"all"},{inline:"span",styles:{fontWeight:"bold"}},{inline:"b",remove:"all"}],italic:[{inline:"em",remove:"all"},{inline:"span",styles:{fontStyle:"italic"}},{inline:"i",remove:"all"}],underline:[{inline:"span",styles:{textDecoration:"underline"},exact:true},{inline:"u",remove:"all"}],strikethrough:[{inline:"span",styles:{textDecoration:"line-through"},exact:true},{inline:"strike",remove:"all"}],forecolor:{inline:"span",styles:{color:"%value"},wrap_links:false},hilitecolor:{inline:"span",styles:{backgroundColor:"%value"},wrap_links:false},fontname:{inline:"span",styles:{fontFamily:"%value"}},fontsize:{inline:"span",styles:{fontSize:"%value"}},fontsize_class:{inline:"span",attributes:{"class":"%value"}},blockquote:{block:"blockquote",wrapper:1,remove:"all"},subscript:{inline:"sub"},superscript:{inline:"sup"},link:{inline:"a",selector:"a",remove:"all",split:true,deep:true,onmatch:function(s){return true},onformat:function(A,s,t){i(t,function(C,B){r.dom.setAttrib(A,B,C)})}},removeformat:[{selector:"b,strong,em,i,font,u,strike",remove:"all",split:true,expand:false,block_expand:true,deep:true},{selector:"span",attributes:["style","class"],remove:"empty",split:true,expand:false,deep:true},{selector:"*",attributes:["style","class"],split:false,expand:false,deep:true}]});i("p h1 h2 h3 h4 h5 h6 div address pre div code dt dd samp".split(/\s/),function(s){r.formatter.register(s,{block:s,remove:"all"})});r.formatter.register(r.settings.formats);r.undoManager=new n.UndoManager(r);r.undoManager.onAdd.add(function(t,s){if(t.hasUndo()){return r.onChange.dispatch(r,s,t)}});r.undoManager.onUndo.add(function(t,s){return r.onUndo.dispatch(r,s,t)});r.undoManager.onRedo.add(function(t,s){return r.onRedo.dispatch(r,s,t)});r.forceBlocks=new n.ForceBlocks(r,{forced_root_block:x.forced_root_block});r.editorCommands=new n.EditorCommands(r);r.serializer.onPreProcess.add(function(s,t){return r.onPreProcess.dispatch(r,t,s)});r.serializer.onPostProcess.add(function(s,t){return r.onPostProcess.dispatch(r,t,s)});r.onPreInit.dispatch(r);if(!x.gecko_spellcheck){r.getBody().spellcheck=0}if(!x.readonly){r._addEvents()}r.controlManager.onPostRender.dispatch(r,r.controlManager);r.onPostRender.dispatch(r);r.quirks=new n.util.Quirks(this);if(x.directionality){r.getBody().dir=x.directionality}if(x.nowrap){r.getBody().style.whiteSpace="nowrap"}if(x.handle_node_change_callback){r.onNodeChange.add(function(t,s,A){r.execCallback("handle_node_change_callback",r.id,A,-1,-1,true,r.selection.isCollapsed())})}if(x.save_callback){r.onSaveContent.add(function(s,A){var t=r.execCallback("save_callback",r.id,A.content,r.getBody());if(t){A.content=t}})}if(x.onchange_callback){r.onChange.add(function(t,s){r.execCallback("onchange_callback",r,s)})}if(x.protect){r.onBeforeSetContent.add(function(s,t){if(x.protect){i(x.protect,function(A){t.content=t.content.replace(A,function(B){return"<!--mce:protected "+escape(B)+"-->"})})}})}if(x.convert_newlines_to_brs){r.onBeforeSetContent.add(function(s,t){if(t.initial){t.content=t.content.replace(/\r?\n/g,"<br />")}})}if(x.preformatted){r.onPostProcess.add(function(s,t){t.content=t.content.replace(/^\s*<pre.*?>/,"");t.content=t.content.replace(/<\/pre>\s*$/,"");if(t.set){t.content='<pre class="mceItemHidden">'+t.content+"</pre>"}})}if(x.verify_css_classes){r.serializer.attribValueFilter=function(C,A){var B,t;if(C=="class"){if(!r.classesRE){t=r.dom.getClasses();if(t.length>0){B="";i(t,function(s){B+=(B?"|":"")+s["class"]});r.classesRE=new RegExp("("+B+")","gi")}}return !r.classesRE||/(\bmceItem\w+\b|\bmceTemp\w+\b)/g.test(A)||r.classesRE.test(A)?A:""}return A}}if(x.cleanup_callback){r.onBeforeSetContent.add(function(s,t){t.content=r.execCallback("cleanup_callback","insert_to_editor",t.content,t)});r.onPreProcess.add(function(s,t){if(t.set){r.execCallback("cleanup_callback","insert_to_editor_dom",t.node,t)}if(t.get){r.execCallback("cleanup_callback","get_from_editor_dom",t.node,t)}});r.onPostProcess.add(function(s,t){if(t.set){t.content=r.execCallback("cleanup_callback","insert_to_editor",t.content,t)}if(t.get){t.content=r.execCallback("cleanup_callback","get_from_editor",t.content,t)}})}if(x.save_callback){r.onGetContent.add(function(s,t){if(t.save){t.content=r.execCallback("save_callback",r.id,t.content,r.getBody())}})}if(x.handle_event_callback){r.onEvent.add(function(s,t,A){if(r.execCallback("handle_event_callback",t,s,A)===false){k.cancel(t)}})}r.onSetContent.add(function(){r.addVisual(r.getBody())});if(x.padd_empty_editor){r.onPostProcess.add(function(s,t){t.content=t.content.replace(/^(<p[^>]*>(&nbsp;|&#160;|\s|\u00a0|)<\/p>[\r\n]*|<br \/>[\r\n]*)$/,"")})}if(a){function u(s,t){i(s.dom.select("a"),function(B){var A=B.parentNode;if(s.dom.isBlock(A)&&A.lastChild===B){s.dom.add(A,"br",{"data-mce-bogus":1})}})}r.onExecCommand.add(function(s,t){if(t==="CreateLink"){u(s)}});r.onSetContent.add(r.selection.onSetContent.add(u))}r.load({initial:true,format:"html"});r.startContent=r.getContent({format:"raw"});r.undoManager.add();r.initialized=true;r.onInit.dispatch(r);r.execCallback("setupcontent_callback",r.id,r.getBody(),r.getDoc());r.execCallback("init_instance_callback",r);r.focus(true);r.nodeChanged({initial:1});i(r.contentCSS,function(s){r.dom.loadCSS(s)});if(x.auto_focus){setTimeout(function(){var s=n.get(x.auto_focus);s.selection.select(s.getBody(),1);s.selection.collapse(1);s.getBody().focus();s.getWin().focus()},100)}y=null},focus:function(v){var z,r=this,u=r.selection,y=r.settings.content_editable,s,q,x=r.getDoc();if(!v){s=u.getRng();if(s.item){q=s.item(0)}r._refreshContentEditable();if(!y){r.getWin().focus()}if(n.isGecko){r.getBody().focus()}if(q&&q.ownerDocument==x){s=x.body.createControlRange();s.addElement(q);s.select()}}if(n.activeEditor!=r){if((z=n.activeEditor)!=null){z.onDeactivate.dispatch(z,r)}r.onActivate.dispatch(r,z)}n._setActive(r)},execCallback:function(v){var q=this,u=q.settings[v],r;if(!u){return}if(q.callbackLookup&&(r=q.callbackLookup[v])){u=r.func;r=r.scope}if(d(u,"string")){r=u.replace(/\.\w+$/,"");r=r?n.resolve(r):0;u=n.resolve(u);q.callbackLookup=q.callbackLookup||{};q.callbackLookup[v]={func:u,scope:r}}return u.apply(r||q,Array.prototype.slice.call(arguments,1))},translate:function(q){var t=this.settings.language||"en",r=n.i18n;if(!q){return""}return r[t+"."+q]||q.replace(/{\#([^}]+)\}/g,function(u,s){return r[t+"."+s]||"{#"+s+"}"})},getLang:function(r,q){return n.i18n[(this.settings.language||"en")+"."+r]||(d(q)?q:"{#"+r+"}")},getParam:function(x,s,q){var t=n.trim,r=d(this.settings[x])?this.settings[x]:s,u;if(q==="hash"){u={};if(d(r,"string")){i(r.indexOf("=")>0?r.split(/[;,](?![^=;,]*(?:[;,]|$))/):r.split(","),function(y){y=y.split("=");if(y.length>1){u[t(y[0])]=t(y[1])}else{u[t(y[0])]=t(y)}})}else{u=r}return u}return r},nodeChanged:function(u){var q=this,r=q.selection,v=r.getStart()||q.getBody();if(q.initialized){u=u||{};v=b&&v.ownerDocument!=q.getDoc()?q.getBody():v;u.parents=[];q.dom.getParent(v,function(s){if(s.nodeName=="BODY"){return true}u.parents.push(s)});q.onNodeChange.dispatch(q,u?u.controlManager||q.controlManager:q.controlManager,v,r.isCollapsed(),u)}},addButton:function(u,r){var q=this;q.buttons=q.buttons||{};q.buttons[u]=r},addCommand:function(q,s,r){this.execCommands[q]={func:s,scope:r||this}},addQueryStateHandler:function(q,s,r){this.queryStateCommands[q]={func:s,scope:r||this}},addQueryValueHandler:function(q,s,r){this.queryValueCommands[q]={func:s,scope:r||this}},addShortcut:function(s,v,q,u){var r=this,x;if(!r.settings.custom_shortcuts){return false}r.shortcuts=r.shortcuts||{};if(d(q,"string")){x=q;q=function(){r.execCommand(x,false,null)}}if(d(q,"object")){x=q;q=function(){r.execCommand(x[0],x[1],x[2])}}i(g(s),function(t){var y={func:q,scope:u||this,desc:v,alt:false,ctrl:false,shift:false};i(g(t,"+"),function(z){switch(z){case"alt":case"ctrl":case"shift":y[z]=true;break;default:y.charCode=z.charCodeAt(0);y.keyCode=z.toUpperCase().charCodeAt(0)}});r.shortcuts[(y.ctrl?"ctrl":"")+","+(y.alt?"alt":"")+","+(y.shift?"shift":"")+","+y.keyCode]=y});return true},execCommand:function(y,x,A,q){var u=this,v=0,z,r;if(!/^(mceAddUndoLevel|mceEndUndoLevel|mceBeginUndoLevel|mceRepaint|SelectAll)$/.test(y)&&(!q||!q.skip_focus)){u.focus()}z={};u.onBeforeExecCommand.dispatch(u,y,x,A,z);if(z.terminate){return false}if(u.execCallback("execcommand_callback",u.id,u.selection.getNode(),y,x,A)){u.onExecCommand.dispatch(u,y,x,A,q);return true}if(z=u.execCommands[y]){r=z.func.call(z.scope,x,A);if(r!==true){u.onExecCommand.dispatch(u,y,x,A,q);return r}}i(u.plugins,function(s){if(s.execCommand&&s.execCommand(y,x,A)){u.onExecCommand.dispatch(u,y,x,A,q);v=1;return false}});if(v){return true}if(u.theme&&u.theme.execCommand&&u.theme.execCommand(y,x,A)){u.onExecCommand.dispatch(u,y,x,A,q);return true}if(u.editorCommands.execCommand(y,x,A)){u.onExecCommand.dispatch(u,y,x,A,q);return true}u.getDoc().execCommand(y,x,A);u.onExecCommand.dispatch(u,y,x,A,q)},queryCommandState:function(v){var r=this,x,u;if(r._isHidden()){return}if(x=r.queryStateCommands[v]){u=x.func.call(x.scope);if(u!==true){return u}}x=r.editorCommands.queryCommandState(v);if(x!==-1){return x}try{return this.getDoc().queryCommandState(v)}catch(q){}},queryCommandValue:function(x){var r=this,v,u;if(r._isHidden()){return}if(v=r.queryValueCommands[x]){u=v.func.call(v.scope);if(u!==true){return u}}v=r.editorCommands.queryCommandValue(x);if(d(v)){return v}try{return this.getDoc().queryCommandValue(x)}catch(q){}},show:function(){var q=this;o.show(q.getContainer());o.hide(q.id);q.load()},hide:function(){var q=this,r=q.getDoc();if(b&&r){r.execCommand("SelectAll")}q.save();o.hide(q.getContainer());o.setStyle(q.id,"display",q.orgDisplay)},isHidden:function(){return !o.isHidden(this.id)},setProgressState:function(q,r,s){this.onSetProgressState.dispatch(this,q,r,s);return q},load:function(u){var q=this,s=q.getElement(),r;if(s){u=u||{};u.load=true;r=q.setContent(d(s.value)?s.value:s.innerHTML,u);u.element=s;if(!u.no_events){q.onLoadContent.dispatch(q,u)}u.element=s=null;return r}},save:function(v){var q=this,u=q.getElement(),r,s;if(!u||!q.initialized){return}v=v||{};v.save=true;if(!v.no_events){q.undoManager.typing=false;q.undoManager.add()}v.element=u;r=v.content=q.getContent(v);if(!v.no_events){q.onSaveContent.dispatch(q,v)}r=v.content;if(!/TEXTAREA|INPUT/i.test(u.nodeName)){u.innerHTML=r;if(s=o.getParent(q.id,"form")){i(s.elements,function(t){if(t.name==q.id){t.value=r;return false}})}}else{u.value=r}v.element=u=null;return r},setContent:function(v,t){var s=this,r,q=s.getBody(),u;t=t||{};t.format=t.format||"html";t.set=true;t.content=v;if(!t.no_events){s.onBeforeSetContent.dispatch(s,t)}v=t.content;if(!n.isIE&&(v.length===0||/^\s+$/.test(v))){u=s.settings.forced_root_block;if(u){v="<"+u+'><br data-mce-bogus="1"></'+u+">"}else{v='<br data-mce-bogus="1">'}q.innerHTML=v;s.selection.select(q,true);s.selection.collapse(true);return}if(t.format!=="raw"){v=new n.html.Serializer({},s.schema).serialize(s.parser.parse(v))}t.content=n.trim(v);s.dom.setHTML(q,t.content);if(!t.no_events){s.onSetContent.dispatch(s,t)}s.selection.normalize();return t.content},getContent:function(r){var q=this,s;r=r||{};r.format=r.format||"html";r.get=true;if(!r.no_events){q.onBeforeGetContent.dispatch(q,r)}if(r.format=="raw"){s=q.getBody().innerHTML}else{s=q.serializer.serialize(q.getBody(),r)}r.content=n.trim(s);if(!r.no_events){q.onGetContent.dispatch(q,r)}return r.content},isDirty:function(){var q=this;return n.trim(q.startContent)!=n.trim(q.getContent({format:"raw",no_events:1}))&&!q.isNotDirty},getContainer:function(){var q=this;if(!q.container){q.container=o.get(q.editorContainer||q.id+"_parent")}return q.container},getContentAreaContainer:function(){return this.contentAreaContainer},getElement:function(){return o.get(this.settings.content_element||this.id)},getWin:function(){var q=this,r;if(!q.contentWindow){r=o.get(q.id+"_ifr");if(r){q.contentWindow=r.contentWindow}}return q.contentWindow},getDoc:function(){var r=this,q;if(!r.contentDocument){q=r.getWin();if(q){r.contentDocument=q.document}}return r.contentDocument},getBody:function(){return this.bodyElement||this.getDoc().body},convertURL:function(q,y,x){var r=this,v=r.settings;if(v.urlconverter_callback){return r.execCallback("urlconverter_callback",q,x,true,y)}if(!v.convert_urls||(x&&x.nodeName=="LINK")||q.indexOf("file:")===0){return q}if(v.relative_urls){return r.documentBaseURI.toRelative(q)}q=r.documentBaseURI.toAbsolute(q,v.remove_script_host);return q},addVisual:function(u){var q=this,r=q.settings;u=u||q.getBody();if(!d(q.hasVisual)){q.hasVisual=r.visual}i(q.dom.select("table,a",u),function(t){var s;switch(t.nodeName){case"TABLE":s=q.dom.getAttrib(t,"border");if(!s||s=="0"){if(q.hasVisual){q.dom.addClass(t,r.visual_table_class)}else{q.dom.removeClass(t,r.visual_table_class)}}return;case"A":s=q.dom.getAttrib(t,"name");if(s){if(q.hasVisual){q.dom.addClass(t,"mceItemAnchor")}else{q.dom.removeClass(t,"mceItemAnchor")}}return}});q.onVisualAid.dispatch(q,u,q.hasVisual)},remove:function(){var q=this,r=q.getContainer();q.removed=1;q.hide();q.execCallback("remove_instance_callback",q);q.onRemove.dispatch(q);q.onExecCommand.listeners=[];n.remove(q);o.remove(r)},destroy:function(r){var q=this;if(q.destroyed){return}if(!r){n.removeUnload(q.destroy);tinyMCE.onBeforeUnload.remove(q._beforeUnload);if(q.theme&&q.theme.destroy){q.theme.destroy()}q.controlManager.destroy();q.selection.destroy();q.dom.destroy();if(!q.settings.content_editable){k.clear(q.getWin());k.clear(q.getDoc())}k.clear(q.getBody());k.clear(q.formElement)}if(q.formElement){q.formElement.submit=q.formElement._mceOldSubmit;q.formElement._mceOldSubmit=null}q.contentAreaContainer=q.formElement=q.container=q.settings.content_element=q.bodyElement=q.contentDocument=q.contentWindow=null;if(q.selection){q.selection=q.selection.win=q.selection.dom=q.selection.dom.doc=null}q.destroyed=1},_addEvents:function(){var C=this,u,D=C.settings,r=C.dom,y={mouseup:"onMouseUp",mousedown:"onMouseDown",click:"onClick",keyup:"onKeyUp",keydown:"onKeyDown",keypress:"onKeyPress",submit:"onSubmit",reset:"onReset",contextmenu:"onContextMenu",dblclick:"onDblClick",paste:"onPaste"};function q(t,E){var s=t.type;if(C.removed){return}if(C.onEvent.dispatch(C,t,E)!==false){C[y[t.fakeType||t.type]].dispatch(C,t,E)}}i(y,function(t,s){switch(s){case"contextmenu":r.bind(C.getDoc(),s,q);break;case"paste":r.bind(C.getBody(),s,function(E){q(E)});break;case"submit":case"reset":r.bind(C.getElement().form||o.getParent(C.id,"form"),s,q);break;default:r.bind(D.content_editable?C.getBody():C.getDoc(),s,q)}});r.bind(D.content_editable?C.getBody():(a?C.getDoc():C.getWin()),"focus",function(s){C.focus(true)});if(n.isGecko){r.bind(C.getDoc(),"DOMNodeInserted",function(t){var s;t=t.target;if(t.nodeType===1&&t.nodeName==="IMG"&&(s=t.getAttribute("data-mce-src"))){t.src=C.documentBaseURI.toAbsolute(s)}})}if(a){function v(){var F=this,H=F.getDoc(),G=F.settings;if(a&&!G.readonly){F._refreshContentEditable();try{H.execCommand("styleWithCSS",0,false)}catch(E){if(!F._isHidden()){try{H.execCommand("useCSS",0,true)}catch(E){}}}if(!G.table_inline_editing){try{H.execCommand("enableInlineTableEditing",false,false)}catch(E){}}if(!G.object_resizing){try{H.execCommand("enableObjectResizing",false,false)}catch(E){}}}}C.onBeforeExecCommand.add(v);C.onMouseDown.add(v)}C.onMouseUp.add(C.nodeChanged);C.onKeyUp.add(function(s,t){var E=t.keyCode;if((E>=33&&E<=36)||(E>=37&&E<=40)||E==13||E==45||E==46||E==8||(n.isMac&&(E==91||E==93))||t.ctrlKey){C.nodeChanged()}});C.onKeyDown.add(function(t,E){if(E.keyCode!=j.BACKSPACE){return}var s=t.selection.getRng();if(!s.collapsed){return}var G=s.startContainer;var F=s.startOffset;while(G&&G.nodeType&&G.nodeType!=1&&G.parentNode){G=G.parentNode}if(G&&G.parentNode&&G.parentNode.tagName==="BLOCKQUOTE"&&G.parentNode.firstChild==G&&F==0){t.formatter.toggle("blockquote",null,G.parentNode);s.setStart(G,0);s.setEnd(G,0);t.selection.setRng(s);t.selection.collapse(false)}});C.onReset.add(function(){C.setContent(C.startContent,{format:"raw"})});if(D.custom_shortcuts){if(D.custom_undo_redo_keyboard_shortcuts){C.addShortcut("ctrl+z",C.getLang("undo_desc"),"Undo");C.addShortcut("ctrl+y",C.getLang("redo_desc"),"Redo")}C.addShortcut("ctrl+b",C.getLang("bold_desc"),"Bold");C.addShortcut("ctrl+i",C.getLang("italic_desc"),"Italic");C.addShortcut("ctrl+u",C.getLang("underline_desc"),"Underline");for(u=1;u<=6;u++){C.addShortcut("ctrl+"+u,"",["FormatBlock",false,"h"+u])}C.addShortcut("ctrl+7","",["FormatBlock",false,"p"]);C.addShortcut("ctrl+8","",["FormatBlock",false,"div"]);C.addShortcut("ctrl+9","",["FormatBlock",false,"address"]);function x(t){var s=null;if(!t.altKey&&!t.ctrlKey&&!t.metaKey){return s}i(C.shortcuts,function(E){if(n.isMac&&E.ctrl!=t.metaKey){return}else{if(!n.isMac&&E.ctrl!=t.ctrlKey){return}}if(E.alt!=t.altKey){return}if(E.shift!=t.shiftKey){return}if(t.keyCode==E.keyCode||(t.charCode&&t.charCode==E.charCode)){s=E;return false}});return s}C.onKeyUp.add(function(s,t){var E=x(t);if(E){return k.cancel(t)}});C.onKeyPress.add(function(s,t){var E=x(t);if(E){return k.cancel(t)}});C.onKeyDown.add(function(s,t){var E=x(t);if(E){E.func.call(E.scope);return k.cancel(t)}})}if(n.isIE){r.bind(C.getDoc(),"controlselect",function(E){var t=C.resizeInfo,s;E=E.target;if(E.nodeName!=="IMG"){return}if(t){r.unbind(t.node,t.ev,t.cb)}if(!r.hasClass(E,"mceItemNoResize")){ev="resizeend";s=r.bind(E,ev,function(G){var F;G=G.target;if(F=r.getStyle(G,"width")){r.setAttrib(G,"width",F.replace(/[^0-9%]+/g,""));r.setStyle(G,"width","")}if(F=r.getStyle(G,"height")){r.setAttrib(G,"height",F.replace(/[^0-9%]+/g,""));r.setStyle(G,"height","")}})}else{ev="resizestart";s=r.bind(E,"resizestart",k.cancel,k)}t=C.resizeInfo={node:E,ev:ev,cb:s}})}if(n.isOpera){C.onClick.add(function(s,t){k.prevent(t)})}if(D.custom_undo_redo){function z(){C.undoManager.typing=false;C.undoManager.add()}r.bind(C.getDoc(),"focusout",function(s){if(!C.removed&&C.undoManager.typing){z()}});C.dom.bind(C.dom.getRoot(),"dragend",function(s){z()});C.onKeyUp.add(function(s,E){var t=E.keyCode;if((t>=33&&t<=36)||(t>=37&&t<=40)||t==13||t==45||E.ctrlKey){z()}});C.onKeyDown.add(function(s,F){var E=F.keyCode,t;if(E==8){t=C.getDoc().selection;if(t&&t.createRange&&t.createRange().item){C.undoManager.beforeChange();s.dom.remove(t.createRange().item(0));z();return k.cancel(F)}}if((E>=33&&E<=36)||(E>=37&&E<=40)||E==13||E==45){if(n.isIE&&E==13){C.undoManager.beforeChange()}if(C.undoManager.typing){z()}return}if((E<16||E>20)&&E!=224&&E!=91&&!C.undoManager.typing){C.undoManager.beforeChange();C.undoManager.typing=true;C.undoManager.add()}});C.onMouseDown.add(function(){if(C.undoManager.typing){z()}})}if(n.isGecko){function B(){var s=C.dom.getAttribs(C.selection.getStart().cloneNode(false));return function(){var t=C.selection.getStart();if(t!==C.getBody()){C.dom.setAttrib(t,"style",null);i(s,function(E){t.setAttributeNode(E.cloneNode(true))})}}}function A(){var t=C.selection;return !t.isCollapsed()&&t.getStart()!=t.getEnd()}C.onKeyPress.add(function(s,E){var t;if((E.keyCode==8||E.keyCode==46)&&A()){t=B();C.getDoc().execCommand("delete",false,null);t();return k.cancel(E)}});C.dom.bind(C.getDoc(),"cut",function(t){var s;if(A()){s=B();C.onKeyUp.addToTop(k.cancel,k);setTimeout(function(){s();C.onKeyUp.remove(k.cancel,k)},0)}})}},_refreshContentEditable:function(){var r=this,q,s;if(r._isHidden()){q=r.getBody();s=q.parentNode;s.removeChild(q);s.appendChild(q);q.focus()}},_isHidden:function(){var q;if(!a){return 0}q=this.selection.getSel();return(!q||!q.rangeCount||q.rangeCount==0)}})})(tinymce);(function(c){var d=c.each,e,a=true,b=false;c.EditorCommands=function(n){var m=n.dom,p=n.selection,j={state:{},exec:{},value:{}},k=n.settings,q=n.formatter,o;function r(z,y,x){var v;z=z.toLowerCase();if(v=j.exec[z]){v(z,y,x);return a}return b}function l(x){var v;x=x.toLowerCase();if(v=j.state[x]){return v(x)}return -1}function h(x){var v;x=x.toLowerCase();if(v=j.value[x]){return v(x)}return b}function u(v,x){x=x||"exec";d(v,function(z,y){d(y.toLowerCase().split(","),function(A){j[x][A]=z})})}c.extend(this,{execCommand:r,queryCommandState:l,queryCommandValue:h,addCommands:u});function f(y,x,v){if(x===e){x=b}if(v===e){v=null}return n.getDoc().execCommand(y,x,v)}function t(v){return q.match(v)}function s(v,x){q.toggle(v,x?{value:x}:e)}function i(v){o=p.getBookmark(v)}function g(){p.moveToBookmark(o)}u({"mceResetDesignMode,mceBeginUndoLevel":function(){},"mceEndUndoLevel,mceAddUndoLevel":function(){n.undoManager.add()},"Cut,Copy,Paste":function(z){var y=n.getDoc(),v;try{f(z)}catch(x){v=a}if(v||!y.queryCommandSupported(z)){if(c.isGecko){n.windowManager.confirm(n.getLang("clipboard_msg"),function(A){if(A){open("http://www.mozilla.org/editor/midasdemo/securityprefs.html","_blank")}})}else{n.windowManager.alert(n.getLang("clipboard_no_support"))}}},unlink:function(v){if(p.isCollapsed()){p.select(p.getNode())}f(v);p.collapse(b)},"JustifyLeft,JustifyCenter,JustifyRight,JustifyFull":function(v){var x=v.substring(7);d("left,center,right,full".split(","),function(y){if(x!=y){q.remove("align"+y)}});s("align"+x);r("mceRepaint")},"InsertUnorderedList,InsertOrderedList":function(y){var v,x;f(y);v=m.getParent(p.getNode(),"ol,ul");if(v){x=v.parentNode;if(/^(H[1-6]|P|ADDRESS|PRE)$/.test(x.nodeName)){i();m.split(x,v);g()}}},"Bold,Italic,Underline,Strikethrough,Superscript,Subscript":function(v){s(v)},"ForeColor,HiliteColor,FontName":function(y,x,v){s(y,v)},FontSize:function(z,y,x){var v,A;if(x>=1&&x<=7){A=c.explode(k.font_size_style_values);v=c.explode(k.font_size_classes);if(v){x=v[x-1]||x}else{x=A[x-1]||x}}s(z,x)},RemoveFormat:function(v){q.remove(v)},mceBlockQuote:function(v){s("blockquote")},FormatBlock:function(y,x,v){return s(v||"p")},mceCleanup:function(){var v=p.getBookmark();n.setContent(n.getContent({cleanup:a}),{cleanup:a});p.moveToBookmark(v)},mceRemoveNode:function(z,y,x){var v=x||p.getNode();if(v!=n.getBody()){i();n.dom.remove(v,a);g()}},mceSelectNodeDepth:function(z,y,x){var v=0;m.getParent(p.getNode(),function(A){if(A.nodeType==1&&v++==x){p.select(A);return b}},n.getBody())},mceSelectNode:function(y,x,v){p.select(v)},mceInsertContent:function(B,I,K){var y,J,E,z,F,G,D,C,L,x,A,M,v,H;y=n.parser;J=new c.html.Serializer({},n.schema);v='<span id="mce_marker" data-mce-type="bookmark">\uFEFF</span>';G={content:K,format:"html"};p.onBeforeSetContent.dispatch(p,G);K=G.content;if(K.indexOf("{$caret}")==-1){K+="{$caret}"}K=K.replace(/\{\$caret\}/,v);if(!p.isCollapsed()){n.getDoc().execCommand("Delete",false,null)}E=p.getNode();G={context:E.nodeName.toLowerCase()};F=y.parse(K,G);A=F.lastChild;if(A.attr("id")=="mce_marker"){D=A;for(A=A.prev;A;A=A.walk(true)){if(A.type==3||!m.isBlock(A.name)){A.parent.insert(D,A,A.name==="br");break}}}if(!G.invalid){K=J.serialize(F);A=E.firstChild;M=E.lastChild;if(!A||(A===M&&A.nodeName==="BR")){m.setHTML(E,K)}else{p.setContent(K)}}else{p.setContent(v);E=n.selection.getNode();z=n.getBody();if(E.nodeType==9){E=A=z}else{A=E}while(A!==z){E=A;A=A.parentNode}K=E==z?z.innerHTML:m.getOuterHTML(E);K=J.serialize(y.parse(K.replace(/<span (id="mce_marker"|id=mce_marker).+?<\/span>/i,function(){return J.serialize(F)})));if(E==z){m.setHTML(z,K)}else{m.setOuterHTML(E,K)}}D=m.get("mce_marker");C=m.getRect(D);L=m.getViewPort(n.getWin());if((C.y+C.h>L.y+L.h||C.y<L.y)||(C.x>L.x+L.w||C.x<L.x)){H=c.isIE?n.getDoc().documentElement:n.getBody();H.scrollLeft=C.x;H.scrollTop=C.y-L.h+25}x=m.createRng();A=D.previousSibling;if(A&&A.nodeType==3){x.setStart(A,A.nodeValue.length)}else{x.setStartBefore(D);x.setEndBefore(D)}m.remove(D);p.setRng(x);p.onSetContent.dispatch(p,G);n.addVisual()},mceInsertRawHTML:function(y,x,v){p.setContent("tiny_mce_marker");n.setContent(n.getContent().replace(/tiny_mce_marker/g,function(){return v}))},mceSetContent:function(y,x,v){n.setContent(v)},"Indent,Outdent":function(z){var x,v,y;x=k.indentation;v=/[a-z%]+$/i.exec(x);x=parseInt(x);if(!l("InsertUnorderedList")&&!l("InsertOrderedList")){d(p.getSelectedBlocks(),function(A){if(z=="outdent"){y=Math.max(0,parseInt(A.style.paddingLeft||0)-x);m.setStyle(A,"paddingLeft",y?y+v:"")}else{m.setStyle(A,"paddingLeft",(parseInt(A.style.paddingLeft||0)+x)+v)}})}else{f(z)}},mceRepaint:function(){var x;if(c.isGecko){try{i(a);if(p.getSel()){p.getSel().selectAllChildren(n.getBody())}p.collapse(a);g()}catch(v){}}},mceToggleFormat:function(y,x,v){q.toggle(v)},InsertHorizontalRule:function(){n.execCommand("mceInsertContent",false,"<hr />")},mceToggleVisualAid:function(){n.hasVisual=!n.hasVisual;n.addVisual()},mceReplaceContent:function(y,x,v){n.execCommand("mceInsertContent",false,v.replace(/\{\$selection\}/g,p.getContent({format:"text"})))},mceInsertLink:function(z,y,x){var v;if(typeof(x)=="string"){x={href:x}}v=m.getParent(p.getNode(),"a");x.href=x.href.replace(" ","%20");if(!v||!x.href){q.remove("link")}if(x.href){q.apply("link",x,v)}},selectAll:function(){var x=m.getRoot(),v=m.createRng();v.setStart(x,0);v.setEnd(x,x.childNodes.length);n.selection.setRng(v)}});u({"JustifyLeft,JustifyCenter,JustifyRight,JustifyFull":function(z){var x="align"+z.substring(7);var v=p.isCollapsed()?[p.getNode()]:p.getSelectedBlocks();var y=c.map(v,function(A){return !!q.matchNode(A,x)});return c.inArray(y,a)!==-1},"Bold,Italic,Underline,Strikethrough,Superscript,Subscript":function(v){return t(v)},mceBlockQuote:function(){return t("blockquote")},Outdent:function(){var v;if(k.inline_styles){if((v=m.getParent(p.getStart(),m.isBlock))&&parseInt(v.style.paddingLeft)>0){return a}if((v=m.getParent(p.getEnd(),m.isBlock))&&parseInt(v.style.paddingLeft)>0){return a}}return l("InsertUnorderedList")||l("InsertOrderedList")||(!k.inline_styles&&!!m.getParent(p.getNode(),"BLOCKQUOTE"))},"InsertUnorderedList,InsertOrderedList":function(v){return m.getParent(p.getNode(),v=="insertunorderedlist"?"UL":"OL")}},"state");u({"FontSize,FontName":function(y){var x=0,v;if(v=m.getParent(p.getNode(),"span")){if(y=="fontsize"){x=v.style.fontSize}else{x=v.style.fontFamily.replace(/, /g,",").replace(/[\'\"]/g,"").toLowerCase()}}return x}},"value");if(k.custom_undo_redo){u({Undo:function(){n.undoManager.undo()},Redo:function(){n.undoManager.redo()}})}}})(tinymce);(function(b){var a=b.util.Dispatcher;b.UndoManager=function(f){var d,e=0,h=[],c;function g(){return b.trim(f.getContent({format:"raw",no_events:1}))}return d={typing:false,onAdd:new a(d),onUndo:new a(d),onRedo:new a(d),beforeChange:function(){c=f.selection.getBookmark(2,true)},add:function(m){var j,k=f.settings,l;m=m||{};m.content=g();l=h[e];if(l&&l.content==m.content){return null}if(h[e]){h[e].beforeBookmark=c}if(k.custom_undo_redo_levels){if(h.length>k.custom_undo_redo_levels){for(j=0;j<h.length-1;j++){h[j]=h[j+1]}h.length--;e=h.length}}m.bookmark=f.selection.getBookmark(2,true);if(e<h.length-1){h.length=e+1}h.push(m);e=h.length-1;d.onAdd.dispatch(d,m);f.isNotDirty=0;return m},undo:function(){var k,j;if(d.typing){d.add();d.typing=false}if(e>0){k=h[--e];f.setContent(k.content,{format:"raw"});f.selection.moveToBookmark(k.beforeBookmark);d.onUndo.dispatch(d,k)}return k},redo:function(){var i;if(e<h.length-1){i=h[++e];f.setContent(i.content,{format:"raw"});f.selection.moveToBookmark(i.bookmark);d.onRedo.dispatch(d,i)}return i},clear:function(){h=[];e=0;d.typing=false},hasUndo:function(){return e>0||this.typing},hasRedo:function(){return e<h.length-1&&!this.typing}}}})(tinymce);(function(l){var j=l.dom.Event,c=l.isIE,a=l.isGecko,b=l.isOpera,i=l.each,h=l.extend,d=true,g=false;function k(o){var p,n,m;do{if(/^(SPAN|STRONG|B|EM|I|FONT|STRIKE|U)$/.test(o.nodeName)){if(p){n=o.cloneNode(false);n.appendChild(p);p=n}else{p=m=o.cloneNode(false)}p.removeAttribute("id")}}while(o=o.parentNode);if(p){return{wrapper:p,inner:m}}}function f(n,o){var m=o.ownerDocument.createRange();m.setStart(n.endContainer,n.endOffset);m.setEndAfter(o);return m.cloneContents().textContent.length==0}function e(o,q,m){var n,p;if(q.isEmpty(m)){n=q.getParent(m,"ul,ol");if(!q.getParent(n.parentNode,"ul,ol")){q.split(n,m);p=q.create("p",0,'<br data-mce-bogus="1" />');q.replace(p,m);o.select(p,1)}return g}return d}l.create("tinymce.ForceBlocks",{ForceBlocks:function(m){var n=this,o=m.settings,p;n.editor=m;n.dom=m.dom;p=(o.forced_root_block||"p").toLowerCase();o.element=p.toUpperCase();m.onPreInit.add(n.setup,n)},setup:function(){var n=this,m=n.editor,p=m.settings,u=m.dom,o=m.selection,q=m.schema.getBlockElements();if(p.forced_root_block){function v(){var y=o.getStart(),t=m.getBody(),s,z,D,F,E,x,A,B=-16777215;if(!y||y.nodeType!==1){return}while(y!=t){if(q[y.nodeName]){return}y=y.parentNode}s=o.getRng();if(s.setStart){z=s.startContainer;D=s.startOffset;F=s.endContainer;E=s.endOffset}else{if(s.item){s=m.getDoc().body.createTextRange();s.moveToElementText(s.item(0))}tmpRng=s.duplicate();tmpRng.collapse(true);D=tmpRng.move("character",B)*-1;if(!tmpRng.collapsed){tmpRng=s.duplicate();tmpRng.collapse(false);E=(tmpRng.move("character",B)*-1)-D}}for(y=t.firstChild;y;y){if(y.nodeType===3||(y.nodeType==1&&!q[y.nodeName])){if(!x){x=u.create(p.forced_root_block);y.parentNode.insertBefore(x,y)}A=y;y=y.nextSibling;x.appendChild(A)}else{x=null;y=y.nextSibling}}if(s.setStart){s.setStart(z,D);s.setEnd(F,E);o.setRng(s)}else{try{s=m.getDoc().body.createTextRange();s.moveToElementText(t);s.collapse(true);s.moveStart("character",D);if(E>0){s.moveEnd("character",E)}s.select()}catch(C){}}m.nodeChanged()}m.onKeyUp.add(v);m.onClick.add(v)}if(p.force_br_newlines){if(c){m.onKeyPress.add(function(s,t){var x;if(t.keyCode==13&&o.getNode().nodeName!="LI"){o.setContent('<br id="__" /> ',{format:"raw"});x=u.get("__");x.removeAttribute("id");o.select(x);o.collapse();return j.cancel(t)}})}}if(p.force_p_newlines){if(!c){m.onKeyPress.add(function(s,t){if(t.keyCode==13&&!t.shiftKey&&!n.insertPara(t)){j.cancel(t)}})}else{l.addUnload(function(){n._previousFormats=0});m.onKeyPress.add(function(s,t){n._previousFormats=0;if(t.keyCode==13&&!t.shiftKey&&s.selection.isCollapsed()&&p.keep_styles){n._previousFormats=k(s.selection.getStart())}});m.onKeyUp.add(function(t,y){if(y.keyCode==13&&!y.shiftKey){var x=t.selection.getStart(),s=n._previousFormats;if(!x.hasChildNodes()&&s){x=u.getParent(x,u.isBlock);if(x&&x.nodeName!="LI"){x.innerHTML="";if(n._previousFormats){x.appendChild(s.wrapper);s.inner.innerHTML="\uFEFF"}else{x.innerHTML="\uFEFF"}o.select(x,1);o.collapse(true);t.getDoc().execCommand("Delete",false,null);n._previousFormats=0}}}})}if(a){m.onKeyDown.add(function(s,t){if((t.keyCode==8||t.keyCode==46)&&!t.shiftKey){n.backspaceDelete(t,t.keyCode==8)}})}}if(l.isWebKit){function r(t){var s=o.getRng(),x,A=u.create("div",null," "),z,y=u.getViewPort(t.getWin()).h;s.insertNode(x=u.create("br"));s.setStartAfter(x);s.setEndAfter(x);o.setRng(s);if(o.getSel().focusNode==x.previousSibling){o.select(u.insertAfter(u.doc.createTextNode("\u00a0"),x));o.collapse(d)}u.insertAfter(A,x);z=u.getPos(A).y;u.remove(A);if(z>y){t.getWin().scrollTo(0,z)}}m.onKeyPress.add(function(s,t){if(t.keyCode==13&&(t.shiftKey||(p.force_br_newlines&&!u.getParent(o.getNode(),"h1,h2,h3,h4,h5,h6,ol,ul")))){r(s);j.cancel(t)}})}if(c){if(p.element!="P"){m.onKeyPress.add(function(s,t){n.lastElm=o.getNode().nodeName});m.onKeyUp.add(function(t,x){var z,y=o.getNode(),s=t.getBody();if(s.childNodes.length===1&&y.nodeName=="P"){y=u.rename(y,p.element);o.select(y);o.collapse();t.nodeChanged()}else{if(x.keyCode==13&&!x.shiftKey&&n.lastElm!="P"){z=u.getParent(y,"p");if(z){u.rename(z,p.element);t.nodeChanged()}}}})}}},getParentBlock:function(o){var m=this.dom;return m.getParent(o,m.isBlock)},insertPara:function(Q){var E=this,v=E.editor,M=v.dom,R=v.getDoc(),V=v.settings,F=v.selection.getSel(),G=F.getRangeAt(0),U=R.body;var J,K,H,O,N,q,o,u,z,m,C,T,p,x,I,L=M.getViewPort(v.getWin()),B,D,A;v.undoManager.beforeChange();J=R.createRange();J.setStart(F.anchorNode,F.anchorOffset);J.collapse(d);K=R.createRange();K.setStart(F.focusNode,F.focusOffset);K.collapse(d);H=J.compareBoundaryPoints(J.START_TO_END,K)<0;O=H?F.anchorNode:F.focusNode;N=H?F.anchorOffset:F.focusOffset;q=H?F.focusNode:F.anchorNode;o=H?F.focusOffset:F.anchorOffset;if(O===q&&/^(TD|TH)$/.test(O.nodeName)){if(O.firstChild.nodeName=="BR"){M.remove(O.firstChild)}if(O.childNodes.length==0){v.dom.add(O,V.element,null,"<br />");T=v.dom.add(O,V.element,null,"<br />")}else{I=O.innerHTML;O.innerHTML="";v.dom.add(O,V.element,null,I);T=v.dom.add(O,V.element,null,"<br />")}G=R.createRange();G.selectNodeContents(T);G.collapse(1);v.selection.setRng(G);return g}if(O==U&&q==U&&U.firstChild&&v.dom.isBlock(U.firstChild)){O=q=O.firstChild;N=o=0;J=R.createRange();J.setStart(O,0);K=R.createRange();K.setStart(q,0)}if(!R.body.hasChildNodes()){R.body.appendChild(M.create("br"))}O=O.nodeName=="HTML"?R.body:O;O=O.nodeName=="BODY"?O.firstChild:O;q=q.nodeName=="HTML"?R.body:q;q=q.nodeName=="BODY"?q.firstChild:q;u=E.getParentBlock(O);z=E.getParentBlock(q);m=u?u.nodeName:V.element;if(I=E.dom.getParent(u,"li,pre")){if(I.nodeName=="LI"){return e(v.selection,E.dom,I)}return d}if(u&&(u.nodeName=="CAPTION"||/absolute|relative|fixed/gi.test(M.getStyle(u,"position",1)))){m=V.element;u=null}if(z&&(z.nodeName=="CAPTION"||/absolute|relative|fixed/gi.test(M.getStyle(u,"position",1)))){m=V.element;z=null}if(/(TD|TABLE|TH|CAPTION)/.test(m)||(u&&m=="DIV"&&/left|right/gi.test(M.getStyle(u,"float",1)))){m=V.element;u=z=null}C=(u&&u.nodeName==m)?u.cloneNode(0):v.dom.create(m);T=(z&&z.nodeName==m)?z.cloneNode(0):v.dom.create(m);T.removeAttribute("id");if(/^(H[1-6])$/.test(m)&&f(G,u)){T=v.dom.create(V.element)}I=p=O;do{if(I==U||I.nodeType==9||E.dom.isBlock(I)||/(TD|TABLE|TH|CAPTION)/.test(I.nodeName)){break}p=I}while((I=I.previousSibling?I.previousSibling:I.parentNode));I=x=q;do{if(I==U||I.nodeType==9||E.dom.isBlock(I)||/(TD|TABLE|TH|CAPTION)/.test(I.nodeName)){break}x=I}while((I=I.nextSibling?I.nextSibling:I.parentNode));if(p.nodeName==m){J.setStart(p,0)}else{J.setStartBefore(p)}J.setEnd(O,N);C.appendChild(J.cloneContents()||R.createTextNode(""));try{K.setEndAfter(x)}catch(P){}K.setStart(q,o);T.appendChild(K.cloneContents()||R.createTextNode(""));G=R.createRange();if(!p.previousSibling&&p.parentNode.nodeName==m){G.setStartBefore(p.parentNode)}else{if(J.startContainer.nodeName==m&&J.startOffset==0){G.setStartBefore(J.startContainer)}else{G.setStart(J.startContainer,J.startOffset)}}if(!x.nextSibling&&x.parentNode.nodeName==m){G.setEndAfter(x.parentNode)}else{G.setEnd(K.endContainer,K.endOffset)}G.deleteContents();if(b){v.getWin().scrollTo(0,L.y)}if(C.firstChild&&C.firstChild.nodeName==m){C.innerHTML=C.firstChild.innerHTML}if(T.firstChild&&T.firstChild.nodeName==m){T.innerHTML=T.firstChild.innerHTML}function S(y,s){var r=[],X,W,t;y.innerHTML="";if(V.keep_styles){W=s;do{if(/^(SPAN|STRONG|B|EM|I|FONT|STRIKE|U)$/.test(W.nodeName)){X=W.cloneNode(g);M.setAttrib(X,"id","");r.push(X)}}while(W=W.parentNode)}if(r.length>0){for(t=r.length-1,X=y;t>=0;t--){X=X.appendChild(r[t])}r[0].innerHTML=b?"\u00a0":"<br />";return r[0]}else{y.innerHTML=b?"\u00a0":"<br />"}}if(M.isEmpty(C)){S(C,O)}if(M.isEmpty(T)){A=S(T,q)}if(b&&parseFloat(opera.version())<9.5){G.insertNode(C);G.insertNode(T)}else{G.insertNode(T);G.insertNode(C)}T.normalize();C.normalize();v.selection.select(T,true);v.selection.collapse(true);B=v.dom.getPos(T).y;if(B<L.y||B+25>L.y+L.h){v.getWin().scrollTo(0,B<L.y?B:B-L.h+25)}v.undoManager.add();return g},backspaceDelete:function(u,B){var C=this,s=C.editor,y=s.getBody(),q=s.dom,p,v=s.selection,o=v.getRng(),x=o.startContainer,p,z,A,m;if(!B&&o.collapsed&&x.nodeType==1&&o.startOffset==x.childNodes.length){m=new l.dom.TreeWalker(x.lastChild,x);for(p=x.lastChild;p;p=m.prev()){if(p.nodeType==3){o.setStart(p,p.nodeValue.length);o.collapse(true);v.setRng(o);return}}}if(x&&s.dom.isBlock(x)&&!/^(TD|TH)$/.test(x.nodeName)&&B){if(x.childNodes.length==0||(x.childNodes.length==1&&x.firstChild.nodeName=="BR")){p=x;while((p=p.previousSibling)&&!s.dom.isBlock(p)){}if(p){if(x!=y.firstChild){z=s.dom.doc.createTreeWalker(p,NodeFilter.SHOW_TEXT,null,g);while(A=z.nextNode()){p=A}o=s.getDoc().createRange();o.setStart(p,p.nodeValue?p.nodeValue.length:0);o.setEnd(p,p.nodeValue?p.nodeValue.length:0);v.setRng(o);s.dom.remove(x)}return j.cancel(u)}}}}})})(tinymce);(function(c){var b=c.DOM,a=c.dom.Event,d=c.each,e=c.extend;c.create("tinymce.ControlManager",{ControlManager:function(f,j){var h=this,g;j=j||{};h.editor=f;h.controls={};h.onAdd=new c.util.Dispatcher(h);h.onPostRender=new c.util.Dispatcher(h);h.prefix=j.prefix||f.id+"_";h._cls={};h.onPostRender.add(function(){d(h.controls,function(i){i.postRender()})})},get:function(f){return this.controls[this.prefix+f]||this.controls[f]},setActive:function(h,f){var g=null;if(g=this.get(h)){g.setActive(f)}return g},setDisabled:function(h,f){var g=null;if(g=this.get(h)){g.setDisabled(f)}return g},add:function(g){var f=this;if(g){f.controls[g.id]=g;f.onAdd.dispatch(g,f)}return g},createControl:function(i){var h,g=this,f=g.editor;d(f.plugins,function(j){if(j.createControl){h=j.createControl(i,g);if(h){return false}}});switch(i){case"|":case"separator":return g.createSeparator()}if(!h&&f.buttons&&(h=f.buttons[i])){return g.createButton(i,h)}return g.add(h)},createDropMenu:function(f,n,h){var m=this,i=m.editor,j,g,k,l;n=e({"class":"mceDropDown",constrain:i.settings.constrain_menus},n);n["class"]=n["class"]+" "+i.getParam("skin")+"Skin";if(k=i.getParam("skin_variant")){n["class"]+=" "+i.getParam("skin")+"Skin"+k.substring(0,1).toUpperCase()+k.substring(1)}f=m.prefix+f;l=h||m._cls.dropmenu||c.ui.DropMenu;j=m.controls[f]=new l(f,n);j.onAddItem.add(function(r,q){var p=q.settings;p.title=i.getLang(p.title,p.title);if(!p.onclick){p.onclick=function(o){if(p.cmd){i.execCommand(p.cmd,p.ui||false,p.value)}}}});i.onRemove.add(function(){j.destroy()});if(c.isIE){j.onShowMenu.add(function(){i.focus();g=i.selection.getBookmark(1)});j.onHideMenu.add(function(){if(g){i.selection.moveToBookmark(g);g=0}})}return m.add(j)},createListBox:function(f,n,h){var l=this,j=l.editor,i,k,m;if(l.get(f)){return null}n.title=j.translate(n.title);n.scope=n.scope||j;if(!n.onselect){n.onselect=function(o){j.execCommand(n.cmd,n.ui||false,o||n.value)}}n=e({title:n.title,"class":"mce_"+f,scope:n.scope,control_manager:l},n);f=l.prefix+f;function g(o){return o.settings.use_accessible_selects&&!c.isGecko}if(j.settings.use_native_selects||g(j)){k=new c.ui.NativeListBox(f,n)}else{m=h||l._cls.listbox||c.ui.ListBox;k=new m(f,n,j)}l.controls[f]=k;if(c.isWebKit){k.onPostRender.add(function(p,o){a.add(o,"mousedown",function(){j.bookmark=j.selection.getBookmark(1)});a.add(o,"focus",function(){j.selection.moveToBookmark(j.bookmark);j.bookmark=null})})}if(k.hideMenu){j.onMouseDown.add(k.hideMenu,k)}return l.add(k)},createButton:function(m,i,l){var h=this,g=h.editor,j,k,f;if(h.get(m)){return null}i.title=g.translate(i.title);i.label=g.translate(i.label);i.scope=i.scope||g;if(!i.onclick&&!i.menu_button){i.onclick=function(){g.execCommand(i.cmd,i.ui||false,i.value)}}i=e({title:i.title,"class":"mce_"+m,unavailable_prefix:g.getLang("unavailable",""),scope:i.scope,control_manager:h},i);m=h.prefix+m;if(i.menu_button){f=l||h._cls.menubutton||c.ui.MenuButton;k=new f(m,i,g);g.onMouseDown.add(k.hideMenu,k)}else{f=h._cls.button||c.ui.Button;k=new f(m,i,g)}return h.add(k)},createMenuButton:function(h,f,g){f=f||{};f.menu_button=1;return this.createButton(h,f,g)},createSplitButton:function(m,i,l){var h=this,g=h.editor,j,k,f;if(h.get(m)){return null}i.title=g.translate(i.title);i.scope=i.scope||g;if(!i.onclick){i.onclick=function(n){g.execCommand(i.cmd,i.ui||false,n||i.value)}}if(!i.onselect){i.onselect=function(n){g.execCommand(i.cmd,i.ui||false,n||i.value)}}i=e({title:i.title,"class":"mce_"+m,scope:i.scope,control_manager:h},i);m=h.prefix+m;f=l||h._cls.splitbutton||c.ui.SplitButton;k=h.add(new f(m,i,g));g.onMouseDown.add(k.hideMenu,k);return k},createColorSplitButton:function(f,n,h){var l=this,j=l.editor,i,k,m,g;if(l.get(f)){return null}n.title=j.translate(n.title);n.scope=n.scope||j;if(!n.onclick){n.onclick=function(o){if(c.isIE){g=j.selection.getBookmark(1)}j.execCommand(n.cmd,n.ui||false,o||n.value)}}if(!n.onselect){n.onselect=function(o){j.execCommand(n.cmd,n.ui||false,o||n.value)}}n=e({title:n.title,"class":"mce_"+f,menu_class:j.getParam("skin")+"Skin",scope:n.scope,more_colors_title:j.getLang("more_colors")},n);f=l.prefix+f;m=h||l._cls.colorsplitbutton||c.ui.ColorSplitButton;k=new m(f,n,j);j.onMouseDown.add(k.hideMenu,k);j.onRemove.add(function(){k.destroy()});if(c.isIE){k.onShowMenu.add(function(){j.focus();g=j.selection.getBookmark(1)});k.onHideMenu.add(function(){if(g){j.selection.moveToBookmark(g);g=0}})}return l.add(k)},createToolbar:function(k,h,j){var i,g=this,f;k=g.prefix+k;f=j||g._cls.toolbar||c.ui.Toolbar;i=new f(k,h,g.editor);if(g.get(k)){return null}return g.add(i)},createToolbarGroup:function(k,h,j){var i,g=this,f;k=g.prefix+k;f=j||this._cls.toolbarGroup||c.ui.ToolbarGroup;i=new f(k,h,g.editor);if(g.get(k)){return null}return g.add(i)},createSeparator:function(g){var f=g||this._cls.separator||c.ui.Separator;return new f()},setControlType:function(g,f){return this._cls[g.toLowerCase()]=f},destroy:function(){d(this.controls,function(f){f.destroy()});this.controls=null}})})(tinymce);(function(d){var a=d.util.Dispatcher,e=d.each,c=d.isIE,b=d.isOpera;d.create("tinymce.WindowManager",{WindowManager:function(f){var g=this;g.editor=f;g.onOpen=new a(g);g.onClose=new a(g);g.params={};g.features={}},open:function(z,h){var v=this,k="",n,m,i=v.editor.settings.dialog_type=="modal",q,o,j,g=d.DOM.getViewPort(),r;z=z||{};h=h||{};o=b?g.w:screen.width;j=b?g.h:screen.height;z.name=z.name||"mc_"+new Date().getTime();z.width=parseInt(z.width||320);z.height=parseInt(z.height||240);z.resizable=true;z.left=z.left||parseInt(o/2)-(z.width/2);z.top=z.top||parseInt(j/2)-(z.height/2);h.inline=false;h.mce_width=z.width;h.mce_height=z.height;h.mce_auto_focus=z.auto_focus;if(i){if(c){z.center=true;z.help=false;z.dialogWidth=z.width+"px";z.dialogHeight=z.height+"px";z.scroll=z.scrollbars||false}}e(z,function(p,f){if(d.is(p,"boolean")){p=p?"yes":"no"}if(!/^(name|url)$/.test(f)){if(c&&i){k+=(k?";":"")+f+":"+p}else{k+=(k?",":"")+f+"="+p}}});v.features=z;v.params=h;v.onOpen.dispatch(v,z,h);r=z.url||z.file;r=d._addVer(r);try{if(c&&i){q=1;window.showModalDialog(r,window,k)}else{q=window.open(r,z.name,k)}}catch(l){}if(!q){alert(v.editor.getLang("popup_blocked"))}},close:function(f){f.close();this.onClose.dispatch(this)},createInstance:function(i,h,g,m,l,k){var j=d.resolve(i);return new j(h,g,m,l,k)},confirm:function(h,f,i,g){g=g||window;f.call(i||this,g.confirm(this._decode(this.editor.getLang(h,h))))},alert:function(h,f,j,g){var i=this;g=g||window;g.alert(i._decode(i.editor.getLang(h,h)));if(f){f.call(j||i)}},resizeBy:function(f,g,h){h.resizeBy(f,g)},_decode:function(f){return d.DOM.decode(f).replace(/\\n/g,"\n")}})}(tinymce));(function(a){a.Formatter=function(V){var M={},P=a.each,c=V.dom,q=V.selection,t=a.dom.TreeWalker,K=new a.dom.RangeUtils(c),d=V.schema.isValidChild,F=c.isBlock,l=V.settings.forced_root_block,s=c.nodeIndex,E="\uFEFF",e=/^(src|href|style)$/,S=false,B=true,p;function z(W){return W instanceof Array}function m(X,W){return c.getParents(X,W,c.getRoot())}function b(W){return W.nodeType===1&&(W.face==="mceinline"||W.style.fontFamily==="mceinline")}function R(W){return W?M[W]:M}function k(W,X){if(W){if(typeof(W)!=="string"){P(W,function(Z,Y){k(Y,Z)})}else{X=X.length?X:[X];P(X,function(Y){if(Y.deep===p){Y.deep=!Y.selector}if(Y.split===p){Y.split=!Y.selector||Y.inline}if(Y.remove===p&&Y.selector&&!Y.inline){Y.remove="none"}if(Y.selector&&Y.inline){Y.mixed=true;Y.block_expand=true}if(typeof(Y.classes)==="string"){Y.classes=Y.classes.split(/\s+/)}});M[W]=X}}}var i=function(X){var W;V.dom.getParent(X,function(Y){W=V.dom.getStyle(Y,"text-decoration");return W&&W!=="none"});return W};var I=function(W){var X;if(W.nodeType===1&&W.parentNode&&W.parentNode.nodeType===1){X=i(W.parentNode);if(V.dom.getStyle(W,"color")&&X){V.dom.setStyle(W,"text-decoration",X)}else{if(V.dom.getStyle(W,"textdecoration")===X){V.dom.setStyle(W,"text-decoration",null)}}}};function T(Z,ag,ab){var ac=R(Z),ah=ac[0],af,X,ae,ad=q.isCollapsed();function W(al,ak){ak=ak||ah;if(al){if(ak.onformat){ak.onformat(al,ak,ag,ab)}P(ak.styles,function(an,am){c.setStyle(al,am,r(an,ag))});P(ak.attributes,function(an,am){c.setAttrib(al,am,r(an,ag))});P(ak.classes,function(am){am=r(am,ag);if(!c.hasClass(al,am)){c.addClass(al,am)}})}}function aa(){function am(at,aq){var ar=new t(aq);for(ab=ar.current();ab;ab=ar.prev()){if(ab.childNodes.length>1||ab==at){return ab}}}var al=V.selection.getRng();var ap=al.startContainer;var ak=al.endContainer;if(ap!=ak&&al.endOffset==0){var ao=am(ap,ak);var an=ao.nodeType==3?ao.length:ao.childNodes.length;al.setEnd(ao,an)}return al}function Y(an,at,aq,ap,al){var ak=[],am=-1,ar,av=-1,ao=-1,au;P(an.childNodes,function(ax,aw){if(ax.nodeName==="UL"||ax.nodeName==="OL"){am=aw;ar=ax;return false}});P(an.childNodes,function(ax,aw){if(ax.nodeName==="SPAN"&&c.getAttrib(ax,"data-mce-type")=="bookmark"){if(ax.id==at.id+"_start"){av=aw}else{if(ax.id==at.id+"_end"){ao=aw}}}});if(am<=0||(av<am&&ao>am)){P(a.grep(an.childNodes),al);return 0}else{au=aq.cloneNode(S);P(a.grep(an.childNodes),function(ax,aw){if((av<am&&aw<am)||(av>am&&aw>am)){ak.push(ax);ax.parentNode.removeChild(ax)}});if(av<am){an.insertBefore(au,ar)}else{if(av>am){an.insertBefore(au,ar.nextSibling)}}ap.push(au);P(ak,function(aw){au.appendChild(aw)});return au}}function ai(al,an,ap){var ak=[],ao,am;ao=ah.inline||ah.block;am=c.create(ao);W(am);K.walk(al,function(aq){var ar;function at(au){var ax=au.nodeName.toLowerCase(),aw=au.parentNode.nodeName.toLowerCase(),av;if(g(ax,"br")){ar=0;if(ah.block){c.remove(au)}return}if(ah.wrapper&&x(au,Z,ag)){ar=0;return}if(ah.block&&!ah.wrapper&&G(ax)){au=c.rename(au,ao);W(au);ak.push(au);ar=0;return}if(ah.selector){P(ac,function(ay){if("collapsed" in ay&&ay.collapsed!==ad){return}if(c.is(au,ay.selector)&&!b(au)){W(au,ay);av=true}});if(!ah.inline||av){ar=0;return}}if(d(ao,ax)&&d(aw,ao)&&!(!ap&&au.nodeType===3&&au.nodeValue.length===1&&au.nodeValue.charCodeAt(0)===65279)&&au.id!=="_mce_caret"){if(!ar){ar=am.cloneNode(S);au.parentNode.insertBefore(ar,au);ak.push(ar)}ar.appendChild(au)}else{if(ax=="li"&&an){ar=Y(au,an,am,ak,at)}else{ar=0;P(a.grep(au.childNodes),at);ar=0}}}P(aq,at)});if(ah.wrap_links===false){P(ak,function(aq){function ar(aw){var av,au,at;if(aw.nodeName==="A"){au=am.cloneNode(S);ak.push(au);at=a.grep(aw.childNodes);for(av=0;av<at.length;av++){au.appendChild(at[av])}aw.appendChild(au)}P(a.grep(aw.childNodes),ar)}ar(aq)})}P(ak,function(at){var aq;function au(aw){var av=0;P(aw.childNodes,function(ax){if(!f(ax)&&!H(ax)){av++}});return av}function ar(av){var ax,aw;P(av.childNodes,function(ay){if(ay.nodeType==1&&!H(ay)&&!b(ay)){ax=ay;return S}});if(ax&&h(ax,ah)){aw=ax.cloneNode(S);W(aw);c.replace(aw,av,B);c.remove(ax,1)}return aw||av}aq=au(at);if((ak.length>1||!F(at))&&aq===0){c.remove(at,1);return}if(ah.inline||ah.wrapper){if(!ah.exact&&aq===1){at=ar(at)}P(ac,function(av){P(c.select(av.inline,at),function(ax){var aw;if(av.wrap_links===false){aw=ax.parentNode;do{if(aw.nodeName==="A"){return}}while(aw=aw.parentNode)}U(av,ag,ax,av.exact?ax:null)})});if(x(at.parentNode,Z,ag)){c.remove(at,1);at=0;return B}if(ah.merge_with_parents){c.getParent(at.parentNode,function(av){if(x(av,Z,ag)){c.remove(at,1);at=0;return B}})}if(at&&ah.merge_siblings!==false){at=u(C(at),at);at=u(at,C(at,B))}}})}if(ah){if(ab){if(ab.nodeType){X=c.createRng();X.setStartBefore(ab);X.setEndAfter(ab);ai(o(X,ac),null,true)}else{ai(ab,null,true)}}else{if(!ad||!ah.inline||c.select("td.mceSelected,th.mceSelected").length){var aj=V.selection.getNode();V.selection.setRng(aa());af=q.getBookmark();ai(o(q.getRng(B),ac),af);if(ah.styles&&(ah.styles.color||ah.styles.textDecoration)){a.walk(aj,I,"childNodes");I(aj)}q.moveToBookmark(af);N(q.getRng(B));V.nodeChanged()}else{Q("apply",Z,ag)}}}}function A(Y,ag,aa){var ab=R(Y),ai=ab[0],af,ae,X;function Z(an){var am,al,ak;am=a.grep(an.childNodes);for(al=0,ak=ab.length;al<ak;al++){if(U(ab[al],ag,an,an)){break}}if(ai.deep){for(al=0,ak=am.length;al<ak;al++){Z(am[al])}}}function ac(ak){var al;P(m(ak.parentNode).reverse(),function(am){var an;if(!al&&am.id!="_start"&&am.id!="_end"){an=x(am,Y,ag);if(an&&an.split!==false){al=am}}});return al}function W(an,ak,ap,at){var au,ar,aq,am,ao,al;if(an){al=an.parentNode;for(au=ak.parentNode;au&&au!=al;au=au.parentNode){ar=au.cloneNode(S);for(ao=0;ao<ab.length;ao++){if(U(ab[ao],ag,ar,ar)){ar=0;break}}if(ar){if(aq){ar.appendChild(aq)}if(!am){am=ar}aq=ar}}if(at&&(!ai.mixed||!F(an))){ak=c.split(an,ak)}if(aq){ap.parentNode.insertBefore(aq,ap);am.appendChild(ap)}}return ak}function ah(ak){return W(ac(ak),ak,ak,true)}function ad(am){var al=c.get(am?"_start":"_end"),ak=al[am?"firstChild":"lastChild"];if(H(ak)){ak=ak[am?"firstChild":"lastChild"]}c.remove(al,true);return ak}function aj(ak){var al,am;ak=o(ak,ab,B);if(ai.split){al=J(ak,B);am=J(ak);if(al!=am){al=O(al,"span",{id:"_start","data-mce-type":"bookmark"});am=O(am,"span",{id:"_end","data-mce-type":"bookmark"});ah(al);ah(am);al=ad(B);am=ad()}else{al=am=ah(al)}ak.startContainer=al.parentNode;ak.startOffset=s(al);ak.endContainer=am.parentNode;ak.endOffset=s(am)+1}K.walk(ak,function(an){P(an,function(ao){Z(ao);if(ao.nodeType===1&&V.dom.getStyle(ao,"text-decoration")==="underline"&&ao.parentNode&&i(ao.parentNode)==="underline"){U({deep:false,exact:true,inline:"span",styles:{textDecoration:"underline"}},null,ao)}})})}if(aa){if(aa.nodeType){X=c.createRng();X.setStartBefore(aa);X.setEndAfter(aa);aj(X)}else{aj(aa)}return}if(!q.isCollapsed()||!ai.inline||c.select("td.mceSelected,th.mceSelected").length){af=q.getBookmark();aj(q.getRng(B));q.moveToBookmark(af);if(ai.inline&&j(Y,ag,q.getStart())){N(q.getRng(true))}V.nodeChanged()}else{Q("remove",Y,ag)}if(a.isWebKit){V.execCommand("mceCleanup")}}function D(X,Z,Y){var W=R(X);if(j(X,Z,Y)&&(!("toggle" in W[0])||W[0]["toggle"])){A(X,Z,Y)}else{T(X,Z,Y)}}function x(X,W,ac,aa){var Y=R(W),ad,ab,Z;function ae(ai,ak,al){var ah,aj,af=ak[al],ag;if(ak.onmatch){return ak.onmatch(ai,ak,al)}if(af){if(af.length===p){for(ah in af){if(af.hasOwnProperty(ah)){if(al==="attributes"){aj=c.getAttrib(ai,ah)}else{aj=L(ai,ah)}if(aa&&!aj&&!ak.exact){return}if((!aa||ak.exact)&&!g(aj,r(af[ah],ac))){return}}}}else{for(ag=0;ag<af.length;ag++){if(al==="attributes"?c.getAttrib(ai,af[ag]):L(ai,af[ag])){return ak}}}}return ak}if(Y&&X){for(ab=0;ab<Y.length;ab++){ad=Y[ab];if(h(X,ad)&&ae(X,ad,"attributes")&&ae(X,ad,"styles")){if(Z=ad.classes){for(ab=0;ab<Z.length;ab++){if(!c.hasClass(X,Z[ab])){return}}}return ad}}}}function j(Y,aa,Z){var X;function W(ab){ab=c.getParent(ab,function(ac){return !!x(ac,Y,aa,true)});return x(ab,Y,aa)}if(Z){return W(Z)}Z=q.getNode();if(W(Z)){return B}X=q.getStart();if(X!=Z){if(W(X)){return B}}return S}function v(ad,ac){var aa,ab=[],Z={},Y,X,W;aa=q.getStart();c.getParent(aa,function(ag){var af,ae;for(af=0;af<ad.length;af++){ae=ad[af];if(!Z[ae]&&x(ag,ae,ac)){Z[ae]=true;ab.push(ae)}}});return ab}function y(aa){var ac=R(aa),Z,Y,ab,X,W;if(ac){Z=q.getStart();Y=m(Z);for(X=ac.length-1;X>=0;X--){W=ac[X].selector;if(!W){return B}for(ab=Y.length-1;ab>=0;ab--){if(c.is(Y[ab],W)){return B}}}}return S}a.extend(this,{get:R,register:k,apply:T,remove:A,toggle:D,match:j,matchAll:v,matchNode:x,canApply:y});function h(W,X){if(g(W,X.inline)){return B}if(g(W,X.block)){return B}if(X.selector){return c.is(W,X.selector)}}function g(X,W){X=X||"";W=W||"";X=""+(X.nodeName||X);W=""+(W.nodeName||W);return X.toLowerCase()==W.toLowerCase()}function L(X,W){var Y=c.getStyle(X,W);if(W=="color"||W=="backgroundColor"){Y=c.toHex(Y)}if(W=="fontWeight"&&Y==700){Y="bold"}return""+Y}function r(W,X){if(typeof(W)!="string"){W=W(X)}else{if(X){W=W.replace(/%(\w+)/g,function(Z,Y){return X[Y]||Z})}}return W}function f(W){return W&&W.nodeType===3&&/^([\t \r\n]+|)$/.test(W.nodeValue)}function O(Y,X,W){var Z=c.create(X,W);Y.parentNode.insertBefore(Z,Y);Z.appendChild(Y);return Z}function o(W,ai,Z){var Y=W.startContainer,ad=W.startOffset,al=W.endContainer,af=W.endOffset,ak,ah,ac,ag;function aj(ar){var am,ap,aq,ao,an;am=ap=ar?Y:al;an=ar?"previousSibling":"nextSibling";root=c.getRoot();if(am.nodeType==3&&!f(am)){if(ar?ad>0:af<am.nodeValue.length){return am}}for(;;){if(ap==root||(!ai[0].block_expand&&F(ap))){return ap}for(ao=ap[an];ao;ao=ao[an]){if(!H(ao)&&!f(ao)){return ap}}ap=ap.parentNode}return am}function ab(am,an){if(an===p){an=am.nodeType===3?am.length:am.childNodes.length}while(am&&am.hasChildNodes()){am=am.childNodes[an];if(am){an=am.nodeType===3?am.length:am.childNodes.length}}return{node:am,offset:an}}if(Y.nodeType==1&&Y.hasChildNodes()){ah=Y.childNodes.length-1;Y=Y.childNodes[ad>ah?ah:ad];if(Y.nodeType==3){ad=0}}if(al.nodeType==1&&al.hasChildNodes()){ah=al.childNodes.length-1;al=al.childNodes[af>ah?ah:af-1];if(al.nodeType==3){af=al.nodeValue.length}}if(H(Y.parentNode)||H(Y)){Y=H(Y)?Y:Y.parentNode;Y=Y.nextSibling||Y;if(Y.nodeType==3){ad=0}}if(H(al.parentNode)||H(al)){al=H(al)?al:al.parentNode;al=al.previousSibling||al;if(al.nodeType==3){af=al.length}}if(ai[0].inline){if(W.collapsed){function ae(an,ar,au){var aq,ao,at,am;function ap(aw,ay){var az,av,ax=aw.nodeValue;if(typeof(ay)=="undefined"){ay=au?ax.length:0}if(au){az=ax.lastIndexOf(" ",ay);av=ax.lastIndexOf("\u00a0",ay);az=az>av?az:av;if(az!==-1&&!Z){az++}}else{az=ax.indexOf(" ",ay);av=ax.indexOf("\u00a0",ay);az=az!==-1&&(av===-1||az<av)?az:av}return az}if(an.nodeType===3){at=ap(an,ar);if(at!==-1){return{container:an,offset:at}}am=an}aq=new t(an,c.getParent(an,F)||V.getBody());while(ao=aq[au?"prev":"next"]()){if(ao.nodeType===3){am=ao;at=ap(ao);if(at!==-1){return{container:ao,offset:at}}}else{if(F(ao)){break}}}if(am){if(au){ar=0}else{ar=am.length}return{container:am,offset:ar}}}ag=ae(Y,ad,true);if(ag){Y=ag.container;ad=ag.offset}ag=ae(al,af);if(ag){al=ag.container;af=ag.offset}}ac=ab(al,af);if(ac.node){while(ac.node&&ac.offset===0&&ac.node.previousSibling){ac=ab(ac.node.previousSibling)}if(ac.node&&ac.offset>0&&ac.node.nodeType===3&&ac.node.nodeValue.charAt(ac.offset-1)===" "){if(ac.offset>1){al=ac.node;al.splitText(ac.offset-1)}else{if(ac.node.previousSibling){}}}}}if(ai[0].inline||ai[0].block_expand){if(!ai[0].inline||(Y.nodeType!=3||ad===0)){Y=aj(true)}if(!ai[0].inline||(al.nodeType!=3||af===al.nodeValue.length)){al=aj()}}if(ai[0].selector&&ai[0].expand!==S&&!ai[0].inline){function aa(an,am){var ao,ap,ar,aq;if(an.nodeType==3&&an.nodeValue.length==0&&an[am]){an=an[am]}ao=m(an);for(ap=0;ap<ao.length;ap++){for(ar=0;ar<ai.length;ar++){aq=ai[ar];if("collapsed" in aq&&aq.collapsed!==W.collapsed){continue}if(c.is(ao[ap],aq.selector)){return ao[ap]}}}return an}Y=aa(Y,"previousSibling");al=aa(al,"nextSibling")}if(ai[0].block||ai[0].selector){function X(an,am,ap){var ao;if(!ai[0].wrapper){ao=c.getParent(an,ai[0].block)}if(!ao){ao=c.getParent(an.nodeType==3?an.parentNode:an,F)}if(ao&&ai[0].wrapper){ao=m(ao,"ul,ol").reverse()[0]||ao}if(!ao){ao=an;while(ao[am]&&!F(ao[am])){ao=ao[am];if(g(ao,"br")){break}}}return ao||an}Y=X(Y,"previousSibling");al=X(al,"nextSibling");if(ai[0].block){if(!F(Y)){Y=aj(true)}if(!F(al)){al=aj()}}}if(Y.nodeType==1){ad=s(Y);Y=Y.parentNode}if(al.nodeType==1){af=s(al)+1;al=al.parentNode}return{startContainer:Y,startOffset:ad,endContainer:al,endOffset:af}}function U(ac,ab,Z,W){var Y,X,aa;if(!h(Z,ac)){return S}if(ac.remove!="all"){P(ac.styles,function(ae,ad){ae=r(ae,ab);if(typeof(ad)==="number"){ad=ae;W=0}if(!W||g(L(W,ad),ae)){c.setStyle(Z,ad,"")}aa=1});if(aa&&c.getAttrib(Z,"style")==""){Z.removeAttribute("style");Z.removeAttribute("data-mce-style")}P(ac.attributes,function(af,ad){var ae;af=r(af,ab);if(typeof(ad)==="number"){ad=af;W=0}if(!W||g(c.getAttrib(W,ad),af)){if(ad=="class"){af=c.getAttrib(Z,ad);if(af){ae="";P(af.split(/\s+/),function(ag){if(/mce\w+/.test(ag)){ae+=(ae?" ":"")+ag}});if(ae){c.setAttrib(Z,ad,ae);return}}}if(ad=="class"){Z.removeAttribute("className")}if(e.test(ad)){Z.removeAttribute("data-mce-"+ad)}Z.removeAttribute(ad)}});P(ac.classes,function(ad){ad=r(ad,ab);if(!W||c.hasClass(W,ad)){c.removeClass(Z,ad)}});X=c.getAttribs(Z);for(Y=0;Y<X.length;Y++){if(X[Y].nodeName.indexOf("_")!==0){return S}}}if(ac.remove!="none"){n(Z,ac);return B}}function n(Y,Z){var W=Y.parentNode,X;if(Z.block){if(!l){function aa(ac,ab,ad){ac=C(ac,ab,ad);return !ac||(ac.nodeName=="BR"||F(ac))}if(F(Y)&&!F(W)){if(!aa(Y,S)&&!aa(Y.firstChild,B,1)){Y.insertBefore(c.create("br"),Y.firstChild)}if(!aa(Y,B)&&!aa(Y.lastChild,S,1)){Y.appendChild(c.create("br"))}}}else{if(W==c.getRoot()){if(!Z.list_block||!g(Y,Z.list_block)){P(a.grep(Y.childNodes),function(ab){if(d(l,ab.nodeName.toLowerCase())){if(!X){X=O(ab,l)}else{X.appendChild(ab)}}else{X=0}})}}}}if(Z.selector&&Z.inline&&!g(Z.inline,Y)){return}c.remove(Y,1)}function C(X,W,Y){if(X){W=W?"nextSibling":"previousSibling";for(X=Y?X:X[W];X;X=X[W]){if(X.nodeType==1||!f(X)){return X}}}}function H(W){return W&&W.nodeType==1&&W.getAttribute("data-mce-type")=="bookmark"}function u(aa,Z){var W,Y,X;function ac(af,ae){if(af.nodeName!=ae.nodeName){return S}function ad(ah){var ai={};P(c.getAttribs(ah),function(aj){var ak=aj.nodeName.toLowerCase();if(ak.indexOf("_")!==0&&ak!=="style"){ai[ak]=c.getAttrib(ah,ak)}});return ai}function ag(ak,aj){var ai,ah;for(ah in ak){if(ak.hasOwnProperty(ah)){ai=aj[ah];if(ai===p){return S}if(ak[ah]!=ai){return S}delete aj[ah]}}for(ah in aj){if(aj.hasOwnProperty(ah)){return S}}return B}if(!ag(ad(af),ad(ae))){return S}if(!ag(c.parseStyle(c.getAttrib(af,"style")),c.parseStyle(c.getAttrib(ae,"style")))){return S}return B}if(aa&&Z){function ab(ae,ad){for(Y=ae;Y;Y=Y[ad]){if(Y.nodeType==3&&Y.nodeValue.length!==0){return ae}if(Y.nodeType==1&&!H(Y)){return Y}}return ae}aa=ab(aa,"previousSibling");Z=ab(Z,"nextSibling");if(ac(aa,Z)){for(Y=aa.nextSibling;Y&&Y!=Z;){X=Y;Y=Y.nextSibling;aa.appendChild(X)}c.remove(Z);P(a.grep(Z.childNodes),function(ad){aa.appendChild(ad)});return aa}}return Z}function G(W){return/^(h[1-6]|p|div|pre|address|dl|dt|dd)$/.test(W)}function J(X,ab){var W,aa,Y,Z;W=X[ab?"startContainer":"endContainer"];aa=X[ab?"startOffset":"endOffset"];if(W.nodeType==1){Y=W.childNodes.length-1;if(!ab&&aa){aa--}W=W.childNodes[aa>Y?Y:aa]}if(W.nodeType===3&&ab&&aa>=W.nodeValue.length){W=new t(W,V.getBody()).next()||W}if(W.nodeType===3&&!ab&&aa==0){W=new t(W,V.getBody()).prev()||W}return W}function Q(af,W,ad){var ai,ag="_mce_caret",X=V.settings.caret_debug;ai=a.isGecko?"\u200B":E;function Y(ak){var aj=c.create("span",{id:ag,"data-mce-bogus":true,style:X?"color:red":""});if(ak){aj.appendChild(V.getDoc().createTextNode(ai))}return aj}function ae(ak,aj){while(ak){if((ak.nodeType===3&&ak.nodeValue!==ai)||ak.childNodes.length>1){return false}if(aj&&ak.nodeType===1){aj.push(ak)}ak=ak.firstChild}return true}function ab(aj){while(aj){if(aj.id===ag){return aj}aj=aj.parentNode}}function aa(aj){var ak;if(aj){ak=new t(aj,aj);for(aj=ak.current();aj;aj=ak.next()){if(aj.nodeType===3){return aj}}}}function Z(al,ak){var am,aj;if(!al){al=ab(q.getStart());if(!al){while(al=c.get(ag)){Z(al,false)}}}else{aj=q.getRng(true);if(ae(al)){if(ak!==false){aj.setStartBefore(al);aj.setEndBefore(al)}c.remove(al)}else{am=aa(al);if(am.nodeValue.charAt(0)===E){am=am.deleteData(0,1)}c.remove(al,1)}q.setRng(aj)}}function ac(){var al,aj,ap,ao,am,ak,an;al=q.getRng(true);ao=al.startOffset;ak=al.startContainer;an=ak.nodeValue;aj=ab(q.getStart());if(aj){ap=aa(aj)}if(an&&ao>0&&ao<an.length&&/\w/.test(an.charAt(ao))&&/\w/.test(an.charAt(ao-1))){am=q.getBookmark();al.collapse(true);al=o(al,R(W));al=K.split(al);T(W,ad,al);q.moveToBookmark(am)}else{if(!aj||ap.nodeValue!==ai){aj=Y(true);ap=aj.firstChild;al.insertNode(aj);ao=1;T(W,ad,aj)}else{T(W,ad,aj)}q.setCursorLocation(ap,ao)}}function ah(){var aj=q.getRng(true),ak,am,ap,ao,al,at,ar=[],an,aq;ak=aj.startContainer;am=aj.startOffset;al=ak;if(ak.nodeType==3){if(am!=ak.nodeValue.length||ak.nodeValue===ai){ao=true}al=al.parentNode}while(al){if(x(al,W,ad)){at=al;break}if(al.nextSibling){ao=true}ar.push(al);al=al.parentNode}if(!at){return}if(ao){ap=q.getBookmark();aj.collapse(true);aj=o(aj,R(W),true);aj=K.split(aj);A(W,ad,aj);q.moveToBookmark(ap)}else{aq=Y();al=aq;for(an=ar.length-1;an>=0;an--){al.appendChild(ar[an].cloneNode(false));al=al.firstChild}al.appendChild(c.doc.createTextNode(ai));al=al.firstChild;c.insertAfter(aq,at);q.setCursorLocation(al,1)}}if(!self._hasCaretEvents){V.onBeforeGetContent.addToTop(function(){var aj=[],ak;if(ae(ab(q.getStart()),aj)){ak=aj.length;while(ak--){c.setAttrib(aj[ak],"data-mce-bogus","1")}}});a.each("onMouseUp onKeyUp".split(" "),function(aj){V[aj].addToTop(function(){Z()})});V.onKeyDown.addToTop(function(aj,al){var ak=al.keyCode;if(ak==8||ak==37||ak==39){Z(ab(q.getStart()))}});self._hasCaretEvents=true}if(af=="apply"){ac()}else{ah()}}function N(X){var W=X.startContainer,ac=X.startOffset,ab,aa,Y,Z;if(W.nodeType==3&&ac>=W.nodeValue.length-1){W=W.parentNode;ac=s(W)+1}if(W.nodeType==1){Y=W.childNodes;W=Y[Math.min(ac,Y.length-1)];ab=new t(W);if(ac>Y.length-1){ab.next()}for(aa=ab.current();aa;aa=ab.next()){if(aa.nodeType==3&&!f(aa)){Z=c.create("a",null,E);aa.parentNode.insertBefore(Z,aa);X.setStart(aa,0);q.setRng(X);c.remove(Z);return}}}}}})(tinymce);tinymce.onAddEditor.add(function(e,a){var d,h,g,c=a.settings;if(c.inline_styles){h=e.explode(c.font_size_legacy_values);function b(j,i){e.each(i,function(l,k){if(l){g.setStyle(j,k,l)}});g.rename(j,"span")}d={font:function(j,i){b(i,{backgroundColor:i.style.backgroundColor,color:i.color,fontFamily:i.face,fontSize:h[parseInt(i.size)-1]})},u:function(j,i){b(i,{textDecoration:"underline"})},strike:function(j,i){b(i,{textDecoration:"line-through"})}};function f(i,j){g=i.dom;if(c.convert_fonts_to_spans){e.each(g.select("font,u,strike",j.node),function(k){d[k.nodeName.toLowerCase()](a.dom,k)})}}a.onPreProcess.add(f);a.onSetContent.add(f);a.onInit.add(function(){a.selection.onSetContent.add(f)})}});
// This [jQuery](http://jquery.com/) plugin implements an `<iframe>`
// [transport](http://api.jquery.com/extending-ajax/#Transports) so that
// `$.ajax()` calls support the uploading of files using standard HTML file
// input fields. This is done by switching the exchange from `XMLHttpRequest` to
// a hidden `iframe` element containing a form that is submitted.

// The [source for the plugin](http://github.com/cmlenz/jquery-iframe-transport)
// is available on [Github](http://github.com/) and dual licensed under the MIT
// or GPL Version 2 licenses.

// ## Usage

// To use this plugin, you simply add a `iframe` option with the value `true`
// to the Ajax settings an `$.ajax()` call, and specify the file fields to
// include in the submssion using the `files` option, which can be a selector,
// jQuery object, or a list of DOM elements containing one or more
// `<input type="file">` elements:

//     $("#myform").submit(function() {
//         $.ajax(this.action, {
//             files: $(":file", this),
//             iframe: true
//         }).complete(function(data) {
//             console.log(data);
//         });
//     });

// The plugin will construct a hidden `<iframe>` element containing a copy of
// the form the file field belongs to, will disable any form fields not
// explicitly included, submit that form, and process the response.

// If you want to include other form fields in the form submission, include them
// in the `data` option, and set the `processData` option to `false`:

//     $("#myform").submit(function() {
//         $.ajax(this.action, {
//             data: $(":text", this).serializeArray(),
//             files: $(":file", this),
//             iframe: true,
//             processData: false
//         }).complete(function(data) {
//             console.log(data);
//         });
//     });

// ### The Server Side

// If the response is not HTML or XML, you (unfortunately) need to apply some
// trickery on the server side. To send back a JSON payload, send back an HTML
// `<textarea>` element with a `data-type` attribute that contains the MIME
// type, and put the actual payload in the textarea:

//     <textarea data-type="application/json">
//       {"ok": true, "message": "Thanks so much"}
//     </textarea>

// The iframe transport plugin will detect this and attempt to apply the same
// conversions that jQuery applies to regular responses. That means for the
// example above you should get a Javascript object as the `data` parameter of
// the `complete` callback, with the properties `ok: true` and
// `message: "Thanks so much"`.

// ### Compatibility

// This plugin has primarily been tested on Safari 5, Firefox 4, and Internet
// Explorer all the way back to version 6. While I haven't found any issues with
// it so far, I'm fairly sure it still doesn't work around all the quirks in all
// different browsers. But the code is still pretty simple overall, so you
// should be able to fix it and contribute a patch :)

// ## Annotated Source

(function($, undefined) {

  // Register a prefilter that checks whether the `iframe` option is set, and
  // switches to the iframe transport if it is `true`.
  $.ajaxPrefilter(function(options, origOptions, jqXHR) {
    if (options.iframe) {
      return "iframe";
    }
  });

  // Register an iframe transport, independent of requested data type. It will
  // only activate when the "files" option has been set to a non-empty list of
  // enabled file inputs.
  $.ajaxTransport("iframe", function(options, origOptions, jqXHR) {
    var form = null,
        iframe = null,
        origAction = null,
        origTarget = null,
        origEnctype = null,
        addedFields = [],
        disabledFields = [],
        files = $(options.files).filter(":file:enabled");

    // This function gets called after a successful submission or an abortion
    // and should revert all changes made to the page to enable the
    // submission via this transport.
    function cleanUp() {
      $(addedFields).each(function() {
        this.remove();
      });
      $(disabledFields).each(function() {
        this.disabled = false;
      });
      form.attr("action", origAction || "")
          .attr("target", origTarget || "")
          .attr("enctype", origEnctype || "");
      iframe.attr("src", "javascript:false;").remove();
    }

    // Remove "iframe" from the data types list so that further processing is
    // based on the content type returned by the server, without attempting an
    // (unsupported) conversion from "iframe" to the actual type.
    options.dataTypes.shift();

    if (files.length) {
      // Determine the form the file fields belong to, and make sure they all
      // actually belong to the same form.
      files.each(function() {
        if (form !== null && this.form !== form) {
          jQuery.error("All file fields must belong to the same form");
        }
        form = this.form;
      });
      form = $(form);

      // Store the original form attributes that we'll be replacing temporarily.
      origAction = form.attr("action");
      origTarget = form.attr("target");
      origEnctype = form.attr("enctype");

      // We need to disable all other inputs in the form so that they don't get
      // included in the submitted data unexpectedly.
      form.find(":input:not(:submit)").each(function() {
        if (!this.disabled && (this.type != "file" || files.index(this) < 0)) {
          this.disabled = true;
          disabledFields.push(this);
        }
      });

      // If there is any additional data specified via the `data` option,
      // we add it as hidden fields to the form. This (currently) requires
      // the `processData` option to be set to false so that the data doesn't
      // get serialized to a string.
      if (typeof(options.data) === "string" && options.data.length > 0) {
        jQuery.error("data must not be serialized");
      }
      $.each(options.data || {}, function(name, value) {
        if ($.isPlainObject(value)) {
          name = value.name;
          value = value.value;
        }
        addedFields.push($("<input type='hidden'>").attr("name", name)
          .attr("value", value).appendTo(form));
      });

      // Add a hidden `X-Requested-With` field with the value `IFrame` to the
      // field, to help server-side code to determine that the upload happened
      // through this transport.
      addedFields.push($("<input type='hidden' name='X-Requested-With'>")
        .attr("value", "IFrame").appendTo(form));

      // Borrowed straight from the JQuery source
      // Provides a way of specifying the accepted data type similar to HTTP_ACCEPTS
      accepts = options.dataTypes[ 0 ] && options.accepts[ options.dataTypes[0] ] ?
        options.accepts[ options.dataTypes[0] ] + ( options.dataTypes[ 0 ] !== "*" ? ", */*; q=0.01" : "" ) :
        options.accepts[ "*" ]

      addedFields.push($("<input type='hidden' name='X-Http-Accept'>")
        .attr("value", accepts).appendTo(form));

      return {

        // The `send` function is called by jQuery when the request should be
        // sent.
        send: function(headers, completeCallback) {
          iframe = $("<iframe src='javascript:false;' name='iframe-" + $.now()
            + "' style='display:none'></iframe>");

          // The first load event gets fired after the iframe has been injected
          // into the DOM, and is used to prepare the actual submission.
          iframe.bind("load", function() {

            // The second load event gets fired when the response to the form
            // submission is received. The implementation detects whether the
            // actual payload is embedded in a `<textarea>` element, and
            // prepares the required conversions to be made in that case.
            iframe.unbind("load").bind("load", function() {

              var doc = this.contentWindow ? this.contentWindow.document :
                (this.contentDocument ? this.contentDocument : this.document),
                root = doc.documentElement ? doc.documentElement : doc.body,
                textarea = root.getElementsByTagName("textarea")[0],
                type = textarea ? textarea.getAttribute("data-type") : null;

              var status = textarea ? parseInt(textarea.getAttribute("response-code")) : 200,
                statusText = "OK",
                responses = { text: type ? textarea.value : root ? root.innerHTML : null },
                headers = "Content-Type: " + (type || "text/html")

              completeCallback(status, statusText, responses, headers);

              setTimeout(cleanUp, 50);
            });

            // Now that the load handler has been set up, reconfigure and
            // submit the form.
            form.attr("action", options.url)
              .attr("target", iframe.attr("name"))
              .attr("enctype", "multipart/form-data")
              .get(0).submit();
          });

          // After everything has been set up correctly, the iframe gets
          // injected into the DOM so that the submission can be initiated.
          iframe.insertAfter(form);
        },

        // The `abort` function is called by jQuery when the request should be
        // aborted.
        abort: function() {
          if (iframe !== null) {
            iframe.unbind("load").attr("src", "javascript:false;");
            cleanUp();
          }
        }

      };
    }
  });

})(jQuery);

(function($) {

  var remotipart;

  $.remotipart = remotipart = {

    setup: function(form) {
      form
        // Allow setup part of $.rails.handleRemote to setup remote settings before canceling default remote handler
        // This is required in order to change the remote settings using the form details
        .one('ajax:beforeSend.remotipart', function(e, xhr, settings){
          // Delete the beforeSend bindings, since we're about to re-submit via ajaxSubmit with the beforeSubmit
          // hook that was just setup and triggered via the default `$.rails.handleRemote`
          // delete settings.beforeSend;
          delete settings.beforeSend;

          settings.iframe      = true;
          settings.files       = $($.rails.fileInputSelector, form);
          settings.data        = form.serializeArray();
          settings.processData = false;

          // Modify some settings to integrate JS request with rails helpers and middleware
          if (settings.dataType === undefined) { settings.dataType = 'script *'; }
          settings.data.push({name: 'remotipart_submitted', value: true});

          // Allow remotipartSubmit to be cancelled if needed
          if ($.rails.fire(form, 'ajax:remotipartSubmit', [xhr, settings])) {
            // Second verse, same as the first
            $.rails.ajax(settings);
          }

          //Run cleanup
          remotipart.teardown(form);

          // Cancel the jQuery UJS request
          return false;
        })

        // Keep track that we just set this particular form with Remotipart bindings
        // Note: The `true` value will get over-written with the `settings.dataType` from the `ajax:beforeSend` handler
        .data('remotipartSubmitted', true);
    },

    teardown: function(form) {
      form
        .unbind('ajax:beforeSend.remotipart')
        .removeData('remotipartSubmitted')
    }
  };

  $('form').live('ajax:aborted:file', function(){
    var form = $(this);

    remotipart.setup(form);

    // If browser does not support submit bubbling, then this live-binding will be called before direct
    // bindings. Therefore, we should directly call any direct bindings before remotely submitting form.
    if (!$.support.submitBubbles && $().jquery < '1.7' && $.rails.callFormSubmitBindings(form) === false) return $.rails.stopEverything(e);

    // Manually call jquery-ujs remote call so that it can setup form and settings as usual,
    // and trigger the `ajax:beforeSend` callback to which remotipart binds functionality.
    $.rails.handleRemote(form);
    return false;
  });

})(jQuery);

// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//


;
