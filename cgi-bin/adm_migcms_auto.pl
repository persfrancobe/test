#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use def_handmade;
use tools; # home-made package for tools
use dm;

use fwlayout;
use fwlib;

my %user = %{get_user_info($dbh,$config{current_user})} or wfw_no_access();



if(!(get_quoted('sel') > 0))
{
	print 'no script selected';
	exit;
}

my %sel = read_table($dbh,'scripts',get_quoted('sel'));
if(!($sel{id_admin} > 0))
{
	print 'no admin selected';
	exit;
}

my %migcms_admin = sql_line({debug=>0,debug_results=>0,table=>'migcms_admins',where=>"id='$sel{id_admin}'"});
if(!($migcms_admin{id} > 0) )
{
	print 'no admin found';
	exit;
}

my $admin_table = 'migcms_auto_'.$migcms_admin{id};

$dm_cfg{enable_search} = 1;
$dm_cfg{deplie_recherche} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{duplicate} = 1;
$dm_cfg{operations} = 0;


$dm_cfg{table_name} = $admin_table;
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_auto.pl?";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_dupl_func} = 'after_dupl_role';

$dm_cfg{page_title} = ucfirst($migcms_admin{nom});

%dm_dfl = ();
%dm_display_fields = ();

%types_fieldtype = (
    'text'=>"text",
	'text_id'=>"text_id",
	'textarea'=>"textarea",
	'textarea_id'=>"textarea_id",
	'textarea_editor'=>"textarea_editor",
	'textarea_editor_id'=>"textarea_id_editor",
	'date'=>"text",
	'time'=>"text",
	'euros'=>"text",
	'iban'=>"text",
	'bic'=>"text",
	'listboxtable'=>"listboxtable",
);

%types_datatype = (
    'text'=>"",
	'text_id'=>"",
	'textarea'=>"",
	'textarea_id'=>"",
	'textarea_editor'=>"",
	'textarea_editor_id'=>"",
	'date'=>"date",
	'time'=>"time",
	'euros'=>"euros",
	'iban'=>"iban",
	'bic'=>"bic",
	'listboxtable'=>"",
);


my @migcms_admin_lines = sql_lines({debug=>0,debug_results=>0,table=>'migcms_admin_lines',order=>"ordby",where=>"visible='y' AND id_admin='$migcms_admin{id}'"});
foreach $migcms_admin_line (@migcms_admin_lines)
{
	my %migcms_admin_line = %{$migcms_admin_line};
	my $mandatory = '';
		
	if($migcms_admin_line{obligatoire} eq 'y')
	{
		$mandatory = 'not_empty';
	}
	
	my $ord = $migcms_admin_line{ordby};
	if($ord < 10)
	{
		$ord = '0'.$ord;
	}
	
	

	$dm_dfl{$ord.'/auto_'.$migcms_admin_line{id}} = 
	(
		{
			'title'=>"$migcms_admin_line{nom}",
			'fieldtype'=>"$types_fieldtype{$migcms_admin_line{type}}",
			'datatype'=>"$types_datatype{$migcms_admin_line{type}}",
			'lbtable'=>"$migcms_admin_line{lbtable}",
			'lbdisplay'=>"$migcms_admin_line{lbtable_display}",
			'lbkey'=>"$migcms_admin_line{lbtable_id}",
			'search' => "$migcms_admin_line{in_search}",
			'mandatory'=> {"type" => "$mandatory" },
		}
	);
	
	if($migcms_admin_line{in_list} eq 'y')
	{
		$dm_display_fields{$ord.'/'.$migcms_admin_line{nom}} = 'auto_'.$migcms_admin_line{id};
	}
	
}


 # '12/nom_role'=> 
	# {
        # 'title'=>"Nom",
        # 'fieldtype'=>'text',
		# 'search' => 'y',
		# 'mandatory'=>
		# {"type" => 'not_empty',
		# }
    # }






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
	<a href="$link_permissions&token_role=$migcms_roles{token}&sel=207" data-placement="top" data-original-title="Modifier les permissions" id="$id" role="button" class=" 
				  btn btn-primary $class show_only_after_document_ready">
					  <i class="fa fa-fw fa-key "> 
				  </i>
						  Permissions
				  </a>
EOH

	
	
	
	return <<"EOH";
		$editer
EOH

}
