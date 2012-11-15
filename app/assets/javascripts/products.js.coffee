root = exports ? this
root.Product =
  load_buyer: (item_id, medium, message, follow_message) ->
    $("#plan_to_buy"+item_id).removeClass().addClass "plan_to_buy_icon_selected"+medium
    $("#plan_to_buy_span"+item_id).removeClass().addClass "action_btns_selected"+medium
    $("#plan_to_buy"+item_id).attr("title", message)
    $("#plan_to_follow"+item_id).attr("title", follow_message)
    $("#plan_to_follow"+item_id).removeClass().addClass "plan_to_follow_icon"+medium
    $("#plan_to_follow_span"+item_id).removeClass().addClass "action_btns"+medium
    $("#plan_to_own"+item_id).removeClass().addClass "plan_to_own_icon"+medium
    $("#plan_to_own_span"+item_id).removeClass().addClass "action_btns"+medium
    buy_href_follow = $("#plan_to_buy"+item_id).attr("href")
    $("#plan_to_buy"+item_id).attr("href", buy_href_follow+'&unfollow=true');
    

  load_owner: (item_id, medium, message, follow_message) ->
    $("#plan_to_own"+item_id).removeClass().addClass "plan_to_own_icon_selected"+medium
    $("#plan_to_own_span"+item_id).removeClass().addClass "action_btns_selected"+medium
    $("#plan_to_own"+item_id).attr("title", message)
    $("#plan_to_follow"+item_id).attr("title", follow_message)
    $("#plan_to_follow"+item_id).removeClass().addClass "plan_to_follow_icon"+medium
    $("#plan_to_follow_span"+item_id).removeClass().addClass "action_btns"+medium
    own_href_follow = $("#plan_to_own"+item_id).attr("href")    
    $("#plan_to_own"+item_id).attr("href", own_href_follow+'&unfollow=true');
    $("#plan_to_buy_span"+item_id).removeClass()
    $("#plan_to_buy"+item_id).removeClass().addClass "plan_to_buy_icon"+medium
    $("#plan_to_buy_span"+item_id).addClass "action_btns"+medium

  load_follow: (item_id, medium, follow_message) ->
    $("#plan_to_follow"+item_id).removeClass()
    $("#plan_to_follow"+item_id).removeClass().addClass "plan_to_follow_icon_selected"+medium
    $("#plan_to_follow_span"+item_id).removeClass().addClass "action_btns_selected"+medium
    $("#plan_to_follow"+item_id).attr("title", follow_message)
    $("#plan_to_buy"+item_id).removeClass().addClass "plan_to_buy_icon"+medium
    $("#plan_to_buy_span"+item_id).removeClass().addClass "action_btns"+medium
    $("#plan_to_own_span"+item_id).removeClass().addClass "action_btns"+medium
    $("#plan_to_own"+item_id).removeClass().addClass "plan_to_own_icon"+medium
    follow_href_follow = $("#plan_to_follow"+item_id).attr("href")
    $("#plan_to_follow"+item_id).attr("href", follow_href_follow+'&unfollow=true');

  unload_buyer: (item_id, medium, message, follow_message) =>
    $("#plan_to_buy"+item_id).removeClass().addClass "plan_to_buy_icon"+medium
    $("#plan_to_buy_span"+item_id).removeClass().addClass "action_btns"+medium
    $("#plan_to_buy"+item_id).attr("title", message)
    $("#plan_to_follow"+item_id).attr("title", follow_message)
    $("#plan_to_follow"+item_id).removeClass().addClass "plan_to_follow_icon"+medium
    $("#plan_to_follow_span"+item_id).removeClass().addClass "action_btns"+medium
    buy_href_follow = $("#plan_to_buy"+item_id).attr("href")
    $("#plan_to_buy"+item_id).attr("href", Product.remove_unfollow_query_string(buy_href_follow, "buyer"));

  unload_owner: (item_id, medium, message, follow_message) ->
    $("#plan_to_own"+item_id).removeClass().addClass "plan_to_own_icon"+medium
    $("#plan_to_own_span"+item_id).removeClass().addClass "action_btns"+medium
    $("#plan_to_own"+item_id).attr("title", message)
    $("#plan_to_follow"+item_id).attr("title", follow_message)
    $("#plan_to_follow"+item_id).removeClass().addClass "plan_to_follow_icon"+medium
    $("#plan_to_follow_span"+item_id).removeClass().addClass "action_btns"+medium
    own_href_follow = $("#plan_to_own"+item_id).attr("href")
    $("#plan_to_own"+item_id).attr("href", Product.remove_unfollow_query_string(own_href_follow, "owner"));



  unload_follow: (item_id, medium, follow_message) ->
    $("#plan_to_follow"+item_id).removeClass().addClass "plan_to_follow_icon"+medium
    $("#plan_to_follow_span"+item_id).removeClass().addClass "action_btns"+medium
    $("#plan_to_buy"+item_id).removeClass().addClass "plan_to_buy_icon"+medium
    $("#plan_to_buy_span"+item_id).removeClass().addClass "action_btns"+medium
    $("#plan_to_own"+item_id).removeClass().addClass "plan_to_own_icon"+medium
    $("#plan_to_own_span"+item_id).removeClass().addClass "action_btns"+medium
    $("#plan_to_follow"+item_id).attr("title", follow_message)
    follow_href_follow = $("#plan_to_follow"+item_id).attr("href")
    $("#plan_to_follow"+item_id).attr("href", Product.remove_unfollow_query_string(follow_href_follow, "follower"));

  remove_unfollow_query_string: (url_path, follow_type) ->
    urlparts= url_path.split('?');
    pars= urlparts[1].split(/[&;]/g);
    pars.pop();    
    urlparts[0] + "?" +pars.join('&')

  hover_follow_but: (but_object, from_message, to_message) ->
    $(but_object).hover ( ->
        $(this).html(to_message)
      ), ->
        $(this).html(from_message)


  related_products: (related_product_url) ->
    $(document).ready ->
      $.ajax
        url: related_product_url
        dataType: "html"
        success: (data) ->
          $("#uisideRelatedProduct").html data

  load_signout_user_link: ->
    $("#plan_to_buy_select").attr "data-url", "javascript:void(0)"

  login_dialog: ->
    $("#dialog-form").dialog
      autoOpen: false
      height: 480
      width: 275
      modal: true
     
      
      close: ->
        allFields.val("").removeClass "ui-state-error"

  show_login_dialog: (dom_elements) ->
    $(dom_elements).click ->
      $(".Close_dialog").show()
      $(".ui-dialog-titlebar").hide()
      $("#dialog-form").dialog "open"


  show_login_dialog_change: (dom_elements) ->
    $(dom_elements).change ->
      $("#dialog-form").dialog "open"

  hide_login_dialog: ->
    $("#dialog-form").hide();

  detailed_specification: ->
    $("#detailed_specification").click ->
      $("#usual2 ul").idTabs "tabs5"
      $("#specification").trigger "click"
      $("#specification").closest("ul").find("li").each (index) ->
        $(this).removeClass "tab_active"  if $(this).hasClass("tab_active")
        $("#specification").closest("li").addClass "tab_active"

  show_notice: (flash_message)->
    $("#comment-notice").html('<div class="flash notice">'+flash_message+'</div>').effect("highlight", {}, 3000);

  invite_dialog: ->
   $("#dialog-invite-form").dialog
     autoOpen: false
     height: 300
     width: 350
     modal: true
     title: "Invite"
     buttons:
       "Send": ->
         bValid = true
         if bValid
           $("#new_invitation").submit()

       Cancel: ->
         $(this).dialog "close"

     close: ->
       $(this).find(":input").val("").removeClass "ui-state-error"
   
  show_invite_dialog: (dom_elements) ->
   $(dom_elements).click ->
    id = $(this).attr('id');
    if id=='invite_buy'
      $('#invitation_follow_type').val(0);
    else if id =='invite_own'
     $('#invitation_follow_type').val(1);
    else
     $('#invitation_follow_type').val(2);
    $("#dialog-invite-form").dialog "open"
