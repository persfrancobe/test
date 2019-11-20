#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "migcms_members_events";
$dm_cfg{list_table_name} = "migcms_members_events";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_members_events.pl?";
$dm_cfg{duplicate} = 0;
$dm_cfg{default_ordby} = "moment desc";


%types_evts = 
(
	'01/signup_insert'        =>"Inscription (Nouveau membre)",
	'02/signup_update'        =>"Inscription (Et matching membre existant)",

	'03/login'        			=>"Connexion",
	'04/logout'       		 =>"Déconnexion",
	
	'10/lost_password'        =>"Demande une réinitialisation de son mot de passe",
	'11/edit_pasword'        =>"Modifie son mot de passe",

	
	'21/view_page'        =>"Visualise la page",
	'22/view_page_non_valide'        =>"N'a pu visualiser la page protégée",
	'23/view_page_group_forbidden'        =>"N'a pas accès à la page protégée",

	'31/reponse_campagne'        =>"Répond à la campagne",
	'32/reponse_question'        =>"Répond à la question",
	
	'51/admin_update'        =>"Modification par l'administrateur",
	'52/sent_mailing'        =>"Envoi e-mailing",
	'53/open_mailing'        =>"Ouverture e-mailing",
	'54/click_mailing'        =>"Click e-mailing",
	'55/error_mailing'        =>"Erreur envoi e-mailing",
	'56/blacklist_mailing'        =>"Email ajouté dans la blacklist",
	'57/add_tag'        =>"Ajout d'un tag",

);


%groupe_type_events = 
(
	'01/signup'        =>"Inscription",
	'02/login'        			=>"Connexion",
	'03/page'        =>"Accès aux pages",
	'04/actions'       		 =>"Actions",
	'04/mailing'       		 =>"E-mailing",
);


# $dm_cfg{col_street} = 'delivery_street';
# $dm_cfg{col_zip} = $config{members_col_zip} || 'delivery_zip';
# $dm_cfg{col_city} = $config{members_col_city} ||  'delivery_city';
# $dm_cfg{col_country} = $config{members_col_country} ||  'delivery_country';

# $dm_cfg{col_lat} = $config{members_col_lat} ||  'lat';
# $dm_cfg{col_lon} = $config{members_col_lon} ||  'lon';

# $dm_cfg{col_phone} =  $config{members_col_phone} || 'delivery_phone';
$dm_cfg{col_nom} = $config{members_col_nom} ||  "CONCAT(delivery_firstname,' ',delivery_lastname,' ',delivery_company,' (',email,')')";



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
		
		'01/id_member' => 
      {
           'title'=>'Membre',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'migcms_members',
           'lbkey'=>'id',
           'lbdisplay'=>"$dm_cfg{col_nom}",
           'lbwhere'=>"",
           'hidden'=>1,
      }
	  ,
		'03/date_event'=> {
	        'title'=>'Date',
	        'fieldtype'=>'text',
	        'data_type'=>'date',
	        'search' => 'n',
	    }
		,
		'04/time_event'=> {
	        'title'=>'Heure',
	        'fieldtype'=>'text',
	        'data_type'=>'time',
	        'search' => 'n',
	    }
		,
		'05/group_type_event '=> {
	        'title'=>"Type d'évement",
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%groupe_type_events,
	    }
		,
		'06/type_evt'=> {
	        'title'=>'Evenement',
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%types_evts,
	    }
		,
		'07/nom_evt'=> {
	        'title'=>'Nom',
	        'fieldtype'=>'text',
	        'search' => 'y',
	    }
		 ,
		'08/detail_evt'=> {
	        'title'=>'Détail',
	        'fieldtype'=>'textarea',
	        'search' => 'y',
	    }
		,
		'10/erreur_evt'=> {
	        'title'=>'Erreur',
	        'fieldtype'=>'text',
	        'search' => 'y',
	    }
	    
	);

%dm_display_fields = (
			"1/Membre"=>"id_member",
			"2/Date"=>"date_event",
			"3/Heure"=>"time_event",
			# "4/Type"=>"type_evt",
			# "5/Evenement"=>"nom_evt",

		);

%dm_lnk_fields = (
"40//evt_preview"=>"evt_preview*",

		);

%dm_mapping_list = (
"evt_preview"=>\&evt_preview,

);


 


%dm_filters = (

"1/Membre"=>{
                         'type'=>'lbtable',
                         'table'=>'migcms_members',
                         'key'=>'id',
                         'display'=>"$dm_cfg{col_nom}",
                         'col'=>'id_member',
                         'where'=>'id IN (select distinct(id_member) from migcms_members_events)'
                        }
,
"2/Types d'évenements"=>{
				 
						 'type'=>'hash',
						 'ref'=>\%groupe_type_events,
						 'col'=>'group_type_event'

						 
                        }
,						
"3/Evenements"=>{
				 
						 'type'=>'hash',
						 'ref'=>\%types_evts,
						 'col'=>'type_evt'

						 
                        }						

,
"4/Page"=>{
                         'type'=>'lbtable',
                         'table'=>'migcms_pages',
                         'key'=>'id',
                         'display'=>'id_textid_name',
						 translate=>1,
                         'col'=>'detail_evt',
                         'where'=>""
                        }
);

$dm_cfg{list_html_top} =<<"EOH";
<style type="text/css">
	.widget-header-actions, .list_action { display : none !important; }
</style>
EOH

# this script's name

$sw = $cgi->param('sw') || "list";

see();

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
		);

if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();

	
	
    print wfw_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}

# %types_evts = 
# (
	# '01/signup_insert'        =>"Inscription (Nouveau membre)",
	# '02/signup_update'        =>"Inscription (Et matching membre existant)",

	# '03/login'        			=>"Connexion",
	# '04/logout'       		 =>"Déconnexion",
	
	# '10/lost_password'        =>"Demande une réinitialisation de son mot de passe",
	# '11/edit_pasword'        =>"Modifie son mot de passe",

	
	# '21/view_page'        =>"Visualise la page",
	# '22/view_page_non_valide'        =>"N'a pu visualiser la page protégée",
	# '23/view_page_group_forbidden'        =>"N'a pas accès à la page protégée",

	# '31/reponse_campagne'        =>"Répond à la campagne",
	# '32/reponse_question'        =>"Répond à la question",
	
	# '51/admin_update'        =>"Modification par l'administrateur",

# );


# %groupe_type_events = 
# (
	# '01/signup'        =>"Inscription",
	# '02/login'        			=>"Connexion",
	# '03/page'        =>"Accès aux pages",
	# '04/action'       		 =>"Actions",
# );


sub evt_preview
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %d = %{$_[3]};
  
  
  my %evt = sql_line({debug_results=>0,table=>$dm_cfg{table_name},where=>"id='$id'"});
  my $evt_preview = '';
   
  if($evt{group_type_event} eq 'page')
  {
		#PAGE*************************************************************************************************
		
		my %page = sql_line({debug_results=>0,table=>'migcms_pages',where=>"id='$evt{detail_evt}'"});
		my $page_name = get_traduction({id=>$page{id_textid_name}});
		if($page_name eq '')
		{
			$page_name = 'Ref:'.$evt{detail_evt};
		}
		my $url_rewriting = $config{baseurl}.'/'.get_url({debug=>$debug,debug_results=>$debug,nom_table=>'migcms_pages',id_table=>$page{id}, id_language => $d{lg}});


		if($evt{type_evt} eq 'view_page')
		{
			return '<div class="alert alert-success" role="alert">Le membre consulte la page <b>'.$page_name.'</b> (Ref:'.$evt{detail_evt}.')<br /><a href="'.$url_rewriting.'" target="_blank">'.$url_rewriting.' <i class="fa fa-external-link-square"></i></a></div>';
		}
		elsif($evt{type_evt} eq 'view_page_non_valide')
		{
			return '<div class="alert alert-danger" role="alert">'."Le membre ne peut consulter une page car car son accès n'est pas validé</div>";
		}
		elsif($evt{type_evt} eq 'view_page_group_forbidden')
		{
			return '<div class="alert alert-danger" role="alert">Le membre consulte la page <b>'.$page_name.'</b> (Ref:'.$evt{detail_evt}.')'." mais l'accès au contenu est refusé car son groupe n'y a pas accès";
		}
		else
		{
			return '<div class="alert alert-info" role="alert">'.$evt{nom_evt}.'</div>';
		}
  }
  elsif($evt{group_type_event} eq 'member' || $evt{group_type_event} eq 'tags')
  {
		#MEMBER*************************************************************************************************
		
		if($evt{type_evt} eq 'admin_update')
		{
			my %rec = read_table($dbh,'users',$evt{detail_evt});
			return '<div class="alert alert-default" role="alert">'.$evt{nom_evt}.': <b>'."$rec{firstname} $rec{lastname}".'</b></div>'; 
		}
		elsif($evt{type_evt} eq 'add_tag')
		{
			return '<div class="alert alert-default" role="alert">'.$evt{nom_evt}.'</div>';
		}
		else
		{
			return '<div class="alert alert-info" role="alert">'.$evt{nom_evt}.'</div>';
		}
  }
  elsif($evt{group_type_event} eq 'mailing')
  {
		#MEMBER*************************************************************************************************
		
		if($evt{type_evt} eq 'sent_mailing')
		{
			my ($id_sending,$server,$token) = split(/\|/,$evt{detail_evt});
			my %mailing_sending = sql_line({debug_results=>0,table=>'mailing_sendings',where=>"id=$id_sending"});
			
			if($mailing_sending{mode_test} ne 'y') {
				return '<div class="alert alert-success" role="alert">Envoi de l\'e-mailing "<strong>'.$mailing_sending{mailing_object}.'</strong>"<br />Serveur d\'envoi : '.$server.'</div>';
			}
			else {
				return '<div class="alert alert-success" role="alert">Envoi de l\'e-mailing de TEST "<strong>'.$mailing_sending{mailing_object}.'</strong>"<br />Serveur d\'envoi : '.$server.'</div>';
			}
		}
		elsif($evt{type_evt} eq 'open_mailing')
		{
			my %mailing_sending = sql_line({debug_results=>0,table=>'mailing_sendings',where=>"id=$evt{detail_evt}"});
			my $device = $evt{device};
			if($device ne "") {
				$device = "<br />Périphérique : ".$device;
			}
			my $city = $evt{city};
			my $country = $evt{country};
			if($country ne "") {
				if($city ne "" && $evt{device} ne "mobile") {
					$city = $city.", ";
				}
				else {
					$city = "";
				}
				$country = " (".$city."".$country.")";
			}
			my $referer = $evt{referer};
			if($referer ne "") {
				$referer = "<br />Referer : ".$referer;
			}
			
			if($mailing_sending{mode_test} ne 'y') {
				return '<div class="alert alert-info" role="alert">Ouverture de l\'e-mailing "<strong>'.$mailing_sending{mailing_object}.'</strong>"'.$device.'<br />IP : '.$evt{ip}.''.$country.''.$referer.'</div>';
			}
			else {
				return '<div class="alert alert-info" role="alert">Ouverture de l\'e-mailing de TEST "<strong>'.$mailing_sending{mailing_object}.'</strong>"'.$device.'<br />IP : '.$evt{ip}.''.$country.''.$referer.'</div>';
			}
			
		}
		elsif($evt{type_evt} eq 'click_mailing')
		{
			my ($id_sending,$url) = split(/\|/,$evt{detail_evt});
			$url = '<a href="'.$url.'" target="blank">'.$url.'</a>';
			my %mailing_sending = sql_line({debug_results=>0,table=>'mailing_sendings',where=>"id=$id_sending"});
			my $device = $evt{device};
			if($device ne "") {
				$device = "<br />Périphérique : ".$device;
			}
			my $city = $evt{city};
			my $country = $evt{country};
			if($country ne "") {
				if($city ne "" && $evt{device} ne "mobile") {
					$city = $city.", ";
				}
				else {
					$city = "";
				}
				$country = " (".$city."".$country.")";
			}
			my $referer = $evt{referer};
			if($referer ne "") {
				$referer = "<br />Referer : ".$referer;
			}
		
			if($mailing_sending{mode_test} ne 'y') {
				return '<div class="alert alert-info" role="alert">Click dans l\'e-mailing "<strong>'.$mailing_sending{mailing_object}.'</strong>"<br />Page de destination : '.$url.''.$device.'<br />IP : '.$evt{ip}.''.$country.''.$referer.'</div>';
			}
			else {
				return '<div class="alert alert-info" role="alert">Click dans l\'e-mailing de TEST "<strong>'.$mailing_sending{mailing_object}.'</strong>"<br />Page de destination : '.$url.''.$device.'<br />IP : '.$evt{ip}.''.$country.''.$referer.'</div>';
			}
		
		}
		elsif($evt{type_evt} eq 'error_mailing')
		{
			my ($id_sending,$server,$token) = split(/\|/,$evt{detail_evt});
			my %mailing_sending = sql_line({debug_results=>0,table=>'mailing_sendings',where=>"id=$id_sending"});
			return '<div class="alert alert-danger" role="alert">Erreur lors de l\'envoi de l\'e-mailing "<strong>'.$mailing_sending{mailing_object}.'</strong>"<br />Serveur d\'envoi : '.$server.'<br />Erreur : '.$evt{erreur_evt}.'</div>';
		}
		elsif($evt{type_evt} eq 'blacklist_mailing')
		{
			return '<div class="alert alert-danger" role="alert">Le membre a été placé dans la blacklist<br />Raison : <strong>PERMANENT BOUNCE</strong></div>';
		}
		else
		{
			return '<div class="alert alert-default" role="alert">'.$evt{nom_evt}.'</div>';
		}
  }
  else
  {
	return '<div class="alert alert-info" role="alert">'.$evt{nom_evt}.'</div>';
  }
   
  # return $evt_preview;
  # my %page = sql_line({debug_results=>0,table=>'migcms_pages',where=>"id='$id'"});



}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------