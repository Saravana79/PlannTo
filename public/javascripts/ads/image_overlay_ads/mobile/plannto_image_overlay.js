$(document).ready(function () {
    //hide pixel img
    $(".plannto-advertisement").siblings("img").hide()

    $(".ad_img_tag").on("error", function()
    {
        var img_id = $(this).attr('id')
        if (img_id == "item_details") {
            $(this).attr('id', 'item')
            $(this).attr("src", $(this).attr('next_src'))
        }
        else if (img_id == "item")
        {
            $(this).attr('id', 'default_image')
            $(this).attr("src", $(this).attr('default_src'))
        }
    });

    var stop_sliding = false

    $(".item_details").hide();
    $(".item_details").first().show();
    $(".item_details").first().addClass('active')
    set_logo_url($(".item_details").first(), "shop-now")

    $("#1").addClass('selected')

    // TODO: temporary commented

    if (1 != 1)
    {
        $(".item_details").each(function (index) {

            if (index == 0)
                return

            var that = this;
            var t = setTimeout(function () {
                if (stop_sliding == false) {
                    $(".item_details").hide();
                    $(".item_details").removeClass('active')
                    $("#pager2 a").removeClass('selected')

                    split_div = $(that).attr('id').split('_')
                    $("#" + split_div[split_div.length - 1]).addClass('selected')

                    $(that).show();
                    $(that).addClass('active')
                    set_logo_url(that, "shop-now")

                    if (index == ($(".item_details").length - 1))
                        setTimeout(function () {
                            if (stop_sliding == false) {
                                $(".item_details").last().hide()
                                $(".item_details").removeClass('active')
                                $("#pager2 a").removeClass('selected')
                                $(".item_details").first().show();
                                $(".item_details").first().addClass('active')
                                set_logo_url($(".item_details").first(), "shop-now")

                                $("#1").addClass("selected")
                            }
                        }, 5000)
                }
            }, 5000 * index);
        });
    }



    $(".next").click(function () {
        var current_div = $(".item_details.active")
        $(".item_details").hide();
        $(".item_details").removeClass('active')
        $("#pager2 a").removeClass('selected')

        var splited_val = $(current_div).attr("id").split('_')

        if (parseInt(splited_val[splited_val.length - 1]) < $(".item_details").length) {
            $(current_div).next().show().addClass('active')
            set_logo_url($(current_div).next(), "shop-now")

            split_div = $(current_div).next().attr("id").split('_')
            $("#" + split_div[split_div.length - 1]).addClass('selected')
        }
        else {
            $(".item_details").first().show().addClass('active')
            set_logo_url($(".item_details").first(), "shop-now")

            $("#1").addClass('selected')
        }
    });


    $(".prev").click(function () {
        var current_div = $(".item_details.active")
        $(".item_details").hide();
        $(".item_details").removeClass('active')
        $("#pager2 a").removeClass('selected')

        var splited_val = $(current_div).attr("id").split('_')

        if (parseInt(splited_val[splited_val.length - 1]) > 1) {
            $(current_div).prev().show().addClass('active')
            set_logo_url($(current_div).prev(), "shop-now")

            split_div = $(current_div).prev().attr("id").split('_')
            $("#" + split_div[split_div.length - 1]).addClass('selected')
        }
        else {
            $(".item_details").last().show().addClass('active')
            set_logo_url($(".item_details").last(), "shop-now")

            last = $(".item_details").length
            $("#" + last).addClass('selected')
        }
    });

    $("#pager2 a").click(function () {
        var that = this
        selected_id = $(that).attr("id")
        selected_div = $("#item_detail_" + selected_id)

        $(".item_details").hide();
        $(".item_details").removeClass('active')

        $(selected_div).show()
        $(selected_div).addClass('active')
        set_logo_url($(selected_div), "shop-now")

        $("#pager2 a").removeClass('selected')
        $(that).addClass('selected')
    })

    $(".advt-block").click(function () {
        stop_sliding = true
    })

    // All place clickable

    $(".plannto-advertisement.main_div").click(function(a)
    {
        var ids_list = []
        ids_list.push(a.target.id)
        ids_list.push(a.target.parentNode.id)
        ids_list.push(a.target.parentNode.parentNode.id)
        var present = $.inArray("pager2", ids_list)
        if (present < 0)
        {

            var x = a.target
            var d = $(x).closest(".product-container")
            var shop_now_url = d.find(".shop-now").attr('href')

            if (shop_now_url == undefined)
            {
                var shop_now_url = $(".item_details.active").find(".shop-now").attr('href')
            }

            window.open(shop_now_url, "_blank")
            return false;
        }
    });

});

function set_logo_url(that, class_name)
{
    var href_val = $(that).find("."+class_name).attr('href')

    var image_src = $(that).find(".vendor_image_src").attr('src')

    if (href_val == "" || href_val == undefined)
    {
        href_val = $("."+class_name).attr('href')
    }
    $(".logo").find('a img').attr('src', image_src)
    $(".logo").find('a.vendor_image').attr('href', href_val)
}