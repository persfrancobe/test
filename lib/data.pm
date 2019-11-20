#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
package data;  
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@ISA = qw(Exporter);  
@EXPORT = qw(                                                       
				get_data_detail_url             
				data_get_setup
			  compute_sheets
			  get_pagination
			  map_list_listing
			  get_tri
			  get_gotobox
			  get_nrbox
			  data_write_tiles_optimized
			  get_categories_list
			  get_data_search_form
			  migcms_build_data_searchs_keyword
			  %rew_names_sfs
			  %rew_names_cats
			  %rew_fathers_cats
			  data_get_html_object_pic_content
			  get_data_detail_url
			  recompute_sheets_id_data_categories
			  recompute_data_categories_has_data_sheets_linked
            );
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use def;
use tools;
use Data::Dumper;
 
use sitetxt;
use JSON::XS;
use migcrender;
use HTML::Entities;
use URI::Escape; 
use eshop; 
use members;
use def_handmade;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
#CACHES (accélerer chargement)
my $lg = get_quoted('lg');
if($lg > 0)
{
	$config{current_language} = $lg;
}
if(!($config{current_language} > 0 && $config{current_language} < 10))
{
	$config{current_language} = 1;
}

my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible = 'y'",ordby=>"id"});

#Cache des urls rewriting des moteurs de recherches
%rew_names_sfs = ();
%eshop_setup = ();
%data_setup = ();
my @data_search_forms = sql_lines({select=>"id_textid_url_rewriting,id",table=>"data_search_forms",ordby=>"",debug=>0});
foreach $data_search_form (@data_search_forms)
{
	my %data_search_form = %{$data_search_form};
	
	foreach $language (@languages)
    {
        my %language = %{$language};
		my $traduction = get_traduction({debug=>1,id_language=>$language{id},id=>$data_search_form{id_textid_url_rewriting}});
		if($traduction ne '')
		{
			$rew_names_sfs{$language{id}}{$data_search_form{id}} = $traduction;
		}
	}
}

#Cache des urls rewriting des catégories
%rew_names_cats = ();
foreach $language (@languages)
{
	my %language = %{$language};
	my @migcms_urls = sql_lines({debug=>0,select=>"url_rewriting,id_table",table=>'migcms_urls',where=>"nom_table='data_categories' AND id_lg='$language{id}'"});
	foreach $migcms_url (@migcms_urls)
	{
		my %migcms_url = %{$migcms_url};
		if($migcms_url{url_rewriting} ne '')
		{
			$rew_names_cats{$language{id}}{$migcms_url{id_table}} = $migcms_url{url_rewriting};
		}
	}
}

%cache_data_fields = ();
%cache_data_fields_id = ();
my @data_fields = sql_lines({table=>"data_fields",ordby=>"",debug=>0});
foreach $data_field (@data_fields)
{
	my %data_field = %{$data_field};
	$cache_data_fields{$data_field{id_data_family}}{$data_field{ordby}} = \%data_field;
	$cache_data_fields_id{$data_field{id}} = \%data_field;
}

#cache des parents des catégories
%rew_fathers_cats = ();
%rew_fathers_cats_txt = ();
my @cats = sql_lines({select=>"id,id_father",table=>'data_categories',where=>"id_father > 0"});
foreach $cat (@cats)
{
	my %cat = %{$cat};
	$rew_fathers_cats{$cat{id}} = $cat{id_father};
}

#cache inverse
%rew_children_cats = ();
foreach my $key (keys %rew_fathers_cats)
{
    my $child_key = $rew_fathers_cats{$key};
    $rew_children_cats{$child_key} = $key;
}


# my ($list_sheets_to_display,$nb_total_resultats) =      ({data_family=>\%data_family,current_page=>$current_page,tri=>$tri,nr=>$nr});
# force_id_data_category=>,add_where=>,force_id_template_object=>,force_ordby=>

sub compute_sheets
{
	log_debug('compute_sheets DEBUT','','compute_sheets');
	
	# use Carp;	
	# my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller();
	# my $stack = Carp::longmess("Stack backtrace :");
	# $stack =~ s/\r*\n/<br>/g;
	# log_debug($stack,'','compute_sheets');
	
	# log_debug('compute_sheets','','data');
	my %d = %{$_[0]};
	my %data_family = %{$d{data_family}};
	my %tarif = %{$d{tarif}};
	my %data_setup = %{$d{data_setup}};
	my %sf = ();
	my $lg = $d{lg};

	if($d{sf} > 0)
	{
		log_debug('read sf','','compute_sheets');
		%sf = sql_line({table=>"data_search_forms",where=>"id='$d{sf}'"});
	}
	my $table = 'data_sheets sh';
	my $colg = $lg;
	if($config{dmforcelg} > 0)
	{
		$colg = $lg = $config{dmforcelg};
	}

	my $params = $d{params} || get_quoted('s_default_params');
	log_debug('$params:'.$d{params},'','compute_sheets');
	log_debug('$params2:'.get_quoted('s_default_params'),'','compute_sheets');

	my @params = split(/\=/,$params);


	# url_only
	#CONSRUCTION DU WHERE
	
	#conditions de base
	my $list_sheets = '';
	my @where = ();
	push @where, " sh.visible='y'";
	push @where, " sh.id_data_family='$data_family{id}'";
	push @where, " sh.id NOT IN (select id_record from migcms_valides where nom_table='data_sheets')";
	
	
	#conditions where via conditions sur mesure (c_srch)
	my $c_srch = get_quoted('c_srch');
	if($c_srch ne '')
	{
		log_debug('CRCH','','compute_sheets');
		my $where_func = 'def_handmade::'.trim(lc($c_srch));
		my $custom_where = &$where_func();
		if($custom_where ne '')
		{
			push @where, " $custom_where ";
		}
	}	
	
	#conditions where via conditions sur mesure dans config
	if($config{data_where_supp_func} ne '')
	{
		log_debug('$config{data_where_supp_func}:'.$config{data_where_supp_func},'','compute_sheets');
		my $where_func = 'def_handmade::'.$config{data_where_supp_func};
		my $custom_where = &$where_func({id_data_family=>$data_family{id}});
		if($custom_where ne '')
		{
			push @where, " $custom_where ";
		}
	}	
	
	#conditions des catégories (via mapping url)
	my $parametres = $list_keywords = '';
	foreach my $num_param (1 .. 10)
	{
		my $param = get_quoted('s'.$num_param) || get_quoted('s_default_'.$num_param);
		my @test_params = split('\:',$param);
		if($test_params[0] eq 'NOTFOUND')
		{
			log_debug('404','','compute_sheets');
			# log_debug('s'.$num_param.':'.$test_params[0].':'.$test_params[1],'','data_not_found_params');
			migcrender::error_404();
		}
		
		if($param eq '')
		{
			$param = $d{'s'.$num_param};
		}
		$parametres .= "'s".$num_param."':'".$param."',";

		if ($param !~ /^\d+$/) {next;}
		
		#unique cas envisagé: catégories
		my $id_data_category = $param;
		push @where, "sh.id_data_categories LIKE '%,$id_data_category,%'";		
	}
	
	#conditions spéciales (via paramètres)
	
	#ajout de la catégorie passée en paramètre
	if($d{force_id_data_category} > 0)
	{
		my $id_data_category = $d{force_id_data_category};
		push @where, "sh.id_data_categories LIKE '%,$id_data_category,%'";		
	}
	
	my $force_keyword = '';
	if($params[0] eq 'k')
	{
		if($params[1] ne '')
		{
			$force_keyword = $params[1];
		}
	}

	foreach my $num_param (1 .. 10)
	{
		my $keyword_received = get_quoted('keyword_s'.$num_param);
		if($keyword_received eq '')
		{
			$keyword_received = $d{'keyword_s'.$num_param};
		}
		if($force_keyword ne '')
		{
			$keyword_received = $force_keyword;
		}
		
		$list_keywords .= "'keyword_s".$num_param."':'".$keyword_received."',";

		
		if($keyword_received ne '' && $sf{id} > 0)
		{
			$table .= ' , data_searchs_keyword skw'.$num_param.' ';
			push @where, " sh.id = skw$num_param.id_data_sheet AND skw$num_param.id_data_search_form = '$sf{id}' AND id_language = '$lg'";	
			
			my @where_keywords = ();
			my @keywords = split('\s',$keyword_received);
			foreach $keyword (@keywords)
			{  
			  push @where_keywords, " skw$num_param.content LIKE '%$keyword%' ";
			}
			my $where_keywords = join(' AND ', @where_keywords);
			push @where, $where_keywords;	
		}
		
		if($force_keyword ne '')
		{
			last;
		}
	}
	
	#ajout du where passé en paramètre
	if($d{add_where} ne '')
	{
		push @where, $d{add_where};		
	}

	# Si c'est les produits associés, ajouts des ID au where
	if($d{related_sheets} eq "y" && $d{nb_total_seulement} ne 'y')
	{
		# log_debug('related sheets','','compute_sheets');
		my $MapRewrite = get_quoted('MapRewrite');
 		my @pars = split(/\-/,$MapRewrite);
		my $extlink = pop @pars; 
		my $id_data_sheet = pop @pars;
		log_debug('related_sheets','','compute_sheets');
		my @related_sheets = sql_lines({debug=>0,dbh=>$dbh, table=>"data_sheets_assoc", where=>"id_data_sheet = '$id_data_sheet'"});

		my $related_sheets_where .= "id IN (";
		if($#related_sheets > -1)
		{      
		  for (my $i=0 ; $i<$#related_sheets+1 ; $i++)
		  {
			my %related_sheet = %{$related_sheets[$i]};

			my $virgule = ", ";
			if($i == $#related_sheets)
			{
			  $virgule = "";
			}
			$related_sheets_where .= "$related_sheet{id_assoc_sheet}$virgule";
		  }
		}
		else
		{
		  $related_sheets_where .=  "-1";
		}
		$related_sheets_where .= ")";

		push @where, $related_sheets_where;		
	}

	# Si fonction personnalisée qui renvoie le where
	if($d{getsheets_custom_function_where} ne "")
	{
		$fct = 'def_handmade::'.$d{getsheets_custom_function_where};
		my $custom_where =  &$fct();
		@where = ();
		push @where, $custom_where;
	}
	
	#tri normal
	my $ordby = 'ordby';
	my $custom_ordby = '';
	
	#custom_ordby
	if($sf{custom_ordby} ne '')
	{
		$custom_ordby = $sf{custom_ordby};
	}
	
	if($params[0] eq 't')
	{
		
		if($params[1] == 3)
		{
			#Prix croissant
			$ordby = 'price';
			$custom_ordby = '';
			push @where, " price > 0 ";		

		}
		elsif($params[1] == 4)
		{
			#Prix décroissant
			$ordby = 'price DESC';
			$custom_ordby = '';
			push @where, " price > 0 ";		
		}
	}
	
	my $select = "sh.*, sh.id as id_data_sheet";
	if($data_family{select_object} ne '')
	{
		$select = $data_family{select_object};
	}
	
	#tri forcés: sur une colonne de la fiche ou sur un champs
	if($sf{sort_on_cat} eq 'y' && get_quoted('s1') > 0)
	{
		$table .= ' ,  data_lnk_sheets_categories lnk ';
		push @where, " lnk.id_data_sheet = sh.id ";		
		push @where, " lnk.id_data_category = '".get_quoted('s1')."'";
		$ordby = 'lnk.ordby asc';		
	}
	elsif($sf{order_field} > 0)
	{
		# my %data_field = sql_line({table=>"data_fields",where=>"id='$sf{order_field}'"});
		my %data_field = %{$cache_data_fields_id{$sf{order_field}}};
		
		if($data_field{field_type} eq 'text' || $data_field{field_type} eq 'textarea' )
		{
			$ordby = 'TRIM(f'.$data_field{ordby}.')';
		}
		elsif($data_field{field_type} eq 'text_id' || $data_field{field_type} eq 'textarea_id' )
		{
			$table .= ' ,  txtcontents txt ';
			my $col = 'f'.$data_field{ordby};
			push @where, " sh.$col = txt.id ";	
			$ordby = 'lg'.$config{current_language};

			$select .= ", txt.*";
		}
	}
	
	#custom_ordby
	if($custom_ordby ne '')
	{
		$ordby = $custom_ordby;
	}
	
	#ordby forcé	
	if($d{force_ordby} ne '')
	{
		$ordby = $d{force_ordby};
	}
		# print $ordby;
	# exit;
	#limit
	
	if($d{nr} eq '')
	{
		$d{nr} = '48';
	}
	
	#limite normale
	my $limit = (($d{current_page}-1) * $d{nr}).','.$d{nr};
	
	#limite pour suivvant/précédent
	my $beg = (($d{current_page}-1) * $d{nr}) + ($d{iteration}+1);
	if($d{previous_sheet} eq 'y')
	{
		$beg--;
		$beg--;
		if($beg < 0)
		{
			return '';
		}
		
		$limit = $beg.",1";
	}
	elsif($d{next_sheet} eq 'y')
	{
		if($beg < 0)
		{
			$beg = 0;
		}
		$limit = $beg.",1";
	}

	#création du where
	my $where = join(" AND ",@where);

	log_debug('table:'.$table,'','compute_sheets');
	log_debug('where:'.$where,'','compute_sheets');
	
	my %nb_total_resultats = sql_line({debug => 1,debug_results => 1,select=>"COUNT(*) as nb",table=>$table,where => $where,debug => $debug,debug_results => $debug});
	log_debug('nb:'.$nb_total_resultats{nb},'','compute_sheets');

	if($d{nb_total_seulement} eq 'y')
	{
		return ($list_sheets,$nb_total_resultats{nb});
	}

	my $base_infos_recherche = "{".$parametres.$list_keywords."'force_id_data_category':'$d{force_id_data_category}','page':'$d{current_page}','sf':'$sf{id}','debut':'".(($d{current_page}-1) * $d{nr})."','nr':'".$d{nr}."','iteration':'ITERATIONHERE'}";
	my $i=0;

	log_debug('select:'.$select,'','compute_sheets');
	log_debug('ordby:'.$ordby,'','compute_sheets');
	log_debug('limit:'.$limit,'','compute_sheets');
	
	my @data_sheets = sql_lines({debug => 1,debug_results => 1,select=>$select, table=>$table,where => $where,ordby => $ordby,limit => $limit});
	log_debug('nb2:'.$#data_sheets,'','compute_sheets');
	
	foreach $data_sheet(@data_sheets)
	{
		my %data_sheet = %{$data_sheet};
			log_debug('SHEET:'.$data_sheet{id},'','compute_sheets');


		$data_sheet{id} = $data_sheet{id_data_sheet};
		if($d{url_only} eq 'y')
		{
			# my $url_detail = get_data_detail_url($dbh,\%data_sheet,$colg,$extlink,'y');   
			return $url_detail;
		}
		
		my %data_family_edited = %data_family;
		if($data_sheet{id_template_object} > 0)
		{
			$data_family_edited{id_template_object} = $data_sheet{id_template_object};
		}
		if($data_sheet{id_template_page} > 0)
		{
			$data_family_edited{id_template_page} = $data_sheet{id_template_page};
			$data_family_edited{id_template_detail_page} = $data_sheet{id_template_page};
		}
		
		if($sf{id_template_object} > 0)
		{
			$data_family_edited{id_template_object} = $sf{id_template_object};
		}
		if($sf{id_template_detail_page} > 0)
		{
			$data_family_edited{id_template_detail_page} = $sf{id_template_detail_page};
		}
		if($sf{id_template_page} > 0)
		{
			$data_family_edited{id_template_page} = $sf{id_template_page};
		}
		
		if($d{force_id_template_object} > 0)
		{
			$data_family_edited{id_template_object} = $data_sheet{id_template_object} = $d{force_id_template_object};
		}
		
		my $template = migcrender::get_template($dbh,$data_family_edited{id_template_object},$d{lg});

		my $infos_recherche = $base_infos_recherche;
		$infos_recherche =~ s/ITERATIONHERE/$i/g;

		my $object = data_write_tiles_optimized($dbh,\%data_sheet,\%data_family_edited,$data_family_edited{id_template_object},$template,$lg,0,'object',$extlink,'',undef,undef,'n',\%data_setup,\%tarif,'',$infos_recherche);
		$list_sheets .= $object;
		$i++;
	}
	if($d{url_only} eq 'y')
	{
		return '';
	}
	
	log_debug('compute_sheets FIN','','compute_sheets');
	return ($list_sheets,$nb_total_resultats{nb});
}

sub get_pagination
{
	my %d = %{$_[0]};

	my $page_interval_1 = $d{current_page} - 3;
	my $page_interval_2 = $d{current_page} + 3;
	if($page_interval_1 < 0)
	{
		$page_interval_2 += abs($page_interval_1);
		$page_interval_1 = 1;
	}
	my $end_page = int(($d{nb_total_resultats}-1) / $d{nr} + 1);
	if($end_page < $page_interval_2)
	{
		$page_interval_2 = $end_page;
	}
	
	my $previous_page = $d{current_page} - 1;
	my $prev_disabled = '';
	if($previous_page < 1)
	{
        $prev_disabled = 'hide';
	}
	my $next_page = $d{current_page} + 1;
	
	
	# print "page_interval_1:$page_interval_1,page_interval_2:$page_interval_2,end_page:$end_page,nb_total_resultats:$d{nb_total_resultats},nr:$d{nr}sf:$d{sf}";
 	my $link = data::get_data_url({params=>$d{params},sf=>$d{sf},number_page=>$previous_page,nr=>$d{nr},from=>'pagination'});
	my $link_first = data::get_data_url({params=>$d{params},sf=>$d{sf},number_page=>1,nr=>$d{nr},from=>'pagination'});
	
	my $pagination=<<"EOH";
<nav aria-label="Page navigation">
	<div class="nbr_result"><span>$d{nb_total_resultats}</span> $sitetxt{result_label}</div>
	<ul class="pagination">
		<li class="$prev_disabled"><a href="$link_first" aria-label="First" class="pagination_first"><span aria-hidden="true">&laquo;</span></a></li>
		<li class="$prev_disabled"><a href="$link" aria-label="Previous" class="pagination_previous"><span aria-hidden="true">&lsaquo;</span></a></li>
                   
EOH
    if($end_page != 1)
    {
        for $number_page ($page_interval_1 .. $page_interval_2)
        {
        	if(!($number_page >0))
        	{
        		next;
        	}
            
			my $link = data::get_data_url({params=>$d{params},sf=>$d{sf},number_page=>$number_page,nr=>$d{nr},from=>'pagination'});
            
            my $page_class="pagination_page";
            my $page_link='<li class="'.$page_class.'"><a href="'.$link.'">'.$number_page.'</a></li>';
            if($number_page == $d{current_page})
            {
                $page_class="active";
				$page_link='<li class="'.$page_class.'"><a href="'.$link.'">'.$number_page.'</a></li>';
            }
            
            $pagination.=<<"EOH";
			$page_link          
EOH
        } 
    }
    my $link = data::get_data_url({params=>$d{params},sf=>$d{sf},number_page=>$next_page,nr=>$d{nr},from=>'pagination'});
	my $link_last = data::get_data_url({params=>$d{params},sf=>$d{sf},number_page=>$end_page,nr=>$d{nr},from=>'pagination'});
    my $next_link="";
    if($next_page <= $page_interval_2)
    {
        $next_link=<<"EOH";
		<li class=""><a href="$link" aria-label="Next" class="pagination_next"><span aria-hidden="true">&rsaquo;</span></a></li>
		<li class=""><a href="$link_last" aria-label="Last" class="pagination_last"><span aria-hidden="true">&raquo;</span></a></li>
EOH
    }
    $pagination.=<<"EOH";
		$next_link
	</ul>
</nav>
EOH
    
	#if($end_page == 1)
	#{
		#$pagination = '';
	#}
	return $pagination;
}

################################################################################
#get_data_url
################################################################################
sub get_data_url
{
    my %d = %{$_[0]};

    my $sf = $d{sf};
    my $force_s1_value = $d{force_s1_value};

    my $current_page = $d{number_page};
	if($current_page eq '')
	{
		$current_page = 1;
	}
    my $nr = $d{nr};
    my $from = $d{from};
	my $lg = $d{lg};
	if(!($lg > 0))
	{
		$lg = get_quoted('lg');
		if($lg > 0)
		{
			$config{current_language} = $lg;
		}
		if(!($config{current_language} > 0 && $config{current_language} < 10))
		{
			$lg = $config{current_language} = 1;
		}
	}
	
	#le lien commence maintenant par un slash car alain ne met plus de baseurl.
	my $url = '/';
	
	#LANGUE
	my %corr_lg = 
	(
		1 => 'fr',
		2 => 'en',
		3 => 'nl',
		4 => 'de',
	);
	$url .= $corr_lg{$lg}.'/';

	if($d{has_children} eq 'y')
	{
		$url .= '/categories/';
	}
	
	#SEARCH FORM
	$url .= $rew_names_sfs{$lg}{$sf}.'/';

	my %categories = ();
	my %fathers = ();
	
	#CATEGORIE RECUE	
	if($d{id_father_categorie} > 0)
	{
		$categories{$d{id_father_categorie}} = 1;
		$fathers{$rew_fathers_cats{$d{id_father_categorie}}} = 1;
		$url .= $rew_names_cats{$lg}{$d{id_father_categorie}}.'/';
	}
    if($d{id_cat_condition} > 0)
    {
        $categories{$d{id_cat_condition}} = 1;
        $fathers{$rew_fathers_cats{$d{id_cat_condition}}} = 1;
        $url .= $rew_names_cats{$lg}{$d{id_cat_condition}}.'/';
    }
	
	#PARAMETRES
	if($d{reset} ne 'y')
	{
		foreach my $num_param (1 .. 10)
		{
			my $param = get_quoted('s'.$num_param);
			if($num_param == 1 && $force_s1_value ne "")
			{
				$param = $force_s1_value;
			}
			
			if($d{reset} == $param)
			{
				next;
			}
			
			if ($param !~ /^\d+$/) {next;}
			
			#si la catégorie n'a pas déjà été passée et si le père n'a pas encore été tiré
			if($categories{$param} != 1 && $fathers{$rew_fathers_cats{$param}} != 1 )
			{
				$categories{$param} = 1;
				$fathers{$rew_fathers_cats{$param}} = 1;
				$url .= $rew_names_cats{$lg}{$param}.'/';
			}
		}
	}
	
	if($d{has_children} eq 'y')
	{
		$url =~ s/\/$//g;
	}
	else
	{
		#CURRENT PAGE
		$url .= $current_page;
	}
	
	#PARAMS
	if($d{params} ne '')
	{
		$url .= '-'.$d{params};
	}
	
	$url =~ s/\/\//\//g;
	
	
	my $page = get_quoted('page');
	 my @params = split(/\-/,$page);
	 my @params_r = split(/\=/,$params[1]);
	 my $params_suffix = '';
	 if($params_r[0] eq 't' && $params_r[1] > 0 && $d{params} eq '' && $d{from} ne 'get_tri')
	 {
		$params_suffix = '-t='.$params_r[1];
		$url .= $params_suffix;
	 }

	
	return $url;
	
	# print "<br>sf:$sf,current_page:$current_page,nr:$nr,from:$from,lg:$config{current_language} $url";	
}

sub get_sf_url_rewriting
{
 my $dbh = $_[0];
 my $sf = $_[1];
 my $lg = $_[2] || $config{current_language};
 
 my %lg = sql_line({table=>"migcms_languages",select=>"name",where=>"id=$lg"});
 my %sf = select_table($dbh,"data_search_forms sf, txtcontents txt","txt.lg$lg AS name","sf.id=$sf and sf.id_textid_url_rewriting = txt.id");
 
 my $url = "$lg{name}/$sf{name}";  
}

################################################################################
#map_list_listing
################################################################################
sub map_list_listing
{
      my $tpl = $_[0];
      my $pagination = $_[1];
      my $list = $_[2];
      my $end_page = $_[3];
	  my $last_page = $_[4];
	  my $nr = $_[5];
	  my $has_tarifs = $_[6];
	  my $nbresults = $_[7];
	  my $params = $_[8];
	  
	  #liste déroulante des tris
      my $tri = get_tri($nr,$has_tarifs,'ul',$params);
      my $tri_listbox = get_tri($nr,$has_tarifs,'listbox',$params);
	  
	  #boite aller à la page
	  my $gotobox = get_gotobox($end_page);
	  
	  #boite nombre de résultats (pas encore utilisé)
	  my $nrbox = get_nrbox();

	  #désactive aller à la page si une seule page
	  if($end_page == 1)
	  {
		$gotobox = '';
	  }
	  
	  $tpl =~ s/<MIGC_DATA_GOTOBOX_HERE>/$gotobox/g; 
	  $tpl =~ s/<MIGC_DATA_NRBOX_HERE>/$nrbox/g; 
      $tpl =~ s/<MIGC_DATA_PAGINATION_HERE>/$pagination/g; 
      $tpl =~ s/<MIGC_DATA_TRI_HERE>/$tri/g;
      $tpl =~ s/<MIGC_DATA_TRILISTBOX_HERE>/$tri_listbox/g;
      $tpl =~ s/<MIGC_DATA_LISTING_HERE>/$list /g;
      $tpl =~ s/<MIGC_DATA_NBRESULTS_HERE>/$nbresults /g;

	  $_ = $tpl;
	  
      my @catnames = (/<MIGC_DATA_CATNAMEFORFATHER_\[(\w+)\]_HERE>/g);
      for (my $i = 0; $i<$#catnames+1; $i++ ) 
      {
			my $father = $catnames[$i];
			my $catname = '';
			my $catdescription = '';
			foreach my $num_param (1 .. 10)
			{
				my $param = get_quoted('s'.$num_param);
				if($param !~ /^\d+$/) {next;}
				if($rew_fathers_cats{$param} == $father)
				{
					my %cat = sql_line({table=>'data_categories',select=>'id_textid_name, id_textid_description',where=>"id='$param'"});
					$catname        = get_traduction({debug=>0,id_language=>$config{current_language},id=>$cat{id_textid_name}});
					$catdescription = get_traduction({debug=>1,id_language=>$config{current_language},id=>$cat{id_textid_description}});
				}
			}

			$tpl =~ s/<MIGC_DATA_CATNAMEFORFATHER_\[$father\]_HERE>/$catname/g;
			$tpl =~ s/<MIGC_DATA_CATDESCRIPTIONFORFATHER_\[$father\]_HERE>/$catdescription/g;
      }	  
      
      return $tpl;
}

sub get_tri
{
	my $sf = get_quoted('sf') || $cfg{default_search_form};
	my $nr = $_[0];
	my $has_tarifs = $_[1];
	my $listbox = $_[2] || 'ul';
	my $params_r = $_[3];
	
	my @params_r = split(/\=/,$params_r);
	my $sel_tri_param = 1;
	if($params_r[0] eq 't')
	{
		 $sel_tri_param = $params_r[1];
	}

	
	
	
	my $tri_sel = $sel_tri_param || $config{data_default_tri} || 1;
	

	
	my %sel = ();
	$sel{$tri_sel} = ' selected="selected" '; 
	
	my $link_nouveautes = data::get_data_url({sf=>$sf,nr=>$nr,from=>'get_tri',params=>''});
	my $link_az = data::get_data_url({sf=>$sf,nr=>$nr,from=>'get_tri',params=>'t=2'});
	my $link_prix_croissant = data::get_data_url({sf=>$sf,nr=>$nr,from=>'get_tri',params=>'t=3'});
	my $link_prix_decroissant = data::get_data_url({sf=>$sf,nr=>$nr,from=>'get_tri',params=>'t=4'});
	
	
	my %sel_ul = ();
	$sel_ul{$tri} = 'migc_selitem';

	if($listbox ne 'listbox')
	{
		my $tri = <<"EOH";

			<ul class="clearfix">
				<li><a href="$link_nouveautes" class="$sel{1}">$sitetxt{hm_new}</a></li>
				<!--<li><a href="$link_az" class="$sel{5}">$sitetxt{hm_prix_alpha}</a></li>-->
EOH
		if($has_tarifs eq 'y')
		{
			$tri .= <<"EOH";
				<li><a href="$link_prix_croissant" class="$sel{3}">$sitetxt{hm_prix_croissant}</a></li>
				<li><a href="$link_prix_decroissant" class="$sel{4}">$sitetxt{hm_prix_decroissant}</a></li>
EOH
		}

		$tri .= <<"EOH";
			</ul>
EOH

		return $tri;
	}
	
    my $listbox_tri = '<select name="data_tri" id="data_tri" class="data_tri">'; 
	my $tri_links = '';
    my @numeros_tris = (1,3,4);
	my %libelles = 
	(
		1 => $sitetxt{hm_new},
		# 2 => $sitetxt{hm_prix_alpha},
		3 => $sitetxt{hm_prix_croissant},
		4 => $sitetxt{hm_prix_decroissant},
	);
	
	foreach my $numero_tri (@numeros_tris)
    {
        if($has_tarifs ne 'y' && $numero_tri > 2)
		{
			next;
		}
		
		my $current_url = $ENV{REDIRECT_URL};
		my @tab_url = split(/\//,$current_url);
		my $last_elt = pop @tab_url;
		my ($numpage,$params) = split(/\-/,$last_elt);
		$current_url = join('/',@tab_url);
		$current_url .=  '/'.$numpage;
		
		my $dataurl = $current_url.'-t='.$numero_tri;
		
		$listbox_tri .= ' <option '.$sel{$numero_tri}.' value="'.$numero_tri.'" dataurl="'.$dataurl.'">'.$libelles{$numero_tri}.'</option>';
		my $link = data::get_data_url($dbh,$sf,1,$nr,{},'',$extlink,$numero_tri);
		
		# $tri_links .= << "EOH";
			# <a href="$link" class="tri_link " id="tri_$numero_tri"></a>
# EOH
    }
    $listbox_tri .= '</select>'.$tri_links;
    $listbox_tri .= <<"EOH";
   
 <script type="text/javascript">                        
 jQuery(document).ready(function()
 {
    jQuery(".data_tri").change(function()
    {
		var tri_url = jQuery(this).children('option:selected').attr('dataurl');
		if(tri_url != '')
		{
			window.location=tri_url;
		}		
    });
 });
 </script>
EOH
    
	return $listbox_tri;
}

sub get_gotobox
{
	my $hidden_fields = '';
	my $end_page = $_[0];
	
	# my $sf = get_quoted('sf');
	# my $nr = get_quoted('nr');
	# my $lg = get_quoted('lg');
	# my $extlink = get_quoted('extlink');
	
	# foreach my $num (1 .. 10)
	# {
		# my $val = get_quoted('s'.$num);
		# $hidden_fields .=<<"EOH";
			# <input type="hidden" name="s$num" value="$val" />
# EOH
	# }
	
			# <input type="hidden" name="lg" value="$lg" />
			# <input type="hidden" name="sf" value="$sf" />
			# <input type="hidden" name="nr" value="$nr" />
	
	my $REQUEST_URI = $ENV{REQUEST_URI};

	return <<"EOH";
		<form method="post" action="$self" class="form-inline" role="form">
			<input type="hidden" name="sw" value="gotopage" />
			<input type="hidden" name="request_uri" value="$REQUEST_URI" />
			<input type="hidden" name="last_page" value="$end_page" />
			<strong>Aller page</strong> <input type="text" name="new_page" class="form-control" style="width:40px;" value="" />  / $end_page	
			<button type="submit">OK</button>
		</form>
EOH

}

sub get_nrbox
{
	return '';
}

################################################################################
# GET_CATEGORIES_LIST
################################################################################
sub get_categories_list
{
 my $dbh = $_[0];
 my $already = $_[1];
 my $menu = $_[2];
 my $menufather = $_[3];
 my $me = $_[4];
 my $id_data_family=$_[5] || get_quoted('id_data_family') || 1;
 my $action_on_me = $_[6] || "grey";
 my $list_cat_only = $_[7];
 my $lg = $_[8] || $config{current_language};

 my $list = '<option value="0"></option>';
 if($action_on_me eq 'this_list_cats_only')
 {
    $list = "";
 }
 
 $list .= recurse_categories($treehome,0,$id_data_family,$me,$menufather,$action_on_me,$list_cat_only,$lg); 
 return $list;
}

################################################################################
# RECURSE CATEGORIES
################################################################################
sub recurse_categories
{
 my $father = $_[0] || 0; 
 my $level = $_[1];
 my $id_data_family=$_[2];
 my $me = $_[3]; 
 my $menufather = $_[4];
 my $action_on_me=$_[5];
 my $list_cat_only = $_[6];
 my $lg = $_[7] || $config{current_language};
 my @list_cat_only_tab = split(/\,/,$list_cat_only);
 
 if($lg>0 && $lg <=10)
 {
 }
 else
 {
	$lg = 1;
 }
 
 
 my $tree;
 my $decay = make_spaces($level);
 my @categories = sql_lines({debug=>0,debug_results=>0,table=>"data_categories",select=>"id,id_textid_name,id_father",where=>"id_father='$father' AND id_data_family='$id_data_family'",ordby=>"ordby"});
 # my @categories = sql_lines({debug=>0,debug_results=>0,table=>"data_categories c, txtcontents txt",select=>"id,lg$lg as titre,id_father",where=>"id_textid_name = txt.id AND c.id_father='$father' AND c.id_data_family='$id_data_family'",ordby=>"tit"});

 my $colspan = 1;
 my $i_category = 0;
 foreach $categorie_ref (@categories)
 {
     my %categorie=%{$categorie_ref};
     
     my $title = "";
     if($action_on_me ne 'this_list_cats_only')
     { 
        ($title,$empty) = get_textcontent($dbh,$categorie{id_textid_name},$lg);
     }
     
     my $suppl_disabled="";
     my $suppl_selected="";
     
     if($me == $categorie{id} && $action_on_me eq 'grey')
     {
        $suppl_disabled=<<"EOH";
   disabled="disabled"      
EOH
     }
     elsif($me == $categorie{id} && $action_on_me eq 'select')
     {
         $suppl_selected=<<"EOH";
   selected="selected"      
EOH
     }
     elsif($menufather == $categorie{id})
     {
        $suppl_selected=<<"EOH";
   selected="selected"      
EOH
     }
            
     if($action_on_me eq 'this_list_cats_only')
     {
         if(is_in_array_int($categorie{id},\@list_cat_only_tab))
         {
                my $pere = '';
			    if($categorie{id_father} > 0)
			    {
					my %father = read_table($dbh,'data_categories',$categorie{id_father});
					my $traduction = get_traduction({debug=>0,id_language=>$lg,id=>$father{id_textid_name}});
					$pere = "$traduction";
				}
               $title = get_traduction({id=>$categorie{id_textid_name},id_language=>$lg});
               $tree .= <<"EOH";     
                     <span data-placement="bottom" data-original-title="Associé à : $pere > $title" class="label label-default" style="font-weight:normal!important;"><span style="font-size:14px">$title</span></span>
EOH
         }
     }
     else
     {
     $tree .= <<"EOH";     
                   <option value="$categorie{id}" $suppl_disabled $suppl_selected>$decay $title  </option>
EOH
     
     }
     $tree.= recurse_categories($categorie{id},$level+1,$id_data_family,$me,$menufather,$action_on_me,$list_cat_only,$lg);
     $i_category++;
 }
 return $tree;
}




################################################################################
# DATA WRITE TILES
################################################################################
sub data_write_tiles_optimized
{
  my $dbh = $_[0];
  my %sheet = %{$_[1]};
  my %data_family = %{$_[2]};
  my $id_template = $_[3];
  my $template = $_[4];
  my $lg = $_[5];        
  my $alt_tpl = $_[6] || 0;
  my $return = $_[7] || 'object';
  my $extlink = $_[8];
  my $domaine = $_[9];
  my @discount_rules = @{$_[10]};
  my @discount_rules_pro = @{$_[11]};
  my $generation = $_[12] || 'n'; 
  my %data_setup = %{$_[13]};
  my %tarif = %{$_[14]};
  my $alt_id_data_family  = $_[15];
  my $infos_recherche  = $_[16];

  return data_write_tile_object_optimized($dbh,\%sheet,\%data_family,$id_template,$template,$lg,$return,$alt_tpl,'',$extlink,$domaine,\@discount_rules,$generation,\%data_setup,\%tarif,$alt_id_data_family,$infos_recherche);
}


################################################################################
# DATA WRITE TILE OBJECT
################################################################################
sub data_write_tile_object_optimized
{
  my $dbh = $_[0];
  my %sheet = %{$_[1]};
  my %data_family = %{$_[2]};
  my $id_tpl = $_[3];
  my $tpl = $_[4];
  my $lg = $_[5];
  my $type = $_[6] || 'object';
  my $alt_tpl = $_[7] || 0;
  my $id_member_group = $_[8]; 
  my $extlink = $_[9];
  my $domaine = $_[10];
  my @discount_rules = @{$_[11]};
  my $generation = $_[12] || 'n';   
  my %data_setup = %{$_[13]};
  my %tarif = %{$_[14]};
  my $alt_id_data_family = $_[15];
  my $infos_recherche = $_[16];

  my $html = data_get_html_object($dbh,\%sheet,$tpl,$lg,$id_member_group,$extlink,$domaine,\@discount_rules,$generation,$tarif{id},\%tarif,$alt_id_data_family,\%data_family,$infos_recherche);
  my $name = $type.'_'.$sheet{id}.'_'.$lg.'_'.$id_tpl.'_'.$tarif{id}.'.'.$config{cache_ext};
 
  return $html;
}

################################################################################
# data_get_html_object
################################################################################
sub data_get_html_object
{
  my $dbh = $_[0];
  my %sheet = %{$_[1]};
  my $tpl = $_[2];
  my $lg = $_[3] || 1;
  my $id_member_group = $_[4];
  my $extlink = $_[5] || 1;
  my $domaine = $_[6];
  my $balise_a_remplacer='';
  my $valeur="";
  my @discount_rules = @{$_[7]};
  my $generation = $_[8] || 'n';
  my $id_tarif = $_[9];
  my %tarif = %{$_[10]};  
  my $alt_id_data_family = $_[11];
  my %data_family = %{$_[12]};  
  my $infos_recherche = $_[13];
  # log_debug("",'vide','data_get_html_object');
  if(!($eshop_setup{id} > 0))
  {
	%eshop_setup = sql_line({debug=>0,table=>'eshop_setup'});
  }
  if(!($data_setup{id} > 0))
  {
	%data_setup = sql_line({debug=>0,table=>'data_setup'});
  }
  
  my %lowest_data_stock_tarif = ();
  my %sheet_prices = ();
  
  if($data_family{profil} eq 'products')
  {
	  # %lowest_data_stock_tarif = sql_line({debug=>1,debug_results=>1,table=>"data_stock_tarif dst, data_stock ds",select=>"",ordby=>"st_pu_tvac asc",limit=>'0,1',where=>"st_pu_tvac >0 AND dst.id_data_stock = ds.id AND dst.id_tarif = '$tarif{id}' AND dst.id_data_sheet = '$sheet{id}' $where_stock"});
	  %lowest_data_stock_tarif = sql_line({debug=>0,debug_results=>0,table=>"data_stock_tarif",select=>"taux,st_pu_htva,st_pu_tva,st_pu_tvac,st_pu_htva_discounted,st_pu_tva_discounted,st_pu_tvac_discounted",ordby=>"st_pu_tvac asc",limit=>'0,1',where=>"st_pu_tvac >0 AND id_tarif = '$tarif{id}' AND id_data_sheet = '$sheet{id}'"});
	  %sheet_prices = %{eshop::get_product_prices({from=>'data',debug=>0,generation=>'n',data_sheet=>\%sheet,data_stock_tarif=>\%lowest_data_stock_tarif})};
  }
  
  $_ = $tpl;

  my @balises = (/<MIGC_DATA_(\w+)_HERE>/g);
  for ($i_html = 0; $i_html<$#balises+1; $i_html++ ) 
  {
       $valeur="";
      my $balise=uc($balises[$i_html]);
      my ($type,$element,$precision,$extra_precision)= split(/\_/,$balise);
	  log_debug("$balise: [$type][$element][$precision]",'','data_get_html_object');
      
      if($type eq 'COL')
      {
          $valeur = data_get_html_object_col
          (
              {
                  dbh=>$dbh,
                  type=>$type,
                  element=>$element,
                  precision=>$precision,
                 	extra_precision=>$extra_precision,
                  lg=>$lg,
                  id_member_group=>$id_member_group,
                  extlink=>$extlink,
                  domaine=>$domaine,
                  sheet=>\%sheet,
                  id_tarif=>$id_tarif,
                  tarif=>\%tarif,
                  eshop_setup => \%eshop_setup,
				  sheet_prices => \%sheet_prices,
              }
          );
      }
      elsif($type eq 'CAT')
      {
          $valeur = data_get_html_object_cat($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine);
      }
      elsif($type eq 'CATID')
      {
					$valeur = data_get_html_object_catid($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine);
      }
      elsif($type eq 'PIC')
      {
          $valeur = data_get_html_object_pic($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine,\%data_family);
      }
      elsif($type eq 'FILE')
      {
          $valeur = data_get_html_object_file($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine,\%data_family);
      }
      elsif($type eq 'FILETHUMBS')
      {
          $valeur = data_get_html_object_filethumbs($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine);
      }
      elsif($type eq 'BUTTON')
      {
          $valeur = data_get_html_object_button($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine,\%data_family,\%member,\%tarif,\%data_setup);
      }
      elsif($type eq 'TABLE')
      {
          $valeur = data_get_html_object_table($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine,\@discount_rules,$generation,$id_tarif,\%tarif,\%sheet_prices);
      }
      elsif($type eq 'PAGEFLIP')
      {
        #  use flipbook;
          # $valeur=get_flipbook_html($sheet{id});
      }
      elsif($type eq 'LINKPRODUCT')
      {
          $valeur=data_get_html_object_linkproduct($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine);
      }
      elsif($type eq 'LINK')
      {
          $valeur=data_get_html_object_link($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine,$alt_id_data_family,$infos_recherche);
      }
      elsif($type eq 'ID')
      {
          $valeur=data_get_html_object_id($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine);
      }
      elsif($type eq 'FUNC')
      {
          $valeur=data_get_html_object_func($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine);
      }
      elsif($type eq 'INPUT')
      {
          $valeur=data_get_html_object_input($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine);
      }
      elsif($type eq 'PATH')
      {
          my %sf = read_table($dbh,"data_search_forms",$cfg{default_search_form});
          $valeur=data_get_html_object_path($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine,\%sf);
      }
      elsif($type eq 'LIST')
      {
          $valeur=data_get_html_object_list($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine);
      }
      elsif($type eq 'OG')
      {
          $valeur=data_get_html_object_og($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine);
      }
      elsif($type eq 'MEMBER')
      {
          $valeur=data_get_html_object_member($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine);
      }
      elsif($type eq 'FORM')
      {
          $valeur=data_get_html_form($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine);
      }
      elsif($type eq 'CATEGORY')
      {
          $valeur=data_get_html_object_category($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine);
      }
      elsif($type eq 'LNKSHEETCAT')
      {
          $valeur=data_get_html_object_lnksheetcat($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine);
      } 
      
      $balise_a_remplacer='<MIGC_DATA_'.$balise.'_HERE>';
      $tpl =~ s/$balise_a_remplacer/$valeur/g;
  }
	

	
	$tpl = migcrender::render_tags({template=>$tpl});
  
  return $tpl;
}

################################################################################
# data_get_html_object_link
################################################################################
sub data_get_html_object_link
{
    my $dbh = $_[0];
    my %sheet = %{$_[1]};
    my $type = $_[2];
    my $element = $_[3];
    my $precision = $_[4];
    my $lg = $_[5];
    my $id_member_group = $_[6];
    my $extlink = $_[7] || 1;
    my $domaine = $_[8] || '';
	my $alt_id_data_family = $_[9];
	my $infos_recherche = $_[10];
	
	
	
	
    
    my $valeur="";
    
    my $full_url = 'n';
    if($domaine ne '')
    {
        $full_url = 'y';
    }
    
    if($element eq 'DETAIL')
    {
		my $id_data_family = $alt_id_data_family || $sheet{id_data_family} || get_quoted('id_data_family');
		$valeur = $domaine.get_data_detail_url($dbh,\%sheet,$lg,$extlink,$full_url,'',$id_data_family);      
    }
	elsif($element eq 'DETAILSEARCHINFOS')
    {
		$valeur =  ' data-searchinfos = "'.$infos_recherche.'" ';
    }
	elsif($element eq 'DETAILCLASS')
    {
		$valeur = ' save_search_info ';
    }
	elsif($element eq 'PREVIOUSSHEET')
    {
		$valeur = get_next_prev_sheet('previous_sheet',\%sheet,$infos_recherche);
    }
	elsif($element eq 'NEXTSHEET')
    {
		$valeur = get_next_prev_sheet('next_sheet',\%sheet,$infos_recherche);
    }
    elsif($element eq 'FILE')
    {
            $precision = $precision || 1;
            my %migcms_linked_file = sql_line({debug=> 0, debug_results=> 0, table=>"migcms_linked_files",where=>"token = $sheet{id} AND table_name='data_sheets' AND table_field='fichiers' AND visible='y' AND ordby = $precision"});
            my $rel = "$migcms_linked_file{file_dir}/$migcms_linked_file{full}$migcms_linked_file{ext}";
			$rel  =~ s/\.\.\///g; 

			
			if($migcms_linked_file{id} > 0)
            {
                my ($name,$dum) = get_textcontent($dbh,$migcms_linked_file{id_textid_legend}); 
                $valeur=<<"EOH";
                    <a class="data_link" href="$rel" target="_blank">$name</a>
EOH
            }
    }
    elsif($element eq 'FILEURL')
    {

			
			$precision = $precision || 1;
            my %migcms_linked_file = sql_line({debug=> 0, debug_results=> 0, table=>"migcms_linked_files",where=>"token = $sheet{id} AND table_name='data_sheets'  AND visible='y' AND table_field='fichiers' AND ordby = $precision"});

            my $rel = "$migcms_linked_file{file_dir}/$migcms_linked_file{full}$migcms_linked_file{ext}";
			$rel  =~ s/\.\.\///g; 

            if($migcms_linked_file{id} > 0)
            {
                $valeur="$rel";
            }
    }
    
    return $valeur;
}

sub get_next_prev_sheet
{
	my $sens = $_[0];
	my $search_infos = $_[2];
	my %sheet = %{$_[1]};
	
	
	if($search_infos eq '')
	{
		#cas fiche detail: l'infors recherche se trouve dans le cookie$
		my $cookie_migcms_data_search_info = $cgi->cookie('migcms_data_search_info');
		if($cookie_migcms_data_search_info ne "")
		{
			$search_infos = $cookie_migcms_data_search_info;
			$cookie_migcms_data_search_info =~ s/\'/\"/g;
			$cookie_migcms_data_search_info_ref = decode_json $cookie_migcms_data_search_info;
			my %cookie_migcms_data_search_info = %{$cookie_migcms_data_search_info_ref};
			if($sens eq 'previous_sheet')
			{
				$cookie_migcms_data_search_info{iteration}--;
			}
			else
			{
				$cookie_migcms_data_search_info{iteration}++;
			}
			
			$search_infos = encode_json \%cookie_migcms_data_search_info;
			$search_infos =~ s/\"/\'/g;
		}
	}
	
	
	
	my %cookie_migcms_data_search_info = ();
	my $cookie_migcms_data_search_info = $cgi->cookie('migcms_data_search_info');
	if($cookie_migcms_data_search_info ne "")
	{
		  $cookie_migcms_data_search_info =~ s/\'/\"/g;
		  $cookie_migcms_data_search_info_ref = decode_json $cookie_migcms_data_search_info;
		  %cookie_migcms_data_search_info = %{$cookie_migcms_data_search_info_ref};
	}
	
	 my %data_setup = %{data_get_setup()};
	 my %data_family = read_table($dbh,"data_families",$sheet{id_data_family}); 
	 my %data_search_form = read_table($dbh,"data_search_forms",$cookie_migcms_data_search_info{sf}); 
	 my %alt_data_family = sql_line({table=>'data_families',where=>"id='$data_family{id_alt_data_family}'"}); 
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
	
  	 #obtenir une url à partir de critères de recherches
	 my $url_detail_data_sheet = compute_sheets(
	 {
		debug=>0,
		keyword=>$cookie_migcms_data_search_info{keyword},
		s1=>$cookie_migcms_data_search_info{s1},
		s2=>$cookie_migcms_data_search_info{s2},
		s3=>$cookie_migcms_data_search_info{s3},
		s4=>$cookie_migcms_data_search_info{s4},
		s5=>$cookie_migcms_data_search_info{s5},
		s6=>$cookie_migcms_data_search_info{s6},
		url_only=>'y',
		$sens=>'y',
		sf=>$data_search_form{id},
		data_setup=>\%data_setup,
		data_family=>\%data_family,
		tarif=>\%tarif,
		current_page=>$cookie_migcms_data_search_info{page},
		nr=>$cookie_migcms_data_search_info{nr},
		iteration=>$cookie_migcms_data_search_info{iteration},
		lg=>$config{current_language},
	});
	
	if($url_detail_data_sheet eq '')
	{
		return '';
	}
	
	$valeur = <<"EOH";
		<a href="$url_detail_data_sheet" data-searchinfos="$search_infos" class="save_search_info" id="$sens"><MIGC_TXT_[$sens]_HERE></a>
EOH
	return $valeur;
}

################################################################################
# data_get_html_object_id
################################################################################
sub get_data_detail_url
{
 my $dbh = $_[0];
 my %sheet = %{$_[1]};
 my $lg = $_[2] || $config{current_language};
 my $extlink = $_[3] || 1;
 my $full_url = $_[4] || 'n';
 my $id_data_family = $_[6];
 
 my $domaine = $config{fullurl};
 if($full_url ne 'y')
 {
      $domaine = '';
 }
 
 if(!($id_data_family > 0))
 {
  $id_data_family = $sheet{id_data_family};
 }
 if(!($id_data_family > 0))
 {
  $id_data_family = $cfg{default_family};
 }
 my %fam = sql_line({debug=>0,table=>"data_families",select=>'id,id_textid_url_rewriting,id_textid_fiche',where=>"id='$id_data_family'"});

 my ($url_rewriting,$empty) = get_textcontent($dbh,$fam{id_textid_url_rewriting},$lg);
 my ($fiche,$empty) = get_textcontent($dbh,$fam{id_textid_fiche},$lg);
 my ($name,$empty) = get_textcontent($dbh,$sheet{id_textid_url_rewriting},$lg);
 # $name  =~ s/\-//g;
 $name = clean_url($name);
 
  $fiche = $fiche || 'detail';
 
 
  my %lg = sql_line({table=>"migcms_languages",select=>"name",where=>"id=$lg"});
  
  if($domaine eq '')
  {
	$domaine = $config{baseurl};
  }
  if($config{data_force_extlink} > 0)
  {
	$extlink = $config{data_force_extlink};
  }  
  my $url = $domaine.'/'.$lg{name}."/$url_rewriting/$fiche/$name-$sheet{id}-$extlink";
  
  # log_debug($url,'','debugsitemap');
  return $url; 
}


################################################################################
# data_get_html_object_pic
################################################################################
sub data_get_html_object_pic
{
    my $dbh = $_[0];
    my %sheet = %{$_[1]};
    my $type = $_[2];
    my $element = $_[3];
    my $precision = $_[4];
    my $lg = $_[5];
    my $domaine = $_[8] || '';
	my %data_family = %{$_[9]};
    my $full_url = 'n';
    if($domaine ne '')
    {
        $full_url = 'y';
    }
    
    my $valeur="";
	
	my $force_alt_pic = '';
	if($data_family{id_field_name} > 0)
	{
		# my %data_field = read_table($dbh,"data_fields",$data_family{id_field_name});
		my %data_field = %{$cache_data_fields_id{$data_family{id_field_name}}};

		#SI CHAMP TRADUCTIBLE
		if($data_field{field_type} eq 'text_id' || $data_field{field_type} eq 'textarea_id' || $data_field{field_type} eq 'textarea_id_editor')
		{
			($force_alt_pic,$dummy) = get_textcontent($dbh,$file{id_textid_name},$lg);
		}
		else
		{
			$force_alt_pic = $sheet{'f'.$data_field{ordby}};
		}
	}
    
    if($element eq 'ALL')
    {
         my @pics = sql_lines({debug=>0,debug_results=>0,table=>"migcms_linked_files lnk",where=>"lnk.table_name='data_sheets' AND table_field = 'photos' AND lnk.visible='y'  AND lnk.token = '$sheet{id}'",ordby=>'ordby_force,ordby'});
         foreach $pic(@pics)
         {
             my %pic=%{$pic};
             $valeur .= data_get_html_object_pic_content(\%pic,$precision,\%sheet,'',$lg,$force_alt_pic,$full_url);
         }
    }
    elsif($element > 0)
    {
          $element--;
          my $limit =  $element.', 1 ';
		  my %pic = sql_line({debug=>0,debug_results=>0,table=>"migcms_linked_files lnk",where=>"lnk.table_name='data_sheets' AND table_field = 'photos' AND lnk.visible='y' AND lnk.token = '$sheet{id}'",ordby=>'ordby_force,ordby',limit=>$limit});
      
          $valeur .= data_get_html_object_pic_content(\%pic,$precision,\%sheet,'',$lg,$force_alt_pic,$full_url);
    }

    return $valeur;
}

################################################################################
# data_get_html_object_file
################################################################################
sub data_get_html_object_file
{
    my $dbh = $_[0];
    my %sheet = %{$_[1]};
    my $type = $_[2];
    my $element = $_[3];
    my $precision = $_[4];
    my $lg = $_[5];
    my $domaine = $_[8] || '';
	my %data_family = %{$_[9]};
    my $full_url = 'n';
    if($domaine ne '')
    {
        $full_url = 'y';
    }
    
    my $valeur="";
	
	my $force_alt_pic = '';
	if($data_family{id_field_name} > 0)
	{
		# my %data_field = read_table($dbh,"data_fields",$data_family{id_field_name});
		my %data_field = %{$cache_data_fields_id{$data_family{id_field_name}}};
		

		#SI CHAMP TRADUCTIBLE
		if($data_field{field_type} eq 'text_id' || $data_field{field_type} eq 'textarea_id' || $data_field{field_type} eq 'textarea_id_editor')
		{
			($force_alt_pic,$dummy) = get_textcontent($dbh,$file{id_textid_name},$lg);
		}
		else
		{
			$force_alt_pic = $sheet{'f'.$data_field{ordby}};
		}
	}
	
    
    if($element eq 'ALL')
    {
         my @pics = sql_lines({debug=>0,debug_results=>0,table=>"migcms_linked_files lnk",where=>"lnk.table_name='data_sheets' AND table_field = 'fichiers' AND lnk.visible='y'  AND lnk.token = '$sheet{id}'",ordby=>'ordby'});
         foreach $pic(@pics)
         {
             my %pic=%{$pic};
			 $valeur .= data_get_html_object_file_content(\%pic,$precision,\%sheet,'',$lg,$force_alt_pic,$full_url);
         }
    }
    elsif($element > 0)
    {
          $element--;
          my $limit =  $element.', 1 ';
		  my %pic = sql_line({debug=>0,debug_results=>0,table=>"migcms_linked_files lnk",where=>"lnk.table_name='data_sheets' AND table_field = 'fichiers' AND lnk.visible='y' AND lnk.token = '$sheet{id}'",ordby=>'ordby',limit=>$limit});
      
          $valeur .= data_get_html_object_file_content(\%pic,$precision,\%sheet,'',$lg,$force_alt_pic,$full_url);
    }

    return $valeur;
}

###############################################################################
# data_get_html_object_file_content
################################################################################
sub data_get_html_object_file_content
{
  
   use Image::Size;
   
   my %pic = %{$_[0]};
   my $precision = $_[1] || "SMALL";
   my %sheet = %{$_[2]};
   my $class_supp = $_[3] || '';
   my $lg = $_[4] || '';
   my $force_name = $_[5]; 
   my $full_url = $_[6] || 'n';
   my $domaine = $config{baseurl}.'/';
   my $valeur = "";

	my $filename =  $pic{file_dir}.'/'.$pic{full}.$pic{ext};
	$filename =~ s/\.\.\///g;
   my ($name,$dummy) = get_textcontent($dbh,$pic{id_textid_legend},$lg);

   
   if($precision eq 'URL')
   {
		$valeur = $filename;
    }
	elsif($precision eq 'LINK')
   {
		$valeur = <<"EOH";
			   <a target="_blank" href="/$filename" data-idlf="$pic{id}" class="data_filename_$precision" title="$name"  rel="">$name</a>
EOH
    }
    return $valeur;
}

###############################################################################
# data_get_html_object_pic
################################################################################
#renvoie le contenu d'une balise PIC
sub data_get_html_object_pic_content
{
  
   use Image::Size;
   # log_debug('data_get_html_object_pic_content','','data_get_html_object_pic_content');
   
   my %pic = %{$_[0]};
   
   my $precision = $_[1] || "SMALL";
   my %sheet = %{$_[2]};
   my $class_supp = $_[3] || '';
   my $lg = $_[4] || '';
   my $force_name = $_[5]; 
   my $full_url = $_[6] || 'n';
   my $domaine = $config{baseurl}.'/';
   my $valeur = "";
   
	my $taille = lc($precision);
	$taille =~ s/lightbox//g;
	$taille =~ s/detail//g;
	$taille =~ s/url//g;
	
	
	# log_debug($precision,'','data_get_html_object_pic_content');
	# log_debug($taille,'','data_get_html_object_pic_content');
	# log_debug($pic{id},'','data_get_html_object_pic_content');
	
	my $pic_width = $pic{'width_'.$taille};
    my $pic_height = $pic{'height_'.$taille};

	if($full_url ne 'y')
   {
      $domaine = '';
   }
   
  my $schemaorg = "";
  if($config{schema_org} eq "y") 
  {
	  $schemaorg = " itemprop=\"image\" ";
	  $schemaorgurl = " itemprop=\"url\" ";
  }
   
   $config{file_dir} = $pic{file_dir};
   
 my ($name,$dummy) = get_textcontent($dbh,$pic{id_textid_legend},$lg);

   if($force_name ne '') { $name = $force_name; }
   
   if(is_in_array($precision,[ 'MINI', 'SMALL', 'MEDIUM', 'LARGE','FULL', 'OG']) )
   {
         # log_debug('PRECISION1','','data_get_html_object_pic_content');
		 my $pic_name=$pic{'name_'.$taille};
		 # log_debug($pic_name,'','data_get_html_object_pic_content');
		 if($taille eq 'full')
		 {
			$pic_name = $pic{$taille}.$pic{ext};
		 }
         if($pic_name  ne "" && -e $config{file_dir}."/$pic_name")
         {
				  if($config{baseurl} ne '')
				  {
					  my $reg = '../';
					  $config{file_dir} =~ s/$reg//;
				  }
				  else
				  {
					  my $reg = '../';
					  $config{file_dir} =~ s/$reg/\//;
				  }
				  my $src = $domaine.$config{file_dir}.'/'.$pic_name;
				  
				   if(!($pic_width > 0 && $pic_height > 0))
				    {
						 ($pic_width, $pic_height ) = imgsize('../'.$config{file_dir}.'/'.$pic_name);
					}
				  
				  
				  if($full_url eq 'y')
				   {
					  $src = $config{fullurl}.'/'.$config{file_dir}.'/'.$pic_name;
				   }
                  $valeur=<<"EOH";
                   <img src="$src" class="$precision $class_supp data_get_html_object_pic_content1" alt="$name" title="$name" width="$pic_width" height="$pic_height" $schemaorg />
EOH
         }
		 else
		 {
			# log_debug('existe pas :'.$config{file_dir}."/$pic_name",'','data_get_html_object_pic_content');
		 }
         
    }
	elsif(is_in_array($precision,[ 'MINILAZYLOAD', 'SMALLLAZYLOAD', 'MEDIUMLAZYLOAD', 'LARGELAZYLOAD','FULLLAZYLOAD', 'OGLAZYLOAD']) )
    {
		$taille =~ s/lazyload//g;        
		my $pic_name=$pic{'name_'.$taille};
		# print "<hr>if($pic_name  ne \"\" && -e $config{file_dir}.\"/$pic_name\")";
		
		 if($taille eq 'full')
		 {
			$pic_name = $pic{$taille}.$pic{ext};
		 }
         # print "if($pic_name  ne \"\" && -e $config{file_dir}.\"/$pic_name\")";
		 if($pic_name  ne "" && -e $config{file_dir}."/$pic_name")
         {
				  if($config{baseurl} ne '')
				  {
					  my $reg = '../';
					  $config{file_dir} =~ s/$reg//;
				  }
				  else
				  {
					  my $reg = '../';
					  $config{file_dir} =~ s/$reg/\//;
				  }
				  my $src = $domaine.$config{file_dir}.'/'.$pic_name;
				  
				   if(!($pic_width > 0 && $pic_height > 0))
				    {
						 ($pic_width, $pic_height ) = imgsize('../'.$config{file_dir}.'/'.$pic_name);
					}
				  
				  
				  if($full_url eq 'y')
				   {
					  $src = $config{fullurl}.'/'.$config{file_dir}.'/'.$pic_name;
				   }
                  $valeur=<<"EOH";
                   <img data-original="$src" class="$precision $class_supp data_get_html_object_pic_content1" alt="$name" title="$name" width="$pic_width" height="$pic_height" $schemaorg />
EOH
         }
         
    }	
    elsif(is_in_array($precision,[ 'MINIURL', 'SMALLURL', 'MEDIUMURL', 'LARGEURL','FULLURL', 'OGURL']) )
    {
         my $pic_name=$pic{'name_'.$taille};
         if($taille eq 'OG')
         {
         }
         
         if($pic_name  ne "" && -e $config{file_dir}."/$pic_name")
         {
                  #if($config{cdn} eq 'y')
                  #{
                  #    $valeur="$config{pic_url}/$pic_name";
                  #}
                  #else
                  #{
                  #    $valeur=$domaine."$config{pic_url}/$pic_name";
                  #}
				  
				  if($config{baseurl} ne '')
				  {
					  my $reg = '../';
					  $config{file_dir} =~ s/$reg//;
				  }
				  else
				  {
					  my $reg = '../';
					  $config{file_dir} =~ s/$reg/\//;
				  }
				  $valeur = $domaine.$config{file_dir}.'/'.$pic_name;
         }
    }
    elsif(is_in_array($precision, [ 'MINILIGHTBOX', 'SMALLLIGHTBOX', 'MEDIUMLIGHTBOX', 'LARGELIGHTBOX', 'FULLLIGHTBOX']) )
    {
		 $precision =~ s/LIGHTBOX//g;
         my $pic_name=$pic{'name_'.$taille};
		 my $pic_name_large = $pic{'name_large'};
		  if($pic_name_large eq '')
		 {
			$pic_name_large = $pic{'name_full'};
		 }
         if($pic_name  ne "" && -e $config{file_dir}."/$pic_name")
         {
			  my $reg = '../';
			  $config{file_dir} =~ s/$reg//;
			  $config{pic_url} = $config{file_dir};
			  my $src = $domaine.$config{file_dir}.'/'.$pic_name;
			  $valeur=<<"EOH";
			   <a href="$config{baseurl}/$config{pic_url}/$pic_name_large" class="nyromodal $class_supp" title="$name"  rel="gal"> <img src="$config{baseurl}/$src" class="img_$class_supp $precision" alt="$name"  width="$pic_width" height="$pic_height" $schemaorg /> </a>
EOH
         }
    }
    elsif(is_in_array($precision, [ 'MINIDETAIL', 'SMALLDETAIL', 'MEDIUMDETAIL', 'LARGEDETAIL', 'FULLDETAIL']))
    {
         $precision =~ s/DETAIL//g;
         my $pic_name=$pic{'name_'.lc($precision)};
		 my $pic_name_large = $pic{'name_large'};
		 if($pic_name_large eq '')
		 {
			$pic_name_large = $pic{'name_full'};
		 }       
         if($pic_name  ne "" && -e $config{file_dir}."/$pic_name")
         {
                  $valeur=<<"EOH";
                   <a href="cgi-bin/data.pl?sw=detail&id_data_sheet=$sheet{id}&id_data_family=$sheet{id_data_family}"  title="$name" class="$class_supp data_pic_lnk_detail" $schemaorgurl> <img src="$config{pic_url}/$pic_name" class="img_$class_supp $precision" alt="$name"  width="$pic_width" height="$pic_height" /> </a>
EOH
         }
    }
	
	# log_debug($valeur,'','data_get_html_object_pic_content');

    return $valeur;
}


################################################################################
# data_get_html_object_col
################################################################################
sub data_get_html_object_col
{
    my %d = %{$_[0]};
    
    my $dbh = $d{dbh};
    my %sheet = %{$d{sheet}};
	my %sheet_prices = %{$d{sheet_prices}};
	
    my %eshop_setup = %{$d{eshop_setup}};
    my $type = $d{type};
    my $element = $d{element};
    my $precision = $d{precision};
    my $extra_precision = lc($d{extra_precision});
    my $lg = $d{lg};
    my $id_member_group = $d{id_member_group};

	
    
    $element =~ s/^F//g;
    
    # my %field = select_table($dbh,"data_fields","","id_data_family='$sheet{id_data_family}' AND ordby = '$element'");
    my %field = %{$cache_data_fields{$sheet{id_data_family}}{$element}};
    if($precision eq 'LABEL')
    {
         my ($name,$dummy) = get_textcontent($dbh,$field{id_textid_name},$lg);
         $valeur=$name;
    }
    elsif($precision eq 'VALUE')
    {
          if($field{field_type} eq "text" || $field{field_type} eq "checkbox" || $field{field_type} eq "textarea_editor" || $field{field_type} eq "textarea")
          {
              $valeur=$sheet{'f'.$element};
			  if($field{data_type} eq 'date')
			  {
				$valeur = to_ddmmyyyy($valeur);
				if($valeur eq '//')
				{
					$valeur = '';
				}
			  }
          }
          elsif($field{field_type} eq "text_id" || $field{field_type} eq "textarea_id" || $field{field_type} eq "textarea_id_editor")
          {
              ($valeur,$dum)=get_textcontent($dbh,$sheet{'f'.$element},$lg);
              if ($valeur eq "" && $lg > 1) {
                  ($valeur,$dum)=get_textcontent($dbh,$sheet{'f'.$element},1);              
              }
              
              if($field{field_type} eq "textarea_id_editor")
              {
                  $valeur =~ s/usr\/\//usr\//g;
                  $valeur =~ s/$htaccess_protocol_rewrite:\/\/usr/usr/g;
              }
              
          }
          elsif($field{field_type} eq "listbox")
          {
              my $id_data_field_listvalue=$sheet{'f'.$element};
              my %data_field_listvalue=select_table($dbh,"data_field_listvalues","id_textid_name","id='$id_data_field_listvalue'");
              ($valeur,$dum)=get_textcontent($dbh,$data_field_listvalue{id_textid_name},$lg);
          }
		  elsif($field{field_type} eq "listboxtable")
          {
              my $id_rec = $sheet{'f'.$element};
              if($field{lbtable} ne '' && $field{lbkey} ne '' && $field{lbdisplay} ne '')
			  {
				my %rec = sql_line({table=>$field{lbtable},select=>"$field{lbdisplay} as affichage",where=>"$field{lbkey}='$id_rec'"});
				if($field{lbdisplay} =~ /id_textid/)
				{
					$rec{affichage} = get_traduction({id=>$rec{affichage},id_language=>$config{current_language}});
				}
				$valeur = $rec{affichage};
			  }
			  else
			  {
				$valeur = "Configuration manquante: TABLE: $field{lbtable} CLE: $field{lbkey} DISPLAY: $field{lbdisplay}";
			  }
			  # my %data_field_listvalue=select_table($dbh,"data_field_listvalues","id_textid_name","id='$id_data_field_listvalue'");
              # ($valeur,$dum)=get_textcontent($dbh,$data_field_listvalue{id_textid_name},$lg);
			  
			  # $valeur = "TOTO".$id_rec;
          }
		  elsif($field{field_type} eq "files_admin")
          {
			 $valeur = '';
			 my @migcms_linked_files = sql_lines({debug=>0,debug_results=>0,table=>"migcms_linked_files",where=>"table_name='data_sheets' AND token = '$sheet{id}' AND table_field='f$element' and visible='y' ",ordby=>'ordby'});
			 foreach $migcms_linked_file(@migcms_linked_files)
			 {
				 my %migcms_linked_file=%{$migcms_linked_file};
				 my $file = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
				 $file =~ s/^\.\.//g;
				 $valeur .= $file;
			 }
          }
    } 
    elsif($precision eq 'CODE')
    {
    	my $id_rec = $sheet{'f'.$element};
    	my %migcms_codes = sql_line({dbh=>$dbh, table=>"migcms_codes", where=>"id = '$id_rec'"});
    	$valeur = $migcms_codes{$extra_precision};
    }   
   elsif($element eq 'PRICEHTVA')
    {
		$valeur = display_price($sheet_prices{price_htva});
    }
	elsif($element eq 'PRICETVAC')
    {
		$valeur = display_price($sheet_prices{price_tvac});
    }
    elsif($element eq 'PRICE')
    {
		if($d{tarif}{is_tvac} eq 'y')
		{
		  $valeur = display_price($sheet_prices{price_tvac});
		}
		else
		{
		  $valeur = display_price($sheet_prices{price_htva});
		}
    }
    elsif($element eq 'STOCK')
    {
         my %simple_stock = sql_line({table=>"data_stock",select=>"SUM(stock) as total_stock",where=>"id_data_sheet = '$sheet{id}'"});
				 $valeur = $simple_stock{total_stock};
    }
    elsif($element eq 'TAXES')
    {
          $valeur = $sheet{taxes};  
    }
    elsif($element eq 'HASTAXES')
    {
          $valeur = $sheet{has_taxes};  
    }
    elsif($element eq 'PRICETVACHTVA')
    {
			# Renvoi HTVA ou TVAC en fonction du tarif
			if($d{tarif}{is_tvac} eq 'y')
			{
			  $valeur = $sitetxt{eshop_tvac};
			}
			else
			{
			  $valeur = $sitetxt{eshop_htva};
			}
    }
    elsif($element eq 'DISCOUNTPRICE')
    {
		if($d{tarif}{is_tvac} eq 'y')
		{
		  $valeur = display_price($sheet_prices{price_discounted_tvac});
		}
		else
		{
		  $valeur = display_price($sheet_prices{price_discounted_htva});
		}
    }
	 elsif($element eq 'DISCOUNTPRICETVAC')
     {
		$valeur = display_price($sheet_prices{price_discount_tvac});
     }
	 elsif($element eq 'DISCOUNTPRICEHTVA')
     {
		$valeur = display_price($sheet_prices{price_discount_htva});
     }
     elsif($element eq 'DISCOUNTTAUX')
     {
		$valeur = $sheet_prices{price_discount_taux};
		if($valeur eq "") {
			$valeur = "0";
		}
     }
     elsif($element eq 'TAUXTVA')
     {
     		my %tva = sql_line({dbh=>$dbh, table=>"eshop_tvas", where=>"id = '$sheet{taux_tva}'"});
        $valeur = $tva{tva_value}*100;          
     }
     elsif($element eq 'DISCOUNTYES')
     {
		$valeur = $sheet_prices{discounted};          
     }
	 elsif($element eq 'PRIXRONDS')
     {
		$valeur = $sheet_prices{prixronds};          
     }
     elsif($element eq 'NEWYES')
     {
          if($cfg{custom_new} eq 'y')
          {
              $valeur = $sheet{custom_new};
          }
          else
          {
              $valeur = $sheet{new};
          }
     }    
     elsif($precision eq 'URLTOFILE')
    {
          my $url = get_url_file_from_list($dbh,$sheet{'f'.$element},$lg);
          $valeur = $url;         
    }
    elsif($precision eq 'URLTOFILEYES')
    {
          my $url = get_url_file_from_list($dbh,$sheet{'f'.$element},$lg);
          if($url eq '')
          {
              $valeur = 'n';
          }
          else
          {
              $valeur = 'y';
          }
    }
    elsif($precision eq 'LINKTOVIDEOPLAYERINLIGHTBOX')
    {
           my $url = get_url_file_from_list($dbh,$sheet{'f'.$element},$lg);
           my $link = <<"EOH";
   <a class="nyroModal link_video shop_product_short_video" href="cgi-bin/data.pl?sw=lightbox_video&amp;url=$url">$sitetxt{linktovideo}</a>        
EOH
            if($url eq '') {$link = '';}
          $valeur = $link;
    }
    else
    {
         $valeur = '';
    }
  
  $valeur  =~ s/ampersands/&/g;
  
    return $valeur;
}

################################################################################
# data_get_html_object_cat
################################################################################
sub data_get_html_object_cat
{
    my $dbh = $_[0];
    my %sheet = %{$_[1]};
    my $type = $_[2];
    my $element = $_[3];
    my $precision = $_[4];
    my $lg = $_[5];
    my $id_member_group = $_[6];
    
    my $where_element = '';
    if($element  ne '')
    {
       $where_element = "AND id_father=$element";
    }
    
    my @categories_list = ();
    my @categories = sql_lines({table=>"data_categories c, data_lnk_sheets_categories lnk",where=>"c.id = lnk.id_data_category AND id_data_sheet = '$sheet{id}' $where_element"});
    foreach $cat (@categories)
    {
        my %cat = %{$cat};
        my ($name,$dummy) = get_textcontent($dbh,$cat{id_textid_name},$lg); 
        if($name ne '')
        {
            push @categories_list,$name;
        }    
    }
    
    return join(',',@categories_list);
}

################################################################################
# data_get_html_object_catid
################################################################################
sub data_get_html_object_catid
{
    my $dbh = $_[0];
    my %sheet = %{$_[1]};
    my $type = $_[2];
    my $element = $_[3];
    my $precision = $_[4];
    my $lg = $_[5];
    my $id_member_group = $_[6];
    
    my $where_element = '';
    if($element  ne '')
    {
       $where_element = "AND id_father=$element";
    }
    
    my @categories_list = ();
    my @categories =get_table($dbh,"data_categories c, data_lnk_sheets_categories lnk","","c.id = lnk.id_data_category AND id_data_sheet = '$sheet{id}' $where_element",'','','',0);
    foreach $cat (@categories)
    {
        my %cat = %{$cat};

        if($cat{id} > 0)
        {
            push @categories_list,$cat{id_data_category};
        }    
    }
    
    return join('-',@categories_list);
}

################################################################################
# data_get_html_object_list
################################################################################
sub data_get_html_object_list
{
    my $dbh = $_[0];
    my %sheet = %{$_[1]};
    my $type = $_[2];
    my $element = $_[3];
    my $precision = $_[4];
    my $lg = $_[5];
    my $id_member_group = $_[6];
    
    my %data_list_sheet = select_table($dbh,"data_list_sheets","","id_parag='$sheet{id_parag}' AND ordby ='$precision'",'','',0);
    if($element eq 'URL')
    {
        %sheet = read_table($dbh,"data_sheets",$data_list_sheet{id_data_sheet});
        my $url = '';
        if($sheet{id} > 0)
        {
            $url = get_data_detail_url($dbh,\%sheet,$data_list_sheet{id_language},$extlink,'y');   ;
        }
        return $url;
    }
    elsif($element eq 'LABEL')
    {
        return $data_list_sheet{product_name};
    }
    elsif($element eq 'DESCRIPTION')
    {
        return $data_list_sheet{description};
    }
    elsif($element eq 'PRICE')
    {
        if($data_list_sheet{full_price} == 0)
        {
            $data_list_sheet{full_price} = '';
        }
        return $data_list_sheet{full_price};
    }
    elsif($element eq 'DISCOUNTPRICE')
    {
        if($data_list_sheet{discount_price} == 0)
        {
            $data_list_sheet{discount_price} = '';
        }
        return $data_list_sheet{discount_price};
    }
    elsif($element eq 'ORDBY')
    {
        return $data_list_sheet{ordby};
    }
    elsif($element eq 'PICTURE')
    {
        my $picture = '';
        
        if($data_list_sheet{id_lnk_pic} > 0)
        {
            my %pic=select_table($dbh,"data_lnk_sheet_pics lnk","","lnk.id='$data_list_sheet{id_lnk_pic}'");
            $picture = data_get_html_object_pic_content(\%pic,'SMALL',\%sheet,'',$lg,'','y');
        }
        elsif($data_list_sheet{new_photo} ne '')
        {
				  # my $reg = '../';
				  # $pic{file_dir} =~ s/$reg//;
				  # my $src = $domaine.$config{file_dir}.'/'.$pic_name;

			$picture = '<img src="'.$config{baseurl}.'/pics/'.$data_list_sheet{new_photo}.'" alt="'.$data_list_sheet{product_name}.'" />';
        } 
        return $picture;
    }
    
    return $valeur;
}


################################################################################
# data_get_html_object_og
################################################################################
sub data_get_html_object_og
{
    my $dbh = $_[0];
    my %sheet = %{$_[1]};
    my $type = $_[2];
    my $element = $_[3];
    my $precision = $_[4];
    my $lg = $_[5];
    my $id_member_group = $_[6];
    my $valeur = '';
    
#     debug('data_get_html_object_og');
    if($element eq 'IMAGE')
    {
        # my %pic=select_table($dbh,"data_lnk_sheet_pics lnk, pics p","","id_data_sheet='$sheet{id}' AND id_pic=p.id AND lnk.visible='y' order by lnk.ordby asc limit 0,1",'','',0);
        # my $pic_url = data::data_get_html_object_pic_content(\%pic,'OGURL',\%sheet,'',$lg,'','y');
		
		my %pic = sql_line({debug=>0,debug_results=>0,table=>"migcms_linked_files lnk",where=>"lnk.table_name='data_sheets' AND table_field = 'photos' AND lnk.visible='y' AND lnk.token = '$sheet{id}'",ordby=>'ordby',limit=>'0,1'});
		$valeur = '['.data_get_html_object_pic_content(\%pic,$precision,\%sheet,'',$lg,$force_alt_pic,$full_url);
    }
    
    return $valeur;
}

################################################################################
# data_get_html_object_member
################################################################################
sub data_get_html_object_member
{
    my $dbh = $_[0];
    my %sheet = %{$_[1]};
    my $type = $_[2];
    my $element = $_[3];
    my $precision = $_[4];
    my $lg = $_[5];
    my $id_member_group = $_[6];
    my $valeur = '';

    my $cookie_member = $cgi->cookie($config{front_cookie_name});
    if($cookie_member ne "")
    {
        $cookie_member_ref=decode_json $cookie_member;
        %hash_member=%{$cookie_member_ref};
    }
  
  my %test_member = sql_line({debug=>0,dbh=>$dbh,table=>'migcms_members',where=>"token != '' && token='$hash_member{member_token}'"});

   # return <<"EOH";
   # $hash_member{eshop_token} ne '' && $hash_member{id} == $test_member{id} && $test_member{id} > 0
# EOH
  if($element eq "LOGGED") 
  {
    if($test_member{id} > 0)
    {
        return 'y';
    }
    else
    {
        return 'n';
    }
  }
  elsif ($element eq "IDTARIF")
  {
    if($test_member{id} > 0)
    {

      return $test_member{id_tarif};
    }
  } 
    
}

################################################################################
# data_get_html_object_category
################################################################################
sub data_get_html_object_category
{
    my $dbh = $_[0];
    my %sheet = %{$_[1]};
    my $type = $_[2];
    my $element = $_[3];
    my $precision = $_[4];
    my $lg = $_[5];
    my $id_member_group = $_[6];
    my $valeur = '';
    
#     debug('data_get_html_object_og');
    if($element eq 'NAME')
    {
        my %lnk_category = sql_line({debug=>0,table=>'data_lnk_sheets_categories',where=>"id_data_sheet='$sheet{id}'"});
        my %category = sql_line({debug=>0,table=>'data_categories',where=>"id='$lnk_category{id_data_category}'"});
        my ($name,$dum) = get_textcontent($dbh,$category{id_textid_name});
        if($name ne '')
        {
            return $name;
        }
    }
  elsif($element eq 'CHILDNAME')
    {
        my %lnk_category = sql_line({debug=>0,table=>'data_lnk_sheets_categories lnk, data_categories c',where=>"lnk.id_data_category = c.id AND c.id_father='$precision' AND id_data_sheet='$sheet{id}'"});
        my %category = sql_line({debug=>0,table=>'data_categories',where=>"id='$lnk_category{id_data_category}'"});
        my ($name,$dum) = get_textcontent($dbh,$category{id_textid_name});
        if($name ne '')
        {
            return $name;
        }
    }
    else
    {
        return "BALISE INCONNUE pour data_get_html_object_category";
    }
}

################################################################################
# data_get_html_object_table
################################################################################
sub data_get_html_object_table
{
    my $dbh = $_[0];
    my %sheet = %{$_[1]};
    my $type = $_[2];
    my $element = $_[3];
    my $precision = $_[4];
    my $lg = $_[5];
    my $id_member_group = $_[6];
    my @discount_rules = @{$_[9]};
    my $generation = $_[10] || 'n';
    my $id_tarif = $_[11];
    my %tarif = %{$_[12]};
	my %sheet_prices = %{$_[13]};
	
    my $valeur="";
   
    if($element eq 'CRITS')
    {
         $valeur = get_crits_table_display($dbh,\%sheet,$id_member_group,\@discount_rules,$generation,$id_tarif,\%tarif,\%sheet_prices);
    }
    elsif($element eq 'COLORS')
    {
         $valeur = data_get_html_object_table_colors($dbh,\%sheet);
    }
    return $valeur;
}

sub get_crits_table_display
{
   my $dbh = $_[0];
   my %sheet = %{$_[1]};
   my $id_member_group = $_[2];
   my @discount_rules = @{$_[3]};
   my $generation = $_[4] || 'n';
   my $id_tarif = $_[5];
   my %tarif = %{$_[6]};
   my %sheet_prices = %{$_[7]};
   
   my $crit1name = '';
   my $crit2name = '';
   
   
   	my @data_stocks = sql_lines({table=>'data_stock',where => "id_data_sheet='$sheet{id}'",ordby => 'id',debug => 0,debug_results => 0});
	$sitetxt{eshop_url_achat} = "/".$sitetxt{eshop_url_achat};
	$sitetxt{eshop_url_achat} =~ s/\/\//\//;
	
my $table =<<"EOH";
<form method="post" action="$sitetxt{eshop_url_achat}" class="buy_form" id="buy_form_$sheet{id}">
      <input type="hidden" name="sw" value="add_cart" />
      <input type="hidden" name="id_data_sheet" class="id_data_sheet" value="$sheet{id}" />
      <input type="hidden" name="lg" class="lg" value="$config{current_language}" />
      <input type="hidden" name="qty" class="qty" value="1" />
			<table class="buy_form_table table table-striped table-hover" id="" >
			<thead>
				<tr>
					<th class="data_stock_crit">$sitetxt{crit_table_label1}</th>
					<th class="data_stock_qty">$sitetxt{crit_table_label2}</th>
					<th class="data_stock">$sitetxt{crit_table_label3}</th>
					<th class="data_stock_reference">$sitetxt{crit_table_label4}</th>
					<th class="data_stock_price">$sitetxt{crit_table_label5}</th>
					<th class="data_stock_totalprice">$sitetxt{crit_table_label6}</th>
				</tr>
			</thead>
			<tbody>
EOH
   
	foreach $data_stock(@data_stocks)
	{
		my %data_stock = %{$data_stock};
		my %data_category = sql_line({table=>'data_categories',where=>"id='$data_stock{id_data_category}'"});
		my %data_category_father = sql_line({table=>'data_categories',where=>"id='$data_category{id_father}'"});
		my %data_stock_tarif = sql_line({debug=>0,debug_results=>0,table=>"data_stock_tarif",select=>"",where=>"id_data_stock = '$data_stock{id}' AND id_tarif = '$tarif{id}'"});
		my %sheet_prices = %{eshop::get_product_prices({from=>'data',debug=>0,generation=>'n',data_sheet=>\%sheet,data_stock_tarif=>\%data_stock_tarif})};

		my $category_name = get_traduction({debug=>0,id_language=>$lg,id=>$data_category{id_textid_name}});		
		my $category_name_father = get_traduction({debug=>0,id_language=>$lg,id=>$data_category_father{id_textid_name}});		
		my $data_stock_price1 = display_price($sheet_prices{price_htva});
		my $data_stock_price2 = $sheet_prices{price_htva};
		my $data_stock_discountprice1 = display_price($sheet_prices{price_discounted_htva});
		my $data_stock_discountprice2 = $sheet_prices{price_discounted_htva};
		if($tarif{is_tvac} eq 'y')
		{
			$data_stock_price1 = display_price($sheet_prices{price_tvac});
			$data_stock_discountprice1 = display_price($sheet_prices{price_discounted_tvac});
			$data_stock_price2 = $sheet_prices{price_tvac};
			$data_stock_discountprice2 = $sheet_prices{price_discounted_tvac};
		}
		my $qty = "1";
		if($config{default_buy_qty} ne '') {
			$qty = $config{default_buy_qty};
		}
		$table .= <<"EOH";
			<tr class="stock_$data_stock{stock}">
				<td class="data_stock_crit">
					<div class="btn-group" data-toggle="buttons">
						<label class="btn btn-default">
							<input type="checkbox" value="$data_stock{id}" name="cb_id_data_stock_$data_stock{id}" id="$data_stock{id}" class="cb_id_data_stock" /> $category_name
						</label>
					</div>
				</td>
				<td class="data_stock_qty">
					<input type="text" name="qty_cb_id_data_stock_$data_stock{id}" id="qty-$data_stock{id}" class="form-control qty-cb_id_data_stock" value="$qty" />
				</td>
				<td class="data_stock"><div>$data_stock{stock}</div></td> 
				<td class="data_stock_reference">$data_stock{reference}</td>
				<td class="data_stock_price" data-price="$data_stock_price2" data-discount-price="$data_stock_discountprice2" data-discount-price-taux="$sheet_prices{discount_taux}"><div>$data_stock_price1</div><div>$data_stock_discountprice1</div></td>
				<td class="data_stock_totalprice"></td>
			</tr>
EOH
     }
	$table .= <<"EOH";
		</tbody>
	</table>
</form>
EOH
  return $table;
}

################################################################################
# data_get_html_object_input
################################################################################
sub data_get_html_object_input
{
    my $dbh = $_[0];
    my %sheet = %{$_[1]};
    my $type = $_[2];
    my $element = $_[3];
    my $precision = $_[4];
    my $lg = $_[5];
    my $func = lc($element);
    
    my $input=<<"EOH";
    <input type="text" class="data_quantity_to_add data_quantity_to_add_$sheet{id} form-control required" id="data_quantity_to_add_$sheet{id}" value="1" />
EOH
    
    return $input;
}


################################################################################
# data_get_html_object_button
################################################################################
# $valeur = data_get_html_object_button($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine,\%data_family,\%member,\%tarif,\%data_setup);
sub data_get_html_object_button
{
    my $dbh = $_[0];
    my %sheet = %{$_[1]};
    my $type = $_[2];
    my $element = $_[3];
    my $precision = $_[4];
    my $lg = $_[5];
    my $id_member_group = $_[6];
    my $extlink = $_[7];
    my $domaine = $_[8];
    my %data_family = %{$_[9]};
    my %member = %{$_[10]};
    my %tarif = %{$_[11]};
    my %data_setup = %{$_[12]};  
    
    my $valeur="";
   
    if($element eq 'BUY' && $tarif{has_no_prices} ne "y")
    {
         $valeur = <<"EOH";          
            <button type="submit" class="btn buy_form_button" id="$sheet{id}"><span>$sitetxt{data_button_buy}</span></button>
EOH
    }
    elsif($element eq 'WISHLIST')
    {
         $valeur = <<"EOH";          
            <button type="button" class="add_wishlist_button" id="$sheet{id}" lg="$lg"><span>$sitetxt{data_button_wishlist}</span></button>
EOH
    }
    # RENDU D'AUTRES BOUTONS SUR-MESURE
    elsif($config{data_additionnal_render_buttons_function} ne "")
    {
    	my $fct = 'def_handmade::'.$config{data_additionnal_render_buttons_function};
    	$valeur = &$fct($dbh,\%sheet,$type,$element,$precision,$lg,$id_member_group,$extlink,$domaine,\%data_family,\%member,\%tarif,\%data_setup);   	
    }
    
    return $valeur;
}

################################################################################
# data_get_html_object_func
################################################################################
sub data_get_html_object_func
{
    my $dbh = $_[0];
    my %sheet = %{$_[1]};
    my $type = $_[2];
    my $element = $_[3];
    my $precision = $_[4];
    my $lg = $_[5];
    my $func = 'def_handmade::'.lc($element);
    
    my $valeur=&$func($dbh,$precision,\%sheet,$lg,\%sws);

    
    
    return $valeur;
}


sub data_get_setup
{
    my %setup = read_table($dbh,"data_setup",1);
    if($setup{id} > 0)
    {
        return \%setup;
    }   
}



sub is_in_array
{
  my $element = $_[0];
  my @array = @{$_[1]};
  foreach $element_in_array (@array)
  {
      if($element_in_array eq $element)
      {
          return 1;
      }
  }
  return 0;
}

sub is_in_array_int
{
  my $element = $_[0];
  my @array = @{$_[1]};

  foreach $element_in_array (@array)
  {
      if($element_in_array == $element)
      {
          return 1;
      }
  }
  return 0;
}

sub get_data_search_form
{
	my $id_data_search_form = $_[0];
	my $lg = $_[1];

	if(!($lg > 0))
	{
		$lg = get_quoted('lg');
	}

	my $id_alt_tpl = $_[2];
	
	#lire le sf
	my %data_search_form = read_table($dbh,"data_search_forms",$id_data_search_form);
    my %data_family = read_table($dbh,"data_families",$data_search_form{id_data_family}); #valeur de famille par defaut du moteur
    
	my $id_tpl = $data_search_form{id_template};
	if($id_alt_tpl > 0)
	{
		$id_tpl = $id_alt_tpl;
	}
	
	my $tpl_form = migcrender::get_template($dbh,$id_tpl,$lg);
	my $s_default_params = get_quoted('page');

	my $annuaire_url = get_data_url({sf=>$data_search_form{id},number_page=>1, lg=>$lg});

	#rendu tpl du form
	my $balise='<MIGC_DATA_SEARCH_FORM_BEGIN_HERE>';
    my $to = <<"EOH";
    <form method="POST" id="data_search_form_$id_data_search_form" class="data_search_form" action="$annuaire_url">
		<input type="hidden" name="annuaire_url" value="$annuaire_url" class="annuaire_url" />
		<input type="hidden" name="lg" value="$lg" class="data_search_lg" />
		<input type="hidden" name="sw" value="list" class="data_search_sw" />
		<input type="hidden" name="extlink" value="$extlink" class="data_extlink" />     
		<input type="hidden" name="sf" value="$data_search_form{id}" class="id_data_search_form" />
		<input type="hidden" name="tri" value="$tri" class="id_data_tri" />
		<input type="hidden" name="id_data_family" value="$data_family{id}" class="" />
		<input type="hidden" name="s_default_params" value="$s_default_params" class="" />
EOH

	foreach my $numero (1 .. 10)
	{
		my $valeur_numero = get_quoted('s'.$numero) || get_quoted('keyword_s'.$numero) || get_quoted('s_default_'.$numero);
		$to .= <<"EOH";
			<input type="hidden" name="s_default_$numero" value="$valeur_numero" class="" />
EOH
	}

    $tpl_form =~ s/$balise/$to/g;
	$balise='<MIGC_DATA_SEARCH_SUBMIT_HERE>';
    $to=<<"EOH";
    <button type="submit">$sitetxt{data_search_form_button_submit}</button>
EOH
    $tpl_form =~ s/$balise/$to/g;
    

    $balise='<MIGC_DATA_SEARCH_FORM_END_HERE>';
    $to=<<"EOH";
    </form>
    
EOH
    $tpl_form =~ s/$balise/$to/g;
	
	#boucler sur les champs du sf{id_data_family}
	my @data_searchs = sql_lines({table=>"data_searchs",ordby=>"ordby",where=>"id_data_search_form = '$data_search_form{id}' AND visible='y'",debug=>0});
	foreach $search(@data_searchs)
    {
        my %search = %{$search};
		 my $label = get_traduction({debug=>0,id_language=>$lg,id=>$search{id_textid_name}});
		 my $field = 'CHAMPS '.$search{type};

		 #récupérer les noms, nombres et urls des catégories si list_checkbox, list_links, listbox, tree_links
		 if($search{type} eq 'tree_links')
		 {
			  $field = get_categories_menu({reset=>$search{reset},id_father_category=>$search{id_father_cat},search=>\%search,sf=>\%data_search_form,extlink=>$extlink,data_family=>\%data_family});
		 }
		 elsif($search{type} eq 'input')
		 {
			  my $keyword = '';
			  if($data_search_form{id} == get_quoted('sf'))
			  {
				$keyword = get_quoted('keyword_s'.$search{ordby});
			  }
			  $field = <<"EOH";
			  <input type="text" name="keyword_s$search{ordby}" class="form-control" value="$keyword" />
EOH
		 }
		 elsif($search{type} eq 'listbox')
		 {
			  	$field = <<"EOH";
					  <select name="s$search{ordby}" class="form-control">
					  <option value="">$sitetxt{all_label}</option>
EOH
				my @data_categories = sql_lines({table=>'data_categories',where=>"id_father = '$search{id_father_cat}' AND visible='y'",ordby=>'ordby'});
				foreach $data_category (@data_categories)
				{
					my %data_category = %{$data_category};
					my $titre_cat = get_traduction({id=>$data_category{id_textid_name},lg=>$config{current_language}});
					my $selected = '';
					if($data_category{id} == get_quoted('s'.$search{ordby}) && $data_search_form{id} == get_quoted('sf'))
					{
						$selected = ' selected ';
					}

					my $nb = '';
					if($data_search_form{count_sheets} eq 'y')
					{
						my ($list_sheets,$nb_total_resultats) = compute_sheets({nb_total_seulement=>'y',force_id_data_category=>$data_category{id},data_setup=>\%data_setup,data_family=>\%data_family,tarif=>\%tarif,current_page=>1,tri=>$tri,nr=>$data_family{family_nr},lg=>$config{current_language}});
						$nb = $nb_total_resultats;
						if(!($nb > 0))
						{
							next;
						}
					}	
					
					#lien url rewriting si besoin (pas nécessaire jusqu'à maintenant donc convenu avec alain de le mettre en place quand ça sera utile)
					# my $link = $config{baseurl}."/".data::get_data_url({params=>'',reset=>$d{reset},sf=>$data_search_form{id},number_page=>1,id_father_categorie=>$data_category{id},nr=>$data_family{family_nr},from=>'recurse_categories_menu'});
					# $link =~ s/\/\//\//g;
					
					 # /$data_search_form{count_sheets}/ ($nb) [$link]
					$field .= <<"EOH";
					<option $selected value="$data_category{id}">$titre_cat</option>
EOH
				}
				
				$field .= <<"EOH";
					  </select>
EOH
		 }
		 
		 #rendu html du champs selon type
         
         $balise='<MIGC_DATA_SEARCH_LABEL_'.$search{ordby}.'_HERE>';
         $tpl_form =~ s/$balise/$label/g;
         $balise='<MIGC_DATA_SEARCH_FIELD_'.$search{ordby}.'_HERE>';
         $tpl_form =~ s/$balise/$field/g;
		 
		 
		 
		 $_ = $tpl_form; 
		my $reg = '<MIGC_DATA_SEARCH_FUNC_'.$search{ordby}.'_\[(.+)\]_HERE>';
		my @funcs = (/$reg/g);
		for (my $i = 0; $i<=$#funcs; $i++ ) 
		{		
			my $func_result = '';
			if($funcs[$i] ne '')
			{
				$func = 'def_handmade::'.$funcs[$i];
				$func_result=&$func();
			}
			$tag = '<MIGC_DATA_SEARCH_FUNC_'.$search{ordby}.'_\['.$funcs[$i].'\]_HERE>';
			$tpl_form =~ s/$tag/$func_result/g;
		}
	}
	
	$_ = $tpl_form;
	
	my $i;
	my @funcs = (/<MIGC_DATA_FUNC_(\w+)_HERE>/g);
	for ($i = 0; $i<=$#funcs; $i++ ) 
	{
		if($funcs[$i] ne '')
		{
			my $func = 'def_handmade::'.lc($funcs[$i]);
			$balise='<MIGC_DATA_FUNC_'.$funcs[$i].'_HERE>';
			$to = &$func();
			$tpl_form =~ s/$balise/$to/g;
		}
	} 
	
	return $tpl_form;
}

sub get_categories_menu
{
	my %d = %{$_[0]};
	my %search = %{$d{search}};
	my %sf = %{$d{sf}};
	my %data_family = %{$d{data_family}};
	my $force_s1_value = $d{force_s1_value};

	my $menu = recurse_categories_menu({id_father_category=>$d{id_father_category},level=>1,sf=>\%sf,search=>\%search,extlink=>$d{extlink},data_family=>\%data_family,reset=>$d{reset}, force_s1_value=>$force_s1_value}); 
    return $menu;
}

sub recurse_categories_menu
{
	my %d = %{$_[0]};
	my %search = %{$d{search}};
	my %sf = %{$d{sf}};
	my %data_family = %{$d{data_family}};
	my $force_s1_value = $d{force_s1_value};

	 
	if($lg>0 && $lg <=10)
	{
	}
	else
	{
		$lg = 1;
	}
	
	my $menu = '';
	my $submenu = '';	
	
	my $id_valeur_unique = 0;
	
	my @params_unsorted = ();
	foreach my $num_param (1 .. 10)
	{
		my $param = get_quoted('s'.$num_param);
		if ($param !~ /^\d+$/) {next;}
		
		#si parent du paramètre recu == parent du menu affiché, pas la peine de calculer le reste
		if($rew_fathers_cats{$param} == $d{id_father_category} && $d{id_father_category} > 0)
		{
			$id_valeur_unique = $param;
		}
		push @params_unsorted, $param;
	}
	my $custom_where = "";
	if($config{data_where_supp_func} ne '')
	{
		log_debug('$config{data_where_supp_func}:'.$config{data_where_supp_func},'','compute_sheets');
		my $where_func = 'def_handmade::'.$config{data_where_supp_func};
		$custom_where = &$where_func({id_data_family=>$data_family{id}});
	}	
	
	my $where_cat = "c.id_textid_name = txt.id AND c.visible='y' AND c.id_father='$d{id_father_category}' AND c.id_data_family='$data_family{id}'";
	if($id_valeur_unique > 0)
	{
		$where_cat = " c.id='$id_valeur_unique' AND c.id_textid_name = txt.id AND c.visible='y' ";
	}
	
	my @categories = sql_lines({select=>"lg$lg as titre, c.id, lg1 as default_trad",debug=>0,debug_results=>0,table=>'data_categories c,txtcontents txt',where=>"$where_cat",ordby=>"titre"});
	# my $zero_lines = 1;
	
	foreach $categorie_ref (@categories)
	{
		my %categorie=%{$categorie_ref};
		my $title = $categorie{titre};
		if($title eq '')
		{
			$title = $categorie{default_trad};
		}
		
		my $nb = '';
		my %one_sheet_fits = ();
		
		if($sf{count_sheets} eq 'y')
		{
			#parametres de base
			my @params_for_this_cat = @params_unsorted;
			
			#ajouter catégorie à prendre en compte
			push @params_for_this_cat, $categorie{id};
			
			#construction du where
			my @where_for_this_cat = ();
			foreach my $param (@params_for_this_cat)
			{
				if($param > 0)
				{
					push @where_for_this_cat," id_data_categories LIKE '%,$param,%' ";
				}
			}
			push @where_for_this_cat," visible='y' ";
			if($custom_where ne '')
			{
				push @where_for_this_cat, " $custom_where ";
			}
			my $where_one_sheet_fits = join(' AND ', @where_for_this_cat);
			
			%one_sheet_fits = sql_line({debug=>0,debug_results=>0,select=>"id",table=>'data_sheets sh',where=>$where_one_sheet_fits,limit=>"0,1"});
			
			if(!($one_sheet_fits{id} > 0))
			{
				# $zero_lines = 0;
				next;
			}
		}	
		else
		{
			# $zero_lines = 0;
		}		

        my $has_children = 'n';
        #s'il faut crééer les liens vers le listing catégories enfants et si la catégorie a des enfants
        if($config{data_auto_menu_has_children} eq 'y' && $rew_children_cats{$categorie{id}} > 0)
        {
            $has_children = 'y';
        }

#        print <<"EOH";
#        my $link = $config{baseurl}."/".data::get_data_url({has_children=>$has_children,lg=>$config{current_language},params=>'',reset=>$d{reset},sf=>$sf{id},number_page=>1,id_father_categorie=>$categorie{id},nr=>$data_family{family_nr},from=>'recurse_categories_menu', force_s1_value=>$force_s1_value});
#        <br>
#EOH

        my $link = $config{baseurl}."/".data::get_data_url({has_children=>$has_children,lg=>$config{current_language},params=>'',reset=>$d{reset},sf=>$sf{id},number_page=>1,id_father_categorie=>$categorie{id},nr=>$data_family{family_nr},from=>'recurse_categories_menu', force_s1_value=>$force_s1_value});
		$link =~ s/\/\//\//g;
		
		my $migc_selitem = '';
		foreach my $num_param (1 .. 10)
		{
			my $param = get_quoted('s'.$num_param);
			if ($param !~ /^\d+$/) {next;}
			if($param == $categorie{id})
			{
				$migc_selitem = ' selitem migc_selitem ';
			}
		}
		# if($sf{count_sheets} eq 'y' && $nb < 1)
		# {
			# next;
		# }
		 $submenu .= <<"EOH";     
            <li id="menuid_$categorie{id}" class="menuid_$categorie{id} level_$d{level} nb_resultats_$nb">
              <a class="$migc_selitem link_level_$d{level}"  href="$link" name="$categorie{id}" data-lg="$config{current_language}">
                  <span>
                      $title
                  </span>
				  <!--
                  <span class="filter_nb_result filter_nb_result_$categorie{id}">
                      ($nb)
                  </span>
				  -->
               </a>  
EOH
		$submenu.= recurse_categories_menu({id_father_category=>$categorie{id},level=>($d{level} + 1),sf=>\%sf,search=>\%search,extlink=>$d{extlink},data_family=>\%data_family,reset=>$d{reset}});
		$submenu.= '</li>';
	}

	
	if($submenu ne "")
	{
		my $all_label = get_traduction({id=>$search{id_textid_all_label}, id_language=>$lg});
		my $all_link = "";
		
		if($all_label ne '')
		{
		my $all_selected_value;
		if($selected_value eq "")
		{
		  $all_selected_value = "data_search_field_s$search{ordby}_li_selitem selitem migc_selitem";
		}

		my $link = $config{baseurl}."/".data::get_data_url({lg=>$config{current_language},params=>'',reset=>$id_valeur_unique,sf=>$sf{id},number_page=>1,nr=>$data_family{family_nr},from=>'recurse_categories_menu'});
		$link =~ s/\/\//\//g;
		$all_link =<<"EOH";
		  <li id="menuid_all" class="menuid_all">
	        <a class="$migc_selitem tous"  href="$link" data-lg="$config{current_language}">
	            <span>
	                $all_label
	            </span>
	         </a>
	    </li>
EOH
		}
		
		# my $class_ul = "";
		# if($zero_lines == 1)
		# {
		 # $class_ul="hide";
		# }

		$menu = <<"EOH";
			<ul id="submenuid_$d{id_father_category} " class="$cfg{submenu_custom_classes} submenuid_$d{id_father_category}">
				$all_link
				$submenu
			</ul>
EOH
	}
	
	return $menu;
}

sub migcms_build_data_searchs_keyword
{
	my %d = %{$_[0]};
	if($d{reset} eq 'y')
	{
		execstmt($dbh,'TRUNCATE data_searchs_keyword');	
	}
	execstmt($dbh,'DELETE FROM `data_searchs_keyword` WHERE id_data_sheet NOT IN (select id from data_sheets)');

	
	my $where_datas_sheet = '';
	if($d{id_data_sheet} > 0)
	{
		$where_datas_sheet .= " AND id = '$d{id_data_sheet}' ";
	}

	see();
	my @data_sheets = sql_lines({table=>'data_sheets',where=>"visible='y' $where_datas_sheet"});
	my @data_searchs = sql_lines({table=>'data_searchs',where=>"type='input' AND cols != ''"});
	my @data_fields = sql_lines({table=>'data_fields'});
	my @migcms_languages = sql_lines({table=>'migcms_languages',where=>"visible='y'"});
	
	foreach $migcms_language (@migcms_languages)
	{
		my %migcms_language = %{$migcms_language};
		
		foreach $data_sheet (@data_sheets)
		{
			my %data_sheet = %{$data_sheet};
			
			foreach $data_search (@data_searchs)
			{
				my %data_search = %{$data_search};
				
				my $content = '';
				
				 my @colonnes = split('\,',$data_search{cols});
				 foreach my $id_data_field(@colonnes)
				 {
					if($id_data_field > 0)
					{
						my %data_field = ();
						foreach $find_data_field (@data_fields)
						{
							my %find_data_field = %{$find_data_field};
							if($find_data_field{id} == $id_data_field)
							{
								%data_field = %find_data_field;
							}
						}	
						if($data_field{field_type} eq 'text' || $data_field{field_type} eq 'textarea' || $data_field{field_type} eq 'textarea_editor')
						{
							$content .= ' '.$data_sheet{'f'.$data_field{ordby}};
						}
						elsif($data_field{field_type} eq 'text_id' || $data_field{field_type} eq 'textarea_id' || $data_field{field_type} eq 'textarea_id_editor')
						{
							my $traduction = get_traduction({debug=>0,id_language=>$migcms_language{id},id=>$data_sheet{'f'.$data_field{ordby}}});
							$content .= ' '.$traduction;
						}
					}
				 }
				
				 my %new_data_searchs_keyword =
				 (
					id_data_sheet => $data_sheet{id},
					id_data_search => $data_search{id},
					id_data_search_form => $data_search{id_data_search_form},
					field => 'keyword_s'.$data_search{ordby},
					cols => $data_search{cols},
					content => $content,
					id_language => $migcms_language{id},
				 );
				 %new_data_searchs_keyword = %{quoteh(\%new_data_searchs_keyword)};
				 sql_set_data({dbh=>$dbh,debug=>0,debug_results=>$dm_cfg{list_debug},table=>'data_searchs_keyword',data=>\%new_data_searchs_keyword, where=>"id_data_sheet='$new_data_searchs_keyword{id_data_sheet}' AND id_data_search='$new_data_searchs_keyword{id_data_search}' AND id_language='$new_data_searchs_keyword{id_language}' AND id_data_search_form='$new_data_searchs_keyword{id_data_search_form}' AND field='$new_data_searchs_keyword{field}'"});
			}
		}
	}
}

sub recompute_sheets_id_data_categories
{
		my %d = %{$_[0]};
		
		my $where = "";
		if($d{id_data_sheet} > 0)
		{
				$where = " id = '$d{id_data_sheet}' ";
		}
		
		my @data_sheets = sql_lines({table=>'data_sheets',where => $where});
		foreach $data_sheet(@data_sheets)
		{
				my %data_sheet = %{$data_sheet};
				my $id_data_categories = ',';
				
				my @data_lnk_sheets_categories = sql_lines({table=>'data_lnk_sheets_categories',where=>"id_data_sheet='$data_sheet{id}'"});
				foreach $data_lnk_sheets_categorie (@data_lnk_sheets_categories)
				{
						my %data_lnk_sheets_categorie = %{$data_lnk_sheets_categorie};
						$id_data_categories .= $data_lnk_sheets_categorie{id_data_category}.',';
				}
				
				execstmt($dbh,"UPDATE data_sheets SET id_data_categories='$id_data_categories' WHERE id = '$data_sheet{id}'");	
		}
}

sub recompute_data_categories_has_data_sheets_linked
{
		see();
		
		my %data_cats = ();
		my @data_sheets = sql_lines({select=>"id,id_data_categories",table=>'data_sheets',where => "id_data_categories != ''"});
		foreach $data_sheet(@data_sheets)
		{
				my %data_sheet = %{$data_sheet};
				my @id_data_categories = split('\,',$data_sheet{id_data_categories});
				foreach my $id_data_cat (@id_data_categories)
				{
					if($id_data_cat > 0)
					{
						$data_cats{$id_data_cat} = 1;
					}
				}
		}
		
		execstmt($dbh,"UPDATE data_categories SET has_data_sheets_linked = 0");	
		
		foreach my $id_cat (keys %data_cats)
		{
			if($id_cat > 0)
			{
				execstmt($dbh,"UPDATE data_categories SET has_data_sheets_linked = 1 WHERE id = '$id_cat'")
			}	
		}		
		exit;
}



1;