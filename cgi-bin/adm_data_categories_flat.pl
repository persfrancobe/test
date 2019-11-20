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
$dm_cfg{visible} = 1;
$dm_cfg{sort} = 1;
$dm_cfg{duplicate} = 1;
$dm_cfg{autocreation} = 1;
$dm_cfg{tree} = 0;
$dm_cfg{after_add_ref}     = \&after_save;
$dm_cfg{after_mod_ref}     = \&after_save;
$dm_cfg{file_prefixe} = 'CAT';

$dm_cfg{after_upload_ref} = \&after_upload;


if($cfg_family{use_other_categories} ne "") 
{
    $id_data_family = $cfg_family{use_other_categories};
}
my %family=read_table($dbh,"data_families",$id_data_family);



$dm_cfg{wherep} = "id_data_family=$id_data_family AND id_father=$id_father";
$dm_cfg{wherel} = "id_data_family=$id_data_family AND id_father=$id_father";
$dm_cfg{table_name} = "data_categories";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{wherep_ordby} = "id_data_family=$id_data_family";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}_flat.pl?id_data_family=$id_data_family&id_father=$id_father&colg=$colg";

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
	    '14/photos' => 
      {
			'title'=> 'Ajouter des photos',
			'tip'=>"<b>Cliquez</b> pour parcourir ou <b>déposez</b> vos fichiers <u>dans ce cadre</u>",
			'fieldtype'=>'files_admin',
			'disable_add'=>1,
			'tab'=>'1',
			'msg'=>'Cliquez ici pour parcourir votre ordinateur ou déposez directement des fichiers dans ce cadre.',
		}
	);
	

%dm_display_fields = (
	"01/$migctrad{id_textid_name}"=>"id_textid_name"
		);

%dm_lnk_fields = (
		);

%dm_mapping_list = (
);

%dm_filters = (
		);



if($config{use_handmade_categories} eq 'y')
{
	@dm_nav = @{def_handmade::get_categories_handmade_dm_nav({migctrad=>\%migctrad})};
	%dm_display_fields  = %{def_handmade::get_categories_handmade_dm_display_fields({migctrad=>\%migctrad})};
	%dm_dfl  = %{def_handmade::get_categories_handmade_dm_dfl({migctrad=>\%migctrad})};
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
	# use Data:Dumper;
	# log_debug(Dumper(\%txt_name));
	# log_debug(Dumper(\%txt_url_rew));
	# log_debug(Dumper(\%update_txt));
	updateh_db($dbh,"txtcontents",\%update_txt,'id',$txt_url_rew{id});	
	
	after_upload($dbh,$id);

}

sub after_upload
{
	my $dbh=$_[0];
	my $id=$_[1];
	my %data_category = sql_line({table=>'data_categories',where=>"id='$id'"});
	my %data_family = sql_line({table=>'data_families',where=>"id='$data_category{id_data_family}'"});
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
			do_not_resize=>'n',
		);
		foreach my $size (@sizes)
		{
			
			$params{'size_'.$size} = $template{'size_'.$size};
		}
		dm::resize_pic(\%params);
	}	
}