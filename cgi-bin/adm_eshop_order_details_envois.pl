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

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{customtitle} = <<"EOH";
   
EOH
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "qty > 0";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "eshop_order_details_expeditions";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{after_del_ref} = \&after_del;
$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
$dm_cfg{hide_id} = 1;
$dm_cfg{default_ordby} = " expedition_moment desc ";
$dm_cfg{after_del_ref} = \&after_del;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_eshop_order_details_envois.pl?";
        
$config{logfile} = "trace.log";


$dm_cfg{after_mod_ref} = \&up;
$dm_cfg{after_add_ref} = \&up;

my $selfcolg=$dm_cfg{self}.'&sw='.$sw.'&id='.get_quoted('id');       
my $colg_menu = get_colg_menu($dbh,$colg,$selfcolg);

$dm_cfg{hiddp}=<<"EOH";

EOH



my $id_data_family = get_quoted('id') || 0;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = 
(
'05/id_eshop_order'=> 
{
'title'=>'Ref commande',
'fieldtype'=>'display',
'fieldsize'=>'50',
'search' => 'y',
}
,
'10/prenom'=> 
{
'title'=>'Prénom',
'fieldtype'=>'display',
'fieldsize'=>'50',
'search' => 'y',
}
,
'15/nom'=> 
{
'title'=>'Nom',
'fieldtype'=>'display',
'fieldsize'=>'50',
'search' => 'y',
}
,
'20/expedition_detail_reference'=> 
{
'title'=>'Référence',
'fieldtype'=>'display',
'fieldsize'=>'50',
'search' => 'y',
}
,
'25/expedition_detail_label'=> 
{
'title'=>'Libellé',
'fieldtype'=>'display',
'fieldsize'=>'50',
'search' => 'y',
}
,
'30/qty'=> 
{
'title'=>'Qté envoyée',
'fieldtype'=>'display',
'checkedval' => 'y'
}

);

%dm_display_fields = 
(
	"05/Ref commande"=>"id_eshop_order",
  "10/Prénom"=>"prenom",
  "15/Nom"=>"nom",
  "20/Référence"=>"expedition_detail_reference",
  "25/Libellé"=>"expedition_detail_label",
  "30/Qté"=>"qty",
);

%dm_lnk_fields = 
    (
"01/Date"=>"order_moment*",
    );



%dm_mapping_list = (
"order_moment"=>\&get_order_moment,
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
sub get_order_moment
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  my %eshop_order_details_expeditions = sql_line({table=>"eshop_order_details_expeditions",where=>"id='$id'"});
  my $date=to_ddmmyyyy($eshop_order_details_expeditions{expedition_moment},"withtime");

  return $date;
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


sub after_del
{
  my $dbh = $_[0];
  my %rec_deleted = %{$_[1]};  
  
   my @order_details = sql_lines({table=>'eshop_order_details',where=>"id_eshop_order='$rec_deleted{id_eshop_order}'"});
     foreach $detail (@order_details)
     {
         my %detail = %{$detail};
       
         #UPDATE QTY EXPEDIE FOR DETAIL 
         my $stmt = <<"EOH";
            UPDATE eshop_order_details SET detail_qty_expedie = (select SUM(qty) FROM eshop_order_details_expeditions WHERE id_eshop_order_detail = '$detail{id}')  WHERE id = '$detail{id}' 
EOH
         execstmt($dbh,$stmt);
         
         #UPDATE QTY RESTANT FOR DETAIL 
         my $stmt = <<"EOH";
            UPDATE eshop_order_details SET detail_qty_restant = detail_qty - detail_qty_expedie  WHERE id = '$detail{id}'
EOH
         execstmt($dbh,$stmt);
     }
     #UPDATE TOTAL QTY EXPEDIE FOR ORDER 
      my $stmt = <<"EOH";
         UPDATE eshop_orders SET total_qty_expedie = (select SUM(detail_qty_expedie) FROM eshop_order_details WHERE id_eshop_order = '$rec_deleted{id_eshop_order}') WHERE id = '$rec_deleted{id_eshop_order}'
EOH
      execstmt($dbh,$stmt);
      
      #UPDATE TOTAL QTY RESTANT FOR ORDER 
      my $stmt = <<"EOH";
         UPDATE eshop_orders SET total_qty_restant = (select SUM(detail_qty_restant) FROM eshop_order_details WHERE id_eshop_order = '$rec_deleted{id_eshop_order}') WHERE id = '$rec_deleted{id_eshop_order}'
EOH
      execstmt($dbh,$stmt);
  
 
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------