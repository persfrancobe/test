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
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "handmade_inv";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_handmade_certigreen_inv.pl?";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_import_ref} = \&after_import;
$dm_cfg{lock_on} = 1;
$dm_cfg{lock_off} = 1;

$dm_cfg{actions} = 1;
$dm_cfg{page_title} = "Inventaire";
$dm_cfg{add_title} = "";
$dm_cfg{excel_key} = 'id';

%dm_filters = 
(
);

$dm_cfg{file_prefixe} = 'INV';

$dm_cfg{list_html_top} = <<"EOH";
EOH


#ajouter une colonne de date de derniere consultation pour l'utilisateur
my @users = sql_lines({table=>'users',where=>"id_role >= 4"});

foreach $us (@users)
{
	my %us = %{$us};

	my %check_col = sql_line({select=>"COUNT(*) as nb",table=>'INFORMATION_SCHEMA.COLUMNS',where=>"table_name = '$dm_cfg{table_name}' AND table_schema = '$config{projectname}' AND column_name = 'user_$us{id}'"});
	if(!($check_col{nb} > 0))
	{
		my $stmt = <<"EOH";
  ALTER TABLE `$dm_cfg{table_name}` ADD `user_$us{id}` varchar(10);
EOH
		execstmt($dbh,$stmt);
	}

}




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
	
	
	
	
	
	
	
 
);

my @users = sql_lines({table=>'users',where=>"id_role >= 7 and id != 25 and id != 28"});
my $cpt = 50;

foreach $us (@users) {
	my %us = %{$us};
	$dm_dfl{$cpt++.'/user_'.$us{id}} = {title=>"$us{firstname} $us{lastname}",'fieldtype'=>'checkbox'};
}


%dm_display_fields = (
    
	"40/Référence"=>"reference",
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

	my %inv = read_table($dbh,$dm_cfg{table_name},$id);


	my @users = sql_lines({table=>'users',where=>"id_role >= 7 and id != 25 and id != 28"});
	foreach $us (@users) {
		my %us = %{$us};

		if($inv{'user_'.$us{id}} eq 'y')
		{
			my %update_genere = (
				id_user => $us{id},
				id_inv => $inv{id},
				reference => "$us{lastname} $inv{reference}",
				INVDESCRIPTION => $inv{INVDESCRIPTION},
				prix_htva => $inv{prix_htva},
				taux_tva => $inv{taux_tva},
				prix_tvac => $inv{prix_tvac},
			);
			%update_genere = %{dm::quoteh(\%update_genere)};

			sql_set_data({dbh=>$dbh,debug=>0,table=>$dm_cfg{table_name}.'_generes',data=>\%update_genere, where=>"id_user = '$update_genere{id_user}' AND id_inv='$update_genere{id_inv}'"});
		}
	}
}