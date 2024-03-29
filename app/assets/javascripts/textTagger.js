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
            minLength: 1,
            delay: 800,
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
            .append("<a>" + "<div style='margin-left:5px;float:left' class='autocompletediv'><img width='40' height='40' onerror='this.error=null;this.src=\"http://cdn1.plannto.com/items/mobile/medium/default_mobile.jpeg\"' src='" + item.imgsrc + "' /></div>" + "<div style='margin-left:53px;'><span class='atext'>" + item.value + "</span><br/><span class ='atext'>" + item.type + "</span></div></a>")
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