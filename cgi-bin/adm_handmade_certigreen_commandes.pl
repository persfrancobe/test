#!/usr/bin/perl -I../lib
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use dm_publish_pdf;
use def_handmade;

my $id = get_quoted('id');
my $sel = get_quoted('sel');
my $mine = get_quoted('mine') || 'n';
my $agence = get_quoted('agence');
my $client = get_quoted('client');
my $adresse = get_quoted('adresse');
my $filter_tel = get_quoted('filter_tel');

my $SEL_COMMANDES = 1000278;
my $SEL_FACTURES = 1000273;
my $next_number_invoice = '';

my %ouinon10 = (
	'1/1'=>'Non',
	'1/0'=>'Oui',
);

#see(\%user);

my $acces_full = 0;
if($user{id_role} > 0 && $user{id_role} < 9)
{
    $acces_full = 1;
}



my $stmt = <<"SQL";
			update intranet_factures f set date_dernier_envoi = (select date from migcms_history where page_record = 'com' AND id_record = f.id order by date desc limit 0,1)
SQL
execstmt($dbh, $stmt);


$dm_cfg{enable_search} = 1;
$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{autocreation} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{file_prefixe} = 'com';
$dm_cfg{javascript_custom_func_form} = 'after_load';
$dm_cfg{do_no_empty_migcms_last_published_file} = 'y';
my $where_supp = '';



my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year+=1900;
$mon++;

my $now = $year.'-'.$mon.'-'.$mday.' '.$hour.':'.$min;


#commandes ou factures avec N° ou NC avec N° + variante pr ceux de l'employe slt
$dm_cfg{wherel} = "validation = 1 AND (type_facture IS NULL OR type_facture = '' OR (type_facture='Facture' AND numero_facture > 0) OR (type_facture='nc' AND numero_nc > 0))  ";
if($mine eq 'y')
{
	$dm_cfg{wherel} = "id_employe='$user{id}' and validation = 1 AND (type_facture IS NULL OR type_facture = '' OR (type_facture='Facture' AND numero_facture > 0) OR (type_facture='nc' AND numero_nc > 0)) ";
}

$filter_tel = trim($filter_tel);
$filter_tel =~ s/\+32//g;
$filter_tel =~ s/^32//g;
$filter_tel =~ s/[^0-9]//g;

#see();
#print $filter_tel;
#exit;
if($filter_tel ne '')
{
	$dm_cfg{wherel} = " ( tel LIKE '%$filter_tel%' OR tel LIKE '$filter_tel%' OR tel LIKE '$filter_tel') ";
}

$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "intranet_factures";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_handmade_certigreen_commandes.pl?agence=$agence&client=$client&adresse=$adresse";
$dm_cfg{show_id} = 0;
$dm_cfg{validation_func} = \&validation_func;

$dm_cfg{default_ordby}='id desc';

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{breadcrumb_func}= \&breadcrumb_func;
#$dm_cfg{after_add_ref} = \&after_save_add;
$dm_cfg{after_add_ref} = \&after_save;

if($acces_full) {

    #$dm_cfg{'list_custom_action_1_func'} = \&reglement;
    $dm_cfg{'list_custom_action_11_func'} = \&download_fa;
    $dm_cfg{'list_custom_action_12_func'} = \&sendmail;
    $dm_cfg{'list_custom_action_13_func'} = \&nc;

    $dm_cfg{'list_custom_action_14_func'} = \&rappel1;
    $dm_cfg{'list_custom_action_15_func'} = \&rappel2;
    $dm_cfg{'list_custom_action_16_func'} = \&rappel3;

    $dm_cfg{'list_custom_action_17_func'} = \&rappel1pdf;
    $dm_cfg{'list_custom_action_18_func'} = \&rappel2pdf;
    $dm_cfg{'list_custom_action_19_func'} = \&rappel3pdf;


}
$dm_cfg{send_by_email_table_license} = 'handmade_certigreen_licenses';
$dm_cfg{send_by_email_field1_license} = 'license_name';
$dm_cfg{send_by_email_field2_license} = 'email';
#$dm_cfg{send_by_email_table_destinataire} = 'members';
#$dm_cfg{send_by_email_col_destinataire} = 'id_member';
#$dm_cfg{send_by_email_field1_destinataire} = 'fusion_short';
#$dm_cfg{send_by_email_field_email_destinataire} = 'email';

$dm_cfg{send_by_email_field_email_destinataire_func} = 'def_handmade::handmade_emailto_commande';
$dm_cfg{send_by_email_field_email_object_func} = 'def_handmade::handmade_object_commande';
$dm_cfg{send_by_email_field_email_body_func} = 'def_handmade::handmade_body_commande';




$dm_cfg{send_by_email_table_templates} = 'handmade_templates';

$dm_cfg{custom_add_button_icon} = '<i class="fa fa-fw fa-arrow-circle-o-right "></i>';$dm_cfg{custom_add_button_txt} = 'Sauvegarder + Etape suivante (Facture)';
$dm_cfg{custom_add_button_id} = 'details_doc';
$dm_cfg{custom_edit_button_txt} = '<i class="fa fa-fw fa-arrow-circle-o-right "></i>';$dm_cfg{custom_add_button_txt} = 'Sauvegarder + Etape suivante (Facture)';
$dm_cfg{custom_edit_button_id} = 'details_doc';

if($acces_full) {

    $dm_cfg{custom_global_action_func} = "rappel1";
    $dm_cfg{custom_global_action_title} = "";
    $dm_cfg{custom_global_action_icon} = 'Rappel 1';

    $dm_cfg{custom_global_action2_func} = "rappel2";
    $dm_cfg{custom_global_action2_title} = "";
    $dm_cfg{custom_global_action2_icon} = 'Rappel 2';

    $dm_cfg{custom_global_action3_func} = "rappel3";
    $dm_cfg{custom_global_action3_title} = "";
    $dm_cfg{custom_global_action3_icon} = 'Rappel 3';
}

#ECRAN COOMMANDES*******************************************************************************************************
if($sel == $SEL_COMMANDES)
{
	$dm_cfg{wherel} .= " AND (numero_nc IS NULL or numero_nc = 0)";


	%dm_display_fields =
		(
			sprintf("%05d", 2)."/Date"=>"date_mission",
			sprintf("%05d", 8)."/Agence"=>"id_member_agence",
			sprintf("%05d", 9)."/Agence2"=>"id_agence2",
#			sprintf("%05d", 92)."/N°FA"=>"numero_facture",
#			sprintf("%05d", 20)."/Total"=>"montant_a_payer_tvac",
#			sprintf("%05d", 22)."/Restant"=>"montant_restant",
			sprintf("%05d", 93)."/Forcer Payé"=>"forcer_paye",
			sprintf("%05d", 94)."/Docs?"=>"deverrouiller_documents",
			sprintf("%05d", 95)."/Remarque"=>"remarque_facturation",
		);

    if(!$acces_full) {

        delete $dm_display_fields{'00093/Forcer Payé'};
        delete $dm_display_fields{'00094/Docs?'};
    }


	%dm_lnk_fields =
		(
			sprintf("%05d", 5)."/Bien/commande_col_adresse"=>"commande_col_adresse*",
			sprintf("%05d", 6)."/Propriétaire/commande_col_client"=>"commande_col_client*",
			sprintf("%05d", 7)."/Facturation/commande_col_factu"=>"commande_col_factu*",


#			sprintf("%05d", 3)."/N° et statut/numero_fac"=>"numero_fac*",

			sprintf("%05d", 21)."/Paiements/liste_montant"=>"liste_montants*",
			sprintf("%05d", 90)."/Documents/liste_documents"=>"liste_documents*",


		);
	%dm_mapping_list = (
		"commande_col_client" => \&commande_col_client,
		"commande_col_factu" => \&commande_col_factu,
		"commande_col_adresse" => \&commande_col_adresse,
		"liste_documents" => \&liste_documents,
		"liste_montants" => \&liste_montants,
#		"numero_fac" => \&numero_fac,

	);


	%dm_filters =
		(
			"1/Dates complétées ?"=>
			{
				'type'=>'hash',
				'ref'=>\%ouinon10,
				'col'=>'documents_restants'
			}
	,	"2/PDF complétés ?"=>
			{
				'type'=>'hash',
				'ref'=>\%ouinon10,
				'col'=>'pdfs_restants'
			}
#			,
#			"70/Employé"=>
#			{
#				'type'=>'lbtable',
#				'table'=>'users',
#				'key'=>'id',
#				'display'=>"CONCAT(firstname,' ',lastname)",
#				'lbordby'=>"ordby",
#				'col'=>'id_employe',
#				'where'=>"(id_role IN ('7','8') and id != '25')"
#			}
			,
			"80/Agence-Notaire"=>
			{
				'type'=>'lbtable',
				'table'=>'members',
				'key'=>'id',
				'display'=>"CONCAT(lastname, ' ',firstname)",
				'lbordby'=>"lastname",
				'ordby'=>"lastname",
				'col'=>'id_member_agence',
				'where'=>"type_member IN('Agence','Notaire') and lastname != '' AND id IN (select distinct(id_member_agence) from intranet_factures)"
			}
			,
			"15/Dates"=>{
				'type'=>'fulldaterange',
				'col'=>'date_mission',
			}
			,
			"91/Rue bien"=>{
				'type'=>'text',
				'col'=>'adresse_rue',
			},
			"92/Nom propriétaire"=>{
				'type'=>'text',
				'col'=>'lastname',
			}
		);


		@dm_nav =
		(
			{
				'tab'=>'Bien',
				'type'=>'tab',
				'title'=>'Commande'
			}
			,
			{
				'tab'=>'Documents',
					'type'=>'tab',
					'disable_add'=>0,
					'title'=>'Documents'
			}
	,
			{
				'tab'=>'Facture',
				'type'=>'tab',
				'disable_add'=>1,
				'title'=>'Facture'
			}
		,
		{
			'tab'=>'nc',
			'type'=>'tab',
			'disable_add'=>1,
			'title'=>'Note de crédit'
		}

		);

}
else
{
	#ECRAN "FACTURES"***************************************************************************************************
	$dm_cfg{wherel} .= " AND (numero_nc > 0 OR numero_facture > 0)";

	%dm_display_fields =
		(
			"00001/Date"=>"date_facturation",
			"00002/Type"=>"type_facture",
#			"00011/TTC"=>"montant_a_payer_tvac",
#			"00012/Statut"=>"statut",
#			"00014/Ech"=>"date_echeance",
			"00024/Nbj.Ech"=>"nbjours_echeance",
			"00028/Envoyée à"=>"envoyee_a",

			sprintf("%05d", 29)."/Remarque"=>"remarque_facturation",


		);


	%dm_lnk_fields =
		(
			sprintf("%05d", 23)."/Paiements/liste_montant"=>"liste_montants*",

			#			sprintf("%05d", 3)."/N° et statut/numero_fac"=>"numero_fac*",
			sprintf("%05d", 19)."/Bien/commande_col_adresse"=>"commande_col_adresse*",

			sprintf("%05d", 20)."/Propriétaire/commande_col_client"=>"commande_col_client*",
			sprintf("%05d", 21)."/Facturation/commande_col_factu"=>"commande_col_factu*",

		);

	%dm_mapping_list = (
		"commande_col_client" => \&commande_col_client,
		"commande_col_factu" => \&commande_col_factu,
		"liste_montants" => \&liste_montants,

		"commande_col_adresse" => \&commande_col_adresse,
#		"numero_fac" => \&numero_fac,

	);

	%dm_filters = (
		"2/Dates"=>{
			'type'=>'fulldaterange',
			'col'=>'date_facturation',
		}
		,
		"3/Propriétaire"=>
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

	@dm_nav =
		(
			{
				'tab'=>'Facture',
					'type'=>'tab',
					'disable_add'=>1,
					'title'=>'Facture'
			}
			,
			{
				'tab'=>'nc',
				'type'=>'tab',
				'disable_add'=>1,
				'title'=>'Note de crédit'
			}
			,
			{
				'tab'=>'Bien',
				'type'=>'tab',
				'title'=>'Commande'
			}
			,
			{
				'tab'=>'Documents',
				'type'=>'tab',
				'disable_add'=>0,
				'title'=>'Documents'
			}

		);
}


my $document_name = 'facture';

 my $js = <<"EOH";
		
		<script type="text/javascript">
						
			jQuery(document).ready( function () 
			{   
				jQuery(document).on("click", ".button_field_recopier_client", function()
				{
					jQuery("#field_street").val(jQuery("#field_adresse_rue").val());
					jQuery("#field_number").val(jQuery("#field_adresse_numero").val());
					jQuery("#field_zip").val(jQuery("#field_adresse_cp").val());
					jQuery("#field_city").val(jQuery("#field_adresse_ville").val());
					return false;
				});
				
				jQuery(document).on("click", ".button_field_recopier_facture", function()
				{
					//jQuery("#field_facture_societe_nom").val(jQuery("#field_societe_nom").val());

					jQuery("#field_facture_nom").val(jQuery("#field_lastname").val());
					jQuery("#field_facture_prenom").val(jQuery("#field_firstname").val());
					jQuery("#field_facture_street").val(jQuery("#field_street").val());
					jQuery("#field_facture_number").val(jQuery("#field_number").val());
					jQuery("#field_facture_zip").val(jQuery("#field_zip").val());
					jQuery("#field_facture_city").val(jQuery("#field_city").val());
					jQuery("#field_facture_email").val(jQuery("#field_email").val());
					jQuery("#field_facture_emailb").val(jQuery("#field_emailb").val());
					//jQuery("#field_city").val(jQuery("#field_firstname").val());
					return false;
				});
				
				jQuery(document).on("click", ".button_field_editer_client", function()
				{
					var id_member = jQuery('input[name="id_member"]').val();
					var url = "$config{baseurl}/cgi-bin/adm_handmade_certigreen_members.pl?sw=add_form&sel=1000277&id="+id_member;
					var win = window.open(url, '_blank');
					win.focus();					
					return false;
				});
				
				jQuery(document).on("click", ".button_field_editer_facture", function()
				{
					var id_member = jQuery('input[name="facture_id_member"]').val();
					var url = "$config{baseurl}/cgi-bin/adm_handmade_certigreen_members.pl?sw=add_form&sel=1000277&id="+id_member;
					var win = window.open(url, '_blank');
					win.focus();					
					return false;
				});
				
				/*
				jQuery(document).on("click", ".ajouter_client", function()
				{
					if(jQuery('.line_client:first').hasClass('hide'))
					{
						jQuery('.line_client').removeClass('hide');
						jQuery('.ajouter_client span').html('-');
					}
					else
					{
						jQuery('.line_client').addClass('hide');
						jQuery('.ajouter_client span').html('+');						
					}
					
					if(jQuery('input[name="id_member"]').val()>0)
					{
						jQuery('.line_client input,.line_client a').attr('disabled','disabled');
					}
					
					return false;
				});



				jQuery(document).on("click", ".ajouter_facturation", function()
				{
					if(jQuery('.line_facturation:first').hasClass('hide'))
					{
						jQuery('.line_facturation').removeClass('hide');
						jQuery('.ajouter_facturation span').html('-');
					}
					else
					{
						jQuery('.line_facturation').addClass('hide');
						jQuery('.ajouter_facturation span').html('+');						
					}
					
					if(jQuery('input[name="facture_id_member"]').val()>0)
					{
						jQuery('.line_facturation input,.line_facturation a').attr('disabled','disabled');
					}
					return false;
				});
				*/

				jQuery(document).on("click", ".send_by_email_rappel1", send_by_email_rappel1);
				jQuery(document).on("click", ".send_by_email_rappel2", send_by_email_rappel2);
				jQuery(document).on("click", ".send_by_email_rappel3", send_by_email_rappel3);

			});








function send_by_email_rappel1()
{
	var id = jQuery(this).attr('id');
	send_by_email_rappel_num(1,id);
}


function send_by_email_rappel2()
{
	var id = jQuery(this).attr('id');
	send_by_email_rappel_num(2,id);
}


function send_by_email_rappel3()
{
	var id = jQuery(this).attr('id');
	send_by_email_rappel_num(3,id);
}




function send_by_email_rappel_num(num,id)
{
	console.log('clic send_by_email_rappel_num'+num);
	var prefixe = jQuery(".prefixe").val();
	scrollbarposition = jQuery(document).scrollTop();
	//var id = jQuery(this).attr('id');
	var self = get_self('full');
	jQuery("#edit_form_container").html('Chargement...');

	swal({
	  title: "Préparation de l'email...",
	  text: "Préparation de l'email de rappel...",
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
			sw : 'send_by_email_rappel'+num,
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
		<style>
		.ajouter_client,.ajouter_facturation
		{
			cursor:pointer;
			/*font-weight:bold;*/
		}
		.alert
		{
			padding:3px!important;
		}
		</style>
EOH

$dm_cfg{list_html_top} .= $js.def_handmade::get_denom_style_et_js();
$dm_cfg{list_html_top} .= <<"EOH";
<input type="hidden" class="prefixe" name="prefixe" value="commande" />


<script src="$config{baseurl}/custom_skin/js/certigreen_intranet_handmade.js"></script>
<script>
jQuery(document).ready(function() 
{
	init_button_document('intranet_factures');
});
</script>
<style>
.dm_lock_off 
{
}
#edit_form_container .admin_edit_save
{
}
</style>


<span id="infos_rec"></span>
<script type="text/javascript">
jQuery(document).ready(function() 
{
	jQuery('.maintitle,.breadcrumb').hide();
	jQuery(document).on("click", ".dm_migedit", dm_migedit_members);
	jQuery(document).on("click", ".cancel_edit ", removenomexposant);
	jQuery(document).on("click", ".admin_edit_save ", removenomexposant);
});

function after_load()
{
	jQuery("#add_rdv").click(function()
	{
		jQuery(".new_rdv.hide:first").removeClass('hide');
	});

	var typeFacture = jQuery("#field_type_facture").val();
	console.log(typeFacture);

	if(typeFacture == '02/nc')
	{
		jQuery('.dm_nav_li_Facture').hide();
	}
	else
	{
			jQuery('.dm_nav_li_nc').hide();
	}

}


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


$dm_cfg{list_html_bottom} = <<"EOH";
<style>
.list_action a.disabled
{
	color:grey;
}
</style>
<script>
jQuery(document).ready(function() 
{
	jQuery(document).on("change", 'input[name="id_member"]', change_id_member);
	jQuery(document).on("change", 'input[name="facture_id_member"]', change_facture_id_member);
});

function change_id_member()
{
	var new_id_member = jQuery('input[name="id_member"]').val();
	var request = jQuery.ajax(
    {
        url: self,
        type: "GET",
        data: 
        {
           sw : 'commande_get_member_info',
           new_id_member : new_id_member
        },
        dataType: "html"
    });
    
    request.done(function(msg) 
    {
		var result = msg.split('___');
		jQuery('input[name="lastname"]').val(result[0]);	
		jQuery('input[name="firstname"]').val(result[1]);	

		if(result[3] == 'Particulier')
		{
			jQuery('#Particulier').click();
		}
		if(result[3] == 'Agence')
		{
			jQuery('#Agence').click();
		}
		jQuery('input[name="street"]').val(result[4]);	
		jQuery('input[name="number"]').val(result[5]);	
		jQuery('input[name="zip"]').val(result[6]);	
		jQuery('input[name="city"]').val(result[7]);	
		jQuery('input[name="tel"]').val(result[8]);	
		jQuery('input[name="email"]').val(result[9]);	
		jQuery('input[name="emailb"]').val(result[10]);	
		jQuery('input[name="id_agence"]').val(result[11]);	
		jQuery('input[name="id_agence2"]').val(result[12]);	
		jQuery('input[name="facture_civilite_id"]').val(result[13]);

	});
}

function change_facture_id_member()
{
	var new_id_member = jQuery('input[name="facture_id_member"]').val();
	var request = jQuery.ajax(
    {
        url: self,
        type: "GET",
        data: 
        {
           sw : 'commande_get_member_info',
           new_id_member : new_id_member
        },
        dataType: "html"
    });
    
    request.done(function(msg) 
    {
		var result = msg.split('___');
		jQuery('input[name="facture_nom"]').val(result[0]);	
		jQuery('input[name="facture_prenom"]').val(result[1]);	
		jQuery('input[name="facture_societe_tva"]').val(result[2]);	

		
		jQuery('input[name="facture_street"]').val(result[4]);	
		jQuery('input[name="facture_number"]').val(result[5]);	
		jQuery('input[name="facture_zip"]').val(result[6]);	
		jQuery('input[name="facture_city"]').val(result[7]);	

		jQuery('input[name="facture_email"]').val(result[9]);	
		jQuery('input[name="facture_emailb"]').val(result[10]);
		jQuery('input[name="facture_civilite_id"]').val(result[13]);

		jQuery('input[name="autocomplete_facture_civilite_id"]').val(result[14]);

	});
}


function custom_func_list()
{
	//jQuery('.list_actions_2').removeClass('list_actions_2').addClass('list_actions_6');
}

function get_request_body()
{
    jQuery(".admin_list_pageloader").show();
    jQuery("#sorting_box").hide();
	custom_func_list();
    
    var page = jQuery("#page").val();
	var colg = jQuery(".colg").val();
    var nr = jQuery("#nr").val();
    var list_keyword = jQuery("#list_keyword").val();
	var list_tags_vals = jQuery("#list_tags_vals").val();
    var list_specific_col = jQuery("#list_specific_col").val();
    var list_count_filters = parseInt(jQuery("#list_count_filters").val());
    var filters = '';
    var sort_field_name = jQuery("#sort_field_name").val();
    var sort_field_sens = jQuery("#sort_field_sens").val();
        
    for(var i = 1;i<list_count_filters;i++)
    {
        var name = jQuery("#list_filter_"+i).attr('name');
        var value = jQuery("#list_filter_"+i).val();
        filters += name+'---'+value+'___';    
    }
    
    var nb_col = jQuery("#migc4_main_table thead tr th").length;
    jQuery(".admin_list_pageloader img").fadeIn();
    
	var report_range_name = jQuery('.report_range').attr('name');
	var report_range_value = jQuery('.report_range').val();
	
    var list_func = jQuery("#list_func").val();
	//alert(list_func);
	var render = 'html';
    var request = jQuery.ajax(
    {
        url: self,
        type: "GET",
        data: 
        {
           sw : list_func,
		   selection : 'COUNT(*) as result',
           page : page,
           nr : nr,
           list_keyword : list_keyword,
		   list_tags_vals : list_tags_vals,
           list_specific_col : list_specific_col,
           filters : filters,
		   lg : colg,
           render : render,
		   report_range_name : report_range_name,
           report_range_value : report_range_value,
           sort_field_name : sort_field_name,
           sort_field_sens : sort_field_sens,
		   restauration_active: jQuery("#restauration_active").val()
        },
        dataType: "html"
    });
    
    request.done(function(msg) 
    {
			jQuery('.nb_commandes').html(msg);
	});      
	
	var request2 = jQuery.ajax(
    {
        url: self,
        type: "GET",
        data: 
        {
           sw : list_func,
		   selection : 'SUM(nb_doc) as result',
           page : page,
           nr : nr,
           list_keyword : list_keyword,
		   list_tags_vals : list_tags_vals,
           list_specific_col : list_specific_col,
           filters : filters,
		   lg : colg,
           render : render,
		   report_range_name : report_range_name,
           report_range_value : report_range_value,
           sort_field_name : sort_field_name,
           sort_field_sens : sort_field_sens,
		   restauration_active: jQuery("#restauration_active").val()
        },
        dataType: "html"
    });
    
    request2.done(function(msg) 
    {
			jQuery('.nb_docs').html(msg);
	}); 
        
  request.fail(function(jqXHR, textStatus) 
  {
  });
}
</script>


EOH


%choix = (
    '01/1'=>"Oui",
    '02/0'=>"Non",
);
%cle = (
    '01/1'=>"Oui",
    '02/0'=>"Non",
);
%envoie_facture = (
    '01/1'=>"Agence",
    '02/0'=>"Propriétaire",
);	
my $cpt = 9;
$tab = 'Bien';

%types_factures= (
	'01/facture'=>"Facture",
	'02/nc'=>"NC",
);

	%type_member = (
    '00/Agence'=>"Agence",
    '01/Notaire'=>"Notaire",
    '02/Particulier'=>"Particulier",
);

%type_agence = (
    '01/agence'=>"Agence",
    '02/notaire'=>"Notaire",
);


%lier_client = (
    '01/lier'=>"Lier à un compte propriétaire existant",
    '02/libre'=>"Encoder librement des coordonnées",
);

%dm_dfl = 
(
	sprintf("%05d", $cpt++).'/titre'=>{'title'=>'Bien','translate'=>0,'fieldtype'=>'titre','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab="Bien",'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
#	sprintf("%05d", $cpt++).'/type_bien_id'=>{'title'=>'Type de bien','translate'=>0,'list_edit'=>1,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'n','mandatory'=>{"type" => 'not_empty'},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"visible='y'",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/type_facture'=>{'title'=>'Type','translate'=>0,'fieldtype'=>'listbox',default_value => '','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>\%types_factures,'hidden'=>1},

#	sprintf("%05d", $cpt++).'/id_employe'=>{default_value=>25,'title'=>'Employé','list_edit'=>1,'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'users','lbkey'=>'id','lbdisplay'=>"CONCAT(firstname,' ',lastname)",'lbwhere'=>"(id_role='8' or id_role='7')",'lbordby'=>"firstname,lastname",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/date_mission'=>{'default_value'=>$now,'title'=>'Date commande','translate'=>0,'fieldtype'=>'text','data_type'=>'datetime','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/adresse_rue'=>{'title'=>'Rue','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/adresse_numero'=>{'title'=>'Numéro','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/adresse_cp'=>{'title'=>'Code postal','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/adresse_ville'=>{'title'=>'Ville','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
    sprintf("%05d", $cpt++).'/cle_disponible'=>{'title'=>'Cle disponible à l\'agence','translate'=>0,'fieldtype'=>'checkbox','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/remarque'=>{'title'=>'Remarque','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/titre'=>{'title'=>'Propriétaire','translate'=>0,'fieldtype'=>'titre','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_member'=>{'title'=>'Compte propriétaire','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/lastname'=>{'title'=>'Nom *','class'=>$line_class='line_client ','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/firstname'=>{'title'=>'Prénom','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
#	sprintf("%05d", $cpt++).'/societe_tva'=>{'title'=>'TVA','class'=>$line_class='line_client ','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/type_member'=>{default_value=>'Particulier','title'=>'Type','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_member,'hidden'=>1},
	sprintf("%05d", $cpt++).'/recopier_client'=>{'title'=>'Recopier les coordonnées du bien ci-desssus','bouton_class'=>'btn btn-primary','translate'=>0,'fieldtype'=>'button','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/street'=>{'title'=>'Rue','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/number'=>{'title'=>'Numéro','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/zip'=>{'title'=>'Code postal','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/city'=>{'title'=>'Ville','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/tel'=>{'title'=>'Téléphone','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/email'=>{'title'=>'Email','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'email','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/emailb'=>{'title'=>'Email 2','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'email','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/id_member_agence'=>{'title'=>'Agence','class'=>$line_class,'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>('CONCAT(members.lastname," ",members.firstname)'),'lbwhere'=>"type_member IN('Agence','Notaire') and lastname != ''",'lbordby'=>"",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/id_agence2'=>{'title'=>'Agence 2','class'=>$line_class,'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>('CONCAT(members.lastname," ",members.firstname)'),'lbwhere'=>"type_member IN('Agence','Notaire') and lastname != ''",'lbordby'=>"",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/titre'=>{'title'=>'Facturation','translate'=>0,'fieldtype'=>'titre','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_id_member'=>{'title'=>'Compte propriétaire','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/recopier_facture'=>{'title'=>'Recopier les coordonnées du propriétaire ci-dessus','bouton_class'=>'btn btn-primary','translate'=>0,'fieldtype'=>'button','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_civilite_id'=>{'title'=>'Civilité','class'=>$line_class='line_facturation ','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'migcms_codes','lbkey'=>'id','lbdisplay'=>'v1','lbwhere'=>"id_code_type='1' and visible='y'",'lbordby'=>"v1",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_nom'=>{'title'=>'Nom *','class'=>$line_class='line_facturation ','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_prenom'=>{'title'=>'Prénom','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_societe_tva'=>{'default_value'=>'N.A.','title'=>'TVA','class'=>$line_class='line_facturation ','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_street'=>{'title'=>'Rue','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_number'=>{'title'=>'Numéro','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_zip'=>{'title'=>'Code postal','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_city'=>{'title'=>'Ville','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_country'=>{'title'=>'Pays','default_value'=>'Belgique','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_email'=>{'title'=>'Email','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'email','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_emailb'=>{'title'=>'Email secondaire','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'email','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},

	sprintf("%05d", $cpt++).'/date_facturation'=>{'title'=>'Date facturation - NC','translate'=>0,'fieldtype'=>'text',default_value => '','data_type'=>'date','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/date_dernier_envoi'=>{'title'=>'Date de dernier envoi','translate'=>0,'fieldtype'=>'text',default_value => '','data_type'=>'date','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/date_paiement'=>{'title'=>'Date de paiement','translate'=>0,'fieldtype'=>'text',default_value => '','data_type'=>'date','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/montant_a_payer_htva'=>{'title'=>'Total HTVA','translate'=>0,'fieldtype'=>'display','data_type'=>'euros','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/montant_a_payer_tvac'=>{'title'=>'Total TVAC','translate'=>0,'fieldtype'=>'display','data_type'=>'euros','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/member_id_commission'=>{'title'=>'Commission','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},

	sprintf("%05d", $cpt++).'/montant_commission'=>{'title'=>'Montant Commission','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'euros','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},

	sprintf("%05d", $cpt++).'/titre'=>{'title'=>'Commande liée','translate'=>0,'fieldtype'=>'titre','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'migcms_codes','lbkey'=>'id','lbdisplay'=>'v1','lbwhere'=>"id_code_type='2' and visible='y'",'lbordby'=>"v1",'fieldvalues'=>\%type_agence,'hidden'=>0},

	sprintf("%03d", $cpt++).'/id_facture_liaison'=>{'title'=>"Commande liée",'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'intranet_factures','lbkey'=>'id','lbdisplay'=>"fusion_facture",'lbwhere'=>"",'lbordby'=>"fusion_facture desc",'fieldvalues'=>'','hidden'=>0},

	sprintf("%05d", $cpt++).'/titre'=>{'title'=>'Communication','translate'=>0,'fieldtype'=>'titre','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'migcms_codes','lbkey'=>'id','lbdisplay'=>'v1','lbwhere'=>"id_code_type='2' and visible='y'",'lbordby'=>"v1",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/id_code_cible'=>{'default_value'=>7,'title'=>'Envoyer à ...','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'migcms_codes','lbkey'=>'id','lbdisplay'=>'v1','lbwhere'=>"id_code_type='2' and visible='y'",'lbordby'=>"v1",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/code_promo'=>{'default_value'=>'','title'=>'Code promo','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'migcms_codes','lbkey'=>'id','lbdisplay'=>'v1','lbwhere'=>"id_code_type='2' and visible='y'",'lbordby'=>"v1",'fieldvalues'=>\%type_agence,'hidden'=>0},

	sprintf("%05d", $cpt++).'/numero_facture'=>{'title'=>'N° Facture','translate'=>0,'fieldtype'=>'text',default_value => '','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab='Facture','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/statut'=>{"default_value"=>2,'title'=>'Statut','importcode'=>'1','translate'=>0,'list_edit'=>0,'list_edit_clean_prefixe'=>0,'fieldtype'=>'display','data_type'=>'listboxtable','search' => 'y','mandatory'=>{"type" => 'not_empty'},tab=>$tab,'lbtable'=>'handmade_certigreen_statuts_facturation','lbkey'=>'id','lbdisplay'=>'nom','lbwhere'=>"",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/forcer_paye'=>{'title'=>'Forcer payé','legend'=>'','translate'=>0,'fieldtype'=>'checkbox',default_value => '','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/forcer_paiement_acte'=>{'title'=>'Forcer paiement acte','legend'=>'','translate'=>0,'fieldtype'=>'checkbox',default_value => '','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},

	sprintf("%05d", $cpt++).'/delai'=>{'title'=>'Délai','importcode'=>'1','translate'=>0,'list_edit'=>0,'list_edit_clean_prefixe'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'handmade_certigreen_delais_facturation','lbkey'=>'id','lbdisplay'=>'nom','lbwhere'=>"",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/delai_autre'=>{'disable_add'=>0,'title'=>'Autre délai','importcode'=>'1','translate'=>0,'list_edit'=>0,'list_edit_clean_prefixe'=>0,'fieldtype'=>'text','mask'=>'999','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'handmade_certigreen_delais_facturation','lbkey'=>'id','lbdisplay'=>'nom','lbwhere'=>"",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/date_echeance'=>{'title'=>'Date échéance','translate'=>0,'fieldtype'=>'text','data_type'=>'date','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/reference'=>{'title'=>'Référence','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/remarque_facturation'=>{'title'=>'Message facturation','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
#	sprintf("%05d", $cpt++).'/montant_restant'=>{'title'=>'Montant restant','translate'=>0,'fieldtype'=>'text','data_type'=>'euros','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},

#	sprintf("%03d", $cpt++).'/id_type_reglement'=>{'hide_update'=>0,'default_value'=>'5','title'=>"Déjà payé par",'legend'=>'Ajoute automatiquement un règlement pour cette facture si elle n\'en a pas encore','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},'tab'=>$tab,'lbtable'=>'handmade_certigreen_statuts_reglement','lbkey'=>'id','lbdisplay'=>"nom",'lbwhere'=>"",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
#	sprintf("%03d", $cpt++).'/remarque_libre'=>{'hide_update'=>0,'default_value'=>'','title'=>"Remarque libre",'legend'=>'','translate'=>0,'fieldtype'=>'textarea','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},'tab'=>$tab,'lbtable'=>'handmade_certigreen_statuts_reglement','lbkey'=>'id','lbdisplay'=>"nom",'lbwhere'=>"",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/envoyee_a'=>{'list_edit'=>0,'multiple'=>1,'title'=>'Envoyée à','class'=>$line_class='line_facturation ','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'migcms_codes','lbkey'=>'id','lbdisplay'=>'v1','lbwhere'=>"id_code_type='3' and visible='y'",'lbordby'=>"v1",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/factures'=>{'title'=>'Facture annexe','translate'=>0,'fieldtype'=>'files_admin','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/alt_facture_url'=>{'title'=>'Ancienne facture','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},

	sprintf("%05d", $cpt++).'/infos_nc'=>{'title'=>'Informations FA','func'=>'def_handmade::nc_infos_fa','translate'=>0,'fieldtype'=>'func',default_value => '',legend => '','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab='nc','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/numero_nc'=>{'title'=>'N° NC','translate'=>0,'fieldtype'=>'text',default_value => '',legend => 'Le numéro de NC sera calculé si vous confirmez celle-ci','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab='nc','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},


	sprintf("%05d", $cpt++).'/deverrouiller_documents'=>{'title'=>'Docs?','legend'=>'Cocher pour déverrouiller le téléchargement des documents','translate'=>0,'fieldtype'=>'checkbox',default_value => '','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab='Documents','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},

	sprintf("%05d", $cpt++).'/func'=>{'title'=>'func','func'=>'def_handmade::commandes_documents','translate'=>0,'fieldtype'=>'func',default_value => '','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab='Documents','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/migcms_deleted'=>{'title'=>'Archivé','fieldtype'=>'display',default_value => '','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab='Documents','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},



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
    
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}

sub denom_from_commandes
{
	my $dbh = $_[0];
	my $id = $_[1];
	my $type = $_[2] || 'long';
	
	my %rec = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
	return denom($dbh,$rec{id_member});
}

sub denom_client_agence
{
	my $dbh = $_[0];
	my $id = $_[1];
	my $type = $_[2] || 'long';
	my %rec = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});

	my $client = def_handmade::denom($dbh,$rec{id_member},'','intranet_factures');
	my $agence = def_handmade::denom($dbh,$rec{id_member_agence},'','intranet_factures');
	my $facture = def_handmade::denom($dbh,$rec{facture_id_member},'','intranet_factures');
	
	my $client_agence = $client;
	if($client_agence ne '' && $facture ne '')
	{
		$client_agence .= '<br /><u>Facturation: </u><br />'.$facture;
	}
	if($client_agence ne '' && $agence ne '')
	{
		$client_agence .= '<br /><u>Agence: </u><br />'.$agence;
	}
	
	return $client_agence
}

sub denom_agence
{
	my $dbh = $_[0];
	my $id = $_[1];
	my $type = $_[2] || 'long';
	
	my %rec = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
	return def_handmade::denom($dbh,$rec{id_member_agence},'','intranet_factures');
}

sub breadcrumb_func
{
    my $dbh=$_[0];
    my $id=$_[1];
	
	
	
	my $breadcrumb = <<"EOH";
	<ol class="breadcrumb">
			<li><a href="#">intranet_factures</a></li>
			<li>Liste des intranet_factures</li>
	</ol>
EOH
	
	return $breadcrumb;
	
}

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

#sub after_save_add
#{
##	my $dbh_rec = $_[0];
#	my $id = $_[1];
#
#	#complete tokens si necessaire
#	generer_tokens_for_all();
#	compute_date_mission($id);
#	valide_commande($id);
#	update_fusion_facture($id);
#	update_fusion_members($id);
#	generer_password_for_all();
#	save_documents($id);
#
#	uppercase_lastnames($id);
#
#
#
#}

sub after_save
{
#    my $dbh=$_[0];
    my $id=$_[1];

	log_debug("",'vide','after_save_commande');
	generer_tokens_for_all();

	update_fusion($id);

	valide_commande($id);
	compute_date_mission($id);
	compute_tel($id);

	#calcule date échéance
	my %facture = read_table($dbh,'intranet_factures',$id);
	def_handmade::save_doc_facture_calcule_echeance(\%facture);
	def_handmade::set_statut_facture_from_reglements($id);


	reporte_alt_facture_url($id);
	reporte_infos_sur_client($id);
	reporte_infos_facture_sur_client($id);

	#maj fusion membres
	update_fusion_facture($id);
	update_fusion_members($id);

	save_documents($id);


	generer_password_for_all();

	uppercase_lastnames($id);

	#genere pdf
	%facture = read_table($dbh,'intranet_factures',$id);
	def_handmade::save_doc_facture_cree_pdf(\%facture);

	#def_handmade::save_doc_facture_commission(\%facture);


	if($facture{montant_a_payer_tvac} > 0) {
		def_handmade::save_doc_facture_rappel_cree_pdf(\%facture, 1);
		def_handmade::save_doc_facture_rappel_cree_pdf(\%facture, 2);
		def_handmade::save_doc_facture_rappel_cree_pdf(\%facture, 3);
	}

}

sub liste_montants {

	my $dbh = $_[0];
	my $id = $_[1];

	my $type = $_[2] || 'long';
	my %commande = sql_line({table=>'intranet_factures',where=>"id='$id'"});
	$commande{montant_a_payer_tvac} = sprintf("%.2f", $commande{montant_a_payer_tvac});

	my $numero = def_handmade::numero_fac('',$id);

	my $rapport = <<"EOH";

	$numero

	<table class="table" style="width:165px">
			<tr><td>Montant facturé</td><td><span style="color:#46b8da">$commande{montant_a_payer_tvac} €</span></td></tr>

EOH


	if ($commande{type_facture} eq "nc") {

		$rapport = <<"EOH";

		$numero

	<table class="table" style="width:165px">
			<tr><td>Montant crédité</td><td><span style="color:#46b8da">$commande{montant_a_payer_tvac} €</span></td></tr>

		</table>
EOH
		return $rapport;

	}
	my $statut = "Att. paiement";
	my $class = "danger";

	if(!($commande{montant_a_payer_tvac} > 0))
	{
		if ($commande{type_facture} ne "nc") {
			if($commande{forcer_paye} eq 'y')
			{
				$class="success";
				$statut = "Payée";
			}
			elsif ($commande{statut} == 3) {
				$class="warning";
				$statut = "Part. payée";
			}
			elsif ($commande{statut} == 4 ) {
				$class="success";
				$statut = "Payée";
			}
			elsif ($commande{statut} == 7 ) {
				$class="danger";
				$statut = "Paiement acte";
			}
		}

		return <<"EOH";

		<div class="alert alert-$class">
 Sans montant encodé ($statut)
</div>
EOH
	}



	my $reste = $commande{montant_a_payer_tvac};

	if($commande{statut} != 5 && $commande{statut} != 6) {

		my @reglements = sql_lines({ table                                                     =>
			'handmade_certigreen_reglements r, handmade_certigreen_statuts_reglement t', where =>
			"r.id_type_reglement = t.id AND r.id_facture='$id'", 'ordby'                       =>
			"date_reglement desc" });
		foreach $reglement(@reglements) {
			my %reglement = %{$reglement};

			$reglement{montant} = sprintf("%.2f", $reglement{montant});
			$reglement{date_reglement} = to_ddmmyyyy($reglement{date_reglement});
			$reste -= $reglement{montant};
			$rapport .= <<"EOH";
		<tr><td><a href="../cgi-bin/adm_handmade_certigreen_reglements.pl?&sel=1000279&id_facture=$commande{id}" data-placement="bottom" data-original-title="Encodé le $reglement{date_reglement}">- $reglement{nom}</a></td><td><span style="color:green">- $reglement{montant} €</span></td></tr>
EOH
		}
	}

	$reste = sprintf("%.2f", $reste);


#	<a href="#" data-placement="bottom"
#    data-original-title="Créez d'abord une facture pour pouvoir ajouter un reglement"
#    id="$id" role="button" class="btn-link  btn btn-default show_only_after_document_ready">
#		<i class="fa fa-eur fa-fw"></i></a>
	my $acces = <<"EOH";
EOH

	if($acces_full && $commande{montant_a_payer_tvac} > 0 && ($commande{statut} != 5 && $commande{statut} != 6))
	{
		$acces = <<"EOH";

		<a target="_blank" href="../cgi-bin/adm_handmade_certigreen_reglements.pl?&sel=1000279&id_facture=$commande{id}&sw=add_form" data-placement="bottom" data-original-title="Ajoutez un règlement à la facture"
		id="$id" role="button" class="">
		<i class="fa fa-plus"></i>&nbsp;Ajouter un reglement&nbsp;...</a>
EOH
	}

	$rapport .=<<"EOH";


EOH
		if($reste > 0 && ($commande{statut} != 5 && $commande{statut} != 6))
		{
			$rapport .=<<"EOH";
			<tr><td>= Reste à payer</td><td><span style="color:red">$reste&nbsp;€</span></td></tr>
			<tr><td colspan="2">$acces</td></tr>
EOH
		}
	else
		{
#			$rapport .=<<"EOH";
#			<tr><td> Reste à payer</td><td><span style="color:green">$reste €</span></td></tr>
#EOH
		}

	$rapport .=<<"EOH";
	</table>


EOH

	return $rapport;

}

sub liste_documents
{
	my $dbh = $_[0];
	my $id = $_[1];
	my $type = $_[2] || 'long';
	my $size = "width:125px;";
	my $hide_class = 'hide';
	my $fa_class = 'fa-plus-square-o';
	if(trim(get_quoted('list_keyword')) ne '' )
	{
		$hide_class = '';
		$fa_class = 'fa-minus-square-o';
	}

	if($id > 0)
	{
		my %commande = sql_line({table=>'intranet_factures',where=>"id='$id'"});
		my %corr = 
		(
			1 => 'Certificat PEB',
			2 => 'Electricité',
			3 => 'Citerne',
			4 => 'Amiante',
			5 => 'Pollution des sols',
			7 => 'Offre',
		);

		my %corrDays =
		(
			'monday' => 'Lundi',
			'tuesday' => 'Mardi',
			'wednesday' => 'Mercredi',
			'thursday' => 'Jeudi',
			'friday' => 'Vendredi',
			'saturday' => 'Samedi',
			'sunday' => 'Dimanche',
		);
		
		my %corr_img = 
		(
			1 => 'peb.png',
			2 => 'elec.png',
			3 => 'citerne.png',
			4 => 'amiante.png',
			5 => 'symbole_pollution.png',
			7 => 'symbole_offre.png',
		);
		
		my $fusion = '';
		my $list_doc_img = '';
		my $list_warn = '';
		
		my @commande_documents = sql_lines({table=>'commande_documents',where=>"commande_id='$id' AND migcms_deleted != 'y' AND type_document_id > 0",ordby=>"type_document_id"});
		
		$fusion .= <<"EOH";
		<table class="table">
		<tr>
		<td style="width:50%">
		<a  style="$size" class="btn btn-primary" href='../cgi-bin/adm_handmade_certigreen_commande_documents.pl?sel=1000289&sw=add_form&commande_id=$id'
data-original-title='Ajouter' data-placement = 'bottom'>
<i class=\"fa fa-plus fa-fw\"></i> Ajouter </a>

		</td>
		<td style="width:50%">
			<a  style="$size" class="btn btn-primary" href='../cgi-bin/adm_handmade_certigreen_commande_documents.pl?sel=1000289&sw=&commande_id=$id'
data-original-title='Liste des documents' data-placement = 'bottom'>
<i class=\"fa fa-list fa-fw\"></i>  Liste </a>
		</td>
		</tr>
EOH


		foreach $commande_document (@commande_documents)
		{
			my %commande_document = %{$commande_document};

			my $document = $corr{$commande_document{type_document_id}};
			my $document_img = $corr_img{$commande_document{type_document_id}};
			$commande_document{date_prevue} = to_ddmmyyyy($commande_document{date_prevue});
			$commande_document{heure_prevue} = sql_to_human_time($commande_document{heure_prevue});
			if($commande_document{heure_prevue} eq '00h00')
			{
				$commande_document{heure_prevue} = '';
			}
			my $date_prevue = trim($commande_document{date_prevue}.' '.$commande_document{heure_prevue});
			if($date_prevue eq '-- 00:00:00' || $date_prevue eq '// h' || $date_prevue =~ /\/\//)
			{
				$date_prevue = '';
			}

			my $url = "../cgi-bin/adm_handmade_certigreen_commande_documents.pl?sel=1000289&commande_id=$id&sw=add_form&id=$commande_document{id}";

			my $info_date = $document.' (Pas encore de date)';
			my $icon_date = '<span style="color:red"><i class="fa fa-calendar fa-fw" aria-hidden="true"></i></span>';
			if($commande_document{date_prevue} eq '' || $date_prevue eq '' || $date_prevue eq '00/00/0000')
			{
			}
			else
			{
				my @dthInfos = split(/ /,$date_prevue);
				my @dtInfos = split(/\//,$dthInfos[0]);
				if($dtInfos[0] > 0 && $dtInfos[1] > 0 && $dtInfos[2]>0) {
					my $dt = DateTime->new(year => $dtInfos[2], month => $dtInfos[1], day => $dtInfos[0]);

					my $jour = $dt->day_name;
					if($corrDays{lc($dt->day_name)} ne '') {
						$jour = $corrDays{lc($dt->day_name)};
					}
					$date_prevue = $jour.' '.$date_prevue;
				}

				$info_date = $document.' ('.$date_prevue.')';
				$icon_date = '<span style="color:green"><i class="fa fa-calendar fa-fw" aria-hidden="true"></i></span>';
			}

			my $dl_icon = "";
			my %doc_lf = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='commande_documents' and table_field='pj' and token='$commande_document{id}'",limit=>'',ordby=>'id'});
			my $file = $doc_lf{file_dir}.'/'.$doc_lf{full}.$doc_lf{ext};
			if(-e $file && $doc_lf{full} ne '')
			{
				$dl_icon = '<a href="'.$file.'"  target="_blank"   data-placement="bottom" data-original-title="Fichier disponible"><i class="fa fa-eye fa-fw" aria-hidden="true"></i></span></a>';
			}
			else
			{
				$dl_icon = '<a  target="_blank"  href="'.$url.'" data-placement="bottom" data-original-title="Fichier non disponible"><span style="color:red"><i class="fa fa-eye fa-fw" aria-hidden="true"></i></span></a>';
			}


			$fusion .= <<"EOH";
			<tr>
			<td style="width:50%">

<a  href='$url'  target="_blank"
 	data-original-title='$info_date'
 	data-placement = 'bottom'>

 	<img src='../skin/img/$document_img' alt='$document' />

$icon_date
 </a>



 </td>
 <td style="width:50%">

 $dl_icon
 </td>
 </tr>

EOH



		}


		$fusion .= <<"EOH";
		</table>
EOH

		#
#		if($type ne 'short')
#		{
#			$fusion .= '<a href=""   data-placement="bottom" data_original-title="Modifier la commande" id="'.$commande{id}.'" class="migedit_'.$commande{id}.' migedit">';
#		}

#		$fusion =~s/\<br \/\>$//g;
#		if($type ne 'short')
#		{
#			$fusion .= '</a>';
#		}
		return $fusion;
	}
	else
	{
		return '';
	}
}

sub validation_func
{
	my $dbh=$_[0];
    my %item = %{$_[1]};
	my $id = $_[2];
	
#	if($id > 0)
#	{
		my $rapport = '';
		my $valide = 1;

		my @oblig = (
			'lastname-Nom du propriétaire',
			'facture_nom-Nom de facturation',
			);

#	'type_bien_id-Type de bien',
#		'id_employe-Employé',

#	use Data::Dumper;

		foreach my $ob (@oblig)
		{
			my @ob_infos = split(/\-/,$ob);

			my $fieldName = $ob_infos[0];
			my $fieldMsg = $ob_infos[1];
			my $fieldValue = $item{$fieldName};

			if($fieldName ne '' && $fieldMsg ne '' && ( $fieldValue eq '' || $fieldValue eq '0'))
			{
				$valide = 0;
				$rapport .=<<"EOH";
				<tr><td><i class="fa fa-times"></i> $fieldMsg</td><td>Ce champs est obligatoire.</td></tr>
EOH
			}
		}

		#si compte client lié et email appartient à un autre client
		if($item{id_member} > 0 && $item{email} ne '')
		{
			my %check_email = sql_line({select=>"id",table=>"members",where=>"email='$item{email}' AND id != '$item{id_member}'"});
			if($check_email{id} > 0)
			{
				$valide = 0;
				$rapport .=<<"EOH";
				<tr><td><i class="fa fa-times"></i>Bien > Propriétaire > Email</td><td>L'email renseigné ($item{email}) est déjà utilisé pour membre N°$check_email{id}. Vous avez choisi le propriétaire N°$item{id_member} pour ses coordonnées. L'email servant d'identifiant de connexion, celui-ci doit être unique.</td></tr>
EOH
			}	
		}
		
		#si compte client facture lié et email appartient à un autre client
		if($item{facture_id_member} > 0 && $item{facture_email} ne '')
		{
			my %check_email = sql_line({select=>"id",table=>"members",where=>"email='$item{facture_email}' AND id != '$item{facture_id_member}'"});
			if($check_email{id} > 0)
			{
				$valide = 0;
				$rapport .=<<"EOH";
				<tr><td><i class="fa fa-times"></i>Bien > Facturation > Email</td><td>L'email renseigné ($item{facture_email}) est déjà utilisé pour membre N°$check_email{id}. Vous avez choisir le propriétaire N°$item{facture_id_member} pour la facturation. L'email servant d'identifiant de connexion, celui-ci doit être unique.</td></tr>
EOH
			}	
		}

		#si type_facure = facture et pas de n° facture
		if($item{type_facture} eq 'facture' && !($item{numero_facture} >0))
		{
			$valide = 0;
			$rapport .=<<"EOH";
				<tr><td><i class="fa fa-times"></i>Facture/NC > N° Facture</td><td>Une facture doit avoir un numéro de facture.</td></tr>
EOH

		}
		#si type_facure = nc et pas de n° nc
		if($item{type_facture} eq 'nc' && !($item{numero_nc} >0))
		{
			$valide = 0;
			$rapport .=<<"EOH";
				<tr><td><i class="fa fa-times"></i>Facture/NC > N° NC</td><td>Une note de crédit doit avoir un numéro de NC.</td></tr>
EOH

		}
		#si type_facure = facture et n° nc
		if($item{type_facture} eq 'facture' && $item{numero_nc} >0)
		{
			$valide = 0;
			$rapport .=<<"EOH";
				<tr><td><i class="fa fa-times"></i>Facture/NC > N° Facture</td><td>Une facture ne doit pas avoir un numéro de NC.</td></tr>
EOH

		}
		#si type_facure = nc et n° facture
		if($item{type_facture} eq 'nc' && $item{numero_facture} >0)
		{
			$valide = 0;
			$rapport .=<<"EOH";
				<tr><td><i class="fa fa-times"></i>Facture/NC > N° NC</td><td>Une note de crédit doit avoir un numéro de facture.</td></tr>
EOH

		}

		if($rapport ne '')
		{
			log_debug('rapport:'.$rapport,'','validation');
			
			$rapport =<<"EOH";
			<h5><i class="fa fa-info"></i> Avant de sauvegarder,vous devez compléter certaines informations obligatoires pour les contacts d'<u>Alias Consult</u>:</h5>
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
			
#			return 'validation_error___'.$rapport.Dumper(\%item);
			return 'validation_error___'.$rapport;
		}
		else
		{
			return '';
		}
#	}
#	else
#	{
#		return '';
#	}
}

sub commande_get_member_info
{
	my $new_id_member = get_quoted('new_id_member');
	my %member = sql_line({table=>'members',where=>"id='$new_id_member'"});
	my $civilite = '';

	if($member{civilite_id} > 0)
	{
		my %migcms_code = sql_line({table=>'migcms_codes',where=>"id='$member{civilite_id}'"});
		$civilite = $migcms_code{code};
	}

	my $retour = '';
	
	$retour .= $member{lastname}.'___';
	$retour .= $member{firstname}.'___';
	$retour .= $member{vat}.'___';
	$retour .= $member{type_member}.'___';
	$retour .= $member{street}.'___';
	$retour .= $member{number}.'___';
	$retour .= $member{zip}.'___';
	$retour .= $member{city}.'___';
	$retour .= $member{tel}.'___';
	$retour .= $member{email}.'___';
	$retour .= $member{emailb}.'___';
	$retour .= $member{id_agence}.'___';
	$retour .= $member{id_agence2}.'___';
	$retour .= $member{civilite_id}.'___';
	$retour .= $civilite.'___';

	print $retour;

	exit;

}

sub generer_tokens_for_all
{
	my @commandes_sans_tokens = sql_lines({select=>"id",dbh=>$dbh, table=>"intranet_factures", where=>"token = ''"});
	foreach $commandes_sans_token (@commandes_sans_tokens)
	{
		my %commandes_sans_token=%{$commandes_sans_token};
		my $new_token = create_token(20);

		my $stmt = <<"SQL";
			UPDATE intranet_factures
				SET token = '$new_token'
				WHERE id = '$commandes_sans_token{id}'
SQL
		execstmt($dbh, $stmt);


	}

	my $stmt = <<"SQL";
			UPDATE intranet_factures
				SET id_facture_liaison = id
				WHERE id_facture_liaison = 0 or id_facture_liaison is NULL
SQL
	execstmt($dbh, $stmt);

#	my $stmt = <<"SQL";
#			UPDATE `commande_documents` SET heure_prevue = '00:00' where DAY(heure_prevue) > 1
#SQL
#	execstmt($dbh, $stmt);
}




sub update_fusion
{
	my $id = $_[0];

	my $fusion = denom_commande($dbh,$id,'','commades');
	my $fusion_short = denom_commande($dbh,$id,'short','intranet_factures');


	my $stmt = <<"EOH";
		UPDATE $dm_cfg{table_name} f SET nom_agence = (select lastname from members where id = f.id_member_agence) WHERE id = '$id'
EOH
	log_debug($stmt,'','after_save_commande');
	execstmt($dbh,$stmt);




	$fusion =~ s/\'/\\\'/g;
	$fusion_short =~ s/\'/\\\'/g;

	my $stmt = <<"EOH";
		UPDATE $dm_cfg{table_name} SET fusion = '$fusion',fusion_short='$fusion_short' WHERE id = '$id'
EOH
	log_debug($stmt,'','after_save_commande');
	execstmt($dbh,$stmt);
}

sub valide_commande
{
	my $id = $_[0];
	my $stmt = <<"EOH";
		UPDATE $dm_cfg{table_name} SET validation = 1 WHERE id = '$id'
EOH

	execstmt($dbh,$stmt);
	log_debug($stmt,'','valide_commande');
}

sub compute_date_mission
{
	my $id = $_[0];

	#complete date si necessaire
	my $stmt = <<"EOH";
	UPDATE $dm_cfg{table_name} SET date_mission = NOW() WHERE (date_mission='0000-00-00' OR date_mission ='0000-00-00 00:00:00') AND id = '$id'
EOH
	execstmt($dbh,$stmt);

}



sub compute_all_tel
{

see();
	my @commandes = sql_lines({select=>'id',table=>$dm_cfg{table_name}});

	foreach $commande (@commandes)
	{
		my %commande = %{$commande};

		compute_tel($commande{id});
	}
	exit;
}

sub compute_tel
{
	my $id = $_[0];

	my %member = sql_line({select=>"tel",table=>$dm_cfg{table_name},where=>"id='$id'"});
	$member{tel} =~ s/[^0-9]//g;

	my $stmt = <<"EOH";
	UPDATE $dm_cfg{table_name} SET tel = '$member{tel}' WHERE id = '$id'
EOH

	execstmt($dbh,$stmt);

}


sub save_documents {

	log_debug('save_documents',"","save_documents");
	my $id = $_[0];
	log_debug($id,"","save_documents");

	my @commande_documents = sql_lines({ table => 'commande_documents', where =>
		"commande_id='$id' AND commande_id > 0" });

	#sauvegarde existants***********************************************************************************************
	foreach $commande_document (@commande_documents) {
		my %commande_document = %{$commande_document};
		log_debug($commande_document{id},"","save_documents");
		if( get_quoted('type_document_id_'.$commande_document{id}) > 0) {
			my %update_document = (
				type_document_id => get_quoted('type_document_id_' . $commande_document{id}),
				date_prevue      => compute_sql_date(get_quoted('date_prevue_' . $commande_document{id})),
				heure_prevue     => get_quoted('heure_prevue_' . $commande_document{id}),
				id_employe       => get_quoted('id_employe_' . $commande_document{id}),
			);
			log_debug($update_document{type_document_id}, "", "save_documents");

			updateh_db($dbh, 'commande_documents', \%update_document, 'id', $commande_document{id});
		}
	}


	#sauvegarde nouveaux************************************************************************************************
	foreach my $new_doc_num (1 .. 10) {
		my %commande_document = %{$commande_document};
		log_debug($commande_document{id},"","save_documents");

		if( get_quoted('new_type_document_id_'.$new_doc_num) > 0)
		{
			my %new_document =(
				commande_id => $id,
				type_document_id => get_quoted('new_type_document_id_'.$new_doc_num),
				date_prevue => compute_sql_date(get_quoted('new_date_prevue_'.$new_doc_num)),
				heure_prevue => get_quoted('new_heure_prevue_'.$new_doc_num),
				id_employe => get_quoted('new_id_employe_'.$new_doc_num),
			);
			inserth_db($dbh,'commande_documents',\%new_document);
		}
	}
	log_debug('save_documents ok',"","save_documents");

}

sub reporte_alt_facture_url
{
	my $id = $_[0];

	my %record = read_table($dbh,$dm_cfg{table_name},$id);
	my %migcms_linked_file = sql_line({table=>'migcms_linked_files',where=>"table_name='intranet_factures' and table_field='factures' and token='$id'"});
	if($migcms_linked_file{id} > 0 && $migcms_linked_file{full} ne '')
	{
		my $alt_facture_url = 'files/com/factures/'.$id.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};

		my $stmt = <<"EOH";
			UPDATE intranet_factures SET alt_facture_url = '$alt_facture_url' WHERE id = '$id'
EOH
		execstmt($dbh,$stmt);
	}
}

sub reporte_infos_sur_client
{
	my $id = $_[0];

	my %record = read_table($dbh,$dm_cfg{table_name},$id);
	my %update_record = ();

	my @fields = ('lastname','firstname','tel','street','number','zip','city','email','emailb','id_agence','id_agence2');

	if($record{id_member} > 0)
	{
		#si client lié, écraser ses données
		my %update_member = ();
		my $if = 0;
		foreach my $f (@fields)
		{
			my $value = get_quoted($f);
			$update_member{$fields[$if]} = trim($value);
			$if++;
		}
		my $new_id_member = sql_set_data({debug=>1,dbh=>$dbh,table=>'members',data=>\%update_member,where=>"id='$record{id_member}'"});
	}
	else
	{
		#si pas de client lié et email pas encore utilisé: créer un compte, lier le compte
		my %test_email = sql_line({debug=>1,debug_results=>1,table=>'members',where=>"email = '$record{email}' and id != $record{id_member}"});
		if(!($test_email{id} > 0) && $record{email} ne '')
		{
			my %insert_member = ();
			my $if = 0;
			foreach my $f (@fields)
			{
				my $value = get_quoted($f);
				$insert_member{$fields[$if]} = trim($value);
				$if++;
			}
			$insert_member{token} = create_token(100);
			my $new_id_member = sql_set_data({debug=>1,dbh=>$dbh,table=>'members',data=>\%insert_member,where=>""});

			$update_record{id_member} = $new_id_member;
		}
	}

	%update_record = %{quoteh(\%update_record)};
	updateh_db($dbh,$dm_cfg{table_name},\%update_record,'id',$record{id});


}

sub reporte_infos_facture_sur_client
{
	my $id = $_[0];
	my %record = read_table($dbh,$dm_cfg{table_name},$id);
	my %update_record = ();

	my @fields = ('lastname','firstname','tel','street','number','zip','city','email','vat');
	my @fields_commande_facture = ('facture_nom','facture_prenom','facture_tel','facture_street','facture_number','facture_zip','facture_city','facture_email','facture_societe_tva');

	if($record{facture_id_member} > 0)
	{
		#si facture_id_member lié, écraser ses données
		my %update_member = ();
		my $if = 0;
		foreach my $f (@fields)
		{
			my $value = get_quoted($fields_commande_facture[$if]);
			$update_member{$fields[$if]} = trim($value);
			$if++;
		}
		my $new_id_member = sql_set_data({debug=>1,dbh=>$dbh,table=>'members',data=>\%update_member,where=>"id='$record{facture_id_member}'"});
	}
	else
	{
		#si pas de client lié et email pas encore utilisé: créer un compte, lier le compte
		if($record{facture_email} ne '')
		{
			my %test_email = sql_line({debug=>1,debug_results=>1,table=>'members',where=>"email = '$record{facture_email}' and id != $record{facture_id_member}"});
			if(!($test_email{id} > 0))
			{
				my %insert_member = ();
				my $if = 0;
				foreach my $f (@fields)
				{
					my $value = get_quoted($fields_commande_facture[$if]);
					$insert_member{$fields[$if]} = trim($value);
					$if++;
				}
				$insert_member{token} = create_token(100);
				my $new_id_member = sql_set_data({debug=>0,dbh=>$dbh,table=>'members',data=>\%insert_member,where=>""});
				$update_record{facture_id_member} = $new_id_member;
			}
		}
	}

	%update_record = %{quoteh(\%update_record)};
	updateh_db($dbh,$dm_cfg{table_name},\%update_record,'id',$record{id});

}

sub update_fusion_members
{
	my $id = $_[0];
	my %record = read_table($dbh,$dm_cfg{table_name},$id);

	if($record{id_member} > 0)
	{
		my $fusion = denom($dbh,$record{id_member});
		my $fusion_short = denom($dbh,$record{id_member},'short');
		$fusion =~ s/\'/\\\'/g;
		$fusion_short =~ s/\'/\\\'/g;
		my $stmt = <<"EOH";
			UPDATE members SET fusion = '$fusion',fusion_short='$fusion_short' WHERE id = '$record{id_member}'
EOH
		execstmt($dbh,$stmt);
	}
	if($record{facture_id_member} > 0)
	{
		my $fusion = denom($dbh,$record{facture_id_member});
		my $fusion_short = denom($dbh,$record{facture_id_member},'short');
		$fusion =~ s/\'/\\\'/g;
		$fusion_short =~ s/\'/\\\'/g;
		my $stmt = <<"EOH";
			UPDATE members SET fusion = '$fusion',fusion_short='$fusion_short' WHERE id = '$record{facture_id_member}'
EOH
		execstmt($dbh,$stmt);
	}
}


sub uppercase_lastnames
{
	my $id = $_[0];
	my $stmt = <<"EOH";
			UPDATE intranet_factures SET fusion = '$fusion',fusion_short='$fusion_short' WHERE id = '$record{id_member}'
EOH
	execstmt($dbh,$stmt);
}

sub generer_password_for_all
{
	my $stmt = <<"EOH";
		UPDATE members SET password = 'd3b05f624a2ab2323882a053662a2729aa990ec7' WHERE password = ''
EOH
	log_debug($stmt,'','after_save');

	execstmt($dbh,$stmt);
}


sub get_nb_commandes
{
	my %nb = sql_line({table=>'intranet_factures',select=>"count(*) as nb",where=>" validation ='1'"});
	print <<"EOH";
	<div class="text-center">
	<h1>$nb{nb}</h1> commandes
	</div>
EOH
	exit;
}

sub get_nb_doc
{
	my %nb = sql_line({table=>'intranet_factures f,commande_documents d',select=>"count(*) as nb",where=>" validation ='1' AND f.id=d.commande_id"});
	print <<"EOH";
	<div class="text-center">
	<h1>$nb{nb}</h1> documents
	</div>
EOH
	exit;
}

sub sendmail
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};
	my $self = "$config{baseurl}/cgi-bin/adm_migcms_codes.pl?sel=".get_quoted('sel').'&id_code_type='.$id;


	my $acces = <<"EOH";

		<a href="#" data-placement="bottom" data-original-title="Créez d'abord une facture pour pouvoir l'envoyer par mail"
		id="$id" role="button" class="btn btn-link show_only_after_document_ready">
		<i class="fa fa-paper-plane-o  fa-fw" data-original-title="" title=""></i></a>
EOH

#	if($record{migcms_last_published_file} ne '' && $record{montant_a_payer_tvac} > 0)
	if($record{migcms_last_published_file} ne '' && $record{montant_a_payer_tvac} > 0)
	{
		$acces = <<"EOH";

		<a href="#" data-placement="bottom" data-original-title="Envoyer par email"
		id="$id" role="button" class="btn btn-default show_only_after_document_ready send_by_email">
		<i class="fa fa-paper-plane-o  fa-fw" data-original-title="" title=""></i></a>
EOH
	}

	#icone vert FA envoyé le xxxxx
	if($record{numero_facture} > 0) {
		my %historique_facture = sql_line({ table => 'migcms_mail_history', where =>
			"email_object LIKE 'Facture%' AND email_object LIKE '%FA$record{numero_facture}%'" });
		if ($historique_facture{id} > 0) {
			if($historique_facture{id_member}>0) {
				my %user_send = read_table($dbh, 'users', $historique_facture{id_member});

				my $legend = 'Envoyé par mail le '.tools::to_ddmmyyyy($historique_facture{moment},'withtimeandbr');
				$legend .= ' par '.$user{firstname}.' '.$user{lastname};

				$acces = <<"EOH";

		<a href="#" data-placement="bottom" data-original-title="$legend"
		id="$id" role="button" class="btn btn-success show_only_after_document_ready send_by_email">
		<i class="fa fa-paper-plane-o  fa-fw" data-original-title="" title=""></i></a>
EOH
			}
		}
	}

	#icone vert NC envoyé le xxxxx
	if($record{numero_nc} > 0) {
		my %historique_facture = sql_line({ table => 'migcms_mail_history', where =>
			"email_object LIKE 'Note de cr%' AND email_object LIKE '%NC$record{numero_nc}%'" });
		if ($historique_facture{id} > 0) {
			if($historique_facture{id_member}>0) {
				my %user_send = read_table($dbh, 'users', $historique_facture{id_member});

				my $legend = 'Envoyé par mail le '.tools::to_ddmmyyyy($historique_facture{moment},'withtimeandbr');
				$legend .= ' par '.$user{firstname}.' '.$user{lastname};

				$acces = <<"EOH";

		<a href="#" data-placement="bottom" data-original-title="$legend"
		id="$id" role="button" class="btn btn-success show_only_after_document_ready send_by_email">
		<i class="fa fa-paper-plane-o  fa-fw" data-original-title="" title=""></i></a>
EOH
			}
		}
	}




	return $acces;
}

sub rappel1
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};
	my $acces = <<"EOH";
		<br style="clear:both" /><a href="#" data-placement="bottom" data-original-title="Envoyer le rappel 1"
		id="$id" role="button" class="btn btn-info show_only_after_document_ready send_by_email_rappel1">
		<i class="fa fa-envelope-o  fa-fw" data-original-title="" title=""></i></a>
EOH
	return $acces;
}
sub rappel2
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};
	my $acces = <<"EOH";
		<a href="#" data-placement="bottom" data-original-title="Envoyer le rappel 2"
		id="$id" role="button" class="btn btn-warning show_only_after_document_ready send_by_email_rappel2">
		<i class="fa fa-envelope-o  fa-fw" data-original-title="" title=""></i></a>
EOH
	return $acces;
}
sub rappel3
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};
	my $acces = <<"EOH";
		<a href="#" data-placement="bottom" data-original-title="Envoyer le rappel 3"
		id="$id" role="button" class="btn btn-danger show_only_after_document_ready send_by_email_rappel3">
		<i class="fa fa-envelope-o  fa-fw" data-original-title="" title=""></i></a>
EOH
	return $acces;
}


sub download_rappel
{
	my $num = get_quoted('num');
	my $id = get_quoted('id');
	my %intranet_facture = read_table($dbh,'intranet_factures',$id);
#	see(\%intranet_facture);

	my $content = def_handmade::get_body_rappel_num($id,1);


	tools::add_historique_envoi_email({
		email_from      =>'Certigreen',
		email_to      => $intranet_facture{email},
		email_position     =>'To',
		email_object     =>'Envoi postal du rappel '.$num,
		email_body     =>$content,
	});
	my $urlRedirect = '../usr/documents/'.$intranet_facture{'r'.$num.'pdf'};
	print $urlRedirect;
	http_redirect($urlRedirect);
	exit;

}

sub rappel1pdf
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};

	my $acces = <<"EOH";
		<br style="clear:both" /><a href="#"  data-placement="bottom" data-original-title="Sauvegardez la commande pour générer ce rappel"
		id="$id" role="button" class="  btn btn-link show_only_after_document_ready ">
		<i class="fa fa-download  fa-fw" data-original-title="" title=""></i></a>
EOH

	if($record{r1pdf} ne '') {

		$acces = <<"EOH";
		<br style="clear:both" /><a target="_blank"  href="../cgi-bin/adm_handmade_certigreen_commandes.pl?sw=download_rappel&num=1&id=$id" data-placement="bottom" data-original-title="Télécharger le rappel 1"
		id="$id" role="button" class="btn btn-info show_only_after_document_ready ">
		<i class="fa fa-download  fa-fw" data-original-title="" title=""></i></a>
EOH
	}
	return $acces;
}


sub rappel2pdf
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};
	my $acces = <<"EOH";
	<a href="#"  data-placement="bottom" data-original-title="Sauvegardez la commande pour générer ce rappel"
		id="$id" role="button" class="  btn btn-link show_only_after_document_ready ">
		<i class="fa fa-download  fa-fw" data-original-title="" title=""></i></a>
EOH

	if($record{r2pdf} ne '') {

		$acces = <<"EOH";
		<a target="_blank" href="../cgi-bin/adm_handmade_certigreen_commandes.pl?sw=download_rappel&num=2&id=$id" data-placement="bottom" data-original-title="Télécharger le rappel 1"
		id="$id" role="button" class="btn btn-warning show_only_after_document_ready ">
		<i class="fa fa-download  fa-fw" data-original-title="" title=""></i></a>
EOH
	}
	return $acces;
}


sub rappel3pdf
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};
	my $acces = <<"EOH";
		<a  target="_blank" href="#"  data-placement="bottom" data-original-title="Sauvegardez la commande pour générer ce rappel"
		id="$id" role="button" class="  btn btn-link show_only_after_document_ready ">
		<i class="fa fa-download  fa-fw" data-original-title="" title=""></i></a>
EOH

	if($record{r3pdf} ne '') {

		$acces = <<"EOH";
		<a href="../cgi-bin/adm_handmade_certigreen_commandes.pl?sw=download_rappel&num=3&id=$id" data-placement="bottom" data-original-title="Télécharger le rappel 1"
		id="$id" role="button" class="btn btn-danger show_only_after_document_ready ">
		<i class="fa fa-download  fa-fw" data-original-title="" title=""></i></a>
EOH
	}
	return $acces;
}

sub nc
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};
	my $self = "$config{baseurl}/cgi-bin/adm_migcms_codes.pl?sel=".get_quoted('sel').'&id_code_type='.$id;




	my $acces = <<"EOH";

		<a href="#" data-placement="bottom"
		data-original-title="Créez d'abord une facture pour pouvoir la créditer"
		id="$id" role="button" class="btn-link  btn btn-default show_only_after_document_ready">
		<i class="fa fa-times fa-fw"></i></a>
EOH

	if($record{type_facture} eq 'nc')
	{
		$acces = <<"EOH";

		<a href="#" data-placement="bottom"
		data-original-title="Vous ne pouvez pas créditer une NC"
		id="$id" role="button" class="btn-link  btn btn-default show_only_after_document_ready">
		<i class="fa fa-times fa-fw"></i></a>
EOH

	}

	if($record{montant_a_payer_tvac} > 0 && $record{type_facture} eq 'facture')
	{
		$acces = <<"EOH";

		<a href="$dm_cfg{self}&sw=copy_invoice_to_nc&id_invoice=$facture{id}&scolg=$colg&tdoc=$tdoc" data-placement="bottom" data-numerofac="$record{numero_facture}" data-original-title="Créditez la facture"
		id="$id" role="button" class="confirm_nc btn btn-default show_only_after_document_ready">
		<i class="fa fa-times fa-fw"></i></a>
EOH
	}

	return $acces;
}


sub reglement
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};
	my $self = "$config{baseurl}/cgi-bin/adm_migcms_codes.pl?sel=".get_quoted('sel').'&id_code_type='.$id;




	my $acces = <<"EOH";

		<a href="#" data-placement="bottom"
		data-original-title="Créez d'abord une facture pour pouvoir ajouter un reglement"
		id="$id" role="button" class="btn-link  btn btn-default show_only_after_document_ready">
		<i class="fa fa-eur fa-fw"></i></a>
EOH

	if($record{montant_a_payer_tvac} > 0)
	{
		$acces = <<"EOH";

		<a href="../cgi-bin/adm_handmade_certigreen_reglements.pl?&sel=1000279&id_facture=$record{id}&sw=add_form" data-placement="bottom" data-original-title="Ajoutez un règlement à la facture"
		id="$id" role="button" class=" btn btn-default show_only_after_document_ready">
		<i class="fa fa-eur fa-fw"></i></a>
EOH
	}

	return $acces;
}

sub download_fa
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = sql_line({table=>'intranet_factures',where=>"id='$id'"});
	my $self = "$config{baseurl}/cgi-bin/adm_migcms_codes.pl?sel=".get_quoted('sel').'&id_code_type='.$id;



	my $acces = <<"EOH";
<br style="clear:both" />
		<a href="#" data-funcpublish="" data-placement="bottom"
		 data-original-title="Créez d'abord une facture pour pouvoir la télécharger" role="button" class="btn btn-link show_only_after_document_ready viewpdf">
		 <i class="fa fa-eye  fa-fw" data-original-title="" title=""></i></a>
EOH

	if($record{migcms_last_published_file} ne '' && $record{montant_a_payer_tvac} > 0)
	{
#		.pdf
		$acces = <<"EOH";
<br style="clear:both" />
		<a href="../usr/documents/$record{migcms_last_published_file}" data-funcpublish="" data-placement="bottom" target="_blank"
		 data-original-title="Télécharger la facture N° FA$record{numero_facture}" role="button" class="btn btn-default show_only_after_document_ready viewpdf">
		 <i class="fa fa-eye  fa-fw" data-original-title="" title=""></i></a>
EOH
	}

	if($record{alt_facture_url} ne '')
	{
		$acces = <<"EOH";
<br style="clear:both" />
		<a href="../usr/$record{alt_facture_url}" data-funcpublish="" data-placement="bottom" target="_blank"
		 data-original-title="Télécharger l'ancienne facture" role="button" class="btn btn-default show_only_after_document_ready viewpdf">
		 <i class="fa fa-eye  fa-fw" data-original-title="" title=""></i></a>
EOH
	}

	return $acces;
}

sub send_by_email_rappel1 {
	print send_by_email_rappel_num(1,get_quoted('id'));
	exit;
}
sub send_by_email_rappel2 {
	print send_by_email_rappel_num(2,get_quoted('id'));
	exit;
}
sub send_by_email_rappel3 {
	print send_by_email_rappel_num(3,get_quoted('id'));
	exit;
}


	sub send_by_email_rappel_num
	{
	#	log_debug('send_by_email','vide','send_by_email');
	my $num = $_[0];
	my $id = $_[1];
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
	#$pdf_filename = &$func_publish($id,lc($dm_cfg{file_prefixe}),$dm_cfg{table_name},$dm_cfg{self});

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


	my %tpl_email_doc = ();
	if($dm_cfg{send_by_email_table_templates} ne '' && $dm_cfg{send_by_email_id_template} ne '')
	{
		%tpl_email_doc = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_templates},where=>"id='$dm_cfg{send_by_email_id_template}'"});
	}
	else
	{
		my %migcms_textes_email = sql_line({table=>'migcms_textes_emails',where=>"table_name='$dm_cfg{table_name}'"});
		$tpl_email_doc{html} = get_traduction({debug=>0,id=>$migcms_textes_email{id_textid_texte},id_language=>$config{current_language}});
	}

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


#	$message = map_license_fields($message,\%license);
#
#	$message = def_handmade::map_document($message,$dm_cfg{table_name},$id,$prefixe);

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



	$message = get_body_rappel_num($record{id},$num);
	$object = 'Rappel '.$num.' concernant votre '.$object;


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
		<!--
		<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_pj} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 mig_cms_value_col">
			$pieces_jointes

			</div>
		</div>
		-->
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

	return $screen;

}


sub send_by_email_db
{
	log_debug('send_by_email_db','vide','send_by_email_db');
	my $alt_de = get_quoted('de') || $_[3];
	my $to = get_quoted('to') || $_[0];
	my $object = get_quoted('object') || $_[1];
	my $cc = get_quoted('cc');
	my $cci = get_quoted('cci');

	my $id_doc = get_quoted('id_doc');
	my $prefixe_doc = get_quoted('prefixe_doc');
	my $company = get_quoted('company');
	my %record = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{table_name},where=>"id='$id_doc'"});




	my $send_mail_screen_message = get_quoted('send_mail_screen_message') || $_[2];
	use HTML::Entities;

	$config{fullurl} = "$config{rewrite_protocol}://$config{rewrite_subdns}$config{rewrite_dns}/";
	my $filename = '';
	if($record{migcms_last_published_file} eq '')
	{
		$record{migcms_last_published_file} = $record{pdf_filename};
	}

	$record{migcms_last_published_file} =~ s/\.pdf//g;

	my $url_fichier = $config{fullurl}.'usr/documents/'.$record{migcms_last_published_file};
	my $url_fichier_complet = $config{fullurl}.'usr/documents/'.$record{migcms_last_published_file}.'.pdf';
	my $url_fichier_pri = $config{fullurl}.'usr/documents/'.$record{migcms_last_published_file}.'_PRI.pdf';
	my $url_fichier_anx = $config{fullurl}.'usr/documents/'.$record{migcms_last_published_file}.'_ANX.pdf';
	# log_debug($config{fullurl},'','fullurl');
	# log_debug($url_fichier,'','fullurl');
	# log_debug($url_fichier_pri,'','fullurl');
	# log_debug($url_fichier_anx,'','fullurl');




	$send_mail_screen_message =~ s/{link1}/$url_fichier_pri/g;
	$send_mail_screen_message =~ s/{link2}/$url_fichier_anx/g;
	$send_mail_screen_message =~ s/{link3}/$url_fichier_complet/g;

	# log_debug($send_mail_screen_message,'','fullurl');


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
			%license = sql_line({debug=>1,debug_results=>1,table=>$dm_cfg{send_by_email_table_license},where=>"id='$record{$dm_cfg{send_by_email_id_license}}'"});
		}
		else
		{
			%license = sql_line({debug=>1,debug_results=>1,table=>$dm_cfg{send_by_email_table_license}});
		}
	}




	# my %license = ();
	# if($dm_cfg{send_by_email_table_license} ne '' )
	# {
	# %license = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_license}});
	# }

	if($dm_cfg{send_by_email_field2_license} eq '')
	{
		$dm_cfg{send_by_email_field2_license} = 'email';
	}
	if($license{$dm_cfg{send_by_email_field2_license}} eq '')
	{
		$license{$dm_cfg{send_by_email_field2_license}} = $alt_de;
	}

	my $de = "$license{$dm_cfg{send_by_email_field1_license}} <$license{$dm_cfg{send_by_email_field2_license}}>";


	my $filepath = $config{directory_path}.'/usr/documents/'.$record{migcms_last_published_file}.'.pdf';





	my @pjs = ();

	#document complet
	my $file_path = $config{directory_path}.'/usr/documents/'.$record{migcms_last_published_file}.'.pdf';
	# my $pj_name = getcode($dbh,$id_doc,$prefixe_doc);
	my $pj_name = $record{migcms_last_published_file};
	my %pj =
		(
			type=> "file/pdf",
			id=> $file_path,
			path=> $file_path,
			Filename => $pj_name.'.pdf'
		);
	if(-e $file_path)
	{
		if($dm_cfg{send_by_mail_less_pj} != 1)
		{
			push @pjs,\%pj;
		}
	}

	#conditions générales seulement



	#facture seulement
	my $file_path = $config{directory_path}.'/usr/documents/'.$record{migcms_last_published_file}.'_PRI.pdf';
	my %pj =
		(
			type=> "file/pdf",
			id=> $file_path,
			path=> $file_path,
			Filename => $pj_name.'_PRI.pdf'
		);
	if(-e $file_path)
	{
		push @pjs,\%pj;
	}

	my $file_path = $config{directory_path}.'/usr/documents/'.$record{migcms_last_published_file}.'_CGV.pdf';

	my %pj =
		(
			type=> "file/pdf",
			id=> $file_path,
			path=> $file_path,
			Filename => $pj_name.'_CGV.pdf'
		);
	if(-e $file_path)
	{
		push @pjs,\%pj;
	}

	#pjs seulement
	my $file_path = $config{directory_path}.'/usr/documents/'.$record{migcms_last_published_file}.'_ANX.pdf';
	my %pj =
		(
			type=> "file/pdf",
			id=> $file_path,
			path=> $file_path,
			Filename => $pj_name.'_ANX.pdf'
		);
	my $filesize = -s $file_path ;
	if(-e $file_path && $filesize > 1000)
	{
		if($dm_cfg{send_by_mail_less_pj} != 1)
		{
			push @pjs,\%pj;
		}
	}

	$send_mail_screen_message =~s/\\\'/\'/g;
	# $send_mail_screen_message = '<div style="font-family:arial;font-size:13px;">'.$send_mail_screen_message.'</div>';



	my %cci_data = ();
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
		%cci_data = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_license_cci}});
	}

	my $license_email =$license{email};
	if($license_email eq '')
	{
		$license_email =$cci_data{email};
	}



	# my $company = trim("$license{license_name} $license{license_type_company}");
	# if($company eq '')
	# {
	# $company = "$cci_data{license_name} $cci_data{license_type_company}";
	# }

	# my $company = trim("$license{license_name} $license{license_type_company}");
	# if($company eq '')
	# {
	# $company = "$cci_data{license_name} $cci_data{license_type_company}";
	# }



	# my %balises =
	# (
	# 'company' => "$license{license_name} $license{license_type_company}",
	# 'address' => "$license{street} $license{street2}$cci_data{street} $cci_data{street2}",
	# 'number' => "$license{number}$cci_data{number}",
	# 'zip' => "$license{zip}$cci_data{zip}",
	# 'city' => "$license{city}$cci_data{city}",
	# 'phone' => "$license{tel}$cci_data{tel}",
	# 'email_1' => "$license_email",
	# 'vat' => "$license{vat}$cci_data{vat}",
	# 'country' => "$license{country}$cci_data{country}",
	# 'siteweb' => "http://$license{domaine}$cci_data{domaine}",
	# 'iban' => "$license{iban}$cci_data{iban}",
	# 'bic' => "$license{bic}$cci_data{bic}",
	# 'rpm' => "$license{rpm}$cci_data{rpm}",
	# 'division' => "$license{division}$cci_data{division}",
	# 'tva' => "$license{vat}$cci_data{vat}",
	# );

	my %balises =
		(
			'company' => "$license{license_name} $license{license_type_company}",
			'address' => "$license{street} $license{street2}",
			'number' => "$license{number}",
			'zip' => "$license{zip}",
			'city' => "$license{city}",
			'phone' => "$license{tel}",
			'email_1' => "$license_email",
			'vat' => "$license{vat}",
			'country' => "$license{country}",
			'siteweb' => "http://$license{domaine}",
			'iban' => "$license{iban}",
			'bic' => "$license{bic}",
			'rpm' => "$license{rpm}",
			'division' => "$license{division}",
			'tva' => "$license{vat}",
		);

	# foreach my $cle_balise (keys %balises)
	# {
	# }

	$send_mail_screen_message = get_email_communication({body=>$send_mail_screen_message,balises=>\%balises});



	#destinataire


	log_debug('de:'.$de,'','send_by_email_db');
	log_debug('to:'.$to,'','send_by_email_db');
	log_debug('cc:'.$cc,'','send_by_email_db');
	log_debug('cci:'.$cci,'','send_by_email_db');
	log_debug('object:'.$object,'','send_by_email_db');
	log_debug('send_mail_screen_message:'.$send_mail_screen_message,'','send_by_email_db');


	send_mail_with_attachment($de,$to,$object,$send_mail_screen_message,\@pjs,"html",'',$cc,$cci);

	#alexis bugi
	$to = 'debug@bugiweb.com';
	send_mail_with_attachment($de,$to,'COPIE BUGIWEB: '.$object,$send_mail_screen_message,\@pjs,"html",'');

	$to =~s/\\\'/\'/g;
	add_history({action=>'send_mail',page=>$prefixe_doc,id=>$id_doc,details=>$to});
	exit;
}


