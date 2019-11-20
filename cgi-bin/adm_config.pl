#!/usr/bin/perl -I../lib

# Includes

use DBI;

use Data::Dumper;
use def;
use tools;

use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset);
use Spreadsheet::ParseExcel;
use fwlib;
use HTML::Entities;

use dm;

use fwlayout;
use fwlib;


         # migc translations


use data;
use data_shop;

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}
$colg = get_quoted('colg') || $config{default_colg};


my $sw=get_quoted('sw') || 'home';
if($sw ne 'get_facture')
{
see();
}


my $selfcolg=$self.'&sw='.$sw.'&id='.get_quoted('id');       
my $colg_menu = get_colg_menu($dbh,$colg,$selfcolg);

$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="colg" value="$colg" />
EOH


  



&$sw();

#*******************************************************************************
# HOME 
#*******************************************************************************
sub home
{
    see();
    init();
    my $form=config_get_form();
    
         

   
  
    print wfw_app_layout($form,"Configuration","","$colg_menu ".$gen_bar,$spec_bar);
#       print "test6";
# exit;   
}


sub config_get_form
{
    my $suppl_old_libs="";
    my $show_old=get_quoted('show_old') || 'n';
    if($show_old eq 'y')
    {
        $suppl_old_libs=<<"EOH";
        
            <li><a href="#config_products">Ancien annuaire produits</a></li>
            <li><a href="#config_multimedia">Ancien annuaire multimédia</a></li>
            <li><a href="#config_datadir">Ancien annuaire</a></li>
            <li><a href="#config_shop">Boutique de l'ancien annuaire</a></li>
EOH
    }
    
    
    
    my $form=<<"EOH";
    
    <style>
    .ui-tabs-vertical 
    {

}
.ui-tabs-vertical .ui-tabs-nav {
    float: left;
    padding: 0.2em 0.1em 0.2em 0.2em;
    width: 190px;
}
.ui-tabs-vertical .ui-tabs-nav li {
    border-bottom-width: 1px !important;
    border-right-width: 0 !important;
    clear: left;
    margin: 0 -1px 0.2em 0;
    width: 100%;
}
.ui-tabs-vertical .ui-tabs-nav li a {
    display: block;
}
.ui-tabs-vertical .ui-tabs-nav li.ui-tabs-selected {
    border-right-width: 1px;
    padding-bottom: 0;
    padding-right: 0.1em;
}
.ui-tabs-vertical .ui-tabs-panel {
    float: left;
    padding: 1em;
} 


    .content {
        text-align:left;
      }
      
      fieldset
      {
          margin:10px;
          padding:10px;
          width:800px;
          text-align:right;
      }
      
      .config_boutique_input
      {
          width:400px;
      }
      .config_boutique_select
      {
          width:400px;
      }
      .config_boutique_checkbox
      {
          margin-right:390px;
      }
      #config_boutique b
      {
          float:left;
      }
      #config_boutique button
      {
          margin-left:780px;
      }
    </style>
    
   <form method="post" id="config_boutique" action="$htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/adm_config.pl?">
    $dm_cfg{hiddp}
    <input type="hidden" name="sw" value="home_db" />
    <input type="hidden" name="show_old" value="$show_old" />
    <a href="$htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/adm_config.pl?&show_old=y">Afficher les configurations des anciens annuaires</a><br /><br />
    
    <div id="config_tabs">
        
        <ul>
            <li><a href="#config_mig">MIG</a></li>
            <li><a href="#config_data">Annuaire générique</a></li>
            <li><a href="#config_data_shop">Boutique</a></li>
            <li><a href="#config_subscription">Inscription</a></li>
            <li><a href="#config_virement">Virement bancaire</a></li>
            <li><a href="#config_ogone">Ogone</a></li>
            <li><a href="#config_kiala">Kiala</a></li>
            <li><a href="#config_paypal">Paypal</a></li>
            <li><a href="#config_devis">Devis</a></li>
            <li><a href="#config_invoices">Facture</a></li>
            $suppl_old_libs  
        </ul>
    
    
    
    <script type="text/javascript">
    
                                 
 jQuery(document).ready(function()
 {
    jQuery("#config_tabs").tabs().addClass('ui-tabs-vertical ui-helper-clearfix');
    jQuery("#config_boutique :text").addClass('config_boutique_input');
    jQuery("#config_boutique select").addClass('config_boutique_select');
    jQuery("#config_boutique :checkbox").addClass('config_boutique_checkbox');
    
    jQuery(".config_boutique_select").each(function(i)
    {
       var me=jQuery(this);
       var parent=me.parent();
       if(me.val()==0 && parent.hasClass('template_container'))
       {
          me.css("background-color","orange");
         parent.css("background-color","orange").css("color","white");
       }
    });
    
 });
    </script>
    
    
EOH
    
    #get configs
    my %shop_cfg_line=select_table($dbh,"config","","varname='shop_cfg'");
    my %shop_cfg = eval("%shop_cfg = ($shop_cfg_line{varvalue});");
    
    my %data_shop_cfg_line=select_table($dbh,"config","","varname='data_shop_cfg'");
    my %data_shop_cfg = eval("%data_shop_cfg = ($data_shop_cfg_line{varvalue});");
    
    my %products_cfg_line=select_table($dbh,"config","","varname='products_cfg'");
    my %products_cfg = eval("%products_cfg = ($products_cfg_line{varvalue});");
    
    my %data_cfg_line=select_table($dbh,"config","","varname='data_cfg'");
    my %data_cfg = eval("%data_cfg = ($data_cfg_line{varvalue});");
    
    my %sub_cfg_line=select_table($dbh,"config","","varname='subscription_config'");
    my %sub_cfg = eval("%sub_cfg = ($sub_cfg_line{varvalue});");
    
    my $listbox_methode_livraison_defaut=get_listbox('methodes m, textcontents t','id','content','shop_default_delivery_method',$shop_cfg{default_delivery_method},'m.id as id,content','','m.type="delivery" and m.id_textid_name=t.id_textid and t.id_language='.$colg,'o',0);
    my $listbox_shop_default_country_iso=get_listbox('shop_delcost_countries','isocode','country_fr','shop_default_country_iso',$shop_cfg{default_country_iso},'','','','o');
  
    my $data_shop_listbox_methode_livraison_defaut=get_listbox('methodes m, textcontents t','id','content','data_shop_default_delivery_method',$data_shop_cfg{default_delivery_method},'m.id as id,content','','m.type="delivery" and m.id_textid_name=t.id_textid and t.id_language='.$colg,'o',0);
    my $data_shop_listbox_shop_default_country_iso=get_listbox('shop_delcost_countries','isocode','country_fr','data_shop_default_country_iso',$data_shop_cfg{default_country_iso},'','','','o');

 my @data_shop_tpl = (
      "change_status_email",
      "blank_page",
      "page",   
      "subscription_tpl",
      "analytics_postpayment",
      "cart_view_list",
      "cart_view_line",   
      "cart_lightbox",
      
      "cart_save_form",  
      
      "cart_saved_list",
      "cart_saved_line",  
      "cart_saved_detail",
      
      "product_discount_line",
      "delivery_discount_line",
      "total_discount_line",
      
      "add_coupon_form",
      "add_coupon_form_not_logged",
      "coupons_list",
      "coupons_line",
      
      "lost_password_tpl",
      "cart_export_form",         
      
      "dlv_meth_list",
      "dlv_meth_line",
      "dlv_no_valid_meths", 
      "dlv_kiala_choice",
      
      "bll_meth_list",
      "bll_meth_line",
      
      "cart_recap_list",
      "cart_recap_line",
      "recap_product_discount_line",
      "recap_delivery_discount_line",
      "recap_total_discount_line",
      
      "invoice_email",
      
      "payment_history_list",
       "payment_history_line",

      );
 
 my @data_shop_tpl_libelles = (
      "Email de notification des statuts",
      "Page blanche",
      "Page",   
      "Email d'inscription",
      "Google Analytics - Post paiement",
      "Panier: liste",
      "Panier: ligne",   
      "Panier: lightbox",
      
      "Formulaire de sauvegarde de panier",   
      
      "Panier sauvegardé: liste",
      "Panier sauvegardé: ligne",  
      "Panier sauvegardé: détail",  
      
      "Ligne de remise sur un produit",
      "Ligne de remise sur les frais de livraison",
      "Ligne de remise sur le total",
      
      "Formulaire d'ajout de coupon",
      "Formulaire d'ajout de coupon, membre pas loggé",
      "Liste des coupons",
      "Ligne des coupons",
      
      "Mot de passe perdu",
      "Formulaire d'export du panier",         
      
      "Méthodes de livraison: liste",
      "Méthodes de livraison: ligne",
      "Méthodes de livraison: pas de méthode valide", 
      "Ecran de choix point KIALA",
      
      "Méthodes de paiement: liste",
      "Méthodes de paiement: ligne",
      
      "Récapitulatif: liste",
      "Récapitulatif: ligne",
      "Récapitulatif: ligne réduction produit",
      "Récapitulatif: ligne réduction livraison",
      "Récapitulatif: ligne réduction total",
      
      "Email contenant la facture",
      
      "Historique des opérations: liste",
      "Historique des opérations: ligne",

      );     

   my @shop_tpl = (
      "blank_page",
      "page",   
      "subscription_tpl",
      
      "cart_view_list",
      "cart_view_line",   
      "cart_lightbox",
      
      "cart_save_form",  
      
      "cart_saved_list",
      "cart_saved_line",  
      "cart_saved_detail",
      
      "product_discount_line",
      "delivery_discount_line",
      "total_discount_line",
      
      "add_coupon_form",
      "coupons_list",
      "coupons_line",
      
      "lost_password_tpl",
      "cart_export_form",         
      
      "dlv_meth_list",
      "dlv_meth_line",
      "dlv_no_valid_meths", 
      "dlv_kiala_choice",
      
      "bll_meth_list",
      "bll_meth_line",
      
      "cart_recap_list",
      "cart_recap_line",
      "recap_product_discount_line",
      "recap_delivery_discount_line",
      "recap_total_discount_line",
      
      "html_recap_list",
      "html_recap_line",
      
      "payment_history_list",
       "payment_history_line",
       "facture_email_tpl"

      );
 
 my @shop_tpl_libelles = (
      "Page blanche",
      "Page",   
      "Email d'inscription",
      
      "Panier: liste",
      "Panier: ligne",   
      "Panier: lightbox",
      
      "Formulaire de sauvegarde de panier",   
      
      "Panier sauvegardé: liste",
      "Panier sauvegardé: ligne",  
      "Panier sauvegardé: détail",  
      
      "Ligne de remise sur un produit",
      "Ligne de remise sur les frais de livraison",
      "Ligne de remise sur le total",
      
      "Formulaire d'ajout de coupon",
      "Liste des coupons",
      "Ligne des coupons",
      
      "Mot de passe perdu",
      "Formulaire d'export du panier",         
      
      "Méthodes de livraison: liste",
      "Méthodes de livraison: ligne",
      "Méthodes de livraison: pas de méthode valide", 
      "Ecran de choix point KIALA",
      
      "Méthodes de paiement: liste",
      "Méthodes de paiement: ligne",
      
      "Récapitulatif: liste",
      "Récapitulatif: ligne",
      "Récapitulatif: ligne réduction produit",
      "Récapitulatif: ligne réduction livraison",
      "Récapitulatif: ligne réduction total",
      
      "Facture: liste (Déprécié)",
      "Facture: ligne (Déprécié)",
      
      "Historique des opérations: liste",
      "Historique des opérations: ligne",
       "Email contenant la facture"

      );
  my @products_tpl = (
      "page",
      "list",
      "line",
      "object",
      "object_detail",
      "path_tpl",
      "assoc_prod_tpl",   
      "assoc_prod_container_tpl",         
      "crit_table",
      "search_box",
      "stock_ok",
      "stock_low",
       "stock_ko",
       "products_filters_home",
       "categories_listing_object"
      );

 my @products_tpl_libelles = (
      "Page",
      "Liste",
      "Ligne",
      "Objet",
      "Détail de l'objet",
      "Path",
      "Produit associé",   
      "Conteneur d'un produit associé",         
      "Table de variantes de critères",
      "Search box",
      "Stock ok",
      "Stock bas",
      "Stock ko",
      "Home filtres",
      "Objet du listing catégories produits"
      ); 
      
#   "path_tpl",
#   "assoc_prod_tpl",   
#   "assoc_prod_container_tpl",         
#   "crit_table"
  
   my @data_tpl = 
  (
       'stock_ok',
       'stock_low',
       'stock_ko'
  );


#         "Path",
#       "Produit associé",   
#       "Conteneur d'un produit associé",         
#       "Table de variantes de critères"

 my @data_tpl_libelles = 
 (
      "Message si stock suffisant",
      "Message si stock faible",
      "Message si stock épuisé"
  ); 
       
      
  my @sub_tpl = (
      "loginform_tpl",
      "lostpwdform_tpl",
      "forms_tpl",
      "subform_tpl",
      "page_tpl",
      "email_free_gift_tpl"
      );

 my @sub_tpl_libelles = (
      "Formulaire d'identification",
      "Formulaire de mot de passe perdu",
      "Contenu: Identification/enregistrement/mot de passe",
      "Formulaire d'enregistrement", 
      "Page",
      "Email coupon gratuit"
      );        
      
      for($t=0;$t<$#shop_tpl+1;$t++)
      {
          ${'listbox_shop_'.$shop_tpl[$t]}=get_listbox('templates','id','name','shop_'.$shop_tpl[$t],$shop_cfg{$shop_tpl[$t]},'','','type="shop" or type="page" or type="menu"','n');
      }
      for($t=0;$t<$#data_shop_tpl+1;$t++)
      {
          ${'listbox_data_shop_'.$data_shop_tpl[$t]}=get_listbox('templates','id','name','data_shop_'.$data_shop_tpl[$t],$data_shop_cfg{$data_shop_tpl[$t]},'','','type="shop" or type="page" or type="menu"','n');
      }
      for($t=0;$t<$#products_tpl+1;$t++)
      {
          ${'listbox_products_'.$products_tpl[$t]}=get_listbox('templates','id','name','products_'.$products_tpl[$t],$products_cfg{$products_tpl[$t]},'','','type="shop" or type="page" or type="prod" or type="menu"','n');
      }
      for($t=0;$t<$#data_tpl+1;$t++)
      {
          ${'listbox_data_'.$data_tpl[$t]}=get_listbox('templates','id','name','data_'.$data_tpl[$t],$data_cfg{$data_tpl[$t]},'','','type="shop" or type="page" or type="data" or type="menu"','n');
      }
      for($t=0;$t<$#sub_tpl+1;$t++)
      {
          ${'listbox_sub_'.$sub_tpl[$t]}=get_listbox('templates','id','name','sub_'.$sub_tpl[$t],$sub_cfg{$sub_tpl[$t]},'','','type="shop" or type="page" or type="prod" or type="menu"','n');
      }
      

    my $cb_shop_no_prices=get_checkbox("shop_no_prices",$shop_cfg{no_prices});                
    my $cb_shop_shop_disabled=get_checkbox("shop_shop_disabled",$shop_cfg{shop_disabled});
    
    my $cb_data_shop_no_prices=get_checkbox("data_shop_no_prices",$data_shop_cfg{no_prices});                
    my $cb_data_shop_shop_disabled=get_checkbox("data_shop_shop_disabled",$data_shop_cfg{shop_disabled});
    
    
    my $cb_products_encode_prices_even_if_shop_is_not_linked=get_checkbox("products_encode_prices_even_if_shop_is_not_linked",$products_cfg{encode_prices_even_if_shop_is_not_linked},'y');
  
    my $listbox_langues=get_listbox('languages','id','name,display_name','default_colg',$config{default_colg},'','','','o');
    
    #MIG*********************************************************************
    my $cb_use_simple_stock=get_checkbox("shop_use_simple_stock",$shop_cfg{use_simple_stock});

    my $listbox_rewrite_404_id_page = get_listbox('pages p, textcontents txt','id','content','rewrite_404_id_page',$config{rewrite_404_id_page},'p.id,txt.content','',' p.id_textid_name = txt.id_textid AND txt.id_language="'.$config{default_colg}.'" ','n',0);
    my $listbox_rewrite_404_id_language = get_listbox('languages','id','name','rewrite_404_id_language',$config{rewrite_404_id_language},'','','','n');
    
    $form.=<<"EOH";
<div id="config_mig">
    <h1>Paramètres généraux</h1>
    <br />Langue d'interface par défaut: $listbox_langues
    <br />Nombre de pages max: <input type="text" name="nb_page_max" value="$config{nb_page_max}" /> 
    <br />Chemin racine par défaut: <input type="text" name="default_fm_root" value="$config{default_fm_root}" />
    <br />URL racine par défaut: <input type="text" name="default_fm_url" value="$config{default_fm_url}" />
    <br />Page URL 404: $listbox_rewrite_404_id_page
    <br />Langue URL 404: $listbox_rewrite_404_id_language
    </div>
EOH

  
    #DATA-**********************************************************************
    my $listbox_data_access_level_fields=get_listbox('roles','id','function','data_access_level_fields',$data_cfg{access_level_fields},'','','','n');
    my $listbox_data_access_level_crits=get_listbox('roles','id','function','data_access_level_crits',$data_cfg{access_level_crits},'','','','n');
    my $listbox_data_access_level_categories=get_listbox('roles','id','function','data_access_level_categories',$data_cfg{access_level_categories},'','','','n');
    my $listbox_data_access_level_stock=get_listbox('roles','id','function','data_access_level_stock',$data_cfg{access_level_stock},'','','','n');
    my $listbox_data_access_level_pictures=get_listbox('roles','id','function','data_access_level_pictures',$data_cfg{access_level_pictures},'','','','n');
    my $listbox_data_access_level_files=get_listbox('roles','id','function','data_access_level_files',$data_cfg{access_level_files},'','','','n');
    my $listbox_data_access_level_discounts=get_listbox('roles','id','function','data_access_level_discounts',$data_cfg{access_level_discounts},'','','','n');
    my $listbox_data_access_level_assoc=get_listbox('roles','id','function','data_access_level_assoc',$data_cfg{access_level_assoc},'','','','n');
    my $listbox_data_access_level_cat=get_listbox('roles','id','function','data_access_level_cat',$data_cfg{access_level_cat},'','','','n');
    
    my $listbox_data_families=get_listbox('data_families','id','name','data_default_family',$data_cfg{default_family},'','','','n');
    my $listbox_data_sf=get_listbox('data_search_forms','id','name','data_default_search_form',$data_cfg{default_search_form},'','','','n');
    
    my $cb_data_crits_show_crits=get_checkbox("data_crits_show_crits",$data_cfg{crits_show_crits});
    my $cb_data_crits_show_stock=get_checkbox("data_crits_show_stock",$data_cfg{crits_show_stock}); 
    my $cb_data_crits_show_weight=get_checkbox("data_crits_show_weight",$data_cfg{crits_show_weight});
    my $cb_data_crits_show_price=get_checkbox("data_crits_show_price",$data_cfg{crits_show_price});
    my $cb_data_crits_show_reference=get_checkbox("data_crits_show_reference",$data_cfg{crits_show_reference});
    
    my $cb_data_submenu_ordby_name=get_checkbox("data_submenu_ordby_name",$data_cfg{submenu_ordby_name});
    my $cb_data_write_all_tiles=get_checkbox("data_write_all_tiles",$data_cfg{write_all_tiles});
    my $cb_data_link_categories_father=get_checkbox("data_link_categories_father",$data_cfg{link_categories_father});
    
    my $cb_data_count_coumpute_sheets=get_checkbox("data_count_coumpute_sheets",$data_cfg{count_coumpute_sheets});
    my $cb_data_multiple_prices=get_checkbox("data_multiple_prices",$data_cfg{multiple_prices});
    my $cb_data_add_data_to_sitemap=get_checkbox("data_add_data_to_sitemap",$data_cfg{add_data_to_sitemap});
    
    my $cb_data_search_cache=get_checkbox("data_search_cache",$data_cfg{search_cache});
    
    my $cb_data_custom_promo=get_checkbox("data_custom_promo",$data_cfg{custom_promo});
    my $cb_data_custom_new=get_checkbox("data_custom_new",$data_cfg{custom_new});
    
    my $cb_data_tri_1=get_checkbox("data_tri_1",$data_cfg{tri_1});
    my $cb_data_tri_2=get_checkbox("data_tri_2",$data_cfg{tri_2});
    my $cb_data_tri_3=get_checkbox("data_tri_3",$data_cfg{tri_3});
    my $cb_data_tri_4=get_checkbox("data_tri_4",$data_cfg{tri_4});
    my $cb_data_tri_5=get_checkbox("data_tri_5",$data_cfg{tri_5});
    my $cb_data_tri_6=get_checkbox("data_tri_6",$data_cfg{tri_6});
    my $cb_data_tri_7=get_checkbox("data_tri_7",$data_cfg{tri_7});
    my $cb_data_tri_8=get_checkbox("data_tri_8",$data_cfg{tri_8});
    
        
$form.=<<"EOH";
    <div id="config_data">
    <h1>Annuaire générique</h1>
<br />       
<br /><b>Droit d'affichage des sections</b>
    <br />
    <br />Les champs de la fiche:       $listbox_data_access_level_fields
    <br />Les rubriques de classement:  $listbox_data_access_level_categories
    <br />Les variantes:                $listbox_data_access_level_crits
    <br />Le stock et les prix          $listbox_data_access_level_stock
    <br />La gestion des images         $listbox_data_access_level_pictures
    <br />La gestion des fichiers       $listbox_data_access_level_files
    <br />Les remises                   $listbox_data_access_level_discounts
    <br />Les produits associés         $listbox_data_access_level_assoc
    <br />Les catégories                $listbox_data_access_level_cat
    <br />
    <br />Afficher: 
                                          <br /><label>$cb_data_crits_show_crits colonne critères</label> 
                                          <br /><label>$cb_data_crits_show_stock colonne stock</label>  
                                          <br /><label>$cb_data_crits_show_weight colonne poids</label>  
                                          <br /><label>$cb_data_crits_show_price colonne prix</label> 
                                          <br /><label>$cb_data_crits_show_reference colonne référence</label>   
    <br />
    <br />URL racine:                   <input type="text" name="data_root_url" value="$data_cfg{root_url}" />
    <br />Classes du menu de navigation: <input type="text" name="data_submenu_custom_classes" value="$data_cfg{submenu_custom_classes}" />
    <br />Famille par défaut:           $listbox_data_families
    <br />Moteur de recherche par défaut: $listbox_data_sf

    <br />Nombre de fiches en nouveauté:    <input type="text" name="data_num_new" value="$data_cfg{num_new}" />
    <br />Nombre de numéros dans la pagination:    <input type="text" name="data_nombre_numeros" value="$data_cfg{nombre_numeros}" />
    <br />Extlink par défaut:    <input type="text" name="data_extlink" value="$data_cfg{extlink}" />
    <br /><label>$cb_data_search_cache (NE PAS ENCORE UTILISER:) Générer le cache MYSQL (requis pour précédent, suivant)</label>
    <br /><label>$cb_data_submenu_ordby_name Moteur de recherche trié par ordre alphabétique</label>
    <br /><label>$cb_data_write_all_tiles Générer systématiquement toutes les tuiles objets et détails à chaque chargement</label>
    <br /><label>$cb_data_link_categories_father Lier automatiquement une fiche aux rubriques parentes également</label>
    <br /><label>$cb_data_count_coumpute_sheets Calculer le nombre de résultats d'avance pour chaque lien</label>
    <br /><label>$cb_data_multiple_prices Gérer plusieurs prix selon les groupes</label>
    <br /><label>$cb_data_add_data_to_sitemap Inclure le catalogue dans le sitemap (si URL rewriting est actif)</label>
    <br /><label>$cb_data_custom_promo Gérer les macarons PROMO manuellement</label>
    <br /><label>$cb_data_custom_new Gérer les macarons NEW manuellement</label>
    <br />
    <br /><label>$cb_data_tri_1 Du + récent au - récent</label>
    <br /><label>$cb_data_tri_2 Du - récent au + récent</label>
    <br /><label>$cb_data_tri_3 Du - cher au + cher</label>
    <br /><label>$cb_data_tri_4 Du + cher au - cher</label>
    <br /><label>$cb_data_tri_5 De A à Z</label>
    <br /><label>$cb_data_tri_6 De Z à A</label>
    <br /><label>$cb_data_tri_7 Les plus populaires</label>
    <br /><label>$cb_data_tri_8 Les meilleures ventes </label>
    <br />
    <br /><b>Templates</b>
    <br />
EOH
#       <br />Nombre de fiches par page:    <input type="text" name="data_nr" value="$data_cfg{nr}" /> 
   for($t=0;$t<$#data_tpl+1;$t++)
   {
      $form.=<<"EOH";
      <div class="template_container">$data_tpl_libelles[$t] ${'listbox_data_'.$data_tpl[$t]}</div>
EOH
   }
$form.=<<"EOH";
   <br />
   </div>
EOH
    
    
    
    #(new)SHOP***********************************************************************
    
#     my $cb_data_shop_disable_discount_line_if_discount_delivery=get_checkbox("data_shop_disable_discount_line_if_discount_delivery",$data_shop_cfg{disable_discount_line_if_discount_delivery});
#     my $cb_data_shop_disable_discount_line_if_discount_total=get_checkbox("data_shop_disable_discount_line_if_discount_total",$data_shop_cfg{disable_discount_line_if_discount_total});
    my $cb_data_shop_order_even_if_qty_is_zero=get_checkbox("data_shop_order_even_if_qty_is_zero",$data_shop_cfg{order_even_if_qty_is_zero});
    my $cb_data_shop_allow_cart_without_login=get_checkbox("data_shop_allow_cart_without_login",$data_shop_cfg{allow_cart_without_login});
    

    
    $form.=<<"EOH";
    <div id="config_data_shop">
    <h1>Boutique</h1>
    <h2>Liée au nouvel annuaire</h2>
    <br /><label>Désactiver la boutique (redirige vers la homepage): $cb_data_shop_shop_disabled</label>
    
    <br />
    <!--
    <br /><label>Pouvoir encoder les prix malgrés tout: $cb_products_encode_prices_even_if_shop_is_not_linked</label>
    <br /><label>Désactiver la remise ligne si remise sur la livraison: $cb_data_shop_disable_discount_line_if_discount_delivery</label>
    <br /><label>Désactiver la remise ligne si remise sur le total: $cb_data_shop_disable_discount_line_if_discount_total</label>
    -->
    
    
    <br /><label>Pouvoir accéder au panier sans être connecté: $cb_data_shop_allow_cart_without_login</label>
    
    
    <br /><label>Pouvoir commander un produit dont le stock est 0: $cb_data_shop_order_even_if_qty_is_zero</label>
    
    <br />Méthode de livraison par défaut: $data_shop_listbox_methode_livraison_defaut
    <br />Pays de livraison par défaut: $data_shop_listbox_shop_default_country_iso
    <br />
    <br />Nom pour l'email d'expédition:  <input type="text" name="data_shop_from_name" value="$data_shop_cfg{from_name}" />
    <br />Adresse email d'expédition:  <input type="text" name="data_shop_from" value="$data_shop_cfg{from}" />
    <br />URL home:  <input type="text" name="data_shop_home_url" value="$data_shop_cfg{home_url}" />
    <br />URL boutique:  <input type="text" name="data_shop_shop_url" value="$data_shop_cfg{shop_url}" />
    <br />Extlink par défaut:    <input type="text" name="data_shop_extlink" value="$data_shop_cfg{extlink}" />
    <br />
    <br />Afficher cordonneés de contact si pas de méthode de livraison dispo:  <input type="text" name="data_shop_coord_no_delivery_method_available" value="$data_shop_cfg{coord_no_delivery_method_available}" />
    <br /><label>Les prix sont facultatifs pour accéder au détail: $cb_data_shop_no_prices</label>
     <br />
     <br /><b>Templates</b><br />
EOH

   for($t=0;$t<$#data_shop_tpl+1;$t++)
   {
     
    $form.=<<"EOH";
    <div class="template_container">$data_shop_tpl_libelles[$t] ${'listbox_data_shop_'.$data_shop_tpl[$t]}</div>
EOH
   } 
      
   $form.=<<"EOH";
   <br />
    </div>
EOH
    
    if($show_old eq 'y')
    {
    
    #PRODUCTS*******************************************************************
    
    my $cb_products_products_always_in_a_category=get_checkbox("products_products_always_in_a_category",$products_cfg{products_always_in_a_category});
    my $cb_products_products_use_lnk_with_datadir=get_checkbox("products_use_lnk_with_datadir",$products_cfg{use_lnk_with_datadir});
    my $cb_products_filter=get_checkbox("products_filter",$products_cfg{filter});
    my $cb_products_filter_generer_vides=get_checkbox("products_filter_generer_vides",$products_cfg{filter_generer_vides});
    
    my $cb_products_default_viewer=get_checkbox("products_default_viewer",$products_cfg{default_viewer},'html');
    my $cb_products_listing_viewer=get_checkbox("products_listing_viewer",$products_cfg{listing_viewer},'html');
    my $cb_products_detail_viewer=get_checkbox("products_detail_viewer",$products_cfg{detail_viewer},'html');
    
    my $cb_products_show_if_stock_positive=get_checkbox("products_show_if_stock_positive",$products_cfg{show_if_stock_positive});
    my $cb_products_order_qty_avaiable=get_checkbox("products_order_qty_avaiable",$products_cfg{order_qty_avaiable});
    my $cb_products_order_even_if_qty_is_zero=get_checkbox("products_order_even_if_qty_is_zero",$products_cfg{order_even_if_qty_is_zero});
    
    my $listbox_products_acl_tags_level=get_listbox('roles','id','function','products_acl_tags_level',$products_cfg{acl_tags_level},'','','','n');
    my $listbox_products_acl_stock_level=get_listbox('roles','id','function','products_acl_stock_level',$products_cfg{acl_stock_level},'','','','n');
    my $listbox_products_acl_discount_level=get_listbox('roles','id','function','products_acl_discount_level',$products_cfg{acl_discount_level},'','','','n');
    my $listbox_products_acl_assoc_level=get_listbox('roles','id','function','products_acl_assoc_level',$products_cfg{acl_assoc_level},'','','','n');
    my $listbox_products_acl_fields_level=get_listbox('roles','id','function','products_acl_fields_level',$products_cfg{acl_fields_level},'','','','n');
    my $listbox_products_acl_crits_level=get_listbox('roles','id','function','products_acl_crits_level',$products_cfg{acl_crits_level},'','','','n');
    my $listbox_products_acl_categories_level=get_listbox('roles','id','function','products_acl_categories_level',$products_cfg{acl_categories_level},'','','','n');
    my $listbox_products_acl_stockprices_level=get_listbox('roles','id','function','products_acl_stockprices_level',$products_cfg{acl_stockprices_level},'','','','n');
    
  
    
$form.=<<"EOH";
    <div id="config_products">
    <h1>Produits</h1>
     <br /><label>Les produits sont toujours dans une catégorie: $cb_products_products_always_in_a_category</label>
     <br /><label>Lier le catalogue de produit à l'annuaire: $cb_products_products_use_lnk_with_datadir</label>
     <br /><label>Activer les filtres: $cb_products_filter</label>
     <br /><label>Générer les catégories vides: $cb_products_filter_generer_vides</label>
     <br />
     <br /><label>Rendu HTML général: $cb_products_default_viewer</label>
     <br /><label>Rendu HTML du listing du catalogue produit: $cb_products_listing_viewer</label>
     <br /><label>Rendu HTML du détail du catalogue produit: $cb_products_detail_viewer</label>
     <br />     
     <br /><label>Afficher le produit seulement si le stock est positif: $cb_products_show_if_stock_positive</label>
     <br /><label>Ramener la quantité commandée à  la quantité disponible: $cb_products_order_qty_avaiable</label>
     <br /><label>Pouvoir mettre le produit dans le panier même si quantité est nulle: $cb_products_order_even_if_qty_is_zero</label>
     <br />
     <br /><b>Miniatures générées:</b>
    <br />Largeur des miniatures mini: <input type="text" name="default_mini_width" value="$config{default_mini_width}" />
    <br />Hauteur des miniatures mini: <input type="text" name="default_mini_height" value="$config{default_mini_height}" />
    <br />Largeur des miniatures small: <input type="text" name="default_small_width" value="$config{default_small_width}" />
    <br />Hauteur des miniatures small: <input type="text" name="default_small_height" value="$config{default_small_height}" />
    <br />Largeur des miniatures medium: <input type="text" name="default_medium_width" value="$config{default_medium_width}" />
    <br />Hauteur des miniatures medium: <input type="text" name="default_medium_height" value="$config{default_medium_height}" />
    <br />                
    <br />EXTLINK: <input type="text" name="products_extlink" value="$products_cfg{extlink}" />
    <br />Nb de produits par page: <input type="text" name="products_nb_results_per_page" value="$products_cfg{nb_results_per_page}" />
     <br />Nb de numéros max pour la pagination: <input type="text" name="products_pagination_max_numbers" value="$products_cfg{pagination_max_numbers}" />
    <br />Classe sur les photos: <input type="text" name="products_pic_class" value="$products_cfg{pic_class}" />
    <br />Chemin d'upload: <input type="text" name="products_upload_path" value="$products_cfg{upload_path}" />
    <br />Dossier d'upload: <input type="text" name="products_upload_dir" value="$products_cfg{upload_dir}" />
    <br />Moteur de recherche: <input type="text" name="products_search_module" value="$products_cfg{search_module}" />
    <br />
    <br />Champ META pour le titre: <input type="text" name="products_meta_title_field" value="$products_cfg{meta_title_field}" />
    <br />Champ META pour la description: <input type="text" name="products_meta_descr_field" value="$products_cfg{meta_descr_field}" />
    <br />Page META par défaut: <input type="text" name="products_meta_products_default_page" value="$products_cfg{meta_products_default_page}" />
    <br />
    <br />Ordre des categories: <input type="text" name="products_categories_ordby" value="$products_cfg{categories_ordby}" />
    <br />
    <br />
    <br /><b>Droit d'affichage des sections</b>
    <br />
    <br />Les tags:                             $listbox_products_acl_tags_level
    <br />Les remises et suppléments:           $listbox_products_acl_discount_level
    <br />Les produits associés:                $listbox_products_acl_assoc_level
    <br />Les champs de la fiche produit:       $listbox_products_acl_fields_level
    <br />Les critères/variantes:               $listbox_products_acl_crits_level
    <br />Les catégories:                       $listbox_products_acl_categories_level    
    <br />Les prix,poids,références et stock:   $listbox_products_acl_stockprices_level
    <br />
    <br /><b>Templates</b>
EOH
   
   for($t=0;$t<$#products_tpl+1;$t++)
   {
     
    $form.=<<"EOH";
    <div class="template_container">$products_tpl_libelles[$t] ${'listbox_products_'.$products_tpl[$t]}</div>
EOH
   } 
      
   $form.=<<"EOH";
   <br />
    </div>
EOH
    
   
    
    #(old)SHOP***********************************************************************
    
    my $cb_shop_disable_discount_line_if_discount_delivery=get_checkbox("shop_disable_discount_line_if_discount_delivery",$shop_cfg{disable_discount_line_if_discount_delivery});
    my $cb_shop_disable_discount_line_if_discount_total=get_checkbox("shop_disable_discount_line_if_discount_total",$shop_cfg{disable_discount_line_if_discount_total});  
    
    $form.=<<"EOH";
    <div id="config_shop">
    <h1>Boutique</h1>
    <br /><label>Désactiver la boutique (redirige vers la homepage): $cb_shop_shop_disabled</label>
    <br /><label>Pouvoir encoder les prix malgrés tout: $cb_products_encode_prices_even_if_shop_is_not_linked</label>
    <br />
    <br /><label>Désactiver la remise ligne si remise sur la livraison: $cb_shop_disable_discount_line_if_discount_delivery</label>
    <br /><label>Désactiver la remise ligne si remise sur le total: $cb_shop_disable_discount_line_if_discount_total</label>
    
    
    <br />Méthode de livraison par défaut: $listbox_methode_livraison_defaut
    <br />Pays de livraison par défaut: $listbox_shop_default_country_iso
    <br />
    <br />Nom pour l'email d'expédition:  <input type="text" name="shop_from_name" value="$shop_cfg{from_name}" />
    <br />Adresse email d'expédition:  <input type="text" name="shop_from" value="$shop_cfg{from}" />
    <br />URL home:  <input type="text" name="shop_home_url" value="$shop_cfg{home_url}" />
    <br />URL boutique:  <input type="text" name="shop_shop_url" value="$shop_cfg{shop_url}" />
    
    <br />
    <br />Afficher cordonneés de contact si pas de méthode de livraison dispo:  <input type="text" name="shop_coord_no_delivery_method_available" value="$shop_cfg{coord_no_delivery_method_available}" />
    <br /><label>Les prix sont facultatifs pour accéder au détail: $cb_shop_no_prices</label>
     <br />
     <br /><b>Templates</b>
EOH

   for($t=0;$t<$#shop_tpl+1;$t++)
   {
     
    $form.=<<"EOH";
    <div class="template_container">$shop_tpl_libelles[$t] ${'listbox_shop_'.$shop_tpl[$t]}</div>
EOH
   } 
      
   $form.=<<"EOH";
   <br />
    </div>
EOH
     }
     
     
     
    #SUBSCRIPTION***********************************************************************
    my $listbox_sub_link_to_mailing_group=get_listbox('mailing_groups','id','title','sub_link_to_mailing_group',$sub_cfg{link_to_mailing_group},'','','','0');
    my $cb_sub_free_gift=get_checkbox("sub_free_gift",$sub_cfg{free_gift},'y');
    $form.=<<"EOH";
    <div id="config_subscription">
    <h1>Inscription</h1>
    <br /><label>Générer et envoyer un chèque cadeau à  l'inscription: $cb_sub_free_gift</label>
    <br />Montant du chèque offert:  <input type="text" name="sub_free_gift_value" value="$sub_cfg{free_gift_value}" />
    <br />
    <br />Nom de l'expéditeur email d'inscription:  <input type="text" name="sub_from_name" value="$sub_cfg{from_name}" />
    <br />Email de l'expéditeur email d'inscription:  <input type="text" name="sub_subscription_from" value="$sub_cfg{subscription_from}" />
    <br />Groupe de membres newsletter lié par défaut:  $listbox_sub_link_to_mailing_group                                                      
    
     <br />
     <br /><b>Templates</b>
EOH

   for($t=0;$t<$#sub_tpl+1;$t++)
   {
     
    $form.=<<"EOH";
    <div class="template_container">$sub_tpl_libelles[$t] ${'listbox_sub_'.$sub_tpl[$t]}</div>
EOH
   } 
      
   $form.=<<"EOH";
   <br />
    </div>
EOH
    
    
    #VIREMENT BANCAIRE**********************************************************
    my %methode=%{get_param_name('virement')};
    my %cfg = eval("%cfg = ($methode{params});");
    
    my $listbox_virement_tpl=get_listbox('templates','id','name','virement_tpl',$cfg{tpl},'','','type="shop"','o');
    my $cb_virement_visible=get_checkbox("virement_visible",$methode{visible});
    my $cb_virement_stock_linked=get_checkbox("virement_stock_linked",$cfg{stock_linked});
    $form.=<<"EOH";
    <div id="config_virement">
    <h1>Virement bancaire</h1>
    <br /><label>Activé: $cb_virement_visible </label>
    <br /><label>Diminue le stock si commande: $cb_virement_stock_linked</label> 
    <br />Template du message de fin de commande: $listbox_virement_tpl
    <br />
    <br />Numéro de compte: <input type="text" name="virement_compte" value="$cfg{compte}" />
    <br />Nom: <input type="text" name="virement_nom" value="$cfg{nom}" />
    <br />Adresse: <input type="text" name="virement_adresse" value="$cfg{adresse}" />
    <br />Ville: <input type="text" name="virement_ville" value="$cfg{ville}" />
    <br />Téléphone: <input type="text" name="virement_telephone" value="$cfg{telephone}" />
    <br />BIC: de compte: <input type="text" name="virement_bic" value="$cfg{bic}" />
    <br />IBAN: <input type="text" name="virement_iban" value="$cfg{iban}" />
    <br />
    </div>
EOH
          
    #OGONE**********************************************************************
    my %methode=%{get_param_name('ogone')};
    my %cfg = eval("%cfg = ($methode{params});");
    
    my $listbox_ogone_tpl=get_listbox('templates','id','name','ogone_tpl',$cfg{tpl},'','','type="shop"','o');
    my $cb_ogone_visible=get_checkbox("ogone_visible",$methode{visible});
    if($cfg{version} eq "")
    {
      $cfg{version}=2;
    }
    if($cfg{language} eq "")
    {
      $cfg{language}="fr_fr";
    }
    my $cb_ogone_stock_linked=get_checkbox("ogone_stock_linked",$cfg{stock_linked});
    $form.=<<"EOH";
<div id="config_ogone">
    <h1>Ogone</h1>
    <br /><label>Activé: $cb_ogone_visible </label>
    <br /><label>Diminue le stock si commande: $cb_ogone_stock_linked </label>
    <br />Template du message de fin de commande: $listbox_ogone_tpl
    <br />
    <br />identifiant du site (si redirection vers payment.bugiweb.com): <input type="text" name="ogone_ogone_id_site" value="$cfg{ogone_id_site}" />
    <br />PSPID: <input type="text" name="ogone_ogone_pspid" value="$cfg{ogone_pspid}" />
    <br />URL Template Ogone: <input type="text" name="ogone_template_ogone" value="$cfg{template_ogone}" />
    <br />Version: <input type="text" name="ogone_version" value="$cfg{version}" />
    <br />Langue: <input type="text" name="ogone_language" value="$cfg{language}" />
    <br />Mode: <input type="text" name="ogone_ogone_prod_status" value="$cfg{ogone_prod_status}" />
    <br />Code SHA1 en entrée: <input type="text" name="ogone_ogone_sha1in" value="$cfg{ogone_sha1in}" />
    <br />Code SHA1 en sortie: <input type="text" name="ogone_ogone_sha1out" value="$cfg{ogone_sha1out}" />    
    <br />Préfixe des commandes: <input type="text" name="ogone_prefixe_id_order" value="$cfg{prefixe_id_order}" />
    <br />Marques: <input type="text" name="ogone_brands" value="$cfg{brands}" />
    
    <br />
    </div>
EOH

    #KIALA**********************************************************************
    my %methode=%{get_param_name('kiala')};
    my %cfg = eval("%cfg = ($methode{params});");
    my $cb_kiala_visible=get_checkbox("kiala_visible",$methode{visible});
    
    $form.=<<"EOH";
<div id="config_kiala">
    <h1>Kiala</h1>
    <br /><label>Activé: $cb_kiala_visible </label>
    <br />DSPID: <input type="text" name="kiala_dspid" value="$cfg{dspid}" />
    <br />Cout fixe: <input type="text" name="kiala_fixcost" value="$cfg{fixcost}" />
    <br />Texte du bouton: <input type="text" name="kiala_button_txt" value="$cfg{button_txt}" />
    <br />Largeur: <input type="text" name="kiala_width" value="$cfg{width}" />
    <br />Hauteur: <input type="text" name="kiala_height" value="$cfg{height}" />
    
    <br />
    </div>
EOH


    #PAYPAL*********************************************************************
    my %methode=%{get_param_name('paypal')};
    my %cfg = eval("%cfg = ($methode{params});");
    
    my $listbox_paypal_tpl=get_listbox('templates','id','name','paypal_tpl',$cfg{tpl},'','','type="shop"','o');
    my $cb_paypal_visible=get_checkbox("paypal_visible",$methode{visible});
    my $cb_paypal_stock_linked=get_checkbox("paypal_stock_linked",$cfg{stock_linked});
    $form.=<<"EOH";
<div id="config_paypal">
    <h1>Paypal</h1>
    <br /><label>Activé: $cb_paypal_visible </label>
    <br /><label>Diminue le stock si commande: $cb_paypal_stock_linked </label>
    <br />Version: <input type="text" name="paypal_version" value="$cfg{version}" />
    <br />Template du message de fin de commande: $listbox_paypal_tpl
    <br />
    <br />PAYPAL ID: <input type="text" name="paypal_paypal_id" value="$cfg{paypal_id}" />
   <br />
    </div>
EOH

    
    




              
    #QUOTATION
    my %quotation_cfg_line=select_table($dbh,"config","","varname='quotation_cfg'");
    my %quotation_cfg = eval("%quotation_cfg = ($quotation_cfg_line{varvalue});");


my @quotation_tpl = (
      "page",
      "container",
      "etape1",
      "etape2",
      "etape3",
      "etape4",
      "etape5",   
      "etape6",         
      "etape7",
      "etape8",
      "etape9",
      "etape10",
      "etape11"
      );

 my @quotation_tpl_libelles = (
      "Page",
      "Coteneur commun",
      "Etape1",
      "Etape2",
      "Etape3",
      "Etape4",
      "Etape5",   
      "Etape6",         
      "Etape7",
      "Etape8",
      "Etape9",
      "Etape10",
      "Etape11"
      );             
      
      for($t=0;$t<$#quotation_tpl+1;$t++)
      {
          ${'listbox_quotation_'.$quotation_tpl[$t]}=get_listbox('templates','id','name','quotation_'.$quotation_tpl[$t],$quotation_cfg{$quotation_tpl[$t]},'','','type="shop" or type="page" or type="menu"','n');
      }
    
    my $cb_un_seul_devis=get_checkbox("quotation_un_seul_devis",$quotation_cfg{un_seul_devis});
    
    #SHOP***********************************************************************
    $form.=<<"EOH";
    <div id="config_devis">   
    
    <h1>Devis</h1>
    <br />Upload path: <input type="text" name="quotation_quotation_upload_path" value="$quotation_cfg{quotation_upload_path}" />
    <br />Adresse from: <input type="text" name="quotation_from" value="$quotation_cfg{from}" />
    <br />Adresse debug: <input type="text" name="quotation_debug_to" value="$quotation_cfg{debug_to}" />
    <br />Tracking source (si centralisation): <input type="text" name="quotation_tracking" value="$quotation_cfg{tracking}" />
    <br />Fiche produit liée au devis:  <input type="text" name="quotation_product_sheet" value="$quotation_cfg{product_sheet}" />
    <br />Fonction de calcul du devis:  <input type="text" name="quotation_calcule_devis_func" value="$quotation_cfg{calcule_devis_func}" />
    <br />URL du dossier contenant les PDFs:  <input type="text" name="quotation_url_pdf" value="$quotation_cfg{url_pdf}" />
    <br />ID du bloc contenant le texte avant le lien:  <input type="text" name="quotation_id_bloc1" value="$quotation_cfg{id_bloc1}" />
    <br />ID du bloc contenant le texte après le lien:  <input type="text" name="quotation_id_bloc2" value="$quotation_cfg{id_bloc2}" />
    <br />Objet de l'email du devis:  <input type="text" name="quotation_objet_email" value="$quotation_cfg{objet_email}" />
    <br />Une seule ligne de devis : $cb_un_seul_devis           
    <br />Taille de la police:  <input type="text" name="quotation_font_size" value="$quotation_cfg{font_size}" />
    <br />Interligne:  <input type="text" name="quotation_interligne" value="$quotation_cfg{interligne}" />
    <br />
    <br /><b>Facturation</b>
    <br />Nom: <input type="text" name="quotation_facture_name" value="$quotation_cfg{facture_name}" />
    <br />Entreprise: <input type="text" name="quotation_facture_company" value="$quotation_cfg{facture_company}" />
    <br />Rue: <input type="text" name="quotation_facture_street" value="$quotation_cfg{facture_street}" />
    <br />CP: <input type="text" name="quotation_facture_zip" value="$quotation_cfg{facture_zip}" />
    <br />Ville: <input type="text" name="quotation_facture_city" value="$quotation_cfg{facture_city}" />
    <br />Province: <input type="text" name="quotation_facture_state" value="$quotation_cfg{facture_state}" />    
    <br />Pays: <input type="text" name="quotation_facture_country" value="$quotation_cfg{facture_country}" />
    <br />Téléphone: <input type="text" name="quotation_facture_tel" value="$quotation_cfg{facture_tel}" />
    <br />Fax: <input type="text" name="quotation_facture_fax" value="$quotation_cfg{facture_fax}" />
    <br />Email: <input type="text" name="quotation_facture_email" value="$quotation_cfg{facture_email}" />
    <br />Site web: <input type="text" name="quotation_facture_web" value="$quotation_cfg{facture_web}" /> 
    <br />Compte: <input type="text" name="quotation_facture_cbc" value="$quotation_cfg{facture_cbc}" />
    <br />CCP: <input type="text" name="quotation_facture_ccp" value="$quotation_cfg{facture_ccp}" />
    <br />BIC: <input type="text" name="quotation_facture_bic" value="$quotation_cfg{facture_bic}" />
    <br />IBAN: <input type="text" name="quotation_facture_iban" value="$quotation_cfg{facture_iban}" />
    <br /> 
    
     <br /><b>Templates</b>
EOH

   for($t=0;$t<$#quotation_tpl+1;$t++)
   {
     
    $form.=<<"EOH";
    <div class="template_container">$quotation_tpl_libelles[$t] ${'listbox_quotation_'.$quotation_tpl[$t]}</div>
EOH
   } 
      
   $form.=<<"EOH";
   <br />
    </div>
EOH



    
    
    my $listbox_gifts_pm=get_listbox('methodes m, textcontents t','id','content','gifts_pm',$gifts_cfg{pm},'m.id as id,content','','m.type="billing" and m.id_textid_name=t.id_textid and t.id_language=1','o',0);
    $form.=<<"EOH";
    <div id="config_invoices">   
    
    <h1>Factures</h1>
   
    <br />Dénomination: <input type="text" name="data_shop_inv_name" value="$data_shop_cfg{inv_name}" />
    <br />
    <br />Ligne adresse 1: <input type="text" name="data_shop_inv_adr1" value="$data_shop_cfg{inv_adr1}" />
    <br />Ligne adresse 2: <input type="text" name="data_shop_inv_adr2" value="$data_shop_cfg{inv_adr2}" />
    <br />Ligne adresse 3: <input type="text" name="data_shop_inv_adr3" value="$data_shop_cfg{inv_adr3}" />
    <br />Tél: <input type="text" name="data_shop_inv_tel" value="$data_shop_cfg{inv_tel}" />
    <br />Fax: <input type="text" name="data_shop_inv_fax" value="$data_shop_cfg{inv_fax}" />
    <br /> 
    <br />Email: <input type="text" name="data_shop_inv_email" value="$data_shop_cfg{inv_email}" />
    <br />Web: <input type="text" name="data_shop_inv_web" value="$data_shop_cfg{inv_web}" />
    <br />TVA: <input type="text" name="data_shop_inv_tva" value="$data_shop_cfg{inv_tva}" />
    <br />Banque: <input type="text" name="data_shop_inv_banque" value="$data_shop_cfg{inv_banque}" />
    <br />IBAN: <input type="text" name="data_shop_inv_iban" value="$data_shop_cfg{inv_iban}" />
    <br />BIC: <input type="text" name="data_shop_inv_bic" value="$data_shop_cfg{inv_bic}" />
    <br />       

   <br />
    </div>
EOH

if($show_old eq 'y')
    {

 #MULTIMEDIA
    my %multimedia_cfg_line=select_table($dbh,"config","","varname='multimedia_cfg'");
    my %multimedia_cfg = eval("%multimedia_cfg = ($multimedia_cfg_line{varvalue});");
#       see();
#     see(\%multimedia_cfg);
      my @multimedia_tpl = (
            "list",
            "object",
            "object_detail_simple_pic",
            "object_detail_simple_video",
            "object_detail_simple_audio",
            "page",
            "search_box",
            "path_tpl",
            "list_elements",
            "list_elements_object",
            "list_elements_object_detail_simple_video",
            "list_elements_object_detail_simple_pic"
            );
      
       my @multimedia_tpl_libelles = (
            "list",
            "object",
            "object_detail_simple_pic",
            "object_detail_simple_video",
            "object_detail_simple_audio",
            "page",
            "search_box",
            "path_tpl",
            "list_elements",
            "list_elements_object",
            "list_elements_object_detail_simple_video",
            "list_elements_object_detail_simple_pic"
            );             
      
      for($t=0;$t<$#multimedia_tpl+1;$t++)
      {
#          print "<br />$multimedia_tpl[$t] $multimedia_cfg{$multimedia_tpl[$t]}";
          ${'listbox_multimedia_'.$multimedia_tpl[$t]}=get_listbox('templates','id','name','multimedia_'.$multimedia_tpl[$t],$multimedia_cfg{$multimedia_tpl[$t]},'','','type="multimedia" or type="shop" or type="datadir" or type="page" or type="menu"','n');
      }


  
      
      
      
    my $cb_multimedia_simple_pic_enabled=get_checkbox("multimedia_simple_pic_enabled",$multimedia_cfg{simple_pic_enabled});
    my $cb_multimedia_simple_audio_enabled=get_checkbox("multimedia_simple_audio_enabled",$multimedia_cfg{simple_audio_enabled});
    my $cb_multimedia_simple_video_enabled=get_checkbox("multimedia_simple_video_enabled",$multimedia_cfg{simple_video_enabled});
    my $cb_multimedia_list_pic_enabled=get_checkbox("multimedia_list_pic_enabled",$multimedia_cfg{list_pic_enabled});
    my $cb_multimedia_list_audio_enabled=get_checkbox("multimedia_list_audio_enabled",$multimedia_cfg{list_audio_enabled});
    my $cb_multimedia_list_video_enabled=get_checkbox("multimedia_list_video_enabled",$multimedia_cfg{list_video_enabled});
    my $cb_multimedia_medium_link_instead_of_detail=get_checkbox("multimedia_medium_link_instead_of_detail",$multimedia_cfg{medium_link_instead_of_detail});
    
    my $cb_multimedia_list_mix_enabled=get_checkbox("multimedia_list_mix_enabled",$multimedia_cfg{list_mix_enabled});
    
    my $cb_multimedia_multimedia_show_type=get_checkbox("multimedia_multimedia_show_type",$multimedia_cfg{multimedia_show_type});
    my $cb_multimedia_multimedia_element_show_type=get_checkbox("multimedia_multimedia_element_show_type",$multimedia_cfg{multimedia_element_show_type});
    my $cb_multimedia_multimedia_show_date_creation=get_checkbox("multimedia_multimedia_show_date_creation",$multimedia_cfg{multimedia_show_date_creation});
    
    my $cb_multimedia_first_pic_of_a_list_pic_is_category_pic=get_checkbox("multimedia_first_pic_of_a_list_pic_is_category_pic",$multimedia_cfg{first_pic_of_a_list_pic_is_category_pic});
    
    my $cb_multimedia_only_one_categort_level=get_checkbox("multimedia_only_one_categort_level",$multimedia_cfg{only_one_categort_level});
    
    my $cb_multimedia_mini_fixed_height_width=get_checkbox("multimedia_mini_fixed_height_width",$multimedia_cfg{mini_fixed_height_width});
    my $cb_multimedia_small_fixed_height_width=get_checkbox("multimedia_small_fixed_height_width",$multimedia_cfg{small_fixed_height_width});
    my $cb_multimedia_medium_fixed_height_width=get_checkbox("multimedia_medium_fixed_height_width",$multimedia_cfg{medium_fixed_height_width});
    
    my $cb_multimedia_medium_link_instead_of_detail=get_checkbox("multimedia_medium_link_instead_of_detail",$multimedia_cfg{medium_link_instead_of_detail});
    my $cb_multimedia_list_elements_medium_link_instead_of_detail=get_checkbox("multimedia_list_elements_medium_link_instead_of_detail",$multimedia_cfg{list_elements_medium_link_instead_of_detail});
    my $cb_multimedia_list_elements_full_link_instead_of_detail=get_checkbox("multimedia_list_elements_full_link_instead_of_detail",$multimedia_cfg{list_elements_full_link_instead_of_detail});   
    
    
    #MULTIMEDIA***********************************************************************
    $form.=<<"EOH";
    <div id="config_multimedia">   
    

    <h1>Galerie multimedia</h1>
    
    <br />Nombre de chiffres de pagination: <input type="text" name="multimedia_pagination_max_numbers" value="$multimedia_cfg{pagination_max_numbers}" />
    <br />Nombre de résultats par page de pagination: <input type="text" name="multimedia_nb_restults_per_page" value="$multimedia_cfg{nb_restults_per_page}" />
    <br />Class ajoutée par défaut: <input type="text" name="multimedia_pic_class" value="$multimedia_cfg{pic_class}" />
    <br />Path d'upload: <input type="text" name="multimedia_upload_path" value="$multimedia_cfg{upload_path}" />
    <br />URL home: <input type="text" name="multimedia_url_home" value="$multimedia_cfg{url_home}" />
    
    <br />
    <br />Largeur des mini: <input type="text" name="multimedia_default_mini_width" value="$multimedia_cfg{default_mini_width}" />
    <br />Hauteur des mini: <input type="text" name="multimedia_default_mini_height" value="$multimedia_cfg{default_mini_height}" />
    <br />Largeur des small: <input type="text" name="multimedia_default_small_width" value="$multimedia_cfg{default_small_width}" />
    <br />Hauteur des small: <input type="text" name="multimedia_default_small_height" value="$multimedia_cfg{default_small_height}" />
    <br />Largeur des medium: <input type="text" name="multimedia_default_medium_width" value="$multimedia_cfg{default_medium_width}" />
    <br />Hauteur des medium: <input type="text" name="multimedia_default_medium_height" value="$multimedia_cfg{default_medium_height}" />
    <br />
    <br />Images minis carrées: $cb_multimedia_mini_fixed_height_width
    <br />Images smalls carrées: $cb_multimedia_small_fixed_height_width
    <br />Images mediums carrées: $cb_multimedia_medium_fixed_height_width
    <br />
    <br />URL medium au lieu du lien detail: $cb_multimedia_medium_link_instead_of_detail
    <br />URL medium au lieu du lien detail de l'élément (liste de photos): $cb_multimedia_list_elements_medium_link_instead_of_detail
    <br />URL full au lieu du lien detail de l'élément (liste de photos): $cb_multimedia_list_elements_full_link_instead_of_detail
    <br />
    
    
    <br />Photos simples activées : $cb_multimedia_simple_pic_enabled
    <br />Lecteur MP3 simple activé : $cb_multimedia_simple_audio_enabled
    <br />Lecteur Vidéo simple activé : $cb_multimedia_simple_video_enabled
    <br />Listes de photos activées : $cb_multimedia_list_pic_enabled
    <br />Liste de MP3s activées : $cb_multimedia_list_audio_enabled 
    <br />Liste de vidéos activées : $cb_multimedia_list_video_enabled
    <br />Mélange de tous les types activés : $cb_multimedia_list_mix_enabled
    <br />
    <br />Afficher la première photo comme photo de catégorie : $cb_multimedia_first_pic_of_a_list_pic_is_category_pic
    <br />Un seul niveau de catégories : $cb_multimedia_only_one_categort_level    
    <br />  
    <br />Admin: Afficher le type : $cb_multimedia_multimedia_show_type
    <br />Admin: Afficher le type des éléments : $cb_multimedia_multimedia_element_show_type
    <br />Admin: Afficher la date de création : $cb_multimedia_multimedia_show_date_creation    
    <br />
    <br />
    <b>Templates</b>
EOH
  
    for($t=0;$t<$#multimedia_tpl+1;$t++)
   {
     
    $form.=<<"EOH";
    <div class="template_container">$multimedia_tpl_libelles[$t] ${'listbox_multimedia_'.$multimedia_tpl[$t]}</div>
EOH
   } 
      
   $form.=<<"EOH";
   <br />
    </div>
EOH
    
}

if($show_old eq 'y')
    {
    
    #DATADIR***********************************************************************
    
    my %datadirs_cfg_line=select_table($dbh,"config","","varname='datadirs_cfg'");
    my %datadirs_cfg = eval("%datadirs_cfg = ($datadirs_cfg_line{varvalue});");
    
    my $cb_datadirs_mini_fixed_height_width=get_checkbox("datadirs_mini_fixed_height_width",$datadirs_cfg{mini_fixed_height_width});
    my $cb_datadirs_small_fixed_height_width=get_checkbox("datadirs_small_fixed_height_width",$datadirs_cfg{small_fixed_height_width});
    my $cb_datadirs_medium_fixed_height_width=get_checkbox("datadirs_medium_fixed_height_width",$datadirs_cfg{medium_fixed_height_width});
    
    
    $form.=<<"EOH";
    <div id="config_datadir">   
    

    <h1>Annuaire</h1>
    
    <br />
    <br />Largeur des mini: <input type="text" name="datadirs_default_mini_width" value="$datadirs_cfg{default_mini_width}" />
    <br />Hauteur des mini: <input type="text" name="datadirs_default_mini_height" value="$datadirs_cfg{default_mini_height}" />
    <br />Largeur des small: <input type="text" name="datadirs_default_small_width" value="$datadirs_cfg{default_small_width}" />
    <br />Hauteur des small: <input type="text" name="datadirs_default_small_height" value="$datadirs_cfg{default_small_height}" />
    <br />Largeur des medium: <input type="text" name="datadirs_default_medium_width" value="$datadirs_cfg{default_medium_width}" />
    <br />Hauteur des medium: <input type="text" name="datadirs_default_medium_height" value="$datadirs_cfg{default_medium_height}" />
    <br />
    <br />Moteur de recherche: <input type="text" name="datadirs_datadir_search_form" value="$datadirs_cfg{datadir_search_form}" />
    <br />
    <br />Where_supplémentaire: <input type="text" name="datadirs_wheresup" value="$datadirs_cfg{wheresup}" />
    <br />
    <br />Images minis carrées: $cb_datadirs_mini_fixed_height_width
    <br />Images smalls carrées: $cb_datadirs_small_fixed_height_width
    <br />Images mediums carrées: $cb_datadirs_medium_fixed_height_width
    <br />
          
    <br />Nombre de résultats par page: <input type="text" name="datadirs_nb_results_per_page" value="$datadirs_cfg{nb_results_per_page}" />
    <br />Code JS executé pour l'admin des fiches annuaires: <textarea name="datadirs_adm_dataforms_sheets_js">
    $datadirs_cfg{adm_dataforms_sheets_js}
    </textarea>
EOH
  
      
   $form.=<<"EOH";
   <br />
    </div>
EOH
    
   }
    
    $form.=<<"EOH";    
       

    </div>
    
    
    
    
    
    
    
<table id="mig_button_content">
				<tbody><tr><td></td>
				<td><button type="submit" class="mig_button">Sauvegarder la modification</button></td></tr>
			</tbody></table>
    
        </form>
EOH



return $form;
}


#*******************************************************************************
# HOME DB
#*******************************************************************************
sub home_db
{
    my %shop_cfg_line=select_table($dbh,"config","","varname='shop_cfg'");
    my %shop_cfg = eval("%shop_cfg = ($shop_cfg_line{varvalue});");
    
    my %data_shop_cfg_line=select_table($dbh,"config","","varname='data_shop_cfg'");
    my %data_shop_cfg = eval("%data_shop_cfg = ($data_shop_cfg_line{varvalue});");
    
    my %products_cfg_line=select_table($dbh,"config","","varname='products_cfg'");
    my %products_cfg = eval("%products_cfg = ($products_cfg_line{varvalue});");
    
    my %data_cfg_line=select_table($dbh,"config","","varname='data_cfg'");
    my %data_cfg = eval("%data_cfg = ($data_cfg_line{varvalue});");
    
    my %gifts_cfg_line=select_table($dbh,"config","","varname='gifts_cfg'");
    my %gifts_cfg = eval("%gifts_cfg = ($gifts_cfg_line{varvalue});");
    
    my %multimedia_cfg_line=select_table($dbh,"config","","varname='multimedia_cfg'");
    my %multimedia_cfg = eval("%multimedia_cfg = ($multimedia_cfg_line{varvalue});");
    
    my %datadirs_cfg_line=select_table($dbh,"config","","varname='datadirs_cfg'");
    my %datadirs_cfg = eval("%datadirs_cfg = ($datadirs_cfg_line{varvalue});");
    
    my %sub_cfg_line=select_table($dbh,"config","","varname='subscription_config'");
    my %sub_cfg = eval("%sub_cfg = ($sub_cfg_line{varvalue});");
    
    my %data=();
    my @fields=$cgi->param();
    for($i=0;$i<$#fields+1;$i++)
    {
      $data{$fields[$i]}=get_quoted($fields[$i],"","dontsanitize");
      $data{$fields[$i]} =~ s/\\'/<APOSTROPHE>/g;	
    }

    my $show_old=get_quoted('show_old') || "n";
     
  
    
    
    
   
   #subscriptions*****************************************************************************
    my @sub_tpl = (
      "loginform_tpl",
      "lostpwdform_tpl",
      "forms_tpl",
      "subform_tpl",
      "page_tpl",
      "email_free_gift_tpl"
      );
      
    for($t=0;$t<$#sub_tpl+1;$t++)
    {
        $sub_cfg{$sub_tpl[$t]}=$data{'sub_'.$sub_tpl[$t]} || 0;
    }
      
    $sub_cfg{free_gift}=$data{sub_free_gift} || "n";
    $sub_cfg{free_gift_value}=$data{sub_free_gift_value} || "0";
    $sub_cfg{from_name}=$data{sub_from_name} || "Administrateurs";
    $sub_cfg{subscription_from}=$data{sub_subscription_from} || "";
    $sub_cfg{link_to_mailing_group}=$data{sub_link_to_mailing_group} || 0;
        
    my %new_config=(); 
    $new_config{id_role}='1';
    $new_config{varname}='subscription_config';
    $new_config{varvalue}=trim(serialize_hash_params(\%sub_cfg));
#     see(\%new_config);
    
    
    sql_update_or_insert($dbh,"config",\%new_config,'varname','subscription_config');
#     exit;
    
    
    
    
    
    
    
    #*********************************************************************************
    # DATA****************************************************************************
#     "path_tpl",
#     "assoc_prod_tpl",   
#     "assoc_prod_container_tpl",         
#     "crit_table"
     
     my @data_tpl = 
    (
       'stock_ok',
       'stock_low',
       'stock_ko'
    );
    
    for($t=0;$t<$#data_tpl+1;$t++)
    {
        $data_cfg{$data_tpl[$t]}=$data{'data_'.$data_tpl[$t]} || 0;
    }
    
    $data_cfg{access_level_fields}=$data{data_access_level_fields} || "0";
    $data_cfg{access_level_crits}=$data{data_access_level_crits} || "0";
    $data_cfg{access_level_categories}=$data{data_access_level_categories} || "0";
    $data_cfg{access_level_stock}=$data{data_access_level_stock} || "0";
    $data_cfg{access_level_pictures}=$data{data_access_level_pictures} || "0";
    $data_cfg{access_level_files}=$data{data_access_level_files} || "0";
    $data_cfg{access_level_discounts}=$data{data_access_level_discounts} || "0";
    $data_cfg{access_level_assoc}=$data{data_access_level_assoc} || "0";
    $data_cfg{access_level_cat}=$data{data_access_level_cat} || "0";
    
    
    $data_cfg{default_family}=$data{data_default_family} || "";
    $data_cfg{root_url}=$data{data_root_url} || "http://www.bugiweb.com";
    $data_cfg{submenu_custom_classes} = $data{data_submenu_custom_classes} || " sf-menu sf-js-enabled ";
    
    $data_cfg{nr}=$data{data_nr} || "12";
    $data_cfg{nombre_numeros} = $data{data_nombre_numeros} || "15";
    $data_cfg{default_search_form} = $data{data_default_search_form};
    
    $data_cfg{crits_show_crits} = $data{data_crits_show_crits} || "n";
    $data_cfg{search_cache} = $data{data_search_cache} || "n";
    
    
    $data_cfg{crits_show_stock} = $data{data_crits_show_stock} || "n";
    $data_cfg{crits_show_weight} = $data{data_crits_show_weight} || "n";
    $data_cfg{crits_show_price} = $data{data_crits_show_price} || "n";
    $data_cfg{crits_show_reference} = $data{data_crits_show_reference} || "n";
    $data_cfg{multiple_prices} = $data{data_multiple_prices} || "n";
    $data_cfg{add_data_to_sitemap} = $data{data_add_data_to_sitemap} || "n";
    $data_cfg{num_new} = $data{data_num_new} || 20;
    
    $data_cfg{extlink} = $data{data_extlink} || "";
          
    $data_cfg{submenu_ordby_name} = $data{data_crits_show_reference} || "n";
    $data_cfg{write_all_tiles} = $data{data_write_all_tiles} || "n";
    $data_cfg{link_categories_father} = $data{data_link_categories_father} || "n";
    $data_cfg{count_coumpute_sheets} = $data{data_count_coumpute_sheets} || "n";
    
    $data_cfg{tri_1} = $data{data_tri_1} || "n";
    $data_cfg{tri_2} = $data{data_tri_2} || "n";
    $data_cfg{tri_3} = $data{data_tri_3} || "n";
    $data_cfg{tri_4} = $data{data_tri_4} || "n";
    $data_cfg{tri_5} = $data{data_tri_5} || "n";
    $data_cfg{tri_6} = $data{data_tri_6} || "n";
    $data_cfg{tri_7} = $data{data_tri_7} || "n";
    $data_cfg{tri_8} = $data{data_tri_8} || "n";
    
    $data_cfg{custom_promo} = $data{data_custom_promo} || "n";
    $data_cfg{custom_new} = $data{data_custom_new} || "n"; 
    
    my %new_config = (); 
    $new_config{id_role} = '1';
    $new_config{varname} = 'data_cfg';
    $new_config{varvalue} = trim(serialize_hash_params(\%data_cfg));
    sql_update_or_insert($dbh,"config",\%new_config,'varname','data_cfg');
    
     #(new)shop*********************************************************************************
    $data_shop_cfg{disable_discount_line_if_discount_total}=$data{data_shop_disable_discount_line_if_discount_total} || "n";
    $data_shop_cfg{disable_discount_line_if_discount_delivery}=$data{data_shop_disable_discount_line_if_discount_delivery} || "n";
    
    $data_shop_cfg{shop_disabled}=$data{data_shop_shop_disabled};
    $data_shop_cfg{default_delivery_method}=$data{data_shop_default_delivery_method};
    $data_shop_cfg{coord_no_delivery_method_available}=$data{data_shop_coord_no_delivery_method_available} || "";
    $data_shop_cfg{from}=$data{data_shop_from};
    $data_shop_cfg{from_name}=$data{data_shop_from_name};
    $data_shop_cfg{use_simple_stock}="y" || $data{data_shop_use_simple_stock} || "n";
    $data_shop_cfg{order_even_if_qty_is_zero} = $data{data_shop_order_even_if_qty_is_zero} || "n";
    $data_shop_cfg{allow_cart_without_login} = $data{data_shop_allow_cart_without_login} || "n";
              
        
    $data_shop_cfg{default_country_iso}=$data{data_shop_default_country_iso} || "BE";
    $data_shop_cfg{no_prices}=$data{data_shop_no_prices} || "n";
    $data_shop_cfg{shop_url}=$data{data_shop_shop_url} || "";
    $data_shop_cfg{home_url}=$data{data_shop_home_url} || "";
    $data_shop_cfg{prefixe_id_order}=$data{ogone_prefixe_id_order} || "";
    
    $data_shop_cfg{extlink}=$data{data_shop_extlink} || "";
    
    my @data_shop_tpl = (
    "change_status_email",
    "blank_page",
    "page",   
    "subscription_tpl",
    "analytics_postpayment",
    "cart_view_list",
    "cart_view_line",   
    "cart_lightbox",
    
    "cart_save_form",  
    
    "cart_saved_list",
    "cart_saved_line",  
    "cart_saved_detail",
    
    "product_discount_line",
    "delivery_discount_line",
    "total_discount_line",
    
    "add_coupon_form",
    "add_coupon_form_not_logged",
    "coupons_list",
    "coupons_line",
    
    "lost_password_tpl",
    "cart_export_form",         
    
    "dlv_meth_list",
    "dlv_meth_line",
    "dlv_no_valid_meths", 
    "dlv_kiala_choice",
    
    "bll_meth_list",
    "bll_meth_line",
    
    "cart_recap_list",
    "cart_recap_line",
    "recap_product_discount_line",
    "recap_delivery_discount_line",
    "recap_total_discount_line",
    
    
    "invoice_email",
    
    "payment_history_list",
     "payment_history_line",
    
    "msg_list",
    );
 
    for($t=0;$t<$#data_shop_tpl+1;$t++)
    {
        $data_shop_cfg{$data_shop_tpl[$t]}=$data{'data_shop_'.$data_shop_tpl[$t]} || 0;
    }
    
    
    $data_shop_cfg{inv_name}=$data{data_shop_inv_name} || "E-shop";
    
    $data_shop_cfg{inv_adr1}=$data{data_shop_inv_adr1} || "";
    $data_shop_cfg{inv_adr2}=$data{data_shop_inv_adr2} || "";
    $data_shop_cfg{inv_adr3}=$data{data_shop_inv_adr3} || "";
    $data_shop_cfg{inv_tel}=$data{data_shop_inv_tel} || "";
    $data_shop_cfg{inv_fax}=$data{data_shop_inv_fax} || "";
    
    $data_shop_cfg{inv_email}=$data{data_shop_inv_email} || "";
    $data_shop_cfg{inv_web}=$data{data_shop_inv_web} || "";
    $data_shop_cfg{inv_tva}=$data{data_shop_inv_tva} || "";
    $data_shop_cfg{inv_banque}=$data{data_shop_inv_banque} || "";
    $data_shop_cfg{inv_iban}=$data{data_shop_inv_iban} || "";
    $data_shop_cfg{inv_bic}=$data{data_shop_inv_bic} || "";
    
    my %new_config=(); 
    $new_config{id_role}='1';
    $new_config{varname}='data_shop_cfg';
    $new_config{varvalue}=trim(serialize_hash_params(\%data_shop_cfg));
    sql_update_or_insert($dbh,"config",\%new_config,'varname','data_shop_cfg');
    
    
    
    
    
    
    
    
    if($show_old eq 'y')
    {
    
    
    #(old)shop*********************************************************************************
    $shop_cfg{disable_discount_line_if_discount_total}=$data{shop_disable_discount_line_if_discount_total} || "n";
    $shop_cfg{disable_discount_line_if_discount_delivery}=$data{shop_disable_discount_line_if_discount_delivery} || "n";
    
    $shop_cfg{shop_disabled}=$data{shop_shop_disabled};
    $shop_cfg{default_delivery_method}=$data{shop_default_delivery_method};
    $shop_cfg{coord_no_delivery_method_available}=$data{shop_coord_no_delivery_method_available} || "";
    $shop_cfg{from}=$data{shop_from};
    $shop_cfg{from_name}=$data{shop_from_name};
    $shop_cfg{use_simple_stock}="y" || $data{shop_use_simple_stock} || "n";
    $shop_cfg{default_country_iso}=$data{shop_default_country_iso} || "BE";
    $shop_cfg{no_prices}=$data{shop_no_prices} || "n";
    $shop_cfg{shop_url}=$data{shop_shop_url} || "";
    $shop_cfg{home_url}=$data{shop_home_url} || "";
    $shop_cfg{prefixe_id_order}=$data{ogone_prefixe_id_order} || "";
    
    my @shop_tpl = (
    "blank_page",
    "page",   
    "subscription_tpl",
    
    "cart_view_list",
    "cart_view_line",   
    "cart_lightbox",
    
    "cart_save_form",  
    
    "cart_saved_list",
    "cart_saved_line",  
    "cart_saved_detail",
    
    "product_discount_line",
    "delivery_discount_line",
    "total_discount_line",
    
    "add_coupon_form",
    "coupons_list",
    "coupons_line",
    
    "lost_password_tpl",
    "cart_export_form",         
    
    "dlv_meth_list",
    "dlv_meth_line",
    "dlv_no_valid_meths", 
    "dlv_kiala_choice",
    
    "bll_meth_list",
    "bll_meth_line",
    
    "cart_recap_list",
    "cart_recap_line",
    "recap_product_discount_line",
    "recap_delivery_discount_line",
    "recap_total_discount_line",
    
    
    "html_recap_list",
    "html_recap_line",
    
    "payment_history_list",
     "payment_history_line",
    
    "msg_list",
    );
 
    for($t=0;$t<$#shop_tpl+1;$t++)
    {
        $shop_cfg{$shop_tpl[$t]}=$data{'shop_'.$shop_tpl[$t]} || 0;
    }
    
    my %new_config=(); 
    $new_config{id_role}='1';
    $new_config{varname}='shop_cfg';
    $new_config{varvalue}=trim(serialize_hash_params(\%shop_cfg));
    sql_update_or_insert($dbh,"config",\%new_config,'varname','shop_cfg');
    
    
    #products*****************************************************************************
    my @products_tpl = (
    "page",
    "list",
    "line",
    "object",
    "object_detail",
    "path_tpl",
    "assoc_prod_tpl",   
    "assoc_prod_container_tpl",         
    "crit_table",
    "search_box",
    "subscription_tpl",
    "dlv_no_valid_meths",
    "stock_ok",
    "stock_low",
    "stock_ko",    
    "products_filters_home",
    "categories_listing_object"
    );
      
    for($t=0;$t<$#products_tpl+1;$t++)
    {
        $products_cfg{$products_tpl[$t]}=$data{'products_'.$products_tpl[$t]} || 0;
    }
      
    $products_cfg{products_always_in_a_category}=$data{products_products_always_in_a_category} || "n";
    
    $products_cfg{acl_tags_level}=$data{products_acl_tags_level} || "0";
    $products_cfg{acl_stock_level}=0;#$data{products_acl_stockprices_level}  || $data{products_acl_stock_level} || "0";
    $products_cfg{acl_discount_level}=$data{products_acl_discount_level} || "0";
    $products_cfg{acl_assoc_level}=$data{products_acl_assoc_level} || "0";
    $products_cfg{acl_fields_level}=$data{products_acl_fields_level} || "0";
    $products_cfg{acl_crits_level}=$data{products_acl_crits_level} || "0";
    $products_cfg{acl_categories_level}=$data{products_acl_categories_level} || "0";
    $products_cfg{acl_stockprices_level}=$data{products_acl_stockprices_level} || "0";
   
    $products_cfg{nb_results_per_page}=$data{products_nb_results_per_page} || "10";
    $products_cfg{pagination_max_numbers}=$data{products_pagination_max_numbers} || "10";
    
    
    $products_cfg{upload_path}=$data{products_upload_path} || "";
    $products_cfg{upload_dir}=$data{products_upload_dir} || "";
    $products_cfg{quotation_linked}=$data{products_quotation_linked} || "n";
    $products_cfg{encode_prices_even_if_shop_is_not_linked}=$data{products_encode_prices_even_if_shop_is_not_linked} || "n";
    $products_cfg{use_lnk_with_datadir}=$data{products_use_lnk_with_datadir} || "n";
    $products_cfg{order_even_if_qty_is_zero} = $data{products_order_even_if_qty_is_zero} || "n";
    
#     see(\%products_cfg);
#     exit;
    
    $products_cfg{pic_class}=$data{products_pic_class} || "";
    $products_cfg{search_module}=$data{products_search_module} || "";
    $products_cfg{filter}=$data{products_filter} || "n";
    $products_cfg{filter_generer_vides}=$data{products_filter_generer_vides} || "n";
    $products_cfg{categories_ordby}=$data{products_categories_ordby} || "";
    $products_cfg{default_viewer}=$data{products_default_viewer} || "cgi";
    $products_cfg{detail_viewer}=$data{products_detail_viewer} || "cgi";
    $products_cfg{listing_viewer}=$data{products_listing_viewer} || "cgi";
   
    $products_cfg{meta_title_field}=$data{products_meta_title_field} || "";
    $products_cfg{meta_descr_field}=$data{products_meta_descr_field} || "";
    $products_cfg{meta_products_default_page}=$data{products_meta_products_default_page} || "";
     
    $products_cfg{extlink}=$data{products_extlink};
    
    $products_cfg{show_if_stock_positive}=$data{products_show_if_stock_positive} || "n"; 
    $products_cfg{order_qty_avaiable}=$data{products_order_qty_avaiable} || "n";
        
    my %new_config=(); 
    $new_config{id_role}='1';
    $new_config{varname}='products_cfg';
    $new_config{varvalue}=trim(serialize_hash_params(\%products_cfg));
    
    sql_update_or_insert($dbh,"config",\%new_config,'varname','products_cfg');
    
    }    
    
    #GENERAUX
    
    my %new_config=(); 
    $new_config{id_role}='1';
    $new_config{varname}='nb_page_max';
    $new_config{varvalue}=get_quoted('nb_page_max');
    sql_update_or_insert($dbh,"config",\%new_config,'varname','nb_page_max');
    
#     my %new_config=(); 
#     $new_config{id_role}='1';
#     $new_config{varname}='default_fm_root';
#     $new_config{varvalue}=get_quoted('default_fm_root');
#     sql_update_or_insert($dbh,"config",\%new_config,'varname','default_fm_root');
#     
#     my %new_config=(); 
#     $new_config{id_role}='1';
#     $new_config{varname}='default_fm_url';
#     $new_config{varvalue}=get_quoted('default_fm_url');
#     sql_update_or_insert($dbh,"config",\%new_config,'varname','default_fm_url');
    
    
    my %new_config=(); 
    $new_config{id_role}='1';
    $new_config{varname}='rewrite_404_id_page';
    $new_config{varvalue}=get_quoted('rewrite_404_id_page');
    sql_update_or_insert($dbh,"config",\%new_config,'varname','rewrite_404_id_page');
    
      my %new_config=(); 
    $new_config{id_role}='1';
    $new_config{varname}='rewrite_404_id_language';
    $new_config{varvalue}=get_quoted('rewrite_404_id_language');
    sql_update_or_insert($dbh,"config",\%new_config,'varname','rewrite_404_id_language');
    
    
    #virement*****************************************************************************
    my %methode=%{get_param_name('virement')};
    my %params = eval("%cfg = ($methode{params});");
    $methode{visible}=$data{virement_visible} || "n";
    $params{name}='virement';
    $params{tpl}=$data{virement_tpl};
    $params{compte}=$data{virement_compte};
    $params{nom}=$data{virement_nom};
    $params{adresse}=$data{virement_adresse};
    $params{ville}=$data{virement_ville};
    $params{telephone}=$data{virement_telephone};
    $params{bic}=$data{virement_bic};
    $params{iban}=$data{virement_iban};
    $params{stock_linked}=$data{virement_stock_linked} || "n";
    
    $methode{params}=serialize_hash_params(\%params);
    sql_update_or_insert($dbh,"methodes",\%methode,"id",$methode{id});
    
    
    #ogone********************************************************************************
    my %methode=%{get_param_name('ogone')};
    $methode{visible}=$data{ogone_visible} || "n";
    my %params = eval("%cfg = ($methode{params});");
    $params{tpl}=$data{ogone_tpl};
    $params{name}='ogone';
    $params{language}=$data{ogone_language} || "fr_fr";
    $params{ogone_pspid}=$data{ogone_ogone_pspid};
    $params{version}=$data{ogone_version};
    $params{ogone_prod_status}=$data{ogone_ogone_prod_status};
    $params{ogone_sha1in}=$data{ogone_ogone_sha1in};
    $params{ogone_sha1out}=$data{ogone_ogone_sha1out};
    $params{prefixe_id_order}=$data{ogone_prefixe_id_order};
    $params{ogone_id_site}=$data{ogone_ogone_id_site} || "";
    $params{stock_linked}=$data{ogone_stock_linked} || "n";
    $params{template_ogone}=$data{ogone_template_ogone} || "";
    $params{brands}=$data{ogone_brands} || "";
    
    $methode{params}=serialize_hash_params(\%params);
    sql_update_or_insert($dbh,"methodes",\%methode,"id",$methode{id});
                         
    #kiala********************************************************************************
    my %methode=%{get_param_name('kiala')};
    $methode{visible}=$data{kiala_visible} || "n";
    my %params = eval("%cfg = ($methode{params});");
    $params{name}='kiala';
    $params{dspid}=$data{kiala_dspid} || 'DEMO_DSP' || '32600160';
    $params{fixcost}=$data{kiala_fixcost} || '0';
    $params{button_txt}=$data{kiala_button_txt} || 'Choisir ce point kiala comme livraison';
    $params{width}=$data{kiala_width} || 965;
    $params{height}=$data{kiala_height} || 500;
    
    
    
    $methode{params}=serialize_hash_params(\%params);
    sql_update_or_insert($dbh,"methodes",\%methode,"id",$methode{id});
    
    
    
    #paypal*******************************************************************************
    my %methode=%{get_param_name('paypal')};
    $methode{visible}=$data{paypal_visible} || "n";
    my %params = eval("%cfg = ($methode{params});");
    $params{name}='paypal';
    $params{version}=$data{paypal_version};
    $params{tpl}=$data{paypal_tpl};
    $params{paypal_id}=$data{paypal_paypal_id};
    $params{stock_linked}=$data{paypal_stock_linked} || "n";
    
    $methode{params}=serialize_hash_params(\%params);
    sql_update_or_insert($dbh,"methodes",\%methode,"id",$methode{id});
    
    
     #configs (diverses)******************************************************************
     my @fields_config=qw(
                        default_colg
                        default_mini_width
                        default_mini_height
                        default_small_width
                        default_small_height
                        default_medium_width
                        default_medium_height
                  );
      
    for($f=0;$f<$#fields_config+1;$f++)
    { 
        
        if($data{$fields_config[$f]} > 0)
        {
            my %new_config=(); 
            $new_config{id_role}='1';
            $new_config{varname}=$fields_config[$f];
            $new_config{varvalue}=$data{$fields_config[$f]};
            sql_update_or_insert($dbh,"config",\%new_config,'varname',$fields_config[$f]);
        }
    }
    
    
    #quotation****************************************************************************
    my %quotation_cfg_line=select_table($dbh,"config","","varname='quotation_cfg'");
    my %quotation_cfg = eval("%quotation_cfg = ($quotation_cfg_line{varvalue});");
    
my @quotation_tpl = (
      "page",
      "container",
      "etape1",
      "etape2",
      "etape3",
      "etape4",
      "etape5",   
      "etape6",         
      "etape7",
      "etape8",
      "etape9",
      "etape10",
      "etape11"
      );

    
    
     for($t=0;$t<$#quotation_tpl+1;$t++)
    {
        $quotation_cfg{$quotation_tpl[$t]}=$data{'quotation_'.$quotation_tpl[$t]} || 0;
    }
    
    
  
    
    
    $quotation_cfg{quotation_upload_path}=$data{quotation_quotation_upload_path} || "";
    $quotation_cfg{from}=$data{quotation_from} || "";
    $quotation_cfg{debug_to}=$data{quotation_debug_to} || "";
    $quotation_cfg{tracking}=$data{quotation_tracking} || "";
    $quotation_cfg{product_sheet}=$data{quotation_product_sheet} || "0";
    $quotation_cfg{calcule_devis_func}=$data{quotation_calcule_devis_func} || "";
    $quotation_cfg{url_pdf}=$data{quotation_url_pdf} || "";
    $quotation_cfg{id_bloc1}=$data{quotation_id_bloc1} || "";
    $quotation_cfg{id_bloc2}=$data{quotation_id_bloc2} || "";                   
    $quotation_cfg{objet_email}=$data{quotation_objet_email} || "";
    $quotation_cfg{un_seul_devis}=$data{quotation_un_seul_devis} || "n";
    $quotation_cfg{font_size}=$data{quotation_font_size} || "";
    $quotation_cfg{interligne}=$data{quotation_interligne} || "";
    
    
    
    
    $quotation_cfg{facture_name}=$data{quotation_facture_name} || "";
    $quotation_cfg{facture_company}=$data{quotation_facture_company} || "";
    $quotation_cfg{facture_street}=$data{quotation_facture_street} || "";
    $quotation_cfg{facture_zip}=$data{quotation_facture_zip} || "";
    $quotation_cfg{facture_city}=$data{quotation_facture_city} || "";
    $quotation_cfg{facture_state}=$data{quotation_facture_state} || "";
    $quotation_cfg{facture_country}=$data{quotation_facture_country} || "";
    $quotation_cfg{facture_tel}=$data{quotation_facture_tel} || "";
    $quotation_cfg{facture_fax}=$data{quotation_facture_fax} || "";
    $quotation_cfg{facture_email}=$data{quotation_facture_email} || "";
    $quotation_cfg{facture_web}=$data{quotation_facture_web} || "";
    $quotation_cfg{facture_cbc}=$data{quotation_facture_cbc} || "";
    $quotation_cfg{facture_ccp}=$data{quotation_facture_ccp} || "";
    $quotation_cfg{facture_bic}=$data{quotation_facture_bic} || "";
    $quotation_cfg{facture_iban}=$data{quotation_facture_iban} || "";
    
    $quotation_cfg{product_sheet_field_pic}='f'.$data{quotation_product_sheet_field_pic} || "";
    
    my %new_config=(); 
    $new_config{varvalue}=trim(serialize_hash_params(\%quotation_cfg));
    sql_update_or_insert($dbh,"config",\%new_config,'varname','quotation_cfg');








    #gifts*****************************************************************************
    my @gifts_tpl = (
    "page",
    "gifts_login",
    "gifts_form",
    "gifts_recap",
    "tpl_end_order_1",
    "tpl_end_order_2",
    );
    
    for($t=0;$t<$#gifts_tpl+1;$t++)
    {
        $gifts_cfg{$gifts_tpl[$t]}=$data{'gifts_'.$gifts_tpl[$t]} || 0;
    }
    
    $gifts_cfg{pm}=get_quoted('gifts_pm') || 0;
    
    my %new_config=(); 
    $new_config{id_role}='1';
    $new_config{varname}='gifts_cfg';
    $new_config{varvalue}=trim(serialize_hash_params(\%gifts_cfg));
    sql_update_or_insert($dbh,"config",\%new_config,'varname','gifts_cfg');
    
    
    if($show_old eq 'y')
    {
        #multimedia*****************************************************************************
         my @multimedia_tpl = (
                "list",
                "object",
                "object_detail_simple_pic",
                "object_detail_simple_video",
                "object_detail_simple_audio",
                "page",
                "search_box",
                "path_tpl",
                "list_elements",
                "list_elements_object",
                "list_elements_object_detail_simple_video",
                "list_elements_object_detail_simple_pic"
                );
        
        for($t=0;$t<$#multimedia_tpl+1;$t++)
        {
            $multimedia_cfg{$multimedia_tpl[$t]}=$data{'multimedia_'.$multimedia_tpl[$t]} || 0;
        }
        
        $multimedia_cfg{pagination_max_numbers}=$data{multimedia_pagination_max_numbers} || "";
        $multimedia_cfg{nb_restults_per_page}=$data{multimedia_nb_restults_per_page} || "";
        $multimedia_cfg{pic_class}=$data{multimedia_pic_class} || "";
        $multimedia_cfg{upload_path}=$data{multimedia_upload_path} || "";
        $multimedia_cfg{url_home}=$data{multimedia_url_home} || "";
        $multimedia_cfg{default_mini_width}=$data{multimedia_default_mini_width} || "";
        $multimedia_cfg{default_mini_height}=$data{multimedia_default_mini_height} || "";
        $multimedia_cfg{default_small_width}=$data{multimedia_default_small_width} || "";
        $multimedia_cfg{default_small_height}=$data{multimedia_default_small_height} || "";
        $multimedia_cfg{default_medium_width}=$data{multimedia_default_medium_width} || "";
        $multimedia_cfg{default_medium_height}=$data{multimedia_default_medium_height} || "";
        
        $multimedia_cfg{simple_pic_enabled}=$data{multimedia_simple_pic_enabled} || "n";
        $multimedia_cfg{simple_audio_enabled}=$data{multimedia_simple_audio_enabled} || "n";
        $multimedia_cfg{simple_video_enabled}=$data{multimedia_simple_video_enabled} || "n";
        $multimedia_cfg{list_pic_enabled}=$data{multimedia_list_pic_enabled} || "n";
        $multimedia_cfg{list_audio_enabled}=$data{multimedia_list_audio_enabled} || "n";
        $multimedia_cfg{list_video_enabled}=$data{multimedia_list_video_enabled} || "n";
        $multimedia_cfg{list_mix_enabled}=$data{multimedia_list_mix_enabled} || "n";
        $multimedia_cfg{multimedia_show_type}=$data{multimedia_multimedia_show_type} || "n";
        $multimedia_cfg{multimedia_element_show_type}=$data{multimedia_multimedia_element_show_type} || "n";
        $multimedia_cfg{multimedia_show_date_creation}=$data{multimedia_multimedia_show_date_creation} || "n";
        $multimedia_cfg{first_pic_of_a_list_pic_is_category_pic}=$data{multimedia_first_pic_of_a_list_pic_is_category_pic} || "n";
        $multimedia_cfg{only_one_categort_level}=$data{multimedia_only_one_categort_level} || "n";
                                        
        $multimedia_cfg{mini_fixed_height_width}=$data{multimedia_mini_fixed_height_width} || "n";
        $multimedia_cfg{small_fixed_height_width}=$data{multimedia_small_fixed_height_width} || "n";
        $multimedia_cfg{medium_fixed_height_width}=$data{multimedia_medium_fixed_height_width} || "n";
        
        $multimedia_cfg{medium_link_instead_of_detail}=$data{multimedia_medium_link_instead_of_detail} || "n";
        $multimedia_cfg{list_elements_medium_link_instead_of_detail}=$data{multimedia_list_elements_medium_link_instead_of_detail} || "n";
        $multimedia_cfg{list_elements_full_link_instead_of_detail}=$data{multimedia_list_elements_full_link_instead_of_detail} || "n";
        
        my %new_config=(); 
        $new_config{id_role}='1';
        $new_config{varname}='multimedia_cfg';
        $new_config{varvalue}=trim(serialize_hash_params(\%multimedia_cfg));
        sql_update_or_insert($dbh,"config",\%new_config,'varname','multimedia_cfg');

    }
    #datadirs*****************************************************************************
    if($show_old eq 'y')
    {
        $datadirs_cfg{default_mini_width}=$data{datadirs_default_mini_width} || "";
        $datadirs_cfg{default_mini_height}=$data{datadirs_default_mini_height} || "";
        $datadirs_cfg{default_small_width}=$data{datadirs_default_small_width} || "";
        $datadirs_cfg{default_small_height}=$data{datadirs_default_small_height} || "";
        $datadirs_cfg{default_medium_width}=$data{datadirs_default_medium_width} || "";
        $datadirs_cfg{default_medium_height}=$data{datadirs_default_medium_height} || "";
    
                                        
        $datadirs_cfg{mini_fixed_height_width}=$data{datadirs_mini_fixed_height_width} || "n";
        $datadirs_cfg{small_fixed_height_width}=$data{datadirs_small_fixed_height_width} || "n";
        $datadirs_cfg{medium_fixed_height_width}=$data{datadirs_medium_fixed_height_width} || "n";
        
        $datadirs_cfg{wheresup}=$data{datadirs_wheresup} || "";
        
        $datadirs_cfg{adm_dataforms_sheets_js}=$data{datadirs_adm_dataforms_sheets_js} || "";
        $datadirs_cfg{nb_results_per_page}=$data{datadirs_nb_results_per_page} || "10";
        
        my %new_config=(); 
        $new_config{id_role}='1';
        $new_config{varname}='datadirs_cfg';
        $new_config{varvalue}=trim(serialize_hash_params(\%datadirs_cfg));
        sql_update_or_insert($dbh,"config",\%new_config,'varname','datadirs_cfg');
    }
    http_redirect("$htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/adm_config.pl?show_old=".$show_old);   
}





#*******************************************************************************
# INIT 
#*******************************************************************************
sub init
{
#     print "init";
#     exit;
    $use_global_textcontents = 0;
   
    my $form="";
    #réécriture de JS CFG (manque souvent des elements)
    my $stmt = "delete from config where varname='js_cfg'";
    my $cursor = $dbh->prepare($stmt);
    my $rc = $cursor->execute;
    if (!defined $rc) 
    {
        see();
        print "[$stmt]";
        exit;   
    } 
    
    my $stmt = "ALTER TABLE `eshop_orders` CHANGE `delivery_status` `delivery_status` ENUM('current','ready','partial_sent','full_sent','cancelled','ready_to_take','retour','partial_repaid') CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT 'current', CHANGE `payment_status` `payment_status` ENUM('wait_payment','captured','paid','repaid','cancelled','partial_retour') CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT 'wait_payment';";
    my $cursor = $dbh->prepare($stmt);
    my $rc = $cursor->execute;
    if (!defined $rc) 
    {
        see();
        print "[$stmt]";
        exit;   
    } 
    
    
    my %new_config=();
    $new_config{varname}="js_cfg";
    $new_config{varvalue}='"data_shop"=>"tooltip,validate,nyromodal2,cycle,json2,cookie,jsoncookie,form,sprintf,data_subscriptions,data_shop,menu_coulissant,swfobject,notification","shop"=>"tooltip,validate,nyromodal,cycle,json2,cookie,jsoncookie,form,sprintf,subscriptions,shop,menu_coulissant,swfobject,notification"';
    $new_config{id_role}="1"; 
    $code=inserth_db($dbh,'config',\%new_config);
 
    create_col_in_table($dbh,'countries','is_intracom','enum_y_n');
    
    
    create_col_in_table($dbh,'data_field_listvalues','id_textid_url_ext','int');
    create_col_in_table($dbh,'data_field_listvalues','id_textid_seo_title','int');
    create_col_in_table($dbh,'data_field_listvalues','id_textid_seo_description','int');
    create_col_in_table($dbh,'data_field_listvalues','id_textid_seo_keywords','int');
    
    create_col_in_table($dbh,'data_fields','in_meta_title','enum_y_n');
    create_col_in_table($dbh,'data_fields','in_meta_description','enum_y_n');
    
    create_col_in_table($dbh,'data_sheets','taxes','varchar');
	
	create_col_in_table($dbh,'data_cache_pages_urls','cache_html','longtext');
	
    create_col_in_table($dbh,'data_sheets','has_taxes','int');
    create_col_in_table($dbh,'data_sheets','tax_1_id_value','int');
    create_col_in_table($dbh,'data_sheets','tax_2_id_value','int');
    create_col_in_table($dbh,'data_sheets','tax_3_id_value','int');
    create_col_in_table($dbh,'eshop_urls','keyword','varchar');
    create_col_in_table($dbh,'data_searchs','all_if_void','enum_n_y');
    create_col_in_table($dbh,'data_searchs','force_value','text');
    create_col_in_table($dbh,'data_searchs','id_textid_default_value','int');
    
    create_col_in_table($dbh,'data_setup','hide_tva_admin','enum_y_n');
    create_col_in_table($dbh,'data_setup','data_sheet_force_tva','varchar');
    create_col_in_table($dbh,'data_setup','donotwritetiles','enum_y_n');
    create_col_in_table($dbh,'data_setup','id_default_tarif','int');
   
    
    create_col_in_table($dbh,'data_lnk_sheets_categories','lnk_qty','int');
    
    create_col_in_table($dbh,'eshop_coupons','free_ship','enum_y_n');
	create_col_in_table($dbh,'eshop_coupons','auto_pay','enum_y_n');
    
    create_col_in_table($dbh,'eshop_orders','id_tarif','int');
    create_col_in_table($dbh,'eshop_orders','ext_id_member','int');
    create_col_in_table($dbh,'eshop_orders','ext_id_identity_delivery','int');
    create_col_in_table($dbh,'eshop_orders','ext_id_identity_billing','int');
    create_col_in_table($dbh,'eshop_orders','ext_id','int');
    
    create_col_in_table($dbh,'eshop_orders','delivery_confirm_email','varchar');
    create_col_in_table($dbh,'eshop_orders','delivery_password','varchar');
    create_col_in_table($dbh,'eshop_orders','delivery_confirm_password','varchar');
    create_col_in_table($dbh,'data_sheets','tr_moment','datetime');
    
    create_col_in_table($dbh,'eshop_orders','email_sent_5','int');
    create_col_in_table($dbh,'eshop_orders','email_sent_10','int');
    create_col_in_table($dbh,'eshop_orders','conditions_ok','enum_y_n');
    create_col_in_table($dbh,'eshop_setup','id_textid_conditions','int');
    
    
    create_col_in_table($dbh,'eshop_orders','billing_confirm_email','varchar');
    create_col_in_table($dbh,'eshop_orders','billing_password','varchar');
    create_col_in_table($dbh,'eshop_orders','billing_confirm_password','varchar');
    
    create_col_in_table($dbh,'mailings','template_html','text');
    
    
    
    create_col_in_table($dbh,'eshop_tarifs','pay_tvac','enum_y_n');
    
    create_col_in_table($dbh,'shop_delcost_zones','id_coupon','int');
	
	create_col_in_table($dbh,'forms','link_to_newsletter_group','int');
  create_col_in_table($dbh,'forms','link_to_data_family','int');
  
  create_col_in_table($dbh,'forms','post_forms_func','varchar');
  
    
    
    create_col_in_table($dbh,'data_stock','id_textid_comment_1','int');
    create_col_in_table($dbh,'data_stock','id_textid_comment_2','int');
    
    create_col_in_table($dbh,'eshop_discounts','discount_coupon','varchar');
    create_col_in_table($dbh,'eshop_discounts','target_not_discounted','enum_y_n');
    
    create_col_in_table($dbh,'eshop_discounts','nb_uses_email','int');
    create_col_in_table($dbh,'eshop_discounts','id_tarif','int');  
    
    create_col_in_table($dbh,'eshop_payments','id_tarif','int');
    
    create_col_in_table($dbh,'eshop_orders','delivery_vat_status','varchar');
    create_col_in_table($dbh,'eshop_orders','billing_vat_status','varchar');
    create_col_in_table($dbh,'eshop_orders','delivery_vat_code','varchar');
    create_col_in_table($dbh,'eshop_orders','billing_vat_code','varchar');
    create_col_in_table($dbh,'eshop_orders','delivery_vat_txt','varchar');
    create_col_in_table($dbh,'eshop_orders','billing_vat_txt','varchar');
    create_col_in_table($dbh,'eshop_orders','total_taxes','float');
    create_col_in_table($dbh,'eshop_orders','is_intracom','int');
    create_col_in_table($dbh,'eshop_orders','order_lg','int');
    create_col_in_table($dbh,'eshop_orders','cart_date','date');   
    
    create_col_in_table($dbh,'eshop_discounts','minimum_qty','int');
    
    create_col_in_table($dbh,'eshop_order_details','avert_stock','enum_y_n');
    create_col_in_table($dbh,'eshop_order_details','id_tarif','int');
    create_col_in_table($dbh,'eshop_order_details','id_data_stock_tarif','int');
    create_col_in_table($dbh,'eshop_order_details','detail_pu_tax','float');
    create_col_in_table($dbh,'eshop_order_details','detail_total_tax','float');
    
    create_col_in_table($dbh,'eshop_orders','use_backorder','enum_y_n');
    create_col_in_table($dbh,'eshop_orders','cmd_fourn','enum_y_n');
    create_col_in_table($dbh,'eshop_orders','total_qty_restant','int');
    create_col_in_table($dbh,'eshop_orders','total_qty_expedie','int');
    create_col_in_table($dbh,'eshop_orders','total_qty','int');  
	
	create_col_in_table($dbh,'eshop_setup','member_autologin_after_signup','enum_y_n'); 
	create_col_in_table($dbh,'eshop_setup','revendeur_autologin_after_signup','enum_y_n'); 
	create_col_in_table($dbh,'eshop_setup','create_ext_identities','enum_y_n');
    create_col_in_table($dbh,'eshop_setup','weight_unit','varchar');
    create_col_in_table($dbh,'eshop_setup','auto_create_member','enum_y_n');
    create_col_in_table($dbh,'eshop_setup','create_member_in_delivery','enum_y_n');
	create_col_in_table($dbh,'eshop_setup','cart_box_func','varchar');
	create_col_in_table($dbh,'eshop_setup','hipay_id_marchand','varchar'); 
	create_col_in_table($dbh,'eshop_setup','hipay_password_marchand','varchar'); 
	create_col_in_table($dbh,'eshop_setup','hipay_site_id','varchar'); 
	create_col_in_table($dbh,'eshop_setup','hipay_category','varchar'); 
	create_col_in_table($dbh,'eshop_setup','cacher_breadcrumb','enum_y_n');
    create_col_in_table($dbh,'eshop_setup','sauter_livraison','enum_y_n');
    create_col_in_table($dbh,'eshop_setup','sauter_methode_livraison','enum_y_n');
    create_col_in_table($dbh,'eshop_setup','sauter_facturation','enum_y_n');
    create_col_in_table($dbh,'eshop_setup','login_obligatoire','enum_y_n');
    create_col_in_table($dbh,'eshop_setup','cacher_lien_creer_un_compte','enum_y_n');
    create_col_in_table($dbh,'eshop_setup','montant_pour_livraison_gratuite','float');
    create_col_in_table($dbh,'eshop_setup','plusieurs_profils_livraison','enum_y_n');          
    create_col_in_table($dbh,'eshop_setup','google_adwords_account','varchar');
    create_col_in_table($dbh,'eshop_setup','avert_stock','enum_y_n');
    create_col_in_table($dbh,'eshop_setup','google_adwords_code_language','varchar');
    create_col_in_table($dbh,'eshop_setup','google_adwords_label_1','varchar');
    create_col_in_table($dbh,'eshop_setup','google_adwords_label_2','varchar');
    create_col_in_table($dbh,'eshop_setup','google_adwords_label_3','varchar');
    create_col_in_table($dbh,'eshop_setup','google_adwords_label_4','varchar');
    create_col_in_table($dbh,'eshop_setup','google_adwords_label_5','varchar');
    create_col_in_table($dbh,'eshop_setup','js_show_member_box','enum_n_y');
    create_col_in_table($dbh,'eshop_setup','accept_intracom_order_if_tva_check_is_disabled','enum_n_y');    
    create_col_in_table($dbh,'eshop_setup','cart_show_method_delivery_name','enum_y_n');
    create_col_in_table($dbh,'eshop_setup','disable_detail_link','enum_y_n');
    create_col_in_table($dbh,'eshop_setup','disable_edit_qty','enum_y_n');
    create_col_in_table($dbh,'eshop_setup','go_to_recap_if_one_method','enum_y_n');
    
    create_col_in_table($dbh,'forms_fields','id_data_field','int');
    
    create_col_in_table($dbh,'identities','do_intracom','enum_y_n'); 
    
    create_col_in_table($dbh,'mailings','use_excel_file','enum_y_n'); 
    create_col_in_table($dbh,'mailings','excel_file','text');
    create_col_in_table($dbh,'mailings','excel_num_col_email','int');
    create_col_in_table($dbh,'mailings','excel_num_line_begin','int'); 
    
    create_col_in_table($dbh,'members','id_tarif','int');
	  create_col_in_table($dbh,'members','social_token','varchar');
    create_col_in_table($dbh,'members','social_id','varchar');
    
    create_col_in_table($dbh,'pics','pic_name_og','varchar');
    create_col_in_table($dbh,'pics','pic_width_og','int');
	
	create_col_in_table($dbh,'pics','pic_name_large','varchar');
    create_col_in_table($dbh,'pics','pic_width_large','int');
	create_col_in_table($dbh,'pics','pic_height_large','int');
   
   create_col_in_table($dbh,'eshop_orders','do_intracom','enum_y_n');  
   
   create_col_in_table($dbh,'pics','pic_height_og','int');
   
   create_col_in_table($dbh,'data_list_sheets','id_parag','int');
   create_col_in_table($dbh,'data_list_sheets','product_name','varchar');
   create_col_in_table($dbh,'data_list_sheets','new_photo','varchar');
   create_col_in_table($dbh,'data_list_sheets','full_price','varchar');
   create_col_in_table($dbh,'data_list_sheets','discount_price','varchar');
   create_col_in_table($dbh,'data_list_sheets','id_lnk_pic','int');
   create_col_in_table($dbh,'data_list_sheets','id_data_sheet','int');
   create_col_in_table($dbh,'data_list_sheets','id_language','int'); 
   create_col_in_table($dbh,'data_list_sheets','description','text');
   
   create_col_in_table($dbh,'identities','identity_type','varchar');
   create_col_in_table($dbh,'identities','street2','varchar'); 
   
   create_col_in_table($dbh,'data_lists','type','varchar'); 
    
#   create_col_in_table($dbh,'product_fields','in_add_multiple','enum_y_n');
   create_col_in_table($dbh,'textcontents','search_content','text');
   create_col_in_table($dbh,'links','id_textid_url','int');
   
   create_col_in_table($dbh,'data_sheets','lowest_price','float');
   
   create_col_in_table($dbh,'data_sheets','lowest_price_pro','float');
   create_col_in_table($dbh,'data_sheets','count_hits','int');
   create_col_in_table($dbh,'data_sheets','count_sales','int');
   
   create_col_in_table($dbh,'members','id_language','int');
   create_col_in_table($dbh,'orders','invoice_num','varchar'); 
   create_col_in_table($dbh,'orders','invoice_count','int');
   create_col_in_table($dbh,'orders','invoice_year','int');     
   
   create_col_in_table($dbh,'eshop_orders','invoice_num','varchar'); 
   
   create_col_in_table($dbh,'data_fields','visible','enum_n_y');
   create_col_in_table($dbh,'data_sheets','visible','enum_n_y');
   create_col_in_table($dbh,'data_sheets','is_discounted','enum_y_n');
   
   
   
   create_col_in_table($dbh,'data_sheets','custom_promo','enum_y_n'); 
   create_col_in_table($dbh,'data_sheets','custom_new','enum_y_n');
   create_col_in_table($dbh,'data_sheets','id_textid_fulltext','int');    
    
   create_col_in_table($dbh,'order_details','taux_tva','float_0.21');
   create_col_in_table($dbh,'orders','taux_tva','float_0.21');
   create_col_in_table($dbh,'orders','edit_delivery_status_moment','datetime');
   create_col_in_table($dbh,'orders','edit_payment_status_moment','datetime');
   create_col_in_table($dbh,'orders','id_order_status_delivery','int');
   create_col_in_table($dbh,'orders','id_order_status_billing','int');
   create_col_in_table($dbh,'orders','tracking','varchar');
   create_col_in_table($dbh,'orders','tracking_num','varchar');
   create_col_in_table($dbh,'orders','coupon','varchar');
   create_col_in_table($dbh,'orders','total_billing','float');
   create_col_in_table($dbh,'orders','lastname','varchar');
   create_col_in_table($dbh,'orders','firstname','varchar');
   create_col_in_table($dbh,'orders','email','varchar');
   create_col_in_table($dbh,'orders','tel','varchar');
   create_col_in_table($dbh,'orders','company','varchar');
   create_col_in_table($dbh,'orders','commentaire','text');
   create_col_in_table($dbh,'data_list_sheets','type','varchar');
      
   create_col_in_table($dbh,'orders','total0_htva','float');
   create_col_in_table($dbh,'orders','total0_tva','float');
   create_col_in_table($dbh,'orders','total0_tvac','float');
   create_col_in_table($dbh,'orders','total6_htva','float');
   create_col_in_table($dbh,'orders','total6_tva','float');
   create_col_in_table($dbh,'orders','total6_tvac','float');
   create_col_in_table($dbh,'orders','total21_htva','float');
   create_col_in_table($dbh,'orders','total21_tva','float');
   create_col_in_table($dbh,'orders','total21_tvac','float');     
   
   create_col_in_table($dbh,'orders','delivery_civility','varchar');
   create_col_in_table($dbh,'orders','delivery_firstname','varchar');
   create_col_in_table($dbh,'orders','delivery_lastname','varchar');
   create_col_in_table($dbh,'orders','delivery_company','varchar');
   create_col_in_table($dbh,'orders','delivery_street','varchar');
   create_col_in_table($dbh,'orders','delivery_number','varchar');
   create_col_in_table($dbh,'orders','delivery_box','varchar');
   create_col_in_table($dbh,'orders','delivery_city','varchar');
   create_col_in_table($dbh,'orders','delivery_zip','varchar');
   create_col_in_table($dbh,'orders','delivery_country','varchar');
   create_col_in_table($dbh,'orders','delivery_tel1','varchar');
   create_col_in_table($dbh,'orders','delivery_tel2','varchar');
   create_col_in_table($dbh,'orders','delivery_vat','varchar');
   create_col_in_table($dbh,'orders','delivery_fax','varchar');
   create_col_in_table($dbh,'orders','delivery_email','varchar');
   create_col_in_table($dbh,'orders','delivery_rem','varchar');
   
   create_col_in_table($dbh,'orders','billing_civility','varchar');
   create_col_in_table($dbh,'orders','billing_firstname','varchar');
   create_col_in_table($dbh,'orders','billing_lastname','varchar');
   create_col_in_table($dbh,'orders','billing_company','varchar');
   create_col_in_table($dbh,'orders','billing_street','varchar');
   create_col_in_table($dbh,'orders','billing_number','varchar');
   create_col_in_table($dbh,'orders','billing_box','varchar');
   create_col_in_table($dbh,'orders','billing_city','varchar');
   create_col_in_table($dbh,'orders','billing_zip','varchar');
   create_col_in_table($dbh,'orders','billing_country','varchar');
   create_col_in_table($dbh,'orders','billing_tel1','varchar');
   create_col_in_table($dbh,'orders','billing_tel2','varchar');
   create_col_in_table($dbh,'orders','billing_vat','varchar');
   create_col_in_table($dbh,'orders','billing_fax','varchar');
   create_col_in_table($dbh,'orders','billing_email','varchar');
   create_col_in_table($dbh,'orders','billing_rem','varchar');
   create_col_in_table($dbh,'orders','method_billing_name','varchar');
   create_col_in_table($dbh,'orders','method_delivery_name','varchar');
   
   create_col_in_table($dbh,'members','id_tarif_souhaite','int');
      
   
   create_col_in_table($dbh,'orders','token','varchar');   
   
   create_col_in_table($dbh,'countries','tel','varchar');
   create_col_in_table($dbh,'languages','encode_ok','enum_y_n');
   
   create_col_in_table($dbh,'languages','id_member_group','int');
   create_col_in_table($dbh,'data_sheets','ordby','int');
   
    
   create_col_in_table($dbh,'orders','email_sent','int');
   create_col_in_table($dbh,'order_details','pu_htva','float');
   create_col_in_table($dbh,'order_details','reference','varchar');
   create_col_in_table($dbh,'order_details','pu_tvac','float');
   
   create_col_in_table($dbh,'mailings','config','text');
   

   
      create_col_in_table($dbh,'data_search_forms','nr','int');
   
   create_col_in_table($dbh,'pics','pic_name_og','varchar');
   create_col_in_table($dbh,'pics','pic_width_og','int');
   create_col_in_table($dbh,'pics','pic_height_og','int');
   
   create_col_in_table($dbh,'data_families','og_width','int');
      create_col_in_table($dbh,'data_families','resize_on_height','enum_y_n');
   create_col_in_table($dbh,'data_families','resize_on_width','enum_y_n');
   create_col_in_table($dbh,'data_families','id_default_search_form','int'); 
   create_col_in_table($dbh,'data_families','price_tvac','enum_n_y');
   create_col_in_table($dbh,'data_families','id_textid_fiche','int');
   create_col_in_table($dbh,'data_families','id_field_description','int');
   create_col_in_table($dbh,'data_families','id_field_reference','int');
   create_col_in_table($dbh,'data_families','id_field_name','int');
   create_col_in_table($dbh,'data_families','large_width','int');
   create_col_in_table($dbh,'data_families','id_field_shoplocator_street','int');
   create_col_in_table($dbh,'data_families','id_field_shoplocator_zip','int');
   create_col_in_table($dbh,'data_families','id_field_shoplocator_city','int');
   create_col_in_table($dbh,'data_families','id_field_shoplocator_country','int');
   create_col_in_table($dbh,'data_families','id_field_shoplocator_lat','int');
   create_col_in_table($dbh,'data_families','id_field_shoplocator_lon','int');
   create_col_in_table($dbh,'data_families','id_template_detail_page','int');
   create_col_in_table($dbh,'data_families','id_template_detail','int');
   create_col_in_table($dbh,'data_families','id_template_listing','int');
   create_col_in_table($dbh,'data_families','id_template_page','int');
   create_col_in_table($dbh,'data_families','id_template_object','int');
   create_col_in_table($dbh,'data_families','id_textid_meta_title','int');
   create_col_in_table($dbh,'data_families','id_textid_meta_description','int');
   create_col_in_table($dbh,'data_families','id_textid_meta_keywords','int');
   create_col_in_table($dbh,'data_families','id_textid_url_rewriting','int');
   create_col_in_table($dbh,'data_families','id_textid_fiche','int');
   create_col_in_table($dbh,'data_families','id_alt_data_family','int');
   
   
   
   
      create_col_in_table($dbh,'data_lists','id_template_list','int');
   create_col_in_table($dbh,'migc_dataforms_fields','id_pic','int');
   
   create_col_in_table($dbh,'data_crit_listvalues','interne','varchar');
   
      create_col_in_table($dbh,'data_sheets','og_width','int');   
   create_col_in_table($dbh,'data_search_forms','custom_ordby','varchar');
   create_col_in_table($dbh,'orders','post_order_ok','enum_y_n');
   
   create_col_in_table($dbh,'order_details','htva_discount','float');
   create_col_in_table($dbh,'order_details','tvac_discount','float');
   create_col_in_table($dbh,'order_details','subtotal_discounted_htva','float');
   
   
   create_col_in_table($dbh,'data_stock_tarif','discounted','enum_y_n');
   
   
   create_col_in_table($dbh,'data_stock_tarif','st_pu_htva','float');
   create_col_in_table($dbh,'data_stock_tarif','st_pu_tva','float');
   create_col_in_table($dbh,'data_stock_tarif','st_pu_tvac','float');
   
   create_col_in_table($dbh,'data_stock_tarif','st_pu_htva_discount','float');
   create_col_in_table($dbh,'data_stock_tarif','st_pu_tva_discount','float');
   create_col_in_table($dbh,'data_stock_tarif','st_pu_tvac_discount','float');
   
   create_col_in_table($dbh,'data_stock_tarif','st_pu_htva_discounted','float');
   create_col_in_table($dbh,'data_stock_tarif','st_pu_tva_discounted','float');
   create_col_in_table($dbh,'data_stock_tarif','st_pu_tvac_discounted','float');
   
   create_col_in_table($dbh,'data_stock_tarif','id_data_sheet','int');
   create_col_in_table($dbh,'data_stock_tarif','taux_tva','int');
   create_col_in_table($dbh,'members','id_tarif','int');
   
   create_col_in_table($dbh,'order_details','subtotal_discounted_tvac','float');
   
   
   
   create_col_in_table($dbh,'data_sheets','synchro_todel','enum_y_n');
   create_col_in_table($dbh,'data_categories','synchro_todel','enum_y_n');
   create_col_in_table($dbh,'data_categories','code_couleur','varchar');
   
   
   create_col_in_table($dbh,'data_stock','synchro_todel','enum_y_n');
   create_col_in_table($dbh,'data_stock','reference','varchar');
   create_col_in_table($dbh,'data_stock','id_eshop_tva','int');
   create_col_in_table($dbh,'data_lnk_sheets_listvalues','synchro_todel','enum_y_n');
   
   create_col_in_table($dbh,'data_lnk_sheets_listvalues','lnk_stock','int');
   create_col_in_table($dbh,'data_lnk_sheets_listvalues','refresh_stock_moment','datetime');
   
   
   create_col_in_table($dbh,'data_crit_listvalues','synchro_todel','enum_y_n');
   
   
   
   create_col_in_table($dbh,'sitetxt','lg7','text');
   create_col_in_table($dbh,'sitetxt','lg8','text');
   create_col_in_table($dbh,'sitetxt','lg9','text');
   
   create_col_in_table($dbh,'sitetxt_common','lg7','text');
   create_col_in_table($dbh,'sitetxt_common','lg8','text');
   create_col_in_table($dbh,'sitetxt_common','lg9','text');
   
   
   create_col_in_table($dbh,'discount_rules2','col1','varchar');
   create_col_in_table($dbh,'discount_rules2','col2','varchar');
   
   create_col_in_table($dbh,'data_search_forms','id_textid_url_rewriting','int');
   
   create_col_in_table($dbh,'data_families','bebat','varchar');
   create_col_in_table($dbh,'data_families','auvibel','varchar');
   create_col_in_table($dbh,'data_families','recupel','varchar');
   
   create_col_in_table($dbh,'data_list_sheets','id_language','int');
   
   create_col_in_table($dbh,'migc_trad','id','int');
   
   create_col_in_table($dbh,'countries','visible','enum_n_y');
    
   create_col_in_table($dbh,'order_details','id_quotation_option','int');
   create_col_in_table($dbh,'order_details','quotation_value','varchar');
   
   create_col_in_table($dbh,'migc_dataforms_fields','ext','varchar');
   
   create_col_in_table($dbh,'banners_zones','toutes','enum_y_n');
   create_col_in_table($dbh,'banners_zones','url','varchar');
   create_col_in_table($dbh,'banners_zones','effect','varchar');
   create_col_in_table($dbh,'banners_zones','speed','varchar'); 
   create_col_in_table($dbh,'banners_zones','random','enum_y_n');
   create_col_in_table($dbh,'banners_zones','preview','varchar');
   create_col_in_table($dbh,'banners_zones','timeout','int');
   create_col_in_table($dbh,'banners_zones','nb_ban','int_1');
   
#    create_col_in_table($dbh,'gifts','id_member','int');
#     create_col_in_table($dbh,'gifts','email_sent','int'); 
   
   create_col_in_table($dbh,'members','firstname','varchar');
   create_col_in_table($dbh,'members','lastname','varchar');
   create_col_in_table($dbh,'members','company','varchar');
   create_col_in_table($dbh,'members','responsable','varchar');
   create_col_in_table($dbh,'members','infosupp1','varchar');
   create_col_in_table($dbh,'members','infosupp2','varchar');
   
   create_col_in_table($dbh,'shop_delcost_zones_costs','de','float');
   create_col_in_table($dbh,'shop_delcost_zones_costs','a','float');   
  
   create_col_in_table($dbh,'sitetxt','type','varchar');
   create_col_in_table($dbh,'sitetxt','description','text');
   create_col_in_table($dbh,'sitetxt','lg6','text');
   create_col_in_table($dbh,'sitetxt_common','lg6','text');
   
   create_col_in_table($dbh,'users','token','text');
   create_col_in_table($dbh,'pics','lightbox','enum_y_n');
#   create_col_in_table($dbh,'product_stock','ordby','int');
   
   create_col_in_table($dbh,'order_status','ordby','int');
   
#   create_col_in_table($dbh,'datadir_categories','label','varchar');
   
   create_col_in_table($dbh,'data_lnk_sheet_pics','id_textid_name','int');
   create_col_in_table($dbh,'data_lnk_sheet_pics','lg1','enum_y_n');
   create_col_in_table($dbh,'data_lnk_sheet_pics','lg2','enum_y_n');
   create_col_in_table($dbh,'data_lnk_sheet_pics','lg3','enum_y_n');
   create_col_in_table($dbh,'data_lnk_sheet_pics','lg4','enum_y_n');
   create_col_in_table($dbh,'data_lnk_sheet_pics','lg5','enum_y_n');
   create_col_in_table($dbh,'data_lnk_sheet_pics','lg6','enum_y_n');
   create_col_in_table($dbh,'data_lnk_sheet_pics','notice','enum_y_n');
   create_col_in_table($dbh,'data_lnk_sheet_pics','video','enum_y_n');
   


   
   create_col_in_table($dbh,'data_search_forms','method','varchar');
   create_col_in_table($dbh,'data_search_forms','synchro_langue','varchar');
   create_col_in_table($dbh,'data_search_forms','custom_compute','varchar');
   create_col_in_table($dbh,'data_search_forms','generer','enum_y_n');
   create_col_in_table($dbh,'data_search_forms','order_on','varchar');
   create_col_in_table($dbh,'data_search_forms','order_field','varchar');
   create_col_in_table($dbh,'data_search_forms','id_tpl_bread','int');
   
   
   
    
   create_col_in_table($dbh,'data_search_forms','id_data_family','int');  
   
   create_col_in_table($dbh,'data_search_forms','id_template_page','int');                                     
   
   create_col_in_table($dbh,'data_searchs','id_textid_url_rewriting','int');
   create_col_in_table($dbh,'data_stock','tva','float');
   
   create_col_in_table($dbh,'data_searchs','in_sitemap','enum_y_n');
   create_col_in_table($dbh,'data_searchs','in_breadcrumb','enum_n_y');
   create_col_in_table($dbh,'data_searchs','in_autocomplete','enum_y_n');
   
   create_col_in_table($dbh,'data_families','id_textid_default_name_title','int'); 
   
   
   
   create_col_in_table($dbh,'eshop_deliveries','max_weight','float');
   create_col_in_table($dbh,'eshop_deliveries','limit_to_country','varchar');
   
   
     create_col_in_table($dbh,'migc_dataforms','id_textid_email_to','int');

   create_col_in_table($dbh,'migc_dataforms_fields','ext','varchar');
   
      create_col_in_table($dbh,'migc_trad','lg6','text');
   create_col_in_table($dbh,'migc_trad','lg7','text');
   create_col_in_table($dbh,'migc_trad','lg8','text');
   create_col_in_table($dbh,'migc_trad','lg9','text');
   
   create_col_in_table($dbh,'orders','billing_brand','varchar');
   create_col_in_table($dbh,'orders','coupon_text','varchar');
   create_col_in_table($dbh,'orders','coupon_value','float');
   create_col_in_table($dbh,'orders','id_rule','int');
   
   
   
 
   
   create_col_in_table($dbh,'coupons','init_value','float');
   create_col_in_table($dbh,'coupons','value','float');
   create_col_in_table($dbh,'coupons','email','varchar');
   create_col_in_table($dbh,'coupons','visible','enum_y_n');
   create_col_in_table($dbh,'coupons','id_gift','int');
   create_col_in_table($dbh,'migc_datacontainers','confirmed','enum_y_n');
   create_col_in_table($dbh,'migc_trad','type','varchar');
   create_col_in_table($dbh,'shop_delcost_zones_costs','type','varchar');
   create_col_in_table($dbh,'shop_delcost_zones','free_after','float');
   create_col_in_table($dbh,'orders','reference','change_text','CHANGE');
   
   create_col_in_table($dbh,'data_sheets','price_pro','float');
   create_col_in_table($dbh,'data_sheets','price_pro_htva','float');
   create_col_in_table($dbh,'data_sheets','price_discount','float');
   create_col_in_table($dbh,'data_sheets','price_pro_discount','float');
   create_col_in_table($dbh,'data_sheets','discount_yes','enum_y_n');
   create_col_in_table($dbh,'data_sheets','discount_pro_yes','enum_y_n');
   create_col_in_table($dbh,'data_sheets','new','enum_y_n');
   create_col_in_table($dbh,'data_sheets','custom_promo_value_euro','float');
   create_col_in_table($dbh,'data_sheets','custom_promo_value_pourcent','float');
  
   
   create_col_in_table($dbh,'discount_rules2','tarif','int');
   create_col_in_table($dbh,'discount_rules_cart','tarif','int');
   
   create_col_in_table($dbh,'discount_rules_cart','nb_uses_total','int');
   create_col_in_table($dbh,'discount_rules_cart','nb_uses_available','int');
   create_col_in_table($dbh,'discount_rules_cart','nb_uses_person','int');
   
   create_col_in_table($dbh,'data_lnk_sheet_files','id_pic','int');
   create_col_in_table($dbh,'data_lnk_sheet_files','id_pic_pochette','int');
   create_col_in_table($dbh,'eshop_urls','keyword','varchar');  


   create_col_in_table($dbh,'orders','shop_order_status','shop_order_status'); 
   create_col_in_table($dbh,'orders','shop_payment_status','shop_payment_status');
   create_col_in_table($dbh,'orders','shop_delivery_status','shop_delivery_status');
   
    create_col_in_table($dbh,'orders','shop_order_status_moment','datetime'); 
    create_col_in_table($dbh,'orders','shop_payment_status_moment','datetime');
    create_col_in_table($dbh,'orders','shop_delivery_status_moment','datetime');
   
    create_col_in_table($dbh,'eshop_orders','total_qty_expedie','int');
    create_col_in_table($dbh,'eshop_orders','total_qty_restant','int');
    
    create_col_in_table($dbh,'eshop_order_details','detail_qty_expedie','int');
    create_col_in_table($dbh,'eshop_order_details','detail_qty_restant','int');
    create_col_in_table($dbh,'eshop_order_details','detail_qty_restant_ok','enum_y_n');
    create_col_in_table($dbh,'eshop_order_details','nom_commande','varchar');
    
    
   
    create_col_in_table($dbh,'countries','fr','varchar');
    create_col_in_table($dbh,'countries','en','varchar');
    create_col_in_table($dbh,'countries','nl','varchar');
     
    create_col_in_table($dbh,'data_fields','in_filters','enum_y_n');
    
    create_col_in_table($dbh,'data_lists','type','varchar');
    create_col_in_table($dbh,'identities','token','varchar');
    
       create_col_in_table($dbh,'wfw_trad','lg6','text');
   create_col_in_table($dbh,'wfw_trad','lg7','text');
   create_col_in_table($dbh,'wfw_trad','lg8','text');
   create_col_in_table($dbh,'wfw_trad','lg9','text');

   create_col_in_table($dbh,'data_search_forms','in_sitemap','enum_n_y');
   create_col_in_table($dbh,'data_search_forms','allow_robots','enum_n_y');
   create_col_in_table($dbh,'data_searchs','allow_robots','enum_n_y');
   create_col_in_table($dbh,'data_families','in_sitemap','enum_n_y');
   create_col_in_table($dbh,'data_families','allow_robots','enum_n_y');
   create_col_in_table($dbh,'data_families','has_detail','enum_n_y');
   create_col_in_table($dbh,'data_field_listvalues','id_textid_url_ext','int');


   fill_search_content(0);
  
    set_ordby_on_datasheets();
    
#       #KIALA-------------------------------------------------------------------
#     my %methode=%{get_param_name('kiala')};
#     
#     if(!($methode{id} > 0))
#     {
#         my  %methode=();
#         $methode{type}='delivery';
#         $methode{id_textid_name}=insert_text($dbh,'Kiala');
#         $methode{params}=<<"EOH";
# file=>\\'\\',
# name=>\\"kiala\\",
# price_func=>\\"kiala\\",
# EOH
#          $code=inserth_db($dbh,'methodes',\%methode);
#     }
    
#     #FASTSECURED----------------------------------------------------------------
#     my %methode=%{get_param_name('fastsecured')};
#     if(!($methode{id} > 0))
#     {
#         my  %methode=();
#         $methode{type}='delivery';
#         $methode{id_textid_name}=insert_text($dbh,'Fast Secured');
#         $methode{params}=<<"EOH";
# file=>\\'usr/dlv/livraison-fs.txt\\',
# name=>\\"fastsecured\\",
# price_func=>\\"dlv_price_weight\\",
# EOH
#         $code=inserth_db($dbh,'methodes',\%methode);
#     }
#     
#     if($config{default_render_type} eq '')
#     {
#         my %new_config=(); 
#         $new_config{id_role}='1';
#         $new_config{varname}='default_render_type';
#         $new_config{varvalue}='cgi';
#         sql_update_or_insert($dbh,"config",\%new_config,'varname','default_render_type');
#     }
    
    #METHODES DE PAIEMENT:***************************************************** 
    #VIREMENT-------------------------------------------------------------------
    my %methode=%{get_param_name('virement')};
    if(!($methode{id} > 0))
    {
        my  %methode=();
        $methode{type}='billing';
        $methode{id_textid_name}=insert_text($dbh,'Virement bancaire');
        $methode{params}=<<"EOH";
name=>\\"virement",
compte=>\\"000-0000000-00\\",
nom=>\\"Nom\\",
adresse=>\\"Adresse\\",
ville=>\\"Belgique\\",
tel=>\\"\\",
bic=>\\"BIC\\",
iban=>\\"IBAN\\",
tpl=>\\"\\",
\\"stock_linked\\"=>\\n"\\",
EOH
         $code=inserth_db($dbh,'methodes',\%methode);
    }
    
    #OGONE-------------------------------------------------------------------
    my %methode=%{get_param_name('ogone')};
    if(!($methode{id} > 0))
    {
        my  %methode=();
        $methode{type}='billing';
        $methode{visible}='n';
        $methode{id_textid_name}=insert_text($dbh,'Ogone');
        $methode{params}=<<"EOH";
\\"ogone_pspid\\"=>\\"\\",
\\"name\\"=>"ogone",
\\"version\\"=>"2",
\\"ogone_prod_status\\"=>"test",
\\"ogone_sha1in\\"=>\\"\\",
\\"ogone_sha1out\\"=>\\"\\",
\\"ogone_currency\\"=>\\"EUR\\",
\\"ogone_title\\"=>\\"\\",
\\"ogone_bgcolor\\"=>\\"\\",
\\"ogone_txtcolor\\"=>\\"\\",
\\"ogone_tblbgcolor\\"=>\\"\\",
\\"ogone_tbltxtcolor\\"=>\\"\\",
\\"ogone_buttonbgcolor\\"=>\\"\\",
\\"ogone_buttontxtcolor\\"=>\\"\\",
\\"ogone_fonttype\\"=>\\"\\",
\\"prefixe_id_order\\"=>\\"\\",
\\"stock_linked\\"=>\\"o\\",
tpl=>\\"\\"
EOH
         $code=inserth_db($dbh,'methodes',\%methode);
    } 
    
#     #CREDIT AGRICOLE-------------------------------------------------------------------
#     my %methode=%{get_param_name('credit_agricole')};
#     if(!($methode{id} > 0))
#     {
#         my  %methode=();
#         $methode{type}='billing';
#         $methode{visible}='n';
#         $methode{id_textid_name}=insert_text($dbh,'Crédit Agricole');
#         $methode{params}=<<"EOH";
# \\"name\\"=>"credit_agricole\\",
# \\"credit_agricole_mode\\"=>\\"1\\",
# \\"credit_agricole_site\\"=>\\"\\",
# \\"credit_agricole_rang\\"=>\\"98\\",
# \\"credit_agricole_identifiant\\"=>\\"3\\",
# \\"credit_agricole_devise\\"=>\\"978\\",
# \\"credit_agricole_background\\"=>\\"#cccccc\\",
# \\"credit_agricole_langue\\"=>\\"FRA\\",
# \\"credit_agricole_type_carte\\"=>\\"CB\\",
# \\"credit_agricole_button_text\\"=>\\"Payer maintenant\\",
# \\"credit_agricole_ip_ok\\"=>\\"195.101.99.76,195.101.99.77,62.39.109.166,194.50.38.6\\",
# \\"prefixe_id_order\\"=>\\"\\",
# \\"stock_linked\\"=>\\"o\\",
# tpl=>\\"\\"
# EOH
#          $code=inserth_db($dbh,'methodes',\%methode);
#     } 
    
    #PAYPAL-------------------------------------------------------------------
    my %methode=%{get_param_name('paypal')};
#     see(\%methode);
    
    if(!($methode{id} > 0))
    {
        my  %methode=();
        $methode{type}='billing';
        $methode{visible}='n';
        $methode{id_textid_name}=insert_text($dbh,'Paypal');
        $methode{params}=<<"EOH";
\\"paypal_id\\"=>\\'\\',
\\"name\\"=>"paypal",
tpl=>\\"\\",
\\"stock_linked\\"=>\\"o\\",
EOH
          print "insert paypal";
         $code=inserth_db($dbh,'methodes',\%methode);
    }
    
#     #CREE LE MOTEUR par défaut (categories)
#     my %data_search_forms=select_table($dbh,"data_search_forms","","name='Catégories' && id_template=0");
#     if(!($data_search_forms{id} > 0))
#     {
#         my  %data_search_forms=();
#         $data_search_forms{name}='Catégories';
#         my $id_data_search_form=inserth_db($dbh,'data_search_forms',\%data_search_forms);
#         
#         my  %data_searchs=();
#         $data_searchs{id_textid_name}=insert_text($dbh,'Catégories');
#         $data_searchs{type}='input';
#         $data_searchs{targets}='cat';
#         $data_searchs{ordby}='1';
#         $data_searchs{visible}='y';
#         $data_searchs{id_data_search_form}=$id_data_search_form;     
#         inserth_db($dbh,'data_searchs',\%data_searchs);
#         
#         #DONT FORGET TO DO THIS: associer l'id du moteur à la config data : moteur par defaut
#     }
    
#      my @order_status_libelles = (
#       "Paiement annulé",
#       "Commandé",   
#       "Commande payée",
#       "Envoi annulé",
#       "Colis en préparation",   
#       "Colis envoyé"
#       );     
# 
#     
# #     CREATE ORDER STATUS (la table doit exister)
#       my @order_status=get_table($dbh,"order_status");
#       if($#order_status == -1)
#       {
#           my $num = 0;
#           my $type = 'billing';
#           for($i=0;$i<6;$i++)
#           {
#             $num=$i;
#             if($i>2)
#             {
#               $num=$i-3;
#               $type = 'delivery';
#             }
#             
#             my %order_status=();
#             $order_status{ordby}=$i+1;
#             $order_status{num}=$num;
#             $order_status{id_textid_name}=insert_text($dbh,$order_status_libelles[$i]);
#             $order_status{type}=$type;
#             $id_order_status=inserth_db($dbh,'order_status',\%order_status);
#           }
#       }
     
     
#           data::fill_url_rewriting_holes();
#           data::fill_meta_holes();
#           fill_orderdetails_holes();
#           fill_data_sheets_count_sales();
#      fill_pics_holes();

        fill_order_tokens();
#         fill_invoice_nums();
        fill_identities_tokens();
         generate_methode_names();
           generate_order_identities();
#            convert_vat();  
#                     generate_factures_not();
    #      phyterma_link_all_to_fathers();
#       birkenstock_insertinlisting();
#       birkenstock_insertcats();

       fill_sitetxtcommons();
}

# sub fill_pics_holes
# {
#     use Image::Size;
#     my @pics = get_table($dbh,"pics");
#     foreach $pic (@pics)
#     {
#         my %pic = %{$pic};
#         my @cols = ('full','small','mini','medium','og');
#         foreach $col (@cols)
#         {
#              my $filename = '../pics/'.$pic{'pic_name_'.$col};
#              
#              if(-e $filename)
#              {
#                    my( $width, $height ) = imgsize($filename);
#                    if($pic{'pic_width_'.$col} == 0 && $width > 0)
#                    {
#                           $stmt = "UPDATE pics SET pic_width_$col = $width WHERE pic_width_$col = 0 AND id = '$pic{id}'";
# #                         print "<br/><b>$filename</b> Largeur: ".$pic{'pic_width_'.$col}." => ".$width;
# #                         print "<br />$stmt";
#                         $cursor = $dbh->prepare($stmt);
#                         $cursor->execute || suicide($stmt);
#                    }
#                    if($pic{'pic_height_'.$col} == 0 && $height > 0)
#                    {
#                         $stmt = "UPDATE pics SET pic_height_$col = $height WHERE pic_height_$col = 0 AND id = '$pic{id}'";
# #                         print "<br/><b>$filename</b> Hauteur: ".$pic{'pic_height_'.$col}." => ".$height;
# #                         print "<br />$stmt";
#                         $cursor = $dbh->prepare($stmt);
#                         $cursor->execute || suicide($stmt);
#                    }
#              }             
#         }
#     }
# }

# sub fill_invoice_nums
# {
# #     if($config{make_invoices} eq 'y')
# #     {
# #         my @orders = get_table($dbh,"orders","id","order_type = 'order' AND (shop_payment_status = 'paid' OR shop_order_status='new')  ORDER BY order_moment asc",'','','',0);
# #         foreach $order (@orders)
# #         {
# #             my %order = %{$order};
# #             set_next_invoice_num($dbh,\%order);
# #         }
# #     }
# }

sub fill_order_tokens
{
    my @orders = get_table($dbh,"orders","id","token = ''",'','','',0);
    foreach $order (@orders)
    {
        my %order = %{$order};
        my $token = create_token(200);            
        $stmt = "UPDATE orders SET token = '$token' WHERE id = '$order{id}'";
        $cursor = $dbh->prepare($stmt);
        $cursor->execute || suicide($stmt);
    }
}

sub convert_vat
{
#     my @orders = get_table($dbh,"identities","vat,id","vat != ''",'','','',0);
#     foreach $order (@orders)
#     {
#          my %order = %{$order};
#          my $new_vat = $order{vat};
#          $new_vat =~ s/BEFR/FR/g;
#          $new_vat =~ s/BEBE/BE/g;
#          $new_vat =~ s/BEbe/BE/g;
#           $stmt = "UPDATE identities SET vat = '$new_vat' WHERE id = '$order{id}'";
#           $cursor = $dbh->prepare($stmt);
#           $cursor->execute || suicide($stmt);
    
#         my %order = %{$order};
#        if($order{vat} =~ /[A-Za-z]{2}0[0-9]{9}/)
#        {
#              print 1;
#        }
#        else
#        {
#           my $new_vat = $order{vat};
#           $new_vat =~ s/\s//g;
#           $new_vat =~ s/\.//g;
#           $new_vat = 'BE'.$new_vat;
#           
#           $stmt = "UPDATE identities SET vat = '$new_vat' WHERE id = '$order{id}'";
#           $cursor = $dbh->prepare($stmt);
#           $cursor->execute || suicide($stmt);
#           
#           
#        }          
#     }
}


# sub fill_order_references
# {
#     my @orders = get_table($dbh,"orders","id","token = ''",'','','',0);
#     foreach $order (@orders)
#     {
#         my %order = %{$order};
#         my $token = create_token(200);            
#         $stmt = "UPDATE orders SET f1 = concat('ref',id)";
#         $cursor = $dbh->prepare($stmt);
#         $cursor->execute || suicide($stmt);
#     }
# }

sub fill_identities_tokens
{
    my @orders = get_table($dbh,"identities","id","token = ''",'','','',0);
    foreach $order (@orders)
    {
        my %order = %{$order};
        my $token = create_token(200);            
        $stmt = "UPDATE identities SET token = '$token' WHERE id = '$order{id}'";
        $cursor = $dbh->prepare($stmt);
        $cursor->execute || suicide($stmt);
    }
}

sub generate_methode_names
{
    my @orders = get_table($dbh,"orders",""," method_delivery_name = '' OR method_billing_name='' ",'','','',0);
    foreach $order (@orders)
    {
        my %order = %{$order};
        
        my %methode = read_table($dbh,"methodes",$order{id_method_delivery});
        my ($method_delivery_name,$dum) = get_textcontent($dbh,$methode{id_textid_name},$config{default_colg});
        my %methode = read_table($dbh,"methodes",$order{id_method_billing});
        my ($method_billing_name,$dum) = get_textcontent($dbh,$methode{id_textid_name},$config{default_colg});
        
        $method_delivery_name =~ s/\'/\\\'/g;
        $method_billing_name =~ s/\'/\\\'/g;
        $stmt = "UPDATE orders SET method_delivery_name = '$method_delivery_name', method_billing_name = '$method_billing_name' WHERE id = '$order{id}'";
        $cursor = $dbh->prepare($stmt);
        $cursor->execute || suicide($stmt);
    }
}

sub generate_order_identities
{
    my @orders = get_table($dbh,"orders",""," delivery_lastname = '' OR billing_email = ''",'','','',0);
    my @fields = ('civility','firstname','lastname','company','street','number','box','city','zip','country','tel1','tel2','fax','email','rem','vat');
    
    foreach $order (@orders)
    {
        my %order = %{$order};
        
        my %identity = read_table($dbh,"identities",$order{id_identity_billing});
        my %order_identity = ();
        foreach $field (@fields)
        {
            $order_identity{'billing_'.$field} = $identity{$field};
            $order_identity{'billing_'.$field} =~ s/\'/\\\'/g;
        }
        updateh_db($dbh_data,'orders',\%order_identity,"id",$order{id});
        
        my %identity = read_table($dbh,"identities",$order{id_identity_delivery});
        my %order_identity = ();
        foreach $field (@fields)
        {
            $order_identity{'delivery_'.$field} = $identity{$field};
            $order_identity{'delivery_'.$field} =~ s/\'/\\\'/g;
        }
        updateh_db($dbh_data,'orders',\%order_identity,"id",$order{id});
    }
}

# sub generate_factures
# {
#     my @orders = get_table($dbh,"orders","","id = '5658'",'','','',0);
#     foreach $order (@orders)
#     {
#         my %order = %{$order};
#         generate_facture($order{token});        
#     }
# }



sub recompute_order_details
{
#     see();
#     my @orders = get_table($dbh,"order_details","","",'','','',0);
#     foreach $order (@orders)
#     {
#         my %od = %{$order};
#         my %new_od = ();
#         $new_od{htva_discount} = $od{tvac_discount} / (1+$od{taux_tva});
#         $new_od{subtotal_discounted_htva} = $od{subtotal_htva} + $new_od{htva_discount};
#         updateh_db($dbh_data,'order_details',\%new_od,"id",$od{id});
#     }
}


sub fill_orderdetails_holes
{
    my @orders = get_table($dbh,"orders","","",'','','',0);
    foreach $order (@orders)
    {
        my %order = %{$order};
        my %nb_order_details = select_table($dbh,"order_details","count(id) as nb","id_order='$order{id}'");
        if($nb_order_details{nb} > 0 && $order{total_discount_tvac} < 0)
        {
            my $discount_tvac = $order{total_discount_tvac} / $nb_order_details{nb};
            
            $stmt = "UPDATE order_details SET subtotal_discounted_tvac = subtotal_tvac + $discount_tvac WHERE id_order = '$order{id}'";
            $cursor = $dbh->prepare($stmt);
            $cursor->execute || suicide($stmt);
        }
    }
}


sub fill_data_sheets_count_sales
{
    my @sales = get_table($dbh,"order_details","id_product_sheet, sum( qty ) AS total"," 1 GROUP BY id_product_sheet",'','','',0);
    foreach $sale (@sales)
    {
        my %sale = %{$sale};
        if($sale{total} > 0)
        {
            $stmt = "UPDATE data_sheets SET count_sales='$sale{total}' WHERE id=$sale{id_product_sheet}";
            $cursor = $dbh->prepare($stmt);
            $cursor->execute || suicide($stmt);
        }
    }
}

sub set_ordby_on_datasheets
{
      my @data_families = get_table($dbh,"data_families");
      foreach $data_family (@data_families)
      {
          my %data_family = %{$data_family};
          my @data_sheets = get_table($dbh,"data_sheets","","id_data_family='$data_family{id}' order by id desc");
          my $ordby = 1;
          foreach $data_sheet (@data_sheets)
          {
              my %data_sheet = %{$data_sheet};
              if($data_sheet{ordby} == 0)
              {
                  $stmt = "UPDATE data_sheets SET ordby='$ordby' WHERE id=$data_sheet{id} AND ordby = '0'";
                  $cursor = $dbh->prepare($stmt);
                  $cursor->execute || suicide($stmt);
              }
              $ordby++;
          }
      }
}

sub phyterma_link_all_to_fathers
{
    my @data_sheets = get_table($dbh,"data_sheets");
    foreach $data_sheet (@data_sheets)
    {
        my %data_sheet = %{$data_sheet};
        my %family = read_table($dbh,"data_families",$data_sheet{id_data_family});
        my $id_data_sheet = $data_sheet{id};
        
        my @data_lnk_sheets_categories=get_table($dbh,"data_lnk_sheets_categories lnk, data_categories cat","","id_data_category = cat.id AND id_data_sheet='$id_data_sheet'",'','','',0);        
        my @cats_to_add = ();
        foreach $lcat (@data_lnk_sheets_categories)
        {
            my %lcat=%{$lcat};
            my $id_father =$lcat{id_father}; 
            
            my %father = read_table($dbh,"data_categories cat","$id_father");
            if($father{id} > 0)
            {
                push @cats_to_add, $father{id};
            }
        }
        foreach $cat_to_add (@cats_to_add)
        {
           my %data_lnk_sheets_categories=();
           $data_lnk_sheets_categories{id_data_sheet} = $id_data_sheet;
           $data_lnk_sheets_categories{id_data_category} = $cat_to_add;
           $data_lnk_sheets_categories{id_data_family} = $family{id};
           
           $stmt = "SELECT MAX(ordby)+1 FROM data_lnk_sheets_categories WHERE id_data_category=$cat_to_add";
           $cursor = $dbh->prepare($stmt);
           $cursor->execute or suicide("error execute : $DBI::errstr [$stmt]\n");
           my ($ordbymax) = $cursor->fetchrow_array;
           if ($ordbymax eq "") { $ordbymax = 1;} 
           
           $data_lnk_sheets_categories{ordby} = $ordbymax;
           
           sql_update_or_insert($dbh,"data_lnk_sheets_categories",\%data_lnk_sheets_categories,'','',"id_data_sheet=$id_data_sheet AND id_data_category=$cat_to_add");
        }
    }
}

sub birkenstock_insertinlisting
{
     print "<br />BEGIN birkenstock_insertcats";
    
    $stmt = "UPDATE data_sheets SET f7='n'";
    $cursor = $dbh->prepare($stmt);
    $cursor->execute || suicide($stmt);
    
    my @data_sheets = get_table($dbh,"data_sheets","","1 group by f2,f3 order by f2,f3",'','','',0);
    foreach $data_sheet (@data_sheets)
    {
        my %data_sheet = %{$data_sheet};
        $stmt = "UPDATE data_sheets SET f7='y' WHERE id=$data_sheet{id}";
        $cursor = $dbh->prepare($stmt);
        $cursor->execute || suicide($stmt);
    }
    
    print "<br />END";



}
sub birkenstock_insertcats
{
    
    print "<br />BEGIN HOMMES";
    #HOMMES = cat 20 field 9
    my $cat = 20;
    my $field = 9;
    my @data_sheets = get_table($dbh,"data_sheets","","id_data_family='1' AND f$field='y' order by id desc",'','','',0);
    foreach $data_sheet (@data_sheets)
    {
        my %data_sheet = %{$data_sheet};
        my %check = select_table($dbh,"data_lnk_sheets_categories","","id_data_category='$cat' and id_data_sheet='$data_sheet{id}'",'','',0);
        if($check{id} > 0)
        {
        }
        else
        {
            my  %lnk=();
            $lnk{id_data_sheet}=$data_sheet{id};
            $lnk{id_data_category}=$cat;
            inserth_db($dbh,'data_lnk_sheets_categories',\%lnk);
            see(\%lnk);
        }
    }
    
    print "<br />BEGIN FEMMES";
    #HOMMES = cat 20 field 9
    my $cat = 21;
    my $field = 10;
    my @data_sheets = get_table($dbh,"data_sheets","","id_data_family='1' AND f$field='y' order by id desc",'','','',0);
    foreach $data_sheet (@data_sheets)
    {
        my %data_sheet = %{$data_sheet};
        my %check = select_table($dbh,"data_lnk_sheets_categories","","id_data_category='$cat' and id_data_sheet='$data_sheet{id}'",'','',0);
        if($check{id} > 0)
        {
        }
        else
        {
            my  %lnk=();
            $lnk{id_data_sheet}=$data_sheet{id};
            $lnk{id_data_category}=$cat;
            inserth_db($dbh,'data_lnk_sheets_categories',\%lnk);
            see(\%lnk);
        }
    }
    
    print "<br />BEGIN ENFANTS";
    #HOMMES = cat 20 field 9
    my $cat = 22;
    my $field = 11;
    my @data_sheets = get_table($dbh,"data_sheets","","id_data_family='1' AND f$field='y' order by id desc",'','','',0);
    foreach $data_sheet (@data_sheets)
    {
        my %data_sheet = %{$data_sheet};
        my %check = select_table($dbh,"data_lnk_sheets_categories","","id_data_category='$cat' and id_data_sheet='$data_sheet{id}'",'','',0);
        if($check{id} > 0)
        {
        }
        else
        {
            my  %lnk=();
            $lnk{id_data_sheet}=$data_sheet{id};
            $lnk{id_data_category}=$cat;
            inserth_db($dbh,'data_lnk_sheets_categories',\%lnk);
            see(\%lnk);
        }
    }
    
    print "<br />BEGIN TOUS";
    #HOMMES = cat 20 field 9
    my $cat = 23;
    my @data_sheets = get_table($dbh,"data_sheets","","id_data_family='1' order by id desc",'','','',0);
    foreach $data_sheet (@data_sheets)
    {
        my %data_sheet = %{$data_sheet};
        my %check = select_table($dbh,"data_lnk_sheets_categories","","id_data_category='$cat' and id_data_sheet='$data_sheet{id}'",'','',0);
        if($check{id} > 0)
        {
        }
        else
        {
            my  %lnk=();
            $lnk{id_data_sheet}=$data_sheet{id};
            $lnk{id_data_category}=$cat;
            inserth_db($dbh,'data_lnk_sheets_categories',\%lnk);
            see(\%lnk);
        }
    }
    
    print "<br />END";
}


#*****************************************************************************************
#GET LISTBOX
#*****************************************************************************************
sub get_listbox
{
    my $table=$_[0] || "";
    my $id=$_[1] || "";
    my $label=$_[2] || "";
    my $field=$_[3] || "";
    my $selected_val=$_[4] || "";
    my $select=$_[5] || "*";
    my $select_id=$_[6] || "";
    my $where=$_[7] || "";
    my $pas_aucun=$_[8] || "n";
    my $debug = $_[9] || 0;
    
    my $aucun=<<"EOH";
      <option value="">Aucun</option>
EOH
    if($pas_aucun eq 'o')
    {
        $aucun="";
    }
    
#      see();
    if($table ne "" && $id ne "" && $label ne "" && $field ne "")
    {
          my $listbox=<<"EOH";
              <select name="$field" id="$select_id" class="inline_save select_$field">$aucun             
EOH
         
          my @data=get_table($dbh,$table,"$select","$where","$label","","",$debug);
          for($i_listbox=0;$i_listbox<$#data+1;$i_listbox++)
          {
              my ($f1,$f2,$f3,$f4) = split (/,/,$label);
              my ($id1,$id2) = split (/,/,$id);
              if($debug)
              {
                  print "ID:[$id]";
              }
              my $val_id=$data[$i_listbox]{$id1};
              if($id2 ne "")
              {
                
                $val_id.='______'.$data[$i_listbox]{$id2};
              }
              
              my $selected="";
#               print "[$selected_val]=[$data[$i_listbox]{$id}],";
              if($selected_val eq $data[$i_listbox]{$id1})
              {
                  $selected=<<"EOH";
                   selected = "selected"                
EOH
              }
              $listbox.=<<"EOH";
              <option value="$val_id" $selected>$data[$i_listbox]{$f1} $data[$i_listbox]{$f2} $data[$i_listbox]{$f3} $data[$i_listbox]{$f4}</option>
EOH
          }    
          
          $listbox.=<<"EOH";
              </select>       
EOH
          return $listbox;
          exit;
          
    }
    else
    {
        return "missing data: [$table][$id][$label][$field]";
    }  
}

sub fill_search_content  
{
  my $est_actif=$_[0] || 0;
  if($est_actif)
  {
  #FILL SEARCH CONTENT---------------------------------------------------------
  my @textcontents=get_table($dbh,"textcontents","*");
  for($i;$i<$#textcontents;$i++)
  {
     my $content=$textcontents[$i]{content};
     my $search_content=$content;
     use HTML::Entities;
     
     $search_content =~ s/&rsquo;/'/g;
     $search_content =~ s/&ugrave;/u/g;
     $search_content =~ s/&oelig;/oe/g;
     
     $search_content=decode_entities($search_content);
     $search_content=remove_accents_from($search_content);
     
     if($textcontents[$i]{id} > 0 && $search_content ne "")
     {
         $search_content =~ s/\'/\\\'/g;
         
         $stmt = "UPDATE textcontents SET search_content='$search_content' WHERE id=$textcontents[$i]{id}";
         $cursor = $dbh->prepare($stmt);
         $cursor->execute || suicide($stmt);
     }
   }
  }   
}

sub create_col_in_table
{
  my $dbh=$_[0];
  my $table=$_[1];
  my $col=$_[2];
  my $type=$_[3];
  my $action=$_[4] || "ADD";
  
  
  
  
  my $type_stmt = "";
  
  if($type eq 'enum_y_n')
  {
     $type_stmt=" ENUM( 'y', 'n' ) NOT NULL DEFAULT 'n' ";
  }
  elsif($type eq 'enum_n_y')
  {
     $type_stmt=" ENUM( 'y', 'n' ) NOT NULL DEFAULT 'y' ";
  }
  elsif($type eq 'text')
  {
     $type_stmt=" TEXT NOT NULL ";
  }
  elsif($type eq 'change_text')
  {
     $type_stmt=" TEXT CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL  ";
  }
  elsif($type eq 'datetime')
  {
     $type_stmt=" DATETIME NOT NULL ";
  }
  elsif($type eq 'date')
  {
     $type_stmt=" DATE NOT NULL ";
  }
  elsif($type eq 'time')
  {
     $type_stmt=" TIME NOT NULL ";
  }
  elsif($type eq 'int')
  {
     $type_stmt=" INT NOT NULL ";
  }
  elsif($type eq 'int_1')
  {
     $type_stmt=" INT NOT NULL  DEFAULT '1'  ";  
  }
  elsif($type eq 'varchar')
  {
     $type_stmt=" VARCHAR( 255 ) NOT NULL  ";
  }
  elsif($type eq 'float')
  {
     $type_stmt=" FLOAT NOT NULL  ";  
  }
  elsif($type eq 'float_0.21')
  {
     $type_stmt=" FLOAT NOT NULL DEFAULT '0.21'  ";  
  }
  elsif($type eq 'shop_order_status')
  {
     $type_stmt=" ENUM( 'new', 'begin', 'current', 'finished', 'unfinished', 'cancelled' ) NOT NULL DEFAULT 'new' AFTER `id`  ";  
  }
  elsif($type eq 'shop_payment_status')
  {
     $type_stmt=" ENUM( 'wait_payment', 'captured', 'paid', 'repaid', 'cancelled' ) NOT NULL DEFAULT 'wait_payment' AFTER `shop_order_status`  ";  
  }
  elsif($type eq 'shop_delivery_status')
  {
     $type_stmt=" ENUM( 'current', 'ready', 'partial_sent', 'full_sent', 'cancelled','ready_to_take' ) NOT NULL DEFAULT 'current' AFTER `shop_payment_status`   ";  
  }
  elsif($type eq 'longtext')
  {
	$type_stmt =" longtext NOT NULL ";
  }
  my @test=get_describe($dbh,$table);
  if($#test == -1)
  {
      return 0;
  }
  for($t=0;$t<$#test+1;$t++)
  {
      my %line=%{$test[$t]};
      if($line{Field} eq $col)
      {
        return 0;
      }
  }
  my $stmt = "ALTER TABLE `$table` $action `$col` $type_stmt";
  my $cursor = $dbh->prepare($stmt);
  my $rc = $cursor->execute;
  if (!defined $rc) 
  {
      see();
      print "[$stmt]";
      exit;   
  }
  return 1; 
}
#*******************************************************************************
# GET_CHECKBOX
#*******************************************************************************
sub get_checkbox
{
   my $name=$_[0];
   my $value=$_[1];
   my $yes_value=$_[2] || 'y';
   
   if($value eq $yes_value)
   {
      return <<"EOH";
     <input type="checkbox" name="$name" value="$yes_value" checked="checked" />
EOH
   }
   else
   {
     return <<"EOH";
     <input type="checkbox" name="$name" value="$yes_value" />
EOH
   }
}

sub fill_sitetxtcommons
{
    my @keywords=(
    'cart_fulldelivery_phrase',
    'cart_sstotalhtva_phrase',
    'cart_sstotaltvac_phrase',
    'cart_remise',
    'cart_recalculer',
    'invoice2_header',
    'invoice2_phone',
    'invoice2_fax',
    'invoice2_email',
    'invoice2_web',
    'invoice2_tva',
    'invoice2_iban',
    'invoice2_banque',
    'invoice2_bic',
    'invoice2_remarque',
    'invoice2_header_infosfacture',
    'invoice2_facture_date',
    'invoice2_facture_num',
    'invoice2_facture_numcommande',
    'invoice2_facture_numclient',
    'invoice2_facture_methpaiement',
    'invoice2_facture_methlivraison',
    'invoice2_header_adresse_facturation',
    'invoice2_header_adresse_livraison',
    'invoice2_header_adresse_remarque',
    'invoice2_header_detail',
    'invoice2_header_articles',
    'invoice2_header_puhtva',
    'invoice2_header_txtva', 
    'invoice2_header_putvac',
    'invoice2_header_qty',
    'invoice2_header_tothtva',
    'invoice2_header_tottvac',
    'invoice2_header_remise',
    'invoice2_remise',
    'invoice2_fraisports',
    'invoice2_fraisadmin',
    'invoice2_totalremiseshtva',
    'invoice2_totalremisestvac',
    'invoice2_totalhtva',
    'invoice2_totaltvac',
    'invoice2_totaltva21',
    'invoice2_totalttc',
    'invoice2_titlefacture',
    'shop_order_status_new',
    'shop_order_status_begin',
    'shop_order_status_unfinished',
    'shop_order_status_current',
    'shop_order_status_finished',
    'shop_order_status_cancelled',
    'shop_payment_status_wait_payment',
    'shop_payment_status_captured',
    'shop_payment_status_paid',
    'shop_payment_status_repaid',
    'shop_payment_status_cancelled',
    'shop_delivery_status_current',
    'shop_delivery_status_ready',
    'shop_delivery_status_partial_sent',
    'shop_delivery_status_full_sent',
    'shop_delivery_status_cancelled',
    'shop_delivery_status_ready_to_take'
    
    
    );
    my @words=(
    'Frais de ports pleins',
    'Sous total HTVA hors remise',
    'Sous total TVAC hors remise',
    'Remise',
    'Recalculer',
    'Récapitulatif de la commande',
    'Tél',
    'Fax',
    'Email',
    'Web',
    'TVA',
    'IBAN',
    'Banque',
    'BIC',
    'Remarque',
    'Informations sur la facture',
    'Date de facture',
    'N° de facture',
    'N° de commande',
    'Votre n° client',
    'Méthode de livraison',
    'Méthode de paiement',
    'Adresse de facturation',
    'Adresse de livraison',
    'Remarque',
    'Détail sur votre commande',
    'Article(s)',
    'PU HTVA',
    'TX TVA',
    'PU TVAC',
    'QTE',
    'TOT HTVA',
    'TOT TVAC',
    'Remise',
    'Remise',
    'Frais de ports',
    'Frais administratifs',
    'Total des remises HTVA sur votre commande',
    'Total des remises TVAC sur votre commande',
    'Total HTVA',
    'Total Remises TVAC',
    'Total TVA à 21%',
    'Total TTC à payer',
    'Facture',
    'Nouvelle',
    'Panier',
    'Non terminée',
    'En cours',
    'Terminée',
    'Annulée',
    'En attente de paiement',
    'Paiement capturé',
    'Payée',
    'Remboursée',
    'Paiement annulé',
    'Préparation en cours',
    'Prête pour expédition',
    'Partiellement envoyée',
    'Envoyée',
    'Envoi annulé',
    'Prête pour enlèvement'
    
    );
    
    my @words_2 = (
    'Full delivery costs',
    'Subtotal excluding VAT without discount',
    'Subtotal including VAT without discount',
    'Discount',
'Recalculate',
'Order summary',
'Pho',
'Fax',
'E-mail',
'Web',
'VAT',
'IBAN',
'Bank',
'BIC',
'Remark',
'Bill Information',
'Invoice Date',
'Invoice N',
'Order N',
'Your Customer N',
'Delivery Method',
'Payment method',
'Billing address',
'Delivery address',
'remark',
'Details of your order',
'Item (s)',
'PR VATEX',
'VAT',
'PR VATIN',
'QTY',
'TOT VATEX',
'TOT VATIN',
'Discount',
'Discount',
'Shipping',
'Administrative costs',
'Total VAT rebates on your order',
'Total VAT rebates on your order',
'total VAT',
'Total VAT Rebates',
'Total VAT to 21%',
'Total tax payable',
'Invoice',
'New',
'Cart',
'Incomplete',
'Current',
'Completed',
'Cancelled',
'Payment Pending',
'Payment captured',
'Paid',
'Refunded',
'Payment canceled',
'Work in progress',
'Ready for shipping',
'Partially sent',
'Sent',
'Sending canceled',
'Ready for pickup'
    );
    
    
    my @words_3 = (
        'Frais de ports pleins',
'Subtotaal excl. BTW zonder vervanging',
    'Subtotaal inc. BTW zonder vervanging',    
    'Remise',
'herberekenen',    
'Bestel samenvatting',
'Tel',
'Fax',
'E-mail',
'Web',
'BTW',
'IBAN',
'Bank',
'BIC',
'Opmerking',
'Bill Informatie',
'Factuurdatum',
'Factuurnummer',
'Bestelnummer',
'Uw klantnummer',
'Levering Wijze',
'Betalingswijze',
'Factuuradres',
'Afleveradres',
'Opmerking',
'Details van uw bestelling',
'Item (s)',
'Prijs',
'BTW',
'Prijs BTW',
'Aant.',
'Tot inc BTW',
'Tot inc BTW',
'Korting',
'Korting',
'Scheepvaart',
'Administratieve kosten',
'Totaal BTW kortingen op uw bestelling',
'Totaal BTW kortingen op uw bestelling',
'Totaal BTW',
'Totaal BTW Kortingen',
'Totaal BTW naar 21%',
'Totaal te betalen belasting',
'Factuur',
'Nieuw',
'Winkelwagen',
'Incomplete',
'Lopende',
'Voltooid',
'Geannuleerd',
'In afwachting van betaling',
'Betaling gevangen',
'Betaald',
'Terugbetaald',
'Betaling geannuleerd',
'Voorbereiding in progress',
'Klaar voor verzending',
'Meestal verzenden',
'Verzenden',
'Bezig met verzenden geannuleerd',
'Klaar voor ontvoering'
);
    
    my $i = 0;
    foreach my $keyword (@keywords)
    {
        my %check = select_table($dbh,"sitetxt_common","","keyword='$keyword'",'','',0);
        if($check{id} > 0)
        {
        }
        else
        {
            my  %lnk=();
            $lnk{keyword}=$keyword;
            $lnk{lg1}=$words[$i];
            $lnk{lg2}=$words_2[$i];
            $lnk{lg3}=$words_3[$i];
            inserth_db($dbh,'sitetxt_common',\%lnk);
        }
        $i++;
    }
}


