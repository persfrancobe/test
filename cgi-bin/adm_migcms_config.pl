#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;


$dm_cfg{customtitle} = $migctrad{templates_title};

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{deplie_recherche} = 1;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "config";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_config.pl?";


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    
		'02/varname'=> {
	        'title'=>'Mot clé',
	        'fieldtype'=>'text',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    },
	    
	    '03/varvalue'=> {
	        'title'=>'Paramètres',
	        'fieldtype'=>'textarea',
			'search' => 'y'
	    }	    
	);

%dm_display_fields = (
			"2/Mot clé"=>"varname",
			"3/Paramètres"=>"varvalue",

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

if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();
	
	 my $suppl_js=<<"EOH";
    
     <style>
      </style>
    
   	
EOH
	
    print wfw_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}