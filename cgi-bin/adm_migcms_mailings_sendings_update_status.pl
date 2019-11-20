#!/usr/bin/perl -I../lib
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use mailing; # home-made package for tools
use dm;

my $sw = get_quoted('sw') || "";
my $planned_date = get_quoted('planned') || "";
my $id_sending = get_quoted('id_sending') || "";
$config{current_language} = get_quoted('lg') || 1;

dm_init();

if($sw eq '')
{
	see();
	print 'err';        
	exit;
}

my @switches = qw(
stop
restart
update
);

if (is_in(@switches,$sw)) { &$sw(); }  

exit;  

sub stop
{
	$dbh_send = DBI->connect($config{db_qm},$config{login_qm},$config{passwd_qm}) or suicide("cannot connect to sending DB");
	execstmt($dbh_send,"SET NAMES utf8");
	
	$stmt = "UPDATE mailings SET status='aborted' WHERE id_nl='$id_sending' AND dbname='$config{db_name}'";
	execstmt($dbh_send,$stmt);
	see();
	print "stop";
	exit;
}

sub restart
{
	$dbh_send = DBI->connect($config{db_qm},$config{login_qm},$config{passwd_qm}) or suicide("cannot connect to sending DB");
	execstmt($dbh_send,"SET NAMES utf8");
	
	$stmt = "UPDATE mailings SET status='started' WHERE id_nl='$id_sending' AND dbname='$config{db_name}'";
	execstmt($dbh_send,$stmt);
	see();
	print "current";
	exit;
}

sub update
{
	my $datetime = $planned_date;
	my ($date,$hours) = split (/ /,$planned_date);
	$planned_date = to_sql_date($date,'date_only');
	$planned_time = to_sql_time($hours);

	$dbh_send = DBI->connect($config{db_qm},$config{login_qm},$config{passwd_qm}) or suicide("cannot connect to sending DB");
	execstmt($dbh_send,"SET NAMES utf8");
	
	$stmt = "UPDATE mailings SET status='planned',planned_time='$planned_date $planned_time' WHERE id_nl='$id_sending' AND dbname='$config{db_name}'";
	execstmt($dbh_send,$stmt);
	see();
	print "planned|$datetime";
	#print $stmt;
	exit;
}