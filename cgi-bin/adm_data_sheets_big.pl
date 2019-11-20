#!/usr/bin/perl -I../lib 

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
# 
# 


# 
         # migc translations
# 
# use migcrender;

# use migccms;
use HTML::Entities;
use Encode;
use Geo::Coder::Google;
#use flipbook;

# use Data::Dumper;
use migcadm;
use data;

$use_global_textcontents=0;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        
###############################################################################################
####################################	CODE DU PROGRAMME		#####################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


my $id_data_family=get_quoted('id_data_family') || 1;

my $id_data_category=get_quoted('id_data_category') || 0;
$colg = get_quoted('colg') || 1;
my $apercu_classement = $config{apercu_classement} || get_quoted('apercu_classement') || 'y';



#vérifier nb_crit et nb_data_stock recu dans after save

my %family=read_table($dbh,"data_families",$id_data_family);

$dm_cfg{page_title} = $family{name};
$dm_cfg{add_title} = "Ajouter <span style='font-size:12px'>une fiche dans $family{name}</span>";


$dm_cfg{map_param} = "data_family";
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 1;
$dm_cfg{trad} = 1;

my $all=get_quoted('all') || "n";
$dm_cfg{wherep} = $dm_cfg{wherel} = $dm_cfg{wherep_ordby} = "id_data_family=$id_data_family";
$dm_cfg{ordby_desc} = 1;
$dm_cfg{table_name} = "data_sheets";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{default_ordby} = "data_sheets.id desc";    
$dm_cfg{autocreation} = 1;
$dm_cfg{file_prefixe} = 'sheets';

#enable duplicate line
# $dm_cfg{duplicate}='y';

#custom duplicate func
# $dm_cfg{custom_duplicate_func}=\&custom_duplicate_data_sheet;

#add a custom func to generate a filter
# $dm_cfg{custom_filter_func}=\&tree_categories_filter;

$dm_cfg{javascript_custom_func_form} = 'init_datasheets_form';
$dm_cfg{javascript_custom_func_listing} = '';

if($id_data_category > 0)
{
    $dm_cfg{wherep} = $dm_cfg{wherel} = "id IN (select id_data_sheet from data_lnk_sheets_categories where id_data_category = $id_data_category)";
}

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;

$self=$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?id_data_family=$id_data_family&colg=$colg&apercu_classement=$apercu_classement&id_data_category=$id_data_category";
 my $sw = $cgi->param('sw') || "list";


$dm_cfg{list_html_top} = <<"EOH";
<script type="text/javascript">
 
	jQuery(document).ready(function() 
	{
		jQuery(document).on("change", ".add_category", function()
		{
			var id_data_sheet = jQuery(this).attr('id');
			var id_data_category = jQuery(this).val();
			var id_data_family = jQuery('input[name="id_data_family"]').val();
			var colg = jQuery('input[name="colg"]').val();

			var cette_case = jQuery(this).parent();

			cette_case.html('<i style="color:#4cae4c" class="fa fa-floppy-o temp_icon "></i>');
			jQuery.ajax(
			{
			 type: "POST",
			 url: "../cgi-bin/adm_data_sheets.pl",
			 data: "sw=add_category&id_data_sheet="+id_data_sheet+"&id_data_category="+id_data_category+"&id_data_family="+id_data_family+"&colg="+colg,
			 success: function(msg)
			 {
				  cette_case.html(msg);
			 }
			});
		});	
		
	});
</script>	
EOH
 
#CODE HTML DANS LE HEAD-----------------------------------------------------------------------------------------
$dm_cfg{head} =<<"EOH";
<script src="../mig_skin/js/jstree.min.js"></script>  
<link rel="stylesheet" href="../mig_skin/css/default/style.min.css" />
<script type="text/javascript">
	
	
	function init_datasheets_form()
	{
		var edit_id =  jQuery(".edit_id").val();
		if(edit_id > 0)
		{
			//CATEGORIES---------------------------------

			//init tree
			jQuery('#son_'+edit_id).jstree(
			{
				"checkbox" : 
				{
					"keep_selected_style" : false,
					"three_state" : false,
					'cascade':''
				},
				"plugins" : [ "checkbox" ]
			});

			//save cat link
			jQuery('#son_'+edit_id).on("changed.jstree", function (e, data) 
			{
				jQuery(".bg-info").append(' <i style="color:#4cae4c" class="fa fa-floppy-o temp_icon "></i>');

				var request = jQuery.ajax(
				{
					url: get_self(),
					type: "GET",
					data: 
					{
					   sw : 'ajax_data_categories_save_link',
					   id_data_sheet : edit_id,
					   id_data_categories : data.selected
					},
					dataType: "html"
				});
				
				request.done(function(msg) 
				{
				   jQuery('.temp_icon').remove();
				});
				request.fail(function(jqXHR, textStatus) 
				{
					alert( "Erreur de sauvegarde: " + textStatus );
				});
			});
			
			
			//VARIANTES
			jQuery(".critcoche").each(function(i)
			{
				jQuery( this ).next().toggleClass('btn-default').toggleClass('btn-info');
			});
			
			
			jQuery(document).on("click", ".datasheet_save_crit", function()
			{
				jQuery( this ).toggleClass('critcoche');
				jQuery( this ).next().toggleClass('btn-default').toggleClass('btn-info');
				
				jQuery(".bg-info").append(' <i style="color:#4cae4c" class="fa fa-floppy-o temp_icon "></i>');
				
				var coches = new Object();
				jQuery(".critcoche").each(function(i)
				{
					var input = jQuery( this );
					coches[input.attr('name')] = input.val();
				});
			
				coches.sw = 'ajax_data_crits_save_link';
				coches.id_data_sheet = edit_id;
				coches.nb_crits = jQuery('input[name="nb_crits"]').val();
				jQuery('.stock_change').removeClass('hide');
				var request = jQuery.ajax(
				{
					url: get_self(),
					type: "GET",
					data: coches,
					dataType: "html"
				});
				
				request.done(function(msg) 
				{
				   jQuery('.temp_icon').remove();
				   
				   
				    //refresh variantes 
				    var request_variantes = jQuery.ajax(
					{
						url: get_self(),
						type: "GET",
						data: 
						{
						   sw : 'datasheets_getstock',
						   id_data_sheet : edit_id
						},
						dataType: "html"
					});
					
					request_variantes.done(function(msg) 
					{
						jQuery('.edit_group_tarifs').html(msg);
					});
				});
				request.fail(function(jqXHR, textStatus) 
				{
					alert( "Erreur de sauvegarde: " + textStatus );
				});
			});
		}
	}
</script>
EOH

$dm_cfg{body} = <<"EOH";
  <input type="hidden" name="cpt" value="$cpt">
  <input type="hidden" name="lg" value="$config{current_language}">
  $dm_cfg{hiddp}
EOH

%visibilite = (
  "y"=>"Visibles",
  "n"=>"Invisibles",
		);


@dm_nav =
(
    {
        'tab'=>'Fiche',
		'type'=>'tab',
        'title'=>'Fiche'
    }
	,
    {
        'tab'=>'rubriques',
		'type'=>'tab',
        'title'=>'Rubriques de classement',
		'cgi_func' => 'datasheets_getcategories',
		'disable_add' => 1
    } 
	,
    {
        'tab'=>'variantes',
		'type'=>'tab',
        'title'=>'Variantes',
		'cgi_func' => 'datasheets_getvariants',
		'disable_add' => 1
    } 
	,
    {
		'tab'=>'tarifs',
		'type'=>'tab',
        'title'=>'Tarifs, poids, stock & TVA',
		'cgi_func' => 'datasheets_getstock',
		'disable_add' => 1
    } 
	,
    {
        'tab'=>'taxes',
		'type'=>'tab',
        'title'=>'Taxes et frais',
		'cgi_func' => '',
		'disable_add' => 1
    } 
	,
    {
        'tab'=>'ref',
		'type'=>'tab',
        'title'=>'Référencement',
		'cgi_func' => '',
		'disable_add' => 1
    } 
	,
    {
        'tab'=>'photos',
		'type'=>'tab',
        'title'=>'Photos',
		'cgi_func' => '',
		'disable_add' => 1
    }
	# ,
    # {
        # 'tab'=>'fichiers',
		# 'type'=>'tab',
        # 'title'=>'Fichiers',
		# 'cgi_func' => '',
		# 'disable_add' => 1
    # }
);

if( !($family{show_categories} >= $user{role})) 
{
	delete $dm_nav[1];
}
if( !($family{show_variantes} >= $user{role})) 
{
	delete $dm_nav[2];
}
if( !($family{show_stock} >= $user{role})) 
{
	delete $dm_nav[3];
}
if( !($family{show_taxes} >= $user{role})) 
{
	delete $dm_nav[4];
}
if( !($family{show_referencement} >= $user{role})) 
{
	delete $dm_nav[5];
}
if( !($family{show_pics} >= $user{role})) 
{
	delete $dm_nav[6];
}
if( !($family{show_files} >= $user{role})) 
{
	delete $dm_nav[7];
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérés de la bdd

     if($sw ne 'export_data_sheets')
     {
          see();
     }
       
      #DM_DFL       
	  
	  if($id_data_family =~ /\//)
	  {
		($ordby_family,$id_data_family) = split(/\//,$id_data_family);	  
	  }
	  
      %dm_dfl = %{data_get_repository_list($dbh,$id_data_family,$colg)};
	  
my %hash=('fieldtype' => 'textarea_id','title' => $migctrad{id_textid_meta_title},'tab'=>'ref');
$dm_dfl{'81/id_textid_meta_title'}=\%hash;

my %hash=('fieldtype' => 'textarea_id','title' => $migctrad{id_textid_meta_description},'tab'=>'ref');
$dm_dfl{'82/id_textid_meta_description'}=\%hash;

my %hash=('fieldtype' => 'text_id','title' => "Mots clés pour l'url" ,'tab'=>'ref');
$dm_dfl{'83/id_textid_url_rewriting'}=\%hash;

my %hash=('fieldtype' => 'textarea_id','title' => 'Mots clés de recherche','tab'=>'ref');
$dm_dfl{'84/id_textid_fulltext'}=\%hash;  

my %hash=('fieldtype' => 'files_admin','title' => 'Photos','tab'=>'photos');
$dm_dfl{'91/photos'}=\%hash;
# my %hash=('fieldtype' => 'files_admin','title' => 'Fichiers','tab'=>'fichiers');
# $dm_dfl{'92/fichiers'}=\%hash;

$dm_dfl{'99/id_data_family'} = 
{
	'title'=>"Famille",
	'fieldtype'=>'text',
	'lbtable'=>'data_families',
	'hidden'=>1,
	'lbkey'=>'id',
	'lbdisplay'=>"name",
	'lbwhere'=>"" ,
	'search' => 'n',
	'tab'=>'Fiche'
};

    
      my $size = 0;
      $size += scalar keys %dm_dfl;  # method 1: explicit scalar context
      if ($size == 0)
      {
           make_error("$migctrad{datadirs_raw_data_error_nofield}");
      }
      $size = 0;
	 
      ($ref_df,$ref_ml,$ref_fil) = data_get_repository_display($dbh,$id_data_family,$colg);
      
      %dm_display_fields=%{$ref_df};
      %dm_mapping_list=%{$ref_ml};
      %dm_filters=%{$ref_fil};
      $dm_filters{'1/Visibilité'}=
      {
            'type'=>'hash',
      	     'ref'=>\%visibilite,
      	     'col'=>'visible'
      };

      $size += scalar keys %dm_display_fields;  # method 1: explicit scalar context
      if ($size == 0)
      {
      }
      
      foreach $key (sort keys(%dm_dfl))
      {
            my ($dum,$field) = split (/\//,$key);
            push @dm_dfl, $field;
      }

      @searchable_fields = @dm_dfl;

	if ($family{show_stock} >= $user{role}) 
	{
		if($config{disable_stock_in_admin_listing} ne 'y')
		{
			$dm_lnk_fields{"60/Stock"} = "stock_preview*";
			$dm_mapping_list{stock_preview} = \&stock_preview;
		}
		if($config{disable_stock_in_admin_listing} ne 'y')
		{
				$dm_lnk_fields{"70/Prix"} = "price_preview*";
				$dm_mapping_list{price_preview} = \&price_preview;
			}
		} 

	if ($family{show_associes} >= $user{role}) 
	{
		$dm_lnk_fields{"53/$migctrad{product_families_assoc}/$migctrad{product_families_assoc}"} = "$config{baseurl}/cgi-bin/adm_data_assoc.pl?id_data_family=$id_data_family&id_data_sheet=";		
	} 

	if ( $family{show_categories} >= $user{role} && $apercu_classement eq 'y') 
	{
		$dm_lnk_fields{"99/Aperçu classement"} = "cat_preview*";
		$dm_mapping_list{cat_preview} = \&cat_preview;
	}

	if ($family{show_pics} >= $user{role}) 
	{
		$dm_lnk_fields{"00/Photo"} = "pic_preview*";  
		$dm_mapping_list{pic_preview} = \&pic_preview;
	}


	if ($config{fb_gateway} eq "y") 
	{
		$dm_lnk_fields{"75/Facebook/Publier"} = "$config{baseurl}/cgi-bin/adm_fb_publish.pl?sw=publish_data_sheet_form&id_data_sheet=";
	} 


my @fcts = qw(
		add_form
		mod_form
		list
		add_db
		test_pictures_div
		mod_db
		ajax_save_price
		del_db
		set_supply
		admin_nodes_db
		add_multiple
		photo_change_position
		tree_categories_filter
		ajax_save_data_db
		upload_pics
		copy_data_sheets_textcontents_to_another_language
		manage_pictures
		load_sheet_pictures
		export_data_sheets
		sauvegarde_adresse
		add_category
		toggle_checkbox
		ajax_data_categories_save_link
		ajax_data_crits_save_link
	);
    
if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    print migc_app_layout($migc_output{content},$migc_output{title},"",$style.$gen_bar,$spec_bar);
}

sub ajax_save_price
{
      my $id_data_stock_tarif = get_quoted('id_data_stock_tarif');
      my %data_stock_tarif = read_table($dbh,"data_stock_tarif",$id_data_stock_tarif);
      my %data_sheet = read_table($dbh,"data_sheets",$data_stock_tarif{id_data_sheet});
      data_copy_col_to_price($dbh,\%data_sheet);
      
      my $valeur = get_quoted('valeur');
      my $col = get_quoted('col');
      
      my $st_pu_htva = 0;
      my $st_pu_tvac = 0;
      if($col eq 'st_pu_tvac')
      {
          $st_pu_tvac = $valeur;
      }
      elsif($col eq 'st_pu_htva')
      {
          $st_pu_htva = $valeur;
      }
      if($st_pu_htva > 0 && $st_pu_tvac > 0)
      {
      }
      elsif($st_pu_htva > 0)
      {
         $st_pu_tvac = $st_pu_htva *(1 + ($data_sheet{taux_tva} / 100));  
      }
      elsif($st_pu_tvac > 0)
      {
         $st_pu_htva = $st_pu_tvac / (1 + ($data_sheet{taux_tva} / 100));  
      }
      my $st_pu_tva = $st_pu_tvac - $st_pu_htva;
      my %new_data_stock_tarif = 
      (
          st_pu_htva => $st_pu_htva,
          st_pu_tva => $st_pu_tva,
          st_pu_tvac => $st_pu_tvac,
          taux_tva => $data_sheet{taux_tva} / 100,
      );
      sql_set_data({debug=>0,dbh=>$dbh,table=>'data_stock_tarif',data=>\%new_data_stock_tarif,where=>"id='$id_data_stock_tarif'"});
      exit;
}


sub add_category
{
    # see();
	my $id_data_sheet = get_quoted('id_data_sheet');
    my $id_data_category = get_quoted('id_data_category');
    my $id_data_family = get_quoted('id_data_family');
    my $colg = get_quoted('colg') || 1;
    
    my %check = select_table($dbh,"data_lnk_sheets_categories","","id_data_sheet='$id_data_sheet' AND id_data_category = '$id_data_category'");
    if($check{id} > 0)
    {
		my $list_cats="";
        my @cats_linked =get_table($dbh,"data_lnk_sheets_categories lnk","distinct(id_data_category) as id_data_category","id_data_sheet='$id_data_sheet'");
        foreach $cat_linked (@cats_linked)
        {
            my %cat = %{$cat_linked};
            $list_cats .= " $cat{id_data_category}, ";
        }
        $list_cats .= ' 0 ';
        
        my $list_cats_preview = get_categories_list($dbh,'','','','',$id_data_family,'this_list_cats_only',$list_cats,$colg);
        my $list_cats_change = get_categories_list($dbh,'','','','',$id_data_family,'select','',$colg);
        
        data_resort_categories();
        
        print "$list_cats_preview<br /><select name='add_category' class='add_category' id='$id_data_sheet'><option value=''>+</option>$list_cats_change</select>";
	
    }
    else
    {
        my %new = ();
        $new{id_data_category} = $id_data_category;
        $new{id_data_sheet} = $id_data_sheet;
        $new{visible} = 'y';
        inserth_db($dbh,"data_lnk_sheets_categories",\%new);
        
        if($config{data_link_categories_father} eq 'y')
        {
            link_to_fathers($id_data_sheet);
        }
        
        my $list_cats="";
        my @cats_linked =get_table($dbh,"data_lnk_sheets_categories lnk","distinct(id_data_category) as id_data_category","id_data_sheet='$id_data_sheet'");
        foreach $cat_linked (@cats_linked)
        {
            my %cat = %{$cat_linked};
            $list_cats .= " $cat{id_data_category}, ";
        }
        $list_cats .= ' 0 ';
        
        my $list_cats_preview = get_categories_list($dbh,'','','','',$id_data_family,'this_list_cats_only',$list_cats,$colg);
        my $list_cats_change = get_categories_list($dbh,'','','','',$id_data_family,'select','',$colg);
        
        data_resort_categories();
        
        print "$list_cats_preview<br /><select name='add_category' class='add_category' id='$id_data_sheet'><option value=''>+</option>$list_cats_change</select>";
    }
    exit;
}


sub data_resort_categories
{
   my @data_categories = sql_lines({table=>'data_categories',ordby=>'id'});
   foreach $data_category (@data_categories)
   {
      my $new_ordby = 1;
      my %data_category = %{$data_category};
      my @lnks = sql_lines({table=>'data_lnk_sheets_categories',where=>"id_data_category='$data_category{id}'",ordby=>'ordby,id'});
      foreach $lnk (@lnks)
      {
            my %lnk = %{$lnk};
            $stmt = "UPDATE data_lnk_sheets_categories SET ordby = '$new_ordby' WHERE id ='$lnk{id}'";
            execstmt($dbh,$stmt);
            $new_ordby++; 
      }
   }
}

sub export_data_sheets
{
 #create file
 my $outfile = "../usr/datasheets_".$id_data_family.".xls";
 
 # Create a new Excel workbook
 my $workbook = Spreadsheet::WriteExcel->new($outfile);
 my $row=0,$col=0;

 # Add a worksheet
 $worksheet = $workbook->add_worksheet("Exports fiches");
 
 
 my @intitules = ();
 my @champs = ();
 my @champs_types = ();
 my @champs_sizes = ();
 
 
 push @intitules,"Référence interne Bugiweb";
 push @champs,'id';
 push @champs_types,'';
push @champs_sizes,'35';
 
 
#  my @fields = get_table($dbh,"data_fields","","visible='y' AND id_data_family = '$id_data_family' AND (1 OR field_type = 'text_id' OR field_type = 'textarea_id_editor' OR field_type = 'textarea_id')");
 my @fields = get_table($dbh,"data_fields","","visible='y' AND id_data_family = '$id_data_family' ");
 foreach $field (@fields)
 {
    my %field = %{$field};

    my ($name,$dum) = get_textcontent($dbh,$field{id_textid_name},$colg);
    if($field{field_type} eq 'text_id' || $field{field_type} eq 'textarea_id' || $field{field_type} eq 'textarea_id_editor')
    {
        push @intitules,"Référence traduction Bugiweb ($name)";
        push @champs_types,'trad';
    }
    else
    {
        push @champs_types,'';
    }
    push @intitules,"$name";
    push @champs,'f'.$field{ordby};
    push @champs_sizes,'75';
 } 
 
 push @intitules,"Prix";
 push @champs,'price';
 push @champs_types,'';
 push @champs_sizes,'10';
 
 push @intitules,"Prix PRO";
 push @champs,'price_pro';
 push @champs_types,'';
 push @champs_sizes,'10';
 
 push @intitules,"Stock";
 push @champs,'stock';
 push @champs_types,'';
 push @champs_sizes,'10';
 
 push @intitules,"Taux TVA";
 push @champs,'taux_tva';
 push @champs_types,''; 
 push @champs_sizes,'10';
 
 push @intitules,"Rubrique";
 push @champs,'category';
 push @champs_types,''; 
 push @champs_sizes,'40';
 
 #1. intitules******************************************************************	
 foreach $intitule (@intitules)
 {
    $val = decode("utf8",$intitule);
    $worksheet->write(0,$col++,$val,$format2);
 }
#   see();
 #2. read data and fill in excel page
 $row = 3;
 $col = 0;
 
 my @data_sheets = get_table($dbh,"data_sheets","","id_data_family = '$id_data_family'");
 foreach $data_sheet (@data_sheets)
 {
      my %data_sheet = %{$data_sheet};
      my $i_champ = 0;
      foreach $champ (@champs)
      {    
         my $val = decode("utf8",$data_sheet{$champ});
         
         if($champ eq 'stock')
         {
            $val = stock_preview($dbh,$data_sheet{id});
#               $val = $data_sheet{stock};
         }
         elsif($champ eq 'category')
         {
            my %cat = select_table($dbh,"data_categories c, data_lnk_sheets_categories lnk, textcontents txt","content","lnk.id_data_category = c.id AND id_data_sheet='$data_sheet{id}' AND c.id_textid_name = txt.id_textid AND txt.id_language=1");
            $val = $cat{content};
            $val = decode("utf8",$val);
         }
         
         my $name = $val;
         if($champs_types[$i_champ] eq 'trad')
         {
             $worksheet->set_column($col,$col+1, 5);
             $worksheet->write($row,$col++,$val,$format2);
             ($name,$dum) = get_textcontent($dbh,$val,$colg);
         }
          
          $name =~ s/(^ *)||( *$)//g;
					$name =~ s/<br \/>/\n/g;
					$name =~ s/<[^>]*>//g;
					$name =~ s/\r*\n/\n/g;
					$name =~ s/(^\n*)||(\n*$)//g;
					
          $val = $name;
#           $val = decode("utf8",$val);
          $val = decode_entities($val);
         
         $worksheet->set_column($col,$col+1, $champs_sizes[$i_champ]);
         $worksheet->write($row,$col++,$val,$format2);
         $i_champ++;
      }
      
      foreach $nb_pic (1 .. 10)
      {
          my $limit1 = $nb_pic -1;
          my %pic = select_table($dbh,"data_lnk_sheet_pics lnk, pics p","pic_name_small","p.id=lnk.id_pic AND lnk.id_data_sheet = '$data_sheet{id}' ORDER BY lnk.ordby LIMIT $limit1,1");     
          $worksheet->set_column($col,$col+1,50);
         
#           $worksheet->insert_image($row,$col++,'/data/www/MIGC/PINK-APPLE-NEW/pics/'.$pic{pic_name_small});      
          my $pic_path = '../pics/'.$pic{pic_name_small};
          if(-e $pic_path && $nb_pic == 1 && $data_sheet{id} == 60)
          {
              $worksheet->insert_image($row,$col++,$pic_path);
          }
          else
          {
               $worksheet->write($row,$col++,$pic{pic_name_small},$format2);
          }      
      }
      
      $col = 0;
      $row++;
 }
#    exit;
 #3. write excel file & download it
 $workbook->close();
  
 print $cgi->header(-type=>"application/vnd.ms-excel",-attachment=>$outfile);
  
 open (FILE,$outfile);
 binmode FILE;
 binmode STDOUT;
 while (read(FILE,$buff,2096))
 {
     print STDOUT $buff;
 }
 close (FILE);
 exit;
}

sub set_supply
{
   my $id_data_sheet=get_quoted('id_data_sheet');
   $table=get_supply_table_form($id_data_sheet,$id_data_family);
   $dm_output{title} = $dm_cfg{customtitle}.' > '.$migctrad{data_stock_title};
   $dm_output{content}=$table;#.$log;
}

#remplacé par save_prices_stock pr migc4
sub update_data_stock
{
    my $id_data_sheet=$_[0] || get_quoted('id_data_sheet') ||  "";
    my %data_sheet = select_table($dbh,"data_sheets","id,taux_tva,f1","id='$id_data_sheet'");
    my $id_data_family=get_quoted('id_data_family');
    my $no_crit=get_quoted('no_crit') || 'n';

     if(1 || $no_crit ne "y") 
     {
        if($config{version_num} >= 3620)
        {
              my @tarifs = sql_lines({table=>"eshop_tarifs","visible='y'"});
              foreach $tarif (@tarifs)
              {
                  my %tarif = %{$tarif};
                 
                  #AVEC CRITERES**********************************************************
                  my $nb_variants = get_quoted('nb_variants');
                  my $i;
                  
                  for ($i=0; $i<$nb_variants; $i++) 
                  {
                      my $default_ref =  $data_sheet{f1}.$i;
                      my %data_stock;
                      my $id_data_stock = get_quoted('id_stock_'.$i);
                      $data_stock{weight}=get_quoted('weight_'.$i);
                      $data_stock{stock}=get_quoted('stock_'.$i);
                      $data_stock{reference}=get_quoted('reference_'.$i) || $default_ref;
                      $data_stock{ordby}=get_quoted('ordby_'.$i);
                      
                      updateh_db($dbh,"data_stock",\%data_stock,"id",$id_data_stock);
                      
                      my $st_pu_htva = get_quoted('st_pu_htva_'.$tarif{id}.'_'.$i);
                      my $st_pu_tvac = get_quoted('st_pu_tvac_'.$tarif{id}.'_'.$i);
                      if($st_pu_htva > 0 && $st_pu_tvac > 0)
                      {
                      }
                      elsif($st_pu_htva > 0)
                      {
                         $st_pu_tvac = $st_pu_htva *(1 + ($data_sheet{taux_tva} / 100));  
                      }
                      elsif($st_pu_tvac > 0)
                      {
                         $st_pu_htva = $st_pu_tvac / (1 + ($data_sheet{taux_tva} / 100));  
                      }
                      my $st_pu_tva = $st_pu_tvac - $st_pu_htva;
                      my %new_data_stock_tarif = 
                      (
                          st_pu_htva => $st_pu_htva,
                          st_pu_tva => $st_pu_tva,
                          st_pu_tvac => $st_pu_tvac,
                          taux_tva => $data_sheet{taux_tva} / 100,
                          id_data_sheet => $data_sheet{id},
                          id_data_stock => $id_data_stock,
                          id_tarif => $tarif{id},
                      );
                      sql_set_data({debug=>0,dbh=>$dbh,table=>'data_stock_tarif',data=>\%new_data_stock_tarif,where=>"id_data_stock='$id_data_stock' AND id_tarif='$tarif{id}'"});
                  }
              }
        }
        else
        {
            #AVEC CRITERES**********************************************************
            my $nb_variants = get_quoted('nb_variants');
            my $i;
            
            for ($i=0; $i<$nb_variants; $i++) 
            {
                my $default_ref =  $data_sheet{f1}.$i;
                my %data_stock;
                my $id_data_stock = get_quoted('id_stock_'.$i);
                $data_stock{weight}=get_quoted('weight_'.$i);
                $data_stock{stock}=get_quoted('stock_'.$i);
                $data_stock{price_currency1}=get_quoted('price_'.$i);
                $data_stock{price_currency2}=get_quoted('price2_'.$i);
                $data_stock{reference}=get_quoted('reference_'.$i) || $default_ref;
                $data_stock{ordby}=get_quoted('ordby_'.$i);
                updateh_db($dbh,"data_stock",\%data_stock,"id",$id_data_stock);
            }
        }
     }
     else
     {
        # SANS CRITERE***********************************************************
        my %data_stock;
        my $id_data_stock = get_quoted('id_stock');
        $data_stock{weight}=get_quoted('weight');
        $data_stock{stock}=get_quoted('stock');
        if($config{version_num} >= 3620)
        {
              my @tarifs = sql_lines({table=>"eshop_tarifs","visible='y'"});
              foreach $tarif (@tarifs)
              {
                  my %tarif = %{$tarif};
                  my $st_pu_htva = get_quoted('st_pu_htva_'.$tarif{id}.'_');
                  my $st_pu_tvac = get_quoted('st_pu_tvac_'.$tarif{id}.'_');
                  if($st_pu_htva > 0 && $st_pu_tvac > 0)
                  {
                  }
                  elsif($st_pu_htva > 0)
                  {
                     $st_pu_tvac = $st_pu_htva *(1 + ($data_sheet{taux_tva} / 100));  
                  }
                  elsif($st_pu_tvac > 0)
                  {
                     $st_pu_htva = $st_pu_tvac / (1 + ($data_sheet{taux_tva} / 100));  
                  }
                  my $st_pu_tva = $st_pu_tvac - $st_pu_htva;
                  my %new_data_stock_tarif = 
                  (
                      st_pu_htva => $st_pu_htva,
                      st_pu_tva => $st_pu_tva,
                      st_pu_tvac => $st_pu_tvac,
                      taux_tva => $data_sheet{taux_tva} / 100,
                  );
                  sql_set_data({debug=>0,dbh=>$dbh,table=>'data_stock_tarif',data=>\%new_data_stock_tarif,where=>"id_data_stock='$id_data_stock' AND id_tarif='$tarif{id}'"});
              }
        }
        else
        {
              $data_stock{price_currency1}=get_quoted('price');
              $data_stock{price_currency2}=get_quoted('price2');
        }
        $data_stock{reference}=get_quoted('reference') || $data_sheet{f1};
        updateh_db($dbh,"data_stock",\%data_stock,"id",$id_data_stock);
     }
      fill_prices_in_data_sheet($id_data_sheet);
      
      
      my %sheet = read_table($dbh,"data_sheets",$id_data_sheet);
      my %data_family = read_table($dbh,"data_families",$sheet{id_data_family});
      my %data_setup = %{data_get_setup()};
      my $tpl_object = migcrender::get_template($dbh,$data_family{id_template_object});
      my $tpl_detail = migcrender::get_template($dbh,$data_family{id_template_detail});
      
      if($config{version_num} >= 3620)
      {
          data_write_all_tiles_optimized({data_setup=>\%data_setup,id_data_sheet=>$sheet{id}});
      }
      else
      {
          data::data_write_tiles_optimized($dbh,\%sheet,\%data_family,$data_family{id_template_object},$tpl_object,$lg,0,'object',$extlink,'',\@discount_rules,\@discount_rules_pro,'y',\%data_setup);
          data::data_write_tiles_optimized($dbh,\%sheet,\%data_family,$data_family{id_template_detail},$tpl_detail,$lg,0,'detail',$extlink,'',\@discount_rules,\@discount_rules_pro,'y',\%data_setup);
      }
     http_redirect("$config{baseurl}/cgi-bin/adm_data_sheets.pl?id_data_family=$id_data_family");
}



sub update_ordby_nodes_todel
{
 my $dbh = $_[0];
 my $prod = $_[1];


 my ($id_tree,$stmt,$rc,$cursor,$stmt2,$rc2,$cursor2,$ordby) ;
 
 $stmt = "select DISTINCT id_data_category FROM data_lnk_sheets_categories WHERE id_data_sheet=$prod";
 $cursor = $dbh->prepare($stmt);
 $rc = $cursor->execute;
 if (!$rc) {die("error execute : $DBI::errstr [$stmt]\n");}
 
 $cursor->bind_columns(\$id_tree);
 while ($cursor->fetch())
  {
   $stmt2 = "SELECT ordby FROM data_lnk_sheets_categories WHERE id_data_category = $id_tree AND id_data_sheet=$prod";
   $cursor2 = $dbh->prepare($stmt2);
   $cursor2->execute or suicide("error execute : $DBI::errstr [$stmt]\n");
   $ordby = $cursor2->fetchrow_array;
   if ($ordby eq "") {$ordby = 0;}
   $cursor2->finish;
   execstmt($dbh,"UPDATE data_lnk_sheets_categories SET ordby = ordby-1 WHERE ordby > $ordby AND id_data_category=$id_tree");
  }

$stmt = "delete FROM data_lnk_sheets_categories WHERE id_data_sheet = $prod";
execstmt($dbh,$stmt);
 
}

sub after_save_flipbookmy 		
{		
	$flipbook_file = $_[0];
	my ($flipbook_lg,$flipbook_file) = split (/\:/,$flipbook_file);
	my %flipbook_file = read_table($dbh,"data_lnk_sheet_files",$flipbook_file);
	my $flipbook_filepath = $flipbook_file{path}.'/'.$flipbook_file{filename};
	flipbook::create_flipbook($id,$flipbook_filepath);
}

sub after_save_shoplocator
{
	my $id_data_sheet = $_[0];
	my %data_sheet = read_table($dbh,"data_sheets",$id_data_sheet);
	my %family = read_table($dbh,'data_families',$data_sheet{id_data_family});

	my $street = $data_sheet{f4};
	if($family{id_field_shoplocator_street} > 0)
	{
	   my %field = read_table($dbh,"data_fields",$family{id_field_shoplocator_street});
	   $street =  $data_sheet{'f'.$field{ordby}};
	}
	my $zip = $data_sheet{f5};
	if($family{id_field_shoplocator_zip} > 0)
	{
	   my %field = read_table($dbh,"data_fields",$family{id_field_shoplocator_zip});
	   $zip =  $data_sheet{'f'.$field{ordby}};
	}
	my $city = $data_sheet{f6};
	if($family{id_field_shoplocator_city} > 0)
	{
	   my %field = read_table($dbh,"data_fields",$family{id_field_shoplocator_city});
	   $city =  $data_sheet{'f'.$field{ordby}};
	}
	my $country = $data_sheet{f7};
	if($family{id_field_shoplocator_country} > 0)
	{
	   my %field = read_table($dbh,"data_fields",$family{id_field_shoplocator_country});
	   $country =  $data_sheet{'f'.$field{ordby}};
	}

	my $adresse=" $street, $zip $city, $country ";
	$adresse =~ s/\r*\n//g;

	my $field_lat = 'f2';
	my $lat=$datadir_sheet{f2};
	if($family{id_field_shoplocator_lat} > 0)
	{
	   my %field = read_table($dbh,"data_fields",$family{id_field_shoplocator_lat});
	   $lat =  $data_sheet{'f'.$field{ordby}};
	   $field_lat = 'f'.$field{ordby};
	}
	my $lon=$datadir_sheet{f3};
	my $field_lon = 'f3';
	if($family{id_field_shoplocator_lon} > 0)
	{
	   my %field = read_table($dbh,"data_fields",$family{id_field_shoplocator_lon});
	   $lon =  $data_sheet{'f'.$field{ordby}};
	   $field_lon = 'f'.$field{ordby};
	}

	my $geocoder = Geo::Coder::Google->new(apiver => 3);
	my $location;
	eval { $location = $geocoder->geocode(location => $adresse) };

	if($@)
	{
		# print <<"EOH";
		# <script type="text/javascript">
		  # alert("L'adresse n'a pu être localisée par Google");
		# </script>
# EOH
	}
	else
	{
	  my $latitude = $location->{geometry}{location}{lat};
	  my $longitude = $location->{geometry}{location}{lng};  

		  if($id_data_sheet ne "" && $latitude ne "" && $longitude ne "" && $field_lat eq "" && $field_lon eq "")
		  {
			my $stmt =<<"EOH"; 
					  UPDATE data_sheets 
					  SET $field_lat = '$latitude',
						  $field_lon = '$longitude'
					  WHERE id='$id_data_sheet'
EOH
			execstmt($dbh,$stmt);

		  }
	    else
	    {
			# print <<"EOH";
			# <script type="text/javascript">
			  # alert("Une erreur est survenue lors de la mise à jour de la latitude et de la longitude (informations manquantes)");
			# </script>
# EOH
		} 
	}
} 
	
	
	
	
sub after_save
{
    # see();
    my $dbh=$_[0];
    my $id=$_[1];
    my $id_data_sheet = $id;
    my %data_sheet = read_table($dbh,"data_sheets",$id_data_sheet);
    my $id_data_family = $data_sheet{id_data_family};
    my %family = read_table($dbh,"data_families",$id_data_family);
    my %data_family = %family;
    my %cfg_family = eval("%cfg_family = ($family{config});");
    my %cfg = get_hash_from_config($dbh,"quotation_cfg"); 
    my $colg=get_quoted('colg') || 1;
    
    if($data_family{profil} eq 'flipbook')
    {
        after_save_flipbook($data_sheet{f2});
    }
    
    my $sw=get_quoted('sw');
    
    #FILL VOID FIELD REFERENCE TO REFxxxxx**************************************
    if($data_family{id_field_reference} > 0)
    {
        my %field_reference = read_table($dbh,"data_fields",$data_family{id_field_reference});
        my $reference = $data_sheet{'f'.$field_reference{ordby}};
        if($reference eq '')
        {
            my $stmt = "UPDATE data_sheets SET f".$field_reference{ordby}." = CONCAT('ref',id) WHERE id = $data_sheet{id} AND f".$field_reference{ordby}."=''";
            execstmt($dbh,$stmt);
        }
    }
    elsif($family{profil} eq 'products')
    {
       my %data_sheet = read_table($dbh,"data_sheets",$id_data_sheet);
       if($data_sheet{f1} eq '' && $data_sheet{id} > 0)
       {
          $stmt = "UPDATE data_sheets SET f1 = concat('ref',id) WHERE id = $id_data_sheet";
          $cursor = $dbh->prepare($stmt);
          $rc = $cursor->execute;
          if (!$rc) {die("error execute : $DBI::errstr [$stmt]\n");}
       } 
    } 
    
    # SHOP LOCATOR: COMPUTE LAT & LON********************************************
    if($family{profil} eq 'shoplocator')
    {                          
       after_save_shoplocator($id_data_sheet);	 
	}
       

    #PLACE LES INFOS REFERENCEMENT - id_textid_url******************************
    my ($check,$dum) = get_textcontent($dbh,$data_sheet{id_textid_url_rewriting},$colg);
    if($check eq '')
    {
        my %field_name = read_table($dbh,"data_fields",$data_family{id_field_name});
        my $name = $data_sheet{'f'.$field_name{ordby}};
        if($field_name{field_type} eq 'text_id' || $field_name{field_type} eq 'textarea_id' || $field_name{field_type} eq 'text_id_editor')
        {
            ($name,$dum)=get_textcontent($dbh,$name,$colg);
        }
        my $name_url = clean_url($name);
        
        my $id_textid_url_rewriting = insert_text($dbh,$name_url,$colg);
        my $stmt = "UPDATE data_sheets SET id_textid_url_rewriting=$id_textid_url_rewriting WHERE id=$id_data_sheet";
        execstmt($dbh,$stmt); 
    }
    
    #PLACE LES INFOS REFERENCEMENT - id_textid_meta_title***********************
    my ($check,$dum) = get_textcontent($dbh_data,$data_sheet{id_textid_meta_title},$colg);
    if($check eq '')
    {
        my %field_name = read_table($dbh,"data_fields",$data_family{id_field_name});
        my $name = $data_sheet{'f'.$field_name{ordby}};
        if($field_name{field_type} eq 'text_id' || $field_name{field_type} eq 'textarea_id' || $field_name{field_type} eq 'textarea_id_editor')
        {
            ($name,$dum)=get_textcontent($dbh,$name,$colg);
        }
        $name =~ s/\'/\\\'/g;
        my $id_textid_meta_title = insert_text($dbh,$name,$colg);
        my $stmt = "UPDATE data_sheets SET id_textid_meta_title=$id_textid_meta_title WHERE id=$id_data_sheet";
        execstmt($dbh,$stmt);
    }
    
    #PLACE LES INFOS REFERENCEMENT - id_textid_meta_description*****************
    my ($check,$dum) = get_textcontent($dbh_data,$data_sheet{id_textid_meta_description}, $colg);
    if($check eq '')
    {
        my %field_description = read_table($dbh,"data_fields",$data_family{id_field_description});
        my $descr = $data_sheet{'f'.$field_description{ordby}};
        if($field_description{field_type} eq 'text_id' || $field_description{field_type} eq 'textarea_id' || $field_description{field_type} eq 'textarea_id_editor')
        {
            ($descr,$dum)=get_textcontent($dbh,$descr,$colg);
        }
        $descr =~ s/\'/\\\'/g;
        
        $descr =~ s/<[^>]*>/ /g;
        $descr =~ s/  / /g;
        $descr =~ s/  / /g;
        my $id_textid_meta_description = insert_text($dbh,$descr,$colg);
        
        my $stmt = "UPDATE data_sheets SET id_textid_meta_description=$id_textid_meta_description WHERE id=$id_data_sheet";
        execstmt($dbh,$stmt); 
    }   
     
    #IF ADD A shop DATA, redirect to price_form
    if($family{profil} eq 'products')  
    {
      
      
#         TRANSITION 
#       data_write_tiles($dbh,$id_data_sheet,$colg);
      # my %sheet = read_table($dbh,"data_sheets",$id_data_sheet);
      # my %data_family = read_table($dbh,"data_families",$sheet{id_data_family});
      # my $tpl_object = migcrender::get_template($dbh,$data_family{id_template_object});
      # my $tpl_detail = migcrender::get_template($dbh,$data_family{id_template_detail});
      # my %data_setup = %{data_get_setup()};   
      # data::data_write_tiles_optimized($dbh,\%sheet,\%data_family,$data_family{id_template_object},$tpl_object,$lg,0,'object',$extlink,'',\@discount_rules,\@discount_rules_pro,'y',\%data_setup);
      # data::data_write_tiles_optimized($dbh,\%sheet,\%data_family,$data_family{id_template_detail},$tpl_detail,$lg,0,'detail',$extlink,'',\@discount_rules,\@discount_rules_pro,'y',\%data_setup);
      
      
      # fill_prices_in_data_sheet($id_data_sheet);
      # data_copy_col_to_price($dbh,\%data_sheet,'f3');
      # http_redirect("$dm_cfg{self_mp}&sw=mod_form&id=$id_data_sheet&step=2$search_params");
      # exit;
    # }
    # else
    # {
		# print "update data stock for $_[1]";
      # update_data_stock($_[1]);
	  save_prices_stock($_[1]);
      # data_copy_col_to_price($dbh,\%data_sheet,'f3');
      
      
      
      # http_redirect("$dm_cfg{self_mp}&sw=list");
      # exit;
    }
}

sub save_prices_stock
{
	my $id_data_sheet = $_[0] || get_quoted('id');
	my %data_sheet = read_table($dbh,'data_sheets',$id_data_sheet);

	my @tarifs = sql_lines({table=>"eshop_tarifs","visible='y'"});
	my $id_data_family = $data_sheet{id_data_family} || get_quoted('id_data_family');
	my $no_crit = get_quoted('no_crit') || 'n';

	
	if($no_crit eq 'y')
	{
		#SANS CRITERES
		
		my %data_stock;
        my $id_data_stock = get_quoted('id_stock');
        $data_stock{weight} = get_quoted('weight');
        $data_stock{stock} = get_quoted('stock');
        $data_stock{reference} = get_quoted('reference') || $data_sheet{f1};
		updateh_db($dbh,"data_stock",\%data_stock,"id",$id_data_stock);
		
		#update stock in data_sheets
		my %update_data_sheet = 
		(
			stock => $data_stock{stock}
		);
		updateh_db($dbh,"data_sheets",\%update_data_sheet,"id",$id_data_sheet);

		foreach $tarif (@tarifs)
		{
			my %tarif = %{$tarif};
			my $st_pu_htva = get_quoted('st_pu_htva_'.$tarif{id}.'_');
			my $st_pu_tvac = get_quoted('st_pu_tvac_'.$tarif{id}.'_');
			if($st_pu_htva > 0)
			{
				$st_pu_tvac = $st_pu_htva *(1 + ($data_sheet{taux_tva} / 100));  
			}
			elsif($st_pu_tvac > 0)
			{
				$st_pu_htva = $st_pu_tvac / (1 + ($data_sheet{taux_tva} / 100));  
			}
			my $st_pu_tva = $st_pu_tvac - $st_pu_htva;
			my %new_data_stock_tarif = 
			(
			  st_pu_htva => $st_pu_htva,
			  st_pu_tva => $st_pu_tva,
			  st_pu_tvac => $st_pu_tvac,
			  taux_tva => $data_sheet{taux_tva} / 100,
			);
			sql_set_data({debug=>0,dbh=>$dbh,table=>'data_stock_tarif',data=>\%new_data_stock_tarif,where=>"id_data_stock='$id_data_stock' AND id_tarif='$tarif{id}'"});
		}
	}
	else
	{
		my $total_stock = 0;
		
		#AVEC CRITERES
		foreach $tarif (@tarifs)
		{
			my %tarif = %{$tarif};
			
			# AVEC CRITERES**********************************************************
			my $nb_variants = get_quoted('nb_variants');
			my $i;

			for ($i=0; $i<$nb_variants; $i++) 
			{
				my $default_ref =  $data_sheet{f1}.$i;
				my %data_stock;
				my $id_data_stock = get_quoted('id_stock_'.$i);
				
				$data_stock{weight}=get_quoted('weight_'.$i);
				$data_stock{stock}=get_quoted('stock_'.$i);
				$total_stock +=  $data_stock{stock};
				
				$data_stock{reference}=get_quoted('reference_'.$i) || $default_ref;
				$data_stock{ordby}=get_quoted('ordby_'.$i);

				updateh_db($dbh,"data_stock",\%data_stock,"id",$id_data_stock);

				my $st_pu_htva = get_quoted('st_pu_htva_'.$tarif{id}.'_'.$i);
				my $st_pu_tvac = get_quoted('st_pu_tvac_'.$tarif{id}.'_'.$i);
				if($st_pu_htva > 0)
				{
					$st_pu_tvac = $st_pu_htva *(1 + ($data_sheet{taux_tva} / 100));  
				}
				elsif($st_pu_tvac > 0)
				{
					$st_pu_htva = $st_pu_tvac / (1 + ($data_sheet{taux_tva} / 100));  
				}
				
				my $st_pu_tva = $st_pu_tvac - $st_pu_htva;
				my %new_data_stock_tarif = 
				(
					st_pu_htva => $st_pu_htva,
					st_pu_tva => $st_pu_tva,
					st_pu_tvac => $st_pu_tvac,
					taux_tva => $data_sheet{taux_tva} / 100,
					id_data_sheet => $data_sheet{id},
					id_data_stock => $id_data_stock,
					id_tarif => $tarif{id},
				);
				sql_set_data({debug=>0,dbh=>$dbh,table=>'data_stock_tarif',data=>\%new_data_stock_tarif,where=>"id_data_stock='$id_data_stock' AND id_tarif='$tarif{id}'"});
			}
		}
		
		#clean useless data_stock_tarif
		$stmt = "UPDATE data_sheets SET stock = '$total_stock' WHERE id = $data_sheet{id}";
		execstmt($dbh,$stmt);
		
	}
	
	#clean useless data_stock_tarif
	$stmt = "DELETE FROM data_stock_tarif WHERE id_data_stock NOT IN (select id from data_stock)";
	execstmt($dbh,$stmt);	
}

# sub update_data_stock
# {
    # my $id_data_sheet=$_[0] || get_quoted('id_data_sheet') ||  "";
    # my %data_sheet = select_table($dbh,"data_sheets","id,taux_tva,f1","id='$id_data_sheet'");
    # my $id_data_family=get_quoted('id_data_family');
    # my $no_crit=get_quoted('no_crit') || 'n';

     # if(1 || $no_crit ne "y") 
     # {
        # if($config{version_num} >= 3620)
        # {
              # my @tarifs = sql_lines({table=>"eshop_tarifs","visible='y'"});
              # foreach $tarif (@tarifs)
              # {
                  # my %tarif = %{$tarif};
                 
                  # AVEC CRITERES**********************************************************
                  # my $nb_variants = get_quoted('nb_variants');
                  # my $i;
                  
                  # for ($i=0; $i<$nb_variants; $i++) 
                  # {
                      # my $default_ref =  $data_sheet{f1}.$i;
                      # my %data_stock;
                      # my $id_data_stock = get_quoted('id_stock_'.$i);
                      # $data_stock{weight}=get_quoted('weight_'.$i);
                      # $data_stock{stock}=get_quoted('stock_'.$i);
                      # $data_stock{reference}=get_quoted('reference_'.$i) || $default_ref;
                      # $data_stock{ordby}=get_quoted('ordby_'.$i);
                      
                      # updateh_db($dbh,"data_stock",\%data_stock,"id",$id_data_stock);
                      
                      # my $st_pu_htva = get_quoted('st_pu_htva_'.$tarif{id}.'_'.$i);
                      # my $st_pu_tvac = get_quoted('st_pu_tvac_'.$tarif{id}.'_'.$i);
                      # if($st_pu_htva > 0 && $st_pu_tvac > 0)
                      # {
                      # }
                      # elsif($st_pu_htva > 0)
                      # {
                         # $st_pu_tvac = $st_pu_htva *(1 + ($data_sheet{taux_tva} / 100));  
                      # }
                      # elsif($st_pu_tvac > 0)
                      # {
                         # $st_pu_htva = $st_pu_tvac / (1 + ($data_sheet{taux_tva} / 100));  
                      # }
                      # my $st_pu_tva = $st_pu_tvac - $st_pu_htva;
                      # my %new_data_stock_tarif = 
                      # (
                          # st_pu_htva => $st_pu_htva,
                          # st_pu_tva => $st_pu_tva,
                          # st_pu_tvac => $st_pu_tvac,
                          # taux_tva => $data_sheet{taux_tva} / 100,
                          # id_data_sheet => $data_sheet{id},
                          # id_data_stock => $id_data_stock,
                          # id_tarif => $tarif{id},
                      # );
                      # sql_set_data({debug=>0,dbh=>$dbh,table=>'data_stock_tarif',data=>\%new_data_stock_tarif,where=>"id_data_stock='$id_data_stock' AND id_tarif='$tarif{id}'"});
                  # }
              # }
        # }
        # else
        # {
            # AVEC CRITERES**********************************************************
            # my $nb_variants = get_quoted('nb_variants');
            # my $i;
            
            # for ($i=0; $i<$nb_variants; $i++) 
            # {
                # my $default_ref =  $data_sheet{f1}.$i;
                # my %data_stock;
                # my $id_data_stock = get_quoted('id_stock_'.$i);
                # $data_stock{weight}=get_quoted('weight_'.$i);
                # $data_stock{stock}=get_quoted('stock_'.$i);
                # $data_stock{price_currency1}=get_quoted('price_'.$i);
                # $data_stock{price_currency2}=get_quoted('price2_'.$i);
                # $data_stock{reference}=get_quoted('reference_'.$i) || $default_ref;
                # $data_stock{ordby}=get_quoted('ordby_'.$i);
                # updateh_db($dbh,"data_stock",\%data_stock,"id",$id_data_stock);
            # }
        # }
     # }
     # else
     # {
        # SANS CRITERE***********************************************************
        # my %data_stock;
        # my $id_data_stock = get_quoted('id_stock');
        # $data_stock{weight}=get_quoted('weight');
        # $data_stock{stock}=get_quoted('stock');
        # if($config{version_num} >= 3620)
        # {
              # my @tarifs = sql_lines({table=>"eshop_tarifs","visible='y'"});
              # foreach $tarif (@tarifs)
              # {
                  # my %tarif = %{$tarif};
                  # my $st_pu_htva = get_quoted('st_pu_htva_'.$tarif{id}.'_');
                  # my $st_pu_tvac = get_quoted('st_pu_tvac_'.$tarif{id}.'_');
                  # if($st_pu_htva > 0 && $st_pu_tvac > 0)
                  # {
                  # }
                  # elsif($st_pu_htva > 0)
                  # {
                     # $st_pu_tvac = $st_pu_htva *(1 + ($data_sheet{taux_tva} / 100));  
                  # }
                  # elsif($st_pu_tvac > 0)
                  # {
                     # $st_pu_htva = $st_pu_tvac / (1 + ($data_sheet{taux_tva} / 100));  
                  # }
                  # my $st_pu_tva = $st_pu_tvac - $st_pu_htva;
                  # my %new_data_stock_tarif = 
                  # (
                      # st_pu_htva => $st_pu_htva,
                      # st_pu_tva => $st_pu_tva,
                      # st_pu_tvac => $st_pu_tvac,
                      # taux_tva => $data_sheet{taux_tva} / 100,
                  # );
                  # sql_set_data({debug=>0,dbh=>$dbh,table=>'data_stock_tarif',data=>\%new_data_stock_tarif,where=>"id_data_stock='$id_data_stock' AND id_tarif='$tarif{id}'"});
              # }
        # }
        # else
        # {
              # $data_stock{price_currency1}=get_quoted('price');
              # $data_stock{price_currency2}=get_quoted('price2');
        # }
        # $data_stock{reference}=get_quoted('reference') || $data_sheet{f1};
        # updateh_db($dbh,"data_stock",\%data_stock,"id",$id_data_stock);
     # }
      # fill_prices_in_data_sheet($id_data_sheet);
      
      
      # my %sheet = read_table($dbh,"data_sheets",$id_data_sheet);
      # my %data_family = read_table($dbh,"data_families",$sheet{id_data_family});
      # my %data_setup = %{data_get_setup()};
      # my $tpl_object = migcrender::get_template($dbh,$data_family{id_template_object});
      # my $tpl_detail = migcrender::get_template($dbh,$data_family{id_template_detail});
      
      # if($config{version_num} >= 3620)
      # {
          # data_write_all_tiles_optimized({data_setup=>\%data_setup,id_data_sheet=>$sheet{id}});
      # }
      # else
      # {
          # data::data_write_tiles_optimized($dbh,\%sheet,\%data_family,$data_family{id_template_object},$tpl_object,$lg,0,'object',$extlink,'',\@discount_rules,\@discount_rules_pro,'y',\%data_setup);
          # data::data_write_tiles_optimized($dbh,\%sheet,\%data_family,$data_family{id_template_detail},$tpl_detail,$lg,0,'detail',$extlink,'',\@discount_rules,\@discount_rules_pro,'y',\%data_setup);
      # }
     # http_redirect("$config{baseurl}/cgi-bin/adm_data_sheets.pl?id_data_family=$id_data_family");
# }


sub data_copy_col_to_price
{
      my $dbh = $_[0];
      my %data_sheet = %{$_[1]};
      my $col = $_[2];
      my $id_data_sheet = $data_sheet{id};
      
      if($config{data_copy_col_to_price} eq 'y')
      {
           my $new_price = $data_sheet{$col};
           $new_price =~ s/[^0-9-]*//g;
           $stmt = "UPDATE data_sheets SET price = '$new_price' WHERE id = $data_sheet{id}";
           execstmt($dbh,$stmt);
      }
      else
      {
          if($config{version_num} < 3620)
          {
              my $lowest_price = data_get_lowest_price($dbh,$id_data_sheet);
              my $lowest_price_pro = data_get_lowest_price_pro($dbh,$id_data_sheet); 
              $stmt = "UPDATE data_sheets SET price = '$lowest_price', price_pro = '$lowest_price_pro' WHERE id = $id_data_sheet";
              execstmt($dbh,$stmt);
          }
          else
          {
              my %data_stock_tarif = sql_line({debug=>0,debug_results=>0,table=>'data_stock_tarif',select=>'MIN(st_pu_tvac) as st_pu_tvac',where=>"id_data_sheet='$id_data_sheet' AND id_tarif = 1"});
              my %data_stock_tarif_pro = sql_line({debug=>0,debug_results=>0,table=>'data_stock_tarif',select=>'MIN(st_pu_tvac) as st_pu_tvac',where=>"id_data_sheet='$id_data_sheet' AND id_tarif = 2"});
              my $lowest_price = $data_stock_tarif{st_pu_tvac};
              my $lowest_price_pro = $data_stock_tarif_pro{st_pu_tvac};
              $stmt = "UPDATE data_sheets SET price = '$lowest_price', price_pro = '$lowest_price_pro' WHERE id = $id_data_sheet";
              execstmt($dbh,$stmt);
              # print $stmt;
          }
      }
}

# sub link_to_fathers
# {
        # my $id_data_sheet = $_[0];
        # my @data_lnk_sheets_categories=get_table($dbh,"data_lnk_sheets_categories lnk, data_categories cat","","id_data_category = cat.id AND id_data_sheet='$id_data_sheet'",'','','',0);
        # foreach $lcat (@data_lnk_sheets_categories)
        # {
            # my %lcat=%{$lcat};
            # my $id_father =$lcat{id_father}; 
            
            # my %father = read_table($dbh,"data_categories cat","$id_father");
            # if($father{id} > 0)
            # {
                # push @cats_to_add, $father{id};
            # }
            # if($father{id_father} > 0)
            # {
                # my %grand_father = read_table($dbh,"data_categories cat","$father{id_father}");
                # if($grand_father{id} > 0)
                # {
                    # push @cats_to_add, $grand_father{id};
                # }
                # if($grand_father{id_father} > 0)
                # {
                    # my %grand_grand_father = read_table($dbh,"data_categories cat","$grand_father{id_father}");
                    # if($grand_grand_father{id} > 0)
                    # {
                        # push @cats_to_add, $grand_grand_father{id};
                    # }
                # }
            # }
        # }
        # print Dumper \@cats_to_add;
        # foreach $cat_to_add (@cats_to_add)
        # {
           # my %data_lnk_sheets_categories=();
           # $data_lnk_sheets_categories{id_data_sheet} = $id_data_sheet;
           # $data_lnk_sheets_categories{id_data_category} = $cat_to_add;
           # $data_lnk_sheets_categories{id_data_family} = $family{id};
           
           # $stmt = "SELECT MAX(ordby)+1 FROM data_lnk_sheets_categories WHERE id_data_category=$cat_to_add";
           # $cursor = $dbh->prepare($stmt);
           # $cursor->execute or suicide("error execute : $DBI::errstr [$stmt]\n");
           # my ($ordbymax) = $cursor->fetchrow_array;
           # if ($ordbymax eq "") { $ordbymax = 1;} 
           
           # $data_lnk_sheets_categories{ordby} = $ordbymax;
           
           # sql_update_or_insert($dbh,"data_lnk_sheets_categories",\%data_lnk_sheets_categories,'','',"id_data_sheet=$id_data_sheet AND id_data_category=$cat_to_add");
        # }

# }

sub same_branches
{
 my $dbh = $_[0];
 my $prod = $_[1];
 my $count = $_[2];
 
my %assoc = ();

 my @lnks = get_table($dbh,"data_lnk_sheets_categories","*","id_data_sheet='$prod'");
 foreach $lnk (@lnks) 
 {
     $assoc{$lnk->{id_data_category}}{nb}++;
     $assoc{$lnk->{id_data_category}}{ordby} = $lnk->{ordby};
     $assoc{$lnk->{id_data_category}}{id} = $lnk->{id};
 }
 
 my $has_changed = 0;
 for ($i = 0; $i < $count; $i++)
 {
  my $id_cat = $cgi->param($i);
  $assoc{$id_cat}{nb}++;
  $assoc{$id_cat}{i}=$i;
    
 }

 return \%assoc;
}                              

sub data_lnk_sheets_listvalues_exists
{
  my $id_crit_listvalue=$_[0];
  my $id_data_sheet=$_[1];
  
  my %record= sql_line({debug=>1,debug_results=>1,table=>"data_lnk_sheets_listvalues",select=>"id",where=>"id_crit_listvalue='$id_crit_listvalue' AND id_data_sheet='$id_data_sheet'"});
  if($record{id} > 0)
  {
    return 1;
  }
  else
  {
    return 0;
  }
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_view
{
	my %item = %{$_[0]};
	my $form = build_view(\%dm_dfl,\%item);

	return $form;
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub before_del
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  wipe_data_sheet($dbh,$id,"y");
  
  
}

sub custom_duplicate_data_sheet
{
    my $dbh_data=$_[0];
    my $id_data_sheet=$_[1];
    
    #duplicate basic line of data sheet (TEXT or TEXTID)
    my $new_id_data_sheet=dm::duplicate_simple_record($dbh_data,$id_data_sheet,'reverse_ordby');
    execstmt($dbh_data,"UPDATE data_sheets SET visible = 'n' WHERE id='$new_id_data_sheet'");
    execstmt($dbh_data,"UPDATE data_sheets SET id_textid_meta_title = '' WHERE id='$new_id_data_sheet'");
    execstmt($dbh_data,"UPDATE data_sheets SET id_textid_meta_description = '' WHERE id='$new_id_data_sheet'");
    execstmt($dbh_data,"UPDATE data_sheets SET id_textid_meta_keywords = '' WHERE id='$new_id_data_sheet'");
    execstmt($dbh_data,"UPDATE data_sheets SET id_textid_url_rewriting = '' WHERE id='$new_id_data_sheet'");
    execstmt($dbh_data,"UPDATE data_sheets SET id_textid_fulltext = '' WHERE id='$new_id_data_sheet'");
    
#     #update ordby
#     my %data_sheet = read_table($dbh,"data_sheets",$id_data_sheet);
#     my $id_data_family = $data_sheet{id_data_family};
#     my $next_ordby = get_next_ordby(dbh=>$dbh,table=>'data_sheets',where=>" id_data_family = '$id_data_family' ");
#     execstmt($dbh_data,"UPDATE data_sheets SET ordby = '$next_ordby' WHERE id='$new_id_data_sheet'");

    #duplicate pictures in pictures zone
#     my @data_lnk_sheet_pics=get_table($dbh,"data_lnk_sheet_pics","","id_data_sheet='$id_data_sheet'",'','','',0);
#     foreach $lpic (@data_lnk_sheet_pics)
#     {
#         my %lpic=%{$lpic};
#         delete $lpic{id};
#         $lpic{id_data_sheet}=$new_id_data_sheet;
# #         see(\%lpic);
#         inserth_db($dbh_data,'data_lnk_sheet_pics',\%lpic);
#     }
    
    #duplicate files in files zone
    
    
    #duplicate links with categories
    duplicate_categories($dbh_data,$id_data_sheet,$new_id_data_sheet);
    
    #duplicate links with crits
    
    
    #duplicate stock
    my @data_stocks=get_table($dbh,"data_stock","","id_data_sheet='$id_data_sheet'",'','','',0);
    foreach $data_stock (@data_stocks)
    {
        my %data_stock=%{$data_stock};
        my $old_id_data_stock = $data_stock{id};
        delete $data_stock{id};
        $data_stock{id_data_sheet}=$new_id_data_sheet;
        $data_stock{reference} =  'ref'.$new_id_data_sheet;
        my $new_id_data_stock = inserth_db($dbh_data,'data_stock',\%data_stock);
        
        #duplicate tarifs linked to this old datastock
        my @old_tarifs = sql_lines({table=>'data_stock_tarif',where=>"id_data_stock='$old_id_data_stock'"});
        foreach $old_tarif (@old_tarifs)
        {
            my %old_tarif = %{$old_tarif};
            delete $old_tarif{id};
            $old_tarif{id_data_stock} = $new_id_data_stock;
            $old_tarif{id_data_sheet} = $new_id_data_sheet;
            my $new_id_tarif = inserth_db($dbh,'data_stock_tarif',\%old_tarif);
        }
    }
    
    my %new_data_sheet = read_table($dbh_data,"data_sheets",$new_id_data_sheet);
    my %data_family = read_table($dbh_data,"data_families",$new_data_sheet{id_data_family});
    if($data_family{id_field_reference} > 0)
    {
        my %field_reference = read_table($dbh,"data_fields",$data_family{id_field_reference});
        my $stmt = "UPDATE data_sheets SET f".$field_reference{ordby}." = CONCAT('ref',id) WHERE id = $new_id_data_sheet";
        execstmt($dbh,$stmt);
    }
}                       

sub duplicate_categories
{
    my $dbh_data=$_[0];
    my $old_data_sheet=$_[1];
    my $new_data_sheet=$_[2];
#     see();
    
    my @lnk_cats=get_table($dbh_data,'data_lnk_sheets_categories',"","id_data_sheet='$old_data_sheet'");
    for($i_cat=0;$i_cat<$#lnk_cats+1;$i_cat++)
    {
        my %new_lnk=();
        $new_lnk{id_data_sheet}=$new_data_sheet;
        $new_lnk{id_data_category}=$lnk_cats[$i_cat]{id_data_category};
        $new_lnk{id_data_family}=$lnk_cats[$i_cat]{id_data_family};
        $new_lnk{visible}=$new_lnk{ordby}=$lnk_cats[$i_cat]{visible};
        $new_lnk{ordby}=$lnk_cats[$i_cat]{ordby};
        $new_lnk{ordby}++;
        
#         see(\%new_lnk);
        my $q="UPDATE data_lnk_sheets_categories SET ordby = ordby+1 WHERE ordby > $new_lnk{ordby} AND id_data_category ='$new_lnk{id_data_category}'";
#         print $q;
        
        inserth_db($dbh,"data_lnk_sheets_categories",\%new_lnk);
        execstmt($dbh_data,$q);
    }
#     exit;
}

sub tree_categories_filter
{
  my $dbh = $_[0];
  my $id_data_category=get_quoted('id_data_category') || '';
  my $cat_list = get_categories_list($dbh,'','','',$id_data_category,'','select','',$colg);
  my $filter=<<"EOH";
   <div class="mig_search_filter">
   <p>
   <span>$migctrad{data_sheets_extra_filter}</span>
   <select name="extra_filter" id="extra_filter" class="mig_select">
            $cat_list
   </select>
   </p>
   </div>
   
   <script type="text/javascript">
      jQuery(document).ready(function() 
      {
        var id_data_family = jQuery('input[name="id_data_family"]').val();
        jQuery("#extra_filter").change(function()
        {
            window.location='$config{baseurl}/cgi-bin/adm_data_sheets.pl?colg=$colg&apercu_classement=&id_data_family='+id_data_family+'&id_data_category='+jQuery('#extra_filter').val();
        });
      })
    </script> 
EOH
  
  return $filter;
}

sub load_sheet_files
{
    my $id_data_sheet = get_quoted('id_data_sheet') || 0;
    my @pics=get_table($dbh,"data_lnk_sheet_files lnk","","id_data_sheet='$id_data_sheet' order by lnk.ordby");
    my $list='';
    my $nb_pics = $#pics+1;
    $list.=<<"EOH";
    <input type="hidden" name="id_data_sheet" value="$id_data_sheet" />
    <input type="hidden" name="nb_files" value="$nb_pics" />
    <table id="sortable_files">
  <thead>
  <tr>
       <th class="sheet_pictures_ext">
       Type
      </th>
      <th class="sheet_pictures_filename">
         Nom du fichier
      </th>
       <th class="sheet_pictures_name">
         Libellé
      </th>
      <th class="sheet_pictures_pochette"> 
         Pochette
     </th>
     <th class="sheet_pictures_visible"> 
          Visible ?
     </th>
      <th class="sheet_pictures_delete"> 
          Supprimer ?
     </th>
  </tr>
  </thead>
  <tbody class="content">
EOH
    my $num=0;
    
    
    foreach $pic(@pics)
    {
        my %pic=%{$pic};
        my ($name,$dum)=get_textcontent($dbh_data,$pic{id_textid_name},$colg);
        my $icon = "";
        $icon="$config{baseurl}/mig_skin/images/icon_".$pic{ext}.".png";
        my $checked_notice = "";
        my $checked_video = "";
        if($pic{video} eq 'y')
        {
           $checked_video = ' checked="checked" ';
        }
        if($pic{notice} eq 'y')
        {
           $checked_notice = ' checked="checked" ';
        }
       
        my $pochettes = '';
        if($pic{ext} eq 'flv' || $pic{ext} eq 'mp4'|| $pic{ext} eq 'mp3')
        {
            $pochettes = get_pics_choice($dbh,$id_data_sheet,$pic{id_pic_pochette},'gal_'.$num,$pic{id});
        }
    
    

       my $checked_visible = '';
       if($pic{visible} eq 'y')
       {
        $checked_visible = <<"EOH";
   checked="checked"      
EOH
       }
        
        my $class = 'line_a';
        if($num % 2 == 0)
        {
            $class = 'line_b';
        }
        
        $list .= <<"EOH";
   <tr id="$pic{id}" class="$class">
      <td class="sheet_pictures_ext">
      <a href="$config{baseurl}/pics/$pic{filename}" target="_blank"> <img src="$icon" alt="$pic{ext}" /> </a>
       <input type="hidden" name="lnk_$num" value="$pic{id}" />
      </td>      
      <td class="sheet_pictures_filename">
      <a href="$config{baseurl}/pics/$pic{filename}" target="_blank"> $pic{filename} </a>
      </td>
      <td class="sheet_pictures_name">
          <input type="text" value="$name" name="name_$num" />
          <div class="mig_trad"><a href="$config{baseurl}/cgi-bin/adm_translations.pl?lg=$colg&amp;sw=trad_win&amp;id=$pic{id_textid_name}&amp;simplerow=y" class="mig_trad mig_tooltip nyroModal" title="" target="_blank">$fwtrad{admin_trad}</a></div>
        
      </td>
      <td class="sheet_pictures_pochette" style=""> 
          $pochettes
     </td>
     <td class="sheet_pictures_visible"> 
          <input type="checkbox" $checked_visible name="visible_file_$num" value="$pic{id}" />
     </td>
     <td class="sheet_pictures_delete"> 
          <input type="checkbox" name="del_file_$num" value="$pic{id}" />
     </td>
    
   </tr>     
EOH
        $num++;     
    }
    $list .=<<"EOH";
   
   </tbody></table>
   <style>

	#sortable label { margin: 0 5px 5px 5px; padding: 5px; font-size: 1.2em; height: 1.5em; }
	html>body #sortable label { height: 60px; width:80px; display:block; float:left; }
	.ui-state-highlight { height: 60px; width:80px;  }
	</style>
	<script>
	
  jQuery(function() 
  {
  Cufon.replace('#sortable_files thead th', {
    hover: true,
    fontFamily: 'Bebas Neue'
});
		
    var id_data_sheet = jQuery('input[name="id"]').val(); 
    
    
       jQuery('.nyroModal').nyroModal
    (
    {
    sizes: {	
    initW: 990,	// Initial width
    initH: 600,	// Initial height
    w: 990,		// width
    h: 600,		// height
    minW: 990,	// minimum width
    minH: 600
  }
    
    
    
    
    }
    );
    
    jQuery( "#sortable_files .content" ).sortable({
			placeholder: "ui-state-highlight",
      containment: 'parent', 
      stop: function(event, ui) 
      { 
        var position = ui.item.index();
        var id_pic = ui.item.attr('id');
        jQuery.ajax(
          {
             type: "POST",
             url: "$config{baseurl}/cgi-bin/adm_data_sheets.pl",
             data: "sw=file_change_position&id_data_sheet="+id_data_sheet+"&id_pic="+id_pic+"&position="+position,
             success: function(msg)
             {
             }
          });
          

      }
		});
		//jQuery( "#sortable .content" ).disableSelection();
	});
	</script>
  
EOH
    
    
    print $list;
    exit;
}


 
sub stock_preview
{
    my $dbh = $_[0];
    my $id_data_sheet = $_[1];  
    my %data_sheet = sql_line({table=>"data_sheets",select=>'stock',where=>"id='$id_data_sheet'"});
    return $data_sheet{stock}; 
#     return data_get_stock({id_data_sheet=>$data_sheet{stock}});
#     my %simple_stock = select_table($dbh,"data_stock","id,stock","id_data_sheet = '$id_data_sheet'");
#     if($simple_stock{id} > 0)
#     {
#         return $simple_stock{stock};
#     }
#     else
#     {
#         my %crit_stock = select_table($dbh,
#         "data_lnk_stock_sheets_listvalues, data_stock s",
#         "sum(s.stock) as total",
#         "
#            id_lnk_sheet_listvalues 
#            IN
#            (
#               SELECT id 
#               FROM data_lnk_sheets_listvalues sl 
#               WHERE sl.id_data_sheet = '$id_data_sheet'
#            )
#            AND
#            id_data_stock = s.id 
#         "
#         );
#        if($crit_stock{total} >= 0)
#        {
#           return $crit_stock{total};
#        }
#        else
#        {
#           return "";
#        }
#     } 
}

################################################################################
# display_price
################################################################################
sub display_price
{
   my $value = $_[0];
   $value = sprintf("%.2f",$value);
   return '€&nbsp;'.$value;
}

sub price_preview
{
    my $dbh = $_[0];
    my $id_data_sheet = $_[1];
    my $list_prices = '';
    
    if($config{data_sheets_edit_prices} eq 'y')
    {
          my @prices = sql_lines({debug=>0,table=>'data_stock_tarif',select=>'id, id_tarif, st_pu_tvac, st_pu_htva',where=>"id_data_sheet='$id_data_sheet'",ordby=>'id_tarif,st_pu_htva'});
          foreach $price (@prices)
          {
              my %price = %{$price};
              $list_prices .= <<"EOH";
              <b>TARIF $price{id_tarif} :</b>
              <br><input type="text" name="st_pu_htva" id="$price{id}" class="ajax_save_price ajax_save_price_htva_$price{id}" value="$price{st_pu_htva}" /> HTVA
              <br><input type="text" name="st_pu_tvac" id="$price{id}" class="ajax_save_price ajax_save_price_tvac_$price{id}" value="$price{st_pu_tvac}" /> TVAC
              <br />
EOH
          }
    }
    else
    {
          my @prices = sql_lines({debug=>0,table=>'data_stock_tarif',select=>'id_tarif, st_pu_tvac, st_pu_htva',where=>"id_data_sheet='$id_data_sheet' AND st_pu_tvac > 0",ordby=>'id_tarif,st_pu_htva',groupby=>'id_tarif'});
          foreach $price (@prices)
          {
              my %price = %{$price};
              $price{st_pu_htva} = display_price($price{st_pu_htva});
              $price{st_pu_tvac} = display_price($price{st_pu_tvac});
              $list_prices .= '<b>TARIF'.$price{id_tarif}.':</b><br>'.$price{st_pu_htva}.'&nbsp;HTVA <br>'.$price{st_pu_tvac}.'&nbsp;TVAC<br />';
          }
    }
    return $list_prices;
}

sub cat_preview
{
    my $dbh = $_[0];
    my $id_data_sheet = $_[1];
    my $sheets="";
    my $list_cats="";
    my @cats_linked =get_table($dbh,"data_lnk_sheets_categories lnk","distinct(id_data_category) as id_data_category","id_data_sheet='$id_data_sheet'");
    foreach $cat_linked (@cats_linked)
    {
        my %cat = %{$cat_linked};
        $list_cats .= " $cat{id_data_category}, ";
    }
    $list_cats .= ' 0 ';
    
    my $id_data_family = get_quoted('id_data_family') || 1;
    my $list_cats_preview = get_categories_list($dbh,'','','','',$id_data_family,'this_list_cats_only',$list_cats,$colg);
    
    my $list_cats_change = get_categories_list($dbh,'','','','',$id_data_family,'select','',$colg);
    return "$list_cats_preview <br /><select name='add_category' class='add_category' id='$id_data_sheet'><option value=''>+</option>$list_cats_change</select>";
}

sub pic_preview
{
    my $dbh = $_[0];
    my $id_data_sheet = $_[1];
    my $sheets="";
    my $list_cats="";
    my %pic=select_table($dbh,"migcms_linked_files lnk","pic_name_mini","lnk.table_name = 'data_sheets' AND lnk.token='$id_data_sheet' order by lnk.ordby limit 0,1","","",0);
    my $pic = <<"EOH";
   <img src="$config{baseurl}/pics/$pic{pic_name_mini}" /> 
EOH
    if($pic{pic_name_mini} eq '')
    {
        return ''
    }
    else
    {
        return $pic;
    }
}


sub sauvegarde_adresse
{
    my $id_data_sheet=get_quoted('id_data_sheet') || "";
    my $lat=get_quoted('lat') || "";
    my $lon=get_quoted('lon') || "";
    
    $lat =~ s/\(//g;
    $lon =~ s/\)//g;
    
    $lat=trim($lat);
    $lon=trim($lon);
    
    my $field_lat=get_quoted('field_lat') || "";
    my $field_lon=get_quoted('field_lon') || "";
    see();
    
    if($id_data_sheet ne "" && $lat ne "" && $lon ne "" && $field_lat ne "" && $field_lon ne "")
    {
          my $stmt=<<"EOH";
            UPDATE `data_sheets` 
            SET   $field_lat = '$lat', 
                  $field_lon = '$lon'
            WHERE id='$id_data_sheet'
EOH
            my $cursor = $dbh->prepare($stmt);
            my $rc = $cursor->execute;
            if (!defined $rc) 
            {
                print "[$stmt]";
                exit;   
            }
            
    }
    print "ok";
}

sub toggle_checkbox
{
    my $table = get_quoted('table');
    my $id = get_quoted('id');
    my $col = get_quoted('col');
    my $string_dbh = get_quoted('dbh');
    
    if($string_dbh eq 'dbh2')
    {
        $dbh = $dbh2;
    }
    
    if($table ne '' && $id > 0 && $col ne '')
    {
        my %current_value = select_table($dbh,$table,"$col,id","id='$id'");
        if($current_value{$col} eq 'y')
        {
            my $stmt=<<"EOH";
            UPDATE `$table` 
            SET   $col = 'n' 
            WHERE id='$id'
EOH
            my $cursor = $dbh->prepare($stmt);
            my $rc = $cursor->execute;
            if (!defined $rc) 
            {
                print "[$stmt]";
                exit;   
            }
            print <<"EOH";
            <input type="checkbox" value="$id" name="$col" class="dm_autosave_cb" />
EOH
        }
        else
        {
            my $stmt=<<"EOH";
            UPDATE `$table` 
            SET   $col = 'y' 
            WHERE id='$id'
EOH
            my $cursor = $dbh->prepare($stmt);
            my $rc = $cursor->execute;
            if (!defined $rc) 
            {
                print "[$stmt]";
                exit;   
            }
            print <<"EOH";
            <input checked="checked" type="checkbox" value="$id" name="$col" class="dm_autosave_cb" />
EOH
        }    
    }
    else
    {
        print "id:[$id],table:[$table],col:[$col]";
    }
    exit;
}

sub ajax_data_categories_save_link
{
	see();
	my $id_data_sheet = get_quoted('id_data_sheet');
	my @data_categories = $cgi->param('id_data_categories[]');
	my %data_sheet = read_table($dbh,'data_sheets',$id_data_sheet);
	
	$stmt = "delete FROM data_lnk_sheets_categories WHERE id_data_sheet = ".$id_data_sheet;
    execstmt($dbh,$stmt);
	
	foreach my $id_data_category (@data_categories)
	{
		my %data_lnk_sheets_categories=();
		$data_lnk_sheets_categories{id_data_sheet} = $id_data_sheet;
		$data_lnk_sheets_categories{id_data_category} = $id_data_category;
		$data_lnk_sheets_categories{id_data_family} = $data_sheet{id_data_family};

		$stmt = "SELECT MAX(ordby)+1 FROM data_lnk_sheets_categories WHERE id_data_category = $id_data_category";
		$cursor = $dbh->prepare($stmt);
		$cursor->execute or suicide("error execute : $DBI::errstr [$stmt]\n");
		my ($ordbymax) = $cursor->fetchrow_array;
		if ($ordbymax eq "") { $ordbymax = 1;} 
		$data_lnk_sheets_categories{ordby} = $ordbymax;
		inserth_db($dbh_data,'data_lnk_sheets_categories',\%data_lnk_sheets_categories);
	}
	exit;
}

sub ajax_data_crits_save_link
{
	see();

	my @crit_listvalue_table=();
    #CREATE CRITS LINKS*********************************************************
    my $nb_crits = get_quoted('nb_crits') || 0;
	my $id_data_sheet = get_quoted('id_data_sheet');	
	
    for(my $i=0;$i<$nb_crits+1;$i++)
    {
		my $id_crit_listvalue = get_quoted('data_crit_'.$i) || 0;
        if($id_crit_listvalue > 0)
        {
            my %lnk=();
            if(!data_lnk_sheets_listvalues_exists($id_crit_listvalue,$id_data_sheet))
            {
                print 'existe pas: on ajoute';
 			    $lnk{id_crit_listvalue} = $id_crit_listvalue;
                $lnk{id_data_sheet} = $id_data_sheet;
				inserth_db($dbh,"data_lnk_sheets_listvalues",\%lnk);
            }
            push @crit_listvalue_table, $id_crit_listvalue;
        }
    }
    
	$vals_in = join(",",@crit_listvalue_table);
    if (1) 
    {
        my @stock_todel = ();
        my $where_vals_in = '';
		
		if($vals_in ne '')
		{
			$where_vals_in =" AND id_crit_listvalue NOT IN ($vals_in) ";
		}
		
		my @lsl_todel = sql_lines(
		{
			debug=>0,
			debug_results=>0,
			table=>"data_lnk_sheets_listvalues",
			select=>"id",
			where=>"id_data_sheet = '$id_data_sheet' $where_vals_in"
		});
		
        if ($#lsl_todel > -1) 
        {
            foreach $lsl_todel (@lsl_todel) 
            {
                push @stock_todel,$lsl_todel->{id};
            }
        
            $stmt = "DELETE FROM data_lnk_sheets_listvalues WHERE id_data_sheet = '$id_data_sheet' $where_vals_in";
            execstmt($dbh,$stmt);
        
            my $stock_todel = join(",",@stock_todel);

            $stmt = "DELETE FROM data_lnk_stock_sheets_listvalues WHERE id_lnk_sheet_listvalues IN ($stock_todel)";
            execstmt($dbh,$stmt);
        }
	}
	
	exit;
}
  
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------