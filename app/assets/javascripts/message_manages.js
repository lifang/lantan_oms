$(function(){
    var ss = $("#message_manages_form").find("option:selected");
    $.each(ss, function(){
        var txt = $(this).text();
        $(this).parents(".selectBox").find("span").first().text(txt);
    });

    $("#message_manages_form").on("change", "select", function(){
        var txt = $(this).find("option:selected").text();
        $(this).parent().find("span").first().text(txt);
    });

    $(document).bind('click', function(e){
        if ($(e.target).closest(".msgChooseItem").length<=0) {
            $(".msgChooseItem").hide()
        }
    });
});



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

function search_revi_valid(obj){    //查询验证
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

function select_customer(obj, cus_id){  //选择单个客户
    var name = $(obj).parents("tr").find("td:nth-child(2)").text();
    var num = $(obj).parents("tr").find("td:nth-child(3)").text();
    var num_detail = $(obj).parents("tr").find("td:nth-child(3)").attr("title");
    var last_time = $(obj).parents("tr").find("td:nth-child(4)").text();
    var price = $(obj).parents("tr").find("td:nth-child(5)").text();
    if($(obj).attr("checked")=="checked"){
        $(obj).parent().attr("class", "checkBox check");
        $("#has_selected_table").append("<tr name='hasselected_"+cus_id+"'><td style='width:20%;'>"+name+"</td><td style='width:20%;' title='"+num_detail+"'>"+num+"</td>\n\
<td style='width:30%;'>"+last_time+"</td><td style='width:20%;'>"+price+"</td><td style='width:10%;'><input type='hidden' name='selected_cus_ids' value='"+cus_id+"'/>\n\
<button type='button' class='delete' title='删除' onclick='remove_selected_cus(this,"+cus_id+")'></button></td></tr>");
    }else{
        $(obj).parent().attr("class", "checkBox");
        $("#has_selected_table").find("tr[name='hasselected_"+cus_id+"']").remove();
    }
}
function select_all_customer(obj){  //选择所有客户
    var setd_trs = $("#has_selected_table").find("tr");
    $.each(setd_trs, function(){
        if($(this).index()!=0){
            $(this).remove();
        }
    });
    var unsetd = $("#unselected_table").find("tr");
    if($(obj).attr("checked")=="checked"){
        $(obj).parent().attr("class", "checkBox check");
        $.each(unsetd, function(){
            if($(this).index()!=0){
                var check = $(this).find("input[type='checkBox']").first();
                check.attr("checked", "checked");
                check.parent().attr("class", "checkBox check");
                var name = $(this).find("td:nth-child(2)").text();
                var num = $(this).find("td:nth-child(3)").text();
                var num_detail = $(this).find("td:nth-child(3)").attr("title");
                var last_time = $(this).find("td:nth-child(4)").text();
                var price = $(this).find("td:nth-child(5)").text();
                var cus_id = $(this).find("input[name='unselected_cus_ids']").first().val();
                $("#has_selected_table").append("<tr name='hasselected_"+cus_id+"'><td style='width:20%;'>"+name+"</td><td style='width:20%;' title='"+num_detail+"'>"+num+"</td>\n\
<td style='width:30%;'>"+last_time+"</td><td style='width:20%;'>"+price+"</td><td style='width:10%;'><input type='hidden' name='selected_cus_ids' value='"+cus_id+"'/>\n\
<button type='button' class='delete' title='删除' onclick='remove_selected_cus(this,"+cus_id+")'></button></td></tr>");
            }
        });
    }else{
        $(obj).parent().attr("class", "checkBox");
        $.each(unsetd, function(){
            if($(this).index()!=0){
                var check = $(this).find("input[type='checkBox']").first();
                check.removeAttr("checked");
                check.parent().attr("class", "checkBox");
            }
        });
    }
}

function remove_selected_cus(obj, cus_id){      //取消已选择的客户
    $(obj).parents("tr").remove();
    var tr = $("#unselected_table").find("tr[name='unselected_"+cus_id+"']").first();
    var check = tr.find("input[type='checkBox']").first();
    check.removeAttr("checked");
    check.parent().attr("class", "checkBox");
}

function get_msg_temp_by_type(type, store_id){  //获取短信模板
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/message_manages/get_msg_temp_by_type",
        dataType: "script",
        data: {
            type : type
        },
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}

function add_msg_temp_by_type(type, name){  //新建短信模板
    $("#new_msg_temp_div").find("h1").first().text("新建"+name+"模板");
    $("#new_msg_temp_div").find("input[name='new_msg_temp_type']").first().val(type);
    popup("#new_msg_temp_div");
}

function new_msg_temp_valid(obj){   //新建短信模板验证
    var cont = $.trim($("#new_msg_temp_cont").val());
    var type = $("#new_msg_temp_div").find("input[name='new_msg_temp_type']").first().val();
    if(cont==""){
        tishi("内容不能为空!");
    }else if(type==undefined || type==""){
        tishi("数据错误!");
    }else{
        popup2("#waiting");
        $(obj).parents("form").submit();
    }
}


//获取光标的位置
$.fn.extend({
    position:function( value ){
        var elem = this[0];
        if (elem&&(elem.tagName=="TEXTAREA"||elem.type.toLowerCase()=="text")) {
            if($.browser.msie){
                var rng;
                if(elem.tagName == "TEXTAREA"){
                    rng = event.srcElement.createTextRange();
                    rng.moveToPoint(event.x,event.y);
                }else{
                    rng = document.selection.createRange();
                }
                if( value === undefined ){
                    rng.moveStart("character",-event.srcElement.value.length);
                    return  rng.text.length;
                }else if(typeof value === "number" ){
                    var index=this.position();
                    index>value?( rng.moveEnd("character",value-index)):(rng.moveStart("character",value-index))
                    rng.select();
                }
            }else{
                if( value === undefined ){
                    return elem.selectionStart;
                }else if(typeof value === "number" ){
                    elem.selectionEnd = value;
                    elem.selectionStart = value;
                }
            }
        }else{
            if( value === undefined )
                return undefined;
        }
    }
})

$.fn.selectRange = function(start, end){
    return this.each(function(){
        if (this.setSelectionRange) {
            this.focus();
            this.setSelectionRange(start, end);
        }
        else
        if (this.createTextRange) {
            var range = this.createTextRange();
            range.collapse(true);
            range.moveEnd('character', end);
            range.moveStart('character', start);
            range.select();
        }
    });
};

function add_temp_to_msg(obj){      //将模板内容添加到短信内容中
    var txt = $(obj).text();
    var posi = $("#send_msg_cont").position();
    var cont = $("#send_msg_cont").val();
    var t1 = cont.substring(0, posi);
    var t2 = cont.substring(posi, cont.length);
    $(obj).parent().hide();
    $("#send_msg_cont").val(t1+txt+t2);
    var posi = $("#send_msg_cont").position((t1+txt).length);
    $("#send_msg_cont").focus();
}

function send_msg_valid(obj){
    var cont = $.trim($("#send_msg_cont").val());
    var c_ids = $("#has_selected_table").find("input[name='selected_cus_ids']");
    if(cont==""){
        tishi("内容不能为空!");
    }else if(c_ids.length<=0){
        tishi("请至少选择一名客户!");
    }else{
        var ids_arr = [];
        $.each(c_ids, function(){
            ids_arr.push($(this).val());
        });
        $("#send_msg_form").find("input[name='send_msg_ids']").first().val(ids_arr);
        popup("#waiting");
        $(obj).parents("form").submit();
    }
}