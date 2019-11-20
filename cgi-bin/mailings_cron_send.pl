#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use mailing;
use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset);


see();
send_mailings();

################################################################################
# SEND_MAILINGS
################################################################################

sub send_mailings
{
	#récupèré les envois qui n'ont pas encore étés envoyés
	my @mailing_sendings = sql_lines({table=>'mailing_sendings',where=>"send_to_mailer = '0' AND (status = 'new' OR status='planned')"});
	if($#mailing_sendings > -1)
	{
		$dbh_send = DBI->connect($config{db_qm},$config{login_qm},$config{passwd_qm}) or suicide("cannot connect to sending DB");
		execstmt($dbh_send,"SET NAMES utf8");
	}
	foreach $mailing_sending (@mailing_sendings)
	{
		my %mailing_sending = %{$mailing_sending};
		
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
			if($mailing_sending{mode} eq "TEST") 
			{
				$mailing_sending{mailing_object} = "TEST - ".$mailing_sending{mailing_object};
				$mailing_sending{mailing_name} = "TEST - ".$mailing_sending{mailing_name};
				$limit = "10";
			}
			
			#créer le mailing
			my $mailer_id_sending = create_migc_mailing
			(
				$dbh_send,
				$mailing_sending{mailing_name}, #campain_name
				"$mailing_sending{mailing_from}<$mailing_sending{mailing_from_email}>", #from
				$mailing_sending{mailing_object}, #object
				$mailing_sending{mailing_content},
				$mailing_sending{id},
				$mailing_sending{planned_time},
				$mime_att,
				1,
				$mailing_headers,
				$mailing_sending{status},
				$mailing_sending{mode}
			);
			
			
			
			#récupérer les emails et boucler
			my $nb_sent_to_mailer = 0;
			my $where = mailing::mailing_get_where_member({tags=>$mailing_sending{tags}});
			my @emails = sql_lines({debug=>0,debug_results=>0,table=>'migcms_members',where=>$where,limit=>$limit});
			foreach $email (@emails)
			{
				my %email = %{$email};
				
				if($email{email} ne '')
				{			
					my $url_unsubscribe = "$config{fullurl}/cgi-bin/members.pl?sw=member_mailing_unsubscribe_db&id_mailing=$mailing_sending{id_migcms_page}&id_sending=$mailing_sending{id}&email=";
					
					create_migc_mq($dbh_send,$mailer_id_sending,$email{email},\@t_data,$url_unsubscribe,\%mailing_cfg);
					
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
			
			#tout est envoyé au mailer
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
    
 #log_to("orig_content : $content");

 $name =~ s/\'/\\\'/g;
 $subject =~ s/\'/\\\'/g;
 $content =~ s/\'/\\\'/g;
 $content =~ s/<br \/>/<br \/>\r\n/g;
 $content =~ s/<\/p>/<\/p>\r\n/g;
 $from_email =~ s/\'/\\\'/g;

 my $ganalytics_account = $config{google_analytics};
#  my $stmt = "START TRANSACTION";
#  execstmt($dbh_send,$stmt);
 execstmt($dbh_send,"SET CHARSET utf8");
 
 $stmt = "INSERT INTO mailings (mailing_name, from_email, subject, content, queued_time, planned_time, status, dbname, id_nl, mime_att, multi, mailing_headers, google_analytics) VALUES ('$name','$from_email','$subject', '$content', NOW(), '$planned_time','$status','$config{db_name}','$id_sending','$mime_att',1,'$mailing_headers','$ganalytics_account')";

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


 my $stmt = "INSERT INTO queue (id_mailing, to_email,queued_on,status,url_unsub,no_count $dfields) VALUES ('$id_sending','$to_email', NOW(),'wait','$url_unsub','$cfg{no_count}' $dvals)";
 execstmt($dbh,$stmt);
}