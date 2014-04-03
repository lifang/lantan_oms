// JavaScript Document
$(function(){		
	var ch = document.documentElement.clientHeight;
	if(ch > $(".loginBg").height()){
		$(".loginBg").css("height",ch);	
	}	
	var cw = document.documentElement.clientWidth;
	if($(".leftBox")){
		$(".leftBox").css("left",(cw-900)/2 - $(".leftBox").width() - 20 + "px");	
	}
	
	$(".loginAct").on("click",".chkbox",function(){
		$(this).toggleClass("check");
	});
	
	$(".second_box .close").click(function(){
		$(this).parents(".second_box").hide();
		$(".second_bg").hide();
	});
	
	$("body").on("click",".scd_btn",function(){
		$(".second_bg").show();
		$(".second_box."+$(this).attr("name")).show();
	});
	
	$("tr").each(function(){
		var table = $(this).parents(".table1");
		var i = table.find("tr").index($(this));
		if(i % 2 ==1 && i != 0){
			$(this).css("background","#f5f5f5");
		}
	});
	
	$(".selectBox").on("click","option",function(){
		$(this).parents(".selectBox").find("span").text($(this).val());
	});
	$(".selectBox2").on("click","option",function(){
		$(this).parents(".selectBox2").find("span").text($(this).val());
	});
	
	$(".paidBill").click(function(){
		$(this).toggleClass("open");
	});
	
	$(".checkBox,.radioBox").on("click","input",function(){
		$(this).parent().toggleClass("check");
	});
	
});

function tishi(message){
    $(".tab_Prompt").find("p").first().html(message);
    var scolltop = document.body.scrollTop|document.documentElement.scrollTop;
    var win_height = document.documentElement.clientHeight;//jQuery(document).height();
    var z_layer_height = $("#tab_Prompt").height();
    $(".tab_Prompt").css('top',(win_height-z_layer_height)/2 + scolltop);
    var doc_width = $(document).width();
    var layer_width = $(".tab_Prompt").width();
    $(".tab_Prompt").css('left',(doc_width-layer_width)/2);
    $(".tab_Prompt").css('display','block');
    jQuery('.tab_Prompt').fadeTo("slow",1);
    $(".tab_Prompt .x").click(function(){
        $(".tab_Prompt").css('display','none');
        stopPropagation(arguments[1]);
    })
    setTimeout(function(){
        jQuery('.tab_Prompt').fadeTo("slow",0);
    }, 3000);
    setTimeout(function(){
        $(".tab_Prompt").css('display','none');
    }, 3000);

}
