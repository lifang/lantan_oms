function out(store_id){     //新建出库记录
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/in_and_out_records/out_new",
        dataType: "script",
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    });
}

function add_prod(prod_id, obj){   //出库添加产品
    var ids = $("#added_prod_list").find("input[name='added_prod_id']");
    var flag = true;
    $.each(ids, function(){
        if($(this).val()==prod_id){
            tishi("已添加该产品!");
            flag = false;
            return false;
        }
    });
    if(flag){
        var pname = $(obj).parents("tr").find("td:nth-child(1)").text();
        var cname = $(obj).parents("tr").find("td:nth-child(2)").text();
        var t_price = $(obj).parents("tr").find("td:nth-child(3)").text();
        var base_price = $(obj).parents("tr").find("td:nth-child(4)").text();
        var storage = $(obj).parents("tr").find("td:nth-child(5)").text();
        $("#added_prod_list").append("<tr><td width='16%'>"+pname+"</td><td width='14%'>"+cname+"</td><td width='14%'>"+t_price+"</td><td width='14%'>"+base_price+"</td>\n\
<td width='14%'>"+storage+"</td><td width='14%'><input type='text' style='width:40px;padding:3px;' name='added_prod["+prod_id+"]' onkeyup='add_prod_set_num(this)'/></td>\n\
<td width='14%'><input type='hidden' name='added_prod_id' value='"+prod_id+"'/><button class='delete' title='删除' onclick='del_added_prod(this)'></button></td></tr>");
    };
}

function del_added_prod(obj){   //出库删除已添加产品
    $(obj).parents("tr").remove();
    var tot_price = 0;
    var nums = $("#added_prod_list").find("input[type='text']");
    $.each(nums, function(){
        var t_price = parseFloat($(this).parents("tr").find("td:nth-child(3)").text());
        var num = parseFloat($(this).val());
        if(isNaN(t_price)==false && isNaN(num)==false){
            tot_price += t_price * num;
        }
    });
    $("#total_price_span").text("订货总计："+tot_price.toFixed(2)+"(元)");
}

function add_prod_set_num(obj){     //出库选择产品时输入的数量验证
    var num = $.trim($(obj).val());
    var storage = parseFloat($(obj).parents("tr").find("td:nth-child(5)").text());
    if(set_num_is_float(num)==false){
        tishi("请输入正确的数量,数量必须为大于零的整数或者两位小数!");
        $(obj).val("");
    }else if(num!="" && parseFloat(num) > storage){
        tishi("出库数量不能大于产品的库存量!");
        $(obj).val("");
    };
    var tot_price = 0;
    var nums = $("#added_prod_list").find("input[type='text']");
    $.each(nums, function(){
        var t_price = parseFloat($(this).parents("tr").find("td:nth-child(3)").text());
        var c_num = parseFloat($(this).val());
        if(isNaN(t_price)==false && isNaN(c_num)==false){
            tot_price += t_price*c_num;
        };
    });
    $("#total_price_span").text("出库总计："+tot_price.toFixed(2)+"(元)");
    
}

function maek_out_records_valid(obj){   //新建出库记录验证
    var flag = true;
    var prod_len = $("#added_prod_list").find("tr").length;
    var staff = $("#out_staff").val();
    if(prod_len<=1){
        tishi("您没有选择任何产品!");
        flag = false;
    }else if(staff=="" || staff==undefined){
        tishi("没有申请人!");
        flag = false;
    }else{
        var nums = $("#added_prod_list").find("input[type='text']");
        $.each(nums, function(){
            var num = $.trim($(this).val());
            if(num==""){
                tishi("出库数量不能为空!");
                flag = false;
                return false;
            }else if(parseFloat(num).toFixed(2)<=0){
                tishi("请输入正确的数量,数量必须为大于零的整数或者两位小数!");
                flag = false;
                return false;
            }else if(isNaN(num)){
                tishi("出库数量格式非法!");
                flag = false;
                return false;
            }
        });
    };
    if(flag){
        popup2("#waiting");
        $(obj).parents("form").submit();
    }
}


function in_records(store_id){  //新建入库记录
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/in_and_out_records/in_new",
        dataType: "script",
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    });
}

function in_add_prod_set_num(obj){     //入库时输入的数量验证
    var num = $.trim($(obj).val());
    var order_num = parseFloat($(obj).parents("tr").find("td:nth-child(6)").text());
    var has_in_num = parseFloat($(obj).parents("tr").find("td:nth-child(7)").text());
    if(set_num_is_float(num)==false){
        tishi("请输入正确的数量,数量必须为大于零的整数或者两位小数!");
        $(obj).val("");
    }else if(num!="" && parseFloat(num) > order_num){
        tishi("入库数量不能大于订货数量!");
        $(obj).val("");
    }else if(num!="" && parseFloat(num) > (order_num - has_in_num).toFixed(2)){
        tishi("入库数量不能大于剩余可入库数量数量!");
        $(obj).val("");
    };
}

function in_del_added_prod(obj){   //入库时删除某个产品
    $(obj).parents("tr").remove();
}

function make_in_records_valid(store_id,obj){   //新建入库记录验证
    var flag = true;
    var prod_len = $("#prod_list").find("tr").length;
    if(prod_len<=1){
        tishi("您没有选择任何产品!");
        flag = false;
    }else{
        var nums = $("#prod_list").find("input[type='text']");
        $.each(nums, function(){
            var num = $.trim($(this).val());
            var order_num = parseFloat($(this).parents("tr").find("td:nth-child(6)").text());
            var has_in_num = parseFloat($(this).parents("tr").find("td:nth-child(7)").text());
            if(order_num!=has_in_num && num==""){
                tishi("入库数量不能为空!");
                flag = false;
                return false;
            }else if(parseFloat(num).toFixed(2)<=0){
                tishi("请输入正确的数量,数量必须为大于零的整数或者两位小数!");
                flag = false;
                return false;
            }else if(num!="" && isNaN(num)){
                tishi("入库数量格式非法!");
                flag = false;
                return false;
            }
        });
    };
    if(flag){
        popup2("#waiting");
        $(obj).parents("form").removeAttr("actoion");
        $(obj).parents("form").removeAttr("target");
        $(obj).parents("form").attr("action", "/stores/"+store_id+"/in_and_out_records/in_create");
        $(obj).parents("form").submit();
    }
}

function print_in_list(store_id, obj){      //打印入库记录清单验证
    var flag = true;
    var prod_len = $("#prod_list").find("tr").length;
    if(prod_len<=1){
        tishi("您没有选择任何产品!");
        flag = false;
    }else{
        var nums = $("#prod_list").find("input[type='text']");
        $.each(nums, function(){
            var num = $.trim($(this).val());
            var order_num = parseFloat($(this).parents("tr").find("td:nth-child(6)").text());
            var has_in_num = parseFloat($(this).parents("tr").find("td:nth-child(7)").text());
            if(order_num!=has_in_num && num==""){
                tishi("入库数量不能为空!");
                flag = false;
                return false;
            }else if(parseFloat(num).toFixed(2)<=0){
                tishi("请输入正确的数量,数量必须为大于零的整数或者两位小数!");
                flag = false;
                return false;
            }else if(num!="" && isNaN(num)){
                tishi("入库数量格式非法!");
                flag = false;
                return false;
            }
        });
    };
    if(flag){
        $(obj).parents("form").removeAttr("actoion");
        $(obj).parents("form").attr("target", "_blank");
        $(obj).parents("form").attr("action", "/stores/"+store_id+"/in_and_out_records/print_in_list");
        $(obj).parents("form").submit();
    }
}
function set_num_is_float(str){ //验证数量是否是浮点数(两位小数)
    var flag = true;
    if(str!=""){
        if(isNaN(str)){
            flag = false;
        }else{
            var float_tst = /^([0-9]+\.*[0-9]{0,2}|[1-9]+[0-9]*)$/;
            if(float_tst.test(str)==false){
                flag = false;
            }else{
                var float_num = parseFloat(str);
                if(float_num<0){
                    flag = false;
                }
            }
        }
    }
    return flag;
}