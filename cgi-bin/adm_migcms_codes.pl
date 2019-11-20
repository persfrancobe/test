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

my $id_code_type = get_quoted('id_code_type');

$dm_cfg{after_add_ref}     = \&after_save;
$dm_cfg{after_mod_ref}     = \&after_save;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 1;

$dm_cfg{table_name} = "migcms_codes";

$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
# $dm_cfg{wherel}  marke= "id_code_type='$id_code_type'";
$dm_cfg{wherep_ordby} = "ordby";
$dm_cfg{default_ordby} = "ordby";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?";
$dm_cfg{file_prefixe} = 'COD';

$cpt = 9;
	

%dm_dfl = (
	sprintf("%05d", $cpt++).'/id_code_type'=>{'title'=>"Type de code",'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'migcms_code_types','lbkey'=>'id','lbdisplay'=>'code','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
	sprintf("%05d", $cpt++).'/code' => {'title'=>"Code",'fieldtype'=>'text',"type" => '','search' => 'y'},
	sprintf("%05d", $cpt++).'/id_textid_name' => {'title'=>"Nom public",'fieldtype'=>'text_id',"type" => '','search' => 'y'},
	sprintf("%05d", $cpt++).'/v1' => {'title'=>"Valeur 1",'fieldtype'=>'text',"type" => '','search' => 'y'},
	sprintf("%05d", $cpt++).'/v2' => {'title'=>"Valeur 2",'fieldtype'=>'text',"type" => '','search' => 'y'},
	sprintf("%05d", $cpt++).'/v3' => {'title'=>"Valeur 3",'fieldtype'=>'text',"type" => '','search' => 'y'},
	sprintf("%05d", $cpt++).'/v4' => {'title'=>"Valeur 4",'fieldtype'=>'text',"type" => '','search' => 'y'},
	sprintf("%05d", $cpt++).'/v5' => {'title'=>"Valeur 5",'fieldtype'=>'text',"type" => '','search' => 'y'},
	sprintf("%05d", $cpt++).'/v6' => {'title'=>"Valeur 6",'fieldtype'=>'text',"type" => '','search' => 'y'},
	sprintf("%05d", $cpt++).'/v7' => {'title'=>"Valeur 7",'fieldtype'=>'text',"type" => '','search' => 'y'},
	sprintf("%05d", $cpt++).'/condition_where'=>{'title'=>"Condition",'translate'=>0,'fieldtype'=>'text','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},'default_value'=>'','lbtable'=>'migcms_code_types','lbkey'=>'id','lbdisplay'=>'code','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0,'search' => 'y'},

	);
	

%dm_display_fields = 
(
	"01/Nom public"=>"id_textid_name",
	"02/Code interne"=>"code",
	"03/Valeur"=>"v1",
	"04/Valeur 2"=>"v2",
	"05/Type"=>"id_code_type",
);

%dm_filters = 
(
	"2/Type de code"=>
	{
		'type'=>'lbtable',
		'table'=>'migcms_code_types',
		'key'=>'id',
		'translate'=>'0',
		'ordby'=>'code',
		'display'=>'code',
		'col'=>'id_code_type',
	}
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

sub after_save_all
{
    # my $dbh = $_[0];
    my $id = $_[1];
	my @recs = sql_lines({table=>"$dm_cfg{table_name}"});
	foreach $rec (@recs)
	{
		my %rec = %{$rec};
		after_save($dbh,$rec{id});
	}
}

sub after_save
{
    my $dbh=$_[0];
    my $id=$_[1];
    my %rec = read_table($dbh,$dm_cfg{table_name},$id);
	
	
	if($rec{id_textid_name} == 0 && $rec{code} ne '')
	{
		set_traduction({id_language=>1,traduction=>$rec{code},id_traduction=>$rec{id_textid_name},table_record=>$dm_cfg{table_name},col_record=>'id_textid_name',id_record=>$rec{id}});
	}

	
}

sub enfants
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};
	my $self = "$config{baseurl}/cgi-bin/adm_migcms_codes.pl?sel=".get_quoted('sel').'&migcms_code_type='.$id;
	
	my $acces = <<"EOH";
		<a class="btn btn-primary" href="$self" data-original-title="Consulter les codes" target="" data-placement="bottom">
		<i class="fa fa-sitemap fa-fw" aria-hidden="true"></i>
		</a>
EOH

	return $acces;
}
