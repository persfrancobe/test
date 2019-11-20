#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use setup;

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{customtitle}=<<"EOH";
EOH

$dm_cfg{trad} = 0;
$dm_cfg{enable_search} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "migcms_setup";
$dm_cfg{list_table_name} = "migcms_setup";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_setup_migfw.pl?";

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_ordby_ref} = '';

$dm_cfg{hiddp}=<<"EOH";
EOH

$dm_cfg{file_prefixe} = 'SSI';

#%dm_dfl = %{setup::get_setup_dm_dfl()};

%dm_dfl = (
	'01/site_name'=> 
	{
		'title'=>"Nom du framework",
		'fieldtype'=>'text'
	}
	,
	'02/admin_first_page_url'=> 
	{
		'title'=>"Page d\'accueil du framework",
		'fieldtype'=>'text'
	}
	,
	'03/logos'=> 
	{
		'title'=>"Logos du framework",
		'fieldtype'=>'files_admin',
		'disable_add'=>1,
		'legend'=>'<u>Ordre des images:</u><br><br>Grand logo (Largeur: 200px) puis petit logo (Largeur: 40px)'
	}
	,
	'04/google_clientid'=>
	{
		'title'=>"ID clients OAuth 2.0 (Google)",
		'fieldtype'=>'text',
	}
);

%dm_display_fields = (
"01/Nom du framework"=>"site_name"
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
    my $id =$_[1];
	
	# my %rec = read_table($dbh,'migcms_setup',$id);
}