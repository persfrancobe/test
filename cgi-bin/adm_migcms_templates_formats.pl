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

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


$dm_cfg{customtitle} = $migctrad{templates_title};

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{deplie_recherche} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "migcms_templates_formats";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{table_width} = 800;
$dm_cfg{fieldset_width} = 950;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_templates_formats.pl?";
$dm_cfg{duplicate} = 'y';

$config{logfile} = "trace.log";








#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    '01/id'=> {
	        'title'=>'ID',
	        'fieldtype'=>'display',
	        'fieldsize'=>'50',
	        'search' => 'y',
	    },
		
		'02/nom_format'=> {
	        'title'=>'Nom',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    },
	    
	    '03/contenu_format'=> {
	        'title'=>'Contenu HTML',
	        'fieldtype'=>'textarea',
	        'fieldparams'=>'',
	    }
	    
	);

%dm_display_fields = (
			"1/ID"=>"id",
			"2/Nom"=>"nom_format",

		);

%dm_lnk_fields = (
		);

%dm_mapping_list = (
);

%dm_filters = (
		);

$dm_cfg{help_url} = "http://www.bugiweb.com";
#$fwicons{"add"} = "<img src=\"../gfx/icons/user_add.png\" />",
#$fwicons{"del"} = "<img src=\"../gfx/icons/user_delete.png\" />",

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

if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
	
	 my $suppl_js=<<"EOH";
    
     <style>
      </style>
    
   	<script type="text/javascript">
      jQuery(document).ready(function() 
      {
          jQuery("#list_keyword").focus();  
		  jQuery( "#list_keyword" ).keypress(function() 
		  {
		  });
            
      });
    </script> 
EOH
	
    print wfw_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_and_check
{
	my %item; 
  my $op = $_[0];
  
	foreach $key (keys(%dm_dfl))
	{ 
		my ($num,$field) = split(/\//,$key);
		$item{$field} = get_quoted($field,"","dontsanitize");
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
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------