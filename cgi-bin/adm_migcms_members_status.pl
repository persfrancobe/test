#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use members;
use def_handmade;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);

$dm_cfg{trad} = 1;
$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 1;
$dm_cfg{operations} = 0;
$dm_cfg{corbeille} = 0;
$dm_cfg{excel} = 0;
$dm_cfg{restauration} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "migcms_members_status";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_members_status.pl?";
if($config{current_language} eq "")
{
   $config{current_language}=get_quoted('lg') || 1;
}
$dm_cfg{default_ordby}='ordby';


$dm_cfg{excel_key} ='id';

           
%dm_dfl = 
(    
 	   
	'01/id_textid_name'=> 
		{
			'title'     =>'Nom',
			'fieldtype' =>'text_id',
			'search'    => 'y',
			'mandatory'=>{"type" => 'not_empty'},
			'trad'      =>1,         
		} 
);
  
%dm_display_fields = 
(
 "01/Nom"=>"id_textid_name",
);


%dm_lnk_fields = 
(
);

%dm_mapping_list = (
);

%dm_filters = 
(
);

%dm_import_excel = (
);


$sw = $cgi->param('sw') || "list";
$sel = $cgi->param('sel') || "";
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

    if ($sw eq "list") {$spec_bar.=$lnkxls;}
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};

    my $script ;
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
