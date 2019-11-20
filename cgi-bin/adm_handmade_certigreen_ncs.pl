#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

use def_handmade;




$dm_cfg{customtitle} = $fwtrad{users_title};
$dm_cfg{enable_search} = 1;
$dm_cfg{deplie_recherche} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "intranet_nc";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
 
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_handmade_certigreen_ncs.pl?";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
# $dm_cfg{javascript_custom_func_form} = '';
$dm_cfg{default_ordby} = 'id desc';
$dm_cfg{lock_on} = 1;
$dm_cfg{lock_off} = 1;
$dm_cfg{show_id} = 1;

$dm_cfg{page_title} = "Notes de Crédit";
$dm_cfg{add_title} = "";

$dm_cfg{modification} = 1;
$dm_cfg{delete} = 0;
$dm_cfg{trad} = 0;
# $dm_cfg{send_by_mail_less_pj} = 1;
$dm_cfg{func_publish} = 'ajax_make_pdf_nc';
$dm_cfg{telecharger} = 1;
$dm_cfg{email} = 1;
$dm_cfg{edit} = 1;
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
$dm_cfg{send_by_email_table_templates} = 'handmade_templates';
# $dm_cfg{send_by_email_id_template} = 20;

$dm_cfg{pdfzip} = 1;

$dm_cfg{custom_add_button_icon} = '<i class="fa fa-fw fa-arrow-circle-o-right "></i>';$dm_cfg{custom_add_button_txt} = 'Sauvegarder + Etape suivante';
$dm_cfg{custom_add_button_id} = 'details_doc';
$dm_cfg{custom_edit_button_txt} = '<i class="fa fa-fw fa-arrow-circle-o-right "></i>';$dm_cfg{custom_add_button_txt} = 'Sauvegarder + Etape suivante';
$dm_cfg{custom_edit_button_id} = 'details_doc';

my $document_name = 'intranet_nc';

# $dm_cfg{list_custom_action_1_func} = \&custom_edit;

my $id_facture = get_quoted('id_facture');
if($id_facture > 0)
{
	$dm_cfg{wherel} = $dm_cfg{wherep} ="id_facture='$id_facture'";
}   

# $dm_cfg{before_del_ref} = 'before_del_handmade_certigreen_documents_devis';
$dm_cfg{after_dupl_func} = 'after_dupl_doc';
			my $stmt = <<"SQL";
			update $dm_cfg{table_name} SET statutbck = statut where statutbck = ''
SQL
			execstmt($dbh, $stmt);


$dm_cfg{autocreation} = 0;
$dm_cfg{add} = 0;
$dm_cfg{def_handmade} = 1;
$lbdisplay_code = 'ne';

%statut = (
    '01/brouillon'=>"brouillon",
	'02/emise'=>"emise",
);
$dm_cfg{default_tab} = 'document';

my $stmt = <<"SQL";
			update $dm_cfg{table_name} SET statutbck = statut where statutbck = ''
SQL
			execstmt($dbh, $stmt);	
			
			my $stmt = <<"SQL";
			update $dm_cfg{table_name} SET statut = '2' where statut = 'emise'
SQL
			execstmt($dbh, $stmt);	
			
			my $stmt = <<"SQL";
			update $dm_cfg{table_name} SET statut = '1' where statut = 'brouillon'
SQL
			execstmt($dbh, $stmt);	

my $cpt = 5;
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
		'type'=>'tab',
		'title'=>'Coord. client',
		'tab'=>'cli',
		'disable_add'=>0,
	}			
	);

%dm_dfl = (
	# sprintf("%03d", $cpt++).'/id_facture'=> 
	# {
        # 'title'=>'N° Facture',
        # 'fieldtype'=>'text',
		# 'hidden'=>1,
		# 'search' => 'y',
    # }
  
# ,
	sprintf("%03d", $cpt++).'/id_facture'=>{"default_value"=>'','title'=>'Facture','importcode'=>'1','translate'=>0,'list_edit'=>0,'list_edit_clean_prefixe'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => 'not_empty'},tab=>$tab,'lbtable'=>'intranet_factures','lbkey'=>'id','lbdisplay'=>'numero','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%03d", $cpt++).'/statut_facturation'=>{"default_value"=>'','title'=>'Statut de facturation','importcode'=>'1','translate'=>0,'list_edit'=>0,'list_edit_clean_prefixe'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'y','mandatory'=>{"type" => 'not_empty'},tab=>$tab,'lbtable'=>'handmade_certigreen_statuts_facturation','lbkey'=>'id','lbdisplay'=>'nom','lbwhere'=>"id = 5 or id = 6",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},

	sprintf("%03d", $cpt++).'/id_member'=> 
	{
        'title'=>'Client',
		'search'=>'y',
        'fieldtype'=>'listboxtable',
        'data_type'=>'autocomplete',
		 'lbtable'=>'members ',
         'lbkey'=>'id',
         'lbdisplay'=>"fusion_short",
         'lbwhere'=>"" ,
		'search' => 'y',
		'mandatory'=>
		{"type" => 'not_empty',
		}
		,
		'hidden' => 0,
		
    }
	,
	# sprintf("%05d", $cpt++).'/id_pdi'=>{'title'=>'PDI','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'handmade_certigreen_points_interets','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0}
	# ,
	# sprintf("%03d", $cpt++).'/date_creation'=> 
	# {
        # 'title'=>'Date',
        # 'fieldtype'=>'display',
		# 'data_type'=>'date',
		# 'hidden'=>0,
    # }
	,
	sprintf("%03d", $cpt++).'/date_facturation'=> 
	{
        'title'=>'Date',
        'fieldtype'=>'text',
		'data_type'=>'date',
		'hidden'=>0,
    }
	,
	sprintf("%03d", $cpt++).'/date_echeance'=> 
	{
        'title'=>'Echéance',
        'fieldtype'=>'text',
		'data_type'=>'date',
		'hidden'=>0,
    }
	# ,
# sprintf("%03d", $cpt++).'/echeance_statut'=> 
# {
	# 'title'=>'Echéance - Statut' ,
	# 'fieldtype'=>'text',
	# 'data_type'=>'',
	# 'search' => 'y',
	# 'hidden'=>0,
# }
	,
	sprintf("%03d", $cpt++).'/montant_a_payer_htva'=> 
	{
        'title'=>'Total HTVA',
        'fieldtype'=>'display',
		'data_type'=>'euros',
		'hidden'=>0,
		'search' => 'y',

    }
	,
	sprintf("%03d", $cpt++).'/montant_a_payer_tvac'=> 
	{
        'title'=>'Total TVAC',
        'fieldtype'=>'display',
		'data_type'=>'euros',
		'hidden'=>0,
		'search' => 'y',

    }
	,
	sprintf("%03d", $cpt++).'/reference'=> 
	{
        'title'=>'Référence',
        'fieldtype'=>'text',
		'search' => 'y',

    }
	# ,
	# sprintf("%03d", $cpt++).'/reference_secondaire'=> 
	# {
        # 'title'=>'Référence secondaire',
        # 'fieldtype'=>'text',
		# 'search' => 'y',

    # }
# ,
	# sprintf("%05d", $cpt++).'/id_handmade_certigreen_marque_facture'=> 
	# {
        # 'title'=>'Marque',
		# 'search'=>'y',
        # 'fieldtype'=>'listboxtable',
		 # 'lbtable'=>'handmade_certigreen_marques',
         # 'lbkey'=>'id',
         # 'lbdisplay'=>"fusion",
         # 'lbwhere'=>"" 
		
    # }	
	
	# ,
# sprintf("%03d", $cpt++).'/statut'=> 
    # {
		# 'title'=>'Statut',
          # 'fieldtype'=>'listbox',
		    # 'list_edit'=>1,
          # 'fieldvalues'=>\%statut,
          # 'default_value'=>'brouillon',
		  # 'mandatory'=>{"type" => 'not_empty'},
    # }
,	
	# sprintf("%05d", $cpt++).'/statut'=>{'title'=>'Statut','importcode'=>'1','translate'=>0,'list_edit'=>1,'list_edit_clean_prefixe'=>1,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'handmade_certigreen_codes_aaa','lbkey'=>'id','lbdisplay'=>$lbdisplay_code,'lbwhere'=>"",'lbordby'=>"id",'fieldvalues'=>'','hidden'=>0}
		# sprintf("%05d", $cpt++).'/statut'=>{'title'=>'Statut','importcode'=>'1','translate'=>0,'list_edit'=>1,'list_edit_clean_prefixe'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => 'not_empty'},tab=>$tab,'lbtable'=>'handmade_certigreen_statuts_nc','lbkey'=>'id','lbdisplay'=>'nom','lbwhere'=>"",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0}

	
,
 sprintf("%03d", $cpt++).'/remarque'=> 
{
	'title'=>'Remarque',
	'fieldtype'=>'textarea',
}

,

	sprintf("%03d", $cpt++).'/facture_civilite_id'=>{'title'=>'Civilité','class'=>$line_class='line_facturation ','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>'cli','lbtable'=>'migcms_codes','lbkey'=>'id','lbdisplay'=>'v1','lbwhere'=>"",'lbordby'=>"v1",'fieldvalues'=>\%type_agence,'hidden'=>0}
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

$dm_cfg{file_prefixe} = 'NC';
$dm_cfg{send_by_email_col_docname} = $doc_names{$doc_tables{lc($dm_cfg{file_prefixe})}};
# $dm_cfg{send_by_email_col_prefixe} = 'id_handmade_certigreen_marque_facture';
# $dm_cfg{send_by_email_col_prefixe_lbtable} = 'handmade_certigreen_marques';
# $dm_cfg{send_by_email_col_prefixe_lbdisplay} = 'nom';
$dm_cfg{send_by_email_col_suffixe} = 'id_member';
$dm_cfg{send_by_email_col_suffixe_lbtable} = 'members';
$dm_cfg{send_by_email_col_suffixe_lbdisplay} = 'lastname';
# $dm_cfg{send_by_email_col_suffixe_lbdisplay_prefixe} = 'cef';

%dm_display_fields = (
	# "02/Client"=>"id_member",
	
	
	"01/Facture N°"=>"id_facture",
	
	"02/Date"=>"date_facturation",
	"03/Nom"=>"nom_f",
	"04/TVA"=>"tva_f",
	

	
	# "04/Total HTVA"=>"montant_a_payer_htva",
	"05/TTC"=>"montant_a_payer_tvac",
	# "06/Référence"=>"reference",
	
	# "07/Statut"=>"statut",
	
);

%dm_filters = (

"2/Dates"=>{
'type'=>'fulldaterange',
'col'=>'date_facturation',
}
);



%dm_lnk_fields = 
(
# "01/Identifiant/col_identifiant"=>"nc_ getcode*",
# "06/N° Facture/col_identifiant"=>"getnum*",
# "05/Statut"=>"stat*",
# "99//list_actions_3"=>"actions*",
);

%dm_mapping_list = (
# "nc_ getcode" => \&getcode,
# "getnum" => \&getnum,
# "stat" => \&getstatut,
# "actions" => \&get_actions_nc,
);


$sw = $cgi->param('sw') || "list";

if($sw ne 'download_pdf' && $sw ne 'publi' && $sw ne '')
{
	see();
}

my $id = get_quoted('id');
my $infos_rec = '';
if($id>0)
{
	$infos_rec = ajax_infos_rec($id,$dm_cfg{table_name});
}

$dm_cfg{list_html_top} = <<"EOH";
<input type="hidden" class="prefixe" name="prefixe" value="$doc_prefixes{$document_name}" />
<script src="$config{baseurl}/custom_skin/js/certigreen_intranet_handmade.js"></script>
<input type="hidden" class="type type_document" value="nc" />


<span id="infos_rec">$infos_rec</span>
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
	jQuery(document).on("click", ".send_mail_screen", send_mail_screen);
});
</script>
<style>
.dm_migedit
{
	/*display:none!important;*/
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
	var col_identifiant  = ligne.children('.col_identifiant ').html();
	var cms_mig_cell_id_member   = ligne.children('.cms_mig_cell_id_member  ').html();
	jQuery('#nomexposant').html(col_identifiant+' '+cms_mig_cell_id_member );
}
function removenomexposant()
{
	jQuery('#nomexposant').html('Liste des NC');
}
</script>
EOH

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
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}


sub getstatut
{
    my $dbh = $_[0];
    my $id = $_[1];
	
	my %nc = sql_line({table=>'intranet_nc',where=>"id='$id'"});
	
	my $statut = '';
	
	
	$nc{statut} = ucfirst($nc{statut});
	
	
	if($nc{statut} eq 'Brouillon')
	{
	$statut =<<"EOH";
		<span class="badge badge-default">$nc{statut}</span>
EOH
	}
	elsif($nc{statut} eq 'Emise')
	{
	$statut =<<"EOH";
		<span class="badge badge-info">$nc{statut}</span>
EOH
	}
	else
	{
		$statut = "Statut erroné: [$facture{statut}]";
	}
	
	
	return $statut;

}


sub getnum
{
    my $dbh = $_[0];
    my $id = $_[1];

	my %nc = sql_line({table=>'intranet_nc',where=>"id='$id'"});
	my %facture = sql_line({table=>'intranet_factures',where=>"id='$nc{id_facture}'"});
	
	
	return getcode($dbh,$facture{numero},'FC0');
	
	
}


sub after_save
{
    # my $dbh = $_[0];
    my $id = $_[1];
	
	my %nc = sql_line({table=>'intranet_nc',where=>"id='$id'"});

	if($nc{statut_facturation} > 0 && $nc{id_facture} > 0)
	{
		$stmt = "UPDATE intranet_factures SET statut = $nc{statut_facturation} WHERE id = '$nc{id_facture}' ";
		execstmt($dbh,$stmt);
	}

}

sub get_actions_nc
{
	my $dbh = $_[0];
    my $id = $_[1];
	
	my $sel = get_quoted('sel');
	
	my %nc = sql_line({table=>'intranet_nc',where=>"id='$id'"});
	my %facture = sql_line({table=>'intranet_factures',where=>"id='$nc{id_facture}'"});
	my %doc = sql_line({debug=>0,table=>'intranet_documents',where=>"table_record = '$facture{table_record}' AND id_record='$facture{id_record}'"});
	my %migcms_role = sql_line({debug=>$debug,debug_results=>$debug,table=>"migcms_roles",where=>"id='$user{id_role}' and visible='y' and token != ''"});

	my $tdoc = $doc_prefixes{$facture{table_record}};
	my $libelle = dm::getcode($dbh,$nc{numero},'ne0');
	
	if($tdoc eq '')
	{
		$tdoc = 'ne0';
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
				<a data-placement="top" data-original-title="Visualiser" class="btn $class" target="_blank" href="../usr/documents/$nc{pdf_filename}.pdf">
					<i class="fa fa-eye"></i> 
				</a> 
				<a data-placement="top" data-original-title="Télécharger/imprimer" class="btn $class" download="$nc{pdf_filename}.pdf" href="../usr/documents/$nc{pdf_filename}.pdf">
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


	return <<"EOH";
		
		<div class="btn-group_dis clearfix">
			$imprimer
			$email
		</div>
EOH
}

# sub get_actions_nc
# {
	# my $dbh = $_[0];
    # my $id = $_[1];
	
	# my %nc = sql_line({table=>'intranet_nc',where=>"id='$id'"});
	# my %facture = sql_line({table=>'intranet_factures',where=>"id='$nc{id_facture}'"});
	# my %doc = sql_line({debug=>0,table=>'intranet_documents',where=>"table_record = '$facture{table_record}' AND id_record='$facture{id_record}'"});

	# my $libelle = 'NE0'.$facture{numero};
	# my $tdoc = $doc_prefixes{$facture{table_record}};
	
	# if($tdoc eq '')
	# {
		# $tdoc = 'ne0';
	# }
	
	# my $table_record = $doc_tables{$tdoc};
	
	# my $class = 'btn-info';
	# if(0)
	# {
		# $class = 'btn-link disabled';
	# }
	# my $editer = <<"EOH";
	# <a href="#" data-placement="top" data-original-title="Modifier (Ref#$id)" id="$id" role="button" class=" animate_gear
				  # btn $class show_only_after_document_ready migedit_$id migedit">
					  # <i class="fa fa-fw fa-gear "> 
				  # </i>
						  
				  # </a>
# EOH

	
	# my $class = 'btn-default';
	# if(0)
	# {
		# $class = 'btn-link disabled';
	# }
	# my $visualiser = <<"EOH";
			# <a class=" $class show_only_after_document_ready btn  " href="$dm_cfg{self}&sw=download_pdf&type=nc&id=$facture{id_record}&id_nc=$id&scolg=$colg&tdoc=$tdoc"
			# data-original-title="Visualiser" title="">
				# <span class="fa-fw fa fa-eye">
				# </span>
			# </a>
# EOH

	# my $class = 'btn-default';
	# if(0)
	# {
		# $class = 'btn-link disabled';
	# }
	# my $imprimer = <<"EOH";
			# <a class=" $class show_only_after_document_ready btn " href="$dm_cfg{self}&sw=download_pdf&type=nc&id=$facture{id_record}&id_nc=$id&scolg=$colg&tdoc=$tdoc"
			# data-original-title="Télécharger/Imprimer" title="">
				# <span class="fa-fw fa fa-download">
				# </span>
			# </a>
# EOH

		# my $class = 'btn-default';
	# if(0)
	# {
		# $class = 'btn-link disabled';
	# }
	# my $email = <<"EOH";
			# <a id="$id" class=" $class show_only_after_document_ready btn send_mail_screen" href="#"
			# data-original-title="Email" title="">
				# @
			# </a>
# EOH

	

# my $espace = <<"EOH";
			# &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
# EOH






	
	
	
	# return <<"EOH";
		# <div class="btn-group_dis clearfix">
			# $visualiser
			# $imprimer
			# $email
			# $courrier
		# </div>
# EOH

# }

sub custom_edit
{
	my $id = $_[0];
	my $colg = $_[1];
	my %page = %{$_[2]};
	
	$type_permission = 'edit';
	my $class = 'btn-info';
		$edit_paragraphes = <<"EOH";
	<a href="#" data-placement="top" data-original-title="Editer (Ref#NE00000$id)" id="$id" role="button" class=" 
		btn $class show_only_after_document_ready migedit_$id migedit">
		<i class="fa fa-fw fa-pencil "> 
		</i>
	</a>
EOH
	if($page{statut} ne 'brouillon')
	{
		return '';
	}
	
	return $edit_paragraphes;
}