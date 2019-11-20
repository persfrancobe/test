#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use members;
use eshop;
use def_handmade;
use dm;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use Geo::Coder::Google;
$dm_cfg{hide_prefixe} = 'y';
$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{visualiser} = 1;
$dm_cfg{sort_opt} = 0;
$dm_cfg{tree} = 0;
$dm_cfg{operations} = 1;
$dm_cfg{excel} = 1;
$dm_cfg{breadcrumb_func} = \&breadcrumb_func;
$dm_cfg{corbeille} = 0;
$dm_cfg{restauration} = 0;

$dm_cfg{validation_func} = \&validation_func;

$dm_cfg{force_corbeille} = 0;

my $id_father = get_quoted('id_father');
my $search_all = get_quoted('search_all');
if($search_all ne 'y')
{
	if($id_father  > 0)
	{
		$dm_cfg{wherep} = "id_father = '$id_father'";
	}
	else
	{
		$dm_cfg{wherep} = "id_father = 0";
	}
}



$dm_cfg{table_name} = "migcms_members";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
if($config{disable_members_liste_des_statuts} ne 'y')
{
	$dm_cfg{line_func} = \&migcms_tr_color;
}
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_members.pl?sel=".get_quoted('sel').'&id_father='.get_quoted('id_father');
if($config{current_language} eq "")
{
   $config{current_language}=get_quoted('lg') || 1;
}
$dm_cfg{default_ordby}= $config{members_default_ordby} || 'delivery_lastname,delivery_firstname desc';

$dm_cfg{tag_search} = 1;
$dm_cfg{tag_table} = 'migcms_members_tags';
$dm_cfg{tag_col} = 'tags';

$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_mod_ref} = \&after_save;

$dm_cfg{excel_key} ='id';

$dm_cfg{compute_gps} = $config{members_compute_gps} || 'y';
$dm_cfg{show_google_map} = $config{members_show_google_map} || 'y';
my $show_map = get_quoted('show_map') || 'n';
if($show_map ne 'y')
{
	$dm_cfg{show_google_map} = 'n';
}


$dm_cfg{col_street} = 'delivery_street';
$dm_cfg{col_zip} = $config{members_col_zip} || 'delivery_zip';
$dm_cfg{col_city} = $config{members_col_city} ||  'delivery_city';
$dm_cfg{col_country} = $config{members_col_country} ||  'delivery_country';

$dm_cfg{col_lat} = $config{members_col_lat} ||  'lat';
$dm_cfg{col_lon} = $config{members_col_lon} ||  'lon';

$dm_cfg{col_phone} =  $config{members_col_phone} || 'delivery_phone';
$dm_cfg{col_nom} = $config{members_col_nom} ||  "CONCAT(delivery_firstname,' ',delivery_lastname,' ',delivery_company)";


$dm_cfg{file_prefixe} = $config{members_file_prefixe} ||  'MEMBERS';


if($config{members_disable_connexion} ne 'y' && $id_father == 0)
{
	$dm_cfg{'list_custom_action_19_func'} = \&custom_connexion;
}
if($config{members_disable_reset_password} ne 'y' && $id_father == 0)
{
	$dm_cfg{'list_custom_action_18_func'} = \&custom_reset_password;
}
if($config{members_disable_historique} ne 'y' && $id_father == 0)
{
	# $dm_cfg{'list_custom_action_17_func'} = \&historique;
}
if($config{members_show_contacts} eq 'y' && $id_father == 0)
{
	$dm_cfg{'list_custom_action_11_func'} = \&contacts;
}

@dm_nav =
(
	 {
      'tab'=>'client',
			'type'=>'tab',
      'title'=>'Coordonnées'
    }
    ,
	 {
    	'tab'=>'commercial',
			'type'=>'tab',
      'title'=>'Commercial'
    } 
	,
 	# {
  #       'tab'=>'financier',
	# 'type'=>'tab',
  #       'title'=>'Financier'
  #   }
  #   ,
    {
        'tab'=>'notes',
		'type'=>'tab',
        'title'=>'Notes'
    }
	,
	 {
        'tab'=>'connexion',
		'type'=>'tab',
        'title'=>'Accès'
    }
	,
	{
        'tab'=>'eshop',
		'type'=>'tab',
        'title'=>'Boutique'
    }
	,
	 {
			'tab'=>'5',
			'type'=>'tab',
			'title'=>'Historique membre',
			'cgi_func' => 'members::members_migcms_history',
			'disable_add' => 1

		}
		,
	 {
			'tab'=>'group',
			'type'=>'tab',
			'title'=>'Sécurité',
		}
);

# Actions supplémentaires si la boutique est activée
my %eshop_setup = eshop::get_setup();
if($eshop_setup{shop_disabled} ne "y") 
{
	my %coord_livraison = (
		'title'    => 'Coordonnées de livraison',
		'type'     => 'tab',
		'cgi_func' => 'def_handmade::members_identities_delivery',
		'tab'      => 'delivery_identities',
	);

	push @dm_nav, \%coord_livraison;

	my %coord_facturation = (
		'title'    => 'Coordonnées de facturation',
		'type'     => 'tab',
		'cgi_func' => 'def_handmade::members_identities_billing',
		'tab'      => 'billing_identities',
	);

	push @dm_nav, \%coord_facturation;
}

%member_types = 
(
	'Normal'        =>"Normal",
	'Commande directe' =>"Commande directe"
);	
           
%dm_dfl = %{members::get_dm_dfl({migctrad=>\%migctrad})};
  
%dm_display_fields = 
(
 #"01/Nom"=>"delivery_lastname",
 #"02/Prénom"=>"delivery_firstname",
 #"03/Société"=>"delivery_company",
 #"04/Email"=>"email",
 "02/Groupes"=>"tags",
);



%dm_lnk_fields = 
(
"01/Membre/col_statut"=>"member_infos*",
#"02/Groupes/col_statut"=>"member_groupes*",
#"03/Segments/col_statut"=>"member_segments*",
#"98/Actions/col_conn"=>"actions*",
#"98/Opt-in/col_statut"=>"optin*",
"99/Statut/col_statut"=>"statut*",
);

%dm_mapping_list = (
"member_infos" => \&get_infos_members,
#"member_groupes" => \&get_groups_members,
#"member_segments" => \&get_tags_members,
# "actions" => \&get_actions_members,
"statut" => \&get_statut_members,
"optin" => \&get_optin_members,
);

if($config{disable_members_email_optin} eq 'y' && $config{disable_members_email_validation} eq 'y' && $config{disable_members_liste_des_statuts} eq 'y')
{
	delete $dm_lnk_fields{'99/Statut/col_statut'};
	delete $dm_mapping_list{'statut'};
}

%dm_filters = 
(

  "6/Status"=>
  {
		'type'      =>'listbox',
		'table'     =>'migcms_members_status',
		'key'       =>'migcms_members_status.id',
		'display'   =>'id_textid_name',
		'col'       =>'id_member_status',
		'where'     =>"",
		'translate' => 1,
  }
);


my %members_setup = select_table($dbh,"members_setup");   


%dm_import_excel = ();
if($members_setup{use_handmade_members} eq 'y')
{
	@dm_nav = @{def_handmade::get_members_handmade_dm_nav({migctrad=>\%migctrad})};
	$dm_cfg{list_html_top} .= def_handmade::get_list_html_top({migctrad=>\%migctrad});
	
	%dm_display_fields  = %{def_handmade::get_members_handmade_dm_display_fields({migctrad=>\%migctrad})};
	%dm_lnk_fields      = %{def_handmade::get_members_handmade_dm_lnk_fields({migctrad=>\%migctrad})};
	%dm_mapping_list 	= %{def_handmade::get_members_handmade_dm_mapping_list({migctrad=>\%migctrad})};
	%dm_filters         = %{def_handmade::get_members_handmade_dm_filters({migctrad=>\%migctrad})};
	%dm_import_excel    = %{def_handmade::get_members_handmade_dm_import_excel({migctrad=>\%migctrad})};
}

if($config{members_show_contacts} eq 'y' && $id_father == 0 && $search_all ne 'y')
{
	delete $dm_display_fields{"30/Type"};
	delete $dm_display_fields{"40/Entreprise"};
}

$sw = $cgi->param('sw') || "list";
$sel = $cgi->param('sel') || "";
 see();
 

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
		);
		
		my $map_class = 'btn-default';
		my $search_all_class = 'btn-default';
		my $map_value = 'y';
		my $search_all_value = 'y';
		if(get_quoted('show_map') eq 'y')
		{
			$map_class='btn-primary';
			$map_value = 'n';
		}
		if(get_quoted('search_all') eq 'y')
		{
			$search_all_class='btn-primary';
			$search_all_value = 'n';
		}

		$dm_cfg{custom_navbar} = <<"EOH";
			<a data-original-title="Groupes de membres" 
			data-placement="bottom" class="btn btn-default btn-lg custom_navbar_groups
			 search_element"
			 href = "adm_migcms_member_groups.pl?sel=$sel"  
			 >
				<i class="fa  fa-lock fa-fw"></i> 
			</a>
			
			<a data-original-title="Afficher la carte" 
			data-placement="bottom" class="btn $map_class btn-lg custom_navbar_map 
			 search_element"
			 href = "$dm_cfg{self}&show_map=$map_value"  
			 >
				<i class="fa  fa-map fa-fw"></i> 
			</a>
			
			<a data-original-title="Rechercher sur tout" 
			data-placement="bottom" class="btn $search_all_class btn-lg custom_navbar_search_all
			 search_element"
			 href = "$dm_cfg{self}&search_all=$search_all_value"  
			 >
				<i class="fa  fa-search-plus fa-fw"></i> 
			</a>
EOH

$dm_cfg{list_html_top} .= <<"HTML";
<style>
.col_statut
{
	width:220px;
}
</style>


<script type="text/javascript">
	var self = '$config{baseurl}/cgi-bin/adm_migcms_members.pl?';
	
	jQuery(document).ready(function() 
	{		
		jQuery(document).on("change", ".change_statut", change_statut);
	});

function change_statut()
{
	var me = jQuery(this);
	var statut_value = me.val();
	var id_member = me.attr('id_member');	

	console.log("Statut :" + statut_value);
	console.log("Membre :" + id_member);
	
	var request = jQuery.ajax(
	{
		url: self,
		type: "GET",
		data: 
		{
			sw : 'change_statut',
			statut_value : statut_value,
			id_member : id_member,
		},
		dataType: "html"
	});
	
	request.done(function(msg) 
	{
			jQuery.bootstrapGrowl('<i class="fa fa-info"></i> Statut sauvegardé', { type: 'success',align: 'center',
			width: 'auto' });

	});
	request.fail(function(jqXHR, textStatus) 
	{

	});
}
</script>
HTML
		
if (is_in(@fcts,$sw)) 
{ 
    dm_init();
	
	# if($search_all eq 'y')
	# {
		# $dm_permissions{editr} = 0;
		# $dm_permissions{view} = 1;
		# $dm_permissions{visualiser} = 1;
		# $dm_cfg{visibility} = 1;
	# }
	
    &$sw();

    if ($sw eq "list") {$spec_bar.=$lnkxls;}
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

sub custom_connexion
{
	my $id = $_[0];
	my $colg = $_[1];
	my %migcms_member = %{$_[2]};
	
	my $actions = <<"EOH";
		<a target="_blank" href="members.pl?sw=member_login_db&stoken=$migcms_member{stoken}&url_after_login=/&clean_cookie=y" data-placement="bottom" data-original-title="Se connecter avec cet accès" id="$id" role="button" class=" 
				  btn btn-success $class show_only_after_document_ready">
					  <i class="fa fa-fw fa-sign-in" "> 
				  </i>
						  
				  </a>

EOH
	if($migcms_member{email} ne '' && $migcms_member{token} ne '' && $migcms_member{token2} ne '' )
	{
	}
	else
	{
		$actions  = <<"EOH";
		<a target="" disabled href="" data-placement="bottom" data-original-title="Aucun accès défini" id="" role="button" class=" 
				   disabled btn btn-success $class show_only_after_document_ready">
					  <i class="fa fa-fw fa-sign-in" "> 
				  </i>
						  
				  </a>

EOH
	}
	
	return $actions;
}


sub custom_reset_password
{
	my $id = $_[0];
	my $colg = $_[1];
	my %migcms_member = %{$_[2]};
	my $actions = '';
	
	# LOST PASSWORD	# 
	if($migcms_member{email} ne '' && $migcms_member{token} ne '' && $migcms_member{token2} ne '' )
	{
		$actions  .= <<"EOH";

			<a target="_blank" href="members.pl?sw=lost_password_db&email=$migcms_member{email}" data-placement="bottom" data-original-title="Récupérer le mot de passe" id="$id" role="button" class=" 
					   btn btn-warning show_only_after_document_ready">
						  <i class="fa fa-key"></i>						  
					  </a>

EOH
	}
	else
	{
		$actions  .= <<"EOH";

			<a target="" disabled href="" data-placement="bottom" data-original-title="Récupérer le mot de passe" id="$id" role="button" class=" 
					   disabled btn btn-warning show_only_after_document_ready">
						  <i class="fa fa-key"></i>						  
					  </a>
EOH
	}

	# $actions .= "</div>";
	
	return $actions;

}

sub get_actions_members
{
	my $dbh = $_[0];
  my $id = $_[1];
	
	my %migcms_member = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
	
	my $actions = <<"EOH";
	<div class="btn-group_dis clearfix">
		<a target="_blank" href="members.pl?sw=member_login_db&stoken=$migcms_member{stoken}&url_after_login=/&clean_cookie=y" data-placement="top" data-original-title="Se connecter avec cet accès" id="$id" role="button" class=" 
				  btn btn-success $class show_only_after_document_ready">
					  <i class="fa fa-fw fa-sign-in" "> 
				  </i>
						  
				  </a>

EOH
	if($migcms_member{email} ne '' && $migcms_member{token} ne '' && $migcms_member{token2} ne '' )
	{
	}
	else
	{
		$actions  = <<"EOH";
	<div class="btn-group_dis clearfix">
		<a target="" disabled href="" data-placement="top" data-original-title="Aucun accès défini" id="" role="button" class=" 
				   disabled btn btn-success $class show_only_after_document_ready">
					  <i class="fa fa-fw fa-sign-in" "> 
				  </i>
						  
				  </a>

EOH
	}

	# LOST PASSWORD	# 
	if($migcms_member{email} ne '' && $migcms_member{token} ne '' && $migcms_member{token2} ne '' )
	{
		$actions  .= <<"EOH";

			<a target="_blank" href="members.pl?sw=lost_password_db&email=$migcms_member{email}" data-placement="top" data-original-title="Récupérer le mot de passe" id="$id" role="button" class=" 
					   btn btn-warning show_only_after_document_ready">
						  <i class="fa fa-key"></i>						  
					  </a>

EOH
	}
	else
	{
		$actions  .= <<"EOH";

			<a target="" disabled href="" data-placement="top" data-original-title="Récupérer le mot de passe" id="$id" role="button" class=" 
					   disabled btn btn-warning show_only_after_document_ready">
						  <i class="fa fa-key"></i>						  
					  </a>
EOH
	}

	$actions .= "</div>";
	
	
	
	
	return <<"EOH";
		$actions
EOH

}

sub change_statut
{
	my $id_member = get_quoted('id_member');
	my $value = get_quoted('statut_value');

	my %migcms_members = sql_line({dbh=>$dbh, table=>$dm_cfg{table_name}, where=>"id = '$id_member'"});

	if($migcms_members{id} > 0)
	{
		my %rec = (
			actif => $value,
		);

	  updateh_db($dbh,"migcms_members",\%rec,'id',$migcms_members{id});

	  #### Envoi d'un mail pour indiquer que le membre est validé ####
		send_validation_mail({member=>\%migcms_members});	
	}
	exit;
		
}

sub get_infos_members
{
	my $dbh = $_[0];
	my $id = $_[1];
	
	# Récupération du membre
	my %migcms_member = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});

	my $nom = $migcms_member{delivery_lastname};
	my $prenom = $migcms_member{delivery_firstname};
	my $societe = $migcms_member{delivery_company};
	my $nom_prenom = "";
	
	if($nom ne "" || $prenom ne "") {
		if($societe ne "") {
			$societe = "(".$migcms_member{delivery_company}.")";
		}
		$nom_prenom = <<"EOH";
		<strong>$nom $prenom $societe</strong><br />
EOH
	}
  
	return <<"EOH";
	$nom_prenom
	$migcms_member{email}
EOH

}

sub get_groups_members
{
	my $dbh = $_[0];
	my $id = $_[1];
	
	# Récupération du membre
	my %migcms_member = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
  
	return <<"EOH";
	
EOH

}

sub get_tags_members
{
	my $dbh = $_[0];
	my $id = $_[1];
	
	# Récupération du membre
	my %migcms_member = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
  
	return <<"EOH";
	
EOH

}


sub get_statut_members
{
	my $dbh = $_[0];
  my $id = $_[1];
	
	# Récupération du membre
	my %migcms_member = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});

	# NOTIFICATION SUR L'ENVOI DU MAIL
	my $email_validation_statut_sent = $migcms_member{email_validation_statut_sent};
	if($email_validation_statut_sent eq 'y')
	{
		$email_validation_statut_sent = '<span style="color:green"><i data-original-title="Email de confirmation envoyé" class="fa fa-envelope"></i> Email de confirmation envoyé</span>'
	}
	else
	{
		$email_validation_statut_sent = '<span style="color:#333"><i data-original-title="Email de confirmation non-envoyé" class="fa fa-envelope"></i> Email de confirmation non-envoyé</span>'
	}

	# STATUT DU MEMBRE
	my $actif;
	my $non_actif;
	if($migcms_member{actif} eq "y")
	{
		$actif = "selected";
	}
	else
	{
		$non_actif = "selected";
	}	
	
	
		my $liste_des_statuts = <<"EOH";
	<select class="form-control change_statut" id_member="$migcms_member{id}" name="change_statut">
		<option $actif  value="y">$migctrad{member_valid}</option>
		<option $non_actif  value="n">$migctrad{member_notvalid}</option>
	</select>
	
EOH

my $email_optin = <<"EOH";
	<span class="input-group-addon" style="color:black;">$config{col_email_optin_label}</span>
EOH

	my $email_optin_2 = <<"EOH";
	<span class="input-group-addon" style="color:black;">$config{col_email_optin_2_label}</span>
EOH

	if($migcms_member{email_optin} eq 'y')
	{
	$email_optin = <<"EOH";
	<span class="input-group-addon" style="background-color:green;color:white;">$config{col_email_optin_label}</span>
EOH
	}
	
	if($migcms_member{email_optin_2} eq 'y')
	{
	$email_optin_2 = <<"EOH";
	<span class="input-group-addon" style="background-color:green;color:white;">$config{col_email_optin_2_label}</span>
EOH
	}
		
	if($config{disable_members_email_optin} eq 'y')
	{
		$email_optin = $email_optin_2 = "";
	}
	
	if($config{email_optin_multisite} ne 'y') {
		$email_optin_2 = "";
	}
    
  return <<"EOH";
	$liste_des_statuts
	<center>$email_validation_statut_sent</center>
	<div class="input-group" style="margin-top:2.5px;height:34px;overflow:hidden;">
		$email_optin
		$email_optin_2
	</div>
EOH

}

sub get_optin_members
{
	my $dbh = $_[0];
	my $id = $_[1];
	
	# Récupération du membre
	my %migcms_member = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});

	my $email_optin = <<"EOH";
	<span class="input-group-addon" style="color:black;">$config{col_email_optin_label}</span>
EOH

	my $email_optin_2 = <<"EOH";
	<span class="input-group-addon" style="color:black;">$config{col_email_optin_2_label}</span>
EOH

	if($migcms_member{email_optin} eq 'y')
	{
	$email_optin = <<"EOH";
	<span class="input-group-addon" style="background-color:green;color:white;">$config{col_email_optin_label}</span>
EOH
	}
	
	if($migcms_member{email_optin_2} eq 'y')
	{
	$email_optin_2 = <<"EOH";
	<span class="input-group-addon" style="background-color:green;color:white;">$config{col_email_optin_2_label}</span>
EOH
	}
		
	if($config{disable_members_email_optin} eq 'y')
	{
		$email_optin = $email_optin_2 = "";
	}
	
	if($config{email_optin_multisite} ne 'y') {
		$email_optin_2 = "";
	}
  
  return <<"EOH";
	<div class="input-group" style="margin-top:-7.5px;height:34px;overflow:hidden;margin-bottom:-7.5px;">
		$email_optin
		$email_optin_2
	</div>
EOH

}

sub after_save
{
	my $dbh=$_[0];
  my $id=$_[1];

	#create token for all members
  my @members = sql_lines({dbh=>$dbh, table=>"migcms_members", where=>"token = '' OR token2 = ''"});
	foreach $member (@members)
	{
		my %member = %{$member};
		if($member{token} eq "")
		{
			my $new_token = create_token(50);
			my $stmt = <<"SQL";
				UPDATE migcms_members
					SET token = '$new_token'
					WHERE id = '$member{id}'
SQL
			execstmt($dbh, $stmt);
		}
		if($member{token2} eq "")
		{
			my $new_token = create_token(50);
			my $stmt = <<"SQL";
				UPDATE migcms_members
					SET token2 = '$new_token'
					WHERE id = '$member{id}'
SQL
			execstmt($dbh, $stmt);
		}
	}
	
	#create stoken for all members
    my @members = sql_lines({dbh=>$dbh, table=>"migcms_members", where=>"stoken = '' AND token != ''"});
	foreach $member (@members)
	{
		my %member = %{$member};
		if($member{stoken} eq "")
		{
			my $stoken = sha1_hex($member{token});
			my $stmt = <<"SQL";
				UPDATE migcms_members
					SET stoken = '$stoken'
					WHERE id = '$member{id}'
SQL
			execstmt($dbh, $stmt);
		}
	}
   
	my %member = sql_line({dbh=>$dbh, table=>"migcms_members", where=>"id = '$id'"});
	
	member_add_event({member=>\%member,type=>'admin_update',name=>"Le membre a été mis à jour par un administrateur",detail=>$user{id},erreur=>'',group=>'member'});

	
	my %eshop_setup = %{eshop::get_setup()};

	# Si la boutique est activée, on ajoute le bouton de TVA intracom
	my $do_not_add_intracom = "n";



	if($eshop_setup{shop_disabled} ne "y")
	{
	  manage_identities({id_member=>$id});
	}	

	

	#### Envoi d'un mail pour indiquer que le membre est validé ####
	send_validation_mail({member=>\%member});	
	if($dm_cfg{compute_gps} eq 'y')
	{
		compute_gps($id);
		
		my @recs = sql_lines({debug=>0,debug_results=>0,table=>$dm_cfg{table_name}, select=>"",where=>"(lat = '' OR lon = '') AND ($dm_cfg{col_zip} != '' OR $dm_cfg{col_city} != '')"});
		foreach $rec (@recs)
		{
			my %rec = %{$rec};
			compute_gps($rec{id});
		}	
	}
	fill_tags();

	#### Fonction d'after_save sur-mesure complémentaires ####
	if($members_setup{additionnal_after_save} eq "y")
	{
		def_handmade::members_additionnal_after_save({id_member=>$member{id}});
	}
		
}

sub manage_identities
{
	my %d = %{$_[0]};

	my $id_member = $d{id_member};
	my $are_same = get_quoted("are_same");

	###################
	#### DELIVERY #####
	###################
	my %identity_delivery = sql_line({dbh=>$dbh, table=>"identities", where=>"id_member = '$id_member' AND identity_type='delivery'"});

	my %update_identity_delivery = ();
	my @champs_identity = @{eshop::get_identities_fields()};	

	$update_identity_delivery{id_member} = $id_member;
	foreach my $champ_identity (@champs_identity)
	{
	  %champ_identity = %{$champ_identity};

	  # Récupération de la valeur du champ et si c'est vide on prend la valeur encodée dans l'onglet Coordonnées
		$update_identity_delivery{$champ_identity{name}} = get_quoted("identity_delivery_".$champ_identity{name}) || get_quoted("delivery_".$champ_identity{name});

	}
	$update_identity_delivery{identity_type} = 'delivery';
	$update_identity_delivery{token} = create_token(50);
	$update_identity_delivery{id_member} = $id_member;

	# récup de l'email si vide
	if($update_identity_delivery{email} eq "")
	{
		$update_identity_delivery{email} = get_quoted("email");
	}

	#formatage du pays si nécessaire (Champ récupéré de l'onglet Coordonnées)
	my @split_country = split("\/",$update_identity_delivery{country});
	if($split_country[2] ne "")
	{
		$update_identity_delivery{country} = $split_country[2];
	}
	
	my $id_delivery_identity = sql_set_data({debug=>0,dbh=>$dbh,table=>'identities',data=>\%update_identity_delivery,where=>"id_member='$update_identity_delivery{id_member}' AND identity_type='delivery'"});
	
	my $stmt = <<"SQL";
		UPDATE migcms_members
			SET id_delivery_identity = '$id_delivery_identity'
		WHERE id = '$id_member'
SQL
	execstmt($dbh, $stmt);

	#################
	#### BILLING ####
	#################
	my %identity_billing = sql_line({dbh=>$dbh, table=>"identities", where=>"id_member = '$id_member' AND identity_type='billing'"});
# 	if($are_same eq "y")
# 	{
# 		$update_identity_delivery{identity_type} = 'billing';
# 		my $id_billing_identity = sql_set_data({debug=>0,dbh=>$dbh,table=>'identities',data=>\%update_identity_delivery,where=>"id_member='$update_identity_delivery{id_member}' AND identity_type='billing'"});

# 		my $stmt = <<"SQL";
# 			UPDATE migcms_members
# 				SET id_billing_identity = '$id_billing_identity'
# 			WHERE id = '$id_member'
# SQL
# 		execstmt($dbh, $stmt);
# 	}
# 	else
	# {
		my %update_identity_billing = ();
		my @champs_identity = @{eshop::get_identities_fields()};	

		$update_identity_billing{id_member} = $id_member;
		foreach my $champ_identity (@champs_identity)
		{
		  %champ_identity = %{$champ_identity};
		  # Si pas encore d'identities, on récupère les données du client (Onglet Coordonnées) 
			$update_identity_billing{$champ_identity{name}} = get_quoted("identity_billing_".$champ_identity{name});

			if($are_same eq "y" && $update_identity_billing{$champ_identity{name}} eq "")
			{
			 $update_identity_billing{$champ_identity{name}} = get_quoted("delivery_".$champ_identity{name});
			}
		}
		$update_identity_billing{identity_type} = 'billing';
		$update_identity_billing{token} = create_token(50);
		$update_identity_billing{id_member} = $id_member;

		if($update_identity_billing{email} eq "")
		{
			$update_identity_billing{email} = get_quoted("email");
		}
		
		my $id_billing_identity = sql_set_data({debug=>0,dbh=>$dbh,table=>'identities',data=>\%update_identity_billing,where=>"id_member='$update_identity_billing{id_member}' AND identity_type='billing'"});
		
		my $stmt = <<"SQL";
			UPDATE migcms_members
				SET id_billing_identity = '$id_billing_identity'
			WHERE id = '$id_member'
SQL
		execstmt($dbh, $stmt);
	# }


	# Si pas encore d'identities, on en créé
# 	if(!$identity_delivery{id} > 0)
# 	{
# 		my @champs_identity = @{eshop::get_identities_fields()};
		

# 		$create_identity{id_member} = $new_id_member;
# 		foreach my $champ_identity (@champs_identity)
# 		{
# 		  %champ_identity = %{$champ_identity};  
# 		  $create_identity{$champ_identity{name}} = $member{"delivery_".$champ_identity{name}};
# 		  $create_identity{$champ_identity{name}} =~ s/\'/\\\'/g;
# 		}
# 		$create_identity{identity_type} = 'delivery';
# 		$create_identity{token} = create_token(50);
# 		$create_identity{id_member} = $id_member;
		
# 		my $id_delivery_identity = sql_set_data({debug=>0,dbh=>$dbh,table=>'identities',data=>\%create_identity,where=>"id_member='$create_identity{id_member}' AND identity_type='delivery'"});
		
# 		my $stmt = <<"SQL";
# 			UPDATE migcms_members
# 				SET id_delivery_identity = '$id_delivery_identity'
# 			WHERE id = '$id_member'
# SQL
# 		execstmt($dbh, $stmt);

# 		# Si les coordonnées de facturation sont identiques, on duplique
# 		if($are_same eq "y")
# 		{
# 			my $id_billing_identity = sql_set_data({debug=>0,dbh=>$dbh,table=>'identities',data=>\%create_identity,where=>"id_member='$create_identity{id_member}' AND identity_type='billing'"});
		
# 			my $stmt = <<"SQL";
# 				UPDATE migcms_members
# 					SET id_billing_identity = '$id_billing_identity'
# 				WHERE id = '$id_member'
# SQL
# 		execstmt($dbh, $stmt);
# 		}
# 	}	
	
# 	my %identity_billing = sql_line({dbh=>$dbh, table=>"identities", where=>"id_member = '$id_member' AND identity_type='billing'"});
# 	if(!$identity_billing{id} > 0 && $are_same ne "y")
# 	{
# 		my @champs_identity = @{eshop::get_identities_fields()};
# 		my %create_identity = ();

# 		$create_identity{id_member} = $new_id_member;
# 		foreach my $champ_identity (@champs_identity)
# 		{
# 		  %champ_identity = %{$champ_identity};  
# 		  $create_identity{$champ_identity{name}} = $member{$champ_identity{name}};
# 	   $create_identity{$champ_identity{name}} =~ s/\'/\\\'/g;
# 		}
# 		$create_identity{identity_type} = 'billing';
# 		$create_identity{token} = create_token(50);
# 		$create_identity{id_member} = $id_member;
		
# 		my $id_bill_identity = sql_set_data({debug=>0,dbh=>$dbh,table=>'identities',data=>\%create_identity,where=>"id_member='$create_identity{id_member}' AND identity_type='billing'"});
		
# 		my $stmt = <<"SQL";
# 			UPDATE migcms_members
# 				SET id_bill_identity = '$id_bill_identity'
# 				WHERE id = '$id_member'
# SQL
# 		execstmt($dbh, $stmt);
# 	}
}

sub compute_gps
{
	my $id = $_[0];
	my %rec = read_table($dbh,$dm_cfg{table_name},$id);
	my $street = $rec{$dm_cfg{col_street}};
	my $zip = $rec{$dm_cfg{col_zip}};
	my $city = $rec{$dm_cfg{col_city}};
	my $country = $rec{$dm_cfg{col_country}};
	if($country eq '' || uc($country) eq 'BE' || $country == 19)
	{
		$country = 'Belgique';
	}
	elsif(uc($country) eq 'FR')
	{
		$country = 'France';
	}
	my $adresse=" $street, $zip $city, $country ";
	$adresse =~ s/\r*\n//g;
	
	my $field_lat = $dm_cfg{col_lat};
	my $field_lon = $dm_cfg{col_lon};

	my $geocoder = Geo::Coder::Google->new(apiver => 3);
	my $location;
	log_debug($adresse);
	eval { $location = $geocoder->geocode(location => $adresse) };
	log_debug($adresse.' after eval');
	if($@)
	{
		log_debug('erreur pas localisé');
		
		my $adresse =" $zip, $country ";
		log_debug($adresse);
		my $geocoder = Geo::Coder::Google->new(apiver => 3);
		my $location;
		eval { $location = $geocoder->geocode(location => $adresse) };
		
		if($@)
		{
			log_debug('erreur pas localisé même raccourci');
			
			
		}
		else
		{
			my $latitude = $location->{geometry}{location}{lat};
			my $longitude = $location->{geometry}{location}{lng};  

			if($id ne "" && $latitude ne "" && $longitude ne "" && $field_lat ne "" && $field_lon ne "")
			{
				my $stmt =<<"EOH"; 
						  UPDATE $dm_cfg{table_name} 
						  SET $field_lat = '$latitude',
							  $field_lon = '$longitude',
							  migcms_moment_last_edit =NOW()
						  WHERE id='$id'
EOH
				log_debug($stmt);
				execstmt($dbh,$stmt);
			}
			else
			{
				log_debug('pas gps recu meme raccourci');
			} 
		}
	}
	else
	{

	  my $latitude = $location->{geometry}{location}{lat};
	  my $longitude = $location->{geometry}{location}{lng};  
	  log_debug('else2');
		  if($id ne "" && $latitude ne "" && $longitude ne "" && $field_lat ne "" && $field_lon ne "")
		  {
			my $stmt =<<"EOH"; 
					  UPDATE $dm_cfg{table_name} 
					  SET $field_lat = '$latitude',
						  $field_lon = '$longitude',
						  migcms_moment_last_edit =NOW()
					  WHERE id='$id'
EOH
			
			log_debug($stmt);
			execstmt($dbh,$stmt);
			
		  }
	    else
	    {
			log_debug('pas gps recu');
		} 
	}
	log_debug('fin after savbe');
}

#### Envoi d'un mail pour indiquer que le membre est validé ####
sub send_validation_mail
{
	my %d = %{$_[0]};

	my %member = %{$d{member}};

	#### Envoi d'un mail pour indiquer que le membre est validé ####
	if($member_setup{disabled_mailing_statut} eq "n"
	 	&& $member{actif} eq "y"
	 	&& $member{email_validation_statut_sent} eq "n"
	 	&& $member{email} ne ""
	 )
	{
		my $lg = 1;
		if($member{id_language} > 0)
		{
			$lg = $member{id_language};
		}
		elsif($member{language} ne "")
		{
			if($member{language} eq "NL")
			{
				$lg = 3;
			}
			elsif($member{language} eq "EN")
			{
				$lg = 2;
			}
		}		

		my %member_setup = %{member_get_setup({lg=>$lg})};
		# Récupération du contenu du mail
		
		my $mail_content = $member_setup{id_textid_mailing_statut};

		$member{firstname} = $member{firstname} || $member{delivery_firstname};
		$member{lastname}  = $member{lastname} || $member{delivery_lastname};
		$member{email}     = $member{email} || $member{delivery_email};

		$mail_content =~ s/{prenom}/$member{firstname}/g;
		$mail_content =~ s/{nom}/$member{lastname}/g;
		$mail_content =~ s/{email}/$member{email}/g;

		# Ajout du Header et Footer global au mail
		my %site_setup = %{setup::get_site_setup()};
    if($site_setup{use_site_email_template} eq "y")
    {
	    my $header = setup::get_migcms_site_emails_header({title=>$members_sitetxt{email_validation_object}, lg=>$lg});
			my $footer = setup::get_migcms_site_emails_footer({lg=>$lg});
			
			$mail_content = setup::get_migcms_site_email_content({content=>$mail_content});

    	$mail_content = $header . $mail_content . $footer;
    }
		

		if($config{custom_mail_validation_content} eq "y")
		{
		  $mail_content = def_handmade::get_custom_mail_validation_content({content=>$mail_content, member=>\%member, lg=>$lg}); 
		}

		my %members_sitetxt = %{get_members_txt($lg)};

		my $sender_mail = $member_setup{email_from}.' <'.$member_setup{email_from}.'>';

		send_mail($sender_mail,$member{email},$members_sitetxt{email_validation_object}, $mail_content, 'html');
		send_mail($sender_mail,'dev@bugiweb.com','COPIE BUGIWEB '.$members_sitetxt{email_validation_object}, $mail_content, 'html');

		my $stmt = <<"SQL";
		UPDATE migcms_members
			SET email_validation_statut_sent = 'y'
			WHERE id = '$member{id}'
SQL

		execstmt($dbh, $stmt);

	}
}

sub breadcrumb_func
{
	my $id_father = $_[0];
	my $url_home = $_[1];
	
	my $titre1 = 'Toutes les entreprises';
	my $titre2 = '';
	my $id_father = get_quoted('id_father');
	my $search_all = get_quoted('search_all');
	my %migcms_member = sql_line({table=>'migcms_members',where=>"id='$id_father'"});
	if($id_father > 0)
	{
		$titre1 =  '<a href="adm_migcms_members.pl?sel=1000219">Toutes les entreprises</a>';
		$titre2 = 'Liste des contacts de <b>'.$migcms_member{member_company}.'</b>';
	}
	if($search_all eq 'y')
	{
return <<"EOH";
	<ul class="breadcrumb panel">
	<li><a href="$config{baseurl}/cgi-bin/$url_home" data-original-title="$migctrad{backtohome}"><i class="fa fa-home"></i>$migctrad{home}</a></li>
	<li><a class="current" href="">Recherche sur tous les membres et les contacts...</a></li>
</ul>
EOH
	}
	return <<"EOH";
	<ul class="breadcrumb panel">
	<li><a href="$config{baseurl}/cgi-bin/$url_home" data-original-title="$migctrad{backtohome}"><i class="fa fa-home"></i>$migctrad{home}</a></li>
	<li><a class="" href="$dm_cfg{self}"><i class="$icon{name}"></i> $titre1</a></li>
	<li><a class="current" href="">$titre2</a></li>
</ul>
EOH
}

sub migcms_tr_color
{
	my $id = $_[1];
	my %d = %{$_[2]};
	
	my $actif = $d{line}{actif};

	my %corr_class=(
	'n' => '',
	'y' => 'success',
	);
	return <<"EOH";
	<tr id="$id" class="$corr_class{$actif} action_$actif rec_$id">
EOH
}

sub fill_tags
{

	my @records = sql_lines({table=>'migcms_members',where=>"tags = ''",ordby=>'id desc'});
	foreach $record (@records)
	{
		my %record = %{$record};
		
		my $tag = '';
		
		#langue*******************************************************
		my $id_language = $record{id_language};
		if($id_language > 0)
		{
		}
		else
		{
			if($record{language} eq 'NL')
			{
				$id_language = 3;
			}
			else
			{
				$id_language = 1;
			}
		}
		$tag .= ','.$id_language.',';
		
		
	
		my %update_record = 
		(
			tags => $tag,	
		);
		
		$stmt = "UPDATE `migcms_members` SET tags = '$tag' WHERE id = '$record{id}'";
		execstmt($dbh,$stmt);
	}
}

sub historique
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};


	my $acces = <<"EOH";
		<a class="btn btn-default" href="adm_migcms_members_events.pl?id_member=$id&sel=$sel" data-original-title="Voir l'historique" target="" data-placement="bottom">
		<i class="fa fa-history fa-fw"></i>
		</a>
EOH

	return $acces;
}

sub contacts
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};

	

	my $acces = <<"EOH";
		<a class="btn btn-default blue" href="adm_migcms_members.pl?id_father=$id&sel=$sel" data-original-title="Contacts" target="" data-placement="bottom">
		<i class="fa fa-users fa-fw"></i>
		</a>
EOH

	return $acces;
}

sub validation_func
{
	my $dbh  = $_[0];
	my %item = %{$_[1]};
	my $id   = $_[2];

	see(\%item);

	#MODIFICATION
	my $rapport = '';

	# Si c'est un ajout
	if(!($id > 0))
	{
		# On vérifie que l'email n'existe pas déjà en DB
		my %check_member = sql_line({dbh=>$dbh, table=>"migcms_members", where=>"email != '' AND email = '$item{email}'"});

		if($check_member{id} > 0)
		{
			$rapport .= '<tr><td><i class="fa fa-times"></i> E-Mail</td><td>Cette adresse E-mail existe déjà !</td></tr>';
		}
	}




	if($rapport ne '')
	{
		
		$rapport =<<"EOH";
		<h5><i class="fa fa-info"></i> Avant de sauvegarder,vous devez compléter/modifier certaines informations</u>:</h5>
		<table class="table table-hover table-striped table-bordered">
			<thead>
				<tr>
					<th>Onglet > champs</th>
					<th>Action à entreprendre</th>
				</tr>
			</thead>
			<tbody>
				$rapport				
			</tbody>
		</table>
EOH
		
		return 'validation_error___'.$rapport;
	}
	else
	{
		return '';
	}

}

