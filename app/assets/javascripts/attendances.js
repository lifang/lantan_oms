$(function(){
    var ss = $(".searchBox").find("option:selected");
    $.each(ss, function(){
        var txt = $(this).text();
        $(this).parents(".selectBox").find("span").first().text(txt);
    });

    $(".searchBox").on("change", "select", function(){
        var txt = $(this).find("option:selected").first().text();
        $(this).parents(".selectBox").find("span").first().text(txt);
    })
})