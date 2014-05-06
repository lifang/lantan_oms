$(function(){
    var spans = $("#shigongxianchang").find("span[name='daojishi']")
    $.each(spans, function(){
        var span = $(this);
        var seconds = parseInt(span.attr("sec"));
        if(seconds <= 0){
            span.text("时间到");
        }else{
            countdown(seconds, span)
        }
    })
})

function countdown(seconds, obj){   //倒计时
    var sdd = setInterval(function(){
        if(seconds > 0){
            var h = "";
            var m = "";
            var s = "";
            var hour = parseInt(seconds/3600);
            if(hour >= 10){
                h = hour;
            }else{
                h = "0"+hour;
            };
            var minute = parseInt((seconds-(hour*3600))/60);
            if(minute >= 10){
                m = minute;
            }else{
                m = "0"+minute;
            };
            var second = seconds-((hour*3600)+(minute*60));
            if(second >= 10){
                s = second
            }else{
                s = "0"+second;
            };
            obj.text(h+":"+m+":"+s);
        }else{
            clearInterval(sdd);
            obj.text("时间到");
        };
        seconds = seconds - 1;
    }, 1000);
}

function show_work_order(store_id, work_order_id){
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/stations/"+work_order_id,
        dataType: "script",
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}

