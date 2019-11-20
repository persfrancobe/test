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
use data;

my $id_data_search_form = get_quoted('id_data_search_form');
$dm_cfg{enable_search} = 0;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 1;
$dm_cfg{trad} = 1;
$dm_cfg{duplicate} = 1;
$dm_cfg{wherep_ordby} = $dm_cfg{wherep} = "id_data_search_form=$id_data_search_form";
$dm_cfg{wherel} = "id_data_search_form=$id_data_search_form";
$dm_cfg{table_name} = "data_searchs";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?id_data_search_form=$id_data_search_form&colg=$colg";

$dm_cfg{page_title} = 'Champs de recherche';
$dm_cfg{add_title} = "Ajouter un champs de recherche";
$dm_cfg{after_add_ref}     = \&after_save;
$dm_cfg{after_mod_ref}     = \&after_save;


my %data_search_form = sql_line({table=>'data_search_forms',where=>"id='$id_data_search_form'"});

$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" value="$id_data_search_form" name="id_data_search_form" />
<input type="hidden" name="colg" value="$colg" />
EOH

%field_type = (
"","Veuillez sélectionner",
"input"=>"$migctrad{data_searchs_input}",
# "checkbox"=>"$migctrad{data_searchs_checkbox}",
"list_checkbox"=>"$migctrad{data_searchs_list_checkbox}",
"listbox"=>"$migctrad{data_searchs_listbox}",
"list_links"=>"$migctrad{data_searchs_list_links}",
"tree_links"=>"$migctrad{data_searchs_tree_links}"      
		);
    
%allifvoid_values = (
'',"Veuillez sélectionner",
'y'=>"Si vide, on affiche tout",
'n'=>"Si vide, on n'affiche rien"
);
    
%dm_dfl = (
	    '01/id_textid_name'=> {
	        'title'=>$migctrad{data_searchs_name},
	        'fieldtype'=>'text_id',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
	    ,
	    '02/id_textid_all_label'=> {
	        'title'=>'Libellé valeur tous (listes)',
	        'fieldtype'=>'text_id',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'translate' => 1,
	    }
	    ,
	    '05/type'=> 
      {
	        'title'=>$migctrad{data_searchs_type},
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%field_type,
          'mandatory'=>{"type" => 'not_empty'}
	    }
      
      # ,
	    # '20/targets'=> 
      # {
	        # 'title'=>'Cible(s) de la recherche<br>',
	        # 'fieldtype'=>'textarea',
	     # }
	   
	    ,
	    '12/id_father_cat' => 
      {
           'title'=>'Sous-catégories de',
           'fieldtype'=>'listboxtable',
		   'datatype'=>'treeview',
           'lbtable'=>'data_categories',
           'lbkey'=>'id',
           'lbdisplay'=>'id_textid_name',
           'translate'=>1,
           'multiple'=>0,
		   	'tree_col'=>'id_father',
		    'summary'=>0,
           'lbwhere'=>"id_data_family='$data_search_form{id_data_family}'",
      }
	  
	      ,
	    '13/cols' => 
      {
           'title'=>'Valeurs de colonnes',
           'fieldtype'=>'listboxtable',
		   'data_type'=>'button',
           'lbtable'=>'data_fields',
           'lbkey'=>'id',
           'lbdisplay'=>'id_textid_name',
           'translate'=>1,
           'multiple'=>1,
		    'summary'=>0,
           'lbwhere'=>"id_data_family='$data_search_form{id_data_family}'",
      }
	  
	  

	  
	  
	  
	  
	  
	  
	  
	  
	  
	  
	   # ,
      # '70/id_textid_url_rewriting'=> 
      # {
          # 'title'=>$migctrad{id_textid_url_rewriting},
          # 'fieldtype'=>'text_id',
          # 'search' => 'n',
          # 'mandatory'=>{"type" => 'not_empty'},
      # }
	  ,
      '79/reset'=> 
      {
	        'title'=>'Sans lien avec les autres champs ?',
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y'
	    }
      ,
      '80/in_sitemap'=> 
      {
	        'title'=>'Sitemap ?',
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y'
	    }
       ,
   
	'81/allow_robots'=> 
	{
	'title'=>'Moteurs de recherche ?',
	'fieldtype'=>'checkbox',
	'checkedval' => 'y'
	},
    
      '82/in_breadcrumb'=> 
      {
	        'title'=>'Breadcrumb ?',
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y'
	    }
		
		 
		 ,
      '84/id_data_search_form'=> 
      {
	        'title'=>'Formulaire',
	        'fieldtype'=>'text',
			'hidden'=>1
	    }
		
	);
	
%dm_display_fields = (
  "02/$migctrad{data_searchs_name}"=>"id_textid_name",
  "03/$migctrad{data_searchs_type}"=>"type",
  "04/Sous-catégories de"=>"id_father_cat",
  "05/Champs"=>"cols",
  # "05/Sitemap"=>"in_sitemap",
  # "06/Breadcrumb"=>"in_breadcrumb",
    # "07/Autocomplete"=>"in_autocomplete",
);

%dm_lnk_fields = (
		);

%dm_mapping_list = (
"wizard" => \&get_wizard,
);

%dm_filters = (
		);

my $selfcolg=$dm_cfg{self}.'&sw='.$sw.'&id='.get_quoted('id');       
# this script's name

$sw = $cgi->param('sw') || "list";

see();

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
      wizard
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    
    &$sw();
    
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    my $css=<<"EOH";
   <style>
   .td_01
   {
      width:80px;
      text-align:center;
   }
   .td_04
   {
      width:50px;
      text-align:center;
   }
   </style> 
EOH
    
    print migc_app_layout($css.$migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}



sub after_save
{
    my $dbh = $_[0];
    my $id = $_[1];
	
	my %rec = read_table($dbh,$dm_cfg{table_name},$id);
	if($rec{cols} ne ',' && $rec{cols} ne '' && $rec{type} eq 'input')
	{
		#infos de recherche
		migcms_build_data_searchs_keyword({reset=>'y'});
	}
}