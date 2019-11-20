#!/usr/bin/perl -I../lib -w

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use data;

my $id=get_quoted('id');
$sw = $cgi->param('sw') || "list";
my $sel = get_quoted('sel');
$dm_cfg{after_add_ref}     = \&after_save;
$dm_cfg{after_mod_ref}     = \&after_save;

$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 0;

$dm_cfg{table_name} = "migcms_member_segments";

$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{wherep_ordby} = "ordby";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?";
$dm_cfg{file_prefixe} = 'SG';
$dm_cfg{default_ordby} = 'name';

$cpt = 9;
	

%dm_dfl = (
	sprintf("%05d", $cpt++).'/name' => {'title'=>"Nom",'fieldtype'=>'text',"type" => 'not_empty'},
	sprintf("%05d", $cpt++).'/titre1'=>{'title'=>'Pour être sélectionné, un membre devra faire partie de l\'ensemble des groupes ci-dessous:','translate'=>0,'fieldtype'=>'titre','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'lbtable'=>'migcms_members_tags','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"name != '' AND fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_migcms_member_dir_1'=>{'title'=>'Groupe 1','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},'lbtable'=>'migcms_members_tags','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"name != '' AND fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_migcms_member_dir_2'=>{'title'=>'ET Groupe 2','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},'lbtable'=>'migcms_members_tags','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"name != '' AND fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_migcms_member_dir_3'=>{'title'=>'ET Groupe 3','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},'lbtable'=>'migcms_members_tags','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"name != '' AND fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_migcms_member_dir_4'=>{'title'=>'ET Groupe 4','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},'lbtable'=>'migcms_members_tags','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"name != '' AND fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_migcms_member_dir_5'=>{'title'=>'ET Groupe 5 )','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},'lbtable'=>'migcms_members_tags','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"name != '' AND fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_migcms_member_dir_6'=>{'title'=>'ET Groupe 6','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},'lbtable'=>'migcms_members_tags','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"name != '' AND fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_migcms_member_dir_7'=>{'title'=>'ET Groupe 7','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},'lbtable'=>'migcms_members_tags','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"name != '' AND fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_migcms_member_dir_8'=>{'title'=>'ET Groupe 8','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},'lbtable'=>'migcms_members_tags','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"name != '' AND fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_migcms_member_dir_9'=>{'title'=>'ET Groupe 9','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},'lbtable'=>'migcms_members_tags','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"name != '' AND fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/id_migcms_member_dir_10'=>{'title'=>'ET Groupe 10','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},'lbtable'=>'migcms_members_tags','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"name != '' AND fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},
	);
	

%dm_display_fields = 
(
	"02/Nom"=>"name",
);



see();

my @fcts = qw(
			list
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();

    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
		
    print migc_app_layout($js.$migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}


sub after_save
{
    my $dbh=$_[0];
    my $id=$_[1];
    # my %rec = read_table($dbh,$dm_cfg{table_name},$id);
		compute_denomination($id);

}

sub compute_denomination
{
	my $id = $_[0];
	my %rec = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
	
	$fusion = ',';
	
	foreach my $num (1 ..10)
	{
		if($rec{'id_migcms_member_dir_'.$num} > 0)
		{
			$fusion .= $rec{'id_migcms_member_dir_'.$num}.',';
		}
	}
	$fusion .= ',';
	
	my $stmt = <<"EOH";
		UPDATE $dm_cfg{table_name} SET fusion = '$fusion' WHERE id = '$rec{id}'
EOH
	execstmt($dbh,$stmt);
}
