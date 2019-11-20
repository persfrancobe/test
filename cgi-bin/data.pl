#!/usr/bin/perl -I../lib 
#-d:NYTProf      
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use data; 
use sitetxt;
use eshop;
use JSON::XS;
use migcrender;
use members;

my $sw = get_quoted('sw') || "list";
#récupere et teste la langue
my $id_data_family = get_quoted('id_data_family') || 1;
my $lg = $config{current_language} = get_quoted('lg') || $config{default_language};
if($lg ne '')
{
	if ($lg !~ /^\d+$/) {exit;}
}
if ($id_data_family !~ /^\d+$/) {exit;}
if ($config{current_language} !~ /^\d+$/) {$config{current_language}=1;}


my %data_setup = %{data_get_setup()};
my %member = ();
if($data_setup{secure_data} eq 'y')
{
	%member = %{members::members_get()};
	if(!($member{id} > 0))
	{
		my %migcms_setup = sql_line({debug=>0,debug_results=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});

		my $url_after_login = "";
		if($config{url_after_login_secure_page} ne "")
		{
			$url_after_login = $config{url_after_login_secure_page};
		}

		see();
		member_login_form({url_after_login=>$url_after_login, url_after_error=>"/cgi-bin/members.pl?lg=$lg&sw=login_form"});
		# exit;
	}
}



%sitetxt = %{get_sitetxt($dbh,$config{current_language})};
$cgi->param(extlink,$extlink); 

my $self = "cgi-bin/data.pl?&lg=$config{current_language}&id_data_family=$id_data_family";
my @fcts = qw(
		  list
		  list_cat
		  detail
		  lightbox_video
		);

if(is_in(@fcts,$sw)) 
{ 
    &$sw();
}

################################################################################
#list_cat
################################################################################
sub list_cat
{
	see();
	my $sf = get_quoted('sf');
	my $id_father = get_quoted('id_father');
	my $id_cat_condition = get_quoted('id_cat_condition');
	log_debug('list_cat_sf:'.$sf.'id_father:'.$id_father.'$id_cat_condition:'.$id_cat_condition,'','list_cat');

	my %data_category = read_table($dbh,'data_categories',$id_father);	
	my $id_data_family = $data_category{id_data_family} || get_quoted('id_data_family');
	my %data_family = read_table($dbh,"data_families",$id_data_family); 	
	my $id_template_page = $data_family{id_template_page_cat};
	my $template_listing = migcrender::get_template($dbh,$data_family{id_template_listing_cat},$config{current_language});
	
	my $where = " id_father = 0 AND id_data_family = $id_data_family AND visible = 'y' ";
	if($id_father > 0)
	{
		$where = " id_father = $id_father AND id_data_family = $id_data_family AND visible = 'y' ";
	}
	if($id_cat_condition > 0)
	{
		#catégories qui correspondent à des fiches  visibles qui correspondent à la catégorie forcée
		$where .= " AND id IN (select distinct(lnk.id_data_category) from data_lnk_sheets_categories  lnk, data_sheets sh where sh.visible='y' AND sh.id = lnk.id_data_sheet AND id_data_sheet IN (select distinct(id_data_sheet) FROM data_lnk_sheets_categories  where id_data_category = '$id_cat_condition')) ";
	}
	my $template_object_cat = migcrender::get_template($dbh,$data_family{id_template_object_cat},$config{current_language});
	my $tag_nb_sheets = '<MIGC_DATA_CAT_NBSHEETS_VALUE_HERE>';
	my $tag_pic1 = '<MIGC_DATA_CAT_PIC1_VALUE_HERE>';
	my $tag_firstsheetpic1 = '<MIGC_DATA_CAT_FIRSTSHEETPIC1_VALUE_HERE>';
	my $tag_url = '<MIGC_DATA_CAT_URL_VALUE_HERE>';
	
	my $tag_listing_cat = "";
	$_ = $template_listing;
	my @tags_listing_cat = (/<MIGC_DATA_LISTINGCAT_\[(\w+)\]_VALUE_HERE>/g);

	foreach my $listing_cat_tag (@tags_listing_cat)
	{	
		my $listing_tag = '<MIGC_DATA_LISTINGCAT_\['.$listing_cat_tag.'\]_VALUE_HERE>';
		my $valeur_listing = "";
		
		if($listing_cat_tag =~ /id_textid/)
		{
			 $valeur_listing = get_traduction({id=>$data_category{$listing_cat_tag},lg=>$config{current_language}});
		}
		else
		{
			$valeur_listing = $data_category{$listing_cat_tag}
		}
		
		# $template_listing =~s/\r*\n/\<br\/\>/g;
		$template_listing =~ s/$listing_tag/$valeur_listing/g;
	}

	my $list_categories = '';
	my $ordby = $config{'list_cat_ordby_'.$data_family{id}};
	my @data_categories = sql_lines({debug=>1,debug_results=>1,table=>'data_categories',where=>$where,ordby=>$ordby});
	foreach $data_category (@data_categories)
	{
		my %data_category = %{$data_category};
		my $titre_cat = get_traduction({id=>$data_category{id_textid_name},lg=>$config{current_language}});

		
		my $new_object_cat = $template_object_cat;
		
		#mapping des balises colonnes
		$_ = $new_object_cat;
		my @new_object_cat_tags = (/<MIGC_DATA_CAT_\[(\w+)\]_VALUE_HERE>/g);

		foreach my $cat_tag (@new_object_cat_tags)
		{	
			$tag = '<MIGC_DATA_CAT_\['.$cat_tag.'\]_VALUE_HERE>';

			my $valeur = "";
			
			if($cat_tag =~ /id_textid/)
			{
				 $valeur = get_traduction({id=>$data_category{$cat_tag},lg=>$config{current_language}});
			}
			else
			{
				$valeur = $data_category{$cat_tag}
			}

			$cat_tag =~s/\r*\n/\<br\/\>/g;
			$new_object_cat =~ s/$tag/$valeur/g;
		}
		
		$_ = $new_object_cat;
		my @new_object_cat_tags = (/<MIGC_DATA_FUNC_(\w+)_HERE>/g);
		foreach my $cat_tag (@new_object_cat_tags)
		{	
			$tag = '<MIGC_DATA_FUNC_'.$cat_tag.'_HERE>';
			my $valeur = 'bbb';
			if($cat_tag ne '')
			{
				my $func = 'def_handmade::'.lc($cat_tag);
				$valeur=&$func($dbh,$precision,\%data_category,$lg,\%sws);
			}
			$cat_tag =~s/\r*\n/\<br\/\>/g;
			$new_object_cat =~ s/$tag/$valeur/g;
		}
		
		#map image cat
		my %migcms_linked_file = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='data_categories' AND token='$data_category{id}'"});
		my $alt = get_traduction({id=>$migcms_linked_file{id_textid_legend},lg=>$config{current_language}});
		if($alt eq '')
		{
			$alt = $titre_cat;
		}
		# my $pic1 = '<img src="/usr/files/CAT/photos/'.$data_category{id}.'/'.$migcms_linked_file{full}.'_small'.$migcms_linked_file{ext}.'" alt ="'.$alt.'" width="'.$migcms_linked_file{width_small}.'" height="'.$migcms_linked_file{height_small}.'" />';
		my $pic1 = '<img src="/usr/files/CAT/photos/'.$data_category{id}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext}.'" alt ="'.$alt.'" width="'.$migcms_linked_file{width_small}.'" height="'.$migcms_linked_file{height_small}.'" />';
		$new_object_cat =~ s/$tag_pic1/$pic1/g;
		
		#map image first sheet
		my %sheet_lnk = sql_line({debug=>1,debug_results=>1,table=>"data_lnk_sheets_categories lnk, data_sheets sh",where=>"lnk.id_data_sheet = sh.id AND lnk.id_data_category='$data_category{id}'",ordby=>'lnk.ordby'});
		my %sheet = sql_line({debug=>1,debug_results=>1,table=>"data_sheets",where=>"id = '$sheet_lnk{id_data_sheet}'"});
				
		my %pic = sql_line({debug=>1,debug_results=>1,table=>"migcms_linked_files lnk",where=>"lnk.table_name='data_sheets' AND lnk.token = '$sheet{id}'",ordby=>'ordby'});
        my $pic_sheet1 .= data_get_html_object_pic_content(\%pic,'SMALL',\%sheet,'',$config{current_language},$force_alt_pic,$full_url);
		$new_object_cat =~ s/$tag_firstsheetpic1/$pic_sheet1/g;
		

		
		
		#map nb elts
		my %nb_elt = sql_line({debug=>0,debug_results=>0,select=>"COUNT(*) as nb",table=>'data_lnk_sheets_categories lnk, data_categories c,data_sheets sh',groupby=>"",where=>"sh.id = lnk.id_data_sheet AND c.id = lnk.id_data_category AND c.id_father = '$id_father' AND c.id_data_family='$data_family{id}' AND c.visible='y' AND lnk.id_data_category='$data_category{id}' AND c.id NOT IN (select id_record from migcms_valides where nom_table='data_sheets')"});
		my $nb_sheets = $nb_elt{nb};
		if(!($nb_sheets > 0))
		{
			$nb_sheets = 0;
		}
		
		$new_object_cat =~ s/$tag_nb_sheets/$nb_sheets/g;
		
		#map url
		my %first_children = sql_line({select=>'id',table=>'data_categories',where=>"id_father='$data_category{id}' AND visible='y'"});
		my $has_children = 'n';
		if($first_children{id} > 0)
		{
			$has_children = 'y';
		}
		my $url = data::get_data_url({sf=>$sf,from=>'list_cat',id_father_categorie=>$data_category{id},id_cat_condition=>$id_cat_condition,has_children=>$has_children});
		$new_object_cat =~ s/$tag_url/$url/g;

		$list_categories .= <<"EOH";
			$new_object_cat
EOH
	}
	
	if($#data_categories == -1)
	{
		$list_categories = <<"EOH";
			<div class="alert alert-info" role="alert">
				$sitetxt{data_no_results}
			</div>
EOH
	}
	
	#map pagination (pas de pagination prévue actuellement)
	my $tag = '<MIGC_DATA_PAGINATION_HERE>';
	$template_listing =~ s/$tag//g;
	
	#map listing content
	my $tag = '<MIGC_DATA_LISTING_HERE>';
	$template_listing =~ s/$tag/$list_categories/g;
	
	#map nb cats
	my $tag_nb_cats = '<MIGC_DATA_LISTCAT_NB_VALUE_HERE>';
	my $nb_cats = $#data_categories + 1;
	if(!($nb_cats > 0))
	{
		$nb_cats = 0;
	}	
	$template_listing =~ s/$tag_nb_cats/$nb_cats/g;
	
	display($template_listing,$id_template_page,'',\%data_family);
}

################################################################################
#LIST
################################################################################
sub list
{
     see();
	 # my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});

	 my $sf = get_quoted('sf') || 0;
     if ($sf !~ /^\d+$/) {exit;}
	 	 
	 my $params = get_quoted('page');
	 
	 my @params = split(/\-/,$params);
	 $current_page = $params[0];
	 
	 $params = $params[1];
	 if ($current_page !~ /^\d+$/) {$current_page=1;}
	 
	 my %data_family = read_table($dbh,"data_families",$id_data_family); 
	 my %data_search_form = read_table($dbh,"data_search_forms",$sf); 
	 # my %alt_data_family = sql_line({table=>'data_families',where=>"id='$data_family{id_alt_data_family}'"}); 
	 my $id_template_page = $data_family{id_template_page};
	 if($data_search_form{id_template_page} > 0)
	 {
		$id_template_page = $data_search_form{id_template_page};
	 }
	 my $id_template_listing = $data_family{id_template_listing};
	 if($data_search_form{id_template_listing} > 0)
	 {
		$id_template_listing = $data_search_form{id_template_listing};
	 }
	 
	 my $nr = $data_family{family_nr};
	 if(!($nr > 0))
	 {
		$nr = 48;
	 }
	 
     my %tarif = ();
	 if($data_family{has_tarifs} eq 'y')
	 {
		 $id_tarif = eshop::eshop_get_id_tarif_member();
		 %tarif = read_table($dbh,"eshop_tarifs",$id_tarif);                                             
     }
     
	 my ($list_sheets,$nb_total_resultats) = compute_sheets({params=>$params,sf=>$sf,data_setup=>\%data_setup,data_family=>\%data_family,tarif=>\%tarif,current_page=>$current_page,tri=>$tri,nr=>$nr,lg=>$config{current_language}});
	 my $pagination = get_pagination({params=>$params,sf=>$sf,current_page=>$current_page,nr=>$nr,nb_total_resultats=>$nb_total_resultats});

	if($nb_total_resultats == 0)
	{
		$list_sheets = <<"EOH";
<div class="alert alert-info" role="alert">
      $sitetxt{data_no_results}
    </div>
EOH
	}
	
    my $tpl = migcrender::get_template($dbh,$id_template_listing,$config{current_language});
	my $end_page = int($nb_total_resultats / $nr) + 1;

    $list = map_list_listing($tpl,$pagination,$list_sheets,$end_page,$last_page,$nr,$data_family{has_tarifs},$nb_total_resultats,$params);
	
	while ($list =~ m/<MIGC_DATA_CAT_\[(.*?)\]\[(.*?)\]_(.*?)_HERE>/g) 
	{
		my $col = trim($1);
		my $id_father_cats = trim($2);
		my @list_id_father_cats = split(/\,/,$id_father_cats);
		my $func = trim($3);
		
		my $current_id_cat = 0;
		
		my $trouve = 0;
		
		foreach my $num_param (1 .. 10)
		{
			my $test_id_cat = get_quoted('s'.$num_param) ; #|| get_quoted('s_default_'.$num_param)
			
			if ($test_id_cat !~ /^\d+$/) {next;}
			
			foreach my $id_father_cat (@list_id_father_cats)
			{
				# print "s".$num_param.':'.$test_id_cat.' | '.$id_father_cat.'=?'.$rew_fathers_cats{$test_id_cat}.'<br>';
				if($id_father_cat == $rew_fathers_cats{$test_id_cat})
				{
					$current_id_cat = $test_id_cat;
					$trouve = 1;
					last;
				}
			}
			if($trouve == 1)
			{
				last;
			}
		}
		my %data_category = sql_line({table=>'data_categories',where=>"id='$current_id_cat'"});
		
		$tag = '<MIGC_DATA_CAT_\['.$col.'\]\['.$id_father_cats.'\]_'.$func.'_HERE>';

		my $cat_value = '';
		if($col =~ /id_textid/ || $col =~ /ID_TEXTID/)
		{
			 $col = lc($col);
			 $cat_value .= get_traduction({id=>$data_category{$col},lg=>$config{current_language}});
		}
		else
		{
			$col=lc($col);
			$cat_value .= $data_category{$col};
		}
		
		if($func eq 'VALUE')
		{
			$func = '';
		}
		if($func ne '')
		{
			$func = 'def_handmade::'.$func;
			$cat_value = &$func($cat_value);
		}
		
		if($cat_value eq '')
		{
			$cat_value = get_traduction({id=>$data_family{id_textid_meta_title},lg=>$config{current_language}});
		}
		
		$cat_value =~s/\r*\n/\<br\/\>/g;
		$list =~ s/$tag/$cat_value/g;
	}
    
    $list .=<<"EOH";
        <input type="hidden" name="id_data_search_form_selected"  id="id_data_search_form_selected" value="$sf" />
EOH
    
	#exectute les fonctions sur mesure dans le template listing
    $_ = $list;
	my @fonctions = (/<MIGC_DATA_FUNC_(\w+)_HERE>/g);
	for ($i_fonction = 0; $i_fonction<$#fonctions+1; $i_fonction++ ) 
	{
		my $balise_a_remplacer = '<MIGC_DATA_FUNC_'.uc($fonctions[$i_fonction]).'_HERE>';
		my $fonction = lc($fonctions[$i_fonction]);
		my $func = 'def_handmade::'.lc($fonction);
		my $valeur=&$func();
		
		$list =~ s/$balise_a_remplacer/$valeur/g;
	}

	display($list,$id_template_page,'',\%data_family,\%data_setup);
}

################################################################################
#DETAIL
################################################################################
sub detail
{
	see();  

	my $MapRewrite = get_quoted('MapRewrite');
	my @pars = split(/\-/,$MapRewrite);
    my $extlink = pop @pars; 
    my $id_data_sheet = pop @pars; 
	 # my %data_setup = %{data_get_setup()};

    if ($id_data_sheet !~ /^\d+$/) {exit;}
	my %data_sheet=read_table($dbh,"data_sheets",$id_data_sheet);

    my $id_data_family = get_quoted('id_data_family') || 1;
    if ($id_data_family !~ /^\d+$/) {exit;}
    my %data_family=read_table($dbh,"data_families",$id_data_family);
		
	#si templates spécifiques à cette sheet
	if($data_sheet{id_template_detail} > 0)
    {
		$data_family{id_template_detail} = $data_sheet{id_template_detail};
	}
	if($data_sheet{id_template_page} > 0)
    {
		$data_family{id_template_page} = $data_sheet{id_template_page};
		$data_family{id_template_detail_page} = $data_sheet{id_template_page};
	}
	# see();
	# print $ENV{HTTP_HOST};
	# exit;
	if($config{'data_id_tpl_page_detail_for_'.$ENV{HTTP_HOST}} > 0)
	{
		$data_family{id_template_page} = $config{'data_id_tpl_page_detail_for_'.$ENV{HTTP_HOST}};
		$data_family{id_template_detail_page} = $config{'data_id_tpl_page_detail_for_'.$ENV{HTTP_HOST}};
	}

    # my %data_setup = %{data_get_setup()};
    my $id_tarif = eshop_get_id_tarif_member();
    my %tarif = read_table($dbh,"eshop_tarifs",$id_tarif);
	
	
	
	
    if($data_sheet{visible} eq 'n' || $id_data_sheet == 0 || !($data_sheet{id} > 0) )
    {
        migcrender::error_404();
    }
    else
    {
         my $template_page = $data_family{id_template_detail_page} || $data_family{id_template_page};
		 
	
               
		 my $template = migcrender::get_template($dbh,$data_family{id_template_detail},$lg);
		 $detail = data_write_tiles_optimized($dbh,\%data_sheet,\%data_family,$data_family{id_template_detail},$template,$lg,0,'detail',$extlink,'','','','',\%data_setup,\%tarif);
		 display($detail,$template_page,$data_history,\%data_family,\%data_setup);
    }
	exit;
}


################################################################################
#DISPLAY
################################################################################
sub display
{
  my $content = $_[0];
  my %data_family = %{$_[3]};
  my %data_setup = %{$_[4]};

  $content .=<<"EOH";
   <input type="hidden" name="script" id="script" value="$config{eshop_script}" />
EOH
  
  my $id_template_page = $_[1];
	
	
	
  my $page_content = render_page({debug=>0,content=>$content,id_tpl_page=>$id_template_page,extlink=>$extlink,lg=>$config{current_language},data_family=>\%data_family});
  
	#rendu tags supplémentaires
	
	#language code
	my %language=read_table($dbh,"migcms_languages",$config{current_language});
   $page_content =~ s/<MIGC_LANGUAGE_CODE_HERE>/$language{name}/g;		
    	
	if($data_setup{use_data_cache} eq 'y')
	{
		log_debug('data_cache','','data_cache');
		
		my $REQUEST_URI = $ENV{REQUEST_URI};
		log_debug($REQUEST_URI,'','data_cache');

		my @dossiers =  split(/\//,$REQUEST_URI);
		my $path = "../cache/site/data/$sw";
		unless (-d $path) {mkdir($path.'/') or die ("cannot create ".$path.'/'.": $!");}

		#créer les dossiers nécessaires
		my $count_dossier = 0;
		foreach my $dossier (@dossiers)
		{
			log_debug('dossier:'.$dossier,'','data_cache');
			log_debug('count_dossier:'.$count_dossier,'','data_cache');
			log_debug('Total:'.$#dossiers,'','data_cache');
			
			if($dossier eq '')
			{
				log_debug('Le dossier est vide -> suivant','','data_cache');
				$count_dossier++;
				next;
			}
			
			#sauf le numéro de page qui termine l'url: dernier dossier et nombre
			if($dossier =~ /\d/ && $count_dossier >= $#dossiers)
			{
				log_debug('Le dossier est un nombre et est le dernier -> last','','data_cache');
				$count_dossier++;
				last;
			}
			$path = $path.'/'.$dossier;
			log_debug('path:'.$path,'','data_cache');
			unless (-d $path) {mkdir($path.'/') or die ("cannot create ".$path.'/'.": $!");}
			
			$count_dossier++;
		}
		
		#si on ne précise pas la page: page 1
		if($REQUEST_URI !~ /\d$/)
		{
			log_debug('URL pas terminée par un nombre','','data_cache');
			$REQUEST_URI.='/1';
		}
		my $out_file = "../cache/site//data/$sw$REQUEST_URI".'.html';		
		
		log_debug('out_file:'.$out_file,'','data_cache');
		log_debug('page_content:'.$page_content,'','data_cache');
		
		if($out_file !~ /\-k/)
		{
			open OUTPAGE, ">$out_file" or die "cannot open $out_file";
			print OUTPAGE $page_content;
			close (OUTPAGE);
		}
	}
   
   print $page_content;
}

sub gotopage
{
	my $request_uri = get_quoted('request_uri');
	my $new_page = get_quoted('new_page');
	my $last_page = get_quoted('last_page');
	
	if($new_page =~ /\d/ && $new_page > 0 && $new_page <= $last_page)
	{
	}
	elsif($last_page =~ /\d/ && $last_page > 0)
	{
		$new_page = $last_page;
	}
	else
	{
		$new_page = 1;
	}
	
	if($request_uri =~ /\d$/)
	{
		$request_uri =~ s/\d$/$new_page/g;
	}
	elsif($new_page == 1)
	{
		$request_uri =~ s/\/$//g;
	}
	elsif($new_page > 1)
	{
		$request_uri .= '/'.$new_page;
	}
	
	cgi_redirect($request_uri);
}