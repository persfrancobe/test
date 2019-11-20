#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;



use Data::Dumper;
# migc modules

         # migc translations


use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;
use sitetxt;
use eshop;

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

$dm_cfg{customtitle}=<<"EOH";
EOH

$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "data_setup";
$dm_cfg{list_table_name} = "data_setup";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
# $dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_setup_data.pl?";

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_ordby_ref} = '';
$config{logfile} = "trace.log";
$dm_cfg{hiddp}=<<"EOH";
EOH

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = 
(
      # '10/do_suivant_precedent'=> 
      # {
      # 'title'=>'Activer Suiv./Préc. (lourd)',
      # 'fieldtype'=>'checkbox',
      # 'checkedval' => 'y'
      # }
      # ,
      # '20/dynamic_search_fields'=> 
      # {
      # 'title'=>'Champs de rech. dyn. (lourd)',
      # 'fieldtype'=>'checkbox',
      # 'checkedval' => 'y'
      # }
      # ,
      '30/hide_tva_admin'=> 
      {
      'title'=>"Cacher la TVA dans l'admin",
      'fieldtype'=>'checkbox',
      'checkedval' => 'y'
      }
      ,
      '40/data_sheet_force_tva'=> 
      {
      'title'=>'Forcer la TVA par défaut',
      'fieldtype'=>'text',
      }
      # ,
      # '50/donotwritetiles'=> 
      # {
      # 'title'=>"Ne pas générer de tuiles",
      # 'fieldtype'=>'checkbox',
      # 'checkedval' => 'y'
      # }
      ,
      '60/id_default_tarif'=> 
      {
      'title'=>"Tarif par défaut",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'eshop_tarifs',
      'lbkey'=>'id',
      'lbdisplay'=>'name',
      'lbwhere'=>"visible = 'y'",
      'mandatory'=>{"type" => 'not_empty'}
      }
	  ,
    '81/use_data_cache'=> 
    {
		'title'=>'Utiliser le cache pour les annuaires',
		'fieldtype'=>'checkbox',
		'checkedval' => 'y',
		'tab' => 'site'
    }
	 ,
    '82/secure_data'=> 
    {
		'title'=>'Etre connecté pour voir les annuaires',
		'fieldtype'=>'checkbox',
		'checkedval' => 'y',
		'tab' => 'site'
    }
);


%dm_display_fields = (
"01/Configuration des annuaires"=>"do_suivant_precedent"
		);

%dm_lnk_fields = (
		);

%dm_mapping_list = (
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
			up
			banners_link
			link_banner_category
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    
    
    
    
    my $suppl_js=<<"EOH";
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <script type="text/javascript">
    jQuery(document).ready(function() 
    {
    });
    </script>
EOH

    if($sw ne "dum")
    {
      $migc_output{content} .= $dm_output{content};
      $migc_output{title} = $dm_output{title}.$migc_output{title};
      print migc_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
    }
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_and_check
{
	my %item; 
  my $op = $_[0];
 
  my $id_banner_zone = get_quoted('id_banner_zone');
  my %banner_zone = read_table($dbh,"banners_zones",$id_banner_zone);
  
  my $upload_path = $config{root_path}.'/usr/';
  
	foreach $key (keys(%dm_dfl))
	{ 
		my ($num,$field) = split(/\//,$key);
		
		$item{$field} = get_quoted($field);

		 if ($dm_dfl{$key}{fieldtype} eq "text_id" || 
         $dm_dfl{$key}{fieldtype} eq "textarea_id" || $dm_dfl{$key}{fieldtype} eq "textarea_id_editor")
      {        
       %item = %{update_textid_field($dbh,$field,$op,\%item)};
      }
      elsif ($dm_dfl{$key}{fieldtype} eq "file")
      { 
             
             $item{$field} = $cgi->param($field);
             
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
           %item = %{update_pic_field_admin_fixed($dbh,$field,$op,\%item,$upload_path,$banner_zone{height},$banner_zone{width},$banner_zone{width},$banner_zone{height},$banner_zone{width},$banner_zone{height},"fixed_height","")};
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


sub after_save
{
    my $dbh=$_[0];
    my $id_banner =$_[1];
    

}
