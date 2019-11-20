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

$dm_cfg{table_name} = "migcms_members_rules";

$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{wherep_ordby} = "ordby";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?";
$dm_cfg{file_prefixe} = 'RUL';
$dm_cfg{default_ordby} = 'name';

$cpt = 9;
	

%dm_dfl = (
	sprintf("%05d", $cpt++).'/name' => {'title'=>"Nom",'fieldtype'=>'text',"type" => 'not_empty'},
	sprintf("%05d", $cpt++).'/description' => {'title'=>"Description",'fieldtype'=>'textarea',"type" => 'not_empty'},
	sprintf("%05d", $cpt++).'/where_members' => {'title'=>"Condition SQL",'fieldtype'=>'textarea',"type" => 'not_empty'},
	);
	
$dm_cfg{'list_custom_action_19_func'} = \&voir_membres;

%dm_display_fields = 
(
	"01/Nom"=>"name",
	"02/Description"=>"description",
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

sub voir_membres
{
	my $id = $_[0];
	my $colg = $_[1];
	my %rule = %{$_[2]};
	
	my $url_members = $config{rules_voir_members};
	if($url_members eq '')
	{
		my %rec_script_members = sql_line({table=>'scripts',where=>"url LIKE '%adm_migcms_members.pl%'"});
		$url_members = 'adm_migcms_members.pl?&sel='.$rec_script_members{id};
	}

	my $actions = <<"EOH";
		<a href="$url_members&id_rule=$rule{id}" data-placement="bottom" data-original-title="Voir les contacts correspondant à cette règle" id="$id" role="button" class=" 
				  btn btn-primary $class show_only_after_document_ready">
					  <i class="fa fa-fw fa-users" "> 
				  </i>
						  
				  </a>

EOH
		
	return $actions;
}