#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use Math::Round;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
see(); 
my $id_campagne = get_quoted('id_campaign');
my $id_sending = get_quoted('id_sending');
my $id_mailing = get_quoted('id_migcms_page');
my $period_start = get_quoted('period_start');
my $period_end = get_quoted('period_end');
my $data_view = get_quoted('data_view');

$where = "status='ended'";
$sendings = "";
$selectperiod = "MONTH(start_time) as period,";
$groupby = " GROUP BY MONTH(start_time)";

if($id_campagne ne '') {
	
	my @mailings_ids = sql_lines({debug=>0,dbh=>$dbh, table=>"migcms_pages", select=>"id", where=>"mailing_id_campaign='$id_campagne'"});
	my $pagesids = "";
	foreach $mailing_id (@mailings_ids)
	{	
		my %mailing_id = %{$mailing_id};
		$pagesids .= $mailing_id{id}.",";
	}
	
	if($pagesids ne "") {
	
		$where .= ' AND id_migcms_page IN ("'.substr($pagesids, 0, -1).'")';
	
		my @sendings_ids = sql_lines({debug=>0,dbh=>$dbh, table=>"mailing_sendings", select=>"id", where=>'id_migcms_page IN ("'.substr($pagesids, 0, -1).'")'});
		my $ids = "";
		foreach $id (@sendings_ids)
		{	
			my %id = %{$id};
			$ids .= $id{id}.",";
		}
		
		if($ids ne "") {
		
			$sendings = " AND detail_evt IN (".substr($ids, 0, -1).")";	
		
		}
	
	}

}

if($id_sending ne '') {
	$where .= " AND id='$id_sending'";
	$sendings = " AND detail_evt IN (".$id_sending.")";
}

if($id_mailing ne '') {
	$where .= " AND id_migcms_page='$id_mailing'";
	
	my @sendings_ids = sql_lines({debug=>0,dbh=>$dbh, table=>"mailing_sendings", select=>"id", where=>"id_migcms_page='$id_mailing'"});
	my $ids = "";
	foreach $id (@sendings_ids)
	{	
		my %id = %{$id};
		$ids .= $id{id}.",";
	}
	
	if($ids ne "") {
		
		$sendings = " AND detail_evt IN (".substr($ids, 0, -1).")";
	
	}
	
}

if($period_start ne '') {
	$where .= " AND start_time>='$period_start'";
}

if($period_end ne '') {
	$where .= " AND start_time<='$period_end'";
}

if($data_view ne '') {
	if($data_view eq 'day') {
		$groupby = " GROUP BY DAY(start_time)";
	}
	elsif($data_view eq 'week') {
		$groupby = " GROUP BY WEEK(start_time)";
	}
	elsif($data_view eq 'year') {
		$groupby = " GROUP BY YEAR(start_time)";
	}
}

my $sw = $cgi->param('sw');
dm_init();
&$sw();

exit;

sub mailing_stat_nb_members
{
	my %nbr_members = sql_line({debug=>0,table=>"migcms_members",select=>'count(*) as nb',where=>"email_optin='y' OR email_optin_2='y'",limit=>'0,1'});
	
	my $widget_content="";
	
	$widget_content .= <<"EOH";
		<h2 class="text-center" style="margin-top:0px;"><strong>$nbr_members{nb}</strong></h2>
		<h4 class="text-center" style="margin-bottom:0px;">membres inscrits</h4>
EOH

print $widget_content;

}

sub mailing_stat_nb_total_open
{
	my %nbr_emails_open = sql_line({debug=>0,table=>"mailing_sendings",select=>'SUM(nb_open) as nb_open, SUM(nb_open_unique) as nb_open_unique, SUM(nb_sent) as nb',where=>$where,limit=>'0,1'});
	
	my $pourcentage = "0";
	
	if($nbr_emails_open{nb} != 0) {
		$pourcentage = ($nbr_emails_open{nb_open_unique} / $nbr_emails_open{nb}) * 100;
		$pourcentage = round($pourcentage*100)/100;
	}
		
	my $widget_content="";
	
	my $nbr_emails_open = "0";
	if($nbr_emails_open{nb_open} ne "") {
		$nbr_emails_open = $nbr_emails_open{nb_open};
	}
		
	$widget_content .= <<"EOH";
		<h2 class="text-center" style="color:#2fe8a3;margin-top:0px;"><strong>$nbr_emails_open</strong> <small style="color:#2fe8a3;">($pourcentage %)</small></h2>
		<h4 class="text-center" style="margin-bottom:0px;">Ouvertures</h4>
EOH

print $widget_content;

}

sub mailing_stat_nb_members_open
{
	my %nbr_members = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(DISTINCT id_member) as nb',where=>"type_evt='open_mailing' $sendings",limit=>'0,1'});
	
	my $widget_content="";
		
	$widget_content .= <<"EOH";
		<h2 class="text-center" style="color:#2fe8a3;margin-top:0px;"><strong>$nbr_members{nb}</strong></h2>
		<h4 class="text-center" style="margin-bottom:0px;">Ouvreurs</h4>
EOH

print $widget_content;

}

sub mailing_stat_nb_total_clic
{
	my %nbr_emails_click = sql_line({debug=>0,table=>"mailing_sendings",select=>'SUM(nb_click) as nb_click, SUM(nb_click_unique) as nb_click_unique, SUM(nb_sent) as nb',where=>$where,limit=>'0,1'});
		
	my $pourcentage = "0";
	
	if($nbr_emails_click{nb} != 0) {
		$pourcentage = ($nbr_emails_click{nb_click_unique} / $nbr_emails_click{nb}) * 100;
		$pourcentage = round($pourcentage*100)/100;
	}
	
	my $widget_content="";
	
	my $nbr_emails_click = "0";
	if($nbr_emails_click{nb_click} ne "") {
		$nbr_emails_click = $nbr_emails_click{nb_click};
	}
		
	$widget_content .= <<"EOH";
		<h2 class="text-center" style="color:#4fcf4f;margin-top:0px;"><strong>$nbr_emails_click</strong> <small style="color:#4fcf4f;">($pourcentage %)</small></h2>
		<h4 class="text-center" style="margin-bottom:0px;">Clics</h2>
EOH

print $widget_content;

}

sub mailing_stat_nb_members_clic
{
	my %nbr_members = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(DISTINCT id_member) as nb',where=>"type_evt='click_mailing' $sendings",limit=>'0,1'});
	
	my $widget_content="";
		
	$widget_content .= <<"EOH";
		<h2 class="text-center" style="color:#4fcf4f;margin-top:0px;"><strong>$nbr_members{nb}</strong></h2>
		<h4 class="text-center" style="margin-bottom:0px;">Cliqueurs</h2>
EOH

print $widget_content;

}

sub mailing_stat_trafic
{
	$where .= $groupby;
	my $widget_content="";
	my $month_content="";
		
	$widget_content .= <<"EOH";
		<div id="mailing-trafic" style="width:100%;height:300px;"></div>
		
		<script class="script hide">
		
var d1 = [
EOH


	$stmt = <<"EOH";
	SELECT 
	CASE EXTRACT(MONTH FROM start_time)
	WHEN 1 Then 'Jan'
	WHEN 2 then 'Fév'
	WHEN 3 then 'Mar'
	WHEN 4 Then 'Avr'
	WHEN 5 Then 'Mai'
	WHEN 6 Then 'Jui'
	WHEN 7 then 'Jui'
	WHEN 8 then 'Aoû'
	WHEN 9 then 'Sep'
	WHEN 10 then 'Oct'
	WHEN 11 then 'Nov'
	WHEN 12 then 'Déc'
	END AS month_fr,
	DATE_FORMAT(start_time,'%m') as month, 
	DATE_FORMAT(start_time,'%Y') as year, 
	SUM(nb_sent) as nb 
	FROM mailing_sendings 
	WHERE status='ended' AND start_time > DATE_SUB(now(), INTERVAL 12 MONTH)
	GROUP BY DATE_FORMAT(start_time,'%m-%Y') 
	ORDER BY year,month ASC
EOH

	my $cursor = $dbh->prepare($stmt);
	my $rc = $cursor->execute;
	if (!defined $rc) {suicide($stmt);}
	my $i=0;
	while (($month_fr,$month,$year,$nb) = $cursor->fetchrow_array()) {
		$widget_content .= <<"EOH";
		[$i, $nb],
EOH
		$month_content .= <<"EOH";
		[$i, "$month_fr $year"],
EOH
		$i++;
	}
	$cursor->finish();
	$dbh->disconnect();


	$widget_content .= <<"EOH";
];
var d2 = [
EOH

	$stmt = <<"EOH";
	SELECT 
	CASE EXTRACT(MONTH FROM start_time)
	WHEN 1 Then 'Jan'
	WHEN 2 then 'Fév'
	WHEN 3 then 'Mar'
	WHEN 4 Then 'Avr'
	WHEN 5 Then 'Mai'
	WHEN 6 Then 'Jui'
	WHEN 7 then 'Jui'
	WHEN 8 then 'Aoû'
	WHEN 9 then 'Sep'
	WHEN 10 then 'Oct'
	WHEN 11 then 'Nov'
	WHEN 12 then 'Déc'
	END AS month_fr,
	DATE_FORMAT(start_time,'%m') as month, 
	DATE_FORMAT(start_time,'%Y') as year, 
	SUM(nb_open) as nb 
	FROM mailing_sendings 
	WHERE status='ended' AND start_time > DATE_SUB(now(), INTERVAL 12 MONTH)
	GROUP BY DATE_FORMAT(start_time,'%m-%Y') 
	ORDER BY year,month ASC
EOH

	my $cursor = $dbh->prepare($stmt);
	my $rc = $cursor->execute;
	if (!defined $rc) {suicide($stmt);}
	my $i=0;
	while (($month_fr,$month,$year,$nb) = $cursor->fetchrow_array()) {
		$widget_content .= <<"EOH";
		[$i, $nb],
EOH
		$i++;
	}
	$cursor->finish();
	$dbh->disconnect();
	

	$widget_content .= <<"EOH";
];
var d3 = [
EOH


	$stmt = <<"EOH";
	SELECT 
	CASE EXTRACT(MONTH FROM start_time)
	WHEN 1 Then 'Jan'
	WHEN 2 then 'Fév'
	WHEN 3 then 'Mar'
	WHEN 4 Then 'Avr'
	WHEN 5 Then 'Mai'
	WHEN 6 Then 'Jui'
	WHEN 7 then 'Jui'
	WHEN 8 then 'Aoû'
	WHEN 9 then 'Sep'
	WHEN 10 then 'Oct'
	WHEN 11 then 'Nov'
	WHEN 12 then 'Déc'
	END AS month_fr,
	DATE_FORMAT(start_time,'%m') as month, 
	DATE_FORMAT(start_time,'%Y') as year, 
	SUM(nb_click) as nb 
	FROM mailing_sendings 
	WHERE status='ended' AND start_time > DATE_SUB(now(), INTERVAL 12 MONTH)
	GROUP BY DATE_FORMAT(start_time,'%m-%Y') 
	ORDER BY year,month ASC
EOH


	my $cursor = $dbh->prepare($stmt);
	my $rc = $cursor->execute;
	if (!defined $rc) {suicide($stmt);}
	my $i=0;
	while (($month_fr,$month,$year,$nb) = $cursor->fetchrow_array()) {
		$widget_content .= <<"EOH";
		[$i, $nb],
EOH
		$i++;
	}
	$cursor->finish();
	$dbh->disconnect();

	$widget_content .= <<"EOH";
];

var data = ([
{
	label: "&nbsp; Total des envois &nbsp;",
	data: d1,
	lines: {
		show: true,
		fill: true,
		fillColor: {
			colors: ["rgba(255,255,255,.0)", "rgba(5,141,199,.5)"]
		}
	}
},
{
	label: "&nbsp; Total des ouvertures &nbsp;",
	data: d2,
	lines: {
		show: true,
		fill: true,
	}
},
{
	label: "&nbsp; Total des cliques &nbsp;",
	data: d3,
	lines: {
		show: true,
		fill: true,
	}
}
]);

jQuery.plot(jQuery("#mailing-trafic"), data,{
	grid: {
		backgroundColor:
		{
			colors: ["#ffffff", "#f4f4f6"]
		},
		hoverable: true,
		clickable: true,
		tickColor: "#eeeeee",
		borderWidth: 1,
		borderColor: "#eeeeee"
	},
	// Tooltip
	tooltip: true,
	tooltipOpts: {
		content: "%s: %y",
		shifts: {
			x: 0,
			y: 25
		},
		defaultTheme: false
	},

	series: {
		lines: {
			show: true,
			fill: false
		},
		points: {
			show: true,
			lineWidth: 1,
			fill: true,
			fillColor: "#ffffff",
			symbol: "circle",
			radius: 1
		},
		shadowSize: 0
	},
	points: {
		show: true,
		radius: 3,
		symbol: "circle"
	},
	colors: ["#058dc7", "#2fe8a3", "#4fcf4f"],
	xaxis: { 
		ticks: [$month_content]
	},
});

		</script>
EOH

	print $widget_content;

}

sub mailing_stat_trafic_byday
{
	$where .= $groupby;
	my $widget_content="";
	my $date_event="";
	my $sent_event="";
	my $open_event="";
	my $click_event="";
	my $i = 0;
	
	my @moments = sql_lines({debug=>0,dbh=>$dbh, table=>"migcms_members_events", select=>"DATE_FORMAT(moment,'%Y-%m-%d') as moment, DATE_FORMAT(moment,'%d-%m') as moment_fr", where=>"(type_evt='sent_mailing' OR type_evt='open_mailing' OR type_evt='click_mailing') $sendings GROUP BY DATE_FORMAT(moment,'%Y-%m-%d')", ordby=>'ORDER BY UNIX_TIMESTAMP(moment) ASC'});
	

	foreach $moment (@moments)
	{	
		my %moment = %{$moment};
		
		$date_event .= <<"EOH";
		[$i, "$moment{moment_fr}"],
EOH
		
		#my %nbr_sent = sql_line({debug=>0,table=>"migcms_members_events",select=>'COUNT(id) as nb',where=>"type_evt='sent_mailing' AND date_event='$moment{moment}' $sendings",limit=>'0,1'});	

		#$sent_event .= <<"EOH";
		#[$i, "$nbr_sent{nb}"],
#EOH
		
		my %nbr_open = sql_line({debug=>0,table=>"migcms_members_events",select=>'COUNT(id) as nb',where=>"type_evt='open_mailing' AND date_event='$moment{moment}' $sendings",limit=>'0,1'});
		
		$open_event .= <<"EOH";
		[$i, "$nbr_open{nb}"],
EOH
		
		my %nbr_click = sql_line({debug=>0,table=>"migcms_members_events",select=>'COUNT(id) as nb',where=>"type_evt='click_mailing' AND date_event='$moment{moment}' $sendings",limit=>'0,1'});
		
		$click_event .= <<"EOH";
		[$i, "$nbr_click{nb}"],
EOH
	
		$i++;
	}
	
	$widget_content .= <<"EOH";
		<div id="mailing-trafic-byday" style="width:100%;height:300px;"></div>
		
		<script class="script hide">
		
var d1 = [
$open_event
];
var d2 = [
$click_event
];

var data = ([
{
	label: "&nbsp; Total des ouvertures &nbsp;",
	data: d1,
	lines: {
		show: true,
		fill: true,
	}
},
{
	label: "&nbsp; Total des cliques &nbsp;",
	data: d2,
	lines: {
		show: true,
		fill: true,
	}
}
]);

jQuery.plot(jQuery("#mailing-trafic-byday"), data,{
	grid: {
		backgroundColor:
		{
			colors: ["#ffffff", "#f4f4f6"]
		},
		hoverable: true,
		clickable: true,
		tickColor: "#eeeeee",
		borderWidth: 1,
		borderColor: "#eeeeee"
	},
	// Tooltip
	tooltip: true,
	tooltipOpts: {
		content: "%s: %y",
		shifts: {
			x: 0,
			y: 25
		},
		defaultTheme: false
	},

	series: {
		lines: {
			show: true,
			fill: false
		},
		points: {
			show: true,
			lineWidth: 1,
			fill: true,
			fillColor: "#ffffff",
			symbol: "circle",
			radius: 1
		},
		shadowSize: 0
	},
	points: {
		show: true,
		radius: 3,
		symbol: "circle"
	},
	colors: ["#2fe8a3", "#4fcf4f"],
	xaxis: { 
		ticks: [$date_event]
	},
});

		</script>

EOH

	print $widget_content;

}

sub mailing_stat_trafic_time
{
	$where .= $groupby;
	my $widget_content="";
	my $month_content="";
	
	$widget_content .= <<"EOH";
		<div id="mailing-trafic-time" style="width:100%;height:300px;"></div>
		
		<script class="script hide">
		
var d1 = [
EOH

	$stmt = <<"EOH";
SELECT 
DATE_FORMAT(time_event,'%H') as hour, 
COUNT(id) as nb 
FROM migcms_members_events 
WHERE type_evt='open_mailing' $sendings
GROUP BY DATE_FORMAT(time_event,'%H') 
ORDER BY hour ASC
EOH

my $cursor = $dbh->prepare($stmt);
my $rc = $cursor->execute;
if (!defined $rc) {suicide($stmt);}
my $i=0;
my %nbr_emails_open = sql_line({debug=>0,table=>"migcms_members_events",select=>'COUNT(id) as nb_open',where=>"type_evt='open_mailing' $sendings",limit=>'0,1'});
while (($hour,$nb) = $cursor->fetchrow_array()) {

	my $pourcentage = ($nb / $nbr_emails_open{nb_open}) * 100;
	$pourcentage = round($pourcentage*100)/100;

	$widget_content .= <<"EOH";
	[$i, $pourcentage],
EOH
	$month_content .= <<"EOH";
	[$i, "$hour h"],
EOH
	$i++;
}
$cursor->finish();
$dbh->disconnect();

$widget_content .= <<"EOH";
];

var data = ([
{
	label: "&nbsp; % des ouvertures par heure &nbsp;",
	data: d1
}
]);

	var stack = 0,
		bars = true,
		lines = false,
		steps = false;

jQuery.plot(jQuery("#mailing-trafic-time"), data,{
	grid: {
		backgroundColor:
		{
			colors: ["#ffffff", "#f4f4f6"]
		},
		hoverable: true,
		clickable: true,
		tickColor: "#eeeeee",
		borderWidth: 1,
		borderColor: "#eeeeee"
	},
	// Tooltip
	tooltip: true,
	tooltipOpts: {
		content: "%y %",
		shifts: {
			x: 0,
			y: 25
		},
		defaultTheme: false
	},

	series: {
		stack: stack,
		lines: {
			show: lines,
			fill: true,
			steps: steps
		},
		bars: {
			show: bars,
			barWidth: 0.6
		}
	},
	colors: ["#058dc7", "#2fe8a3", "#4fcf4f"],
	xaxis: { ticks: [$month_content] },
});

		</script>
EOH

print $widget_content;

}

sub mailing_stat_trafic_dayweek
{
	$where .= $groupby;
	my $widget_content="";
	my $month_content="";
	
	foreach $url (@urls)
	{	
		my %url = %{$url};
	}
	
	$widget_content .= <<"EOH";
		<div id="mailing-trafic-dayweek" style="width:100%;height:300px;"></div>
		
		<script class="script hide">
		
var d1 = [
EOH

	$stmt = <<"EOH";
SELECT 
DATE_FORMAT(date_event,'%w') as dayweek, 
COUNT(id) as nb 
FROM migcms_members_events 
WHERE type_evt='open_mailing' $sendings
GROUP BY DATE_FORMAT(date_event,'%w') 
ORDER BY dayweek ASC
EOH

my $cursor = $dbh->prepare($stmt);
my $rc = $cursor->execute;
if (!defined $rc) {suicide($stmt);}
my $i=0;
my %nbr_emails_open = sql_line({debug=>0,table=>"migcms_members_events",select=>'COUNT(id) as nb_open',where=>"type_evt='open_mailing' $sendings",limit=>'0,1'});
while (($dayweek,$nb) = $cursor->fetchrow_array()) {

	my $pourcentage = ($nb / $nbr_emails_open{nb_open}) * 100;
	$pourcentage = round($pourcentage*100)/100;

	$widget_content .= <<"EOH";
	[$dayweek, $pourcentage],
EOH
	$i++;
}
$cursor->finish();
$dbh->disconnect();

$widget_content .= <<"EOH";
];

var data = ([
{
	label: "&nbsp; % des ouvertures par jour &nbsp;",
	data: d1
}
]);

	var stack = 0,
		bars = true,
		lines = false,
		steps = false;

jQuery.plot(jQuery("#mailing-trafic-dayweek"), data,{
	grid: {
		backgroundColor:
		{
			colors: ["#ffffff", "#f4f4f6"]
		},
		hoverable: true,
		clickable: true,
		tickColor: "#eeeeee",
		borderWidth: 1,
		borderColor: "#eeeeee"
	},
	// Tooltip
	tooltip: true,
	tooltipOpts: {
		content: "%y %",
		shifts: {
			x: 0,
			y: 25
		},
		defaultTheme: false
	},

	series: {
		stack: stack,
		lines: {
			show: lines,
			fill: true,
			steps: steps
		},
		bars: {
			show: bars,
			barWidth: 0.6
		}
	},
	colors: ["#058dc7", "#2fe8a3", "#4fcf4f"],
	xaxis: { ticks: [[0, "Dimanche"],[1, "Lundi"],[2, "Mardi"],[3, "Mercredi"],[4, "Jeudi"],[5, "Vendredi"],[6, "Samedi"]] },
});

		</script>
EOH

print $widget_content;

}

sub mailing_stat_nb_newsletters
{
	my %nbr_sendings = sql_line({debug=>0,table=>"mailing_sendings",select=>'count(*) as nb',where=>$where,limit=>'0,1'});
	
	my $widget_content="";
	
	$widget_content .= <<"EOH";
		<h2 class="text-center" style="margin-top:0px;"><strong>$nbr_sendings{nb}</strong></h2>
		<h4 class="text-center" style="margin-bottom:0px;">newsletters envoyées</h4>
EOH

print $widget_content;

}

sub mailing_stat_nb_emails
{
	my %nbr_emails = sql_line({debug=>0,table=>"mailing_sendings",select=>'SUM(nb_sent) as nb',where=>$where,limit=>'0,1'});
	

# $dbh_send = DBI->connect($config{db_qm},$config{login_qm},$config{passwd_qm}) or suicide("cannot connect to sending DB");
# $stmt = " SET NAMES utf8mb4";	
# $cursor = $dbh->prepare($stmt);		
# $rc = $cursor->execute;	

	
	my $widget_content="";
	
	my $nbr_email = "0";
	if($nbr_emails{nb} ne "") {
		$nbr_email = $nbr_emails{nb};
	}
	
	$widget_content .= <<"EOH";
		<h2 class="text-center" style="margin-top:0px;"><strong>$nbr_email</strong></h2>
		<h4 class="text-center" style="margin-bottom:0px;">emails envoyés</h4>
EOH

print $widget_content;

}

sub mailing_stat_nb_uopen
{
	#my %nbr_emails_open = sql_line({debug=>0,table=>"mailing_sendings",select=>'SUM(nb_sent) as nb, SUM(nb_open_unique) as nb_open_unique',where=>$where,limit=>'0,1'});
	
	my $modify_sendings = $sendings;
	$modify_sendings =~ s/ AND //g;
	
	my %nbr_members = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(DISTINCT id_member) as nb',where=>"$modify_sendings",limit=>'0,1'});
	my %nbr_members_open = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(DISTINCT id_member) as nb',where=>"type_evt='open_mailing' $sendings",limit=>'0,1'});
	
	my $widget_content="";
	
	my $pourcentage = "0";
	
	if($nbr_members{nb} != 0) {
		$pourcentage = ($nbr_members_open{nb} / $nbr_members{nb}) * 100;
		$pourcentage = round($pourcentage*100)/100;
	}
		
	$widget_content .= <<"EOH";
		<h2 class="text-center" style="color:#2fe8a3;margin-top:0px;"><strong>$pourcentage %</strong></h2>
		<h4 class="text-center" style="margin-bottom:0px;">des membres ont ouvert</h4>
EOH

print $widget_content;

}

sub mailing_stat_nb_uclick
{
	#my %nbr_emails_click = sql_line({debug=>0,table=>"mailing_sendings",select=>'SUM(nb_open_unique) as nb, SUM(nb_click_unique) as nb_click_unique',where=>$where,limit=>'0,1'});
	
	my $modify_sendings = $sendings;
	$modify_sendings =~ s/ AND //g;
	
	my %nbr_members = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(DISTINCT id_member) as nb',where=>"$modify_sendings",limit=>'0,1'});
	my %nbr_members_click = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(DISTINCT id_member) as nb',where=>"type_evt='click_mailing' $sendings",limit=>'0,1'});
	
	my $widget_content="";
	
	my $pourcentage = "0";
	
	if($nbr_members{nb} != 0) {
		$pourcentage = ($nbr_members_click{nb} / $nbr_members{nb}) * 100;
		$pourcentage = round($pourcentage*100)/100;
	}
	
	$widget_content .= <<"EOH";
		<h2 class="text-center" style="color:#4fcf4f;margin-top:0px;"><strong>$pourcentage %</strong></h2>
		<h4 class="text-center" style="margin-bottom:0px;">des membres ont cliqués un lien</h2>
EOH

print $widget_content;

}

sub mailing_stat_nb_unsub
{
	#my %nbr_desinscriptions = sql_line({debug=>0,table=>"mailing_sendings",select=>'SUM(nb_sent) as nb, SUM(nb_desinscriptions) as nb_desinscriptions',where=>$where,limit=>'0,1'});
	
	my $modify_sendings = $sendings;
	$modify_sendings =~ s/ AND //g;
	
	my %nbr_members = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(DISTINCT id_member) as nb',where=>"$modify_sendings",limit=>'0,1'});
	my %nbr_members_desinscriptions = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(DISTINCT id_member) as nb',where=>"type_evt='unsubscribe_mailing' $sendings",limit=>'0,1'});
	
	my $widget_content="";
	
	my $pourcentage = "0";
	
	if($nbr_members{nb} != 0) {
		$pourcentage = ($nbr_members_desinscriptions{nb} / $nbr_members{nb}) * 100;
		$pourcentage = round($pourcentage*100)/100;
	}
	
	$widget_content .= <<"EOH";
		<h2 class="text-center" style="color:#ff9b0d;margin-top:0px;"><strong>$pourcentage %</strong></h2>
		<h4 class="text-center" style="margin-bottom:0px;">des membres se sont désinscrits</h4>
EOH

print $widget_content;

}

sub mailing_stat_nb_error
{
	#my %nbr_erreurs = sql_line({debug=>1,table=>"mailing_sendings",select=>'SUM(nb_sent) as nb, SUM(nb_erreurs) as nb_erreurs',where=>$where,limit=>'0,1'});
	
	my $modify_sendings = $sendings;
	$modify_sendings =~ s/ AND //g;
	
	my %nbr_members = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(DISTINCT id_member) as nb',where=>"$modify_sendings",limit=>'0,1'});
	my %nbr_members_error = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(DISTINCT id_member) as nb',where=>"type_evt='blacklist_mailing' $sendings",limit=>'0,1'});
	
	my $widget_content="";
			
	my $pourcentage = "0";
	
	if($nbr_members{nb} != 0) {
		$pourcentage = ($nbr_members_error{nb} / $nbr_members{nb}) * 100;
		$pourcentage = round($pourcentage*100)/100;
	}
	
	$widget_content .= <<"EOH";
		<h2 class="text-center" style="color:#d9524e;margin-top:0px;"><strong>$pourcentage %</strong></h2>
		<h4 class="text-center" style="margin-bottom:0px;">des membres sont en erreur<br ><small>(Hard-bounces)</small></h4>
EOH

print $widget_content;

}

sub mailing_stat_desktop_vs_mobile
{
	my %nbr_device = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(device) as nb',where=>"device!='' $sendings",limit=>'0,1'});
	my %nbr_desktop = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(device) as nb',where=>"device='desktop' $sendings",limit=>'0,1'});
	my %nbr_mobile = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(device) as nb',where=>"device='mobile' $sendings",limit=>'0,1'});
	
	my $widget_content="";
	
	my $pourcentage_desktop = "0";
	my $pourcentage_mobile = "0";
	
	if($nbr_device{nb} != 0) {
		$pourcentage_desktop = ($nbr_desktop{nb} / $nbr_device{nb}) * 100;
		$pourcentage_desktop = round($pourcentage_desktop*100)/100;
	
		$pourcentage_mobile = ($nbr_mobile{nb} / $nbr_device{nb}) * 100;
		$pourcentage_mobile = round($pourcentage_mobile*100)/100;
	}
	
	$widget_content .= <<"EOH";
		<div id="pie-chart-donut" class="pie-chart" data-desktop="$pourcentage_desktop" data-mobile="$pourcentage_mobile"><div id="mailing-desktopvsmobile" style="width:100%;height:300px;"></div></div>

		<script class="script hide">
var data = [
	{  label: "&nbsp; Desktop ($pourcentage_desktop %) &nbsp;" ,  data: $pourcentage_desktop}, 
	{  label: "&nbsp; Mobile ($pourcentage_mobile %) &nbsp;",  data: $pourcentage_mobile}
];

jQuery.plot(jQuery("#mailing-desktopvsmobile"), data,{
	series: {
		pie: { 
			innerRadius: 0.4,
			show: true,
			label: {
				show:true,
				radius: 0.8,
				formatter: function (label, series) {
					return '<div style="font-size:12px;text-align:center;padding:5px;color:white;">' +
					label+
					'</div>';
				},
				background: {
					opacity: 0.6,
					color: '#000'
				}
			}
		}
	},
	colors: ["#4fcf4f", "#0389C6"]
});
		</script>		
EOH

print $widget_content;

}

sub mailing_stat_software_vs_webmail_vs_online 
{
	my %nbr_open = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(id) as nb',where=>"type_evt='open_mailing' $sendings",limit=>'0,1'});
	my %nbr_software = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(id) as nb',where=>"type_evt='open_mailing' AND referer='' $sendings",limit=>'0,1'});
	my %nbr_webmail = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(id) as nb',where=>"type_evt='open_mailing' AND referer!='' AND referer NOT LIKE '%mailer.fw.be%' $sendings",limit=>'0,1'});
	my %nbr_online = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(id) as nb',where=>"type_evt='open_mailing' AND referer!='' AND referer LIKE '%mailer.fw.be%' $sendings",limit=>'0,1'});
	
	my $widget_content="";
	
	my $pourcentage_software = "0";
	my $pourcentage_webmail = "0";
	my $pourcentage_online = "0";
	
	if($nbr_open{nb} != 0) {
		$pourcentage_software = ($nbr_software{nb} / $nbr_open{nb}) * 100;
		$pourcentage_software = round($pourcentage_software*100)/100;
	
		$pourcentage_webmail = ($nbr_webmail{nb} / $nbr_open{nb}) * 100;
		$pourcentage_webmail = round($pourcentage_webmail*100)/100;
	
		$pourcentage_online = ($nbr_online{nb} / $nbr_open{nb}) * 100;
		$pourcentage_online = round($pourcentage_online*100)/100;
	}
	
	$widget_content .= <<"EOH";
		<div id="pie-chart-donut" class="pie-chart"><div id="mailing-software-webmail-online" style="width:100%;height:300px;"></div></div>

		<script class="script hide">
var data = [
	{  label: "&nbsp; Logiciels de messagerie ($pourcentage_software %) &nbsp;" ,  data: $pourcentage_software}, 
	{  label: "&nbsp; Webmail ($pourcentage_webmail %) &nbsp;",  data: $pourcentage_webmail},
	{  label: "&nbsp; Copie Web ($pourcentage_online %) &nbsp;",  data: $pourcentage_online}
];

jQuery.plot(jQuery("#mailing-software-webmail-online"), data,{
	series: {
		pie: { 
			innerRadius: 0.4,
			show: true,
			label: {
				show:true,
				radius: 0.8,
				formatter: function (label, series) {
					return '<div style="font-size:12px;text-align:center;padding:5px;color:white;">' +
					label+
					'</div>';
				},
				background: {
					opacity: 0.6,
					color: '#000'
				}
			}
		}
	},
	colors: ["#4fcf4f", "#0389C6", "#2b3a4d"]
});
		</script>		
EOH

	print $widget_content;
}

sub mailing_stat_topopen
{

	$widget_content = <<"EOH";
		<table class="table table-hover">
			<tr>
				<th><strong>Newsletter</strong></th>
				<th style="white-space:nowrap;text-align:center;"><strong>Date de l'envoi</strong></th>
				<th style="white-space:nowrap;text-align:center;"><strong>Nombre d'ouvertures</strong></th>
			</tr>
EOH

	my @urls = sql_lines({debug=>0,dbh=>$dbh, table=>"migcms_members_events", select=>"detail_evt, COUNT(detail_evt) as nbr", where=>"type_evt='open_mailing' $sendings group by detail_evt", ordby=>'nbr desc', limit=>'20'});

	foreach $url (@urls)
	{	
		my %url = %{$url};
		my %mailing_sending = sql_line({debug=>0,table=>"mailing_sendings",select=>'mailing_object,start_time',where=>"id='$url{detail_evt}'",limit=>'0,1'});
		$widget_content .= <<"EOH";
			<tr>
				<td>$mailing_sending{mailing_object}</td>
				<td style="white-space:nowrap;">$mailing_sending{start_time}</td>
				<td style="text-align:right;">$url{nbr}</td>
			</tr>	
EOH
	}

	$widget_content .= <<"EOH";
		</table>
EOH

print $widget_content;

}

sub mailing_stat_topurls
{

	$widget_content = <<"EOH";
		<table class="table table-hover">
			<tr>
				<th><strong>URL</strong></th>
				<th style="white-space:nowrap;text-align:right;"><strong>Nombre de clics</strong></th>
			</tr>
EOH

	my $limit = "20";
	if($sendings != "") {
		$limit = "0";
	}
	my @urls = sql_lines({debug=>0,dbh=>$dbh, table=>"migcms_members_events", select=>"substring_index(substring_index(detail_evt,'?url=',-1),'|',-1) as url, COUNT(id) as nbr", where=>"type_evt='click_mailing' $sendings group by url", ordby=>'nbr desc', limit=>"$limit"});

	foreach $url (@urls)
	{	
		my %url = %{$url};
		$widget_content .= <<"EOH";
			<tr>
				<td><a href="$url{url}" target="_blank">$url{url}</a></td>
				<td style="text-align:right;">$url{nbr}</td>
			</tr>	
EOH
	}

	$widget_content .= <<"EOH";
		</table>
EOH

print $widget_content;

}


sub mailing_stat_credits {

	my $widget_content="";
		
	$widget_content .= <<"EOH";
		<h2 class="text-center" style="margin-top:0px;"><strong>$config{mailing_credits}</strong></h2>
		<h4 class="text-center" style="margin-bottom:0px;">crédits restant</h2>
EOH

print $widget_content;

}

sub mailing_delivrability_by_domain {

	$widget_content = <<"EOH";
		<table class="table table-hover">
			<tr>
				<th><strong>Nom de domaine</strong></th>
				<th style="white-space:nowrap;text-align:right;"><strong>Nombre d'ouvertures</strong></th>
				<th style="white-space:nowrap;text-align:right;"><strong>Pourcentage d'ouvertures</strong></th>
				<!--<th style="white-space:nowrap;text-align:right;"><strong>Taux d'ouvertures</strong></th>-->
			</tr>
EOH

	my $limit = "20";
	if($sendings != "") {
		$limit = "0";
	}
	
	my %nbr_members_open = sql_line({debug=>0,table=>"migcms_members_events",select=>'count(id_member) as nb',where=>"type_evt='open_mailing' $sendings",limit=>'0,1'});
	
	my @domains = sql_lines({debug=>0,dbh=>$dbh, table=>"migcms_members,migcms_members_events", select=>"(SUBSTRING_INDEX(SUBSTR(email, INSTR(email, '\@') + 1),'.',1)) AS domain, COUNT(*) as nbr", where=>"type_evt='open_mailing' AND migcms_members.id = migcms_members_events.id_member $sendings group by domain", ordby=>'nbr desc', limit=>"$limit"});
	
	foreach $domain (@domains)
	{	
		my %domain = %{$domain};
		
		my $pourcentage = "0";
		$pourcentage = ($domain{nbr} / $nbr_members_open{nb}) * 100;
		$pourcentage = round($pourcentage*100)/100;
		
		#my %nbr_members_perdomain = sql_line({debug=>0,table=>"migcms_members,migcms_members_events",select=>'COUNT(*) as nb',where=>"(SUBSTRING_INDEX(SUBSTR(email, INSTR(email, '\@') + 1),'.',1)) = '$domain{domain}' AND type_evt='sent_mailing' AND migcms_members.id = migcms_members_events.id_member $sendings",limit=>'0,1'});
		
		my $pourcentage2 = "0";
		#$pourcentage2 = ($domain{nbr} / $nbr_members_perdomain{nb}) * 100;
		#$pourcentage2 = round($pourcentage2*100)/100;
		
		#if($pourcentage2 > 100) {
		#	$pourcentage2 = "100";
		#}
		
		$widget_content .= <<"EOH";
			<tr>
				<td>$domain{domain}</a></td>
				<td style="text-align:right;">$domain{nbr}</td>
				<td style="text-align:right;">$pourcentage %</td>
				<!--<td style="text-align:right;">$pourcentage2 %</td>-->
			</tr>	
EOH
	}

	$widget_content .= <<"EOH";
		</table>
EOH

print $widget_content;

}