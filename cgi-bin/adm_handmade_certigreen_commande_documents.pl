#!/usr/bin/perl -I../lib
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use dm_publish_pdf;
use def_handmade;
use File::Copy;


$dbh_data = $dbh2 = $dbh;

my $acces_full = 0;
if($user{id_role} > 0 && $user{id_role} < 9)
{
	$acces_full = 1;
}

my $commande_id = get_quoted("commande_id");

$dm_cfg{func_publish} = 'publish_document_dum';
$dm_cfg{send_by_email_table_license} = 'handmade_certigreen_licenses';
$dm_cfg{send_by_email_field1_license} = 'license_name';
$dm_cfg{send_by_email_field2_license} = 'email';
#$dm_cfg{send_by_email_table_destinataire} = 'members';
#$dm_cfg{send_by_email_col_destinataire} = 'id_member';
#$dm_cfg{send_by_email_field1_destinataire} = 'fusion_short';
#$dm_cfg{send_by_email_field_email_destinataire} = 'email';

$dm_cfg{send_by_email_field_email_destinataire_func} = 'def_handmade::handmade_emailto_document';
$dm_cfg{send_by_email_field_email_object_func} = 'def_handmade::handmade_object_document';
$dm_cfg{send_by_email_field_email_body_func} = 'def_handmade::handmade_body_document';


#$dm_cfg{send_by_email_table_templates} = 'handmade_templates';
$dm_cfg{disable_if_migcms_last_published_file_not_exist} = 'y';



$dm_cfg{custom_global_action_func} = "prevenir_client";
$dm_cfg{custom_global_action_title} = "Prévenir le client: Agence ou particulier sans agence ou agence du particulier et agence 2 du particulier";
$dm_cfg{custom_global_action_icon} = '<i class="fa fa-paper-plane-o  fa-fw"></i>';




$dm_cfg{enable_search} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
if($commande_id > 0) {
	$dm_cfg{wherel} = $dm_cfg{wherep} = "commande_id = '$commande_id'";
}

$dm_cfg{table_name} = "commande_documents";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_handmade_certigreen_commande_documents.pl?commande_id=$commande_id";
$dm_cfg{hide_id} = 0;
$dm_cfg{duplicate}='y';
$dm_cfg{default_ordby}='id desc';

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{breadcrumb_func}= \&breadcrumb_func;
$dm_cfg{after_add_ref} = \&after_save;
# $dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{autocreation} = 0;


$dm_cfg{'list_custom_action_14_func'} = \&download_document;
$dm_cfg{'list_custom_action_15_func'} = \&send_document;
$dm_cfg{'list_custom_action_19_func'} = \&send_rdv;
$dm_cfg{'list_custom_action_16_func'} = \&download_communication;

%reportResults = (
	'01/NOK'=>"NOK",
	'02/OK'=>"OK",
);

$dm_cfg{file_prefixe} = 'DOC';

my $cpt = 9;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = 
(

	sprintf("%05d", $cpt++).'/infos_nc'=>{'title'=>'Informations','func'=>'def_handmade::doc_infos_doc','translate'=>0,'fieldtype'=>'func',default_value => '',legend => '','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab='nc','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},


	sprintf("%05d", $cpt++).'/titre'=>{'title'=>'Document','translate'=>0,'fieldtype'=>'titre','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"fusion_short",'fieldvalues'=>'','hidden'=>0},

	sprintf("%05d", $cpt++).'/type_document_id'=>{'title'=>'Type','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_document','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
  	sprintf("%05d", $cpt++).'/date_prevue'=>{'title'=>'Date RDV','translate'=>0,'fieldtype'=>'text','data_type'=>'date','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_document','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
  	sprintf("%05d", $cpt++).'/heure_prevue'=>{'title'=>'H RDV','translate'=>0,'fieldtype'=>'text','data_type'=>'time','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_document','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_employe'=>{default_value=>25,'title'=>'Employé','list_edit'=>0,'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'users','lbkey'=>'id','lbdisplay'=>"CONCAT(firstname,' ',lastname)",'lbwhere'=>"id_role='8' or id_role='7'",'lbordby'=>"firstname,lastname",'fieldvalues'=>'','hidden'=>0},

	sprintf("%05d", $cpt++).'/date_realisee'=>{'title'=>'Date dépôt','translate'=>0,'fieldtype'=>'text','data_type'=>'date','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_document','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
  	sprintf("%05d", $cpt++).'/commande_id'=>{'title'=>'Commande','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'intranet_factures','lbkey'=>'id','lbdisplay'=>'id','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
  	sprintf("%05d", $cpt++).'/id_member'=>{'title'=>'Membre','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"fusion_short",'fieldvalues'=>'','hidden'=>1},
  	sprintf("%05d", $cpt++).'/date_encodage'=>{'title'=>"Date ENCO",'translate'=>0,'fieldtype'=>'text','data_type'=>'date','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"fusion_short",'fieldvalues'=>'','hidden'=>0},
#  	sprintf("%05d", $cpt++).'/date_facturation'=>{'title'=>"Date FA",'translate'=>0,'fieldtype'=>'text','data_type'=>'date','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"fusion_short",'fieldvalues'=>'','hidden'=>0},
  	sprintf("%05d", $cpt++).'/date_envoi_facture'=>{'title'=>"Envoi DOC",'translate'=>0,'fieldtype'=>'text','data_type'=>'date','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"fusion_short",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_encode_envoye_a'=>{'title'=>'Envoyé à...','class'=>$line_class='line_facturation ','translate'=>0,'multiple'=>1,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'migcms_codes','lbkey'=>'id','lbdisplay'=>'v1','lbwhere'=>"id_code_type='3' and visible='y'",'lbordby'=>"v1",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/envoyee_a'=>{'title'=>"Remarque envoi",'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"fusion_short",'fieldvalues'=>'','hidden'=>0},

	sprintf("%05d", $cpt++).'/report_number'=>{'title'=>"N° Rapport",'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"fusion_short",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/report_result'=>{'title'=>"Résultat",'translate'=>0,'fieldtype'=>'listbox','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"fusion_short",'fieldvalues'=>\%reportResults,'hidden'=>0},
	sprintf("%05d", $cpt++).'/report_date'=>{'title'=>"Echeance",'translate'=>0,'fieldtype'=>'text','data_type'=>'date','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"fusion_short",'fieldvalues'=>'','hidden'=>0},

#  	sprintf("%05d", $cpt++).'/date_paiement'=>{'title'=>"Date PAYE",'translate'=>0,'fieldtype'=>'text','data_type'=>'date','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"fusion_short",'fieldvalues'=>'','hidden'=>0},
	
  	sprintf("%05d", $cpt++).'/pj'=>{'disable_add'=>1,'title'=>'Document','translate'=>0,'fieldtype'=>'files_admin','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_document','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
#  	sprintf("%05d", $cpt++).'/avertissement'=>{'title'=>"Prévenir le client par mail",'translate'=>0,'fieldtype'=>'checkbox','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"fusion_short",'fieldvalues'=>'','hidden'=>0},

	 sprintf("%05d", $cpt++).'/titre'=>{'title'=>'Communication','translate'=>0,'fieldtype'=>'titre','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"fusion_short",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_code_cible'=>{list_edit=>'1','default_value'=>7,'title'=>'Envoyer à...','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'migcms_codes','lbkey'=>'id','lbdisplay'=>'v1','lbwhere'=>"id_code_type='2' and visible='y'",'lbordby'=>"v1",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/id_texte_email'=>{list_edit=>'1','default_value'=>9,'title'=>'Texte email','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'migcms_textes_emails','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"migcms_lock!='y'",'lbordby'=>"name",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/id_texte_pdf'=>{list_edit=>'1','default_value'=>9,'title'=>'Texte courrier','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'migcms_textes_emails','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"migcms_lock!='y'",'lbordby'=>"name",'fieldvalues'=>\%type_agence,'hidden'=>0},

);

%dm_display_fields = 
(
	"01/Type"=>"type_document_id",            
	"09/Date prévue"=>"date_prevue",            
	"10/Heure prévue"=>"heure_prevue", 	
	"11/Date dépôt"=>"date_realisee", 	
	"21/Envoyer à"=>"id_code_cible",
	"22/Texte email"=>"id_texte_email",
	"23/Texte courrier"=>"id_texte_pdf",
);

if(!$acces_full) {

	delete $dm_display_fields{'21/Envoyer à'};
	delete $dm_display_fields{'22/Texte email'};
	delete $dm_display_fields{'23/Texte courrier'};
}

%dm_lnk_fields = 
(      
);
	

%dm_mapping_list = (
);
 
 
 my $js = <<"EOH";
		<style>
		.maintitle
		{
			display:none;
		}
		</style>
		<script type="text/javascript">
			
			jQuery(document).ready( function () 
			{     			    		
				jQuery('.maintitle').html('Documents de la commande '+jQuery('.parametre_url_commande_id').val()).show();
							jQuery(document).on("click", ".send_by_email_rdv", send_by_email_rdv);

			});



function send_by_email_rdv()
{
	var prefixe = jQuery(".prefixe").val();
	scrollbarposition = jQuery(document).scrollTop();
	var id = jQuery(this).attr('id');
	var self = get_self('full');
	jQuery("#edit_form_container").html('Chargement...');

	swal({
	  title: "Préparation de l'email...",
	  text: "Préparation de l'email et génération des pièces jointes en cours...",
	  html: true,
	  confirmButtonText: 'Fermer',
	  imageUrl: '../mig_skin/img/loader-big-noanimation.svg'
	});

	var request = jQuery.ajax(
	{
		url: self,
		type: "GET",
		data:
		{
			rdv : 'y',
			sw : 'send_by_email_rdv_txt',
			id : id,
			prefixe: prefixe
		},
		dataType: "html"
	});

	request.done(function(msg)
	{
		jQuery("#edit_form_container").html(msg).toggleClass('hide');
		jQuery("#mig_list_display").toggleClass('hide');
		swal.close();
		tinymce.remove();
		tinymce.init({
			selector: ".wysiwyg",
			forced_root_block : false,
			language : 'fr_FR',
			inline: false,
			  menubar: false,
			theme: "modern",
			plugins:
			[
			  "advlist autolink lists link image charmap hr pagebreak",
			  "searchreplace wordcount visualblocks visualchars code fullscreen",
			  "insertdatetime nonbreaking table contextmenu directionality",
			  "emoticons paste textcolor  "
			]
			,
			toolbar1: " undo redo |  bold italic forecolor | alignleft aligncenter alignright alignjustify | bullist numlist outdent indent   ",
			});

		jQuery('a.cancel_edit').tooltip({html:'true'});
		jQuery('a.send_mail_screen_submit').tooltip({html:'true'});

		jQuery(".send_mail_screen_submit").click(function()
		{
			var to = jQuery('.send_mail_screen_to').val();
			var send_mail_screen_object = jQuery('.send_mail_screen_object').val();
			var send_mail_screen_cc = jQuery('.send_mail_screen_cc').val();
			var send_mail_screen_cci = jQuery('.send_mail_screen_cci').val();


			var send_mail_screen_message = '';//jQuery('.send_mail_screen_message').html();

			var this_name = jQuery('.mce-tinymce').attr('id');
            // console.log(this_name);
            //tinyMCE.get(this_name).save();
			//console.log(jQuery(this).val());
			//var content = tinymce.get(this_name).getContent({format: 'text'});
			var content = tinymce.activeEditor.getContent();
			//console.log('textarea wysiwyg: '+content);
            // donnees[jQuery (this).attr('name')] = jQuery(this).val();

			send_mail_screen_message = content;
			var company = jQuery(".company").val();
			var request2 = jQuery.ajax(
			{
				url: self,
				type: "POST",
				data:
				{
					sw : 'send_by_email_db',
					company : company,
					to : to,
					cc : send_mail_screen_cc,
					cci : send_mail_screen_cci,
					object: send_mail_screen_object,
					id_doc : jQuery(".id_doc").val(),
					prefixe_doc : jQuery(".prefixe_doc").val(),
					send_mail_screen_message: send_mail_screen_message
				},
				dataType: "html"
			});

			request2.done(function(msg)
			{
				swal({
				title: "Email envoyé",
				  text: "Votre document a bien été envoyé.",
				  html: true,
				  confirmButtonText: 'Fermer',
				  type: "success"
				});

			});

			jQuery("#edit_form_container").toggleClass('hide');
			jQuery("#mig_list_display").toggleClass('hide');
			return false;
		});


	});
	return false;




}


      
		</script>
EOH

my %cmd = read_table($dbh,'intranet_factures',$commande_id);
$dm_cfg{list_html_top} .= $js.def_handmade::get_denom_style_et_js();
my $download_fa_link = '';
if($cmd{migcms_last_published_file} ne '' && $cmd{montant_a_payer_tvac} > 0)
{
	#		.pdf
	$download_fa_link = <<"EOH";

		<a href="../usr/documents/$cmd{migcms_last_published_file}" data-funcpublish="" data-placement="bottom" target="_blank"
		 data-original-title="Télécharger la facture N° FA$cmd{numero_facture}" role="button" class="btn btn-default show_only_after_document_ready viewpdf">
		 <i class="fa fa-eye  fa-fw" data-original-title="" title=""></i></a>
EOH
}

if($cmd{alt_facture_url} ne '')
{
	$download_fa_link = <<"EOH";

		<a href="../usr/$cmd{alt_facture_url}"  data-funcpublish="" data-placement="bottom" target="_blank"
		 data-original-title="Télécharger l'ancienne facture" role="button" class="btn btn-default show_only_after_document_ready viewpdf">
		 <i class="fa fa-eye  fa-fw" data-original-title="" title=""></i></a>
EOH
}

$cmd{date_dernier_envoi} = sql_to_human_date($cmd{date_dernier_envoi});
$cmd{date_dernier_envoi} =~ s/\r*\n//g;
if($cmd{date_dernier_envoi} eq '00/00/0000')
{
	$cmd{date_dernier_envoi} = 'Pas encore envoyé';
}
$cmd{date_facturation} = sql_to_human_date($cmd{date_facturation});
$cmd{date_facturation} =~ s/\r*\n//g;
if($cmd{date_facturation} eq '00/00/0000')
{
	$cmd{date_facturation} = 'Pas encore facturé';
}
$cmd{date_paiement} = sql_to_human_date($cmd{date_paiement});
$cmd{date_paiement} =~ s/\r*\n//g;
if($cmd{date_paiement} eq '00/00/0000')
{
	$cmd{date_paiement} = 'Pas encore payé';
}

my $envoye_a_list = '';
my @envoye_a_array = split('\,',$cmd{envoyee_a});
foreach my $envoye_a (@envoye_a_array)
{
	if($envoye_a > 0)
	{
		my %code = sql_line({table=>'migcms_codes',where=>"id='$envoye_a'"});
		if($code{id} > 0 && $code{v1} ne '')
		{
			$envoye_a_list .= "<i class='fa fa-check' aria-hidden='true'></i> $code{v1}";
		}
	}
}

my $txtRappel="";
if($cmd{nom_facture_liaison} ne ''){
	
	my %searchRappel1 = sql_line({table=>'migcms_mail_history',where=>'email_object LIKE "%Rappel 1%" AND email_object LIKE "%'.$cmd{nom_facture_liaison}.'%"'});
	if($searchRappel1{id} > 0 )
	{
		$date_rappel_1 = $searchRappel1{moment};
	}else{
		$date_rappel_1 = "Pas encore envoyé";
	}

	my %searchRappel2 = sql_line({table=>'migcms_mail_history',where=>'email_object LIKE "%Rappel 2%" AND email_object LIKE "%'.$cmd{nom_facture_liaison}.'%"'});
	if($searchRappel2{id} > 0)
	{
		$date_rappel_2 = $searchRappel2{moment};
	}else{
		$date_rappel_2 = "Pas encore envoyé";
	}

	my %searchRappel3 = sql_line({table=>'migcms_mail_history',where=>'email_object LIKE "%Rappel 3%" AND email_object LIKE "%'.$cmd{nom_facture_liaison}.'%"'});
	if($searchRappel3{id} > 0)
	{
		$date_rappel_3 =  $searchRappel3{moment};
	}else{
		$date_rappel_3 = "Pas encore envoyé";
	}
	$txtRappel="<br /><br /><br />Rappel 1 envoyé le: <b>$date_rappel_1</b><br />Rappel 2 envoyé le: <b>$date_rappel_2</b><br />Rappel 3 envoyé le: <b>$date_rappel_3</b>";
}else{
	$date_rappel_1 = "//";
	$date_rappel_2 = "//";
	$date_rappel_3 = "//";
	$txtRappel="<br /><br /><br />Rappel 1 envoyé le: <b>$date_rappel_1</b><br />Rappel 2 envoyé le: <b>$date_rappel_2</b><br />Rappel 3 envoyé le: <b>$date_rappel_3</b>";
}



if($acces_full) {

	$dm_cfg{list_html_bottom} .= <<"EOH";

<br />
<div class="well">
<h4>Infos facturations:</h4>


<br />Etabli le: <b>$cmd{date_facturation}</b>
<br />Envoyé à: <b>$envoye_a_list</b>
<br />Envoyée le: <b>$cmd{date_dernier_envoi}</b>
<br />Payée le: <b>$cmd{date_paiement}</b>
<br />$download_fa_link
$txtRappel
</div>
EOH
}
$dm_cfg{list_html_top} .=<<"EOH";

<span id="infos_rec"></span>
<script type="text/javascript">
jQuery(document).ready(function() 
{
	jQuery('.maintitle').hide();
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



EOH


sub after_save_all
{
		
}

sub after_save
{
	my $dbh = $_[0];  
  	my $id = $_[1];	 
	
	log_debug('after_save_document','vide','after_save_document');
	
#	my $stmt = <<"EOH";
#	UPDATE intranet_factures SET documents_restants = '0'
#EOH
#	execstmt($dbh,$stmt);
	log_debug($stmt,'','after_save_document');
	my %cd = read_table($dbh,'commande_documents',$id);
	my %commande_document = read_table($dbh,'commande_documents',$id);
	my %commande = read_table($dbh,'intranet_factures',$commande_document{commande_id});

	my %migcms_linked_file = sql_line({table=>"migcms_linked_files",where=>"table_name='commande_documents' AND token='$id'"});
	my $pdf = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full};
	$pdf =~ s/\.\.\/usr/\.\.\//g;
	$pdf = $pdf.$migcms_linked_file{ext};
	$pdf =~ s/\/\//\//g;
	
	# my $migcms_last_published_file = '../files/'.$dm_cfg{file_prefixe}.'/pj/'.$commande_document{id}.'/'.$commande_document{url};
	my $migcms_last_published_file = $pdf;
	my $stmt = "UPDATE $dm_cfg{table_name} SET id_member='$commande{id_member}',migcms_last_published_file = '$migcms_last_published_file' WHERE id = '$commande_document{id}'";
	execstmt($dbh,$stmt);
	log_debug($stmt,'','after_save_document');	

#	my @commande_documents = sql_lines({table=>'commande_documents', where=>"date_prevue = '0000-00-00' "});
#	foreach $commande_document (@commande_documents)
#	{
#		my %commande_document = %{$commande_document};
#
#		my $stmt = <<"EOH";
#		UPDATE intranet_factures SET documents_restants = '1' WHERE id = '$commande_document{commande_id}'
#EOH
#		execstmt($dbh,$stmt);
#		log_debug($stmt,'','after_save_document');
#	}
#
	$stmt = <<"EOH";
	UPDATE intranet_factures c
SET 
nb_doc = 
(
    SELECT COUNT(*) FROM commande_documents doc, migcms_linked_files lnk
    WHERE
    lnk.table_name='commande_documents' 
    AND lnk.token = doc.id
    AND	doc.commande_id = c.id
)
WHERE id = '$cd{commande_id}'
EOH
	log_debug($stmt,'','after_save_document');
	execstmt($dbh,$stmt);

	my $stmt = <<"SQL";
			UPDATE intranet_factures SET documents_restants = 0,pdfs_restants = 0;
SQL
	execstmt($dbh, $stmt);
	my $stmt = <<"SQL";
			UPDATE intranet_factures SET documents_restants = 1 WHERE id IN (select commande_id from commande_documents where date_prevue = '0000-00-00' or date_prevue IS NULL)
SQL
	execstmt($dbh, $stmt);

	my $stmt = <<"SQL";
			UPDATE intranet_factures SET pdfs_restants = 1 WHERE id IN (select commande_id from commande_documents where migcms_last_published_file = '' or migcms_last_published_file IS NULL or length(migcms_last_published_file) < 5 or migcms_last_published_file LIKE '%/')
SQL
	execstmt($dbh, $stmt);
	log_debug($stmt,'','pdfs_restants');
	
#	log_debug('avertissement:'.$commande_document{avertissement},'','after_save_document');
#	if($commande_document{avertissement} eq 'y')
#	{
#		avertissement_client($commande_document{id});
#	}


	def_handmade::save_document_cree_pdf(\%commande_document);



}



%dm_filters = (
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
	
	my $js = <<"EOH";
	<script type="text/javascript">
	</script>
EOH
	
    print wfw_app_layout($js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub avertissement_client_DISABLED
{
    # my $id_document = get_quoted('id_doc');
    my $id_document = $_[0];
	
#     print $id_document;            
    my $expediteur = 'info@certigreen.be';

    my $destinataire = "";
    my $dest_nom ="";
	my $destinataire2 = "";
	my $dest_nom2 = "";
	my $destinataire3 = "";
	my $dest_nom3 = "";
    
    my %doc = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',where=>"id='$id_document'"});
    my %id_type_doc = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'types_document',where=>"id='$doc{type_document_id}'"});
    my %commande = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"id='$doc{commande_id}'"});
    my %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"id='$commande{id_member}'"});  
    my $txt = '';
	my $token_link=$member{token};
	my $token_link2='';
	my $token_link3='';
	
    if (($member{type_member} eq "Agence") || (($member{type_member} eq "Particulier") && ($member{id_agence} == 0)))
    {
        $destinataire = $member{email};
        $dest_nom = $member{firstname}." ".$member{lastname};
    }
    elsif (($member{type_member} eq "Particulier") && ($member{id_agence} != 0 ))
    {
        my %agence = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"id='$member{id_agence}'"});    
        $destinataire = $member{email};
		$destinataire2 = $agence{email};     
        $dest_nom = $agence{firstname}." ".$agence{lastname};
		$txt = "<br/>Concerne: CLIENT: $member{firstname} $member{lastname} $commande{adresse_rue} $commande{adresse_numero} $commande{adresse_cp} $commande{adresse_ville}<br/>";
		$token_link = $agence{token};
    }
	
	if(($member{type_member} eq "Particulier") && ($member{id_agence2} != 0 ))
    {
        my %agence2 = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"id='$member{id_agence2}'"});    
        $destinataire2 = $agence2{email};     
        $dest_nom2 = $agence2{firstname}." ".$agence2{lastname};
		$token_link2 = $agence2{token};
    }
	
	# if(($member{type_member} eq "Particulier") && ($member{id_agence3} != 0 ))
    # {
        # my %agence3 = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"id='$member{id_agence3}'"});    
        # $destinataire3 = $agence3{email};     
        # $dest_nom3 = $agence3{firstname}." ".$agence3{lastname};
		# $token_link3 = $agence3{token};
    # }
	
	
	#DEBUG:
	# $destinataire3 = $destinataire2 = $destinataire = 'alexis@bugiweb.com';
	
	
           

# Vous pouvez le télécharger en cliquant sur ce lien:
            # <br />
            # <a href="$htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/certigreen.pl?lg=1&extlink=1&sw=get_document&token=$commande{token}&id_document=$id_document">  
                # $htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/certigreen.pl?lg=1&extlink=1&sw=get_document&token=$commande{token}&id_document=$id_document;
            # </a>    
            # <br /><br />
			# OU
			# <br />
			
			
			
		   # &token_member=$token_link
		   # &token_member=$token_link
		   
		   
		   
    my $object = "Certigreen: document est disponible";
    my $body = <<"EOH";
            Bonjour $dest_nom, 
            <br /><br />
            Votre document "$id_type_doc{type_1}" est disponible sur notre site.
            <br />
            $txt
			<br />
			Vous pouvez vous connecter à votre espace Certigreen en cliquant sur ce lien:<br />
			 <a href="https://$config{rewrite_default_url}/cgi-bin/certigreen.pl?lg=1&extlink=1&sw=login_db&ret=espace_perso">  
                https://$config{rewrite_default_url}/cgi-bin/certigreen.pl?lg=1&extlink=1&sw=login_db&ret=espace_perso
            </a> 
            <br />
            <br />Merci pour votre confiance,
            <br />
            <br />L'équipe CERTIGREEN  
EOH
   
   	log_debug('object:'.$object,'','after_save_document');
   	log_debug('body:'.$body,'','after_save_document');
   	log_debug('expediteur:'.$expediteur,'','after_save_document');
   	log_debug('destinataire:'.$destinataire,'','after_save_document');

   my $stmt = "UPDATE commande_documents SET avertissement = 'n' WHERE id = '$id_document'";
	execstmt($dbh,$stmt);
   
   log_debug("$expediteur,$destinataire,$object,$body",'','after_save_document');
   if($destinataire ne '')
   {
    send_mail($expediteur,$destinataire,$object,$body,"html");  
}

# $token_link2
if($destinataire2 ne '')
{
my $body = <<"EOH";
            Bonjour $dest_nom2, 
            <br /><br />
            Votre document "$id_type_doc{type_1}" est disponible sur notre site..
            <br />
            $txt
			<br />
			Vous pouvez vous connecter à votre espace Certigreen en cliquant sur ce lien:<br />
			 <a href="$htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/certigreen.pl?lg=1&extlink=1&sw=login_db&token_member=&ret=espace_perso">  
                $htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/certigreen.pl?lg=1&extlink=1&sw=login_db&token_member=&ret=espace_perso
            </a> 
            <br />
            <br />Merci pour votre confiance,
            <br />
            <br />L'équipe CERTIGREEN  
EOH
   
    send_mail($expediteur,$destinataire2,$object,$body,"html");   
   	log_debug('destinataire2:'.$destinataire2,'','after_save_document');

}	
# token_link3

if($destinataire3 ne '')
{
my $body = <<"EOH";
            Bonjour $dest_nom3, 
            <br /><br />
            Votre document "$id_type_doc{type_1}" est disponible sur notre site...
            <br />
            $txt
			<br />
			Vous pouvez vous connecter à votre espace Certigreen en cliquant sur ce lien:<br />
			 <a href="$htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/certigreen.pl?lg=1&extlink=1&sw=login_db&token_member=&ret=espace_perso">  
                $htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/certigreen.pl?lg=1&extlink=1&sw=login_db&token_member=&ret=espace_perso
            </a> 
            <br />
            <br />Merci pour votre confiance,
            <br />
            <br />L'équipe CERTIGREEN  
EOH
    log_debug('destinataire3:'.$destinataire3,'','after_save_document');
    send_mail($expediteur,$destinataire3,$object,$body,"html");   
}	
	
    print "ok";
}

sub link_docs
{
	log_debug('link_docs','vide','link_docs');
	use Data::Dumper;
	
	my $where = "url !=''";
	# my $where = " commande_id='5017' AND url !=''";
	
	my @commande_documents = sql_lines({debug=>1,debug_results=>1,dbh=>$dbh,table=>"commande_documents",ordby=>"",where=>$where});
	foreach $commande_document(@commande_documents) {
		
		my %commande_document = %{$commande_document};
		
		my %commande = read_table($dbh,'intranet_factures',$commande_document{commande_id});
		
		
		#creation répertoire cible
		my $dir = $config{directory_path}.'/usr/files/'.$dm_cfg{file_prefixe}.'/pj/'.$commande_document{id};
		log_debug($dir,'','link_docs');
		unless (-d $dir) {mkdir($dir.'/') or log_debug("cannot create ".$dir.": $!");}
		
		#préparation nouvel enregistrement
		my @tabext = split(/\./,$commande_document{url});
		my $ext = '.'.$tabext[$#tabext];
		pop @tabext;
		my $filename_without_ext = join(",",@tabext);
		log_debug($commande_document{url}.','.$filename_without_ext.',.'.$ext,'','link_docs');	
		log_debug(Dumper(\%commande_document),'','link_docs');	
        my %new = (
			'table_name'=>$dm_cfg{table_name},
			'table_field'=>'pj',
			'visible'=>'y',
			'do_not_resize'=>'y',
			'token'=> $commande_document{id},
			'full'=>$filename_without_ext,
			'file'=>$commande_document{url},
			'name_small'=>'',
			'ordby'=>1,
			'size'=>'',
			'ext'=>$ext,
			'size_small'=>'',
			'width_small'=>'',
			'file_dir'=>'../usr/files/'.$dm_cfg{file_prefixe}.'/pj/'.$commande_document{id},
        );
		%new = %{quoteh(\%new)};
		log_debug(Dumper(\%new),'','link_docs');	
		#ajout/update
        my $id_migcms_linked_file = sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_linked_files',data=>\%new, where=>"token='$new{token}' AND table_name='$new{table_name}'"});
		log_debug('#'.$id_migcms_linked_file,'','link_docs');	
		
		my $migcms_last_published_file = '../files/'.$dm_cfg{file_prefixe}.'/pj/'.$commande_document{id}.'/'.$commande_document{url};
		my $stmt = "UPDATE $dm_cfg{table_name} SET id_member='$commande{id_member}',migcms_last_published_file = '$migcms_last_published_file' WHERE id = '$commande_document{id}'";
		execstmt($dbh,$stmt);
		log_debug($stmt,'','link_docs');	

		
		#copie du fichier
		my $path_origin = $config{directory_path}.'/import_usr/';
		my $path_destination = $config{directory_path}.'/usr/files/'.$dm_cfg{file_prefixe}.'/pj/'.$commande_document{id}.'/';
		copy("$path_origin/$commande_document{url}","$path_destination/$commande_document{url}");
		log_debug("copy($path_origin/$commande_document{url},$path_destination/$commande_document{url});",'','link_docs');	
		
	}	
	exit;
}


sub breadcrumb_func
{
	my $commande_id = get_quoted("commande_id");

	# my %commande_document = read_table($dbh,'commande_documents',$id);
	my %commande = read_table($dbh,'intranet_factures',$commande_id);
	my $fusion = '';
	my $np = trim($commande{lastname}.' '.$commande{firstname});
	if($np ne '')
	{
		$fusion .= "$np ";
	}
	my $rue = trim($commande{adresse_rue}.' '.$commande{adresse_numero});
	if($rue ne '')
	{
	$fusion .= "$rue ";
	}
	my $ville = trim($commande{adresse_cp}.' '.$commande{adresse_ville});
	if($ville ne '')
	{
	$fusion .= " - $ville ";
	}

	my $breadcrumb = <<"EOH";
	<ol class="breadcrumb">
			<li><a href="/cgi-bin/adm_handmade_certigreen_commandes.pl?&sel=1000278">Commandes</a></li>
			<li><a href="/cgi-bin/adm_handmade_certigreen_commandes.pl?sel=1000278&page=1&nr=25&list_keyword=DERSEARCHED&lg=1" id="searchBack">Résultats Recherche</a></li>
			<li>Documents de la commande $commande{id} : $fusion</li>
	</ol>
EOH
	
	return $breadcrumb;
	
}


sub send_document
{
	my $id = $_[0];
	my $colg = $_[1];
#	my %record = %{$_[2]};

	my %record = read_table($dbh,$dm_cfg{table_name},$id);

	my $acces = <<"EOH";

		<a href="#" data-placement="bottom" data-original-title="Déposez d'abord un document pour pouvoir l'envoyer par mail"
		id="$id" role="button" class="btn btn-link show_only_after_document_ready">
		<i class="fa fa-paper-plane-o  fa-fw" data-original-title="" title=""></i></a>
EOH

	if($record{migcms_last_published_file} ne '' && $record{migcms_last_published_file} ne '/')
	{
		$acces = <<"EOH";

		<a href="#" data-placement="bottom" data-original-title="Envoyer le document par email"
		id="$id" role="button" class="btn btn-default show_only_after_document_ready send_by_email">
		<i class="fa fa-paper-plane-o  fa-fw" data-original-title="" title=""></i></a>
EOH
	}

	#icone vert NC envoyé le xxxxx
		my %historique_facture = sql_line({debug=>1,debug_results=>1, table => 'migcms_mail_history', where =>
			"email_object LIKE '%REFD: $id' " });
		if ($historique_facture{id} > 0) {
			if($historique_facture{id_member}>0) {
				my %user_send = read_table($dbh, 'users', $historique_facture{id_member});

				my $legend = 'Document envoyé par mail le '.tools::to_ddmmyyyy($historique_facture{moment},'withtimeandbr');
				$legend .= ' par '.$user{firstname}.' '.$user{lastname};

				$acces = <<"EOH";

		<a href="#" data-placement="bottom" data-original-title="$legend"
		id="$id" role="button" class="btn btn-success show_only_after_document_ready send_by_email">
		<i class="fa fa-paper-plane-o  fa-fw" data-original-title="" title=""></i></a>
EOH
			}
		}



	return $acces;
}



sub send_rdv
{
	my $id = $_[0];
	my $colg = $_[1];
#	my %record = %{$_[2]};

	my %record = read_table($dbh,$dm_cfg{table_name},$id);




	 my $acces = <<"EOH";

		<a href="#" data-placement="bottom" data-original-title="Confirmation de rendez-vous"
		id="$id" role="button" class="btn btn-default show_only_after_document_ready send_by_email_rdv">
		<i class="fa fa-clock-o" aria-hidden="true"></i></a>
EOH



	return $acces;
}


sub download_document
{
	my $id = $_[0];
	my $colg = $_[1];
#	my %record = %{$_[2]};
	my $self = "$config{baseurl}/cgi-bin/adm_migcms_codes.pl?sel=".get_quoted('sel').'&id_code_type='.$id;

	my %record = read_table($dbh,$dm_cfg{table_name},$id);
#see(\%record);


	my $acces = <<"EOH";

		<a href="#"  data-placement="bottom"
		 data-original-title="Déposez'abord un document PDF pour pouvoir le télécharger" role="button" class="btn btn-link show_only_after_document_ready ">
		 <i class="fa fa-eye  fa-fw" data-original-title="" title=""></i></a><!-- [$record{migcms_last_published_file}]-->
EOH

	if($record{migcms_last_published_file} ne '' && $record{migcms_last_published_file} ne '/')
	{
		$record{migcms_last_published_file} =~ s/\.\.\//\.\.\/usr\//g;
		$acces = <<"EOH";

		<a href="$record{migcms_last_published_file}"  data-placement="bottom" target="_blank"
		 data-original-title="Télécharger le document PDF $record{migcms_last_published_file}" role="button" class="btn btn-default show_only_after_document_ready ">
		 <i class="fa fa-eye  fa-fw" data-original-title="" title=""></i></a>
EOH
	}

	return $acces;
}

sub download_communication
{
	my $id = $_[0];
	my $colg = $_[1];
#	my %record = %{$_[2]};
	my $self = "$config{baseurl}/cgi-bin/adm_migcms_codes.pl?sel=".get_quoted('sel').'&id_code_type='.$id;
	my %record = read_table($dbh,$dm_cfg{table_name},$id);




	my $acces = <<"EOH";

		<a href="#"  data-placement="bottom"
		 data-original-title="Sauvegardez le document pour générer la communication PDF" role="button" class="btn btn-link show_only_after_document_ready ">
		 <i class="fa fa-envelope-o  fa-fw" data-original-title="" title=""></i></a>
EOH

	if($record{communication_pdf} ne '' && $record{communication_pdf} ne '/')
	{
		$acces = <<"EOH";

		<a href="../usr/documents/$record{communication_pdf}"  data-placement="bottom" target="_blank"
		 data-original-title="Télécharger la communication pour ce document" role="button" class="btn btn-default show_only_after_document_ready ">
		 <i class="fa fa-envelope-o  fa-fw" data-original-title="" title=""></i></a>
EOH
	}

	return $acces;
}


sub action_globale_prevenir_client
{
	my $ids = get_quoted('ids');
	log_debug('action_globale_prevenir_client','','action_globale_prevenir_client');

	my @ids = split (/,/,$ids);
	foreach $id (@ids)
	{
		if($id > 0)
		{
			my $id_document = $id;

			my $expediteur = 'info@certigreen.be';
			my $destinataire = "";
			my $dest_nom ="";

			my $destinatire2 = "";
			my $dest_nom2 = "";

			my %doc = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',where=>"id='$id_document'"});
			my %id_type_doc = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'types_document',where=>"id='$doc{id_type_document}'"});
			my %commande = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"id='$doc{commande_id}'"});
			my %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"id='$commande{id_member}'"});
			my $txt = '';
			my $token_link=$member{token};
			my $token_link2='';

			log_debug("ID DOC: ".$id_document,'','action_globale_prevenir_client');
			log_debug("ID DOC TYPE: ".$doc{id_type_document},'','action_globale_prevenir_client');
			log_debug("ID COMMANDE: ".$doc{commande_id},'','action_globale_prevenir_client');
			log_debug("ID COMMANDE id_member: ".$commande{id_member},'','action_globale_prevenir_client');
			log_debug("ID member: ".$member{id},'','action_globale_prevenir_client');
			log_debug("ID Agence: ".$member{id_agence},'','action_globale_prevenir_client');
			if(!($member{id_agence} > 0))
			{
				log_debug("case 1",'','action_globale_prevenir_client');

				$destinataire = $commande{email};
				$dest_nom = $commande{firstname}." ".$commande{lastname};
			}
			elsif (($member{type_member} eq "Particulier") && ($member{id_agence} != 0 ))
			{
				log_debug("case 2",'','action_globale_prevenir_client');
				my %agence = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"id='$member{id_agence}'"});
				$destinataire = $agence{email};
				$dest_nom = $agence{firstname}." ".$agence{lastname};
				$txt = "<br/>Concerne: CLIENT: $member{firstname} $member{lastname} $commande{adresse_rue} $commande{adresse_numero} $commande{adresse_cp} $commande{adresse_ville}<br/>";
				$token_link = $agence{token};
			}

			if(($member{type_member} eq "Particulier") && ($member{id_agence2} != 0 ))
			{
				log_debug("case 2 agence 2",'','action_globale_prevenir_client');
				my %agence2 = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"id='$member{id_agence2}'"});
				$destinataire2 = $agence2{email};
				$dest_nom2 = $agence2{firstname}." ".$agence2{lastname};
				$token_link2 = $agence2{token};
			}


			my $object = "Certigreen: document est disponible";
			my $body = <<"EOH";

             Cher $dest_nom,
 <br /> <br />

Le document $id_type_doc{type_1} concernant le bien sis à $commande{adresse_ville}, $commande{adresse_rue} $commande{adresse_numero} est disponible sur votre espace client Certigreen.
 <br /> <br />
La facture concernant ce dossier peut également être téléchargée via votre espace en cliquant sur l'onglet Facture. Nous vous invitons par ailleurs à vérifier le statut de paiement avant la passation des actes.
 <br /> <br />
Vous pouvez accéder à votre espace client via le lien ci-dessous:<br />
 <a href="http://www.certigreen.be/public/connexion">http://www.certigreen.be/public/connexion</a>
 <br /> <br />
Cordialement,
 <br /> <br />
Certigreen
 <br /> <br />
Sauf demande faite au certificateur, les documents sont envoyés uniquement par voie informatique. Si vous souhaitez recevoir une version papier, n'hésitez pas à en faire la demande par réponse à cet email.
EOH

			log_debug($expediteur,'','action_globale_prevenir_client');
			log_debug($destinataire,'','action_globale_prevenir_client');
			log_debug($object,'','action_globale_prevenir_client');
			log_debug($body,'','action_globale_prevenir_client');
			send_mail($expediteur,$destinataire,$object,$body,"html");


			if($destinataire2 ne '')
			{
				my $body = <<"EOH";
            Bonjour $dest_nom2,
            <br /><br />
 <br /> <br />

Le document $id_type_doc{type_1} concernant le bien sis à $commande{adresse_ville}, $commande{adresse_rue} $commande{adresse_numero} est disponible sur votre espace client Certigreen.
 <br /> <br />
La facture concernant ce dossier peut également être téléchargée via votre espace en cliquant sur l'onglet Facture. Nous vous invitons par ailleurs à vérifier le statut de paiement avant la passation des actes.
 <br /> <br />
Vous pouvez accéder à votre espace client via le lien ci-dessous:<br />
 <a href="http://www.certigreen.be/public/connexion">http://www.certigreen.be/public/connexion</a>
 <br /> <br />
Cordialement,
 <br /> <br />
Certigreen
 <br /> <br />
Sauf demande faite au certificateur, les documents sont envoyés uniquement par voie informatique. Si vous souhaitez recevoir une version papier, n'hésitez pas à en faire la demande par réponse à cet email.
EOH
				log_debug($expediteur,'','action_globale_prevenir_client');
				log_debug($destinataire2,'','action_globale_prevenir_client');
				log_debug($object,'','action_globale_prevenir_client');
				log_debug($body,'','action_globale_prevenir_client');

				send_mail($expediteur,$destinataire2,$object,$body,"html");
			}

		}
	}





	exit;
}

sub list_calendrier2
{


	my $jours_titre = '';
	my $jours_taches = '';
	for(my $i = 0; $i <7;$i++)
	{
		my %jour = sql_line({table=>'users',limit=>'1',select=>"DATE_ADD(CURRENT_DATE,INTERVAL $i DAY) as date_jour, WEEKDAY(DATE_ADD(CURRENT_DATE,INTERVAL $i DAY)) as jour_semaine"});
		if($jour{jour_semaine} == 5 || $jour{jour_semaine} == 6)
		{
			next;
		}
		my $human_date = sql_to_human_date($jour{date_jour});
		$jours_titre .= <<"EOH";
			<th style="width:20%">
				$human_date
			</th>
EOH
		my $where_user = " id_user_to > 0 AND id_user_to='$user{id}' AND ";
		if($user{id} == 3000)
		{
			# $where_user = " id_user_to > 0 AND id_user_to='4' AND ";
			$where_user = " id_user_to > 0 AND  ";
		}

#		my @handmade_alias_taches_avec_heures = sql_lines({debug =>0,debug_results=>0,select=>"",table=>'handmade_alias_taches',where=>"$where_user objectif_date='$jour{date_jour}' AND traite != 'y' AND objectif_time != '00:00'",ordby=>"objectif_time"});
#		my @handmade_alias_taches_sans_heures = sql_lines({debug =>0,debug_results=>0,select=>"",table=>'handmade_alias_taches',where=>"$where_user objectif_date='$jour{date_jour}' AND traite != 'y' AND objectif_time = '00:00'",ordby=>""});
		$jours_taches .= <<"EOH";
			<td>
EOH
		foreach $handmade_alias_tache (@handmade_alias_taches_avec_heures)
		{

			my %handmade_alias_tache = %{$handmade_alias_tache};

			$jours_taches .= alias_calendrier_get_bloc(\%handmade_alias_tache);
		}

		foreach $handmade_alias_tache (@handmade_alias_taches_sans_heures)
		{

			my %handmade_alias_tache = %{$handmade_alias_tache};

			$jours_taches .= alias_calendrier_get_bloc(\%handmade_alias_tache);

		}

		$jours_taches .= <<"EOH";
			</td>
EOH
	}

	my $list = <<"EOH";

	<style>
	.list-group-item
	{
		background-color:#49586e!important;
		color:white!important;
	}
	.list-group-item a
	{
		color:white!important;
	}
	.list-group-item b a
	{
		/*color:#4fcf4f!important;*/
	}


	.panel
	{
		margin-top:10px;
	}
	</style>

	<table class="table tab-condensed">
		<thead>
			<tr>
				$jours_titre
			</tr>
		</thead>
		<tbody>
			<tr>
				$jours_taches
			</tr>
		</tbody>
	</table>
EOH

	print $list;
	exit;
}




sub send_by_email_rdv_txt
{
	#	log_debug('send_by_email','vide','send_by_email');
	my $id = get_quoted('id');
	#	log_debug($id,'','send_by_email');
	my $prefixe = $dm_cfg{file_prefixe};
	if($prefixe eq '')
	{
		$prefixe = sprintf("%.02d",get_quoted('sel'));
	}

	#publication du fichier si nécessaire
	my $func_publish = 'ajax_publish_pdf';
	if($dm_cfg{func_publish} ne '')
	{
		$func_publish = 'def_handmade::'.$dm_cfg{func_publish};
	}
	$pdf_filename = &$func_publish($id,lc($dm_cfg{file_prefixe}),$dm_cfg{table_name},$dm_cfg{self});

	my %record = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{table_name},where=>"id='$id'"});
	if($record{migcms_last_published_file} eq '')
	{
		$record{migcms_last_published_file} = $record{pdf_filename};
	}
	my %destinataire = ();
	if($dm_cfg{send_by_email_table_destinataire} eq '')
	{
		$dm_cfg{send_by_email_table_destinataire} = $config{send_by_email_table_destinataire};
	}
	if($dm_cfg{send_by_email_col_destinataire} eq '')
	{
		$dm_cfg{send_by_email_col_destinataire} = $config{send_by_email_col_destinataire};
	}
	if($dm_cfg{send_by_email_table_destinataire} ne '' && $dm_cfg{send_by_email_col_destinataire} ne '')
	{
		%destinataire = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_destinataire},where=>"id='$record{$dm_cfg{send_by_email_col_destinataire}}'"});
	}

	#DE
	my %license = ();
	if($dm_cfg{send_by_email_table_license} eq '')
	{
		$dm_cfg{send_by_email_table_license} = $config{send_by_email_table_license};
	}
	if($dm_cfg{send_by_email_table_license} ne '' )
	{
		if($dm_cfg{send_by_email_id_license} ne '' && $record{$dm_cfg{send_by_email_id_license}} > 0 )
		{
			%license = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_license},where=>"id='$record{$dm_cfg{send_by_email_id_license}}'"});
		}
		else
		{
			%license = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_license}});
		}
	}

	#CCI
	my %cci = ();
	if($dm_cfg{send_by_email_table_license_cci} eq '')
	{
		$dm_cfg{send_by_email_table_license_cci} = $config{send_by_email_table_license_cci};
	}
	if($dm_cfg{send_by_email_table_license_cci} eq '')
	{
		$dm_cfg{send_by_email_table_license_cci} = $dm_cfg{send_by_email_table_license};
	}
	if($dm_cfg{send_by_email_table_license_cci} ne '' )
	{
		%cci = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_license_cci}});
	}



	if($dm_cfg{send_by_email_id_template} eq '')
	{
		$dm_cfg{send_by_email_id_template} = $config{send_by_email_id_template};
	}
	if($dm_cfg{send_by_email_table_templates} eq '')
	{
		$dm_cfg{send_by_email_table_templates} = $config{send_by_email_table_templates};
	}


#	my %tpl_email_doc = ();
#	if($dm_cfg{send_by_email_table_templates} ne '' && $dm_cfg{send_by_email_id_template} ne '')
#	{
#		%tpl_email_doc = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_templates},where=>"id='$dm_cfg{send_by_email_id_template}'"});
#	}
#	else
#	{
#		my %migcms_textes_email = sql_line({table=>'migcms_textes_emails',where=>"table_name='$dm_cfg{table_name}'"});
#		$tpl_email_doc{html} = get_traduction({debug=>0,id=>$migcms_textes_email{id_textid_texte},id_language=>$config{current_language}});
#	}

	my %tpl_email_doc = sql_line({debug=>0,debug_results=>0,table=>'handmade_templates',where=>"id='28'"});

	my $message = $tpl_email_doc{html};
	if($dm_cfg{send_by_email_field1_license} eq '')
	{
		$dm_cfg{send_by_email_field1_license} = $config{send_by_email_field1_license};
	}
	if($dm_cfg{send_by_email2_field1_license} eq '')
	{
		$dm_cfg{send_by_email2_field1_license} = $config{send_by_email2_field1_license};
	}


	my $de = "$license{$dm_cfg{send_by_email_field1_license}} ";
	my $alt_de = '';
	if($license{$dm_cfg{send_by_email_field2_license}} ne '')
	{
		$de .= " ($license{$dm_cfg{send_by_email_field2_license}})";
		$alt_de = "$license{$dm_cfg{send_by_email_field2_license}}";
	}
	elsif($cci{email} ne '')
	{
		$de .= " ($cci{email})";
		$alt_de = "$cci{email}";
	}

	my $pj_name = getcode($dbh,$id,$prefixe);
	$message =~ s/{numero_document}/$pj_name/g;


	foreach my $cle_cci (keys %cci)
	{
		if($license{$cle_cci} eq '' && $cci{$cle_cci} ne '')
		{
			$license{$cle_cci} = $cci{$cle_cci};
		}

	}


	$message = map_license_fields($message,\%license);

	$message = def_handmade::map_document($message,$dm_cfg{table_name},$id,$prefixe);


	my %commande = sql_line({table=>'intranet_factures',where=>"id='$record{commande_id}'"});
	my %member = sql_line({table=>'members',where=>"id='$commande{id_member}'"});
	my %civilite = sql_line({table=>'migcms_codes',where=>"id='$member{civilite_id}'"});
	my %typedoc = sql_line({table=>'types_document',where=>"id='$member{type_document_id}'"});

	$record{date_prevue} = to_ddmmyyyy($record{date_prevue});
	$record{heure_prevue} = sql_to_human_time($record{heure_prevue});
	if($record{date_prevue} eq '//') { $record{date_prevue} = ''; }
	if($record{heure_prevue} eq 'h') { $record{heure_prevue} = ''; }

	$message =~ s/---rdvcivilite---/$civilite{code}/g;
	$message =~ s/---rdvnom---/$commande{lastname}/g;
	$message =~ s/---rdvprenom---/$commande{firstname}/g;
	$message =~ s/---rdvdate---/$record{date_prevue}/g;
	$message =~ s/---rdvheure---/$record{heure_prevue}/g;
	$message =~ s/---rdvadressebien---/$commande{adresse_rue} $commande{adresse_numero} $commande{adresse_cp} $commande{adresse_ville} /g;
	$message =~ s/---rdvtypedocument---/$typedoc{name}/g;
	$message =~ s/\r*\n/<br>/g;
#
#		---rdvcivilite---
#		---rdvnom---
#		---rdvprenom---
#		---rdvdate---
#		---rdvheure---
#		---rdvadressebien---
#		---rdvtypebien---
#		---rdvtypedocument---



	if($dm_cfg{send_by_email_field1_destinataire} eq '')
	{
		$dm_cfg{send_by_email_field1_destinataire} = $config{send_by_email_field1_destinataire};
	}
	if($dm_cfg{send_by_email_field2_destinataire} eq '')
	{
		$dm_cfg{send_by_email_field2_destinataire} = $config{send_by_email_field2_destinataire};
	}
	if($dm_cfg{send_by_email_col_objet} eq '')
	{
		$dm_cfg{send_by_email_col_objet} = $config{send_by_email_col_objet};
	}







	#construction de l'objet

	#prefixe
	my $prefixe_objet = "";
	if($dm_cfg{send_by_email_col_prefixe} ne '')
	{
		$prefixe_objet = $record{$dm_cfg{send_by_email_col_prefixe}};
		if($dm_cfg{send_by_email_col_prefixe_lbtable} ne '' && $dm_cfg{send_by_email_col_prefixe_lbdisplay} ne '')
		{
			my %lbtable_value = sql_line({table=>$dm_cfg{send_by_email_col_prefixe_lbtable},where=>"id='$record{$dm_cfg{send_by_email_col_prefixe}}'"});
			$prefixe_objet = $lbtable_value{$dm_cfg{send_by_email_col_prefixe_lbdisplay}};
			if($dm_cfg{send_by_email_col_prefixe_lbdisplay} eq 'id')
			{
				my $display_prefixe = $dm_cfg{send_by_email_col_prefixe_lbdisplay_prefixe};
				if($display_prefixe eq '')
				{
					$display_prefixe = $prefixe;
				}
				$prefixe_objet = getcode($dbh,$prefixe_objet,$prefixe);
			}
		}
		$prefixe_objet = $prefixe_objet
	}

	#suffixe
	my $suffixe_objet = "";
	if($dm_cfg{send_by_email_col_suffixe} ne '')
	{
		$suffixe_objet = $record{$dm_cfg{send_by_email_col_suffixe}};
		if($dm_cfg{send_by_email_col_suffixe_lbtable} ne '' && $dm_cfg{send_by_email_col_suffixe_lbdisplay} ne '')
		{
			my %lbtable_value = sql_line({table=>$dm_cfg{send_by_email_col_suffixe_lbtable},where=>"id='$record{$dm_cfg{send_by_email_col_suffixe}}'"});
			$suffixe_objet = $lbtable_value{$dm_cfg{send_by_email_col_suffixe_lbdisplay}};
			if($dm_cfg{send_by_email_col_suffixe_lbdisplay} eq 'id')
			{
				my $display_prefixe = $dm_cfg{send_by_email_col_suffixe_lbdisplay_prefixe};
				if($display_prefixe eq '')
				{
					$display_prefixe = $prefixe;
				}
				$suffixe_objet = getcode($dbh,$suffixe_objet,$display_prefixe);
			}
		}
		$suffixe_objet = ' - '.$suffixe_objet;
	}

	#MARQUE - PREFIXE - Titre n° PREFIXE0000ID - CEF0000XXX
	my $object = trim(trim($prefixe_objet).' - '.trim($prefixe).' - '.trim($dm_cfg{send_by_email_col_docname}).' '.trim($pj_name).' '.trim($suffixe_objet));
	$object =~ s/^\-//g;
	$object = trim($object);

	my $company = "$destinataire{$dm_cfg{send_by_email_field1_destinataire}} $destinataire{$dm_cfg{send_by_email_field2_destinataire}}";


	my $emailTo = $destinataire{$dm_cfg{send_by_email_field_email_destinataire}};

	#destinataire sur mesure
	if($dm_cfg{send_by_email_field_email_destinataire_func} ne '')
	{
		my $func = $dm_cfg{send_by_email_field_email_destinataire_func};
		$emailTo = &$func({dm_cfg=>\%dm_cfg,id=>$id,colg=>1});
	}

	#objet sur mesure
	if($dm_cfg{send_by_email_field_email_object_func} ne '')
	{
		my $func = $dm_cfg{send_by_email_field_email_object_func};
		$object = &$func({dm_cfg=>\%dm_cfg,id=>$id,colg=>1});
	}



	$self = $dm_cfg{self};

	my $cc = $record{$dm_cfg{send_by_email_col_cc}};

	$record{migcms_last_published_file} =~ s/\.pdf//g;

	my $file_pj_name = $record{migcms_last_published_file}.'.pdf';

	if($config{send_by_email_nom_simple} eq 'y')
	{
		$file_pj_name = 'Document complet N°'.$record{id};
	}

	if($config{send_by_email_pjname_equal_ojbect} eq 'y')
	{
		$file_pj_name = $object;
	}

	my $pieces_jointes = <<"EOH";
			<a data-placement="top" data-original-title="Visualiser"
			class="btn btn-default" target="_blank"
			href="../usr/documents/$record{migcms_last_published_file}">
					<i class="fa fa-eye"></i> $file_pj_name
			</a>
EOH

	if($dm_cfg{send_by_mail_less_pj} == 1)
	{
		$pieces_jointes = '';
	}

	my $file_pj_name = $record{migcms_last_published_file}.'_PRI.pdf';
	if(-e "../usr/documents/$record{migcms_last_published_file}_PRI.pdf")
	{
		if($config{send_by_email_nom_simple} eq 'y')
		{
			$file_pj_name = 'Document principal N°'.$record{id};
		}

		$pieces_jointes .= <<"EOH";
			<a data-placement="top" data-original-title="Visualiser"
			class="btn btn-default" target="_blank"
			href="../usr/documents/$record{migcms_last_published_file}_PRI.pdf">
					<i class="fa fa-eye"></i> $file_pj_name
			</a>
EOH
	}
	# else
	# {
	# $pieces_jointes .= <<"EOH";
	# "../usr/documents/$record{migcms_last_published_file}_PRI.pdf"
	# EOH
	# }

	my $file_pj_name = $record{migcms_last_published_file}.'_CGV.pdf';
	my $filesize = -s "../usr/documents/$record{migcms_last_published_file}.pdf";
	if(-e "../usr/documents/$record{migcms_last_published_file}_CGV.pdf")
	{
		if($config{send_by_email_nom_simple} eq 'y')
		{
			$file_pj_name = 'Document conditions générales N°'.$record{id};
		}

		$pieces_jointes .= <<"EOH";
			<a data-placement="top" data-original-title="Visualiser"
			class="btn btn-default" target="_blank"
			href="../usr/documents/$record{migcms_last_published_file}_CGV.pdf">
					<i class="fa fa-eye"></i> $file_pj_name
			</a>
EOH
	}





	if($dm_cfg{send_by_mail_less_pj} != 1)
	{
		my $filesize = -s "../usr/documents/$record{migcms_last_published_file}_ANX.pdf";
		my $file_pj_name = $record{migcms_last_published_file}.'_ANX.pdf';
		if(-e "../usr/documents/$record{migcms_last_published_file}_ANX.pdf" && $filesize > 1000)
		{

			if($config{send_by_email_nom_simple} eq 'y')
			{
				$file_pj_name = 'Document annexes N°'.$record{id};
			}

			$pieces_jointes .= <<"EOH";
				<a data-placement="top" data-original-title="Visualiser"
				class="btn btn-default" target="_blank"
				href="../usr/documents/$record{migcms_last_published_file}_ANX.pdf">
						<i class="fa fa-eye"></i> $file_pj_name
				</a>
EOH
		}
	}




	my $screen = <<"EOH";
	<h2>$migctrad{send_by_email_title}</h2>
	<input type="hidden" class="id_doc" value="$id" />
	<input type="hidden" class="alt_de" value="$alt_de" />
	<input type="hidden" class="prefixe_doc" value="$prefixe" />
	<input type="hidden" class="company" value="$company" />

	<div class="well form-horizontal adminex-form">
		<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_de} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 control-label mig_cms_value_col"><input type="text" class="form-control" name="send_mail_screen_from" disabled value="$de" /></div>
		</div>
		<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_a} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 mig_cms_value_col"><input type="text" class="form-control send_mail_screen_to" name="send_mail_screen_to" value="$emailTo" />
			<span class="help-block text-left"><i class="fa fa-info-circle"></i> <b>$migctrad{send_by_email_a_txt1}</b>: $migctrad{send_by_email_a_txt2}</span>
			</div>
		</div>
		<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_cc} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 mig_cms_value_col"><input type="text" class="form-control send_mail_screen_cc" name="send_mail_screen_cc" value="$cc" />
			<span class="help-block text-left"><i class="fa fa-info-circle"></i> <b>$migctrad{send_by_email_cc_txt1}</b>: $migctrad{send_by_email_cc_txt2}</span>
			</div>
		</div>
		<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_cci} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 mig_cms_value_col"><input type="text" class="form-control send_mail_screen_cci" name="send_mail_screen_cci" value="$cci{email}" />
						<span class="help-block text-left"><i class="fa fa-info-circle"></i> <b>$migctrad{send_by_email_cci_txt1}</b>: $migctrad{send_by_email_cci_txt2}</span>
			</div>
		</div>
			<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_objet} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 mig_cms_value_col"><input type="text" class="form-control send_mail_screen_object" name="send_mail_screen_object" value="$object" /></div>
		</div>
		<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_pj} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 mig_cms_value_col">
			$pieces_jointes

			</div>
		</div>
		<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_msg} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 mig_cms_value_col"><textarea name="message" style="min-height:300px" class="wysiwyg send_mail_screen_message form-control">$message</textarea></div>
		</div>


	</div>

	<div class="row">
		<div class="col-md-12 text-right">
					<a data-placement="top" data-original-title="$migctrad{back}" class="btn btn-lg btn-default show_only_after_document_ready cancel_edit c7" aria-hidden="true">$ICONCANCEL</i></a>
			<a class="btn btn-lg btn-success send_mail_screen_submit" data-placement="top" data-original-title="$migctrad{action_email}"><i class="fa fa-paper-plane-o" aria-hidden="true"></i></a>
		</div>
	</div>


EOH

	print $screen;
	exit;
}

