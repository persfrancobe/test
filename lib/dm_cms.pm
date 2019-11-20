package dm_cms;
@ISA = qw(Exporter);
@EXPORT = qw(
do_build_pages
migcms_build_compute_urls
save_url
set_publish_progression
get_publish_progression
);
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use sitetxt;
use migcrender;
use members;
use data;
use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset);

$dbh_data=$dbh;
if($dm_cfg{dbh} eq 'dbh2')
{
    $dbh_data = $dbh2;
}


my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

my $publish_token = create_token(10);


sub write_map_file
{
	my $mapname = $_[0];
	
	#categories
	my $mapcontent = '';
	my @migcms_urls = sql_lines({table=>'migcms_urls',where=>"nom_table='data_categories' AND id_table > 0 AND url_rewriting != ''"});
	foreach $migcms_url (@migcms_urls)
	{
		my %migcms_url = %{$migcms_url};
		$mapcontent .= "\n".$migcms_url{url_rewriting}.' '.$migcms_url{id_table};	
	}
	reset_file('../'.$mapname.'.txt');
	write_file('../'.$mapname.'.txt',$mapcontent);
	
	
}

sub get_publish_progression
{
	see();
	
	my %progression = sql_line({table=>'config',where=>"varname='publish_progession'"});
	if($progession{varvalue} > 0)
	{
		print $progession{varvalue};
	}
	else
	{
		print 0;
	}
	exit;
}

sub set_publish_progession
{
	my $progression = $_[0];	
	my $total = $_[1];	
	my $ratio = sprintf("%.0f",(100*($progression/$total)));
	log_debug($ratio,'vide','publish_progession.txt','no_date');
	if($ratio >= 100)
	{
		log_debug(0,'vide','publish_progession.txt','no_date');
	}
}


sub do_build_pages
{
    log_debug('do_build_pages','vide','do_build_pages');
	my %migcms_setup = sql_line({debug=>0,debug_results=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
	my %data_setup = sql_line({debug=>0,debug_results=>0,table=>"data_setup",select=>'',where=>"",limit=>'0,1'});

	my $one_language_site = 1;
	my %nb_languages_site = sql_line({table=>'migcms_languages',select=>"COUNT(*) as nb",where=>"visible='y'"});
	if($nb_languages_site{nb} > 1)
	{
		$one_language_site = 0;
	}
	
	my $tmp_htaccess = "../.htaccess_".$publish_token;
	my $tmp_htaccess2 = '';	
	if($config{htaccess_2_for_page} > 0)
	{
		$tmp_htaccess2 = "../.htaccess2_".$publish_token;
	}
	
	my $tmp_sitemap = "../sitemap_".$publish_token.'.xml';
	my $tmp_sitemap2 = '';	
	if($config{sitemap_2_for_page} > 0)
	{
		$tmp_sitemap2 = "../sitemap2_".$publish_token.'.xml';
	}
	
	my $mapname = $config{projectname}.'_map';
	
	my $dossier_page_public = '../cache/site/cms/pages/public';
	my $dossier_page_private = '../cache/site/cms/pages/private';
	
	#crée des dossiers temporaires
	mkdir $dossier_page_public.$publish_token;
	mkdir $dossier_page_private.$publish_token;
	log_debug('mkdir ok','','do_build_pages');

	# data::migcms_build_data_searchs_keyword(); #reconstruit la recherche par mot clé. Normalement construit lors de la sauvegarde d'une fiche
	migcms_build_compute_urls();
	log_debug('migcms_build_compute_urls ok','','do_build_pages');

	write_map_file($mapname);
	init_htaccess($publish_token,);
	init_sitemap();
	if($config{htaccess_2_for_page} > 0)
	{
		init_htaccess($publish_token,$tmp_htaccess2);
	}
	if($config{sitemap_2_for_page} > 0)
	{
		init_sitemap($tmp_sitemap2);
	}
	log_debug('init ok','','do_build_pages');

	my $type = $_[0];

	# Compresse les fichiers JS
	if($migcms_setup{compile_js} eq "y")
	{	
		my $filename = "../skin/js/".$config{projectname}."_compil.js";
		reset_file($filename);
		my @files = sql_lines({debug=>0,debug_results=>0,table=>'migcms_frontend_js',ordby=>'ordby',where=>"visible='y'"});
		
		foreach $file (@files)
		{
			my %file = %{$file};
			my $src_file = '../'.$file{filename};
			
			my $content = get_file($src_file) or die ("cannont find $src_file");
			
			
			write_file($filename,$content);
		}
	}
	
	my %count_page = sql_line({table=>'migcms_pages',select=>"COUNT(*) as nb",where=>"visible='y' AND migcms_pages_type = 'page'"});
	my %count_lg = sql_line({table=>'migcms_languages',select=>"COUNT(*) as nb",where=>"visible='y'"});
	my $nb = $count_page{nb} * $count_lg{nb};
	my $e = 0;
	
	#génère les pages 
	my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible='y'"});
	foreach $language (@languages)
    {
		my %language = %{$language};
        $use_global_sitetxt = 0;
		$config{current_language} = $language{id};
        %sitetxt = %{get_sitetxt($dbh,$config{current_language})};

		my $where_depends_on_actif_language = '';
		if($dm_cfg{depends_on_actif_language} eq 'y') 
		{	
			$where_depends_on_actif_language = ' actif_'.$language{id}.' = "y" AND ';
		}		
		my @migcms_pages = sql_lines({table=>'migcms_pages',where=>"$where_depends_on_actif_language visible='y' AND migcms_pages_type = 'page'"});
		
		foreach $page (@migcms_pages)
		{
			my %page = %{$page};
			
			$e++;
			set_publish_progession($e,$nb);

			log_debug("page $page{id}: $e / $nb  $language{id}",'','do_build_pages');

			my $is_private = 0;
			
			#les pages protégées ne se publient pas
			if(migcrender::is_page_protected({debug=>0,id_page=>$page{id}}) ne 'page_not_protected')
			{
				$is_private = 1;
			}
			
			#récupération de l'url
			my $url_rewriting = get_url({debug=>0,nom_table=>'migcms_pages',id_table=>$page{id}, id_language => $language{id}});

			log_debug("page $page{id}: $e / $nb  url_rewriting:[$url_rewriting]",'','do_build_pages');
			log_debug("page $page{id}: $e / $nb  migcms_pages_type:[$page{migcms_pages_type}]",'','do_build_pages');


			#rendu HTML de la page
			my $page_html = '';
			if($page{migcms_pages_type} eq 'page')
			{
				log_debug("$page_html = migcrender::render_page({debug=>0,id=>$page{id},lg=>$language{id},preview=>'n',edit=>'n'});",'','do_build_pages');
				$page_html = migcrender::render_page({debug=>0,id=>$page{id},lg=>$language{id},preview=>'n',edit=>'n'});

			}
			log_debug("rendu html OK",'','do_build_pages');


			my $url = clean_url($url_rewriting);
			$url = $page{id}.'_'.$language{id}.'_'.$url;
			log_debug("page $page{id}: $e / $nb  url:[$url]",'','do_build_pages');

			#écriture de la page
			if($url ne '')
			{
				my $dossier_page_sans_points = $dossier_page = $dossier_page_public;
				if($is_private == 1)
				{
					$dossier_page_sans_points = $dossier_page = $dossier_page_private;
				}
				$dossier_page_sans_points =~ s/^\.\.\///g;
				
				my $url_reecrite = $dossier_page_sans_points."/".$url.".html";
				log_debug("page $page{id}: $e / $nb  url_reecrite:[$url_reecrite]",'','do_build_pages');

				if($is_private == 1)
				{
					if($config{private_pages_are_dynamic} eq 'y')
					{
						$url_reecrite = $config{baseurl}.'/cgi-bin/migcms_view.pl?lg='.$language{id}.'&id_page='.$page{id};
					}
					else
					{
						$url_reecrite = $config{baseurl}.'/cgi-bin/migcms_view.pl?cache='.$url.'&lg='.$language{id}.'&id_page='.$page{id};
					}
				}
				
				
				my $tmp_access_param = $tmp_htaccess;
				if($page{id_fathers} ne '' && $config{htaccess_2_for_page} > 0 && $page{id_fathers} =~ /\,$config{htaccess_2_for_page}\,/)
				{
					$tmp_access_param = $tmp_htaccess2;
				}				
				
				#MAJ de HTACCESS
				# if($one_language_site == 1 && $page{id} == $migcms_setup{id_default_page} && $migcms_setup{id_default_page} > 0 )
				if($one_language_site == 1 && (($page{id} == $migcms_setup{id_default_page} && $migcms_setup{id_default_page} > 0) || ($page{id} == $config{id_default_page2} && $config{id_default_page2} > 0)))
				{
					#si c'est la première page d'un site en une langue: url spéciale 
					my $htaccess_line = "\n".' RewriteRule ^$ '.$url_reecrite;
					$url_rewriting = '';
					log_debug("A: $tmp_access_param $htaccess_line",'','do_build_pages');

					write_file($tmp_access_param,$htaccess_line);
				}
				elsif($url_rewriting =~ /404/)
				{
					my $htaccess_line = "\n RewriteRule ^".$url_rewriting."\$ $url_reecrite";
					log_debug("B: $tmp_htaccess $htaccess_line",'','do_build_pages');

					write_file($tmp_htaccess,$htaccess_line);
					if($config{htaccess_2_for_page} > 0)
					{
						write_file($tmp_htaccess2,$htaccess_line);						
					}
				}
				else
				{
					my $htaccess_line = "\n RewriteRule ^".$url_rewriting."\$ $url_reecrite";
					log_debug("C: $tmp_access_param $htaccess_line",'','do_build_pages');

					write_file($tmp_access_param,$htaccess_line);
				}

				my $tmp_sitemap_param = $tmp_sitemap;
				my $full_url_param = $config{fullurl};
				if($page{id_fathers} ne '' && $config{sitemap_2_for_page} > 0 && $page{id_fathers} =~ /\,$config{sitemap_2_for_page}\,/)
				{
					$tmp_sitemap_param = $tmp_sitemap2;
					$full_url_param = $config{baseurl_2};
				}

				log_debug("MAJ du sitemap",'','do_build_pages');


				#MAJ du sitemap
				my ($date,$time) = split(/ /,$page{migcms_moment_last_edit});
				my ($yyyy,$mm,$dd) = split (/-/,$date); 
				if(!($yyyy > 0 && $mm > 0 && $dd > 0))
				{
					($date,$time) = split(/ /,$page{migcms_moment_create});
				}
				my $sitemap_line = <<"EOH";
				 <url>
					<loc>$full_url_param/$url_rewriting</loc>
					<lastmod>$date</lastmod>
				 </url>
EOH
				if($url_rewriting !~ /404/)
				{
					write_file($tmp_sitemap_param,$sitemap_line);
				}
				log_debug("MAJ du sitemap OK",'','do_build_pages');


				#génération de la page HTML 
				if($config{private_pages_are_dynamic} eq 'y' && $is_private == 1)
				{
					#ne pas générer les pages privées dynamiques
				}
				else
				{
					log_debug("Génération de la page HTML ",'','do_build_pages');
					write_file($dossier_page.$publish_token.'/'.$url.'.html',$page_html);
					log_debug("Génération de la page HTML OK ",'','do_build_pages');
				}

				log_debug("page $page{id}: $e / $nb OK  $language{id}",'','do_build_pages');
			}
		}
	}

	
	#complète le HTACCESS avec les URLS des familles+moteurs de DATA + MODULES
	foreach $language (@languages)
    {
		my %language = %{$language};
		#urls details
		my @data_families = sql_lines({table=>'data_families'});
		{
			foreach my $data_family (@data_families)
			{
				%data_family = %{$data_family};
				my ($texte_url_famille,$dum) = get_textcontent ($dbh,$data_family{id_textid_url_rewriting},$language{id});
				if($texte_url_famille eq '')
				{
					$texte_url_famille = 'famille_'.$data_family{id};
				}
				my ($txt_detail,$dum) = get_textcontent ($dbh,$data_family{id_textid_fiche},$language{id});
				if($txt_detail eq '')
				{
					$txt_detail = 'detail';
				}
				$url_rewriting = $language{name}.'/'.$texte_url_famille.'/'.$txt_detail;
				$url_rewriting = clean_url($url_rewriting,'y');
				
				my $htaccess_line = "\nRewriteRule ^".$url_rewriting.'/(.*)$ cgi-bin/data.pl?sw=detail&lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&MapRewrite=$1';
							
				if($url_rewriting ne '')
				{
					write_file($tmp_htaccess,$htaccess_line);
					if($config{htaccess_2_for_page} > 0)
					{
						write_file($tmp_htaccess2,$htaccess_line);
					}	
				}
			}
		}
		log_debug("URLS des familles+moteurs OK  $language{id}",'','do_build_pages');
		
		#urls moteurs
		my @data_search_forms = sql_lines({debug=>0,debug_results=>0,table=>'data_search_forms',where=>""});		
		foreach my $data_search_form (@data_search_forms)
		{
			%data_search_form = %{$data_search_form};
			my %data_family = read_table($dbh,'data_families',$data_search_form{id_data_family});
			
			my $url_rewriting = get_url({nom_table=>'data_search_form',id_table=>$data_search_form{id}, id_language => $language{id}});
			my $url_rewriting_list_cat = get_url({nom_table=>'data_listcat_form',id_table=>$data_search_form{id}, id_language => $language{id}});
			
			my $nom_moteur  = get_traduction({debug=>0,id_language=>$language{id},id=>$data_search_form{id_textid_name}});
			
			
			my $htaccess_line = '';
			
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting_list_cat.'/(.*)/(.*)$ cgi-bin/data.pl?sw=list_cat&lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&id_father=${'.$mapname.':$1|NOTFOUND:$1!}'.'&id_cat_condition=${'.$mapname.':$2|NOTFOUND:$2!}&page=1';
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting_list_cat.'/(.*)/$ cgi-bin/data.pl?sw=list_cat&lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&id_father=${'.$mapname.':$1|NOTFOUND:$1!}&page=1';
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting_list_cat.'/(.*)$ cgi-bin/data.pl?sw=list_cat&lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&page=1';

			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting.'/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)$ cgi-bin/data.pl?lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&s1=${'.$mapname.':$1|NOTFOUND:$1!}&s2=${'.$mapname.':$2|NOTFOUND}&s3=${'.$mapname.':$3|NOTFOUND}&s4=${'.$mapname.':$4|NOTFOUND}&s5=${'.$mapname.':$5|NOTFOUND}&s6=${'.$mapname.':$6|NOTFOUND}&s7=${'.$mapname.':$7|NOTFOUND}&s8=${'.$mapname.':$8|NOTFOUND}&s9=${'.$mapname.':$9|NOTFOUND}&s10=${'.$mapname.':$10|NOTFOUND}&page=$11';
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting.'/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)$ cgi-bin/data.pl?lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&s1=${'.$mapname.':$1|NOTFOUND:$1!}&s2=${'.$mapname.':$2|NOTFOUND}&s3=${'.$mapname.':$3|NOTFOUND}&s4=${'.$mapname.':$4|NOTFOUND}&s5=${'.$mapname.':$5|NOTFOUND}&s6=${'.$mapname.':$6|NOTFOUND}&s7=${'.$mapname.':$7|NOTFOUND}&s8=${'.$mapname.':$8|NOTFOUND}&s9=${'.$mapname.':$9|NOTFOUND}&page=$10';
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting.'/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)$ cgi-bin/data.pl?lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&s1=${'.$mapname.':$1|NOTFOUND:$1!}&s2=${'.$mapname.':$2|NOTFOUND}&s3=${'.$mapname.':$3|NOTFOUND}&s4=${'.$mapname.':$4|NOTFOUND}&s5=${'.$mapname.':$5|NOTFOUND}&s6=${'.$mapname.':$6|NOTFOUND}&s7=${'.$mapname.':$7|NOTFOUND}&s8=${'.$mapname.':$8|NOTFOUND}&page=$9';
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting.'/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)$ cgi-bin/data.pl?lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&s1=${'.$mapname.':$1|NOTFOUND:$1!}&s2=${'.$mapname.':$2|NOTFOUND}&s3=${'.$mapname.':$3|NOTFOUND}&s4=${'.$mapname.':$4|NOTFOUND}&s5=${'.$mapname.':$5|NOTFOUND}&s6=${'.$mapname.':$6|NOTFOUND}&s7=${'.$mapname.':$7|NOTFOUND}&page=$8';
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting.'/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)$ cgi-bin/data.pl?lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&s1=${'.$mapname.':$1|NOTFOUND:$1!}&s2=${'.$mapname.':$2|NOTFOUND}&s3=${'.$mapname.':$3|NOTFOUND}&s4=${'.$mapname.':$4|NOTFOUND}&s5=${'.$mapname.':$5|NOTFOUND}&s6=${'.$mapname.':$6|NOTFOUND}&page=$7';
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting.'/(.*)/(.*)/(.*)/(.*)/(.*)/(.*)$ cgi-bin/data.pl?lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&s1=${'.$mapname.':$1|NOTFOUND:$1!}&s2=${'.$mapname.':$2|NOTFOUND}&s3=${'.$mapname.':$3|NOTFOUND}&s4=${'.$mapname.':$4|NOTFOUND}&s5=${'.$mapname.':$5|NOTFOUND}&page=$6';
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting.'/(.*)/(.*)/(.*)/(.*)/(.*)$ cgi-bin/data.pl?lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&s1=${'.$mapname.':$1|NOTFOUND:$1!}&s2=${'.$mapname.':$2|NOTFOUND}&s3=${'.$mapname.':$3|NOTFOUND}&s4=${'.$mapname.':$4|NOTFOUND}&page=$5';
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting.'/(.*)/(.*)/(.*)/(.*)$ cgi-bin/data.pl?lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&s1=${'.$mapname.':$1|NOTFOUND:$1!}&s2=${'.$mapname.':$2|NOTFOUND}&s3=${'.$mapname.':$3|NOTFOUND}&page=$4';
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting.'/(.*)/(.*)/(.*)$ cgi-bin/data.pl?lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&s1=${'.$mapname.':$1|NOTFOUND:$1!}&s2=${'.$mapname.':$2|NOTFOUND}&page=$3';
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting.'/(.*)/(.*)$ cgi-bin/data.pl?lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&s1=${'.$mapname.':$1|NOTFOUND:$1!}&page=$2';
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting.'/(.*)$ cgi-bin/data.pl?lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&page=$1';
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting.'/*$ cgi-bin/data.pl?lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&page=1';
			$htaccess_line .= "\n".'RewriteRule ^'.$url_rewriting.'$ cgi-bin/data.pl?lg='.$language{id}.'&id_data_family='.$data_family{id}.'&sf='.$data_search_form{id}.'&page=1';
			
			if($url_rewriting ne '')
			{
				write_file($tmp_htaccess,$htaccess_line);
				if($config{htaccess_2_for_page} > 0)
				{
					write_file($tmp_htaccess2,$htaccess_line);
				}	
				
				#ajouter des liens pour le listing sheets et le listing catégories
				
				#listing sheets
				
				#on s'assure que le lien existe
				my %update_migcms_link =
				(
					'link_table' => 'data_search_form',
					'link_type' => 'module',
					'link_id' => $data_search_form{id},
				);
				my $id_migcms_link = sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_links',data=>\%update_migcms_link, where=>"link_table='$update_migcms_link{link_table}' AND link_id = '$update_migcms_link{link_id}'"}); 
				my %migcms_link = read_table($dbh,'migcms_links',$id_migcms_link);
				
				#on met à jour les traductions
				set_traduction({id_language=>$language{id},traduction=>$nom_moteur,id_traduction=>$migcms_link{id_textid_link_name},table_record=>'migcms_links',col_record=>'id_textid_link_name',id_record=>$migcms_link{id}});
				set_traduction({id_language=>$language{id},traduction=>$url_rewriting,id_traduction=>$migcms_link{id_textid_link_url},table_record=>'migcms_links',col_record=>'id_textid_link_url',id_record=>$migcms_link{id}});
				
				#listing categories
				
				#on s'assure que le lien existe
				my %update_migcms_link =
				(
					'link_table' => 'data_search_form_cat',
					'link_type' => 'module',
					'link_id' => $data_search_form{id},
				);
				my $id_migcms_link = sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_links',data=>\%update_migcms_link, where=>"link_table='$update_migcms_link{link_table}' AND link_id = '$update_migcms_link{link_id}'"}); 
				my %migcms_link = read_table($dbh,'migcms_links',$id_migcms_link);
				
				#on met à jour les traductions
				set_traduction({id_language=>$language{id},traduction=>$nom_moteur.'( Catégories)',id_traduction=>$migcms_link{id_textid_link_name},table_record=>'migcms_links',col_record=>'id_textid_link_name',id_record=>$migcms_link{id}});
				set_traduction({id_language=>$language{id},traduction=>$url_rewriting_list_cat,id_traduction=>$migcms_link{id_textid_link_url},table_record=>'migcms_links',col_record=>'id_textid_link_url',id_record=>$migcms_link{id}});		
			}
		}
		log_debug("URLS moteurs OK $language{id}",'','do_build_pages');

		# see();

		# MODULES
		my @migcms_urls = sql_lines({dbh=>$dbh, table=>"migcms_urls", where=>"url_base != '' AND url_rewriting != '' AND id_lg = '$language{id}'"});
		foreach $migcms_urls (@migcms_urls)
		{
			my %migcms_urls = %{$migcms_urls};

			my $htaccess_line = "\nRewriteRule ^" .$migcms_urls{url_rewriting_htaccess}. " " .$migcms_urls{url_base};

			write_file($tmp_htaccess,$htaccess_line);
			if($config{htaccess_2_for_page} > 0)
			{
				write_file($tmp_htaccess2,$htaccess_line);
			}	
		}
		log_debug("URLS modules OK $language{id}",'','do_build_pages');
	}
	
	
	
	#test si le premiere page est un lien !
	if($migcms_setup{id_default_page} > 0)
	{
		my %test_page = read_table($dbh,'migcms_pages',$migcms_setup{id_default_page});
		if($test_page{migcms_pages_type} eq 'link')
		{
			my $url_reecrite = get_link_page({migcms_page=>\%test_page});
			my $htaccess_line = "\n".'RewriteRule ^$ '.$url_reecrite;
			write_file($tmp_htaccess,$htaccess_line);
		}
	}
	
	if($config{custom_data_sitemap_func} ne "")
	{
		my $func = 'def_handmade::'.$config{custom_data_sitemap_func};
		&$func($tmp_sitemap,$tmp_sitemap2);
	}
	else
	{
		fill_sitemap_with_data();
	}
	
	
	# if($config{htaccess_2_for_page} > 0)
	# {
		# fill_sitemap_with_data($tmp_htaccess2);
	# }	
	
		
	#remplace le dossier pages par le dossier temporaire
	use File::Path qw(make_path remove_tree);
	remove_tree($dossier_page_public);
	remove_tree($dossier_page_private);
	
	rename $dossier_page_public.$publish_token,$dossier_page_public;
	rename $dossier_page_private.$publish_token,$dossier_page_private;

	end_htaccess();
	end_sitemap();
	
	if($config{htaccess_2_for_page} > 0)
	{
		end_htaccess($tmp_htaccess2);
	}
	if($config{sitemap_2_for_page} > 0)
	{
		end_sitemap($tmp_sitemap2);
	}
	
	use File::Path qw(remove_tree rmtree);
	remove_tree( '../cache/site/data', {keep_root => 1} );

	if($config{custom_after_build_func} ne "")
	{
		my $custom_after_build_func = 'def_handmade::'.$config{custom_after_build_func};
		&$custom_after_build_func();		
	}

}


sub fill_sitemap_with_data
{
	# my $tmp_htaccess2 = $_[0];
	fill_sitemap_details($tmp_htaccess2);
	fill_sitemap_searchs($tmp_htaccess2);
}

sub fill_sitemap_details
{
	# my $tmp_htaccess2 = $_[0];
	
	my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible='y'"});
	my @data_sheets = sql_lines({dbh=>$dbh,select=>"sh.*",table=>"data_sheets sh, data_families f",where=>"f.in_sitemap = 'y' AND sh.visible='y' AND sh.id_data_family=f.id"});
	my $extlink = 1;
	my $tmp_sitemap = '../sitemap_'.$publish_token.'.xml';

	foreach $data_sheet(@data_sheets)
	{
		my %data_sheet = %{$data_sheet};
		foreach $language (@languages)
		{
			my %language = %{$language};
			my $url = data::get_data_detail_url($dbh,\%data_sheet,$language{id},$extlink,'y');
			my ($date,$time) = split(/ /,$data_sheet{migcms_moment_last_edit});
			my ($yyyy,$mm,$dd) = split (/-/,$date); 
			if(!($yyyy > 0 && $mm > 0 && $dd > 0))
			{
				($date,$time) = split(/ /,$page{migcms_moment_create});
			}

			my $sitemap_line = <<"EOH";
			 <url>
				<loc>$url</loc>
				<lastmod>$date</lastmod>
			 </url>
EOH
			write_file($tmp_sitemap,$sitemap_line);
		}
	}
}

sub fill_sitemap_searchs
{
	# my $tmp_htaccess2 = $_[0];
	
	my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible='y'"});
	my @data_searchs = sql_lines({dbh=>$dbh,selet=>"",table=>"data_searchs",where=>"id_father_cat > 0 AND in_sitemap = 'y'"});
	my @data_search_forms = sql_lines({dbh=>$dbh,selet=>"",table=>"data_search_forms",where=>"in_sitemap = 'y'"});
	my $extlink = 1;
	my $tmp_sitemap = '../sitemap_'.$publish_token.'.xml';
	
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year+=1900;
	$mon++;
	
	if($mon < 10)
	{
		$mon = '0'.$mon;
	}
	if($mday < 10)
	{
		$mday = '0'.$mday;
	}
	my $today = $year.'-'.$mon.'-'.$mday;
		
	foreach $language (@languages)
	{
		my %language = %{$language};
		foreach $data_search_form(@data_search_forms)
		{
			my %data_search_form = %{$data_search_form};		
			my $data_url = data::get_data_url({lg=>$language{id},params=>'',reset=>'n',sf=>$data_search_form{id},number_page=>1,nr=>$data_family{family_nr},from=>'fill_sitemap_searchs'});
			log_debug("$data_url = data::get_data_url({params=>'',reset=>'n',sf=>$data_search_form{id},number_page=>1,nr=>$data_family{family_nr},from=>'fill_sitemap_searchs'});",'','debug_sitemap');
			$data_url =~ s/^\///g;
			
			my $url_sans_cat_sans_search = $config{fullurl}.'/'.$data_url;
			log_debug('url_sans_cat_sans_search:'.$url_sans_cat_sans_search,'','debug_sitemap');
			my ($date,$time) = split(/ /,$data_sheet{migcms_moment_last_edit});
			my ($yyyy,$mm,$dd) = split (/-/,$date); 
			if(!($yyyy > 0 && $mm > 0 && $dd > 0))
			{
			($date,$time) = split(/ /,$page{migcms_moment_create});
			}
			
			
			
			my $sitemap_line = <<"EOH";
				<url>
				<loc>$url_sans_cat_sans_search</loc>
				<lastmod>$today</lastmod>
				</url>
EOH
			write_file($tmp_sitemap,$sitemap_line);
		}
	}

	foreach $data_search(@data_searchs)
	{
		my %data_search = %{$data_search};
		
		my %sf = read_table($dbh,'data_search_forms',$data_search{id_data_search_form});
		my %data_family = read_table($dbh,'data_search_forms',$sf{id_data_family});
		my @data_categories = sql_lines({dbh=>$dbh,selet=>"",table=>"data_categories",where=>"id_father = '$data_search{id_father_cat}' "});
		
		# my $url_sans_cat = $config{fullurl}.'/'.data::get_data_url({params=>'',reset=>'n',sf=>$data_search{id_data_search_form},number_page=>1,nr=>$data_family{family_nr},from=>'fill_sitemap_searchs'});
		# log_debug('url_sans_cat:'.$url_sans_cat,'','debug_sitemap');
		# my ($date,$time) = split(/ /,$data_sheet{migcms_moment_last_edit});
		# my ($yyyy,$mm,$dd) = split (/-/,$date); 
		# if(!($yyyy > 0 && $mm > 0 && $dd > 0))
		# {
		# ($date,$time) = split(/ /,$page{migcms_moment_create});
		# }

		# my $sitemap_line = <<"EOH";
		# <url>
		# <loc>$url_sans_cat</loc>
		# <lastmod>$today</lastmod>
		# </url>
# EOH
		# write_file($tmp_sitemap,$sitemap_line);

		foreach $language (@languages)
		{
			my %language = %{$language};
			
			foreach $data_category (@data_categories)
			{
				my %data_category = %{$data_category};
				my $url = $config{fullurl}.data::get_data_url({lg=>$language{id},params=>'',reset=>'n',sf=>$data_search{id_data_search_form},number_page=>1,id_father_categorie=>$data_category{id},nr=>$data_family{family_nr},from=>'fill_sitemap_searchs'});

				my ($date,$time) = split(/ /,$data_sheet{migcms_moment_last_edit});
				my ($yyyy,$mm,$dd) = split (/-/,$date); 
				if(!($yyyy > 0 && $mm > 0 && $dd > 0))
				{
					($date,$time) = split(/ /,$page{migcms_moment_create});
				}

				my $sitemap_line = <<"EOH";
				 <url>
					<loc>$url</loc>
					<lastmod>$today</lastmod>
				 </url>
EOH
				write_file($tmp_sitemap,$sitemap_line);
			}
		}
	}
}



			
sub init_htaccess
{
	my $alt_path = $_[1];
	
   my %migcms_setup = sql_line({debug=>0,debug_results=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
my %data_setup = sql_line({debug=>0,debug_results=>0,table=>"data_setup",select=>'',where=>"",limit=>'0,1'});

 

	
	

	
	
	
	my $tmp_token = "../.htaccess_".$publish_token;
 
  if($alt_path ne '')
	{
	$tmp_token = "../.htaccess2_".$publish_token;
	}
 
	reset_file($tmp_token);
 
 
	my $migcms_url_rewrite = '';
	if(-e "../cgi-bin/migcms_url_rewrite.dat")
	{
		$migcms_url_rewrite = get_file("../cgi-bin/migcms_url_rewrite.dat");
	}
 
	my $htaccess_options = '';
	if(-e "../skin/htaccess_options.txt")
	{
		$htaccess_options = get_file("../skin/htaccess_options.txt");
	}
	
	my $htaccess_options_rewrite_domains = '';
	if(-e "../skin/htaccess_options_rewrite_domains.txt")
	{
		$htaccess_options_rewrite_domains = get_file("../skin/htaccess_options_rewrite_domains.txt");
	}
	
	my $htaccess_ssl = $config{rewrite_ssl};
	my $htaccess_ssl_rewrite = "";
	my $htaccess_protocol_rewrite = "http";
	if($htaccess_ssl eq 'y' && $config{rewrite_ssl_noconfig} ne 'y') 
	{
	 	$htaccess_protocol_rewrite = "https";
		$htaccess_ssl_rewrite = <<"EOH";
RewriteCond %{SERVER_PORT} 80
RewriteRule ^(.*)\$ $htaccess_protocol_rewrite://$config{rewrite_host}$config{rewrite_base}\$1 [L,R=301]
EOH
	}

	my $r404_url = $config{rewrite_base};
	my $r404_url2 = $config{rewrite_base};
	if($migcms_setup{id_notfound_page} > 0) 
	{
		my $url_rewriting = get_url({debug=>0,debug_results=>0,nom_table=>'migcms_pages',id_table=>$migcms_setup{id_notfound_page}, id_language => $language{id}});
		$r404_url = $config{baseurl}.'/'.$url_rewriting;
	}
	if($config{id_page_404_for_htaccess2} > 0) 
	{
		my $url_rewriting = get_url({debug=>0,debug_results=>0,nom_table=>'migcms_pages',id_table=>$config{id_page_404_for_htaccess2}, id_language => $language{id}});
		$r404_url2 = $config{baseurl}.'/'.$url_rewriting;
	}

	my $rewrite_redir_301 = <<"EOH";
RewriteCond %{HTTP_HOST} !^$config{rewrite_host}\$ [NC]
RewriteRule ^(.*)\$ $htaccess_protocol_rewrite://$config{rewrite_host}$config{rewrite_base}\$1 [L,R=301]
EOH

	if($config{rewrite_redir_301} ne 'y')
	{
		$rewrite_redir_301 = '';
	}
	
	my $secure_data = 'RewriteCond %{HTTP_COOKIE} '.$config{front_cookie_name}.'=([^;]+)'."\n";

	if($data_setup{secure_data} ne 'y')
	{
		$secure_data = '';
	}	
	
	my $data_cache = $secure_data;
	$data_cache .= <<'EOH';
RewriteCond %{DOCUMENT_ROOT}/cache/site/data/list/%{REQUEST_URI}.html -f
RewriteRule ^(.*)$ cache/site/data/list/%{REQUEST_URI}.html [L,E=NOCACHE:1]
EOH
	
	$data_cache .= $secure_data;
	$data_cache .= <<'EOH';
RewriteCond %{DOCUMENT_ROOT}/cache/site/data/list/%{REQUEST_URI}/1.html -f
RewriteRule ^(.*)$ cache/site/data/list/%{REQUEST_URI}/1.html [L,E=NOCACHE:1]
EOH
	$data_cache .= $secure_data;
	$data_cache .= <<'EOH';
RewriteCond %{DOCUMENT_ROOT}/cache/site/data/detail/%{REQUEST_URI}.html -f
RewriteRule ^(.*)$ cache/site/data/detail/%{REQUEST_URI}.html [L,E=NOCACHE:1]
EOH

	if($data_setup{use_data_cache} ne 'y')
	{
		$data_cache = '';
	}
	
	my $line_404 =<<"EOH";
ErrorDocument 404 $r404_url
EOH

	if($alt_path ne '' && $config{id_page_404_for_htaccess2} > 0)
	{
			$line_404 =<<"EOH";
		ErrorDocument 404 $r404_url2
EOH
	}
	
	
     my $htaccess_header = <<"EOH";
$htaccess_options


<IfModule mod_rewrite.c>

RewriteEngine On
RewriteBase $config{rewrite_base}
$htaccess_ssl_rewrite

$rewrite_redir_301

$line_404

$htaccess_options_rewrite_domains

$data_cache

$migcms_url_rewrite
EOH
   write_file($tmp_token,$htaccess_header);
}


sub end_htaccess
{
	my $alt_path = $_[0];
	my $tmp_token = "../.htaccess_".$publish_token;
	if($alt_path ne '')
	{
		$tmp_token = "../.htaccess2_".$publish_token;
	}
	my $ok = "../.htaccess";
	if($alt_path ne '')
	{
		$ok = "../.htaccess2";
	}
	
	my $htaccess_options_rewrite = '';
	if(-e "../skin/htaccess_options_rewrite.txt")
	{
		$htaccess_options_rewrite = get_file("../skin/htaccess_options_rewrite.txt");
	}
	
	my $htaccess_footer = <<"EOH";
	
	$htaccess_options_rewrite
</IfModule>
EOH
	write_file($tmp_token,$htaccess_footer);

	#publish htaccess
	`rm -f $ok`;
	`mv $tmp_token $ok`;  
}

sub init_sitemap
{
	 my $alt_path = $_[0];
	
   
 

	
	
	
	my $tmp_sitemap = '../sitemap_'.$publish_token.'.xml';
	my $ok_sitemap = '../sitemap.xml';;
	
	 if($alt_path ne '')
	{
$tmp_sitemap = '../sitemap2_'.$publish_token.'.xml';
	 $ok_sitemap = '../sitemap2.xml';;
	}
	
	# reset_file($ok_sitemap);

     my $xmlsitemap_header = <<"EOX";
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
EOX
    write_file($tmp_sitemap,$xmlsitemap_header);
}

sub end_sitemap
{
   see();
   
   my $alt_path = $_[0];
	
   
 my $xmlsitemap_footer = "\n</urlset>";
 my $tmp_sitemap = '../sitemap_'.$publish_token.'.xml';
 my $ok_sitemap = '../sitemap.xml';
 
 if($alt_path ne '')
	{
		$tmp_sitemap = '../sitemap2_'.$publish_token.'.xml';
  $ok_sitemap = '../sitemap2.xml';
	}
 
 write_file($tmp_sitemap,$xmlsitemap_footer);
 
 #publish sitemap
 `rm -f $ok_sitemap`;
 `mv $tmp_sitemap $ok_sitemap`;  
}


sub migcms_build_compute_urls
{
	log_debug('migcms_build_compute_urls','vide','migcms_build_compute_urls');
	$stmt = "TRUNCATE `migcms_urls` ";
	$cursor = $dbh->prepare($stmt);
	$rc = $cursor->execute;

	#construit les URLS rew dans la DB
	my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible='y'"});
	foreach $language (@languages)
	{
		my %language = %{$language};

		#URL FORCEES****************************************************************************************************
		my @migcms_pages = sql_lines({debug=>0,debug_results=>0,table=>'migcms_pages',where=>"id IN (select id_table from migcms_force_urls where nom_table='migcms_pages')",ordby=>"id"});
		foreach $page (@migcms_pages)
		{
			my %page = %{$page};
			log_debug('LIGNE 887: $page{id}'.$page{id},'','migcms_build_compute_urls');
			
			my %url_forcee = sql_line({table=>'migcms_force_urls',where=>"nom_table='migcms_pages' AND id_table='$page{id}' AND id_lg='1'"});
			my $texte_url = $url_forcee{url_rewriting};
			set_traduction({id_language=>$language{id},traduction=>$texte_url,id_traduction=>$page{id_textid_url},table_record=>'migcms_pages',col_record=>'id_textid_url',id_record=>$page{id}});

			#on forme la nouvelle url: langue / url
			my $url_rewriting = $language{name}.'/'.$texte_url;
			log_debug('$url_rewriting'.$url_rewriting,'','migcms_build_compute_urls');
			save_url($url_rewriting,'migcms_pages',$page{id},$texte_url,\%language);
		}
		
		#PAGES VISIBLES ET PAS SPECIALES****************************************************************************************************
		my @migcms_pages = sql_lines({debug=>0,debug_results=>0,table=>'migcms_pages',where=>"id NOT IN (select id_table from migcms_force_urls where nom_table='migcms_pages') AND visible='y' AND migcms_pages_type != 'newsletter' AND migcms_pages_type != 'link' AND migcms_pages_type != 'block' AND migcms_pages_type != 'handmade' AND migcms_pages_type != 'directory'",ordby=>"id"});
		foreach $page (@migcms_pages)
		{
			my %page = %{$page};
			log_debug('LIGNE 886: $page{id}'.$page{id},'','migcms_build_compute_urls');
			my $texte_url = get_traduction({debug=>0,id=>$page{id_textid_url_words},id_language=>$language{id}});
			if($texte_url eq '')
			{
				$texte_url = get_traduction({debug=>0,id=>$page{id_textid_name},id_language=>$language{id}});
				if($texte_url eq '')
				{
					$texte_url = $page{id}.'_'.$language{id};
				}
			}
			$texte_url =~ s/p\-invisible\///g;
			set_traduction({id_language=>$language{id},traduction=>$texte_url,id_traduction=>$page{id_textid_url},table_record=>'migcms_pages',col_record=>'id_textid_url',id_record=>$page{id}});

			#on forme la nouvelle url: langue / url
			my $url_rewriting = $language{name}.'/'.$texte_url;
			log_debug('$url_rewriting'.$url_rewriting,'','migcms_build_compute_urls');
			save_url($url_rewriting,'migcms_pages',$page{id},$texte_url,\%language);
		}
		
		#PAGES INVISIBLES ET AUTRES****************************************************************************************************
		my @migcms_pages = sql_lines({debug=>0,debug_results=>0,table=>'migcms_pages',where=>"id NOT IN (select id_table from migcms_force_urls where nom_table='migcms_pages') AND visible !='y' OR migcms_pages_type = 'newsletter' OR migcms_pages_type = 'link' OR migcms_pages_type = 'block' OR migcms_pages_type = 'handmade' OR migcms_pages_type = 'directory'",ordby=>"id"});
		foreach $page (@migcms_pages)
		{
			my %page = %{$page};
			log_debug('INV: $page{id}'.$page{id},'','migcms_build_compute_urls');
			my $texte_url = get_traduction({debug=>0,id=>$page{id_textid_url_words},id_language=>$language{id}});
			$texte_url =~ s/p\-invisible\///g;
			if($texte_url eq '')
			{
				$texte_url = get_traduction({debug=>0,id=>$page{id_textid_name},id_language=>$language{id}});
				if($texte_url eq '')
				{
					$texte_url = 'p-invisible/'.$page{id}.'_'.$language{id};
				}
				else
				{
					$texte_url = 'p-invisible/'.$texte_url;
				}
			}
			else
			{
				$texte_url = 'p-invisible/'.$texte_url;
			}
			
			set_traduction({id_language=>$language{id},traduction=>$texte_url,id_traduction=>$page{id_textid_url},table_record=>'migcms_pages',col_record=>'id_textid_url',id_record=>$page{id}});

			#on forme la nouvelle url: langue / url
			my $url_rewriting = $language{name}.'/'.$texte_url;
			log_debug('$url_rewriting'.$url_rewriting,'','migcms_build_compute_urls');
			save_url($url_rewriting,'migcms_pages',$page{id},$texte_url,\%language);
		}

		# FAMILLES + MOTEURS ****************************************************************************************************
		my @data_families = sql_lines({table=>'data_families',where=>""});
		foreach my $data_family (@data_families)
		{
			my %data_family = %{$data_family};

			my @data_search_forms = sql_lines({debug=>0,debug_results=>0,table=>'data_search_forms',where=>"id_data_family='$data_family{id}'"});
			foreach my $data_search_form (@data_search_forms)
			{
				%data_search_form = %{$data_search_form};
				($texte_url_moteur,$dum) = get_textcontent($dbh,$data_search_form{id_textid_url_rewriting},$language{id});
				if($texte_url_moteur ne '')
				{
					my $url_rewriting = $language{name}.'/'.$texte_url_moteur;
					save_url($url_rewriting,'data_search_form',$data_search_form{id},$texte_url_moteur,\%language);
					my $url_rewriting = $language{name}.'/categories/'.$texte_url_moteur;
					save_url($url_rewriting,'data_listcat_form',$data_search_form{id},$texte_url_moteur,\%language);
				}
			}
		}

		# CATEGORIES ****************************************************************************************************
		my @data_categories = sql_lines({table=>'data_categories',where=>""});
		foreach my $data_category (@data_categories)
		{
			my %data_category = %{$data_category};

			($texte_cat,$dum) = get_textcontent($dbh,$data_category{id_textid_url_rewriting},$language{id});
			if($texte_cat ne '')
			{
				my $url_rewriting = $texte_cat;
				save_url($url_rewriting,'data_categories',$data_category{id},$texte_cat,\%language);
			}
		}
		
		#URLS COMMUNES SYNCHRONISEES (boutique,membres,...)
		my @migcms_urls_commons = sql_lines({debug=>0,debug_results=>0,select=>"u.*,l.*,l.id as id_language,u.id as id_url",table=>'migcms_urls_common u,migcms_languages l',where=>"u.id_language=l.id"});
		foreach my $migcms_urls_common (@migcms_urls_commons)
		{
				my %migcms_urls_common = %{$migcms_urls_common};
				
				#fr/boutique/fin/succes
				my $url_rewriting = $migcms_urls_common{name}.'/'.$migcms_urls_common{url_rewriting};
				
				#fr/boutique/fin/succes/*(.*)
				my $url_rewriting_htaccess = $migcms_urls_common{name}.'/'.$migcms_urls_common{url_rewriting}.'/*(.*)';
				
				#cgi-bin/eshop.pl?sw=end&lg=1&status=success&token=$1
				my $url_base = $migcms_urls_common{url};
				
				my %language = ();
				$language{id} = $migcms_urls_common{id_language};
				
				if($url_rewriting ne '' && $url_rewriting_htaccess ne '' && $url_base ne '')
				{
					save_url($url_rewriting,'migcms_urls_common',$migcms_urls_common{id_url},$url_rewriting,\%language,$url_rewriting_htaccess,$url_base);
				}
		}
	}
	log_debug('migcms_build_compute_urls OK','','migcms_build_compute_urls');
}



sub save_url
{
	my $url_rewriting = $_[0];
	my $nom_table = $_[1];
	my $id_table = $_[2];
	my $texte_url = $_[3];
	my %language = %{$_[4]};
	
	my $url_rewriting_htaccess = $_[5];
	my $url_base = $_[6];
	
	$url_rewriting = clean_url($url_rewriting,'y');

	

	
	# boucle pour éviter doublons d'url
	#convenu avec alain de ne plus générer de suffixe meme si deux urls identiques car il préfere qu'une page ne soit pas affichée plutot que d'avoir une url changeante
	#->ilfaut activer le controle des urls sous peine d'erreur 500 lors de la publication car contrainte UNIQUE De l'url. On perdrait donc l'intéret de centraliser et calculer les urls...
	my $new_url_rewriting = $url_rewriting;
	if($config{disable_page_suffix} ne 'y')
	{
		# if($nom_table ne 'migcms_pages')
		# {

			log_debug("Vérifie si une URL existe déjà pour la table $nom_table, un autre ID que $id_table et avec le texte $url_rewriting et langue $language{id}",'','durl');


			my %check_url = sql_line({debug=>1,debug_results=>1,table=>'migcms_urls',where=>"nom_table = '$nom_table' AND id_table != '$id_table' AND url_rewriting='$url_rewriting' AND id_lg = '$language{id}'"});
			if(!($check_url{id}>0))
			{
				log_debug("NON Il n'y a pas d'URL $url_rewriting pour la table $nom_table, un autre ID que $id_table et avec le texte $new_url_rewriting et langue $language{id}",'','durl');

			}
			my $suffix = 2;
			while($check_url{id} > 0)
			{
				log_debug("OUI une URL existe déjà pour la table $nom_table, un autre ID que $id_table et avec le texte $url_rewriting",'','durl');

				$new_url_rewriting = $url_rewriting.$suffix;
				log_debug("Nouvelle URL: $new_url_rewriting",'','durl');

				%check_url = sql_line({debug=>1,debug_results=>1,table=>'migcms_urls',where=>"nom_table = '$nom_table' AND id_table != '$id_table' AND url_rewriting='$new_url_rewriting'"});

				log_debug("OUI2 une URL existe déjà pour la table $nom_table, un autre ID que $id_table et avec le texte $new_url_rewriting",'','durl');

				$suffix++;
			}
		# }
	}
	
	#maj de l'url
	my %migcms_url =
	(
		'nom_table' => $nom_table,
		'id_table' => $id_table,
		'id_lg' => $language{id},
		'words' => $texte_url,
		'url_rewriting' => $new_url_rewriting,
	);

	log_debug("Maj de l'URL $new_url_rewriting pour la table $nom_table, un autre ID que $id_table et avec le texte $new_url_rewriting et LG $migcms_url{id_lg}",'','durl');


	$migcms_url{words}  =~ s/\'/\\\'/g;
	
	if($url_rewriting_htaccess ne '')
	{
		$migcms_url{url_rewriting_htaccess} = $url_rewriting_htaccess;
	}
	if($url_base ne '')
	{
		$migcms_url{url_base} = $url_base;
	}

	sql_set_data({debug=>1,dbh=>$dbh,table=>'migcms_urls',data=>\%migcms_url, where=>"nom_table='$migcms_url{nom_table}' AND id_table='$migcms_url{id_table}'  AND id_lg='$migcms_url{id_lg}'"});
}

1;