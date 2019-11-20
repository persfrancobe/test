#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

# migc modules

         # migc translations



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();
$colg = get_quoted('colg') || $config{default_colg};

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 1;
$dm_cfg{trad} = 1;

$dm_cfg{wherel} = "";
$dm_cfg{table_name} = "eshop_payments";
$dm_cfg{list_table_name} = "eshop_payments";
$dm_cfg{disable_del_button}='n';

$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/eshop_payments.pl?";
$dm_cfg{after_mod_ref} = \&update_embed;
$dm_cfg{after_add_ref} = \&add_embed;
$dm_cfg{duplicate}='n';
$dm_cfg{hide_id} = 1;

$config{logfile} = "trace.log";

@dm_nav =
(
    {
        'tab'=>'config',
		'type'=>'tab',
        'title'=>'Configuration'
    }
	,
	{
		'tab'   =>'auto',
		'type'  =>'func',
		'title' =>'Tarifs associés',
		'func'  => 'get_payment_tarifs',
    }
	,
);

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
      '01/name'=> 
      {
	        'title'=>'Identifiant (Ne pas modifier)',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	        'tab' => 'config'
	    }
	    ,
      '02/id_textid_name'=> 
      {
	        'title'=>'Nom',
	        'fieldtype'=>'text_id',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	        'tab' => 'config'
	    }
	    ,
	    '03/id_textid_description'=> 
      {
	        'title'=>'Description',
	        'fieldtype'=>'textarea_id_editor',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => 'config'
	    }
      ,
      '06/remove_qty_from_stock'=> 
      {
	        'title'=>'Diminuer la quantité du stock',
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y',
	        'tab' => 'config'
	    }
      ,
	    '07/params'=> 
      {
	        'title'=>'Paramètres techniques (Ne pas modifier)',
	        'fieldtype'=>'textarea',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => 'config'
	    }
	);

%dm_display_fields = (
	"01/Identifiant"=>"name",
	"02/Diminuer la quantité du stock"=>"remove_qty_from_stock"  
		);

%dm_lnk_fields = (
		);

%dm_mapping_list = (
);

%dm_filters = (
		);

$dm_cfg{help_url} = "http://www.bugiweb.com";

# this script's name

$sw = $cgi->param('sw') || "list";
my $selfcolg=$self.'&sw='.$sw.'&id='.get_quoted('id');       

$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="colg" value="$colg" />
EOH

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
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    print migc_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_and_check
{
	my %item; 
  my $op = $_[0];
  
  
	foreach $key (keys(%dm_dfl))
	{ 
		my ($num,$field) = split(/\//,$key);
		
		$item{$field} = get_quoted($field);

		if ($dm_dfl{$key}{fieldtype} eq "text_id" || $dm_dfl{$key}{fieldtype} eq "textarea_id" || $dm_dfl{$key}{fieldtype} eq "textarea_id_editor")
      {           
       %item = %{update_textid_field($dbh,$field,$op,\%item)};
      }
      
		if (defined $dm_dfl{$key}{mandatory})
		{
			if (!check_field_value($item{$field}, $dm_dfl{$key}{mandatory}{type}, \@{$dm_dfl{$key}{mandatory}{params}}))
			{
				dm_check_error($dm_dfl{$key}{title});
			}
		}
  }

	return (\%item);	
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_form
{
	my %item = %{$_[0]};
	
	my $form = build_form(\%dm_dfl,\%item);

	return $form;
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_view
{
	my %item = %{$_[0]};
	my $form = build_view(\%dm_dfl,\%item);

	return $form;
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub before_del
{
  my $dbh = $_[0];
  my $id = $_[1];
}

sub add_embed
{
  my $dbh = $_[0];
  my $id = $_[1];
  
}

sub update_embed
{
  my $dbh = $_[0];
  my $id = $_[1];
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

sub get_payment_tarifs
{

  	my $id_payment = get_quoted("edit_id");
	
	# Récupération des tarifs
	my @tarifs = sql_lines({dbh=>$dbh, table=>"eshop_tarifs"});

	my $script = get_payment_tarifs_script();

	my $content = $script;

	foreach $tarif (@tarifs)
	{
		my %tarif = %{$tarif};

		# Récupération de la liaison entre le tarif et la méthode de paiement
		my %lnk_payment_tarif = sql_line({dbh=>$dbh, table=>"eshop_lnk_payments_tarifs", where=>"id_tarif = $tarif{id} && id_payment = '$id_payment'"});

		my $checked = "";
		if($lnk_payment_tarif{id} > 0)
		{
			$checked = "checked";
		}

		$content .= <<"HTML";
			<div class="form-group item  row_edit_remove_qty_from_stock  migcms_group_data_type_ hidden_">
					<label for="tarif_$tarif{id}" class="col-sm-3 control-label">
						$tarif{name} 
					</label>
					<div class="col-sm-9 mig_cms_value_col">
	                    <input id="tarif_$tarif{id}" id_tarif="$tarif{id}" id_payment="$id_payment" $checked class="form-control edit_lnk_payment_tarif" type="checkbox">  
					</div>
				</div>
HTML

	}


	print $content;
	exit;	
}

sub get_payment_tarifs_script
{
	my $script = <<"HTML";
		<script type="text/javascript">
			jQuery(function()
			{
				jQuery(document).on("change", ".edit_lnk_payment_tarif", edit_lnk_payment_tarif)
				jQuery(".edit_lnk_payment_tarif").each(function(){
					console.log("checkbox");
				})
			});

			function edit_lnk_payment_tarif()
			{
				console.log("ici");
				var element = jQuery(this);
				var parent = element.parent();

				parent.empty().append('<img src="../mig_skin/img/ajax-loader.gif">');

				var id_tarif = element.attr("id_tarif");
				var id_payment = element.attr("id_payment");

				var action = "remove";
				if(element.is(":checked"))
				{
					action = "add";
				}

				jQuery.ajax(
				{
				 	type: "POST",
				 	url: self,
				 	data: 
			        {
			           sw : 'ajax_edit_lnk_payment_tarif',
			           id_tarif : id_tarif,
					   id_payment: id_payment,
					   action : action,
			        },

				 	success: function(msg)
				 	{
				 		var content;
				    	if(msg != "ko")
				    	{
				    		var checked = '';
				    		if(msg == "add")
				    		{
				    			checked = "checked";
				    		}
				    		content = "<input id='tarif_"+id_tarif+"' id_tarif='"+id_tarif+"' id_payment='"+id_payment+"' "+checked+" class='form-control edit_lnk_payment_tarif' type='checkbox'>";
				    	}
				    	else
				    	{
				    		content = "Une erreur est survenue";
				    	}

				    	parent.empty().append(content);
				 	}
				});
			}
		</script>
HTML
}

sub ajax_edit_lnk_payment_tarif
{
	my $action     = get_quoted("action");
	my $id_tarif   = get_quoted("id_tarif");
	my $id_payment = get_quoted("id_payment");

	my $response = "ko";

	if($id_tarif > 0 && $id_payment > 0)
	{
		if($action eq "add")
		{
			# On vérifie qu'il n'y a pas encore d'entrée en DB
			my %existing_lnk = sql_line({dbh=>$dbh, table=>'eshop_lnk_payments_tarifs', where=>"id_tarif = '$id_tarif' AND id_payment = '$id_payment'"});
			if(!($existing_lnk{id}>0))
			{
				my $stmt = <<"SQL";
				INSERT INTO eshop_lnk_payments_tarifs (id_tarif, id_payment)
				VALUES ($id_tarif,$id_payment)
SQL
				execstmt($dbh,$stmt);
			}
			

			$response = "add";
		}
		elsif ($action eq "remove")
		{
			my $stmt = <<"SQL";
				DELETE FROM eshop_lnk_payments_tarifs
				WHERE id_tarif = '$id_tarif'
					AND id_payment = '$id_payment'
SQL
			execstmt($dbh,$stmt);

			$response = "remove";
		}
	}

	print $response;
	exit;
}