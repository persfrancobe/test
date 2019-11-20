#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

$dm_cfg{customtitle} = $migctrad{mailings}.' > '.$migctrad{mailing_blacklist};
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{operation} = 1;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "mailing_blacklist";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{default_ordby} = "moment desc";
$dm_cfg{excel_key} = 'id';

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_$dm_cfg{table_name}.pl?";
 
$dm_cfg{hiddp}=<<"EOH";

EOH



%status = (
			"running"=>"$migctrad{yes}",
			"ok"=>"$migctrad{no}"
		);

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    '01/email'=> {
	        'title'=>$migctrad{adm_mailing_blacklist_email},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
		,
	     '02/moment'=>
		 {
	        'title'=>$migctrad{adm_mailing_blacklist_moment},
	        'fieldtype'=>'text',
	    }
	    ,
	    '03/reason'=> {
	       'title'=>$migctrad{adm_mailing_blacklist_reason},
	       'fieldtype'=>'text',
	    }
	);

%dm_display_fields = (
	"01/$migctrad{adm_mailing_blacklist_email}"=>"email",
	"02/$migctrad{adm_mailing_blacklist_moment}"=>"moment",
	"03/$migctrad{adm_mailing_blacklist_reason}"=>"reason"
		);
		
%dm_lnk_fields = (

		);

%dm_mapping_list = (
);

%dm_filters = (
		);

$sw = $cgi->param('sw') || "list";

if ($sw ne "get_all_xls") {see();}

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
			up
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}


