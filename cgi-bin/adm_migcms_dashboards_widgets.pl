#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use migcrender;

my $id_dashboard=get_quoted('id_dashboard');
$colg = get_quoted('colg') || $config{default_colg};
my $dashboard_name = "";

$dm_cfg{customtitle} = $migctrad{products_management}.' > '.$dashboard_name.' > Widgets';

$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 1;
$dm_cfg{trad} = 0;

$dm_cfg{table_name} = "lnk_dashboards_widgets";
$dm_cfg{wherep_ordby} = $dm_cfg{wherep} = "id_dashboard=$id_dashboard";

$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{wherel} = "id_dashboard=$id_dashboard";
$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
my $self=$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_dashboards_widgets.pl?id_dashboard=$id_dashboard";
#$dm_cfg{after_mod_ref} = \&after_save;
#$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{duplicate}='y';
$dm_cfg{page_title} = "Widgets";

%grid_type = (
			"col-md-1"=>"1/12",
			"col-md-2"=>"2/12",
			"col-md-3"=>"3/12",
			"col-md-4"=>"4/12",
			"col-md-5"=>"5/12",
			"col-md-6"=>"6/12",
			"col-md-7"=>"7/12",
			"col-md-8"=>"8/12",
			"col-md-9"=>"9/12",
			"col-md-10"=>"10/12",
			"col-md-11"=>"11/12",
			"col-md-12"=>"12/12",
		);
		
%grid_color = (
	""=>"Blanc",
	"purple"=>"Violet",
	"deep-purple-box"=>"Violet foncé",
	"red"=>"Rouge",
	"blue"=>"Bleu 1",
	"blue-box"=>"Bleu 2",
	"green"=>"Vert 1",
	"green-box"=>"Vert 2",
);
    
%etapes = (
			"1"=>"1",
			"2"=>"2",
			"3"=>"3",
			"4"=>"4"
		);    

$config{logfile} = "trace.log";
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	'01/id_dashboard'=> 
	{
		'title'=>"ID dasboard",
		'fieldtype'=>'text',
		'hidden'=>1,      
	}
	,
	'02/id_widget' =>{
		'title'=>"Widgets",
		'fieldtype'=>'listboxtable',
		'lbtable'=>'widgets',
		'lbkey'=>'widgets.id',
		'lbdisplay'=>'widgets.name',
	}
	,
	'03/name' =>{
		'title'=>"Nom du widget (facultatif)",
		'fieldtype'=>'text',
		'fieldsize'=>'50',
		'legend'=>"Si champ vide, le nom du widget sera le nom par défaut défini dans les widgets",
	}
	,
	'04/header'=> {
		'title'=>"Afficher le titre",
		'default_value'=>'y',
		'fieldtype'=>'checkbox',
	}
	,
	'05/grid'=> {
		'title'=>"Grilles",
		'fieldtype'=>'listbox',
		'fieldvalues'=>\%grid_type
	}
	,
	'06/color'=> {
		'title'=>"Couleurs",
		'fieldtype'=>'listbox',
		'fieldvalues'=>\%grid_color,
		'legend'=>"Si champ vide, la couleur de fond sera blanche",
	}
	,

);



%dm_display_fields = (
"01/Widget"=>"id_widget",
"02/Grilles"=>"grid",
"03/Couleurs"=>"color",
"04/Titre"=>"header",
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

    if ($sw eq "list") {$spec_bar.=$lnkxls;}
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

sub after_save
{
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------