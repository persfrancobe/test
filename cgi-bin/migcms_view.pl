#!/usr/bin/perl -I../lib 

# CPAN modules
use CGI::Carp 'fatalsToBrowser';
use CGI;              
use DBI;              
use def;              
use tools;            
         
use migcrender; 
use IO::Handle; 
use members;



my $lg = get_quoted('lg') || 1;
$lg =~ s/undefined//g;
$config{current_language} = $config{default_colg} = $lg;
my $sw = get_quoted('sw') || 'view';
my $edit = get_quoted('edit') || 'n';
if($edit eq 'y')
{
	my $module = 'dm';
	my $file = $module;
	$file =~ s[::][/]g;
	$file .= '.pm';
	require $file;
	$module->import;
	%user = %{dm::get_user_info()};
	if(!($user{id}>0))
	{
		cgi_redirect($config{baseurl}."/admin");
		exit;
	}
}

see();
my $self = $config{baseurl}.'/cgi-bin/migcms_view.pl?lg='.$lg;

&$sw();

#VIEW ************************************************************************************
sub view 
{
	my $id_page = $cgi->param('id_page');
	my $mailing = $cgi->param('mailing');
	my $block = $cgi->param('block');
    if($id_page > 0)
    {
		my %page = sql_line({debug=>0,debug_results=>0,table=>"migcms_pages",where=>"id='$id_page'"});
		my %migcms_lnk_page_group = sql_line({table=>'migcms_lnk_page_groups',where=>"is_linked='y' AND id_migcms_page='$id_page' "});

		my $is_page_protected = is_page_protected({debug=>0,id_page=>$id_page});
		
		
		if( $is_page_protected eq 'page_not_protected')
		{
			#si la page n'est pas protégée on l'affiche
		
			view_page({mailing=>$mailing,block=>$block,id_page=>$id_page,fr=>'bugi',page=>\%page});
			exit;
		}
		else
		{
			#si elle protégée on commence les vérifications pour le membre
			my %member = %{members_get()};

			#si on est connecte
			if($member{id} > 0)
			{
				#si le groupe correspond à la page
				my %migcms_lnk_page_group = sql_line({debug=>0, debug_results=>0, table=>'migcms_lnk_page_groups', where=>"id_migcms_group = '$member{id_member_group}' AND is_linked='y' AND id_migcms_page='$id_page'"});
				
				if($migcms_lnk_page_group{id} > 0)
				{
					#si on a le droit de voir cette page = si on fait partie d'un groupe qui a le droit de voir cette page
					my $cache = get_quoted('cache');
					
					#si le membre est validé
					if($member{actif} eq 'y')
					{
						member_add_event({member=>\%member,type=>'view_page',name=>"Le membre consulte la page $id_page",detail=>$id_page,erreur=>''});
						view_page({cache=>$cache,type=>'private',id_page=>$id_page,fr=>'bugi',page=>\%page});
						exit;
					}
					else
					{
						#si on n'a pas le droit de voir la page
						member_add_event({member=>\%member,type=>'view_page_non_valide',name=>"Le membre consulte la page $id_page mais l'accès au contenu est refusé car son accès n'est pas validé",detail=>$member{validation_statut},erreur=>'erreur_validation'});
						member_error_page_validation({lg=>$lg,member=>\%member,id_page=>$id_page});
						exit;
					}
				}
				else
				{
					#si on n'a pas le droit de voir la page
					member_add_event({member=>\%member,type=>'view_page_group_forbidden',name=>"Le membre consulte la page $id_page mais l'accès au contenu est refusé car son groupe n'y a pas accès",detail=>$member{id_member_group},erreur=>'erreur_groupe'});
					member_error_page({id_page=>$id_page});
					exit;
				}
			}
			else
			{
				#si on n'est pas connecte
				member_login_form({id_page=>$id_page, url_after_error=>"/cgi-bin/members.pl?lg=$lg&sw=login_form"});
				exit;
			}
			# elsif($config{member_token_name} ne '' && $config{member_token_table} ne '' && get_quoted($config{member_token_name}) ne '')
			# {
				# si un token passe droit est passé autorisant l'accès à cette page malgré tout
				# my %table_passe_droit = sql_line({table=>$config{member_token_table},where=>"$config{member_token_name} != '' AND $config{member_token_name} = '".get_quoted($config{member_token_name})."'"});
				# if($table_passe_droit{id} > 0)
				# {
					# view_page({id_page=>$d{id_page},token_passe_droit=>get_quoted($config{member_token_name}),member_token_name=>$config{member_token_name},fr=>'bugi',page=>\%page});
					# exit;
				# }
			# }
			
		}
		
		my $page_html = render_page({debug=>0,id=>$id_page,lg=>$lg,preview=>'y',edit=>$edit});
		see();

        print $page_html;
    }
    else
    {
		print "Entrez un numéro de page valide svp";
		exit;
    }
    exit;
}

#VIEW PAGE********************************************************************************
sub view_page
{
	my %d = %{$_[0]};
	# see(\%d);

	if($d{fr} eq 'bugi')
	{
		# if($d{page}{visible} eq 'y')
		# {
			if($d{cache} ne '' && $d{type} ne '')
			{
				my $url_cache = '../cache/site/cms/pages/'.$d{type}.'/'.$d{cache}.'.html';	
				if($d{type} eq 'private' && $config{private_pages_are_dynamic} eq 'y')
				{
					#pas de publication de page privée dynamique (rendu live)
				}
				elsif (-e $url_cache)
				{
					my $page_html = get_file($url_cache);
					my $nettoyage = '<MIGC.*_HERE>';
					$page_html =~ s/$nettoyage//g;		
					print $page_html;
					exit;
				}
			}
			
			#rendu de la page, passer le token passe droit dans les urls
			my $page_html = render_page({full_url=>1,mailing=>$d{mailing},block=>$d{block},debug=>0,id=>$d{id_page},lg=>$lg,preview=>'y',edit=>$edit,type_page=>$d{type}});
			# my $nettoyage = '<MIGC.*_HERE>';
			# $page_html =~ s/$nettoyage//g;	


			my $tag = '<MIGC_(.*?)_HERE>';
			$_ = $page_html; 
			my @lnks = (/<MIGC_([a-zA-Z0-9\_]*)_HERE>/g);
			for ($i = 0; $i<=$#lnks; $i++ ) 
			{		
				$tag = '<MIGC_'.$lnks[$i].'_HERE>';
				if($lnks[$i] ne 'UNSUBSCRIBE_URL' && $lnks[$i] ne 'MAILER_URL')
				{
					$page_html =~ s/$tag//g;
				}
			}
			
			print $page_html;
			exit;
		# }
		# else
		# {
			#page invisible
		# }
	}
	else
	{
		print 'errfr';	
		exit;
	}
	exit;
}


#TWIN VIEW ************************************************************************************
sub twinview
{
	see();
    print <<"EOH";
	<style>
    iframe{
        height: 100%;
        width: 48%;
        }
</style>
<iframe src="../cgi-bin/migcms_view.pl?page=1&edit=y&lg=1"></iframe>
<iframe src="../cgi-bin/migcms_view.pl?page=1&edit=y&lg=3"></iframe>
EOH
    exit;

}

#save_mig_parag_content ************************************************************************
sub save_mig_parag_content
{
	see();
	
	my $content = get_quoted('content');
	my $id = get_quoted('id');
	my $lg = get_quoted('lg');
	# print "update text for $id and $lg : $content";
	my $stmt = "UPDATE txtcontents SET lg$lg='$content' WHERE id ='$id'";
	execstmt($dbh,$stmt);
}