#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;



$dm_cfg{hide_id} = 0;
$dm_cfg{trad} = 1;
$dm_cfg{duplicate} = 1;
$dm_cfg{enable_search} = 0;

$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;

$dm_cfg{wherep} = "";
$dm_cfg{wherel} = "";
$dm_cfg{table_name} = "migcms_textes_emails";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{wherep_ordby} = "";
$dm_cfg{default_ordby} = "";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?";


$dm_cfg{hiddp}=<<"EOH";

EOH


%dm_dfl = (
      '01/table_name' => 
      {
       'title'=>'Ecran',
       'fieldtype'=>'text',
	   'mandatory'=>{"type" => 'not_empty', }
      }
	  ,
	'02/name' =>
	{
		'title'=>'Nom',
		'fieldtype'=>'text',
		'mandatory'=>{"type" => 'not_empty', }
	}
	,
	'03/id_textid_texte'=>
	  {
	        'title'=>"Texte de l'email",
	        'fieldtype'=>'textarea_id_editor',
	        'search' => 'y',
	        
	    }
		 ,
	'04/id_textid_raw_texte'=>
	  {
	        'title'=>"Code HTML supplémentaire",
	        'fieldtype'=>'textarea_id',
	        'search' => 'y',
	        'mandatory'=>{"type" => '', }
	    }
	);
	

%dm_display_fields = (
	"02/Ecran "=>"table_name",
	"03/Nom "=>"name",
  # "3/Texte"=>"id_textid_texte",
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
    
    
      
    print migc_app_layout($suppl_js.$migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}

            
