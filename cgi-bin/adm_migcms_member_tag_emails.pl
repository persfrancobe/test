#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
# use def_handmade;

$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{excel} = 1;
$dm_cfg{sort_opt} = 0;
$dm_cfg{trad} = 0;

$dm_cfg{table_name} = "migcms_member_tag_emails";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_member_tag_emails.pl?";

$dm_cfg{list_html_top} = <<"EOH";
<script>
jQuery(document).ready(function() 
{
});
</script>
EOH

$dm_cfg{list_html_bottom} = <<"EOH";
EOH

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;

my $id_migcms_member_tag = get_quoted('id_migcms_member_tag');
if($id_migcms_member_tag > 0)
{
	$dm_cfg{wherel} .= "  id_migcms_member_tag = '$id_migcms_member_tag' ";
}



$dm_cfg{default_tab} = 'st';
my $cpt = 9;
my $tab = 'st';



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	
		sprintf("%05d", $cpt++).'/id_migcms_member_tag'=>{'title'=>'Tag attaché','translate'=>0,'fieldtype'=>'listboxtable',tab=>$tab,'data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => 'not_empty'},'default_value'=>'','lbtable'=>'migcms_members_tags','lbkey'=>'id','lbdisplay'=>"name",'lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>\%periodicite_facturation,'hidden'=>0},
		sprintf("%05d", $cpt++).'/id_migcms_member'=>{'title'=>'Email','translate'=>0,'fieldtype'=>'listboxtable',tab=>$tab,'data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => 'not_empty'},'default_value'=>'','lbtable'=>'migcms_members','lbkey'=>'id','lbdisplay'=>"email",'lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>\%periodicite_facturation,'hidden'=>0},
	);

	
%dm_display_fields = 
(
	sprintf("%05d", $cpt++)."/Tag attaché"=>"id_migcms_member_tag",
	sprintf("%05d", $cpt++)."/Email"=>"id_migcms_member",
);

%dm_lnk_fields = (
			
		);

%dm_mapping_list = (
);



$sw = $cgi->param('sw') || "list";



my @fcts = qw(
			add_form
			tab_prestations
			mod_form
			list
			add_db
			set_date_cloture
			mod_db
			del_db
		);

if (is_in(@fcts,$sw)) { 
    see();
    dm_init();
    &$sw();
    if ($sw eq "list") {$spec_bar.=$lnkxls;}
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}




sub after_save
{
  	my $dbh = $_[0];  
  	my $id = $_[1];
	
	
}

