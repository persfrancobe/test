#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
package bugi_stripe;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@ISA = qw(Exporter);	
@EXPORT = qw(
  stripe_form_elements
  stripe_form_elements_db

  stripe_source_form
  stripe_source_db
  stripe_source_post_paiement


  $stripe_pulic_key
  $stripe_secret_key
  
  get_stripe_url_redirect_after_success
  get_stripe_url_redirect_after_error
);
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use def;
use tools;
use sitetxt;
use sws;
use setup;
use JSON::XS;
use eshop;


# use XML::Simple;
# use HTML::Entities;
# use Encode qw(decode encode);


my $lg = get_quoted('lg');
if ($lg eq "") {$lg = $config{current_language};}


$lg =~ s/undefined//g;
$config{current_language} = $config{default_colg} = $lg;

$stripe_pulic_key  = get_stripe_public_key();
$stripe_secret_key = get_stripe_secret_key();
$stripe_url_redirect_after_success = $config{fullurl} . "/cgi-bin/eplus.pl?sw=list_badges&msg=stripe_ok";
$stripe_url_redirect_after_error = $config{fullurl} . "/cgi-bin/eplus.pl?sw=mon_panier_db";

sub get_setup_stripe
{
	my %d = %{$_[0]};
  my $lg = $d{lg} || 1;
	$lg =~ s/\D//g;
	if(!($lg > 0 && $lg <= 10))
	{
		$lg = 1;
	}
  my %setup = sql_line({table=>"members_setup"});
  if($setup{id} > 0)
  {
    foreach my $key (keys %setup)
    {
      if($key =~ /id_textid/)
      {
        $setup{$key} = get_traduction({id=>$setup{$key},id_language=>$lg});
      }
    }

    return \%setup;
  }
}

sub get_stripe_public_key
{
	my %stripe_setup = sql_line({select=>"stripe_public_key",table=>"stripe_setup"});	
	return $stripe_setup{stripe_public_key};
}

sub get_stripe_secret_key
{
	my %stripe_setup = sql_line({select=>"stripe_secret_key",table=>"stripe_setup"});	
	return $stripe_setup{stripe_secret_key};
}

sub get_stripe_url_redirect_after_success 
{
	my %d = %{$_[0]};

	my $order_token = $d{order_token};
	my $lg = $d{lg} || 1;

	my %stripe_setup = sql_line({select=>"stripe_url_redirect_after_success",table=>"stripe_setup"});
	$stripe_setup{stripe_url_redirect_after_success} = get_traduction({id=>$stripe_setup{stripe_url_redirect_after_success},id_language=>$lg});

	my $link = $stripe_setup{stripe_url_redirect_after_success} . "&token=$order_token";

	return $link;
}

sub get_stripe_url_redirect_after_error 
{
	my %d = %{$_[0]};

	my $order_token = $d{order_token};
	my $lg = $d{lg} || 1;

	my %stripe_setup = sql_line({select=>"stripe_url_redirect_after_error",table=>"stripe_setup"});
	$stripe_setup{stripe_url_redirect_after_error} = get_traduction({id=>$stripe_setup{stripe_url_redirect_after_error},id_language=>$lg});

	my $link = $stripe_setup{stripe_url_redirect_after_error} . "&token=$order_token";

	return $link;
}

sub stripe_form_elements
{
	my %d = %{$_[0]};

	my $self = $d{self};

	my $member_email = $d{member_email};
	my $order_token = $d{order_token};

	my $url_after_success = $d{url_after_success};
	my $url_after_error   = $d{url_after_error};
	
	log_debug("Initialisation du formulaire de paiement des cartes de crédit avec l\'adresse email [$member_email]","","stripe_".$order_token);

	my $form = <<"HTML";

	<script src="//js.stripe.com/v3/"></script>

	<script> 
		jQuery(function() {
			var stripe = Stripe('$stripe_pulic_key');
			var elements = stripe.elements();


			// Custom styling can be passed to options when creating an Element.
			var style = {
			  base: {
			    // Add your base input styles here. For example:
			    fontSize: '16px',
			    lineHeight: '24px'
			  }
			};

			// Create an instance of the card Element
			var card = elements.create('card', {
				style: style,
				hidePostalCode : true,				

			});

			// Add an instance of the card Element into the `card-element` <div>
			card.mount('#card-element');

			card.addEventListener('change', function(event) {
		  	var displayError = document.getElementById('card-errors');
			  if (event.error) {
			    displayError.textContent = event.error.message;
			  } else {
			    displayError.textContent = '';
			  }
			});

			
			// Create a token or display an error when the form is submitted.
			var form = document.getElementById('payment-form');
			form.addEventListener('submit', function(event) {
			  event.preventDefault();

			  stripe.createToken(card).then(function(result) {
			    if (result.error) {
			      // Inform the user if there was an error
			      var errorElement = document.getElementById('card-errors');
			      errorElement.textContent = result.error.message;
			    } else {
			      // Send the token to your server
			      stripeTokenHandler(result.token);
			    }
			  });
			});

			function stripeTokenHandler(token) 
			{
			  // Insert the token ID into the form so it gets submitted to the server
			  var form = document.getElementById('payment-form');
			  var hiddenInput = document.createElement('input');
			  hiddenInput.setAttribute('type', 'hidden');
			  hiddenInput.setAttribute('name', 'stripeToken');
			  hiddenInput.setAttribute('value', token.id);
			  form.appendChild(hiddenInput);

			  // Submit the form
			  form.submit();
			}


		});
	</script>

	<form action="$self" method="post" id="payment-form">		
		<input type="hidden" name="sw" value="stripe_form_elements_db">
		<input type="hidden" name="member" value="$member_email">
		<input type="hidden" name="order" value="$order_token">
		<input type="hidden" name="url_after_success" value="$url_after_success">
		<input type="hidden" name="url_after_error" value="$url_after_error">


	  <div class="form-row">
	    <label for="card-element">
	      Credit or debit card
	    </label>
	    <div id="card-element">
	      <!-- a Stripe Element will be inserted here. -->
	    </div>

	    <!-- Used to display Element errors -->
	    <div id="card-errors" role="alert"></div>
	  </div>

	  <button class="btn btn-primary">Payer</button>
	</form>


HTML
}


sub stripe_form_elements_db
{
	
	my $stripeToken       = get_quoted("stripeToken");	
	my $email             = get_quoted("member");
	my $order_token       = get_quoted("order");
	my $url_after_success = get_quoted("url_after_success");
	my $url_after_error   = get_quoted("url_after_error");

	my $order_table = "eshop_orders";
	if($config{custom_order_table} ne "") #E+
	{
		$order_table = $config{custom_order_table};
	}

	my %order = sql_line({table=>$order_table, where=>"token != '' AND token = '$order_token'"});

	my $col_total_order = "total_discounted_tvac";
	if($config{custom_order_col_total} ne "") #E+
	{
		$col_total_order = $config{custom_order_col_total};
	}

	my $stripe_amount = $order{$col_total_order};
	my $stripe_amount = $stripe_amount*100;

	log_debug("On charge la carte du client [$email] pour la somme de [$stripe_amount]","","stripe_".$order_token);

	if(!($stripe_amount > 0) || !($order{id} > 0))
	{
		log_debug("Autre type d'erreur","","stripe_".$order_token);
		log_debug("Redirection vers la page d'erreur","","stripe_".$order_token);
		send_mail('dev@bugiweb.com','dev@bugiweb.com',"Erreur AVANT un paiement Stripe","Site : $setup{site_name} Log :stripe_".$order_token.".log","html");
		see();
		http_redirect($url_after_error."&error_code=other");
		exit;
	}

	# Chargement de la source et traitement après chargement
	stripe_charge_source({
		amount      => $stripe_amount,
		currency    => "eur",
		source_id   => $stripeToken,
		description => "Paiement de $email",
		order_id    => $order{id},
		order_token => $order_token,
	});

}

sub stripe_error_message
{
	my %d = %{$_[0]};

	my $error_code = $d{error_code};
	my $error_msg = "";

	# GESTION DES MESSAGES D'ERREUR
  use Switch;
  switch ($error_code) 
  {
    case "invalid_number" 
    {
    	$error_msg = "Numéro de carte invalide";
    }
    case "invalid_expiry_month"
    {
    	$error_msg = "Le mois d'expiration est invalide";
    }
    case "invalid_expiry_year"
    {
    	$error_msg = "L'année d'expiration est invalide";
    }
    case "card_declined"
    {
    	$error_msg = "Votre carte a été refusée";
    }
    case "expired_card"
    {
    	$error_msg = "Votre carte a expiré";
    }
    else
    {
    	$error_msg = "Une erreur est survenue durant la transaction";
    }
  }

  return $error_msg;
}

############################################################
#################### stripe_source_form ####################
############################################################
# Génération du formulaire caché soumis lorsqu'une methode 
# de paiement avec carte de débit est cochée
sub stripe_source_form
{
	my %d = %{$_[0]};

	my $self              = $d{self};
	my $type              = $d{type};
	my $order_token       = $d{order_token};
	my $member_email      = $d{member_email};
	my $member_lastname   = $d{member_lastname};
	my $member_firstname  = $d{member_firstname};
	my $url_after_success = $d{url_after_success};
	my $url_after_error   = $d{url_after_error};

	my $content = <<"EOH";
		<form action="$self" id="stripe_bancontact_form">
			<input type="hidden" name="sw" value="stripe_source_db">
			<input type="hidden" name="type" value="$type">
			<input type="hidden" name="member_email" value="$member_email">
			<input type="hidden" name="member_firstname" value="$member_firstname">
			<input type="hidden" name="member_lastname" value="$member_lastname">
			<input type="hidden" name="order" value="$order_token">
			<input type="hidden" name="url_after_success" value="$url_after_success">
			<input type="hidden" name="url_after_error" value="$url_after_error">
		</form>
EOH

	return $content;
}

##########################################################
#################### stripe_source_db ####################
##########################################################
# Création de la source et redirection du client vers la
# page de paiement
sub stripe_source_db
{
	my $type              = get_quoted("type");
	my $order_token       = get_quoted("order");
	my $member_email      = get_quoted("member_email");
	my $member_lastname   = get_quoted("member_lastname");
	my $member_firstname  = get_quoted("member_firstname");
	my $url_after_success = get_quoted("url_after_success");
	my $url_after_error   = get_quoted("url_after_error");

	log_debug("Création d'un source de type [$type]","","stripe_".$order_token);

	my $order_table = "eshop_orders";
	if($config{custom_order_table} ne "") #E+
	{
		$order_table = $config{custom_order_table};
	}

	my %order = sql_line({table=>$order_table, where=>"token != '' AND token = '$order_token'"});

	my $col_total_order = "total_discounted_tvac";
	if($config{custom_order_col_total} ne "") #E+
	{
		$col_total_order = $config{custom_order_col_total};
	}

	my $stripe_amount = $order{$col_total_order};
	my $stripe_amount = $stripe_amount*100;

	if(!($stripe_amount > 0) || !($order{id} > 0))
	{
		log_debug("Autre type d'erreur","","stripe_".$order_token);
		log_debug("Redirection vers la page d'erreur","","stripe_".$order_token);
		send_mail('dev@bugiweb.com','dev@bugiweb.com',"Erreur AVANT un paiement Stripe","Site : $setup{site_name} Log :stripe_".$order_token.".log","html");

		cgi_redirect($url_after_error."&error_code=other");
		exit;
	}

	# Création du nom du propriétaire de la carte
	my $owner_name = "$member_firstname $member_lastname";
	if(trim($owner_name) eq "")
	{
		$owner_name = $member_email;
	}

	# Url de redirection après que le client ait effectué (ou pas) le paiement
	my $url_after_paiement = $config{fullurl}.'/cgi-bin/eplus.pl?sw=stripe_source_post_paiement';

	my $cmd = <<"EOH";
  curl https://api.stripe.com/v1/sources -u $stripe_secret_key -d type=$type -d currency=eur -d amount=$stripe_amount -d metadata[order_id]=$order{id} -d owner[email]=$member_email -d owner[name]=$owner_name -d statement_descriptor="$order{id}" -d redirect[return_url]=$url_after_paiement
EOH

	# Execution de la commande CURL
	my $response = `$cmd`;
	log_debug("Réponse [$response]","","stripe_".$order_token);

	my %response_json = %{decode_json($response)};

	if($response_json{status} eq "pending")
	{
		log_debug("Source crée avec succès [Status : $response_json{status}]","","stripe_".$order_token);
		log_debug("Redirection du client vers la page de paiement pour qu'il autorise celui-ci","","stripe_".$order_token);

		cgi_redirect($response_json{redirect}{url});
		exit;
	}
	else
  {
  	# ERREUR LORS DE LA CREATION DE LA SOURCE
  	log_debug("Erreur durant la création de la source [$response_json{error}{message}]","","stripe_".$order_token);

		log_debug("Redirection vers la page d'erreur","","stripe_".$order_token);
		send_mail('dev@bugiweb.com','dev@bugiweb.com',"Erreur durant un paiement Stripe","Site : $setup{site_name} Log :stripe_".$order_token.".log","html");

		cgi_redirect($url_after_error."&error_code=other");
		exit;
	}


}

#####################################################################
#################### stripe_source_post_paiement ####################
#####################################################################
# Fonction vers lequel est redirigé un client après avoir autorisé 
# ou non un paiement sur une page externe
# 
# Récupération de la source
# + Passe la main à la fonction de création de source si celle ci est chargeable
# 	Sinon redirection vers écran d'erreur
sub stripe_source_post_paiement
{

	my $id_source = get_quoted("source");

	my $cmd = <<"EOH";
  curl https://api.stripe.com/v1/sources/$id_source -u $stripe_secret_key
EOH

	# Execution de la commande CURL
	my $response = `$cmd`;

	my %response_json = %{decode_json($response)};

	# stripe_source_post_paiement_db({source_id=>$response_json{id},source_status=>$response_json{status}, order_id=>$response_json{metadata}{order_id}});

	if($config{custom_stripe_source_post_paiement_db} ne "")
	{
		# FONCTION SUR-MESURE
		my $custom_stripe_source_post_paiement_db = 'def_handmade::'.$config{custom_stripe_source_post_paiement_db};
		&$custom_stripe_source_post_paiement_db({
			amount        => $response_json{amount},
			source_id     => $response_json{id},
			source_status => $response_json{status}, 
			order_id      => $response_json{metadata}{order_id}
		});		
	}
	else
	{
		my $order = sql_line({table=>"eshop_orders", where=>"id = '$response_json{metadata}{order_id}'"});

		if($order{id} > 0)
		{			
			if($source_status eq "chargeable")
			{
				# Si la source est chargeable, on peut "charger" la source
				stripe_charge_source({
					amount      => $amount,
					currency    => "eur",
					source_id   => $source_id,
					description => "",
					order_id    => $order{id},
					order_token => $order{token},
				});
			}
			else
			{
				# Si c'est annulé ou qu'il y a une erreur
				# Redirection vers écran d'erreur
			}
		}
	}
}

sub stripe_source_post_paiement_link
{
	my %d = %{$_[0]};

	my $source_status = $d{source_status};
	my $order_token = $d{order_token};

	my $link;

	# GESTION DES MESSAGE À AFFICHER EN FOCNTION DES STATUS DE LA SOURCE
  use Switch;
  switch ($source_status) 
  {
  	case "chargeable"
  	{
    	$link = get_stripe_url_redirect_after_success({order_token=>$order_token});
    }
    case "canceled"
  	{
    	$link = get_stripe_url_redirect_after_error({order_token=>$order_token});
    }
    case "failed"
  	{
    	$link = get_stripe_url_redirect_after_error({order_token=>$order_token});
    }
  }

  return $link;
}

sub stripe_source_post_paiement_message
{
	my %d = %{$_[0]};

	my $source_status = $d{source_status};
	my $msg = "";

	# GESTION DES MESSAGE À AFFICHER EN FOCNTION DES STATUS DE LA SOURCE
  use Switch;
  switch ($source_status) 
  {
  	case "chargeable"
  	{
    	$msg = "Votre commande a bien été reçue et est en attente de confirmation de paiement";
    }
    case "canceled"
  	{
    	$msg = "Votre paiement a échoué et votre commande n'a pas pu se terminer";
    }
    case "failed"
  	{
    	$msg = "Votre paiement a échoué et votre commande n'a pas pu se terminer";
    }    
  }

  return $msg;
}

sub stripe_charge_source
{
	my %d = %{$_[0]};

	my $amount      = $d{amount};
	my $currency    = $d{currency} || "eur";
	my $description = $d{description};
	my $source_id   = $d{source_id};
	my $order_id    = $d{order_id};
	my $order_token = $d{order_token};

	log_debug("On charge la source du client","","stripe_".$order_token);

	my $cmd = <<"EOH";
  curl https://api.stripe.com/v1/charges -u $stripe_secret_key -d amount=$amount -d currency=$currency -d description="$description" -d metadata[order_id]=$order_id -d source=$source_id
EOH

	# Execution de la commande CURL
	my $response = `$cmd`;
	log_debug("Réponse [$response]","","stripe_".$order_token);

	my %response_json = %{decode_json($response)};	

	stripe_charge_source_db({order_token=>$order_token, response_json=>\%response_json});
  
}

sub stripe_charge_source_db
{
	my %d = %{$_[0]};

	my %response_json = %{$d{response_json}};
	my $order_token = $d{order_token};

	log_debug("Début des actions après chargement de la source","","stripe_".$order_token);

	if($response_json{status} eq "succeeded")
  {
  	# TRANSACTION REUSSIE  	
  	log_debug("Transaction réussie","","stripe_".$order_token);

  	# Fonction sur-mesure
  	if($config{custom_postsale_billing_stripe_after_success} ne "")
  	{
  		log_debug("Fonction de postsale sur-mesure","","stripe_".$order_token);
  		my $custom_postsale_billing_stripe = 'def_handmade::'.$config{custom_postsale_billing_stripe_after_success};
			&$custom_postsale_billing_stripe({response_json=>\%response_json, order_token=>$order_token});
			exit;
  	}
  	else
  	{
  		# Comportement classique de la boutique
  	}
  }
  else
  {
  	# ERREUR LORS DE LA TRANSACTION
  	log_debug("Erreur durant la transaction","","stripe_".$order_token);
  	
		my $url_after_error = get_stripe_url_redirect_after_error({order_token=>$order_token});
  	# Erreur concernant la carte
  	if($response_json{error}{type} eq "card_error")
  	{
  		log_debug("Erreur concernant la carte","","stripe_".$order_token);
  		log_debug("Redirection vers la page d'erreur","","stripe_".$order_token);
  		see();
  		http_redirect($url_after_error."&error_code=".$response_json{error}{code});
  		exit;
  	}
  	# Autre erreur (https://stripe.com/docs/api/curl#errors)
  	else
  	{
  		log_debug("Autre type d'erreur","","stripe_".$order_token);
  		log_debug("Redirection vers la page d'erreur","","stripe_".$order_token);
  		send_mail('dev@bugiweb.com','dev@bugiweb.com',"Erreur durant un paiement Stripe","Site : $setup{site_name} Log :stripe_".$order_token.".log","html");
  		see();
  		http_redirect($url_after_error."&error_code=other");
  		exit;
  	}  	
  }
}


1;