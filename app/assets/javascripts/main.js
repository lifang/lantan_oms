// JavaScript Document
$(function(){		
    var ch = document.documentElement.clientHeight;
    if(ch > $(".loginBg").height()){
        $(".loginBg").css("height",ch);
    }
    var cw = document.documentElement.clientWidth;
    if($(".leftBox")){
        $(".leftBox").css("left",(cw-900)/2 - $(".leftBox").width() - 20 + "px");
    }
	
    $(".loginAct").on("click",".chkbox",function(){
        $(this).toggleClass("check");
    });
		
	
    $("tr").each(function(){
        var table = $(this).parents(".table1");
        var i = table.find("tr").index($(this));
        if(i % 2 ==1 && i != 0){
            $(this).css("background","#f5f5f5");
        }
    });
	
    $(".selectBox").on("click","option",function(){
        $(this).parents(".selectBox").find("span").text($(this).val());
    });
    $(".selectBox2").on("click","option",function(){
        $(this).parents(".selectBox2").find("span").text($(this).val());
    });
	
    $(".paidBill").click(function(){
        $(this).toggleClass("open");
    });
	
	
});

function tishi(message){
    $("#tishi_div").find("p").first().html(message);
    var scolltop = document.body.scrollTop|document.documentElement.scrollTop;
    var win_height = document.documentElement.clientHeight;//jQuery(document).height();
    var z_layer_height = $("#tishi_div").height();
    $("#tishi_div").css('top',(win_height-z_layer_height)/2 + scolltop);
    var doc_width = $(document).width();
    var layer_width = $("#tishi_div").width();
    $("#tishi_div").css('left',(doc_width-layer_width)/2);
    $("#tishi_div").css('display','block');
    jQuery('#tishi_div').fadeTo("slow",1);
    $("#tishi_div .x").click(function(){
        $("#tishi_div").css('display','none');
        //stopPropagation(arguments[1]);
    })
    setTimeout(function(){
        jQuery('#tishi_div').fadeTo("slow",0);
    }, 3000);
    setTimeout(function(){
        $("#tishi_div").css('display','none');
    }, 3000);

}

function popup(t){      //弹出一级菜单
    var win_width = $(window).width();
    var doc_height = $(document).height();
    var layer_width = $(t).width();

    var scolltop = document.body.scrollTop|document.documentElement.scrollTop;
    var win_height = document.documentElement.clientHeight;
    var z_layer_height = $(t).height();

    var left = (win_width-layer_width)/2;
    var top = (win_height-z_layer_height)/2 + scolltop;
    $(".second_bg").css("height",doc_height);
    $(t).css('top',top);
    $(t).css('left',left);
    $(".second_bg").css("display","block");
    $(t).css('display','block');

    $(t+" .close").click(function(){
        $(this).parents(t).css("display","none");
        $(".second_bg").css("display","none");
    });
}

function popup2(t){      //弹出二级菜单
    var win_width = $(window).width();
    var doc_height = $(document).height();
    var layer_width = $(t).width();

    var scolltop = document.body.scrollTop|document.documentElement.scrollTop;
    var win_height = document.documentElement.clientHeight;
    var z_layer_height = $(t).height();

    var left = (win_width-layer_width)/2;
    var top = (win_height-z_layer_height)/2 + scolltop;
    $(".second_bg2").css("height",doc_height);
    $(t).css('top',top);
    $(t).css('left',left);
    $(".second_bg2").css("display","block");
    $(t).css('display','block');

    $(t+" .close2").click(function(){
        $(this).parents(t).css("display","none");
        $(".second_bg2").css("display","none");
    });
}

function get_str_len(str){      //获取名称长度
    var length = str.length;
    var a = 0;
    for(var i=0;i<length;i++){
        var charCode = str.charCodeAt(i);
        if(charCode>=0 && charCode<=128){
            a += 1;
        }else{
            a += 2;
        }
    }
    return a;
}

function show_order(store_id, order_id){    //点击显示订单详情
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/customers/show_order",
        dataType: "script",
        data: {
            order_id : order_id
        },
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}
