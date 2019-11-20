#!/usr/bin/perl -I../lib
use CGI::Carp 'fatalsToBrowser';
use CGI;   
use DBI;   
use def; 
use tools; 
use dm;
use data;
use migcrender;
use def_handmade;
use dm_cms;

$dm_cfg{trad} = 1;
my $id_page = get_quoted('id_page'); 
my $sel = get_quoted('sel');
$dm_cfg{disable_mod} = 'n';   
$dm_cfg{hide_id} = 1;
$dm_cfg{enable_search} = 0;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 1;
$dm_cfg{autocreation} = 1;
$dm_cfg{duplicate} = 1;
$dm_cfg{excel} = 0;
$dm_cfg{page_cms} = 1;
$dm_cfg{pic_url} = 1;
$dm_cfg{pic_alt} = 1;
$dm_cfg{modification} = 1;
$dm_cfg{force_nr} = 1000;

$dm_cfg{wherep} = $dm_cfg{wherel} = " id_page='$id_page' ";
$dm_cfg{wherep_ordby} = "";
$dm_cfg{default_ordby} = " ordby ";
$dm_cfg{after_add_ref} = \&after_add;
$dm_cfg{after_mod_ref} = \&after_save;
# $dm_cfg{after_upload_ref} = \&after_upload;
$dm_cfg{'list_custom_action_1_func'} = \&custom_preview_ordby;
$dm_cfg{javascript_custom_func_listing} = 'custom_func_list';
my $colg = get_quoted('colg')  || $config{current_language} || 1;
# $dm_cfg{depends_on_actif_language} = 'y';
  
$dm_cfg{table_name} = "parag";
$dm_cfg{file_prefixe} = 'PAR';
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_$dm_cfg{table_name}.pl?id_page=$id_page&type=".get_quoted('type');
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{col_id} = 'id';
my $custom_html_top = '';
my $url_rewriting = get_url({debug=>0,debug_results=>0,nom_table=>'migcms_pages',id_table=>$id_page, id_language => $colg});	
my $url = "$config{baseurl}/".$url_rewriting;
my %page = sql_line({debug => 0,debug_results=>0,table=>'migcms_pages',where=>"id='$id_page'"});

%types = (
"01/content"=>"Contenu",
"03/function"=>"Fonction",
"02/menu"=>"Menu"
);

#MEMBER GROUPS
my $member_groups = '';
my @migcms_member_groups = sql_lines({table=>'migcms_member_groups'});
foreach $migcms_member_group (@migcms_member_groups)
{
	%migcms_member_group = %{$migcms_member_group};
	my ($traduit,$dum)=get_textcontent($dbh,$migcms_member_group{id_textid_name},1);
	my $checked = '';
	my %migcms_lnk_page_group = sql_line({table=>'migcms_lnk_page_groups',where=>"is_linked='y' AND id_migcms_page='$id_page' AND id_migcms_group = '$migcms_member_group{id}' "});
	if($migcms_lnk_page_group{id} > 0)
	{
		$checked =' checked = "checked" ';
	}
	$member_groups .= <<"EOH";
	<div class="checkbox"><label><input type="checkbox" $checked name="group_$migcms_member_group{id}" value="y" id="$migcms_member_group{id}" class="parag_edit_page_group_secu parag_edit_page_group_secu_$migcms_member_group{id} parag_edit_page" /> $traduit</label></div>
EOH
}
my %nb_languages = sql_line({select=>"COUNT(*) as nb",table=>'migcms_languages',where=>"visible='y' OR encode_ok = 'y'"});

%migctrad = ();
if($user{id_language} > 0 && $user{id_language} < 20)
{
}
else
{
	$user{id_language} = 1;
}

my $user_id_language_col = 'lg'.$user{id_language};
my @migcms_trads = sql_lines({debug=>1,debug_results=>1,table=>'migcms_trads',select=>"keyword,$user_id_language_col as traduction"});
foreach $migcms_trad (@migcms_trads)
{
	my %migcms_trad = %{$migcms_trad};
	$migctrad{$migcms_trad{keyword}} = $migcms_trad{traduction};
}
if($config{txt_custom} eq 'y')
{
	my @migcms_trads_custom = sql_lines({debug=>1,debug_results=>1,table=>'migcms_trads_custom',select=>"keyword,$user_id_language_col as traduction"});
	foreach $migcms_trad (@migcms_trads_custom)
	{
		my %migcms_trad = %{$migcms_trad};
		$migctrad{$migcms_trad{keyword}} = $migcms_trad{traduction};
	}
}
#NOMS ZONES TEMPLATE
my %noms_zones_template = ();
my $template_page = get_template({debug=>$d{debug},id=>$page{id_tpl_page},lg=>$colg});
$_ = $template_page;
my @pagescontents = (/<MIGC_PAGECONTENT_\[(\w+)\]_HERE>/g);
my $hidden_zone_template = 1;
for ($i = 0; $i<=$#pagescontents; $i++ ) 
{		
	$noms_zones_template{$pagescontents[$i]} = $pagescontents[$i];
	$hidden_zone_template = 0;
} 

#TITE ET METAs
my $page_title = get_traduction({id=>$page{id_textid_name},id_language=>$colg});
my $meta_title = get_traduction({id=>$page{id_textid_meta_title},id_language=>$colg});
my $meta_description = get_traduction({debug=>1,id=>$page{id_textid_meta_description},id_language=>$colg});


my $type_parag = 'parag';
my $type_template = "type = 'parag'";
my $type_page = 'page';
if(get_quoted('type') ne '' && get_quoted('type') ne 'mailing' && get_quoted('type') ne 'block') 
{
	$type_parag = get_quoted('type').'_parag';
	$type_parag2 = 'handmade_parag';
	$type_page = get_quoted('type');
	$dm_cfg{trad} = 0;
}
elsif(get_quoted('type') eq 'mailing')
{
	$type_parag = 'mailing_parag';
	$type_template = "type = 'mailing_parag'";
	$type_page = 'mailing';
	$dm_cfg{trad} = 0;
}
elsif(get_quoted('type') eq 'block')
{
	$type_parag = 'block_parag';
	$type_template = "type = 'block' || type = 'parag'";
	$type_page = 'block';
	$dm_cfg{trad} = 0;
}

#BREAD TITLE
$dm_cfg{bread_title} =<< "EOH";
$page_title <span class="divider"></span> 
EOH

#PAGE TITLE
$dm_cfg{page_title} = "$page_title";

#BLOC RETOUCHES RAPIDES
my $retouches_rapides = <<"EOH";
<a class="btn btn-lg btn-default search_element " href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page=$id_page&edit=y" data-original-title="Editer directement la page sur le site" target="_blank" data-placement="bottom">
	<i class="fa fa-pencil-square-o"></i> 
	</a>
EOH

my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
if($migcms_setup{view_edit_on} ne 'y')
{
	$retouches_rapides = '';
}

#apercu page, edition page wysiwyg
if($type_parag ne 'mailing_parag' && $type_parag2 ne 'handmade_parag' && $type_parag ne 'block_parag')
{
	#APERCU + ACCEDER + WYSIWYG
	
	my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible='y'"});
	my $menu_langues_page = '';
	foreach $language (@languages)
	{
	my %language = %{$language};
	$language{name} = uc($language{name});
	$dm_cfg{custom_navbar} .= <<"EOH";
	<a class="btn btn-lg  btn-default search_element " href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page=$id_page&lg=$language{id}" data-original-title="Aperçu des modifications" target="_blank" data-placement="bottom">
	<i class="fa fa-eye fa-fw"></i> $language{name}
	</a>
EOH
	}
		
	$dm_cfg{custom_navbar} .= <<"EOH";
	
	
	<a class="btn btn-lg  btn-default search_element " target="_blank" href="$url" data-original-title="Ouvrir la page sur le site" target="_blank" data-placement="bottom">
	<i class="fa fa-external-link fa-fw"></i> 
	</a>
	
	$retouches_rapides
	
EOH
}
else
{
	if($type_parag eq 'block_parag') {
		#APERCU
		$dm_cfg{custom_navbar} .= <<"EOH";
		<a class="btn btn-lg  btn-default search_element " href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page=$id_page&block=y&lg=1" data-original-title="Aperçu" target="_blank" data-placement="bottom">
		<i class="fa fa-eye fa-fw"></i>  
		</a>
EOH
	}


	if($type_parag eq 'mailing_parag') {
		#APERCU
		$dm_cfg{custom_navbar} .= <<"EOH";
		<a class="btn btn-lg  btn-default search_element " href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page=$id_page&mailing=y&lg=1" data-original-title="Aperçu" target="_blank" data-placement="bottom">
		<i class="fa fa-eye fa-fw"></i>  
		</a>
EOH
	
		#ENVOYER
		my %script_rec = sql_line({table=>'scripts',where=>"url LIKE '%adm_migcms_mailings_sendings.pl?%'"});
		my $link = $config{baseurl}.'/cgi-bin/adm_migcms_mailings_sendings.pl?&sw=prepare_form&id_migcms_page='.$page{id}.'&sel='.$script_rec{id}.'&mailing_basehref='.$page{mailing_basehref};			

		
		$dm_cfg{custom_navbar} .= <<"EOH";
			<a class="btn btn-lg btn-default" href="$link" data-original-title="Envoyer la newsletter" target="" data-placement="bottom">
				<i class="fa fa-paper-plane fa-fw" data-original-title="" title=""></i>
			</a>
EOH
	
		#HISTORIQUE
		my %script_rec = sql_line({table=>'scripts',where=>"url LIKE '%adm_migcms_mailings_sendings.pl?%'"});
		my $link = $config{baseurl}.'/cgi-bin/adm_migcms_mailings_sendings.pl?&id_migcms_page='.$page{id}.'&sel='.$script_rec{id};		
		
		$dm_cfg{custom_navbar} .= <<"EOH";
			<a class="btn btn-lg btn-default" href="$link" data-original-title="Historique des envois" target="" data-placement="bottom">
				<i class="fa fa-archive fa-fw" data-original-title="" title=""></i>  
			</a>
EOH
	
		#STATISTIQUES
		my %script_rec = sql_line({table=>'scripts',where=>"url LIKE '%adm_migcms_mailings_sendings.pl?%'"});
		my $link = '/cgi-bin/adm_migcms_dashboard.pl?mailing=y&id_dashboard=3&id_migcms_page='.$page{id}.'&sel='.$script_rec{id};
		$dm_cfg{custom_navbar} .= <<"EOH";
			<a class="btn btn-lg  btn-default" href="$link" data-original-title="Statistiques de la newsletter" data-placement="bottom">
				<i class="fa fa-bar-chart" aria-hidden="true"></i>
			</a>
EOH
	}
}

if($config{admin_parag_handmade} == 1)
{
	if($type_parag ne 'mailing_parag')
	{
		$dm_cfg{custom_navbar} .= def_handmade::get_parag_custom_navbar();
		$custom_html_top = def_handmade::get_parag_custom_html_top();
	}
}

my $where_type = " type='page' ";
if(get_quoted('type') ne '' && get_quoted('type') ne 'mailing') 
{
	$where_type = " type='".get_quoted('type')."' ";
}
elsif(get_quoted('type') eq 'mailing')
{
	$where_type = " type='mailing' ";
}

my $msg = get_quoted('msg');
my $listbox_templates_page = get_sql_listbox({with_blank=>'y',selected_id=>$page{id_tpl_page},col_display=>"name",table=>"templates",where=>"$where_type",ordby=>"id",name=>'id_tpl_page',class=>" parag_edit_page form-control id_tpl_page"});
my $listbox_templates_page_mailing = get_sql_listbox({with_blank=>'y',selected_id=>$page{id_tpl_page},col_display=>"name",table=>"templates",where=>"$where_type",ordby=>"id",name=>'id_tpl_page_mailing',class=>" parag_edit_page form-control id_tpl_page_mailing"});
my $listbox_campains_page_mailing = get_sql_listbox({with_blank=>'y',selected_id=>$page{mailing_id_campaign},col_display=>"campaign_name",table=>"mailing_campaigns",ordby=>"id",name=>'mailing_id_campaign',class=>" parag_edit_page form-control mailing_id_campaign"});
# my @basehref = sql_lines({debug=>'1',table=>'config',where=>"WHERE varname LIKE '%fullurl_%'",ordby=>"varname"});

my $listbox_basehref = get_sql_listbox({with_blank=>'y',selected_id=>$page{mailing_basehref},col_display=>"varvalue",table=>"config",where=>"WHERE varname LIKE '%fullurl_%'",ordby=>"id",name=>'mailing_basehref',class=>" parag_edit_page form-control list_mailing_basehref"});
my $listbox_googleanalytics = get_sql_listbox({with_blank=>'y',selected_id=>$page{mailing_googleanalytics},col_display=>"varvalue",table=>"config",where=>"WHERE varname LIKE '%google_analytics%'",ordby=>"id",name=>'mailing_googleanalytics',class=>" parag_edit_page form-control list_mailing_googleanalytics"});

# my $listbox_pages = get_sql_listbox({with_blank=>'y',selected_id=>$page{id_father},col_display=>"id_textid_name",table=>"migcms_pages",translate=>1,where=>"id != '$page{id}' AND (migcms_pages_type = 'page' OR  migcms_pages_type = 'link' OR migcms_pages_type = 'directory')",ordby=>"id",name=>'id_father',class=>"parag_edit_page parag_edit_page_id_father form-control"});
my $listbox_pages = get_listbox_pages($page{id_father},$page{id});
my $txt_url = get_traduction({id=>$page{id_textid_url},id_language=>$colg});
my $txt_url_words = get_traduction({id=>$page{id_textid_url_words},id_language=>$colg});

#valeurs des tags 
my $valeurs = '';
my @valeurs_db = sql_lines({table=>'migcms_members_tags'});
foreach $valeur_db (@valeurs_db)
{
	my %valeur_db = %{$valeur_db};
	$valeurs .= '{ "value": '.$valeur_db{id}.' , "text": "'.$valeur_db{name}.'"    },';
}

#HAUT DE PAGE SPECIFIQUE --------------------------------------------------------------------------------------------
my %class_page = ();
my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible='y'"});
my $menu_langues_page = '';
foreach $language (@languages)
{
	my %language = %{$language};
	my $class_page = 'btn-default';
	if($colg == $language{id})
	{
		$class_page = 'btn-info';
	}
	$menu_langues_page .= '<a href="'.$dm_cfg{self}.'&colg='.$language{id}.'" class="btn btn '.$class_page.'" data-original-title="" title="">'.uc($language{name}).'</a>';
}

#PLAN DU SITE (si pas mailing)
my $type_parag_disabled1 = '';
my $type_parag_disabled2 = '';
my $retour = '';
if($type_parag eq 'parag')
{
	$dm_cfg{before_main_panel_html} = '<div class="col-lg-3 hidden-xs hidden-sm hidden-md hidden-md mig-sitemap hide" style="margin-top:0px!important"><h2 style="font-size:15px;" class="maintitle migctitle hide">Accès rapide aux autres pages:</h2><div class="panel"><div class="panel-body"><table class="tree_container"></table></div></div></div>';
	$dm_cfg{main_panel_class} = "col-lg-12 col-md-12 col-sm-12 col-xs-12 main-panel-content";
	$type_parag_disabled1 = 'mailing_parag';
	$type_parag_disabled2 = 'block_parag';
	my %script_page = sql_line({table=>'scripts',where=>"url LIKE '%adm_migcms_pages.pl?%'"});
	$retour = $script_page{url}.'&sel='.$script_page{id};
}
elsif($type_parag eq 'mailing_parag') {
	$type_parag_disabled1 = 'parag';
	$type_parag_disabled2 = 'block_parag';
}
elsif($type_parag eq 'block_parag') {
	$type_parag_disabled1 = 'parag';
	$type_parag_disabled2 = 'mailing_parag';
}



$dm_cfg{list_html_top} = <<"EOH";
$custom_html_top
<style>
.list_ordby,.list_ordby_header,thead.cf,.row_actions_globales,.td-input,.mig_cb_col,td.list_action,.maintitle
{
	display:none;
}
.disable_$type_parag_disabled1
{
	display:none;
}
.disable_$type_parag_disabled2
{
	display:none;
}
.sortable-placeholder
{
	background-color:##4fcf4f;
}
.edit_group_parag > .row_edit_id_template,
.edit_group_parag > .row_edit_id_textid_title,
.edit_group_parag > .row_edit_id_textid_parag,
.edit_group_parag > .row_edit_id_textid_text_1,
.edit_group_parag > .row_edit_id_textid_text_2,
.edit_group_parag > .row_edit_id_textid_text_3,
.edit_group_parag > .row_edit_id_textid_text_4,
.edit_group_parag > .row_edit_id_textid_text_5,
.edit_group_parag > .row_edit_id_textid_textwysiwyg_1,
.edit_group_parag > .row_edit_id_textid_textwysiwyg_2,
.edit_group_parag > .row_edit_id_textid_textwysiwyg_3,
.edit_group_parag > .row_edit_id_textid_textwysiwyg_4,
.edit_group_parag > .row_edit_id_textid_textwysiwyg_5,
.edit_group_photos,
.edit_group_parag > .row_edit_id_page_directory,
.edit_group_parag > .row_edit_function,
.edit_group_parag > .row_edit_id_template_menu {
display : none;
}
\@media only screen and (max-width: 800px) {
	.list_action { display : none !important;}
}
</style>
	<script type="text/javascript"> 
	jQuery(document).ready(function() 
	{ 
		init_tabs_section();
		
		var nb_lg = jQuery('.edit_switch_language1').length;
		
	
		if('$migcms_setup{id_default_page}' == '$id_page' && nb_lg == 1)
		{
			jQuery(".toggle_url ").parent().parent().hide();
		}
		if($nb_languages{nb} == 1)
		{
			jQuery(".actiflg").parent().parent().parent().hide();
		}
	
	   custom_func_list();
	   
	   jQuery('.edit_switch_language1').click(function()
	   {
		   var id_language = jQuery(this).attr('id');
		   jQuery('.page_colg').val(id_language);
		   var request = jQuery.ajax(
			{
				url: self,
				type: "GET",
				data: 
				{
				   sw : 'refresh_page_infos',
				   id_migcms_page : jQuery('.parametre_url_id_page').val(),
				   id_language : id_language
				},
				dataType: "html"
			});
			
			request.done(function(msg) 
			{
				var tab_contenu = msg.split("___");
				jQuery('.id_textid_name_page').val(tab_contenu[0]);
				jQuery('.url_preview').html(tab_contenu[1]);
				jQuery('.edit_url').val(tab_contenu[2]);
				jQuery('#id_textid_meta_title_page').val(tab_contenu[3]);
				jQuery('#id_textid_meta_description_page').val(tab_contenu[4]);

				/*
					$retour .= $page_title.'___';
					$retour .= $url.'___';
					$retour .= $txt_url.'___';
					$retour .= $meta_title.'___';
					$retour .= $meta_description.'___';
					.id_tpl_page	
					.id_father
					.url_preview
					.edit_url 
					#id_textid_meta_title_page
					#id_textid_meta_description_page
				*/
				
			   
			});
			request.fail(function(jqXHR, textStatus) 
			{
			});
		   
		   
		   
		   
		   
	   });
	   
	    
	   jQuery('.toggle_tab').click(function()
	   {
			var enfonce = false;
			if(jQuery(this).hasClass('btn-primary'))
			{
				enfonce = true;
			}
			
			jQuery('.toggle_tab').removeClass('btn-primary').addClass('btn-default');
			if(enfonce)
			{
				jQuery('.toggle_div').removeClass('hide').addClass('hide');
			}
			else
			{
				jQuery(this).addClass('btn-primary').removeClass('btn-default');
				
				jQuery('.toggle_div').removeClass('hide').addClass('hide');
				jQuery('.toggle_div_'+jQuery(this).attr('id')).removeClass('hide');
			}
			
			return false;			
	   });
	   
	   jQuery('.toggle_plansite').click(function()
	   {
		   var me = jQuery(this);
		   me.toggleClass('btn-default').toggleClass('btn-primary');
		   
		   if(me.hasClass('btn-primary'))
		   {
				jQuery(".mig-sitemap").removeClass('hide');
				jQuery(".main-panel-content").removeClass('col-lg-12').addClass('col-lg-9');
		   }
		   else
		   {
				jQuery(".mig-sitemap").addClass('hide');
				jQuery(".main-panel-content").removeClass('col-lg-9').addClass('col-lg-12');
		   }
		   
	   
		return false;
	   });
	   
	   jQuery('.edit_page_infos').click(function()
	   {
			var me = jQuery(this);
			me.toggleClass('btn-default').toggleClass('btn-info');
		   
		   if(me.hasClass('btn-info'))
		   {
				jQuery(".page_infos_container").removeClass('hide');
		   }
		   else
		   {
				jQuery(".page_infos_container").addClass('hide');
		   }
			
			return false;
	   });
	   
	   jQuery(document).on("change", ".save_template", save_template_ajax);
	   
	   if('$msg' == 'verrou_ok')
	   {
			modif_verrou_ok();
	   }
		
		if(jQuery('.dropzone_container_alt').length)
		{
			var alt_prefixe = 'pages';
			var alt_edit_id = jQuery('.parametre_url_id_page').val();
			var alt_table_name = 'migcms_pages';
			//alert('load_files_admin...:'+alt_prefixe+','+alt_edit_id+','+alt_table_name);
			load_files_admin_alt(alt_prefixe,alt_edit_id,alt_table_name);
		}
		
		jQuery(document).on("click", ".mailing_include_pics", parag_edit_page);
		jQuery(document).on("click", ".mailing_autoconnect", parag_edit_page);
		jQuery(document).on("click", ".mailing_headers", parag_edit_page);
		jQuery(document).on("blur", ".parag_edit_page", parag_edit_page);
		jQuery(document).on("blur", ".mailing_alt_html", parag_edit_page);
		jQuery(document).on("change", ".parag_edit_page,.tt-input", parag_edit_page);
		jQuery(document).on("click", ".tt-suggestion", parag_edit_page);
		jQuery(document).on("click", ".toggle_url_btn", toggle_url_btn);
		if(0 && '$type_page' != 'mailing')
		{
		  var request = jQuery.ajax(
		  {
			  url: 'adm_migcms_preview_pages.pl?',
			  type: "GET",
			  data: 
			  {
				 sw : 'list_body_ajax',
				 nr : 25,
				 page : 1,
				 sel : '$sel',
				 sel_page : '$sel',
				 id_page : '$id_page'
			  },
			  dataType: "html"
		  });
		
		request.done(function(msg) 
		{
		   msg = msg.replace('______1____________','');
		   msg = msg.replace('___','');
		   
		   jQuery(".tree_container").html(msg);
		    //makedotdotdot();
		});
		request.fail(function(jqXHR, textStatus) 
		{
		});
		}
		
		jQuery(document).ajaxComplete(function(event, xhr, settings) {
			if (~settings.url.indexOf("sw=edit_ajax")) {
				//parag_fields();
				var type = jQuery("#field_content_type").val();
				parag_type(type);
			}
		});
		
		jQuery(document).on("change", "#field_content_type",parag_type);
		jQuery(document).on("changed.bs.select", ".migcms_field_update_id_template", parag_type);
	});
	
	
	function load_files_admin_alt(prefixe,edit_id,table_name)
	{
		var self_script = get_self();
		var upload_parametres = '';
	
		upload_parametres += prefixe;
		upload_parametres += '-';
		upload_parametres += edit_id;
		upload_parametres += '-';
		upload_parametres += table_name;	
		
		var self = 'migcms_simple_upload_file.pl?';
			
		jQuery(".dropzone_container_alt").each(function(i)
		{
			var fieldname = jQuery(this).attr('id');
			var label = jQuery(this).attr('rel');
			var field_upload_parametres = upload_parametres;
			field_upload_parametres += '-';
			field_upload_parametres += fieldname;
			
			field_upload_parametres += '-';
			var dropzone_container_alt_fieldname = 	'.dropzone_container_alt_'+fieldname;

			jQuery(dropzone_container_alt_fieldname).html('<div class="files_dropzone_'+fieldname+' dropzone "></div><div id="'+fieldname+'" class="files_get_file_list_alt files_get_file_list_alt_'+fieldname+'"></div>');
			var myDropzone = new Dropzone(".files_dropzone_"+fieldname,
			{ 
				url: self+field_upload_parametres,
				methode : 'GET',
				parallelUploads: 1,
				dictDefaultMessage:label			

			});
			
			myDropzone.on("complete", function(file) 
			{
				refresh_files_admin_alt();
		
				var request = jQuery.ajax(
				{
					url: self_script,
					type: "GET",
					data: 
					{
					   sw : 'dm_after_upload_file_alt',
					   fieldname : fieldname,
					   edit_id : edit_id
					},
					dataType: "html"
				});
				
				request.done(function(msg) 
				{			
					
				});
			
				
				
			});
			
		});
		refresh_files_admin_alt();
	}
	
	function refresh_files_admin_alt()
	{
		var self = get_self('full');
		jQuery(".files_get_file_list_alt").each(function(i)
		{
			var filename = jQuery(this).attr('id');
			var alt_prefixe = 'pages';
			var alt_edit_id = jQuery('.parametre_url_id_page').val();
			var alt_table_name = 'migcms_pages';

			var request = jQuery.ajax(
			{
				url: self,
				type: "GET",
				data: 
				{
				   sw : 'refresh_files_admin',
				   token : alt_edit_id,
				   filename : filename,
				   file_prefixe : alt_prefixe,
				   table_name : alt_table_name,
				   colg : jQuery('.colg').val()
				},
				dataType: "html"
			});
		
		request.done(function(msg_r) 
		{
		   var msg=msg_r.replace("table-sort","table-sort-dis");
		   jQuery('.files_get_file_list_alt_'+filename).html(msg);
		  
		   jQuery(".show_only_after_document_ready").removeAttr('disabled');
			
		   //delete file
		   jQuery('.list_del_file').click(function()
			{
				var id_migcms_linked_file = jQuery(this).attr('rel');
				if(id_migcms_linked_file != '')
				{
					if(confirm("Voulez-vous supprimer le fichier "+jQuery(this).attr('title')+' ?'))
					{
						var request = jQuery.ajax(
						{
							url: self,
							type: "GET",
							data: 
							{
							   sw : 'list_del_file',
							   id_migcms_linked_file : id_migcms_linked_file
							},
							dataType: "html"
						});
						
						request.done(function(msg) 
						{
						   refresh_files_admin_alt();
						});
						request.fail(function(jqXHR, textStatus) 
						{
						});
					
					}		
				}
				return false;
			});
		   
		});
		request.fail(function(jqXHR, textStatus) 
		{
		});
			
			
		});

	}
	
	function init_tabs_section() {
		var url = window.location.href;
		if (~url.indexOf("type=mailing")) {
			jQuery("div#tab_parammailing").removeClass("hide");
			jQuery("a#tab_parammailing").removeClass("btn-default").addClass("btn-primary");
		}
		else if (~url.indexOf("type=block")) {
			jQuery("div#tab_paramblock").removeClass("hide");
			jQuery("a#tab_paramblock").removeClass("btn-default").addClass("btn-primary");
		}
		else {
			jQuery("div#tab_parametres").removeClass("hide");
			jQuery("a#tab_parametres").removeClass("btn-default").addClass("btn-primary");
		}
	}
	
	//TEMPLATES
	function parag_fields(type) {
	
		if(type != "content" || type != "menu" || type != "function" || type == "") {
			type = jQuery("#field_content_type").val();
		}
		
		console.log(type);
		
		var field_values = jQuery(".migcms_field_update_id_template").selectpicker('val');
		
		var active_title = "";
		var active_content = "";
		var active_txt_1 = "";
		var active_txt_2 = "";
		var active_txt_3 = "";
		var active_txt_4 = "";
		var active_txt_5 = "";
		var active_textwysiwyg_1 = "";
		var active_textwysiwyg_2 = "";
		var active_textwysiwyg_3 = "";
		var active_textwysiwyg_4 = "";
		var active_textwysiwyg_5 = "";
		var active_pics = "";
		
		if(field_values != "") {
			field_values = jQuery('.migcms_field_update_id_template > option[value="'+field_values+'"]').attr("field_params");
			field_values_array = field_values.split('|');
			active_title = field_values_array[1];
			active_content = field_values_array[2];
			active_txt_1 = field_values_array[3];
			active_txt_2 = field_values_array[4];
			active_txt_3 = field_values_array[5];
			active_txt_4 = field_values_array[6];
			active_txt_5 = field_values_array[6];
			active_textwysiwyg_1 = field_values_array[7];
			active_textwysiwyg_2 = field_values_array[8];
			active_textwysiwyg_3 = field_values_array[9];
			active_textwysiwyg_4 = field_values_array[10];
			active_textwysiwyg_5 = field_values_array[10];
			active_pics = field_values_array[11];
		}
		
		if(type == "content") {
			jQuery(".edit_group_parag > .row_edit_id_page_directory").hide();
			jQuery(".edit_group_parag > .row_edit_function").hide();
			jQuery(".edit_group_parag > .row_edit_id_template_menu").hide();
		
			if(active_title == 'y') {jQuery(".edit_group_parag > .row_edit_id_textid_title").show();	} else { jQuery(".edit_group_parag > .row_edit_id_textid_title").hide(); }
			if(active_content == 'y') {jQuery(".edit_group_parag > .row_edit_id_textid_parag").show();	} else { jQuery(".edit_group_parag > .row_edit_id_textid_parag").hide(); }
			if(active_pics == 'y') {jQuery(".edit_group_photos").show();	} else { jQuery(".edit_group_photos").hide(); }
			if(active_txt_1 == 'y') {jQuery(".edit_group_parag > .row_edit_id_textid_text_1").show();	} else { jQuery(".edit_group_parag > .row_edit_id_textid_text_1").hide(); }
			if(active_txt_2 == 'y') {jQuery(".edit_group_parag > .row_edit_id_textid_text_2").show();	} else { jQuery(".edit_group_parag > .row_edit_id_textid_text_2").hide(); }
			if(active_txt_3 == 'y') {jQuery(".edit_group_parag > .row_edit_id_textid_text_3").show();	} else { jQuery(".edit_group_parag > .row_edit_id_textid_text_3").hide(); }
			if(active_txt_4 == 'y') {jQuery(".edit_group_parag > .row_edit_id_textid_text_4").show();	} else { jQuery(".edit_group_parag > .row_edit_id_textid_text_4").hide(); }
			if(active_txt_5 == 'y') {jQuery(".edit_group_parag > .row_edit_id_textid_text_5").show();	} else { jQuery(".edit_group_parag > .row_edit_id_textid_text_5").hide(); }
			if(active_textwysiwyg_1 == 'y') {jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_1").show();	} else { jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_1").hide(); }
			if(active_textwysiwyg_2 == 'y') {jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_2").show();	} else { jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_2").hide(); }
			if(active_textwysiwyg_3 == 'y') {jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_3").show();	} else { jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_3").hide(); }
			if(active_textwysiwyg_4 == 'y') {jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_4").show();	} else { jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_4").hide(); }
			if(active_textwysiwyg_5 == 'y') {jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_5").show();	} else { jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_5").hide(); }
		}
		else {
			jQuery(".edit_group_parag > .row_edit_id_textid_title").hide();
			jQuery(".edit_group_parag > .row_edit_id_textid_parag").hide();
			jQuery(".edit_group_photos").hide();
			jQuery(".edit_group_parag > .row_edit_id_textid_text_1").hide();
			jQuery(".edit_group_parag > .row_edit_id_textid_text_2").hide();
			jQuery(".edit_group_parag > .row_edit_id_textid_text_3").hide();
			jQuery(".edit_group_parag > .row_edit_id_textid_text_4").hide();
			jQuery(".edit_group_parag > .row_edit_id_textid_text_5").hide();
			jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_1").hide();
			jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_2").hide();
			jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_3").hide();
			jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_4").hide();
			jQuery(".edit_group_parag > .row_edit_id_textid_textwysiwyg_5").hide();

			if(type == "menu") {
				jQuery(".edit_group_parag > .row_edit_id_template_menu").show();
				jQuery(".edit_group_parag > .row_edit_id_page_directory").show();
			}
			
			else if(type == "function") {
				jQuery(".edit_group_parag > .row_edit_function").show();
			}
		}
	}
	
	function parag_type()  {
		jQuery(".edit_group_parag > .row_edit_id_template").hide();
		var type = jQuery("#field_content_type").val();
	
		if(type != '')
		{
			jQuery(".edit_group_parag > .row_edit_id_template").show();
			parag_fields(type);
		}
		else {
			jQuery(".edit_group_parag > .row_edit_id_template").hide();
		}
    }
		
	function save_template_ajax()
	{
		var me = jQuery(this);
		var id_template = me.val();
		var id_parag = me.attr('id');
		
		var request = jQuery.ajax(
		{
			url: self,
			type: "GET",
			data: 
			{
			   sw : 'save_template_ajax',
			   id_template :id_template,
			   id_parag :id_parag
			},
			dataType: "html"
		});
		
		request.done(function(msg) 
		{
				jQuery.bootstrapGrowl('<i class="fa fa-info"></i> $migctrad{templates_title}', { type: 'success',align: 'center',
				width: 'auto' });

		});
		request.fail(function(jqXHR, textStatus) 
		{

		});
	}
	
	function custom_func_list()
	{
		//déplace les boutons en haut
		jQuery("td.list_action").each(function(i)
		{
			var me = jQuery(this);
			var line = me.parent();
			var bouton_container = line.children('.mig_cell_func_1').find('.mig_cms_value_col_topactions_button');
			bouton_container.html(me.html());
		});
		

	}
	
	function toggle_url_btn()
	{
		jQuery('.url_preview,.toggle_url').toggleClass('hide');
		return false;
	}
	

	
	function parag_edit_page()
	{	
		if('$type_page' != 'mailing')
		{
			jQuery('.savestatus').removeClass('hide');
			var self = '$dm_cfg{self}';
			var data_object = 
			{
				   id_page : jQuery('.parametre_url_id_page').val(),
				   id_father : jQuery('.parag_edit_page_id_father').val(),
				   id_tpl_page : jQuery('.id_tpl_page').val(),
				   type : '$type_page',
				   sel : '$sel',
				   id_textid_name_page : jQuery('.id_textid_name_page').val(),
				   colg : jQuery('.page_colg').val(),
				   id_textid_meta_title_page : jQuery('#id_textid_meta_title_page').val(),
				   edit_url : jQuery('.edit_url').val(),
				   id_textid_meta_description_page : jQuery('#id_textid_meta_description_page').val(),
				   sw : 'parag_page_db'
			};
			
			jQuery('.parag_edit_page_group_secu').each(function(i)
			{
				var me = jQuery(this);
				var valeur = 'n';
				if(me.prop('checked') == true)
				{
					valeur = 'y';
				}
				data_object['group_'+me.attr('id')] = valeur;
			});
			
			jQuery('.actiflg').each(function(i)
			{
				var me = jQuery(this);
				var valeur = 'n';
				if(me.prop('checked') == true)
				{
					valeur = 'y';
				}
				data_object['actif_'+me.attr('id')] = valeur;
			});
			
			
			
			var request = jQuery.ajax(
			{
				url: self,
				type: "POST",
				data: data_object,
				dataType: "html"
			});
			
			request.done(function(msg) 
			{	
				jQuery('.savestatus').addClass('hide');
			});
			
			
			
			
			//boucler sur les groupes
			//parag_edit_page_group_secu_ID
			
			//boucler sur les langues
			var actif_LGID  = '';
			
			//requete ajax vers parag_page_db
		}
		else
		{
			//MAILING
			
			
			jQuery('.savestatus').removeClass('hide');
			var self = '$dm_cfg{self}';
			var data_object = 
			{
				   id_page : '$id_page',
				   mailing_from : jQuery('.mailing_from').val(),
				   mailing_from_email : jQuery('.mailing_from_email').val(),
				   mailing_name : jQuery('.mailing_name').val(),
				   mailing_object : jQuery('.mailing_object').val(),
				   tracking_url : jQuery('.tracking_url').val(),
				   id_tpl_page : jQuery('.id_tpl_page_mailing').val(),
				   mailing_alt_html : jQuery('.mailing_alt_html').val(),
				   mailing_include_pics : jQuery('.mailing_include_pics:checked').val(),
				   mailing_autoconnect : jQuery('.mailing_autoconnect:checked').val(),
				   mailing_headers : jQuery('.mailing_headers:checked').val(),
				   mailing_basehref : jQuery('.list_mailing_basehref').val(),
				   mailing_googleanalytics : jQuery('.list_mailing_googleanalytics').val(),
				   mailing_id_campaign : jQuery('.mailing_id_campaign').val(),
				   sw : 'parag_mailing_db'
			};
			
			var request = jQuery.ajax(
			{
				url: self,
				type: "POST",
				data: data_object,
				dataType: "html"
			});
			
			request.done(function(msg) 
			{	
				jQuery('.savestatus').addClass('hide');
			});
			
			//boucler sur les groupes
			//parag_edit_page_group_secu_ID
			
			//boucler sur les langues
			var actif_LGID  = '';
			
			//requete ajax vers parag_page_db
		}
	}

	function modif_verrou_ok()
	{
		 jQuery.bootstrapGrowl('<h4><i class="fa fa-check"></i> Modifications sauvegardées.</h4>', { type: 'success',align: 'center',
						width: 'auto',offset: {from: 'top', amount: 20}, delay: 5000});
	}
	</script>
EOH



my $liste_langues = '';
	my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible = 'y' || encode_ok = 'y'"});
    foreach $language (@languages)
    {
        my %language = %{$language};
		my $check = '';
		if($page{'actif_'.$language{id}} eq 'y')
		{
			$check = ' checked = "checked" ';
		}
		$liste_langues .= '<label class="btn btn-default parag_edit_page"><input  '.$check.' type="checkbox" id="'.$language{id}.'" class="actiflg actif_'.$language{id}.'" name="actif_'.$language{id}.'" value="y"> '.uc($language{name}).'</label> ';
	}

	my $render_page_fr = $render_page_nl = '';

	my $label_title = $migctrad{parag_id_textid_title};
	my $mailing_include_pics_checked = '';
	my $mailing_headers_checked = '';
	my $mailing_autoconnect = '';
	if($type_parag eq 'mailing_parag')
	{
		$render_page_fr = trim(render_page({mailing=>'y',debug=>0,id=>$id_page,lg=>1,preview=>'y',edit=>'n'}));
		if($page{mailing_include_pics} eq 'y')
		{
			$mailing_include_pics_checked = ' checked="checked" ';
		}
		if($page{mailing_headers} eq 'y')
		{
			$mailing_headers_checked = ' checked="checked" ';
		}
		if($page{mailing_autoconnect} eq 'y')
		{
			$mailing_autoconnect_checked = ' checked="checked" ';
		}
		
		
	}
	
	my $hide_pageparams = "";
	if($type_parag2 eq 'handmade_parag')
	{
		$render_page_fr = trim(render_page({mailing=>'y',debug=>0,id=>$id_page,lg=>1,preview=>'y',edit=>'n'}));
		$hide_pageparams = "hide";
	}
	
	$dm_cfg{panel_html_top} .= <<"EOH"; 
	<br />
	<div class="btn-group" role="group" aria-label="..." style="margin-right:15px!important;margin-left:15px!important;">
		<a class="btn btn-default toggle_tab disable_parag parag_tab" id="tab_parametres">
			<i class="fa fa-file-text-o fa-fw"></i> $migctrad{page_params}
		</a>
		<a class="btn btn-default toggle_tab disable_parag parag_tab $hide_pageparams" id="tabo_google">
			<i class="fa fa-google fa-fw"></i> $migctrad{page_seo}
		</a>
		<a class="btn btn-default toggle_tab disable_parag parag_tab $hide_pageparams" id="tab_secu">
			<i class="fa fa-lock fa-fw"></i> $migctrad{page_security}
		</a>
		<a class="btn hide btn-default toggle_plansite disable_paragparag_tab $hide_pageparams">
			<i class="fa fa-sitemap fa-fw"></i> $migctrad{page_sitemap}
		</a>
		<a class="btn btn-default toggle_tab disable_mailing_parag parag_tab $hide_pageparams" id="tab_parammailing">
			<i class="fa fa-file-text-o fa-fw"></i> $migctrad{mailing_params}
		</a>
		<a class="btn btn-default toggle_tab disable_mailing_parag parag_tab $hide_pageparams" id="tab_althtml">
			<i class="fa fa-code fa-fw"></i> $migctrad{mailing_canevas_html}
		</a>
		<a class="btn btn-default toggle_tab disable_mailing_parag parag_tab $hide_pageparams" id="tab_trackmailing">
			<i class="fa fa-bar-chart fa-fw"></i> $migctrad{mailing_tracking}
		</a>
		<a class="btn btn-default toggle_tab disable_block_parag parag_tab $hide_pageparams" id="tab_paramblock">
			<i class="fa fa-file-text-o fa-fw"></i> $migctrad{block_params}
		</a>
EOH
if($config{mailing_renderhtml_tab} eq "y") 
{
	$dm_cfg{panel_html_top} .= <<"EOH"; 
		<a class="btn btn-default toggle_tab disable_mailing_parag parag_tab $hide_pageparams" id="tab_html">
			<i class="fa fa-code fa-fw"></i> $migctrad{mailing_render_html}
		</a>
EOH
}
	
	$field_name = 'imageog';
	
	my $bloc_edit_url = <<"EOH";
	<div class="toggle_url ">
		<span class="url_preview">$url</span>
		<a href="#" class="toggle_url_btn btn btn-link"><i class="fa fa-edit"></i> $migctrad{page_modifyurl}</a>
	</div>
	<div class="toggle_url hide">
		$config{baseurl}/fr/<input type="text" class="edit_url parag_edit_page" name="edit_url" value="$txt_url_words" />
	</div>
EOH
	
	my %url_forcee = sql_line({table=>'migcms_force_urls',where=>"nom_table='migcms_pages' AND id_table='$page{id}' AND id_lg='$colg'"});
	if($url_forcee{id} > 0)
	{
		#on ne touche pas à l'url
		$bloc_edit_url = <<"EOH";
		<div class=" ">
			<span class="url_preview">$url</span>
			<a href="#" class="disabled btn btn-default" disabled><i class="fa fa-lock"></i> </a>
		</div>		
EOH
	}
	
	
	$dm_cfg{panel_html_top} .= <<"EOH"; 
		<a class="btn btn-link savestatus disbled hide" disabled style="color:green;" id="">
			<i class="fa fa-floppy-o fa-fw" aria-hidden="true"></i>
		</a>
	</div>
	<input type="hidden" class="page_colg" value="$colg" />
	<div class="hide toggle_div toggle_div_tab_parametres form-horizontal adminex-form" id="tab_parametres">
		<div class="well" style="margin-right:15px!important;margin-left:15px!important;border-radius:0px 4px 4px 4px !important;">
			<div class="edit_group">
			
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="field_id_textid_name"> $label_title </div>
					<div class="col-sm-10 mig_cms_value_col"><input type="text" class="form-control input-block parag_edit_page id_textid_name_page" name="id_textid_name_page" value="$page_title" /></div>
				</div>

				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="field_id_textid_name"> $migctrad{templates_title}</div>
					<div class="col-sm-10 mig_cms_value_col">$listbox_templates_page</div>
				</div>
				
				<div class="form-group item $hide_pageparams">
					<div class="col-sm-2 control-label text-right" for="field_id_textid_name"> $migctrad{page_parent} </div>
					<div class="col-sm-10 mig_cms_value_col">$listbox_pages</div>
				</div>	
				
				<div class="form-group item $hide_pageparams">
					<div class="col-sm-2 control-label text-right" for=""> $migctrad{page_languages} </div>
					<div class="col-sm-10 mig_cms_value_col">$liste_langues</div>
				</div>	
				
				<div class="form-group item $hide_pageparams">
					<div class="col-sm-2 control-label text-right" for="field_id_textid_name"> $migctrad{page_url} </div>
					<div class="col-sm-10 mig_cms_value_col">
						$bloc_edit_url
					</div>
				</div>
				
			</div>
		</div>
	</div>	
		
	<div class="hide toggle_div toggle_div_tabo_google form-horizontal adminex-form $hide_pageparams" id="tabo_google">
		<div class="well" style="margin-right:15px!important;margin-left:15px!important;border-radius:0px 4px 4px 4px !important;">
			<div class="edit_group">

				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="field_id_textid_name"> $migctrad{page_metatitle} </div>
					<div class="col-sm-10 mig_cms_value_col"><input type="text" class="form-control input-block parag_edit_page" name="id_textid_meta_title_page" id="id_textid_meta_title_page" value="$meta_title" /></div>
				</div>
				
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="field_id_textid_name"> $migctrad{page_metadescription} </div>
					<div class="col-sm-10 mig_cms_value_col"><textarea class="form-control parag_edit_page" name="id_textid_meta_description_page" id="id_textid_meta_description_page">$meta_description</textarea></div>
				</div>
								
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="field_id_textid_name"> Image Facebook </div>
					<div class="col-sm-10 mig_cms_value_col">
						<div class="dropzone_container_alt dropzone_container_alt_$field_name" id="$field_name" rel="Image Facebook: Déposez une image qui sera recadrée au meilleur format pour un partage sur les réseaux sociaux">CONTAINER</div>		
					</div>
				</div>
							
				<div class="form-group item">
					<h1 class="seo-simulator-label hidden-sm hidden-xs">$migctrad{page_seosimulation}</h1>
					<div class="seo-simulator hidden-sm hidden-xs">
						<h2>$meta_title</h2>
						<div class="seo-simulator-url">$config{rewrite_host}$url</div>
						<div class="seo-simulator-text">$meta_description</div>
					</div>
				</div>
				
			</div>
		</div>
	</div>
		
	<div class="hide toggle_div toggle_div_tab_secu form-horizontal adminex-form $hide_pageparams" id="tab_secu">
		<div class="well" style="margin-right:15px!important;margin-left:15px!important;border-radius:0px 4px 4px 4px !important;">
			<div class="alert alert-info"><i class="fa fa-info-circle"></i> $migctrad{page_security_txt}</div>
			<div class="form-group item">
				<div class="col-sm-2 control-label text-right" for="field_id_textid_name"> $migctrad{page_security_groups} </div>
				<div class="col-sm-10 mig_cms_value_col">$member_groups</div>
			</div>
		</div>
	</div>
		
	<div class="hide toggle_div toggle_div_tab_althtml form-horizontal $hide_pageparams" id="tab_althtml">
		<div class="well" style="margin-right:15px!important;margin-left:15px!important;border-radius:0px 4px 4px 4px !important;">
			<div class="form-group item">
				<textarea class="form-control mailing_alt_html">$page{mailing_alt_html}</textarea>			
			</div>
		</div>
	</div>
EOH
if($config{mailing_renderhtml_tab } eq "y") {
	$dm_cfg{panel_html_top} .= <<"EOH"; 		
	<div class="hide toggle_div toggle_div_tab_html form-horizontal $hide_pageparams" id="tab_html">
		<div class="well" style="margin-right:15px!important;margin-left:15px!important;border-radius:0px 4px 4px 4px !important;">
			<div class="form-group item">
				<textarea class="form-control code_html">$render_page_fr</textarea>			
			</div>
		</div>
	</div>
EOH
}
	$dm_cfg{panel_html_top} .= <<"EOH";
	
	<div class="hide toggle_div toggle_div_tab_trackmailing form-horizontal $hide_pageparams" id="tab_trackmailing">
		<div class="well" style="margin-right:15px!important;margin-left:15px!important;border-radius:0px 4px 4px 4px !important;">
			<div class="edit_group">
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right">$migctrad{mailing_headers}</div>
					<div class="col-sm-10 mig_cms_value_col">
						<div class="checkbox">
							<label>
								<input class="mailing_headers" $mailing_headers_checked type="checkbox" name="mailing_headers" value="y" />
							</label>
						</div>
					</div>
				</div>
EOH
if($config{multisites} eq "y") {
	$dm_cfg{panel_html_top} .= <<"EOH"; 				
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="mailing_object">$migctrad{mailing_googleanalytics}</div>
					<div class="col-sm-10 mig_cms_value_col">$listbox_googleanalytics</div>
				</div>
EOH
}
if($config{mailing_externaltracking} eq "y") {
	$dm_cfg{panel_html_top} .= <<"EOH"; 				
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="mailing_object">$migctrad{mailing_extrernaltracking}</div>
					<div class="col-sm-10 mig_cms_value_col"><input type="text" class="form-control input-block parag_edit_page tracking_url" name="tracking_url" value="$page{tracking_url}" /></div>
				</div>
EOH
}
	$dm_cfg{panel_html_top} .= <<"EOH"; 
			</div>
		</div>
	</div>
		
	<div class="hide toggle_div toggle_div_tab_parammailing form-horizontal adminex-form $hide_pageparams" id="tab_parammailing">
		<div class="well" style="margin-right:15px!important;margin-left:15px!important;border-radius:0px 4px 4px 4px !important;">
			<div class="edit_group">

				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="mailing_campaign"> $migctrad{mailings_campaign_name} </div>
					<div class="col-sm-10 mig_cms_value_col">$listbox_campains_page_mailing</div>
				</div>	
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="mailing_name"> $migctrad{mailing_name} *</div>
					<div class="col-sm-10 mig_cms_value_col"><input type="text" class="form-control input-block parag_edit_page mailing_name" name="mailing_name" value="$page{mailing_name}" /></div>
				</div>	
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="mailing_from"> $migctrad{mailing_from} *</div>
					<div class="col-sm-10 mig_cms_value_col"><input type="text" class="form-control input-block parag_edit_page mailing_from" name="mailing_from" value="$page{mailing_from}" /></div>
				</div>	
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="mailing_from_email"> $migctrad{mailing_from_email} *</div>
					<div class="col-sm-10 mig_cms_value_col"><input type="text" class="form-control input-block parag_edit_page mailing_from_email" name="mailing_from_email" value="$page{mailing_from_email}" /></div>
				</div>				
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="mailing_object"> $migctrad{mailing_object} * </div>
					<div class="col-sm-10 mig_cms_value_col"><input type="text" class="form-control input-block parag_edit_page mailing_object" name="mailing_object" value="$page{mailing_object}" /></div>
				</div>
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="id_tpl_page_mailing"> $migctrad{templates_title}</div>
					<div class="col-sm-10 mig_cms_value_col">$listbox_templates_page_mailing</div>
				</div>
				<div class="form-group item hide"> <!-- trop large URI -->
					<div class="col-sm-2 control-label text-right" for="mailing_alt_html"> $migctrad{mailing_canevas_html} </div>
					<div class="col-sm-10 mig_cms_value_col"><textarea name="mailing_alt_html" class="form-control mailing_alt_html">$page{mailing_alt_html}</textarea></div>
				</div>
EOH
if($config{multisites} eq "y") {
	$dm_cfg{panel_html_top} .= <<"EOH"; 				
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="mailing_object">$migctrad{mailing_basehref}</div>
					<div class="col-sm-10 mig_cms_value_col">$listbox_basehref</div>
				</div>
EOH
}
$dm_cfg{panel_html_top} .= <<"EOH"; 
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right">$migctrad{mailing_include_photos}</div>
					<div class="col-sm-10 mig_cms_value_col">
						<div class="checkbox">
							<label>
								<input class="mailing_include_pics" $mailing_include_pics_checked type="checkbox" name="mailing_include_pics" value="y" />
							</label>
						</div>
					</div>
				</div>
EOH

if($config{disable_autoconnexion} eq "n") {
$dm_cfg{panel_html_top} .= <<"EOH"; 
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right">$migctrad{mailing_autoconnect}</div>
					<div class="col-sm-10 mig_cms_value_col">
						<div class="checkbox">
							<label>
								<input class="mailing_autoconnect" $mailing_autoconnect_checked type="checkbox" name="mailing_autoconnect" value="y" />
							</label>
						</div>
					</div>
				</div>
EOH
}
$dm_cfg{panel_html_top} .= <<"EOH"; 
			</div>
		</div>
	</div>
	
	<div class="hide toggle_div toggle_div_tab_paramblock form-horizontal adminex-form $hide_pageparams" id="tab_paramblock">
		<div class="well" style="margin-right:15px!important;margin-left:15px!important;border-radius:0px 4px 4px 4px !important;">
			<div class="edit_group">
				<div class="form-group item">
					<div class="col-sm-2 control-label text-right" for="field_id_textid_name"> $label_title </div>
					<div class="col-sm-10 mig_cms_value_col"><input type="text" class="form-control input-block parag_edit_page id_textid_name_page" name="id_textid_name_page" value="$page_title" /></div>
				</div>
			</div>
		</div>
	</div>
EOH
	
	$dm_cfg{list_html_top} .= <<"EOH"; 
		
		<!--<a class="btn btn-link disable_parag" style="position:absolute;" role="button" href="$retour">
		  <i class="fa fa-fw fa-arrow-left"></i> $migctrad{back}
		</a>-->
		
EOH


my $type = get_quoted('type');


# ONGLETS ------------------------------------
@dm_nav =
(
#	{
#		'type'=>'tab',
#		'tab'=>'parag',
#		'title'=>'Contenu',
#		'icon' =>'fa fa-font fa-fw',
#	}
#	,
#	{
#		'type'=>'tab',
#		'tab'=>'photos',
#		'title'=>'Photos',
#		'icon' =>'fa fa-picture-o fa-fw',
#	}
#	,
#	{
#		'type'=>'tab',
#		'tab'=>'langues',
#		'title'=>'Langues',
#		'icon' =>'fa fa-language fa-fw',
#	}
);

if(get_quoted('type') eq 'mailing')
{
	pop @dm_nav;
}


#FORMULAIRE EDITION ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%dm_dfl = (
	'01/content_type'=> 
	{
		'title'=>"Type de contenu",
		'tab'=>'parag',
		'fieldtype'=>'listbox',
		'data_type'=>'btn-group',
		'fieldvalues'=>\%types,
		'default_value'=>'content',
	}
	,
	'02/id_template' => 
	{
		'title'=>$migctrad{template},
		'mandatory'=>{"type" => 'not_empty' },
		'fieldtype'=>'listboxtable',
		'lbtable'=>'templates',
		'lbkey'=>'id',
		'lbdisplay'=>"name",
		'tab'=>'parag',		
		'lbwhere'=>"$type_template",
		'params'=>'active_title,active_content,active_txt_1,active_txt_2,active_txt_3,active_txt_4,active_textwysiwyg_1,active_textwysiwyg_2,active_textwysiwyg_3,active_textwysiwyg_4,active_textwysiwyg_5, active_pics'
	}     
	,
	'02/nom_zone_template'	=>{'title'=>'Zone de contenu','fieldtype'=>'listbox','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>'parag','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','fieldvalues'=>\%noms_zones_template,'hidden'=>$hidden_zone_template},
	,
	'03/id_textid_title' => 
	{
		'title'=>'Titre',
		'tab'=>'parag',
		'fieldtype'=>'text_id',
	}
	,
	'04/id_textid_parag' => 
	{
		'title'=>'Contenu',
		'tab'=>'parag',
		'fieldtype'=>'textarea_id_editor',
		
	}  
	,
	'05/id_textid_text_1' => 
	{
		'title'=>'Texte 1',
		'tab'=>'parag',
		'fieldtype'=>'text_id',
	}
	,
	'06/id_textid_text_2' => 
	{
		'title'=>'Texte 2',
		'tab'=>'parag',
		'fieldtype'=>'text_id',
	}
	,
	'07/id_textid_text_3' =>
	{
		'title'=>'Texte 3',
		'tab'=>'parag',
		'fieldtype'=>'text_id',
	}
	,
	'08/id_textid_text_4' =>
	{
		'title'=>'Texte 4',
		'tab'=>'parag',
		'fieldtype'=>'text_id',
	}
	,
	'09/id_textid_text_5' =>
	{
		'title'=>'Texte 5',
		'tab'=>'parag',
		'fieldtype'=>'text_id',
	}
	,
	'10/id_textid_textwysiwyg_1' =>
	{
		'title'=>'Contenu 1',
		'tab'=>'parag',
		'fieldtype'=>'textarea_id_editor',
		
	}  
	,
	'11/id_textid_textwysiwyg_2' =>
	{
		'title'=>'Contenu 2',
		'tab'=>'parag',
		'fieldtype'=>'textarea_id_editor',
		
	}  
	,
	'12/id_textid_textwysiwyg_3' =>
	{
		'title'=>'Contenu 3',
		'tab'=>'parag',
		'fieldtype'=>'textarea_id_editor',
		
	}  
	,
	'13/id_textid_textwysiwyg_4' =>
	{
		'title'=>'Contenu 4',
		'tab'=>'parag',
		'fieldtype'=>'textarea_id_editor',
		
	}  ,
	'14/id_textid_textwysiwyg_5' =>
		{
			'title'=>'Contenu 5',
			'tab'=>'parag',
			'fieldtype'=>'textarea_id_editor',

		}
		,
	'50/fichiers'=> 
	{
		'title'=>"Photos",
		'tab'=>'photos',
		'fieldtype'=>'files_admin',
		'disable_add'=>1,
		'msg'=>'Cliquez <b>ici</b> pour parcourir votre ordinateur ou déposez directement des photos dans ce cadre.',
	}
	,
	'51/do_not_resize'=> 
	{
		'title'=>"Ne pas redimensionner",
		'tab'=>'photos',
		'default_value'=>'n',
		'fieldtype'=>'checkbox',
		'disable_add'=>1,
	}
	,
	'70/id_template_menu' => 
	{
		'title'=>'Template menu *',
		'tab'=>'parag',
		'fieldtype'=>'listboxtable',
		'lbtable'=>'templates',
		'lbkey'=>'id',
		'lbdisplay'=>'name',
		'lbwhere'=>"type='menu'" ,
	}
	,
	'71/id_page_directory' => 
	{
		'title'=>'Menu a afficher',
		'tab'=>'parag',
		'fieldtype'=>'listboxtable',
		'lbtable'=>'migcms_pages',
		'lbkey'=>'migcms_pages.id',
		'lbdisplay'=>'id_textid_name',
		#'lbwhere'=>"migcms_pages_type = 'directory'",
		'lbwhere'=>"",
		'translate'=>"1",
	}
	,
	'72/function' => 
	{
		'title'=>'Fonction externe',
		'tab'=>'parag',
		'fieldtype'=>'text',
		'lbwhere'=>"",
	}
	,
	'99/id_page' => 
	{
		'title'=>'Page',
		'tab'=>'parag',		
		'fieldtype'=>'text',
		'hidden'=>1,
	}
	);
	
	my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible = 'y' || encode_ok = 'y'"});
    my $hidden_lg_parag = 0;
	if($type_parag eq 'mailing_parag' || $type_parag2 eq 'handmade_parag')
	{
		$hidden_lg_parag = 1;
	}
	
	my $count = 71;
	foreach $language (@languages)
    {
        my %language = %{$language};
		if($#languages == 0)
		{
			$hidden_lg_parag = 1;
		}
		
		$dm_dfl{$count.'/actif_'.$language{id}} =
		{
			'title'=>'Afficher en '.uc($language{name}),
			'tab'=>'langues',	
			'default_value'=>'n',
			hidden=>$hidden_lg_parag,
			'fieldtype'=>'checkbox'
		};
		$count++;
	}

%dm_display_fields = 
(
);


%dm_lnk_fields = 
(
"01/"=>"parag_rendu*",
);

%dm_mapping_list = 
(
	"parag_rendu"=>\&parag_rendu,
);
%dm_filters = 
(
);

$sw = $cgi->param('sw') || "list";

if($sw ne 'parag_page_db')
{
	see();
}

my @fcts = qw(
			add_form
			mod_form
			list
			parag_page_db
		);
		
if (is_in(@fcts,$sw)) 
{ 
	dm_init();
	&$sw();
	$migc_output{content} .= $dm_output{content};
	$migc_output{title} = $dm_output{title}.$migc_output{title};
	print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub parag_rendu
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %d = %{$_[3]};
  my %parag = read_table($dbh,"parag",$id);
  if($parag{handmade_type} ne '' && $parag{handmade_id} > 0)
  {
	 my $func = 'def_handmade::'.'parag_rendu_'.$parag{handmade_type};
	 return &$func({parag=>\%parag,admin=>'y',d=>\%d});
	 exit;
  }
  
  if(get_quoted('lg') > 0)
  {
  $config{current_language} = get_quoted('lg');
  }
  
  my ($title,$dum) = get_textcontent($dbh,$parag{id_textid_title},$config{current_language});
  my ($parag,$dum) = get_textcontent($dbh,$parag{id_textid_parag},$config{current_language});
  my ($text1,$dum) = get_textcontent($dbh,$parag{id_textid_text_1},$config{current_language});
  my ($text2,$dum) = get_textcontent($dbh,$parag{id_textid_text_2},$config{current_language});
  my ($text3,$dum) = get_textcontent($dbh,$parag{id_textid_text_3},$config{current_language});
  my ($text4,$dum) = get_textcontent($dbh,$parag{id_textid_text_4},$config{current_language});
  my ($text5,$dum) = get_textcontent($dbh,$parag{id_textid_text_5},$config{current_language});
  my ($textwysiwyg1,$dum) = get_textcontent($dbh,$parag{id_textid_textwysiwyg_1},$config{current_language});
  my ($textwysiwyg2,$dum) = get_textcontent($dbh,$parag{id_textid_textwysiwyg_2},$config{current_language});
  my ($textwysiwyg3,$dum) = get_textcontent($dbh,$parag{id_textid_textwysiwyg_3},$config{current_language});
  my ($textwysiwyg4,$dum) = get_textcontent($dbh,$parag{id_textid_textwysiwyg_4},$config{current_language});
  my ($textwysiwyg5,$dum) = get_textcontent($dbh,$parag{id_textid_textwysiwyg_5},$config{current_language});
  my $photos = '';
  
  #si parag.donotresize != migcms_linked_files.donotresize -> reporter parag sur linkedfiles
  my %test_linked_file = sql_line({select=>'id',table=>'migcms_linked_files',where=>"table_name='parag' AND token='$id' AND do_not_resize != '$parag{do_not_resize}'"});
  if($test_linked_file{id} > 0 && $parag{do_not_resize} ne '')
  {
	$stmt = "UPDATE migcms_linked_files SET do_not_resize = '$parag{do_not_resize}' WHERE table_name='parag' AND token='$id' AND do_not_resize != '$parag{do_not_resize}'";
    execstmt($dbh,$stmt);
  }
  
  my @migcms_linked_files = sql_lines({table=>'migcms_linked_files',where=>"table_name='parag' AND token='$id'",ordby=>'ordby'});
  foreach $migcms_linked_file (@migcms_linked_files)
  {
		my %migcms_linked_file = %{$migcms_linked_file};
		my $txt_url = get_traduction({id=>$migcms_linked_file{id_textid_url},id_language=>$config{current_language}});		
		
		if($migcms_linked_file{do_not_resize} eq 'y')
		{
			my $url_pic_preview = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
			$photos .= "<a href='#' id='$id' class='migedit_$id migedit'><img style=\"height:75px\" src='$url_pic_preview' /></a> ";
			# $photos .= '<div style="height:75px; position:relative;"><a href="#"  id="'.$id.'" class="migedit_'.$id.' migedit"><figure class="zoo-item" zoo-image="'.$url_pic_preview.'" zoo-scale="1.5"></figure></a></div>';
		}
		else
		{
			my $url_pic_preview = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{name_mini};
			$photos .= "<a href='#'  id='$id' class='migedit_$id migedit'><img style=\"height:75px\"  src='$url_pic_preview' /></a> ";
			# $photos .= '<div style="height:75px; position:relative;"><a href="#"  id="'.$id.'" class="migedit_'.$id.' migedit"><figure class="zoo-item" zoo-image="'.$url_pic_preview.'" zoo-scale="1.5"></figure></a></div>';
		}
		if($txt_url ne '')
		{
			$photos .= "<br />[<a href=\"$txt_url\" target=\"_blank\">$txt_url</a>]<br />";
		}
  }
  
  my $zone_color = 'label-primary';
  if($parag{nom_zone_template} eq '')
  {
		$parag{nom_zone_template} = 'Zone principale';
		$zone_color = 'label-success';
  }
  
    my $content_type = "";
	if($parag{content_type} eq "content") {
		$content_type = ' - Contenu';
	}
	elsif($parag{content_type} eq "menu") {
		$content_type = ' - Menu';
	}
	elsif($parag{content_type} eq "function") {
		$content_type = ' - Fonction externe';
	}
  
	$zone = '<span class="label '.$zone_color .'">'.ucfirst(lc($parag{nom_zone_template})).$content_type.'</span>';
	$zone =~ s/_/ /g;
  
	my @templates = sql_lines({table=>'templates',where=>$type_template,ordby=>"name"});
	my $list_templates = '';
	foreach $template(@templates)
	{
		my %template = %{$template};
		my $selected = '';
		if($template{id} == $parag{id_template})
		{
			$selected = 'selected';
		}
		
		$list_templates .=<<"EOH";
			<option $selected value="$template{id}">$template{name}</option>
EOH
	}

	# if($photos ne '' && $parag ne '')
	# {
		# $photos = '<hr />'.$photos;
	# }
	if($photos ne '')
	{
		$photos = '<hr />'.$photos;
	}
  
  
  my $warn_lg = '';
  if($parag{'actif_'.$config{current_language}} ne 'y' && $type_parag ne 'mailing_parag')
  {
	my %migcms_language = read_table($dbh,'migcms_languages',$config{current_language});
	$warn_lg = '<span class="label label-info">Désactivé pour le '.$migcms_language{display_name}.'</span>';
  }
  
	my $rendu = "";
	if($type_parag eq "parag" || $type_parag eq "mailing_parag") {
		$rendu .= <<"EOH";
		<div class="content_zone">$zone</div>
EOH
	}
	else {
	
		if($parag{content_type} eq "content") {
			$zone = '<span class="label label-success">Contenu</span>';
		}
		elsif($parag{content_type} eq "menu") {
			$zone = '<span class="label label-success">Menu</span>';
		}
		elsif($parag{content_type} eq "function") {
			$zone = '<span class="label label-success">Fonction externe</span>';
		}
	  
		$rendu .= <<"EOH";
	<div class="content_zone">$zone</div>
EOH
	
	}


	$rendu .= <<"EOH";
<div class="row">
	<div class="col-lg-6 col-md6 col-sm-12 col-xs-12">
		<div class="mig_cms_value_col_topactions_button"></div>
	</div>
	<div class="col-lg-6 col-md6 col-sm-12 col-xs-12">
		<select class="form-control save_template" id="$id">$list_templates</select>
	</div>
</div>
<hr />
$warn_lg
<div class="mig_cms_value_col">
EOH
if($title ne "" && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
$rendu .= <<"EOH";
	<h2 class="mig-parag-title">$title</h2>
EOH
}

if(($parag ne "" || $text1 ne "" || $text2 ne "" || $text3 ne "" || $text4 ne "" || $textwysiwyg1 ne "" || $textwysiwyg2 ne "" || $textwysiwyg3 ne "" || $textwysiwyg4 ne "") && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
$rendu .= <<"EOH";
	<div class="mig-parags-content">
EOH
}


if($parag ne ""  && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
$rendu .= <<"EOH";
	<div class="mig-parag-content">$parag</div>
EOH
}
if($text1 ne ""  && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
$rendu .= <<"EOH";
	<div class="mig-parag-content">$text1</div>
EOH
}
if($text2 ne ""  && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
$rendu .= <<"EOH";
	<div class="mig-parag-content">$text2</div>
EOH
}
if($text3 ne ""  && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
$rendu .= <<"EOH";
	<div class="mig-parag-content">$text3</div>
EOH
}
if($text4 ne ""  && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
$rendu .= <<"EOH";
	<div class="mig-parag-content">$text4</div>
EOH
}
if($text5 ne ""  && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
		$rendu .= <<"EOH";
	<div class="mig-parag-content">$text5</div>
EOH
}
if($textwysiwyg1 ne "" && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
$rendu .= <<"EOH";
	<div class="mig-parag-content">$textwysiwyg1</div>
EOH
}
if($textwysiwyg2 ne "" && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
$rendu .= <<"EOH";
	<div class="mig-parag-content">$textwysiwyg2</div>
EOH
}
if($textwysiwyg3 ne "" && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
$rendu .= <<"EOH";
	<div class="mig-parag-content">$textwysiwyg3</div>
EOH
}
if($textwysiwyg4 ne ""  && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
$rendu .= <<"EOH";
	<div class="mig-parag-content">$textwysiwyg4</div>
EOH
}
if($textwysiwyg5 ne ""  && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
		$rendu .= <<"EOH";
	<div class="mig-parag-content">$textwysiwyg5</div>
EOH
}
if(($parag ne "" || $text1 ne "" || $text2 ne "" || $text3 ne "" || $text4 ne "" || $textwysiwyg1 ne "" || $textwysiwyg2 ne "" || $textwysiwyg3 ne "" || $textwysiwyg4 ne "") && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
$rendu .= <<"EOH";
	</div>
EOH
}
if($photos ne "" && ($parag{content_type} eq "content" || $parag{content_type} eq "")) {
$rendu .= <<"EOH";
	<div>$photos</div>
EOH
}
if($parag{content_type} eq "menu") {

	$rendu .= "<ul>";
	my @menus = sql_lines({dbh=>$dbh,table=>"migcms_pages",where=>"visible = 'y' && id_father='$parag{id_page_directory}' ORDER BY ordby asc"});
    foreach $menu (@menus)
    {
		my %menu = %{$menu};
		my ($menu_name,$dum) = get_textcontent($dbh,$menu{id_textid_name},$config{current_language});
		$rendu .= <<"EOH";
		<li>$menu_name</li>
EOH
	}
	$rendu .= "</ul>";
}
if($parag{content_type} eq "function") {
$rendu .= <<"EOH";
	<span class="label label-info" style="font-size:14px;">$parag{function}</span> 
EOH
}
  return $rendu;
}

sub parag_mailing_db
{
	see();
	my $id_page = get_quoted('id_page');
	my %page = read_table($dbh,'migcms_pages',$id_page);
	if($page{token} eq '')
	{
		my $new_token = create_token(45);
		my $stmt = <<"EOH";
			UPDATE migcms_pages SET token = '$new_token' WHERE id = '$page{id}'
EOH
		execstmt($dbh,$stmt);
	}
	
	my $sel = get_quoted('sel');
	my $colg = get_quoted('colg') || $config{current_language};
	if($colg eq '')
	{
		$colg = 1;
	}
	
	
	my %update_page = 
	(
		mailing_from => get_quoted('mailing_from'),
		mailing_from_email => get_quoted('mailing_from_email'),
		mailing_name => get_quoted('mailing_name'),
		mailing_object => get_quoted('mailing_object'),
		tracking_url => get_quoted('tracking_url'),
		id_tpl_page => get_quoted('id_tpl_page'),
		mailing_alt_html => trim(get_quoted('mailing_alt_html')),
		mailing_include_pics => get_quoted('mailing_include_pics'),
		mailing_headers => get_quoted('mailing_headers'),
		mailing_basehref => get_quoted('mailing_basehref'),
		mailing_googleanalytics => get_quoted('mailing_googleanalytics'),
		mailing_autoconnect => get_quoted('mailing_autoconnect'),
		mailing_id_campaign => get_quoted('mailing_id_campaign'),
	);
	updateh_db($dbh,"migcms_pages",\%update_page,'id',$id_page);	
	
	exit;
}

sub parag_page_db
{
	see();
	log_debug('parag_page_db','vide','parag_page_db');
	my $id_page = get_quoted('id_page');
	my $type = get_quoted('type');
	my %page = read_table($dbh,'migcms_pages',$id_page);
	if($page{token} eq '')
	{
		my $new_token = create_token(45);
		my $stmt = <<"EOH";
			UPDATE migcms_pages SET token = '$new_token' WHERE id = '$page{id}'
EOH
		execstmt($dbh,$stmt);
	}
	
	my $sel = get_quoted('sel');
	my $colg = get_quoted('colg') || $config{current_language};
	if($colg eq '')
	{
		$colg = 1;
	}

	#NAME PAGE
	my $id_textid_name_page = get_quoted('id_textid_name_page');
	set_traduction({id_language=>$colg,traduction=>$id_textid_name_page,id_traduction=>$page{id_textid_name},table_record=>'migcms_pages',col_record=>'id_textid_name',id_record=>$page{id}});
	
	#META TITLE
	my $id_textid_meta_title_page = get_quoted('id_textid_meta_title_page');
	$id_textid_meta_title_page =~ s/\'/\\\'/g;
	if($id_textid_meta_title_page eq '')
	{
		$id_textid_meta_title_page = $id_textid_name_page;
	}
	set_traduction({id_language=>$colg,traduction=>$id_textid_meta_title_page,id_traduction=>$page{id_textid_meta_title},table_record=>'migcms_pages',col_record=>'id_textid_meta_title',id_record=>$page{id}});
	
	#META DESCRIPTION
	my $id_textid_meta_description_page = get_quoted('id_textid_meta_description_page');
	$id_textid_meta_description_page =~ s/\'/\\\'/g;
	set_traduction({id_language=>$colg,traduction=>$id_textid_meta_description_page,id_traduction=>$page{id_textid_meta_description},table_record=>'migcms_pages',col_record=>'id_textid_meta_description',id_record=>$page{id}});

	#URL
	my $edit_url = $url_words = get_quoted('edit_url');
	log_debug('$url_words:'.$edit_url,'','parag_page_db');
	log_debug('$edit_url:'.$edit_url,'','parag_page_db');
	my %url_forcee = sql_line({table=>'migcms_force_urls',where=>"nom_table='migcms_pages' AND id_table='$page{id}' AND id_lg='$colg'"});
	if($url_force{id} > 0)
	{
		#on ne touche pas à l'url
	}
	else
	{
		set_traduction({id_language=>$colg,traduction=>$url_words,id_traduction=>$page{id_textid_url_words},table_record=>'migcms_pages',col_record=>'id_textid_url_words',id_record=>$page{id}});
		set_traduction({id_language=>$colg,traduction=>$edit_url,id_traduction=>$page{id_textid_url},table_record=>'migcms_pages',col_record=>'id_textid_url',id_record=>$page{id}});
	}
	
	#SAUVEGARDE TEMPLATE ET PARENT
	my $id_tpl_page = get_quoted('id_tpl_page');
	my $id_father = get_quoted('id_father');
	
	$stmt = "UPDATE migcms_pages SET id_father='$id_father', id_tpl_page='$id_tpl_page' where id=$id_page";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt); 
	
	#SAUVEGARDE VERROUX**********************************
	my @migcms_member_groups = sql_lines({table=>'migcms_member_groups'});
	foreach $migcms_member_group (@migcms_member_groups)
	{
		%migcms_member_group = %{$migcms_member_group};
		my $valeur = get_quoted('group_'.$migcms_member_group{id});
		if($valeur ne 'y')
		{
			$valeur = 'n';
		}
		my %migcms_lnk_page_group = 
		(
			id_migcms_page => $id_page,
			id_migcms_group => $migcms_member_group{id},
			is_linked => $valeur,
		);
		sql_set_data({dbh=>$dbh,debug=>0,debug_results=>0,table=>'migcms_lnk_page_groups',data=>\%migcms_lnk_page_group, where=>"id_migcms_page ='$migcms_lnk_page_group{id_migcms_page}' AND id_migcms_group ='$migcms_lnk_page_group{id_migcms_group}'"});                            
	}
	
	
	my $valeurs_langues = '';
	my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible = 'y' || encode_ok = 'y'"});
    foreach $language (@languages)
    {
        my %language = %{$language};
		my $check = '';
		if(get_quoted('actif_'.$language{id}) eq 'y')
		{
			$valeurs_langues .= 'actif_'.$language{id}.' = "y",';
		}
		else
		{
			$valeurs_langues .= 'actif_'.$language{id}.' = "n",';
		}
	}	
	chop($valeurs_langues);
	$stmt = "UPDATE migcms_pages SET $valeurs_langues where id=$id_page";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt); 
	
	
	dm_cms::migcms_build_compute_urls();
	save_all_fathers(0);
	
	log_debug('parag_page_db END','','parag_page_db');

	
	# cgi_redirect("$dm_cfg{self}&id_page=$id_page&sel=$sel".'&msg=verrou_ok&colg='.$colg.'&type='.$type);
	exit;
}

sub save_all_fathers
{
	my $id_father = $_[0];
	
	#trouver les scripts dont le pere est $id_father
	my @scripts = sql_lines({debug=>1,debug_results=>0,table=>'migcms_pages',where=>"id_father='$id_father'",ordby=>'ordby'});
	foreach $script (@scripts)
	{
		my %script = %{$script};
		
		#calculer la colonne id_fathers en ajoutant l'id des scripts parents tant qu'il y en a.
		
		#parent direct du script
		my $liste_des_parents = '';
		my %parent_direct = sql_line({debug=>1,debug_results=>0,dbh=>$dbh,table=>"migcms_pages",where=>"id='$script{id_father}'"});
		while($parent_direct{id} > 0)
		{
			#s'il y a un parent / tant qu'il y a des parents -> ajouter à la liste
			$liste_des_parents .= ','.$parent_direct{id}.',';
			
			#parent suivant
			%parent_direct = sql_line({debug=>1,debug_results=>0,dbh=>$dbh,table=>"migcms_pages",where=>"id='$parent_direct{id_father}'"});
		}
		
		$stmt = "UPDATE migcms_pages SET id_fathers ='$liste_des_parents' WHERE id = '$script{id}' ";
		log_debug($stmt,'','save_all_fathers');
		execstmt($dbh,$stmt);
		
		#trouver les scripts dont le pere est $script{id}	
		save_all_fathers($script{id});
	}
}


sub after_add
{
	my $dbh=$_[0];
	my $id=$_[1];
	
	# my %rec = read_table($dbh,$dm_cfg{table_name},$id);
	# my %page = read_table($dbh,'migcms_pages',$rec{id_page});
		
	my $liste_langues = '';
	my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>""});
    foreach $language (@languages)
    {
        my %language = %{$language};
		# if($page{migcms_pages_type} eq 'newsletter')
		# {
			# $liste_langues .= " actif_$language{id} = 'y', ";
		# }
		# else
		# {
			$liste_langues .= " actif_$language{id} = 'y', ";
		# }
		
	}
	$liste_langues .= " visible='y' ";
	
	my $stmt = "UPDATE $dm_cfg{table_name} SET $liste_langues WHERE id = '$id'";
	execstmt($dbh,$stmt);
}

sub after_save
{
	my $dbh=$_[0];
	my $id=$_[1];
	
	after_upload($dbh,$id);
}

sub after_upload
{
	my $dbh=$_[0];
	my $id=$_[1];
	my %parag = sql_line({table=>'parag',where=>"id='$id'"});
	my %template = sql_line({table=>'templates',where=>"id='$parag{id_template}'"});
	my %parag_setup = sql_line({table=>'parag_setup',where=>""});
	
	#calcul les tailles des images: d'abord celles du templates sinon les valeurs par défaut
	my @sizes = ('mini','small','medium','large','og');
	foreach my $size (@sizes)
	{
	    if(!($template{'size_'.$size} > 0))
		{
			$template{'size_'.$size} = $parag_setup{'default_size_'.$size};
		}
	}
	
	#boucle sur les images du paragraphes
	my @migcms_linked_files = sql_lines({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"ext IN ('.jpg','.jpeg','.png') AND table_name='$dm_cfg{table_name}' AND table_field='fichiers' AND token='$id'",ordby=>'ordby'});
	foreach $migcms_linked_file (@migcms_linked_files)
	{
		#appelle la fonction de redimensionnement
		my %migcms_linked_file = %{$migcms_linked_file};
		
		if(
		$migcms_linked_file{size_mini}  > 0
		|| $migcms_linked_file{size_medium}  > 0
		|| $migcms_linked_file{size_og}  > 0
		|| $migcms_linked_file{size_large}  > 0
		|| $migcms_linked_file{size_small}  > 0	
		)
		{
			next;
		}
		
		my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
		my %params = (
			migcms_linked_file=>\%migcms_linked_file,
			do_not_resize=>$parag{do_not_resize}
		);
		foreach my $size (@sizes)
		{
			$params{'size_'.$size} = $template{'size_'.$size};
			# log_debug($size.':'.$params{'size_'.$size});
		}
		dm::resize_pic(\%params);
	}	
	
	my $stmt = "UPDATE migcms_linked_files SET do_not_resize='y' WHERE ext IN ('.gif') AND table_name='$dm_cfg{table_name}' AND table_field='fichiers' AND token='$id'";
	execstmt($dbh,$stmt);
}


sub ajax_save_parag
{
	see();
	my $id = get_quoted('id');
	my $type = get_quoted('type');
	my $content = get_quoted('content');
	my $colg = get_quoted('colg');
	my %parag = sql_line({table=>'parag',where=>"id='$id'"});
#     $content =~ s/\'/\\\'/g;
	if($type eq 'content')
	{
		my $stmt = "UPDATE txtcontents SET lg$colg='$content' WHERE id ='$parag{id_textid_parag}'";
		execstmt($dbh,$stmt);
	}
	elsif($type eq 'title')
	{
		my $stmt = "UPDATE txtcontents SET lg$colg='$content' WHERE id ='$parag{id_textid_title}'";
		execstmt($dbh,$stmt);
	}
}

sub save_template_ajax
{
	see();
	my $id_template = get_quoted('id_template');
	my $id_parag = get_quoted('id_parag');
	
	if($id_template > 0 && $id_parag > 0)	
	{
		my %rec = (
			id_template => $id_template,
		);
		updateh_db($dbh,"$dm_cfg{table_name}",\%rec,'id',$id_parag);
	}
	exit;
}

sub custom_preview_ordby
{
	my $id = $_[0];
	my $colg = $_[1];
	my %parag = %{$_[2]};
	$d{$colg} = $colg;
		
	return <<"EOH";
<a class="btn btn-lnk disabled" disabled><span class="badge ordby_number ordby_number_3" data-original-title="" title="">$parag{ordby}</span></a>
EOH
}

# <div class="row">
					# <div class="col-sm-2  text-right" for="field_id_textid_name">Segment </div>
					# <div class="col-sm-10 mig_cms_value_col">
					
										
									# <div class="input-group"> 
										# <span class="input-group-addon "><i class="fa-fw fa fa-tags "></i></span>
										# <input type="text"  placeholder="ex: Belgique, Francophone..." id="list_tags" name="list_tags" class="form-control  search_element" />
										# <input type="hidden" placeholder="" id="list_tags_vals" name="list_tags_vals" />
									# </div>
								# <script>
								# jQuery(document).ready(function() 
								# {
									
									# var tags = new Bloodhound(
									# {
										# datumTokenizer: Bloodhound.tokenizers.obj.whitespace('text'),
										# queryTokenizer: Bloodhound.tokenizers.whitespace,
										# local:
										# [ 
											# $valeurs
										# ]
									# });
									# tags.initialize();
									# elt = jQuery('#list_tags');
									# elt.tagsinput(
									# {
										# itemValue: 'value',
										# itemText: 'text',
										# typeaheadjs: 
										# {
											# name: 'tags',
											# displayKey: 'text',
											# source: tags.ttAdapter()
										# }
									# });
									# elt.on('itemAdded', function(event) 
									# {
										# var list_tags_vals = jQuery("#list_tags").val();
										# jQuery("#list_tags_vals").val(list_tags_vals);
									# });
									# elt.on('itemRemoved', function(event) 
									# {
										# var list_tags_vals = jQuery("#list_tags").val();
										# jQuery("#list_tags_vals").val(list_tags_vals);
									# });
								# });
								# </script>

					# </div>
				# </div>
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
################################################################################
# get_listbox_pages
################################################################################
sub get_listbox_pages
{
 my $selected_page = $_[0] || 0; 
 my $me = $_[1] || 0; 
 
 my $list = <<"EOH";
EOH
 $list .= '<select style="font-family:FontAwesome,Roboto Condensed,​sans-serif" name="id_father" id="" class="form-control parag_edit_page parag_edit_page_id_father form-control ">'; 
  $list .= '<option value="0"></option>';
 $list .= recurse_listbox_pages(0,0,$selected_page,$me); 

 $list .= '</select>';
 
 return $list;
}

################################################################################
# recurse_listbox_pages
################################################################################
sub recurse_listbox_pages
{
 my $father = $_[0] || 0; 
 my $level = $_[1] || 0; 
 my $selected_page = $_[2] || 0; 
 my $me = $_[3] || 0; 
 
 my $lg = $config{current_language};
 
 my $tree;
 my $decay = make_spaces($level,'-----');
 my @migcms_pages = sql_lines({debug=>0,debug_results=>0,table=>"migcms_pages",where=>"migcms_pages_type!='newsletter' AND migcms_pages_type != 'block' AND migcms_pages_type != 'handmade' AND id_father='$father'",ordby=>"ordby"});
 foreach $migcms_page (@migcms_pages)
 {
     my %migcms_page = %{$migcms_page};
     
     my ($title,$dum) = get_textcontent($dbh,$migcms_page{id_textid_name},1);
     my $suppl_selected = '';
     my $suppl_disabled = '';
     if($migcms_page{id} == $selected_page)
     {
         $suppl_selected = <<"EOH";
			selected="selected"      
EOH
     }
	 
	 if($migcms_page{id} == $me)
     {
		$suppl_disabled=<<"EOH";
	   disabled="disabled"      
EOH
		$title .= " ( &#xf129; Cette page ne peut être son propre parent )";
	 }
	 
	 my $icon = '';
	 if($migcms_page{migcms_pages_type} eq 'link')
	 {
		$icon = '&#xf0c1;';
		# $suppl_disabled=<<"EOH";
   # disabled="disabled"      
# EOH
	 }
	 elsif($migcms_page{migcms_pages_type} eq 'directory')
	 {
		$icon = '&#xf115;';
	 }
	 elsif($migcms_page{migcms_pages_type} eq 'page')
	 {
		$icon = '&#xf0f6;';
	 }
	 
	 
	 
            
     $tree .= <<"EOH";     
			<option value="$migcms_page{id}" $suppl_disabled $suppl_selected>$decay $icon $title</option>
EOH
     
     $tree.= recurse_listbox_pages($migcms_page{id},$level+1,$selected_page,$me);
 }
 
 return $tree;
}

sub refresh_page_infos
{
	my $id_migcms_page = get_quoted('id_migcms_page');
	my $id_language = get_quoted('id_language');
	
	my %migcms_page = read_table($dbh,'migcms_pages',$id_migcms_page);
	
	my $retour = '';
	
	my $page_title = get_traduction({id=>$page{id_textid_name},id_language=>$id_language});
	my $meta_title = get_traduction({id=>$page{id_textid_meta_title},id_language=>$id_language});
	my $meta_description = get_traduction({debug=>1,id=>$page{id_textid_meta_description},id_language=>$id_language});
	my $txt_url = get_traduction({id=>$page{id_textid_url},id_language=>$id_language});
	my $url_rewriting = get_url({debug=>1,debug_results=>1,nom_table=>'migcms_pages',id_table=>$id_migcms_page, id_language => $id_language});	
	my $url = "$config{baseurl}/".$url_rewriting;
	
	$retour .= $page_title.'___';
	$retour .= $url.'___';
	$retour .= $txt_url.'___';
	$retour .= $meta_title.'___';
	$retour .= $meta_description.'___';
	
	print $retour;
	exit;
}

sub dm_after_upload_file_alt
{
	log_debug('dm_after_upload_file_alt','vide','dm_after_upload_file_alt');
	
	my $edit_id = get_quoted('edit_id');
	my $fieldname = get_quoted('fieldname');
	
	log_debug($edit_id,'','dm_after_upload_file_alt');
	log_debug($fieldname,'','dm_after_upload_file_alt');
	
	if ($edit_id > 0)
	{
		after_upload_og_pic($dbh,$edit_id,$fieldname);
		exit;
	}
}

sub after_upload_og_pic
{
	my $dbh=$_[0];
	my $id=$_[1];
	my $fieldname=$_[2];

	resize_page_pics({table_field=>"$fieldname",id=>$id});
	my %migcms_linked_file = sql_line({table=>"migcms_linked_files",where=>"ordby='1' AND table_name='migcms_pages' AND table_field='imageog' AND token='$id'"});
	my $path = $config{directory_path}.'/usr/files/pages/imageog/'.$id;
	resizeog_for_page($migcms_linked_file{name_og},$migcms_linked_file{name_medium},$path);
}

sub resize_page_pics
{
	my %d = %{$_[0]};
	my @sizes = ('large','small','medium','mini','og');
	my %migcms_linked_file = sql_line({table=>"migcms_linked_files",where=>"ordby='1' AND table_name='migcms_pages' AND table_field='imageog' AND token='$d{id}'"});
	my %parag_setup = sql_line({table=>'parag_setup',where=>""});
	
	my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
	my %params = (
		migcms_linked_file=>\%migcms_linked_file,
		do_not_resize=>'n',
	);
	foreach my $size (@sizes)
	{
		$params{'size_'.$size} = $parag_setup{'default_size_'.$size};
		if($size eq 'medium')
		{
			$params{'size_'.$size} = 1200; #pour une qualite optimale
		}
	}
	dm::resize_pic(\%params);
}


sub resizeog_for_page
{
	use File::Path;
	use File::Copy;
	
	my $og_width = 1200;
	my $og_heigt = 630;
	
	my $og_file = $_[0];
	my $medium_file = $_[1];
	my $path = $_[2];
	if($og_file eq '')
	{
		# log_debug('og_file vide !','','resizeog_for_sheet');
		return 0;
	}
	
	my @splitted = split(/\./,$og_file);
	my $ext = pop @splitted;
	my $filename = join(".",@splitted);
	$filename =~ s/_og$//g;

	# 600x449 -> 1200x630
	my $original_path = $path.'/'.$og_file;
	if(!(-e $original_path))
	{
		# log_debug('Og existe PAS ! '.$original_path,'','resizeog_for_sheet');
		$original_path = $path.'/'.$medium_file;
		
		if(!(-e $original_path))
		{
			# log_debug('medium existe PAS ! '.$original_path,'','resizeog_for_sheet');

			return 0;
		}
		else
		{
			# log_debug('medium existe ! '.$original_path,'','resizeog_for_sheet');
		}
	}
	else
	{
		# log_debug('Og existe ! '.$original_path,'','resizeog_for_sheet');
	}
	
	my $inter_path = $path.'/'.$filename.'_inter.'.$ext;
	my $recoup_path = $path.'/'.$filename.'_recoup.'.$ext;
	my $original = GD::Image->new($original_path);
	my ($original_width,$original_height) = $original->getBounds();
	
	if($original_height == 0)
	{
		# log_debug('$original_height = 0 '.$original_height,'','resizeog_for_sheet');
		return 0;
	}
	if($original_width == $og_width)
	{
		unlink($inter_path);
		unlink($recoup_path);
		# log_debug('widths identiques: return 1'.$original_height,'','resizeog_for_sheet');
		return 1;
	}
	
	my $inter_ratio =  $og_heigt / $original_height;
	my $inter_height = $og_heigt;
	my $inter_width = $original_width * $inter_ratio;
	
	#nouvelle image inter
	my $inter = GD::Image->new($inter_width,$inter_height,1);
	$inter->saveAlpha(1);
	$inter->alphaBlending(0);
	$inter->copyResampled($original,0,0,0,0,$inter_width,$inter_height,$original_width,$original_height);
	my $data = $inter->jpeg(100); 
	# log_debug('>'.$inter_path,'','resizeog_for_sheet');

	open (THUMB,">$inter_path");
	binmode THUMB;  
	print THUMB $data;  
	close THUMB;  
	
	#nouvelle image taille fixe
	my $marge = $og_width - $inter_width;
	$marge /= 2;
	
	my $recoup = GD::Image->new($og_width,$og_heigt,1);
	my $white = $recoup->colorAllocate(255,255,255);
	$recoup->fill(0,0,$white);
	$recoup->saveAlpha(1);
	$recoup->alphaBlending(0);
	$recoup->copyResampled($inter,$marge,0,0,0,$inter_width,$inter_height,$inter_width,$inter_height);
	my $data = $recoup->jpeg(100); 
	
	# log_debug('>'.$recoup_path,'','resizeog_for_sheet');
	open (THUMB,">$recoup_path");
	binmode THUMB;  
	print THUMB $data;  
	close THUMB;
	
	$original_path = $path.'/'.$og_file;
	copy($recoup_path,$original_path);
	# log_debug('copy:'."$recoup_path,$original_path",'','resizeog_for_sheet');
	unlink($inter_path);
	unlink($recoup_path);
	# log_debug('unlink et fin:','','resizeog_for_sheet');
	
	return 1;
}