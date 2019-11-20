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

use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset);
$dbh_data = $dbh;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{add} = 0; 
$dm_cfg{trad} = 0;
$dm_cfg{tree} = 0;
$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{no_export_excel} = 1;


$dm_cfg{visibility} = 0;
$dm_cfg{sort} = 0;
$dm_cfg{modification} = 0;
$dm_cfg{delete} = 0;

$dm_cfg{nolabelbuttons} = 'y';

$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "migcms_pages";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{javascript_custom_func_form} = 'after_load';

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_translations.pl?";

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;

$dm_cfg{list_func} = 'list_translations';


$dm_cfg{custom_navbar} = <<"EOH";

EOH

$dm_cfg{list_html_top} .= <<"EOH";
 <script type="text/javascript"> 
    
    jQuery(document).ready(function() 
    { 
		
      
	});
	
    
    function after_load()
    {
        
    }
    </script>
	<style>

     #migc4_main_table
     {
        display:none;
     }
     </style>
EOH


if($config{current_language} eq "")
{
   $config{current_language}=get_quoted('lg') || 1;
}



$dm_cfg{hiddp}=<<"EOH";

EOH


        

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    
      '01/migcms_pages_type'=> 
      {
          'title'=>"Type",
          'fieldtype'=>'listbox',
          'data_type'=>'btn-group',
          'fieldvalues'=>\%types,
          'tab'    => 'page',
          'default_value'=>'page',
      }
      ,
       '02/id_textid_name'=> 
      {
	        'title'=>'Titre',
	        'fieldtype'=>'text_id',
	        'search' => 'y',
				'tab'    => 'page'
	    }
      ,
	    '05/id_tpl_page' => 
      {
           'title'=>'Canevas',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'templates',
           'lbkey'=>'id',
           'lbdisplay'=>'name',
           'lbwhere'=>"type = 'page'" ,
          'tab'    => 'page'
      }
      ,
	    '99/id_father' => 
      {
           'title'=>'Menu parent',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'migcms_pages, txtcontents',
           'lbkey'=>'migcms_pages.id',
           'lbdisplay'=>'lg1',
           'lbwhere'=>"migcms_pages_type = 'directory' AND txtcontents.id = migcms_pages.id_textid_name",
          'tab'    => 'page'
      }
      ,
      '09/id_migcms_link' => 
      {
           'title'=>'Lien',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'migcms_links',
           'lbkey'=>'id',
           'lbdisplay'=>'link_name',
           'lbwhere'=>"",
		   			'legend'=>'<a href="#" class="btn btn-default addlink"><i class="fa fa-plus"></i> Ajouter un nouveau lien</a>',
           'tab'    => 'page'
      }
      ,
      '10/new_migcms_link_name'=> 
      {
	        'title'=>'<i class="fa fa-plus"></i> Nom du lien',
	        'fieldtype'=>'text',
	        'search' => 'y',
          'tab'    => 'page'
	    }
       ,
      '11/new_migcms_link_url'=> 
      {
	        'title'=>'<i class="fa fa-plus"></i> URL du lien',
	        'fieldtype'=>'text_id',
			'legend'=>'',
	        'search' => 'y',
          'tab'    => 'page'
	    }
      ,
      '20/id_textid_url'=> 
      {
	        'title'=>"Texte pour l'url",
	        'fieldtype'=>'text_id',
	        'search' => 'y',
          'tab'    => 'referencement'
	    }
      ,
      '21/id_textid_meta_title'=> 
      {
	        'title'=>'Titre',
	        'fieldtype'=>'textarea_id',
	        'search' => 'y',
          'tab'    => 'referencement'
	    }
      ,
      '22/id_textid_meta_description'=> 
      {
	        'title'=>'Description',
	        'fieldtype'=>'textarea_id',
	        'search' => 'y',
          'tab'    => 'referencement'
	    }
      ,
      '24/id_textid_meta_keywords'=> 
      {
	        'title'=>'Mots clés',
	        'fieldtype'=>'textarea_id',
	        'search' => 'y',
          'tab'    => 'referencement'
	    }
	);

%dm_display_fields =  
      (
	      
      );  
%dm_lnk_fields = (
		);
                                                         
%dm_mapping_list = (
);

%dm_filters = (
      
		);

$dm_cfg{help_url} = "http://www.bugiweb.com";

# this script's name

$sw = $cgi->param('sw') || "list";

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
    see();
    dm_init();
    &$sw();

    if ($sw eq "list") {$spec_bar.=$lnkxls;}
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title});
}

sub after_save
{
    my $dbh=$_[0];
    my $id =$_[1];
    
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub before_del
{
  my $dbh = $_[0];
  my $id = $_[1];
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------