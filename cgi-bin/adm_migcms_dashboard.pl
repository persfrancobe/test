#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
see(); 
my $id_dashboard = get_quoted('id_dashboard');
my $sw = $cgi->param('sw') || "start";
dm_init();
&$sw();
exit;


sub start
{

my $params = $ENV{QUERY_STRING};
my $mailing = get_quoted('mailing');
my $id_page = get_quoted('id_migcms_page');
my $id_sending = get_quoted('id_sending');
my $id_campaign = get_quoted('id_campaign');

my $page_name = "";

if($id_page != "" && $mailing eq 'y') {
	my %page_title = sql_line({debug=>0,table=>"migcms_pages",select=>'mailing_object',where=>"id='$id_page'",limit=>'0,1'});
	$page_name = " (".$page_title{mailing_object}.")";
}

if($id_sending != "" && $mailing eq 'y') {
	my %page_title = sql_line({debug=>0,table=>"mailing_sendings",select=>'mailing_object',where=>"id='$id_sending'",limit=>'0,1'});
	$page_name = " (".$page_title{mailing_object}.")";
}

if($id_campaign != "" && $mailing eq 'y') {
	my %page_title = sql_line({debug=>0,table=>"mailing_campaigns",select=>'campaign_name',where=>"id='$id_campaign'",limit=>'0,1'});
	$page_name = " (".$page_title{campaign_name}.")";
}

my $dashboard_content = '<div class="wrapper">';

my %dashboard_name = sql_line({debug=>0,table=>"dashboards",select=>'name',where=>"id='$id_dashboard'",limit=>'0,1'});

$dashboard_content .= '<div class="header-actions dashboard-content"><div class="row"><div class="col-lg-12"><h1 class="maintitle">'.$dashboard_name{name}.$page_name.'</h1></div></div>';


$stmt = <<"EOSQL";
SELECT list.id, list.grid, widgets.name, widgets.script, widgets.html, widgets.function, list.header, list.color, list.name
	FROM lnk_dashboards_widgets as list, widgets
	WHERE list.id_dashboard = $id_dashboard
	AND list.id_widget = widgets.id
	AND list.visible = 'y'
	ORDER BY ordby ASC
EOSQL

my $cursor = $dbh->prepare($stmt);
my $rc = $cursor->execute;
if (!defined $rc) {suicide($stmt);}
$dashboard_row = 0;
while (($id_widget,$grid,$widget_name,$widget_script,$widget_html,$widget_function,$widget_title,$widget_color,$widget_name_alt) = $cursor->fetchrow_array()) {

	if($dashboard_row == 0) {
		$dashboard_content .= '<div class="row">';
	}
	
	if($widget_color eq "") {
		$widget_color = "blanc";
	}
	
	if($widget_name_alt ne '') {
		$widget_name = $widget_name_alt;
	}
	
	my $widget_title_content = '';
	if($widget_title eq 'y') {
		$widget_title_content = '<header class="panel-heading">'.$widget_name.'</header>';
	}
	
	if($widget_function ne "") {
		$dashboard_content .= '<div class='.$grid.' id="widget_'.$id_widget.'"><section class="panel widget_panel '.$widget_color.'">'.$widget_title_content.'<div class="panel-body panel-dashboard"></div></section></div>';
		$widget_html = "";
		$widget_script = "";
	}
	elsif($widget_html ne "") {
		$dashboard_content .= '<div class='.$grid.' id="widget_'.$id_widget.'"><section class="panel widget_panel '.$widget_color.'">'.$widget_title_content.'<div class="panel-body panel-dashboard">'.$widget_html.'</div></section></div>';
		$widget_script = "";
	}
	elsif($widget_script ne "") {
		$dashboard_content .= '<div class='.$grid.' id="widget_'.$id_widget.'"><section class="panel widget_panel '.$widget_color.'">'.$widget_title_content.'<div class="panel-body panel-dashboard" widget_script="'.$widget_script.'&'.$params.'"><div class="widget_loading"><svg class="spinner" width="40px" height="40px" viewBox="0 0 66 66" xmlns="http://www.w3.org/2000/svg"><circle class="path" fill="none" stroke-width="6" stroke-linecap="round" cx="33" cy="33" r="30"></circle> </svg></div></div></section></div>';
	}
	else {
		$dashboard_content .= '<div class='.$grid.' id="widget_'.$id_widget.'"><section class="panel widget_panel '.$widget_color.'">'.$widget_title_content.'<div class="panel-body panel-dashboard">ERROR</div></section></div>'
	}
	
		
	my $grid_number = $grid;
	$grid_number =~ s/col-md-//g;
	
	$dashboard_row = $dashboard_row+$grid_number;
		
	if($dashboard_row == 12) {
		$dashboard_content .= '</div>';
		$dashboard_row = 0;
	}
}
# $cursor->finish();
# $dbh->disconnect();

$dashboard_content .= '</div>';
 
print migc_app_layout($dashboard_content,"","","","");
}