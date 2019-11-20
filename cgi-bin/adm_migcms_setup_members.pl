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
$dm_cfg{table_name} = "members_setup";
$dm_cfg{list_table_name} = "members_setup";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_setup_members.pl?";

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_ordby_ref} = '';

$dm_cfg{hiddp}=<<"EOH";
EOH


@dm_nav =
(
  {
    'tab'=>'gen',
    'type'=>'tab',
    'title'=>'Configuration générale',
  }
  ,
   {
    'tab'=>'login',
    'type'=>'tab',
    'title'=>'Login'
  }
  , 
   {
    'tab'=>'signup',
    'type'=>'tab',
    'title'=>'Inscription',
  }
  , 
  {
    'tab'=>'back',
    'type'=>'tab',
    'title'=>'Gestion Backoffice'
  }
  , 
  {
    'tab'=>'front',
    'type'=>'tab',
    'title'=>'Gestion Frontoffice'
  }
  , 
  {
    'tab'=>'email',
    'type'=>'tab',
    'title'=>'Validation'
  }
  # , 
  # {
    # 'tab'=>'newsletter',
    # 'type'=>'tab',
    # 'title'=>'Newsletter',
  # }
  ,
  {
    'tab'=>'account',
    'type'=>'tab',
    'title'=>'Page Mon Compte',
  }
  , 
  {
    'tab'=>'social',
    'type'=>'tab',
    'title'=>'Réseaux sociaux',
  }
  ,

	
);

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = 
(
  # CONFIGURATION GENERALE
  '01/member_disabled'=> 
  {
    'title'      => "Gestion des membres désactivée",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'gen', 
  }
  ,   
  '05/email_from'=> 
  {
    'title'     => "Adresse E-mail",
    'tab'       => 'gen',
    'fieldtype' => 'text',
	'data_type'=>'email',
  }
  ,
  # LOGIN
  '28/enable_simplify_connect'=> 
  {
    'title'     => "Activer l'écran de connexion/inscription simplifié",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'login',
  }
  ,
  '30/id_textid_login_form_infos_suppl'=> 
  {
    'title'     => "Infos suppl au dessus du formulaire de connexion",
    'tab'       => 'login',
    'fieldtype' => 'textarea_id_editor',
  }
  ,
  '32/id_textid_conditions'=> 
  {
    'title'     => "Texte à cocher pour les conditions",
    'tab'       => 'login',
    'fieldtype' => 'textarea_id_editor',
  }
  ,
  
  '38/disabled_login_recaptcha'=> 
  {
    'title'     => "Désactiver le recaptcha à  la connexion",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'login',
  }
  ,
  '39/before_login_func'=> 
  {
    'title'      => "Fonction before login",
    'fieldtype'  => 'text',
    'checkedval' => 'y',
    'tab'        => 'login',
  } 
  ,
  '40/after_login_func'=> 
  {
    'title'      => "Fonction post login",
    'fieldtype'  => 'text',
    'checkedval' => 'y',
    'tab'        => 'login',
  } 
  ,
  '45/member_url_after_login'=> 
  {
    'title'      => "Url redirection after login",
    'fieldtype'  => 'text',
    'checkedval' => 'y',
    'tab'        => 'login',
  } 
  ,
  
  ,
  # '39/member_custom_login_form'=> 
  # {
  #   'title'      => "Page de login personnalisée",
  #   'fieldtype'  => 'checkbox',
  #   'checkedval' => 'y',
  #   'tab'        => 'login',
  # }
  # ,
  '40/use_handmade_member_login_form_func'=> 
  {
    'title'     => "Fonction pour la page login-inscription",
    'fieldtype'  => 'text',
    'tab'        => 'login',
  }
  ,
  
  # INSCRIPTION
  # 
  '50/id_textid_signup_form_infos_suppl'=> 
  {
    'title'     => "Infos suppl au dessus du formulaire d'inscription'",
    'tab'       => 'signup',
    'fieldtype' => 'textarea_id_editor',
  }
  ,
  '53/disable_member_signup'=> 
  {
    'title'     => "Désactiver l'inscription",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'       => 'signup',
  }
  ,
  '54/disable_member_autoactivation_after_signup'=> 
  {
    'title'      => "Désactiver la validation automatique du membre lors de l'inscription",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'signup',
  }
 ,
  '55/auto_email_optin_after_signup'=> 
  {
    'title'      => "Optin email toujours oui par défaut",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'signup',
  } 
   ,
   '56/before_signup_func'=> 
  {
    'title'      => "Fonction before inscription",
    'fieldtype'  => 'text',
    'checkedval' => 'y',
    'tab'        => 'signup',
  } 
  ,'56/use_handmade_member_signup_form_func'=> 
  {
    'title'     => "Fonction pour la page entière d'Inscription",
    'fieldtype'  => 'text',
    'tab'        => 'signup',
  }
  ,
  ,'57/use_handmade_member_html_signup_form_func'=> 
  {
    'title'     => "Fonction pour l'HTML du formulaire d'inscription",
    'fieldtype'  => 'text',
    'tab'        => 'signup',
  }
  ,
  '57/use_handmade_member_signup_db_func'=> 
  {
    'title'     => "Fonction pour la sauvegarde de l'inscription",
    'fieldtype'  => 'text',
    'tab'        => 'signup',
  }
  ,  
  '57/after_signup_func'=> 
  {
    'title'      => "Fonction post inscription",
    'fieldtype'  => 'text',
    'checkedval' => 'y',
    'tab'        => 'signup',
  } 
  ,
  '58/member_autologin_after_signup'=> 
  {
    'title'      => "Connexion automatique après inscription",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'signup',
  }
  ,
  '59/member_autologin_after_signup_url'=> 
  {
    'title'      => "Connexion automatique après inscription vers URL...",
    'fieldtype'  => 'text',
    'tab'        => 'signup',
  }
  ,
  '60/member_signup_mail_activation'=> 
  {
    'title'      => "Activation du compte après inscription par mail",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'signup',
  }
  ,
  '61/disabled_mailing_after_signup'=> 
  {
    'title'     => "Désactiver l\'envoi de mail lors de l\'inscription",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'signup', 
  }
  ,
  '62/id_textid_mailing_after_signup'=> 
  {
    'title'      => "Contenu du mail d'inscription",
    'fieldtype'  => 'textarea_id_editor',
    'tab'        => 'signup',
  },
  # GESTION EN BACKOFFICE
  '70/use_handmade_members'=> 
  {
    'title'      => "Admin des membres personnalisée (def_handmade)",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'back', 
  }
  ,
  '75/additionnal_after_save'=> 
  {
    'title'      => "Fonction d'after_save supplémentaire",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'back', 
  },

  # GESTION EN FRONTOFFICE
  '100/id_tpl_page'=> 
  {
    'title'     => "Template de page",
    'tab'       => 'front',
    'fieldtype' => 'listboxtable',
    'lbtable'   => 'templates',
    'lbkey'     => 'templates.id',
    'lbdisplay' => 'templates.name',
    'lbwhere'   => "type = 'page'",
    'mandatory' => {"type" => 'not_empty'},
  }
  ,
  '100/id_tpl_page_notconnected'=> 
  {
    'title'     => "Template de page (Si pas connecté)",
    'tab'       => 'front',
    'fieldtype' => 'listboxtable',
    'lbtable'   => 'templates',
    'lbkey'     => 'templates.id',
    'lbdisplay' => 'templates.name',
    'lbwhere'   => "type = 'page'",
    'mandatory' => {"type" => 'not_empty'},
  }
  ,
  '105/id_page'=> 
  {
    'title'     => "Page",
    'tab'       => 'front',
    'fieldtype' => 'listboxtable',
    'lbtable'   => 'migcms_pages',
    'lbkey'     => 'migcms_pages.id',
    'lbdisplay' => 'migcms_pages.id_textid_name',
    'lbwhere'   => "migcms_pages_type = 'page'",
    'mandatory' => {"type" => 'not_empty'},
    'translate' => 1,
  }
  ,
  '105/id_page_bis'=> 
  {
    'title'     => "Page Bis (multisites)",
    'tab'       => 'front',
    'fieldtype' => 'listboxtable',
    'lbtable'   => 'migcms_pages',
    'lbkey'     => 'migcms_pages.id',
    'lbdisplay' => 'migcms_pages.id_textid_name',
    'lbwhere'   => "migcms_pages_type = 'page'",
    'mandatory' => {"type" => ''},
    'translate' => 1,
  }
  ,
  '110/class_col_left_member_zone'=> 
  {
    'title'     => "Class html de la colonne de gauche",
    'tab'       => 'front',
    'fieldtype' => 'text',    
  }
  ,
  '111/class_col_right_member_zone'=> 
  {
    'title'     => "Class html de la colonne de droite",
    'tab'       => 'front',
    'fieldtype' => 'text',    
  }
  ,
  '112/force_login_register_page'=> 
  {
    'title'      => "Forcer la page de connexion et d'enregistrement",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'front', 
  },



  # GESTION EN FRONTOFFICE
  '150/disabled_mailing_statut'=> 
  {
    'title'     => "Désactiver l\'envoi de mail lors de la validation",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'email', 
  }
  ,
  '155/id_textid_mailing_statut'=> 
  {
    'title'     => "Contenu du mail de validation",
    'tab'       => 'email',
    'fieldtype' => 'textarea_id_editor',
  }
  # ,
  # NEWSLETTER
  # '180/id_default_mailing_group'=> 
  # {
    # 'title'     => "Groupe de newsletter par défaut",
    # 'fieldtype' =>'listboxtable',
    # 'lbtable'   =>'mailing_groups',
    # 'lbkey'     =>'id',
    # 'lbdisplay' =>'title',
    # 'tab'       => 'newsletter',
  # }
  ,
  # MON COMPTE
  '200/id_textid_account_content'=> 
  {
    'title'     => "Contenu de la page \"Mon compte\"",
    'fieldtype' =>'textarea_id_editor',
    "tab"       => "account",
  }
  ,
  '150/custom_menu'=> 
  {
    'title'     => "Menu personnalisé",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'account', 
  }
  , 
   # SOCIAL MEDIAS
  '200/enable_social_medias'=> 
  {
    'title'     => "Activer inscription/connexion via réseaux sociaux",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'social', 
  }
  ,  
  '210/enable_social_facebook'=> 
  {
    'title'     => "Activer Facebook",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'social', 
  }
  , 
  '211/social_facebook_code'=> 
  {
    'title'     => "Facebook-appID",
    'fieldtype'  => 'text',
    'tab'        => 'social', 
  }
  , 
  '220/enable_social_google'=> 
  {
    'title'     => "Activer Google",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'social', 
  }
  ,  
  '221/social_google_code'=> 
  {
    'title'     => "Google-clientID",
    'fieldtype'  => 'text',
    'tab'        => 'social', 
  }
  ,    
  
);


%dm_display_fields = (
  "01/Configuration des membres"=>"id_tpl_page1",
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