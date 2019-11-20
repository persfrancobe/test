#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI; 
use DBI;  
use def; 
use tools; 
use dm;

$dm_cfg{customtitle} = $migctrad{blocktypes_title};
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "mailing_campaigns";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_mailings_campaigns.pl?";


%dm_dfl = (
		'01/campaign_name'=> {
	        'title'=>$migctrad{mailings_campaign_name},
	        'fieldtype'=>'text',
	        'search' => 'y',
	    }
	);

	%dm_display_fields = 
	(
		"02/$migctrad{mailings_campaign_name}"=>"campaign_name",
	);

	

	%dm_lnk_fields = 
	(
	);

	%dm_mapping_list = 
	(
	);

	%dm_filters = (
	);
	
$dm_cfg{'list_custom_action_1_func'} = \&custom_content_edit;
$dm_cfg{'list_custom_action_2_func'} = \&get_stats;


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


sub custom_content_edit
{
	my $id = $_[0];
	my $colg = $_[1];
	my %rec = %{$_[2]};
	
	
	my $sel_page_newsletters = 0;
	my %rec_script = sql_line({table=>'scripts',where=>"url LIKE '%adm_migcms_pages_newsletters.pl?%'"});

	
	my $edit_content = <<"EOH";
		<a href="$config{baseurl}/cgi-bin/adm_migcms_pages_newsletters.pl?&mailing_id_campaign=$rec{id}&sel=$rec_script{id}" data-placement="bottom" data-original-title="Gérer les newsletters de la campagne" data-placement='top' class="btn btn-default "> 
		<i class="fa fa-pencil-square-o fa-fw"></i> </a>
EOH
}

sub get_stats
{
    my $id = $_[0];
	$script_rec{id} = get_quoted('sel');
	my $url = 'adm_migcms_dashboard.pl?mailing=y&id_dashboard=2&id_campaign='.$id.'&sel='.$script_rec{id};
	
	my $acces = <<"EOH";
		<a class="btn btn-default" href="$url" data-original-title="Statistiques de la newsletter" data-placement="bottom">
			<i class="fa fa-bar-chart" aria-hidden="true"></i>
		</a>
EOH

	return $acces;
}