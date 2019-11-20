#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use dm_cms;
use sitetxt;
use migcrender;
use members;
use data;
use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset);

$dbh_data = $dbh;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
$use_global_sitetxt = 0;

my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

my $publish_token = create_token(10);

$sw = $cgi->param('sw') || "init_build";

my @fcts = qw(
			build_pages
			check_session_validity
		);

if (is_in(@fcts,$sw)) 
{ 
    &$sw();
} 

sub check_session_validity
{
see();
exit;
}

sub init_build
{
	
	my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
	my $id_default_page = $migcms_setup{id_default_page};
	$url_rewriting = get_url({debug=>0,debug_results=>0,nom_table=>'migcms_pages',id_table=>$id_default_page, id_language => $colg});
	$home = "$config{baseurl}/";

	my $retouches_rapides = <<"EOH";
			<section class="panel text-center">
				<header class="panel-heading">
					$migctrad{build_title_wysiwyg}
				</header>
				<div class="panel-body">
					<p>$migctrad{build_descr_wysiwyg}</p>
					
					<a class="btn btn-primary" target="_blank"  href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page=$id_default_page&edit=y" role="button"><i class="fa fa-pencil-square-o"></i>  $migctrad{build_descr_wysiwyg}</a>
				</div>
			</section>
EOH
	if($migcms_setup{view_edit_on} ne 'y')
	{
		$retouches_rapides = '';
	}
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	my $ts = $sec.$min.$hour.$mon.$year;
	my $page = <<"EOH";
<div class="wrapper">
	<div class="row">
		<div class="col-sm-12">
			<section class="panel text-center">
				<header class="panel-heading">
					$migctrad{build_title_publish}
				</header>
				<div class="panel-body">
					<p>$migctrad{build_descr_publish}</p>
					
					<a class="btn btn-lg btn-success" id="publish_do" href="#" role="button"><i class="fa fa-check"></i> $migctrad{build_action_publish}</a>
				</div>
			</section>
		</div>
	</div>
	<br />
	<div class="row">
		<div class="col-sm-6">
			<section class="panel text-center">
				<header class="panel-heading">
					$migctrad{top_viewsite}
				</header>
				<div class="panel-body">
					<p>$migctrad{top_viewsite_descr}</p>
					
					<a class="btn btn-primary" target="_blank" href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page=$id_default_page" role="button"><i class="fa fa-external-link"></i> $migctrad{adm_preview}</a>
					<a class="btn btn-primary" id="" target="_blank" href="$home" role="button"><i class="fa fa-external-link"></i> $migctrad{build_action_acceder}</a>
				</div>
			</section>
		</div>
		<div class="col-sm-6">
			$retouches_rapides
		</div>
	</div>
</div>

	
	<script> 
    
    jQuery(document).ready(function() 
    { 
		var publish_do = jQuery("#publish_do");
		publish_do.click(function()
		{
			do_publish();
			return false;
			
		});
        
    });
	
	function do_publish()
	{
	   swal({   
	   title: "$migctrad{build_title_publish}? ",   
	   text: "<div class='progr_perc'>0%</div><div class='progress '><div class='progress-bar progress-striped' style='width: 0%; background-color:#5cb85c'></div></div>",   
	   html:true,
	   showCancelButton: true,   
	   confirmButtonColor: "#5cb85c",   
	   confirmButtonText: "$migctrad{publish_action_1}",   
	   cancelButtonText: "$migctrad{publish_action_2}",   
	   closeOnConfirm: false,   
	   closeOnCancel: false }, 
	   function(isConfirm)
	   {    
		    jQuery('.progress-bar').css('width','0%'); 

			if (isConfirm)
			{     
				jQuery('.sa-button-container').hide();
				jQuery('.progress-bar').css('width','0%'); 
				jQuery('.progress').removeClass('hide');
				var perc = 0;
				var timeint_progression = setInterval(function()
				{ 
					/*
					jQuery.get( "../syslogs/publish_progession.txt.log?var=$ts", function( progession ) {
											jQuery('.progress-bar').css('width',progession+'%'); 

					});
					*/
					var request_prog =jQuery.ajax(
					{
						url: "../syslogs/publish_progession.txt.log?var=$ts",
						type: "GET",
						cache: false,
						dataType: "html"
					});
					request_prog.done(function(progession) 
					{
						if(progession > 0)
						{
							jQuery('.progress-bar').css('width',progession+'%'); 
						}
						jQuery('.progr_perc').html(progession+'%');
					});
							
					
				}, 1250);
				
				var request =jQuery.ajax(
				{
					url: '$config{baseurl}/cgi-bin/adm_migcms_build.pl?',
					type: "GET",
					data: 
					{
					   sw : 'do_build_pages'			   
					},
					dataType: "html"
				});
				
				request.done(function(msg) 
				{
					clearInterval(timeint_progression);
					
					
					jQuery('.progress-bar').css('width','100%');
					
					jQuery('.progress').addClass('hide');

					jQuery('.sa-button-container').show();
					swal({title:"$migctrad{publish_status_ok_title}", text:"$migctrad{publish_status_ok}", type:"success"});  
				});
				
				request.fail(function(jqXHR, textStatus) 
				{
					clearInterval(timeint_progression);
				});
			} 
			else 
			{     
				swal({title:"$migctrad{publish_status_ko_title}", text:"$migctrad{publish_status_ko}", type:"error", timer: 2000});   
			} 
		}
		);
		return false;
	}
	</script>
EOH

	see();
	print migc_app_layout($page);
	exit;
# $migctrad{build_question_publish}
}