#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use def_handmade;






$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{excel} = 1;
$dm_cfg{show_id} = 1;
$dm_cfg{table_name} = "handmade_certigreen_reglements";
$dm_cfg{default_ordby} = "id desc";
my $id_facture = get_quoted('id_facture');


$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?id_facture=$id_facture";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{before_del_func} = \&before_del;
# $dm_cfg{upload_file_size_min} = 600;
$dm_cfg{after_upload_ref} = \&after_upload;
$dm_cfg{validation_func} = \&validation_func;

$dm_cfg{autocreation} = 0;

$dm_cfg{hiddp}=<<"EOH";
EOH

$dm_cfg{html_top} .=<<"EOH";
<span id="infos_rec"></span>
<script type="text/javascript">
jQuery(document).ready(function() 
{
	jQuery('.maintitle,.breadcrumb').hide();
	jQuery(document).on("click", ".dm_migedit", dm_migedit_members);
	jQuery(document).on("click", ".cancel_edit ", removenomexposant);
	jQuery(document).on("click", ".admin_edit_save ", removenomexposant);
});


function dm_migedit_members()
{
	
	jQuery('#infos_rec').html('...');
	jQuery('#infos_rec').removeClass('hide');
	jQuery.ajax(
	  {
		 type: "POST",
		 url: self,
		 data: "&sw=ajax_infos_rec&t=$dm_cfg{table_name}&id="+jQuery(this).attr('id'),
		 success: function(msg)
		 {
			jQuery('#infos_rec').html(msg);	
		 }
	  });	
		  
}

function removenomexposant()
{
	jQuery('#infos_rec').html('');
}
</script>


EOH

my $cpt = 9;


my $montantDefaut = "";
if($id_facture > 0)
{
	$dm_cfg{wherel} = $dm_cfg{wherep} ="id_facture='$id_facture'";

	my $totalRestant = 0;
	my %commande = read_table($dbh,'intranet_factures',$id_facture);
	my %totalReglements = sql_line({select=>"SUM(montant) as total",table=>"$dm_cfg{table_name}",where=>"id_facture='$id_facture'"});

	$montantDefaut = $commande{montant_a_payer_tvac};
	if($totalReglements{total} > 0)
	{
		$montantDefaut -= $totalReglements{total};
	}

	$montantDefaut = sprintf("%.2f", $montantDefaut);
}   


%dm_dfl = 
(
	sprintf("%03d", $cpt++).'/date_reglement'=>{'title'=>"Date",'translate'=>0,'fieldtype'=>'text','data_type'=>'date','search' => 'y','mandatory'=>{"type" => 'not_empty'},'tab'=>$tab,'default_value'=>$today,'lbtable'=>'users','lbkey'=>'id','lbdisplay'=>"CONCAT(firstname,' ',lastname)",'lbwhere'=>"id_role > 1 OR initiales != ''",'lbordby'=>"firstname,lastname",'fieldvalues'=>'','hidden'=>0},
	# sprintf("%03d", $cpt++).'/id_member'=>{'title'=>"Client",'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'members','lbkey'=>'id','lbdisplay'=>"fusion_short",'lbwhere'=>"",'lbordby'=>"fusion_short",'fieldvalues'=>'','hidden'=>0},
	sprintf("%03d", $cpt++).'/id_facture'=>{'title'=>"Numéro de facture",'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => 'not_empty'},'tab'=>$tab,'default_value'=>'','lbtable'=>'intranet_factures','lbkey'=>'id','lbdisplay'=>"fusion_facture",'lbwhere'=>"numero_facture>0",'lbordby'=>"numero_facture desc",'fieldvalues'=>'','hidden'=>0},
	sprintf("%03d", $cpt++).'/montant'=>{'default_value'=>$montantDefaut,'title'=>"Montant",'translate'=>0,'fieldtype'=>'text','data_type'=>'euros','search' => 'y','mandatory'=>{"type" => 'not_empty'},'tab'=>$tab,'lbtable'=>'intranet_factures','lbkey'=>'id','lbdisplay'=>"CONCAT('Facture N°',id,' ',nom_f,' ',montant_total_htva,'€')",'lbwhere'=>"",'lbordby'=>"fusion_short",'fieldvalues'=>'','hidden'=>0},
	sprintf("%03d", $cpt++).'/id_type_reglement'=>{'title'=>"Type de règlement",'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'y','mandatory'=>{"type" => 'not_empty'},'tab'=>$tab,'default_value'=>'','lbtable'=>'handmade_certigreen_statuts_reglement','lbkey'=>'id','lbdisplay'=>"nom",'lbwhere'=>"id != 5",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
	
);

%dm_display_fields = 
(
	sprintf("%03d", $cpt++).'/Date'=>"date_reglement",
	# sprintf("%03d", $cpt++).'/Client'=>"id_member",
	sprintf("%03d", $cpt++).'/Facture'=>"id_facture",
	sprintf("%03d", $cpt++).'/Montant'=>"montant",
	sprintf("%03d", $cpt++).'/Type de règlement'=>"id_type_reglement",
);

%dm_lnk_fields = 
(
);

%dm_mapping_list = (
);

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

    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}



sub after_save
{
    my $dbh = $_[0];
    my $id = $_[1];
	my %reglement = sql_line({table=>'handmade_certigreen_reglements',where=>"id='$id'"});
	def_handmade::set_statut_facture_from_reglements($reglement{id_facture});
}


sub before_del
{
#    my $dbh = $_[0];
    my $id = $_[1];

    my %reglement = sql_line({table=>'handmade_certigreen_reglements',where=>"id='$id'"});
    log_debug($reglement{id},'','before_del');
    log_debug($reglement{id_facture},'','before_del');

    my $stmt = <<"EOH";
		UPDATE handmade_certigreen_reglements SET id_facture = 0 WHERE id = '$id'
EOH
    log_debug($stmt,'','before_del');
    execstmt($dbh,$stmt);

    def_handmade::set_statut_facture_from_reglements($reglement{id_facture});
}


sub validation_func
{
    my $dbh=$_[0];
    my %item = %{$_[1]};
    my $id = $_[2];

    log_debug('validation_func','','validation_func_reglements');

        my $rapport = '';
        my $valide = 1;

        if(!$item{id_type_reglement} > 0)
        {
            $valide = 0;
            $rapport .=<<"EOH";
				<tr><td><i class="fa fa-times"></i>Type de règlement </td><td>Manquant.</td></tr>
EOH
        }
        my %commande = read_table($dbh,'intranet_factures',$item{id_facture});


    if(!($item{montant} > 0))
    {
        $valide = 0;
        $rapport .=<<"EOH";
				<tr><td><i class="fa fa-times"></i>Montant </td><td>Doit être nombre positif.</td></tr>
EOH
    }


        #montant total facture
        my $montant_total_facture =  $commande{montant_a_payer_tvac};

        #montant restant avec les autres reglements
        my %totalReglements = sql_line({select=>"SUM(montant) as total",table=>"$dm_cfg{table_name}",where=>"id_facture='$item{id_facture}' and id !='$id'"});
        my $montant_restant_avec_autres_reglements =  $totalReglements{total};

        #montant restant avec ce reglement
        my $montant_restant_avec_ce_reglement =  $montant_restant_avec_autres_reglements + $item{montant};

        #montant autorisé
        my $montant_autorise = $montant_total_facture - $montant_restant_avec_autres_reglements;



    $montant_total_facture = sprintf("%.2f", $montant_total_facture);
    $montant_restant_avec_autres_reglements = sprintf("%.2f", $montant_restant_avec_autres_reglements);
    $montant_restant_avec_ce_reglement = sprintf("%.2f", $montant_restant_avec_ce_reglement);
    $montant_autorise = sprintf("%.2f", $montant_autorise);

        if($montant_restant_avec_ce_reglement > $montant_total_facture)
        {
            $valide = 0;
            $rapport .=<<"EOH";
				<tr><td><i class="fa fa-times"></i>Montant </td><td>Le montant <b>$item{montant} €</b> est trop élévé: Maximum autorisé: <b>$montant_autorise €</b> </b>
				</td></tr>
EOH
        }


        if($rapport ne '')
        {
            log_debug('rapport:'.$rapport,'','validation');

            $rapport =<<"EOH";
			<h5><i class="fa fa-info"></i> Avant de sauvegarder,vous devez compléter certaines informations obligatoires pour les contacts d'<u>Alias Consult</u>:</h5>
			<table class="table table-hover table-striped table-bordered">
				<thead>
					<tr>
						<th>Onglet > champs</th>
						<th>Action à entreprendre</th>
					</tr>
				</thead>
				<tbody>
					$rapport
				</tbody>
			</table>
EOH

            return 'validation_error___'.$rapport;
        }
        else
        {
            return '';
        }

}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

