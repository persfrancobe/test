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
#use fwlayout;
#use fwlib;
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

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();
$dbh_data = $dbh3;

$dm_cfg{one_button} = 0;
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{table_name} = "contacts";
$dm_cfg{default_ordby} = "lastname";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
# $dm_cfg{line_func} = 'custom_orders_paid';  
$dm_cfg{dbh} = $dbh3;
my $dm_search = get_quoted('dm_search') || '';

$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
#$dm_cfg{before_del_ref} = \&before_del;

$dm_cfg{table_width} = 1100;
$dm_cfg{fieldset_width} = 1100;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_contacts.pl?";
$dm_cfg{hiddp} = <<"EOH";
  
EOH

$dm_cfg{after_mod_ref} = \&update_status;
$dm_cfg{howmany} = 50;

$config{logfile} = "trace.log";

%default_payment_types = (
    '1'=>"A la livraison",
    '2'=>'Comptant',
    '3'=>"X jours fin de mois",
    '4'=>"X jours date facture",
    '5'=>"Avant la livraison"
);

%ouinon = (
    'y'=>"Oui",
    'n'=>'Non'
);


%dm_nav =
(
    '01/header_cli'=>
    {
        'type'=>'header',
        'title'=>'Contact'
    }
    ,
    '02/client'=>
    {
        'type'=>'tab',
        'icon'=>'icon-user',
        'title'=>'Infos'
    } 
    ,
    '03/coo'=>
    {
        'type'=>'tab',
        'icon'=>'icon-bubbles ',
        'title'=>'Contact direct'
    }
    ,
    '04/coow'=>
    {
        'type'=>'tab',
        'icon'=>'icon-bubbles-4 ',
        'title'=>'Contact web'
    }  
);
           
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (    
       '01/civility'=> 
       {
	        'title'=>'Civilité',
	         'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'client'
	    }
      , 
       '04/firstname'=> 
       {
	        'title'=>'Prénom',
	         'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'client'
	    },
       '05/lastname'=> 
       {
	        'title'=>'Nom',
	         'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'client'
	    }
     ,
       '06/fonction'=> 
       {
	        'title'=>'Fonction',
	         'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'client'
	    }
     ,
        '07/date_verif'=> 
       {
	        'title'=>'Date de dernière vérif.',
	         'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'client'
	    }
       
     ,
        '08/delegue'=> 
       {
	        'title'=>'Délégué',
	         'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'client'
	    }
        ,
      '09/contact_status'=> 
       {
	        'title'=>'Actif',
          'fieldtype'=>'checkbox',
	        'checkedval' => 'n',
          'tab'=>'client'
	    },
       '44/email1'=> 
       {
	        'title'=>"Email 1",
	       'fieldtype'=>'text',
         'datatype'=>'email',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'coow'
	        
	    }
      , 
       '46/email2'=> 
       {
	        'title'=>"Email 2",
	       'fieldtype'=>'text',
         'datatype'=>'email',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'coow'
	        
	    }
      , 
       '48/email3'=> 
       {
	        'title'=>"Email 3",
	       'fieldtype'=>'text',
         'datatype'=>'email',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'coow'
	        
	    } 
         
          , 
       '62/phone'=> 
       {
	       'title'=>"Téléphone",
	       'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'coo'
	        
	    } 
       , 
       '64/extension'=> 
       {
	       'title'=>"Extension",
	       'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'coo'
	        
	    } 
       , 
       '66/gsm'=> 
       {
	       'title'=>"GSM",
	       'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'coo'
	        
	    } 
         
       , 
       '68/fax'=> 
       {
	       'title'=>"FAX",
	       'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'coo'
	        
	    }    
       , 
       '72/skype'=> 
       {
	       'title'=>"Skype",
	       'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'coo'
	        
	    }  
         , 
       '80/facebook'=> 
       {
	       'title'=>"Facebook",
	       'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'coow'
	        
	    } 
       , 
       '82/linkedin'=> 
       {
	       'title'=>"Linkedin",
	       'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
          'tab'=>'coow'
	        
	    } 
     
	);
  
%dm_display_fields = (
 "01/Nom"=>"lastname",
 "02/Prénom"=>"firstname",
 "03/Téléphone"=>"phone",
 "04/GSM"=>"gsm",
 "05/Email"=>"email1"
);


%dm_lnk_fields = (

);


%dm_mapping_list = (
			
);

%dm_filters = (
"60/Client"=>
            {
               'type'=>'lbtable',
               'table'=>'cli',
               'key'=>'id',
               'display'=>"name_client",
               'col'=>'id_client',
               'where'=>""
            },
            "70/Contact actif ?"=>
            {
                  'type'=>'hash',
            	     'ref'=>\%ouinon,
            	     'col'=>'contact_status'
            },
            "60/Forme juridique"=>
            {
               'type'=>'lbtable',
               'table'=>'clients_formes_juridiques',
               'key'=>'id',
               'display'=>"fj_name",
               'col'=>'id_forme_juridique',
               'where'=>""
            }            
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