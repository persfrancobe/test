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
use eshop;

$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "eshop_discounts";
$dm_cfg{list_table_name} = $dm_cfg{table_name};
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_eshop_discounts.pl?";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{validation_func} = \&validation_func;


my %types = (
'eur'=>'Remise en € TVAC',
'perc'=>'Remise en %'
);   

my %discount_types = (
'01/produit'=>'Sur des produits',
'02/panier'=>'Sur le total du panier',
);   

    

my %data_cfg = get_hash_from_config($dbh,"data_cfg");
my %famille_par_defaut = read_table($dbh,"data_families",$data_cfg{default_family});
my $id_field_name = $famille_par_defaut{id_field_name};
my %data_field = read_table($dbh,"data_fields",$id_field_name);

my $tab = '';
my $cpt = 9;

@dm_nav =
	(
		 {
			'tab'=>'Remise',
			'type'=>'tab',
			'title'=>'Remise'
		}
		,
		 {
			'tab'=>'Produits',
			'type'=>'tab',
			'title'=>'Cibler les produits'
		}
		,
		{
			'tab'=>'Coupon',
			'type'=>'tab',
			'title'=>'Déclenchement par coupon'
		}
			,
		 {
			'tab'=>'Conditions',
			'type'=>'tab',
			'title'=>'Conditions supplémentaires'
		}
	);

#my $hidden_evite_produits_deja_remise = 1;
#my %codes = tools::get_codes();
#my $sitename = $codes{shoeman_config}{sitename}{v1};
#si module shoeman active: on peut cibler les produits sans prix réduits (qui ne sont pas des soldes)
#if($sitename ne '')
#{
#	$hidden_evite_produits_deja_remise = 0;
#}



%dm_dfl = 
(    

sprintf("%05d", $cpt++).'/nom'=>{'title'=>'Nom *',legend=>'Décrire la promotion en quelques mots, ne sera pas affiché publiquement','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab='Remise','default_value'=>'','lbtable'=>'handmade_codes_contacts_clients','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
sprintf("%05d", $cpt++).'/discount_type'=>{'title'=>'Type de remise *','translate'=>0,'fieldtype'=>'listbox','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'data_sheets','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>\%discount_types,'hidden'=>0},
sprintf("%05d", $cpt++).'/id_tarif'=>{'title'=>'Tarif *','translate'=>0,'list_edit'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'eshop_tarifs','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"",'fieldvalues'=>'','hidden'=>0},

# sprintf("%05d", $cpt++).'/titre'=>{'title'=>'<b style="font-size:18px">Valeur *</b>','translate'=>0,'fieldtype'=>'titre','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'data_sheets','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},
sprintf("%05d", $cpt++).'/discount_eur'=>{'title'=>'Remise en €','translate'=>0,'fieldtype'=>'text','data_type'=>'euros','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'handmade_codes_contacts_clients','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
sprintf("%05d", $cpt++).'/discount_perc'=>{'title'=>'OU Remise en %','translate'=>0,'fieldtype'=>'text','data_type'=>'perc','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'handmade_codes_contacts_clients','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},


sprintf("%05d", $cpt++).'/titre'=>{'title'=>'Si la remise porte seulement sur certains produits, précisez la cible (1 choix):','translate'=>0,'fieldtype'=>'titre','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab='Produits','default_value'=>'','lbtable'=>'data_sheets','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},
sprintf("%05d", $cpt++).'/target_all'=>{'title'=>'Tous les produits','translate'=>0,'fieldtype'=>'checkbox','legend'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
# sprintf("%05d", $cpt++).'/target_sheets_from'=>{'title'=>'Par référence','legend'=>'Utilisez les premières lettres pour cibler tous les produits commençant par cette référence, par ex: 18 pour les produits dont la référence commence par 18','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
 sprintf("%05d", $cpt++).'/target_categories' => 
{
   'title'=>'Par catégorie(s)',
   'fieldtype'=>'listboxtable',
   'data_type'=>'treeview',
   'lbtable'=>'data_categories',
   'translate'=>1,
   'lbkey'=>'id',
   'lbdisplay'=>'id_textid_name',
   'summary'=>0,
   'tree_col'=>'id_father',
   'legend'=>'',
   'lbwhere'=>"",
   'tab'=>$tab,
},
sprintf("%05d", $cpt++).'/target_sheets'=>{'title'=>'Un seul produit','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'autocomplete','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'data_sheets','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},


# sprintf("%05d", $cpt++).'/titre'=>{'title'=>'<b style="font-size:18px">Conditions supplémentaires</b>','translate'=>0,'fieldtype'=>'titre','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab='Conditions','default_value'=>'','lbtable'=>'data_sheets','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>'','hidden'=>0},

	sprintf("%05d", $cpt++).'/target_coupons'=>{'title'=>'Coupons','legend'=>'Un ou plusieurs coupons séparés par des virgules, sans espace. Doit être encodé en majuscules avec seulement des lettres et des chiffres. Exemple: HIVER,STVALENTIN,ETE2018','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab='Coupon','default_value'=>'','lbtable'=>'handmade_codes_contacts_clients','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},

sprintf("%05d", $cpt++).'/coupon_qte_totale'=>{'title'=>'Nb. de coupons total','legend'=>'0 = illimité','mask'=>'999999','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
sprintf("%05d", $cpt++).'/coupon_qte_restante'=>{'title'=>'Nb. de coupons restant ','legend'=>'','translate'=>0,'fieldtype'=>'display','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},

	sprintf("%05d", $cpt++).'/func'=>{'default_value'=>'','title'=>'','translate'=>0,'fieldtype'=>'func','func'=>'eshop::utilisation_coupons','search' => 'n','mandatory'=>{'type' => ''},tab=>$tab,'lbtable'=>'migcms_codes','lbkey'=>'id','lbdisplay'=>"id_textid_name",'lbwhere'=>"id_code_type='30' AND visible='y'",'lbordby'=>'code','fieldvalues'=>'','hidden'=>0},

sprintf("%05d", $cpt++).'/target_qty'=>{'title'=>'Quantité minimum de produits dans le panier','legend'=>'','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab='Conditions','default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},

#	sprintf("%05d", $cpt++).'/evite_produits_deja_remise'=>{'title'=>'Produits sans promotion seulement','legend'=>'Valable seulement pour le type de remise "Sur des produits". Le type de remise "Sur le total du panier" correspond au total sans distinction des produits.','translate'=>0,'fieldtype'=>'checkbox','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>$hidden_evite_produits_deja_remise},

sprintf("%05d", $cpt++).'/begin_date'=>{'title'=>'Date de début','translate'=>0,'fieldtype'=>'text','data_type'=>'date','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'handmade_codes_contacts_clients','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
sprintf("%05d", $cpt++).'/end_date'=>{'title'=>'Date de fin','translate'=>0,'fieldtype'=>'text','data_type'=>'date','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'handmade_codes_contacts_clients','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
# sprintf("%05d", $cpt++).'/nb_utilisations'=>{'title'=>'Nombre d\'utilisations disponibles','legend'=>'Utilisé uniquement lors d\'une remise avec coupon. Limite de nombre d\'utilisation de la remise. Laisser vide pour ne pas utiliser cette option.','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'data_sheets','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>\%nbuses,'hidden'=>0},
# sprintf("%05d", $cpt++).'/minimum'=>{'title'=>'Total du panier minimum (HTVA)','translate'=>0,'fieldtype'=>'text','data_type'=>'euros','search' => 'n',''=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'data_sheets','lbkey'=>'id','lbdisplay'=>'fusion','lbwhere'=>"fusion != ''",'lbordby'=>"fusion",'fieldvalues'=>\%nbuses,'hidden'=>0},
# sprintf("%05d", $cpt++).'/target_members_logged'=>{'title'=>'Seulement pour les clients connectés','translate'=>0,'fieldtype'=>'checkbox','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
);

%dm_display_fields = 
(
	"01/Nom"=>"nom",
	"02/Type de remise"=>"discount_type",
	"03/Tarif"=>"id_tarif",
);

%dm_lnk_fields = (
"05/Conditions"=>"conditions*",
		);

%dm_mapping_list = (
"conditions"=>\&get_conditions,
);


# my %target_sheets = ();
# my @sheets = sql_lines({dbh=>$dbh,table=>"data_sheets",select=>"id,f1,f2",ordby=>'ORDER BY f1,f2'});
# foreach $sheet (@sheets)
# {
    # my %sheet = %{$sheet};
    # $target_sheets{$sheet{id}}="$sheet{f1} $sheet{f2}";
# } 

# my %liste_tarifs = ();
# my @tarifs = sql_lines({dbh=>$dbh,table=>"eshop_tarifs",select=>"",ordby=>'ORDER BY id'});
# foreach $tarif (@tarifs)
# {
    # my %tarif = %{$tarif};
    # $liste_tarifs{$tarif{id}}=$tarif{name};
# } 
         
%dm_filters = (
"2/Produit"=>
{
      'type'=>'hash',
	     'ref'=>\%target_sheets,
	     'col'=>'target_sheets'
}
,
"3/Tarif"=>
{
      'type'=>'hash',
	     'ref'=>\%liste_tarifs,
	     'col'=>'id_tarif'
}
);

$dm_cfg{help_url} = "http://www.bugiweb.com";

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

    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    
    $dm_output{content} .=<<"EOH";
    
    <script>
	jQuery(function() 
  {
		function sql_date_to_human_date(date)
    {
              var star_date_infos = String(date).split('-');
              var jour=star_date_infos[2];
              var mois=star_date_infos[1];
              var annee=star_date_infos[0];
              var date_str='';
              
              if(jour > 0 && mois > 0 && annee > 0)
              {
                  date_str=jour+'/'+mois+'/'+annee;
                  return date_str;
              }
              else
              {
                  return date;
              }
    }
    jQuery( "#field_begin_date" ).val(sql_date_to_human_date(jQuery( "#field_begin_date" ).val()));
    jQuery( "#field_end_date" ).val(sql_date_to_human_date(jQuery( "#field_end_date" ).val()));
    
    jQuery.datepicker.setDefaults( jQuery.datepicker.regional[ "" ] );
    jQuery.datepicker.regional['fr'] = {
		closeText: 'Fermer',
		prevText: '&#x3c;Préc',
		nextText: 'Suiv&#x3e;',
		currentText: 'Courant',
		monthNames: ['Janvier','Février','Mars','Avril','Mai','Juin',
		'Juillet','Août','Septembre','Octobre','Novembre','Décembre'],
		monthNamesShort: ['Jan','Fév','Mar','Avr','Mai','Jun',
		'Jul','Aoû','Sep','Oct','Nov','Déc'],
		dayNames: ['Dimanche','Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi'],
		dayNamesShort: ['Dim','Lun','Mar','Mer','Jeu','Ven','Sam'],
		dayNamesMin: ['Di','Lu','Ma','Me','Je','Ve','Sa'],
		weekHeader: 'Sm',
		dateFormat: 'dd/mm/yy',
		firstDay: 1,
		isRTL: false,
		showMonthAfterYear: false,
		yearSuffix: ''};
	  jQuery.datepicker.setDefaults(jQuery.datepicker.regional['fr']);
  
		jQuery( "#field_begin_date" ).datepicker( jQuery.datepicker.regional[ "fr" ] );
    jQuery( "#field_end_date" ).datepicker( jQuery.datepicker.regional[ "fr" ] );
	});
  
  
  
  
	</script>
    
EOH
    
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}

sub after_save
{
    my $dbh=$_[0];
    my $id=$_[1];
	
	my %rec = read_table($dbh,$dm_cfg{table_name},$id);
	
	#nettoyage conditions inférieures
	if($rec{target_all} eq 'y')
	{
		execstmt($dbh,"UPDATE $dm_cfg{table_name} SET target_categories = '',target_sheets_from='',target_sheets='' WHERE id ='$rec{id}'");	
	}
	elsif($rec{target_sheets_from} ne '')
	{
		execstmt($dbh,"UPDATE $dm_cfg{table_name} SET target_categories = '',target_sheets='' WHERE id ='$rec{id}'");	
	}
	elsif($rec{target_categories} ne '' && $rec{target_categories} ne ',')
	{
		execstmt($dbh,"UPDATE $dm_cfg{table_name} SET target_sheets='' WHERE id ='$rec{id}'");	
	}
	
	if($rec{discount_eur} > 0)
	{
		execstmt($dbh,"UPDATE $dm_cfg{table_name} SET discount_perc = 0 WHERE id ='$rec{id}'");	
		execstmt($dbh,"UPDATE $dm_cfg{table_name} SET discount_value_on_total = $rec{discount_eur}, discount_type_on_total = 'eur' WHERE id ='$rec{id}'");	
	}
	elsif($rec{discount_perc} > 0)
	{
		execstmt($dbh,"UPDATE $dm_cfg{table_name} SET discount_value_on_total = $rec{discount_perc}, discount_type_on_total = 'perc' WHERE id ='$rec{id}'");	
	}
	
	#complete les virgules nécessaires (début et fin)
	if($rec{target_coupons} ne '')
	{
		if($rec{target_coupons} !~ /^,/)
		{
			execstmt($dbh,"UPDATE $dm_cfg{table_name} SET target_coupons = CONCAT(',',target_coupons) WHERE id ='$rec{id}'");	
		}
		if($rec{target_coupons} !~ /,$/)
		{
			execstmt($dbh,"UPDATE $dm_cfg{table_name} SET target_coupons = CONCAT(target_coupons,',') WHERE id ='$rec{id}'");	
		}
	}
	
	if($rec{target_categories} ne '')
	{
		if($rec{target_categories} !~ /^,/)
		{
			execstmt($dbh,"UPDATE $dm_cfg{table_name} SET target_categories = CONCAT(',',target_categories) WHERE id ='$rec{id}'");	
		}
		if($rec{target_categories} !~ /,$/)
		{
			execstmt($dbh,"UPDATE $dm_cfg{table_name} SET target_categories = CONCAT(target_categories,',') WHERE id ='$rec{id}'");	
		}
	}

	#recalcul du nb de coupons disponibles
	my $stmt = <<"EOH";
	UPDATE eshop_discounts d SET coupon_qte_restante = (coupon_qte_totale - (SELECT COUNT(*) FROM coupon_journal WHERE id_eshop_discount=d.id)) WHERE target_coupons != '' AND coupon_qte_totale > 0
EOH
	execstmt($dbh,$stmt);
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

		 if ($dm_dfl{$key}{fieldtype} eq "text_id" || $dfl{$key}{fieldtype} eq "textarea_id")
      {           
       %item = %{update_textid_field($dbh,$field,$op,\%item)};
      }
      elsif ($dm_dfl{$key}{fieldtype} eq "file")
      { 
             
             if($datadir_config{upload_path} eq "")
             {
                $datadir_config{upload_path}=$config{root_path}.'/usr/';
             }
             
             
             
             %item = %{update_file_field_admin($dbh,$field,$op,\%item,$datadir_config{upload_path})};

            
             
             if ($item{$field} eq "") {delete $item{$field};} elsif ($item{$field} eq " "){$item{$field}="";} 
      }
      elsif ($dm_dfl{$key}{fieldtype} eq "pic")
      { 
           %item = %{update_pic_field_admin($dbh,$field,$op,\%item,$datadir_config{upload_path})};
           if ($item{$field} eq "") {delete $item{$field};}
      }
      
		if (defined $dm_dfl{$key}{mandatory})
		{
			if (!check_field_value($item{$field}, $dm_dfl{$key}{mandatory}{type}, \@{$dm_dfl{$key}{mandatory}{params}}))
			{
				dm_check_error($dm_dfl{$key}{title});
			}
		}
  }

  if($item{begin_date} ne "")
  {
     my ($dd,$mm,$yyyy) = split (/\//,$item{begin_date});
     $item{begin_date} = "$yyyy-$mm-$dd";
  }
  if($item{end_date} ne "")
  {
     my ($dd,$mm,$yyyy) = split (/\//,$item{end_date});
     $item{end_date} = "$yyyy-$mm-$dd";
  }
  
#   @coupons = split(/\,/,$item{coupons});
#   foreach $coupon (@coupons)
#   {
#       my %coup = ();
#       $coup{code}=lc($coupon);
#       $coup{type}='generic';
#       $coup{visible}='y';
#       sql_update_or_insert($dbh,"coupons",\%coup,'code',$coup{code});                
#   } 

  # if($item{discount_value_on_total} < 0)
  # {
      # $item{discount_value_on_total} *= -1;
  # }
  # $item{discount_coupon} = simplifier_ce_coupon($item{discount_coupon});
  # my %set_coupon = 
  # (
      # nom => $item{discount_coupon},
      # coupons => $item{discount_coupon},
      # nb_uses_total => 1000000,
      # nb_uses_email => 1000000,
      # visible => 'y'
  # );
  # sql_set_data({debug=>0,dbh=>$dbh,table=>'eshop_coupons',data=>\%set_coupon,cold_id=>'id',where=>"nom ='$item{discount_coupon}' AND coupons='$item{discount_coupon}'"});
	# return (\%item);	
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_form
{
	my %item = %{$_[0]};
	my $form = build_form(\%dm_dfl,\%item);
	return $form;
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_conditions
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  
  
  
  
  
  my %eshop_discount = sql_line({table=>"eshop_discounts",where=>"id='$id'"});
  my %eshop_tarif = sql_line({table=>"eshop_tarifs",where=>"id='$eshop_discount{id_tarif}'"});
  my $conditions ="";
  my $list_categories = '';
  my @array_categories = split(/\,/,$eshop_discount{target_categories});
   
   
  if($eshop_discount{target_all} eq 'y')
  {
    $conditions .= "<b>Tous les produits</b><br />"; 
  }
  elsif($eshop_discount{target_sheets_from} ne '')
  {
	$conditions .= "Les produits dont la référence commence par :<b>$eshop_discount{target_sheets_from}...</b><br />"; 
  }
  elsif($#array_categories > -1)
  {
		foreach my $id_category(@array_categories)
		{
			if($id_category > 0)
			{
				my %data_category = sql_line({table=>'data_categories',select=>"id,fusion,id_textid_name",where=>"id='$id_category'"});
				if($data_category{id} > 0)
				{
					my $title = get_traduction({id=>$data_category{id_textid_name},id_language=>1});
					$list_categories .= <<"EOH";     
						<span data-placement="bottom" data-original-title="$data_category{fusion}" class="label label-default" style="font-weight:normal!important;"><span style="font-size:14px">$title</span></span>
EOH
				}
			}
		}
		$conditions .= "<b>Par catégorie(s)</b>:<br />$list_categories<br />";
  }
  elsif($eshop_discount{target_sheets} > 0)
  {
      my %ds = read_table($dbh,"data_sheets",$eshop_discount{target_sheets});
      $conditions .= "Le produit <b>$ds{fusion}</b><br />"; 
  }
   
  if($eshop_discount{discount_eur} > 0)
  {
   $conditions .= "<b>Valeur</b>: ".$eshop_discount{discount_eur}.' €<br />';
  }
  elsif($eshop_discount{discount_perc} > 0)
  {
   $conditions .= "<b>Valeur</b>: ".$eshop_discount{discount_perc}.' %<br />';
  }
   
  if($eshop_discount{target_coupons} ne '')
  {
  $eshop_discount{target_coupons}=~ s/^,//g;
  $eshop_discount{target_coupons}=~ s/,$//g;
  $eshop_discount{target_coupons}=~ s/,/, /g;
   $conditions .= "<b>Coupons</b>: ".$eshop_discount{target_coupons}.'<br />';
  }
  
  if($eshop_discount{target_qty} > 0)
  {
   $conditions .= "<b>Quantité minimum</b>: ".$eshop_discount{target_qty}.'<br />';
  }
   # if($eshop_discount{minimum} > 0)
  # {
   # $conditions .= "<b>Total du panier minimum (HTVA)</b>: ".$eshop_discount{minimum}.' €<br />';
  # }
   
  if($eshop_discount{begin_date} ne '0000-00-00' || $eshop_discount{end_date} ne '0000-00-00')
  {
   $conditions .= "<b>Date(s)</b>: ";
  }
   
  if($eshop_discount{begin_date} ne '0000-00-00')
  {
     my ($yyyy,$mm,$dd) = split(/\-/,$eshop_discount{begin_date});
     $conditions .= "du $dd/$mm/$yyyy"; 
  }
  if($eshop_discount{end_date} ne '0000-00-00')
  {
     my ($yyyy,$mm,$dd) = split(/\-/,$eshop_discount{end_date});
     $conditions .= " au $dd/$mm/$yyyy"; 
  }
  
  # if($eshop_discount{minimum_qty} > 0)
  # {
    # $conditions .= "<br />A partir de $eshop_discount{minimum_qty} unités"; 
  # }
  
  # if($eshop_discount{nb_utilisations} ne '')
  # {
    # $conditions .= "<br />Nombre d'utilisations restantes: <b>$eshop_discount{nb_utilisations}</b>"; 
  # }
  # if($eshop_discount{target_members_logged} eq 'y')
  # {
    # $conditions .= "<br />Seulement pour les clients connectés"; 
  # }
  
  return $conditions;
}

sub simplifier_ce_coupon
{
    my $nom = $_[0];
    $nom =~ s/[^0-9a-zA-Z\s\-]+//g;
    return $nom;
}

sub validation_func
{
	my $dbh=$_[0];
    my %item = %{$_[1]};
	my $id = $_[2];
	
	log_debug('validation','vide','validation');
	log_debug('ID:'.$id,'','validation');
	

	#MODIFICATION
	my $rapport = '';
	my $valide = 1;
	
	#champs obligatoires p
	my @obligatoires_champs = qw
	(
		nom
		discount_type
		id_tarif
	);
	
	my @obligatoires_noms = 
	(
		'Nom',
		'Type de remise',
		'Tarif',
	);

	#regles basiques (champs complété)
	my $c = 0;
	
	foreach my $obligatoires_champ (@obligatoires_champs)
	{
		log_debug($obligatoires_champ.':'.$item{$obligatoires_champ},'','validation');
		my $nom = $obligatoires_noms[$c];
		if($item{$obligatoires_champ} eq '' || $item{$obligatoires_champ} eq ',')
		{
			$valide = 0;
			$rapport .=<<"EOH";
			<tr><td><i class="fa fa-times"></i> $nom</td><td>Le champs doit être complété.</td></tr>
EOH
		}
		$c++;
	}
	
	if($item{discount_eur} > 0 || $item{discount_perc} > 0)
	{
	}
	else
	{
		$valide = 0;
		$rapport .=<<"EOH";
				<tr><td><i class="fa fa-times"></i> Valeur</td><td>Entrez une valeur de remise en € ou en %.</td></tr>
EOH
	
	
	}


#	evite_produits_deja_remise: Valable seulement pour le type de remise "Sur des produits". Le type de remise "Sur le total du panier" correspond au total sans distinction des produits.
#	if($item{evite_produits_deja_remise} eq 'y' && $item{discount_type} ne 'produit')
#	{
#		$valide = 0;
#		$rapport .=<<"EOH";
#				<tr><td><i class="fa fa-times"></i> Produits sans promotion seulement</td><td>Valable seulement pour le type de remise "Sur des produits". Le type de remise "Sur le total du panier" correspond au total sans distinction des produits.</td></tr>
#EOH
#
#
#	}

	#coupon encodé et non valide
	if($item{target_coupons} ne '' && $item{target_coupons} =~ /[^A-Z0-9,]+/)
	{
		$valide = 0;
		$rapport .=<<"EOH";
				<tr><td><i class="fa fa-times"></i>Coupons</td><td>La valeur de coupons n'est pas valide:<br>Un ou plusieurs coupons séparés par des virgules, sans espace. <br>Doit être encodé en MAJUSCULES avec seulement des lettres et des chiffres. Exemple: HIVER,STVALENTIN,ETE2018</td></tr>
EOH
	
	
	}
	
	#si panier et pas de coupon valide
	if($item{discount_type} eq 'panier' && ($item{target_coupons} eq '' || $item{target_coupons} =~ /[^A-Z0-9,]+/))
	{
		$valide = 0;
		$rapport .=<<"EOH";
				<tr><td><i class="fa fa-times"></i>Coupons</td><td>Avec le type de remise: <b>Sur le total du panier</b>, vous devez encoder un code coupon valide: :<br>Un ou plusieurs coupons séparés par des virgules, sans espace. <br>Doit être encodé en MAJUSCULES avec seulement des lettres et des chiffres. Exemple: HIVER,STVALENTIN,ETE2018
				</td></tr>
EOH
	
	}
	
	#cible de produits encodé
	if($item{target_sheets} > 0 ||($item{target_categories} ne '' && $item{target_categories} ne ','& $item{target_categories} != 0) || $item{target_sheets_from} ne '' || $item{target_all} eq 'y')
	{
		#si panier: pas compatible
		if($item{discount_type} eq 'panier')
		{
			$valide = 0;
			$rapport .=<<"EOH";
					<tr><td><i class="fa fa-times"></i>Cibler les produits</td><td>Vous ne pouvez pas cibler des produits spécifiques avec une remise: Type de remise: <b>Sur le total du panier</b>
					</td></tr>
EOH
		
		}
	}
	else
	{
		#si produit: nécessaire
		if($item{discount_type} eq 'produit')
		{
			$valide = 0;
			$rapport .=<<"EOH";
					<tr><td><i class="fa fa-times"></i>Cibler les produits</td><td>Vous avez choisi une remise de type <b>Sur des produits</b>, vous devez donc choisir au moins une option dans l'onglet <b>Cibler les produits</b>. 
						<ul>
							<li>Soit la case à cocher 'Tous les produits'</li>
							<li>Soit par rérerence</li>
							<li>Soit par catégorie(s)</li>
							<li>Soit un seul produit</li>
						</ul>
					</td></tr>
EOH
		}
	}
	
	if($rapport ne '')
	{
		log_debug('rapport:'.$rapport,'','validation');
		
		$rapport =<<"EOH";
		<h5><i class="fa fa-info"></i> Avant de sauvegarder,vous devez compléter certaines informations obligatoires</u>:</h5>
		<table class="table table-hover table-striped table-bordered">
			<thead>
				<tr>
					<th>Onglet > champs</th>
					<th>Action à entreprendre</th>
				</tr>
			</thead>
			<tbody>
				$rapport
			</tbody>
		</table>
EOH
		
		return 'validation_error___'.$rapport;
	}
	else
	{
		return '';
	}

}