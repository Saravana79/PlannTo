console.log(jQuery(".product-container"))
jQuery(".product-container").click(function()
{
    var shop_now = jQuery(this).find(".shop-now")
    window.open(shop_now.attr("href"))
    return false;
});

jQuery(document).ready(function()
{
    jQuery(".product-container-top").hide()
    jQuery("#1").show()
    jQuery("#1").addClass("active")
    jQuery(".planntocarosel-left").css("opacity", 0.2);

    var active_div = jQuery(".active")
    var next_div = jQuery(active_div).next()

    if (active_div.length == 0 || jQuery(next_div).attr("class") == "planntocarosel-right")
    {
        jQuery(".planntocarosel-right").css("opacity", 0.2);
        jQuery(".planntocarosel-left").css("opacity", 0.2);
    }
});

jQuery(".planntocarosel-left").live('click', function(event)
{
    var active_div = jQuery(".active")
    var prev_div = jQuery(active_div).prev()

    if (jQuery(prev_div).next().attr("class") == "planntocarosel-right")
    {
        jQuery(".planntocarosel-right").css("opacity", 0.2);
    }
    else
    {
        jQuery(".planntocarosel-right").css("opacity", 1);
    }

    if (jQuery(prev_div).prev().attr("class") == "planntocarosel-left")
    {
        jQuery(".planntocarosel-left").css("opacity", 0.2);
    }

    if (jQuery(prev_div).attr("class") != "planntocarosel-left")
    {
        jQuery(".product-container-top").hide()
        jQuery(prev_div).show()
        jQuery(".product-container-top").removeClass("active")
        jQuery(prev_div).addClass("active")
    }
    event.preventDefault();
    return false;
});

jQuery(".planntocarosel-right").live('click', function(event)
{
    var active_div = jQuery(".active")
    var next_div = jQuery(active_div).next()

    if (jQuery(next_div).next().attr("class") == "planntocarosel-right")
    {
        jQuery(".planntocarosel-right").css("opacity", 0.2);
    }

    if (jQuery(next_div).prev().attr("class") != "planntocarosel-left")
    {
        jQuery(".planntocarosel-left").css("opacity", 1);;
    }

    if (jQuery(next_div).attr("class") != "planntocarosel-right")
    {
        jQuery(".product-container-top").hide()
        jQuery(next_div).show()
        jQuery(".product-container-top").removeClass("active")
        jQuery(next_div).addClass("active")
    }
    event.preventDefault();
    return false;
});