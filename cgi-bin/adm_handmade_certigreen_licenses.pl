#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;




$dm_cfg{default_tab} = 'license';



%langue = 
(
	'01/FR'=>'FR',
	'02/NL'=>'NL',
	'03/EN'=>'EN',
	'04/DE'=>'DE',
);

$dm_cfg{customtitle} = $fwtrad{users_title};
$dm_cfg{enable_search} = 1;
$dm_cfg{add} = 0;
$dm_cfg{delete} = 0;

$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "handmade_certigreen_licenses";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_handmade_certigreen_licenses.pl?";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;


$dm_cfg{file_prefixe} = 'INF';

%license_type_companys = (
	'res.'=>"res.",
	'ipp.'=>"ipp.",
	'sprl.'=>"sprl.",
	'sa.'=>"sa.",
	'scrl.'=>"scrl.",
	'sarl.'=>"sarl.",
	'asbl.'=>"asbl.",
	'e&a.'=>"e&a.",
	'spb.'=>"spb.",
	'sas.'=>"sas.",
	'ltd.'=>"ltd.",
	'gmbh.'=>"gmbh.",
	'sarl.'=>"sarl.",
	'sc.'=>"sc.",
	'ag.'=>"ag.",
	'inc.'=>"inc.",
	'xxx.'=>"xxx.",
);


%dm_dfl = 
(
'03/license_name'=> 
{
'title'=>'Dénomination',
'fieldtype'=>'text',
'search' => 'y',
'mandatory'=>{"type" => 'not_empty',
	 }
}
,
'05/vat'=> 
{
'title'=>'TVA',
'fieldtype'=>'text',
'mask'=>'AAAA AAAA AAAA AAAA AAAA AAAA AAAA AAAA AAAA AAAA AAAA AAAA AAAA AAAA AAAA',

}
,
'51/street'=> 
{
'title'=>'Adresse L1',
'fieldtype'=>'text',
}
,
'52/street2'=> 
{
'title'=>'Adresse L2',
'fieldtype'=>'text',
}
,
'53/number'=> 
{
'title'=>'Boite postale',
'fieldtype'=>'text',
}
,
'54/zip'=> 
{
'title'=>'Code postal',
'fieldtype'=>'text',
}
,
'55/city'=> 
{
'title'=>'Ville',
'fieldtype'=>'text',
}
,
'56/country'=> 
{
'title'=>'Pays',
'fieldtype'=>'text',
}
,
'57/tel'=> 
{
'title'=>'Téléphone',
'data_type'=>'tel',
'fieldtype'=>'text',
}
,
'58/fax'=> 
{
'title'=>'FAX',
'data_type'=>'tel',
'fieldtype'=>'text',
}
,
'59/gsm'=> 
{
'title'=>'Mobile',
'data_type'=>'tel',
'fieldtype'=>'text',
}
,
'60/email'=> 
{
'title'=>'Email',
'data_type'=>'email',
'fieldtype'=>'text',
}
,
'62/iban'=> 
{
'title'=>'IBAN',
'data_type'=>'iban',
'fieldtype'=>'text',
}
,
'63/bic'=> 
{
'title'=>'bic',
'fieldtype'=>'text',
'data_type'=>'bic',
}
,
'67/remarque'=> 
{
'title'=>"Remarque",
'fieldtype'=>'textarea',
}
,
'77/logo_document'=> 
{
'title'=>"Logo des documents",
'fieldtype'=>'files_admin',
}
,
'78/logo_width'=> 
{
'title'=>"Largeur du logo en pixels",
'fieldtype'=>'text',
}
,
'79/logo_height'=> 
{
'title'=>"hauteur du logo en pixels",
'fieldtype'=>'text',
}
,
'80/cg'=> 
{
'title'=>"Conditions générales pour les documents",
'fieldtype'=>'textarea_editor',
}
);

%dm_display_fields = (
    "1/Libelle"=>"license_name",
);

%dm_lnk_fields = 
(
);

%dm_mapping_list = (
);


$sw = $cgi->param('sw') || "list";

see();


my @fcts = qw(
add_form
mod_form
list
);


if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}


sub after_save
{
    my $dbh = $_[0];
    my $id = $_[1];
      
	
}
