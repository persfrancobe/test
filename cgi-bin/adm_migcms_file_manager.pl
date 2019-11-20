#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use Data::Dumper;
         

$colg = get_quoted('colg') || $config{default_colg} || 1;


$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 1;
$dm_cfg{operations} = 0;
$dm_cfg{trad} = 0;
$dm_cfg{excel} = 0;
$dm_cfg{enable_search} = 0;
$dm_cfg{deplie_recherche} = 0;

$dm_cfg{corbeille} = 0;
$dm_cfg{restauration} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "migcms_file_manager";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{excel_key} = 'id';
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?";
$dm_cfg{page_cms} = 1;
# $dm_cfg{tree} = 1;
$dm_cfg{autocreation} = 0;


$dm_cfg{etapeFinale} = 1;
$dm_cfg{etapeFinaleNom} = 'Etape finale';
$dm_cfg{etapeFinaleFields} = 'fi';


$dm_cfg{add_title} = "Créer un dossier";
$dm_cfg{after_mod_ref} = \&up;
$dm_cfg{after_add_ref} = \&up;
$dm_cfg{file_prefixe} = 'di';

$dm_cfg{page_title} = "Gestion des fichiers";
$dm_cfg{after_upload_ref} = \&after_upload;


$dm_cfg{hiddp}=<<"EOH";
EOH

$dm_cfg{list_html_top} = <<"EOH";
<style>
  
  .list_ordby,.list_ordby_header, thead.cf,.row_actions_globales,.td-input,.mig_cb_col, .breadcrumb
	 {
		display:none;
	 }

	.fa-file-image-o
	{
		color:#333333;
	}
	.fa-file-excel-o
	{
		color:#38892e;
	}
	.fa-file-word-o
	{
		color:#0e66c3;
	}
	.pick_link_y, .only_pick_link_
	{
		display:none!important;
	}
	.dm_migedit
	{
	/*display:none!important;*/
	}
</style>
<script>
jQuery(document).ready(function() 
{
	        //jQuery('.list_actions_2').removeClass('list_actions_2').addClass('list_actions_1');
});
</script>
EOH


%dm_dfl = 
(
'02/name'=> 
{
'title'=>'Nom du dossier',
'fieldtype'=>'text',
'search' => 'y',
'mandatory'=>{"type" => 'not_empty'},
}
 # ,
	    # '09/id_father' => 
      # {
           # 'title'=>'Parent',
           # 'fieldtype'=>'listboxtable',
		   # 'data_type'=>'treeview',
           # 'lbtable'=>'migcms_file_manager',
           # 'lbkey'=>'id',
           # 'lbdisplay'=>'name',
           # 'summary'=>0,
			# 'tree_col'=>'id_father',

           # 'lbwhere'=>""
      # }
	  ,
	'63/fi'=> 
	{
		'title'=>"<b>Ajouter des fichiers</b>",
		'tip'=>"<b>Cliquez</b> pour parcourir ou <b>déposez</b> vos fichiers <u>dans ce cadre</u>",
		'fieldtype'=>'files_admin',
		'disable_add'=>1,
				'msg'=>'Cliquez ici pour parcourir votre ordinateur ou déposez directement des fichiers dans ce cadre.',

	}

);

%dm_display_fields = 
(
	# "01/Nom du dossier"=>"name",
);

%dm_lnk_fields = 
    (
"01/"=>"dir_rendu*",
    );



%dm_mapping_list = (
"dir_rendu"=>\&dir_rendu,

);

sub up
{
    my $dbh=$_[0];
    my $id=$_[1];
    
}


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
			list_files
		);

if (is_in(@fcts,$sw)) 
{ 

    dm_init();
    &$sw();
	$migc_output{content} .= $dm_output{content};
	$migc_output{title} = $dm_output{title}.$migc_output{title};

	print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}


sub dir_rendu
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %dir = read_table($dbh,"$dm_cfg{table_name}",$id);

my $rendu = <<"EOH";
	<a href="#" class="migedit_$id migedit" id="$id"><i class="fa fa-folder-open-o fa-fw" data-original-title="" title=""></i>$dir{name}</a>
EOH
  return $rendu;
}


sub list_files
{
	my $list = '';
	
	$list .= <<"EOH";
			<table id="migc4_main_table" class="table table-condensed table-striped table-bordered table-hover no-margin">
EOH

	my @migcms_file_manager = sql_lines({table=>'migcms_file_manager',ordby=>'ordby'});
	foreach $migcms_file_manager_dir (@migcms_file_manager)
	{
		my %migcms_file_manager_dir = %{$migcms_file_manager_dir};
		$list .= <<"EOH";
			<tr>
				<td class="cell-value-container td-cell-value  list_tree_func list_tree_func_level_1 mig_cell_func mig_cell_func_1 ">
					<span class="cell-value"><label><i class="fa fa-folder-o fa-fw"></i> $migcms_file_manager_dir{name}</label></span>
				</td>
			</tr>
EOH

		my @migcms_linked_files = sql_lines({table=>'migcms_linked_files',ordby=>'file',where=>"table_name='migcms_file_manager' AND table_field = 'fi' AND token='$migcms_file_manager_dir{id}'"});
		foreach $migcms_linked_file (@migcms_linked_files)
		{
			my %migcms_linked_file = %{$migcms_linked_file};
			
			
			my $icon = get_file_icon($migcms_linked_file{ext},'width:34px;','fa-2x',\%migcms_linked_file);

			my $file_display = lc(lc($migcms_linked_file{file}));
			
			
			my $rel = "$migcms_linked_file{file_dir}/$migcms_linked_file{full}$migcms_linked_file{ext}";
			$rel  =~ s/\.\.\///g; 
			# log_debug($rel,'','rel');
			$rel = $config{baseurl}.'/'.$rel;
			# log_debug($rel,'','rel');
			$list .= <<"EOH";
			<tr>
				<td class="cell-value-container list_tree_func list_tree_func_level_2 mig_cell_func mig_cell_func_1 ">
					<span class="cell-value">
					<input type="radio" name="pick_link" class="pick_link" rel="$rel" value="$migcms_linked_file{id}" />
					$icon
					$file_display</span>
				</td>
			</tr>
EOH
		}
	}
	$list .=<<"EOH";
	</table>
	<style>
	.fa-folder
	{
		color:#ffe894!important;
	}
	.fa-file-image-o
	{
		color:#333333;
	}
	.fa-file-excel-o
	{
		color:#38892e;
	}
	.fa-file-word-o
	{
		color:#0e66c3;
	}
	.pick_link_y, .only_pick_link_
	{
		display:none!important;
	}
</style>
EOH
	
	print $list;
	exit;


}


sub after_upload
{
	my $dbh=$_[0];
	my $id=$_[1];
	
	#boucle sur les images du paragraphes
	my @migcms_linked_files = sql_lines({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"ext IN ('.jpg','.jpeg','.png') AND table_name='$dm_cfg{table_name}' AND name_mini = '' AND token='$id'",ordby=>'ordby'});
	foreach $migcms_linked_file (@migcms_linked_files)
	{
		#appelle la fonction de redimensionnement
		my %migcms_linked_file = %{$migcms_linked_file};
		my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
		my %params = (
			migcms_linked_file=>\%migcms_linked_file,
			do_not_resize=>'n',
			size_mini => 75,
		);
		dm::resize_pic(\%params);
	}	
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
