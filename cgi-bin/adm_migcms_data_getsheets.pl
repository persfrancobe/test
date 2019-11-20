#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;


$dm_cfg{enable_search} = 1;

$dm_cfg{sort_opt} = 0;
$dm_cfg{duplicate} = 0;

$dm_cfg{table_name} = "migcms_data_getsheets";
$dm_cfg{default_ordby} = "";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_data_getsheets.pl?";

my $where_role = "";
$dm_cfg{wherep} = $dm_cfg{wherel} =  "";



$dm_cfg{add_title} = "Ajouter un get sheet";

%dm_dfl = (
    '01/getsheets_limit'=> {
        'title'=>'Quantité',
        'fieldtype'=>'text',
        'search' => 'y',
        'mandatory'=>{"type" => 'not_empty',
                     }
    }
	,
'12/id_data_family'=> 
{
'title'=>'Famille',
'fieldtype'=>'listboxtable',
'lbtable'=>'data_families',
'lbkey'=>'id',
'lbdisplay'=>'name',
'mandatory'=>{"type" => 'not_empty'},
}
,
'13/id_data_search_form'=> 
{
'title'=>'Moteur de recherche',
'fieldtype'=>'listboxtable',
'lbtable'=>'data_search_forms',
'lbkey'=>'id',
'translate'=>'1',
'lbdisplay'=>'id_textid_name',
'mandatory'=>{"type" => 'not_empty'},
}
,
	'14/getsheets_ordby'=> {
        'title'=>'Trier par',
        'fieldtype'=>'text',
        'mandatory'=>{"type" => '',
                     }
    }
	,
'23/id_template_object'=> 
{
'title'=>$migctrad{adm_data_families_id_template_object},
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'id',
'lbdisplay'=>'name',
'lbwhere'=>"type = 'data'",
'mandatory'=>{"type" => 'not_empty'},

}

,
'24/getsheets_where_id_category'=> 
{
'title'=>'Condition catégorie',
'fieldtype'=>'listboxtable',
'lbtable'=>'data_categories',
'translate'=>'1',
'lbkey'=>'id',
'lbdisplay'=>'id_textid_name',
'lbwhere'=>"",
}
,
'33/getsheets_where'=> {
    'title'=>'Condition supplémentaire',
    'fieldtype'=>'text',
    'fieldsize'=>'40',
    'search' => 'y',
    'mandatory'=>{"type" => '',
                 }
},
'40/getsheets_custom_function_where'=> {
    'title'=>'Fonction sur-mesure pour renvoyer le where',
    'fieldtype'=>'text',
    'fieldsize'=>'40',
    'search' => 'y',
    'mandatory'=>{"type" => '',
                 }
},
'50/related_sheets'=> {
    'title'=>'Afficher les sheets associées (A utiliser sur la page détail d\'une fiche)',
    'fieldtype'=>'checkbox',
    'checkvalue'=>"y",
    'search' => 'y',
    'mandatory'=>{"type" => '',
         }
},
	
);

%dm_display_fields = (
    "01/Quantité"=>"getsheets_limit",
	"02/Famille"=>"id_data_family",
	"03/Moteur"=>"id_data_search_form",
	"04/Tri"=>"getsheets_ordby",
	"05/Template"=>"id_template_object",
	"08/Condition catégorie"=>"getsheets_where_id_category",
	"09/Condition supplémentaire"=>"getsheets_where",
    "10/Produits associés"=>"related_sheets",
);

	$dm_lnk_fields{"99/Balise"} = "balise*";
	$dm_mapping_list{balise} = \&balise;



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
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}





sub balise
{
    my $dbh = $_[0];
    my $id_rec = $_[1];
    my %rec = read_table($dbh,$dm_cfg{table_name},$id_rec);
	return <<"EOH"
	MIGC_DATA_GETSHEETS_[$id_rec]_HERE
EOH
	
	
}