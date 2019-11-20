#!/usr/bin/perl -I../lib

# CPAN modules
use CGI::Carp 'fatalsToBrowser';
use CGI;              # standard package for easy CGI scripting
use DBI;              # standard package for Database access
# wfw modules
use def;              # home-made package for defines
use tools;            # home-made package for tools
# migc modules

         # migc translations
use migcrender; use IO::Handle; STDOUT->autoflush(1);
use sitetxt;

            
# build the CGI object, and so on...
$_ = $cgi->param('sw');
$lg = get_quoted('lg') || $config{default_language};

# $config{charset} = get_charset($dbh,$config{current_language});

$page = $cgi->param('page');
$config{viewer} = "cgi";
$config{logfile} = "../trace.log";

$self = "nl.pl?lg=$lg";
my $sw = get_quoted('sw') || "subscribe";
 
&$sw();


sub subscribe
{
    my $email=get_quoted('email') || "";
    my $ajax_mode = get_quoted('ajax_mode') || 'y';
    my $id_mailing_group=get_quoted('id_mailing_group') || 0;
    
    my $phrase_ok = $sitetxt{mailing_add_msg_ok};
    my $phrase_ko = $sitetxt{mailing_add_msg_ko};
    my $phrase_deja = $sitetxt{mailing_add_msg_deja};
    my $phrase_remove_ok = $sitetxt{mailing_remove_msg_ok};
    my $phrase_remove_ko = $sitetxt{mailing_remove_msg_ko};
    
    see();
    
    if($id_mailing_group > 0 && $email ne "")
    {
        if(is_mailing_member_from_group($dbh,$email,$id_mailing_group))
        {
            if($ajax_mode eq 'y')
            {
                print "deja";
                exit;
            }
            else
            {
                my $txterror = $phrase_deja;
                $txterror =~ s/\'/\\\'/g;
                make_error($txterror);
                exit;
            }
        }
        
        #add mailing member
        my %mailing_member=();
        $mailing_member{email}=$email; 
        my $id_mailing_member = inserth_db($dbh,"mailing_members",\%mailing_member);
        
        #add lnk
        my %mailing_lnk_member_group=();
        $mailing_lnk_member_group{id_mailing_member}=$id_mailing_member;
        $mailing_lnk_member_group{id_mailing_group}=$id_mailing_group;
        my $id_mailing_lnk_member_group = inserth_db($dbh,"mailing_lnk_member_groups",\%mailing_lnk_member_group);
       
        if($ajax_mode eq 'y')
        {
            if($id_mailing_lnk_member_group > 0 && $id_mailing_member > 0)
            {
                print "ok";
                exit;
            }
            else
            {
                print "ko";
                exit;
            }
         }
         else
         {
            if($id_mailing_lnk_member_group > 0 && $id_mailing_member > 0)
            {
                $msg = "$phrase_ok";
            }
            else
            {
                my $txterror = $phrase_ko;
                $txterror =~ s/\'/\\\'/g;
                make_error($txterror);
                exit;
            }
         }
    }
    else
    {
        if($ajax_mode eq 'y')
        {
              print "ko";
              exit;
        }
        else
        {
            my $txterror = $phrase_ko;
            $txterror =~ s/\'/\\\'/g;
            make_error($txterror);
            exit;
        }
    }
    
   my $msg = "<div class=\"nl_ok\">$msg</div>";
   my $id_template_page = $config{newsletter_result_page_tpl};
   my $template_page=migcrender::get_template($dbh,$id_template_page,$config{current_language},"","html");
   my $page_content = get_link_canvas($dbh,$config{newsletter_extlink},$template_page,"html",$msg,$id_template_page,$config{current_language});
   print $page_content;
}

sub unsubscribe
{
    my $email=get_quoted('email') || "";
    my $id_mailing_group=get_quoted('id_mailing_group') || 0;
    
    my $phrase_ok = $sitetxt{mailing_add_msg_ok};
    my $phrase_ko = $sitetxt{mailing_add_msg_ko};
    my $phrase_deja = $sitetxt{mailing_add_msg_deja};
    my $phrase_remove_ok = $sitetxt{mailing_remove_msg_ok};
    my $phrase_remove_ko = $sitetxt{mailing_remove_msg_ko};
    
    see();
    
    if($id_mailing_group > 0 && $email ne "")
    {
        #delete multiple email (si doublons)
        my @lnks=get_table($dbh,"mailing_members m,mailing_lnk_member_groups l","","email='".$email."' and l.id_mailing_member = m.id");
        for($i=0;$i<$#lnks+1;$i++)
        {
              my $stmt = "delete from mailing_lnk_member_groups where id_mailing_member='".$lnks[$i]{id_mailing_member}."'";
              my $cursor = $dbh->prepare($stmt);
              my $rc = $cursor->execute;
              if (!defined $rc) 
              {
                      see();
                      print "[$stmt]";
                      exit;   
              }
        }
        
        #delete email from members
        my $stmt = "delete from mailing_members where email='".$email."'";
        my $cursor = $dbh->prepare($stmt);
        my $rc = $cursor->execute;
        if (!defined $rc) 
        {
                see();
                print "[$stmt]";
                exit;   
        }
       
        if($ajax_mode eq 'y')
        {
              print "ok";
              exit;
        }
        else
        {
            $msg =  $phrase_remove_ok;
        }
       
    }
    else
    {
        if($ajax_mode eq 'y')
        {
              print "ko";
              exit;
        }
        else
        {
            my $txterror = $phrase_remove_ko;
            $txterror =~ s/\'/\\\'/g;
            make_error($txterror);
            exit;
        }
    }
    
    
   my $msg = "<div class=\"nl_ko\">$msg</div>";
   my $id_template_page = $config{newsletter_result_page_tpl};
   my $template_page=migcrender::get_template($dbh,$id_template_page,$config{current_language},"","html");
   my $page_content = get_link_canvas($dbh,$config{newsletter_extlink},$template_page,"html",$msg,$id_template_page,$config{current_language});
   print $page_content; 
}

###############################################################################
# UNSUBSCRIBE_DB
###############################################################################

sub unsubscribe_db
{
 my $email = get_quoted('email');
 my $id_sending = get_quoted('nl');

 my $id_member;
 
#  see();
#  print "[$email]";
#  exit;

 my $stmt = "SELECT id_mailing FROM mailing_sendings WHERE id = $id_sending ";
 my $cursor = $dbh->prepare($stmt);
 $cursor->execute || suicide($stmt);
 my ($id_mailing) = $cursor->fetchrow_array;
 $cursor->finish;

 #$stmt = "INSERT INTO mailing_blacklist (id_mailing,id_sending,email,moment,reason) VALUES ($id_mailing,$id_sending,'$email','NOW()','unsubscribe')";
 #execstmt($dbh,$stmt);
 
  $stmt = "UPDATE migcms_members set email_optin ='n' where email='$email'";
 execstmt($dbh,$stmt);
 
 # $stmt = "SELECT id FROM mailing_members WHERE email='$email'";
 # $cursor = $dbh->prepare($stmt);
 # $cursor->execute || suicide($stmt);

 # while (($id_member) = $cursor->fetchrow_array) {
     # $stmt = "DELETE FROM mailing_lnk_member_groups WHERE id_mailing_member =$id_member";
     # execstmt($dbh,$stmt); 
     # $stmt = "DELETE FROM mailing_members WHERE id='$id_member'";
     # execstmt($dbh,$stmt); 
      
 # }
 # $cursor->finish;

 my $display = <<"EOH";
<html>
<body>
<h1>Ok !</h1>
<p>Your unsubscription request has been made.</p>
<p>Votre désinscription a bien été prise en compte.</p>
</body>
</html>
EOH
see();

print $display;
}