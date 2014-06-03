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
})

function new_supplier(store_id){
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/suppliers/new",
        dataType: "script",
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}

function del_supplier(store_id, supp_id){   //删除供应商
    var flag = confirm("确定删除该供应商?");
    if(flag){
        popup("#waiting");
        $.ajax({
            type: "delete",
            url: "/stores/"+store_id+"/suppliers/"+supp_id,
            dataType: "script",
            error: function(){
                $("#waiting").hide();
                $(".second_bg").hide();
                tishi("数据错误!");
            }
        })
    }
}

function edit_supplier(store_id, supp_id){   //编辑供应商
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/suppliers/"+supp_id+"/edit",
        dataType: "script",
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}

function supp_valid(obj, store_id, supp_id){      //编辑或者新建供应商验证
    var phone_flag = /^1+[0-9]{10,10}$/;
    var int_flag = /^[1-9]+$/;
    var name = $.trim($("#s_name").val());
    var cap_name = $.trim($("#cap_name").val());
    var phone = $.trim($("#phone").val());
    var check_time = $.trim($("#check_time").val());
    if(name==""){
        tishi("名称不能为空!");
    }else if(cap_name==""){
        tishi("助记码不能为空!");
    }else if(phone==""){
        tishi("手机号码不能为空!");
    }else if(phone_flag.test(phone)==false){
        tishi("请输入正确的手机号码!");
    }else if(check_time==""){
        tishi("请输入结算时间!");
    }else if(check_time!="" && int_flag.test(check_time)==false){
        tishi("请输入正确的结算时间!");
    }else{
        popup2("#waiting");
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/suppliers/supplier_valid",
            dataType: "json",
            data: {
                supplier_id : supp_id,
                name : name,
                cap_name : cap_name,
                phone : phone
            },
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
                tishi("数据错误!");
            }
        })
    }
}
