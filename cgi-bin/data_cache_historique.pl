#!/usr/bin/perl -I../lib 
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use data; # home-made package for tools
use JSON::XS;


my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}


my $sw = "rendu_historique";

my $self = "cgi-bin/data_cache_historique.pl?";
my @fcts = qw(
rendu_historique
		);

if(is_in(@fcts,$sw)) 
{ 
    &$sw();
}

sub rendu_historique
{
	see();
	use LWP::Simple;
	my $id_data_sheet = get_quoted('id_data_sheet');
	my $cook_data_history = $cgi->cookie('data_history');
	my %hash_dc = ();
	if($cook_data_history ne "")
	{
	   $cook_data_history =~ s/null//g;
	   $cook_data_history =~ s/^,//g;
	   $cook_data_history =~ s/,$//g;
	}

	my @old_history = split(/,/,$cook_data_history);
	my $i = 1;
	
	@reversedNames = @old_history; 
	
	my %data_family = sql_line({table=>'data_families'});
	my %data_setup = sql_line({table=>'data_setup'});
	my %tarif = sql_line({table=>'eshop_tarifs'});
	my $template = get_template($dbh,$data_family{id_template_object},$config{current_language});

	foreach my $old_hist (@reversedNames)
	{
		if($traite{$old_hist} == 1 || $id_data_sheet == $old_hist)
		{
			next;
		}
		my %data_sheet = sql_line({table=>'data_sheets',where=>"id='$old_hist'"});
		$traite{$old_hist} = 1;
		# $get_url = $config{rewrite_protocol}.'://'.$ENV{SERVER_NAME}.$ENV{REDIRECT_URL}.'/cache/site/data/objects/'.$old_hist.'.txt';
		my $object = data_write_tiles_optimized($dbh,\%data_sheet,\%data_family,$data_family{id_template_object},$template,$lg,0,'object',$extlink,'',undef,undef,'n',\%data_setup,\%tarif,'',$infos_recherche);

		# $list .= get($get_url);
		$list .= $object
	}  
	print $list;
	exit;
}