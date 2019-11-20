$(document).ready(function() 
{
	if($(".panel-dashboard").length != 0) {
		$(".panel-dashboard[widget_script]").each(function() {
			var widget_script = $(this).attr("widget_script");
			$.ajax({url: widget_script, context: this, success: function(result){
				$(this).html(result);
				var javascript = $(this).find("pre");
			}});
		});
	}
});