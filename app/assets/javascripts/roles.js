function edit_role(role_name, role_id, store_id){       //编辑角色
    $("#set_role").find("h1").first().text("编辑角色");
    $("#set_role_name").val(role_name);
    $("#role_commit_button").removeAttr("onclick");
    $("#role_commit_button").attr("onclick", "edit_role_commit("+ role_id + "," + store_id + ")");
    popup("#set_role");
}

function edit_role_commit(role_id, store_id){   //编辑角色验证
    var role_name = $.trim($("#set_role_name").val());
    if(role_name==""){
        tishi("角色名不能为空!");
    }else if(get_str_len(role_name) > 16){
        tishi("角色名不得超过16个字符!");
    }else{
        popup2("#waiting");
        $.ajax({
            type: "post",
            url: "/stores/"+store_id+"/roles/role_name_valid",
            data: {
                role_name : role_name,
                role_id : role_id,
                type : 1
            },
            dataType: "json",
            success: function(data){
                if(data.status==0){
                    $("#waiting").hide();
                    $(".second_bg2").hide();
                    tishi("已有同名的角色!");
                }else{
                    $.ajax({
                        type: "put",
                        url: "/stores/"+store_id+"/roles/"+role_id,
                        data: {
                            role_name : role_name
                        },
                        dataType: "json",
                        success: function(){
                            window.location.href="/stores/"+store_id+"/roles";
                        },
                        error: function(){
                            $("#waiting").hide();
                            $(".second_bg2").hide();
                            tishi("数据错误!");
                        }
                    })
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

function new_role(store_id){       //新建角色
    $("#set_role").find("h1").first().text("新建角色");
    $("#set_role_name").val("");
    $("#role_commit_button").removeAttr("onclick");
    $("#role_commit_button").attr("onclick", "new_role_commit("+ store_id + ")");
    popup("#set_role");
}

function new_role_commit(store_id){   //新建角色验证
    var role_name = $.trim($("#set_role_name").val());
    if(role_name==""){
        tishi("角色名不能为空!");
    }else if(get_str_len(role_name) > 16){
        tishi("角色名不得超过16个字符!");
    }else{
        popup2("#waiting");
        $.ajax({
            type: "post",
            url: "/stores/"+store_id+"/roles/role_name_valid",
            data: {
                role_name : role_name,
                type : 0
            },
            dataType: "json",
            success: function(data){
                if(data.status==0){
                    $("#waiting").hide();
                    $(".second_bg2").hide();
                    tishi("已有同名的角色!");
                }else{
                    $.ajax({
                        type: "post",
                        url: "/stores/"+store_id+"/roles",
                        data: {
                            role_name : role_name
                        },
                        dataType: "json",
                        success: function(){
                            window.location.href="/stores/"+store_id+"/roles";
                        },
                        error: function(){
                            $("#waiting").hide();
                            $(".second_bg2").hide();
                            tishi("数据错误!");
                        }
                    })
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

function set_auth(role_id, store_id){   //设定权限
    $("#new_role_button").hide();
    $(".roleBox").find("div[name='role_act_div']").hide();
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/roles/set_auth",
        data: {
            role_id : role_id
        },
        dataType: "script",
        error: function(){
            $("#new_role_button").show();
            $(".roleBox").find("div[name='role_act_div']").show();
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}

function set_role_cancel(){
    $("#set_role").hide();
    $(".second_bg").hide();
}

function set_auth_cancel(){
    $("#new_role_button").show();
    $(".roleBox").find("div[name='role_act_div']").show();
    $("#set_auth_div").empty();
}

function select_roles(obj){      //选中或者取消权限时加上或去掉√样式
    $(obj).parent().removeAttr("class");
    if($(obj).attr("checked")=="checked"){
        $(obj).parent().attr("class", "checkBox check");
    }else{
        $(obj).parent().attr("class", "checkBox");
    }
}

function select_menus(obj){ //选中或者取消菜单时...
    $(obj).parent().removeAttr("class");
    if($(obj).attr("checked")=="checked"){
        $(obj).parent().attr("class", "checkBox check");
        $(obj).parents(".rightSet").find(".rightSetPicker").first().find("input[type='checkbox']").attr("checked", "checked");
        var divs = $(obj).parents(".rightSet").find(".rightSetPicker").first().find(".checkBox");
        $.each(divs, function(){
            $(this).removeAttr("class");
            $(this).attr("class", "checkBox check");
        })
    }else{
        $(obj).parent().attr("class", "checkBox");
        $(obj).parents(".rightSet").find(".rightSetPicker").first().find("input[type='checkbox']").removeAttr("checked");
        var divs = $(obj).parents(".rightSet").find(".rightSetPicker").first().find(".checkBox");
        $.each(divs, function(){
            $(this).removeAttr("class");
            $(this).attr("class", "checkBox");
        })
    }
}

function set_auth_commit(obj){  //设置权限提交
    popup("#waiting");
    $(obj).parents("form").submit();
}

function delete_role(role_id, store_id, obj){    //删除角色
    var flag = confirm("确定删除该角色?");
    if(flag){
        popup("#waiting");
        $.ajax({
            type: "delete",
            url: "/stores/"+store_id+"/roles/"+role_id,
            dataType: "json",
            success: function(data){
                if(data.status==0){
                    $("#waiting").hide();
                    $(".second_bg").hide();
                    tishi("删除失败!");
                }else{
                    $("#waiting").hide();
                    $(".second_bg").hide();
                    tishi("删除成功!");
                    $(obj).parents(".role").remove();
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