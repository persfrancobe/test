#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

my %user = %{get_user_info($dbh,$config{current_user})} or wfw_no_access();



$dm_cfg{customtitle} = $fwtrad{users_title};
$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "migcms_admins";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_admins.pl?";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;

$dm_cfg{add_title} = "Ajouter un écran d'encodage";
$dm_cfg{page_title} = "Ecrans d'encodage";

$dm_cfg{custom_style_for_contextual_actions} = 'width: 150px;';
$dm_cfg{file_prefixe} = 'ADM';
$dm_cfg{default_ordby} = 'nom';

%dm_dfl = (
    '01/nom'=> 
	{
        'title'=>'Nom',
        'fieldtype'=>'text',
        'search' => 'y',
		'disable_update'=>1,
		'mandatory'=>{"type" => 'not_empty',
		}
    }
	,
	'02/acronyme'=> 
	{
        'title'=>'Acronyme',
		'mask'=>'AAA',
        'fieldtype'=>'text',

    }
);

%dm_display_fields = (
    
	"02/Libelle"=>"nom",
);

%dm_lnk_fields = (
# "01/Identifiant"=>"getcode*",
"99//Champs"=>"$config{baseurl}/cgi-bin/adm_migcms_admin_lines.pl?&id_admin=",
);




%dm_mapping_list = (
"getcode" => \&getcode,
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
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}




################################################################################



sub after_save
{
    my $id = $_[1];
	
	my %migcms_admin = read_table($dbh,'migcms_admins',$id);
	my @list_of_tables = get_list_of_tables($config{projectname},$dbh);
    
	my $existe = 0;   
	my $admin_table = 'migcms_auto_'.$id;
    
	foreach my $table (@list_of_tables)
    {
         if($table ne '')
         {
			if($table eq $admin_table)
			{
				$existe = 1;
			}
         }   
    }
	
	if($existe == 0 && trim($migcms_admin{nom}) ne '')
	{
		 my $stmt = <<"EOH";
		 CREATE TABLE IF NOT EXISTS `$admin_table` (
			`id` int(11) NOT NULL AUTO_INCREMENT,
			`migcms_deleted` enum('y','n') NOT NULL DEFAULT 'n',
			PRIMARY KEY (`id`)
		  ) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=3000001 ;
EOH
		  execstmt($dbh,$stmt);
	}  
}




sub getcode
{
    my $dbh = $_[0];
    my $id = $_[1];
	
	return $dm_cfg{file_prefixe}.$id;
}