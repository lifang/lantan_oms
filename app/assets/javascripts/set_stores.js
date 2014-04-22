$(function(){
    $("#edit_store_form").on("change", ".selectBox select", function(){
        var e = $(this);
        var txt = e.find("option:selected").text();
        var name = e.attr("name");
        e.parents(".selectBox").find("span").text(txt);
        if(name=="store_prov_id"){
            var p_id = e.val();
            var store_id = $("#store_id").val();
            popup("#waiting");
            $.ajax({
                type: "get",
                url: "/stores/"+store_id+"/set_stores/search_cities",
                data: {
                    province_id : p_id
                },
                dataType: "script",
                error: function(){
                    $(".second_bg").hide();
                    $("#waiting").hide();
                    tishi("数据错误!");
                }
            })
        }else if(name=="store_status"){
            var status = e.val();
            if(status==1){
                $("#store_sale_stime").removeAttr("disabled");
                $("#store_sale_etime").removeAttr("disabled");
            }else{
                $("#store_sale_stime").val("");
                $("#store_sale_stime").attr("disabled", "disabled");
                $("#store_sale_etime").val("");
                $("#store_sale_etime").attr("disabled", "disabled");
            }
        }
    })
})

function upload_store_img(obj){
    $(obj).next().click();
}

function edit_store_valid(obj){
    if($("#store_city_id").val()=="" || $("#store_city_id").val()=="0"){
        tishi("请选择门店所在地区!");
    }else if($.trim($("#store_x_position").val())=="" || $.trim($("#store_y_position").val())==""){
        tishi("请输入门店坐标!");
    }else if($.trim($("#store_name").val())==""){
        tishi("请输入门店名称!");
    }else if($.trim($("#store_contanct").val())==""){
        tishi("请输入门店联系人!");
    }else if($.trim($("#store_address").val())==""){
        tishi("请输入门店地址!");
    }else if($("#store_status").val()==1 && ($("#store_sale_stime").val()=="" || $("#store_sale_etime").val()=="")){
        tishi("请输入门店的营业开始和结束时间!");
    }else if($.trim($("#store_phone").val())==""){
        tishi("请输入门店联系电话!");
    }else if($.trim($("#store_lim_pwd").val())==""){
        tishi("请设置免单密码!");
    }else{
        popup("#waiting");
        $(obj).parents("form").submit();
    }
}