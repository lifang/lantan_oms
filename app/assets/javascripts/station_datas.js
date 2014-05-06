function search_station(store_id){      //搜索工位
    var s_name = $.trim($("#search_station").val());
    window.location.href="/stores/"+store_id+"/station_datas?s_name="+s_name;
}

function edit_station(store_id, station_id){    //编辑工位
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/station_datas/"+station_id+"/edit",
        dataType: "script",
        error: function(){
            $(".second_bg").hide();
            $("#waiting").hide();
            tishi("数据错误!");
        }
    })
}

function show_diff_servs(category_id, obj){
    $(obj).parent().find("li").removeAttr("class");
    $(obj).attr("class", "hover");
    $(obj).parents("div.newStationJob").find("div.jobClass_1").hide();
    $("#servs_div_"+category_id).show();
}

function select_serv(obj){      //选择获取取消选择服务加上√的样式
    $(obj).parent().removeAttr("class");
    if($(obj).attr("checked")=="checked"){
        $(obj).parent().attr("class", "checkBox check");
    }else{
        $(obj).parent().attr("class", "checkBox");
    }
}

function edit_station_commit(obj, staton_id, store_id){     //编辑工位验证
    var name = $.trim($("#station_name").val());
    var code = $.trim($("#station_code").val());
    var coll_code = $.trim($("#station_collector_code").val());
    if(name==""){
        tishi("工位名称不能为空!");
    }else if(code==""){
        tishi("工位编号不能为空!");
    }else if(coll_code==""){
        tishi("采集器编号不能为空!");
    }else{
        popup2("#waiting");
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/station_datas/name_valid",
            dataType: "json",
            data: {
                type : 1,
                station_id : staton_id,
                name : name,
                code : code
            },
            success: function(data){
                if(data.status==0){
                    $("#waiting").hide();
                    $(".second_bg2").hide();
                    tishi("工位名称或工位编号已存在!");
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

function station_cancel(){     //编辑或新建工位时取消
    $(".second_bg").hide();
    $("#station_form").hide();
    $("#station_form").empty();
}

function new_station(store_id){     //新建工位
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/station_datas/new",
        dataType: "script",
        error: function(){
            $(".second_bg").hide();
            $("#waiting").hide();
            tishi("数据错误!");
        }
    })
}

function new_station_commit(obj, store_id){     //新建工位验证
    var name = $.trim($("#station_name").val());
    var code = $.trim($("#station_code").val());
    var coll_code = $.trim($("#station_collector_code").val());
    if(name==""){
        tishi("工位名称不能为空!");
    }else if(code==""){
        tishi("工位编号不能为空!");
    }else if(coll_code==""){
        tishi("采集器编号不能为空!");
    }else{
        popup2("#waiting");
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/station_datas/name_valid",
            dataType: "json",
            data: {
                type : 0,
                name : name,
                code : code
            },
            success: function(data){
                if(data.status==0){
                    $("#waiting").hide();
                    $(".second_bg2").hide();
                    tishi("工位名称或工位编号已存在!");
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
