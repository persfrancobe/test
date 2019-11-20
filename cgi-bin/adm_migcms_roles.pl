#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use def_handmade;
use tools; # home-made package for tools
use dm;


$dm_cfg{enable_search} = 1;
$dm_cfg{deplie_recherche} = 1;
$dm_cfg{enable_multipage} = 1;

$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 0;

$dm_cfg{wherel} = " id >= $user{id_role} AND id != 2 ";

my $sel = get_quoted('sel');

$dm_cfg{table_name} = "migcms_roles";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_roles.pl?";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_dupl_func} = 'after_dupl_role';

$dm_cfg{page_title} = "Roles";

my $link_permissions = "$config{baseurl}/cgi-bin/adm_migcms_roles_permissions.pl?";


%dm_dfl = 
(
	 '12/nom_role'=> 
	{
        'title'=>"Nom",
        'fieldtype'=>'text',
		'search' => 'y',
		'mandatory'=>
		{"type" => 'not_empty',
		}
    }
	
);

%dm_display_fields = (
	"02/Nom"=>"nom_role",
);

%dm_lnk_fields = 
(
"99/Permissions/col_permissions"=>"actions*",
);

%dm_mapping_list = (
"actions" => \&get_actions_roles,
);


%dm_filters = (


);



$sw = $cgi->param('sw') || "list";

see();


$dm_cfg{list_html_top} = <<"EOH";
<script>
jQuery(document).ready(function() 
{
	
	
	
   
});

function custom_func_form()
{
	
}

</script>

EOH

my @fcts = qw(
add_form
mod_form
list
add_db
mod_db
del_db
get_zips
get_cities
get_countries
);


if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}







sub after_save
{
    my $dbh = $_[0];
    my $id = $_[1];
	  
	my $new_token = create_token(50);
	
	my $stmt = <<"EOH";
		  UPDATE migcms_roles
		  SET
			 token = '$new_token'
		  WHERE
			  id = $id
EOH
		execstmt($dbh,$stmt);
}


sub get_actions_roles
{
	my $dbh = $_[0];
    my $id = $_[1];
	
	my %migcms_roles = sql_line({table=>'migcms_roles',where=>"id='$id'"});
	
	
	my $editer = <<"EOH";
	<div class="btn-group_dis clearfix">
		<a href="$link_permissions&token_role=$migcms_roles{token}&sel=$sel" data-placement="top" data-original-title="Modifier les permissions" id="$id" role="button" class=" 
				  btn btn-info $class show_only_after_document_ready">
					  <i class="fa fa-fw fa-key "> 
				  </i>
						  
				  </a>
	</div>
EOH

	
	
	
	return <<"EOH";
		$editer
EOH

}
