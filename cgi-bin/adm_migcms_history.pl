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
$dm_cfg{corbeille} = 0;
$dm_cfg{table_name} = "migcms_history";
$dm_cfg{default_ordby} = "moment desc";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{line_func} = \&migcms_tr_color;
my $dm_search = get_quoted('dm_search') || '';

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_history.pl?";
$dm_cfg{hiddp} = <<"EOH";
  
EOH

$dm_cfg{after_mod_ref} = \&update_status;

$dm_cfg{page_title} = 'Historique';

$dm_cfg{add} = 0;
$dm_cfg{delete} = 0;
$dm_cfg{modification} = 0;


$dm_cfg{list_html_top} = <<"EOH";		
<style>
.migedit
{
	display:none!important;
}

</style>
EOH

%action = (
    '01/show'=>"Afficher",
    '03/hide'=>"Cacher",
    '06/delete'=>"Supprime définitivement",
    '04/edit'=>"Modifier",
    '02/insert'=>'Ajouter',
	'05/login'=>'Se connecter',
	'07/corbeille'=>'Supprime',	
	'08/restauration'=>'Restaure',	
);
       
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (    
      '01/action'=> 
       {
	        'title'=>'Action',
			'search'=>'y',
	         'fieldtype'=>'text',
		 'fieldvalues'=>\%action,
          'mandatory'=>{"type" => 'not_empty'}
	    }

       ,  
	   '02/id_user'=> 
	{
        'title'=>'Utilisateur',
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
	   '03/date'=> 
       {
	        'title'=>'Date',
	         'fieldtype'=>'text',
			 'data_type'=>'date',
	    }
 ,
	   '04/time'=> 
       {
	        'title'=>'Heure',
	         'fieldtype'=>'text',	 
			 'data_type'=>'time',
	    }
	   ,
	    '05/page_record'=> 
       {
	        'title'=>'Page',
	         'fieldtype'=>'text',
			   'search' => 'y'
	    }
		,
	    '06/id_record'=> 
       {
	        'title'=>'ID',
	         'fieldtype'=>'text',
			   'search' => 'y'
	    }
		 ,
	    '07/infos'=> 
       {
	        'title'=>'Infos',
	         'fieldtype'=>'display',
			   'search' => 'y'
	    }

	);
  
%dm_display_fields = 
(
"01/Date"=>"date",
"02/Heure"=>"time",
"03/Utilisateur"=>"id_user",
"04/Action"=>"action",
"05/Page"=>"page_record",
"07/# Enregistrement"=>"id_record",
);

%dm_lnk_fields = (

);


%dm_mapping_list = (
			
);

%dm_filters = (

"1/Utilisateur"=>{
                         'type'=>'lbtable',
                         'table'=>'users',
                         'key'=>'id',
                         'display'=>"CONCAT(firstname,' ',lastname)",
                         'col'=>'id_user',
                         'where'=>''
                        }
,
"2/Action"=>{
                         'type'=>'lbtable',
                         'table'=>'migcms_history',
                         'key'=>'action',
                         'display'=>'action',
                         'col'=>'action',
                         'where'=>'1 group by action'
                        }
,
"3/Page"=>{
                         'type'=>'lbtable',
                         'table'=>'migcms_history',
                         'key'=>'page_record',
                         'display'=>'page_record',
                         'col'=>'page_record',
                         'where'=>'1 group by page_record'
                        }
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



sub migcms_tr_color
{
	my $id = $_[1];
	my %d = %{$_[2]};
	
	#traductions migctrad erronées
	my %trad_err =
	(
		'$migctrad{add_action}'=>'ajoute',
		'$migctrad{change}'=>'modifie',
	);
	if($trad_err{$d{line}{action}} ne '')
	{
		$d{line}{action} = $trad_err{$d{line}{action}};
	}
	
	
	
	my $action = $d{line}{action};
	
	#traductions classes
	my %trad_actions =
	(
		'se connecte'=>'login',
		'auto connecte'=>'login',
		'modifie'=>'edit',
		'affiche'=>'show',
		'cache'=>'hide',
		'trie'=>'sort',
		'ajoute'=>'insert',
		'erreur connexion'=>'error',
	);
	if($trad_actions{$action} ne '')
	{
		$action = $trad_actions{$action};
	}
	
	my %corr_class=(
	'error' => 'danger',
	'delete' => 'danger',
	'insert' => 'success',
	'edit' => 'warning',
	'update' => 'warning',
	'sort' => 'info',
	'show' => 'info',
	'hide' => 'info',
	'login'=>'success',
	);
	return <<"EOH";
	<tr id="$id" class="$corr_class{$action} action_$action rec_$id">
EOH
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------