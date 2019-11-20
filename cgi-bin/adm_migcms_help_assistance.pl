#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;




$dm_cfg{add_title} = "";
$dm_cfg{table_name} = "migcms_help_assistance";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_help_assistance.pl?";
$dm_cfg{enable_search} = 1;
$dm_cfg{duplicate} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{trad} = 0;
$dm_cfg{wherel} = $dm_cfg{wherep} = "";
$dm_cfg{migcrender} = 0;
$dm_cfg{def_handmade} = 0;
$dm_cfg{operations} = 0;
$dm_cfg{default_ordby}='nom';


  
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%dm_dfl = (    
 	   
	   '01/tags'=> 
       {
			'title'=>'Page',
			'fieldtype'=>'text',
			'search' => 'y',
	    }
		,
	   '02/Titre'=> 
       {
			'title'=>'Nom',
			'fieldtype'=>'text',
			'search' => 'y',
			'mandatory'=>{"type" => 'not_empty'}          
	    }
		,
		'03/description'=> 
       {
			'title'=>'Description',
			'fieldtype'=>'textarea_editor',
			'search' => 'y',
	    },
		
	);
  
%dm_display_fields = (
 "01/Page"=>"tags",
 "02/Titre"=>"nom",
 "03/Description"=>"description",
 
);



%dm_lnk_fields = 
(

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

   my $suppl_js=<<"EOH";
    
     <style>
	 
      </style>
    
   	<script type="text/javascript">
      jQuery(document).ready(function() 
      {
          
		  
		 
		  
            
      });
    </script> 
EOH
    
    print migc_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}


