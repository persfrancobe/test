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
dataerror_mailings();

################################################################################
# SEND_MAILINGS
################################################################################

sub dataerror_mailings
{
		
		
	@mailings_errors = sql_lines({debug=>0,table=>"migcms_members_events",where=>"type_evt='error_mailing'"});
	
	foreach $mailings_error (@mailings_errors)
	{	
		my %mailings_error = %{$mailings_error};
		
		print "Boucle sur les erreurs. ID = $mailings_error{id}\n";
	
		my $id = $mailings_error{id};
		my $id_member = $mailings_error{id_member};
		my $error_moment = $mailings_error{moment};
		my $error_reason = $mailings_error{erreur_evt};
		my $date = $mailings_error{date_event};
		my $time = $mailings_error{time_event};
		my ($id_sending,$server,$token) = split(/\|/,$mailings_error{detail_evt});

				
		my $addtoblacklist = 0;
		
		my $nom_evt = "Blacklist de l'adresse email";
		
		my %mailings = sql_line({debug=>0,table=>"mailing_sendings",select=>'id_migcms_page',where=>"id='$id_sending'"});
		my $idmailing = $mailings{id_migcms_page};
		
		my %emails = sql_line({debug=>0,table=>"migcms_members",select=>'email',where=>"id='$id_member'"});
		my $email = $emails{email};
		
		$error_reason = lc($error_reason);
		
		my %emails = sql_line({debug=>0,table=>"mailing_blacklist",select=>'id',where=>"email='$email'"});
		my $id_email = $emails{id};
		
		my $nbr_open_click = 0;
		my %count_open_click = sql_line({debug=>0,table=>"migcms_members_events",select=>'COUNT(id) as nbr',where=>"id_member='$id_member' AND (type_evt = 'open_mailing' OR type_evt = 'click_mailing')"});
		$nbr_open_click = $count_open_click{nbr};
		
		my $nbr_error = 0;
		my %count_error = sql_line({debug=>0,table=>"migcms_members_events",select=>'COUNT(id) as nbr',where=>"id_member='$id_member' AND type_evt = 'error_mailing'"});
		$nbr_error = $count_error{nbr};
		
		my $mailing_nbr_error_blacklist = $config{mailing_nbr_error_blacklist} | 5;
		
		if($nbr_open_click > 0 || $nbr_error >= $mailing_nbr_error_blacklist) {
		
			if($error_reason =~/smtp; 500/ && $error_reason !~/black list/ && $error_reason !~/blacklist/ && $error_reason !~/service unavailable/  && $error_reason !~/blocked/  && $error_reason !~/rule/  && $error_reason !~/address rejected/) {
				my %permanentbounce_error = 
				(
				   email=>lc($email),
				   moment=>$error_moment,
				   reason=>'bad email syntax (500)',
				   id_mailing=>$idmailing,
				   id_sending=>$id_sending,
				);

				if($id_email ne "") {
					$stmt = "UPDATE `mailing_blacklist` SET moment = '$error_moment', reason = 'bad email syntax (500)', id_mailing = '$idmailing', id_sending = '$id_sending' WHERE id = '$id_email'";
					execstmt($dbh,$stmt);
				}
				else {
					inserth_db($dbh,"mailing_blacklist",\%permanentbounce_error);
				}
				$addtoblacklist = 1;
				print "bad email syntax (500) de l'email($email). ID = $id_member\n";
			}
			elsif($error_reason =~/smtp; 501/ && $error_reason !~/black list/ && $error_reason !~/blacklist/ && $error_reason !~/service unavailable/  && $error_reason !~/blocked/  && $error_reason !~/rule/  && $error_reason !~/address rejected/) {
				my %permanentbounce_error = 
				(
				   email=>lc($email),
				   moment=>$error_moment,
				   reason=>'bad email syntax (501)',
				   id_mailing=>$idmailing,
				   id_sending=>$id_sending,
				);
				if($id_email ne "") {
					$stmt = "UPDATE `mailing_blacklist` SET moment = '$error_moment', reason = 'bad email syntax (500)', id_mailing = '$idmailing', id_sending = '$id_sending' WHERE id = '$id_email'";
					execstmt($dbh,$stmt);
				}
				else {
					inserth_db($dbh,"mailing_blacklist",\%permanentbounce_error);
				}
				$addtoblacklist = 1;
				print "bad email syntax (501) de l'email($email). ID = $id_member\n";
			}
			elsif($error_reason =~/smtp; 550/ && $error_reason !~/black list/ && $error_reason !~/blacklist/ && $error_reason !~/service unavailable/  && $error_reason !~/blocked/  && $error_reason !~/rule/  && $error_reason !~/address rejected/) {
				my %permanentbounce_error = 
				(
				   email=>lc($email),
				   moment=>$error_moment,
				   reason=>'unknown email (550)',
				   id_mailing=>$idmailing,
				   id_sending=>$id_sending,
				);
				if($id_email ne "") {
					$stmt = "UPDATE `mailing_blacklist` SET moment = '$error_moment', reason = 'bad email syntax (500)', id_mailing = '$idmailing', id_sending = '$id_sending' WHERE id = '$id_email'";
					execstmt($dbh,$stmt);
				}
				else {
					inserth_db($dbh,"mailing_blacklist",\%permanentbounce_error);
				}
				$addtoblacklist = 1;
				print "unknown email (550) de l'email($email). ID = $id_member\n";
			}
			elsif($error_reason =~/smtp; 553/ && $error_reason !~/black list/ && $error_reason !~/blacklist/ && $error_reason !~/service unavailable/  && $error_reason !~/blocked/  && $error_reason !~/rule/  && $error_reason !~/address rejected/) {
				my %permanentbounce_error = 
				(
				   email=>lc($email),
				   moment=>$error_moment,
				   reason=>'incorrect email (553)',
				   id_mailing=>$idmailing,
				   id_sending=>$id_sending,
				);
				if($id_email ne "") {
					$stmt = "UPDATE `mailing_blacklist` SET moment = '$error_moment', reason = 'bad email syntax (500)', id_mailing = '$idmailing', id_sending = '$id_sending' WHERE id = '$id_email'";
					execstmt($dbh,$stmt);
				}
				else {
					inserth_db($dbh,"mailing_blacklist",\%permanentbounce_error);
				}
				$addtoblacklist = 1;
				print "incorrect email (553) de l'email($email). ID = $id_member\n";
			}
			elsif($error_reason =~/smtp; 554/ && $error_reason !~/black list/ && $error_reason !~/blacklist/ && $error_reason !~/service unavailable/  && $error_reason !~/blocked/  && $error_reason !~/rule/  && $error_reason !~/address rejected/) {
				my %permanentbounce_error = 
				(
				   email=>lc($email),
				   moment=>$error_moment,
				   reason=>'permanent error (554)',
				   id_mailing=>$idmailing,
				   id_sending=>$id_sending,
				);
				if($id_email ne "") {
					$stmt = "UPDATE `mailing_blacklist` SET moment = '$error_moment', reason = 'bad email syntax (500)', id_mailing = '$idmailing', id_sending = '$id_sending' WHERE id = '$id_email'";
					execstmt($dbh,$stmt);
				}
				else {
					inserth_db($dbh,"mailing_blacklist",\%permanentbounce_error);
				}
				$addtoblacklist = 1;
				print "permanent error (554) de l'email($email). ID = $id_member\n";
			}
			
			if($addtoblacklist == 1) {
					
				my %queue_error = 
				(
				   id_member => $id_member,
				   moment=>$error_moment,
				   nom_evt=>$nom_evt,
				   detail_evt=>$mailings_error{detail_evt},
				   erreur_evt=>$error_reason,
				   type_evt=>'blacklist_mailing',
				   date_event=>$date,
				   time_event=>$time,
				   group_type_event=>'mailing',
				);
				%queue_error = %{quoteh(\%queue_error)};			
				inserth_db($dbh,"migcms_members_events",\%queue_error);
				
			}
			print "Erreur email($email). ID = $id_member\n";
		}
	}
} 
