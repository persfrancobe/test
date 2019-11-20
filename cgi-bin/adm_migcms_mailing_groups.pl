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

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{customtitle} = $migctrad{mailings}.' > '.$migctrad{mailing_groups};
$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;

$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "mailing_groups";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?";
$dm_cfg{hiddp}=<<"EOH";
EOH

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%dm_dfl = (
	    '01/title'=> {
	        'title'=>$migctrad{adm_mailing_groups_title},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
    
	);

	%dm_display_fields = (
	"01/$migctrad{adm_mailing_groups_title}"=>"title",
		);

%dm_lnk_fields = (
"02/Membres/Membres"=>"$config{baseurl}/cgi-bin/adm_migcms_members.pl?&id_group=",
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
    # if ($sw eq "list") {update_members_stats();}
    &$sw();
    $gen_bar = get_gen_buttonbar($mailing_gen_bar);
    $spec_bar = get_spec_buttonbar($sw);
    $spec_bar .= "<a href=\"$dm_cfg{self}&sw=get_all_xls\" target=\"_blank\">Export XLS</a>";
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}


sub update_members_stats
{
 my $stmt = "update mailing_groups mg set nb_members = (select count(*) from mailing_lnk_member_groups lnk where lnk.id_mailing_group = mg.id and lnk.status='ok')";
 execstmt($dbh,$stmt);
 
}
sub mailing_send
{
    my $id_mailing=get_quoted('id_mailing');
    see();
    print "send mailing #$id_mailing";
}
