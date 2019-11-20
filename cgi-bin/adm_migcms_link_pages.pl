#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
         # migc translations
use members;
$dbh_data = $dbh;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
$dm_cfg{visibility} = 0;
$dm_cfg{sort} = 0;
$dm_cfg{add} = 0;
$dm_cfg{modification} = 0;
$dm_cfg{delete} = 0;
$dm_cfg{tree} = 1;

$dm_cfg{enable_search} = 0;
$dm_cfg{wherep} = 'migcms_pages_type!="newsletter" AND migcms_pages_type != "block" AND migcms_pages_type != "handmade"';
$dm_cfg{table_name} = "migcms_pages";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{default_ordby} = "ordby";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_link_pages.pl?";
if($config{current_language} eq "")
{
   $config{current_language}=get_quoted('lg') || 1;
}
$dm_cfg{line_func} = 'custom_tree_levels';  

$dm_cfg{hiddp}=<<"EOH";

EOH


%types = (
			"page"=>"Page",
			"link"=>"Lien",
      "directory"=>"Dossier"
		);
    
%dm_nav =
(
    '01/header_page'=>
    {
        'type'=>'header',
        'title'=>'Page'
    }
    ,
    '02/page'=>
    {
        'type'=>'tab',
        'icon'=>'icon-info-2',
        'title'=>'Page'
    }
    ,
    '04/referencement'=>
    {
        'type'=>'tab',
        'icon'=>'icon-drawer-2',
        'title'=>'Référencement'
    }
);
        

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    
      '01/id_textid_name'=> 
      {
	        'title'=>'Titre',
	        'fieldtype'=>'text_id',
	        'search' => 'y',
          'tab'    => 'page'
	    }
      ,
      '03/migcms_pages_type'=> 
      {
          'title'=>"Type d'élément",
          'fieldtype'=>'listbox',
          'fieldvalues'=>\%types,
          'tab'    => 'page'
      }
      
      ,
	    '05/id_tpl_page' => 
      {
           'title'=>'Canevas de la page',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'templates',
           'lbkey'=>'id',
           'lbdisplay'=>'name',
           'lbwhere'=>"type = 'page'" ,
          'tab'    => 'page'
      }
      ,
	    '07/id_father' => 
      {
           'title'=>'Menu parent',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'migcms_pages',
           'lbkey'=>'id',
           'lbdisplay'=>'id_textid_name',
           'translate'=>1,
           'lbwhere'=>"migcms_pages_type = 'directory'",
          'tab'    => 'page'
      }
      ,
      '09/id_migcms_link' => 
      {
           'title'=>'Lien vers un module',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'migcms_links',
           'lbkey'=>'id',
           'lbdisplay'=>'link_name',
           'lbwhere'=>"",
           'tab'    => 'page'
      }
      ,
      '10/new_migcms_link_name'=> 
      {
	        'title'=>'Nom du nouveau lien',
	        'fieldtype'=>'text',
	        'search' => 'y',
          'tab'    => 'page'
	    }
       ,
      '11/new_migcms_link_url'=> 
      {
	        'title'=>'URL du nouveau lien',
	        'fieldtype'=>'text_id',
	        'search' => 'y',
          'tab'    => 'page'
	    }
      ,
      '20/id_textid_url'=> 
      {
	        'title'=>"Réécriture d'URL",
	        'fieldtype'=>'text_id',
	        'search' => 'y',
          'tab'    => 'referencement'
	    }
      ,
      '21/id_textid_meta_title'=> 
      {
	        'title'=>'Titre',
	        'fieldtype'=>'textarea_id',
	        'search' => 'y',
          'tab'    => 'referencement'
	    }
      ,
      '22/id_textid_meta_description'=> 
      {
	        'title'=>'Description',
	        'fieldtype'=>'textarea_id',
	        'search' => 'y',
          'tab'    => 'referencement'
	    }
      ,
      '24/id_textid_meta_keywords'=> 
      {
	        'title'=>'Mots clés',
	        'fieldtype'=>'textarea_id',
	        'search' => 'y',
          'tab'    => 'referencement'
	    }
	);

%dm_display_fields =  
      (
      );  
%dm_lnk_fields = (
"40/"=>"page_preview*"
		);
%dm_mapping_list = (
     "page_preview"=>\&page_preview
);

%dm_filters = (
		);

$dm_cfg{help_url} = "http://www.bugiweb.com";

# this script's name

$sw = $cgi->param('sw') || "list";

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
		);

if (is_in(@fcts,$sw)) 
{ 
    see();
    dm_init();
    &$sw();
    if ($sw eq "list") {$spec_bar.=$lnkxls;}
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}



sub page_preview
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %d = %{$_[3]};

  my $preview ='';
  my %page = sql_line({debug_results=>0,table=>'migcms_pages',where=>"id='$id'"});
  my $type = '';
  my $link = '';
  my $phrase = '';
  my ($elt_name,$dum) = get_textcontent($dbh,$page{id_textid_name});
  my $class = '';
  my $elt = '';
  
  if($page{migcms_pages_type} eq 'directory')
  {
      $link = $page{id};
      $phrase = "";
      
      my %count = select_table($dbh,"migcms_pages","count(id) as total","id_father = '$page{id}'");
      $elt = <<"EOH";
<span class="badge">$page{ordby}</span> <i class="fa fa-folder-o"></i> $elt_name
EOH
  }
  # elsif($page{migcms_pages_type} eq 'link')
  # {
      # $elt = <<"EOH";
# <span class="badge">$page{ordby}</span><i class="fa fa-link"></i><i> $elt_name</i>
# EOH
  # }
  elsif($page{migcms_pages_type} eq 'page' || $page{migcms_pages_type} eq 'link')
  {
      $class= ' text-info ';
	  my $sel = get_quoted('sel'); 
	  
	  my $lock = '';
	  my %migcms_lnk_page_group = sql_line({table=>'migcms_lnk_page_groups',where=>"is_linked='y' AND id_migcms_page='$page{id}' "});
	  if($migcms_lnk_page_group{id} > 0)
	  {
		$lock =' <i class="fa fa-lock"></i> ';
	  }
	  
	  my $icon = '<i class="fa fa-file-text-o"></i>';
	  
	  if($page{migcms_pages_type} eq 'link')
	  {
		$icon = '<i class="fa fa-link"></i>';
	  }
	  
	  $elt = <<"EOH";
	  <label>
		<input type="radio" name="migcms_parag_links_page" class="migcms_parag_links_page" id="$page{id}" />
		<span class="badge">$page{ordby}</span> $icon $elt_name $lock 
	   </label>
EOH
  }
  
  my $preview = <<"EOH";
     $elt
EOH
  
  return $preview;
}

sub after_save
{
    my $dbh=$_[0];
    my $id =$_[1];
    my %page = sql_line({dbh=>$dbh_data,table=>"migcms_pages",where=>"id='$id'"});
    my ($url,$dum) = get_textcontent($dbh,$page{new_migcms_link_url});
    
    if(trim($page{new_migcms_link_name}) ne '' && trim($url) ne '' )
    {
        my $id_textid_link_url = insert_text($dbh_data,$url,$colg);
        my %new_link = (
        'link_name' => $page{new_migcms_link_name},
        'id_textid_link_url' => $id_textid_link_url,
        'visible' => 'y'
        );
        $new_link{link_name} =~ s/\'/\\\'/g;
        my $id_link = inserth_db($dbh_data,'migcms_links',\%new_link);
        
        my $stmt = "UPDATE migcms_pages SET id_migcms_link = $id_link, new_migcms_link_name='', new_migcms_link_url=0  WHERE id='$id'";
        execstmt($dbh_data,$stmt);
    }
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------