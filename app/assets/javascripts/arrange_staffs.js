$(function(){
    var selects = $("#arrange_staff_table").find("select");
    $.each(selects, function(){
        var txt = $(this).find("option:selected").text();
        $(this).parents(".selectBox").find("span").first().text(txt);
    });

    $("#arrange_staff_table").on("change", "select", function(){
        var s = $(this).find("option:selected").text();
        $(this).parents(".selectBox").find("span").first().text(s);
    })
})

function arrange_staffs_valid(obj){
    var flag = true;
    var station_status_tds = $("#arrange_staff_table").find("td[name='station_status_td']");
    var staff_ids = []
    $.each(station_status_tds, function(){
        var td = $(this);
        var status = td.find("select").first().val();
        if(status==2){
            var s1 = $(td.parent().find("td[name='station_staffs_td']").find("select")[0]).val();
            var s2 = $(td.parent().find("td[name='station_staffs_td']").find("select")[1]).val();
            if(s1==0 || s2==0){
                tishi("状态正常的工位必须分配技师!");
                flag = false;
                return false;
            }else if(s1==s2){
                tishi("一个工位上不能有两个相同的技师!");
                flag = false;
                return false;
            }else{
                staff_ids.push(s1);
                staff_ids.push(s2);
            }
        }
    });
    if(flag){
        if(staff_ids.length > 0){
            staff_ids.sort();
            var flag2 = true;
            for(var i=0;i < staff_ids.length-1;i++){
                if(staff_ids[i]==staff_ids[i+1]){
                    flag2 = confirm("技师被重复分配,是否继续?");
                    break;
                }
            };
            if(flag2){
                popup("#waiting");
                $(obj).parents("form").submit();
            }
        }else{
            popup("#waiting");
            $(obj).parents("form").submit();
        }
    }


}