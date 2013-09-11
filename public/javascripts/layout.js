// To make this work on localhost
//var nAgt = navigator.userAgent;
//if ((nAgt.indexOf("Chrome"))!=-1) {
//document.domain = /(\w+)(.\w+)?$/.exec(location.hostname)[0];
//}
function removeCompare(obj){
    $(obj).parents('.compare-view').remove();
    key = $(obj).attr('rel') ;
    $.cookie(key,null);
    $('#add_to_compare_' + key ).attr('checked',false);
    var url = $('#compare-items a').attr('href')
    idsPrt = url.split('=');
    idsStr = idsPrt[1];
    var url = url.split('=')[0];
    idsArr = idsStr.split(',');
    ids = jQuery.grep(idsArr,function(a){
        return a != key
    } );
    idsStr = ids.join(',')
    $.cookie('allItems',idsStr)
    url = $('#compare-items a').attr('href',url + '=' + idsStr)
    if($('#compare-list .compare-view').length > 1){
        $('#compare-items').show();
    }else{
        $('#compare-items').hide();
    }
    if($('#compare-list div.compare-view').length == 0){
        $('#compare-list').hide();
    }
    return false;
};

//##################################### ADDED BY GANESH #####################################
function reinitialiseVotingPoshyTip(){   
    $('.btn_dislike_positive').poshytip('destroy')

    $('.btn_like_positive').poshytip('destroy')

    $('.btn_like_default').poshytip('destroy')

    $('.btn_dislike_default').poshytip('destroy')

    $('.btn_like_negative').poshytip('destroy')
    $('.btn_dislike_negative').poshytip('destroy')


    $('.btn_dislike_positive').poshytip({
        content: 'Dislike It',
        className: 'tip-darkgray',
        bgImageFrameSize: 11,
        offsetX: -25
    });
    $('.btn_like_positive').poshytip({
        content: 'Already Liked It, click to cancel it',
        className: 'tip-darkgray',
        bgImageFrameSize: 11,
        offsetX: -25
    });
    $('.btn_like_default').poshytip({
        content: 'Like It',
        className: 'tip-darkgray',
        bgImageFrameSize: 11,
        offsetX: -25
    });
    $('.btn_dislike_default').poshytip({
        content: 'Dislike It',
        className: 'tip-darkgray',
        bgImageFrameSize: 11,
        offsetX: -25
    });
    $('.btn_like_negative').poshytip({
        content: 'Like It',
        className: 'tip-darkgray',
        bgImageFrameSize: 11,
        offsetX: -25
    });
    $('.btn_dislike_negative').poshytip({
        content: 'Alread Disliked it, click to cancel',
        className: 'tip-darkgray',
        bgImageFrameSize: 11,
        offsetX: -25
    });
}

$(document).ready(function(){
    reinitialiseVotingPoshyTip();

    $("#ui-active-menuitem").mouseout(function() {
        $("#ui-active-menuitem").hide();
    });

    $('#plannToSearch').focus(function(){
      //  $(this).val('');
        $(this).keydown();
    });




    $("#plannToSearch").autocomplete({
        minLength: 2,
        format: "js",
        // source: "/search/autocomplete_items?search_type=" + $("#plannto_search_type").val() ,
        source: function( request, response )
        {
            var opts = {
                lines: 12, // The number of lines to draw
                length: 5, // The length of each line
                width: 4, // The line thickness
                radius: 5, // The radius of the inner circle
                color: '#2EFE9A', // #rgb or #rrggbb
                speed: 1, // Rounds per second
                trail: 50, // Afterglow percentage
                shadow: true, // Whether to render a shadow
                hwaccel: false // Whether to use hardware acceleration
            };
            var target = document.getElementById('plannToSearchSpan');
            var spinner = new Spinner(opts).spin(target);
            $.ajax(
            {
                url: "/search/autocomplete_items",
                data: {
                    term: request.term,
                    content: "true",
                    search_type: $("#plannto_search_type").val()
                },
                type: "get",
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
                    spinner.stop();
                }
            });
        },
        focus:function(e, ui) {
            return false
        },
        select: function( event, ui ) {
            $("#item_search1").val("true");
            if (ui.item.id  == 0){
            	//alert(ui.item.url)
            	 
                location.href = "/search/search_items?q=" + ui.item.url
                //$("#item_search").val("")
            // return false;
            }
            else{
                
                location.href = "" + ui.item.url
               // $("#item_search").val("")
            // return false;
            }
        // return false;
        }
    })
       _renderMenu = function(ul, items) {
        var self = this;
        $.each(items, function(index, item) {
            self._renderItem(ul, item, index);
        });
        
        item = {
            value: "Search more items...",
            id: "0",
            imgsrc: ""
        }
        self._renderItem(ul, item, -1);
    };
    $("#plannToSearch").data("autocomplete")._renderItem = function(ul, item, index) {
    	
        if (item.id == 0) {
            return $("<li></li>")
            .data("item.autocomplete", item)
            .append("<a class='searchMore'>" + item.value + "" + "</a>")
            .appendTo(ul);
        }
        else {
            return $("<li></li>")
            .data("item.autocomplete", item)
            .append("<a>" + "<div style='margin-left:5px;float:left'><img width='40' height='40' src='" + item.imgsrc + "' /></div>" + "<div style='margin-left:53px;'><span class='atext'>" + item.value + "</span><br/><span class ='atext'>" + item.type + "</span></div></a>")
            .appendTo(ul);
        }
    };

});

  
$(document).ready(function() {
  $('input#plannToSearch').keyup(function(e){
     if(e.keyCode == 13 && $("#item_search1").val()!="true")
       {
         window.location.href= "/search/search_items?q=" + $("#plannToSearch").val();
       }
    }); 
    
    $('a.youtube').youtube();
    $('span.buttonLink a#youtube_form').click(function() {
        $("#image_share").hide();
        $("#article_share").hide();
        $("#youtube").toggle(2000);
        //          alert('Handler for .click() called.');
        return false;
    });


    $('span.buttonLink a#image_form').click(function() {
        $("#article_share").hide();
        $("#youtube").hide();
        $("#image_share").toggle(2000);
        return false;
    });


    $('span.buttonLink a#article_form').click(function() {
        $("#youtube").hide();
        $("#image_share").hide();
        $("#article_share").toggle(2000);
        return false;
    });

});

$("#share_an_article").click(function(){
        $("share_an_article_form").show();
    }
);


/* placeholder.js content merged withlayout to reduce the no. of js files. */


var Placeholders = (function () {

    "use strict";

    /* List of input types that support the placeholder attribute. We only want to modify input elements with one of these types.
     * WARNING: If an input type is not supported by a browser, the browser will choose the default type (text) and the placeholder shim will 
     * apply */
    var validTypes = [
            "text",
            "search",
            "url",
            "tel",
            "email",
            "password",
            "number",
            "textarea"
        ],

    //Default options, can be overridden by passing object to `init`
        settings = {
            live:           false,
            hideOnFocus:    false,
            className:      'placeholderspolyfill', // placeholder class name to apply to form fields
            textColor:      '#999',                 // default placeholder text color
            styleImportant: true                    // add !important flag to placeholder style
        },

    //Keycodes that are not allowed when the placeholder is visible and `hideOnFocus` is `false`
        badKeys = [37, 38, 39, 40],

    //Used if `live` options is `true`
        interval,

    //Stores the input value on keydown (used when `hideOnFocus` option is `false`)
        valueKeyDown,

    // polyfill class name regexp
        classNameRegExp = new RegExp('\\b' + settings.className + '\\b');

    // The cursorToStart function attempts to jump the cursor to before the first character of input
    function cursorToStart(elem) {
        var range;
        if (elem.createTextRange) {
            range = elem.createTextRange();
            range.move("character", 0);
            range.select();
        } else if (elem.selectionStart) {
            elem.focus();
            elem.setSelectionRange(0, 0);
        }
    }

    /* The focusHandler function is executed when input elements with placeholder attributes receive a focus event. If necessary, the placeholder
     * and its associated styles are removed from the element. Must be bound to an element. */
    function focusHandler() {

        var type;

        //If the placeholder is currently visible, remove it and its associated styles
        if (this.value === this.getAttribute("placeholder")) {

            if (!settings.hideOnFocus) {
                cursorToStart(this);
            } else {
                /* Remove the placeholder class name. Use a regular expression to ensure the string being searched for is a complete word, and not part of a longer
                 * string, on the off-chance a class name including that string also exists on the element */
                this.className = this.className.replace(classNameRegExp, "");
                this.value = "";

                // Check if we need to switch the input type (this is the case if it's a password input)
                type = this.getAttribute("data-placeholdertype");
                if (type) {
                    this.type = type;
                }
            }
        }
    }

    /* The blurHandler function is executed when input elements with placeholder attributes receive a blur event. If necessary, the placeholder
     * and its associated styles are applied to the element. Must be bound to an element. */
    function blurHandler() {

        var type;

        //If the input value is the empty string, apply the placeholder and its associated styles
        if (this.value === "") {
            this.className = this.className + " " + settings.className;
            this.value = this.getAttribute("placeholder");

            // Check if we need to switch the input type (this is the case if it's a password input)
            type = this.getAttribute("data-placeholdertype");
            if (type) {
                this.type = "text";
            }
        }
    }

    /* The submitHandler function is executed when the containing form, if any, of a given input element is submitted. If necessary, placeholders on any
     * input element descendants of the form are removed so that the placeholder value is not submitted as the element value. */
    function submitHandler() {
        var inputs = this.getElementsByTagName("input"),
            textareas = this.getElementsByTagName("textarea"),
            numInputs = inputs.length,
            num = numInputs + textareas.length,
            element,
            placeholder,
            i;
        //Iterate over all descendant input elements and remove placeholder if necessary
        for (i = 0; i < num; i += 1) {
            element = (i < numInputs) ? inputs[i] : textareas[i - numInputs];
            placeholder = element.getAttribute("placeholder");

            //If the value of the input is equal to the value of the placeholder attribute we need to clear the value
            if (element.value === placeholder) {
                element.value = "";
            }
        }
    }

    /* The keydownHandler function is executed when the input elements with placeholder attributes receive a keydown event. It simply stores the current
     * value of the input (so we can kind-of simulate the poorly-supported `input` event). Used when `hideOnFocus` option is `false`. Must be bound to an element. */
    function keydownHandler(event) {
        valueKeyDown = this.value;

        //Prevent the use of the arrow keys (try to keep the cursor before the placeholder)
        return !(valueKeyDown === this.getAttribute("placeholder") && badKeys.indexOf(event.keyCode) > -1);
    }

    /* The keyupHandler function is executed when the input elements with placeholder attributes receive a keyup event. It kind-of simulates the native but
     * poorly-supported `input` event by checking if the key press has changed the value of the element. Used when `hideOnFocus` option is `false`. Must be bound to an element. */
    function keyupHandler() {

        var type;

        if (this.value !== valueKeyDown) {

            // Remove the placeholder
            this.className = this.className.replace(classNameRegExp, "");
            this.value = this.value.replace(this.getAttribute("placeholder"), "");

            // Check if we need to switch the input type (this is the case if it's a password input)
            type = this.getAttribute("data-placeholdertype");
            if (type) {
                this.type = type;
            }
        }
        if (this.value === "") {

            blurHandler.call(this);
            cursorToStart(this);
        }
    }

    //The addEventListener function binds an event handler with the context of an element to a specific event on that element. Handles old-IE and modern browsers.
    function addEventListener(element, event, fn) {
        if (element.addEventListener) {
            return element.addEventListener(event, fn.bind(element), false);
        }
        if (element.attachEvent) {
            return element.attachEvent("on" + event, fn.bind(element));
        }
    }

    //The addEventListeners function binds the appropriate (depending on options) event listeners to the specified input or textarea element.
    function addEventListeners(element) {
        if (!settings.hideOnFocus) {
            addEventListener(element, "keydown", keydownHandler);
            addEventListener(element, "keyup", keyupHandler);
        }
        addEventListener(element, "focus", focusHandler);
        addEventListener(element, "blur", blurHandler);
    }

    /* The updatePlaceholders function checks all input and textarea elements and updates the placeholder if necessary. Elements that have been added to the DOM since the call to 
     * createPlaceholders will not function correctly until this function is executed. The same goes for any existing elements whose placeholder property has been changed (via 
     * element.setAttribute("placeholder", "new") for example) */
    function updatePlaceholders() {

        //Declare variables, get references to all input and textarea elements
        var inputs = document.getElementsByTagName("input"),
            textareas = document.getElementsByTagName("textarea"),
            numInputs = inputs.length,
            num = numInputs + textareas.length,
            i,
            form,
            element,
            oldPlaceholder,
            newPlaceholder;

        //Iterate over all input and textarea elements and apply/update the placeholder polyfill if necessary
        for (i = 0; i < num; i += 1) {

            //Get the next element from either the input NodeList or the textarea NodeList, depending on how many elements we've already looped through
            element = (i < numInputs) ? inputs[i] : textareas[i - numInputs];

            //Get the value of the placeholder attribute
            newPlaceholder = element.getAttribute("placeholder");

            //Check whether the current input element is of a type that supports the placeholder attribute
            if (validTypes.indexOf(element.type) > -1) {

                //The input type does support the placeholder attribute. Check whether the placeholder attribute has a value
                if (newPlaceholder) {

                    //The placeholder attribute has a value. Get the value of the current placeholder data-* attribute
                    oldPlaceholder = element.getAttribute("data-currentplaceholder");

                    //Check whether the placeholder attribute value has changed
                    if (newPlaceholder !== oldPlaceholder) {

                        //The placeholder attribute value has changed so we need to update. Check whether the placeholder should currently be visible.
                        if (element.value === oldPlaceholder || element.value === newPlaceholder || !element.value) {

                            //The placeholder should be visible so change the element value to that of the placeholder attribute and set placeholder styles
                            element.value = newPlaceholder;
                            element.className = element.className + " " + settings.className;
                        }

                        //If the current placeholder data-* attribute has no value the element wasn't present in the DOM when event handlers were bound, so bind them now
                        if (!oldPlaceholder) {
                            //If the element has a containing form bind to the submit event so we can prevent placeholder values being submitted as actual values
                            if (element.form) {

                                //Get a reference to the containing form element (if present)
                                form = element.form;

                                //The placeholdersubmit data-* attribute is set if this form has already been dealt with
                                if (!form.getAttribute("data-placeholdersubmit")) {

                                    //The placeholdersubmit attribute wasn't set, so attach a submit event handler
                                    addEventListener(form, "submit", submitHandler);

                                    //Set the placeholdersubmit attribute so we don't repeatedly bind event handlers to this form element
                                    form.setAttribute("data-placeholdersubmit", "true");
                                }
                            }
                            addEventListeners(element);
                        }

                        //Update the value of the current placeholder data-* attribute to reflect the new placeholder value
                        element.setAttribute("data-currentplaceholder", newPlaceholder);
                    }
                }
            }
        }
    }

    /* The createPlaceholders function checks all input and textarea elements currently in the DOM for the placeholder attribute. If the attribute
     * is present, and the element is of a type (e.g. text) that allows the placeholder attribute, it attaches the appropriate event listeners
     * to the element and if necessary sets its value to that of the placeholder attribute */
    function createPlaceholders() {

        //Declare variables and get references to all input and textarea elements
        var inputs = document.getElementsByTagName("input"),
            textareas = document.getElementsByTagName("textarea"),
            numInputs = inputs.length,
            num = numInputs + textareas.length,
            i,
            element,
            form,
            placeholder;

        //Iterate over all input elements and apply placeholder polyfill if necessary
        for (i = 0; i < num; i += 1) {

            //Get the next element from either the input NodeList or the textarea NodeList, depending on how many elements we've already looped through
            element = (i < numInputs) ? inputs[i] : textareas[i - numInputs];

            //Get the value of the placeholder attribute
            placeholder = element.getAttribute("placeholder");

            //Check whether or not the current element is of a type that allows the placeholder attribute
            if (validTypes.indexOf(element.type) > -1) {

                //The input type does support placeholders. Check that the placeholder attribute has been given a value
                if (placeholder) {

                    // If the element type is "password", attempt to change it to "text" so we can display the placeholder value in plain text
                    if (element.type === "password") {

                        // The `type` property is read-only in IE < 9, so in those cases we just move on. The placeholder will be displayed masked
                        try {
                            element.type = "text";
                            element.setAttribute("data-placeholdertype", "password");
                        } catch (e) {}
                    }

                    //The placeholder attribute has a value. Keep track of the current placeholder value in an HTML5 data-* attribute
                    element.setAttribute("data-currentplaceholder", placeholder);

                    //If the value of the element is the empty string set the value to that of the placeholder attribute and apply the placeholder styles
                    if (element.value === "" || element.value === placeholder) {
                        element.className = element.className + " " + settings.className;
                        element.value = placeholder;
                    }

                    //If the element has a containing form bind to the submit event so we can prevent placeholder values being submitted as actual values
                    if (element.form) {

                        //Get a reference to the containing form element (if present)
                        form = element.form;

                        //The placeholdersubmit data-* attribute is set if this form has already been dealt with
                        if (!form.getAttribute("data-placeholdersubmit")) {

                            //The placeholdersubmit attribute wasn't set, so attach a submit event handler
                            addEventListener(form, "submit", submitHandler);

                            //Set the placeholdersubmit attribute so we don't repeatedly bind event handlers to this form element
                            form.setAttribute("data-placeholdersubmit", "true");
                        }
                    }

                    //Attach event listeners to this element
                    addEventListeners(element);
                }
            }
        }
    }

    /* The init function checks whether or not we need to polyfill the placeholder functionality. If we do, it sets up various things
     * needed throughout the script and then calls createPlaceholders to setup initial placeholders */
    function init(opts) {

        //Create an input element to test for the presence of the placeholder property. If the placeholder property exists, stop.
        var test = document.createElement("input"),
            opt,
            styleElem,
            styleRules,
            i,
            j;

        //Test input element for presence of placeholder property. If it doesn't exist, the browser does not support HTML5 placeholders
        if (typeof test.placeholder === "undefined") {
            //HTML5 placeholder attribute not supported.

            //Set the options (or use defaults)
            for (opt in opts) {
                if (opts.hasOwnProperty(opt)) {
                    settings[opt] = opts[opt];
                }
            }

            //Create style element for placeholder styles
            styleElem = document.createElement("style");
            styleElem.type = "text/css";

            //Create style rules as text node
            var importantValue = (settings.styleImportant) ? "!important" : "";
            styleRules = document.createTextNode("." + settings.className + " { color:" + settings.textColor  + importantValue + "; }");

            //Append style rules to newly created stylesheet
            if (styleElem.styleSheet) {
                styleElem.styleSheet.cssText = styleRules.nodeValue;
            } else {
                styleElem.appendChild(styleRules);
            }

            //Append new style element to the head
            document.getElementsByTagName("head")[0].appendChild(styleElem);

            //We use Array.prototype.indexOf later, so make sure it exists
            if (!Array.prototype.indexOf) {
                Array.prototype.indexOf = function (obj, start) {
                    for (i = (start || 0), j = this.length; i < j; i += 1) {
                        if (this[i] === obj) { return i; }
                    }
                    return -1;
                };
            }

            /* We use Function.prototype.bind later, so make sure it exists. This is the MDN implementation, slightly modified to pass JSLint. See
             * https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Function/bind */
            if (!Function.prototype.bind) {
                Function.prototype.bind = function (oThis) {
                    if (typeof this !== "function") {
                        throw new TypeError("Function.prototype.bind - what is trying to be bound is not callable");
                    }
                    var aArgs = Array.prototype.slice.call(arguments, 1),
                        fToBind = this,
                        FNop = function () {},
                        fBound = function () {
                            return fToBind.apply(this instanceof FNop
                                 ? this
                                 : oThis,
                                aArgs.concat(Array.prototype.slice.call(arguments)));
                        };
                    FNop.prototype = this.prototype;
                    fBound.prototype = new FNop();
                    return fBound;
                };
            }

            //Create placeholders for input elements currently part of the DOM
            createPlaceholders();

            /* If the `live` option is truthy, call updatePlaceholders repeatedly to keep up to date with any DOM changes.
             * We use an interval over events such as DOMAttrModified (which are used in some other implementations of the placeholder attribute)
             * since the DOM level 2 mutation events are deprecated in the level 3 spec. */
            if (settings.live) {
                interval = setInterval(updatePlaceholders, 100);
            }

            //Placeholder attribute was successfully polyfilled :)
            return true;
        }

        //Placeholder attribute already supported by browser :)
        return false;
    }

    //Expose public methods
    return {
        init: init,
        refresh: updatePlaceholders
    };
}());

/* jquery.bpopup.min.js file content added here */
 (function(b){b.fn.bPopup=function(u,C){function v(){a.modal&&b('<div class="b-modal '+e+'"></div>').css({backgroundColor:a.modalColor,position:"fixed",top:0,right:0,bottom:0,left:0,opacity:0,zIndex:a.zIndex+l}).appendTo(a.appendTo).fadeTo(a.speed,a.opacity);z();c.data("bPopup",a).data("id",e).css({left:"slideIn"===a.transition?-1*(m+h):n(!(!a.follow[0]&&p||g)),position:a.positionStyle||"absolute",top:"slideDown"===a.transition?-1*(q+h):r(!(!a.follow[1]&&s||g)),"z-index":a.zIndex+l+1}).each(function(){a.appending&&b(this).appendTo(a.appendTo)});D(!0)}function t(){a.modal&&b(".b-modal."+c.data("id")).fadeTo(a.speed,0,function(){b(this).remove()});a.scrollBar||b("html").css("overflow","auto");b(".b-modal."+e).unbind("click");j.unbind("keydown."+e);d.unbind("."+e).data("bPopup",0<d.data("bPopup")-1?d.data("bPopup")-1:null);c.undelegate(".bClose, ."+a.closeClass,"click."+e,t).data("bPopup",null);D();return!1}function E(f){var b=f.width(),e=f.height(),d={};a.contentContainer.css({height:e,width:b});e>=c.height()&&(d.height=c.height());b>=c.width()&&(d.width=c.width());w=c.outerHeight(!0);h=c.outerWidth(!0);z();a.contentContainer.css({height:"auto",width:"auto"});d.left=n(!(!a.follow[0]&&p||g));d.top=r(!(!a.follow[1]&&s||g));c.animate(d,250,function(){f.show();x=A()})}function D(f){switch(a.transition){case "slideIn":c.css({display:"block",opacity:1}).animate({left:f?n(!(!a.follow[0]&&p||g)):j.scrollLeft()-(h||c.outerWidth(!0))-200},a.speed,a.easing,function(){B(f)});break;case "slideDown":c.css({display:"block",opacity:1}).animate({top:f?r(!(!a.follow[1]&&s||g)):j.scrollTop()-(w||c.outerHeight(!0))-200},a.speed,a.easing,function(){B(f)});break;default:c.stop().fadeTo(a.speed,f?1:0,function(){B(f)})}}function B(f){f?(d.data("bPopup",l),c.delegate(".bClose, ."+a.closeClass,"click."+e,t),a.modalClose&&b(".b-modal."+e).css("cursor","pointer").bind("click",t),!G&&(a.follow[0]||a.follow[1])&&d.bind("scroll."+e,function(){x&&c.dequeue().animate({left:a.follow[0]?n(!g):"auto",top:a.follow[1]?r(!g):"auto"},a.followSpeed,a.followEasing)}).bind("resize."+e,function(){if(x=A())clearTimeout(F),F=setTimeout(function(){z();c.dequeue().each(function(){g?b(this).css({left:m,top:q}):b(this).animate({left:a.follow[0]?n(!0):"auto",top:a.follow[1]?r(!0):"auto"},a.followSpeed,a.followEasing)})},50)}),a.escClose&&j.bind("keydown."+e,function(a){27==a.which&&t()}),k(C)):(c.hide(),k(a.onClose),a.loadUrl&&(a.contentContainer.empty(),c.css({height:"auto",width:"auto"})))}function n(a){return a?m+j.scrollLeft():m}function r(a){return a?q+j.scrollTop():q}function k(a){b.isFunction(a)&&a.call(c)}function z(){var b;s?b=a.position[1]:(b=((window.innerHeight||d.height())-c.outerHeight(!0))/2-a.amsl,b=b<y?y:b);q=b;m=p?a.position[0]:((window.innerWidth||d.width())-c.outerWidth(!0))/2;x=A()}function A(){return(window.innerHeight||d.height())>c.outerHeight(!0)+y&&(window.innerWidth||d.width())>c.outerWidth(!0)+y}b.isFunction(u)&&(C=u,u=null);var a=b.extend({},b.fn.bPopup.defaults,u);a.scrollBar||b("html").css("overflow","hidden");var c=this,j=b(document),d=b(window),G=/OS 6(_\d)+/i.test(navigator.userAgent),y=20,l=0,e,x,s,p,g,q,m,w,h,F;c.close=function(){a=this.data("bPopup");e="__b-popup"+d.data("bPopup")+"__";t()};return c.each(function(){if(!b(this).data("bPopup"))if(k(a.onOpen),l=(d.data("bPopup")||0)+1,e="__b-popup"+l+"__",s="auto"!==a.position[1],p="auto"!==a.position[0],g="fixed"===a.positionStyle,w=c.outerHeight(!0),h=c.outerWidth(!0),a.loadUrl)switch(a.contentContainer=b(a.contentContainer||c),a.content){case "iframe":var f=b('<iframe class="b-iframe" scrolling="no" frameborder="0"></iframe>');f.appendTo(a.contentContainer);w=c.outerHeight(!0);h=c.outerWidth(!0);v();f.attr("src",a.loadUrl);k(a.loadCallback);break;case "image":v();b("<img />").load(function(){k(a.loadCallback);E(b(this))}).attr("src",a.loadUrl).hide().appendTo(a.contentContainer);break;default:v(),b('<div class="b-ajax-wrapper"></div>').load(a.loadUrl,a.loadData,function(){k(a.loadCallback);E(b(this))}).hide().appendTo(a.contentContainer)}else v()})};b.fn.bPopup.defaults={amsl:50,appending:!0,appendTo:"body",closeClass:"b-close",content:"ajax",contentContainer:!1,easing:"swing",escClose:!0,follow:[!0,!0],followEasing:"swing",followSpeed:500,loadCallback:!1,loadData:!1,loadUrl:!1,modal:!0,modalClose:!0,modalColor:"#000",onClose:!1,onOpen:!1,opacity:0.7,position:["auto","auto"],positionStyle:"absolute",scrollBar:!0,speed:250,transition:"fadeIn",zIndex:9997}})(jQuery);

/* jquery.hoverIntent.minified.js */
 (function(e){e.fn.hoverIntent=function(t,n,r){var i={interval:100,sensitivity:7,timeout:0};if(typeof t==="object"){i=e.extend(i,t)}else if(e.isFunction(n)){i=e.extend(i,{over:t,out:n,selector:r})}else{i=e.extend(i,{over:t,out:t,selector:n})}var s,o,u,a;var f=function(e){s=e.pageX;o=e.pageY};var l=function(t,n){n.hoverIntent_t=clearTimeout(n.hoverIntent_t);if(Math.abs(u-s)+Math.abs(a-o)<i.sensitivity){e(n).off("mousemove.hoverIntent",f);n.hoverIntent_s=1;return i.over.apply(n,[t])}else{u=s;a=o;n.hoverIntent_t=setTimeout(function(){l(t,n)},i.interval)}};var c=function(e,t){t.hoverIntent_t=clearTimeout(t.hoverIntent_t);t.hoverIntent_s=0;return i.out.apply(t,[e])};var h=function(t){var n=jQuery.extend({},t);var r=this;if(r.hoverIntent_t){r.hoverIntent_t=clearTimeout(r.hoverIntent_t)}if(t.type=="mouseenter"){u=n.pageX;a=n.pageY;e(r).on("mousemove.hoverIntent",f);if(r.hoverIntent_s!=1){r.hoverIntent_t=setTimeout(function(){l(n,r)},i.interval)}}else{e(r).off("mousemove.hoverIntent",f);if(r.hoverIntent_s==1){r.hoverIntent_t=setTimeout(function(){c(n,r)},i.timeout)}}};return this.on({"mouseenter.hoverIntent":h,"mouseleave.hoverIntent":h},i.selector)}})(jQuery)


