#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
#
#
#
# migc modules
#
#         # migc translations
#
use sitetxt;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


# $dbh_data = $dbh3;
my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}
$dm_cfg{one_button} = 0;
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{table_name} = "migcms_sys";
$dm_cfg{default_ordby} = "moment desc";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{line_func} = '';  
my $dm_search = get_quoted('dm_search') || '';

$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_sys.pl?";
$dm_cfg{hiddp} = <<"EOH";
  
EOH



$dm_cfg{page_title} = 'SYS';

$dm_cfg{add} = 0;
$dm_cfg{delete} = 0;
$dm_cfg{modification} = 0;


$config{logfile} = "trace.log";

$dm_cfg{list_html_top} = <<"EOH";
<style>
	
</style>
EOH

       
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (    
      '01/id'=> 
       {
	        'title'=>'SYS',
	         'fieldtype'=>'text',
			 'search'=>'y',
	    }

       ,  
	   '02/id_user'=> 
	{
        'title'=>'Utilisateur',
		 'search'=>'y',
        'fieldtype'=>'listboxtable',
		 'lbtable'=>'users',
         'lbkey'=>'id',
         'lbdisplay'=>"CONCAT(firstname,' ',lastname)",
         'lbwhere'=>"" ,
		'mandatory'=>
		{"type" => 'not_empty',
		}
    }
	   ,
	   '03/moment'=> 
       {
	        'title'=>'Date',
	         'fieldtype'=>'text',
	    }
	   ,
	    '05/nom_table'=> 
       {
	        'title'=>'Table impactée',
			
	         'fieldtype'=>'text',
			   'search' => 'y'
	    }
		,
	    '06/id_table'=> 
       {
	        'title'=>'Code',
	         'fieldtype'=>'text',
			  'search' => 'y'
	    }
		
	);
  
%dm_display_fields = 
(
"01/SYS"=>"id",
"02/Date"=>"moment",
"03/Utilisateur"=>"id_user",
"04/Table"=>"nom_table",
"05/Code"=>"id_table",
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
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);

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





#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_and_check
{
	my %item; 
  my $op = $_[0];
  


	return (\%item);	
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_view
{
	my %item = %{$_[0]};
	my $form = build_view(\%dm_dfl,\%item);

	return $form;
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub before_del
{
  my $dbh = $_[0];
  my $id = $_[1];
  
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------