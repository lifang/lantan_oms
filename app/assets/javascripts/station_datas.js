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

function select_serv(obj){      //选择获取取消选择服务加上√的样式
    $(obj).parent().removeAttr("class");
    if($(obj).attr("checked")=="checked"){
        $(obj).parent().attr("class", "checkBox check");
    }else{
        $(obj).parent().attr("class", "checkBox");
    }
}
