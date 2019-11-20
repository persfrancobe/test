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
use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


$colg = get_quoted('colg') || $config{default_colg} || 1;


$dm_cfg{trad}              = 0;
$dm_cfg{customtitle}       = <<"EOH";
    <a href="$config{baseurl}/cgi-bin/adm_data_families.pl?colg=$colg">$migctrad{data_title_families}</a>   
EOH
$dm_cfg{enable_search}     = 0;
$dm_cfg{enable_multipage}  = 0;
$dm_cfg{vis_opt}           = 0;
# $dm_cfg{duplicate}           = 1;
$dm_cfg{sort_opt}          = 0;
$dm_cfg{wherel}            = "";
$dm_cfg{wherep}            = "";
$dm_cfg{table_name}        = "data_families";
$dm_cfg{list_table_name}   = "$dm_cfg{table_name}";

$dm_cfg{self}              = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?";
$dm_cfg{no_export_excel}   = 1;
my $sel                    = get_quoted('sel');
$dm_cfg{page_title}        = 'Annuaires';
$dm_cfg{add_title}         = "Ajouter un annuaire";
$dm_cfg{after_mod_ref}     = \&after_save;
$dm_cfg{after_add_ref}     = \&after_save;
my $selfcolg               = $dm_cfg{self}.'&sw='.$sw.'&id='.get_quoted('id');       
$dm_cfg{default_ordby}     = 'name';
$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="colg" value="$colg" />
EOH
$migctrad{adm_data_families_type_products} = $migctrad{adm_data_families_type_products} ||  'adm_data_families_type_products';
$migctrad{adm_data_families_type_news} = $migctrad{adm_data_families_type_news} ||  'adm_data_families_type_news';

%profil = (
            "03/products"    => "$migctrad{adm_data_families_type_products}",
            "01/other"       => "$migctrad{adm_data_families_type_other}",
            "02/news"        =>"$migctrad{adm_data_families_type_news}",
            "05/multimedia"  =>"$migctrad{adm_data_families_type_multimedia}",
            "04/shoplocator" =>"$migctrad{adm_data_families_type_shop_locator}",
            "06/flipbook"    =>"Page Flip",
		);
		
		
my %roles;
my @migcms_roles = sql_lines({table=>'migcms_roles',where=>"",ordby=>"id"});
foreach $migcms_role (@migcms_roles)
{
	my %migcms_role = %{$migcms_role};
	$roles{sprintf("%.02d",$migcms_role{id}).'/'.$migcms_role{id}} = $migcms_role{nom_role};
}		


my $id_data_family = get_quoted('id') || 0;

@dm_nav =
(
    {
        'tab'   =>'famille',
        'type'  =>'tab',
        'title' =>'Famille'
    }
	,
    {
        'tab'         =>'template',
        'type'        =>'tab',
        'title'       =>'Templates',
        'disable_add' => 0
    } 
	,
    {
        'tab'         =>'droit',
        'type'        =>'tab',
        'title'       =>"Autorisations onglets",
        'cgi_func'    => '',
        'disable_add' => 0
    } 
	,
    {
        'tab'         =>'taille',
        'type'        =>'tab',
        'title'       =>'Tailles des images',
        'cgi_func'    => '',
        'disable_add' => 0
    } 
	,
    {
        'tab'         =>'referencement',
        'type'        =>'tab',
        'title'       =>'Référencement',
        'cgi_func'    => '',
        'disable_add' => 0
    } 
	,
    {
        'tab'         =>'champs_geo',
        'type'        =>'tab',
        'title'       =>'Annuaire géographique (Champs)',
        'cgi_func'    => '',
        'disable_add' => 1
    } 
	
	,
    {
        'tab'         =>'champs_eshop',
        'type'        =>'tab',
        'title'       =>'Boutique (Champs)',
        'cgi_func'    => '',
        'disable_add' => 1
    } 
	
	
	 
);


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = 
(
'01/name'=> 
{
'title'=>$migctrad{adm_data_families_name},
'fieldtype'=>'text',
'fieldsize'=>'50',
'search' => 'y',
'mandatory'=>{"type" => 'not_empty'},
'tab'=>'famille',
}
,
'02/profil'=> 
{
'title'=>$migctrad{adm_data_families_profil},
'fieldtype'=>'listbox',
'fieldvalues'=>\%profil,
'mandatory'=>{"type" => 'not_empty'},

'tab'=>'famille',
}
,
'03/id_template_object'=> 
{
'title'=>$migctrad{adm_data_families_id_template_object},
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'templates.id',
'lbdisplay'=>'templates.name',
'lbwhere'=>"type = 'data'",
'tab'=>'template',
}

,
'04/id_template_detail'=> 
{
'title'=>$migctrad{adm_data_families_id_template_detail},
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'templates.id',
'lbdisplay'=>'templates.name',
'lbwhere'=>"type = 'data'",
'tab'=>'template',
}
,
'05/id_template_listing'=> 
{
'title'=>$migctrad{adm_data_families_id_template_listing},
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'templates.id',
'lbdisplay'=>'templates.name',
'lbwhere'=>"type = 'data'",
'tab'=>'template',
}
,
'06/id_template_page'=> 
{
'title'=>$migctrad{adm_data_families_id_template_page},
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'templates.id',
'lbdisplay'=>'templates.name',
'lbwhere'=>"type = 'page'",
'tab'=>'template',
}
,
'07/id_template_detail_page'=> 
{
'title'=>$migctrad{adm_data_families_id_template_detail_page},
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'templates.id',
'lbdisplay'=>'templates.name',
'lbwhere'=>"type = 'page'",
'tab'=>'template',
}
,
'08/id_template_object_cat'=> 
{
'title'=>'Template objet des catégories',
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'templates.id',
'lbdisplay'=>'templates.name',
'lbwhere'=>"type = 'data'",
'tab'=>'template',
}
,
'09/id_template_page_cat'=> 
{
'title'=>'Template page des catégories',
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'templates.id',
'lbdisplay'=>'templates.name',
'lbwhere'=>"type = 'page'",
'tab'=>'template',
}
,
'10/id_template_listing_cat'=> 
{
'title'=>'Template listing des catégories',
'fieldtype'=>'listboxtable',
'lbtable'=>'templates',
'lbkey'=>'templates.id',
'lbdisplay'=>'templates.name',
'lbwhere'=>"type = 'data'",
'tab'=>'template',
}
,
'11/id_field_name'=> 
{
'title'=>$migctrad{adm_data_families_id_field_name},
'fieldtype'=>'listboxtable',
'lbtable'=>'data_fields',
'lbkey'=>'data_fields.id',
'lbdisplay'=>'id_textid_name',
'lbwhere'=>"id_data_family = $id_data_family",
'tab'=>'champs_eshop',
'translate' => 1,
}

,
'12/id_field_reference'=> 
{
'title'=>$migctrad{adm_data_families_id_field_reference},
'fieldtype'=>'listboxtable',
'lbtable'=>'data_fields',
'lbkey'=>'data_fields.id',
'lbdisplay'=>'id_textid_name',
'lbwhere'=>"id_data_family = $id_data_family",
'tab'=>'champs_eshop',
'translate' => 1,
}
, 
'13/id_field_description'=> 
{
'title'=>'Description',
'fieldtype'=>'listboxtable',
'lbtable'=>'data_fields',
'lbkey'=>'data_fields.id',
'lbdisplay'=>'id_textid_name',
'lbwhere'=>"id_data_family = $id_data_family",
'tab'=>'champs_eshop',
'translate' => 1,
}
,

'14/id_textid_default_name_title'=> 
{
'title'=>$migctrad{adm_data_families_id_textid_default_name_title},
    'fieldtype'=>'text_id',
    'fieldsize'=>'50',
    'search' => 'n',
'tab'=>'famille',
}
,
'15/id_field_shoplocator_street'=> 
{
'title'=>'Adresse',
'fieldtype'=>'listboxtable',
'lbtable'=>'data_fields',
'lbkey'=>'data_fields.id',
'lbdisplay'=>'id_textid_name',
'lbwhere'=>"id_data_family = $id_data_family",
'tab'=>'champs_geo',
'translate' => 1,
}
,
'16/id_field_shoplocator_zip'=> 
{
'title'=>'Code Postal',
'fieldtype'=>'listboxtable',
'lbtable'=>'data_fields',
'lbkey'=>'data_fields.id',
'lbdisplay'=>'id_textid_name',
'lbwhere'=>"id_data_family = $id_data_family",
'tab'=>'champs_geo',
'translate' => 1,
}

,
'17/id_field_shoplocator_city'=> 
{
'title'=>'Ville',
'fieldtype'=>'listboxtable',
'lbtable'=>'data_fields',
'lbkey'=>'data_fields.id',
'lbdisplay'=>'id_textid_name',
'lbwhere'=>"id_data_family = $id_data_family",
'tab'=>'champs_geo',
'translate' => 1,
}
,
'18/id_field_shoplocator_country'=> 
{
'title'=>'Pays',
'fieldtype'=>'listboxtable',
'lbtable'=>'data_fields',
'lbkey'=>'data_fields.id',
'lbdisplay'=>'id_textid_name',
'lbwhere'=>"id_data_family = $id_data_family",
'tab'=>'champs_geo',
'translate' => 1,
}
,
'19/id_field_shoplocator_lat'=> 
{
'title'=>'Lat',
'fieldtype'=>'listboxtable',
'lbtable'=>'data_fields',
'lbkey'=>'data_fields.id',
'lbdisplay'=>'id_textid_name',
'lbwhere'=>"id_data_family = $id_data_family",
'tab'=>'champs_geo',
'translate' => 1,
}
,
'19/id_field_shoplocator_lon'=> 
{
'title'=>'Lon',
'fieldtype'=>'listboxtable',
'lbtable'=>'data_fields',
'lbkey'=>'data_fields.id',
'lbdisplay'=>'id_textid_name',
'lbwhere'=>"id_data_family = $id_data_family",,
'tab'=>'champs_geo',
'translate' => 1,
}

,

'20/mini_width'=> 
{
'title'=>$migctrad{adm_data_families_mini_width},
'fieldtype'=>'text',
'tab'=>'taille',
'mask'=>'000',
'tip'=>'Taille en pixels',
}
,
'21/small_width'=> 
{
'title'=>$migctrad{adm_data_families_small_width},
'fieldtype'=>'text',
'mask'=>'0000',
'tab'=>'taille',
'tip'=>'Taille en pixels',
}
,
'22/medium_width'=> 
{
'title'=>$migctrad{adm_data_families_medium_width},
'fieldtype'=>'text',
'mask'=>'0000',
'tab'=>'taille',
'tip'=>'Taille en pixels',
}
,
'23/large_width'=> 
{
'title'=>$migctrad{adm_data_families_full_width},
'fieldtype'=>'text',
'mask'=>'0000',
'tab'=>'taille',
'tip'=>'Taille en pixels',
}
,
'24/og_width'=> 
{
'title'=>'Taille de la miniature OG',
'fieldtype'=>'text',
'mask'=>'0000',
'tab'=>'taille',
'tip'=>'Taille en pixels',
}
,
'25/medium_height'=> 
{
'title'=>'Hauteur du player vidéo',
'fieldtype'=>'text',
'mask'=>'0000',
'tab'=>'taille',
'tip'=>'Taille en pixels',
}
 ,
'26/id_textid_meta_title'=> 
 {
    'title'=>$migctrad{id_textid_meta_title},
    'fieldtype'=>'textarea_id',
    'search' => 'y',
'tab'=>'referencement',
}
,
'27/id_textid_meta_description'=> 
 {
    'title'=>$migctrad{id_textid_meta_description},
    'fieldtype'=>'textarea_id',
    'search' => 'y',
'tab'=>'referencement',
}
# ,
# '30/id_textid_meta_keywords'=> 
 # {
    # 'title'=>$migctrad{id_textid_meta_keywords},
    # 'fieldtype'=>'textarea_id',
    # 'search' => 'y',
# 'tab'=>'referencement',
# }
,
'31/family_nr'=> 
 {
    'title'=>'Nombre de résultats par page',
    'fieldtype'=>'text',
	'tab'=>'referencement',
	'tab'=>'famille',
'mandatory'=>{"type" => 'not_empty'},
	
}
 ,
'40/id_textid_url_rewriting'=> 
{
    'title'=>$migctrad{id_textid_url_rewriting},
    'fieldtype'=>'text_id',
    'search' => 'n',
	'mandatory'=>{"type" => 'not_empty'},

'tab'=>'referencement',
    
}
 ,
'45/id_textid_fiche'=> 
{
    'title'=>'Nom URL fiche',
    'fieldtype'=>'text_id',
    'search' => 'n',
'tab'=>'referencement',
    
}
, 
'80/id_default_search_form'=> 
{
'title'=>'Moteur de recherche par défaut',
'fieldtype'=>'listboxtable',
'lbtable'=>'data_search_forms',
'lbkey'=>'data_search_forms.id',
'lbdisplay'=>'id_textid_name',
'lbwhere'=>"",
'mandatory'=>{"type" => ''},
'tab'=>'famille',
'translate'=>1,
}
,
'81/in_sitemap'=> 
{
'title'=>'Dans les URLs du sitemap',
'fieldtype'=>'checkbox',
'checkedval' => 'y',
'tab'=>'referencement',
},

'82/allow_robots'=> 
{
'title'=>'Autoriser le crawling des moteurs de recherche',
'fieldtype'=>'checkbox',
'checkedval' => 'y',
'tab'=>'referencement',
},
'83/has_detail'=> 
{
'title'=>'Activer les fiches détail',
'fieldtype'=>'checkbox',
'checkedval' => 'y',
'tab'=>'droit',
}
,
'84/has_tarifs'=> 
{
'title'=>'Activer les tarifs',
'fieldtype'=>'checkbox',
'checkedval' => 'y',
'tab'=>'droit',
}
,
'85/show_categories'=> 
{
'title'=>'Catégories',
'fieldtype'=>'listbox',
'data_type'=>'button',
'multiple'=>1,
'fieldvalues'=>\%roles,
'default_value'=>3,
'mandatory'=>{"type" => 'not_empty'},
'tab'=>'droit',
}
,
'86/show_variantes'=> 
{
'title'=>$migctrad{families_show_variantes},
'fieldtype'=>'listbox',
'data_type'=>'button',
'fieldvalues'=>\%roles,
'default_value'=>0,
'multiple'=>1,
'mandatory'=>{"type" => 'not_empty'},
'tab'=>'droit',
}

,
'87/show_stock'=> 
{
'title'=>$migctrad{families_show_stock},
'fieldtype'=>'listbox',
'multiple'=>1,
'data_type'=>'button',
'fieldvalues'=>\%roles,
'default_value'=>0,
'mandatory'=>{"type" => 'not_empty'},
'tab'=>'droit',
}
,
'88/show_referencement'=> 
{
'title'=>$migctrad{families_show_referencement},
'multiple'=>1,
'fieldtype'=>'listbox',
'data_type'=>'button',
'fieldvalues'=>\%roles,
'default_value'=>0,
'mandatory'=>{"type" => 'not_empty'},
'tab'=>'droit',
}

,
'89/show_pics'=> 
{
'title'=>$migctrad{families_show_pics},
'fieldtype'=>'listbox',
'data_type'=>'button',
'multiple'=>1,
'fieldvalues'=>\%roles,
'default_value'=>0,
'mandatory'=>{"type" => 'not_empty'},
'tab'=>'droit',
}
,
'90/show_files'=> 
{
'title'=>$migctrad{families_show_files},
'fieldtype'=>'listbox',
'data_type'=>'button',
'multiple'=>1,
'fieldvalues'=>\%roles,
'default_value'=>0,
'mandatory'=>{"type" => 'not_empty'},
'tab'=>'droit',
}
, 
'92/func_after_save'=> 
{
'title'=>'Fonction aftersave sheet',
'fieldtype'=>'text',
'tab'=>'famille',
}


# ,
# '92/show_google_map'=> 
# {
# 'title'=>$migctrad{families_show_google_map},
# 'fieldtype'=>'checkbox',
# 'checkedval' => 'y',
# 'tab'=>'champs_geo',
# }
);

%dm_display_fields = 
(
	"01/$migctrad{adm_data_families_name}"=>"name"
);

%dm_lnk_fields = 
    (
 "02/Type"=>"typepreview*",  
 "03/Fiches"=>"editsheets*",
   
    );



%dm_mapping_list = (
"typepreview" => \&typepreview,
"editsheets" => \&editsheets
);

sub after_save
{
    my $dbh=$_[0];
    my $id=$_[1];
    my %family = read_table($dbh,"data_families",$id);

    my @fields= get_table($dbh,"data_fields","","id_data_family='$id'");
    
    if($#fields > -1)
    {
    }
    elsif($family{profil} eq 'products')
    {
        create_field_in_family($dbh,'Référence','text',$id,1,'y','y','y');
        create_field_in_family($dbh,'Nom','text_id',$id,2,'y','y','y');
        create_field_in_family($dbh,'Description','textarea_id_editor',$id,3,'y','y','y');
    }
    elsif($family{profil} eq 'news')
    {
        create_field_in_family($dbh,'Date','text',$id,1,'y','y','y');
        create_field_in_family($dbh,'Titre','text_id',$id,2,'y','y','y');
        create_field_in_family($dbh,'Description courte','textarea_id_editor',$id,3,'y','y','y');
        create_field_in_family($dbh,'Description longue','textarea_id_editor',$id,4,'y','y','y');
    }
    elsif($family{profil} eq 'multimedia')
    {
        create_field_in_family($dbh,'Titre','text',$id,1,'y','y','y');
        create_field_in_family($dbh,'Description','textarea_id_editor',$id,2,'n','y','y');
        create_field_in_family($dbh,'Auteur','text',$id,3,'y','y','y');
        create_field_in_family($dbh,'Date de création','text',$id,4,'n','n','n');
        create_field_in_family($dbh,'Date de publication','text',$id,5,'n','n','n');
        create_field_in_family($dbh,'Durée','text',$id,6,'n','n','y');
        create_field_in_family($dbh,'URL','text_id',$id,7,'n','n','y');
    }
    elsif($family{profil} eq 'shoplocator')
    {
        create_field_in_family($dbh,'Nom','text_id',$id,1,'y','y','y');
        create_field_in_family($dbh,'Latitude','text',$id,2,'y','y','y');
        create_field_in_family($dbh,'Longitude','text',$id,3,'y','y','y');
        create_field_in_family($dbh,'Adresse','text',$id,4,'y','n','n');
        create_field_in_family($dbh,'Code postal','text',$id,5,'y','n','n');
        create_field_in_family($dbh,'Ville','text',$id,6,'y','n','n');
        create_field_in_family($dbh,'Pays','text',$id,7,'y','n','n');
    }    
     elsif($family{profil} eq 'flipbook')
    {
#         create_field_in_family($dbh,'Nom','text_id',$id,1,'y','y','y');
#         create_field_in_family($dbh,'Description','textarea_id_editor',$id,2,'n','y','y');
#         create_field_in_family($dbh,'Largeur Flipbook','text',$id,3,'n','n','n');
#         create_field_in_family($dbh,'Hauteur Flipbook','text',$id,4,'n','n','n');
#         create_field_in_family($dbh,'Largeur PDF','text',$id,5,'n','n','y');
#         create_field_in_family($dbh,'Hauteur PDF','text',$id,6,'n','n','n');
#         create_field_in_family($dbh,'Couleur de fond','text',$id,7,'n','n','n');
#         create_field_in_family($dbh,'Couleur de fond de page','text',$id,8,'n','n','n');
        create_field_in_family($dbh,'Fichier PDF','link_to_file_id',$id,1,'y','y','y');
    }
	
	migcms_create_links();
	
	#traitement URL rew
	my %rec = read_table($dbh,$dm_cfg{table_name},$id);
	my $url_rewriting = get_traduction({id=>$rec{id_textid_url_rewriting},lg=>$config{current_language}});
	$url_rewriting = clean_url($url_rewriting,'y');
	update_text($dbh,$rec{id_textid_url_rewriting},$url_rewriting,$config{current_language});
	
	my $url_rewriting = get_traduction({id=>$rec{id_textid_fiche},lg=>$config{current_language}});
	$url_rewriting = clean_url($url_rewriting,'y');
	update_text($dbh,$rec{id_textid_fiche},$url_rewriting,$config{current_language});

}

sub typepreview
{
    my $dbh = $_[0];
    my $id = $_[1];
    my %family = read_table($dbh,"data_families",$id);
    my $name =  $migctrad{'adm_data_families_type_'.$family{profil}} || $family{profil};
    return $name;
} 

sub editsheets
{
    my $dbh = $_[0];
    my $id = $_[1];
	
    my %family = read_table($dbh,"data_families",$id);
    my $links = '';
    
    my $sel_data_sheets;
    if($id == 1)
    {
      $sel_data_sheets = 1000212;
    }
    elsif ($id == 2)
    {
      $sel_data_sheets = 1000269;
    }
    elsif ($id == 4)
    {
      $sel_data_sheets = 1000214;
    }
    
    my %sel_data_fields = sql_line({select=>"id", table=>"scripts", where=>"url LIKE '%data_fields.pl%'"});
    my %sel_data_crits = sql_line({select=>"id", table=>"scripts", where=>"url LIKE '%data_crits.pl%'"});
    my %sel_data_categories = sql_line({select=>"id", table=>"scripts", where=>"url LIKE '%data_categories.pl%'"});
    
    if($family{id_template_object} > 0 && $family{id_template_detail} > 0 &&$family{id_template_listing} > 0 &&$family{id_template_detail} > 0)
    { 
        $links .=<< "EOH";
        <div class="mig_lnk_content">
            <a class="mig_lnk btn btn-info" href="$config{baseurl}/cgi-bin/adm_data_sheets.pl?colg=$colg&id_data_family=$id&sel=$sel_data_sheets">
                <i class="fa fa-pencil fa-lg"></i> Fiches
            </a>
            
            <a class="mig_lnk btn btn-default" href="$config{baseurl}/cgi-bin/adm_data_fields.pl?colg=$colg&id_data_family=$id&sel=$sel_data_fields{id}">
                <i class="fa fa-th-list"></i> Champs
            </a>
            
            <a class="mig_lnk btn btn-default" href="$config{baseurl}/cgi-bin/adm_data_crits.pl?colg=$colg&id_data_family=$id&sel=$sel_data_crits{id}">
                <i class="fa fa-tags"></i> Critères
            </a>
            
            <a class="mig_lnk btn btn-default" href="$config{baseurl}/cgi-bin/adm_data_categories.pl?colg=$colg&id_data_family=$id&sel=$sel_data_categories{id}">
                <i class="fa fa-sitemap"></i> Catégories
            </a>
        </div>
EOH
    }
	else
	{
		$links .= "<span style='color:red'>Cf configuration <br />templates dans <br />la famille</span>";
	}
	
	#selon config famille: ajouter boutons
	# if ($data_cfg{access_level_fields} >= $user{role}) 
# {
    # $dm_lnk_fields{"02//$migctrad{data_families_champs}"}="$config{baseurl}/cgi-bin/adm_data_fields.pl?colg=$colg&id_data_family=";
# } 

# if ($data_cfg{access_level_crits} >= $user{role}) 
# {
    # $dm_lnk_fields{"03//$migctrad{data_families_crit}"} = "$config{baseurl}/cgi-bin/adm_data_crits.pl?colg=$colg&id_data_family=";
# } 

# if ($data_cfg{access_level_categories} >= $user{role}) 
# {
    # $dm_lnk_fields{"04//$migctrad{data_families_cat}"} = "$config{baseurl}/cgi-bin/adm_data_categories.pl?colg=$colg&id_data_family=";
# } 
	
	
    return $links;
}

  
                 

sub create_field_in_family
{
    my $dbh=$_[0];
    my $nom=$_[1];
    my $type=$_[2];
    my $id_data_family=$_[3];
    my $ordby=$_[4];
    my $in_list=$_[5];
    my $searchable=$_[6];
    my $in_add_multiple=$_[7];
    my $field_tab=$_[8] || 'Fiche';
    
    my %field=();
    $field{id_data_family}=$id_data_family;
    $field{id_textid_name}=insert_text($dbh,$nom,$colg);
    $field{field_type}=$type;
    $field{ordby}=$ordby;
    $field{in_list}=$in_list;
    $field{searchable}=$searchable;
    $field{in_add_multiple}=$in_add_multiple;
    $field{field_tab} = $field_tab;
    inserth_db($dbh,"data_fields",\%field);
}

################################################################################
# ACCESS CONTROL LIST for MODULES
################################################################################

my %data_cfg = eval("%data_cfg = ($config{data_cfg});");


################################################################################



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
  
  $stmt = "DELETE FROM data_field_listvalues WHERE  id_data_family='$id'";
  execstmt($dbh,$stmt);
  
  $stmt = "DELETE FROM data_fields WHERE id_data_family='$id'";
  execstmt($dbh,$stmt);
  
  $stmt = "DELETE FROM data_categories WHERE id_data_family='$id'";
  execstmt($dbh,$stmt);
  
  $stmt = "DELETE FROM data_crit_listvalues WHERE id_data_crit IN ( SELECT id FROM data_crits WHERE id_data_family='$id')";
  execstmt($dbh,$stmt);
  
  $stmt = "DELETE FROM data_crits WHERE id_data_family='$id'";
  execstmt($dbh,$stmt);
}

# sub create_large_pics
# {
	# see();
	# use data;
	# my $pic_dir = '../pics';
	# my %data_family = read_table($dbh,'data_families',1);
	# my @pics = sql_lines({table=>'data_lnk_sheet_pics lnk, pics p',where=>"lnk.id_pic = p.id AND p.pic_width_large = 0"});
	# foreach $pic (@pics)
	# {
		# my %pic = %{$pic};
		# ($large,$large_width,$large_height,$big_width,$big_height) = data::data_thumbnailize($pic{pic_name_full},$pic_dir,\%data_family,,"large");	
	# }
	# exit;
# }
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------