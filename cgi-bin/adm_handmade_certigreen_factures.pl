#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;



use Data::Dumper;
use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;
use def_handmade;


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$colg = get_quoted('colg') || $config{default_colg} || 1;
my $full_self = "$config{baseurl}/cgi-bin/adm_handmade_certigreen_factures.pl?lg=$lg&extlink=$extlink";

my $id_record = get_quoted("commande_id");
my $id_member = get_quoted("id_member");
# $dm_cfg{send_by_mail_less_pj} = 1;
$dm_cfg{add} = 0;
$dm_cfg{delete} = 0;
$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
if($id_record > 0)
{
	$dm_cfg{wherel} = "id_record='$id_record'";
}
if($id_member > 0)
{
	$dm_cfg{wherel} = "id_member='$id_member'";
}
$dm_cfg{validation_func} = \&validation_func;


$dm_cfg{corbeille} = 0;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_handmade_certigreen_factures.pl?";
$dm_cfg{table_name} = "intranet_factures";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{lock_on} = 1;
$dm_cfg{lock_off} = 1;
$dm_cfg{show_id} = 1;
$dm_cfg{hide_id} = 0;
$dm_cfg{default_ordby}='id desc';
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;

$dm_cfg{custom_style_for_contextual_actions} = 'width:50px';
$dm_cfg{custom_add_button_icon} = '<i class="fa fa-fw fa-arrow-circle-o-right "></i>';$dm_cfg{custom_add_button_txt} = 'Sauvegarder + Etape suivante';
$dm_cfg{custom_add_button_id} = 'details_doc';
$dm_cfg{custom_edit_button_txt} = '<i class="fa fa-fw fa-arrow-circle-o-right "></i>';$dm_cfg{custom_add_button_txt} = 'Sauvegarder + Etape suivante';
$dm_cfg{custom_edit_button_id} = 'details_doc';
$dm_cfg{pdfzip} = 1;

$dm_cfg{line_func} = \&migcms_tr_color;


$dm_cfg{func_publish} = 'ajax_make_pdf_facture';
$dm_cfg{telecharger} = 1;
$dm_cfg{email} = 1;
$dm_cfg{edit} = 0;
$dm_cfg{viewpdf} = 1;
$dm_cfg{excel} = 1;
$dm_cfg{lock_on} = 0;
$dm_cfg{lock_off} = 0;
$dm_cfg{send_by_email_table_license} = 'handmade_certigreen_licenses';
$dm_cfg{send_by_email_field1_license} = 'license_name';
$dm_cfg{send_by_email_field2_license} = 'email';
$dm_cfg{send_by_email_table_destinataire} = 'members';
$dm_cfg{send_by_email_col_destinataire} = 'id_member';
$dm_cfg{send_by_email_field1_destinataire} = 'lastname';
# $dm_cfg{send_by_email_field2_destinataire} = 'CTMTYPE';
$dm_cfg{send_by_email_field_email_destinataire} = 'email';
# $dm_cfg{send_by_email_id_template} = 20;
# $dm_cfg{list_custom_action_1_title} = 'Créditer la facture';
# $dm_cfg{list_custom_action_1_icon} = '<i class="fa fa-eur fa-fw"></i>';
# $dm_cfg{list_custom_action_1_class} = 'confirm_nc btn-danger';
# $dm_cfg{list_custom_action_1_ok_only_if_file_not_lock} = 0;  

$dm_cfg{'list_custom_action_15_func'} = \&custom_crediter_facture;
$dm_cfg{list_html_top} .= $js.def_handmade::get_denom_style_et_js();


$dm_cfg{custom_global_action_title} = 'Envoyer un rappel';
$dm_cfg{custom_global_action_func} = 'rappel1';
$dm_cfg{custom_global_action_icon} = '<i class="fa fa-envelope-o"></i> Rappel 1';

$dm_cfg{custom_global_action2_title} = 'Envoyer un rappel';
$dm_cfg{custom_global_action2_func} = 'rappel2';
$dm_cfg{custom_global_action2_icon} = '<i class="fa fa-envelope-o"></i> Rappel 2';

$dm_cfg{custom_global_action3_title} = 'Envoyer un rappel';
$dm_cfg{custom_global_action3_func} = 'rappel3';
$dm_cfg{custom_global_action3_icon} = '<i class="fa fa-envelope-o"></i> Rappel 3';

$dm_cfg{'list_custom_action_2_func'} = \&reglements;
$dm_cfg{'list_custom_action_16_func'} = \&ncs;


my $document_name = 'intranet_factures';


$dm_cfg{file_prefixe} = 'FC0';
$dm_cfg{send_by_email_col_docname} = $doc_names{$doc_tables{lc($dm_cfg{file_prefixe})}};
$dm_cfg{send_by_email_col_prefixe} = 'id_handmade_certigreen_marque_facture';
# $dm_cfg{send_by_email_col_prefixe_lbtable} = 'handmade_certigreen_marques';
# $dm_cfg{send_by_email_col_prefixe_lbdisplay} = 'nom';
$dm_cfg{send_by_email_col_suffixe} = 'id_member';
$dm_cfg{send_by_email_col_suffixe_lbtable} = 'members';
$dm_cfg{send_by_email_col_suffixe_lbdisplay} = 'lastname';
# $dm_cfg{send_by_email_col_suffixe_lbdisplay_prefixe} = 'cef';
$lbdisplay_code = 'fv';

# my $nb_lignes_facture_details = 10;
# my $taux_tva = 0.21;

$dm_cfg{page_title} = "Factures";
$dm_cfg{add_title} = "Créer une facture ";

%statut = (
    '01/brouillon'=>"brouillon",
	'02/emise'=>"emise",
    '03/payee'=>"payee",
    '04/creditee correction'=>"creditee correction",
	'05/creditee résiliation'=>"creditee résiliation",
);


%periodicite = (
    '01/1'=>"Mensuelle",
	'02/12'=>"Annuelle",
);	

%type = (
    '01/unique'=>"Unique",
	'02/recurrente'=>"Récurrente",
);	


@dm_nav =
	(
		 {
			'tab'=>'document',
			'type'=>'tab',
			'title'=>'Document'
		}
		# ,
		 # {
			# 'tab'=>'ventilation',
			# 'type'=>'tab',
			# 'title'=>'Ventilation'
		# }	
,
		 {
			'tab'=>'factures-reglements',
			'type'=>'tab',
			'title'=>'Reglements',
			'cgi_func' => 'def_handmade::factures_reglements',
			'disable_add' => 1
		}
,
	{
		'type'=>'tab',
		'title'=>'Coord. client',
		'tab'=>'cli',
		'disable_add'=>0,
	}		
	);
# see();
			

			
			


my $cpt = 5;

$dm_cfg{default_tab} = 'document';
#my $next_number_invoice = intranet_factures_get_next_number($annee);

%dm_dfl = 
(
	sprintf("%05d", $cpt++).'/numero'=>{'title'=>'Numéro',
			'default_value'=>$next_number_invoice,

	'mask'=>'9999999999999','importcode'=>'1','translate'=>0,'list_edit'=>0,'list_edit_clean_prefixe'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => 'not_empty'},tab=>$tab,'lbtable'=>'handmade_certigreen_delais_facturation','lbkey'=>'id','lbdisplay'=>'nom','lbwhere'=>"",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},

	sprintf("%03d", $cpt++).'/id_member'=> 
	{
        'title'=>'Lien client',
        'fieldtype'=>'listboxtable',
        'data_type'=>'autocomplete',
		 'lbtable'=>'members',
         'lbkey'=>'id',
		 		'search' => 'y',
         'lbdisplay'=>"fusion_short",
         'lbwhere'=>"" ,
		'mandatory'=>
		{"type" => 'not_empty',
		}
		
    }
	,
	sprintf("%03d", $cpt++).'/id_record'=> 
	{
        'title'=>'Lien commande',
        'fieldtype'=>'listboxtable',
        'data_type'=>'autocomplete',
		 'lbtable'=>'intranet_factures',
         'lbkey'=>'id',
		 		'search' => 'y',
         'lbdisplay'=>"CONCAT(migcms_id,' ',fusion_short)",
         'lbwhere'=>"" ,
		'mandatory'=>
		{"type" => '',
		}
		
    }
	,
	# sprintf("%05d", $cpt++).'/id_pdi'=>{'title'=>'PDI','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'handmade_certigreen_points_interets','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0}
	,
 sprintf("%03d", $cpt++).'/date_facturation'=> 
{
	'title'=>'Date',
	'fieldtype'=>'text',
	'data_type'=>'date',
	'search' => 'y',
	default_value => $today,
	'hidden'=>0 ,
		'mandatory'=>
		{"type" => 'not_empty',
		}
},
	sprintf("%05d", $cpt++).'/delai'=>{'title'=>'Délai','importcode'=>'1','translate'=>0,'list_edit'=>0,'list_edit_clean_prefixe'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'handmade_certigreen_delais_facturation','lbkey'=>'id','lbdisplay'=>'nom','lbwhere'=>"",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/delai_autre'=>{'disable_add'=>1,'title'=>'Autre délai','importcode'=>'1','translate'=>0,'list_edit'=>0,'list_edit_clean_prefixe'=>0,'fieldtype'=>'text','mask'=>'999','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'handmade_certigreen_delais_facturation','lbkey'=>'id','lbdisplay'=>'nom','lbwhere'=>"",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
 sprintf("%03d", $cpt++).'/date_echeance'=> 
{
	'title'=>'Echéance',
	'fieldtype'=>'text',
	'data_type'=>'date',
	'search' => 'y',
	'hidden'=>0,
	'disable_add'=>1,
}
	,
	sprintf("%03d", $cpt++).'/montant_a_payer_htva'=> 
    {
		'title'=>'Total HTVA',
		'fieldtype'=>'display',
		'data_type'=>'euros',
		'hidden'=>0 ,
		'disable_add'=>1,
		'mandatory'=>
		{"type" => '',
		}
    }
	
	 ,
	sprintf("%03d", $cpt++).'/montant_a_payer_tvac'=> 
    {
		'title'=>'Total TVAC',
		'fieldtype'=>'display',
		'data_type'=>'euros',
		'disable_add'=>1,
		'hidden'=>0 ,
		'mandatory'=>
		{"type" => '',
		}
    }
		,
	sprintf("%03d", $cpt++).'/reference'=> 
	{
        'title'=>'Référence',
        'fieldtype'=>'text',
		'search' => 'y',

    }
	 ,
	sprintf("%05d", $cpt++).'/statut'=>{"default_value"=>2,'title'=>'Statut','importcode'=>'1','translate'=>0,'list_edit'=>0,'list_edit_clean_prefixe'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'y','mandatory'=>{"type" => 'not_empty'},tab=>$tab,'lbtable'=>'handmade_certigreen_statuts_facturation','lbkey'=>'id','lbdisplay'=>'nom','lbwhere'=>"",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
	sprintf("%03d", $cpt++).'/id_type_reglement'=>{'hide_update'=>0,'default_value'=>'5','title'=>"Déjà payé par",'legend'=>'Ajoute automatiquement un règlement pour cette facture si elle n\'en a pas encore','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},'tab'=>$tab,'lbtable'=>'handmade_certigreen_statuts_reglement','lbkey'=>'id','lbdisplay'=>"nom",'lbwhere'=>"",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},

 sprintf("%03d", $cpt++).'/remarque'=> 
{
	'title'=>'Remarque',
	'fieldtype'=>'textarea',
}
,
	sprintf("%05d", $cpt++).'/facture_civilite_id'=>{'title'=>'Civilité','class'=>$line_class='line_facturation ','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>'cli','lbtable'=>'migcms_codes','lbkey'=>'id','lbdisplay'=>'v1','lbwhere'=>"",'lbordby'=>"v1",'fieldvalues'=>\%type_agence,'hidden'=>0}


# ,
	 # '31/societe_f'=> 
    # {
		# 'title'=>'Société',
		# 'fieldtype'=>'text',
		# 'search'=>'y',
		# 'tab'=>'cli',
    # }
	,
	 '32/tva_f'=> 
    {
		'title'=>'TVA',
		'fieldtype'=>'text',
		'search'=>'y',
		'default_value'=>'N.A.',
		'tab'=>'cli',
    }
	,
	 '33/nom_f'=> 
    {
		'title'=>'Nom',
		'fieldtype'=>'text',
		'search'=>'y',
		'tab'=>'cli',
    }
	# ,
	 # '34/contact_f'=> 
    # {
		# 'title'=>'Contact',
		# 'fieldtype'=>'text',
		# 'search'=>'n',
		# 'tab'=>'cli',
    # }
	,
	 '35/adresse_f'=> 
    {
		'title'=>'Adresse',
		'fieldtype'=>'text',
		'search'=>'n',
		'tab'=>'cli',
    }
	,
	 '36/ville_f'=> 
    {
		'title'=>'Ville',
		'fieldtype'=>'text',
		'search'=>'n',
		'tab'=>'cli',
    }
	,
	'37/pays_f'=> 
    {
		'title'=>'Pays',
		'default_value'=>'Belgique',
		'fieldtype'=>'text',
		'search'=>'n',
		'tab'=>'cli',
    }
);

%dm_display_fields = 
(
	"01/Numéro"=>"numero",
	# "02/Société"=>"societe_f",
	"03/Nom"=>"nom_f",
	"04/TVA"=>"tva_f",
	"08/Date fac"=>"date_facturation",
	"09/Date ech"=>"date_echeance",
	"10/NbJEch"=>"nbjours_echeance",
	"11/TTC"=>"montant_a_payer_tvac",
	"12/Statut"=>"statut",
);





%dm_lnk_fields = 
(
# "06/Statut/col_statut"=>"stat*",
# sprintf("%02d", 20)."/Client/denom"=>"denom_client_agence*",

"05/Commande/commande_col_adresse"=>"commande_col_adresse*",



);

%dm_mapping_list = (
# "stat" => \&getstatut,
# "denom_client_agence" => \&denom_client_agence,
"commande_col_adresse" => \&commande_col_adresse_facture,


);


$dm_cfg{list_html_top} .= <<"EOH";
<style>
.col_identifiant,.cms_mig_cell_id 
{
	display:nonea;
}
.col_statut
{
	width:120px;
}
</style>

<input type="hidden" class="prefixe" name="prefixe" value="$doc_prefixes{$document_name}" />
<script src="$config{baseurl}/custom_skin/js/certigreen_intranet_handmade.js"></script>
<input type="hidden" class="type type_document" value="facture" />


<span id="infos_rec"></span>
<script type="text/javascript">
jQuery(document).ready(function() 
{
	jQuery('.maintitle,.breadcrumb').hide();
	jQuery(document).on("click", ".dm_migedit", dm_migedit_members);
	jQuery(document).on("click", ".cancel_edit ", removenomexposant);
	jQuery(document).on("click", ".admin_edit_save ", removenomexposant);
});


function dm_migedit_members()
{
	
	jQuery('#infos_rec').html('...');
	jQuery('#infos_rec').removeClass('hide');
	jQuery.ajax(
	  {
		 type: "POST",
		 url: self,
		 data: "&sw=ajax_infos_rec&t=$dm_cfg{table_name}&id="+jQuery(this).attr('id'),
		 success: function(msg)
		 {
			jQuery('#infos_rec').html(msg);	
		 }
	  });	
		  
}

function removenomexposant()
{
	jQuery('#infos_rec').html('');
}
</script>



<script>	  
	jQuery(document).ready(function() 
	{
		init_button_document('$document_name');
		/*jQuery(document).on("click", ".send_mail_screen", send_mail_screen);*/
		jQuery(document).on("change", ".change_statut", change_statut);
	});
	
	function change_statut()
{
	var me = jQuery(this);
	var statut_value = me.val();
	var id_facture = me.attr('id_facture');	

	console.log("Statut :" + statut_value);
	console.log("id_facture :" + id_facture);
	
	var request = jQuery.ajax(
	{
		url: self,
		type: "GET",
		data: 
		{
			sw : 'change_statut',
			statut_value : statut_value,
			id_facture : id_facture,
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
<style>
.list_action,.widget-header-actions, .mig_cb_col, .td-input
{
	/*display:none !important;*/
}
</style>




<script type="text/javascript">
jQuery(document).ready(function() 
{
	jQuery(document).on("click", ".dm_migedit", nomexposant);
	jQuery(document).on("click", ".cancel_edit ", removenomexposant);
	jQuery(document).on("click", ".admin_edit_save ", removenomexposant);
});
function nomexposant()
{
	var idnomexposant = jQuery(this).attr('id');
	var ligne = jQuery('tr.rec_'+idnomexposant);
	var cms_mig_cell_numero   = ligne.children('.cms_mig_cell_numero').html();
	var cms_mig_cell_nom_f    = ligne.children('.cms_mig_cell_nom_f ').html();
	var commande_col_adresse   = ligne.children('.commande_col_adresse').html();
	
	jQuery('#nomexposant').html(cms_mig_cell_numero+' '+cms_mig_cell_nom_f+' '+commande_col_adresse);
}
function removenomexposant()
{
	jQuery('#nomexposant').html('Liste des factures');
}
</script>
EOH



%dm_filters = (
# "1/Statut"=>
# {
      # 'type'=>'hash',
	     # 'ref'=>\%statut,
	     # 'col'=>'statut'
# }
# ,
"2/Dates"=>{
'type'=>'fulldaterange',
'col'=>'date_facturation',
}
,
	"3/Client"=>
	{
		'type'=>'lbtable',
		'table'=>'members',
		'key'=>'id',
		'display'=>'fusion_short',
		'ordby'=>'fusion_short',
		'where'=>'id IN (select distinct(id_member) from intranet_factures)',
		'col'=>'id_member',
	}
,
	"4/Statut"=>
	{
		'type'=>'lbtable',
		'table'=>'handmade_certigreen_statuts_facturation',
		'key'=>'id',
		'display'=>'nom',
		'ordby'=>'ordby',
		'col'=>'statut',
	}

);


$sw = $cgi->param('sw') || "list";
if($sw ne 'download_pdf' && $sw ne 'publi' && $sw ne '' && $sw ne 'intranet_get_facture')
{
	see();
}


my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
			facturier
			fac
			
			
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();

    print wfw_app_layout($js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}



sub getactions
{
    my $dbh = $_[0];
    my $id = $_[1];
	
	my %facture = sql_line({table=>'intranet_factures',where=>"id='$id'"});
	my %doc = sql_line({debug=>0,table=>'intranet_documents',where=>"table_record = '$facture{table_record}' AND id_record='$facture{id_record}'"});

	my $libelle = 'FC0'.$facture{numero};
	my $tdoc = $doc_prefixes{$facture{table_record}};
	
	if($tdoc eq '')
	{
		$tdoc = 'fc0';
	}
	 
	
	
	$telecharger_facture = <<"EOH";
		<!-- PRINT -->
		<a class=" btn-default btn btn-success " 
		href="$dm_cfg{self}&sw=download_pdf&type=facture&id=$facture{id_record}&id_fac=$id&scolg=$colg&tdoc=$tdoc" 
		data-original-title="Voir/Imprimer" title="">
			<span class="fa-fw fa fa-eye"></span>
		</a>
EOH

my $modifier_facture = '';
if($facture{statut} eq 'brouillon')
{
	$modifier_facture .= <<"EOH";
	<a href="#" data-placement="top" data-original-title="Modifier (Ref#$id)" id="$id" role="button" class=" animate_gear
				  btn btn-info show_only_after_document_ready migedit_$id migedit">
					  <i class="fa fa-fw fa-gear ">
				  </i>
						  
				  </a>
EOH
}
# elsif($facture{statut} ne 'brouillon')
# {
	# $telecharger_facture .= <<"EOH";
	# <a href="#" data-placement="top" data-original-title="Modifier (Ref#$id)" id="$id" role="button" class=" animate_gear
				  # btn btn-default show_only_after_document_ready migedit_$id migedit">
					  # <i class="fa fa-fw fa-gear ">
				  # </i>
						  
				  # </a>
# EOH
# }
	
	return <<"EOH";
		
		$telecharger_facture
		
			
			
			
		

EOH


}


sub get_actions_facture
{
	my $dbh = $_[0];
    my $id = $_[1];
	
	my $sel = get_quoted('sel');
	my %facture = sql_line({table=>'intranet_factures',where=>"id='$id'"});
	my %doc = sql_line({debug=>0,table=>'intranet_documents',where=>"table_record = '$facture{table_record}' AND id_record='$facture{id_record}'"});
	my %migcms_role = sql_line({debug=>$debug,debug_results=>$debug,table=>"migcms_roles",where=>"id='$user{id_role}' and visible='y' and token != ''"});

	my $tdoc = $doc_prefixes{$facture{table_record}};
	
	my $libelle = dm::getcode($dbh,$facture{numero},'fc0');
	
	if($tdoc eq '')
	{
		$tdoc = 'fc0';
	}
	 
	my $table_record = $doc_tables{$tdoc};
	
	$type_permission = 'download';
	my %migcms_roles_detail = sql_line({debug=>0,debug_results=>0,select=>"id",table=>'migcms_roles_details',where=>"id_role='$migcms_role{id}' AND id_module='$sel' AND type_permission='$type_permission'"});
	my $class = 'btn-default';
	if(!($migcms_roles_detail{id} > 0))
	{
		$class = 'btn-link disabled';
	}
	my $imprimer = <<"EOH";
				<a data-placement="top" data-original-title="Visualiser" class="btn $class" target="_blank" href="../usr/documents/$facture{pdf_filename}.pdf">
					<i class="fa fa-eye"></i> 
				</a> 
				<a data-placement="top" data-original-title="Télécharger/imprimer" class="btn $class" download="$facture{pdf_filename}.pdf" href="../usr/documents/$facture{pdf_filename}.pdf">
					<i class="fa fa-download"></i> 
				</a>
EOH

	$type_permission = 'email';
	my %migcms_roles_detail = sql_line({debug=>0,debug_results=>0,select=>"id",table=>'migcms_roles_details',where=>"id_role='$migcms_role{id}' AND id_module='$sel' AND type_permission='$type_permission'"});
	my $class = 'btn-default';
	if(!($migcms_roles_detail{id} > 0))
	{
		$class = 'btn-link disabled';
	}
	my $email = <<"EOH";
			<a id="$id" class=" $class show_only_after_document_ready btn send_mail_screen" href="#"
			data-original-title="Email" title="">
				<span class="fa-fw fa fa-at">	</span>
			</a>
EOH


	$type_permission = 'facturer';
	my %migcms_roles_detail = sql_line({debug=>0,debug_results=>0,select=>"id",table=>'migcms_roles_details',where=>"id_role='$migcms_role{id}' AND id_module='$sel' AND type_permission='$type_permission'"});
	my $class = 'btn-danger confirm_nc';
	if(!($migcms_roles_detail{id} > 0))
	{
		$class = 'btn-link disabled';
	}

	my $nc = <<"EOH";
			<a id="$id" class=" $class show_only_after_document_ready btn  " 
			href="$dm_cfg{self}&sw=copy_invoice_to_nc&id_invoice=$facture{id}&scolg=$colg&tdoc=$tdoc" 
			data-original-title="Créditer $libelle" title="">
				<i class="fa fa-eur"></i>
			</a>
EOH
	
	return <<"EOH";
		
		<div class="btn-group_dis clearfix">
			$imprimer
			$email
			$nc
		</div>
EOH
}

sub getstatut
{
    my $dbh = $_[0];
    my $id = $_[1];
	
	my %facture = sql_line({table=>'intranet_factures',where=>"id='$id'"});
	
	my $statut = '';
	
%statut = (
	'02/emise'=>"emise",
    '03/payee'=>"payee",
);



	my $liste_des_statuts = <<"EOH";
	<select  style="width:auto;float:right;" class="form-control change_statut" id_facture="$id" name="change_statut">
EOH
	
	
	
	foreach my $cle (sort keys %statut)
	{
		my $display_statut = ucfirst(lc($statut{$cle}));
		if($display_statut eq 'Payee')
		{
			$display_statut = 'Soldée';
		}
		if($display_statut eq 'Creditee correction')
		{
			$display_statut = 'Créditée correction';
		}if($display_statut eq 'Creditee résiliation')
		{
			$display_statut = 'Créditée résiliation';
		}
		my $selected = '';
		if($statut{$cle} eq $facture{statut})
		{
			$selected='selected';
		}
		
		$liste_des_statuts .= <<"EOH";
			<option $selected value="$statut{$cle}">$display_statut</option>
EOH
	}

		

$liste_des_statuts .= <<"EOH";
	</select>	
EOH
	
	
	return $liste_des_statuts;

}

sub getnum
{
    my $dbh = $_[0];
    my $id = $_[1];
	
	my %facture = sql_line({table=>'intranet_factures',where=>"id='$id'"});
	$facture{type} = ucfirst($facture{type});

	
	if($facture{type} eq 'Recurrente')
	{
		return <<"EOH";
			<span class="badge badge-warning">AUTOMATIQUE</span>
EOH
	}
	elsif($facture{statut} eq 'brouillon' && !($facture{numero} > 0))
	{
		return '<span class="badge badge-default">Brouillon</span>';
	}
	else
	{
		return $facture{numero};
	}

	
	
	
	
}

sub custom_crediter_facture
{
	my $id = $_[0];
	my $colg = $_[1];
	my %facture = %{$_[2]};
	my $pj_name = dm::getcode($dbh,$id,$dm_cfg{file_prefixe});
		 my $apercu = <<"EOH";
		<a title="" data-original-title="Créditer la facture $pj_name" href="#" class=" btn-default show_only_after_document_ready btn confirm_nc btn-danger" id="$id">
			<i class="fa fa-eur fa-fw" data-original-title="" title=""></i>
		</a>
EOH
	
	return $apercu;
}


sub after_save
{
  	my $dbh = $_[0];  
  	my $id = $_[1];
	log_debug('factures_after_save','','factures_after_save');
	log_debug($id,'','factures_after_save');

	my %facture = sql_line({table=>'intranet_factures',where=>"id='$id'"});

	#delais
	if($facture{delai} == 1 && $facture{delai_autre} != 8)
	{
		$stmt = "UPDATE intranet_factures SET delai_autre = 8 WHERE id = '$id' ";
		log_debug($stmt,'','factures_after_save');

		execstmt($dbh,$stmt);
	}
	elsif($facture{delai} == 2 && $facture{delai_autre} != 30)
	{
		$stmt = "UPDATE intranet_factures SET delai_autre = 30 WHERE id = '$id' ";
		log_debug($stmt,'','factures_after_save');
		execstmt($dbh,$stmt);
	}

	my $filename = def_handmade::make_pdf_facture($id,$dm_cfg{file_prefixe},'force_fac');	
	log_debug('after_make','','factures_after_save');
	
	my %facture = sql_line({table=>'intranet_factures',where=>"id='$id'"});

	#CALCUL DATE ECHEANCE*********************************************************************************
	my ($yyyy,$mm,$dd) = split (/-/,$facture{date_facturation}); 
	if($yyyy > 2000 && $mm > 0 && $dd >0 && length $yyyy > 0 && length $mm > 0 && length $dd > 0)
	{
	}
	else
	{
		$yyyy = $year;
		$mm = $mon;
		$dd = $mday;
	}
	
	my $today = DateTime-> new (
                     year =>$yyyy,
                     month =>$mm,,
                     day   =>$dd,
                     hour  =>12,
                     time_zone =>'local'
                     );
	my $sql_date_limite = '';
	$delai_j = $facture{delai_autre};
	if(!($delai_j > 0))
	{
		$delai_j = 8;
	}
	if($delai_j ne '' && $delai_j >=0 )
	{
		$today->add( days => $delai_j);
		$sql_date_limite = $today->ymd; 
	}
	$stmt = "update intranet_factures SET date_echeance='$sql_date_limite' WHERE id = '".$facture{id} ."' ";
	execstmt($dbh,$stmt);
	
	#RECOPIE INFOS MEMBRE -> INFOS CLIENT FAC
	if($facture{id_member} > 0)
	{
		my %member = sql_line({table=>'members',where=>"id='$facture{id_member}'"});
		my %update_facture = ();

		if($facture{tva_f} eq '')
		{
			$update_facture{tva_f} = $member{vat};
			$update_facture{tva_f} =~ s/\'/\\\{/g;
		}
		if($facture{nom_f} eq '')
		{
			$update_facture{nom_f} = trim("$member{firstname} $member{lastname}");
			$update_facture{nom_f} =~ s/\'/\\\{/g;
		}
		if($facture{adresse_f} eq '')
		{
			$update_facture{adresse_f} = trim("$member{street} $member{number}");
			$update_facture{adresse_f} =~ s/\'/\\\{/g;
		}
		if($facture{ville_f} eq '')
		{
			$update_facture{ville_f} = trim("$member{zip} $member{city}");
			$update_facture{ville_f} =~ s/\'/\\\{/g;
		}
		updateh_db($dbh,$dm_cfg{table_name},\%update_facture,'id',$facture{id});
	}
}

sub fac_getcode
{
    my $dbh = $_[0];
    my $id = $_[1];
	
	my %fac = read_table($dbh,'intranet_factures',$id);
	return $dm_cfg{file_prefixe}.sprintf("%07d",$fac{numero});

}

sub migcms_tr_color
{
	my $dbh = $_[0];
	my $id = $_[1];
	my %d = %{$_[2]};
	
	
	my $statut = $d{line}{statut};	
	my %trad_class = (
	'brouillon'=>"",
	'emise'=>"info",
    'payee'=>"success",
    'creditee correction'=>"warning",
	'creditee résiliation'=>"danger",
	);
	my $class = $trad_class{$statut};

	my $tr = '<tr id="'.$class.'" class="'.$class.' rec_'.$d{line}{id_table_record}.'">';
	
	return $tr;
}

sub change_statut
{
	my $id_facture = get_quoted('id_facture');
	my $value = get_quoted('statut_value');

	my %facture = sql_line({dbh=>$dbh, table=>$dm_cfg{table_name}, where=>"id = '$id_facture'"});

	if($facture{id} > 0)
	{
		my %rec = (
			statut => $value,
		);

	  updateh_db($dbh,$dm_cfg{table_name},\%rec,'id',$facture{id});
	}
	exit;
		
}

sub denom_client_agence
{
	my $dbh = $_[0];
	my $id = $_[1];
	my $type = $_[2] || 'long';
	my %rec = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
	my %member = sql_line({table=>'members',where=>"id='$rec{id_member}'"});

	my $client_agence = def_handmade::denom($dbh,$rec{id_member}).'<br />'.def_handmade::denom($dbh,$member{id_agence});
	
	return $client_agence
}

sub reglements
{
	my $id = $_[0];
	my $colg = $_[1];
	my %rec = %{$_[2]};
	my $table_name = $_[3];
	my $acces = <<"EOH";
		<a class="btn btn-success blue" href="adm_handmade_certigreen_reglements.pl?&sel=1000279.pl&id_facture=$id" data-original-title="Voir ou ajouter des reglements pour la facture $rec{numero}" target="" data-placement="bottom">
		RE
		</a>
EOH

	return $acces;
}

sub ncs
{
	my $id = $_[0];
	my $colg = $_[1];
	my %rec = %{$_[2]};
	my $table_name = $_[3];
	
	my %children = sql_line({select=>"COUNT(*) as nb",table=>'intranet_nc',where=>"id_facture='$id'"});
	my $class = "btn btn-primary blue";
	my $disabled = "";
	if(!($children{nb} > 0))
	{
		$class = "btn btn-default disabled";
		$disabled = " disabled ";
	}
	
	
	my $acces = <<"EOH";
		<a class="$class" $disabled href="adm_handmade_certigreen_ncs.pl?&sel=1000276.pl&id_facture=$id" data-original-title="Voir le notes de crédits pour la facture $rec{numero}" target="" data-placement="bottom">
		NC
		</a>
EOH

	return $acces;
}

sub intranet_factures_get_next_number
{
	my %last_invoice = sql_line({debug=>0,debug_results=>0,table=>'intranet_factures',select => 'MAX(numero) as last_number', where=>""});
	
	my $next_number = $last_invoice{last_number};
	if($next_number > 0)
	{
		$next_number++;
	}
	else
	{
		$next_number = 1;
	}
	
	# $next_number = sprintf("%.04d",$next_number);
	# print $next_number;
	return $next_number;
}


sub validation_func
{
	# my $dbh=$_[0];
    my %item = %{$_[1]};
	my $id = $_[2];
	
	my %rec = read_table($dbh,$dm_cfg{table_name},$id);
	
	my $rapport = '';
	my $valide = 1;

	if($item{numero} =~ /\d/ && $item{numero} > 0)
	{
	}
	else
	{	
		#Numero non valable		
		$valide = 0;
		$rapport .=<<"EOH";
		<tr><td><i class="fa fa-times"></i>Document > Numéro</td><td>Le numéro n'est pas valable. Il doit être un chiffre > 0</td></tr>
EOH
	}
	
	my $next_number_invoice = intranet_factures_get_next_number($annee);
	if(($item{numero} >= $next_number_invoice || $item{numero} == $rec{numero})  && $item{numero} ne '')
	{
	}
	else
	{	
		#Numero non valable		
		$valide = 0;
		$rapport .=<<"EOH";
		<tr><td><i class="fa fa-times"></i>Document > Numéro</td><td>Le numéro n'est pas valable. Il doit être au moins <b>$next_number_invoice</b></td></tr>
EOH
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

sub commande_col_adresse_facture
{
	# my $dbh = $_[0];
	my $id = $_[1];
	my $type = $_[2] || 'long';
	my $from = $_[3] || 'intranet_factures';
	my %facture = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
	
	if($facture{id_record} > 0)
	{
		my %commande = sql_line({table=>'intranet_factures',where=>"id='$facture{id_record}'"});
		
		if($commande{id} > 0)
		{
			my $fusion = '';
			
			my $rue = trim($commande{adresse_rue}.' '.$commande{adresse_numero});
			if($rue ne '')
			{
				$fusion .= "$rue<br />";
			}
			my $ville = trim($commande{adresse_cp}.' '.$commande{adresse_ville});
			if($ville ne '')
			{
				$fusion .= "$ville<br />";
			}
			
			return $fusion;
		}
		else
		{
			return '';
		}
	}
	else
	{
		return '';
	}
}
