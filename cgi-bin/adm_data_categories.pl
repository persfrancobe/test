#!/usr/bin/perl -I../lib -w

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use data;

my $id=get_quoted('id');
my $id_data_family = get_quoted('id_data_family');
my $id_father = get_quoted('id_father');
$sw = $cgi->param('sw') || "list";


$dm_cfg{enable_search} = 0;
$dm_cfg{excel} = 0;
$dm_cfg{visibility} = 1;
$dm_cfg{sort} = 1;
$dm_cfg{tree} = 1;
$dm_cfg{trad} = 1;
$dm_cfg{use_migcms_cache} = 1;
$dm_cfg{after_upload_ref} = \&after_upload;


$dm_cfg{after_add_ref}     = \&after_save;
$dm_cfg{after_mod_ref}     = \&after_save;
$dm_cfg{autocreation} = 1;

$dm_cfg{'list_custom_action_1_func'} = \&voir_sheets;
$dm_cfg{'list_custom_action_2_func'} = \&sort_sheets;



if ($cfg_family{use_other_categories} ne "") 
{
    $id_data_family = $cfg_family{use_other_categories};
}
my %family=read_table($dbh,"data_families",$id_data_family);



$dm_cfg{wherep} = "id_data_family=$id_data_family";
$dm_cfg{wherel} = "id_data_family=$id_data_family";
$dm_cfg{table_name} = "data_categories";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{wherep_ordby} = "id_data_family=$id_data_family";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?id_data_family=$id_data_family&colg=$colg";
$dm_cfg{page_title} = 'Catégories';
$dm_cfg{line_func} = 'custom_tree_levels';  
$dm_cfg{file_prefixe} = 'CAT';
@dm_nav =
(
    {
        'tab'   =>'1',
        'type'  =>'tab',
        'title' =>'Nom'
    }
	,
	 {
        'tab'   =>'2',
        'type'  =>'tab',
        'title' =>'Informations supplémentaires'
    }
	,
	 {
        'tab'   =>'3',
        'type'  =>'tab',
        'title' =>'Référencement'
    }
);
	
	
	
	

%dm_dfl = (
	    '01/id_textid_name'=> 
      {
	        'title'=>$migctrad{id_textid_name},
	        'fieldtype'=>'text_id',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
			tab=>1,
	    },
	    '02/id_textid_description'=> 
       {
	        'title'=>$migctrad{id_textid_description},
	        'fieldtype'=>'textarea_id_editor',
	        'search' => 'y',
			tab=>2,
	    }
	    ,
	    '04/id_textid_url'=> 
      {
	        'title'=>$migctrad{data_categories_url},
	        'fieldtype'=>'text_id',
	        'search' => 'n',
			tab=>2,
	    }
      ,
      '05/target_blank'=> 
      {
	        'title'=>$migctrad{data_categories_target_blank},
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y',
			tab=>2,
	    }
		  ,
	    '07/id_textid_url_rewriting'=> 
      {
	        'title'=>$migctrad{id_textid_url_rewriting},
	        'fieldtype'=>'text_id',
	        'search' => 'n',
			tab=>3,
	    }
      ,
      '08/id_textid_meta_title'=> 
       {
	        'title'=>$migctrad{id_textid_meta_title},
	        'fieldtype'=>'textarea_id',
	        'search' => 'y',
			tab=>3,
	    }
      ,
      '09/id_textid_meta_description'=> 
       {
	        'title'=>$migctrad{id_textid_meta_description},
	        'fieldtype'=>'textarea_id',
	        'search' => 'y',
			tab=>3,
	    }
       ,
	    '12/id_father' => 
      {
           'title'=>'Parent',
           'fieldtype'=>'listboxtable',
		   'datatype'=>'treeview',
           'lbtable'=>'data_categories',
           'lbkey'=>'id',
           'lbdisplay'=>'id_textid_name',
           'translate'=>1,
           'multiple'=>0,
		   	'tree_col'=>'id_father',
		    'summary'=>0,
           'lbwhere'=>"id_data_family='$id_data_family'",
			tab=>1,
      }
	  ,
	    '13/id_data_family' => 
      {
           'title'=>'Famille',
           'fieldtype'=>'text',
           'lbtable'=>'data_families',
           'lbkey'=>'id',
           'lbdisplay'=>'name',
           'lbwhere'=>"",
           'hidden'=>1,
			tab=>1,
		   
      }
	  ,
	   '14/variante'=> 
      {
	        'title'=>'Variante ?',
	        'fieldtype'=>'checkbox',
			tab=>1,
	    }
  ,
	    '15/photos' => 
      {
			'title'=> 'Ajouter des photos',
			'tip'=>"<b>Cliquez</b> pour parcourir ou <b>déposez</b> vos fichiers <u>dans ce cadre</u>",
			'fieldtype'=>'files_admin',
			'disable_add'=>1,
			'tab'=>'1',
			'msg'=>'Cliquez ici pour parcourir votre ordinateur ou déposez directement des fichiers dans ce cadre.',
		},
		'20/f25'=> 
      {
        'title'=>"Infos supplémentaires",
        'fieldtype'=>'text',
				tab=>2,
	    },
		
	);
	

%dm_display_fields = (
	"01/$migctrad{id_textid_name}"=>"id_textid_name",
	"02/Variante ?"=>"variante"
		);

%dm_lnk_fields = (
		);

%dm_mapping_list = (
);

%dm_filters = (
		);



if($config{use_handmade_categories} eq 'y')
{
	if(($config{use_handmade_categories_for_id_father} eq '') || ($config{use_handmade_categories_for_id_father} ne '' && $config{use_handmade_categories_for_id_father} == $id_father))
	{
	@dm_nav = @{def_handmade::get_categories_handmade_dm_nav({migctrad=>\%migctrad})};
	%dm_display_fields  = %{def_handmade::get_categories_handmade_dm_display_fields({migctrad=>\%migctrad})};
	%dm_dfl  = %{def_handmade::get_categories_handmade_dm_dfl({migctrad=>\%migctrad})};
	}
}		
		
see();

my @fcts = qw(
			list
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();

    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
		
    print migc_app_layout($js.$migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}


sub after_save
{
    my $dbh=$_[0];
    my $id=$_[1];
    my %rec = read_table($dbh,$dm_cfg{table_name},$id);
	
	my %txt_name = sql_line({table=>'txtcontents',where=>"id='$rec{id_textid_name}'"});
	my %txt_url_rew = sql_line({table=>'txtcontents',where=>"id='$rec{id_textid_url_rewriting}'"});
	
	my %update_txt = ();
	my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible = 'y' || encode_ok = 'y'"});
    foreach $language (@languages)
    {
        my %language = %{$language};
		
		if($txt_name{'lg'.$language{id}} ne '')
		{
			$update_txt{'lg'.$language{id}} = clean_url($txt_name{'lg'.$language{id}},'n');
		}
		else
		{
			$update_txt{'lg'.$language{id}} = clean_url($txt_url_rew{'lg'.$language{id}},'n');
		}
	}
	%update_txt = %{quoteh(\%update_txt)};
	updateh_db($dbh,"txtcontents",\%update_txt,'id',$txt_url_rew{id});	
	
	after_upload($dbh,$id);
	
	my $category_fusion = ''  ;    
	compute_cat_denomination(0,$category_fusion);
	edit_db_sort_tree_recurse(0); 

}

sub compute_cat_denomination
{
	my $id_father = $_[0];
	my $category_fusion_r = $_[1];
	
	my @cats = sql_lines({debug=>0,table=>$dm_cfg{table_name},where=>"id_father='$id_father'"});

	foreach $cat (@cats)
	{
		my %cat = %{$cat};
		
		my $nom_module = get_traduction({debug=>0,id=>$cat{id_textid_name},id_language=>1});

		
		my $category_fusion = $category_fusion_r.' > '.$nom_module;
		
		compute_cat_denomination($cat{id},$category_fusion);	
		
		$category_fusion = trim($category_fusion);
		$category_fusion =~ s/^\>//g;
		# $cat{category_reference}.' '.
		$category_fusion = trim($category_fusion);
		$category_fusion =~ s/\'/\\\'/g;
		my $id_avec_prefixe = getcode($dbh,$cat{id});


		
		# $stmt = "UPDATE $dm_cfg{table_name} SET fusion= '$id_avec_prefixe | > $category_fusion' WHERE id = $cat{id}";
		$stmt = "UPDATE $dm_cfg{table_name} SET fusion= '$category_fusion' WHERE id = $cat{id}";
		execstmt($dbh,$stmt);
	}	
}

sub after_upload
{
	my $dbh=$_[0];
	my $id=$_[1];
	my %data_category = sql_line({table=>'data_categories',where=>"id='$id'"});
	my %data_family = sql_line({table=>'data_categories',where=>"id='$data_category{id_data_family}'"});
	my %template = sql_line({table=>'templates',where=>"id='$data_family{id_template_object_cat}'"});
	
	my @sizes = ('mini','small','medium','large','og');
	
	my @migcms_linked_files = sql_lines({debug=>1,debug_results=>1,table=>'migcms_linked_files',where=>"ext IN ('.jpg','.jpeg','.png') AND table_name='$dm_cfg{table_name}' AND table_field='photos' AND token='$id'",ordby=>'ordby'});
	foreach $migcms_linked_file (@migcms_linked_files)
	{
		#appelle la fonction de redimensionnement
		my %migcms_linked_file = %{$migcms_linked_file};
		my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
		my %params = (
			migcms_linked_file=>\%migcms_linked_file,
			do_not_resize=>$parag{do_not_resize}
		);
		foreach my $size (@sizes)
		{
			$params{'size_'.$size} = $template{'size_'.$size};
		}
		dm::resize_pic(\%params);
	}	
}

sub voir_sheets
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};

	my $sel_data_sheets;
  if($id == 1)
  {
    $sel_data_sheets = 1000212;
  }
  elsif ($id == 2)
  {
    $sel_data_sheets = 1000269;
  }
  elsif ($id == 4)
  {
    $sel_data_sheets = 1000214;
  }

	my $acces = <<"EOH";
		<a class="btn btn-primary" href="../cgi-bin/adm_data_sheets.pl?colg=$colg&id_data_family=$id_data_family&sel=$sel_data_sheets&menu_sw=235&extra_filter=$record{id}&id_data_categories=,$record{id}," data-original-title="Voir ou ajouter des fiches pour cette catégorie" target="" data-placement="bottom">
		<i class="fa fa-cube fa-fw"></i>
		</a>
EOH

	return $acces;
}

sub sort_sheets
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};


	my $acces = <<"EOH";
		<a class="btn btn-default" href="../cgi-bin/adm_migcms_data_sheets_cat_sort.pl?colg=$colg&id_data_family=$id_data_family&sel=1000272&menu_sw=235&extra_filter=$record{id}&id_data_categories=,$record{id}," data-original-title="Trier les fiches de cette catégorie" target="" data-placement="bottom">
		<i class="fa fa-random fa-fw"></i>
		</a>
EOH

	return $acces;
}