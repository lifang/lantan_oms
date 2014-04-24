function set_functions_new(type){       //新建 0部门 1职务 2商品 3物料 4服务
    if(type==0){
        $("#set_functions_new").find("h1").first().text("新建部门");
    }else if(type==1){

    }else if(type==2){
        $("#set_functions_new").find("h1").first().text("新建商品");
    }else if(type==3){
        $("#set_functions_new").find("h1").first().text("新建物料");
    }else if(type==4){
        $("#set_functions_new").find("h1").first().text("新建服务");
    }
    $("#new_commit_button").attr("onclick", "new_commit_button("+type+")");
    $("#set_functions_name").val("");
    popup("#set_functions_new");
}

function new_commit_button(type){       //验证
    var name = $.trim($("#set_functions_name").val());
    if(name==""){
        tishi("名称不能为空!");
    }else if(get_str_len(name)>16){
        tishi("名称长度不得超过16个字符!");
    }else{
        popup("#waiting");
        var store_id = $("#set_functions_new").find("input[type='hidden']").first().val();
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/new_valid",
            dataType: "json",
            data: {
                name : name,
                type : type
            },
            success: function(data){
                if(data.status==0){
                    $("#waiting").hide();
                    if(type==0){
                        tishi("已有同名的部门!");
                    }else if(type==1){

                    }else if(type==2){
                        tishi("已有同名的商品类型!");
                    }else if(type==3){
                        tishi("已有同名的物料类型!");
                    }else if(type==4){
                        tishi("已有同名的服务类型!");
                    }
                }else{
                    $.ajax({
                        type: "post",
                        url: "/stores/"+store_id+"/set_functions",
                        dataType: "script",
                        data: {
                            name : name,
                            type : type
                        },
                        error: function(){
                            $("#waiting").hide();
                            tishi("创建失败!");
                        }
                    })
                }
            },
            error: function(){
                $("#waiting").hide();
                tishi("数据错误!");
            }
        })
    }
}

function new_same_lv_dpt(level, store_id){    //新建同级部门
    $("#set_functions_new").find("h1").first().text("新建同级部门");
    $("#new_commit_button").attr("onclick", "new_same_lv_dpt_button("+level+")");
    $("#set_functions_name").val("");
    popup("#set_functions_new");
}

function new_same_lv_dpt_button(level){     //新建同级部门验证
    var name = $.trim($("#set_functions_name").val());
    if(name==""){
        tishi("名称不能为空!");
    }else if(get_str_len(name)>16){
        tishi("名称长度不得超过16个字符!");
    }else{
        popup("#waiting");
        var store_id = $("#set_functions_new").find("input[type='hidden']").first().val();
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/new_valid",
            dataType: "json",
            data: {
                name : name,
                type : 0
            },
            success: function(data){
                if(data.status==0){
                    $("#waiting").hide();
                    tishi("已有同名的部门!");
                }else{
                    $.ajax({
                        type: "post",
                        url: "/stores/"+store_id+"/set_functions",
                        dataType: "script",
                        data: {
                            name : name,
                            type : 0,
                            level : level
                        },
                        error: function(){
                            $("#waiting").hide();
                            tishi("创建失败!");
                        }
                    })
                }
            },
            error: function(){
                $("#waiting").hide();
                tishi("数据错误!");
            }
        })
    }
}

function set_functions_change_type(type, obj){   //切换页面显示类容
    $(obj).parents("ul").find("li").removeAttr("class");
    $("#menu_1").attr("class", "storeLeftMenu_1");
    $("#menu_2").attr("class", "storeLeftMenu_2");
    $("#menu_3").attr("class", "storeLeftMenu_3");
    var css = $(obj).parent().attr("class");
    $(obj).parent().attr("class", css+" hover");
    $("#dpt_div").hide();
    $("#goods_div").hide();
    $("#materials_div").hide();
    $("#servs_div").hide();
    if(type==1){
        $("#dpt_div").show();
    }else if(type==2){
        $("#goods_div").show();
        $("#materials_div").show();
    }else if(type==3){
        $("#servs_div").show();
    }
}

function set_funcions_edit(type, obj_id, store_id){       //编辑
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/set_functions/"+obj_id+"/edit",
        data: {
            type : type
        },
        dataType: "script",
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}

function edit_commit_button(type, obj_id, store_id){    //编辑验证
    var name = $.trim($("#set_functions_edit_name").val());
    if(name==""){
        tishi("名称不能为空!");
    }else if(get_str_len(name)>16){
        tishi("名称长度不得超过16个字符!");
    }else{
        popup("#waiting");
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/edit_valid",
            dataType: "json",
            data: {
                name : name,
                type : type,
                id : obj_id
            },
            success: function(data){
                if(data.status==0){
                    $("#waiting").hide();
                    if(type==0){
                        tishi("已有同名的部门!");
                    }else if(type==1){

                    }else if(type==2){
                        tishi("已有同名的商品类型!");
                    }else if(type==3){
                        tishi("已有同名的物料类型!");
                    }else if(type==4){
                        tishi("已有同名的服务类型!");
                    }
                }else{
                    $.ajax({
                        type: "put",
                        url: "/stores/"+store_id+"/set_functions/"+obj_id,
                        dataType: "script",
                        data: {
                            name : name,
                            type : type
                        },
                        error: function(){
                            $("#waiting").hide();
                            tishi("编辑失败!");
                        }
                    })
                }
            },
            error: function(){
                $("#waiting").hide();
                tishi("数据错误!");
            }
        })
    }
}

function set_funcions_delete(type, obj_id, store_id){     //删除
    var str = ""
    if(type==0){
        str = "确定删除该部门?"
    }else if(type==1){

    }else if(type==2){
        str = "确定删除该商品类别?"
    }else if(type==3){
        str = "确定删除该物料类别?"
    }else if(type==4){
        str = "确定删除该服务类别?"
    }
    var flag = confirm(str);
    if(flag){
        popup("#waiting");
        $.ajax({
            type: "delete",
            url: "/stores/"+store_id+"/set_functions/"+obj_id,
            data: {
                type : type
            },
            dataType: "json",
            success: function(data){
                $("#waiting").hide();
                $(".second_bg").hide();
                if(data.status==0){
                    tishi("删除失败!");
                }else{
                    tishi("删除成功!");
                    $.ajax({
                        type: "get",
                        url: "/stores/"+store_id+"/set_functions",
                        dataType: "script",
                        data: {
                            type : type
                        }
                    })
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

function del_position(position_id, store_id, obj){    //删除职务
    var flag = confirm("确定删除该职位?");
    if(flag){
        popup2("#waiting");
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/del_position",
            data: {
                p_id : position_id
            },
            dataType: "json",
            success: function(data){
                if(data.status==0){
                    $(".second_bg2").hide();
                    $("#waiting").hide();
                    tishi("删除失败!");
                }else{
                    $(obj).parents("li").remove();
                    $.ajax({
                        type: "get",
                        url: "/stores/"+store_id+"/set_functions",
                        dataType: "script",
                        data: {
                            type : 0
                        }
                    });
                    $(".second_bg2").hide();
                    $("#waiting").hide();
                    tishi("删除成功!");
                }
            },
            error: function(){
                $(".second_bg2").hide();
                $("#waiting").hide();
                tishi("数据错误!");
            }
        })
    }
}


function edit_position(obj){   //编辑职务
    var old_name = $(obj).parent().find("span").first().text();
    $(obj).next().hide();
    $(obj).hide();
    $(obj).parent().find("span").first().hide();
    $(obj).parent().find("input[type='text']").first().val(old_name);
    $(obj).parent().find("input[type='text']").first().show();
    $(obj).parent().find("input[type='text']").first().focus();
}

function edit_position_commit(dpt_id, position_id, store_id, obj){  //编辑职务验证并提交
    var old_name = $(obj).parent().find("span").first().text();
    var new_name = $(obj).val();
    if(new_name=="" || new_name==old_name){
        $(obj).prev().show();
        $(obj).val("");
        $(obj).hide();
        $(obj).next().show();
        $(obj).next().next().show();
    }else{
        popup2("#waiting");
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/edit_valid",
            data: {
                id : position_id,
                name : new_name,
                type : 1,
                dpt_id : dpt_id
            },
            dataType: "json",
            success: function(data){
                if(data.status==0){
                    $(obj).prev().show();
                    $(obj).val("");
                    $(obj).hide();
                    $(obj).next().show();
                    $(obj).next().next().show();
                    $("#waiting").hide();
                    $(".second_bg2").hide();
                    tishi("该部门下已有同名的职务!");
                }else{
                    $.ajax({
                        type: "post",
                        url: "/stores/"+store_id+"/set_functions/edit_position",
                        data: {
                            name : new_name,
                            id : position_id
                        },
                        dataType: "json",
                        success: function(data){
                            if(data.status==0){
                                $(obj).prev().show();
                                $(obj).val("");
                                $(obj).hide();
                                $(obj).next().show();
                                $(obj).next().next().show();
                                $("#waiting").hide();
                                $(".second_bg2").hide();
                                tishi("编辑失败!");
                            }else{
                                $.ajax({
                                    type: "get",
                                    url: "/stores/"+store_id+"/set_functions",
                                    dataType: "script",
                                    data: {
                                        type : 0
                                    }
                                });
                                $(obj).prev().text(new_name);
                                $(obj).prev().show();
                                $(obj).val("");
                                $(obj).hide();
                                $(obj).next().show();
                                $(obj).next().next().show();
                                $("#waiting").hide();
                                $(".second_bg2").hide();
                                tishi("编辑成功!");
                            }
                        },
                        error: function(){
                            $(obj).prev().show();
                            $(obj).val("");
                            $(obj).hide();
                            $(obj).next().show();
                            $(obj).next().next().show();
                            $("#waiting").hide();
                            $(".second_bg2").hide();
                            tishi("数据错误!");
                        }
                    })
                }
            },
            error: function(){
                $(obj).prev().show();
                $(obj).val("");
                $(obj).hide();
                $(obj).next().show();
                $(obj).next().next().show();
                $("#waiting").hide();
                $(".second_bg2").hide();
                tishi("数据错误!");
            }
        })
    }
}

function new_position(dpt_id, store_id){    //新建职务
    $("#new_position_commit_button").removeAttr("onclick");
    $("#new_position_commit_button").attr("onclick", "new_position_commit("+dpt_id+","+store_id+")");
    popup2("#new_position");
}

function new_position_commit(dpt_id, store_id){     //新建职务验证并提交
    var p_name = $.trim($("#new_position_name").val());
    if(p_name==""){
        tishi("职务名称不能为空!");
    }else if(get_str_len(p_name)>16){
        tishi("名称长度不得超过16个字符!");
    }else{
        popup2("#waiting");
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/new_valid",
            data: {
                name : p_name,
                type : 1,
                dpt_id : dpt_id
            },
            dataType: "json",
            success: function(data){
                if(data.status==0){
                    $("#waiting").hide();
                    tishi("该部门下已有同名的职务!");
                }else{
                    $.ajax({
                        type: "post",
                        url: "/stores/"+store_id+"/set_functions/new_position",
                        data: {
                            name : p_name,
                            dpt_id : dpt_id
                        },
                        dataType: "script",
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

function new_cancel_button(){    //新建 部门 职务 商品 物料 服务 取消
    $("#set_functions_new").hide();
    $("#set_functions_edit").hide();
    $(".second_bg").hide();
}

function new_position_cancel(){     //新建职务，取消
    $("#new_position").hide();
    $(".second_bg2").hide();
}