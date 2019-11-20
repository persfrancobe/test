#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Package de la librairie
package tools;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@ISA = qw(Exporter);	
@EXPORT = qw(
get_quoted
add_history
sql_set_data
sql_update_or_insert
sql_line
sql_lines
sql_listbox
sql_radios
select_table
format_tel
getcode
sql_to_human_date
sql_to_human_time
see
get_table
inserth_db
updateh_db
send_mail
send_mail_with_attachment
read_table
add_historique_envoi_email
sanitize_input
trim
get_languages_ids
get_traduction
set_traduction
get_textcontent
log_debug
get_url
get_sql_listbox
is_in
create_token
http_redirect
cgi_redirect
is_human_recaptcha
get_alert
get_txt_from_html_body
display_price
minify_html_body
clean_url
clean_filename
remove_accents_from
reset_file
get_file
get_script
write_file
execstmt
suicide
to_ddmmyyyy
get_describe
clean
cleanh
quote
quoteh
update_txtcontent
get_template
thumbnailize
get_next_ordby
upload_image
upload_file
compute_sql_date
add_denomination
get_hash_from_config
get_hash_from_fields
build_form
sql_listbox
split_date
split_time
split_datetime
make_spaces
pdf_text
get_email_communication
send_mail_commercial
get_migcms_sys
get_document_filename
fill_sys
fill_creation_date
get_list_of_tables
get_list_of_cols

get_csv_nbr_rows
get_xls_nbr_rows
get_xlsx_nbr_rows

get_excel_value
get_codes

write_file_csv




remove_param_from_url
sql_get_rows_array
sql_get_row_from_id
);
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use def;     
use Math::Round;
use JSON::XS;

clean_log_degug();

%migcms_urls = ();
my @migcms_urls = sql_lines({debug=>0,debug_results=>0,table=>'migcms_urls',select=>"nom_table,id_table,id_lg,url_rewriting"});
foreach $migcms_url (@migcms_urls)
{
	my %migcms_url = %{$migcms_url};
	$migcms_urls{$migcms_url{nom_table}.'_'.$migcms_url{id_table}.'_'.$migcms_url{id_lg}} = $migcms_url{url_rewriting};
}

#read cookie info
my %cookie_user_hash = ();
my $cookie_user = $cgi->cookie($config{migc4_cookie});
if($cookie_user ne "")
{
	  $cookie_user_ref = decode_json $cookie_user;
	  %cookie_user_hash=%{$cookie_user_ref};
}
%user = sql_line({debug=>$debug,debug_results=>$debug,table=>"users",where=>"token='$cookie_user_hash{token}' AND token != '' "});



%cache_templates_id = ();
%migcms_setup = ();

my @templates = sql_lines({select=>"id,template",table=>"templates"});
foreach $template (@templates)
{
	my %template = %{$template};
	$cache_templates_id{$template{id}} = $template{template};
}

#*****************************************************************************************
#SQL TO HUMAN TIME
#*****************************************************************************************
sub sql_to_human_date
{
   my $content = trim($_[0]);
   my ($year,$month,$day) = split (/-/,$content);
   return <<"EOH";
$day/$month/$year
EOH
}
#*****************************************************************************************
#SQL TO HUMAN TIME
#*****************************************************************************************
sub sql_to_human_time
{
   my $content = trim($_[0]);
   my $separator = $_[1] || 'h';
   my ($hour,$min,$sec) = split (/:/,$content);
   return $hour.$separator.$min;
EOH
}

#alias de sql_set_data
sub sql_update_or_insert
{
	my $dbh = $_[0];
	my $table = $_[1];
	my %rec = %{$_[2]};
	my $cle = $_[3];
	my $valeur = $_[4];
	my $where = " $cle = '$valeur' ";
	my $id = sql_set_data({dbh=>$dbh,debug=>0,table=>$table,data=>\%rec, where=>$where});  
	return $id;
}

sub sql_set_data
{
   my %d = %{$_[0]};
   $d{col_id} = $d{col_id} || 'id';
   my %data = %{$d{data}};
   
   if($d{where} ne '')
   {
        my @check_if_data_exists = sql_lines({dbh=>$d{dbh},select=>$d{select},table=>$d{table},where=>$d{where},debug=>$d{debug},debug_results=>$d{debug_results}});
        if($#check_if_data_exists > -1)
        {
              my %first_elt = %{$check_if_data_exists[0]};
			  
              my @columns = keys(%data);
            	my ($upd,$stmt,$rc);
            
            	foreach $v (@columns) 
              {
            	    $upd.="$v = '$data{$v}',";
            	}
            	chop($upd);
            
            	$stmt = "UPDATE $d{table} SET $upd WHERE $d{col_id} = '$first_elt{$d{col_id}}'";
            	$stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
            	$stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;
            
              if($d{debug} > 0)
              {
				log_debug($stmt);
              }
              $rc = $d{dbh}->do($stmt) || suicide("$DBI::errstr [$stmt]\n");
              return $first_elt{$d{col_id}}; 
        }
        else
        {
			  my @columns = keys(%data);
            	 my ($cols,$vals,$stmt,$rc);
            
            	 foreach $v (@columns)
            	 {
            	    $cols.="$v,";
            	    $vals.="'$data{$v}',";
            	 }
            	 chop($cols);
            	 chop($vals);
            
            	 $stmt = "INSERT into $d{table} ($cols) VALUES ($vals)";
            	 $stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
            	 $stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;
            	 
            	 
				if($d{debug} > 0)
				{
					log_debug($stmt);
				}
               
               $rc = $d{dbh}->do($stmt) || suicide("$DBI::errstr [$stmt]\n");
                
            	 return $d{dbh}->{mysql_insertid};
        }
   }
	 
	 my @columns = keys(%data);
	 my ($cols,$vals,$stmt,$rc);

	 foreach $v (@columns)
	 {
	    $cols.="$v,";
	    $vals.="'$data{$v}',";
	 }
	 chop($cols);
	 chop($vals);

	 $stmt = "INSERT into $d{table} ($cols) VALUES ($vals)";
	 $stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
	 $stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;
	 
	 if($d{debug} > 0)
	{
		log_debug($stmt);
	}
   
   $rc = $d{dbh}->do($stmt) || suicide("$DBI::errstr [$stmt]\n");
    
	 return $d{dbh}->{mysql_insertid};
}

sub sql_set_data_newer_but_bad
{
	my %d = %{$_[0]};
	$d{col_id} = $d{col_id} || 'id';
	my %data = %{$d{data}};
   
	if($d{where} ne '')
	{
		my @check_if_data_exists = sql_lines({dbh=>$d{dbh},select=>$d{select},table=>$d{table},where=>$d{where},debug=>$d{debug},debug_results=>$d{debug_results},limit=>"1"});
		if($#check_if_data_exists > -1)
		{
			my %first_elt = %{$check_if_data_exists[0]};	  
			return updateh_db($dbh,$d{table},\%first_elt,$d{col_id},$first_elt{$d{col_id}});	
		}
		else
		{
			return inserth_db($dbh,$d{table},\%data);	
		}
	}
	else
	{
		return inserth_db($dbh,$d{table},\%data);	
	}
}


sub send_mail
{
	my $adr_from = $_[0];
	my $adr_to = $_[1];
	my $subject = $_[2];
	my $body_html = $_[3];
	my $sending_id = $_[4];
	my $url_unsub = $_[5];
	my $real_from = $_[6];
	my @pjs = @{$_[7]};
	my $mailing_headers = $_[8];
	my $cc = $_[9];
	my $cci = $_[10];
	my $returnpath = $_[11];
	my $replyto = $_[12];
 
	my $body_text = get_txt_from_html_body($body_html);
	
	use MIME::Lite;

	$body_html = minify_html_body($body_html);
	
	my ($name,$email) = split(/</,$adr_from);
	$email=~s/[<>]//g;

	if($email eq "")
	{
		$adr_from = '<'.$name.'>'; 		
	}
	else
	{
		$name = encode("MIME-B",decode_utf8($name));
		$adr_from = $name.' <'.$email.'>'; 		
	}


	if($config{mode_developpement} eq "y")
	{
		$adr_to = 'dev@bugiweb.com';
	}

	if($adr_to ne 'debug@bugiweb.com' && $adr_to ne 'dev@bugiweb.com') {
	tools::add_historique_envoi_email({
		email_from      =>$adr_from,
		email_to      =>$adr_to,
		email_position     =>'To',
		email_object     =>$subject,
		email_body     =>$body_html,
	});
	}
	
	# tools::add_historique_envoi_email({
		# email_from      =>$adr_from,
		# email_to      =>$adr_to,
		# email_position     =>'cc',
		# email_object     =>$subject,
		# email_body     =>$body_text,
	# });
	# tools::add_historique_envoi_email({
		# email_from      =>$adr_from,
		# email_to      =>$adr_to,
		# email_position     =>'Cci',
		# email_object     =>$subject,
		# email_body     =>$body_text,
	# });
	
	$msg = MIME::Lite->new(
		From    =>$adr_from,
		To      =>$adr_to,
		Cc      =>$cc,
		Bcc     =>$cci,
		Reply-To=>$replyto,
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
		Type => 'multipart/mixed',
	);
   
	$html->attach(
		Type => 'text/html;charset=UTF-8',
		Data => $body_html,
		Encoding => 'quoted-printable',
	);
	$html->delete("X-Mailer");
	$html->delete("Date");	
	$html->attr('content-type.charset' => 'UTF-8');
   
   foreach my $pj (@pjs) 
   {
		my %pj = %{$pj};
		
		log_debug('Type:'.$pj{type}.'Id:'.$pj{id}.'Path:'.$pj{path}.'Filename:'.$pj{Filename});
		
		if($pj{type} ne '' && $pj{Filename} ne '')
		{
			$html->attach(
				Type => $pj{type},
				Id   => $pj{id},
				Path => $pj{path},
				Filename => $pj{Filename},
				Disposition => 'attachment'
			);
			$html->delete("Content-Disposition");
		}
    }

	$msg->attach($text);   
	$msg->attach($html);   

	$msg->delete("X-Mailer");
	
	if($returnpath ne "") {
		$msg->add("Return-path" => $returnpath);
	}
	
	$msg->send_by_smtp('localhost');
}


sub send_mail_with_attachment
{
	my $adr_from = $_[0];
	my $adr_to = $_[1];
	my $subject = $_[2];
	my $body = $_[3];
	my @pjs = @{$_[4]};
	my $type = $_[5];
	my $priority = $_[6];
	my $cc = $_[7];
	my $cci = $_[8];
	my $tracking = $_[9];
	
	send_mail(
				$adr_from, #email sender
				$adr_to,                                                   #email to
				$subject,                                            #subject
				$body,                                            #content
				$tracking,                                                 #mailingid + queue id
				'', #unsub url
				$adr_from,  #fake from ex: noreply@selion.be
				\@pjs,                                                  # array of attachments
				'',
				$cc,
				$cci
			);
	

}

sub inserth_db
{
	 my $dbh = $_[0];
	 my $table = $_[1];
	 my %row = %{$_[2]};
	 my $nosyscol = $_[3];
	 my @columns = keys(%row);
	 my ($cols,$vals,$stmt,$rc);


	
	if($nosyscol ne 'nosyscol')
	{
		$cols.="migcms_id_user_create,";
		$cols.="migcms_moment_create,";
		$cols.="migcms_id_user_last_edit,";
		$cols.="migcms_moment_last_edit,";	
		$cols.="migcms_id_user_view,";
		$cols.="migcms_moment_view,";	

		$vals.="'$user{id}',";
		$vals.="NOW(),";
		$vals.="'$user{id}',";
		$vals.="NOW(),";
		$vals.="'$user{id}',";
		$vals.="NOW(),";
	}
	
	 foreach $v (@columns)
	 {
	    if($v eq 'migcms_id_user_create' || $v eq 'migcms_moment_create' || $v eq 'migcms_id_user_last_edit' || $v eq 'migcms_moment_last_edit' || $v eq 'migcms_id_user_view' || $v eq 'migcms_moment_view')
		{
			next;
		}
		
		$cols.="$v,";
	    $vals.="'$row{$v}',";
	 }
	 chop($cols);
	 chop($vals);

	 $stmt = "INSERT into $table ($cols) VALUES ($vals)";
	 $stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
	 $stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;
	 $stmt =~ s/\'DATE\(NOW\(\)\)\'/DATE\(NOW\(\)\)/g;
	 $stmt =~ s/\'TIME\(NOW\(\)\)\'/TIME\(NOW\(\)\)/g;
	 $rc = $dbh->do($stmt) || suicide("$DBI::errstr [$stmt]\n");
	
	 my $new_id = $dbh->{mysql_insertid};
	 return $new_id;
}

sub updateh_db
{
	 my $dbh = $_[0];
	 my $table = $_[1];
	 my %row = %{$_[2]};
	 my $key = $_[3];
	 my $value = $_[4];
	 my $where_alt = $_[5];

	 my @columns = keys(%row);
	 my ($upd,$stmt,$rc);

	 
	$upd.="migcms_id_user_last_edit = '$user{id}',";
	$upd.="migcms_moment_last_edit = NOW(),";
	$upd.="migcms_id_user_view = '$user{id}',";
	$upd.="migcms_moment_view = NOW(),";
 
   return if ($#columns == -1);
   
    
	 foreach $v (@columns) 
	 {
	 
		if($v eq 'migcms_id_user_create' || $v eq 'migcms_moment_create' || $v eq 'migcms_id_user_last_edit' || $v eq 'migcms_moment_last_edit' || $v eq 'migcms_id_user_view' || $v eq 'migcms_moment_view')
		{
			next;
		}
	 
	    $upd.="$v = '$row{$v}',";
	 }
	 chop($upd);

	 my $where_update = " $key = '$value' ";
	 if($where_alt ne '')
	 {
		$where_update = $where_alt;
	 }
	 
	 
	 $stmt = "UPDATE $table SET $upd WHERE $where_update ";
	 $stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
	 $stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;

	 $dbh->do($stmt) || suicide("$DBI::errstr [$stmt]\n");
	 return $value;
}

sub execstmt
{
	 my $dbh = $_[0];
	 my $stmt = $_[1];

	 $dbh->do($stmt) || suicide ("$DBI::errstr [$stmt]\n");
}

sub get_quoted
{
	my $var = $_[0];	
	my $val = $cgi->param($var);	
       if (ref($cgi->upload($var)) eq "IO") {
           return $cgi->upload($var);
       }
  
	my $utf8 = $_[1];
	if ($utf8 eq "utf8") {
  	  use Encode;
	    $val = decode("utf8",$val);
  }
	
	my $dontsanitize = $_[2];
	
	#sanitiez if admin user is not logged
	my %cookie_user_hash_test = ();
	my $cookie_user = $cgi->cookie($config{migc4_cookie});
	if($cookie_user ne "")
	{
		  $cookie_user_ref = decode_json $cookie_user;
		  %cookie_user_hash_test=%{$cookie_user_ref};
	}
	if($cookie_user_hash_test{token} ne '')
	{
		$dontsanitize = 'dontsanitize';
	}

  my $quote = $_[3] || 'y';

	if ($dontsanitize eq "dontsanitize") {
      $val = $val;
  } else {
      $val = sanitize_input($val);
  }
	
	if($quote eq 'y')
  {
	 $val =~ s/\'/\\\'/g;	
  }
	
	return $val;	
}

sub sql_line
{
    my %d = %{$_[0]};
    $d{one_line} = 'y';
    return sql_lines(\%d);
}

sub sql_lines
{
    my %d = %{$_[0]};
	
    my $dbh_line = $dbh;
    $d{where} = trim($d{where});
    
    $d{where} =~ s/^WHERE//g;
    $d{where} =~ s/^where//g;
    if($d{where} eq "")    {    $d{where} = " 1 ";         }
    if($d{where} ne "")    {    $d{where} = "WHERE $d{where} ";         }
    
    $d{ordby} =~ s/ORDER BY//g;
    $d{ordby} =~ s/order by//g;
    if($d{ordby} ne "")    {    $d{ordby} = "ORDER BY $d{ordby} ";      }
    
    $d{groupby} =~ s/GROUP BY//g;
    $d{groupby} =~ s/group by//g;
    if($d{groupby} ne "")  {    $d{groupby} = "GROUP BY $d{groupby} ";    }
    
    $d{limit} =~ s/LIMIT//g;
    $d{limit} =~ s/limit//g;
    if($d{limit} ne "")    {    $d{limit} = "LIMIT $d{limit} ";         }
    
    if($d{select} eq "")   {    $d{select} = "*";                       }
    if($d{dbh} ne '')      {    

	$dbh_line = $d{dbh};                         } 
    
    if($d{stmt} eq '' && ($d{table} eq '' || $d{select} eq '' || $d{where} eq ''))
    {
        see();
        print "MISSING PARAMS: table[$d{table}]select[$d{select}]where[$d{where}]";
		
			use Carp;	
			my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller();
			my $stack = Carp::longmess("Stack backtrace :");
			$stack =~ s/\r*\n/<br>/g;
print $stack;			
		
        exit;
    }
    
    my @table =();
  	my $stmt = "SELECT $d{select} FROM $d{table} $d{where} $d{groupby} $d{ordby} $d{limit}";        
  	if($d{debug})        	
	{    
		if(1)
		{		
			# use Carp;	
			# my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller();
			# my $stack = Carp::longmess("Stack backtrace :");
			# $stack =~ s/\r*\n/<br>/g;		
			log_debug($stmt);
		}
		else
		{
			see();
			print $stmt;
		}          	
	
	}
	
	if($d{stmt} ne '')
	{
		$stmt = $d{stmt};
	}
	
  	my $cursor = $dbh_line->prepare($stmt) || die("CANNOT PREPARE $stmt");
  	$cursor->execute || suicide($stmt);
  	
    if($d{one_line} eq 'y')
    {
        my %ligne = %{$cursor->fetchrow_hashref()};
        $cursor->finish;
        if($d{debug_results})        	
		{    
			if(1)
			{
				use Data::Dumper;
				log_debug(Dumper(\%ligne));
			}
			else
			{
				see(\%ligne);
			}          	
		
		}
        return %ligne;
    } 
    
    while ($ref_rec = $cursor->fetchrow_hashref()) 
  	{
		push @table,\%{$ref_rec};
		if($d{debug_results})        	
		{    
			if(1)
			{
				log_debug(Dumper($ref_rec));
			}
			else
			{
				see($ref_rec);
			}          	
		
		}
  	}
  	$cursor->finish;
  	return @table;
}


sub read_table
{
  my $dbh_dbf     = $_[0];
  my $table       = $_[1] || "";
  my $id          = $_[2] || 0;
  my $debug       = $_[3] || 0;
  my %ligne=();
  
	my $stmt = "select * FROM $table where id='$id'";
  
  if($debug>0)
  {
    see();
    print "<br /><br />".$stmt;
  }
  if($id ne "")
  { 
   #print "\n$stmt";print "\n".join('/',caller);
  
      my $cursor = $dbh_dbf->prepare($stmt);
    	my $rc = $cursor->execute;
    	
    	if (!defined $rc) 
    	{
    		  see();
    		  print "[$stmt]";
    	    exit;   
    	}
    	 while ($ref_rec = $cursor->fetchrow_hashref()) 
    	 {
    	    %ligne = %{$ref_rec};
    	 } 
    	 $cursor->finish;
    	 return %ligne;
    }
    else
    {
        see();
        print "id non fourni";
        return "id non fourni";
    }
}

sub sanitize_input
{
 my $val = $_[0];
 
  $val =~ s/\a*//g;	
	$val =~ s/\e*//g;	
	$val =~ s/\x00*//g;	
	$val =~ s/\x0d*//g;	
	$val =~ s/\x04*//g;	
	$val =~ s/\/etc\/passwd//g;	
	$val =~ s/\/tmp//g;	
	$val =~ s/%00//g;	
	$val =~ s/%04//g;	
	$val =~ s/%0d//g;	
	$val =~ s/1=1//g;	
	$val =~ s/\/\*//g;	
	$val =~ s/\*\///g;	
	$val =~ s/null\,//ig;	
	$val =~ s/select\s+//ig;	
	$val =~ s/delete\s+//ig;	
	$val =~ s/update\s+//ig;	
	$val =~ s/\(select//ig;	
	$val =~ s/describe\s+//ig;	
 return $val;
}

sub trim
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub get_languages_ids
{
 my $dbh = $_[0];
 my $stmt = "SELECT id FROM migcms_languages where visible = 'y' ORDER BY id";
 my $cursor = $dbh->prepare($stmt);
 my $rc = $cursor->execute;
 if (!defined $rc) {suicide($stmt);}

 my @idarray = ();
 while (($id) = $cursor->fetchrow_array)
  {
    if($id > 0)
    {
        push (@idarray,$id);
    }
  }
 $cursor->finish;

 return (@idarray);
}

sub get_textcontent
{
 my $textid = $_[1];
 my $id_language = $_[2] || $config{current_language} || 1;
 my $traduction = get_traduction({id_language=>$id_language,id=>$textid});
 return ($traduction,$empty); 
}

#set_traduction({id_language=>1,traduction=>'',id_traduction=>4471,table_record=>'migcms_pages',col_record=>'id_textid_meta_title',id_record=>6});
sub set_traduction
{
	my %d = %{$_[0]};
	if($d{id_language} > 0)
	{
		my $id_traduction = 0;
		my %update_txtcontent = 
		(
			'lg'.$d{id_language} => $d{traduction},		
		);
		%update_txtcontent = %{quoteh(\%update_txtcontent)};
		
		if($d{table_record} ne '' && $d{col_record} ne '' && $d{id_record} > 0 )
		{
			$update_txtcontent{field_table_id} = $d{id_record};
			$update_txtcontent{field_table_name} = $d{table_record};
			$update_txtcontent{field_table_col} = $d{col_record};
		}
		
		#si id de traduction passé, on le teste
		if($d{id_traduction} > 0)
		{
			my %check_id = sql_line({table=>'txtcontents',where=>"id='$d{id_traduction}'"});
			if($check_id{id} > 0)
			{
				#ok: traduction existe, on fait la maj
				$id_traduction = $check_id{id};
				# log_debug($id_traduction.' updated','','set_traduction');
				updateh_db($dbh,"txtcontents",\%update_txtcontent,'id',$id_traduction);	
			}
			else
			{
				#la traduction n'existe pas, on crée une ligne
				$id_traduction = inserth_db($dbh,'txtcontents',\%update_txtcontent);	
				# log_debug($id_traduction.' inserted: id='.$d{id_traduction}.' non trouvé !','','set_traduction');
			}
		}
		else
		{
			#la traduction n'existe pas, on crée une ligne
			$id_traduction = inserth_db($dbh,'txtcontents',\%update_txtcontent);	
			log_debug($id_traduction.' inserted: id='.$d{id_traduction}.' non trouvé !','','set_traduction');
		}
		
		#si la table, la colonne et l'id sont passés, on fait l'update
		if($d{table_record} ne '' && $d{col_record} ne '' && $d{id_record} > 0 )
		{
			$stmt = "UPDATE $d{table_record} SET $d{col_record} = '$id_traduction' WHERE id = '$d{id_record}'";
			log_debug($stmt,'','set_traduction');
			execstmt($dbh,$stmt);
		}
	
		return $id_traduction;
	}
}



sub get_traduction
{
	my %d = %{$_[0]};
	
	my $dbh_line = $dbh;
    if($d{dbh} ne '')      {    $dbh_line = $d{dbh};                         } 
$d{debug} = 0;
	if($d{lg} > 0)
	{
		$d{id_language} = $d{lg};
	}
	if(!($d{id_language} > 0 && $d{id_language} <= 10))
	{
		$d{id_language} = get_quoted('lg')
	}
	if(!($d{id_language} > 0 && $d{id_language} <= 10))
	{
		$d{id_language} = 1;
	}
	
	# if( (0 || $dm_cfg{admin_cache_txtcontent} == 1) && $cache_traduction{$d{id}} ne '')
	# {	
		# return $cache_traduction{$d{id}};
	# }
	# els
	if($d{id} > 0)
	{
		my %txt = sql_line({debug=>$d{debug},debug_results=>$d{debug},dbh=>$dbh_line,table=>'txtcontents',select=>"id, lg$d{id_language} as content, lg1",where=>"id='$d{id}'"});
		if($txt{id} > 0)
		{
			if($txt{content} ne '')
			{
				return $txt{content};
			}
			else
			{
				return $txt{lg1};
			}
			
		}
	}
	#cache traductions: à placer au debut de tools si utile
	# if(0 || $dm_cfg{admin_cache_txtcontent} == 1)
	# {
		# $d{debug} = 1;
		
		# my @txts = sql_lines({debug=>$d{debug},debug_results=>$d{debug},dbh=>$dbh,table=>'txtcontents',select=>"id, lg$config{current_language} as content, lg1",where=>""});
		# foreach $txt(@txts)
		# {
			# my %txt = %{$txt};
			# $cache_traduction{$txt{id}} = $txt{content} || $txt{lg1};
		# }
	# }
	# see(\%cache_traduction);
	# print "[$dm_cfg{admin_cache_txtcontent}]";
	# exit;

}

sub clean_log_degug
{
	my $path = $config{directory_path}.'/syslogs/';
	opendir (MYDIR, $path) || die ("cannot LS $path");
	my @files_array = readdir(MYDIR);
	closedir (MYDIR);
	
	
	foreach my $file (@files_array) 
	{
		my $full_name = "$path/$file";
		if($file eq '.' || $file eq '..')
		{
			next;
		}
		
		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat $full_name;
		$size /= 1024;
		
		if($size > 5000)
		{
			unlink($path.'/'.$file);
		}		
	}
}

sub log_debug
{
	my $commande = $_[1];
	my $filename = $_[2] || 'mig_log.log';
	my $date = $_[3] || 'date';
	my $out_file = "../syslogs/$filename.log";
	if($commande eq 'vide')
	{
		open OUTPAGE, ">$out_file";
		print OUTPAGE '';
		close (OUTPAGE);
	}
	
	# use Carp;	
	# my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller();
	# my $stack = Carp::longmess("Stack backtrace :");
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);	
	my $moment =  sprintf("[%04d-%02d-%02d:%02d:%02d:%02d]",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	my $out_log = "$moment\t".$_[0]."\n";
	if($date eq 'no_date')
	{
		$out_log = $_[0];
	}
	if($date eq 'no_date_but_cr')
	{
		$out_log = $_[0]."\n";
	}
	if($date eq 'no_date_not_cr')
	{
		$out_log = $_[0];
	}
	open OUTPAGE, ">>$out_file";
	print OUTPAGE $out_log;
	close (OUTPAGE);
}

sub get_url
{
	log_debug('get_url','','get_url');
	my %d = %{$_[0]};
	if(!($d{id_language} > 0))
	{
		$d{id_language} = 1;
	}
	
	# %migcms_setup = %{$d{migcms_setup}};
	if(!($migcms_setup{id} > 0))
	{
		%migcms_setup = sql_line({debug=>1,table=>'migcms_setup'});		
	}

	log_debug("if(".$migcms_setup{id}." > 0 && ".$migcms_setup{id_default_page}." > 0 && ".$migcms_setup{id_default_page}." == ".$d{id_table}.")",'','get_url');

	############################## !!! ATTENTION !!! #################################################
	# Condition à vérifier car $migcms_setup{id_default_page} == $d{id_table} est parfois sans rapport (j'ai rajouté des conditions pour ce ça marche)
	# Exemple : $d{id_table} peut être un id de data_search_form. Ca n'a pas de sens de le comparer avec l'id de la page par défaut... et si en plus les id 
	# correspondent comme j'ai eu le cas sur Equiwood, ça renvoit une URL vide.
	if($migcms_setup{id} > 0 && $migcms_setup{id_default_page} > 0 && $migcms_setup{id_default_page} == $d{id_table} && $d{id_language} == 1 && $d{nom_table} eq "migcms_page")
	{
		log_debug('url:'.$config{baseurl}.'/','','get_url');
		return '';
	}
	
	# print "[$d{nom_table}][$d{preview}][$d{id_table}][$d{from}]";
	if($d{nom_table} eq 'migcms_pages' && $d{preview} eq 'y' && $d{mailing} ne 'y' && $d{id_table} > 0 && $d{type_page} ne 'private')
	{
		my $u = $config{baseurl}.'/cgi-bin/migcms_view.pl?lg='.$d{id_language}.'&id_page='.$d{id_table}.'&edit='.get_quoted('edit');
		$u =~ s/\/\//\//g;
		# print "[U]$u";
		return $u;
	}
	
	my $cache_url = $migcms_urls{$d{nom_table}.'_'.$d{id_table}.'_'.$d{id_language}};
	if($cache_url ne '')
	{
		# print "[cache_url]$cache_url";
		# log_debug($cache_url);
		return $cache_url;
	}
	$d{debug} = 1;
	$d{debug_results} = 1;
	my %url = sql_line({dbh=>$dbh,debug=>$d{debug},debug_results=>$d{debug_results},table=>'migcms_urls',where=>"nom_table='$d{nom_table}' AND id_table='$d{id_table}' AND id_lg='$d{id_language}'"});
	if(!($url{id} > 0))
	{
		%url = sql_line({dbh=>$dbh,debug=>$d{debug},debug_results=>$d{debug_results},table=>'migcms_urls',where=>"nom_table='$d{nom_table}' AND id_table='$d{id_table}' AND id_lg='2'"});
	}
	
	# print "[url_rewriting]$url{url_rewriting}";
	return $url{url_rewriting};
}


sub get_sql_listbox
{
	my %d = %{$_[0]};
	if($d{col_id} eq '')
	{
		$d{col_id} = 'id';
	}
	
	my $selected_id = $d{selected_id} || $d{selected_value};
	
	my $required = '';
	if($d{required} eq 'y' || $d{required} eq 'required')
	{
		$required = ' required ';
	}
	
	my $select = '<select class=" '.$d{class}.' '.$required.'" '.$required.' id="'.$d{id}.'" name="'.$d{name}.'" title="'.$d{title}.'">';
	if($d{with_blank} eq 'y')
	{
		$veuillez = $sitetxt{veuillez_selectionner};
		if($d{blanktitle} == 1) {
			$veuillez = $d{title};
		}
		$select .= '<option value="">'.$veuillez.'</option>';
	}

	if($d{col_rel} eq '')
	{
		$d{col_rel} = $d{col_id};
	}
	if($d{col_display} eq '')
	{
		$d{col_display} = $d{col_id};
	}
	my @lignes = sql_lines({table=>$d{table},select=>"$d{col_rel} as col_rel, $d{col_id} as col_id, $d{col_display} as col_display",where=>"$d{where}",ordby=>$d{ordby},limit=>"$d{limit}",groupby=>$d{groupby}});
	foreach $ligne (@lignes)
	{
		my %ligne = %{$ligne};
		my $selected = "";
		if($selected_id eq $ligne{col_id})
		{
			$selected = ' selected = "selected" ';
		}
		if($d{translate} == 1)
		{
			$ligne{col_display} = get_traduction({id_language=>$id_language,id=>$ligne{col_display}});
		}
		$select .= '<option '.$selected.' rel="'.$ligne{col_rel}.'" value="'.$ligne{col_id}.'">'.$ligne{col_display}.'</option>';
	}
	$select .= '</select>';	
	
	return $select;
}

sub select_table
{
  my $dbh_dbf        = $_[0];
  my $table          = $_[1];
  my $selector       = $_[2] || '*';
  my $where          = $_[3];
  my $order          = $_[4];
  my $limit          = $_[5];
  my $debug          = $_[6] || 0;

  my %ligne = sql_line({dbh=>$dbh_dbf,table=>$table,select=>$selector,where=>$where,ordby=>$order,limit=>$limit,debug=>$debug,debug_results=>$debug});
  return %ligne;
}

sub get_table
{
  my $dbh_dbf        = $_[0];
  my $table          = $_[1];
  my $selector       = $_[2] || '*';
  my $where          = $_[3];
  my $order          = $_[4];
  my $limit          = $_[5];
  my $debug          = $_[6] || 0;

  my @array = sql_lines({dbh=>$dbh_dbf,table=>$table,select=>$selector,where=>$where,ordby=>$order,limit=>$limit,debug=>$debug,debug_results=>$debug});
  return @array;
}

sub see
{
  print $cgi->header(-expires=>'-1d',-charset => 'utf-8');
  my %hash=%{$_[0]};
  if($_[0] ne "")
  { 
      use Data::Dumper;
	  print Dumper(\%hash);	  
  }
}

sub is_in
{
	 my @a = @{$_[0]};
	 my $id = $_[1];
	 my $k;

	 
	 my $found = -1;
	 
	 for ($k=0; $k<=$#a; $k++) 
	 {
	     if ($a[$k] eq $id) {$found=$k;last;}
	 }
		
	 return $found;
}

sub create_token
{
	my $length_of_randomstring= $_[0];
  my $whatchars= $_[1] || 'aA0';
  my @chars = (); 
  if($whatchars eq 'aA0')
  {
	   @chars=('a'..'z','A'..'Z','0'..'9');
  }
  elsif($whatchars eq 'a0')
  {
	   @chars=('a'..'z','0'..'9');
  }
  elsif($whatchars eq 'a')
  {
	   @chars=('a'..'z');
  }
  elsif($whatchars eq '0')
  {
	   @chars=('0'..'9');
  }
	my $random_string;
	foreach (1..$length_of_randomstring) 
	{
		$random_string.=$chars[rand @chars];
	}
	return $random_string;
}

sub http_redirect
{
	my $url = $_[0];	#url de redirection
	print "<META HTTP-EQUIV=\"Refresh\" CONTENT=\"0; URL=$url\">";
}

sub cgi_redirect
{
    my $url = $_[0];	#url de redirection
    print $cgi->redirect("$url");
    exit;
}


sub is_human_recaptcha 
{
	use JSON::XS; 
	my %d = %{$_[0]};

    my $secret_key = $d{secret_key};
    my $g_recaptcha_response = $d{g_recaptcha_response};

    # On considère que l'utilisateur est un bot
    my $i_am_human = "n";
    # Si on reçoit une valeur de recaptcha et que la secret key n'est pas vide
    if($g_recaptcha_response ne "" && $secret_key ne "")
    {
        # Requête vers Google pour savoir si la valeur est valide
        my $url = "https://www.google.com/recaptcha/api/siteverify?secret=".$secret_key."&response=".$g_recaptcha_response;

        use LWP::UserAgent 6;
        my $ua = LWP::UserAgent->new((ssl_opts => { verify_hostname => 0}));
        my $response = $ua->get($url);

        $content = decode_json ($response->decoded_content);
        %content = %{$content};
        # Si on reçoit true, le captcha est bon
        if($content{success} == 1)
        {
            # L'utilisateur est un humain
            $i_am_human = "y";
        }
        
    }

    return $i_am_human;
}

sub get_alert 
{
    my %d = %{$_[0]};

    my $alert;

    if($d{display} eq "sweet")
    {
        $alert = get_alert_sweetAlert(\%d);
    }
    else
    {
        $alert = get_alert_default(\%d);
    }

    return $alert;
}

sub get_alert_sweetAlert
{
    my %d = %{$_[0]};

    $d{title} =~ s/\"/\\\"/g;
    $d{message} =~ s/\"/\\\"/g;

    my $content=<<"EOH";
<!DOCTYPE html>
<html lang="fr">
<head>

    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
	<meta name="robots" content="noindex, nofollow">
    <meta name="author" content="Bugiweb.com">
    
	<link rel="apple-touch-icon" sizes="57x57" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-57x57.png">
	<link rel="apple-touch-icon" sizes="60x60" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-60x60.png">
	<link rel="apple-touch-icon" sizes="72x72" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-72x72.png">
	<link rel="apple-touch-icon" sizes="76x76" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-76x76.png">
	<link rel="apple-touch-icon" sizes="114x114" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-114x114.png">
	<link rel="apple-touch-icon" sizes="120x120" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-120x120.png">
	<link rel="apple-touch-icon" sizes="144x144" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-144x144.png">
	<link rel="apple-touch-icon" sizes="152x152" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-152x152.png">
	<link rel="apple-touch-icon" sizes="180x180" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-180x180.png">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-32x32.png" sizes="32x32">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-194x194.png" sizes="194x194">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-96x96.png" sizes="96x96">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/android-chrome-192x192.png" sizes="192x192">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-16x16.png" sizes="16x16">
	<link rel="manifest" href="$config{baseurl}/mig_skin/ico/manifest.json">
	<meta name="msapplication-TileColor" content="#ffffff">
	<meta name="msapplication-TileImage" content="$config{baseurl}/mig_skin/ico/mstile-144x144.png">
	<meta name="theme-color" content="#ffffff">
	<meta name="application-name" content="$migcms_setup{site_name}">	

    <title>Alert</title>
    
	<link href="//maxcdn.bootstrapcdn.com/font-awesome/4.1.0/css/font-awesome.min.css" rel="stylesheet">
    <link href="$config{baseurl}/html/css/style.css" rel="stylesheet">
    <link href="$config{baseurl}/html/css/style-responsive.css" rel="stylesheet">
	<link rel="stylesheet" href="$config{baseurl}/mig_skin/css/sweet-alert.css">

    <!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
    <script src="$config{baseurl}/html/js/html5shiv.js"></script>
    <script src="$config{baseurl}/html/js/respond.min.js"></script>
    <![endif]-->
</head>

<body class="login-body">

<!-- Placed js at the end of the document so the pages load faster -->
<script src="$config{baseurl}/html/js/jquery-1.10.2.min.js"></script>
<script src="$config{baseurl}/html/js/bootstrap.min.js"></script>
<script src="$config{baseurl}/html/js/modernizr.min.js"></script>
<script src="$config{baseurl}/mig_skin/js/sweet-alert.min.js"></script>

<script language="javascript">

	jQuery(document).ready(function()
	{
		sweetAlert({
			title :"$d{title}",
			text : "$d{message}",
			type : "$d{type}",
		},
		function(isConfirm)
		{			
			if('$d{goto}' == 'login')
			{
				window.location.href="$config{baseurl}/admin";
			}
			else
			{
				history.go(-1);
			}
		});
		return false;
	});
		  
</script>

</body>
</html>

EOH

    return $content;

}

sub get_alert_default
{

}

#sub get_txt_from_html_body
#{
#	use Encode qw/encode decode/;
#	use HTML::Entities;
	
#	my $body_html = $_[0];

#	$body_html = decode("utf8", $body_html);

#	$body_html = decode_entities($body_html,'<>&');

#	my $body_text = $body_html;

#	$body_text = encode("utf8", $body_text);

#	return $body_text;
#}

sub get_txt_from_html_body
{
	my $body_html = $_[0];
	
	use Encode qw/encode decode/;
	use HTML::Entities;

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

sub minify_html_body
{
	my $body_html = $_[0];
	$body_html =~ s/ISO-8859-1/UTF-8/ig;

	# use HTML::Packer;
	# my $packer = HTML::Packer->init(); 
	# my $minified_body_html = $packer->minify( \$body_html);
	my $minified_body_html = $body_html;
	
	return $minified_body_html;
}

sub clean_url
{
  my $url = $_[0];
  my $allow_slashes = $_[1] || "n";
  
  $url = trim ($url);
  if ($allow_slashes ne "y") { $url =~ s/\//-/g; }
  $url =~ s/\@/a/g;
  $url =~ s/\€/eur/g;
  $url =~ s/\#//g;
  $url =~ s/\.//g;
  $url =~ s/\™//g;
  $url =~ s/\*//g;
  
  $url = lc(clean_filename($url,'n',$allow_slashes));
  
  return $url;

}

sub clean_filename
{
 my $filename = $_[0];
 my $cut = $_[1] || 'y';
 my $allow_slashes = $_[2] || "n";
 
 if ($allow_slashes ne "y") {
     my @filepath = split(/[\/|\\]/,$filename);
     $filename = $filepath[$#filepath]; 
 }
 
 $filename =~ s/\'//g;
 $filename =~ s/\,//g;
 $filename =~ s/\"//g;
 $filename =~ s/\?//g;
 $filename =~ s/\(//g;
 $filename =~ s/\)//g;
 $filename =~ s/\;//g;
 $filename =~ s/\&//g;
 $filename =~ s/\+//g;
 $filename =~ s/\s+/-/g;
 
 $filename = remove_accents_from($filename);

 $filename =~ s/%/-/g;
 if($cut eq 'y')
 {
    $filename = substr($filename,0,75);
 }
 return $filename;
}

sub remove_accents_from
{
	 my $str = $_[0];
	 
	 my %accents = ("¥" => "Y", "µ" => "u", "À" => "A", "Á" => "A", 
	                "Â" => "A", "Ã" => "A", "Ä" => "A", "Å" => "A", 
	                "Æ" => "A", "Ç" => "C", "È" => "E", "É" => "E", 
	                "Ê" => "E", "Ë" => "E", "Ì" => "I", "Í" => "I", 
	                "Î" => "I", "Ï" => "I", "Ð" => "D", "Ñ" => "N", 
	                "Ò" => "O", "Ó" => "O", "Ô" => "O", "Õ" => "O", 
	                "Ö" => "O", "Ø" => "O", "Ù" => "U", "Ú" => "U", 
	                "Û" => "U", "Ü" => "U", "Ý" => "Y", "ß" => "s", 
	                "à" => "a", "á" => "a", "â" => "a", "ã" => "a", 
	                "ä" => "a", "å" => "a", "æ" => "a", "ç" => "c", 
	                "è" => "e", "é" => "e", "ê" => "e", "ë" => "e", 
	                "ì" => "i", "í" => "i", "î" => "i", "ï" => "i", 
	                "ð" => "o", "ñ" => "n", "ò" => "o", "ó" => "o", 
	                "ô" => "o", "õ" => "o", "ö" => "o", "ø" => "o", 
	                "ù" => "u", "ú" => "u", "û" => "u", "ü" => "u", 
	                "ý" => "y", "ÿ" => "y"
				);

	 foreach $char (keys(%accents)) {
	     $str =~ s/$char/$accents{$char}/g;
	 }

	return $str;
}

sub get_file
{
	my $filename = $_[0];	
	my $content = "";		
	open(FILE, $filename) or suicide ("GET_FILE : cannot open $filename");	
	while (<FILE>)		
	{	
	   $content.= $_;
	}
	close(FILE);	
	return $content	
}
sub reset_file
{
 my $filename = $_[0] || "";
 
 open (FILE,">$filename") || die "cannot create $filename : $!";
 close FILE;
}

sub write_file
{
 my $filename = $_[0] || "";
 my $content = $_[1] || "";
 
 open (FILE,">>$filename") || suicide("cannot open $filename : $!");
 print FILE $content;
 close FILE;
}

sub suicide
{
	my $msg = $_[0]; 
use Carp;	
my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller();
my $stack = Carp::longmess("Stack backtrace :");
$stack =~ s/\r*\n/<br>/g;		
	print <<"EOM";
<!DOCTYPE html>
<html lang="fr,en" id="mig-error-html">
<head>
	<meta charset="utf-8">
	<title>Error</title>
	<meta name="robots" content="none">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<meta name="viewport" content="width=device-width, initial-scale=1">

<style type="text/css">
* {
margin : 0px;
padding : 0px;
}

html#mig-error-html {
min-height : 100%;
height : auto;
height : 100%;
}

body#mig-error {
height : 100%;
font-family : arial;
color : black;
background : url('../mig_skin/img/error_help.jpg') no-repeat;
background-size: 100% 100%;
}

div#mig-error-page {
position : relative;
padding : 20px;
}

div#mig-error-page-content {
width : auto;
max-width : 570px;
background : white;
background : rgba(255,255,255,0.8);
border-radius : 15px;
padding : 20px;
}

div#mig-error-page-content p {
font-size : 8pt;
padding : 0px 0px 12px 0px;
margin : 0px 0px 12px 0px;
color : #272727;
background : url('../mig_skin/img/error_help_separator.png') no-repeat bottom left;
font-weight:bold;
}

div#mig-error-page-content p#mig-error-en {
background : none;
margin : 0px;
}

div#mig-error-page-content p a {
color :#d7031c;
}

div#mig-error-page-content p a:hover {
text-decoration : none;
}

div#mig-error-msg {
width : auto;
max-width : 570px;
background : white;
background : rgba(255,255,255,0.8);
border-radius : 15px;
padding : 20px;
margin-top : 20px;
display : none;
}

#mig-error-page-content h1 {
font-size : 13pt;
}

#mig-error-page-content hr {
border : 0px;
border-top : 1px solid black;
margin : 10px 0px;
}
</style>
		
</head>

<body id="mig-error">

	<div id="mig-error-page">
	
		<div id="mig-error-page-content">
		
			<h1>Le système a détecté un problème technique, et ne peut continuer.</h1>
		
			<p id="mig-error-fr">Un problème technique est survenu, veuillez nous en excuser.<br />Nous vous invitons à réessayer un peu plus tard.<br />Si le problème persiste, contactez le <a HREF="mailto:support\@bugiweb.com">support technique</a>.<br />Merci !</p>
		
			<h1>The system has detected a technical problem, and cannot continue.</h1>
		
			<p id="mig-error-en">A technical problem occurred, we are sorry for the inconvenience.<br />Please try again later.<br />If the problem occurs again, please contact the <a HREF="mailto:support\@bugiweb.com">technical support</a>.<br />Thank you !</p>
		
		</div>
EOM

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);	

	my $moment =  sprintf("[%04d-%02d-%02d:%02d:%02d:%02d]",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	my $errormsg = <<"EOT";
		<div id="mig-error-msg">
			<strong>Site : </strong>$config{baseurl}<br />
			<strong>Moment : </strong>$moment<br />
			<hr />
			$msg
			<hr />
			$package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask
			<hr />
			$stack
		</div>
		
	</div>
</body>
</html>
EOT
	my $out_file = "../syslogs/mig_error.log";
	my $out_log = "$moment\n$msg\n$package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask\n$stack\n";

	open OUTPAGE, ">>$out_file";
	print OUTPAGE $out_log;
	close (OUTPAGE);
	print "$errormsg";
	exit();
}

sub to_ddmmyyyy
{
	my $datetime = $_[0] || ""; 
	my $notime = $_[1] || ""; 
  my ($date,$time) = split(/ /,$datetime);
  my ($yyyy,$mm,$dd) = split (/-/,$date); 
  my ($h,$min,$sec) = split (/:/,$time); 
  my $result="";
  
  if ($notime eq "withtime") 
  {
      $result = "$dd/$mm/$yyyy, ".$h."h".$min;
  }
  elsif ($notime eq "withtimeandbr") 
  {
      $result = "$dd/$mm/$yyyy, <br />".$h."h".$min;
  }
  else
  {
	   $result = "$dd/$mm/$yyyy";	
  }
  return $result;	
}

sub get_describe
{
    my $dbh_dbf     = $_[0];
    my $table_name=$_[1];
    my @table =();
  	my $stmt = "DESCRIBE $table_name";
  	if($debug)
  	{
        see();
   	    print "<br /><br />".$stmt."<br /><br />";
   	}
  	my $cursor = $dbh_dbf->prepare($stmt);
  	my $rc = $cursor->execute;
  	if (!defined $rc) 
  	{
  		  see();
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


#quote*******************************************************************************************************************
sub quote
{
	my $dirty = $_[0];
	my $clean = $dirty;
	$clean =~ s/\\//g;
	$clean =~ s/\\//g;
	$clean =~ s/\\//g;
	$clean =~ s/\'/\\\'/g;
	return $clean;
}

#quoteh*******************************************************************************************************************
sub quoteh
{
	my %hash_r = %{$_[0]};
	foreach $key (keys %hash_r)
	{
		$hash_r{$key} = quote($hash_r{$key});
		
	}
	return \%hash_r;
}

sub update_txtcontent
{
	my %d = %{$_[0]};
	
	#mise à jour du txtcontent dans la langue indiquée
	
	my %update_txtcontent = 
	(
		id => $d{id},
	);
	
	#créer le txtcontent s'il n'existe pas
	if(!($update_txtcontent{id} > 0))
	{
		$update_txtcontent{id} = inserth_db($dbh,'txtcontents',\%update_txtcontent);		
	}
	
	#ajoute les traductions passées
	foreach my $id_lg (1 .. 10)
	{
		if($d{'lg'.$id_lg} ne '')
		{
			$update_txtcontent{'lg'.$id_lg} = $d{'lg'.$id_lg};
		}
	}
	%update_txtcontent = %{quoteh(\%update_txtcontent)};
	
	updateh_db($dbh,"txtcontents",\%update_txtcontent,'id',$update_txtcontent{id});
	
	return $update_txtcontent{id};
}

sub get_template
{
    my %d = %{$_[0]};
	if(!($d{id}>0) && $_[1] > 0)
	{
		$d{id} = $_[1]; #old syntax
	}
	# log_debug('get_template','','tools');
	# my %template = sql_line({debug=>$d{debug},debug_results=>$d{debug_results},table=>'templates',where=>"id='$d{id}'"});
	return $cache_templates_id{$d{id}};
}

sub thumbnailize
{
	use GD;	
	GD::Image->trueColor(1);	

	my $filename = $_[0];	
	my $upload_path = $_[1];	
	my $th_width = $_[2];	
	my $th_height = $_[3];	
	my $th_suffix = $_[4] || "_thumb";
	if ($th_suffix eq " ") {$th_suffix = "";}
	my $other_dir = $_[5] || "";
	my $initial_th_height=$th_height;
	my $fullname = $upload_path."/".$filename;	

	my @splitted = split(/\./,$filename);	
	my $ext = pop @splitted;	
	
	my $thumb_url = join(".",@splitted)."$th_suffix.".$ext;	
    if ($other_dir ne "") {$upload_path=$other_dir;}
	my $thumb_filename = $upload_path."/".$thumb_url;	#
	
	my $full = GD::Image->new($fullname) || log_debug("GD cannot open $fullname : [$!]");	
	my ($fu_width,$fu_height) = $full->getBounds();		
	my ($transparent) = $full->transparent();		

	my $prop = 1;

	if ($th_width > $fu_width) {$th_width = $fu_width;} 
	if ($th_height > $fu_height) {$th_height = $fu_height;}	

	if ($fu_width >= $th_width && $fu_height >= $th_height) 
	{
	
		if($config{pic_resize_on_width} eq 'y') {
		
            $prop = $fu_width / $th_width;
            $th_height = int ($fu_height / $prop); #hauteur d'image automatique.
				
		}
		else {
		
			if ($fu_width > $fu_height) 
			{
				$prop = $fu_width / $th_width;
				$th_height = int ($fu_height / $prop);	
				if($th_height > $initial_th_height)
				{
					 my $prop2=$initial_th_height/$th_height;
					 $th_width*=$prop2;
					 $th_height=$initial_th_height;
				}	
			} 
			else 
			{
				$prop = $fu_height / $th_height;
				$th_width = int ($fu_width / $prop);
			}
		
		}
	}
	
	my $thumb = GD::Image->new($th_width,$th_height,1);
	

 	$thumb->copyResampled($full,0,0,0,0,$th_width,$th_height,$fu_width,$fu_height);	#Copie de l'image



	if($config{watermark} ne '' && $config{watermark_width} > 0 && $config{watermark_height} > 0) {

        my $ratio = $th_width/$config{watermark_width};
        if($ratio > 1){
            $ratio = 1;
        }
		my $watermark = GD::Image->newFromPng($config{directory_path} . $config{watermark});
		$thumb->copyResized($watermark, # Src Image;
			($th_width / 2 - ($config{watermark_width} * $ratio / 2)), ($th_height / 2 - ($config{watermark_height} * $ratio / 2)), # $dstX,$dstY,
			0, 0, # $srcX,$srcY,
			$config{watermark_width} * $ratio, $config{watermark_height} * $ratio, # $destW,$destH,
			$config{watermark_width}, $config{watermark_height});                   # $srcW,$srcH,

	}

	my $data;
	$thumb->saveAlpha(1);
	$thumb->alphaBlending(0);
	if ($ext =~ /[Jj][Pp][Ee]*[Gg]/) #Test de l'extension
	{
	    $data = $thumb->jpeg(100); 
	} 
	elsif ($ext =~ /[Pp][Nn][Gg]/) 
	{

	    $data = $thumb->png; 
	}
	open (THUMB,">$thumb_filename");	#Ouverture du fichier
	binmode THUMB;	#Mode binaire
	print THUMB $data;	#Enregistrement du fichier
	close THUMB;	#Fermeture


	return ($thumb_url,$th_width,$th_height,$fu_width,$fu_height);	#Retourne le nouveau nom du fichier et les informations sur la taille
}

sub get_script
{
	 my $url = $_[0];

	 my @t1 = split(/\?/,$url);
	 my @t2 = split (/\//,$t1[0]);
	 
	 return $t2[$#t2];
}

sub get_next_ordby
{
    my %params = @_;
    
    my $where = $params{where} || 1;
    my %next = select_table($params{dbh},$params{table},'ordby',$where.' order by ordby desc');
    
    return $next{ordby} + 1;
}

sub upload_file;
*upload_file = \&upload_image;	

sub upload_image
{
	my $in_filename = $_[0] || "";	
	my $upload_path = $_[1];		
	my ($size, $buff, $bytes_read, $file_url);	

	if ($in_filename eq "" || $in_filename =~ /(php|js|pl|asp|cgi|swf)$/) { return ""; }	#Si pas de fichier alors retour de rien
	
	my @splitted = split(/\./,$in_filename);	
	my $ext = lc($splitted[$#splitted]);	
	my $filename = $splitted[0];
	$filename = clean_filename($filename);
  
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	
	$year+=1900;
	$mon++;
	
	my @chars = ( "A" .. "Z", "a" .. "z");
	$file_url = "$filename\_$year$mon$mday$hour$min$sec".".".$ext;
	my $out_filename = $upload_path."/".$file_url;

	# upload the file contained in the CGI buffer
	if (!open(WFD,">$out_filename"))
	{
		suicide("cannot create file $out_filename $!");	
	}

	while ($bytes_read = read($in_filename,$buff,2096))	
	{
	    $size += $bytes_read;
	    binmode WFD;
	    print WFD $buff;
	}
	
	close(WFD);

	return ($file_url,$size);
}

sub compute_sql_date
{
	my $raw_date = $_[0];
	
	#03-05-2016
	#2016-05-03
	#03/05/2016
	my ($dd,$mm,$yyyy) = split (/\//,$raw_date);
	if($dd > 0 && $mm > 0 && $yyyy > 0)
	{
		if($yyyy < 100)
		{
			$yyyy += 2000;
		}
		return $yyyy.'-'.$mm.'-'.$dd;
	}
	my ($dd,$mm,$yyyy) = split (/-/,$raw_date);
	if($dd > 0 && $mm > 0 && $yyyy > 0)
	{
		my $sav_yyyy = $yyyy;
		my $sav_dd = $dd;
		if($dd > 31 && $yyyy <= 31)
		{
			$dd = $sav_yyyy;
			$yyyy = $sav_dd;
		}
		return $yyyy.'-'.$mm.'-'.$dd;
	}
	return '0000-00-00';
}

sub add_denomination
{
	my $denomination = $_[0];
	my $elt = $_[1];
	
	if($denomination ne '' && $elt ne '')
	{
		$denomination = $denomination.' ';
	}
	$denomination .= $elt;
	
	return $denomination;
}

sub display_price
{
  my $value = $_[0];

  my $devise = "€";

  if($config{devise} ne "")
  {
    $devise = $config{devise};
  }

  $value = round($value*100)/100;
  $value = sprintf("%.2f",$value);
  return $value." $devise";
}

sub get_hash_from_config
{
 my $dbh_dbf = $_[0];
 my $param = $_[1];
$hash = $config{$param};

$hash =~ s/<APOSTROPHE>/\\\'/g;

my %hash = eval ("%hash = ($hash)");  die "$@ ($param)" if $@;
 return %hash;
}
sub get_hash_from_fields
{
    my @fields_web = @{$_[0]};
    my @fields_sql = @{$_[1]};
    my %d = %{$_[2]};
    
    my %new_hash = ();
    my $counter = 0;
    foreach $field (@fields_web)
    {
        $new_hash{$fields_sql[$counter]} = get_quoted($field) || $d{$field} || "";
        $counter++;
    }
    return \%new_hash;
}
sub build_form
{
	my %d = %{$_[0]};

	my @champs = @{$d{fields}};
	my $lg = $d{lg};

	my $form = '';

	
	my %optionnel_txt = 
	(
		''         => ucfirst($sitetxt{eshop_optionnel}),
		'required' => '',
	);
	
	foreach my $champ (@champs)
	{
		my %champ = %{$champ};

		
		if($champ{value} eq "")
		{
			$champ{value} = get_quoted($champ{name}) || $champ{valeurs}{$champ{name}};
			$champ{value} =~ s/\\//g;
		}

		if($champ{do_not_add} eq "y")
		{
			next;
		}

		#valeurs par défaut--------------------------------------------
		if($champ{type} eq '')
		{
			$champ{type} = 'text';
		}
		#construction formulaire-------------------------------------------------------------
    if($champ{type} eq 'text' || $champ{type} eq 'email' || $champ{type} eq 'password')
    {
			$form .=<< "EOH";
				<div class="form-group form-group-$champ{name}">
						 <label class="control-label col-sm-4" for="$champs[$i]">$champ{label} </label>
							   <div class="col-sm-8">
								<input type="$champ{type}" name="$champ{name}" $champ{required} value="$champ{value}" class="$champ{class} $champ{required} form-control" /> 
								<span class="help-block">
									$optionnel_txt{$champ{required}}
									<em>$champ{hint}</em>
									$champ{suppl}
								</span>
						 </div>
				</div>
EOH
			
    }
		elsif($champ{type} eq 'delivery_google_search')
    {
			$form .=<< "EOH";
				<div class="form-group form-group-$champ{name}">
						 <label class="control-label col-sm-4" for="$champs[$i]"> </label>
							   <div class="col-sm-8">
									<small>Retrouvez votre adresse sur Google map (Facultatif)</small>
									<input type="text" class="input-xlarge  form-control" value="" name="delivery_google_autocomplete" id="delivery_google_autocomplete" />
									<span class="help-block">
								</span>
						 </div>
				</div>
EOH
			
    }
		elsif($champ{type} eq 'billing_google_search')
    {
			$form .=<< "EOH";
				<div class="form-group form-group-$champ{name}">
						 <label class="control-label col-sm-4" for="$champs[$i]"> </label>
							   <div class="col-sm-8">
									<small>Retrouvez votre adresse sur Google map (Facultatif)</small>
									<input type="text" class="input-xlarge  form-control" value=""  name="billing_google_autocomplete" id="billing_google_autocomplete" />
									<span class="help-block">
								</span>
						 </div>
				</div>
EOH
			
    }
    elsif($champ{type} eq 'countries_list')
    {
			#liste des pays (FR, NL, ANGLAIS sinon)
			my $col = 'en';
			if($lg == 1)
			{
			$col = "fr";
			}
			elsif($lg == 3)
			{
			$col = "nl";
			}
		
			my $country = $champ{value};
			if(!($country > 0))
			{
				$country = $setup{cart_default_id_country};
			}
		
      my $listbox_countries = sql_listbox(
       {
          dbh       =>  $dbh,
          name      => $champ{name},
          select    => "c.id,$col",
          table     => 'shop_delcost_countries dc, countries c',
          where     => 'dc.isocode=c.iso',
          ordby     => $col,
          show_empty=> 'y',
          empty_txt =>  $sitetxt{eshop_veuillez},
          value     => 'id',
          current_value     => $country,
          display    => $col,
          required => 'required',
          id       => '',
          class    => 'input-xlarge required form-control',
          debug    => 0,
       }
      );
		
			$form .=<< "EOH";
				<div class="form-group form-group-$champ{name}">
					<label class="control-label col-sm-4">$champ{label}  </label>
					<div class="col-sm-8">
						$listbox_countries
					</div>
				</div>
EOH
			
    }
    elsif($champ{type} eq "checkbox")
    {
    	$form .=<< "EOH";
				<div class="form-group form-group-$champ{name}">
	        <div class="col-sm-4"></div>
					<div class="col-sm-8">
						<label class="checkbox">
							<input type="checkbox" value="$champ{value}" $champ{required} name="$champ{name}" />
							$champ{label} 
						</label>
					</div>
	      </div>
EOH
    }
    $i++;
	}

	return $form;
}

sub sql_listbox
{
    my %d = %{$_[0]};

    my $empty_option=<<"EOH";
      <option value="">$d{empty_txt}</option>
EOH
    if($d{show_empty} ne 'y')
    {
        $empty_option="";
    }
    
    if($d{table} ne "" && $d{value} ne "" && $d{display} ne "" && $d{name} ne "")
    {
		 my $readonly = "";
		 if($d{readonly} eq "y") {
			$readonly = 'readonly="readonly"';
		 }
	
          my $listbox=<<"EOH";
              <select name="$d{name}" $d{required} id="$d{id}" class="$d{class}" $readonly>
                  $empty_option             
EOH
         
          my @records=get_table($d{dbh},$d{table},$d{select},$d{where},$d{ordby},"","",$d{debug});
          
          foreach my $rec (@records)
          {
              my $selected="";
              if($d{current_value} eq $rec->{$d{value}})
              {
                  $selected=<<"EOH";
                   selected = "selected"                
EOH
              }
              if($d{translate} eq 'y')
              {
                  ($rec->{$d{display}},$dum) = get_textcontent($dbh,$rec->{$d{display}},$d{lg});
              }
              $listbox.=<<"EOH";
                  <option value="$rec->{$d{value}}" $selected>
                    $rec->{$d{display}}
                  </option>
EOH
          }    
          
          $listbox.=<<"EOH";
              </select>       
EOH
          return $listbox;
          exit;
    }
    else
    {
        return "missing mandatory data: [table:$d{table}][value:$d{value}][display:$d{display}][name:$d{name}]";
    }  
}

sub split_datetime
{
    my $date_time=$_[0];
    my ($date1,$time1) = split(/ /,$date_time);
    my ($year1,$month1,$day1) = split(/-/,$date1);
    return ($day1,$month1,$year1);
}

sub split_date
{
    my $date_time=$_[0];
    my ($date1,$time1) = split(/ /,$date_time);
    my ($year1,$month1,$day1) = split(/\-/,$date1);
    return ($day1,$month1,$year1);
}

sub split_time
{
    my $date_time=$_[0];
    my ($date1,$time1) = split(/ /,$date_time);
    my ($heures,$minutes,$secondes) = split(/\:/,$time1);
    return ($heures,$minutes,$secondes);
}

sub make_spaces
{
 my $thelevel = $_[0]*3;
 my $char = $_[1];
 my $str = "";
 my $i_space = 0;

 while ($i_space < $thelevel)
 {
	if($char eq 'spaces')
	{
		$str .="&nbsp;";
	}
	elsif($char ne '')
	{
		$str .="$char";
	}
	else
	{
	$str .="-";
	}
	$i_space++;
 }  

return $str;
}

#==============================================================================================================================================
# PDF_TEXT
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# print text in the given PDF handle
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : PDF handle
#  1 : text
#  2 : font
#  3 : font size
#  4 : x position (0,0 is bottom left) 
#  5 : y position (0,0 is bottom left) 
#  6 : color
#  7 : align (0=left,1=center,2=right)
# OUTPUT PARAMETERS
#  none
#==============================================================================================================================================
sub pdf_text
{
 my $pdf_h = $_[0];
 my $txt = $_[1];
 
 
 
 $txt = decode("utf8",$txt);
 
 my $font = $_[2];
 my $fontsize = $_[3];
 my $x = $_[4];
 my $y = $_[5];
 my $color = $_[6];
 my $align = $_[7];
 
 if ($align) { 
     my $w = $pdf_h->getFontWidth($txt,$font,$fontsize);
     if ($align == 1) {
         $decay = int ($w/2);
     } elsif ($align == 2) {
         $decay = $w;
     }
  $x -= $decay;
 } 

 $pdf_h->drawText($txt,$font,$fontsize,$x,$y,$color);
 
}

sub get_email_communication
{
	my %d = %{$_[0]};
	# use setup;
	
	# $d{body} =~ s/\r*\n/\<br\/\>/g;
	
	my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
	
	my %balises = %{$d{balises}};
	
	
	my %logo_facture = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='migcms_setup' and token='$migcms_setup{id}'",limit=>'2,1',ordby=>'ordby'});
	$logo_facture{file_dir} =~ s/\.\.\///g;
	my $url_logo_facture = $config{fullurl}.'/'.$logo_facture{file_dir}.'/'.$logo_facture{full}.$logo_facture{ext};
	if($logo_facture{full} eq '')
	{
		%logo_facture = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='migcms_setup' and token='$migcms_setup{id}'",limit=>'0,1',ordby=>'ordby'});
		$logo_facture{file_dir} =~ s/\.\.\///g;
		$url_logo_facture = $config{fullurl}.'/'.$logo_facture{file_dir}.'/'.$logo_facture{full}.$logo_facture{ext};
	}
	
	my $img = "<img src=\"$url_logo_facture\" alt=\"\">";
	if($logo_facture{full} eq '')
	{
		$img = "$balises{company}"
	}
	
	my $banner = <<"EOH";
	<a href="$balises{web}">$img</a>
EOH
								
	
	my $email_communication = <<"EOH";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD XHTML 1.0 Transitional //EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	<title>Facture PRO FORMA N°14016394</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
</head>
<body itemscope itemtype="http://schema.org/Order" bgcolor="#ffffff" style="font-family:arial,sans-serif;color:#292929;font-size:14px;line-height:20px;background:#e5e5e5;-webkit-text-size-adjust:none;">

<style type="text/css">
* {
padding : 0px;
margin : 0px;
}

body {
font-family : arial,sans-serif;
color : #292929;
font-size : 14px;
line-height : 20px;
background : #e5e5e5;
-webkit-text-size-adjust : none;
}

a {
border : 0px;
color : #1780B8;
}

a:hover {
color : #1780B8;
}

img {
border : 0px;
}

a img {
border  :0px;
}

.td25pc {
padding : 5px;
}

.td25pc img {
max-width : 100%;
height : auto;
}

@media only screen and (max-width: 600px) { 

  *[class].table800, *[class].td800, *[class].img800, *[class].pub { width:100% !important; height:auto; }
  *[class].td45 { width:5% !important; }
  *[class].td710 { width:90% !important; }
  *[class].table710 { width:100% !important; height:auto; }
  *[class].tdleftcontent { width : 100% !important; display: table-header-group !important; }
  *[class].td40 { width : 100% !important; display: table-header-group !important; }
  *[class].tdrightcontent { width : 100% !important; display: table-header-group !important; }
  *[class].fancybox { width : 100%; height : auto; }
  *[class].table100pc { width:100% !important; height:auto; }
  *[class].td25pc { width : 100% !important; display: table-header-group !important; }
  *[class].menulink { display : block !important; }
  *[class].maintitle { font-size:25px !important; line-height:30px !important; margin:0px; }
  *[class].linkcategory { display : none !important; }
  *[class].hidden-sm  { display : none !important; }
} 

</style>

<table width="100%" border="0" cellpadding="0" cellspacing="0"><tr><td align="center">
	<table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800" bgcolor="white">
		<tr>
			<td width="800" align="center" class="td800">

				

				<table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
					<tr>
						<td width="45" align="center" class="td45"></td>
						<td width="710" align="left" class="td710">

							<table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
								<tr>
									<td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
								</tr>
								<tr>
									<td align="left" class="tdleftcontent" valign="top">
										---banner---
									</td>
									<td width="40" align="center" class="td40" valign="top">&nbsp;</td>
									<td align="right" class="tdrightcontent" valign="middle">
									</td>
								</tr>
								<tr>
									<td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
								</tr>
							</table>

							

						
							
							

							

							
---body---
						
						

					


									</td>
								</tr>
                <tr>
                  <td class="td40" valign="top">&nbsp;</td>
                </tr>
                <tr>
                  <td class="tdcentercontent" valign="top" align="right">
                    
                  </td>
                </tr>
								<tr>
									<td class="td40" valign="top">&nbsp;</td>
								</tr>
								
								<tr>
									<td class="td40" valign="top">&nbsp;</td>
								</tr>
							</table>
							
						</td>
						<td width="45" align="center" class="td45"></td>
					</tr>
				</table>
				<table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
					<tr>
						<td width="800" height="32" align="left" colspan="3">&nbsp;</td>
					</tr>
				</table>

				<table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800" bgcolor="#333333">
					<tr>
						<td width="45" align="center" class="td45"></td>
						<td width="710" height="52" align="center" class="td710">
							<span style="color:#dadada;">
							
							---company--- | 
										
										<span>---address--- ---number--- à ---zip--- ---city---, ---country---<br />
										Tél: <a href="tel:---phone---"><font color="#ffffff">---phone---</font></a> | M: <a href="mailto:---email_1---"><font color="#ffffff">---email_1---</font></a> 
						
							</span>
						</td>
						<td width="45" align="center" class="td45"></td>
					</tr>
				</table>
			</td>
		</tr>	
	</table>
          
</td></tr></table>
</body>
</html>
EOH

	my %alt_email_communication = sql_line({debug=>0,debug_results=>0,table=>'migcms_textes_emails',where=>"table_name='canevas email'"});
	
	my $alt_html = get_traduction({debug=>0,id=>$alt_email_communication{id_textid_raw_texte},id_language=>$config{current_language}});
	if($alt_html ne '')
	{
		$email_communication = $alt_html;
	}
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	
	$year+=1900;
	$mon++;
	
	$email_communication =~ s/\-\-\-company\-\-\-/$balises{company}/g;
	$email_communication =~ s/\-\-\-address\-\-\-/$balises{address}/g;
	$email_communication =~ s/\-\-\-number\-\-\-/$balises{number}/g;
	$email_communication =~ s/\-\-\-zip\-\-\-/$balises{zip}/g;
	$email_communication =~ s/\-\-\-city\-\-\-/$balises{city}/g;
	$email_communication =~ s/\-\-\-country\-\-\-/$balises{country}/g;
	$email_communication =~ s/\-\-\-phone\-\-\-/$balises{phone}/g;
	$email_communication =~ s/\-\-\-email_1\-\-\-/$balises{email_1}/g;
	$email_communication =~ s/\-\-\-body\-\-\-/$d{body}/g;
	$email_communication =~ s/\-\-\-banner\-\-\-/$banner/g;
	$email_communication =~ s/\-\-\-siteweb\-\-\-/$balises{siteweb}/g;
	$email_communication =~ s/\-\-\-iban\-\-\-/$balises{iban}/g;
	$email_communication =~ s/\-\-\-bic\-\-\-/$balises{bic}/g;
	$email_communication =~ s/\-\-\-rpm\-\-\-/$balises{rpm}/g;
	$email_communication =~ s/\-\-\-division\-\-\-/$balises{division}/g;
	$email_communication =~ s/\-\-\-tva\-\-\-/$balises{tva}/g;
	$email_communication =~ s/\-\-\-year\-\-\-/$year/g;
	$email_communication =~ s/\-\-\-month\-\-\-/$mon/g;
	$email_communication =~ s/\-\-\-day\-\-\-/$mday/g;
	
	
	
	
	return $email_communication;
}


sub send_mail_commercial
{
	my %d = %{$_[0]};
	
	#definir expéditeur,destinataire,objet,body
	my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
	
	my $from_name = get_traduction({id=>$migcms_setup{id_textid_balise_email_1_title},lg=>$config{current_language}});
	my $from_email = get_traduction({id=>$migcms_setup{id_textid_balise_email_1},lg=>$config{current_language}});
	my $from = "$from_name <$from_email>";
	
	my $to_name = "$d{member}{delivery_firstname} $d{member}{delivery_lastname}";
	my $to_email = $d{member}{email};
	if($to_email eq '')
	{
		$to_email = $d{member}{delivery_email};
	}
	my $to = "$to_name <$to_email>";
	
	my $object = $d{object};
	my $body = $d{body};

	if($config{mode_developpement} eq "y")
	{
		$to = 'dev@bugiweb.com';
	}
	
	
	if(!($from_email ne '' && ($to_email ne '' || $d{mailing} eq 'y') && $object ne '' && $body ne ''))
	{
		see();
		print 'erreur données incomplètes'."!($from_email ne '' && $to ne '' && $object ne '' && $body ne '')";
		use Data::Dumper;
		log_debug('erreur données incomplètes'."!($from_email ne '' && $to ne '' && $object ne '' && $body ne '')",'','send_mail_commercial');
		log_debug(Dumper(\%d),'','send_mail_commercial');
		exit;
	}
	if($d{mailing} ne 'y')
	{
		$d{mailing} = 'n';
	}
	
	#appliquer eventuel template
	if($d{id_template} > 0)
	{
		$body = migcrender::render_page({id_tpl_page=>$d{id_template},full_url=>1,mailing=>$d{mailing},debug=>0,content=>$body,lg=>$config{current_language},preview=>'n',edit=>'n'});
	}
	
	if($d{mailing} ne 'y')
	{
		#soit envoi direct
		send_mail($from,'debug@bugiweb.com','COPIE BUGIWEB:'.$object,$body,"html");

		send_mail($from,$to,$object,$body,"html");
				log_debug('erreur données OK'."($from_email ne '' && $to ne '' && $object ne '' && $body ne '')",'','send_mail_commercial');

	}
	else
	{
		if($d{tags} eq '')
		{
			see();
			print 'erreur données incomplètes'."tags: $d{tags}";
			log_debug('erreur données incomplètes'."tags: $d{tags}",'','send_mail_commercial');
			exit;
		}
		
		#soit envoi par mailing
		my %new_sending = (
		'mailing_object'=>$object,
		'mailing_name'=>$object,
		'mailing_content'=>$body,
		'mailing_from'=>$from_name,
		'mailing_from_email'=>$from_email,
		'tags'=>$d{tags},
		'mailing_headers'=>"y",
		'visible'=>'y',
		'status'=>'new',
		'id_migcms_page'=>'1',
		'mail_system'=>'1',
		'ext_id'=>$d{ext_id},
        );
		%new_sending = %{quoteh(\%new_sending)};
		my $id_sending = inserth_db($dbh,'mailing_sendings',\%new_sending);
        log_debug("Sending $id_sending créé pour $object. tags: $d{tags} From: $from_name Email: $from_email ext_id: $d{ext_id}",'','send_mail_commercial');

    }
}

sub get_migcms_sys
{
	my %d = %{$_[0]};	
	
	my %sys = sql_line({debug=>0,debug_results=>0,select=>'id',table=>'migcms_sys',where=>"nom_table='$d{nom_table}' AND id_table='$d{id_table}'"});
	if($sys{id} > 0)
	{
		return \%sys;
	}
	elsif($d{nom_table} ne '' && $d{id_table} > 0)
	{
		#créer le SYS manquant
		my %new_sys =
		(
			moment => 'NOW()',
			nom_table => $d{nom_table},		
			id_table => $d{id_table},		
			id_user => $user{id},
		);
		$new_sys{id} = inserth_db($dbh,'migcms_sys',\%new_sys);
		return \%new_sys;
	}
}

sub get_document_filename
{
	my %d = %{$_[0]};
	my $document_name = '';
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year+=1900;
	$mon++;
	# Si document: AAAA_SYSidsys_BBBidrecord
	# Si listing: AAAA_BBB_date
	# AAAA = numéro de licence
	# BBB = prefixe
	my $id_site = '';

	if($d{prefixe} eq '')
	{
		my %script = read_table($dbh,"scripts",get_quoted('sel'));
		$d{prefixe} = sprintf("%.03d",$script{id});
	}

	if($config{handmade_id_site_table} ne '' && $config{handmade_id_site_col} ne '')
	{
		my %id_site_rec = sql_line({debug=>0,debug_results=>0,select=>"$config{handmade_id_site_col} as id_site",table=>$config{handmade_id_site_table}});
		$id_site = $id_site_rec{id_site};
	}
	if($id_site ne '')
	{
		$document_name .= 'LCS';
		$document_name .= sprintf("%.010d",$id_site);
	} 
	if($d{type} eq 'document' && $d{sys}{id} > 0)
	{
		if($document_name ne '')
		{
			$document_name .= '_';
		}
		$document_name .= 'SYS';
		$document_name .= sprintf("%.010d",$d{sys}{id});

		if($d{sequence} eq '')
		{
			$d{sequence} = '000';
		}

	}
	elsif($d{type} eq 'listing')
	{
	}

	if($d{barcode} != 0)
	{
		return $document_name;
	}

# log_debug('pre'.$d{prefixe});

	if($d{prefixe} ne '')
	{
		if($document_name ne '')
		{
			$document_name .= '_';
		}
		$document_name .= uc($d{prefixe});
	}
	if($d{type} eq 'document')
	{
		$document_name .= sprintf("%.07d",$d{id});
	}
	if($d{sequence} ne '')
	{
		$document_name .= '_';
		$document_name .= $d{sequence};
	}
	if($d{date} != 0)
	{
		$document_name .= '_';
		$document_name .= $year.sprintf("%.02d",$mon).sprintf("%.02d",$mday).sprintf("%.02d",$hour).sprintf("%.02d",$min).sprintf("%.02d",$sec);
	}
	# log_debug('dn'.$document_name);
	return $document_name;
}


sub fill_sys
{
		log_debug('fill_sys','','new_sys');

		if($config{use_sys} ne 'y')
		{
				return "";
		}
		else
		{
		    my $current_db_name = $config{db_name};
				my $remove = 'DBI:mysql:';
				$current_db_name =~ s/$remove//g;
				
				my @list_of_tables_site = get_list_of_tables($current_db_name,$dbh);    
				foreach my $table (@list_of_tables_site)
				{
						if($table eq 'migcms_sys')
						{
							next;
						}
						my @records = sql_lines({table=>$table,where=>"id NOT IN (select id_table from migcms_sys where nom_table='$table')"});
						foreach $record (@records)
						{
								my %record = %{$record};
								
								my %new_migcms_sys = 
								(
									'nom_table'=>$table,
									'id_table'=>$record{id},
									'moment'=>'NOW()',
								);
								%new_migcms_sys = %{quoteh(\%new_migcms_sys)};
								my $id_sys = inserth_db($dbh,'migcms_sys',\%new_migcms_sys);
						}
						fill_creation_date({table=>$table});
						fill_creation_user({table=>$table});
				}
				
				my @records = sql_lines({table=>'migcms_sys',where=>"token = ''"});
				foreach $record(@records)
				{
					my %record = %{$record};
					my $new_token = create_token(50);
					execstmt($dbh,"UPDATE migcms_sys SET token = '$new_token' where id = '$record{id}' AND token = '' ");	
				}
		}
}

sub fill_creation_date
{
		my %d = %{$_[0]};
		log_debug('fill_creation_date','','fill_creation_date');
	
		my @records = sql_lines({debug=>1,debug_results=>1,table=>$d{table},where=>"migcms_moment_create = '0000-00-00 00:00:00'"});
		foreach $record(@records)
		{
				my %record = %{$record};
				my %sys = sql_line({table=>"migcms_sys",where=>"id_table='$record{id}' AND nom_table='$d{table}' "});
				execstmt($dbh,"UPDATE $d{table} SET migcms_moment_create = '$sys{moment}'  where id = '$record{id}' AND migcms_moment_create = '0000-00-00 00:00:00' ");	
		}
}

sub fill_creation_user
{
		my %d = %{$_[0]};
		log_debug('fill_creation_user','','fill_creation_user');

		my @records = sql_lines({debug=>1,debug_results=>1,table=>$d{table},where=>"migcms_id_user_create = 0"});
		foreach $record(@records)
		{
				my %record = %{$record};
				my %sys = sql_line({table=>"migcms_sys",where=>"id_table='$record{id}' AND nom_table='$d{table}' "});
				if($sys{id_user} == 0)
				{
					$sys{id_user} = 8;
				}
				execstmt($dbh,"UPDATE $d{table} SET migcms_id_user_create = '$sys{id_user}'  where id = '$record{id}' AND migcms_id_user_create = 0 ");	
		}
}

sub get_list_of_cols
{
    my $dbh_r = $_[2];
    my @list_of_cols =();
    my $stmt_list_of_cols = "SELECT COLUMN_NAME, DATA_TYPE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA ='$_[0]' AND table_name = '$_[1]'";
    my $cursor_list_of_cols = $dbh_r->prepare($stmt_list_of_cols) || die("CANNOT PREPARE $stmt_list_of_cols");
    $cursor_list_of_cols->execute || suicide($stmt_list_of_cols);
    while ($ref_rec = $cursor_list_of_cols->fetchrow_hashref()) 
    {
        push @list_of_cols,\%{$ref_rec};
    }
    $cursor_list_of_cols->finish;
    return @list_of_cols;
}

sub get_list_of_tables
{
    #list of TABLES
    my $dbh_r = $_[1];
	my @list_of_tables =();
    my $stmt_list_of_tables = "SELECT t.TABLE_NAME AS stud_tables FROM INFORMATION_SCHEMA.TABLES AS t WHERE t.TABLE_TYPE = 'BASE TABLE' AND t.TABLE_SCHEMA = '$_[0]'";
    my $cursor_list_of_tables = $dbh_r->prepare($stmt_list_of_tables) || die("CANNOT PREPARE $stmt_list_of_tables");
    $cursor_list_of_tables->execute || suicide($stmt_list_of_tables);
    while ($ref_rec = $cursor_list_of_tables->fetchrow_hashref()) 
  	{
        push @list_of_tables,$ref_rec->{stud_tables};
  	}
  	$cursor_list_of_tables->finish;
    return @list_of_tables;
}

sub add_history
{
	my %d = %{$_[0]};
	my $id_user = $user{id};
	
	if($d{id_user} > 0)
	{
		$id_user = $d{id_user};
	}
	
	my %history =
	(
		action => $d{action},
		details => $d{details},
		id_user => $id_user,
		date => 'NOW()',
		time => 'NOW()',
		moment => 'NOW()',
		infos => "$ENV{REMOTE_ADDR} $ENV{HTTP_USER_AGENT}",
		page_record => $d{page},
		id_record => $d{id},
	);
	%history = %{quoteh(\%history)};
	inserth_db($dbh,'migcms_history',\%history);
}


#clean*******************************************************************************************************************
sub clean
{
	my $dirty = $_[0];
	my $clean = trim($dirty);
	$clean =~ s/[^\x00-\x7F]//g;
	$clean =~ s/[^A-Za-z0-9\-\.\:\,\(\)\/\\\@\_ ]//g;
	$clean =~ s/\s+$//g;
	$clean =~ s/\|//g;
	
	return $clean;
}

#cleanh*******************************************************************************************************************
sub cleanh
{
	my %hash_r = %{$_[0]};
	foreach $key (keys %hash_r)
	{
		$hash_r{$key} = clean($hash_r{$key});
	}
	return \%hash_r;
}

########################################################
################### get_csv_nbr_rows ###################
########################################################
# Récupération du nombre de ligne présentent dans le
# fichier
#
# Params 1 : $d{file} => path vers le fichier
########################################################
sub get_csv_nbr_rows
{
  my %d = %{$_[0]};

  # Ouverture du fichier à importer
  open my $data, "<", $d{file} or die "$d{file}: $!";

  # On compte le nombre de lignes dans le fichier
  my $rows = 0;
  $rows++ while <$data>;

  return $rows;
}

########################################################
################### get_xls_nbr_rows ###################
########################################################
# Récupération du nombre de ligne présentent dans le
# fichier
#
# Params 1 : $d{file} => path vers le fichier
# 
# file => path vers le fichier (obligatoire)
# page_nbr => Nbr de la page dont il faut compter
#             le nbr de ligne (facultatif)
########################################################
sub get_xls_nbr_rows
{
  use Spreadsheet::ParseExcel;

  my %d = %{$_[0]};

  my $page_nbr = $d{page_nbr} || 0;

  my $parser   = Spreadsheet::ParseExcel->new();
  my $workbook = $parser->parse($d{file});

  my $worksheet = $workbook->worksheet($page_nbr);

  my ( $row_min, $row_max ) = $worksheet->row_range();$worksheet->row_range();

  return $row_max;
}

########################################################
################### get_xlsx_nbr_rows ##################
########################################################
# Récupération du nombre de ligne présentent dans le
# fichier
#
# Params 1 : $d{file} => path vers le fichier
# 
# file => path vers le fichier (obligatoire)
# page_nbr => Nbr de la page dont il faut compter
#             le nbr de ligne (facultatif)
########################################################
sub get_xlsx_nbr_rows
{
  use Spreadsheet::XLSX;

  my %d = %{$_[0]};

  my $page_nbr = $d{page_nbr} || 0;

  my $excel = Spreadsheet::XLSX -> new ($d{file});
  my $sheet = $excel -> {Worksheet}[$page_nbr];

  return $sheet -> {MaxRow};
}

sub format_tel
{
	my $num = $_[0];
	
	 $num =~ s/[^0-9]//g;
	 $num =~ s/^32//g;
	 $num =~ s/^0//g;
	 my @nums = split //, $num;
	 my @new_num = ();
	 
	 my $i = 0;
	 if (($num =~ /^47/ || $num =~ /^48/ || $num =~ /^49/) )
	 {
		push @new_num, $nums[$i++];
		push @new_num, $nums[$i++];
		push @new_num, $nums[$i++];
		push @new_num, ' ';
		push @new_num, $nums[$i++];
		push @new_num, $nums[$i++];
		push @new_num, ' ';
		push @new_num, $nums[$i++];
		push @new_num, $nums[$i++];
		push @new_num, ' ';
		push @new_num, $nums[$i++];
		push @new_num, $nums[$i++];			
	 }
	 else
	 {
		push @new_num, $nums[$i++];
		push @new_num, ' ';
		push @new_num, $nums[$i++];
		push @new_num, $nums[$i++];
		push @new_num, $nums[$i++];
		push @new_num, ' ';
		push @new_num, $nums[$i++];
		push @new_num, $nums[$i++];
		push @new_num, ' ';
		push @new_num, $nums[$i++];
		push @new_num, $nums[$i++];	
	 }
	 $num = '+32 '.join("",@new_num);
	
	return $num;

}

sub getcode
{
 my $dbh = $_[0];
 my $id = $_[1];
 my $force_prefixe = $_[2];
 my $prefixe = $dm_cfg{file_prefixe};
 
 if($force_prefixe ne '' )	{
		 $prefixe = $force_prefixe;
	 }
   
	$prefixe = uc($prefixe);
	return $prefixe.sprintf("%07d",$id);
}

##############################################################################
# get_excel_value
# 
# Params : 
# 	- excel_sheet : la page du fichier Excel
# 	- row : la ligne
# 	- col : la colonne
# 	
##############################################################################
sub get_excel_value
{
	my %d = %{$_[0]};

	# see(\%d);
	# exit;

	my $cell = $d{excel_sheet}->{Cells}[$d{row}][$d{col}]; 

  my $value = trim($cell->{Val});
  $value =~ s/\'/\\\'/g;

  return $value;
}


sub get_codes
{
	my $code = $_[0];
	my $where_code = '';
	if($code ne '')
	{
		$where_code = " AND code = '$code' ";
	}
	
	my %codes = ();
	
	my @migcms_code_types = sql_lines({select=>"t.id,t.code",table=>'migcms_code_types t',where=>"visible='y' $where_code"});
	foreach my $migcms_code_type (@migcms_code_types)
	{
		my %migcms_code_type = %{$migcms_code_type};
		
		my @migcms_codes = sql_lines({select=>"code,id_textid_name,ordby,condition_where,v1,v2,v3,v4,v5,v6,v7",table=>'migcms_codes ',where=>"visible='y' AND id_code_type = '$migcms_code_type{id}'"});
		foreach $migcms_code (@migcms_codes)
		{
			my %migcms_code = %{$migcms_code};
			
			foreach my $col (keys %migcms_code)
			{
				if($migcms_code{$col} ne '')
				{
					$codes{$migcms_code_type{code}}{$migcms_code{code}}{$col} = $migcms_code{$col};
				}
			}
		}
	}
	return %codes;
}

##############################################################################
# write_file_csv
# 
# Params : 
# 	- data : arrays de hashes des lignes à écrire dans le fichier
# 	- separator : séparateur de données (Défaut : ";")
# 	- outfile : Path vers le fichier à écrire
# 	
##############################################################################
sub write_file_csv
{
  my %d = %{$_[0]};

  my @lines = @{$d{data}};

  use Text::CSV;
	use Text::Iconv;

  my $csv = Text::CSV->new ( { 
		binary             => 1,
		sep_char           => ";",
		always_quote => 1,
		allow_loose_quotes => 1,
		eol                => $/,
  })  # should set binary attribute.
    or die "Cannot use CSV: ".Text::CSV->error_diag ();

  open $fh, ">", "$d{outfile}" or die "$d{outfile}: $!";

  my $converter = Text::Iconv->new("UTF-8", "ISO-8859-1");

  foreach $line (@lines)
  {
    my %line = %{$line};
    # see(\%line);

		my @record;
    foreach $key (sort keys %line)
    {
			my $value = $converter->convert($line->{$key});

      push @record, $value;
    }

    # Ecriture de la ligne dans le fichier CSV
    $csv->print ($fh, \@record);

  }

	close $fh or die "$d{outfile}: $!";
}

sub add_historique_envoi_email
{
	my %d = %{$_[0]};
	$d{moment} =  'NOW()';
	$${email_script} = $ENV{REQUEST_URI};
	
	if($d{email_to} ne '')
	{
		%d = %{quoteh(\%d)};
		
        my @emails_to = split (/,/,$d{email_to});
		foreach $email_to (@emails_to)
		{
			if($email_to ne '')
			{
				$d{email_to} = $email_to;
				$d{id_member} = $user{id};
				inserth_db($dbh,'migcms_mail_history',\%d);	

				# {
					# email_from      =>$adr_from,
					# email_to      =>$adr_to,
					# email_position     =>'Cci',
					# email_object     =>$subject
					# email_body     =>$body_text
				# }

			
			
			}			
		}
		

		
	
	}
	
	
	
}


sub remove_param_from_url
{
 my $url = $_[0];
 my $param = $_[1];
 
 my @newparts = ();
 my @parts = split(/&/,$url);
 foreach $part (@parts) {
  if ($part !~ /^$param/) {
      push @newparts, $part;
  }
 }
 
 return join("&",@newparts);
}


sub sql_get_rows_array;
*sql_get_rows_array = \&get_table;

sub sql_get_row_from_id;
*sql_get_row_from_id = \&read_table;



sub sql_radios
{
  my %d = %{$_[0]};
      
  if($d{table} ne "" && $d{value} ne "" && $d{display} ne "" && $d{name} ne "")
  {
    my $cbs=<<"EOH";
EOH
    my @records=get_table($d{dbh},$d{table},$d{select},$d{where},$d{ordby},"","",$d{debug});
    foreach my $rec (@records)
    {
        my $checked="";
        if($d{current_value} eq $rec->{$d{value}})
        {
            $checked=<<"EOH";
             checked = "checked"                
EOH
        }
        $cbs.=<<"EOH";
          <label>   
            <input type="radio" name="$d{name}" $checked value="$rec->{$d{value}}" $d{required} class="$d{class}"> 
            $rec->{$d{display}}
          </label>
EOH
    }    
    
    $cbs.=<<"EOH";
EOH
    return $cbs;
    exit;
  }
  else
  {
      return "missing mandatory data: [table:$d{table}][value:$d{value}][display:$d{display}][name:$d{name}]";
  }  
}




1;