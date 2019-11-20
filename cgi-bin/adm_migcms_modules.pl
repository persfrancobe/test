#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

my %securite_setup = sql_line({table=>'securite_setup'});
my $droits = get_quoted('droits');

$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 1;
$dm_cfg{duplicate} = 1;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "scripts";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_modules.pl?droits=$droits";
$dm_cfg{add_title} = "Ajouter un module";
$dm_cfg{tree} = 1;
$dm_cfg{trad} = 1;
$dm_cfg{file_prefixe} = 'MOD';

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;

my @migcms_roles = sql_lines({table=>'migcms_roles',ordby=>"id asc",where=>"id > 1"});
my @migcms_roles_scripts_permissions = sql_lines({table=>'migcms_roles_scripts_permissions'});

my @actions = 
  (
		{
			name=>'Afficher les données',
			code=>"view",
			icon=>"fa fa-fw fa-eye",
		}
		,
		{
			name=>'Ajouter',
			code=>"addr",
			icon=>"fa fa-fw fa-plus",
		}
		,
		{
			name=>'Modifier',
			code=>"editr",
			icon=>"fa fa-fw fa-pencil",
		}
		,
		{
			name=>'Trier',
			code=>"sort",
			icon=>"fa fa-fw fa-sort",
		}
		,
		{
			name=>'Visible/Invisible',
			code=>"visibility",
			icon=>"fa fa-fw fa-eye-slash",
		}
		,
		{
			name=>'Dupliquer',
			code=>"duplicate",
			icon=>"fa fa-fw fa-copy",
		}
		,
		{
			name=>'Corbeille',
			code=>"corbeille",
			icon=>"fa fa-fw fa-trash-o",
		}
		,
		{
			name=>'Supprimer définitivement',
			code=>"deleter",
			icon=>"fa fa-fw fa-trash",
		}
		,
		{
			name=>'Voir éléments supprimés+Restaurer',
			code=>"restauration",
			icon=>"fa fa-fw fa-history",
		}
		,
		{
			name=>'Export Excel',
			code=>"excel",
			icon=>"fa fa-file-excel-o",
		}
		,
		{
			name=>'Import + Export Excel',
			code=>"operations",
			icon=>"fa fa-cloud",
		}
		,
		{
			name=>'Télécharger',
			code=>"download",
			icon=>"fa fa-fw fa-download",
			id_modules=>'169,164,162,161,163,228,226',
		}
		,
		{
			name=>'Email',
			code=>"email",
			icon=>"fa fa-fw fa-at",
			id_modules=>'169,164,162,161,163,179,198',
			
		}
		,
		{
			name=>'Facturer',
			code=>"facturer",
			icon=>"fa fa-fw fa-eur",
			id_modules=>'169,164,162,161,163',

		}
		,
		{
			name=>'Créditer',
			code=>"crediter",
			icon=>"fa fa-fw fa-eur btn-danger",
			id_modules=>'169,164,162,161,163',

		}
		,
		{
			name=>'Verrouiller',
			code=>"lock_on",
			icon=>"fa fa-lock fa-fw btn-warning",
		}
		,
		{
			name=>'Déverrouiller',
			code=>"lock_off",
			icon=>"fa fa-unlock-alt fa-fw btn-success",
		}
		,
		{
			name=>'Voir',
			code=>"viewpdf",
			icon=>"fa fa-eye fa-fw ",
		}
		,
		{
			name=>'Télécharger',
			code=>"telecharger",
			icon=>"fa fa-download fa-fw ",
		}
		
		
  );
  
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
	    
      # '01/name'=> {
	        # 'title'=>$migctrad{fm_name},
	        # 'fieldtype'=>'display',
	        # 'search' => 'y',
	    # },
		
		'02/id_textid_name'=> {
	        'title'=>$migctrad{fm_name},
	        'fieldtype'=>'text_id',
	        'search' => 'y',
	    },
		
		'03/short'=> {
	        'title'=>'Nom court',
	        'fieldtype'=>'text',
	        'search' => 'y',
	    },
		
		'05/icon'=> {
	        'title'=>'Icon Font awesome',
	        'fieldtype'=>'text',
	    },
	    '06/url'=> {
	        'title'=>'URL',
	        'fieldtype'=>'text',
	        'search' => 'y',
	    }
	    # ,
	    # '09/id_father' => 
      # {
           # 'title'=>'Parent',
           # 'fieldtype'=>'listboxtable',
           # 'lbtable'=>'scripts',
           # 'lbkey'=>'id',
           # 'lbdisplay'=>'name',
           # 'lbwhere'=>""
      # }
	  ,
	    '09/id_father' => 
      {
           'title'=>'Parent',
           'fieldtype'=>'listboxtable',
		   'data_type'=>'treeview',
           'lbtable'=>'scripts',
		   'multiple'=>0,
		   'translate'=>1,
           'lbkey'=>'id',
           'lbdisplay'=>'id_textid_name',
           'summary'=>0,
			'tree_col'=>'id_father',

           'lbwhere'=>""
      }
	  # ,
	  # '90/id_referent' => 
      # {
           # 'title'=>'Référent distant (ID)',
           # 'fieldtype'=>'text',
      # }
			
	  # ,
	    # ,
	  # '20/id_admin' => 
      # {
       # 'title'=>"Lien vers écran d'encodage",
       # 'fieldtype'=>'listboxtable',
       # 'lbtable'=>'migcms_admins ',
       # 'lbkey'=>'id',
       # 'lbdisplay'=>'nom',
       # 'lbwhere'=>""
      # }
	  
	  # ,
		
		# '22/class'=> {
	        # 'title'=>'Classe spécifique',
	        # 'fieldtype'=>'text',
	    # }
		
		
		
		
	    # ,
	    # '10/id_role' => 
      # {
       # 'title'=>'Droit requis',
       # 'fieldtype'=>'listboxtable',
       # 'lbtable'=>'roles ',
       # 'lbkey'=>'id',
       # 'lbdisplay'=>'function',
       # 'lbwhere'=>""
      # }
	  ,
	    '58/depli_menu' => 
      {
       'title'=>'Déplier le menu ?',
       'fieldtype'=>'checkbox',
      }
       ,
	    '59/cacher_menu' => 
      {
       'title'=>'Cacher dans le menu',
       'legend'=>'Ne pas afficher dans le menu ?',
       'fieldtype'=>'checkbox',
      }
	  ,
	    '60/synchro' => 
      {
       'title'=>'Synchro',
       'fieldtype'=>'checkbox',
      }
	);
#   "02/Droit requis"=>"id_role"
%dm_display_fields =  
      (
	    	"50/Cacher dans le menu"=>"cacher_menu",
	    	"60/Synchro"=>"synchro"
  
      ); 
	  
	
 
%dm_lnk_fields = (
"01/Nom"=>"get_nom*",
		);

%dm_mapping_list = (
    "get_nom"=>\&get_nom,
);

%dm_filters = (
		);


		
		
		
$dm_cfg{list_html_top} = <<"EOH";	
   	
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
    if ($sw eq "list") {$spec_bar.=$lnkxls;}
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}


sub generer_droits
{
	exit;
	my @scripts = sql_lines({table=>'scripts',ordby=>"",where=>""});
	my @migcms_roles = sql_lines({table=>'migcms_roles',ordby=>"",where=>"id > 1",ordby=>"id desc"});
	foreach $script (@scripts)
	{
		my %script = %{$script};
		
		foreach $migcms_role (@migcms_roles)
		{
			my %migcms_role = %{$migcms_role};
			my %migcms_roles_scripts_permission = 
			(
				id_role => $migcms_role{id},
				id_script => $script{id},
			);
			my $i = 0;
			foreach $action (@actions)
			{
				my %action = %{$action};
				if($migcms_role{id} == 3)
				{
					if($i < 13)
					{
						$migcms_roles_scripts_permission{$action{code}} = 'y';
					}
					else
					{
						$migcms_roles_scripts_permission{$action{code}} = 'n';
					}
				}
				elsif($migcms_role{id} == 4)
				{
					if($i < 12)
					{
						$migcms_roles_scripts_permission{$action{code}} = 'y';
					}
					else
					{
						$migcms_roles_scripts_permission{$action{code}} = 'n';
					}
				}
				elsif($migcms_role{id} == 7)
				{
					if($i < 7)
					{
						$migcms_roles_scripts_permission{$action{code}} = 'y';
					}
					else
					{
						$migcms_roles_scripts_permission{$action{code}} = 'n';
					}
				}
				elsif($migcms_role{id} == 8)
				{
					if($i < 3)
					{
						$migcms_roles_scripts_permission{$action{code}} = 'y';

					}
					else
					{
						$migcms_roles_scripts_permission{$action{code}} = 'n';
					}
				}
				$i++;
			}
			# see(\%migcms_roles_scripts_permission);
			sql_set_data({dbh=>$dbh,debug=>0,table=>'migcms_roles_scripts_permissions',data=>\%migcms_roles_scripts_permission, where=>"id_role='$migcms_roles_scripts_permission{id_role}' AND id_script = '$migcms_roles_scripts_permission{id_script}'"});      		
		}
	}
}


sub get_nom
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %script = read_table($dbh,"scripts",$id);
  
  my $label = '';
  my $colg = get_quoted('lg') || get_quoted('colg');
  my $traduction = get_traduction({debug=>0,id_language=>$colg,id=>$script{id_textid_name}});
  if($traduction ne '')
  {
		$script{name} = $traduction;
  }

  my $line = '';
  
	$line = <<"EOH";
	<i class="$script{icon}"></i> $script{short} $script{name}
EOH
  
   return $line;
}

sub custom_page_add
{
	my $id = $_[0];
	my $colg = $_[1];
	my %page = %{$_[2]};
	my $sel = get_quoted('sel'); #sel item menu
	my %d = ();
	$d{$colg} = $colg;
		
	return <<"EOH";

	<a href="$dm_cfg{self}&sw=add_form&id_father=,$id," data-original-title="Ajouter un sous-module" data-placement="bottom" class="btn btn-info">
	<i class="fa fa-plus fa-fw" data-original-title="" title=""></i> 
	</a>
EOH

}

sub after_save
{
    my $dbh=$_[0];
    my $id =$_[1];
	
	save_all_fathers(0);
	
	my $category_fusion = ''  ;    
	compute_cat_denomination(0,$category_fusion);
	edit_db_sort_tree_recurse(0); 
	

	# save_all_children(0);
}	

sub compute_cat_denomination
{
	my $id_father = $_[0];
	my $category_fusion_r = $_[1];
	
	my @cats = sql_lines({debug=>0,table=>$dm_cfg{table_name},where=>"id_father='$id_father'"});

	foreach $cat (@cats)
	{
		my %cat = %{$cat};
		
		my $nom_module = get_traduction({debug=>0,id=>$cat{id_textid_name},id_language=>1});

		
		my $category_fusion = $category_fusion_r.' > '.$nom_module;
		
		compute_cat_denomination($cat{id},$category_fusion);	
		
		$category_fusion = trim($category_fusion);
		$category_fusion =~ s/^\>//g;
		# $cat{category_reference}.' '.
		$category_fusion = trim($category_fusion);
		$category_fusion =~ s/\'/\\\'/g;
		my $id_avec_prefixe = getcode($dbh,$cat{id});


		
		$stmt = "UPDATE $dm_cfg{table_name} SET fusion= '$id_avec_prefixe | > $category_fusion' WHERE id = $cat{id}";
		execstmt($dbh,$stmt);
	}	
	
}


# sub save_all_children
# {
	# my $id_father = $_[0];
	# my @scripts = sql_lines({table=>'scripts',where=>"id_father='$id_father'",ordby=>'ordby'});
	# foreach $script (@scripts)
    # {
			# my %script = %{$script};
			# my $children = get_children_recurse({id_father=>$script{id}});
			# $stmt = "UPDATE scripts SET id_children ='$children' WHERE id = '$script{id}' ";
			# execstmt($dbh,$stmt);
	# }
# }

# sub get_children_recurse
# {
	# my %d = %{$_[0]};
	# my @scripts = sql_lines({table=>'scripts',where=>"id_father='$id_father'",ordby=>'ordby'});
	# foreach $script (@scripts)
    # {
			# my %script = %{$script};
			# save_fathers($script{id});
			# save_all_fathers($script{id});
	# }

# }

sub save_all_fathers
{
	my $id_father = $_[0];
	my @scripts = sql_lines({table=>'scripts',where=>"id_father='$id_father'",ordby=>'ordby'});
	foreach $script (@scripts)
    {
			my %script = %{$script};
			save_fathers($script{id});
			save_all_fathers($script{id});
	}
}


sub save_fathers
{
	my $id = $_[0];
	
	my %script = sql_line({debug_results=>0,dbh=>$dbh,table=>"scripts",where=>"id='$id'"});
	my $id_fathers = '';
	if($script{id_father} > 0)
	{
		#trouver pere
		my %father = sql_line({debug_results=>0,dbh=>$dbh,table=>"scripts",where=>"id_father='$script{id_father}'"});
		my $id_father = $father{id};
		while ($id_father > 0)
		{
			# if($id_fathers ne '')
			# {
				# $id_fathers .= ',';
			# }
			#ajouter pere
			$id_fathers .= ','.$id_father.',';
			
			#trouver pere du pere
			my %father = sql_line({debug_results=>0,dbh=>$dbh,table=>"scripts",where=>"id='$id_father'"});
			$id_father = $father{id_father};
		}
	}
	
	$stmt = "UPDATE scripts SET id_fathers ='$id_fathers' WHERE id = '$script{id}' ";
    execstmt($dbh,$stmt);
}



    
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------