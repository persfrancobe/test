#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

use fwlayout;
use fwlib;

my %user = %{get_user_info($dbh,$config{current_user})} or wfw_no_access();


 
 my $id_admin = get_quoted('id_admin');
 
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 1;
$dm_cfg{wherep} = $dm_cfg{wherel} = "id_admin = '$id_admin'";
$dm_cfg{table_name} = "migcms_admin_lines";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_admin_lines.pl?id_admin=$id_admin";

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;

$dm_cfg{add_title} = "Ajouter un champs";
$dm_cfg{page_title} = "Champs d'encodage";


%types = (
    '01/text'=>"Texte",
	'02/text_id'=>"Texte traductible",
	'03/textarea'=>"Texte multilignes",
	'04/textarea'=>"Texte multilignes traductible",
	'05/textarea_editor'=>"Texte avec éditeur HTML",
	'05/textarea_editor_id'=>"Texte avec éditeur HTML traductible",
	'06/date'=>"Date",
	'07/time'=>"Heure",
	'07/euros'=>"Montant en euros",
	'09/iban'=>"IBAN",
	'10/bic'=>"BIC",
	'11/listboxtable'=>"Lien vers une autre table",
);


%dm_dfl = (
    '01/id_admin'=> 
	{
        'title'=>'ID écran',
		'hidden'=> 1,
        'fieldtype'=>'text',
        'search' => 'y',
        'mandatory'=>{"type" => 'not_empty',
                     }
    }
	,
	'02/nom'=> 
	{
        'title'=>'Nom',
        'fieldtype'=>'text',
        'fieldsize'=>'40',
        'search' => 'y',
        'mandatory'=>{"type" => 'not_empty',
                     }
    }
	
	,
	'06/type'=> 
	{
        'title'=>'Type',
        'fieldtype'=>'listbox',
	    'fieldvalues'=>\%types,
		'default_value'=>'text',
		'mandatory'=>{"type" => 'not_empty' }
    }
	,
	'14/obligatoire'=> 
	{
        'title'=>'Est obligatoire',
        'fieldtype'=>'checkbox',
		'checkedval' => 'y'
    }
	,
	'14/in_list'=> 
	{
        'title'=>'Dans la liste',
        'fieldtype'=>'checkbox',
		'checkedval' => 'y'
    }
	,
	'14/in_search'=> 
	{
        'title'=>'Dans la recherche',
        'fieldtype'=>'checkbox',
		'checkedval' => 'y'
    }
	,
	'20/lbtable'=> 
	{
        'title'=>'Nom de la table',
        'fieldtype'=>'text',
		'legend'=>'Si lien vers une table',
    }
	,
	'21/lbtable_display'=> 
	{
        'title'=>'Champs à afficher',
        'fieldtype'=>'text',
		'legend'=>'Si lien vers une table',
    }
	,
	'22/lbtable_id'=> 
	{
        'title'=>'Valeur utilisée',
        'fieldtype'=>'text',
		'legend'=>'Si lien vers une table',
    }
);

%dm_display_fields = (
    "1/Nom"=>"nom",
	"4/Type"=>"type",
	"6/Obligatoire"=>"obligatoire",
	"7/Liste"=>"in_list",
	"8/Recherche"=>"in_search",
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

if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}



sub after_save
{
    my $id = $_[1];
	see();
	my %migcms_admin_line = sql_line({table=>'migcms_admin_lines',where=>"id='$id'"});
	my %migcms_admin = sql_line({debug=>1,debug_results=>1,table=>'migcms_admins',where=>"id='$migcms_admin_line{id_admin}'"});
	my $admin_table = 'migcms_auto_'.$migcms_admin{id};
	my $current_db_name = $config{db_name};
	my $remove = 'DBI:mysql:';
	$current_db_name =~ s/$remove//g;
	
	my @list_of_existing_cols = get_list_of_cols($current_db_name,$admin_table,$dbh);
	my @migcms_admin_lines = sql_lines({debug=>0,debug_results=>0,table=>'migcms_admin_lines',where=>"id_admin='$migcms_admin{id}'"});
	foreach $migcms_admin_line (@migcms_admin_lines)
	{
		my %migcms_admin_line = %{$migcms_admin_line};
		my $existe = 0;
		foreach my $col_site (@list_of_existing_cols)
		{
			my %col_site = %{$col_site}; 
			if('auto_'.$migcms_admin_line{id} eq $col_site{COLUMN_NAME})
			{
				$existe = 1;
			}
		}
		if($existe == 0)
		{
			$msg .= '<br />Ajout de la colonne <b>'.'auto_'.$migcms_admin_line{id}.'</b> dans la table <b>'.$admin_table.'</b>';
			create_col_in_table($dbh,$admin_table,'auto_'.$migcms_admin_line{id},'text'); 
		}
		else
		{
			$msg .= '<br /> <span style="color:green">Colonne <b>'.'auto_'.$migcms_admin_line{id}.'</b> trouvée dans la table '.$admin_table.'</span>';
		}
	}
	print $msg;
}
