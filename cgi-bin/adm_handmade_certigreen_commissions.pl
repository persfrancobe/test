#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use def_handmade;


$dm_cfg{customtitle} = $fwtrad{users_title};
$dm_cfg{enable_search} = 1;
$dm_cfg{deplie_recherche} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "handmade_certigreen_commissions";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_handmade_certigreen_commissions.pl?";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_import_ref} = \&after_import;
$dm_cfg{lock_on} = 1;
$dm_cfg{lock_off} = 1;

$dm_cfg{actions} = 1;
$dm_cfg{force_duplicate} = 0;
$dm_cfg{force_duplicate} = 0;
$dm_cfg{add_title} = "";
$dm_cfg{excel_key} = 'id';

%dm_filters = 
(
);

$dm_cfg{file_prefixe} = 'COM';

$dm_cfg{list_html_top} = <<"EOH";
EOH




%calcul_tva = (
    '01/HTVA'=>"HTVA",
    '02/TVAC'=>"TVAC",
);

my $cpt = 9;
$tab = '';

%dm_dfl = 
(
	sprintf("%05d", $cpt++).'/member_id'=>{'title'=>'Client','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'members','lbkey'=>'id','lbdisplay'=>"CONCAT(fusion_short,' - ',type_member)",'lbwhere'=>"",'lbordby'=>"lastname,firstname",'fieldvalues'=>'','hidden'=>0},
    sprintf("%03d", $cpt++).'/commande_id'=>{'title'=>"Commande",'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'y','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'intranet_factures','lbkey'=>'id','lbdisplay'=>"fusion_facture",'lbwhere'=>"",'lbordby'=>"fusion_facture desc",'fieldvalues'=>'','hidden'=>0},
    sprintf("%03d", $cpt++).'/date_commission'=>{'title'=>"Date commission",'translate'=>0,'fieldtype'=>'text','data_type'=>'date','search' => 'y','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'intranet_factures','lbkey'=>'id','lbdisplay'=>"fusion_facture",'lbwhere'=>"",'lbordby'=>"fusion_facture desc",'fieldvalues'=>'','hidden'=>0},
    sprintf("%03d", $cpt++).'/montant'=>{'title'=>"Montant TVAC",'translate'=>0,'fieldtype'=>'text','data_type'=>'euro','search' => 'y','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'intranet_factures','lbkey'=>'id','lbdisplay'=>"fusion_facture",'lbwhere'=>"",'lbordby'=>"fusion_facture desc",'fieldvalues'=>'','hidden'=>0},
    sprintf("%03d", $cpt++).'/paye'=>{'title'=>"Payé",'translate'=>0,'fieldtype'=>'checkbox','data_type'=>'','search' => 'y','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'intranet_factures','lbkey'=>'id','lbdisplay'=>"fusion_facture",'lbwhere'=>"",'lbordby'=>"fusion_facture desc",'fieldvalues'=>'','hidden'=>0},
);



%dm_display_fields = (
    
	"40/Client"=>"member_id",
	"41/Commande"=>"commande_id",
	"50/Date commission"=>"date_commission",
	"60/Montant TVAC"=>"montant",
	"70/Payé"=>"paye",
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
list_del_file
);


if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}




################################################################################



sub get_prix
{
    my $dbh = $_[0];
    my $id = $_[1];
	
	return $dm_cfg{file_prefixe}.$id;
}

sub after_save
{
    my $dbh = $_[0];
    my $id = $_[1];
	my $all = $_[2] || 'not';

#	my %inv = read_table($dbh,$dm_cfg{table_name},$id);
  my %commission = read_table($dbh,'handmade_certigreen_commissions',$id);
    def_handmade::save_doc_commission_cree_pdf(\%commission, 1);

}