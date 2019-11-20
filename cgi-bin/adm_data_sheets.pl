#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use data;
use migcrender;
use Geo::Coder::Google;
use setup;

my $id_data_family = get_quoted('id_data_family') || 1;

my $apercu_classement = $config{apercu_classement} || get_quoted('apercu_classement') || 'y';
$dm_cfg{enable_search} = 1;
$dm_cfg{autocreation} = 1;
$dm_cfg{excel} = 0;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort} = 1;
$dm_cfg{force_duplicate} = 0;

$dm_cfg{page_cms} = 1;
$dm_cfg{pic_url} = 1;
$dm_cfg{pic_alt} = 1;

$dm_cfg{wherep} = $dm_cfg{wherel} = $dm_cfg{wherep_ordby} = "id_data_family=$id_data_family";
$dm_cfg{table_name} = $dm_cfg{list_table_name} = "data_sheets";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_data_sheets.pl?id_data_family=$id_data_family";

$dm_cfg{after_add_ref}     = \&after_save;
$dm_cfg{after_mod_ref}     = \&after_save;
$dm_cfg{custom_filter_func}=\&tree_categories_filter;
$dm_cfg{after_upload_ref} = \&after_upload;

$dm_cfg{default_ordby} = "ordby asc";  
$dm_cfg{ordby_desc} = 1;  
$dm_cfg{trad} = 1;
my $default_tva_value = 21;
if($config{default_tva_value} ne '')
{
	$default_tva_value = $config{default_tva_value};
}

#fiches d'une catégorie
my $id_data_categories = get_quoted('id_data_categories') || '';
# if($id_data_categories ne '')
# {
	# $dm_cfg{sort} = 0;
# }


$sw = $cgi->param('sw') || "list";
%visibilite = 
(
	"y"=>"Visibles",
	"n"=>"Invisibles",
);

%dm_filters = (
"1/Visibles"=>
{
      'type'=>'hash',
	     'ref'=>\%visibilite,
	     'col'=>'visible'
}
);

see();
my %data_family = read_table($dbh,"data_families",$id_data_family);
$dm_cfg{page_title} = $data_family{name};
$dm_cfg{file_prefixe} = 'SHEETS';
if($config{force_file_prefixe_data_sheets} ne '')
{
	$dm_cfg{file_prefixe} = $config{force_file_prefixe_data_sheets};
}


#vérifie si le role gere les categories
$role_gere_categories = 0;
my %check = sql_line({table=>'data_families',where=>"show_categories LIKE '%,$user{id_role},%' AND id='$data_family{id}'"});
if($check{id} > 0 && $apercu_classement eq 'y')
{
	$role_gere_categories = 1;
}

#vérifie si le role gere les photos
$role_gere_photos = 0;
my %check = sql_line({debug=>0,debug_results=>0,table=>'data_families',where=>"show_pics LIKE '%,$user{id_role},%' AND id='$data_family{id}'"});
if($check{id} > 0)
{
	$role_gere_photos = 1;
}

#vérifie si le role gere les fichiers
$role_gere_fichiers = 0;
my %check = sql_line({debug=>0,debug_results=>0,table=>'data_families',where=>"show_files LIKE '%,$user{id_role},%' AND id='$data_family{id}'"});
if($check{id} > 0)
{
	$role_gere_fichiers = 1;
}

#vérifie si le role gere les stock/prix
$role_gere_prix = 0;
my %check = sql_line({debug=>0,debug_results=>0,table=>'data_families',where=>"show_stock LIKE '%,$user{id_role},%' AND id='$data_family{id}'"});
if($check{id} > 0)
{
	$role_gere_prix = 1;
}

#vérifie si le role gere le référencement
$role_gere_seo = 0;
my %check = sql_line({debug=>0,debug_results=>0,table=>'data_families',where=>"show_referencement LIKE '%,$user{id_role},%' AND id='$data_family{id}'"});
if($check{id} > 0)
{
	$role_gere_seo = 1;
}

#vérifie si le role gere les produits associés
$role_gere_related_products = 0;
my %check = sql_line({debug=>0,debug_results=>0,table=>'data_families',where=>"show_related_products LIKE '%,$user{id_role},%' AND id='$data_family{id}'"});
if($check{id} > 0)
{
	$role_gere_related_products = 1;
}

@dm_nav = get_dm_nav({
	role_gere_prix             => $role_gere_prix,
	role_gere_seo              => $role_gere_seo,
	role_gere_categories       => $role_gere_categories,
	role_gere_photos           => $role_gere_photos,
	role_gere_fichiers         => $role_gere_fichiers,
	role_gere_related_products => $role_gere_related_products,
	id_data_family             => $id_data_family,
});

%dm_dfl = %{get_dm_dfl({
	role_gere_prix             => $role_gere_prix,
	role_gere_seo              => $role_gere_seo,
	role_gere_categories       => $role_gere_categories,
	role_gere_photos           => $role_gere_photos,
	role_gere_fichiers         => $role_gere_fichiers,
	role_gere_related_products => $role_gere_related_products,
	id_data_family             => $id_data_family,
})};
%dm_display_fields = %{get_dm_display_fields({
	role_gere_prix             => $role_gere_prix,
	role_gere_seo              => $role_gere_seo,
	role_gere_categories       => $role_gere_categories,
	role_gere_photos           => $role_gere_photos,
	role_gere_fichiers         => $role_gere_fichiers,
	role_gere_related_products => $role_gere_related_products,
	id_data_family             => $id_data_family,
})};

if($role_gere_categories == 1)
{
	$dm_lnk_fields{"99/Catégories"} = "cat_preview*";
	$dm_mapping_list{cat_preview} = \&cat_preview;
}

my %code_shoeman = sql_line({table=>'migcms_codes',where=>"code='path_dirmacom'"});
if($code_shoeman{id} > 0)
{
	$dm_lnk_fields{"90/Shoeman"} = "shoeman*";
	$dm_mapping_list{shoeman} = \&shoeman;
}
if($role_gere_photos == 1)
{
	$dm_lnk_fields{"00/Photos"} = "pic_preview*";
	$dm_mapping_list{pic_preview} = \&pic_preview;
}

$dm_cfg{list_html_top} = <<"HTML";
  <link rel="stylesheet" href="//code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css">
  <link rel="stylesheet" href="/resources/demos/style.css">
	<script type="text/javascript"> 
	
	
	function ajout_nouvelle_ligne()
	{
		jQuery('.nouvelle_ligne.hide:first').removeClass('hide');
		return false;
	}
	
	function delete_stock_line()
	{
		var me = jQuery(this);
		me.parent().parent().find('select').val('');
		me.parent().parent().find('input').val('');
		me.parent().parent().hide();
		return false;
	}

	jQuery(document).ready(function() 
	{ 
		jQuery(document).on("click", ".ajout_nouvelle_ligne", ajout_nouvelle_ligne);
		jQuery(document).on("click", ".delete_stock_line", delete_stock_line);
	

		/*-------------- PRODUITS ASSOCIES ------------ */
	  var lg = "1";

	  // Suppression d'une liaison
	  jQuery(document).on("click", ".remove_assoc a", remove_assoc);

	  // Ajout d'une liaison
	  jQuery(document).on("keydown","#related_product_search", function(){  	
	  	var id_data_sheet = jQuery("input[name='id_data_sheet']").attr("value");

		  jQuery("#related_product_search").autocomplete(
		  {
		  	
		    source: "adm_data_sheets.pl?sw=get_autocomplete_data_sheets&id_data_family=$data_family{id}&lg="+lg,
		    select: function( event, ui ) 
		    {
		      // On associe la sheet récupérée à la fiche courante
		      jQuery.ajax(
		      {
		        type: "POST",
		        url: '$dm_cfg{self}',
		        data: {
		          id_data_sheet : id_data_sheet,
		          id_assoc_sheet : ui.item.id,
		          sw : "ajax_add_assoc_sheet",
		        },
		        dataType:"json",
		        success: function(response)
		        {
		          if(response.status == "ok")
		          {
		            // On met à jour le tableau des associations
		            update_related_product_table_content(id_data_sheet);
		          }
		          else if(response.status == "existing")
		          {
		            alert("Ce produit est déjà associé");
		          }
		          else
		          {              
		            alert("Une erreur est survenue lors de l'association avec un autre produit");
		          }
		          
		        }
		      });
		    },
		  });   
	  })
	});

  function remove_assoc(event)
  {
  	var id_data_sheet = jQuery("input[name='id_data_sheet']").attr("value");
    // var id_data_sheet = event.data.id_data_sheet;
    var id_assoc_sheet = jQuery(this).attr("id");
    var element = jQuery(this);

    jQuery(".se-pre-con").show();

    jQuery.ajax(
    {
      type: "POST",
      url: '$dm_cfg{self}',
      data: {
        id_data_sheet : id_data_sheet,
        id_assoc_sheet: id_assoc_sheet,
        sw : "ajax_remove_assoc_sheet",
      },
      dataType:"json",
      success: function(response)
      {
        if(response.status == "ok")
        {
        	jQuery(".se-pre-con").hide();
          // On met à jour le tableau des associations
          update_related_product_table_content(id_data_sheet);

        }
        
      }
    });

    event.preventDefault();
  }

  function update_related_product_table_content()
  {
  	var id_data_sheet = jQuery("input[name='id_data_sheet']").attr("value");
    // On vide le tableau
    jQuery(".se-pre-con").show();

    // On associe la sheet récupérée à la fiche courante
    jQuery.ajax(
    {
      type: "POST",
      url: '$dm_cfg{self}',
      data: {
        id_data_sheet : id_data_sheet,
        ajax_call : "y",
        sw : "ajax_get_assoc_sheets",
      },
      dataType:"json",
      success: function(response)
      {
        var content = response.content;
        jQuery("#related_product_table_content").empty().append(content);
        jQuery(".se-pre-con").hide();
        
      }
    });
	}

	
	</script>
HTML

my @fcts = qw(
			list
			get_autocomplete_data_sheets
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}

sub get_dm_dfl
{
	my %d = %{$_[0]};
	my %new_dm_dfl;
	
	my @data_fields = sql_lines({table=>'data_fields',where=>"id_data_family='$d{id_data_family}' AND visible='y'",ordby=>"ordby"});
	foreach $data_field (@data_fields)
	{
		my %data_field = %{$data_field};
		
		my $title = get_traduction({debug=>0,id_language=>$d{colg},id=>$data_field{id_textid_name}});
		my $legend = '';
		if($data_field{in_meta_title} eq 'y' || $data_field{in_meta_description} eq 'y')
		{
			# $legend = 'Egalement utilisé pour le référencement naturel';
		}
		if($data_field{in_meta_title} eq 'y' && $data_field{in_meta_description} eq 'y')
		{
			# $legend .= ' (Titre, url et description)';
		}
		elsif($data_field{in_meta_title} eq 'y')
		{
			# $legend .= ' (Titre et url)';
		}
		elsif($data_field{in_meta_description} eq 'y')
		{
			# $legend .= ' (Description)';
		}
		my $mandatory = '';
		if($data_field{mandatory} eq 'y')
		{
			$mandatory='not_empty';
		}
		my $multiple = '';
		if($data_field{multiple} eq 'y')
		{
			$multiple = 1;
		}
		my $hidden = '';
		if($data_field{hidden} eq 'y')
		{
			$hidden = 1;
		}
		my $translate = '';
		if($data_field{lbdisplay} =~ /textid/)
		{
			$translate = 1;
		}
		$new_dm_dfl{sprintf("%.02d",$data_field{ordby}).'/f'.$data_field{ordby}} = 
		{
			'title'=> $title,
	        'fieldtype'=>$data_field{field_type},
	        'legend'=> $legend,
	        'data_type'=>$data_field{data_type},
	        'btn_style'=>$data_field{btn_style},
	        'search' => $data_field{searchable},
	        'tab' => 'tab_'.lc($data_field{field_tab}),
			'lbtable'=>$data_field{lbtable},
			'lbkey'=>$data_field{lbkey},
			'lbdisplay'=>$data_field{lbdisplay},
			'translate'=>$translate,
			'multiple'=> $multiple,
			'hidden'=> $hidden,		
			'lbwhere'=>$data_field{lbwhere},
			'lbordby'=>$data_field{lbordby},
			'default_value'=>$data_field{default_value},
	        'mandatory'=>{"type" => $mandatory},
		};
	}
	
	$new_dm_dfl{'90/id_data_family'} = 
	{
		'title'=> 'Famille',
		'fieldtype'=> 'text',
		'search' => 'n',
		'tab' => 'tab_fiche',
		'hidden' => 1,
	};
	
	if($data_family{profil} eq 'products')
	{
		$new_dm_dfl{'75/taux_tva'} = 
		{
			'title'=> 'TVA',
			'fieldtype'=>'listboxtable',
			'lbtable'=>'eshop_tvas',
			'tab' => 'tab_fiche',
			'hidden' => 0,
			'lbkey'=>'id',
			'lbdisplay'=>"tva_reference",
			'default_value'=>$default_tva_value,
		};
	}
	
	
	
	
	if($d{role_gere_categories} == 1)
	{
		$new_dm_dfl{'90/id_data_categories'} = 
		{
			'title'=> 'Catégories',
			'fieldtype'=>'listboxtable',
			'lbtable'=>'data_categories',
			translate=>1,
			'data_type'=>'treeview',
			'lbkey'=>'id',
			'lbdisplay'=>"id_textid_name",
			'lbwhere'=>"migcms_deleted != 'y' AND id_data_family='$d{id_data_family}' AND id NOT IN (select id_record from migcms_valides where nom_table='data_categories')" ,
			'tree_col'=>'id_father',
			'search' => 'n',
			'tab'=>'tab_categories'
		};
	}
	
	if($d{role_gere_photos} == 1)
	{
		$new_dm_dfl{'80/photos'} = 
		{
			'title'=> 'Ajouter des photos',
			'tip'=>"<b>Cliquez</b> pour parcourir ou <b>déposez</b> vos fichiers <u>dans ce cadre</u>",
			'fieldtype'=>'files_admin',
			'disable_add'=>1,
			'tab'=>'tab_photos',
			'msg'=>'Cliquez ici pour parcourir votre ordinateur ou déposez directement des fichiers dans ce cadre.',

		};
	}
	
	if($d{role_gere_fichiers} == 1)
	{
		$new_dm_dfl{'81/fichiers'} = 
		{
			'title'=> 'Ajouter des fichiers',
						'tip'=>"<b>Cliquez</b> pour parcourir ou <b>déposez</b> vos fichiers <u>dans ce cadre</u>",

			'fieldtype'=>'files_admin',
			'disable_add'=>1,
			'tab'=>'tab_photos',
						'msg'=>'Cliquez ici pour parcourir votre ordinateur ou déposez directement des fichiers dans ce cadre.',
		};
	}

	if($d{role_gere_seo} == 1)
	{
		$new_dm_dfl{'001/id_textid_url_rewriting'} = 
		{
			'title'=> 'URL',
			'fieldtype'=>'text_id',
			'disable_add'=>0,
			'tab'=>'tab_seo',
			'msg'=>'',

		};

		$new_dm_dfl{'002/id_textid_meta_title'} = 
		{
			'title'=> 'Titre',
			'fieldtype'=>'text_id',
			'disable_add'=>0,
			'tab'=>'tab_seo',
			'msg'=>'Max: 80 caractères',

		};

		$new_dm_dfl{'003/id_textid_meta_description'} = 
		{
			'title'=> 'Description',
			'tip' => 'Max: 200 caractères',
			'fieldtype'=>'textarea_id',
			'disable_add'=>0,
			'tab'=>'tab_seo',
			'msg'=>'Max: 200 caractères',

		};
	}

	# if($d{role_gere_related_products} == 1)
	# {
	# 	$new_dm_dfl{'400/f70'} = 
	# 	{
	# 		'title'=>'Rechercher un produit à associer',
	# 		'translate'=>0,
	# 		'fieldtype'=>'text',
	# 		'data_type'=>'autocomplete',
	# 		'search' => 'n',
	# 		'mandatory'=>{"type" => ''},
	# 		'tab'=>'tab_related_products',
	# 		'lbtable'=>'data_sheet',
	# 		'lbkey'=>'id',
	# 		'lbdisplay'=>'CTMDENOMINATION',
	# 		'lbwhere'=>"",
	# 		'lbordby'=>"CTMDENOMINATION",
	# 		'fieldvalues'=>'',
	# 		'hidden'=>0,
	# 	};


	# 	$new_dm_dfl{'405/tableau_produits_associes'} = 
	# 	{
	# 		'title'=>'Produits associés',
	# 		'fieldtype'=>'titre',
	# 		'data_type'=>'',
	# 		'tab'=>'tab_related_products',
	# 	};
	# }
	
	return \%new_dm_dfl;
}

sub get_dm_display_fields
{
	my %d = %{$_[0]};
	my %new_dm_display_fields;

	
	my @data_fields = sql_lines({table=>'data_fields',where=>"id_data_family='$d{id_data_family}' AND visible='y' AND in_list='y'",ordby=>"ordby"});
	foreach $data_field (@data_fields)
	{
		my %data_field = %{$data_field};
		
		my $title = get_traduction({debug=>0,id_language=>$d{colg},id=>$data_field{id_textid_name}});
		
		$new_dm_display_fields{sprintf("%.02d",$data_field{ordby}).'/'.$title} = 'f'.$data_field{ordby};
	}
	
	if($d{role_gere_prix} == 1)
	{
		$new_dm_display_fields{'99/TVA'} = 'taux_tva';
	}
	
	return \%new_dm_display_fields;

}

sub get_dm_nav
{
	my %d = %{$_[0]};
	my %new_dm_display_fields;
	my @new_dm_nav = ();
	my @data_fields = sql_lines({select=>"distinct(field_tab) as field_tab",table=>'data_fields',where=>"id_data_family='$d{id_data_family}' AND visible='y'",ordby=>"ordby"});
	foreach $data_field (@data_fields)
	{
		my %data_field = %{$data_field};
		if($data_field{field_tab} eq 'seo'|| $data_field{field_tab} eq 'categories'|| $data_field{field_tab} eq 'photos'|| $data_field{field_tab} eq 'fichiers'|| $data_field{field_tab} eq 'prix')
		{
			next;
		}
		
		my %hash = 
		(
			'tab'=>'tab_'.lc($data_field{field_tab}),
			'type'=>'tab',
			'title'=>$data_field{field_tab},
		);
		push @new_dm_nav, \%hash;
	}
	
	#le role gere les categories 
	if($d{role_gere_categories} == 1)
	{
		my %hash = 
		(
			'tab'=>'tab_categories',
			'type'=>'tab',
			'title'=>'Catégories',
		);
		push @new_dm_nav, \%hash;
	}
	
	#le role gere les photos 
	if($d{role_gere_photos} == 1 || $d{role_gere_fichiers} == 1)
	{
		my %hash = 
		(
			'tab'=>'tab_photos',
			'type'=>'tab',
			'title'=>'Photos, fichiers',
		);
		push @new_dm_nav, \%hash;
	}
	
	#le role gere les prix
	if($d{role_gere_prix} == 1)
	{
		my %hash = 
		(
			'tab'=>'tab_prix',
			'type'=>'cgi_func',
			'cgi_func'=>\&ecran_prix,
			'title'=>'Prix, stock',
		);
		push @new_dm_nav, \%hash;
	}

	#le role gere le Référencement
	if($d{role_gere_seo} == 1)
	{
		my %hash = 
		(
			'tab'=>'tab_seo',
			'type'=>'tab',
			'title'=>$migctrad{families_show_referencement},
		);
		push @new_dm_nav, \%hash;
	}

	#le role gere le Référencement
	if($d{role_gere_related_products} == 1)
	{
		my %hash = 
		(
			'tab'=>'tab_related_products',
			'type'=>'tab',
			'title'=>$migctrad{families_show_related_products},
			'cgi_func'=>\&ecran_related_products,
		);
		push @new_dm_nav, \%hash;
	}
	
	return @new_dm_nav;
}

sub ecran_related_products
{
	my $dbh = $_[0];
  my $id = $_[1];

  # my %data_sheet = sql_line({table=>'data_sheets',where=>"id='$id'"});
  
  my $related_products = ajax_get_assoc_sheets({id_data_sheet=> $id});


  my $page = <<"HTML";
		<div class="row $config{class_admin_ecran_prix}">
			<div class="form-group">
				<label class="control-label col-sm-2">Rechercher un produit à ajouter :</label>
				<div class="col-sm-10">
					<input name="id_data_sheet" value="$id" type="hidden">
				 <input id="related_product_search" type="text" class="form-control">
				</div>
			</div>
		
			<div id="related_product_table_content">
				$related_products
			</div>

      

    </div>

HTML

	return $page;
}

sub ecran_prix
{
    my $dbh = $_[0];
    my $id = $_[1];
	
	my %data_sheet = sql_line({table=>'data_sheets',where=>"id='$id'"});
	my @data_stock = sql_lines({table=>'data_stock',where=>"id_data_sheet='$id'",ordby=>'id'});
	my @eshop_tarifs = sql_lines({table=>'eshop_tarifs',where=>"visible='y'",ordby=>'id'});
	my @eshop_tvas = sql_lines({table=>'eshop_tvas',where=>"",ordby=>'id'});
	
	$page .= <<"EOH";
		<div class="row $config{class_admin_ecran_prix}">
			<div class="col-md-3">
				Variante
			</div>
			<div class="col-md-2">
				Référence
			</div>
			<div class="col-md-1">
				Poids
			</div>
			<div class="col-md-1">
				Stock
			</div>
			<div class="col-md-2">
				Tarif
			</div>
			<div class="col-md-1">
				€ HTVA
			</div>
			<div class="col-md-1">
				€ TVAC
			</div>
			<div class="col-md-1">
				Effacer
			</div>
		</div>
		<hr />
EOH
	
	
	my $current_id_data_stock = 0;
	
	foreach $data_stock (@data_stock)
	{
		my %data_stock = %{$data_stock};
		$page .=<<"EOH";
EOH
			foreach $eshop_tarif (@eshop_tarifs)
			{
				my %eshop_tarif = %{$eshop_tarif};
				
				
				my %data_stock_tarif = sql_line({table=>'data_stock_tarif',where=>"id_data_stock='$data_stock{id}' AND id_tarif='$eshop_tarif{id}' "});
				
				my $ref = <<"EOH";
					<input type="text" class="form-control saveme" value="$data_stock{reference}" name="reference_$data_stock{id}" />
EOH
				my $weight = <<"EOH";
					<input type="text" class="form-control saveme" value="$data_stock{weight}"  name="weight_$data_stock{id}" />
EOH
				my $stock = <<"EOH";
					<input type="text" class="form-control saveme" value="$data_stock{stock}"  name="stock_$data_stock{id}" />
EOH
				my $variantes = get_sql_listbox({with_blank=>'y',selected_id=>$data_stock{id_data_category},col_display=>"fusion",table=>"data_categories",where=>"variante='y'",ordby=>"fusion",name=>'data_category_'.$data_stock{id},class=>"saveme form-control data_category_$data_stock{id}"});

				
				if($data_stock{id} == $current_id_data_stock)
				{
					$ref = $stock = $weight = $variantes = '';
				}
				$current_id_data_stock = $data_stock{id};

				my $encodage_tvac = "disabled = disabled";
				my $encodage_htva;
				if($config{encodage_tvac} eq "y")
				{
					$encodage_tvac = "";
					$encodage_htva = "disabled = disabled";
				}
				
				
				$page .=<<"EOH";
					<div class="row  $config{class_admin_ecran_prix}" >
						<div class="col-md-3">
						$variantes
						</div>
						<div class="col-md-2">
						$ref	
						</div>
						<div class="col-md-1">
						$weight
						</div>
						<div class="col-md-1">
						$stock	
						</div>
						<div class="col-md-2">
							<b>$eshop_tarif{name}:</b>
						</div>
						<div class="col-md-1">
							<input type="text" value="$data_stock_tarif{st_pu_htva}" $encodage_htva class="form-control saveme" name="htva_$data_stock{id}_$eshop_tarif{id}" />
						</div>
						<div class="col-md-1">
							<input type="text" value="$data_stock_tarif{st_pu_tvac}" $encodage_tvac class="form-control saveme" name="tvac_$data_stock{id}_$eshop_tarif{id}" />
						</div>
						<div class="col-md-1">
							<a href="#" data-placement="bottom" data-original-title="Supprimer " id="" role="button" class="btn btn-danger delete_stock_line"><i class="fa fa-trash fa-fw" data-original-title="" title=""></i></a>
						</div>
					</div>
EOH
			}
	}
	

	$current_id_data_stock = '';
	foreach my $nouvelle_ligne (1 .. 20)
	{
		
		$page .=<<"EOH";
EOH
			foreach $eshop_tarif (@eshop_tarifs)
			{
				my %eshop_tarif = %{$eshop_tarif};
				
				
				my %data_stock_tarif = sql_line({table=>'data_stock_tarif',where=>"id_data_stock='$data_stock{id}' AND id_tarif='$eshop_tarif{id}' "});
				
				my $ref = <<"EOH";
					<input type="text" class="form-control saveme" value="" name="reference_nouvelle_$nouvelle_ligne" />
EOH
				my $weight = <<"EOH";
					<input type="text" class="form-control saveme" value=""  name="weight_nouvelle_$nouvelle_ligne" />
EOH
				my $stock = <<"EOH";
					<input type="text" class="form-control saveme" value=""  name="stock_nouvelle_$nouvelle_ligne" />
EOH
				my $nouvelles_variantes = get_sql_listbox({with_blank=>'y',selected_id=>$data_stock{id_data_category},col_display=>"fusion",table=>"data_categories",where=>"variante='y'",ordby=>"fusion",name=>'data_category_nouvelle_'.$nouvelle_ligne,class=>"saveme form-control data_category_nouvelle_$nouvelle_ligne"});

				if($nouvelle_ligne == $current_id_data_stock)
				{
					$ref = $stock = $weight = $nouvelles_variantes = '';
				}
				$current_id_data_stock = $nouvelle_ligne;

				my $encodage_tvac = "disabled = disabled";
				my $encodage_htva;
				if($config{encodage_tvac} eq "y")
				{
					$encodage_tvac = "";
					$encodage_htva = "disabled = disabled";
				}
				
				my $col_htva = 'htva_nouvelle_'.$nouvelle_ligne.'_'.$eshop_tarif{id};
				my $col_tvac = 'tvac_nouvelle_'.$nouvelle_ligne.'_'.$eshop_tarif{id};
				
				$page .=<<"EOH";
					<div class="row nouvelle_ligne hide $config{class_admin_ecran_prix}" >
						<div class="col-md-3">
						$nouvelles_variantes
						</div>
						<div class="col-md-2">
						$ref	
						</div>
						<div class="col-md-1">
						$weight
						</div>
						<div class="col-md-1">
						$stock	
						</div>
						<div class="col-md-2">
							<b>$eshop_tarif{name}:</b>
						</div>
						<div class="col-md-1">
							<input type="text" value="" $encodage_htva class="form-control saveme" name="$col_htva" />
						</div>
						<div class="col-md-1">
							<input type="text" value="" $encodage_tvac class="form-control saveme" name="$col_tvac" />
						</div>
						<div class="col-md-1">
						<a href="#" data-placement="bottom" data-original-title="Supprimer " id="" role="button" class="btn btn-danger delete_stock_line"><i class="fa fa-trash fa-fw" data-original-title="" title=""></i></a>						</div>
					</div>
EOH
			}	
	}
	
	$page .=<<"EOH";
	<br /><br />
	<a class="btn btn-info ajout_nouvelle_ligne">Ajouter une variante</a>
EOH
	return $page;
}

sub after_save
{
    my $dbh = $_[0];
    my $id = $_[1];
    my $lg = $_[2];
    my %data_sheet = read_table($dbh,"data_sheets",$id);
	log_debug('after_save','vide','after_save_sheet');
	log_debug('sheet:'.$data_sheet{id},'','after_save_sheet');
	
	#compléter l'id data family
	$data_sheet{id_data_family} = fill_id_data_family({data_sheet=>\%data_sheet,id_data_family=>$id_data_family});
	my %family = sql_line({table=>'data_families',where=>"id='$data_sheet{id_data_family} '"});
	log_debug('fill_id_data_family:'.$id_data_family,'','after_save_sheet');
	
	#liaisons aux catégories
	link_categories({id_data_sheet=>$data_sheet{id},id_data_family=>$data_sheet{id_data_family},id_data_categories=>$data_sheet{id_data_categories}});
	log_debug('link_categories:'.$data_sheet{id_data_categories},'','after_save_sheet');

	#reset fusion
	# $stmt = "UPDATE data_sheets SET fusion = '' ";
	# $cursor = $dbh->prepare($stmt);
	# $cursor->execute || suicide($stmt);	

	#gps geolocator
	if($family{profil} eq 'shoplocator')
    {                          
       after_save_shoplocator($id);	 
	}
	elsif($family{profil} eq 'products')
	{
		#calcule la fusion produit
		my %eshop_setup = sql_line({table=>"eshop_setup"});
		my $detail_label = '';
		my @data_sheets_fusions = sql_lines({debug=>0,debug_results=>0,table=>'data_sheets',where=>"fusion = '' AND id_data_family='$family{id}'"});
		foreach $data_sheet_fusion(@data_sheets_fusions)
		{
			my %data_sheet_fusion = %{$data_sheet_fusion};
			$detail_label = sprintf("%08d", $data_sheet_fusion{id});
			$detail_label .= ' '.$data_sheet_fusion{f1}.' ';
			foreach my $num_label (1 .. 5)
			{
				if($eshop_setup{'id_data_field_name'.$num_label} > 0)
				{
					my %data_field = read_table($dbh,"data_fields",$eshop_setup{'id_data_field_name'.$num_label});				
					if($data_field{field_type} eq 'text_id')
					{
						my $traduction = get_traduction({debug=>0,id_language=>1,id=>$data_sheet_fusion{'f'.$data_field{ordby}}});
						$detail_label .= "$traduction ";
					}
					else
					{
						$detail_label .= $data_sheet_fusion{'f'.$data_field{ordby}}.' ';
					}
				}
			}
			$detail_label =~ s/\'/\\\'/g;
			if(trim($detail_label) ne '')
			{
				$stmt = "UPDATE data_sheets SET fusion = '$detail_label' WHERE id = '$data_sheet_fusion{id}'";
				log_debug($stmt,'','after_save_sheet');		
				$cursor = $dbh->prepare($stmt);
				$cursor->execute || suicide($stmt);	
			}
		}
	}
	
	#Sauver les prix/stock
	save_stock_prix(\%data_sheet); 
	log_debug('save_stock_prix','','after_save_sheet');

	#infos de recherche
	migcms_build_data_searchs_keyword({id_data_sheet=>$data_sheet{id}});
	log_debug('migcms_build_data_searchs_keyword','','after_save_sheet');
	
	#référencement
	fill_seo(\%data_sheet,$lg);
	# log_debug('fill_seo','','after_save_sheet');
	
	if($family{func_after_save} ne '')
    {                          
       	my $func = 'def_handmade::'.$family{func_after_save};
		log_debug('func:'.$func,'','after_save_sheet');
		&$func({data_sheet=>\%data_sheet,data_family=>\%family});
	}
	
	#redimensionnement des photos (appliqué lors de l'upload)
	if($config{data_sheet_resize_sheet_pics_after_save} eq 'y')
	{
		resize_sheet_pics({id_data_family=>$data_sheet{id_data_family},id_data_sheet=>$data_sheet{id}});
	}

	use File::Path qw(remove_tree rmtree);
	remove_tree( '../cache/site/data', {keep_root => 1} );
	
	log_debug('fin after_save','','after_save_sheet');
}

sub fill_all_seo
{
	see();
	my @data_sheets = sql_lines({table=>'data_sheets'});
	foreach $data_sheet (@data_sheets)
	{
		my %data_sheet = %{$data_sheet};
		fill_seo(\%data_sheet);
	}
	exit;
}

sub fill_seo
{
	my %data_sheet = %{$_[0]};
	
	my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"visible = 'y' || encode_ok = 'y'",ordby=>"id"});
	my @data_fields = sql_lines({table=>'data_fields',where=>"id_data_family='$data_sheet{id_data_family}'"});

    foreach $language (@languages)
    {
        my %language = %{$language};
		my $id_textid_meta_title = "";
		my $id_textid_meta_description = "";
		my $id_textid_url_rewriting = "";
		
		#recopie les champs cochés dans les colonnes title,descr,url
		foreach $data_field (@data_fields)
		{
			my %data_field = %{$data_field};
			my $valeur = $data_sheet{'f'.$data_field{ordby}};
			if($data_field{field_type} eq 'text_id' || $data_field{field_type} eq 'textarea_id' || $data_field{field_type} eq 'textarea_id_editor')
			{
				my $traduction = get_traduction({debug=>0,id_language=>$language{id},id=>$data_sheet{'f'.$data_field{ordby}}});
				$valeur = $traduction;
			}

			if($data_field{in_meta_title} eq 'y')
			{
				$id_textid_meta_title .= $valeur.' ';
				$id_textid_url_rewriting .= $valeur.' ';
			}
			
			if($data_field{in_meta_description} eq 'y')
			{
				$id_textid_meta_description .= $valeur.' ';
			}
			
		}

		# On ajoute le nom du site à la fin
		$id_textid_meta_title .= "- $balises{seo_site_name}";

		# On met les 1ères lettres de chaque mot en majuscule
		$id_textid_meta_title = lc($id_textid_meta_title);
    $id_textid_meta_title =~ s/\b(\w)/\U$1/g;

		
		my $traduction_id_textid_meta_title = get_traduction({debug=>0,id_language=>$language{id},id=>$data_sheet{id_textid_meta_title}});
		if($traduction_id_textid_meta_title eq '')
		{
			set_traduction({id_language=>$language{id},traduction=>$id_textid_meta_title,id_traduction=>$data_sheet{id_textid_meta_title},table_record=>'data_sheets',col_record=>'id_textid_meta_title',id_record=>$data_sheet{id}});
		}
				
		my $traduction_id_textid_meta_description = get_traduction({debug=>0,id_language=>$language{id},id=>$data_sheet{id_textid_meta_description}});
		if($traduction_id_textid_meta_description eq '')
		{
			set_traduction({id_language=>$language{id},traduction=>$id_textid_meta_description,id_traduction=>$data_sheet{id_textid_meta_description},table_record=>'data_sheets',col_record=>'id_textid_meta_description',id_record=>$data_sheet{id}});
		}
		
		my $traduction_id_textid_url_rewriting = get_traduction({debug=>0,id_language=>$language{id},id=>$data_sheet{id_textid_url_rewriting}});
		if($traduction_id_textid_url_rewriting eq '')
		{
			set_traduction({id_language=>$language{id},traduction=>clean_url($id_textid_url_rewriting),id_traduction=>$data_sheet{id_textid_url_rewriting},table_record=>'data_sheets',col_record=>'id_textid_url_rewriting',id_record=>$data_sheet{id}});
		}
		
		my @migcms_linked_files = sql_lines({table=>'migcms_linked_files',where=>"table_name='data_sheets' AND token='$data_sheet{id}'"});
		foreach $migcms_linked_file (@migcms_linked_files)
		{
			my %migcms_linked_file = %{$migcms_linked_file};
			my $traduction_id_textid_legend = get_traduction({debug=>0,id_language=>$language{id},id=>$migcms_linked_file{id_textid_legend}});
			if($traduction_id_textid_legend eq '')
			{
				set_traduction({id_language=>$language{id},traduction=>$id_textid_meta_title,id_traduction=>$migcms_linked_file{id_textid_legend},table_record=>'migcms_linked_files',col_record=>'id_textid_legend',id_record=>$migcms_linked_file{id}});
			}
		}
	}
}

sub fill_stock_prix_DESACTIVE
{
	my %data_sheet = %{$_[0]};

	#cas sans variante uniquement: vérifier qu'un stocke existe et un tarif de chaque
	my %update_stock = 
	(
		id_data_sheet => $data_sheet{id},
		reference => 'SKU'.$data_sheet{id},
	);
	
	my %check_data_stock = sql_line({table=>'data_stock',where=>"id_data_sheet='$data_sheet{id}'"});
	if($check_data_stock{id} > 0)
	{
		#stock existe
	}
	else
	{
		$check_data_stock{id} = inserth_db($dbh,'data_stock',\%update_stock);
	}
	
	my @eshop_tarifs = sql_lines({table=>'eshop_tarifs',where=>"visible='y'"});
	foreach $eshop_tarif(@eshop_tarifs)
	{
		my %eshop_tarif = %{$eshop_tarif};
		
		my %update_stock_tarif = 
		(
			id_data_sheet => $data_sheet{id},
			id_data_stock => $check_data_stock{id},
			id_tarif => $eshop_tarif{id},
		);
		
		my %check_data_stock_tarif = sql_line({table=>'data_stock_tarif',where=>"id_data_stock='$check_data_stock{id}' AND id_tarif='$eshop_tarif{id}'"});
		if($check_data_stock_tarif{id} > 0)
		{
			#stock tarif existe
		}
		else
		{
			$check_data_stock_tarif{id} = inserth_db($dbh,'data_stock_tarif',\%update_stock_tarif);
		}
	}
}

sub save_stock_prix
{
	log_debug('','vide','save_stock_prix');
	
	my %data_sheet = %{$_[0]};
	my %eshop_tva = read_table($dbh,'eshop_tvas',$data_sheet{taux_tva});
	
	log_debug("Sheet $data_sheet{id}",'','save_stock_prix');

	#verifier s'il ya au moins un data_stock et un data_stock_tarif par tarif
	my $creation = 0;
	
	#data_stock
	my %update_stock = 
	(
		id_data_sheet => $data_sheet{id},
	);
	my %check_data_stock = sql_line({table=>'data_stock',where=>"id_data_sheet='$data_sheet{id}'"});
	if(!($check_data_stock{id} > 0))
	{
		$check_data_stock{id} = inserth_db($dbh,'data_stock',\%update_stock);
		log_debug("Nouveau stock initial: $check_data_stock{id}",'','save_stock_prix');
		$stmt = "UPDATE data_stock SET reference = CONCAT('REF',id) WHERE id = '$check_data_stock{id}'";
		$cursor = $dbh->prepare($stmt);
		$cursor->execute || suicide($stmt);	
		$creation = 1;
	}
	
	#data_stock_tarif
	my @eshop_tarifs = sql_lines({table=>'eshop_tarifs',where=>"visible='y'"});
	foreach $eshop_tarif(@eshop_tarifs)
	{
		my %eshop_tarif = %{$eshop_tarif};
		
		my %update_stock_tarif = 
		(
			id_data_sheet => $data_sheet{id},
			id_data_stock => $check_data_stock{id},
			id_tarif => $eshop_tarif{id},
		);
		
		my %check_data_stock_tarif = sql_line({table=>'data_stock_tarif',where=>"id_data_stock='$check_data_stock{id}' AND id_tarif='$eshop_tarif{id}'"});
		if(!($check_data_stock_tarif{id} > 0))
		{
			$check_data_stock_tarif{id} = inserth_db($dbh,'data_stock_tarif',\%update_stock_tarif);
			log_debug("Nouveau stock tarif initial: $check_data_stock_tarif{id}",'','save_stock_prix');

		}
	}	
	
	if($creation == 1)
	{
		log_debug("Fin ajout initial",'','save_stock_prix');
		return ''; #cas de l'ajout: on a ajouté un stock et des tarifs.
	}
	
	#sauvegarde	#stocks existants
	log_debug("sauvegarde	#stocks existants",'','save_stock_prix');
	
	#marquer les stocks pour supprimer les stocks inutiles
	$stmt = "UPDATE data_stock SET todel = 1 WHERE id_data_sheet = '$data_sheet{id}' ";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt);	

	my @data_stocks = sql_lines({table=>'data_stock',where=>"id_data_sheet='$data_sheet{id}'"});
	foreach $data_stock (@data_stocks)
	{
		my %data_stock = %{$data_stock};
		my $reference = get_quoted('reference_'.$data_stock{id});
		
		my $todel = 1;
		
		if($reference eq '')
		{
			$reference = 'REF'.$data_stock{id};
		}	
		else
		{
			$todel = 0;
		}
		
		my $id_data_category = get_quoted('data_category_'.$data_stock{id});
		my $stock = get_quoted('stock_'.$data_stock{id});
		my $weight = get_quoted('weight_'.$data_stock{id});
		if($stock ne '' || $weight ne ''|| $id_data_category ne '')
		{
			$todel = 0;		
		}
		
		#update stock
		my %update_data_stock = 
		(
			id_data_category => $id_data_category,
			reference => $reference,
			stock => $stock,
			weight => $weight,
			id_eshop_tva => $eshop_tva{id},
		);
		updateh_db($dbh,"data_stock",\%update_data_stock,"id",$data_stock{id});
		log_debug("Maj stock $data_stock{id}",'','save_stock_prix');
		
		#update stock tarifs
		my @eshop_tarifs = sql_lines({table=>'eshop_tarifs',where=>"visible='y'"});
		foreach $eshop_tarif(@eshop_tarifs)
		{
			my %eshop_tarif = %{$eshop_tarif};
			
			my %data_stock_tarif = sql_line({table=>'data_stock_tarif',where=>"id_data_stock='$data_stock{id}' AND id_tarif='$eshop_tarif{id}'"});
			
			my %update_data_stock_tarif = 
			(
				taux_tva => $eshop_tva{tva_value},
			);
			
			my $tvac = get_quoted('tvac_'.$data_stock{id}.'_'.$eshop_tarif{id});
			my $htva = get_quoted('htva_'.$data_stock{id}.'_'.$eshop_tarif{id});
			if($tvac ne '' || $htva ne '')
			{
				$todel = 0;		
			}
			
			if($config{encodage_tvac} eq "y")
			{
				#encodagage des prix TVAC
				$update_data_stock_tarif{st_pu_tvac} = $tvac;
				$update_data_stock_tarif{st_pu_htva} = $update_data_stock_tarif{st_pu_tvac} / (1 + $eshop_tva{tva_value});
				$update_data_stock_tarif{st_pu_tva} = $update_data_stock_tarif{st_pu_tvac} - $update_data_stock_tarif{st_pu_htva};
			}
			else
			{
				#encodagage des prix HTVA
				$update_data_stock_tarif{st_pu_htva} = $htva;
				$update_data_stock_tarif{st_pu_tva} = $update_data_stock_tarif{st_pu_htva} * $eshop_tva{tva_value};
				$update_data_stock_tarif{st_pu_tvac} = $update_data_stock_tarif{st_pu_htva} * (1 + $eshop_tva{tva_value});
			}
			updateh_db($dbh,"data_stock_tarif",\%update_data_stock_tarif,"id",$data_stock_tarif{id});
			log_debug("Maj stock tarif$data_stock_tarif{id}",'','save_stock_prix');
		}
		$stmt = "UPDATE data_stock SET todel = $todel WHERE id = '$data_stock{id}' ";
		$cursor = $dbh->prepare($stmt);
		$cursor->execute || suicide($stmt);	
	}
	
	#sauvegarde nouveaux stocks
	foreach my $nouvelle_ligne (1 .. 20)
	{
		my $reference = get_quoted('reference_nouvelle_'.$nouvelle_ligne);
		my $id_stock = '';
		
		my $todel = 1;
		if($reference ne '')
		{
			$todel = 0;
		}
		
		my $id_data_category = get_quoted('data_category_nouvelle_'.$nouvelle_ligne);
		my $stock = get_quoted('stock_nouvelle_'.$nouvelle_ligne);
		my $weight = get_quoted('weight_nouvelle_'.$nouvelle_ligne);
		if($stock ne '' || $weight ne ''|| $id_data_category ne '')
		{
			$todel = 0;		
		}

		my %update_data_stock = 
		(
			id_data_category => $id_data_category,
			id_data_sheet => $data_sheet{id},
			reference => $reference,
			stock => $stock,
			weight => $weight,
			todel => $todel,
			id_eshop_tva => $eshop_tva{id},
		);
		
		log_debug("Nouveau stock $nouvelle ligne: todel: $todel",'','save_stock_prix');
		
		#nouvelle ligne utile
		if($todel == 0)
		{
			$id_stock = inserth_db($dbh,'data_stock',\%update_data_stock);
			$stmt = "UPDATE data_stock SET reference = CONCAT('REF',id) WHERE id = '$id_stock'";
			$cursor = $dbh->prepare($stmt);
			$cursor->execute || suicide($stmt);	

			log_debug("Nouvel id stock: $id_stock",'','save_stock_prix');
			
			foreach $eshop_tarif (@eshop_tarifs)
			{
				my %eshop_tarif = %{$eshop_tarif};

				my %update_stock_tarif = 
				(
					id_data_sheet => $data_sheet{id},
					id_data_stock => $id_stock,
					id_tarif => $eshop_tarif{id},
				);
				my $id_data_stock_tarif = inserth_db($dbh,'data_stock_tarif',\%update_stock_tarif);
				log_debug("Nouvel id stock tarif: $id_data_stock_tarif",'','save_stock_prix');
				
				my %update_data_stock_tarif = 
				(
					taux_tva => $eshop_tva{tva_value},
				);
				
				my $tvac = get_quoted('tvac_nouvelle_'.$nouvelle_ligne.'_'.$eshop_tarif{id});
				my $htva = get_quoted('htva_nouvelle_'.$nouvelle_ligne.'_'.$eshop_tarif{id});
				if($config{encodage_tvac} eq "y")
				{
					#encodagage des prix TVAC
					$update_data_stock_tarif{st_pu_tvac} = $tvac;
					$update_data_stock_tarif{st_pu_htva} = $update_data_stock_tarif{st_pu_tvac} / (1 + $eshop_tva{tva_value});
					$update_data_stock_tarif{st_pu_tva} = $update_data_stock_tarif{st_pu_tvac} - $update_data_stock_tarif{st_pu_htva};
				}
				else
				{
					#encodagage des prix HTVA
					$update_data_stock_tarif{st_pu_htva} = $htva;
					$update_data_stock_tarif{st_pu_tva} = $update_data_stock_tarif{st_pu_htva} * $eshop_tva{tva_value};
					$update_data_stock_tarif{st_pu_tvac} = $update_data_stock_tarif{st_pu_htva} * (1 + $eshop_tva{tva_value});
				}
				updateh_db($dbh,"data_stock_tarif",\%update_data_stock_tarif,"id",$id_data_stock_tarif );
				
				log_debug("Maj stock tarif: $id_data_stock_tarif",'','save_stock_prix');
			}
		}
	}
	
	#supprimer stocks + tarifs inutiles
	$stmt = "DELETE FROM data_stock WHERE id_data_sheet = 0";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt);
	$stmt = "DELETE FROM data_stock WHERE id_data_sheet NOT IN (SELECT id FROM data_sheets) ";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt);	
	$stmt = "DELETE FROM data_stock WHERE todel = 1 AND id_data_sheet = '$data_sheet{id}' ";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt);	
	$stmt = "DELETE FROM data_stock_tarif WHERE id_data_stock NOT IN (SELECT id FROM data_stock) ";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt);	
	
	
	#crée les apercus de prix pour ce produit et pour les produits sans apercu.
	$stmt = "update `data_sheets` ds set price = (select MIN(st_pu_tvac) from data_stock_tarif where id_data_sheet = ds.id and id_tarif=1 and st_pu_tvac != 0 order by st_pu_tvac asc) where price = 0 and id_data_family='$data_sheet{id_data_family}'";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt);
	$stmt = "update `data_sheets` ds set price = (select MIN(st_pu_tvac) from data_stock_tarif where id_data_sheet = ds.id and id_tarif=1 and st_pu_tvac != 0 order by st_pu_tvac asc) where id = '$data_sheet{id}'";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt);

}

sub save_stock_prix_DESACTIVE
{
	#cas sans variante: boucler sur les stock et sauver les infos recues
	my %data_sheet = %{$_[0]};
	my %check_data_stock = sql_line({table=>'data_stock',where=>"id_data_sheet='$data_sheet{id}'"});
	
	my %eshop_tva = read_table($dbh,'eshop_tvas',$data_sheet{taux_tva});
	my $reference = get_quoted('reference_'.$check_data_stock{id});
	if($reference eq '')
	{
		$reference = 'REF'.$data_sheet{id};
	}
	
	#update sheet
	my %update_data_sheet = 
	(
		taux_tva => $eshop_tva{id},
	);
    updateh_db($dbh,"data_sheets",\%update_data_sheet,"id",$data_sheet{id});
	
	#update stock
	my %update_data_stock = 
	(
		reference => $reference,
		stock => get_quoted('stock_'.$check_data_stock{id}),
		weight => get_quoted('weight_'.$check_data_stock{id}),
		id_eshop_tva => $eshop_tva{id},
	);
    updateh_db($dbh,"data_stock",\%update_data_stock,"id",$check_data_stock{id});
	
	#update stock tarifs
	my @eshop_tarifs = sql_lines({table=>'eshop_tarifs',where=>"visible='y'"});
	foreach $eshop_tarif(@eshop_tarifs)
	{
		my %eshop_tarif = %{$eshop_tarif};
		
		my %data_stock_tarif = sql_line({table=>'data_stock_tarif',where=>"id_data_stock='$check_data_stock{id}' AND id_tarif='$eshop_tarif{id}'"});
		
		my %update_data_stock_tarif = 
		(
			taux_tva => $eshop_tva{tva_value},
		);
		
		if($config{encodage_tvac} eq "y")
		{
			#encodagage des prix TVAC
			$update_data_stock_tarif{st_pu_tvac} = get_quoted('tvac_'.$check_data_stock{id}.'_'.$eshop_tarif{id});
			$update_data_stock_tarif{st_pu_htva} = $update_data_stock_tarif{st_pu_tvac} / (1 + $eshop_tva{tva_value});
			$update_data_stock_tarif{st_pu_tva} = $update_data_stock_tarif{st_pu_tvac} - $update_data_stock_tarif{st_pu_htva};
		}
		else
		{
			#encodagage des prix HTVA
			$update_data_stock_tarif{st_pu_htva} = get_quoted('htva_'.$check_data_stock{id}.'_'.$eshop_tarif{id});
			$update_data_stock_tarif{st_pu_tva} = $update_data_stock_tarif{st_pu_htva} * $eshop_tva{tva_value};
			$update_data_stock_tarif{st_pu_tvac} = $update_data_stock_tarif{st_pu_htva} * (1 + $eshop_tva{tva_value});
		}
		updateh_db($dbh,"data_stock_tarif",\%update_data_stock_tarif,"id",$data_stock_tarif{id});
	}
}


sub fill_id_data_family
{
	my %d = %{$_[0]};
	if($d{data_sheet}{id_data_family} == 0 && $d{id_data_family} > 0)
	{
		$stmt = "UPDATE data_sheets SET id_data_family = $d{id_data_family} WHERE id = '$d{data_sheet}{id}' ";
		$cursor = $dbh->prepare($stmt);
		$cursor->execute || suicide($stmt);
		$d{data_sheet}{id_data_family} = $d{id_data_family};
	}
	return $d{data_sheet}{id_data_family};
}

sub link_categories
{
	my %d = %{$_[0]};
	#le role gere les categories 
	my %check = sql_line({table=>'data_families',where=>"show_categories LIKE '%,$user{id_role},%'  AND id='$d{id_data_family}'"});
	if(!($check{id} > 0))
	{
		return '';
	}
	else
	{
		#toutes les catégories à ne pas garder
		$stmt = "UPDATE data_lnk_sheets_categories SET keep_category = 0 WHERE id_data_sheet = '$d{id_data_sheet}'";
		$cursor = $dbh->prepare($stmt);
		$cursor->execute || suicide($stmt);
		
		#categories cochées
		my @id_data_categories = split(/,/,$d{id_data_categories});
		foreach my $id_data_category (@id_data_categories) 
		{
			if($id_data_category > 0)
			{
				#INSERT OR UPDATE pour les catégories cochées avec à garder = 1
				my %lnk = 
				(
					id_data_category => $id_data_category,
					id_data_sheet => $d{id_data_sheet},
					id_data_family => $d{id_data_family},
					visible => 'y',
					migcms_id_user_last_edit => $user{id},
					migcms_moment_last_edit => 'NOW()',
					keep_category => 1,
				);
				my $id_lnk = sql_set_data({debug=>0,dbh=>$dbh,table=>'data_lnk_sheets_categories',data=>\%lnk, where=>"id_data_category='$lnk{id_data_category}' AND id_data_sheet='$lnk{id_data_sheet}'"});               
				
				#met les nouveaux à la fin
				$stmt = "UPDATE data_lnk_sheets_categories SET ordby = '9999' WHERE ordby = '0' AND id_data_sheet = '$d{id_data_sheet}'";
				execstmt($dbh,$stmt);

				#retri
				my $reordby = 'lnk.ordby,lnk.id';
				if($config{cat_reordby} ne '')
				{
					$reordby = $config{cat_reordby};
				}
				my $new_ordby = 1;
				my @lnks = sql_lines({debug=>0,debug_results=>0,table=>'data_lnk_sheets_categories lnk, data_sheets sh',where=>"lnk.id_data_sheet = sh.id AND lnk.id_data_category='$id_data_category'",ordby=>$reordby});
				foreach $lnk (@lnks)
				{
					my %lnk = %{$lnk};
					$stmt = "UPDATE data_lnk_sheets_categories SET ordby = '$new_ordby' WHERE id ='$lnk{id}'";
					# log_debug($stmt);
					execstmt($dbh,$stmt);
					$new_ordby++; 
				}
			}		
		}
		
		#delete celles qui ne sont pas à garder
		$stmt = "DELETE FROM data_lnk_sheets_categories WHERE keep_category != 1 AND id_data_sheet = '$d{id_data_sheet}'";
		$cursor = $dbh->prepare($stmt);
		$cursor->execute || suicide($stmt);
	}
	
	$stmt = "UPDATE data_sheets SET id_data_categories = CONCAT(',',id_data_categories) WHERE id ='$d{id_data_sheet}'";
	execstmt($dbh,$stmt);
	$stmt = "UPDATE data_sheets SET id_data_categories = CONCAT(id_data_categories,',') WHERE id ='$d{id_data_sheet}'";
	execstmt($dbh,$stmt);
	

}
 
sub link_categories_remplace
{
	my %d = %{$_[0]};
	
	#le role gere les categories 
	my %check = sql_line({table=>'data_families',where=>"show_categories LIKE '%,$user{id_role},%'  AND id='$d{id_data_family}'"});
	if(!($check{id} > 0))
	{
		return '';
	}
	else
	{
		#chercher les catégories à conserver
		my @sql_list_categories = ();
		my @id_data_categories = split(/,/,$d{id_data_categories});
		foreach my $id_data_category (@id_data_categories) 
		{
			if($id_data_category > 0)
			{
				push @sql_list_categories,"'$id_data_category'";
			}
		}
		my $sql_list_categories = join(",",@sql_list_categories);
		if($sql_list_categories eq '')
		{
			$sql_list_categories = "'0'";
		}
		
		#supprimer les catégories inutiles
		# $stmt = "DELETE FROM data_lnk_sheets_categories WHERE id_data_sheet = '$d{id_data_sheet}' AND id_data_category NOT IN ($sql_list_categories)";
		$stmt = "DELETE FROM data_lnk_sheets_categories WHERE id_data_sheet = '$d{id_data_sheet}'";
		$cursor = $dbh->prepare($stmt);
		$cursor->execute || suicide($stmt);
		
		#ajouter les autres
		my @id_data_categories = split(/,/,$d{id_data_categories});
		foreach my $id_data_category (@id_data_categories) 
		{
			my %lnk = 
			(
				id_data_category => $id_data_category,
				id_data_sheet => $d{id_data_sheet},
				id_data_family => $d{id_data_family},
				ordby => 0,
				visible => 'y',
				migcms_id_user_last_edit => $user{id},
				migcms_moment_last_edit => 'NOW()',
			);
			sql_set_data({debug=>0,dbh=>$dbh,table=>'data_lnk_sheets_categories',data=>\%lnk, where=>"id_data_category='$lnk{id_data_category}' AND id_data_sheet='$lnk{id_data_sheet}'"});               
		}
		
		#sort all categories
		 my @data_categories = sql_lines({table=>'data_categories',ordby=>'id'});
		 foreach $data_category (@data_categories)
		 {
			my $new_ordby = 1;
			my %data_category = %{$data_category};
			my $reordby = 'lnk.ordby,lnk.id';
			if($config{cat_reordby} ne '')
			{
				$reordby = $config{cat_reordby};
			}
			my @lnks = sql_lines({table=>'data_lnk_sheets_categories lnk, data_sheets sh',where=>"lnk.id_data_sheet = sh.id AND lnk.id_data_category='$data_category{id}'",ordby=>$reordby});
			foreach $lnk (@lnks)
			{
				my %lnk = %{$lnk};
				$stmt = "UPDATE data_lnk_sheets_categories SET ordby = '$new_ordby' WHERE id ='$lnk{id}'";
				execstmt($dbh,$stmt);
				$new_ordby++; 
			}
		 }
	}
	
	$stmt = "UPDATE data_sheets SET id_data_categories = CONCAT(',',id_data_categories) WHERE id ='$d{id_data_sheet}'";
	execstmt($dbh,$stmt);
	$stmt = "UPDATE data_sheets SET id_data_categories = CONCAT(id_data_categories,',') WHERE id ='$d{id_data_sheet}'";
	execstmt($dbh,$stmt);
}



sub cat_preview
{
    my $dbh = $_[0];
    my $id_data_sheet = $_[1];
    my $sheets="";
    my $list_cats="";
    my @cats_linked = get_table($dbh,"data_lnk_sheets_categories lnk","distinct(id_data_category) as id_data_category","id_data_sheet='$id_data_sheet'");
    foreach $cat_linked (@cats_linked)
    {
        my %cat = %{$cat_linked};
        $list_cats .= " $cat{id_data_category}, ";
    }
    $list_cats .= ' 0 ';
    
    my $id_data_family = get_quoted('id_data_family') || 1;
    my $list_cats_preview = get_categories_list($dbh,'','','','',$id_data_family,'this_list_cats_only',$list_cats,$colg);
    
    # my $list_cats_change = get_categories_list($dbh,'','','','',$id_data_family,'select','',$colg);
    # return "$list_cats_preview <br /><select name='add_category' class='add_category' id='$id_data_sheet'><option value=''>+</option>$list_cats_change</select>";
    
	$list_cats_preview = <<"EOH";
	<div class="text-left" style="min-width:200px">$list_cats_preview</div>
EOH
	
	return $list_cats_preview;
}

sub pic_preview
{
    my $dbh = $_[0];
    my $id_data_sheet = $_[1];
	
	my %migcms_linked_file = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='$dm_cfg{table_name}' AND token='$id_data_sheet' AND table_field='photos' ",limit=>"1",ordby=>"ordby"});
	my $photo = migcrender::render_pic({full_url=>1,migcms_linked_file => \%migcms_linked_file,size=>"mini",lg=>1});	

    return  $photo;
}

sub shoeman
{
    # my $dbh = $_[0];
    my $id_data_sheet = $_[1];
	
	my %ds = sql_line({select=>"f30,stock_activable,photos_activable,sheet_activable,migcms_moment_last_edit",table=>'data_sheets',where=>"id='$id_data_sheet'"});
	
	#sheet_activable
	my $class_sheet = " btn btn-default ";
	my $icon = " fa-times ";
	my $class_title = " La fiche ne répond pas aux critères et peut être affichée publiquement ";
	if($ds{sheet_activable} == 1)
	{
		$class_sheet = " btn btn-success ";
		$class_title = " La fiche peut être affichée publiquement ";
		$icon = " fa-check ";		
	}
	
	my $prix = "";
	
	#stock_activable
	my $class_stock = " btn btn-default ";
	my $class_stock_title = " Stock non reçu ";
	if($ds{stock_activable} == 1)
	{
		$class_stock = " btn btn-success ";
		$class_stock_title = " Stock reçu ";	
		my %dst_min = sql_line({select=>"st_pu_tvac,st_pu_htva,st_pu_tvac_discounted,st_pu_htva_discounted",ordby=>"st_pu_tvac desc",limit=>"0,1",table=>'data_stock_tarif dst, data_stock ds',where=>"dst.id_data_stock = ds.id AND stock > 0 AND st_pu_tvac > 0 AND dst.id_data_sheet='$id_data_sheet'"});
		
		if($dst_min{st_pu_tvac} > 0 )
		{
			# my %dst_max = sql_line({select=>"MAX(st_pu_tvac) as montant",table=>'data_stock_tarif dst, data_stock ds',where=>"dst.id_data_stock = ds.id AND stock > 0 AND st_pu_tvac > 0 AND dst.id_data_sheet='$id_data_sheet'"});
			$prix = "<br />àpd <b>$dst_min{st_pu_tvac} € TVAC</b> ($dst_min{st_pu_htva} € HTVA)";
			
			if($dst_min{st_pu_tvac_discounted} > 0 )
			{
				$prix = "<br /><span style=\"text-decoration:line-through\" <b>$dst_min{st_pu_tvac} € TVAC</b> ($dst_min{st_pu_htva} € HTVA)</span>";
				$prix .= "<br /><span style=\"color:red\"><b>$dst_min{st_pu_tvac_discounted} € TVAC</b> ($dst_min{st_pu_htva_discounted} € HTVA)</span>";
			}
		}	
	}
	
	#photos_activable
	my $class_photo = " btn btn-default ";
	my $class_photo_title = " Pas assez de photo reçue ";
	if($ds{photos_activable} == 1)
	{
		$class_photo = " btn btn-success ";
		$class_photo_title = " Photos reçues ";	
	}
	
	my $remarque = '';
	if($ds{f30} ne '')
	{
		$remarque = "<br><span style=\"color:red\">$ds{f30}</span>";
	}
	
	my %stock_total = ();
	if($ds{stock_activable} == 1)
	{
		%stock_total = sql_line({select=>"SUM(stock) as tot",table=>'data_stock ds',where=>"id_data_sheet='$id_data_sheet'"});
	}
	if($stock_total{tot} eq '')
	{
		$stock_total{tot} = 0;
	}
	
	$ds{migcms_moment_last_edit} = to_ddmmyyyy($ds{migcms_moment_last_edit},"withtime");
	my $col = <<"EOH";
	<div style="width:250px!important">
		<a href="#" class="$class_stock" data-placement="bottom" data-original-title="$class_stock_title"><i class="fa fa-cubes" aria-hidden="true"></i> Stock: $stock_total{tot}</a>
		<a href="#" class="$class_photo" data-placement="bottom" data-original-title="$class_photo_title"><i class="fa fa-picture-o" aria-hidden="true"></i></a>
		<a href="#" class="$class_sheet" data-placement="bottom" data-original-title="$class_title"><i class="fa $icon" aria-hidden="true"></i></a>
		<br />Maj: $ds{migcms_moment_last_edit}
		$remarque
		$prix
	</div>
EOH
	

    return  $col;
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
		print <<"EOH";
		<script type="text/javascript">
		  alert("L'adresse n'a pu être localisée par Google");
		</script>
EOH
	}
	else
	{
	  my $latitude = $location->{geometry}{location}{lat};
	  my $longitude = $location->{geometry}{location}{lng};  

		  if($id_data_sheet ne "" && $latitude ne "" && $longitude ne "" && $field_lat ne "" && $field_lon ne "" && $data_sheet{$field_lat} eq "" && $data_sheet{$field_lon} eq "")
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
			print <<"EOH";
			<script type="text/javascript">
			  alert("Une erreur est survenue lors de la mise à jour de la latitude et de la longitude (informations manquantes)");
			</script>
EOH
		} 
	}
} 

sub tree_categories_filter
{
  my $dbh = $_[0];
  my $id_data_category = get_quoted('id_data_category') || '';
  my $extra_filter = get_quoted('extra_filter') || '';
  if($id_data_category eq '' && $extra_filter > 0)
  {
		$id_data_category = $extra_filter;
  }
  my $cat_list = get_categories_list($dbh,'','','',$id_data_category,'','select','',$colg);
  if($cat_list eq '<option value="0"></option>')
  {
	return '';
  }
  my $filter=<<"EOH";
 
   
   <div class="form-group group-filters-labtable-$col col-md-3">
	<label><strong>$migctrad{data_sheets_extra_filter}</strong></label>
	<select class="list_filter select2 form-control search_element" data-placeholder="$label"  id="extra_filter" name="id_data_categories">
		 $cat_list
	</select>
</div>
EOH
  
  return $filter;
}

sub after_upload
{
	my $dbh=$_[0];
	my $id=$_[1];
	my $fieldname=$_[2];
	
	my %data_sheet = read_table($dbh,'data_sheets',$id);
   	# log_debug('after_upload:'.$fieldname,'','after_upload');
	
	if($fieldname eq 'photos')
	{
		# log_debug('resize_sheet_pics','','after_upload');
		resize_sheet_pics({id_data_family=>$data_sheet{id_data_family},id_data_sheet=>$data_sheet{id}});
	}
	else
	{
		my $ordby_field = $fieldname;
		$ordby_field =~ s/^f//g;
		if($ordby_field > 0)
		{
			# log_debug('resize_sheet_pics','','after_upload');
			resize_sheet_pics({table_field=>"$fieldname",id_data_family=>$data_sheet{id_data_family},id_data_sheet=>$data_sheet{id}});

			my %data_field = sql_line({table=>"data_fields",where=>"ordby='$ordby_field' AND id_data_family='$data_sheet{id_data_family}'"});
			my %migcms_linked_file = sql_line({table=>"migcms_linked_files",where=>"ordby='1' AND table_name='data_sheets' AND table_field='$fieldname' AND token='$data_sheet{id}'"});
			if($data_field{field_type} eq 'files_admin' && $data_field{field_tab} eq 'seo')
			{
				my $path = $config{directory_path}.'/usr/files/'.$dm_cfg{file_prefixe}.'/'.$fieldname.'/'.$id;
				resizeog_for_sheet($migcms_linked_file{name_og},$migcms_linked_file{name_medium},$path);
			}			
		}
	}
}

sub resize_sheet_pics
{
	my %d = %{$_[0]};
	if($d{table_field} eq '')
	{
		$d{table_field} = 'photos';
	}
	my %data_family = read_table($dbh,"data_families",$d{id_data_family});

	my @sizes = ('large','small','medium','mini','og');
	
	#boucle sur les images du paragraphes
	my @migcms_linked_files = sql_lines({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='$dm_cfg{table_name}' AND table_field='$d{table_field}' AND token='$d{id_data_sheet}'",ordby=>'ordby'});
	foreach $migcms_linked_file (@migcms_linked_files)
	{
		#appelle la fonction de redimensionnement
		my %migcms_linked_file = %{$migcms_linked_file};
		my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
		my %params = (
			migcms_linked_file=>\%migcms_linked_file,
			do_not_resize=>'n',
		);
		foreach my $size (@sizes)
		{
			$params{'size_'.$size} = $data_family{$size.'_width'};
		}
		dm::resize_pic(\%params);
	}	
}

sub resizeog_for_sheet
{
	use File::Path;
	use File::Copy;
	log_debug('','vide','resizeog_for_sheet');
	
	my $og_width = 1200;
	my $og_heigt = 630;
	
	my $og_file = $_[0];
	my $medium_file = $_[1];
	my $path = $_[2];
	if($og_file eq '')
	{
		log_debug('og_file vide !','','resizeog_for_sheet');
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
		log_debug('Og existe PAS ! '.$original_path,'','resizeog_for_sheet');
		$original_path = $path.'/'.$medium_file;
		
		if(!(-e $original_path))
		{
			log_debug('medium existe PAS ! '.$original_path,'','resizeog_for_sheet');

			return 0;
		}
		else
		{
			log_debug('medium existe ! '.$original_path,'','resizeog_for_sheet');
		}
	}
	else
	{
		log_debug('Og existe ! '.$original_path,'','resizeog_for_sheet');
	}
	
	my $inter_path = $path.'/'.$filename.'_inter.'.$ext;
	my $recoup_path = $path.'/'.$filename.'_recoup.'.$ext;
	my $original = GD::Image->new($original_path);
	my ($original_width,$original_height) = $original->getBounds();
	
	if($original_height == 0)
	{
		log_debug('$original_height = 0 '.$original_height,'','resizeog_for_sheet');
		return 0;
	}
	if($original_width == $og_width)
	{
		unlink($inter_path);
		unlink($recoup_path);
		log_debug('widths identiques: return 1'.$original_height,'','resizeog_for_sheet');
		return 1;
	}
	
	my $inter_ratio =  $og_heigt / $original_height;
	my $inter_height = $og_heigt;
	my $inter_width = $original_width * $inter_ratio;
	
	log_debug('og_heigt'.$og_heigt,'','resizeog_for_sheet');
	log_debug('original_height'.$original_height,'','resizeog_for_sheet');
	log_debug('og_width'.$og_width,'','resizeog_for_sheet');
	log_debug('original_width'.$original_width,'','resizeog_for_sheet');
	log_debug('inter_ratio'.$inter_ratio,'','resizeog_for_sheet');
	log_debug('inter_height'.$inter_height,'','resizeog_for_sheet');
	log_debug('inter_width'.$inter_width,'','resizeog_for_sheet');

	
	#nouvelle image inter
	my $inter = GD::Image->new($inter_width,$inter_height,1);
	$inter->saveAlpha(1);
	$inter->alphaBlending(0);
	$inter->copyResampled($original,0,0,0,0,$inter_width,$inter_height,$original_width,$original_height);
	my $data = $inter->jpeg(100); 
	log_debug('>'.$inter_path,'','resizeog_for_sheet');

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
	
	log_debug('>'.$recoup_path,'','resizeog_for_sheet');
	open (THUMB,">$recoup_path");
	binmode THUMB;  
	print THUMB $data;  
	close THUMB;
	
	$original_path = $path.'/'.$og_file;
	copy($recoup_path,$original_path);
	log_debug('copy:'."$recoup_path,$original_path",'','resizeog_for_sheet');
	unlink($inter_path);
	unlink($recoup_path);
	log_debug('unlink et fin:','','resizeog_for_sheet');
	
	return 1;
}

sub get_autocomplete_data_sheets
{	

   #prend la famille par défaut
   my $lg = get_quoted('lg') || $config{default_colg} || 1;
   my $id_data_family = get_quoted("id_data_family");
   my %data_family = read_table($dbh,"data_families",$id_data_family);
   my $term = get_quoted('term') || '';

   #récupère le champ nom et le champ référence afin de déterminer leur type (on considère que le champ référence est tjs non traductible)
   my %field_reference = read_table($dbh,"data_fields",$data_family{id_field_reference});
   my %field_name = read_table($dbh,"data_fields",$data_family{id_field_name});
   my $field_reference = 'f'.$field_reference{ordby};
   my $field_name = 'f'.$field_name{ordby};

   my $list = '[';

 		my @data_sheets = sql_lines({
 			debug => 1,
 			dbh=>$dbh, 
 			select=>"sheets.id, $field_reference, txtcontents.lg$lg as name",
 			table=>"data_sheets as sheets, txtcontents",
 			where=>"id_data_family = '$id_data_family'
 							AND txtcontents.id = sheets.$field_name
 							AND ($field_reference LIKE '%$term%' OR txtcontents.lg$lg LIKE '%$term%')"
 		});

     # my @data_sheets = get_table($dbh,"data_sheets sh, txtcontents txt","sh.id,$field_reference,lg$lg as content","sh.$field_name = txt.id AND txt.lg$lg = $lg AND ($field_reference LIKE '%$term%' OR lg$lg LIKE '%$term%')","","","",0);
     foreach $data_sheet (@data_sheets)
     {            
        my %data_sheet = %{$data_sheet};
        $data_sheet{content} =~ s/\"//g;
        $list .= '{ "id": "'.$data_sheet{id}.'", "label": "'.$data_sheet{$field_reference}.': '.$data_sheet{name}.'", "value": "'.$data_sheet{$field_reference}.': '.$data_sheet{name}.'" },';
     }
     
     # Suppression de la dernière , 
     chop($list);

   $list .=']';

  print $list;
  exit;

   
}

#############################################################
################### ajax_get_assoc_sheets ###################
#############################################################
# Renvoit les produits associés à la fiche
# 
# JSON:
# - ID
# - REFERENCE
# - NOM
# - IMAGE
#############################################################
sub ajax_get_assoc_sheets
{
	my %d = %{$_[0]};
  my $id_data_sheet = get_quoted("id_data_sheet") || $d{id_data_sheet};
  my $ajax_call = get_quoted("ajax_call");

  my %response = ();

  # Récupération des associations entre la fiche courante et d'autres fiches
  my @data_sheets_assoc = sql_lines({dbh=>$dbh, table=>"data_sheets_assoc", where=>"id_data_sheet = '$id_data_sheet'"});

  my $related_sheets_content = "";
  if($#data_sheets_assoc > -1)
  {

     # On parcourt les associations
    foreach $data_sheet_assoc (@data_sheets_assoc)
    {
      my %data_sheet_assoc = %{$data_sheet_assoc};

      # Récupération de la fiche du produit associé
      my %data_sheet = sql_line({dbh=>$dbh, table=>"data_sheets", where=>"id = '$data_sheet_assoc{id_assoc_sheet}'"});

      if($data_sheet{id} > 0)
      {
        # Récupération de l'image du produit
        # my %pic=select_table($dbh,"data_lnk_sheet_pics lnk, pics p","pic_name_mini","id_data_sheet='$data_sheet{id}' AND lnk.id_pic = p.id AND  lnk.visible='y' order by lnk.ordby limit 0,1","","",0);

        my %migcms_linked_file = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='$dm_cfg{table_name}' AND token='$data_sheet{id}' AND table_field='photos' ",limit=>"1",ordby=>"ordby"});
				my $photo = migcrender::render_pic({full_url=>1,migcms_linked_file => \%migcms_linked_file,size=>"mini",lg=>1});

        my $nom = get_traduction({id=>"$data_sheet{f2}", lg=>$config{current_language}});


        $response{content} .= <<"EOH";
        <tr>
	        <td align=''>$photo</td>
	        <td>$data_sheet{f1}</td>
	        <td>$nom</td>
	        <td class='remove_assoc'>
	        <a id='$data_sheet{id}' href="#" data-placement="bottom" data-original-title="Supprimer" role="button" class="btn btn-danger"><i class="fa fa-trash fa-fw" data-original-title="" title=""></i></a>
	        </td>
        </tr>
EOH
      }

    }

    $response{content} = <<"EOH";
	  	<table id="" class="table table-bordered table-striped table-condensed cf table-hover">
	      	<tr class="mig_th_header">
						<th data-noresize="" class="widget-header-func"><span class="btn-block">Photos</span></th>
						<th class="widget-header"><span class="btn-block">Référence</span></th>
						<th class="widget-header"><span class="btn-block">Nom</span></th>
						<th class="widget-header"></th>
					</tr>
					$response{content}
	      </table>
EOH
  }
  else
  {
    $response{content} = <<"HTML"
      <div class="panel panel-warning block_to_link ">
        <div class="panel-heading">
          <i class="fa fa-exclamation-triangle" data-original-title="" title=""></i> Ce produit ne possède pas encore de produits associés
        </div>
      </div>
HTML
  }

  if($ajax_call eq "y")
  {
  	print JSON->new->utf8(0)->encode(\%response);
  	exit;  	
  }
  else
  {
  	return $response{content};
  }
}

############################################################
################### ajax_add_assoc_sheet ###################
############################################################
# Ajoute en ajax une association en DB
# Response : JSON :
#   - status
#   - id_data_sheet_assoc
############################################################
sub ajax_add_assoc_sheet
{
  my $id_data_sheet = get_quoted("id_data_sheet");
  my $id_assoc_sheet = get_quoted("id_assoc_sheet");

  my %response = (
    status => "ko",
  );

  if($id_data_sheet > 0 && $id_assoc_sheet > 0)
  {
    # On vérifie que ces deux produits ne sont pas déjà associé
    my %existing_assoc = sql_line({dbh=>$dbh, table=>"data_sheets_assoc", where=>"id_data_sheet = '$id_data_sheet' AND id_assoc_sheet = '$id_assoc_sheet'"});
    
    if(!$existing_assoc{id} > 0)
    {
      my %new_data_sheets_assoc = (
        id_data_sheet  => $id_data_sheet,
        id_assoc_sheet => $id_assoc_sheet,
      );

      my $id_data_sheet_assoc = inserth_db($dbh, "data_sheets_assoc", \%new_data_sheets_assoc);

      if($id_data_sheet_assoc > 0)
      {
        %response = (
          status              => "ok",
          id_data_sheet_assoc => $id_data_sheet_assoc,
        );
      }
    }
    else
    {
      %response = (
        status => "existing",
      );
    }
    
  }

  print JSON->new->utf8(0)->encode(\%response);
  exit;
}


###############################################################
################### ajax_remove_assoc_sheet ###################
###############################################################
# Supprime en ajax une association en DB
###############################################################
sub ajax_remove_assoc_sheet
{
  my $id_data_sheet = get_quoted("id_data_sheet");
  my $id_assoc_sheet = get_quoted("id_assoc_sheet");

  my %response = (
    status => "ko",
  );

  if($id_data_sheet > 0 & $id_assoc_sheet > 0)
  {
    my $stmt = <<"SQL";
      DELETE FROM data_sheets_assoc
        WHERE id_data_sheet = '$id_data_sheet'
          AND id_assoc_sheet = '$id_assoc_sheet'
SQL

    execstmt($dbh, $stmt);

    $response{status} = "ok";
  }

  print JSON->new->utf8(0)->encode(\%response);
  exit;
}