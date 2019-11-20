#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Package de la librairie
# see();
package migcrender;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

@ISA = qw(Exporter);	#Permet l'export
@EXPORT = qw(
render_page
render_parag
render_block_zone
render_block
render_block_pic
render_tags
render_tags_lnk
get_obj_name
is_page_protected
get_link_page
error_404
);
 
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use def;
use tools;
use sitetxt;
use setup;
use data;  
use eshop;
use JSON::XS;
use URI::Escape;
use def_handmade;
# use Data::Dumper;
use forms;


my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
my $one_language_site = 1;
my %nb_languages_site = sql_line({table=>'migcms_languages',select=>"COUNT(*) as nb",where=>"visible='y'"});
if($nb_languages_site{nb} > 1)
{
	$one_language_site = 0;
}
	

################################################################################
# render_page
################################################################################
sub render_page
{
	my %d = %{$_[0]};
	my %data_family = %{$d{data_family}};
	$d{debug} = 0;

	my $template = '';
	
	my $global_lg = $lg || $d{lg} || get_quoted('lg') || $config{current_language};
   
   my $infos_cms = << "EOH";
<input type="hidden" name="global_lg" class="global_lg" value="$global_lg" />
<input type="hidden" name="force_id_tpl_page" class="force_id_tpl_page" value="$d{force_id_tpl_page}" />
EOH

	my %page = ();
	if(!($d{id} > 0))
	{
		#si rendu page normale
		
		if($d{force_id_tpl_page} > 0)
		{
			$d{id_tpl_page} = $d{force_id_tpl_page};
		}
		

		$template = get_template({debug=>$d{debug},id=>$d{id_tpl_page},lg=>$d{lg}});
		
		if($d{force_content} ne "")
		{
			$template = render_tags({full_url=>$d{full_url},type_page => $d{type_page},token_membre=>$d{token_membre},mailing=>$d{mailing},force_content=>$d{force_content},template=>$template,lg=>$d{lg},data_family=>\%data_family});
		}
		else
		{
			$template = render_tags({full_url=>$d{full_url},type_page => $d{type_page},token_membre=>$d{token_membre},mailing=>$d{mailing},content=>$d{content},template=>$template,lg=>$d{lg},data_family=>\%data_family});
		}
	}
    else
	{	
		#si rendu page cms
		%page = sql_line({debug=>$d{debug},debug_results=>$d{debug},table=>'migcms_pages',where=>"id='$d{id}'"});
		
		if($d{force_id_tpl_page} > 0)
		{
			$page{id_tpl_page} = $d{force_id_tpl_page};
		}
		
		if($page{migcms_pages_type} eq 'link')
		{
			my %migcms_link = read_table($dbh,'migcms_links',$page{id_migcms_link});
			($url,$dum) = get_textcontent($dbh,$migcms_link{id_textid_link_url},$d{lg});
		
			 $_ = $url;
			if(/^http/)
			{				
			}
			elsif($url ne '')
			{
				$url = $config{baseurl}.'/'.$url;				
			}

			if($d{preview} eq "y")
			{
				http_redirect($url);
			}
			else
			{
				cgi_redirect($url);		
			}

			exit;
		}
		else 
		#elsif($page{migcms_pages_type} eq 'page' || $page{migcms_pages_type} eq 'newsletter')
		{
			if($d{block} eq "y") {
				$template = "<MIGC_PAGECONTENT_HERE>";
			}
			else {
				$template = get_template({debug=>$d{debug},id=>$page{id_tpl_page},lg=>$d{lg}});
			}
			$template = render_tags({full_url=>$d{full_url},type_page => $d{type_page},token_membre=>$d{token_membre},mailing=>$d{mailing},debug=>$d{debug},template=>$template,id_page=>$page{id},lg=>$d{lg},preview=>$d{preview},edit=>$d{edit},force_content=>$d{force_content},data_family=>\%data_family});
			
			#js si edition wysiwyg
			if($d{edit} eq 'y')
			{
				my $edit_js =<<"EOH";
				
	<script src="/mig_skin/js/ohsnap.js"></script>
	<script src="/mig_skin/tinymce/tinymce.min.js"></script>
	<script src="/mig_skin/tinymce/jquery.tinymce.min.js"></script>
	<script src="/mig_skin/tinymce/langs/fr_FR.js"></script>  
	<script src="/mig_skin/js/mig_edit.js"></script>
	<style>
	/* ALERTS */
	/* inspired by Twitter Bootstrap */

	.alert {
	padding: 15px;
	margin-bottom: 20px;
	border: 1px solid #eed3d7;
	border-radius: 4px;
	position: absolute;
	top: 10px;
	right: 10px;
	/* Each alert has its own width */
	}

	.alert-red {
	color: white;
	background-color: #ff0000;
	}
	.alert-green {
	color: white;
	background-color: #41cac0;
	}
	</style>
EOH

				my $balise_script = 'async defer></script>';
				my $balise_script_clean = '></script>';
				$template =~ s/$balise_script/$balise_script_clean$edit_js /g;

				my $balise_body = '</body>';
				my $edit_body = '<div id="ohsnap"></div>';
				$template =~ s/$balise_body/$edit_body $balise_body /g;
			}
		}
	}
	my $balise_body = '</body>';
	my $input_cookie = '<input type="hidden" id="cookie_front" value="'.$config{front_cookie_name}.'" />';
	$template =~ s/$balise_body/$input_cookie $balise_body/g;
	$template =~ s/\<\/body\>/$infos_cms\<\/body\>/g;
	
	#my $url_login = "$config{fullurl}/cgi-bin/members.pl?sw=member_login_db&stoken=<MQD_DATA1_HERE>&url_after_login=";
	
	
	#paramètre URL: soit la full, soit l'url sélectionnée pour le mailing si multisite
	my $full_url_param = $config{fullurl}.$page{mailing_basehref};
	if($page{mailing_basehref} > 0)
	{
		#recupere url configurée
		my %rec_config = read_table($dbh,'config',$page{mailing_basehref});
		$full_url_param = $rec_config{varvalue};
	}
	$full_url_param = $1 if($full_url_param=~/(.*)\/$/); #retire le dernier slash
	
	
	my $url_login = "$full_url_param/$sitetxt{member_url_autoconnect}/<MQD_DATA1_HERE>/?url=";
	my $tracking_url = $page{tracking_url};
	$tracking_url =~ s/\&/\@SEP_EXT\@/g;
	
	if($d{mailing} eq 'y' && $page{migcms_pages_type} eq 'newsletter' && $page{mailing_alt_html} ne '')
	{
		return $page{mailing_alt_html};
	}
	
	my $tpl2 = $template;
		
	if($d{mailing} eq 'y' && $config{disable_autoconnexion} ne 'y' && $page{mailing_autoconnect} eq 'y')
	{
		while ($template =~ m/href\s*=\s*"([^"\s]+)"/gi) 
		{
		  my $url = $1;
		  
		  if($url !~ /member_mailing_unsubscribe_db/ && $url !~ /UNSUBSCRIBE/ && $url !~ /MAILER/)
		  {		  
			  my $url_avec_login = $url_login.$tracking_url.$url;
			  $url =~ s/\?/\\\?/g;
			  $tpl2 =~ s/href\s*=\s*\"$url\"/href=\"$url_avec_login\"/g;
		  }
		}
			
		if($config{mqd_data1_preview} ne '' && $d{preview} eq "y")
		{
			$tpl2 =~ s/\<MQD_DATA1_HERE\>/$config{mqd_data1_preview}/g;
		}
	}
	
	
    return $tpl2;
}

################################################################################
# render_parag
################################################################################
sub render_parag
{
	my %d = %{$_[0]};

    $d{lg} = $d{colg} || $d{lg};
    
    if($d{parag}{id} > 0)
	{
		%parag = %{$d{parag}};
	}
	else
	{
		%parag = read_table($dbh,'parag',$d{id});
	}

	if($parag{handmade_type} ne '' && $parag{handmade_id} > 0)
	{
		my $func = 'def_handmade::'.'parag_rendu_'.$parag{handmade_type};
		return &$func({parag=>\%parag,d=>\%d,mode=>'migcrender'});
		exit;
	}
	
	 my %template = read_table($dbh,'templates',$parag{id_template});

	($title_content,$dum) = get_textcontent($dbh,$parag{id_textid_title},$d{lg});
	($parag_content,$dum) = get_textcontent($dbh,$parag{id_textid_parag},$d{lg});
	($text1,$dum) = get_textcontent($dbh,$parag{id_textid_text_1});
	($text2,$dum) = get_textcontent($dbh,$parag{id_textid_text_2});
	($text3,$dum) = get_textcontent($dbh,$parag{id_textid_text_3});
	($text4,$dum) = get_textcontent($dbh,$parag{id_textid_text_4});
	($textwysiwyg1,$dum) = get_textcontent($dbh,$parag{id_textid_textwysiwyg_1});
	($textwysiwyg2,$dum) = get_textcontent($dbh,$parag{id_textid_textwysiwyg_2});
	($textwysiwyg3,$dum) = get_textcontent($dbh,$parag{id_textid_textwysiwyg_3});
	($textwysiwyg4,$dum) = get_textcontent($dbh,$parag{id_textid_textwysiwyg_4});

	if($d{edit} eq 'y')
	{
		$title_content = '<span class="mig_parag_title_content" data-idcontent="'.$parag{id_textid_title}.'" data-lg="'.$d{lg}.'">'.$title_content.'</span>';
		$parag_content = '<span class="mig_parag_content" data-idcontent="'.$parag{id_textid_parag}.'" data-lg="'.$d{lg}.'">'.$parag_content.'</span>';
	}

	# Garder les < et > des balises MIGC pour le render_tags
	$parag_content =~ s/\&lt;/</g;	
	$parag_content =~ s/\&gt;/>/g;
	
	$text1 =~ s/\&lt;/</g;	
	$text1 =~ s/\&gt;/>/g;
	$text2 =~ s/\&lt;/</g;	
	$text2 =~ s/\&gt;/>/g;
	$text3 =~ s/\&lt;/</g;	
	$text3 =~ s/\&gt;/>/g;
	$text4 =~ s/\&lt;/</g;	
	$text4 =~ s/\&gt;/>/g;
	$textwysiwyg1 =~ s/\&lt;/</g;	
	$textwysiwyg1 =~ s/\&gt;/>/g;
	$textwysiwyg2 =~ s/\&lt;/</g;	
	$textwysiwyg2 =~ s/\&gt;/>/g;
	$textwysiwyg3 =~ s/\&lt;/</g;	
	$textwysiwyg3 =~ s/\&gt;/>/g;
	$textwysiwyg4 =~ s/\&lt;/</g;	
	$textwysiwyg4 =~ s/\&gt;/>/g;
	
	


	$template{template} =~ s/<MIGC_PARAGID_HERE>/$parag{id}/g; 
	$template{template} =~ s/<MIGC_PARAGTITLE_HERE>/$title_content/g; 
	$template{template} =~ s/<MIGC_PARAGCONTENT_HERE>/$parag_content/g; 
	$template{template} =~ s/<MIGC_PARAGID_HERE>/$d{id}/g; 
	$template{template} =~ s/<MIGC_PARAGTEXT1_HERE>/$text1/g; 
	$template{template} =~ s/<MIGC_PARAGTEXT2_HERE>/$text2/g; 
	$template{template} =~ s/<MIGC_PARAGTEXT3_HERE>/$text3/g; 
	$template{template} =~ s/<MIGC_PARAGTEXT4_HERE>/$text4/g; 
	$template{template} =~ s/<MIGC_PARAGCONTENT1_HERE>/$textwysiwyg1/g; 
	$template{template} =~ s/<MIGC_PARAGCONTENT2_HERE>/$textwysiwyg2/g; 
	$template{template} =~ s/<MIGC_PARAGCONTENT3_HERE>/$textwysiwyg3/g; 
	$template{template} =~ s/<MIGC_PARAGCONTENT4_HERE>/$textwysiwyg4/g; 
	
	
	# print "[$template{template}]";

	# Rendu des autres TAGS
	$template{template} = render_parag_other_tags({full_url=>$d{full_url},parag=>\%parag, table_name=>"parag", template=>$template{template}, lg=>$d{lg}});	
	
	$_ = $template{template};
	my @forms = (/<MIGC_FORMS_(\w+)_HERE>/g);
	for (my $i = 0; $i<=$#forms; $i++ ) 
	{
		if ($forms[$i] > 0) 
		{
			my $id_form = $forms[$i];
			$pat = "<MIGC_FORMS_".$id_form."_HERE>";
			($title_content,$html_form,$id_template_page) = forms::form_get(
			{
				id_form => $id_form,
				token => '',
				step  => 1,
				colg => $lg,
			});
			$template{template} =~ s/$pat/$html_form/g;
		}
	}
	
	$_ = $template{template};
	my @tblocks = (/<MIGC_T(\w+)BLOCKS_HERE>/g);
	for (my $i = 0; $i<=$#tblocks; $i++ ) 
	{
		if ($tblocks[$i] > 0) 
		{
			my $id_blocktype = $tblocks[$i];
			$pat = "<MIGC_T".$id_blocktype."BLOCKS_HERE>";
			my $html_block = render_block_zone({mailing=>$d{mailing},id=>$id_blocktype,lg=>$d{lg},preview=>$d{preview},edit=>$d{edit}});
			$template{template} =~ s/$pat/$html_block/g;
		}
	}
	
	$_ = $template{template};
	my @blocks = (/<MIGC_BLOCKS_(\w+)_HERE>/g);
	for (my $i = 0; $i<=$#blocks; $i++ ) 
	{
		if ($blocks[$i] > 0) 
		{
			my $id_blocktype = $blocks[$i];
			my $balise = "<MIGC_BLOCKS_".$id_blocktype."_HERE>";
			my $html_block = render_page({full_url=>1,block=>'y',debug=>0,id=>$id_blocktype,lg=>$d{lg},preview=>'y',edit=>$d{edit},type_page=>$d{type}});			
			$template{template} =~ s/$balise/$html_block/g;
		}
	}

    return $template{template};
}

################################################################################
# render_parag_other_tags
################################################################################
sub render_parag_other_tags
{
	my %d = %{$_[0]};

	my %parag = %{$d{parag}};

	$_ = $d{template};
	my @photos = (/<MIGC_IMGLAZYLOAD_(\w+)_HERE>/g);
	for (my $i = 0; $i<=$#photos; $i++ ) 
	{
		if ($photos[$i] > 0) 
		{
			my $ordby_photo = $photos[$i];
			my %migcms_linked_file = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"visible='y' AND table_name='$d{table_name}' AND token='$parag{id}'",limit=>"$i,1",ordby=>"ordby"});
			if($migcms_linked_file{id} > 0)
			{
				my $photo = render_pic({mailing=>$d{mailing},full_url=>$d{full_url},parag=>\%parag,migcms_linked_file => \%migcms_linked_file,size=>"small",lg=>$d{lg},lazyload=>"y"});	
				$pat = "<MIGC_IMGLAZYLOAD_".$ordby_photo."_HERE>";
		
				$d{template} =~ s/$pat/$photo/g;
			}
		}
	}
	
	$_ = $d{template};
	my @photos = (/<MIGC_IMG_(\w+)_HERE>/g);
	for (my $i = 0; $i<=$#photos; $i++ ) 
	{
		if ($photos[$i] > 0) 
		{
			my $ordby_photo = $photos[$i];
			my %migcms_linked_file = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"visible='y' AND table_name='$d{table_name}' AND token='$parag{id}'",limit=>"$i,1",ordby=>"ordby"});
			if($migcms_linked_file{id} > 0)
			{
				my $photo = render_pic({mailing=>$d{mailing},full_url=>$d{full_url},parag=>\%parag,migcms_linked_file => \%migcms_linked_file,size=>"small",lg=>$d{lg}});	
				$pat = "<MIGC_IMG_".$ordby_photo."_HERE>";
		
				$d{template} =~ s/$pat/$photo/g;
			}
		}
	}

	$_ = $d{template};
	my @photos = (/<MIGC_IMGSRC_(\w+)_HERE>/g);
	for (my $i = 0; $i<=$#photos; $i++ ) 
	{
		if ($photos[$i] > 0) 
		{
			my $ordby_photo = $photos[$i];
			my %migcms_linked_file = sql_line({mailing=>$d{mailing},debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"visible='y' AND table_name='$d{table_name}' AND token='$parag{id}'",limit=>"$i,1",ordby=>"ordby"});
			if($migcms_linked_file{id} > 0)
			{
				#SRC DE LA PHOTO
				$migcms_linked_file{file_dir} =~ s/\.\.\///g; 
				$src = $config{baseurl}."/".$migcms_linked_file{file_dir}."/".$migcms_linked_file{full}."".$migcms_linked_file{ext};
				$pat = "<MIGC_IMGSRC_".$ordby_photo."_HERE>";
				$d{template} =~ s/$pat/$src/g;
			}
		}
	}
	
	$_ = $d{template};
	my @photos = (/<MIGC_IMGURL_(\w+)_HERE>/g);
	for (my $i = 0; $i<=$#photos; $i++ ) 
	{
		if ($photos[$i] > 0) 
		{
			my $ordby_photo = $photos[$i];
			my %migcms_linked_file = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"visible='y' AND table_name='$d{table_name}' AND token='$parag{id}'",limit=>"$i,1",ordby=>"ordby"});
			if($migcms_linked_file{id} > 0)
			{
				my $traduction = get_traduction({debug=>0,id_language=>$config{current_language},id=>$migcms_linked_file{id_textid_url}});
				$pat = "<MIGC_IMGURL_".$ordby_photo."_HERE>";
		
				$d{template} =~ s/$pat/$traduction/g;
			}
		}
	}
	
	$_ = $d{template};
	my @photos = (/<MIGC_IMGALT_(\w+)_HERE>/g);
	for (my $i = 0; $i<=$#photos; $i++ ) 
	{
		
		if ($photos[$i] > 0) 
		{
			my $ordby_photo = $photos[$i];
			my %migcms_linked_file = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"visible='y' AND table_name='$d{table_name}' AND token='$parag{id}'",limit=>"$i,1",ordby=>"ordby"});
			if($migcms_linked_file{id} > 0)
			{
				my $traduction = get_traduction({debug=>0,id_language=>$config{current_language},id=>$migcms_linked_file{id_textid_legend}});
				$pat = "<MIGC_IMGALT_".$ordby_photo."_HERE>";
				$d{template} =~ s/$pat/$traduction/g;
			}
		}
	}
	
	$_ = $d{template};
	
	my @pages = (/<MIGC_PAGE_\[(\w+)\]_HERE>/g);
	for ($i = 0; $i<=$#pages; $i++ ) 
	{		
		
		

		my %migcms_page = read_table($dbh,'migcms_pages',$pages[$i]);
		
		

		
		
		if($migcms_page{migcms_pages_type} eq 'directory')
		{
			#lien vers un dossier: pas de logique actuellement
		}
		elsif($migcms_page{migcms_pages_type} eq 'page')
		{
			#lien vers une page
			my $url_page = get_url({mailing=>$d{mailing},preview=>$d{preview},from=>'render_tags',debug=>0,debug_results=>0,nom_table=>'migcms_pages',id_table=>$pages[$i], id_language => $d{lg}});
			
			if($d{mailing} eq 'y')
			{
				my $full_url_param = $config{fullurl};
				if($migcms_page{id_fathers} ne '' && $config{sitemap_1_for_page} > 0 && $migcms_page{id_fathers} =~ /\,$config{sitemap_1_for_page}\,/)
				{
					$full_url_param = $config{baseurl_1};
				}
				if($migcms_page{id_fathers} ne '' && $config{sitemap_2_for_page} > 0 && $migcms_page{id_fathers} =~ /\,$config{sitemap_2_for_page}\,/)
				{
					$full_url_param = $config{baseurl_2};
				}
				$url_page = $full_url_param.$config{baseurl}."/".$url_page;
			}
			else
			{
				$url_page = $config{baseurl}."/".$url_page;
			}
			$url_page =~ s/\/\//\//g;
			
			if($one_language_site == 1 && ($migcms_page{id} == $migcms_setup{id_default_page} || $migcms_page{id} == $config{id_default_page2}) && $migcms_setup{id_default_page} > 0 )
			{
				#cas site en 1 langue et page d'accueil: url spéciale
				$url_page = $config{baseurl};
			}
			
				# print "<br />[$migcms_page{migcms_pages_type}]";
				# print "<br />[$pages[$i]]";
				# print "<br />[$url_page]";
			
			
		
			$pat = '<MIGC_PAGE_\['.$pages[$i].'\]_HERE>';
			# print $d{template};
			# print $pat;
			# exit;
			$d{template} =~ s/$pat/$url_page/g;
						# print "<br />[$d{template}]";
					
		}
		else
		{
			#lien vers un lien
			my $url_page = get_link_page({migcms_page=>\%migcms_page,mailing=>$d{mailing}});
			$url_page =~ s/\/\//\//g;
			# log_debug("PAGE:".$pages[$i],"","PAGE");
			# log_debug($url_page,"","PAGE");
			$pat = '<MIGC_PAGE_\['.$pages[$i].'\]_HERE>';
			$d{template} =~ s/$pat/$url_page/g;
		}
	} 	

	return $d{template}
}

sub render_pic
{
	my %d = %{$_[0]}; 
	# see($d{migcms_linked_file});
	# print "render_pic";
	#legende et url traductibles
	if(!($d{migcms_linked_file}{id} > 0))
	{
		return '';
	}
	
	my ($legende,$dum) = get_textcontent($dbh,$d{migcms_linked_file}{id_textid_legend},$d{lg});
	my ($url,$dum) = get_textcontent($dbh,$d{migcms_linked_file}{id_textid_url},$d{lg});
	my $size = 'small';
	if($d{size} ne '')
	{
		$size = $d{size};
	}

	my $url_alt_traduction = get_traduction({id=>$d{parag}{id_textid_link_url},id_language=>$d{lg}});
	if($url_alt_traduction ne '' && $url eq '')
	{
		$url = $url_alt_traduction;
	}

	my $src_pic = $href_pic = $target_blank = '';

	#sauvegarde de l'url relative
	$d{migcms_linked_file}{file_dir} =~ s/\.\.\///g; 

	my $relative_path_large = $config{directory_path}.'/'.$d{migcms_linked_file}{file_dir}.'/'.$d{migcms_linked_file}{name_large};
	my $relative_path_full = $config{directory_path}.'/'.$d{migcms_linked_file}{file_dir}.'/'.$d{migcms_linked_file}{file};
	# print "\n relative_path_full:$relative_path_full";
	
	# Construction de l'URL de base
	if($d{full_url} == 1 || $d{mailing} eq 'y')
	{
		$d{migcms_linked_file}{file_dir} = $config{fullurl} . "/" . $d{migcms_linked_file}{file_dir}; #pr afficher les urls complètes
		
	}
	else
	{
		$d{migcms_linked_file}{file_dir} = "/" . $d{migcms_linked_file}{file_dir}; #pr afficher les urls complètes
	}

	#si l'image est redimensionnée (on prend small et large, sinon full)
	if($d{migcms_linked_file}{do_not_resize} eq 'y')
	{
		if($d{full_url} == 1)
		{
			$src_pic = $d{migcms_linked_file}{file_dir}.'/'.$d{migcms_linked_file}{full}.$d{migcms_linked_file}{ext};
		}
		else
		{
			$src_pic = $d{migcms_linked_file}{file_dir}.'/'.$d{migcms_linked_file}{full}.$d{migcms_linked_file}{ext};
		}
	}
	else
	{
		if($d{full_url} == 1)
		{
			$src_pic = $d{migcms_linked_file}{file_dir}.'/'.$d{migcms_linked_file}{'name_'.$size};
			$href_pic = $d{migcms_linked_file}{file_dir}.'/'.$d{migcms_linked_file}{name_large};
		}
		else
		{
			$src_pic = $d{migcms_linked_file}{file_dir}.'/'.$d{migcms_linked_file}{'name_'.$size};
			$href_pic = $d{migcms_linked_file}{file_dir}.'/'.$d{migcms_linked_file}{name_large};
		}
	}

	#si on n'a pas encodé de lien on met l'image large
	my $class = '';
	# log_debug("$url eq '' && ($href_pic ne '' && -e $relative_path_large && $d{migcms_linked_file}{name_large} ne '')",'','dpics');
	# log_debug("$url eq '' && ($href_pic ne '' && -e $relative_path_full && $d{migcms_linked_file}{name_large} ne '')",'','dpics');
	if($url eq '' && ($href_pic ne '' && -e $relative_path_large && $d{migcms_linked_file}{name_large} ne ''))
	{
		# log_debug("OUI1",'','dpics');
		#si pas de lien et une fichier large existant
		$url = $href_pic;
		$class = 'fancybox';
	}
	elsif($url eq '' && ($href_pic ne '' && -e $relative_path_full && $d{migcms_linked_file}{name_large} ne ''))
	{
		# log_debug("OUI2",'','dpics');
		#si pas de lien et une fichier full existant
		$url = $href_pic;
		$class = 'fancybox';
	}
	else
	{
		# log_debug("NON",'','dpics');
	}
	
	if($d{migcms_linked_file}{blank} eq "y")
	{
		$target_blank = "target='_blank'";
	}
	
	my $width = $d{migcms_linked_file}{'width_'.$size};
	my $tag_width = '';
	if($d{migcms_linked_file}{'width_'.$size} > 0)
	{
		$tag_width = 'width="'.$width.'" ';
	}
	
	my $height = $d{migcms_linked_file}{'height_'.$size};
	my $tag_height = '';
	if($d{migcms_linked_file}{'height_'.$size} > 0)
	{
		$tag_height = 'height="'.$height.'" ';
	}
	
	my $tag_styles = '';
	if(get_quoted('mailing') eq 'y')
	{
		$tag_styles = 'styles="display:block;" ';
	}
	
	# print "$url";
	
	my $lazyload = $d{lazyload};
	
	#renvoie le lien et/ou l'image
		
	if($url ne '')
	{
		if($lazyload eq 'y') {
			return '<a href="'.$url.'" '.$target_blank.' title="'.$legende.'" class="'.$class.'" rel="pic'.$d{migcms_linked_file}{token}.'"><img data-original="'.$src_pic.'" alt="'.$legende.'" '.$tag_width.' '.$tag_height.' '.$tag_styles.' /></a>';
		}
		else {
			return '<a href="'.$url.'" '.$target_blank.' title="'.$legende.'" class="'.$class.'" rel="pic'.$d{migcms_linked_file}{token}.'"><img src="'.$src_pic.'" alt="'.$legende.'" '.$tag_width.' '.$tag_height.' '.$tag_styles.' /></a>';
		}
	}	
	else
	{
		if($lazyload eq 'y') {
			return '<img data-original="'.$src_pic.'" alt="'.$legende.'" '.$tag_width.' '.$tag_height.' '.$tag_styles.' />';
		}
		else {
			return '<img src="'.$src_pic.'" alt="'.$legende.'" '.$tag_width.' '.$tag_height.' '.$tag_styles.' />';
		}
	}
	
}




################################################################################
# render_parags
################################################################################
sub render_parags
{
  my %d = %{$_[0]};
  $d{lg} = $d{colg} || $d{lg};
	if(!$d{lg} > 0)
	{
		$d{lg} = 1;
	}
	$d{debug} = 0;
	
	my $id_page = $d{id};
	my $list_parags = '';
	
	my $where_depends_on_actif_language = '';
	if($config{parag_depends_on_actif_language} eq 'y' && $d{page}{migcms_pages_type} ne 'newsletter') 
	{	
		$where_depends_on_actif_language = ' actif_'.$d{lg}.' = "y" AND ';
	}	
	
	my $where_nom_zone_template = '';
	if($d{nom_zone_template} ne '')
	{
		$where_nom_zone_template = " nom_zone_template = '$d{nom_zone_template}' AND ";
	}
	else
	{
		$where_nom_zone_template = " nom_zone_template = '' AND ";
	}
		
	my @paragraphes = sql_lines({debug=>$d{debug},debug_results=>$d{debug},table=>'parag', where=>"$where_nom_zone_template $where_depends_on_actif_language id_page='$d{id_page}' AND migcms_deleted != 'y' AND visible = 'y' AND id NOT IN (select id_record from migcms_valides where nom_table='parag')",ordby=>'ordby'});
	foreach my $p (@paragraphes)
	{
		my %parag = %{$p};
		if($parag{content_type} eq 'menu')
		{
			#PARAG DE TYPE MENU------------------------------------------------------------------
			my $html_menu = '';
			my $template_menu = get_template({debug=>0,debug_results=>0,id=>$parag{id_template_menu},lg=>$d{lg}});
			my $template_bloc = get_template({debug=>0,debug_results=>0,id=>$parag{id_template},lg=>$d{lg}});
			
			#charge les lignes du sous menu
			my @children_pages = sql_lines({debug=>0,debug_results=>0,table=>'migcms_pages',where=>"id_father='$parag{id_page_directory}' AND visible='y'",ordby=>'ordby'});
			foreach my $children_pages (@children_pages)
			{
				#nouvele ligne de menu
				my %children_page = %{$children_pages};
				my $menu_line = $template_menu;
				
				# ID
				$menu_line =~ s/<MIGC_ID_HERE>/menuid_$children_page{id}/g; 
				
				# LINK OF PAGE					
				my $url_rewriting = '';
				if($one_language_site == 1 && (($children_page{id} == $migcms_setup{id_default_page} && $migcms_setup{id_default_page} > 0) || ($children_page{id} == $config{id_default_page2} && $config{id_default_page2} > 0)))
				{
					#cas site en 1 langue et page d'accueil: url spéciale
					$url_rewriting = $config{baseurl}.'/';
					if($d{preview} eq 'y' && $d{type_page} ne 'private')
					{
						$url_rewriting = $config{baseurl}.'/cgi-bin/migcms_view.pl?lg='.$d{lg}.'&id_page='.$migcms_setup{id_default_page}.'&edit='.get_quoted('edit');
					}
				}
				elsif($children_page{migcms_pages_type} eq 'page')
				{
					$url_rewriting = get_url({from=>'render_blockmenupage',preview=>$d{preview},debug=>0,debug_results=>0,nom_table=>'migcms_pages',id_table=>$children_page{id}, id_language => $d{lg}});
					$url_rewriting = $config{baseurl}."/".$url_rewriting;
				}
				elsif($children_page{migcms_pages_type} eq 'link')
				{
					$url_rewriting = get_link_page({preview=>$d{preview},migcms_page=>\%children_page});
				}
				$url_rewriting =~ s/^\/\//\//g;
				$menu_line =~ s/<MIGC_LNK_HERE>/$url_rewriting/g;
				my $target_blank = '';
				if($children_page{blanktarget} eq 'y')
				{
					 $target_blank = ' target="_blank" ';
				}
				$menu_line =~ s/<MIGC_TARGETBLANK_HERE>/$target_blank/g;
				
				
				# NAME OF PAGE
				($page_name,$dum) = get_textcontent($dbh,$children_page{id_textid_name},$d{lg});
				$menu_line =~ s/<MIGC_NAME_HERE>/$page_name/g;
				
				#ajout du template de ligne au code html du menu
				$html_menu .= $menu_line;
			}

			$template_bloc =~ s/<MIGC_PARAGCONTENT_HERE>/$html_menu/g;
			$list_parags .= $template_bloc;
		}
		elsif($parag{content_type} eq 'function')
		{
			my $template_bloc = '';
			
			#$parag{function}  =~ s|\(.*\)||g;
			
			my @pars = split(/\(/,$parag{function});
			
			my $func = $pars[0];
			
			#look in def_handmade if needed
			if(
				$func ne 'block_mailing_subscribe'
				&&
				$func ne 'block_main_menu' 
				&&
				$func ne 'block_full_menu'
				&&
				$func ne 'mailing_subscribe'
				&&
				$func ne 'migc_search_form'
			)
			{
				$func = 'def_handmade::'.$func;
			}
			
			#print $func;
			#exit;
			
			my $info = &$func($pars[1]);
			$list_parags .= $info;
			# ($dbh_data,$d{line}{id_table_record},$dm_cfg{map_param},\%d)
			
		}
		else {
			$list_parags .= render_parag({full_url=>$d{full_url},debug=>$d{debug},debug_results=>$d{debug},parag=>$p,id=>$p{id},lg=>$d{lg},edit=>$d{edit}});
		}
	}
    return $list_parags;
}


################################################################################
# render_block_zone
################################################################################
sub render_block_zone
{
    
	my %d = %{$_[0]};
    $d{lg} = $d{colg} || $d{lg};
	if(!$d{lg} > 0)
	{
		$d{lg} = 1;
	}
		
	my $id_blocktype = $d{id};
	my $blockzone = '';
	
	my @blocks = sql_lines({debug=>0,debug_results=>0,table=>'migcms_blocks', where=>"id_blocktype='$id_blocktype' AND visible = 'y' AND migcms_deleted = 'n'",ordby=>'ordby'});
	foreach $b (@blocks)
	{
		my %b = %{$b};
		
		$blockzone .= render_block({mailing=>$d{mailing},type_page => $d{type_page},block=>\%b,id=>$b{id},lg=>$d{lg},preview=>$d{preview},edit=>$d{edit}});
	}
 
    return $blockzone;
}


################################################################################
# render_block
################################################################################
sub render_block
{
    
	my %d = %{$_[0]};
	if($d{block}{id} > 0)
	{
		%block = %{$d{block}};
	}
	else
	{
		%block = read_table($dbh,'migcms_blocks',$d{id});
	}
	
    $d{lg} = $d{colg} || $d{lg};
	if(!$d{lg} > 0)
	{
		$d{lg} = 1;
	}
	my $template_bloc = get_template({debug=>0,debug_results=>0,id=>$block{id_template},lg=>$d{lg}});

	if($block{type} eq 'menu')
	{
		#BLOCK DE TYPE MENU------------------------------------------------------------------
		my $html_menu = '';
		my $template_menu = get_template({debug=>0,debug_results=>0,id=>$block{id_template_menu},lg=>$d{lg}});
		
		#charge les lignes du sous menu
		my @children_pages = sql_lines({debug=>0,debug_results=>0,table=>'migcms_pages',where=>"id_father='$block{id_page_directory}' AND visible='y'",ordby=>'ordby'});
		foreach my $children_pages (@children_pages)
		{
			#nouvele ligne de menu
			my %children_page = %{$children_pages};
			my $menu_line = $template_menu;
			
			# ID
			$menu_line =~ s/<MIGC_ID_HERE>/menuid_$children_page{id}/g; 
			
			# LINK OF PAGE					
			my $url_rewriting = '';
			if($one_language_site == 1 && (($children_page{id} == $migcms_setup{id_default_page} && $migcms_setup{id_default_page} > 0) || ($children_page{id} == $config{id_default_page2} && $config{id_default_page2} > 0)))
			{
				#cas site en 1 langue et page d'accueil: url spéciale
				$url_rewriting = $config{baseurl}.'/';
				if($d{preview} eq 'y' && $d{type_page} ne 'private')
				{
					$url_rewriting = $config{baseurl}.'/cgi-bin/migcms_view.pl?lg='.$d{lg}.'&id_page='.$migcms_setup{id_default_page}.'&edit='.get_quoted('edit');
				}
			}
			elsif($children_page{migcms_pages_type} eq 'page')
			{
				$url_rewriting = get_url({from=>'render_blockmenupage',preview=>$d{preview},debug=>0,debug_results=>0,nom_table=>'migcms_pages',id_table=>$children_page{id}, id_language => $d{lg}});
				$url_rewriting = $config{baseurl}."/".$url_rewriting;
			}
			elsif($children_page{migcms_pages_type} eq 'link')
			{
				$url_rewriting = get_link_page({preview=>$d{preview},migcms_page=>\%children_page});
			}
			$url_rewriting =~ s/^\/\//\//g;
			$menu_line =~ s/<MIGC_LNK_HERE>/$url_rewriting/g;
			my $target_blank = '';
			if($children_page{blanktarget} eq 'y')
			{
				 $target_blank = ' target="_blank" ';
			}
			$menu_line =~ s/<MIGC_TARGETBLANK_HERE>/$target_blank/g;
			
			
			# NAME OF PAGE
			($page_name,$dum) = get_textcontent($dbh,$children_page{id_textid_name},$d{lg});
			$menu_line =~ s/<MIGC_NAME_HERE>/$page_name/g;
			
			#ajout du template de ligne au code html du menu
			$html_menu .= $menu_line;			
		}

		$template_bloc =~ s/<MIGC_PARAGCONTENT_HERE>/$html_menu/g;
		return $template_bloc;
	}
	elsif($block{type} eq 'function')
	{
	
			my $template_bloc = '';
			
			#$parag{function}  =~ s|\(.*\)||g;
			
			my @pars = split(/\(/,$block{function});
			
			my $func = $pars[0];
			
			#look in def_handmade if needed
			if(
				$func ne 'block_mailing_subscribe'
				&&
				$func ne 'block_main_menu' 
				&&
				$func ne 'block_full_menu'
				&&
				$func ne 'mailing_subscribe'
				&&
				$func ne 'migc_search_form'
			)
			{
				$func = 'def_handmade::'.$func;
			}
			
			my $info = &$func($pars[1]);			
			return $info;
	
		#my $template_bloc = '';
		#$block{function}  =~ s|\(.*\)||g;
		#my $func = $block{function}; 
		
		#look in def_handmade if needed
		#if(
		 #$func ne 'block_mailing_subscribe'
		 #&&
		 #$func ne 'block_main_menu' 
		 #&&
		 #$func ne 'block_full_menu'
		 #&&
		 #$func ne 'mailing_subscribe'
		 #&&
		 #$func ne 'migc_search_form'
		 #)
		 #{
			#$func = 'def_handmade::'.$func;
		#}	
		
		#my $info = &$func(\%d);
		#return $info;
		# ($dbh_data,$d{line}{id_table_record},$dm_cfg{map_param},\%d)
		
	}
	else
	{
		#BLOCK DE TYPE CONTENU------------------------------------------------------------------
		
		($title_content,$dum) = get_textcontent($dbh,$block{id_textid_title},$d{lg});
		($parag_content,$dum) = get_textcontent($dbh,$block{id_textid_content},$d{lg});
		
		if($d{edit} eq 'y')
		{
			$title_content = '<span class="mig_parag_title_content" data-idcontent="'.$block{id_textid_title}.'" data-lg="'.$d{lg}.'">'.$title_content.'</span>';
			$parag_content = '<span class="mig_parag_content" data-idcontent="'.$block{id_textid_content}.'" data-lg="'.$d{lg}.'">'.$parag_content.'</span>';
		}
		
		$parag_content =~ s/\&lt;/</g;	
		$parag_content =~ s/\&gt;/>/g;
			
		$template_bloc =~ s/<MIGC_PARAGCONTENT_HERE>/$parag_content/g; 
		$template_bloc =~ s/<MIGC_PARAGTITLE_HERE>/$title_content/g;
				
		# Rendu des autres TAGS
		$template_bloc = render_parag_other_tags({mailing=>$d{mailing},parag=>\%block, table_name=>"migcms_blocks", template=>$template_bloc, lg=>$d{lg}});
		
		return $template_bloc;
	}
}

# sub render_block_pic
# {
  # my %d = %{$_[0]};
  # my %pic = sql_line({debug=>0,debug_results=>0,table=>'migcms_blocks_pics',where=>"id=$d{id}"});
  # my ($legende,$dum) = get_textcontent($dbh,$pic{id_textid_alt},$colg);
  
  # my $style = '';
  # if($d{admin} eq 'y')
  # {
	# $style .= " max-width:400px; ";
  # }
  
  # my $thumb_field = 'url_pic_small';
  # my $thumb_big_field = 'url_pic_big';
  # if($pic{pic_thumb_create} ne 'y')
  # {
	# $thumb_field = 'pic_name_orig';
	# $thumb_big_field = 'pic_name_orig';
  # }
  
  # if($d{force_size} ne '')
  # {
	# $thumb_field = 'url_pic_'.$d{force_size};
	# $thumb_big_field = 'pic_name_orig';
  # }
  
  
  # if($pic{url} ne '')
  # {
	# return <<"EOH";
		# <a href="$pic{url}" title="$legende" class="migcms_block_pic_url">
			# <img src="$config{baseurl}/pics/$pic{$thumb_field}"  style = " $style "  class=""/>
		# </a>
# EOH
  # }
  # elsif($pic{lightbox} eq 'y')
  # {
	# return <<"EOH";
	# <a href="$config{baseurl}/pics/$pic{url_pic_big}" title="$legende" class="fancybox migcms_block_pic_lightbox">
		# <img src="$config{baseurl}/pics/$pic{$thumb_field}"  style = " $style " class="" />
	# </a>
# EOH
  # }
  # elsif($pic{pic_thumb_create} eq 'y')
  # {
	# return <<"EOH";
		# <a href="$pic{$thumb_big_field}" title="$legende" class="migcms_block_pic">
			# <img src="$config{baseurl}/pics/$pic{$thumb_field}"  style = " $style "  class=""/>
		# </a>
# EOH
  # }
  # else
  # {
	# $thumb_field = $thumb_big_field;
	# return <<"EOH";
		# <img src="$config{baseurl}/pics/$pic{$thumb_field}"  style = " $style "  class="" />
# EOH
  # }
# }



################################################################################
# GET_TEMPLATE
################################################################################
sub render_tags
{
 	my %d = %{$_[0]};
 	my %data_family = %{$d{data_family}};

 	my %balises = %{setup::get_balises($dbh_data,$d{lg})};

# print $d{preview};
   # $d{debug} = 1;
   my %page = sql_line({debug=>$d{debug},debug_results=>$d{debug},dbh=>$dbh_data,table=>"migcms_pages",where=>"id='$d{id_page}'"});

   if(!($d{lg} > 0 && $d{lg} <= 10))
   {	
		$d{lg} = get_quoted('lg');
		if(!($d{lg} > 0 && $d{lg} <= 10))
		{	
				$d{lg} = 1;
		}
   }
   

   
   #rendu de page content
   $_ = $d{template};
   my @pagescontents = (/<MIGC_PAGECONTENT_\[(\w+)\]_HERE>/g);
	foreach my $pc (@pagescontents)
	{		
		#si contenu force et plusieurs zones, on remplit le contenu forcé dans la premiere zone
		if($d{force_content} ne "")
	    {
			$tag = '<MIGC_PAGECONTENT_\['.$pc.'\]_HERE>';
			$d{template} =~ s/$tag/$d{force_content}/g;
			last;
		}
		
		#on remplit les paragraphes de la zone
		my $page_html = render_parags({page=>\%page,full_url=>$d{full_url},nom_zone_template=>$pc,debug=>$d{debug},debug_results=>$d{debug},id_page=>$d{id_page},lg=>$d{lg},edit=>$d{edit}});	 
		$tag = '<MIGC_PAGECONTENT_\['.$pc.'\]_HERE>';
		$d{template} =~ s/$tag/$page_html/g;
	}


 	my $tag = '<MIGC_PAGECONTENT_HERE>';
	$_ = $d{template};
	if (/$tag/)
	{
		if($d{force_content} ne "")
		{			
			#RENDU DU CONTENU DE PAGE (contenu force)
			my $page_html = $d{force_content};	 
			$d{template} =~ s/$tag/$page_html/g;
		}
		elsif($d{id_page} ne "")
		{
				
			
			#RENDU DU CONTENU DE PAGE (paragraphes)
			my $page_html = render_parags({page=>\%page,full_url=>$d{full_url},nom_zone_template=>"",debug=>$d{debug},debug_results=>$d{debug},id_page=>$d{id_page},lg=>$d{lg},edit=>$d{edit}});	 
			$d{template} =~ s/$tag/$page_html/g;
		}
		else
		{
			$d{template} =~ s/$tag/$d{content}/g;
		}
 	}

 	#BLOCKS (2x pour les blocks contenant des blocks -> faire une fonction)
	$_ = $d{template}; 
    my @blocks = (/<MIGC_(\w+)BLOCKS_HERE>/g);
	for ($i = 0; $i<=$#blocks; $i++ ) 
	{
		if ($blocks[$i] =~ /^T(\d+)/) 
		{
			my $id_blocktype = $1;
			my $blockzone = render_block_zone({mailing=>$d{mailing},type_page => $d{type_page},id=>$id_blocktype,lg=>$d{lg},preview=>$d{preview},edit=>$d{edit}});
			# log_debug($blockzone,'','blockzone'.$id_blocktype);
			$pat = "<MIGC_T".$id_blocktype."BLOCKS_HERE>";
			$d{template} =~ s/$pat/$blockzone/g;
		}
	}  
	$_ = $d{template}; 
    my @blocks = (/<MIGC_(\w+)BLOCKS_HERE>/g);
	for ($i = 0; $i<=$#blocks; $i++ ) 
	{
		if ($blocks[$i] =~ /^T(\d+)/) 
		{
			my $id_blocktype = $1;
			my $blockzone = render_block_zone({mailing=>$d{mailing},id=>$id_blocktype,type_page => $d{type_page},lg=>$d{lg},preview=>$d{preview},edit=>$d{edit}});
			$pat = "<MIGC_T".$id_blocktype."BLOCKS_HERE>";
			$d{template} =~ s/$pat/$blockzone/g;
		}
	} 
	
	#BLOCKS (NEW)
	$_ = $d{template}; ;
	my @blocks = (/<MIGC_BLOCKS_(\w+)_HERE>/g);
	for (my $i = 0; $i<=$#blocks; $i++ ) 
	{
		if ($blocks[$i] > 0) 
		{
			my $id_blocktype = $blocks[$i];
			my $balise = "<MIGC_BLOCKS_".$id_blocktype."_HERE>";
			my $html_block = render_page({full_url=>1,block=>'y',debug=>0,id=>$id_blocktype,lg=>$d{lg},preview=>$d{preview},edit=>$d{edit},type_page=>$d{type}});			
			$d{template} =~ s/$balise/$html_block/g;
		}
	}
	
	#FORMS
	$_ = $d{template}; 
	my @forms = (/<MIGC_FORMS_(\w+)_HERE>/g);
	for (my $i = 0; $i<=$#forms; $i++ ) 
	{
		if ($forms[$i] > 0) 
		{
			my $id_form = $forms[$i];
			
			$pat = "<MIGC_FORMS_".$id_form."_HERE>";
			($title_content,$html_form,$id_template_page) = forms::form_get(
			{
				id_form => $id_form,
				token => '',
				step  => 1,
				colg => $lg,
			});
			$d{template} =~ s/$pat/$html_form/g;
		}
	}
	
	# MOTEURS DE RECHERCHES DE DATA
	$_ = $d{template}; 
	my @sfs = (/<MIGC_DATA_SEARCH_FORM_\[(.+)\]_HERE>/g);
	for (my $i = 0; $i<=$#sfs; $i++ ) 
	{		
		my ($id_sf,$id_alt_tpl)= split(/\,/,$sfs[$i]);
		my $value = data::get_data_search_form($id_sf,$d{lg},$id_alt_tpl);
		# my $value = 'get_data_search_form';
		$tag = '<MIGC_DATA_SEARCH_FORM_\['.$sfs[$i].'\]_HERE>';
		$d{template} =~ s/$tag/$value/g;
	}
	
	# DATA::GET_SHEETS
	$_ = $d{template}; 
	my @gs = (/<MIGC_DATA_GETSHEETS_\[(\w+)\]_HERE>/g);
	for (my $i = 0; $i<=$#gs; $i++) 
	{	
		my $value = render_tags_data_get_sheets($gs[$i],$d{lg});
		$tag = '<MIGC_DATA_GETSHEETS_\['.$gs[$i].'\]_HERE>';
		$d{template} =~ s/$tag/$value/g;
	}
	
	#DATA::IMAGE OG: champs admin_files dont le tab est seo
   $_ = $d{template}; 
   my $tag = '<MIGC_DATA_OG_IMAGE_HERE>';
   if (/$tag/)
   {  
		my $og_image = '';
		my $balise_og;
		
		my $MapRewrite = get_quoted('MapRewrite');
		my @pars = split(/\-/,$MapRewrite);
		my $extlink = pop @pars; 
		my $id_data_sheet = pop @pars; 
		if ($id_data_sheet =~ /^\d+$/) 
		{
			my %data_sheet=read_table($dbh,"data_sheets",$id_data_sheet);
			my %data_field = sql_line({table=>"data_fields",where=>"field_type='files_admin' AND id_data_family='$data_sheet{id_data_family}' AND field_tab = 'seo'"});
			my $fieldname = 'f'.$data_field{ordby};
			my %migcms_linked_file = sql_line({table=>"migcms_linked_files",where=>"ordby='1' AND table_name='data_sheets' AND table_field='$fieldname' AND token='$data_sheet{id}'"});
			if($data_field{field_type} eq 'files_admin' && $data_field{field_tab} eq 'seo')
			{
				$og_image = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{name_og};
				$og_image =~ s/\.\.\///g; 
				$og_image = $config{rewrite_protocol}.'://'.$ENV{HTTP_HOST}.'/'.$og_image;
				$balise_og = <<"EOH";
				<meta property="og:image" content="$og_image"/>
				<meta name="twitter:image" content="$og_image"/>
EOH
				if($migcms_linked_file{name_og} eq '')
				{
					$balise_og = '';
				}
			}
			while ($d{template} =~ /$tag/g)
			{
			  $d{template} =~ s/$tag/$balise_og/g;
			}
		}
	}
	
	#PAGE::IMAGE OG: champs admin_files dont le tab est seo
   $_ = $d{template}; 
   my $tag = '<MIGC_PAGE_OG_IMAGE_HERE>';
   if (/$tag/)
   {  
		my $og_image = '';
		my $balise_og;
		
		my $MapRewrite = get_quoted('MapRewrite');
		if ($d{id_page} =~ /^\d+$/) 
		{
			my %migcms_linked_file = sql_line({table=>"migcms_linked_files",where=>"ordby='1' AND table_name='migcms_pages' AND table_field='imageog' AND token='$d{id_page}'"});
			$og_image = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{name_og};
			$og_image =~ s/\.\.\///g; 
			
			my $full_url_param = $config{fullurl};
			if($page{id_fathers} ne '' && $config{sitemap_1_for_page} > 0 && $page{id_fathers} =~ /\,$config{sitemap_1_for_page}\,/)
			{
				$full_url_param = $config{baseurl_1};
			}
			if($page{id_fathers} ne '' && $config{sitemap_2_for_page} > 0 && $page{id_fathers} =~ /\,$config{sitemap_2_for_page}\,/)
			{
				$full_url_param = $config{baseurl_2};
			}	
			$og_image = $full_url_param.'/'.$og_image;
			$balise_og = <<"EOH";
				<meta property="og:image" content="$og_image"/>
				<meta name="twitter:image" content="$og_image"/>
EOH
			if($migcms_linked_file{name_og} eq '')
			{
				$balise_og = '';
			}
			while ($d{template} =~ /$tag/g)
			{
			  $d{template} =~ s/$tag/$balise_og/g;
			}
		}
	}
  
   #RENDU DES AUTRES BALISES
   $_ = $d{template}; 
   my $tag = '<MIGC_BASEURL_HERE>';
   if (/$tag/)
   {  
		# my $baseurl = $config{fullurl}.'/'; #base url ne revoit pas full !
		my $baseurl = $config{baseurl}.'/';
		while ($d{template} =~ /$tag/g)
		{
		  $d{template} =~ s/$tag/$baseurl/g;
		}
  }

  $_ = $d{template}; 
 	my $tag = '<MIGC_JAVASCRIPT_HERE>';
 	if (/$tag/)
 	{  
 		# SI le mode compilé est activé
 		my $value;
 		if($migcms_setup{compile_js} eq "y")
 		{
			$value = '<script src="'.$config{baseurl}.'/skin/js/'.$config{projectname}.'_compil.js"></script>';
 		}
 		else
 		{
 			my @js_files = sql_lines({debug=>1,debug_results=>1,table=>'migcms_frontend_js',ordby=>'ordby',where=>"visible='y'"});
	
			foreach $file (@js_files)
			{
				my %file = %{$file};

				$value .= '<script src="'.$config{baseurl}.$file{filename}.'"></script>';
			}
 		}
		while ($d{template} =~ /$tag/g)
		{
		  $d{template} =~ s/$tag/$value/g;
		}
  }
	
	my $tag = '<MIGC_PAGETITLE_HERE>';
	if($d{mailing} eq 'y' && /$tag/)
	{
		$d{template} =~ s/$tag/$page{mailing_name}/g;
	}
	elsif($d{mailing} ne 'y' && /$tag/)
	{
		$page_title = get_traduction({id=>$page{id_textid_name},lg=>$d{lg}});
		$d{template} =~ s/$tag/$page_title/g;
	}
		
	my $tag = '<MIGC_METATITLE_HERE>';
	if (/$tag/)
    {
	   $texte_nom = get_traduction({id=>$page{id_textid_meta_title},lg=>$d{lg}});
	   if($texte_nom eq "")
	   {
	   	my $test_sw = get_quoted('sw') || "account";
	   	$texte_nom = $sitetxt{'member_metatitle_'.$test_sw};
	   }

	   while ($d{template} =~ /$tag/g)
	   {
		  $d{template} =~ s/$tag/$texte_nom/g;
	   }
    }
	
	my $tag = '<MIGC_OBJID_HERE>';
	if (/$tag/)
    {
	   while ($d{template} =~ /$tag/g)
	   {
		  $d{template} =~ s/$tag/$d{id_page}/g;
	   }
    }
	
	
	
   
   my $tag = '<MIGC_METADESCRIPTION_HERE>';
   if (/$tag/)
   {
	   $texte = get_traduction({id=>$page{id_textid_meta_description},lg=>$d{lg}});
	   while ($d{template} =~ /$tag/g)
	   {
		  $d{template} =~ s/$tag/$texte/g;
		}
   }

   my $tag = '<MIGC_DATA_DETAIL_BREADCRUMB_HERE>';
   if (/$tag/)
   {
   	my $breadcrumb = get_data_detail_categories_breadcrumb();
   	while ($d{template} =~ /$tag/g)
	   {
		  $d{template} =~ s/$tag/$breadcrumb/g;
		}
   }
   
   my $tag = '<MIGC_BREADCRUMB_HERE>';
   if (/$tag/)
   {
	   use Data::Dumper;

	   my $racine = '/'.get_url({debug=>0,nom_table=>'migcms_pages',id_table=>$migcms_setup{id_default_page}, id_language => $d{lg}});

	   my $breadcrumb = <<"EOH";
	   <ol class="breadcrumb">
			<li><a href="$racine">$sitetxt{data_breadcrumb_accueil}</a></li>
EOH

	   my $type_breadcrumb = '';
	   my $test_sw = get_quoted('sw');
	   my $sf = get_quoted('sf');
	   if($ENV{SCRIPT_NAME} =~ /data.pl/ && $test_sw eq 'list_cat')
	   {
			$type_breadcrumb = 'data_listcat';
	   }
	   elsif($ENV{SCRIPT_NAME} =~ /data.pl/ && ($test_sw eq 'list' || $test_sw eq ''))
	   {
			$type_breadcrumb = 'data_list';
	   }
	   elsif($ENV{SCRIPT_NAME} =~ /data.pl/ && ($test_sw eq 'detail'))
	   {
			$type_breadcrumb = 'data_detail';
	   }
	   elsif($ENV{SCRIPT_NAME} =~ /adm_migcms_build.pl/ || $ENV{SCRIPT_NAME} =~ /migcms_view.pl/)
	   {
			$type_breadcrumb = 'page';
	   }
	   elsif($ENV{SCRIPT_NAME} =~ /members.pl/)
	   {
			$type_breadcrumb = 'membre';
	   }
	   elsif($ENV{SCRIPT_NAME} =~ /eshop.pl/)
	   {
			$type_breadcrumb = 'eshop';
	   }
	   
	   if($type_breadcrumb eq 'data_listcat')
	   {
			my $id_father = get_quoted('id_father');
			my %data_category = read_table($dbh,'data_categories',$id_father);	
			my %sf = read_table($dbh,'data_search_forms',$sf);	
			
			my $titre_cat = get_traduction({id=>$data_category{id_textid_name},lg=>$config{current_language}});
			my $titre_moteur = get_traduction({id=>$sf{id_textid_name},lg=>$config{current_language}});
			
			my $url_moteur = get_url({debug=>0,nom_table=>'data_listcat_form',id_table=>$sf{id}, id_language => $config{current_language}});
			my $url_cat = get_url({debug=>0,nom_table=>'data_categories',id_table=>$id_father, id_language => $config{current_language}});
			my $url = $config{baseurl}.'/'.$url_moteur.'/'.$url_cat.'/1';
			
			#parents
			my $parents = "";
			while($data_category{id_father} > 0)
			{
				%data_category = read_table($dbh,'data_categories',$data_category{id_father});	
				my $url_cat = get_url({debug=>0,nom_table=>'data_categories',id_table=>$data_category{id}, id_language => $config{current_language}});
				my $url = $config{baseurl}.'/'.$url_moteur.'/'.$url_cat.'/1';
				my $titre_cat = get_traduction({id=>$data_category{id_textid_name},lg=>$config{current_language}});

				if($data_category{visible} eq 'y')
				{
					$parents =<<"EOH";
					<li><a href="$url">$titre_cat</a></li>
					$parents
EOH
				}
			}
			
			$breadcrumb .= <<"EOH";
				<li><a href="$url" data-lg="$config{current_language}">$titre_moteur</a></li>
				$parents
				<li><a href="$url">$titre_cat</a></li>
				<li><a href="">Page 1</a></li>
EOH
	   }
	   elsif($type_breadcrumb eq 'data_list')
	   {
			my $id_father = get_quoted('id_father');
			
			 %rew_fathers_cats = ();
			my @cats = sql_lines({select=>"id,id_father",table=>'data_categories',where=>"id_father > 0"});
			foreach $cat (@cats)
			{
				my %cat = %{$cat};
				$rew_fathers_cats{$cat{id}} = $cat{id_father};
			}
			
			my %sf = read_table($dbh,'data_search_forms',$sf);	
			my $titre_moteur = get_traduction({id=>$sf{id_textid_name},lg=>$config{current_language}});
			my $url_moteur = get_url({debug=>0,nom_table=>'data_search_form',id_table=>$sf{id}, id_language => $config{current_language}});
						
			
			$breadcrumb .= <<"EOH";
				<li><a href="$url" data-lg="$config{current_language}">$titre_moteur</a></li>
EOH
			my $url_cat = '';
			
			foreach my $num_param (1 .. 10)
			{
				my $test_id_cat = get_quoted('s'.$num_param);
				my $url = '';
				my $titre = '';
				if($test_id_cat > 0)
				{
					my %data_category = read_table($dbh,'data_categories',$test_id_cat);	
					$titre = get_traduction({id=>$data_category{id_textid_name},lg=>$config{current_language}});
					$url_cat = $config{baseurl}.'/'.$url_moteur.'/'.get_url({debug=>0,nom_table=>'data_categories',id_table=>$data_category{id}, id_language => $config{current_language}});
					
					#si la catégorie ne correspond pas à la catégorie forcée
					if($config{force_breadcrumb_category_of_father} > 0 && $config{force_breadcrumb_category_of_father} != $rew_fathers_cats{$data_category{id}})
					{
						foreach my $num_param (1 .. 10)
						{
							#trouver la catégorie qui correspond
							my $param = get_quoted('s'.$num_param);
							if($param !~ /^\d+$/) {next;}
							if($rew_fathers_cats{$param} == $config{force_breadcrumb_category_of_father})
							{
								my %cat = sql_line({table=>'data_categories',where=>"id='$param'"});
								$url_cat .= '/'.get_url({debug=>0,nom_table=>'data_categories',id_table=>$param, id_language => $config{current_language}});
							}
						}
					}
				}
				else
				{
					next;
				}
				
				$breadcrumb .= <<"EOH";
				<li><a href="$url_cat/1">$titre</a></li>
EOH
			}
			
			$url .= 1;
			
			$breadcrumb .= <<"EOH";
				<li><a href="">Page 1</a></li>
EOH
	   }
	   elsif($type_breadcrumb eq 'data_detail')
	   {
			my $MapRewrite = get_quoted('MapRewrite');
			my @pars = split(/\-/,$MapRewrite);
			my $extlink = pop @pars; 
			my $id_data_sheet = pop @pars; 
			my %data_sheet = read_table($dbh,'data_sheets',$id_data_sheet);
			my %data_family = read_table($dbh,'data_families',$data_sheet{id_data_family});
			my %data_field = read_table($dbh,'data_fields',$data_family{id_field_name});
			my %data_search_form = read_table($dbh,'data_search_forms',$data_family{id_default_search_form});
			
			my $titre_moteur = get_traduction({id=>$data_search_form{id_textid_name},lg=>$config{current_language}});
			my $url_moteur = get_url({debug=>0,nom_table=>'data_search_form',id_table=>$data_search_form{id}, id_language => $config{current_language}});
			my $url_moteur_finale = $url_moteur;
			my $titre_sheet = get_traduction({id=>$data_sheet{'f'.$data_field{ordby}},lg=>$config{current_language}});
			if($sitetxt{breadcrumb_data_detail_alt} ne '')
			{
				$url_moteur_finale = $sitetxt{breadcrumb_data_detail_alt};
			}
			$breadcrumb .= <<"EOH";
					<li><a href="/$url_moteur_finale">$titre_moteur </a></li>
EOH
			if($config{breadcrumb_detail_show_category_of_father} > 0)
			{
				my %cat = sql_line({table=>'data_lnk_sheets_categories lnk, data_categories c',where=>"c.id = lnk.id_data_category AND id_data_sheet=$data_sheet{id} AND c.id_father = $config{breadcrumb_detail_show_category_of_father}"});
				my $titre_cat = get_traduction({id=>$cat{id_textid_name},lg=>$config{current_language}});
				my $url_cat = $url_moteur.'/'.$sitetxt{breadcrumb_data_detail_sup}.get_url({debug=>0,nom_table=>'data_categories',id_table=>$cat{id}, id_language => $config{current_language}}).'/1';
				
				$breadcrumb .= <<"EOH";
						<li><a href="/$url_cat">$titre_cat</a></li>
EOH
			}
			
			if($config{breadcrumb_detail_show_categories_linked} > 0)
			{
				my @data_lnk_sheets_categories = sql_lines({debug=>1,debug_results=>1,select=>"id_data_category",table=>'data_lnk_sheets_categories lnk, data_categories c',where=>"lnk.id_data_category = c.id AND c.visible='y' AND id_data_sheet='$data_sheet{id}'"});
				foreach $data_lnk_sheets_categorie (@data_lnk_sheets_categories)
				{	
					my %data_lnk_sheets_categorie = %{$data_lnk_sheets_categorie};
					
					my %cat = sql_line({table=>'data_categories c',where=>"id=$data_lnk_sheets_categorie{id_data_category}"});
					my $titre_cat = get_traduction({id=>$cat{id_textid_name},lg=>$config{current_language}});
					my $url_cat = $url_moteur.'/'.$sitetxt{breadcrumb_data_detail_sup}.get_url({debug=>0,nom_table=>'data_categories',id_table=>$cat{id}, id_language => $config{current_language}}).'/1';
					$breadcrumb .= <<"EOH";
						<li><a href="$url_cat">$titre_cat</a></li>
EOH
				}
			}
			
			
			
			
			$breadcrumb .= <<"EOH";
					<li><a href="">$titre_sheet</a></li>
EOH
	   }
	   elsif($type_breadcrumb eq 'membre')
	   {
			$breadcrumb .= <<"EOH";
					<li><a href="/cgi-bin/members.pl?lg=$d{lg}">$sitetxt{myaccount}</a></li>
EOH
	   }
	   elsif($type_breadcrumb eq 'eshop')
	   {
			# $breadcrumb .= <<"EOH";
					# <li><a href="$sitetxt{eshop_url_panier}">Panier</a></li>
# EOH
	   }
	   elsif($type_breadcrumb eq 'page')
	   {
			my $titre_page = get_traduction({id=>$page{id_textid_name},lg=>$config{current_language}});
			
			#parents
			my $listeParents = "";
			my %parent = sql_line({table=>'migcms_pages',where=>"id='$page{id_father}'"});
			while($parent{id} > 0)
			{
				my $titre_page_parent = get_traduction({id=>$parent{id_textid_name},lg=>$config{current_language}});
				my $url_page_parent = '';

				if($parent{visible} eq 'y')
				{
					my $url_page_parent = '#';
					if($parent{migcms_pages_type} eq 'page')
					{
						$url_page_parent = $config{baseurl}.'/'.get_url({debug=>0,nom_table=>'migcms_pages',id_table=>$parent{id}, id_language => $config{current_language}});
					}
					$listeParents =<<"EOH";
					<li><a href="$url_page_parent">$titre_page_parent</a></li>
					$listeParents
EOH
				}
				%parent = sql_line({table=>'migcms_pages',where=>"id='$parent{id_father}'"});
			}

			$breadcrumb .= <<"EOH";
					$listeParents
					<li><a href="">$titre_page</a></li>
EOH
	   }
	   else
	   {
			# $breadcrumb = $type_breadcrumb;
			# $breadcrumb .= "";
	   }
	   
	   
	   $breadcrumb .= <<"EOH";
		</ol><!-- Fin du breadcrumb $type_breadcrumb --> 
EOH
	   
	   if($type_breadcrumb eq 'eshop')
	   {
	   }
	   
	   while ($d{template} =~ /$tag/g)
	   {
		  $d{template} =~ s/$tag/$breadcrumb/g;
		}
   }
   
	 
			
		my $tag = '<MIGC_DATA_LISTINGIDFATHER_HERE>';
		if(/$tag/)
		{
			my $id_father = get_quoted('id_father');
			$d{template} =~ s/$tag/$id_father/g;
		}
		
		my $tag = '<MIGC_DATA_LISTINGS1_HERE>';
		if(/$tag/)
		{
			my $s1 = get_quoted('s1');
			$d{template} =~ s/$tag/$s1/g;
		}
		
		my $tag = '<MIGC_DATA_LISTINGS1FATHERCAT_HERE>';
		if(/$tag/)
		{
			my $s1 = get_quoted('s1');
			if($s1>0)
			{
				my %cat = read_table($dbh,'data_categories',$s1);
				$d{template} =~ s/$tag/$cat{id_father}/g;
			}
		}
			my $tag = '<MIGC_LISTING_LISTINGS1FATHERCAT_HERE>';
		if(/$tag/)
		{
			my $s1 = get_quoted('s1');
			if($s1>0)
			{
				my %cat = read_table($dbh,'data_categories',$s1);
				$d{template} =~ s/$tag/$cat{id_father}/g;
			}
		}

	
	$_ = $d{template};
	my $tag = '<MIGC_DATA_ALLOW_ROBOTS_HERE>';
	if (/$tag/)
    {
		#Autoriser sauf si: mot clé recu, page 2
		my $allow_robot = 'INDEX,FOLLOW';
		
		my $kwReceived = 0;
		foreach my $num_param (1 .. 10)
		{
			my $kwReceivedValue = get_quoted('keyword_s'.$num_param);
			if($kwReceivedValue ne '')
			{
				$kwReceived = 1;
			}
		}
		my $page = get_quoted('page');
		
		if($kwReceived == 1 || $page > 1)
		{
			$allow_robot = 'NOINDEX,NOFOLLOW';
		}
		$d{template} =~ s/$tag/$allow_robot/g;
	}
		
	$_ = $d{template};
	my $tag = '<MIGC_DATA_META_TITLE_HERE>';
	if (/$tag/)
    {
			my $test_sw = get_quoted('sw');
			my $sf = get_quoted('sf');
			my $type_page;
			my $texte;
			if($ENV{SCRIPT_NAME} =~ /data.pl/ && $test_sw eq 'detail')
			{
				$type_page = 'data_detail';
			}
			elsif($ENV{SCRIPT_NAME} =~ /data.pl/ && $test_sw eq 'list_cat')
			{
				$type_page = 'list_cat';
			}

			if($type_page eq "data_detail")
			{
				my $MapRewrite = get_quoted('MapRewrite');
				my @pars = split(/\-/,$MapRewrite);
				my $extlink = pop @pars; 
				my $id_data_sheet = pop @pars; 
				my %data_sheet = read_table($dbh,'data_sheets',$id_data_sheet);		

				#texte de la sheet
				$texte = get_traduction({id=>$data_sheet{id_textid_meta_title},lg=>$d{lg}});
			}
			elsif($type_page eq "list_cat")
			{
				#texte de la famille
				$texte = get_traduction({id=>$data_family{id_textid_meta_title},lg=>$d{lg}});		   
				
				#texte des catégories
				my $texte_categories = '';
				my $test_id_cat = get_quoted('id_father');
				if($test_id_cat > 0)
				{
					my %data_category = read_table($dbh,'data_categories',$test_id_cat);	
					$texte_categories .= ' '.get_traduction({id=>$data_category{id_textid_meta_title},lg=>$config{current_language}});
				}
				$texte_categories = trim($texte_categories);
				
				#remplace le texte de la famille par celui des catégories
				if($texte_categories ne '')
				{
					$texte = $texte_categories;
				}
			}
			else
			{
				#texte de la famille
				$texte = get_traduction({id=>$data_family{id_textid_meta_title},lg=>$d{lg}});		   
				
				#texte des catégories
				my $texte_categories = '';
				foreach my $num_param (1 .. 3)
				{
					my $test_id_cat = get_quoted('s'.$num_param);
					if($test_id_cat > 0)
					{
						my %data_category = read_table($dbh,'data_categories',$test_id_cat);	
						$texte_categories .= ' '.get_traduction({id=>$data_category{id_textid_meta_title},lg=>$config{current_language}});
					}
				}
				$texte_categories = trim($texte_categories);
				
				#remplace le texte de la famille par celui des catégories
				if($texte_categories ne '')
				{
					$texte = $texte_categories;
				}
			}

		while ($d{template} =~ /$tag/g)
		{
			$d{template} =~ s/$tag/$texte/g;
		}
    }
	
	
	$_ = $d{template};
	my $tag = '<MIGC_DATA_META_DESCRIPTION_HERE>';
	if (/$tag/)
    {
			my $test_sw = get_quoted('sw');
			my $sf = get_quoted('sf');
			my $type_page;
			my $texte;
			if($ENV{SCRIPT_NAME} =~ /data.pl/ && $test_sw eq 'detail')
			{
				$type_page = 'data_detail';
			}
			elsif($ENV{SCRIPT_NAME} =~ /data.pl/ && $test_sw eq 'list_cat')
			{
				$type_page = 'list_cat';
			}

			if($type_page eq "data_detail")
			{
				my $MapRewrite = get_quoted('MapRewrite');
				my @pars = split(/\-/,$MapRewrite);
				my $extlink = pop @pars; 
				my $id_data_sheet = pop @pars; 
				my %data_sheet = read_table($dbh,'data_sheets',$id_data_sheet);		

				#texte de la sheet
				$texte = get_traduction({id=>$data_sheet{id_textid_meta_description},lg=>$d{lg}});
			}
			elsif($type_page eq "list_cat")
			{
				#texte de la famille
				$texte = get_traduction({id=>$data_family{id_textid_meta_title},lg=>$d{lg}});		   
				
				#texte des catégories
				my $texte_categories = '';
				my $test_id_cat = get_quoted('id_father');
				if($test_id_cat > 0)
				{
					my %data_category = read_table($dbh,'data_categories',$test_id_cat);	
					$texte_categories .= ' '.get_traduction({id=>$data_category{id_textid_meta_description},lg=>$config{current_language}});
				}
				$texte_categories = trim($texte_categories);
				
				#remplace le texte de la famille par celui des catégories
				if($texte_categories ne '')
				{
					$texte = $texte_categories;
				}
			}
			else
			{
				#texte de la famille
				$texte = get_traduction({id=>$data_family{id_textid_meta_description},lg=>$d{lg}});		   
				
				#texte des catégories
				my $texte_categories = '';
				foreach my $num_param (1 .. 3)
				{
					my $test_id_cat = get_quoted('s'.$num_param);
					if($test_id_cat > 0)
					{
						my %data_category = read_table($dbh,'data_categories',$test_id_cat);	
						$texte_categories .= ' '.get_traduction({id=>$data_category{id_textid_meta_description},lg=>$config{current_language}});
					}
				}
				$texte_categories = trim($texte_categories);
				
				#remplace le texte de la famille par celui des catégories
				if($texte_categories ne '')
				{
					$texte = $texte_categories;
				}
			}

		while ($d{template} =~ /$tag/g)
		{
			$d{template} =~ s/$tag/$texte/g;
		}
    }
	
	
   $_ = $d{template};
   #LGID
   my $tag = '<MIGC_LGID_HERE>';
   if (/$tag/)
   {
	   while ($d{template} =~ /$tag/g)
	   {
		  $d{template} =~ s/$tag/$d{lg}/g;
	   }
   } 
    $_ = $d{template};
    #IDPAGE
   my $tag = '<MIGC_IDPAGE_HERE>';
   if (/$tag/)
   {
	   while ($d{template} =~ /$tag/g)
	   {
		  $d{template} =~ s/$tag/$d{id_page}/g;
	   }
   }
   my $tag = '<MIGC_PAGEID_HERE>';
   if (/$tag/)
   {
	   while ($d{template} =~ /$tag/g)
	   {
		  $d{template} =~ s/$tag/$d{id_page}/g;
	   }
   }

   my $tag = '<MIGC_FULLURL_HERE>';
   if (/$tag/)
   {
	   my $full_url_param = $config{fullurl};
	   if($page{id_fathers} ne '' && $config{baseurl_1_for_page} > 0 && $page{id_fathers} =~ /\,$config{baseurl_1_for_page}\,/)
		{
			$full_url_param = $config{baseurl_1};
		}
		if($page{id_fathers} ne '' && $config{baseurl_2_for_page} > 0 && $page{id_fathers} =~ /\,$config{baseurl_2_for_page}\,/)
		{
			$full_url_param = $config{baseurl_2};
		}
		if($page{id} eq '')
		{
			my $env_self = 'http://';
			if($ENV{HTTPS} eq 'on')
			{
				$env_self = 'https://';
			}
			$env_self .= $ENV{HTTP_HOST};
			$full_url_param = $env_self;
		}
		while ($d{template} =~ /$tag/g)
		{
			$d{template} =~ s/$tag/$full_url_param/g;
		}
   }    
   
   #LANGUAGES
   my $tag = '<MIGC_LANGUAGES_HERE>';
   if (/$tag/)
   {
	   my %sels=();
	   $sels{$d{lg}} = 'migc_selitem';

	   my $lg_menu = '';
	   my @lgs = sql_lines({table=>'migcms_languages',ordby=>'id',where=>'visible="y"'});
	   foreach $lg_rec (@lgs)
	   {
			my %lg_rec = %{$lg_rec};
			
			my $link = $config{baseurl}.'/'.$lg_rec{name}.'/';
			if($d{id_page} > 0)
			{
				$link = $config{baseurl}.'/'.get_url({debug=>0,nom_table=>'migcms_pages',id_table=>$d{id_page}, id_language => $lg_rec{id}});
			}
			else
			{
				$link = $config{baseurl}.'/'.get_url({debug=>0,nom_table=>'migcms_pages',id_table=>$migcms_setup{id_default_page}, id_language => $lg_rec{id}});
			}
			
			$lg_menu .=<<"EOH";
				<li><a href="$link" class="$sels{$lg_rec{id}}"><span class="icon-$lg_rec{display_name}"></span> $lg_rec{display_name}</a></li>
EOH
	   }
	   while ($d{template} =~ /$tag/g)
	   {
		  $d{template} =~ s/$tag/$lg_menu/g;
	   }
   }
	
   my $tag = '<MIGC_ESHOP_CART_BOX_HERE>';
   if(/$tag/)
   {
	  my $eshop_cart_box = eshop::get_eshop_cart_box($d{lg});
      $d{template} =~ s/$tag/$eshop_cart_box/g;
   }

   my $tag = '<MIGC_MEMBER_LOGOUT_HERE>';
   if(/$tag/)
   {
	  my $member_logout = eshop::get_member_logout($d{lg});
      $d{template} =~ s/$tag/$member_logout/g;
   }
   
   my $tag = '<MIGC_ESHOP_MEMBER_BOX_HERE>';
   if (/$tag/)
   {
      my $eshop_member_box = eshop::get_eshop_member_box($d{lg});
      $d{template} =~ s/$tag/$eshop_member_box/g;
   }
	$_ = $d{template};
	

	
	# see();
	#PAGES
    my @pages = (/<MIGC_PAGE_\[(\w+)\]_HERE>/g);
	for ($i = 0; $i<=$#pages; $i++ ) 
	{		
		
		

		my %migcms_page = read_table($dbh,'migcms_pages',$pages[$i]);
		
		
	
		
		
		if($migcms_page{migcms_pages_type} eq 'directory')
		{
			#lien vers un dossier: pas de logique actuellement
		}
		elsif($migcms_page{migcms_pages_type} eq 'page')
		{
			#lien vers une page
			my $url_page = get_url({mailing=>$d{mailing},preview=>$d{preview},from=>'render_tags',debug=>0,debug_results=>0,nom_table=>'migcms_pages',id_table=>$pages[$i], id_language => $d{lg}});
			
			if($d{mailing} eq 'y')
			{
				my $full_url_param = $config{fullurl};
				if($migcms_page{id_fathers} ne '' && $config{sitemap_1_for_page} > 0 && $migcms_page{id_fathers} =~ /\,$config{sitemap_1_for_page}\,/)
				{
					$full_url_param = $config{baseurl_1};
				}
				if($migcms_page{id_fathers} ne '' && $config{sitemap_2_for_page} > 0 && $migcms_page{id_fathers} =~ /\,$config{sitemap_2_for_page}\,/)
				{
					$full_url_param = $config{baseurl_2};
				}
				$url_page = $full_url_param.$config{baseurl}."/".$url_page;
			}
			else
			{
				$url_page = $config{baseurl}."/".$url_page;
			}
			$url_page =~ s/\/\//\//g;
			
			if($one_language_site == 1 && ($migcms_page{id} == $migcms_setup{id_default_page} || $migcms_page{id} == $config{id_default_page2}) && $migcms_setup{id_default_page} > 0 )
			{
				#cas site en 1 langue et page d'accueil: url spéciale
				$url_page = $config{baseurl};
			}
			
				# print "<br />[$migcms_page{migcms_pages_type}]";
				# print "<br />[$pages[$i]]";
				# print "<br />[$url_page]";
			
			
		
			$pat = '<MIGC_PAGE_['.$pages[$i].']_HERE>';
			# print $d{template};
			# print $pat;
			# exit;
			$d{template} =~ s/$pat/$url_page/g;
						# print "<br />[$d{template}]";
					
		}
		else
		{
			#lien vers un lien
			my $url_page = get_link_page({migcms_page=>\%migcms_page,mailing=>$d{mailing}});
			$url_page =~ s/\/\//\//g;
			log_debug("PAGE:".$pages[$i],"","PAGE");
			log_debug($url_page,"","PAGE");
			$pat = '<MIGC_PAGE_\['.$pages[$i].'\]_HERE>';
			$d{template} =~ s/$pat/$url_page/g;
		}
	} 	
	
	$_ = $d{template};
	#url vers la page en cours
	my $tag = '<MIGC_CANONICALURL_HERE>';
			

	if (/$tag/)
	{
		log_debug(Dumper(\%ENV),'','dataenv');
		my $type_elt = '';
		if($ENV{SCRIPT_NAME} =~ /data.pl/ && $test_sw eq 'list_cat')
		{
			$type_elt = 'data_listcat';
		}
		elsif($ENV{SCRIPT_NAME} =~ /data.pl/ && ($test_sw eq 'list' || $test_sw eq ''))
		{
			$type_elt = 'data_list';
		}
		elsif($ENV{SCRIPT_NAME} =~ /data.pl/ && ($test_sw eq 'detail'))
		{
			$type_elt = 'data_detail';
		}
		elsif($ENV{SCRIPT_NAME} =~ /adm_migcms_build.pl/ || $ENV{SCRIPT_NAME} =~ /migcms_view.pl/)
		{
			$type_elt = 'page';
		}
		else		
		{
			$type_elt = $ENV{SCRIPT_NAME};
		}
		
		
		
		my $url = "";
		if($type_elt eq 'page')
		{
			#cas d'une page
			$url = get_url({from=>'canonicalurl',preview=>$d{preview},debug=>0,debug_results=>0,nom_table=>'migcms_pages',id_table=>$page{id}, id_language => $d{lg}});
			if($one_language_site == 1 && ($page{id} == $migcms_setup{id_default_page} || $page{id} == $config{id_default_page2}) && $migcms_setup{id_default_page} > 0 )
			{
				#cas site en 1 langue et page d'accueil: url spéciale
				$url = $config{baseurl};
			}
		}
		else
		{
			$url = $ENV{SCRIPT_URL};
			if($url eq '')
			{
				$url = $ENV{REQUEST_URI};
			}
			$url =~ s/^\///g;
		}
	
		$d{template} =~ s/$tag/$url/g;		
	}
	
	$_ = $d{template};
	#MAINMENU
	my $tag = '<MIGC_MAINMENU_HERE>';
    if (/$tag/)
    {
	  my $menu = mig_menu_tree({id => $page{id},type_page=>$d{type_page},preview=>$d{preview},id_father => 0, viewer => $viewer,maxlevel => $config{mainmenu_maxlevel}, lg => $d{lg}, preview => $d{preview}});
      $d{template} =~ s/$tag/$menu/g;
    }
	$_ = $d{template};
	#SUBMENU
	my $tag = '<MIGC_SUBMENU_HERE>';
	if (/$tag/)
	{
		my $submenu = mig_menu_tree({id => $page{id},type_page=>$d{type_page},preview=>$d{preview}, id_father => $page{id_father}, viewer => $viewer,maxlevel => $config{mainmenu_maxlevel}, lg => $d{lg}, preview => $d{preview}});
		$d{template} =~ s/$tag/$submenu/g;
	}
	$_ = $d{template};
	my @menus = (/<MIGC_MAINMENU_BOOTSTRAP\[(\w+)\]_HERE>/g);
	for ($i = 0; $i<=$#menus; $i++ ) 
	{		
		my $submenu = mig_menu_tree({type=>'bootstrap',type_page=>$d{type_page},preview=>$d{preview},id => $page{id}, id_father => $menus[$i], viewer => $viewer,maxlevel => $config{mainmenu_maxlevel}, lg => $d{lg}, preview => $d{preview}});
		$tag = '<MIGC_MAINMENU_BOOTSTRAP\['.$menus[$i].'\]_HERE>';
		$d{template} =~ s/$tag/$submenu/g;
	} 
	$_ = $d{template};
	#CHILDRENMENU
	my $tag = '<MIGC_CHILDRENMENU_HERE>';
	if (/$tag/)
	{
		my $submenu = mig_menu_tree({id => $page{id},type_page=>$d{type_page},preview=>$d{preview}, id_father => $page{id}, viewer => $viewer,maxlevel => $config{mainmenu_maxlevel}, lg => $d{lg}, preview => $d{preview}});
		$d{template} =~ s/$tag/$submenu/g;
	}
	$_ = $d{template};
	#FATHERTITLE
	my $tag = '<MIGC_FATHERTITLE_HERE>';
	if (/$tag/)
	{
		my %page_father = sql_line({debug_results=>0,dbh=>$dbh_data,table=>"migcms_pages",where=>"id='$page{id_father}'"});
		($title_father,$dum) = get_textcontent ($dbh,$page_father{id_textid_name});
		$d{template} =~ s/$tag/$title_father/g;
	}

	
	$_ = $d{template};
	#CURRENT_YEAR
	my $tag = '<MIGC_CURRENT_YEAR_HERE>';
	if (/$tag/)
	{
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); 
		$year+=1900;
		$d{template} =~ s/$tag/$year/g;
	}
	$_ = $d{template};
	#LANGUAGE_CODE
	my $tag = '<MIGC_LANGUAGE_CODE_HERE>';
	if (/$tag/)
	{
		my %language = read_table($dbh,"migcms_languages",$d{lg});
		if($language{name} eq '')
		{
			$language{name} = 'fr';
		}
		$d{template} =~ s/$tag/$language{name}/g;
	}
	$_ = $d{template};
	#MEMBER link logout
	my $tag = '<MIGC_MEMBERS_LOGOUTLINK_HERE>';
	my $turl = $urlrew{member_logout_db}{$d{lg}};
	if (/$tag/)
	{
		my $logout_link = "$config{baseurl}/$turl";
		$d{template} =~ s/$tag/$logout_link/g;
	}


	
	
	
	# REMPLACEMENT DU TEXTE
	$_ = $d{template}; 
	if(/MIGC_TXT/)
	{
		$d{template}  =~ s/<MIGC_TXT_\[(.*?)\]_HERE>/$sitetxt{$1}/g;
	} 
	
	# REMPLACEMENT DU LIEN
	$_ = $d{template}; 
	my @lnks = (/<MIGC_LNK_\[(\w+)\]_HERE>/g);
	for ($i = 0; $i<=$#lnks; $i++ ) 
	{		
		
		my $value = render_tags_lnk($lnks[$i],$d{lg});
		$tag = '<MIGC_LNK_\['.$lnks[$i].'\]_HERE>';
		$d{template} =~ s/$tag/$value/g;
	}

	#BALISES
	my $tag = 'MIGC_BALISES_\[(.*?)\]_HERE';
	$_ = $d{template}; 
	if (/$tag/)
	{	
		$d{template} =~ s/&lt;MIGC_BALISES_\[(.*?)\]_HERE&gt;/$balises{$1}/g;
		$d{template} =~ s/<MIGC_BALISES_\[(.*?)\]_HERE>/$balises{$1}/g;
	}

	# META_TITLE ESHOP
	my $tag = '<MIGC_METATITLE_SHOP_HERE>';
	$_ = $d{template}; 
	if (/$tag/)
  {
   	my $test_sw = get_quoted('sw');
   	my $value = $sitetxt{'eshop_metatitle_'.$test_sw};
		$d{template} =~ s/$tag/$value/g;
	}

	#clean last tags sauf unubscribe (remplacé dans le mailer)
	# $d{template}  =~ s/<MIGC(?!_UNSUBSCRIBE_URL).*_HERE>//g;
	
	my $tag = '<MIGC_(.*?)_HERE>';
	$_ = $d{template}; 
	my @lnks = (/<MIGC_([a-zA-Z0-9\_]*)_HERE>/g);
	for ($i = 0; $i<=$#lnks; $i++ ) 
	{		
		$tag = '<MIGC_'.$lnks[$i].'_HERE>';
		if($lnks[$i] ne 'UNSUBSCRIBE_URL' && $lnks[$i] ne 'MAILER_URL')
		{
			$d{template} =~ s/$tag//g;
		}
	}
	
   return $d{template};
}

sub render_tags_lnk
{
	
	my $id_page = $_[0];
	my $lg = $_[1];
	my %migcms_page_link = sql_line({debug=>0,debug_results=>0,table=>'migcms_pages,migcms_links',where=>"migcms_pages.id_migcms_link = migcms_links.id AND migcms_pages.id='$id_page'"});
	my $link_traduction = get_traduction({id=>$migcms_page_link{id_textid_link_url},id_language=>$lg});
	return $link_traduction;
}

sub render_tags_data_get_sheets
{
	my $id_migcms_data_getsheets = $_[0];
	my $lg = $_[1];
	
	my %migcms_data_getsheets = sql_line({table=>'migcms_data_getsheets',where=>"id='$id_migcms_data_getsheets'"});
	my %data_setup = %{data::data_get_setup()};

	 my %data_family = read_table($dbh,"data_families",$migcms_data_getsheets{id_data_family}); 
	 my $nr = $migcms_data_getsheets{getsheets_limit};
   my %tarif = ();
	 if($data_family{has_tarifs} eq 'y')
	 {
		 $id_tarif = eshop::eshop_get_id_tarif_member();
		 %tarif = read_table($dbh,"eshop_tarifs",$id_tarif);                                             
   }

	 my ($list_sheets,$nb_total_resultats) = data::compute_sheets({data_setup=>\%data_setup,data_family=>\%data_family,tarif=>\%tarif,current_page=>1,force_id_data_category=>$migcms_data_getsheets{getsheets_where_id_category},add_where=>$migcms_data_getsheets{getsheets_where},force_id_template_object=>$migcms_data_getsheets{id_template_object},force_ordby=>$migcms_data_getsheets{getsheets_ordby},nr=>$nr,lg=>$lg,related_sheets=>$migcms_data_getsheets{related_sheets},getsheets_custom_function_where=>$migcms_data_getsheets{getsheets_custom_function_where}});

	return $list_sheets;
}

###############################################################################
# MAINMENU_TREE
###############################################################################
sub mig_menu_tree
{
	my %d = %{$_[0]};
	
	my %selitem = ();
	use Data::Dumper;
	
	my %sel_page = sql_line({debug=>1,debug_results=>1,select=>"id,id_fathers",table=>'migcms_pages',where=>"id='".$d{id}."'"});
	my @liste_of_fathers = split(/\,/,$sel_page{id_fathers});
	foreach my $fat (@liste_of_fathers)
	{
		if($fat > 0)
		{
			$selitem{$fat} = 'migc_selitem';	
		}
	}
	
	$selitem{$d{id}} = 'migc_selitem';	
	
	my $tree = '';
	if ($d{level} >= $d{maxlevel}) { return "";}

	#boucle sur les "pages" types: directory, link ou page (contenu) du parent
	my @migcms_pages = sql_lines({debug=>0,debug_results=>0,table=>'migcms_pages',where=>"id_father='$d{id_father}' AND visible='y' AND migcms_deleted ='n' AND migcms_pages_type IN ('directory','link','page')",ordby=>'ordby'});
	foreach $migcms_page (@migcms_pages)
	{
		my %migcms_page = %{$migcms_page};
		
		

		if($d{level} eq '')
		{
			$d{level} = 0;
		}

		if($d{level} >= 0)
		{
			my $id = 'menuid_'.$migcms_page{id};
			my $page_id = $migcms_page{id};
			my $page_id_bck = $migcms_page{id};
			my $link = '#';
			my $url_rewriting = '';
			
			
			my ($name,$dum) = get_textcontent($dbh,$migcms_page{id_textid_name},$d{lg});
	
			my %page_enfant = ();
			
			if($migcms_page{migcms_pages_type} eq 'directory')
			{
				#DIRECTORY -> on cherche l'url du premier enfant 
				%page_enfant = sql_line({debug=>0,debug_results=>0,table=>'migcms_pages',where=>"id_father='$migcms_page{id}'",ordby=>'ordby',limit=>'0,1'});
				if($page_enfant{migcms_pages_type} ne 'page' && $page_enfant{migcms_pages_type} ne 'link')
				{
					%page_enfant = sql_line({debug=>0,debug_results=>0,table=>'migcms_pages',where=>"id_father='$page_enfant{id}'",ordby=>'ordby',limit=>'0,1'});
					if($page_enfant{migcms_pages_type} ne 'page')
					{
						%page_enfant = sql_line({debug=>0,debug_results=>0,table=>'migcms_pages',where=>"id_father='$page_enfant{id}'",ordby=>'ordby',limit=>'0,1'});
					}
				}	
				elsif($page_enfant{migcms_pages_type} eq 'link')
				{
					$url_rewriting = get_link_page({migcms_page=>\%page_enfant,preview=>$d{preview}});
				}
				else
				{			
					$page_id = $page_enfant{id};
					$url_rewriting = $config{baseurl}.'/'.get_url({from=>'directory',debug=>0,nom_table=>'migcms_pages',id_table=>$page_enfant{id}, id_language => $d{lg}});
					if($d{preview} eq 'y')
					{
						$url_rewriting = $config{baseurl}.'/cgi-bin/migcms_view.pl?lg='.$d{lg}.'&id_page='.$page_id.'&edit='.get_quoted('edit');
					}
				}
			}
			elsif($migcms_page{migcms_pages_type} eq 'page')
			{
				#PAGE, on cherche directement l'url
				if($one_language_site == 1 && (($page_id == $migcms_setup{id_default_page} && $migcms_setup{id_default_page} > 0) || ($page_id == $config{id_default_page2} && $config{id_default_page2} > 0)))
				{
					#cas site en 1 langue et page d'accueil: url spéciale
					$url_rewriting = $config{baseurl}.'/';
					if($d{preview} eq 'y' && $d{type_page} ne 'private')
					{
						$url_rewriting = $config{baseurl}.'/cgi-bin/migcms_view.pl?lg='.$d{lg}.'&id_page='.$migcms_setup{id_default_page}.'&edit='.get_quoted('edit');
					}
				}
				else
				{
					$url_rewriting = $config{baseurl}.'/'.get_url({from=>'migmenutree',type_page=>$d{type_page},preview=>$d{preview},debug=>$debug,debug_results=>$debug,nom_table=>'migcms_pages',id_table=>$page_id, id_language => $d{lg}});
					if($d{preview} eq 'y' && $d{type_page} ne 'private')
					{
						$url_rewriting = $config{baseurl}.'/cgi-bin/migcms_view.pl?lg='.$d{lg}.'&id_page='.$migcms_page{id}.'&edit='.get_quoted('edit');
					}
				}
			}
			else
			{
				#LIEN, on cherche directement l'url 
				$url_rewriting = get_link_page({migcms_page=>\%migcms_page,preview=>$d{preview}});

			}
			
			
			$url_rewriting =~ s/^\/\//\//g;
			
			#si l'url n'est pas complète et ne commence par par un /, il faut le forcer
			if($url_rewriting !~ m=^http= && $url_rewriting !~ m=^/=)
			{
				$url_rewriting = '/'.$url_rewriting;
			}
			
			my $link_url = $url_rewriting;
			
			
			#MODE APERCU: sans url rewriting
			# if($d{preview} eq 'y' && $migcms_page{migcms_pages_type} eq 'page')
			# {
				# my $id_page = $page_enfant{id} || $migcms_page{id};
				# $link_url = $config{baseurl}.'/cgi-bin/migcms_view.pl?lg='.$d{lg}.'&id_page='.$id_page.'&edit='.get_quoted('edit');
			# }
			
			my $caret = '';
			my %count_migcms_pages = sql_line({debug=>0,debug_results=>0,table=>'migcms_pages',select=>"count(*) as nb",where=>"id_father='$migcms_page{id}' AND visible='y'",ordby=>'ordby'});
			if($count_migcms_pages{nb} > 0)
			{
				 $caret = '<span class="caret"></span>';
			}

			my $submenu .= mig_menu_tree({id=>$d{id},type_page=>$d{type_page},type=>$d{type},id_father => $migcms_page{id},preview=>$d{preview}, level => ($d{level}+1), viewer => $d{viewer}, maxlevel => $d{maxlevel}+5, lg=> $d{lg}});
		
			my $type_class = ' ';
			my $type_autre = ' class=" ';
			if($d{type} eq 'bootstrap' && $submenu ne '')
			{
				$type_class = 'dropdown';
				$type_autre = ' data-toggle="dropdown" class="dropdown-toggle ';
			}
			my $test_url = $ENV{REQUEST_URI};
			$test_url =~ s/$config{rewrite_directory}//g;
			
			
			my $alt_selitem = '';
			
			my $test_url_sans_slash = $test_url;
			my $link_url_sans_slash = $link_url;
			$test_url_sans_slash =~ s/\///g;
			$link_url_sans_slash =~ s/\///g;
			# log_debug("if($test_url eq '/'.$link_url || $test_url eq $link_url || $test_url =~ /^$link_url/ || $test_url_sans_slash =~ /$link_url_sans_slash/)","","test sel item");
			if($test_url eq '/'.$link_url || $test_url eq $link_url || $test_url =~ /^$link_url/ || $test_url_sans_slash =~ /$link_url_sans_slash/)
			{
				$alt_selitem = 'migc_selitem';
			}
			
			if($link_url =~ /member_logout_db/)
			{
				$selitem{$page_id_bck} = $alt_selitem = '';
			}
			
			# my $dumpLog = Dumper(\%selitem);
			# $tree .= '<li  id="'.$id.'" class="'.$type_class.' mig_type_'.$migcms_page{migcms_pages_type}.'" ><a rel="test" datasels="'.$d{sels}.'" href="'.$link_url.'" '.$type_autre.' '.$selitem{$page_id_bck}.' '.$alt_selitem.'"><span>'.$name.$dumpLog.'|'.$d{id}.' '.$caret.'</span></a>';
			my $blank ="";
			if($migcms_page{blanktarget} eq 'y')
			{
				$blank = ' target="_blank" ';
			}
			
			$tree .= '<li  id="'.$id.'" data-type-lien="'.$migcms_page{type_lien}.'" data-type-page-enfant="'.$page_enfant{migcms_pages_type}.'" data-type-lien-page-enfant="'.$page_enfant{type_lien}.'" class="'.$type_class.' mig_type_'.$migcms_page{migcms_pages_type}.'" ><a '.$blank.' datasels="'.$d{sels}.'" href="'.$link_url.'" '.$type_autre.' '.$selitem{$page_id_bck}.' '.$alt_selitem.'"><span>'.$name.' '.$caret.'</span></a>';
			
			if($submenu ne '')
			{
				my $type_class = ' ';
				if($d{type} eq 'bootstrap')
				{
					$type_class = 'dropdown-menu';
				}
				$tree.='<ul class="'.$type_class.'">'.$submenu.'</ul>';
			}

			$tree .= '</li>';			
		}
		
	}
	return $tree;
} 
 


sub block_main_menu
{
	 my %d = %{$_[0]};
	 my $menu = mig_menu_tree({id => $contextual, type_page => $d{type_page}, id_father => $d{id_father}, viewer => $viewer,maxlevel => $config{mainmenu_maxlevel}, lg => $lg, preview => $d{preview},edit=>$d{edit}});
	 return $menu;
}

sub block_mailing_subscribe
{
 	#my %d = %{$_[0]} ;
	my $params = $_[0];
	$params =~ s/\)//;
	
	my $tpl = $params;

 	#my $index_first_parenthese = index($d{block}{function}, "(");
	#my $index_last_parenthese = rindex($d{block}{function}, ")");
	#my $longueur = $index_last_parenthese - $index_first_parenthese;

 	#my $tpl = trim(substr $d{block}{function}, $index_first_parenthese+1, $longueur-1);

 	if($tpl > 0)
 	{
 		$tpl = get_template({id=>$tpl,lg=>$config{current_language}});
 	}

	my $phrase_ok = $sitetxt{mailing_add_msg_ok};
	my $phrase_ko = $sitetxt{mailing_add_msg_ko};
	my $phrase_deja = $sitetxt{mailing_add_msg_deja};
	my $phrase_remove_ok = $sitetxt{mailing_remove_msg_ok};
	my $phrase_remove_ko = $sitetxt{mailing_remove_msg_ko};
	my $required = "required";
	
	my $begin_form = "<form action=\"$config{fullurl}/cgi-bin/members.pl\" id=\"newsletter_form\" method=\"post\">";
 	my $end_form = "</form>";
	
	my $groups = "";
	my $groups_ids = "";
	my $groups_checked = "";
		
	$_ = $tpl;
	my @groups = (/<MIGC_MAILING_GROUPS_(\w+)_HERE>/g);
	for (my $i = 0; $i<=$#groups; $i++ ) 
	{		
		if ($groups[$i] > 0) 
		{
			my $id_group = $groups[$i];
			$pat = "<MIGC_MAILING_GROUPS_".$id_group."_HERE>";
			
			my @tags = sql_lines({table=>'migcms_members_tags', where=>"id_migcms_member_dir='$groups[$group]' AND visible='y'",ordby=>'ordby'});
			foreach my $tag (@tags)
			{
				my %tag = %{$tag};
				
				my $group_id = $tag{id};
				my $group_name = $tag{name};
				
				$groups_ids .= $group_id.",";
				
				$groups .=<<"EOH";
				<div class="checkbox">
					<label>
						<input type="checkbox" id="group_$group_id" name="group_$group_id" value="y" checked> $group_name
					</label>
				</div>
EOH
			}
			
			$tpl =~ s/$pat/$groups/g;
			
		}
	}

	my $hidden =<<"EOH";
	 	<input type="hidden" name="sw" value="member_mailing_subscribe_db">
		<input type="hidden" name="lg" value="$config{current_language}">
 		<input type="hidden" name="tags" value=",103,">
 		<input type="hidden" name="groups" value="$groups_ids">
EOH
	

	$tpl =~ s/<MIGC_MAILING_FORM_BEGIN_HERE>/$begin_form/;	
	$tpl =~ s/<MIGC_MAILING_HIDDEN_HERE>/$hidden/;	
	#$tpl =~ s/<MIGC_MAILING_GROUPS_HERE>/$groups/;	
	#$tpl =~ s/<MIGC_MAILING_GROUPS_CHECKED_HERE>/$groups_checked/;	
	$tpl =~ s/<MIGC_MAILING_FORM_END_HERE>/$end_form/;
 
 	return ("",$tpl);
}


sub migc_search_form
{
    # my %cfg = eval("%cfg = ($config{search_cfg});");
    # my $search_form_tpl = get_template($dbh,$cfg{search_form});
    # my $lg=get_quoted('lg') || $config{current_language} || 1;
    # my $keyword=get_quoted('keyword') || "";
    # my $extlink = $cfg{extlink};
    
    
    # $search_form_tpl =~ s/<MIGC_SEARCH_KEYWORD_HERE>/$keyword/;
    # $search_form_tpl =~ s/<MIGC_SEARCH_LANGUAGE_HERE>/$lg/; 
    # $search_form_tpl =~ s/<MIGC_SEARCH_EXTLINK_HERE>/$extlink/; 
    
    return $search_form_tpl;
}

###############################################################################
# GET_OBJ_NAME
###############################################################################

sub get_obj_name
{
	my $dbh = $_[0];
	my $id = $_[1];
	my $table = $_[2];
	my $lg = $_[3] || $config{current_language};
	my $field = $_[4] || 'id_textid_name';
	my ($stmt,$cursor,$rc);

	my %rec = sql_line({select=>$field,table=>$table,where=>"id='$id'"});
	my ($name,$dummy) = get_textcontent($dbh,$id_textid_name,$lg);	
	return $name;
}

 sub is_page_protected
{
	my %d = %{$_[0]};
	my $page_protegee = 1;
	
	if($d{id_page} > 0)
	{
		my %page = sql_line({debug=>$d{debug},debug_results=>$d{debug},table=>"migcms_pages",where=>"id='$d{id_page}'"});
		my %migcms_lnk_page_group = sql_line({debug=>$d{debug},debug_results=>$d{debug},table=>'migcms_lnk_page_groups',where=>"is_linked='y' AND id_migcms_page='$page{id}' "});
		if($migcms_lnk_page_group{id} > 0)
		{
			return 1;
		}
		else
		{
			return 'page_not_protected';
		}
	}
	else
	{
		return 0;
	}
}

sub get_link_page
{
	my %d = %{$_[0]};
	my %migcms_page = %{$d{migcms_page}};
	my $link = '';
	
	my $debug = 0;
	
	if($debug == 1) { log_debug($migcms_page{id},'','get_link_page'); }
	
	#on vérifie que c'est bien un lien
	if($migcms_page{migcms_pages_type} ne 'link')
	{
		if($debug == 1) { log_debug('Pas un lien','','get_link_page'); }
		return '';
	}
	
	if($migcms_page{id_migcms_link_modules} > 0 && $migcms_page{type_lien} eq 'link_module')
	{
		if($debug == 1) { log_debug('id_migcms_link_modules:'.$migcms_page{id_migcms_link_modules},'','get_link_page'); }
		
		#si lien vers un module (moteur de recherche)
		my %migcms_link = read_table($dbh,'migcms_links',$migcms_page{id_migcms_link_modules});
		my $url_rewriting = get_traduction({debug=>0,id_language=>$config{current_language},id=>$migcms_link{id_textid_link_url}});
		if($d{mailing} ne 'y')
		{
			if($debug == 1) { log_debug($url_rewriting,'','get_link_page'); }
			return $config{baseurl}.'/'.$url_rewriting;
		}
		else
		{
			if($debug == 1) { log_debug($url_rewriting,'','get_link_page'); }
			return $config{fullurl}.'/'.$url_rewriting;
		}
	}
	elsif($migcms_page{id_migcms_link_page} > 0 && $migcms_page{type_lien} eq 'link_page')
	{
		if($debug == 1) { log_debug('id_migcms_link_page:'.$migcms_page{id_migcms_link_page},'','get_link_page'); }
		
		#déterminer le type de la page ciblée
		my %migcms_page_cible = sql_line({table=>'migcms_pages',where=>"id='$migcms_page{id_migcms_link_page}'"});
		if($migcms_page_cible{migcms_pages_type} eq 'link' && $migcms_page_cible{id} > 0 && $migcms_page_cible{id} != $migcms_page{id})
		{
			if($debug == 1) { log_debug('lien vers un lien','','get_link_page'); }
			$url_rewriting = get_link_page({migcms_page=>\%migcms_page_cible,preview=>$d{preview}});
			if($debug == 1) { log_debug($url_rewriting,'','get_link_page'); }
			return $config{baseurl}.'/'.$url_rewriting;
		}
		
		#si lien vers une page
		my $url_rewriting = get_url({debug=>0,preview=>$d{preview},nom_table=>'migcms_pages',id_table=>$migcms_page{id_migcms_link_page}, id_language => $config{current_language}});
		if($d{mailing} ne 'y')
		{
			if($debug == 1) { log_debug($url_rewriting,'','get_link_page'); }
			return $config{baseurl}.'/'.$url_rewriting;
		}
		else
		{
			if($debug == 1) { log_debug($url_rewriting,'','get_link_page'); }
			return $config{fullurl}.'/'.$url_rewriting;
		}
	}
	elsif($migcms_page{id_migcms_link} > 0 && $migcms_page{type_lien} eq 'link')
	{
		if($debug == 1) { log_debug('id_migcms_link:'.$migcms_page{id_migcms_link},'','get_link_page'); }
		
		#si lien sur mesure
		my %migcms_link = read_table($dbh,'migcms_links',$migcms_page{id_migcms_link});
		my $url_rewriting = get_traduction({debug=>0,id_language=>$config{current_language},id=>$migcms_link{id_textid_link_url}});
		if($debug == 1) { log_debug($url_rewriting,'','get_link_page'); }
		return $url_rewriting;
	}
	elsif($migcms_page{simple_url} ne '' && $migcms_page{type_lien} eq 'simple_url')
	{
		if($debug == 1) { log_debug('simple_url:'.$migcms_page{simple_url},'','get_link_page'); }
		
		my $url_rewriting = $migcms_page{simple_url};
		
		$_ = $url_rewriting; 
		
		#rendu des balises PAGE comme lien
		my @pages_lien = (/<MIGC_PAGE_\[(\w+)\]_HERE>/g);
		for ($pl = 0; $pl<=$#pages_lien; $pl++ ) 
		{		
			my $url_rewriting = get_url({debug=>0,preview=>$d{preview},nom_table=>'migcms_pages',id_table=>$pages_lien[$pl], id_language => $config{current_language}});
			if($debug == 1) { log_debug($url_rewriting,'','get_link_page'); }


			log_debug('PAGE'.$pages_lien[$pl].':'.$url_rewriting,'','PAGE');
			#si l'url n'est pas complète et ne commence par par un /, il faut le forcer
			if($url_rewriting !~ m=^http= && $url_rewriting !~ m=^/=)
			{
				$url_rewriting = '/'.$url_rewriting;
				log_debug('->'.$url_rewriting,'','PAGE');
			}

			return $url_rewriting;
		}
		
		#rendu des balises LNK comme lien
		my @pages_lien = (/<MIGC_LNK_\[(\w+)\]_HERE>/g);
		for ($pl = 0; $pl<=$#pages_lien; $pl++ ) 
		{		
			my %migcms_link = read_table($dbh,'migcms_links',$pages_lien[$pl]);
			my $url_rewriting = get_traduction({debug=>0,id_language=>$config{current_language},id=>$migcms_link{id_textid_link_url}});
			if($debug == 1) { log_debug($url_rewriting,'','get_link_page'); }

			log_debug('LNK'.$pages_lien[$pl].':'.$url_rewriting,'','LNK');
			#si l'url n'est pas complète et ne commence par par un /, il faut le forcer
			if($url_rewriting !~ m=^http= && $url_rewriting !~ m=^/=)
			{
				$url_rewriting = '/'.$url_rewriting;
				log_debug('->'.$url_rewriting,'','LNK');
			}

			return $url_rewriting; 
		}
		if($debug == 1) { log_debug($url_rewriting,'','get_link_page'); }
		return $url_rewriting;
	}
	else
	{
		if($debug == 1) { log_debug('aucun des cas !','','get_link_page'); }
	}
}

sub error_404
{
$config{charset} = "ISO-8859-1";

	# print $cgi->header( 
				# -type => "text/html",
				# -status=>"404 Not Found",
				# -expires=>'-1d',
				# -charset=>$config{charset},
			  # );

# if ($config{rewrite_404_id_language} > 0 && $config{rewrite_404_id_page} > 0) 
# {
    # my $page_name = get_obj_url($dbh,$config{rewrite_404_id_page},"html","pages",$config{current_language},"nopath","nourlrewriting");
	
	# my $url_page = '/'.get_url({mailing=>$d{mailing},preview=>$d{preview},from=>'error_404',debug=>0,debug_results=>0,nom_table=>'migcms_pages',id_table=>$config{rewrite_404_id_page}, id_language => $$config{rewrite_404_id_language}});
		# $body = migcrender::render_page({id_tpl_page=>$d{id_template},full_url=>1,mailing=>$d{mailing},debug=>0,content=>$body,lg=>$config{current_language},preview=>'n',edit=>'n'});

    # my $out_name = $config{fullurl}.$url_page;
    if($config{rewrite_404_filepath} ne '')
	{
		insert_file($config{directory_path}.'/'.$config{rewrite_404_filepath});
	}
}
sub insert_file
{
	my $content = get_file($_[0]); 
	print "$content";	
}

sub get_data_detail_categories_breadcrumb
{
	my $MapRewrite = get_quoted('MapRewrite');
  my @pars = split(/\-/,$MapRewrite);
  my $extlink = pop @pars; 
  my $id_data_sheet = pop @pars;

  my %data_sheet = sql_line({dbh=>$dbh, table=>"data_sheets", where=>"id = '$id_data_sheet'"});

  my $id_sf = get_quoted("sf");
  my %sf = sql_line({table=>"data_search_forms", where=>"id = '7'"});

  # On récupère les catégories associées à la sheet
  my @categories = sql_lines({
  	select => "cat.id, cat.id_textid_name",
  	table=>"data_categories as cat, data_lnk_sheets_categories as lnk",
  	where=>"cat.id = lnk.id_data_category
  					AND lnk.id_data_sheet = '$data_sheet{id}'
  					AND lnk.id_data_sheet != ''",
  	ordby => "id ASC"
  }); 

  # On boucle sur les catégories reçues
  my $criteres = "";
  foreach $category (@categories)
  {
    my %category = %{$category};

    if($category{id} > 0)
    {
      # Nom de la catégorie
      my $cat_name = get_traduction({lg=>$config{current_language}, id=>$category{id_textid_name}});

      # Construction de l'url de base vers le listing
      my $url = data::get_data_url({lg=>$config{current_language},params=>'',reset=>'y',sf=>$sf{id},id_father_categorie=>$category{id}});      

      $criteres .= "<li><a href='$url''>$cat_name</a></li>";
    }
  }

  my $content = "";
  if($criteres ne "")
  {
    $content = <<"HTML";
      <ul class="breadcrumb">
        $criteres
      </ul>
HTML
    
  }

  return $content;	
}
1;