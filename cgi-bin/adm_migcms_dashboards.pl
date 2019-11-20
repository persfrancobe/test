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
# migc modules


use migcrender;
use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Variables globales
my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();
$colg = get_quoted('colg') || $config{default_colg};


$dm_cfg{trad}             = 0;
$dm_cfg{customtitle}      = $migctrad{products_management}.' > '.$migctrad{product_families_list};
$dm_cfg{enable_search}    = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt}          = 1;
$dm_cfg{sort_opt}         = 0;
$dm_cfg{wherel}           = "";
$dm_cfg{wherep}           = "";
$dm_cfg{table_name}       = "dashboards";
$dm_cfg{list_table_name}  = "$dm_cfg{table_name}";
$dm_cfg{table_width}      = 850;
$dm_cfg{fieldset_width}   = 850;
my $self                  =$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_dashboards.pl?";



$config{logfile} = "trace.log";
my $id = get_quoted('id');
%etapes = (
			"1"=>"1",
			"2"=>"2",
			"3"=>"3",
			"4"=>"4",
			"5"=>"5"
		);


@dm_nav =
(
);

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    
	'01/name'=> {
		'title'=>"Nom du dashboard",
		'fieldtype'=>'text',
		'fieldsize'=>'50',
		'search' => 'y',
		'mandatory'=>{"type" => 'not_empty'},
	}
	,
	'02/id_user' =>{
		'title'=>"Utilisateur",
		'fieldtype'=>'listboxtable',
		'lbtable'=>'users',
		'lbkey'=>'users.id',
		'lbdisplay'=>'users.firstname',
	}
);

%dm_display_fields = (
	"01/Nom du dashboard"=>"name",
);

%dm_lnk_fields = (
"03//Widgets"=>"$config{baseurl}/cgi-bin/adm_migcms_dashboards_widgets.pl?colg=$colg&id_dashboard=",
		);

%dm_mapping_list = (
);

%dm_filters = (
		);

$dm_cfg{help_url} = "http://www.bugiweb.com";


# this script's name

$sw = $cgi->param('sw') || "list";
my $selfcolg=$self.'&sw='.$sw.'&id='.get_quoted('id');       

$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="colg" value="$colg" />
<input type="hidden" value="$id_dataform" name="id_dataform" />
EOH

see();

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
    $spec_bar = get_spec_buttonbar($sw);
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);;
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------