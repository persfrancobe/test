#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;


$dm_cfg{customtitle} = $fwtrad{users_title};
$dm_cfg{enable_search} = 1;
$dm_cfg{deplie_recherche} = 1;

$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "";

$dm_cfg{table_name} = "migcms_support";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_support.pl?";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;

$dm_cfg{file_prefixe} = 'SUP';

$dm_cfg{autocreation} = 1;
$dm_cfg{add} = 1;
$dm_cfg{operations} = 0;
$dm_cfg{excel_key} = 'id';
$dm_cfg{default_ordby}='moment desc';


%type_support = 
(
	'01/Bug'=>'Bug',
	'02/Correction'=>'Correction',
	'03/Amélioration'=>'Amélioration',
	'04/Développement'=>'Développement',
	'05/Urgence contractuelle'=>'Urgence contractuelle',
	'06/Urgence non contractuelle'=>'Urgence non contractuelle',
	'07/Développement futur'=>'Développement futur',
);

%statut_support = 
(
	'01/Nouveau'=>'Nouveau',
	'02/Attente'=>'Attente',
	'03/Traitement/Traitement en cours'=>'Traitement en cours',
	'04/Informations nécessaires'=>'Informations nécessaires',
	'05/Traité'=>'Traité',
	'06/Annulé'=>'Annulé',
	
);

%urgence = 
(
	'01/1'=>'1',
	'02/2'=>'2',
	'03/3'=>'3',
	'04/4'=>"4",
);


%dm_dfl = 
(    
	'04/type_support'		=>{'title'=>'Assistance','fieldtype'=>'listbox','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},'tab'=>'','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','fieldvalues'=>\%type_support,'hidden'=>0},
	'04/statut_support'		=>{'title'=>'Statut','fieldtype'=>'listbox','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},'tab'=>'','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','fieldvalues'=>\%statut_support,'hidden'=>0},
	'06/description_support'		=>{'title'=>'Requête','fieldtype'=>'textarea','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},'tab'=>'','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','fieldvalues'=>'','hidden'=>0},
	'07/url_page'			=>{'title'=>'URL','fieldtype'=>'text','data_type'=>'','mask'=>'','search' => 'y','mandatory'=>{"type" => ''},'tab'=>'','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','fieldvalues'=>'','hidden'=>0},
	'08/id_script'=>{'title'=>'Module','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>'','default_value'=>'','lbtable'=>'scripts','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>'','fieldvalues'=>'','hidden'=>0},
	'09/urgence'	=>{'title'=>'urgence',legend=>"De 1 (je suis bloqué) à 4 (J'ai le temps",'fieldtype'=>'listbox','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},'tab'=>'','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','lbordby'=>'','fieldvalues'=>\%urgence,'hidden'=>0},
	'10/tel'	=>{'title'=>'Téléphone 1','fieldtype'=>'text','data_type'=>'tel','search' => 'y','mandatory'=>{"type" => ''},'tab'=>'','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','lbordby'=>'ordby','fieldvalues'=>'','hidden'=>0},
	'11/gsm'	=>{'title'=>'GSM','fieldtype'=>'text','data_type'=>'gsm','search' => 'y','mandatory'=>{"type" => ''},'tab'=>'','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','lbordby'=>'ordby','fieldvalues'=>'','hidden'=>0},
	'12/remarque'	=>{'title'=>'Remarque','fieldtype'=>'textarea','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},'tab'=>'','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','lbordby'=>'ordby','fieldvalues'=>'','hidden'=>0},
	'13/fichiers'	=>{'title'=>'Pièces jointes','fieldtype'=>'files_admin','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},'tab'=>'','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','lbordby'=>'ordby','fieldvalues'=>'','hidden'=>0},
);

%dm_display_fields = (
	"01/Date"=>"moment",
	"04/Statut"=>"statut_support",
	"08/Type"=>"type_support",
	"12/Module"=>"id_script",
	"16/Urgence"=>"urgence",
	"20/Description"=>"description_support",
);

 %dm_filters = 
	(
		"01/Module"=>
		{
			'type'=>'lbtable',
			'table'=>'scripts',
			'key'=>'id',
			'translate'=>0,
			'display'=>'name',
			'col'=>'id_script',
			'ordby'=>'',
			'where'=>''
		}
		,		
		"05/Statut"=>
		{
			'type'=>'hash',
			'ref'=>\%statut_support,
			'col'=>'statut_support'
		}
		,		
		"06/Type"=>
		{
			'type'=>'hash',
			'ref'=>\%type_support,
			'col'=>'type_support'
		}
		,
		"12/Dates"=>{
		 'type'=>'fulldaterange',
		 'col'=>'moment',
		}		
		
	);

%dm_lnk_fields = 
(
# "01/Identifiant/col_identifiant"=>"getcode*",
);

%dm_mapping_list = (
# "getcode" => \&getcode,
);




$sw = $cgi->param('sw') || "list";

see();


$dm_cfg{list_html_top} = <<"EOH";
<script>
jQuery(document).ready(function() 
{
	 
	
   
});

</script>

EOH

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

    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}







sub after_save
{
    my $id = $_[1];
	
	my %rec = read_table($dbh,$dm_cfg{table_name},$id);
	
	if($rec{statut_support} eq '')
	{
		my $stmt = <<"EOH";
			UPDATE $dm_cfg{table_name} SET statut_support = 'Nouveau' WHERE id = '$id'
EOH
		execstmt($dbh,$stmt);
	 }
	
	if($rec{moment} eq '0000-00-00 00:00:00')
	{
		my $stmt = <<"EOH";
			UPDATE $dm_cfg{table_name} SET moment = NOW() WHERE id = '$id'
EOH
		execstmt($dbh,$stmt);
	 }
	 else
	 {
			 my $email_body = <<"EOH";
			Type: $rec{type_support}<br /><br />
			Statut: $rec{statut_support}<br /><br />
			Description: <br/>$rec{description_support}<br />
EOH
			 send_mail('info@selion.be','alexis@bugiweb.com','Support: Selion: '.$rec{id},$email_body,"html");
	 
	 }
	 

	 
	 
}

