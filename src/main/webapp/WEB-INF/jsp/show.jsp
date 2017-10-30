<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
	<title>中山大学发票识别监控系统</title>
	<meta charset="utf-8">
	<script src="script/jquery-3.2.1.min.js"></script>
	<script type="text/javascript" src="script/StackBlur.js"></script>
	<script type="text/javascript" src="script/bootstrap.min.js"></script>
	<link rel="stylesheet" type="text/css" href="style/bootstrap.min.css">
	<link rel="stylesheet" type="text/css" href="style/layout.css">
</head>
<body>
	<header>
		<img src="pic/zhongda.jpg" style="width: 15%;" />
	</header>
	<main>
	   <div align="right">
	      <h3 align="right">欢迎!${user.user_name}!</h3>
	   	  <button onclick="javascrtpt:window.location.href='${pageContext.request.contextPath}/logout.action'">注销</button>
	   </div> 
		<aside class="col-lg-2">
			<div class="list-group">
				<a href="${pageContext.request.contextPath}/queue.action" class="list-group-item">缓冲队列</a>
				<a href="${pageContext.request.contextPath}/show.action" class="list-group-item selected">监控显示</a>
				<a href="${pageContext.request.contextPath}/paint.action" class="list-group-item">模板库</a>
				<a href="${pageContext.request.contextPath}/fault.action" class="list-group-item">报错发票
					<span class="badge">4</span>
				</a>
			</div>
		</aside>
		<div class="col-lg-10">
			<div class="col-lg-8" style="padding-left: 0px;">
				<div class="panel panel-default">
				    <div class="panel-heading">
				        <h2 class="panel-title" style="font-size: 18px;">正在识别的图片</h2>
				        <p class="help-block" style="margin: 1em 0 0; font-size: 14px;"><span>发送者：</span><span style="margin-left: 4em;">发送时间：</span></p>
				    </div>
				    <div class="panel-body" style="padding: 0px;">
						<div style="width: 100%; height:auto; overflow: hidden; border-radius: 4px; position: relative;" id="canvas_panel_body">
							<canvas style="background: url('pic/shibie_placehold.png')  no-repeat center; background-color: rgba(255,255,255,0); background-size: cover; position:relative; z-index: 2;" id="show_fapiao"></canvas>
							<!-- 用于备份图片的画布 -->
							<canvas id="copy_fapiao" style="z-index: 1; position: absolute; background: url('pic/shibie_placehold.png') no-repeat center; background-size: cover;"></canvas>
						</div>
				    </div>
				</div>
			</div>
			<div class="col-lg-4">
				<div class="panel panel-default">
				    <div class="panel-heading">
				        <h3 class="panel-title">区域信息<span class="title_load"></span></h3>
				    </div>
				    <div class="panel-body">
				        <ul class="list-group" id="img_msg" style="margin-bottom: 0px;">
				        	<li class="list-group-item">发票类型:</li>
							<li class="list-group-item">金额:</li>
							<li class="list-group-item">客户名称:</li>
							<li class="list-group-item">发票号码:</li>
							<li class="list-group-item">日期:</li>
						    <li class="list-group-item">时间:</li>
							<li class="list-group-item">具体信息:</li>
							<li class="list-group-item">身份证号码:</li>
						</ul>
				    </div>
				</div>
				<div class="panel panel-default">
					<div class="panel-heading">
				        <h3 class="panel-title">套用模板<span class="muban_info"></span></h3>
				    </div>
				    <div class="panel-body">
				        <img src="pic/shibie_placehold.png" style="width: 100%;" id="muban" />
				    </div>
				</div>
			</div>
		</div>
	</main>

	<script type="text/javascript">
		var ip2; //host_ip
		var wsuri; //websocket_url
        var ws = null;

        //读取config.xml配置ip等信息
        function loadxml(fileName) {
        	$.ajax({
        		async : false,
        		url : fileName,
        		dataType : "xml",
        		type : "GET",
        		success : function(res, status) {
        			var xml_data = res;
        			ip2 = xml_data.getElementsByTagName("connect_ip")[0].innerHTML;
        			wsuri = "ws://" + ip2 + "/invoice/webSocketServer";
        			console.log(wsuri);
        		},
        		error : function() {
        			alert("读取配置文件失败，稍后重试");
        		}
        	})
        }

        function resetImgLine(jq_ele, img_list) {
        	jq_ele.each(function(index, e){
				$(this).html("");
				if(index < img_list.length) {
					$(this).append("<img>");
					$(this).children().eq(0).get(0).src = img_list[index].url;	
				}
			})
        }

        //返回的画布坐标和实际画布坐标换算
        function coordinateConvert(x, y, w, h) {
        	var size = parseFloat($("#show_fapiao").width()) / 1160;
        	return {
        		convert_x: parseFloat(x * size),
        		convert_y: parseFloat(y * size),
        		convert_w: parseFloat(w * size),
        		convert_h: parseFloat(h * size)
        	}
        }

        //获取画布及其上下文
        var c=document.getElementById("show_fapiao");
        var c1=document.getElementById("copy_fapiao");
		var cxt;
		var cxt1;

        function connectEndpoint(){

            ws = new WebSocket(wsuri);
            var img_list = [];
            var nth_area = 1; //记录这是识别的第几个区域

            //test
            $("#copy_fapiao").css("backgroundImage", "url(\'4.bmp\')");
            var temp_img = new Image();
            temp_img.onload = function(){
    			//cxt.drawImage(temp_img, 0, 0, parseFloat($("#show_fapiao").width()), parseFloat($("#show_fapiao").height()));
    			//stackBlurCanvasRGB("show_fapiao", 0, 0, parseFloat($("#show_fapiao").width()), parseFloat($("#show_fapiao").height()), 15);
    			var temp_data = cxt1.getImageData(0, 0, 100, 100);
    			console.log(temp_data);
    			cxt.putImageData(temp_data, 0,0);
    		}
    		temp_img.src = $("#copy_fapiao").css("backgroundImage").split("url")[1].replace("(", "").replace(")","");

            ws.onmessage = function(evt) {
            	//alert(evt.data);
            	console.log(evt.data);
            	var data = JSON.parse(evt.data);
            	if(data.msg_id == 203 || data.msg_id == 202) {
					//copy_fapiao获取背景图, show_fapiao绘制图片
            		$("#copy_fapiao").css("backgroundImage", "url(" + data.img_str + ")");
            		$("#show_fapiao").css("backgroundImage", "url('')");
            		var temp_img = new Image();
            		temp_img.onload = function(){
            			cxt.clearRect(0, 0, parseFloat($("#show_fapiao").width()), parseFloat($("#show_fapiao").height()));
            			cxt.drawImage(temp_img, 0, 0, parseFloat($("#show_fapiao").width()), parseFloat($("#show_fapiao").height()));
            			$(".muban_info").text("（正在搜索可用模板）");
            		}
            		temp_img.src = data.img_str;
            		if(data.msg_id == 202) {
            			console.log(data.region_list);
            			for(var i = 0; i < data.region_list.length; i++) {
            				var data1 = JSON.parse(data.region_list[i]);
            				$("#img_msg li").each(function() {
		            			if($(this).text().split(":")[0] == data1.pos_id) {
		            				var origin_text = $(this).text();
		            				$(this).text(origin_text + data1.ocr_result);
		            			}
		            		});
            			}
            		}
            	}
            	else if(data.msg_id == 100 && data.status == 0) {
            		console.log(data.id + " " + data.url); //输出发票类
            		$(".muban_info").text("（模板名称：" + data.label + "）");
            		$("#muban").get(0).src = data.url;
            		var origin_text = $("#img_msg li").eq(0).text();
            		$("#img_msg li").eq(0).text(origin_text + data.model_label);
            	}
            	else if(data.msg_id == 101 && data.status == 0) {
            		//模糊其它区域
            		if(nth_area == 1){
            			stackBlurCanvasRGB("show_fapiao", 0, 0, parseFloat($("#show_fapiao").width()), parseFloat($("#show_fapiao").height()), 15);	
            			nth_area ++;
            		} 
            		
            		//框出识别区域并使其区域清晰
            		// console.log(cxt1);
					var position = coordinateConvert(data.position.x, data.position.y, data.position.w, data.position.h);
					//console.log("data.position.x:" + data.position.x + ";" + "position.convert_x:" + position.convert_x);
					var temp_imageData = cxt1.getImageData(position.convert_x, position.convert_y, position.convert_w, position.convert_h);
					cxt.putImageData(temp_imageData, position.convert_x, position.convert_y);
            		cxt.strokeRect(position.convert_x, position.convert_y, position.convert_w, position.convert_h);
            		$(".title_load").text("（正在识别" + data.pos_id + "）");
            	}
            	else if(data.msg_id == 102 && data.status == 0) {
            		$("#img_msg li").each(function() {
            			if($(this).text().split(":")[0] == data.pos_id) {
            				var origin_text = $(this).text();
            				$(this).text(origin_text + data.ocr_result);
            			}
            		});
            	}
            	else if(data.msg_id == 1 && data.status == 0) {
            		$(".title_load").text("（识别完毕）");
            		nth_area = 1;
            		console.log(data);

            		//过3秒后重置
            		setTimeout(function(){
            			$(".title_load").text("");
            			cxt.clearRect(0, 0, parseFloat($("#show_fapiao").width()), parseFloat($("#show_fapiao").height()));
            			$("#show_fapiao").css("backgroundImage", "url('pic/shibie_placehold.png')");
        				$("#muban").get(0).src = "pic/shibie_placehold.png";
        				$("#copy_fapiao").css("backgroundImage", "url('pic/shibie_placehold.png')");
        				$(".muban_info").text("");
            			$("#img_msg li").each(function() {
            				var origin_text = $(this).text().split(":")[0];
            				$(this).text(origin_text+":");
	            		});
            		}, 3000);
            	}
            };

            ws.onclose = function(evt) {
                console.log("close");
            };

            ws.onopen = function(evt) {
                console.log("open");
                //开始加载图片
                $.ajax({
                	url: "http://" + ip2 + "/invoice/openConsole",
                	type: "POST",
                	data: {},
                	success: function(res) {
                		console.log(res);
                		var data = JSON.parse(res);
                		$("#copy_fapiao").css("backgroundImage", "url(" + data.img_str + ")");
	            		var temp_img = new Image();
	            		temp_img.onload = function(){
	            			cxt.clearRect(0, 0, parseFloat($("#show_fapiao").width()), parseFloat($("#show_fapiao").height()));
	            			cxt.drawImage(temp_img, 0, 0, parseFloat($("#show_fapiao").width()), parseFloat($("#show_fapiao").height()));	
	            		}
	            		temp_img.src = data.img_str;
	            		//temp_img.src = data.url;
            			console.log(data.region_list);
            			for(var i = 0; i < data.region_list.length; i++) {
            				var data1 = JSON.parse(data.region_list[i]);
            				$("#img_msg li").each(function() {
		            			if($(this).text().split(":")[0] == data1.pos_id) {
		            				var origin_text = $(this).text();
		            				$(this).text(origin_text + data1.ocr_result);
		            			}
		            		});
            			}
                	},
                	error: function(e) {
                		console.log(e);
                	}
                })
            };
        }

        //初始化画布调整画布及图片比例为1160/817
        function initCanvasPhoto() {
        	$("#muban").get(0).style.height = parseFloat($("#muban").width() * parseFloat(817/1160)) + "px";
        	$("#show_fapiao").get(0).width = $("#canvas_panel_body").get(0).offsetWidth;
        	$("#show_fapiao").get(0).height = parseFloat($("#show_fapiao").get(0).width * parseFloat(817/1160));
    		$("#show_fapiao").css("backgroundSize", $("#show_fapiao").get(0).width+"px "+$("#show_fapiao").get(0).height+"px");
        	$("#copy_fapiao").get(0).width = $("#show_fapiao").get(0).width;
        	$("#copy_fapiao").get(0).height = $("#show_fapiao").get(0).height;
        	$("#copy_fapiao").css("backgroundSize", $("#copy_fapiao").get(0).width+"px "+$("#copy_fapiao").get(0).height+"px");

        	$("#copy_fapiao").get(0).style.top = $("#show_fapiao").get(0).offsetTop;
        	$("#copy_fapiao").get(0).style.left = $("#show_fapiao").get(0).offsetLeft;
        }

        $(document).ready(function(){
        	initCanvasPhoto();

        	cxt = c.getContext("2d");
        	cxt1 = c1.getContext("2d");
        	cxt.strokeStyle = "#00ff36";
			cxt.lineWidth = 2;
        	//console.log(cxt);

        	loadxml("config.xml");
        	connectEndpoint();
        	//ws.send("success");
        })
	</script>
</body>
</html>