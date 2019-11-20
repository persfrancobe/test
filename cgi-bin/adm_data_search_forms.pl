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


$dm_cfg{trad} = 1;
$dm_cfg{customtitle} = <<"EOH";
<a href="$config{baseurl}/cgi-bin/adm_data_search_forms.pl?colg=$colg">$migctrad{data_title_search_forms}</a>   
EOH
$dm_cfg{enable_search} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "data_search_forms";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{after_add_ref}     = \&after_save;
$dm_cfg{after_mod_ref}     = \&after_save;

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?colg=$colg";
$dm_cfg{no_export_excel} = 1;

$dm_cfg{page_title} = 'Formulaire de recherche';
$dm_cfg{add_title} = "Ajouter un formulaire de recherche";

%sens = (
			"asc"=>"ASC",
			"desc"=>"DESC"
		);
    
%methodes = (
			"post"=>"POST",
			"get"=>"GET"
		);    

$dm_cfg{hiddp}=<<"EOH";

EOH
$dm_cfg{custom_style_for_contextual_actions} = "width:160px";

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = 
(
'10/id_textid_name'=> 
{
'title'=>$migctrad{adm_data_search_forms_name},
'fieldtype'=>'text_id',
'search' => 'y',
'mandatory'=>{"type" => 'not_empty'},
}
,
'12/id_data_family'=> 
{
'title'=>'Famille liée',
'fieldtype'=>'listboxtable',
'lbtable'=>'data_families',
'lbkey'=>'data_families.id',
'lbdisplay'=>'data_families.name',
'mandatory'=>{"type" => 'not_empty'},
}
,
'20/id_template'=> 
{
'title'=>'Tpl du formulaire',
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'templates.id',
'lbdisplay'=>'templates.name',
'lbwhere'=>"type = 'search'",
}
,
'21/id_template_page'=> 
{
'title'=>'Tpl Page spécifique',
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'templates.id',
'lbdisplay'=>'templates.name',
'lbwhere'=>"type = 'page'"
}
,
'22/id_template_listing'=> 
{
'title'=>'Tpl listing spécifique',
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'templates.id',
'lbdisplay'=>'templates.name',
'lbwhere'=>"type = 'data'"
}
,
'23/id_template_detail'=> 
{
'title'=>'Tpl detail alternatif',
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'templates.id',
'lbdisplay'=>'templates.name',
'lbwhere'=>"type = 'data'"
}
,
'24/id_template_detail_page'=> 
{
'title'=>'Tpl page pour le detail alternatif',
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'templates.id',
'lbdisplay'=>'templates.name',
'lbwhere'=>"type = 'page'"
}
,
'25/id_template_object'=> 
{
'title'=>'Tpl Objet alternatif',
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'templates.id',
'lbdisplay'=>'templates.name',
'lbwhere'=>"type = 'data'"
}
,
'49/order_field'=> 
      {
          'title'=>'Tri sur le champ de la fiche',
          'fieldtype'=>'listboxtable',
          'lbtable'=>'data_fields',
          'lbkey'=>'id',
          'translate'=>1,
          'lbdisplay'=>'id_textid_name',
          'lbwhere'=>"",
          'lbordby'=>"id_data_family,ordby"
      }
,
'50/custom_ordby'=> 
{
'title'=>'Tri personnalisé',
'fieldtype'=>'text',
}
,
'70/id_textid_url_rewriting'=> 
{
    'title'=>$migctrad{id_textid_url_rewriting},
    'fieldtype'=>'text_id',
    'fieldsize'=>'50',
    'search' => 'n',
	'mandatory'=>{"type" => 'not_empty'},
    
}
,
'71/count_sheets'=> 
{
'title'=>'Précalculer le nombre de résultats pour chaque lien (Ralenti fortement le chargement de la page)',
'fieldtype'=>'checkbox',
'checkedval' => 'y'
}
,
'72/in_sitemap'=> 
{
'title'=>'Dans les URLs du sitemap',
'fieldtype'=>'checkbox',
'checkedval' => 'y'
},

'73/allow_robots'=> 
{
'title'=>'Autoriser le crawling des moteurs de recherche',
'fieldtype'=>'checkbox',
'checkedval' => 'y'
}
,

'75/sort_on_cat'=> 
{
'title'=>'Trier sur la catégorie si possible',
'fieldtype'=>'checkbox',
'checkedval' => 'y'
}
);



%dm_display_fields = 
(
	"01/$migctrad{adm_data_search_forms_name}"=>"id_textid_name"
);

%dm_lnk_fields = 
(
"07//Champs du formulaire"=>"$config{baseurl}/cgi-bin/adm_data_searchs.pl?colg=$colg&id_data_search_form=",
);

%dm_mapping_list = (
);

%dm_filters = (
		);

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
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub before_del
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  $stmt = "DELETE FROM data_searchs WHERE  id_data_search_form='$id'";
  execstmt($dbh,$stmt);
}

sub after_save
{
    my $dbh=$_[0];
    my $id=$_[1];
   
	#traitement URL rew
	my %rec = read_table($dbh,$dm_cfg{table_name},$id);
	my $url_rewriting = get_traduction({id=>$rec{id_textid_url_rewriting},lg=>$config{current_language}});
	$url_rewriting = clean_url($url_rewriting,'y');
	update_text($dbh,$rec{id_textid_url_rewriting},$url_rewriting,$config{current_language});
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------