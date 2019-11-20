#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use migcrender;
use Data::Dumper;
$colg = get_quoted('colg') || $config{default_colg} || 1;

my $id_data_family=get_quoted('id_data_family');  
my %family=read_table($dbh,"data_families",$id_data_family);

#stock config_data_fields*********************************************************************
my %data_fields_params=();
my @data_fields=get_table($dbh,"data_fields","","id_data_family='$id_data_family'");
for $i (0 .. $#data_fields)
{
    $data_fields_params{$data_fields[$i]{ordby}}=$data_fields[$i]{field_type};
}
 
my $field_name = get_obj_name($dbh,$id_data_field,'data_fields',$colg);

$dm_cfg{customtitle} = <<"EOH";
<a href="$config{baseurl}/cgi-bin/adm_data_families.pl?&colg=$colg">$migctrad{data_title_families}</a>   
> 
<a href="$config{baseurl}/cgi-bin/adm_data_fields.pl?id_data_family=$id_data_family&colg=$colg">$migctrad{data_title_fields_families} $family{name}</a>  

EOH

$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 1;
$dm_cfg{trad} = 1;
$dm_cfg{sort_opt} = 1;
$dm_cfg{wherep_ordby} = $dm_cfg{wherep} = "id_data_family=$id_data_family";
$dm_cfg{wherel} = "id_data_family=$id_data_family";
$dm_cfg{table_name} = "data_fields";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?id_data_family=$id_data_family";
$dm_cfg{dupliquer} = 1;
$dm_cfg{page_title} = "Champs de l'annuaire";

my $selfcolg=$dm_cfg{self}.'&sw='.$sw.'&id='.get_quoted('id');       

%field_type = (
	# "","Veuillez sélectionner",
	"01/text"=>"$migctrad{data_fields_text}",
	"02/text_id"=>"$migctrad{data_fields_text_id}",
	"03/textarea"=>"$migctrad{data_fields_texarea}",
	"04/textarea_id"=>"$migctrad{data_fields_textarea_id}",
	"05/textarea_editor"=>"$migctrad{data_fields_textarea_editor}",      
	"06/textarea_id_editor"=>"$migctrad{data_fields_textarea_id_editor}",
	# "listbox"=>"$migctrad{data_fields_listbox_id}",
	# "listbox"=>"$migctrad{data_fields_listbox_id}",
	"07/checkbox"=>"$migctrad{data_fields_checkbox}",
	"08/files_admin"=>"Fichier(s)",
	"09/titre"=>"titre",
	"09/listboxtable"=>"table liée",
		);
%data_types = (
	"","",
	"01/date"=>"Date",
	"02/time"=>"Heure",
	"03/datetime"=>"Date et heure",
	"04/euros"=>"Euros",      
	"05/perc"=>"Pourcents",
	"06/email"=>"Email",      
	"07/iban"=>"IBAN",
	"08/bic"=>"BIC",
	"09/phone"=>"Téléphone",
	"10/gsm"=>"GSM",
	"11/fax"=>"FAX",
	"12/password"=>"Mot de passe",
	"13/button"=>"Boutons",
	"14/autocomplete"=>"autocomplete",
		);	
		
$cpt = 9;		
		
%dm_dfl = (
	    
		sprintf("%05d", $cpt++).'/id_textid_name'=>{'title'=>$migctrad{id_textid_name},'fieldtype'=>'text_id','mandatory'=>{"type" => 'not_empty'},search=>'y'},
		sprintf("%05d", $cpt++).'/field_type'=>{'title'=>$migctrad{field_type},'fieldtype'=>'listbox','default_value'=>'text','mandatory'=>{"type" => 'not_empty'},search=>'y','fieldvalues'=>\%field_type},
		sprintf("%05d", $cpt++).'/data_type'=>{'title'=>'Sous-type','fieldtype'=>'listbox','mandatory'=>{"type" => ''},search=>'y','fieldvalues'=>\%data_types},
		sprintf("%05d", $cpt++).'/field_tab'=>{'title'=>$migctrad{field_tab},'fieldtype'=>'text','default_value'=>'Fiche'},
		sprintf("%05d", $cpt++).'/in_list'=>{'title'=>$migctrad{in_list},'fieldtype'=>'checkbox'},
		sprintf("%05d", $cpt++).'/searchable'=>{'title'=>$migctrad{searchable},'fieldtype'=>'checkbox'},
		sprintf("%05d", $cpt++).'/in_filters'=>{'title'=>'Dans les filtres','fieldtype'=>'checkbox'},
		sprintf("%05d", $cpt++).'/in_meta_title'=>{'title'=>'Dans les META TITLE','fieldtype'=>'checkbox'},
		sprintf("%05d", $cpt++).'/in_meta_description'=>{'title'=>'Dans les META description','fieldtype'=>'checkbox'},
		sprintf("%05d", $cpt++).'/id_data_family'=>{'title'=>'Famille','fieldtype'=>'text','hidden' => 1},
		sprintf("%05d", $cpt++).'/mandatory'=>{'title'=>'Obligatoire','fieldtype'=>'checkbox'},
		sprintf("%05d", $cpt++).'/default_value'=>{'title'=>'Valeur par défaut','fieldtype'=>'text'},
		sprintf("%05d", $cpt++).'/lbtable'=>{'title'=>'Table liée','fieldtype'=>'text'},
		sprintf("%05d", $cpt++).'/lbkey'=>{'title'=>'Clé de la table liée','fieldtype'=>'text'},
		sprintf("%05d", $cpt++).'/lbdisplay'=>{'title'=>'Affichage de la table liée','fieldtype'=>'text'},
		sprintf("%05d", $cpt++).'/lbwhere'=>{'title'=>'Where pour la table liée','fieldtype'=>'text'},
		sprintf("%05d", $cpt++).'/lbordby'=>{'title'=>'Tri pour la table liée','fieldtype'=>'text'},
		sprintf("%05d", $cpt++).'/hidden'=>{'title'=>'Caché','fieldtype'=>'checkbox'},		
		sprintf("%05d", $cpt++).'/multiple'=>{'title'=>'Mulitple','fieldtype'=>'checkbox'},		
		sprintf("%05d", $cpt++).'/btn_style'=>{'title'=>'Style du bouton','fieldtype'=>'text'},		
	);

	%dm_display_fields = (
  "01/$migctrad{id_textid_name}"=>"id_textid_name",
  "02/$migctrad{field_type}"=>"field_type",
  "03/Sous-type"=>"data_type",
  "04/$migctrad{field_tab}"=>"field_tab",
  "05/$migctrad{in_list}"=>"in_list",
    "07/Caché"=>"hidden",

		);


%dm_lnk_fields = (
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



sub get_field_type_values
{
    my $dbh = $_[0];
    my $id = $_[1];
 
    my $stmt;
    $stmt="select field_type from data_fields where id='".$id."'";
  	my $cursor = $dbh->prepare($stmt);
  	my $rc = $cursor->execute;
  	if (!defined $rc) 
  	{
  	  see();
  	  print "[$stmt]";
  	  exit;   
  	}	
  	
  	while ($ref_rec = $cursor->fetchrow_hashref()) 
  	{
  	  my %rec = %{$ref_rec};
  		if($rec{field_type} eq "listbox" || $rec{field_type} eq "listbox_id" || $rec{field_type} eq "radio" )
  		{
        return <<"EOH";
        <a href="$config{baseurl}/cgi-bin/adm_data_field_listvalues.pl?id_data_family=$id_data_family&id_data_field=$id&traductible=n&colg=$colg" title="$migctrad{valeurs}">$migcicons{valeurs}</a>
EOH
      }
      elsif($rec{field_type} eq "listbox" || $rec{field_type} eq "radio" )
  		{
        return <<"EOH";
        <a href="$config{baseurl}/cgi-bin/adm_data_field_listvalues.pl?id_data_family=$id_data_family&id_data_field=$id&traductible=n&colg=$colg" title="$migctrad{valeurs}">$migcicons{valeurs}</a>
EOH
      }
  	} 
  	return '';
}



