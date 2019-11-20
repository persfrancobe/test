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
# migc modules

         # migc translations


use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;
use sitetxt;
use eshop;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------









$dm_cfg{customtitle}=<<"EOH";
EOH

$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "eshop_setup";
$dm_cfg{list_table_name} = "eshop_setup";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{id_col} = 'id';


$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_setup_eshop.pl?";

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_ordby_ref} = '';
$dm_cfg{hiddp}=<<"EOH";
EOH

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = 
(
      '01/code'=> 
      {
      'title'=>"Identifiant de la boutique <br>(10 char max de a à z uniquement)",
      'fieldtype'=>'text',
      'mandatory'=>{"type" => 'not_empty'}      
      }
      ,
      '02/eshop_name'=> 
      {
      'title'=>"Nom de la boutique",
      'fieldtype'=>'text',
      'mandatory'=>{"type" => 'not_empty'}    
      }
      ,
      '03/eshop_street'=> 
      {
      'title'=>"Adresse",
      'fieldtype'=>'text',
      }
      ,
      '04/eshop_zip_city'=> 
      {
      'title'=>"CP et Ville",
      'fieldtype'=>'text',
      }
      ,
      '05/eshop_country'=> 
      {
      'title'=>"Pays",
      'fieldtype'=>'text',
      }
      ,
      '06/eshop_tel'=> 
      {
      'title'=>"Téléphone",
      'fieldtype'=>'text',
      }
      ,
      '07/eshop_email'=> 
      {
      'title'=>"Email",
      'fieldtype'=>'text',
      'mandatory'=>{"type" => 'not_empty'}    
      }
      ,
      '07/eshop_email_debug'=> 
      {
      'title'=>"Email de testing",
      'fieldtype'=>'text',
      }
      ,
      '08/eshop_web'=> 
      {
      'title'=>"Site web",
      'fieldtype'=>'text',
      }
      ,
      '09/eshop_tva'=> 
      {
      'title'=>"TVA",
      'fieldtype'=>'text',
      },
      '10/eshop_banque'=> 
      {
      'title'=>"Banque",
      'fieldtype'=>'text',
      }
      ,
      '11/eshop_iban'=> 
      {
      'title'=>"IBAN",
      'fieldtype'=>'text',
      }
      ,
      '12/eshop_bic'=> 
      {
      'title'=>"BIC",
      'fieldtype'=>'text',
      }
      ,
      '12/id_textid_conditions'=> 
      {
      'title'=>"Texte à cocher pour les conditions",
      'fieldtype'=>'textarea_id',
      }
      ,
      '15/post_order_func'=> 
      {
      'title'=>"Fonction appelée après commande",
      'fieldtype'=>'text'
      }
      ,
       '16/email_from'=> 
      {
      'title'=>"Adresse email",
      'fieldtype'=>'text',
      'mandatory'=>{"type" => 'not_empty'}      
      }
	 
      ,
      '20/id_tpl_page1'=> 
      {
      'title'=>"Template de page complet",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'templates',
      'lbkey'=>'templates.id',
      'lbdisplay'=>'templates.name',
      'lbwhere'=>"type = 'page'",
      'mandatory'=>{"type" => 'not_empty'}
      }
      ,
      '30/id_tpl_page2'=> 
      {
      'title'=>"Template de page réduit",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'templates',
      'lbkey'=>'templates.id',
      'lbdisplay'=>'templates.name',
      'lbwhere'=>"type = 'page'",
      'mandatory'=>{"type" => 'not_empty'}
      }
      ,
      '31/id_data_field_name1'=> 
      {
      'title'=>"Champ 1 du libellé de commande",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'data_fields',
      'lbkey'=>'id',
      'lbdisplay'=>"CONCAT('FAMILLE',id_data_family,', f',data_fields.ordby)",
      'lbwhere'=>"",
      }
      ,
      '32/id_data_field_name2'=> 
      {
      'title'=>"Champ 2 du libellé de commande",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'data_fields',
      'lbkey'=>'id',
      'lbdisplay'=>"CONCAT('FAMILLE',id_data_family,', f',data_fields.ordby)",
      'lbwhere'=>"",
      }
      ,
      '33/id_data_field_name3'=> 
      {
      'title'=>"Champ 3 du libellé de commande",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'data_fields',
      'lbkey'=>'id',
      'lbdisplay'=>"CONCAT('FAMILLE',id_data_family,', f',data_fields.ordby)",
      'lbwhere'=>"",
      }
      ,
      '34/id_data_field_name4'=> 
      {
      'title'=>"Champ 4 du libellé de commande",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'data_fields',
      'lbkey'=>'id',
      'lbdisplay'=>"CONCAT('FAMILLE',id_data_family,', f',data_fields.ordby)",
      'lbwhere'=>"",
      }
      ,
      '35/id_data_field_name5'=> 
      {
      'title'=>"Champ 5 du libellé de commande",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'data_fields',
      'lbkey'=>'id',
      'lbdisplay'=>"CONCAT('FAMILLE',id_data_family,', f',data_fields.ordby)",
      'lbwhere'=>"",
      }
      ,
      '52/id_tpl_member_on'=> 
      {
      'title'=>"Template de box membre connecté",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'templates',
      'lbkey'=>'templates.id',
      'lbdisplay'=>'templates.name',
      'lbwhere'=>"type = 'shop'",
      }
      ,
      '53/id_tpl_member_off'=> 
      {
      'title'=>"Template de box membre déconnecté",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'templates',
      'lbkey'=>'templates.id',
      'lbdisplay'=>'templates.name',
      'lbwhere'=>"type = 'shop'",
      }
      ,
      '60/url_info_livraison'=> 
      {
      'title'=>"URL de la page d'info sur les frais de port",
      'fieldtype'=>'text'
      }
      ,
      '61/google_analytics_account'=> 
      {
      'title'=>"Compte Google Analytics",
      'fieldtype'=>'text'
      }
      ,
      '62/google_adwords_account'=> 
      {
      'title'=>"Compte Google Adwords",
      'fieldtype'=>'text'
      }
      ,
      '63/google_adwords_code_language'=> 
      {
      'title'=>"Adwords: code language",
      'fieldtype'=>'text'
      }
      ,
      '64/google_adwords_label_1'=> 
      {
      'title'=>"Adwords: campagne cible en FR",
      'fieldtype'=>'text'
      }
      ,
      '65/google_adwords_label_2'=> 
      {
      'title'=>"Adwords: campagne cible en EN",
      'fieldtype'=>'text'
      }
      ,
      '66/google_adwords_label_3'=> 
      {
      'title'=>"Adwords: campagne cible en NL",
      'fieldtype'=>'text'
      }
      ,
      '67/google_adwords_label_4'=> 
      {
      'title'=>"Adwords: campagne cible en DE",
      'fieldtype'=>'text'
      }
      ,
      '68/google_adwords_label_5'=> 
      {
      'title'=>"Adwords: campagne cible en IT",
      'fieldtype'=>'text'
      }
      ,
      '70/default_delivery'=> 
      {
        'title'=>"Méthode de livraison précochée",
        'fieldtype'=>'listboxtable',
        'lbtable'=>'eshop_deliveries',
        'lbkey'=>'eshop_deliveries.name',
        'lbdisplay'=>'eshop_deliveries.name',
        'lbwhere'=>"visible = 'y'",
      'mandatory'=>{"type" => 'not_empty'}  
      }
      ,
      '71/default_payment'=> 
      {
        'title'=>"Méthode de paiement précochée",
        'fieldtype'=>'listboxtable',
        'lbtable'=>'eshop_payments',
        'lbkey'=>'eshop_payments.name',
        'lbdisplay'=>'eshop_payments.name',
        'lbwhere'=>"visible = 'y'",
      'mandatory'=>{"type" => 'not_empty'}  
      }
      ,
      '72/cart_listbox_countries'=> 
      {
        'title'=>"Liste des pays dans le panier",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y'
      }
       ,
      '75/cart_default_id_country'=> 
      {
        'title'=>"Pays par défaut",
        'fieldtype'=>'listboxtable',
        'lbtable'=>'countries',
        'lbkey'=>'id',
        'lbdisplay'=>'fr',
        'lbwhere'=>""
      }
      
       ,
      '77/auto_create_member'=> 
      {
        'title'=>"Créer automatiquement un membre",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y',
      }
      
       ,
       
 '771/member_autologin_after_signup'=>
      {
        'title'=>"Connexion auto après inscription (membre)",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y',
      },
 '772/revendeur_autologin_after_signup'=>
      {
        'title'=>"Connexion auto après inscription (revendeur)",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y',
      },

       
      '76/create_ext_identities'=> 
      {
        'title'=>"Générer un membre pour passerelle externe",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y',
      }
       ,
      '77/cart_show_method_delivery_name'=> 
      {
        'title'=>"Afficher le nom de la méthode dans le panier",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y',
      }
      
      ,
      '79/avert_stock'=> 
      {
        'title'=>"Avertissement de dépassement de stock",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y'
      }
      
      ,
      '80/disable_detail_link'=> 
      {
        'title'=>"Panier: Désactiver le lien vers le produit",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y'
      }
      ,
      '81/disable_edit_qty'=> 
      {
        'title'=>"Panier: Désactiver la modification de quantité",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y'
      }
      
      ,
      '85/check_stock'=> 
      {
        'title'=>"Contrôler le stock",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y'
      }
      ,
      '87/create_member_in_delivery'=> 
      {
        'title'=>"Pouvoir créer un membre à l'étape 2.",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y'
      }
      ,
      '88/sauter_livraison'=> 
      {
        'title'=>"Désactiver l'étape 2. Livraison",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y'
      }
      ,
      '89/sauter_methode_livraison'=> 
      {
        'title'=>"Désactiver l'étape 2. Méthodes de livraison",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y'
      }
      
      ,
      '90/sauter_facturation'=> 
      {
        'title'=>"Désactiver l'étape 3. Facturation",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y'
      }
      ,
      '91/cacher_breadcrumb'=> 
      {
        'title'=>"Cacher le breadcrumb",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y'
      }
      ,
      '92/login_obligatoire'=> 
      {
        'title'=>"Identification obligatoire",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y'
      }
      ,
      '93/cacher_lien_creer_un_compte'=> 
      {
        'title'=>"Cacher le lien créer un compte",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y'
      }
      ,
      '94/montant_pour_livraison_gratuite'=> 
      {
        'title'=>"Montant à atteindre pour la livraison gratuite + avertissement",
        'fieldtype'=>'text',
      }
      ,
      '95/plusieurs_profils_livraison'=> 
      {
        'title'=>"Gérer plusieurs profils de livraison à la fois",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y'
      } ,
      '96/weight_unit'=> 
      {
        'title'=>"Unité pour le poids",
        'fieldtype'=>'text'
      }
       ,
      '97/detail_invoice_after_id'=> 
      {
        'title'=>"Détail de facture après l'ID",
        'fieldtype'=>'text'
      }
      ,
      '99/shop_disabled'=> 
      {
        'title'=>"Désactiver la boutique",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y'
      }
      
);
	
  
#   ,
#       '40/show_pu_htva'=> 
#       {
#       'title'=>'Afficher la colonne PU HTVA',
#       'fieldtype'=>'checkbox',
#       'checkedval' => 'y'
#       }
#       ,
#       '42/show_pu_tva'=> 
#       {
#       'title'=>'Afficher la colonne PU TVA',
#       'fieldtype'=>'checkbox',
#       'checkedval' => 'y'
#       }
#       ,
#       '44/show_pu_tvac'=> 
#       {
#       'title'=>'Afficher la colonne PU TVAC',
#       'fieldtype'=>'checkbox',
#       'checkedval' => 'y'
#       }
#       ,
#       '50/show_total_htva'=> 
#       {
#       'title'=>'Afficher la colonne TOTAL HTVA',
#       'fieldtype'=>'checkbox',
#       'checkedval' => 'y'
#       }
#       ,
#       '52/show_total_tva'=> 
#       {
#       'title'=>'Afficher la colonne TOTAL TVA',
#       'fieldtype'=>'checkbox',
#       'checkedval' => 'y'
#       }
#       ,
#       '54/show_total_tvac'=> 
#       {
#       'title'=>'Afficher la colonne TOTAL TVAC',
#       'fieldtype'=>'checkbox',
#       'checkedval' => 'y'
#       }

%dm_display_fields = (
"01/Configuration de la boutique"=>"id_tpl_page1"
		);

%dm_lnk_fields = (
		);

%dm_mapping_list = (
);

%dm_filters = (
		);
		
	

$dm_cfg{help_url} = "http://www.bugiweb.com";
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
			up
			banners_link
			link_banner_category
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    
    
    
    
    my $suppl_js=<<"EOH";
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <script type="text/javascript">
    jQuery(document).ready(function() 
    {
    });
    </script>
EOH

    if($sw ne "dum")
    {
      $migc_output{content} .= $dm_output{content};
      $migc_output{title} = $dm_output{title}.$migc_output{title};
      print migc_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
    }
}


sub after_save
{
    my $dbh=$_[0];
    # my $id_banner =$_[1];
    
#     fill_eshop_words();
#     fill_eshop_logs();
    
    # my %new_config=(); 
    # $new_config{id_role}='1';
    # $new_config{varname}='eshop_url';
    # $new_config{varvalue}='cgi-bin/eshop.pl?';
    # sql_update_or_insert($dbh,"config",\%new_config,'varname','eshop_url');
    # my %new_config=(); 
    # $new_config{id_role}='1';
    # $new_config{varname}='eshop_full_url';
    # $new_config{varvalue}=$config{rewrite_protocol}."://".$config{default_url};
    # sql_update_or_insert($dbh,"config",\%new_config,'varname','eshop_full_url');
    
    #CHECK FIELD LABELS VALIDITY
    # foreach my $fstep (1 .. 5)
    # {
       # my $fstep_name = 'id_data_field_name'.$fstep;
       # my $id_data_field =  $setup{$fstep_name};
       # my %data_field = read_table($dbh,"data_fields",$id_data_field);
       # if(!($data_field{id} > 0))
       # {
            # $stmt = "UPDATE eshop_setup SET $fstep_name = 0";
            # $cursor = $dbh->prepare($stmt);
            # $cursor->execute || suicide($stmt);
       # } 
    # }
    # $stmt = "ALTER TABLE `eshop_setup` CHANGE `shop_disabled` `shop_disabled` ENUM( 'y', 'n' ) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT 'n'";
    # $cursor = $dbh->prepare($stmt);
    # $cursor->execute || suicide($stmt);
}
