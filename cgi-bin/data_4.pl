#!/usr/bin/perl -I../lib 
#                  -d:NYTProf
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use Crypt::OpenSSL::RSA;
use migcrender;
# use Data::Dumper;
use data; 
use sitetxt;
use JSON::XS;
use members;
use def_handmade;
# STDOUT->autoflush(1);absz
# use Devel::NYTProf;

if ($config{urlrewriting} eq "y" ) 
{
    decode_rewrite_params();
}

#utiliser le système de cache page complète pour l'annuaire
if($config{data_cache_pages_urls} eq 'y')
{
	if($config{data_cache_pages_urls_nb_min_cache} > 0)
	{
		$stmt = "delete FROM `data_cache_pages_urls` WHERE moment < DATE_SUB(NOW(), INTERVAL $config{data_cache_pages_urls_nb_min_cache} MINUTE)";
		 execstmt($dbh,$stmt);
	}
	my $check_url = $config{rewrite_protocol}.'://'.$ENV{SERVER_NAME}.$ENV{REDIRECT_URL};
    my %check_cache = sql_line({debug=>0,debug_results=>0,table=>'data_cache_pages_urls',where=>"url='$check_url'"});
    if($check_cache{url} ne '' && $check_cache{cache_html} ne '')
    {
        see();
        my $html =  $check_cache{cache_html};
        print $html;
        exit;
    }
} 

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

my $lg=$config{current_language} = get_quoted('lg') || $config{default_language};
if($lg ne '')
{
	if ($lg !~ /^\d+$/) {exit;}
}
my %check_language = read_table($dbh,"migcms_languages",$config{current_language});
if($check_language{visible} ne 'y')
{
    $config{current_language} = $lg = 1;
}

%sitetxt = %{get_sitetxt($dbh,$config{current_language})};
%cfg = get_hash_from_config($dbh,'data_cfg');

fb_timeout();

$extlink = get_quoted('extlink') || $cfg{extlink};
$cgi->param(extlink,$extlink); 

my $sw = get_quoted('sw') || "list";
my $id_data_family = get_quoted('id_data_family') || $cfg{default_family} || 1;
if ($config{current_language} eq "") {$config{current_language} = $config{default_language};}
if ($id_data_family !~ /^\d+$/) {exit;}

my $self = "cgi-bin/data.pl?&lg=$config{current_language}&extlink=$extlink&id_data_family=$id_data_family";
my @fcts = qw(
		  list
		  detail
		  lightbox_video
		  ajax_autocomplete_search
		);

if(is_in(@fcts,$sw)) 
{ 
    &$sw();
}

################################################################################
#LIST
################################################################################
sub list
{
     my %data_setup = %{data_get_setup()};
	 
	 my $id_tarif = get_id_tarif_member();
     my %tarif = read_table($dbh,"eshop_tarifs",$id_tarif);
     my $id_template_page = 0;
     
     #GET SEARCH FORM
     my $sf = get_quoted('sf') || 0;

     my %data_family = read_table($dbh,"data_families",$id_data_family); 
	
	#utiliser plutot le contenu d'une autre famille
	 my %alt_data_family = sql_line({table=>'data_families',where=>"id='$data_family{id_alt_data_family}'"}); 
	 
     $id_template_page = $data_family{id_template_page};
     my $current_page = get_quoted('page') || 1;
     my $nr = get_quoted('nr') || $cfg{nr};
     my $sens = get_quoted('s') || 'a';
     my $number = (($current_page-1)*$nr)+1;
     
     if(0 && $data_setup{do_suivant_precedent} eq 'y')
     {
         #SAVE CACHE (précédent/suivant) + set cookie
         my %data_search_cache = ();
         foreach $number (1 .. 15)
         {
             $data_search_cache{'s'.$number} = get_quoted('s'.$number);
         }
         $data_search_cache{result} = join(',', @list_sheets);
         $data_search_cache{sf} = $sf;
         $data_search_cache{date} = 'NOW()';
         my $id_cache = inserth_db($dbh,"data_search_cache",\%data_search_cache);
         my $cookie_cache = $cgi->cookie('data_search_cache');
		 
		 $stmt = "DELETE FROM data_search_cache WHERE date < DATE(NOW())";
		 execstmt($dbh,$stmt);
     
         my %hash_cache = ();
         $hash_cache{id} = $id_cache;
         my $cache_utf8_encoded_json_text = encode_json(\%hash_cache);
         my $cook_cache = $cgi->cookie(-name=>'data_search_cache',-value=>$cache_utf8_encoded_json_text,-path=>'/');
         print $cgi->header(-cookie=>$cook_cache,-charset => 'utf-8');
     }
     else
     {
        see();
     }
	
     ($nb_resultats,@list_sheets) = compute_sheets($dbh,$sf,$config{current_language},'','',\%data_family,'list','',$current_page,$nr,$sens,$number,\%alt_data_family);

     if($sf > 0)
     {
          my %search_form = read_table($dbh,"data_search_forms",$sf);
          $id_template_page = $search_form{id_template_page} || $data_family{id_template_page};

          if($search_form{order_on} > 0 || $search_form{order_field} > 0 || $search_form{custom_ordby} ne '')
          {
              #tri par catégorie (tableau deja trié)
          }
          else
          {
#               @list_sheets = reverse sort { $a <=> $b } @list_sheets;
          }
      }
      else
      {
#           @list_sheets = reverse sort { $a <=> $b } @list_sheets;
      }
   
   
   
    #filtrer les ids avec nombre de résultats par page, page actuelle, nombre de résultats au total
    
    
    my ($list_sheets_to_display,$pagination,$end_page,$last_page) = get_pagination(\@list_sheets,$current_page,$nr,$sf,$nb_resultats,\%data_setup);
    my @list_sheets_to_display = @{$list_sheets_to_display};
	# print join("\n",@list_sheets_to_display),"\n";
	
    # print Dumper \@list_sheets_to_display;
# exit;


    my $list="";

    
    foreach $id_sheet (@list_sheets_to_display)
    {
        my $name = $type.'_'.$id_data_sheet.'_'.$lg.'_'.$data_family{id_template_detail}.'_'.$tarif{id}.'.'.$config{cache_ext};;
		my $type = 'object';
        my $object = '';
        my $url_object = $config{dir_cache_object}.'/'.$name;
		
        if(! -e $url_object)
        {
            my %sheet = read_table($dbh,"data_sheets",$id_sheet);
			my $template = get_template({id=>$data_family{id_template_object},lg=>$config{current_language}});
			$object = data_write_tiles_optimized($dbh,\%sheet,\%data_family,$data_family{id_template_object},$template,$lg,0,'object',$extlink,'',undef,undef,'n',\%data_setup,\%tarif);
        }
        else
        {
             $object = get_file($url_object);
        }
       
        $object =~ s/MIGC_DATA_LIST_ORDBY_HERE/$number/g; 
        $list .= $object;
        $number++;
    }
    
	if($#list_sheets_to_display == -1)
	{
		$list = <<"EOH";
<div class="alert alert-info" role="alert">
      $sitetxt{data_no_results}
    </div>
EOH
	}
	
    my $tpl = migcrender::get_template($dbh,$data_family{id_template_listing},$config{current_language});
	
    $list = map_list_listing($tpl,$pagination,$list,$end_page,$last_page);
    
    $list .=<<"EOH";
        <input type="hidden" name="id_data_search_form_selected"  id="id_data_search_form_selected" value="$sf" />
        <input type="hidden" name="id_data_search_form_selected"  id="val_infosupp1" value="$member{infosupp1}" />
        <input type="hidden" name="id_data_search_form_selected"  id="val_infosupp2" value="$member{infosupp2}" />
EOH
    
	#exectute les fonctions sur mesure dans le template listing
    $_ = $list;
	my @fonctions = (/<MIGC_DATA_FUNC_(\w+)_HERE>/g);
	for ($i_fonction = 0; $i_fonction<$#fonctions+1; $i_fonction++ ) 
	{
		my $balise_a_remplacer = '<MIGC_DATA_FUNC_'.uc($fonctions[$i_fonction]).'_HERE>';
		# print $balise_a_remplacer;
		
		my $fonction = lc($fonctions[$i_fonction]);
		my $func = 'def_handmade::'.lc($fonction);
		my $valeur=&$func();
		
		$list =~ s/$balise_a_remplacer/$valeur/g;
		# print $list;
		# exit;
	}
	display($list,$id_template_page);
}

################################################################################
#DETAIL
################################################################################
sub detail
{
    my $id_data_sheet = get_quoted('id_data_sheet') || 0;
    if ($id_data_sheet !~ /^\d+$/) {exit;}
    my $id_data_family = get_quoted('id_data_family') || $cfg{default_family} || 1;
    my %data_family=read_table($dbh,"data_families",$id_data_family);
    my %data_sheet=read_table($dbh,"data_sheets",$id_data_sheet);
    my %data_setup = %{data_get_setup()};
    my $id_tarif = get_id_tarif_member();
    my %tarif = read_table($dbh,"eshop_tarifs",$id_tarif);
        
    if($data_sheet{visible} eq 'n' || $id_data_sheet == 0 || !($data_sheet{id} > 0) )
    {
        migcrender::error_404();
    }
    else
    {
          if($config{version_num} >= 3620)
          {
              my $type = 'detail';
              $name = $type.'_'.$id_data_sheet.'_'.$lg.'_'.$data_family{id_template_detail}.'_'.$id_tarif.'.'.$config{cache_ext};
          }
          else
          {
              $name=$id_data_family.'_'.$id_data_sheet.'_'.$lg.'_'.$data_family{id_template_detail}.'.'.$config{cache_ext};
              if($cfg{multiple_prices} eq 'y')
              {
                  my $id_member_group = 1;
                  my $id_member = get_id_member();
                  if($id_member > 0)
                  {
                     %member = read_table($dbh,"members",$id_member);
                     $id_member_group = $member{id_group};
                     $name=$id_data_family.'_'.$id_data_sheet.'_'.$lg.'_'.$data_family{id_template_detail}.'_'.$id_member_group.'.'.$config{cache_ext};
                  }
              }
          }
                    
          my $template_page = $data_family{id_template_detail_page} || $data_family{id_template_page};
          
          my $data_history = '';
          if($config{data_history} eq 'y' && $id_data_family == 1)
          {
               my $cook_data_history = $cgi->cookie('data_history');
               my %hash_dc = ();
               my %check = ();
               if($cook_data_history ne "")
               {
                       $cook_data_history_ref=decode_json $cook_data_history;
                       %hash_dc=%{$cook_data_history_ref};
               }
               my @old_history = split(/,/,$hash_dc{history});
               my @new_history = ();
               push @new_history, $data_sheet{id};
               my $i = 1;
               my $template_object = migcrender::get_template($dbh,$data_family{id_template_object},$lg);
               
#                @reversedNames = reverse(@old_history);
               @reversedNames = @old_history; 
               foreach my $old_hist (@reversedNames)
               {
                  if($old_hist > 0 && $i <= 5)
                  {
                      if($check{$old_hist} > 0)
                      {
                      
                      }
                      else
                      {
                          $check{$old_hist} = 1;
                          push @new_history, $old_hist;
                          my %data_sheet = read_table($dbh,'data_sheets',$old_hist);
                          $data_history .= data_write_tiles_optimized($dbh,\%data_sheet,\%data_family,$data_family{id_template_object},$template_object,$lg,0,'object',$extlink,'','','','',\%data_setup,\%tarif);
                      }
                  }
                  $i++;
               }        
               
#                my %data_sheet = read_table($dbh,'data_sheets',$id_data_sheet);
#                $data_history .= data_write_tiles_optimized($dbh,\%data_sheet,\%data_family,$data_family{id_template_object},$template_object,$lg,0,'object',$extlink,'','','','',\%data_setup,\%tarif);
               
               
               
                
               my $neo_history = join(',', @new_history);
               $hash_dc{history} = $neo_history;
               
               $order_utf8_encoded_json_text = encode_json \%hash_dc;
               my $cookie = $cgi->cookie(-name=>'data_history',-value=>$order_utf8_encoded_json_text,-path=>'/');
               
               print $cgi->header(-cookie=>[$cookie],-charset => 'utf-8');
          }
          else
          {
              see();
          }  
          
       
          
          if(-e $config{dir_cache_detail}.'/'.$name)
          {
              my $detail=get_file($config{dir_cache_detail}.'/'.$name);
              display($detail,$template_page,$data_history);
          }
          else
          {
         
              my $template = migcrender::get_template($dbh,$data_family{id_template_detail},$lg);
         
			  $detail = data_write_tiles_optimized($dbh,\%data_sheet,\%data_family,$data_family{id_template_detail},$template,$lg,0,'detail',$extlink,'','','','',\%data_setup,\%tarif);
              display($detail,$template_page,$data_history);
          }
    }
}

#*******************************************************************************
#LIGHTBOX VIDEO*****************************************************************
sub lightbox_video
{
    my $url=get_quoted('url');
    my %data_cfg=get_hash_from_config($dbh,'data_cfg');
    my $template = get_template($dbh,$cfg{lightbox_video_tpl});
    $url = "$htaccess_protocol_rewrite://".$config{rewrite_default_url}.'/'.$url;
     
    $template =~ s/<MIGC_LIGHTBOX_VIDEO_FILE_URL>/$url/g;

    see();
    print $template;
}



################################################################################
#DISPLAY
################################################################################
sub display
{
  my $content = $_[0];

  $content .=<<"EOH";
   <input type="hidden" name="script" id="script" value="$config{eshop_script}" />
EOH
  
  my $id_template_page = $_[1];
  my $data_history = $_[2];
  
  # my $template_page=migcrender::get_template($dbh,,$config{current_language},"","html");
  
#   if($sw eq 'detail')
#   {
#       my $id_data_sheet = get_quoted('id_data_sheet') || 0;
#       my $from = '<MIGC_DATA_OG_IMAGE_HERE>';
#       my %sheet = read_table($dbh,"data_sheets",$id_data_sheet);
#       my %pic=select_table($dbh,"data_lnk_sheet_pics lnk, pics p","","id_data_sheet='$id_data_sheet' AND id_pic=p.id AND lnk.visible='y' order by lnk.ordby asc limit 0,1",'','',0);
#       my $to = data::data_get_html_object_pic_content(\%pic,'OGURL',\%sheet,'',$lg,'','y');
#       $template_page =~ s/$from/$to/g;
#   }
 

  my $page_content = render_page({debug=>0,content=>$content,id_tpl_page=>$id_template_page,extlink=>$extlink,lg=>$config{current_language}});

  my $logged = get_login_status();
 
 
  my %language=read_table($dbh,"migcms_languages",$config{current_language});
  $page_content =~ s/<MIGC_LANGUAGE_CODE_HERE>/$language{name}/g;		
  
  my $tag = '<MIGC_DATA_HISTORY_HERE>';
  $page_content =~ s/$tag/$data_history/g;   
  
   my $check_url = $config{rewrite_protocol}.'://'.$ENV{SERVER_NAME}.$ENV{REDIRECT_URL};
   
   print $page_content;
   
   if($config{data_cache_pages_urls} eq 'y')
	{
		$page_content =~ s/\'/\\\'/g;
		if($check_url ne $config{rewrite_protocol}."://".$config{rewrite_subdns}.$config{rewrite_dns})
		{
			my %data_cache_pages_urls = (
				url => $check_url,
				cache_html => $page_content,   
				moment => 'NOW()',
			);
			sql_set_data({debug=>0,dbh=>$dbh,table=>'data_cache_pages_urls',data=>\%data_cache_pages_urls,where=>"url = '$check_url'"});
		}
  }
}  

sub ajax_autocomplete_search
{
	see();
	my $query = get_quoted('query');
	my $json = '['.get_file('../autocomplete.json').']';
	my $arrayref = decode_json $json;
	my @json_array = @{$arrayref};
	my @result_json = ();
	if($query ne '')
	{
		foreach $json_line (@json_array)
		{
			my %json_line = %{$json_line};

			#espaces et casse
			if($json_line{name} =~ m/$query/i)
			{
				push @tab_json, <<"EOH";
				{
						"name": "$json_line{name}",
						"url": "$json_line{url}",
						"nb": "$json_line{nb}"
				}
EOH
			}
		}
	}
		
	my $json_lines = join(", ",@tab_json);
	my $json = <<"EOH";
[
	$json_lines
]
EOH

	print $json;
	exit;
}