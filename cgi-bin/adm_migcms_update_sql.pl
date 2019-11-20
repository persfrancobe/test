#!/usr/bin/perl -I../lib

# Includes
use CGI::Carp qw(fatalsToBrowser set_message);
print $cgi->header(-expires=>'-1d',-charset => 'utf-8');
use DBI;
use def;

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

my $sw=$cgi->param('sw') || 'mig_update_mysql';



&$sw();

sub mig_update_mysql
{
    my $stmts = get_sql_from_file("../dbs_upd/eshop_txts.sql");
#     $stmts =~ s/\'/\\\'/g;
#     $stmts =~ s/\"/\\\"/g;
    my $cursor = $dbh->prepare($stmts);
    my $rc = $cursor->execute;
    if (!defined $rc) {die("$DBI::errstr  $stmts");}
    print 'OK';
    exit;
}

sub get_sql_from_file 
{
        my $SQL = '';
        open (sqlFile, shift) or die ("Can't open SQL File for reading");
        my @lines = <sqlFile>;
        $SQL = join( " " , @lines); 
        close(sqlFile);
        return $SQL;
};

sub get_describe
{
    my $dbh_dbf     = $_[0];
    my $table_name=$_[1];
    my @table =();
  	my $stmt = "DESCRIBE $table_name";
  	if($debug)
  	{
   	    print "<br /><br />".$stmt."<br /><br />";
   	}
  	my $cursor = $dbh_dbf->prepare($stmt);
  	my $rc = $cursor->execute;
  	if (!defined $rc) 
  	{
  		  print "[$stmt]";
  	    exit;   
  	}
  	 while ($ref_rec = $cursor->fetchrow_hashref()) 
  	 {
  	    my %rec = %{$ref_rec};
  		  push @table,\%{$ref_rec};
  	 }
  	 $cursor->finish;
  	 return @table;
}