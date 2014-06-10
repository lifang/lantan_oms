$(function(){
    var ss = $(document).find("option:selected");
    $.each(ss, function(){
        var txt = $(this).text();
        $(this).parents(".selectBox").find("span").first().text(txt);
    });

    $(document).on("change", "select", function(){
        var txt = $(this).find("option:selected").first().text();
        $(this).parents(".selectBox").find("span").first().text(txt);
    })
})

function new_staff(store_id){       //新建员工
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/staff_manages/new",
        dataType: "script",
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}

function staff_valid(obj, store_id){    //新建员工验证
    var flag = true;
    var name = $.trim($("#staff_name").val());
    var phone = $.trim($("#staff_phone").val());
    var idn = $.trim($("#staff_idn").val());
    var dpt = $("#staff_dpt").val();
    var posi = $("#staff_posi").val();
    var base_salary = $.trim($("#staff_base_salary").val());
    var entry_time = $("#staff_entry_time").val();
    var work_st = $("#staff_work_st");
    var secure_fee = $.trim($("#staff_secure_fee").val());
    var reward_fee = $.trim($("#staff_reward_fee").val());
    if(is_name(name)==false){
        tishi("请输入员工名字，不得包含非法字符!");
        flag = false;
    }else if(is_phone(phone)==false){
        tishi("请输入正确的手机号码!");
        flag = false;
    }else if(idn==""){
        tishi("请输入身份证号码!");
        flag = false;
    }else if(dpt==0){
        tishi("请选择部门!");
        flag = false;
    }else if(posi==0){
        tishi("请选择职位!");
        flag = false;
    }else if(is_float(base_salary)==false){
        tishi("请输入正式底薪,底薪必须为正整数或者两位小数!");
        flag = false;
    }else if(entry_time==""){
        tishi("请选择入职时间!");
        flag = false;
    }else if(secure_fee!="" && is_float(secure_fee)==false){
        tishi("请输入正确的社保扣款,必须为正整数或两位小数!");
        flag = false;
    }else if(reward_fee!="" && is_float(reward_fee)==false){
        tishi("请输入正确的补贴,必须为正整数或两位小数!");
        flag = false;
    }else if(work_st.attr("checked")=="checked"){
        var prob_days = $.trim($("#staff_prob_days").val());
        var prob_salary = $.trim($("#staff_prob_salary").val());
        if(is_int(prob_days)==false){
            tishi("请输入正确的试用期时长!");
            flag = false;
        }else if(is_float(prob_salary)==false){
            tishi("请输入正确的试用期底薪!");
            flag = false;
        }
    }
    if(flag){
        popup2("#waiting");
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/staff_manages/staff_valid",
            dataType: "json",
            data: {
                types : 1,
                staff_name : name,
                staff_phone : phone
            },
            success: function(data){
                if(data.status==1){
                    $(obj).parents("form").submit();
                }else{
                    $("#waiting").hide();
                    $(".second_bg2").hide();
                    tishi(data.msg);
                }
            },
            error: function(){
                $("#waiting").hide();
                $(".second_bg2").hide();
                tishi("验证失败!");
            }
        })
    }
}

function new_reward_violation(store_id, types){     //新建处罚或奖励
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/staff_manages/new_reward_violation",
        dataType: "script",
        data: {
            types : types
        },
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}

function r_v_valid(obj){    //新建处罚或奖励验证
    var l = $("#staffs_list").find("input[type='checkbox']:checked").length;
    var score_num = $.trim($("#score_num").val());
    var salary_num = $.trim($("#salary_num").val());
    var situation = $.trim($("#situation").val());
    var mrak = $.trim($("#mark").val());
    if(l<=0){
        tishi("没有选择任何对象");
    }else if(situation==""){
        tishi("请输入原因!");
    }else if(score_num!="" && is_float(score_num)==false){
        tishi("请输入正确的分值!");
    }else if(salary_num!="" && is_float(salary_num)==false){
        tishi("请输入正确的金额!");
    }else if(mrak==""){
        tishi("请输入备注说明!");
    }else{
        popup2("#waiting");
        $(obj).parents("form").submit();
    }
}

function new_train(store_id){   //新建培训
    popup("#waiting");
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/staff_manages/new_train",
        dataType: "script",
        error: function(){
            $("#waiting").hide();
            $(".second_bg").hide();
            tishi("数据错误!");
        }
    })
}

function train_valid(obj){  //新建培训验证
    var s_t = $("#train_s_time").val();
    var e_t = $("#train_e_time").val();
    var l = $("#staffs_list").find("input[type='checkbox']:checked").length;
    var cont = $.trim($("#train_cont").val());
    if(s_t=="" || e_t==""){
        tishi("培训的开始和结束时间不能为空!");
    }else if(l <= 0){
        tishi("没有选择任何培训人员!");
    }else if(cont==""){
        tishi("请输入培训原因!");
    }else if(s_t!="" && e_t!="" && new Date(s_t) > new Date(e_t)){
        tishi("培训的开始时间不得大于结束时间!");
    }else{
        popup2("#waiting");
        $(obj).parents("form").submit();
    }
}