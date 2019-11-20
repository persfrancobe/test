#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Package de la librairie
package mailing;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@ISA = qw(Exporter);	#Permet l'export
@EXPORT = qw(
             is_mailing_member_from_blacklist
			 mailing_get_where_member
			 sync_mailings_from_mailer
            );
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use tools;
use def;

$config{db_qm} = "DBI:mysql:mailer;host=mailer.fw.be";
$config{login_qm} = "mailer";
$config{passwd_qm} = "h3sLC8seCu39XrcZ";

sub mailing_get_where_member
{
	my %d = %{$_[0]};
	
	my $id_member_rule = $d{id_member_rule};
	my $variable_a = $d{variable_a};
	my $variable_b = $d{variable_b};
	my $tags = $d{tags};
	my $groupes = $d{groupes};
	
	my $emails_test_r = $d{emails_test};
	my $tag_interdit = $d{tag_interdit};
	log_debug($emails_test_r,'','mailing_get_where_member');

	my $id_migcms_page = $d{id_migcms_page};
	my @emails_test = ();
	my $list_emails_test = '';
	
	my @emails_test_raw = split('\,',$emails_test_r);
	my @emails_test = ();
	
	foreach my $email_test_raw (@emails_test_raw)
	{
		$email_test_raw =~ s/\'//g;
		$email_test_raw =~ s/\s//g;
		$email_test_raw = trim($email_test_raw);
		if($email_test_raw ne '')
		{
			push @emails_test, "'$email_test_raw'";
		}
	}	
	$list_emails_test = join(",",@emails_test);

	my @where_legal = ();
	my @where_tags = ();
	my @where_groupes = ();
	
	my $field_optout = 'email_optin';
	if($d{num_optout} == 2)
	{
		$field_optout = 'email_optin_2';
	}

	#email pas vide
	push @where_legal," email != '' ";
	
	#stoken pas vide
	push @where_legal," stoken != '' ";
	
	#token pas vide
	push @where_legal," token != '' ";
	
	#email valide
	push @where_legal,' email REGEXP "^[A-Z0-9._%-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$" ';
	
	#email optin
	push @where_legal," $field_optout = 'y' ";
	
	#black list
	push @where_legal," email NOT IN (SELECT email FROM mailing_blacklist) ";
	
	#TAGS
	my $tags_presents = 0;
	my @ids = split('\,',$tags);
	foreach my $id (@ids)
	{
		if($id > 0)
		{
			$tags_presents = 1;
			push @where_tags, " tags LIKE '%,$id,%' ";
		}
	}
	
	#GROUPES
	my $groupes_presents = 0;
	my @groupes = split('\,',$groupes);
	foreach my $groupe (@groupes)
	{
		if($groupe > 0)
		{
			$groupes_presents = 1;
			push @where_groupes, " tags LIKE '%,$groupe,%' ";
		}
	}
	
	my $where_legal = join(" AND ",@where_legal);
	my $where_tags = join(" AND ",@where_tags);
	my $where_groupes = join(" OR ",@where_groupes);
	if($where_legal eq '')
	{
		return 0;
	}
	
	my @where_final = ();

	if($where_tags ne '' && $list_emails_test eq '')
	{
		push @where_final,  " ( $where_tags ) ";
	}
	if($where_groupes ne '' && $tags_presents == 0 && $list_emails_test eq '')
	{
		push @where_final,  " ( $where_groupes ) ";
	}
	if($list_emails_test ne '')
	{
		push @where_final,  " ( email IN ($list_emails_test) ) ";
	}
	if($tag_interdit ne '')
	{
		push @where_final,  " ( tags NOT LIKE '%,$tag_interdit,%' ) ";
	}
	
	#contacts répondant aux critères OU contacts des sociétés répondant aux critères
	my $where_fathers = '';
	if(join(" AND ",@where_final) ne '')
	{
		$where_fathers = " ( id_father > 0 AND id_father IN (SELECT id FROM `migcms_members` WHERE id_father = 0 AND (".join(" AND ",@where_final).")) AND ( $where_legal ) )";
	}

	#ajout des conditions "legales"
	push @where_final,  " ( $where_legal ) ";
	
	#conditions légales ET les segments ou les jokers
	my $where_final = "(".join(" AND ",@where_final).")";
	
	log_debug('WHERE final:'.$where_final,'','mailing_get_where_member');
	log_debug('WHERE fathers:'.$where_fathers,'','mailing_get_where_member');
	
	#final + fathers
	my @where_global = ();
	push @where_global, $where_final;
	if($where_fathers ne '')
	{
		push @where_global, $where_fathers;
	}
	my $where_global = join(" OR ",@where_global);
	
	if($id_member_rule > 0)
	{
		my %migcms_members_rule = sql_line({table=>'migcms_members_rules',where=>"id='$id_member_rule'"});
		$where_global = $migcms_members_rule{where_members};
		
		if($variable_a eq '' && $where_global =~ /PARAMETRE1/)
		{
			#un paramètre est attendu !
			return 0;
		}
		if($variable_b eq '' && $where_global =~ /PARAMETRE2/)
		{
			#un paramètre est attendu !
			return 0;
		}
		
		$where_global =~ s/PARAMETRE1/$variable_a/g;
		$where_global =~ s/PARAMETRE2/$variable_b/g;
	}	
	
	log_debug('WHERE GLOBAL:'.$where_global,'','mailing_get_where_member');

	return $where_global;
}


sub is_mailing_member_from_blacklist
{
 my $dbh = $_[0];
 my $email = $_[1];
 
 my $stmt = "select email FROM mailing_blacklist WHERE email='$email'";
 my $cursor = $dbh->prepare($stmt);
 my $rc = $cursor->execute || die("error execute : $DBI::errstr [$stmt]\n");

 my ($selemail);
 
 $cursor->bind_columns(\$selemail);
 $cursor->fetch();
 $cursor->finish;
  
 if (lc($selemail) eq lc($email)) {return 1;}
 return 0;
}

sub sync_mailings_from_mailer
{
	$dbh_send = DBI->connect($config{db_qm},$config{login_qm},$config{passwd_qm}) or suicide("cannot connect to sending DB");
	execstmt($dbh_send,"SET NAMES utf8mb4");
	
	my $where_db_name = $config{db_name};
	my $where_db = "dbname='$where_db_name'";
	
	if($where_db_name eq 'DBI:mysql:medimerck2016')
	{
		$where_db = " dbname='DBI:mysql:medimerck' OR dbname='DBI:mysql:medimerck2016' ";
	}
	
	my @mailings = sql_lines({dbh=>$dbh_send,table=>'mailings',where=>"$where_db"});
	foreach $mailing (@mailings)
	{
		my %mailing = %{$mailing};
		
		my %update_mailing_sending = 
		(
			queued_time => $mailing{queued_time},
			start_time => $mailing{start_time},
			end_time => $mailing{end_time},
			planned_time => $mailing{planned_time},
			status => $mailing{status},
			nb_sent => $mailing{nbsent},
			nb_open => $mailing{nbopen},
			nb_click => $mailing{nbclick},
			nb_open_unique => $mailing{nbuopen},
			nb_click_unique => $mailing{nbuclick},			
		);
		updateh_db($dbh,"mailing_sendings",\%update_mailing_sending,'id',$mailing{id_nl});
	}
}

1;