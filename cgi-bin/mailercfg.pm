#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
package mailercfg;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@ISA = qw(Exporter);

@EXPORT = qw(
%mailercfg
handle_error
log_to
execstmt
suicide
process_inline_images
get_txt_from_html_body
minify_html_body
send_mail
);

use Encode;
use HTML::Entities;


%mailercfg = ();

$mailercfg{old_dbname} = "DBI:mysql:qm";
$mailercfg{old_login} = "mailer";
$mailercfg{old_passwd} = "h3sLC8seCu39XrcZ";
$mailercfg{new_dbname} = "DBI:mysql:mailer";
$mailercfg{new_login} = "mailer";
$mailercfg{new_passwd} = "h3sLC8seCu39XrcZ";
$mailercfg{data_dir} = "/var/www/vhosts/mailer.fw.be/data/";
$mailercfg{log_file} = "/var/www/vhosts/mailer.fw.be/logs/mq3d.log";
$mailercfg{count_url} = "http://mailer.fw.be/cgi-bin/track.pl?";
$mailercfg{sender_host} = "mailer.fw.be";
$mailercfg{delay} = 0.1;
$mailercfg{limit} = 1;

$LOG_FILE = $mailercfg{log_file};
$DATA_DIR = $mailercfg{data_dir};

sub handle_error {
	my $error = shift;
	log_to("An error occurred in the script");
	log_to("Message: $error");
	return 1;
}

################################################################################
# LOG_TO
################################################################################

sub log_to
{
	my $txt = $_[0];
	my $file = $LOG_FILE; 
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

	open (LOGFILE,">>$file");
	my $log = sprintf("[%04d-%02d-%02d:%02d:%02d:%02d]",$year+1900,$mon+1,$mday,$hour,$min,$sec)."[$txt]\n";
	# print $log;
	print LOGFILE $log;
	close (LOGFILE);
}

################################################################################
# EXECSTMT
################################################################################

sub execstmt
{
	my $dbh = $_[0];
	my $stmt = $_[1];

	# log_to($stmt);
	my $sth = $dbh->prepare($stmt) or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth->execute or die("error execute : $DBI::errstr [$stmt]\n");

	#  $dbh->do($stmt) || die ("$DBI::errstr [$stmt]\n");
}

################################################################################
# SUICIDE
################################################################################

sub suicide
{
	log_to($_[0]);
	die($_[0]);	
}

################################################################################
# PROCESS_INLINE_IMAGES
################################################################################

sub process_inline_images
{
	my $html_in = $_[0];
	my $lwp = $_[1];
	my $make_download = $_[2];
	my $tmp_att = $_[3];

	my $tmp_dir = "";

	if ($tmp_att eq "") {
		my @chars = ( "A" .. "Z", "a" .. "z");
		$tmp_att =join("", @chars[ map { rand @chars } ( 1 .. 10 ) ]);
		$tmp_dir =$DATA_DIR.$tmp_att;
		mkdir($tmp_dir);
	} else {
		$tmp_dir = $DATA_DIR.$tmp_att;
		if (!-e $tmp_dir) {
			mkdir($tmp_dir);
			$make_download=1;

		}
	}

	$_ = $html_in;

	my @pjs = ();
	my $html_out = $html_in;

	my @imgs = (/src=\"([^#].*?)\"/ig);
    
	foreach $img (@imgs) {
		my @imgparts = split(/\//,$img);
		my $filename = pop @imgparts;
		my @fileparts = split(/\./,$filename);
		my $ext = lc(pop(@fileparts)); 

		my $tmpfile = $tmp_dir."/".$filename;

		if ($make_download) {
		$lwp->mirror($img,$tmpfile);
		}

		my %pj = (
			type=> "image/".$ext,
			id=> $filename,
			path=> $tmpfile    
		);      

		push @pjs,\%pj;

		$html_out =~ s/$img/cid:$filename/g;
	}
      
	return ($html_out,$tmpdir,\@pjs,$tmp_att);  
}   

################################################################################
# GET_TXT_FROM_HTML_BODY
################################################################################

sub get_txt_from_html_body
{
	my $body_html = $_[0];

	$body_html = decode("utf8", $body_html);

	$body_html = decode_entities($body_html,'<>&');

	use HTML::FormatText::WithLinks;

	my $f = HTML::FormatText::WithLinks->new(
		leftmargin => 0,
		before_link => '',
		after_link => ' (%l)',
		footnote => ''
	);

	my $body_text = $f->parse($body_html);

	$body_text = encode("utf8", $body_text);

	return $body_text;
}

################################################################################
# MINIFY_HTML_BODY
################################################################################

sub minify_html_body
{
	my $body_html = $_[0];
	$body_html =~ s/ISO-8859-1/UTF-8/ig;

	use HTML::Packer;
	my $packer = HTML::Packer->init(); 
	my $minified_body_html = $packer->minify( \$body_html);

	return $minified_body_html;
}

################################################################################
# SEND_MAIL
################################################################################

sub send_mail
{
	# get parameters
	my $adr_from = $_[0];
	my $adr_to = $_[1];
	my $subject = $_[2];
	my $body_html = $_[3];
	my $sending_id = $_[4];
	my $url_unsub = $_[5];
	my $real_from = $_[6];
	my @pjs = @{$_[7]};
	my $mailing_headers = $_[8];
 
	if ($real_from eq '') {
	$real_from = 'mailer@mailer.fw.be'; 
	} 

	my ($list_id,$host) = split(/\@/,$real_from);
	
	my $body_text = get_txt_from_html_body($body_html);

	$body_html = minify_html_body($body_html);

	my ($name,$email) = split(/</,$adr_from);
	$email=~s/[<>]//g;

	$name = encode("MIME-B",decode_utf8($name));
	$adr_from = $name.' <'.$email.'>'; 

	$msg = MIME::Lite->new(
		From    =>$adr_from,
		To      =>$adr_to,
		Subject =>encode("MIME-B", decode_utf8($subject)),
		Type    =>'multipart/alternative',
	);  

	my $text = MIME::Lite->new(
		Type => 'text/plain;charset=UTF-8',
		Encoding => 'quoted-printable',
		Data => $body_text,
	);
	$text->delete("X-Mailer");
	$text->delete("Date");

	my $html = MIME::Lite->new(
		Type => 'multipart/related',		 
	);
   
	$html->attach(
		Type => 'text/html;charset=UTF-8',
		Data => $body_html,
		Encoding => 'quoted-printable',
	);
	$html->delete("X-Mailer");
	$html->delete("Date");	
	$html->attr('content-type.charset' => 'UTF-8');
   
   foreach my $pj (@pjs) {
    
        my %pj = %{$pj};
                    
        $html->attach(
            Type => $pj{type},
            Id   => $pj{id},
            Path => $pj{path},
        );
        
    }

	$msg->attach($text);   
	$msg->attach($html);   

	$msg->delete("X-Mailer");
	$msg->add("Return-path" => $real_from);
	
	if ($mailing_headers) {
		$msg->add("Sender" => $real_from);
		$msg->add("X-Sender-Id" => $sending_id);
		$msg->add("List-Id" => $list_id);
		$msg->add("List-Owner" => $adr_from);
		$msg->add("List-Unsubscribe" => "<$url_unsub>,<mailto:$adr_from?subject=unsubscribe from mailing list&body=Please unsubscribe my address ($adr_to) from your mailing list>");
		$msg->add("X-Mailer" => "FW Mailer");
		$msg->add("X-Report-Abuse" => "Please report abuse by forwarding a copy of this message to abuse\@fw.be");
	}


	$msg->send_by_smtp('localhost',Port=>587,SetSender=>1);   
}

1;