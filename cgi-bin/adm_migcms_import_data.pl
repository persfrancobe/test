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
use def_handmade;

use Text::Iconv;
use Spreadsheet::XLSX;
use HTML::Entities;

use Math::Round;

use Digest::MD5::File qw(dir_md5_hex file_md5_hex url_md5_hex);
use File::Copy::Vigilant qw(copy move);




$dm_cfg{add_title}       = "";
$dm_cfg{table_name}      = "";
$dm_cfg{list_table_name} = "";
$dm_cfg{self}            = "$config{fullurl}/cgi-bin/adm_migcms_import_data.pl?";
$dm_cfg{enable_search}   = 1;
$dm_cfg{duplicate}       = 0;
$dm_cfg{vis_opt}         = 1;
$dm_cfg{sort_opt}        = 1;
$dm_cfg{trad}            = 0;
$dm_cfg{wherel}          = $dm_cfg{wherep} = "";
$dm_cfg{migcrender}      = 0;
$dm_cfg{def_handmade}    = 0;
$dm_cfg{operations}      = 0;



my $sw = get_quoted("sw") || "import_data_form";




my %data_import_config = %{def_handmade::get_data_import_config()};

see();

my @fcts = qw(
      import_data_form
      import_data_form_db
    );

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);

    my $suppl_js=<<"EOH";
    <link href="//netdna.bootstrapcdn.com/font-awesome/4.1.0/css/font-awesome.min.css" rel="stylesheet">

    <style>
    
    
    
    </style>
EOH
    
    print migc_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}

########################################################
################### import_data_form ###################
########################################################
# Formulaire d'import
########################################################
sub import_data_form
{
  my $script = get_script();
  my $token = create_token(50);

    $dm_output{content} = <<"EOH";

    <style>
    input[type=checkbox].disabled
    {
      cursor: not-allowed;
    }
    </style>

    $script

    <div class="wrapper">

      <div class="row">
        <div class="col-md-6">
          <h1 class="maintitle">Synchronisation XLSX</h1>
        </div>
      </div>

      <section class="panel">
        <!-- Body -->
        <div class="panel-body">                             
          <div class="panel panel-success">
            <div class="panel-heading">
              <i class="fa fa-cloud-upload"></i> Importer/mettre à jour des fiches (.xlsx)
            </div>
            <div class="panel-body">
              <form id="import_data_form" class="form-horizontal" action="$dm_cfg{self}" method="POST" enctype="multipart/form-data">
                <input type="hidden" name="sw" value="import_data_form_db" />
                <input type="hidden" id="synchro_token" name="synchro_token" value="$token" />

                <div class="form-group">
                  <label class="col-sm-2 control-label"></label>
                  <div class="col-sm-9">
                    <input onclick="return false;" type="checkbox" name="update_data_sheet" value="y" class="disabled" checked="checked">
                    Mettre à jour les données d'une fiche
                  </div>
                </div>
                <div class="form-group">
                  <label class="col-sm-2 control-label"></label>
                  <div class="col-sm-9">
                    <input onclick="return false;" type="checkbox" name="update_data_categories" value="y" class="disabled" checked="checked">
                    Mettre à jour les catégories
                  </div>
                </div>
                <div class="form-group">
                  <label class="col-sm-2 control-label"></label>
                  <div class="col-sm-9">
                    <input onclick="return false;" type="checkbox" name="update_data_stock_tarif" value="y" class="disabled" checked="checked">
                    Mettre à jour les prix
                  </div>
                </div>
                <div class="form-group $config{synchro_pics_checkbox_class}">
                  <label class="col-sm-2 control-label"></label>
                  <div class="col-sm-9">
                    <input onclick="return false;" type="checkbox" name="update_data_sheet_pics" value="y" class="disabled" checked="checked">
                    Mettre à jour les photos
                  </div>
                </div>
                <div class="form-group">
                  <label class="col-sm-2 control-label"></label>
                  <div class="col-sm-9">
                    <input onclick="return false;" type="checkbox" name="update_data_related_sheets" value="y" class="disabled" checked="checked">
                    Mettre à jour les produits associés
                  </div>
                </div>
                  <div class="form-group">
                      <label class="col-sm-2 control-label">Fichier Excel</label>
                      <div class="col-sm-9">
                        <input type="file" id="field_import_excel" name="import_excel" required />
                      </div>
                  </div>    
                  <br/>
                  <button id="submit_form" type="submit" class="btn btn-lg btn-success">Démarrer la synchronisation</button>
              </form>
            </div>
          </div>
        </div>
      </div>

    </div>
EOH

    return $dm_output{content};
}

###########################################################
################### import_data_form_db ###################
###########################################################
# Upload du fichier et début de la synchro
###########################################################
sub import_data_form_db {
    my $file = $cgi->param("import_excel");

    my $response = 0;
    my ($file_url, $size);

    # upload du fichier 
    if($file ne "")
    {  
      ($file_url,$size) = upload_file($file, $data_import_config{path});

      if($file_url eq "" || $size eq "")
      {
          # Erreur lors de l'upload
          $response = 2;            
      }
    }
    else
    {
      # Pas de fichier envoyé
      $response = 1;
    }

    # Si pas d'erreur de fichier, on lance la synchro
    my $nbr_rows;
    if($response == 0)
    {
      my $update_data_sheet          = get_quoted("update_data_sheet");
      my $update_data_categories     = get_quoted("update_data_categories");
      my $update_data_stock_tarif    = get_quoted("update_data_stock_tarif");
      my $update_data_sheet_pics     = get_quoted("update_data_sheet_pics");
      my $update_data_related_sheets = get_quoted("update_data_related_sheets");
      my $token                      = get_quoted("synchro_token");

      # récupération du nombre total de ligne présentent dans le fichier
      my $nbr_rows = get_xlsx_nbr_rows({file=>"$data_import_config{path}/$file_url"});

      # On multiple le nombre par deux car le fichier est parcouru deux fois pendant la synchro
      $nbr_rows = $nbr_rows*2;

      if($data_import_config{mode_test} eq "y")
      {
        $nbr_rows = 10;
      }

      if($nbr_rows > 0)
      {
        my $id_synchro_progress = init_synchro_progress({file=>"$data_import_config{path}/$file_url", nbr_rows=>$nbr_rows, type=>"update", token=>$token});

        $response = init_synchro({
          update_data_sheet          => $update_data_sheet,
          update_data_categories     => $update_data_categories,
          update_data_stock_tarif    => $update_data_stock_tarif,
          update_data_sheet_pics     => $update_data_sheet_pics,
          update_data_related_sheets => $update_data_related_sheets,
          id_synchro_progress        => $id_synchro_progress,
          filename                   => $file_url,
        });

      }
    }
    
    print $response;
    exit;
}


##############################################################################
# init_synchro
##############################################################################
sub init_synchro
{
  my %d = %{$_[0]};

  my $response = 0;

  $debug_filename = "migcms_import_data\_$d{id_synchro_progress}".".log";

	log_debug("Init synchro...","", $debug_filename);

	
  my $converter = Text::Iconv->new("utf-8","utf-8"); 
	my $excel = Spreadsheet::XLSX -> new ($data_import_config{path}."/".$d{filename},$converter);

	my $excel_sheet = $excel -> {Worksheet}[0];

  log_debug("Excel Sheet : [$excel_sheet]","", $debug_filename);

  if($config{mapping_data_import_config} eq "y")
  {
    ($data_import_config, $response) = def_handmade::mapping_data_import_config({excel_sheet=>$excel_sheet, config=>\%data_import_config});   
    %data_import_config = %{$data_import_config};

  }

  if($response != 0)
  {
    print $response;
    exit;
  }

	# On parcourt le fichier excel
	my $nbr_lignes = 1;
	foreach my $row ($data_import_config{startline} .. $excel_sheet->{MaxRow})
	{
    my $reference =  get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{data_sheets}{reference}{excel_col}});
    
    log_debug("Ligne [$row] REFERENCE = [$reference]","", $debug_filename);
		if($reference eq "")
		{     
			next;
		}

  	log_debug("[ligne $row] : Début","", $debug_filename);

    # DETECTION SI VARIANTE
    $isVariante = "n";
    if($data_import_config{gestion_variantes} eq "y")
    {
      $isVariante = checkIfVariante({excel_sheet=>$excel_sheet, row=>$row});
    }
  
  	# SYNCHRO DATA_SHEET
    if($d{update_data_sheet} eq "y" && $isVariante ne "y")
    {
      synchro_data_sheet({excel_sheet=>$excel_sheet, row=>$row});      
    } 

  	# SYNCHRO DATA_CATEGORIES
    if($d{update_data_categories} eq "y")
    { 
      synchro_data_categories({excel_sheet=>$excel_sheet, row=>$row, isVariante=>$isVariante});
    }

    # SYNCHRO DATA_SHEET_STOCK
    if($d{update_data_stock_tarif} eq "y")
    {
      synchro_data_sheet_stock({excel_sheet=>$excel_sheet, row=>$row, isVariante=>$isVariante});
    }
    # SYNCHRO PICS
    if($d{update_data_sheet_pics} eq "y" && $isVariante ne "y")
    {
      synchro_data_sheet_pics({excel_sheet=>$excel_sheet, row=>$row});
    }

  	log_debug("[ligne $row] : Fin","", $debug_filename);

    # On met à jour le status de la synchro en DB
    update_synchro_progress({dbh=>$dbh,id_synchro=>$d{id_synchro_progress}});

  	# Si c'est le mode test, s'arrête après 10 lignes
  	if($data_import_config{mode_test} eq "y" && $nbr_lignes == 10)
  	{
  		last;
  	}
  	$nbr_lignes++;
	}

  if($data_import_config{gestion_related_products} eq "y" || $data_import_config{custom_after_import_function} ne "")
  {
    # On remet à 0 le nbr de rows traité
#     my $stmt = <<"SQL";
#     UPDATE migcms_data_synchro
#       SET executed_rows = 0
#       WHERE id = '$d{id_synchro_progress}'
# SQL
#     execstmt($dbh, $stmt);    
    
    log_debug("Début du deuxième passage du fichier Excel (Traitement sur-mesure et/ou produits associés","", $debug_filename);

    # On reparcourt une fois que les produits ont été importés pour les produits associés
    my $nbr_lignes = 1;
    foreach my $row ($data_import_config{startline} .. $excel_sheet->{MaxRow})
    {
      my $reference =  get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{data_sheets}{reference}{excel_col}});
      if($reference eq "")
      {
        next;
      }

      # SYNCHRO DATA_SHEET_RELATED_PRODUCTS
      if($d{update_data_related_sheets} eq "y")
      {
        synchro_data_sheet_related_products({excel_sheet=>$excel_sheet, row=>$row});
      }

      # CUSTOM FUNCTION
      if($data_import_config{custom_after_import_function} ne "")
      {
        $fct = 'def_handmade::'.$data_import_config{custom_after_import_function};
        &$fct({excel_sheet=>$excel_sheet, row=>$row, data=>\%d, debug_filename=>$debug_filename});
      }

      # Si c'est le mode test, s'arrête après 10 lignes
      if($data_import_config{mode_test} eq "y" && $nbr_lignes == 10)
      {
        last;
      }

       # On met à jour le status de la synchro en DB
      update_synchro_progress({dbh=>$dbh,id_synchro=>$d{id_synchro_progress}});
      $nbr_lignes++;
    }    
  }

	return $response;
	
}


##############################################################################
# synchro_data_sheet_pics
##############################################################################
sub synchro_data_sheet_pics
{
  my %d = %{$_[0]};

  my $excel_sheet = $d{excel_sheet};
  my $row = $d{row};

  log_debug("[ligne $row] : Synchro pics","", $debug_filename);

  my $reference =  get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{data_sheets}{reference}{excel_col}});

  # On récupère la sheet en DB
  my %data_sheet = sql_line({dbh=>$dbh, table=>"data_sheets", where=>"f1 = '$reference' AND f1 != ''"});

  if($data_sheet{id} > 0 && $data_import_config{gestion_image} eq "y")
  {
    my %data_family = sql_line({dbh=>$dbh, table=>"data_families", where=>"id = $data_import_config{id_data_family}"});

    # On récupère toutes les images du dossier les contenant
    my @pics = @{get_files_directory({path=>$data_import_config{pics_directory}})};
    # On converti le tableau en hash pour pouvoir vérifier si une valeur existe
    my %hash_pics = map { $_ => 1 } @pics;

    # Pour chaque colonne d'image du fichier Excel
    foreach $key (sort keys %{$data_import_config{images}})
    {
      # On check si l'image existe
      my $pic_name = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{images}{$key}{excel_col}});
      if(exists($hash_pics{$pic_name}))
      {
        log_debug("[ligne $row] : La photo $pic_name a été trouvée","", $debug_filename);
        my $dir_sheet_pics = "../usr/files/SHEETS/photos/" . $data_sheet{id};

        # Si le dossier photos de la sheet n'existe pas on le créé
        unless (-d $dir_sheet_pics) {mkdir($dir_sheet_pics.'/') or die ("cannot create ".$dir.": $!");}

        # Si la photo n'existe pas
        if(!(-e $dir_sheet_pics."/".$pic_name))
        {
          my @splitted = split(/\./,$pic_name);
          my $ext = ".". lc($splitted[$#splitted]);
          my $filename = $splitted[0];

          if($filename ne "")
          {
            # On déplace la photo dans le dossier photos de la sheet
            copy("$data_import_config{pics_directory}/$pic_name",$dir_sheet_pics."/".$pic_name) or die "The move operation failed: $!";

            #insert linked file in database
            my %migcms_linked_file =
            (
              file        => $pic_name,
              file_dir    => $dir_sheet_pics,
              file_path   => "",            
              moment      => 'NOW()',
              table_name  => "data_sheets",
              table_field => "photos",
              token       => $data_sheet{id},
              full        => $filename,
              ext         => $ext,
              size_mini   => $data_family{mini_width},
              size_small  => $data_family{small_width},
              size_medium => $data_family{medium_width},
              size_large  => $data_family{large_width},
              size_og     => $data_family{og_width},
            );

            sql_set_data({dbh=>$dbh,table=>"migcms_linked_files",data=>\%migcms_linked_file, where=>"file != '' AND file = '$pic_name' AND table_name = 'data_sheets' AND token = '$data_sheet{id}' AND token != ''"}); 
            log_debug("[ligne $row] : Ajout de la photo $pic_name","", $debug_filename);
          }
        }
      }
      else
      {
        log_debug("[ligne $row] : Pas de photo $pic_name trouvée","", $debug_filename);
      }
    }


    # Une fois les photos ajoutées, on recrée les miniatures
    #boucle sur les images du paragraphes
    my @sizes = ('mini','small','medium','large','og');
    my @migcms_linked_files = sql_lines({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"ext IN ('.jpg','.jpeg','.png') AND table_name='data_sheets' AND table_field='photos' AND token='$data_sheet{id}'",ordby=>'ordby'});
    foreach $migcms_linked_file (@migcms_linked_files)
    {
      #appelle la fonction de redimensionnement
      my %migcms_linked_file = %{$migcms_linked_file};
      my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
      my %params = (
        migcms_linked_file=>\%migcms_linked_file,
      );
      foreach my $size (@sizes)
      {
        $params{'size_'.$size} = $data_family{$size."_width"};
      }
      dm::resize_pic(\%params);
    } 

  }
}

###########################################################
################### get_files_directory ###################
###########################################################
# Renvoit un array des fichiers présents dans un dossier 
# 
# path => Chemin vers le dossier (obligatoire) 
###########################################################
sub get_files_directory
{
  my %d = %{$_[0]};

  my @files;
  opendir (DIR, $d{path});
  while (my $file = readdir(DIR))
  {
    if($file ne "." && $file ne "..")
    {
      push  @files, $file;
    }      
  }
  closedir(DIR);

  return \@files;
}

##############################################################################
# synchro_data_sheet_related_products
##############################################################################
sub synchro_data_sheet_related_products
{
  my %d = %{$_[0]};

  my $excel_sheet = $d{excel_sheet};
  my $row = $d{row};

  log_debug("[ligne $row] : Synchro related products","", $debug_filename);

  my $reference =  get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{data_sheets}{reference}{excel_col}});

  # On récupère la sheet en DB
  my %data_sheet = sql_line({dbh=>$dbh, table=>"data_sheets", where=>"f1 = '$reference' AND f1 != ''"});

  if($data_sheet{id} > 0 && $data_import_config{gestion_related_products} eq "y")
  {    
    foreach $key (sort keys %{$data_import_config{related_products}})
    { 
      # On check si le produit associé existe
      my $reference_related_product = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{related_products}{$key}{excel_col}});
      my %data_sheet_related = sql_line({dbh=>$dbh, table=>"data_sheets", where=>"f1 = '$reference_related_product' AND f1 != ''"});

      if($data_sheet_related{id} > 0)
      {
        my %new_sheets_assoc = (
          id_data_sheet  => $data_sheet{id},
          id_assoc_sheet => $data_sheet_related{id},
        );
        sql_set_data({dbh=>$dbh, table=>"data_sheets_assoc", data=>\%new_sheets_assoc, where=>"id_data_sheet = '$data_sheet{id}' AND id_assoc_sheet = '$data_sheet_related{id}'"});
      }
    }
  }
}

##############################################################################
# synchro_data_sheet_stock
##############################################################################
sub synchro_data_sheet_stock
{
  my %d = %{$_[0]};

  my $excel_sheet = $d{excel_sheet};
  my $row         = $d{row};
  my $isVariante  = $d{isVariante};

  log_debug("[ligne $row] : synchro_data_sheet_stock","", $debug_filename);

  my $reference =  get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{data_sheets}{reference}{excel_col}});
  my $reference_stock = $reference;

  if($isVariante eq "y")
  {
    $reference = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{excel_col_reference_liaison}});
  }

  # On récupère la sheet en DB
  my %data_sheet = sql_line({dbh=>$dbh, table=>"data_sheets", where=>"f1 = '$reference' AND f1 != ''"});

  if($data_sheet{id} > 0)
  {
    # LIAISON AVEC DATA_STOCK
    
    # Récup du stock
    my $stock = 9999;
    if($data_import_config{gestion_stock} eq "y")
    {
      $stock = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{excel_col_stock}});
    }

    # Récup du poids
    my $weight=0;
    if($data_import_config{gestion_weight} eq "y")
    {
      $weight = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{excel_col_weight}});
    }

    # Récup de la tva
    my $tva = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{taux_tva}});
    if($data_import_config{taux_tva_variable} eq "y")
    {
      $tva = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{excel_col_tva}});
    }

    # Si la colonne de variante n'est pas vide,récupération de l'ID de la catégorie de variante
    my $id_data_category = 0;
    my $variante_value = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{variante_excel_col}});
    if($variante_value ne "")
    {
      my $categorie_value = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{variante_excel_col}});

      my %categoryVariante = sql_line({
        debug => 0,
        dbh => $dbh,
        select => "categories.id as id",
        table => "data_categories as categories",
        where => "LOWER(categories.f1) = LOWER('$categorie_value')
                  AND categories.f1 != ''
                  AND categories.id_data_family = '$data_import_config{id_data_family}'
                  AND id_father = '$data_import_config{id_father_categories_variante}'
                  "
      });

      $id_data_category = $categoryVariante{id};
    }

     # Selection du plus grand ordby des elements de même parent
    my %last_child = sql_line({dbh=>$dbh, table=>"data_stock", where=>"reference = '$data_sheet{f1}' AND reference != ''", ordby=>"ordby DESC", limit=>"1"});
    my $ordby_data_stock = $last_child{ordby} + 1;

    my %data_stock = (
      stock            => $stock,
      reference        => $reference_stock,
      id_data_sheet    => $data_sheet{id},
      weight           => $weight,
      tva              => $tva, 
      id_eshop_tva     => $tva,
      id_data_category => $id_data_category,
      ordby            => $ordby_data_stock,
    );

    my $id_data_stock = sql_set_data({dbh=>$dbh, table=>"data_stock", data=>\%data_stock, where=>"reference = '$data_stock{reference}' AND reference != '' AND id_data_category = '$data_stock{id_data_category}'"});

    # LIAISON AVEC DATA_STOCK_TARIF
    foreach $tarif (keys %{$data_import_config{tarifs}})
    {
      # Récupération du prix
      
      my $price = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{tarifs}{$tarif}{excel_col}});

      my $is_tvac = $data_import_config{tarifs}{$tarif}{tvac};

      my $price_htva;
      my $price_tva;
      my $price_tvac;
      # Calcul si on possède le prix tvac
      if($is_tvac eq "y")
      {
        $price_tvac = $price;
        my $tva_calcul = 1+$data_sheet{taux_tva}/100;
        $price_htva = ($price_tvac/$tva_calcul);
        $price_tva = $price_tvac - $price_htva;
      }
      # Calcul si on possède le prix htva
      else
      {
        $price_htva = $price;
        $price_tvac = $price * (1+$data_sheet{taux_tva}/100);
        $price_tva = $price_tvac - $price_htva;
      }

      my %data_stock_tarif = (
        id_data_stock => $id_data_stock,
        id_tarif      => $data_import_config{tarifs}{$tarif}{migc_id_tarif},
        id_data_sheet => $data_sheet{id},
        st_pu_htva    => $price_htva,
        st_pu_tva     => $price_tva,
        st_pu_tvac    => $price_tvac,
        taux_tva      => $data_sheet{taux_tva}/100,
      );

      sql_set_data({dbh=>$dbh, table=>"data_stock_tarif", data=>\%data_stock_tarif, where=>"id_data_stock = '$id_data_stock' AND id_tarif = '$data_stock_tarif{id_tarif}'"});
    }
  }
}

##############################################################################
# checkIfVariante
##############################################################################
sub checkIfVariante
{
  my %d = %{$_[0]}; 

  my $excel_sheet = $d{excel_sheet};
  my $row = $d{row};

  my $isVariante = "n";

  log_debug("[ligne $row] : checkIfVariante","", $debug_filename);

  my $reference =  get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{data_sheets}{reference}{excel_col}});
  my $referenceLiaison =  get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{excel_col_reference_liaison}});

  if($referenceLiaison ne "" && $reference ne $referenceLiaison)
  {
    $isVariante = "y";
    log_debug("[ligne $row] : La ligne est une variante de la référence [$referenceLiaison]","", $debug_filename);
  }

  return $isVariante;


}

##############################################################################
# synchro_data_sheet
##############################################################################
sub synchro_data_sheet
{
	my %d = %{$_[0]};

	my $excel_sheet = $d{excel_sheet};
	my $row = $d{row};

	log_debug("[ligne $row] : synchro_data_sheet","", $debug_filename);

	my $reference =  get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{data_sheets}{reference}{excel_col}});

	# On récupère une éventuelle sheet en DB
	my %data_sheet = sql_line({dbh=>$dbh, table=>"data_sheets", where=>"f1 = '$reference' AND f1 != ''"});

	if($data_sheet{id}>0)
	{
		log_debug("[ligne $row] : Sheet existante trouvée pour la référence [$reference]- id : $data_sheet{id}","", $debug_filename);		
	}
	else
	{
		log_debug("[ligne $row] : Aucune sheet existante trouvée pour la référence [$reference]","", $debug_filename);
	}

  if($data_import_config{data_type} eq "products")
  {
  	# Assignation du taux de tva
    if($data_import_config{taux_tva_variable} eq "n")
    {
      # Récupération du taux fixé dans le tableau de config
      $data_sheet{taux_tva} = $data_import_config{taux_tva};
    }
    else
    {
      # Récupération du taux dans le fichier excel pour chaque ligne
      $new_data_sheet{taux_tva} = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{excel_col_tva}});
    }
  }

  # On boucle sur les champs de la fiche renseignés dans la config pour remplir/mettre à jour la sheet
  foreach $champ (keys %{$data_import_config{data_sheets}})
  {
  	my $value = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{data_sheets}{$champ}{excel_col}});


  	# Si c'est le champ d'url rewriting
    if($data_import_config{data_sheets}{$champ}{migc_col} eq "id_textid_url_rewriting")
    {
      # Conversion au format url
      $value = clean_url($value);
    }

    # On arrondi la valeur si nécessaire
    if($data_import_config{data_sheets}{$champ}{arrondi} eq "y")
    {
      $value = round($value*100)/100;
    }

    # Si c'est le nom id_textid_meta_title
    if($data_import_config{data_sheets}{$champ}{migc_col} eq "id_textid_meta_title")
    {
      # On met les 1ères lettres de chaque mot en majuscule
      $value = lc($value);
      $value =~ s/\b(\w)/\U$1/g;
    }

    # Si c'est un champ traductible, on ajoute la value dans la
    # table des traductions et on récupère le textid
    if($data_import_config{data_sheets}{$champ}{traductible} eq "y")
    {
    	my $lg = 1;
    	my $id_textid = set_traduction({id_language => $lg, traduction=>$value, id_traduction=>$data_sheet{$data_import_config{data_sheets}{$champ}{migc_col}}});

    	# Ajout de la valeur (ou du textid) dans le hash de la fiche
      $data_sheet{$data_import_config{data_sheets}{$champ}{migc_col}} = $id_textid;
    }
    # Sinon on récupère directement la valeur
    else
    {
    	$data_sheet{$data_import_config{data_sheets}{$champ}{migc_col}} = $value;
    }
  }

  $data_sheet{visible} = "y";
  $data_sheet{id_data_family} = $data_import_config{id_data_family};

  # On détermine l'ordby de la sheet s'il n'y en a pas encore
  if(!($data_sheet{ordby} > 0))
  {
  	my %max_ordby = sql_line({dbh=>$dbh, select=>"MAX(ordby) as max_ordby", table=>"data_sheets", where=>"id_data_family = '$data_import_config{id_data_family}'"});
    if($max_ordby{max_ordby} > 0)
    {
    	$data_sheet{ordby} = $max_ordby{max_ordby} + 1;
    }
    else
    {
    	$data_sheet{ordby} = 1;
    }
  }

  $data_sheet{visible} = "y";

  # Ajout/Mise à jour de la sheet en db
  log_debug("[ligne $row] : Ajout/mise à jour de  la sheet","", $debug_filename);

  sql_set_data({dbh=>$dbh, table=>"data_sheets", where=>"id = '$data_sheet{id}'", data=>\%data_sheet});

}

##############################################################################
# synchro_data_categories
##############################################################################
sub synchro_data_categories
{
	my %d = %{$_[0]};

	my $excel_sheet = $d{excel_sheet};
	my $row = $d{row};
  my $isVariante = $d{isVariante};

  log_debug("[ligne $row] : synchro_data_categories","", $debug_filename);



	# Si la gestion des catégories est activée , on lie la fiche à une catégorie
  if($data_import_config{gestion_categorie} eq "y")
  {
    my $reference =  get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{data_sheets}{reference}{excel_col}});
    if($isVariante eq "y")
    {
      $reference = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{excel_col_reference_liaison}});
    }
    # On récupère une éventuelle sheet en DB
    my %data_sheet = sql_line({dbh=>$dbh, table=>"data_sheets", where=>"f1 = '$reference' AND f1 != ''"});

    if(!($data_sheet{id} > 0))
    {
      log_debug("[ligne $row] : Pas de sheet trouvée","", $debug_filename);
    }
    else
    {
      
      # Si la colonne de variante n'est pas vide, on crée la catégorie de variante
      my $variante_value = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{variante_excel_col}});
      if($variante_value ne "")
      {
        check_and_create_category_variante({row=>$row, excel_sheet=>$excel_sheet});
      }

      # Si la fiche n'est pas une variante, on l'associe à ses catégories
      if($isVariante ne "y")
      {
      	# On parcourt les catégories
        foreach $categorie (sort keys %{$data_import_config{categories}})
        {
          my $category_name = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{categories}{$categorie}{excel_col}});

          if($category_name ne "")
          {
            my $id_category = recursive_check_and_create_category({import_config_cat_key=>$categorie, row=>$row, excel_sheet=>$excel_sheet});
            #------------ Liaison avec sheet et categorie ------------#
            #---------------------------------------------------------#
            my %lnk_sheets_categories = (
              id_data_sheet    => $data_sheet{id},
              id_data_category => $id_category,
              id_data_family   => $data_import_config{id_data_family},
              visible          => "y",
            );

            log_debug("[ligne $row] : Sheet[$data_sheet{id}] liée avec la catégorie [$id_category]","", $debug_filename);

            my $id_lnk_sheets_categories = sql_set_data({dbh=>$dbh, table=>"data_lnk_sheets_categories", where=>"id_data_sheet = '$data_sheet{id}' AND id_data_category = '$id_category'", data=>\%lnk_sheets_categories});
      
          }             
        }
      }

      # Recalcule de la colonne id_data_categories de la sheet
      recompute_sheet_categories({id_data_sheet=>$data_sheet{id}});
    }
  }
  else
  {
  	log_debug("[ligne $row] : Gestion des catégories désactivée","", $debug_filename);
  }

}

##############################################################################
# recompute_sheet_categories
##############################################################################
sub recompute_sheet_categories
{
  my %d = %{$_[0]};

  if($d{id_data_sheet} > 0)
  {
    # Recalcule de la colonne id_data_categories sur base de la table data_sheets_lnk_categories  
    my @lnk = sql_lines({table=>"data_lnk_sheets_categories", where=>"id_data_sheet > 0 AND id_data_sheet = '$d{id_data_sheet}'"});

    my $id_data_categories = "";
    foreach $lnk (@lnk) 
    {
      $id_data_categories .= ','.$lnk->{id_data_category}. ',';
    }

    my $stmt = <<"EOH";
      UPDATE data_sheets
      SET id_data_categories = '$id_data_categories'
      WHERE id = $d{id_data_sheet}
EOH
    execstmt($dbh, $stmt);    
  }

}

sub check_and_create_category_variante
{
  my %d = %{$_[0]};

  log_debug("[ligne $row] : check_and_create_category_variante","", $debug_filename);

  my $config_categorie_key = $d{import_config_cat_key};
  my $row                  = $d{row};
  my $excel_sheet          = $d{excel_sheet};

  my $idCategoryVariante;

  # On récupère le nom de la categorie
  my $categorie_value = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{variante_excel_col}});

  # my $category_variante =

  # my $id_data_category_variante = 

  # On récupère la catégorie dont la valeur de f1 correspond au nom de la catégorie  (lg =1)
  my %categoryVariante = sql_line({
    debug => 0,
    dbh => $dbh,
    select => "categories.id as id",
    table => "data_categories as categories",
    where => "LOWER(categories.f1) = LOWER('$categorie_value')
              AND categories.f1 != ''
              AND categories.id_data_family = '$data_import_config{id_data_family}'
              AND id_father = '$data_import_config{id_father_categories_variante}'
              "
  });

  if($categoryVariante{id} > 0)
  {
    # La catégorie existe déjà
    $idCategoryVariante = $categoryVariante{id};
    log_debug("[ligne $row] : La catégorie [$categorie_value] existe déjà [$idCategoryVariante]","", $debug_filename);
  }
  else
  {
    # La catégorie n'existe pas encore
    # On créé la catégorie
    log_debug("[ligne $row] : La catégorie [$categorie_value] n'existe pas. On la crée","", $debug_filename);
    my $name_formate = lc($categorie_value);
    $name_formate =~ s/\b(\w)/\U$1/g;

    my $id_textid_name = set_traduction({id_language => 1, traduction=>$name_formate});
    my $id_textid_meta_title = set_traduction({id_language => 1, traduction=>$name_formate});

    # url
    $url = clean_url($name_formate);

    my $id_textid_url_rewriting = set_traduction({id_language => 1, traduction=>$url});

    # Selection du plus grand ordby des elements de même parent
    my %last_child = sql_line({dbh=>$dbh, table=>"data_categories", where=>"id_data_family = '$data_import_config{id_data_family}' AND id_father = '$data_import_config{id_father_categories_variante}'", ordby=>"ordby DESC", limit=>"1"});
    my $ordby_category = $last_child{ordby} + 1;
    
    my %new_data_categories = (
      f1                      => "$categorie_value",
      visible                 => "y",
      id_father               => $data_import_config{id_father_categories_variante},
      id_data_family          => $data_import_config{id_data_family},
      id_textid_name          => $id_textid_name,
      id_textid_meta_title    => $id_textid_meta_title,
      id_textid_url_rewriting => $id_textid_url_rewriting,
      ordby                   => $ordby_category,
      variante                => "y",
    );


    $idCategoryVariante = inserth_db($dbh, "data_categories", \%new_data_categories);
    log_debug("[ligne $row] : La catégorie [$categorie_value] a été créée [$idCategoryVariante]","", $debug_filename);
  }

  return $idCategoryVariante;

}


####################### SYNCHRONISATION & BACKUP ###############################
#-------------------------------------------------------------------------------
# recursive_check_and_create_category - Crée les catégories
# Params : $_[0] -> clé de la catégorie dans le tableau de config
#          $_[1] -> ligne courante du fichier excel
#-------------------------------------------------------------------------------
sub recursive_check_and_create_category
{
	my %d = %{$_[0]};

	my $config_categorie_key = $d{import_config_cat_key};
	my $row                  = $d{row};
	my $excel_sheet          = $d{excel_sheet};

  # On récupère le nom de la categorie
  my $categorie_value = get_excel_value({excel_sheet=>$excel_sheet, row=>$row, col=>$data_import_config{categories}{$config_categorie_key}{excel_col}});

  # Si la catégorie a un parent, on ajoute la condition id_father au where
  my $additionnal_where = "";
  # Parent fixe
  if($data_import_config{categories}{$config_categorie_key}{id_father_fixe} ne "")
  {
    $additionnal_where = " AND id_father = $data_import_config{categories}{$config_categorie_key}{id_father_fixe}";
  }
  # Parent créé dynamiquement via la synchro
  elsif($data_import_config{categories}{$config_categorie_key}{father} ne "")
  {
    my $id_category_parent = recursive_check_and_create_category({import_config_cat_key=>$data_import_config{categories}{$config_categorie_key}{father}, row=>$row, excel_sheet=>$excel_sheet});
    $additionnal_where = " AND id_father = $id_category_parent";
  }

  # On récupère la catégorie dont la valeur de f1 correspond au nom de la catégorie  (lg =1)
  my %categorie = sql_line({
    debug => 0,
    dbh => $dbh,
    select => "categories.id as id, txtcontents.lg1",
    table => "data_categories as categories, txtcontents",
    where => "LOWER(categories.f1) = LOWER('$categorie_value')
              AND categories.f1 != ''
              AND categories.id_data_family = '$data_import_config{id_data_family}'
              $additionnal_where
              "
  });

  # La catégorie n'existe pas
  if($categorie{id} <= 0)
  { 
    # Si elle a un parent fixe, on récupère son ID
    if($data_import_config{categories}{$config_categorie_key}{id_father_fixe} ne "")
    {
      $id_father = $data_import_config{categories}{$config_categorie_key}{id_father_fixe};
    }
    # Si elle a un parent dynamique (créé par la synchro), on récupère son ID
    elsif($data_import_config{categories}{$config_categorie_key}{father} ne "")
    {
      $id_father = recursive_check_and_create_category({import_config_cat_key=>$data_import_config{categories}{$config_categorie_key}{father}, row=>$row, excel_sheet=>$excel_sheet});
    }
    else
    {
      # Sinon on lui met celui par défaut ou 0
      if($data_import_config{id_categorie_parent} ne "")
      {
        $id_father = $data_import_config{id_categorie_parent};
      }
      else
      {
        $id_father = 0;                
      }
    }

    # On créé la catégorie
    my $name_formate = lc($categorie_value);
    $name_formate =~ s/\b(\w)/\U$1/g;

    my $id_textid_name = set_traduction({id_language => 1, traduction=>$name_formate});
    my $id_textid_meta_title = set_traduction({id_language => 1, traduction=>$name_formate});

    # url
    $url = clean_url($name_formate);

    my $id_textid_url_rewriting = set_traduction({id_language => 1, traduction=>$url});

    # Selection du plus grand ordby des elements de même parent
    my %last_child = sql_line({dbh=>$dbh, table=>"data_categories", where=>"id_data_family = '$data_import_config{id_data_family}' AND id_father = '$id_father'", ordby=>"ordby DESC", limit=>"1"});
    my $ordby_category = $last_child{ordby} + 1;
    
    my %new_data_categories = (
      f1                      => "$categorie_value",
      visible                 => "y",
      id_father               => $id_father,
      id_data_family          => $data_import_config{id_data_family},
      id_textid_name          => $id_textid_name,
      id_textid_meta_title    => $id_textid_meta_title,
      id_textid_url_rewriting => $id_textid_url_rewriting,
      ordby                   => $ordby_category,
    );

    $id_category = inserth_db($dbh, "data_categories", \%new_data_categories);

  }
  else
  {
    $id_category = $categorie{id};
  }

  return $id_category;

}

sub get_script
{
  my $script = <<"HTML";
    <script src="$config{fullurl}/mig_skin/js/jquery.form.js"></script>
    <script type="text/javascript">
      jQuery(function(){

        jQuery('#submit_form').on('click',function(e){
            e.preventDefault();

            swal({   
             title: "Synchroniser ?",   
             text: "<div class='progress '><div class='progress-bar progress-striped' style='width: 0%; background-color:#5cb85c'></div></div>",   
             html:true,
             showCancelButton: true,   
             confirmButtonColor: "#5cb85c",   
             confirmButtonText: "Oui, synchroniser",   
             cancelButtonText: "$migctrad{publish_action_2}",   
             closeOnConfirm: false,   
             closeOnCancel: true }, 
             function(isConfirm)
             {
              if(isConfirm)
              {
                var timeId = 0;

                var options = {
                  // Avant l'envoi
                  beforeSubmit: function(){
                    // Récupération du token de la synchro
                    var synchro_token = jQuery("#synchro_token").val();
                    jQuery("#progressbar .ui-progressbar-value").css("display", "block");

                    jQuery("#import_data_form button").prop("disabled",true);
                    jQuery(".sa-button-container").hide();
                    jQuery(".showSweetAlert h2").empty().text("Synchronisation en cours...");

                    timerId = setInterval(function(){
                      get_synchro_progress(synchro_token);
                    }, 2000);
                  },
                  // Quand l'import est fini
                  success: function(response)
                  {
                    jQuery('#import_data_form')[0].reset();
                    jQuery("#progressbar .ui-progressbar-value").css("width", "100%");
                    clearInterval(timerId);
                    jQuery(".sa-button-container").show();
                    
                    var message;
                    var type;
                    if(response == 1)
                    {
                      message = "Merci de compléter tous les champs requis";
                      type = "error";
                    }
                    else if(response == 2)
                    {
                      message = "Une erreur est survenue lors de l'upload du fichier";
                      type = "error";
                    }
                    else if(response == 3)
                    {
                      message = "Merci de d'abord uploader un fichier d'import";
                      type = "error";
                    }
                    else if(response == 4)
                    {
                      message = "Erreur de matching : Colonne(s) manquante(s)";
                      type = "error";
                    }
                    else if(response == 0)
                    {
                      message = "Mise à jour effectuée";
                      type = "success";
                    }
                    else
                    {
                      message = "Une erreur est survenue";
                      type = "error";
                    }              

                      swal(
                      {
                        title: message,
                        text: "",
                        type: type,
                        showCancelButton: false,
                        confirmButtonColor: "#406C9C",
                        confirmButtonText: "Continuer",
                        closeOnConfirm: true,
                      },
                      function(isConfirm)
                      {
                        if(isConfirm) 
                        {
                          var rand = function() {
                              return Math.random().toString(36).substr(2); // remove `0.`
                          };

                          var token = function() {
                              return rand() + rand(); // to make it longer
                          };

                          var token = token();
                          jQuery("#synchro_token").attr("value", token);
                          jQuery("#progressbar .ui-progressbar-value").css("width", "0%");
                          

                          // Réactivation du bouton de synchro
                          jQuery("#import_data_form button").prop("disabled", false);
                        }
                      }); 
                    }           

                }
                
                jQuery('#import_data_form').ajaxForm(options);        
                jQuery("#import_data_form").submit();                
              }
          });      

      });
});

      function get_synchro_progress(token)
      {
        jQuery.ajax(
        {
          type: "POST",
          url: '$dm_cfg{self}',
          data: {
            token : token,
            sw : "ajax_get_synchro_progress",
          },
          dataType:"html",
          success: function(msg)
          {
            if(msg != "ko")
            {
              jQuery(".progress .progress-bar").css("width", msg + "%");
            }
            
          }
        });
      }

    </script>
HTML

  return $script;
}

####################################################
################### init_synchro ###################
####################################################
# Ecriture en DB du début de la synchro
# Sauvegarde du nombre de lignes total à traiter
####################################################
sub init_synchro_progress
{
  my %d = %{$_[0]};

  my %new_synchro = (
    synchro_type         => $d{type},
    synchro_file         => $d{file},
    migcms_moment_create => 'NOW()',
    total_rows           => $d{nbr_rows},
    executed_rows        => 0,
    token                => $d{token},
  );

  my $id_synchro_progress = inserth_db($dbh, "migcms_data_synchro", \%new_synchro);

  return $id_synchro_progress;

}

#################################################################
################### ajax_get_synchro_progress ###################
#################################################################
# Renvoit le pourcentage de lignes traitées par rapport au total
#################################################################
sub ajax_get_synchro_progress
{
  
  my $token = get_quoted("token");

  # Récupération de la synchro en cours
  my %synchro = sql_line({dbh=>$dbh, table=>"migcms_data_synchro", where=>"token = '$token'"});

  my $msg = "ko";
  if($synchro{id} > 0)
  {
    my $pourcentage_accompli = $synchro{executed_rows}/$synchro{total_rows}*100;
    $msg = $pourcentage_accompli;
  }

  print $msg;
  exit;
}

######################################################
################### update_synchro ###################
######################################################
# Mise à jour en DB du nombre de champ traité
######################################################
sub update_synchro_progress
{
  my %d = %{$_[0]};

  if($d{id_synchro} > 1)
  {
    my $stmt = <<"SQL";
    UPDATE migcms_data_synchro
      SET executed_rows = executed_rows + 1
      WHERE id = '$d{id_synchro}'
SQL

    execstmt($d{dbh}, $stmt);    
  }

}


