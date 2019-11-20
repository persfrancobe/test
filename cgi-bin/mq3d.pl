#!/usr/bin/perl -I/var/www/vhosts/mailer.fw.be/httpdocs/cgi-bin

use DBI;   # standard package for Database access
use MIME::Lite;
use LWP::UserAgent;
use File::Path; 
use mailercfg;

$MAILINGS_TABLE="mailings";
$QUEUE_TABLE="queue";

$DATA_DIR = $mailercfg{data_dir};
$LOG_FILE = $mailercfg{log_file};
$COUNT_URL = $mailercfg{count_url};
$SENDER_HOST = $mailercfg{sender_host};
$DELAY = $mailercfg{delay};
$LIMIT = $mailercfg{limit};


################################################################################
# MQ3D.PL - Mail queue daemon
# ------------------------------------------------------------------------------
# This script manages the centralized sending of mass emailing, collected through
# a database. The clients push the requested sendings, acting like a FIFO queue.
# When sending is done, an email is sent to the emettor containing a report. 
################################################################################

my $lwp = LWP::UserAgent->new();

# some sorcery...
mq_daemon($dbh,$lwp);



################################################################################
# MQ_DAEMON
################################################################################

sub mq_daemon
{
	# get the parameters
	my $dbh = $_[0];
	my $lwp = $_[1];
 	
	while (1) # till the end of time...
	{
   
		# log_to($stmt);
		# take some rest...
		select(undef,undef,undef,$DELAY);
		
		# connect to database
		$dbh = DBI->connect($mailercfg{new_dbname},$mailercfg{new_login},$mailercfg{new_passwd},{ RaiseError => 1, HandleError=>\&handle_error, AutoCommit=>0 }) or die("cannot connect to $mailercfg{new_dbname}");
		my $stmt = " SET NAMES UTF8";	
		my $cursor = $dbh->prepare($stmt);		
		my $rc = $cursor->execute;
		
		$stmt = "SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED";
		execstmt($dbh,$stmt);
		$stmt = "START TRANSACTION";
		execstmt($dbh,$stmt);

		# select the unachieved mailings
		# $stmt = "LOCK TABLES mailings WRITE,queue WRITE";
		# execstmt($dbh,$stmt);
		# log_to($stmt);

		# log_to("before begin_work");
		# $dbh->begin_work();
		# log_to("after begin_work");

		$stmt = <<"EOSQL";
SELECT id,status,from_email,subject,content,dbname,mime_att,tmp_att,multi,mailing_headers,google_analytics,mailing_name,dbname
	FROM $MAILINGS_TABLE
	WHERE status <> 'ended' 
	AND status <> 'aborted' 
	AND status <> 'new' 
	AND status <> 'planned'
	AND status <> ''
	AND multi = 1
EOSQL

		my $cursor = $dbh->prepare($stmt);
		my $rc = $cursor->execute;
		if (!defined $rc) {suicide($stmt);}
		# log_to($stmt);
		# and for each
		while (($id_mailing,$status,$from,$subject,$content,$dbname,$mime_attachments,$tmp_attachments,$multi,$mailing_headers,$ganalytics_account,$mailing_name) = $cursor->fetchrow_array()) {	
		
			if ($status eq "started") {
				my $stmt = "UPDATE $MAILINGS_TABLE SET status = 'current', start_time=NOW() WHERE id = $id_mailing";
				execstmt($dbh,$stmt);
			}
			#elsif ($status eq "planned") {
			#	my $stmt = "UPDATE $MAILINGS_TABLE SET status = 'started' WHERE id = $id_mailing AND status='planned' AND planned_time <= NOW() AND year(planned_time) <> '0000'";
			#	log_to($stmt);
			#	execstmt($dbh,$stmt);
			#	last;
			#}
			
			# log_to("fetching data");
			my $real_from  = $dbname;
			$real_from =~ s/DBI:mysql://g;
			$real_from =~ s/admin//g;
			$real_from =~ s/[_12345]//g;

			my @pjs = ();

				 
			
			if ($mime_attachments && $tmp_attachments eq "") {
				#log_to("first time - download attachments");
				my ($cid_content,$tmpdir,$ref_pjs,$tmp_att) = process_inline_images($content,$lwp,1,$tmp_attachments);
				@pjs = @{$ref_pjs};
				# print Dumper @pjs;
				$content = $cid_content;
				  
				# $stmt = "LOCK TABLES mailings WRITE";
				# execstmt($dbh,$stmt);
					

				$stmt = <<"EOSQL";
UPDATE $MAILINGS_TABLE
	SET tmp_att = '$tmp_att' 
	WHERE id = $id_mailing 
EOSQL
				execstmt($dbh,$stmt);
				  
				# log_to($stmt);
			} elsif ($tmp_attachments ne "") {
				#log_to("nth time - attachments in $tmp_attachments");
				my ($cid_content,$tmpdir,$ref_pjs,$tmp_att) = process_inline_images($content,$lwp,0,$tmp_attachments);
				@pjs = @{$ref_pjs};
				# print Dumper @pjs;
				$content = $cid_content;
			}
			
			$stmt = "COMMIT"; 
			execstmt($dbh,$stmt);

			$stmt = "SET TRANSACTION ISOLATION LEVEL READ COMMITTED";
			execstmt($dbh,$stmt);
			$stmt = "START TRANSACTION";
			execstmt($dbh,$stmt);
			
			#log_to("before make_sending");			 
			# send all the emails
			my $sent = make_sending($dbh,
				$lwp,
				$id_mailing,
				$from,
				$subject,
				$content,
				$mime_att,
				$real_from,
				\@pjs,
				$mailing_headers,
				$ganalytics_account,
				$mailing_name
			);
			
			$stmt = "COMMIT"; 
			execstmt($dbh,$stmt);
			
			$stmt = "SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED";
			execstmt($dbh,$stmt);
			$stmt = "START TRANSACTION";
			execstmt($dbh,$stmt);
			
			if ($sent > 0) {
				# update tricky counter
				$stmt = "UPDATE $MAILINGS_TABLE SET nbsent = nbsent + 1 WHERE id = $id_mailing";
				execstmt($dbh,$stmt);
			}
			
			$stmt = "COMMIT"; 
			execstmt($dbh,$stmt);
			
			# log_to("after make_sending");			 
			if ($sent == 0) {
			
				# log_to("sent == 0");
				
				$stmt = "SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED";
				execstmt($dbh,$stmt);
				$stmt = "START TRANSACTION";
				execstmt($dbh,$stmt);
				
				$stmt = "UPDATE $MAILINGS_TABLE SET status = 'ended', end_time=NOW() WHERE id = $id_mailing";
				execstmt($dbh,$stmt);
				
				#send_report($dbh,$id_mailing);
				
				$stmt = "COMMIT"; 
				execstmt($dbh,$stmt);
				  
				#my $stmt2 = <<"EOSQL";
#SELECT nbsent 
#	FROM $MAILINGS_TABLE
#	WHERE id=$id_mailing
#EOSQL

#				my $cursor2 = $dbh->prepare($stmt2);
#				my $rc2 = $cursor2->execute;
								
#				if (!defined $rc2) {suicide($stmt2);}
				#log_to($stmt2);
				# and for each
#				my ($nbsent) = $cursor2->fetchrow_array();
#				if ($nbsent > 0) {
					# log_to("nbsent > 0");
					# set the status flag to ok
#					$stmt = "UPDATE $MAILINGS_TABLE SET status = 'ended', end_time=NOW() WHERE id = $id_mailing and nbsent > 0 ";
#					execstmt($dbh,$stmt);
					#log_to("$stmt");

					#if ($mime_attachments) {
						#log_to("DELETING $DATA_DIR$tmp_attachments");
						#rmtree($DATA_DIR.$tmp_attachments);
					#}

					# send report to responsible people
					# log_to("sending report");
					#send_report($dbh,$id_mailing);
#				}
				
			}
			
		}  
		
		#log_to("---- COMMIT ----");
		#$dbh->commit();
		
		#$stmt = "COMMIT";
		#execstmt($dbh,$stmt);
		
		$cursor->finish();
		$dbh->disconnect();
	}	

}

################################################################################
# MAKE_SENDINGS
################################################################################

sub make_sending
{
	# get the parameters
	my $dbh = $_[0];
	my $lwp = $_[1];
	my $id_mailing = $_[2];
	my $from = $_[3];
	my $subject = $_[4];
	my $origcontent = $_[5];
	my $mime_att = $_[6];
	my $real_from = $_[7];
	my @pjs = @{$_[8]};
	my $mailing_headers = $_[9];
	my $ganalytics_account = $_[10];
	my $mailing_name = $_[11];

	# select each 'to' adress to send email to them 

	$stmt = <<"EOSQL";
SELECT id,to_email,qmdata1,qmdata2,qmdata3,qmdata4,qmdata5,url_unsub,no_count 
	FROM $QUEUE_TABLE 
	WHERE status = 'wait' 
	AND id_mailing='$id_mailing' 
	LIMIT $LIMIT
	FOR UPDATE
EOSQL

	my $cursor = $dbh->prepare($stmt);
	my $rc = $cursor->execute;
	if (!defined $rc) {suicide($stmt);}

	my $sent = 0;
	my @qmdata = ();
	my ($id_qm,$to_email,$url_unsub,$no_count);

	# for each of them
	while (($id_qm,$to_email,$qmdata1,$qmdata2,$qmdata3,$qmdata4,$qmdata5,$url_unsub,$no_count) = $cursor->fetchrow_array())
	{
		#use Email::Valid;
		#my $chech_to_email = Email::Valid->address($to_email);
		
			
        if ($to_email =~ /^[^@]+@([-\w]+\.)+[A-Za-z]{2,4}$/ && $to_email !~ /^\-/) { # email valide

			my $content = $origcontent;
			my $co = "";
			$_ = $content; 

			if (/<MQD_EMAIL_HERE>/) {
			   $content =~ s/<MQD_EMAIL_HERE>/$to_email/g;
			}
			#for (my $i=1;$i<=5; $i++) {
			#	my $tag = '<MQD_DATA'.$i.'_HERE>';
			#	my $value = $qmdata[$i];  
			#	if (/$tag/) {
			#		$content =~ s/$tag/$value/g;
			#	}   
			#}

   if (/<MQD_DATA1_HERE>/)
       {
        $content =~ s/<MQD_DATA1_HERE>/$qmdata1/g;
       }

   if (/<MQD_DATA2_HERE>/)
       {
        $content =~ s/<MQD_DATA2_HERE>/$qmdata2/g;
       }

   if (/<MQD_DATA3_HERE>/)
       {
        $content =~ s/<MQD_DATA3_HERE>/$qmdata3/g;
       }

   if (/<MQD_DATA4_HERE>/)
       {
        $content =~ s/<MQD_DATA4_HERE>/$qmdata4/g;
       }

   if (/<MQD_DATA5_HERE>/)
       {
        $content =~ s/<MQD_DATA5_HERE>/$qmdata5/g;
       }
	   
			if (/<MIGC_UNSUBSCRIBE_URL_HERE>/) {
				$url_unsub.=$to_email;
				$content =~ s/<MIGC_UNSUBSCRIBE_URL_HERE>/$url_unsub/g;
			}

			$_ = $co = $content;
			my @lnks = (/href=\"([^#].*?)\"/g);
		
		   foreach $lnk (@lnks) {
				$oldlnk = $lnk;
				$lnk =~ s/\&amp;/\@\@URL\_SEP\@\@/g;
				$lnk =~ s/\&/\@\@URL\_SEP\@\@/g;
				
				if ($oldlnk ne $lnk) {
					$content =~ s/\Q$oldlnk\E/$lnk/;
				}
			}

			my $click_url= $COUNT_URL."sw=click&id=$id_mailing&email=$to_email&url=";    
			$content =~ s/a href=\"([^#].*?)\"/a href=\"$click_url$1\"/g;

			my $open_url = $COUNT_URL."sw=open&id=$id_mailing&email=$to_email";
		
			my $ganalytics_pic = "";
			if($ganalytics_account ne "") {
				use UUID::Random;
				use URI::Escape;
				
				my $uuid = UUID::Random::generate;
				$mailing_name = uri_escape($mailing_name);
				$ganalytics_pic = "<img src=\"http://www.google-analytics.com/collect?v=1&tid=$ganalytics_account&cid=$uuid&t=event&ec=email&ea=open&el=recipient_id&cs=newsletter&cm=email&cn=$mailing_name&ci=$id_mailing\" border=\"0\" width=\"1\" height=\"1\" styles=\"display:none;\" />";
			}

			my $pic = "<img src=\"$open_url\" border=\"0\" width=\"1\" height=\"1\" styles=\"display:none;\" />$ganalytics_pic";

			if ($no_count ne "y"){
				$content =~ s/<\/body>\s*<\/html>/$pic<\/body><\/html>/i; 
			}

			send_mail(
				$from, #email sender
				$to_email,                                                   #email to
				$subject,                                            #subject
				$content,                                            #content
				$id_mailing."/".$id_qm,                                                 #mailingid + queue id
				$url_unsub.$to_email, #unsub url
				$real_from.'@mailer.fw.be',                                     #real from
				\@pjs,                                                  # array of attachments
				$mailing_headers
			);

			$sent = 1;
			# set status to send
			$stmt = "UPDATE $QUEUE_TABLE SET status='sent',sent_on=NOW(),sent_by='$SENDER_HOST' WHERE id = '$id_qm'";
			execstmt($dbh,$stmt);
        } 
		else { # email pas valide
			$sent = 1;
		
			$stmt = "UPDATE $QUEUE_TABLE SET status='sent',has_error='y',sent_on=NOW(),sent_by='$SENDER_HOST' WHERE id = '$id_qm'";
			execstmt($dbh,$stmt);
		}
	}

	return $sent;
}