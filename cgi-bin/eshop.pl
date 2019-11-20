#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;
use DBI;
use def;
use tools; 
use migcrender; 
use eshop;
use sitetxt;
use members;
use JSON::XS;
use def_handmade;

use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);


my %setup = %{get_setup()};

my $lg = get_quoted('lg');
if($lg > 0 && $lg <= 10)
{
	#ok
}
else
{
	$lg = 1;
}
#see();
#print $lg;
#exit;
$config{current_language} = $config{default_colg} = $lg;

my $sw = get_quoted('sw');

$config{eshop_col_left_class} = $config{eshop_col_right_class} = 'col-md-6';

my $secure_msg = <<"EOH";
<div class="eshop_secure_msg">
	<span>$sitetxt{eshop_secure_msg}</span>
</div>
<div class="pull-left" id="secure-paiement-label">
	<h2>$sitetxt{'eshop_secure_title'}</h2>
	<p>$sitetxt{'eshop_secure_text'}</p>
</div>
EOH

#fonctions autorisées
my @fcts = qw(
cart
get_cart
get_mini_cart
get_micro_cart
login
add_cart
recompute_order
lightbox_confirmation
edit_cart_qty
delete_detail_line
);

if(is_in(@fcts,$sw)) 
{ 
    &$sw();
	exit;
}
see();
print 'acces interdit';
exit;
       
################################################################################
# CART
################################################################################
sub cart
{
	 see();
	 
	 my %order = %{get_eshop_order()};
	 
	 member_add_event({group=>'eshop',type=>"etape",name=>"<b>Ecran du panier</b>",detail=> $order{id}});


	if($order{id} > 0)
	{
	 	# Remise à "n" de la colonne qui indique 
		# si Bpost a calculé les frais de port
		%order = %{reset_bpost_compute({order=>\%order})};	 	
 	}

	 #poursuivre vos achats
	 # my $referer = "<a href=\"$config{baseurl}.'/'.$order{referer}\" class=\"btn btn-info\">$sitetxt{retour_achat}</a>";
	 my $referer = "<a href=\"$order{referer}\" class=\"btn btn-info eshop_go_back\">$sitetxt{retour_achat}</a>";
	 if($order{referer} eq '')
	 {
		$referer = '';
	 }
	 
	 #bloc coupons
	 my $form_coupons = <<"EOH";
	 <div class="form-inline">
						<div class="form-group">
							<label class="control-label">$sitetxt{'eshop_cart_11'} :</label>
						</div>
						<div class="form-group">
							<input type="text" name="coupon" id="coupon"  class="form-control" placeholder="$sitetxt{'eshop_cart_11'}" />
						</div>
						<div class="form-group">
							<button type="submit" class="btn btn-info save_coupon">$sitetxt{'eshop_cart_10'}</button>
						</div>
					</div>
EOH
	if($setup{coupons_disabled} eq 'y') { $form_coupons = ''; }


	#panier: lignes,coupons et total
	 my $page =<<"EOH";
	<div id="eshop" class="$config{eshop_col_container_class} clearfix">
		<div class="$config{eshop_col_center_class}">
			
			<!-- titre -->
			<h1><span><span>$sitetxt{eshop_cart_title}</span></span></h1>
			
			<!-- poursuivre vos achats -->
			<div class=" pull-left clearfix">
				$referer						
			</div>
			
			<div class="cart-buttons pull-right clearfix">
				<a href="$config{baseurl}/$sitetxt{eshop_url_login}" class="btn btn-info hide eshop_go_to_login eshop_go_to_login_top">$sitetxt{eshop_cart_identificationlink}</a>
			</div>
			
			<!-- lignes du panier -->
			<div id="eshop_cart_lines">
			</div>
            
			<!-- total du panier -->
			<div class="cart-recap clearfix">
				<div class="cart-coupon $config{eshop_col_left_class}">
					$form_coupons
					<p id="coupons_list">
					
					</p>          
				</div>
				<div id="eshop_mini_cart" class="cart-recap-prices $config{eshop_col_right_class}">
				</div>
            </div>
			
			<div class="secure-msg-container col-md-offset-6 col-md-6">
				$secure_msg
				</div>
			<div class="cart-buttons pull-right clearfix">
				<a href="$config{baseurl}/$sitetxt{eshop_url_login}" class="btn btn-info hide eshop_go_to_login eshop_go_to_login_bottom">$sitetxt{eshop_cart_identificationlink}</a>
			</div>
			
			</form>
		</div>
	</div>
	

EOH
		display($page);
}


################################################################################
# LOGIN
################################################################################
sub login
{
# 	see();
# print $config{fullurl};
# exit;
		link_order_and_continue_if_logged();
		see();
		
		my %member_setup = %{member_get_setup({lg=>$lg})};
		
		my $error = get_quoted("error");
		$error_msg;
		if($error eq "50")
		{
			$error_msg = <<"EOH";
        <div class="alert alert-block alert-error alert-danger">
	        <p>$sitetxt{login_error_msg}</p>
	      </div>
EOH
		}

		my $additionnal_header_msg;
		if($config{additionnal_header_msg_login_eshop} ne "")
		{
			my $func = 'def_handmade::'.$config{additionnal_header_msg_login_eshop};
      $additionnal_header_msg = &$func();
		}


		#login form
		my $login_form = members::member_html_login_form({
			url_after_login => $config{fullurl}.'/'.$sitetxt{eshop_url_addresses},
			url_after_error => $config{fullurl}.'/cgi-bin/eshop.pl?sw=login',
			lg => $lg
		});
		
		#continuer en tant qu'invite
		my $continuer_en_invite;
		if($setup{login_obligatoire} ne 'y')
		{
			$continuer_en_invite = <<"EOH";
				<div class="newaccount-form">
					<h1 class="maintitle"><span>$sitetxt{eshop_identification_title_pas_encore_client}</span></h1>
					<p>$sitetxt{eshop_identification_txt_pas_encore_client}</p>
					<a class="btn btn-info" href="$config{baseurl}/$sitetxt{eshop_url_addresses}">$sitetxt{eshop_identification_txt_pas_encore_client_link_continue}</a>
				</div>
EOH
		}
		
		if($setup{login_obligatoire} ne 'y')
		{
			member_add_event({group=>'eshop',type=>"etape",name=>"<b>Ecran connexion ou continuer en invité</b>",detail=> $order{id}});

			$page = <<"EOH";				
				$error_msg
				$additionnal_header_msg
				<div id="eshop" class="$config{eshop_col_container_class} clearfix">
					$social_button
					<div class="$config{eshop_col_left_class}">
						$login_form
					</div>
					<div class="$config{eshop_col_right_class}">
						$continuer_en_invite
					</div>
				</div>	 	 
EOH
		}
		else
		{
				 member_add_event({group=>'eshop',type=>"etape",name=>"<b>Ecran du login obligatoire</b>",detail=> $order{id}});

			$page = <<"EOH";
				$error_msg
				$additionnal_header_msg
				<div id="eshop" class="$config{eshop_col_container_class} clearfix">
					$social_button
					<div class="$config{eshop_col_center_class}">
						$login_form
					</div>
				</div>  	  	  
				$secure_msg
EOH
		}

		display($page);
}


################################################################################
# addresses
################################################################################
sub addresses 
{
	see();
    my %order = %{get_eshop_order()};
	my %member = %{members::members_get()};
				 member_add_event({group=>'eshop',type=>"etape",name=>"<b>Ecran coordonnées</b>",detail=> $order{id}});

    my $id_member = $member{id};
	

	if($member{member_type} eq 'Commande directe')
	{	
		http_redirect("$self$sws{methodes}{$lg}");
		exit;
	}

	my $err = get_quoted('err');
	my $viesoff = get_quoted('viesoff');
	if($viesoff != 1)
	{
		$sitetxt{viesoff} = '';
	}


	
	#DELIVERY FORM ---------------------------------------------
	
	#gestion erreurs TVA INTRACOMM-------------------------------------------
	my $suppl_erreur_intracom_delivery = '';
	if($err eq 'vat' || ($order{delivery_vat_status} == 2 && $order{delivery_vat} ne '' && $order{do_intracom} eq 'y'))
	{
		$suppl_erreur_intracom_delivery = <<"EOH";
			<div class="alert alert-block alert-error alert-danger">
				$sitetxt{eshop_error_tva_intracom}<br /><br />
				$sitetxt{viesoff}
			</div>         
EOH
	}
	
	my @champs = @{eshop::get_adresses_fields("delivery_")};

	my $size = @champs;
    for (my $i=0 ; $i<$size ; $i++)
    {
    	$champs[$i]->{valeurs} = \%order;
    }

	my $delivery_form = eshop_get_form(\@champs,"delivery");
	
	#DELIVERY FORM ---------------------------------------------
	
	#gestion erreurs TVA INTRACOMM-------------------------------------------
	my $suppl_erreur_intracom_billing = '';
	if($order{billing_vat_status} == 2 && $order{billing_vat} ne '' && $order{do_intracom} eq 'y')
	{
		$suppl_erreur_intracom_billing = <<"EOH";
			<div class="alert alert-block alert-error alert-danger">
				$sitetxt{eshop_error_tva_intracom} 
			</div>         
EOH
	}
	
	#TABLEAU DES CHAMPS (FACTURATION)
	my @champs = @{eshop::get_adresses_fields("billing_")};
	
	my $size = @champs;
    for (my $i=0 ; $i<$size ; $i++)
    {
    	$champs[$i]->{valeurs} = \%order;
    }
    
	my $billing_form = eshop_get_form(\@champs,"billing");

	
   
	#checkbox memes adresses
	my $checked = '';
	# see(\%order);
	
	my %same_identities = sql_line({dbh=>$dbh, table=>"identities", select=>"same_identities", where=>"id_member = '$order{id_member}'", limit=>1});	

    if(($order{delivery_same_identities} eq 'y' || ($order{id_member} == 0 && $order{billing_updated} ne 'y') || $same_identities{same_identities} eq "y"))
    {
         $checked = ' checked = "checked" ';
    }

	#checkbox intracomm
    my $checked_do_intracom = '';    
    if($order{do_intracom} eq 'y')
    {
         $checked_do_intracom = ' checked = "checked" ';
    }
	
	#checkbox do_fact
    my $checked_do_fact = '';    
    if($order{do_fact} eq 'y')
    {
         $checked_do_fact = ' checked = "checked" ';
    }
    
	#erreur champs obligatoire manquant
    my $erreur = get_quoted('erreur');
    my $erreur_champ = get_quoted('champ') || get_quoted("f");
    $erreur_champ =~ s/delivery_//g;
    $erreur_champ = $sitetxt{'eshop_'.$erreur_champ};
    my $erreur_msg = '';
    if($erreur ne '' || $err eq "fie")
    {
        $erreur_msg = <<"EOH";
			<div class="alert alert-block alert-error alert-danger">
				<h4 class="alert-heading">Champ obligatoire.</h4>
				<p>Merci de compléter le champ obligatoire <b>$erreur_champ</b> svp....</p>
			</div>
EOH
    }
    
	#breadcrumb
	my $breadcrumb = '<div id="eshop-breadcrumb">'.eshop::get_breadcrumb(1,2).'</div>';
    if($setup{disable_breadcrumb} eq 'y')
    {
       $breadcrumb = ''; 
    }

    # Facture intracom
    my $checkbox_intracom = <<"HTML";
    	<div class="form-group group_intracom">
			<div class="control-label col-sm-4"></div>
			<div class="col-sm-8">
				<label class="checkbox"><input type="checkbox" value="y" $checked_do_intracom name="do_intracom" />$sitetxt{'eshop_do_intracom_label'} ( <i class="eshop_tooltip" data-toggle="tooltip" data-placement="right" data-placement="bottom" title="$sitetxt{'eshop_do_intracom_txt'}">?</i> ) </label>
			</div>
		</div>
HTML
	if($setup{frontend_disabled_intraco} eq "y")
	{
		$checkbox_intracom = "";
	}
	
	# Je souhaite une facture
	my $checkbox_facture = <<"HTML";
    	<div class="form-group group_fact">
			<div class="control-label col-sm-4"></div>
			<div class="col-sm-8">
				<label class="checkbox"><input type="checkbox" value="y" $checked_do_fact name="do_fact" />$sitetxt{'eshop_do_fact_label'}  </label>
			</div>
		</div>
HTML
	if($setup{frontend_disabled_facture} eq "y")
	{
		$checkbox_facture = "";
	}
	
	
	my $page_content = "";
	
	if($setup{frontend_show_delivery_billing_form} eq "y") {
	
		$page_content = <<"EOH";

		$breadcrumb

		$link_back    

		$erreur_msg
		$suppl_erreur_intracom_delivery
		$suppl_erreur_intracom_billing
		
		<form method="post" id="form-addresses" class="form-horizontal" action="$script_self"  enctype="multipart/form-data">
		
			<div id="eshop" class="$config{eshop_col_container_class} clearfix">
				
				<div class="$config{eshop_col_left_class}">

				
					<input type="hidden" name="sw" value = "addresses_db" />     
					<input type="hidden" name="lg" value = "$lg" />  
					<input type="hidden" id="delivery_same_identities" name="delivery_same_identities" value="n" />
					
					<h1><span>$sitetxt{'eshop_metatitle_addresses_livraison'}</span></h1>
					$delivery_form 
					
					$checkbox_intracom

					$checkbox_facture					
					
				</div>
			
				<div class="$config{eshop_col_right_class}">
					
					<h1><span>$sitetxt{'eshop_metatitle_addresses_facturation'}</span></h1>
					$billing_form

				</div>
				
			</div>
			<div id="eshop" class="$config{eshop_col_container_class} clearfix">
				
				<div class="col-md-12">
				
					<div class="text-right">
						<button type="submit" class="btn btn-info">$sitetxt{'eshop_etape_suivante'}</button>
					</div>

					<div class="recap-form">
						<h1><span>$sitetxt{'eshop_order_resume'}</span></h1>
						<div id="eshop_mini_cart" class="recap-prices">
							$recap
						</div>
					</div>
					
					$secure_msg
				
				</div>
				
			</div>
		</form>
		
<style type="text/css">
	.recap-form {
		display : block !important;
	}
</style>
EOH
	
	}
	else {
	
		$page_content = <<"EOH";

		$breadcrumb

		$link_back    

		$erreur_msg
		$suppl_erreur_intracom_delivery
		$suppl_erreur_intracom_billing
		
		<form method="post" id="form-addresses" class="form-horizontal" action="$script_self"  enctype="multipart/form-data">
		
			<div id="eshop" class="$config{eshop_col_container_class} clearfix">
				
				<div class="$config{eshop_col_left_class}">

				
					<input type="hidden" name="sw" value = "addresses_db" />     
					<input type="hidden" name="lg" value = "$lg" />  
					
					<h1><span>$sitetxt{'eshop_metatitle_addresses_livraison'}</span></h1>
					$delivery_form

					<div class="form-group group_sameidentities">
						<div class="control-label col-sm-4 col-sm-4"></div>
						<div class="col-sm-8">
							<label class="checkbox"><input type="checkbox" value="y" $checked id="delivery_same_identities" name="delivery_same_identities" />$sitetxt{'eshop_delivery_1'} </label>						
						</div>
					</div>    
					
					$checkbox_intracom

					$checkbox_facture
					
					<div class="group_intracom_left_container">
					</div>
					
					
					
					<div class="form-group zone_formulaire_livraison_seul">
						<div class="control-label col-sm-4"></div>
						<div class="col-sm-8">
							<button type="submit" class="btn btn-info">$sitetxt{'eshop_etape_suivante'}</button>
						</div>
					</div>
					
				</div>
			
			<div class="$config{eshop_col_right_class}">
				
				<div id="zone_formulaire_facturation" class="hide">
					<h1><span>$sitetxt{'eshop_metatitle_addresses_facturation'}</span></h1>
					$billing_form
					
					<div class="group_intracom_right_container">
					</div>
					
					<div class="form-group">
						<div class="control-label col-sm-4"></div>
						<div class="col-sm-8">
							<button type="submit" class="btn btn-info">$sitetxt{'eshop_etape_suivante'}</button>
						</div>
					</div>
					
				</div>
				<div class="recap-form">
					<h1><span>$sitetxt{'eshop_order_resume'}</span></h1>
					<div id="eshop_mini_cart" class="recap-prices">
						$recap
					</div>
				</div>
				
				$secure_msg
			</div>			
		</div>
	  </form>
EOH
	
	}
      
    display($page_content,'',$setup{id_tpl_page2});
}

################################################################################
# addresses
################################################################################
sub addresses_old
{
	see();
	
	my %order = %{get_eshop_order()};

	my $err = get_quoted('err');
	my $viesoff = get_quoted('viesoff');
	if($viesoff != 1)
	{
		$sitetxt{viesoff} = '';
	}
	
	#DELIVERY FORM ---------------------------------------------
	
	#gestion erreurs TVA INTRACOMM-------------------------------------------
	my $suppl_erreur_intracom_delivery = '';
	if($err eq 'vat' || ($order{delivery_vat_status} == 2 && $order{delivery_vat} ne '' && $order{do_intracom} eq 'y'))
	{
		$suppl_erreur_intracom_delivery = <<"EOH";
			<div class="alert alert-block alert-error alert-danger">
				$sitetxt{eshop_error_tva_intracom}<br /><br />
				$sitetxt{viesoff}
			</div>         
EOH
	}

	#TABLEAU DES CHAMPS (LIVRAISON)
	my $prefixe = 'delivery_';
	my @champs = 
	(
		{
			name => $prefixe.'firstname',
			label => $sitetxt{eshop_firstname},
			required => 'required',
			valeurs => \%order,
		}
		,
		{
			name => $prefixe.'lastname',
			label => $sitetxt{eshop_lastname},
			required => 'required',
			valeurs => \%order,
		}
		,
		{
			name => $prefixe.'company',
			label => $sitetxt{eshop_company},
			valeurs => \%order,
		}
		,
		{
			name => $prefixe.'vat',
			label => $sitetxt{eshop_vat},
			hint => "($sitetxt{eshop_exemple}: BE123456789)",
			suppl => $suppl_erreur_intracom_delivery,
			valeurs => \%order,
		}
		,
		{
			type=> 'delivery_google_search'
		}
		,
		{
			name => $prefixe.'street',
			label => $sitetxt{eshop_street},
			required => 'required',
			valeurs => \%order,
			class =>  'delivery_google_map_route',
		}
		,
		{
			name => $prefixe.'number',
			label => $sitetxt{eshop_number},
			class => 'input-small',
			valeurs => \%order,
			class =>  'delivery_google_map_street_number',
		}
		,
		{
			name => $prefixe.'box',
			label => $sitetxt{eshop_box},
			class => 'input-small',
			valeurs => \%order,
		}
		,
		{
			name => $prefixe.'zip',
			label => $sitetxt{eshop_zip},
			class => 'input-small',
			required => 'required',
			valeurs => \%order,
			class =>  'delivery_google_map_postal_code',
		}
		,
		{
			name => $prefixe.'city',
			label => $sitetxt{eshop_city},
			class => 'input-small',
			required => 'required',
			valeurs => \%order,
			class =>  'delivery_google_map_locality',
		}
		,
		{
			name => $prefixe.'country',
			type => 'countries_list',
			label => $sitetxt{eshop_country},
			class => 'select_country delivery_google_map_country',
			required => 'required',
			valeurs => \%order,
		}
		,
		{
			name => $prefixe.'phone',
			label => $sitetxt{eshop_tel},
			required => 'required',
			valeurs => \%order,
		}
		,
		{
			name => $prefixe.'email',
			type => 'email',
			label => $sitetxt{eshop_email},
			required => 'required',
			valeurs => \%order,
		}
	);
	my $delivery_form = build_form({fields=>\@champs, lg=>$lg});

	#DELIVERY FORM ---------------------------------------------
	
	#gestion erreurs TVA INTRACOMM-------------------------------------------
	my $suppl_erreur_intracom_billing = '';
	if($order{billing_vat_status} == 2 && $order{billing_vat} ne '' && $order{do_intracom} eq 'y')
	{
		$suppl_erreur_intracom_billing = <<"EOH";
			<div class="alert alert-block alert-error alert-danger">
				$sitetxt{eshop_error_tva_intracom} 
			</div>         
EOH
	}
	
	#TABLEAU DES CHAMPS (FACTURATION)
	my $prefixe = 'billing_';
	my @champs = 
	(
		{
			name => $prefixe.'firstname',
			label => $sitetxt{eshop_firstname},
			required => 'required',
			valeurs => \%order,
		}
		,
		{
			name => $prefixe.'lastname',
			label => $sitetxt{eshop_lastname},
			required => 'required',
			valeurs => \%order,
		}
		,
		{
			name => $prefixe.'company',
			label => $sitetxt{eshop_company},
			valeurs => \%order,
		}
		,
		{
			name => $prefixe.'vat',
			label => $sitetxt{eshop_vat},
			hint => "($sitetxt{eshop_exemple}: BE123456789)",
			suppl => $suppl_erreur_intracom_deliver,
			valeurs => \%order,
		}
		,
		{
			type=> 'billing_google_search'
		}
		,
		{
			name => $prefixe.'street',
			label => $sitetxt{eshop_street},
			required => 'required',
			valeurs => \%order,
			class =>  'billing_google_map_route',
		}
		,
		{
			name => $prefixe.'number',
			label => $sitetxt{eshop_number},
			class => 'input-small',
			valeurs => \%order,
			class =>  'billing_google_map_street_number',
		}
		,
		{
			name => $prefixe.'box',
			label => $sitetxt{eshop_box},
			class => 'input-small',
			valeurs => \%order,
		}
		,
		{
			name => $prefixe.'zip',
			label => $sitetxt{eshop_zip},
			class => 'input-small',
			required => 'required',
			valeurs => \%order,
			class =>  'billing_google_map_postal_code',
		}
		,
		{
			name => $prefixe.'city',
			label => $sitetxt{eshop_city},
			class => 'input-small',
			required => 'required',
			valeurs => \%order,
			class =>  'billing_google_map_locality',
		}
		,
		{
			name => $prefixe.'country',
			type => 'countries_list',
			label => $sitetxt{eshop_country},
			class => 'select_country',
			required => 'required',
			valeurs => \%order,
			class =>  'billing_google_map_country',
		}	
		,
		{
			name => $prefixe.'phone',
			label => $sitetxt{eshop_tel},
			required => 'required',
			valeurs => \%order,
		}
		,
		{
			name => $prefixe.'email',
			type => 'email',
			label => $sitetxt{eshop_email},
			required => 'required',
			valeurs => \%order,
		}
	);

	my $billing_form = build_form({fields=>\@champs, lg=>$lg});

	#checkbox memes adresses
	my $checked = '';
    if(($order{delivery_same_identities} eq 'y' || ($order{id_member} == 0 && $order{billing_updated} ne 'y')))
    {
         $checked = ' checked = "checked" ';
    }

	#checkbox intracomm
    my $checked_do_intracom = '';    
    if($order{do_intracom} eq 'y')
    {
         $checked_do_intracom = ' checked = "checked" ';
    }
	
	#checkbox do_fact
    my $checked_do_fact = '';    
    if($order{do_fact} eq 'y')
    {
         $checked_do_fact = ' checked = "checked" ';
    }
    
	#erreur champs obligatoire manquant
    my $erreur = get_quoted('erreur');
    my $erreur_champ = get_quoted('champ');
    $erreur_champ =~ s/delivery_//g;
    $erreur_champ = $sitetxt{'eshop_'.$erreur_champ};
    my $erreur_msg = '';
    if($erreur ne '')
    {
        $erreur_msg = <<"EOH";
			<div class="alert alert-block alert-error alert-danger">
				<h4 class="alert-heading">Champ obligatoire.</h4>
				<p>Merci de compléter le champ obligatoire <b>$erreur_champ</b> svp....</p>
			</div>
EOH
    }
    
	#breadcrumb
	my $breadcrumb = '<div id="eshop-breadcrumb">'.get_breadcrumb(1,2).'</div>';
    if($setup{disable_breadcrumb} eq 'y')
    {
       $breadcrumb = ''; 
    }
      
    my $page_content = <<"EOH";

		$breadcrumb

		$link_back    

		$erreur_msg
		
		<form method="post" id="form-addresses" class="form-horizontal" action="$sitetxt{eshop_boutique_general}"  enctype="multipart/form-data">
			<div id="eshop" class="$config{eshop_col_container_class} clearfix">
				<div class="$config{eshop_col_left_class}">
					<input type="hidden" name="sw" value = "addresses_db" />     
					<input type="hidden" name="lg" value = "$lg" />  
					<h1><span>$sitetxt{eshop_metatitle_addresses_livraison}</span></h1>
					$delivery_form
					<div class="form-group group_sameidentities">
						<div class="control-label col-sm-4 col-sm-4"></div>
						<div class="col-sm-8">
							<label class="checkbox"><input type="checkbox" value="y" $checked id="delivery_same_identities" name="delivery_same_identities" />$sitetxt{'eshop_delivery_1'} </label>						
						</div>
					</div>    
					<div class="form-group group_intracom">
						<div class="control-label col-sm-4"></div>
						<div class="col-sm-8">
							<label class="checkbox"><input type="checkbox" value="y" $checked_do_intracom name="do_intracom" />$sitetxt{'eshop_do_intracom_label'} ( <i class="eshop_tooltip" data-toggle="tooltip" data-placement="right" data-placement="bottom" title="$sitetxt{'eshop_do_intracom_txt'}">?</i> ) </label>
						</div>
					</div>
					<div class="form-group group_fact">
						<div class="control-label col-sm-4"></div>
						<div class="col-sm-8">
							<label class="checkbox"><input type="checkbox" value="y" $checked_do_fact name="do_fact" />$sitetxt{'eshop_do_fact_label'}  </label>
						</div>
					</div>
					<div class="group_intracom_left_container">
					</div>
					<div class="form-group zone_formulaire_livraison_seul">
						<div class="control-label col-sm-4"></div>
						<div class="col-sm-8">
							<button type="submit" class="btn btn-info">$sitetxt{'eshop_etape_suivante'}</button>
						</div>
					</div>
				</div>
			<div class="$config{eshop_col_right_class}">
				<div id="zone_formulaire_facturation" class="hide">
					<h1><span>$sitetxt{'eshop_metatitle_addresses_facturation'}</span></h1>
					$billing_form
					<div class="group_intracom_right_container">
					</div>
					<div class="form-group">
						<div class="control-label col-sm-4"></div>
						<div class="col-sm-8">
							<button type="submit" class="btn btn-info">$sitetxt{'eshop_etape_suivante'}</button>
						</div>
					</div>
				</div>
				<div class="recap-form">
					<h1><span>$sitetxt{'eshop_order_resume'}</span></h1>
					<div id="eshop_mini_cart">
					</div>
				</div>
				$secure_msg
			</div>			
		</div>
	  </form>
EOH
   
	display($page_content,'',$setup{id_tpl_page2});
}

################################################################################
# addresses_db_old
################################################################################  
sub addresses_db_old
{
	my %order = %{get_eshop_order()};
	my %update_order = ();
	my %update_identity_delivery = ();
	my %update_identity_billing = ();
	
	$update_order{delivery_same_identities} = get_quoted('delivery_same_identities') || 'n';
	if($update_order{delivery_same_identities} ne 'y')
	{
		$update_order{billing_updated} = 'y';
	}
	
	my $required_empty_fields = '';
	
	#SAVE DELIVERY------------------------
	my $prefixe = 'delivery_';
   	my @champs = @{eshop::get_adresses_fields($prefixe)};

    
    my %update_member = ();
    foreach my $champ (@champs)
    {
      my %champ = %{$champ};

			$update_order{$champ{name}} = get_quoted($champ{name});
			$update_member{$champ{name}} = get_quoted($champ{name});
			
			my $identity_name_field = $champ{name};
			$identity_name_field =~ s/$prefixe//g; #no prefix in table identity 
			$update_identity_delivery{$identity_name_field} = $update_identity_billing{$identity_name_field} = get_quoted($champ{name});	
				
			#recopie les données dans billing si coché
			if($update_order{delivery_same_identities} eq 'y')
			{
				my $billing_name = $champ{name};
				$billing_name =~ s/delivery/billing/g;
				$update_order{$billing_name} = get_quoted($champ{name});	
				$update_member{$billing_name} = get_quoted($champ{name});
			}
		
			if($update_order{$champ{name}} eq '' && $champ{required} eq 'required')
			{
				$required_empty_fields  .= $champ{name}.',';
			}
    }
	
	if($update_order{delivery_same_identities} eq 'n')
	{
		#SAVE BILLING------------------------
		my $prefixe = 'billing_';
		my @champs = 
		(
			{
				name => $prefixe.'firstname',
				required => 'required',
			}
			,
			{
				name => $prefixe.'lastname',
				required => 'required',
			}
			,
			{
				name => $prefixe.'company',
			}
			,
			{
				name => $prefixe.'vat',
			}
			,
			{
				name => $prefixe.'street',
				required => 'required',
			}
			,
			{
				name => $prefixe.'number',
			}
			,
			{
				name => $prefixe.'box',
			}
			,
			{
				name => $prefixe.'zip',
				required => 'required',
			}
			,
			{
				name => $prefixe.'city',
				required => 'required',
			}
			,
			{
				name => $prefixe.'country',
				required => 'required',
			}
			,
			{
				name => $prefixe.'phone',
				required => 'required',
			}
			,
			{
				name => $prefixe.'email',
				required => 'required',
			}
		);
		
		foreach my $champ (@champs)
		{
			my %champ = %{$champ};
			
			$update_order{$champ{name}} = get_quoted($champ{name});
			$update_member{$champ{name}} = get_quoted($champ{name});		
			
			my $identity_name_field = $champ{name};
			$identity_name_field =~ s/$prefixe//g; #no prefix in table identity 
			$update_identity_billing{$identity_name_field} = get_quoted($champ{name});	
			
			if($update_order{$champ{name}} eq '' && $champ{required} eq 'required')
			{
				$required_empty_fields .= $champ{name}.',';
			}
		}
	}
	
	 #intracom
	 $update_order{do_intracom} = get_quoted('do_intracom') || 'n';
	 $update_order{do_fact} = get_quoted('do_fact') || 'n';

	 # Si la commande est liée à un compte on met à jour les données du membres
	 if($order{id_member} > 0)
	 {
		
	 }	
	
	#maj order
	updateh_db($dbh,"eshop_orders",\%update_order,"id",$order{id});

  #maj du membres et des identities si le membre est connecté
  if($order{id_member} > 0)
  {
  	# maj member
  	$update_member{are_same} = $update_member{delivery_same_identities};
  	delete $update_member{delivery_same_identities};
  	delete $update_member{billing_same_identities};
  	sql_set_data({debug=>0,dbh=>$dbh,table=>"migcms_members", data=>\%update_member, where=>"id = '$order{id_member}'"});

    #maj profil livraison
		$update_identity_delivery{id_member} = $order{id_member};
		$update_identity_delivery{identity_type} = "delivery";
		sql_set_data({dbh=>$dbh,debug=>0, table=>"identities",data=>\%update_identity_delivery,where=>"id_member='$order{id_member}' AND identity_type='delivery'"});
	
		#maj profil facturation
		$update_identity_billing{id_member} = $order{id_member};
		$update_identity_billing{identity_type} = "billing";
		sql_set_data({dbh=>$dbh,debug=>0, table=>"identities",data=>\%update_identity_billing,where=>"id_member='$order{id_member}' AND identity_type='billing'"});

  }
    
	#champs manquant: retour en arrière avant champs mis en avant
	if($required_empty_fields ne '')
	{
		cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_addresses}");
	}
	see(\%update_order);
	#vérifications TVA intracom
	if($update_order{do_intracom} eq 'y' && $update_order{delivery_vat} eq '')
	{
		cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_addresses}&err=vat&viesoff=$vies_non_dispo");
		exit;
	}
	exit;
    my ($result_check_vat_order,$vies_non_dispo) = check_vat_order($update_order{delivery_vat},$order{id},'delivery',$update_order{delivery_country},$update_order{do_intracom});
	
	# Fonction supplémentaire sur-mesure appelé après address_db (ex: cf equiwood)
	if($config{addresses_db_custom} eq "y")
	{
		def_handmade::addresses_db_custom({id_order=>$order{id}});
	}

	if($result_check_vat_order == 1)
    {
		recompute_order();
		cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_methodes}");
    }
    else
    {
		cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_addresses}&err=vat&viesoff=$vies_non_dispo");
    }
}

################################################################################
# addresses_db
################################################################################  
sub addresses_db
{
	my %order = %{get_eshop_order()};
	my %member = %{members::members_get()};
	
	my %update_order = ();
	my %update_identity_delivery = ();
	my %update_identity_billing = ();

	$update_order{delivery_same_identities} = get_quoted('delivery_same_identities') || 'n';
	if($update_order{delivery_same_identities} ne 'y')
	{
		$update_order{billing_updated} = 'y';
	}
	
	my $required_empty_fields = '';

	# Fusion des champs prénom et nom
	my $required_field = "required";
	if($config{eshop_simplified_adresses} eq "y")
	{
		$required_field = "";
	}

	my $prefixe = "delivery_";
	my @champs = @{eshop::get_adresses_fields("delivery_")};
    
	my $log = '';
	
    foreach my $champ (@champs)
    {
        my %champ = %{$champ};

        if($champ{name} ne "")
        {
        	$update_order{$champ{name}} = get_quoted($champ{name});	
		
			my $identity_name_field = $champ{name};
			$identity_name_field =~ s/$prefixe//g; #no prefix in table identity 
			$update_identity_delivery{$identity_name_field} = $update_identity_billing{$identity_name_field} = get_quoted($champ{name});	
			#recopie les données dans billing si coché
			if($update_order{delivery_same_identities} eq 'y')
			{
				my $billing_name = $champ{name};
				$billing_name =~ s/delivery/billing/g;
				$update_order{$billing_name} = get_quoted($champ{name});	
				$log .= "<br>$champ{label} (Livr et fact): ".$update_order{$champ{name}};
			}
			else
			{
				$log .= "<br>$champ{label} (Livr): ".$update_order{$champ{name}};
			}
			
			if($update_order{$champ{name}} eq '' && $champ{required} eq 'required')
			{
				$required_empty_fields  .= $champ{label}.',';
			}
        }		
		
    }

    $update_identity_delivery{same_identities} = $update_identity_billing{same_identities} = $update_order{delivery_same_identities};

	if($update_order{delivery_same_identities} eq 'n')
	{
		my $prefixe = "billing_";
		@champs = @{eshop::get_adresses_fields("billing_")};
		
		foreach my $champ (@champs)
		{
			my %champ = %{$champ};

			if($champ{name} ne "")
        	{
			
				$update_order{$champ{name}} = get_quoted($champ{name});	
				
				$log .= "<br>$champ{label} (Fact): ".$update_order{$champ{name}};
				
				my $identity_name_field = $champ{name};
				$identity_name_field =~ s/$prefixe//g; #no prefix in table identity 
				$update_identity_billing{$identity_name_field} = get_quoted($champ{name});	
				
				if($update_order{$champ{name}} eq '' && $champ{required} eq 'required')
				{
					$required_empty_fields .= $champ{label}.',';
				}
			}
		}
	}
	
	
	#intracom
    $update_order{do_intracom} = get_quoted('do_intracom') || 'n';
	$update_order{do_fact} = get_quoted('do_fact') || 'n';

	# Calcul Bpost
	$update_order{bpost_total_delivery_computed} = "n";

	#update order
    updateh_db($dbh,"eshop_orders",\%update_order,"id",$order{id});

    #maj profils par défaut si le membre est connecté
    if($order{id_member} > 0 && $config{order_auto_update_identities} ne "n")
    {
      #maj profil livraison
			my %identity = sql_line({table=>'identities',where=>"id_member='$order{id_member}' AND identity_type='delivery'"});
    	$update_identity_delivery{id_member} = $order{id_member};
    	$update_identity_delivery{identity_type} = "delivery";
    	my $id_delivery_identity = sql_set_data({dbh=>$dbh, table=>"identities", where=>"id = '$identity{id}' AND id > 0", data=>\%update_identity_delivery});
			# updateh_db($dbh,"identities",\%update_identity_delivery,'id',$identity{id});

		
			#maj profil facturation
			%identity = sql_line({table=>'identities',where=>"id_member='$order{id_member}' AND identity_type='billing'"});
			$update_identity_billing{id_member} = $order{id_member};
			$update_identity_billing{identity_type} = "billing";
    	my $id_billing_identity = sql_set_data({dbh=>$dbh, table=>"identities", where=>"id = '$identity{id}' AND id > 0", data=>\%update_identity_billing});

    	# Mise à jour du membre
    	my $stmt = <<"SQL";
    		UPDATE migcms_members
    		SET id_delivery_identity = '$id_delivery_identity',
    			id_bill_identity = '$id_billing_identity'
    		WHERE id = $order{id_member}
SQL

			execstmt($dbh,$stmt);
        
    }
    
	#champs manquant: retour en arrière avant champs mis en avant
	if($required_empty_fields ne '' || ($update_order{do_intracom} eq "y" && $update_order{delivery_vat} eq ""))
	{
		member_add_event({member=>\%member,group=>'eshop',type=>"addresses_db",erreur=>"Champs manquants, retour aux coordonnées: $required_empty_fields",detail=> $order{id}});
		if($required_empty_fields eq '')
		{
			$required_empty_fields = "do_intracom";
			member_add_event({member=>\%member,group=>'eshop',type=>"addresses_db",erreur=>"Champs manquants, retour aux coordonnées: $required_empty_fields",detail=> $order{id}});
		}
		cgi_redirect("$script_self?&sw=addresses&lg=$lg&err=fie&f=$required_empty_fields");
	}
	else
	{
		member_add_event({member=>\%member,group=>'eshop',type=>"addresses_db",name=>"Le client sauvegarde ses coordonnées: $log",detail=> $order{id}});
	}
	
	#vérifications TVA intracom
  my ($result_check_vat_order,$vies_non_dispo) = check_vat_order($update_order{delivery_vat},$order{id},'delivery',$update_order{delivery_country},$update_order{do_intracom});
	
  # Fonction supplémentaire sur-mesure
	if($config{addresses_db_custom} eq "y")
	{
		# Utilisé sur Equiwood par exemple
		def_handmade::addresses_db_custom({id_order=>$order{id}});
	}	

	if($result_check_vat_order == 1)
    {
		recompute_order();
		cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_methodes}");
    }
    else
    {
		cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_addresses}&err=vat&viesoff=$vies_non_dispo");
    }

	
}

################################################################################
# methodes
################################################################################
sub methodes
{
	my %order = %{get_eshop_order()};
	my $id_tarif = eshop_get_id_tarif_member();
member_add_event({group=>'eshop',type=>"etape",name=>"<b>Ecran méthodes de livraison/paiement</b>",detail=> $order{id}});
	# Récupération des méthodes de livraison et de paiement
	
	if($order{total_weight} eq '')
	{
		$order{total_weight}  = 0;
	}
	
	# A TERMINER : LIER METHODES DE LIVRAISON A UN TARIF
	my @deliveries = sql_lines({
		debug         => 0,
		debug_results => 0,
		table         => "eshop_deliveries",
		where         => "( max_weight = 0 OR $order{total_weight} < max_weight ) AND visible='y'",
		ordby         => 'order by ordby'
	});
	
	my @payments = sql_lines({
		debug         => 0,
		debug_results => 0,
		table         => 'eshop_payments as payments, eshop_lnk_payments_tarifs as lnk',
		where         => "lnk.id_tarif = '$id_tarif'
											AND lnk.id_payment = payments.id",
		ordby         => 'order by ordby'
	});
	
	my $nbr_deliveries = @deliveries;
	my $nbr_payments = @payments;

	# Redirection vers le récap si une seule méthode de paiement et de livraison
	if($setup{go_to_recap_if_one_method} eq "y" && $order{delivery_country} > 0 && $order{delivery} ne '' && $order{payment} ne '' && $nbr_deliveries == 1 && $nbr_payments == 1)
	{
		#si les deux méthodes sont complétées et qu'aucun choix n'est possible				
		if($order{delivery} eq 'bpost')
		{
			#si la méthode de livraison est bpost: redirection vers bpost
			cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_bpost}");
			exit;
		}
		else
		{
			#sinon redirection vers le récapitulatif
			cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_recap}");
			exit;
		}
	}

    
  my $breadcrumb = eshop::get_breadcrumb(2,2);
  my %tva = read_table($dbh,"eshop_tvas",21); #frais de ports tjs à [21]%

	if($order{total_weight} eq '')
	{
		$order{total_weight}=0;
	}
	
	#infos livraison
	my $url_page_livraison = get_url({debug=>0,debug_results=>0,nom_table=>'migcms_pages',id_table=>"$setup{url_info_livraison}", id_language => $lg});
	my $lien_vers_livraison;
	if($url_page_livraison ne "")
	{
		$lien_vers_livraison =<< "EOH";
   <a href="$config{baseurl}/$url_page_livraison" target="_blank" class="info_livraison">$sitetxt{eshop_delivery_meth_7}</a>
EOH
	}
	
	see();    

  my $form = <<"EOH";
	 <div id="eshop-breadcrumb">$breadcrumb</div> 
	 <div id="eshop" class="$config{eshop_col_container_class} clearfix">
		<div class="$config{eshop_col_left_class}">
		  <div class="customer-form">
			  
			  
			  <form method="post" class="form-horizontal" action="$script_self" >			
				<input type="hidden" name="sw" value = "methodes_db" />     
				<input type="hidden" name="lg" value = "$lg" />  
	   
				<!-- METHODES DE LIVRAISON -->
				<h1 class="$hide"><span>$sitetxt{eshop_delivery_meth_6}</span></h1>

				<table id="delivery-billing-table" class="$hide">
				<thead>
				   <tr>
					  <th class="customer-radio">&nbsp;</th>
					  <th class="delivery-method">
						  $sitetxt{eshop_delivery_meth_3}
					  </th>
					  <th class="delivery-price">
						  $sitetxt{eshop_delivery_meth_4}
					  </th>
					  <th class="delivery-more-infos">
						  $sitetxt{eshop_delivery_meth_5}
					  </th>
				  </tr>
				</thead>
				<tbody>
EOH
    
	#boucle sur les méthodes de livraisons
	my $custom_deliveries_methods = '';
	if($setup{methode_deliveries_func} ne '')
	{
		my $methode_deliveries_func = 'def_handmade::'.$setup{methode_deliveries_func};
    $custom_deliveries_methods = &$methode_deliveries_func(\%order);
    $form .= $custom_deliveries_methods;
	}
	else
	{
		foreach $delivery (@deliveries)
		{
			my %del = %{$delivery};
					
			# if($del{limit_to_country} ne '' && $del{limit_to_country} ne $order{delivery_country})
			# {
				# next;        
			# }
			
			my ($del_name,$dum) = get_textcontent($dbh,$del{id_textid_name});
			my ($del_descr,$dum) = get_textcontent($dbh,$del{id_textid_description});
			my $price = 0;
			my $price_tvac = get_delivery_price({del=>\%del});
			my $checked = '';
			
			if($order{default_delivery} eq '' && $order{delivery} eq '')
			{
				$order{default_delivery} = $order{delivery} = 'bpost';
			}
			
			#coche la méthode sélectionnée ou la méthode par défaut
			if($order{delivery} ne '' && $del{name} eq $order{delivery})
			{
				 $checked = ' checked = "checked" ';
			}
			elsif($order{delivery} eq '' && $del{name} eq $setup{default_delivery})
			{
				 $checked = ' checked = "checked" ';
			}
			
			#si intracom: frais de port HTVA
			if($order{is_intracom} && $order{do_intracom} eq 'y')
			{
			   $price = $price_tvac / (1+$tva{tva_value});
			}
			else
			{
			   $price = $price_tvac;
			}

			if($price_tvac >= 0)
			{
			  $price = display_price($price);
			  $form .= <<"EOH";
								<tr>
									  <td class="customer-radio">
										   <input type="radio" name="delivery" required id="$del{name}" $checked value="$del{name}" />
									 </td>
									 <td class="delivery-method">
											<label for="$del{name}"><strong>$del_name</strong></label>
									 </td>
									 <td class="delivery-price">
											<strong>$price</strong>
									 </td>
									 <td class="delivery-more-infos">
											$del_descr
									 </td>
								</tr>                          
EOH
			}
		}

	}

	
	$form .= <<"EOH";
						</table>
						<div class="$hide" id="eshop_livraison">$lien_vers_livraison</div>
EOH

	#Méthodes de paiements
	$form .= <<"EOH";
					
					<!-- METHODES DE PAIEMENTS -->
					<h1><span>$sitetxt{eshop_payment_method2}</span></h1>
					<table id="delivery-billing-table" class="billing-table">
					<thead>
					   <tr>
						  <th class="customer-radio">&nbsp;</th>
						  <th class="billing-method" colspan="2">
							  $sitetxt{eshop_delivery_meth_3}
						  </th>
					  </tr>
					</thead>
					<tbody>
EOH
  foreach $payment (@payments)
  {
      my %pay = %{$payment};
      if($pay{id_tarif} > 0 && $pay{id_tarif} != $id_tarif)
      {
          next;
      }

      # Permettre un mode de paiement si le membre fait partie du groupe d'id 1
      my $id_group = eshop_get_id_group_member();

      my %hash_params = eval("%hash_params = ($pay{params});");

      if($hash_params{enabled_id_group} == 1 && $id_group != 1)
      {
        next;
      }
      
      my ($pay_name,$dum) = get_textcontent($dbh,$pay{id_textid_name});
      my $checked = '';
      if($order{payment} ne '' && $pay{name} eq $order{payment})
      {
           $checked = ' checked = "checked" ';
      }
      elsif($order{payment} eq '' && $pay{name} eq $setup{default_payment})
      {
           $checked = ' checked = "checked" ';
      }
      
      $form .= <<"EOH";
      <tr>
           <td class="customer-radio">
                 <input type="radio" required name="payment" id="$pay{name}" $checked value="$pay{name}" />
           </td>
           <td class="billing-method">
                 <img src="$config{baseurl}/skin/shop/$pay{name}.svg" alt="$pay{name}" /> 
           </td>
           <td>
                  <label for="$pay{name}"><strong>$pay_name</strong></label>
           </td>
      </tr>                          
EOH
  }
    
	my $text_legal = '';
	if($sitetxt{texte_methodes} ne '')
	{	
		$text_legal = <<"EOH";
		<div class="well">
			$sitetxt{texte_methodes}
		</div>
EOH
	}
	
    $form .= <<"EOH";
		</table>
		 
	
						 <br />
						 <a href="$config{baseurl}/$sitetxt{eshop_url_addresses}" class="btn btn-default">$sitetxt{eshop_etape_precedente}</a>
						 <button type="submit" class="btn btn-info">$sitetxt{eshop_etape_suivante}</button>       
					</form>  
				</div>
			</div>
           
			<div class="$config{eshop_col_right_class}">
				<div class="recap-form">
					<h1><span>$sitetxt{'eshop_order_resume'}</span></h1>
					<div id="eshop_mini_cart" class="recap-prices">
					</div>
				</div>
				
				$secure_msg
			</div>
      </div> 
	  
	  $text_legal
EOH
    display($form,'',$setup{id_tpl_page2});
}

################################################################################
# methodes_db
################################################################################  
sub methodes_db
{
	 my %order = %{get_eshop_order()};
	my %member = %{members::members_get()};

	my %update_order = (
		delivery => get_quoted('delivery'),
		payment => get_quoted('payment'),
	);
	
	 my $log = "<br />Méthode de livraison: <span>$update_order{delivery}</span>";
	 $log .= "<br />Méthode de paiement: <span>$update_order{payment}</span>";

	
	if(get_quoted('id_magasin') > 0)
	{
		$update_order{delivery} = 'magasin';
	}
	if($update_order{delivery} eq 'magasin')
	{
		$update_order{id_magasin} = get_quoted('id_magasin');
		$log .= "<br />Numéro du magasin: <span>$update_order{id_magasin}</span>";
		
	}
	else
	{
		$update_order{id_magasin} = 0;
	}
	
	member_add_event({member=>\%member,group=>'eshop',type=>"methodes_db",name=>"Méthodes sauvegardées: $log",detail=> $order{id}});

	
   	updateh_db($dbh,"eshop_orders",\%update_order,"id",$order{id});
    recompute_order();
	
	#redirection si:
	if($update_order{delivery} eq 'bpost')
    {
        #BPOST
		member_add_event({member=>\%member,group=>'eshop',type=>"methodes_db",name=>"Redirection vers Bpost",detail=> $order{id}});
		cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_bpost}");
    }
	else
    {
      #RECAP
			cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_recap}");
    } 
}

################################################################################
# bpost
################################################################################
sub bpost
{
  
  my %bpost = select_table($dbh,"eshop_deliveries","","name='bpost'");
  my %params = %{$bpost{params}};
  
  my %order = %{get_eshop_order()};
	member_add_event({group=>'eshop',type=>"etape",name=>"<b>Ecran Bpost</b>",detail=> $order{id}});
	
  see();
  my %country = sql_line({table=>'countries',where=>"id='$order{delivery_country}'"});
  my $langue='FR';
	
	if($lg == 2)
	{
		$langue = 'EN';
	}
	elsif($lg == 3)
	{
		$langue = 'NL';
	}
	
    
    
  $order{delivery_firstname} = uri_escape($order{delivery_firstname});
  $order{delivery_lastname} = uri_escape($order{delivery_lastname});
    
  if($config{bpost_multisite} eq 'y')
	{
		$stmt = "UPDATE eshop_orders SET eshop_site='$ENV{HTTP_HOST}' where id='$order{id}'";
		$cursor = $dbh->prepare($stmt);
		$cursor->execute || suicide($stmt); 
	}    
    
  my $total_to_pay = $order{total_discounted_tvac} - $order{total_delivery_tvac};
  $total_to_pay *=  100;
  $total_to_pay = int($total_to_pay);
  $order{total_weight} *=  100;
  $order{total_weight} = int($order{total_weight});
    
  my @articles = ();
  my $form = bpost_get_form
  (
    $order{delivery_firstname},
    $order{delivery_lastname},
    $order{delivery_street},
    $order{delivery_number},
    $order{delivery_box},
    $order{delivery_city},
    $order{delivery_zip},
    $order{delivery_email},
    $order{delivery_phone},
    $country{iso},
    $order{total_weight},
    $setup{code}.'O'.$order{id},
    $total_to_pay,
    \@articles,
    $langue,
		$order{delivery_country},
  );
    
    
    my $breadcrumb = get_breadcrumb(2,2);
    my $content = <<"EOH";
        <div id="eshop-breadcrumb">$breadcrumb</div>
        
        $form
        
        <div id="showme">
    		    <iframe id="shmFrame" name="shmFrame" width="100%" height="600" style="border:none;"></iframe>
    		</div>
    		<script type="text/javascript">
    		</script>
    
        <style>
        #logobpost
        {
        display:none;
        }
        </style>
        <script type="text/javascript">
        jQuery(function() 
        {
          jQuery('#logobpost').click();
        });
        </script>
EOH
    
  display($content,'',$setup{id_tpl_page2});
}

sub bpost_get_form 
{
  my %bpost = sql_line({table=>"eshop_deliveries",where=>"name='bpost'",debug=>0});

  my %bpost_cfg = eval("%bpost_cfg = ($bpost{params});");
  
	$prenom=$_[0];
	$nom=$_[1];
	$adresse=$_[2];
	$numadresse=$_[3];
	$boite=$_[4];
	$ville=$_[5];
	$cp=$_[6];
	$email=$_[7];
	$phone=$_[8];
	$pays=$_[9];

	$poids_commande=$_[10];
	$num_commande=$_[11];
	$prix_commande=$_[12];
	
	# $ville = uri_escape($ville);
	# $ville = remove_accents_from($ville);
	
	
	
	@articles=@{$_[13]};

	$langue=$_[14];
	$id_country = $_[15];
	
  $accountid= $bpost_cfg{account_id};
	$mdp=$bpost_cfg{passphrase};
	$prixplafond=$bpost_cfg{free_after};
  
	my $form = <<HTML;
	<form id="myForm" method="POST" target="shmFrame" action="https://shippingmanager.bpost.be/ShmFrontEnd/start">
	<input type="image" id="logobpost" src="//www.bpost.be/site/nl/residential/parcels/pickup/handle-with-care_2groot.jpg" style="cursor:pointer" alt="Submit button"/>
	<input type="hidden" name="lang" value="$langue"/>
	<input type="hidden" name="accountId" value="$bpost_cfg{account_id}"/>
	<input type="hidden" name="action" value="START"/>
	<input type="hidden" name="orderReference" value="$num_commande"/>
	<input type="hidden" name="orderTotalPrice" value="$prix_commande"/>
	<input type="hidden" name="orderWeight" value="$poids_commande"/>
	<input type="hidden" name="customerFirstName" value="$prenom"/>
	<input type="hidden" name="customerLastName" value="$nom"/>
	<input type="hidden" name="customerStreet" value="$adresse"/>
	<input type="hidden" name="customerStreetNumber" value="$numadresse"/>
	<input type="hidden" name="extra" value="$config{projectname}"/>
HTML
	
		# <input type="hidden" name="deliveryMethodOverrides" value="bpack EXPRESS|$bpost_cfg{bpack_express_visible_status}|0"/>	
	if((($prix_commande/100) >= $bpost_cfg{free_after} && $bpost_cfg{free_after} > 0) || (($prix_commande/100) >= $bpost_cfg{'free_after_'.$id_country} && $bpost_cfg{'free_after_'.$id_country} > 0)  ) 
  { 
      $form .= <<HTML;
    	<input type="hidden" name="deliveryMethodOverrides" value="Parcels depot|$bpost_cfg{parcels_depot_visible_status}|0"/>
    	<input type="hidden" name="deliveryMethodOverrides" value="Pugo|$bpost_cfg{pugo_visible_status}|0"/>
    	<input type="hidden" name="deliveryMethodOverrides" value="Regular|$bpost_cfg{regular_visible_status}|0"/>
    	<input type="hidden" name="deliveryMethodOverrides" value="bpack BUSINESS|$bpost_cfg{bpack_business_visible_status}"/>
    
HTML
# |0&deliveryMethodOverrides=bpack EXPRESS|'.$bpost_cfg{bpack_express_visible_status}.'
		$str = 'accountId='.$accountid.'&action=START&customerCountry='.$pays.'&deliveryMethodOverrides=Parcels depot|'.$bpost_cfg{parcels_depot_visible_status}.'|0&deliveryMethodOverrides=Pugo|'.$bpost_cfg{pugo_visible_status}.'|0&deliveryMethodOverrides=Regular|'.$bpost_cfg{regular_visible_status}.'|0&deliveryMethodOverrides=bpack BUSINESS|'.$bpost_cfg{bpack_business_visible_status}.'&orderReference='.$num_commande.'&orderWeight='.$poids_commande.'&'.$mdp;
	} 
  else 
  {
		$str = 'accountId='.$accountid.'&action=START&customerCountry='.$pays.'&orderReference='.$num_commande.'&orderWeight='.$poids_commande.'&'.$mdp;

	}
  
	foreach $ligne (@articles)
	{
		$form .= <<HTML;
		<input type="hidden" name="orderLine" value="$ligne"/>
HTML
	}
	
	$form .= <<HTML;
		<input type="hidden" name="customerBox" value="$boite"/>
		<input type="hidden" name="customerCity" value="$ville"/>
		<input type="hidden" name="customerPostalCode" value="$cp"/>
		<input type="hidden" name="customerEmail" value="$email"/>
		<input type="hidden" name="customerPhoneNumber" value="$phone"/>
		<input type="hidden" name="customerCountry" value="$pays"/>
HTML

	$sha = Digest::SHA->new(256);
	$sha->add($str);
	$strcode=$sha->hexdigest();

	$form .= <<HTML;
		<input type="hidden" name="checksum" value="$strcode"/>
		</form>
HTML

  return $form;
}

################################################################################
# recap
################################################################################
sub recap
{
	my %order = %{get_eshop_order()};
	member_add_event({group=>'eshop',type=>"etape",name=>"<b>Ecran récapitulatif</b>",detail=> $order{id}});
	# Si c'est par bpost mais que les frais de Bpost n'ont pas été calculés
  if($order{delivery} eq "bpost" && $order{bpost_total_delivery_computed} ne "y")
  {
		cgi_redirect("$config{baseurl}/$sitetxt{eshop_url_methodes}");
    exit;
  } 


    my ($conditions_txt,$dum) = get_textcontent($dbh,$setup{id_textid_conditions});
	my $breadcrumb = eshop::get_breadcrumb(3);
    my $id_tarif = eshop_get_id_tarif_member();
    my $paiement_txt =  $sitetxt{eshop_proceder_paiement};
    if($order{payment} eq 'virement' || $order{payment} eq 'paiement_magasin')
    {
        $paiement_txt =  $sitetxt{eshop_payer_virement};
    }
	
	check_order();
	
    see();
    my $street2_delivery =<<"EOH";
    <br />$order{delivery_box}
EOH
    my $street2_billing =<<"EOH";
    <br />$order{billing_box}
EOH
    if($order{delivery_box} eq '')  {$street2_delivery ='';}
    if($order{billing_box} eq '')   {$street2_billing  ='';}
    my %delivery_country = read_table($dbh,"countries",$order{delivery_country});
    my %billing_country = read_table($dbh,"countries",$order{billing_country});
    if($order{delivery_company} ne '')
    {
        $order{delivery_company} .= '<br />';
    }
    if($order{billing_company} ne '')
    {
        $order{billing_company} .= '<br />';
    }
    if($order{billing_vat} ne '')
    {
        $order{billing_vat} .= '<br />';
    }

    my $page =<<"EOH";
<div id="eshop-breadcrumb">$breadcrumb</div>
<form method="post" action="$script_self">
      <input type="hidden" name="sw" value="recap_db" />
      <input type="hidden" name="lg" value="$lg" />		  
      <div id="eshop" class="$config{eshop_col_container_class} clearfix">
		<div class="$config{eshop_col_left_class}">
            <div class="customer-form">
				<h1><span>$sitetxt{eshop_recap_title}</span></h1>
EOH
	
    if($setup{sauter_facturation} ne 'y')
    {
    	# ADRESSE DE LIVRAISON
    	$link_edit_delivery = "$sitetxt{eshop_url_addresses}";
    	my $recap_delivery_address = <<"EOH";
    	<td>
				<strong>$sitetxt{'eshop_ad_liv'}</strong>
				<p>
					$order{delivery_company}
					$order{billing_vat}
					$order{delivery_firstname} $order{delivery_lastname}
					<br />$order{delivery_street} $order{delivery_number} 
					$street2_delivery
					<br />$order{delivery_zip} $order{delivery_city}<br />
					$delivery_country{fr}<br />
					<a href="$config{baseurl}/$link_edit_delivery">$sitetxt{'eshop_modifier'}</a>
				</p>
			</td>
EOH
			my %delivery = select_table($dbh,"eshop_deliveries","","name='$order{delivery}'");
			if($delivery{identity_tier} eq "y") 
			{
				my %delivery_country = read_table($dbh,"countries",$order{tier_country});

				if($order{tier_company} ne '')
		    {
		        $order{tier_company} .= '<br />';
		    }

				$recap_delivery_address = <<"EOH";
					<td>
					  <strong>$sitetxt{'eshop_ad_liv'} :</strong>
						<p>
						  $order{tier_company}
		          $order{tier_firstname} $order{tier_lastname}
						  <br />$order{tier_street} $order{tier_number} 
						  $street2_delivery
						  <br />$order{tier_zip} $order{tier_city}<br />
						  $delivery_country{fr}<br />
					  </p>
				  </td>
EOH
			}
			elsif($setup{recap_hide_deliveries_address} eq "y")
			{
				$recap_delivery_address = "";
			}
	
		# ADRESSE DE FACTURATION
		$link_edit_billing = "$sitetxt{eshop_url_addresses}";
		my $edit_billing_link = "<a href='$config{baseurl}/$link_edit_billing'>$sitetxt{'eshop_modifier'}</a>";
		if($setup{recap_disable_edit_billing} eq "y")
		{
			$edit_billing_link = "";
		}

		my $recap_billing_address = <<"EOH";
			<td>
				<strong>$sitetxt{'eshop_ad_fac'}</strong>
				<p>
					$order{billing_company}
					$order{billing_vat}
					$order{billing_firstname} $order{billing_lastname}
					<br />$order{billing_street} $order{billing_number} 
					$street2_billing
					<br />$order{billing_zip} $order{billing_city}<br />
					$billing_country{fr}<br />
					$edit_billing_link
				</p>
			</td>
EOH
		
		# METHODE DE LIVRAISON
		my %delivery = select_table($dbh,"eshop_deliveries","","name='$order{delivery}'");
    	my ($delivery,$dum) = get_textcontent($dbh,$delivery{id_textid_name}); 
		# see(\%sitetxt);
		$link_edit_delivery_meth = $sitetxt{'eshop_url_methodes'};
	

		my $link_delivery_edit = "<a href='$config{baseurl}/$link_edit_delivery_meth'>$sitetxt{'eshop_modifier'}</a>";
		# Si le processus de commande rapide est activé et qu'il n'y a qu'une seule méthode de livraison
		# alors le lien "modifier" est vide
		if($setup{go_to_recap_if_one_method} eq "y")
		{
			my %nb_methods_delivery = sql_line({debug=>0,debug_results=>0,table=>'eshop_deliveries',select=>"COUNT(*) as nb",where=>"visible='y'"});
			if($nb_methods_delivery{nb} == 1)
			{
				$link_delivery_edit = "";
			}
		}
		my $recap_delivery_method = <<"EOH";
		<td>
			<strong>$sitetxt{'eshop_met_liv'}</strong>
			<p>
			   $delivery<br/>
			   $link_delivery_edit
		  </p>
		</td>
EOH

		if($setup{recap_hide_deliveries_methods} eq "y")
		{
			$recap_delivery_method = "";
		}

		# METHODE DE PAIEMENT
		my %payment = select_table($dbh,"eshop_payments","","name='$order{payment}'");
    	my ($payment,$dum) = get_textcontent($dbh,$payment{id_textid_name});

    	$link_edit_billing_meth = "$sitetxt{eshop_url_methodes}";
    	my $link_payment_edit = "<a href='$config{baseurl}/$link_edit_billing_meth'>$sitetxt{'eshop_modifier'}</a>";
		
		# Si le processus de commande rapide est activé et qu'il n'y a qu'une seule méthode de livraison
		# alors le lien "modifier" est vide
		if($setup{go_to_recap_if_one_method} eq "y")
		{

			my %nb_methods_payment = sql_line({
				debug=>0,
				debug_results=>0,
				table=>'eshop_payments as payments, eshop_lnk_payments_tarifs as lnk',
				select=>"COUNT(*) as nb",
				where=>"payments.visible='y'
						AND lnk.id_tarif = '$id_tarif'
						AND lnk.id_payment = payments.id",
			});
			if($nb_methods_payment{nb} == 1)
			{
				$link_payment_edit = "";
			}
		}
		my $recap_payment_method = <<"EOH";
		<td>
			<strong>$sitetxt{'eshop_met_pai'}</strong>
			<p>
			 	<img src="$config{baseurl}/skin/shop/$order{payment}.png" alt="$payment" /> $payment<br/>
			 	$link_payment_edit
		  	</p>
  	</td>
EOH

        $page .=<<"EOH";
					<input type="hidden" name="eshop_recap_txt_conditions_ko" id="eshop_recap_txt_conditions_ko" value="$sitetxt{eshop_recap_txt_conditions_ko}" />
					
					<table id="recap-order-table">
					  	<tr>					  		
						  	$recap_delivery_address					  	
							  $recap_billing_address
					  	</tr>
					  	<tr>
							  $recap_delivery_method
							  $recap_payment_method
					  	</tr>
					  <tr>
						<td colspan="2">
							<strong>$sitetxt{'eshop_remarque_commande_livraison'}: </strong>
							<p>
								<textarea name="commentaire" placeholder="" class="input-block-level  form-control" style="max-width:100%">$order{commentaire}</textarea>
							</p>
						</td>
					  </tr>
				</table>
EOH
      }
      else
	  {
			#sauter facturation
			$page .=<<"EOH";
						<table id="recap-order-table">
						  <tr>
							  <td>
								  <strong>$sitetxt{'eshop_ad_liv'} : <a href="$config{baseurl}/$config{fullurl}/$sitetxt{eshop_url_addresses}">$sitetxt{'eshop_modifier'}</a></strong>
									<p>
									  $order{delivery_company}
										$order{delivery_firstname} $order{delivery_lastname}
									  <br />$order{delivery_street} $order{delivery_number} 
									  $street2_delivery
									  <br />$order{delivery_zip} $order{delivery_city}<br />
									  $delivery_country{fr}<br />
								  </p>
							  </td>
						  </tr>
						  <tr>
							<td >
								<strong>$sitetxt{'eshop_remarque_commande_livraison'}:</strong>
								<p>
									$order{commentaire}
								</p>
				
			   
				  <br /><br />
							</td>
						  </tr>
					</table>
EOH
      }
       $page .=<<"EOH"; 
		
		</div>
		</div>
		<div class="$config{eshop_col_right_class}">
				<div class="recap-form">
					<h1><span>$sitetxt{'eshop_order_resume'}</span></h1>
					<div id="eshop_mini_cart" class="recap-prices">
						
					</div>
				</div>
				
				$secure_msg
			</div>
      
	  <div class="col-md-12">
		<div id="eshop_cart_lines"></div>
		<div class="additionnal_infos">
			<label class="recap_newsletter"><input type="checkbox" name="nl_ok" value="y" /> $sitetxt{nl_ok}</label><br /> 
			<label class="recap_cgv"><input type="checkbox" required name="conditions_ok" id="conditions_ok" value="y" /> $conditions_txt</label> 
		</div>
		<br />
		<div class="cart-buttons clearfix">
			<a href="$config{baseurl}/$sitetxt{eshop_url_panier}" id="gotocart">$sitetxt{eshop_edit_cart}</a>
			<button class="btn btn-info button-gotopaiement"><span class="icon-lock icon-white"></span> $paiement_txt</button>
		</div>
	  </div>
      </form>
      </div> 
EOH
    display($page,'',$setup{id_tpl_page2});
}

################################################################################
# recap_db
################################################################################  
sub recap_db
{
	check_order();

	#récupère la commande en cours
	my %eshop_order = %{get_eshop_order()};
	
	my %update_order = ();
  $update_order{commentaire} = get_quoted('commentaire') || '';
  $update_order{conditions_ok} = get_quoted('conditions_ok') || 'n';
  $update_order{order_lg} = $lg || $config{current_language} || 1;

  updateh_db($dbh,"eshop_orders",\%update_order,"id",$eshop_order{id});
   
    
  if($update_order{conditions_ok} ne 'y')
  {
		member_add_event({group=>'eshop',type=>"recap_db",erreur=>"Le membre n'a pas validé les conditions légales, retour au recap: [$update_order{conditions_ok}]",detail=> $eshop_order{id}});
		cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_recap}");
		exit;
  }
  member_add_event({group=>'eshop',type=>"recap_db",name=>"Le membre valide les conditions légales, commande confirmée, accès au paiement",detail=> $eshop_order{id}});



	# On indique que le recap est validé
	my $stmt = "UPDATE eshop_orders SET order_lg = '$lg', order_finish_moment = NOW(), recap_validate = 'y' WHERE id = '$eshop_order{id}'";
	execstmt($dbh,$stmt);


	# Création d'un membre si la commande est passée en tant qu'invité
	my %test_member = sql_line({table=>'migcms_members',where=>"email != '' AND email = '$eshop_order{billing_email}'"});
	if(!($eshop_order{id_member} > 0) && !($test_member{id} > 0))
	{
		create_member_from_order({token=>$eshop_order{token}, tags=>",2001,1001,", actif=>"n", email_optin=>$update_order{conditions_ok}, commande_invite=>"y"});
	}



	# Redirection vers pay_start
	cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_terminer}");
	exit;

}

################################################################################
# check_order
################################################################################ 
sub check_order
{
	my %eshop_order = %{get_eshop_order()};
	my %member = %{members::members_get()};
	#si aucun produit commande, retour au panier
    if(!($eshop_order{total_qty} > 0))
    {
   		member_add_event({member=>\%member,group=>'eshop',type=>"recap",erreur=>"Aucun produit commandé, retour au panier",detail=> $eshop_order{id}});
		cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_panier}");
        exit;
    }

  #VERIFIE  si une méthode de paiement et de livraison a été associée
  my %check_delivery = sql_line({dbh=>$dbh, select=>"id", table=>"eshop_deliveries", where=>"name='$eshop_order{delivery}'"});
  my %check_payment = sql_line({dbh=>$dbh, select=>"id", table=>"eshop_payments", where=>"name='$eshop_order{payment}'"});
  if(!($check_delivery{id} > 0) || !($check_payment{id} > 0))
  { 	
  	# Redirection vers les méthodes
	member_add_event({member=>\%member,group=>'eshop',type=>"recap",erreur=>"Aucune méthode de livraison ($eshop_order{delivery} - $check_delivery{id}) ou de paiement ($eshop_order{payment} - $check_payment{id})",detail=> $eshop_order{id}});
	cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_methodes}");
    exit;
  }

  # VERIFIE si les champs requis de livraison ne sont pas vides
  my @champs_identity = @{get_identities_fields()};

  my %identity = ();
  foreach my $champ_identity (@champs_identity)
  {
    %champ_identity = %{$champ_identity};  

    if($eshop_order{"delivery_".$champ_identity{name}} eq "" && $champ_identity{required} eq "required")
    {    	
    	member_add_event({member=>\%member,group=>'eshop',type=>"recap",erreur=>"Champs de livraison manquant: $champ_identity{label} ($champ_identity{name}), retour aux coordonnées",detail=> $eshop_order{id}});
		cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_addresses}&erreur=1&champ=delivery_".$champ_identity{name});
		exit;
    }
  }
}

################################################################################
# pay_start
################################################################################  
sub pay_start
{
	check_order();

	#récupère la commande en cours
	my %eshop_order = %{get_eshop_order()};

	#execute fonction sur mesure (avant pay_start)
  my $pay_start_func = $config{eshop_pay_start_func};
  if($config{eshop_pay_start_func} ne '')
  {
      my $pay_start_func = 'def_handmade::'.$config{eshop_pay_start_func};
      &$pay_start_func(\%eshop_order);
  }

  if($eshop_order{payment} eq 'virement'
    || $eshop_order{payment} eq 'cheque'
    || $eshop_order{payment} eq 'paiement_livraison'
    || $eshop_order{payment} eq 'paiement_magasin'
    )
  {
  	
	member_add_event({group=>'eshop',type=>"pay_start",name=>"Commande par $eshop_order{payment} ",detail=> $eshop_order{id}});

	change_status({status=>'new',payment_status=>'wait_payment',delivery_status=>'current',order=>\%eshop_order});

    # Execution de l'éventuelle fonction post_order
    exec_post_order({order=>\%eshop_order, payment_status=>"wait_payment"});
	
	# Mise à jour du stock (si activé)
    eshop::update_stock({order=>\%eshop_order});
    
    # Envoi du mail de confirmation de commande
    eshop_mailing_confirmation(\%eshop_order);

    # Redirection vers la page de confirmation
    cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_end_success}/$eshop_order{token}");
    exit;
  }
  elsif($eshop_order{payment} eq 'commande_fournisseur') 
  {
  	change_status({status=>'new',payment_status=>'paid',delivery_status=>'current',order=>\%eshop_order});

  	# Execution de l'éventuelle fonction post_order
    exec_post_order({order=>\%eshop_order, payment_status=>"paid"});
    
    # Mise à jour du stock
    eshop::update_stock({order=>\%eshop_order});
    
    # Envoi du mail de confirmation de commande        
    eshop_mailing_confirmation(\%eshop_order);
    
    # Envoi du mail de facture Pro Forma
    eshop_mailing_facture(\%eshop_order);

    # Génération d'un numéro séquentiel de facture
    if($setup{generate_bill_number_if_paid} eq "y")
    {            
        my $invoice_num = eshop::generate_sequential_num_db({id=>$eshop_order{id}, table=>"eshop_orders", col=>"invoice_num"});
        # Récupération de l'order mise à jour avec le numéro de facture
        my %eshop_order = sql_line({table=>"eshop_orders", where=>"id = '$eshop_order{id}'"});
        # Envoi de la facture pdf
        eshop::eshop_mailing_facture_pdf(\%eshop_order);
    }
    
    # Redirection vers la page de confirmation
    cgi_redirect("$config{fullurl}/$sitetxt{eshop_url_end_success}/$eshop_order{token}");
    exit;
  }
  else
  {
		change_status({status=>'unfinished',payment_status=>'wait_payment',delivery_status=>'current',order=>\%eshop_order});
		
	  my $payment_form = get_payment_form();
	  my $payment_screen = <<"EOH";
			<div id="eshop-redir">
				$sitetxt{eshop_paystart_msg}
				$payment_form
			</div>
EOH
		see();
		# Affichage du formulaire qui se soumet tout seul en javascript
	 	display($payment_screen,'',$setup{id_tpl_page1});  	
  }

	
}


################################################################################
# get_payment_form
################################################################################  
sub get_payment_form
{
	#récupère la commande en cours
	my %eshop_order = %{get_eshop_order()};

	my $form = "";

	#### PAYPLUG #####
  if($eshop_order{payment} eq "payplug")
  {
    use Crypt::OpenSSL::RSA;
    use PHP::HTTPBuildQuery qw(http_build_query);
    use URI::Escape;
    use MIME::Base64;

    my %setup = %{get_setup()};

    my $total = $eshop_order{total_discounted_tvac};

    my %tarif = read_table($dbh,'eshop_tarifs',$eshop_order{id_tarif});
    if(($eshop_order{is_intracom} && $eshop_order{do_intracom} eq 'y') || ($tarif{pay_tvac} ne "y" && $tarif{id} > 0))
    {
      $total = $eshop_order{total_discounted_htva}; 
    }

    $total = sprintf("%.2f",$total);
    # On retire la virgule car Payplug a besoin de la somme en cents
    $total =~ s/\.//;

    my $email = $eshop_order{billing_email};
    my $firstname = remove_accents_from($eshop_order{delivery_firstname});
    my $lastname = remove_accents_from($eshop_order{delivery_lastname});

    if($eshop_order{id_member} eq "")
    {
      $eshop_order{id_member} = "NULL";
    }
    
    my %params = (
      amount      => $total,
      currency    => "EUR",
      ipn_url     => "$config{fullurl}/$sitetxt{eshop_url_retour_payment}",
      return_url  => "$config{fullurl}/$sitetxt{eshop_url_end_success}/$eshop_order{token}",
      cancel_url  => "$config{fullurl}/$sitetxt{eshop_url_end_error}",
      email       => $email || "NULL",
      first_name  => $firstname || "NULL",
      last_name   => $lastname || "NULL",
      customer    => $eshop_order{id_member},
      order       => $eshop_order{id},
      custom_data => "null",
      origin      => "null",

    );   


   #  see();
   # print "<pre>";
   # see(\%params);
   # exit;

    my $parametres = http_build_query(\%params);
    my $data = uri_escape(encode_base64($parametres,""));

    # Signature 
    my $private_key = Crypt::OpenSSL::RSA->new_private_key($setup{payplug_private_key});
    
    $private_key->use_sha1_hash();
    $signature = $private_key->sign($parametres);
    $signature = uri_escape(encode_base64($signature,""));

    # $signature =~ s/\%0A//g;


    my $url = "$setup{payplug_url}?data=$data&sign=$signature";
    
    $form = <<"HTML";
      <form method="POST" action="$url" id="payment_method_payplug"  class="payment_form">
      </form> 
     	<script type="text/javascript">
			jQuery(document).ready(function()
			{
			    jQuery('#payment_method_payplug').submit();
			});
      </script>  
HTML

	}
	# PAYPAL
	elsif($eshop_order{payment} eq 'paypal')
  {
     my %paypal = sql_line({dbh=>$dbh,table=>"eshop_payments",where=>"name='paypal'"});

     my %params = eval("%params = ($paypal{params});");

     my $total = $eshop_order{total_discounted_tvac};
     my %tarif = read_table($dbh,'eshop_tarifs',$eshop_order{id_tarif});
     if(($eshop_order{is_intracom} && $eshop_order{do_intracom} eq 'y') || ($tarif{pay_tvac} ne "y" && $tarif{id} > 0))
     {
        $total = $eshop_order{total_discounted_htva}; 
     }
     $total = sprintf("%.2f",$total);
     
     my $amo = $total;
     my $email = $eshop_order{billing_email};
     
     my $firstname = remove_accents_from($eshop_order{delivery_firstname});
     my $lastname = remove_accents_from($eshop_order{delivery_lastname});
     my $address1 = remove_accents_from($eshop_order{delivery_street}) . " " . remove_accents_from($eshop_order{delivery_number}) . " " . remove_accents_from($eshop_order{delivery_box});
     my $address2 = remove_accents_from($eshop_order{delivery_street2});
     my $zip = $eshop_order{delivery_zip};
     my $city = remove_accents_from($eshop_order{delivery_city});
     my $phone = $eshop_order{delivery_phone};
     $phone =~ s/^\+32//;
     $phone =~ s/\s//g;
     my %country=read_table($dbh,"countries",$eshop_order{delivery_country});
     my $country = $country{iso};
     my @labels = ();
     my @det = get_table($dbh,"eshop_order_details","detail_label","id_eshop_order=$eshop_order{id} order by id");
     foreach my $det (@det) 
     {
       push @labels,$det->{detail_label};
     }
     
     my $url_test = 'https://www.sandbox.paypal.com/cgi-bin/webscr';
     my $url_prod = 'https://www.paypal.com/be/cgi-bin/webscr';
     my $url = $url_test;
     if($params{version} eq 'PROD')
     {
        $url = $url_prod;
     }

     my $currency_code = "EUR";
     if($params{currency_code} ne '')
     {
        $currency_code = $params{currency_code};
     }

     # lg paypal checkout (tiens aussi compte de la langue du navigateur)
     my $lc = "FR";
     if($eshop_order{order_lg} > 1)
     {
       my %order_language = sql_line({dbh=>$dbh, table=>"migcms_languages", where=>"id = '$eshop_order{order_lg}'"});
       $lc = uc($order_language{name});

       # Cas particulier : EN => US pour Paypal
       if($lc eq "EN")
       {
        $lc = "US";
       }
     }
     
     my $item_name = $eshop_order{id}." ".join(" ",@labels);
     $form = <<"EOH";
        <form action="$url" method="post"  id="payment_method_paypal" class="payment_form">
            <!-- begin data -->
            <input type="hidden" name="cmd" value="_ext-enter" />
            <input type="hidden" name="redirect_cmd" value="_xclick" />
            <input type="hidden" name="business" value="$params{paypal_id}" />
            <input type="hidden" name="item_name" value="$item_name" />
            <input type="hidden" name="currency_code" value="$currency_code" />
            <input type="hidden" name="amount" value="$amo" />
            <input type="hidden" name="no_note" value="1" />
            <input type="hidden" name="no_shipping" value="1" />
            <input type="hidden" name="address_override" value="1" />
            <input type="hidden" name="invoice" value="$eshop_order{id}" />
            <input type="hidden" name="rm" value="1" />
            <input type="hidden" name="email" value="$email" />
            <input type="hidden" name="country" value="$country" />
            <input type="hidden" name="first_name" value="$firstname" />
            <input type="hidden" name="last_name" value="$lastname" />
            <input type="hidden" name="address1" value="$address1" />
            <input type="hidden" name="zip" value="$zip" />
            <input type="hidden" name="city" value="$city" />
            <input type="hidden" name="night_phone_a" value="32" />
            <input type="hidden" name="night_phone_b" value="$phone" />
            <input type="hidden" name="lc" value="$lc" />
            <input type="hidden" name="bn" value="PP-BuyNowBF" />
            <input type="hidden" name="charset" value="ISO-8859-1"  />
            <input type="hidden" NAME="return" value="$config{fullurl}/$sitetxt{eshop_url_end_success}" />
            <input type="hidden" NAME="notify_url" value="$config{fullurl}/$sitetxt{eshop_url_retour_payment}&ipn=yes" />
            <input type="hidden" NAME="cancel_return" value="$config{fullurl}/$sitetxt{eshop_url_end_error}" />
            <!-- end data -->
        </form>
         <script type="text/javascript">
             jQuery(document).ready(function()
             {
                  jQuery('#payment_method_paypal').submit();
             });
        </script> 
EOH
   }



 	return $form;
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
	
	member_add_event({group=>'eshop',type=>"change_status",name=>"Changement des statuts de la commande: <span>Statut: $d{status}<br>Paiement: $d{payment_status}<br>Livraison: $d{delivery_status}</span>",detail=> $order{id}});
}

################################################################################
# order_end_confirmation
################################################################################
sub order_end_success
{
	my $token = get_quoted("token");
	my %eshop_order = sql_line({debug=>0,debug_results=>0,table=>"eshop_orders",where=>"token='$token'"});
	# change_status({status=>'new',delivery_status=>'current',order=>\%eshop_order});
	member_add_event({group=>'eshop',type=>"etape",name=>"<b>Ecran de fin de commande avec succès</b>",detail=> $order{id}});
	
	# Instructions Virement
	my $instructions_paiement;
  if($eshop_order{payment} eq 'virement')
  {
    $instructions_paiement .=<<"EOH";
	    <div class="alert alert-block alert-info">
	  		<h4 class="alert-heading">$sitetxt{eshop_virement_instructions_1}</h4>
	  		<p>$sitetxt{eshop_virement_instructions_2}:<br />
	        <br />$setup{eshop_name}
	        <br />$setup{eshop_street}
	        <br />$setup{eshop_zip_city}<br />
	        <br /><strong>$sitetxt{eshop_banque} :</strong> $setup{eshop_banque}
	        <br /><strong>$sitetxt{eshop_iban} :</strong> $setup{eshop_iban}
	        <br /><strong>$sitetxt{eshop_bic} :</strong> $setup{eshop_bic}
	        <br /><strong>$sitetxt{eshop_communication} :</strong> $setup{eshop_name} $eshop_order{id}</p>
	  	</div>
EOH
  }

  

 	my %existing_email_account = sql_line({table=>'migcms_members',where=>"email = '$eshop_order{billing_email}' "});

 	# Si le compte associé à la commande n'est pas actif => commande invité
 	# On propose la création d'un compte
 	my $formulaires;
 	if($eshop_order{id} > 0 && $existing_email_account{actif} eq "n")
  {
  	$formulaires =<<"EOH";
			<div id="eshop" class="clearfix">
				<h1><span>$sitetxt{eshop_account_1}</span></h1>

				<script type="text/javascript">
					jQuery(document).ready(function()
					{
						jQuery("#password").focus();
					});
				</script>

				<p><strong>$sitetxt{eshop_account_2}.<br />
				$sitetxt{eshop_account_3}.</strong></p>
       
				<form class="form-horizontal" id="form_signup" method="post" action="$config{fullurl}/cgi-bin/members.pl">
  				<input type="hidden" name="sw" value="create_member_from_order" />
  				<input type="hidden" name="lg" value="$lg" />
  				<input type="hidden" name="token" value="$eshop_order{token}" />
					<input type="hidden" name="email_optin" value="$eshop_order{conditions_ok}" />

    
				  <div class="form-group">
					  <label class="control-label col-sm-4">$sitetxt{'eshop_email'}</label>
					  <div class="col-sm-8">   
						  <input type="text" disabled value="$eshop_order{billing_email}" name="email" required id="inputEmail" placeholder="Adresse e-mail" class="form-control" />
					  </div>
				  </div>
				  <div class="form-group">
					  <label class="control-label col-sm-4">$sitetxt{'eshop_password'}</label>
					  <div class="col-sm-8">
						  <input type="password" name="password" required id="password" placeholder="Mot de passe" class="required form-control" />
					  </div>
				  </div>
				  <div class="form-group">
					  <div class="col-sm-4"></div>
					  <div class="col-sm-8">
						  <button type="submit" class="btn btn-info">$sitetxt{eshop_create_account}</button>
					  </div>
				  </div>
    		</form>
	</div>
EOH
  }
   # Si la commande n'est pas liée à un compte et que l'adresse email EXISTE dans les membres
  # On propose de lier la commande à son compte 
  elsif($eshop_order{id} > 0 && !($eshop_order{id_member} > 0) && ($existing_email_account{id} > 0))
  {
$formulaires .=<<"EOH";
		<div id="eshop" class="clearfix">
			<h1><span>$sitetxt{eshop_link_order_to_member_title}</span></h1>
			<script type="text/javascript">
				jQuery(document).ready(function()
				{
					jQuery("#link_password").val('');
          jQuery("#link_password").focus();
				});
			</script>
			<p><strong>$sitetxt{eshop_link_order_to_member_txt}</strong></p>
         
			<form class="form-horizontal" id="form_signup" method="post" action="$script_self">
      				<input type="hidden" name="sw" value="link_order_to_member" />
      				<input type="hidden" name="lg" value="$lg" />
					    <input type="hidden" name="token_order" value="$eshop_order{token}" />
              <input type="hidden" name="billing_email" value="$eshop_order{billing_email}" />
              
      
      				  <div class="form-group">
      					  <label class="control-label col-sm-4">$sitetxt{'eshop_email'}</label>
      					  <div class="col-sm-8">   
      						  <input type="text" disabled value="$eshop_order{billing_email}" name="email" required id="inputEmail" placeholder="Adresse e-mail" class="form-control" />
      					  </div>
      				  </div>
      				  <div class="form-group">
      					  <label class="control-label col-sm-4">$sitetxt{'eshop_password'}</label>
      					  <div class="col-sm-8">
      						  <input type="password" name="password" required id="link_password" placeholder="" class="required form-control" />
      					  </div>
      				  </div>
      				  <div class="form-group">
						  <div class="col-sm-4"></div>
      					  <div class="col-sm-8">
      						  <button type="submit" class="btn btn-info">$sitetxt{eshop_save}</button>
      					  </div>
      				  </div>
      		</form>
		</div>
EOH

  }

  my $page =<<"EOH";
		<div id="eshop" class="clearfix">
			<h1><span>$sitetxt{eshop_end_ok_1}</span></h1>
			<div class="alert alert-block alert-success">
	  			<h4 class="alert-heading">$sitetxt{eshop_end_ok_2}</h4>
	  			<p>$sitetxt{eshop_end_ok_3}.<br />
				$sitetxt{eshop_end_ok_4}.</p>
				<p><a class="btn btn-success" target="_blank" href="$config{baseurl}/$sitetxt{eshop_url_facture_pro_forma}/$eshop_order{token}">$sitetxt{eshop_end_ok_5}</a></p>
			</div>
			
			$instructions_paiement

			$formulaires

		</div>
EOH

 	see();
 	display($page,'',$setup{id_tpl_page1});
}

################################################################################
# order_end_error
################################################################################
sub order_end_error
{
	see();
	member_add_event({group=>'eshop',type=>"etape",name=>"<b>Ecran de fin de commande avec erreur</b>",detail=> $order{id}});
	my $token = get_quoted('token');
  my %order = sql_line({table=>'eshop_orders',where=>"token='$token'"});

 	my $page =<<"EOH";
	<div id="eshop" class="$config{eshop_col_container_class} clearfix">
		<div class="col-lg-12">
			<h1><span>$sitetxt{eshop_end_ko_1}</span></h1>
			<div class="alert alert-block alert-error alert-danger">
				<h4 class="alert-heading">$sitetxt{eshop_end_ko_2}</h4>
				<p>$sitetxt{eshop_end_ko_3}.<br />
				$sitetxt{eshop_end_ko_4}.</p>
				<p><a class="btn btn-danger" href="/$sitetxt{eshop_url_recap}">$sitetxt{eshop_go_recap}</a></p>
			</div>
		</div>
	</div>
EOH
     display($page,$setup{id_tpl_page1});
}

################################################################################
# add_wishlist
################################################################################
sub add_wishlist
{
	my $id_data_sheet = get_quoted("id_data_sheet");

	# On récupère la sheet
	my %data_sheet = sql_line({table=>"data_sheets", where=>"id = '$id_data_sheet'"});

	my $msg = "ko";

	if($data_sheet{id} > 0)
	{
		# On récupère le membre
		my %member = %{members_get()};

		if($member{id} > 0)
		{
			# Ajout d'une sheet à la wishlist du membre
			my %new_sheet_wishlist = (
				id_member => $member{id},
				id_data_sheet => $data_sheet{id},
			);

			sql_set_data({dbh=>$dbh, table=>"data_sheets_wishlist", data=>\%new_sheet_wishlist, where=>"id_data_sheet = '$new_sheet_wishlist{id_data_sheet}' AND id_member = '$new_sheet_wishlist{id_member}'"});

			$msg = "ok";
		}
		else
		{
			$msg = "login";
		}

	}

	see();
	print $msg;
	exit;
}

################################################################################
#add_cart
################################################################################
sub add_cart
{
		#crée une commande si necessaire
		my $id_eshop_order = create_eshop_order();
		log_debug('add_cart','vide','eshop_add_cart');

		#récupère la commande en cours
		my %eshop_order = %{get_eshop_order({id=>$id_eshop_order})};
		
		my $id_tarif = eshop::eshop_get_id_tarif_member();
		my $id_data_stock_checked = get_quoted('id_data_stock_checked');
		my @list_id_data_stock_checked = split(/\,/,$id_data_stock_checked);
		
		my $avert_stock = 'n';
		
		foreach my $id_data_stock_info (@list_id_data_stock_checked)
		{
				my ($id_data_stock,$detail_qty) = split(/\|/,$id_data_stock_info);
				my %data_stock = read_table($dbh,'data_stock',$id_data_stock);

				#arret si data_stock inconnu
				if(!($data_stock{id} > 0))
				{
						log_debug("$eshop_order{id}: Référence stock non connue <span>$id_data_stock </span>",'','eshop_add_cart');
						member_add_event({group=>'eshop',type=>"add_cart",erreur=>"Référence stock non connue <span>$id_data_stock </span>",detail=> $eshop_order{id}});
						next;
				}
				my %data_sheet = read_table($dbh,'data_sheets',$data_stock{id_data_sheet});
				my %data_family = read_table($dbh,'data_families',$data_sheet{id_data_family});
				my %field_reference = sql_line({table=>'data_fields',where=>"id='$data_family{id_field_reference}'"});
				
				#recherche stock et prix
				my %data_stock_tarif = sql_line({debug=>1,debug_results=>1,table=>'data_stock_tarif',where=>"id_data_stock='$data_stock{id}' AND id_tarif='$id_tarif'",ordby=>"st_pu_tvac asc"});
				%sheet_prices = %{eshop::get_product_prices({from=>'data',debug=>1,generation=>'n',data_sheet=>\%data_sheet,data_stock_tarif=>\%data_stock_tarif})};

				#arret si prix = 0
				if(!($sheet_prices{price_htva} > 0))
				{
					log_debug("$eshop_order{id}: Aucun prix Stock:$id_data_stock HTVA:$sheet_prices{price_htva} TVAC:$sheet_prices{price_tvac}",'','eshop_add_cart');
					member_add_event({group=>'eshop',type=>"add_cart",erreur=>"Aucun prix <span>$id_data_stock </span>",detail=> $eshop_order{id}});
					next;
				}
				
				#calcul reference et libellé
				my $detail_reference = trim($data_sheet{'f'.$field_reference{ordby}});
				if(trim($data_stock{reference}) ne '' && trim($data_stock{reference}) ne $detail_reference)
				{	
					$detail_reference .= ' / '.trim($data_stock{reference});
				}
				my $detail_label = '';
				foreach my $num_label (1 .. 5)
				{
					if($setup{'id_data_field_name'.$num_label} > 0)
					{
							my %data_field = read_table($dbh,"data_fields",$setup{'id_data_field_name'.$num_label});
							if($data_field{field_type} eq 'text_id')
							{
									my $traduction = get_traduction({debug=>0,id_language=>$lg,id=>$data_sheet{'f'.$data_field{ordby}}});
									$detail_label .= "$traduction";
							}
							elsif($data_field{field_type} eq 'listboxtable')
							{
								my %migcms_code = sql_line({table=>"migcms_codes",select=>"id_textid_name, v1",where=>"id='".$data_sheet{'f'.$data_field{ordby}}."'"});
								if($migcms_code{id_textid_name} > 0)
								{
									$detail_label .= get_traduction({id=>$migcms_code{id_textid_name},id_language=>$lg}) . " ";;									
								}
								else
								{
									$detail_label .= $migcms_code{v1} . " ";
								}
							}
							else
							{
									$detail_label .= $data_sheet{'f'.$data_field{ordby}}.' ';
							}
					}
				}

				# Si c'est un produit à variante, on rajoute le nom de la catégorie/variante dans le label
				if($data_stock{id_data_category} > 0) {
					my %category = sql_line({table=>"data_categories", where=>"id = $data_stock{id_data_category}"});
					my $traduction = get_traduction({debug=>0,id_language=>$lg,id=>$category{id_textid_name}});

					$detail_label .= "($traduction)";
				}

				log_debug("$eshop_order{id}: Label: $detail_label",'','eshop_add_cart');

				#cumul de quantites: verifie si une ligne detail existe deja pour cette variante 
				my %check_existing_eshop_order_detail = sql_line({debug=>0,debug_results=>0,table=>'eshop_order_details',where=>"id_eshop_order='$eshop_order{id}' AND id_data_stock = '$data_stock{id}'"});
				if($config{custom_check_existing_eshop_order_detail} ne "")
				{
					my $fct = 'def_handmade::'.$config{custom_check_existing_eshop_order_detail};
					%check_existing_eshop_order_detail = %{&$fct({eshop_order=>\%eshop_order, data_stock=>\%data_stock, after_add_cart=>get_quoted("after_add_cart")})};
				}

				if(!($detail_qty >= 1))
				{
					$detail_qty = 1;
				}
				if($check_existing_eshop_order_detail{id} > 0)
				{
					$detail_qty += $check_existing_eshop_order_detail{detail_qty};
				}
				
				#vérifications sur la quantité
				if($detail_qty > 0)
				{
						if($detail_qty > 10000)
						{
							$detail_qty = 10000;
						}
				}
				else
				{
						$detail_qty = 1;
				}
				log_debug("$eshop_order{id}: detail_qty: $detail_qty",'','eshop_add_cart');
				
				#veririfications sur le stock
				if($setup{check_stock} eq 'y' && $detail_qty > $data_stock{stock})
				{
						member_add_event({group=>'eshop',type=>"add_cart",erreur=>"Quantité ($detail_qty) réduite car stock insuffisant ($data_stock{stock})",detail=> $eshop_order{id}});
						$detail_qty = $data_stock{stock};
						$avert_stock = 'y';
				}
							
				#ajout/maj de la ligne detail
				my %new_eshop_order_detail = 
				(
						id_eshop_order => $eshop_order{id},
						id_data_sheet => $data_sheet{id},
						id_tva => $data_sheet{taux_tva},
						id_data_stock => $data_stock{id},
						id_data_family => $data_sheet{id_data_family},
						id_tarif => $id_tarif,
						id_data_stock_tarif => $data_stock_tarif{id},
						avert_stock => $avert_stock,
						detail_reference => $detail_reference,
						detail_label => $detail_label,
						detail_qty => $detail_qty,
						detail_weight => $data_stock{weight},
						detail_pu_htva => $sheet_prices{price_htva},
						detail_pu_tvac => $sheet_prices{price_tvac} ,
						detail_pu_tva => $sheet_prices{price_tva},
						detail_pu_discount_htva => $sheet_prices{price_discount_htva},
						detail_pu_discount_tvac => $sheet_prices{price_discount_tvac} ,
						detail_pu_discount_tva => $sheet_prices{price_discount_tva} ,						
						detail_pu_discounted_htva => $sheet_prices{price_discounted_htva},
						detail_pu_discounted_tvac => $sheet_prices{price_discounted_tvac},
						detail_pu_discounted_tva => $sheet_prices{price_discounted_tva},		
						detail_total_htva => $detail_qty * $sheet_prices{price_htva},
						detail_total_tvac => $detail_qty * $sheet_prices{price_tvac} ,
						detail_total_tva => $detail_qty * $sheet_prices{price_vac},
						detail_total_discount_htva => $detail_qty * $sheet_prices{price_discount_htva},
						detail_total_discount_tvac => $detail_qty * $sheet_prices{price_discount_tvac} ,
						detail_total_discount_tva => $detail_qty * $sheet_prices{price_discount_tva} ,						
						detail_total_discounted_htva => $detail_qty * $sheet_prices{price_discounted_htva},
						detail_total_discounted_tvac => $detail_qty * $sheet_prices{price_discounted_tvac},
						detail_total_discounted_tva => $detail_qty * $sheet_prices{price_discounted_tva},	
				);
				%new_eshop_order_detail = %{quoteh(\%new_eshop_order_detail)};

				if($check_existing_eshop_order_detail{token} eq '')
				{
					$new_eshop_order_detail{token} = create_token(60);
				}

				member_add_event({group=>'eshop',type=>"add_cart",name=>"Ajout au panier de l'article <span>$detail_reference $detail_label x $detail_qty </span>",detail=> $eshop_order{id}});
				
				#ajout/maj ligne detail
				$new_eshop_order_detail{id} = sql_set_data({debug=>0, dbh=>$dbh, table=>"eshop_order_details",data=>\%new_eshop_order_detail,where=>"id='$check_existing_eshop_order_detail{id}'"});
				log_debug("$eshop_order{id}: Ajout détail OK",'','eshop_add_cart');
				
				#sauvegarde du referer						
				my $referer = $ENV{'HTTP_REFERER'};
				$referer =~ s/\'/\\\'/g;
				
				$stmt = "UPDATE eshop_orders SET referer='$referer' where id='$eshop_order{id}'";
			    $cursor = $dbh->prepare($stmt);
			    $cursor->execute || suicide($stmt); 
				log_debug("$eshop_order{id}: Ajout OK",'','eshop_add_cart');

				# Fonction sur-mesure d'after add
				my $after_add_cart = get_quoted("after_add_cart") || $config{handmade_after_add_cart};
				if($after_add_cart ne "")
				{
					my $fct = 'def_handmade::'.$after_add_cart;
					&$fct({eshop_order=>\%eshop_order, eshop_order_detail=>\%new_eshop_order_detail, data_stock=>\%data_stock});
				}

				# Remise à "n" de la colonne qui indique 
				# si Bpost a calculé les frais de port
				%eshop_order = %{reset_bpost_compute({order=>\%eshop_order})};

				recompute_order();				
		}

		if($config{eshop_no_lightbox} eq 'y')
		{
			print 'no_ligthtbox';
		}
		else
		{
			print 'ok';
		}
}



################################################################################
#save_coupon
################################################################################
sub save_coupon
{
	see();

	#read order
	my %order = %{get_eshop_order()};

	log_debug("save_coupon pour $order{id} D","","save_coupon");


	if(!($order{id}>0))
	{
		print '<div class="alert alert-warning" role="alert">'.$sitetxt{eshop_no_order_msg}.'</div>';
		exit;
	}

	if($order{coupon_txt} ne '')
	{
		print '<div class="alert alert-warning" role="alert">'.$sitetxt{eshop_err_deja}.'</div>';
		exit;
	}

	my $coupon = uc(trim(get_quoted('coupon')));
	my $id_tarif = eshop_get_id_tarif_member();
	my $retour = '';
	my %coupon_valide = ();
	
	if($coupon =~ /[A-Z0-9,]+/ && $coupon ne '')
	{
		%coupon_valide = sql_line({debug=>1,debug_results=>1,table=>'eshop_discounts',where=>"(coupon_qte_totale = 0 OR coupon_qte_restante > 0) AND (target_coupons LIKE '%,$coupon,%' OR target_coupons = '$coupon') AND id_tarif='$id_tarif' AND visible = 'y' AND (begin_date = '0000-00-00' OR CURRENT_DATE >= begin_date) AND (end_date = '0000-00-00' OR CURRENT_DATE <= end_date)"});
	}

	if($coupon_valide{id} > 0)
	{
		#enregistre le coupon dans la commande
		my $stmt = "UPDATE eshop_orders SET coupon_txt='$coupon',coupon_id_eshop_discount='$coupon_valide{id}' where id='$order{id}'";
		execstmt($dbh,$stmt);

		#journal utilisation du coupon
		my %coupon_journal = (
			id_eshop_order => $order{id},
			id_eshop_discount => $coupon_valide{id},
			date_utilisation => 'NOW()',
			coupon_txt => $coupon,
		);
		my $id_journal = inserth_db($dbh,"coupon_journal",\%coupon_journal);

		#recalcul le nb de coupons restants
		my $stmt = <<"EOH";
	UPDATE eshop_discounts d SET coupon_qte_restante = (coupon_qte_totale - (SELECT COUNT(*) FROM coupon_journal WHERE id_eshop_discount=d.id)) WHERE target_coupons != '' AND coupon_qte_totale > 0
EOH
		execstmt($dbh,$stmt);

		log_debug("JOURNAL: $stmt","","save_coupon");
	}
	else
	{
		log_debug("COUPON NON VALIDE pour $order{id}: $coupon","","save_coupon");

		$retour = <<"EOH";
		<div class="alert alert-block alert-error alert-danger">
			<h4 class="alert-heading">$sitetxt{coupon_incorrect}</h4>
			<p>$sitetxt{coupon_incorrect_a} <b>$coupon</b> $sitetxt{coupon_incorrect_b}.</p>
		</div>
EOH
		print $retour;
	}

	log_debug("save_coupon pour $order{id} F","","save_coupon");

	exit;
}

################################################################################
#delete_coupon
################################################################################
sub delete_coupon
{
	see();
	
	#read order
	my %order = %{get_eshop_order()};
	if(!($order{id}>0))
	{
		print '<div class="alert alert-warning" role="alert">'.$sitetxt{eshop_no_order_msg}.'</div>';
		exit;
	}
	
	$stmt = "UPDATE eshop_orders SET coupon_txt='',coupon_id_eshop_discount=0 where id='$order{id}'";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt); 
	log_debug("$stmt",'','delete_coupon');


	$stmt = "DELETE FROM coupon_journal WHERE id_eshop_order = '$order{id}'";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt);

	#recompute order & order_details
	recompute_order();

	#recalcul le nb de coupons restants
	my $stmt = <<"EOH";
	UPDATE eshop_discounts d SET coupon_qte_restante = (coupon_qte_totale - (SELECT COUNT(*) FROM coupon_journal WHERE id_eshop_discount=d.id)) WHERE target_coupons != '' AND coupon_qte_totale > 0
EOH
	execstmt($dbh,$stmt);
}


################################################################################
#get_coupon
################################################################################
sub get_coupon
{
	see();

	log_debug('get_coupon','','get_coupon');
	
	#read order
	my %order = %{get_eshop_order()};

	log_debug($order{id},'get_coupon');
	log_debug($order{coupon_txt},'get_coupon');

	if(!($order{id}>0))
	{
		print '<div class="alert alert-warning" role="alert">'.$sitetxt{eshop_no_order_msg}.'</div>';
		exit;
	}
	
#	if($order{coupon_txt} eq '')
#	{
#		exit;
#	}

	my $id_tarif = eshop_get_id_tarif_member();
	log_debug($id_tarif,'get_coupon');
	my %coupon_valide = sql_line({table=>'eshop_discounts',where=>"(target_coupons LIKE '%,$order{coupon_txt},%' OR target_coupons = '$order{coupon_txt}') AND ( ($order{total_qty} >= target_qty AND target_qty > 0) OR target_qty = 0) AND id_tarif='$id_tarif' AND visible = 'y' AND (begin_date = '0000-00-00' OR CURRENT_DATE >= begin_date) AND (end_date = '0000-00-00' OR CURRENT_DATE <= end_date)"});
	if($coupon_valide{id} > 0)
	{
		$order{coupon_txt} = uc($order{coupon_txt});
		log_debug("coupon valide $order{coupon_txt}",'get_coupon');

		print <<"EOH";
		<i class="fa fa-check-circle" aria-hidden="true"></i> $sitetxt{eshop_coupon_conf1} <b>$order{coupon_txt}</b> $sitetxt{eshop_coupon_conf2} - <a href="#" class="eshop_delete_coupon">$sitetxt{eshop_supprimer}</a>
EOH
	}
	else
	{
		log_debug("coupon non valide $order{coupon_txt}",'get_coupon');
		# si on ne retrouve plus de coupon valide, on le supprime de la commande
		my $stmt = <<"EOH";
			UPDATE eshop_orders
			SET coupon_txt = '',coupon_id_eshop_discount=0
			WHERE id = '$order{id}'
EOH
		execstmt($dbh,$stmt);
	}

	
	
}

################################################################################
#get_cart
################################################################################
sub get_cart
{
	see();
	
	#read order
	my %order = %{get_eshop_order()};
	if(!($order{id}>0))
	{
		print '<div class="alert alert-warning" role="alert">'.$sitetxt{eshop_no_order_msg}.'</div>';
		exit;
	}
	
	my $id_tarif = eshop_get_id_tarif_member();
    my %tarif = read_table($dbh,'eshop_tarifs',$id_tarif);

	
	my $eshop_sw = get_quoted('eshop_sw');

	#recompute order & order_details
	recompute_order();	
	
	#tableau du panier
	my $page = <<"EOH";
    <table id="table_cart">
        <thead>
            <tr class="table_line_header table_line_header1">
        				<th class="cart-product">$sitetxt{eshop_produits_title}</th>
        				<th class="col_visible_$setup{show_pu_tvac} cart-price hidden-xs">$sitetxt{eshop_prix_title}</th>
        				<th class="cart-qty">$sitetxt{eshop_quantite_title}</th>
        				<th class="col_visible_$setup{show_total_tvac} cart-price hidden-xs">$sitetxt{eshop_total_title}</th>
						<th class="cart-delete ">&nbsp;</th>
            </tr>
           <tr class="table_line_header table_line_header2">
        				<th>&nbsp;</th>
        				<th class="col_visible_$setup{show_pu_tvac} cart-price hidden-xs">$sitetxt{eshop_tvac}</th>
        				<th>&nbsp;</th>
        				<th class="col_visible_$setup{show_total_tvac} cart-price hidden-xs">$sitetxt{eshop_tvac}</th>
						<th class="cart-delete ">&nbsp;</th>
          </tr>
          </thead>
          <tbody>
EOH
    
	my @order_details = sql_lines({table=>"eshop_order_details",where=>"id_eshop_order = '$order{id}'",debug=> 0,debug_results=>0,ordby=>'id'});
	if($#order_details == -1)
	{
		print '<div class="alert alert-warning" role="alert">'.$sitetxt{eshop_no_detail_msg}.'</div>';
		exit;
	}
	
    my $detail_count = 0;
    foreach $order_detail (@order_details)
    {
        my %order_detail = %{$order_detail};
        my %data_stock = read_table($dbh,"data_stock",$order_detail{id_data_stock});
        my %sheet = sql_line({dbh=>$dbh,table=>"data_sheets",select=>"id,id_textid_url_rewriting,id_data_family",where=>"id='$order_detail{id_data_sheet}'"});
        my $product_link = get_data_detail_url($dbh,\%sheet,$lg,$extlink,'y');   ;

        my %migcms_linked_file = sql_line({table=>"migcms_linked_files",where=>"table_name='data_sheets' AND token = '$order_detail{id_data_sheet}' AND table_field = 'photos'",ordby=>"ordby"});
		my $pic_path = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{name_mini};
		my $pic_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{name_mini};
		$pic_url =~ s/\.\.\///g;
		
		$pic_url = "/".$pic_url;
		$pic_url =~ s/\/\//\//;

		my $pic_html = "<img class='cart_line pic' src='$pic_url'/>";
		if($pic_url eq "/")
		{
			$pic_html  = "<span class='no_pic'></span>";
		}
		
        if(!(-e $pic_path))
        {
            # $pic_path = $htaccess_protocol_rewrite.'://'.$config{rewrite_default_url}.'/skin/default_pic_if_void.png';
        }
		
        my $has_discount = 'n';
        if($order_detail{detail_pu_discounted_htva} < $order_detail{detail_pu_htva})
        {
           $has_discount = 'y';
        }
        
        $order_detail{detail_pu_htva} = display_price($order_detail{detail_pu_htva});
        $order_detail{detail_pu_tva} = display_price($order_detail{detail_pu_tva});
        $order_detail{detail_pu_tvac} = display_price($order_detail{detail_pu_tvac});
        
        $order_detail{detail_total_htva} = display_price($order_detail{detail_total_htva});
        $order_detail{detail_total_tva} = display_price($order_detail{detail_total_tva});
        $order_detail{detail_total_tvac} = display_price($order_detail{detail_total_tvac});
        
        $order_detail{detail_pu_discounted_htva} = display_price($order_detail{detail_pu_discounted_htva});
        $order_detail{detail_pu_discounted_tva} = display_price($order_detail{detail_pu_discounted_tva});
        $order_detail{detail_pu_discounted_tvac} = display_price($order_detail{detail_pu_discounted_tvac});
        
        $order_detail{detail_total_discounted_htva} = display_price($order_detail{detail_total_discounted_htva});
        $order_detail{detail_total_discounted_tva} = display_price($order_detail{detail_total_discounted_tva});
        $order_detail{detail_total_discounted_tvac} = display_price($order_detail{detail_total_discounted_tvac});
        
        my $qty = $order_detail{detail_qty};
        my $alert = '';
		 
        if($eshop_sw eq 'cart')
        {
            if($order_detail{avert_stock} eq 'y')
            {
                $alert=<<"EOH";
                   <tr>
					   <td colspan="5">
						   <div class="alert alert-block alert-info alert-info">
								$sitetxt{eshop_cart_3}                    
						  </div>
					  </td>
				  </tr>
EOH
            } 
            my $stmt = "UPDATE eshop_order_details SET avert_stock= 'n' WHERE id_eshop_order = '$order{id}'";
			execstmt($dbh,$stmt);
			
			$qty = <<"EOH";
				<div>
					<input autocomplete="off" type="text" data-detailtoken="$order_detail{token}" value="$order_detail{detail_qty}" class="eshop_change_qty form-control" id="" name="qty" />
					<button class="eshop_change_qty_save btn-xs btn btn-default hide">$sitetxt{'eshop_cart_4'}</button>
				</div>
EOH
   
        
			#si l'option desactive lien vers le détail n'est pas à y
			if($setup{disable_detail_link} ne 'y')
			{
				$order_detail{detail_label} = <<"EOH";
					  <a href="$product_link">$order_detail{detail_label}</a>
EOH
			}
        
        }
		else
		{
			$qty = $order_detail{detail_qty};
		}
        
        my $pu = $order_detail{detail_pu_tvac};
        my $pu_discounted = $order_detail{detail_pu_discounted_tvac};
        my $total = $order_detail{detail_total_tvac};
        my $total_discounted = $order_detail{detail_total_discounted_tvac};
        my $suffixe = $sitetxt{eshop_tvac};
        if($tarif{is_tvac} ne 'y')
        {
            $suffixe = $sitetxt{eshop_htva};
        }
        if(($order{is_intracom} && $order{do_intracom} eq 'y') || $tarif{is_tvac} ne 'y')
        {
            $suffixe = $sitetxt{eshop_htva};
            $pu = $order_detail{detail_pu_htva};
            $pu_discounted = $order_detail{detail_pu_discounted_htva};
            $total = $order_detail{detail_total_htva};
            $total_discounted = $order_detail{detail_total_discounted_htva};
        }
		
		my $delete_link = <<"EOH";
		<a href="#" data-detailtoken="$order_detail{token}" data-placement="right"  title="$sitetxt{eshop_supprimer}" data-original-title="$sitetxt{eshop_supprimer}" class="eshop_del_detail btn btn-link"><i class="icon-trash glyphicon glyphicon-remove"></i></a>
EOH
		if($eshop_sw eq 'recap')
		{
			$delete_link = '';
		}
        
        $page .=<<"EOH";
        <tr class="table_line_body">
            <td class="cart-product">        
                    <div class="media">
                        <span class="pull-left hidden-xs">
                          $pic_html
                        </span>
                        <div class="media-body">
                            <h2 class="media-heading">$order_detail{detail_label}</h2>
                            <p>$order_detail{detail_reference}</p>
                        </div>
                    </div>
              </td>

              <td class="col_visible_$setup{show_pu_tvac} cart-price hidden-xs">
                    <span class="eshop_price full_with_discount_$has_discount">$pu $suffixe</span>
                  <br /><span class="eshop_price discount_$has_discount">$pu_discounted $suffixe</span>
              </td>
              <td class="cart-qty">
                    $qty 
              </td>
            
              <td class="col_visible_$setup{show_total_tvac} cart-price hidden-xs">
                   <span class="eshop_price full_with_discount_$has_discount">$total $suffixe</span>
                  <br /><span class="eshop_price discount_$has_discount">$total_discounted $suffixe</span>
              </td>
               <td class="cart-delete">
                  $delete_link
              </td>
      </tr> 
	  $alert
EOH
    }
    
    $page .=<<"EOH";
        </tbody>
        </table>
EOH
	print $page;
	exit;
}


################################################################################
# get_mini_cart
################################################################################
sub get_mini_cart
{
	see();
	
	#read order
	my %order = %{get_eshop_order()};
	if(!($order{id}>0))
	{
		print '<div class="alert alert-warning" role="alert">'.$sitetxt{eshop_no_order_msg}.'</div>';
		exit;
	}

	#recompute order & order_details
	recompute_order();	
	
	my $id_tarif = eshop_get_id_tarif_member();
    my %tarif = read_table($dbh,'eshop_tarifs',$id_tarif);
    
	my $total_tvac = display_price($order{total_tvac});
	my $total_htva = display_price($order{total_htva});
	my $total_tva = display_price($total_tvac - $total_htva);
	
	my $remise_htva = display_price($order{total_discount_htva});
	my $coupons_htva = display_price($order{total_coupons_htva});
	my $port_htva = display_price($order{total_delivery_htva});
	
	my $remise_tvac = display_price($order{total_discount_tvac});
	my $coupons_tvac = display_price($order{total_coupons_tvac});
	my $port_tvac = display_price($order{total_delivery_tvac});
	
	my $apayer_htva = display_price($order{total_discounted_htva});
	my $apayer_tva = display_price($order{total_discounted_tva});
	my $apayer_tvac = display_price($order{total_discounted_tvac});	

	if(($order{is_intracom} && $order{do_intracom} eq 'y') || $tarif{pay_tvac} ne "y")
	{
		$apayer_tva = '-';
		$apayer_tvac = $apayer_htva;
	}

	my $alert_restant_pour_port_offert = '';
    if($setup{montant_pour_livraison_gratuite} > 0)
    {
        if($order{total_htva} >= $setup{montant_pour_livraison_gratuite})
        {
             my $restant = $setup{montant_pour_livraison_gratuite} - $order{total_htva};
             $alert_restant_pour_port_offert = <<"EOH";
				  <div class="alert alert-success">
					<strong>Frais de ports offerts</strong><br />Le total de vos articles a atteint $setup{montant_pour_livraison_gratuite}€
				   </div>
EOH
        }
        else
        {
             my $restant =  $setup{montant_pour_livraison_gratuite} - $order{total_htva};
             $alert_restant_pour_port_offert = <<"EOH";
				  <div class="alert alert-warning">
					  <strong>Encore $restant €</strong> <p>Ajoutez encore $restant € dans votre panier pour obtenir la livraison gratuite de votre commande</p>
				  </div>
EOH
        }
    }
	 if($total_tva eq '')
	 {
		$total_tva= '-';
	 }
	my $recap = <<"EOH";
		 <table>
			<tr class="total_articles_line total_articles_line_htva">
				<td>
					<!-- Total HTVA-->
					$sitetxt{'eshop_recapbox_1'} $sitetxt{'eshop_htva'} :
				</td>
				<td class="cart_recap_price_col2">
					$total_htva
				</td>
			</tr>
			<tr class="total_articles_line total_articles_line_tva">
				<td>
					<!-- Total HTVA-->
					$sitetxt{'eshop_recapbox_1'} $sitetxt{'eshop_tva'} :
				</td>
				<td class="cart_recap_price_col2">
					$total_tva
				</td>
			</tr>
			<tr class="total_articles_line">
				<td>
					<!-- Total HTVA-->
					$sitetxt{'eshop_recapbox_1'} $sitetxt{'eshop_tvac'} :
				</td>
				<td class="cart_recap_price_col2">
					$total_tvac
				</td>
			</tr>
			
EOH
			if($order{total_discount_htva} > 0)
			{
				$recap .= <<"EOH";
					<tr class="total_articles_line">
						<td>
							<!-- Remise HTVA-->
							$sitetxt{'eshop_recapbox_4'} :
						</td>
						<td class="cart_recap_price_col2">
							- $remise_tvac
						</td>
					</tr>
EOH
			}
			
			if($order{total_coupons_htva} > 0)
			{
				$recap .= <<"EOH";
					<tr class="total_articles_line">
						<td>
							<!-- Coupons HTVA-->
							$sitetxt{'eshop_recapbox_5'}:
						</td>
						<td class="cart_recap_price_col2">
							- $coupons_tvac
						</td>
					</tr>
EOH
			}
			
	$recap .= <<"EOH";
				<tr class="total_articles_line">
					<td>
						<!-- port HTVA-->
						$sitetxt{'eshop_invoice2_fraisports'}:
					</td>
					<td class="cart_recap_price_col2">
						$port_tvac
					</td>
				</tr>
			
				
				<tr class="total_articles_line">
					<td>
						<!-- Total TTC à payer-->
						<b>$sitetxt{'eshop_invoice2_totalttc'}</b>:
					</td>
					<td class="cart_recap_price_col2">
					<b>$apayer_tvac</b>
					</td>
				</tr>
				</table>
EOH
	
	print $recap;
	exit;
}

################################################################################
# get_micro_wishlist
################################################################################
sub get_micro_wishlist
{	
	my $qty = 0;
	
	#read order
	my %member = %{members_get()};
	if($member{id}> 0)
	{
		my @wishlist = sql_lines({table=>"data_sheets_wishlist", where=>"id_member = '$member{id}' AND id_member != ''"});

		$qty = $#wishlist + 1;
	}

	see();
	print $qty;
	exit;
}


################################################################################
# get_micro_cart
################################################################################
sub get_micro_cart
{
	see();
	log_debug('get_micro_cart','vide','get_micro_cart');
	my $qty = 0;
	
	#read order
	my %order = %{get_eshop_order()};
	log_debug('order:'.$order{id},'','get_micro_cart');
	log_debug('total_qty:'.$order{total_qty},'','get_micro_cart');
	if($order{id}> 0 && $order{total_qty} > 0)
	{
		print int($order{total_qty});
		exit;
	}
	print $qty;
	exit;
}


################################################################################
# get_micro_cart
################################################################################
sub get_micro_cart_price
{
	see();

	#read order
	my %order = %{get_eshop_order()};
	my $apayer_tvac = display_price($order{total_discounted_tvac});	
	if($order{id}> 0 && $order{total_discounted_tvac} > 0)
	{
		print $apayer_tvac;
		exit;
	}
	print $apayer_tvac;
	exit;
}


################################################################################
# lightbox_confirmation_wishlist
################################################################################
sub lightbox_confirmation_wishlist
{
  see();
	
	$sitetxt{member_url_wishlist} =~ s/\/\//\//;
	
	my $content = <<"EOH";
    <div id="shop_menu_addtocart">
    		<div id="shop_menu_addtocart_logo"></div>
    		<div id="shop_menu_addtocart_txt">$sitetxt{eshop_wishlist_lightbox_items_added}</div>
    		<ul>
        		<li id="shop_menu_addtocart_menu1"><a class="btn btn-primary lightboxlink" href="#" onclick="\$.fancybox.close();return false;">$sitetxt{eshop_cart_lightbox_continue}</a></li>
        		<li id="shop_menu_addtocart_menu2"><a href="$config{baseurl}/$sitetxt{member_url_wishlist}" class="btn btn-primary lightboxlink">$sitetxt{eshop_wishlist_lightbox_view}</a></li>
    		</ul>
	</div> 
EOH
    
  display($content,'','blank');
}


################################################################################
# lightbox_confirmation
################################################################################
sub lightbox_confirmation
{
    see();
	
	$sitetxt{eshop_url_panier} = $sitetxt{eshop_url_panier};
	$sitetxt{eshop_url_panier} =~ s/\/\//\//;

	
	my $content = <<"EOH";
    <div id="shop_menu_addtocart">
    		<div id="shop_menu_addtocart_logo"></div>
    		<div id="shop_menu_addtocart_txt">$sitetxt{eshop_cart_lightbox_items_added}</div>
    		<ul>
        		<li id="shop_menu_addtocart_menu1"><a class="btn btn-primary lightboxlink" href="#" onclick="\$.fancybox.close();return false;">$sitetxt{eshop_cart_lightbox_continue}</a></li>
        		<li id="shop_menu_addtocart_menu2"><a href="$config{baseurl}/$sitetxt{eshop_url_panier}" class="btn btn-primary lightboxlink">$sitetxt{eshop_cart_lightbox_viewcart}</a></li>
    		</ul>
	</div> 
EOH
    
    if(trim($instruction_supp) eq 'identity_plz')
    {
        $content = <<"EOH";
    <div id="shop_menu_addtocart">
    		<div id="shop_menu_addtocart_logo"></div>
    		<div id="shop_menu_addtocart_txt">Commencez par vous connecter avant de débuter votre commande svp</div>
    		
	</div> 
EOH
    
    }
		
	my %eshop_order = %{get_eshop_order()};
    display($content,'','blank');
}


################################################################################
# get_data_detail_url
################################################################################
sub get_data_detail_url
{
 my $dbh = $_[0];
 my %sheet = %{$_[1]};
 my $lg = $_[2] || $config{current_language};
 my $extlink = $_[3] || 1;
 my $full_url = $_[4] || 'n';
 my $id_data_family = $_[6];
 
 my $domaine = $config{fullurl}.'/';
 if($full_url ne 'y')
 {
      $domaine = '';
 }
 
 if(!($id_data_family > 0))
 {
  $id_data_family = $sheet{id_data_family};
 }
 if(!($id_data_family > 0))
 {
  $id_data_family = $cfg{default_family};
 }
 my %fam = sql_line({debug=>0,table=>"data_families",select=>'id,id_textid_url_rewriting,id_textid_fiche',where=>"id='$id_data_family'"});

 my ($url_rewriting,$empty) = get_textcontent($dbh,$fam{id_textid_url_rewriting},$lg);
 my ($fiche,$empty) = get_textcontent($dbh,$fam{id_textid_fiche},$lg);
 my ($name,$empty) = get_textcontent($dbh,$sheet{id_textid_url_rewriting},$lg);
 # $name  =~ s/\-//g;
 $name = clean_url($name);
 
  $fiche = $fiche || 'detail';
 
 
  my %lg = sql_line({debug=>0,table=>"migcms_languages",select=>"name",where=>"id='$lg'"});
  
  if($domaine eq '')
  {
	$domaine = $config{baseurl}.'/';
  }
  
  my $url = $domaine."$lg{name}/$url_rewriting/$fiche/$name-$sheet{id}-$extlink";
  
  return $url; 
}


################################################################################
#delete_detail_line
################################################################################
sub delete_detail_line
{
	see();
	
	my $token = get_quoted('token');
	
	my %eshop_order_detail = sql_line({table=>'eshop_order_details',where=>"token='$token'"});
	my %eshop_order = sql_line({table=>'eshop_orders',where=>"id='$eshop_order_detail{id_eshop_order}'"});
	if($eshop_order{status} eq 'begin')
	{
		my $stmt = "DELETE FROM eshop_order_details WHERE token = '$token'";
		execstmt($dbh,$stmt);
	}	
	exit;
}



################################################################################
#edit_cart_qty
################################################################################
sub edit_cart_qty
{
	see();
	my $token = get_quoted('token');

	my $qty = get_quoted('qty');
	if($qty == 0)
	{
		delete_detail_line($token);
		exit;
	}
	elsif($qty < 1)
	{
		$qty = 1;
	}
	
	my %eshop_order_detail = sql_line({table=>'eshop_order_details',where=>"token='$token'"});
	my %eshop_order = sql_line({table=>'eshop_orders',where=>"id='$eshop_order_detail{id_eshop_order}'"});
	if($eshop_order{status} eq 'begin' || $eshop_order{status} eq 'unfinished')
	{
		my $stmt = "UPDATE eshop_order_details SET detail_qty= '$qty' WHERE token = '$token'";
		execstmt($dbh,$stmt);
	}
	exit;
}

################################################################################
#DISPLAY
################################################################################
sub display
{
  my $content=$_[0];
  my $id_tpl_page = $_[2];
  if(!($id_tpl_page > 0) && $id_tpl_page ne 'blank' )
  {
		$id_tpl_page = $setup{id_tpl_page1};
  }
  $content .= '<input type="hidden" id="eshop_lg" value="'.$lg.'" />'.'<input type="hidden" id="eshop_sw" value="'.$sw.'" />';

  if($setup{shop_disabled} eq 'y')
  {
      cgi_redirect($config{fullurl});
      exit;     
  }
  else
  {
      if($id_tpl_page ne 'blank')
      {
					my $meta_title = $sitetxt{'eshop_metatitle_'.$sw};
					my $tag = '<MIGC_METATITLE_SHOP_HERE>';
					$content =~ s/$tag/$meta_title/g;

					my $page_content = render_page({debug=>0,content=>$content,id_tpl_page=>$id_tpl_page,lg=>$lg});

					
					print $page_content;
      }
      else
      {
          print $content;
      }
  }
  exit;
}

################################################################################
# check_vat_order
################################################################################  
sub check_vat_order
{
    my $vat = $_[0];
    my $id_order = $_[1];
    my $prefix = $_[2];
    my $id_country = $_[3];
    my $do_intracom = $_[4];
	
	my $vies_non_dispo = 0;

    if(trim($vat) ne '' && $do_intracom eq 'y')
    {
        my $is_intracom = 0;
        my %country = read_table($dbh,'countries',$id_country);
        if($country{is_intracom} eq 'y')
        {
            my ($result,$error_code,$error_txt,$vies_non_dispo) = check_vat($vat,$id_order);
            $error_txt =~ s/\'/\\\'/g;
			
            if($result > 0)
            {
                $result = 1;
                $is_intracom = 1;
            }
            elsif($error_code > 16 && $setup{accept_intracom_order_if_tva_check_is_disabled} eq 'y')
            {
                $result = 1;
                $is_intracom = 1;
				$vies_non_dispo = 0;
            }
            elsif($error_code > 16 && $setup{accept_intracom_order_if_tva_check_is_disabled} ne 'y')
            {
                $result = 2;
                $is_intracom = 0;
            } 
            else 
            {
                $result = 2;
                $is_intracom = 0;
            }
			
            my %update_order = 
            (
                  $prefix.'_vat_status' => $result,
                  $prefix.'_vat_code' => $error_code,
                  $prefix.'_vat_txt' => $error_txt,
                  'is_intracom' => $is_intracom
            );
            updateh_db($dbh,"eshop_orders",\%update_order,"id",$id_order);
            return ($result,$vies_non_dispo);
        }
        else
        {
            my %update_order = 
            (
                  'is_intracom' => 0
            );
            updateh_db($dbh,"eshop_orders",\%update_order,"id",$id_order);
            return 1;
        }
    }
    else
    {
        my %update_order = 
        (
              'is_intracom' => 0
        );
        updateh_db($dbh,"eshop_orders",\%update_order,"id",$id_order);
        return 1;
    }
}


################################################################################
# check_vat
################################################################################  
sub check_vat
{
    use Business::Tax::VAT::Validation;
    
    my @vat = split(//,$_[0]);
    
    my $id_order = $_[1];
    
    my $vat_code = shift @vat;
    $vat_code .= shift @vat;
    my $vat_number = join("",@vat);
    $vat_number =~ s/\D//g;
    
    my $vat = $vat_code.$vat_number;
   
    $stmt = "UPDATE eshop_orders SET delivery_vat='$vat',billing_vat='$vat' where id='$id_order'";
    execstmt($dbh,$stmt);
    
    my $hvatn = Business::Tax::VAT::Validation->new();
    
    if($hvatn->check($vat))
    {
        return (1,'','');
    }
    else
    {
        my $error_code = $hvatn->get_last_error_code();
        my $error_txt = $hvatn->get_last_error();
		
		
		my $vies_non_dispo = 0;
		if($error_code >=17)
		{
			$vies_non_dispo = 1;
		}
        return (0,$error_code,$error_txt,$vies_non_dispo);
    }
}



################################################################################
# link_order_to_member
################################################################################  
sub link_order_to_member
{
	my $password = sha1_hex(trim(get_quoted('password')));
    my $token_order = get_quoted ('token_order');
    my $billing_email = get_quoted ('billing_email');
    my %member = sql_line({debug=>0,table=>"migcms_members",select=>'id,token,id_tarif,stoken',where=>"LOWER(email) = LOWER('$billing_email') AND LOWER(password) = LOWER('$password') AND password != '' "});
    my %order = sql_line({debug=>0,table=>'eshop_orders',where=>"token='$token_order'"});
    if($member{id} > 0)
    {
       my $stmt = "UPDATE eshop_orders SET id_member = $member{id} WHERE id = '$order{id}'";
       execstmt($dbh,$stmt);
       member_login_db({stoken=>$member{stoken}, url_after_login=>"$config{fullurl}/cgi-bin/members.pl?"});
       exit;
    }
    else
    {
        see();
        print<<"EOH";
      		<script language="javascript">
      		alert("Mot de passe incorrect");
      		history.go(-1);
      		</script>
EOH
    }
}

################################################################################
#FACT
################################################################################
sub fact
{
    see();
    my $token = get_quoted('token') || $_[0];
    my %order = sql_line({table=>'eshop_orders',where=>"token='$token'"});
    
    if($order{id} > 0 && $token ne '')
    {
         my $html = eshop_mailing_facture(\%order, "y");
         print $html;
    }
    else
    {
        print "Erreur d'identification";
        exit;
    }
}

################################################################################
# retour
################################################################################
sub retour
{
	my $token = get_quoted("token");
	my $mail = get_quoted("mail");


	my $content = eshop::get_order_retour_content({token=>$token});


	my $mail_msg;
	if($mail eq 'ok')
  {
    $mail_msg = <<"EOH";
      <div class="alert alert-block alert-success alert-success">
        <p>$sitetxt{retour_submitted}</p>
      </div>
EOH
  }


	my $page = <<"HTML";
	<div id="eshop" class="clearfix">
		$mail_msg
		$content
	</div>
HTML

	see();
 	display($page,'',$setup{id_tpl_page1});
}

################################################################################
# retour_db
################################################################################
sub retour_db
{
  my $token = get_quoted('token');
  
  my %order = sql_line({table=>'eshop_orders',where=>"token='$token'"});
  
  my $type                      = $sitetxt{'retour_'.get_quoted('retour_type')};
  my $retour_references         = get_quoted('retour_references');
  my $retour_echange_precisions = get_quoted('retour_echange_precisions');
  my $retour_raison             = get_quoted('retour_raison');
  my $retour_iban               = get_quoted('retour_iban');
  my $retour_bic                = get_quoted('retour_bic');
  
  my $details = <<"EOH";
  <table width="630" border="0" cellpadding="5" cellspacing="0" bgcolor="#ffffff" align="center" class="">

      <tr>
        <th align="center" bgcolor="#173a5d" width="300"><font color="#ffffff">$sitetxt{'eshop_fac_7'}</font></th>
        <th align="center" bgcolor="#173a5d" width="30"><font color="#ffffff">$sitetxt{'eshop_fac_8'} </font></th>
        <th align="center" bgcolor="#173a5d" width="60"><font color="#ffffff">$sitetxt{'eshop_fac_9'} $precision</font></th>
        <th align="center" bgcolor="#173a5d" width="75"><font color="#ffffff">$sitetxt{'eshop_fac_10'} $precision</font></th>
      </tr>
EOH

  my @order_details = get_table($dbh,"eshop_order_details",'',"id_eshop_order = '$order{id}'",'','','',0);
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
          
      if(get_quoted('detail_'.$order_detail{id}) eq 'y')
      {
        $details .= <<"EOH"; 
          <tr bgcolor="#fcfcfc">
            <td>
              <label><input type="checkbox" checked name="detail_$order_detail{id}" value="y" />
              <font color="#224c75"><b>$order_detail{detail_label}</b></font><br />
                 <font color="#838383">Ref : $order_detail{detail_reference}</font>
                 </label>
            </td>
            <td align="center"><b>$order_detail{detail_qty}</b></td>
            <td align="right"><b> $pu_discounted</b></td>
            <td align="right"><b> $total_discounted</b></td>
          </tr>
EOH
      }
  
  }
  
  $details .= <<"EOH"; 
    </table>
EOH
  
  my $infos_adresses = <<"EOH";
    <b>$sitetxt{'eshop_ad_liv'} :</b>
    <br /><br />
    $order{delivery_company}
    $order{delivery_vat}
    $order{delivery_firstname} $order{delivery_lastname}
    <br />$order{delivery_street} $order{delivery_number} $order{delivery_box}
    <br />$order{delivery_zip} $order{delivery_city}<br />
    $delivery_country{fr}<br />
    $order{delivery_phone}<br />
    $order{delivery_email}<br />
    <br /><br />
    <b>$sitetxt{'eshop_ad_fac'} :</b>
    <br /><br />
    $order{billing_company}
    $order{billing_vat}
    $order{billing_firstname} $order{billing_lastname}
    <br />$order{billing_street} $order{billing_number} $order{billing_box}
    <br />$order{billing_zip} $order{billing_city}<br />
    $billing_country{fr}<br />
    $order{billing_phone}<br />
    $order{billing_email}<br />
EOH
  
  my $message_html = << "EOH";
  <b>Commande N</b>: $order{id}         <br />
  <br /><br />
  $infos_adresses
  <br /><br />
  <b>$sitetxt{retour_question}</b>: $type     <br /><br />
  <b>$sitetxt{retour_references}</b>: $details    <br /><br />
  <b>$sitetxt{retour_echange_precisions}</b>: $retour_echange_precisions    <br /><br />
  <b>$sitetxt{retour_raison}</b>: $retour_raison    <br /><br />
  <b>$sitetxt{retour_iban}</b>: $retour_iban    <br /><br />
  <b>$sitetxt{retour_bic}</b>: $retour_bic    <br /><br />
EOH

  #Envoi a l'administrateur de la boutique
  send_mail($order{delivery_email},$setup{eshop_email},'Commande N'.$order{id}.': '.$type,$message_html,'html');
  send_mail($order{delivery_email},'dev@bugiweb.com','COPIE BUGIWEB : Commande N'.$order{id}.': '.$type,$message_html,'html');
  

  # Si le membre est connecté on le redirige vers son compte
  my %member = %{members::members_get()};
  if($member{id} > 0)
  {
  	cgi_redirect($config{fullurl}.'/'.'cgi-bin/members.pl?lg='.$lg.'&extlink='.$extlink . "&sw=member_orders_history&mail=ok");
  }
  else
  {
  	cgi_redirect($config{fullurl}.'/'.$sitetxt{eshop_url_retour}."&token=$order{token}&mail=ok");
  }
}

################################################################################
# get_facture
################################################################################
sub get_facture
{
  my $token = get_quoted('token');
  my $type= get_quoted("type") || "commande";
  my $file = ''; 
  if($config{eshop_facture_sub} ne '')
  {
     my $sub = $config{eshop_facture_sub};
     $file =  &$sub($token);
  }
  else
  {
    $file =  generate_facture($token, $type);
  }
  my @tmp = split(/\//,$file);
  my $file_display = $tmp[$#tmp];
  print $cgi->header(-attachment=>$file_display,-type=>'application/pdf');
  open (FILE,$file);
  binmode FILE;
  binmode STDOUT;
  while (read(FILE,$buff,2096)){
    print STDOUT $buff;
  }
  close (FILE);

  exit;
}


sub eshop_get_form
{
	my @champs = @{$_[0]};
	my $type = $_[1];
	my $form = '';
	
	my %optionnel_txt = 
	(
		'' => ucfirst($sitetxt{eshop_optionnel}),
		'required' => '',
	);
	
	my $input_email_readonly ="";
	if($setup{frontend_cant_modify_email} eq "y") {
		$input_email_readonly ="readonly=readonly";
	}
	
	my $input_billing_readonly ="";
	if($setup{frontend_cant_modify_billing} eq "y" && $type eq "billing") {
		$input_billing_readonly ='readonly="readonly"';
	}
	
	foreach my $champ (@champs)
	{
		my %champ = %{$champ};

		my $mandatory_fields = "";
		if($champ{required} eq "required")
		{
			$mandatory_fields = "*";
		}

		if($champ{display} ne "n")
		{

			#valeurs par défaut--------------------------------------------
			if($champ{type} eq '')
			{
				$champ{type} = 'text';
			}
			if($champ{class} eq '')
			{
				$champ{class} = 'input-xlarge';
			}
			#construction formulaire-------------------------------------------------------------	
	        if($champ{type} eq 'text' || $champ{type} eq 'password')
	        {
				$form .=<< "EOH";
					<div class="form-group form-group-$champ{name}">
							 <label class="control-label col-sm-4" for="$champs[$i]">$champ{label} <span class="eshop_mandatory">$mandatory_fields</span></label>
								   <div class="col-sm-8">
									<input type="$champ{type}" name="$champ{name}" $champ{required} placeholder="$champ{hint}" value="$champ{valeurs}{$champ{name}}" class="$champ{class} $champ{required} form-control" $input_billing_readonly /> 
									<span class="help-block">
										<span class="facultatif">$optionnel_txt{$champ{required}}</span>
										
										$champ{suppl}
									</span>
							 </div>
					</div>
EOH
				
	        }
			elsif($champ{type} eq 'email')
	        {
				$form .=<< "EOH";
					<div class="form-group form-group-$champ{name}">
							 <label class="control-label col-sm-4" for="$champs[$i]">$champ{label} <span class="eshop_mandatory">$mandatory_fields</span></label>
								   <div class="col-sm-8">
									<input type="$champ{type}" name="$champ{name}" $champ{required} placeholder="$champ{hint}" value="$champ{valeurs}{$champ{name}}" class="$champ{class} $champ{required} form-control" $input_email_readonly $input_billing_readonly /> 
									<span class="help-block">
										<span class="facultatif">$optionnel_txt{$champ{required}}</span>
										
										$champ{suppl}
									</span>
							 </div>
					</div>
EOH
				
	        }
			elsif($champ{type} eq 'delivery_google_search')
	        {
				$form .=<< "EOH";
					<div class="form-group form-group-delivery_google_search">
							 <label class="control-label col-sm-4" for="$champs[$i]"> </label>
								   <div class="col-sm-8">
										<small>$sitetxt{eshop_googlemap_label}</small>
										<input type="text" class="input-xlarge  form-control" value="" name="delivery_google_autocomplete" id="delivery_google_autocomplete" />
										<span class="help-block">
									</span>
							 </div>
					</div>
EOH
				
	        }
			elsif($champ{type} eq 'billing_google_search')
	        {
				$form .=<< "EOH";
					<div class="form-group form-group-billing_google_search">
							 <label class="control-label col-sm-4" for="$champs[$i]"> </label>
								   <div class="col-sm-8">
										<small>$sitetxt{eshop_googlemap_label}</small>
										<input type="text" class="input-xlarge  form-control" value=""  name="billing_google_autocomplete" id="billing_google_autocomplete" $input_billing_readonly />
										<span class="help-block">
									</span>
							 </div>
					</div>
EOH
				
	        }
	        elsif($champ{type} eq 'countries_list')
	        {
	            # see(\%champ);
				#liste des pays (FR, NL, ANGLAIS sinon)
				my $col = 'en';
	            if($lg == 1)
	            {
	                $col = "fr";
	            }
	            elsif($lg == 3)
	            {
	                $col = "nl";
	            }
				
				my $country = $champ{valeurs}{$champ{name}};
				if(!($country > 0))
				{
					$country = $setup{cart_default_id_country};
				}
				
	            my $listbox_countries = sql_listbox(
	             {
	                dbh       =>  $dbh,
	                name      => $champ{name},
	                select    => "c.id,$col",
	                table     => 'shop_delcost_countries dc, countries c',
	                where     => 'dc.isocode=c.iso',
	                ordby     => $col,
	                show_empty=> 'y',
	                empty_txt =>  $sitetxt{eshop_veuillez},
	                value     => 'id',
	                current_value     => $country,
	                display    => $col,
	                required => 'required',
	                id       => '',
	                class    => 'input-xlarge required form-control',
	                debug    => 0,
					readonly => 'y'
	             }
	            );
				
				$form .=<< "EOH";
					<div class="form-group form-group-$champ{name}">
						<label class="control-label col-sm-4">$sitetxt{'eshop_country'} <span class="eshop_mandatory">$mandatory_fields</span> </label>
						<div class="col-sm-8">
							$listbox_countries
							<span class="help-block">
								<span class="facultatif">$optionnel_txt{$champ{required}}</span>
								<em>$champ{hint}</em>
								$champ{suppl}
							</span>
						</div>
					</div>
EOH
				
	        }
	    }
        $i++;
	}

	return $form;
}
