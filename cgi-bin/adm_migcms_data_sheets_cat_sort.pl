#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use data;
use migcrender;
use Geo::Coder::Google;

my $id_data_family = get_quoted('id_data_family') || 1;
my $extra_filter = get_quoted('extra_filter') || 1;

my $apercu_classement = $config{apercu_classement} || get_quoted('apercu_classement') || 'y';
$dm_cfg{enable_search} = 1;
$dm_cfg{autocreation} = 1;
$dm_cfg{excel} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort} = 1;
$dm_cfg{duplicate} = 0;

$dm_cfg{page_cms} = 1;
$dm_cfg{pic_url} = 1;
$dm_cfg{pic_alt} = 1;
$dm_cfg{edit} = 0;
$dm_cfg{delete} = 0;

$dm_cfg{table_name} = $dm_cfg{list_table_name} = "data_lnk_sheets_categories";
$dm_cfg{wherep} = $dm_cfg{wherel} = $dm_cfg{wherep_ordby} = "id_data_category = '$extra_filter' AND id_data_sheet > 0 AND id_data_sheet IN (select id from data_sheets)";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_data_sheets_cat_sort.pl?extra_filter=$extra_filter";

$dm_cfg{default_ordby} = "ordby asc";  
$dm_cfg{ordby_desc} = 1;  
$dm_cfg{trad} = 0;




$sw = $cgi->param('sw') || "list";


see();
my %data_family = read_table($dbh,"data_families",$id_data_family);
my %data_category = read_table($dbh,"data_categories",$extra_filter);
my $data_category_name = get_traduction({id=>$data_category{id_textid_name},id_language=>$colg});


$dm_cfg{page_title} = $data_family{name};
$dm_cfg{file_prefixe} = 'SHEETS';


%dm_dfl = (
  
    # '07/id_data_category'=> {
        # 'title' => 'Catégorie',
        # 'fieldtype'=>'listboxtable',
        # 'lbtable'=>'data_categories',
        # 'lbkey'=>'id',
        # 'lbdisplay'=>'id_textid_name',
        # 'translate'=>'1',
        # 'lbwhere'=>"",
        # 'mandatory'=>{"type" => 'not_empty',
                    # }
	# }
	# ,
	 # '08/id_data_sheet'=> {
        # 'title' => 'Fiche',
        # 'fieldtype'=>'listboxtable',
        # 'lbtable'=>'data_sheets',
        # 'lbkey'=>'id',
        # 'lbdisplay'=>'f1',
        # 'translate'=>'0',
        # 'lbwhere'=>"",
        # 'mandatory'=>{"type" => 'not_empty',
                    # }
	# }
	
);


%dm_display_fields = (
    # "1/Catégorie"=>"id_data_category",
	# "2/Fiche"=>"id_data_sheet",
);

%dm_lnk_fields = 
(
"99/Fiche/col_fiche"=>"rendu_sheet*",
);

%dm_mapping_list = (
"rendu_sheet" => \&rendu_sheet,
);
my @fcts = qw(
			list
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}


sub rendu_sheet
{
 	my $dbh = $_[0];
	my $id = $_[1];
	my %rec = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
	my %data_sheet = sql_line({table=>'data_sheets',where=>"id='$rec{id_data_sheet}'"});
	
	my %migcms_linked_file = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='data_sheets' AND token='$data_sheet{id}' AND table_field='photos' ",limit=>"1",ordby=>"ordby"});
	my $photo = migcrender::render_pic({full_url=>1,migcms_linked_file => \%migcms_linked_file,size=>"mini",lg=>$config{current_language}});	

	my $rendu = $photo.'';
	
	my @data_fields = sql_lines({table=>'data_fields',where=>"id_data_family='$data_sheet{id_data_family}' AND visible='y' AND in_list='y'",ordby=>"ordby"});
	foreach $data_field (@data_fields)
	{
		my %data_field = %{$data_field};
		my $title = get_traduction({debug=>0,id_language=>$d{colg},id=>$data_field{id_textid_name}});
		

		my $valeur = $data_sheet{'f'.$data_field{ordby}};
		if($data_field{field_type} eq 'text_id' || $data_field{field_type} eq 'textarea_id' || $data_field{field_type} eq 'textarea_id_editor')
		{
			$valeur = get_traduction({debug=>0,id_language=>$config{current_language},id=>$valeur});
		}
		$rendu .= " $title: <b>".$valeur.'</b>';
	}
	return $rendu;
}

	