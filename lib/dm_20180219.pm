package dm;
@ISA = qw(Exporter);
@EXPORT = qw(
%dm_cfg
%dm_import_excel
@dm_nav
%dm_output
%dm_display_fields
%dm_lnk_fields
%dm_mapping_list
%dm_dfl
%dm_filters
%dm_permissions
$dbh_data
$colg
$colg_compare
save_cluf
get_user_info
list
list_body_ajax
list_delete_ajax
list_corbeille_ajax
list_restaurer_ajax
list_changevis_ajax
list_changevislf_ajax
list_changecb_ajax
dm_sauvegarder_recherche
edit_db_refresh_ordby
list_action_globale_show_ajax
list_action_globale_hide_ajax
list_action_globale_delete_ajax
list_action_globale_corbeille_ajax
list_action_globale_restauration_ajax
list_action_globale_pdfzip_ajax
list_action_globale_facturationsysteme_ajax
get_files_in_dir
list_change_ordby_db_ajax
list_get_where
google_map_markers
dm_after_upload_file
ajax_save_elt
save_list_edit
list_files
list_translations
edit_ajax
edit_db_ajax
parag_template
edit_migcms_pics
json_request
display
dm_init
get_gen_buttonbar
get_spec_buttonbar
migc_app_layout
wfw_app_layout
to_sql_date
to_sql_time
resize_pic
sql_radios
sql_listbox
mod_form
add_form
autosave_lf
add_error
custom_get_total_duration
ajax_save_elt
get_setup
logout_db
sql_listbox_ajax
duplicate_simple_record
edit_db_sort_tree_recurse
get_migcms_publish_bar
ajax_data_categories_save_link
datasheets_getstock
migcms_ajax_get_tinymce_data
migcms_update_databases_form
migcms_update_databases_db
migcms_update_databases_ok
quoteh
$today
import_excel
%user
migcms_create_links
migcms_upload

download_file
refresh_files_admin
migcms_do_upload_file
list_del_file
get_migcms_pages_actions
get_operations_div
insert_text
set_new_ordby_linked_files
dupliquer
get_list_of_cols
get_list_of_tables
create_col_in_table
edit_db_refresh_ordby
getcode
get_document_filename
%migcms_role
%migctrad
update_text
insert_text
save_url
clean_linked_files
clean_linked_txtcontents
clean_all_in_table
lock_on
lock_off

get_publish_pdf_html
map_license_fields
send_by_email
send_by_email_db
check_session_validity
get_file_icon
get_migcms_sys
autocomplete_query
link_files_to_records

get_authentification_google
google_linked_db
google_unlinked_db
@dm_actions
get_toggle_cols_db
reset_toggle_cols_db
separ_params
get_toggle_tags_form
migcms_upload
);

use def;
use dm_publish_pdf;
# use dm_cms;
BEGIN
{
    if($dm_cfg{dm_cms} == 1)
	{
		my $module = 'dm_cms';
		my $file = $module;
		$file =~ s[::][/]g;
		$file .= '.pm';
		require $file;
		$module->import;
	}
}
use tools;
use JSON::XS;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use File::Copy;

@dm_actions = 
(
	{
		name=>'Afficher les informations de la page',
		code=>"view",
		icon=>"fa fa-fw fa-eye",
	}
	,
	{
		name=>'Ajouter',
		code=>"addr",
		icon=>"fa fa-fw fa-plus",
	}
	,
	{
		name=>'Modifier',
		code=>"editr",
		icon=>"fa fa-fw fa-pencil",
	}
	,
	{
		name=>'Visualiser le PDF',
		code=>"viewpdf",
		icon=>"fa fa-eye fa-fw ",
	}
	,
	{
		name=>'Télécharger le PDF',
		code=>"telecharger",
		icon=>"fa fa-download fa-fw ",
	}
	,
	{
		name=>'Email',
		code=>"email",
		icon=>"fa fa-paper-plane-o fa-fw",
	}
	,
	{
		name=>'Facturer',
		code=>"facturer",
		icon=>"fa fa-fw fa-eur",
		id_modules=>'169,164,162,161,163',

	}
	,
	{
		name=>'Trier',
		code=>"sort",
		icon=>"fa fa-fw fa-sort",
	}
	,
	{
		name=>'Dupliquer',
		code=>"duplicate",
		icon=>"fa fa-fw fa-copy",
	}
	,
	{
		name=>'Visible/Invisible',
		code=>"visibility",
		icon=>"fa fa-fw fa-eye-slash",
	}
	
	,
	{
		name=>'Créditer',
		code=>"crediter",
		icon=>"fa fa-fw fa-eur btn-danger",
		id_modules=>'169,164,162,161,163',

	}
	,
	{
		name=>'Archiver',
		code=>"corbeille",
		icon=>"fa fa-archive fa-fw",
	}
	,
	{
		name=>'Verrouiller',
		code=>"lock_on",
		icon=>"fa fa-lock fa-fw btn-warning",
	}
	,
	{
		name=>'Déverrouiller',
		code=>"lock_off",
		icon=>"fa fa-unlock-alt fa-fw btn-success",
	}
	,
	{
		name=>'Voir éléments supprimés+Restaurer',
		code=>"restauration",
		icon=>"fa fa-fw fa-history",
	}
	,
	{
		name=>'Supprimer définitivement',
		code=>"deleter",
		icon=>"fa fa-fw fa-trash",
	}
	,
	{
		name=>'Export Excel',
		code=>"excel",
		icon=>"fa fa-file-excel-o",
	}
	,
	{
		name=>'Import + Export Excel',
		code=>"operations",
		icon=>"fa fa-cloud",
	}
	,
	{
		name=>'Télécharger une archive',
		code=>"zip",
		icon=>"fa fa-download",
	}
);

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}
my $colg = get_quoted('force_colg') || get_quoted('colg') || $config{default_colg} || 1;
$colg = int($colg);
if($colg eq '')
{
	$colg=1;
}

my $ICONCANCEL = '<i class="fa fa-fw fa-times-circle-o"></i>';
# my $ICONSAVE = $migctrad{save_action};
my $ICONSAVE = '<i class="fa fa-fw fa fa-floppy-o"></i>';
my $TXTETAPEFINALE = 'Sauvegarder et accéder aux Pièce(s) jointe(s)';

	 
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year+=1900;
$mon++;
$today = sprintf("%.04d",$year).'-'.sprintf("%.02d",$mon).'-'.sprintf("%.02d",$mday);
my $colg_compare = get_quoted('force_colg_compare');
my $sel = get_quoted('sel');
my $base_script = $config{baseurl}.'/cgi-bin/';
my %securite_setup = sql_line({table=>'securite_setup'});
my $user_key = get_quoted('user_key');

#forcer le parmatre sw 
if($cgi->param('sw_priority') ne '')
{
	$cgi->param('sw',$cgi->param('sw_priority'));
}
 
#vérifier/récupérer l'utilisateur

%user = ();
if(
get_quoted('sw') ne 'get_html_document'
&& get_quoted('sw') ne 'get_html_facture'
&& get_quoted('sw') ne 'get_html_nc'
&& get_quoted('sw') !~ /cron/
&& $ENV{_} !~ /cron/
)
{
	%user = %{get_user_info()};
}


%migctrad = ();
if($user{id_language} > 0 && $user{id_language} < 20)
{
}
else
{
	$user{id_language} = 1;
}

my $user_id_language_col = 'lg'.$user{id_language};
my @migcms_trads = sql_lines({debug=>0,debug_results=>0,table=>'migcms_trads',select=>"keyword,$user_id_language_col as traduction"});
foreach $migcms_trad (@migcms_trads)
{
	my %migcms_trad = %{$migcms_trad};
	$migctrad{$migcms_trad{keyword}} = $migcms_trad{traduction};
}
if($config{txt_custom} eq 'y')
{
	my @migcms_trads_custom = sql_lines({debug=>0,debug_results=>0,table=>'migcms_trads_custom',select=>"keyword,$user_id_language_col as traduction"});
	foreach $migcms_trad (@migcms_trads_custom)
	{
		my %migcms_trad = %{$migcms_trad};
		$migctrad{$migcms_trad{keyword}} = $migcms_trad{traduction};
	}
}




BEGIN
{
    if($dm_cfg{migcrender} == 1)
	{
		my $module = 'migcrender';
		my $file = $module;
		$file =~ s[::][/]g;
		$file .= '.pm';
		require $file;
		$module->import;
	}
}
BEGIN
{
    if($dm_cfg{def_handmade} == 1)
	{
		my $module = 'def_handmade';
		my $file = $module;
		$file =~ s[::][/]g;
		$file .= '.pm';
		require $file;
		$module->import;
	}
}
$dbh_data=$dbh;
if($dm_cfg{dbh} eq 'dbh2')
{
    $dbh_data = $dbh2;
}
################################################################################
#     1. LIST
#     2. EDIT
#     3. DISPLAY
#     4. CUSTOMs/OLDs
################################################################################
sub list
{
	$dm_output{content} = get_list();

	if($dm_permissions{view} != 1)
	{
		if($user{id_role} != 1)
		{
			$dm_output{content} = '';
		}
		$dm_output{content} = $migctrad{dm_permissions_view_page}.$dm_output{content};
	}
}
sub add_form
{
    $dm_output{content} = get_list('add');
	# log_debug($dm_output{content});
	
	if($dm_permissions{view} != 1)
	{
		if($user{id_role} != 1)
		{
			$dm_output{content} = '';
		}
		$dm_output{content} = $migctrad{dm_permissions_view_page}.$dm_output{content};
	}	
}

################################################################################
# LIST
################################################################################
sub get_list
{
    my $list_sw = $_[0];
    my $mod_id = $_[1];

	
	#FONCTION ALTERNATIVE POUR PAGE******************************************
	if($dm_cfg{page_func} ne '')
    {
        my $func = 'def_handmade::'.$dm_cfg{page_func};
		return &$func({dm_cfg=>\%dm_cfg,colg=>1});
    }
	
	#CHARGEMENT SCRIPT ET SCRIPT PARENT*******************************************
    my %script = read_table($dbh,"scripts",$sel);
    my %father = ();
    if($script{id_father} > 0)
    {
        %father = read_table($dbh,"scripts",$script{id_father} );
    }
    my $page_title = '';
	my $nom_script_traduit = get_traduction({debug=>0,id=>$script{id_textid_name}});
	if($nom_script_traduit ne '')
	{
		$page_title = $dm_cfg{page_title} = $nom_script_traduit
	}
	elsif($script{name} ne '')
	{
		$page_title = $dm_cfg{page_title} = $script{name};
	}

	my $father = "";
    if($father{id} > 0)
    {
        $father = <<"EOH";
<li><a href="$script{url}&sel=$father{id}" data-original-title="$migctrad{sort_goto} $father{name}"><i class="$icon2{name}"></i> $father{name}</a></li>
EOH
    }
	my $list = '';
	my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
	my $url_home = $migcms_setup{admin_first_page_url};
	
	my $breadcrumb = <<"EOH";
	<ul class="breadcrumb panel">
	<li><a href="$config{baseurl}/cgi-bin/$url_home" data-original-title="$migctrad{backtohome}"><i class="fa fa-home"></i> $migctrad{home}</a></li>
	$father
	<li><a class="current" href="$config{baseurl}/cgi-bin/$script{url}&sel=$sel"><i class="$icon{name}"></i> $page_title</a></li>
</ul>
EOH

	if($dm_cfg{breadcrumb_func} ne '')
	{
		my $fct = $dm_cfg{breadcrumb_func};
        $breadcrumb = &$fct($mod_id,$url_home);
	}
	
	$list .= $breadcrumb;

	#PAGINATION********************************************************************
    my $page = get_quoted('admin_page') || '1';
    my $nr = $dm_cfg{force_nr} || get_quoted('nr') || '25';
    my $debut = (($page-1)*$nr)+1;
    my $fin = $debut + $nr - 1;
	if($dm_cfg{edit_func} eq '')
    {
        $dm_cfg{edit_func} = 'edit_ajax';
    }
    if($dm_cfg{list_func} eq '')
    {
        $dm_cfg{list_func} = 'list_body_ajax';
    }
	if($page == $end_page_max && $page == 1)
    {
        $pagination = '';
    }
	my $edit_func = $dm_cfg{edit_func};
	my $list_func = 'list_body_ajax';
	if($dm_cfg{list_func} ne '' && $dm_cfg{list_func} ne 'list_body_ajax')
    {
		if(
			$dm_cfg{list_func} eq 'list_files'
			|| $dm_cfg{list_func} eq 'list_translations'
			)
		{
			$list_func = $dm_cfg{list_func};
		}
		else
		{
			$list_func = 'def_handmade::'.$dm_cfg{list_func};
		}
    }
	#GET LINES OF CONTENT FOR LIST **************************************************
	my ($list_elts,$pagination,$end_page_max,$info_page,$info_nb_results,$custom_header_func_result,$nbr_box) =  &$list_func({view=>'cgi',colg=>$colg});
	my $migc_list_edit = '';
	
	
	if($list_sw eq 'add')
	{
		$migc_list_edit = edit_ajax({id=>0,render=>'cgi'});
		
	}
	
	#BLOCS MENUS LANGUE***************************************************************
	my $list_languages1 = '<div class="btn-group btn-group-sm">';
    my $list_languages2 = '<div class="btn-group btn-group-sm">';
	my @languages = ();
	if($dm_cfg{trad} == 1)
	{
		@languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible = 'y' || encode_ok = 'y'",ordby=>"id"});
	}
    foreach $language (@languages)
    {
        my %language = %{$language};
        my $class1 = "";
        my $class2 = "";
		if($colg == $language{id})
        {
            $class1="btn-info";
        }
        else
        {
            $class1="btn-default";
        }
		if($colg_compare == $language{id})
        {
            $class2="btn-info";
        }
        else
        {
            $class2="btn-default";
        }
        $language{name} = uc($language{name});
        $list_languages1 .=<< "EOH";
<a href="$dm_cfg{self}&colg=$language{id}" id="$language{id}" class="btn edit_switch_language edit_switch_language1 edit_switch_language1_$language{id} $class1">$language{name}</a>
EOH
        $list_languages2 .=<< "EOH";
<a href="$dm_cfg{self}&colg=$language{id}" id="$language{id}"  class="btn btn-sm edit_switch_language edit_switch_language2 edit_switch_language2_$language{id} $class2">$language{name}</a>
EOH
    }
    $list_languages1 .='</div>';
    $list_languages2 .='</div>';
    my $language_menu = <<"EOH";
<div class="row row-menulg1">
	<div class="col-md-6 lgview text-left">
		$list_languages1
	</div>
	<div class="col-md-6 lgcompareview text-right menu-trad hide">
		<span> $migctrad{compareto} </span> $list_languages2
	</div>
</div>
EOH
	# if($#languages == 0 || !($dm_cfg{trad} == 1))
	if( !($dm_cfg{trad} == 1))
    {
       $language_menu = '<div class="row row-menulg1"></div>';
    }
	#MOTEUR DE RECHERCHE*************************************************************************
    my $formulaire_recherche = '';
	if($dm_cfg{enable_search})
	{
		my $filters = list_get_filters();
		my $in = '';
		if($dm_cfg{deplie_recherche} == 1)
		{
			$in = 'in'; #deplie le menu recherche par défaut
		}
		
		my $class_search_element = 'search_element';
		if($config{disable_mod_on_search} eq 'y')
		{
			$class_search_element = ' ';
		}
		
		
		my $keyword_search = <<"EOH";
<div class="input-group">
	<span class="input-group-addon"><i class="fa-fw fa fa-search"></i></span>
	<input type="text" placeholder="$migctrad{admin_search_button} ..." id="list_keyword" name="list_keyword" class="form-control $class_search_element" />
	<span class="input-group-btn">
		<a class="btn btn-info $class_search_element" id="list_search" data-placement="left" data-original-title="$migctrad{admin_search_button}"><i class=" fa fa-search"></i></a>
		<a class="btn btn-default $class_search_element" id="list_afficher_tout" data-placement="left" data-original-title="$migctrad{reloadall}"><i class="fa fa-undo"></i></a>
	</span>
</div>
EOH
		my $tag_search = '';
		my $list_cols_search = get_list_cols_search();

		if($dm_cfg{tag_search} == 1)
		{
			my $valeurs = '';
			my @valeurs_db = sql_lines({table=>$dm_cfg{tag_table},where=>"visible='y'"});
			foreach $valeur_db (@valeurs_db)
			{
				my %valeur_db = %{$valeur_db};
				$valeur_db{type} =~ s/\"//g;
				$valeur_db{name} =~ s/\"//g;
				
				%valeur_db = %{quoteh(\%valeur_db)};
				$valeurs .= '{ "value": '.$valeur_db{id}.' , "text": "'.$valeur_db{type}.': '.$valeur_db{name}.'"    },';
			}
			
			
			
			my $toggle_tags_form = get_toggle_tags_form();
			
			
			
			
			
			$tag_search = <<"EOH";

	
	<div id="list_tags" name="list_tags" style="padding-top:5px; padding-bottom:5px;padding-right:5px;" >
		
	
		<a class="btn btn-default search_element openmodal get_toggle_tags_form_openmodal"  data-toggle="modal" data-target="#get_toggle_tags_form"><i class="fa fa-tags"></i> Filter par tags </a>
		<span class="tags_preview_container"></span>
		<input type="hidden" placeholder="" id="list_tags_vals" name="list_tags_vals" />
	</div>

	$toggle_tags_form
	
<script>
jQuery(document).ready(function()
{
	/*
	var tags = new Bloodhound(
	{
		datumTokenizer: Bloodhound.tokenizers.obj.whitespace('text'),
		queryTokenizer: Bloodhound.tokenizers.whitespace,
		local:
		[
			$valeurs
		]
	});
	tags.initialize();
	elt = jQuery('#list_tags');
	elt.tagsinput(
	{
		itemValue: 'value',
		itemText: 'text',
		typeaheadjs:
		{
			name: 'tags',
			displayKey: 'text',
			source: tags.ttAdapter()
		}
	});
	elt.on('itemAdded', function(event)
	{
		var list_tags_vals = jQuery("#list_tags").val();
		jQuery("#list_tags_vals").val(list_tags_vals);
		get_list_body();
	});
	elt.on('itemRemoved', function(event)
	{
		var list_tags_vals = jQuery("#list_tags").val();
		jQuery("#list_tags_vals").val(list_tags_vals);
		get_list_body();
	});
	*/
});
</script>
EOH
		}
		if($dm_cfg{keyword_search} == 0)
		{
			$dm_cfg{keyword_search} = '';
		}
		$dm_cfg{select_col_search} = 1;
		my $select_col_search = '';
		
		if($dm_cfg{select_col_search} != 0)
		{
			$select_col_search = <<"EOH";
					<input type="checkbox" name="exact_search" value="y" id="exact_search" /> Rechercher le terme exact  	
					<a href="#" onclick="return false;" data-placement="bottom" data-original-title="= Mot entier entouré d’un espace">
					<i class="fa fa-question-circle-o" aria-hidden="true"></i></a>

				<div class="pull-right text-right get_toggle_cols_search_form" method="POST" action = "">
					<input type="hidden" name="sw" value="get_toggle_cols_search_db" />
					<input type="hidden" name="sel" value="$sel" />
					<input type="hidden" name="self" value="$dm_cfg{self}" />
					<select class="mig_col_search hide " multiple="multiple">
						$list_cols_search
						
					</select>
				
				</div>
EOH
		}
		
		
		$formulaire_recherche = <<"EOH";
<!-- RECHERCHE ET FILTRES -->
<div class="search_panel">
	<div class="row">
		<form id="list_form_search" role="form">
			$keyword_search
			$select_col_search
			$tag_search
			$search_save
			
		</form>
	</div>
	<div class="row">
		$filters
	</div>
</div>
EOH
	}


	#DIV AFFICHAGE**************************************************************************
   	my ($header_line,$dum) = list_map_line_header({class=>'header',line=>\%line});
   	my ($footer_line,$dum) = list_map_line_header({class=>'footer hide',line=>\%line});

if($pagination ne "")
{
	$toppagination = <<"EOH";

<!-- PAGINATION  ET NAVIGATION -->
<div class="row row-pagination">
	<div class="col-md-2 text-left"><span class="admin_list_pagenumber">$info_page</span></div>
	<div class="col-md-8 text-center">
		<div class="pagination_container">
			$pagination
		</div>
	</div>
	<div class="col-md-2 text-right"><span class="admin_list_totalresults">$info_nb_results</span></div>
</div>

EOH
}

	my $migc_list_display = <<"EOH";
$toppagination
<div class="row row-listing">
	<div class="col-md-12 text-left">
		<!-- TABLEAU DE RESULTATS -->
		<section id="no-more-tables">
			<table id="migc4_main_table" class="table table-bordered table-striped table-condensed cf table-hover">
				$header_line
				<tbody id="migc4_main_table_tbody">
					$list_elts
				</tbody>
				$footer_line
			</table>
		</section>
	</div>
</div>
<!-- PAGINATION  ET NAVIGATION -->
<div class="row row-pagination row-pagination-bottom">
	<div class="col-md-4 row_actions_globales">
		<div class="text-left">
EOH
# || $dm_cfg{facturationsysteme}		
		if($dm_cfg{visibility} || $dm_permissions{deleter} || $dm_permissions{corbeille} || $dm_permissions{zip} )
			{
				$migc_list_display .= <<"EOH";
$migctrad{forselection} :
<div id="btn-group-actions_globales">
EOH
				 if($dm_cfg{custom_global_action_func} ne '')
				  {
							  $migc_list_display .= <<"EOH";
<a href="#" id="action_globale_$dm_cfg{custom_global_action_func}" class="action_globale_custom btn btn-default" data-original-title="$dm_cfg{custom_global_action_title}">$dm_cfg{custom_global_action_icon}</a>
EOH
				  }
				  if($dm_cfg{custom_global_action2_func} ne '')
				  {
							  $migc_list_display .= <<"EOH";
<a href="#" id="action_globale_$dm_cfg{custom_global_action2_func}" class="action_globale_custom btn btn-default" data-original-title="$dm_cfg{custom_global_action2_title}">$dm_cfg{custom_global_action2_icon}</a>
EOH
				  }
				   if($dm_cfg{custom_global_action3_func} ne '')
				  {
							  $migc_list_display .= <<"EOH";
<a href="#" id="action_globale_$dm_cfg{custom_global_action3_func}" class="action_globale_custom btn btn-default" data-original-title="$dm_cfg{custom_global_action3_title}">$dm_cfg{custom_global_action3_icon}</a>
EOH
				  }
				  if($dm_cfg{visibility})
				  {
						$migc_list_display .= <<"EOH";
<a href="#" id="action_globale_show" class="btn btn-success" data-original-title="$migctrad{dm_make_visible}"><span class="fa fa-check fa-fw"></span></a>
<a href="#" id="action_globale_hide" class="btn btn-warning" data-original-title="$migctrad{dm_make_invisible}"><span class="fa fa-ban fa-fw"></span></a>
EOH
				  }
				if($dm_permissions{corbeille} && $dm_permissions{restauration} == 1)
				{
					$migc_list_display .= <<"EOH";
<a href="#" id="action_globale_restauration" class="btn btn-default" data-original-title="$migctrad{restore}"><i class="fa fa-history fa-fw"></i></a>
EOH
				}
				  if($dm_permissions{corbeille})
				  {
						  $migc_list_display .= <<"EOH";
<a href="#" id="action_globale_corbeille" class="btn btn-default" style="background-color:#dddddd!important" data-original-title="$migctrad{archive}"><i class="fa fa-archive fa-fw"></i></a>
EOH
				  }
				  if($dm_permissions{zip})
				  {
						  $migc_list_display .= <<"EOH";
<a href="#" id="action_globale_pdfzip" class="btn btn-default" data-original-title="$migctrad{pdfzip}"><i class="fa fa-download fa-fw"></i></a>
EOH
				  }
				  if($dm_cfg{facturationsysteme} == 1 && $dm_cfg{facturer_col_client} ne '' && $dm_cfg{facturer_col_facture} ne '' && $dm_cfg{facturer_col_total} ne '')
				  {
						  $migc_list_display .= <<"EOH";
<a href="#" id="action_globale_facturationsysteme" class="btn btn-default" data-original-title="$migctrad{facturationsysteme}"><i class="fa fa-euro fa-fw"></i></a>
EOH
				  }
				  if($dm_permissions{deleter})
				  {
						  $migc_list_display .= <<"EOH";
<a href="#" id="action_globale_delete" class="btn btn-danger" data-original-title="$migctrad{delete}"><i class="fa fa-trash fa-fw"></i></a>
EOH
				  }
						  $migc_list_display .= <<"EOH";
</div>
EOH
				  }
				  else
				  {
						  $migc_list_display .= <<"EOH";
<br />
<br />
EOH
				  }
	   $migc_list_display .= <<"EOH";
		</div>
	</div>
	<div class="col-md-8 text-right"><span class="pagination_container" >$pagination</span></div>
</div>
<!-- fin list display -->
EOH
	#REPORT PARAMETRERS URLS********************************************************
	my $parametres_url = '';
	my @names = $cgi->param;
	foreach $name ( @names )
	{
		if($name ne '' && $cgi->param($name) ne '')
		{
			$parametres_url .= '<input type="hidden" name="'.$name.'" value="'.$cgi->param($name).'" class="parametre_url parametre_url_'.$name.'" />';
		}
	}
	
	#RESTAURATION
	my $restauration_switch = <<"EOH";
<a class="btn btn-default btn-lg search_element" id="restauration_switch" data-placement="bottom" data-original-title="$migctrad{seedeleteditems}"><i class="fa fa-history fa-fw"></i></a>
EOH
	if($dm_permissions{restauration} != 1)
	{
		$restauration_switch = '';
	}
	
	#EXPORT EXCEL
	my $export_excel = <<"EOH";
<a class="btn btn-default btn-lg search_element" id="export_excel" data-placement="bottom" data-original-title="$migctrad{excel_export}"><i class="fa fa-file-excel-o fa-fw"></i></a>
<a class="btn btn-default btn-lg search_element" id="export_csv" data-placement="bottom" data-original-title="Export CSV">CSV</a>
EOH
	if($dm_permissions{excel} != 1)
	{
		$export_excel = '';
	}
	#AJOUT
	my $title = $dm_cfg{add_title};
	$dm_cfg{add_title} = '';
	if($title eq '')
	{
		$title = 'Ajouter un élément';
	}
	my $ajout = <<"EOH";
<a href="$dm_cfg{self}&sw=add_form" class="btn btn-info btn-lg migadd search_element" data-placement="bottom" data-original-title="$migctrad{add_element}" ><i class="fa fa-plus fa-fw"></i> $dm_cfg{add_title}</a>
EOH
	if(!$dm_permissions{addr})
	{
		$ajout = '';
	}
	if($dm_permissions{excel} != 1 && $dm_permissions{operations} != 1)
	{
		$export_excel = '';
	}
	my $default_ordby = trim($dm_cfg{default_ordby});
	my $operations_button = '';
	if($dm_permissions{operations} == 1)
	{
		$operations_button = <<"EOH";
<a class="btn btn-default btn-lg operations_button search_element" data-placement="bottom" data-original-title="$migctrad{imprtexp_data}"><i class="fa fa-cloud-download"></i><i class="fa fa-cloud-upload"></i></a>
EOH
	}

	if($dm_cfg{main_panel_class} eq "") 
	{
		$dm_cfg{main_panel_class} = "col-sm-12";
	}
	
	my $mig_list_display_class = '';
	$edit_form_container_class = 'hide';
	
	if($list_sw eq 'add')
	{
		$mig_list_display_class = 'hide';
		$edit_form_container_class = '';
		$autoadd = 1;
	}
	
	if($dm_cfg{tree} == 1)
	{
		$formulaire_recherche = '';
	}
	
	my $script_self = $dm_cfg{self};
	$script_self =~ s/$config{baseurl}//g;
	$script_self =~ s/$config{fullurl}//g;
	$script_self = $config{fullurl}.$script_self;

	
	
	
	my $search_save = '';
	my $search_load = '';
	if($dm_cfg{search_save} == 1)
	{
		$search_save = <<"EOH";
			<div class="search_save pull-right text-right navbar navbar-default" style="">
				<div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
					<ul class="nav navbar-nav">
						<li><input class="form-control dm_nommer_recherche" style="width:150px;display:inline;" type="text" placeholder="Nommer la recherche" /> <button type="submit" class="btn btn-default dm_sauvegarder_recherche">Sauvegarder</button> </li>
					</ul>
				</div>
			</div>
EOH

	my $liste_recherches = '';
	
	if(0)
	{
	my @migcms_recherches_sauvegardees = sql_lines({table=>'migcms_recherches_sauvegardees',where=>"id_user='$user{id}' AND name !='' AND id_script = '$sel' AND visible='y'",ordby=>"name",limit=>"0,10"});
	foreach $migcms_recherches_sauvegardee (@migcms_recherches_sauvegardees)
	{
		my %migcms_recherches_sauvegardee = %{$migcms_recherches_sauvegardee};
		
		$migcms_recherches_sauvegardee{keywords} =~ s/\"//g;
		$migcms_recherches_sauvegardee{tags} =~ s/\"//g;
		$migcms_recherches_sauvegardee{tags} =~ s/\|//g;
		
		my $tags = '';
		my @ids = split('\,',$migcms_recherches_sauvegardee{tags});
		foreach my $id (@ids)
		{
			if($id > 0)
			{
				my %tag = sql_line({table=>$dm_cfg{tag_table},where=>"id='$id'"});
				$tags .= $tag{type}.' '.$tag{name}.'|'.$tag{id}.',';
			}
		}
				
		$liste_recherches .= <<"EOH";
			<li><a href="#" class="dm_charger_recherche" id="" data-keywords="$migcms_recherches_sauvegardee{keywords}" data-tags="$tags">$migcms_recherches_sauvegardee{name}</a></li>
EOH
	}
	}

	$search_load = <<"EOH";
				<div class="search_save pull-right text-right navbar navbar-default" style="border-color:#ccc!important;background-color:white!important;min-height:45px!important;height:45px!important;">
					<div class="collapse navbar-collapse" id="bs-example-navbar-collapse-1">
						<ul class="nav navbar-nav">
							<li class="dropdown">
								<a href="#" class="dropdown-toggle dropdown-charger-recherche " data-toggle="dropdown" role="button" aria-haspopup="true" aria-expanded="false" data-placement="bottom" data-original-title="Charger une recherche sauvegardée"> <i class="fa fa-search" aria-hidden="true"></i> Recherches
 <span class="caret"></span></a>
							<ul class="dropdown-menu dropdown-menu-right">
								$liste_recherches
							</ul>
							</li>
						</ul>
					</div>
				</div>
EOH

			if(1 || $#migcms_recherches_sauvegardees == -1)
			{
				$search_load = '';
			}
		
		}
	
	$list .= <<"EOH";
<div class="wrapper">
	<!-- Paramètres via URL -->
	$parametres_url
	<!-- LIST HTML TOP -->
	$dm_cfg{list_html_top}
	<!-- Header -->
	<div class="header-actions">
		<div class="row">
			<div class="col-lg-4">
				<h1 class="maintitle">$dm_cfg{page_title}</h1>
			</div>
			<div class="col-lg-8 text-right">
				$ajout
				$export_excel
				$operations_button
				$restauration_switch
				$search_load
				$dm_cfg{custom_navbar}
			</div>
		</div>
	</div>
	<!-- Formulaire de recherche -->
	$formulaire_recherche
	<!-- Panneau principal -->

	<div class="row">
	$dm_cfg{before_main_panel_html}
	<div class="$dm_cfg{main_panel_class}">

		<!-- Menu langues -->
		$language_menu

		<section class="panel">
		
		$dm_cfg{panel_html_top}
		
			<!-- Body -->
			<div class="panel-body">
				<!-- Ecran listing -->
				<div id="mig_list_display" class="$mig_list_display_class">
					<!-- Listing -->
					$migc_list_display
					$search_save
				</div>
				<!-- Ecran édition -->
				<div id="edit_form_container" class="$edit_form_container_class">
					$migc_list_edit
				</div>
				<!-- LIST HTML BOTTOM -->
				$dm_cfg{list_html_bottom}
			</div>
		</section>
	</div>
	</div>
</div>
<!-- Box flottante de tri -->
<div id="sorting_box">
   <div class="btn-group">
		<button class="btn" id="sorting_box_first"><i class="fa fa-fast-backward"></i></button>
		<button class="btn" id="sorting_box_previous"><i class="fa fa-backward"></i></button>
		<button class="btn" id="sorting_box_next"><i class="fa fa-forward"></i></button>
		<button class="btn" id="sorting_box_last"><i class="fa fa-fast-forward"></i></button>
	</div>
	<div class="form-group">
		<label for="new_ordby" class="control-label"></label>
		<div class="controls">
			<input type="text" placeholder="$migctrad{new_position}" id="new_ordby" class="form-control">
			<input type="hidden" placeholder="" id="new_ordby_id">
		</div>
	</div>
	<div class="btn-group">
		<button class="btn btn-default close_sorting_box"><i class="icon-remove"></i> $migctrad{close} </button>
		<button class="btn btn-success save_sorting_box"><i class="icon-ok"></i> OK</button>
	</div>
</div>
<input type="hidden" name="self" id="self" value="$dm_cfg{self}" />
<input type="hidden" name="baseurl" id="baseurl" value="$config{baseurl}" />
<input type="hidden" name="fullurl" id="fullurl" value="$config{fullurl}" />
<input type="hidden" name="script_self" id="script_self" value="$script_self" />
<input type="hidden" name="user_key" id="user_key" value="$user{token}" />
<input type="hidden" name="myself" id="myself" value="$dm_cfg{self}" />
<input type="hidden" name="page" id="page" class="page" value="$page" />
<input type="hidden" name="sort_field_name" id="sort_field_name" value="$sfn" />
<input type="hidden" name="sort_field_sens" id="sort_field_sens" value="$sfs" />
<input type="hidden" name="table_name" id="table_name" value="$dm_cfg{table_name}" />
<input type="hidden" name="javascript_custom_func_form" id="javascript_custom_func_form" value="$dm_cfg{javascript_custom_func_form}" />
<input type="hidden" name="javascript_custom_func_listing" id="javascript_custom_func_listing" value="$dm_cfg{javascript_custom_func_listing}" />
<input type="hidden" name="nrdisabled" id="nrdisabled" value="$nr" />
<input type="hidden" name="last_page" id="last_page" value="$end_page_max" />
<input type="hidden" name="sort_opt" id="sort_opt" value="$dm_cfg{sort}" />
<input type="hidden" name="no_drag_sort" id="no_drag_sort" value="$dm_cfg{no_drag_sort}" />
<input type="hidden" name="inline_edit" id="inline_edit" value="$dm_cfg{inline_edit}" />
<input type="hidden" name="mig_file_selected" id="mig_file_selected" value="" />
<input type="hidden" name="inline_edit_html" id="inline_edit_html" value="$dm_cfg{inline_edit_html}" />
<input type="hidden" name="edit_func" id="edit_func" value="$dm_cfg{edit_func}" />
<input type="hidden" name="list_func" id="list_func" value="$dm_cfg{list_func}" />
<input type="hidden" name="autocreation" id="autocreation" value="$dm_cfg{autocreation}" />
<input type="hidden" name="file_prefixe" id="file_prefixe" value="$dm_cfg{file_prefixe}" />
<input type="hidden" name="default_ordby" id="default_ordby" value="$default_ordby" />
<input type="hidden" name="restauration_active" id="restauration_active" value="0" />
<input type="hidden" name="list_sw" id="list_sw" value="$list_sw" />
<input type="hidden" name="mod_id" id="mod_id" value="$mod_id" />
<input type="hidden" name="upload_file_type_only" id="upload_file_type_only" value="$dm_cfg{upload_file_type_only}" />
<input type="hidden" name="upload_file_size_min" id="upload_file_size_min" value="$dm_cfg{upload_file_size_min}" />
<input type="hidden" name="nr" id="nr" value="25" />
<input type="hidden" name="autoadd" class="autoadd" value="$autoadd" />
<input type="hidden" name="migcms_parag_inline_edit" id="migcms_parag_inline_edit" value="$dm_cfg{migcms_parag_inline_edit}" />



EOH
    
	 
	  
	  return $list;
}

sub import_excel
{
	# log_debug('import_excel','vide','import_excel');
	if ($dm_cfg{before_import_ref} ne "")
	{
		$fct = $dm_cfg{before_import_ref};

		&$fct($dbh_data,$new_id,'all');
		# log_debug("$dm_cfg{before_import_ref} appelée",'','import_excel');
	}
	
	# my $debug_limit = 10;
	
	use Encode;
	use HTML::Entities;
	my $file = $cgi->param("import_excel");
	my $code_error = 0;
    my ($file_url, $size);
    # upload du fichier
    if($file ne "")
    {
        ($file_url,$size) = upload_file($file,$config{directory_path}.'/usr/documents');
        if($file_url eq "" || $size eq "")
        {
            # Erreur lors de l'upload
            $code_error = 2;
			# log_debug("Erreur lors de l'upload de ".$config{directory_path}.'/usr/documents'.": $file_url,$size",'','import_excel');
        }
		else
		{
			# log_debug("Ok pour l'upload de ".$config{directory_path}.'/usr/documents'.": $file_url,$size",'','import_excel');
		}
		my $outfile = '../usr/documents/'.$file_url;

		if ($file =~ /\.txt$/i)
		{
			#IMPORT TEXTE********************************************************************************
			open my $fh, '<', $outfile or die "$migctrad{cantopen} $outfile: $!";
			my $secu = 1;
			while ( my $line = <$fh> )
			{
				chomp;
				if($secu)
				{
					$secu = 0;
					next;
				}
				my @row = split( "\t", $line );
				my $num_col = 0;
				my %update_record = ();
				my @excel_keys = sort keys %dm_import_excel;
				if($#excel_keys > -1)
				{
				}
				else
				{
					# see();
					#si via dm dfl
					 my $excel_col = 0;
					  foreach $dm_dfl_line (sort keys %dm_dfl)
					  {
						  my ($num,$field) = split(/\//,$dm_dfl_line);
						  my %cell_infos = %{$dm_dfl{$dm_dfl_line}};
						  if($field ne '')
						  {
								my $col_value = '';
								my $traductible = 0;
								my $cb = 0;
								my $field_name = '';
								my $name = '';
								my $type = '';
								my $subtype = '';
								my $data_type = '';
								my $inline_edit = '';
								my $rec_field_name = '';
								my $rec_field_line = '';
								my $multiple = 0;
								my $spec = '';
								my $lbtable = '';
								my $lbkey = '';
								my $lbdisplay = '';
								my %line = ();
								foreach $field_line (sort keys %dm_dfl)
								{
									($ordby,$field_name) = split(/\//,$field_line);
									if($field_name eq $field)
									{
									   %line = %{$dm_dfl{$field_line}};
									   $type =  $line{fieldtype};
									   $list_style = $line{list_style};
									   $subtype = $line{subtype};
									   $data_type = $line{data_type};
									   $inline_edit = $line{inline_edit};
									   $multiple = $line{multiple};
									   $lbtable = $line{lbtable};
									   $lbkey = $line{lbkey};
									   $lbdisplay = $line{lbdisplay};
									   $rec_field_name = $field_name;
									   $rec_field_line = $field_line;
									   if($inline_edit == 1)
									   {
										  $spec = 'inline_edit';
									   }
									}
								}
								if($rec_field_name eq 'id' || $rec_field_name eq 'id')
								{
										my $excel_value_display = trim(encode("utf8",$row[$num_col]));
										$excel_value_display = decode_entities($excel_value_display);
										$excel_value_display =~ s/\D//g;
										$excel_value_display =~ s/\'/\\\'/g;
										$update_record{$field} = $excel_value_display;
								}
								elsif($type eq 'listbox' || $type eq 'text' || $type eq 'display' || $type eq 'textarea')
								{
										my $excel_value_display = trim(encode("utf8",$row[$num_col]));
										$excel_value_display = decode_entities($excel_value_display);
										$excel_value_display =~ s/\'/\\\'/g;
										$update_record{$field} = $excel_value_display;
										# print "<span style='color:red'>$excel_value_display</span>";
										if($update_record{$field} ne '')
										{
											$vide = 0;
										}
								}
								elsif($type eq 'listboxtable')
								{
										my $excel_value_display = trim(encode("utf8",$row[$num_col]));
										$excel_value_display = decode_entities($excel_value_display);
										$excel_value_display =~ s/\'/\\\'/g;
										# print "<span style='color:red'>$excel_value_display</span>";
										my %record_from_display = sql_line({debug=>0,table=>$lbtable,where=>" $lbdisplay = '$excel_value_display' "});
										$update_record{$field} = $record_from_display{$lbkey};
										# print " [$excel_value_display][$record_from_display{$lbkey}]";
										if($update_record{$field} ne '')
										{
											$vide = 0;
										}
								}
								$num_col++;
						  }
					  }
				}
				if($vide == 0)
				{
					if($dm_permissions{sort})
					{
						$update_record{ordby} = $ordby++;
					}
					if($dm_cfg{excel_key} ne 'id')
					{
						delete $update_record{id};
					}
					if($dm_cfg{excel_key} ne '')
					{
						#si cle: insert or update
						my $id_record = sql_set_data({debug=>0,dbh=>$dbh_data,table=>$dm_cfg{table_name},data=>\%update_record, where=>"$dm_cfg{excel_key} = '$update_record{$dm_cfg{excel_key}}'"});
					}
					else
					{
						#sinon insert
						inserth_db($dbh,$dm_cfg{table_name},\%update_record);
					}
				}
			}
			close($fh);
			# exit;
		}
		elsif ($file =~ /\.xls$/i)
		{
			# log_debug('import666','','import666');
			
			#IMPORT EXCEL *******************************************************************************
			$number = 0;
			my %letter_to_col = ();
			foreach my $lettre ('A'..'Z')
			{
				$letter_to_col{$lettre} = $number++;
			}

			my $parser   = Spreadsheet::ParseExcel->new();
			my $workbook = $parser->parse($outfile) || die 'cannont open '.$outfile;
			if ( !defined $workbook )
			{
				die $parser->error(), ".\n";
			}
			my $worksheet = $workbook->worksheet(0);
			# On boucle sur les lignes du fichier excel
			my $ordby = 1;
			my @excel_keys = sort keys %dm_import_excel;
			# log_debug("Fichier import: $#excel_keys clés détectées",'','import_excel');

			foreach my $row (1 .. 10000000)
			{
				my %update_record = ();
				my $vide = 1;
				if($debug_limit > 0 && $debug_limit < $row)
				{
					last;
				}
				#si via dm import excel
				if($#excel_keys > -1)
				{

					# log_debug('keys','','import666');
					foreach my $letter (keys %dm_import_excel)
					{
						my $col = $letter_to_col{$letter};
						$update_record{$dm_import_excel{$letter}{field}} = import_excel_cell({
																				field => $dm_import_excel{$letter}{field},
																				type=> $dm_import_excel{$letter}{type},
																				row=>$row,
																				col=>$col,
																				lbtable => $dm_import_excel{$letter}{lbtable},
																				lbkey => $dm_import_excel{$letter}{lbkey},
																				lbdisplay => $dm_import_excel{$letter}{lbdisplay},
																				},$worksheet);


						if(trim($update_record{$dm_import_excel{$letter}{field}}) ne '')
						{
							$vide = 0
						}

					}
				}
				else
				{
					# log_debug('dm_dfl','','import666');
					 #si via dm dfl
					 my $excel_col = 0;
					 foreach $dm_dfl_line (sort keys %dm_dfl)
					  {
						  my ($num,$field) = split(/\//,$dm_dfl_line);
						  my %cell_infos = %{$dm_dfl{$dm_dfl_line}};
						  if($field ne '')
						  {
								my $col_value = '';
								my $traductible = 0;
								my $cb = 0;
								my $field_name = '';
								my $name = '';
								my $type = '';
								my $subtype = '';
								my $data_type = '';
								my $importcode = '';
								my $inline_edit = '';
								my $rec_field_name = '';
								my $rec_field_line = '';
								my $multiple = 0;
								my $spec = '';
								my $lbtable = '';
								my $lbkey = '';
								my $lbdisplay = '';
								my %line = ();
								foreach $field_line (sort keys %dm_dfl)
								{
									($ordby,$field_name) = split(/\//,$field_line);
									# log_debug("$field_name eq $field");
									if($field_name eq $field)
									{
									   %line = %{$dm_dfl{$field_line}};
									   $type =  $line{fieldtype};
									   $list_style = $line{list_style};
									   $subtype = $line{subtype};
									   $data_type = $line{data_type};
									   $inline_edit = $line{inline_edit};
									   $multiple = $line{multiple};
									   $lbtable = $line{lbtable};
									   $importcode = $line{importcode};
									   $lbkey = $line{lbkey};
									   $lbdisplay = $line{lbdisplay};
									   $rec_field_name = $field_name;
									   $rec_field_line = $field_line;
									   if($inline_edit == 1)
									   {
										  $spec = 'inline_edit';
									   }
									}
								}
								# log_debug("field:[$field],type:[$type]",'','import_excel');

								if($type ne 'files_admin' && $type ne 'titre' && $type ne 'button')
								{
									$update_record{$field} = import_excel_cell({
																					field => $field,
																					type=>$type,
																					row=>$row,
																					col=>$excel_col,
																					lbtable => $lbtable,
																					lbkey => $lbkey,
																					lbdisplay => $lbdisplay,
																					data_type => $data_type,
																					importcode => $importcode,
																					},$worksheet);
									if($update_record{$field} ne '')
									{
										$vide = 0;
									}
								}
								$excel_col++;
						  }
					  }
				}
				
				if($vide == 0)
				{
					# log_debug('pasvide','','import666');
					

					if($dm_permissions{sort})
					{
						$update_record{ordby} = $ordby++;
					}

					my $id_record = 0;
					if($dm_cfg{excel_key} ne '')
					{
						#si cle: insert or update
						$update_record{migcms_moment_last_edit} = 'NOW()';
						$update_record{migcms_id_user_last_edit} = $user{id};
						
						#on passe eventuellement le rencord qui doit etre ajoute ou modifie à une fonction qui va calculer la valeur de la clé
						if($dm_cfg{excel_key_func} ne '')
						{
							my $fct_make_key = $dm_cfg{excel_key_func};
							$update_record{$dm_cfg{excel_key}} = &$fct_make_key(\%update_record);
						}
						%update_record = %{quoteh(\%update_record)};	
						# log_debug('exck','','import666');
						# use Data::Dumper;
						# log_debug('exck','','import666');
						$id_record = sql_set_data({debug=>0,dbh=>$dbh_data,table=>$dm_cfg{table_name},data=>\%update_record, where=>"$dm_cfg{excel_key} = '$update_record{$dm_cfg{excel_key}}'"});
						# log_debug('exck :'.$id_record,'','import666');
					}
					else
					{
						#sinon insert
						foreach my $key (keys %update_record)
						{
							$update_record{$key} =~  s/\'//g;
						}
						$id_record = inserth_db($dbh,$dm_cfg{table_name},\%update_record);
					}
					if($dm_cfg{after_ligne_import_ref} ne "")
					{
						$fct = $dm_cfg{after_ligne_import_ref};
						&$fct($id_record);
					}
				}
				else
				{
					# log_debug('vide','','import666');
					my $sel = get_quoted('sel');
					$dm_cfg{self} = $dm_cfg{self}.'&sel='.$sel;
					if ($dm_cfg{after_import_ref} ne "")
					{
						$fct = $dm_cfg{after_import_ref};

						&$fct($dbh_data,$new_id,'all');
					}
					http_redirect($dm_cfg{self});
					exit;
				}
			}
		}
    }
	else
	{
		# log_debug('fichier vide','','import_excel');
	}
	# if(trim($dm_cfg{after_import_excel}) ne "")
	# {
		# $fct = 'def_handmade::'.trim($dm_cfg{after_import_excel});
		# &$fct($dbh_data,$new_id,'all');
	# }
	my $sel = get_quoted('sel');
	$dm_cfg{self} = $dm_cfg{self}.'&sel='.$sel;
	if ($dm_cfg{after_import_ref} ne "")
	{

		$fct = $dm_cfg{after_import_ref};
		&$fct($dbh_data,$new_id,'all');
	}
	http_redirect($dm_cfg{self});
}



sub import_excel_cell
{
	my %d = %{$_[0]};

	my $field = $d{field};
	my $type = $d{type};
	my $excel_col = $d{col};
	my $row = $d{row};
	my $lbtable = $d{lbtable};
	my $lbkey = $d{lbkey};
	my $lbdisplay = $d{lbdisplay};
	my $data_type = $d{data_type};
	my $importcode = $d{importcode};
	my $worksheet = $_[1];
	
	# log_debug("type recu:[$type]",'','import_excel');

	if($type eq '')
	{
		$type = 'text';
	}
	# log_debug("type recu2:[$type]",'','import_excel');
	my %update_record = ();


	if($type eq 'listbox' || $type eq 'text' || $type eq 'checkbox' || $type eq 'display' || $type eq 'textarea' || $type eq 'text_id' || $type eq 'textarea_id' || $type eq 'textarea_id_editor')
	{
		my $cell = $worksheet->get_cell($row, $excel_col);
		if($cell ne "")
		{
			my $excel_value = trim(encode("utf8",$cell->value()));
			if($excel_value ne '')
			{
				# log_debug($excel_value,'','debug_import_excel');
			}
			my $excel_value = $cell->value();
			if($excel_value ne '')
			{
				# log_debug($excel_value,'','debug_import_excel');
			}
			if($field eq 'id' || $field eq 'id_father')
			{
				$excel_value =~ s/\D//g;
			}
			$excel_value = decode_entities($excel_value);
			$excel_value = encode_entities($excel_value);
			
			if($excel_value ne '')
			{
				# log_debug($excel_value,'','debug_import_excel');
			}
			# $excel_value =~ s/[^a-zA-Z\s0-9\,\'\"\)\(\]\[\/\éèïöüâîàù&]//g;
			# $excel_value =~ s/[^a-zA-Z\s0-9\,\'\"\)\(\]\[\/\éèïöüâîàù&]//g;
			$excel_value =~ s/\?//g;

			# $update_record{$field} = clean_avec_accents(trim($excel_value));
			$update_record{$field} = trim($excel_value);
			
			if($excel_value ne '')
			{
				# log_debug($update_record{$field},'','debug_import_excel');
			}
			# $update_record{$field} =~ s/[^A-Za-z0-9éèïöüâîàù\']//g;
			# if($dm_cfg{import_encode_entities} ne 'y')
			# {
				# $update_record{$field} =~ s/[^\x00-\x7Féèïöüâîàù&;\s]//g;
				# $update_record{$field} =~ s/[^A-Za-z0-9\-\.\:\,\(\)\/\\\@\_éèïöüâîàù&;\s]//g;
				
				# $update_record{$field} =~ s/\&nbsp\;//g;
				# $update_record{$field} =~ s/\&eacute\;/é/g;
				# $update_record{$field} =~ s/\&Eacute\;/E/g;
				# $update_record{$field} =~ s/\&eagrave\;/è/g;
				# $update_record{$field} =~ s/\&icirc\;/î/g;
				# $update_record{$field} =~ s/\&Agrave\;/A/g;
				# $update_record{$field} =~ s/\&agrave\;/à/g;
				# $update_record{$field} =~ s/\&Ccedil\;/C/g;
				# $update_record{$field} =~ s/\&Ocirc\;/O/g;
				
				# $update_record{$field} =~ s/\&39\;/\'/g;
				# $update_record{$field} =~ s/\&amp\;/\&/g;
				# $update_record{$field} =~ s/\'/\\\'/g;
				
				# $update_record{$field} = decode_entities($update_record{$field});
			# }
			if($excel_value ne '')
			{
				# log_debug($field.':'.$update_record{$field},'','debug_import_excel');
			}
			if($data_type eq 'date')
			{
				$update_record{$field} = compute_sql_date($excel_value);
			}
			
			if($type eq 'text_id' || $type eq 'textarea_id' || $type eq 'textarea_id_editor')
			{
				#si traductible: insertion traduction et valeur -> id traduction
				$update_record{$field} = set_traduction({id_language=>1,traduction=>$update_record{$field}});
			}
			
				# log_debug("valeur:[".$update_record{$field}."]",'','import_excel');

			
			if(trim($excel_value) ne '')
			{
				$vide = 0;
			}
		}
		else
		{
			$update_record{$field} = '';
		}
	}
	elsif($type eq 'listboxtable')
	{
		# log_debug("$type eq 'listboxtable'",'','import_excel');

		my $cell = $worksheet->get_cell($row, $excel_col);
		if($cell ne "")
		{
			my $excel_value_display = $cell->value();
			# log_debug("LBT VAL1:[".$excel_value_display."]",'','import_excel');
			
			if($excel_value_display ne '%' && $excel_value_display ne '€')
			{
				$excel_value_display = trim(encode("utf8",$cell->value()));
				$excel_value_display = decode_entities($excel_value_display);
				$excel_value_display =~ s/\'/\\\'/g;
			}
			# log_debug("LBT VAL2:[".$excel_value_display."]",'','import_excel');
			my %record_from_display = sql_line({debug=>0,debug_results=>0,table=>$lbtable,where=>" $lbdisplay = '$excel_value_display' "});
			# log_debug('LISTBOXTABLE, excel_value_display:'.$excel_value_display.','.'lbtable:'.$lbtable.'importcode:'.$importcode,'','debug_import_excel');
			# log_debug($excel_value_display,'','debug_import_excel');
			
			#import via la clé étrangère nettoyée
			if($importcode == 1)
			{
				my @ics = split('\s',trim($excel_value_display));
				my $ic = $ics[0];
				$ic =~ s/\D//g;
				# log_debug('Identifiant:'.$ic,'','debug_import_excel');
				if($ic > 0)
				{
					# log_debug('Clé:'.$lbkey,'','debug_import_excel');
					# log_debug("LBT VAL ID:[".$ic."]",'','import_excel');
					%record_from_display = sql_line({debug=>0,debug_results=>0,table=>$lbtable,where=>" $lbkey = '$ic' "});
					# log_debug($lbkey.':'.$record_from_display{$lbkey},'','debug_import_excel');
				}
			}
			# log_debug("LBT VAL3:[".$record_from_display{$lbkey}."]",'','import_excel');
			
			$update_record{$field} = $record_from_display{$lbkey};
			if(trim($update_record{$field}) ne '')
			{
				$vide = 0;
			}
		}
		else
		{
			# log_debug("CELL VIDE ($row, $excel_col)",'','import_excel');
		}
	}
	else
	{
		# log_debug("type recu inconnu !:[$type]",'','import_excel');
	}

	# $update_record{$field} = decode_entities($update_record{$field});
	return $update_record{$field};
}



################################################################################
# list_changevis_ajax
################################################################################
sub list_map_line_header
{
    my %d = %{$_[0]};

	my $balise = 'thead';
	if($d{class} eq 'footer' || $d{class} eq 'footer hide')
	{
		$balise = 'tfoot';
	}

    my $line = <<"EOH";
<$balise class="cf">
<tr class="mig_th_$d{class}">
	<th class="mig_cb_col mig_cb_col_$d{class}" data-noresize><input type="checkbox" id="check_all_cb" class="check_all_cb form-control" name="all" /></th>
EOH
    if($dm_permissions{sort})
    {
        $line .= <<"EOH";
	<th class="list_ordby_header widget-header" data-noresize><span class="btn-block">$migctrad{order}</span></th>
EOH
    }
	if($config{dm_show_id} == 1 || $dm_cfg{show_id} == 1)
	{
        my $sorting_class = 'sorting';
		my $sorting_icon = '<span class="sorting_icon"><i class="fa fa-sort"></i></span>';
		my $fieldname = 'Identifiant';
		my $field = 'id';


		$line .= <<"EOH";
<th class="widget-header cms_mig_cell_$field cms_mig_cell_data_type_$info"><a href="" class="col_header_$info btn-block $sorting_class" id="id">$sorting_icon $fieldname</a></th>

EOH
	}
    my %fields = (%dm_display_fields,%dm_lnk_fields);
    my $are_links = 0;
    my $col_count = 1;
    foreach $field (sort keys %fields )
    {
        my $col = $dm_display_fields{$field};
        my $link_or_func = $dm_lnk_fields{$field};
        if($col ne '')
        {
            my $sorting_class = 'sorting';
			my $sorting_icon = '<span class="sorting_icon"><i class="fa fa-sort"></i></span>';
            my ($num,$fieldname) = split(/\//,$field);
			$info = get_data_type($fields{$field});
		$line .= <<"EOH";
	<th class="widget-header cms_mig_cell_$field cms_mig_cell_data_type_$info"><a href="" class="col_header_$info btn-block $sorting_class" id="$col">$sorting_icon $fieldname</a></th>
EOH
            $col_count++;
        }
        else
        {
            #DM LNK FIELDS (LINK OR FUNC)#######################################
            my $type = '';
            my $link_or_func = $dm_lnk_fields{$field};
            if($link_or_func =~ /^http/ || $link_or_func =~ /^\// || $link_or_func =~ /^\.\.\//)
            {
				my ($dum,$dum,$info) = split(/\//,$field);
#               #LINK***********************************************************
                my $menu_id_selected1 = get_quoted('mis') || '1';
                my $menu_id_selected2 = get_quoted('mis2') || '';
                my $id_col = $dm_cfg{id_col} || 'id';
                my $link = $link_or_func.$d{line}{$id_col}.'&colg='.$colg;
                $are_links = 1;
            }
            elsif($link_or_func =~ /\*$/)
            {
                #FUNC***********************************************************
                my $hidden_class='';
                if($col_count > 5)
                {
                    $hidden_class = 'hidden-phone';
                }
                my ($num,$fieldname,$info) = split(/\//,$field);
                $line .= <<"EOH";
	<th data-noresize class="header_$info widget-header $hidden_class widget-header-func"><span class="btn-block">$fieldname</span></th>
EOH
                $col_count++;
            }
        }
    }
    if($are_links)
    {
       $line .= <<"EOH";
	<th data-noresize class="widget-header list_action_supp list_action" style="$dm_cfg{custom_style_for_contextual_actions}"></th>
EOH
    }
    if($dm_permissions{sort} || $dm_cfg{visibility} || $dm_permissions{editr} || $dm_permissions{deleter} || $dm_permissions{corbeille} || $dm_permissions{duplicate})
    {
       $line .= <<"EOH";
	<th data-noresize class="widget-header widget-header-actions"></th>
EOH
    }
   $line .= <<"EOH";
</tr>
</$balise>
EOH
    return ($line,$onebuttonmenu);
}
################################################################################
# list_get_specific_fields
################################################################################
sub list_get_specific_fields
{
    my %d = %{$_[0]};
	
	$d{list_col_search} =~s/\,$//g;
	$d{list_col_search} = trim($d{list_col_search});
	my @col_searchs = split(/\,/,$d{list_col_search});
		
	
    my @where_fields = ();
    my $specific_fields = '';
    my %specific_fields = ();
	
	#choisir les champs selon dm_dfl	
    foreach my $field_line (sort keys %dm_dfl)
    {
        my ($ordby,$field) = split(/\//,$field_line);
		if($dm_dfl{$field_line}{search} eq 'y')
        {
             push @where_fields, $field;
			$specific_fields{$dm_dfl{$field_line}{title}} = $field;
        }
    }
	
	#choisir les champs selon col_search
	if($#col_searchs > -1)
	{
		@where_fields = ();
		foreach my $col_search (@col_searchs)
		{
				push @where_fields, $col_search;
		}
	}
	
	push @where_fields, 'migcms_id';
	
    foreach my $field (sort keys %specific_fields)
    {
        $specific_fields .= '<option value="'.$specific_fields{$field}.'">'.$field.'</option>';
    }
    if($d{type} eq 'option')
    {
       return $specific_fields;
    }
    else
    {
	   return @where_fields;
    }
}
################################################################################
# list_get_filters
################################################################################
sub list_get_filters
{
    my $filters = '';
    my $count_filters = 1;
	my $filters_set = 0;
	if(get_quoted('extra_filter') ne '')
	{
		$filters_set = 1;
	}
	
    foreach my $field_line (sort keys %dm_filters)
    {
        my ($ordby,$label) = split(/\//,$field_line);
        my $col = $dm_filters{$field_line}{col};
        my $type = $dm_filters{$field_line}{type};
        my $init_value = get_quoted($col) || '';
        my $options = "";
        if($type eq 'hash')
        {
            my %hash = %{$dm_filters{$field_line}{ref}};
            foreach my $option (sort keys %hash)
            {
                     my $selected = "";
					  my ($ordby,$option_value) = split(/\//,$option);

                     if($option eq $init_value || $option_value eq $init_value)
                     {
                         $selected = ' selected="selected" ';
						 $filters_set = 1;
                     }
					 my $txt = $dm_filters{$field_line}{ref}{$option};
					 if($dm_filters{$field_line}{translate} == 1)
					 {
						($txt,$dum)=get_textcontent($dbh,$txt,$colg);
					 }
                     $options .=<<"EOH";
		<option $selected value="$option">$txt</option>
EOH
            }
            $filters .=<<"EOH";
<div class="form-group group-filters-hash-$col col-md-3">
	<label><strong>$label</strong></label>
	<select data-init-value="$init_value" class="list_filter select2 form-control input-block search_element" data-placeholder="$label" id="list_filter_$count_filters" name="$col">
		<option></option>
		$options
	</select>
</div>
EOH
        }
        elsif($type eq 'lbtable')
        {
            my $dbh_spec = $dm_cfg{dbh} || $dbh;
            my @option_values = 
			sql_lines
			(
				{
					dbh=>$dbh_spec,
					table=>$dm_filters{$field_line}{table},
					select=>"$dm_filters{$field_line}{key} as cle, $dm_filters{$field_line}{display} as valeur",
					where=>$dm_filters{$field_line}{where},
					ordby=>$dm_filters{$field_line}{ordby},
					limit=>$dm_filters{$field_line}{limit},
					groupby=>$dm_filters{$field_line}{groupby},
				}
			);
					
            foreach my $option_value (@option_values)
            {
               my %option_value = %{$option_value};
               my $selected = "";
               if($option_value{cle} eq $init_value)
               {
                   $selected = ' selected="selected" ';
				   $filters_set = 1;
               }
			   my $txt = $option_value{valeur};
			  if($dm_filters{$field_line}{translate} == 1)
			  {
				($txt,$dum)=get_textcontent($dbh,$txt,$colg);
			  }
			   $options .=<<"EOH";
		<option $selected value="$option_value{cle}">$txt</option>
EOH
            }
            $filters .=<<"EOH";
<div class="form-group group-filters-labtable-$col col-md-3">
	<label><strong>$label</strong></label>
	<select class="list_filter select2 form-control search_element" data-placeholder="$label"  id="list_filter_$count_filters" name="$col">
		<option></option>
		$options
	</select>
</div>
EOH
        }
        elsif($type eq 'fulldaterange')
        {
            my $dbh_spec = $dm_cfg{dbh} || $dbh;
            $filters .=<<"EOH";
<div class="form-group col-md-3">
	<label><strong>$label</strong></label>
	<input type="text" placeholder="$label" name="$col" class="search_element form-control report_range" id="list_filter_$count_filters" />
</div>
EOH
        }
        $count_filters++;
    }
	
	if($dm_cfg{custom_filter_func} ne "")
	{
	  my $func = $dm_cfg{custom_filter_func};
	  $filters .= &$func();
	  $count_filters++;
	}
	
	
	
    $filters .=<<"EOH";
<input type="hidden" name="list_count_filters"  id="list_count_filters" value="$count_filters" />
<input type="hidden" name="filters_set"  id="filters_set" value="$filters_set" />
EOH
       
	   
	   
	   
	   return $filters;
}
################################################################################
# list_body_ajax
################################################################################
sub list_body_ajax
{
   my %d = %{$_[0]};

   my $page = get_quoted('page') || 1;
   my $selection = get_quoted('selection') || '';
   my $nr = $dm_cfg{force_nr} || get_quoted('nr') || '25';
   my $keyword = get_quoted('list_keyword') || '';
   my $list_tags_vals = get_quoted('list_tags_vals') || '';
   my $specific_col = get_quoted('list_specific_col') || '';
   my $filters = get_quoted('filters') || '';
   my $extra_filter = get_quoted('extra_filter') || '';
   my $exact_search = get_quoted('exact_search') || '';
   my $extra_filter_name = get_quoted('extra_filter_name') || '';
   my $extra_filter_value = get_quoted('extra_filter_value') || '';
   my $list_col_search = get_quoted('list_col_search') || '';
   
   if($extra_filter_name ne '' && $extra_filter_value ne '')
   {
		$extra_filter = $extra_filter_name.'---'.$extra_filter_value;
   }
   
  #cache listboxtables: précharge toutes les valeurs pour l'affichage listing ainsi que les exports xls et txt
  my %cache_listboxtables = ();
  if($dm_cfg{enable_cache_listboxtables} == 1)
  {
	  
	  foreach $field_line (sort keys %dm_dfl)
	  {
			($ordby,$field_name) = split(/\//,$field_line);
			%line = %{$dm_dfl{$field_line}};
			$type =  $line{fieldtype};
			$data_type =  $line{data_type};
			if($type eq 'listboxtable' || $data_type eq 'listboxtable')
			{
				$lbtable = $line{lbtable};
				
				# log_debug('cache pour '.$lbtable,'','cache_listboxtable');
				
				$lbkey = $line{lbkey};
				$lbdisplay = $line{lbdisplay};
				my %cache = ();
			    my $where = " id NOT IN (select id_record from migcms_valides WHERE nom_table='$lbtable')";

				my @records_for_cache = sql_lines({table=>$lbtable,select=>"$lbkey as cle, $lbdisplay as display",where=>"$where"});
				foreach $record_for_cache (@records_for_cache)
				{
					my %record_for_cache = %{$record_for_cache};
					$cache{$record_for_cache{cle}} = $record_for_cache{display};			   
				}
				# log_debug('Tableau de '.$#records_for_cache.' records (cle:'.$lbkey.' display:'.$lbdisplay,'','cache_listboxtable');
				$cache_listboxtables{$field_name} = \%cache;
			}
	  }
   }
   my $render = get_quoted('render') || 'html';
   my $sort_field_name = get_quoted('sort_field_name') || '';
   my $sort_field_sens = get_quoted('sort_field_sens') || '';
   my $colg = get_quoted('lg') || get_quoted('colg') ||  $colg || 1;
   if($render eq 'html')
   {
         my $id = get_quoted('id');
         my $sens = get_quoted('sens');
         my $count = 1;
         my $groupby = $dm_cfg{groupby};
         my $limit = (($page-1) * $nr).','.$nr;
		 
		 #cache pour un affichage arborescent plus rapide.
		 my @tree = ();
		 if($dm_cfg{tree} == 1 && $dm_cfg{cache_tree} == 1)
		 {
			my $select = list_get_select();
			@tree = sql_lines({select=>$select,table=>$dm_cfg{table_name}});
		 }
		 
		 my $tree_start = 0;
		 if($dm_cfg{tree_start} > 0)
		 {
			$tree_start = $dm_cfg{tree_start};
		 }

		 
		 
          my ($list,$pagination,$end_page_max,$info_page,$info_nb_results,$customfuncresult) =
		 list_body_map_lines_recurse
         (
            {
                colg=>$colg,
				selection=>$selection,
                id_father=>$tree_start,
                level=>'0',
                keyword=>$keyword,
				list_tags_vals=>$list_tags_vals,
                specific_col=>$specific_col,
                filters=>$filters,
                extra_filter=>$extra_filter,
                exact_search=>$exact_search,
                list_col_search=>$list_col_search,
                groupby=>$groupby,
                limit=>$limit,
                page=>$page,
                nr=>$nr,
                id=>$id,
                sens=>$sens,
                sort_field_name=>$sort_field_name,
                sort_field_sens=>$sort_field_sens,
				cache_listboxtables=>\%cache_listboxtables,
				tree=>\@tree,
            }
        );
        my $list_of_fathers = '';
        if($dm_cfg{tree})
        {
              my %parents = select_table($dbh_data,$dm_cfg{list_table_name},'GROUP_CONCAT(DISTINCT(id_father)) as parents');
              $list.= '<input type="hidden" name="parents" id="parents" value="'.$parents{parents}.'" />';
        }
        if($d{view} eq 'cgi')
        {
             # log_debug($list,'','list_finalecgi');
			 return ($list,$pagination,$end_page_max,$info_page,$info_nb_results,$custom_header_func_result,$nbr_box);
        }
        else
        {
            # log_debug($list,'','list_finale');
			print $list.'___'.$pagination.'___'.$end_page_max.'___'.$info_page.'___'.$info_nb_results.'___'.$custom_header_func_result.'___'.$nbr_box;
            exit;
        }
  }
  elsif($render eq 'csv')
  {
	if($dm_cfg{custom_export_csv_func} ne '')
	{
		$fct = $dm_cfg{custom_export_csv_func};
		&$fct($dbh,$id);
		exit;
	}
	# use Text::CSV::Encoded; 
	use Encode;
	log_debug('csv','','csv');
			
	my @csv_data = ();
	my %newLine = ();
	my $ordby = 0;
	
	
	#LIBELLES
	foreach $field (sort keys %dm_dfl)
	{
		my ($num,$cell_infos_ref) = split(/\//,$field);
		my %cell_infos = %{$dm_dfl{$field}};
		my $title = trim($cell_infos{title});
		if($cell_infos{fieldtype} eq 'files_admin')
		{
			next;
		}
		
		$newLine{sprintf("%05d", $ordby++)} = $title;
	}
	push @csv_data, \%newLine;	
	  
  
	#LIGNES  
	my $select = list_get_select();
	my $where = list_get_where({debug=>0,list_col_search=>$list_col_search,list_tags_vals=>$list_tags_vals,wherel =>$dm_cfg{wherel},wherep =>$dm_cfg{wherep}, keyword => $keyword, specific_col => $specific_col, filters => $filters,extra_filter => $extra_filter});
	if($dm_cfg{default_ordby} eq '' && $dm_permissions{sort})
	{
		$dm_cfg{default_ordby} = " ordby ";
	}
	my $ordby = $dm_cfg{default_ordby};
	if($dm_cfg{tree} == 1)
	{
		$ordby = 'id';
	}
	
	my @lines = sql_lines({dbh=>$dbh_data,limit=>"",table=>$dm_cfg{list_table_name},select=>$select,where=>$where,ordby=>$ordby,groupby=>$d{groupby},debug=>0,debug_results=>0});
	my $id_col = $dm_cfg{id_col} || 'id';
	foreach $line(@lines)
	{
		my %line = %{$line};

		my %newLine = ();
		my $ordby = 0;

		foreach $dm_dfl_line (sort keys %dm_dfl)
		{
			my ($num,$field) = split(/\//,$dm_dfl_line);
			my %cell_infos = %{$dm_dfl{$dm_dfl_line}};

			if($field ne '')
			{
				my ($cell_content,$cell_type,$spec,$cell_subtype,$list_style,$data_type) = list_map_body_col_value({cache_listboxtables=>\%cache_listboxtables,line=>\%line,value=>$line{$field},col=>$field,render=>$render});

				if($cell_type eq 'files_admin')
				{
					next;
				}

				$cell_content = trim($cell_content);
				$cell_content = decode_entities($cell_content);

				if($field eq 'id')
				{
					$cell_content= getcode($dbh,$line{$field},$dm_cfg{file_prefixe});
				}
				elsif($cell_type eq 'checkbox')
				{
					$cell_content = 'Non';
					if($line{$field} eq 'y')
					{
						$cell_content = 'Oui';
					}
				}
				elsif($cell_type eq 'listboxtable')
				{

				}

				$newLine{sprintf("%05d", $ordby++)} = $cell_content;
			}
		}

		push @csv_data, \%newLine;	

	}

	my $outfile = "../usr/documents/$dm_cfg{list_table_name}.csv"; 
	tools::write_file_csv({outfile=>$outfile, data=>\@csv_data});
	# print $cgi->header(-type =>'text/plain', -expires=>'-1d',-charset => 'utf-8', -attachment =>"$dm_cfg{list_table_name}.csv");
	# print get_file($outfile);
	print $outfile;
	exit;

  }
  elsif($render eq 'excel' )
  {
	if($dm_cfg{custom_export_excel_func} ne '')
	{
		$fct = $dm_cfg{custom_export_excel_func};
		&$fct($dbh,$id);
		exit;
	}
	use Spreadsheet::ParseExcel;
	use Spreadsheet::WriteExcel;
	use Encode;
	$dm_cfg{export_excel_simple} = 1;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	my $document_filename = get_document_filename({date=>1,prefixe=>$dm_cfg{file_prefixe},type=>'listing'});
	my $outfile = "../usr/documents/$document_filename.xls";
	my $workbook = Spreadsheet::WriteExcel->new($outfile);
	my $worksheet = $workbook->add_worksheet("Export");
	my $date_format = $workbook->add_format(num_format => 'dd/mm/yyyy');
	my $time_format = $workbook->add_format(num_format => 'hh:mm');
       $worksheet->set_column('A:A', 20);
       $worksheet->set_column('B:Z', 30);
      my $select = list_get_select();
      my $where = list_get_where({debug=>0,list_col_search=>$list_col_search,list_tags_vals=>$list_tags_vals,wherel =>$dm_cfg{wherel},wherep =>$dm_cfg{wherep}, keyword => $keyword, specific_col => $specific_col, filters => $filters,extra_filter => $extra_filter});
      if($dm_cfg{default_ordby} eq '' && $dm_permissions{sort})
      {
            $dm_cfg{default_ordby} = " ordby ";
      }
	  my $ordby = $dm_cfg{default_ordby};
	  if($dm_cfg{tree} == 1)
	  {
		$ordby = 'id';
	  }

	  
	  

      my @lines = sql_lines({dbh=>$dbh_data,limit=>"",table=>$dm_cfg{list_table_name},select=>$select,where=>$where,ordby=>$ordby,groupby=>$d{groupby},debug=>0,debug_results=>0});
      my $row = 0;
      my $col = 1;
      my $id_col = $dm_cfg{id_col} || 'id';
      $row++;
      $col = 0;
      my @col_types = ('');
      foreach $line(@lines)
      {
          my %line = %{$line};
		  my @excel_keys = sort keys %dm_import_excel;
		  if(0 && $#excel_keys > -1)
		  {
				#génération des lignes excel à partir de %dm_import_excel
				foreach my $excel_key (@excel_keys)
				{
					my $field = $dm_import_excel{$excel_key};
					my ($cell_content,$cell_type,$spec,$cell_subtype,$list_style,$data_type) = list_map_body_col_value({cache_listboxtables=>\%cache_listboxtables,line=>\%line,value=>$line{$field},col=>$field,render=>$render});
					$cell_content = trim(decode("utf8",$cell_content));
					$worksheet->write($row,$col++,$cell_content,$format_vert);
				}
		  }
		  else
		  {
			  #génération des lignes excel à partir de %dm_dfl
			  foreach $dm_dfl_line (sort keys %dm_dfl)
			  {
				  my ($num,$field) = split(/\//,$dm_dfl_line);
				  my %cell_infos = %{$dm_dfl{$dm_dfl_line}};
				  if($field ne '')
				  {
					  my ($cell_content,$cell_type,$spec,$cell_subtype,$list_style,$data_type) = list_map_body_col_value({cache_listboxtables=>\%cache_listboxtables,line=>\%line,value=>$line{$field},col=>$field,render=>$render});
					  if($cell_type eq 'files_admin')
					  {
						next;
					  }
					  $cell_content = trim(decode("utf8",$cell_content));
					  $cell_content = decode_entities($cell_content);
					  push @col_types,$cell_type;
					  push @col_subtypes,$cell_subtype;
					  if($field eq 'id')
					  {
							my $id = getcode($dbh,$line{$field},$dm_cfg{file_prefixe});
							$worksheet->write($row,$col++,$id,$format_vert);
					  }
					  elsif($cell_type eq 'checkbox')
					  {
						  $worksheet->write($row,$col++,$line{$field},$format_vert);
					  }
					  elsif($data_type eq 'euros' || $data_type eq 'perc' || $data_type eq 'number')
					  {
						  $worksheet->write($row,$col++,$line{$field},$format_vert);
					  }
					  elsif($data_type eq 'date')
					  {
						  $worksheet->write_date_time($row,$col++,$line{$field}.'T', $date_format);
					  }
					  elsif($cell_type ne 'listboxtable' && $cell_type ne '')
					  {
						  if(trim($cell_content) eq '00/00/0000')
						  {
							$cell_content = '';
						  }
						  $worksheet->write($row,$col++,$cell_content,$format_vert);
					  }
					  elsif($cell_type eq 'listboxtable')
					  {
						  $worksheet->write($row,$col++,$cell_content,$format_vert);
						  if(!$dm_cfg{export_excel_simple})
						  {
							  $worksheet->write($row,$col++,$line{$champ},$format_vert);
						  }
					  }
					  else
					  {
						$worksheet->write($row,$col++,'CELLTYPE VIDE',$format_vert);
					  }
				  }
			  }
		  }
		 $row++;
          $col = 0;
		  	# exit;
      }
      $row = 0;
      $col = 0;
      if(!$dm_cfg{export_excel_simple})
      {
          $worksheet->write($row,$col++,"NE PAS MODIFIER",$format_rouge);
      }
	  my @excel_keys = sort keys %dm_import_excel;
	  if(0 && $#excel_keys > -1)
	  {
			foreach my $excel_key (@excel_keys)
			{
				my $field = $dm_import_excel{$excel_key};
				if($field eq 'id')
				{
					$field = 'NE PAS MODIFIER';
				}
				$worksheet->write($row,$col++,$field,$format_rouge);
			}
	  }
	  else
	  {
		  #Ecriture libelles à partir de dm_dfl
		  foreach $field (sort keys %dm_dfl)
		  {
			  my ($num,$cell_infos_ref) = split(/\//,$field);
			  my %cell_infos = %{$dm_dfl{$field}};
			  my $text_cell_content = $cell_infos{title};
			  $cell_content = trim(decode("utf8","$num/$cell_content"));
			  $text_cell_content = trim(decode("utf8","$text_cell_content"));
			  
			  if($cell_infos{fieldtype} eq 'files_admin')
			  {
				next;
			  }


			 if($dm_cfg{export_excel_simple})
			  {
				  $worksheet->write($row,$col++,"$text_cell_content",$format_rouge);
			  }
			  else
			  {
				  if($col_types[$col] eq 'listboxtable')
				  {
					  $worksheet->write($row,$col++,"$cell_content/$col_types[$col]/$col_subtypes[$col]/$dm_display_fields{$field}",$format_rouge);
					  $worksheet->write($row,$col++,"",$format_rouge);
				  }
				  else
				  {
					$worksheet->write($row,$col++,"$cell_content/$col_types[$col]/$col_subtypes[$col]/$dm_display_fields{$field}",$format_rouge);
				  }
			  }
		  }
		}
		$workbook->close();
		print $outfile;
		exit;
		# open (FILE,$outfile);
		# binmode FILE;
		# binmode STDOUT;
		# while (read(FILE,$buff,2096))
		# {
			# print STDOUT $buff;
		# }
		# close (FILE);
	}
	elsif($render eq 'txt')
	{
		use Encode;
		my $outfile = "../usr/txt_$dm_cfg{table_name}.txt";
		my $select = list_get_select();
		my $where = list_get_where({wherel =>$dm_cfg{wherel},wherep =>$dm_cfg{wherep}, keyword => $keyword, specific_col => $specific_col, filters => $filters});
		if($dm_cfg{default_ordby} eq '' && $dm_permissions{sort})
		{
			$dm_cfg{default_ordby} = " ordby ";
		}
		my @lines = sql_lines({dbh=>$dbh_data,table=>$dm_cfg{list_table_name},select=>$select,where=>$where,ordby=>$dm_cfg{default_ordby},groupby=>$d{groupby},debug=>0});
		my $id_col = $dm_cfg{id_col} || 'id';
		my $txt_lines = '';
		my @excel_keys = sort keys %dm_import_excel;
		  if($#excel_keys > -1)
		  {
		  }
		  else
		  {
			my $txt_line = '';
			foreach $field (sort keys %dm_dfl)
			  {
				  my ($num,$cell_infos_ref) = split(/\//,$field);
				  my %cell_infos = %{$dm_dfl{$field}};
				  my $text_cell_content = $cell_infos{title};
				  $text_cell_content = trim(decode("utf8","$text_cell_content"));
				  $txt_line .= $text_cell_content."\t";
			  }
			  $txt_line .= "\r\n";
			  $txt_lines .= $txt_line;
		  }
		foreach $line(@lines)
		{
			  my %line = %{$line};
			 my $txt_line = '';
			  my @excel_keys = sort keys %dm_import_excel;
			  if($#excel_keys > -1)
			  {
					#génération des lignes excel à partir de %dm_import_excel
					# foreach my $excel_key (@excel_keys)
					# {
						# my $field = $dm_import_excel{$excel_key};
						# my ($cell_content,$cell_type,$spec,$cell_subtype,$list_style,$data_type) = list_map_body_col_value({line=>\%line,value=>$line{$field},col=>$field,render=>$render});
						# $cell_content = trim(decode("utf8",$cell_content));
						# $txt_line .= $cell_content."\t";
					# }
			  }
			  else
			  {
				  #génération des lignes excel à partir de %dm_dfl
				  foreach $dm_dfl_line (sort keys %dm_dfl)
				  {
					  my ($num,$field) = split(/\//,$dm_dfl_line);
					  my %cell_infos = %{$dm_dfl{$dm_dfl_line}};
					  if($field ne '')
					  {
						  my ($cell_content,$cell_type,$spec,$cell_subtype,$list_style,$data_type,$lbtable,$lbkey,$lbdisplay) = list_map_body_col_value({cache_listboxtables=>\%cache_listboxtables,line=>\%line,value=>$line{$field},col=>$field,render=>$render});
						  if($cell_type eq 'files_admin')
						  {
							next;
						  }
						  $cell_content = trim(decode("utf8",$cell_content));
						  push @col_types,$cell_type;
						  push @col_subtypes,$cell_subtype;
						  if($cell_type eq 'checkbox')
						  {
							  $txt_line .= $line{$field}."\t";
						  }
						  elsif($data_type eq 'euros' || $data_type eq 'perc' || $data_type eq 'number')
						  {
							  $txt_line .= $line{$field}."\t";
						  }
						  elsif($data_type eq 'date')
						  {
							  $txt_line .= $line{$field}."\t";
						  }
						  elsif($cell_type ne 'listboxtable' && $cell_type ne '')
						  {
							  $txt_line .= $cell_content."\t";
						  }
						  elsif($cell_type eq 'listboxtable')
						  {
							#id -> valeur affichée
							my %display_from_record = sql_line({debug=>0,table=>$lbtable,where=>" id = '$line{$field}' "});
							my $excel_value_display = trim(encode("utf8",$display_from_record{$lbdisplay}));
							$excel_value_display = decode_entities($excel_value_display);
							$excel_value_display =~ s/\'/\\\'/g;
							# print "<span style='color:red'>$excel_value_display</span>";
							# $update_record{$field} = $record_from_display{$lbkey};
							# print " [$excel_value_display][".$record_from_display{$lbkey}.']';
							# if($update_record{$field} ne '')
							# {
								# $vide = 0;
							# }
							  $txt_line .= $excel_value_display."\t";
							  # $txt_line .= $cell_content."\t";
						  }
					  }
				  }
			  }
			  $txt_line .= "\r\n";
			  $txt_lines .= $txt_line;
		  }
		  	 open LOGAP, '>'.$outfile;
			 print LOGAP "$txt_lines";
			 close LOGAP;
			 print $outfile;
			 # download_file($outfile,'txt','');
			 exit;
	}
}
################################################################################
# list_get_select
################################################################################
sub list_get_select
{
   #MAKE SELECT FOR LIST TABLE**************************************************
   my @selects = ();
   my @tables = split(/,/,$dm_cfg{list_table_name});
   foreach $table (@tables)
   {
      push @selects, " $table.* ";
   }
   my $id_col = $dm_cfg{id_col} || 'id';
   push @selects, " $dm_cfg{table_name}.$id_col as id_table_record ";
   if($dm_cfg{custom_select} ne '')
   {
      push @selects, " $dm_cfg{custom_select}";
   }
   my $select = join(",",@selects);
   return $select;
}
################################################################################
# list_body_map_lines_recurse
################################################################################
sub list_body_map_lines_recurse
{
	my %d = %{$_[0]};
	my %cache_listboxtables = %{$d{cache_listboxtables}};
    my $customfuncresult = '';
	$d{level}++;
	
	#construction du select
	my $select = list_get_select();
	
	#construction du where
	my $where = list_get_where({exact_search=>$d{exact_search},list_col_search=>$d{list_col_search},list_tags_vals=>$d{list_tags_vals},id_father=>$d{id_father},wherel =>$dm_cfg{wherel},wherep =>$dm_cfg{wherep}, keyword => $d{keyword}, specific_col => $d{specific_col}, filters => $d{filters}, extra_filter => $d{extra_filter}});
	
	#sauvegarde la condition where pour les affichages annexes: ex google map
	if($dm_cfg{show_google_map} eq 'y')
	{
		my %migcms_where = (
		id_user => $user{id},
		cond => $where,
		nom_table => $dm_cfg{table_name},
		);
		%migcms_where = %{quoteh(\%migcms_where)};
		sql_set_data({dbh=>$dbh_data,debug=>$dm_cfg{list_debug},debug_results=>$dm_cfg{list_debug},table=>'migcms_wheres',data=>\%migcms_where, where=>"id_user='$migcms_where{id_user}' AND nom_table = '$migcms_where{nom_table}'"});
   }
   
   
   if($dm_cfg{default_ordby} eq '' && $dm_permissions{sort})
   {
        $dm_cfg{default_ordby} = " ordby ";
   }
   
   #nextORprev:
   my $id_to_find = $d{id};
   my $next = 0;
   my $prev = 0;
   if($d{sens} ne '')
   {
        $d{limit} = '';
        $select = $dm_cfg{table_name}.'.id';
   }
   
   #TRI SIMPLE******************************************************************
   my $ordby = $dm_cfg{default_ordby};
   if(trim($d{sort_field_name}) ne '' && trim($d{sort_field_sens}) ne '')
   {
      $ordby = " $d{sort_field_name} $d{sort_field_sens} ";
   }
   #TRI COMPLEXE (VIA UNE TABLE LIEE[, UNE FONCTION, UN LIEN])******************
   foreach my $field_line (sort keys %dm_dfl)
   {
        my ($dum,$field_name) = split(/\//,$field_line);
        if($field_name eq $d{sort_field_name} && $d{sort_field_name} ne '')
        {
            $dm_dfl{$field_line}{lbtable} = trim($dm_dfl{$field_line}{lbtable});
            if($dm_dfl{$field_line}{fieldtype} eq 'listboxtable')
            {
               my @ids = ();
			   my $lb_ordby = $dm_dfl{$field_line}{lbdisplay};
			   if($dm_dfl{$field_line}{lbordby} ne '')
			   {
					$lb_ordby = $dm_dfl{$field_line}{lbordby};
			   }

			   my $where = $dm_dfl{$field_line}{lbwhere};

			   my @ids_in_order = sql_lines({dbh=>$dbh_data,table=>$dm_dfl{$field_line}{lbtable},select=>$dm_dfl{$field_line}{lbkey},ordby=>$lb_ordby,where=>$where});
               foreach $id_in_order (@ids_in_order)
               {
                  my %id_in_order = %{$id_in_order};
				  $id_in_order{$dm_dfl{$field_line}{lbkey}} =~ s/\'/\\\'/g;
                  push @ids,"'".$id_in_order{$dm_dfl{$field_line}{lbkey}}."'";
               }
               my $ids_in_order = join(',',@ids);
               $ordby = <<"EOH";
FIELD ($dm_cfg{table_name}.$d{sort_field_name},$ids_in_order) $d{sort_field_sens}
EOH
            }
        }
   }
   
   $where = trim($where);
   
    if($d{selection} ne '')
    {
		$select = $d{selection};
    }
	
    if($dm_cfg{tree} == 1)
	{
		$d{limit} = '';
	}
	
	#*************************************************************************************************************************************************
	#SELECTION DES LIGNES*****************************************************************************************************************************
	#*************************************************************************************************************************************************

	my @lines = ();
	my @tree = @{$d{tree}};

	if($#tree > -1 && $dm_cfg{tree} == 1 && $dm_cfg{cache_tree} == 1)
	{
		@lines = @tree;
	}
	else
	{
		@lines = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh_data,table=>$dm_cfg{list_table_name},select=>$select,where=>$where,ordby=>$ordby,groupby=>$d{groupby},limit=>$d{limit}});
	}
    if($d{selection} ne '')
    {
		print $lines[0]{result};
		exit;
    }
    
   my $i = 0;
   foreach $line(@lines)
   {
      my %line = %{$line};
      
	  if($dm_cfg{tree} == 1 && $dm_cfg{cache_tree} == 1)
	  {
			if($line{id_father} != $d{id_father})
			{
				next;
			}
	  }

	  if($next)
      {
          print $line{id};
          exit;
      }
      if($line{id} == $id_to_find)
      {
          if($d{sens} eq 'previous')
          {
               $i--;
               if(!($i>=0))
               {
                  $i = $#lines;
               }
               print $lines[$i]{id};
               exit;
          }
          elsif($d{sens} eq 'next')
          {
               $next = 1;
          }
      }
      $i++;
      $list .= list_map_line_body({cache_listboxtables=>\%cache_listboxtables,colg=>$d{colg},line=>\%line,count=>$count++,level=>$d{level},id_father=>$d{id_father},keyword=>$d{keyword}});
           
	  if($dm_cfg{tree})
      {
          list_body_map_lines_recurse
          (
              {
                  colg=>$d{colg},
                  id_father=>$line{id},
                  level=>$d{level},
                  keyword=>$d{keyword},
                  specific_col=>$specific_col,
                  filters=>$filters,
                  groupby=>$groupby,
                  limit=>$limit,
                  page=>$page,
                  nr=>$d{nr},
                  id=>$id,
                  sens=>$sens,
				  cache_listboxtables=>\%cache_listboxtables,
				  tree=>\@tree,
              }
          );
      }
   }
   my $id_col = $dm_cfg{id_col} || 'id';
   my %tot = sql_line({dbh=>$dbh_data,debug=>0,debug_results=>0,table=>$dm_cfg{list_table_name},select=>"count($dm_cfg{table_name}.$id_col) as nr_total",where=>$where});
   my $nr = $dm_cfg{force_nr} || get_quoted('nr') || '25';
   my $nbr_box =<<"EOH";
<span class="nbr_box_container">
	<button type="button" class="btn btn-default dropdown-toggle nr_sel" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"><span class="badge badge-info">$nr_r</span> $migctrad{resultspage} <span class="caret"></span></button>
	<ul class="dropdown-menu dropdown-menu-right nr_box">
		<li><a href="#" class="nr_select" id="25"><span class="badge badge-info">25</span> $migctrad{resultspage}</a></li>
		<li><a href="#" class="nr_select" id="100"><span class="badge badge-info">100</span> $migctrad{resultspage}</a></li>
		<li><a href="#" class="nr_select" id="250"><span class="badge badge-info">250</span> $migctrad{resultspage}</a></li>
		<li><a href="#" class="nr_select" id="500"><span class="badge badge-info">500</span> $migctrad{resultspage}</a></li>
		<li><a href="#" class="nr_select" id="1000"><span class="badge badge-info">1000</span> $migctrad{resultspage}</a></li>
		<li><a href="#" class="nr_select" id="2000"><span class="badge badge-info">2000</span> $migctrad{resultspage}</a></li>
		$nbr_box_all
	</ul>
</span>
EOH
   # if($tot{nr_total} <= 25)
   # {
		 # $nbr_box = '';
   # }
   if($dm_cfg{custom_header_func} ne '')
    {
        my $func = $dm_cfg{custom_header_func};
        $customfuncresult = &$func($dbh_data,$where);
    }
	 my ($pagination,$end_page_max) = list_pagination({nbr_box=>$nbr_box,page=>$d{page},nombre_numeros=>5,nr=>$d{nr},nr_total=>$tot{nr_total}});
	 my $info_page =<<"EOH";
Page <span class="badge badge-info title-center">$d{page}</span> $migctrad{of} $end_page_max
EOH
   my $info_nb_results =<<"EOH";
<span class="badge badge-info" title="" data-original-title="$tot{nr_total} $migctrad{totalresults}">$tot{nr_total} $migctrad{totalresults}</span>
EOH
	if($dm_cfg{tree})
   {
      $pagination = '';
      $info_page = '';
      $info_nb_results = '';
	  $nbr_box = '';
   }
   return ($list,$pagination,$end_page_max,$info_page,$info_nb_results,$customfuncresult);
}
sub get_listboxtable_where
{
   my $field_name_r = $_[0];
   my $keyword = $_[1];
   my $exact_search   = $_[2];
   
   foreach my $field_line (sort keys %dm_dfl)
   {
		my ($dum,$field_name) = split(/\//,$field_line);
		if($field_name eq $field_name_r)
		{
			my $where = "$dm_dfl{$field_line}{lbdisplay} LIKE '%$keyword%'";
			
			if($exact_search eq 'y')
			{
				$where = "( $dm_dfl{$field_line}{lbdisplay} LIKE '% $keyword %' OR $dm_dfl{$field_line}{lbdisplay} LIKE '$keyword %' OR $dm_dfl{$field_line}{lbdisplay} LIKE '$keyword' )";
			}
			
			if($dm_dfl{$field_line}{lbwhere} ne '')
			{
				$where .= ' AND '.$dm_dfl{$field_line}{lbwhere};
			}
			
			
			
			return " $field_name IN ( select $dm_dfl{$field_line}{lbkey} FROM $dm_dfl{$field_line}{lbtable} WHERE $where )";
		}
	}
}
sub get_fieldtype
{
	my $field_name_r = $_[0];
   foreach my $field_line (sort keys %dm_dfl)
   {
		my ($dum,$field_name) = split(/\//,$field_line);
		if($field_name eq $field_name_r)
		{
			return $dm_dfl{$field_line}{fieldtype};
		}
	}
}
sub get_data_type
{
	my $field_name_r = $_[0];
   foreach my $field_line (sort keys %dm_dfl)
   {
		my ($dum,$field_name) = split(/\//,$field_line);
		if($field_name eq $field_name_r)
		{
			return $dm_dfl{$field_line}{data_type};
		}
	}
}
################################################################################
# list_get_where
################################################################################
sub list_get_where
{
    my %d = %{$_[0]};
    my @where = ();
    my @where_fields = list_get_specific_fields({list_col_search=>$d{list_col_search},type=>'field'});
	$d{debug} = 1;
	
	if($d{debug} == 1)
	{
		# log_debug('','vide','list_get_where');
		# log_debug('keyword:'.$d{keyword},'','list_get_where');
		# log_debug('tags:'.$d{list_tags_vals},'','list_get_where');
		# log_debug('extra_filter:'.$d{extra_filter},'','list_get_where');
		# log_debug('wherep:'.$d{wherep},'','list_get_where');
		# log_debug('wherel:'.$d{wherel},'','list_get_where');
		# log_debug('filters:'.$d{filters},'','list_get_where');
		# log_debug('list_col_search:'.$d{list_col_search},'','list_get_where');
		# log_debug('tree:'.$d{tree},'','list_get_where');
		# log_debug('depends_on_actif_language:'.$d{depends_on_actif_language},'','list_get_where');
	}

    my @search_fields = ();
	$d{keyword} = lc($d{keyword});
	$d{keyword} =~ s/[^a-zA-Z0-9éèêêàâîïü]/ /g;
	
    #RECHERCHE SUR MOT CLE******************************************************
    if($d{keyword} ne '')
    {
        my @keywords = split('\s',$d{keyword});
		my @where_keyword = ();
        #recherche sur le tableau des champs
		foreach my $keyword (@keywords)
		{
			my @where_field_keyword = ();
			foreach $col (@where_fields)
			{
				  if($col ne '')
				  {
					  my $field_type = get_fieldtype($col);

					  #SELON TYPE
					  if($field_type eq 'text' || $field_type eq 'textarea' || $field_type eq 'textarea_editor' || $field_type eq 'display' || $col eq 'migcms_id')
					  {
						  if($d{exact_search} eq 'y')
						  {
							push @where_field_keyword, " ( (LOWER($col) LIKE '% $keyword %') OR (LOWER($col) LIKE '$keyword %') OR (LOWER($col) LIKE '$keyword') ) ";
						  }
						  else
						  {
							push @where_field_keyword, " LOWER($col) LIKE '%$keyword%' ";
						  }
					  }
					  elsif($field_type eq 'listboxtable')
					  {
							my $listboxtable_where = get_listboxtable_where($col,$keyword,$d{exact_search});
						   push @where_field_keyword,$listboxtable_where;
					  }
					  elsif($field_type eq 'text_id' || $field_type eq 'textarea_id' || $field_type eq 'textarea_id_editor')
					  {
						  if($d{exact_search} eq 'y')
						  {
							push @where_field_keyword, " id IN (select data_sheets.id FROM data_sheets, txtcontents where ( ( $col = txtcontents.id AND lg$colg LIKE '% $keyword % ') OR ($col = txtcontents.id AND lg$colg LIKE '$keyword % ') OR ($col = txtcontents.id AND lg$colg LIKE '$keyword')) ";
						  }
						  else
						  {
							push @where_field_keyword, " id IN (select data_sheets.id FROM data_sheets, txtcontents where $col = txtcontents.id AND lg$colg LIKE '%$keyword%') ";
						  }
						  
						  
					  }
					}
			}
			my $where_field_keyword = join(" OR ",@where_field_keyword);
			push @where_keyword, ' ( '.$where_field_keyword.' ) ';
		}
        my $where_field_keyword = join(" AND ",@where_keyword);
		push @where, $where_field_keyword;
    }

    #RECHERCHE SUR TAGS******************************************************
    if($d{list_tags_vals} ne '')
    {
        my @ids = split('\,',$d{list_tags_vals});
		my $where_tags = '';
		my @where_field_tag = ();
		foreach my $id (@ids)
		{
			push @where_field_tag, " $dm_cfg{tag_col} LIKE '%,$id,%' ";
		}
		my $where_tags = join(" AND ",@where_field_tag);
		push @where, $where_tags;
    }

	#RECHERCHE SUR EXTRA FILTER******************************************************
    if($d{extra_filter} ne '')
    {
		my ($field,$value) = split(/\-\-\-/,$d{extra_filter});       
		if($field ne '' && $value ne '')
		{
			if($dm_cfg{extra_filter_exact} eq 'y')
			{
				push @where, " $field = '$value' ";
			}
			else
			{
				push @where, " $field LIKE '%,$value,%' ";
			}
		}
    }

    #RECHERCHE SUR FILTRES******************************************************
    my @filters = split(/___/,$d{filters});
    foreach $filter (@filters)
    {
          my $type ='';
          my ($field,$value) = split(/\-\-\-/,$filter);
		  if($field eq 'undefined')
		  {
			$field = '';
		  }
		  if($value eq 'undefined')
		  {
			$field = '';
		  }
          foreach $cle (keys %dm_filters)
          {
              if($dm_filters{$cle}{col} eq $field)
              {
                  $type = $dm_filters{$cle}{type};
              }
          }
          if($field ne '' && $value ne '')
          {
              my ($du,$au) = split(/ au /,$value);
              my ($j1,$m1,$a1) = split(/\//,$du);
              my ($j2,$m2,$a2) = split(/\//,$au);
              my $sql_du = $a1.'-'.$m1.'-'.$j1;
              my $sql_au = $a2.'-'.$m2.'-'.$j2;
              if($type eq 'fulldaterange')
              {
                  push @where, " ( $field >= '$sql_du' AND $field <= '$sql_au' )  ";
              }
              else
              {
					my ($test_ordby,$test_value) = split(/\//,$value);
					if($test_ordby > 0 && $test_value ne '')
					{
						$value = $test_value;
					}
					push @where, " $field = '$value' ";
              }
          }
    }

    if(trim($dm_cfg{wherep}) ne '')
    {
        push @where, $dm_cfg{wherep};
    }
    if(trim($dm_cfg{wherel}) ne '')
    {
        push @where, $dm_cfg{wherel};
    }

    #IF TREE********************************************************************
    if($dm_cfg{tree} &&  $d{id_father} ne '' )
    {
        push @where, " id_father = $d{id_father}";
    }
	if($dm_cfg{autocreation} == 1)
	{
		push @where, " id NOT IN (select id_record from migcms_valides where nom_table='$dm_cfg{table_name}')";
	}
	if((get_quoted('restauration_active') eq 'restauration_active' && $dm_permissions{restauration} == 1)  ||  $dm_permissions{corbeille} == 0)
	{
	}
	else
	{
		push @where, " migcms_deleted != 'y' ";
	}

	if($dm_cfg{depends_on_actif_language} eq 'y')
	{
		my $lg = get_quoted('lg');
		if($lg eq '')
		{
			$lg= 1;
		}
		push @where, " actif_$lg = 'y' ";
	}

	#where supplémentaire
	my %where_supp = sql_line({table=>'migcms_modules_wheres',where=>"id_script='$sel' AND (('$user{id_role}' != '' AND id_role='$user{id_role}' AND id_role != 0) OR id_role='0')"});
	if($where_supp{where_supp} ne '')
	{
		push @where, $where_supp{where_supp};
	}


	my $computed_where = join(" AND ",@where);
	if($d{debug} == 1)
	{
		# log_debug($computed_where,'','list_get_where');
	}
	log_debug($computed_where,'','list_get_where');
    return $computed_where;
}
################################################################################
# list_map_line_body
################################################################################
sub list_map_line_body
{
	my %d = %{$_[0]};
	my %cache_listboxtables = %{$d{cache_listboxtables}};


    #BEGIN OF THE LINE: <TR> or custom TR by FUNC###############################
    my $tr = '<tr id="'.$d{line}{id_table_record}.'" class=" rec_'.$d{line}{id_table_record}.' migcms_deleted_'.$d{line}{migcms_deleted}.'">';
    if($dm_cfg{line_func} ne '')
    {
        my $func = $dm_cfg{line_func};
        $tr = &$func($dbh_data,$d{line}{id_table_record},\%d);
    }

	#FIELD CHECKBOX#############################################################
    my $line = <<"EOH";
$tr
<td class="text-center td-input">
   <label><input type="checkbox" id="$d{line}{id_table_record}" name="cb_$d{count}" class="cb_$d{count} cb no-margin form-control" /></label>
</td>
EOH

   #ajout de classes de tri + niveaux
    if($dm_permissions{sort})
    {
        my $tree_class = "";
        if($dm_cfg{tree})
        {
           $tree_class = 'list_tree_level list_tree_level_'.$d{level};
        }
        my %father = ();
		if($d{line}{id_father} > 0)
		{
			%father = read_table($dbh,$dm_cfg{table_name},$d{line}{id_father});
		}
		my $father_ordby = '';
		if($father{ordby} > 0)
		{
			$father_ordby = '<span class="badge hidden-lg hidden-md badge_father">'.$father{ordby}.'</span>';
		}
		$line .= <<"EOH";
<td class="tree-folder list_ordby $hidden_class $tree_class" data-title="Ordre"><div class="cell-value-badge">$father_ordby <span class="badge ordby_number ordby_number_$d{line}{id_table_record}">$d{line}{ordby}</span></div></td>
EOH
    }
	
	if($config{dm_show_id} == 1 || $dm_cfg{show_id} == 1)
	{
		my $code = getcode($dbh,$d{line}{id},$dm_cfg{file_prefixe});

		$line .= <<"EOH";
<td class="col_identifiant" data-title="Identifiant"><span>$code</span></td>
EOH
	}
	
    my %fields = (%dm_display_fields,%dm_lnk_fields);
    my $list_col_count = 1;
	my $i = 1;
    my $links = '';
	
   #BOUCHE DE CHAMPS D'AFFICHAGE***********************************************
    foreach $field (sort keys %fields)
    {
        my $col = $dm_display_fields{$field};

        #CHAMP AFFICHAGE SIMPLE
        if($col ne '')
        {
            my $tree_class = "";
            my $field_id = '';
            if($dm_cfg{tree})
            {
               $tree_class = 'list_tree_col list_tree_col_level_'.$d{level};
            }

			#CALCULE LA VALEUR, le TYPE, récupère également les spécificités
            my ($value,$type,$spec,$subtype,$list_style,$data_type) = list_map_body_col_value({cache_listboxtables=>\%cache_listboxtables,line=>$d{line},value=>$d{line}{$col},col=>$col,colg=>$d{colg}});

            my $inline_edit_class = '';
			my %dm_dfl_line = %{get_dm_dfl_line($col)};
 			# if($dm_dfl_line{data_type} ne '' && $dm_dfl_line{fieldtype} ne 'checkbox' && $dm_dfl_line{search} eq 'y')
			# {
				# my @keywords = split('\s',$d{keyword});
				# my $shadow_color = '';
				# my $raw_value = $value;
				# foreach my $keyword (@keywords)
				# {
					# $keyword = clean($keyword);
					# my $to = "<k>".$keyword.'</k>';
					# if($raw_value=~ /$keyword/ && $keyword ne '')
					# {
						# $value =~ s/$keyword/$to/g;
					# }
				# }
				# foreach my $keyword (@keywords)
				# {
					# $keyword = uc($keyword);
					# $keyword = clean($keyword);
					# $raw_value = uc($raw_value);
					# my $to = "<k>".$keyword.'</k>';
					# if($raw_value=~ /$keyword/ && $keyword ne '')
					# {
						# $value =~ s/$keyword/$to/g;
					# }
				# }
			# }
			# EDITION EN LIGNE
            if($dm_cfg{inline_edit} && $spec eq 'inline_edit')
            {
                $inline_edit_class = " inline_edit ";
                $field_id = $col;
				$value = <<"EOH";
<input type="text" name="$col" class="inline_edit_save form-control" value = "$value" />
EOH
            }
			#RENDU DE LA CELLULE AVEC LA VALEUR RECUE
			if($type eq 'textarea')
			{
				$value =~ s/\r*\n/\<br\>/g;
			}
			$line .= <<"EOH"
<td data-title="$dm_dfl_line{title}" rel="$field_id" class="td-cell-value cms_mig_cell cms_mig_cell_$i cms_mig_cell_$col cms_mig_cell_data_type_$data_type $tree_class $inline_edit_class" style="$list_style"><span class="cell-value">$value</span></td>
EOH
        }
        else
        {
            #LINK OR FUNCTIONS
            my $type = '';
            my $link_or_func = $dm_lnk_fields{$field};
            if($link_or_func =~ /^http/ || $link_or_func =~ /^\.\.\// || $link_or_func =~ /^\//)
            {
                #LINK***********************************************************
                my $menu_selected = get_quoted('sel') || '';
                my $id_col = $dm_cfg{id_col} || 'id';
                my $link = $link_or_func.$d{line}{$id_col};
                $link .= '&sel='.$menu_selected.'&colg='.$d{colg};
                my ($dum,$type_action,$info,$display_mode,$custom_style) = split(/\//,$field);
                if($display_mode eq 'custom_modal')
                {
                    $links.= <<"EOH";
<a href="#custom_modal" id="$d{line}{id_table_record}" role="button" class="custom_modal custom_modal_btn_$type_action btn btn-mini" data-toggle="modal">$info</a>
EOH
                }
                else
                {
                 $links.= <<"EOH";
<a class=" btn-default btn btn-mini btn_$type_action" href="$link">$info</a>
EOH
                }
            }
            elsif($link_or_func =~ /\*$/)
            {
                #FUNC***********************************************************
                $link_or_func =~ s/\*//;
                my $func = $dm_mapping_list{$link_or_func};
							
                my $info = &$func($dbh_data,$d{line}{id_table_record},$dm_cfg{map_param},\%d);
                my $tree_class = "";
                if($dm_cfg{tree})
                {
                   $tree_class = 'list_tree_func list_tree_func_level_'.$d{level};
                }
                my ($num,$fieldname,$infosupp) = split(/\//,$field);
				my $class_container = 'cell-value';
				my $class_container_td = 'cell-value-container';
				 # || $info =~ m/btn-info/ || $info =~ m/btn-primary/ || $info =~ m/btn-danger/
				if($info =~ m/btn-group/)
				{
					$class_container = 'cell-value-buttons';
					$class_container_td = 'cell-value-buttons-container';
				}
                $line .= <<"EOH";
<td data-title="$fieldname" class="$class_container_td td-cell-value $hidden_class $tree_class mig_cell_func mig_cell_func_$i $infosupp">
	<span class="$class_container">
		$info
	</span>
</td>
EOH
            }
        }
		$i++;
    }
    #LINKS**********************************************************************
    if(trim($links) ne '')
    {
    $line .= <<"EOH";
<td class="list_action list_action_supp">$links</td>
EOH
    }
	
   #COMMON ACTIONS**************************************************************
   my $nb_actions =  0;
   if($dm_cfg{visibility})   {    $nb_actions ++    }
   if($dm_permissions{editr})   {    $nb_actions ++    }
   if($dm_cfg{visualiser})   {    $nb_actions ++    }
   if($dm_permissions{deleter})   {    $nb_actions ++    }
   if($dm_permissions{corbeille})   {    $nb_actions ++    }
   if($dm_permissions{sort})   {    $nb_actions ++    }
   if($dm_permissions{duplicate})   {    $nb_actions ++    }
   if($dm_permissions{lock_on} || $dm_permissions{lock_off})   {    $nb_actions ++    }
   if($dm_permissions{viewpdf})   {    $nb_actions ++    }
   if($dm_permissions{telecharger})   {    $nb_actions ++    }
   if($dm_permissions{email})   {    $nb_actions ++    }
   
    foreach my $number ( 1 .. 20)
	{
		my $class = $dm_cfg{'list_custom_action_'.$number.'_class'};
		my $title = $dm_cfg{'list_custom_action_'.$number.'_title'};
		my $icon = $dm_cfg{'list_custom_action_'.$number.'_icon'};
		my $func = $dm_cfg{'list_custom_action_'.$number.'_func'};
		if($class ne '' || $title ne '' || $icon ne '' || $func ne '')
		{
			$nb_actions++;
		}
	}
   
   # see(\%d);
	
   
   if($d{line}{migcms_last_published_file} eq '')
   {
		$d{line}{migcms_last_published_file} = $d{line}{pdf_filename};
    }
    $d{line}{migcms_last_published_file} =~ s/\.pdf//;
  
if(1)
{

 if($dm_permissions{sort} || $dm_cfg{visibility} || $dm_cfg{visualiser} || $dm_permissions{editr} || $dm_permissions{deleter} || $dm_permissions{corbeille} || $dm_permissions{duplicate} || $dm_permissions{lock_on} || $dm_permissions{lock_off} || $dm_permissions{viewpdf} || $dm_permissions{telecharger} || $dm_permissions{email} || $dm_permissions{list_custom_action_1_class} ne '') 
   {
        $line .= <<"EOH";
<td class="list_action list_actions_$nb_actions" >
	<div class="btn-group_dis clearfix">
EOH
   }
   
   foreach my $number ( 1 .. 10)
	{
		$line .= get_list_custom_action_button($number,$d{line}{id_table_record},$d{colg},$d{line});
	} 

	my $pj_name = getcode($dbh,$d{line}{id_table_record},$dm_cfg{file_prefixe});
	if($dm_cfg{hide_prefixe} eq 'y')
	{
		$pj_name =~ s/\D//g;
		$pj_name = 'SKU:'.int($pj_name);
	}
	
   # EDIT************************************************************************
   my $edit_link = "$dm_cfg{self}&sw=add_form&id=$d{line}{id_table_record}";
   if($dm_cfg{disable_edit_link} eq 'y')
   {
	$edit_link = '#';
   }
   
   
    my $modifier = <<"EOH";
<a href="$edit_link" disabled data-placement="bottom" data-original-title="$migctrad{edit} $pj_name" id="$d{line}{id_table_record}" role="button" class=" animate_gear btn btn-info show_only_after_document_ready migedit_$d{line}{id_table_record} migedit dm_migedit"><i class="fa fa-fw fa-pencil"></i>$label</a>
EOH
# ($user{id} == 3 || $user{id} == 16 || 
   if(1 && ($config{edit_lightbox} eq 'y' || $dm_cfg{edit_lightbox} == 1))
   {
		 $modifier = <<"EOH";
			<button id="$d{line}{id_table_record}" role="button" class="btn btn-info show_only_after_document_ready migedit_lightbox_$d{line}{id_table_record} migedit_lightbox dm_migedit_lightbox" data-toggle="modal" data-target="#myModal"><i class="fa fa-fw fa-pencil"></i>$label</button>
EOH
	}

   if(($dm_permissions{editr}) && $d{line}{migcms_deleted} ne 'y' && $d{line}{migcms_lock} ne 'y')
   {
      $line .= <<"EOH";
$modifier 
EOH
   }
    my $modifier_eyeonly = <<"EOH";
<a href="$dm_cfg{self}&sw=add_form&id=$d{line}{id_table_record}" disabled data-placement="bottom" data-original-title="$migctrad{see} $pj_name" id="$d{line}{id_table_record}" role="button" class=" animate_gear btn btn-info show_only_after_document_ready migedit_$d{line}{id_table_record} migedit dm_migedit"><i class="fa fa-fw fa-eye"></i>$label</a>
EOH
   if(!($dm_permissions{editr}) && $dm_cfg{visualiser} == 1 && $d{line}{migcms_deleted} ne 'y' && $d{line}{migcms_lock} ne 'y')
   {
      $line .= <<"EOH";
$modifier_eyeonly
EOH
   }
   #DUPL************************************************************************
    my $dupliquer = <<"EOH";
<a href="#" disabled data-placement="bottom" data-original-title="$migctrad{duplicate} $pj_name" id="$d{line}{id_table_record}" role="button" class="btn btn-default show_only_after_document_ready dupliquer"><i class="fa fa-fw fa-copy"></i>$label</a>
EOH
   if($dm_permissions{duplicate} == 1 && $d{line}{migcms_deleted} ne 'y' && $d{line}{migcms_lock} ne 'y')
   {
      $line .= <<"EOH";
$dupliquer
EOH
   }
	 
	 my $nom_fichier = '';
   #viewpdf************************************************************************
	if(-e '../usr/documents/'.$d{line}{migcms_last_published_file}.'.pdf')
	{
		$nom_fichier = $d{line}{migcms_last_published_file}.'.pdf';
	}
	elsif(-e '../usr/documents/'.$d{line}{migcms_last_published_file})
	{
		$nom_fichier = $d{line}{migcms_last_published_file};
	}
	else
	{
		$d{line}{migcms_last_published_file} = '';
	}
	
	
	
	my $viewpdf = <<"EOH";
<a href="../usr/documents/$nom_fichier" data-funcpublish="$dm_cfg{func_publish}" disabled data-placement="bottom" target="_blank" data-original-title="$migctrad{action_viewpdf} $pj_name" id="$d{line}{id_table_record}" role="button" class="btn btn-default show_only_after_document_ready viewpdf"><i class="fa fa-eye  fa-fw"></i>$label</a>
EOH
   
   #config pour désactiver le bouton si aucun document disponible
	my $fichier_existe = 0;
	if(-e '../usr/documents/'.$nom_fichier && $nom_fichier ne '')
	{
		$fichier_existe = 1;
	}
	if($dm_cfg{disable_if_migcms_last_published_file_not_exist} eq 'y' && !$fichier_existe ) {
		$viewpdf = <<"EOH";
			<a href="#" id="" role="button" class="btn btn-default disabled show_only_after_document_ready "><i class="fa fa-eye  fa-fw"></i>$label </a>
EOH
	}
   
   
   if($dm_permissions{viewpdf} == 1 && $d{line}{migcms_deleted} ne 'y')
   {
      $line .= <<"EOH";
$viewpdf
EOH
   }
    
	#telecharger************************************************************************
    my $telecharger = <<"EOH";
<a href="../usr/documents/$nom_fichier" data-funcpublish="$dm_cfg{func_publish}"  target="_blank" download disabled data-placement="top" data-original-title="$migctrad{action_telecharger}  $pj_name" id="$d{line}{id_table_record}" role="button" class="btn btn-default show_only_after_document_ready telecharger"><i class="fa fa-download  fa-fw"></i>$label</a>
EOH
   
    #config pour désactiver le bouton si aucun document disponible
	if($dm_cfg{disable_if_migcms_last_published_file_not_exist} eq 'y' && !$fichier_existe ) {
		$telecharger = <<"EOH";
			<a href="#" id="" role="button" class="btn btn-default disabled show_only_after_document_ready "><i class="fa fa-download  fa-fw"></i>$label </a>
EOH
	}
   
   if($dm_permissions{telecharger} == 1 && $d{line}{migcms_deleted} ne 'y')
   {
      $line .= <<"EOH";
$telecharger
EOH
   }
   
   #email************************************************************************
    my $email = <<"EOH";
<a href="#" disabled data-placement="bottom" data-original-title="$migctrad{action_email}  $pj_name" id="$d{line}{id_table_record}" role="button" class="btn btn-default show_only_after_document_ready send_by_email"><i class="fa fa-paper-plane-o  fa-fw"></i>$label</a>
EOH

	#config pour désactiver le bouton si aucun document disponible
	if($dm_cfg{disable_if_migcms_last_published_file_not_exist} eq 'y' && !$fichier_existe ) {
		$email = <<"EOH";
			<a href="#" id="" role="button" class="btn btn-default disabled show_only_after_document_ready "><i class="fa fa-paper-plane-o  fa-fw"></i>$label </a>
EOH
	}

   if($dm_permissions{email} == 1 && $d{line}{migcms_deleted} ne 'y' )
   {
      $line .= <<"EOH";
$email
EOH
   }   
   
     #SORT************************************************************************
	my $trier = <<"EOH";
<a href="#" id="$d{line}{id_table_record}" disabled data-placement="bottom" data-original-title="$migctrad{dm_sort}  $pj_name" role="button" class="btn btn-default show_only_after_document_ready list_sort list_sort_$d{line}{id_table_record}"><i class="fa fa-fw fa-sort"></i>$label</a>
EOH
   if($dm_permissions{sort} && $d{line}{migcms_deleted} ne 'y' && $d{line}{migcms_lock} ne 'y')
   {
      $line .= <<"EOH";
$trier
EOH
   }
   #VISIBLE / INVISIBLE ********************************************************
   if($dm_cfg{visibility} && $d{line}{migcms_deleted} ne 'y' && $d{line}{migcms_lock} ne 'y')
   {
      if($d{line}{visible} eq 'y')
      {
         # Cliquez ici pour rendre cet élément invisible
         $line .= <<"EOH";
<a href="$dm_cfg{self}&sw=ajax_changevis" disabled data-placement="bottom" data-original-title="$migctrad{dm_make_visibleinvisible}  $pj_name" id="$d{line}{id_table_record}" role="button" class="btn btn-success  show_only_after_document_ready link_changevis_$dm_cfg{nolabelbuttons} link_changevis link_changevis_$d{line}{id}"><span class="fa fa-check  fa-fw"></span>$label</a>
EOH
     }
     else
     {
         # Cliquez ici pour rendre cet élément visible
         $line .= <<"EOH";
<a href="$dm_cfg{self}&sw=ajax_changevis" disabled data-placement="top" data-original-title="$migctrad{dm_make_visibleinvisible} $pj_name" id="$d{line}{id_table_record}" role="button" class="btn btn-warning  show_only_after_document_ready link_changevis_$dm_cfg{nolabelbuttons} link_changevis link_changevis_$d{line}{id} set_visible toggle_visible"><span class="fa fa-ban fa-fw"></span>$label</a>
EOH
     }
    }
  #CORBEILLE**********************************************************************
   my $corbeille = <<"EOH";
<a href="#" disabled data-placement="bottom" data-original-title="$migctrad{archive} $pj_name" id="$d{line}{id_table_record}" role="button" style="background-color:#dddddd!important" class="btn btn-default list_corbeille show_only_after_document_ready"><i class="fa fa-archive fa-fw"></i>$label</a>
EOH
# && $d{line}{migcms_lock} ne 'y'
   if($dm_permissions{corbeille} == 1 && $d{line}{migcms_deleted} ne 'y' )
   {
      $line .= <<"EOH";
$corbeille
EOH
   }
   
      #lock off************************************************************************
    my $lock_off = <<"EOH";
<a href="#" disabled data-placement="bottom" data-original-title="$migctrad{lock_off} $pj_name" id="$d{line}{id_table_record}" role="button" class="btn btn-default show_only_after_document_ready lock_off dm_lock_off"><i class="fa fa-unlock-alt fa-fw"></i>$label</a>
EOH
   if($dm_permissions{lock_off} == 1 && $d{line}{migcms_deleted} ne 'y' && $d{line}{migcms_lock} eq 'y')
   {
      $line .= <<"EOH";
$lock_off
EOH
   }
   
    #lock on************************************************************************
    my $lock_on = <<"EOH";
<a href="#" disabled data-placement="bottom" data-original-title="$migctrad{lock_on} $pj_name" id="$d{line}{id_table_record}" role="button" class="btn btn-danger show_only_after_document_ready lock_on"><i class="fa fa-lock fa-fw"></i>$label</a>
EOH
   if($dm_permissions{lock_on} == 1 && $d{line}{migcms_deleted} ne 'y' && $d{line}{migcms_lock} ne 'y')
   {
      $line .= <<"EOH";
$lock_on
EOH
   }
   
   
   #restaurer**********************************************************************
   my $restaurer = <<"EOH";
<a href="#" disabled data-placement="bottom" data-original-title="$migctrad{restore} $pj_name" id="$d{line}{id_table_record}" role="button" class="btn btn-info list_restaurer show_only_after_document_ready"><i class="fa fa-history fa-fw"></i>$label</a>
EOH
   if($dm_permissions{corbeille} == 1 && $d{line}{migcms_deleted} eq 'y' )
   {
      $line .= <<"EOH";
$restaurer
EOH
   }
   #DELETE**********************************************************************
   my $supprimer = <<"EOH";
<a href="#" disabled data-placement="bottom" data-original-title="$migctrad{delete} $pj_nam" id="$d{line}{id_table_record}" role="button" class="btn btn-danger list_delete show_only_after_document_ready"><i class="fa fa-trash fa-fw"></i>$label</a>
EOH
   if($dm_permissions{deleter} && $d{line}{migcms_deleted} ne 'y' && $d{line}{migcms_lock} ne 'y')
   {
      $line .= <<"EOH";
$supprimer
EOH
   }
    
	foreach my $number ( 11 .. 20)
	{
		$line .= get_list_custom_action_button($number,$d{line}{id_table_record},$d{colg},$d{line});
	}
   
    if($dm_permissions{sort} || $dm_cfg{visibility} || $dm_cfg{visualiser} || $dm_permissions{editr} || $dm_permissions{deleter} || $dm_permissions{corbeille} || $dm_permissions{duplicate} || $dm_permissions{lock_on}|| $dm_permissions{lock_off} || $dm_permissions{visualiser} || $dm_permissions{telecharger} || $dm_permissions{email})
    {
       $line .='</div></td>';
    }
	
	}
    $line .= <<"EOH";
</tr>
EOH
    return $line;
}


sub get_list_custom_action_button
{
	my $number = $_[0];
	my $id = $_[1];
	my $colg = $_[2];
	my %line = %{$_[3]};

	
	my $button = '';
	my $class = $dm_cfg{'list_custom_action_'.$number.'_class'};
	my $title = $dm_cfg{'list_custom_action_'.$number.'_title'};
	my $icon = $dm_cfg{'list_custom_action_'.$number.'_icon'};
	my $func = $dm_cfg{'list_custom_action_'.$number.'_func'};
	if($func ne '')
	{
		
		return &$func($id,$colg,\%line,$dm_cfg{table_name});
	}
	else
	{
		my $list_custom_action = <<"EOH";
			<a id="$id" class=" btn-default show_only_after_document_ready btn $class" 
			href="#" 
			data-original-title="$title" title="">
				$icon
			</a>
EOH
	
		my $ok = 1;
		if($class ne '')
		{
			if($d{line}{migcms_last_published_file} eq '')
			{
				$d{line}{migcms_last_published_file} = $d{line}{pdf_filename};
			}
			if($dm_cfg{'list_custom_action_'.$number.'_ok_only_if_file_published'} && $d{line}{migcms_last_published_file} eq '')
			{
				$ok = 0;	
			}
			elsif($dm_cfg{'list_custom_action_'.$number.'_ok_only_if_file_not_published'}  && $d{line}{migcms_last_published_file} ne '')
			{
				$ok = 0;
			}
			elsif($dm_cfg{'list_custom_action_'.$number.'_ok_only_if_file_not_lock'}  && $d{line}{migcms_lock} eq 'y')
			{
				$ok = 0;
			}
			
			if($ok)
			{
				$button = <<"EOH";
					$list_custom_action
EOH
			}
		}
		return $button;
	}
}


sub get_dm_dfl_line
{
	my $col = $_[0];
	my %line = ();
	foreach $field_line (sort keys %dm_dfl)
    {
        #certains types ne passent pas à cause des alias de jointures ex: code_project != project_name
        ($ordby,$field_name) = split(/\//,$field_line);
        if($field_name eq $col)
        {
           %line = %{$dm_dfl{$field_line}};
		   return \%line;
		}
	}
}
################################################################################
# list_map_body_col_value
################################################################################
sub list_map_body_col_value
{
    my %d = %{$_[0]};
	
	my %cache_listboxtables = %{$d{cache_listboxtables}};
    my $col_value = '';
    my $traductible = 0;
    my $cb = 0;
    my $field_name = '';
    my $name = '';
    my $type = '';
    my $subtype = '';
    my $data_type = '';
    my $default_value = '';
    my $inline_edit = '';
	my $rec_field_name = '';
	my $rec_field_line = '';
	my $multiple = 0;
	my $lbtable = '';
	my $lbkey = '';
	my $lbdisplay = '';
	my $lbwhere = '';
	my $lbwhere_display = '';
    my $spec = '';
    my $title = '';
    my $nopdf = '';
    my %line = ();
    foreach $field_line (sort keys %dm_dfl)
    {
        #certains types ne passent pas à cause des alias de jointures ex: code_project != project_name
		($ordby,$field_name) = split(/\//,$field_line);
        if($field_name eq $d{col})
        {
           %line = %{$dm_dfl{$field_line}};
           $type =  $line{fieldtype};
		   $list_style = $line{list_style};
           $subtype = $line{subtype};
           $data_type = $line{data_type};
           $default_value = $line{default_value};
           $inline_edit = $line{inline_edit};
		   $multiple = $line{multiple};
		   $lbtable = $line{lbtable};
		   $lbkey = $line{lbkey};
		   $title = $line{title};
		   $lbdisplay = $line{lbdisplay};
		   $lbwhere = $line{lbwhere};
		   $lbwhere_display = $line{lbwhere_display};
		   $translate = $line{translate};
		   $nopdf = $line{nopdf};
		   $rec_field_name = $field_name;
		   $rec_field_line = $field_line;
           if($inline_edit == 1)
           {
              $spec = 'inline_edit';
           }
           $name =  $field_name;
           if($type eq 'text_id' || $type eq 'textarea_id' || $type eq 'textarea_id_editor' || $translate == 1)
           {
              $traductible = 1;
           }
           elsif($type eq 'checkbox')
           {
              $cb = 1;
           }
        }
    }
    if($type eq 'listboxtable' || $data_type eq 'listboxtable')
    {
        $d{value} =~ s/\'/\\\'/g;
		if($multiple == 1)
		{
			if($d{render} ne 'excel' && $d{render} ne 'csv')
			{
				$col_value = edit_lines_listboxes({from=>'list',rec=>$d{line},translate=>$d{translate},multiple=>1,debug=>0,'selected_only'=>1,disabled=>'disabled="disabled"','list_btns' => 1,type=>$type,field_name=>$rec_field_name,field_line=>$rec_field_line});
			}
		}
		else
		{
			#valeur brute
			$col_value = $d{value};
			
			#valeur affichage (cache ou via sql))
			if($dm_cfg{enable_cache_listboxtables} == 1)
			{
				$col_value = $cache_listboxtables{$name}{$d{value}};
			}
			else
			{
				my $where = "$lbkey = '$col_value' $lbwhere_display";
				my %lbvalue = sql_line({debug=>0,debug_results=>0,table=>$lbtable,select=>"$lbdisplay as display",where=>$where});
				$col_value = $lbvalue{display};
			}
			if($traductible == 1)
			{
				$col_value = get_traduction({debug=>0,id_language=>$d{colg},id=>$col_value});
			}
			
			#liste select
			if($d{render} ne 'excel' && $d{render} ne 'csv' && $line{list_edit} == 1)
			{
				my $list_edit = '<select style="min-width:110px" id="'.$d{line}{id}.'" name="'.$rec_field_name.'" class="form-control save_list_edit"><option value=""></option>';
				
				
				
				
				my @lbvalues = sql_lines({table=>$lbtable,select=>"$lbdisplay as display,$lbkey as cle",where=>"$lbwhere"});
				foreach $lbvalue (@lbvalues)
				{
					my %lbvalue = %{$lbvalue};
					my $selected = '';
					if($lbvalue{cle} eq $d{value})
					{
						 $selected = ' selected="selected" ';
					}					
					
					if($line{list_edit_clean_prefixe} == 1)
					{
						my @labels = split(/\s/,$lbvalue{display});
						shift @labels;
						$lbvalue{display} = join(" ",@labels);
					}
					
					$list_edit .= '<option value="'.$lbvalue{cle}.'" '.$selected.'>'.$lbvalue{display}.'</option>';
				}			
				$list_edit .= '</select>';
				$col_value = $list_edit;
			}		
		}
    }
    elsif($type eq 'listbox')
    {
		$col_value = $d{value};
		if($d{render} ne 'excel' && $d{render} ne 'csv')
		{
			my $list_edit = '<select id="'.$d{line}{id}.'" name="'.$rec_field_name.'" class="form-control save_list_edit"><option value=""></option>';
			
			foreach my $field_value (sort keys %{$line{fieldvalues}})
			{
				my ($test_ordby,$test_value) = split(/\//,$field_value);
				if($test_ordby > 0 && $test_value eq $d{value})
				{
					$col_value = $line{fieldvalues}{$field_value};
					$list_edit .= '<option selected value="'.$test_value.'">'.$test_value.'</option>';
				}	
				else
				{
					$list_edit .= '<option value="'.$test_value.'">'.$test_value.'</option>';
				}			
			}
			$list_edit .= '</select>';
			if($line{list_edit} == 1)
			{
				$col_value = $list_edit;
			}
		}
    }
    elsif($traductible)
    {
		$col_value = get_traduction({debug=>0,id_language=>$d{colg},id=>$d{value}});
    }
    elsif($cb)
    {
        my $checked = '';
        if($d{line}{$name} eq 'y')
        {
          $checked = ' checked = "checked" ';
        }
        $col_value = <<"EOH";
<div class="td-input">
	<input type="checkbox" $checked name="$d{col}" class="list_autosavecb dm_col_$d{col} form-control" value="$d{line}{id}" />
</div>
EOH
    }
    elsif($data_type eq 'date')
    {
        if($d{render} ne 'excel' && $d{render} ne 'csv')
		{
			
			$d{value} = sql_to_human_date($d{value});
			
		}
		 if($d{value} eq '00/00/0000' || $d{value} eq '0000-00-00' || trim($d{value}) eq '//')
		 {
			$d{value} = '';
		 }
         $col_value = $d{value};
    }
	elsif($data_type eq 'datetime')
    {
        if($d{render} ne 'excel' && $d{render} ne 'csv')
		{
			my ($sql_date,$sql_time) = split (/ /,$d{value});
			$d{value} = sql_to_human_date($sql_date).' '.sql_to_human_time($sql_time);
			
		}
		 if($d{value} eq '00/00/0000 00:00' || $d{value} eq '0000-00-00 00:00' || trim($d{value}) eq '// :' || $d{value} =~ /0000/)
		 {
			$d{value} = '';
		 }
         $col_value = $d{value};
    }
	elsif($data_type eq 'euros' || $data_type eq 'number')
    {
		$d{value} = sprintf("%.2f",$d{value});
		$d{value} =~ s/\./\,/g;
		
         $col_value =<<"EOH";
$d{value} €
EOH
		if($d{render} eq 'excel' && $d{render} ne 'csv')
		{
			$col_value = $d{value};
		}
    }
	elsif($data_type eq 'email')
    {
         $col_value =<<"EOH";
<a href="mailto:$d{value}">$d{value}</a>
EOH
		if($d{render} eq 'excel' && $d{render} ne 'csv')
		{
			$col_value = $d{value};
		}
    }
	elsif($data_type eq 'gsm' || $data_type eq 'phone')
    {
         $col_value =<<"EOH";
<a href="tel:$d{value}">$d{value}</a>
EOH
		if($d{render} eq 'excel' && $d{render} ne 'csv')
		{
			$col_value = $d{value};
		}
    }
	elsif($data_type eq 'perc')
    {
		$d{value} = sprintf("%.2f",$d{value});
         $col_value =<<"EOH";
$d{value} %
EOH
		if($d{render} eq 'excel' && $d{render} ne 'csv')
		{
			$col_value = $d{value};
		}
    }
    elsif($data_type eq 'time')
    {
        if($d{render} ne 'excel' && $d{render} ne 'csv')
		{
			$d{value} = sql_to_human_time($d{value},'h');
		}
         $col_value =<<"EOH";
$d{value}
EOH
    }
    elsif($data_type eq 'datetime')
    {
         my ($date,$time) = split (/ /,$d{value});
         $d{value} = sql_to_human_date($date).' '.sql_to_human_time($time,'h');
         $col_value =<<"EOH";
$d{value}
EOH
    }
    else
    {
        $col_value =<<"EOH";
$d{value}
EOH
    }
    
	if($dm_cfg{excel10aulieudeyn} == 1)
	{
		if(trim($col_value) eq '') {	$col_value = $default_value;}
		if(trim($col_value) eq 'y' || trim($col_value) eq 'Oui') {$col_value = 1;}
		if(trim($col_value) eq 'n' || trim($col_value) eq 'Non') {$col_value = 0;}
	}
	
	
	
	
	return ($col_value,$type,$spec,$subtype,$list_style,$data_type,$lbtable,$lbkey,$lbdisplay,$title,$nopdf);
}
################################################################################
# list_pagination
################################################################################
sub list_pagination
{
    my %d = %{$_[0]};
    my $pagination = <<"EOH";
<ul class="pagination pagination">
EOH
    my $current_page =  $d{page} || 1;
    my $nr = $d{nr} || 25;
    my $nr_total = $d{nr_total} || 1;
    my $nombre_numeros = $d{nombre_numeros} || 1;
    my $previous_page=$current_page-1;
    my $next_page=$current_page+1;
    my $begin = $nr * ($current_page-1);
    my $end = $begin + $nr;
    my $nombre_numeros_supp = ($nombre_numeros - 1) / 2;
    my $begin_class = '';
    my $previous_class = '';
    my $next_class = '';
    my $end_class = '';
    my $calcul_begin_page = $current_page - $nombre_numeros_supp;
    if($calcul_begin_page < 1)
    {
        $calcul_begin_page = 1;
    }
    my $begin_page=$calcul_begin_page;
    my $calcul_end_page_max = ($nr_total-1) / $nr;
    my $end_page_max=int($calcul_end_page_max) + 1;
    my $calcul_end_page = $current_page + $nombre_numeros_supp;
    if($calcul_end_page - $begin_page < $nombre_numeros)
    {
      $calcul_end_page +=  ($nombre_numeros - ($calcul_end_page - $begin_page)) -1 ;
    }
    if($calcul_end_page > $end_page_max)
    {
        $calcul_end_page = $end_page_max;
    }
    my $end_page=$calcul_end_page;
    if($end_page - $begin_page < $nombre_numeros)
    {
      $begin_page -=  ($nombre_numeros - ($end_page - $begin_page)) -1;
    }
    if($begin_page < 1)
    {
        $begin_page = 1;
    }
    if($current_page == 1)
    {
        $begin_class = " disabled ";
        $previous_class = " disabled ";
		if($current_page == $end_page_max)
		{
			$next_class = " disabled ";
			$end_class = " disabled ";
		}
    }
    elsif($current_page == $end_page_max)
    {
        $next_class = " disabled ";
        $end_class = " disabled ";
    }
    $pagination .= <<"EOH";
	<li class="admin_list_pagination_begin $begin_class"><a href="#">$migctrad{begin}</a></li>
	<li class="admin_list_pagination_previous $previous_class"><a href="#">$migctrad{dm_sort_up}</a></li>
EOH
        my $count_page = 1;
        for $number_page ($begin_page .. $end_page)
        {
            my $hidden_phone = '';
            if($count_page > 3)
            {
                # $hidden_phone = 'hidden-phone';
            }
            if($current_page == $number_page)
			{
				$hidden_phone .= ' active ';
			}
			$pagination.=<<"EOH";
	<li class="pagination_page_link_$number_page $hidden_phone"><a href="#" id="$number_page" class="numpage hidden-xs">$number_page</a></li>
EOH
            $count_page++;
        }
		if(0 && $end_page != $end_page_max)
		{
		$pagination.=<<"EOH";
	<li class="disabled $hidden_phone"><a href="#" id="" class="disabled hidden-xs">...</a></li>
	<li class="pagination_page_link_$end_page_max $hidden_phone"><a href="#" id="$end_page_max" class="numpage hidden-xs">$end_page_max</a></li>
EOH
		}
    $pagination.=<<"EOH";
	<li class="$next_class admin_list_pagination_next"><a href="#">$migctrad{dm_sort_down}</a></li>
	<li class="$end_class admin_list_pagination_end"><a href="#">$migctrad{end}</a></li>
</ul>
$d{nbr_box}
EOH
    # if($begin_page == $end_page)
    # {
        # $pagination = '';
    # }
	
	if($config{disable_toggle_cols_form} ne 'y' && $dm_cfg{disable_toggle_cols_form} != 1)
	{
		$pagination .= get_toggle_cols_form();
	}

	
    return ($pagination,$end_page_max);
}

sub reset_toggle_cols_db
{
	$stmt = "delete FROM migcms_user_script_cols WHERE id_user = '$user{id}' AND id_script = '".get_quoted('sel')."' ";
    execstmt($dbh,$stmt);
	http_redirect(get_quoted('self'));
}



sub get_toggle_cols_db
{
	foreach $field_line (sort keys %dm_dfl)
	{
		($ordby,$field_name) = split(/\//,$field_line);
		my $afficher = 'n';
		if(get_quoted('toggle_cols_'.$field_name) eq 'y')
		{
			$afficher = 'y';
		}
		if($field_name eq '')
		{
			next();
		}
		
		my $ordby = get_quoted('ordby_'.$field_name);
		if($field_name eq 'id')
		{
			$ordby = 1;
		}
		elsif($field_name eq 'migcms_moment_create')
		{
			$ordby = 2;
		}
		elsif($field_name eq 'migcms_id_user_create')
		{
			$ordby = 3;
		}
		else
		{
			$ordby += 3;
		}
		
		my %update_migcms_user_script_col = 
		(
			id_script => get_quoted('sel'),
			id_user => $user{id}, 
			field => $field_name, 
			ordby => $ordby,
			afficher => $afficher, 
		);

		sql_set_data({dbh=>$dbh,debug=>0,debug_results=>0,table=>'migcms_user_script_cols',data=>\%update_migcms_user_script_col, 
		where=>"id_script='$update_migcms_user_script_col{id_script}' AND id_user='$update_migcms_user_script_col{id_user}' AND field='$update_migcms_user_script_col{field}' "
		});
	}
	http_redirect(get_quoted('self'));
}

sub get_list_cols_search
{
	my $list_cols_search = '';
	
	foreach $field_line (sort keys %dm_dfl)
	{
		my $libelle = $dm_dfl{$field_line}{title};
		if($dm_cfg{show_tab_in_toggle_form} eq 'y')
		{
			$libelle = "&nbsp;$dm_dfl{$field_line}{tab} > $dm_dfl{$field_line}{title}";
		}
		
		
		if($dm_dfl{$field_line}{hide_colsearch} != 1 
		&& $dm_dfl{$field_line}{fieldtype} ne 'checkbox' 
		&& $dm_dfl{$field_line}{fieldtype} ne 'titre' 
		&& $dm_dfl{$field_line}{fieldtype} ne 'button' 
		&& $dm_dfl{$field_line}{fieldtype} ne 'files_admin'
		&& $dm_dfl{$field_line}{fieldtype} ne 'listbox'
		&& $dm_dfl{$field_line}{data_type} ne 'password'
		&& $dm_dfl{$field_line}{data_type} ne 'treeview'	
		&& $dm_dfl{$field_line}{title} ne 'Tags'	
		
		)
		{
			($ordby,$field_name) = split(/\//,$field_line);
			if($dm_dfl{$field_line}{search} eq 'y')
			{
				 $list_cols_search .=<<"EOH";
					<option selected value="$field_name">$libelle</option>
EOH
			}
			else
			{
				$list_cols_search .=<<"EOH";
					<option value="$field_name">$libelle</option>
EOH
			}
		}
	}
	
	$list_cols_search .=<<"EOH";
	<script type="text/javascript">
jQuery(document).ready(function() 
{
	jQuery('.mig_col_search').multiselect({
	dropRight: true,
		buttonText: function(options, select) 
		 {
			if(options.length > 1)
			{
				return 'Rechercher sur ces '+options.length+' colonnes...';
			}
			if(options.length == 1)
			{
				return 'Rechercher sur cette colonne...';
			}
			if(options.length == 0)
			{
				return 'La recherche ne porte sur aucune colonne !';
			}
			
		},
		templates: {
                ul: '<ul class="multiselect-container dropdown-menu"></ul>',
                filter: '<li class="multiselect-item filter"><div class="input-group"><span class="input-group-addon"><i class="fa fa-search"></i></span><input class="form-control multiselect-search" type="text"></div></li>',
                filterClearBtn: '<span class="input-group-btn"><button class="btn btn-default multiselect-clear-filter" type="button"><i class="fa fa-times"></i></button></span>'
            }
		
		});
		//.removeClass('hide');
});
</script>
EOH
	return $list_cols_search;
}

sub get_toggle_tags_form
{
	# log_debug('','vide','get_toggle_tags_form');
	my $form = <<"EOH";
<script type="text/javascript">
jQuery(document).ready(function() 
{
		jQuery('.tags_multipleselect').multiselect({
		enableCaseInsensitiveFiltering: true,
		maxHeight: 200,
		buttonWidth: '100%',
		 buttonText: function(options, select) 
		 {
			var labels = [];
			 if (options.length === 0) {
                    return 'Veuillez sélectionner ...';
                }
				
			 options.each(function(i) 
			 {
				
				if (jQuery(this).attr('label') !== undefined) {
					 labels.push(jQuery(this).attr('label'));
				 }
				 else {
					 labels.push(jQuery(this).html());
				 }
			 });
			 return labels.join(', ') + '';
		}
		,
		templates: {
                ul: '<ul class="multiselect-container dropdown-menu"></ul>',
                filter: '<li class="multiselect-item filter"><div class="input-group"><span class="input-group-addon"><i class="fa fa-search"></i></span><input class="form-control multiselect-search" type="text"></div></li>',
                filterClearBtn: '<span class="input-group-btn"><button class="btn btn-default multiselect-clear-filter" type="button"><i class="fa fa-times"></i></button></span>'
            }
		});

		jQuery('.set_list_tags_vals').click(function()
		{
			var target = jQuery('#list_tags_vals');
			
			var ids = jQuery('.tags_multipleselect option:selected').map(function(a, item){return item.value;});
			var list_ids = '';
			jQuery.each(ids,function(index,value)
			{
				list_ids += value+',';
			});
			jQuery('#list_tags_vals').val(list_ids);
			
			var names = jQuery('.tags_multipleselect option:selected');
			var array_names = new Array();
			var list_names = '';
			
			names.each(function(i)
			{
				array_names.push('<span class="badge">'+jQuery(this).attr('data-type')+': <b>'+jQuery(this).html()+'</b></span>');
			});
			
			list_names = array_names.join(" ET ");
			jQuery('#list_tags_vals').val(list_ids);

			jQuery('.tags_preview_container').html(list_names);
			jQuery('.modal-header button').click();
			jQuery('#list_search').click();
			
			
			return false;
		});		
});
</script>
<div class="row">
EOH

	# my @migcms_members_tags = sql_lines({table=>'migcms_members_tags',where=>"visible='y'",select=>'type',groupby=>type,ordby=>'type'});
	# my @migcms_members_tags = sql_lines({table=>'migcms_members_tags t, lnk_member_tag lnk, migcms_member_dirs d',where=>"t.id_migcms_member_dir = d.id AND t.visible='y' AND lnk.id_migcms_member_tag = t.id",select=>'d.name',ordby=>'name'});
	my @migcms_members_tags = sql_lines({debug=>1,debug_results=>1,table=>'migcms_member_dirs',where=>"visible='y'",select=>'name,id',ordby=>'name'});
	my $type_precedent = '';
	foreach $migcms_members_tag (@migcms_members_tags)
	{
		my %migcms_members_tag = %{$migcms_members_tag};
		# my %migcms_member_dir = read_table($dbh,'migcms_member_dirs',$migcms_members_tag{id_migcms_member_dir});
		
		($name1,$name2) = split(/\:/,$migcms_members_tag{name});
		if($name2 eq '')
		{
			# $name2 = $name1;
		}
		$name2 =~ s/^t\d*\s//g;	
		log_debug($name2,'','get_toggle_tags_form');
		$form .= <<"EOH";
			<div class="col-md-12 text-left">
EOH
		my $vide = 1;
		
		my $type_groupe = $name1;
		my $saut = '';
		if($type_precedent eq $type_groupe)
		{
			$type_groupe = '<b>'.$name1.'</b>';
		}
		else
		{
			# $saut = '<hr />';
		}
		$type_precedent = $name1;
		
		my $select_tags = <<"EOH";
				$saut
				<div class="row">
					<div class="col-md-4 text-left">
						<b>$migcms_members_tag{name}</b>
					</div>	
					<div class="col-md-8 text-left">
EOH
						
						$select_tags .= <<"EOH";
						<select class="tags_multipleselect" multiple="multiple">
EOH
						$migcms_members_tag{type} =~ s/\'/\\\'/g;
						
						# my @migcms_member_tags_values = sql_lines({table=>'migcms_members_tags',where=>"visible='y' AND type='$migcms_members_tag{type}'",select=>'id,name',ordby=>'name'});
						my @migcms_member_tags_values = ();
						my %test_nb_lnk_member_tag = sql_line({select=>"COUNT(*) as nb",table=>'lnk_member_tag'});
						if($test_nb_lnk_member_tag{nb} > 0)
						{
							@migcms_member_tags_values = sql_lines({debug=>0,debug_results=>0,table=>'migcms_members_tags t, lnk_member_tag lnk',groupby=>'t.id',where=>"t.visible='y' AND lnk.id_migcms_member_tag = t.id AND t.id_migcms_member_dir='$migcms_members_tag{id}'",select=>'t.id,t.name',ordby=>'t.name'});
						}
						else
						{
							@migcms_member_tags_values = sql_lines({debug=>0,debug_results=>0,table=>'migcms_members_tags',where=>"visible='y' AND id_migcms_member_dir='$migcms_members_tag{id}'",select=>'id,name',ordby=>'name'});
						}
						foreach $migcms_member_tags_value (@migcms_member_tags_values)
						{
							my %migcms_member_tags_value = %{$migcms_member_tags_value};
							
							# my %nb = sql_line({select=>"COUNT(*) as nb",table=>$dm_istcfg{table_name},where=>"tags LIKE '%,$migcms_member_tags_value{id},%'"});
							# if($nb{nb} > 0 || $dm_cfg{tags_show_if_zero} == 1)
							# {($nb{nb})
								$vide = 0;
								$select_tags .= <<"EOH";
								<option data-type="$name2" value="$migcms_member_tags_value{id}">$migcms_member_tags_value{name} </option>
EOH
							# }

							# log_debug($migcms_member_tags_value{id},'','get_toggle_tags_form');
							# log_debug($migcms_member_tags_value{name},'','get_toggle_tags_form');
						}
						$select_tags .= <<"EOH";
										</select>
EOH

						$select_tags .= <<"EOH";
									</div>
								</div>
EOH
						if($vide == 0)
						{
							$form .= $select_tags;
						}
						
						
					

						$form .= <<"EOH";
							</div> 
EOH
	}
	
	$form .= <<"EOH";
			</div>	
EOH

my $editer = <<"EOH";

	<!-- Modal -->
	<div class="modal fade" id="get_toggle_tags_form" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
	  <div class="modal-dialog" style="width:80%!important;" role="document">
		<div class="modal-content">
		  <div class="modal-header">
			<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
			<h4 class="modal-title" id="myModalLabel">Choisissez un ou plusieurs tags</h4>
		  </div>
		  <div class="modal-body">
                $form
				<br />
				<div class="text-center">
					<a class="btn btn btn-success set_list_tags_vals">Valider</a>
				</div>
		  </div>
		</div>
	  </div>
	</div>
EOH

	return $editer;
}

sub get_toggle_cols_form
{
	my $form = <<"EOH";
	<form class="text-left get_toggle_cols_form" method="POST" action = "">
	<input type="hidden" name="sw" value="get_toggle_cols_db" />
	<input type="hidden" name="sel" value="$sel" />
	<input type="hidden" name="self" value="$dm_cfg{self}" />
	<table class="table table-hover">
	<thead>
		<tr>
			<th>
				
			</th>
			<th>
				Champs
			</th>
			<th style="width:130px">
				Ordre
			</th>
		</tr>
	</thead>
	<tbody>
EOH
	  my $line_counter = 1;
	  my @custom_cols = sql_lines({table=>'migcms_user_script_cols',where=>"id_script='$sel' AND id_user='$user{id}'"});
	  foreach $field_line (sort keys %dm_dfl)
	  {
			($ordby,$field_name) = split(/\//,$field_line);
			%line = %{$dm_dfl{$field_line}};
			$type =  $line{fieldtype};
			$data_type =  $line{data_type};

			# if($type eq 'files_admin' || $line{hidden} == 1)
			if($type eq 'files_admin')
			{
				next;
			}
			my $checked = '';
			
			#affiche par defaut les colonnes de dm_display_fields
			my %fields = (%dm_display_fields);
			foreach $field (sort keys %fields )
			{
				my $col = $dm_display_fields{$field};
				
				#default value for check				
				if($field_name eq $col || $field_name eq 'id')
				{
					$checked = " checked ";
					last;
				}
			}
			
			#affiche les choix si disponibles
			my $ordre = '';
			foreach $custom_col (@custom_cols )
			{
				my %custom_col = %{$custom_col};
				$checked = "  ";
				if($custom_col{field} eq $field_name)
				{
					if($custom_col{afficher} eq 'y')
					{
						$checked = " checked ";
						$ordre = $custom_col{ordby};
					}
					last;
				}
			}	
			
			
			my $field_info = "&nbsp; $line{title}";
			if($dm_cfg{show_tab_in_toggle_form} eq 'y')
			{
				$field_info = "&nbsp;$line{tab} > $line{title}";
			}
			
			if($field_name eq 'id')
			{
				next;
			}
			
			$form .= <<"EOH";
				<tr>
					<td style="width:30px">
						<input type="checkbox" name="toggle_cols_$field_name" $checked id="$field_name" value="y" />
					</td>
					<td>
						<label for="$field_name">$field_info</label>
					</td>
					<td>
						  <input type="text" class="line_ordby form-control" name="ordby_$field_name" style="width:50px; display:none;" readonly value="$line_counter" />
						  <a data-placement="bottom" data-original-title="En première position" class="btn btn-xs btn-default change_line_ordby change_line_ordby_first" rel="first"><i class="fa-fw fa fa-step-backward fa-rotate-90"></i></a>
						  <a data-placement="bottom" data-original-title="En avant"  class="btn btn-default btn-xs change_line_ordby change_line_ordby_previous" rel="previous"><i class="fa-fw fa fa fa-chevron-up"></i></a>
						  <a data-placement="bottom" data-original-title="En arrière"  class="btn btn-default btn-xs change_line_ordby  change_line_ordby_next" rel="next"><i class="fa-fw fa fa fa-chevron-down"></i></a>
						  <a data-placement="bottom" data-original-title="En dernière position"  class="btn btn-default btn-xs change_line_ordby  change_line_ordby_last" rel="last"><i class="fa-fw fa fa-step-forward fa-rotate-90"></i></a>
					</td>
				</tr>	
EOH
			$line_counter++;
		}
		
		$form .= <<"EOH";
		</tbody>
		</table>

		<button  class="btn btn-success" type="submit">
			Sauvegarder
		</button>

		
	</form>
	<br /><br />
	<form class="text-left get_toggle_cols_form" method="POST" action = "">
	<input type="hidden" name="sw" value="reset_toggle_cols_db" />
	<input type="hidden" name="sel" value="$sel" />
	<input type="hidden" name="self" value="$dm_cfg{self}" />
	<button  class="btn btn-danger" type="submit">
	<i class="fa fa-undo"></i> Revenir aux valeurs initiales
	</button>
	</form>
	<script>
	jQuery(document).ready(function()
	{
		jQuery('.change_line_ordby').unbind();
		jQuery('.change_line_ordby').click(function()
		{
			var me = jQuery(this);
			var line = me.parent().parent();
			var begin_table = me.parent().parent().parent();
			var previous_line = line.prev();
			var next_line = line.next();
			var sens = me.attr('rel');
				
			if(sens == 'first')
			{
				begin_table.prepend(line);
			}
			if(sens == 'previous')
			{
				previous_line.insertAfter(line);
			}
			if(sens == 'next')
			{
				next_line.insertBefore(line);
			}
			if(sens == 'last')
			{
				begin_table.append(line);
			}
			
			jQuery(".line_ordby").each(function(i)
			{
				var ordre = i+1;
				jQuery(this).val(ordre);		
			});	
			jQuery('.change_line_ordby').show();
			jQuery('.change_line_ordby_first:first').hide();
			jQuery('.change_line_ordby_previous:first').hide();
			jQuery('.change_line_ordby_next:last').hide();
			jQuery('.change_line_ordby_last:last').hide();

			return false;
		});
		
		jQuery('.change_line_ordby').show();
		jQuery('.change_line_ordby_first:first').hide();
		jQuery('.change_line_ordby_previous:first').hide();
		jQuery('.change_line_ordby_next:last').hide();
		jQuery('.change_line_ordby_last:last').hide();
	});
	</script>
EOH
	
my $editer = <<"EOH";
	<div class="pull-right">
		<button  class="animate_gear btn btn-default openmodal" href="#" role="button" data-toggle="modal" data-target="#get_toggle_cols_form">
			<span class="fa fa-gear"></span>
		</button>
	</div>
	
	<!-- Modal -->
	<div class="modal fade" id="get_toggle_cols_form" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
	  <div class="modal-dialog" role="document">
		<div class="modal-content">
		  <div class="modal-header">
			<button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
			<h4 class="modal-title" id="myModalLabel">Cochez les colonnes à afficher</h4>
		  </div>
		  <div class="modal-body">
                $form
		  </div>
		</div>
	  </div>
	</div>
EOH

	return $editer;
}



################################################################################
# list_delete_ajax
################################################################################
sub list_delete_ajax
{
   my $id = get_quoted('id');
   if($id =~ /\D/ || $id eq '')
   {
		print 'err';
		exit;
   }
   my $id_col = $dm_cfg{id_col} || 'id';
    my %check = ();
    if($id > 0)
    {
        %check = sql_line({debug=>0,dbh=>$dbh_data,table=>$dm_cfg{table_name},where=>"$id_col='$id'"});
    }
	if($check{migcms_lock} eq 'y')
	{
		exit;
	}
   
   

    if ($dm_cfg{before_del_func} ne "")
	{
		my $func = $dm_cfg{before_del_func};
		&$func($dbh_data,$id);
	}
	if ($dm_cfg{before_del_ref} ne "")
	{
		my $func = 'def_handmade::'.$dm_cfg{before_del_ref};
		&$func($dbh_data,$id);
	}


	clean_linked_files($dm_cfg{table_name},$id);
	clean_linked_txtcontents($dm_cfg{table_name},$id);

	$stmt = "delete FROM $dm_cfg{table_name} WHERE $id_col = '$id' ";
    execstmt($dbh_data,$stmt);

    add_history({action=>'delete',page=>$dm_cfg{table_name},id=>"$id"});

   exit;
}

sub clean_all_in_table
{
	my $table = $_[0];

	my @records = sql_lines({table=>$table});
	foreach $record (@records)
	{
		my %record = %{$record};
		clean_linked_files($table,$record{id});
		clean_linked_txtcontents($table,$record{id});
	}

	my $stmt = 'TRUNCATE `'.$table.'`';
	execstmt($dbh,$stmt);
}

sub clean_linked_files
{
	my $table_r = $_[0];
	my $id_r = $_[1];

	my @migcms_linked_files = sql_lines({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='$table_r' AND token='$id_r'"});
	foreach $migcms_linked_file (@migcms_linked_files)
	{
		my %migcms_linked_file = %{$migcms_linked_file};

		#unlink file and thumbs
		my @cols = ('full','name_mini','name_small','name_medium','name_large','name_og');
		foreach my $col (@cols)
		{
			my $url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{$col};
			if($col eq 'full')
			{
				$url .= $migcms_linked_file{ext};
			}

			if(-e $url)
			{
				unlink($url);
			}
			else
			{
				#cant find
			}
		}

	    $stmt = "delete FROM migcms_linked_files WHERE id = '$migcms_linked_file{id}' ";
		execstmt($dbh,$stmt);
	}
}

sub clean_linked_txtcontents
{
	my $table_r = $_[0];
	my $id_r = $_[1];

	#read record
	my %rec = sql_line({table=>$table_r,where=>"id='$id_r'"});

	#read cols
	my @list_of_cols = get_list_of_cols($config{projectname},$table_r,$dbh);
	foreach my $col (@list_of_cols)
	{
		my %col = %{$col};
		my $colname = $col{COLUMN_NAME};

		#if linked with txtcontent
		if($colname  =~ /textid/ )
		{
			if($rec{$colname} > 0)
			{
				$stmt = "delete FROM txtcontents WHERE id = '$rec{$colname}' ";
				execstmt($dbh,$stmt);
			}
		}
	}
}

################################################################################
# list_corbeille_ajax
################################################################################
sub list_corbeille_ajax
{
   my $id = get_quoted('id');
   my $id_col = $dm_cfg{id_col} || 'id';
   see();
   $stmt = "update $dm_cfg{table_name} SET migcms_deleted = 'y' WHERE id = '$id' ";
   execstmt($dbh_data,$stmt);
   add_history({action=>'delete',page=>$dm_cfg{table_name},id=>"$id"});
   
    if ($dm_cfg{after_corbeille_ref} ne "")
	{
		$fct = $dm_cfg{after_corbeille_ref};
		&$fct($dbh_data,$id);
	}
   exit;
}
################################################################################
# list_restaurer_ajax
################################################################################
sub list_restaurer_ajax
{
   my $id = get_quoted('id');
   my $id_col = $dm_cfg{id_col} || 'id';
   see();
   $stmt = "update $dm_cfg{table_name} SET migcms_deleted = 'n' WHERE id = '$id' ";
   execstmt($dbh_data,$stmt);
   add_history({action=>'$migctrad{restore_action}',page=>$dm_cfg{table_name},id=>"$id"});
   
    if ($dm_cfg{after_restaurer_ref} ne "")
	{
		$fct = $dm_cfg{after_restaurer_ref};
		&$fct($dbh_data,$id);
	}
   exit;
}
################################################################################
# ajax_save_elt
################################################################################
# sub ajax_save_elt
# {
#     see();
#     my $id_elt = get_quoted('id_elt');
#     my $table_name = get_quoted('table_name');
#     my $col = get_quoted('col');
#     my $content = get_quoted('content');
#
#     if($table_name ne '' && $col ne '' && $id_elt > 0)
#     {
#         my $stmt = "UPDATE $table_name SET $col='$content' WHERE id='$id_elt'";
#         execstmt($dbh_data,$stmt);
#         exit;
#     }
#     else
#     {
#         print "MISSING DATA: $table_name ne '' && $col ne '' && $id_elt > 0";
#     }
# }
sub ajax_save_elt
{
    my $dbh_rec = $dbh;
    if($dm_cfg{dbh} ne '')
    {
        $dbh_rec = $dm_cfg{dbh};
    }
    my $id_elt = get_quoted('id_elt');
    my $table_name = get_quoted('table_name');
    my $col = get_quoted('col');
    my $content = get_quoted('content');
    my $inline_edit_html = get_quoted('inline_edit_html');
    if(!$inline_edit_html)
    {
        $content =~ s/<(?:[^>"]*|(['"]).*?\1)*>//g;
    }
    my $id_col = $dm_cfg{id_col} || 'id';
    if($table_name ne '' && $col ne '' && $id_elt > 0)
    {
        my $stmt = "UPDATE $table_name SET $col='$content' WHERE $id_col='$id_elt'";
        execstmt($dbh_rec,$stmt);
        exit;
    }
    else
    {
        print "MISSING DATA: $table_name ne '' && $col ne '' && $id_elt > 0";
    }
}
################################################################################
# list_changevis_ajax
################################################################################
sub list_changevis_ajax
{
      my $id = get_quoted('id');
      my %rec = read_table($dbh_data,$dm_cfg{table_name},$id);
      my $new_vis = 'y';
      if($rec{visible} eq 'y')
      {
          $new_vis = 'n';
		  add_history({action=>'cache',page=>$dm_cfg{table_name},id=>"$id"});
      }
	  else
	  {
		add_history({action=>'affiche',page=>$dm_cfg{table_name},id=>"$id"});
	  }
      $stmt = "UPDATE $dm_cfg{table_name} SET visible = '$new_vis' WHERE id =$id";
      execstmt($dbh_data,$stmt);
	 
	  clean_migcms_cache();
      exit;
}

################################################################################
# list_changevislf_ajax
################################################################################
sub list_changevislf_ajax
{
      my $id = get_quoted('id');
      my %rec = read_table($dbh_data,'migcms_linked_files',$id);
      my $new_vis = 'y';
      if($rec{visible} eq 'y')
      {
          $new_vis = 'n';
		  add_history({action=>'cache',page=>'migcms_linked_files',id=>"$id"});
      }
	  else
	  {
		add_history({action=>'affiche',page=>'migcms_linked_files',id=>"$id"});
	  }
      $stmt = "UPDATE migcms_linked_files SET visible = '$new_vis' WHERE id =$id";
      execstmt($dbh_data,$stmt);
      exit;
}

################################################################################
# list_changecb_ajax
################################################################################
sub list_changecb_ajax
{
      my $id = get_quoted('id');
      my $col = get_quoted('col');
      my %rec = read_table($dbh_data,$dm_cfg{table_name},$id);
      my $new_value = 'y';
      if($rec{$col} eq 'y')
      {
          $new_value = 'n';
      }
	  # add_history({action=>'modifie',page=>$dm_cfg{table_name},id=>"$id",info=>'change checkbox value'});
      $stmt = "UPDATE $dm_cfg{table_name} SET $col = '$new_value' WHERE id =$id";
      execstmt($dbh_data,$stmt);
	  # if ($dm_cfg{after_mod_ref} ne "")
	  # {
			# $fct = $dm_cfg{after_mod_ref};
			# &$fct($dbh_data,$id);
	  # }
  	  clean_migcms_cache();
	  
      if($new_value eq 'y')
      {
          print <<"EOH";
                 <input type="checkbox" checked="checked" name="$col" class="list_autosavecb" value="$id" />
EOH
      }
      else
      {
          print <<"EOH";
                 <input type="checkbox" name="$col" class="list_autosavecb" value="$id" />
EOH
      }
      exit;
}

sub clean_migcms_cache
{
	if($config{migcms_cache} eq 'y' && $dm_cfg{table_name} ne '')
	{
		if($dm_cfg{use_migcms_cache} == 1 && -e '../cache/admin/'.$dm_cfg{table_name})
		{
			unlink('../cache/admin/'.$dm_cfg{table_name});
		}
	}
}

################################################################################
# list_action_globale_show_ajax
################################################################################
sub list_action_globale_show_ajax
{
    see();
    my $ids = get_quoted('ids');
    my @ids = split (/,/,$ids);
    my $id_col = $dm_cfg{id_col} || 'id';
    foreach $id (@ids)
    {
        if($id > 0)
        {
            $stmt = "UPDATE $dm_cfg{table_name} SET visible = 'y' WHERE $id_col = $id";
            execstmt($dbh_data,$stmt);
			add_history({action=>'cache',page=>$dm_cfg{table_name},id=>"$id"});
        }
    }
	clean_migcms_cache();
    print 'ok';
    exit;
}
################################################################################
# list_action_globale_show_ajax
################################################################################
sub list_action_globale_pdfzip_ajax
{
    # see();
    my $ids = get_quoted('ids');
    my @ids = split (/,/,$ids);
    my $id_col = $dm_cfg{id_col} || 'id';
    use Archive::Zip;
	my $zip = Archive::Zip->new();
	# log_debug('list_action_globale_pdfzip_ajax','vide','list_action_globale_pdfzip_ajax');
	# log_debug('prefixe:'.$dm_cfg{file_prefixe},'','list_action_globale_pdfzip_ajax');
	
	
	
	
	
	my $zipname = get_document_filename({date=>1,sys=>\%sys,prefixe=>$dm_cfg{file_prefixe},type=>'listing'});
	
	# log_debug('zipname:'.$zipname,'','list_action_globale_pdfzip_ajax');
	my $out_path_zip = $config{directory_path}.'/usr/documents/'.$zipname.'.zip';
	
		# log_debug('out_path_zip:'.$out_path_zip,'','list_action_globale_pdfzip_ajax');
	
	foreach $id (@ids)
    {
        if($id > 0)
        {
			#publication du pdf selon la méthode classique ou sur mesure (si nécessaire)
					# log_debug('id:'.$id,'','list_action_globale_pdfzip_ajax');
					# use Data::Dumper;
					
					# log_debug(Dumper(\%dm_cfg),'','list_action_globale_pdfzip_ajax');
			my $pdf_filename = '';
			if($dm_cfg{no_auto_publish_pdf} != 1)
			{
				my $func_publish = 'ajax_publish_pdf';
				if($dm_cfg{func_publish} ne '')
				{
					$func_publish = 'def_handmade::'.$dm_cfg{func_publish};
				}
				$pdf_filename = &$func_publish($id,lc($dm_cfg{file_prefixe}),$dm_cfg{table_name});
				# log_debug('pdf_filename1:'.$pdf_filename,'','list_action_globale_pdfzip_ajax');
			}
			else
			{
				my %rec = read_table($dbh,$dm_cfg{table_name},$id);
				$pdf_filename = '../usr/documents/'.$rec{migcms_last_published_file};
				# log_debug('pdf_filename2:'.$pdf_filename,'','list_action_globale_pdfzip_ajax');
			}
			
			my $remove = '../usr/documents/';
			my $name = $pdf_filename;
			$name =~ s/$remove//g;
			# log_debug('pdf_filename3:'.$pdf_filename,'','list_action_globale_pdfzip_ajax');
			# log_debug('name:'.$name,'','list_action_globale_pdfzip_ajax');
			#ajouter le fichier au zip
			$zip->addFile($pdf_filename,$name);
        }
    }
	
	 unless ( $zip->writeToFileNamed($out_path_zip) == AZ_OK ) 
	 {
       die 'write error '.$out_path_zip;
	}
	
	# log_debug('../usr/documents/'.$zipname.'.zip','','list_action_globale_pdfzip_ajax');
	
    print '../usr/documents/'.$zipname.'.zip';
    exit;
}

################################################################################
# list_action_globale_facturationsysteme_ajax
################################################################################
sub list_action_globale_facturationsysteme_ajax
{
    # see();
    my $ids = get_quoted('ids');
    my @ids = split (/,/,$ids);
    my $id_col = $dm_cfg{id_col} || 'id';
	
	
	see();
	add_history({action=>'facturation système',page=>$dm_cfg{table_name},id=>$ids,details=>''});

	
	if($dm_cfg{facturer_col_facture} eq '' || $dm_cfg{facturer_col_client} eq '' || $dm_cfg{facturer_table_client} eq '' && $ids ne '')
	{
		# use Data::Dumper;
		# log_debug(Dumper(\%dm_cfg).'erreur:'."[facturer_col_client:".$dm_cfg{facturer_col_client}."][facturer_table_client:".$dm_cfg{facturer_table_client}."][ids:".$ids."][facturer_col_facture:".$dm_cfg{facturer_col_facture}."]",'','action_globale_facturer');
		dm::add_error({action=>'facturation système',page=>$dm_cfg{table_name},id=>$ids,details=>'erreur:'."[facturer_col_client:".$dm_cfg{facturer_col_client}."][facturer_table_client:".$dm_cfg{facturer_table_client}."][ids:".$ids."][facturer_col_facture:".$dm_cfg{facturer_col_facture}."]"});
		return '';
		exit;
	}
	
	
	#publication des pdfs (si necessaire)
	foreach $id (@ids)
    {
        if($id > 0)
        {		
			#publication du pdf selon la méthode classique ou sur mesure (si nécessaire)
			my $func_publish = 'ajax_publish_pdf';
			if($dm_cfg{func_publish} ne '')
			{
				$func_publish = 'def_handmade::'.$dm_cfg{func_publish};
			}
			$pdf_filename = &$func_publish($id,lc($dm_cfg{file_prefixe}),$dm_cfg{table_name});
			
			my $remove = '../usr/documents/';
			my $name = $pdf_filename;
			$name =~ s/$remove//g;
        }
    }
	
	
	
	
	
	
	
	
	
	# log_debug('debut','','list_action_globale_facturationsysteme_ajax');
	my $NOM_TABLE_FACTURE_SYSTEME = 'handmade_selion_documents_facturesysteme';
	my $prefixe = 'vs0';
	
	# use Data::Dumper;
	# log_debug(Dumper(\%dm_cfg),'','list_action_globale_facturationsysteme_ajax');
	
	
    #rassembler les records par client
	# log_debug('rassembler les records par client','','list_action_globale_facturationsysteme_ajax');
	
    
	my %recs_by_clients = ();
	my %marques_by_clients = ();
	my %id_fs0_by_clients = ();
	my %id_document_by_clients = ();
    foreach my $id (@ids)
    {
        # log_debug('rassembler les records par client '.$id,'','list_action_globale_facturationsysteme_ajax');
		if($id > 0)
        {
			my %rec = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
			my $statut_facturation = $rec{$dm_cfg{facturer_col_facture}};
			my $id_client = $rec{$dm_cfg{facturer_col_client}};
			
			#vérifier si la ligne n'a pas déjà été facturée: 2 = id du statut A facturer (1 = facturé, 3 = info) et si montant et si client
			if($statut_facturation == 2 && $rec{$dm_cfg{facturer_col_total}} > 0 && $id_client > 0)
			{
				$recs_by_clients{$rec{$dm_cfg{facturer_col_client}}} .= $id.',';
				$marques_by_clients{$rec{$dm_cfg{facturer_col_client}}} = $rec{id_handmade_selion_marque};
			}
			else
			{
				my $resultat = '';
				if($statut_facturation != 2 && $statut_facturation != 1)
				{
					$resultat .= "Pas à facturer<br>";
				}
				if($statut_facturation == 1)
				{
					$resultat .= "Déjà facturé<br>";
				}
				if(!($id_client > 0))
				{
					$resultat .= "Pas de client<br>";
				}
				if(!($rec{$dm_cfg{facturer_col_total}} >0))
				{
					$resultat .= "Pas de montant<br>";
				}
				$stmt = "UPDATE $dm_cfg{table_name} SET date_creation='NOW()', resultat = '$resultat' WHERE id = '$id' ";
				execstmt($dbh_data,$stmt);
				# log_debug('erreur2:'."$statut_facturation == 2 && $rec{$dm_cfg{facturer_col_total}} > 0 && $id_client > 0",'','list_action_globale_facturationsysteme_ajax');
				dm::add_error({action=>'facturation système',page=>$dm_cfg{table_name},id=>$id,details=>'Non facturé car: déja facturé:'."$statut_facturation == 2 && Total: $rec{$dm_cfg{facturer_col_total}} > 0 && Client: $id_client > 0"});
			}
		}
    }
	
	#bpour chaque client, créer une facture syteme (type de document fSO), créer un document et y attache plusieurs lignes
	foreach my $id_client (keys %recs_by_clients)
	{
		my %client = read_table($dbh,$dm_cfg{facturer_table_client},$id_client);
		if(trim($recs_by_clients{$id_client}) eq '')
		{
			# log_debug('next car pas de lignes éligibles pour le client:'.$id_client,'','list_action_globale_facturationsysteme_ajax');
			next;
		}
		if(trim($id_fs0_by_clients{$id_client}) > 0)
		{
			# log_debug('next car le client existe deja:'.$id_client,'','list_action_globale_facturationsysteme_ajax');
			next;
		}
		
		
		#créer un document fs0
		my %new_handmade_selion_documents_facturesysteme =
		(
			date_creation => 'NOW()',
			id_ctm => $id_client,
			id_handmade_selion_marque => $marques_by_clients{$id_client}
		);
		
		my $id_fs0 = inserth_db($dbh,$NOM_TABLE_FACTURE_SYSTEME,\%new_handmade_selion_documents_facturesysteme);
		$id_fs0_by_clients{$id_client} = $id_fs0;
		
		#créer le SYS pour le document fs0
		my %new_sys =
		(
			moment => 'NOW()',
			nom_table => 'handmade_selion_documents_facturesysteme',		
			id_table => $id_fs0,
			id_user => $user{id}
		);
		my $id_sys = inserth_db($dbh,'migcms_sys',\%new_sys);
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		#créer un document lié au fs0
		my %new_document = 
		(
			table_record => $NOM_TABLE_FACTURE_SYSTEME,
			id_ctm => $id_client,
			id_record => $id_fs0,
			remise_globale => 0,
			nom_f => $client{CTMDENOMINATION},
			societe_f => '',
			tva_f => $client{CTMCTVA},
			contact_f => '',
			adresse_f => $client{CTMADRESSEL1},
			ville_f => "$client{CTMCP} $client{CTMVILLE}",
			pays_f => $client{CTMPAYS},			
			date_facturation => 'NOW()',			
		);
		
		%new_document = %{dm::quoteh(\%new_document)};
		my $id_document = inserth_db($dbh,'intranet_documents',\%new_document);
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		my $delai_j = 0;
	
	my %delais_j = 
	(
		'J+07'=>7,
		'J+15'=>15,
		'J+30'=>30,
		'J+30 fin de mois'=>45
	);
	

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year+=1900;	
	$mon++;	
		
	my ($yyyy,$mm,$dd) = split (/-/,$document{date_facturation}); 
	
	if($yyyy > 2000 && $mm > 0 && $dd >0 && length $yyyy > 0 && length $mm > 0 && length $dd > 0)
	{
	}
	else
	{
		$yyyy = $year;
		$mm = $mon;
		$dd = $mday;
	}
	
	my $today = DateTime-> new (
                     year =>$yyyy,
                     month =>$mm,,
                     day   =>$dd,
                     hour  =>12,
                     time_zone =>'local'
                     );
	my $sql_date_limite = '';
	if($delais_j{$client{CTMDELAIPAIEMENT}} <= 30)
	{
		#calcul delai + 7 15 30
		$delai_j = $delais_j{$client{CTMDELAIPAIEMENT}};
		if($delai_j ne '' && $delai_j >=0 )
		{
			$today->add( days => $delai_j);
			$sql_date_limite = $today->ymd; 
		}
	}
	else
	{
		#calul delai 30j fin de mois 
		$today->set_day(1);
		$today->add( months => 2 );
		$today->add( days => -1 );
		$sql_date_limite = $today->ymd; 
	}
	
	
	#vide le nom du fichier pdf
	$stmt = "update intranet_documents SET date_echeance='$sql_date_limite' WHERE id = '".$id_document ."' ";
	execstmt($dbh,$stmt);
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		

		$id_document_by_clients{$id_client} = $id_document;
		
		#compléter le document avec les lignes à facturer
		my @ids_rec = split (/,/,$recs_by_clients{$id_client});
		my $ordby = 1;
		foreach my $id_rec (@ids_rec)
		{
			if($id_rec > 0 )
			{
				$resultat = dm::getcode($dbh,$id_fs0,'VS0');
				$stmt = "UPDATE $dm_cfg{table_name} SET id_fs='$resultat' WHERE id = '$id_rec' ";
				execstmt($dbh_data,$stmt);

				my %rec = sql_line({table=>$dm_cfg{table_name},where=>"id='$id_rec'"});
				
				$rec{date_livraison} =~ s/\-/\//g;
				
				
				my $reference = $rec{reference};
				if($dm_cfg{fact_col_reference} ne '')
				{
					$reference = $rec{$dm_cfg{fact_col_reference}};
				}
				
				my $code = dm::getcode($dbh,$rec{id},$dm_cfg{file_prefixe});
				my $label = "$code - $rec{date_livraison} - $reference";
				
				if($dm_cfg{fact_col_label} ne '' )
				{
					$label = $rec{$dm_cfg{fact_col_label}};
					$label =~ s/\'/\\\'/g;
				}
				
				
				my %new_document_ligne = 
				(
					id_document => $id_document,
					ordby => $ordby,
					pu_htva => $rec{$dm_cfg{facturer_col_total}},
					ref => $code,
					qty => 1,
					remise => 0,
					label => $label,
					id_taux_tva => $dm_cfg{facturer_id_taux_tva}		
				);
				
									# remarque => $rec{remarque},

				
				%new_document_ligne = %{dm::quoteh(\%new_document_ligne)};
				
				my $id_document_ligne = sql_set_data({dbh=>$dbh,debug=>0,table=>'intranet_documents_lignes',data=>\%new_document_ligne, where=>"id_document = '$new_document_ligne{id_document}' AND ordby='$new_document_ligne{ordby}'"});      		
				def_handmade::intranet_totalize_line_document({save_fac=>'save_doc',id_document_ligne=>$id_document_ligne,type=>'document'});
				
				#ajouter la piece jointe à la table migcms_linked_files
				$rec{migcms_last_published_file} =~ s/\.pdf//g;
				my %new_migcms_linked_files =
				(
					file => $rec{migcms_last_published_file},
					file_dir=> '../usr/files/'.uc($prefixe).'/fichiers/'.$id_fs0,
					ordby => $ordby++,
					moment => 'NOW()',
					table_name=>'handmade_selion_documents_facturesysteme',
					table_field=>'fichiers',
					ext=>'.pdf',
					token=>$id_fs0,
					full => $rec{migcms_last_published_file}
				);
				inserth_db($dbh,'migcms_linked_files',\%new_migcms_linked_files);
				
				
				#crér les dossiers requis
				my $dir = $config{directory_path}.'/usr/files/'.uc($prefixe);
				unless (-d $dir) {mkdir($dir.'/') or die ("cannot create ".$dir.'/'.": $!");}
				my $dir = $config{directory_path}.'/usr/files/'.uc($prefixe).'/fichiers';
				unless (-d $dir) {mkdir($dir.'/') or die ("cannot create ".$dir.'/'.": $!");}
				my $dir = $config{directory_path}.'/usr/files/'.uc($prefixe).'/fichiers/'.$id_fs0;
				unless (-d $dir) {mkdir($dir.'/') or die ("cannot create ".$dir.'/'.": $!");}

				#copier la piece jointe dans le dossier de la facture systeme
				copy($config{directory_path}.'/usr/documents/'.$rec{migcms_last_published_file}.'.pdf',$config{directory_path}.'/usr/files/'.uc($prefixe).'/fichiers/'.$id_fs0);
				
				#maj du statut du rec: facturé
				$stmt = "UPDATE $dm_cfg{table_name} SET $dm_cfg{facturer_col_facture} = 1 WHERE id = '$rec{id}' ";
				execstmt($dbh_data,$stmt);
				
				add_history({action=>'facturation système',page=>$dm_cfg{table_name},id=>$rec{id},details=>'Le processus est facturé'});
			}
		}
		def_handmade::intranet_totalize_document({debug=>0,debug_results=>0,save_fac=>'save_doc',id_document=>$id_document,type=>'document',sans_frais=>'y'});
		my %document = sql_line({debug=>0,debug_results=>0,table=>'intranet_documents',where=>"id='$id_document'"});
		
		
		
		#LIGNES DE TOTAUX (3)
		
		my $ordby = 1;
		
		
		#total htva
		my %line_bas = 
		(
			id_facture => $document{id},
			ordby => $ordby++,
			nom => 'Total HTVA',
			valeur => $document{montant_total_htva},
			type_frais => 'general',

		);
		inserth_db($dbh,'intranet_documents_bas',\%line_bas);
		
		
		
		
		
		#remise globale
		my %line_bas = 
		(
			id_facture => $document{id},
			ordby => $ordby++,
			nom => 'Remise globale ('.$document{remise_globale}.'%)',
			valeur => $document{montant_total_htva_discount},
			type_frais => 'general',

		);
		inserth_db($dbh,'intranet_documents_bas',\%line_bas);
		
		#total htva remise deduite
		my %line_bas = 
		(
			id_facture => $document{id},
			ordby => $ordby++,
			nom => 'Total HTVA remise déduite',
			valeur => $document{montant_total_htva_discounted},
			type_frais => 'general',

		);
		inserth_db($dbh,'intranet_documents_bas',\%line_bas);


		#total frais
		my %line_bas = 
		(
			id_facture => $document{id},
			ordby => $ordby++,
			nom => 'Total des frais',
			valeur => $total_frais_partie1,
			type_frais => 'general',

		);
		inserth_db($dbh,'intranet_documents_bas',\%line_bas);
				
		
		#total frais
		my %line_bas = 
		(
			id_facture => $document{id},
			ordby => $ordby++,
			nom => 'Majorations / reductions conventionnees',
			valeur => $total_frais_partie2,
			type_frais => 'general',

		);
		inserth_db($dbh,'intranet_documents_bas',\%line_bas);
			
		my %line_bas = 
		(
			id_facture => $document{id},
			ordby => $ordby++,
			nom => 'Total HTVA',
			valeur => $document{montant_total_htva},
			type_frais => 'general',

		);
		inserth_db($dbh,'intranet_documents_bas',\%line_bas);
		
		$document{montant_total_tva} = $document{montant_total_htva} * ($dm_cfg{facturer_valeur_tva} / 100);
		$document{montant_total_tvac} = $document{montant_total_htva} + $document{montant_total_tva};
		
		#total tva
		my %line_bas = 
		(
		id_facture  => $document{id},
		ordby => $ordby++,
		nom => 'Total TVA '.$dm_cfg{facturer_valeur_tva}.'%',
		valeur => $document{montant_total_tva},
		type_frais => 'general',

		);
		inserth_db($dbh,'intranet_documents_bas',\%line_bas);

		#total tvac
		my $montant_a_payer_tva = $total_tva;
		my $montant_a_payer_tvac = $document{montant_a_payer_htva} + $total_tva;

		my %line_bas = 
		(
		id_facture => $document{id},
		ordby => $ordby++,
		nom => 'Total TVAC',
		valeur => $document{montant_total_tvac},
		type_frais => 'general',
		);
		inserth_db($dbh,'intranet_documents_bas',\%line_bas);
		
		#calculer le montant_a_payer_tva et montant_a_payer_tvac
		$stmt = "UPDATE intranet_documents SET montant_a_payer_tvac = $document{montant_total_htva},montant_a_payer_tvac = $document{montant_total_tvac},montant_a_payer_tva = $document{montant_total_tva} where id='$document{id}'";
		execstmt($dbh,$stmt); 	
		
		
		
		$stmt = "UPDATE $NOM_TABLE_FACTURE_SYSTEME SET total_htva = '$document{montant_a_payer_htva}',total_tvac ='$montant_a_payer_tvac' where id='$id_fs0'";
		execstmt($dbh,$stmt); 			

		def_handmade::ajax_make_pdf_document($id_fs0,$prefixe,'noclean');
	}
    print 'ok';
    exit;
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
    print 'ok';
    exit;
}

################################################################################
# list_action_globale_hide_ajax
################################################################################
sub list_action_globale_hide_ajax
{
    see();
    my $ids = get_quoted('ids');
    my @ids = split (/,/,$ids);
    my $id_col = $dm_cfg{id_col} || 'id';
    foreach $id (@ids)
    {
        if($id > 0)
        {
            $stmt = "UPDATE $dm_cfg{table_name} SET visible = 'n' WHERE $id_col = $id";
            execstmt($dbh_data,$stmt);
			add_history({action=>'$migctrad{hide}',page=>$dm_cfg{table_name},id=>"$id"});
        }
    }
	clean_migcms_cache();
    print 'ok';
    exit;
}
################################################################################
# list_action_globale_corbeille_ajax
################################################################################
sub list_action_globale_corbeille_ajax
{
    see();
    my $ids = get_quoted('ids');
    my @ids = split (/,/,$ids);
    my $id_col = $dm_cfg{id_col} || 'id';
    foreach $id (@ids)
    {
        if($id > 0)
        {
            $stmt = "UPDATE $dm_cfg{table_name} SET migcms_deleted = 'y' WHERE $id_col = $id";
            execstmt($dbh_data,$stmt);
			add_history({action=>'$migctrad{makestrash}',page=>$dm_cfg{table_name},id=>"$id"});
			
			if ($dm_cfg{after_corbeille_ref} ne "")
			{
				$fct = $dm_cfg{after_corbeille_ref};
				&$fct($dbh_data,$id);
			}
        }
    }
	clean_migcms_cache();
    print 'ok';
    exit;
}
################################################################################
# list_action_globale_restauration_ajax
################################################################################
sub list_action_globale_restauration_ajax
{
    see();
    my $ids = get_quoted('ids');
    my @ids = split (/,/,$ids);
    my $id_col = $dm_cfg{id_col} || 'id';
    foreach $id (@ids)
    {
        if($id > 0)
        {
            $stmt = "UPDATE $dm_cfg{table_name} SET migcms_deleted = 'n' WHERE $id_col = $id";
            execstmt($dbh_data,$stmt);
			add_history({action=>'$migctrad{restore_action}',page=>$dm_cfg{table_name},id=>"$id"});
			
			if ($dm_cfg{after_restaurer_ref} ne "")
			{
				$fct = $dm_cfg{after_restaurer_ref};
				&$fct($dbh_data,$id);
			}
        }
		
    }
	clean_migcms_cache();
    print 'ok';
    exit;
}
################################################################################
# list_action_globale_delete_ajax
################################################################################
sub list_action_globale_delete_ajax
{
    see();
    my $ids = get_quoted('ids');
    my @ids = split (/,/,$ids);
    my $id_col = $dm_cfg{id_col} || 'id';
    foreach $id (@ids)
    {
        if($id > 0)
        {
			
			my %check = ();
			if($id > 0)
			{
				%check = sql_line({debug=>0,dbh=>$dbh_data,table=>$dm_cfg{table_name},where=>"$id_col='$id'"});
			}
			if($check{migcms_lock} eq 'y')
			{
				next;
			}
			
			if ($dm_cfg{before_del_func} ne "")
			{
				my $func = $dm_cfg{before_del_func};
				&$func($dbh_data,$id);
			}
			my $func = 'def_handmade::'.$dm_cfg{before_del_ref};
			if ($dm_cfg{before_del_ref} ne "")
			{
				$fct = $func;
				&$fct($dbh_data,$id);
			}
			clean_linked_files($dm_cfg{table_name},$id);
			clean_linked_txtcontents($dm_cfg{table_name},$id);

			$stmt = "delete FROM $dm_cfg{table_name} WHERE $id_col = $id";
            execstmt($dbh_data,$stmt);
			add_history({action=>'delete',page=>$dm_cfg{table_name},id=>"$id"});
        }
    }
	clean_migcms_cache();
    print 'ok';
    exit;
}
sub list_change_ordby_db_ajax
{
    see();
    my $id_rec = get_quoted('id_rec');
	add_history({action=>'trie',page=>$dm_cfg{table_name},id=>"$id_rec"});
    my $id_father = '';
    my %rec = ();
    my $id_col = $dm_cfg{id_col} || 'id';
    if($id_rec > 0)
    {
        %rec = select_table($dbh_data,$dm_cfg{table_name},"","$id_col='$id_rec'");
        $id_father = $rec{id_father};
    }
    my $ordby_after = get_quoted('new_ordby');
    my $where_max_ordby = ' 1 ';
    if($dm_cfg{tree})
    {
        $where_max_ordby .= ' AND id_father = '.$id_father.' ';
    }
    if($dm_cfg{wherel} ne '')
    {
        $where_max_ordby .= ' AND '.$dm_cfg{wherel};
    }
    my %max_ordby = sql_line({debug=>0,debug_results=>0,dbh=>$dbh_data,table=>$dm_cfg{table_name},select=>"MAX(ordby) as leplusgrand",where=>$where_max_ordby});
    if($ordby_after eq 'last')
    {
        $ordby_after = $max_ordby{leplusgrand};
    }
    if($id_rec > 0 && $ordby_after > 0)
    {
        my $ordby_before = $rec{ordby};
        my $stmt = '';
        my $suppl_tree = '';
        if($ordby_after > $ordby_before)
        {
            $stmt = "UPDATE $dm_cfg{table_name} SET ordby = ordby - 1 WHERE ordby > $ordby_before AND ordby <= $ordby_after $suppl_tree";
            if($dm_cfg{tree})
			{
				$stmt .= ' AND id_father = '.$id_father.' ';
			}
			if($dm_cfg{wherel} ne '' && $stmt ne '')
			{
				$stmt .= ' AND '.$dm_cfg{wherel};
			}
			if($stmt ne '')
			{
			execstmt($dbh_data,$stmt);
			}
        }
        elsif($ordby_after < $ordby_before)
        {
            $stmt = "UPDATE $dm_cfg{table_name} SET ordby = ordby + 1 WHERE ordby >= $ordby_after  $suppl_tree";
			if($dm_cfg{tree})
			{
				$stmt .= ' AND id_father = '.$id_father.' ';
			}
			if($dm_cfg{wherel} ne '' && $stmt ne '')
			{
				$stmt .= ' AND '.$dm_cfg{wherel};
			}
			if($stmt ne '')
			{
			execstmt($dbh_data,$stmt);
			}
        }
        if($ordby_after <= $max_ordby{leplusgrand})
        {
			  $stmt = "UPDATE $dm_cfg{table_name} SET ordby = $ordby_after WHERE id ='$id_rec'";
			  execstmt($dbh_data,$stmt);
			  if($ordby_after < $ordby_before)
			  {
				  if($dm_cfg{tree})
				  {
					  edit_db_sort_tree_recurse(0);
					  print '440';
				  }
				  else
				  {
					  edit_db_sort();
					  print '444';
				  }
			  }
			  else
			{
				if($dm_cfg{tree})
			   {
				  edit_db_sort_tree_recurse(0);
				  print '540';
			   }
			   else
			   {
				  edit_db_sort();
				  print '544';
			   }
			}
        }
		else
		{
			print '322';
		}
    }
	else
	{
		print '321';
	}
    print 'ok';
    exit;
}
################################################################################
# edit_migcms_pics
################################################################################
sub edit_migcms_pics
{
	my %d = %{$_[0]};
	my $id = get_quoted('id');
    my ($navlist,$nb_nav) = edit_navlist({id=>$id});
    my $lines = edit_lines({id=>$id});
    my %pic = ();
    my $preview = '';
    if($id>0)
    {
        my $photo = '';
		if($dm_cfg{table_name} eq "migcms_blocks_pics")
		{
			$photo = migcrender::render_block_pic({id=>$id,admin=>'y'});
		}
		else
		{
			$photo = migcrender::render_parag_pic({id=>$id,admin=>'y'});
		}
		$preview = <<"EOH";
<div class="control-group migcms_group_data_type_">
	<label for="field_pic_name_orig" class="control-label">$migctrad{adm_preview} :</label>
	<div class="controls">
		$photo
	</div>
	<br />
</div>
EOH
    }
    my $title = "Ajouter une photo";
    my $subtitle = "Nouvel élément";
    if($id > 0)
    {
        $title = 'Modifier une photo';
        $subtitle = "Enregistrement: #$id";
    }
    my $content =<< "EOH";
<div class="pull-right">
	<div class="custom_options1">
		<div class="btn-group">
			$save_previous
			<a data-placement="bottom" data-original-title="$migctrad{save_action}" class="btn btn-success show_only_after_document_ready admin_edit_save">$ICONSAVE</a>
			$save_next
			<a class="btn btn-link cancel_edit show_only_after_document_ready"  aria-hidden="true">$ICONCANCEL</a>
			
		</div>
	</div>
	<div class="custom_options2" style="display:none;">
		<a href="#" class="btn btn-success migcms_pics_choose_pic">$migctrad{choose_image}</a>
		<a href="#" class="btn btn-error migcms_pics_cancel_choose_pic">$ICONCANCEL</a>
	</div>
</div>
<div style="clear:both;"></div>
<div class="migcms_pics_form">
	<div class="row-fluid">
		<div class="span12">
			<div class="widget">
				<div class="widget-body">
					<form class="form-horizontal admin_edit_form" method="post" >
						<div class="container">
							<row class="span3">
								$navlist
							</row>
							<row class="span9">
								$preview
								$lines
							</row>
						</div>
					</form>
				</div>
			</div>
		</div>
	</div>
</div>
<div class="custom_options1 pull-right">
	$save_previous
	<a data-placement="bottom" data-original-title="$migctrad{back}" class="btn  btn-link btn-lg show_only_after_document_ready cancel_edit c1" aria-hidden="true">$ICONCANCEL</a>
	<a data-placement="bottom" data-original-title="$migctrad{save_action}" class="btn btn-lg btn-success show_only_after_document_ready admin_edit_save">$ICONSAVE</a>
	$save_next
</div>
EOH
    if($d{render} eq 'cgi')
	  {
			return $content;
	  }
	  else
	  {
	print $content;
	exit;
	  }
}
sub edit_navlist
{
    my %d = %{$_[0]};
	my $nb_nav = 0;
    my $first = ' active ';
	
	my $activ_nav = get_quoted('activ_nav');
	if($activ_nav ne '')
	{
		$first = '';
	}

    my $navlist = <<"EOH";

<ul class="mail-navigation nav nav-tabs nav_$d{id}" role="tablist">
EOH
    foreach $dm_nav (@dm_nav)
    {
          my %dm_nav_line = %{$dm_nav};
		  
		  if($dm_nav_line{system_only} == 1 && $user{id_role} > 1)
		  {
			next;
		  }

          if($dm_nav_line{type} eq 'header')
          {
              if(1)
			  {
	     		$navlist .=<<"EOH";
	<li class="nav-header">$dm_nav_line{title}</li>
EOH
			  }
          }
          elsif($dm_nav_line{type} eq 'tab'|| $dm_nav_line{type} eq 'func' || $dm_nav_line{type} eq 'cgi_func')
          {
				$nb_nav++;
				if($activ_nav ne '')
				{
					if($activ_nav eq $dm_nav_line{tab})
					  {
						$first = ' active ';
					  }
					  else
					  {
						$first = '';
					  }
			  	} 
						  
			  if(($dm_nav_line{disable_add} != 1 && ($d{id} eq '' || $d{id} == 0)) || $d{id} > 0)
			  {
				  my $icon = '';
				  if($dm_nav_line{icon} ne '')
				  {
					$icon = <<"EOH";
						<i class="active $dm_nav_line{icon}"></i>
EOH
				  }
				  $navlist .=<<"EOH";
	<li class="$first dm_nav_li_$dm_nav_line{tab}"><a href="#" id="$dm_nav_line{tab}" class="mig_onglet" role="tab" data-toggle="tab">$icon $dm_nav_line{title}</a></li>
EOH
			  }
              $first = '';
          }
    }
  $navlist .= <<"EOH";
</ul>

EOH
  return ($navlist,$nb_nav);
}
################################################################################
# edit_ajax
################################################################################
sub edit_ajax
{
    my %d = %{$_[0]};
    my $ac = 'add';
	my $id = get_quoted('id');
	my $etapeFinale = get_quoted('etapeFinale');
	if($id eq '')
	{
		 $id = $d{id};
	}
    my $title =  $dm_cfg{add_title} || '';
    if($id > 0 && $id ne 'NaN')
    {
        $ac = 'edit';
		
		if ($dm_cfg{before_mod_ref} ne "")
		{
			$fct = $dm_cfg{before_mod_ref};
			&$fct($dbh_data,$id,$colg);
		}		
    }
	my ($navlist,$nb_nav) = edit_navlist({id=>$id,ac=>$ac,permission_modification=>$dm_permissions{editr}});
    my ($lines,$bloc_info) = edit_lines({id=>$id,ac=>$ac,nb_nav=>$nb_nav,permission_modification=>$dm_permissions{editr},etapeFinale=>$etapeFinale});

	#custom buttons-----------------------------------------------------------------------------------------
	my $custom_button_xs = '';
	my $custom_button_lg = '';

	my $etapeFinale_button_xs = '';
	my $etapeFinale_button_lg = '';

	if($ac eq 'add' && $etapeFinale ne 'etapeFinale')
	{
		if($dm_cfg{custom_add_button_txt} ne '' && $dm_cfg{custom_add_button_id} ne '')
		{
			$custom_button_xs = <<"EOH";
<a data-placement="bottom" data-original-title="$dm_cfg{custom_add_button_txt}" class="$dm_cfg{custom_add_button_id} btn btn-info btn-sm">$dm_cfg{custom_add_button_icon}</a>
EOH
			$custom_button_lg = <<"EOH";
<a data-placement="bottom" data-original-title="$dm_cfg{custom_add_button_txt}" class="$dm_cfg{custom_add_button_id} btn btn-info btn-lg ">$dm_cfg{custom_add_button_icon}</a>
EOH
		}
	}

	if($ac eq 'edit' && $etapeFinale ne 'etapeFinale')
	{
		if($dm_cfg{custom_edit_button_txt} ne '' && $dm_cfg{custom_edit_button_id} ne '')
		{
			$custom_button_xs = <<"EOH";
<a data-placement="bottom" data-original-title="$dm_cfg{custom_add_button_txt}" class="$dm_cfg{custom_add_button_id} btn btn-info btn-sm">$dm_cfg{custom_add_button_icon}</a>
EOH
			$custom_button_lg = <<"EOH";
<a data-placement="bottom" data-original-title="$dm_cfg{custom_add_button_txt}" class="$dm_cfg{custom_add_button_id} btn btn-info btn-lg ">$dm_cfg{custom_add_button_icon}</a>
EOH
		}
	}

	if($dm_cfg{etapeFinale} == 1 && $etapeFinale ne 'etapeFinale') {

			$etapeFinale_button_xs = <<"EOH";
			<a data-placement="bottom" data-original-title="$TXTETAPEFINALE" class="admin_edit_save_and_show_finale btn btn-info btn-sm" style="background-color:black!important;color:white!important;border-color:none!important;">$dm_cfg{etapeFinaleNom}</a>
EOH
			$etapeFinale_button_lg = <<"EOH";
			<a data-placement="bottom" data-original-title="$TXTETAPEFINALE"  class="admin_edit_save_and_show_finale btn btn-info btn-lg " style="background-color:black!important;color:white!important;border-color:none!important;">$dm_cfg{etapeFinaleNom}</a>
EOH

	}

  my $button_save = <<"EOH";
  <a data-placement="bottom"   data-original-title="$migctrad{save_action}" class="btn btn-sm btn-success show_only_after_document_ready admin_edit_save">$ICONSAVE</a>
EOH
 my $button_save2 = <<"EOH";
  <a data-placement="bottom"  data-original-title="$migctrad{save_action}"   class="btn btn-lg btn-success show_only_after_document_ready admin_edit_save">
				$ICONSAVE
			</a>
EOH

# if($custom_button_lg ne '')
# {
	# $button_save = $button_save2 = '';
	# $etapeFinale_button_xs = $etapeFinale_button_lg = '';
# }


if($dm_permissions{editr} == 0 && $dm_permissions{add} == 0)
{
	$button_save = $button_save2 = '';
}

    my $content =<< "EOH";
	<div class="alert alert-danger validation_msg hide">
	</div>
	
	
	
<form class="form-horizontal admin_edit_form adminex-form valid_form_$ac"  enctype="multipart/form-data" method="post" role="form" autocomplete="off">
	$dm_cfg{hiddp}
EOH
              #SI ONGLETS*********************************************************************
              if($nb_nav > 0 && $etapeFinale ne 'etapeFinale')
              {
                  $content .=<< "EOH";
		<div class="save-top">
			<div class="row">
				<div class="col-md-6">
				$bloc_info
				</div>
				<div class="col-md-6  text-right">
					<a data-dismiss="modal" data-placement="bottom" data-original-title="$migctrad{back}" class="btn btn-sm btn-default show_only_after_document_ready cancel_edit c2" aria-hidden="true">$ICONCANCEL</a>
					$etapeFinale_button_xs
										$custom_button_xs

					$button_save
					
					
				</div>
			</div>
		</div>
		<div class="row">
			
			
			<div class="col-lg-12">
				
			$navlist
				$lines
			</div>
		</div>

EOH
              }
              else
              {
                 $content .=<< "EOH";
		<!--<div class="form-horizontal">-->
		<div class="save-top">
			<div class="row">
				<div class="col-md-6">
				$bloc_info
				</div>
				<div class="col-md-6  text-right">
					<a data-placement="bottom" data-dismiss="modal" data-original-title="$migctrad{back}" class="btn btn-sm btn-default show_only_after_document_ready cancel_edit c3" aria-hidden="true">$ICONCANCEL</a>
					$custom_button_xs
					$etapeFinale_button_xs
					$button_save
					
					
				</div>
			</div>
		</div>
		<div class="row">
			<div class="col-md-12 text-left">
				<div class="widget-box">
						<div class="widget-title">
							<!--
							<span class="icon">
								<i class="icon-pencil"></i>
							</span>
							
							<h5 style="font-weight:normal">$fonction</h5>
							-->
						</div>
						<div class="widget-content-disabled">
						$lines
					</div>
				</div>
			</div>
		</div>
		<!--</div>-->
EOH

                  # $content .=<< "EOH";
	# <div class="form-horizontal admin_edit_form adminex-form valid_form_edit">
		# <div class="save-top">
			# <div class="row">
				# <div class="col-md-6">
				# $bloc_info
				# </div>
				# <div class="col-md-6  text-right">
					# <a class="btn btn-sm btn-default show_only_after_document_ready cancel_edit" aria-hidden="true"><i class="fa fa-arrow-left"></i> $migctrad{back}</a>
					# $button_save
					# $custom_button_xs
				# </div>
			# </div>
		# </div>
		# <div class="row">
			# <div class="col-lg-12">
				# <div class="edit_group_form edit_group">
					# $lines
				# </div>
			# </div>
		# </div>
	# </div>
# EOH

              }
              $content .=<< "EOH";
	<div class="row">
		<div class="col-md-12 text-right">
		<div class="alert alert-danger validation_msg hide text-left">
	</div>
			
			<a data-dismiss="modal" data-placement="bottom" data-original-title="$migctrad{back}" class="btn btn-lg btn-default show_only_after_document_ready cancel_edit c4" aria-hidden="true">$ICONCANCEL</a>
			$custom_button_lg
			$etapeFinale_button_lg
			$button_save2
		</div>
	</div>
	<br /><br /><br />
</form>

EOH
	if($d{render} eq 'cgi')
	{
		return $content;
	}
	else
	{
		print $content;
		exit;
	}
}

################################################################################
# edit_lines
################################################################################
sub edit_lines
{
    my %d = %{$_[0]};
    my %rec = ();
    my $id_col = $dm_cfg{id_col} || 'id';
	($d{id},$dum) = split(/Expires/,$d{id});
	log_debug("edit_lines","","edit_lines");
    if($d{id} > 0)
    {
        %rec = select_table($dbh_data,$dm_cfg{table_name},"","$id_col = '$d{id}'","","",0);
		log_debug($d{id},"","edit_lines");
		
		$stmt = "UPDATE $dm_cfg{table_name} SET migcms_moment_view=NOW(),migcms_id_user_view='$user{id}' WHERE id = '$d{id}' ";
		execstmt($dbh,$stmt);
		log_debug($stmt,"","edit_lines");
    }
	
	 my %cache_listboxtables = ();


  if($dm_cfg{disable_cache_listboxtables} != 1)
  {
	  foreach $field_line (sort keys %dm_dfl)
	  {
			($ordby,$field_name) = split(/\//,$field_line);
			%line = %{$dm_dfl{$field_line}};
			$type =  $line{fieldtype};
			$data_type =  $line{data_type};
			if($type eq 'listboxtable' || $data_type eq 'listboxtable')
			{
				$lbtable = $line{lbtable};
				$lbkey = $line{lbkey};
				$lbdisplay = $line{lbdisplay};
				my %cache = ();
				my @records_for_cache = sql_lines({table=>$lbtable,select=>"$lbkey as cle, $lbdisplay as display"});
				foreach $record_for_cache (@records_for_cache)
				{
					my %record_for_cache = %{$record_for_cache};
					$cache{$record_for_cache{cle}} = $record_for_cache{display};			   
				}
				$cache_listboxtables{$field_name} = \%cache;
			}
	  }
   }
	
	
    my $id = $rec{$id_col};
    my $comparaison = "";
    my %lines_content = ();
	
    foreach my $field_line (sort keys %dm_dfl)
    {
        my ($ordby,$field_name) = split(/\//,$field_line);
        $dm_dfl{$field_line}{title} = ucfirst($dm_dfl{$field_line}{title});
        my $type =  $dm_dfl{$field_line}{fieldtype};
        my $data_type =  $dm_dfl{$field_line}{data_type} || $dm_dfl{$field_line}{datatype};
        my $hidden =  $dm_dfl{$field_line}{hidden};
        my $disabled =  $dm_dfl{$field_line}{disabled};
        my $multiple =  $dm_dfl{$field_line}{multiple};
        my $required =  $dm_dfl{$field_line}{mandatory}{type};
        my $default_value = $dm_dfl{$field_line}{default_value};
		my $disable_add = $dm_dfl{$field_line}{disable_add};
		my $disable_update = $dm_dfl{$field_line}{disable_update};
		my $translate = $dm_dfl{$field_line}{translate};
		my $hide_update = $dm_dfl{$field_line}{hide_update};
		my $tree_col = $dm_dfl{$field_line}{tree_col};
		my $old_type = $type;
		if($dm_dfl{$field_line}{frontend_only} eq 'y')
		{
			next;
		}

		if(!($id>0) && $disable_add)
		{
			next;
		}
		if(($id>0) && $hide_update)
		{
			$hidden = 1;
		}

		#si on est à l'étape finale, on ne garde que les champs mentionnés
		if($d{etapeFinale} eq 'etapeFinale' && ($dm_cfg{etapeFinaleFields} ne '' && $dm_cfg{etapeFinaleFields} !~ /$field_name/)) {
			$hidden = 1;
		}

		if($id>0 && $disable_update)
		{
			$type = 'display';
		}
		if($d{permission_modification} == 0)
		{
			# $type = 'display';
		}
        my $data_type_class = '';
        my $required_value = '';
        my $required_info = '';
        if($required eq 'not_empty')
        {
            $required_value = ' required ';
            $required_info = ' * ';
        }
        my $field = '';
		if($dm_dfl{$field_line}{placeholder} ne '' && $dm_dfl{$field_line}{tip} eq '')
		{
			$dm_dfl{$field_line}{tip} = $dm_dfl{$field_line}{placeholder};
		}
		my $clear_field = 'clear_field';
		if($dm_dfl{$field_line}{input_style} ne '' || $dm_dfl{$field_line}{class} ne '')
		{
			$clear_field = '';
		}
		
		#mode display
        if($type eq 'display')
        {
			$rec{$field_name} =~ s/\"/&quot;/g;
			if($old_type eq 'listbox')
			{
				#affiche la valeur listbox plutot que l'identifiant
				%option_values = %{$dm_dfl{$field_line}{fieldvalues}};
				foreach my $field_value (keys %option_values)
				{
					my ($test_ordby,$test_value) = split(/\//,$field_value);
					if($test_ordby > 0 && $test_value eq $rec{$field_name})
					{
						$rec{$field_name} = $option_values{$field_value};
						$field = <<"EOH";
<input type="text" disabled class="disabled form-control" value="$rec{$field_name}&nbsp;" />
EOH
						last;
					}
				}
			}
			elsif($data_type eq 'listboxtable')
			{
						my $id_rec = $rec{$field_name};		
						$valeur = $id_rec;
						if($dm_cfg{enable_cache_listboxtables} == 1)
						{
							$valeur = $cache_listboxtables{$field_name}{$id_rec};
						}
						else
						{
							my %lbtable = sql_line({table=>$dm_dfl{$field_line}{lbtable}, select=>"$dm_dfl{$field_line}{lbdisplay} as affichage",where=>"   $dm_dfl{$field_line}{lbkey} = '$id_rec'"});
							$valeur = $lbtable{affichage};
						}
						if($dm_dfl{$field_line}{translate} == 1)
						{
							$valeur = get_traduction({debug=>0,id_language=>$colg,id=>$valeur});
						}
						$field = <<"EOH";
<input type="text" disabled class="disabled form-control ancienlistboxtable  $field_name $id_rec" value="$valeur" />
EOH

			
			}
			elsif($data_type eq 'date')
			{
				$rec{$field_name} = to_ddmmyyyy($rec{$field_name});
				
				$field = <<"EOH";
<input type="text" data-ordby="$ordby" disabled class="disabled form-control" value="$rec{$field_name}&nbsp;" /> 
EOH
			}
			elsif($data_type eq 'datetime')
			{
				$rec{$field_name} = to_ddmmyyyy($rec{$field_name},'withtime');
				$field = <<"EOH";
<input type="text" data-ordby="$ordby"  disabled class="disabled form-control" value="$rec{$field_name}&nbsp;" /> 
EOH
			}
			elsif($data_type eq 'textarea')
			{
				$field = <<"EOH";
<textarea name="$field_name" $required_value id="field_$field_name" rows="3" class="form-control disabled" disabled placeholder="$placeholder">$rec{$field_name}</textarea>
EOH
			}
			elsif($data_type eq 'html')
			{
				$field = <<"EOH";
$rec{$field_name}
EOH
			}
			else
			{
				$field = <<"EOH";
<input type="text" data-ordby="$ordby"  disabled class="disabled form-control ancien_data_type_$data_type" value="$rec{$field_name}&nbsp;" /> 
EOH
			}
        }
        elsif($type eq 'display_hidden')
        {
            my $txtvalue  = $rec{$field_name} || get_quoted($field_name) || $dm_dfl{$field_line}{default_value};
			my $received_value = get_quoted($field_name) || $dm_dfl{$field_line}{default_value};
            if($data_type eq 'date')
            {
                $txtvalue = sql_to_human_date($txtvalue);
            }
            elsif($data_type eq 'time')
            {
                $txtvalue = sql_to_human_time($txtvalue);
            }
			elsif($data_type eq 'datetime')
            {
                my ($sql_date,$sql_time) = split (/ /,$txtvalue);
				$txtvalue = sql_to_human_date($sql_date).' '.sql_to_human_time($sql_time);
            }
			
            $field = <<"EOH";
$txtvalue
<input type="hidden" $disabled name="$field_name" data-defaultvalue="$received_value" value="$txtvalue" id="field_$field_name" class="form-control saveme saveme_txt $data_type_class" $required_value  />
EOH
        }
        elsif($type eq 'text' || $type eq 'text_id')
        {
            my $valeur_r = $rec{$field_name};
			if($valeur_r eq '')
			{
				$valeur_r = get_quoted($field_name);
			}
			if($valeur_r eq '' || $valeur_r eq '0000-00-00')
			{
				$valeur_r = $dm_dfl{$field_line}{default_value};
			}
			my $txtvalue  = $comparaison = $valeur_r;

            my $received_value = get_quoted($field_name);
			if($received_value eq '')
			{
				$received_value = $dm_dfl{$field_line}{default_value};
			}

			$txtvalue =~ s/\"/&quot;/g;
            #traductible
            if($type eq 'text_id')
            {
                ($txtvalue,$dum) = get_textcontent($dbh,$rec{$field_name},$colg,$dm_cfg{textcontents});
				$txtvalue =~ s/\"/&quot;/g;
                if($colg_compare > 0)
                {
                    ($comparaison,$dum) = get_textcontent($dbh,$rec{$field_name},$colg_compare,$dm_cfg{textcontents});
					if($comparaison eq '')
					{
						$comparaison = '<i class="fa fa-globe" style="color:green"></i> '.$migctrad{trad_translatein};
					}
                }
            }
			else
			{
				$comparaison = <<"EOH";
<span class="fa-stack"><i class="fa fa-globe fa-stack-1x"></i> <i class="fa fa-ban fa-stack-2x text-danger"></i></span> $migctrad{not_translatable}
EOH
			}
            #champs texte + time, date, email, phone

			if($dm_dfl{$field_line}{tip} eq "") {
				my $placeholder = $dm_dfl{$field_line}{placeholder};
			}
			else {
				my $placeholder = "<--- Contenu manquant --->";
			}

            if($data_type eq 'time')
            {
                 $txtvalue = $comparaison = sql_to_human_time($txtvalue,':');
                 if($txtvalue eq ':')
                 {
                    $txtvalue = '00:00';
                 }
				 if($txtvalue eq '00:00')
				 {
					$txtvalue = '';
				 }
                 $field = <<"EOH";
<div class="input-group">
	<span class="input-group-addon"><i class="fa fa-clock-o"></i></span>
	<input type="text" data-domask="00:00" name="$field_name" value="$txtvalue" id="field_$field_name" $required_value class="form-control saveme saveme_txt" />
</div>
EOH
            }
            elsif($data_type eq 'date')
            {
				 $txtvalue = $comparaison = sql_to_human_date($txtvalue);
				 my $class_datepicker = 'edit_datepicker';
				 if(!$d{id}>0)
				 {
					$class_datepicker = 'add_datepicker';
				 }
				 if(trim($txtvalue) eq '0000-00-00' || trim($txtvalue) eq '00/00/0000' || trim($txtvalue) eq '//')
				 {
					$txtvalue = $comparaison = '';
				 }
                 $field = <<"EOH";
<div class="input-group">
	<span class="input-group-addon"><i class="fa fa-calendar"></i></span>
	<input autocomplete="off"  data-ordby="$ordby"  type="text" data-domask="$dm_dfl{$field_line}{mask}" name="$field_name" value="$txtvalue" id="field_$field_name" class="form-control saveme saveme_txt $class_datepicker" $required_value placeholder="$placeholder" />
</div>
EOH
            }
			elsif($data_type eq 'datetime')
            {
				
				my $test = '';
				 my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
				$year+=1900;
				$mon++;
				


				if(trim($txtvalue) eq '' && $dm_dfl{$field_line}{maintenant} eq 'y')
				 {
					$test = "$mday/$mon/$year $hour:$min";
				 }
				
				my ($sql_date,$sql_time) = split (/ /,$txtvalue);
				if($sql_date ne "" && $sql_time ne "") {
					$txtvalue = sql_to_human_date($sql_date).' '.sql_to_human_time($sql_time);
				}
				
				
				if($test ne '' )
				{
					$txtvalue = $test;
				}				 
				 
				 $field = <<"EOH";
<div class="input-group">
	<span class="input-group-addon"><i class="fa fa-calendar"></i></span>
	<input autocomplete="off"  type="text" data-domask="" name="$field_name" value="$txtvalue" id="field_$field_name" class="clear_field form-control saveme saveme_txt datetimepicker" $required_value placeholder="$placeholder" />
</div>
EOH
            }
            elsif($data_type eq 'euros')
            {
                 
				 $txtvalue =~ s/\./\,/g;
				 $field = <<"EOH";
<div class="input-group">
	<span class="input-group-addon"><i class="fa fa-eur fa-fw"></i></span>
	<input autocomplete="off" data-ordby="$ordby"  type="text" data-domask="$dm_dfl{$field_line}{mask}" name="$field_name" value="$txtvalue" id="field_$field_name" class="form-control saveme saveme_txt"  $required_value  placeholder="$placeholder" />
</div>
EOH
            }
			elsif($data_type eq 'number')
            {
                 
				 $txtvalue =~ s/\./\,/g;
				 $field = <<"EOH";

	<input autocomplete="off" type="text" data-domask="$dm_dfl{$field_line}{mask}" name="$field_name" value="$txtvalue" id="field_$field_name" class="form-control saveme saveme_txt"  $required_value  placeholder="$placeholder" />

EOH
            }
			elsif($data_type eq 'perc')
            {
                 $field = <<"EOH";
<div class="input-group">
	<span class="input-group-addon">%</span>
	<input autocomplete="off" type="text" data-domask="$dm_dfl{$field_line}{mask}" name="$field_name" value="$txtvalue" id="field_$field_name" class="form-control saveme saveme_txt"  $required_value  placeholder="$placeholder" />
</div>
EOH
            }
			elsif($data_type eq 'iban')
            {
                 $field = <<"EOH";
<div class="input-group">
	<span class="input-group-addon">IBAN</span>
	<input autocomplete="off" type="text" data-domask="SS00 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000" name="$field_name" value="$txtvalue" id="field_$field_name" class="clear_field form-control saveme saveme_txt"  $required_value placeholder="$placeholder" />
</div>
EOH
            }
			elsif($data_type eq 'bic')
            {
                 $field = <<"EOH";
<div class="input-group">
	<span class="input-group-addon">BIC</span>
	<input autocomplete="off" type="text" data-domask="SSSS SS SS SS SS SS SS" name="$field_name" value="$txtvalue" id="field_$field_name" class="clear_field form-control saveme saveme_txt" $required_value placeholder="$placeholder" />
</div>
EOH
            }
            elsif($data_type eq 'email')
            {
                 $field = <<"EOH";
<div class="input-group">
	<span class="input-group-addon"><i class="fa fa-envelope-o fa-fw"></i></span>
	<input autocomplete="false" type="email" autocomplete="off" name="$field_name" value="$txtvalue" id="field_$field_name" class="clear_field form-control saveme saveme_txt edit_email" $required_value  placeholder="$placeholder" />
</div>
EOH
            }
			 elsif($data_type eq 'password')
            {
				if($config{use_securepwd} eq 'y') {
					my $securepwd_class = "securepwd";
					$field = <<"EOH";
<div class="$securepwd_class">
	<div class="input-group">
		<span class="input-group-addon"><i class="fa fa-key fa-fw"></i></span>
		<input autocomplete="new-password" type="password" autocomplete="off" name="$field_name" id="field_$field_name" class="form-control saveme saveme_txt edit_password" $required_value />

	</div>
	<i class="fa fa-info-circle"></i> $migctrad{securepwd_info}
	<!--
	<div class="pwstrength_viewport_title"><i class="fa fa-key"></i> $migctrad{pass_difficulty} :</div>
	<div class="pwstrength_viewport_progress"></div>
	<div class="pwstrength_viewport_info"><i class="fa fa-question-circle" data-placement="bottom" data-original-title="<strong>$migctrad{improve_pass} :</strong><br />$migctrad{lie_pass}.<br />$migctrad{pass_onecap}.<br />$migctrad{pass_onenumb}.<br />$migctrad{pass_onespecialchar}."></i></div>
	-->
</div>
EOH
				}
				else {
                 $field = <<"EOH";
	<div class="input-group">
		<span class="input-group-addon"><i class="fa fa-key fa-fw"></i></span>
		<input autocomplete="off" type="password" autocomplete="off" name="$field_name" id="field_$field_name" class="form-control saveme saveme_txt edit_password" $required_value />
	</div>
EOH
				}
            }
            elsif($data_type eq 'phone' || $data_type eq 'tel' || $data_type eq 'gsm' || $data_type eq 'fax')
            {
                 $field = <<"EOH";
<input type="text" autocomplete="off" name="$field_name" value="$txtvalue" id="field_$field_name" class="form-control telinput saveme_tel $data_type_class" $required_value placeholder="$dm_dfl{$field_line}{placeholder}" />
<!--
<div class="input-group">
	<span class="input-group-addon"><i class="fa fa-phone fa-fw"></i></span>
	<input type="tel" data-domask="$dm_dfl{$field_line}{mask}" name="$field_name" value="$txtvalue" id="field_$field_name" class="form-control saveme saveme_txt edit_tel" $required_value  placeholder="$placeholder" />
</div>
-->
EOH
            }
			elsif($data_type eq 'autocomplete')
            {
				 my $class_autocomplete = 'update_autocomplete_txt';
				 if(!$d{id}>0)
				 {
					$class_autocomplete = 'insert_autocomplete_txt';
				 }
			  $field = <<"EOH";
<input type="text" data-doautocomplete="$dm_dfl{$field_line}{autocomplete_target}" name="$field_name" value="$txtvalue" id="field_$field_name" class="form-control saveme $class_autocomplete saveme_txt $data_type_class" $required_value placeholder="$dm_dfl{$field_line}{tip}" />
EOH
            }
            else
            {
				
			  $field = <<"EOH";
<input style="$dm_dfl{$field_line}{input_style}" type="text" autocomplete="off" data-domask="$dm_dfl{$field_line}{mask}" rel="$received_value" name="$field_name" value="$txtvalue" id="field_$field_name" class="$clear_field form-control saveme saveme_txt $data_type_class" $required_value placeholder="$dm_dfl{$field_line}{tip}" />
EOH
            }
        }
        elsif($type eq 'textarea' || $type eq 'textarea_id')
        {
            if(0 && $data_type eq 'code')
			{
				$field = <<"EOH";
<textarea name="$field_name" $required_value id="field_$field_name" rows="3" class="form-control saveme">$txtvalue</textarea>
<script>var myCodeMirror = CodeMirror.fromTextArea(document.getElementById("field_$field_name"));</script>
EOH
			}
			else
			{
				my $txtvalue  = $comparaison = $rec{$field_name};
				if($type eq 'textarea_id')
				{
					($txtvalue,$dum) = get_textcontent($dbh,$rec{$field_name},$colg,$dm_cfg{textcontents});
				}
				if($comparaison eq '')
				{
					$comparaison = '<i class="fa fa-globe" style="color:green"></i> A traduire';
				}
				$field = <<"EOH";
<textarea name="$field_name" $required_value id="field_$field_name" rows="3" class="form-control saveme" placeholder="$placeholder">$txtvalue</textarea>
EOH
			}
        }
        elsif($type eq 'textarea_editor' || $type eq 'textarea_id_editor')
        {
           my $txtvalue  = $comparaison = $rec{$field_name};
           if($type eq 'textarea_id_editor')
           {
                ($txtvalue,$dum) = get_textcontent($dbh,$rec{$field_name},$colg,$dm_cfg{textcontents});
                if($colg_compare > 0)
                {
                    ($comparaison,$dum) = get_textcontent($dbh,$rec{$field_name},$colg_compare,$dm_cfg{textcontents});
					if($comparaison eq '')
					{
						$comparaison = '<i class="fa fa-globe" style="color:green"></i> '.$migctrad{trad_translatein};
					}
                }
           }
           my $token = create_token(5);
           my $id = "field_$field_name".$token;
           $field = <<"EOH";
<div class="wysiwyg-container">
	<textarea name="$field_name" id="$id"  class="saveme wysiwyg input-block-level" $required_value style="width:100%;height:200px;">$txtvalue</textarea>
</div>
EOH
        }
        elsif($type eq 'pic')
        {
            # my $pic_preview = get_pic_thumb($dbh_data,$rec{$field_name});
            $field = <<"EOH";
<input type="file" $required_value name="$field_name" id="field_$field_name" class="span6 saveme" /> $pic_preview
EOH
        }
        elsif($type eq 'listbox' || $type eq 'listboxtable')
        {
			  	 my $txtvalue  = $rec{$field_name};
				if($txtvalue eq '' || $txtvalue eq ',,')	
				{
					$txtvalue = get_quoted($field_name);
				}	
				if($txtvalue eq '' || $txtvalue eq ',,')	
				{
					$txtvalue = $default_value;
				}	
# log_debug('$field_name:'.$field_name,'','listboxdebug');
# log_debug('txtvalue:'.$txtvalue,'','listboxdebug');

			  my $select_class = "form-control";
			  $comparaison = <<"EOH";
					<span class="fa-stack"><i class="fa fa-globe fa-stack-1x"></i><i class="fa fa-ban fa-stack-2x text-danger"></i></span> $migctrad{not_translatable}
EOH

              if($data_type eq 'treeview')
			  {
					 #CB TREEVIEW --------------------------------------------------------------------------

					 my $treeview = edit_lines_listboxtable_treeview({dbh=>$dbh,multiple=>$dm_dfl{$field_line}{multiple},lbwhere=>$dm_dfl{$field_line}{lbwhere},field=>$field_name,translate=>$translate,field_line=>$field_line,value=>$txtvalue,tree_col=>$tree_col});

						my @t = split(/,/,$txtvalue);
						my @t2 = ();
						foreach my $t (@t) {
						   push @t2,$field_name."_".$t;
						}
						$txtvalue = join(",",@t2);

					 $field =<<"EOH"
						<div class="listboxtable_treeview_container" style="$dm_dfl{$field_line}{div_style}">
							$treeview
						</div>
						<div style="display:none;">
							<input type="text" name="$field_name" rel="$txtvalue" value="$txtvalue" id="field_$field_name" class="field_$field_name form-control saveme saveme_txt $data_type_class" $required_value  placeholder="$dm_dfl{$field_line}{tip}" />
						</div>
EOH
			  }
			  elsif($data_type eq 'autocomplete')
			  {
					 #AUTOCOMPLETE --------------------------------------------------------------------------
					

				  	my %rec = sql_line({debug=>1,debug_results=>1,table=>$dm_dfl{$field_line}{lbtable},select=>"$dm_dfl{$field_line}{lbdisplay} as affichage",where=>"$dm_dfl{$field_line}{lbkey} = '$txtvalue' $dm_dfl{$field_line}{lbwhere_display} "});
					
					$field =<<"EOH"
						<table style="width:90%!important">
						<tr>
						
						<td>						
						<input type="text" name="autocomplete_$field_name" rel="$field_name" data-key="$txtvalue" value="$rec{affichage}" id="autocomplete_$field_name" class=" autocomplete_$field_name form-control $data_type_class listboxtable_autocomplete" $required_value  placeholder="$dm_dfl{$field_line}{tip}" />
						</td>
						<td style="width:20px">
						<a href="" class="erase_autocomplete btn btn-warning" data-nameautocomplete="$field_name"><i class="fa fa-eraser" aria-hidden="true"></i></a>
						</td>
						</tr>
						</table>
EOH
			  }
			  elsif($data_type eq '' || $data_type eq 'btn-group' || $data_type eq 'button')
			  {
	 			  #LISTBOX ou BOUTTONS --------------------------------------------------------------------------
				  ($field,$list_btns) = edit_lines_listboxes({split_on_disabled=>$dm_dfl{$field_line}{split_on_disabled},disabled=>$dm_dfl{$field_line}{disabled},debug=>0,translate=>$translate,multiple=>$multiple,list_btns=>1,class=>$select_class,default_value=>$txtvalue,rec=>\%rec,type=>$type,field_name=>$field_name,field_line=>$field_line,required_value=>$required_value,required_info=>$required_info});

   				  if( $data_type eq 'btn-group' || $data_type eq 'button')
				  {
					  # log_debug('txtvalue avant:'.$txtvalue,'','listboxdebug');
					  if($rec{$field_name} eq '' || $rec{$field_name} == 0)
					  {
						  $rec{$field_name} = $dm_dfl{$field_line}{default_value};
					  }
					  # log_debug('txtvalue apres1:'.$txtvalue,'','listboxdebug');
					  if($txtvalue eq '' || $txtvalue eq '0')
					  {
						  $txtvalue = $dm_dfl{$field_line}{default_value};
					  }
					  # log_debug('txtvalue apres2:'.$txtvalue,'','listboxdebug');
					  $field =<<"EOH"
							<div class="multiple_$multiple" style="width:100%;display: flex; flex-wrap: wrap;">
								$list_btns
							</div>
							<div style="display:none;">
								<input type="text" name="$field_name" data-defaultvalue="$dm_dfl{$field_line}{default_value}" rel="$txtvalue" value="$txtvalue" data-old-value="$rec{$field_name}" id="field_$field_name" class="field_$field_name form-control saveme saveme_txt $data_type_class" $required_value  placeholder="$dm_dfl{$field_line}{tip}" />
							</div>
EOH
				  }
			}
        }
        elsif($type eq 'checkbox')
        {
             my $checked = '';
             my $btn_class = ' btn-default ';
             if($rec{$field_name} eq 'y' || get_quoted($field_name) eq 'y' || ($rec{$field_name} eq '' && $dm_dfl{$field_line}{default_value} eq 'y'))
             {
                $checked = ' checked = "checked" ';
                $btn_class = ' btn-info cb_valide_'.$field_name;
             }
             if($data_type eq 'btn')
             {
                 $field = <<"EOH";
<a class="btn $btn_class mig_btn_cb_toggle">$dm_dfl{$field_line}{title}</a>
<span class="hide mig_btn_cb_container"><input  data-ordby="$ordby"  type="checkbox" id="field_$field_name" $checked name="$field_name" $required_value class="form-control cbsaveme" value="y" /></span>
EOH
             }
             else
             {
                 $field = <<"EOH";
<label><input type="checkbox" id="field_$field_name"   data-ordby="$ordby" $checked name="$field_name" $required_value class=" cbsaveme" value="y" /> $dm_dfl{$field_line}{title}</label>
EOH
             }
        }
		elsif($type eq 'file')
        {
			my $action_file = '$migctrad{add_file}';
			my $download_link = '';
			if($rec{$field_name} ne '')
			{
				$action_file = '$migctrad{replace_file}';
				$download_link = <<"EOH";
<a class="btn btn btn-default filepreview" target="_blank" href="$config{baseurl}/pics/$rec{$field_name}" data-original-title="$migctrad{see}"><i class="fa fa-eye  pull-left"></i> $rec{$field_name}</a>
EOH
			}
			else
			{
				$download_link = <<"EOH";
<a class="btn btn btn-default filepreview hide" href="#">$migctrad{preview_afterselec}</a>
EOH
			}
			 $field = <<"EOH";
<a class="btn btn-primary btn click_next"  data-original-title="$action_file" ><i class="fa fa-upload pull-left"></i> $migctrad{browse}...</a>
<input type="file" name="$field_name" id="field_$field_name" class="filesaveme hide" />
$download_link
<div class="migcms_file_perc_progress progress">
	<div class="migcms_file_perc_progress_bar progress-bar" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100" style="width: 0%;"></div>
</div>
<div class="text-center"><span class="migcms_file_perc">0%</span></div>
EOH
        }
		elsif($type eq 'files_admin' && $d{permission_modification} != 0)
        {
			 $field = <<"EOH";
<div class="dropzone_container dropzone_container_$field_name" id="$field_name" rel="$dm_dfl{$field_line}{title}: $dm_dfl{$field_line}{msg}">CONTAINER</div>
EOH
        }
		elsif($type eq 'files_admin' && $d{permission_modification} == 0)
        {
			 $field = <<"EOH";
$dm_dfl{$field_line}{title}
EOH
        }
		elsif($type eq 'titre' )
        {
			 $field = <<"EOH";
<p>$dm_dfl{$field_line}{title}</p>
EOH
        }
		elsif($type eq 'button' )
        {
			  my $legend = $dm_dfl{$field_line}{legend};
			if($legend ne '') {
				$legend = '<i class="fa fa-info-circle"></i> '.$dm_dfl{$field_line}{legend};
			}
			 
			 my $title = $dm_dfl{$field_line}{title};
			 $dm_dfl{$field_line}{title} = '';
			 
			 
			 $field = <<"EOH";
<a class="$dm_dfl{$field_line}{bouton_class} button_field_$field_name" href="#" id="$field_name">$title</a> <br />$legend
EOH
        }
        else
        {
              $field = "$migctrad{field_type_notsupported} : [$type]";
        }


		my $tab = $dm_dfl{$field_line}{tab} || $dm_cfg{default_tab} || 'Fiche';
        my $legend = $dm_dfl{$field_line}{legend};
		if($legend ne '') {
			$legend = '<i class="fa fa-info-circle"></i> '.$dm_dfl{$field_line}{legend};
		}
		my $class_hide = '';
		if($hidden == 1)
		{
			$class_hide = ' hide ';
		}
		if($dm_dfl{$field_line}{fieldtype} eq 'checkbox' || $dm_dfl{$field_line}{fieldtype} eq 'titre')
		{
			$dm_dfl{$field_line}{title} = $required_info = '';
		}
		
        if($colg_compare > 0)
        {
				
				
				$lines_content{$tab} .=<<"EOH";
<div class="edit_group_$tab edit_group">
	<div class="row row_edit_$field_name migcms_group_data_type_$data_type hidden_$hidden $class_hide $dm_dfl{$field_line}{class}">
		<div class="col-md-8">
			<div class="form-group migcms_group_data_type_$data_type $dm_dfl{$field_line}{class}">
				<label for="field_$field_name" class="control-label">$dm_dfl{$field_line}{title} $required_info</label>
				<div class="controls">
					 $field 
					<span class="help-block text-left">$legend</span>
				</div>
			</div>
		</div>
		<div class="col-md-4">
			<p style="padding-top: 30px;">$comparaison</p>
		</div>
	</div>
</div>
EOH
		}
        else
        {
			my $line_content = <<"EOH";
				<label for="field_$field_name" class="col-sm-2 control-label $dm_dfl{$field_line}{class}">
					$dm_dfl{$field_line}{title} $required_info 
				</label>
				<div class="col-sm-10 mig_cms_value_col $dm_dfl{$field_line}{class}">
					$field
					<span class="help-block text-left">$legend</span>
				</div>
EOH
			if($dm_dfl{$field_line}{fieldtype} eq 'titre')
			{
				$line_content = <<"EOH";
					<div class="col-sm-12 l6487 mig_cms_value_col $dm_dfl{$field_line}{class}" style="font-size:14px;background-color:#414e5f;color:white!important;padding-top:10px;">
						$field
					</div>
EOH
			}
			elsif($dm_dfl{$field_line}{fieldtype} eq 'func')
			{
				my $field_func = $dm_dfl{$field_line}{func};
				if($field_func ne '')
				{
					$line_content = &$field_func($dbh,$id);            
				}
			}
			elsif($dm_dfl{$field_line}{fieldtype} eq 'adresse')
			{
				my $id_map = 'map_'.$field_name;
				
				# migcms_map_autocomplete_map_$field_name_street_number
				my %map_ids = (
				'route' =>  'migcms_map_autocomplete_map_'.$field_name.'_route',				
				'street_number' =>  'migcms_map_autocomplete_map_'.$field_name.'_street_number',				
				'locality' =>  'migcms_map_autocomplete_map_'.$field_name.'_locality',				
				'postal_code' =>  'migcms_map_autocomplete_map_'.$field_name.'_postal_code',				
				'country' =>  'migcms_map_autocomplete_map_'.$field_name.'_country',				
				'lat' =>  'migcms_map_autocomplete_map_'.$field_name.'_lat',				
				'lon' =>  'migcms_map_autocomplete_map_'.$field_name.'_lon',				
				'lat_degres' =>  'migcms_map_autocomplete_map_'.$field_name.'_lat_degres',				
				'lat_minutes' =>  'migcms_map_autocomplete_map_'.$field_name.'_lat_minutes',				
				'lat_secondes' =>  'migcms_map_autocomplete_map_'.$field_name.'_lat_secondes',				
				'lon_degres' =>  'migcms_map_autocomplete_map_'.$field_name.'_lon_degres',				
				'lon_minutes' =>  'migcms_map_autocomplete_map_'.$field_name.'_lon_minutes',				
				'lon_secondes' =>  'migcms_map_autocomplete_map_'.$field_name.'_lon_secondes',				
				);
				
				#noms des champs
				my $c=0;
				my @adresse_fields = split(/\,/,$dm_dfl{$field_line}{adresse_fields});
				my %map_cols = (
				'route' =>  $adresse_fields[$c++],
				'street_number' =>  $adresse_fields[$c++],
				'box' => $adresse_fields[$c++],
				'street2' =>  $adresse_fields[$c++],		
				'postal_code' =>  $adresse_fields[$c++],
				'locality' =>  $adresse_fields[$c++],
				'country' =>  $adresse_fields[$c++],		
				'lat' =>  $adresse_fields[$c++],						
				'lon' => $adresse_fields[$c++],					
				'lat_degres' => $adresse_fields[$c++],	
				'lat_minutes' => $adresse_fields[$c++],	
				'lat_secondes' => $adresse_fields[$c++],
				'lon_degres' => $adresse_fields[$c++],
				'lon_minutes' => $adresse_fields[$c++],
				'lon_secondes' => $adresse_fields[$c++],
				);
				
				#valeurs par défaut
				my $c=0;
				my @default_values = split(/\,/,$dm_dfl{$field_line}{default_values});
				my %map_defaults = (
				'route' =>  $default_values[$c++],
				'street_number' =>  $default_values[$c++],
				'box' => $default_values[$c++],
				'street2' =>  $default_values[$c++],		
				'postal_code' =>  $default_values[$c++],
				'locality' =>  $default_values[$c++],
				'country' =>  $default_values[$c++],		
				'lat' =>  $default_values[$c++],						
				'lon' => $default_values[$c++],					
				'lat_degres' => $default_values[$c++],	
				'lat_minutes' => $default_values[$c++],	
				'lat_secondes' => $default_values[$c++],
				'lon_degres' => $default_values[$c++],
				'lon_minutes' => $default_values[$c++],
				'lon_secondes' => $default_values[$c++],
				);
				
				if($rec{$map_cols{country}} eq '')
				{
					$rec{$map_cols{country}} = $map_defaults{country};
				}
				
				#champs renommés
				foreach my $adresse_field (@adresse_fields)
				{
					$item{$adresse_field} = trim(get_quoted($adresse_field));
				}
				# use Data::Dumper;

				# log_debug(Dumper(\%rec),'','member_street');
				
				my $class_for_bloc_carte = $dm_cfg{class_for_bloc_carte} || 'hidea';
				my $class_for_bloc_gps = $dm_cfg{class_for_bloc_gps} || 'hidea';
				my $default_class_for_bloc_carte = $dm_cfg{default_class_for_bloc_carte} || 'btn-info';
				my $default_class_for_bloc_gps = $dm_cfg{default_class_for_bloc_gps} || 'btn-info';
				
				
				$line_content = <<"EOH";
						<label for="field_$field_name" class="col-sm-2 control-label">
							$dm_dfl{$field_line}{title} 
							<br />
							<br />
							<a class="btn $default_class_for_bloc_carte btn-block show_map_bloc_carte " data-id="$id_map">
								<i class="fa fa-map" aria-hidden="true"></i> Afficher la carte 
							</a>
							<a class="btn $default_class_for_bloc_gps btn-block show_map_bloc_gps " data-id="$id_map">
								<i class="fa fa-compass" aria-hidden="true"></i> Afficher les coordonnées GPS
							</a>
							
						
						</label>
						<div class="col-sm-10 mig_cms_value_col">
							<div class="panel panel-primary">
								<div class="panel-heading hide">
									<h3 class="panel-title">$dm_dfl{$field_line}{title}</h3>
								</div>
								<div class="panel-body">
									
										
									<div class="form-group map_bloc_carte map_bloc_carte_$id_map $class_for_bloc_carte ">
										<div class="col-md-12 migcms_map " id="$id_map" style="width:100%; height:275px;">
										... 
										</div>
									</div>
									<div class="form-group map_bloc_carte_$id_map $class_for_bloc_gps">
										<div class="col-md-12">
											<input type="text" style="background-color:#eee!important" name="migcms_map_autocomplete_map_$field_name" id="migcms_map_autocomplete_map_$field_name" class=" form-control   "  />															
										</div>
									</div>
									
									<div class="form-group">
										<div class="col-md-6">
											<input style="" type="text" autocomplete="off" data-domask="" rel="" name="$map_cols{route}" value="$rec{$map_cols{route}}" id="$map_ids{route}" class="clear_field form-control saveme saveme_txt " placeholder="Rue" />
										</div>
										<div class="col-md-3">
											<input style="" type="text" autocomplete="off" data-domask="" rel="" name="$map_cols{street_number}" value="$rec{$map_cols{street_number}}" id="$map_ids{street_number}" class="clear_field form-control saveme saveme_txt " placeholder="Numéro" />
										</div>
										<div class="col-md-3">
											<input style="" type="text" autocomplete="off" data-domask="" rel="" name="$map_cols{box}" value="$rec{$map_cols{box}}" id="$map_ids{box}" class="clear_field form-control saveme saveme_txt " placeholder="Boîte" />
										</div>
									</div>
									<div class="form-group">
										<div class="col-md-12">
											<input style="" type="text" autocomplete="off" data-domask="" rel="" name="$map_cols{street2}" value="$rec{$map_cols{street2}}" id="$map_ids{street2}" class="clear_field form-control saveme saveme_txt " placeholder="Complément d'adresse" />
										</div>
									</div>
									<div class="form-group">
										<div class="col-md-3">
											<input style="" type="text" autocomplete="off" data-domask="" rel="" name="$map_cols{postal_code}" value="$rec{$map_cols{postal_code}}" id="$map_ids{postal_code}" class="clear_field form-control saveme saveme_txt " placeholder="Code postal" />
										</div>
										<div class="col-md-5">
											<input style="" type="text" autocomplete="off" data-domask="" rel="" name="$map_cols{locality}" value="$rec{$map_cols{locality}}" id="$map_ids{locality}" class="clear_field form-control saveme saveme_txt " placeholder="Ville" />
										</div>
										<div class="col-md-4">
											<input style="" type="text" autocomplete="off" data-domask="" rel="" name="$map_cols{country}" value="$rec{$map_cols{country}}" id="$map_ids{country}" class="clear_field form-control saveme saveme_txt " placeholder="Pays" />
										</div>
									</div>
									
									
									<div class="form-group map_bloc_gps map_bloc_gps_$id_map $class_for_bloc_gps">
										<div class="col-md-6">
											<div class="row">
												<div class="col-md-12">
													<h3>DD (degrés décimaux)</h3>
												</div>
												<div class="col-md-6">
													Latitude:
												</div>
												<div class="col-md-6">
													<input  type="text" autocomplete="off" data-domask="" rel="" name="$map_cols{lat}" value="$rec{$map_cols{lat}}" id="$map_ids{lat}" class="clear_field form-control saveme saveme_txt " placeholder="Latitude" />
												</div>
												<div class="col-md-6">
													Longitude:
												</div>
												<div class="col-md-6">
													<input  type="text" autocomplete="off" data-domask="" rel="" name="$map_cols{lon}" value="$rec{$map_cols{lon}}" id="$map_ids{lon}" class="clear_field form-control saveme saveme_txt " placeholder="Longitude" />
												</div>
											</div>
										</div>
										
										<div class="col-md-6">
												<div class="row">
												<div class="col-md-12">
													<h3>DMS (degrés, minutes, secondes)</h3>
												</div>
												<div class="col-md-3">
													Latitude:
												</div>
												<div class="col-md-9">
													<div class="row">
														<div class="col-md-3">
															<input  type="text"  autocomplete="off" data-domask="" rel="" name="$map_cols{lat_degres}" value="$rec{$map_cols{lat_degres}}" id="$map_ids{lat_degres}" class=" form-control saveme saveme_txt " placeholder="" /> 
														</div>
														<div class="col-md-1">
															°
														</div>
														<div class="col-md-3">
															<input  type="text"  autocomplete="off" data-domask="" rel="" name="$map_cols{lat_minutes}" value="$rec{$map_cols{lat_minutes}}" id="$map_ids{lat_minutes}" class=" form-control saveme saveme_txt " placeholder="" /> 
														</div>
														<div class="col-md-1">
															'
														</div>
														<div class="col-md-3">
															<input  type="text"  autocomplete="off" data-domask="" rel="" name="$map_cols{lat_secondes}" value="$rec{$map_cols{lat_secondes}}" id="$map_ids{lat_secondes}" class=" form-control saveme saveme_txt " placeholder="" /> 
														</div>
														<div class="col-md-1">
														"
														</div>
													</div>
												</div>
												<div class="col-md-3">
													Longitude:
												</div>
												<div class="col-md-9">
													<div class="row">
														<div class="col-md-3">
															<input  type="text"  autocomplete="off" data-domask="" rel="" name="$map_cols{lon_degres}" value="$rec{$map_cols{lon_degres}}" id="$map_ids{lon_degres}" class=" form-control saveme saveme_txt " placeholder="" /> 
														</div>
														<div class="col-md-1">
															°
														</div>
														<div class="col-md-3">
															<input  type="text"  autocomplete="off" data-domask="" rel="" name="$map_cols{lon_minutes}" value="$rec{$map_cols{lon_minutes}}" id="$map_ids{lon_minutes}" class=" form-control saveme saveme_txt " placeholder="" /> 
														</div>
														<div class="col-md-1">
															'
														</div>
														<div class="col-md-3">
															<input  type="text"  autocomplete="off" data-domask="" rel="" name="$map_cols{lon_secondes}" value="$rec{$map_cols{lon_secondes}}" id="$map_ids{lon_secondes}" class=" form-control saveme saveme_txt " placeholder="" /> 
														</div>
														<div class="col-md-1">
															"
														</div>
													</div>
												</div>
											</div>
										</div>
									</div>
									
									
									
								
								</div>
							</div>
						</div>
						
											
						
					
						
EOH
			# <script async defer src="https://maps.googleapis.com/maps/api/js?key=AIzaSyDrMTzDM5WDr1nqKW3PoF0QQAlQg4mpKBg&signed_in=true&callback=initMap"></script>
					# <label for="field_$field_name" class="col-sm-2 control-label">
					# $dm_dfl{$field_line}{title} $required_info 
					# </label>
					# <div class="col-sm-10 mig_cms_value_col">
					# <div class="row">
					
					
					# <div class="col-sm-12 mig_cms_value_col" style="font-size:14px;background-color:#414e5f;color:white!important;padding-top:10px;">
						# $dm_dfl{$field_line}{title}
					# </div>	
					# <div class="row">
							# <div class="col-xs-6">
								# <input style="" type="text" autocomplete="off" data-domask="" rel="" name="member_vat" value="" id="field_member_vat" class="clear_field form-control saveme saveme_txt " placeholder="Rue" />
							# </div>
							# <div class="col-xs-3">
								# <input style="" type="text" autocomplete="off" data-domask="" rel="" name="member_vat" value="" id="field_member_vat" class="clear_field form-control saveme saveme_txt " placeholder="Numéro" />
							# </div>
							# <div class="col-xs-3">
								# <input style="" type="text" autocomplete="off" data-domask="" rel="" name="member_vat" value="" id="field_member_vat" class="clear_field form-control saveme saveme_txt " placeholder="Boîte" />
							# </div>
						# </div>
					# </div>
			
			}
			if($dm_dfl{$field_line}{class} ne '')
			{
				# $line_content = <<"EOH";
					# <span class="control-label">$dm_dfl{$field_line}{title} $required_info </span>	$field
# EOH
			}
			
			
			$lines_content{$tab} .=<<"EOH";
<div class="form-group item $dm_dfl{$field_line}{class} row_edit_$field_name  migcms_group_data_type_$data_type hidden_$hidden $class_hide">
	$line_content
</div>
EOH
		}
    }
    my $fonction = "";
    my %langue = read_table($dbh,"migcms_languages",$colg);
    $langue{name} = uc($langue{name});
    $dm_cfg{add_title} = $dm_cfg{add_title} || '';
	if($dm_cfg{trad} != 1)
	{
			if($id > 0 && $id ne 'NaN')
			{
			  $fonction = "$migctrad{registration_modif} N°<b>$id</b>";
			}
			else
			{
			  # $fonction = $dm_cfg{add_title};
			}
	}
	else
	{
			if($d{permission_modification} != 0 && $id > 0 && $id ne 'NaN')
			{
			  $fonction = "$migctrad{registration_modif} N°<b>$id</b> en <b>$langue{name}</b>";
			}
			elsif($d{permission_modification} == 0 && $id > 0 && $id ne 'NaN')
			{
			  $fonction = "$migctrad{registration_modif} N°<b>$id</b> en <b>$langue{name}</b>";
			}
			else
			{
			  $fonction = $dm_cfg{add_title}." <b>$langue{name}</b>";
			}



	}
	my $bloc_info = '';
	if($fonction ne '')
	{
		$bloc_info = <<"EOH";
<p class="bg-default bloc-info">$fonction</p>
EOH
	}
    my $lines = <<"EOH";
<div class="well">
EOH
    my $class  = 'active';
	
	if($#dm_nav == -1)
	{
		foreach $tab (sort keys %lines_content)
		{
			$lines .= <<"EOH";
				<div class="edit_group_$tab edit_group">
				$sys_code
				$lines_content{$tab}
				</div>
EOH
				$class ='';
		}
    }
    foreach $dm_nav (@dm_nav)
    {
          my %dm_nav_line = %{$dm_nav};
		  if($dm_nav_line{type} eq 'func' && $dm_nav_line{func} ne '')
          {
               my $func = $dm_nav_line{func};
               if(($dm_nav_line{disable_add} != 1 && $id eq '') || $id > 0)
			   {
				   $lines.=<<"EOH";
						<div rel="$id" class="edit_group_$dm_nav_line{tab} edit_group edit_group_func" id="$func"> $migctrad{loading} ... </div>
EOH
				}
          }
		  elsif($dm_nav_line{type} eq 'cgi_func' && $dm_nav_line{cgi_func} ne '')
          {
               my $cgi_func = $dm_nav_line{cgi_func};
			   if($cgi_func ne '')
			   {
					my $cgi_func_content = &$cgi_func($dbh_data,$id);            
				    if(($dm_nav_line{disable_add} != 1 && $id eq '') || $id > 0)
				    {
					   $lines.=<<"EOH";
							<div rel="$id" class="edit_group_$dm_nav_line{tab} edit_group edit_group_cgi_func" id="">$cgi_func_content</div>
EOH
					}
			   }
			  
          }
		  else
		  {
				if(($id>0) || ( !($id>0) && $dm_nav_line{disable_add} != 1))
				{
					if($dm_nav_line{cgi_func} ne '')
					{
						my $func = $dm_nav_line{cgi_func};
						$lines_content{$dm_nav_line{tab}} = &$func($dbh,$id);
					}
					$lines.=<<"EOH";
						<div class="edit_group_$dm_nav_line{tab} edit_group">
							$lines_content{$dm_nav_line{tab}}
						</div>
EOH
				}
		  }
    }

	$lines.=<<"EOH";
</div>
<input type="hidden" class="id_user" name="id_user" value="$user{id}" />
<input type="hidden" class="edit_id" name="edit_id" value="$d{id}" />
<input type="hidden" class="colg" name="colg" value="$colg" />
<input type="hidden" class="colg_compare" name="colg_compare" value="$colg_compare" />
EOH
    return ($lines,$bloc_info);
}

sub edit_lines_listboxtable_treeview
{
	my %d = %{$_[0]};

	my $treeview = edit_lines_listboxtable_treeview_recursion({dbh=>$d{dbh}, lbwhere=>$d{lbwhere}, $d{tree_col}=>0, translate=>$d{translate},field=>$d{field}, field_line=>$d{field_line},value=>$d{value},tree_col=>$d{tree_col}});
	my $treeview_container = <<"EOH";
	   <div id="$d{field}" class="listboxtable_treeview listboxtable_treeview_$d{multiple}" style="border: 1px solid #e3e3e3;border-radius: 4px;">
			$treeview
		</div>
EOH
	if($dm_dfl{$d{field_line}}{summary} == 1)
	{
		$treeview_container = '<div class="resume_treeview">'.get_listboxtable_treeview_resume_treeview(\%d).'</div>'.$treeview_container;
	}
	
	return $treeview_container;
}

sub edit_lines_listboxtable_autocomplete
{
	my %d = %{$_[0]};

	my $autocomplete_container = <<"EOH";
	   <div id="$d{field}" class="listboxtable_autocomplete listboxtable_autocomplete_$d{multiple}" style="border: 1px solid #e3e3e3;border-radius: 4px;">
				<input id="example1" type="text" name="country" placeholder="Enter a Country" class="form-control">
		</div>
EOH
		
	return $autocomplete_container;
}



sub get_listboxtable_treeview_resume_treeview
{
	my %d = %{$_[0]};
	my @values = split(/\,/,$d{value});
	
	my $resume = '<p><ul class="bg-info">';

	foreach my $value(@values)
	{
		if($value ne "")
		{
		   $d{me} = $value;
		   my $chemin = get_listboxtable_treeview_resume_treeview_chemin(\%d);
		   $resume .= <<"EOH";
			<li>$chemin </li>
EOH
		}
	}
	$resume .= <<"EOH";
			</ul></p>
EOH
	return $resume;
}

sub get_listboxtable_treeview_resume_treeview_chemin
{
	my %d = %{$_[0]};
	my $me = $d{me};
	my $parent_col = $dm_dfl{$d{field_line}}{tree_col};
	if($dm_dfl{$d{field_line}}{lbkey} eq '')
	{
		$dm_dfl{$d{field_line}}{lbkey} = 'id';
	}
  my $select_father = ", $parent_col as parent_col"; 
	if($parent_col eq '')
	{
   $select_father = "";		
	}
	
	my %me = sql_line({dbh=>$d{dbh},debug=>0,debug_results=>0,select=>$dm_dfl{$d{field_line}}{lbdisplay}." as valeur_affichee $select_father",table=>$dm_dfl{$d{field_line}}{lbtable},where=>"$dm_dfl{$d{field_line}}{lbkey}='$me'"});
	if($me{parent_col} ne "")
	{
		$d{me} = $me{parent_col};
		if($dm_dfl{$d{field_line}}{translate} == 1)
		{
			$me{valeur_affichee} = get_traduction({debug=>0,id_language=>$colg,id=>$me{valeur_affichee}});
		}
		
		$me{valeur_affichee} = get_listboxtable_treeview_resume_treeview_chemin(\%d).' > '.$me{valeur_affichee};
		
		
	}
		
	return $me{valeur_affichee};
}

sub edit_lines_listboxtable_treeview_recursion
{
	my %d = %{$_[0]};
	if($dm_dfl{$d{field_line}}{lbordby} eq '')
	{
		$dm_dfl{$d{field_line}}{lbordby} = 'ordby';
	}
	if($dm_dfl{$d{field_line}}{lbkey} eq '')
	{
		$dm_dfl{$d{field_line}}{lbkey} = 'id';
	}

	my @values = split(/\,/,$d{value});

	my $level = <<"EOH";
	<ul>
EOH

  my $where = $d{lbwhere};

  if ($d{tree_col} ne "")
  {

	  if($where ne '')
	  {
		$where = "($where) AND ";
	  }
	  $where .= "id_father='$d{id_father}'";
  }

	my @listbox_table_treeview_lines = sql_lines({
                                       dbh=>$d{dbh},
                                       table=>"$dm_dfl{$d{field_line}}{lbtable}",
                                       where=>$where,
                                       ordby=>"$dm_dfl{$d{field_line}}{lbordby}",
                                     });

	foreach my $listbox_table_treeview_line (@listbox_table_treeview_lines)
	{
		my %listbox_table_treeview_line = %{$listbox_table_treeview_line};

		my $field_name = $dm_dfl{$d{field_line}}{lbdisplay};
		my $display_value = $listbox_table_treeview_line{$field_name};


		my $check_status = '';

		my $est_coche = 'n';
		foreach my $valeur (@values)
		{
			if($valeur eq $listbox_table_treeview_line{$dm_dfl{$d{field_line}}{lbkey}})
			{
				$est_coche='y';
				last;
			}
		}

		if($est_coche eq 'y')
		{
			$check_status = 'checked';
		}

		if($d{translate} == 1)
		{
			$display_value = get_traduction({debug=>0,id_language=>$colg,id=>$display_value});
		}

		$level .= <<"EOH";
			<li data-jstree='{"opened":false}' rel="$d{field}" id="$d{field}_$listbox_table_treeview_line{$dm_dfl{$d{field_line}}{lbkey}}" data-checkstate="$check_status"> $display_value
EOH
    if ($d{tree_col} ne '') {
		    $level .= edit_lines_listboxtable_treeview_recursion({dbh=>$d{dbh}, lbwhere=>$d{lbwhere},translate=>$d{translate},$d{tree_col}=>$listbox_table_treeview_line{$dm_dfl{$d{field_line}}{lbkey}}, field=>$d{field}, field_line=>$d{field_line},value=>$d{value},tree_col=>$d{tree_col}});
    }

		$level .= <<"EOH";

			</li>
EOH
	}

$level .= <<"EOH";
	</ul>
EOH

	return $level;
}




################################################################################
# edit_lines_listboxes
################################################################################
sub edit_lines_listboxes
{
   my %d = %{$_[0]};
   #my $list_btns = '<div class="btn-group" role="group">';
   my $list_btns = '';
   my $params_champs_nbr = 0;
   if($d{debug})
   {
      see(\%d);
   }
   my %option_values = ();
   if($d{type} eq 'listbox')
   {
		%option_values = %{$dm_dfl{$d{field_line}}{fieldvalues}};
   }
   elsif($d{type} eq 'listboxtable' && $dm_dfl{$d{field_line}}{lbtable} ne '' && $dm_dfl{$d{field_line}}{lbkey} ne '' && $dm_dfl{$d{field_line}}{lbdisplay} ne '')
   {
       $dbh_rec = $dm_cfg{dbh} || $dbh;
	   my $where_filtrer_non_valides = '';

	   if($dm_dfl{$d{field_line}}{lbwhere} ne '')
	   {
			$dm_dfl{$d{field_line}}{lbwhere} .= " AND migcms_deleted != 'y' ";
	   }
	   else
	   {
			$dm_dfl{$d{field_line}}{lbwhere} = " migcms_deleted != 'y' ";
	   }
		$config{filtrer_non_valides} = 1;
	   if($config{filtrer_non_valides} == 1)
	   {
		   if($dm_dfl{$d{field_line}}{lbwhere} ne '')
		   {
				$where_filtrer_non_valides = ' AND ';
		   }
		   $where_filtrer_non_valides .= " id NOT IN (select id_record from migcms_valides where nom_table='$dm_dfl{$d{field_line}}{lbtable}')";
	   }
	   my $where_option_values = trim("$dm_dfl{$d{field_line}}{lbwhere} $where_filtrer_non_valides");
       my $ordby = 'valeur';
	   if($dm_dfl{$d{field_line}}{lbordby} ne '')
	   {
			$ordby = $dm_dfl{$d{field_line}}{lbordby};
	   }
	   
	   my $nom_champs_data_split='id';
	   if($dm_dfl{$d{field_line}}{data_split} ne '')
	   {
			$nom_champs_data_split = $dm_dfl{$d{field_line}}{data_split};
			$ordby = $nom_champs_data_split.','.$dm_dfl{$d{field_line}}{lbdisplay};
	   }
	   
	   my $params_champs='';
	   if($dm_dfl{$d{field_line}}{params} ne '') {
			my @params_cols = split(/\,/,$dm_dfl{$d{field_line}}{params});
			foreach my $valeur (@params_cols)
			{
				$params_champs_nbr++;
				$params_champs .= ' , '.$valeur.' as param'.$params_champs_nbr;
			}
	   }
	   my $btn_style = $dm_dfl{$d{field_line}}{btn_style};

		   
	   my @option_values = sql_lines(
	   {
		   debug=>0,
		   debug_results=>0,
		   dbh=>$dbh_rec,
		   table=>$dm_dfl{$d{field_line}}{lbtable},
		   select => "$dm_dfl{$d{field_line}}{lbkey} as cle, $dm_dfl{$d{field_line}}{lbdisplay} as valeur, $nom_champs_data_split as data_split $params_champs",
		   where => $where_option_values,
		   ordby => $ordby,
       }
	   );
	   my $i=1;
	  
       foreach my $option_value (@option_values)
       {
           my %option_value = %{$option_value};
		   my $i_opt=$i+100000000;
		   $i++;
		   
			my $params_champs_values = "";
			for($x=1;$x<=$params_champs_nbr;$x++) {
				if($params_champs_values == $x) {
					$params_champs_values .= $option_value{'param'.$x};
				}
				else {
					$params_champs_values .= $option_value{'param'.$x}.'|';
				}
			}
		  
          $option_values{$i_opt.'/'.$option_value{cle}.'/'.$option_value{data_split}.'/|'.$params_champs_values} =  $option_value{valeur};
       }
   }
   else
   {
        print "Il manque des données:<br />type:[$d{type}]lbtable:[$dm_dfl{$d{field_line}}{lbtable}]lbkey:[$dm_dfl{$d{field_line}}{lbkey}]lbdisplay[$dm_dfl{$d{field_line}}{lbdisplay}]field_line:[$d{field_line}]<br />$d{type}]<br />lbtable:[$dm_dfl{$d{field_line}}{lbtable}]<br />lbkey:[$dm_dfl{$d{field_line}}{lbkey}]<br />lbdisplay:[$dm_dfl{$d{field_line}}{lbdisplay}]"
   }

   $d{field_name} = trim($d{field_name});
   my $sel_value = $d{rec}{$d{field_name}} || $dm_dfl{$d{field_line}}{default_value} || $d{default_value};
   my $action = 'insert_'.$d{field_name};
   if($d{rec}{id} > 0)
   {
		$action = 'update_'.$d{field_name};
   }

   $special_class = 'migselect';

   $field = <<"EOH";
<select rel="$sel_value" data-defaultvalue="" id="field_$d{field_name}" $d{required_value}  $dm_dfl{$d{field_line}}{disabled} name="$d{field_name}" class="$d{class} saveme migcms_field_$action $special_class">
	<option value="">$sitetxt{veuillez_selectionner}</option>
EOH
		my $new_split = $old_split = '';
		foreach my $option_id (sort keys %option_values)
        {
            if($option_id ne '')
            {
				my $selected = '';
                my $sel_class = "btn-default";
				my $option_value = $option_id;
				my $option_value_params = '';
				my $option_display = trim($option_values{$option_id});
				if($d{translate} == 1)
				{
					$option_display = get_traduction({debug=>0,id_language=>$colg,id=>$option_display});
				}
				
				#priorité: d'abord le champs recu en GET de même nom ensuite la valeur par défaut
				# my $option_default_value = get_quoted($d{field_name}) || $dm_dfl{$d{field_line}}{default_value};
				#priorité: d'abord la valeur par défau ensuite le champs recu en GET de même nom
				my $option_default_value = $dm_dfl{$d{field_line}}{default_value} || get_quoted($d{field_name});
				my $record_value = $d{rec}{$d{field_name}};

				my ($ordby,$option_value_id,$valeur_data_split,$option_value_params) = split(/\//,$option_value);				
				my ($option_value,$option_value_params) = split(/\/\|/,$option_value);
				
				if($option_value_params ne '') {
					$option_value_params = '|'.$option_value_params;
				}
				
				if
				(
					(
						 ($record_value ne '' || $record_value != 0)
						 &&
						 (
							$option_value eq $record_value
							||
							$option_value_id eq $record_value
						 )
					)
					||
					(
						$option_default_value ne ''
						&&
						($record_value eq '' || ($record_value =~ /^[\d\.]*$/ && $record_value == 0)) #si la chaine est vide ou le nombre est 0. (string = 0)
						&&
						(
							$option_value eq $option_default_value
							||
							$option_value_id eq $option_default_value
						)
					)
				)
                {
                    $selected = ' selected="selected" ';
                    $sel_class = "btn-info ";
                }
				else
				{
					$selected = "";
					$sel_class = "btn-default";
				}
								
                $field .= <<"EOH";
	<option value="$option_value" field_params="$option_value_params" datavaleurs="[$record_value][$option_value][$option_value_id]" $selected>$option_display</option>
EOH
				if($d{list_btns})
                {
					 if($d{multiple})
                     {
						$sel_class = "btn-default";
						 if($d{debug})
						 {
							   print "------------------------------------ [$d{selected_only}]";
						 }
						 if($d{selected_only} == 1)
						 {
							$sel_class = " hide ";
						 }
                         my @sel_vals = split(/\,/,$d{rec}{$d{field_name}});
                         foreach my $sel_val (@sel_vals)
                         {
                              if($sel_val ne '' && $sel_val eq $option_value_id)
                              {
                                  $sel_class = " btn-info ";
                                  last;
                              }
                         }
						 if($sel_class ne " btn-info ")
						 {
							 my @sel_vals = split(/\,/,$option_default_value);
							 foreach my $sel_val (@sel_vals)
							 {
								  if($sel_val ne '' && $sel_val eq $option_value_id)
								  {
									  $sel_class = " btn-info ";
									  last;
								  }
							 }
						 
						 
						 }
						 
                     }
                     my $label = $option_display;
                     if($label =~ m/\*/)
                     {
                        ($dum,$label) = split(/\*/,$label);
                     }
					 my $btn_style = $dm_dfl{$d{field_line}}{btn_style};
					 if($d{from} eq 'list' && $dm_dfl{$d{field_line}}{translate} == 1)
					 {
					 	$label = get_traduction({debug=>0,id_language=>$colg,id=>$label});
					}
					
					if($valeur_data_split > 0)
					{
						$valeur_data_split = "";
					}
					$new_data_split = $valeur_data_split;
					
					#si on est en édition, si on a précisé une valeur de groupement et qu'on change de groupe
					if(($d{disabled} ne 'disabled="disabled"' || $d{split_on_disabled}  eq 'y') && $valeur_data_split ne '' && $old_data_split ne $new_data_split)
					{
						 if($old_data_split ne '')
						 {
							$list_btns .= "<br><br>";
						 }
						$valeur_data_split =~ s/^t\d*\s//g;						
						$list_btns .=<<"EOH";
							<b style="margin-top:5px;" data-selectedonly="$d{field_line}{selected_only}">$valeur_data_split :</b><br/>
EOH
						 
						 
					}
					
					if($d{disabled} eq 'disabled="disabled"')
					{
						$sel_class .=<<"EOH";
							btn-xs 
EOH
					}
					$old_data_split = $new_data_split;
					
                    $list_btns .= "<a class=\"btn $sel_class btn_change_listbox\" $btn_style $d{disabled} rel=\"field_$d{field_name}\" id=\"$option_value_id\">$label</a>";
                }
            }
        }
    $field .= <<"EOH";
</select>
EOH
	  #$list_btns .= '</div>';
	  return ($field,$list_btns);
}


################################################################################
# edit_db_ajax
################################################################################
sub edit_db_ajax
{
    # log_debug('edit_db_ajax','vide','edit_db_ajax');
	my %item = ();
    my $id = get_quoted('id');
    my %check = ();
    my $id_col = $dm_cfg{id_col} || 'id';
    my $textcontents = get_quoted('textcontents');
    my $colg = get_quoted('colg');
    if($id > 0)
    {
        %check = sql_line({debug=>0,dbh=>$dbh_data,table=>$dm_cfg{table_name},where=>"$id_col='$id'"});
    }
	if($check{migcms_lock} eq 'y')
	{
		exit;
	}
	
	
	my %item = ();
	my $custom_before_save_func = $dm_cfg{custom_before_save_func};
	if($custom_before_save_func ne '')
	{
		 %item = &$custom_before_save_func($dbh_data,$id);
	}
	else
	{
		%item = %{default_before_save($id)};
	}
	# log_debug(Dumper(\%item),"vide","returned_default_before_save");

	if($dm_cfg{validation_func} ne "")
	{
		$validation_func = $dm_cfg{validation_func};
		my $validation_msg = &$validation_func($dbh_data,\%item,$id);
		if($validation_msg ne '')
		{
			print trim($validation_msg);
			exit;
		}
	}

	#vérifie si une traduction est bien crée pour les URLS et légendes et complète les URLs et légendes
	my @migcms_linked_files = sql_lines({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='$dm_cfg{table_name}' AND token='$id'",ordby=>'ordby'});
	foreach $migcms_linked_file (@migcms_linked_files)
	{
		my %migcms_linked_file = %{$migcms_linked_file};

		#URLS et légendes
		my $text_pic_url = get_quoted('pic_url_'.$migcms_linked_file{id});
		my $text_pic_legend = get_quoted('pic_legend_'.$migcms_linked_file{id});
		set_traduction({id_language=>$colg,traduction=>$text_pic_url,id_traduction=>$migcms_linked_file{id_textid_url},table_record=>'migcms_linked_files',col_record=>'id_textid_url',id_record=>$migcms_linked_file{id}});
		set_traduction({id_language=>$colg,traduction=>$text_pic_legend,id_traduction=>$migcms_linked_file{id_textid_legend},table_record=>'migcms_linked_files',col_record=>'id_textid_legend',id_record=>$migcms_linked_file{id}});
		
		#Nouvelle fenêtre
		my $target_blank = get_quoted('blank_'.$migcms_linked_file{id});
		if($target_blank ne 'y')
		{
			$target_blank = 'n';
		}
		$stmt = "UPDATE migcms_linked_files SET blank='$target_blank' WHERE id = '$migcms_linked_file{id}' ";
		execstmt($dbh_data,$stmt);
	}	
		
    foreach my $field_line (sort keys %dm_dfl)
    {
        my ($ordby,$field_name) = split(/\//,$field_line);
        my $type =  $dm_dfl{$field_line}{fieldtype};
        my $data_type =  $dm_dfl{$field_line}{datatype} || $dm_dfl{$field_line}{data_type};
		
		
		if($dm_dfl{$field_line}{frontend_only} eq 'y')
		{
			next;
		}		
		if($data_type eq 'password')
		{
			next;
		}
		
		my $disable_add = $dm_dfl{$field_line}{disable_add};
		my $disable_update = $dm_dfl{$field_line}{disable_update};
		if($disable_update && $id > 0)
		{
			# log_debug("$field_name deleted!: [$disable_update] $id","","returned_default_before_save");
			delete $item{$field_name};
			next;
		}
		
		
		
		if(
        $type eq 'text' ||
        $type eq 'textarea' ||
        $type eq 'textarea_editor' ||
        $type eq 'listbox' ||
        $type eq 'listboxtable'
        )
        {
			if($data_type eq 'date')
            {
				$item{$field_name} = to_sql_date($item{$field_name},'date_only');
            }
            elsif($data_type eq 'time')
            {
                $item{$field_name} = to_sql_time($item{$field_name});
            }
			elsif($data_type eq 'datetime')
            {
                my ($human_date,$human_time) = split(/\s/,$item{$field_name});
				$item{$field_name} = to_sql_date($human_date,'date_only').' '.to_sql_time($human_time).':00';
            }
			my ($test_ordby,$test_value) = split(/\//,$item{$field_name});
			$test_ordby = int($test_ordby);
			$item{$field_name} = $item{$field_name};
			if(($type eq 'listbox' || $type eq 'listboxtable') && $test_ordby > 0 && trim($test_value) ne '')
			{
				$item{$field_name} = $test_value;
			}
        }
        elsif
		(
			$type eq 'text_id' ||
			$type eq 'textarea_id' ||
			$type eq 'textarea_id_editor'
        )
        {
            my $content = $item{$field_name}; 
			if($config{save_all_in_lowercase})
			{
				$content = lc($content);
			}
            if($check{$field_name} > 0)
            {
               $item{$field_name} =  update_text($dbh,$check{$field_name},$content,$colg,'',$textcontents,0);
            }
            else
            {
                $item{$field_name} = insert_text($dbh,$content,$colg,$textcontents,0);
            }
        }
        elsif
		(
			$type eq 'checkbox'
        )
        {
			if($item{$field_name} eq '')
			{
				$item{$field_name} = 'n';
			}
        }
		elsif
		(
			$type eq 'file'
        )
        {
			$item{$field_name} = migcms_upload($field_name);
        }
    }
	if($config{save_all_in_lowercase})
	{
		foreach $cle (keys %item)
		{
			$item{$cle} = lc($item{$cle});
		}
	}
	if($config{remove_all_accents})
	{
		foreach $cle (keys %item)
		{
			$item{$cle} = remove_accents_from($item{$cle});
		}
	}

    #UPDATE OR INSERT***********************************************************
    if($id > 0)
    {
		add_history({action=>'modifie',page=>$dm_cfg{table_name},id=>"$id"});
		# $item{migcms_moment_last_edit} = 'NOW()';
		# $item{migcms_id_user_last_edit} = $user{id};
		
	
		if($dm_cfg{do_no_empty_migcms_last_published_file} ne 'y')
		{
			$item{migcms_last_published_file} = '';
		}
		# my $id_record = sql_set_data({debug=>0,debug_results=>0,dbh=>$dbh_data,table=>$dm_cfg{table_name},data=>\%item, where=>"$id_col='$id'"});
		# %item = %{quoteh(\%item)};	
		# log_debug(Dumper(\%item),"vide","dm_update");
		$id_record = updateh_db($dbh_data,$dm_cfg{table_name},\%item,$id_col,$id,"$id_col='$id'");
		
		clean_migcms_cache();
		print $id_record;
		#si autocreation: supprimer ligne valide (attente)
		if($dm_cfg{autocreation} == 1)
		{
			#supprime la ligne valides du record
			$stmt = "delete FROM  migcms_valides WHERE id_record = '$id_record' AND nom_table='$dm_cfg{table_name}'";
			# log_debug($stmt,'','debugvalides');
			execstmt($dbh_data,$stmt);
			#nettoie les anciennes lignes valides
			my @migcms_valides = sql_lines({table=>'migcms_valides',where=>"moment < CURRENT_DATE"});
			foreach $migcms_valides(@migcms_valides)
			{
				my %migcms_valides = %{$migcms_valides};
				if($migcms_valides{nom_table} ne '' && $migcms_valides{id_record} > 0)
				{
					#supprime le record en question
					$stmt = "delete FROM  $migcms_valides{nom_table} WHERE id = '$migcms_valides{id_record}'";
					# log_debug($stmt,'','debugvalides');
					execstmt($dbh_data,$stmt);
					#supprime la ligne valides
					$stmt = "delete FROM  migcms_valides WHERE nom_table = '$migcms_valides{nom_table}' AND id_record='$migcms_valides{id_record}'";
					# log_debug($stmt,'','debugvalides');
					execstmt($dbh_data,$stmt);
				}
			}
		}
        if ($dm_cfg{after_mod_ref} ne "")
        {
            $fct = $dm_cfg{after_mod_ref};
            &$fct($dbh_data,$id,$colg);
        }
		if($dm_permissions{sort}  == 1 && $dm_cfg{tree}  == 1)
        {
			edit_db_sort_tree_recurse(0);
        }
		elsif($dm_permissions{sort} == 1)
		{
			edit_db_refresh_ordby();
		}
    }
    else
    {
        if ($dm_cfg{wherep_ordby} eq "") { $dm_cfg{wherep_ordby}=$dm_cfg{wherep};    }
        if ($dm_cfg{wherep_ordby} ne "") { $dm_cfg{wherep_ordby} = "WHERE $dm_cfg{wherep_ordby}";}
        if( $dm_permissions{sort})
        {
              if ($dm_cfg{ordby_desc} == 1)
              {
                  $stmt = "UPDATE $dm_cfg{table_name} SET ordby = ordby + 1 $dm_cfg{wherep_ordby}";
                  $cursor = $dbh_data->prepare($stmt);
                  $cursor->execute;
                  $item{ordby} = 1;
              }
              else
              {
                  $stmt = "SELECT MAX(ordby)+1 FROM $dm_cfg{table_name} $dm_cfg{wherep_ordby}";
                  $cursor = $dbh_data->prepare($stmt);
                  $cursor->execute;
                  my ($ordbymax) = $cursor->fetchrow_array;
                  $cursor->finish;
                  if ($ordbymax eq "") { $ordbymax = 1;}
                  $item{ordby} = $ordbymax;
              }
        }
        if ($dm_cfg{vis_opt}) { $item{visible} = 'y'; }
        if ($dm_cfg{visible}) { $item{visible} = 'y'; }
		# log_debug(Dumper(\%item),"vide","dm_insert");
        my $new_id = inserth_db($dbh_data,$dm_cfg{table_name},\%item);
		clean_migcms_cache();
		# log_debug('id ajoute'.$new_id,'','debugvalides');
		
		#log sys
		if($config{use_sys} eq 'y')
		{
			my %sys =
			(
				nom_table => $dm_cfg{table_name},
				id_table => $new_id,
				id_user => $user{id},
				moment => 'NOW()'
			);
			inserth_db($dbh_data,'migcms_sys',\%sys);
		}
		#autocreation
		if($dm_cfg{autocreation} == 1)
		{
			# log_debug('ajout valide avec '.$new_id,'','debugvalides');
			my %migcms_valide =
			(
				nom_table => $dm_cfg{table_name},
				id_record => $new_id,
				moment => 'NOW()'
			);
			my $id_valide_ajoute = inserth_db($dbh_data,'migcms_valides',\%migcms_valide);
			# log_debug('valide ajoute: '.$id_valide_ajoute,'','debugvalides');
			
			$stmt = "delete FROM $dm_cfg{table_name} WHERE id IN (select id_record from migcms_valides WHERE nom_table='$dm_cfg{table_name}' AND moment < DATE_SUB(NOW(), INTERVAL 2 DAY) )";
			# log_debug($stmt,'','debugvalides');
			execstmt($dbh_data,$stmt);
		}
		print $new_id;
		add_history({action=>'insert',page=>$dm_cfg{table_name},id=>"$new_id"});
        if ($dm_cfg{after_add_ref} ne "")
        {
            $fct = $dm_cfg{after_add_ref};
            &$fct($dbh_data,$new_id,$colg);
        }
		if($dm_permissions{sort} && $dm_cfg{tree})
        {
            edit_db_sort_tree_recurse(0);
        }
		elsif($dm_permissions{sort})
		{
			edit_db_refresh_ordby();
		}
    }
	
	if($dm_cfg{file_prefixe} ne '')
	{
		$stmt = "UPDATE $dm_cfg{table_name} SET migcms_id = CONCAT('$dm_cfg{file_prefixe}',LPAD( id, 7, '0' ))  WHERE migcms_id = ''";
		execstmt($dbh_data,$stmt);
	}
	
	
	
    exit;
}
sub edit_db_sort_tree_recurse
{
   my $id_father = $_[0];
   my $new_ordby = 1;
   my $where = " 1 ";
   if($dm_cfg{tree})
   {
        $where .= ' AND id_father = '.$id_father.' ';
   }
   if($dm_cfg{wherel} ne '')
   {
        $where .= ' AND '.$dm_cfg{wherel};
   }
   
	$where = " ($where) AND id NOT IN (select id_record from migcms_valides WHERE nom_table='$dm_cfg{table_name}')";
   

   
   my @table = sql_lines({debug=>0,debug_results=>0,table=>$dm_cfg{table_name},select=>"id,ordby",where=>$where,ordby=>"ordby"});
   foreach $rec (@table)
   {
      my %rec = %{$rec};
      $stmt = "UPDATE $dm_cfg{table_name} SET ordby = '$new_ordby' WHERE id ='$rec{id}'";
      execstmt($dbh_data,$stmt);
      edit_db_sort_tree_recurse($rec{id});
      $new_ordby++;
   }
   clean_migcms_cache();
}
sub edit_db_sort
{
   my $where = " 1 ";
   if($dm_cfg{wherel} ne '')
   {
        $where .= ' AND '.$dm_cfg{wherel};
   }

   $where = " ($where) AND id NOT IN (select id_record from migcms_valides WHERE nom_table='$dm_cfg{table_name}')";

   
   my $new_ordby = 1;
   my @table = sql_lines({debug=>0,debug_results=>01,dbh=>$dbh,table=>$dm_cfg{table_name},select=>"id,ordby",where=>$where,ordby=>"ordby"});
   foreach $rec (@table)
   {
      my %rec = %{$rec};
      $stmt = "UPDATE $dm_cfg{table_name} SET ordby = '$new_ordby' WHERE id ='$rec{id}'";
      execstmt($dbh_data,$stmt);
      $new_ordby++;
   }
   add_history({action=>'trie',page=>$dm_cfg{table_name},id=>"$rec{id}"});
   edit_db_refresh_ordby();
   clean_migcms_cache();
   exit;
}
sub edit_db_refresh_ordby
{
   my $new_ordby = 1;
   my $table = $_[0] || $dm_cfg{table_name};
   my $where = $_[1] || $dm_cfg{wherel};

   my $ordby = 'ordby, id desc';
   if($dm_cfg{retri_ordby} ne '')
   {
		$ordby = $dm_cfg{retri_ordby};
   }

   if($where ne '')
   {
	  $where = " ($where) AND id NOT IN (select id_record from migcms_valides WHERE nom_table='$table')";
   }
   else
   {
	  $where = " id NOT IN (select id_record from migcms_valides WHERE nom_table='$table')";
   }

   my @table = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh,table=>$table,select=>"id,ordby",ordby=>$ordby,where=>"$where"});

   foreach $rec (@table)
   {
      my %rec = %{$rec};
      $stmt = "UPDATE $table SET ordby = '$new_ordby' WHERE id ='$rec{id}'";
	  execstmt($dbh_data,$stmt);
      $new_ordby++;
   }
}
################################################################################
# display
################################################################################
sub display
{
    my $content =  trim($_[0]) || $migc_output{content};
    my $title = trim($_[1]) || $migc_output{title};
    
	my $activ_nav = get_quoted('activ_nav');
	
	my $menu = display_get_menu();
    $content .= <<"EOH";
<input type="hidden" class="colg" name="colg" value = "$colg" />
<input type="hidden" class="mode" name="mode" value = "list" />
<input type="hidden" class="activ_nav" name="activ_nav" value="$activ_nav" />


EOH
    my $page = display_set_canvas({content=>$content,menu=>$menu, title=>$title});

	
	
	my $nettoyage = '<MIGC.*_HERE>';
	$page =~ s/$nettoyage//g;

	if($config{migcms_cache} eq 'y' && $dm_cfg{use_migcms_cache} == 1)
	{
		# log_debug($page,'vide','../cache/admin/'.$dm_cfg{table_name}.'_'.$user{id},'no_date_not_cr');
	}
	
	my $debug_cache = get_quoted('debug_cache') || 'n';
	if($debug_cache eq 'y')
	{
		log_debug('dm_cache','','dm_cache');
		
		#script
		my $path = "../cache/admin/".get_quoted('sel');
		unless (-d $path) {mkdir($path.'/') or die ("cannot create ".$path.'/'.": $!");}
		
		#user
		$path .= '/'.$user{id};
		unless (-d $path) {mkdir($path.'/') or die ("cannot create ".$path.'/'.": $!");}
		
		#cache file
		my $out_file = $path.'/page.html';
		open OUTPAGE, ">$out_file" or die "cannot open $out_file";
		print OUTPAGE $page;
		close (OUTPAGE);
		
		
		#si on ne précise pas la page: page 1
		# if($REQUEST_URI !~ /\d$/)
		# {
			# log_debug('URL pas terminée par un nombre','','data_cache');
			# $REQUEST_URI.='/1';
		# }
		# my $out_file = "../cache/site//data/$sw$REQUEST_URI".'.html';		
		
		# log_debug('out_file:'.$out_file,'','data_cache');
		# log_debug('page_content:'.$page_content,'','data_cache');
		
		# if($out_file !~ /\-k/)
		# {
			# open OUTPAGE, ">$out_file" or die "cannot open $out_file";
			# print OUTPAGE $page_content;
			# close (OUTPAGE);
		# }
	}
	
	print $page;
    exit;
}


################################################################################
# display_get_menu
################################################################################
sub display_get_menu
{
	my $sel = get_quoted('sel');
	my $menu_sw = get_quoted('menu_sw');
	if($menu_sw > 0)
	{
		$sel = $menu_sw;
	}
	
	my $menu = '';
	if(!$user{id}>0)
	{
		exit;
	}
	
	my %migcms_role = sql_line({debug=>$debug,debug_results=>$debug,table=>"migcms_roles",where=>"id='$user{id_role}' and visible='y' and token != ''"});
	$menu = recurse_display_get_menu({sel=>$sel,id_role=>$migcms_role{id},level=>0,id_father=>0});
	
	return $menu;
}

sub recurse_display_get_menu
{
	my %d = %{$_[0]};
	
	
	my $level = $d{level} + 1;
	if($level > 5)
	{
		return '';
	}
	my $where = "s.id = per.id_script  AND s.cacher_menu != 'y' AND s.visible = 'y' AND s.migcms_deleted = 'n' AND s.id_father = $d{id_father}";
	if($d{id_role} != 1)
	{
		$where .= " AND view = 'y' AND per.id_role='$d{id_role}'"; 
	}
	else
	{
		$where .= " AND per.id_role='2'"; #role "disponibilites"  uniquement pour le system
	}
	
	my @scripts = sql_lines({debug=>0,debug_resuts=>0,select=>"s.*",table=>'scripts s, migcms_roles_scripts_permissions per',where=>$where,ordby=>'s.ordby'});
	if($#scripts == -1)
	{
		return '';
	}
	
	my %ul_classes_for_level =
	(
		'1'=>'nav nav-pills nav-stacked custom-nav',
		'2'=>'sub-menu-list',
	);
	my %li_classes_for_level =
	(
		'1'=>'menu-list submenu menu-list-js',
		'2'=>'',
	);
	my %span_classes_for_level_open =
	(
		'1'=>'<span>',
	);
	my %span_classes_for_level_close =
	(
		'1'=>'</span>',
	);

	my $ul_class = $ul_classes_for_level{$level};
	
	my $menu = '';
	
	if($level == 3 && $d{check_children_menu} > 0)
	{
		my %parent = sql_line({debug=>0,debug_results=>0,table=>'scripts',where=>"id='$d{id_father}'"});
		my $traduction = get_traduction({debug=>0,id_language=>$user{id_language},id=>$parent{id_textid_name}});
		$menu .= <<"EOH";
		<ul>
			<li><button type="button"><i class="fa fa-arrow-left"></i>$traduction</button>
EOH
	}
	
	$menu .= <<"EOH";
		<!-- NIVEAU $level -->
		<ul class="$ul_class">
EOH
 
	my $is_open = 'nav-active open';
	
    foreach $script (@scripts)
    {
			my %script = %{$script};
			my $li_class = $li_classes_for_level{$level};

			#si le menu a des enfants et à partir du niveau 2, ajouter une classe has-sub-menu-list
			my %check_children_menu = sql_line({debug=>0,debug_results=>0,table=>'scripts',where=>"cacher_menu != 'y' AND visible = 'y' AND migcms_deleted = 'n' AND id_father='$script{id}'"});
			if($level >= 2 && $check_children_menu{id} > 0)
			{
				$li_class .= " has-sub-menu-list";
			}
			elsif($level == 1 && $script{depli_menu} eq 'y') {
				$li_class = $li_class." nav-active";
			}
			elsif($level == 1 && !($check_children_menu{id} > 0))
			{
				$li_class = "";
			}
			
			my $traduction = get_traduction({debug=>0,id_language=>$user{id_language},id=>$script{id_textid_name}});
			if($traduction eq '')
			{
				$traduction = $script{name};
			}
			my $url = $base_script.trim($script{url})."&sel=$script{id}";
			
			my $active = '';
			if($d{sel} == $script{id} || $script{id_children} =~ /,$script{id},/)
			{
				$active = 'active';
			}
			
		    my $class_traduction = clean_url($traduction.$script{url});
						
			$menu .= <<"EOH";
				<li class="$li_class $active">
					<a href="$url" class="$active level$level $class_traduction"><i class="$script{icon}"></i> <em>$script{short}</em>  $span_classes_for_level_open{$level} $traduction $span_classes_for_level_close{$level} </a>
EOH

			$menu .= recurse_display_get_menu({sel=>$d{sel},id_role=>$d{id_role},level=>$level,id_father=>$script{id},check_children_menu=>$check_children_menu{id}});		
	
	$menu .= <<"EOH";
				</li>
EOH
	}
	
$menu .= <<"EOH";
		</ul><!-- FIN NIVEAU $level -->
EOH

	if($level == 3 && $d{check_children_menu} > 0)
	{
		$menu .= <<"EOH";
				</li>
		</ul><!-- FIN ul2 NIVEAU $level --> 
EOH
	}

	return $menu;
}

################################################################################
# display_set_canvas
################################################################################
sub display_set_canvas
{
    my %d = %{$_[0]};
    my $url = $config{admin_first_page_url} || "adm_dashboard.pl?";
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year+=1900;
    my $list_languages = "";
    my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible='y'"});
    foreach $language (@languages)
    {
        my %language = %{$language};
        $language{name} = uc($language{name});
        $list_languages .=<< "EOH";
<li class="btn" ><a data-original-title="$migctrad{see_content_in} $language{name}" data-placement="bottom" href="$dm_cfg{self}&colg=$language{id}"><span class="text">$language{name}</span></a></li>
EOH
    }
	
	# $config{baseurl} = $config{fullurl};
	
	my $tok = create_token(50);
    my $base = $base_script;
	my $publish_bar = '';
	if($config{cms} eq 'y')
	{
		$publish_bar .= get_migcms_publish_bar();
	}
	my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
	my %logo_big = sql_line({table=>'migcms_linked_files',where=>"table_name='migcms_setup' and token='$migcms_setup{id}' AND table_field='logos'",limit=>'0,1',ordby=>'ordby'});
	my %logo_small = sql_line({table=>'migcms_linked_files',where=>"table_name='migcms_setup' and token='$migcms_setup{id}' AND table_field='logos'",limit=>'1,1',ordby=>'ordby'});
	my $url_logo_big = "$config{baseurl}/mig_skin/img/logo.svg";
	my $url_logo_small = "$config{baseurl}/mig_skin/img/logo-small.svg";
	if($logo_big{full} ne '' && $logo_big{file_dir} ne '')
	{
		$url_logo_big = $logo_big{file_dir}.'/'.$logo_big{full}.$logo_big{ext};
	}
	if($logo_small{full} ne '' && $logo_small{file_dir} ne '')
	{
		$url_logo_small = $logo_small{file_dir}.'/'.$logo_small{full}.$logo_small{ext};
	}
	if($migcms_setup{site_name} eq '')
	{
		$migcms_setup{site_name} = 'Bugiweb';
	}

	my $msg_securite = '';
	if($securite_setup{disable_security} eq 'y')
    {
		$msg_securite = <<"EOH";
	<div class="alert alert-warning alert-dismissible" role="alert">
  <button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button>
  <strong>$migctrad{desactivated_security}.</strong> $migctrad{modules_access_desactivated}
</div>
EOH
	}

	$d{content} = $msg_securite.$d{content};

	
	my $js_google_map = '';
	my $html_google_map = '';
	if($dm_cfg{show_google_map} eq 'y')
	{
		$js_google_map = <<"EOH";
			<!--&libraries=geometry,places-->
			<script src="https://maps.google.com/maps/api/js?sensor=true"></script>
			<script src="../mig_skin/js/infobox.js"></script>
EOH

		$html_google_map = <<"EOH";
			<div id="googlemap" class="ici"></div>
			<div id="liste-points" class="hide">
			</div>
EOH
	}
	
	if(1 && $dm_cfg{include_maps} == 1)
	{
		$js_google_map = <<"EOH";
	<script async defer src="https://maps.googleapis.com/maps/api/js?key=AIzaSyDrMTzDM5WDr1nqKW3PoF0QQAlQg4mpKBg&sensor=true&region=be&async=2&libraries=geometry,places"></script>	
EOH
	
	}
	
	
	my $css = <<"EOH";
		<link href="$config{baseurl}/mig_skin/css/font-awesome.min.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/css/sweet-alert.css" rel="stylesheet">
		<link href="$config{baseurl}/html/css/style.css" rel="stylesheet">
		<link href="$config{baseurl}/html/css/style-responsive.css" rel="stylesheet">
		<link href="$config{baseurl}/html/css/table-responsive.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/css/migc4.css" rel="stylesheet">
		<link rel="stylesheet" href="$config{baseurl}/mig_skin/js/themes/default/style.min.css" />
		<link href="$config{baseurl}/mig_skin/css/intlTelInput.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/css/bootstrap-progressbar-3.3.0.min.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/css/daterangepicker-bs3.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/css/fv.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/css/bootstrap-tagsinput.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/css/jquery.resizableColumns.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/css/timepicker.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/css/datepicker.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/css/datepicker3.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/css/bootstrap-tagsinput.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/css/dropzone.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/css/animate.min.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/css/bootstrap-select.min.css" rel="stylesheet">
		<link href="$config{baseurl}/mig_skin/tinymce/skins/lightgray/skin.min.css" rel="stylesheet">	
EOH

	if(-e $config{directory_path}.'/mig_skin/css/migcms_all_min.css')
	{
		 $css = <<"EOH";
				<link href="$config{baseurl}/html/css/style.css" rel="stylesheet">
				<link href="$config{baseurl}/html/css/style-responsive.css" rel="stylesheet">
				<link href="$config{baseurl}/html/css/table-responsive.css" rel="stylesheet">
				<link href="$config{baseurl}/mig_skin/tinymce/skins/lightgray/skin.min.css" rel="stylesheet">	

				<link href="$config{baseurl}/mig_skin/css/migcms_all_min.css" rel="stylesheet">
EOH
	}
	
	my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
	my $google_clientid = $migcms_setup{google_clientid} || "759361789094-8bb1m8593ms24pcasofq9adfgd2784c7.apps.googleusercontent.com";

	my $js = <<"HTML";
		<script src="$config{baseurl}/html/js/jquery-ui-1.10.3.min.js"></script>
		<script src="$config{baseurl}/mig_skin/js/jquery.dotdotdot.min.js"></script>
		<script src="$config{baseurl}/mig_skin/js/typeahead.js"></script>
		<script src="$config{baseurl}/mig_skin/js/validatr.min.js"></script>
		<script src="$config{baseurl}/mig_skin/js/dropzone.js"></script>
		<script src="$config{baseurl}/mig_skin/js/intlTelInput_countries.js"></script>
		<script src="$config{baseurl}/mig_skin/js/intlTelInput.js"></script>
		<script src="$config{baseurl}/mig_skin/js/moment.min.js"></script>
		<script src="$config{baseurl}/mig_skin/js/daterangepicker.js"></script>
		<script src="$config{baseurl}/mig_skin/js/validator.js"></script>
		<script src="$config{baseurl}/mig_skin/js/multifield.js"></script>
		<script src="$config{baseurl}/mig_skin/js/typeahead.bundle.js"></script>
		<script src="$config{baseurl}/mig_skin/js/bootstrap-tagsinput.min.js"></script>
		<script src="$config{baseurl}/mig_skin/js/sweet-alert.min.js"></script>
		<script src="$config{baseurl}/mig_skin/js/migc4.js"></script>
		<script src="$config{baseurl}/html/js/jquery.nicescroll.js"></script>
		<script src="$config{baseurl}/html/js/jquery-migrate-1.2.1.min.js"></script>
		<script src="$config{baseurl}/html/js/bootstrap.min.js"></script>
		<script src="$config{baseurl}/mig_skin/js/bootstrap-progressbar.min.js"></script>
		<script src="$config{baseurl}/html/js/modernizr.min.js"></script>
		<script src="$config{baseurl}/mig_skin/js/jquery.bootstrap-growl.js"></script>
		<script src="$config{baseurl}/mig_skin/js/jquery.autosize.min.js"></script>
		<script src="$config{baseurl}/mig_skin/tinymce/tinymce.min.js" ></script>
		<script src="$config{baseurl}/mig_skin/tinymce/jquery.tinymce.min.js" ></script>
		<script src="$config{baseurl}/mig_skin/tinymce/langs/fr_FR.js" ></script>
		<script src="$config{baseurl}/mig_skin/js/bootstrap-timepicker.js"></script>
		<script src="$config{baseurl}/mig_skin/js/jquery.maskedinput.min.js"></script>
		<script src="$config{baseurl}/mig_skin/js/jstree.min.js"></script>
		<script src="$config{baseurl}/mig_skin/js/bootstrap-datepicker.js"></script>
		<script src="$config{baseurl}/mig_skin/js/locales/bootstrap-datepicker.fr.js"></script>
		<script src="$config{baseurl}/mig_skin/js/jquery.cookie.js"></script>
		<script src="$config{baseurl}/mig_skin/js/pwstrength-bootstrap-1.2.8.min.js"></script>
		<script src="$config{baseurl}/mig_skin/js/bootstrap-add-clear.min.js"></script>
		<script src="$config{baseurl}/mig_skin/js/bootstrap-select.min.js"></script>
		<script src="$config{baseurl}/mig_skin/js/defaults-fr_FR.min.js"></script>
		<script src="$config{baseurl}/html/js/scripts.js"></script>




HTML

	if(-e $config{directory_path}.'/mig_skin/js/migcms_all.js')
	{
		 $js = <<"EOH";
			<script src="$config{baseurl}/mig_skin/js/migcms_all.js"></script>	

			<script src="$config{baseurl}/mig_skin/tinymce/tinymce.min.js" ></script>
			<script src="$config{baseurl}/mig_skin/tinymce/jquery.tinymce.min.js" ></script>
			<script src="$config{baseurl}/mig_skin/tinymce/langs/fr_FR.js" ></script>	
			
			$config{head_bottom}
EOH
	}
	else
	{
		my @files = sql_lines({select=>"filename",debug=>0,debug_results=>0,table=>'migcms_page_js',ordby=>'ordby',where=>"visible='y'"});
		$js = "";
		foreach $file (@files)
		{
			my %file = %{$file};
			$js .= <<"EOH";
			<script src="$config{baseurl}/$file{filename}"></script>
EOH
		}
	}
	
	my $list_tasks = '';
	
				

	
	my @migcms_tasks_pendings = sql_lines({table=>'migcms_tasks_pending',where=>"task_progression < 100 OR task_begin >= DATE_SUB(NOW(), INTERVAL 1 DAY)",ordby=>"id desc",limit=>"0,10"});
	my $nb_pending = $#migcms_tasks_pendings+1;
	my $nb_pending_label = '';
	my $phrase = 'Vous n\'avez pas de traitement en cours';
	if($nb_pending > 0)
	{
		$nb_pending_label = '<span class="badge" STYLETACHESCSS>'.$nb_pending.'</span>';
		$phrase = 'Vous avez '.$nb_pending.' traitement(s) en cours';
	}

	$list_tasks = <<"EOH";
	
	<li>
						<a href="#" class="btn btn-default dropdown-toggle info-number" data-toggle="dropdown">
							<i class="fa fa-tasks"></i>
							$nb_pending_label
						</a>
						<div class="dropdown-menu dropdown-menu-head pull-right">
							<h5 class="title">$phrase</h5>
							<ul class="dropdown-list user-list">
EOH
	
	my $all_finished = 1;
	
	foreach $migcms_task_pending (@migcms_tasks_pendings)
	{
		my %migcms_task_pending = %{$migcms_task_pending};
		
		#ajouter couleurs (info,warning,danger,success ou aucun)
		my $progress_bar_class = 'progress-bar-info';
		my $task_link = '#';
		
		if($migcms_task_pending{task_link} ne '')
		{
			$task_link = $migcms_task_pending{task_link};
		}
		
		if($migcms_task_pending{task_progression} < 100)
		{
			$all_finished = 0;
		}
		
		$list_tasks .= <<"EOH";
		<li class="new">
			<a href="$task_link">
				<div class="task-info">
					<div>$migcms_task_pending{task_name}</div>
				</div>
				<div class="progress progress-striped">
					<div style="width: $migcms_task_pending{task_progression}%" aria-valuemax="100" aria-valuemin="0" aria-valuenow="$migcms_task_pending{task_progression}" role="progressbar" class="progress-bar $progress_bar_class">
						<span class="">$migcms_task_pending{task_progression}%</span>
					</div>
				</div>
			</a>
		</li>
EOH
	}
	
	if($all_finished == 1)
	{
		$list_tasks =~ s/STYLETACHESCSS/ style\=\"background\:\#65CEA7\!important" /g;
	}
	else
	{
		$list_tasks =~ s/STYLETACHESCSS//g;
	}
	
	
	
	$list_tasks .= <<"EOH";
					<li class="new hide"><a href="">Voir tous les traitements...</a></li>
				</ul>
			</div>
		</li>
EOH
	
	
    $page = <<"HTML";
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
	<meta name="robots" content="noindex, nofollow">
    <meta name="author" content="Bugiweb.com">

	<link rel="apple-touch-icon" sizes="57x57" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-57x57.png">
	<link rel="apple-touch-icon" sizes="60x60" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-60x60.png">
	<link rel="apple-touch-icon" sizes="72x72" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-72x72.png">
	<link rel="apple-touch-icon" sizes="76x76" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-76x76.png">
	<link rel="apple-touch-icon" sizes="114x114" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-114x114.png">
	<link rel="apple-touch-icon" sizes="120x120" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-120x120.png">
	<link rel="apple-touch-icon" sizes="144x144" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-144x144.png">
	<link rel="apple-touch-icon" sizes="152x152" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-152x152.png">
	<link rel="apple-touch-icon" sizes="180x180" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-180x180.png">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-32x32.png" sizes="32x32">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-194x194.png" sizes="194x194">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-96x96.png" sizes="96x96">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/android-chrome-192x192.png" sizes="192x192">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-16x16.png" sizes="16x16">
	<link rel="manifest" href="$config{baseurl}/mig_skin/ico/manifest.json">
	<meta name="msapplication-TileColor" content="#ffffff">
	<meta name="msapplication-TileImage" content="$config{baseurl}/mig_skin/ico/mstile-144x144.png">
	<meta name="theme-color" content="#ffffff">
	<meta name="application-name" content="$migcms_setup{site_name}">
	<meta name="SKYPE_TOOLBAR" content="SKYPE_TOOLBAR_PARSER_COMPATIBLE" />
	<meta name="format-detection" content="telephone=no">
	<title>$migcms_setup{site_name} - $dm_cfg{page_title}</title>
	
	$css
	
	<!--<link href="$config{baseurl}/mig_skin/css/mig.css" rel="stylesheet" />-->
    <!--[if lt IE 9]><script href="$config{baseurl}/html/js/html5shiv.js"></script><script href="$config{baseurl}/html/js/respond.min.js"></script><![endif]-->
		
	<!--
	<script src="$config{baseurl}/html/js/jquery-1.10.2.min.js"></script>				
	-->
	<script src="$config{fullurl}/mig_skin/js/jquery-3.0.0.min.js"></script>
	<script src="$config{fullurl}/mig_skin/js/jquery-migrate-3.0.0.min.js"></script>
	

	$dm_cfg{head}
	
	<style>
	.cms_mig_cell_id
	{
		width:92px;
	}
	.red
	{
		$config{dm_css_red}
	}
	.blue
	{
		$config{dm_css_blue}
	}
	.green
	{
		$config{dm_css_green}
	}
	.list_actions_10, .header_list_actions_10
	{
		width: 495px !important;
	}
	.list_actions_11, .header_list_actions_11
	{
		width: 555px !important;
	}
	.list_actions_12, .header_list_actions_12
	{
		width: 595px !important;
	}
	#googlemap
	{
	height: 415px;
	}
	.infoBox{text-align:center;width:270px}.infoBox h1{font-size:23px;color:#fff;font-weight:300;margin:25px 0}.infoBox h2{font-size:16px;color:#fff;font-weight:300;padding-left:40px;padding-right:40px}.infoBox .phone{display:inline-block;color:#fff;font-size:16px;font-weight:300;background:url(../mig_skin/img/phone-blanc.png) no-repeat left center;padding-left:25px;margin-top:10px}
	</style>
	$js_google_map
</head>
<body class="sticky-header">


<div class="se-pre-con"></div>
$dm_cfg{body}
<section>
    <!-- left side start-->
    <div class="left-side sticky-left-side">
        <div class="left-side-inner">
			<!--logo and iconic logo start-->
			<div class="logo"><a href="$config{baseurl}/cgi-bin/$migcms_setup{admin_first_page_url}" data-original-title="$migctrad{backtohome}" data-placement="bottom"><img src="$url_logo_big" /></a></div>
			<div class="logo-icon text-center"><a href="$config{baseurl}/cgi-bin/$migcms_setup{admin_first_page_url}" data-original-title="$migctrad{backtohome}" data-placement="bottom"><img src="$url_logo_small" /></a></div>
            <!-- visible to small devices only -->
            <div class="visible-xs hidden-sm hidden-md hidden-lg">
                <div class="media logged-user">
                    <div class="media-body">
                        <h4>$user{firstname} $user{lastname}</h4>
                    </div>
					<ul class="nav nav-pills nav-stacked custom-nav">
						<li><a href="$config{baseurl}/cgi-bin/adm_migcms_user_data.pl"><i class="fa fa-user"></i> $migctrad{your_profile}</a></li>
                        <li><a id="logoutlink" href="$config{baseurl}/cgi-bin/fwauth.pl?sw=logout&tok=$tok"><i class="fa fa-sign-out"></i> $migctrad{lock_profile}</a></li>
                        <li><a href="$config{baseurl}/cgi-bin/fwauth.pl?sw=logout&all=y&tok=$tok"><i class="fa fa-sign-out"></i> $migctrad{disconnect_profile} </a></li>
					</ul>
                </div>
            </div>
            <!--sidebar nav start-->
           $d{menu}
        </div>
    </div>
    <!-- main content start-->
    <div class="main-content" >
        <!-- header section start-->
        <div class="header-section">
			<!--toggle button start-->
			<a class="toggle-btn"><i class="fa fa-bars"></i></a>
			<!--search start-->
			<!--
			<form class="searchform" action="$config{baseurl}/cgi-bin/adm_dashboard.pl?sel=106" method="post">
				<input type="text" class="form-control" name="keyword" placeholder="$migctrad{search_here}" />
			</form>
			-->
			$language_menu
			<!--notification menu start -->
			$publish_bar
			<div class="menu-right">
				<ul class="notification-menu">
					$list_tasks
					<!--
					<li>
						<a href="#" class="btn btn-default dropdown-toggle info-number" data-toggle="dropdown">
							<i class="fa fa-tasks"></i>
							<span class="badge">8</span>
						</a>
						<div class="dropdown-menu dropdown-menu-head pull-right">
							<h5 class="title">You have 8 pending task</h5>
							<ul class="dropdown-list user-list">
								<li class="new">
									<a href="#">
										<div class="task-info">
											<div>Database update</div>
										</div>
										<div class="progress progress-striped">
											<div style="width: 40%" aria-valuemax="100" aria-valuemin="0" aria-valuenow="40" role="progressbar" class="progress-bar progress-bar-warning">
												<span class="">40%</span>
											</div>
										</div>
									</a>
								</li>
								<li class="new">
									<a href="#">
										<div class="task-info">
											<div>Dashboard done</div>
										</div>
										<div class="progress progress-striped">
											<div style="width: 90%" aria-valuemax="100" aria-valuemin="0" aria-valuenow="90" role="progressbar" class="progress-bar progress-bar-success">
												<span class="">90%</span>
											</div>
										</div>
									</a>
								</li>
								<li>
									<a href="#">
										<div class="task-info">
											<div>Web Development</div>
										</div>
										<div class="progress progress-striped">
											<div style="width: 66%" aria-valuemax="100" aria-valuemin="0" aria-valuenow="66" role="progressbar" class="progress-bar progress-bar-info">
												<span class="">66% </span>
											</div>
										</div>
									</a>
								</li>
								<li>
									<a href="#">
										<div class="task-info">
											<div>Mobile App</div>
										</div>
										<div class="progress progress-striped">
											<div style="width: 33%" aria-valuemax="100" aria-valuemin="0" aria-valuenow="33" role="progressbar" class="progress-bar progress-bar-danger">
												<span class="">33% </span>
											</div>
										</div>
									</a>
								</li>
								<li>
									<a href="#">
										<div class="task-info">
											<div>Issues fixed</div>
										</div>
										<div class="progress progress-striped">
											<div style="width: 80%" aria-valuemax="100" aria-valuemin="0" aria-valuenow="80" role="progressbar" class="progress-bar">
												<span class="">80% </span>
											</div>
										</div>
									</a>
								</li>
								<li class="new"><a href="">See All Pending Task</a></li>
							</ul>
						</div>
					</li>
					<li>
						<a href="#" class="btn btn-default dropdown-toggle info-number" data-toggle="dropdown">
							<i class="fa fa-envelope-o"></i>
							<span class="badge">5</span>
						</a>
						<div class="dropdown-menu dropdown-menu-head pull-right">
							<h5 class="title">You have 5 Mails </h5>
							<ul class="dropdown-list normal-list">
								<li class="new">
									<a href="">
										<span class="thumb"><img href="$config{baseurl}/html/images/photos/user1.png" alt="" /></span>
											<span class="desc">
											  <span class="name">John Doe <span class="badge badge-success">new</span></span>
											  <span class="msg">Lorem ipsum dolor sit amet...</span>
											</span>
									</a>
								</li>
								<li>
									<a href="">
										<span class="thumb"><img href="$config{baseurl}/html/images/photos/user2.png" alt="" /></span>
											<span class="desc">
											  <span class="name">Jonathan Smith</span>
											  <span class="msg">Lorem ipsum dolor sit amet...</span>
											</span>
									</a>
								</li>
								<li>
									<a href="">
										<span class="thumb"><img href="$config{baseurl}/html/images/photos/user3.png" alt="" /></span>
											<span class="desc">
											  <span class="name">Jane Doe</span>
											  <span class="msg">Lorem ipsum dolor sit amet...</span>
											</span>
									</a>
								</li>
								<li>
									<a href="">
										<span class="thumb"><img href="$config{baseurl}/html/images/photos/user4.png" alt="" /></span>
											<span class="desc">
											  <span class="name">Mark Henry</span>
											  <span class="msg">Lorem ipsum dolor sit amet...</span>
											</span>
									</a>
								</li>
								<li>
									<a href="">
										<span class="thumb"><img href="$config{baseurl}/html/images/photos/user5.png" alt="" /></span>
											<span class="desc">
											  <span class="name">Jim Doe</span>
											  <span class="msg">Lorem ipsum dolor sit amet...</span>
											</span>
									</a>
								</li>
								<li class="new"><a href="">Read All Mails</a></li>
							</ul>
						</div>
					</li>
					<li>
						<a href="#" class="btn btn-default dropdown-toggle info-number" data-toggle="dropdown">
							<i class="fa fa-bell-o"></i>
							<span class="badge">4</span>
						</a>
						<div class="dropdown-menu dropdown-menu-head pull-right">
							<h5 class="title">Notifications</h5>
							<ul class="dropdown-list normal-list">
								<li class="new">
									<a href="">
										<span class="label label-danger"><i class="fa fa-bolt"></i></span>
										<span class="name">Server #1 overloaded.  </span>
										<em class="small">34 mins</em>
									</a>
								</li>
								<li class="new">
									<a href="">
										<span class="label label-danger"><i class="fa fa-bolt"></i></span>
										<span class="name">Server #3 overloaded.  </span>
										<em class="small">1 hrs</em>
									</a>
								</li>
								<li class="new">
									<a href="">
										<span class="label label-danger"><i class="fa fa-bolt"></i></span>
										<span class="name">Server #5 overloaded.  </span>
										<em class="small">4 hrs</em>
									</a>
								</li>
								<li class="new">
									<a href="">
										<span class="label label-danger"><i class="fa fa-bolt"></i></span>
										<span class="name">Server #31 overloaded.  </span>
										<em class="small">4 hrs</em>
									</a>
								</li>
								<li class="new"><a href="">See All Notifications</a></li>
							</ul>
						</div>
					</li>
					-->
					<li>
						<a href="#" class="btn btn-default dropdown-toggle" data-toggle="dropdown">$user{firstname} $user{lastname} <span class="caret"></span></a>
						<ul class="dropdown-menu dropdown-menu-usermenu pull-right">
							<li><a href="$config{baseurl}/cgi-bin/adm_migcms_user_data.pl"><i class="fa fa-user"></i> Votre profil</a></li>
							<li><a href="$config{baseurl}/cgi-bin/fwauth.pl?sw=logout&tok=$tok"><i class="fa fa-sign-out"></i> Verrouiller</a></li>
							<li><a id="logoutlink" href="$config{baseurl}/cgi-bin/fwauth.pl?sw=logout&all=y&tok=$tok"><i class="fa fa-sign-out"></i> Se déconnecter</a></li>
						</ul>
					</li>
				</ul>
			</div>
        </div>
        <!--body wrapper start-->
		$html_google_map
		$d{content}
        <!--footer section start
        <footer class="footer">
            $year &copy; BUGIWEB
        </footer>
        footer section end-->
    </div>
</section>

$js

<input type="hidden" id="url_site" value="$ENV{HTTP_HOST}" />




<div class="modal fade" id="myModal">
  <div class="modal-dialog modal-lg" style="width:95%!important;">
    <div class="modal-content">
      <div class="hide modal-header">
        <button type="button" class="close hide" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
			
			<div class="fixed">
				<a data-dismiss="modal" data-placement="bottom" data-original-title="Retour / Annuler" class="btn btn-sm btn-default show_only_after_document_ready cancel_edit c2" aria-hidden="true">
				<i class="fa fa-fw fa-times-circle-o" data-original-title="" title=""></i>
				</a>
				<a data-placement="bottom" data-original-title="Sauvegarder" class="btn btn-sm btn-success show_only_after_document_ready admin_edit_save">
				<i class="fa fa-fw fa fa-floppy-o" data-original-title="" title=""></i>
				</a>
			</div>

					  
      </div>
      <div class="modal-body modal-edit-content">
        <i class="fa fa-cog fa-spin fa-3x fa-fw"></i><span class="sr-only">...</span>
      </div>
    </div>
  </div>
</div>
<iframe id="my_iframe" style="display:none;"></iframe>
</body>
</html>
HTML
    return $page;
}
################################################################################
# custom_tree_levels
################################################################################
sub custom_tree_levels
{
   my $id = $_[1];
   my %d = %{$_[2]};
   my $father_classes = '';
   my %rec = read_table($dbh,"$dm_cfg{table_name}",$id);
   my $fathername = 'father_'.$rec{id_father};
   do
   {
      $father_classes .=  ' father_'.$rec{id_father}.' ';
      %rec = read_table($dbh,"$dm_cfg{table_name}",$rec{id_father});
   }
   while($rec{id_father} > 0);
   if($d{level} > 0)
   {
      return <<"EOH";
<tr id="$id" name="$fathername" class="rec_$id list_line_level_$d{level} $father_classes tree tree_line">
EOH
   }
   else
   {
      return <<"EOH";
<tr class="rec_$id">
EOH
   }
}
################################################################################
# custom_get_total_duration
################################################################################
sub custom_get_total_duration
{
   my $where = $_[1] || 1;
   my $dbh_spec = $_[2] || $dm_cfg{dbh} || $dbh;
   $dm_cfg{wherep} = $dm_cfg{wherep} || 1;
   my %rec = select_table($dbh_spec,$dm_cfg{list_table_name},"sum(TIME_TO_SEC(duration)) as total_duration","$dm_cfg{wherep} AND $where","","",0);
   my $secs = $rec{total_duration};
   my $hs = int($secs/3600);
   my $mins = int(($secs % 3600)/60);
   my $jrs = $secs/28800;
   $jrs=sprintf("%.2f",$jrs);
   my $total = ($hs * 60) + ($mins * (60/60));
   $total=sprintf("%.2f",$total);
      return <<"EOH";
<div class="wrapper">
	<ul class="month-income">
		<li>
			<span class="icon-block blue-block"><b data-icon="&#xe048;" aria-hidden="true" class="fs1"></b></span>
			<h5>$hs h $mins	<small>$jrs jour(s)</small></h5>
			<p>+/- €$total (€60/h)</p>
		</li>
	</ul>
</div>
EOH
}
################################################################################
# custom_get_total_duration
################################################################################
sub bugi_facturation_dev
{
   my $where = $_[1] || 1;
   my $dbh_spec = $_[2] || $dm_cfg{dbh} || $dbh;
   my $id_facture_developpement = get_quoted('id_facture_developpement');
   my %total_facturations = sql_line({dbh=>$dbh_spec,select=>'SUM(montant_acompte) as total,id_facture_developpement',table=>'invoices_facturation_developpements',where=>$where});
   if($total_facturations{id_facture_developpement} == 0)
   {
      $total_facturations{id_facture_developpement} = $id_facture_developpement;
   }
   my %la_facture = sql_line({dbh=>$dbh_spec,table=>'invoices_facture_developpements',where=>"id='$total_facturations{id_facture_developpement}'"});
   my $reste = $la_facture{amount_due} - $total_facturations{total};
   $total=sprintf("%.2f",$total);
      return <<"EOH";
<div class="wrapper">
	<ul class="month-income">
		<li>
			<span class="icon-block blue-block"><b data-icon="&#xe022;" aria-hidden="true" class="fs1"></b></span>
			<h5><small>A facturer:</small><br /> €$la_facture{amount_due}</h5>
			<p></p>
		</li>
	<li>
		<span class="icon-block green-block"><b data-icon="&#xe0fe;" aria-hidden="true" class="fs1"></b></span>
		<h5><small>Déja facturé:</small><br /> €$total_facturations{total}</h5>
		<p></p>
	</li>
	<li>
	<span class="icon-block red-block">
	<b data-icon="&#xe038;" aria-hidden="true" class="fs1"></b>
	</span>
	<h5>
	<small class="">Reste:</small><br /> €$reste
	</h5>
	<p>
	</p>
	</li>
	</ul>
</div>
EOH
}
################################################################################
# custom FUNCS
################################################################################
sub custom_orders_paid
{
   my $id = $_[1];
   my %rec = read_table($dbh,"orders",$id);
   if($rec{shop_payment_status} eq 'paid' || $rec{shop_payment_status} eq 'captured')
   {
      return <<"EOH";
      <tr class="success rec_$id">
EOH
   }
   else
   {
      return <<"EOH";
      <tr class=" rec_$id">
EOH
   }
}
################################################################################
# custom FUNCS
################################################################################
sub billing_amount_remaining
{
   my $id = $_[1];
   my %rec = sql_line({debug=>0,dbh=>$dm_cfg{dbh},select=>'amount_remaining',table=>"invoices_facture_developpements",where=>"id='$id'"});
   if($rec{amount_remaining} == 0)
   {
      return <<"EOH";
      <tr class="green_line success rec_$id" style="">
EOH
   }
   elsif($rec{amount_remaining} < 0)
   {
      return <<"EOH";
      <tr class="error rec_$id">
EOH
   }
   else
   {
      return <<"EOH";
      <tr class=" rec_$id">
EOH
   }
}
sub custom_offers
{
   my $id_table_record = $_[1];
   my $id_col = $dm_cfg{id_col} || 'id';
   my %rec = select_table($dm_cfg{dbh},"offers","status","$id_col = '$id_table_record'");
   return <<"EOH";
      <tr class="offer_$rec{status} rec_$id_table_record">
EOH
}


sub dm_init
{
	my $sel = get_quoted('sel');
	$dm_cfg{self} = $dm_cfg{self}.'&sel='.$sel;
	if($dm_cfg{enable_search} eq '')
	{
		$dm_cfg{enable_search} = 1;
	}
	
	if($dm_cfg{visibility} eq '')
	{
		$dm_cfg{visibility} = $dm_cfg{vis_opt};
	}
	if($dm_cfg{disable_cache_listboxtables} eq '')
	{
		$dm_cfg{disable_cache_listboxtables} = 1;
	}

	my %disponibilite_permission = sql_line({debug=>0,debug_results=>0,table=>'migcms_roles_scripts_permissions',where=>"id_script='$sel' AND id_role='2'"});
	my %user_permission = ();
	if($user{id_role} != 1)
	{
		%user_permission = sql_line({debug=>0,debug_results=>0,table=>'migcms_roles_scripts_permissions',where=>"id_script='$sel' AND id_role='$user{id_role}'"});
	}
	
	%dm_permissions = ();
	
	
	if($config{generer_droit_users} ne 'y')
	{
		#GERER DROITS PAR ROLE
		foreach $action (@dm_actions)
		{
			my %action = %{$action};
			if($action{code} eq 'sort')
			{
				next;
			}
			if($action{code} eq 'visibility')
			{
				next;
			}

			if($disponibilite_permission{$action{code}} eq 'y' && ($user{id_role} == 1 || $user_permission{$action{code}} eq 'y'))
			{
				$dm_permissions{$action{code}} = 1;
			}
			else
			{
				$dm_permissions{$action{code}} = 0;
			}
			
			my $permission_forcee = $dm_cfg{'force_'.$action{code}};
			if( $permission_forcee ne '')
			{
				#force certaines permissions
				$dm_permissions{$action{code}} = $permission_forcee;
			}
		}
	}
	else
	{
		#GERER DROITS PAR USER
		foreach $action (@dm_actions)
		{
			my %action = %{$action};
			if($action{code} eq 'sort')
			{
				next;
			}
			if($action{code} eq 'visibility')
			{
				next;
			}

			if($user_permission{$action{code}} eq 'y')
			{
				$dm_permissions{$action{code}} = 1;
			}
			else
			{
				$dm_permissions{$action{code}} = 0;
			}
			
			my $permission_forcee = $dm_cfg{'force_'.$action{code}};
			if( $permission_forcee ne '')
			{
				#force certaines permissions
				$dm_permissions{$action{code}} = $permission_forcee;
			}
		}
	}
	
	#tri: désactivé par défaut sauf si paramètre précisé dans le script ou script arborescent
	$dm_permissions{sort} = 0;
	if($dm_cfg{sort} == 1 || $dm_cfg{sort_opt} == 1 || $dm_cfg{sort_op} eq 'y' || $dm_cfg{tree} == 1)
	{
		$dm_permissions{sort} = 1;
	}
	
	#visibilité: désactivé par défaut sauf si paramètre précisé dans le script
	$dm_permissions{visibility} = 0;
	if($dm_cfg{vis_opt} == 1 || $dm_cfg{visibility} == 1 || $dm_cfg{vis_opt} eq 'y' || $dm_cfg{visibility} eq 'y')
	{
		$dm_permissions{visibility} = 1;
	}
	
	if($dm_cfg{enable_search} == 1 && $dm_cfg{search_save} eq '')
	{
		$dm_cfg{search_save} = 1;
	}
	
	if($dm_permissions{operations} == 1)
	{
		$dm_permissions{excel} = 0;
	}
	
	#ajoute les  colonnes systemes (ID,date de création, id_user de création) à dm_dfl
	my %new_dm_dfl = ();
	my $count = 4;
	foreach $key (keys(%dm_dfl))
	{	
		my ($num,$cell_infos_ref) = split(/\//,$key);
		
		if($dm_dfl{$key}{system_only} == 1 && $user{id_role} > 1)
		{
			next;
		}
		
		$new_dm_dfl{sprintf("%05d", ($num*20)).'/'.$cell_infos_ref} = $dm_dfl{$key};
		if($dm_dfl{$key}{adresse_fields} ne '')
		{
			my @adresse_fields = split(/\,/,$dm_dfl{$key}{adresse_fields});
			my @adresse_names = split(/\,/,$dm_dfl{$key}{adresse_names});
			my $af = 0;
			my $hide_colsearch = 0;
			foreach my $adresse_field (@adresse_fields)
			{
				if($adresse_field ne '')
				{
					$new_dm_dfl{sprintf("%05d", $count++).'/'.$adresse_field} = 	
					{
						'title'=>$adresse_names[$af],
						'tab'=>$dm_dfl{$key}{tab},
						'hide_colsearch'=>$hide_colsearch,
						'fieldtype'=>'display',
						'fromadresse'=>'y',
						'search'=>$dm_dfl{$key}{search},
						'hidden'=>'1',
					};
				}
				$af++;
				if($af > 6)
				{
					$hide_colsearch = 1;
				}
			}			
		}
	}
	
	%dm_dfl = %new_dm_dfl;
	$dm_dfl{'00001/id'} = 	
	{
        'title'=>'Identifiant',
        'fieldtype'=>'text',
        'search'=>'y',
        'hidden'=>'1',
    };
	$dm_dfl{'00002/migcms_moment_create'} = 	
	{
        'title'=>'Date création',
        'fieldtype'=>'text',
        'data_type'=>'datetime',
        'hidden'=>'1',
    };
	$dm_dfl{'00003/migcms_id_user_create'} = 	
	{
        'title'=>"Création par",
        'fieldtype'=>'listboxtable',
		 'lbtable'=>'users',
         'lbkey'=>'id',
         'lbdisplay'=>"CONCAT(firstname,' ',lastname)",
        'hidden'=>'1',
		 
    };
	$dm_dfl{'00004/migcms_moment_last_edit'} = 	
	{
        'title'=>'Date dernière modification',
        'fieldtype'=>'text',
        'data_type'=>'datetime',
        'hidden'=>'1',
    };
	$dm_dfl{'00005/migcms_id_user_last_edit'} = 	
	{
        'title'=>"Dernière modification par",
        'fieldtype'=>'listboxtable',
		 'lbtable'=>'users',
         'lbkey'=>'id',
         'lbdisplay'=>"CONCAT(firstname,' ',lastname)",
        'hidden'=>'1',
		 
    };
	$dm_dfl{'00006/migcms_moment_view'} = 	
	{
        'title'=>'Date dernier accès',
        'fieldtype'=>'text',
        'data_type'=>'datetime',
        'hidden'=>'1',
    };
	$dm_dfl{'00007/migcms_id_user_view'} = 	
	{
        'title'=>"Dernier accès par",
        'fieldtype'=>'listboxtable',
		 'lbtable'=>'users',
         'lbkey'=>'id',
         'lbdisplay'=>"CONCAT(firstname,' ',lastname)",
        'hidden'=>'1',
		 
    };
	# use Data::Dumper;
	# log_debug(Dumper(\%dm_dfl),'','dmdfl');
		
	#adapte la config full url
	if($config{fullurl} eq '')
	{
		my $page_url = 'http';
		$page_url.='s' if $ENV{HTTPS};
		$page_url.='://';
		$page_url.="$ENV{SERVER_NAME}/";
		$config{fullurl} = $page_url;
	}	
	
	#adapte dm_display_fields selon les choix du user
	my @custom_cols = sql_lines({table=>'migcms_user_script_cols',where=>"id_script='$sel' AND id_user='$user{id}'",ordby=>"ordby"});
	my %new_dm_display_fields = ();
	my $if = 0;
	if($#custom_cols > -1)
	{
		foreach $custom_col (@custom_cols)
		{
			my %custom_col = %{$custom_col};
			if($custom_col{afficher} eq 'y' && $custom_col{field} ne 'id')
			{
				# $new_dm_display_fields{get_field_info_from_dm_dfl($custom_col{field},'ordby').'/'.get_field_info_from_dm_dfl($custom_col{field},'title')} = $custom_col{field};
				$new_dm_display_fields{sprintf("%03d", (100+$custom_col{ordby})).'/'.get_field_info_from_dm_dfl($custom_col{field},'title')} = $custom_col{field};
			}
		}
		%dm_display_fields = %new_dm_display_fields;
	}
}

sub get_field_info_from_dm_dfl
{
	my $field = $_[0];
	my $info = $_[1];
		
	foreach $field_line (sort keys %dm_dfl)
	{
		($ordby,$field_name) = split(/\//,$field_line);
		if($field_name eq $field)
		{
		   %line = %{$dm_dfl{$field_line}};
		   if($info eq 'ordby')
		   {
				return $ordby;
		   }
		   return $line{$info};
		}
	}
}

################################################################################
# OLD subroutines for compatibility < MIGC4
################################################################################
sub get_gen_buttonbar
{
}
sub get_spec_buttonbar
{
}
sub migc_app_layout
{
    display($_[0]);
}
sub wfw_app_layout
{
    display($_[0]);
}

#TOOLS
sub to_sql_date
{
	my $date = $_[0];	#Date à convertir
	my $date_only=$_[1] || "all";
	my ($dd,$mm,$yyyy) = split (/\//,$date);	#Séparation de la date
	if($date_only eq 'date_only')
	{
      $date = "$yyyy-$mm-$dd";	#Reformattage de la date
  }
  else
  {
      $date = "$yyyy-$mm-$dd 00:00:00";	#Reformattage de la date
	}
	return $date;	#Renvoit de la date au bon format
}
sub to_sql_time
{
	my $time = $_[0];	#Date à convertir
  #10h15
  $_ = $time;
  if (/h/)
  {
     my ($hh,$mm) = split (/h/,$time);	#Séparation de la date
     if($hh eq "")
     {
        $hh='00';
     }
     if($mm eq "")
     {
        $mm='00';
     }
     return "$hh:$mm:00";
  }
  #10:15 ou 10:15:00
  $_ = $time;
  if (/\:/)
  {
     my ($hh,$mm,$ss) = split (/\:/,$time);	#Séparation de la date
     if($hh eq "")
     {
        $hh='00';
     }
     if($mm eq "")
     {
        $mm='00';
     }
     if($ss eq "")
     {
        $ss='00';
     }
     return "$hh:$mm:$ss";
  }
  #10
  $_ = $time;
  if (/\d/)
  {
     return "$time:00:00";
  }
  return "";
}
#*****************************************************************************************
#DATE time TO HUMAN time
#*****************************************************************************************
sub datetime_to_human_time
{
   my $content = trim($_[0]);
   my $separator = $_[1] || 'h';
   my ($dum,$content) = split (/ /,$content);
   my ($heure,$min,$sec) = split (/:/,$content);
   return $heure.$separator.$min;
}

#*****************************************************************************************
sub sql_radios
{
    my %d = %{$_[0]};
    if($d{table} ne "" && $d{value} ne "" && $d{display} ne "" && $d{name} ne "")
    {
          my $cbs=<<"EOH";
EOH
          my @records=get_table($d{dbh},$d{table},$d{select},$d{where},$d{ordby},"","",$d{debug});
          foreach my $rec (@records)
          {
              my $checked="";
              if($d{current_value} eq $rec->{$d{value}})
              {
                  $checked=<<"EOH";
                   checked = "checked"
EOH
              }
              $cbs.=<<"EOH";
                <label>
                  <input type="radio" name="$d{name}" $checked value="$rec->{$d{value}}" $d{required} class="$d{class}">
                  $rec->{$d{display}}
                </label>
EOH
          }
          $cbs.=<<"EOH";
EOH
          return $cbs;
          exit;
    }
    else
    {
        return "missing mandatory data: [table:$d{table}][value:$d{value}][display:$d{display}][name:$d{name}]";
    }
}
sub sql_listbox_ajax
{
   my $value = get_quoted('value');
   my $display = get_quoted('display');
   my $name = get_quoted('name');
   my $selval = get_quoted('selval');
   my $use_dbh = get_quoted('use_dbh');
   my $table = get_quoted('table');
   my $dbh_rec = $dbh;
   my $where = get_quoted('where');
   $where =~ s/\\\'/\'/g;
   my $hide = get_quoted('hide') || 0;
   if($use_dbh eq 'dbh2')
   {
      $dbh_rec = $dbh2;
   }
   if ($hide) {
       $required = "style=\"display:none;\"";
   } else {
       $required = "";
   }
   my $listbox = sql_listbox(
                                {
                                      dbh=>$dbh_rec,
                                      table=>$table,
                                      show_empty=>'y',
                                      select=>"$value as value, $display as display",
                                      value=>'value',
                                      display=>'display',
                                      name=> $name,
                                      class=>"$name inc_combobox",
                                      where => $where,
                                      current_value => $selval,
                                      required => $required,
                                });
    print $listbox;
    exit;
}
#*****************************************************************************************
sub sql_listbox
{
    my %d = %{$_[0]};
    my $empty_option=<<"EOH";
      <option value="">$d{empty_txt}</option>
EOH
    if($d{show_empty} ne 'y')
    {
        $empty_option="";
    }
    if($d{table} ne "" && $d{value} ne "" && $d{display} ne "" && $d{name} ne "")
    {
          my $listbox=<<"EOH";
              <select name="$d{name}" $d{required} id="$d{id}" class="$d{class}">
                  $empty_option
EOH
          my @records=get_table($d{dbh},$d{table},$d{select},$d{where},$d{ordby},"","",$d{debug});
          foreach my $rec (@records)
          {
              my $selected="";
              if($d{current_value} eq $rec->{$d{value}})
              {
                  $selected=<<"EOH";
                   selected = "selected"
EOH
              }
              $listbox.=<<"EOH";
                  <option value="$rec->{$d{value}}" $selected>
                    $rec->{$d{display}}
                  </option>
EOH
          }
          $listbox.=<<"EOH";
              </select>
EOH
          return $listbox;
          exit;
    }
    else
    {
        return "missing mandatory data: [table:$d{table}][value:$d{value}][display:$d{display}][name:$d{name}]";
    }
}
################################################################################
# get_setup
################################################################################
sub get_setup
{
    my %d = %{$_[0]};
    if($d{module} eq 'migcms')
    {
        my %setup = sql_line({table=>"migcms_setup"});
        if($setup{id} > 0)
        {
            return \%setup;
        }
        else
        {
            see();
            print "Lancez le setup de la boutique pour continuer";
            exit;
        }
    }
}
sub json_request
{
    print <<"EOH";
       [
          {
            "cle":1,
            "display": "Hopital Saint Joseph",
            "value": "Pediatrie - Hopital Saint Joseph"
          }
        ]
EOH
    exit;
}


sub dupliquer
{
    see();
	my $id = get_quoted('id');

	if($dm_cfg{custom_duplicate_func} ne "")
	{
		  my $func = $dm_cfg{custom_duplicate_func};
		  &$func($dbh,$id);
	}
	else
	{
		  my $new_id = duplicate_simple_record($dbh,$id);
		  if ($dm_cfg{after_duplicate_ref} ne "")
          {
            my $func = $dm_cfg{after_duplicate_ref};
            &$func($dbh,$new_id,$id);
          }
	}
	exit;
}

sub lock_on
{
    see();
	my $id = get_quoted('id'); 
	execstmt($dbh_data,"UPDATE $dm_cfg{table_name} SET migcms_lock = 'y' WHERE id = '$id' ");
	exit;
}

sub lock_off
{
    see();
	my $id = get_quoted('id');
	execstmt($dbh_data,"UPDATE $dm_cfg{table_name} SET migcms_lock = 'n' WHERE id = '$id' ");
	exit;
}

################################################################################
# DUPLICATE SIMPLE RECORD
################################################################################
sub duplicate_simple_record
{
	my $dbh_data=$_[0];
	my $num=$_[1];
	my $reverse_ordby = $_[2] || '';
	my $table_name = $_[3];
	my $debug = $_[4];

	my %dm_dfl_alt = %{$_[5]};

	my $alt_file_prefixe = $_[6];
	my $use_file_prefixe = $dm_cfg{file_prefixe};
	if($alt_file_prefixe ne '')
	{
		$use_file_prefixe = $alt_file_prefixe;
	}

	my %use_dm_dfl = ();
	%use_dm_dfl = %dm_dfl;


	$size = keys %dm_dfl_alt;
	if($size > 1)
	{
		my %use_dm_dfl_temp = %dm_dfl_alt;
		%use_dm_dfl = %use_dm_dfl_temp;
	}


	if($table_name eq '')
	{
		$table_name = $dm_cfg{table_name};
	}

	my $colg=get_quoted('colg') || $config{default_colg} || 1;
	my @languages = get_table($dbh,"migcms_languages",'',"visible='y' AND id!=$colg");
	my %rec= sql_line({debug=>0,debug_results=>0,table=>$table_name,where=>"id='$num'"});
	my $ordby = "";
	if ($dm_permissions{sort})
	{
		$ordby=$rec{ordby};
		if ($ordby eq "")
		{
			$ordby = 0;
		}
	}
	foreach $key (sort keys(%rec))
	{
		$rec{$key} =~ s/\'/\\\'/g;
	}

	foreach $key (sort keys(%use_dm_dfl))
	{
		my ($dum,$field) = split (/\//,$key);

		my %hash=%{$use_dm_dfl{$key}};
		if($hash{fieldtype} eq 'text_id' || $hash{fieldtype} eq 'textarea_id' || $hash{fieldtype} eq 'textarea_id_editor')
		{
			my %txtcontent = read_table($dbh,'txtcontents',$rec{$field});
			delete $txtcontent{id};
			%txtcontent = %{quoteh(\%txtcontent)};
			$rec{$field} = inserth_db($dbh_data,'txtcontents',\%txtcontent);
		}
	}

	if ($dm_permissions{sort})
	{
		if($reverse_ordby eq 'reverse_ordby')
		{
			execstmt($dbh_data,"UPDATE $table_name SET ordby = ordby+1");
			$rec{ordby} = 1;
		}
		else
		{
			$rec{ordby} = get_next_ordby(dbh=>$dbh_data,table=>$table_name,where => $dm_cfg{wherep_ordby});
		}
	}
	my $old_id = $red{id};
	delete $rec{id};
	my $new_id=inserth_db($dbh_data,$table_name,\%rec);

	if(0)
	{

	#duplicate linked files
	foreach $key (sort keys(%use_dm_dfl))
	{
		my ($dum,$field) = split (/\//,$key);

		my %hash=%{$use_dm_dfl{$key}};

		if($hash{fieldtype} eq 'files_admin')
		{
			if(0 && $use_file_prefixe ne '')
			{
				#create dirs
				my $dir = $config{directory_path}.'/usr/files/'.$use_file_prefixe;
				unless (-d $dir) {mkdir($dir.'/') or log_debug("cannot create ".$dir.": $!");}
				my $dir = $config{directory_path}.'/usr/files/'.$use_file_prefixe.'/'.$field;
				unless (-d $dir) {mkdir($dir.'/') or log_debug("cannot create ".$dir.": $!");}
				my $dir = $config{directory_path}.'/usr/files/'.$use_file_prefixe.'/'.$field.'/'.$new_id;
				unless (-d $dir) {mkdir($dir.'/') or log_debug("cannot create ".$dir.": $!");}

				#copy content
				use File::NCopy;
				my $source_dir = $config{directory_path}.'/usr/files/'.$use_file_prefixe.'/'.$field.'/'.$old_id;
				my $target_dir = $config{directory_path}.'/usr/files/'.$use_file_prefixe.'/'.$field.'/'.$new_id;
				my $cp = File::NCopy->new(recursive => 1);


				#!!!!! PROBLEME: cela copie tous les fichiers de PAR/ dans le nouveau dossier !


				$cp->copy("$source_dir/*", $target_dir)
					or log_debug("Could not perform rcopy of $source_dir to $target_dir: $!");
			}
		}

		if($dm_cfg{after_dupl_func} ne '')
		{
			my $func = 'def_handmade::'.$dm_cfg{after_dupl_func};
			return &$func({new_id=>$new_id,record_table=>$table_name,record_id=>$num});
		}
	}

	}

	return $new_id;
}
###############################################################################
# logout_db
###############################################################################
sub logout_db
{
    my %hash_order = ();
    $hash_order{token} = '';
    my $order_utf8_encoded_json_text = encode_json \%hash_order;
    my $cook = $cgi->cookie(-name=>$config{migc4_cookie},-value=>$order_utf8_encoded_json_text,-path=>'/');
    print $cgi->header(-cookie=>$cook,-charset => 'utf-8');
    http_redirect('$config{baseurl}/cgi-bin/fwauth.pl?');
}

sub parag_template
{
	see();
	my $id_parag = get_quoted('id_parag');
	my $id_template = get_quoted('id_template');
	if($id_parag > 0 && $id_template > 0)
	{
		$stmt = "UPDATE parag SET id_template='$id_template' WHERE id = '$id_parag' ";
		execstmt($dbh,$stmt);
	}
}
sub is_mobile()
{
  my $agent = $ENV{HTTP_USER_AGENT};
	return 1 if ($agent =~ m/android|avantgo|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od|ad)|iris|kindle|lge |maemo|midp|mmp|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i);
	return 1 if (substr($agent, 0, 4) =~ m/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|e\-|e\/|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(di|rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|xda(\-|2|g)|yas\-|your|zeto|zte\-/i);
	return 0;
}

sub get_migcms_publish_bar
{
	my $id_page = $_[0];
	my $texte_apercu = 'Aperçu';

	if($colg eq '')
	{
		$colg = 1;
	}

	if(!($id_page>0))
	{
		my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
		$id_page = $migcms_setup{id_default_page};
		$texte_apercu = 'Aperçu';
	}
	$url_rewriting = get_url({debug=>0,debug_results=>0,nom_table=>'migcms_pages',id_table=>$id_page, id_language => $colg});
	# $home = "$config{baseurl}/".$url_rewriting;
	$home = "$config{baseurl}/";

	return <<"EOH";
<a data-placement="bottom"  target="_blank" data-original-title="$migctrad{see_website_online}" href="$home" class="btn-viewsite"><i class="fa fa-external-link"></i></a>
<a data-placement="bottom"  target="_blank" data-original-title="$migctrad{overview_changes}" href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page=$id_page" class="btn-previewsite"><i class="fa fa-eye"></i></a>
<a data-placement="bottom"  data-original-title="$migctrad{publish_changes}" href="$config{baseurl}/cgi-bin/adm_migcms_build.pl?&sel=178" class="btn-generatesite"><i class="fa fa-check"></i></a>
EOH

}
sub datasheets_getcategories
{
	my $dbh=$_[0];
	my $id_data_sheet=$_[1];
    my ($arbre,$cpt) = migcadm::data_get_shop_tree_nodes2($dbh,0,0,$id_data_sheet,$colg);
	my $categories = <<"EOH";
		<div id="son_$id_data_sheet">
			<ul id="" class="filetree">
				$arbre
			</ul>
		</div>
EOH
    return $categories;
}
sub datasheets_getvariants
{
	my $id_data_sheet=$_[1];
    my $last_nb_crit = 0;
    my $str_crits = "";
        my @crits = get_table($dbh,"data_crits","","1 order by ordby","","","",0);
        foreach $crit (@crits)
        {
           my %crit=%{$crit};
           my ($name,$dum) = get_textcontent($dbh,$crit{id_textid_name},$colg);
           my $crits = "";
           ($crits,$last_nb_crit) = data::data_get_crits_list($dbh,$crit{id},get_quoted('id'),$last_nb_crit);
            $str_crits .= <<"EOH";
                <fieldset class="mig_fieldset">
                  <h2 class="mig_legend">
                      $name
                  </h2>
                  $crits
                </fieldset>
EOH
        }
        $str_crits .= '<input type="hidden" name="nb_crits" value="'.$last_nb_crit.'" />';
		$str_crits = <<"EOH";
      		<fieldset class="fm_fieldset" id="crit_boxes">
              $str_crits
          </fieldset>
			<div role="alert" class="stock_change alert alert-warning hide">
				<strong> <i class="fa fa-info-circle"></i> $migctrad{adm_prices} </strong>
				<br /> $migctrad{adm_variantschanges}
			</div>
EOH
		return $str_crits;
}
sub datasheets_getstock
{
	my $id_data_sheet=$_[1] || get_quoted('id_data_sheet');
	my %ps = sql_line({debug=>0,debug_results=>0,table=>"data_sheets",where=>"id='$id_data_sheet'"});
	my $id_data_family= $ps{id_data_family};
	my $stock_div="";
	$table = data::get_supply_table_form($id_data_sheet,$id_data_family,"no_form");
	my %taux =
	(
		0=>'0%',
		6=>'6%',
		12=>'12%',
		21=>'21%'
	);
	my $list_tva = makeselecth(\%taux,$ps{taux_tva});
	my $hide_tva = "";
	if ($config{hide_tva_admin} eq "y")
	{
	  $hide_tva = "style=\"display:none;\"";
	}
	if($config{data_sheet_force_tva} eq '')
	{
		$stock_div.=<<"EOH";
			<div id="mig_data_tva" $hide_tva>
				TVA: <select name="taux_tva" class="taux_tva mig_select saveme"> $list_tva </select>
			</div>
EOH
	}
	else
	{
		$stock_div.=<<"EOH";
			<div id="mig_data_tva" $hide_tva>
				<input name="taux_tva" class="taux_tva mig_select"  type="hidden" value="$config{data_sheet_force_tva}" />
			</div>
EOH
	}
		$stock_div.=<<"EOH";
			<input type="hidden" id="shop_linked" value="$shop_linked" />
			$table
EOH
		if(get_quoted('id_data_sheet') > 0)
		{
			print $stock_div;
			exit;
		}
		else
		{
			return $stock_div;
		}
}
sub migcms_ajax_get_tinymce_data
{
	# see();
	my @migcms_templates_styles = sql_lines({table=>'migcms_templates_styles',ordby=>'nom_style'});
	my @styles = ();
	foreach my $migcms_templates_style (@migcms_templates_styles)
	{
		my %migcms_templates_style = %{$migcms_templates_style};
		$migcms_templates_style{css_style} =~ s/\r*\n//g;
		push @styles, "{title: '$migcms_templates_style{nom_style}', $migcms_templates_style{balise_style}, styles: {$migcms_templates_style{css_style}}}",
	}
	my $liste_styles = join(",",@styles);
	my $style_format = <<"EOH";
	[
		$liste_styles
    ]
EOH
	my @migcms_templates_formats = sql_lines({table=>'migcms_templates_formats',ordby=>'nom_format'});
	my @formats = ();
	foreach my $migcms_templates_format (@migcms_templates_formats)
	{
		my %migcms_templates_format = %{$migcms_templates_format};
		$migcms_templates_format{contenu_format} =~ s/\r*\n//g;
		push @formats, "{title: '$migcms_templates_format{nom_format}', content: '$migcms_templates_format{contenu_format}'}",
	}
	my $liste_formats = join(",",@formats);
	my $templates = <<"EOH";
	[
		$liste_formats
    ]
EOH
	print $style_format.'___'.$templates;
	exit;
}
sub quoteh
{
	my %hash_r = %{$_[0]};
	foreach $key (keys %hash_r)
	{
		$hash_r{$key} =~ s/\\//g;
		$hash_r{$key} =~ s/\\//g;
		$hash_r{$key} =~ s/\\//g;
		$hash_r{$key} =~ s/\'/\\\'/g;
	}
	return \%hash_r;
}



sub add_error
{
	my %d = %{$_[0]};
	my $id_user = $d{id_user};
	if($id_user eq '')
	{
		$id_user = $user{id};
	}
	if(!($id_user>0))
	{
		# %user = %{get_user_info($dbh, $config{current_user})};
		$id_user = $user{id};
	}
	my %history =
	(
		action => $d{action},
		details => $d{details},
		id_user => $id_user,
		date => 'NOW()',
		time => 'NOW()',
		moment => 'NOW()',
		infos => "$ENV{REMOTE_ADDR} $ENV{HTTP_USER_AGENT}",
		page_record => $d{page},
		id_record => $d{id},
	);
	%history = %{quoteh(\%history)};
	inserth_db($dbh,'migcms_errors',\%history);
}

sub migcms_upload
{
	my $field_name = $_[0];
	 my $og_width = $_[1];
	 my $mini_width = $_[2];
	 my $small_width = $_[3];
	 my $medium_width = $_[4];
	 my $large_width = $_[5];
	 my $insert_pic = $_[6];
	 my $table_name = $_[7] || 'data_sheets';
	 my $id_table = $_[8];
	 my $ordby = $_[9] || 1;
	my $test_file = $cgi->param($field_name);
	if($test_file ne '')
    {
        my $full =  migcms_upload_file($field_name,$og_width,$mini_width,$small_width,$medium_width,$large_width,$insert_pic,$table_name,$id_table,$ordby);
		return $full;
	}
	else
	{
		print "no file received for [$field_name]";
	}
}
sub migcms_upload_file
{
     my $field_name = $_[0];
	 my $og_width = $_[1];
	 my $mini_width = $_[2];
	 my $small_width = $_[3];
	 my $medium_width = $_[4];
	 my $large_width = $_[5];
	 my $insert_pic = $_[6];
	 my $table_name = $_[7] || '';
	 my $id_table = $_[8];
	 my $ordby = $_[9] || 1;
	 my $full_r = $_[10];
	 my $fullname_r = $_[11];
     my $ext = '';
     my $pic = $cgi->param($field_name);
     my $pic_dir = '../pics';
	my $filename = '';
	if($full_r eq '' || $fullname_r eq '')
	{
		($full,$fullname,$orig_size) = migcms_do_upload_file($pic,$pic_dir);
	}
	else
	{
		$full = $full_r;
		$fullname = $fullname_r;
	}
	if($og_width > 0)
	{
		($og,$og_width,$og_height,$full_width,$full_height) = thumbnailize($full,$pic_dir,$og_width,$og_width,"_og");
	}
	if($mini_width > 0)
	{
		($mini,$mini_width,$mini_height,$full_width,$full_height) = thumbnailize($full,$pic_dir,$mini_width,$mini_width,"_mini");
	}
	if($small_width > 0)
	{
		($small,$small_width,$small_height,$full_width,$full_height) = thumbnailize($full,$pic_dir,$small_width,$small_width,"_small");
	}
	if($medium_width > 0)
	{
		($medium,$medium_width,$medium_height,$full_width,$full_height) = thumbnailize($full,$pic_dir,$medium_width,$medium_width,"_medium");
	}
	if($large_width > 0)
	{
		($large,$large_width,$large_height,$full_width,$full_height) = thumbnailize($full,$pic_dir,$large_width,$large_width,"_large");
	}
	if($insert_pic eq 'insert_pic')
	{
		my %newpic =
		(
		  id_table=>$id_table,
		  table_name=>$table_name,
		  ordby=>0,
		  pic_name_full => $full,
		  pic_width_full => $full_width,
		  pic_height_full => $full_width,
		  pic_name_og => $og,
		  pic_width_og => $og_width,
		  pic_height_og => $og_width,
		  pic_name_mini=>$mini,
		  pic_width_mini=>$mini_width,
		  pic_height_mini=>$mini_width,
		  pic_name_small=>$small,
		  pic_width_small=>$small_width,
		  pic_height_small=>$small_width,
		  pic_name_medium=>$medium,
		  pic_width_medium=>$medium_width,
		  pic_height_medium=>$medium_width,
		  pic_name_large=>$large,
		  pic_width_large=>$large_width,
		  pic_height_large=>$large_width,
		  url=>'',
		  blank=>'',
		  id_textid_alt=>0,
		);
		$id_pic = inserth_db($dbh,"pics",\%newpic);
		return $id_pic;
	}
	return $full;
}
sub migcms_do_upload_file
{
	my $in_filename = $_[0] || "";	#Nom du fichier
	my $upload_path = $_[1];		#Chemin absolu du fichier
	my $token = $_[2];
	my $force_file_url = $_[3];
	my ($size, $buff, $bytes_read, $file_url);
	if ($in_filename eq "" || $in_filename =~ /(php|js|pl|asp|cgi|swf)$/) {  return ""; }	#Si pas de fichier alors retour de rien
	my @splitted = split(/\./,$in_filename);
	my $ext = lc($splitted[$#splitted]);
	my $filename = $splitted[0];
	$filename = clean_filename($filename);
	# build unique filename from current timestamp
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year+=1900;
	$mon++;
	my @chars = ( "A" .. "Z", "a" .. "z");
	$file_url = $filename .'_'.$year.$mon.$mday.$hour.$min.'.'.$ext;
	if($config{no_date_in_file} eq 'y')
	{
		$file_url = $filename.'.'.$ext;
	}
	if($force_file_url ne '')
	{
		$file_url = $force_file_url.'.'.$ext;
	}
	# add the target directory
	my $out_filename = $upload_path."/".$file_url;

	# upload the file contained in the CGI buffer
	if (!open(WFD,">$out_filename"))
	{
		suicide("cannot create file $out_filename $!");
	}
	# $in_filename = "define::$in_filename";
	while ($bytes_read = read($in_filename,$buff,2096))	#Tant qu'on peut lire le fichier
	{
	    $size += $bytes_read;	#Ajout des bytes lu
	    binmode WFD;
	    print WFD $buff;	#Enregistrement
	}
	close(WFD);	#Fermeture
	return $file_url;
}

sub resize_pic
{
	my %d = %{$_[0]};
	my %update_migcms_linked_file = ();
	my @sizes = ('mini','small','medium','large','og');
	$update_migcms_linked_file{do_not_resize} = $d{do_not_resize};
	my $full_pic = $d{migcms_linked_file}{'full'}.$d{migcms_linked_file}{'ext'};
	foreach my $size (@sizes)
	{
		#supprimer le fichier miniature existante s'il existe
		if(trim($d{migcms_linked_file}{'name_'.$size}) ne '' && $d{migcms_linked_file}{'name_'.$size} ne '.' && $d{migcms_linked_file}{'name_'.$size} ne '..' && $d{migcms_linked_file}{'name_'.$size} ne '/')
		{
			my $existing_file_url = $d{migcms_linked_file}{file_dir}.'/'.$d{migcms_linked_file}{'name_'.$size};
			
			if(-e $existing_file_url)
			{
				unlink($existing_file_url);
				log_debug("unlink($existing_file_url)");
			}
			else
			{
				log_debug('existe pas');
			}
		}
		
		if
		(
			$d{do_not_resize} eq 'y'
		)
		{
			#ne pas redimensionner: nettoyer données existantes
			$update_migcms_linked_file{'size_'.$size} = 0;
			$update_migcms_linked_file{'width_'.$size} = 0;
			$update_migcms_linked_file{'height_'.$size} = 0;
			$update_migcms_linked_file{'name_'.$size} = '';
		}
		else
		{
			#créer une nouvelle miniature
			
			if($d{'size_'.$size} > 0)
			{
				# log_debug('2size_'.$size.':'.$d{'size_'.$size});
				($thumb,$thumb_width,$thumb_height,$full_width,$full_height) = thumbnailize($full_pic,$d{migcms_linked_file}{file_dir},$d{'size_'.$size},$d{'size_'.$size},'_'.$size);
				$update_migcms_linked_file{'size_'.$size} = $d{'size_'.$size};
				$update_migcms_linked_file{'width_'.$size} = $thumb_width;
				$update_migcms_linked_file{'height_'.$size} = $thumb_height;
				$update_migcms_linked_file{'name_'.$size} = $thumb;
			}
		}
		updateh_db($dbh,"migcms_linked_files",\%update_migcms_linked_file,'id',$d{migcms_linked_file}{id});
	}
}
sub migcms_create_links
{
}



sub get_files_in_dir
{
	 my @files_list= ();
	 if($_[0] ne '')
	 {
		 my $out_path = $_[0];
		 
		 opendir (MYDIR, $out_path) || die ("cannot LS $out_path");
		 my @files_array = readdir(MYDIR);
		 closedir (MYDIR);

		 my $cpt = 0;
		 foreach my $file (@files_array) 
		 {

			my $full_name = "$out_path/$file";
			my @fileprop = stat $full_name;
			if (-f $full_name) 
			{         
				push @files_list,$file;
			}   
		 }
	 
		 return @files_list; 
	 }
}

sub download_file
{
	my $file = $_[0];
	my $ext = $_[1];
	my $del = $_[2];
	my $no_download = $_[3];
	my %types =
	(
		'pdf'=> 'application/pdf',
		'txt'=> 'text/html',
	);
	my @tmp = split(/\//,$file);
	my $file_display = $tmp[$#tmp];
	print $cgi->header(-attachment=>$file_display,-type=>$types{$ext});
	open (FILE,$file);
	binmode FILE;
	binmode STDOUT;
	while (read(FILE,$buff,2096)){
	print STDOUT $buff;
	}
	close (FILE);
	if($del eq 'del')
	{
		unlink($file);
	}
	exit;
}
sub get_user_info
{
	my $env = "$ENV{REMOTE_ADDR} $ENV{HTTP_USER_AGENT}";
	if($ENV{USER} eq 'root')
	{
	$securite_off = 1;
	$securite_setup{disable_env}='y';
	}
	
	my $module = $ENV{SCRIPT_NAME};
	my @module = split(/\//,$module);
	$module = pop @module;
	my $securite_off = 0;
	if($securite_setup{disable_security} eq 'y')
    {
		$securite_off = 1;
	}

	my $where_env = " AND env = '$env' AND env != '' ";
	if($securite_setup{disable_env} eq 'y')
    {
		$where_env = " ";
	}


	#read cookie info
	my %cookie_user_hash = ();
	my $cookie_user = $cgi->cookie($config{migc4_cookie});
	if($cookie_user ne "")
	{
		  $cookie_user_ref = decode_json $cookie_user;
		  %cookie_user_hash=%{$cookie_user_ref};
	}
	my $debug = 0;
	if($debug)
	{
		see(\%cookie_user_hash);
		print "cookie lu: $config{migc4_cookie}";
	}
	$debug = 0;
	
	#recevoir le token via la requete ajax (si pas de cookie lu)
	if($cookie_user_hash{token} eq '')
	{
		$cookie_user_hash{token} = $user_key;
	}
	
	#read user with corresponding token AND env
	my %user = sql_line({debug=>$debug,debug_results=>$debug,table=>"users",where=>"token='$cookie_user_hash{token}' and visible='y' $where_env AND token != '' "});
	
	#read role for user
	%migcms_role = sql_line({debug=>$debug,debug_results=>$debug,table=>"migcms_roles",where=>"id='$user{id_role}' and visible='y' and token != ''"});
	
	
	if($config{use_cluf} eq 'y' &&  $user{cluf_accepte} ne 'y' && get_quoted('sw') eq 'list')
	{
		see();
		
		my %txt = sql_line({debug=>0,debug_results=>0,table=>'migcms_textes_emails',where=>"id='16'"});
		
		my $cluf = get_traduction({debug=>0,id_language=>1,id=>$txt{id_textid_texte}});
		
		my $box = <<"EOH";
		<form method="post" action="">
		<input type="hidden" name="sw" value="save_cluf" />
		<input type="hidden" name="token_user" value="$user{token}" />
		
		<div class="row">
		<div class="col-md-3">
		</div>
		<div class="col-md-6">
		<h3>Veuillez accepter les conditions générales d'utilisation pour continuer:</h3>
		<div class="alert alert-success" role="alert" style="height:600px;overflow:auto;text-align:justify;">$cluf</div>
		
		<button type="submit" class="btn btn-success pull-right">J'ai lu et j'accepte les conditions générales d'utilisation</button>
		
		</div>
		<div class="col-md-3">
		</div>
		</div>
		
		</form>
EOH

		# display($box,$box,'no_menu');
		    my $page = display_set_canvas({content=>$box,menu=>$menu, title=>$title});
			print $page;

		exit;
	}
	
	# if($migcms_role{id} == 1)
	# {
		#si user system ou (droits simples et droit sur le module ok)
		# $securite_off = 1;
	# }
	
	#verifie que le sel correspond
	# my $sel = get_quoted('sel');
	# my $where_sel = "";
	# if($sel > 0)
	# {
		# $where_sel =" AND (id='$sel' OR id_father='$sel') ";
	# }
	# my %script = sql_line({debug=>$debug,debug_results=>$debug,dbh=>$dbh,table=>"scripts",where=>"url LIKE '$module%' $where_sel"});
	# if(!($script{id} > 0))
	# {
		# %script = sql_line({debug=>$debug,debug_results=>$debug,dbh=>$dbh,table=>"scripts",where=>"url LIKE '$module%'"});
	# }
	
	#droits simplifies
	# if($securite_setup{droits_simples} eq 'y')
	# {
		# if($script{'ok_role_'.$migcms_role{id}} eq 'y')
		# {
			# $securite_off = 1,
		# }
	# }
	
	#recupere le role pour ce sel
	
	
	# my %migcms_roles_detail = sql_line({debug=>$debug,debug_results=>$debug,select=>"id",table=>'migcms_roles_details',where=>"id_role='$migcms_role{id}' AND id_module='$script{id}' AND type_permission='view'"});
	# use Data::Dumper;
	# log_debug(Dumper(\%ENV),'','env');
	my $ok_REMOTE_ADDR = $config{public_ok_remote_addr} || '91.121.217.39'; #adresse ip publique du serveur '127.0.0.1';
	my $test_REMOTE_ADDR = $ENV{REMOTE_ADDR};
	my $ok_SERVER_ADDR = $config{public_ok_remote_addr} || '91.121.217.39'; #adresse ip publique du serveur '127.0.0.1';
	my $test_SERVER_ADDR = $ENV{SERVER_ADDR};
	my $ok_SERVER_ADDR2 = '91.121.217.39';
	my $ok_SERVER_ADDR3 = '127.0.0.1';
	
	if($user{id} > 0 && ($migcms_role{id} > 0 || $config{generer_droit_users} eq 'y'))
	{
		if($user{id_language} > 1 && $user{id_language} < 20)
		{
		}
		else
		{
			$user{id_language} = 1;
		}
		return (\%user);
	}
	elsif($ok_REMOTE_ADDR eq $test_REMOTE_ADDR && $ok_SERVER_ADDR eq $test_SERVER_ADDR)
	{
		#
	}
	elsif($test_SERVER_ADDR eq $ok_SERVER_ADDR2 || $test_SERVER_ADDR eq $ok_SERVER_ADDR3)
	{
		#
	}
	else
	{
		see();
		if($debug)
		{
			print "<b>error</b>";
			see(\%user);
			see(\%migcms_role);
			see(\%migcms_roles_details);
			exit;
		}
		if(!($user{id}>0))
		{
			# log_debug('4.1.1 NO USER ID'.Dumper(\%ENV),'','secu');
			http_redirect($config{baseurl}."/cgi-bin/fwauth.pl?");
			exit;
		}
		else
		{
			log_debug('4.1.2 USER FORBID','','secu');
			my $alert = get_alert({type=>"error",goto=>'login',display=>'sweet',title=>"Accès refusé", message=>"Vous ne disposez pas des autorisations pour accéder a cette section ($module)"});
			http_redirect($config{baseurl}."/cgi-bin/fwauth.pl?");
			# print $alert;
			exit;
		}
	}
}

sub get_file_icon
{
	my $ext = $_[0];
	my $pic_size = $_[1];
	my $icon_size = $_[2];
	my %migcms_linked_file = %{$_[3]};
	
	my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
	my $file_url_pic = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{name_mini};
	if($migcms_linked_file{name_mini} eq '')
	{
		$file_url_pic = $file_url;
	}

	
	if($pic_size eq '')
	{
		$pic_size = "width:100px;";
	}
	if($icon_size eq '')
	{
		$icon_size = "fa-3x";
	}
	
	
	my %icons = (
		'.docx'=>'fa-file-word-o',
		'.doc'=>'fa-file-word-o',
		'.xlsx'=>'fa-file-excel-o',
		'.xls'=>'fa-file-excel-o',
		'.pdf'=>'fa-file-pdf-o',
		'.jpg'=>'fa-file-image-o',
		'.jpeg'=>'fa-file-image-o',
		'.png'=>'fa-file-image-o',
		'.bmp'=>'fa-file-image-o',
		'.tiff'=>'fa-file-image-o',
		'.mp3'=>'fa-file-audio-o',
		'.mp4'=>'fa-file-movie-o',
		'.mov'=>'fa-file-movie-o',
		'.mpeg'=>'fa-file-movie-o',
		'.txt'=>'fa-file-text-o',
		'.ppt'=>'fa-file-powerpoint-o'
		);
		
		my $icon = '';
		if($ext eq '.jpg' || $ext eq '.JPG' || $ext eq '.jpeg' || $ext eq '.JPEG' || $ext eq '.png' || $ext eq '.PNG')
		{
			$icon = '<img style="'.$pic_size.'" src="'.$file_url_pic.'" alt ="'.$migcms_linked_file{full}.'" />';
		}
		else
		{
			if($icons{$ext} ne '')
			{
				$icon = '<i class="'.$icon_size.' fa '.$icons{$ext}.' fa-fw"></i>';
			}
			else
			{
				$icon = '<i class="fa fa-file-o fa-fw"></i>';
			}
		}
	return $icon;
}

sub refresh_files_admin
{
	if ($dm_cfg{custom_refresh_files_admin} ne "")
	{
		my $func = $dm_cfg{custom_refresh_files_admin};
		return &$func($_[0],$_[1],$_[2]);
	}

	my $token = get_quoted('token') || $_[0];
	my $colg = get_quoted('colg');
	my $table_name = get_quoted('table_name');
	my $alt = '';
	if($table_name eq '')
	{
		$table_name = $dm_cfg{table_name};
	}
	else
	{
		$alt = 'alt';
	}
	
	($token,$dum) = split(/Expires/,$token);
	my $filename = get_quoted('filename') || $_[1];
	my $file_prefixe = get_quoted('file_prefixe') || $_[2];
	my $suffix = '';
	if($file_prefixe ne '' && $token > 0)
	{
		$suffix = '/'.$file_prefixe.'/'.$filename.'/'.$token;
	}
    my $pic_dir = '../usr/files'.$suffix ;
	my $dir = $config{directory_path}.'/usr/files/'.$file_prefixe;
	unless (-d $dir) {mkdir($dir.'/') or die ("cannot create ".$dir.'/'.": $!");}
	my $dir = $config{directory_path}.'/usr/files/'.$file_prefixe.'/'.$filename;
	unless (-d $dir) {mkdir($dir.'/') or die ("cannot create ".$dir.'/'.": $!");}
	my $dir = $config{directory_path}.'/usr/files/'.$file_prefixe.'/'.$filename.'/'.$token;
	unless (-d $dir) {mkdir($dir.'/') or die ("cannot create ".$dir.'/'.": $!");}
	my @files_array = ();
	
	my $files_lines = '';
	my @files_list= ();
	my @migcms_linked_files = sql_lines({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='$table_name' AND table_field='$filename' AND token='$token' AND token > 0 AND table_field != '' AND table_name != ''",ordby=>'ordby'});
	foreach $migcms_linked_file (@migcms_linked_files)
	{
		my %migcms_linked_file = %{$migcms_linked_file};
		my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
		

		 my $col_cms = '';
		 my $icon = get_file_icon($migcms_linked_file{ext},'','',\%migcms_linked_file);

		my $sort_td = '<td><i class="fa fa-sort"></i></td>';
		if($alt eq 'alt')
		{
			$sort_td = '';
		}
		$files_lines .=<<"EOH";
			<tr id="$migcms_linked_file{id}">
				$sort_td
				<td>$icon</td>
				<td>
EOH

if($dm_cfg{page_cms} == 1 && $alt ne 'alt')
{

			my $text_pic_url = get_traduction({debug=>0,id_language=>$colg,id=>$migcms_linked_file{id_textid_url}});
			my $text_pic_legend = get_traduction({debug=>0,id_language=>$colg,id=>$migcms_linked_file{id_textid_legend}});
			$text_pic_legend =~ s/\"/&quot;/g;

			$files_lines .=<<"EOH";
					<table class="">
						<tr>
							<td colspan="2">
								<input type="text" disabled class="form-control disabled" value="$migcms_linked_file{full}$migcms_linked_file{ext}" />
							</td>
						</tr>
EOH
	if($dm_cfg{pic_url} == 1)
	{
		my $blank_checked = '';
		if($migcms_linked_file{blank} eq 'y')
		{
			$blank_checked = ' checked ';
		}
		
		$files_lines .=<<"EOH";
								<tr>
									<td>$migctrad{pic_clic_url}</td>
									<td>
										<div class="input-group">
											<input type="text" id="field_pic_url_$migcms_linked_file{id}" data-idlf="$migcms_linked_file{id}" name="pic_url_$migcms_linked_file{id}" class="form-control saveme saveme_txt autosave_lf_url" value="$text_pic_url" />
											<span class="input-group-btn">
												<a href="#" class="find_link_for_pic btn btn-default" id="pic_url_$migcms_linked_file{id}"><i class="fa fa-search"></i></a>
											</span>
										</div>
									</td>
								</tr>
								<tr>
									<td></td>
									<td>
											<label><input $blank_checked type="checkbox" data-idlf="$migcms_linked_file{id}" id="blank_$migcms_linked_file{id}" name="blank_$migcms_linked_file{id}" class=" cbsaveme autosave_lf_blank " value="y" /> Ouvrir dans une nouvelle fenêtre ? </label>
									</td>
								</tr>
EOH
	}


	if($dm_cfg{pic_alt} == 1)
	{
		$files_lines .=<<"EOH";
						<tr>
							<td>$migctrad{pic_alt}</td>
							<td>
								<input type="text" data-idlf="$migcms_linked_file{id}" name="pic_legend_$migcms_linked_file{id}" class="form-control saveme saveme_txt  autosave_lf_alt" value="$text_pic_legend" />
							</td>
						</tr>

EOH
	}

	$files_lines .=<<"EOH";
		</table>
EOH
}
else
{
	$files_lines .=<<"EOH";
					$migcms_linked_file{full}$migcms_linked_file{ext}
EOH
}

	 my $visibilite = '';
	 if($migcms_linked_file{visible} eq 'y')
      {
         $visibilite = <<"EOH";
<a href="$dm_cfg{self}&sw=ajax_changevislf" disabled data-placement="bottom" data-original-title="$migctrad{dm_make_visibleinvisible}  $pj_name" id="$migcms_linked_file{id}" role="button" class="btn btn-success  show_only_after_document_ready link_changevis_$dm_cfg{nolabelbuttons} link_changevislf link_changevislf_$migcms_linked_file{id}"><span class="fa fa-check  fa-fw"></span>$label</a>
EOH
     }
     else
     {
         $visibilite = <<"EOH";
		 <a href="$dm_cfg{self}&sw=ajax_changevislf" disabled data-placement="top" data-original-title="$migctrad{dm_make_visibleinvisible} $pj_name" id="$migcms_linked_file{id}" role="button" class="btn btn-warning  show_only_after_document_ready link_changevislf_$dm_cfg{nolabelbuttons} link_changevislf link_changevislf_$migcms_linked_file{id} set_visible toggle_visible"><span class="fa fa-ban fa-fw"></span>$label</a>
EOH
     }
	 
	 if($alt eq 'alt')
	 {
		$visibilite = '';
	 }

	$files_lines .=<<"EOH";
				</td>
				$col_cms
				<td>
					<a href="$file_url" data-placement="top" target="_blank" data-original-title="$migctrad{adm_preview}" id="" role="button" class=" btn btn-default  ">
						<i class="fa fa-fw fa-eye "></i>
					</a>
					$visibilite
					<!--
					<a href="#" data-placement="top" data-original-title="$migctrad{see}" id="" role="button" class=" btn btn-link disabled ">
						<i class="fa fa-fw fa-pencil "></i>
					</a>

					<a href="#" id="" data-placement="top" data-original-title="$migctrad{crop}" role="button" class="btn btn-link disabled " >
						<i class="fa fa-crop"></i>
					</a>	-->
					<a href="#" id="" title="$file" rel="$migcms_linked_file{id}" data-placement="top" data-original-title="$migctrad{delete}" role="button" class="list_del_file btn btn-danger">
						<i class="fa fa-trash-o fa-fw"></i>
					</a>
					
				</td>
			</tr>
EOH
	}
	 # my $cpt = 0;
     # foreach my $file (@files_array)
     # {
        # my $full_name = "$pic_path/$file";
		# my $file_url = $config{baseurl}.'/usr/files'.$suffix.'/'.$file;
		# my $rel = $suffix;
        # my @fileprop = stat $full_name;
        # if (-f $full_name)
        # {
		# my $size = $fileprop[7];
		# if($size > 999999)
		# {
		   # my $mb = $size / 1024 / 1024;
		   # $mb = sprintf("%.02f",$mb );
		   # $size = "$mb Mo";
		# }
		# elsif($size > 999)
		# {
		   # my $ko = $size / 1024 ;
		   # $ko = sprintf("%.02f",$ko );
		   # $size = "$ko Ko";
		# }
		# else
		# {
		   # $size = sprintf("%.02f",$size );
		   # $size .= " o";
		# }
		# my ($ext) = $file =~ /(\.[^.]+)$/;
		# my $icon = '';
		# if($icons{$ext} ne '')
		# {
			# $icon = '<i class="fa '.$icons{$ext}.' fa-fw"></i>';
		# }
		# else
		# {
			# $icon = '<i class="fa fa-file-o fa-fw"></i>';
		# }
		# $files_lines .=<<"EOH";
			# <tr>
				# <td>
					# $icon
					# <a href="$file_url" target="_blank">
						# $file
					# </a>
				# </td>
				# <td>
				# $size
				# </td>
				# <td>
					# <div class="btn-group btn-group-sm">
								# <a href="#" data-placement="top" data-original-title="Voir" id="" role="button" class=" btn btn-default hide">
									# <i class="fa fa-fw fa-eye "></i>
								# </a>
								# <a href="#" data-placement="top" data-original-title="Voir" id="" role="button" class=" btn btn-default hide">
									# <i class="fa fa-fw fa-pencil "></i>
								# </a>
								# <a href="#" id="" data-placement="top" data-original-title="Recadrer" role="button" class="btn btn-default hide" >
									# <i class="fa fa-crop"></i>
								# </a>
								# <a href="#" id="" title="$file" rel="$rel" data-placement="top" data-original-title="Supprimer" role="button" class="list_del_file btn btn-default">
									# <i class="fa fa-trash-o fa-fw"></i>
								# </a>
					# </div>
				# </td>
			# </tr>
# EOH
        # }
     # }
	 my $col_cms = '';
	 $dm_cfg{page_cms} = 0;
	 if($dm_cfg{page_cms} == 1 && $alt ne 'alt')
	 {
		$col_cms = '<th><i class="fa fa-link"></i> $migctrad{link} (URL)</th>';
	 }

	 my $sort_th = "<th>$migctrad{order}</th>";
	if($alt eq 'alt')
	{
		$sort_th = '';
	}
	 
	 my $file_list = <<"EOH";
		<br />
		<table id="$token" class="table table-sort table-condensed cf table-striped table-bordered">
			<thead>
				<tr>
					$sort_th
					<th>$migctrad{adm_preview}</th>
					<th>$migctrad{infos}</th>
					<th>$migctrad{actions}</th>
				</tr>
			</thead>
			<tbody class="sortable">
				$files_lines
			</tbody>
		</table>
EOH
		if($_[0] ne '')
		{		
			return $file_list;
		}
		else
		{
			print $file_list;
			exit;
		}
}

sub dm_after_upload_file
{
	# my $id_migcms_linked_file = $_[0];
	# if ($dm_cfg{after_upload_ref} ne "")
	# {
		# $fct = $dm_cfg{after_upload_ref};
		# my %id_migcms_linked_file = sql_line({table=>'migcms_linked_files',where=>"id='$id_migcms_linked_file'",select=>"token"});
		# &$fct($dbh,$id_migcms_linked_file{token});
	# }	
	# log_debug('dm_after_upload_file','','dm_after_upload_file');
	
	my $edit_id = get_quoted('edit_id');
	my $fieldname = get_quoted('fieldname');
	
	# log_debug($edit_id,'','dm_after_upload_file');
	# log_debug($fieldname,'','dm_after_upload_file');
	
	if ($edit_id > 0)
	{
		$fct = $dm_cfg{after_upload_ref};
		if($fct ne '')
		{
			&$fct($dbh,$edit_id,$fieldname);
		}
		exit;
	}
}

sub list_del_file
{
	see();
	my $id_migcms_linked_file = get_quoted('id_migcms_linked_file') || $_[0];
	my $edit_id = get_quoted('edit_id');
	my $file_name = get_quoted('file_name');
	my $table_name = get_quoted('table_name');
		
	my %migcms_linked_file = ();
	
	if($id_migcms_linked_file > 0)
	{
		%migcms_linked_file = read_table($dbh,'migcms_linked_files',$id_migcms_linked_file);
	}
	elsif($edit_id > 0 && $file_name ne '' && $table_name ne '')
	{
		%migcms_linked_file = sql_line({table=>'migcms_linked_files',where=>"file='$file_name' AND token='$edit_id' AND table_name ='$table_name'"});
	}
	
	


	#unlink file and thumbs
	my @cols = ('full','name_mini','name_small','name_medium','name_large','name_og');
	foreach my $col (@cols)
	{
		my $url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{$col};
		if($col eq 'full')
		{
			$url .= $migcms_linked_file{ext};
		}

		if(-e $url)
		{
			unlink($url);
		}
		else
		{
			#cant find
		}
	}

	$stmt = "delete FROM migcms_linked_files WHERE id = '$migcms_linked_file{id}' ";
	print $stmt;
	execstmt($dbh,$stmt);
	exit;
}

sub list_translations
{
	my %d = %{$_[0]};
	my $list = '';
	$list .=<<"EOH";
	<script>
	jQuery(document).ready(function()
	{
		tinymce.init({
					selector: ".trad",
					inline: true,
					toolbar: "undo redo | bold italic backcolor ",
					plugins:
					[
						"save textcolor autosave "
					],
					menubar: false,
					save_enablewhendirty: true,
					save_onsavecallback: translations_save,
				});
	});
	function translations_save()
	{
		  var id_editor = jQuery(this).attr('id');
		  var editor = jQuery("#"+id_editor);
		  var content = editor.html();
		  var id = editor.parent().attr('id');
		  console.log(content);
		  console.log(id);
			/*
		  jQuery.ajax(
		  {
			 type: "POST",
			 url: self,
			 data: "&sw=ajax_save_detail&id="+id+'&content='+encodeURIComponent(content),
			 success: function(msg)
			 {
					jQuery.bootstrapGrowl('<i class="fa fa-info"></i> $migctrad{text_saved} (Réf: #'+id+').', { type: 'success',align: 'center',
							width: 'auto' });
			 }
		  });
		  */
	}
	</script>
	<div class="btn-group btn-group-sm">
EOH
	my @languages = sql_lines({table=>'migcms_languages',where=>"visible='y' OR encode_ok = 'y'"});
	foreach $language (@languages)
	{
		my %language = %{$language};
		$list .=<<"EOH";
		<a class="btn btn btn-default" id="$language{id}" href="$config{baseurl}/adm_migcms_translations.pl?sel=160" title="" data-original-title="">$language{name}</a>
EOH
	}
	$list .=<<"EOH";
	</div>
	<div class="container">
	<div class="row">
		<div class="col-md-6 text-center">
			FR
		</div>
		<div class="col-md-6 text-center">
			NL
		</div>
	</div>
EOH
	my @lgs = (1,3);
	my @pages = sql_lines({debug=>0,debug_results=>0,table=>'migcms_pages',where=>"id NOT IN (select id_page from mailings)",ordby=>''});
	foreach $page (@pages)
	{
		my %page = %{$page};
		my @page_fields = qw(
			id_textid_name
			id_textid_meta_title
			id_textid_meta_keywords
			id_textid_meta_description
			id_textid_meta_url
			id_textid_url
		);
		my $i = 0;
		foreach my $page_field (@page_fields)
		{
			$col=0;
			# $row++;
			#nom de la page pour se situer
			# if($i == 0)
			# {
				# my ($pagename,$dum) = get_textcontent($dbh,$page{id_textid_name},1);
				# $list .= '<br>PAGE: '.$pagename;
			# }
			$col++;
			#boucle sur les champs traductibles de la PAGE
			my $no_data = 1;
			if($page{$page_field} > 0)
			{
				#id
				# $list .= '<br>ID: '.$page{$page_field};
				$list .= '<div class="row"><div class="col-md-12"></div>';
				#boucle sur le contenu des langues
				my $longueur = 0;
				foreach $language (@lgs)
				{
					my ($traduction,$dum) = get_textcontent($dbh,$page{$page_field},$language);
					$list .= '<div class="trad col-md-6"  style="border-right: 1px dashed #dddddd;">'.$traduction.'</div>';
				}
				$list .= '</div>';
				# if($longueur > 0)
				# {
					$row++;
				# }
			}
			$i++;
		}
		#boucle sur les champs traductibles du PARAG
		my @parags = sql_lines({debug=>0,debug_results=>0,table=>'parag',where=>"id_page = '$page{id}'",ordby=>'ordby'});
		foreach $parag (@parags)
		{
			my %parag = %{$parag};
			my @parag_fields = qw(
				id_textid_title
				id_textid_parag
			);
			foreach my $parag_field (@parag_fields)
			{
				$col=0;
				$col++;
				#boucle sur les champs traductibles
				my $is_data = 0;
				if($parag{$parag_field} > 0)
				{
					$list .= '<div class="row"><div class="col-md-12">'.$parag{$parag_field}.'</div>';
					#boucle sur les langues
					my $longueur = 0;
					foreach $language (@lgs)
					{
						my ($traduction,$dum) = get_textcontent($dbh,$parag{$parag_field},$language);
						$list .= '<div class="trad col-md-6">'.$traduction.'</div>';
					}
					$list .= '</div>';
					# if($longueur > 0)
					# {
						$row++;
					# }
				}
			}
		}
	}
	$list .= '</div>';
	if($d{view} eq 'cgi')
	{
		return $list;
	}
	else
	{
		print $list;
		exit;
	}
}
sub list_files
{
	my %d = %{$_[0]};
	my $list = '';
	my $dir = get_quoted('dir');
	my $pick_link = get_quoted('pick_link');
	$dir .= '/';
	my $url_home = $dm_cfg{self};
	my $url_dir = $dm_cfg{self}.'&dir='.$dir;
	my $dir_display = $dir;
	$dir_display =~ s/^\///g;
	my $breadcrumb = '';
	if($pick_link ne 'y')
	{
		$breadcrumb= <<"EOH";
		<ol class="breadcrumb">
			<li><a href="$url_home">$migctrad{my_files}</a></li>
EOH
		if($dir ne '/')
		{
			$breadcrumb .= <<"EOH";
				<li><a href="$url_dir">$dir_display</a></li>
EOH
		}
		$breadcrumb .= <<"EOH";
				</ol>
EOH
	}
    my $root_dir = '../usr';
	my $root_path = $config{directory_path}.'/usr';
	my $root_url = $config{baseurl}.'/usr';
	unless (-d $root_path) {mkdir($root_path.'/') or die ("cannot create ".$root_path."/: $!");}
	my @files_array = ();
	opendir (MYDIR, $root_path.$dir) || die ("cannot LS $root_path");
	@files_array = readdir(MYDIR);
	closedir (MYDIR);
	my $files_lines = '';
	my @files_list= ();
	 my $cpt = 0;
     foreach my $file (@files_array)
     {
        if($file eq '.' || $file eq '..')
		{
			next;
		}
	    my $full_name = $root_path.$dir.$file;
		my $file_url = $root_url.$dir.$file;
        my @fileprop = stat $full_name;

        if ($full_name ne '')
        {
			my $size = $fileprop[7];
			if($size > 999999)
			{
			   my $mb = $size / 1024 / 1024;
			   $mb = sprintf("%.02f",$mb );
			   $size = "$mb Mo";
			}
			elsif($size > 999)
			{
			   my $ko = $size / 1024 ;
			   $ko = sprintf("%.02f",$ko );
			   $size = "$ko Ko";
			}
			else
			{
			   $size = sprintf("%.02f",$size );
			   $size .= " o";
			}
			my ($ext) = $file =~ /(\.[^.]+)$/;
			my %icons = (
			''=>'fa fa-folder',
			'.docx'=>'fa-file-word-o',
			'.doc'=>'fa-file-word-o',
			'.xlsx'=>'fa-file-excel-o',
			'.xls'=>'fa-file-excel-o',
			'.pdf'=>'fa-file-pdf-o',
			'.jpg'=>'fa-file-image-o',
			'.jpeg'=>'fa-file-image-o',
			'.png'=>'fa-file-image-o',
			'.bmp'=>'fa-file-image-o',
			'.tiff'=>'fa-file-image-o',
			'.mp3'=>'fa-file-audio-o',
			'.mp4'=>'fa-file-movie-o',
			'.mov'=>'fa-file-movie-o',
			'.mpeg'=>'fa-file-movie-o',
			'.txt'=>'fa-file-text-o',
			'.ppt'=>'fa-file-powerpoint-o'
			);
			my $icon = '';
			if($icons{$ext} ne '')
			{
				$icon = '<i class="fa fa-3x '.$icons{$ext}.' fa-fw"></i>';
			}
			else
			{
				$icon = '<i class="fa fa-3x fa-file-o fa-fw"></i>';
			}
			my $target = "_blank";
			my $action_download = <<"EOH";
			<a href="$file_url" target="$target" data-placement="top" data-original-title="$migctrad{seedownload}" id="" role="button" class=" btn btn-default ">
										<i class="fa fa-fw fa-eye "></i>
									</a>
EOH
			if($ext eq '')
			{
				$target = '';
				$file_url = $dm_cfg{self}.'&dir='.$dir.$file;
				$action_download = '';
				if($pick_link eq 'y')
				{
					next;
				}
			}
			my $actions_image = <<"EOH";
				<a href="#" id="" data-placement="top" disabled data-original-title="$migctrad{crop}" role="button" class="disabled btn btn-default " >
					<i class="fa fa-crop"></i>
				</a>
EOH
			$files_lines .=<<"EOH";
				<tr>
					<td class="only_pick_link_$pick_link ">
						<input type="radio" name="pick_link" class="pick_link" rel="$file_url" />
					</td>
					<td>
						<a href="$file_url" target="$target">
							$icon
							$file
						</a>
					</td>
					<td class="pick_link_$pick_link">
					$size
					</td>
					<td class="text-right pick_link_$pick_link">
								$action_download
								$actions_image
								<a href="#" id="" title="$file" rel="$rel" data-placement="top" data-original-title="$migctrad{delete}" role="button" class="list_del_file btn btn-primary">
									<i class="fa fa-trash-o fa-fw"></i>
								</a>
					</td>
				</tr>
EOH
        }
     }
	 my $file_list = <<"EOH";
	<style>
	.fa-folder
	{
		color:#5bc0de!important;
	}
	.fa-file-image-o
	{
		color:#333333;
	}
	.fa-file-excel-o
	{
		color:#38892e;
	}
	.fa-file-word-o
	{
		color:#0e66c3;
	}
	.pick_link_y, .only_pick_link_
	{
		display:none!important;
	}
</style>
$breadcrumb
	<table class="table  table-condensed cf table-hover" style="background-color:white">
<tr>
	<th class="only_pick_link_$pick_link"></th>
	<th></th>
	<th style="width:150px;" class="pick_link_$pick_link">Taille</th>
	<th style="width:250px;" class="pick_link_$pick_link">Actions</th>
</tr>
$files_lines
</table>
EOH
	if($d{view} eq 'cgi')
	{
		return $file_list;
	}
	else
	{
		print $file_list;
		exit;
	}
}
sub update_text
{
	my $dbh = $_[0];
	my $id_textid = $_[1];
	my $txt = $_[2];
	my $lg = $_[3] || $config{current_language};
	if(!($lg > 0 && $lg < 10))
	 {
		$lg = $config{current_language} = 1;
	 }
	my $force_update = $_[4];
	my $txt_src = $_[5];
	my $debug = $_[6];
	my $table_txt_src = 'txtcontents';
	if($txt_src ne '' && $txt_src ne 'undefined')
	{
		$table_txt_src = $txt_src.'_'.$table_txt_src;
	}
	my %check = sql_line({debug=>0,dbh=>$dbh,table=>$table_txt_src,select=>"id",where=>"id='$id_textid'"});
	if($check{id} > 0)
	{
	$stmt = "UPDATE $table_txt_src SET lg$lg = '$txt' WHERE id = '$id_textid'";
	if($debug)
	{
	  print $stmt;
	}
	execstmt($dbh,$stmt);
	}
	else
	{
	$id_textid = insert_text($dbh,"$txt",$lg,$txt_src,$debug);
	}
	return $id_textid;
}
################################################################################
# INSERT_TEXT
################################################################################
sub insert_text
{
     my $dbh = $_[0];
     my $txt = $_[1];
     my $lg = $_[2] || $config{current_language};
	 if(!($lg > 0 && $lg < 10))
	 {
		$lg = $config{current_language} = 1;
	 }
     my $txt_src = $_[3];
     my $debug = $_[4];
         my $table_txt_src = 'txtcontents';
         if($txt_src ne '' && $txt_src ne 'undefined')
         {
            $table_txt_src = $txt_src.'_'.$table_txt_src;
         }
         $stmt = "INSERT INTO $table_txt_src (lg$lg) VALUES ('$txt')";
         if($debug == 1)
         {
          print $stmt;
         }
         execstmt($dbh,$stmt);
         my $id_textid = $dbh->{'mysql_insertid'};
         return $id_textid;
}

sub get_operations_div
{
	my $actions_div = <<"EOH";
	<div class="row">
		<div class="col-md-12 text-right">
								<a data-placement="bottom" data-original-title="$migctrad{back}" data-dismiss="modal" aria-label="Close"  class="btn btn-sm btn-default show_only_after_document_ready cancel_edit c5" aria-hidden="true">$ICONCANCEL</a>

		</div>
	</div>
	<div class="tab-pane" id="tab_mig_list_actions">
		<div class="panel panel-success">
			<div class="panel-heading"><i class="fa fa-cloud-download"></i> $migctrad{exp_data} </div>
			<div class="panel-body">
				<div class="help-block text-left">
					<i class="fa fa-info-circle"></i>
					$migctrad{reimportdata_info}
				</div>
				<a class="btn btn-lg btn-success" id="export_excel" style="" data-placement="" data-original-title="">
					<i class="fa fa-file-excel-o"></i>
					$migctrad{download_to_excel}
				</a>
				<a class="btn btn-lg btn-success" id="export_txt" style="" data-placement="" data-original-title="">
					<i class="fa fa-file-text-o"></i>
					$migctrad{download_to_textformat}
				</a>
				<!--
				<a class="btn btn-lg btn-success" id="export_csv" style="" data-placement="" data-original-title="">
					<i class="fa fa-file-csv-o"></i>
					Télécharger au format CSV
				</a>
				-->
			</div>
		</div>
		<div class="panel panel-success">
			<div class="panel-heading"><i class="fa fa-cloud-upload"></i> $migctrad{imp_data} </div>
				<div class="panel-body">
					<form method="post" enctype="multipart/form-data" action="$dm_cfg{self}">
						<div class="help-block text-left">
							<i class="fa fa-info-circle"></i>
							$migctrad{importdata_info}
						</div>
						<input type="file" name="import_excel" />
						<input type="hidden" name="sel" value="$sel" />
						<input type="hidden" name="sw" value="import_excel" />
						<br />
						<button type="submit" class="btn btn-lg btn-success"> $migctrad{import} </button>
					</form>
				</div>
			</div>
	<div class="row">
		<div class="col-md-12 text-right">
								<a data-placement="bottom" data-original-title="$migctrad{back}" class="btn btn-sm btn-default show_only_after_document_ready cancel_edit c6" data-dismiss="modal" aria-label="Close" aria-hidden="true">$ICONCANCEL</a>

		</div>
	</div>
EOH
	print $actions_div;
	exit;
}

sub set_new_ordby_linked_files
{
	see();
	my $new_position = get_quoted('new_position');
	my $id_element = get_quoted('id_element'); #id de la piece jointe
	my $id_record = get_quoted('id_record'); #id global du record pour ttes les pieces jointes
	my $table_name = get_quoted('table_name');
	$new_position++;
	if($id_record > 0 && $table_name ne '' && $new_position > 0 && $id_element > 0)
	{
		$stmt = "UPDATE migcms_linked_files SET ordby = ordby + 1 WHERE table_name = '$table_name' AND token = '$id_record' AND ordby >= $new_position";
		execstmt($dbh,$stmt);
		# log_debug($stmt,'','set_new_ordby_linked_files');
	    $stmt = "UPDATE migcms_linked_files SET ordby = $new_position WHERE id = '$id_element' AND table_name = '$table_name' AND token = '$id_record'  ";
		execstmt($dbh,$stmt);
		# log_debug($stmt,'','set_new_ordby_linked_files');
	}
	my $new_ordby = 1;
    my @table = sql_lines({debug=>1,debug_results=>1,dbh=>$dbh,table=>'migcms_linked_files',,ordby=>"ordby",where=>"table_name = '$table_name' AND token = '$id_record'"});
    foreach $rec (@table)
    {
      my %rec = %{$rec};
      $stmt = "UPDATE migcms_linked_files SET ordby = '$new_ordby' WHERE id ='$rec{id}'";
	  # log_debug($stmt,'','set_new_ordby_linked_files');
	  execstmt($dbh,$stmt);
      $new_ordby++;
   }
	exit;
}

sub get_list_of_cols
{
    my $dbh_r = $_[2];
	#list of COLS
    my @list_of_cols =();
    my $stmt_list_of_cols = "SELECT COLUMN_NAME, DATA_TYPE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA ='$_[0]' AND table_name = '$_[1]'";
    my $cursor_list_of_cols = $dbh_r->prepare($stmt_list_of_cols) || die("CANNOT PREPARE $stmt_list_of_cols");
    $cursor_list_of_cols->execute || suicide($stmt_list_of_cols);
    while ($ref_rec = $cursor_list_of_cols->fetchrow_hashref())
    {
        push @list_of_cols,\%{$ref_rec};
    }
    $cursor_list_of_cols->finish;
    return @list_of_cols;
}
sub get_list_of_tables
{
    #list of TABLES
    my $dbh_r = $_[1];
	my @list_of_tables =();
    my $stmt_list_of_tables = "SELECT t.TABLE_NAME AS stud_tables FROM INFORMATION_SCHEMA.TABLES AS t WHERE t.TABLE_TYPE = 'BASE TABLE' AND t.TABLE_SCHEMA = '$_[0]'";
    my $cursor_list_of_tables = $dbh_r->prepare($stmt_list_of_tables) || die("CANNOT PREPARE $stmt_list_of_tables");
    $cursor_list_of_tables->execute || suicide($stmt_list_of_tables);
    while ($ref_rec = $cursor_list_of_tables->fetchrow_hashref())
  	{
        push @list_of_tables,$ref_rec->{stud_tables};
  	}
  	$cursor_list_of_tables->finish;
    return @list_of_tables;
}

sub default_before_save
{
    my $id = $_[0];

	#contruit le hash item selon les regles
	my %item = ();

	my $debug = 1;
	
	if($debug)
	{
	 # use Data::Dumper;
	 # log_debug(Dumper(\%dm_dfl),'vide','default_before_save');
	}
	
	delete $dm_dfl{'00001/id'};
	delete $dm_dfl{'00002/migcms_moment_create'};
	delete $dm_dfl{'00003/migcms_id_user_create'};
	
	
	
	foreach $key (keys(%dm_dfl))
	{
		my ($num,$field) = split(/\//,$key);
		$item{$field} = trim(get_quoted($field));
		if($debug)
		{	
			# log_debug($key.':'.$dm_dfl{$key}{fieldtype}.':'.$field.':'.$item{$field},'','default_before_save');
		}
		
		if($dm_dfl{$key}{fieldtype} eq 'adresse')
		{
			# my @adresse_fields = split(/\,/,$dm_dfl{$key}{adresse_fields});
		    # foreach my $adresse_field (@adresse_fields)
			# {
				# $item{$adresse_field} = trim(get_quoted($adresse_field));
			# }
			next;
		}
		
		if($dm_dfl{$key}{data_type} eq '' && $dm_dfl{$key}{datatype} ne '')
		{
			$dm_dfl{$key}{data_type} = $dm_dfl{$key}{datatype};
		}
		
		if($debug)
		{
			# log_debug("avant: $field: ".$item{$field}.' key:['.$key.'] fieldtype:['.$dm_dfl{$key}{fieldtype}.'] data_type:['.$dm_dfl{$key}{data_type}.'] multiple:['.$dm_dfl{$key}{multiple}.']','','default_before_save');
		}
		
		

		if($dm_dfl{$key}{fieldtype} eq "listboxtable" && $dm_dfl{$key}{data_type} eq "treeview" && $dm_dfl{$key}{multiple} eq '0')
		 {
			$item{$field} =~ s/\D//g;
		 }
		elsif($dm_dfl{$key}{fieldtype} eq "listboxtable" && $dm_dfl{$key}{data_type} eq "treeview")
		{
			#enleve les préfixes
			my @t = split(/,/,$item{$field});
			my @t2 = ();
			foreach my $t (@t)
			{
				my @ttmp = split(/_/,$t);
				push @t2,pop @ttmp;
			}
			$item{$field} = join(",",@t2);
		 }

		if($dm_dfl{$key}{fieldtype} eq "pic" || $dm_dfl{$key}{fieldtype} eq "file")
		{
			$item{$field} = $cgi->param($field);
		}
		if($dm_dfl{$key}{fieldtype} eq "files_admin" || $dm_dfl{$key}{fieldtype} eq "titre" || $dm_dfl{$key}{fieldtype} eq "func")
		{
			delete $item{$field};
		}
		
		
		
		if($dm_dfl{$key}{data_type} eq "password" || $dm_dfl{$key}{datatype} eq "password")
		{
			if($item{$field} ne '')
			{
				$item{$field} = sha1_hex($item{$field});
			}
			else
			{
				delete $item{$field};
			}
		}
		
	
		
		if($dm_dfl{$key}{data_type} eq "iban" || $dm_dfl{$key}{datatype} eq "iban" || $dm_dfl{$key}{data_type} eq "bic" || $dm_dfl{$key}{datatype} eq "bic")
		{
			$item{$field} = uc($item{$field});
		}
		
		if($dm_dfl{$key}{data_type} eq "euros" || $dm_dfl{$key}{data_type} eq "number")
		{
			$item{$field} =~ s/\,/\./g;
		}
		
		if(($dm_dfl{$key}{disable_update} == 1) && $id > 0)
		{
			if($debug)
			{	
				# log_debug($field.':'.$item{$field}.': supprimé car disable_update=1','','default_before_save');
			}
			delete $item{$field};
		}
		
		
		if($dm_dfl{$key}{fromadresse} ne 'y' && $dm_dfl{$key}{fieldtype} eq "display")
		{
			if($debug)
			{	
				# log_debug($field.':'.$item{$field}.': supprimé car display:'.$dm_dfl{$key}{fromadresse},'','default_before_save');
			}
			delete $item{$field};
		}

		if($dm_dfl{$key}{frontend_only} eq 'y')
		{
			if($debug)
			{	
				# log_debug($field.':'.$item{$field}.': supprimé car frontend_only','','default_before_save');
			}
			delete $item{$field};
		}
		
		if($debug)
		{
			# log_debug("après: $field: ".$item{$field},'','default_before_save');
		}
	}
	
	if($debug)
	{
	 # log_debug(Dumper(\%item),'','default_before_save');
	}
	return \%item;
}


sub create_col_in_table
{
  my $dbh=$_[0];
  my $table=$_[1];
  my $col=$_[2];
  my $type=$_[3];
  my $action=$_[4] || "ADD";
  my $type_stmt = "";
  if($type eq 'enum_y_n')
  {
     $type_stmt=" ENUM( 'y', 'n' ) NOT NULL DEFAULT 'n' ";
  }
  elsif($type eq 'enum_n_y')
  {
     $type_stmt=" ENUM( 'y', 'n' ) NOT NULL DEFAULT 'y' ";
  }
  elsif($type eq 'text')
  {
     $type_stmt=" TEXT NOT NULL ";
  }
  elsif($type eq 'change_text')
  {
     $type_stmt=" TEXT CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL  ";
  }
  elsif($type eq 'datetime')
  {
     $type_stmt=" DATETIME NOT NULL ";
  }
  elsif($type eq 'date')
  {
     $type_stmt=" DATE NOT NULL ";
  }
  elsif($type eq 'time')
  {
     $type_stmt=" TIME NOT NULL ";
  }
  elsif($type eq 'int')
  {
     $type_stmt=" INT NOT NULL ";
  }
  elsif($type eq 'int_1')
  {
     $type_stmt=" INT NOT NULL  DEFAULT '1'  ";
  }
  elsif($type eq 'varchar')
  {
     $type_stmt=" VARCHAR( 255 ) NOT NULL  ";
  }
  elsif($type eq 'float')
  {
     $type_stmt=" FLOAT NOT NULL  ";
  }
  elsif($type eq 'float_0.21')
  {
     $type_stmt=" FLOAT NOT NULL DEFAULT '0.21'  ";
  }
  elsif($type eq 'shop_order_status')
  {
     $type_stmt=" ENUM( 'new', 'begin', 'current', 'finished', 'unfinished', 'cancelled' ) NOT NULL DEFAULT 'new' AFTER `id`  ";
  }
  elsif($type eq 'shop_payment_status')
  {
     $type_stmt=" ENUM( 'wait_payment', 'captured', 'paid', 'repaid', 'cancelled' ) NOT NULL DEFAULT 'wait_payment' AFTER `shop_order_status`  ";
  }
  elsif($type eq 'shop_delivery_status')
  {
     $type_stmt=" ENUM( 'current', 'ready', 'partial_sent', 'full_sent', 'cancelled','ready_to_take' ) NOT NULL DEFAULT 'current' AFTER `shop_payment_status`   ";
  }
  elsif($type eq 'longtext')
  {
	$type_stmt =" longtext NOT NULL ";
  }
  my @test=get_describe($dbh,$table);
  if($#test == -1)
  {
      return 0;
  }
  for($t=0;$t<$#test+1;$t++)
  {
      my %line=%{$test[$t]};
      if($line{Field} eq $col)
      {
        return 0;
      }
  }
  my $stmt = "ALTER TABLE `$table` $action `$col` $type_stmt";
  my $cursor = $dbh->prepare($stmt);
  my $rc = $cursor->execute;
  if (!defined $rc)
  {
      see();
      print "[$stmt]";
      exit;
  }
  return 1;
}


sub migcms_build_compute_urls_dm_old
{
	# $stmt = "delete FROM `migcms_urls` WHERE nom_table IN ('data_search_form','data_listcat_form','migcms_pages','data_categories','migcms_urls_common')";
	# $cursor = $dbh->prepare($stmt);
	# $rc = $cursor->execute;
	$stmt = "TRUNCATE `migcms_urls` ";
	$cursor = $dbh->prepare($stmt);
	$rc = $cursor->execute;

	#construit les URLS rew dans la DB
	my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible='y'"});
	foreach $language (@languages)
	{
		my %language = %{$language};

		#PAGES****************************************************************************************************
		my @migcms_pages = sql_lines({debug=>0,debug_results=>0,table=>'migcms_pages',where=>"migcms_pages_type != 'newsletter' && migcms_pages_type != 'link' && migcms_pages_type != 'block' && migcms_pages_type != 'handmade'"});
		foreach $page (@migcms_pages)
		{
			my %page = %{$page};

			my $texte_url = get_traduction({debug=>0,id=>$page{id_textid_url},id_language=>$language{id}});
			if($texte_url eq '')
			{
				$texte_url = get_traduction({debug=>0,id=>$page{id_textid_name},id_language=>$language{id}});
				if($texte_url eq '')
				{
					$texte_url = $page{id}.'_'.$language{id};
				}
			}
			set_traduction({id_language=>$language{id},traduction=>$texte_url,id_traduction=>$page{id_textid_url},table_record=>'migcms_pages',col_record=>'id_textid_url',id_record=>$page{id}});

			#on forme la nouvelle url: langue / url
			my $url_rewriting = $language{name}.'/'.$texte_url;
			save_url($url_rewriting,'migcms_pages',$page{id},$texte_url,\%language);
		}

		# FAMILLES + MOTEURS ****************************************************************************************************
		my @data_families = sql_lines({table=>'data_families',where=>""});
		foreach my $data_family (@data_families)
		{
			my %data_family = %{$data_family};

			my @data_search_forms = sql_lines({debug=>0,debug_results=>0,table=>'data_search_forms',where=>"id_data_family='$data_family{id}'"});
			foreach my $data_search_form (@data_search_forms)
			{
				%data_search_form = %{$data_search_form};
				($texte_url_moteur,$dum) = get_textcontent($dbh,$data_search_form{id_textid_url_rewriting},$language{id});
				if($texte_url_moteur ne '')
				{
					my $url_rewriting = $language{name}.'/'.$texte_url_moteur;
					save_url($url_rewriting,'data_search_form',$data_search_form{id},$texte_url_moteur,\%language);
					my $url_rewriting = $language{name}.'/categories/'.$texte_url_moteur;
					save_url($url_rewriting,'data_listcat_form',$data_search_form{id},$texte_url_moteur,\%language);
				}
			}
		}

		# CATEGORIES ****************************************************************************************************
		my @data_categories = sql_lines({table=>'data_categories',where=>""});
		foreach my $data_category (@data_categories)
		{
			my %data_category = %{$data_category};

			($texte_cat,$dum) = get_textcontent($dbh,$data_category{id_textid_url_rewriting},$language{id});
			if($texte_cat ne '')
			{
				my $url_rewriting = $texte_cat;
				save_url($url_rewriting,'data_categories',$data_category{id},$texte_cat,\%language);
			}
		}
		
		
		#URLS COMMUNES SYNCHRONISEES (boutique,membres,...)
		my @migcms_urls_commons = sql_lines({debug=>0,debug_results=>0,select=>"u.*,l.*,l.id as id_language,u.id as id_url",table=>'migcms_urls_common u,migcms_languages l',where=>"u.id_language=l.id"});
		foreach my $migcms_urls_common (@migcms_urls_commons)
		{
				my %migcms_urls_common = %{$migcms_urls_common};
				
				#fr/boutique/fin/succes
				my $url_rewriting = $migcms_urls_common{name}.'/'.$migcms_urls_common{url_rewriting};
				
				#fr/boutique/fin/succes/*(.*)
				my $url_rewriting_htaccess = $migcms_urls_common{name}.'/'.$migcms_urls_common{url_rewriting}.'/*(.*)';
				
				#cgi-bin/eshop.pl?sw=end&lg=1&status=success&token=$1
				my $url_base = $migcms_urls_common{url};
				
				my %language = ();
				$language{id} = $migcms_urls_common{id_language};
				
				if($url_rewriting ne '' && $url_rewriting_htaccess ne '' && $url_base ne '')
				{
					save_url($url_rewriting,'migcms_urls_common',$migcms_urls_common{id_url},$url_rewriting,\%language,$url_rewriting_htaccess,$url_base);
				}
		}

		# if($language{id}> 0 && $language{id} < 4)
		# {
			
			
			
			
			# ESHOP
			# my %eshop_setup = sql_line({table=>'eshop_setup'});
			# if($eshop_setup{id} > 0 && $eshop_setup{shop_disabled} ne 'y')
			# {
				# my %eshop_shopcodes =
				# (
					# 1 => 'boutique',
					# 2 => 'shop',
					# 3 => 'winkel',
				# );

				# fill_migcms_urls_from_csv({module_code=>\%eshop_shopcodes, outfile=>'../cgi-bin/eshop_urls.csv', lg=>$language{id}});
			# }

			# MEMBERS
			# my %members_setup = sql_line({table=>'members_setup'});
			# if($members_setup{id} > 0 && $members_setup{shop_disabled} ne 'y')
			# {
				# my %members_shopcodes =
				# (
					# 1 => 'membre',
					# 2 => 'member',
					# 3 => 'lid',
				# );

				# fill_migcms_urls_from_csv({debug=>0,module_code=>\%members_shopcodes, outfile=>'../cgi-bin/members_urls.csv', lg=>$language{id}});
			# }
		# }
	}
}


sub save_url_dm_old
{
	my $url_rewriting = $_[0];
	my $nom_table = $_[1];
	my $id_table = $_[2];
	my $texte_url = $_[3];
	my %language = %{$_[4]};
	
	my $url_rewriting_htaccess = $_[5];
	my $url_base = $_[6];
	
	$url_rewriting = clean_url($url_rewriting,'y');

	

	
	# boucle pour éviter doublons d'url
	# my %check_url = sql_line({table=>'migcms_urls',where=>"url_rewriting='$url_rewriting' AND id_table != '$id_table'"});
	my %check_url = sql_line({debug=>0,debug_results=>0,table=>'migcms_urls',where=>"url_rewriting='$url_rewriting'"});
	my $suffix = 2;
	my $new_url_rewriting = $url_rewriting;
	while($check_url{id} > 0)
	{
		$new_url_rewriting = $url_rewriting.$suffix;
		%check_url = sql_line({debug=>0,debug_results=>0,table=>'migcms_urls',where=>"url_rewriting='$new_url_rewriting'"});
		$suffix++;
	}

	#maj de l'url
	my %migcms_url =
	(
		'nom_table' => $nom_table,
		'id_table' => $id_table,
		'id_lg' => $language{id},
		'words' => $texte_url,
		'url_rewriting' => $new_url_rewriting,
	);
	$migcms_url{words}  =~ s/\'/\\\'/g;
	
	if($url_rewriting_htaccess ne '')
	{
		$migcms_url{url_rewriting_htaccess} = $url_rewriting_htaccess;
	}
	if($url_base ne '')
	{
		$migcms_url{url_base} = $url_base;
	}

	sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_urls',data=>\%migcms_url, where=>"nom_table='$migcms_url{nom_table}' AND id_table='$migcms_url{id_table}'  AND id_lg='$migcms_url{id_lg}'"});
}




sub get_publish_pdf_html_add_page
{
	my %d = %{$_[0]};
	
	my %license = %{$d{license}};
	my %record = %{$d{record}};
	my $nouvelle_page = '';
	
	my %html = sql_line({table=>'migcms_textes_emails',where=>"table_name='bloc client'"});
	my $bloc_client = get_traduction({debug=>0,id=>$html{id_textid_raw_texte},id_language=>$config{current_language}});
	my %html = sql_line({table=>'migcms_textes_emails',where=>"table_name='page content'"});
	my $bloc_page = get_traduction({debug=>0,id=>$html{id_textid_raw_texte},id_language=>$config{current_language}});
	my $pj_name = getcode($dbh,$d{id_record},$d{prefixe});
	
	
	$facture_ligne_bas{html} = <<"EOH";
			<tr class="{hide_class}">
					<td class="facture-table-col2" colspan="3"><b>{libelle} </b></td>
					<td class="facture-table-col5 text-right"><b>{ligne_total_htva}</b></td>
			</tr>
EOH

	$facture_ligne_bas_1col{html} = <<"EOH";
					<tr class="{hide_class}" style="border:0px!important; text-transform:none!important;">
							<td class="facture-table-col2  text-center" colspan="4"  style="border:0px!important; text-transform:none!important;"><b style="text-transform:none!important;">{libelle} </b></td>
					</tr>
EOH

	$facture_ligne_tableau{html} = <<"EOH";
		<tr class="{hide_class}">
			<td class="facture-table-col2">{libelle} <i>{remarque}</i></td>
			<td class="facture-table-col3" style="width:30px;">{qte}</td>
			<td class="facture-table-col4 text-right" style="width:80px;text-align:right!important;">{puhtva}</td>
			<td class="facture-table-col5 text-right" style="width:80px;text-align:right!important;">{ligne_total_htva}</td>
			<td class="facture-table-col5 text-right" style="width:80px;text-align:right!important;">{ligne_taux_tva}</td>
		</tr>	
EOH

	if($d{type} eq 'publication_tableau')
	{
		my $nb_lignes = 999;
		my $nb_max_lignes = 22;
		my $debut = 1;
		
		my $page_title = trim($dm_cfg{page_title}) || "";
		if($dm_cfg{page_title} eq '')
		{
			my %script = read_table($dbh,"scripts",get_quoted('sel'));
			my $traduction_titre = get_traduction({debug=>0,id=>$script{id_textid_name},id_language=>$config{current_language}});
			$page_title = $dm_cfg{page_title} = $traduction_titre;
			if($traduction_titre eq '')
			{
				$page_title = $dm_cfg{page_title} = $script{name};
			}
		}	
		my $titre = $page_title;

		
		my $page_content = <<"EOH";	
			<table class="table table-bordered">
EOH
		
		  #génération des lignes à partir de %dm_dfl
		  my $nb_total_de_lignes = keys %dm_dfl;
		  my $ligne_actuelle = 0;
		  
	
		  
		  
		  foreach my $dm_dfl_line (sort keys %dm_dfl)
		  {  		
				
								

				if($dm_dfl_line eq '00001/id' && $dm_cfg{pdf_no_id} == 1)
				{
					$nb_total_de_lignes--;
					next;					
				}
				if($dm_dfl_line eq '00002/migcms_moment_create' && $dm_cfg{pdf_no_migcms_moment_create} == 1)
				{
					$nb_total_de_lignes--;
					next;					
				}
				if($dm_dfl_line eq '00003/migcms_id_user_create' && $dm_cfg{pdf_no_migcms_id_user_create} == 1)
				{
					$nb_total_de_lignes--;
					next;
				}
				 $ligne_actuelle++;
				
				
				if(($debut == 0 && $nb_lignes >= $nb_max_lignes) || $ligne_actuelle == $nb_total_de_lignes)
				{
					$page_content .= <<"EOH";	
						</table>
EOH
					$d{head} .= get_publish_pdf_html_add_bloc_head({size=>'858',number=>$d{number}});
					if($nb_lignes > 0 )
					{
						$nouvelle_page .= get_publish_pdf_html_add_page_content({titre=>$titre,content=>"<br /> $page_content",table_record=>$d{table_record},bloc_page=>$bloc_page,license=>\%license,record=>\%record,document=>\%document,ctm=>\%ctm,sys=>\%sys,facture_ligne_bas_1col=>$facture_ligne_bas_1col{html},facture_ligne_bas=>$facture_ligne_bas{html},number=>$d{number}++,prefixe=>$d{prefixe},pj_name=>$pj_name});
						$d{number}++;
					}
					
				}
				
				if($nb_lignes >= $nb_max_lignes)
				{
					$nb_lignes = 0;
					$page_content = <<"EOH";	
						<table class="table table-bordered">
EOH
				}
				
				($nouvelle_ligne,$nb_lignes) = get_publish_pdf_html_get_champs_valeur({record=>\%record,nb_lignes=>$nb_lignes,dm_dfl_line=>$dm_dfl_line,prefixe=>$d{prefixe}});
				
				
				$page_content .= $nouvelle_ligne;
		
				$debut = 0;
				
		}
		
	}
	elsif($d{type} eq 'content')
	{
		$d{head} .= get_publish_pdf_html_add_bloc_head({size=>'813.5',number=>$d{number}++});
		$nouvelle_page = get_publish_pdf_html_add_page_content({titre=>"$d{titre}",content=>"<br /> $d{content}",table_record=>$d{table_record},bloc_page=>$bloc_page,license=>\%license,record=>\%record,document=>\%document,ctm=>\%ctm,sys=>\%sys,facture_ligne_bas_1col=>$facture_ligne_bas_1col{html},facture_ligne_bas=>$facture_ligne_bas{html},number=>$d{number}++,prefixe=>$d{prefixe},pj_name=>$pj_name});
	}
	
	$d{body} .= $nouvelle_page;
	
	return ($d{head},$d{body},$d{number});
}

sub get_publish_pdf_html_add_bloc_head
{
	my %d = %{$_[0]};
	
	my $number = $d{number};
	
	return <<"EOH";
		if(jQuery('#pagescontent$number').contents().length > 0)
		{
			// when we need to add a new page, use a jq object for a template
			// or use a long HTML string, whatever your preference
			jQuerypage = jQuery("#page_template2").clone().addClass("document").css("display", "block");
			
			// fun stuff, like adding page numbers to the footer
			//jQuerypage.find(".footer span").append(page);
			jQuery("body").append(jQuerypage);
			page++;
			
			// here is the columnizer magic
			jQuery('#pagescontent$number').columnize({
				columns: 1,
				target: ".document:last .document-texte",
				manualBreaks : true,
				overflow: {
					height: $d{size},
					id: "#pagescontent$number",
					doneFunc: function(){
						buildPages();
					}
				}
			});
		}
EOH
}

sub get_publish_pdf_html_add_page_content
{
	my %d = %{$_[0]};

	my $bloc_page = $d{bloc_page};
	my $bloc_client = $d{bloc_client};
	
	my %license = %{$d{license}};
	my %record = %{$d{record}};
	my %document = %{$d{document}};
	my %ctm = %{$d{ctm}};
	my %sys = %{$d{sys}};
	my $facture_ligne_bas_1col = $d{facture_ligne_bas_1col};
	my $facture_ligne_bas = $d{facture_ligne_bas};
	
	$page_content = get_publish_pdf_html_tags_document(
	{	
		titre => $d{titre},
		phrase => "",
		numero_document => $d{pj_name},
		date => $record{date_creation},
		document => $bloc_page,
		number => $d{number},
		bloc_client => $bloc_client,
		license=>\%license,
		ctm=>\%ctm,
		sys=>\%sys,
		rec_document=>\%document,
		record=>\%record,
		page_content => $d{content},
	});
	
	
	
	return $page_content;
}


sub get_publish_pdf_html_tags_document
{
	my %d = %{$_[0]};
	my %license = %{$d{license}};
	my %ctm = %{$d{ctm}};
	my %document = %{$d{rec_document}};
	my %record = %{$d{record}};
	my %sys = %{$d{sys}};
	my $phrase_classe = '';
	if(trim($d{phrase}) eq '')
	{
		$phrase_classe = " hide ";
	}
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year+=1900;	
	$mon++;	
	$license{tel} = format_tel($license{tel});
	$license{fax} = format_tel($license{fax});
	$license{gsm} = format_tel($license{gsm});
	

	

	$d{document} =~ s/\-\-\-number\-\-\-/$d{number}/g;
	$d{document} =~ s/\-\-\-bloc_client\-\-\-/$d{bloc_client}/g;
	$d{document} =~ s/\-\-\-year\-\-\-/$year/g;
	$d{document} =~ s/\-\-\-month\-\-\-/$mon/g;
	$d{document} =~ s/\-\-\-day\-\-\-/$mday/g;
	
	$d{document} =~ s/\-\-\-titre\-\-\-/$d{titre}/g;
	$d{document} =~ s/\-\-\-phrase\-\-\-/$d{phrase}/g;
	$d{document} =~ s/\-\-\-phrase_classe\-\-\-/$phrase_classe/g;
	$d{document} =~ s/\-\-\-date\-\-\-/$d{date}/g;
	$d{document} =~ s/\-\-\-refclient\-\-\-//g;
	$d{document} =~ s/\-\-\-page_content\-\-\-/$d{page_content}/g;
	
	$d{document} =~ s/\-\-\-license_company\-\-\-/$license{license_name} $license{license_type_company}/g;
	$d{document} =~ s/\-\-\-license_street\-\-\-/$license{street} $license{street2}/g;
	$d{document} =~ s/\-\-\-license_number\-\-\-//g;
	$d{document} =~ s/\-\-\-license_city\-\-\-/$license{city}/g;
	$d{document} =~ s/\-\-\-license_zip\-\-\-/$license{zip}/g;
	$d{document} =~ s/\-\-\-license_country\-\-\-/$license{country}/g;
	$d{document} =~ s/\-\-\-license_tel\-\-\-/$license{tel}/g;
	$d{document} =~ s/\-\-\-license_fax\-\-\-/$license{fax}/g;
	$d{document} =~ s/\-\-\-license_gsm\-\-\-/$license{gsm}/g;
	$d{document} =~ s/\-\-\-license_mail\-\-\-/$license{email}/g;
	$d{document} =~ s/\-\-\-license_iban\-\-\-/$license{iban}/g;
	$d{document} =~ s/\-\-\-license_bic\-\-\-/$license{bic}/g;
	$d{document} =~ s/\-\-\-license_rpm\-\-\-/$license{rpm}/g;
	$d{document} =~ s/\-\-\-license_division\-\-\-/$license{division}/g;
	$d{document} =~ s/\-\-\-license_siteweb_url\-\-\-/http\:\/\/$license{domaine}/g;
	$d{document} =~ s/\-\-\-license_siteweb\-\-\-/$license{domaine}/g;
	$d{document} =~ s/\-\-\-license_tva\-\-\-/$license{vat}/g;
	$d{document} =~ s/\-\-\-signature document\-\-\-/<br>$license{signature_document}/g;
	
	$d{document} =~ s/\-\-\-signature_ligne1\-\-\-/$license{titre_document1}/g;
	$d{document} =~ s/\-\-\-signature_ligne1_color\-\-\-/$license{titre_document1_color}/g;
	$d{document} =~ s/\-\-\-signature_ligne2\-\-\-/$license{titre_document2}/g;
	$d{document} =~ s/\-\-\-signature_ligne2_color\-\-\-/$license{titre_document2_color}/g;
	$d{document} =~ s/\-\-\-signature_ligne3\-\-\-/$license{titre_document3}/g;
	$d{document} =~ s/\-\-\-signature_ligne3_color\-\-\-/$license{titre_document3_color}/g;
	
	$d{document} =~ s/\-\-\-client_company\-\-\-/$ctm{denomination_systeme_short}/g;
	$d{document} =~ s/\-\-\-client_street\-\-\-/$ctm{CTMADRESSEL1} $ctm{CTMBP} $ctm{CTMADRESSEL2}/g;
	$d{document} =~ s/\-\-\-client_number\-\-\-//g;
	$d{document} =~ s/\-\-\-client_city\-\-\-/$ctm{CTMVILLE}/g;
	$d{document} =~ s/\-\-\-client_zip\-\-\-/$ctm{CTMCP}/g;
	$d{document} =~ s/\-\-\-client_country\-\-\-/$ctm{CTMPAYS}/g;
	$d{document} =~ s/\-\-\-client_tva\-\-\-/$ctm{CTMCTVA}/g;
	$d{document} =~ s/\-\-\-client_denomination\-\-\-/$ctm{CTMDENOMINATION}/g;
	$d{document} =~ s/\-\-\-numero_facture_raw\-\-\-/$d{numero_document}/g;
	

	
	
	if($sys{id} > 0)
	{
		my $barcode = get_document_filename({barcode=>1,date=>0,sys=>\%sys,prefixe=>$d{prefixe},id=>$d{id_record},type=>'document'});
		$d{document} =~ s/\-\-\-barcode\-\-\-/$barcode/g;
	}
	
	
	my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
	
	# $config{fullurl} = 'https://www.bugiweb.net/SELION_INTRANET/erps/selion/';
	
	
	my %logo_facture = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='handmade_selion_licenses' and token='1'",limit=>'',ordby=>''});
	$logo_facture{file_dir} =~ s/\.\.\///g;
	my $url_logo_facture = $config{fullurl}.'/'.$logo_facture{file_dir}.'/'.$logo_facture{full}.$logo_facture{ext};
	my $img = "<img src=\"$url_logo_facture\" width=\"$license{logo_width}\" height=\"$license{logo_height}\">";
	if($logo_facture{full} eq '')
	{
		$img = "$license{license_name}"
	}
	
	my $banner = <<"EOH";
	<a href="http://$license{domaine}">$img</a>
EOH
	$d{document} =~ s/\-\-\-banner\-\-\-/$banner/g;

	
	return $d{document};
}

sub get_publish_pdf_html_get_champs_valeur
{
	  my %d = %{$_[0]};
	  my %line = %{$d{record}};
	  
	  my $dm_dfl_line = $d{dm_dfl_line};
	  my $nb_lignes = $d{nb_lignes};
	  my $nb_max_char = 50;
	  my $new_line = '';
		
	  my ($num,$field) = split(/\//,$dm_dfl_line);
	  my %cell_infos = %{$dm_dfl{$d{dm_dfl_line}}};

	  if($field ne '')
	  {
		  my ($cell_content,$cell_type,$spec,$cell_subtype,$list_style,$data_type,$lbtable,$lbkey,$lbdisplay,$nom_champs,$nopdf) = list_map_body_col_value({line=>\%line,value=>$line{$field},col=>$field,render=>$render});
		  if($cell_type eq 'files_admin' || $data_type eq 'password' || $nopdf == 1)
		  {
			next;
		  }
		  
		  # my $valeur = trim(decode("utf8",$cell_content));
		  my $valeur = $cell_content;
		  
		  if($field eq 'id')
		  {
				$valeur = getcode($dbh,$line{$field},$d{prefixe});
		  }
		  elsif($cell_type eq 'checkbox')
		  {
			  # next;
		  }
		  elsif($data_type eq 'euros' || $data_type eq 'number'  )
		  {
			  $valeur = $valeur;
		  }
		   elsif($data_type eq 'perc')
		  {
			  $valeur = $valeur.' %';
		  }
		  elsif($data_type eq 'date')
		  {
			   # $valeur = $line{$field};
		  }
		  elsif($cell_type ne 'listboxtable' && $cell_type ne '')
		  {
			  # if(trim($cell_content) eq '00/00/0000')
			  # {
				 # $valeur = '';
			  # }
			  # $worksheet->write($row,$col++,$cell_content,$format_vert);
		  }
		  elsif($cell_type eq 'listboxtable')
		  {
					my %lbtable = sql_line({table=>$cell_infos{lbtable}, select=>"$cell_infos{lbdisplay} as affichage",where=>"$cell_infos{lbkey} = '$line{$field}'"});
					$valeur = $lbtable{affichage};
					
					# VAR1 = { 'search' => 'y', 'fieldtype' => 'listboxtable', 'lbtable' => 'handmade_processus_zerry_patient', 'lbdisplay' => 'fusion', 'lbwhere' => '', 'title' => 'Patient', 'mandatory' => { 'type' => 'not_empty' }, 'lbkey' => 'id' }; (listboxtable)
					
					
					# $valeur = $valeur.Dumper(\%cell_infos).'(listboxtable)';
				# $worksheet->write($row,$col++,$cell_content,$format_vert);
			  # if(!$dm_cfg{export_excel_simple})
			  # {
				  # $worksheet->write($row,$col++,$line{$champ},$format_vert);
			  # }
		  }
		  else
		  {
					$valeur = $cell_type.' non supporte';
					# $worksheet->write($row,$col++,'CELLTYPE VIDE',$format_vert);
		  }
		  
		  
		  my $nb_char = length $valeur;
		  my $nb_lignes_a_ajouter = int($nb_char/$nb_max_char)+1;
		  $nb_lignes += $nb_lignes_a_ajouter;
		  
		  $new_line =<<"EOH";
			<tr>
				<th class="regie-table-col" rel="$nb_lignes">$nom_champs</th>
				<td class="regie-table-col">$valeur</td>
			</tr>
EOH
		
	  }
	 
	  return ($new_line,$nb_lignes);
	  
}

sub get_publish_pdf_html
{
	my $id = get_quoted('id');
	my %line = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
	my %sys = %{get_migcms_sys({nom_table=>$dm_cfg{table_name},id_table=>$id})};
	my $prefixe = $dm_cfg{file_prefixe} || get_quoted('file_prefixe');
	my $pj_name = getcode($dbh,$id,$prefixe);

	my $body = "";
	my $head = "";
	my $number = 1;
	
	if(1)
	{
		($head,$body,$number) = get_publish_pdf_html_add_page({type=>'publication_tableau',number=>$number, prefixe=>$prefixe,id_record=>$id,table_record=>$dm_cfg{table_name},record=>\%line,sys=>\%sys,head=>$head,body=>$body});
	}
	
	
	
	#habillage document
	my $html_document = get_publish_pdf_html_set_canvas({head=>$head,body=>$body,record=>\%line,sys=>\%sys});
	
	print $html_document;
	exit;
}

sub get_publish_pdf_html_set_canvas
{
	my %d = %{$_[0]};
	
	my %html = sql_line({table=>'migcms_textes_emails',where=>"table_name='page simplifiee'"});
	
	my $page_container = get_traduction({debug=>0,id=>$html{id_textid_raw_texte},id_language=>$config{current_language}});
	
	$page_container =~ s/\-\-\-body\-\-\-/$d{body}/g;
	$page_container =~ s/\-\-\-head\-\-\-/$d{head}/g;
	
	my %record = %{$d{record}};
	my %document = %{$d{document}};
	my %ctm = %{$d{ctm}};
	my %sys = %{$d{sys}};

	
	my %license = sql_line({debug=>0,debug_results=>0,table=>'handmade_selion_licenses'});
	$page_container = get_publish_pdf_html_tags_document({document=>$page_container,license=>\%license,ctm=>\%ctm,
										sys=>\%sys,
										rec_document=>\%document,
										record=>\%record,});

	return $page_container;
}


sub get_publish_pdf_html2
{
	my $id = get_quoted('id');
	my %line = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
	# my %sys = sql_line({debug=>0,select=>'id',table=>'migcms_sys',where=>"nom_table='$dm_cfg{table_name}' AND id_table='$id'"});
	my %sys = %{get_migcms_sys({nom_table=>$dm_cfg{table_name},id_table=>$id})};

	my $fac = '';
	
	my %tpl_debut = read_table($dbh,'handmade_templates',25);
	my %tpl_header = read_table($dbh,'handmade_templates',1);
	my %tpl_titre_content = read_table($dbh,'handmade_templates',17);
	my %tpl_footer = read_table($dbh,'handmade_templates',6);

	#DEBUG
	$fac .= $tpl_debut{html};
	
	#PAGE 1
	$fac .= $tpl_header{html};
	$fac .= $tpl_titre_content{html};
	$fac .= $tpl_footer{html};
	
	#BALISES
	$fac =~ s/{js}//g;
	
	my $prefixe = $dm_cfg{file_prefixe};
    my $page_title = trim($dm_cfg{page_title}) || "";
	if($dm_cfg{page_title} eq '')
	{
		my %script = read_table($dbh,"scripts",get_quoted('sel'));
		$page_title = $dm_cfg{page_title} = $script{name};
	}	
	my $titre = $page_title;

	my $nb_lignes = 0;
	my $nb_max_lignes = 22;
	my $nb_max_char = 50;
	
	my $content = <<"EOH";	
		</table>
		<table class="table table-bordered">
EOH
	
      #génération des lignes à partir de %dm_dfl
	  
	  foreach $dm_dfl_line (sort keys %dm_dfl)
	  {
		  if($nb_lignes >= $nb_max_lignes)
		  {
			 $content .= <<"EOH";	
				</table>
EOH
			$fac =~ s/{titre}/$titre/g;
			$fac =~ s/{content}/$content/g;
		
			#PAGE ++
			$fac .= $tpl_header{html};
			$fac .= $tpl_titre_content{html};
			$fac .= $tpl_footer{html};
			$nb_lignes = 1;
			  
			$content = <<"EOH";	
				<table class="table table-bordered">
EOH
		  }
		  my ($num,$field) = split(/\//,$dm_dfl_line);
		  my %cell_infos = %{$dm_dfl{$dm_dfl_line}};
		  if($field ne '')
		  {
			  my ($cell_content,$cell_type,$spec,$cell_subtype,$list_style,$data_type,$lbtable,$lbkey,$lbdisplay,$nom_champs,$nopdf) = list_map_body_col_value({line=>\%line,value=>$line{$field},col=>$field,render=>$render});
			  if($cell_type eq 'files_admin' || $data_type eq 'password' || $nopdf == 1)
			  {
				next;
			  }
			  
			  # my $valeur = trim(decode("utf8",$cell_content));
			  my $valeur = $cell_content;
			  
			  if($field eq 'id')
			  {
					$valeur = getcode($dbh,$line{$field});
			  }
			  elsif($cell_type eq 'checkbox')
			  {
				  # next;
			  }
			  elsif($data_type eq 'euros' || $data_type eq 'number')
			  {
				  $valeur = $valeur;
			  }
			   elsif($data_type eq 'perc')
			  {
				  $valeur = $valeur.' %';
			  }
			  elsif($data_type eq 'date')
			  {
				   # $valeur = $line{$field};
			  }
			  elsif($cell_type ne 'listboxtable' && $cell_type ne '')
			  {
				  # if(trim($cell_content) eq '00/00/0000')
				  # {
					 # $valeur = '';
				  # }
				  # $worksheet->write($row,$col++,$cell_content,$format_vert);
			  }
			  elsif($cell_type eq 'listboxtable')
			  {
				  # $worksheet->write($row,$col++,$cell_content,$format_vert);
				  # if(!$dm_cfg{export_excel_simple})
				  # {
					  # $worksheet->write($row,$col++,$line{$champ},$format_vert);
				  # }
			  }
			  else
			  {
				# $worksheet->write($row,$col++,'CELLTYPE VIDE',$format_vert);
			  }
			  
			  
			  my $nb_char = length $valeur;
			  my $nb_lignes_a_ajouter = int($nb_char/$nb_max_char)+1;
			  $nb_lignes += $nb_lignes_a_ajouter;
			  
			  $content .=<<"EOH";
				<tr>
					<th class="regie-table-col">$nom_champs</th>
					<td class="regie-table-col">$valeur</td>
				</tr>
EOH
		  }
	  }

	$content .=<<"EOH";
		</table>
EOH
	
	$fac =~ s/{titre}/$titre/g;
	$fac =~ s/{content}/$content/g;
	
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year+=1900;	
	$mon++;	
	
    $pat = '{year}';
	$fac =~ s/$pat/$year/g;
	
	$pat = '{month}';
	$fac =~ s/$pat/$mon/g;
	my %license = sql_line({table=>'handmade_selion_licenses'}); #simplement changer nom pr rendre générique (table + tableau de champs license)
	$fac = map_license_fields($fac,\%license);
	my $barcode = get_document_filename({barcode=>1,date=>1,sys=>\%sys,prefixe=>$prefixe,id=>$id,type=>'document'});
	$fac =~ s/{barcode}/$barcode/g;
	print $fac;
	exit;
}



sub map_license_fields
{
	my $fac = $_[0];
	my %license = %{$_[1]};
	
	my $domaine = $license{domaine};
	
	my $domaine_link = $domaine;
	if($domaine_link =~ /^http:\/\// || $domaine_link =~ /^https:\/\//)
	{
		
	}
	else
	{
		$domaine_link = $htaccess_protocol_rewrite.'://'.$domaine_link;
	}
	
	 my $num = $license{tel};
	 
	
	$fac =~ s/{license_company}/$license{license_name} $license{license_type_company}/g;
	$fac =~ s/{license_street}/$license{street}/g;
	$fac =~ s/{license_street2}/$license{street2}/g;
	$fac =~ s/{license_number}/$license{number}/g;
	
	$fac =~ s/{license_zip}/$license{zip}/g;
	$fac =~ s/{license_email}/$license{email}/g;
	
	$fac =~ s/{license_tel}/$license{tel}/g;
	$fac =~ s/{license_tel_link}/$license_tel_link/g;
	$fac =~ s/{license_iban}/$license{iban}/g;
	$fac =~ s/{license_bic}/$license{bic}/g;
	$fac =~ s/{license_rpm}/$license{rpm}/g;
	$fac =~ s/{license_division}/$license{division}/g;
	$fac =~ s/{license_web}/$domaine/g;
	$fac =~ s/{license_web_link}/$domaine_link/g;
	
	
	$fac =~ s/{license_city}/$license{city}/g;
	$fac =~ s/{license_country}/$license{country}/g;
	$fac =~ s/{license_responsable}/$license{responsable}/g;
	
	if($license{vat} ne '')
	{
		$license{vat} = "TVA $license{vat}";
	}
	$fac =~ s/{license_vat}/$license{vat}/g;
	
	return $fac;
}


sub send_by_email
{
	log_debug('send_by_email','vide','send_by_email');
	my $id = get_quoted('id');
	log_debug($id,'','send_by_email');
	my $prefixe = $dm_cfg{file_prefixe};
	if($prefixe eq '')
	{
		$prefixe = sprintf("%.02d",get_quoted('sel'));
	}
	
	#publication du fichier si nécessaire
	my $func_publish = 'ajax_publish_pdf';
	if($dm_cfg{func_publish} ne '')
	{
		$func_publish = 'def_handmade::'.$dm_cfg{func_publish};
	}
	$pdf_filename = &$func_publish($id,lc($dm_cfg{file_prefixe}),$dm_cfg{table_name},$dm_cfg{self});

	my %record = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{table_name},where=>"id='$id'"});
	if($record{migcms_last_published_file} eq '')
	{
		$record{migcms_last_published_file} = $record{pdf_filename};
	}
	my %destinataire = ();
	if($dm_cfg{send_by_email_table_destinataire} eq '')
	{
		$dm_cfg{send_by_email_table_destinataire} = $config{send_by_email_table_destinataire};
	}
	if($dm_cfg{send_by_email_col_destinataire} eq '')
	{
		$dm_cfg{send_by_email_col_destinataire} = $config{send_by_email_col_destinataire};
	}
	if($dm_cfg{send_by_email_table_destinataire} ne '' && $dm_cfg{send_by_email_col_destinataire} ne '')
	{
		%destinataire = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_destinataire},where=>"id='$record{$dm_cfg{send_by_email_col_destinataire}}'"});
	}
	
	#DE
	my %license = ();
	if($dm_cfg{send_by_email_table_license} eq '')
	{
		$dm_cfg{send_by_email_table_license} = $config{send_by_email_table_license};
	}
	if($dm_cfg{send_by_email_table_license} ne '' )
	{
		if($dm_cfg{send_by_email_id_license} ne '' && $record{$dm_cfg{send_by_email_id_license}} > 0 )
		{
			%license = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_license},where=>"id='$record{$dm_cfg{send_by_email_id_license}}'"});
		}
		else
		{
			%license = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_license}});
		}
	}
	
	#CCI
	my %cci = ();
	if($dm_cfg{send_by_email_table_license_cci} eq '')
	{
		$dm_cfg{send_by_email_table_license_cci} = $config{send_by_email_table_license_cci};
	}
	if($dm_cfg{send_by_email_table_license_cci} eq '')
	{
		$dm_cfg{send_by_email_table_license_cci} = $dm_cfg{send_by_email_table_license};
	}
	if($dm_cfg{send_by_email_table_license_cci} ne '' )
	{
		%cci = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_license_cci}});
	}

	
	
	if($dm_cfg{send_by_email_id_template} eq '')
	{
		$dm_cfg{send_by_email_id_template} = $config{send_by_email_id_template};
	}
	if($dm_cfg{send_by_email_table_templates} eq '')
	{
		$dm_cfg{send_by_email_table_templates} = $config{send_by_email_table_templates};
	}
	
	
	my %tpl_email_doc = ();
	if($dm_cfg{send_by_email_table_templates} ne '' && $dm_cfg{send_by_email_id_template} ne '')
	{
		%tpl_email_doc = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_templates},where=>"id='$dm_cfg{send_by_email_id_template}'"});
	}
	else
	{
		my %migcms_textes_email = sql_line({table=>'migcms_textes_emails',where=>"table_name='$dm_cfg{table_name}'"});
		$tpl_email_doc{html} = get_traduction({debug=>0,id=>$migcms_textes_email{id_textid_texte},id_language=>$config{current_language}});
	}
	
	my $message = $tpl_email_doc{html};
	if($dm_cfg{send_by_email_field1_license} eq '')
	{
		$dm_cfg{send_by_email_field1_license} = $config{send_by_email_field1_license};
	}
	if($dm_cfg{send_by_email2_field1_license} eq '')
	{
		$dm_cfg{send_by_email2_field1_license} = $config{send_by_email2_field1_license};
	}
	
		
	my $de = "$license{$dm_cfg{send_by_email_field1_license}} ";
	my $alt_de = '';
	if($license{$dm_cfg{send_by_email_field2_license}} ne '')
	{
		$de .= " ($license{$dm_cfg{send_by_email_field2_license}})";
		$alt_de = "$license{$dm_cfg{send_by_email_field2_license}}";
	}
	elsif($cci{email} ne '')
	{
		$de .= " ($cci{email})";
		$alt_de = "$cci{email}";
	}
	
	my $pj_name = getcode($dbh,$id,$prefixe);
	$message =~ s/{numero_document}/$pj_name/g;
	
	
	foreach my $cle_cci (keys %cci)
	{
		if($license{$cle_cci} eq '' && $cci{$cle_cci} ne '')
		{
			$license{$cle_cci} = $cci{$cle_cci};
		}
	
	}
	
	
	$message = map_license_fields($message,\%license);
	
	$message = def_handmade::map_document($message,$dm_cfg{table_name},$id,$prefixe);
	
	if($dm_cfg{send_by_email_field1_destinataire} eq '')
	{
		$dm_cfg{send_by_email_field1_destinataire} = $config{send_by_email_field1_destinataire};
	}
	if($dm_cfg{send_by_email_field2_destinataire} eq '')
	{
		$dm_cfg{send_by_email_field2_destinataire} = $config{send_by_email_field2_destinataire};
	}
	if($dm_cfg{send_by_email_col_objet} eq '')
	{
		$dm_cfg{send_by_email_col_objet} = $config{send_by_email_col_objet};
	}
	
	
	#construction de l'objet
	
	#prefixe
	my $prefixe_objet = "";
	if($dm_cfg{send_by_email_col_prefixe} ne '')
	{
		$prefixe_objet = $record{$dm_cfg{send_by_email_col_prefixe}};
		if($dm_cfg{send_by_email_col_prefixe_lbtable} ne '' && $dm_cfg{send_by_email_col_prefixe_lbdisplay} ne '')
		{
			my %lbtable_value = sql_line({table=>$dm_cfg{send_by_email_col_prefixe_lbtable},where=>"id='$record{$dm_cfg{send_by_email_col_prefixe}}'"});
			$prefixe_objet = $lbtable_value{$dm_cfg{send_by_email_col_prefixe_lbdisplay}};
			if($dm_cfg{send_by_email_col_prefixe_lbdisplay} eq 'id')
			{
				my $display_prefixe = $dm_cfg{send_by_email_col_prefixe_lbdisplay_prefixe};
				if($display_prefixe eq '')
				{
					$display_prefixe = $prefixe;
				}
				$prefixe_objet = getcode($dbh,$prefixe_objet,$prefixe);
			}
		}
		$prefixe_objet = $prefixe_objet
	}
	
	#suffixe
	my $suffixe_objet = "";
	if($dm_cfg{send_by_email_col_suffixe} ne '')
	{
		$suffixe_objet = $record{$dm_cfg{send_by_email_col_suffixe}};
		if($dm_cfg{send_by_email_col_suffixe_lbtable} ne '' && $dm_cfg{send_by_email_col_suffixe_lbdisplay} ne '')
		{
			my %lbtable_value = sql_line({table=>$dm_cfg{send_by_email_col_suffixe_lbtable},where=>"id='$record{$dm_cfg{send_by_email_col_suffixe}}'"});
			$suffixe_objet = $lbtable_value{$dm_cfg{send_by_email_col_suffixe_lbdisplay}};
			if($dm_cfg{send_by_email_col_suffixe_lbdisplay} eq 'id')
			{
				my $display_prefixe = $dm_cfg{send_by_email_col_suffixe_lbdisplay_prefixe};
				if($display_prefixe eq '')
				{
					$display_prefixe = $prefixe;
				}
				$suffixe_objet = getcode($dbh,$suffixe_objet,$display_prefixe);
			}
		}
		$suffixe_objet = ' - '.$suffixe_objet;
	}
	
	#MARQUE - PREFIXE - Titre n° PREFIXE0000ID - CEF0000XXX
	my $object = trim(trim($prefixe_objet).' - '.trim($prefixe).' - '.trim($dm_cfg{send_by_email_col_docname}).' '.trim($pj_name).' '.trim($suffixe_objet));
	$object =~ s/^\-//g;
	$object = trim($object);
	
	my $company = "$destinataire{$dm_cfg{send_by_email_field1_destinataire}} $destinataire{$dm_cfg{send_by_email_field2_destinataire}}";
	
	
	$self = $dm_cfg{self};
	
	my $cc = $record{$dm_cfg{send_by_email_col_cc}};
	
	$record{migcms_last_published_file} =~ s/\.pdf//g;
	
	my $file_pj_name = $record{migcms_last_published_file}.'.pdf';
	
	if($config{send_by_email_nom_simple} eq 'y')
	{
		$file_pj_name = 'Document complet N°'.$record{id};
	}
	
	my $pieces_jointes = <<"EOH";
			<a data-placement="top" data-original-title="Visualiser" 
			class="btn btn-default" target="_blank" 
			href="../usr/documents/$record{migcms_last_published_file}.pdf">
					<i class="fa fa-eye"></i> $file_pj_name
			</a>
EOH

	if($dm_cfg{send_by_mail_less_pj} == 1)
	{
		$pieces_jointes = '';
	}
	
	my $file_pj_name = $record{migcms_last_published_file}.'_PRI.pdf';
	if(-e "../usr/documents/$record{migcms_last_published_file}_PRI.pdf")
	{
		if($config{send_by_email_nom_simple} eq 'y')
		{
			$file_pj_name = 'Document principal N°'.$record{id};
		}
		
		$pieces_jointes .= <<"EOH";
			<a data-placement="top" data-original-title="Visualiser" 
			class="btn btn-default" target="_blank" 
			href="../usr/documents/$record{migcms_last_published_file}_PRI.pdf">
					<i class="fa fa-eye"></i> $file_pj_name
			</a>
EOH
	}
	# else
	# {
	# $pieces_jointes .= <<"EOH";
	# "../usr/documents/$record{migcms_last_published_file}_PRI.pdf"
# EOH
	# }
	
	my $file_pj_name = $record{migcms_last_published_file}.'_CGV.pdf';
	my $filesize = -s "../usr/documents/$record{migcms_last_published_file}.pdf";
	if(-e "../usr/documents/$record{migcms_last_published_file}_CGV.pdf")
	{
		if($config{send_by_email_nom_simple} eq 'y')
		{
			$file_pj_name = 'Document conditions générales N°'.$record{id};
		}
		
		$pieces_jointes .= <<"EOH";
			<a data-placement="top" data-original-title="Visualiser" 
			class="btn btn-default" target="_blank" 
			href="../usr/documents/$record{migcms_last_published_file}_CGV.pdf">
					<i class="fa fa-eye"></i> $file_pj_name
			</a>
EOH
	}

	if($dm_cfg{send_by_mail_less_pj} != 1)
	{
		my $filesize = -s "../usr/documents/$record{migcms_last_published_file}_ANX.pdf";
		my $file_pj_name = $record{migcms_last_published_file}.'_ANX.pdf';
		if(-e "../usr/documents/$record{migcms_last_published_file}_ANX.pdf" && $filesize > 1000)
		{
			
			if($config{send_by_email_nom_simple} eq 'y')
			{
				$file_pj_name = 'Document annexes N°'.$record{id};
			}
			
			$pieces_jointes .= <<"EOH";
				<a data-placement="top" data-original-title="Visualiser" 
				class="btn btn-default" target="_blank" 
				href="../usr/documents/$record{migcms_last_published_file}_ANX.pdf">
						<i class="fa fa-eye"></i> $file_pj_name 
				</a>
EOH
		}
	}
	
	my $screen = <<"EOH";
	<h2>$migctrad{send_by_email_title}</h2>
	<input type="hidden" class="id_doc" value="$id" />
	<input type="hidden" class="alt_de" value="$alt_de" />
	<input type="hidden" class="prefixe_doc" value="$prefixe" />
	<input type="hidden" class="company" value="$company" />

	<div class="well form-horizontal adminex-form">
		<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_de} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 control-label mig_cms_value_col"><input type="text" class="form-control" name="send_mail_screen_from" disabled value="$de" /></div>
		</div>
		<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_a} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 mig_cms_value_col"><input type="text" class="form-control send_mail_screen_to" name="send_mail_screen_to" value="$destinataire{$dm_cfg{send_by_email_field_email_destinataire}}" />
			<span class="help-block text-left"><i class="fa fa-info-circle"></i> <b>$migctrad{send_by_email_a_txt1}</b>: $migctrad{send_by_email_a_txt2}</span>
			</div>
		</div>
		<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_cc} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 mig_cms_value_col"><input type="text" class="form-control send_mail_screen_cc" name="send_mail_screen_cc" value="$cc" />
			<span class="help-block text-left"><i class="fa fa-info-circle"></i> <b>$migctrad{send_by_email_cc_txt1}</b>: $migctrad{send_by_email_cc_txt2}</span>
			</div>
		</div>
		<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_cci} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 mig_cms_value_col"><input type="text" class="form-control send_mail_screen_cci" name="send_mail_screen_cci" value="$cci{email}" />
						<span class="help-block text-left"><i class="fa fa-info-circle"></i> <b>$migctrad{send_by_email_cci_txt1}</b>: $migctrad{send_by_email_cci_txt2}</span>
			</div>
		</div>
			<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_objet} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 mig_cms_value_col"><input type="text" class="form-control send_mail_screen_object" name="send_mail_screen_object" value="$object" /></div>
		</div>
		<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_pj} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 mig_cms_value_col">
			$pieces_jointes
			
			</div>
		</div>
		<div class="form-group">
			<label class="col-lg-1 col-md-2 col-sm-2 control-label">$migctrad{send_by_email_msg} :</label>
			<div class="col-lg-11 col-md-10 col-sm-10 mig_cms_value_col"><textarea name="message" style="min-height:300px" class="wysiwyg send_mail_screen_message form-control">$message</textarea></div>
		</div>
	
	
	</div>

	<div class="row">
		<div class="col-md-12 text-right">
					<a data-placement="top" data-original-title="$migctrad{back}" class="btn btn-lg btn-default show_only_after_document_ready cancel_edit c7" aria-hidden="true">$ICONCANCEL</i></a>
			<a class="btn btn-lg btn-success send_mail_screen_submit" data-placement="top" data-original-title="$migctrad{action_email}"><i class="fa fa-paper-plane-o" aria-hidden="true"></i></a>
		</div>
	</div>
	
	
EOH

	print $screen;
	exit;
}

sub send_by_email_db
{
	log_debug('send_by_email_db','vide','send_by_email_db');
	my $alt_de = get_quoted('de') || $_[3];
	my $to = get_quoted('to') || $_[0];
	my $object = get_quoted('object') || $_[1];
	my $cc = get_quoted('cc');
	my $cci = get_quoted('cci');
	
	my $id_doc = get_quoted('id_doc');
	my $prefixe_doc = get_quoted('prefixe_doc');
	my $company = get_quoted('company');
	my %record = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{table_name},where=>"id='$id_doc'"});
	

		
	
	my $send_mail_screen_message = get_quoted('send_mail_screen_message') || $_[2];
	use HTML::Entities;
	
	$config{fullurl} = "$config{rewrite_protocol}://$config{rewrite_subdns}$config{rewrite_dns}/";
	my $filename = '';
	if($record{migcms_last_published_file} eq '')
	{
		$record{migcms_last_published_file} = $record{pdf_filename};
	}
	
	$record{migcms_last_published_file} =~ s/\.pdf//g;

	my $url_fichier = $config{fullurl}.'usr/documents/'.$record{migcms_last_published_file};
	my $url_fichier_complet = $config{fullurl}.'usr/documents/'.$record{migcms_last_published_file}.'.pdf';
	my $url_fichier_pri = $config{fullurl}.'usr/documents/'.$record{migcms_last_published_file}.'_PRI.pdf';
	my $url_fichier_anx = $config{fullurl}.'usr/documents/'.$record{migcms_last_published_file}.'_ANX.pdf';
	# log_debug($config{fullurl},'','fullurl');
	# log_debug($url_fichier,'','fullurl');
	# log_debug($url_fichier_pri,'','fullurl');
	# log_debug($url_fichier_anx,'','fullurl');




	$send_mail_screen_message =~ s/{link1}/$url_fichier_pri/g;
	$send_mail_screen_message =~ s/{link2}/$url_fichier_anx/g;
	$send_mail_screen_message =~ s/{link3}/$url_fichier_complet/g;
	
	# log_debug($send_mail_screen_message,'','fullurl');
	
	
	#DE
	my %license = ();
	if($dm_cfg{send_by_email_table_license} eq '')
	{
		$dm_cfg{send_by_email_table_license} = $config{send_by_email_table_license};
	}
	if($dm_cfg{send_by_email_table_license} ne '' )
	{
		if($dm_cfg{send_by_email_id_license} ne '' && $record{$dm_cfg{send_by_email_id_license}} > 0 )
		{
			%license = sql_line({debug=>1,debug_results=>1,table=>$dm_cfg{send_by_email_table_license},where=>"id='$record{$dm_cfg{send_by_email_id_license}}'"});
		}
		else
		{
			%license = sql_line({debug=>1,debug_results=>1,table=>$dm_cfg{send_by_email_table_license}});
		}
	}

	
	
	
	# my %license = ();
	# if($dm_cfg{send_by_email_table_license} ne '' )
	# {
		# %license = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_license}});
	# }
	
	if($dm_cfg{send_by_email_field2_license} eq '')
	{
		$dm_cfg{send_by_email_field2_license} = 'email';
	}
	if($license{$dm_cfg{send_by_email_field2_license}} eq '')
	{
		$license{$dm_cfg{send_by_email_field2_license}} = $alt_de;
	}

	my $de = "$license{$dm_cfg{send_by_email_field1_license}} <$license{$dm_cfg{send_by_email_field2_license}}>";
	
	
	my $filepath = $config{directory_path}.'/usr/documents/'.$record{migcms_last_published_file}.'.pdf';
	
	

		
	
	my @pjs = ();
	
	#document complet
	my $file_path = $config{directory_path}.'/usr/documents/'.$record{migcms_last_published_file}.'.pdf';
	# my $pj_name = getcode($dbh,$id_doc,$prefixe_doc);
	my $pj_name = $record{migcms_last_published_file};
	my %pj = 
	(
			type=> "file/pdf",
			id=> $file_path,
			path=> $file_path,
			Filename => $pj_name.'.pdf'
	);  
	if(-e $file_path)
	{
		if($dm_cfg{send_by_mail_less_pj} != 1)
		{
			push @pjs,\%pj;
		}
	}
	
	#conditions générales seulement
	
	
	
	#facture seulement
	my $file_path = $config{directory_path}.'/usr/documents/'.$record{migcms_last_published_file}.'_PRI.pdf';
	my %pj = 
	(
			type=> "file/pdf",
			id=> $file_path,
			path=> $file_path,
			Filename => $pj_name.'_PRI.pdf'
	);  
	if(-e $file_path)
	{
		push @pjs,\%pj;
	}
	
	my $file_path = $config{directory_path}.'/usr/documents/'.$record{migcms_last_published_file}.'_CGV.pdf';
	
	my %pj = 
	(
			type=> "file/pdf",
			id=> $file_path,
			path=> $file_path,
			Filename => $pj_name.'_CGV.pdf'
	);  
	if(-e $file_path)
	{
		push @pjs,\%pj;
	}
	
	#pjs seulement
	my $file_path = $config{directory_path}.'/usr/documents/'.$record{migcms_last_published_file}.'_ANX.pdf';
	my %pj = 
	(
			type=> "file/pdf",
			id=> $file_path,
			path=> $file_path,
			Filename => $pj_name.'_ANX.pdf'
	);
	my $filesize = -s $file_path ;	
	if(-e $file_path && $filesize > 1000)
	{
		if($dm_cfg{send_by_mail_less_pj} != 1)
		{
			push @pjs,\%pj;
		}
	}
	
	$send_mail_screen_message =~s/\\\'/\'/g;
	# $send_mail_screen_message = '<div style="font-family:arial;font-size:13px;">'.$send_mail_screen_message.'</div>';
	
	
	
	my %cci_data = ();
	if($dm_cfg{send_by_email_table_license_cci} eq '')
	{
		$dm_cfg{send_by_email_table_license_cci} = $config{send_by_email_table_license_cci};
	}
	if($dm_cfg{send_by_email_table_license_cci} eq '')
	{
		$dm_cfg{send_by_email_table_license_cci} = $dm_cfg{send_by_email_table_license};
	}
	if($dm_cfg{send_by_email_table_license_cci} ne '' )
	{
		%cci_data = sql_line({debug=>0,debug_results=>0,table=>$dm_cfg{send_by_email_table_license_cci}});
	}

	my $license_email =$license{email};
	if($license_email eq '')
	{
		$license_email =$cci_data{email};
	}
	
	
	
		# my $company = trim("$license{license_name} $license{license_type_company}");
		# if($company eq '')
		# {
			# $company = "$cci_data{license_name} $cci_data{license_type_company}";
		# }
		
		# my $company = trim("$license{license_name} $license{license_type_company}");
		# if($company eq '')
		# {
			# $company = "$cci_data{license_name} $cci_data{license_type_company}";
		# }
		
		
		
		# my %balises = 
		# (
			# 'company' => "$license{license_name} $license{license_type_company}",
			# 'address' => "$license{street} $license{street2}$cci_data{street} $cci_data{street2}",
			# 'number' => "$license{number}$cci_data{number}",
			# 'zip' => "$license{zip}$cci_data{zip}",
			# 'city' => "$license{city}$cci_data{city}",
			# 'phone' => "$license{tel}$cci_data{tel}",
			# 'email_1' => "$license_email",
			# 'vat' => "$license{vat}$cci_data{vat}",
			# 'country' => "$license{country}$cci_data{country}",
			# 'siteweb' => "http://$license{domaine}$cci_data{domaine}",
			# 'iban' => "$license{iban}$cci_data{iban}",
			# 'bic' => "$license{bic}$cci_data{bic}",
			# 'rpm' => "$license{rpm}$cci_data{rpm}",
			# 'division' => "$license{division}$cci_data{division}",
			# 'tva' => "$license{vat}$cci_data{vat}",
		# );
		
		my %balises = 
		(
			'company' => "$license{license_name} $license{license_type_company}",
			'address' => "$license{street} $license{street2}",
			'number' => "$license{number}",
			'zip' => "$license{zip}",
			'city' => "$license{city}",
			'phone' => "$license{tel}",
			'email_1' => "$license_email",
			'vat' => "$license{vat}",
			'country' => "$license{country}",
			'siteweb' => "http://$license{domaine}",
			'iban' => "$license{iban}",
			'bic' => "$license{bic}",
			'rpm' => "$license{rpm}",
			'division' => "$license{division}",
			'tva' => "$license{vat}",
		);
		
		# foreach my $cle_balise (keys %balises)
		# {
		# }
		
		$send_mail_screen_message = get_email_communication({body=>$send_mail_screen_message,balises=>\%balises});

	
	
	#destinataire
	
	
	log_debug('de:'.$de,'','send_by_email_db');
	log_debug('to:'.$to,'','send_by_email_db');
	log_debug('cc:'.$cc,'','send_by_email_db');
	log_debug('cci:'.$cci,'','send_by_email_db');
	log_debug('object:'.$object,'','send_by_email_db');
	log_debug('send_mail_screen_message:'.$send_mail_screen_message,'','send_by_email_db');
	
	send_mail_with_attachment($de,$to,$object,$send_mail_screen_message,\@pjs,"html",'',$cc,$cci);
	
	#alexis bugi
	$to = 'debug@bugiweb.com';
	send_mail_with_attachment($de,$to,'COPIE BUGIWEB: '.$object,$send_mail_screen_message,\@pjs,"html",'');

	$to =~s/\\\'/\'/g;
	add_history({action=>'send_mail',page=>$prefixe_doc,id=>$id_doc,details=>$to});
	exit;
}



sub google_map_markers
{
	my %migcms_where = sql_line({table=>'migcms_wheres', where=>"id_user = '$user{id}' AND nom_table= '$dm_cfg{table_name}'"});
	my $where = "lat != '' AND lon != ''";
	if($migcms_where{cond} ne '')
	{
		$where .=" AND $migcms_where{cond} ";
	}
	
	my $liste_points = '';
	my @recs = sql_lines({limit=>"0,1000",debug=>0,debug_results=>0,table=>$dm_cfg{table_name}, select=>"id,$dm_cfg{col_nom} as nom, $dm_cfg{col_lat} as lat,$dm_cfg{col_lon} as lon,$dm_cfg{col_street} as street,$dm_cfg{col_zip} as zip,$dm_cfg{col_city} as city,$dm_cfg{col_country} as country,$dm_cfg{col_phone} as phone",where=>$where});
	foreach $rec (@recs)
	{
		my %rec = %{$rec};
		$liste_points .=<<"EOH";
	<div class="markers">latitude_$rec{lat}___longitude_$rec{lon}___boxContent_<h1>$rec{nom}</h1><h2>$rec{street}, $rec{zip} $rec{city} $rec{country}</h2><div class="phone">$rec{phone} <a href="#" data-placement="top" data-original-title="Editer le contenu" id="$rec{id}" role="button" class="hide animate_gear btn btn-info show_only_after_document_ready migedit_$rec{id} migedit dm_migedit"><i class="fa fa-fw fa-pencil" data-original-title="" title=""></i></a></div></div>
EOH
	}
	print $liste_points;
	
	
	exit;

}

sub check_session_validity
{
	# see();
	exit;
}

sub autocomplete_query
{
	log_debug('autocomplete_query','','autocomplete_query');
	my $field_rec = get_quoted('field');
	$field_rec =~ s/autocomplete\_//g;
	# see();
	my $query_rec = trim(get_quoted('query'));
	my $editId = trim(get_quoted('edit_id'));



	my @keywords = split('\s',$query_rec);

	#retrouver le champs
	my $lbtable = '';
	my $lbkey = '';
	my $lbdisplay = '';
	my $lbwhere = '';
	my $lbordby = '';
	my $limit = '';
	my $field_name = '';
	my %line = ();
	foreach $field_line (sort keys %dm_dfl)
	{
		($ordby,$field_name) = split(/\//,$field_line);
		if($field_name eq $field_rec)
		{
		   %line = %{$dm_dfl{$field_line}};
		   $lbtable = $line{lbtable};
		   $lbkey = $line{lbkey};
		   $lbdisplay = $line{lbdisplay};
		   $lbwhere = $line{lbwhere};
		   $lbordby = $line{lbordby};
		   $limit = $line{lblimit};
		}
	}
	
	
		my @where_keyword = ();
		foreach my $keyword (@keywords)
		{
			push @where_keyword, " UPPER($lbdisplay) LIKE UPPER('%$keyword%') ";
		}
	
		push @where_keyword, $lbwhere;
		
		my $where = join(" AND ",@where_keyword);
	$where = trim($where);
	$where =~  s/AND$//g;
	if($limit eq '')
	{
		$limit = '10';
	}


	my $json = "";
	if($lbtable ne '' && $lbkey ne '' && $lbdisplay ne '' && $query_rec ne '')
	{
		my @json_content = ();
		$where =~ s/MIGCCURRENTEDITID/$editId/g;
		my @lines = sql_lines({debug=>1,debug_resumts=>1,table=>$lbtable,select=>"$lbdisplay as affichage, $lbkey as cle",where=>$where,ordby=>"$lbordby",limit=>$limit});
		foreach my $line (@lines)
		{
			my %line = %{$line};
			push @json_content, '{"id":"'.$line{cle}.'","label":"'.$line{affichage}.'"}';
		}
		my $json_content = join(",",@json_content);
		$json = "[$json_content]";
		log_debug($json,'','autocomplete_query');
	}
	else
	{
	}
	print $json;
	exit;	
}

sub link_files_to_records
{
	exit;
	my $field = 'pj';
	my $ext = '.pdf';
	my $from_path = $config{directory_path}."/usr/import/".$dm_cfg{file_prefixe}."/";
	my $to_path_base = $config{directory_path}."/usr/files/".$dm_cfg{file_prefixe}."/$field/";
	my $to_dir_base = "../usr/files/".$dm_cfg{file_prefixe}."/$field/";
	# delete FROM `migcms_linked_files` WHERE table_name='handmade_selion_achats'
	
	my @files_list = get_files_list($from_path);
	
	#boucler sur les fichiers
	foreach my $file (@files_list) 
    {
		my $filepath = $path.$file;
		my $id_rec = $file;
		my @id_rec_data = split('\s',trim($id_rec));
		
		#recupérer l'id
		$id_rec = $id_rec_data[0];
		$id_rec =~ s/\D//g;
		$id_rec =~ s/\'/\\\'/g;
		$id_rec *= 1;
		
		#lecture du record 
		my %rec = read_table($dbh,$dm_cfg{table_name},$id_rec);
		if(!($rec{id} > 0))
		{
			next;
		}
		$rec{id} = int($rec{id});

		my $to_path = $to_path_base.$rec{id}.'/';
		
		my $dir = $config{directory_path}.'/usr/files/'.$dm_cfg{file_prefixe};
		unless (-d $dir) {mkdir($dir.'/') or log_debug("cannot create ".$dir.": $!");}
		my $dir = $config{directory_path}.'/usr/files/'.$dm_cfg{file_prefixe}.'/'.$field;
		unless (-d $dir) {mkdir($dir.'/') or log_debug("cannot create ".$dir.": $!");}
		my $dir = $config{directory_path}.'/usr/files/'.$dm_cfg{file_prefixe}.'/'.$field.'/'.$rec{id};
		unless (-d $dir) {mkdir($dir.'/') or log_debug("cannot create ".$dir.": $!");}
		

		my %sys = ();
		if($config{use_sys} eq 'y')
		{
			%sys = sql_line({table=>'migcms_sys',where=>"nom_table='$dm_cfg{table_name}' AND id_table='$rec{id}'"});
		}
		
		my %last_migcms_linked_file = sql_line({debug=>0,debug_results=>0,select=>"MAX(ordby) as max_ordby",table=>'migcms_linked_files',where=>"table_field='$field' AND table_name='$dm_cfg{table_name}' AND token='$rec{id}'"});
		if($last_migcms_linked_file{max_ordby} > 0)
		{
			$next_num = $last_migcms_linked_file{max_ordby} + 1;
		}
		else
		{
			$next_num = 1;
		}
		my $next_num_f = sprintf("%03d",$next_num);
		my $document_filename = get_document_filename({sequence=>$next_num_f,date=>1,prefixe=>$dm_cfg{file_prefixe},type=>'document',id=>$rec{id},sys=>\%sys});		
		$full = $document_filename;
		$full =~ s/(\.[^.]+)$//g;
				
		# print "<br />$id_rec|$file. copy: $from_path$file","$to_path$file unlink: $from_path/$file | $to_dir_base.$rec{id}";
		print "<br />copy: $from_path$file","$to_path$document_filename$ext full: $full";
		
		#copier le fichier dans le dossier du record
		copy("$from_path$file","$to_path$document_filename$ext");

		#supprimer le fichier de usr/import/
		print "<br /> unlink: $from_path$file";
		unlink("$from_path$file");
		
		#ajouter le lien en db:
		my %new_linked_file = 
		(
			'file' => $file,
			'full' => $full,
			'file_dir' => $to_dir_base.$rec{id},
			'file_path' => $to_path_base.$rec{id},
			'ordby' => 1,
			'moment'=>'NOW()',
			'table_name'=>$dm_cfg{table_name},
			'table_field'=>$field,
			'token'=>$rec{id},
			'ext'=>$ext
		);
		inserth_db($dbh,'migcms_linked_files',\%new_linked_file);	
		
	}
	exit;
}


sub get_files_list
{
	 my @files_list= ();
	 if($_[0] eq '')
	 {
		print '<br>  NO PATH';
		exit;
	 }
	 
	 my $out_path = $_[0];
     opendir (MYDIR, $out_path) || die ("cannot LS $out_path");
     my @files_array = readdir(MYDIR);
     closedir (MYDIR);
     my $cpt = 0;
     foreach my $file (@files_array) 
     {
        my $full_name = "$out_path/$file";
        my @fileprop = stat $full_name;
        if (-f $full_name) 
        {         
			push @files_list,$file;
        }   
     }
     return @files_list;
}

sub get_authentification_google
{
	my %d = %{$_[0]};

	my $id_user = $d{id_user};

	my %user = sql_line({dbh=>$dbh, table=>"users", where=>"id = '$id_user'"});

  my $content;

  my $script = get_script_google_auth();

  my $hide_block_to_link = "";
  my $hide_block_to_unlink = "";
  # UTILISATEUR DEJA ASSOCIE AU COMPTE GOOGLE
  if($user{google_linked} eq "y")
  {
    $hide_block_to_link = "hide";
  }
  else
  {
    $hide_block_to_unlink = "hide";
  }


    $content = <<"HTML";
      $script
      <!-- UTILISATEUR DEJA ASSOCIE -->
      <div class="panel panel-success block_to_unlink $hide_block_to_unlink">
        <div class="panel-heading">
          <i class="fa fa-check"></i> L'utilisateur est associé au compte Google "<span class="social_email"><strong>$user{social_email}</strong>"</span>
        </div>
        <div class="panel-body">
            <a type="submit" class="btn btn-warning google_unlinked">
             <i class="fa fa-chain-broken"></i> Désassocier le compte Google
            </a>
          </div>
      </div>
      <!-- UTILISATEUR NON ASSOCIE -->
      <div class="panel panel-warning block_to_link $hide_block_to_link">
        <div class="panel-heading">
          <i class="fa fa-exclamation-triangle"></i> Aucun compte Google associé
        </div>
        <div class="panel-body">
          <a type="submit" class="btn btn-google google_linked">
           <i class="fa fa-google"></i> Associer à un compte Google
          </a>
        </div>
      </div>

      <div class="error_message"></div>
HTML

  return $content;
}

sub get_script_google_auth {
	my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
	my $clientid = $migcms_setup{google_clientid} || "759361789094-8bb1m8593ms24pcasofq9adfgd2784c7.apps.googleusercontent.com";
  my $script = <<"HTML";
  <script>
    jQuery(document).ready(function(){

      // Désassociation du compte
      jQuery(".google_unlinked").click(function(){
        swal({   
          title: "Supprimer définitivement tous éléménts cochés ?",   
          text: 'Tapez "del" ou "DEL" pour confirmer la suppression définitive des élements cochés',   
          type: "warning",   
          showCancelButton: true,   
          closeOnConfirm: true,   
          confirmButtonColor: "#DD6B55",   

          closeOnCancel: true,  
          animation: "slide-from-top",   
          confirmButtonText: "Oui, désassocier le compte !",   
          cancelButtonText: "Non, ne rien faire",
        },
        function (isConfirm) {
          if(isConfirm)
          {
            jQuery(".se-pre-con").show();
            google_unlinked_db_ajax();
          } 
        }); 
      });

      // Association du compte
      jQuery(".google_linked").click(function(){
        jQuery(".se-pre-con").show();
        // Envoi de la requête d'authentification google
        gapi.auth.signIn(
          {
            'clientid' : "$clientid",
            'cookiepolicy' : 'single_host_origin',
            'callback' : 'signinCallback',
            'requestvisibleactions': 'http://schemas.google.com/AddActivity',
            'scope': 'https://www.googleapis.com/auth/plus.login https://www.googleapis.com/auth/userinfo.email',
          }
        ) 
        return false;
      });

    }); 

    // Chargement de l'API gapi
    (function() {
    var po = document.createElement('script'); po.type = 'text/javascript'; po.async = true;
    po.src = 'https://apis.google.com/js/client:plusone.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(po, s);
    })();

    // Retour de google pour la liaison à l'utilisateur
    function signinCallback(authResult) {
      // Si la connexion est réussie et que c'est la méthode PROMPT (et non la méthode AUTO. Permet d'empêcher 2 callbacks)
      if (authResult['status']['method'] == 'PROMPT' && authResult['status']['signed_in'] == true)
      {

        gapi.client.load('oauth2', 'v2', function()
        {
          gapi.client.oauth2.userinfo.get()
            .execute(function(resp)
            {
              // console.log(resp);
              var email     = typeof resp.email != "undefined" ? resp.email : "";
              var token     = authResult.access_token;
              var id        = typeof resp.id != "undefined" ? resp.id : "";

              var infos = {
                "email"         :  email,
                "token"         : token,
                "id"            : id,
              }

              google_linked_db_ajax(infos);         
            });
        });

      } 
      else if
      (authResult['error'])
      {
      // Une erreur s'est produite.
      // Codes d'erreur possibles :
      //   "access_denied" - L'utilisateur a refusé l'accès à l'application
      //   "immediate_failed" - La connexion automatique de l'utilisateur a échoué
      // console.log('Une erreur s'est produite : ' + authResult['error']);
      }
    }

    // Assocation du compte en DB via une requête Ajax
    function google_linked_db_ajax(infos)
    {
  
      var social_id        = infos["id"];
      var social_token     = infos["token"];
      var social_email     = infos["email"];

      jQuery(".se-pre-con").show();

      var request = jQuery.ajax(
      {
          url: 'adm_migcms_users.pl',
          type: "GET",
          data: 
          {
            sw : 'google_linked_db',
            social_id : social_id,
            social_token : social_token,  
            social_email : social_email,
          },
          dataType: "json"
      });

      request.done(function(response) 
      {
        jQuery(".se-pre-con").hide();
        if(response.status == "ok")
        {
          jQuery(".block_to_link").addClass("hide");
          jQuery(".block_to_unlink").removeClass("hide");
          jQuery(".social_email").empty().append("<strong>"+social_email+"</strong>")
          jQuery(".error_message").hide();
        }
        else
        {
          jQuery(".error_message").empty().append("<div class='alert alert-warning'>"+response.message+"</div>");
        }

      });
      request.fail(function(jqXHR, textStatus) 
      {
          
      });

    }

    function google_unlinked_db_ajax()
    {      
      var request = jQuery.ajax(
      {
          url: 'adm_migcms_users.pl',
          type: "GET",
          data: 
          {
            sw : 'google_unlinked_db',
          },
          dataType: "json"
      });

      request.done(function(response) 
      {
        jQuery(".se-pre-con").hide();
        if(response.status == "ok")
        {
          jQuery(".block_to_link").removeClass("hide");
          jQuery(".block_to_unlink").addClass("hide");
          jQuery(".error_message").hide();
        }
        else
        {
          jQuery(".error_message").empty().append("<div class='alert alert-warning'>"+response.message+"</div>");
        }

      });
    }

  </script>
HTML

  return $script;
}

sub google_linked_db
{
  my $social_id = get_quoted("social_id");
  my $social_token = get_quoted("social_token");
  my $social_email = get_quoted("social_email");

  my %response; 

  if($social_id eq "" || $social_token eq "" || social_email eq "")
  { 
    %response = (
      status => "ko",
      message => "Une ou plusieurs informations fournies par Google sont manquantes",
    );
    print JSON->new->utf8(0)->encode(\%response);
    exit; 
  }

  my %user = %{get_user_info()};

  # On cherche si un utilisateur est déjà associé à ce compte google
  my %existing_user = sql_line({dbh=>$dbh,table=>'users',where=>"social_id='$social_id'"});

  if($existing_user{id} > 0)
  {
    %response = (
      status => "ko",
      message => "Ce compte est déjà associé à l'utilisateur $existing_user{email}",
    );
    print JSON->new->utf8(0)->encode(\%response);   
    exit; 
  }
  else
  {
    
    my %update_user = (
      social_id => $social_id,
      social_token => $social_token,
      social_email => $social_email,
      google_linked => "y",
    );

    sql_set_data({dbh=>$dbh, table=>"users", where=>"id = $user{id}", data=>\%update_user});

    %response = (
      status => "ok",
      message => "L'utilisateur a été associé au compte google $social_email",
    );
    print JSON->new->utf8(0)->encode(\%response);   
    exit; 
  }

  exit;  
}

sub google_unlinked_db
{
  my %user = %{get_user_info()};

  my $social_email = $user{social_email};

  my %update_user = (
    social_id => "",
    social_token => "",
    social_email => "",
    google_linked => "n",
  );

  sql_set_data({dbh=>$dbh, table=>"users", where=>"id = $user{id}", data=>\%update_user});

  %response = (
    status => "ok",
    message => "L'utilisateur a été désacocié du compte google $social_email",
  );
  print JSON->new->utf8(0)->encode(\%response);   
  exit;

}

sub get_google_check_user_connected {
	my $script = <<"HTML";
	<script type="text/javascript">			

		/* ########## JSON cookie plugin ##########*/
(function(jQuery){var isObject=function(x){return(typeof x==='object')&&!(x instanceof Array)&&(x!==null)};jQuery.extend({getJSONCookie:function(cookieName){var cookieData=jQuery.cookie(cookieName);return cookieData?JSON.parse(cookieData):{}},setJSONCookie:function(cookieName,data,options){var cookieData='';options=jQuery.extend({expires:0,path:'/'},options);if(!isObject(data)){throw new Error('JSONCookie data must be an object')}cookieData=JSON.stringify(data);return jQuery.cookie(cookieName,cookieData,options)},removeJSONCookie:function(cookieName){return jQuery.cookie(cookieName,null)},JSONCookie:function(cookieName,data,options){if(data){jQuery.setJSONCookie(cookieName,data,options)}return jQuery.getJSONCookie(cookieName)}})})(jQuery);


			// Chargement de l'API gapi
	    (function() {
	    var po = document.createElement('script'); po.type = 'text/javascript'; po.async = true;
	    po.src = 'https://apis.google.com/js/client:plusone.js';
	    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(po, s);
	    })();

	    // Retour de google pour la liaison à l'utilisateur
	    function signinCallback(authResult) {
	      // Si la connexion est réussie et que c'est la méthode PROMPT (et non la méthode AUTO. Permet d'empêcher 2 callbacks)
	      if (authResult['status']['method'] == 'PROMPT' && authResult['status']['signed_in'] == true)
	      {

	        gapi.client.load('oauth2', 'v2', function()
	        {
	          gapi.client.oauth2.userinfo.get()
	            .execute(function(resp)
	            {
	              // console.log(resp);
	              var email     = typeof resp.email != "undefined" ? resp.email : "";
	              var token     = authResult.access_token;
	              var id        = typeof resp.id != "undefined" ? resp.id : "";

	              var infos = {
	                "email"         :  email,
	                "token"         : token,
	                "id"            : id,
	              }

	              alert("Connecté")

	              // google_linked_db_ajax(infos);         
	            });
	        });

	      } 
	      else if
	      (authResult['error'])
	      {
	      // Une erreur s'est produite.
	      // Codes d'erreur possibles :
	      //   "access_denied" - L'utilisateur a refusé l'accès à l'application
	      //   "immediate_failed" - La connexion automatique de l'utilisateur a échoué
	      // console.log('Une erreur s'est produite : ' + authResult['error']);
	      }
	    }

	    jQuery(document).ready(function(){

		    //read cookie bugi member
		    var cookie_name = "$config{migc4_cookie}";
		    var cookie_json = jQuery.JSONCookie(cookie_name);
		    var cookie_jsontext=JSON.stringify(cookie_json);
		    var cookie = eval("(" + cookie_jsontext + ")");

		    // alert(cookie.social_connect)

		    
		    if(cookie.social_connect == "y")
		    {

					  var auth2 = gapi.auth.init({
					      client_id: "$google_clientid",
					      scope: 'profile'
					   });

					}    	

			})
		</script>
HTML

	return $script;

}

sub autosave_lf
{
	see();
	
	my $id_lf = get_quoted('id_lf');
	my $content = get_quoted('content');
	my $lg = get_quoted('page_colg');
	my $field = get_quoted('field');
	# log_debug('','vide','autosave_lf');
	# log_debug($id_lf,'','autosave_lf');
	# log_debug($lg,'','autosave_lf');
	# log_debug($field,'','autosave_lf');
	# log_debug($content,'','autosave_lf');
	if($id_lf > 0 && $lg > 0 && $field ne '')
	{
		my %lf = read_table($dbh,'migcms_linked_files',$id_lf);
		if($field eq 'id_textid_url' || $field eq 'id_textid_legend')
		{
			set_traduction({id_language=>$lg,traduction=>$content,id_traduction=>$lf{$field},table_record=>'migcms_linked_files',col_record=>$field,id_record=>$lf{id}});
		}
		elsif($field eq 'blank')
		{
			$stmt = "UPDATE migcms_linked_files SET blank = '$content' WHERE id = '".$lf{id}."' ";
			# log_debug($stmt,'','autosave_lf');
			execstmt($dbh,$stmt);
		}
	}
	exit;
}

sub save_cluf
{
	my $token_user = get_quoted('token_user');
	
	$stmt = "UPDATE users SET cluf_accepte = 'y',date_cluf_accepte=NOW() WHERE token='$token_user'  ";
    execstmt($dbh_data,$stmt);
	my $url = "$config{baseurl}/admin";
	http_redirect($url);
	add_history({action=>'Condifions générales acceptées',id_user=>"$user{id}"});	
}

sub dm_sauvegarder_recherche
{
	see();
	my $token_user = get_quoted('token_user');
	my %user = sql_line({table=>'users',where=>"token='$token_user'"});
	my $name = get_quoted('name');
	$name =~ s/\'/\\\'/g;
	my $keywords = get_quoted('keywords');
	$keywords =~ s/\'/\\\'/g;
	my $tags = get_quoted('tags');
	$tags =~ s/\'/\\\'/g;
	
	my %new_migcms_recherches_sauvegardee =
	(
		id_script => get_quoted('id_script'),
		id_user => $user{id},
		name => $name,
		keywords => $keywords,
		tags => $tags,
		visible => 'y',
	);
	inserth_db($dbh,'migcms_recherches_sauvegardees',\%new_migcms_recherches_sauvegardee);	
	exit;
}

sub separ_params
{
	my $raw = $_[0];
	my @raws = split(/\//,$raw);
	return $raws[1];
}


sub save_list_edit
{
	my $id_rec = get_quoted('id_rec');
	$id_rec =~ s/\D//g;
	my $valeur = get_quoted('valeur');
	my $col = get_quoted('col');
	if($id_rec > 0 && $col ne '')
	{
		$stmt = "UPDATE $dm_cfg{table_name} SET $col = '$valeur' WHERE id='$id_rec'  ";
		print $stmt;
		execstmt($dbh_data,$stmt);
	}
	exit;
}

1;