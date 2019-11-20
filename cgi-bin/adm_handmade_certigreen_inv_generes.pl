#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use def_handmade;


$dm_cfg{customtitle} = $fwtrad{users_title};
$dm_cfg{enable_search} = 1;
$dm_cfg{deplie_recherche} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "id_inv NOT IN (select id from handmade_inv where migcms_deleted = 'y')";
$dm_cfg{table_name} = "handmade_inv_generes";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_handmade_certigreen_inv_generes.pl?";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_import_ref} = \&after_import;
$dm_cfg{lock_on} = 1;
$dm_cfg{lock_off} = 1;

$dm_cfg{actions} = 1;
$dm_cfg{force_addr} = 0;
$dm_cfg{force_editr} = 0;
$dm_cfg{force_duplicate} = 0;
$dm_cfg{force_duplicate} = 0;
$dm_cfg{page_title} = "Inventaire";
$dm_cfg{add_title} = "";
$dm_cfg{excel_key} = 'id';

%dm_filters = 
(
);

$dm_cfg{file_prefixe} = 'INV';

$dm_cfg{list_html_top} = <<"EOH";
EOH




%calcul_tva = (
    '01/HTVA'=>"HTVA",
    '02/TVAC'=>"TVAC",
);


%dm_dfl = 
(
	'04/reference'=> 
	{
        'title'=>'Référence',
        'fieldtype'=>'text',
		'tab'=>'',
	}
	,
	 '10/INVDESCRIPTION'=> 
	{
        'title'=>"Nom",
        'fieldtype'=>'textarea',
		'tab'=>'',
    }

	,
	'35/prix_htva'=> 
	{
        'title'=>'Prix HTVA',
        'fieldtype'=>'text',
		'data_type'=>'euros',
		'placeholder'=>"",
		'tab'=>'',
    }
		,
	'40/taux_tva'=> 
	{
        'title'=>"Taux TVA",
		'default_value'=>'21',
		'fieldtype'=>'listboxtable',
		'data_type'=>'button',
		 'lbtable'=>'eshop_tvas',
         'lbkey'=>'id',
         'lbdisplay'=>"tva_reference",
         'lbwhere'=>"" ,
		 'tab'=>'',
    }
	,
	'41/id_user'=>
	{
		'title'=>"Employé",
		'default_value'=>'',
		'fieldtype'=>'listboxtable',
		'data_type'=>'button',
		'lbtable'=>'users',
		'lbkey'=>'id',
		'lbdisplay'=>"CONCAT(firstname,' ',lastname)",
		'lbwhere'=>"" ,
		'tab'=>'',
	}
	
	
	
	
	
	
 
);



%dm_display_fields = (
    
	"40/Référence"=>"reference",
	"41/Employé"=>"id_user",
#	"42/Produit"=>"id_inv",
	"50/Nom"=>"INVDESCRIPTION",
	"60/Prix HTVA"=>"prix_htva",
	"70/Taux TVA"=>"taux_tva",
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
list_del_file
);


if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}




################################################################################



sub get_prix
{
    my $dbh = $_[0];
    my $id = $_[1];
	
	return $dm_cfg{file_prefixe}.$id;
}

sub after_save
{
    my $dbh = $_[0];
    my $id = $_[1];
	my $all = $_[2] || 'not';

#	my %inv = read_table($dbh,$dm_cfg{table_name},$id);


}