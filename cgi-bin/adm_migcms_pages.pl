#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use migcrender;
use dm;
my $colg = get_quoted('colg')  || $config{current_language} || 1;
$dm_cfg{trad} = 1;
$dm_cfg{tree} = 1;
$dm_cfg{enable_search} = 0;
$dm_cfg{force_excel} = 0;
$dm_cfg{corbeille} = 0;
$dm_cfg{restauration} = 0;
$dm_cfg{visibility} = 1;
$dm_cfg{sort} = 1;
$dm_cfg{modification} = 1;
$dm_cfg{delete} = 1;
$dm_cfg{wherep} = $dm_cfg{wherel}  = "(migcms_pages_type = 'page' OR  migcms_pages_type = 'link' OR migcms_pages_type = 'directory')";
$dm_cfg{use_migcms_cache} = 0;

$dm_cfg{table_name} = "migcms_pages";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{javascript_custom_func_form} = 'after_load';
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_pages.pl?";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{before_del_func} = \&before_del_page;
$dm_cfg{list_debug} = 0;
$dm_cfg{duplicate} = 1;
$dm_cfg{custom_duplicate_func} = \&duplicate_page;

$dm_cfg{page_title} = $migctrad{website_management};
$dm_cfg{add_title} = "Ajouter";
$dm_cfg{file_prefixe} = 'pages';

$dm_cfg{line_func} = 'custom_tree_levels';  
$dm_cfg{depends_on_actif_language} = 'n';  

my %migcms_language = read_table($dbh,'migcms_languages',$config{current_language});

$dm_cfg{custom_navbar} = <<"EOH";
<a data-original-title="$migctrad{exp_data}" 
data-placement="bottom" class="btn btn-default btn-lg 
 search_element"
 href = "$config{baseurl}/cgi-bin/adm_migcms_exports_trads.pl?" 
 >
<i class="fa  fa-file-excel-o"></i> 
</a>
EOH

# ONGLETS ------------------------------------
@dm_nav =
(
	{
		'type'=>'tab',
		'tab'=>'page',
		'title'=>'Page'
	}
	,
	{
		'type'=>'tab',
		'tab'=>'parent',
		'title'=>'Parent'
	}
);

$dm_cfg{'list_custom_action_1_func'} = \&custom_page_edit;
$dm_cfg{'list_custom_action_2_func'} = \&custom_page_add;
$dm_cfg{'list_custom_action_3_func'} = \&custom_page_preview;
$dm_cfg{'list_custom_action_4_func'} = \&custom_page_link;

$dm_cfg{javascript_custom_func_listing} = 'custom_func_list';

$dm_cfg{list_html_top} .= <<'EOH';
	<style>
		.list_ordby,.list_ordby_header,.dm_migedit 
		{
			display:none!important;
		}
		
		@media only screen and (max-width: 800px) {
			/*.cell-value .badge, .list_action { display : none !important;}*/
		}
	</style>
EOH
$dm_cfg{list_html_top} .= <<"EOH";
    <input type="hidden" id="id_father" class="set_data" name="id_father" value="" />
    <script type="text/javascript"> 
    
    jQuery(document).ready(function() 
    { 
		refresh_pages_types();
		custom_func_list();
		jQuery(document).on("change", "#field_migcms_pages_type",refresh_pages_types);
		jQuery(document).on("change", "#field_type_lien",refresh_type_lien);
		jQuery(document).on("click", ".addlink",addlink);    
		jQuery(document).on("click", ".complete_link_with_language",complete_link_with_language);    
		
		
	});
	
	function complete_link_with_language()
	{
		var me = jQuery(this);
		var colg = jQuery('.colg').val();
		me.attr('href',me.attr('href')+'&colg='+colg);
	}
	
	function custom_func_list()
	{
		jQuery('.list_actions_9').removeClass('list_actions_9').addClass('list_actions_8');
		jQuery('.parametre_url_sw').val('list_body_ajax');
	}
	
	function addlink()
	{
	    jQuery('.row_edit_new_migcms_link_name,.row_edit_new_migcms_link_url').show();
		return false;
	}
	
    function refresh_pages_types()
    {
            var type = jQuery("#field_migcms_pages_type").val();
            jQuery('.row_edit_id_tpl_page, .row_edit_id_father, .row_edit_id_migcms_link, .row_edit_new_migcms_link_name, .row_edit_new_migcms_link_url').show();
            jQuery('.row_edit_id_migcms_link_modules,.row_edit_id_migcms_link_page,.row_edit_new_migcms_link_name,.row_edit_new_migcms_link_url').hide();
            if(type == 'directory')
            {
                jQuery('.row_edit_blanktarget,.row_edit_type_lien,.row_edit_id_migcms_link_modules,.row_edit_id_migcms_link_page,.id_migcms_link_page,.row_edit_id_tpl_page, .row_edit_id_migcms_link, .row_edit_new_migcms_link_name, .row_edit_new_migcms_link_url').hide();
            }
            if(type == 'link')
            {
				jQuery('.row_edit_id_tpl_page').hide();
                jQuery('.row_edit_blanktarget,.row_edit_type_lien,.row_edit_id_migcms_link_modules,.row_edit_id_migcms_link_page').show();
				jQuery('.row_edit_id_migcms_link,.row_edit_id_migcms_link_modules,.row_edit_id_migcms_link_page,.row_edit_new_migcms_link_name,.row_edit_new_migcms_link_url,.row_edit_simple_url').hide();				
              	refresh_type_lien();
            }
            if(type == 'page')
            {
                jQuery('.row_edit_blanktarget,.row_edit_type_lien,.row_edit_id_migcms_link_modules,.row_edit_id_migcms_link_page,.row_edit_id_migcms_link, .row_edit_new_migcms_link_name, .row_edit_new_migcms_link_url').hide();
            }
    }
	
	function refresh_type_lien()
    {
			var type_lien = jQuery("#field_type_lien").val();
			jQuery('.row_edit_id_migcms_link,.row_edit_id_migcms_link_modules,.row_edit_id_migcms_link_page,.row_edit_new_migcms_link_name,.row_edit_new_migcms_link_url,.row_edit_simple_url').hide();
            if(type_lien == 'link_module')
            {
				jQuery('.row_edit_id_migcms_link_modules').show();
            }
            if(type_lien == 'link')
            {
                jQuery('.row_edit_id_migcms_link').show();
            }
            if(type_lien == 'link_page')
            {
				jQuery('.row_edit_id_migcms_link_page').show();
            }
			if(type_lien == 'simple_url')
            {
				jQuery('.row_edit_simple_url').show();
            }
    }
    
    function after_load()
    {
       // jQuery('.btn_change_listbox.btn-info').click();
	   refresh_type_lien();
    }
    </script>
EOH


if($config{current_language} eq "")
{
   $config{current_language}=get_quoted('lg') || 1;
}



$dm_cfg{hiddp}=<<"EOH";

EOH


%types = (
			"01/page"=>$migctrad{tpltype_page},
			"02/link"=>$migctrad{link},
			"03/directory"=>$migctrad{tpltype_menu},
		);
		
%list_types_lien = (
			"01/simple_url"=>$migctrad{link_type_url},
			"02/link"=>"Lien traductible",
			"03/link_page"=>"Lien vers une page",
			"04/link_module"=>"Lien vers un module",
		);		
    
 my $cpt = 50;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    
      '01/migcms_pages_type'=> 
      {
          'title'=>"Type",
          'fieldtype'=>'listbox',
          'data_type'=>'btn-group',
          'fieldvalues'=>\%types,
          'tab'    => 'page',
          'default_value'=>'page',
		  'hide_update'=>1,
      }
	  ,
	  '02/type_lien'=> 
      {
          'title'=>"Type de lien",
          'fieldtype'=>'listbox',
          'data_type'=>'btn-group',
          'fieldvalues'=>\%list_types_lien,
          'tab'    => 'page',
          'default_value'=>'simple_url',
		  'hide_update'=>0,
      }
      ,
       '03/id_textid_name'=> 
      {
	        'title'=>'Titre',
	        'fieldtype'=>'text_id',
	        'search' => 'y',
			'tab'    => 'page'
	    }
      ,
	    '05/id_tpl_page' => 
      {
           'title'=>'Template',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'templates',
		   'legend'=>"Mises en page préconcues pour habiller le contenu",
           'lbkey'=>'id',
           'lbdisplay'=>'name',
           'lbwhere'=>"type = 'page'" ,
          'tab'    => 'page'
      }
      ,
	    '99/id_father' => 
      {
           'title'=>'Parent',
           'fieldtype'=>'listboxtable',
		    'data_type'=>'treeview',
           'lbtable'=>'migcms_pages',
           'lbkey'=>'id',
		   'legend'=>"",
           'lbdisplay'=>'id_textid_name',
           'lbwhere'=>'migcms_pages_type!="newsletter" AND migcms_pages_type!="block" AND migcms_pages_type!="handmade"',
		   
          	'tab'    => 'parent',
          	'translate' => 1,
		   'multiple'=>0,
		   'summary'=>0,
		   		'tree_col'=>'id_father',

      }
	   ,
      '09/id_migcms_link_modules' => 
      {
           'title'=>'Liens vers un module',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'migcms_links',
           'lbkey'=>'id',
           'lbdisplay'=>'id_textid_link_name',
           'lbwhere'=>"link_type='module'",
           'tab'    => 'page',
           'translate' => 1,
      }
	  ,
      '10/id_migcms_link_page' => 
      {
           'title'=>'Lien vers une page du site',
           'fieldtype'=>'listboxtable',
		    'data_type'=>'treeview',
           'lbwhere'=>'migcms_pages_type!="newsletter" AND migcms_pages_type != "block" AND migcms_pages_type != "handmade"',			
           'lbtable'=>'migcms_pages',
           'lbkey'=>'id',
		   'legend'=>"",
           'lbdisplay'=>'id_textid_name',
           'tab'    => 'page',
          	'translate' => 1,
		   'multiple'=>0,
		   'summary'=>0,
		   	'tree_col'=>'id_father',
      }
      ,
      '11/id_migcms_link' => 
      {
           'title'=>'Mes liens',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'migcms_links',
           'lbkey'=>'id',
           'lbdisplay'=>'id_textid_link_name',
           'lbwhere'=>"link_type=''",
		   	'legend'=>'<a href="#" class="btn btn-link addlink">Ajouter un nouveau lien</a>',
           'tab'    => 'page',
           'translate' => 1,
      }
      # ,
      # '10/new_migcms_link_name'=> 
      # {
	        # 'title'=>'<i class="fa fa-plus"></i> Nom du lien',
	        # 'fieldtype'=>'text',
	        # 'search' => 'y',
          # 'tab'    => 'page'
	    # }
       ,
      '12/new_migcms_link_url'=> 
      {
	        'title'=>'<i class="fa fa-plus"></i> Nouveau lien',
	        'fieldtype'=>'text_id',
			'legend'=>'',
	        'search' => 'y',
          'tab'    => 'page'
	    }
		  ,
      '13/simple_url'=> 
      {
	        'title'=>'URL simple non traductible',
	        'fieldtype'=>'text',
			'legend'=>'',
	        'search' => 'y',
          'tab'    => 'page'
	    }
		,
      '14/blanktarget'=> 
      {
	        'title'=>'Ouvrir dans une nouvelle page ?',
	        'fieldtype'=>'checkbox',
			'legend'=>'',
	        'search' => 'n',
          'tab'    => 'page'
	    },
		
		#champs cachés encodés pour que la duplication fonctionne
		sprintf("%05d", $cpt++).'/id_fathers'=>{'tab'=>'page','title'=>'id_fathers','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/mailing_id_campaign'=>{'tab'=>'page','title'=>'mailing_id_campaign','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/mailing_from'=>{'tab'=>'page','title'=>'mailing_from','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/mailing_from_email'=>{'tab'=>'page','title'=>'mailing_from_email','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/mailing_name'=>{'tab'=>'page','title'=>'mailing_name','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/mailing_object'=>{'tab'=>'page','title'=>'mailing_object','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/mailing_alt_html'=>{'tab'=>'page','title'=>'mailing_alt_html','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/mailing_include_pics'=>{'tab'=>'page','title'=>'mailing_include_pics','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/mailing_headers'=>{'tab'=>'page','title'=>'mailing_headers','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/mailing_basehref'=>{'tab'=>'page','title'=>'mailing_basehref','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/mailing_googleanalytics'=>{'tab'=>'page','title'=>'mailing_googleanalytics','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/mailing_status'=>{'tab'=>'page','title'=>'mailing_status','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/tracking_url'=>{'tab'=>'page','title'=>'tracking_url','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		
		sprintf("%05d", $cpt++).'/id_textid_meta_title'=>{'tab'=>'page','title'=>'id_textid_meta_title','translate'=>0,'fieldtype'=>'text_id','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/id_textid_meta_keywords'=>{'tab'=>'page','title'=>'id_textid_meta_keywords','translate'=>0,'fieldtype'=>'text_id','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/id_textid_meta_description'=>{'tab'=>'page','title'=>'id_textid_meta_description','translate'=>0,'fieldtype'=>'text_id','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/id_textid_url'=>{'tab'=>'page','title'=>'id_textid_url','translate'=>0,'fieldtype'=>'text_id','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/id_textid_url_words'=>{'tab'=>'page','title'=>'id_textid_url_words','translate'=>0,'fieldtype'=>'text_id','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		sprintf("%05d", $cpt++).'/id_textid_meta_url'=>{'tab'=>'page','title'=>'id_textid_meta_url','translate'=>0,'fieldtype'=>'text_id','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>'','hidden'=>1},
		
		
		
	);

%dm_display_fields =  
      (
	      
      );  
	  
%dm_lnk_fields = (
"40//page_preview"=>"page_preview*",
		);
                                                         
%dm_mapping_list = (
"page_preview"=>\&page_preview,
);

%dm_filters = (
      
		);


# this script's name

$sw = $cgi->param('sw') || "list";

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
			before_del_page 
		);

if (is_in(@fcts,$sw)) 
{ 
    see();
    dm_init();
    &$sw();
	
    if ($sw eq "list") {$spec_bar.=$lnkxls;}
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title});}

	
sub page_preview
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %d = %{$_[3]};

  my $lg = get_quoted('lg');
  
  my $preview ='';
  my %page = sql_line({debug_results=>0,table=>'migcms_pages',where=>"id='$id'"});
  my $type = '';
  my $link = '';
  my $phrase = '';
  my $elt_name  = get_traduction({debug=>0,id_language=>$lg,id=>$page{id_textid_name}});
  my $class = '';
  my $elt = '';
  
  my $actif_lg =  $page{'actif_'.$config{current_language}};
  
  if($page{migcms_pages_type} eq 'directory')
  {
      $link = $page{id};
      $phrase = "";
      
      my %count = select_table($dbh,"migcms_pages","count(id) as total","id_father = '$page{id}'");
      $elt = <<"EOH";
<span class="badge" data-placement="top" data-original-title="Ordre">$page{ordby}</span>
<i class="fa fa-folder-open-o" data-placement="top" data-original-title="Dossier"></i>
$elt_name
EOH
  }
  elsif($page{migcms_pages_type} eq 'link')
  {
      $elt = <<"EOH";
<span class="badge" data-placement="top" data-original-title="Ordre">$page{ordby}</span>
<i class="fa fa-link" data-placement="top" data-original-title="Lien"></i>
$elt_name
EOH
  }
  elsif($page{migcms_pages_type} eq 'page')
  {
      $class= ' text-info ';
	  my $sel = get_quoted('sel'); 
	  
	  my $lock = '';
	  my %migcms_lnk_page_group = sql_line({table=>'migcms_lnk_page_groups',where=>"is_linked='y' AND id_migcms_page='$page{id}' "});
	  if($migcms_lnk_page_group{id} > 0)
	  {
		$lock ='<span class="label label-warning" data-placement="top" data-original-title="Page sécurisée : authentification requise (email / mot de passe) pour consulter cette page"><i class="fa fa-lock"></i></span>';
	  }
	  
	  if($actif_lg eq 'n')
	  {
		$elt_name = $elt_name.' <span class="label label-info">Désactivé pour le '.$migcms_language{display_name}.'</span>';
	  }
	  
	  $elt = <<"EOH";
<span class="badge" data-placement="top" data-original-title="Ordre">$page{ordby}</span>
<i class="fa fa-file-text-o" data-fathers="$page{id_fathers}" data-placement="top" data-original-title="Page"></i>
$lock
$elt_name  
EOH
  }
  
  my $preview = <<"EOH";
     $elt 
EOH
  
  return $preview;
}


sub migcms_pages_fill_gaps
{
    my @migcms_pages = sql_lines({debug=>0,debug_results=>0,table=>"migcms_pages",where=>""});
    foreach $migcms_page (@migcms_pages)
	{
		my %migcms_page = %{$migcms_page};

		#si token vide
		if($migcms_page{token} eq '')
		{
			my $new_token = create_token(45);
			my $stmt = <<"EOH";
				UPDATE migcms_pages SET token = '$new_token' WHERE id = '$migcms_page{id}'
EOH
			execstmt($dbh,$stmt);
		}
		
		#Recopie nom dans "texte pour txt url" si url vide
		my ($texte_nom,$dum) = get_textcontent ($dbh,$migcms_page{id_textid_name});
		my ($texte_url,$dum) = get_textcontent ($dbh,$migcms_page{id_textid_url});
		
		if($texte_url eq '' && $texte_nom ne '')
		{
			$texte_nom =~ s/\'/\\\'/g;
			update_text($dbh,$migcms_page{id_textid_url},$texte_nom,$colg);
		}
		
		#complète la date de création si manquant
		if($migcms_page{migcms_moment_create} eq '0000-00-00 00:00:00')
		{
				my $stmt = <<"EOH";
				UPDATE migcms_pages SET migcms_moment_create = NOW() WHERE id = '$migcms_page{id}'
EOH
			execstmt($dbh,$stmt);
		}
		
		#toutes les langues = n -> toutes les langues à y 
		if($migcms_page{actif_1} eq 'n' && $migcms_page{actif_2} eq 'n' && $migcms_page{actif_3} eq 'n'  && $migcms_page{actif_4} eq 'n'  && $migcms_page{actif_5} eq 'n'  && $migcms_page{actif_6} eq 'n'  && $migcms_page{actif_7} eq 'n'  && $migcms_page{actif_8} eq 'n'  && $migcms_page{actif_9} eq 'n'  && $migcms_page{actif_10} eq 'n'  )
		{
				my $stmt = <<"EOH";
				UPDATE migcms_pages SET actif_1 = 'y',actif_2 = 'y',actif_3 = 'y',actif_4 = 'y',actif_5 = 'y',actif_6 = 'y',actif_7 = 'y',actif_8 = 'y',actif_9 = 'y',actif_10 = 'y' WHERE id = '$migcms_page{id}'
EOH
				execstmt($dbh,$stmt);
		}
	}
}

sub after_save
{
    my $dbh=$_[0];
    my $id =$_[1];
    my %page = sql_line({debug_results=>0,dbh=>$dbh,table=>"migcms_pages",where=>"id='$id'"});
    
	migcms_pages_fill_gaps();
	
	my @languages = sql_lines({table=>'migcms_languages',where=>"visible='y'"});
	foreach $l (@languages)
	{
		my %l = %{$l};
		
		my ($texte_url,$dum) = get_textcontent ($dbh,$page{id_textid_url},$l{id});
		
		if($texte_url eq '')
		{
			$texte_url = $id;
		}
	
		my $url_rewriting = $l{name}.'/'.clean_url($texte_url,'y');
		$url_rewriting  =~ s/\'/\\\'/g;	
		
		#boucle pour éviter doublons
		my %check_url = sql_line({table=>'migcms_urls',where=>"url_rewriting='$url_rewriting' AND id_table != '$id'"});
		my $suffix = 2;
		while($check_url{id} > 0)
		{
			$url_rewriting = $l{name}.'/'.clean_url($texte_url,'y').$suffix;
			$url_rewriting  =~ s/\'/\\\'/g;	
			
			%check_url = sql_line({table=>'migcms_urls',where=>"url_rewriting='$url_rewriting' AND id_table != '$id'"});
			$suffix++;
		}
			
		my %migcms_url = (
        'nom_table' => 'migcms_pages',
        'id_table' => $id,
        'id_lg' => $l{id},
        'words' => $texte_url,
        'url_rewriting' => $url_rewriting,
        );
        sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_urls',data=>\%migcms_url, where=>"nom_table='$migcms_url{nom_table}' AND id_table='$migcms_url{id_table}'  AND id_lg='$migcms_url{id_lg}'"});               
	}
	
	#création du nouveau lien
	my ($url,$dum) = get_textcontent($dbh,$page{new_migcms_link_url});
	
    if(trim($url) ne '' )
    {
        my $nom_nouveau_lien  = get_traduction({debug=>0,id_language=>$colg,id=>$page{id_textid_name}});
		my $url_nouveau_lien  = get_traduction({debug=>0,id_language=>$colg,id=>$page{new_migcms_link_url}});

		$nom_nouveau_lien =~ s/\'/\\\'/g;
		$url_nouveau_lien =~ s/\'/\\\'/g;

		my $id_textid_link_name = insert_text($dbh,$nom_nouveau_lien,$colg);
		my $id_textid_link_url = insert_text($dbh,$url_nouveau_lien,$colg);
		
        my %new_link = (
        'id_textid_link_name' => $id_textid_link_name,
        'id_textid_link_url' => $id_textid_link_url,
        'visible' => 'y'
        );
		
        my $id_link = inserth_db($dbh,'migcms_links',\%new_link);
        
        my $stmt = "UPDATE migcms_pages SET id_migcms_link = $id_link, new_migcms_link_name='', new_migcms_link_url=0  WHERE id='$id'";
        execstmt($dbh,$stmt);
    }
	
	#sauvegarder les parents (multisite)
	save_all_fathers(0);
}

sub save_all_fathers
{
	my $id_father = $_[0];
	my @scripts = sql_lines({table=>'migcms_pages',where=>"id_father='$id_father'",ordby=>'ordby'});
	foreach $script (@scripts)
    {
			my %script = %{$script};
			save_fathers($script{id});
			save_all_fathers($script{id});
	}
}

sub save_fathers
{
	my $id = $_[0];
	
	my %script = sql_line({debug_results=>0,dbh=>$dbh,table=>"migcms_pages",where=>"id='$id'"});
	my $id_fathers = '';
	if($script{id_father} > 0)
	{
		#trouver pere
		my %father = sql_line({debug_results=>0,dbh=>$dbh,table=>"migcms_pages",where=>"id_father='$script{id_father}'"});
		my $id_father = $father{id};
		while ($id_father > 0)
		{
			# if($id_fathers ne '')
			# {
				# $id_fathers .= ',';
			# }
			#ajouter pere
			$id_fathers .= ','.$id_father.',';
			
			#trouver pere du pere
			my %father = sql_line({debug_results=>0,dbh=>$dbh,table=>"migcms_pages",where=>"id='$id_father'"});
			$id_father = $father{id_father};
		}
	}
	
	$stmt = "UPDATE migcms_pages SET id_fathers ='$id_fathers' WHERE id = '$script{id}' ";
    execstmt($dbh,$stmt);
}

sub before_del_page
{
	my $id = $_[1];
	
	my @paragraphes_lies = sql_lines({debug=>0,debug_results=>0,table=>'parag',where=>"id_page='$id'"});
	foreach $paragraphes_lie (@paragraphes_lies)
	{
		my %paragraphes_lie = %{$paragraphes_lie};
		
		dm::clean_linked_files('parag',$paragraphes_lie{id});
		
		#supprime les paragraphes liés aux pages
		$stmt = "delete FROM parag WHERE id = '$paragraphes_lie{id}' ";
		execstmt($dbh,$stmt);
	}
}

sub duplicate_page
{
	my $id_page = $_[1];
		
	my %migcms_page = read_table($dbh,'migcms_pages',$id_page);
	my $title = get_traduction({id=>$migcms_page{id_textid_name},id_language=>$colg});
	
	my $duplicated_id_migcms_page = duplicate_simple_record($dbh,$id_page);
	
	#changer la page dupliquée pour la rendre invisible
	$stmt = "UPDATE migcms_pages SET visible = 'n' WHERE id = '$duplicated_id_migcms_page'";
	execstmt($dbh,$stmt);

	%dm_dfl_parags = (
	'01/id_template' => 
	{
		'title'=>'Template de contenu',
		'mandatory'=>{"type" => 'not_empty' },
		'fieldtype'=>'listboxtable',
		# 'legend'=>"Correspond à la mise en forme graphique de ce paragraphe",
		'lbtable'=>'templates',
		'lbkey'=>'id',
		'lbdisplay'=>"name",
		'tab'=>1,
		'lbwhere'=>"type = '$type_parag'" ,
	}   
	
	,
	'11/id_textid_title' => 
	{
		'title'=>'Titre',
		'tab'=>1,
		'fieldtype'=>'text_id',
	}
	,
	'21/id_textid_parag' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'textarea_id_editor',
	}  
	,
	'22/id_textid_text_1' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	} 
	,
	'23/id_textid_text_2' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	} 
	,
	'24/id_textid_text_3' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	} 
	,
	'25/id_textid_text_4' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	} 
	,
	'32/id_textid_textwysiwyg_1' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	} 
	,
	'33/id_textid_textwysiwyg_2' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	} 
	,
	'34/id_textid_textwysiwyg_3' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	} 
	,
	'35/id_textid_textwysiwyg_4' => 
	{
		'title'=>'Contenu',
		'tab'=>1,
		'fieldtype'=>'text_id',
	}
	,
	'84/do_not_resize'=> 
	{
		'title'=>"Ne pas redimensionner les photos",
		'tab'=>2,
		'default_value'=>'n',
		'fieldtype'=>'checkbox',
		'disable_add'=>1,
	}
	,
	'83/fichiers'=> 
	{
		'title'=>"Photos",
		'tab'=>2,
		'fieldtype'=>'files_admin',
		'disable_add'=>1,
	}
	,
	'99/id_page' => 
	{
		'title'=>'Page',
		'tab'=>2,
		'fieldtype'=>'text',
		'data_type'=>"hidden"
	}
	);
	
	#dupliquer les paragraphes de la page
	my @parags = sql_lines({table=>'parag',where=>"id_page ='$id_page'",ordby=>"ordby,id"});
	foreach $parag (@parags)
	{
		my %parag = %{$parag};
		# my $duplicated_id_parag = duplicate_simple_record($dbh,$parag{id},'reverse_ordby','parag',0,\%dm_dfl_parags,'PAR');
		my $duplicated_id_parag = duplicate_simple_record($dbh,$parag{id},'','parag',0,\%dm_dfl_parags,'PAR');
	
		#lier les paragraphes dupliques à la page dupliquee
		$stmt = "UPDATE parag SET id_page = '$duplicated_id_migcms_page' WHERE id = '$duplicated_id_parag'";
		execstmt($dbh,$stmt);
	}	
	
	dm_cms::migcms_build_compute_urls();

	exit;
}

sub custom_page_add
{
	my $id = $_[0];
	my $colg = $_[1];
	my %page = %{$_[2]};
	my $sel = get_quoted('sel'); #sel item menu
	my %d = ();
	$d{$colg} = $colg;
		
	return <<"EOH";

	<a href="$dm_cfg{self}&sw=add_form&id_father=,$id," data-original-title="$migctrad{add_element}" data-placement="bottom" class="btn btn-info">
	<i class="fa fa-plus fa-fw" data-original-title="" title=""></i> 
	</a>
EOH
}

sub custom_page_edit
{
	my $id = $_[0];
	my $colg = $_[1];
	my %page = %{$_[2]};
	my $sel = get_quoted('sel'); #sel item menu
	my %d = ();
	$d{$colg} = $colg;
	
   if($page{migcms_pages_type} eq 'page')
   {
	  #Modifier pages + paragraphes*******************************
	  $type_permission = 'edit';
	  my $class = 'btn-info complete_link_with_language';
	  $link = '../cgi-bin/adm_migcms_parag.pl?id_page='.$page{id}.'&sel='.$sel;
	  $phrase = "$migctrad{edit} (Ref#$id)";
	  $edit_paragraphes = <<"EOH";
		<a href="$link" data-placement="bottom" data-original-title="$phrase" class="btn $class "> 
		<i class="fa fa-pencil fa-fw"></i> </a>
EOH


	
	  #Apercu du site*****************************************
	  my $link_view = '../cgi-bin/migcms_view.pl?page='.$page{id}.'&colg='.$d{colg}.'&sel='.$sel;
	  my $phrase_view = $migctrad{adm_preview};
	  $apercu = <<"EOH";
		<a href="$link_view"  target="_blank" data-placement="bottom" data-original-title="$phrase_view" class="btn  btn-default "> 
		<i class="fa fa-eye fa-fw"></i> </a>
EOH

	  #Retouches rapides**************************************
	  my $link_view_edit = '../cgi-bin/migcms_view.pl?page='.$page{id}.'&colg='.$d{colg}.'&sel='.$sel.'&edit=y';
	  my $phrase_view_edit = $migctrad{build_title_wysiwyg};
	  $retouches = <<"EOH";
		<a href="$link_view_edit"  target="_blank" data-placement="bottom" data-original-title="$phrase_view_edit" class="btn  btn-default "> 
		<i class="fa fa-bolt fa-fw"></i> </a>
EOH

	}
	else
	{
		$type_permission = 'edit';
		my $class = 'btn-info';
		$edit_paragraphes = <<"EOH";
	<a href="#" data-placement="top" data-original-title="$migctrad{edit} (Ref#$id)" id="$id" role="button" class=" 
		btn $class show_only_after_document_ready migedit_$id migedit">
		<i class="fa fa-fw fa-pencil ">
		</i>
	</a>
EOH
	
	}	
	
	return $edit_paragraphes;
}


sub custom_page_preview
{
	my $id = $_[0];
	my $colg = $_[1];
	my %page = %{$_[2]};
	
	my $disabled = 'disabled';
	my $class = 'btn-link';
	
	if($page{migcms_pages_type} ne 'page')
	{
		my $apercu = <<"EOH";
			<a class="btn $disabled  $class" href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page=$id&mailing=n&lg=$colg" data-original-title="$migctrad{adm_preview}" target="_blank" data-placement="bottom">
				<i class="fa fa-eye fa-fw"></i>
			</a>
EOH
	
	return $apercu;
	}
	
	$disabled = '';
	$class = 'btn-default';
	if($url_rewriting ne '')
	{
		
	}

	my $apercu = <<"EOH";
	<a class="btn $disabled  $class" href="$config{baseurl}/cgi-bin/migcms_view.pl?id_page=$id&mailing=n&lg=$colg" data-original-title="$migctrad{adm_preview}" target="_blank" data-placement="bottom">
		<i class="fa fa-eye fa-fw"></i>
	</a>
EOH
	
	return $apercu;
}

sub custom_page_link
{
	my $id = $_[0];
	my $colg = $_[1];
	my %page = %{$_[2]};

	#DIRECTORY
	my $disabled = 'disabled';
	my $class = 'btn-link';
	
	if($page{migcms_pages_type} eq 'directory')
	{
		my $acces = <<"EOH";
			<a class="btn $disabled $class" href="$url" data-original-title="" target="_blank" data-placement="bottom">
			<i class="fa fa-external-link fa-fw"></i>
			</a>
EOH

		return $acces;
	}
	
	
	#PAGE
	my $disabled = 'disabled';
	my $class = 'btn-link';
	
	if($page{migcms_pages_type} eq 'page')
	{
		$url_rewriting = get_url({debug=>0,debug_results=>0,nom_table=>'migcms_pages',id_table=>$id, id_language => $colg});	
		$url = "$config{baseurl}/".$url_rewriting;
		if($url_rewriting ne '')
		{
			$disabled = '';
			$class = 'btn-default';
		}

		my $acces = <<"EOH";
			<a class="btn $disabled $class" href="$url" data-original-title="$migctrad{build_action_acceder}" target="_blank" data-placement="bottom">
			<i class="fa fa-external-link fa-fw"></i>
			</a>
EOH

		return $acces;
	}
	
	#LIEN
	my $disabled = 'disabled';
	my $class = 'btn-link';

	if($page{migcms_pages_type} eq 'link')
	{
		$url = get_link_page({migcms_page=>\%page});
	}
	if($url_rewriting ne '')
	{
		$disabled = '';
		$class = 'btn-default';
	}

	my $acces = <<"EOH";
		<a class="btn $disabled $class" href="$url" data-original-title="$migctrad{build_action_acceder}" target="_blank" data-placement="bottom">
		<i class="fa fa-external-link fa-fw"></i>
		</a>
EOH

	return $acces;
}

sub recover_url_pages_rew
{
	see();
	exit;
	my @migcms_pages = sql_lines({select=>"id,id_textid_url,id_textid_url_words",table=>'migcms_pages'});
	foreach $migcms_page (@migcms_pages)
	{
		my %migcms_page = %{$migcms_page};
		if($migcms_page{id_textid_url} > 0)
		{
			my %trad_recover = sql_line({table=>'txtcontents_recover',where=>"id='$migcms_page{id_textid_url}'"});
			$trad_recover{lg1} =~ s/\'/\\\'/g;
			my %new_link = (
			'nom_table' => 'migcms_pages',
			'id_table' => $migcms_page{id},
			'id_lg' => 1,
			'url_rewriting' => $trad_recover{lg1},
			);
			inserth_db($dbh,'migcms_force_urls',\%new_link);			
		}
	}
	
	exit;
	my @migcms_pages = sql_lines({select=>"id,id_textid_url,id_textid_url_words",table=>'migcms_pages'});
	foreach $migcms_page (@migcms_pages)
	{
		my %migcms_page = %{$migcms_page};
		if($migcms_page{id_textid_url} > 0)
		{
			$trad_recover{lg1} =~ s/\'/\\\'/g;
			
			#recevor id_textid_url
			my %trad = sql_line({table=>'txtcontents',where=>"id='$migcms_page{id_textid_url}'"});	
			my %trad_recover = sql_line({table=>'txtcontents_recover',where=>"id='$migcms_page{id_textid_url}'"});
			print "<br />$trad{lg1} -> $trad_recover{lg1}";
			$stmt = "UPDATE txtcontents SET lg1 = '$trad_recover{lg1}' WHERE id = '$migcms_page{id_textid_url}'";
			$cursor = $dbh->prepare($stmt);
			$rc = $cursor->execute;
			
			# complète id_textid_url_words
			set_traduction({id_language=>1,traduction=>$trad_recover{lg1},id_traduction=>$migcms_page{id_textid_url_words},table_record=>'migcms_pages',col_record=>'id_textid_url_words',id_record=>$migcms_page{id}});
		}
	}
	exit;
}

sub cure_duplicate_page_txtconents_for_new_cols
{
	see();
	exit;
	# my @cols = qw(
	# id_textid_url
	# id_textid_url_words
	# );
	my @cols = qw(
	id_textid_meta_url
	id_textid_meta_title
	id_textid_meta_description
	);
	log_debug('cure_duplicate_page_txtconents_for_new_cols','vide','cure_duplicate_page_txtconents_for_new_cols');
	
	#boucler sur les pages
	
	
	 # id='6109'
	 # 0,1
	my @parags = sql_lines({table=>'migcms_pages',where=>"migcms_pages_type IN('page','newsletter')",ordby=>"id desc",limit=>""});
	foreach $parag (@parags)
	{
		my %parag = %{$parag};
	
		#boucler sur les colonnes
		foreach my $col (@cols)
		{
			my $log = "PAGE $parag{id}:";
			$log .= "COL $col:";
			
			#si un autre page a cet id traduction
			my %test_parag = sql_line({select=>"id,id_textid_name,mailing_object",table=>'migcms_pages',where=>" $col = '$parag{$col}' AND id != '$parag{id}'"});
			if($test_parag{id} > 0)
			{
				$log .= "PARAG : $test_parag{id}";
				
				#ajouter une nouvelle traduction avec le meme texte et remplacer l'id
				my $traduction = get_traduction({debug=>0,id=>$parag{$col},id_language=>1});
				$traduction =~s/\'/\\\'/g;
				
				$log .= "Trad : $traduction";
				if($traduction ne '')
				{
					my $traduction_page = get_traduction({debug=>0,id=>$parag{id_textid_name},id_language=>1});
					my $traduction_autre_page = get_traduction({debug=>0,id=>$test_parag{id_textid_name},id_language=>1});
					$log = $traduction_page.' : '.$log;
					
					log_debug('PAGE1:'.$parag{id}.':'.$parag{mailing_object}.$traduction_page,'','cure_duplicate_page_txtconents_for_new_cols');
					log_debug('PAGE2:'.$test_parag{id}.':'.$test_parag{mailing_object}.$traduction_autre_page,'','cure_duplicate_page_txtconents_for_new_cols');
					log_debug('Texte concerné:'.$traduction,'','cure_duplicate_page_txtconents_for_new_cols');
					log_debug('','','cure_duplicate_page_txtconents_for_new_cols');
					print $log;
				} 
				
				set_traduction({id_language=>1,traduction=>$traduction,id_traduction=>0,table_record=>'migcms_pages',col_record=>$col,id_record=>$parag{id}});
			}
			else
			{
				# $log .= "PARAG avec même trad : AUCUN";
			}
			
		}
	}
	exit;
}

sub cure_duplicate_parag_txtconents_for_new_cols
{
	see();
	exit;
	my @cols = qw(
	id_textid_text_1
	id_textid_text_2
	id_textid_text_3
	id_textid_text_4
	id_textid_textwysiwyg_1
	id_textid_textwysiwyg_2
	id_textid_textwysiwyg_3
	id_textid_textwysiwyg_4
	);
	log_debug('cure_duplicate_parag_txtconents_for_new_cols','vide','cure_duplicate_parag_txtconents_for_new_cols');
	
	#boucler sur les paragraphes
	
	
	 # id='6109'
	 # 0,1
	my @parags = sql_lines({table=>'parag',where=>"",ordby=>"id desc",limit=>""});
	# my @parags = sql_lines({table=>'parag',where=>"id='6109'",ordby=>"id desc",limit=>""});
	foreach $parag (@parags)
	{
		my %parag = %{$parag};
	
		#boucler sur les colonnes
		foreach my $col (@cols)
		{
			my $log = "PARAG $parag{id}:";
			$log .= "COL $col:";
			
			#si un autre paragraphe a cet id traduction
			my %test_parag = sql_line({select=>"id,id_page",table=>'parag',where=>"$col = '$parag{$col}' AND id != '$parag{id}'"});
			if($test_parag{id} > 0)
			{
				$log .= "PARAG : $test_parag{id}";
				
				#ajouter une nouvelle traduction avec le meme texte et remplacer l'id
				my $traduction = get_traduction({debug=>0,id=>$parag{$col},id_language=>1});
				$traduction =~s/\'/\\\'/g;
				
				$log .= "Trad : $traduction";
				if($traduction ne '')
				{
					my %migcms_page = sql_line({select=>"id_textid_name,mailing_object,id",table=>'migcms_pages',where=>"id = '$parag{id_page}'"});
					my %migcms_page_autre_page = sql_line({select=>"id_textid_name,mailing_object,id",table=>'migcms_pages',where=>"id = '$test_parag{id_page}'"});
					my $traduction_page = get_traduction({debug=>0,id=>$migcms_page{id_textid_name},id_language=>1});
					my $traduction_autre_page = get_traduction({debug=>0,id=>$migcms_page_autre_page{id_textid_name},id_language=>1});
					$log = $traduction_page.' : '.$log;
					
					log_debug('PAGE1:'.$migcms_page{id}.':'.$migcms_page{mailing_object}.$traduction_page,'','cure_duplicate_parag_txtconents_for_new_cols');
					log_debug('PAGE2:'.$migcms_page_autre_page{id}.':'.$migcms_page_autre_page{mailing_object}.$traduction_autre_page,'','cure_duplicate_parag_txtconents_for_new_cols');
					log_debug('Texte concerné:'.$traduction,'','cure_duplicate_parag_txtconents_for_new_cols');
					log_debug('','','cure_duplicate_parag_txtconents_for_new_cols');
					print $log;
				}
				
				set_traduction({id_language=>1,traduction=>$traduction,id_traduction=>0,table_record=>'parag',col_record=>$col,id_record=>$parag{id}});
			}
			else
			{
				# $log .= "PARAG avec même trad : AUCUN";
			}
			
		}
	}
	exit;
}
