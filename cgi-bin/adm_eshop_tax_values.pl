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
# migc modules
use migclib;          
         


use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();
$colg = get_quoted('colg') || $config{default_colg} || 1;
my $id_eshop_tax =  get_quoted('id_eshop_tax');

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}



$dm_cfg{customtitle} = <<"EOH";
Taxes  
EOH
$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "id_eshop_tax=$id_eshop_tax";
$dm_cfg{wherep} = "id_eshop_tax=$id_eshop_tax";
$dm_cfg{table_name} = "eshop_tax_values";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?id_eshop_tax=$id_eshop_tax";

$config{logfile} = "trace.log";


$dm_cfg{after_mod_ref} = \&up;
$dm_cfg{after_add_ref} = \&up;

my $selfcolg=$dm_cfg{self}.'&sw='.$sw.'&id='.get_quoted('id');       
my $colg_menu = get_colg_menu($dbh,$colg,$selfcolg);

$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="colg" value="$colg" />
<input type="hidden" name="id_eshop_tax" value="$id_eshop_tax" />
EOH



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = 
(
'01/value'=> 
{
'title'=>'Valeur',
'fieldtype'=>'text',
'fieldsize'=>'50',
'search' => 'y',
'mandatory'=>{"type" => 'not_empty'},
}

);

%dm_display_fields = 
(
	"01/Valeur"=>"value"
);

%dm_lnk_fields = 
    (
    );


%dm_mapping_list = (
);

sub up
{
    my $dbh=$_[0];
    my $id=$_[1];
    
}




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
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar("$colg_menu ");
    $spec_bar = get_spec_buttonbar($sw);
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_and_check
{
	my %item; 
  my $op = $_[0];
  
	foreach $key (keys(%dm_dfl))
	{ 
		my ($num,$field) = split(/\//,$key);
		
		$item{$field} = get_quoted($field);

		 if ($dm_dfl{$key}{fieldtype} eq "text_id" || $dm_dfl{$key}{fieldtype} eq "textarea_id")
      {           
       %item = %{update_textid_field($dbh,$field,$op,\%item)};
      }
      elsif ($dm_dfl{$key}{fieldtype} eq "file")
      { 
             
             if($datadir_config{upload_path} eq "")
             {
                $datadir_config{upload_path}=$config{root_path}.'/usr/';
             }
             
             
             
             %item = %{update_file_field_admin($dbh,$field,$op,\%item,$datadir_config{upload_path})};

            
             
             if ($item{$field} eq "") {delete $item{$field};} elsif ($item{$field} eq " "){$item{$field}="";} 
      }
      elsif ($dm_dfl{$key}{fieldtype} eq "pic")
      { 
           %item = %{update_pic_field_admin($dbh,$field,$op,\%item,$datadir_config{upload_path})};
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
  $item{id_eshop_tax} = $id_eshop_tax;
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
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------