function logins_valid(obj){
    var name = $("#logins_form").find("input[name='logins_name']").first().val();
    var pwd = $("#logins_form").find("input[name='logins_pwd']").first().val();
    if($.trim(name)==""){
        tishi("用户名不能为空!");
    }else if($.trim(pwd)==""){
        tishi("密码不能为空!");
    }else{
        $(obj).parents("form").submit();
    }
}

$(function(){
    var d = $("#logins_form").on("click", "div.chkbox", function(){
        var has_check = $(this).attr("class");
        if(has_check=="chkbox check"){
            $("#logins_form").find("input[type='checkbox']").first().attr("checked", "checked");
        }else{
            $("#logins_form").find("input[type='checkbox']").first().removeAttr("checked");
        }
    })

})