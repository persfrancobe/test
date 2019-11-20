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
use def_handmade;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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

$dm_cfg{wherep} = $dm_cfg{wherel} = " id_page='$id_page' ";
$dm_cfg{table_name} = "parag";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{wherep_ordby} = "";
$dm_cfg{default_ordby} = " ordby ";
$dm_cfg{file_prefixe} = 'PAR';
$dm_cfg{after_add_ref} = \&after_add;
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_upload_ref} = \&after_upload;
$dm_cfg{'list_custom_action_1_func'} = \&custom_preview_ordby;
$dm_cfg{javascript_custom_func_listing} = 'custom_func_list';
my $colg = get_quoted('colg');
$dm_cfg{depends_on_actif_language} = 'y';  
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_$dm_cfg{table_name}.pl?id_page=$id_page&type=".get_quoted('type');
$dm_cfg{col_id} = 'id';
my $custom_html_top = '';
my $url_rewriting = get_url({debug=>0,debug_results=>0,nom_table=>'migcms_pages',id_table=>$id_page, id_language => $colg});	
my $url = "$config{baseurl}/".$url_rewriting;
my %page = sql_line({debug => 0,debug_results=>0,table=>'migcms_pages',where=>"id='$id_page'"});

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
	<div class="checkbox"><label><input type="checkbox" $checked name="group_$migcms_member_group{id}" value="y" class="parag_edit_page" /> $traduit</label></div>
EOH
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
my $meta_description = get_traduction({id=>$page{id_textid_meta_description},id_language=>$colg});

my $type_parag = 'parag';
my $type_page = 'page';
if(get_quoted('type') eq 'mailing')
{
	$type_parag = 'mailing_parag';
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
<a class="btn btn-lg btn-default" href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page=$id_page&edit=y" data-original-title="Editer directement la page sur le site" target="_blank" data-placement="bottom">
	<i class="fa fa-pencil-square-o"></i> 
	</a>
EOH

my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
if($migcms_setup{view_edit_on} ne 'y')
{
	$retouches_rapides = '';
}

#apercu page, edition page wysiwyg
if($type_parag ne 'mailing_parag')
{
	#APERCU + ACCEDER + WYSIWYG
	$dm_cfg{custom_navbar} .= <<"EOH";
	<a class="btn btn-lg  btn-default" href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page=$id_page" data-original-title="Aperçu des modifications" target="_blank" data-placement="bottom">
	<i class="fa fa-eye fa-fw"></i> 
	</a>
	
	<a class="btn btn-lg  btn-default" target="_blank" href="$url" data-original-title="Ouvrir la page sur le site" target="_blank" data-placement="bottom">
	<i class="fa fa-external-link fa-fw"></i> 
	</a>
	
	$retouches_rapides
	
EOH
}
else
{
	#APERCU
	$dm_cfg{custom_navbar} .= <<"EOH";
	<a class="btn btn-lg  btn-default" href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page=$id_page&mailing=y&lg=1" data-original-title="Aperçu de la campagne mailing" target="_blank" data-placement="bottom">
	<i class="fa fa-eye fa-fw"></i>  
	</a>
EOH

	#ENVOYER
	$dm_cfg{custom_navbar} .= <<"EOH";
	<a class="btn btn-lg  btn-primary" href="$dm_cfg{self}&sw=send_newsletter" data-original-title="Envoyer la campagne mailing" data-placement="bottom">
	<i class="fa fa-paper-plane fa-fw"></i>  
	</a>
EOH

	#HISTORIQUE
	$dm_cfg{custom_navbar} .= <<"EOH";
	<a class="btn btn-lg  btn-default" href="$config{baseurl}/cgi-bin/adm_migcms_mailing_sendings.pl?" data-original-title="Historique des envois" data-placement="bottom">
	<i class="fa fa-archive fa-fw"></i>  
	</a>
EOH
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
if(get_quoted('type') eq 'mailing')
{
	$where_type = " type='mailing' ";
}

my $msg = get_quoted('msg');
my $listbox_templates_page = get_sql_listbox({with_blank=>'y',selected_id=>$page{id_tpl_page},col_display=>"name",table=>"templates",where=>"$where_type",ordby=>"id",name=>'id_tpl_page',class=>" parag_edit_page form-control"});
my $listbox_pages = get_sql_listbox({with_blank=>'y',selected_id=>$page{id_father},col_display=>"id_textid_name",table=>"migcms_pages",translate=>1,where=>"id != '$page{id}' AND (migcms_pages_type = 'page' OR  migcms_pages_type = 'link' OR migcms_pages_type = 'directory')",ordby=>"id",name=>'id_father',class=>"parag_edit_page form-control"});
my $txt_url = get_traduction({id=>$page{id_textid_url},id_language=>$colg});

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
my $type_parag_disabled = 'parag';
my $retour = '';
if($type_parag ne 'mailing_parag')
{
	$dm_cfg{before_main_panel_html} = '<div class="col-lg-3 hidden-xs hidden-sm hidden-md hidden-md mig-sitemap hide" style="margin-top:0px!important"><h2 style="font-size:15px;" class="maintitle migctitle hide">Accès rapide aux autres pages:</h2><div class="panel"><div class="panel-body"><table class="tree_container"></table></div></div></div>';
	$dm_cfg{main_panel_class} = "col-lg-12 col-md-12 col-sm-12 col-xs-12 main-panel-content";
	$type_parag_disabled = 'mailing_parag';
	my %script_page = sql_line({table=>'scripts',where=>"url LIKE '%adm_migcms_pages.pl?%'"});
	$retour = $script_page{url}.'&sel='.$script_page{id};
}



$dm_cfg{list_html_top} = <<"EOH";
$custom_html_top
<style>
  .list_ordby,.list_ordby_header,thead.cf,.row_actions_globales,.td-input,.mig_cb_col,td.list_action,.maintitle
	 {
		display:none;
	 }
	 .disable_$type_parag_disabled
	 {
		display:none;
	 }
</style>
	<script type="text/javascript"> 
	jQuery(document).ready(function() 
	{ 
	   custom_func_list();
	    
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
		jQuery(document).on("keyup", ".parag_edit_page", parag_edit_page);
		jQuery(document).on("change", ".parag_edit_page,.tt-input", parag_edit_page);
		jQuery(document).on("click", ".tt-suggestion", parag_edit_page);
		jQuery(document).on("click", ".toggle_url_btn", toggle_url_btn);
		
		  var request = jQuery.ajax(
		  {
			  url: 'adm_migcms_preview_pages.pl?',
			  type: "GET",
			  data: 
			  {
				 sw : 'list_body_ajax',
				 nr : 25,
				 page : 1,
				 sel : 189,
				 sel_page : $sel,
				 id_page : $id_page
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
		
	});
	
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
				jQuery.bootstrapGrowl('<i class="fa fa-info"></i> Template sauvegardé', { type: 'success',align: 'center',
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
			var bouton_container = line.children('.mig_cell_func_1').children('span').children('.row').children('.col-md-4');
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
		jQuery('.parag_edit_page_btn').removeClass('hide').addClass('animated jello');
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
		$liste_langues .= '<label class="btn btn-default parag_edit_page"><input  '.$check.' type="checkbox" name="actif_'.$language{id}.'" value="y"> '.uc($language{name}).'</label> ';
	}

	my $render_page_fr = $render_page_nl = '';
	$render_page_fr = trim(render_page({mailing=>'y',debug=>0,id=>$id_page,lg=>1,preview=>'y',edit=>'n'}));

	my $label_title = 'Titre de la page';
	if($type_parag ne 'mailing_parag')
	{
		$label_title = 'Titre/objet';
	}
	
	$dm_cfg{list_html_top} .= <<"EOH"; 
		
		<a class="btn btn-link disable_parag" role="button" href="$retour">
		  <i class="fa fa-fw fa-arrow-left"></i> Retour
		</a>
		
		<a class="btn btn-default toggle_plansite disable_parag" role="button" >
		 <i class="fa fa-sitemap fa-fw"></i> Plan du site
		</a>
		
		<a href="" class="btn btn-default toggle_tab disable_parag" id="tab_parametres">
		  <i class="fa fa-file-text-o fa-fw"></i> Paramètres de la page</a>
		</a>
		
		<a href=""  class="btn btn-default toggle_tab disable_parag" id="tabo_google">
		  <i class="fa fa-google fa-fw"></i> Référencement Google</a>
		</a>
		
		<a href=""  class="btn btn-default toggle_tab disable_parag" id="tab_secu">
		  <i class="fa fa-lock fa-fw"></i> Sécurité</a>
		</a>
		
		<a href="" class="btn btn-default toggle_tab disable_mailing_parag" id="tab_html">
		  <i class="fa fa-code fa-fw"></i> Code HTML</a>
		</a>
		
		<a href="" class="btn btn-default toggle_tab disable_mailing_parag " id="tab_envoi">
		  <i class="fa fa-fw fa-cogs"></i> Paramètres du mailing</a>
		</a>

		<div class="hide toggle_div toggle_div_tab_parametres" id="tab_parametres">
		  <div class="well">
				<div class="row">
					<label class="col-sm-2 control-label" for="field_id_textid_name"> $label_title </label>
					<div class="col-sm-10 mig_cms_value_col"><input type="text" class="form-control input-block parag_edit_page" name="id_textid_name_page" value="$page_title" /></div>
				</div>

				<div class="row">
					<label class="col-sm-2 control-label" for="field_id_textid_name"> Template</label>
					<div class="col-sm-10 mig_cms_value_col">$listbox_templates_page</div>
				</div>
				
				<div class="row">
					<label class="col-sm-2 control-label" for="field_id_textid_name"> Parent </label>
					<div class="col-sm-10 mig_cms_value_col">$listbox_pages</div>
				</div>	
				<div class="row">
					<label class="col-sm-2 control-label" for=""> Langues </label>
					<div class="col-sm-10 mig_cms_value_col">$liste_langues</div>
				</div>				
				<div class="row">
					<label class="col-sm-2 control-label" for="field_id_textid_name"> Permalien </label>
					<div class="col-sm-10 mig_cms_value_col">
						<div class="toggle_url ">
							<span class="url_preview">$url</span>
							<a href="#" class="toggle_url_btn btn btn-link"><i class="fa fa-edit"></i> Modifier l'url</a>
						</div>
						<div class="toggle_url hide">
							$config{baseurl}/fr/<input type="text" class="edit_url parag_edit_page" name="edit_url" value="$txt_url" />
						</div>
					</div>
				</div>
		  </div>
		</div>	
		
		<div class="hide toggle_div toggle_div_tabo_google" id="tabo_google">
		  <div class="well">
				<div class="row">
					<label class="col-sm-2 control-label" for="field_id_textid_name"> Titre META </label>
					<div class="col-sm-10 mig_cms_value_col"><input type="text" class="form-control input-block parag_edit_page" name="id_textid_meta_title_page" id="id_textid_meta_title_page" value="$meta_title" /></div>
				</div>
				<div class="row">
					<label class="col-sm-2 control-label" for="field_id_textid_name"> Description META </label>
					<div class="col-sm-10 mig_cms_value_col"><textarea class="form-control parag_edit_page" name="id_textid_meta_description_page" id="id_textid_meta_description_page">$meta_description</textarea></div>
				</div>
				<hr class="hidden-sm hidden-xs" />
				<h1 class="seo-simulator-label hidden-sm hidden-xs">Simulation dans la recherche de Google : </h1>
				<div class="seo-simulator hidden-sm hidden-xs">
					<h2>$meta_title</h2>
					<div class="seo-simulator-url">$config{rewrite_host}$url</div>
					<div class="seo-simulator-text">$meta_description</div>
				</div>
		  </div>
		</div>
		
		<div class="hide toggle_div toggle_div_tab_secu" id="tab_secu">
		  <div class="well">
			<div class="alert alert-info"><i class="fa fa-info-circle"></i> Vous pouvez restreindre l'accès à cette page en cochant un ou plusieurs groupe(s) de membres.</div>
				<div class="row">
					 <label class="col-sm-2 control-label" for="field_id_textid_name"> Groupes de membres </label>
				<div class="col-sm-10 mig_cms_value_col">$member_groups </div>
			</div>
		  </div>
		</div>
		
		<div class="hide toggle_div toggle_div_tab_html" id="tab_html">
		  <div class="well">
			<textarea class="form-control" style="height:500px!important;">$render_page_fr</textarea>			
		  </div>
		</div>
		
		<div class="hide toggle_diva toggle_div_tab_envoi" id="tab_envoi">
		  <div class="well">
		
				<div class="row">
					<label class="col-sm-2 control-label" for="field_id_textid_name"> Nom de l'expéditeur</label>
					<div class="col-sm-10 mig_cms_value_col"><input type="text" class="form-control input-block parag_edit_page" name="sender_name" value="$sender_name" /></div>
				</div>	
				<div class="row">
					<label class="col-sm-2 control-label" for="field_id_textid_name"> Email de l'expéditeur </label>
					<div class="col-sm-10 mig_cms_value_col"><input type="text" class="form-control input-block parag_edit_page" name="sender_email" value="$sender_email" /></div>
				</div>
				
				<div class="row">
					<label class="col-sm-2 control-label" for="field_id_textid_name">Segment </label>
					<div class="col-sm-10 mig_cms_value_col">
					
										
									<div class="input-group"> 
										<span class="input-group-addon "><i class="fa-fw fa fa-tags "></i></span>
										<input type="text"  placeholder="ex: Belgique, Francophone..." id="list_tags" name="list_tags" class="form-control  search_element" />
										<input type="hidden" placeholder="" id="list_tags_vals" name="list_tags_vals" />
									</div>
								<script>
								jQuery(document).ready(function() 
								{
									
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
									});
									elt.on('itemRemoved', function(event) 
									{
										var list_tags_vals = jQuery("#list_tags").val();
										jQuery("#list_tags_vals").val(list_tags_vals);
									});
								});
								</script>

					</div>
				</div>
		 </div>
		</div>
EOH


my $type = get_quoted('type');


#FORMULAIRE EDITION ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%dm_dfl = (
	'01/id_template' => 
	{
		'title'=>$migctrad{parag_id_template},
		'mandatory'=>{"type" => 'not_empty' },
		'fieldtype'=>'listboxtable',
		'lbtable'=>'templates',
		'lbkey'=>'id',
		'lbdisplay'=>"name",
		'tab'=>1,
		'lbwhere'=>"type = '$type_parag'" ,
	}     
	,
	'11/id_textid_title' => 
	{
		'title'=>$migctrad{parag_id_textid_title},
		'tab'=>1,
		'fieldtype'=>'text_id',
	}
	,
	'21/id_textid_parag' => 
	{
		'title'=>$migctrad{parag_id_textid_parag},
		'tab'=>1,
		'fieldtype'=>'textarea_id_editor',
	}  
	,
	'25/nom_zone_template'	=>{'title'=>$migctrad{parag_nom_zone_template},'fieldtype'=>'listbox','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>'1','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','fieldvalues'=>\%noms_zones_template,'hidden'=>$hidden_zone_template},
	,
	'63/fichiers'=> 
	{
		'title'=>$migctrad{parag_fichiers},
		'tab'=>2,
		'fieldtype'=>'files_admin',
		'disable_add'=>1,
		'msg'=>$migctrad{parag_fichiers_msg},
	}
	,
	'64/do_not_resize'=> 
	{
		'title'=>$migctrad{parag_do_not_resize},
		'tab'=>2,
		'default_value'=>'n',
		'fieldtype'=>'checkbox',
		'disable_add'=>1,
	}
	,
	'99/id_page' => 
	{
		'title'=>$migctrad{parag_id_page},
		'tab'=>2,
		'fieldtype'=>'text',
		'data_type'=>"hidden"
	}
	);
	
	my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible = 'y' || encode_ok = 'y'"});
    my $hidden_lg_parag = 0;
	if($type_parag eq 'mailing_parag')
	{
		$hidden_lg_parag = 1;
	}
	
	my $count = 71;
	foreach $language (@languages)
    {
        my %language = %{$language};
		
		
		$dm_dfl{$count.'/actif_'.$language{id}} =
		{
			'title'=>$migctrad{parag_actif_in}.' '.uc($language{name}),
			'tab'=>2,	
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
  
  my ($title,$dum) = get_textcontent($dbh,$parag{id_textid_title});
  my ($parag,$dum) = get_textcontent($dbh,$parag{id_textid_parag});
  my $photos = '';
  my @migcms_linked_files = sql_lines({table=>'migcms_linked_files',where=>"table_name='parag' AND token='$id'",ordby=>'ordby'});
  foreach $migcms_linked_file (@migcms_linked_files)
  {
		my %migcms_linked_file = %{$migcms_linked_file};
		if($migcms_linked_file{do_not_resize} eq 'y')
		{
			my $url_pic_preview = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
			$photos .= "<img src='$url_pic_preview' />";
		}
		else
		{
			my $url_pic_preview = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{name_medium};
			$photos .= "<img src='$url_pic_preview' />";
		}
  }
  
  if($parag{nom_zone_template} eq '')
  {
		$parag{nom_zone_template} = $migctrad{parag_zone_principale};
  }
  $zone = '<a class="btn btn-block disabled btn-default" style="">'.ucfirst(lc($parag{nom_zone_template})).'</a>';
  $zone =~ s/_/ /g;
  
	my @templates = sql_lines({table=>'templates',where=>"type = '$type_parag'",ordby=>"name"});
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

  
my $rendu = <<"EOH";
	<div class="row">
		<div class="col-md-4">
		...
		</div>
		<div class="col-md-2">
			$zone
		</div>
		<div class="col-md-6">
			<select name="" class="form-control save_template pull-right" id="$id" rel="">$list_templates</select>
		</div>
		
		
	</div>

	<div class="mig_cms_value_col">
		<br /><h2 class="mig-parag-title">$title</h2>
		$parag
		$photos
	</div>
	
EOH
  return $rendu;
}


sub parag_page_db
{
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
	my $colg = get_quoted('colg');
	if($colg eq '')
	{
		$colg = 1;
	}

	#NAME PAGE
	my $id_textid_name_page = get_quoted('id_textid_name_page');
	$stmt = "UPDATE txtcontents SET lg$colg='$id_textid_name_page' where id=$page{id_textid_name}";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt);   
	
	#META TITLE
	my $id_textid_meta_title_page = get_quoted('id_textid_meta_title_page');
	if($id_textid_meta_title_page eq '')
	{
		$id_textid_meta_title_page = $id_textid_name_page;
	}
	$stmt = "UPDATE txtcontents SET lg$colg='$id_textid_meta_title_page' where id=$page{id_textid_meta_title}";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt); 
	
	#META DESCRIPTION
	my $id_textid_meta_description_page = get_quoted('id_textid_meta_description_page');
	$stmt = "UPDATE txtcontents SET lg$colg='$id_textid_meta_description_page' where id=$page{id_textid_meta_description}";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt); 
	
	#URL
	my $edit_url = get_quoted('edit_url');
	$stmt = "UPDATE txtcontents SET lg$colg='$edit_url' where id=$page{id_textid_url}";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt);
	
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
	
	
	migcms_build_compute_urls();
	
	cgi_redirect("$dm_cfg{self}&id_page=$id_page&sel=$sel".'&msg=verrou_ok&colg='.$colg.'&type='.$type);
	exit;
}


sub after_add
{
	my $dbh=$_[0];
	my $id=$_[1];
	
	my $liste_langues = '';
	my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>""});
    foreach $language (@languages)
    {
        my %language = %{$language};
		$liste_langues .= " actif_$language{id} = 'y', ";
	}
	$liste_langues .= " visible='n' ";
	
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
		my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
		my %params = (
			migcms_linked_file=>\%migcms_linked_file,
			do_not_resize=>$parag{do_not_resize}
		);
		foreach my $size (@sizes)
		{
			$params{'size_'.$size} = $template{'size_'.$size};
		}
		dm::resize_pic(\%params);
	}	
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
<a class="btn btn-lnk disabled" disabled>$parag{ordby}</a>
EOH
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------