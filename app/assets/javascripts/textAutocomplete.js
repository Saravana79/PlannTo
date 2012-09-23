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
        deleteFunctionName: "",
        has_parent: false
        
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
        $.addIdToTextField(settings.hidden_field, ui.item.id, settings.has_parent)
        }
        $.addTagToAutocomplete(fieldId, taggingField, settings, ui.item.value, ui.item.id, settings.has_parent);
           
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
            $.removeIdFromField(settings.hidden_field, deleteId, settings.has_parent);
        }
        $(this).closest('li').remove();
        if (settings.deleteFunctionName){
            data = new Object()
            data.id = deleteId;
            $.selectEvent(data, settings.deleteFunctionName)
        }
        return false;
    });
    
    jQuery.addIdToTextField = function(hidden_field, id, has_parent){
        if (has_parent == false){
           hidden_field = "#" + hidden_field
        }
        var formVal = $("" + hidden_field).val();
        var formValArray = formVal.toString() == "" ? [] : formVal.split(",")
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
    
    
    jQuery.addTagToAutocomplete = function(fieldId, taggingField, settings, value, id, has_parent) {
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
}   


