package eshop;

@ISA = qw(Exporter);	#Permet l'export
@EXPORT = qw(
									get_eshop_cart_box
									get_eshop_member_box
									link_order_and_continue_if_logged
									eshop_get_id_tarif_member
									get_product_prices
									get_product_prices_get_remise
									get_product_prices_apply_discount
									get_default_payment_method_name
									get_setup
									eshop_signup_member
									get_identities_fields
									recompute_order
									create_eshop_order
									get_eshop_order
									lnk_order_to_member
									get_breadcrumb
									get_edit_identity_content
									get_orders_history_content
									get_delivery_price
									eshop_get_id_group_member
									generate_sequential_num_db
									eshop_mailing_facture

									edit_identity_db
									exec_post_edit_identity

									eshop_mailing_newsletter_subscription
	                eshop_mailing_order_send
	                eshop_mailing_confirmation
	                eshop_mailing_facture
	                eshop_mailing_order_finished
	                eshop_mailing_relance_panier
	                eshop_mailing_relance_paiement
	                eshop_mailing_subscribe
	                eshop_mailing_update_status
	                eshop_mailing_facture_pdf

	                get_eshop_emails_setup 
	                get_eshop_emails_config_trad
	                get_eshop_emails_header
	                get_eshop_emails_footer
	                get_eshop_emails_products

	                get_country_name

	                generate_facture
	                create_pdf_pages
	                cutText

	                update_stock
	                exec_post_order

	                get_order_moment
	                get_order_retour_content

	                change_status

	                display_price
	                display_price2
	                display_price4

	                reset_bpost_compute
					

	                simplifier
					get_adresses_fields
					historique
            );
use def;
use def_handmade;
use tools;
use sitetxt;
use setup;
use JSON::XS;
use Math::Round;
use members;

       
my $lg = get_quoted('lg');
if($lg > 0 && $lg <= 10)
{
	$lg = 1;
}
$config{current_language} = $config{default_colg} = $lg;

$self =  $script_self = $config{fullurl}.'/cgi-bin/eshop.pl?lg='.$lg."&extlink=$extlink";
$id_tarif = 0;
$id_member = 0;
$periode_solde = '';

my %setup = %{get_setup()};


%cache_eshop_tvas_tva_value = ();
my @eshop_tvas = sql_lines({select=>"tva_value,id",table=>"eshop_tvas",ordby=>"",debug=>0});
foreach $eshop_tva (@eshop_tvas)
{
	my %eshop_tva = %{$eshop_tva};
	$cache_eshop_tvas_tva_value{$eshop_tva{id}} = $eshop_tva{tva_value};
}


################################################################################
# get_eshop_cart_box
################################################################################
sub get_eshop_cart_box
{ 
  return def_handmade::eshop_handmade_cart_box();
}

################################################################################
# get_eshop_member_box
################################################################################
sub get_eshop_member_box
{
  return def_handmade::eshop_handmade_member_box();
}



sub eshop_get_id_tarif_member
{
		my %member = %{members::members_get()};

		my $id_tarif = $member{id_tarif};
		if(!$id_tarif > 0)
		{
			 my %data_setup = read_table($dbh,"data_setup",1);
			 $id_tarif = $data_setup{id_default_tarif};
		}
		return $id_tarif;
}

################################################################################
# get_product_prices
################################################################################ 
sub get_product_prices
{
		my %d = %{$_[0]};
		# $d{debug} = 0;

		if($d{debug})
		{
			# see(\%d);
		}
		
		if($periode_solde eq '')
		{
			my %setup = sql_line({table=>"eshop_setup"});
			# see(\%setup);
			$periode_solde = 0;
			
			my $date_debut_soldes_sql = $setup{soldes_debut1};
			my $date_fin_soldes_sql = $setup{soldes_fin1};
			my $date_debut_soldes_sql2 = $setup{soldes_debut2};
			my $date_fin_soldes_sql2 = $setup{soldes_fin2};
			
			my %test_soldes = sql_line({debug=>0,debug_results=>0,table=>'users',select=>"(CAST(NOW() AS DATE) BETWEEN CAST('$date_debut_soldes_sql' AS DATE) AND CAST('$date_fin_soldes_sql' AS DATE)) as soldes_hiver,(CAST(NOW() AS DATE) BETWEEN CAST('$date_debut_soldes_sql2' AS DATE) AND CAST('$date_fin_soldes_sql2' AS DATE)) as soldes_ete  "});
			
			if($test_soldes{soldes_hiver} == 1 || $test_soldes{soldes_ete} == 1)
			{
				$periode_solde = 1;
			}
		}

		my $st_pu_htva_discount = 0;
		my $st_pu_tva_discount = 0;
		my $st_pu_tvac_discount = 0;

		my $st_pu_htva_discounted = 0;
		my $st_pu_tva_discounted = 0;
		my $st_pu_tvac_discounted = 0;

		if(!($id_tarif > 0))
		{
			$id_tarif = eshop_get_id_tarif_member();
		}
		
		my %prices = 
		(
			price_htva => $d{data_stock_tarif}{st_pu_htva},
			price_tva => $d{data_stock_tarif}{st_pu_tva},
			price_tvac => $d{data_stock_tarif}{st_pu_tvac},
		);

		my %remise = ();
		
	#	chercher une remise si on n'utilise pas les prix pré-calculés ou si le taux = 0
		if($config{data_use_computed_discount} ne 'y' || $d{data_stock_tarif}{taux} == 0)
		{
			#on cherche la remise applicable
			%remise = %{get_product_prices_get_remise({from=>$d{from},id_tarif=>$id_tarif,order=>$d{order},data_sheet=>$d{data_sheet},qty=>$d{qty}})};
		}
		elsif($d{data_stock_tarif}{taux} > 0 && $periode_solde == 1)
		{
			#période soldes
			%remise =
			(
				discount_perc => $d{data_stock_tarif}{taux},
				reduit => 1,
			);
		}
		elsif($d{data_stock_tarif}{taux} > 0 && $periode_solde != 1)
		{
			%prices = 
			(
				price_htva => $d{data_stock_tarif}{st_pu_htva_discounted},
				price_tva => $d{data_stock_tarif}{st_pu_tva_discounted},
				price_tvac => $d{data_stock_tarif}{st_pu_tvac_discounted},
				'prixronds' => 'y',
				reduit => 1,
			);
		}
				
		#on applique la remise
		%prices = %{get_product_prices_apply_discount({debug=>$d{debug},prices=>\%prices,discount=>\%remise,data_sheet=>$d{data_sheet}})};

		foreach my $cle (keys %prices)
		{
			if($cle ne 'discounted' && $cle ne 'price_discount_taux')
			{
				$prices{$cle} = display_price5($prices{$cle});		
			}
		}
		
		return \%prices;
}

sub get_product_prices_get_remise
{
	my %d = %{$_[0]};
	my $debug = $d{debug};

#	log_debug('get_product_prices_get_remise','','get_product_prices_get_remise');
	
	#defini la colonne référence par défaut
	if($config{target_sheets_from_col} eq '')
	{
		$config{target_sheets_from_col} = 'f1';
	}

	#condition interdisant une remise: ex: si le produit est deja un prix rond
	if($config{eshop_exclusion_remise_col} ne '' && $config{eshop_exclusion_remise_value} ne '')
	{
		if($d{data_sheet}{$config{eshop_exclusion_remise_col}} eq $config{eshop_exclusion_remise_value})
		{
			return '';
		}
	}
	
	#conditions fixes pour la remise: visible,dates, et pas de coupon hors panier********************************************************************
	my $conditions_fixes = "visible='y'";														#est visible
	$conditions_fixes .= " AND discount_type='produit' ";										#cible produit
	$conditions_fixes .= " AND id_tarif='$d{id_tarif}' ";										#pour le bon tarif
	$conditions_fixes .= " AND (begin_date = '0000-00-00' OR CURRENT_DATE >= begin_date)";		#n'a pas de règle de debut ou en a une et la date actuelle est apres le debut 
	$conditions_fixes .= " AND (end_date = '0000-00-00' OR CURRENT_DATE <= end_date)";			#n'a pas de règle de fin ou en a une et la date actuelle est avant la fin 
	if($d{from} ne 'eshop')
	{
		$conditions_fixes .= " AND target_coupons = '' ";
	}
	
	
	#on recherche une remise la plus précise possible: produit, catégorie, référence ou tout. Chaque fois avec ou sans coupon.***************************************
	
	#1. produit
	
	#1.1 produit avec coupon
	%eshop_discount = %{check_discount({nom=>'PRODUIT',qty=>$d{qty},coupon_txt=>$d{order}{coupon_txt},conditions_fixes=>$conditions_fixes,where_supp=>" AND target_sheets='$d{data_sheet}{id}'"})};
	if($eshop_discount{id} > 0) { return \%eshop_discount; }
	
	#2. catégorie
	my @categories =  split(/,/,$d{data_sheet}{id_data_categories});
	my @where_cats = ();
	foreach my $id_cat (@categories)
	{
		if($id_cat > 0)
		{
			push @where_cats, " target_categories LIKE '%,$id_cat,%' ";
		}
		my $where_categories = join(" OR ",@where_cats);
		if($where_categories ne '')
		{
			%eshop_discount = %{check_discount({nom=>'CATEGORIES',qty=>$d{qty},coupon_txt=>$d{order}{coupon_txt},conditions_fixes=>$conditions_fixes,where_supp=>" AND ($where_categories) "})};
			if($eshop_discount{id} > 0) { return \%eshop_discount; }
		}
	}
	#3.référence
	
	
	
	
	
	#4.tout
	%eshop_discount = %{check_discount({nom=>'TOUT',qty=>$d{qty},coupon_txt=>$d{order}{coupon_txt},conditions_fixes=>$conditions_fixes,where_supp=>" AND target_all='y'"})};
	if($eshop_discount{id} > 0) { return \%eshop_discount; }

#	 log_debug('AUCUNE REMISE','','get_product_prices_get_remise');
}

sub check_discount
{
	my %d = %{$_[0]};
	
	if($d{qty} eq '')
	{
		$d{qty} = 0;
	}

	my $debug = 1;
	
	#qté recue suffisante ou pas de critère qté
	my $where_qty = "AND ( ($d{qty} >= target_qty AND target_qty > 0) OR target_qty = 0)";

	#avec coupon et test qté
	my $where_coupon = " AND (target_coupons LIKE '%,$d{coupon_txt},%' OR target_coupons = '$d{coupon_txt}' ) $where_qty";
	
	#sans coupon et test qté
	my $where_coupon_inverse = " AND target_coupons = '' $where_qty";

	# On vérifie en partant des remises/coupons les plus importants, le but étant d'appliquer la remise la plus élevée possible 
	my $ordby_valeur = "discount_eur DESC, discount_perc DESC";
	
	#avec coupon
	if($d{coupon_txt} ne '')
	{
		my $where = "$d{conditions_fixes} $where_coupon  $d{where_supp}";
#		log_debug($d{nom}.': AVEC COUPON: '.$where,'','get_product_prices_get_remise');
		my %eshop_discount = sql_line({debug=>$debug,debug_results=>$debug,table=>'eshop_discounts',where=>$where, ordby =>"discount_eur DESC, discount_perc DESC"});
		if($eshop_discount{id} > 0)
		{
			return \%eshop_discount;
		}
	}
	else
	{
#		log_debug('PAS DE COUPON','','get_product_prices_get_remise');
	}

	#sans coupon
	my $where = "$d{conditions_fixes} $where_coupon_inverse $d{where_supp}";
	# log_debug($d{nom}.': SANS COUPON: '.$where,'','get_product_prices_get_remise');
	my %eshop_discount = sql_line({debug=>$debug,debug_results=>$debug,table=>'eshop_discounts',where=>$where, ordby =>"discount_eur DESC, discount_perc DESC"});
	if($eshop_discount{id} > 0)
	{
		# log_debug($eshop_discount{id},'','get_product_prices_get_remise');
		return \%eshop_discount;
	}
	
	
	#sans coupon et sans qté
	
	
	
	
	
	#a supprimer:
	#avec qté
	# if($d{qty} > 0)
	# {
		# my $where = "$d{conditions_fixes}  AND $d{qty} >= target_qty AND target_qty > 0 $d{where_supp}";
		# my %eshop_discount = sql_line({debug=>$debug,debug_results=>$debug,table=>'eshop_discounts',where=>$where});
		# if($eshop_discount{id} > 0)
		# {
			# return \%eshop_discount;
		# }
	# }
	# else
	# {
		# log_debug('PAS DE QTE','','get_product_prices_get_remise');
	# }
}



sub get_product_prices_apply_discount
{
	my %d = %{$_[0]};
	# $d{debug} = 1;
	if($d{debug})
	{
		# see(\%d);
	}

	my %prices = %{$d{prices}};
	my %discount = %{$d{discount}};
	
	if($discount{discount_eur} > 0)
	{
		$prices{price_discount_tvac} = $discount{discount_eur};
		$prices{price_discount_taux} = $discount{discount_eur} ." €";
	}
	elsif($discount{discount_perc} > 0)
	{
		$prices{price_discount_tvac} = $prices{price_tvac} * ($discount{discount_perc} /100);
		$prices{price_discount_taux} = int($discount{discount_perc}) ." %";
	}
	
	if($prices{price_tvac} < $prices{price_discount_tvac})
	{
		$prices{price_discount_tvac} = $prices{price_tvac};
	}
	
	#taux tva (ex: 1.21)
	my $taux_tva = $cache_eshop_tvas_tva_value{$d{data_sheet}{taux_tva}} + 1;
	
	$prices{price_discount_htva} = $prices{price_discount_tvac} / $taux_tva;
	$prices{price_discount_htva} = display_price4($prices{price_discount_htva});
	# log_debug("$prices{price_discount_htva} = $prices{price_discount_tvac} / $taux_tva;","","debugarrondi");
	
	$prices{price_discount_tva} = $prices{price_discount_tvac} - $prices{price_discount_htva};
	
	#calcule le prix réduit
	
	$prices{price_discounted_htva} = $prices{price_htva} - $prices{price_discount_htva};
	$prices{price_discounted_tva} = $prices{price_tva} - $prices{price_discount_tva};
	$prices{price_discounted_tvac} = $prices{price_tvac} - $prices{price_discount_tvac};
	
	if($prices{price_tvac} > 0)
	{
		$prices{discount_taux} = sprintf("%.0f",(100 - (100 * ($prices{price_discounted_tvac} / $prices{price_tvac}))));
	}
	
	if($prices{price_discounted_tvac} == $prices{price_tvac})
	{
		$prices{price_discount_htva} = 0;
		$prices{price_discount_tva} = 0;
		$prices{price_discount_tvac} = 0;
	}
	
	if($prices{price_discount_tvac} > 0)
	{
		$prices{discounted} = 'y';
		$prices{reduit} = 1;
	}
	else
	{
		$prices{discounted} = 'n';
	}
	
	if($d{debug})
	{
		# see(\%prices);
	}
	
	return \%prices;
}

################################################################################
# get_default_payment_method_name
################################################################################
sub get_default_payment_method_name
{
    my %d = %{$_[0]};
    # On récupère le tarif du membre
    my $id_tarif = $d{id_tarif} || eshop_get_id_tarif_member();
    
    my %tarif = sql_line({dbh=>$dbh, table=>"eshop_tarifs", where=>"id = '$id_tarif'"});

    my %payment = sql_line({dbh=>$dbh, table=>"eshop_payments", where=>"id = '$tarif{id_payment_default}'"});

    return $payment{name};
}

################################################################################
# get_setup
################################################################################
sub get_setup
{
    my %setup = sql_line({table=>"eshop_setup"});
    if($setup{id} > 0)
    {
        return \%setup;
    }
}

################################################################################
# eshop_signup_member
# 
# Actions supplémentaires propre à la boutique lors de la création d'un membre
################################################################################
sub eshop_signup_member
{
  my %d = %{$_[0]};

  my %member = %{$d{member}};

  if(!($member{id} > 0))
  {
    exit;
  }

  ###############################
  ### Création des identities ###
  ###############################
  my @champs_identity = @{get_identities_fields()};

  my %identity = ();
  foreach my $champ_identity (@champs_identity)
  {
    %champ_identity = %{$champ_identity};  

    $identity{$champ_identity{name}} = get_quoted($champ_identity{name})  || get_quoted("delivery_".$champ_identity{name}) || get_quoted("billing_".$champ_identity{name} || $member{$champ_identity{name}});
  }

  delete $identity{password};
  delete $identity{email2};
  delete $identity{password2};

  $identity{id_member} = $member{id};

  # Livraison
  $identity{identity_type} = "delivery"; 
  $identity{token} = create_token(50);
  sql_set_data({debug=>0, dbh=>$dbh, table=>"identities",data=>\%identity,where=>"id_member=' $identity{id_member}' AND identity_type = '$identity{identity_type}'"});

  # Facturation
  $identity{identity_type} = "billing";
  $identity{token} = create_token(50); 
  sql_set_data({debug=>0, dbh=>$dbh, table=>"identities",data=>\%identity,where=>"id_member=' $identity{id_member}' AND identity_type = '$identity{identity_type}'"});

  #################
  ### Revendeur ###
  #################
  if($d{type} eq "revendeur")
  {
    # On désactive le membre et on lui attribue le tarif 2
    my $stmt = <<"SQL";
      UPDATE migcms_members
        SET actif = 'n',
            id_tarif = 2
        WHERE id = '$member{id}'
SQL
    execstmt($dbh, $stmt);


    # On envoi un mail pour prévenir qu'un nouveau revendeur est à valider
    my $email_content =<<"EOH";
    Bonjour,
    <br /><br />
    Une nouveau professionnel s'est inscrit sur votre site. Vous pouvez le valider dans le backoffice de votre boutique. (Revendeurs en attente)
    <br /><br />
    Informations professionnel:<br />
    <br />$identity{company} $identity{vat}
    <br />$identity{firstname} $identity{lastname}
    <br />$identity{street} $identity{number} $identity{box}
    <br />$identity{city} $identity{zip}
    <br />$identity{phone} 
    <br />$identity{email}
EOH
    send_mail($setup{email_from},$setup{email_from},"Nouveau professionnel à valider",$email_content,"html");
    # Envoies des copies du mails
    if($setup{eshop_email_copies} ne "")
    {
        send_mail($setup{eshop_email},$setup{eshop_email_copies},"Nouveau professionnel à valider",$email_content,"html");        
    }
    send_mail($setup{email_from},'dev@bugiweb.com',"COPIE BUGIWEB: Nouveau professionnel à valider",$email_content,"html");


    # On envoi un mail au revendeur pour le prévenir que son compte doit être validé
    my $email_object_member = "$sitetxt{email_object_revendeur} $setup{eshop_name}";
    my $email_content_member = <<"EOH";
    $sitetxt{email_content_revendeur}
    <a href="$setup{eshop_web}">$setup{eshop_web}</a>
    $sitetxt{email_signature} $setup{eshop_name}
EOH
    
    send_mail($setup{email_from},$member{email},$email_object_member,$email_content_member,"html");
    send_mail($setup{email_from},'dev@bugiweb.com',"COPIE BUGIWEB: $email_object_member",$email_content_member,"html");

  }
}


################################################################################
# get_identities_fields
################################################################################
sub get_identities_fields
{
  my %d = %{$_[0]};

  my %valeurs = %{$d{valeurs}};

  my @champs;
  if($config{custom_identities_fields} eq "y")
  {
    @champs = @{def_handmade::get_custom_identities_fields()}; 
  }
  else
  {
    @champs = 
    (
      {
        name => 'firstname',
        label => $sitetxt{eshop_firstname},
        required => 'required',
        display => $display_fields_simplify,
        valeurs => \%valeurs,
      }
      ,
      {
        name => 'lastname',
        label => $sitetxt{eshop_lastname},
        required => 'required',
        valeurs => \%valeurs,
      }
      ,
      {
        name => 'company',
        label => $sitetxt{eshop_company},
        valeurs => \%valeurs,
      }
      ,
      {
        name => 'vat',
        label => $sitetxt{eshop_vat},
        hint => "($sitetxt{eshop_exemple}: BE123456789)",
        suppl => $suppl_erreur_intracom_delivery,
        valeurs => \%valeurs,
      }
      ,
      {
        name => 'street',
        label => $sitetxt{eshop_street},
        required => 'required',
        class =>  'google_map_route',
        valeurs => \%valeurs,
      }
      ,
      {
        name => 'number',
        label => $sitetxt{eshop_number},
        class => 'input-small',
        class =>  'google_map_street_number',
        display => $display_fields_simplify,
        valeurs => \%valeurs,
      }
      ,
      {
        name => 'box',
        label => $sitetxt{eshop_box},
        class => 'input-small',
        display => $display_fields_simplify,
        valeurs => \%valeurs,
      }
      ,
      {
        name => 'zip',
        label => $sitetxt{eshop_zip},
        class => 'input-small',
        required => 'required',
        class =>  'google_map_postal_code',
        valeurs => \%valeurs,
      }
      ,
      {
        name => 'city',
        label => $sitetxt{eshop_city},
        class => 'input-small',
        required => 'required',
        class =>  'google_map_locality',
        valeurs => \%valeurs,
      }
      ,
      {
        name => 'country',
        type => 'countries_list',
        label => $sitetxt{eshop_country},
        class => 'select_country',
        required => 'required',
        class =>  'google_map_country',
        valeurs => \%valeurs,
      }
      ,
      {
        name => 'phone',
        label => $sitetxt{eshop_tel},
        required => 'required',
        valeurs => \%valeurs,
      }
      ,
      {
        name => 'email',
        type => 'email',
        label => $sitetxt{eshop_email},
        required => 'required',
        valeurs => \%valeurs,
      },
    );
  }

  return \@champs;
}

################################################################################
#recompute_order
################################################################################
sub recompute_order
{
	my %order = %{get_eshop_order()};
	my %setup = %{get_setup()};

	my @fields = qw(
		htva
		tva
		tvac
		discount_htva
		discount_tva
		discount_tvac
		discounted_htva
		discounted_tva
		discounted_tvac	
	);
	
	my @fields_totaux_arrondis = qw(
		detail_pu
		detail_pu_discount
		detail_pu_discounted
		detail_total
		detail_total_discount
		detail_total_discounted
	);
	# log_debug('','vide','get_product_prices_get_remise');
	
	my $id_tarif = eshop::eshop_get_id_tarif_member();
	
	
	my $stmt = <<"EOH";
	UPDATE eshop_order_details SET detail_qty = '1'  WHERE detail_qty < 1
EOH
	execstmt($dbh,$stmt);



	#totaux order details:
	my @order_details = sql_lines({debug=>0,table=>"eshop_order_details",where=>"id_eshop_order='$order{id}'"});
    foreach $order_detail (@order_details)
    {
        my %order_detail = %{$order_detail};
		my %data_sheet = read_table($dbh,'data_sheets',$order_detail{id_data_sheet});
		my %data_stock = read_table($dbh,'data_stock',$order_detail{id_data_stock});
		my %data_stock_tarif = sql_line({table=>'data_stock_tarif',where=>"id_data_stock = '$data_stock{id}' AND id_tarif = '$id_tarif'"});		
		
		%sheet_prices = %{eshop::get_product_prices({from=>'eshop',debug=>1,generation=>'n',order=>\%order,data_sheet=>\%data_sheet,data_stock_tarif=>\%data_stock_tarif, qty=>$order_detail{detail_qty}})};
		
		#verifications sur le stock
		my $avert_stock = 'n';
		if($setup{check_stock} eq 'y' && $order_detail{detail_qty} > $data_stock{stock})
		{
			my $detail_qty = $data_stock{stock};
			$avert_stock = 'y';
			
			#maj qté et avertissement
			my $stmt = <<"EOH";
			UPDATE eshop_order_details SET detail_qty = '$detail_qty', avert_stock = '$avert_stock' WHERE id = '$order_detail{id}'
EOH
			execstmt($dbh,$stmt);
		}
		
		# MISE A JOUR DES DETAILS
		foreach my $field (@fields)
		{	
			# Sous-totaux
			my $price = $sheet_prices{'price_'.$field};
			$price = display_price5($price);
			my $stmt = <<"EOH";
				UPDATE eshop_order_details SET detail_total_$field = ($price * detail_qty) WHERE id = '$order_detail{id}'
EOH
			execstmt($dbh,$stmt);

			# PU
			my $price = $sheet_prices{'price_'.$field};
			$price = display_price5($price);
			
			
			
			my $stmt = <<"EOH";
				UPDATE eshop_order_details SET detail_pu_$field = $price WHERE id = '$order_detail{id}'
EOH
			execstmt($dbh,$stmt);
			
			# Poids
			my $weight = $data_stock{'weight'};
			if($weight eq '')
			{
				$weight = 0;
			}
			my $stmt = <<"EOH";
				UPDATE eshop_order_details SET detail_weight = ($weight * detail_qty) WHERE id = '$order_detail{id}'
EOH
			execstmt($dbh,$stmt);
		}
		
		
		# MISE A JOUR DES DETAILS
		foreach my $field (@fields_totaux_arrondis)
		{	
			my $stmt =  'UPDATE eshop_order_details SET '.$field.'_tvac = '.$field.'_htva + '.$field.'_tva WHERE id = '."'$order_detail{id}'";
			execstmt($dbh,$stmt);
		}
	}
	
	#totaux order: 
	
	#sous totaux à partir d'order_details
	my %update_order = ();
	
	foreach my $field (@fields)
	{
		my $stmt = <<"EOH";
			UPDATE eshop_orders SET total_$field = (select SUM(detail_total_$field) FROM eshop_order_details WHERE id_eshop_order = '$order{id}') WHERE id = '$order{id}'
EOH
		execstmt($dbh,$stmt);
	}
	
	#calcul des frais de port
	
	#poids et qté
	my $stmt = <<"EOH";
			UPDATE eshop_orders SET total_qty = (select SUM(detail_qty) FROM eshop_order_details WHERE id_eshop_order = '$order{id}'), total_weight = (select SUM(detail_weight) FROM eshop_order_details WHERE id_eshop_order = '$order{id}') WHERE id = '$order{id}'
EOH
	execstmt($dbh,$stmt);
	
  my $total_delivery_tvac = get_delivery_price({debug=>$d{debug},recompute_bpost=>$d{recompute_bpost}});
  if($total_delivery_tvac < 0 || $total_delivery_tvac eq '')
  {
      $total_delivery_tvac = 0;
  }
  my $total_delivery_tva =  $total_delivery_tvac / (100+0.21*100) * (0.21*100);
  my $total_delivery_htva = $total_delivery_tvac - $total_delivery_tva;


  
  
	#calcul de la remise panier avec coupon
	my $total_coupons_htva = 0;
	my $total_coupons_tva = 0;
	my $total_coupons_tvac = 0;
	
	my $where_remise_panier = "visible='y'";														#est visible
	$where_remise_panier .= " AND discount_type='panier' ";											#cible produit
	$where_remise_panier .= " AND (begin_date = '0000-00-00' OR CURRENT_DATE >= begin_date)";		#n'a pas de règle de debut ou en a une et la date actuelle est apres le debut 
	$where_remise_panier .= " AND (end_date = '0000-00-00' OR CURRENT_DATE <= end_date)";			#n'a pas de règle de fin ou en a une et la date actuelle est avant la fin 
	$where_remise_panier .= " AND target_coupons LIKE '%,$order{coupon_txt},%' ";					#avec un coupon
	my %eshop_discount_panier = sql_line({table=>'eshop_discounts',where=>$where_remise_panier});
	# my %eshop_tva = sql_line({debug=>1,table=>'eshop_tvas',where=>"id='21'"});
	my $taux_tva = $cache_eshop_tvas_tva_value{21};

	
	if($eshop_discount_panier{id} > 0 && $eshop_discount_panier{discount_eur} > 0)
	{
		if($eshop_discount_panier{discount_eur} > $order{total_tvac})
		{
			$eshop_discount_panier{discount_eur} = $order{total_tvac};
		}
		$total_coupons_tvac = $eshop_discount_panier{discount_eur};
		$total_coupons_htva = $eshop_discount_panier{discount_eur} / (1+$taux_tva);
		$total_coupons_tva = $total_coupons_htva - $total_coupons_htva;		
	}
	elsif($eshop_discount_panier{id} > 0 && $eshop_discount_panier{discount_perc} > 0)
	{
		my $valeur_remise = $order{total_tvac} * ($eshop_discount_panier{discount_perc} / 100);
		if($valeur_remise > $order{total_tvac})
		{
			$valeur_remise = $order{total_tvac};
		}
		$total_coupons_tvac = $valeur_remise;
		$total_coupons_htva = $valeur_remise / (1+$taux_tva);
		$total_coupons_tva = $total_coupons_tvac - $total_coupons_htva;		
	}
	
	$total_coupons_tvac = display_price5($total_coupons_tvac);
	$total_coupons_htva = display_price5($total_coupons_htva);
	$total_coupons_tva = display_price5($total_coupons_tva);

	#+ frais de port, taxes - coupons,remises	
	my $stmt = <<"EOH";
      UPDATE eshop_orders
      SET
         total_delivery_htva = '$total_delivery_htva',
         total_delivery_tva = '$total_delivery_tva',
         total_delivery_tvac = '$total_delivery_tvac',	
		 total_coupons_tvac = '$total_coupons_tvac',
         total_coupons_tva = '$total_coupons_tva',
         total_coupons_htva = '$total_coupons_htva',	
		 coupon_id_eshop_discount = '$eshop_discount_panier{id}'
      WHERE
          id = $order{id}
EOH
    execstmt($dbh,$stmt);
	
	
	  # CALCUL DES MONTANTS TOTAUX (!! ARRONDIS A 2 DECIMALES !!)
  my %order = %{get_eshop_order()};
  my $total_discounted_htva = $order{total_htva} + $total_delivery_htva - $order{total_discount_htva} - $total_coupons_htva + $order{total_taxes};
  my $total_discounted_tva =  $order{total_tva} + $total_delivery_tva - $order{total_discount_tva} - $total_coupons_tva;
  my $total_discounted_tvac = $total_discounted_htva + $total_discounted_tva;
	if($total_discounted_htva < 0)
	{
		$total_discounted_htva = 0;
	}
	if($total_discounted_tva < 0)
	{
		$total_discounted_tva = 0;
	}
	if($total_discounted_tvac < 0)
	{
		$total_discounted_tvac = 0;
	}
	
	my $stmt = <<"EOH";
      UPDATE eshop_orders
      SET
		 total_discounted_htva = $total_discounted_htva,
         total_discounted_tva = $total_discounted_tva,
         total_discounted_tvac = $total_discounted_tvac
      WHERE
          id = $order{id}
EOH
    execstmt($dbh,$stmt);
}

################################################################################
#create_eshop_order
################################################################################
sub create_eshop_order
{
		my %setup = %{get_setup()};
		
		#read cookie ORDER
		my %hash_order = ();
		my $cookie_order = $cgi->cookie($config{front_cookie_name});
		if($cookie_order ne "")
		{
				$cookie_order_ref=decode_json $cookie_order;
				%hash_order=%{$cookie_order_ref};
		}

		if($hash_order{eshop_token} ne '')
		{
				my %eshop_order = sql_line({debug=>0,debug_results=>0,table=>"eshop_orders",where=>"token='$hash_order{eshop_token}' and status = 'begin' "});
				if($eshop_order{id} > 0)
				{
						#rien, on a déjà une commande
						see();
						return "";
				}
		}
				
		#créer une commande vide et écrit le cookie
		my %order = ();
		$order{token}                    = create_token(50);
		$order{token2}                   = create_token(50);
		$order{delivery}                 = $setup{default_delivery};
		$order{payment}                  = get_default_payment_method_name();
		$order{order_begin_moment}       = 'NOW()';
		$order{delivery_same_identities} = 'y';  #attention au cas login avec identity précédents et addresse écrasée avec recopie form	
		$order{status}                   = 'begin';
		$order{cart_date}                = 'NOW()';
		$order{migcms_moment_create}     = 'NOW()';
		$order{id_tarif}                 = eshop_get_id_tarif_member();
		my $new_id_eshop_order = inserth_db($dbh,"eshop_orders",\%order);
		
		members::member_add_event({group=>'eshop',type=>"create_eshop_order",name=>"Création de la commande $new_id_eshop_order",detail=>$new_id_eshop_order,erreur=>''});
		
		#write cookie order
		my %hash_order = ();
		my $cookie_order = $cgi->cookie($config{front_cookie_name});
		if($cookie_order ne "")
		{
					$cookie_order_ref=decode_json $cookie_order;
					%hash_order=%{$cookie_order_ref};
		}

		$hash_order{eshop_token} = $order{token};
		$cookie_value = encode_json \%hash_order;
		my $cook = $cgi->cookie(-name=>$config{front_cookie_name},-value=>$cookie_value,-path=>$config{rewrite_directory});
		print $cgi->header(-cookie=>$cook,-expires=>'-1d',-charset => 'utf-8');
		
		return $new_id_eshop_order;
}


################################################################################
#get_eshop_order
################################################################################
sub get_eshop_order
{
		log_debug('get_eshop_order','','get_eshop_order');

		my %d = %{$_[0]};

		my $alt_id_eshop_order = $d{id};
		my $token = $d{token};

	log_debug('1','','get_eshop_order');

		#read cookie ORDER
		my %order = ();
		my $cookie_order = $cgi->cookie($config{front_cookie_name});
		if($cookie_order ne "")
		{
				$cookie_order_ref=decode_json $cookie_order;
				%hash_order=%{$cookie_order_ref};
		}
	log_debug('2','','get_eshop_order');
		if($alt_id_eshop_order > 0)
		{
				my %eshop_order = sql_line({debug=>0,debug_results=>0,table=>"eshop_orders",where=>"id='$alt_id_eshop_order' and (status = 'begin' OR status = 'unfinished') "});
			log_debug('3','','get_eshop_order');
			if($eshop_order{id} > 0)
				{
						return \%eshop_order;
				}	
		}
		elsif($token ne "")
		{
			my %eshop_order = sql_line({debug=>0,debug_results=>0,table=>"eshop_orders",where=>"token='$token' and (status = 'begin' OR status = 'unfinished') "});
			log_debug('4','','get_eshop_order');
			if($eshop_order{id} > 0)
			{
					return \%eshop_order;
			}	
		}
		elsif($hash_order{eshop_token} ne '')
		{
				my %eshop_order = sql_line({debug=>0,debug_results=>0,table=>"eshop_orders",where=>"token='$hash_order{eshop_token}' and (status = 'begin' OR status = 'unfinished') "});
			log_debug('5','','get_eshop_order');
			if($eshop_order{id} > 0)
				{
						return \%eshop_order;
				}	
		}
}

################################################################################
# get_delivery_price
################################################################################
sub get_delivery_price
{
    my %d = %{$_[0]};
    my %del = %{$d{del}};
	my %order = %{get_eshop_order()};
	
    # members::member_add_event({group=>'eshop',type=>"delivery",name=>"get_delivery_price",detail=> $order{id}});		
    # members::member_add_event({group=>'eshop',type=>"delivery",name=>"méthode: $del{name}",detail=> $order{id}});		
    # members::member_add_event({group=>'eshop',type=>"delivery",name=>"use_cost: $del{use_cost}",detail=> $order{id}});		
	
	if($del{name} eq '')
	{
	    # members::member_add_event({group=>'eshop',type=>"delivery",name=>"Rechargement methode: $order{delivery}",detail=> $order{id}});		
		%del = sql_line({
			debug         => 0,
			debug_results => 0,
			table         => "eshop_deliveries",
			where         => "name='$order{delivery}'",
		});
		
		# members::member_add_event({group=>'eshop',type=>"delivery",name=>"get_delivery_price",detail=> $order{id}});		
		# members::member_add_event({group=>'eshop',type=>"delivery",name=>"méthode: $del{name}",detail=> $order{id}});		
		# members::member_add_event({group=>'eshop',type=>"delivery",name=>"use_cost: $del{use_cost}",detail=> $order{id}});		
	}
	
	if(($order{total_discounted_htva} - $order{total_delivery_htva}) > $config{free_after_htva} && $config{free_after_htva} > 0)
	{
	    # members::member_add_event({group=>'eshop',type=>"delivery",name=>"Frais de ports HTVA gratuits ($order{total_discounted_htva} - $order{total_delivery_htva} > $config{free_after_htva})",detail=> $order{id}});
		return 0;
	}
	elsif(($order{total_discounted_tvac} - $order{total_delivery_tvac}) > $config{free_after_tvac} && $config{free_after_tvac} > 0)
	{
		# members::member_add_event({group=>'eshop',type=>"delivery",name=>"Frais de ports TVAC gratuits ($order{total_discounted_tvac} - $order{total_delivery_tvac} > $config{free_after_tvac})",detail=> $order{id}});		
		return 0;
	}
		
    if($del{name} eq '')
    {
        %del = sql_line({table=>"eshop_deliveries",where=>"name='$order{delivery}'"}); 
    }
    if($del{use_cost} eq 'y')
    {
        # members::member_add_event({group=>'eshop',type=>"delivery",name=>"Frais de ports avec un coût fixe de $del{cost} ",detail=> $order{id}});		
		return $del{cost};
    }
    elsif(trim($del{name}) eq 'kilopost')
    {
   	    return kilopost({debug=>$d{debug}});
    }
    # elsif($del{name} eq "paiement_magasin")
    elsif($del{name} eq "livraison_magasin")
    {
    	 # members::member_add_event({group=>'eshop',type=>"delivery",name=>"Frais de ports gratuits car paiement au magasin",detail=> $order{id}});		
		 return 0;
    }
    elsif($del{name} eq 'bpost')
    {
      if(!$order{id}>0)
      {
			%order = %{get_eshop_order()};
      }

      # Si les frais de Bpost ont été calculés via le shipping manager, on renvoit directement le prix
      if($order{bpost_total_delivery_computed} eq "y" && $order{delivery} eq 'bpost')
      {
      	return $order{total_delivery_tvac};
      }

        my %bpost_cfg = eval("%bpost_cfg = ($del{params});");
         
        if(($order{total_discounted_tvac} - $order{total_delivery_tvac}) >= $bpost_cfg{free_after} && $bpost_cfg{free_after} > 0 )
        {
           return 0; 
        }
        else
        {
		   if($bpost_cfg{'free_after_'.$order{delivery_country}} > 0 && ($order{total_discounted_tvac} - $order{total_delivery_tvac}) >= $bpost_cfg{'free_after_'.$order{delivery_country}})
		   {
				return 0;
		   }
		   elsif($bpost_cfg{'bpost_price_'.$order{delivery_country}} > 0)
		   {
				return $bpost_cfg{'bpost_price_'.$order{delivery_country}};
		   }
		   else
		   {
			   my @world_costs = split(/,/,$bpost_cfg{world_costs});
			   if($order{total_weight} >= 0  && $order{total_weight} <= 2)
			   {
				  return $world_costs[0];
			   }
			   elsif($order{total_weight} > 2 && $order{total_weight} <= 5)
			   {
				  return $world_costs[1];
			   }
			   elsif($order{total_weight} > 5 && $order{total_weight} <= 10)
			   {
				  return $world_costs[2];
			   }
			   elsif($order{total_weight} > 10 && $order{total_weight} <= 20)
			   {
				  return $world_costs[3];
			   }
			   elsif($order{total_weight} > 20 && $order{total_weight} <= 30)
			   {
				  return $world_costs[4];
			   }
		   }
        }
    }
    elsif($del{name} eq 'handmade_delivery')
    {
    	return def_handmade::handmade_delivery_costs();
    }
    return -1;
}

sub kilopost
{
    my %setup = %{get_setup()};
   	# members::member_add_event({group=>'eshop',type=>"delivery",name=>" Début de kilopost...",detail=> $order{id}});
	my $log_kilopost = "Livraison à domicile: ";
	
	my %d = %{$_[0]};
	my %order = %{get_eshop_order()};
	if($order{total_weight} eq '')
	{
		$order{total_weight} = 0;
	}
    if($order{delivery_country} eq '')
    {
       $order{delivery_country} = $setup{cart_default_id_country};
    }
    
	my %country = sql_line({debug=>0,table=>"countries",where=>"id='$order{delivery_country}'"});
	$log_kilopost .= " Pays: $country{iso} ($order{delivery_country})";
    my %delcost_country = sql_line({table=>"shop_delcost_countries",where=>"isocode='$country{iso}'"});
	my %zone = sql_line({table=>"shop_delcost_zones",where=>"id='$delcost_country{id_zone}'"});
	$log_kilopost .= " Zone: $zone{id} ($delcost_country{id_zone})";
	
    if($zone{free_after} > 0 &&  $zone{free_after} <= ($order{total_discounted_tvac} - $order{total_delivery_tvac}))
    {
		# members::member_add_event({group=>'eshop',type=>"delivery",name=>"Frais de ports gratuits car le prix nécessaire est atteint ($zone{free_after} <= $order{total_discounted_tvac} - $order{total_delivery_tvac})",detail=> $order{id}});				
		return 0;
    }
	else
	{
	}
	
    #TEST DU PRIX***************************************************************
    my @costs=get_table($dbh,"shop_delcost_zones_costs","","id_zone='$delcost_country{id_zone}' AND type='prix' order by de",'','','',0);    
	for($i_cost=0;$i_cost<$#costs+1;$i_cost++)
    {
        # print "TEST DU PRIX if($costs[$i_cost]{de} <= ($order{total_discounted_tvac} - $order{total_delivery_tvac}) && $costs[$i_cost]{a} >= ($order{total_discounted_tvac} - $order{total_delivery_tvac}))";
		if($costs[$i_cost]{de} <= ($order{total_discounted_tvac} - $order{total_delivery_tvac}) && $costs[$i_cost]{a} >= ($order{total_discounted_tvac} - $order{total_delivery_tvac}))
        {
			my $log = "Frais de port au prix: ".$costs[$i_cost]{price};
			$log .= ': ';
			$log .= $costs[$i_cost]{price}.' € ('."$costs[$i_cost]{de} <= ($order{total_discounted_tvac} - $order{total_delivery_tvac}) && $costs[$i_cost]{a} >= ($order{total_discounted_tvac} - $order{total_delivery_tvac} )";
			$log_kilopost .= $log;
			# members::member_add_event({group=>'eshop',type=>"delivery",name=>$log_kilopost,detail=> $order{id}});				
			return  $costs[$i_cost]{price};
        } 
    }
	
    #TEST DE LA QUANTITE********************************************************
    my @costs=get_table($dbh,"shop_delcost_zones_costs","","id_zone='$delcost_country{id_zone}' AND type='qty' order by de",'','','',0);
    for($i_cost=0;$i_cost<$#costs+1;$i_cost++)
    {
        # print "TEST DE LA QUANTITE if($costs[$i_cost]{de} <= $order{total_qty} && $costs[$i_cost]{a} >= $order{total_qty})";
		if($costs[$i_cost]{de} <= $order{total_qty} && $costs[$i_cost]{a} >= $order{total_qty})
        {
			my $log = "Frais de port au prix: ".$costs[$i_cost]{price};
			$log .= ': ';
			$log .= $costs[$i_cost]{price}.' € ('."$costs[$i_cost]{de} <= $order{total_qty} && $costs[$i_cost]{a} >= $order{total_qty} )";
			$log_kilopost .= $log;
			# members::member_add_event({group=>'eshop',type=>"delivery",name=>$log_kilopost,detail=> $order{id}});				
			return  $costs[$i_cost]{price};
        } 
    }
	
    #TEST DU POIDS**************************************************************
    my @costs=get_table($dbh,"shop_delcost_zones_costs","","id_zone='$delcost_country{id_zone}' AND type='poids' order by de",'','','',0);
    for($i_cost=0;$i_cost<$#costs+1;$i_cost++)
    {
		
		# print "TEST DU POIDS if($costs[$i_cost]{de} <= $order{total_weight} && $costs[$i_cost]{a} >= $order{total_weight})";
		if($costs[$i_cost]{de} <= $order{total_weight} && $costs[$i_cost]{a} >= $order{total_weight})
        {
			my $log = "Frais de port au prix: ".$costs[$i_cost]{price};
			$log .= ': ';
			$log .= $costs[$i_cost]{price}.' € ('."$costs[$i_cost]{de} <= $order{total_weight} && $costs[$i_cost]{a} >= $order{total_weight} )";
			$log_kilopost .= $log;
			# members::member_add_event({group=>'eshop',type=>"delivery",name=>$log_kilopost,detail=> $order{id}});				
			return  $costs[$i_cost]{price};
        } 
    }
	
	$log_kilopost .= "Pas de prix de livraison trouvé !";
	# members::member_add_event({group=>'eshop',type=>"delivery",name=>$log_kilopost,detail=> $order{id}});				
	
    return -1;
}


sub link_order_and_continue_if_logged
{
	my %order = %{get_eshop_order()};
	my %member = %{members::members_get()};
	if($member{id} > 0)
	{
		#lie les logs au membre
		$stmt = "UPDATE migcms_members_events SET id_member='$member{id}' where group_type_event = 'eshop' AND detail_evt = '$order{id}' and detail_evt > 0 AND id_member = 0";
		$cursor = $dbh->prepare($stmt);
		$cursor->execute || suicide($stmt);
		
		#if logged
		if(!($order{id_member} > 0))
		{	
			#if order not yet linked
			lnk_order_to_member({order_token=>$order{token},member_email=>$member{email}});
		}
		
		#continue
		cgi_redirect($config{fullurl}.'/'.$sitetxt{eshop_url_addresses});
		exit;
	}
}

################################################################################
# lnk_order_to_member
################################################################################
sub lnk_order_to_member
{
  my %d = %{$_[0]};

  my $order_token = get_quoted("token_order") || $d{order_token};
  my $member_email = get_quoted("billing_email") || $d{member_email};
  

  my %member = sql_line({dbh=>$dbh, table=>"migcms_members", where=>"email != '' AND email = '$member_email'"});
  my %order = sql_line({dbh=>$dbh, table=>"eshop_orders", where=>"token != '' AND token = '$order_token'"});

  #Récupération du tarif du membre
  my $id_tarif = $member{id_tarif};
  if($id_tarif eq "" || $id_tarif == 0)
  {
      $id_tarif = eshop_get_id_tarif_member();
  }

  # Récupération de la méthode de payment par défaut du membre
  my $payment = get_default_payment_method_name({id_tarif=>$id_tarif});
   
  $stmt = "UPDATE eshop_orders SET id_member=$member{id}, payment='$payment', id_tarif='$id_tarif' where id='$order{id}'";
  $cursor = $dbh->prepare($stmt);
  $cursor->execute || suicide($stmt);

  #Rempli automatiquement les données de livraison et de facturation par rapport aux profils par défaut du membre
  my %update_order = ();
  my @champs = ('firstname','lastname','company','vat','street','number','box','zip','city','country','phone','email'); #same_identites retiré car pas dans la table identities
  
  #DELIVERY***************************************************************
  my $prefixe = 'delivery_';
  my %identity = sql_line({table=>"identities",where=>"id_member = $member{id} AND identity_type='delivery'"});
  if(!($identity{id} > 0))
  {
      %identity = sql_line({table=>"identities",where=>"id_member = $member{id}",ordby=>'id desc'});
  }
  
  foreach my $champ (@champs)
  {
     $update_order{$prefixe.$champ} = $identity{$champ};
     $update_order{$prefixe.$champ} =~ s/\'/\\\'/g;
  }
  
  #BILLING****************************************************************
  my $prefixe = 'billing_';
  my %identity = sql_line({table=>"identities",where=>"id_member = $member{id} AND identity_type='billing'"});
  if(!($identity{id} > 0))
  {
      %identity = sql_line({table=>"identities",where=>"id_member = $member{id}",ordby=>'id desc'});
  }
  foreach my $champ (@champs)
  {
     $update_order{$prefixe.$champ} = $identity{$champ};
     $update_order{$prefixe.$champ} =~ s/\'/\\\'/g;
  }

  if($config{use_enseigne} eq "y")
  {
  	if($update_order{delivery_company} eq "")
  	{
  		$update_order{delivery_company} = $member{delivery_enseigne};
  	}
  	if($update_order{billing_company} eq "")
  	{
  		$update_order{billing_company} = $member{delivery_enseigne};
  	}
  }

  sql_set_data({debug=>0, dbh=>$dbh, table=>"eshop_orders",data=>\%update_order,where=>"id='$order{id}'"});
  
  #On retotalise les commandes pour tenir compte du membre
  if($order{id} > 0)
  {
		recompute_order();
  }
}

sub get_breadcrumb
{
    my $resume = '';
    
	my $step = $_[0];

		my $num = 1;
		$resume = <<"EOH";
			<ul class="breadcrumb">
EOH
		my %bread_sel_item = ();
		$bread_sel_item{$step} = 'bread_active';
		#prévoir de pouvoir désactiver chaque étape
		if(1)
		{
			$resume .= <<"EOH";
			<li><a href="#" class="$bread_sel_item{1}" style="cursor:default;" onclick="return false;"> $num. $sitetxt{'eshop_breadcrumb_step_1'}</a>
EOH
		}
		$num++;
		if(1)
		{
			$resume .= <<"EOH";
			<li><a href="#" class="$bread_sel_item{2}" style="cursor:default;" onclick="return false;"> $num. $sitetxt{'eshop_breadcrumb_step_2'}</a>
EOH
		}
		$num++;
		if(1)
		{
			$resume .= <<"EOH";
			<li><a href="#" class="$bread_sel_item{3}" style="cursor:default;" onclick="return false;"> $num. $sitetxt{'eshop_breadcrumb_step_3'}</a>
EOH
		}
		
		$resume .= <<"EOH";
			</ul>
EOH
	
	
    if($setup{cacher_breadcrumb} eq 'y')
    {
        $resume = '';
    }

    return $resume;
}



################################################################################
# edit_identity
################################################################################
sub get_edit_identity_content
{
  my %d = %{$_[0]};

  my $type= $d{type};
  my %member = %{$d{member}};

  my $title ='';
  my %identity = ();
  my $glyphicon = "";
  if($type eq 'delivery')
  {
     %identity = sql_line({debug_results=>0,table=>"identities",where=>"id_member = '$member{id}' AND identity_type='delivery'"});
     $title = $sitetxt{eshop_metatitle_delivery};
     $glyphicon = "glyphicon glyphicon-road";
  }
  elsif($type eq 'billing')
  {
     %identity = sql_line({table=>"identities",where=>"id_member = '$member{id}' AND identity_type='billing'"});
     $title = $sitetxt{eshop_metatitle_billing};
     $glyphicon = "glyphicon glyphicon-euro";
  }

  # Récupération du tableau des champs du formulaire
  my @champs = @{get_identities_fields({valeurs=>\%identity})};

  # Construction du formulaire
  my $form = build_form({fields=>\@champs, lg=>$lg});

  my $menu = members::get_menu();  
 
  my $form = <<"EOH";
    <h1 class="page_title"><span><i class="$glyphicon"></i> $title</span></h1>

    $d{msg}

    <form id="edit_identity" method="post" class="form-horizontal" action="$script_self"  enctype="multipart/form-data">
      <input type="hidden" name="sw" value = "edit_identity_db" />
      <input type="hidden" name="token" value = "$identity{token}" />
      <input type="hidden" name="id_identity" value = "$identity{id}" />
      <input type="hidden" name="type" value = "$type" />                   
      <input type="hidden" name="lg" value = "$lg" />
      <input type="hidden" name="url_after_edit" value="$d{url_after_edit}">

      $form

      <div class="form-group">
        <div class="col-sm-4"></div>
        <div class="col-sm-8">
          <button type="submit" class="btn btn-info">$sitetxt{'eshop_save'}</button>
        </div>
      </div>
    </form>


EOH
  return $form;
}


################################################################################
# get_wishlist_content
################################################################################
sub get_wishlist_content
{
	my %d = %{$_[0]};

  my %member = %{$d{member}};

  my $content = <<"HTML";
    <h1 class="page_title"><span><i class="glyphicon glyphicon-heart"></i> $sitetxt{eshop_metatitle_wishlist}</span></h1>
HTML
	
	# Récupération de la wishlist du membre
	my @wishlist = sql_lines({table=>"data_sheets_wishlist", where=>"id_member = '$member{id}' AND id_member != ''"});

	if($#wishlist == -1)
  {
     $content .= <<"HTML";
        <div class="alert alert-block alert-warning">
          <h4 class="alert-heading">$sitetxt{'eshop_erreur_aucune_wishlist'}</h4>
        </div>
HTML
  }
  else
  {
		foreach $wishlist_element (@wishlist)
		{
			my %wishlist_element = %{$wishlist_element};

			# On récupère la fiche associée
			my %sheet = sql_line({table=>"data_sheets", where=>"id = '$wishlist_element{id_data_sheet}'"});

			my $name = get_traduction({lg=>$lg, id=>$sheet{f2}});
			my $url_detail = data::get_data_detail_url($dbh,\%sheet,$lg,$extlink,'n','',$sheet{id_data_family});

			$table_content .= <<"HTML";
        <tr> 
          <td data-th="$sitetxt{'eshop_history_number'}" class="eshop_orders_nr">
            <a href="$url_detail">$name</a><br/>
            Ref : $sheet{f1}          
          </td>           
        </tr>
HTML
		}

		$content .= <<"HTML";      

	    <table class="table table-striped table-bordered table-hover">
	      <thead>
	        <tr> 
	         <th class="eshop_orders_nr">
	           $sitetxt{'eshop_lastname'}
	         </th>
	        </tr>
	      </thead>

	      <tbody>
	        $table_content
	      </tbody>

	    </table>
HTML
  	
  }

  return $content;

}


################################################################################
# get_orders_history_content
################################################################################
sub get_orders_history_content
{
  my %d = %{$_[0]};

  my %member = %{$d{member}};

  my $mail = get_quoted('mail');
  my $mail_msg = '';
  if($mail eq 'ok')
  {
    $mail_msg = <<"EOH";
      <div class="alert alert-block alert-success alert-success">
        <p>$sitetxt{retour_submitted}</p>
      </div>
EOH
  }

   my $content = <<"HTML";
    <h1 class="page_title"><span><i class="glyphicon glyphicon-list-alt"></i> $sitetxt{eshop_metatitle_history}</span></h1>

    $mail_msg
HTML

  my @orders = sql_lines({
    debug=>0,
    table=>'eshop_orders',
    where=>"id_member='$member{id}'
      AND recap_validate = 'y'",
    ordby=>'id desc'
  });

  if($#orders == -1)
  {
     $content .= <<"HTML";
        <div class="alert alert-block alert-warning">
          <h4 class="alert-heading">$sitetxt{'eshop_erreur_aucune_commande'}</h4>
        </div>
HTML
  }
  else
  {

    %status = (
      'new'=>$sitetxt{eshop_order_status_new},
      'begin'=>$sitetxt{eshop_order_status_begin},
      'unfinished'=>$sitetxt{eshop_order_status_unfinished},
      'current'=>$sitetxt{eshop_order_status_current},
      'finished'=>$sitetxt{eshop_order_status_finished},
      'cancelled'=>$sitetxt{eshop_order_status_cancelled}
    );

    %payment_status = (
      'wait_payment'=>$sitetxt{eshop_payment_status_wait_payment},
      'captured'=>$sitetxt{eshop_payment_status_captured},
      'paid'=>$sitetxt{eshop_payment_status_paid},
      'repaid'=>$sitetxt{eshop_payment_status_repaid},
      'cancelled'=>$sitetxt{eshop_payment_status_cancelled},
    );

    %delivery_status = (
      'current'=>$sitetxt{eshop_delivery_status_current},
      'ready'=>$sitetxt{eshop_delivery_status_ready},
      'partial_sent'=>$sitetxt{eshop_delivery_status_partial_sent},
      'full_sent'=>$sitetxt{eshop_delivery_status_full_sent},
      'cancelled'=>$sitetxt{eshop_delivery_status_cancelled},
      'ready_to_take'=>$sitetxt{eshop_delivery_status_ready_to_take},
      'retour'=>$sitetxt{eshop_delivery_status_retour},
    );

    my $table_content;
    foreach $order (@orders)
    {
      my %order = %{$order};
      
      # Par défaut on prend la date de fin de commande sauf si elle est égale à 0
      my $order_moment = eshop::get_order_moment(\%order);

      my ($jour,$mois,$annee) = split_date($order_moment);  
      my ($heures,$minutes,$secondes) = split_time($order_moment);
      my $date = $jour.'/'.$mois.'/'.$annee;
      my $time = $heures.'h'.$minutes;
      my $tracking = $order{tracking_num};

      # GESTION DU CODE DE TRACKING
      if($order{tracking} ne '')
      {
          $tracking =<<"EOH";
			<li><a target="_blank"  href="$order{tracking}">$sitetxt{'eshop_history_lien_suivi'}</a></li>
EOH
      }
      elsif($order{delivery} eq 'bpost')
      {
        my $trackingref = $order{id};
        if($config{tracking_with_eshop_code})
        {
          $trackingref = $setup{code}.'0'.$order{id};
        }
            
        $tracking =<<"EOH";
          <li><a target="_blank" href="http://track.bpost.be/etr/light/performSearch.do?searchByCustomerReference=true&oss_language=fr&customerReference=$trackingref">$sitetxt{'eshop_history_lien_suivi'}</a></li>
EOH
      }           
                
      my $link_confirmation="/".$sitetxt{eshop_url_confirmation}.'/'.$order{token};
      my $link_proforma="/".$sitetxt{eshop_url_facture_pro_forma}.'/'.$order{token};
      $order{total_discounted_tvac} = display_price($order{total_discounted_tvac});
      
      my $liv = "";
	  if($order{payment_status} eq "paid") {
		$liv = $delivery_status{$order{delivery_status}};
	  }
      if($order{delivery_status} eq 'partial_sent' || $order{delivery_status} eq 'full_sent')
      {
        $liv = <<"EOH";
          <a href="$script_self&sw=delivery_info&id_order=$order{id}">$delivery_status{$order{delivery_status}}</a>               
EOH
      }
                
      # $fact = '<a href="'.$link_confirmation.'" target="_blank">'.$sitetxt{'eshop_history_voir'}.'</a>'; 
      # 
      
      my $link_retour;

      if($setup{return_exchange_disabled} ne "y")
      {
      	$link_retour = <<"EOH";
      		<a href="/cgi-bin/members.pl?sw=member_order_retour&token=$order{token}&lg=$config{current_language}">$sitetxt{'eshop_history_retour'}</a>      
EOH
      	
      }
	  
		my $suivis = "<ul>";

		if($order{payment_status} eq "paid") {
			$suivis .= <<"HTML";
				<li><a href="$link_proforma" target="_blank">$sitetxt{eshop_history_facture}</a></li>
HTML
		}
		if(($order{delivery_status} eq "full_sent" || $order{delivery_status} eq "partial_sent") && $setup{return_exchange_disabled} ne "y") {
			$suivis .= <<"HTML";
				<li><a href="/cgi-bin/members.pl?sw=member_order_retour&token=$order{token}&lg=$config{current_language}">$sitetxt{'eshop_history_retour'}</a></li>
HTML
		}
		$suivis .= $tracking;
		
		$suivis .= "</ul>";
		
		my $total_price = $order{total_discounted_tvac}." ".$sitetxt{eshop_tvac};
		if($order{is_intracom} == 1) {
			$total_price = $order{total_discounted_htva}." ".$sitetxt{eshop_htva};
		}
                
      $table_content .= <<"HTML";
			<tr>
				<td data-th="$sitetxt{'eshop_history_date'}" class="eshop_orders_date text-center">
					<span style="white-space:nowrap;">$date, $time</span>
				</td>
				<td data-th="$sitetxt{'eshop_history_number'}" class="eshop_orders_nr text-center">
					<a href="$link_confirmation" target="_blank">$order{id}</a>
				</td> 
				<td data-th="$sitetxt{'eshop_history_paiement'}" class="eshop_orders_bill text-center">
					<span style="white-space:nowrap;">$total_price - <strong>$payment_status{$order{payment_status}}</strong></span>             
				</td>				
				<td data-th="$sitetxt{'eshop_history_livraison'}" class="eshop_orders_dlv text-center">
					<strong style="white-space:nowrap;">$liv</strong>
				</td>
				<td data-th="$sitetxt{'eshop_history_suivi'}" class="eshop_orders_actions">
					$suivis
				</td>
			</tr>
HTML
    } 

    $content .= <<"HTML";
      

	<table class="table table-striped table-bordered table-hover">
		<thead>
			<tr> 
				<th class="eshop_orders_date text-center">
					$sitetxt{'eshop_history_date'}
				</th>
				<th class="eshop_orders_nr text-center">
					$sitetxt{'eshop_history_number'}
				</th>
				<th class="eshop_orders_bill text-center">
					$sitetxt{'eshop_history_paiement'}
				</th>
				<th class="eshop_orders_dlv text-center">
					$sitetxt{'eshop_history_livraison'}
				</th>
				<th class="eshop_orders_actions">
					$sitetxt{'eshop_history_suivi'}
				</th>
			</tr>
		</thead>

	<tbody>
	$table_content
	</tbody>

	</table>

HTML
  }

  return $content;
}

sub eshop_get_id_group_member
{
     my %d = %{$_[0]};
     
     #read cookie MEMBER
     my $cookie_member = $cgi->cookie($config{front_cookie_name});
     if($cookie_member ne "")
     {
           $cookie_member_ref=decode_json $cookie_member;
           %hash_member=%{$cookie_member_ref};
           
           my %member = sql_line({debug=>$d{debug},debug_results=>$d{debug},table=>"migcms_members",select=>"id_group",where=>"token='$hash_member{member_token}' and token !=''"});
           return $member{id_group};
     }
     else
     {
          return 0;
     }
}

##################################################################
################### generate_sequential_num_db ###################
##################################################################
# Génère un numéro séquentiel en DB en incrémentant le numéro
# le plus élévé trouvé
# 
# Params : id => l'id de la ligne
#          table => Le nom de la table
#          col => Le nom de la colonne du numéro séquentielle
#          col_moment_create => La colonne dans laquelle on stocke la
# 															date de création
# 
# Return : Le numéro séquentiel ajouté
##################################################################
sub generate_sequential_num_db {

    my %d = %{$_[0]};

    my %highest_num = sql_line({
        dbh => $dbh,
        select=>"MAX($d{col}) as num",
        table=>$d{table},
    });


    my $new_sequential_num;
    # Si on récupère un numéro, on l'incrémente de 1
    # pour généré le numéro de facture
    if($highest_num{num} > 0)
    {

        $new_sequential_num = $highest_num{num} + 1;
        $new_sequential_num = sprintf("%08d", $new_sequential_num);
        
    }
    # Sinon, c'est la première facture
    else
    {
        $new_sequential_num = sprintf("%08d", 1);
    }

    # Sauvegarde de la date de génération
    my $set_moment_create;
    if($d{col} eq "invoice_nc")
    {
    	$set_moment_create = ", invoice_nc_create_moment = NOW()";
    }
    elsif($d{col} eq "invoice_num")
    {
    	$set_moment_create = ", invoice_num_create_moment = NOW()";
    }

    # Ajout du numéro de facture en db
    my $stmt = <<"SQL";
        UPDATE eshop_orders
        SET $d{col} = '$new_sequential_num'
        $set_moment_create
        WHERE id = '$d{id}'
SQL

    execstmt($dbh,$stmt);

    return $new_sequential_num;
}

###################################################################
#################### get_eshop_emails_products ####################
###################################################################
# Params: 1 => Le hash avec les infos sur les produits
#         2 => Le préfixe des champs à cibler
#         3 => La langue
#         4 => Le nombre de produit à ajouter
###################################################################
sub get_eshop_emails_products
{
  %emails_config = %{$_[0]};
  my $prefixe = $_[1];
  my $lg = $_[2];
  my $limit = $_[3] || 5;
  my %order = %{$_[4]};

  my $content = <<"HTML";
    <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
      <tr>
        <td class="td40" valign="top" colspan="3">&nbsp;</td>
      </tr>
      <tr>
        <td align="left" class="tdcentercontent" valign="top">
          <span style="color:$emails_config{color_content};font-size:20px;line-height:27px;"><strong>$emails_config{related_items_textid}</strong></span>
        </td>
      </tr>
      <tr>
        <td class="td40" valign="top" colspan="3">&nbsp;</td>
      </tr>
      <tr>
        <td align="left" class="tdproductcontent" valign="top">
          <table width="100%" border="0" cellpadding="0" cellspacing="0" align="center" class="table100pc">
              <tr>
HTML
  
  # Récupération de l'id_tarif
  my %member = sql_line({debug=>0,table=>"migcms_members",select=>"id_tarif",where=>"id='$order{id_member}'"});
  my $id_tarif = $member{id_tarif};
  if(!$id_tarif > 0)
  {
    my %data_setup = read_table($dbh,"data_setup",1);
    $id_tarif = $data_setup{id_default_tarif};
  }

  # On boucle sur le nombre de produit à ajouter
  for(my $i=1 ; $i<=$limit ; $i++)
  {
    my $id_data_sheet = $emails_config{$prefixe."id_data_sheet_".$i};

    my %data_sheet = read_table($dbh, "data_sheets", $id_data_sheet);

    if($data_sheet{id} > 0)
    {
      my $product_name = $emails_config{$prefixe."product_name_".$i."_textid"};
      # my $product_full_price = $emails_config{$prefixe."product_full_price_".$i};

      # On récupère la première photo liée à la data_sheet
      # my %pic = sql_line ({
      #   dbh=>$dbh,
      #   table=>"pics,
      #           data_lnk_sheet_pics as lnk",
      #   where=>"pics.id = lnk.id_pic
      #           AND lnk.id_data_sheet = '$data_sheet{id}'
      #           AND lnk.ordby = 1",
      #   limit => "1",
      # });      

      # Récupération du prix en fonction du tarif
      %stock_tarif = sql_line({
        debug=>0,
        dbh=>$dbh,
        select=>"MIN(st_pu_tvac), st_pu_tvac as st_pu_tvac, discounted as discounted, st_pu_tvac_discounted as st_pu_tvac_discounted",
        table=>"data_stock_tarif",
        where=>"id_data_sheet = '$data_sheet{id}'
                AND id_tarif = '$id_tarif'"
      });

      # Récupération du lien vers la fiche détail
      my $url="";
      if($emails_config{has_detail} eq "y")
      {
        $url = data::get_data_detail_url($dbh,\%data_sheet,$lg,$extlink);
      }      

      my $product_prices;
      my $full_price = eshop::display_price($stock_tarif{st_pu_tvac});
      if($stock_tarif{discounted} eq "n")
      {
        $product_prices = <<"HTML";
          <span style="text-transform:uppercase;color:$emails_config{color_content};font-size:17px;line-height:22px;">$full_price</span>
HTML
      }
      else
      {
        my $full_price_discounted = eshop::display_price($stock_tarif{st_pu_tvac_discounted});
        $product_prices = <<"HTML";
          <span style="text-decoration:line-through;text-transform:uppercase;color:$emails_config{color_content};font-size:17px;line-height:22px;">$full_price</span><br/>
          <span style="text-transform:uppercase;color:$emails_config{color_content_second};font-size:17px;line-height:22px;">$full_price_discounted</span>
HTML
      }

      $content .= <<"HTML";
      <td width="25%" class="td25pc" align="center" style="vertical-align:top;">
        <a href="$config{baseurl}/$url" style="text-decoration:none;" target="_blank">
          <img src="$config{baseurl}/pics/$pic{pic_name_mini}"><br />
          <span style="text-transform:uppercase;color:$emails_config{color_content_second};font-size:17px;line-height:22px;"><strong>$product_name</strong></span><br /><br />
          $product_prices
        </a>
      </td>
HTML
    } 
    
  }  

  $content .= <<"HTML";

    </tr>
      </table>
        </td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
            </table>
HTML

  return $content;
}


sub eshop_mailing_subscribe
{

  my $email_to = $_[0];
  my $lg = $_[1] || 1;

  if ($email_to ne "")
  {
    # Récupération de la config de la boutique
    my %eshop_setup = %{get_setup()};
    # Récupération de la config des emails
    my %eshop_emails_setup = %{get_eshop_emails_setup()};  

    if($eshop_emails_setup{disabled_emailing} ne "y" && $eshop_emails_setup{disabled_subscribe} ne "y")
    {
      # Création d'un nouveau hash sitetxt pour avoir la langue de la commande lorsqu'on appelle le hash
      %sitetxt = %{get_eshop_txt($lg)};

      # Traduction des données reçues
      %emails_config = %{get_eshop_emails_config_trad(\%eshop_emails_setup, $lg, "_textid")};
      # see(\%emails_config);
      

      

      # Récupération de l'entete de l'email
      my $header = get_eshop_emails_header($emails_config{subscribe_subject_textid}, \%emails_config, \%eshop_setup, $lg);
      # Récupération du footer
      my $footer = get_eshop_emails_footer(\%emails_config, \%eshop_setup, $lg);

      # Récupération de l'image du logo
      # Récupération de l'image du logo
      my %logo = sql_line({dbh=>$dbh, table=>"migcms_linked_files", where=>"token = '$emails_config{id_pic}'"});
    	my %logo = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='eshop_emails_setup' AND token='$emails_config{id}' AND table_field='id_pic' ",limit=>"1",ordby=>"ordby"});

     	my $logo_path = $logo{file_dir};
     	$logo_path =~ s/\.\.\///g;
     	$logo_path = $config{fullurl}."/".$logo_path."/".$logo{name_medium};

      # Hard codage du contenu de la newsletter
      $emails_config{subscribe_content_textid} =~ s/<p>//g;
      $emails_config{subscribe_content_textid} =~ s/<\/p>//g;

      $emails_config{subscribe_content_textid} =~ s/{EMAIL_DU_CLIENT}/<a href="mailto:$email_to">$email_to<\/a>/g;

      my $logo = "<a href='$config{fullurl}' target='_blank'><img src='$logo_path' width='$logo{width_medium}' height='$logo{height_medium}' alt='$balises{company}' /></a>";
      my %site_setup = %{setup::get_site_setup()};
		  if($site_setup{use_site_email_template} eq "y")
		  {
		  	$logo = "";
		  }
  


      my $content= <<"HTML";
          
        $header      
            
        <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
          <tr>
            <td width="45" align="center" class="td45"></td>
            <td width="710" align="left" class="td710">

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdleftcontent" valign="top">
              $logo
            </td>
            <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
            <td align="right" class="tdrightcontent" valign="middle">&nbsp;</td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td align="left" class="tdrightcontent" valign="top">
              <span style="color:$emails_config{color_content_second};font-size:30px;line-height:45px;" class="maintitle">$emails_config{subscribe_title_textid}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top">&nbsp;</td>
          </tr>
        </table>
            
        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdrightcontent" valign="top" width="355">
              <span>$emails_config{subscribe_content_textid}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

       
        
        
            </td>
            <td width="45" align="center" class="td45"></td>
          </tr>
        </table>

        $footer
HTML
    
    $content = replace_balises({content=>$content, emails_config=>\%emails_config, order=>\%order, eshop_setup=>\%eshop_setup});

    send_mail($eshop_setup{eshop_email},$email_to,$emails_config{subscribe_subject_textid}, $content, 'html');
    send_mail($eshop_setup{eshop_email},'dev@bugiweb.com','COPIE BUGIWEB '.$emails_config{subscribe_subject_textid}, $content, 'html');

    if($emails_config{subscribe_send_copy} eq "y")
    {
      send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email},$emails_config{subscribe_subject_textid}, $content, 'html');
      # Envoies des copies du mails
      if($eshop_setup{eshop_email_copies} ne "")
      {
          send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email_copies},$emails_config{subscribe_subject_textid},$content,"html");        
      }
    }

    }
    else
    {
      # see();
      # print "Mailing désactivé";
    }
  }
  else
  {
    # see();
    # print "Aucun email de destinataire renseigné (no order)";
  }  
}

sub eshop_mailing_facture_pdf
{
  my %order = %{$_[0]};

  if ($order{id} > 0)
  {
    # Récupération de la config de la boutique
    my %eshop_setup = %{get_setup()};

    # Récupération de la config des emails
    my %eshop_emails_setup = %{get_eshop_emails_setup()};  

    if($eshop_emails_setup{disabled_emailing} ne "y" && $eshop_emails_setup{disabled_facture_pdf} ne "y" && $order{invoice_num} ne "" && $order{email_facture_pdf_sent} ne "y")
    {
      # Création d'un nouveau hash sitetxt pour avoir la langue de la commande lorsqu'on appelle le hash
      %sitetxt = %{get_eshop_txt($lg)};

      # Traduction des données reçues
      %emails_config = %{get_eshop_emails_config_trad(\%eshop_emails_setup, $lg, "_textid")};   

      # Récupération de l'entete de l'email
      my $header = get_eshop_emails_header($emails_config{subscribe_subject_textid}, \%emails_config, \%eshop_setup, $lg);
      # Récupération du footer
      my $footer = get_eshop_emails_footer(\%emails_config, \%eshop_setup, $lg);

      # Récupération de l'image du logo
      # Récupération de l'image du logo
      my %logo = sql_line({dbh=>$dbh, table=>"migcms_linked_files", where=>"token = '$emails_config{id_pic}'"});
    	my %logo = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='eshop_emails_setup' AND token='$emails_config{id}' AND table_field='id_pic' ",limit=>"1",ordby=>"ordby"});

     	my $logo_path = $logo{file_dir};
     	$logo_path =~ s/\.\.\///g;
     	$logo_path = $config{fullurl}."/".$logo_path."/".$logo{name_medium};

      # Hard codage du contenu de la newsletter
      $emails_config{facture_pdf_content_textid} =~ s/<p>//g;
      $emails_config{facture_pdf_content_textid} =~ s/<\/p>//g;

      my $logo = "<a href='$config{fullurl}' target='_blank'><img src='$logo_path' width='$logo{width_medium}' height='$logo{height_medium}' alt='$balises{company}' /></a>";
      my %site_setup = %{setup::get_site_setup()};
		  if($site_setup{use_site_email_template} eq "y")
		  {
		  	$logo = "";
		  }

      my $content= <<"HTML";
          
        $header      
            
        <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
          <tr>
            <td width="45" align="center" class="td45"></td>
            <td width="710" align="left" class="td710">

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdleftcontent" valign="top">
              $logo
            </td>
            <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
            <td align="right" class="tdrightcontent" valign="middle">&nbsp;</td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td align="left" class="tdrightcontent" valign="top">
              <span style="color:$emails_config{color_content_second};font-size:30px;line-height:45px;" class="maintitle">$emails_config{facture_pdf_title_textid}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top">&nbsp;</td>
          </tr>
        </table>
            
        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdrightcontent" valign="top">
              <span>$emails_config{facture_pdf_content_textid}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

       
        
        
            </td>
            <td width="45" align="center" class="td45"></td>
          </tr>
        </table>

        $footer
HTML
    
      $content = replace_balises({content=>$content, emails_config=>\%emails_config, order=>\%order, eshop_setup=>\%eshop_setup});

      my $facture_pdf_path = generate_facture($order{token}, "facture");

      my @splitted = split(/\//,$facture_pdf_path);   
      my $filename = pop @splitted;    

      my $absolute_path = $config{directory_path} . "/inv/" . $filename;

      my %pieces_jointes = (
        type     => "file/pdf",
        id       => $absolute_path,
        path     => $absolute_path,
        Filename => $filename
      );

      my @pjs;
  
      if(-s $absolute_path)
      {
         push @pjs,\%pieces_jointes;
      }

      # send_mail_with_attachment($eshop_setup{eshop_email},$order{billing_email},$emails_config{facture_pdf_subject_textid}, $content, '','html');
      # send_mail_with_attachment($eshop_setup{eshop_email},'dev@bugiweb.com','COPIE BUGIWEB '.$emails_config{facture_pdf_subject_textid}, $content, '', 'html');
      
      send_mail_with_attachment($eshop_setup{eshop_email},$order{billing_email},$emails_config{facture_pdf_subject_textid}, $content,\@pjs,"html",'');
      send_mail_with_attachment($eshop_setup{eshop_email},'dev@bugiweb.com','COPIE BUGIWEB '.$emails_config{facture_pdf_subject_textid}, $content,\@pjs,"html",'');

      if($emails_config{facture_pdf_send_copy} eq "y")
      {
        # send_mail_with_attachment($eshop_setup{eshop_email},$eshop_setup{eshop_email},$emails_config{facture_pdf_subject_textid}, $content, $facture_pdf, 'html');
        send_mail_with_attachment($eshop_setup{eshop_email},$eshop_setup{eshop_email},$emails_config{facture_pdf_subject_textid}, $content,\@pjs,"html",'');
        # Envoies des copies du mails
        if($eshop_setup{eshop_email_copies} ne "")
        {
            send_mail_with_attachment($eshop_setup{eshop_email},$eshop_setup{eshop_email_copies},$emails_config{facture_pdf_subject_textid},$content,\@pjs,"html",'');        
        }
      }
      my $stmt = "UPDATE eshop_orders SET email_facture_pdf_sent = 'y' WHERE id = $order{id}";
      execstmt($dbh,$stmt);
      

    }
    else
    {
    }
  }
  else
  {
  }  
}

sub eshop_mailing_newsletter_subscription
{

  my $email_to = $_[0];
  my $lg = $_[1] || 1;


  if ($email_to ne "")
  {
    # Récupération de la config de la boutique
    my %eshop_setup = %{get_setup()};
    # Récupération de la config des emails
    my %eshop_emails_setup = %{get_eshop_emails_setup()};  

    if($eshop_emails_setup{disabled_emailing} ne "y" && $eshop_emails_setup{disabled_bienvenue} ne "y")
    {
      # Création d'un nouveau hash sitetxt pour avoir la langue de la commande lorsqu'on appelle le hash
      %sitetxt = %{get_eshop_txt($lg)};
      # Traduction des données reçues
      %emails_config = %{get_eshop_emails_config_trad(\%eshop_emails_setup, $lg, "_textid")};
      # see(\%emails_config);

      # Récupération de l'entete de l'email
      my $header = get_eshop_emails_header($emails_config{bienvenue_subject_textid}, \%emails_config, \%eshop_setup, $lg);
      # Récupération du footer
      my $footer = get_eshop_emails_footer(\%emails_config, \%eshop_setup, $lg);

      # Récupération de l'image du logo
      # Récupération de l'image du logo
      my %logo = sql_line({dbh=>$dbh, table=>"migcms_linked_files", where=>"token = '$emails_config{id_pic}'"});
    	my %logo = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='eshop_emails_setup' AND token='$emails_config{id}' AND table_field='id_pic' ",limit=>"1",ordby=>"ordby"});

     	my $logo_path = $logo{file_dir};
     	$logo_path =~ s/\.\.\///g;
     	$logo_path = $config{fullurl}."/".$logo_path."/".$logo{name_medium};
  

      # Hard codage du style pour la liste de li
      $emails_config{bienvenue_list_textid} =~ s/<ul>/<ul style="margin-left:25px;">/g;

      # Hard codage du contenu de la newsletter
      $emails_config{bienvenue_list_textid} =~ s/<p>//g;
      $emails_config{bienvenue_content_textid} =~ s/<\/p>//g;

      # Remplacement de la balise contenant l'email du client
      $emails_config{bienvenue_content_textid} =~ s/{EMAIL_DU_CLIENT}/<a href="mailto:$email_to">$email_to<\/a>/g;

      # Récupération des produits recommandés
      my $products_content = get_eshop_emails_products(\%emails_config, "bienvenue_", $lg, 4, \%order);

      my $logo = "<a href='$config{fullurl}' target='_blank'><img src='$logo_path' width='$logo{width_medium}' height='$logo{height_medium}' alt='$balises{company}' /></a>";
      my %site_setup = %{setup::get_site_setup()};
		  if($site_setup{use_site_email_template} eq "y")
		  {
		  	$logo = "";
		  }

      my $content= <<"HTML";
          
        $header      
            
        <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
          <tr>
            <td width="45" align="center" class="td45"></td>
            <td width="710" align="left" class="td710">

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdleftcontent" valign="top">
              $logo
            </td>
            <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
            <td align="right" class="tdrightcontent" valign="middle">&nbsp;</td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td align="left" class="tdrightcontent" valign="top">
              <span style="color:$emails_config{color_content_second};font-size:30px;line-height:45px;" class="maintitle">$emails_config{bienvenue_title_textid}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top">&nbsp;</td>
          </tr>
        </table>
            
        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdleftcontent" valign="top" width="315">
              <span style="color:$emails_config{color_content};font-size:20px;line-height:27px;"><strong>$emails_config{bienvenue_subtitle_textid}</strong></span>
              <br /><br />
              $emails_config{bienvenue_list_textid}
            </td>
            <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
            <td align="left" class="tdrightcontent" valign="top" width="355">
              <span>$emails_config{bienvenue_content_textid}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>



        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>
            
        
              $products_content            
        
        
            </td>
            <td width="45" align="center" class="td45"></td>
          </tr>
        </table>

        $footer
HTML

    $content = replace_balises({content=>$content, emails_config=>\%emails_config, order=>\%order, eshop_setup=>\%eshop_setup});

    send_mail($eshop_setup{eshop_email},$email_to,$emails_config{bienvenue_subject_textid}, $content, 'html');
    send_mail($eshop_setup{eshop_email},'dev@bugiweb.com','COPIE BUGIWEB '.$emails_config{bienvenue_subject_textid}, $content, 'html');

    if($emails_config{bienvenue_send_copy} eq "y")
    {
      send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email},$emails_config{bienvenue_subject_textid}, $content, 'html');
      # Envoies des copies du mails
      if($eshop_setup{eshop_email_copies} ne "")
      {
          send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email_copies},$emails_config{bienvenue_subject_textid},$content,"html");        
      }
    }

    }
    else
    {
      # see();
      # print "Mailing désactivé";
    }
  }
  else
  {
    # see();
    # print "Aucun email de destinataire renseigné";
  }  
}


sub eshop_mailing_order_send
{ 
  my %order = %{$_[0]};


  if($order{id} > 0)
  {
    # Récupération de la config de la boutique
    my %eshop_setup = %{get_setup()};
    # Récupération de la config des emails
    my %eshop_emails_setup = %{get_eshop_emails_setup()};

    if($eshop_emails_setup{disabled_emailing} ne "y" && $eshop_emails_setup{disabled_expediee} ne "y")
    {
      # Traduction des données reçues
      my $lg = $order{order_lg};
      if($lg <= 0)
      {
        $lg = 1;
      }
      # Création d'un nouveau hash sitetxt pour avoir la langue de la commande lorsqu'on appelle le hash
      %sitetxt = %{get_eshop_txt($lg)};

      # Préfixe pour récupérer les bons champs de livraison
      my $prefixe = "delivery_";
      my %delivery = sql_line({dbh=>$dbh, table=>"eshop_deliveries", where=>"name = '$order{delivery}' AND name != ''"});
      if($delivery{identity_tier} eq "y")
      {
        $prefixe = "tier_";
      }

      %emails_config = %{get_eshop_emails_config_trad(\%eshop_emails_setup, $lg, "_textid")};
      # Nom du pays de livraison
      my $country_name = get_country_name($order{$prefixe."country"}, $lg);

      # Récupération de l'entete de l'email
      my $header = get_eshop_emails_header($emails_config{expediee_subject_textid}, \%emails_config, \%eshop_setup, $lg);
      # Récupération du footer
      my $footer = get_eshop_emails_footer(\%emails_config, \%eshop_setup, $lg);

      # Récupération de l'image du logo
      # Récupération de l'image du logo
      my %logo = sql_line({dbh=>$dbh, table=>"migcms_linked_files", where=>"token = '$emails_config{id_pic}'"});
    	my %logo = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='eshop_emails_setup' AND token='$emails_config{id}' AND table_field='id_pic' ",limit=>"1",ordby=>"ordby"});

     	my $logo_path = $logo{file_dir};
     	$logo_path =~ s/\.\.\///g;
     	$logo_path = $config{fullurl}."/".$logo_path."/".$logo{name_medium};

      # Hard codage des textarea_id_editor
      $emails_config{expediee_content_textid} =~ s/<p>//g;
      $emails_config{expediee_content_textid} =~ s/<\/p>//g;

      $emails_config{expediee_code_suivi_content_textid} =~ s/<p>//g;
      $emails_config{expediee_code_suivi_content_textid} =~ s/<\/p>//g;

      $emails_config{expediee_products_send_content_textid} =~ s/<p>//g;
      $emails_config{expediee_products_send_content_textid} =~ s/<\/p>//g;

      $emails_config{expediee_contact_textid} =~ s/<p>//g;
      $emails_config{expediee_contact_textid} =~ s/<\/p>//g;


      my $delivery_company;
      if($order{$prefixe."company"} ne "")
      {
        $delivery_company = $order{$prefixe."company"};
        $delivery_company = <<"HTML";
          <strong>$delivery_company</strong><br />
HTML
      }


      # Récupération des produits de la commande
      my $order_products = get_eshop_order_products(\%order,"y","y");

      my $delivery_firstname = $order{$prefixe."firstname"};
      my $delivery_lastname  = $order{$prefixe."lastname"};
      my $delivery_street    = $order{$prefixe."street"};
      my $delivery_number    = $order{$prefixe."number"};
      my $delivery_box       = $order{$prefixe."box"};
      my $delivery_zip       = $order{$prefixe."zip"};
      my $delivery_city      = $order{$prefixe."city"};
      my $delivery_tel1      = $order{$prefixe."phone"};
      my $delivery_email     = $order{$prefixe."email"};

      # Code de suivi
      my $tracking_content;
      my $tracking_text;


      if($order{tracking} ne "" && $order{tracking_num} ne "")
      {
        $tracking_content = <<"HTML";
          <span><strong>$sitetxt{eshop_mailing_order_code_suivi} * :</strong> <a href="$order{tracking}" target="_blank">$order{tracking_num}</a><br /></span>
HTML
        $tracking_text = <<"HTML";
          <span><i>* $emails_config{expediee_code_suivi_content_textid}</i></span>
HTML
      }
    
      # Récupération des produits recommandés
      my $products_content = get_eshop_emails_products(\%emails_config, "expediee_", $lg, 4, \%order);

      my $logo = "<a href='$config{fullurl}' target='_blank'><img src='$logo_path' width='$logo{width_medium}' height='$logo{height_medium}' alt='$balises{company}' /></a>";
      my %site_setup = %{setup::get_site_setup()};
		  if($site_setup{use_site_email_template} eq "y")
		  {
		  	$logo = "";
		  }

      my $content= <<"HTML";

        $header

        <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
          <tr>
            <td width="45" align="center" class="td45"></td>
            <td width="710" align="left" class="td710">

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdleftcontent" valign="top">
              $logo
            </td>
            <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
            <td align="right" class="tdrightcontent" valign="middle">
              $sitetxt{eshop_mailing_order_number} <strong>$order{id}</strong>
            </td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td align="left" class="tdcentercontent" valign="top">
              <span style="color:$emails_config{color_content_second};font-size:30px;line-height:45px;" class="maintitle">$emails_config{expediee_title_textid}</span><br /><br />
              <span>$emails_config{expediee_content_textid}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>
            
        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdcentercontent" valign="top" colspan="3">
              <span style="color:$emails_config{color_content};font-size:20px;line-height:27px;"><strong>$sitetxt{eshop_mailing_order_send_to}</strong></span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
           <td align="left" class="tdleftcontent" valign="top">
										<span><strong>$sitetxt{eshop_invoice2_header_adresse_livraison} :</strong><br /> $delivery_company $delivery_street $delivery_number $delivery_box<br />$delivery_zip $delivery_city<br />$country_name</span>
									</td>
									<td width="40" align="center" class="td40" valign="top">&nbsp;</td>
									<td align="left" class="tdrightcontent" valign="top">
										$tracking_content
									</td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdcentercontent" valign="top" colspan="3">
              $tracking_text
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdcentercontent" valign="top">
              <span style="color:$emails_config{color_content};font-size:20px;line-height:27px;"><strong>$sitetxt{eshop_mailing_order_products_send}</strong></span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdlcentercontent" valign="top">
              <span>$emails_config{expediee_products_send_content_textid}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdcentercontent" valign="top">

              $order_products
            
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdlcentercontent" valign="top">
              <span>$emails_config{expediee_contact_textid}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>
            
        
              
              $products_content
              

            
            
            
            
            </td>
            <td width="45" align="center" class="td45"></td>
          </tr>
        </table>

    $footer
HTML
      
      $content = replace_balises({content=>$content, emails_config=>\%emails_config, order=>\%order, eshop_setup=>\%eshop_setup});

      send_mail($eshop_setup{eshop_email},$order{billing_email},$emails_config{expediee_subject_textid}, $content, 'html');
      send_mail($eshop_setup{eshop_email},'dev@bugiweb.com','COPIE BUGIWEB '.$emails_config{expediee_subject_textid}, $content, 'html');

      if($emails_config{expediee_send_copy} eq "y")
      {
        send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email},$emails_config{expediee_subject_textid}, $content, 'html');
        # Envoies des copies du mails
        if($eshop_setup{eshop_email_copies} ne "")
        {
            send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email_copies},$emails_config{expediee_subject_textid},$content,"html");        
        }
      }

      # On sauvegarde en db le fait que l'email a été envoyé
      my $stmt = "UPDATE eshop_orders SET email_delivery_sent = 'y' WHERE id = $order{id}";
      execstmt($dbh,$stmt); 


      

    }
  }
  else
  {

  }

}

sub eshop_mailing_confirmation
{
  my %order = %{$_[0]};

  if($order{email_sent} == 0)
  {


  if($order{id} > 0)
  {
    # Récupération de la config de la boutique
    my %eshop_setup = %{get_setup()};
    # Récupération de la config des emails
    my %eshop_emails_setup = %{get_eshop_emails_setup()};

    if($eshop_emails_setup{disabled_emailing} ne "y" && $eshop_emails_setup{disabled_confirmation} ne "y")
    {
      # Traduction des données reçues
      my $lg = $order{order_lg};
      if($lg <= 0)
      {
        $lg = 1;
      }
      # Création d'un nouveau hash sitetxt pour avoir la langue de la commande lorsqu'on appelle le hash
      %sitetxt = %{get_eshop_txt($lg)};

      # Préfixe pour récupérer les bons champs de livraison
      my $prefixe = "delivery_";
      my %delivery = sql_line({dbh=>$dbh, table=>"eshop_deliveries", where=>"name = '$order{delivery}' AND name != ''"});
      if($delivery{identity_tier} eq "y")
      {
        $prefixe = "tier_";
      }

      %emails_config = %{get_eshop_emails_config_trad(\%eshop_emails_setup, $lg, "_textid")};
      # Nom du pays de livraison
      my $country_name = get_country_name($order{$prefixe."country"}, $lg);

      # Récupération de l'entete de l'email
      my $header = get_eshop_emails_header($emails_config{confirmation_subject_textid}, \%emails_config, \%eshop_setup, $lg);
      # Récupération du footer
      my $footer = get_eshop_emails_footer(\%emails_config, \%eshop_setup, $lg);

      # Récupération de l'image du logo
      # Récupération de l'image du logo
      my %logo = sql_line({dbh=>$dbh, table=>"migcms_linked_files", where=>"token = '$emails_config{id_pic}'"});
    	my %logo = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='eshop_emails_setup' AND token='$emails_config{id}' AND table_field='id_pic' ",limit=>"1",ordby=>"ordby"});

     	my $logo_path = $logo{file_dir};
     	$logo_path =~ s/\.\.\///g;
     	$logo_path = $config{fullurl}."/".$logo_path."/".$logo{name_medium};
      # Hard codage du contenu de la newsletter
      $emails_config{confirmation_content_textid} =~ s/<p>//g;
      $emails_config{confirmation_content_textid} =~ s/<\/p>//g;



      # Récupération des produits recommandés
      my $products_content = get_eshop_emails_products(\%emails_config, "confirmation_", $lg, 4, \%order);

      # Récupération des produits de la commande
      my $order_products = get_eshop_order_products(\%order,"y","y");

	  my $instructions_paiement = '';
	  
	  if($order{payment} eq 'virement')
	  {
		$instructions_paiement = <<"EOH";
          <div class="alert alert-block alert-info">
          		<h4 class="alert-heading">$sitetxt{eshop_virement_instructions_1}</h4>
          		<p>$sitetxt{eshop_virement_instructions_2}:<br />
                <br />$eshop_setup{eshop_name}
                <br />$eshop_setup{eshop_street}
                <br />$eshop_setup{eshop_zip_city}<br />
                <br /><strong>$sitetxt{eshop_banque} :</strong> $eshop_setup{eshop_banque}
                <br /><strong>$sitetxt{eshop_iban} :</strong> $eshop_setup{eshop_iban}
                <br /><strong>$sitetxt{eshop_bic} :</strong> $eshop_setup{eshop_bic}
                <br /><strong>$sitetxt{eshop_communication} :</strong> $eshop_setup{eshop_name} $order{id}</p>
          	</div>
EOH
	  }


      my $delivery_company;
      if($order{$prefixe."company"} ne "")
      {
        $delivery_company = $order{$prefixe."company"};
        $delivery_company = <<"HTML";
          <strong>$delivery_company</strong><br />
HTML
      }

      my $delivery_tva;
      if($order{$prefixe."vat"} ne "")
      {
        $delivery_tva = $order{$prefixe."vat"};
        $delivery_tva = <<"HTML";
        $delivery_tva<br/>
HTML
      }

      my $delivery_box;
      if($order{$prefixe."box"} ne "")
      {
        $delivery_box = $order{$prefixe."box"};
        $delivery_box = <<"HTML";
        $sitetxt{eshop_box} $order{delivery_box}
HTML
      }
	  
      my $delivery_firstname = $order{$prefixe."firstname"};
      my $delivery_lastname  = $order{$prefixe."lastname"};
      my $delivery_street    = $order{$prefixe."street"};
      my $delivery_number    = $order{$prefixe."number"};
      my $delivery_box       = $order{$prefixe."box"};
      my $delivery_zip       = $order{$prefixe."zip"};
      my $delivery_city      = $order{$prefixe."city"};
	  
	  	my $logo = "<a href='$config{fullurl}' target='_blank'><img src='$logo_path' width='$logo{width_medium}' height='$logo{height_medium}' alt='$balises{company}' /></a>";
      my %site_setup = %{setup::get_site_setup()};
		  if($site_setup{use_site_email_template} eq "y")
		  {
		  	$logo = "";
		  }

		  my $infos_livraison = "";
		  if($eshop_setup{recap_hide_deliveries_address} ne "y")
		  {
		  	$infos_livraison = <<"EOH";
		  		<table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
            <tr>
              <td class="td40" valign="top">&nbsp;</td>
            </tr>
            <tr>
              <td align="left" class="tdcentercontent" valign="top">
                <span style="color:$emails_config{color_content};font-size:20px;line-height:27px;"><strong>$sitetxt{eshop_mailing_order_will_be_send_to}</strong></span>
              </td>
            </tr>
            <tr>
              <td class="td40" valign="top">&nbsp;</td>
            </tr>
            <tr>
              <td align="left" class="tdcentercontent" valign="top">
										<span><strong>$sitetxt{eshop_invoice2_header_adresse_livraison} :</strong><br/>$delivery_company $delivery_tva $delivery_firstname $delivery_lastname<br/>$delivery_street $delivery_number $delivery_box<br />$delivery_zip $delivery_city<br />$country_name<br/> $order{delivery_phone}<br/>$order{delivery_email}</span>
									</td>
            </tr>
            <tr>
              <td class="td40" valign="top">&nbsp;</td>
            </tr>
          </table>

          <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
            <tr>
              <td class="td40" valign="top" colspan="3">&nbsp;</td>
            </tr>
            <tr>
              <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
            </tr>
            <tr>
              <td class="td40" valign="top" colspan="3">&nbsp;</td>
            </tr>
          </table>
EOH
		  }

	  
	  
      my $content = <<"HTML";
        $header
        <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
        <tr>
          <td width="45" align="center" class="td45"></td>
        <td width="710" align="left" class="td710">

          <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
            <tr>
              <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
            </tr>
            <tr>
              <td align="left" class="tdleftcontent" valign="top">
                $logo
              </td>
              <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
              <td align="right" class="tdrightcontent" valign="middle">
                $sitetxt{eshop_mailing_order_number} <strong>$order{id}</strong>
              </td>
            </tr>
            <tr>
              <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
            </tr>
          </table>

          <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
            <tr>
              <td align="left" class="tdcentercontent" valign="top">
                <span style="color:$emails_config{color_content_second};font-size:30px;line-height:45px;" class="maintitle">$emails_config{confirmation_title_textid}</span><br /><br />
                <span>$emails_config{confirmation_content_textid}</span>
              </td>
            </tr>
            <tr>
              <td class="td40" height="40" valign="top">&nbsp;</td>
            </tr>
          </table>

          <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
            <tr>
              <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
            </tr>
            <tr>
              <td class="td40" valign="top" colspan="3">&nbsp;</td>
            </tr>
          </table>
          
		  		$instructions_paiement
		  
		  
          $infos_livraison
          

          <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
            <tr>
              <td class="td40" valign="top">&nbsp;</td>
            </tr>
            <tr>
              <td align="left" class="tdcentercontent" valign="top">
                <span style="color:$emails_config{color_content};font-size:20px;line-height:27px;"><strong>$sitetxt{eshop_mailing_order_infos_title}</strong></span>
              </td>
            </tr>
            <tr>
              <td class="td40" valign="top">&nbsp;</td>
            </tr>
            <tr>
              <td align="left" class="tdlcentercontent" valign="top">
                <span>$sitetxt{eshop_mailing_order_infos_txt} <strong>$order{id}</strong>.</span>
              </td>
            </tr>
            <tr>
              <td class="td40" valign="top">&nbsp;</td>
            </tr>
            <tr>
              <td align="left" class="tdcentercontent" valign="top">

                $order_products
              
              </td>

            </tr>
            <tr>
            <td class="td40" valign="top">&nbsp;</td>
	          </tr>
	          <tr>
	            <td align="left" class="tdcentercontent" valign="top">
	              <span><strong>$sitetxt{eshop_mailing_order_comment_title}</strong><br />$order{commentaire}</span>
	              $retour_link
	            </td>
	          </tr>
            <tr>
              <td class="td40" valign="top">&nbsp;</td>
            </tr>
          </table>



      $products_content
            
          
          
          
          
          
          </td>
          <td width="45" align="center" class="td45"></td>
        </tr>
      </table>

      $footer
HTML

      $content = replace_balises({content=>$content, emails_config=>\%emails_config, order=>\%order, eshop_setup=>\%eshop_setup});

	  members::member_add_event({group=>'eshop',type=>"eshop_mailing_confirmation",name=>"Envoi du mail de confirmation de commande de $eshop_setup{eshop_email} à $order{billing_email}. Objet: $emails_config{confirmation_subject_textid}",detail=> $order{id}});
      send_mail($eshop_setup{eshop_email},$order{billing_email},$emails_config{confirmation_subject_textid}, $content, 'html');
      send_mail($eshop_setup{eshop_email},'dev@bugiweb.com','COPIE BUGIWEB '.$emails_config{confirmation_subject_textid}, $content, 'html');

      if($emails_config{confirmation_send_copy} eq "y")
      {
		members::member_add_event({group=>'eshop',type=>"eshop_mailing_confirmation",name=>"Envoi de la copie du mail de confirmation de commande de $eshop_setup{eshop_email} à $eshop_setup{eshop_email}. Objet: $emails_config{confirmation_subject_textid}",detail=> $order{id}});

		send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email},$emails_config{confirmation_subject_textid}, $content, 'html');
        # Envoies des copies du mails
        if($eshop_setup{eshop_email_copies} ne "")
        {
       		members::member_add_event({group=>'eshop',type=>"eshop_mailing_confirmation",name=>"Envoi d'une copie du mail de confirmation de commande de $eshop_setup{eshop_email} à $eshop_setup{eshop_email_copies}. Objet: $emails_config{confirmation_subject_textid}",detail=> $order{id}});
			send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email_copies},$emails_config{confirmation_subject_textid},$content,"html");        
        }
      }

      my $stmt = "UPDATE eshop_orders SET email_sent=1 WHERE id=$order{id}";
      execstmt($dbh,$stmt);  
    }
  }
  else
  {

  }
}

}



sub eshop_mailing_facture
{
  my %order = %{$_[0]};
  my $is_facture = $_[1];  

  if($order{id} > 0)
  {
    # Récupération de la config de la boutique
    my %eshop_setup = %{get_setup()};
    # Récupération de la config des emails
    my %eshop_emails_setup = %{get_eshop_emails_setup()};

    # Si c'est pour généré l'aperçu de la facture OU si les mailings sont activés
    if($is_facture eq "y" || ($eshop_emails_setup{disabled_emailing} ne "y" && $eshop_emails_setup{disabled_facture} ne "y"))
    {
      # Traduction des données reçues
      my $lg = $order{order_lg};
      if($lg <= 0)
      {
        $lg = 1;
      }
      # Création d'un nouveau hash sitetxt pour avoir la langue de la commande lorsqu'on appelle le hash
      %sitetxt = %{get_eshop_txt($lg)};

      %emails_config = %{get_eshop_emails_config_trad(\%eshop_emails_setup, $lg, "_textid")};

      # Préfixe pour récupérer les bons champs de livraison
      my $prefixe = "delivery_";
      my %delivery = sql_line({dbh=>$dbh, table=>"eshop_deliveries", where=>"name = '$order{delivery}' AND name != ''"});
      if($delivery{identity_tier} eq "y")
      {
        $prefixe = "tier_";
      }

      # Nom du pays de livraison
      my $country_name = get_country_name($order{$prefixe."country"}, $lg);
      # Nom du pays de facturation
      my $country_name_billing = get_country_name($order{billing_country}, $lg);

      # Récupération de l'entete de l'email
      my $charset;
      if($is_facture eq "y")
      {
        $charset = "utf8";
      }
      my $header = get_eshop_emails_header($emails_config{facture_subject_textid}, \%emails_config, \%eshop_setup, $charset, $lg);
      # Récupération du footer
      my $footer = get_eshop_emails_footer(\%emails_config, \%eshop_setup, $lg);

      # Récupération du label de méthode de livraison
      my %delivery = sql_line({
        dbh=>$dbh,
        table=>"eshop_deliveries",
        where=>"name = '$order{delivery}'",
      });
      my ($delivery_label,$empty) = get_textcontent($dbh, $delivery{id_textid_name}, $order{order_lg});

      # Récupération du label de méthode de paiement
      my %payment = sql_line({
        dbh=>$dbh,
        table=>"eshop_payments",
        where=>"name = '$order{payment}'",
      });
      my ($payment_label,$empty) = get_textcontent($dbh, $payment{id_textid_name}, $order{order_lg});

      # Hard codage du contenu du mail
      $emails_config{facture_content_textid} =~ s/<p>//g;
      $emails_config{facture_content_textid} =~ s/<\/p>//g;


      # Afficher la société si elle est renseignée
      my $billing_company;
      if($order{billing_company} ne "")
      {
        $billing_company = <<"HTML";
          <strong>$order{billing_company}</strong><br />
HTML
      }
     my $delivery_company;
      if($order{$prefixe."company"} ne "")
      {
        $delivery_company = $order{$prefixe."company"};
        $delivery_company = <<"HTML";
          <strong>$delivery_company</strong><br />
HTML
      }

      # Afficher la tva si elle est renseignée
      my $billing_tva;
      if($order{billing_vat} ne "")
      {
        $billing_tva = <<"HTML";
        $order{billing_vat}<br/>
HTML
      }



      my $delivery_tva;
      if($order{delivery_vat} ne "")
      {
        $delivery_tva = $order{$prefixe."vat"};
        $delivery_tva = <<"HTML";
        $delivery_tva<br/>
HTML
      }

      my $delivery_box;
      if($order{delivery_box} ne "" && $order{delivery_zip})
      {
        $delivery_box = $order{$prefixe."box"};
        $delivery_box = <<"HTML";
        $sitetxt{eshop_box} $delivery_box
HTML
      }

      my $billing_box;
      if($order{billing_box} ne "")
      {
        $billing_box = <<"HTML";
        $sitetxt{eshop_box} $order{billing_box}
HTML
      }

      my $delivery_firstname = $order{$prefixe."firstname"};
      my $delivery_lastname  = $order{$prefixe."lastname"};
      my $delivery_street    = $order{$prefixe."street"};
      my $delivery_number    = $order{$prefixe."number"};
      my $delivery_box       = $order{$prefixe."box"};
      my $delivery_zip       = $order{$prefixe."zip"};
      my $delivery_city      = $order{$prefixe."city"};
      my $delivery_tel1      = $order{$prefixe."phone"};
      my $delivery_email     = $order{$prefixe."email"};

      
      my $client_number;
      if($order{id_member} > 0)
      {
        $client_number = <<"HTML";
          <strong>$sitetxt{eshop_invoice2_facture_numclient} : </strong>$order{id_member}<br/>
HTML
      }

      # Conversion du format de la date de commande
      $order{order_finish_moment} = trim(to_ddmmyyyy(get_order_moment(\%order)));

      # Récupération de l'image du logo
      # my %logo = sql_line({dbh=>$dbh, table=>"migcms_linked_files", where=>"token = '$emails_config{id_pic}'"});
    	my %logo = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='eshop_emails_setup' AND token='$emails_config{id}' AND table_field='id_pic' ",limit=>"1",ordby=>"ordby"});

     	my $logo_path = $logo{file_dir};
     	$logo_path =~ s/\.\.\///g;
     	$logo_path = $config{fullurl}."/".$logo_path."/".$logo{name_medium};

      # Récupération des produits de la commande
      my $order_products = get_eshop_order_products(\%order,"y","y");

      my $retour_link;
      if($eshop_setup{return_exchange_disabled} ne "y")
      {
        $link = $config{fullurl}.'/'.$sitetxt{eshop_url_retour}."&token=$order{token}";   
        $retour_link = <<"HTML";
      </br><br/>
        <table border="0" cellpadding="0" cellspacing="0" align="left" bgcolor="$emails_config{color_button_bg}">
              <tr>
                  <td width="25">&nbsp;</td>
                  <td height="50"><a href="$link" style="color:$emails_config{color_button};text-decoration:none;">$sitetxt{eshop_history_retour}</a></td>
                  <td width="25">&nbsp;</td>
              </tr>
            </table>
HTML
      }

      my $delivery_company;
      if($order{delivery_company} ne "")
      {
        $delivery_company = <<"HTML";
        $sitetxt{eshop_company} : $order{delivery_company}
HTML
      }

      my $logo = "<a href='$config{fullurl}' target='_blank'><img src='$logo_path' width='$logo{width_medium}' height='$logo{height_medium}' alt='$balises{company}' /></a>";
      my %site_setup = %{setup::get_site_setup()};
		  if($site_setup{use_site_email_template} eq "y")
		  {
		  	$logo = "";
		  }

		  my $billing_coordonnees = <<"HTML";
		  	$billing_company $billing_tva $order{billing_lastname} $order{billing_firstname}<br/>$order{billing_street} $order{billing_number} $billing_box<br />$order{billing_zip} $order{billing_city}<br />$country_name_billing
HTML
			if($config{custom_mailing_pro_forma_coordonnees_func} ne "")
			{
				my $custom_mailing_pro_forma_coordonnees_func = 'def_handmade::'.$config{custom_mailing_pro_forma_coordonnees_func};
				$billing_coordonnees = &$custom_mailing_pro_forma_coordonnees_func({order => \%order, lg=>$lg});		
			}

			my $infos_livraison = "";
			if($eshop_setup{recap_hide_deliveries_address} ne "y")
		  {
		  	$infos_livraison = <<"EOH";
		  		<table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdcentercontent" valign="top" colspan="3">
              <span style="color:$emails_config{color_content};font-size:20px;line-height:27px;"><strong>$sitetxt{eshop_mailing_order_will_be_send_to}</strong></span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdleftcontent" valign="top">
							<span><strong>$sitetxt{eshop_invoice2_header_adresse_livraison} :</strong><br/>$delivery_company $delivery_tva $delivery_lastname $delivery_firstname<br />$delivery_street $delivery_number $delivery_box<br />$delivery_zip $delivery_city<br />$country_name</span>
						</td>
						<td width="40" align="center" class="td40" valign="top">&nbsp;</td>
						<td align="left" class="tdrightcontent" valign="top">
							<span><strong>$sitetxt{eshop_invoice2_phone}. : </strong>$delivery_tel1<br /><strong>$sitetxt{eshop_email} : </strong>$delivery_email<br /><strong>$sitetxt{eshop_invoice2_facture_methlivraison} : </strong>$delivery_label<br />$company</span>
						</td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>
        
        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

EOH
		  }

      my $content = <<"HTML";
        $header

        <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
          <tr>
            <td width="45" align="center" class="td45"></td>
            <td width="710" align="left" class="td710">

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td align="left" class="tdleftcontent" valign="top">
              $logo
            </td>
            <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
          </tr>  
          <tr>
          	<td width="40" align="center" class="td40" height="40"  valign="top">&nbsp;</td>
          </tr>        
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td align="left" class="tdcentercontent" valign="top">
              <span style="color:$emails_config{color_content_second};font-size:30px;line-height:45px;" class="maintitle">$emails_config{facture_title_textid}</span><br /><br />
              <span>$emails_config{facture_content_textid}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdcentercontent" valign="top" colspan="3">
              <span style="color:$emails_config{color_content};font-size:20px;line-height:27px;"><strong>$eshop_setup{eshop_name}</strong></span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdleftcontent" valign="top">
              <span>$eshop_setup{eshop_street}<br />$eshop_setup{eshop_zip_city}<br />$eshop_setup{eshop_country}<br /><strong>$sitetxt{eshop_invoice2_phone}. : </strong>$eshop_setup{eshop_tel}<br /><strong>$sitetxt{eshop_facture_mail} : </strong>$eshop_setup{eshop_email}<br /><strong>$sitetxt{eshop_facture_web} : </strong>$eshop_setup{eshop_web}</span>
            </td>
            <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
            <td align="left" class="tdrightcontent" valign="top">
              <span><strong>$sitetxt{eshop_tva} : </strong>$eshop_setup{eshop_tva}<br /><strong>$sitetxt{eshop_invoice2_banque} : </strong>$eshop_setup{eshop_banque}<br /><strong>$sitetxt{eshop_facture_iban} : </strong>$eshop_setup{eshop_iban}<br /><strong>$sitetxt{eshop_facture_bic} : </strong>$eshop_setup{eshop_bic}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>
            
        $infos_livraison
    

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdcentercontent" valign="top" colspan="3">
              <span style="color:$emails_config{color_content};font-size:20px;line-height:27px;"><strong>$sitetxt{eshop_mailing_order_billing_to}</strong></span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdleftcontent" valign="top">
              <span>$billing_coordonnees</span>
            </td>
            <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
            <td align="left" class="tdrightcontent" valign="top">
              <span><strong>$sitetxt{eshop_invoice2_phone}. : </strong>$order{billing_phone}<br /><strong>$sitetxt{eshop_email} : </strong>$order{billing_email}
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdcentercontent" valign="top">
              <span style="color:$emails_config{color_content};font-size:20px;line-height:27px;"><strong>$sitetxt{eshop_mailing_order_infos_title}</strong></span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdlcentercontent" valign="top">
              <span>$client_number <strong>$sitetxt{eshop_invoice2_facture_numcommande} : </strong>$order{id}<br />
			  <strong>$sitetxt{eshop_fac_2} : </strong>$order{order_finish_moment}<br />
			  <strong>$sitetxt{eshop_payment_method2} : </strong>$payment_label</span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdcentercontent" valign="top">

              $order_products
            
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdcentercontent" valign="top">
              <span><strong>$sitetxt{eshop_mailing_order_comment_title}</strong><br />$order{commentaire}</span>
              $retour_link
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
        </table>
            
            </td>
            <td width="45" align="center" class="td45"></td>
          </tr>
        </table>

        $footer
HTML

      $content = replace_balises({content=>$content, emails_config=>\%emails_config, order=>\%order, eshop_setup=>\%eshop_setup});
      my $subject = replace_balises({content=>$emails_config{facture_subject_textid}, emails_config=>\%emails_config, order=>\%order, eshop_setup=>\%eshop_setup});

      # Si ce n'est pas pour généré la facture sur le site, on envoit le mail
      if($is_facture ne "y")
      {

        my $id_member = members::get_id_member();
        my %member = read_table($dbh,"migcms_members",$id_member);
        if($member{member_type} eq 'Commande directe' && $config{commande_directe_no_email} eq 'y')
        {
        }
        elsif($order{email_billing_sent} eq "n")
        {
            send_mail($eshop_setup{eshop_email},$order{billing_email},$subject, $content, 'html');
            send_mail($eshop_setup{eshop_email},'dev@bugiweb.com','COPIE BUGIWEB '.$subject, $content, 'html');

            if($emails_config{facture_send_copy} eq "y")
            {
              send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email},$subject, $content, 'html');
              # Envoies des copies du mails
              if($eshop_setup{eshop_email_copies} ne "")
              {
                  send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email_copies},$subject,$content,"html");        
              }
            }

            my $stmt = "UPDATE eshop_orders SET email_billing_sent = 'y' WHERE id = $order{id}";
            execstmt($dbh,$stmt);

        }
        else
        {
        }
      }
      else
      {
        return $content;
      }
    }
  }
  else
  {

  }
}


################################################################
################## eshop_mailing_update_status #################
################################################################
sub eshop_mailing_update_status 
{
  my %order = %{$_[0]};
  my $payment_status = $_[1];
  my $delivery_status = $_[2];

  if($order{id} > 0)
  {
    # Récupération de la config de la boutique
    my %eshop_setup = %{get_setup()};
    # Récupération de la config des emails
    my %eshop_emails_setup = %{get_eshop_emails_setup()};

    # Traduction des données reçues
    my $lg = $order{order_lg};
    if($lg <= 0)
    {
      $lg = 1;
    }

    # Création d'un nouveau hash sitetxt pour avoir la langue de la commande lorsqu'on appelle le hash
    %sitetxt = %{get_eshop_txt($lg)};

    %emails_config = %{get_eshop_emails_config_trad(\%eshop_emails_setup, $lg, "_textid")};    

    # Récupération de l'entete de l'email
    my $header = get_eshop_emails_header("$sitetxt{eshop_suivi_commande} $order{id}", \%emails_config, \%eshop_setup, $lg);
    # Récupération du footer
    my $footer = get_eshop_emails_footer(\%emails_config, \%eshop_setup, $lg);

    # Récupération de l'image du logo
    # Récupération de l'image du logo
      my %logo = sql_line({dbh=>$dbh, table=>"migcms_linked_files", where=>"token = '$emails_config{id_pic}'"});
    	my %logo = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='eshop_emails_setup' AND token='$emails_config{id}' AND table_field='id_pic' ",limit=>"1",ordby=>"ordby"});

     	my $logo_path = $logo{file_dir};
     	$logo_path =~ s/\.\.\///g;
     	$logo_path = $config{fullurl}."/".$logo_path."/".$logo{name_medium};

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year+=1900;
    $mon++;
         
    my $date = "$mday/$mon/$year";
    my $heure = "$hour h $min";
    my $ps = $payment_status{$order{payment_status}};
    my $ds = $delivery_status{$order{delivery_status}};

    my $table_suivi = '';
    if(trim($order{tracking_num}) ne '')
    {
      $table_suivi = <<"EOH";
      <tr>
        <td width="230">
            <font size="2">
            <b>
                $sitetxt{'eshop_fac_tracking_num'}
            </b>
            </font>
        </td>
        <td width="400">
             $order{tracking_num}
        </td>
      </tr>
EOH
    }

    my %delivery = select_table($dbh,"eshop_deliveries","","name='$order{delivery}'");
    my ($delivery,$dum) = get_textcontent($dbh,$delivery{id_textid_name});
    my %payment = select_table($dbh,"eshop_payments","","name='$order{payment}'");
    my ($payment,$dum) = get_textcontent($dbh,$payment{id_textid_name});

    my $logo = "<a href='$config{fullurl}' target='_blank'><img src='$logo_path' width='$logo{width_medium}' height='$logo{height_medium}' alt='$balises{company}' /></a>";
    my %site_setup = %{setup::get_site_setup()};
	  if($site_setup{use_site_email_template} eq "y")
	  {
	  	$logo = "";
	  }

    my $content= <<"HTML";
          
        $header      
            
        <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
          <tr>
            <td width="45" align="center" class="td45"></td>
            <td width="710" align="left" class="td710">

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdleftcontent" valign="top">
              $logo
            </td>
            <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
            <td align="right" class="tdrightcontent" valign="middle">&nbsp;</td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td align="left" class="tdrightcontent" valign="top">
              <span style="color:$emails_config{color_content_second};font-size:30px;line-height:45px;" class="maintitle">$sitetxt{eshop_suivi_commande} $order{id}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top">&nbsp;</td>
          </tr>
        </table>
            
        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdrightcontent" valign="top" width="355">
              <span>Bonjour $order{billing_firstname}  $order{billing_lastname},
            <br /><br />
            Nous vous remercions pour votre commande numéro $order{id} sur $setup{eshop_name} et avons le plaisir de vous informer que son statut a été mis à jour le $date à $heure:
            <br />
            <br /></span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

          <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">         
            <tr>
              <td width="230">
                  <font size="2">
                  <b>
                      Livraison
                  </b>
                  </font>
              </td>
              <td width="400">
                   $delivery
              </td>
            </tr>
            <tr>
              <td width="230">
                  <font size="2">
                  <b>
                      Statut de votre livraison
                  </b>
                  </font>
              </td>
              <td width="400">
                   $delivery_status
              </td>
            </tr>
            <tr>
              <td width="230">
                  <font size="2">
                  <b>
                      Paiement
                  </b>
                  </font>
              </td>
              <td width="400">
                   $payment
              </td>
            </tr>
            <tr>
              <td width="230">
                  <font size="2">
                  <b>
                      Statut de votre paiement
                  </b>
                  </font>
              </td>
              <td width="400">
                   $payment_status
              </td>
            </tr>
            
            $table_suivi
            
            </table>

       
        
        
            </td>
            <td width="45" align="center" class="td45"></td>
          </tr>
        </table>

        $footer
HTML
    
    $content = replace_balises({content=>$content, emails_config=>\%emails_config, order=>\%order, eshop_setup=>\%eshop_setup});

    send_mail($eshop_setup{eshop_email},$order{billing_email},"$sitetxt{eshop_suivi_commande} $order{id}", $content, 'html');
    send_mail($eshop_setup{eshop_email},'dev@bugiweb.com',"COPIE BUGIWEB $sitetxt{eshop_suivi_commande} $order{id}", $content, 'html');
	send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email},"$sitetxt{eshop_suivi_commande} $order{id}", $content, 'html');
    # Envoies des copies du mails
    if($eshop_setup{eshop_email_copies} ne "")
    {
        send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email_copies},"$sitetxt{eshop_suivi_commande} $order{id}",$content,"html");        
    }


  }

}

#################################################################
################## eshop_mailing_order_finished #################
#################################################################
sub eshop_mailing_order_finished
{
  my %order = %{$_[0]};

  if($order{id} > 0)
  {
    # Récupération de la config de la boutique
    my %eshop_setup = %{get_setup()};
    # Récupération de la config des emails
    my %eshop_emails_setup = %{get_eshop_emails_setup()};

    if($eshop_emails_setup{disabled_emailing} ne "y" && $eshop_emails_setup{disabled_merci} ne "y")
    {
      # Traduction des données reçues
      my $lg = $order{order_lg};
      if($lg <= 0)
      {
        $lg = 1;
      }

      # Création d'un nouveau hash sitetxt pour avoir la langue de la commande lorsqu'on appelle le hash
      %sitetxt = %{get_eshop_txt($lg)};

      %emails_config = %{get_eshop_emails_config_trad(\%eshop_emails_setup, $lg, "_textid")};
      

      # Récupération de l'entete de l'email
      my $header = get_eshop_emails_header($emails_config{merci_subject_textid}, \%emails_config, \%eshop_setup, $lg);
      # Récupération du footer
      my $footer = get_eshop_emails_footer(\%emails_config, \%eshop_setup, $lg);

      # Hard codage du contenu du mail
      $emails_config{merci_content_textid} =~ s/<p>//g;
      $emails_config{merci_content_textid} =~ s/<\/p>//g;


      # Hard codage du contenu du mail
      $emails_config{merci_title_product_textid} =~ s/<p>//g;
      $emails_config{merci_title_product_textid} =~ s/<\/p>//g;

      # Génération d'un coupon si l'option n'est pas désactivée
      if($emails_config{merci_disabled_coupon} ne "y")
      {
        # Génération d'un code promo
        my $code_promo = uc(create_token(10));

        my %new_coupon = (
          nom                     => "Coupon de remerciement pour la commande n°$order{id}",
          coupons                 => $code_promo,
          begin_date              => $emails_config{merci_coupon_begin},
          end_date                => $emails_config{merci_coupon_end},
          discount_type_on_total  => $emails_config{merci_coupon_type},
          discount_value_on_total => $emails_config{merci_coupon_value},
          nb_uses_email           => 1,
          nb_uses_total           => 1,
          visible                 => 'y',

        );

        inserth_db($dbh, "eshop_coupons", \%new_coupon);

        # Remplacement de la balise qui indique la valeur de la remise
        my $type_remise = "€";
        if($emails_config{merci_coupon_type} eq "perc")
        {
          $type_remise = "%";
        }
        $emails_config{merci_content_textid} =~ s/{REMISE}/<strong>$emails_config{merci_coupon_value}$type_remise<\/strong>/g;

        my $validity;
        if($emails_config{merci_coupon_end} ne "0000-00-00")
        {
          my $validity_date = sql_to_human_date($emails_config{merci_coupon_end});
          $validity = $sitetxt{eshop_mailing_coupon_validity} . " " . $validity_date;
        }

        # Remplacement de la balise qui indique le code promo
        $emails_config{merci_content_textid} =~ s/{CODE_PROMO}/<strong style="color:$emails_config{color_content_second};">$sitetxt{eshop_mailing_code_promo_title}: <\/strong><strong>$code_promo<\/strong><br\/>$validity/g;

      }


      # Récupération de l'image du logo
      # Récupération de l'image du logo
      my %logo = sql_line({dbh=>$dbh, table=>"migcms_linked_files", where=>"token = '$emails_config{id_pic}'"});
    	my %logo = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='eshop_emails_setup' AND token='$emails_config{id}' AND table_field='id_pic' ",limit=>"1",ordby=>"ordby"});

     	my $logo_path = $logo{file_dir};
     	$logo_path =~ s/\.\.\///g;
     	$logo_path = $config{fullurl}."/".$logo_path."/".$logo{name_medium};

     	my $logo = "<a href='$config{fullurl}' target='_blank'><img src='$logo_path' width='$logo{width_medium}' height='$logo{height_medium}' alt='$balises{company}' /></a>";
      my %site_setup = %{setup::get_site_setup()};
		  if($site_setup{use_site_email_template} eq "y")
		  {
		  	$logo = "";
		  }

      my $content = <<"HTML";

        $header

        <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
          <tr>
            <td width="45" align="center" class="td45"></td>
            <td width="710" align="left" class="td710">

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdleftcontent" valign="top">
              $logo
            </td>
            <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
            <td align="right" class="tdrightcontent" valign="middle">
              <a href="$emails_config{merci_title_product_link_textid}" target="_blank" style="text-decoration:none;"><strong>$emails_config{merci_title_product_textid}</strong></a>
            </td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td align="left" class="tdcentercontent" valign="top" colspan="3">
              <span style="color:$emails_config{color_content_second};font-size:30px;line-height:45px;" class="maintitle">$emails_config{merci_title_textid}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdleftcontent" valign="top">
              <span>
        $emails_config{merci_content_textid}
              </span>
            </td>
            <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
            <td align="left" class="tdrightcontent" valign="top">
              <img src="$config{baseurl}/pics/$image{pic_name_mini}" width="$image{pic_width_mini}" height="$image{pic_height_mini}" alt="$eshop_setup{eshop_name}" />
            </td>
          </tr>
        </table>

            </td>
            <td width="45" align="center" class="td45"></td>
          </tr>
        </table>

        <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
          <tr>
            <td width="800" height="32" align="left" colspan="3">&nbsp;</td>
          </tr>
        </table>

        $footer
HTML

      $content = replace_balises({content=>$content, emails_config=>\%emails_config, order=>\%order, eshop_setup=>\%eshop_setup});

      send_mail($eshop_setup{eshop_email},$order{billing_email},$emails_config{merci_subject_textid}, $content, 'html');
      send_mail($eshop_setup{eshop_email},'dev@bugiweb.com','COPIE BUGIWEB '.$emails_config{merci_subject_textid}, $content, 'html');

      if($emails_config{merci_send_copy} eq "y")
      {
        send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email},$emails_config{merci_subject_textid}, $content, 'html');
        # Envoies des copies du mails
        if($eshop_setup{eshop_email_copies} ne "")
        {
            send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email_copies},$emails_config{merci_subject_textid},$content,"html");        
        }
      }

      my $stmt = "UPDATE eshop_orders SET email_finished_sent = 'y' WHERE id = $order{id}";

      execstmt($dbh,$stmt);
    }
  }
  else
  {

  }
}


#################################################################
################## eshop_mailing_relance_panier #################
#################################################################
sub eshop_mailing_relance_panier
{
  my %order = %{$_[0]};

    # %order = read_table($dbh, "eshop_orders", 21);


  if($order{id} > 0)
  {
    # Récupération de la config de la boutique
    my %eshop_setup = %{get_setup()};
    # Récupération de la config des emails
    my %eshop_emails_setup = %{get_eshop_emails_setup()};

    if($eshop_emails_setup{disabled_emailing} ne "y" && $eshop_emails_setup{disabled_relance_panier} ne "y")
    {
      # Traduction des données reçues
      my $lg = $order{order_lg};
      if($lg <= 0)
      {
        $lg = 1;
      }

      # Création d'un nouveau hash sitetxt pour avoir la langue de la commande lorsqu'on appelle le hash
      %sitetxt = %{get_eshop_txt($lg)};

      %emails_config = %{get_eshop_emails_config_trad(\%eshop_emails_setup, $lg, "_textid")};


      # Récupération de l'entete de l'email
      my $header = get_eshop_emails_header($emails_config{relance_panier_subject_textid}, \%emails_config, \%eshop_setup, $lg);
      # Récupération du footer
      my $footer = get_eshop_emails_footer(\%emails_config, \%eshop_setup, $lg);

      # Hard codage du contenu du mail
      $emails_config{relance_panier_content_textid} =~ s/<p>//g;
      $emails_config{relance_panier_content_textid} =~ s/<\/p>//g;


      # Création du lien vers le panier    
      my $url_panier = "$config{baseurl}/cgi-bin/eshop.pl?sw=load_order&token=$order{token}";

      my $lien = <<"HTML";
        </span>
            <table border="0" cellpadding="0" cellspacing="0" align="left" bgcolor="$emails_config{color_button_bg}">
              <tr>
                  <td width="25">&nbsp;</td>
                  <td height="50"><a href="$url_panier" style="color:$emails_config{color_button};text-decoration:none;">$sitetxt{eshop_mailing_lnk_cart}</a></td>
                  <td width="25">&nbsp;</td>
              </tr>
            </table>
        <br /><br />
        <span>
HTML
      $emails_config{relance_panier_content_textid} =~ s/{LIEN_VERS_LE_PANIER}/$lien/g;

       # Récupération de l'image du logo
      # Récupération de l'image du logo
      my %logo = sql_line({dbh=>$dbh, table=>"migcms_linked_files", where=>"token = '$emails_config{id_pic}'"});
    	my %logo = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='eshop_emails_setup' AND token='$emails_config{id}' AND table_field='id_pic' ",limit=>"1",ordby=>"ordby"});

     	my $logo_path = $logo{file_dir};
     	$logo_path =~ s/\.\.\///g;
     	$logo_path = $config{fullurl}."/".$logo_path."/".$logo{name_medium};

      # Récupération des produits de la commande
      my $order_products = get_eshop_order_products(\%order,"y","n");

      my $logo = "<a href='$config{fullurl}' target='_blank'><img src='$logo_path' width='$logo{width_medium}' height='$logo{height_medium}' alt='$balises{company}' /></a>";
      my %site_setup = %{setup::get_site_setup()};
		  if($site_setup{use_site_email_template} eq "y")
		  {
		  	$logo = "";
		  }

      my $content = <<"HTML";

        $header

        <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
            <tr>
                <td width="45" align="center" class="td45"></td>
                <td width="710" align="left" class="td710">

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
            <tr>
                <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
            </tr>
            <tr>
                <td align="left" class="tdleftcontent" valign="top">
                  $logo
                </td>
                <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
                <td align="right" class="tdrightcontent" valign="middle">&nbsp;</td>
            </tr>
            <tr>
                <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
            </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
            <tr>
                <td align="left" class="tdcentercontent" valign="top">
                    <span style="color:$emails_config{color_content_second};font-size:30px;line-height:45px;" class="maintitle">$emails_config{relance_panier_title_textid}</span><br /><br />
                    <span style="color:$emails_config{color_content};font-size:20px;line-height:27px;"><strong>$emails_config{relance_panier_subtitle_textid}</strong></span><br /><br />
                    <span>$emails_config{relance_panier_content_textid}</span>
                </td>
            </tr>
            <tr>
                <td class="td40" height="40" valign="top">&nbsp;</td>
            </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
            <tr>
                <td align="left" class="tdcentercontent" valign="top">

                    $order_products
                
                </td>
            </tr>
            <tr>
                <td class="td40" valign="top">&nbsp;</td>
            </tr>
        </table>
                
                </td>
                <td width="45" align="center" class="td45"></td>
            </tr>
        </table>

        $footer
HTML

      $content = replace_balises({content=>$content, emails_config=>\%emails_config, order=>\%order, eshop_setup=>\%eshop_setup});

      send_mail($eshop_setup{eshop_email},$order{billing_email},$emails_config{relance_panier_subject_textid}, $content, 'html');
      send_mail($eshop_setup{eshop_email},'dev@bugiweb.com','COPIE BUGIWEB '.$emails_config{relance_panier_subject_textid}, $content, 'html');

      if($emails_config{relance_panier_send_copy} eq "y")
      {
        send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email},$emails_config{relance_panier_subject_textid}, $content, 'html');
        # Envoies des copies du mails
        if($eshop_setup{eshop_email_copies} ne "")
        {
            send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email_copies},$emails_config{relance_panier_subject_textid},$content,"html");        
        }
      }
    }
  }
  else
  {

  }
}

###################################################################
################## eshop_mailing_relance_paiement #################
###################################################################
sub eshop_mailing_relance_paiement
{
  my %order = %{$_[0]};

  if($order{id} > 0)
  {
    # Récupération de la config de la boutique
    my %eshop_setup = %{get_setup()};
    # Récupération de la config des emails
    my %eshop_emails_setup = %{get_eshop_emails_setup()};

    if($eshop_emails_setup{disabled_emailing} ne "y" && $eshop_emails_setup{disabled_relance_paiement} ne "y")
    {
      # Traduction des données reçues
      my $lg = $order{order_lg};
      if($lg <= 0)
      {
        $lg = 1;
      }

      # Création d'un nouveau hash sitetxt pour avoir la langue de la commande lorsqu'on appelle le hash
      %sitetxt = %{get_eshop_txt($lg)};

      %emails_config = %{get_eshop_emails_config_trad(\%eshop_emails_setup, $lg, "_textid")};

      # Préfixe pour récupérer les bons champs de livraison
      my $prefixe = "delivery_";
      my %delivery = sql_line({dbh=>$dbh, table=>"eshop_deliveries", where=>"name = '$order{delivery}' AND name != ''"});
      if($delivery{identity_tier} eq "y")
      {
        $prefixe = "tier_";
      }


      # Récupération de l'entete de l'email
      my $header = get_eshop_emails_header($emails_config{relance_paiement_subject_textid}, \%emails_config, \%eshop_setup, $lg);
      # Récupération du footer
      my $footer = get_eshop_emails_footer(\%emails_config, \%eshop_setup, $lg);

      # Hard codage du contenu du mail
      $emails_config{relance_paiement_content_textid} =~ s/<p>//g;
      $emails_config{relance_paiement_content_textid} =~ s/<\/p>//g;
      

      # Récupération de l'image du logo
      my %logo = sql_line({dbh=>$dbh, table=>"migcms_linked_files", where=>"token = '$emails_config{id_pic}'"});
    	my %logo = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='eshop_emails_setup' AND token='$emails_config{id}' AND table_field='id_pic' ",limit=>"1",ordby=>"ordby"});

     	my $logo_path = $logo{file_dir};
     	$logo_path =~ s/\.\.\///g;
     	$logo_path = $config{fullurl}."/".$logo_path."/".$logo{name_medium};

      # Nom du pays de livraison
     my $country_name = get_country_name($order{$prefixe."country"}, $lg);

      # Récupération des produits de la commande
      my $order_products = get_eshop_order_products(\%order,"y","n");

      my $delivery_firstname = $order{$prefixe."firstname"};
      my $delivery_lastname  = $order{$prefixe."lastname"};
      my $delivery_street    = $order{$prefixe."street"};
      my $delivery_number    = $order{$prefixe."number"};
      my $delivery_box       = $order{$prefixe."box"};
      my $delivery_zip       = $order{$prefixe."zip"};
      my $delivery_city      = $order{$prefixe."city"};

      my $logo = "<a href='$config{fullurl}' target='_blank'><img src='$logo_path' width='$logo{width_medium}' height='$logo{height_medium}' alt='$balises{company}' /></a>";
      my %site_setup = %{setup::get_site_setup()};
		  if($site_setup{use_site_email_template} eq "y")
		  {
		  	$logo = "";
		  }

      my $content = <<"HTML";

        $header

        <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
          <tr>
            <td width="45" align="center" class="td45"></td>
            <td width="710" align="left" class="td710">

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdleftcontent" valign="top">
              $logo
            </td>
            <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
            <td align="right" class="tdrightcontent" valign="middle">
              $sitetxt{eshop_mailing_order_number}<strong>$order{id}</strong>
            </td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td align="left" class="tdcentercontent" valign="top">
              <span style="color:$emails_config{color_content_second};font-size:30px;line-height:45px;" class="maintitle">$emails_config{relance_paiement_title_textid}</span><br /><br />
              <span>$emails_config{relance_paiement_content_textid}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" height="40" valign="top">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdcentercontent" valign="top" colspan="3">
              <span style="color:$emails_config{color_content};font-size:20px;line-height:27px;"><strong>$sitetxt{eshop_virement_instructions_1} :</strong></span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdleftcontent" valign="top">
              <span><strong>$eshop_setup{eshop_name}</strong><br />$eshop_setup{eshop_street} $eshop_setup{eshop_number} $eshop_setup{eshop_box}<br />$eshop_setup{eshop_zip_city}<br />$eshop_setup{eshop_country}</span>
            </td>
            <td width="40" align="center" class="td40" valign="top">&nbsp;</td>
            <td align="left" class="tdrightcontent" valign="top">
              <span><strong>$sitetxt{eshop_mailing_montant_to_pay} : </strong>$total_a_payer<br /><strong>$sitetxt{eshop_banque} : </strong>$eshop_setup{eshop_banque}<br /><strong>$sitetxt{eshop_iban} : </strong>$eshop_setup{eshop_iban}<br /><strong>$sitetxt{eshop_bic} : </strong>$eshop_setup{eshop_bic}<br /><strong>$sitetxt{eshop_communication} : </strong>$setup{eshop_name} $order{id}</span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>
            
        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
          <tr>
          <td align="left" class="tdcentercontent" valign="top">
            <span style="color:$emails_config{color_content};font-size:20px;line-height:27px;"><strong>$sitetxt{eshop_mailing_order_will_be_send_to}</strong></span>
          </td>
        </tr>
        <tr>
          <td class="td40" valign="top">&nbsp;</td>
        </tr>
        <tr>
          <td align="left" class="tdcentercontent" valign="top">
						<span><strong>$sitetxt{eshop_invoice2_header_adresse_livraison} :</strong><br />$delivery_street $delivery_number<br />$delivery_zip $delivery_city<br />$country_name</span>
					</td>
        </tr>
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" height="1" class="tdcentercontent" valign="top" bgcolor="#d4d4d4" width="710"></td>
          </tr>
          <tr>
            <td class="td40" valign="top" colspan="3">&nbsp;</td>
          </tr>
        </table>

        <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdcentercontent" valign="top">
              <span style="color:$emails_config{color_content};font-size:20px;line-height:27px;"><strong>$sitetxt{eshop_mailing_order_infos_title} :</strong></span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdlcentercontent" valign="top">
              <span>$sitetxt{eshop_mailing_order_infos_txt} <strong>$order{id}</strong>.</span>
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
          <tr>
            <td align="left" class="tdcentercontent" valign="top">
              $order_products          
            </td>
          </tr>
          <tr>
            <td class="td40" valign="top">&nbsp;</td>
          </tr>
        </table>
            
            </td>
            <td width="45" align="center" class="td45"></td>
          </tr>
        </table>


        $footer
HTML

      $content = replace_balises({content=>$content, emails_config=>\%emails_config, order=>\%order, eshop_setup=>\%eshop_setup});
      $subject = replace_balises({content=>$emails_config{relance_paiement_subject_textid}, emails_config=>\%emails_config, order=>\%order, eshop_setup=>\%eshop_setup});
    
      send_mail($eshop_setup{eshop_email},$order{billing_email},$subject, $content, 'html');
      send_mail($eshop_setup{eshop_email},'dev@bugiweb.com','COPIE BUGIWEB '.$subject, $content, 'html');

      if($emails_config{relance_paiement_send_copy} eq "y")
      {
        send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email},$emails_config{relance_paiement_subject_textid}, $content, 'html');
        # Envoies des copies du mails
        if($eshop_setup{eshop_email_copies} ne "")
        {
            send_mail($eshop_setup{eshop_email},$eshop_setup{eshop_email_copies},$emails_config{relance_paiement_subject_textid},$content,"html");        
        }
      }
      
    }
  }
  else
  {

  }
}



###################################################
################## replace_balises ################
###################################################
# Remplace les balises générales du contenu du
# mail   
#                      
# Return: Le contenu avec les balises remplacées
###################################################
sub replace_balises
{
  my %d = %{$_[0]};  

  my %emails_balises = (
    SIGNATURE_EMAIL        => $d{emails_config}{signature_textid},
    CONTACT_SERVICE_CLIENT => $d{emails_config}{contact_email_textid},
    NOM_DU_CLIENT          => "<strong>".$d{order}{billing_firstname}." ".$d{order}{billing_lastname}."</strong>",
    NUMERO_DE_COMMANDE     => $d{order}{id},
    URL_DU_SITE            => "<a href='$balises{web}'>$balises{web}</a>",
    NOM_DE_LA_BOUTIQUE     => "<a href='$balises{web}'>$balises{company}</a>",
    EMAIL_SERVICE_CLIENT   => $d{eshop_setup}{eshop_email},
  );

  foreach $balise (keys %emails_balises)
  {

    $d{content} =~ s/\{$balise\}/$emails_balises{$balise}/g;
  }

  return $d{content};
}



############################################################
################## get_eshop_order_products ################
############################################################
# Params: 1 => %order
#         2 => afficher le total ? ('y' ou 'n')
#         3 => afficher le sku ? ('y' ou 'n')
#              
# Return: Un tableau html avec les produits commandés
############################################################
sub get_eshop_order_products
{
  my %order = %{$_[0]};
  my $display_total = $_[1];
  my $display_sku = $_[2];

  my @order_details = sql_lines({
    dbh=>$dbh,
    table=>"eshop_order_details",
    where=>"id_eshop_order = '$order{id}'",
  });

  my %member = sql_line({debug=>0,table=>"migcms_members",select=>"id_tarif",where=>"id='$order{id_member}'"});

  my $id_tarif = $member{id_tarif};
  if($id_tarif == 0)
  {
    # Si le membre n'a pas de tarif attribué, on va rechercher celui par défaut
    my %tarif_default = sql_line({dbh=>$dbh,select=>"id_default_tarif",table=>"data_setup"});
    $id_tarif = $tarif_default{id_default_tarif};
  }
  
  my %tarif = read_table($dbh,'eshop_tarifs',$id_tarif);
  
  my $total_articles_htva;
  my $total_remise_tvac;
  my $total_livraison_htva;
  my $total_htva;
  my $total_tva;
  $total_a_payer;

  my $affichage_articles;
  if($order{is_intracom} && $order{do_intracom} eq 'y')
  {
    # AFFICHAGE HTVA ET PAIEMENT HTVA
    $affichage_articles = "htva";
    $total_articles_htva  = display_price($order{total_htva});
    $total_remise_tvac    = display_price($order{total_discount_htva} + $order{total_coupons_htva});
	$total_coupon_tvac    = display_price($order{total_coupons_htva} + $order{total_coupons_tva});
    $total_livraison_htva = display_price($order{total_delivery_htva});
    $total_htva           = display_price($order{total_discounted_htva});
    $total_tva            = "-";
    $total_a_payer        = display_price($order{total_discounted_htva});
  }
  elsif(($tarif{is_tvac} ne 'y' || $config{mailing_products_price_display_htva} eq "y") && $tarif{pay_tvac} eq 'y')
  {
    # AFFICHAGE HTVA ET PAIEMENT TVAC
    $affichage_articles = "htva";
    $total_articles_htva  = display_price($order{total_htva});
    $total_remise_tvac    = display_price($order{total_discount_htva} + $order{total_coupons_htva});
	$total_coupon_tvac    = display_price($order{total_coupons_htva} + $order{total_coupons_tva});
    $total_livraison_htva = display_price($order{total_delivery_htva});
    $total_htva           = display_price($order{total_discounted_htva});
    $total_tva            = display_price($order{total_discounted_tva});
    $total_a_payer        = display_price($order{total_discounted_tvac});
  }
  elsif($tarif{is_tvac} ne 'y' && $tarif{pay_tvac} ne 'y')
  {
    # AFFICHAGE HTVA ET PAIEMENT HTVA
    $affichage_articles = "htva";
    $total_articles_htva  = display_price($order{total_htva});
    $total_remise_tvac    = display_price($order{total_discount_htva} + $order{total_coupons_htva});
	$total_coupon_tvac    = display_price($order{total_coupons_htva} + $order{total_coupons_tva});
    $total_livraison_htva = display_price($order{total_delivery_htva});
    $total_htva           = display_price($order{total_discounted_htva});
    $total_tva            = "-";
    $total_a_payer        = display_price($order{total_discounted_htva});
  }
  else
  {
    # AFFICHAGE TVAC ET PAIEMENT TVAC 
    $affichage_articles = "tvac"; 
    $total_articles_htva  = display_price($order{total_htva});
    $total_remise_tvac    = display_price($order{total_discount_htva} + $order{total_coupons_htvac});
	$total_coupon_tvac    = display_price($order{total_coupons_htva} + $order{total_coupons_tva});
    $total_livraison_htva = display_price($order{total_delivery_htva});
    $total_htva           = display_price($order{total_discounted_htva});
    $total_tva            = display_price($order{total_discounted_tva});
    $total_a_payer        = display_price($order{total_discounted_tvac});
          
  }

  my $precision = $sitetxt{eshop_tvac};
  if($affichage_articles eq "htva")
  {
    $precision = $sitetxt{eshop_htva};
  }

  my $comment_title;
  my $th_article_width = "80";
  if($config{allow_cart_comments} eq "y")
  {
    $th_article_width = "50";
    $comment_title = <<"HTML";
        <th width="30" class="cart-comment" style="background:$emails_config{color_bandeau_bg};color:$emails_config{color_bandeau_price};font-weight:bold;">$sitetxt{eshop_comments_title}</th>
HTML
  }

  my $content = <<"HTML";
    <table width="710" border="0" cellpadding="0" cellspacing="0" align="center" class="table100pc">
      <tr>
        <th width="5" height="38" style="background:$emails_config{color_bandeau_bg};color:$emails_config{color_bandeau_price};font-weight:bold;">&nbsp;</th>
        <th width="80" style="background:$emails_config{color_bandeau_bg};color:$emails_config{color_bandeau_price};font-weight:bold;">$sitetxt{eshop_mailing_quantity_title}</th>
        
        <th style="background:$emails_config{color_bandeau_bg};color:$emails_config{color_bandeau_price};font-weight:bold;">$sitetxt{eshop_invoice2_header_articles}</th>
        $comment_title
        <th width="80" style="background:$emails_config{color_bandeau_bg};color:$emails_config{color_bandeau_price};font-weight:bold;" class="hidden-sm">$sitetxt{eshop_fac_9} $precision</th>
        <th width="5" height="38" style="background:$emails_config{color_bandeau_bg};color:$emails_config{color_bandeau_price};font-weight:bold;">&nbsp;</th>
      </tr>
HTML

  foreach $detail (@order_details)
  {
    %detail = %{$detail};

    my $sku;
    if($display_sku eq "y")
    {
      $sku = <<"HTML";
        <br /><small><i>SKU : $detail{detail_reference}</i></small>
HTML
    }

    # Récupération des totaux TVAC OU HTVA en fonction du type d'affichage
    my $article_price = display_price($detail{detail_total_tvac});
    my $article_price_discounted = display_price($detail{detail_total_discounted_tvac});
    if($affichage_articles eq "htva")
    {
      $article_price = display_price($detail{detail_total_htva});
      $article_price_discounted = display_price($detail{detail_total_discounted_htva});
    }

     # Affichage de la ligne normale ou avec remise s'il y en a eu une
    my $table_line_with_price = <<"HTML";
    <td style="border-bottom:1px solid #b2b2b2;" class="hidden-sm" align="right"><span>$article_price</span></td>
HTML
		if($detail{detail_total_discounted_tvac} < $detail{detail_total_tvac})
		{
			$table_line_with_price = <<"HTML";
    		<td style="border-bottom:1px solid #b2b2b2;" class="hidden-sm" align="right"><span style="text-decoration: line-through;">$article_price</span><br/><span>$article_price_discounted</span></td>
HTML
		}

    my $comment_content;
    if($config{allow_cart_comments} eq "y")
    {
      $comment_content = <<"HTML";
          <td style="border-bottom:1px solid #b2b2b2;">$detail{detail_comment}</td>
HTML
    }

    $content .= <<"HTML";
      <tr>
        <td style="border-bottom:1px solid #b2b2b2;" height="45">&nbsp;</td>
        <td style="border-bottom:1px solid #b2b2b2;">$detail{detail_qty}</td>
        <td style="border-bottom:1px solid #b2b2b2;">$detail{detail_label} $sku</td>
        $comment_content
        $table_line_with_price
        <td style="border-bottom:1px solid #b2b2b2;">&nbsp;</td>
      </tr>
HTML

  }

  if($display_total eq "y")
  {

    $content .= <<"HTML";
   	 <tr>
   	 	<td colspan="5" height="60">&nbsp;</td>
   	 </tr>
      <tr>
        <td height="20">&nbsp;</td>
        <td>&nbsp;</td>
        <td align="right"><strong>$sitetxt{eshop_recapbox_1} $sitetxt{'eshop_htva'} :&nbsp;</strong></td>
        <td align="right" style="white-space:nowrap;">$total_articles_htva</td>
        <td>&nbsp;</td>
      </tr>
HTML
	if($total_remise_tvac ne '0.00 €') {
    $content .= <<"HTML";
      <tr>
        <td height="20">&nbsp;</td>
        <td>&nbsp;</td>
        <td align="right"><strong>$sitetxt{eshop_recapbox_4} :&nbsp;</strong></td>
        <td align="right" style="white-space:nowrap;">-$total_remise_tvac</td>
        <td>&nbsp;</td>
      </tr>
HTML
	}
	if($total_coupon_tvac ne '0.00 €') {
    $content .= <<"HTML";
	  <tr>
        <td height="20">&nbsp;</td>
        <td>&nbsp;</td>
        <td align="right"><strong>$sitetxt{eshop_recapbox_5} :&nbsp;</strong></td>
        <td align="right" style="white-space:nowrap;">-$total_coupon_tvac</td>
        <td>&nbsp;</td>
      </tr>
HTML
	}
    $content .= <<"HTML";
      <tr>
        <td height="20">&nbsp;</td>
        <td>&nbsp;</td>
        <td align="right"><strong>$sitetxt{eshop_recapbox_2} :&nbsp;</strong></td>
        <td align="right" style="white-space:nowrap;">$total_livraison_htva</td>
        <td>&nbsp;</td>
      </tr>
      <tr>
        <td height="20">&nbsp;</td>
        <td>&nbsp;</td>
        <td align="right"><strong>$sitetxt{eshop_invoice2_totalhtva} :&nbsp;</strong></td>
        <td align="right" style="white-space:nowrap;">$total_htva</td>
        <td>&nbsp;</td>
      </tr>
      <tr>
        <td height="20">&nbsp;</td>
        <td>&nbsp;</td>
        <td align="right"><strong>$sitetxt{eshop_invoice2_tva} :&nbsp;</strong></td>
        <td align="right" style="white-space:nowrap;">$total_tva</td>
        <td>&nbsp;</td>
      </tr>

      <tr>
        <td style="border-top:1px solid #b2b2b2;" height="38">&nbsp;</td>
        <td style="border-top:1px solid #b2b2b2;">&nbsp;</td>
        <td style="border-top:1px solid #b2b2b2;" align="right"><strong>$sitetxt{eshop_tot_tvac} :&nbsp;</strong></td>
        <td align="right" style="border-top:1px solid #b2b2b2;white-space:nowrap;">$total_a_payer</td>
        <td style="border-top:1px solid #b2b2b2;">&nbsp;</td>
      </tr>
HTML
    
  }

  $content .= <<"HTML";
    </table>
HTML

  return $content
}


############################################################
################## get_eshop_emails_footer #################
############################################################
# Params: 1 => %order
#              
# Return: Le footer des mails de la boutique
############################################################
sub get_eshop_emails_footer
{
  %emails_config = %{$_[0]};
  my %eshop_setup = %{$_[1]};

  my $lg = $_[2] || "1";

  my %site_setup = %{setup::get_site_setup()};
  if($site_setup{use_site_email_template} eq "y")
  {
  	my $footer = setup::get_migcms_site_emails_footer({lg=>$lg});
  	return $footer;
  	exit;
  }

  my $footer = <<"HTML";
    <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
      <tr>
        <td width="800" height="32" align="left" colspan="3">&nbsp;</td>
      </tr>
    </table>

    <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800" bgcolor="$emails_config{color_bandeau_bg}">
      <tr>
        <td width="45" align="center" class="td45"></td>
        <td width="710" height="52" align="center" class="td710">
          <span style="color:$emails_config{color_bandeau};">$eshop_setup{eshop_name} - $eshop_setup{eshop_street}, $eshop_setup{eshop_zip_city} ($eshop_setup{eshop_country})</span>
        </td>
        <td width="45" align="center" class="td45"></td>
      </tr>
    </table>
          
          </td>
        </tr>
      </table>


      </body>
      </html>
HTML
}

############################################################
################## get_eshop_emails_header #################
############################################################
# Params: 1 => %order
#              
# Return: Le header des mails de la boutique
############################################################
sub get_eshop_emails_header
{
  my $title = $_[0];
  %emails_config = %{$_[1]};
  my %eshop_setup = %{$_[2]};
  my $charset = $_[3] || "iso-8859-1";
  my $lg = $_[4] || "1";

  my %site_setup = %{setup::get_site_setup()};
  if($site_setup{use_site_email_template} eq "y")
  {
  	my $header = setup::get_migcms_site_emails_header({title=>$title, lg=>$lg});
  	return $header;
  	exit;
  }



  my $social_links;
  if($emails_config{facebook_link_textid} ne "")
  {
    $social_links .= <<"HTML";
      &nbsp;<a href="$emails_config{facebook_link_textid}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$emails_config{color_bandeau};"><img src="$config{fullurl}/skin/newsletter/facebook.png" alt="Facebook" width="13" height="23" /></a>&nbsp;
HTML
  }
  if($emails_config{twitter_link_textid} ne "")
  {
    $social_links .= <<"HTML";
      &nbsp;<a href="$emails_config{twitter_link_textid}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$emails_config{color_bandeau};"><img src="$config{fullurl}/skin/newsletter/twitter.png" alt="Twitter" width="20" height="23" /></a>&nbsp;
HTML
  }
  if($emails_config{google_link_textid} ne "")
  {
    $social_links .= <<"HTML";
      &nbsp;<a href="$emails_config{google_link_textid}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$emails_config{color_bandeau};"><img src="$config{fullurl}/skin/newsletter/googleplus.png" alt="Google+" width="23" height="23" /></a>&nbsp;
HTML
  }

  my $entete;
  if($emails_config{header_1_textid} ne "" || $emails_config{header_2_textid} ne "" || $emails_config{header_3_textid} ne "" || $emails_config{header_4_textid} ne "" || $emails_config{header_5_textid} ne "")
  {
	  $entete = <<"HTML";
	  	<table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800 linkcategory" style="border-top:1px solid #e5e5e5;border-bottom:1px solid #e5e5e5;">
	      <tr>
	        <td width="45" align="center" class="td45"></td>
	        <td width="710" height="32" align="center" class="td710">
	          &nbsp;&nbsp;<a href="$emails_config{header_1_link_textid}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$emails_config{color_entete_links};">$emails_config{header_1_textid}</a>&nbsp;&nbsp;
	          &nbsp;&nbsp;<a href="$emails_config{header_2_link_textid}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$emails_config{color_entete_links};">$emails_config{header_2_textid}</a>&nbsp;&nbsp;
	          &nbsp;&nbsp;<a href="$emails_config{header_3_link_textid}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$emails_config{color_entete_links};">$emails_config{header_3_textid}</a>&nbsp;&nbsp;
	          &nbsp;&nbsp;<a href="$emails_config{header_4_link_textid}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$emails_config{color_entete_links};">$emails_config{header_4_textid}</a>&nbsp;&nbsp;
	          &nbsp;&nbsp;<a href="$emails_config{header_5_link_textid}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$emails_config{color_entete_links};">$emails_config{header_5_textid}</a>&nbsp;&nbsp;
	        </td>
	        <td width="45" align="center" class="td45"></td>
	      </tr>
	    </table>
HTML

  }



  my $header = <<"HTML";
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>$title</title>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="Content-Type" content="text/html; charset=$charset" />
    </head>
    <body bgcolor="#ffffff" style="font-family:arial,sans-serif;color:$emails_config{color_content};font-size:14px;line-height:20px;background:#e5e5e5;-webkit-text-size-adjust:none;">

    <style type="text/css">
    * {
    padding : 0px;
    margin : 0px;
    }

    body {
    font-family : arial,sans-serif;
    color : $emails_config{color_content};
    font-size : 14px;
    line-height : 20px;
    background : #e5e5e5;
    -webkit-text-size-adjust : none;
    }

    a {
    border : 0px;
    color : $emails_config{color_content_link};
    }

    a:hover {
    color : $emails_config{color_content_link};
    }

    img {
    border : 0px;
    }

    a img {
    border  :0px;
    }

    .td25pc {
    padding : 5px;
    }

    .td25pc img {
    max-width : 100%;
    height : auto;
    }

    \@media only screen and (max-width: 600px) { 

      *[class].table800, *[class].td800, *[class].img800, *[class].pub { width:100% !important; height:auto; }
      *[class].td45 { width:5% !important; }
      *[class].td710 { width:90% !important; }
      *[class].table710 { width:100% !important; height:auto; }
      *[class].tdleftcontent { width : 100% !important; display: table-header-group !important; }
      *[class].td40 { width : 100% !important; display: table-header-group !important; }
      *[class].tdrightcontent { width : 100% !important; display: table-header-group !important; }
      *[class].fancybox { width : 100%; height : auto; }
      *[class].table100pc { width:100% !important; height:auto; }
      *[class].td25pc { width : 100% !important; display: table-header-group !important; }
      *[class].menulink { display : block !important; }
      *[class].maintitle { font-size:25px !important; line-height:30px !important; margin:0px; }
      *[class].linkcategory { display : none !important; }
      *[class].hidden-sm  { display : none !important; }
    } 

    </style>

    <table width="100%" border="0" cellpadding="0" cellspacing="0"><tr><td align="center">
      <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800" bgcolor="white">
        <tr>
          <td width="800" align="center" class="td800">
          
            <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800" bgcolor="$emails_config{color_bandeau_bg}">
              <tr>
                <td width="45" align="center" class="td45"></td>
                <td align="center" class="tdleftcontent" valign="middle" height="52" height="52">
                  <span style="color:$emails_config{color_bandeau};">Service client : $eshop_setup{eshop_tel} - <a href="mailto:$eshop_setup{eshop_email}" style="color:$emails_config{color_bandeau};">$eshop_setup{eshop_email}</a></span>
                </td>
                <td width="40" align="center" class="td40 hidden-sm" valign="top">&nbsp;</td>
                <td align="right" class="tdrightcontent hidden-sm" valign="middle" height="52">
                  $social_links                
                </td>
                <td width="45" align="center" class="td45"></td>
              </tr>
            </table>
            <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
              <tr>
                <td width="800" height="32" align="left" colspan="3">&nbsp;</td>
              </tr>
            </table>
            
            $entete_links
HTML

  return $header;
}


#################################################################
################## get_eshop_emails_config_trad #################
#################################################################
# Params: 1 => le hash à traduire
#         2 => la langue cible
#         3 => le suffixe des clés du hash pour lesquels il faut
#              traduire
#              
# Return: Le tableau reçu avec les textid traduits
##################################################################
sub get_eshop_emails_config_trad
{
  my %hash_to_translate = %{$_[0]};
  my $lg = $_[1];
  my $suffixe = $_[2] || "";


  foreach $key (keys %hash_to_translate)
  {
    # Si la clé se termine par le suffixe, on traduit
    if($key =~ /.*$suffixe$/)
    {
      my ($value,$empty) = get_textcontent($dbh,$hash_to_translate{$key},$lg);
      # Si pas de traduction, on récupère les textes fr
      if($value eq "")
      {
        ($value,$empty) = get_textcontent($dbh,$hash_to_translate{$key},1);
      }
      $hash_to_translate{$key} = $value;
    }
    
  }

  return \%hash_to_translate;
}


##################################################
################## get_eshop_txt #################
##################################################
# Renvoit un hash des textes de la boutiques dans 
# la langue spécifiée
# 
# params: 1 => Le numéro de la langue voulue
#        
##################################################
sub get_eshop_txt
{
  my $lg = $_[0] || 1;

  # # Création d'un nouveau hash sitetxt pour avoir la langue de la commande lorsqu'on appelle le hash
  # my @sitetxt_eshop = sql_lines({debug_results=> 0, dbh=>$dbh,table=>"eshop_txts"});
  # my %sitetxt=();
  # foreach $sitetxt_eshop (@sitetxt_eshop)
  # {
  #   my %sitetxt_eshop = %{$sitetxt_eshop};
  #   my $value = $sitetxt_eshop{"lg".$lg};
  #   if($value eq "")
  #   {
  #     $value = $sitetxt_eshop{"lg1"};
  #   }

  #   $sitetxt{$sitetxt_eshop{keyword}} = $value;

  # }
  # 
  my %sitetxt = %{get_sitetxt($dbh,$lg)};

  return \%sitetxt;

}


#####################################################
################## get_country_name #################
#####################################################
# Params: 1 => l'id du pays de la table countries
#         2 => la langue cible
#         
# return: Le nom du pays          
######################################################
sub get_country_name
{
  my $id_country = $_[0];
  my $lg = $_[1];

  my %country = read_table($dbh, "countries", $id_country);

  my $col_name;
  if($lg == 1)
  {
    $col_name = "fr";
  }
  elsif ($lg == 2)
  {
    $col_name = "en";
  }
  elsif ($lg == 3)
  {
    $col_name = "nl";
  }

  return $country{$col_name}

}

sub generate_facture
{
    my $token = $_[0];
    my $type = $_[1] || "commande";
    my $y_rectangle = 0;    

    my %order = sql_line({dbh=>$dbh,table=>"eshop_orders",where=>"token='$token'"});

    if($token eq '' || !($order{id}>0))
    {
        see();
        print "Une erreur est survenue";
        exit;
    }

    my $font = 'Arial';
    my $ligne = 0;
    my $interligne = 14;

    # Préfixe pour récupérer les bons champs de livraison
    my $prefixe = "delivery_";
    my %delivery = sql_line({dbh=>$dbh, table=>"eshop_deliveries", where=>"name = '$order{delivery}' AND name != ''"});
    if($delivery{identity_tier} eq "y")
    {
      $prefixe = "tier_";
    }
    
    my $firstname = lc(trim(remove_accents_from($order{billing_firstname})));
    my $lastname = lc(trim(remove_accents_from($order{billing_lastname})));
    
    my @date_lines = split(/ /,get_order_moment(\%order));
    my $date = $date_lines[0];
    my $dis_token = substr $order{token}, 140, 4;
    $firstname = simplifier($firstname);
    $lastname = simplifier($lastname);

    my $num = $order{id};
    my $file_type = "order";
    my $document_date = trim(to_ddmmyyyy(get_order_moment(\%order)));

    if($type eq "facture")
    {
      $file_type = "invoice";
      $num = $order{invoice_num_handmade} || $order{invoice_num};
      @date_lines = split(/ /,$order{invoice_num_create_moment});
    	$date = $date_lines[0];
    	$document_date = trim(to_ddmmyyyy($order{invoice_num_create_moment}));
    }
    elsif($type eq "note")
    {
      $file_type = "nc";
      $num = $order{invoice_nc_handmade} || $order{invoice_nc};
      @date_lines = split(/ /,$order{invoice_nc_create_moment});
    	$date = $date_lines[0];
    	$document_date = trim(to_ddmmyyyy($order{invoice_nc_create_moment}));
    }
    
    my $cn="$firstname $lastname";
    my $pdf_file = "../inv/".$file_type."_".$num.'_'.$firstname.'_'.$lastname.'_'.$date.'_'.$dis_token.'.pdf';
    
    my @pdf = ();
        
    my %newpage = (
          type=>"new_page",
          model=>'../mig_skin/modeles/facture-pro-format-vide.pdf',
          content=>''
    );
    push @pdf,\%newpage;

    my $header_title = $sitetxt{eshop_facture_title};
    if($order{invoice_num} ne "" && $type eq "facture")
    {
      $header_title = $sitetxt{eshop_numero_facture_title},
    }
    elsif($order{invoice_nc} ne "" && $type eq "note")
    {
      $header_title = $sitetxt{eshop_note_credit_title},
    }
    
    my @lines = @{cutText($order{commentaire},47)};
    $order{commentaire} = $lines[0];
    if($#lines > 0)
    {
       $order{commentaire} =~ s/<br \/>/ /g;
       $order{commentaire} .= '...'; 
    }
    
    my @lines = @{cutText($order{payment},47)};
    $order{method_billing_name} = $lines[0];
    if($#lines > 0)
    {
       $order{method_billing_name} =~ s/<br \/>/ /g;
       $order{method_billing_name} .= '...'; 
    }
    my @lines = @{cutText($order{delivery},47)};
    $order{method_delivery_name} = $lines[0];
    if($#lines > 0)
    {
       $order{method_delivery_name} =~ s/<br \/>/ /g;
       $order{method_delivery_name} .= '...'; 
    } 
    my $delivery_intitule = trim("$order{delivery_lastname}  $order{delivery_firstname}");
    if($delivery_intitule ne '' && $order{$prefixe."company"} ne '')
    {
       $delivery_intitule .= ', '.$order{$prefixe."company"}; 
    }
    my $billing_intitule = trim("$order{billing_lastname}  $order{billing_firstname}");
    if($billing_intitule ne '' && $order{billing_company} ne '')
    {
       $billing_intitule .= ', '.$order{billing_company}; 
    }

    if($config{hide_firstname_lastname_billing} eq "y")
    {
    	$billing_intitule = $order{billing_company};
    }
    
    my $lg = get_quoted('lg');
    my %country = read_table($dbh,"countries",$order{billing_country}); 
    if($lg == 2)
    {
        $order{billing_country} = $country{en};
    }
    elsif($lg == 3)
    {
        $order{billing_country} = $country{nl};
    }
    else
    {
        $order{billing_country} = $country{fr};
    }
    
    my %country = read_table($dbh,"countries",$order{$prefixe."country"}); 
    if($lg == 2)
    {
        $order{$prefixe."country"} = $country{en};
    }
    elsif($lg == 3)
    {
        $order{$prefixe."country"} = $country{nl};
    }
    else
    {
        $order{$prefixe."country"} = $country{fr};
    }
    
     my @header = 
     (
       {
           type=>"data",
           value=>$header_title,
           x=>"41",
           y=>"802",
           font_weight=>"bold",
           font_size=>"16",
           font_color=>"#173a5d",
           text_align=>"0"
       }
     );
     push @pdf,@header;
     
#      print "[$sitetxt{eshop_facture_title}][$sitetxt{eshop_invoice2_banque}]";
#      exit;
     
     #COORDONNEES COL 1*********************************************************
     $ligne = 0;
     my $col1 = 50;
     my $col2 = 75;
     my @coordonnees1 = 
     (
       {
           type=>"data",
           value=>"$setup{eshop_name}",
           x=>$col1,
           y=>750 - $ligne++ * $interligne,
           font_weight=>"bold",
           font_size=>"10",
           font_color=>"#000000",
       }
       ,
       {
           type=>"data",
           value=>"$setup{eshop_street}",
           font_color=>"#000000",
           x=>$col1,
           y=>750 - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$setup{eshop_zip_city}",
           font_color=>"#000000",
           x=>$col1,
           y=>750 - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$setup{eshop_country}",
           font_color=>"#000000",
           x=>$col1,
           y=>750 - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_phone}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>750 - $ligne * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$setup{eshop_tel}",
           font_color=>"#000000",
           x=>$col2,
           y=>750 - $ligne++ * $interligne
       }
       
     );
     push @pdf,@coordonnees1;
    
    #COORDONNEES COL 2*********************************************************
     $ligne = 0;
     $col1 = 230;
     $col2 = 280;
     my @coordonnees2 = 
     (
       {
           type=>"data",
           value=>"$sitetxt{eshop_facture_mail}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>750 - $ligne * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$setup{eshop_email}",
           font_color=>"#000000",
           x=>$col2,
           y=>750 - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_web}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>750 - $ligne * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$setup{eshop_web}",
           font_color=>"#000000",
           x=>$col2,
           y=>750 - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_tva}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>750 - $ligne * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$setup{eshop_tva}",
           font_color=>"#000000",
           x=>$col2,
           y=>750 - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_banque}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>750 - $ligne * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$setup{eshop_banque}",
           font_color=>"#000000",
           x=>$col2,
           y=>750 - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$sitetxt{eshop_iban}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>750 - $ligne * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$setup{eshop_iban}",
           font_color=>"#000000",
           x=>$col2,
           y=>750 - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$sitetxt{eshop_bic}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>750 - $ligne * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$setup{eshop_bic}",
           font_color=>"#000000",
           x=>$col2,
           y=>750 - $ligne++ * $interligne
       }
     );
     push @pdf,@coordonnees2;
     
     #INFORMATIONS SUR LA FACTURE***********************************************
     my $col1= 41;
     my @header = 
     (
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_header_infosfacture}",
           x=>$col1,
           y=>"650",
           font_weight=>"bold",
           font_size=>"12",
           font_color=>"#173a5d",
           text_align=>"0"
       }
     );
     push @pdf,@header;
     
     
     #INFOS FACTURE COL 1*******************************************************
     $ligne = 0;
     my $col1 = 50;
     my $col2 = 135;
     my $y = 631;

     my @infos1 = 
     (
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_facture_date}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>$y - $ligne * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$document_date",
           font_color=>"#000000",
           x=>$col2,
           y=>$y - $ligne++ * $interligne
       }
     );
     push @pdf,@infos1;

     if($order{invoice_nc} ne "" && $type eq "note")
     {
         my @infos1 = 
        (
               {
                     type=>"data"
,                     value=>"$sitetxt{eshop_facture_nc}:",
                     font_color=>"#000000",
                     x=>$col1,
                     font_weight=>"bold",
                     y=>$y - $ligne * $interligne
                 }
                 ,
                 {
                     type=>"data",
                     value=>$order{invoice_nc_handmade} || $order{invoice_nc},
                     font_color=>"#000000",
                     x=>$col2,
                     y=>$y - $ligne++ * $interligne
                 }
        );
         push @pdf,@infos1;
     }
     
     if($order{invoice_num} ne "" && $type ne "commande")
     {
         my @infos1 = 
        (
               {
                     type=>"data"
,                     value=>"$sitetxt{eshop_invoice2_facture_num}:",
                     font_color=>"#000000",
                     x=>$col1,
                     font_weight=>"bold",
                     y=>$y - $ligne * $interligne
                 }
                 ,
                 {
                     type=>"data",
                     value=>$order{invoice_num_handmade} || $order{invoice_num},
                     font_color=>"#000000",
                     x=>$col2,
                     y=>$y - $ligne++ * $interligne
                 }
        );
         push @pdf,@infos1;
     }     
     
     
       my @infos1 = 
      (
      {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_facture_numcommande}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>$y - $ligne * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$order{id}",
           font_color=>"#000000",
           x=>$col2,
           y=>$y - $ligne++ * $interligne
       }
       );
       push @pdf,@infos1;
   
     
     #INFOS FACTURE COL 2*******************************************************
     $ligne = 0;
     my $col1 = 229;
     my $col2 = 337;
     my $y = 631;
     
     
     my %delivery = select_table($dbh,"eshop_deliveries","","name='$order{delivery}'");
     my ($delivery,$dum) = get_textcontent($dbh,$delivery{id_textid_name});
     my %payment = select_table($dbh,"eshop_payments","","name='$order{payment}'");
     my ($payment,$dum) = get_textcontent($dbh,$payment{id_textid_name});
     
     $order{order_finish_moment} = trim(to_ddmmyyyy(get_order_moment(\%order)));
     my @infos2 = 
     (
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_facture_numclient}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>$y - $ligne * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$order{id_member}",
           font_color=>"#000000",
           x=>$col2,
           y=>$y - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_facture_methpaiement}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>$y - $ligne * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$payment",
           font_color=>"#000000",
           x=>$col2,
           y=>$y - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_facture_methlivraison}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>$y - $ligne * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$delivery",
           font_color=>"#000000",
           x=>$col2,
           y=>$y - $ligne++ * $interligne
       }
     );
     push @pdf,@infos2;
     
     $y -= 60;
     my $ligne_adresse_header = $y;
     
    #ADRESSE DE LIVRAISON ****************************************************
    my @header = 
    (
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_header_adresse_livraison}",
           x=>"50",
           y=>"$ligne_adresse_header",
           font_weight=>"bold",
           font_size=>"12",
           font_color=>"#173a5d",
           text_align=>"0"
       }
    );
    push @pdf,@header;     
    
     $ligne = 0;
     my $col1 = 50;
     my $col2 = 85;
     my $y = $ligne_adresse_header - 16;
     my @coordonnees1 = 
     (
       {
           type=>"data",
           value=>"$delivery_intitule",
           x=>$col1,
           y=>$y - $ligne++ * $interligne,
           font_color=>"#000000",
       }
       ,
       {
           type=>"data",
           value=>"$order{$prefixe.'street'} $order{$prefixe.'number'}  $order{$prefixe.'box'}",
           font_color=>"#000000",
           x=>$col1,
           y=>$y - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$order{$prefixe.'zip'} $order{$prefixe.'city'}",
           font_color=>"#000000",
           x=>$col1,
           y=>$y - $ligne++ * $interligne
       }
        ,
       {
           type=>"data",
           value=>"$order{$prefixe.'country'}",
           font_color=>"#000000",
           x=>$col1,
           y=>$y - $ligne++ * $interligne
       }
        ,
       {
           type=>"data",
           value=>"$order{$prefixe.'phone'}",
           font_color=>"#000000",
           x=>$col1,
           y=>$y - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_tva}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>$y - $ligne * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$order{$prefixe.'vat'}",
           font_color=>"#000000",
           x=>$col2,
           y=>$y - $ligne++ * $interligne
       }
     );
     push @pdf,@coordonnees1;
    
    #ADRESSE DE FACTURATION ******************************************************
     my @header = 
     (
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_header_adresse_facturation}",
           x=>"315",
           y=>"$ligne_adresse_header",
           font_weight=>"bold",
           font_size=>"12",
           font_color=>"#173a5d",
           text_align=>"0"
       }
     );
     push @pdf,@header;  
     
     
     $ligne = 0;
     my $col1 = 315;
     my $col2 = 350;
     my $y = $ligne_adresse_header - 16;
     my @coordonnees2 = 
     (
       {
           type=>"data",
           value=>"$billing_intitule",
           x=>$col1,
           y=>$y - $ligne++ * $interligne,
           font_color=>"#000000",
       }
       ,
       {
           type=>"data",
           value=>"$order{billing_street} $order{billing_number}  $order{billing_box}",
           font_color=>"#000000",
           x=>$col1,
           y=>$y - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$order{billing_zip} $order{billing_city} ",
           font_color=>"#000000",
           x=>$col1,
           y=>$y - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$order{billing_country}",
           font_color=>"#000000",
           x=>$col1,
           y=>$y - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$order{billing_phone}",
           font_color=>"#000000",
           x=>$col1,
           y=>$y - $ligne++ * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_tva}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>$y - $ligne * $interligne
       }
       ,
       {
           type=>"data",
           value=>"$order{billing_vat}",
           font_color=>"#000000",
           x=>$col2,
           y=>$y - $ligne++ * $interligne
       }
        
     );
     push @pdf,@coordonnees2;    
     
     
     #DETAIL SUR VOTRE COMMANDE***********************************************
     my $col1= 41;
     $y -= 135;
     my @header = 
     (
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_header_detail}",
           x=>$col1,
           y=>$y,
           font_weight=>"bold",
           font_size=>"12",
           font_color=>"#173a5d",
           text_align=>"0"
       }
     );
     push @pdf,@header;
     
     
     
     $ligne = 0;
     my $col1 = 50;
     my $col2 = 310;
     my $col3 = 355;
     my $col4 = 406;
     my $col5 = 439;
     my $col6 = 503;
     my $col7 = 560;
     
     if($config{invoice_no_htva_col} eq 'y')
     {
        $col4 = 439;
        $col5 = 503;
        $col6 = 503;
        $col7 = 560;
     }
     
     $y -= 20; 
     $y_rectangle = $y;
     my @intitules = 
     (
       {
           type=>"line",
           x1=>$col1-5,
           y1=>$y+10,
           x2=>$col1-5,
           y2=>$y-20,
           font_color=>"#000000",
       }
        ,
           {
               type=>"line",
               x1=>$col1-5,
               y1=>$y+10,
               x2=>$col7+5,
               y2=>$y+10,
               font_color=>"#000000",
           } 
       ,
        {
           type=>"line$config{invoice_no_htva_col}",
           x1=>$col2+5,
           y1=>$y+10,
           x2=>$col2+5,
           y2=>$y-20,
           font_color=>"#000000",
       }
       ,
        {
           type=>"line",
           x1=>$col3+5,
           y1=>$y+10,
           x2=>$col3+5,
           y2=>$y-20,
           font_color=>"#000000",
       }
       ,
        {
           type=>"line",
           x1=>$col4+5,
           y1=>$y+10,
           x2=>$col4+5,
           y2=>$y-20,
           font_color=>"#000000",
       }
       ,
        {
           type=>"line",
           x1=>$col5+5,
           y1=>$y+10,
           x2=>$col5+5,
           y2=>$y-20,
           font_color=>"#000000",
       }
       ,
        {
           type=>"line",
           x1=>$col6+5,
           y1=>$y+10,
           x2=>$col6+5,
           y2=>$y-20,
           font_color=>"#000000",
       }
       ,
        {
           type=>"line",
           x1=>$col7+5,
           y1=>$y+10,
           x2=>$col7+5,
           y2=>$y-20,
           font_color=>"#000000",
       }
       ,
       {
           type=>"data",
           font_weight=>"bold",
           value=>"$sitetxt{eshop_invoice2_header_articles}",
           x=>$col1,
           y=>$y-4,
           font_color=>"#ffffff",
       }
       ,
       {
           type=>"data$config{invoice_no_htva_col}",
           value=>"$sitetxt{eshop_invoice2_header_puhtva}",
           font_weight=>"bold",
           x=>$col2,
           text_align=>2,
           y=>$y-4,
           font_color=>"#ffffff",
       }
       ,
       {
           type=>"data$config{invoice_no_htva_col}",
           font_weight=>"bold",
           value=>"$sitetxt{eshop_invoice2_header_txtva}",
           x=>$col3,
           y=>$y-4,
           text_align=>2,
           font_color=>"#ffffff",
       }
       ,
       {
           type=>"data",
           font_weight=>"bold",
           value=>"$sitetxt{eshop_invoice2_header_putvac}",
           x=>$col4,
           y=>$y-4,
           text_align=>2,
           font_color=>"#ffffff",
       }
       ,
       {
           type=>"data",
           font_weight=>"bold",
           value=>"$sitetxt{eshop_invoice2_header_qty}",
           x=>$col5,
           text_align=>2,
           y=>$y-4,
           font_color=>"#ffffff",
       }
       ,
       {
           type=>"data$config{invoice_no_htva_col}",
           font_weight=>"bold",
           value=>"$sitetxt{eshop_invoice2_header_tothtva}",
           x=>$col6,
           y=>$y-4,
           text_align=>2,
           font_color=>"#ffffff",
       }
        ,
       {
           type=>"data",
           font_weight=>"bold",
           value=>"$sitetxt{eshop_invoice2_header_tottvac}",
           x=>$col7,
           y=>$y-4,
           text_align=>2,
           font_color=>"#ffffff",
       }
        
     );
     push @pdf,@intitules;   
     
     
    my @details = get_table($dbh,"eshop_order_details","","id_eshop_order='$order{id}'","","");
    my $y_details = $y-10;
    my $ligne_detail = 1;
    $interligne = 10;
    my $premiere_page = 1;
    my $count_lignes = 0;
    foreach $detail (@details)
    {
         if(($premiere_page == 1 && $count_lignes > 7) || ($count_lignes > 16 || ($count_lignes > 24) || ($count_lignes > 32)))
         {
              $y_details=800;
              my %newpage = (
              type=>"new_page",
              model=>'../mig_skin/vierge.pdf',
              content=>''
              );
              
              push @pdf,\%newpage;
              $count_lignes = 0;
              $ligne_detail = 0;
              $premiere_page = 0;
         }
         
         
         my %detail = %{$detail};
         $y = $y_details - $ligne_detail++ * $interligne;
         
         my $pu_remise_htva = display_price($detail{detail_pu_discount_htva});
         my $pu_remise_tvac = display_price($detail{detail_pu_discount_tvac});
         my $show_remise = 0;
         if(abs($pu_remise_htva) > 0 || abs($pu_remise_tvac) > 0)
         {
           $show_remise = 1;
         }
         
         # my %tva = read_table($dbh,"eshop_tvas",$detail{id_tva});
         my $taux_tva = $cache_eshop_tvas_tva_value{$detail{id_tva}} * 100;
         $detail{taux_tva} = $tva{reference};
         $detail{pu_htva} = display_price($detail{detail_pu_htva});
         $detail{pu_tvac} = display_price($detail{detail_pu_tvac});
         $detail{subtotal_htva} = display_price($detail{detail_total_htva});
         $detail{subtotal_tvac} = display_price($detail{detail_total_tvac});
         $detail{htva_discount} = display_price($detail{detail_total_discount_htva});
         $detail{tvac_discount} = display_price($detail{detail_total_discount_tvac});
         
         my @test_lines = @{cutText($detail{detail_label},50)};
         my $nb_lignes = $#test_lines + 1 ;     
         
         my $line_font_size = 8;
         my @ligne_detail = 
         (
           {
               type=>"line",
               x1=>$col1-5,
               y1=>$y+10,
               x2=>$col1-5,
               y2=>$y-30,
               font_size=>"$line_font_size",
               font_color=>"#000000",
           } 
         
           ,
           {
               type=>"line$config{invoice_no_htva_col}",
               x1=>$col2+5,
               y1=>$y+10,
               x2=>$col2+5,
               y2=>$y-30,
               font_size=>"$line_font_size",
               font_color=>"#000000",
           } 
           ,
           {
               type=>"line",
               x1=>$col3+5,
               y1=>$y+10,
               x2=>$col3+5,
               y2=>$y-30,
               font_size=>"$line_font_size",
               font_color=>"#000000",
           } 
           ,
           {
               type=>"line",
               x1=>$col4+5,
               y1=>$y+10,
               x2=>$col4+5,
               y2=>$y-30,
               font_size=>"$line_font_size",
               font_color=>"#000000",
           } 
           ,
           {
               type=>"line",
               x1=>$col5+5,
               y1=>$y+10,
               x2=>$col5+5,
               y2=>$y-30,
               font_size=>"$line_font_size",
               font_color=>"#000000",
           } 
           ,
           {
               type=>"line",
               x1=>$col6+5,
               y1=>$y+10,
               x2=>$col6+5,
               y2=>$y-30,
               font_size=>"$line_font_size",
               font_color=>"#000000",
           }
            ,
           {
               type=>"line",
               x1=>$col7+5,
               y1=>$y+10,
               x2=>$col7+5,
               y2=>$y-30,
               font_size=>"$line_font_size",
               font_color=>"#000000",
           } 
           ,
           {
               type=>"data",
               value=>"$detail{detail_reference}",
               maxlen=>"50",
               linedecay=>"11",
               maxlignes=>"2",
               x=>$col1,
               font_size=>"$line_font_size",
               y=>$y,
               font_color=>"#000000",
           }
           ,
           {
               type=>"data",
               value=>"$detail{detail_label}",
               maxlen=>"50",
               linedecay=>"11",
               maxlignes=>"2",
               x=>$col1,
               font_size=>"$line_font_size",
               y=>$y-10,
               font_color=>"#000000",
           }
           ,
           {
               type=>"data$config{invoice_no_htva_col}",
               value=>"$detail{pu_htva}",
               text_align=>2,
               x=>$col2,
               y=>$y,
               font_size=>"$line_font_size",
               font_color=>"#000000",
           }
           ,
           {
               type=>"data$config{invoice_no_htva_col}",
               value=>"$taux_tva",
               text_align=>2,
               x=>$col3,
               y=>$y,
               font_size=>"$line_font_size",
               font_color=>"#000000",
           }   
           ,
           {
               type=>"data",
               value=>"$detail{pu_tvac}",
               text_align=>2,
               x=>$col4,
               y=>$y,
               font_size=>"$line_font_size",
               font_color=>"#000000",
           }
           ,
           {
               type=>"data",
               value=>"$detail{detail_qty}",
               text_align=>2,
               x=>$col5,
               y=>$y,
               font_size=>"$line_font_size",
               font_color=>"#000000",
           }
           ,
           {
               type=>"data$config{invoice_no_htva_col}",
               value=>"$detail{subtotal_htva}",
               text_align=>2,
               x=>$col6,
               y=>$y,
               font_size=>"$line_font_size",
               font_color=>"#000000",
           }
            ,
           {
               type=>"data",
               value=>"$detail{subtotal_tvac}",
               text_align=>2,
               x=>$col7,
               y=>$y,
               font_size=>"$line_font_size",
               font_color=>"#000000",
           }
           ,
           {
               type=>"line",
               x1=>$col1-5,
               y1=>$y-30,
               x2=>$col7+5,
               y2=>$y-30,
               font_color=>"#000000",
            }
                   
         );
         
                  
         push @pdf,@ligne_detail;  
         
         $nb_lignes = 2;
         $ligne_detail += $nb_lignes;
         $ligne_detail++;
         
         if($show_remise )
         {
         $y = $y_details - $ligne_detail++ * $interligne;
         my @ligne_detail = 
         (
           
           {
               type=>"line",
               x1=>$col1-5,
               y1=>$y+10,
               x2=>$col1-5,
               y2=>$y-20,
               font_color=>"#000000",
           } 
           
           ,
           {
               type=>"line$config{invoice_no_htva_col}",
               x1=>$col2+5,
               y1=>$y+10,
               x2=>$col2+5,
               y2=>$y-20,
               font_color=>"#000000",
           } 
           ,
           {
               type=>"line",
               x1=>$col3+5,
               y1=>$y+10,
               x2=>$col3+5,
               y2=>$y-20,
               font_color=>"#000000",
           } 
           ,
           {
               type=>"line",
               x1=>$col4+5,
               y1=>$y+10,
               x2=>$col4+5,
               y2=>$y-20,
               font_color=>"#000000",
           } 
           ,
           {
               type=>"line",
               x1=>$col5+5,
               y1=>$y+10,
               x2=>$col5+5,
               y2=>$y-20,
               font_color=>"#000000",
           } 
           ,
           {
               type=>"line",
               x1=>$col6+5,
               y1=>$y+10,
               x2=>$col6+5,
               y2=>$y-20,
               font_color=>"#000000",
           }
            ,
           {
               type=>"line",
               x1=>$col7+5,
               y1=>$y+10,
               x2=>$col7+5,
               y2=>$y-20,
               font_color=>"#000000",
           } 
           ,
           {
               type=>"data",
               value=>"$sitetxt{eshop_invoice2_remise}",
               x=>$col1,
               font_size=>"$line_font_size",
               y=>$y,
               font_size=>"$line_font_size",
               font_color=>"#bbbbbb",
           }
           ,
           {
               type=>"data$config{invoice_no_htva_col}",
               value=>"$pu_remise_htva", 
               text_align=>2,               
               font_size=>"$line_font_size",
               x=>$col2,
               y=>$y,
               font_color=>"#bbbbbb",
           }
            ,
           {
               type=>"data$config{invoice_no_htva_col}",
               value=>"$detail{taux_tva}",
               text_align=>2,
               font_size=>"$line_font_size",
               x=>$col3,
               y=>$y,
               font_color=>"#bbbbbb",
           } 
           ,
           {
               type=>"data",
               value=>"$pu_remise_tvac",
               text_align=>2,            
               font_size=>"$line_font_size",   
               x=>$col4,
               y=>$y,
               font_color=>"#bbbbbb",
           }
            ,
           {
               type=>"data",
               value=>"$detail{detail_qty}",
               text_align=>2,       
               font_size=>"$line_font_size",        
               x=>$col5,
               y=>$y,
               font_color=>"#bbbbbb",
           }
           ,
           {
               type=>"data$config{invoice_no_htva_col}",
               value=>"$detail{htva_discount}",
               text_align=>2,               
               x=>$col6,
               font_size=>"$line_font_size",
               y=>$y,
               font_color=>"#bbbbbb",
           }
            ,
           {
               type=>"data",
               value=>"$detail{tvac_discount}",
               text_align=>2,               
               x=>$col7,
               y=>$y,
               font_size=>"$line_font_size",
               font_color=>"#bbbbbb",
           }
           
         );
         push @pdf,@ligne_detail; 
         $count_lignes++;
         }
         
         $count_lignes++;
    }
    
    
    
    
     my @bas = 
     (
       {
           type=>"line",
           x1=>$col1-5,
           y1=>$y-20,
           x2=>$col7+5,
           y2=>$y-20,
           font_color=>"#000000"
       }
      
    ); 
    push @pdf,@bas;  
    
    
    
    $ligne = 0;
     my $col1 = 460;
     my $col2 = 560;
    $y -= 40; 
    
	my $total_htva = display_price($order{total_htva});
	my $remise_htva = display_price($order{total_discount_htva});
	my $coupons_htva = display_price($order{total_coupons_htva});
	my $port_htva = display_price($order{total_delivery_htva});
	my $apayer_htva = display_price($order{total_discounted_htva});
	my $apayer_tva = display_price($order{total_discounted_tva});
	my $apayer_tvac = display_price($order{total_discounted_tvac});	
	

	my $id_tarif = $order{id_tarif} || 1;
  my %tarif = read_table($dbh,'eshop_tarifs',$id_tarif);

	if($order{is_intracom} eq "1" && $order{do_intracom} eq 'y')
  {
  	$col1 = 400;
		$apayer_tva = $sitetxt{eshop_do_intracom_label};
		$apayer_tvac = $apayer_htva;
	}
	elsif($tarif{pay_tvac} ne "y")
	{
		$apayer_tva = '-';
		$apayer_tvac = $apayer_htva;
	}
	
	#total HTVA
	$y -= $interligne;
	my @line = 
	(
		{
		   type=>"data",
		   value=>"$sitetxt{'eshop_invoice2_totalhtva'}:",
		   x=>$col1,
		   y=>$y,
		   font_weight=>"",
		   font_size=>"10",
		   text_align=>'2',
		   font_color=>"#000000",
		}
		,
		{
		   type=>"data",
		   value=>"$total_htva",
		   font_color=>"#000000",
		   text_align=>'2',
		   x=>$col2,
		   y=>$y
		}
	);
	push @pdf,@line;  
    
    
			if($order{total_discount_htva} > 0)
			{
				#Remise HTVA
				$y -= $interligne;
				my @line = 
				(
					{
					   type=>"data",
					   value=>"$sitetxt{'eshop_invoice2_remise'} $sitetxt{'eshop_htva'}:",
					   x=>$col1,
					   y=>$y,
					   font_weight=>"",
					   font_size=>"10",
					   text_align=>'2',
					   font_color=>"#ff0000",
					}
					,
					{
					   type=>"data",
					   value=>"$remise_htva",
					   font_color=>"#ff0000",
					   text_align=>'2',
					   x=>$col2,
					   y=>$y
					}
				);
				push @pdf,@line;  
			}
			
			
			if($order{total_coupons_htva} > 0)
			{
				#total_coupons_htva HTVA
				$y -= $interligne;
				my @line = 
				(
					{
					   type=>"data",
					   value=>"$sitetxt{'eshop_recapbox_5'} $sitetxt{'eshop_htva'}:",
					   x=>$col1,
					   y=>$y,
					   font_weight=>"",
					   font_size=>"10",
					   text_align=>'2',
					   font_color=>"#ff0000",
					}
					,
					{
					   type=>"data",
					   value=>"$coupons_htva",
					   font_color=>"#ff0000",
					   text_align=>'2',
					   x=>$col2,
					   y=>$y
					}
				);
				push @pdf,@line;  
			}
			
	#port  HTVA
  if($port_htva > 0)
  {        
  	$y -= $interligne;
  	my @line = 
  	(
  		{
  		   type=>"data",
  		   value=>"$sitetxt{'eshop_invoice2_fraisports'} $sitetxt{'eshop_htva'}:",
  		   x=>$col1,
  		   y=>$y,
  		   font_weight=>"",
  		   font_size=>"10",
  		   text_align=>'2',
  		   font_color=>"#000000",
  		}
  		,
  		{
  		   type=>"data",
  		   value=>"$port_htva",
  		   font_color=>"#000000",
  		   text_align=>'2',
  		   x=>$col2,
  		   y=>$y
  		}
  	);
		push @pdf,@line; 	
  }

	#Total  HTVA après remises et frais de port
	if($total_htva != $apayer_htva)
	{
		$y -= $interligne;
		my @line = 
		(
			{
			   type=>"data",
			   value=>"$sitetxt{'eshop_invoice2_totalhtva'}:",
			   x=>$col1,
			   y=>$y,
			   font_weight=>"",
			   font_size=>"10",
			   text_align=>'2',
			   font_color=>"#000000",
			}
			,
			{
			   type=>"data",
			   value=>"$apayer_htva",
			   font_color=>"#000000",
			   text_align=>'2',
			   x=>$col2,
			   y=>$y
			}
		);
		push @pdf,@line; 		
	}

			
	#TVA
	$y -= $interligne;
	my @line = 
	(
		{
		   type=>"data",
		   value=>"$sitetxt{'eshop_tva'}:",
		   x=>$col1,
		   y=>$y,
		   font_weight=>"",
		   font_size=>"10",
		   text_align=>'2',
		   font_color=>"#000000",
		}
		,
		{
		   type=>"data",
		   value=>"$apayer_tva",
		   font_color=>"#000000",
		   text_align=>'2',
		   x=>$col2,
		   y=>$y
		}
	);
	push @pdf,@line;

	#Total  tvac
	my $label_grand_total = $sitetxt{eshop_invoice2_totalttc};
	if($order{is_intracom} eq "1")
	{
		$label_grand_total = $sitetxt{eshop_invoice2_totalhtva};		
	}	
	$y -= $interligne;
	my @line = 
	(
		{
		   type=>"data",
		   value=>"$label_grand_total:",
		   x=>$col1,
		   y=>$y,
		   font_weight=>"Bold",
		   font_size=>"10",
		   text_align=>'2',
		   font_color=>"#000000",
		}
		,
		{
		   type=>"data",
		   value=>"$apayer_tvac",
		   font_color=>"#000000",
		   text_align=>'2',
		     font_weight=>"Bold",
		   x=>$col2,
		   y=>$y
		}
	);
	push @pdf,@line;			
			
     
    $ligne = 0;
     my $col1 = 50;
     my $col2 = 85;
     $y -= $interligne;
     my @remarque = 
     (
       {
           type=>"data",
           value=>"$sitetxt{eshop_invoice2_remarque}:",
           font_color=>"#000000",
           x=>$col1,
           font_weight=>"bold",
           y=>$y
       }
       ,
       {
           type=>"data",
           value=>"$order{commentaire}",
           font_color=>"#000000",
           font_size=>"8",
           x=>$col1,
           y=>$y - 20
       }
     );
     push @pdf,@remarque;
     $y -= $interligne;   

    
    create_pdf_pages($pdf_file,\@pdf,'Arial',10,$y_rectangle);
    return $pdf_file;
}

sub create_pdf_pages
{
   my $chemin=$_[0];
   my @lignes = @{$_[1]};
   my $default_font = $_[2];
   my $default_size = $_[3];
   my $y_rectangle = $_[4];
   my $url_picture = $_[5] || '../skin/invoice_logo.png';
   my $rectangle_color = $_[6] || '#173a5d';
   
   if($_[5] eq '' && -e '../skin/invoice_logo.png')
   {
   }
   elsif($_[5] eq '')
   {
        $url_picture = '../skin/invoice_logo.jpg';
   }
   use PDF::CreateSimple;
   my $pdfFile = "";   
   my $firstpage = 1;
   for($i=0;$i<$#lignes+1;$i++)
   {
        my %ligne=%{$lignes[$i]};
       
        if($ligne{type} eq "new_page")
        {
            if ($firstpage) {
            	 $pdfFile = PDF::CreateSimple->new($chemin,$ligne{model});
               $firstpage = 0;            
            } else {
               $pdfFile->importPage('../usr/'.$ligne{model});
            }
            if($y_rectangle > 0)
            {
               my $y1 = $y_rectangle +10;
               my $y2 = $y_rectangle -10;
               $pdfFile->drawRectangle(45,$y1,565,$y2,0,'#000000',$rectangle_color,1);
               $y_rectangle = 0; 
            }
        }
        elsif($ligne{type} eq "data")
        {
           my @lignes = ();
           $lignes[0] = $ligne{value};
           if ($ligne{value} =~ /\n/) {
               @lignes = split(/\n/,$ligne{value});
           }

           my $nbline=0;
           foreach my $ligne (@lignes) 
           {
           
                   my @lines = @{cutText($ligne,$ligne{maxlen})};
                  
                   my $multi = 0;
                   my $font = $ligne{font} || $default_font;
                   foreach my $line (@lines) 
                   {
                       $ligne{font_size} = $ligne{font_size} || $default_size;
                       $ligne{font} = $font;
                       if($ligne{font_weight} ne 'normal')
                       {
                          $ligne{font} = $font.' '.$ligne{font_weight};
                       }
if($ligne{linedecay} > 11)
{
}
else
{
  $ligne{linedecay} =11;
}

                          pdf_text($pdfFile,$line,$ligne{font},$ligne{font_size},$ligne{x},$ligne{y}-($nbline*$ligne{linedecay}),$ligne{font_color},$ligne{text_align});
                       $nbline++;
                       $multi = 1;
                   }
               if (!$multi) { $nbline++; } 
           }
        }
        elsif($ligne{type} eq "line")
        {
           # $pdfFile->drawLine($ligne{x1},$ligne{y1},$ligne{x2},$ligne{y2},0.5,$ligne{font_color});
        }
   }
    #LOGO*********************************************************************
    if($url_picture ne '' && -e $url_picture)
    {
        $pdfFile->drawImage($url_picture,425,745,1,undef,1); 
    }
   $pdfFile->closeFile;
}

sub cutText
{
	my $text = $_[0] ;
	my $length = $_[1] || 0;
	
	my $lengthOfText = length($text) ;
	my @table = () ;

	if (!$length) {
      $table[0] = $text; 
      return (\@table);
  }
	
	my $i;
	
	if($lengthOfText > $length)
	{
		my @texte = split(/ /, $text) ;		
		my $string = "" ;
		for($i = 0 ; $i < @texte ; $i++)
		{
			if((length($texte[$i]) + length($string)) < $length)
			{
				$string .= "$texte[$i] " ;
			}
			else
			{
				push(@table, $string) ;
				$string = "$texte[$i] " ;
			}
		}
		push(@table, $string) ;
	}
	else
	{
		push(@table, $text) ;
	}
	
	return (\@table) ;
}

################################################################################
# update_stock
################################################################################
sub update_stock
{
	my %d = %{$_[0]};
	log_debug('debug update stock','vide','update_stock');
  my %order = %{$d{order}};
  my $alt_payment_status = $d{payment_status};
log_debug($order{id},'','update_stock');
  my %payment = select_table($dbh,"eshop_payments","","name='$order{payment}'");
     log_debug('payment id:'.$payment{id},'','update_stock');   
     log_debug('payment_status:'.$order{payment_status},'','update_stock');   
     log_debug('alt_payment_status:'.$alt_payment_status,'','update_stock');   
     log_debug('eshop_always_remove_from_stock:'.$config{eshop_always_remove_from_stock},'','update_stock');   
     log_debug('payment remove_qty_from_stock:'.$payment{remove_qty_from_stock},'','update_stock');   
     log_debug('stock_updated:'.$order{stock_updated},'','update_stock');   
    
    
    if( $order{payment_status} eq 'paid' 
        || $order{payment_status} eq 'captured' 
        || $alt_payment_status eq 'paid' 
        || $alt_payment_status eq 'captured'
		|| $config{eshop_always_remove_from_stock} eq 'y'
    )
    {
        if($payment{remove_qty_from_stock} eq 'y' && $order{stock_updated} == 0)
        {
              my @order_details=get_table($dbh,"eshop_order_details","","id_eshop_order='$order{id}'","","","",0);
              for ($p=0;$p<$#order_details+1;$p++)
              {
                   my %data_stock=read_table($dbh,"data_stock",$order_details[$p]{id_data_stock});
                   if($data_stock{id} > 0)
                   {
                          $data_stock{stock} -= $order_details[$p]{detail_qty};
                          $stmt = "UPDATE data_stock SET stock='$data_stock{stock}' where id='$order_details[$p]{id_data_stock}'";
						  log_debug($stmt,'','update_stock');   
                          execstmt($dbh,$stmt); 
                          
                          $stmt = "UPDATE eshop_orders SET stock_updated = 1 where id='$order{id}'";
						  log_debug($stmt,'','update_stock');   
                          execstmt($dbh,$stmt);
                          
                   }
                   else
                   {
                   }
              }
        }
        else
        {
        }
    }
    else
    {
    }
}

################################################################################
# exec_post_order
################################################################################
sub exec_post_order
{
	my %d = %{$_[0]};

  my %order = %{$d{order}};
  my $alt_payment_status = $d{payment_status};

  
	if ($order{post_order_ok} eq 'n' && $setup{post_order_func} ne "")
	{
		members::member_add_event({group=>'eshop',type=>"exec_post_order",name=>"Exécution du traitement post-commande ($setup{post_order_func})",detail=> $order{id}});
		my $post_order_func = 'def_handmade::'.$setup{post_order_func};
		&$post_order_func($dbh,\%order,$alt_payment_status);      
		members::member_add_event({group=>'eshop',type=>"exec_post_order",name=>"Exécution du traitement post-commande ($setup{post_order_func}) terminé",detail=> $order{id}});
 	}
}

##################################################################################
# get_order_moment
##################################################################################
# Renvoit la date de fin de commande sauf si elle est égale à 0, alors renvoit la 
# date de début de commande
###################################################################################
sub get_order_moment
{
  my %order = %{$_[0]};

  my $order_moment = $order{order_finish_moment};
  if($order_moment eq "0000-00-00 00:00:00" || $order_moment eq "")
  {
    $order_moment = $order{order_begin_moment};
  }

  return $order_moment;
}

##################################################################################
# get_eshop_emails_setup
##################################################################################
sub get_eshop_emails_setup
{
    my %emails_setup = select_table($dbh,"eshop_emails_setup");
    if($emails_setup{id} > 0)
    {
        return \%emails_setup;
    }

}


################################################################################
# get_order_retour_content
################################################################################
sub get_order_retour_content
{
  my %d = %{$_[0]};

  my $token = $d{token};  
  
  $sitetxt{retour_explications} =~ s/\r*\n/<br>/g;
     
  my %order = sql_line({table=>'eshop_orders',where=>"token='$token'"});
    
  my @order_details = get_table($dbh,"eshop_order_details",'',"id_eshop_order = '$order{id}'",'','','',0);
  my $products;

  my $id_tarif = eshop_get_id_tarif_member();
  my %tarif = sql_line({dbh=>$dbh, table=>"eshop_tarifs", where=>"id = $id_tarif"});
  
  foreach $order_detail (@order_details)
  {
    my %order_detail = %{$order_detail};
    my $has_discount = 'n';
    if($order_detail{detail_pu_discounted_htva} < $order_detail{detail_pu_htva})
    {
       $has_discount = 'y';
    }
    my $pu_discounted = $order_detail{detail_pu_discounted_tvac};
    my $total_discounted = $order_detail{detail_total_discounted_tvac};
    if($order{is_intracom} && $order{do_intracom} eq 'y' || $tarif{is_tvac} ne 'y')
    {
        $pu_discounted = $order_detail{detail_pu_discounted_htva};
        $total_discounted = $order_detail{detail_total_discounted_htva};
    }
            
    $pu_discounted = display_price($pu_discounted);
    $total_discounted = display_price($total_discounted);
          
   $products .= <<"HTML"; 
      <tr>
        <td>
          <label><input type="checkbox" name="detail_$order_detail{id}" value="y" />
            <b>$order_detail{detail_label}</b><br />
            Ref : $order_detail{detail_reference}
          </label>
        </td>
        <td align="center"><b>$order_detail{detail_qty}</b></td>
        <td align="right"><b> $pu_discounted</b></td>
        <td align="right"><b> $total_discounted</b></td>
      </tr>
HTML
  }
   

  my $product_table = <<"HTML";
  <table class="table table-striped table-bordered table-hover">
    <thead>
      <tr>
        <th align="center" width="300">$sitetxt{'eshop_fac_7'}</th>
        <th align="center" width="30">$sitetxt{'eshop_fac_8'} </th>
        <th align="center" width="60">$sitetxt{'eshop_fac_9'} $precision</th>
        <th align="center" width="75">$sitetxt{'eshop_fac_10'} $precision</th>
      </tr>
    </thead>
    <tbody>
      $products
    </tbody>
  </table>
HTML
  
  my $eshop_echange_class = '';
  my $line_choix_retour_echange = <<"HTML";
    <div class="form-group">
      <label class="control-label col-sm-4">$sitetxt{retour_question} : </label>
      <div class="col-sm-8">
        <select name="retour_type" required id="" class="input-xlarge required form-control">
          <option value="">$sitetxt{eshop_veuillez}</option>
          <option value="retour">
            $sitetxt{retour_retour}
          </option>
          <option value="echange" >
            $sitetxt{retour_echange}
          </option>
        </select>       
      </div>
    </div>
HTML



  
  if($config{eshop_disable_echange} eq 'y')
  {
    $eshop_echange_class = ' hide ';
    $line_choix_retour_echange = <<"HTML";
    <input name="retour_type" type="hidden" value="retour" />
HTML
  }
  
  
  my $page = <<"HTML";

    <h1 class="page_title"><span>$sitetxt{eshop_history_retour}</span></h1>    
    $sitetxt{retour_explications}
    <br /><br />

    <form method="post" class="form-horizontal" action="$script_self"  enctype="multipart/form-data">
      <input type="hidden" name="sw" value = "retour_db" />     
      <input type="hidden" name="token" value = "$token" />     
      <input type="hidden" name="lg" value = "$config{current_language}" />                                  
                        
      $line_choix_retour_echange            
            
      <div class="form-group">
        <label class="control-label col-sm-4" for="lastname">$sitetxt{retour_references}:</label>
        <div class="col-sm-8">
          $product_table                        
        </div>
      </div>
            
      <div class="form-group $eshop_echange_class">
        <label class="control-label col-sm-4" for="lastname">$sitetxt{retour_echange_precisions}:</label>
          <div class="col-sm-8">
            <textarea name="retour_echange_precisions"  value="" class="form-control"></textarea> 
          </div>
      </div>
            
      <div class="form-group">
        <label class="control-label col-sm-4" for="lastname">$sitetxt{retour_raison}:</label>
        <div class="col-sm-8">
          <textarea name="retour_raison"  value="" class="form-control"></textarea>                         
        </div>
      </div>
                        
      <div class="form-group">
        <label class="control-label col-sm-4" for="company">$sitetxt{retour_iban}:</label>
        <div class="col-sm-8">
          <input type="text" name="retour_iban"  value="" class="input-xlarge  form-control" /> 
        </div>
      </div>
            
      <div class="form-group">
        <label class="control-label col-sm-4" for="company">$sitetxt{retour_bic} :</label>
        <div class="col-sm-8">
          <input type="text" name="retour_bic"  value="" class="input-xlarge  form-control" /> 
        </div>
      </div>         
        
      <div class="form-group">
        <div class="col-sm-4"></div>
        <div class="col-sm-8">
          <button type="submit" class="btn btn-info">$sitetxt{retour_submit}</button>
        </div>
      </div>
    </form>

HTML

  return $page;
}

################################################################################
# simplifier
################################################################################ 
sub simplifier
{
    my $nom = $_[0];
    if($_[1] eq 'with_spaces')
    {
        if($_[2] eq 'plus_spaces')
        {
            if($_[3] eq 'avec_accents')
            {
                $nom =~ s/[^éàùèâêîôïöëa-zA-Z0-9\s]+/ /g;
            }
            else
            {
                $nom =~ s/[^a-zA-Z0-9\s]+/ /g;
            }
        }
        else
        {
            $nom =~ s/[^a-zA-Z0-9\s]+//g;
        }
    }
    else
    {
        $nom =~ s/[^a-zA-Z]+//g;
    }
    return $nom;
}




################################################################################
# get_adresses_fields
################################################################################
sub get_adresses_fields
{
  my $prefixe = $_[0];

  my @champs;
  if($config{custom_adresses_form} eq "y")
  {
    @champs = @{def_handmade::get_custom_adresses_fields($prefixe)}; 
  }
  else
  {
    @champs = 
    (
      {
        name => $prefixe.'firstname',
        label => $sitetxt{eshop_firstname},
        required => 'required',
        display => $display_fields_simplify
      }
      ,
      {
        name => $prefixe.'lastname',
        label => $sitetxt{eshop_lastname},
        required => 'required',
      }
      ,
      {
        name => $prefixe.'company',
        label => $sitetxt{eshop_company},
      }
      ,
      {
        name => $prefixe.'vat',
        label => $sitetxt{eshop_vat},
        hint => "$sitetxt{eshop_exemple}: BE123456789",
        suppl => $suppl_erreur_intracom_delivery,
      }
      ,
      {
        type=> $prefixe.'google_search'
      }
      ,
      {
        name => $prefixe.'street',
        label => $sitetxt{eshop_street},
        required => 'required',
        class =>  $prefixe.'google_map_route',
      }
      ,
      {
        name => $prefixe.'number',
        label => $sitetxt{eshop_number},
        class => 'input-small',
        class =>  $prefixe.'google_map_street_number',
        display => $display_fields_simplify,
        required => 'required',
      }
      ,
      {
        name => $prefixe.'box',
        label => $sitetxt{eshop_box},
        class => 'input-small',
        display => $display_fields_simplify,
      }
      ,
      {
        name => $prefixe.'zip',
        label => $sitetxt{eshop_zip},
        class => 'input-small',
        required => 'required',
        class =>  $prefixe.'google_map_postal_code',
      }
      ,
      {
        name => $prefixe.'city',
        label => $sitetxt{eshop_city},
        class => 'input-small',
        required => 'required',
        class =>  $prefixe.'google_map_locality',
      }
      ,
      {
        name => $prefixe.'country',
        type => 'countries_list',
        label => $sitetxt{eshop_country},
        class => 'select_country',
        required => 'required',
        class =>  $prefixe.'google_map_country',
      }
      ,
      {
        name => $prefixe.'phone',
        label => $sitetxt{eshop_tel},
        required => 'required',
      }
      ,
      {
        name => $prefixe.'email',
        type => 'email',
        label => $sitetxt{eshop_email},
        required => 'required',
      }
    );
  }

  return \@champs;

}

################################################################################
# change_status
################################################################################  
sub change_status
{
    my %d = %{$_[0]};
    my %order = %{$d{order}};
    if($d{status} ne '')
    {
         $stmt = "UPDATE eshop_orders SET status='$d{status}' where id=$order{id}";
         execstmt($dbh,$stmt);       
    }
    if($d{payment_status} ne '')
    {
         $stmt = "UPDATE eshop_orders SET payment_status='$d{payment_status}' where id=$order{id}";
         execstmt($dbh,$stmt);       
    }
    if($d{delivery_status} ne '')
    {
         $stmt = "UPDATE eshop_orders SET delivery_status='$d{delivery_status}' where id=$order{id}";
         execstmt($dbh,$stmt);       
    }
	
		members::member_add_event({group=>'eshop',type=>"change_status",name=>"Changement des statuts de la commande: <span>Statut: $d{status}<br>Paiement: $d{payment_status}<br>Livraison: $d{delivery_status}</span>",detail=> $order{id}});
}

################################################################################
# edit_identy_db
################################################################################  
sub edit_identity_db
{
    my %member = %{members::members_get()}; 
    if(!($member{id} > 0))
    {
      cgi_redirect($config{fullurl}. "/" . $sws{member_login}{$lg});
    }

    my @champs_identity = @{get_identities_fields()};   

    my %update_identity = ();
    $create_identity{id_member} = $member{id};
    foreach my $champ_identity (@champs_identity)
    {
      %champ_identity = %{$champ_identity};
      $update_identity{$champ_identity{name}} = get_quoted($champ_identity{name});
    }

    $update_identity{token} = get_quoted("token");
    $update_identity{id_identity} = get_quoted("id_identity");

    
    #vérifie token
    my %check_identity = sql_line({table=>'identities',where=>"UPPER(token) = UPPER('$update_identity{token}') AND token != ''"});
    if($check_identity{id} > 0 && $check_identity{id} == $update_identity{id_identity})
    {
    }
    else
    {
        # On créé l'identities
        my $id_member = members::get_id_member();

        if($id_member > 0)
        {
            my %new_identity = (
                id_member     => $id_member,
                token         => create_token(50),
                identity_type => get_quoted("type"),
            );

            # On l'ajoute en DB
            my $id_new_identity = inserth_db($dbh,"identities",\%new_identity); 
            # On la récupère
            %check_identity = sql_line({table=>'identities',where=>"id= '$id_new_identity'"});

            # On met à jour migcms_member
            my $col;
            if($new_identity{identity_type} eq "delivery")
            {
                $col = "id_delivery_identity";
            }
            elsif($new_identity{identity_type} eq "billing")
            {
                $col = "id_bill_identity";
            }
            
            my $stmt = <<"SQL";
                UPDATE migcms_members
                    SET $col = $id_new_identity
                    WHERE id = $id_member
SQL
            execstmt($dbh,$stmt);
        }
        else
        {
            see();
        print<<"EOH";
            <script language="javascript">
            alert("Merci de vous connecter à votre compte");
            history.go(-1);
            </script>
EOH
        exit;
        }
        
    }
    
    delete $update_identity{id_identity};
    delete $update_identity{token};
    delete $update_identity{type};
    
    updateh_db($dbh,"identities",\%update_identity,'id',$check_identity{id});

    # Fonction post edit identity
    exec_post_edit_identity({update_data => \%update_identity, id_identity => $check_identity{id}});

    my $url_after_edit = get_quoted("url_after_edit");
    cgi_redirect($url_after_edit);
}

sub exec_post_edit_identity
{
  my %d = %{$_[0]};

  if ($setup{post_edit_identity_func} ne "")
  {
    my $post_edit_identity_func = 'def_handmade::'.$setup{post_edit_identity_func};
    &$post_edit_identity_func(\%d);
        
  }
  else
  {
  }
}

################################################################################
# display_price
################################################################################
sub display_price
{
  my $value = $_[0];

  my $devise = "€";

  if($config{devise} ne "")
  {
    $devise = $config{devise};
  }

  $value = round($value*100)/100;
  $value = sprintf("%.2f",$value);
  return $value." $devise";
}

################################################################################
# display_price
################################################################################
sub display_price3
{
  my $value = $_[0];

  my $devise = "";

  # if($config{devise} ne "")
  # {
    # $devise = $config{devise};
  # }

  $value = round($value*1000)/1000;
  $value = sprintf("%.3f",$value);
  return $value." $devise";
}

################################################################################
# display_price
################################################################################
sub display_price4
{
  my $value = $_[0];

  my $devise = "";

  # if($config{devise} ne "")
  # {
    # $devise = $config{devise};
  # }

  $value = round($value*10000)/10000;
  $value = sprintf("%.4f",$value);
  return $value." $devise";
}

################################################################################
# display_price
################################################################################
sub display_price5
{
  my $value = $_[0];

  my $devise = "";

  # if($config{devise} ne "")
  # {
    # $devise = $config{devise};
  # }

  $value = round($value*100000)/100000;
  $value = sprintf("%.5f",$value);
  return $value." $devise";
}

################################################################################
# display_price
################################################################################
sub display_price2
{
  my $value = $_[0];

  my $devise = "";

  # if($config{devise} ne "")
  # {
    # $devise = $config{devise};
  # }

  $value = round($value*100)/100;
  $value = sprintf("%.2f",$value);
  return $value." $devise";
}


################################################################################
# reset_bpost_compute
# 
# Remet à "n" la colonne qui indique que Bpost a calculé les frais de port
# (bpost_total_delivery_computed)
################################################################################
sub reset_bpost_compute
{
  my %d = %{$_[0]};

  my %order = %{$d{order}};
  members::member_add_event({group=>'eshop',type=>"reset_bpost_compute",name=>"BPOST TOTAL DELIVERY COMPUTED : [n]",detail=> $order{id}});

  if($order{id} > 0 && $order{delivery} eq "bpost")
  {
    my $stmt = <<"EOH";
      UPDATE eshop_orders
        SET bpost_total_delivery_computed = "n"
        WHERE id = "$order{id}"
EOH
    execstmt($dbh, $stmt);    
  }

  return \%order;
}


sub historique
{
	my $dbh = $_[0];
	my $id = $_[1];

	my @migcms_members_events = sql_lines({table=>'migcms_members_events',where=>"group_type_event = 'eshop' AND detail_evt='$id'",ordby=>"id desc"});
	
	my $taches = "";
	
	my %corr_types = (
	'eshop_mailing_confirmation' => 'Email au client',
	'change_status' => 'Changement de statut',
	'pay_start' => 'Début du paiement',
	'recap_db' => 'Récapitulatif validé',
	'eshop_bpost_callback' => 'Retour de Bpost',
	'addresses_db' => 'Coordonneés enregistrées',
	'add_cart' => 'Ajout au panier',
	'create_eshop_order' => 'Création',
	);
	
	my @types_interdits = qw
	(
		reset_bpost_compute
	);
	
	$taches .= <<"EOH";
	<table class="table table-hover table-border table-striped">
		<thead>
			<tr>
				<th>
					Date
				</th>
				<th>
					Type
				</th>
				<th>
					Nom
				</th>
			</tr>
		</thead>
		<tbody>
EOH
	foreach $migcms_members_event (@migcms_members_events)
	{
		my %migcms_members_event = %{$migcms_members_event};
		my $interdit = 0;
		foreach my $types_interdit (@types_interdits)
		{
			if($types_interdit eq $migcms_members_event{type_evt})
			{
				$interdit = 1;
			}
		}
		
		if($interdit == 1)
		{
			next;
		}
		
		$migcms_members_event{date_event} = to_ddmmyyyy($migcms_members_event{date_event});
		
		$handmade_alias_tache{description} =~ s/\r*\n/\<br\/\>/g;
		if($corr_types{$migcms_members_event{type_evt}} ne '')
		{
			$migcms_members_event{type_evt} = $corr_types{$migcms_members_event{type_evt}};
		}
		
		$taches .= <<"EOH";
				<tr>
					<td>
						$migcms_members_event{date_event} $migcms_members_event{time_event}
					</td>
					<td>
						$migcms_members_event{type_evt}
					</td>
					<td>
						$migcms_members_event{nom_evt}
					</td>
				</tr>
EOH
	}
		$taches .= <<"EOH";
		</tbody>
	</table>
	
	<script>
	jQuery(document).ready(function() 
	{
		

	});
	</script>
EOH
}

sub utilisation_coupons
{

	my $id = $_[1];

	my $page = "<br /><br /><h2>Journal d'utilisation des coupons pour cette règle: </h2>";
	$page .= '<table class="table">';
	$page .= '<tr><th>Date</th><th>N°Commande</th><th>Coupon utilisé</th></tr>';

	my @coupon_journals = sql_lines({table=>'coupon_journal',where=>"id_eshop_discount='$id'",ordby=>"date_utilisation desc"});

	foreach $coupon_journal (@coupon_journals)
	{
		my %coupon_journal = %{$coupon_journal};


		$coupon_journal{date_utilisation} = to_ddmmyyyy($coupon_journal{date_utilisation},'withtime');
		$page .= "<tr><td>$coupon_journal{date_utilisation}</td><td>$coupon_journal{id_eshop_order}</td><td>$coupon_journal{coupon_txt}</td></tr>";

	}


	$page .= "</table>";

	return $page;
}
1;