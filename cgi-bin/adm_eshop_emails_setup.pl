#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;


         # migc translations

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################  CODE DU PROGRAMME   ######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();
$dm_cfg{customtitle} = "Gestion des revues";
my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dbh_data=$dbh;
$dm_cfg{trad} = 1;
$dm_cfg{file_prefixe} = 'EM';
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{hide_id} = 1;
$dm_cfg{table_name} = "eshop_emails_setup";
$dm_cfg{default_ordby} = "id";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{after_upload_ref} = \&after_upload;

$dm_cfg{after_add_ref} = \&after_add;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_eshop_emails_setup.pl?";

$dm_cfg{hiddp} = <<"EOH";

EOH



@dm_nav =
(
    {
        'tab'=>'tab0',
		'type'=>'tab',
        'title'=>'Configuration générale'
    },
	{
        'tab'=>'tab1',
		'type'=>'tab',
        'title'=>"Email d'inscription"
    }
	,
	{
        'tab'=>'tab2',
		'type'=>'tab',
        'title'=>'Email de bienvenue newsletter'
    }
	,
	{
        'tab'=>'tab3',
		'type'=>'tab',
        'title'=>'Email commande expédiée'
    }
	,
	{
        'tab'=>'tab4',
		'type'=>'tab',
        'title'=>'Email confirmation commande'
    }
	,
	{
        'tab'=>'tab5',
		'type'=>'tab',
        'title'=>'Email facture Pro Forma'
    }
	,
	{
        'tab'=>'tab6',
		'type'=>'tab',
        'title'=>'Email remerciement'
    }
	,
	{
        'tab'=>'tab7',
		'type'=>'tab',
        'title'=>'Email relance de panier'
    }
	,
	{
        'tab'=>'tab8',
		'type'=>'tab',
        'title'=>'Email relance de paiement'
    }
	,
	{
        'tab'=>'tab9',
		'type'=>'tab',
        'title'=>'Gestion des couleurs'
    }
    ,
    {
        'tab'=>'tab10',
        'type'=>'tab',
        'title'=>'Email de facture PDF'
    }
    ,
	);


###############################################################################
# Config de la taille des images à uploader
################################################################################

%upload_config = (
  # Pour l'image du mail de remerciement
  mini_height => "331",  
  mini_width  =>  "272",
  # Pour le logo
  medium_height => "218",
  medium_width  => "218",
  # Pour les blocs publicitaire
  large_height => "700",
  large_width  => "700",

);

###############################################################################
# Hash des Elements de type ENUM en DB
################################################################################

my %merci_coupon_type = (
    eur => "€",
    perc => "%",
);




###############################################################################
# DESCRIPTION DES CHAMPS QUI VONT ETRE RECUPERE EN DB
################################################################################

%dm_dfl = (   
    '1001/disabled_emailing'=> 
   {
        'title'      =>'Désactiver tous l\'emailing',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab0",
    }, 
    '1002/id_pic'=> 
    {
        'title'=>"Logo",
        'fieldtype'=>'files_admin',
        'disable_add'=>0,
        'msg'=>'Cliquez <b>ici</b> pour parcourir votre ordinateur ou déposez directement des photos dans ce cadre.',
        'tab' => "tab0",
    }
    ,
    '1003/facebook_link_textid'=> 
   {
        'title'     =>'Lien vers la page Facebook',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },  

    '1004/twitter_link_textid'=> 
   {
        'title'     =>'Lien vers la page Twitter',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
    '1005/google_link_textid'=> 
   {
        'title'     =>'Lien vers la page Google',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
    '1006/related_items_textid'=> 
   {
        'title'     =>'Titre des articles proposés',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },

    
     '1007/header_1_textid'=> 
    {
        'title'     =>'Texte du lien d\'entête 1',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
     '1008/header_1_link_textid'=> 
    {
        'title'     =>'Url du lien d\'entête 1',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
    '1009/header_2_textid'=> 
    {
        'title'     =>'Texte du lien d\'entête 2',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
     '1010/header_2_link_textid'=> 
    {
        'title'     =>'Url du lien d\'entête 2',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
    '1011/header_3_textid'=> 
    {
        'title'     =>'Texte du lien d\'entête 3',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
     '1012/header_3_link_textid'=> 
    {
        'title'     =>'Url du lien d\'entête 3',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
    '1013/header_4_textid'=> 
    {
        'title'     =>'Texte du lien d\'entête 4',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
    '1014/header_4_link_textid'=> 
    {
        'title'     =>'Url du lien d\'entête 4',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
    '1015/header_5_textid'=> 
    {
        'title'     =>'Texte du lien d\'entête 5',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
     '1016/header_5_link_textid'=> 
    {
        'title'     =>'Url du lien d\'entête 5',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
    '1017/site_url_textid'=> 
    {
        'title'     =>'Url de la boutique',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
    '1018/contact_email_textid'=> 
    {
        'title'     =>'Texte pour contacter le service client',
        'fieldtype' =>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
    '1018/signature_textid'=> 
    {
        'title'     =>'Signature des emails',
        'fieldtype' =>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab0",
    },
	# ,
    # '18a/has_detail'=> 
    # {
        # 'title'      =>'Fiche détail activée',
        # 'fieldtype'  =>'checkbox',
        # 'checkedval' => 'y'
    # },
    
 
    # INSCRIPTION
	'1019/disabled_subscribe'=> 
    {
        'title'      =>'Désactiver l\'emailing d\'inscription',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab1",
    },
    '1019/subscribe_send_copy'=> 
   {
        'title'      =>'Je souhaite recevoir une copie',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab1",
    },
    '1019/subscribe_subject_textid'=> 
    {
        'title'     =>'Objet du message',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab1",
    },
    '1019/subscribe_title_textid'=> 
    {
        'title'     =>'Titre',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab1",
    },
    '1019/subscribe_content_textid'=> 
    {
        'title'     =>'Contenu du mail d\'inscription',
        'fieldtype' =>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab1",
    },
	
	
	
	
     
    ########## CONFIG EMAIL BIENVENUE NEWSLETTER ##########  
    '1020/disabled_bienvenue'=> 
   {
        'title'      =>'Désactiver l\'emailing de bienvenue',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab2",
    }, 
    '1021/bienvenue_send_copy'=> 
   {
        'title'      =>'Je souhaite recevoir une copie',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab2",
    },
    '1021/bienvenue_subject_textid'=> 
    {
        'title'     =>'Objet du message',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab2",
    },
    '1022/bienvenue_title_textid'=> 
    {
        'title'     =>'Titre',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab2",
    },
    '1023/bienvenue_subtitle_textid'=> 
    {
        'title'     =>'Titre des avantages de la newsletter',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab2",
    },  
    '1024/bienvenue_list_textid'=> 
    {
        'title'     =>'Liste des avantages de la newsletter',
        'fieldtype' =>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab2",
    },
    '1025/bienvenue_content_textid'=> 
    {
        'title'     =>'Contenu de la newsletter',
        'fieldtype' =>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab2",
    },

    # '1026/bienvenue_pub_id_pic'=> 
    # {
    #     'title'     =>'Image publicitaire',
    #     'fieldtype' =>'file',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    #     'tab' => "tab2",
    # },
    # '1027/bienvenue_pub_link_textid'=> 
    # {
    #     'title'     =>'Lien de l\'image publicitaire',
    #     'fieldtype' =>'text_id',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    #     'tab' => "tab2",
    # },
    # '1028/bienvenue_reference_1'=> 
    # {
    #     'title'     =>'Référence du produit 1',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    #     'tab' => "tab2",
    # },
    # '1029/bienvenue_id_data_sheet_1'=> 
    # {
    #     'title'     =>'Id de la data_sheet',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    #     'tab' => "tab2",
    # },
    # '1030/bienvenue_product_name_1_textid'=> 
    # {
    #     'title'     =>'Nom du produit 1',
    #     'fieldtype' =>'text_id',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '28/bienvenue_product_full_price_1'=> 
    # {
    #     'title'     =>'Prix du produit 1',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '29/bienvenue_product_discount_price_1'=> 
    # {
    #     'title'     =>'Prix barré du produit 1',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1031/bienvenue_reference_2'=> 
    # {
    #     'title'     =>'Référence du produit 2',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1032/bienvenue_id_data_sheet_2'=> 
    # {
    #     'title'     =>'Id de la data_sheet',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1033/bienvenue_product_name_2_textid'=> 
    # {
    #     'title'     =>'Nom du produit 2',
    #     'fieldtype' =>'text_id',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '33/bienvenue_product_full_price_2'=> 
    # {
    #     'title'     =>'Prix du produit 2',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '34/bienvenue_product_discount_price_2'=> 
    # {
    #     'title'     =>'Prix barré du produit 2',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1034/bienvenue_reference_3'=> 
    # {
    #     'title'     =>'Référence du produit 3',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1035/bienvenue_id_data_sheet_3'=> 
    # {
    #     'title'     =>'Id de la data_sheet',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1036/bienvenue_product_name_3_textid'=> 
    # {
    #     'title'     =>'Nom du produit 3',
    #     'fieldtype' =>'text_id',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '38/bienvenue_product_full_price_3'=> 
    # {
    #     'title'     =>'Prix du produit 3',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '39/bienvenue_product_discount_price_3'=> 
    # {
    #     'title'     =>'Prix barré du produit 3',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1040/bienvenue_reference_4'=> 
    # {
    #     'title'     =>'Référence du produit 4',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1041/bienvenue_id_data_sheet_4'=> 
    # {
    #     'title'     =>'Id de la data_sheet',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1042/bienvenue_product_name_4_textid'=> 
    # {
    #     'title'     =>'Nom du produit 4',
    #     'fieldtype' =>'text_id',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '43/bienvenue_product_full_price_4'=> 
    # {
    #     'title'     =>'Prix du produit 4',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '44/bienvenue_product_discount_price_4'=> 
    # {
    #     'title'     =>'Prix barré du produit 4',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    ########## CONFIG EMAIL COMMANDE EXPEDIEE NEWSLETTER ##########  
    '1043/disabled_expediee'=> 
   {
        'title'      =>'Désactiver l\'emailing des commandes expédiées',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab3",
    },
    '1045/expediee_send_copy'=> 
   {
        'title'      =>'Je souhaite recevoir une copie',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab3",
    }, 
    '1046/expediee_subject_textid'=> 
    {
        'title'     =>'Objet du message',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab3",
    },
    '1047/expediee_title_textid'=> 
    {
        'title'     =>'Titre',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab3",
    },
    '1048/expediee_content_textid'=> 
    {
        'title'     =>'Contenu de du mail',
        'fieldtype' =>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab3",
    },
    '1049/expediee_code_suivi_content_textid'=> 
    {
        'title'     =>'Explication du code de suivi',
        'fieldtype' =>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab3",
    },
    '1050/expediee_products_send_content_textid'=> 
    {
        'title'     =>'Texte concernant les produits envoyés',
        'fieldtype' =>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab3",
    },
    '1051/expediee_contact_textid'=> 
    {
        'title'     =>'Texte de remerciement',
        'fieldtype' =>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab3",
    },
    # '1052/expediee_reference_1'=> 
    # {
    #     'title'     =>'Référence du produit 1',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1053/expediee_id_data_sheet_1'=> 
    # {
    #     'title'     =>'Id de la data_sheet',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1054/expediee_product_name_1_textid'=> 
    # {
    #     'title'     =>'Nom du produit 1',
    #     'fieldtype' =>'text_id',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '55/expediee_product_full_price_1'=> 
    # {
    #     'title'     =>'Prix du produit 1',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '56/expediee_product_discount_price_1'=> 
    # {
    #     'title'     =>'Prix barré du produit 1',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1057/expediee_reference_2'=> 
    # {
    #     'title'     =>'Référence du produit 2',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1058/expediee_id_data_sheet_2'=> 
    # {
    #     'title'     =>'Id de la data_sheet',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1059/expediee_product_name_2_textid'=> 
    # {
    #     'title'     =>'Nom du produit 2',
    #     'fieldtype' =>'text_id',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '60/expediee_product_full_price_2'=> 
    # {
    #     'title'     =>'Prix du produit 2',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '61/expediee_product_discount_price_2'=> 
    # {
    #     'title'     =>'Prix barré du produit 2',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1062/expediee_reference_3'=> 
    # {
    #     'title'     =>'Référence du produit 3',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1063/expediee_id_data_sheet_3'=> 
    # {
    #     'title'     =>'Id de la data_sheet',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1064/expediee_product_name_3_textid'=> 
    # {
    #     'title'     =>'Nom du produit 3',
    #     'fieldtype' =>'text_id',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '65/expediee_product_full_price_3'=> 
    # {
    #     'title'     =>'Prix du produit 3',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '66/expediee_product_discount_price_3'=> 
    # {
    #     'title'     =>'Prix barré du produit 3',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1067/expediee_reference_4'=> 
    # {
    #     'title'     =>'Référence du produit 4',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1068/expediee_id_data_sheet_4'=> 
    # {
    #     'title'     =>'Id de la data_sheet',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1069/expediee_product_name_4_textid'=> 
    # {
    #     'title'     =>'Nom du produit 4',
    #     'fieldtype' =>'text_id',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '70/expediee_product_full_price_4'=> 
    # {
    #     'title'     =>'Prix du produit 4',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '71/expediee_product_discount_price_4'=> 
    # {
    #     'title'     =>'Prix barré du produit 4',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    ########## CONFIG EMAIL COMMANDE CONFIRMATION ##########  
    '1079/disabled_confirmation'=> 
   {
        'title'      =>'Désactiver l\'emailing de confirmation de commande',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab4",
    },
    '1080/confirmation_send_copy'=> 
   {
        'title'      =>'Je souhaite recevoir une copie',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab4",
    },  
    '1081/confirmation_subject_textid'=> 
    {
        'title'     =>'Objet du message',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab4",
    },
    '1082/confirmation_title_textid'=> 
    {
        'title'     =>'Titre',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab4",
    },
    '1083/confirmation_content_textid'=> 
    {
        'title'     =>'Contenu du mail de confirmation',
        'fieldtype' =>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab4",
    },
    # '1083/confirmation_pub_id_pic'=> 
    # {
    #     'title'     =>'Image publicitaire',
    #     'fieldtype' =>'file',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    #     'tab' => "tab4",
    # },
    # '1083/confirmation_pub_link_textid'=> 
    # {
    #     'title'     =>'Lien de l\'image publicitaire',
    #     'fieldtype' =>'text_id',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1084/confirmation_reference_1'=> 
    # {
    #     'title'     =>'Référence du produit 1',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1085/confirmation_id_data_sheet_1'=> 
    # {
    #     'title'     =>'Id de la data_sheet',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1086/confirmation_product_name_1_textid'=> 
    # {
    #     'title'     =>'Nom du produit 1',
    #     'fieldtype' =>'text_id',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '87/confirmation_product_full_price_1'=> 
    # {
    #     'title'     =>'Prix du produit 1',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '88/confirmation_product_discount_price_1'=> 
    # {
    #     'title'     =>'Prix barré du produit 1',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1089/confirmation_reference_2'=> 
    # {
    #     'title'     =>'Référence du produit 2',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1090/confirmation_id_data_sheet_2'=> 
    # {
    #     'title'     =>'Id de la data_sheet',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1091/confirmation_product_name_2_textid'=> 
    # {
    #     'title'     =>'Nom du produit 2',
    #     'fieldtype' =>'text_id',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '92/confirmation_product_full_price_2'=> 
    # {
    #     'title'     =>'Prix du produit 2',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '93/confirmation_product_discount_price_2'=> 
    # {
    #     'title'     =>'Prix barré du produit 2',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1094/confirmation_reference_3'=> 
    # {
    #     'title'     =>'Référence du produit 3',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1095/confirmation_id_data_sheet_3'=> 
    # {
    #     'title'     =>'Id de la data_sheet',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1096/confirmation_product_name_3_textid'=> 
    # {
    #     'title'     =>'Nom du produit 3',
    #     'fieldtype' =>'text_id',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '97/confirmation_product_full_price_3'=> 
    # {
    #     'title'     =>'Prix du produit 3',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '98/confirmation_product_discount_price_3'=> 
    # {
    #     'title'     =>'Prix barré du produit 3',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1099/confirmation_reference_4'=> 
    # {
    #     'title'     =>'Référence du produit 4',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1100/confirmation_id_data_sheet_4'=> 
    # {
    #     'title'     =>'Id de la data_sheet',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # '1101/confirmation_product_name_4_textid'=> 
    # {
    #     'title'     =>'Nom du produit 4',
    #     'fieldtype' =>'text_id',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # 'a103/confirmation_product_full_price_4'=> 
    # {
    #     'title'     =>'Prix du produit 4',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    # 'a104/confirmation_product_discount_price_4'=> 
    # {
    #     'title'     =>'Prix barré du produit 4',
    #     'fieldtype' =>'text',
    #     'fieldsize' =>'50',
    #     'search'    => 'n',
    # },
    ########## CONFIG EMAIL FACTURE ##########   
    '1113/disabled_facture'=> 
    {
        'title'      =>'Désactiver l\'emailing d\'envoi de facture',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab5",
    },
    '1114/facture_send_copy'=> 
   {
        'title'      =>'Je souhaite recevoir une copie',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab5",
    },
    '1115/facture_subject_textid'=> 
    {
        'title'     =>'Objet du message',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab5",
    },
    '1116/facture_title_textid'=> 
    {
        'title'     =>'Titre',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab5",
    },
    '1117/facture_content_textid'=> 
    {
        'title'     =>'Contenu du message',
        'fieldtype' =>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab5",
    },
     ########## CONFIG EMAIL COMMANDE REMERCIEMENT ##########  
    '1129/disabled_merci'=> 
   {
        'title'      =>'Désactiver l\'emailing de remerciement après commande',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab6",
    },
    '1130/merci_send_copy'=> 
   {
        'title'      =>'Je souhaite recevoir une copie',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab6",
    },
    '1131/merci_subject_textid'=> 
   {
        'title'     =>'Objet du message',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab6",
    },
    '1132/merci_title_textid'=> 
    {
        'title'     =>'Titre',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab6",
    },
    '1133/merci_content_textid'=> 
    {
        'title'     =>'Contenu du message',
        'fieldtype' =>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab6",
    },
    '1134/merci_disabled_coupon'=> 
    {
        'title'      =>'Désactiver la génération d\'un coupon de réduction',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab6",
    },
    '1135/merci_coupon_type'=> 
   {
        'title'=>'Type de remise',
        'fieldtype'=>'listbox',
        'fieldvalues'=>\%merci_coupon_type,
        'fieldsize' =>'20',
        'tab' => "tab6",
    },
    '1136/merci_coupon_value'=> 
   {
        'title'=>'Valeur de la remise',
        'fieldtype'=>'text',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab6",
    },
    '1137/merci_coupon_begin'=> 
   {
        'title'=>'Date de début (facultatif)',
        'fieldtype'=>'text',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab6",
    },
    '1138/merci_coupon_end'=> 
   {
        'title'=>'Date de fin (facultatif)',
        'fieldtype'=>'text',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab6",
    },
    '1139/merci_title_product_textid'=> 
   {
        'title'=>'Texte du lien qui redirige vers la boutique',
        'fieldtype'=>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab6",
    },
    '1140/merci_title_product_link_textid'=> 
   {
        'title'=>'Url du lien qui redirige vers la boutique',
        'fieldtype'=>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab6",
    },
    '1141/merci_id_pic'=> 
   {
        'title'=>'Grande image d\'illustration',
        'fieldtype' =>'file',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab6",
    },
    ########## CONFIG EMAIL RELANCE PANIER ##########  
    '1149/disabled_relance_panier'=> 
    {
        'title'      =>'Désactiver l\'emailing de relance de panier',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab7",
    },
    '1150/relance_panier_send_copy'=> 
   {
        'title'      =>'Je souhaite recevoir une copie',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab7",
    },
    '1151/relance_panier_subject_textid'=> 
    {
        'title'     =>'Objet du message',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab7",
    },
    '1152/relance_panier_title_textid'=> 
    {
        'title'     =>'Titre',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab7",
    },
    '1153/relance_panier_subtitle_textid'=> 
    {
        'title'     =>'Sous-titre',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab7",
    },
    '1154/relance_panier_content_textid'=> 
    {
        'title'     =>'Contenu du message',
        'fieldtype' =>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab7",
    },
    # '1155/relance_panier_first'=> 
    # {
        # 'title'     =>'Délai avant le 1er mail de relance',
        # 'fieldtype' =>'text',
        # 'fieldsize' =>'50',
        # 'search'    => 'n',
    # },
    # '1156/relance_panier_second'=> 
    # {
        # 'title'     =>'Délai avant le 2ème mail de relance',
        # 'fieldtype' =>'text',
        # 'fieldsize' =>'50',
        # 'search'    => 'n',
    # },
    ########## CONFIG EMAIL RELANCE PAIEMENT ########## 
    '1169/disabled_relance_paiement'=> 
    {
        'title'      =>'Désactiver l\'emailing de relance de paiement',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab8",
    },
    '1170/relance_paiement_send_copy'=> 
   {
        'title'      =>'Je souhaite recevoir une copie',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab' => "tab8",
    },
    '1171/relance_paiement_subject_textid'=> 
    {
        'title'     =>'Objet du message',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab8",
    },
    '1172/relance_paiement_title_textid'=> 
    {
        'title'     =>'Titre',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab8",
    },
    '1173/relance_paiement_content_textid'=> 
    {
        'title'     =>'Contenu du mail de relance',
        'fieldtype' =>'textarea_id_editor',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab8",
    },
    '1174/relance_paiement_first'=> 
    {
        'title'     =>'Délai avant le 1er mail de relance',
        'fieldtype' =>'text',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab8",
    },
    '1175/relance_paiement_second'=> 
    {
        'title'     =>'Délai avant le 2ème mail de relance',
        'fieldtype' =>'text',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab8",
    },
    ########## CONFIG EMAIL INSCRIPTION ########## 
  
    ########## CONFIG DES COULEURS ########## 
    '2100/color_bandeau_bg'=> 
    {
        'title'     =>'Couleur de fond des bandeaux',
        'fieldtype' =>'text',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab9",
    },
    '2101/color_bandeau'=> 
    {
        'title'     =>'Couleur des bandeaux',
        'fieldtype' =>'text',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab9",
    },
    '2107/color_bandeau_price'=> 
    {
        'title'     =>'Couleur des textes du bandeau du tableau de prix',
        'fieldtype' =>'text',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab9",
    },
    '2102/color_content'=> 
    {
        'title'     =>'Couleur des textes du contenu',
        'fieldtype' =>'text',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab9",
    },
    '2103/color_content_second'=> 
    {
        'title'     =>'Couleur des textes du contenu mis en avant',
        'fieldtype' =>'text',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab9",
    },
    '2104/color_content_link'=> 
    {
        'title'     =>'Couleur des liens du contenu',
        'fieldtype' =>'text',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab9",
    },
    '2105/color_button'=> 
    {
        'title'     =>'Couleur du texte du boutton',
        'fieldtype' =>'text',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab9",
    },
    '2106/color_button_bg'=> 
    {
        'title'     =>'Couleur de fond du boutton',
        'fieldtype' =>'text',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab9",
    },
    '2107/color_entete_links'=> 
    {
        'title'     =>'Couleur des liens d\'entete',
        'fieldtype' =>'checkbox',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab' => "tab9",
    },
    ########### FACTURE PDF ########## 
    '2200/disabled_facture_pdf'=> 
    {
        'title'      =>'Désactiver l\'emailing de facture PDF',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab'       => "tab10",
    },
    '2201/facture_pdf_send_copy'=> 
    {
        'title'      =>'Je souhaite recevoir une copie',
        'fieldtype'  =>'checkbox',
        'checkedval' => 'y',
        'tab'       => "tab10",
    },
    '2202/facture_pdf_subject_textid'=> 
    {
        'title'     =>'Objet du message',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab'       => "tab10",
    },
    '2203/facture_pdf_title_textid'=> 
    {
        'title'     =>'Titre',
        'fieldtype' =>'text_id',
        'fieldsize' =>'50',
        'search'    => 'n',
        'tab'       => "tab10",
    },
    '2204/facture_pdf_content_textid'=> 
    {
        'title'     => 'Contenu du mail',
        'fieldtype' => 'textarea_id_editor',
        'fieldsize' => '50',
        'search'    => 'n',
        'tab'       => "tab10",
    },

);
# see();
# see(\%dm_dfl);
# my $count = 0;
# my $tab_count = 0;
# foreach $cle (sort keys %dm_dfl)
# {
# 	my %h = %{$dm_dfl{$cle}};
# 	# print "<br>$cle [$count][tab$tab_count]";
# 	$dm_dfl{$cle}{tab} = 'tab'.$tab_count;
	
# 	if($count == 18 || $count == 23 || $count == 44 || $count == 64 || $count == 83 || $count == 88    || $count == 101  || $count == 109 || $count == 1149 || $count == 1169 || $count == 2099)
# 	{
# 		$tab_count++;
# 		# print '<b>'.$count.'</b><hr>';
# 	}
	
# 	$count++;
# }
  # see(\%dm_dfl);
# exit;

%dm_display_fields = (
"02/Emails désactivés"=>"disabled_emailing",

);

# $dm_lnk_fields{"01/Logo"} = "preview_logo*";
# $dm_mapping_list{preview_logo} = \&preview_logo;


$dm_cfg{help_url} = "http://www.bugiweb.com";

$sw = $cgi->param('sw') || "list";


see();



my @fcts = qw
(
  add_form
  mod_form
  list
  add_db
  mod_db
  del_db
  view
  add_editorial
);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
   

    
    print migc_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_form
{
  my %item = %{$_[0]};
  my $form_div=build_form(\%dm_dfl,\%item);


    my %eshop_config = sql_line({dbh=>$dbh, table=>"eshop_setup",limit=>1});


    if($eshop_config{eshop_emails_cron_disabled} eq "y")
    {
        $disabled = "class='disabled-li'";
    }

  my $tabs=<<"EOH";

    <li><a href="#field_tab_config">Configuration générale</a></li>
    <li><a href="#field_tab_subscribe">Email d'inscription</a></li>
    <li><a href="#field_tab_bienvenue">Email de bienvenue newsletter</a></li>
    <li><a href="#field_tab_expediee">Email commande expédiée</a></li>
    <li><a href="#field_tab_confirmation">Email confirmation commande</a></li>
    <li><a href="#field_tab_facture">Email facture</a></li>
    <li><a href="#field_tab_merci">Email remerciement</a></li>
    <li $disabled ><a href="#field_tab_relance_panier">Email relance de panier</a></li>
    <li $disabled ><a href="#field_tab_relance_paiement">Email relance de paiement</a></li>
    <li><a href="#field_tab_colors">Gestion des couleurs</a></li>
EOH
  # my $form = build_form(\%dm_dfl,\%item);
  # 
  my $content= <<"EOH";
   <div id="admin_eshop_emails_tabs">
        <ul>
          $tabs
        </ul>
        $form_div

    </div>
EOH

  $form=<<"JAVASCRIPT";
       <style>
       .void_pictures, .void_files, .void_crits, .void_stock, .void_tax
       {
          color:white!important;
       }
       </style>
        <style type="text/css">
  
/* Vertical Tabs
----------------------------------*/
.ui-tabs-vertical { width: 100%; }
.ui-tabs-vertical .ui-tabs-nav { padding: .2em .1em .2em .2em; float: left; width: 15%; }
.ui-tabs-vertical .ui-tabs-nav li { clear: left; width: 100%; border-bottom-width: 1px !important; border-right-width: 0 !important; margin: 0 -1px .2em 0; }
.ui-tabs-vertical .ui-tabs-nav li a { display:block; }
.ui-tabs-vertical .ui-tabs-nav li.ui-tabs-selected { padding-bottom: 0; padding-right: .1em; border-right-width: 1px; border-right-width: 1px; }
.ui-tabs-vertical .ui-tabs-panel { padding: 1em; float: right; width: 80%;}
  </style>
       <script type="text/javascript">
       jQuery(document).ready(function(){
          jQuery("#admin_eshop_emails_tabs").tabs().addClass('ui-tabs-vertical ui-helper-clearfix');
          var url_rewriting_preview_container='<span class="url_rewriting_preview_container">Aperçu</span>';
          jQuery(".field_field_id_textid_url_rewriting").prepend(url_rewriting_preview_container);
        });
        
 
        
          

        </script>
           
      $content
JAVASCRIPT
        
  return $form;;
}

sub preview_logo
{
  my $dbh = $_[0];
  my $id = $_[1];

  # Récupération de l'id_pic
  %email_config = sql_line({dbh=>$dbh, table=>"eshop_emails_setup", where=>"id = '$id'"});
  # Récupération de l'image en db
  %pic = sql_line({debug_results=>0,dbh=>$dbh, table=>"pics", where=>"id = '$email_config{id_pic}'"});

  my $content = <<"EOH";
    <img src="pics/$pic{pic_name_medium}" height="$pic{pic_height_medium}" width="$pic{pic_width_medium}">
EOH



  return $content;
}

sub after_add
{
    my $dbh=$_[0];
    my $id =$_[1];

    my %eshop_emails_config = sql_line({debug_results=> 0,dbh=>$dbh, table=>$dm_cfg{table_name}, where=>"id = '$id'"});



    my %demozone_data = 
    (
        subscribe_subject_textid => {
            traductible => "y",
            1 => "Bienvenue",
        },
        subscribe_title_textid => {
            traductible => "y",
            1 => "Merci de vous être inscrit sur notre boutique !",
        },
        subscribe_content_textid => {
            traductible => "y",
            1 => "<span>Vous êtes inscrit en tant que {EMAIL_DU_CLIENT}.</span>",
        },

        bienvenue_subject_textid => {
            traductible => "y",
            1 => "Bienvenue",
        },
        bienvenue_title_textid => {
            traductible => "y",
            1 => "Merci de vous être abonné pour recevoir nos bons plans !",
        },
        bienvenue_subtitle_textid => {
            traductible => "y",
            1 => "Vous serez le premier à :",
        },
        bienvenue_list_textid => {
            traductible => "y",
            1 => "<ul>
                    <li>Recevoir nos coupons de r&eacute;duction</li>
                    <li>&Ecirc;tre au courant des nouveaut&eacute;s</li>
                  </ul>",
        },
        bienvenue_content_textid => {
            traductible => "y",
            1 => "<span>Vous &ecirc;tes inscrit en tant que {EMAIL_DU_CLIENT}. </span>Pour &ecirc;tre certain de recevoir nos mails, ajoutez {EMAIL_SERVICE_CLIENT} dans votre carnet d'adresses.<br /><br />Vous pouvez &eacute;galement acheter quand vous le souhaitez sur {NOM_DE_LA_BOUTIQUE}</a>",
        },
        expediee_subject_textid => {
            traductible => "y",
            1 => "Commande expédiée",
        },
        expediee_title_textid => {
            traductible => "y",
            1 => "Votre commande a été expédiée",
        },
        expediee_content_textid => {
            traductible => "y",
            1 => "Merci encore d'avoir commandé sur notre site {NOM_DE_LA_BOUTIQUE}.<br/>
                Les informations de livraison et le code de suivi de votre commande se trouvent ci-dessous.",
        },
        expediee_contact_textid => {
            traductible => "y",
            1 => "{CONTACT_SERVICE_CLIENT}<br /><br />{SIGNATURE_EMAIL}",
        },
        confirmation_subject_textid => {
            traductible => "y",
            1 => "Confirmation de commande",
        },
        confirmation_title_textid => {
            traductible => "y",
            1 => "Merci pour votre commande !",
        },
        confirmation_content_textid => {
            traductible => "y",
            1 => "<span>Bonjour</span> {NOM_DU_CLIENT},<br /><br /><span>Nous vous remercions d&rsquo;avoir effectu&eacute; une commande sur {NOM_DE_LA_BOUTIQUE}, nous sommes tr&egrave;s reconnaissant de la confiance que vous nous accordez. Vous trouverez les informations concernant votre commande ci-dessous.</span><br /><br /><span>{CONTACT_SERVICE_CLIENT}<br /><br />{SIGNATURE_EMAIL}<br /><br /><strong>PS :</strong> Vous recevrez bient&ocirc;t une confirmation d&rsquo;envoi de votre commande lorsque celle-ci quittera nos entrep&ocirc;ts.</span>",
        },
        facture_subject_textid => {
            traductible => "y",
            1 => "Facture PRO FORMA N°{NUMERO_DE_COMMANDE}",
        },
        facture_title_textid => {
            traductible => "y",
            1 => "Facture PRO FORMA N°{NUMERO_DE_COMMANDE}",
        },
        facture_content_textid => {
            traductible => "y",
            1 => "Bonjour {NOM_DU_CLIENT},<br /><br />Merci pour votre commande.<br /><br />{CONTACT_SERVICE_CLIENT}<br /><br />{SIGNATURE_EMAIL}",
        },
        merci_subject_textid => {
            traductible => "y",
            1 => "Merci",
        },
        merci_title_textid => {
            traductible => "y",
            1 => "Merci !",
        },
        merci_content_textid => {
            traductible => "y",
            1 => "Cher {NOM_DU_CLIENT},<br /><br /><span>Ce fut un r&eacute;el plaisir d&rsquo;avoir pu vous servir sur notre boutique {NOM_DE_LA_BOUTIQUE}.</span><br /><br /><span>Merci encore pour votre achat.<br /><br /> {SIGNATURE_EMAIL}</span>",
        },
        color_bandeau_bg     => {
            traductible => "n",
            1 => "#333333",
        },
        color_bandeau        => {
            traductible => "n",
            1 => "#dadada",
        },
        color_content        => {
            traductible => "n",
            1 => "#292929",
        },
        color_content_second => {
            traductible => "n",
            1 => "#d80404",
        },
        color_content_link   => {
            traductible => "n",
            1 => "#D80404",
        },
        color_button         => {
            traductible => "n",
            1 => "#FFFFFF",
        },
        color_button_bg      => {
            traductible => "n",
            1 => "#d80404",
        },
        color_bandeau_price  => {
            traductible => "n",
            1 => "#FFFFFF",
        },
        color_entete_links   => {
            traductible => "n",
            1 => "#292929",
        },
    );
    see();
    my %update_emails_config;
    foreach $key (keys %demozone_data)
    {
        # Si le champ est vide
        my ($textcontent, $empty) = get_textcontent($dbh,$demozone_data{$key});

        if($textcontent eq "")
        {
            my $value;
            if($demozone_data{$key}{traductible} eq "y")
            {
                $demozone_data{$key}{1} =~ s/\'/\\\'/g;
                $demozone_data{$key}{1} =~ s/\@/\\\@/g;
                $value = insert_text($dbh, $demozone_data{$key}{1}, 1);
            }
            else
            {
                $value = $demozone_data{$key}{1};
            }

            $update_emails_config{$key} = $value;
        }
    }

    updateh_db($dbh, $dm_cfg{table_name}, \%update_emails_config, "id", $id)


    
    
}

sub get_autocomplete_data_sheets
{

   #prend la famille par défaut
   my $lg = get_quoted('lg') || $config{default_colg} || 1;
   my %data_cfg_line=select_table($dbh,"config","","varname='data_cfg'");
   my %data_cfg = eval("%data_cfg = ($data_cfg_line{varvalue});");
   my %data_family = read_table($dbh,"data_families",$data_cfg{default_family});

   #récupère le champ nom et le champ référence afin de déterminer leur type (on considère que le champ référence est tjs non traductible)
   my %field_reference = read_table($dbh,"data_fields",$data_family{id_field_reference});
   my %field_name = read_table($dbh,"data_fields",$data_family{id_field_name});
   my $field_reference = 'f'.$field_reference{ordby};
   my $field_name = 'f'.$field_name{ordby};
   
   if($field_name{field_type} eq 'text' || $field_name{field_type} eq 'textarea')
   {
         my $term = get_quoted('term') || '';
         my @data_sheets = get_table($dbh,"data_sheets sh","sh.id,$field_reference,$field_name","($field_reference LIKE '%$term%' OR $field_name LIKE '%$term%')","","","",0);
         my $list = '[';
         foreach $data_sheet (@data_sheets)
         {
            
            my %data_sheet = %{$data_sheet};
            $data_sheet{$field_name} =~ s/\"//g;
            $list .= '{ "id": "'.$data_sheet{id}.'", "label": "'.$data_sheet{$field_reference}.': '.$data_sheet{$field_name}.'", "value": "'.$data_sheet{$field_reference}.': '.$data_sheet{$field_name}.'" },';
         }
         
         chop($list);
         
         $list.=']';
      
         print $list;
         exit;
   }
   else
   {
         my $term = get_quoted('term') || '';
         my @data_sheets = get_table($dbh,"data_sheets sh, textcontents txt","sh.id,$field_reference,content","sh.$field_name = txt.id_textid AND txt.id_language = $lg AND ($field_reference LIKE '%$term%' OR content LIKE '%$term%')","","","",0);
         my $list = '[';
         foreach $data_sheet (@data_sheets)
         {
            
            my %data_sheet = %{$data_sheet};
            $data_sheet{content} =~ s/\"//g;
            $list .= '{ "id": "'.$data_sheet{id}.'", "label": "'.$data_sheet{$field_reference}.': '.$data_sheet{content}.'", "value": "'.$data_sheet{$field_reference}.': '.$data_sheet{content}.'" },';
         }
         
         chop($list);
         
         $list.=']';
      
         print $list;
         exit;
   }
}

sub after_upload
{
    my $dbh=$_[0];
    my $id=$_[1];
    my %parag = sql_line({table=>'parag',where=>"id='$id'"});
    my %template = sql_line({table=>'templates',where=>"id='$parag{id_template}'"});
    my %parag_setup = sql_line({table=>'parag_setup',where=>""});
    
    my @sizes = ('mini','small','medium','large','og');
    
    #boucle sur les images du paragraphes
    my @migcms_linked_files = sql_lines({debug=>1,debug_results=>1,table=>'migcms_linked_files',where=>"ext IN ('.jpg','.jpeg','.png') AND table_name='$dm_cfg{table_name}' AND table_field='id_pic' AND token='$id'",ordby=>'ordby'});
    foreach $migcms_linked_file (@migcms_linked_files)
    {
        #appelle la fonction de redimensionnement
        my %migcms_linked_file = %{$migcms_linked_file};
        my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
        my %params = (
            migcms_linked_file=>\%migcms_linked_file,
            do_not_resize=>$parag{do_not_resize}
        );
        foreach my $size (@sizes)
        {
            $params{'size_'.$size} = $upload_config{$size."_width"};
        }
        dm::resize_pic(\%params);
    }   
}






