#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

$dm_cfg{customtitle} = $migctrad{blocktypes_title};
my $sel = get_quoted('sel');
my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

my %sel_adm_migcms_blocks = sql_line({select=>"id", table=>"scripts", where=>"url LIKE '%adm_migcms_blocks.pl%'"});

$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;

$dm_cfg{wherep} = "";

if($user{id_role} != 1)
{
	$dm_cfg{wherep} = " visible_system != 'y' ";
}

$dm_cfg{table_name} = "migc_blocktypes";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_blocktypes.pl?";
$dm_cfg{add_title} = "Ajouter une zone de blocs";
$dm_cfg{default_ordby} = 'id asc';

%type_bloc_zones = 
(
	'01/pages' =>"Pages",
	'02/mailing' =>"Mailing",
);


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    
		'01/id'=> {
	        'title'=>'ID',
	        'fieldtype'=>'display',
	        'search' => 'y',
			'list_style'=>'width:20px;',
	    }
		,		
		'02/name'=> 
		{
	        'title'=>$migctrad{blocktypes_name},
	        'fieldtype'=>'text',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }	
		,
		'44/visible_system'	=>{'title'=>'Visible seulement par le rôle system','fieldtype'=>'checkbox','default_value'=>'n','search' => 'n','mandatory'=>{"type" => ''},'tab'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','fieldvalues'=>'','hidden'=>0},
	);

	%dm_display_fields = 
	(
		"01/ID"=>"id",
		"02/$migctrad{blocktypes_name}"=>"name",
		"03/$migctrad{blockzonevisiblesystem}"=>"visible_system",
	);

	if($user{id_role} != 1)
	{
		delete $dm_dfl{'44/visible_system'};
		delete $dm_display_fields{'03/'.$migctrad{blockzonevisiblesystem}};
	}

	%dm_lnk_fields = 
	(
	);

	%dm_mapping_list = 
	(
	);

	%dm_filters = (
	);
	
$dm_cfg{'list_custom_action_1_func'} = \&custom_content_edit;


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
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}


sub custom_content_edit
{
	my $id = $_[0];
	my $colg = $_[1];
	my %rec = %{$_[2]};
	
	

	
	my $edit_content = <<"EOH";
		<a href="$config{baseurl}/cgi-bin/adm_migcms_blocks.pl?&id_blocktype=$rec{id}&sel=$sel_adm_migcms_blocks{id}" data-placement="bottom" data-original-title="Modifier le contenu du bloc" data-placement='top' class="btn btn-default "> 
		<i class="fa fa-pencil-square-o fa-fw"></i> </a>
EOH
}

