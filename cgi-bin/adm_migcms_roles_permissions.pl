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
if($securite_setup{droits_simples} eq 'y')
{
	my %script_modules = sql_line({table=>'scripts',where=>"url LIKE '%adm_migcms_modules.pl?%'"});
	my $retour  = $script_modules{url}.'&sel='.$script_modules{id};
	cgi_redirect($retour);
	exit;
}

$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 1;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "scripts";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_roles_permissions.pl?";
$dm_cfg{tree} = 1;
$dm_cfg{duplicate} = 0;
$dm_cfg{corbeille} = 0;

if($config{current_language} eq "")
{
   $config{current_language}=get_quoted('lg') || 1;
}


$dm_cfg{modification} = 0;
$dm_cfg{delete} = 0;

$dm_cfg{wherel} = '';

# $dm_cfg{sort} = 0;
$dm_cfg{add} = 0;
$dm_cfg{no_export_excel} = 1;
$dm_cfg{excel} = 0;

$dm_cfg{line_func} = 'custom_tree_levels';  
my $token_role = get_quoted('token_role');
my %migcms_role = sql_line({table=>'migcms_roles',where=>" token != '' AND token = '$token_role' "});
$dm_cfg{hiddp}=<<"EOH";

EOH

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    
      '01/name'=> {
	        'title'=>'Nom complet',
	        'fieldtype'=>'text',
	        'search' => 'y',
	    },
		
		'02/short'=> {
	        'title'=>'Nom court',
	        'fieldtype'=>'text',
	        'search' => 'y',
	    },
		
		'03/icon'=> {
	        'title'=>'Icon Font awesome',
	        'fieldtype'=>'text',
	    },
	    '04/url'=> {
	        'title'=>'URL',
	        'fieldtype'=>'text',
	        'search' => 'y',
	    }
	    ,
	    '09/id_father' => 
      {
           'title'=>'Parent',
           'fieldtype'=>'listboxtable',
           'lbtable'=>'scripts',
           'lbkey'=>'id',
           'lbdisplay'=>'name',
           'lbwhere'=>""
      }
	    ,
	    '10/id_role' => 
      {
       'title'=>'Droit requis',
       'fieldtype'=>'listboxtable',
       'lbtable'=>'roles ',
       'lbkey'=>'id',
       'lbdisplay'=>'function',
       'lbwhere'=>""
      }

	);
%dm_display_fields =  
      (
	      
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
<style>
.list_sort,.mig_cb_col,#migc4_main_table_tbody tr td.text-center,.migedit
{
	display:none!important;
}
.maintitle {
	display : none;
}
</style>

<div class="row">
<div class="col-md-6">
<h1 class="maintitle show">Permissions pour <b>$migcms_role{nom_role}</b></h1>
</div>
<div class="col-md-6 text-right"> </div>
</div>

<script>
jQuery(document).ready(function() 
{
	var self = jQuery('#myself').val();
	var token = '$token_role';
	
	jQuery('.btn_save_permission').click(function()
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
			   token : token,
			   type_permission : jQuery(this).attr('id'),
			   id_module : jQuery(this).attr('rel'),
			   is_checked:jQuery(this).hasClass('btn-success')
			   
			},
			dataType: "html"
		});
		
		request.done(function(msg) 
		{
			
		});
		request.fail(function(jqXHR, textStatus) 
		{
			alert( "Erreur de sauvegarde: " + textStatus );
		});
		return false;
	});	
	
	jQuery('.cliquer_ligne').click(function()
	{
		var ligne = jQuery(this).parent();
		ligne.children('.btn_save_permission').click();
		return false;
	});
	jQuery('.cliquer_ligne_all').click(function()
	{
		var ligne = jQuery(this).parent();
		ligne.children('.btn_save_permission.btn-danger').click();
		return false;
	});
	jQuery('.cliquer_ligne_aucun').click(function()
	{
		var ligne = jQuery(this).parent();
		ligne.children('.btn_save_permission.btn-success').click();
		return false;
	});
	
});
</script>
EOH


# this script's name

$sw = $cgi->param('sw') || "list";

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
			change_permission
		);

if (is_in(@fcts,$sw)) 
{ 
    see();
    dm_init();
    
    
    &$sw();
    $gen_bar = get_gen_buttonbar($members_gen_bar);
    $spec_bar = get_spec_buttonbar($sw);
    if ($sw eq "list") {$spec_bar.=$lnkxls;}
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}

sub change_permission
{
	my $token = get_quoted('token');
	my %migcms_role = sql_line({table=>'migcms_roles',where=>" token != '' AND token = '$token' "});
	my $type_permission = get_quoted('type_permission');
	my $id_module = get_quoted('id_module');
	
	if(get_quoted('is_checked') eq 'true')
	{
		my %detail = 
		(
			id_role => $migcms_role{id},
			id_module => $id_module,		
			type_permission => $type_permission,
		);
		sql_set_data({dbh=>$dbh,debug=>0,table=>'migcms_roles_details',data=>\%detail, where=>"id_role='$detail{id_role}' AND id_module = '$detail{id_module}' AND type_permission = '$detail{type_permission}'"});      		
	}
	else
	{
		$stmt = "delete FROM migcms_roles_details WHERE id_role='$migcms_role{id}' AND id_module = '$id_module' AND type_permission = '$type_permission' ";
		execstmt($dbh,$stmt);
		# print $stmt;
	}
	exit;
}

sub get_nom
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %script = read_table($dbh,"scripts",$id);
  
  my $label = '';
  my %count = select_table($dbh,"scripts","count(id) as total","id_father = '$id'");
  
  
  
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
			code=>"add",
			icon=>"fa fa-fw fa-plus",
		}
		,
		{
			name=>'Modifier',
			code=>"edit",
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
			code=>"delete",
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
		,
		{
			name=>'Email',
			code=>"email",
			icon=>"fa fa-paper-plane-o fa-fw",
		}
		
  );
  
  
  
  my $list_actions = '';
  foreach $action (@actions)
  {
		my %action = %{$action};
		my $ok = 1;
		# if($action{id_modules} ne '')
		# {
			# $ok = 0;
			# my @id_modules = split(/\,/,$action{id_modules});
			# foreach my $id_module (@id_modules)
			# {
				# if($id_module == $id)
				# {
					# $ok = 1;
				# }
			# }
			# if($ok == 0)
			# {
			# }
		# }
		
		my %check_action = sql_line({debug=>0,debug_results=>0,select=>"id",table=>'migcms_roles_details',where=>"id_role='$migcms_role{id}' AND id_module='$id' AND type_permission='$action{code}'"});
		my $btn_class = 'btn-danger';
		if($check_action{id} > 0)
		{
			$btn_class = 'btn-success';
		}
		
		if($ok == 1)
		{
			$list_actions .=<<"EOH";
			  <a href="#" data-placement="top" rel="$id" data-original-title="$action{name}" id="$action{code}" class="btn $btn_class btn_save_permission"><i class="$action{icon}"></i> $action{label}</a>

EOH
		}
		# if($count{total} > 0)
		# {
			# last;
		# }
  }
 
 
   my $name = $script{name};
   
	my $traduction = get_traduction({debug=>0,id_language=>$colg,id=>$script{id_textid_name}});
	if($traduction ne '')
	{
		$name = $traduction;
	}

  
  
  if($count{total} > 0)
  {
	  return <<"EOH";
		<a id="$script{id}" data-original-title="" class="list_tree_link" ><i class="$icon{name}"></i>$name <i class="hide">#$script{id}</i></a>
		<div>
			$list_actions
			<a class="cliquer_ligne btn btn-default"> Inverser</a>
			<a class="cliquer_ligne_all btn btn-success"> Tous</a>
			<a class="cliquer_ligne_aucun btn btn-danger"> Aucun</a>
		</div>
		
</div>
EOH
  }
  else 
  {
	  return <<"EOH";
		$name <i class="hide">#$script{id}</i>
		<div>
			$list_actions
			<a class="cliquer_ligne btn btn-default"> Inverser</a>
			<a class="cliquer_ligne_all btn btn-success"> Tous</a>
			<a class="cliquer_ligne_aucun btn btn-danger"> Aucun</a>
		</div>
		
EOH
  }

}





#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------