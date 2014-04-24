function search_staff(store_id){
    var staff_name = $.trim($("#search_staff_name").val());
    window.location.href="/stores/"+store_id+"/set_staffs?staff_name="+staff_name;
}

function set_staff_roles(staff_id, store_id){   //分配职位
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/set_staffs/"+staff_id+"/edit",
        dataType: "script",
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}

function select_roles(obj){      //选中或者取消权限时加上或去掉√样式
    $(obj).parent().removeAttr("class");
    if($(obj).attr("checked")=="checked"){
        $(obj).parent().attr("class", "checkBox check");
    }else{
        $(obj).parent().attr("class", "checkBox");
    }
}

function set_staff_roles_commit(){
    popup2("#waiting");
}

function set_staff_roles_cancel(){
    $("#set_staff_roles").hide();
    $(".second_bg").hide();
    $("#set_staff_roles").empty();
}