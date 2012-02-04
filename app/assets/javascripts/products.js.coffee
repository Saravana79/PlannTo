root = exports ? this
root.Product =
  load_buyer: ->
    $("#plan_to_buy").removeClass()
    $("#plan_to_buy_span").removeClass().addClass "action_btns btn_active"
    $("#plan_to_buy").addClass "btn_plantobuy_icon"
    $("#plan_to_buy").attr "href", "javascript:void(0)"
    $("#plan_to_follow").removeClass()
    $("#plan_to_follow").addClass "btn_followthiscar_icon"
    $("#plan_to_follow_span").removeClass().addClass "action_btns btn_active"
    $("#plan_to_follow").attr "href", "javascript:void(0)"

  load_owner: ->
    $("#plan_to_own").removeClass()
    $("#plan_to_own").addClass "btn_iwonit_icon"
    $("#plan_to_own_span").removeClass().addClass "action_btns btn_active"

    $("#plan_to_own").attr "href", "javascript:void(0)"
    $("#plan_to_buy").removeClass()
    $("#plan_to_buy").addClass "btn_plantobuy_icon"
    $("#plan_to_buy_span").removeClass().addClass "action_btns"
    $("#plan_to_buy").attr "href", "javascript:void(0)"
    $("#plan_to_follow").removeClass()
    $("#plan_to_follow").addClass "btn_followthiscar_icon"
    $("#plan_to_follow_span").removeClass().addClass "action_btns btn_active"
    $("#plan_to_follow").attr "href", "javascript:void(0)"

  load_follow: ->
    $("#plan_to_follow").removeClass()
    $("#plan_to_follow").addClass "btn_followthiscar_icon"
    $("#plan_to_buy").addClass "btn_plantobuy_icon"
    $("#plan_to_buy_span").removeClass("btn_active")
    $("#plan_to_own_span").removeClass("btn_active")
    $("#plan_to_follow_span").removeClass().addClass "action_btns btn_active"
    $("#plan_to_follow").attr "href", "javascript:void(0)"

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