#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;


my %user = %{get_user_info($dbh,$config{current_user})} or wfw_no_access();

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{customtitle} = $fwtrad{config_title};
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "config";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";


$dm_cfg{self} = "$config{baseurl}/cgi-bin/fwconfig.pl?";


%acces = (
			"1"=>"Administrateur",
      "2"=>"Webmaster",
      "3"=>"Editeur"			
		);


%dm_dfl = (
        '01/varname'=> {
            'title'=>$fwtrad{config_varname},
            'fieldtype'=>'text',
            'fieldsize'=>'40',
            'search'=>'y'
        },
        '02/varvalue'=> {
            'title'=>$fwtrad{config_varvalue},
            'fieldtype'=>'textarea',
            'fieldparams'=>'cols=90 rows=30',    
        },
        '03/id_role'=> {
            'title'=>'Acces',
  	        'fieldtype'=>'listbox',
  	        'fieldvalues'=>\%acces
        }
    );



%dm_display_fields = (
    "1/$fwtrad{config_varname}"=>"varname",
    "2/$fwtrad{config_varvalue}"=>"varvalue",
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
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}




