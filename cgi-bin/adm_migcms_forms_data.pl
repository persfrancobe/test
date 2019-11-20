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

use migcrender;
use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$colg = get_quoted('colg') || $config{default_colg};

$dm_cfg{customtitle} = $migctrad{products_management}.' > '.$migctrad{product_families_list};
$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{add} = 0;
$dm_cfg{edit} = 0;
$dm_cfg{visualiser} = 1;
$dm_cfg{excel} = 1;
$dm_cfg{table_name} = "forms_data";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{txtsrc} = 'forms';
$dm_cfg{default_ordby} = 'moment desc';
 
$dm_cfg{after_mod_ref} = \&up;
$dm_cfg{after_add_ref} = \&up;

my $id_form = get_quoted('id_form') || 1;

$dm_cfg{wherep} = $dm_cfg{wherel} = " id_form='$id_form' ";

my $self=$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_forms_data.pl?";

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = ( 
      '99/moment'=> 
      {
	        'title'=>"Date",
	        'fieldtype'=>'text',
	        'data_type'=>'datetime',

	    }
);

%dm_display_fields = (
"99/Date"=>"moment",
);

my @fields = sql_lines({debug=>0,table=>'forms_fields',where=>"id_form = $id_form",ordby=>'ordby'});
foreach $field (@fields)
{
   my %field = %{$field};
   my $ordby = sprintf("%02d",$field{ordby});
   my ($name,$dum) = get_textcontent($dbh,$field{id_textid_name});
   $dm_dfl{$ordby.'/f'.$field{ordby}}{title}=$name;
   $dm_dfl{$ordby.'/f'.$field{ordby}}{fieldtype}='text';
#    if($field{type} eq 'text')
#    {
#        
#    }
#    elsif($field{type} eq 'radio' || $field{type} eq 'listbox'  || $field{type} eq 'checlbox' )
#    {
#        $dm_dfl{$ordby.'/f'.$field{ordby}}{fieldtype}='listboxtable';
#        $dm_dfl{$ordby.'/f'.$field{ordby}}{lbtable}='forms_fields_listvalues f, textcontents txt';
#        $dm_dfl{$ordby.'/f'.$field{ordby}}{lbkey}='f.id';
#        $dm_dfl{$ordby.'/f'.$field{ordby}}{lbdisplay}='content';
#        $dm_dfl{$ordby.'/f'.$field{ordby}}{lbwhere}="id_field = '$field{id}' AND f.id_textid_name = txt.id_textid AND id_language = 1 ";
#    }
   
   if($field{in_list} eq 'y')
   {
      $dm_display_fields{"$ordby/$name"}='f'.$field{ordby};
   }
}

# On met la date en 1er
$dm_display_fields{"00/moment"}='moment';

%dm_lnk_fields = (
		);

%dm_mapping_list = (
);

%dm_filters = (
		);


$sw = $cgi->param('sw') || "list";
my $selfcolg=$self.'&sw='.$sw.'&id='.get_quoted('id');       

$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="colg" value="$colg" />
<input type="hidden" value="$id_dataform" name="id_dataform" />
EOH

see();

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
			up
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);;
}




sub up
{
    my $dbh=$_[0];
    my $id=$_[1];
   
}



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------