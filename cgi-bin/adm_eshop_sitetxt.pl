#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

use fwlayout;
use fwlib;
use Data::Dumper;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();
$dm_cfg{customtitle} = 'Textes ESHOP';



$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = " keyword LIKE 'eshop_%'";
$dm_cfg{table_name} = "sitetxt_common";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{table_width} = 800;
$dm_cfg{fieldset_width} = 750;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_sitetxt.pl?";
$dm_cfg{default_ordby} = "keyword asc";

$config{logfile} = "trace.log";



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    	
	    '01/keyword'=> {
	        'title'=>"Mot clé",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty', }
	    }  
	    , 
      '02/lg1'=> 
      {
	        'title'=>"Français",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty', }
	    } 
      , 
      '03/lg2'=> 
      {
	        'title'=>"Anglais",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty', }
	    } 
      , 
      '04/lg3'=> 
      {
	        'title'=>"Néérlandais",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty', }
	    } 
      , 
      '05/lg4'=> 
      {
	        'title'=>"Allemand",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty', }
	    } 
      ,
      '06/type'=> 
      {
	        'title'=>'Module',
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%sitetxt_types
	    }
	);

%dm_display_fields = (
			"1/Clé"=>"keyword",
      "2/Français"=>"lg1",
      "3/Anglais"=>"lg2",
      "4/Néérlandais"=>"lg3",
      "5/Allemand"=>"lg4"      
		);

my %maplg = eval("%maplg = ($config{maplg})");

$cpt = 4;
#   see();
#   print Dumper(\%maplg);

foreach $lg_id (sort keys %maplg) {
    my $lg_key = sprintf("%02d",$cpt)."/".$maplg{$lg_id};
    
#     my %language = %{get_obj_hash_from_db($dbh,"languages","id",$lg_id)}; #renvoie le mauvais rec?
    my %language=read_table($dbh,"migcms_languages",$lg_id);
    
    my $dis_key = $cpt."/".$language{display_name};
    my $lg_name = $language{display_name};

    my $tmp = " %dum = (
        'title'=>\"$lg_name\",
	      'fieldtype'=>'textarea',
	      'fieldparams'=>'cols=100 rows=10',
	      'search' => 'y',
        )
        ";
    my %dum = eval $tmp;    
    $dm_dfl{$lg_key} = \%dum;
        
           
    $dm_display_fields{$dis_key} = $maplg{$lg_id};
    $cpt++;
    
}

#print Dumper(\%dm_dfl);
#print Dumper(\%dm_display_fields);

%dm_lnk_fields = (
		);


%dm_mapping_list = (
);





%dm_filters = (
"1/Module"=>{
             'type'=>'hash',
	     'ref'=>\%sitetxt_types,
	     'col'=>'type'
                        }
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
			view
			assoc_loc_form
			assoc_loc_db
			assoc_them_form
			assoc_them_db
			hide_txt
		);

if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    if ($sw eq "list") {
        $dm_output{content} = "<p class=\"txt_exp\">".$migctrad{sitetxt_exp}."</p>".$dm_output{content};
    }
    
    
    
#     print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
    print $dm_output{content};
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


sub get_view
{
	my %item = %{$_[0]};
	my $form = build_view(\%dm_dfl,\%item);

	return $form;
}

