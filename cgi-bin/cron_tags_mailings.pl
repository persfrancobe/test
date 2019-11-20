#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
#use dm;
use mailing;
use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset);

#see();
tags_mailings();

################################################################################
# SEND_MAILINGS
################################################################################

sub tags_mailings
{

	@members = sql_lines({debug=>0,table=>"migcms_members"});
	
	foreach $member (@members)
	{	
		my %member = %{$member};
		
		print "Boucle sur les membres. ID = $member{id}\n";
	
		my $id = $member{id};
		my $email = $member{email};
		my $tags = $member{tags};
		
		my $nbr_open = 0;
		my %count_open = sql_line({debug=>0,table=>"migcms_members_events",select=>'COUNT(id) as nbr',where=>"id_member='$id' AND type_evt = 'open_mailing'"});
		$nbr_open = $count_open{nbr};
		
		my $new_tags = $tags;
		
		my $tag_open = ','.$config{mailing_tag_open}.',';
		my $tag_click = ','.$config{mailing_tag_click}.',';
		
		if($tags !~/$tag_open/ && $nbr_open > 0) {
			my $new_id_tag = $tag_open;
			$new_tags = $new_tags.$new_id_tag;
			$stmt = "UPDATE migcms_members SET tags='".$new_tags."' WHERE id ='".$id."'";
			execstmt($dbh,$stmt);	
			print "Ajout tag 'Ouvert' au membre ($email). ID = $id\n";
		}
		
		my $nbr_click = 0;
		my %count_click = sql_line({debug=>0,table=>"migcms_members_events",select=>'COUNT(id) as nbr',where=>"id_member='$id' AND type_evt = 'click_mailing'"});
		$nbr_click = $count_click{nbr};
		
		if($tags !~/$tag_click/ && $nbr_click > 0) {
			my $new_id_tag = $tag_click;
			$new_tags = $new_tags.$new_id_tag;
			$stmt = "UPDATE migcms_members SET tags='".$new_tags."' WHERE id ='".$id."'";
			execstmt($dbh,$stmt);	
			print "Ajout tag 'Click' au membre ($email). ID = $id\n";
		}
		
	}
} 
