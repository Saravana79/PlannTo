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

            .append("<a>" + "<div style='margin-left:5px;float:left'><img width='40' height='30' src='" + item.imgsrc + "' /></div>" + "<div style='margin-left:53px;'><span class='atext'>" + item.value + "</span><br/><span class ='atext'>" + item.type + "</span></div></a>")
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


