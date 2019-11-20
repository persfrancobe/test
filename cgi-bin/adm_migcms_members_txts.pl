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

         # migc translations

use members;

$dm_cfg{enable_search} = 1;
$dm_cfg{duplicate} = 1;
$dm_cfg{sort_opt} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{corbeille} = 0;
$dm_cfg{operations} = 1;
$dm_cfg{restauration} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "members_txts";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{excel_key} = "keyword";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_$dm_cfg{table_name}.pl?";
if($config{current_language} eq "")
{
   $config{current_language} = get_quoted('lg') || 1;
}
$dm_cfg{customtitle} = 'Textes membres';

$dm_cfg{hiddp}=<<"EOH";

EOH




#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    	
	    '01/keyword'=> {
	        'title'=>"Mot clé",
	        'fieldtype'=>'text',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty', }
	    }  
	);


%dm_display_fields = (
			"01/Clé"=>"keyword",
		);
    
    
    my @lgs = get_table($dbh,"migcms_languages","","encode_ok = 'y' || visible='y' ORDER BY id asc ");
    my $line = 20;
    foreach $langue (@lgs)
    {
        my %langue = %{$langue};
		my $lined = $line;
		if($line < 10)
		{
			$lined = '0'.$line;
		}
        $dm_display_fields{$lined.'/'.$langue{display_name}} = 'lg'.$langue{id};
        $line++;
    }
    
    my $line = 20;
    foreach $langue (@lgs)
    {
        my %langue = %{$langue};
		my $lined = $line;
		if($line < 10)
		{
			$lined = '0'.$line;
		}       
	   $dm_dfl{'0'.$lined.'/lg'.$langue{id}} = { 'title'=> $langue{display_name}, 'fieldtype' => 'textarea', 'search' => 'y'};
        $line++;
    }
    

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
    
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------