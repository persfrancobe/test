#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use Data::Dumper;
         # migc translations

$colg = get_quoted('colg') || $config{default_colg} || 1;

$dm_cfg{customtitle} = $migctrad{mailings};
$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "mailings";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_$dm_cfg{table_name}.pl?colg=".$colg;
 $dm_cfg{after_add_ref} = \&after_add;
 $dm_cfg{after_mod_ref} = \&after_mod;
 $dm_cfg{default_ordby} = "id desc";
$dm_cfg{add_title} = "Ajouter un envoi";

$dm_cfg{custom_navbar} = <<"EOH";
<a data-original-title="Blacklist" 
data-placement="bottom" class="btn btn-primary btn-lg 
 search_element"
 href = "adm_migcms_mailing_blacklist.pl?sel=$sel"  
 >
<i class="fa  fa-ban fa-fw"></i> 

</a>



EOH


%status = (
			'running'=>$migctrad{yes},
			'ok'=>$migctrad{no},
		);

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    '01/title'=> {
	        'title'=>$migctrad{adm_mailings_title},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    },
	     '02/sender_name'=> {
	        'title'=>$migctrad{adm_mailings_sender_name},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    },
	     '03/sender_email'=> {
	        'title'=>$migctrad{adm_mailings_sender_email},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    },
	     '04/email_subject'=> {
	        'title'=>$migctrad{adm_mailings_email_subject},
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
		,
	     '05/id_migcms_page'=> {
	        'title'=>'Newsletter',
	        'fieldtype'=>'listboxtable',
		      'lbtable'=>'migcms_pages',
		      'lbkey'=>'migcms_pages.id',
		      'lbwhere'=>'migcms_pages_type="newsletter"',
		      'lbdisplay'=>'id_textid_name',
	        'mandatory'=>{"type" => 'not_empty'},
	        'translate' => "1",
			  
          }
		  ,
	     '06/id_language_mailing'=> 
		 {
	        'title'=>'Langue',
	        'fieldtype'=>'listboxtable',
		      'lbtable'=>'migcms_languages',
		      'lbkey'=>'id',
		      'lbwhere'=>"visible='y'",
		      'lbdisplay'=>'display_name',
	        'mandatory'=>{"type" => 'not_empty'},
          }
		  
          # ,
	     # '06/template_html'=> {
	        # 'title'=>'Utiliser plutôt le canevas HTML',
	        # 'fieldtype'=>'textarea',
          # },


      
          
      
	);
	
%dm_display_fields = 
(
	"01/$migctrad{adm_mailings_title}"=>"title",
	"02/Objet de l'email"=>"email_subject",
);

		
%dm_lnk_fields = 
(
	# "04/Voir cette newsletter/<span class='span_tooltip fa fa-eye' data-original-title='Voir cette newsletter' data-placement='top'>"=>"$config{baseurl}/cgi-bin/adm_migcms_mailing_sendings.pl?colg=$colg&sw=send_mailing_choose_groups&id_mailing=",
	"05/Envoyer cette newsletter/<span class='span_tooltip fa fa-paper-plane' data-original-title='Envoyer cette newsletter' data-placement='top'>"=>"$config{baseurl}/cgi-bin/adm_migcms_mailing_sendings.pl?colg=$colg&sw=send_mailing_choose_groups&id_mailing=",
	"06//<span class='span_tooltip fa fa fa-archive' data-original-title='Historique des envois' data-placement='top'>"=>"$config{baseurl}/cgi-bin/adm_migcms_mailing_sendings.pl?colg=$colg&id_mailing=",
);

%dm_mapping_list = (
);




$sw = $cgi->param('sw') || "list";

see();

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
			up
			mailing_send
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}

sub mailing_send
{
    my $id_mailing=get_quoted('id_mailing');
    $dm_output{content}="send mailing #$id_mailing";
}

sub after_add
{
  my $dbh = $_[0];
  my $id = $_[1];

 my %mailing = read_table($dbh,"mailings",$id);

 foreach $k (keys(%mailing)) {
     $mailing{$k} =~ s/\'/\\\'/g;
 }
 
 my $id_template = $mailing{'id_template'};
 my $title = $mailing{'title'};
 #$title =~ s/\'/\\\'/g;
 my $id_textid_title = insert_text($dbh,$title,$colg);
 
 # INSERT PAGE
 my $stmt = "INSERT INTO pages (id_textid_name,id_template) VALUES ('$id_textid_title','$id_template')";
 execstmt($dbh,$stmt);      

 my $page = $dbh->{'mysql_insertid'};
  
 $mailing{id_page} = $page;
 
 updateh_db($dbh,"mailings",\%mailing,"id",$id);
}

sub after_mod
{
  my $dbh = $_[0];
  my $id = $_[1];

  my %mailing = read_table($dbh,"mailings",$id);

  $page{id_template} = $mailing{id_template};
   
 updateh_db($dbh,"pages",\%page,"id",$mailing{id_page});
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------