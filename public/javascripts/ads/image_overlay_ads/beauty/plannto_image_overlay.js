console.log($(".product-container"))
$(".product-container").click(function()
{
    var shop_now = $(this).find(".shop-now")
    window.open(shop_now.attr("href"))
    return false;
});

$(document).ready(function()
{
    $(".product-container-top").hide()
    $("#1").show()
    $("#1").addClass("active")
    $(".planntocarosel-left").css("opacity", 0.2);

    var active_div = $(".active")
    var next_div = $(active_div).next()

    if (active_div.length == 0 || $(next_div).attr("class") == "planntocarosel-right")
    {
        $(".planntocarosel-right").css("opacity", 0.2);
        $(".planntocarosel-left").css("opacity", 0.2);
    }
});

$(".planntocarosel-left").live('click', function(event)
{
    var active_div = $(".active")
    var prev_div = $(active_div).prev()

    if ($(prev_div).next().attr("class") == "planntocarosel-right")
    {
        $(".planntocarosel-right").css("opacity", 0.2);
    }
    else
    {
        $(".planntocarosel-right").css("opacity", 1);
    }

    if ($(prev_div).prev().attr("class") == "planntocarosel-left")
    {
        $(".planntocarosel-left").css("opacity", 0.2);
    }

    if ($(prev_div).attr("class") != "planntocarosel-left")
    {
        $(".product-container-top").hide()
        $(prev_div).show()
        $(".product-container-top").removeClass("active")
        $(prev_div).addClass("active")
    }
    event.preventDefault();
    return false;
});

$(".planntocarosel-right").live('click', function(event)
{
    var active_div = $(".active")
    var next_div = $(active_div).next()

    if ($(next_div).next().attr("class") == "planntocarosel-right")
    {
        $(".planntocarosel-right").css("opacity", 0.2);
    }

    if ($(next_div).prev().attr("class") != "planntocarosel-left")
    {
        $(".planntocarosel-left").css("opacity", 1);;
    }

    if ($(next_div).attr("class") != "planntocarosel-right")
    {
        $(".product-container-top").hide()
        $(next_div).show()
        $(".product-container-top").removeClass("active")
        $(next_div).addClass("active")
    }
    event.preventDefault();
    return false;
});