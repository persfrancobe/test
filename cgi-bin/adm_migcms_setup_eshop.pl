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
         # migc translations
use sitetxt;
use eshop;


$dm_cfg{customtitle}=<<"EOH";
EOH

$dm_cfg{enable_search} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{trad} = 1;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "eshop_setup";
$dm_cfg{list_table_name} = "eshop_setup";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_setup_eshop.pl?";

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_ordby_ref} = '';

$dm_cfg{hiddp}=<<"EOH";
EOH


@dm_nav =
(
    {
        'tab'=>'iden',
		'type'=>'tab',
        'title'=>'Identification'
    }
	,
	 {
        'tab'=>'inte',
		'type'=>'tab',
        'title'=>'Intégration'
    }
	
	,
	 {
        'tab'=>'panier',
		'type'=>'tab',
        'title'=>'Panier'
    }
	,
	 {
        'tab'=>'livraison',
		'type'=>'tab',
        'title'=>'Livraison'
    }
	,
   {
        'tab'=>'recap',
    'type'=>'tab',
        'title'=>'Récapitulatif'
    }
  ,
	 
	 {
        'tab'=>'google',
		'type'=>'tab',
        'title'=>'Google'
    }
	,
	 {
        'tab'=>'member',
		'type'=>'tab',
        'title'=>'Membres'
    }

    ,
    {
      'tab'=>'order_processus',
      'type'=>'tab',
      'title'=>'Processus de commande'
    }
    ,
    {
      'tab'=>'facturation',
      'type'=>'tab',
      'title'=>'Facturation'
    }
    ,
    {
      'tab'=>'coupons',
      'type'=>'tab',
      'title'=>'Coupons'
    }
    ,
    {
        'tab'=>'Paiements',
    'type'=>'header',
        'title'=>'Paiements'
    }
  ,
    {
        'tab'=>'hipay',
    'type'=>'tab',
        'title'=>'Hipay'
    }
  ,
   {
        'tab'=>'payplug',
    'type'=>'tab',
        'title'=>'Pay Plug'
    }
  ,

	
	
	
);

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = 
(
      '01/code'=> 
      {
        'title'=>"Identifiant",
        'fieldtype'=>'text',
    	  'tip'=>'10 char max de a à z uniquement',
    	  'mask'=>'AAAAAAAAAA',
    	  'tab'=>'iden',
        'mandatory'=>{"type" => 'not_empty'}      
      }
      ,
      '02/eshop_name'=> 
      {
      'title'=>"Enseigne",
      'fieldtype'=>'text',
	  'tab'=>'iden',
      'mandatory'=>{"type" => 'not_empty'}    
      }
      ,
      '03/eshop_street'=> 
      {
      'title'=>"Adresse",
	  'tab'=>'iden',
      'fieldtype'=>'text',
      }
      ,
      '04/eshop_zip_city'=> 
      {
      'title'=>"CP et Ville",
	  'tab'=>'iden',
      'fieldtype'=>'text',
      }
      ,
      '05/eshop_country'=> 
      {
      'title'=>"Pays",
	  'tab'=>'iden',
      'fieldtype'=>'text',
      }
      ,
      '06/eshop_tel'=> 
      {
      'title'=>"Téléphone",
	  'tab'=>'iden',
      'fieldtype'=>'text',
      }
      ,
      '07/eshop_email'=> 
      {
      'title'=>"Email",
      'fieldtype'=>'text',
	  'tab'=>'iden',
      'mandatory'=>{"type" => 'not_empty'}    
      }
      ,
      '07/eshop_email_debug'=> 
      {
      'title'=>"Email de testing",
	  'tab'=>'iden',
      'fieldtype'=>'text',
      }
      ,
      '07/eshop_email_copies'=> 
      {
      'title'=>"Emails reception des mails en copie",
    'tab'=>'iden',
      'fieldtype'=>'text',
      }
      ,
      '08/eshop_web'=> 
      {
      'title'=>"Site web",
	  'tab'=>'iden',
      'fieldtype'=>'text',
      }
      ,
      '09/eshop_tva'=> 
      {
      'title'=>"TVA",
	  'tab'=>'iden',
      'fieldtype'=>'text',
      },
      '10/eshop_banque'=> 
      {
      'title'=>"Banque",
	  'tab'=>'iden',
      'fieldtype'=>'text',
      }
      ,
      '11/eshop_iban'=> 
      {
      'title'=>"IBAN",
	  'tab'=>'iden',
      'fieldtype'=>'text',
      }
      ,
      '12/eshop_bic'=> 
      {
      'title'=>"BIC",
	  'tab'=>'iden',
      'fieldtype'=>'text',
      }
      ,
      '13/id_textid_conditions'=> 
      {
      'title'=>"Texte à cocher pour les conditions",
      'tab'=>'iden',
      'fieldtype'=>'textarea_id',
      }
      ,
      # ########### #
      # INTEGRATION #
      # ########### #
      '17/post_order_func'=> 
      {
      'title'=>"Fonction appelée après commande",
	  'tab'=>'inte',
      'fieldtype'=>'text'
      }
      ,
	  '18/methode_deliveries_func'=> 
      {
      'title'=>"Fonction générant les méthodes de livraison",
	  'tab'=>'livraison',
      'fieldtype'=>'text'
      }
      ,  
       '19/email_from'=> 
      {
      'title'=>"Adresse email",
	  'tab'=>'iden',
      'fieldtype'=>'text',
      'mandatory'=>{"type" => 'not_empty'}      
      }
	 
      ,
      '20/id_tpl_page1'=> 
      {
      'title'=>"Template de page complet",
      'tab'=>'inte',
      'fieldtype'=>'listboxtable',
      'lbtable'=>'templates',
      'lbkey'=>'templates.id',
      'lbdisplay'=>'templates.name',
      'lbwhere'=>"type = 'page'",
      'mandatory'=>{"type" => 'not_empty'}
      }
      ,
      '21/id_tpl_page2'=> 
      {
      'title'=>"Template de page réduit",
	  'tab'=>'inte',
      'fieldtype'=>'listboxtable',
      'lbtable'=>'templates',
      'lbkey'=>'templates.id',
      'lbdisplay'=>'templates.name',
      'lbwhere'=>"type = 'page'",
      'mandatory'=>{"type" => 'not_empty'}
      }
      ,
      '22/id_data_field_name1'=> 
      {
      'title'=>"Champ 1 du libellé de commande",
			'tab'=>'inte',
      'fieldtype'=>'listboxtable',
      'lbtable'=>'data_fields',
      'lbkey'=>'id',
      'translate'=>1,
      'lbdisplay'=>"id_textid_name",
      'lbwhere'=>"id_data_family IN (select id from data_families where profil = 'products') ",
      }
      ,
      '23/id_data_field_name2'=> 
      {
      'title'=>"Champ 2 du libellé de commande",
			'tab'=>'inte',
      'fieldtype'=>'listboxtable',
      'lbtable'=>'data_fields',
      'lbkey'=>'id',
      'translate'=>1,
      'lbdisplay'=>"id_textid_name",
      'lbwhere'=>"id_data_family IN (select id from data_families where profil = 'products') ",
      }
      ,
      '24/id_data_field_name3'=> 
      {
      'title'=>"Champ 3 du libellé de commande",
			'tab'=>'inte',
      'fieldtype'=>'listboxtable',
      'lbtable'=>'data_fields',
      'lbkey'=>'id',
      'translate'=>1,
      'lbdisplay'=>"id_textid_name",
      'lbwhere'=>"id_data_family IN (select id from data_families where profil = 'products') ",
      }
      ,
      '25/id_data_field_name4'=> 
      {
      'title'=>"Champ 4 du libellé de commande",
			'tab'=>'inte',
      'fieldtype'=>'listboxtable',
      'lbtable'=>'data_fields',
      'lbkey'=>'id',
      'translate'=>1,
      'lbdisplay'=>"id_textid_name",
      'lbwhere'=>"id_data_family IN (select id from data_families where profil = 'products') ",
      }
      ,
      '26/id_data_field_name5'=> 
      {
      'title'=>"Champ 5 du libellé de commande",
			'tab'=>'inte',
      'fieldtype'=>'listboxtable',
      'lbtable'=>'data_fields',
      'lbkey'=>'id',
      'translate'=>1,
      'lbdisplay'=>"id_textid_name",
      'lbwhere'=>"id_data_family IN (select id from data_families where profil = 'products') ",
      }
      ,
      '27/return_exchange_disabled'=> 
      {
        'title'=>"Désactiver les retours/échanges",
        'fieldtype'=>'checkbox',
        'tab'=>'inte',
        'checkedval' => 'y',
      }
      ,
      '60/url_info_livraison'=> 
      {
      'title'=>'Page infos livraison',
           'fieldtype'=>'listboxtable',
		    'data_type'=>'treeview',
           'lbwhere'=>"migcms_pages_type!='newsletter'",			
           'lbtable'=>'migcms_pages',
           'lbkey'=>'id',
		   'legend'=>"",
		   			'tab'=>'livraison',

           'lbdisplay'=>'id_textid_name',
          	'translate' => 1,
		   'multiple'=>0,
		   'summary'=>0,
		   	'tree_col'=>'id_father',
      }
      ,
      '30/google_analytics_account'=> 
      {
      'title'=>"Compte Google Analytics",
	  'tab'=>'google',
      'fieldtype'=>'text'
      }
      ,
      '31/google_adwords_account'=> 
      {
      'title'=>"Compte Google Adwords (conversion ID)",
	  'tab'=>'google',
      'fieldtype'=>'text'
      }
      ,
      '32/google_adwords_code_language'=> 
      {
      'title'=>"Adwords: code language (conversion language)",
	  'tab'=>'google',
      'fieldtype'=>'text'
      }
      ,
      '33/google_adwords_label_1'=> 
      {
      'title'=>"Adwords: campagne cible en FR (Conversion label)",
	  'tab'=>'google',
      'fieldtype'=>'text'
      }
      ,
      '34/google_adwords_label_2'=> 
      {
      'title'=>"Adwords: campagne cible en EN (Conversion label)",
	  'tab'=>'google',
      'fieldtype'=>'text'
      }
      ,
      '35/google_adwords_label_3'=> 
      {
      'title'=>"Adwords: campagne cible en NL (Conversion label)",
	  'tab'=>'google',
      'fieldtype'=>'text'
      }
      ,
      '36/google_adwords_label_4'=> 
      {
      'title'=>"Adwords: campagne cible en DE (Conversion label)",
	  'tab'=>'google',
      'fieldtype'=>'text'
      }
      ,
      '37/hipay_id_marchand'=> 
      {
      'title'=>"Id marchand",
	  'tab'=>'hipay',
      'fieldtype'=>'text'
      }
	  ,
      '38/hipay_password_marchand'=> 
      {
      'title'=>"Password marchand",
	  'tab'=>'hipay',
      'fieldtype'=>'text'
      }
	  ,
      '39/hipay_site_id'=> 
      {
      'title'=>"Numéro de site",
	  'tab'=>'hipay',
      'fieldtype'=>'text'
      }
	  ,
      '40/hipay_category'=> 
      {
      'title'=>"Numéro de catégorie",
	  'tab'=>'hipay',
      'fieldtype'=>'text'
      }
      ,
      '41/payplug_url'=> 
      {
      'title'=>"Url ",
	  'tab'=>'payplug',
      'fieldtype'=>'text'
      }      
      ,
      '42/payplug_private_key'=> 
      {
      'title'=>"Private key",
	  'tab'=>'payplug',	  
      'fieldtype'=>'textarea'
      }
      
      ,
      '43/payplug_public_key'=> 
      {
      'title'=>"Public Key",
	  'tab'=>'payplug',	  
      'fieldtype'=>'textarea'
      }
      ,
      '70/default_delivery'=> 
      {
        'title'=>"Livraison par défaut",
		'tab'=>'livraison',
        'fieldtype'=>'listboxtable',
        'lbtable'=>'eshop_deliveries',
        'lbkey'=>'eshop_deliveries.name',
        'lbdisplay'=>'eshop_deliveries.name',
        'lbwhere'=>"visible = 'y'",
      'mandatory'=>{"type" => 'not_empty'}  
      }
      ,
      '50/accept_intracom_order_if_tva_check_is_disabled'=> 
      {
        'title'=>"Si vies indisponible: valider tva",
        'fieldtype'=>'checkbox',
		'tab'=>'panier',
        'checkedval' => 'y'
      } 
      ,
      '73/cart_default_id_country'=> 
      {
        'title'=>"Pays par défaut",
        'fieldtype'=>'listboxtable',
		'tab'=>'livraison',
        'lbtable'=>'countries',
        'lbkey'=>'id',
        'lbdisplay'=>'fr',
        'lbwhere'=>""
      }
      
,
      '74/soldes_debut1'=> 
      {
        'title'=>"Début des soldes 1",
        'fieldtype'=>'text',
		'tab'=>'panier',
		
		'data_type'=>'datetime',
      }
	  ,
      '75/soldes_fin1'=> 
      {
        'title'=>"Fin des soldes 1",
        'fieldtype'=>'text',
		'tab'=>'panier',
		
		'data_type'=>'datetime',
      }
	  ,
      '76/soldes_debut2'=> 
      {
        'title'=>"Début des soldes 2",
        'fieldtype'=>'text',
		'tab'=>'panier',
		
		'data_type'=>'datetime',
      }
	  ,
      '77/soldes_fin2'=> 
      {
        'title'=>"Fin des soldes 2",
        'fieldtype'=>'text',
		'tab'=>'panier',
		
		'data_type'=>'datetime',
      }
,
       
      # '76/create_ext_identities'=> 
      # {
        # 'title'=>"Membre pour pass. ext.",
        # 'fieldtype'=>'checkbox',
		# 'tab'=>'member',
        # 'checkedval' => 'y',
      # }
      
      ,
      '79/avert_stock'=> 
      {
        'title'=>"Avert. dép. stock",
        'fieldtype'=>'checkbox',
		'tab'=>'panier',
        'checkedval' => 'y'
      }
      
      ,
      '80/disable_detail_link'=> 
      {
        'title'=>"Pas de le lien produit",
        'fieldtype'=>'checkbox',
		'tab'=>'panier',
        'checkedval' => 'y'
      }
      # ,
      # '81/disable_edit_qty'=> 
      # {
        # 'title'=>"Pas de modif. de qté",
        # 'fieldtype'=>'checkbox',
		# 'tab'=>'panier',
        # 'checkedval' => 'y'
      # }
      
      ,
      '85/check_stock'=> 
      {
        'title'=>"Contrôler le stock",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y',
		'tab'=>'panier',
      }
      # ,
      # '91/cacher_breadcrumb'=> 
      # {
        # 'title'=>"Cacher le breadcrumb",
        # 'fieldtype'=>'checkbox',
        # 'checkedval' => 'y',
		# 'tab'=>'panier',
      # }
      ,
      '92/login_obligatoire'=> 
      {
        'title'=>"Identification obligatoire",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y',
				'tab'=>'member',
      }
      # ,
      # '93/cacher_lien_creer_un_compte'=> 
      # {
        # 'title'=>"Cacher le lien créer un compte",
        # 'fieldtype'=>'checkbox',
        # 'checkedval' => 'y',
				# 'tab'=>'member',
      # }
      ,
      '94/montant_pour_livraison_gratuite'=> 
      {
        'title'=>"Montant à atteindre pour la livraison gratuite + avertissement",
        'fieldtype'=>'text',
		'tab'=>'livraison',
      }
      ,
      # '95/plusieurs_profils_livraison'=> 
      # {
        # 'title'=>"Gérer plusieurs profils de livraison à la fois",
        # 'fieldtype'=>'checkbox',
        # 'checkedval' => 'y',
		# 'tab'=>'livraison',
      # } ,
      '96/weight_unit'=> 
      {
        'title'=>"Unité pour le poids",
        'fieldtype'=>'text',
		'tab'=>'livraison',
      }
      ,
      '98/social_connect_disabled'=> 
      {
        'title'=>"Désactiver la connexion avec les réseaux sociaux",
        'fieldtype'=>'checkbox',
		'tab'=>'member',

      }
	  # ,
      # '99/eshop_emails_cron_disabled'=> 
      # {
        # 'title'=>"Les emails de relances sont désactivés",
        # 'fieldtype'=>'checkbox',
		# 'tab'=>'member',
        # 'checkedval' => 'y',
      # }
	  # ,
      # 'a100/save_cart_disabled'=> 
      # {
        # 'title'=>"Désactiver la sauvegarde de panier",
        # 'fieldtype'=>'checkbox',
		# 'tab'=>'panier',
        # 'checkedval' => 'y',
      # }
      # ,
      # 'a101/share_cart_disabled'=> 
      # {
        # 'title'=>"Désactiver le partage de panier",
        # 'fieldtype'=>'checkbox',
		# 'tab'=>'panier',		
        # 'checkedval' => 'y',
      # }
      ,
      'a101/shop_disabled'=> 
      {
        'title'=>"Désactiver la boutique",
        'fieldtype'=>'checkbox',
		'tab'=>'iden',
        'checkedval' => 'y',
      }
      ,
      'a102/go_to_recap_if_one_method'=> 
      {
        'title'=>"Activer le processus de commande rapide si une seule méthode de livraison et de paiement",
        'fieldtype'=>'checkbox',
        'tab'=>'order_processus',
        'checkedval' => 'y',
      }
      ,
      'a103/frontend_cant_modify_billing'=> 
      {
        'title'=>"Les coordonnées de facturation ne sont pas modifiable dans le processus de commande",
        'fieldtype'=>'checkbox',
        'tab'=>'order_processus',
        'checkedval' => 'y',
      }
	  ,	 
	 'a104/frontend_cant_modify_email'=> 
      {
        'title'=>"L'adresse email n'est pas modifiable dans le processus de commande",
        'fieldtype'=>'checkbox',
        'tab'=>'order_processus',
        'checkedval' => 'y',
      }
	  ,
	 'a105/frontend_show_delivery_billing_form'=> 
      {
        'title'=>"Afficher le formulaire de coordonnées de livraison et de facturation en parallèle",
        'fieldtype'=>'checkbox',
        'tab'=>'order_processus',
        'checkedval' => 'y',
      }
	  ,
	 'a106/frontend_disabled_intraco'=> 
      {
        'title'=>"Masquer la case à cocher \"Facturation intracommunautaire\"",
        'fieldtype'=>'checkbox',
        'tab'=>'order_processus',
        'checkedval' => 'y',
      }
	  ,
	 'a107/frontend_disabled_facture'=> 
      {
        'title'=>"Masquer la case à cocher \"Je souhaite une facture\"",
        'fieldtype'=>'checkbox',
        'tab'=>'order_processus',
        'checkedval' => 'y',
      }
	  ,	  
      'a110/coupons_disabled'=> 
      {
        'title'=>"Désactiver les coupons",
        'fieldtype'=>'checkbox',
        'tab'=>'coupons',
        'checkedval' => 'y',
      }
      ,
      'a130/generate_bill_number_if_paid'=> 
      {
        'title'=>"Générer un numéro de facture dès que la commande est payée",
        'fieldtype'=>'checkbox',
        'tab'=>'facturation',
        'checkedval' => 'y',
      }
      ,
       'a135/generate_custom_inv_number'=> 
      {
        'title'=>"Fonction pour générer un numéro de facture sur-mesure",
        'tab'=>'facturation',
        'fieldtype'=>'text'
      }
      ,
      'a136/generate_custom_nc_number'=> 
      {
        'title'=>"Fonction pour générer un numéro de note de crédit sur-mesure",
        'tab'=>'facturation',
        'fieldtype'=>'text'
      }
      ,
      'a160/recap_hide_deliveries_address'=> 
      {
        'title'=>"Cacher les coordonnées de livraison dans le récap",
        'tab'=>'recap',
        'fieldtype'=>'checkbox',
        'checkedval' => 'y',
      }
      ,
      'a161/recap_hide_deliveries_methods'=> 
      {
        'title'=>"Cacher la méthode de livraison dans le récap",
        'tab'=>'recap',
        'fieldtype'=>'checkbox',
        'checkedval' => 'y',
      }
      ,
      'a165/recap_disable_edit_billing'=> 
      {
        'title'=>"Empêcher l'édition des coordonnées de facturation",
        'tab'=>'recap',
        'fieldtype'=>'checkbox',
        'checkedval' => 'y',
      }
      ,

      
);


%dm_display_fields = (
"01/Configuration de la boutique"=>"id_tpl_page1",
"02/Boutique désactivée"=>"shop_disabled"
		);

%dm_lnk_fields = (
		);

%dm_mapping_list = (
);

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
			up
			banners_link
			link_banner_category
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    
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
    my $id_banner =$_[1];
    
    my %new_config=(); 
    $new_config{id_role}='1';
    $new_config{varname}='eshop_url';
    $new_config{varvalue}='cgi-bin/eshop.pl?';
    sql_update_or_insert($dbh,"config",\%new_config,'varname','eshop_url');
    my %new_config=(); 
    $new_config{id_role}='1';
    $new_config{varname}='eshop_full_url';
    $new_config{varvalue}=$config{rewrite_protocol}."://".$config{default_url};
    sql_update_or_insert($dbh,"config",\%new_config,'varname','eshop_full_url');
}