$(function(){
    var ss = $("#search_revi_form").find("option:selected");
    $.each(ss, function(){
        var txt = $(this).text();
        $(this).parents(".selectBox").find("span").first().text(txt);
    });

    $("#search_revi_form").on("change", "select", function(){
        var txt = $(this).find("option:selected").text();
        $(this).parent().find("span").first().text(txt);
    });
})

function search_revi_select_type(obj, type){    //选择消费次数或者消费满..元
    var flag = $(obj).attr("checked")=="checked";
    if(flag){
        $(obj).parent().attr("class", "checkBox check");
        if(type==1){    //消费满...次
            $("#search_revi_count").removeAttr("disabled");
        }else if(type==2){  //消费满..元
            $("#search_revi_money").removeAttr("disabled");
        }
    }else{
        $(obj).parent().attr("class", "checkBox");
        if(type==1){    //消费满...次
            $("#search_revi_count").val("");
            $("#search_revi_count").attr("disabled", "disabled");
        }else if(type==2){  //消费满..元
            $("#search_revi_money").val("");
            $("#search_revi_money").attr("disabled", "disabled");
        }
    }
}

function search_revi_valid(obj){
    var flag = true;
    var s_time = $("#search_revi_st_time").val();
    var e_time = $("#search_revi_end_time").val();
    if(s_time!="" && e_time!=""){
        var st_time = new Date(s_time.replace("-", "/"));
        var ed_time = new Date(e_time.replace("-", "/"));
        if(st_time>ed_time){
            tishi("起始时间不得大于结束时间!");
            flag = false;
        }
    }
    if(flag){
        var car_num = $.trim($("#search_revi_carnum").val());
        var ing_flag = new RegExp(/^[0-9]*[1-9][0-9]*$/);
        var pattern = new RegExp("[`~@#$^&*()=:;,\\[\\].<>?~！@#￥……&*（）——|{}。，、？-]");
        var count_ele = $("#search_revi_count");
        var money_ele = $("#search_revi_money");
        if(car_num!="" && (pattern.test(car_num)==true || car_num.length != 7)){
            tishi("车牌号码格式不正确!");
        }else if(count_ele.attr("disabled")!="disabled" && $.trim(count_ele.val())=="" ){
            tishi("请输入消费次数!");
        }else if(count_ele.attr("disabled")!="disabled" && ing_flag.test($.trim(count_ele.val()))==false){
            tishi("消费次数为大于等于1的整数!");
        }else if(money_ele.attr("disabled")!="disabled" && $.trim(money_ele.val())=="" ){
            tishi("请输入消费金额!");
        }else if(money_ele.attr("disabled")!="disabled" && ing_flag.test($.trim(money_ele.val()))==false){
            tishi("消费金额为大于零的整数!");
        }else{
            popup("#waiting");
            $(obj).parents("form").submit();
        }
    }
}

function new_revisit(store_id, order_id){       //点击回访
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/revisits/new",
        dataType: "script",
        data: {order_id : order_id},
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}

function new_revi_valid(obj){
    var title = $.trim($("#revi_title").val());
    var con = $.trim($("#revi_content").val());
    var answer = $.trim($("#revi_answer").val());
    if(title==""){
        tishi("回访标题不能为空!");
    }else if(con==""){
        tishi("回访内容不能为空!");
    }else if(answer==""){
        tishi("客户反馈不能为空!");
    }else{
        popup("#waiting");
        $(obj).parents("form").submit();
    }
}