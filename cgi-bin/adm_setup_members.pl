#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{customtitle}=<<"EOH";
EOH

$dm_cfg{enable_search} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "members_setup";
$dm_cfg{list_table_name} = "members_setup";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_setup_members.pl?";

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_ordby_ref} = '';

$dm_cfg{hiddp}=<<"EOH";
EOH

$dm_cfg{file_prefixe} = 'SME';

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = 
(
      '01/email_from'=> 
      {
		  'title'=>"Expéditeur des emails",
		  'fieldtype'=>'text',
		  'data_type'=>'email',
		  'mandatory'=>{"type" => 'not_empty'},
      }
	  ,
	  '31/use_handmade_members'=> 
      {
		  'title'=>"Redéfinir member sur mesure",
		  'fieldtype'=>'checkbox',
      }
	  ,
	   '32/use_handmade_member_login_form_func'=> 
      {
		  'title'=>"Fonction pour la page login-inscription",
		  'fieldtype'=>'text',
      }
	  ,
	   '33/use_handmade_member_signup_db_func'=> 
      {
		  'title'=>"Fonction pour la sauvegarde de l'inscription",
		  'fieldtype'=>'text',
      }
	  
);

%dm_display_fields = (
"01/email_from"=>"email_from",
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
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();

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
}