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

function new_product(store_id){     //新建产产品
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/storages/new",
        dataType: "script",
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}

function has_shelves(obj){       //是否上架销售
    if($(obj).attr("checked")=="checked"){
        $("#good_detail").show();
    }
    else{
        $("#good_detail").hide();
    }
}

function check_type(obj){       //选择销售和技师的提成方式
    var name = $(obj).attr("name");
    var type = $(obj).val()
    if(name=="xs_t_type"){
        if(type==1){
            $("#xs_t_span").text("提成金额：");
        }
        else if(type==2){
            $("#xs_t_span").text("提成百分点：");
        }
    }else if(name=="js_t_type"){
        if(type==1){
            $("#js_t_span").text("提成金额：");
        }else if(type==2){
            $("#js_t_span").text("提成百分点：");
        }
    }
}

function need_add(obj){     //选择是否需要施工
    if($(obj).attr("checked")=="checked"){
        $("#new_p_form").find("input[name='js_t_type']").removeAttr("disabled");
        $("#js_t").removeAttr("disabled");
    }else{
        $("#new_p_form").find("input[name='js_t_type']").attr("disabled", "disabled");
        $("#js_t").attr("disabled", "disabled");
    }
}

function auto_revi(obj){    //选择是否自动回访
    if($(obj).attr("checked")=="checked"){
        $("#revist_time").removeAttr("disabled");
        $("#revist_cont").removeAttr("disabled");
    }else{
        $("#revist_time").attr("disabled", "disabled");
        $("#revist_cont").attr("disabled", "disabled");
    }
}

function up_img(){      //点击上传图片
    $("#p_image").click();
}

function new_prod_valid(obj, store_id, m_id){       //新建和编辑产品验证
    var flag = true;
    var code = $.trim($("#code").val());
    var name= $.trim($("#name").val());
    var standard = $.trim($("#standard").val());
    var unit = $.trim($("#unit").val());
    var types = $("#types").val();
    var t_price = $.trim($("#t_price").val());
    var b_price = $.trim($("#base_price").val());
    var s_price = $.trim($("#sale_price").val());
    var img = $("#p_image").val()
    if(name==""){
        tishi("名称不能为空!");
        flag = false;
    }else if(is_name(name)==false){
        tishi("名称不能包含非法字符!");
        flag = false;
    }else if(standard!="" && is_name(standard)==false){
        tishi("规格不能包含非法字符!")
        flag = false;
    }else if(unit!="" && is_name(unit)==false){
        tishi("单位不能包含非法字符!")
        flag = false;
    }else if(types=="0"){
        tishi("请选择产品类别!")
        flag = false;
    }else if(t_price==""){
        tishi("请输入成本价!")
        flag = false;
    }else if(is_float(t_price)==false){
        tishi("成本价必须为大于零的整数或小数(最多两位小数)!")
        flag = false;
    }else if(b_price==""){
        tishi("请输入零售价!")
        flag = false;
    }else if(is_float(b_price)==false){
        tishi("零售价必须为大于零的整数或小数(最多两位小数)!")
        flag = false;
    }else if(s_price==""){
        tishi("请输入促销价!")
        flag = false;
    }else if(is_float(s_price)==false){
        tishi("促销价必须为大于零的整数或小数(最多两位小数)!")
        flag = false;
    }else if(img!=""){
        var img_format =["jpg", "png", "bmp"];
        var img_type = img.substring(img.lastIndexOf(".")).toLowerCase();
        if(img!="" && img_format.indexOf(img_type.substring(1,img_type.length))==-1){
            tishi("图片格式不正确，请选择jpg,png,bmp的文件!");
            flag = false;
        }
    };
    if(flag){
        var is_shelves = $("#is_shelves");
        if(is_shelves.attr("checked")=="checked"){
            var p_point = $.trim($("#p_point").val());
            var xs_t_type = $("#new_p_form").find("input[name='xs_t_type']:checked").first().val();
            var xs_t = $.trim($("#xs_t").val());
            var need_added = $("#is_added");
            var auto_revist = $("#auto_revist");
            if(p_point==""){
                tishi("请输入产品积分!");
                flag = false;
            }else if(is_int(p_point)==false){
                tishi("产品积分必须为大于零的整数!");
                flag = false;
            }else if(xs_t==""){
                if(xs_t_type==1){
                    tishi("请输入销售提成金额!");
                }else{
                    tishi("请输入销售提成百分比!");
                }
                flag = false;
            }else if(xs_t!="" && is_float(xs_t)==false){
                if(xs_t_type==1){
                    tishi("请输入正确的销售提成金额!");
                }else{
                    tishi("请输入正确的销售提成百分比!");
                }
                flag = false;
            }else{
                if(need_added.attr("checked")=="checked"){
                    var js_t_type = $("#new_p_form").find("input[name='js_t_type']:checked").first().val();
                    var js_t = $.trim($("#js_t").val());
                    if(js_t==""){
                        if(js_t_type==1){
                            tishi("请输入技师提成金额!");
                        }else{
                            tishi("请输入技师提成百分比!");
                        }
                        flag = false;
                    }else if(js_t!="" && is_float(js_t)==false){
                        if(js_t_type==1){
                            tishi("请输入正确的技师提成金额!");
                        }else{
                            tishi("请输入正确的技师提成百分比!");
                        }
                        flag = false;
                    }
                };
                if(auto_revist.attr("checked")=="checked"){
                    var revi_time = $("#revist_time").val();
                    var revi_cont = $.trim($("#revist_cont").val());
                    if(revi_time=="0"){
                        tishi("请选择回访时间!");
                        flag = false;
                    }else if(revi_cont==""){
                        tishi("请输入回访内容!");
                        flag = false;
                    }
                }
            }
            if(flag){
                popup2("#waiting");
                $.ajax({
                    type: "get",
                    url: "/stores/"+store_id+"/storages/prod_valid",
                    data: {
                        code : code,
                        name : name,
                        id : m_id
                    },
                    dataType: "json",
                    success: function(data){
                        if(data.status==0){
                            $("#waiting").hide();
                            $(".second_bg2").hide();
                            tishi(data.msg);
                        }else{
                            $(obj).parents("form").submit();
                        }
                    },
                    error: function(){
                        $("#waiting").hide();
                        $(".second_bg2").hide();
                        tishi("验证失败!");
                    }
                });
            }
        }else{
            popup2("#waiting");
            $.ajax({
                type: "get",
                url: "/stores/"+store_id+"/storages/prod_valid",
                data: {
                    code : code,
                    name : name,
                    id : m_id
                },
                dataType: "json",
                success: function(data){
                    if(data.status==0){
                        $("#waiting").hide();
                        $(".second_bg2").hide();
                        tishi(data.msg);
                    }else{
                        $(obj).parents("form").submit();
                    }
                },
                error: function(){
                    $("#waiting").hide();
                    $(".second_bg2").hide();
                    tishi("验证失败!");
                }
            });
        }
    }
}

function set_product(types, store_id, m_id, obj){    //设置1备注、2编辑、3快速入库、4预警、5忽略
    if(types==5){
        var txt = $(obj).text();
        var con = "";
        if(txt=="忽略"){
            con = "是否忽略该产品?"
        }else{
            con = "是否取消忽略该产品?"
        };
        var flag = confirm(con);
        if(flag){
            popup2("#waiting");
            $.ajax({
                type: "put",
                url: "/stores/"+store_id+"/storages/"+m_id,
                data: {
                    set_product_types : types
                },
                dataType: "script",
                error: function(){
                    $("#waiting").hide();
                    $(".second_bg2").hide();
                    tishi("数据错误!");
                }
            })
        }
    }else{
        popup("#waiting");
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/storages/"+m_id+"/edit",
            data: {
                set_product_types : types
            },
            dataType: "script",
            error: function(){
                $("#waiting").hide();
                $(".second_bg").hide();
                tishi("数据错误!");
            }
        })
    }
}

function del_product(store_id, m_id){
    var flag = confirm("确定删除此产品?");
    if(flag){
        popup("#waiting");
        $.ajax({
            type: "delete",
            url: "/stores/"+store_id+"/storages/"+m_id,
            dataType: "json",
            success: function(data){
                $("#waiting").hide();
                $(".second_bg").hide();
                if(data.status==1){
                    $(".second_bg").show();
                    tishi("删除成功!");
                    setTimeout(function(){
                        window.location.reload();
                    }, 300);
                }else{
                    tishi("操作失败!");
                }
            },
            error: function(){
                $("#waiting").hide();
                $(".second_bg").hide();
                tishi("数据错误!");
            }
        })
    }
}
