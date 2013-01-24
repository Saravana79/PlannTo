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

function intToFormat(nStr)
    {
     nStr += '';
     x = nStr.split('.');
     x1 = x[0];
     x2 = x.length > 1 ? '.' + x[1] :'';
  
     if (x2.length == 0) {
         x2 = '.00';
       } else if (x2.length == 2) {
         x2 = '.' + x[1] + ’0′;
       } else {
         x2 = '.' + x[1];
       }
     var rgx = /(\d+)(\d{3})/;
     var z = 0;
     var len = String(x1).length;
     var num = parseInt((len/2)-1);
 
      while (rgx.test(x1))
      {
        if(z > 0)
        {
          x1 = x1.replace(rgx, '$1' + ',' + '$2');
        }
        else
        {
          x1 = x1.replace(rgx, '$1' + ',' + '$2');
          rgx = /(\d+)(\d{2})/;
        }
        z++;
        num--;
        if(num == 0)
        {
          break;
        }
      }
     return x1 + x2;
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
            "top": (position.top -5)+ "px",
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
                    var searchCriteria = $("#which_type").val() + " "  + intToFormat(sliderVal[ 0 ]) + " " + $("#which_unit").val() + " - " + intToFormat(sliderVal[ 1 ]) + " "  + $("#which_unit").val()
                    $("#searchCriteriaLabel").html(searchCriteria)
                }
            });
        }
        else{
            $('#Slider' + attr_name).next(".jslider").show()
            $('#Slider' + attr_name).slider( "value", parseFloat(displayInfo.min_v), parseFloat(displayInfo.max_v) )
            //$( "#Slider" + attr_name).val( "" +parseFloat(displayInfo.min_v) + ";" + parseFloat(displayInfo.max_v) + "");
            var searchCriteria = $("#which_type").val() + " "  + intToFormat(min_v) + " " + $("#which_unit").val() + " - " + intToFormat(max_v) + " "  + $("#which_unit").val()
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
            "top": (position.top -5)+ "px",
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
		//to remove duplicate search criteria
	 	 if ($("#" +tagId + " span").text() == booleanObject.display_name){
	 	 	$("#" + $("#which_attribute").val()).hide();
	 	 	return false
	 	 }
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
            "top": (position.top -5)+ "px",
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
        "top": (position.top -5)+ "px",
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
            var value = "" + $("#which_type").val() + " "  + number_to_indian_currency(minValue) + " " + $("#which_unit").val() + " - " + number_to_indian_currency(maxValue) + " "  + $("#which_unit").val() + ""
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

    //$(".boxClick").mouseenter(function(){
    //    enableDocumentMouseOverEvent()
    //    $("#criteriaPopup").hide();
    //})

    $('.boxClick').live('click', function(){
        enableDocumentMouseOverEvent()
        $("#criteriaPopup").hide();
    });
  
  //  $(".box").mouseover(function() {
   //     enableDocumentMouseOverEvent()
   //     $(this).click();
  //  })

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
}

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
