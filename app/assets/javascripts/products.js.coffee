root = exports ? this
root.Product =
  load_buyer: ->
    $("#plan_to_buy").removeClass()
    $("#plan_to_buy_span").removeClass().addClass "tabstyle"
    $("#plan_to_buy").attr "href", "javascript:void(0)"
    $("#plan_to_follow").removeClass()
    $("#plan_to_follow_span").removeClass().addClass "tabstyle"
    $("#plan_to_follow").attr "href", "javascript:void(0)"

  load_owner: ->
    $("#plan_to_own").removeClass()
    $("#plan_to_own_span").removeClass().addClass "tabstyle"
    $("#plan_to_own").attr "href", "javascript:void(0)"
    $("#plan_to_buy").removeClass()
    $("#plan_to_buy_span").removeClass().addClass "tabstyle"
    $("#plan_to_buy").attr "href", "javascript:void(0)"
    $("#plan_to_follow").removeClass()
    $("#plan_to_follow_span").removeClass().addClass "tabstyle"
    $("#plan_to_follow").attr "href", "javascript:void(0)"

  load_follow: ->
    $("#plan_to_follow").removeClass()
    $("#plan_to_follow_span").removeClass().addClass "tabstyle"
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
      $("#usual2 ul").idTabs "tabs2"
      $("#specification").trigger "click"

  show_notice: (flash_message)->
    $("#comment-notice").html('<div class="flash notice">'+flash_message+'</div>').effect("highlight", {}, 3000);