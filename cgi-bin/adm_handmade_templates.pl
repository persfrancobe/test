#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;


my %user = %{get_user_info($dbh,$config{current_user})} or wfw_no_access();



$dm_cfg{customtitle} = $fwtrad{users_title};
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{dupliquer} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "handmade_templates";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{table_width} = 600;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_handmade_templates.pl?";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;

$dm_cfg{add_title} = "Ajouter un canevas";
$dm_cfg{page_title} = "Canevas de publipostage";



%dm_dfl = (
 
	
	'03/nom'=> 
	{
        'title'=>'Libelle',
        'fieldtype'=>'text',
        'search' => 'y',
        'mandatory'=>{"type" => 'not_empty',
                     }
    }
	,
	 '04/html'=> 
	{
        'title'=>'Code HTML',
         'fieldtype'=>'textarea',
        'mandatory'=>{"type" => 'not_empty',
                     }
    }
	,
	'47/type'=> 
	{
        'title'=>'Type',
         'fieldtype'=>'text',
		 'search' => 'y',
        'mandatory'=>{"type" => 'not_empty',
                     }
    }
);

%dm_display_fields = (
    "1/Libelle"=>"nom",
	"3/Type"=>"type",
);

$dm_cfg{help_url} = "http://www.bugiweb.com";



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
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}




################################################################################

sub get_and_check
{
 my %item; 

foreach $key (keys(%dm_dfl)) { 
  my ($num,$field) = split(/\//,$key);
  $item{$field} = get_quoted($field);
  if (defined $dm_dfl{$key}{mandatory}) {
      if (!check_field_value($item{$field},
                             $dm_dfl{$key}{mandatory}{type},
                             \@{$dm_dfl{$key}{mandatory}{params}}
                             )) {
          dm_check_error($dm_dfl{$key}{title});
      }
  }
 }

 return (\%item);	
}



sub get_form
{
 my %item = %{$_[0]};
 
 my $form = build_form(\%dm_dfl,\%item);

return $form;
}


sub after_save
{
    my $dbh = $_[0];
    my $id = $_[1];
      
	my %license = sql_line({table=>"handmade_selion_licenses",where=>"id='$id'"});
	if($license{license_token} eq '')
	{
	   my $new_token = create_token(50);
	   my $stmt = <<"EOH";
			UPDATE handmade_selion_licenses SET license_token = '$new_token' WHERE id = '$license{id}'
EOH
      execstmt($dbh,$stmt);
    }
	# my $stmt = <<"EOH";
			# UPDATE handmade_selion_licenses SET code_license = CONCAT(SLNACRONYME,id) WHERE id = '$license{id}'
# EOH
      # execstmt($dbh,$stmt);
	
}