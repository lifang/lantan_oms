$(function(){
    var ss = $("#new_cus_form").find("option:selected");
    $.each(ss, function(){
        var txt = $(this).text();
        $(this).parents(".selectBox").find("span").first().text(txt);
    });

    var s_div = $("#search_cus_div").find("option:selected");
    $.each(s_div, function(){
        var txt = $(this).text();
        $(this).parents(".selectBox").find("span").first().text(txt);
    });
})

function show_and_hide_complaints(obj){     //展开或收起投诉
    var st = $(obj).text();
    if(st=="展开"){
        $(obj).parents(".leftBox").find(".infoBlock").show();
        $(obj).text("收起");
    }else if(st=="收起"){
        $(obj).parents(".leftBox").find(".infoBlock").hide();
        $(obj).text("展开");
    }
}

function del_customer(customer_id, store_id){   //删除客户
    var flag = confirm("确定删除该客户?");
    if(flag){
        popup("#waiting");
        $.ajax({
            type: "delete",
            url: "/stores/"+store_id+"/customers/"+customer_id,
            dataType: "script",
            error: function(){
                $("#waiting").hide();
                $(".second_bg").hide();
                tishi("数据错误!");
            }
        })
    }
}

function search_cus_select(obj){
    var txt = $(obj).find("option:selected").text();
    $(obj).parents(".selectBox").find("span").first().text(txt);
}

function new_customer(){    //新建客户
    popup("#new_customer");
}

function edit_customer(customer_id, store_id){   //编辑客户
    $("#edit_car_div").empty();
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/customers/"+customer_id+"/edit",
        dataType: "script",
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}
function select_sex(obj){   //选择性别
    var divs = $(obj).parents(".choiceBox").find(".radioBox");
    $.each(divs, function(){
        $(this).removeAttr("class");
        $(this).attr("class", "radioBox");
    });
    $(obj).parent().removeAttr("class");
    $(obj).parent().attr("class", "radioBox check");
}

function select_property(obj){  //选择属性
    var type = $(obj).val();
    var divs = $(obj).parents(".choiceBox").find(".radioBox");
    $.each(divs, function(){
        $(this).removeAttr("class");
        $(this).attr("class", "radioBox");
    });
    $(obj).parent().removeAttr("class");
    $(obj).parent().attr("class", "radioBox check");
    $("#cus_group_name").removeAttr("disabled");
    $("#cus_group_name").prev().find("font").remove();
    if(parseInt(type)==0){
        $("#cus_group_name").attr("disabled", "disabled");
    }else{
        $("#cus_group_name").prev().prepend("<font class='red'>*</font>");
    }
}

function select_is_vip(obj){    //勾选是否VIP
    $(obj).parent().removeAttr("class");
    if($(obj).attr("checked")=="checked"){
        $(obj).parent().attr("class", "checkBox check");
    }else{
        $(obj).parent().attr("class", "checkBox");
    }
}

function allow_debts(obj){  //是否允许挂账
    var type = $(obj).val();
    var divs = $(obj).parents(".choiceBox").find(".radioBox");
    $.each(divs, function(){
        $(this).removeAttr("class");
        $(this).attr("class", "radioBox");
    });
    $(obj).parent().removeAttr("class");
    $(obj).parent().attr("class", "radioBox check");
    $("#cus_debts_money").removeAttr("disabled");
    $("#cus_debts_money").prev().find("font").remove();
    if(parseInt(type)==0){  //不允许欠账
        $("#cus_debts_money").attr("disabled", "disabled");
        var radios = $("#debts_div").find("input[name='cus_check_type']");
        $.each(radios, function(){
            $(this).attr("disabled", "disabled");
        });
        $("#debts_by_month").attr("disabled", "disabled");
        $("#debts_by_week").attr("disabled", "disabled");
    }else{      //允许欠账
        $("#cus_debts_money").prev().prepend("<font class='red'>*</font>");
        var radios = $("#debts_div").find("input[name='cus_check_type']");
        $.each(radios, function(){
            var radio = $(this);
            radio.removeAttr("disabled");
            if(radio.attr("checked")=="checked"){
                if(parseInt(radio.val())==0){
                    $("#debts_by_month").removeAttr("disabled");
                }else{
                    $("#debts_by_week").removeAttr("disabled");
                }
            }
        });
    }
}

function select_debts_type(obj){    //结算类型
    var type = $(obj).val();
    var divs = $("#debts_div").find(".radioBox");
    $.each(divs, function(){
        $(this).removeAttr("class");
        $(this).attr("class", "radioBox");
    });
    $(obj).parent().removeAttr("class");
    $(obj).parent().attr("class", "radioBox check");
    $("#debts_by_month").attr("disabled", "disabled");
    $("#debts_by_week").attr("disabled", "disabled");
    if(parseInt(type)==0){
        $("#debts_by_month").removeAttr("disabled");
    }else{
        $("#debts_by_week").removeAttr("disabled");
    }
}

function select_change(obj, store_id){  //选择汽车品牌型号 后台加载
    var txt = $(obj).find("option:selected").text();
    $(obj).parents(".selectBox").find("span").first().text(txt);
    if($(obj).attr("id")=="car_capital"){
        var c_id = $(obj).find("option:selected").val();
        if(parseInt(c_id)==0){
            $("#car_brand").html("<option value='0'>------</option>");
            $("#car_brand").parents(".selectBox").find("span").first().text("-----");
            $("#car_model").html("<option value='0'>------</option>");
            $("#car_model").parents(".selectBox").find("span").first().text("-----");
        }else{
            popup2("#waiting");
            $.ajax({
                type: "get",
                url: "/stores/"+store_id+"/customers/add_car_get_datas",
                dataType: "script",
                data: {
                    type : 0,
                    id : c_id
                },
                error: function(){
                    $("#waiting").hide();
                    $(".second_bg2").hide();
                    tishi("数据错误!");
                }
            })
        }
    }else if($(obj).attr("id")=="car_brand"){
        var b_id = $(obj).find("option:selected").val();
        if(parseInt(b_id)==0){
            $("#car_model").html("<option value='0'>------</option>");
            $("#car_model").parents(".selectBox").find("span").first().text("-----");
        }else{
            popup2("#waiting");
            $.ajax({
                type: "get",
                url: "/stores/"+store_id+"/customers/add_car_get_datas",
                dataType: "script",
                data: {
                    type : 1,
                    id : b_id
                },
                error: function(){
                    $("#waiting").hide();
                    $(".second_bg2").hide();
                    tishi("数据错误!");
                }
            })
        }
    }
}

function select_inspection_type(obj){   //选择年检规则
    var divs = $(obj).parents(".choiceBox").find(".radioBox");
    $.each(divs, function(){
        $(this).removeAttr("class");
        $(this).attr("class", "radioBox");
    });
    $(obj).parent().removeAttr("class");
    $(obj).parent().attr("class", "radioBox check");
}

function add_car(obj, store_id){    //添加车辆
    var buy_year = $("#buy_year").val();
    var car_model = $("#car_model").val();
    var car_model_text = $("#car_model").find("option:selected").text();
    var car_brand_text = $("#car_brand").find("option:selected").text();
    var car_distance = $("#distance").val();
    var last_inspection = $("#last_inspection").val();
    var inspection_type = $(obj).parents("form").find("input[name='inspection_type']:checked").val();
    var insurance_ended = $("#insurance_ended").val();
    var maint_distance = $("#maint_distance").val();
    var car_num = $("#car_num").val();
    var vin_code = $("#vin_code").val();
    var ing_flag = new RegExp(/^[1-9]*[1-9][0-9]*$/);
    var pattern = new RegExp("[`~@#$^&*()=:;,\\[\\].<>?~！@#￥……&*（）——|{}。，、？-]");
    if(buy_year==""){
        tishi("车辆年份不能为空!");
    }else if(car_model=="0"){
        tishi("请选择车辆型号!");
    }else if(car_distance!="" && ing_flag.test(car_distance)==false){
        tishi("行驶里程请输入正整数!");
    }else if(maint_distance!="" && ing_flag.test(maint_distance)==false){
        tishi("保养里程请输入正整数!");
    }else if(car_num==""){
        tishi("车牌号码不能为空!");
    }else if(car_num!="" && (pattern.test(car_num)==true || car_num.length != 7)){
        tishi("车牌号码格式不正确!");
    }else{
        var index = 1;
        var trs =$("#add_car_table").find("tr[name='add_car_tr']");
        var flag = true;
        if(trs.length >= 1){
            var car_num_arr = [];   //车牌的arr，判断车牌是否已重复
            var arr = [];   //索引的arr
            $.each(trs, function(){
                var tr = $(this);
                var td = tr.find("td[name='add_car_num_td']").first().text();
                car_num_arr.push(td);
                arr.push(parseInt(tr.attr("s_index")));
            });
            if(car_num_arr.indexOf(car_num)>=0){
                flag = false;
                tishi("已有同样的车牌!");
            }else{
                arr.sort();
                index = arr[arr.length-1]+1;
            }
        };
        if(flag){
            popup2("#waiting");
            $.ajax({
                type: "post",
                url: "/stores/"+store_id+"/customers/add_car_item",
                dataType: "script",
                data: {
                    buy_year : buy_year,
                    car_model : car_model,
                    car_model_text : car_model_text,
                    car_brand_text : car_brand_text,
                    car_distance : car_distance,
                    last_inspection : last_inspection,
                    inspection_type : inspection_type,
                    insurance_ended : insurance_ended,
                    maint_distance : maint_distance,
                    car_num : car_num,
                    vin_code : vin_code,
                    index : index
                },
                error: function(){
                    $("#waiting").hide();
                    $(".second_bg2").hide();
                    tishi("数据错误!");
                }
            })
        }
    }
}

function add_car_item_delete(obj){  //删除已添加的车辆
    $(obj).parents("tr").remove();
}

function new_cus_valid(obj, type){    //新建客户验证
    var cus_name = $.trim($("#cus_name").val());
    var cus_phone = $.trim($("#cus_phone").val());
    var cus_property = parseInt($(obj).parents("form").find("input[name='cus_property']:checked").val());
    var cus_group_name = $.trim($("#cus_group_name").val());
    var cus_allow_debts = parseInt($(obj).parents("form").find("input[name='cus_allow_debts']:checked").val());
    var debts_money = $.trim($("#cus_debts_money").val());
    var ing_flag = new RegExp(/^[1-9]*[1-9][0-9]*$/);
    var flag = true;
    if(cus_name==""){
        tishi("请输入姓名!");
        flag = false;
    }else if(is_name(cus_name)==false){
        tishi("姓名不得包含非法字符!");
        flag = false;
    }else if(cus_phone==""){
        tishi("请输入手机号码!");
        flag = false;
    }else if(cus_phone!="" && is_phone(cus_phone)==false){
        tishi("请输入正确的手机号码!");
        flag = false;
    }else if(cus_property==1 && cus_group_name==""){
        tishi("请输入单位名称!");
        flag = false;
    }else if(cus_allow_debts==1 && debts_money==""){
        tishi("请输入挂账额度!");
        flag = false;
    }else if(cus_allow_debts==1 && debts_money!="" && ing_flag.test(debts_money)==false){
        tishi("挂账额度必须为正整数!");
        flag = false;
    };

    if(flag){
        if(type==0){    //新建
            var trs_l = $("#add_car_table").find("tr[name='add_car_tr']").length;
            if(trs_l > 0){
                popup2("#waiting");
                $(obj).parents("form").submit();
            }else{
                var con = confirm("没有为该客户添加任何车辆,是否继续?");
                if(con){
                    popup2("#waiting");
                    $(obj).parents("form").submit();
                }
            }
        }else{  //编辑
            popup2("#waiting");
            $(obj).parents("form").submit();
        }
    }
}

function show_diff_table(obj, index){   //点击切换消费记录,回访记录等...
    $(obj).parents(".custmRecord").find("li").removeAttr("class");
    $(obj).find("li").first().attr("class", "hover");
    $(obj).parents(".main_con").find("div[name='cus_diff_div']").hide();
    if(index==1){       //消费记录
        $("#cus_order_list").show();
    }else if(index==2){     //回访记录
        $("#cus_revist_list").show();
    }else if(index==3){     //投诉记录
        $("#cus_complaint_list").show();
    }else if(index==4){     //储值卡消费记录
        $("#cus_svcard_records_list").show();
    }else if(index==5){     //套餐卡消费记录
        $("#cus_pcard_records_list").show();
    }
}

function print_cus_orders_select_all(obj){      //打印消费记录，选择全部
    var flag = $(obj).attr("checked")=="checked";
    var trs = $("#cus_order_table").find("tr[name='cus_order_tr']");
    if(flag){
        $(obj).parent().removeAttr("class");
        $(obj).parent().attr("class", "checkBox check");
        $.each(trs, function(){
            var input = $(this).find("input").first();
            input.attr("checked", "checked");
            input.parent().removeAttr("class");
            input.parent().attr("class", "checkBox check");
        })
    }else{
        $(obj).parent().removeAttr("class");
        $(obj).parent().attr("class", "checkBox");
        $.each(trs, function(){
            var input = $(this).find("input").first();
            input.removeAttr("checked");
            input.parent().removeAttr("class");
            input.parent().attr("class", "checkBox");
        })
    }
}

function print_cus_orders_select_one(obj){      //打印消费记录，选择一个
    var flag = $(obj).attr("checked")=="checked";
    if(flag){
        $(obj).parent().removeAttr("class");
        $(obj).parent().attr("class", "checkBox check");
    }else{
        $(obj).parent().removeAttr("class");
        $(obj).parent().attr("class", "checkBox");
    }
}

function print_orders(store_id){    //打印消费记录
    var checked_ids = $("input[id^='line']:checked");
    if(checked_ids.length < 1){
        tishi("请至少选择一条消费记录!");
    }else{
        var ids = [];
        for(var i=0; i < checked_ids.length; i++){
            ids.push(checked_ids[i].value);
        };
        window.open("/stores/"+store_id+"/customers/print_orders?ids="+ids.join(","),"_blank");
    }
}


function edit_car(store_id, carnum_id){     //编辑车辆
    $("#edit_customer").empty();
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/customers/edit_car",
        dataType: "script",
        data: {
            carnum_id : carnum_id
        },
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}

function update_car_valid(obj, car_num_id){     //编辑车辆验证
    var buy_year = $("#buy_year").val();
    var car_model = $("#car_model").val();
    var car_distance = $("#distance").val();
    var last_inspection = $("#last_inspection").val();
    var insurance_ended = $("#insurance_ended").val();
    var maint_distance = $("#maint_distance").val();
    var car_num = $("#car_num").val();
    var ing_flag = new RegExp(/^[1-9]*[1-9][0-9]*$/);
    var pattern = new RegExp("[`~@#$^&*()=:;,\\[\\].<>?~！@#￥……&*（）——|{}。，、？-]");
    if(buy_year==""){
        tishi("车辆年份不能为空!");
    }else if(car_model=="0"){
        tishi("请选择车辆型号!");
    }else if(car_distance!="" && ing_flag.test(car_distance)==false){
        tishi("行驶里程请输入正整数!");
    }else if(maint_distance!="" && ing_flag.test(maint_distance)==false){
        tishi("保养里程请输入正整数!");
    }else if(car_num==""){
        tishi("车牌号码不能为空!");
    }else if(car_num!="" && (pattern.test(car_num)==true || car_num.length != 7)){
        tishi("车牌号码格式不正确!");
    }else{
        popup2("#waiting");
        $(obj).parents("form").submit();
    }
}

function del_car(store_id, car_num_id){
    var flag = confirm("删除该车辆后,该车辆对应的消费、投诉等记录都将清除,请慎重操作。\r是否继续删除该车辆?");
    if(flag){
        popup("#waiting");
        $.ajax({
          type: "get",
          url: "/stores/"+store_id+"/customers/del_car",
          dataType: "script",
          data: {car_num_id : car_num_id},
          error: function(){
              $("#waiting").hide();
              $(".second_bg").hide();
              tishi("数据错误!");
          }
        })
    }
}