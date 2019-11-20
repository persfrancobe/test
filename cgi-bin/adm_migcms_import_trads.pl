#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

         # migc translations
use sitetxt;

use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::FmtUnicode;
use Spreadsheet::WriteExcel;
use Encode;
use HTML::Entities;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		###############################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

my %import_config = (
    upload_path => "../usr",
);

my $lignes_imported = 0;



$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{table_width} = 1100;
$dm_cfg{fieldset_width} = 1100;
$dm_cfg{self} = "$htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/adm_migcms_import_trads.pl?";
$dm_cfg{hiddp} = <<"EOH";

EOH

$dm_cfg{help_url} = "http://www.bugiweb.com";

$sw = $cgi->param('sw') || "import_trads_form_step_1";

see();

my @fcts = qw(
			import_trads_form_step_1
            import_trads_form_step_1_db
            import_trads_form_step_2
            import_trads_form_step_2_db
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


################################################################
################### import_trads_form_step_1 ###################
################################################################
# Etape une du formulaire d'import
################################################################
sub import_trads_form_step_1
{
    $dm_output{content} = <<"HTML";

    <div class="wrapper">

        <div class="row">
            <div class="col-md-6">
                <h1 class="maintitle">Import des traductions</h1>
            </div>
        </div>

        <section class="panel">
            <!-- Body -->
            <div class="panel-body">
                <div class="panel panel-success">
                    <div class="panel-heading">
                        <i class="fa fa-cloud-upload"></i> Importer des traductions (.xls)
                    </div>
                    <div class="panel-body">
                        <form action="$dm_cfg{self}" method="POST" enctype="multipart/form-data">
                            <input type="hidden" name="sw" value="import_trads_form_step_1_db" class="sw_mod_db" />    
                            <input type="file" id="field_import_excel" name="import_excel" class="mig_input_file" required />
                            <br/>
                            <button type="submit" class="btn btn-lg btn-success">Etape suivante</button>
                        </form>
                    </div>
                </div>
            </div>
        </div>

    </div>
HTML

    return $dm_output{content};
}

###################################################################
################### import_trads_form_step_1_db ###################
###################################################################
# Upload du fichier et redirection vers étape 2
###################################################################
sub import_trads_form_step_1_db {
    my $file = $cgi->param("import_excel");

    my $code_error = 0;
    my ($file_url, $size);

    # upload du fichier 
    if($file ne "")
    {
        ($file_url,$size) = upload_file($file, $import_config{upload_path});

        if($file_url eq "" || $size eq "")
        {
            # Erreur lors de l'upload
            $code_error = 2;            
        }

    }
    else
    {
        # Pas de fichier envoyé
        $code_error = 1;
    }

    # Si pas d'erreur on redirige vers l'étape 2
    if($code_error == 0)
    {
        http_redirect("$dm_cfg{self}&sw=import_trads_form_step_2&file_url=$file_url");
    }
    else
    {
        display_error_message($code_error);
    }    

}


################################################################
################### import_trads_form_step_2 ###################
################################################################
# Etapes deux du formulaire
# 
# quoted: "file_url" => nom du fichier uploadé 
################################################################
sub import_trads_form_step_2 {
    
    my $file_url = get_quoted("file_url");

    my $code_error = 0;

    if($file_url eq "")
    {
        # Etape 1 pas complétée
        $code_error = 3;
    }


    if($code_error == 0)
    {
        my @languages = sql_lines({table=>'migcms_languages',where=>"visible='y' OR encode_ok = 'y'"});

        my $outfile = $import_config{upload_path}."/".$file_url;
        my $parser   = Spreadsheet::ParseExcel->new();
        my $workbook = $parser->parse($outfile);

        if ( !defined $workbook ) {
            die $parser->error(), ".\n";
        }       

        
        # On parcourt les pages du fichier excel
        # On sauvegarde dans un hash le nom de chaque page avec son numéro de page
        my $page_nbr = 0;
        my %worksheets_infos;
        for my $worksheet ($workbook->worksheets()) 
        {
            my $worksheet_name = encode("utf8", $worksheet->get_name());
            $worksheets_infos{$page_nbr} = $worksheet_name;

            $page_nbr++;            
        }

        # Récupération des options pour les listes des lettres de l'alphabet
        my $alphabetics_options = get_alphabetic_options();

        # On parcourt le hash des pages
        # Pour chaque page on crée un block du formulaire
        my $form_step_2 = "";
        foreach $worksheet (sort keys %worksheets_infos)
        {
            my $logique_options = get_logique_options();


            # Pour chaque langue active, on ajoute un select
            my $select_languages;
            foreach $language (@languages)
            {   
                %language = %{$language};
                
                $select_languages .= <<"HTML";
                <div class="form-group">
                    <label class="col-sm-3 control-label">Colonne $language{display_name}</label>
                    <div class="col-sm-9">             
                        <select name="col_$language{name}_$worksheet" class="form-control" required />
                            <option value="-1" selected >Ne pas importer la colonne</option>
                            $alphabetics_options
                        </select>
                    </div>
                </div>
HTML
            }

            # BLOCK DU FORMULAIRE
            $form_step_2 .= <<"HTML";
                <div class="panel-body">
                    <div class="panel panel-info">
                        <div class="panel-heading">
                            $worksheets_infos{$worksheet}
                        </div>
                        <div class="well">
                            <div class="form-group">
                                <label class="col-sm-3 control-label">Type de page</label>
                                <div class="col-sm-9">
                                    <select name="worksheet_$worksheet" class="form-control get_logique_options" required />
                                        $logique_options
                                    </select>
                                </div>
                            </div>
                            <div class="form-group">
                                <label class="col-sm-3 control-label">Colonne de l'identifiant</label>
                                <div class="col-sm-9">
                                    <select name="col_id_$worksheet" class="form-control get_logique_options" required />
                                        <option value='-1' selected >Ne pas importer la page</option>
                                        $alphabetics_options
                                    </select>
                                </div>
                            </div>
                            $select_languages
                            <div class="form-group">
                                <label class="col-sm-3 control-label">Ne pas écraser une valeur existante</label>
                                <div class="col-sm-9">
                                    <input type="checkbox" name="do_not_override_existing_trad_$worksheet" value="y" class="form-control">
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

HTML
        }

        


         $dm_output{content} = <<"HTML";

          <div class="wrapper">

            <div class="row">
                <div class="col-md-6">
                    <h1 class="maintitle">Import des traductions</h1>
                </div>
            </div>

            <section class="panel">
            <!-- Body -->
            <div class="panel-body">
                <div class="panel panel-success">
                    <div class="panel-heading">
                        <i class="fa fa-cloud-upload"></i> Importer des traductions (.xls)
                    </div>
                </div>
            </div>

            <form class="form-horizontal adminex-form" action="$dm_cfg{self}" method="GET">
                <input type="hidden" name="file_url" value="$file_url" class="sw_mod_db" />
                <input type="hidden" name="sw" value="import_trads_form_step_2_db" class="sw_mod_db" />

                $form_step_2
                <br>
                <button type="submit" class="btn btn-lg btn-success">Importer les traductions</button>

            </form>
        </div>
HTML

        return $dm_output{content};
    }
    else
    {
        display_error_message($code_error);
    }
}

###################################################################
################### import_trads_form_step_2_db ###################
###################################################################
# Import des traductions
#
###################################################################
sub import_trads_form_step_2_db
{
    my $file_url = get_quoted("file_url");

    my $code_error = 0;
    


    if($file_url eq "")
    {
        # Etape 2 pas complétée
        $code_error = 3;
    }

    if($code_error == 0)
    {
        

        my $outfile = $import_config{upload_path}."/".$file_url;
        my $parser   = Spreadsheet::ParseExcel->new();
        my $workbook = $parser->parse($outfile);

        if ( !defined $workbook ) {
            die $parser->error(), ".\n";
        } 

        my @languages = sql_lines({table=>'migcms_languages',where=>"visible='y' OR encode_ok = 'y'"});
        
        # On parcourt les pages du fichier excel
        # On crée le tableau de configuration de l'import
        my $worksheet_number = 0;
        my %worksheets_infos;
        for my $worksheet ($workbook->worksheets()) 
        {
            my $worksheet_name = encode("utf8", $worksheet->get_name());

            $worksheets_infos{$worksheet_number}{name} = $worksheet_name;
            # Récupération du type d'import
            $worksheets_infos{$worksheet_number}{type} = get_quoted("worksheet_$worksheet_number");
            # Récupération de la colonne de l'identifiant
            $worksheets_infos{$worksheet_number}{col_identifiant} = get_quoted("col_id_$worksheet_number");
            # Récupération du souhait d'écraser une traduction existante ou non
            $worksheets_infos{$worksheet_number}{override_existing_trad} = get_quoted("do_not_override_existing_trad_$worksheet_number");

            # Pour chaque langue, récupération de la colonne
            foreach $language (@languages)
            {   
                %language = %{$language};
                
                $worksheets_infos{$worksheet_number}{languages}{$language{name}}{id_language} = $language{id};
                $worksheets_infos{$worksheet_number}{languages}{$language{name}}{col} = get_quoted("col_$language{name}_$worksheet_number");
            }

            $worksheet_number++;            
        }




        
        # On parcourt chaque page du tableau de config
        foreach $page (sort keys %worksheets_infos)
        {
            if($worksheets_infos{$worksheet_number}{col_identifiant} != -1)
            {
               my $table_to_import;
                # Import de contenu normal
                if ($worksheets_infos{$page}{type} eq "txtcontents")
                {
                    $table_to_import = "txtcontents";
                }
                # Import de textes de la boutique
                elsif ($worksheets_infos{$page}{type} eq "eshop_txts")
                {
                    $table_to_import = "eshop_txts";
                }
                # Import de textes spécifiques
                elsif ($worksheets_infos{$page}{type} eq "sitetxt")
                {
                    $table_to_import = "sitetxt";
                }


                if($table_to_import ne "")
                {
                    # on boucle sur les langues de la page
                    foreach $language (sort keys %{$worksheets_infos{$page}{languages}})
                    {

                        # On récupère la colonne de la langue et de l'identifiant
                        my $col_to_import = $worksheets_infos{$page}{languages}{$language}{col};
                        my $col_identifiant = $worksheets_infos{$page}{col_identifiant};

                        # Si la valeur de la colonne à importer est différente de -1, on importe les éléments de la langue
                        if($col_to_import != -1 )
                        {
                            my $worksheet = $workbook->worksheet($page);
                            my $row = 1;
                            my $row_max = $worksheet->row_range();

                            # On boucle sur les lignes du fichier excel
                            while ($row <= $row_max)
                            {    
                                my $cell = $worksheet->get_cell($row, $col_to_import);
                                my $cell_identifiant = $worksheet->get_cell($row, $col_identifiant);
                                if($cell ne "" && $cell_identifiant ne "")
                                {
                                    my $traduction = trim(encode("utf8",$cell->value()));
                                    $traduction = decode_entities($traduction);
                                    $traduction =~ s/\'/\\\'/g;

                                    my $identifiant = trim(encode("utf8",$cell_identifiant->value()));
                                    $identifiant = decode_entities($identifiant);

                                    # print "$row -> $traduction<br/>";
                                    if($identifiant > 0)
                                    {
                                      import_traduction_db($identifiant, $traduction, $table_to_import, $worksheets_infos{$page}{languages}{$language}{id_language}, $worksheets_infos{$page}{override_existing_trad} );
                                    }

                                }
                                

                                $row++;
                            }

                        }
                    }
                } 
            }       
         
            
        }


        
        $dm_output{content} = <<"HTML";
        <div class="wrapper">
            <div class="row">
                <div class="col-md-6">
                    <h1 class="maintitle">Import des traductions</h1>
                </div>
            </div>

            <section class="panel">
                <!-- Body -->
                <div class="panel-body">
                    <div class="panel panel-success">
                        <div class="panel-heading">
                            <i class="fa fa-check"></i> Import des traductions terminé !
                        </div>
                        <div class="panel-body">
                             <p>Nombre de cellules importées : $lignes_imported</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
           
HTML

        return $dm_output{content};

        
    }
    else
    {
        display_error_message($code_error);
    }
}

############################################################
################### import_traduction_db ###################
############################################################
# Import de la traduction en DB
#
############################################################
sub import_traduction_db 
{
    my $id                     = $_[0];
    my $trad                   = $_[1];
    my $table                  = $_[2];
    my $id_language            = $_[3];
    my $do_not_override_existing_trad = $_[4];

    my %data;
    my $return_value;


    my $do_import = "y";

    my %donnees = (
      "lg".$id_language     => $trad,
      type => "blocs",
      id_txtcontent => $id,
    );

    sql_set_data({dbh=>$dbh, table=>"traductions", data=>\%donnees, where=>"id_txtcontent = $id"});
   



    # On vérifie si une entrée existe déjà dans une langue
    # my $where = "id = '$id'";
    # my %existing_value = sql_line({dbh=>$dbh, table=>$table, where=>$where});

    # if($existing_value{id} > 0)
    # {
    #   # On a choisi de ne pas écraser les valeurs existantes, on vérifie qu'une traduction existe
    #   # avant d'ajouter
    #   if($do_not_override_existing_trad eq "y")
    #   {
         
          
    #       my $colg = "lg" . $id_language;   
    #       if($existing_value{content} ne "" || $existing_value{$colg} ne "")
    #       {
    #           $do_import = "n";
    #       }
    #   }

    #   if($do_import eq "y")
    #   {
    #       my $autre;
    #       my %data = ();
    #       if($table eq "txtcontents")
    #       {
    #           %data = (
    #               "lg".$id_language     => $trad,
    #               migcms_moment_last_edit  => "NOW()",               

    #           );
              
    #       }
    #       elsif($table eq "eshop_txts" || $table eq "sitetxt")
    #       {
    #           %data = (
    #               "lg".$id_language => $trad,
    #               visible => 'y',
                 
    #           ); 

    #            $autre = 1;           
    #       }

         

    #       $return_value = sql_set_data({dbh=>$dbh,debug=>0, table=>$table,data=>\%data,where=>"id='$id'"});


    #       if($return_value > 0)
    #       {
    #           $lignes_imported++;
    #       }
    #   }
      
    # }
   



}


##############################################################
################### get_alphabetic_options ###################
##############################################################
# Renvoit les options d'un select avec choix des lettres
# de l'alphabet
#
##############################################################
sub get_alphabetic_options {
    
    my %alpabetics_value = (
         "A" => 0 ,
         "B" => 1 ,
         "C" => 2 ,
         "D" => 3 ,
         "E" => 4 ,
         "F" => 5 ,
         "G" => 6 ,
         "H" => 7 ,
         "I" => 8 ,
         "J" => 9 ,
         "K" => 10,
         "L" => 11,
         "M" => 12,
         "N" => 13,
         "O" => 14,
         "P" => 15,
         "Q" => 16,
         "R" => 17,
         "S" => 18,
         "T" => 19,
         "U" => 20,
         "V" => 21,
         "W" => 22,
         "X" => 23,
         "Y" => 24,
         "Z" => 25,
    );

    foreach $key (sort keys %alpabetics_value)
    {
        $options .= <<"HTML";
            <option value="$alpabetics_value{$key}">$key</option>
HTML
    }

    return $options;
}


###########################################################
################### get_logique_options ###################
###########################################################
# Renvoit les options du select de choix de logique à appliquer
#
###########################################################
sub get_logique_options
{
    my %d = %{$_[0]};

    my $options = <<"HTML";
        <option value=" " selected>Ne pas importer la page</option>
        <option value="txtcontents">Autre type</option>
        <option value="sitetxt">Textes spécifiques</option>
        <option value="eshop_txts">Textes pour la boutique</option>
HTML

    return $options;
}


#############################################################
################### display_error_message ###################
#############################################################
# Affiche un message d'erreur et met fin au script
#
# Params : 1 => le code d'erreur
# 
# Erreur 1 => Champs requis
# Erreur 2 => Erreur upload fichier

#############################################################
sub display_error_message
{
    my $erreur_code = $_[0] || 1;

    
    my $message;
    use Switch;
    switch ($erreur_code)
    {
        case 1 
        {
            $message = "Merci de compléter tous les champs requis";
        }
        case 2 
        {
            $message = "Une erreur est survenue lors de l'upload du fichier";
        }
        case 3
        {
            $message = "Merci de d'abord uploader un fichier d'import";
        }

    }

    $dm_output{content} = <<"HTML";
        <link rel="stylesheet" type="text/css" href="mig_skin/css/sweet-alert.css">
        <script src="mig_skin/js/sweet-alert.min.js"></script>
        <script language="javascript">
            jQuery(document).ready(function(){
                sweetAlertInitialize();
                sweetAlert({
                    title :"Oops...",
                    text : "$message",
                    type : "error",
                },
                function(isConfirm){
                    history.go(-1);
                });
                
            })        
        </script>
HTML

    return $dm_output{content};


}
