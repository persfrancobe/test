#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
# see();
use dm;

generer_droits();
compute_noms();



my %securite_setup = sql_line({table=>'securite_setup'});
my $droits = get_quoted('droits');
$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{edit} = 0;
$dm_cfg{add} = 0;
$dm_cfg{delete} = 0;
$dm_cfg{operations} = 1;
$dm_cfg{default_ordby} = "fusion,id_role";
$dm_cfg{wherep} = $dm_cfg{wherel} = " fusion != '' ";
$dm_cfg{table_name} = "migcms_roles_scripts_permissions";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_roles_scripts_permissions.pl?";
$dm_cfg{tree} = 0;
$dm_cfg{trad} = 0;
$dm_cfg{file_prefixe} = 'PER';
$dm_cfg{extra_filter_exact} = 'y';
# $dm_cfg{after_mod_ref} = \&after_save;
# $dm_cfg{after_add_ref} = \&after_save;

$dm_cfg{custom_filter_func}=\&tree_scripts_filter;


  
if($config{current_language} eq "")
{
   $config{current_language}=get_quoted('lg') || 1;
}
$dm_cfg{disable_mod} = "n";

$dm_cfg{line_func} = 'custom_tree_levels';  

$dm_cfg{hiddp}=<<"EOH";

EOH

my @scripts = sql_lines({table=>'scripts',where=>"id_textid_name = 0"});
foreach $script(@scripts)
{
	my %script = %{$script};
	my $new_id_textid_name = update_txtcontent({lg1=>$script{name},lg2=>$script{name},lg3=>$script{name}});
	$stmt = "UPDATE scripts SET id_textid_name = $new_id_textid_name WHERE id = '$script{id}' ";
    execstmt($dbh,$stmt);
}




#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    
       '11/id_role' => 
      {
           'title'=>'Rôle',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'migcms_roles',
		   'translate'=>0,
           'lbkey'=>'id',
           'lbdisplay'=>'nom_role',
           'summary'=>0,
           'lbwhere'=>""
      }
	  ,
	    '12/id_script' => 
      {
           'title'=>'Module',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'scripts',
		   'translate'=>1,
           'lbkey'=>'id',
           'lbdisplay'=>'id_textid_name',
           'summary'=>0,
           'lbwhere'=>""
      },
	'13/nom_role' => 
      {
           'title'=>'Nom du rôle',
           'fieldtype'=>'text',
           'search'=>'y',
      }
	  ,
	  '14/nom_script' => 
      {
           'title'=>'Nom du module',
           'fieldtype'=>'text',
           'search'=>'y',
		   
      }
	  ,
	  '15/fusion' => 
      {
           'title'=>'Dénomination',
           'fieldtype'=>'text',
           'search'=>'y',
		   
      }
	);
%dm_display_fields =  
      (
"02/Module"=>"fusion",
# "03/Module"=>"id_script",
"04/Niveau"=>"nom_role",	  
      ); 
	  
	 

 
%dm_lnk_fields = (
"05/Permissions"=>"get_nom*",
		);

%dm_mapping_list = (
    "get_nom"=>\&get_nom,
);

%dm_filters = (

"5/Niveau"=>{
                         'type'=>'lbtable',
                         'table'=>'migcms_roles',
                         'key'=>'id',
                         'display'=>'nom_role',
                         'ordby'=>'id',
                         'col'=>'id_role',
                         'where'=>''
                        }
		);


		
		
		
$dm_cfg{list_html_top} = <<"EOH";	
   	<script type="text/javascript">
      jQuery(document).ready(function() 
      {
			var self = jQuery('#myself').val();

			
			jQuery(document).on("click", ".btn_save_permission", function()
			{
				if(jQuery(this).hasClass('btn-success') || jQuery(this).hasClass('btn-danger'))
				{
					jQuery(this).toggleClass('btn-success');
					jQuery(this).toggleClass('btn-danger');
					
					var request = jQuery.ajax(
					{
						url: self,
						type: "GET",
						data: 
						{
						   sw : 'change_permission',
						   col : jQuery(this).attr('data-col'),
						   id_role : jQuery(this).attr('data-role'),
						   id_script : jQuery(this).attr('data-script'),
						   is_checked:jQuery(this).hasClass('btn-success')
						   
						},
						dataType: "html"
					});
					
					request.done(function(msg) 
					{
										jQuery.bootstrapGrowl('<i class="fa fa-3x fa-check"></i>', { type: 'success',delay:200,align: 'center',
							width: 'auto',allow_dismiss: false});

					});
					request.fail(function(jqXHR, textStatus) 
					{
										jQuery.bootstrapGrowl('<i class="fa fa-3x fa-times"></i>', { type: 'danger',delay:2000,align: 'center',
										width: 'auto',allow_dismiss: false});
					});
					
				}
				else
				{
					jQuery(this).toggleClass('btn-default');
					jQuery(this).toggleClass('btn-info');
					
						var request = jQuery.ajax(
					{
						url: self,
						type: "GET",
						data: 
						{
						   sw : 'change_permission',
						   col : jQuery(this).attr('data-col'),
						   id_role : jQuery(this).attr('data-role'),
						   id_script : jQuery(this).attr('data-script'),
						   is_checked:jQuery(this).hasClass('btn-info')
						   
						},
						dataType: "html"
					});
					
					request.done(function(msg) 
					{
										jQuery.bootstrapGrowl('<i class="fa fa-3x fa-check"></i>', { type: 'success',delay:200,align: 'center',
							width: 'auto',allow_dismiss: false});

					});
					request.fail(function(jqXHR, textStatus) 
					{
										jQuery.bootstrapGrowl('<i class="fa fa-3x fa-times"></i>', { type: 'danger',delay:2000,align: 'center',
										width: 'auto',allow_dismiss: false});
					});
				}
				
				
				return false;
			});	
			
			jQuery(document).on("click", ".btn-success.cliquer_ligne_all", function()
			{
				var ligne = jQuery(this).parent();
				ligne.children('.btn_save_permission.btn-danger').click();
				return false;
			});
			jQuery(document).on("click", ".btn-info.cliquer_ligne_all", function()
			{
				var ligne = jQuery(this).parent();
				ligne.children('.btn_save_permission.btn-default').click();
				return false;
			});
			jQuery(document).on("click", ".btn-danger.cliquer_ligne_aucun", function()
			{
				var ligne = jQuery(this).parent();
				ligne.children('.btn_save_permission.btn-success').click();
				return false;
			});
			jQuery(document).on("click", ".btn-default.cliquer_ligne_aucun", function()
			{
				var ligne = jQuery(this).parent();
				ligne.children('.btn_save_permission.btn-info').click();
				return false;
			});
            
      });
	  
	  
	  
	  
    </script> 
	<style>
	.cms_mig_cell_cacher_menu, .cms_mig_cell_cacher_menu  span,.cms_mig_cell_synchro, .cms_mig_cell_synchro span
	{
		width:55px!important;
	}
	</style>
EOH




$dm_cfg{list_html_bottom} .= <<"EOH";
EOH

$dm_cfg{list_html_bottom} .= <<"EOH";
EOH

$sw = $cgi->param('sw') || "list";

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
    see();
    dm_init();
    
    
    &$sw();
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}

# use Data::Dumper;

sub generer_droits
{
	my @scripts = sql_lines({table=>'scripts',ordby=>"",where=>""});
	my @migcms_roles = sql_lines({table=>'migcms_roles',ordby=>"",where=>"id > 1",ordby=>"id desc"});
	foreach $script (@scripts)
	{
		my %script = %{$script};
		# log_debug("SCRIPT $script{id}");
		if($script{id}> 0)
		{
		}
		else
		{
			next;
		}

		foreach $migcms_role (@migcms_roles)
		{
			my %migcms_role = %{$migcms_role};
			# log_debug("ROLE $migcms_role{id}");

			if($migcms_role{id}> 0)
			{
			}
			else
			{
				next;
			}			
			
		    my $nom_role = $migcms_role{nom_role};
		    my $nom_script = get_traduction({debug=>0,id_language=>$colg,id=>$script{id_textid_name}});
			
			my %migcms_roles_scripts_permission = 
			(
				id_role => $migcms_role{id},
				id_script => $script{id},
				nom_role => $nom_role,
				nom_script => $nom_script,
			);
			%migcms_roles_scripts_permission = %{quoteh(\%migcms_roles_scripts_permission)};
			my $i = 0;
			# foreach $action (@actions)
			# {
				# my %action = %{$action};
				# if($migcms_role{id} == 3 || $migcms_role{id} == 2)
				# {
					# if($i < 13)
					# {
						# $migcms_roles_scripts_permission{$action{code}} = 'y';
					# }
					# else
					# {
						# $migcms_roles_scripts_permission{$action{code}} = 'n';
					# }
				# }
				# elsif($migcms_role{id} == 4)
				# {
					# if($i < 12)
					# {
						# $migcms_roles_scripts_permission{$action{code}} = 'y';
					# }
					# else
					# {
						# $migcms_roles_scripts_permission{$action{code}} = 'n';
					# }
				# }
				# elsif($migcms_role{id} == 7)
				# {
					# if($i < 7)
					# {
						# $migcms_roles_scripts_permission{$action{code}} = 'y';
					# }
					# else
					# {
						# $migcms_roles_scripts_permission{$action{code}} = 'n';
					# }
				# }
				# elsif($migcms_role{id} == 8)
				# {
					# if($i < 3)
					# {
						# $migcms_roles_scripts_permission{$action{code}} = 'y';

					# }
					# else
					# {
						# $migcms_roles_scripts_permission{$action{code}} = 'n';
					# }
				# }
				# $i++;
			# }
			
			
			sql_set_data({dbh=>$dbh,debug=>0,table=>'migcms_roles_scripts_permissions',data=>\%migcms_roles_scripts_permission, where=>"id_role='$migcms_roles_scripts_permission{id_role}' AND id_script = '$migcms_roles_scripts_permission{id_script}'"});      		
		}
	}
	# see();
	$stmt = "delete FROM `migcms_roles_scripts_permissions` WHERE id_role NOT IN (select id from migcms_roles)";
	execstmt($dbh,$stmt);
	
	$stmt = "delete FROM `migcms_roles_scripts_permissions` WHERE id_script NOT IN (select id from scripts)";
	execstmt($dbh,$stmt);

	
}


sub get_nom
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %migcms_role_script_permission = read_table($dbh,"migcms_roles_scripts_permissions",$id);
  my %migcms_role = read_table($dbh,"migcms_roles",$migcms_role_script_permission{id_role});
  
  
  my $list_actions = '';
  
 
		



		if($migcms_role{id} == 2)
		{
			$list_actions .= '<a href="#" data-placement="top" data-original-title="Tous" id="all" class="btn btn-xs btn-info cliquer_ligne_all">TS</a>';
			$list_actions .= '<a href="#" data-placement="top"  data-original-title="Aucun" id="all" class="btn btn-xs btn-default cliquer_ligne_aucun">AC</a>&nbsp;&nbsp;&nbsp;';
		}
else
{
			
			$list_actions .= '<a href="#" data-placement="top" data-original-title="Tous" id="all" class="btn btn-xs btn-success cliquer_ligne_all">TS</a>';
			$list_actions .= '<a href="#" data-placement="top"  data-original-title="Aucun" id="all" class="btn btn-xs btn-danger cliquer_ligne_aucun">AC</a>&nbsp;&nbsp;&nbsp;';
}
			foreach $action (@dm_actions)
			{
				my %action = %{$action};
				my $ok = 0;
				
				if($migcms_role_script_permission{$action{code}} eq 'y')
				{
					$ok = 1;
				}
				
				if($action{code} eq 'sort' || $action{code} eq 'visibility')
				{
					next;
				}
			
				my $btn_class = 'btn-danger';
				if($ok == 1)
				{
					$btn_class = 'btn-success';
				}
				if($migcms_role{id} == 2)
				{
					$btn_class = 'btn-default';
					if($ok == 1)
					{
						$btn_class = 'btn-info';
					}
				}
				$list_actions .= '<a href="#" data-placement="top" data-original-title="'.$action{name}.' ( '.$action{code}.' ) ." data-script="'.$migcms_role_script_permission{id_script}.'" data-role="'.$migcms_role{id}.'" data-col="'.$action{code}.'" class="show_only_after_document_ready  btn btn-xs '.$btn_class.' btn_save_permission"><i class="'.$action{icon}.'"></i> '.$action{label}.'</a>';
EOH
			}

 
  
  return $list_actions;

}


sub compute_noms
{
	my @migcms_roles_scripts_permissions = sql_lines({select=>"p.id,s.fusion",table=>'migcms_roles_scripts_permissions p, scripts s',ordby=>"",where=>"p.id_script = s.id"});
	foreach $migcms_role_script_permission (@migcms_roles_scripts_permissions)
	{
		my %migcms_role_script_permission = %{$migcms_role_script_permission};
		$migcms_role_script_permission{fusion} =~ s/\'/\\\'/g;
		$stmt = "UPDATE migcms_roles_scripts_permissions SET fusion = '$migcms_role_script_permission{fusion}' WHERE id = '$migcms_role_script_permission{id}' ";
		execstmt($dbh,$stmt);
	}
	
}	




sub tree_scripts_filter
{
  my $dbh = $_[0];
  my $id_father = get_quoted('id_father') || '';
  my $extra_filter = get_quoted('extra_filter') || '';
  if($id_father eq '' && $extra_filter > 0)
  {
		$id_father = $extra_filter;
  }
  my $cat_list = get_scripts_list($dbh,'','','',$id_father,'','select','',$colg);
  my $filter=<<"EOH";
 
   
   <div class="form-group group-filters-labtable-$col col-md-3">
	<label><strong>Module</strong></label>
	<select class="list_filter select2 form-control search_element" data-placeholder="$label"  id="extra_filter" name="id_script">
		 $cat_list
	</select>
</div>
EOH
  
  return $filter;
}  

sub get_scripts_list
{
 my $dbh = $_[0];
 my $already = $_[1];
 my $menu = $_[2];
 my $menufather = $_[3];
 my $me = $_[4];
 my $id_data_family=$_[5] || get_quoted('id_data_family') || 1;
 my $action_on_me = $_[6] || "grey";
 my $list_cat_only = $_[7];
 my $lg = $_[8] || $config{current_language};

 my $list = '<option value="0"></option>';
 if($action_on_me eq 'this_list_cats_only')
 {
    $list = "";
 }
 
 $list .= recurse_scripts($treehome,0,$id_data_family,$me,$menufather,$action_on_me,$list_cat_only,$lg); 
 return $list;
}

sub recurse_scripts
{
 my $father = $_[0] || 0; 
 my $level = $_[1];
 my $id_data_family=$_[2];
 my $me = $_[3]; 
 my $menufather = $_[4];
 my $action_on_me=$_[5];
 my $list_cat_only = $_[6];
 my $lg = $_[7] || $config{current_language};
 my @list_cat_only_tab = split(/\,/,$list_cat_only);
 
 
 my $tree;
 my $decay = make_spaces($level);
 my @categories = sql_lines({debug=>0,debug_results=>0,table=>"scripts",select=>"id,id_textid_name,id_father",where=>"id_father='$father' ",ordby=>"ordby"});

 my $colspan = 1;
 my $i_category = 0;
 foreach $categorie_ref (@categories)
 {
     my %categorie=%{$categorie_ref};
     
     my $title = "";
     if($action_on_me ne 'this_list_cats_only')
     { 
        ($title,$empty) = get_textcontent($dbh,$categorie{id_textid_name},$lg);
     }
     
     my $suppl_disabled="";
     my $suppl_selected="";
     
     if($me == $categorie{id} && $action_on_me eq 'grey')
     {
        $suppl_disabled=<<"EOH";
   disabled="disabled"      
EOH
     }
     elsif($me == $categorie{id} && $action_on_me eq 'select')
     {
         $suppl_selected=<<"EOH";
   selected="selected"      
EOH
     }
     elsif($menufather == $categorie{id})
     {
        $suppl_selected=<<"EOH";
   selected="selected"      
EOH
     }
            
     if($action_on_me eq 'this_list_cats_only')
     {
         if(is_in_array_int($categorie{id},\@list_cat_only_tab))
         {
                my $pere = '';
			    if($categorie{id_father} > 0)
			    {
					my %father = read_table($dbh,'data_categories',$categorie{id_father});
					my $traduction = get_traduction({debug=>0,id_language=>$lg,id=>$father{id_textid_name}});
					$pere = "$traduction";
				}
               $title = get_traduction({id=>$categorie{id_textid_name},id_language=>$lg});
               $tree .= <<"EOH";     
                     <span data-placement="bottom" data-original-title="Associé à : $pere > $title" class="label label-default" style="font-weight:normal!important;"><span style="font-size:14px">$title</span></span>
EOH
         }
     }
     else
     {
     $tree .= <<"EOH";     
                   <option value="$categorie{id}" $suppl_disabled $suppl_selected>$decay $title  </option>
EOH
     
     }
     $tree.= recurse_scripts($categorie{id},$level+1,$id_data_family,$me,$menufather,$action_on_me,$list_cat_only,$lg);
     $i_category++;
 }
 return $tree;
}



sub change_permission
{
	my $col = get_quoted('col');
	my $id_script = get_quoted('id_script');
	my $id_role = get_quoted('id_role');
	my $is_checked = get_quoted('is_checked') || 'false';

		
	my %migcms_role = sql_line({table=>'migcms_roles',where=>" token != '' AND token = '$token' "});
	my $type_permission = get_quoted('type_permission');
	
	my $col_value = 'n';
	if($is_checked eq 'true')
	{
		$col_value = 'y';
	}
	my %migcms_roles_scripts_permission = 
	(
		id_role => $id_role,
		id_script => $id_script,		
		$col => $col_value,
	);
	sql_set_data({dbh=>$dbh,debug=>0,table=>'migcms_roles_scripts_permissions',data=>\%migcms_roles_scripts_permission, where=>"id_role='$migcms_roles_scripts_permission{id_role}' AND id_script = '$migcms_roles_scripts_permission{id_script}'"});      		
	
	exit;
}