#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use migcrender;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

my $id_table = get_quoted('id_parag');

$dm_cfg{disable_mod} = 'n';   
$dm_cfg{disable_buttons} = 'n';
$dm_cfg{hide_id} = 1;
$dm_cfg{add} = 0;
$dm_cfg{nolabelbuttons} = 'y';
$dm_cfg{trad} = 1;
$dm_cfg{no_export_excel} = 1;
$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 1;
$dm_cfg{no_drag_sort} = 1;
$dm_cfg{migcms_parag_inline_edit} = 1;
$dm_cfg{inline_edit} = 1;

$dm_cfg{wherep} = $dm_cfg{wherel} = " id_parag='$id_table' ";
$dm_cfg{table_name} = "migcms_parag_pics";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{wherep_ordby} = "";
$dm_cfg{default_ordby} = " ordby ";

$dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_parag_pics.pl?id_parag=$id_table";

$dm_cfg{col_id} = 'id';
$dm_cfg{edit_func} = 'edit_migcms_pics';
$dm_cfg{page_title} = 'Images du paragraphe';

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{add_title} = "Ajouter une image";

my %parag = sql_line({debug => 0, debut_results=>0,table=>'parag',where=>"id='$id_table'"});
my %page = sql_line({debug => 0, debut_results=>0,table=>'migcms_pages',where=>"id='$parag{id_page}'"});
my ($page_title,$dum) = get_textcontent($dbh,$page{id_textid_name});
my ($parag_title,$dum) = get_textcontent($dbh,$parag{id_textid_title});
$dm_cfg{bread_title} =<< "EOH";
<a href="cgi-bin/adm_migcms_parag.pl?&id_page=$parag{id_page}">
$page_title 
</a> 
<span class="divider">/</span>
$parag_title
EOH

my $id_parag = get_quoted('id_parag');
$dm_cfg{list_html_top} = <<"EOH";





<div class="well custom_add">
<b>Ajouter une image:</b>
<a href="" class="btn btn-default">Depuis votre ordinateur</a> 
<a href="" class="btn btn-link" disabled>Depuis "Mes fichiers"</a> 

<br>
<form action="../cgi-bin/adm_migcms_parag_pics_upload.pl?"
      class="dropzone"
      id="my-awesome-dropzone" enctype="multipart/form-data">
	<u>Options d'envoi:</u> <br> <br> 
	<div class="form-group">
	
	<input type="hidden" name="id_parag" value="$id_parag" />
					<label class="col-sm-10 control-label" for="">
						Utiliser la miniature  ? 
					</label>
					<div class="col-sm-2 ">
					   <input type="checkbox" value="y" class="form-control create_thumb" name="create_thumb" checked="checked" />  
					</div>
	</div>
	
	<div class="form-group">
					<label class="col-sm-10 control-label" for="">
						Taille de la miniature ? 
					</label>
					<div class="col-sm-2 ">
					   <input type="text" value="150" class="form-control size_thumb" name="size_thumb" />  
					</div>
	</div>
	
	<div class="form-group">
					<label class="col-sm-10 control-label" for="">
						Copier dans la bibliothèque ? 
					</label>
					<div class="col-sm-2 ">
					   <input type="checkbox" value="y" class="form-control bibliotheque" name="bibliotheque" />  
					</div>
	</div>
	  

	  
	  </form>
		
    </div>
	
EOH


$dm_cfg{list_html_bottom} = <<"EOH";
		   <script>
              jQuery(document).ready(function() 
			  {		
					jQuery('.migedit').click(function()
					{
						jQuery('.custom_add').slideUp();
					});
					
					jQuery('.cancel_edit,.return_to_list').click(function()
					{
						jQuery('.custom_add').slideDown();
					});
					
					Dropzone.options.myAwesomeDropzone = 
					{
						paramName: "photo", // The name that will be used to transfer the file
						maxFilesize: 50, // MB
						dictDefaultMessage:'<br /><br /><br /><br /><br /><br /><i class="fa fa-plus fa-lg fa-fw"></i> <i class="fa fa-file-image-o  fa-lg fa-fw"></i> Déposez des fichiers ici ou <a class="btn btn-info" onclick="return false;">cliquez ici pour parcourir</a> votre ordinateur'
						,
						init: function () 
						{
							this.on("complete", function (file) 
							{
								get_list_body();
							});
						}
					};

             jQuery("#field_pic_name_orig").parent().append(' <a href="#" class="parag_pics_choose"> Parcourir</a>');
			 
             });
             </script>
EOH

$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="id_parag" value="$id_parag" />
EOH

$config{logfile} = "trace.log";

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
      '10/id_parag' => 
      {
       'title'=>'Num du paragraphe',
       'fieldtype'=>'text',
       'data_type'=>"hidden"
      }
      # ,
      # '20/pic_path_orig' => 
      # {
       # 'title'=>'Chemin',
       # 'fieldtype'=>'text',
       # 'data_type'=>"hidden"
      # }
      ,
      '30/pic_name_orig' => 
      {
       'title'=>"Nom de l'image",
       'fieldtype'=>'display',
      }
	   ,
	   '31/lightbox'=> 
      {
	        'title'=>'Ouvrir dans une lightbox ?',
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y',
          'default_value' => 'n'
	    }
      ,
	   '32/new_window'=> 
      {
	        'title'=>'Ouvrir dans une nouvelle fenêtre ?',
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y',
          'default_value' => 'n'
	    }
      ,
      '40/pic_thumb_create'=> 
      {
	        'title'=>'Utiliser la miniature ?',
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y',
          'default_value' => 'y'
	    }
      ,
      '50/pic_thumb_size' => 
      {
       'title'=>'Largeur de la miniature',
       'fieldtype'=>'text',
       'default_value' => '150'
      }
      ,
      '60/id_textid_alt' => 
      {
       'title'=>'Légende',
       'fieldtype'=>'text_id',
	   'inline_edit'=>'0',
      }
      ,
      '70/id_textid_url' => 
      {
       'title'=>"Lien sur l'image",
       'fieldtype'=>'text_id',
      }
	 
	);
	

%dm_display_fields = (
  # "02/Utiliser la miniature ?"=>"pic_thumb_create",
  "03/Légende"=>"id_textid_alt",
  
		);


%dm_lnk_fields = (
"01/"=>"pic_rendu*",
		);

    

%dm_mapping_list = (
    "pic_rendu"=>\&pic_rendu,
);

%dm_filters = (
		);

$dm_cfg{help_url} = "http://www.bugiweb.com";

# this script's name

$sw = $cgi->param('sw') || "list";

see();

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
			effect_gallery
      ajax_save_parag
      ajax_save_elt
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw,"");

    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
#     my $id_banner_zone=get_quoted('id');
#     my $markup=get_markup($id_banner_zone);
    
    my $suppl_js=<<"EOH";
    <style>
    .list_action
    {
        width:125px;
        text-align:center;
    }
    </style>
<script type="text/javascript">
    jQuery(document).ready(function() 
    {
       
    });
</script>

    
    
EOH
      
    print migc_app_layout($suppl_js.$migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}

            
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_and_check
{
	my %item; 
  my $op = $_[0];
#  use Data::Dumper;

  
	foreach $key (keys(%dm_dfl))
	{ 
		my ($num,$field) = split(/\//,$key);
		
		$item{$field} = get_quoted($field);

		 if ($dm_dfl{$key}{fieldtype} eq "text_id" || 
         $dm_dfl{$key}{fieldtype} eq "textarea_id" || $dm_dfl{$key}{fieldtype} eq "textarea_id_editor")
      {        
       %item = %{update_textid_field($dbh,$field,$op,\%item)};
#         see(\%item);

      }
      elsif ($dm_dfl{$key}{fieldtype} eq "file")
      { 
             
             if($datadir_config{upload_path} eq "")
             {
                $datadir_config{upload_path}=$upload_path;
             }
             
             
             
             %item = %{update_file_field_admin($dbh,$field,$op,\%item,$datadir_config{upload_path},$default_small_height,$default_small_width,$default_medium_width,$default_medium_height,$default_mini_width,$default_mini_height)};

            
             
             if ($item{$field} eq "") {delete $item{$field};} elsif ($item{$field} eq " "){$item{$field}="";} 
      }
      elsif ($dm_dfl{$key}{fieldtype} eq "pic")
      { 
           $item{$field} = $cgi->param($field);
           %item = %{update_pic_field_admin_fixed($dbh,$field,$op,\%item,$datadir_config{upload_path},$default_small_height,$default_small_width,$default_medium_width,$default_medium_height,$default_mini_width,$default_mini_height,"fixed_height")};
           if ($item{$field} eq "") {delete $item{$field};}
      }
      
		if (defined $dm_dfl{$key}{mandatory})
		{
			if (!check_field_value($item{$field}, $dm_dfl{$key}{mandatory}{type}, \@{$dm_dfl{$key}{mandatory}{params}}))
			{
				dm_check_error($dm_dfl{$key}{title});
			}
		}
  }
	return (\%item);	
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_form
{
	my %item = %{$_[0]};
	
	my $form = build_form(\%dm_dfl,\%item);



	return $form;
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_view
{
	my %item = %{$_[0]};
	my $form = build_view(\%dm_dfl,\%item);

	return $form;
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub before_del
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  
}

sub add_embed
{
  my $dbh = $_[0];
  my $id = $_[1];
  
}

sub update_embed
{
  my $dbh = $_[0];
  my $id = $_[1];
}

sub ajax_save_parag
{
    see();
    my $id = get_quoted('id');
    my $type = get_quoted('type');
    my $content = get_quoted('content');
    my %parag = sql_line({table=>'parag',where=>"id='$id'"});
#     $content =~ s/\'/\\\'/g;
    
    if($type eq 'content')
    {
        my $stmt = "UPDATE textcontents SET content='$content' WHERE id_textid='$parag{id_textid_parag}' AND id_language = 1";
        execstmt($dbh,$stmt);
    }
    elsif($type eq 'title')
    {
        my $stmt = "UPDATE textcontents SET content='$content' WHERE id_textid='$parag{id_textid_title}' AND id_language = 1";
        execstmt($dbh,$stmt);
    }
}


sub ajax_save_elt
{
    see();
    my $id_elt = get_quoted('id_elt');
    my $table_name = get_quoted('table_name');
    my $col = get_quoted('col');
    my $content = get_quoted('content');
   
    if($table_name ne '' && $col ne '' && $id_elt > 0)
    {
        my $stmt = "UPDATE $table_name SET $col='$content' WHERE id='$id_elt'";
        print $stmt;
        execstmt($dbh,$stmt);
        exit;
    }
    else
    {
        print "MISSING DATA: $table_name ne '' && $col ne '' && $id_elt > 0";
    }
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub pic_rendu
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  my $photo = migcrender::render_parag_pic({id=>$id,admin=>'y'});
  
  return $photo; 
}


sub after_save
{
    use Image::Size;
    my $dbh=$_[0];
    my $id =$_[1];
	
    my %pic = sql_line({debug=>0,debug_results=>0,table=>'migcms_parag_pics',where=>"id=$id"});
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	
	$year+=1900;	
	$mon++;
	
    my $orig = $config{directory_path}.'/'.$pic{pic_path_orig}.'/'.$pic{pic_name_orig};
	
	my @splitted = split(/\./,$pic{pic_name_orig});
	my $ext = lc($splitted[$#splitted]);	
	my $filename = $splitted[0];
	my $file_url = $filename .'_'.$year.$mon.$mday.$hour.$min.$sec.'.'.$ext;
	
	my $dest = $config{directory_path}.'/pics/'.$file_url;

	system("cp $orig $dest");

    if(-e $dest)
    {
		if($pic{pic_thumb_create} eq 'y')
		{
			($orig_width, $orig_height ) = imgsize($dest);
			my $orig_path = $config{directory_path}.'/pics';
			($small,$small_width,$small_height,$orig_width,$orig_height) = thumbnailize($file_url,$orig_path,$pic{pic_thumb_size},$pic{pic_thumb_size},"_small",$config{pic_dir});
			($full,$full_width,$full_height,$orig_width,$orig_height) = thumbnailize($file_url,$orig_path,1200,1200,"_full",$config{pic_dir});
			($og,$og_width,$og_height,$orig_width,$orig_height) = thumbnailize($file_url,$orig_path,130,130,"_og",$config{pic_dir});
			my %pic_update =
			(
				url_pic_small => "$small",
				url_pic_big => "$full",
				url_pic_ogg => "$og",   
				pic_name_orig => "$file_url",
			);
			updateh_db($dbh,'migcms_parag_pics',\%pic_update,"id",$pic{id});
		}
		else
		{
			my %pic_update =
			(
				pic_name_orig => "$file_url",               
			);
			updateh_db($dbh,'migcms_parag_pics',\%pic_update,"id",$pic{id});
		}
    }
    else
    {
        see();
        print "$dest doesnt exist !";
        exit;
    }
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------