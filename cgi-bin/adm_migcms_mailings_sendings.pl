#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI; 
use DBI;  
use def; 
use mailing;
use tools; 
use dm;
use migcrender;
use members;

%status = (
	'01/new'        =>"$migctrad{mailing_status_new}",
	'02/started'    =>"$migctrad{mailing_status_started}",
	'03/current'    =>"$migctrad{mailing_status_current}",
	'04/ended'   =>"$migctrad{mailing_status_ended}",
	'05/aborted'  =>"$migctrad{mailing_status_aborted}",
	'06/planned'  =>"$migctrad{mailing_status_planned}",
);

my $id_migcms_page = get_quoted('id_migcms_page');
my %migcms_page = read_table($dbh,'migcms_pages',$id_migcms_page);

$dbh_send = DBI->connect($config{db_qm},$config{login_qm},$config{passwd_qm}) or suicide("cannot connect to sending DB");

members::after_save_create_token();
sync_mailings_from_mailer();

if($id_migcms_page eq "") {
	$dm_cfg{wherep} = $dm_cfg{wherel}  = "";
}
else {
	$dm_cfg{wherep} = $dm_cfg{wherel}  = "id_migcms_page = '$id_migcms_page'";
}

$dm_cfg{customtitle} = $migctrad{blocktypes_title};
$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{visualiser} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{delete} = 0;
$dm_cfg{edit} = 1;
my $sel = get_quoted('sel'),
$dm_cfg{after_add_ref} = \&after_add;

$dm_cfg{page_title} = "$migcms_page{mailing_object} > Envois";

$dm_cfg{add} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "mailing_sendings";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_mailings_sendings.pl?id_migcms_page=$id_migcms_page";
# $dm_cfg{javascript_custom_func_form} = 'custom_func_form_sendings';
$dm_cfg{default_ordby} = 'id DESC';

$dm_cfg{list_html_top} .= <<"EOH";
	
EOH

my $multisites = 1;
if($config{multisites} eq "y") {
	$multisites = 0;
}

my @basehref = sql_lines({debug=>'1',table=>'config',where=>"WHERE varname LIKE '%fullurl_%'",ordby=>"varname"});
%basehref = ();
# $basehref{"01/1"} = $config{fullurl};
my $i = 1;
foreach $basehref_foreach (@basehref)
{
	my %basehref_foreach = %{$basehref_foreach};
		
	$basehref{$i."/".$basehref_foreach{id}} = $basehref_foreach{varvalue};
	$i++;
}

my @google_analytics_account = sql_lines({debug=>'0',table=>'config',where=>"WHERE varname LIKE '%google_analytics%'"});
%googleanalytics = ();
my $j = 1;

foreach $google_analytics_account (@google_analytics_account)
{
	my %google_analytics_account = %{$google_analytics_account};	
	$googleanalytics{$j."/".$google_analytics_account{varvalue}} = $google_analytics_account{varvalue};
	$j++;
} 

my $cpt = 5;
my $tab = 1;
my $prefixe = '';
my $fn=0;

my $hidden_mailing_conditions_cases = 1;
my $hidden_mailing_conditions_dates = 1;

if($config{enable_mailing_conditions_cases} eq 'y')
{
	$hidden_mailing_conditions_cases = 0;
}
if($config{enable_mailing_conditions_dates} eq 'y')
{
	$hidden_mailing_conditions_dates = 0;
}



%dm_dfl = (
		
	
		sprintf("%03d", $cpt++).'/titre'=> 
		{
	        'title'=>'Paramètres de newsletter',
	        'fieldtype'=>'titre',
	    }
		,
		sprintf("%03d", $cpt++).'/mailing_from'=> 
		{
	        'title'=>$migctrad{mailing_from},
	        'fieldtype'=>'text',
			'default_value'=>$migcms_page{mailing_from},
	        'hidden' => 0,
			'legend'=>$migctrad{mailing_from_txt},
	    }
		,
		sprintf("%03d", $cpt++).'/mailing_from_email'=> 
		{
	        'title'=>$migctrad{mailing_from_email},
	        'fieldtype'=>'text',
	        'data_type'=>'email',
			'default_value'=>$migcms_page{mailing_from_email},
	        'mandatory'=>{"type" => 'not_empty'},							
	        'hidden' => 0,
	    }
		,
		sprintf("%03d", $cpt++).'/mailing_object'=> 
		{
	        'title'=>$migctrad{mailing_object},
	        'fieldtype'=>'text',
			'default_value'=>$migcms_page{mailing_object},
	        'mandatory'=>{"type" => 'not_empty'},									
	        'hidden' => 0,
			'legend'=>$migctrad{mailing_object_txt},
	    }
		,
		sprintf("%03d", $cpt++).'/mailing_name'=> 
		{
	        'title'=>$migctrad{mailing_name},
	        'fieldtype'=>'text',
			'default_value'=>$migcms_page{mailing_name},
	        'mandatory'=>{"type" => 'not_empty'},									
	        'hidden' => 1,
	    }
		,
		sprintf("%03d", $cpt++).'/id_migcms_page'=> 
		{
	        'title'=>'ID PAGE',
	        'fieldtype'=>'text',
	        'hidden' => 1,
			'default_value'=>$migcms_page{id},
	    }
		,
		sprintf("%03d", $cpt++).'/queued_time'=> 
		{
	        'title'=>'Queued time',
	        'fieldtype'=>'text',
	        'data_type'=>'datetime',
	        'hidden' => 1,
	    }
		,
		sprintf("%03d", $cpt++).'/start_time'=> 
		{
	        'title'=>'Start time',
	        'fieldtype'=>'text',
	        'data_type'=>'datetime',
	        'hidden' => 1,
	    }
		,
		sprintf("%03d", $cpt++).'/end_time'=> 
		{
	        'title'=>'End time',
	        'fieldtype'=>'text',
	        'data_type'=>'datetime',
	        'hidden' => 1,
	    }
		,
		sprintf("%03d", $cpt++).'/planned_time'=> 
		{
	        'title'=>$migctrad{mailing_planneddatetime},
	        'fieldtype'=>'text',
			# 'default_value'=>$now,
	        'data_type'=>'datetime',
			# 'maintenant'=>'y',
	        # 'mandatory'=>{"type" => 'not_empty'},							
	        'hidden' => 0,
	    }
		,
      sprintf("%03d", $cpt++).'/status'=> 
      {
	        'title'=>'Statut',
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%status,
	        'default_value'=>'new',
	        'search' => 'y',
			'hidden'=>1,

	    }
		,
		sprintf("%03d", $cpt++).'/nb_sent'=> 
		{
	        'title'=>'Nb envois',
	        'fieldtype'=>'display',
	        'hidden' => 1,
	    }
		,
		sprintf("%03d", $cpt++).'/nb_open'=> 
		{
	        'title'=>'Nb ouverts',
	        'fieldtype'=>'display',
	        'hidden' => 1,
	    }
		,
		sprintf("%03d", $cpt++).'/nb_click'=> 
		{
	        'title'=>'Nb clickés',
	        'fieldtype'=>'display',
	        'hidden' => 1,
	    }
,
		sprintf("%03d", $cpt++).'/nb_open'=> 
		{
	        'title'=>'Nb ouverts',
	        'fieldtype'=>'display',
	        'hidden' => 1,
	    }
		,
		sprintf("%03d", $cpt++).'/nb_click'=> 
		{
	        'title'=>'Nb clickés',
	        'fieldtype'=>'display',
	        'hidden' => 1,
	    }			
		,
		sprintf("%03d", $cpt++).'/nb_erreurs'=> 
		{
	        'title'=>'Nb erreurs',
	        'fieldtype'=>'display',
	        'hidden' => 1,
	    }
		,
		sprintf("%03d", $cpt++).'/nb_desinscriptions'=> 
		{
	        'title'=>'Nb désinscriptions',
	        'fieldtype'=>'display',
	        'hidden' => 1,
	    }
		
		,
		sprintf("%03d", $cpt++).'/mailing_include_pics'=> 
		{
	       'title'=>$migctrad{mailing_include_photos},
	       'fieldtype'=>'text',
			'default_value'=>$migcms_page{mailing_include_pics},
	       'hidden' => 1,
	    }	
		,
		sprintf("%03d", $cpt++).'/mailing_headers'=> 
		{
	       'title'=>$migctrad{mailing_headers},
	       'fieldtype'=>'text',
			'default_value'=>$migcms_page{mailing_headers},
	       'hidden' => 1,
	    }
		,
		sprintf("%03d", $cpt++).'/titre'=> 
		{
	        'title'=>'Destinaires',
	        'fieldtype'=>'titre',
	    }
		,
		sprintf("%03d", $cpt++).'/ajout_pas_recu_cette_nl' => 
		{
		'title'=>'Inclure les adresses emails de ceux qui n\'ont pas reçu <b>cette</b> newsletter.',
		'fieldtype'=>'checkbox',
		'hidden'=>$hidden_mailing_conditions_cases,
		}
		,
		sprintf("%03d", $cpt++).'/ajout_pas_recu_aucune_nl' => 
		{
		'title'=>'Inclure les adresses emails de ceux qui n\'ont reçu <b>aucune</b> newsletter.',
		'fieldtype'=>'checkbox',
		'hidden'=>$hidden_mailing_conditions_cases,
		}
		,
		sprintf("%03d", $cpt++).'/ouvert_depuis' => 
		{
		'title'=>'Inclure les adresses emails de ceux qui ont ouvert depuis...',
		'fieldtype'=>'text',
		'data_type'=>'date',
		'hidden'=>$hidden_mailing_conditions_dates,
		}
		,
		sprintf("%03d", $cpt++).'/click_depuis' => 
		{
		'title'=>'Inclure les adresses emails de ceux qui ont cliqués depuis...',
		'fieldtype'=>'text',
		'data_type'=>'date',
		'hidden'=>$hidden_mailing_conditions_dates,
		}
		,
		sprintf("%03d", $cpt++).'/tags'=> 
		{
			'title'=>'Inclure les adresses emails de ceux qui correspondent aux segments',
			'fieldtype'=>'listboxtable',
			'lbtable'=>'migcms_members_tags',
			'data_type'=>'button',
			'data_split'=>'type',
			'multiple'=>1,
			'lbkey'=>'id',
			'lbdisplay'=>"name",
			'lbwhere'=>"visible='y' And type != 'Raison du départ'" ,
			'search' => 'n',
			'legend'=>$migctrad{mailing_tags_txt},
        }
		,
		sprintf("%03d", $cpt++).'/titre'=> 
		{
	        'title'=>'TEST',
	        'fieldtype'=>'titre',
	    }
		,
		sprintf("%03d", $cpt++).'/mode_test' => 
		{
			'title'=>'Mode test (Limiter à 10 emails)',
			'fieldtype'=>'checkbox',
			'legend'=>"Une newsletter en mode TEST ne sera pas facturée. Le mot TEST sera ajouté à l'objet de l'email.",
		}
		,

		
	);
	
# if($config{enable_mailing_conditions_cases} ne 'y')
# {
	# delete $dm_dfl{'00270/ajout_pas_recu_cette_nl'};
	# delete $dm_dfl{'00280/ajout_pas_recu_aucune_nl'};
# }
# if($config{enable_mailing_conditions_dates} ne 'y')
# {
	# delete $dm_dfl{'00290/ouvert_depuis'};
	# delete $dm_dfl{'00300/click_depuis'};
# }

	%dm_display_fields = 
	(
		"01/Date"=>"migcms_moment_create",
		#"02/$migctrad{mailing_from}"=>"mailing_from",
		"03/$migctrad{mailing_object}"=>"mailing_object",
		# "04/Destinaires"=>"tags",
		"05/Envois"=>"nb_sent",
		"06/Ouvertures"=>"nb_open",
		"07/Clics"=>"nb_click",
	);

%dm_lnk_fields = 
(
# "10/Mode test/mode_test"=>"modetest*",
"02/Expéditeur"=>"sender*",
"98/Etat/statut"=>"status*",
"99//"=>"stats*",
);

%dm_mapping_list = (
"modetest" => \&get_mode,
"status" => \&get_status,
"stats" => \&get_stats,
"sender" => \&get_sender,
);

	%dm_filters = (
	);
	

	
$dm_cfg{list_html_top} =<<"EOH";
<style type="text/css">
	.widget-header-actions, .list_action { display : none !important; }
</style>
<script type="text/javascript">

jQuery(document).ready(function() {

	jQuery(document).on("change", "#field_mode_test", compute_nb_members_from_tags);
	var back_button_bottom = '<a class="btn btn-lg btn-link" aria-hidden="true" href="$config{baseurl}/cgi-bin/adm_migcms_pages_newsletters.pl?sel=$sel"><i class="fa fa-arrow-left" data-original-title="" title=""></i> Retour</a>';
	jQuery(".col-md-6.text-right").html("");
	jQuery(".col-md-12.text-right").prepend(back_button_bottom);
	
	custom_func_list();
	custom_func_form_sendings();
	
	jQuery(".text-right .btn-success").html("Oui, je confirme l'envoi");
	var mailing_page_id = jQuery("#field_id_migcms_page").val();
	
	var mailing_credits = '$config{mailing_credits}';
	var mailing_mail_tester_com = '<span style="color:#ce5454;">Pour tester l\\'indésirabilité (spam) de vos emails, vous pouvez générer une adresse email de TEST sur <a href="https://www.mail-tester.com/" target="_blank" style="color:#ce5454;"><strong>www.mail-tester.com</strong></a>, afin d\\'obtenir un rapport.</span><br /><br />';
	if(mailing_credits != "") {
		var mailing_credits_content = '<br /><br /><div class="credits_restants"><h4>Crédits restants :</strong> '+mailing_credits+' (après envoi : <span class="nb_credits_after_send">...</span>)</div><div class="credits_restants_msg hide"><h4><strong>Crédits insuffisants pour effectuer l´envoi (Reste : '+mailing_credits+')</strong></h4></div>';
		
		var alert_info = '<div class="col-md-12 text-right"><div class="alert alert-info"><h4>Désirez vous envoyer <b class="nb_membres">...</b> email(s), avec pour contenu <a href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page='+mailing_page_id+'&mailing=y&lg=1" target="_blank" style="color:#31708f;text-decoration:underline;">cette page ?</a></h4>Temps nécessaire pour envoyer tous les emails : <b class="nb_min">...</b> (donnée aproximative dépendant de la disponibilité des serveurs)'+mailing_credits_content+'</div>'+mailing_mail_tester_com+'</div>';
	}
	else {
		var alert_info = '<div class="col-md-12 text-right"><div class="alert alert-info"><h4>Désirez vous envoyer <b class="nb_membres">...</b> email(s), avec pour contenu <a href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page='+mailing_page_id+'&mailing=y&lg=1" target="_blank" style="color:#31708f;text-decoration:underline;">cette page ?</a></h4>Temps nécessaire pour envoyer tous les emails : <b class="nb_min">...</b> (donnée aproximative dépendant de la disponibilité des serveurs)</div>'+mailing_mail_tester_com+'</div>';
	}
	
	
	jQuery(".col-md-12.text-right").parent(".row").prepend(alert_info);  
	//console.log('end');
	
	
	// UPDATE status (AJAX)
	jQuery(".update_status_ajax, .update_plannedstatus_ajax-btn").click(function() {
				
		var action = jQuery(this).attr("href");
		action = action.replace("#","");
		action = action.split("-");
		
		if(action[0] != 'update') {
			var wait_msg = '<i class="fa fa-spinner fa-pulse fa-fw"></i>';
			jQuery(this).replaceWith(wait_msg);
		}
		
		//alert(action[0]);
		//alert(action[1]);
		
		var id = action[1];
		var new_datetime = "";
			
		if(action[0] == 'update') {
			new_datetime = jQuery("#new_datetime_"+id).val();
			//new_datetime = new_datetime.replace("/",-");
			jQuery('#modal-'+id).modal('hide');
		}
		
		var url_request = '$config{baseurl}/cgi-bin/adm_migcms_mailings_sendings_update_status.pl?sel=$sel&sw='+action[0]+'&id_sending='+action[1]+'&planned='+new_datetime;
		
		
		///console.log(url_request);
		
		var request = jQuery.ajax(
		{
			url: url_request,
			dataType: "html",
			success: function(msg)
			{
				//alert(msg);
				var msg_planned = msg.split("|");
				if(msg == "stop") {
					var msg_cancel = '<div class="alert alert-danger text-center" id="alert-'+id+'" style="padding:0px 5px;"><strong>Envoi annulé</strong></div>';
					//alert(msg_cancel);
					jQuery("#alert-"+id).replaceWith(msg_cancel);
				}
				else if(msg_planned[0] == "planned") {
					//var msg_planned = '<div class="alert alert-info text-center" id="alert-'+id+'" style="padding:0px 5px;"><strong>Envoi planifié</strong> le '+msg_planned[1]+'<br /><a href="#update-'+id+'" class="update_status_ajax">Modifier</a> - <a href="#stop-'+id+'" class="update_status_ajax">Annuler</a></div>';
					var msg_planned = '<div class="alert alert-info text-center" id="alert-'+id+'" style="padding:0px 5px;"><strong>Envoi planifié</strong> le '+msg_planned[1]+'</div>';
					//alert(msg_planned);
					jQuery("#alert-"+id).replaceWith(msg_planned);
				}
				else if(msg == "current") {
					var msg_current = '<div class="alert alert-warning text-center" id="alert-'+id+'" style="padding:0px 5px;"><strong>Envoi en cours</strong></div>';
					//alert(msg_current);
					jQuery("#alert-"+id).replaceWith(msg_current);
				}
				else {
					swal({
						title: "Erreur!",
						text: "Erreur inconnue. Réessayez!",
						type: "error",
						confirmButtonText: "Fermer"
					});
				}
			}
		});
		
		return false;
	});
});

function custom_func_form_sendings()
{
	console.log('custom_func_form_sendings');
	var nb = 0;
	compute_nb_members_from_tags();
	
	jQuery(document).on("change", ".field_tags", compute_nb_members_from_tags);
	
}

function custom_func_list()
{
	jQuery('.list_actions_2').removeClass('list_actions_2').addClass('list_actions_1');
}


function compute_nb_members_from_tags()
{
	console.log(jQuery(this).attr('name'));
	var tags = jQuery('.field_tags').val();
	jQuery('.nb_membres').html('...');
	jQuery('.nb_min').html('...');
	var id_migcms_page = jQuery('.parametre_url_id_migcms_page').val();
	
	jQuery.ajax(
	{
	   type: "POST",
	   url: '$dm_cfg{self}',
	   data: "sw=compute_nb_members_from_tags&tags="+tags+"&id_migcms_page="+id_migcms_page+"&mailing_basehref="+jQuery(".parametre_url_mailing_basehref").val()+"&mode_test="+jQuery("#field_mode_test:checked").val(),
	   success: function(msg)
	   {
			
			var tab_contenu = msg.split("_");
			jQuery('.nb_membres').html(tab_contenu[0]);
			
			var mailing_credits = '$config{mailing_credits}';
			if(mailing_credits != "") {
				mailing_credits = Number(mailing_credits);
				var total_send = tab_contenu[0];

				if((total_send > mailing_credits) && jQuery('#field_mode_test').prop('checked')==false) {
					jQuery(".col-md-12.text-right").find(".credits_restants").addClass("hide");
					jQuery(".col-md-12.text-right").find(".credits_restants_msg").removeClass("hide");
					jQuery(".col-md-12.text-right").find(".alert-info").removeClass("alert-info").addClass("alert-danger");
					jQuery('.admin_edit_save').hide();
				}
				else {
					jQuery(".col-md-12.text-right").find(".credits_restants").removeClass("hide");
					jQuery(".col-md-12.text-right").find(".credits_restants_msg").addClass("hide");
					jQuery(".col-md-12.text-right").find(".alert-danger").removeClass("alert-danger").addClass("alert-info");
					var mailing_new_credits = mailing_credits-total_send;
					jQuery('.nb_credits_after_send').html(mailing_new_credits);
					if(tab_contenu[0] > 0)
					{
						jQuery('.admin_edit_save').show();
					}
					else
					{
						jQuery('.admin_edit_save').hide();
					}
				}
			}
			else {
				if(tab_contenu[0] > 0)
				{
					jQuery('.admin_edit_save').show();
				}
				else
				{
					jQuery('.admin_edit_save').hide();
				}
			}
				
			jQuery('.nb_min').html(tab_contenu[1]);
				 
	   }
	});
	
	
}
</script>
<style>
  /*.list_ordby,.row_actions_globales,td.td-input,.mig_cb_col,.maintitle,.cancel_edit,.dm_migedit*/
  .list_ordby,.row_actions_globales,td.td-input,.mig_cb_col,.maintitle,.cancel_edit
	 {
		display:none!important;
	 }
</style>
EOH

$sw = $cgi->param('sw') || "list";
if($sw ne 'prepare_form_db')
{
see();
}

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			compute_nb_members_from_tags
			del_db
		);

if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}

sub compute_nb_members_from_tags
{
	my %d = %{$_[0]};

	my $id_member_rule = $d{id_member_rule} || get_quoted('id_member_rule');
	my $variable_a = $d{variable_a} || get_quoted('variable_a');
	my $variable_b = $d{variable_b} || get_quoted('variable_b');
	
	my $tags = $d{tags} || get_quoted('tags');
	my $groupes = $d{groupes} || get_quoted('groupes');
	my $emails_test = $d{emails_test} || get_quoted('emails_test');
	my $tag_interdit = $d{tag_interdit} || get_quoted('tag_interdit');
	my $mailing_basehref = $d{mailing_basehref} || get_quoted('mailing_basehref');
	my $id_migcms_page = $d{id_migcms_page} || get_quoted('id_migcms_page');
	
	my %rec_config = read_table($dbh,'config',$mailing_basehref);
	my $basehref = $rec_config{varvalue}; 
	$basehref = $1 if($basehref=~/(.*)\/$/); #retire le dernier slash
	my $num_optout = '';
	if($config{'optout_for_base_href_'.$basehref} > 0)
	{
		 $num_optout = '2';
	}

	my %migcms_page = sql_line({table=>'migcms_pages',where=>"id='$id_migcms_page'"});
	my $where = mailing::mailing_get_where_member({id_migcms_page=>$id_migcms_page,id_member_rule=>$id_member_rule,variable_a=>$variable_a,variable_b=>$variable_b,tags=>$tags,groupes=>$groupes,tag_interdit=>$tag_interdit,emails_test=>$emails_test,num_optout=>$num_optout});

	my %migcms_members = sql_line({debug=>0,debug_results=>0,table=>'migcms_members',select=>"COUNT(DISTINCT(email)) as nb",where=>$where});
	if($migcms_members{nb} > 0)
	{
	}
	else
	{
		$migcms_members{nb} = 0;
	}
	
	my $mode_test = get_quoted('mode_test');
	if($mode_test eq 'y' && $migcms_members{nb} > 10)
	{
		$migcms_members{nb} = 10;
	}
	
	my $duree = '-';
	if($migcms_members{nb} > 0)
	{
		my $nb_sec =$migcms_members{nb}; #un email par seconde
		if($migcms_page{mailing_include_pics} ne 'y')
		{
			$nb_sec /= 3; #3 semails par seconde
		}
		$duree = convert_seconds_to_hhmmss($nb_sec);		
	}	
	
	if($_[0] ne '')
	{
		return $migcms_members{nb};
	}
	else
	{
		print $migcms_members{nb}.'_'.$duree;
		exit;
	}
}

 sub convert_seconds_to_hhmmss 
 {

  my $hourz=int($_[0]/3600);

  my $leftover=$_[0] % 3600;

  my $minz=int($leftover/60);

  my $secz=int($leftover % 60)+1;

  return sprintf ("%dh %dmin %dsec", $hourz,$minz,$secz);
}

sub after_add
{
	# my $dbh=$_[0];
	my $id=$_[1];
	
	#créer le contenu du mail et son statut
	my %sending = read_table($dbh,$dm_cfg{table_name},$id);
	my %migcms_page = read_table($dbh,'migcms_pages',$sending{id_migcms_page});
	$migcms_page{mailing_alt_html} = trim($migcms_page{mailing_alt_html});
	
	my $mailing_content = '';
	
	if($migcms_page{mailing_alt_html} ne '')
	{
		$mailing_content = $migcms_page{mailing_alt_html};
	}
	elsif($migcms_page{id_tpl_page} > 0)
	{
		$mailing_content = migcrender::render_page({full_url=>1,mailing=>'y',debug=>0,id=>$migcms_page{id},lg=>$config{current_language},preview=>'n',edit=>'n'});
	}
		
	$mailing_content =~ s/\'/\\\'/g;
	$mailing_content =~ s/\&amp;/\&/g;
	
	my $status = "new";
	if($sending{planned_time} ne "0000-00-00 00:00:00" && $sending{planned_time} ne '')
	{
		$status = "planned";
	}
	
	if($migcms_page{mailing_googleanalytics} > 0)
	{
		my %rec_config = read_table($dbh,'config',$migcms_page{mailing_googleanalytics});
		$migcms_page{mailing_googleanalytics} = $rec_config{varvalue};
	}
	if($migcms_page{mailing_basehref} > 0)
	{
		my %rec_config = read_table($dbh,'config',$migcms_page{mailing_basehref});
		$migcms_page{mailing_basehref} = $rec_config{varvalue};
	}	
	$stmt = "UPDATE $dm_cfg{table_name} SET status='$status', googleanalytics = '$migcms_page{mailing_googleanalytics}', basehref = '$migcms_page{mailing_basehref}', mailing_content = '$mailing_content' WHERE id = $sending{id}";
	execstmt($dbh,$stmt);

	my $mailing_basehref = get_quoted('mailing_basehref');
		
	my $nb_membres_a_decompter = compute_nb_members_from_tags({tags=>$sending{tags},groupes=>$sending{groupes},emails_test=>$sending{emails_test},mailing_basehref=>$mailing_basehref,id_migcms_page=>$sending{id_migcms_page}});

	log_debug('Decompte de '.$nb_membres_a_decompter.' credits:','','credits_mailing');
	if($nb_membres_a_decompter > 0)
	{
		$stmt = "UPDATE config SET varvalue = (varvalue - $nb_membres_a_decompter) WHERE varname = 'mailing_credits'";
		log_debug($stmt,'','credits_mailing');
		execstmt($dbh,$stmt);
	}
}

sub get_mode
{
	my $dbh = $_[0];
    my $id = $_[1];
	
	my %sending = sql_line({table=>'mailing_sendings',where=>"id='$id'"});
	my $mode = $sending{mode_test};
	
	if($mode eq 'y') {
		return "Oui";
	}
	else {
		return "Non";
	}
}

sub get_status
{
    my $dbh = $_[0];
    my $id = $_[1];
 
    my %mailing = sql_line({debug=>0,dbh=>$dbh_send, table=>"mailings", where=>"id_nl = '$id' AND dbname='$config{db_name}'"});
    my $content = $mailing{status};
	

    # Une date d'envoi est prévue => on prévoit d'annuler ou de modifier la date
    if($mailing{status} eq "planned")
    {
		my %mailing_sending = sql_line({debug=>0,dbh=>$dbh, table=>"mailing_sendings", where=>"id='$id'"});
		my $pageid = $mailing_sending{id_migcms_page};
 
        my $lnk_update = "#update-".$id;
        my $lnk_stop = "#stop-".$id;
		my $datetime = $mailing{planned_time};
 
		my ($date,$time) = split (/ /,$mailing{planned_time});
        $mailing{planned_time} = sql_to_human_date($date).' '.sql_to_human_time($time,'h');
 
        $content = <<"EOH";
<div class="alert alert-info text-center" id="alert-$id" style="padding:0px 5px;"><strong>Envoi planifié</strong> le $mailing{planned_time}<br /><a href="$lnk_update" class="update_plannedstatus_ajax" data-toggle="modal" data-target="#modal-$id">Modifier</a> - <a href="$lnk_stop" class="update_status_ajax">Annuler</a></div>
<!-- Modal -->
<div class="modal fade" id="modal-$id" tabindex="-1" role="dialog" aria-labelledby="modalLabel-$id">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <h4 class="modal-title" id="modalLabel-$id">Modifier l'envoi planifié</h4>
      </div>
      <div class="modal-body">
		<form class="form-horizontal">
          <div class="form-group">
            <label for="new_datetime-name" class="col-sm-4 control-label">$migctrad{mailing_planneddatetime}</label>
			<div class="col-sm-8 mig_cms_value_col">
				<input type="text" class="form-control datetimepicker" id="new_datetime_$id" name="new_datetime_$id" value="$mailing{planned_time}">
			</div>
          </div>
		  <!--<div class="form-group">
            <label for="new_datetime-name" class="col-sm-4 control-label">$migctrad{mailing_object}</label>
			<div class="col-sm-8 mig_cms_value_col">
				<input type="text" class="form-control" id="new_object" name="new_object" value="$mailing{subject}">
			</div>
          </div>
		  <div class="form-group">
            <label for="new_datetime-name" class="col-sm-4 control-label">Mise à jour du contenu (<a href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page=$pageid&mailing=y&lg=1" target="_blank">Newsletter</a>)</label>
			<div class="col-sm-8 mig_cms_value_col">
				<div class="radio">
				  <label>
					<input type="radio" name="updatecontent" id="updatecontent" value="yes">
					Oui
				  </label>
				</div>
				<div class="radio">
				  <label>
					<input type="radio" name="updatecontent" id="updatecontent" value="no" checked>
					Non
				  </label>
				</div>
			</div>
          </div>-->
        </form>
      </div>
      <div class="modal-footer">
        <a href="#update-$id" class="btn btn-primary update_plannedstatus_ajax-btn" id="update-$id">Sauvegarder</a>
      </div>
    </div>
  </div>
</div>
EOH
    }
	elsif($mailing{status} eq "current" || $mailing{status} eq "started")
    {
 
        my $lnk_stop = "#stop-".$id;
				
		my %total_queue = sql_line({debug=>0,dbh=>$dbh_send, table=>"queue", select=>"COUNT(to_email) as total_email", where=>"id_mailing=$mailing{id}"});
		my $total_email = $total_queue{total_email};
		
		my $send_progress = int(($mailing{nbsent} / $total_email) * 100);
 
        $content = <<"EOH";
<div class="alert alert-warning text-center"  id="alert-$id" style="padding:0px 5px;"><strong>Envoi en cours</strong> ($send_progress %)<br /><a href="$lnk_stop" class="update_status_ajax">Arrêter</a></div>
EOH
    }
    elsif($mailing{status} eq "aborted")
    {
        my $lnk_activate = "#restart-".$id;
		
        $content = <<"EOH";
<div class="alert alert-danger text-center"  id="alert-$id" style="padding:0px 5px;"><strong>Envoi annulé</strong><br /><a href="$lnk_activate" class="update_status_ajax">Reprendre</a></div>
EOH
    }
    elsif($mailing{status} eq "ended")
    {
		my ($date,$time) = split (/ /,$mailing{end_time});
        $mailing{end_time} = sql_to_human_date($date).' '.sql_to_human_time($time,'h');
        $content = <<"EOH";
<div class="alert alert-success text-center" id="alert-$id" style="padding:0px 5px;"><strong>Envoyée</strong> le $mailing{end_time}</div>
EOH
    }
	else {
        $content = <<"EOH";
Préparation en cours
EOH
    }
 
 
    return $content;
}

sub get_stats
{
	my $dbh = $_[0];
    my $id = $_[1];
	$script_rec{id} = get_quoted('sel');
	my $url = 'adm_migcms_dashboard.pl?mailing=y&id_dashboard=4&id_sending='.$id.'&sel='.$script_rec{id};
	
	my $acces = <<"EOH";
		<a class="btn btn-default" href="$url" data-original-title="Statistiques de la newsletter" data-placement="bottom">
			<i class="fa fa-bar-chart" aria-hidden="true"></i>
		</a>
EOH

	return $acces;
}


sub compute_mailing_short_stats
{
	see();
	log_debug('Commence','vide','migcms_mailing_short');
	log_debug('Commence','vide','migcms_mailing_short_stats_sent');
	log_debug('Commence','vide','migcms_mailing_short_stats_open');
	log_debug('Commence','vide','migcms_mailing_short_stats_click');

	my $stmt = "TRUNCATE migcms_mailing_short_stats";
	execstmt($dbh,$stmt);
	
	my $limit = "0,5000000";
	log_debug($limit,'','migcms_mailing_short');
	
	#cache email -> id membre
	my @members = sql_lines({debug=>0,table=>"migcms_members",select=>'id,email,tags'});
	my %cache_members = ();
	foreach $member (@members)
	{
		my %member = %{$member};
		$cache_members{lc(trim($member{email}))} = $member{id};
	}
	my %migcms_mailing_short_stats_sent = ();
	my %migcms_mailing_short_stats_open = ();
	my %migcms_mailing_short_stats_click = ();
	
	#cache id_mailing mailer -> id_nl (sending local)
	my @mailings_mailers = sql_lines({dbh=>$dbh_send,debug=>0,table=>"mailings",select=>'id,id_nl',where=>"dbname = 'DBI:mysql:energiesplus'"});
	my %cache_mailings_mailer = ();
	foreach $mailings_mailer (@mailings_mailers)
	{
		my %mailings_mailer = %{$mailings_mailer};
		$cache_mailings_mailer{$mailings_mailer{id}} = $mailings_mailer{id_nl};
	}
	log_debug('cache 1 ok','','migcms_mailing_short');
	
	#cache id_sending -> id_migcms_page
	my @mailing_sendings = sql_lines({dbh=>$dbh,debug=>0,table=>"mailing_sendings",select=>'id,id_migcms_page',where=>""});
	my %cache_id_migcms_page = ();
	foreach $mailing_sending (@mailing_sendings)
	{
		my %mailing_sending = %{$mailing_sending};
		$cache_id_migcms_page{$mailing_sending{id}} = $mailing_sending{id_migcms_page};
	}
	log_debug('cache 2 ok','','migcms_mailing_short');
	
	my $i = 0;
	foreach $mailings_mailer (@mailings_mailers)
	{
		my %mailings_mailer = %{$mailings_mailer};
		log_debug('mailings: '.$i.'/'.$#mailings_mailers.':'.$mailings_mailer{id},'','migcms_mailing_short');

		#queues 
		my @queues = sql_lines({dbh=>$dbh_send,debug=>0,table=>"queue",select=>'to_email,status',where=>"id_mailing = '$mailings_mailer{id}'",limit=>$limit});
		foreach $queue (@queues)
		{
			my %queue = %{$queue};
			my $id_migcms_member = $cache_members{lc(trim($queue{to_email}))};
			my $id_migcms_page = $cache_id_migcms_page{$cache_mailings_mailer{$mailings_mailer{id}}};			
			my $key = $id_migcms_member.'_'.$id_migcms_page;
			if($queue{status} eq 'sent')
			{
				$migcms_mailing_short_stats_sent{$key} = 1;
			}
		}
		log_debug('queue ok','','migcms_mailing_short');
		
		#open, click 
		my @stats = sql_lines({dbh=>$dbh_send,debug=>0,table=>"stats",select=>'email,op',where=>"id_mailing = '$mailings_mailer{id}'",limit=>$limit});
		foreach $stat (@stats)
		{
			my %stat = %{$stat};
			my $id_migcms_member = $cache_members{lc(trim($stat{email}))};
			my $id_migcms_page = $cache_id_migcms_page{$cache_mailings_mailer{$mailings_mailer{id}}};			
			my $key = $id_migcms_member.'_'.$id_migcms_page;
			if($stat{op} eq 'open')
			{
				$migcms_mailing_short_stats_open{$key} = 1;
			}
			if($stat{op} eq 'click')
			{
				$migcms_mailing_short_stats_click{$key} = 1;
			}
		}	
		log_debug('stats ok','','migcms_mailing_short');
		$i++;
	}
	log_debug('hashes ok','','migcms_mailing_short');
	
	foreach my $key (keys %migcms_mailing_short_stats_sent)
	{
		my ($id_migcms_member,$id_migcms_page) = split (/\_/,$key);
		
		my %new_migcms_mailing_short_stat =
		(
			id_migcms_member => $id_migcms_member,
			id_migcms_page => $id_migcms_page,
			sent => $migcms_mailing_short_stats_sent{$key},
			open => $migcms_mailing_short_stats_open{$key},
			click => $migcms_mailing_short_stats_click{$key},	
		);	
		inserth_db($dbh,'migcms_mailing_short_stats',\%new_migcms_mailing_short_stat);
	}
	log_debug('insert terminés','','migcms_mailing_short');
	
	use Data::Dumper;
	log_debug(Dumper(\%migcms_mailing_short_stats_sent),'','migcms_mailing_short_stats_sent');
	log_debug(Dumper(\%migcms_mailing_short_stats_open),'','migcms_mailing_short_stats_open');
	log_debug(Dumper(\%migcms_mailing_short_stats_click),'','migcms_mailing_short_stats_click');
	
	exit;
}

sub test_make_stat_sent_mailing
{
	see();
	my %nb_evt_per_member = ();
	log_debug('','vide','test_make_stat_sent_mailing');
	my $i =0;
	my @migcms_members_events = sql_lines({select=>'id_member',table=>'migcms_members_events',where=>"type_evt='sent_mailing'"});
	foreach $migcms_members_event (@migcms_members_events)
	{
		my %migcms_members_event = %{$migcms_members_event};
		log_debug($i.'/'.$#migcms_members_events,'','test_make_stat_sent_mailing');
		if($nb_evt_per_member{$migcms_members_event{id_member}} > 0)
		{
			$nb_evt_per_member{$migcms_members_event{id_member}}++;
		}
		else
		{
			$nb_evt_per_member{$migcms_members_event{id_member}} = 1;
		}
		$i++;
	}
	my $i =0;
	my @arr = keys(%nb_evt_per_member);
	
	foreach my $id_member(@arr)
	{
		my $nb = $nb_evt_per_member{$id_member};
		my $stmt = "UPDATE migcms_members SET stat_sent_mailing='$nb' WHERE id = $id_member";
		execstmt($dbh,$stmt);	
		# log_debug($stmt,'','test_make_stat_sent_mailing');
		log_debug('upd '.$i.'/'.$#arr.' '.$nb,'','test_make_stat_sent_mailing');
		$i++;
	}
	exit;
}

sub prepare_form
{
	see();
	
	my $liste_dirs = '<table class="table table-striped table-hover">';
	my $liste_segments = '<table class="table table-striped table-hover">';
	my $liste_regles = '<table class="table table-striped table-hover">';
	my $aucun_groupe_dossier = 1;
	my $aucun_groupe = 1;
	my $aucun_segment = 1;
	my $aucune_regle = 1;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year+=1900;	
	$mon++;	
	
	my $date = $mday.'/'.$mon.'/'.$year;
	my $heure = $hour.'h'.$min;
	
	my %nb_tags_calc = sql_line({select=>"COUNT(*) as nb",table=>'migcms_members_tags'});
	my $nb_tags = $nb_tags_calc{nb};
	my $NB_LIMIT_TAGS_FOR_PREVIEW = 15;

	my %this_script = sql_line({select=>"id",table=>"scripts",where=>"url LIKE '%adm_migcms_mailings_sendings%'"});
	my $this_sel = $this_script{id};
		
	my @migcms_member_dirs = sql_lines({table=>'migcms_member_dirs',where=>"visible='y' AND name != ''",ordby=>"name"});
	foreach $migcms_member_dir (@migcms_member_dirs)
	{
		my %migcms_member_dir = %{$migcms_member_dir};
		my $liste_groupes = '<table class="table table-striped table-hover">';
		$aucun_groupe_dossier = 1;
		
		my @migcms_members_tags = sql_lines({table=>'migcms_members_tags',where=>"id_migcms_member_dir='$migcms_member_dir{id}' AND visible='y' AND name != ''",ordby=>"name"});
		foreach $migcms_members_tag (@migcms_members_tags)
		{
			my %migcms_members_tag = %{$migcms_members_tag};
			
			my $nb2 = 0;
			my $nb_preview = '';
			if($nb_tags < $NB_LIMIT_TAGS_FOR_PREVIEW)
			{
				$nb2 = compute_nb_members_from_tags({tags=>','.$migcms_members_tag{id}.','});
				$nb_preview = " <span class=\"badge\">$nb2</span> ";
				if($nb2 == 0)
				{
					next;
				}
			}
			
			$aucun_groupe = 0;
			$aucun_groupe_dossier = 0;
			$liste_groupes .= <<"EOH";
			<tr><td>
					<label><input type="checkbox" class="reset_field compute_nb groupecb" id="$migcms_members_tag{id}" name="groupe_$migcms_members_tag{id}" value="y" /> $migcms_members_tag{name} $nb_preview</label><br />				
			</td></tr>
EOH
			
		}
		$liste_groupes .= '</table>';
		
		if($#migcms_members_tags == -1 || $aucun_groupe_dossier)
		{
			next;
		}
		
		$liste_dirs .= <<"EOH";
			<tr><td>
				
					<i class="fa fa-plus-square-o" aria-hidden="true"></i>
					<i class="hide fa fa-minus-square-o" aria-hidden="true"></i>
					<a class="deplie_groupes" style="cursor:pointer;">$migcms_member_dir{name}</a>
					<div class="groupes hide">$liste_groupes</div>
				
			</td></tr>
EOH
	}
	$liste_dirs .= '</table>';
	
	#SEGEMENTS
	my @migcms_member_segments = sql_lines({table=>'migcms_member_segments',where=>"visible='y' AND name != ''",ordby=>"name"});
	$liste_segments .= <<"EOH";
		<tr><td>
				<label><input type="radio" name="id_segment" value="0"  class="reset_field compute_nb id_segment" /> Aucun </label><br />				
		</td></tr>
EOH
	foreach $migcms_member_segment (@migcms_member_segments)
	{
		my %migcms_member_segment = %{$migcms_member_segment};
		my $liste_groupes = '<table class="table table-striped table-hover">';
		$aucun_segment = 0;

		
		
		# my $nb = compute_nb_members_from_tags({tags=>$migcms_member_segment{fusion}});

		
		
		$liste_segments .= <<"EOH";
		<tr><td>
				<label><input type="radio" name="id_segment" rel="$migcms_member_segment{fusion}" value="$migcms_member_segment{id}" class="reset_field compute_nb id_segment" /> $migcms_member_segment{name} <span class="badge hide">$nb</span></label><br />				
		</td></tr>
EOH
	}
	$liste_segments .= '</table>';
	
	#REGLES
	my @migcms_members_rules = sql_lines({table=>'migcms_members_rules',where=>"visible='y'",ordby=>"name"});
	$liste_regles .= <<"EOH";
		<tr><td>
				<label><input type="radio" name="id_member_rule" value="0"  class="reset_field compute_nb id_member_rule" /> Aucun </label><br />				
		</td><td></td></tr>
EOH

	my $url_members = $config{rules_voir_members};
	if($url_members eq '')
	{
		my %rec_script_members = sql_line({table=>'scripts',where=>"url LIKE '%adm_migcms_members.pl%'"});
		$url_members = 'adm_migcms_members.pl?&sel='.$rec_script_members{id};
	}

	
	foreach $migcms_members_rule (@migcms_members_rules)
	{
		my %migcms_members_rule = %{$migcms_members_rule};
		my $liste_groupes = '<table class="table table-striped table-hover">';
		$aucune_regle = 0;
		$migcms_members_rule{description} =~  s/\r*\n/\<br\>/g;
		
		$liste_regles .= <<"EOH";
		<tr><td>
		<label><input type="radio" name="id_member_rule" rel="" value="$migcms_members_rule{id}" class="reset_field compute_nb id_member_rule" /> <b>$migcms_members_rule{name}</b></label><br />				
		$migcms_members_rule{description}		
		</td>
		<td class="hide">
		<a target="_blank" href="$url_members&id_rule=$migcms_members_rule{id}" data-placement="bottom" data-original-title="Voir les contacts correspondant à cette règle" id="$id" role="button" class=" 
				  btn btn-primary $class show_only_after_document_ready">
					  <i class="fa fa-fw fa-users" "> 
				  </i>
						  
				  </a>
				  </td>
		</tr>
EOH
	}
	$liste_regles .= '</table>';
	
	$liste_regles =~ s/PARAMETRE1/<b style="color:red">PARAMETRE1<\/b>/g;
	$liste_regles =~ s/PARAMETRE2/<b style="color:blue">PARAMETRE2<\/b>/g;
	
	
	
	
	if(0 || $aucun_groupe)
	{
		$liste_dirs = "<p>Vous n'avez encore défini aucun groupe. Vous pouvez en créer dans E-mailing > Groupes</p>";
	}
	if(0 || $aucun_segment)
	{
		$liste_segments = "<p>Vous n'avez encore défini aucun segment. Vous pouvez en créer dans E-mailing > Segments</p>";
	}
	
	if(0 || $aucune_regle)
	{
		$liste_regles = "<p>Vous n'avez encore défini aucune règle spéciale. Faites une demande de règle sur mesure à l'adresse support\@bugiweb.com</p>";
	}
	
	my $id_migcms_page = get_quoted('id_migcms_page');
	my $mailing_basehref = get_quoted('mailing_basehref');
	
	my $mailing_credits = '';
	
	
	my $confirm_button = <<"EOH";
	<button type="submit" data-placement="bottom" data-original-title="Sauvegarder" class="confirm_button3 btn btn-lg btn-success  ">Oui, je confirme l'envoi</a>
EOH
	
	if($config{use_mailing_credits} eq 'y')
	{
		$mailing_credits = <<"EOH";
			<div class="msg_credits_restant hide">
				<br /><br /><div class="credits_restants">
				<h4>Crédits restants :</strong> $config{mailing_credits} (après envoi : <span class="nb_credits_after_send">...</span>)</div><div class="credits_restants_msg hide"><h4><strong>Crédits insuffisants pour effectuer l´envoi (Reste : $config{mailing_credits})</strong></h4></div>
			</div>
EOH

	$confirm_button = <<"EOH";
	<button type="submit" data-placement="bottom" data-original-title="Sauvegarder" class="hide confirm_button3 btn btn-lg btn-success  ">Oui, je confirme l'envoi</a>
EOH
	}
	
	
	 my $listbox_tag_interdit = sql_listbox(
                                {
                                      dbh=>$dbh,
                                      table=> 'migcms_members_tags',
                                      show_empty=>'y',
                                      select=>"id as value, fusion as display",
                                      value=>'value',
                                      display=>'display',
                                      name=> 'tag_interdit',
                                      class=>"tag_interdit form-control",
                                      where => "fusion != ''",
                                      current_value => "",
                                      required => "",
                                });
	
	
	my $content = <<"EOH";
<style type="text/css">
	.deplie_datetime.active, .deplie_contacts.active {
		background-color: #5bc0de;
		border-color: #46b8da;
		color: #fff;
	}
</style>
<script type="text/javascript">
	var t_interdit;
	
	jQuery(document).ready(function() 
	{
		
		var quand = '';
		var cible = '';
		
		t_interdit = jQuery('.tag_interdit');
		
		t_interdit.selectpicker(
								{
									liveSearch:true,
									noneSelectedText:''
								});
		
		jQuery('.reset_field').prop('checked',false);
		
		jQuery('.deplie_groupes').click(function()
		{
			jQuery(this).parent().children('.fa-plus-square-o').toggleClass('hide');
			jQuery(this).parent().children('.fa-minus-square-o').toggleClass('hide');
			jQuery(this).parent().children('.groupes').toggleClass('hide');
		});		
		
		jQuery('.deplie_datetime').click(function()
		{
			if(jQuery(this).hasClass("deplie_datetime_planned")) {
				jQuery(".planned_datetime").removeClass('hide');
			}
			else {
				jQuery(".planned_datetime").addClass('hide');
			}
		});	
		
		jQuery('.deplie_contacts').click(function()
		{
			if(jQuery(this).hasClass("deplie_contacts_test")) {
				jQuery(".choix_test").removeClass('hide');
				jQuery(".choix_contacts").addClass('hide');
			}
			else if(jQuery(this).hasClass("deplie_contacts_groups")) {
				jQuery(".choix_test").addClass('hide');
				jQuery(".choix_contacts").removeClass('hide');
			}
		});	

		jQuery('.compute_nb').change(function()
		{
			compute_nb();
			jQuery('.alert-info').removeClass('hide');
			jQuery('.next_step3').removeClass('hide');
		});	
		t_interdit.change(function()
		{
			compute_nb();
			jQuery('.alert-info').removeClass('hide');
			jQuery('.next_step3').removeClass('hide');
		});			
		
		jQuery('.next_step2').click(function()
		{
			var test_form = 0;
		
			quand = jQuery('input[name="planned_datetime"]:checked').val();
			if(quand == 'planned')
			{
				var planned_date 	= jQuery('input#planned_date').val();
				var planned_heure 	= jQuery('input#planned_heure').val();
								
				if(planned_date != "" && planned_heure != "") {
					test_form = 1;
				}
				else {
					swal({title:"Attention", text:"Vous devez choisir une date et une heure d'envoi pour continuer...", type:"warning", timer: 5000});
				}
			}
			else if(quand == 'notplanned') {
				test_form = 1;
			}
			else if(quand != 'planned' && quand != 'notplanned')
			{
				swal({title:"Attention", text:"Vous devez choisir quand la newsletter sera envoyée pour continuer...", type:"warning", timer: 5000});
			}
			
			
			if(test_form == 1) {
			
				cible = jQuery('input[name="cible"]:checked').val();
				if(cible == 'tous')
				{
					jQuery('.prepare_form_step1').addClass('hide');
					jQuery('.prepare_form_step3').removeClass('hide');
				}
				else if(cible == 'groupes')
				{
					jQuery('.prepare_form_step1').addClass('hide');
					jQuery('.prepare_form_step2').removeClass('hide');
				}
				else if(cible != 'tous' && cible != 'groupes')
				{
					swal({title:"Attention", text:"Vous devez choisir les destinataires pour continuer...", type:"warning", timer: 5000});   

				}
			}
			return false;
				
		});	
		
		jQuery('.next_step3').click(function()
		{
			var id_migcms_page = jQuery('.id_migcms_page').val();
			var mailing_basehref = jQuery('.mailing_basehref').val();
			var emails_test = jQuery('.emails_test').val();
			var groupescb = [];
			jQuery(".groupecb:checked").each(function(){
			   groupescb.push(this.id); 
			});
			var groupescb_list = groupescb.toString();
			var id_segment = jQuery('.id_segment:checked').attr('rel');
			var id_member_rule = jQuery('.id_member_rule:checked').val();

			if(groupescb_list == '' && !(id_segment>0) && emails_test == '' && !(id_member_rule>0))
			{
				swal({title:"Attention", text:"Vous avez choisi de ne pas faire un envoi à tous vos contacts: Vous devez donc sélectionner soit un groupe, soit un segment, soit une règle, soit encoder au moins un email test.", type:"warning"});   
			}
			else
			{
				jQuery('.prepare_form_step2').addClass('hide');
				jQuery('.prepare_form_step3').removeClass('hide');
			}
			return false;
		});
		
		jQuery('.previous_step2').click(function()
		{
			jQuery('.prepare_form_step1').removeClass('hide');
			jQuery('.prepare_form_step2').addClass('hide');
			jQuery('.alert-info').addClass('hide');
			jQuery('.nb_membres').html('...');			
			return false;
		});	
		
		jQuery('.previous_step3').click(function()
		{
			
			if(cible == 'tous')
			{
				jQuery('.prepare_form_step1').removeClass('hide');
				jQuery('.prepare_form_step3').addClass('hide');
			}
			if(cible == 'groupes')
			{
				jQuery('.prepare_form_step2').removeClass('hide');
				jQuery('.prepare_form_step3').addClass('hide');
			}
			return false;

		});
		
		jQuery('#preview_regle').click(function()
		{
			var id_member_rule = jQuery('.id_member_rule:checked').val();
			if(id_member_rule > 0)
			{
				var href = jQuery('#preview_regle').attr('href');
				href += id_member_rule;
				href += '&variable_a='+jQuery('#variable_a').val();
				href += '&variable_b='+jQuery('#variable_b').val();
				window.open(href,'_blank');
			}
			else
			{
				swal({title:"Attention", text:"Vous devez choisir une règle d'abord...", type:"warning", timer: 5000});
			}
			
			
			return false;
		});
		
		
		
		compute_nb();
		
	});	

	function compute_nb()
	{
		jQuery('.nb_membres').html('...');
		var id_migcms_page = jQuery('.id_migcms_page').val();
		var mailing_basehref = jQuery('.mailing_basehref').val();
		var emails_test = jQuery('.emails_test').val();
		var tag_interdit = t_interdit.val();
		var groupescb = [];
		jQuery(".groupecb:checked").each(function(){
		   groupescb.push(this.id); 
		});
		var groupescb_list = groupescb.toString();
		var id_segment = jQuery('.id_segment:checked').attr('rel');
		var id_member_rule = jQuery('.id_member_rule:checked').val();
		var variable_a = jQuery('#variable_a').val();
		var variable_b = jQuery('#variable_b').val();
		
		jQuery.ajax(
		{
		   type: "GET",
		   url: '$dm_cfg{self}',
		   data: "sw=compute_nb_members_from_tags&id_member_rule="+id_member_rule+"&variable_a="+variable_a+"&variable_b="+variable_b+"&tags="+id_segment+"&groupes="+groupescb_list+"&tag_interdit="+tag_interdit+"&emails_test="+emails_test+"&id_migcms_page="+id_migcms_page,
		   success: function(msg)
		   {
				//nb emails et nb minutes
				var tab_contenu = msg.split("_");
				jQuery('.nb_membres').html(tab_contenu[0]);
				jQuery('.nb_min').html(tab_contenu[1]);
				
				var mailing_credits_restants = '$config{mailing_credits}';
				
				//credits
				if(mailing_credits_restants != "" && '$config{use_mailing_credits}' == 'y' ) 
				{
					mailing_credits_restants = Number(mailing_credits_restants);
					var restant_apres_envoi = mailing_credits_restants - tab_contenu[0];
					
					jQuery('.nb_credits_after_send').html(restant_apres_envoi);
					
					if(!(restant_apres_envoi > 0)) 
					{
						jQuery('.credits_restants_msg').removeClass('hide');
						jQuery('.next_step3').addClass('hide');
						jQuery('.confirm_button3').addClass('hide');
					}
					else 
					{
						jQuery('.credits_restants_msg').addClass('hide');
						jQuery('.next_step3').removeClass('hide');
						jQuery('.confirm_button3').removeClass('hide');
					}
					jQuery('.msg_credits_restant').removeClass('hide');
				}
		    }
		});
		
	}
</script>

<div class="wrapper">
	<form method="post" action="" class="form-horizontal adminex-form">
		<input type="hidden" name="id_migcms_page" value="$id_migcms_page" class="id_migcms_page" />
		<input type="hidden" name="mailing_basehref" value="$mailing_basehref" class="mailing_basehref" />
		<input type="hidden" name="sw" value="prepare_form_db" />
		
		<div class="prepare_form_step1 prepare_form_step ">
			<div class="header-actions" style="">
				<div class="row">
					<div class="col-lg-12">
						<h1 class="maintitle">Envoyer la newsletter: Préparation</h1>
					</div>
				</div>
			</div>
			<div class="panel">
				<div class="panel-body">
					<div class="well">
					
						<!-- NOM -->
						<div class="form-group item  row  migcms_group_data_type_ hidden_0 ">
							<label for="field_mailing_from" class="col-sm-2 control-label ">
							Nom de l'expéditeur  
							</label>
							<div class="col-sm-10 mig_cms_value_col ">
								<div class="add-clear-span has-feedback "><input style="" type="text" autocomplete="off" data-domask="" rel="Demozone" name="mailing_from" value="$migcms_page{mailing_from}" id="field_mailing_from" class="clear_field form-control  " placeholder=""><span class="add-clear-x form-control-feedback fa fa-times" style="display: none; color: rgb(204, 204, 204); cursor: pointer; text-decoration: none; overflow: hidden; position: absolute; pointer-events: auto; right: 0px; top: 0px;"></span></div>
								<span class="help-block text-left"><i class="fa fa-info-circle" data-original-title="" title=""></i> Nom affiché devant l'adresse email. Exemple : <strong>Nom Prénom</strong> &lt;votre-adresse-email\@votre-nom-de-domaine.com&gt;</span>
							</div>
						</div>
						
						<!-- EMAIL -->
						<div class="form-group item  row  migcms_group_data_type_email hidden_0 ">
							<label for="field_mailing_from_email" class="col-sm-2 control-label ">
							Email de l'expéditeur  *  
							</label>
							<div class="col-sm-10 mig_cms_value_col ">
								<div class="input-group">
									<span class="input-group-addon"><i class="fa fa-envelope-o fa-fw" data-original-title="" title=""></i></span>
									<div class="add-clear-span has-feedback "><input autocomplete="off" type="email" name="mailing_from_email" value="$migcms_page{mailing_from_email}" id="field_mailing_from_email" class="clear_field form-control saveme saveme_txt edit_email" required="" placeholder=""><span class="add-clear-x form-control-feedback fa fa-times" style="display: none; color: rgb(204, 204, 204); cursor: pointer; text-decoration: none; overflow: hidden; position: absolute; pointer-events: auto; right: 0px; top: 0px;"></span></div>
								</div>
								<span class="help-block text-left"></span>
							</div>
						</div>
						
						<!-- OBJET -->
						<div class="form-group item  row  migcms_group_data_type_ hidden_0 ">
							<label for="field_mailing_object" class="col-sm-2 control-label ">
							Objet du mail  *  
							</label>
							<div class="col-sm-10 mig_cms_value_col ">
								<div class="add-clear-span has-feedback "><input style="" type="text" autocomplete="off" data-domask="" rel="Newsletter Demozone" name="mailing_object" value="$migcms_page{mailing_object}" id="field_mailing_object" class="clear_field form-control  " required="" placeholder=""><span class="add-clear-x form-control-feedback fa fa-times" style="display: none; color: rgb(204, 204, 204); cursor: pointer; text-decoration: none; overflow: hidden; position: absolute; pointer-events: auto; right: 0px; top: 0px;"></span></div>
								<span class="help-block text-left"><i class="fa fa-info-circle" data-original-title="" title=""></i> Afin d'éviter que votre newsletter soit bloquée par les filtres antispam, il est recommandé d'éviter des mots entièrement en majuscules</span>
							</div>
						</div>
						
						<!-- PRE HEADER -->
						<div class="form-group item  row  migcms_group_data_type_ hidden_0 ">
							<label for="field_mailing_object" class="col-sm-2 control-label ">
							Pré-header  *  
							</label>
							<div class="col-sm-10 mig_cms_value_col ">
								<div class="add-clear-span has-feedback "><input style="" type="text" autocomplete="off" data-domask="" rel="Newsletter Demozone" name="mailing_name" value="$migcms_page{mailing_name}" id="field_mailing_name" class="clear_field form-control  " required="" placeholder=""><span class="add-clear-x form-control-feedback fa fa-times" style="display: none; color: rgb(204, 204, 204); cursor: pointer; text-decoration: none; overflow: hidden; position: absolute; pointer-events: auto; right: 0px; top: 0px;"></span></div>
								<span class="help-block text-left"><i class="fa fa-info-circle" data-original-title="" title=""></i> <a href="http://www.emailing.biz/rediger-son-contenu/pre-header-emailing/" target="_blank">Comment rédiger un bon pré-header ?</a></span>
							</div>
						</div>
						
						<!-- SIMULATION -->
						<div class="form-group item  row  migcms_group_data_type_ hidden_0 ">							
							<label for="field_mailing_object" class="col-sm-2 control-label ">
							Simulation de votre newsletter dans un logiciel de messagerie (Outlook, Gmail, ...)
							</label>
							<div class="col-sm-10 mig_cms_value_col ">
								<div class="mail_simulator" style="background:url('/mig_skin/img/mail_simulator.jpg');width:524px;height:239px;padding-left:37px;padding-right:37px;padding-top:63px;line-height:16px;font-family:arial;">
									<div class="mail_simulator_expeditor" style="color:black;font-size:17px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">$migcms_page{mailing_from}</div>
									<div class="mail_simulator_object" style="color:black;font-size:12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">$migcms_page{mailing_object}</div>
									<div class="mail_simulator_preheader" style="font-size:12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">$migcms_page{mailing_name}</div>
								</div>
							</div>
						</div>
						
						<!-- DATE --> 
						<div class="form-group item  row  migcms_group_data_type_date hidden_ ">
							<label for="field_date_prestation" class="col-sm-2 control-label">
							Quand envoyer votre newsletter ? 
							</label>
							<div class="col-sm-10 mig_cms_value_col">
							
								<div class="btn-group" data-toggle="buttons">
									<label class="btn btn-default deplie_datetime deplie_datetime_planned">
										<input type="radio" name="planned_datetime" autocomplete="off" value="planned"> Je souhaite planifier l'envoi de cette newsletter
									</label>
									<label class="btn btn-default deplie_datetime deplie_datetime_noplanned">
										<input type="radio" name="planned_datetime" autocomplete="off" value="notplanned"> Je souhaite l'envoyer directement
									</label>
								</div>
								
								<div class="hide planned_datetime" style="margin-top:5px;">
								
									<div class="input-group" style="margin-bottom:5px;">
										<span class="input-group-addon"><i class="fa fa-calendar" data-original-title="" title=""></i></span>
										<input autocomplete="off" data-ordby="00200" type="text" data-domask="" name="planned_date" value="" id="planned_date" class="form-control saveme saveme_txt edit_datepicker" placeholder="">
									</div>
									
									<div class="input-group">
										<span class="input-group-addon"><i class="fa fa-clock-o" data-original-title="" title=""></i></span>
										<input type="text" name="planned_heure" value="" id="planned_heure" class="form-control" autocomplete="off">
									</div>
								
								</div>

							</div>
						</div>
						
						<!-- CIBLE -->
						<div class="form-group item  row  migcms_group_data_type_time hidden_ ">
							<label for="field_duree" class="col-sm-2 control-label">
							Destinataires * 
							</label>
							<div class="col-sm-10 mig_cms_value_col">
								<div class="input-group">
								
									<div class="radio">
										<label>
											<input type="radio" name="cible" id="tous" value="tous" class="">
											Envoyer à tous les contacts
										</label>
									</div>
									<div class="radio">
										<label>
											<input type="radio" name="cible" id="groupes" value="groupes" class="">
											Envoyer à un ou plusieurs groupes de contacts
										</label>
									</div>

								</div>
								<span class="help-block text-left"></span>
							</div>
						</div>
												
						<div class="row">
							<div class="col-md-12 text-right">
								<a class="btn btn-lg btn-link" aria-hidden="true" href="/cgi-bin/adm_migcms_pages_newsletters.pl?&sel=$this_sel" data-original-title="" title=""><i class="fa fa-arrow-left" data-original-title="" title=""></i> Retour</a>
								<a class="btn btn-lg btn-success show_only_after_document_ready admin_edit_save next_step2">Étape suivante</a>
							</div>
						</div>
					
					</div>
				</div>
			</div>
		</div>
		
		
		<div class="prepare_form_step2 prepare_form_step  hide">
			<div class="header-actions" style="">
				<div class="row">
					<div class="col-lg-12">
						<h1 class="maintitle">Envoyer la newsletter: Envoyer à des groupes ou des segments...</h1>
					</div>
				</div>
			</div>
			<div class="panel">
				<div class="panel-body">
					<div class="well">
									
						
						<!-- CHOIX --> 
						<div class="form-group item  row  migcms_group_data_type_date hidden_ ">
							<label for="field_date_prestation" class="col-sm-2 control-label">
							Que désirez-vous faire? *  
							</label>
							<div class="col-sm-10 mig_cms_value_col">
							
								<div class="btn-group" data-toggle="buttons">
									<label class="btn btn-default deplie_contacts deplie_contacts_test">
										<input type="radio" name="choix" autocomplete="off" value="test"> Faire un test
									</label>
									<label class="btn btn-default deplie_contacts deplie_contacts_groups">
										<input type="radio" name="choix" autocomplete="off" value="contacts"> Envoyer à un ou plusieurs groupes de contacts
									</label>
								</div>

							</div>
						</div>
						
						<!-- CHOIX TEST --> 
						<div class="form-group item  row  migcms_group_data_type_date hidden_ hide choix_test">
							<label for="field_date_prestation" class="col-sm-2 control-label">
							Envoyer aux adresses suivantes *  
							</label>
							<div class="col-sm-10 mig_cms_value_col">
							
								<input type="text" name="emails_test" value="" class="form-control compute_nb emails_test" placeholder="julie\@monsite.be,info\@client.be" />

							</div>
						</div>
						
						<!-- CHOIX CONTACTS GROUPES --> 
						<div class="form-group item  row  migcms_group_data_type_date hidden_ hide  choix_contacts">
							<label for="field_date_prestation" class="col-sm-2 control-label">
							<b>Choisissez un ou plusieurs groupes:</b>
							<br /><span style="color:#aaa"><i class="fa fa-info"></i> Seront sélectionnés les membres qui correspondent à un groupe au moins</span>
							</label>
							<div class="col-sm-10 mig_cms_value_col">
							
								$liste_dirs

							</div>
						</div>
						
					
						
						
						<!-- CHOIX CONTACTS SEGMENTS --> 
						<div class="form-group item  row  migcms_group_data_type_date hidden_ hide  choix_contacts">
							
							<label for="field_date_prestation" class="col-sm-2 control-label">
							<b>OU Choisissez un segment:</b>
							<br /><span style="color:#aaa"><i class="fa fa-info"></i> Seront sélectionnés les membres qui correspondent à tous les groupes du segment</span>
							</label>
							<div class="col-sm-10 mig_cms_value_col">
							
								$liste_segments

							</div>
						</div>
						
						
						<!-- CHOIX listbox_tag_interdit --> 
						<div class="form-group item  row  migcms_group_data_type_date hidden_ hide  choix_contacts">
							
							<label for="field_date_prestation" class="col-sm-2 control-label">
							<b>Retirez un groupe de la sélection:</b>
							<br /><span style="color:#aaa"><i class="fa fa-info"></i> Seront retirés de la sélection ci-dessus, les membres qui correspondent ce groupe</span>
							</label>
							<div class="col-sm-10 mig_cms_value_col">
							
								$listbox_tag_interdit

							</div>
						</div>
						
						<hr />
						<!-- CHOIX CONTACTS REGLES --> 
						<div class="form-group item  row  migcms_group_data_type_date hidden_ hide  choix_contacts">
							
							<label for="field_date_prestation" class="col-sm-2 control-label">
							<b>OU Forcer une règle spécifique:</b>
							<br /><span style="color:#aaa"><i class="fa fa-info"></i> Seront sélectionnés les membres qui correspondent à cette règle spécifique. Toutes les autres conditions sont remplacées par celle-ci.</span>
							
							<br />
							
							<br />
							Paramètre 1:
							<br />
							<input type="text" class="form-control compute_nb" id="variable_a" name="variable_a" value="" />
							Paramètre 2:
							<br />
							<input type="text" class="form-control compute_nb" id="variable_b" name="variable_b" value="" />
							<br />
							<a target="_blank" href="adm_migcms_handmade_energiesplus_members.pl?&amp;sel=219&amp;id_rule=" data-placement="bottom" data-original-title="Voir les contacts correspondant à la règle sélectionnée" id="preview_regle" role="button" class=" 
				  btn btn-primary  show_only_after_document_ready">
					  <i class="fa fa-fw fa-users" "="" data-original-title="" title=""> 
				  </i>
						  
				  </a>
							</label>
							<div class="col-sm-10 mig_cms_value_col">
							
								$liste_regles

							</div>
						</div>
						
						

						<div class="row">
							<div class="col-md-12">
								<div class="alert alert-info hide">
									<h4>L'envoi sera de <b class="nb_membres">...</b> email(s), avec pour contenu <a href="/cgi-bin/migcms_view.pl?id_page=$id_migcms_page&amp;mailing=y&amp;lg=1" target="_blank" style="color:#31708f;text-decoration:underline;" data-original-title="" title="">cette page.</a></h4>
									Temps nécessaire pour envoyer tous les emails : <b class="nb_min">...</b> (donnée aproximative dépendant de la disponibilité des serveurs)
								</div>
								<span style="color:#ce5454;">Pour tester l'indésirabilité (spam) de vos emails, vous pouvez générer une adresse email de TEST sur <a href="https://www.mail-tester.com/" target="_blank" style="color:#ce5454;" data-original-title="" title=""><strong>www.mail-tester.com</strong></a>, afin d'obtenir un rapport.</span><br>
							</div>
						</div>
						
						$mailing_credits
						
						
						<div class="row">
							<div class="col-md-12 text-right">
								<a class="btn btn-lg btn-link previous_step2" aria-hidden="true" href="#" data-original-title="" title=""><i class="fa fa-arrow-left" data-original-title="" title=""></i> Retour</a>
								
								<a class="btn btn-lg btn-success show_only_after_document_ready admin_edit_save next_step3 hide">Étape suivante</a>
								
							</div>
						</div>				
					
					</div>
				</div>
			</div>
		</div>
		
		
		<div class="prepare_form_step3 prepare_form_step hide">
			<div class="header-actions" style="">
				<div class="row">
					<div class="col-lg-12">
						<h1 class="maintitle">Envoyer la newsletter: Confirmation</h1>
					</div>
				</div>
			</div>
			<div class="panel">
				<div class="panel-body">
					<div class="well">
					
						<div class="row">
							<div class="col-md-12">
								<div class="alert alert-info">
									<h4>L'envoi sera de <b class="nb_membres">...</b> email(s), avec pour contenu <a href="/cgi-bin/migcms_view.pl?id_page=$id_migcms_page&amp;mailing=y&amp;lg=1" target="_blank" style="color:#31708f;text-decoration:underline;" data-original-title="" title="">cette page.</a></h4>
									Temps nécessaire pour envoyer tous les emails : <b class="nb_min">...</b> (donnée aproximative dépendant de la disponibilité des serveurs)
								</div>
								<span style="color:#ce5454;">Pour tester l'indésirabilité (spam) de vos emails, vous pouvez générer une adresse email de TEST sur <a href="https://www.mail-tester.com/" target="_blank" style="color:#ce5454;" data-original-title="" title=""><strong>www.mail-tester.com</strong></a>, afin d'obtenir un rapport.</span><br>
							</div>
						</div>
						
						$mailing_credits
						
						<div class="row">
							<div class="col-md-12 text-right">
								<a class="btn btn-lg btn-link previous_step3" aria-hidden="true" href="#" data-original-title="" title=""><i class="fa fa-arrow-left" data-original-title="" title=""></i> Retour</a>
								$confirm_button
							</div>
						</div>
					
					</div>
				</div>
			</div>
		</div>
	</form>
</div>
EOH
	
	
	
	
	
	$dm_output{content} = $content;
}

sub prepare_form_db
{
	# see();
	# print "L'envoi réel est désactivé en mode test.";
	# exit;
	my $id_migcms_page = get_quoted('id_migcms_page');
	my $emails_test = get_quoted('emails_test');
	my $tag_interdit = get_quoted('tag_interdit');
	my $planned_date = trim(get_quoted('planned_date'));
	my $planned_heure = trim(get_quoted('planned_heure'));
	my $cible = get_quoted('cible');
	
	my $planned_date_sql = sending_to_sql_date($planned_date);
	my $planned_heure_sql = sending_to_sql_time($planned_heure);

	
	my $groupes = "";
	my $tags = "";
	my $id_member_rule = get_quoted('id_member_rule');
	my $variable_a = get_quoted('variable_a');
	my $variable_b = get_quoted('variable_b');
	

	my @migcms_members_tags = sql_lines({table=>'migcms_members_tags',where=>"visible='y' AND name != ''"});
	foreach $migcms_members_tag (@migcms_members_tags)
	{
		my %migcms_members_tag = %{$migcms_members_tag};
		if(get_quoted('groupe_'.$migcms_members_tag{id}) eq 'y')
		{
			$groupes .= $migcms_members_tag{id}.',';
		}
	}

	my $id_segment = get_quoted('id_segment');
	my %migcms_member_segment = ();
	if($id_segment > 0)
	{
		%migcms_member_segment = sql_line({table=>'migcms_member_segments',where=>"id = '$id_segment'",ordby=>"name"});
	}
	if($migcms_member_segment{id} > 0 && $migcms_member_segment{fusion} ne '')
	{
		$tags = $migcms_member_segment{fusion};
	}

	
	if($emails_test ne '')
	{
		$groupes = $tags = "";		
	}
	if($groupes ne '')
	{
		$tags = "";		
	}
	
	# print "<br />Tests: $emails_test";
	# print "<br />Groupes: $groupes";
	# print "<br />Segments: $tags";
	# exit;
	
	my %migcms_page = sql_line({table=>'migcms_pages',where=>"id='$id_migcms_page'"});
	if(!($migcms_page{id} > 0))
	{
		see();
		print "no page received/found";
		exit;	
	}
		# '' => $migcms_page{mailing_autoconnect},
		# '' => $migcms_page{mailing_id_campaign},

	my %new_sending = 
	(
		'id_migcms_page' => $id_migcms_page,
		'mailing_from' => get_quoted('mailing_from'),
		'mailing_from_email' => get_quoted('mailing_from_email'),
		'mailing_object' => get_quoted('mailing_object'),
		'mailing_name' => $migcms_page{mailing_name},
		'cible' => $cible,
		'emails_test' => $emails_test,
		'tag_interdit' => $tag_interdit,
		'planned_time' => $planned_date_sql.' '.$planned_heure_sql,
		'id_member_rule'=>$id_member_rule,
		'variable_a'=>$variable_a,
		'variable_b'=>$variable_b,
		'tags'=>$tags,
		'groupes'=>$groupes,
		'status' => '',
		'mailing_include_pics' => $migcms_page{mailing_include_pics},
		'mailing_headers' => $migcms_page{mailing_headers},
		'basehref' => $migcms_page{mailing_basehref},
		'google_analytics' => $migcms_page{mailing_googleanalytics},
	);
	$new_sending{mailing_name} =~s /\'/\\\'/g;
	$new_sending{cible} =~s /\'/\\\'/g;
	$new_sending{mailing_headers} =~s /\'/\\\'/g;
	
	my $id_sending = inserth_db($dbh,$dm_cfg{table_name},\%new_sending);
	after_add($dbh,$id_sending);
	
	
	my %this_script = sql_line({select=>"id",table=>"scripts",where=>"url LIKE '%adm_migcms_mailings_sendings%'"});
	cgi_redirect('/cgi-bin/adm_migcms_mailings_sendings.pl?&id_migcms_page='.$id_migcms_page.'&sel='.$this_script{id});
	exit;
	
	
	#status 						new
	#mailing_include_pics   		$migcms_page{mailing_include_pics}
	#mailing_headers 	 			$migcms_page{mailing_headers}



}


#TOOLS
sub sending_to_sql_date
{
	my $date = $_[0];	
	my ($dd,$mm,$yyyy) = split (/\//,$date);	
	if($mm < 10)
	{
		$mm = '0'.$mm;
	}
	if($dd < 10)
	{
		$dd = '0'.$dd;
	}
	$date = "$yyyy-$mm-$dd";
	return $date;
}
sub sending_to_sql_time
{
	my $time = $_[0];	#Date à convertir
  #10h15
  $_ = $time;
  if (/h/)
  {
     my ($hh,$mm) = split (/h/,$time);	#Séparation de la date
     if($hh eq "")
     {
        $hh='00';
     }
     if($mm eq "")
     {
        $mm='00';
     }
     return "$hh:$mm:00";
  }
  #10:15 ou 10:15:00
  $_ = $time;
  if (/\:/)
  {
     my ($hh,$mm,$ss) = split (/\:/,$time);	#Séparation de la date
     if($hh eq "")
     {
        $hh='00';
     }
     if($mm eq "")
     {
        $mm='00';
     }
     if($ss eq "")
     {
        $ss='00';
     }
     return "$hh:$mm:$ss";
  }
  #10
  $_ = $time;
  if (/\d/)
  {
     return "$time:00:00";
  }
  return "";
}

sub get_sender
{
	my $dbh = $_[0];
    my $id = $_[1];
	
	my %page = sql_line({table=>'mailing_sendings',select=>"*",where=>"id='$id'"});
	
	my $sender = $page{mailing_from}." (".$page{mailing_from_email}.")";

	return $sender;
}