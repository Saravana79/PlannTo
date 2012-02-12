root = exports ? this
root.Product =
  load_buyer: (medium, message, follow_message) ->
    $("#plan_to_buy").removeClass().addClass "plan_to_buy_icon_selected"
    $("#plan_to_buy_span").removeClass().addClass "action_btns_selected"+medium
    $("#plan_to_buy_span").attr "title", message    
    $("#plan_to_follow_span").attr "title", follow_message
    $("#plan_to_follow").removeClass().addClass "plan_to_follow_icon_selected"
    $("#plan_to_follow_span").removeClass().addClass "action_btns_selected"+medium
    $("#plan_to_own").removeClass().addClass "plan_to_own_icon"
    $("#plan_to_own_span").removeClass().addClass "action_btns"+medium
    buy_href_follow = $("#plan_to_buy").attr("href")
    $("#plan_to_buy").attr("href", buy_href_follow+'&unfollow=true');
    follow_href_follow = $("#plan_to_follow").attr("href")
    $("#plan_to_follow").attr("href", buy_href_follow+'&unfollow=true');

  load_owner: (medium, message, follow_message) ->
    $("#plan_to_own").removeClass().addClass "plan_to_own_icon_selected"
    $("#plan_to_own_span").removeClass().addClass "action_btns_selected"+medium
    $("#plan_to_own_span").attr "title", message
    $("#plan_to_follow_span").attr "title", follow_message
    $("#plan_to_follow").removeClass().addClass "plan_to_follow_icon_selected"
    $("#plan_to_follow_span").removeClass().addClass "action_btns_selected"+medium
    own_href_follow = $("#plan_to_own").attr("href")
    $("#plan_to_own").attr("href", own_href_follow+'&unfollow=true');
    follow_href_follow = $("#plan_to_follow").attr("href")
    $("#plan_to_follow").attr("href", follow_href_follow+'&unfollow=true');
    $("#plan_to_buy_span").removeClass()
    $("#plan_to_buy").removeClass().addClass "plan_to_buy_icon"
    $("#plan_to_buy_span").addClass "action_btns"    

  load_follow: (medium, follow_message) ->
    $("#plan_to_follow").removeClass()
    $("#plan_to_follow").removeClass().addClass "plan_to_follow_icon_selected"
    $("#plan_to_follow_span").removeClass().addClass "action_btns_selected"+medium
    $("#plan_to_follow_span").attr "title", follow_message
    $("#plan_to_buy").removeClass().addClass "plan_to_buy_icon"
    $("#plan_to_buy_span").removeClass().addClass "action_btns"+medium
    $("#plan_to_own_span").removeClass().addClass "action_btns"+medium
    $("#plan_to_own").removeClass().addClass "plan_to_own_icon"
    follow_href_follow = $("#plan_to_follow").attr("href")
    $("#plan_to_follow").attr("href", follow_href_follow+'&unfollow=true');

  unload_buyer: (medium, message, follow_message) =>
    $("#plan_to_buy").removeClass().addClass "plan_to_buy_icon"
    $("#plan_to_buy_span").removeClass().addClass "action_btns"+medium
    $("#plan_to_buy_span").attr "title", message
    $("#plan_to_follow").removeClass().addClass "plan_to_follow_icon"
    $("#plan_to_follow_span").removeClass().addClass "action_btns"+medium
    $("#plan_to_follow_span").attr "title", follow_message
    follow_href_follow = $("#plan_to_follow").attr("href")
    $("#plan_to_follow").attr("href", Product.remove_unfollow_query_string(follow_href_follow, "Follow"));
    buy_href_follow = $("#plan_to_buy").attr("href")
    $("#plan_to_buy").attr("href", Product.remove_unfollow_query_string(buy_href_follow, "Buyer"));

  unload_owner: (medium, message, follow_message) ->
    $("#plan_to_own").removeClass().addClass "plan_to_own_icon"
    $("#plan_to_own_span").removeClass().addClass "action_btns"+medium
    $("#plan_to_own_span").attr "title", message
    $("#plan_to_follow").removeClass().addClass "plan_to_follow_icon"
    $("#plan_to_follow_span").removeClass().addClass "action_btns"+medium
    $("#plan_to_follow_span").attr "title", follow_message
    own_href_follow = $("#plan_to_own").attr("href")
    $("#plan_to_own").attr("href", Product.remove_unfollow_query_string(own_href_follow, "Owner"));
    follow_href_follow = $("#plan_to_follow").attr("href")
    $("#plan_to_follow").attr("href", Product.remove_unfollow_query_string(follow_href_follow, "Follow"));



  unload_follow: (medium, follow_message) ->
    $("#plan_to_follow").removeClass().addClass "plan_to_follow_icon"
    $("#plan_to_follow_span").removeClass().addClass "action_btns"+medium
    $("#plan_to_buy").removeClass().addClass "plan_to_buy_icon"
    $("#plan_to_buy_span").removeClass().addClass "action_btns"+medium
    $("#plan_to_own").removeClass().addClass "plan_to_own_icon"
    $("#plan_to_own_span").removeClass().addClass "action_btns"+medium
    $("#plan_to_follow_span").attr "title", follow_message
    follow_href_follow = $("#plan_to_follow").attr("href")
    $("#plan_to_follow").attr("href", Product.remove_unfollow_query_string(follow_href_follow, "Follow"));

  remove_unfollow_query_string: (url_path, follow_type) ->
    urlparts= url_path.split('?');
    pars= urlparts[1].split(/[&;]/g);
    follow_type_var = pars[0].split("=")[0]
    urlparts[0] + "?" +follow_type_var+"="+follow_type

  hover_follow_but: (but_object, from_message, to_message) ->
    $(but_object).hover ( ->
        $(this).html(to_message)
        $(".PlanntoBuyBtn span[title]").tooltip().getTip()[0].innerText = $(".PlanntoBuyBtn span[title]").tooltip().getTrigger()[0].getAttribute("title");
      ), ->
        $(this).html(from_message)
        $(".PlanntoBuyBtn span[title]").tooltip().getTip()[0].innerText = $(".PlanntoBuyBtn span[title]").tooltip().getTrigger()[0].getAttribute("title");


  related_products: (related_product_url) ->
    $(document).ready ->
      $.ajax
        url: related_product_url
        dataType: "html"
        success: (data) ->
          $("#uisideRelatedProduct").html data

  load_signout_user_link: ->
    $("#plan_to_own").attr "href", "javascript:void(0)"
    $("#plan_to_buy").attr "href", "javascript:void(0)"
    $("#plan_to_follow").attr "href", "javascript:void(0)"
    $("#plan_to_buy_select").attr "data-url", "javascript:void(0)"

  login_dialog: ->
    $("#dialog-form").dialog
      autoOpen: false
      height: 300
      width: 350
      modal: true
      title: "Login"
      buttons:
        "Sign in": ->
          bValid = true
          if bValid
            $("#user_new").submit()
            $(this).dialog "close"

        Cancel: ->
          $(this).dialog "close"

      close: ->
        allFields.val("").removeClass "ui-state-error"

  show_login_dialog: (dom_elements) ->
    $(dom_elements).click ->
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
