function new_back(store_id){     //新建退货记录
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/back_records/new",
        dataType: "script",
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    });
}

function tuihuo_search_supplier(store_id, obj){    //订货时搜索供应商
    var name = $.trim($(obj).val());
    if(name!=""){
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/back_records/search_supplier",
            dataType: "script",
            data: {
                name : name
            }
        });
    }else{
        $("#supp_name_list").hide();
    }
}

function tuihuo_select_a_supp(obj){  //退货时选择某个供应商
    var s_name = $.trim($(obj).text());
    $("#supp_name_list").hide();
    $("#supp_name_list").parents(".listInput").find("input[type='text']").first().val(s_name);
    $("#supp_name_list").parents(".listInput").find("input[type='text']").first().focus();
}

function tuihuo_search_prod(store_id){     //退货时搜索产品
    var prod_name = $.trim($("#prod_name").val());
    var prod_type = $("#prod_type").val();
    popup2("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/back_records/search_prod",
        dataType: "script",
        data: {
            prod_name : prod_name,
            prod_type : prod_type
        },
        error: function(){
            $("#waiting").hide();
            $(".second_bg2").hide();
            tishi("数据错误!");
        }
    })
}

function tuihuo_add_prod(prod_id, obj){   //退货添加产品
    var ids = $("#tuihuo_added_prod_list").find("input[name='added_prod_id']");
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
        $("#tuihuo_added_prod_list").append("<tr><td width='15%'>"+pname+"</td><td width='15%'>"+cname+"</td><td width='12%'>"+t_price+"</td><td>"+base_price+"</td>\n\
<td width='12%'>"+storage+"</td><td width='12%'><input type='text' style='width:40px;padding:3px;' name='added_prod["+prod_id+"]' onkeyup='tuihuo_add_prod_set_num(this)'/></td>\n\
<td width='12%'>0.00</td><td width='8%'><input type='hidden' name='added_prod_id' value='"+prod_id+"'/><button class='delete' title='删除' type='button' onclick='tuihuo_del_added_prod(this)'></button></td></tr>");
    };
}

function tuihuo_add_prod_set_num(obj){     //退货选择产品时输入的数量验证
    var num = $.trim($(obj).val());
    var storage = parseFloat($(obj).parents("tr").find("td:nth-child(5)").text());
    if(set_num_is_float(num)==false){
        tishi("请输入正确的数量,数量必须为大于零的整数或者两位小数!");
        $(obj).val("");
    }else if(parseFloat(num)>storage){
        tishi("退货数量不得大于库存量!");
        $(obj).val("");
    };
    var tot_price = 0;
    var nums = $("#tuihuo_added_prod_list").find("input[type='text']");
    $.each(nums, function(){
        var t_price = parseFloat($(this).parents("tr").find("td:nth-child(3)").text());
        var c_num = parseFloat($(this).val());
        if(isNaN(t_price)==false && isNaN(c_num)==false){
            tot_price += t_price*c_num;
            $(this).parent().next().text((t_price*c_num).toFixed(2));
        }else{
            $(this).parent().next().text("0.00");
        }
    });
    $("#total_price_span").text("退货总计："+tot_price.toFixed(2)+"(元)");
}

function tuihuo_del_added_prod(obj){   //退货删除已添加产品
    $(obj).parents("tr").remove();
    var tot_price = 0;
    var nums = $("#tuihuo_added_prod_list").find("input[type='text']");
    $.each(nums, function(){
        var t_price = parseFloat($(this).parents("tr").find("td:nth-child(3)").text());
        var num = parseFloat($(this).val());
        if(isNaN(t_price)==false && isNaN(num)==false){
            tot_price += t_price * num;
        }
    });
    $("#total_price_span").text("订货总计："+tot_price.toFixed(2)+"(元)");
}

function tuihuo_maek_out_records_valid(obj){   //新建退货记录验证
    var flag = true;
    var supp_name = $.trim($("#supplier_name").val());
    var prod_len = $("#tuihuo_added_prod_list").find("tr").length;
    if(prod_len<=1){
        tishi("您没有选择任何产品!");
        flag = false;
    }else if(supp_name==""){
        tishi("请输入供应商名称!");
        flag = false;
    }else{
        var nums = $("#tuihuo_added_prod_list").find("input[type='text']");
        $.each(nums, function(){
            var num = $.trim($(this).val());
            if(num==""){
                tishi("退货数量不能为空!");
                flag = false;
                return false;
            }else if(parseFloat(num).toFixed(2)<=0){
                tishi("请输入正确的数量,数量必须为大于零的整数或者两位小数!");
                flag = false;
                return false;
            }else if(isNaN(num)){
                tishi("退货数量格式非法!");
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