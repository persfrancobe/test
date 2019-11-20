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
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{duplicate} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{deplie_recherche} = 1;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "migcms_modules_wheres";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_modules_wheres.pl?";


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    
	  '09/id_script' => 
      {
           'title'=>'Module',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'scripts',
           'lbkey'=>'id',
           'translate'=>'1',
           'lbdisplay'=>'id_textid_name',
           'lbwhere'=>""
      }
	  ,
	  '19/id_role' => 
      {
           'title'=>'Rôle',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'migcms_roles',
           'lbkey'=>'id',
           'lbdisplay'=>'nom_role',
           'lbwhere'=>""
      }
	   ,
	  '29/where_supp' => 
      {
           'title'=>'Condition where supplémentaire',
           'fieldtype'=>'textarea',
      }
	);

%dm_display_fields = (
			"2/Module"=>"id_script",
			"3/Rôle"=>"id_role",
			"4/Condition where supplémentaire"=>"where_supp",

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