#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;



# migc modules

         # migc translations

use members;

use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset);

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

$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "id_tarif != id_tarif_souhaite and id_tarif_souhaite > 0";
$dm_cfg{table_name} = "members";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_validation_revendeurs.pl?";
if($config{current_language} eq "")
{
   $config{current_language}=get_quoted('lg') || 1;
}

$config{logfile} = "trace.log";

$dm_cfg{disable_mod} = "n";

$dm_cfg{hiddp}=<<"EOH";

EOH

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    
      '01/firstname'=> {
	        'title'=>$migctrad{adm_firstname},
	        'fieldtype'=>'text',
	        'search' => 'y',
	    },
	    '02/lastname'=> {
	        'title'=>$migctrad{adm_lastname},
	        'fieldtype'=>'text',
	        'search' => 'y',
	    },
	    '03/company'=> {
	        'title'=>$migctrad{adm_company},
	        'fieldtype'=>'text',
	        'search' => 'y',
	    },
      
      
      
      
      '04/email'=> {
	        'title'=>$migctrad{adm_email},
	        'fieldtype'=>'text',
	        'search' => 'y',
	    }
	     ,
      '10/id_tarif'=> 
      {
      'title'=>"Tarif actuel<br>(vide = tarif normal)",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'eshop_tarifs',
      'lbkey'=>'id',
      'lbdisplay'=>'name',
      'lbwhere'=>"visible = 'y'",
      }
      
      ,
      '10/id_tarif_souhaite'=> 
      {
      'title'=>"Tarif souhaite",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'eshop_tarifs',
      'lbkey'=>'id',
      'lbdisplay'=>'name',
      'lbwhere'=>"visible = 'y'",
      }
	    
	    
	);

%dm_display_fields = (
      "01/$migctrad{adm_lastname}"=>"lastname",
      "02/$migctrad{adm_firstname}"=>"firstname",
	    "03/$migctrad{adm_email}"=>"email",


		);  
# 	    "04/$migctrad{adm_pwd}"=>"passwd",
#       	    "05/$migctrad{adm_creation_time}"=>"creation_time",
# 	    "06/$migctrad{adm_lastlogin_time}"=>"lastlogin_time",
%dm_lnk_fields = (
    "04/Tarifs"=>"member_group*",   
		);


#     $dm_lnk_fields{"08//$migctrad{adm_orders}"} = "$config{baseurl}/cgi-bin/adm_orders.pl?&id_member2=";
%dm_mapping_list = (
    "member_group"=>\&member_group
);

%dm_filters = (
		);

$dm_cfg{help_url} = "http://www.bugiweb.com";

# this script's name

$sw = $cgi->param('sw') || "list";
$lnkxls = "<a href=\"$dm_cfg{self}&sw=get_content_xls\" target=\"_blank\">$migcicons{xls_export}</a>";
if ($sw ne "get_content_xls") { see(); }

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
    $gen_bar = get_gen_buttonbar($members_gen_bar);
    $spec_bar = get_spec_buttonbar($sw);
    if ($sw eq "list") {$spec_bar.=$lnkxls;}
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub member_group
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  my %member=read_table($dbh,"members",$id);
  
  my %tarif_actuel = read_table($dbh,"eshop_tarifs",$member{id_tarif});
  my %tarif_souhaite = read_table($dbh,"eshop_tarifs",$member{id_tarif_souhaite});
  
  return <<"EOH";
   Tarif actuel: $tarif_actuel{name}
   <br />Tarif souhaité: $tarif_souhaite{name}   
EOH
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

		 if ($dm_dfl{$key}{fieldtype} eq "text_id" || $dfl{$key}{fieldtype} eq "textarea_id")
      {           
       %item = %{update_textid_field($dbh,$field,$op,\%item)};
      }
      
		if (defined $dm_dfl{$key}{mandatory})
		{
			if (!check_field_value($item{$field}, $dm_dfl{$key}{mandatory}{type}, \@{$dm_dfl{$key}{mandatory}{params}}))
			{
				dm_check_error($dm_dfl{$key}{title});
			}
		}
  }
  
  my %webdisk_config = eval("%webdisk_config = ($config{webdisk_cfg});");
  my $dir = $webdisk_config{root}."/".$item{directory};
  if (! -e $dir)
  {
    my $rc = mkdir($dir);
   	if (!rc) {suicide("cannot create $dir : $!");}
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
  
  my $stmt = "DELETE FROM identities WHERE id_member='$id'";
  execstmt($dbh,$stmt);
  
#  $stmt = "DELETE FROM lnk_member_groups WHERE id_member='$id'";
#  execstmt($dbh,$stmt);
}

sub get_content_xls
{

 my @members = get_table($dbh,"members");  

 my @header,@data,@row;

 @header = ('ID','email','vis.','firstname','lastname','nickname',' ',' '); 
 
 foreach my $m (@members) {
  
     @row = (
             $m->{id},
             $m->{email},
             $m->{visible},
             $m->{firstname},
             $m->{lastname}, 
             $m->{nickname}, 
             $m->{infosupp1}, 
             $m->{infosupp2},
            );
     my @myrow = @row;
     for (my $ijk =0; $ijk <= $#myrow; $ijk++) {$myrow[$ijk] = from_utf8({ -string => $myrow[$ijk], -charset => 'ISO-8859-1' });}
     push @data, (\@myrow);       
 }



 my @identities = get_table($dbh,"identities");  

 my @header2,@data2,@row2;

 @header2 = ('MEMBER','email','civility','firstname','lastname','company','street','number','box','city','state','zip','country','countrycode','tel1','tel2','fax','newsletter','rem','vat','vat_app'); 
 
 foreach my $i (@identities) {
  
     @row2 = (
             $i->{id_member},
             $i->{email},
             $i->{civility},
             $i->{firstname},
             $i->{lastname}, 
             $i->{company}, 
             $i->{street}, 
             $i->{number},
             $i->{box},
             $i->{city},
             $i->{state},
             $i->{zip},
             $i->{country},
             $i->{countrycode},
             $i->{tel1},
             $i->{tel2},
             $i->{fax},
             $i->{newsletter},
             $i->{rem},
             $i->{vat},
             $i->{vat_app},
            );
     my @myrow = @row2;
     for (my $ijk =0; $ijk <= $#myrow; $ijk++) 
     {
         $myrow[$ijk] =~ s/[^a-zA-Z0-9\s\@\.\-\_]+//g;
         $myrow[$ijk] = from_utf8({ -string => $myrow[$ijk], -charset => 'ISO-8859-1' });
     }
     push @data2, (\@myrow);       
 }



  


       
 use Spreadsheet::SimpleExcel;

 binmode(\*STDOUT);

  # create a new instance
  my $excel = Spreadsheet::SimpleExcel->new();

  # add worksheets
  $excel->add_worksheet('Members',{-headers => \@header, -data => \@data});
  $excel->add_worksheet('Identities',{-headers => \@header2, -data => \@data2});

  # print into file
  $outfile = $config{pic_dir}."/tmpxls.xls";
  $excel->output_to_file($outfile);

print $cgi->redirect(-location=>$outfile,-content-type=>'application/vnd.ms-excel');

}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------