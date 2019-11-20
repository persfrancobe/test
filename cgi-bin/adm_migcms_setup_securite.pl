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
use sitetxt;


$dm_cfg{customtitle}=<<"EOH";
EOH

$dm_cfg{enable_search} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{trad} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "securite_setup";
$dm_cfg{list_table_name} = "securite_setup";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_setup_securite.pl?";

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_ordby_ref} = '';

$dm_cfg{hiddp}=<<"EOH";
EOH


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = 
(
  '01/disable_google_captcha'=> 
  {
    'title'      => $migctrad{securite_desactiver_google},
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
  }
  ,
   '02/disable_security'=> 
  {
    'title'      => $migctrad{securite_desactiver_modules},
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
  }
  ,
   '03/disable_env'=> 
  {
    'title'      => $migctrad{securite_desactiver_env},
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
  }
  ,
   '04/droits_simples'=> 
  {
    'title'      => $migctrad{securite_droits_simples},
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
  }
  
 );


%dm_display_fields = (
  "01/$migctrad{securite_desactiver_google}"=>"disable_google_captcha",
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
    
}