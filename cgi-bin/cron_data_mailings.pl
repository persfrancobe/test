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

# see();
data_mailings();

################################################################################
# SEND_MAILINGS
################################################################################

sub data_mailings
{
	my @mailing_sendings = sql_lines({table=>'mailing_sendings',where=>"send_to_mailer='2'"});
	my %cache_members = ();
	my %cache_members_tags = ();
	if($#mailing_sendings > -1)
	{
		print "Connexion au MAILER\n"; 
		$dbh_send = DBI->connect($config{db_qm},$config{login_qm},$config{passwd_qm}) or suicide("cannot connect to sending DB");
		execstmt($dbh_send,"SET NAMES utf8mb4");
		
		print "Création du tableau des membres\n";
		@members = sql_lines({debug=>0,table=>"migcms_members",select=>'id,email,tags'});
		foreach $member (@members)
		{
			my %member = %{$member};
			$cache_members{lc(trim($member{email}))} = $member{id};
			$cache_members_tags{$member{id}} = $member{tags};
		}
		#my $id_member = 1;
		#my $tags_member = $cache_members_tags{$id_member};
		#print $tags_member;
		#exit;
	}
	
	foreach $mailing_sending (@mailing_sendings)
	{
		my %mailing_sending = %{$mailing_sending};
		
		print "Boucle sur les sendings de la DB($config{db_name}). ID = $mailing_sending{id}\n";
		
		my @mailings_queue = get_table($dbh_send,"mailings as mls,queue as mls_queue","mls_queue.*","mls.id_nl='$mailing_sending{id}' AND mls.dbname='$config{db_name}' AND mls_queue.status <> 'wait' AND mls_queue.status <> 'ready' AND mls_queue.send_to_client=0 AND mls.id = mls_queue.id_mailing");
		
		foreach $mailing_queue (@mailings_queue)
		{	
			my %mailing_queue = %{$mailing_queue};
			
			print "Boucle sur la liste des destinataires. ID = $mailing_queue{id}\n";
		
			my $id = $mailing_queue{id};
			my $email = $mailing_queue{to_email};
			my $status = $mailing_queue{status};
			my $moment = $mailing_queue{sent_on};
			my $sent_by = $mailing_queue{sent_by};
			my $has_error = $mailing_queue{has_error};
			my $error_reason = $mailing_queue{error_reason};
			my $error_moment = $mailing_queue{err_dt};
			my $token = $mailing_queue{token};
			
			if($token eq '') {
				$token = "tokenmissing";
			}
						
			my $id_member = $cache_members{lc(trim($email))};
			print "Recherche de l'ID du membre sur base de l'email($email). ID = $id_member\n";
			
			if($id_member != 0 || $id_member ne "") {
				my $nom_evt = "";
				my $detail_evt = "";
				if($status eq 'sent') {
					my ($date,$time) = split(/ /,$moment);
					$nom_evt = "Envoi de l'emailing ".$mailing_sending{id}." au membre";
					$detail_evt = $mailing_sending{id}."|".$sent_by."|".$token;
					
					# INSERT sent to member (ancienne version)
					#my %queue_sent = 
					#(
					#   id_member =>$id_member,
					#   moment=>$moment,
					#   nom_evt=>$nom_evt,
					#   detail_evt=>$detail_evt,
					#   type_evt=>'sent_mailing',
					#   date_event=>$date,
					#   time_event=>$time,
					#   group_type_event=>'mailing',
					#);
					#%queue_sent = %{quoteh(\%queue_sent)};			
					#inserth_db($dbh,"migcms_members_events",\%queue_sent);
					
					#UPDATE queue_mailing to member (nouvelle version)
					$stmt = "UPDATE `migcms_members_events` SET moment = '$moment', detail_evt='$detail_evt', type_evt='sent_mailing', date_event='$date', time_event='$time'  WHERE id_member = '$id_member' AND detail_evt='$mailing_sending{id}'";
					execstmt($dbh,$stmt);
					
				}
				if($has_error eq 'y') {
					my ($date,$time) = split(/ /,$error_moment);
					$nom_evt = "Envoi de l'emailing ".$mailing_sending{id}." au membre a échoué";
					$detail_evt = $mailing_sending{id}."|".$sent_by."|".$token;
					my @l = split('\r*\n',$error_reason);
					foreach my $l (@l) {          
						if ($l =~ /^Diagnostic-Code: (.*?)$/) {$error_reason = $1;}
					}
					if($error_reason eq "") {
						$error_reason = "Erreur";
					}
					
					# INSERT error to member
					my %queue_error = 
					(
					   id_member => $id_member,
					   moment=>$error_moment,
					   nom_evt=>$nom_evt,
					   detail_evt=>$detail_evt,
					   erreur_evt=>$error_reason,
					   type_evt=>'error_mailing',
					   date_event=>$date,
					   time_event=>$time,
					   group_type_event=>'mailing',
					);
					%queue_error = %{quoteh(\%queue_error)};			
					inserth_db($dbh,"migcms_members_events",\%queue_error);
					
					my %mailings = sql_line({debug=>0,table=>"mailing_sendings",select=>'id_migcms_page',where=>"id='$id'"});
					my $idmailing = $mailings{id_migcms_page};
					
					$error_reason = lc($error_reason);
					
					my $addtoblacklist = 0;
					
					my %emails = sql_line({debug=>0,table=>"mailing_blacklist",select=>'id',where=>"email='$email'"});
					my $id_email = $emails{id};
					
					my $nbr_open_click = 0;
					my %count_open_click = sql_line({debug=>0,table=>"migcms_members_events",select=>'COUNT(id) as nbr',where=>"id_member='$id_member' AND (type_evt = 'open_mailing' OR type_evt = 'click_mailing')"});
					$nbr_open_click = $count_open_click{nbr};
					
					my $nbr_error = 0;
					my %count_error = sql_line({debug=>0,table=>"migcms_members_events",select=>'COUNT(id) as nbr',where=>"id_member='$id_member' AND type_evt = 'error_mailing'"});
					$nbr_error = $count_error{nbr};
					
					my $mailing_nbr_error_blacklist = $config{mailing_nbr_error_blacklist} | 5;
					#my $mailing_nbr_error_blacklist = 1;
					
					if($nbr_open_click > 0 || $nbr_error >= $mailing_nbr_error_blacklist) {
						if($error_reason =~/smtp; 500/ && $error_reason =~/smtp;500/ && $error_reason !~/black list/ && $error_reason !~/blacklist/ && $error_reason !~/service unavailable/  && $error_reason !~/blocked/  && $error_reason !~/rule/  && $error_reason !~/address rejected/) {
							my %permanentbounce_error = 
							(
							   email=>lc(trim($email)),
							   moment=>$error_moment,
							   reason=>'bad email syntax (500)',
							   id_mailing=>$idmailing,
							   id_sending=>$mailing_sending{id},
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
						elsif($error_reason =~/smtp; 501/ && $error_reason =~/smtp;501/ && $error_reason !~/black list/ && $error_reason !~/blacklist/ && $error_reason !~/service unavailable/  && $error_reason !~/blocked/  && $error_reason !~/rule/  && $error_reason !~/address rejected/) {
							my %permanentbounce_error = 
							(
							   email=>lc(trim($email)),
							   moment=>$error_moment,
							   reason=>'bad email syntax (501)',
							   id_mailing=>$idmailing,
							   id_sending=>$mailing_sending{id},
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
						elsif($error_reason =~/smtp; 550/ && $error_reason =~/smtp;550/ && $error_reason !~/black list/ && $error_reason !~/blacklist/ && $error_reason !~/service unavailable/  && $error_reason !~/blocked/  && $error_reason !~/rule/  && $error_reason !~/address rejected/) {
							my %permanentbounce_error = 
							(
							   email=>lc(trim($email)),
							   moment=>$error_moment,
							   reason=>'unknown email (550)',
							   id_mailing=>$idmailing,
							   id_sending=>$mailing_sending{id},
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
						elsif($error_reason =~/smtp; 553/ && $error_reason =~/smtp;553/ && $error_reason !~/black list/ && $error_reason !~/blacklist/ && $error_reason !~/service unavailable/  && $error_reason !~/blocked/  && $error_reason !~/rule/  && $error_reason !~/address rejected/) {
							my %permanentbounce_error = 
							(
							   email=>lc(trim($email)),
							   moment=>$error_moment,
							   reason=>'incorrect email (553)',
							   id_mailing=>$idmailing,
							   id_sending=>$mailing_sending{id},
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
						elsif($error_reason =~/smtp; 554/ && $error_reason =~/smtp;554/ && $error_reason !~/black list/ && $error_reason !~/blacklist/ && $error_reason !~/service unavailable/  && $error_reason !~/blocked/  && $error_reason !~/rule/  && $error_reason !~/address rejected/) {
							my %permanentbounce_error = 
							(
							   email=>lc(trim($email)),
							   moment=>$error_moment,
							   reason=>'permanent error (554)',
							   id_mailing=>$idmailing,
							   id_sending=>$mailing_sending{id},
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
							   detail_evt=>$detail_evt,
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
				$stmt = "UPDATE `queue` SET send_to_client = '1' WHERE id = '$id'";
				execstmt($dbh_send,$stmt);
			}
			else {
				log_debug($email,'','data_mailing_queues');
				$stmt = "UPDATE `queue` SET send_to_client = '2' WHERE id = '$id'";
				execstmt($dbh_send,$stmt);
			}
		}
			
		my @mailings_stats = sql_lines({debug=>0,dbh=>$dbh_send,table=>"mailings as mls,stats as mls_stats",where=>"mls_stats.send_to_client = 0 AND mls.id_nl='$mailing_sending{id}' AND mls.dbname='$config{db_name}' AND mls_stats.send_to_client=0 AND mls.id = mls_stats.id_mailing"});
		foreach $mailings_stat (@mailings_stats)
		{	
			my %mailings_stat = %{$mailings_stat};
		
			my $id = $mailings_stat{id};
			my $email = $mailings_stat{email};
			my $op = $mailings_stat{op};
			my $params = $mailings_stat{params};
			my $moment = $mailings_stat{moment};
			my $ip = $mailings_stat{ip};
			my $user_agent = $mailings_stat{user_agent};
			my $device = $mailings_stat{device};
			my $lat = $mailings_stat{lat};
			my $long = $mailings_stat{lon};
			my $city = $mailings_stat{city};
			my $country = $mailings_stat{country};
			my $referer = $mailings_stat{referer};
			
			my ($date,$time) = split(/ /,$moment);
						
			my $id_member = $cache_members{lc(trim($email))};
			print "Recherche de l'ID du membre sur base de l'email($email). ID = $id_member\n";
			
			my $tags_member = $cache_members_tags{$id_member};
			my $new_tags = $tags_member;
			
			my $tag_open = ','.$config{mailing_tag_open}.',';
			my $tag_click = ','.$config{mailing_tag_click}.',';
			
			if($id_member != 0 || $id_member ne "") {
			
				my $nom_evt = "";
				my $detail_evt = "";
				if($op eq 'open') {
					$nom_evt = "Le membre consulte l'emailing ".$mailing_sending{id};
					$detail_evt = $mailing_sending{id};
					
					if($tags_member !~/$tag_open/) {
						my $new_id_tag = $tag_open;
						$new_tags = $new_tags.$new_id_tag;
						$stmt = "UPDATE migcms_members SET tags='".$new_tags."' WHERE id ='".$id_member."'";
						execstmt($dbh,$stmt);
						print "Ajout tag 'Ouvert' au membre ($email). ID = $id\n";
						
						my %stats = 
						(
						   id_member => $id_member,
						   moment=>"NOW()",
						   nom_evt=>"Ajout du tag 'Ouvert' au membre",
						   detail_evt=>$tag_open,
						   type_evt=>'add_tag_mailing',
						   date_event=>"DATE(moment)",
						   time_event=>"TIME(moment)",
						   group_type_event=>'tags',
						);
						%stats = %{quoteh(\%stats)};			
						my $id_event = inserth_db($dbh,"migcms_members_events",\%stats);
						$stmt = "UPDATE migcms_members_events SET date_event=DATE(moment), time_event = TIME(moment) where id=$id_event";
						execstmt($dbh,$stmt);						
					}
				}
				if($op eq 'click') {
					$nom_evt = "Le membre clique sur le lien $params de l'emailing ".$mailing_sending{id};
					$detail_evt = $mailing_sending{id}."|".$params;
					if($tags_member !~/$tag_click/) {
						my $new_id_tag = $tag_click;
						$new_tags = $new_tags.$new_id_tag;
						$stmt = "UPDATE migcms_members SET tags='".$new_tags."' WHERE id ='".$id_member."'";
						execstmt($dbh,$stmt);
						print "Ajout tag 'Click' au membre ($email). ID = $id\n";
						
						my %stats = 
						(
						   id_member => $id_member,
						   moment=>"NOW()",
						   nom_evt=>"Ajout du tag 'Click' au membre",
						   detail_evt=>$tag_click,
						   type_evt=>'add_tag_mailing',
						   date_event=>"DATE(moment)",
					       time_event=>"TIME(moment)",
						   group_type_event=>'tags',
						);
						%stats = %{quoteh(\%stats)};			
						my $id_event = inserth_db($dbh,"migcms_members_events",\%stats);
						$stmt = "UPDATE migcms_members_events SET date_event=DATE(moment), time_event = TIME(moment) where id=$id_event";
						execstmt($dbh,$stmt);	
					}
				}
				if($op eq 'unsubscribe') {
					$nom_evt = "Le membre se désinscrit en cliquant sur le lien $params de l'emailing ".$mailing_sending{id};
					$detail_evt = $mailing_sending{id};
				}
						
				my %stats = 
				(
				   id_member => $id_member,
				   moment=> $moment,
				   nom_evt=>$nom_evt,
				   detail_evt=>$detail_evt,
				   type_evt=>$op.'_mailing',
				   date_event=>$date,
				   time_event=>$time,
				   group_type_event=>'mailing',
				   ip=>$ip,
				   user_agent=>$user_agent,
				   device=>$device,
				   lat=>$lat,
				   lon=>$long,
				   city=>$city,
				   country=>$country,
				   referer=>$referer,
				);
				%stats = %{quoteh(\%stats)};			
				inserth_db($dbh,"migcms_members_events",\%stats);
				
				$stmt = "UPDATE `stats` SET send_to_client = '1' WHERE id = '$id'";
				execstmt($dbh_send,$stmt);
			}
			else {
				log_debug($email,'','data_mailing_stats');
				$stmt = "UPDATE `stats` SET send_to_client = '2' WHERE id = '$id'";
				execstmt($dbh_send,$stmt);
			}
		}
	}
	
	apply_id_mailings();
	fill_clic_date();
	fill_view_date();
} 

sub fill_clic_date
{
		if($config{compute_members_clic_date} eq 'y')
		{
			$stmt = "update migcms_members m SET migcms_last_clic = (SELECT date_event FROM `migcms_members_events` WHERE id_member=m.id AND type_evt = 'click_mailing' ORDER BY date_event DESC limit 1)'";
			log_debug("<br>Traitement: $stmt",'','fill_clic_date');
			execstmt($dbh,$stmt);
		}
}
sub fill_view_date
{
		if($config{compute_members_view_date} eq 'y')
		{
			$stmt = "update migcms_members m SET migcms_last_view = (SELECT date_event FROM `migcms_members_events` WHERE id_member=m.id AND type_evt = 'open_mailing' ORDER BY date_event DESC limit 1)'";
			log_debug("<br>Traitement: $stmt",'','fill_view_date');
			execstmt($dbh,$stmt);
		}
}


sub apply_id_mailings
{
	see();
	# my @mailing_sendings = sql_lines({table=>'mailing_sendings',where=>"id_migcms_page='100265'"});
	
	# my @mailing_sendings = sql_lines({table=>'mailing_sendings',where=>"migcms_moment_create >= DATE_SUB(CURRENT_DATE, INTERVAL 8 DAY)"});
	my @mailing_sendings = sql_lines({table=>'mailing_sendings',where=>""});
	log_debug('sendings créés depuis x jours:'.($#mailing_sendings+1),'','apply_id_mailings');
	foreach $mailing_sending (@mailing_sendings)
	{
		my %mailing_sending = %{$mailing_sending};
	
		$stmt = "UPDATE migcms_members_events SET id_event = '$mailing_sending{id_migcms_page}' WHERE `type_evt` IN ('sent_mailing','open_mailing') AND `id_event` = 0 and detail_evt LIKE '$mailing_sending{id}|%'";
		log_debug("<br>Traitement: $stmt",'','apply_id_mailings');
		execstmt($dbh,$stmt);
	}
	exit;
}