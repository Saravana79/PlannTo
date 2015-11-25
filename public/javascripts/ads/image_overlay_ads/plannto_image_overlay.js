jQuery(document).ready(function () {
    //hide pixel img
    jQuery(".plannto-advertisement").siblings("img").hide()

    jQuery(".ad_img_tag").on("error", function()
    {
        var img_id = jQuery(this).attr('id')
        if (img_id == "item_details") {
            jQuery(this).attr('id', 'item')
            jQuery(this).attr("src", jQuery(this).attr('next_src'))
        }
        else if (img_id == "item")
        {
            jQuery(this).attr('id', 'default_image')
            jQuery(this).attr("src", jQuery(this).attr('default_src'))
        }
    });

    var stop_sliding = false

    jQuery(".item_details").hide();
    jQuery(".item_details").first().show();
    jQuery(".item_details").first().addClass('active')
    set_logo_url(jQuery(".item_details").first(), "shop-now")

    jQuery("#1").addClass('selected')

    // TODO: temporary commented

    if (1 != 1)
    {
        jQuery(".item_details").each(function (index) {

            if (index == 0)
                return

            var that = this;
            var t = setTimeout(function () {
                if (stop_sliding == false) {
                    jQuery(".item_details").hide();
                    jQuery(".item_details").removeClass('active')
                    jQuery("#pager2 a").removeClass('selected')

                    split_div = jQuery(that).attr('id').split('_')
                    jQuery("#" + split_div[split_div.length - 1]).addClass('selected')

                    jQuery(that).show();
                    jQuery(that).addClass('active')
                    set_logo_url(that, "shop-now")

                    if (index == (jQuery(".item_details").length - 1))
                        setTimeout(function () {
                            if (stop_sliding == false) {
                                jQuery(".item_details").last().hide()
                                jQuery(".item_details").removeClass('active')
                                jQuery("#pager2 a").removeClass('selected')
                                jQuery(".item_details").first().show();
                                jQuery(".item_details").first().addClass('active')
                                set_logo_url(jQuery(".item_details").first(), "shop-now")

                                jQuery("#1").addClass("selected")
                            }
                        }, 5000)
                }
            }, 5000 * index);
        });
    }



    jQuery(".next").click(function () {
        var current_div = jQuery(".item_details.active")
        jQuery(".item_details").hide();
        jQuery(".item_details").removeClass('active')
        jQuery("#pager2 a").removeClass('selected')

        var splited_val = jQuery(current_div).attr("id").split('_')

        if (parseInt(splited_val[splited_val.length - 1]) < jQuery(".item_details").length) {
            jQuery(current_div).next().show().addClass('active')
            set_logo_url(jQuery(current_div).next(), "shop-now")

            split_div = jQuery(current_div).next().attr("id").split('_')
            jQuery("#" + split_div[split_div.length - 1]).addClass('selected')
        }
        else {
            jQuery(".item_details").first().show().addClass('active')
            set_logo_url(jQuery(".item_details").first(), "shop-now")

            jQuery("#1").addClass('selected')
        }
    });


    jQuery(".prev").click(function () {
        var current_div = jQuery(".item_details.active")
        jQuery(".item_details").hide();
        jQuery(".item_details").removeClass('active')
        jQuery("#pager2 a").removeClass('selected')

        var splited_val = jQuery(current_div).attr("id").split('_')

        if (parseInt(splited_val[splited_val.length - 1]) > 1) {
            jQuery(current_div).prev().show().addClass('active')
            set_logo_url(jQuery(current_div).prev(), "shop-now")

            split_div = jQuery(current_div).prev().attr("id").split('_')
            jQuery("#" + split_div[split_div.length - 1]).addClass('selected')
        }
        else {
            jQuery(".item_details").last().show().addClass('active')
            set_logo_url(jQuery(".item_details").last(), "shop-now")

            last = jQuery(".item_details").length
            jQuery("#" + last).addClass('selected')
        }
    });

    jQuery("#pager2 a").click(function () {
        var that = this
        selected_id = jQuery(that).attr("id")
        selected_div = jQuery("#item_detail_" + selected_id)

        jQuery(".item_details").hide();
        jQuery(".item_details").removeClass('active')

        jQuery(selected_div).show()
        jQuery(selected_div).addClass('active')
        set_logo_url(jQuery(selected_div), "shop-now")

        jQuery("#pager2 a").removeClass('selected')
        jQuery(that).addClass('selected')
    })

    jQuery(".advt-block").click(function () {
        stop_sliding = true
    })

    // All place clickable

    jQuery(".plannto-advertisement.main_div").click(function(a)
    {
        var ids_list = []
        ids_list.push(a.target.id)
        ids_list.push(a.target.parentNode.id)
        ids_list.push(a.target.parentNode.parentNode.id)
        var present = jQuery.inArray("pager2", ids_list)
        if(present < 0)
        {

        ids_list = []
        ids_list.push(a.attr('class'))
        ids_list.push(a.target.parentNode.attr('class'))
        ids_list.push(a.target.parentNode.parentNode.attr('class'))
            var present = jQuery.inArray("owl-page", ids_list)
        }
        if (present < 0)
        {

            var x = a.target
            var d = jQuery(x).closest(".product-container")
            var shop_now_url = d.find(".shop-now").attr('href')

            if (shop_now_url == undefined)
            {
                var shop_now_url = jQuery(".item_details.active").find(".shop-now").attr('href')
            }

            window.open(shop_now_url, "_blank")
            return false;
        }
    });

});

function set_logo_url(that, class_name)
{
    var href_val = jQuery(that).find("."+class_name).attr('href')

    var image_src = jQuery(that).find(".vendor_image_src").attr('src')

    if (href_val == "" || href_val == undefined)
    {
        href_val = jQuery("."+class_name).attr('href')
    }
    jQuery(".logo").find('a img').attr('src', image_src)
    jQuery(".logo").find('a.vendor_image').attr('href', href_val)
}