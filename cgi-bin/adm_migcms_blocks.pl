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
use migcrender;
$dbh_data = $dbh;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



my $id_blocktype = get_quoted('id_blocktype');

$dm_cfg{tree} = 0;
$dm_cfg{enable_search} = 0;
$dm_cfg{visibility} = 1;
$dm_cfg{trad} = 1;
$dm_cfg{sort} = 1;
$dm_cfg{autocreation} = 1;
$dm_cfg{modification} = 1;
$dm_cfg{delete} = 1;
$dm_cfg{wherep} = $dm_cfg{wherel} = " id_blocktype='$id_blocktype' ";
$dm_cfg{table_name} = "migcms_blocks";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{javascript_custom_func_form} = 'after_load';
$dm_cfg{pic_url} = 1;
$dm_cfg{pic_alt} = 1;

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_blocks.pl?id_blocktype=$id_blocktype";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{add_title} = "Ajouter un bloc";
$dm_cfg{file_prefixe} = 'BLO';
$dm_cfg{page_cms} = 1;

$dm_cfg{list_html_top} = <<"EOH"; 
<style>
.maintitle
{
display:none;
}
.sortable-placeholder
{
	background-color:#4fcf4f;
}
.migcms_parag_links tr .list_ordby,.migcms_parag_links tr .td-input
{
	
}
</style>
EOH

if($config{current_language} eq "")
{
   $config{current_language}=get_quoted('lg') || 1;
}




$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="id_blocktype" value="$id_blocktype" />

EOH


%types = (
			"01/content"=>"Contenu",
			"03/function"=>"Fonction",
      "02/menu"=>"Menu"
		);
  
  
my $where_type_block_templates = " type = 'block' || type = 'parag' || type = 'menu' ";
my %migc_blocktype = read_table($dbh,'migc_blocktypes',$id_blocktype);
$dm_cfg{page_title} = "Contenus répétitifs pour ".$migc_blocktype{name};
if($migc_blocktype{type_bloc_zone} eq 'mailing')
{
	$where_type_block_templates = " type = 'block' ||  type = 'mailing_parag' ";
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	'01/type'=> 
	{
		'title'=>"Type de contenu",
		'fieldtype'=>'listbox',
		'data_type'=>'btn-group',
		'fieldvalues'=>\%types,
		'default_value'=>'content',
	}
	,
	'02/id_template' => 
	{
		'title'=>'Template ',
		'fieldtype'=>'listboxtable',
		'lbtable'=>'templates',
		'lbkey'=>'id',
		'lbdisplay'=>'name',
		'lbwhere'=>"$where_type_block_templates" ,
	}
	,
	'03/id_template_menu' => 
	{
		'title'=>'Template menu ',
		'fieldtype'=>'listboxtable',
		'lbtable'=>'templates',
		'lbkey'=>'id',
		'lbdisplay'=>'name',
		'lbwhere'=>"$where_type_block_templates" ,
	}
	,
	'04/id_textid_title'=> 
	{
		'title'=>'Titre',
		'fieldtype'=>'text_id',
		'search' => 'y',
	}
	,
	'05/id_textid_content' => 
	{
		'title'=>'Contenu',
		'fieldtype'=>'textarea_id_editor',
	} 
	,
	'07/id_page_directory' => 
	{
		'title'=>'Menu a afficher',
		'fieldtype'=>'listboxtable',
		'lbtable'=>'migcms_pages',
		'lbkey'=>'migcms_pages.id',
		'lbdisplay'=>'id_textid_name',
		'lbwhere'=>"migcms_pages_type = 'directory'",
		'translate'=>"1",
	}
	,
	'09/function' => 
	{
		'title'=>'Fonction externe',
		'fieldtype'=>'text',
		'lbwhere'=>"",
	}
	,
	'63/fichiers'=> 
	{
		'title'=>"Photos",
		'tab'=>'',
		'fieldtype'=>'files_admin',
		'disable_add'=>1,
	}
	,
	'64/do_not_resize'=> 
	{
		'title'=>"Ne pas redimensionner les photos",
		'tab'=>'',
		'default_value'=>'n',
		'fieldtype'=>'checkbox',
		'disable_add'=>1,
	}
	,
	'98/id_textid_link_url' => 
	{
		'title'=>'URL sur les photos',
		'tab'=>'',
		'fieldtype'=>'text_id',
	}
	,
	'99/id_blocktype' => 
	{
		'title'=>'Bloc',
		'fieldtype'=>'text',
		'data_type'=>"hidden"
	}
);      

%dm_display_fields =  
      (
"01/"=>"type",	      
      );  
%dm_lnk_fields = (
"40/"=>"parag_rendu*",
# "60//<span class='span_tooltip fa fa-image' data-original-title='Photos' data-placement='top'>/"=>"$config{baseurl}/cgi-bin/adm_migcms_block_pics.pl?&id_block=",
		);

		%dm_mapping_list = (
     "parag_rendu"=>\&parag_rendu
);

		
%dm_filters = (
      
		);



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
    
    my $suppl =<<"EOH";
     <style>
     .list_ordby,.list_ordby_header
     {
       /* display:none;*/
     }
     </style>
    <input type="hidden" id="id_father" class="set_data" name="id_father" value="" />
    <script type="text/javascript"> 
    
    jQuery(document).ready(function() 
    { 
        jQuery(document).on("change", "#field_type",refresh_pages_types);
        refresh_pages_types();
        
    });
    
    
    function refresh_pages_types()
    {
            var type = jQuery("#field_type").val();
		
            jQuery('.row_edit_type, .row_edit_id_template, .row_edit_id_textid_title, .row_edit_id_textid_content, .row_edit_id_page_directory, .row_edit_function, .row_edit_fichiers, .row_edit_do_not_resize, .row_edit_id_textid_link_url').show();
            
            if(type == 'content')
            {
                jQuery('.row_edit_id_template_menu, .row_edit_id_page_directory, .row_edit_function').hide();
            }
            if(type == 'function')
            {
                jQuery('.row_edit_id_textid_title,.row_edit_id_textid_content,.row_edit_id_page_directory, .row_edit_fichiers, .row_edit_do_not_resize, .row_edit_id_textid_link_url').hide();
            }
            if(type == 'menu')
            {
                jQuery('.row_edit_id_textid_title,.row_edit_id_textid_content,.row_edit_function, .row_edit_fichiers, .row_edit_do_not_resize, .row_edit_id_textid_link_url').hide();
            }
			
    }
    
    function after_load()
    {
		//jQuery('.btn_change_listbox.btn-info').click();
		refresh_pages_types();
    }
    </script>
EOH
    
    print migc_app_layout($suppl.$migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub parag_rendu
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %d = %{$_[3]};
  my %bloc = read_table($dbh,"migcms_blocks",$id);

  my $title = get_traduction({id=>$bloc{id_textid_title},id_language=>1});
  my $content = get_traduction({id=>$bloc{id_textid_content},id_language=>1,debug=>0});

  my $photos = '';
  my @migcms_linked_files = sql_lines({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='$dm_cfg{table_name}' AND token='$id'",ordby=>'ordby'});
  foreach $migcms_linked_file (@migcms_linked_files)
  {
		my %migcms_linked_file = %{$migcms_linked_file};
		if($migcms_linked_file{do_not_resize} eq 'y')
		{
			my $url_pic_preview = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
			$photos .= "<img src='$url_pic_preview' />";
		}
		else
		{
			my $url_pic_preview = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{name_medium};
			if(!(-e $url_pic_preview)  || $migcms_linked_file{name_medium} eq '')
			{
				$url_pic_preview = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
			}
			$photos .= "<img src='$url_pic_preview' />";
		}
  }
  
  if($bloc{type} eq 'function' && $bloc{function} ne '')
  {
  $rendu = <<"EOH";
  <div class="mig_cms_value_col">
	<div class="mig_cms_value_col">
		<span class="label label-info">$bloc{type} externe</span> 
		<span class="label label-default">$bloc{function}</span> 
	</div>
EOH
	return $rendu;
  }
  
  my $rendu = <<"EOH";
  <div class="mig_cms_value_col">
		<!--<strong>Template de contenu :</strong><br />-->
	</div>
	<div class="mig_cms_value_col">
		<h2 class="mig-parag-title">$title</h2>
		$content
		$photos
	</div>
	<div class="mig_cms_value_col">
		<hr />
		<span class="label label-info">$bloc{type}</span>
	</div>
EOH

  return $rendu;
}

sub after_save
{
    my $dbh=$_[0];
    my $id =$_[1];
   
    my %bloc = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
	my %template = sql_line({table=>'templates',where=>"id='$bloc{id_template}'"});
	my %parag_setup = sql_line({table=>'parag_setup',where=>""});
	#calcul les tailles des images: d'abord celles du templates sinon les valeurs par défaut
	my @sizes = ('mini','small','medium','large','og');
	foreach my $size (@sizes)
	{
	    if(!($template{'size_'.$size} > 0))
		{
			$template{'size_'.$size} = $parag_setup{'default_size_'.$size};
		}
	}
	#boucle sur les images du paragraphes
	my @migcms_linked_files = sql_lines({debug=>1,debug_results=>1,table=>'migcms_linked_files',where=>"table_name='$dm_cfg{table_name}' AND table_field='fichiers' AND token='$id'",ordby=>'ordby'});
	foreach $migcms_linked_file (@migcms_linked_files)
	{
		#appelle la fonction de redimensionnement
		my %migcms_linked_file = %{$migcms_linked_file};
		my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
		my %params = 
		(
			migcms_linked_file=>\%migcms_linked_file,
			do_not_resize=>$bloc{do_not_resize}
		);
		foreach my $size (@sizes)
		{
			$params{'size_'.$size} = $template{'size_'.$size};
		}
		log_debug('resize');
		use Data::Dumper;
		log_debug(Dumper(\%params));
		dm::resize_pic(\%params);
	}
}

# sub after_upload
# {
	# my $dbh=$_[0];
	# my $id=$_[1];
	# my %parag = sql_line({table=>'parag',where=>"id='$id'"});
	# my %template = sql_line({table=>'templates',where=>"id='$parag{id_template}'"});
	# my %parag_setup = sql_line({table=>'parag_setup',where=>""});
	
	# calcul les tailles des images: d'abord celles du templates sinon les valeurs par défaut
	# my @sizes = ('mini','small','medium','large','og');
	# foreach my $size (@sizes)
	# {
	    # if(!($template{'size_'.$size} > 0))
		# {
			# $template{'size_'.$size} = $parag_setup{'default_size_'.$size};
		# }
	# }
	
	# boucle sur les images du paragraphes
	# my @migcms_linked_files = sql_lines({debug=>1,debug_results=>1,table=>'migcms_linked_files',where=>"ext IN ('.jpg','.jpeg','.png') AND table_name='$dm_cfg{table_name}' AND table_field='fichiers' AND token='$id'",ordby=>'ordby'});
	# foreach $migcms_linked_file (@migcms_linked_files)
	# {
		# appelle la fonction de redimensionnement
		# my %migcms_linked_file = %{$migcms_linked_file};
		# my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
		# my %params = (
			# migcms_linked_file=>\%migcms_linked_file,
			# do_not_resize=>$parag{do_not_resize}
		# );
		# foreach my $size (@sizes)
		# {
			# $params{'size_'.$size} = $template{'size_'.$size};
			# log_debug($size.':'.$params{'size_'.$size});
		# }
		# dm::resize_pic(\%params);
	# }	
# }