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

use HTML::Entities;
use Encode;
use eshop;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = $dm_cfg{wherel} = "";
$dm_cfg{table_name} = "data_stock";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
$dm_cfg{default_ordby} = "reference asc";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_eshop_datastock.pl?";
$dm_cfg{hiddp} = <<"EOH";
  
EOH

$dm_cfg{disable_mod} = "n";

$config{logfile} = "trace.log";

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    '01/reference'=> {
	        'title'=>'Référence',
	        'fieldtype'=>'display',
	        'search' => 'y',
	    },
	    
	    '03/id_textid_comment_1'=> {
	        'title'=>'Commentaire',
	        'fieldtype'=>'text_id',
	        'search' => 'y',
	    }
	);
	
%dm_display_fields = (
      "03/Référence"=>"reference"
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
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    
    my $suppl_js=<<"EOH";
   	<script type="text/javascript">
      jQuery(document).ready(function() 
      {
       
      })
    </script> 
EOH
    
    print migc_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
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
 
  if ($id_member ne "") {$item{id_member} = $id_member;}
 
	return (\%item);	
}
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
sub before_del
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------