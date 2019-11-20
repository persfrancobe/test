#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use DBI;   # standard package for Database access
use CGI;   # standard package for easy CGI scripting
use def; # home-made package for defines
use tools;
use dm;

use fwlayout;
use fwlib;
# migc modules

         # migc translations



# build the CGI object, and so on...
$_ = $cgi->param('sw');
$id_data_category = $cgi->param('id_data_category');
$id_data_family = $cgi->param('id_data_family');

$config{current_language} = get_quoted('lg') || $config{default_language};
$colg = get_quoted('colg') || $config{default_colg} || 1;

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{customtitle} = $migctrad{data_management}.' > '.$migctrad{data_categories_title};
$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{howmany} = 500;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 1;
$dm_cfg{table_width} = 500;
$dm_cfg{fieldset_width} = 500;

$dm_cfg{disable_buttons} = "y";
$dm_cfg{disable_mod} = "y";

# name of the SQL table we work with
$dm_cfg{table_name} = "data_lnk_sheets_categories";


$dm_cfg{wherep_ordby} = $dm_cfg{wherep} = "data_lnk_sheets_categories.id_data_category=$id_data_category";   
# get the fields list for this table 
@dm_dfl = ();

# hidden field for all forms
$dm_cfg{hiddp} = <<"EOH";
<input type="hidden" name="id_data_category" value="$id_data_category" />
<input type="hidden" name="id_data_family" value="$id_data_family" />
<input type="hidden" name="colg" value="$colg" />
EOH
 
# this script's name
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_data_nodes.pl?id_data_family=$id_data_family&lg=$config{current_language}&id_data_category=$id_data_category";

my $selfcolg=$dm_cfg{self}.'&sw='.$sw.'&id='.get_quoted('id');       
my $colg_menu = get_colg_menu($dbh,$colg,$selfcolg);

# my %data_field=select_table($dbh,"data_fields","","id_data_family='$id_data_family' AND ordby='2'");
# if($data_field{field_type} eq 'text')
# {
#   $dm_cfg{list_table_name} = "$dm_cfg{table_name},data_sheets AS prods";
#   $dm_cfg{wherel} = "data_lnk_sheets_categories.id_data_sheet = prods.id AND data_lnk_sheets_categories.id_data_category=$id_data_category";
# }
# else
# {
#   $dm_cfg{list_table_name} = "$dm_cfg{table_name},textcontents AS txt,data_sheets AS prods";
#   $dm_cfg{wherel} = "prods.f2 = txt.id_textid AND txt.id_language=$config{current_language} AND data_lnk_sheets_categories.id_data_sheet = prods.id AND data_lnk_sheets_categories.id_data_category=$id_data_category";
# }
# 
# 
# if($data_field{field_type} eq 'text')
# {
#   %dm_display_fields = (
#                    "1/Fiche"=>'f2'
#                   );
# }
# else
# {
#   %dm_display_fields = (
#                    "1/Fiche"=>'txt.content'
#                   );
# }
$dm_cfg{list_table_name} = "$dm_cfg{table_name},data_sheets AS prods";
$dm_cfg{wherel} = "data_lnk_sheets_categories.id_data_sheet = prods.id AND data_lnk_sheets_categories.id_data_category=$id_data_category";
%dm_dfl = %{data_get_repository_list($dbh,$id_data_family)};

$dm_lnk_fields{"00/Photo"} = "pic_preview*";  
    $dm_mapping_list{pic_preview} = \&pic_preview;

my $size = 0;
      $size += scalar keys %dm_dfl;  # method 1: explicit scalar context
      if ($size == 0)
      {
           make_error("$migctrad{datadirs_raw_data_error_nofield}");
      }
      $size = 0;
      ($ref_df,$ref_ml) = data_get_repository_display($dbh,$id_data_family);
      
      %dm_display_fields=%{$ref_df};
      

$sw = $cgi->param('sw') || "list";

see();

my @fcts = qw(list change_ordby);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar("$colg_menu ");
    $spec_bar = get_spec_buttonbar($sw);

    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
     
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}



sub pic_preview
{
    my $dbh = $_[0];
    my $id_lnk = $_[1];
    my %lnk = read_table($dbh,'data_lnk_sheets_categories',$id_lnk);
    
    my $sheets="";
    my $list_cats="";
    my %pic=select_table($dbh,"data_lnk_sheet_pics lnk, pics p","pic_name_mini","id_data_sheet='$lnk{id_data_sheet}' AND lnk.id_pic = p.id AND  lnk.visible='y' order by lnk.ordby limit 0,1","","",0);
    my $pic = <<"EOH";
   <img src="$config{baseurl}/pics/$pic{pic_name_mini}" /> 
EOH
    if($pic{pic_name_mini} eq '')
    {
        return '';
    }
    else
    {
        return $pic;
    }
}