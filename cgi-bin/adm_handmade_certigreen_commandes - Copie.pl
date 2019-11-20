#!/usr/bin/perl -I../lib
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use dm_publish_pdf;
use def_handmade;

$dbh_data = $dbh2 = $dbh;

$stmt = "UPDATE commandes c SET id_member_agence = (SELECT id_agence FROM members WHERE id = c.id_member AND c.id_member > 0 AND id_agence > 0)";
execstmt($dbh,$stmt);
# see();

$stmt = <<"EOH";
UPDATE 
commandes c 
SET 
total_fc = 
(
	SELECT SUM(montant_a_payer_tvac) FROM intranet_factures f WHERE table_record='commandes' AND id_record=c.id
)
, 
total_nc = 
(
	SELECT SUM(montant_a_payer_tvac) FROM intranet_nc WHERE id_facture IN (select id from intranet_factures where table_record='commandes' AND id_record=c.id)
)
, total_reglements =  
(
	SELECT SUM(montant) FROM handmade_certigreen_reglements WHERE id_facture IN (select id from intranet_factures where table_record='commandes' AND id_record=c.id)
)
EOH

execstmt($dbh,$stmt);
$stmt = "UPDATE commandes c SET montant_restant = total_fc - total_nc - total_reglements";
execstmt($dbh,$stmt);

$stmt = "UPDATE commandes c SET date_mission = DATE(date_commande)";
execstmt($dbh,$stmt);

my $id = get_quoted('id');
my $mine = get_quoted('mine') || 'n';
my $commande_id = get_quoted("commande_id");
my $agence = get_quoted('agence');
my $client = get_quoted('client');
my $adresse = get_quoted('adresse');
$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{autocreation} = 1;
$dm_cfg{sort_opt} = 0;
$dm_cfg{file_prefixe} = 'cmd';

my $where_supp = '';




$dm_cfg{wherel} = "validation = 1";
if($mine eq 'y')
{
	$dm_cfg{wherel} = "id_employe='$user{id}' and validation = 1";
}

$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "commandes";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_handmade_certigreen_commandes.pl?agence=$agence&client=$client&adresse=$adresse";
$dm_cfg{show_id} = 0;
$dm_cfg{validation_func} = \&validation_func;

$dm_cfg{default_ordby}='id desc';

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save_add;


$dm_cfg{func_publish} = 'ajax_make_pdf_document';
$dm_cfg{send_by_email_table_license} = 'handmade_certigreen_licenses';
$dm_cfg{send_by_email_field1_license} = 'license_name';
$dm_cfg{send_by_email_field2_license} = 'email';
$dm_cfg{send_by_email_table_destinataire} = 'members';
$dm_cfg{send_by_email_col_destinataire} = 'id_member';
$dm_cfg{send_by_email_field1_destinataire} = 'fusion_short';
$dm_cfg{send_by_email_field_email_destinataire} = 'email';
$dm_cfg{send_by_email_table_templates} = 'handmade_templates';
# $dm_cfg{send_by_email_id_template} = 19;

$dm_cfg{list_custom_action_12_title} = 'Espace';
$dm_cfg{list_custom_action_12_class} = 'hide';
# $dm_cfg{list_custom_action_15_func} = \&custom_deverrouiller;
$dm_cfg{list_custom_action_11_func} = \&custom_facturer;


$dm_cfg{custom_add_button_icon} = '<i class="fa fa-fw fa-arrow-circle-o-right "></i>';$dm_cfg{custom_add_button_txt} = 'Sauvegarder + Etape suivante';
$dm_cfg{custom_add_button_id} = 'details_doc';
$dm_cfg{custom_edit_button_txt} = '<i class="fa fa-fw fa-arrow-circle-o-right "></i>';$dm_cfg{custom_add_button_txt} = 'Sauvegarder + Etape suivante';
$dm_cfg{custom_edit_button_id} = 'details_doc';
my $document_name = 'commandes';



 my $js = <<"EOH";
		
		<script type="text/javascript">
						
			jQuery(document).ready( function () 
			{   
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
			});	
		</script>
		<style>
		.ajouter_client,.ajouter_facturation
		{
			cursor:pointer;
			/*font-weight:bold;*/
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
	init_button_document('commandes');
});
</script>
<style>
.dm_lock_off 
{
	/*display:none !important;*/
}
#edit_form_container .admin_edit_save
{
}
</style>
EOH



my $id_data_family = get_quoted('id') || 0;



$dm_cfg{list_html_bottom} = <<"EOH";
<style>
.mig_cb_col,.td-input
{
/*	display:none;*/
}
.list_action a.disabled
{
	color:grey;
}
.ajouter_client,.ajouter_facturation
{
	/*background-color:none!important;*/
}
.ajouter_client p,.ajouter_facturation p
{
	/*background-color:red!important;*/
}


</style>
<div class="panel">
<div class="panel-footer ">
                            <h3>
									<span class=""> <b class="nb_commandes">...</b> commandes</span>
									 pour 
									<span class=""><b class="nb_docs">...</b> documents </span>
									
							</h3>
							
                        </div>
</div>
<script>
jQuery(document).ready(function() 
{
    jQuery(".search_element").change(function()
	{
		get_request_body();
	});
	 jQuery("#list_keyword").keypress(function()
	{
		get_request_body();
	});
	 jQuery("#list_keyword").blur(function()
	{
		get_request_body();
	});
});

function custom_func_list()
{
	jQuery('.list_actions_2').removeClass('list_actions_2').addClass('list_actions_6');
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

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd	

%choix = (
    '1'=>"Oui",
    '0'=>"Non",
);
%cle = (
    '1'=>"Oui",
    '0'=>"Non",
);
%envoie_facture = (
    '0'=>"Agence",
    '1'=>"Client",
);	
my $cpt = 9;
$tab = 'commercial';

@dm_nav =
	(
		 {
			'tab'=>'Commercial',
			'type'=>'tab',
			'title'=>'Commercial'
		}
		,
		 {
			'tab'=>'Coordonnees',
			'type'=>'tab',
			'title'=>'Coordonnees'
		}
		# ,
		 # {
			# 'tab'=>'Facturation',
			# 'type'=>'tab',
			# 'title'=>'Facturation'
		# }
		,
		 {
			'tab'=>'Contact',
			'type'=>'tab',
			'title'=>'Contact'
		}
		,
		 {
			'tab'=>'factures-emises',
			'type'=>'tab',
			'title'=>'Factures',
			'cgi_func' => 'def_handmade::factures_client',
			'disable_add' => 1
		}
		,
		 {
			'tab'=>'Annexes-factures',
			'type'=>'tab',
			'title'=>'Annexes factures'
		}
		,
		 {
			'tab'=>'Photos',
			'type'=>'tab',
			'title'=>'Photos'
		}
		,
		 {
			'tab'=>'PJ',
			'type'=>'tab',
			'title'=>'Pièces jointes'
		}
		
			
	);
	
	
	%type_member = (
    'Agence'=>"Agence/Notaire",
    'Particulier'=>"Particulier",
);

%type_agence = (
    'agence'=>"Agence",
    'notaire'=>"Notaire",
);
%dm_dfl = 
(
	
	sprintf("%05d", $cpt++).'/id_type_bien'=>{'title'=>'Type de bien','translate'=>0,'list_edit'=>1,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => 'not_empty'},tab=>$tab='Commercial','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"visible='y'",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_statut_commande'=>{'title'=>'Statut commande','translate'=>0,'list_edit'=>1,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => 'not_empty'},tab=>$tab,'lbtable'=>'handmade_certigreen_statuts_commande','lbkey'=>'id','lbdisplay'=>'nom','lbwhere'=>"",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0,'default_value'=>1},
	sprintf("%05d", $cpt++).'/id_statut_facturation'=>{'title'=>'Statut facturation','translate'=>0,'list_edit'=>1,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => 'not_empty'},tab=>$tab,'lbtable'=>'handmade_certigreen_statuts_facturation','lbkey'=>'id','lbdisplay'=>'nom','lbwhere'=>"",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0,'default_value'=>1},
	sprintf("%05d", $cpt++).'/id_employe'=>{default_value=>25,'title'=>'Propriétaire','list_edit'=>1,'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'users','lbkey'=>'id','lbdisplay'=>"CONCAT(firstname,' ',lastname)",'lbwhere'=>"id_role='8'",'lbordby'=>"firstname,lastname",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/date_mission'=>{'title'=>'Date','translate'=>0,'fieldtype'=>'text','data_type'=>'date','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/adresse_rue'=>{'title'=>'Rue','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/adresse_numero'=>{'title'=>'Numero','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/adresse_cp'=>{'title'=>'Code postal','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/adresse_ville'=>{'title'=>'Ville','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
    sprintf("%05d", $cpt++).'/cle_disponible'=>{'title'=>'Cle disponible à l\'agence','translate'=>0,'fieldtype'=>'checkbox','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	# sprintf("%05d", $cpt++).'/code_promo'=>{'title'=>'Code promo','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},

	sprintf("%05d", $cpt++).'/titre'=>{'title'=>'Client','translate'=>0,'fieldtype'=>'titre','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab="Coordonnees",'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_member'=>{'title'=>'Contact Client','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab="Coordonnees",'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/titre'=>{'title'=>'<span>+</span> Ajouter/voir','class'=>'ajouter_client','translate'=>0,'fieldtype'=>'titre','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/lastname'=>{'title'=>'Nom *','class'=>$line_class='line_client hide','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/firstname'=>{'title'=>'Prénom','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/type_member'=>{'title'=>'Type','class'=>$line_class,'translate'=>0,'fieldtype'=>'listbox','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_member,'hidden'=>0},
	sprintf("%05d", $cpt++).'/type_agence'=>{'title'=>'Agence ou notaire ?','class'=>$line_class,'translate'=>0,'fieldtype'=>'listbox','data_type'=>'button','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/street'=>{'title'=>'Rue','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/number'=>{'title'=>'Numéro','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/zip'=>{'title'=>'Code postal','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/city'=>{'title'=>'Ville','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/tel'=>{'title'=>'Téléphone','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'tel','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/email'=>{'title'=>'Email','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'email','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/emailb'=>{'title'=>'Email secondaire','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'email','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/password'=>{'title'=>'Mot de passe','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'password','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/id_agence'=>{'title'=>'Agence','class'=>$line_class,'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>('CONCAT(members.lastname," ",members.firstname)'),'lbwhere'=>"type_member = 'Agence' and lastname != ''",'lbordby'=>"",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/id_agence2'=>{'title'=>'Agence 2','class'=>$line_class,'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => '','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>('CONCAT(members.lastname," ",members.firstname)'),'lbwhere'=>"type_member = 'Agence' and lastname != ''",'lbordby'=>"",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/id_agence3'=>{'title'=>'Agence 3','class'=>$line_class,'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => '','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>('CONCAT(members.lastname," ",members.firstname)'),'lbwhere'=>"type_member = 'Agence' and lastname != ''",'lbordby'=>"",'fieldvalues'=>\%type_agence,'hidden'=>0},

	sprintf("%05d", $cpt++).'/titre'=>{'title'=>'Facturation','translate'=>0,'fieldtype'=>'titre','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_id_member'=>{'title'=>'Contact Facturation','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/facturation_idem_client'=>{'title'=>'Idem <b>Contact Client</b>','translate'=>0,'fieldtype'=>'checkbox','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>'fusion_short','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/titre'=>{'title'=>'<span>+</span> Ajouter/voir','class'=>'ajouter_facturation','translate'=>0,'fieldtype'=>'titre','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_nom'=>{'title'=>'Nom *','class'=>$line_class='line_facturation hide','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_prenom'=>{'title'=>'Prénom','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_street'=>{'title'=>'Rue','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_number'=>{'title'=>'Numéro','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_zip'=>{'title'=>'Code postal','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_city'=>{'title'=>'Ville','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_email'=>{'title'=>'Email','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'email','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/facture_email'=>{'title'=>'Email secondaire','class'=>$line_class,'translate'=>0,'fieldtype'=>'text','data_type'=>'email','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},


  	# sprintf("%05d", $cpt++).'/titre'=>{'title'=>'Contact','translate'=>0,'fieldtype'=>'titre','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab='Contact','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/contact_prenom'=>{'title'=>'Prénom','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab='Contact','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/contact_tel'=>{'title'=>'Téléphone','translate'=>0,'fieldtype'=>'text','data_type'=>'tel','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/contact_email'=>{'title'=>'Email','translate'=>0,'fieldtype'=>'text','data_type'=>'email','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/remarque'=>{'title'=>'Remarque','translate'=>0,'fieldtype'=>'textarea','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	
	
  	# sprintf("%05d", $cpt++).'/titre'=>{'title'=>'Commercial','translate'=>0,'fieldtype'=>'titre','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	
	# sprintf("%05d", $cpt++).'/prix'=>{'title'=>'Prix hors TVA','translate'=>0,'fieldtype'=>'text','data_type'=>'euros','search' => 'y','mandatory'=>{"type" => ''},tab=>'Factures','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	# sprintf("%05d", $cpt++).'/envoie_facture'=>{'title'=>'Envoyer la facture au client','translate'=>0,'fieldtype'=>'checkbox','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},tab=>'Factures','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"id",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/remarque_facturation'=>{'title'=>'Message facturation','translate'=>0,'fieldtype'=>'textarea','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>'Annexes-factures','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/montant_restant'=>{'title'=>'Montant restant','translate'=>0,'fieldtype'=>'text','data_type'=>'euros','search' => 'y','mandatory'=>{"type" => ''},tab=>'Annexes-factures','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
	sprintf("%05d", $cpt++).'/factures'=>{'title'=>'Factures annexes','translate'=>0,'fieldtype'=>'files_admin','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},tab=>'Annexes-factures','lbtable'=>'types_bien','lbkey'=>'id','lbdisplay'=>'type_1','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},

	sprintf("%05d", $cpt++).'/photos'=>{'title'=>'Photos','translate'=>0,'fieldtype'=>'files_admin','data_type'=>'','search' => '','mandatory'=>{"type" => ''},tab=>'Photos','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},
	sprintf("%05d", $cpt++).'/pj'=>{'title'=>'Pièces jointes','translate'=>0,'fieldtype'=>'files_admin','data_type'=>'','search' => '','mandatory'=>{"type" => ''},tab=>'PJ','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"",'lbordby'=>"fusion",'fieldvalues'=>\%type_agence,'hidden'=>0},

);

	

%dm_display_fields = 
(
sprintf("%05d", 10)."/Date"=>"date_mission",

sprintf("%05d", 90)."/Statut"=>"id_statut_commande",
sprintf("%05d", 94)."/Restant"=>"montant_restant",
sprintf("%05d", 95)."/Remarque"=>"remarque",

);


%dm_lnk_fields = 
(
sprintf("%05d", 20)."/Client/denom"=>"denom_client_agence*",
sprintf("%05d", 25)."/Bien/denom_commande"=>"denom_commande*",
sprintf("%05d", 30)."/Documents/denom_documents"=>"denom_documents*",

);
%dm_mapping_list = (
"denom_client_agence" => \&denom_client_agence,
"denom_commande" => \&denom_commande,
"denom_documents" => \&denom_documents,
);





sub after_save_add
{	
    my $dbh_rec = $_[0];
    my $id = $_[1];
	
	
	
}

my %ouinon10 = (
'1/1'=>'Non',
'1/0'=>'Oui',
);


%dm_filters = 
(
"1/Dates complétées ?"=>
{
      'type'=>'hash',
	     'ref'=>\%ouinon10,
	     'col'=>'documents_restants'
}
,
"60/Statut commande"=>
{
	'type'=>'lbtable',
	'table'=>'handmade_certigreen_statuts_commande',
	'key'=>'id',
	'display'=>"nom",
	'lbordby'=>"ordby",
	
	'col'=>'id_statut_commande',
	'where'=>""
}
,
"60/Statut facturation"=>
{
	'type'=>'lbtable',
	'table'=>'handmade_certigreen_statuts_facturation',
	'key'=>'id',
	'display'=>"nom",
	'lbordby'=>"ordby",
	'col'=>'id_statut_facturation',
	'where'=>""
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
,
"80/Dates"=>{
                         'type'=>'fulldaterange',
                         'col'=>'date_mission',
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

	my $client = def_handmade::denom($dbh,$rec{id_member});
	my $agence = def_handmade::denom($dbh,$rec{id_member_agence});
	my $facture = def_handmade::denom($dbh,$rec{facture_id_member});
	
	
	
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
	return def_handmade::denom($dbh,$rec{id_member_agence});
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

sub after_save
{
    my $dbh=$_[0];
    my $id=$_[1];
	
	my $fusion = denom_commande($dbh,$id);
	my $fusion_short = denom_commande($dbh,$id,'short'); 
	
	$fusion =~ s/\'/\\\'/g;
	$fusion_short =~ s/\'/\\\'/g;
	
	my $stmt = <<"EOH";
		UPDATE $dm_cfg{table_name} SET fusion = '$fusion',fusion_short='$fusion_short' WHERE id = '$id'
EOH
	log_debug($stmt,'','after_save');
	execstmt($dbh,$stmt);
	
		my $stmt = <<"EOH";
		UPDATE $dm_cfg{table_name} SET id_statut_facturation = '4' WHERE id_statut_facturation = 0
EOH
	log_debug($stmt,'','after_save');
	execstmt($dbh,$stmt);
	
	
		my $stmt = <<"EOH";
		UPDATE $dm_cfg{table_name} SET id_statut_commande = '2' WHERE id_statut_commande = 0
EOH
	log_debug($stmt,'','after_save');
	execstmt($dbh,$stmt);
	
	
	# my $stmt = <<"EOH";
		# UPDATE $dm_cfg{table_name} SET validation = '0' WHERE id = '$id' 
# EOH

my $stmt = <<"EOH";
		UPDATE $dm_cfg{table_name} SET validation = '1' WHERE id = '$id' AND (email != '' OR id_member > 0 OR nom_dossier != '' OR adresse_ville != '' OR facture_nom != '' OR nb_doc > 0)
EOH
	log_debug($stmt,'','after_save');
	execstmt($dbh,$stmt);
	
	
	$stmt = <<"EOH";
	UPDATE commandes c
SET 
nb_doc = 
(
    SELECT COUNT(*) FROM commande_documents doc, migcms_linked_files lnk
    WHERE
    lnk.table_name='commande_documents' 
    AND lnk.token = doc.id
    AND	doc.commande_id = c.id
)
WHERE id = '$id'
EOH
	execstmt($dbh,$stmt);
	use Data::Dumper;
	my %record = read_table($dbh,$dm_cfg{table_name},$id);
	my %update_record = ();
	# log_debug(Dumper(\%record),'','after_save');
	# log_debug(Dumper(\%update_record),'','after_save');
	#créer id_member si = 0 (à partir des coordonées)
	
	#créer facture_id_member (à partir des coordonnées facture)
	
		# log_debug('$record{id_member}:'.$record{id_member},'','after_save');

	#si client lié mais coordonnées vides, les compléter
	my @fields = ('lastname','firstname','tel','street','number','zip','city','email','emailb','id_agence','id_agence2','id_agence3');  
	if($record{id_member} > 0)
	{
		# log_debug("1: MEMBRE EXISTE",'','after_save');
		my %member = read_table($dbh,'members',$record{id_member});
		# log_debug('$member{id}:'.$member{id},'','after_save');

		foreach my $f (@fields)
		{
			# log_debug('$f:'.$f,'','after_save');
			if($f ne '')
			{
			$update_record{$f} = $member{$f};
			}
			# log_debug("$update_record{$f} = $member{$f};",'','after_save');
		}
	}
	else
	{
			# log_debug("2: MEMBRE AJOUT",'','after_save');
			#INSERT MEMBER
			my %insert_member = ();  
			my $if = 0;
			foreach my $f (@fields)
			{
				my $value = get_quoted($f);
				$insert_member{$fields[$if]} = trim($value);
				$if++;
			}      
			$insert_member{token} = create_token(100);
			# log_debug(Dumper(\%insert_member),'','after_save');

			if($insert_member{lastname} ne '')
			{
				my $new_id_member = sql_set_data({debug=>0,dbh=>$dbh,table=>'members',data=>\%insert_member,where=>''});     
				$update_record{id_member} = $new_id_member;
			}
	}
	
	#si client facture lié mais coordonnées facture vides, les compléter
	my @fields = ('lastname','firstname','tel','street','number','zip','city','email');  
	my @fields_commande_facture = ('facture_nom','facture_prenom','facture_street','facture_number','facture_zip','facture_city','facture_email');  

	if($record{facture_id_member} > 0)
	{
		# log_debug("3: MEMBRE FACTURE EXISTE",'','after_save');
		my %member = read_table($dbh,'members',$record{facture_id_member});
		# log_debug('$member{id}:'.$member{id},'','after_save');

		my $fc = 0;

		foreach my $f (@fields)
		{
			log_debug('$fields_commande_facture[$fc]:'.$fields_commande_facture[$fc],'','after_save');
			if($fields_commande_facture[$fc] ne '')
			{
				$update_record{$fields_commande_facture[$fc]} = $member{$f};
			}
			$fc++;
		}
	}
	else
	{
			# log_debug("4: MEMBRE AJOUT",'','after_save');
			
			#INSERT MEMBER
			my %insert_member = ();  
			my $if = 0;
			foreach my $f (@fields)
			{
				my $value = get_quoted($fields_commande_facture[$if]);
				$insert_member{$fields[$if]} = trim($value);
				$if++;
			}      
			$insert_member{token} = create_token(100);
			# log_debug(Dumper(\%insert_member),'','after_save');

			if($insert_member{lastname} ne '')
			{
				my $new_id_member = sql_set_data({debug=>0,dbh=>$dbh,table=>'members',data=>\%insert_member,where=>''});     
				$update_record{facture_id_member} = $new_id_member;
			}
	}
	
	
	# log_debug(Dumper(\%update_record),'','after_save');
	
	%update_record = %{quoteh(\%update_record)};
	updateh_db($dbh,$dm_cfg{table_name},\%update_record,'id',$record{id});
	
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
	
	my %test_doc = sql_line({table=>'intranet_documents',where=>"id_record='$record{id}'"});
	if($test_doc{id} > 0)
	{
		ajax_make_pdf_document($record{id},$dm_cfg{file_prefixe});
	}
}



sub denom_documents
{
	my $dbh = $_[0];
	my $id = $_[1];
	my $type = $_[2] || 'long';
	
	my $hide_class = 'hide';
	my $fa_class = 'fa-plus-square-o';
	if(trim(get_quoted('list_keyword')) ne '' )
	{
	$hide_class = '';
	$fa_class = 'fa-minus-square-o';
	}

	
	if($id > 0)
	{
		my %commande = sql_line({table=>'commandes',where=>"id='$id'"});
		my %corr = 
		(
			1 => 'Certificat PEB',
			2 => 'Electricité',
			3 => 'Citerne',
			4 => 'Amiante',
			5 => 'Pollution des sols',
		);
		
		my %corr_img = 
		(
			1 => 'peb.png',
			2 => 'elec.png',
			3 => 'citerne.png',
			4 => 'amiante.png',
			5 => 'symbole_pollution.png',
		);
		
		my $fusion = '';
		my $list_doc_img = '';
		my $list_warn = '';
		
		my @commande_documents = sql_lines({table=>'commande_documents',where=>"commande_id='$id' AND migcms_deleted != 'y'"});
		
		if($#commande_documents == -1)
		{
			# 'Aucun document';
			$fusion .= "<a  target=\"_blank\"  href='../cgi-bin/adm_handmade_certigreen_commande_documents.pl?sel=1000278&sw=&commande_id=$id' data-original-title='Ajouter des documents' data-placement = 'bottom'><i class=\"fa fa-plus fa-fw\"></i></a>";
		}
		
		foreach $commande_document (@commande_documents)
		{
			my %commande_document = %{$commande_document};
			my $document = $corr{$commande_document{type_document_id}};
			my $document_img = $corr_img{$commande_document{type_document_id}};
			$commande_document{date_prevue} = to_ddmmyyyy($commande_document{date_prevue});
			$commande_document{heure_prevue} = sql_to_human_time($commande_document{heure_prevue});
			my $date_prevue = trim($commande_document{date_prevue}.' '.$commande_document{heure_prevue});
			if($date_prevue eq '-- 00:00:00')
			{
				$date_prevue = '';
			}
			
			my $doc = "<a target=\"_blank\" href='../cgi-bin/adm_handmade_certigreen_commande_documents.pl?sel=1000278&sw=&commande_id=$id' data-original-title='$document : $date_prevue' data-placement = 'bottom'><img src='../skin/img/$document_img' alt='$document' /></a>";
			if($doc ne '' && $doc ne 'short')
			{
				$list_doc_img .= "$doc ";
				if($commande_document{date_prevue} eq '' || $date_prevue eq '')
				{
					$list_warn .= '<br /><span style="color:red"><i class="fa fa-exclamation-triangle" aria-hidden="true"></i> Pas de date fixée pour <b>'.$document.'</b></span>';
				}
			}
		}
		$fusion .= $list_doc_img.$list_warn;
		
		if($type ne 'short')
		{
			$fusion .= '<a href=""  target=\"_blank\"  data-placement="bottom" data_original-title="Modifier la commande" id="'.$commande{id}.'" class="migedit_'.$commande{id}.' migedit">';
		}
		
		if($commande{code_promo} ne '')
		{
			$fusion .= "<br />PROMO: $commande{code_promo}";
		}
		
		$fusion =~s/\<br \/\>$//g;
		if($type ne 'short')
		{
			$fusion .= '</a>';
		}			
		return $fusion;
	}
	else
	{
		return '';
	}
}


sub custom_facturer
{
	my $id = $_[0];
	my $colg = $_[1];
	my %rec = %{$_[2]};
	my $table_name = $_[3];
	return def_handmade::custom_facturer($id,$colg,\%rec,$table_name);
}

sub custom_deverrouiller
{
	my $id = $_[0];
	my $colg = $_[1];
	my %rec = %{$_[2]};
	my $table_name = $_[3];
	return def_handmade::custom_deverrouiller($id,$colg,\%rec,$table_name);
}

sub validation_func
{
	my $dbh=$_[0];
    my %item = %{$_[1]};
	my $id = $_[2];
	
	log_debug('validation','vide','validation');
	log_debug('ID:'.$id,'','validation');
	
	if($id > 0)
	{
		#MODIFICATION
		my $rapport = '';
		my $valide = 1;
		
		
		#champs obligatoires pour alias: 
		my @obligatoires_societe_champs = qw
		(
			id_type_bien
			id_statut_commande
			id_statut_facturation
		);
		
		my @obligatoires_societe_noms = 
		(
			'Commercial > Type de bien',
			'Commercial > Statut commande',
			'Commercial > Statut facturation',
		);

		#regles basiques (champs complété)
		my $c = 0;
		if($item{id_father} == 0)
		{
			foreach my $obligatoires_societe_champ (@obligatoires_societe_champs)
			{
				log_debug($obligatoires_societe_champ.':'.$item{$obligatoires_societe_champ},'','validation');
				my $nom = $obligatoires_societe_noms[$c];
				if($item{$obligatoires_societe_champ} eq '' || $item{$obligatoires_societe_champ} eq ',')
				{
					$valide = 0;
					$rapport .=<<"EOH";
					<tr><td><i class="fa fa-times"></i> $nom</td><td>Le champs doit être complété.</td></tr>
EOH
				}
				$c++;
				}
		}
		
		
		if($item{id_member} > 0)
		{
			#soit client existant
		}
		else
		{
			# soit nouveau client (email différent) 
			if($item{lastname} eq '')
			{
				$valide = 0;
				$rapport .=<<"EOH";
				<tr><td><i class="fa fa-times"></i> Ajouter un client > Nom</td><td>Si vous ne choisissez pas un contact existant: <br />Le champs doit être complété </td></tr>
EOH
			}
			
			# if($item{email} ne '')
			# {
				# my %check_member = sql_line({table=>'members',where=>"email = '$item{email}'"});
				# if($check_member{id} > 0)
				# {
					# $valide = 0;
					# $rapport .=<<"EOH";
					# <tr><td><i class="fa fa-times"></i> Ajouter un client > Email</td><td>Si vous ne choisissez pas un client existant: Si vous encodez un email, celui-ci ne doit pas être déjà dans la base de donnée. L'email sert en effet d'identifiant de connexion au membre: <b>$check_member{firstname} $check_member{lastname} #$check_member{id}</b></td></tr>
# EOH
				# }
			# }
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
			
			return 'validation_error___'.$rapport;
		}
		else
		{
			return '';
		}
	}
	else
	{
		#AUTOCREATION
		return '';
	}
}