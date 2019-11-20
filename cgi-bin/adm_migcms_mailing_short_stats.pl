#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


my $sel = get_quoted('sel');



$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{table_name} = "migcms_mailing_short_stats";
$dm_cfg{list_table_name} = "migcms_mailing_short_stats";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_mailing_short_stats.pl?";
$dm_cfg{duplicate} = 0;
$dm_cfg{default_ordby} = "";


%ouinon = 
(
	'01/1'        =>"Oui",
	'02/0'        =>"Non",
);
my $cpt= 5;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
		# sprintf("%05d", $cpt++).'/id_migcms_page'=>{'title'=>'Mailing','translate'=>1,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'migcms_pages','lbkey'=>'id','lbdisplay'=>'id_textid_name','lbwhere'=>'','lbordby'=>'','fieldvalues'=>'','hidden'=>0},
		sprintf("%05d", $cpt++).'/id_migcms_page'=>{'title'=>'ID Mailing','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'migcms_pages','lbkey'=>'id','lbdisplay'=>'id','lbwhere'=>'','lbordby'=>'','fieldvalues'=>'','hidden'=>0},
		sprintf("%05d", $cpt++).'/id_migcms_member'=>{'title'=>'Membre','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'migcms_members','lbkey'=>'id','lbdisplay'=>'email','lbwhere'=>'','lbordby'=>'','fieldvalues'=>'','hidden'=>0},
		sprintf("%05d", $cpt++).'/sent'=>{'title'=>'Envoyé','translate'=>0,'fieldtype'=>'listbox','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'migcms_members','lbkey'=>'id','lbdisplay'=>'email','lbwhere'=>'','lbordby'=>'','fieldvalues'=>\%ouinon,'hidden'=>0},
		sprintf("%05d", $cpt++).'/open'=>{'title'=>'Ouvert','translate'=>0,'fieldtype'=>'listbox','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'migcms_members','lbkey'=>'id','lbdisplay'=>'email','lbwhere'=>'','lbordby'=>'','fieldvalues'=>\%ouinon,'hidden'=>0},
		sprintf("%05d", $cpt++).'/click'=>{'title'=>'Click','translate'=>0,'fieldtype'=>'listbox','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'migcms_members','lbkey'=>'id','lbdisplay'=>'email','lbwhere'=>'','lbordby'=>'','fieldvalues'=>\%ouinon,'hidden'=>0},    
	);

%dm_display_fields = (
			"1/ID Mailing"=>"id_migcms_page",
			"2/Membre"=>"id_migcms_member",
		);

%dm_lnk_fields = (

		);

%dm_mapping_list = (
);


 


%dm_filters = (

"5/ID Mailing"=>{
                         'type'=>'lbtable',
                         'table'=>'migcms_pages',
                         'key'=>'id',
                         'display'=>"id",
                         'col'=>'id_migcms_page',
                         'translate'=>'0',
                         'where'=>''
                        }
						,
"6/Envoyé"=>
{
      'type'=>'hash',
	     'ref'=>\%ouinon,
	     'col'=>'sent'
}
						,
"7/Ouvert"=>
{
      'type'=>'hash',
	     'ref'=>\%ouinon,
	     'col'=>'open'
}
						,
"8/Click"=>
{
      'type'=>'hash',
	     'ref'=>\%ouinon,
	     'col'=>'click'
}
);

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

if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();

	
	
    print wfw_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}
