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
$dm_cfg{table_name} = "stripe_setup";
$dm_cfg{list_table_name} = "stripe_setup";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_setup_stripe.pl?";

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
);

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = 
(
  # CONFIGURATION GENERALE
  sprintf("%02d", $ordby++)."/stripe_public_key"=> 
  {
    'title'      => "Public Key",
    'fieldtype'  => 'text',
    'tab'        => 'gen', 
  }
  ,   
  sprintf("%02d", $ordby++)."/stripe_secret_key"=> 
  {
    'title'     => "Secret Key",
    'fieldtype' => 'text',
    'tab'       => 'gen',
  }
  ,
  sprintf("%02d", $ordby++)."/stripe_url_redirect_after_success"=> 
  {
    'title'     => "Redirection après un paiement réussi",
    'tab'       => 'gen',
    'fieldtype' => 'text_id',
  }
  ,
  sprintf("%02d", $ordby++)."/stripe_url_redirect_after_error"=> 
  {
    'title'     => "Redirection après une erreur durant un paiement",
    'tab'       => 'gen',
    'fieldtype' => 'text_id',
  }
  ,
     
  
);


%dm_display_fields = (
  "01/Public Key"=>"stripe_public_key",
  "02/Secret Key"=>"stripe_secret_key",
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
);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    
    my $suppl_js=<<"EOH";    
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
}