$(function(){
    var ss = $(document).find("option:selected");
    $.each(ss, function(){
        var txt = $(this).text();
        $(this).parents(".selectBox").find("span").first().text(txt);
    });
    $(document).on("change", "select", function(){      //下拉框样式
        var txt = $(this).find("option:selected").first().text();
        $(this).parents(".selectBox").find("span").first().text(txt);
    });

    $(document).on("click", "input[type='checkbox']", function(){   //复选框样式
        var cb = $(this);
        if(cb.attr("checked")=="checked"){
            cb.parent().attr("class", "checkBox check");
        }else{
            cb.parent().attr("class", "checkBox");
        }
    });

    $(document).on("click", "input[type='radio']", function(){      //单选框样式
        var rd = $(this);
        var divs = rd.parents(".form_row").find("div.radioBox");
        $.each(divs, function(){
            $(this).attr("class", "radioBox");
        });
        rd.parent().attr("class", "radioBox check");
    });
})

function storage_new(name){
    popup("#"+name);
}