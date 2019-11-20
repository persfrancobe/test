#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
see();
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
print " ECRAN A REVOIR ";
exit;
###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

$colg = get_quoted('colg') || $config{default_colg};

$id_field = get_quoted('id_field');
$id_form = get_quoted('id_form') || 0;
$type = get_quoted('type');
$id_father = get_quoted('id_father') || 0;

# my $family_name = get_obj_name($dbh,$id_dataform,'forms',$colg);
# my $field_name = get_obj_name($dbh,$id_field,'forms_fields',$colg);

$dm_cfg{customtitle} = $migctrad{data_fields_listvalues_title}.' > '.$family_name.' > '.$field_name.' > '.$migctrad{product_fields_listvalues_title};



$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 1;

$dm_cfg{wherep} = "id_field=$id_field";
if ($type eq "listbox_tree") {
    $dm_cfg{wherep}.= " AND id_father=$id_father";
}
# $dm_cfg{wherel} = "id_field=$id_field";
$dm_cfg{wherel} = "id_textid_name=txt.id_textid AND txt.id_language=$colg AND id_field=$id_field";
if ($type eq "listbox_tree") {
    $dm_cfg{wherel}.= " AND id_father=$id_father";
}
$dm_cfg{table_name} = "forms_fields_listvalues";
$dm_cfg{list_table_name} = "$dm_cfg{table_name},textcontents AS txt";



$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_forms_field_listvalues.pl?id_field=$id_field&type=$type&id_form=$id_form&id_father=$id_father";


if ($type eq "listbox_tree") {
    my %current_path = %{get_values_path_hashtable($dbh,$id_father,"forms_fields_listvalues")};
    my $url = $dm_cfg{self};
    $url= remove_param_from_url($url,"id_father");
    $dm_cfg{customtitle} .= " > <a href=\"$url&id_father=0\">[/]</a>";
    foreach $level (sort keys(%current_path)) {
        my $url = $dm_cfg{self};
    $url= remove_param_from_url($url,"id_father");
    $dm_cfg{customtitle} .= " > <a href=\"$url&id_father=$current_path{$level}{id}\">$current_path{$level}{name}</a>";
}
}


$config{logfile} = "trace.log";

$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="colg" value="$colg" />
<input type="hidden" name="type" value="$type" />
<input type="hidden" name="id_field" value="$id_field" />
<input type="hidden" name="id_form" value="$id_form" />
<input type="hidden" name="id_father" value="$id_father" />
EOH

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (

	    '01/id_textid_name'=> {
	        'title'=>$migctrad{id_textid_name},
	        'fieldtype'=>'text_id',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
	    
	);
	
#\@
%dm_display_fields = (
	"01/$migctrad{id_textid_value}"=>"txt.content",
		);

%dm_lnk_fields = (
		);

if ($type eq "listbox_tree") {
    my $url = $dm_cfg{self};
    $url= remove_param_from_url($url,"id_father");

    %dm_lnk_fields = (
        "02/.../..."=>$url."&id_father=",
		);
}



%dm_mapping_list = (
);

%dm_filters = (
		);


$sw = $cgi->param('sw') || "list";
my $selfcolg=$self.'&sw='.$sw.'&id='.get_quoted('id');       
# my $colg_menu = get_colg_menu($dbh,$colg,$selfcolg);
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


 sub get_values_path_hashtable
{
 my $dbh = $_[0];
 my $id_zone = $_[1];
 my $zone = $_[2];

 my $level = 100;
 my %path = ();

 while ($level > 0) {
     my ($stmt,$cursor,$id_father,$name);
     $stmt = "select id_father,id FROM $zone where id = $id_zone order by ordby";
     $cursor = $dbh->prepare($stmt) || suicide("error execute : $DBI::errstr [$stmt]\n");
     $cursor->execute || suicide("error execute : $DBI::errstr [$stmt]\n");
     $cursor->bind_columns(\$id_father,\$id_val);
     $cursor->fetch();
     $cursor->finish();
     my $name = get_obj_name($dbh,$id_val,'forms_fields_listvalues',$colg);
     $level = get_values_path_level($dbh,$id_zone,$zone);
     last if (!$level);

     $path{$level}{name} = $name;
     $path{$level}{id} = $id_zone;
     $path{$level}{father} = $id_father;

     $id_zone = $id_father;
 }

 return \%path;
}

sub get_values_path_level
{
 my $dbh = $_[0];
 my $id_father = $_[1];
 my $zone = $_[2];
 my $level = 0;

 while ($id_father) {

     my ($stmt,$cursor);
     $stmt = "select id_father FROM $zone where id = $id_father";
     $cursor = $dbh->prepare($stmt);
     $cursor->execute || wfw_exception("SQL_ERROR","error execute : $DBI::errstr [$stmt]\n");
     $cursor->bind_columns(\$id_father);
     $cursor->fetch();
     $cursor->finish();
     $level++;
 }
 return $level;
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------