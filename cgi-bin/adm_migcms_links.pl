#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
# migc modules

use migcrender;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		###############################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}
 

# $dm_cfg{dbh} = $dbh_data;
$dm_cfg{disable_mod} = 'n';   
$dm_cfg{disable_buttons} = 'n';
$dm_cfg{show_id} = 1;
$dm_cfg{trad} = 1;
$dm_cfg{enable_search} = 0;

$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;

$dm_cfg{wherep} = "";
$dm_cfg{wherel} = "";
$dm_cfg{table_name} = "migcms_links";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{wherep_ordby} = "";
$dm_cfg{default_ordby} = "link_type,id desc";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?";
$dm_cfg{col_id} = 'id';
$dm_cfg{inline_edit} = 1;


$dm_cfg{hiddp}=<<"EOH";

EOH

$config{logfile} = "trace.log";

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	   
      # '01/link_name'=> {
	        # 'title'=>"Nom du lien",
	        # 'fieldtype'=>'text',
	        # 'search' => 'y',
	        # 'mandatory'=>{"type" => 'not_empty', }
	    # }
        # ,
		
		'02/id_textid_link_name'=> 
	  {
	        'title'=>"Nom",
	        'fieldtype'=>'text_id',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty', }
	    }
        ,
      '11/id_textid_link_url' => 
      {
       'title'=>'URL',
       'fieldtype'=>'text_id',
       'mandatory'=>{"type" => 'not_empty', }
      } 
	   ,
      '13/link_type' => 
      {
       'title'=>'Type',
       'fieldtype'=>'text',
      } 
      
	);
	

%dm_display_fields = (
	# "01/Nom du lien"=>"link_name",
	"02/Nom "=>"id_textid_link_name",
  "3/URL"=>"id_textid_link_url",
  "4/Type"=>"link_type"
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
			effect_gallery
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();

    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
#     my $id_banner_zone=get_quoted('id');
#     my $markup=get_markup($id_banner_zone);
    
    my $suppl_js=<<"EOH";
    
EOH
      
    print migc_app_layout($suppl_js.$migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}

            
