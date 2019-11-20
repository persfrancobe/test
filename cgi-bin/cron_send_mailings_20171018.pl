#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
# use dm;
use mailing;
use members;
use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset);
use def_handmade;

see();
send_mailings();
member_events_to_mailing_tags();


sub member_events_to_mailing_tags
{
	log_debug('member_events_to_mailing_tags','vide','cron_send_mailings');
	my $id_dir_envoi = 0;
	my $id_dir_lecture = 0;
	my $id_dir_clic = 0;
	
	if($config{id_dir_envoi} > 0)
	{
		$id_dir_envoi = $config{id_dir_envoi};
	}
	if($config{id_dir_lecture} > 0)
	{
		$id_dir_lecture = $config{id_dir_lecture};
	}
	if($config{id_dir_clic} > 0)
	{
		$id_dir_clic = $config{id_dir_clic};
	}
	if($id_dir_envoi > 0 && $id_dir_lecture > 0 && $id_dir_clic > 0 && $config{tag_from_date} ne '')
	{
		my @newsletters = sql_lines({ordby=>'id',select=>'p.id,p.mailing_object',table=>"migcms_pages p",where=>"p.migcms_pages_type LIKE 'newsletter' AND p.id NOT IN (select id_src from migcms_members_tags where table_src='migcms_pages')"});
		foreach $newsletter(@newsletters)
		{
			my %newsletter = %{$newsletter};
			$newsletter{lg1} =~ s/\'/\\\'/g;
			$newsletter{mailing_object} =~ s/\'/\\\'/g;
			
			#envoi
			my %update_newsletter_tag = (
			'id_src' => $newsletter{id},
			'name' => 'Envoi: '.$newsletter{id}.': '.$newsletter{mailing_object},
			'table_src' => 'migcms_pages',
			'type' => 'Membres: Envoi newsletters',
			'fusion' => 'Membres: Envoi newsletters > Envoi: '.$newsletter{mailing_object},
			'id_migcms_member_dir' => $id_dir_envoi,
			);
			# see(\%update_newsletter_tag);
			sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_members_tags',data=>\%update_newsletter_tag, where=>"table_src='$update_newsletter_tag{table_src}' AND id_src='$update_newsletter_tag{id_src}' AND id_migcms_member_dir='$update_newsletter_tag{id_migcms_member_dir}'"});
			
			#lecture
			my %update_newsletter_tag = (
			'id_src' => $newsletter{id},
			'name' => 'Lecture: '.$newsletter{id}.': '.$newsletter{mailing_object},
			'table_src' => 'migcms_pages',
			'type' => 'Membres: Lecture newsletters',
			'fusion' => 'Membres: Lecture newsletters > Lecture: '.$newsletter{mailing_object},
			'id_migcms_member_dir' => $id_dir_lecture,
			);
			# see(\%update_newsletter_tag);
			sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_members_tags',data=>\%update_newsletter_tag, where=>"table_src='$update_newsletter_tag{table_src}' AND id_src='$update_newsletter_tag{id_src}' AND id_migcms_member_dir='$update_newsletter_tag{id_migcms_member_dir}'"});
			
			#clic
			my %update_newsletter_tag = (
			'id_src' => $newsletter{id},
			'name' => 'Clic: '.$newsletter{id}.': '.$newsletter{mailing_object},
			'table_src' => 'migcms_pages',
			'type' => 'Membres: Clic newsletters',
			'fusion' => 'Membres: Clic newsletters > Clic: '.$newsletter{mailing_object},
			'id_migcms_member_dir' => $id_dir_clic,
			);
			# see(\%update_newsletter_tag);
			sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_members_tags',data=>\%update_newsletter_tag, where=>"table_src='$update_newsletter_tag{table_src}' AND id_src='$update_newsletter_tag{id_src}' AND id_migcms_member_dir='$update_newsletter_tag{id_migcms_member_dir}'"});
		}	
		# log_debug('tags créés','','cron_send_mailings');
		
		#queue_mailing,sent_mailing -> id_dir_envoi
		#open_mailing -> id_dir_lecture
		#click_mailing -> id_dir_clic
		
		my %cache_envoi = ();
		my %cache_lecture = ();
		my %cache_clic = ();
		my %cache_page_sending = ();
		
		my @tags_envoi = sql_lines({table=>'migcms_members_tags',where=>"id_migcms_member_dir='$id_dir_envoi' AND table_src='migcms_pages'"});
		my @tags_lecture = sql_lines({table=>'migcms_members_tags',where=>"id_migcms_member_dir='$id_dir_lecture' AND table_src='migcms_pages'"});
		my @tags_clic = sql_lines({table=>'migcms_members_tags',where=>"id_migcms_member_dir='$id_dir_clic' AND table_src='migcms_pages'"});
		my @mailing_sendings = sql_lines({table=>'mailing_sendings',where=>""});
		
		foreach $tag_envoi (@tags_envoi)
		{
			my %tag_envoi = %{$tag_envoi};
			#pour un id de page, retrouver l'id tag
			$cache_envoi{$tag_envoi{id_src}} = $tag_envoi{id};
		}	
		foreach $tag_lecture (@tags_lecture)
		{
			my %tag_lecture = %{$tag_lecture};
			#pour un id de page, retrouver l'id tag
			$cache_lecture{$tag_lecture{id_src}} = $tag_lecture{id};
		}
		foreach $tag_clic (@tag_clic)
		{
			my %tag_clic = %{$tag_clic};
			#pour un id de page, retrouver l'id tag
			$cache_clic{$tag_clic{id_src}} = $tag_clic{id};
		}
		foreach $mailing_sending (@mailing_sendings)
		{
			my %mailing_sending = %{$mailing_sending};
			#pour un id de seding, retrouver l'id page
			$cache_page_sending{$mailing_sending{id}} = $mailing_sending{id_migcms_page};
		}
		# log_debug('caches créés','','cron_send_mailings');
		
		my $limit = "0,6000";
		
		# my @mailing_sendings = sql_lines({select=>"id",table=>'mailing_sendings',where=>"id_migcms_page IN ('100281','100282')"});
		# foreach $mailing_sending (@mailing_sendings)
		# {
			# my %mailing_sending = %{$mailing_sending};
			# $config{tag_where_supp} = "detail_evt LIKE '$mailing_sending{id}|%' AND ";
			 # $config{tag_from_date} = "2000-01-01";
			 
			my @migcms_member_events = sql_lines({select=>"id,id_member,detail_evt,type_evt",table=>"migcms_members_events",ordby=>"id desc",where=>"$config{tag_where_supp} moment > '$config{tag_from_date}' AND trans = 0 AND type_evt IN ('queue_mailing','sent_mailing','open_mailing','click_mailing')",limit=>"$limit"});
			foreach $migcms_member_event (@migcms_member_events)
			{
				my %migcms_member_event = %{$migcms_member_event};
				
				my ($id_sending,$dum,$dum) = split(/\|/,$migcms_member_event{detail_evt});
				my $id_tag = 0;
				
				if($migcms_member_event{type_evt} eq 'queue_mailing')
				{
					$id_tag = $cache_envoi{$cache_page_sending{$id_sending}};
				}
				elsif($migcms_member_event{type_evt} eq 'sent_mailing')
				{
					$id_tag = $cache_envoi{$cache_page_sending{$id_sending}};			
				}
				elsif($migcms_member_event{type_evt} eq 'open_mailing')
				{
					$id_tag = $cache_lecture{$cache_page_sending{$id_sending}};			
				}
				elsif($migcms_member_event{type_evt} eq 'click_mailing')
				{
					$id_tag = $cache_clic{$cache_page_sending{$id_sending}};			
				}
				
				my %update_migcms_member_tag_email = 
				(
					'id_migcms_member_tag' => $id_tag,
					'id_migcms_member' => $migcms_member_event{id_member},
					'migcms_last_published_file' => 'cron_send_mailings',
					'migcms_moment_create' => 'NOW()',
				);
				inserth_db($dbh,"migcms_member_tag_emails",\%update_migcms_member_tag_email);
				# sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_member_tag_emails',data=>\%update_migcms_member_tag_email, where=>"id_migcms_member_tag='$update_migcms_member_tag_email{id_migcms_member_tag}' AND id_migcms_member='$update_migcms_member_tag_email{id_migcms_member}'"});
				
				if($config{member_events_to_mailing_tags_after_func} ne '')
				{
					my $func = 'def_handmade::'.$config{member_events_to_mailing_tags_after_func};
					&$func($update_migcms_member_tag_email{id_migcms_member});
					# log_debug('Member: '.$migcms_member_event{id_member}.' Sending: '.$id_sending.' Tag: '.$id_tag,'','cron_send_mailings');
				}
				
				$stmt = "UPDATE `migcms_members_events` SET trans = '1' WHERE id = '$migcms_member_event{id}'";
				log_debug($stmt,'','cron_send_mailings');
				execstmt($dbh,$stmt);
			}
		# }	
	}
}


################################################################################
# SEND_MAILINGS
################################################################################

sub send_mailings
{
	#récupère les envois qui n'ont pas encore étés envoyés
	my @mailing_sendings = sql_lines({debug=>0,debug_results=>0,table=>'mailing_sendings',where=>"send_to_mailer = '0' AND (status = 'new' OR status='planned')"});
	
	if($#mailing_sendings > -1)
	{
		$dbh_send = DBI->connect($config{db_qm},$config{login_qm},$config{passwd_qm}) or suicide("cannot connect to sending DB");
		$stmt = " SET NAMES utf8mb4";	
		$cursor = $dbh->prepare($stmt);		
		$rc = $cursor->execute;	
	}
	
	foreach $mailing_sending (@mailing_sendings)
	{
		my %mailing_sending = %{$mailing_sending};
		
		my %migcms_page = sql_line({table=>'migcms_pages',where=>"id='$mailing_sending{id_migcms_page}'"});
	
		my $full_url_param = $config{fullurl};

		my $num_optout = '';
		if($mailing_sending{basehref} ne '')
		{
			$full_url_param = $mailing_sending{basehref};
		}
		$full_url_param = $1 if($full_url_param=~/(.*)\/$/); #retire le dernier slash

		if($config{'optout_for_base_href_'.$full_url_param} > 0)
		{
			$num_optout = 2;
		}
		
		if($mailing_sending{id} > 0)
		{
			if($mailing_sending{mode_test} eq 'y')
			{
				$mailing_sending{mode} = 'TEST';
			}
			
			#attacher les images au mail
			my $mime_att = 0;
			if($mailing_sending{mailing_include_pics} eq 'y')
			{
				$mime_att = 1;
			}
			my $mailing_headers = 0;
			if($mailing_sending{mailing_headers} eq 'y')
			{
				$mailing_headers = 1;
			}
			
			my $limit = "";
			if($mailing_sending{mode} eq "TEST" || $mailing_sending{mode_test} eq 'y') 
			{
				if($mailing_sending{mode_test} eq 'y' && $mailing_sending{mode} eq '')
				{
					$mailing_sending{mode} = 'TEST';
				}
				if($mailing_sending{mode_test} eq '' && $mailing_sending{mode} eq 'TEST')
				{
					$mailing_sending{mode_test} = 'y';
				}
				$mailing_sending{mailing_object} = "TEST - ".$mailing_sending{mailing_object};
				$mailing_sending{mailing_name} = "TEST - ".$mailing_sending{mailing_name};
				$limit = "10";
			}
			
			# créer le mailing
			my $mailer_id_sending = create_migc_mailing
			(
				$dbh_send,
				$mailing_sending{mailing_name}, #campain_name
				"$mailing_sending{mailing_from} <$mailing_sending{mailing_from_email}>", #from
				$mailing_sending{mailing_object}, #object
				$mailing_sending{mailing_content},
				$mailing_sending{id},
				$mailing_sending{planned_time},
				$mime_att,
				1,
				$mailing_headers,
				$mailing_sending{status},
				$mailing_sending{mode},
				$mailing_sending{mail_system},
				$mailing_sending{googleanalytics},
			);
			
			$stmt = "UPDATE mailing_sendings SET send_to_mailer='1' WHERE id  = $mailing_sending{id}";
			execstmt($dbh,$stmt);
			
			# my $tags = $d{tags};
			# my $click_depuis = $d{click_depuis};
			# my $ouvert_depuis = $d{ouvert_depuis};
			# my $ajout_pas_recu_cette_nl = $d{ajout_pas_recu_cette_nl};
			# my $ajout_pas_recu_aucune_nl = $d{ajout_pas_recu_aucune_nl};
			# my $id_migcms_page = $d{id_migcms_page};
			
			
			#récupérer les emails et boucler
			my $nb_sent_to_mailer = 0;
			my $where = mailing::mailing_get_where_member({tags=>$mailing_sending{tags},groupes=>$mailing_sending{groupes},emails_test=>$mailing_sending{emails_test},num_optout=>$num_optout,click_depuis=>$mailing_sending{click_depuis},ouvert_depuis=>$mailing_sending{ouvert_depuis},ajout_pas_recu_cette_nl=>$mailing_sending{ajout_pas_recu_cette_nl},ajout_pas_recu_aucune_nl=>$mailing_sending{ajout_pas_recu_aucune_nl},id_migcms_page=>$mailing_sending{id_migcms_page}});
			my @emails = sql_lines({select=>"",debug=>0,debug_results=>0,groupby=>"email",table=>'migcms_members',where=>$where,limit=>$limit});
			foreach $email (@emails)
			{
				my %email = %{$email};
				
				if($email{email} ne '')
				{			
					# my $url_unsubscribe = $full_url_param."/cgi-bin/members.pl?sw=member_mailing_unsubscribe_db&id_mailing=$mailing_sending{id_migcms_page}&id_sending=$mailing_sending{id}&email=";
					my $url_unsubscribe = $full_url_param."/fr/membres/desinscription-mailing$num_optout/$mailing_sending{id_migcms_page}/$mailing_sending{id}/";

					# Si mailing sur backoffice multisites et que c'est le 2e site
					# On indique un template de page alternatif
					if($num_optout eq "2")
					{
						my %member_setup = %{members::member_get_setup()};
						my $id_page = $member_setup{id_page_bis};
						$url_unsubscribe = $full_url_param."/fr/membres/desinscription-mailing$num_optout/$mailing_sending{id_migcms_page}/$mailing_sending{id}/$id_page/";
					}

					$f1 = $email{stoken};
					log_debug($url_unsubscribe,'','url_unsubscribe');
					log_debug($where,'','url_unsubscribe');
					
					my @t_data = ($f1,$f2,$f3,$f4,$f5);
					
					my $email = $email{email};
					$email =~ s/\'/\\\'/g;
					
					create_migc_mq($dbh_send,$mailer_id_sending,$email{email},\@t_data,$url_unsubscribe,\%mailing_cfg);
					
					# INSERT queue to member (nouvelle version)
					my $id_member = $email{id};
					my $nom_evt = "Envoi de l'emailing ".$mailing_sending{id}." au membre";
					my $detail_evt = $mailing_sending{id};
				 
					my %queue_sent = 
					(
					   id_member =>$id_member,
					   moment=>'NOW()',
					   nom_evt=>$nom_evt,
					   detail_evt=>$detail_evt,
					   type_evt=>'queue_mailing',
					   date_event=>'CURDATE()',
					   time_event=>'DATE_FORMAT(NOW(), "%T")',
					   group_type_event=>'mailing',
					);
					%queue_sent = %{quoteh(\%queue_sent)};			
					inserth_db($dbh,"migcms_members_events",\%queue_sent);
					
					$nb_sent_to_mailer++;
					if($nb_sent_to_mailer == 250) 
					{
						$stmt = "UPDATE mailings set status='started' where id = $mailer_id_sending and status <> 'planned'";
						execstmt($dbh_send,$stmt);
					}
				}
				
			}
			
			if($nb_sent_to_mailer < 250) 
			{
				$stmt = "UPDATE mailings set status='started' where id = $mailer_id_sending and status <> 'planned'";
				execstmt($dbh_send,$stmt);
			}
			
			# tout est envoyé au mailer
			$stmt = "UPDATE mailing_sendings SET send_to_mailer='2' WHERE id  = $mailing_sending{id}";
			execstmt($dbh,$stmt);
		}
	}
} 

###############################################################################
# CREATE_MIGC_MAILING
###############################################################################

sub create_migc_mailing
{
 my $dbh_send = $_[0];
 my $name = $_[1];
 my $from_email = $_[2];
 my $subject = $_[3];
 my $content = $_[4];
 my $id_sending = $_[5];
 my $planned_time = $_[6];
 my $mime_att = $_[7];
 my $multi = $_[98];
 my $mailing_headers = $_[9];
 my $status = $_[10];
 my $mode = $_[11];
 my $mail_system = $_[12];
 my $googleanalytics = $_[13];
    
 #log_to("orig_content : $content");

 $name =~ s/\'/\\\'/g;
 $subject =~ s/\'/\\\'/g;
 $content =~ s/\'/\\\'/g;
 $content =~ s/<br \/>/<br \/>\r\n/g;
 $content =~ s/<\/p>/<\/p>\r\n/g;
 $from_email =~ s/\'/\\\'/g;

 my $ganalytics_account = $config{google_analytics};
 if($googleanalytics ne '')
 {
	$ganalytics_account = $googleanalytics;
 }
#  my $stmt = "START TRANSACTION";
#  execstmt($dbh_send,$stmt);
# execstmt($dbh_send,"SET CHARSET utf8");
 execstmt($dbh_send,"SET CHARSET utf8mb4");
 
 $stmt = "INSERT INTO mailings (mail_system, mailing_name, from_email, subject, content, queued_time, planned_time, status, dbname, id_nl, mime_att, multi, mailing_headers, google_analytics) VALUES ('$mail_system','$name','$from_email','$subject', '$content', NOW(), '$planned_time','$status','$config{db_name}','$id_sending','$mime_att',1,'$mailing_headers','$ganalytics_account')";

 execstmt($dbh_send,$stmt);
 my $id_mailing = $dbh_send->{'mysql_insertid'};
 

 #log_to("id_mailing : $id_mailing");
 #log_to("content : $content");
 return $id_mailing;
}

###############################################################################
# CREATE_MIGC_MQ
###############################################################################

sub create_migc_mq
{
 my $dbh = $_[0];
 my $id_sending = $_[1];
 my $to_email = $_[2];
 my @specdata = @{$_[3]};
 my $url_unsub = $_[4];
 my %cfg = %{$_[5]};


 my @fields = ();
 my @values = ();
 for (my $i = 0; $i<=$#specdata; $i++) {
      my $j = $i+1;
      if ($specdata[$i] ne "") {
          $specdata[$i] =~ s/\'/\\\'/g;
          push @fields,"qmdata".$j;
          my $val =   $specdata[$i];
          push @values,$val;                 
      }
 
 }
 my $dfields = "";
 my $dvals = "";
 if ($#values > -1) {
     $dfields = ",".join(",",@fields);     
     $dvals = ",'".join("','",@values)."'";     
 }

 $to_email =~ s/\'/\\\'/g;

 my $stmt = "INSERT INTO queue (id_mailing, to_email,queued_on,status,url_unsub,no_count $dfields) VALUES ('$id_sending','$to_email', NOW(),'wait','$url_unsub','$cfg{no_count}' $dvals)";
 execstmt($dbh,$stmt);
}