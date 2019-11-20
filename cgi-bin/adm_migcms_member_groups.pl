#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

use Data::Dumper;

use members;




$dm_cfg{customtitle} = $migctrad{mailings}.' > '.$migctrad{mailing_groups};
$dm_cfg{enable_search} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{trad} = 1;
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;

$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "migcms_member_groups";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?";
$dm_cfg{hiddp}=<<"EOH";

EOH



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%dm_dfl = (
	    '01/id_textid_name'=> {
	        'title'=>'Nom',
	        'fieldtype'=>'text_id',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
    
	);
	
%dm_display_fields = (
	"01/Nom"=>"id_textid_name",
		);

%dm_lnk_fields = (
# "02/Membres/Membres"=>"$config{baseurl}/cgi-bin/adm_migcms_members.pl?&id_group=",
		);

%dm_mapping_list = (
);

%dm_filters = (
		);


$sw = $cgi->param('sw') || "list";


if ($sw ne "get_all_xls") {see();}

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
			up
			mailing_send
			get_all_xls
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar($mailing_gen_bar);
    $spec_bar = get_spec_buttonbar($sw);
    $spec_bar .= "<a href=\"$dm_cfg{self}&sw=get_all_xls\" target=\"_blank\">Export XLS</a>";
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}




sub after_save
{
    my $dbh=$_[0];
    my $id =$_[1];
    	
	my @recs = sql_lines({table=>$dm_cfg{table_name},where=>"token=''"});
	foreach $rec (@recs)
	{
		my %rec = %{$rec};
		my $new_token = create_token(50);
		my $stmt = "UPDATE $dm_cfg{table_name} SET token = '$new_token' WHERE id='$rec{id}' and token=''";
        execstmt($dbh_data,$stmt);
	}	
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------