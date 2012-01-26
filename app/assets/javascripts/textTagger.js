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
 *
 *
 */

$(document).ready(function(){
    $.textTagger = function(fieldId, taggingField, options){
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
            multiple: true,
            rounded: false,
            hidden_field: ""
        },
        settings = $.extend({}, defaults, options);
        $("#"+ fieldId).each(function(){
            $(this).bind('keypress', function(e) {
                if(e.keyCode==13){
            //  var text = $("#"+ fieldId).val();

            //  var add = true;
            //  $("#tag_list").find("li").each(function(index) {
            // var compText = text + "href='#'>"
            //   if ($(this).text().toString() == text.toString())  {
            //      add = false;
            //    }
            //  });

            // if ((text != "") && add == true)
            // {
            //    if (settings.multiple == false){
            //remove old tags is multiple tags are not allowed.
            //    $("#"+ taggingField).find("li").remove();
            //   }
            //  var str = "<li   style= 'line-height:35px;' id = 'textTaggers' class = 'textboxlist-bit textboxlist-bit-box textboxlist-bit-box-deletable '>" +text +"<a id= 'deleteTaggers' class='textboxlist-bit-box-deletebutton'></a></li>"
            //$(str).insertAfter('#' + taggingField);
            //    $(str).appendTo('#' + taggingField);
            //   $("#" + fieldId).val("")
            //    $('#' + fieldId).autocomplete("enable");
            //    if (settings.editMode){
            //       $(".textboxlist-bit-box-deletebutton").show();
            //     }
            //    else{
            //      $(".textboxlist-bit-box-deletebutton").hide();
            //     }
            //   }
            //    $("#"+ fieldId).val("");
            //  $(".textboxlist-bit-box-deletebutton").hide();
            }
            });
        });
        if (settings.addButton){
            var tagButton = "<button id='addTag'> Add </button>"

            $(tagButton).insertAfter("#"+ fieldId);
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
        $( "#" + fieldId ).autocomplete({
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
                type: "POST",
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
        };

        $('#addTag').live( 'click', function(){
            $.addTag(fieldId, taggingField, settings, $("#" + fieldId).val(), '');
        })

        $('#textTaggers').live('click', function(){
            })

        $('#deleteTag').live('click', function(){
            if (settings.hidden_field != ""){
                var deleteId = $(this).closest('li').attr('id').replace("textTaggers",'');
                $.removeIdFromField(settings.hidden_field, deleteId);
            }
            $(this).closest('li').remove();
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

    jQuery.addIdToField = function(hidden_field, id){
        var formVal = $("#" + hidden_field).val();
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
        $("#" + hidden_field).val(formValArray.toString())
    }

    jQuery.removeIdFromField = function(hidden_field, deleteId){
        var formVal = $("#" + hidden_field).val();
        var formValArray =  formVal == "" ?  [] : formVal.split(",")
        var idList = [];
        $.each(formValArray, function(index, value) {
            if (value.toString() != deleteId.toString())  {
                idList.push(value);
            }
        })
        $("#" + hidden_field).val(idList);
    }
    jQuery.doneEvent = function(fieldId, taggingField, editMode){
        if(editMode){
            $("#" + fieldId).hide();
            $("#addTag").hide();
            $("#doneButton").hide();
            $("#editTag").show();
        }
    }

    jQuery.setMode = function(fieldId, taggingField, editMode){
        if(editMode){
            var tagButton = "<button id='editTag'>Edit</button>"
            $(tagButton).insertAfter("#"+ taggingField);
            $("#" + fieldId).hide();
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
            $("#" + fieldId).val("")
            $("#" + fieldId).show();
            if (!$('#addTag').length) {
                var tagButton = "<button id=" + '"' +"addTag" + '"' + "> Add </button>"
                $(tagButton).insertAfter("#"+ fieldId);
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

    jQuery.addTag = function(fieldId, taggingField, settings, value, id) {
        var text = value;
        var add = true;
        $("#" + taggingField).find("li").each(function(index) {
            if ($(this).text().toString() == text.toString())  {
                add = false;
            }
        });
        if ((text != "") && add == true)
        {
            if (settings.multiple == false){
                $("#"+ taggingField).find("li").remove();
            }
            var listTagId = 'textTaggers' + id
            var list = "<li id='" + listTagId + "'" + " class='middlebg'  style= 'height:40px;'><span class='title_txt'>" + value + "<a id= 'deleteTag' class='icon_close'></a></span></li>" ;
            $(list).appendTo('#' + taggingField);
            $("#" + fieldId).val("")
            $('#' + fieldId).autocomplete("enable");
            if (settings.editMode || settings.close){
                var hideField = "ul#" +taggingField + " li span a.icon_close"
                $(hideField).show();
            }
            else{
                var hideField = "ul#" +taggingField + " li span a.icon_close"
                $(hideField).hide();
            }
        }
        $("#"+ fieldId).val("");
    }

});