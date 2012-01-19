
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


  function searchData(){
    $.get('/search',$("#searchForm").serialize(),null,"script");
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
  
$(document).ready(function(){
  $('div.pagination a').live('click', function(){
    var page = $(this).text()
    var current = $('em.current').text();
    if (page == "← Previous"){
      page = parseInt(current) -1
    }
    else if (page == "Next →"){
      page = parseInt(current) + 1
    }
    $("#page").val(page)
    $.get('/search',$("#searchForm").serialize(),null,"script");
    return false;
  })

});