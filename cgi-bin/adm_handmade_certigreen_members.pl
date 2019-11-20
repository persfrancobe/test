#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use dm_publish_pdf;
use def_handmade;

$dbh_data = $dbh2 = $dbh;
my $id_member = get_quoted("id_member");
my $id = get_quoted("id");
 

$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 0;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_handmade_certigreen_members.pl?";
my $mine = get_quoted('mine') || 'n';
if($mine eq 'y')
{
	$dm_cfg{wherel} = "id_employe='$user{id}'"; #24
}

my $acces_full = 0;
if($user{id_role} > 0 && $user{id_role} < 9)
{
    $acces_full = 1;
}


$dm_cfg{validation_func} = \&validation_func;

$dm_cfg{table_name} = "members";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{hide_id} = 0;
 $dm_cfg{duplicate}='y';
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{default_ordby} = 'last_login desc';
if($acces_full) {
    $dm_cfg{'list_custom_action_17_func'} = \&impayes;
    $dm_cfg{'list_custom_action_1_func'} = \&loginas;
}
else
{
    $dm_cfg{'list_custom_action_1_func'} = \&loginascommercial;
}


my %client = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"id='$id'"});

%type_member = (
    '01/Agence'=>"Agence",
    '02/Notaire'=>"Notaire",
    '03/Particulier'=>"Particulier",
);

# %type_agence = (
    # 'agence'=>"Agence",
    # 'notaire'=>"Notaire",
# );

my $cpt = 9;
my $tab = 'Client';

@dm_nav =
(
	 {
		'tab'=>'Client',
		'type'=>'tab',
		'title'=>'Client'
	}
	,
	 {
		'tab'=>'PJ',
		'type'=>'tab',
		'title'=>'Pièces jointes',
		 'disable_add'=>'1'
	}
		
);

$dm_cfg{list_html_top} .= def_handmade::get_denom_style_et_js();

%dm_dfl = 
(
	sprintf("%05d", $cpt++).'/civilite_id'=>{'title'=>'Civilité','class'=>$line_class='line_facturation ','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'migcms_codes','lbkey'=>'id','lbdisplay'=>'v1','lbwhere'=>"id_code_type='1' and visible='y'",'lbordby'=>"v1",'fieldvalues'=>\%type_agence,'hidden'=>0},

	sprintf("%05d", $cpt++).'/lastname'=>{'title'=>'Nom','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/firstname'=>{'title'=>'Prénom','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/vat'=>{'default_value'=>'N.A.','title'=>'TVA','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/type_member'=>{'default_value'=>'Particulier','title'=>'Type','translate'=>0,'fieldtype'=>'listbox','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_member,'hidden'=>0},
	# sprintf("%05d", $cpt++).'/type_agence'=>{'title'=>'Agence ou notaire ?','translate'=>0,'fieldtype'=>'listbox','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/id_employe'=>{'default_value'=>'25','title'=>'Propriétaire','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'users','lbkey'=>'id','lbdisplay'=>"CONCAT(firstname,' ',lastname)",'lbwhere'=>"id_role='8'",'lbordby'=>"firstname,lastname",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/street'=>{'title'=>'Rue','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/number'=>{'title'=>'Numéro','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/zip'=>{'title'=>'Code postal','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/city'=>{'title'=>'Ville','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/tel'=>{'title'=>'Téléphone','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/email'=>{'title'=>'Email','translate'=>0,'fieldtype'=>'text','data_type'=>'email','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/password'=>{'title'=>'Mot de passe','translate'=>0,'fieldtype'=>'text','data_type'=>'password','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/id_agence'=>{'title'=>'Agence','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>('CONCAT(members.lastname," ",members.firstname)'),'lbwhere'=>"type_member = 'Agence' and lastname != ''",'lbordby'=>"",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/id_agence2'=>{'title'=>'Agence 2','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => '','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>('CONCAT(members.lastname," ",members.firstname)'),'lbwhere'=>"type_member = 'Agence' and lastname != ''",'lbordby'=>"",'fieldvalues'=>\%type_agence,'hidden'=>0},
#	sprintf("%05d", $cpt++).'/id_agence3'=>{'title'=>'Agence 3','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => '','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>('CONCAT(members.lastname," ",members.firstname)'),'lbwhere'=>"type_member = 'Agence' and lastname != ''",'lbordby'=>"",'fieldvalues'=>\%type_agence,'hidden'=>0},
	# sprintf("%05d", $cpt++).'/last_login'=>{'title'=>'Dernière connexion','translate'=>0,'fieldtype'=>'text','data_type'=>'datetime','search' => '','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/fusion_short'=>{'title'=>'Fusion courte','translate'=>0,'fieldtype'=>'display','data_type'=>'','search' => '','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>1},
	sprintf("%05d", $cpt++).'/fusion'=>{'title'=>'Fusion','translate'=>0,'fieldtype'=>'display','data_type'=>'','search' => '','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>1},
	sprintf("%05d", $cpt++).'/pj'=>{'disable_add'=>'1','title'=>'Pièces jointes','translate'=>0,'fieldtype'=>'files_admin','data_type'=>'','search' => '','mandatory'=>{"type" => ''},tab=>'PJ','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
);

$cpt=9;

%dm_display_fields = 
(
	sprintf("%05d", 1)."/Dernière conn"=>"last_login",
	sprintf("%05d", 3)."/Type"=>"type_member",
	sprintf("%05d", 4)."/Type d'agence"=>"type_agence",
);



%dm_lnk_fields = 
(
sprintf("%05d", 2)."/Nom/denom"=>"denom*",
sprintf("%05d", 5)."/Agence/denom_agence"=>"denom_agence*",
);

%dm_mapping_list = 
(
"denom" => \&denom,
"denom_agence" => \&denom_agence,
);

sub after_save_all
{
	see();
	my @recs = sql_lines({select=>'id',table=>$dm_cfg{table_name},where=>""});
	foreach $rec (@recs)
	{
		my %rec = %{$rec};	
		after_save($dbh,$rec{id});
	}
	exit;
}

sub after_save
{
    my $dbh=$_[0];
    my $id=$_[1];
	
	my $fusion = denom($dbh,$id);
	my $fusion_short = denom($dbh,$id,'short'); 
	
	$fusion =~ s/\'/\\\'/g;
	$fusion_short =~ s/\'/\\\'/g;
	
	my $stmt = <<"EOH";
		UPDATE members SET fusion = '$fusion',fusion_short='$fusion_short' WHERE id = '$id'
EOH
	log_debug($stmt,'','after_save');

	execstmt($dbh,$stmt);

	my $stmt = <<"EOH";
		UPDATE members SET last_login = NOW() WHERE id = '$id' and last_login = '0000-00-00'
EOH
	log_debug($stmt,'','after_save');

	execstmt($dbh,$stmt);

	
	
	my $stmt = <<"EOH";
		UPDATE members SET password = 'd3b05f624a2ab2323882a053662a2729aa990ec7' WHERE password = ''
EOH
	log_debug($stmt,'','after_save');

	execstmt($dbh,$stmt);

log_debug('after_save_certi_membre','','after_save_certi_membre');
	my @members = sql_lines({dbh=>$dbh, table=>"members", where=>"token = ''"});
	foreach $member (@members)
	{
		my %member = %{$member};

		log_debug($member{id},'','after_save_certi_membre');
		see(\%member);
		if($member{token} eq "")
		{
			my $new_token = create_token(50);
			my $stmt = <<"SQL";
				UPDATE members
					SET token = '$new_token'
					WHERE id = '$member{id}'
SQL
			log_debug($stmt,'','after_save_certi_membre');
			execstmt($dbh, $stmt);
		}
	}



	
}

sub denom_agence
{
	my $dbh = $_[0];
	my $id = $_[1];
	my $type = $_[2] || 'long';
	
	my %rec = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
	return def_handmade::denom($dbh,$rec{id_agence});
}




%dm_filters = (
 "60/Notaire ou Agence"=>
{
	'type'=>'lbtable',
	'table'=>'members',
	'key'=>'id',
	'display'=>"CONCAT(UPPER(lastname),' ',firstname)",
	'col'=>'id_agence',
	'where'=>"type_member = 'Agence'"
}
,
"70/Propriétaire"=>
{
	'type'=>'lbtable',
	'table'=>'users',
	'key'=>'id',
	'display'=>"CONCAT(firstname,' ',lastname)",
	'lbordby'=>"ordby",
	'col'=>'id_employe',
	'where'=>"id_role='8' and id != '25'"
}

		);		


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

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar("$colg_menu ");
    $spec_bar = get_spec_buttonbar($sw);
	
	
    my $js = <<"EOH";
		
		<script type="text/javascript">
						
			jQuery(document).ready( function () 
			{     			
				jQuery('#dm_button_del').show();
				jQuery('#dm_button_dupl').hide();
				jQuery('#dm_button_add').show().html("Nouveau client");

				jQuery(document).on("click", ".send_by_email_impayes", send_by_email_impayes);

			});



function send_by_email_impayes()
{
	console.log('clic send_by_email_impayes');
	scrollbarposition = jQuery(document).scrollTop();
	var token = jQuery(this).attr('data-token');

	jQuery("#edit_form_container").html('Chargement...');


	swal({
   		title: "Envoyer les impayes à ce membre ? ",
   		text: "Le membre recevra toutes les commandes auquel il est attaché et qui sont impayées.",
   		type: "warning",
   		showCancelButton: true,
   		confirmButtonColor: "#DD6B55",
   		confirmButtonText: "Oui, envoyez le !",
   		cancelButtonText: "Non, ne rien faire",
   		closeOnConfirm: false,
   		closeOnCancel: false },
   		function(isConfirm)
   		{
			if (isConfirm)
			{

				swal({title:"Envoi programmé !", text:"L'envoi a été enregistré. Celui-ci partira dans moins d'une minute.", type:"success"});

				var request = jQuery.ajax(
				{
					url: 'https://www.certigreen.be/public/receive-billing-data/'+token,
					type: "GET",
					dataType: "html"
				});

				request.done(function(content)
				{
					get_list_body();
				});

			}
			else
			{
				swal({title:"Annulé", text:"L'envoié a été annulé", type:"error", timer: 2000});
			}
		}
		);

	return false;




}
			
		</script>
EOH
	
	
    print wfw_app_layout($js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}

sub cure_duplicate_email
{
	see();
	my @emails_dedoubles = sql_lines({table=>"members",select=>"count(*) as nb, email",where=>"1 group by email having  nb > 1 and email != ''"});
	foreach $email_dedouble (@emails_dedoubles)
	{
		my %email_dedouble = %{$email_dedouble};
		
		execstmt($dbh, "UPDATE members SET email_info=email where email = '$email_dedouble{email}'");	
		execstmt($dbh, "UPDATE members SET email = CONCAT(email,'_',id) where email = '$email_dedouble{email}'");	
	}
	exit;
}

sub validation_func
{
	my $dbh=$_[0];
    my %item = %{$_[1]};
	my $id = $_[2];
	
	my $rapport = '';
	my $valide = 1;

	if($item{email} ne '')
	{
		#si email rempli: doit être unique !
		my %check_email = sql_line({select=>"id",table=>"members",where=>"email='$item{email}' AND id != '$id'"});
		if($check_email{id} > 0)
		{
			$valide = 0;
			$rapport .=<<"EOH";
			<tr><td><i class="fa fa-times"></i>Client > Email</td><td>L'email renseigné est déjà utilisé pour membre N°$check_email{id}. L'email servant d'identifiant de connexion, celui-ci doit être unique.</td></tr>
EOH
		}		
	}
	
	
	if($rapport ne '')
	{
		log_debug('rapport:'.$rapport,'','validation');
		
		$rapport =<<"EOH";
		<h5><i class="fa fa-info"></i> Avant de sauvegarder,vous devez compléter certaines informations obligatoires pour les contacts d'<u>ALIAS Consult</u>:</h5>
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

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

sub loginas
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});

	my $self = "$config{baseurl}/public/auto-connexion/$record{token}";
	return <<"EOH";

		<a href="$self" data-funcpublish="" data-placement="bottom" target="_blank"
		 data-original-title="Se connecter entant que $record{lastname} $record{firstname} $record{id}" role="button" class="btn btn-default show_only_after_document_ready ">
		 <i class="fa fa-key  fa-fw" data-original-title="" title=""></i></a>
EOH
}

sub loginascommercial
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});

	my $self = "$config{baseurl}/public/auto-c/$record{token}";
	return <<"EOH";

		<a href="$self" data-funcpublish="" data-placement="bottom" target="_blank"
		 data-original-title="Se connecter entant que $record{lastname} $record{firstname} $record{id}" role="button" class="btn btn-default show_only_after_document_ready ">
		 <i class="fa fa-key  fa-fw" data-original-title="" title=""></i></a>
EOH
}

sub impayes
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};
	my $acces = <<"EOH";
		<a href="#" data-placement="bottom" data-original-title="Envoyer les impayés"
		id="$id" role="button" class="btn btn-danger show_only_after_document_ready send_by_email_impayes" data-token="$record{token}">
		 <i class="fa fa-euro  fa-fw" data-original-title="" title=""></i>  </a>
EOH
	return $acces;
}