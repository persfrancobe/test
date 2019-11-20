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

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();
$colg = get_quoted('colg') || $config{default_colg};

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 1;
$dm_cfg{trad} = 1;

$dm_cfg{wherel} = "";
$dm_cfg{table_name} = "eshop_deliveries";
$dm_cfg{list_table_name} = "eshop_deliveries";
$dm_cfg{disable_del_button}='n';

$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/eshop_deliveries.pl?";
$dm_cfg{after_mod_ref} = \&update_embed;
$dm_cfg{after_add_ref} = \&add_embed;

$config{logfile} = "trace.log";

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
      '01/name'=> 
      {
	        'title'=>'Identifiant (Ne pas modifier)',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
	    ,
      '02/id_textid_name'=> 
      {
	        'title'=>'Nom',
	        'fieldtype'=>'text_id',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
	    ,
	    '03/id_textid_description'=> 
      {
	        'title'=>'Description',
	        'fieldtype'=>'textarea_id_editor',
	        'fieldsize'=>'50',
	        'search' => 'y'
	    }
      ,
      '04/use_cost'=> 
      {
	        'title'=>'Utiliser le cout fixe',
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y'
	    }
      ,
      '04/identity_tier'=> 
      {
	        'title'=>'Identity tier (Adresse de livraison différente)',
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y'
	    }
      ,
	    '05/cost'=> 
      {
	        'title'=>'Cout fixe',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y'
	    }
       ,
	    '06/max_weight'=> 
      {
	        'title'=>'Poids max',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y'
	    }
        ,
	    # '07/limit_to_country'=> 
     #  {
	    #     'title'=>'Limiter au pays',
	    #     'fieldtype'=>'text',
	    #     'fieldsize'=>'50',
	    #     'search' => 'y'
	    # }
     #  ,
	    '08/params'=> 
      {
	        'title'=>'Paramètres techniques (Ne pas modifier)',
	        'fieldtype'=>'textarea',
	        'fieldsize'=>'50',
	        'search' => 'y'
	    }
	);
	
#\@
%dm_display_fields = (
	"01/Identifiant"=>"name"
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
my $selfcolg=$self.'&sw='.$sw.'&id='.get_quoted('id');       

$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="colg" value="$colg" />
EOH

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
    print migc_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
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

		if ($dm_dfl{$key}{fieldtype} eq "text_id" || $dm_dfl{$key}{fieldtype} eq "textarea_id" || $dm_dfl{$key}{fieldtype} eq "textarea_id_editor")
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

sub add_embed
{
  my $dbh = $_[0];
  my $id = $_[1];
  
}

sub update_embed
{
  my $dbh = $_[0];
  my $id = $_[1];
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------