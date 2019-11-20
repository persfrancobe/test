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
# migc modules

         # migc translations

use migcrender;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();

$colg = get_quoted('colg') || $config{default_colg} || 1;

my $id_data_crit=get_quoted('id_data_crit');
my $id_data_family=get_quoted('id_data_family');

# if($id_data_family > 0)
# {
# }
# else
# {
    # see();
    # print "Précisez l'identifiant de la famille svp";
    # exit;
# }
my %family=read_table($dbh,"data_families",$id_data_family);
my $crit_name = get_obj_name($dbh,$id_data_crit,'data_crits');

$dm_cfg{customtitle} = <<"EOH";
<a href="$config{baseurl}/cgi-bin/adm_data_families.pl?colg=$colg">$migctrad{data_title_families}</a>   
> 
<a href="$config{baseurl}/cgi-bin/adm_data_crits.pl?id_data_family=$id_data_family&colg=$colg">$migctrad{data_title_crits_families} $family{name}</a>  
>
<a href="$config{baseurl}/cgi-bin/adm_data_crit_listvalues.pl?id_data_family=$id_data_family&id_data_crit=$id_data_crit&colg=$colg">$migctrad{data_crits_listvalues_title} $crit_name</a>

EOH


$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 1;

$dm_cfg{wherep} = "id_data_crit=$id_data_crit and id_data_family=$id_data_family";
$dm_cfg{wherel} = "id_data_family=$id_data_family and id_data_crit=$id_data_crit";
$dm_cfg{table_name} = "data_crit_listvalues";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";



$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
$dm_cfg{self} = "$htaccess_protocol_rewrite://$config{ewrite_default_url}/cgi-bin/adm_$dm_cfg{table_name}.pl?id_data_crit=$id_data_crit&id_data_family=$id_data_family";

$dm_cfg{page_title} = "Valeurs d'une variante";
$dm_cfg{add_title} = "Ajouter une valeur de variante";
$config{logfile} = "trace.log";

my $selfcolg=$dm_cfg{self}.'&sw='.$sw.'&id='.get_quoted('id');       
my $colg_menu = get_colg_menu($dbh,$colg,$selfcolg);



$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" value="$id_data_crit" name="id_data_crit" />
<input type="hidden" value="$id_data_family" name="id_data_family" />
<input type="hidden" name="colg" value="$colg" />
EOH

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (

	    '01/id_textid_name'=> {
	        'title'=>$migctrad{id_textid_name},
	        'fieldtype'=>'text_id',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
		,
		'02/id_data_family'=> 
	{
        'title'=>'id_data_family',
		'hidden'=>1,
        'fieldtype'=>'text',
        'fieldsize'=>'40',
        'search' => 'y',
        'mandatory'=>{"type" => 'not_empty',
                     }
    }
	,
		'03/id_data_crit'=> 
	{
        'title'=>'id_data_crit',
		'hidden'=>1,
        'fieldtype'=>'text',
        'fieldsize'=>'40',
        'search' => 'y',
        'mandatory'=>{"type" => 'not_empty',
                     }
    }
	    
	);
	
#\@
%dm_display_fields = (
	"01/$migctrad{id_textid_value}"=>"id_textid_name",
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
		);

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

 $item{id_data_family} = $id_data_family;
 $item{id_data_crit} = $id_data_crit;
 
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