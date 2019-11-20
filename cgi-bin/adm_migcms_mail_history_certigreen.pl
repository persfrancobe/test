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



$dm_cfg{one_button} = 0;
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;

$dm_cfg{table_name} = "migcms_mail_history";
$dm_cfg{default_ordby} = "moment desc";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
my $dm_search = get_quoted('dm_search') || '';

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_mail_history_certigreen.pl?";
$dm_cfg{hiddp} = <<"EOH";
  
EOH



$dm_cfg{list_custom_action_2_func} = \&hist;



$dm_cfg{list_html_top} = <<"EOH";		
<style>
.migedit
{
	/*text:none!important;*/
}

</style>
EOH
#
#%action = (
#    '01/show'=>"Afficher",
#    '03/hide'=>"Cacher",
#    '06/delete'=>"Supprime définitivement",
#    '04/edit'=>"Modifier",
#    '02/insert'=>'Ajouter',
#	'05/login'=>'Se connecter',
#	'07/corbeille'=>'Supprime',
#	'08/restauration'=>'Restaure',
#);
       
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (    
	'01/id_member' =>
	{
		'title'=>'Utilisateur',
		'fieldtype'=>'text',
		'data_type'=>'listboxtable',
		'lbtable'=>'users',
		'lbkey'=>'id',
		'lbdisplay'=>"CONCAT(firstname,' ',lastname)",
		'lbwhere'=>"",
		'hidden'=>0,
	}


	,
	   '02/email_from'=>
	{
        'title'=>'Expéditeur',
        'fieldtype'=>'text',
        'search'=>'y',

    }
	,
	'03/email_to'=>
	{
		'title'=>'Destinataire',
		'fieldtype'=>'text',
		'search'=>'y',
	}
	,
	'04/email_position'=>
	{
		'title'=>'En tant que',
		'fieldtype'=>'text',
		'search'=>'y',
	}
	,
	'05/email_object'=>
	{
		'title'=>'Objet',
		'fieldtype'=>'text',
		'search'=>'y',
	}
	,
	'06/email_body'=>
	{
		'title'=>'Corps',
		'fieldtype'=>'textarea',
		'search'=>'y',
	}
	,
	'07/moment'=>
	{
		'title'=>'Date et heure',
		'fieldtype'=>'text',
		'search'=>'y',
		'data_type'=>'datetime',
	}
	,
	'08/email_script'=>
	{
		'title'=>'Script',
		'fieldtype'=>'text',
		'search'=>'y',
	}
	   ,
	'09/email_type'=>
	{
		'title'=>'Type',
		'fieldtype'=>'text',
		'search'=>'y',
	}
	);
  
%dm_display_fields =
(
"01/Utilisateur"=>"id_member",
"02/Date et heure"=>"moment",
"03/Expéditeur"=>"email_from",
"04/Destinataire"=>"email_to",
"05/Objet"=>"email_object",
);

%dm_lnk_fields = (

);


%dm_mapping_list = (
			
);

%dm_filters = (
#
#"1/Utilisateur"=>{
#                         'type'=>'lbtable',
#                         'table'=>'users',
#                         'key'=>'id',
#                         'text'=>"CONCAT(firstname,' ',lastname)",
#                         'col'=>'id_user',
#                         'where'=>''
#                        }
#,
#"2/Action"=>{
#                         'type'=>'lbtable',
#                         'table'=>'migcms_history',
#                         'key'=>'action',
#                         'text'=>'action',
#                         'col'=>'action',
#                         'where'=>'1 group by action'
#                        }
#,
#"3/Page"=>{
#                         'type'=>'lbtable',
#                         'table'=>'migcms_history',
#                         'key'=>'page_record',
#                         'text'=>'page_record',
#                         'col'=>'page_record',
#                         'where'=>'1 group by page_record'
#                        }
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



sub cm_sheet_history_mails_view_content
{
	my $id = get_quoted('id');
	my %migcms_mail_history = sql_line({table=>'migcms_mail_history',where=>"id='$id'"});

	$dm_output{content} = <<"EOH";
	
	$migcms_mail_history{email_object}<br /><br />
	<div class="well" style="background-color:white;padding:10px;margin:10px">$migcms_mail_history{email_body}</div>
EOH
	



}


sub hist
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};

	my $acces = <<"EOH";
		<a class="btn btn-primary" target="_blank" href="$dm_cfg{self}&sw=cm_sheet_history_mails_view_content&id=$id" data-original-title="Voir le mail" target="_blank" data-placement="bottom">
		<i class="fa fa-envelope" aria-hidden="true"></i>
		</a>
EOH

	return $acces;
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------