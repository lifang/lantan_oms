function new_loss(store_id){     //新建报损记录
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/prod_losses/new",
        dataType: "script",
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    });
}

function loss_add_prod(prod_id, obj){   //报损时添加产品
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
<td width='14%'>"+storage+"</td><td width='14%'><input type='text' style='width:40px;padding:3px;' name='added_prod["+prod_id+"]' onkeyup='loss_add_prod_set_num(this)'/></td>\n\
<td width='14%'><input type='hidden' name='added_prod_id' value='"+prod_id+"'/><button class='delete' title='删除' onclick='loss_del_added_prod(this)'></button></td></tr>");
    };
}

function loss_del_added_prod(obj){   //报损时删除已添加产品
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
    $("#total_price_span").text("报损总计："+tot_price.toFixed(2)+"(元)");
}

function loss_add_prod_set_num(obj){     //报损时输入的数量验证
    var num = $.trim($(obj).val());
    var storage = parseFloat($(obj).parents("tr").find("td:nth-child(5)").text());
    if(set_num_is_float(num)==false){
        tishi("请输入正确的数量,数量必须为大于零的整数或者两位小数!");
        $(obj).val("");
    }else if(num!="" && parseFloat(num) > storage){
        tishi("报损数量不能大于产品的库存量!");
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
    $("#total_price_span").text("报损总计："+tot_price.toFixed(2)+"(元)");
}

function loss_make_out_records_valid(obj){   //新建报损记录验证
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
                tishi("报损数量不能为空!");
                flag = false;
                return false;
            }else if(parseFloat(num).toFixed(2)<=0){
                tishi("请输入正确的数量,数量必须为大于零的整数或者两位小数!");
                flag = false;
                return false;
            }else if(isNaN(num)){
                tishi("报损数量格式非法!");
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