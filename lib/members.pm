#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
package members;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@ISA = qw(Exporter);	
@EXPORT = qw(
  
		members_get
		ajax_is_member_connected
		get_id_member
		autoconnexionbis 
		after_save_create_token
		member_error_page
		member_login_form
		member_login_db
		member_logout_db
		member_signup_db
		member_mailing_subscribe_db
		member_mailing_unsubscribe_db
		member_html_login_form
		member_html_lost_password_form
		member_html_signup_form
		member_html_signup_form_revendeur
		member_html_login_lost_signup_form

		member_mail_activation
		member_mail_activation_db
		member_mail_activation_ok

		member_add_event

		member_build_form

		member_get_setup

		lost_password_db
		lost_password_ok
		lost_password_ko

		edit_password
		edit_password_db
		edit_password_ok
		$captcha_public_key
		member_error_page_validation
		%member_setup

		get_members_txt

		members_migcms_history

		get_id_status_valide
		get_id_status_non_valide

		get_menu

		get_dm_dfl
		get_frontend_form_from_dm_dfl

		member_signup_fields
		create_member_from_order

		get_member_error_message

		get_member_backend_identities_form
);
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use def;
use tools;
use eshop;
use sitetxt;
use sws;
use JSON;
use JSON::XS; 
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use setup;
my $cookie_member_name = 'migcms_member_'.$config{projectname};
my $captcha_public_key = $config{captcha_public_key} || "6LebNAATAAAAAPCtNCI_GeyRA8n7W1LnL6LqiSL3";
my $lg = get_quoted('lg');
if ($lg eq "") {$lg = $config{current_language};}

my $extlink = get_quoted('extlink');
my $extlink_member = get_quoted("extlink_member");

$lg =~ s/undefined//g;
$config{current_language} = $config{default_colg} = $lg;

my $self = $config{baseurl}.'/'.'cgi-bin/members.pl?lg='.$lg.'&extlink='.$extlink . 'extlink_member='.$extlink_member;
my $self_env_full = 'http://';
if($ENV{HTTP} eq 'on' || $config{force_https} eq 'y')
{
	$self_env_full = 'https://';
}
$self_env_full .= $ENV{HTTP_HOST}.$config{baseurl}.'/'.'cgi-bin/members.pl?lg='.$lg.'&extlink='.$extlink . 'extlink_member='.$extlink_member;

%member_setup = %{member_get_setup({lg=>$lg})};

%email_optin = 
(
	'y'        =>"Oui",
	'n' =>"Non"
);


sub member_html_signup_form_revendeur
{
	my %d = %{$_[0]};
	my %members_setup = select_table($dbh,"members_setup");

	# Récupération du tableau des champs du formulaire
  my @champs = @{members::member_signup_fields_revendeur()};  

  # Construction du formulaire
  my $form = build_form({fields=>\@champs, lg=>$d{lg}});

  my $intro_revendeur;
  if($d{disabled_intro_revendeur} ne "y")
  {
  	$intro_revendeur = $sitetxt{member_intro_revendeur}
  }

	my $form = <<"EOH";
	<div class="customer-form">
		<h1 class="maintitle"><span>$sitetxt{'member_signup_revendeur_title'}</span></h1>
		$intro_revendeur

		<form id="member-signup-revendeur" method="post" class="form-horizontal" action="$self"  enctype="multipart/form-data">
  		<input type="hidden" name="sw" value = "member_signup_db" />     
      <input type="hidden" name="lg" value = "$d{lg}" />  	
      <input type="hidden" name="type" value = "revendeur">	
      <input type="hidden" name="url_after_error" value="$d{url_after_error}">

      $form

		  <div class="form-group">
			  <div class="col-sm-4"></div>
			  <div class="col-sm-8">
				  <button type="submit" class="btn btn-info">$sitetxt{'eshop_metatitle_signup'}</button>
			  </div>
		  </div>
		</form>
	</div>
EOH

	return $form;
}

################################################################################
# member_signup_fields_revendeur
################################################################################
sub member_signup_fields_revendeur
{
  my @champs;


  if($config{custom_signup_fields_revendeur} eq "y")
  {
    @champs = @{def_handmade::get_custom_signup_fields_revendeur()}; 
  }
  else
  {
  	my %eshop_setup = %{eshop::get_setup()};

  	# Si la boutique est activée, on ajoute le bouton de TVA intracom
  	my $do_not_add_intracom = "n";
  	if($eshop_setup{shop_disabled} eq "y")
  	{
  		$do_not_add_intracom = "y";
  	}

  	my $conditions_txt = $member_setup{id_textid_conditions};

    @champs = 
    (
      {
        name => 'delivery_firstname',
        label => $sitetxt{members_firstname},
        required => 'required',
      }
      ,
      {
        name => 'delivery_lastname',
        label => $sitetxt{members_lastname},
        required => 'required',
      }
      ,
      {
        name => 'delivery_company',
        label => $sitetxt{members_company},
        required => 'required',
      }
      ,
      {
        name => 'delivery_vat',
        label => $sitetxt{members_vat},
        hint => "($sitetxt{members_exemple}: BE123456789)",
        required => 'required',
      }
      ,
      {
        name => 'delivery_street',
        label => $sitetxt{members_street},
        required => 'required',
        class =>  'google_map_route',
      }
      ,
      {
        name => 'delivery_number',
        label => $sitetxt{members_number},
        class =>  'google_map_street_number',
        required => 'required',
      }
      ,
      {
        name => 'delivery_box',
        label => $sitetxt{members_box},
        class => '',
      }
      ,
      {
        name => 'delivery_zip',
        label => $sitetxt{members_zip},
        required => 'required',
        class =>  'google_map_postal_code',
      }
      ,
      {
        name => 'delivery_city',
        label => $sitetxt{members_city},
        required => 'required',
        class =>  'google_map_locality',
      }
      ,
      {
        name => 'delivery_country',
        type => 'countries_list',
        label => $sitetxt{members_country},
        required => 'required',
        class =>  'google_map_country',
      }
      ,
      {
        name => 'delivery_phone',
        label => $sitetxt{members_tel},
        required => 'required',
      }
      ,
      {
        name => 'email',
        type => 'email',
        label => $sitetxt{members_email},
        required => 'required',
      },
      {
        name => 'email2',
        type => 'email',
        label => $sitetxt{members_confirme_email},
        required => 'required',
      },
      {
        name => 'password',
        type => 'password',
        label => $sitetxt{members_password},
        required => 'required',
      },
      {
        name => 'password2',
        type => 'password',
        label => $sitetxt{members_confirme_password},
        required => 'required',
      },
      {
				name       => 'do_intracom',
				type       => 'checkbox',
				label      => "$sitetxt{'members_do_intracom_label'} ( <i class='eshop_tooltip' data-toggle='tooltip' data-placement='right' data-placement='bottom' title='$sitetxt{members_do_intracom_txt}'>?</i> )",
				required   => '',
				value      => "y",
				do_not_add => $do_not_add_intracom,
				class      =>  'group_intracom',
      },
      {
        name => 'email_optin',
        type => 'checkbox',
        label => "$sitetxt{email_optin_label}",
        required => '',
        value => "y",
      },
      {
        name => 'conditions_ok',
        type => 'checkbox',
        label => "$conditions_txt",
        required => 'required',
        value => "y",
      },
    );
  }

  return \@champs;
}

#MEMBER_GET*****************************************************************************************
sub member_add_event
{
	my %d = %{$_[0]};
	$d{name} =~ s/\'/\\\'/g;
	$d{detail} =~ s/\'/\\\'/g;
	$d{erreur} =~ s/\'/\\\'/g;
	$d{group} =~ s/\'/\\\'/g;
	
	
	$d{name} =~ s/\\\\\'/\\\'/g;
	$d{detail} =~ s/\\\\\'/\\\'/g;
	$d{erreur} =~ s/\\\\\'/\\\'/g;
	$d{group} =~ s/\\\\\\'/\\\'/g;
	
	
	my $group_type_event = '';
	if($d{group} eq '')
	{
		if($d{type} =~ m/signup/ || $d{type} =~ m/password/)
		{
			$group_type_event = 'signup';
		}
		elsif($d{type} =~ m/view_page/)
		{
			$group_type_event = 'page';
		}
		elsif($d{type} =~ m/login/ || $d{type} =~ m/logout/)
		{
			$group_type_event = 'login';
		}
		elsif($d{type} =~ m/reponse/)
		{
			$group_type_event = 'actions';
		}
	}
	else
	{
		$group_type_event = $d{group};
		$group_type_event =~ s/\'/\\\'/g;
	}
	
	my %migcms_members_event = 
	(
		id_member => $d{member}{id},
		moment => 'NOW()',
		nom_evt => $d{name},
		detail_evt => $d{detail},
		type_evt => $d{type},
		erreur_evt => $d{erreur},
		group_type_event => $group_type_event,
		date_event => 'DATE(NOW())',
		time_event => 'TIME(NOW())',
	);
	
	my $id_event = inserth_db($dbh,"migcms_members_events",\%migcms_members_event);
	# $stmt = "UPDATE migcms_members_events SET date_event=DATE(moment), time_event = TIME(moment) where id=$id_event";
    # execstmt($dbh,$stmt);	
}

################################################################################
# member_get_setup
################################################################################
sub member_get_setup
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

################################################################################
# ajax_is_member_connected
################################################################################
sub ajax_is_member_connected
{
  

  my $response = "ko";
     
  #read cookie MEMBER
  my $cookie_front = $cgi->cookie($config{front_cookie_name});
  if($cookie_front ne "")
  {
       $cookie_member_ref=decode_json $cookie_front;
       %hash_front_cookie=%{$cookie_member_ref};
       
       my %member = sql_line({debug=>$d{debug},debug_results=>$d{debug},table=>"migcms_members",select=>"id",where=>"token='$hash_front_cookie{member_token}' and token !=''"});
       if($member{id} > 0)
       {
          $response = "ok";
       }
  }
  
  see();
  print $response;
  exit;
}

################################################################################
# get_id_member
################################################################################
sub get_id_member
{
     my %d = %{$_[0]};
     
     #read cookie MEMBER
     my $cookie_front = $cgi->cookie($config{front_cookie_name});
     if($cookie_front ne "")
     {
           $cookie_member_ref=decode_json $cookie_front;
           %hash_front_cookie=%{$cookie_member_ref};
           
           my %member = sql_line({debug=>$d{debug},debug_results=>$d{debug},table=>"migcms_members",select=>"id",where=>"token='$hash_front_cookie{member_token}' and token !=''"});
           return $member{id};
     }
     else
     {
          return 0;
     }
}

#MEMBER_GET*****************************************************************************************
sub members_get
{
	 my %cookie_member = ();
     my $cookie_member = $cgi->cookie($config{front_cookie_name});
     if($cookie_member ne "")
     {
		  $cookie_member_ref = decode_json $cookie_member;
		  %cookie_member = %{$cookie_member_ref};
     }

	 
	 my %member = sql_line({debug=>0,debug_results=>0,table=>"migcms_members",where=>"token='$cookie_member{member_token}' AND token !='' AND token2 != ''"});
	 delete $member{password};
	 
	 return \%member; 
}

#MEMBER ERROR PAGE*********************************************************
sub member_error_page
{
	my %d = %{$_[0]};
	
	my $error_content = <<"EOH";
	
	<div class="alert alert-danger">
		<h1><span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span> $sitetxt{'members_title_acces_denied'}</h1>
		$sitetxt{'members_message_acces_denied'}
	</div>
EOH
	
	my $page_html = migcrender::render_page({force_content=>$error_content,debug=>0,id=>$d{id_page},lg=>$lg,preview=>'y',edit=>$edit});
	print $page_html;
	exit;
}

#MEMBER ERROR PAGE*********************************************************
sub member_error_page_validation
{
	my %d = %{$_[0]};
	
	my $txt =  $sitetxt{'members_signup_confirmation_txt_group_'.$d{member}{id_member_group}};
	
	my $page =<<"EOH";			
<div class="alert alert-info">
		 $txt 
</div>
EOH
	
    if($d{id_page} > 0)
	{
		my $page_html = migcrender::render_page({force_content=>$page,debug=>0,id=>$d{id_page},lg=>$d{lg},preview=>'y',edit=>$edit});
		print $page_html;
		exit;
	}
	print '';
	exit;

	
}

#MEMBER LOGIN FORM*********************************************************
sub member_login_form
{
	my %d = %{$_[0]};
	my $html_login_form = member_html_login_lost_signup_form({id_page=>$d{id_page}, url_after_login=>$d{url_after_login}, url_after_error=>$d{url_after_error}});
	
	my %member_setup = %{member_get_setup({lg=>$lg})};
	if($member_setup{force_login_register_page} eq 'y') {
	
		my $id_page = $member_setup{id_page};

		my $page_html = migcrender::render_page({force_content=>$html_login_form,debug=>0,id=>$id_page,lg=>$lg});
		print $page_html;
		exit; 
	
	}
	
	if($d{id_page} > 0)
	{
		#si une page est passée, on remplace le contenu de la page par le formulaire de login-form
		my $page_html = migcrender::render_page({force_content=>$html_login_form,debug=>0,id=>$d{id_page},lg=>$lg,preview=>'y',edit=>$edit});
		print $page_html;
		exit;
	}
	
	print $html_login_form;
	exit;
}

#MEMBER LOGIN DB*********************************************************

sub autoconnexionbis
{
	# see();
	my $url = get_quoted('url');
	
	
	if($url ne "")
	{
		cgi_redirect($url);	
		# print 'red:'.$url;
		# exit;
	}
	else
	{
		cgi_redirect('/');	
	}
	# exit;
}

sub member_login_db
{
	log_debug('member_login_db','','debugmember');
	my %d = %{$_[0]};

	my %eshop_setup = %{eshop::get_setup()};
	my %member_setup = %{member_get_setup({lg=>$lg})};

	my $clean_cookie = get_quoted("clean_cookie");

	# Connexion via un réseau social
	my $social_id = get_quoted("social_id");
  my $social_token = get_quoted("social_token");
  my $social_email = get_quoted("social_email");
  # Mise à jour du social token
  if($social_id ne "" && $social_token ne "") 
  {
    $stmt = "UPDATE migcms_members SET social_token='$social_token' where social_id = '$social_id' AND social_id != ''";
    execstmt($dbh,$stmt);
  }
	
	#SHA token
	my $stoken = get_quoted('stoken') || $d{stoken};	
	log_debug('stoken:'.$stoken,'','debugmember');

	#recaptcha google	
	if(get_quoted('stoken') eq '' && $member_setup{disabled_login_recaptcha} ne "y")
	{
		my $secret_key = $config{captcha_secret_key} || "6LebNAATAAAAABrhItqdIIU_Gt3DPMtUYVrPivSv";
		my $i_am_human = tools::is_human_recaptcha({g_recaptcha_response=>get_quoted("g-recaptcha-response"), secret_key=>$secret_key});
		if($i_am_human ne "y")
		{
		   my $alert = tools::get_alert({type=>"error",display=>'sweet',title=>"Attention", message=>"Veuillez cocher la case \"Je ne suis pas un robot\""});

		   see();
		   print $alert;
		   exit;
		}
	}
	
	#login
	my $id_page = trim(get_quoted('id_page')) || $d{id_page};
	my $token_page = trim(get_quoted('token_page'));
  my $lg = get_quoted('lg');
  my $url_after_login = get_quoted("url_after_login") || $d{url_after_login} || $member_setup{member_url_after_login};
  my $url_after_error = get_quoted("url_after_error") || $d{url_after_error};

	#email / password
	my $email = trim(get_quoted('email')) || $d{email};;
	my $password = sha1_hex(trim(get_quoted('password'))) || $d{password};
  
  if($config{custom_crypt_password} eq "y")
  {
    $password = def_handmade::get_custom_crypt_password({password=>trim(get_quoted('password'))});
  }

	# Fonction sur-mesure before_login
	if($member_setup{before_login_func} ne '')
	{
		my $before_login_func = 'def_handmade::'.$member_setup{before_login_func};
		&$before_login_func({email=>$email, password=>$password});		
	}

	# Where sur-mesure supplémentaire
	my $handmade_where_login = $config{handmade_where_login};

	
	#teste si le membre n'a pas de mot de passe
	# && $url_after_login !~ /member_mailing_unsubscribe_db/
	my %member = sql_line({debug=>1,debug_results=>1,table=>'migcms_members',where=>"email='$email' AND email != '' AND password = '' $handmade_where_login"});
	if($member{id} > 0 & $member{password} eq '')
	{
		
    # Génération d'un password si le membre n'en possède pas		
		my $generated_password = sha1_hex(create_token(20));

		$stmt = "UPDATE migcms_members SET password = '$generated_password' WHERE id = '$member{id}'";
		$cursor = $dbh->prepare($stmt);
		$cursor->execute || suicide($stmt);
	}
	
  # Récupération de l'id du statut valide pour construire le WHERE
	my $where_validation_member = " AND actif = 'y'";
	if($config{member_validation_not_mandatory_to_login} eq 'y')
	{
		$where_validation_member = " ";
	}

	my %member = sql_line({debug=>1,debug_results=>1,table=>'migcms_members',where=>"((social_token = '$social_token' AND social_token != '') OR (stoken!= '' AND stoken= '$stoken') OR (email='$email' AND email != '' AND password = '$password' AND password != '')) AND token != '' AND token2 != '' $where_validation_member $handmade_where_login" });
	if($member{id} > 0)
	{

		if($member{id_language} > 0)
		{
		  $lg = $member{id_language};
		}

		# Lecture du Front Cookie qui existerait déjà sauf s'il faut le vider
		my %hash_front_cookie = ();
		if($clean_cookie ne "y")
		{
			my $cookie_front = $cgi->cookie($config{front_cookie_name});
			if($cookie_front ne "")
			{
			      $cookie_front_ref=decode_json $cookie_front;
			      %hash_front_cookie=%{$cookie_front_ref};
			}			
		}

		#changement du token lors de la connexion (déconnecte les autres users du meme compte) + Sauvegarde de la date de connexion
		my $new_token = create_token(100); 
		$stmt = "UPDATE migcms_members SET token = '$new_token', migcms_moment_last_login = NOW() WHERE id = '$member{id}'";
		$cursor = $dbh->prepare($stmt);
		$cursor->execute || suicide($stmt);


		# Si la boutique est activée et qu'une commande est en cours
		if($eshop_setup{shop_disabled} ne "y" && $hash_front_cookie{eshop_token} ne '')
		{
			#lecture de la commande en cours
		  my %order = %{eshop::get_eshop_order()};

      if($order{id} > 0)
      {        
        # Association de la commande au membre
        eshop::lnk_order_to_member({order_token=>$order{token},member_email=>$member{email}});
      }

		}
		
		# On ajoute le token dans le cookie
		$hash_front_cookie{member_token} = $new_token;
		
		# Ecriture du cookie
		my $json_front_cookie_value = encode_json \%hash_front_cookie;
		my $cook = $cgi->cookie(-domain=>$config{cookie_dns},-name=>$config{front_cookie_name},-value=>$json_front_cookie_value,-path=>$config{rewrite_directory},-expires=>'');
		print $cgi->header(-cookie=>$cook,-charset => 'utf-8');
		
		member_add_event({member=>\%member,type=>'login',name=>"Le membre se connecte",detail=>'',erreur=>''});

		# Fonction sur-mesure after_login
		if($member_setup{after_login_func} ne '')
		{
			my $after_login_func = 'def_handmade::'.$member_setup{after_login_func};
			&$after_login_func({member=>\%member});		
		}
		
	log_debug('Redirections','','debugmember');
	log_debug('$id_page:'.$id_page,'','debugmember');
	log_debug('$url_after_login:'.$url_after_login,'','debugmember');
	log_debug('$token_page:'.$token_page,'','debugmember');

		######################
		#### Redirections ####
		######################
		my $redirect_url = "";
		# Redirection vers l'id_page passée en paramètre
		if($id_page > 0)
		{
			$redirect_url = $config{baseurl}.'/'.get_url({debug=> 0,nom_table=>'migcms_pages',id_table=>$id_page, id_language => $lg});
			
			log_debug('cas1: id_page:'.$id_page,'','get_url');
			log_debug('cas1: redirect_url:'.$redirect_url,'','get_url');
			
		}
		# Redirection vers l'url renseignée dans la configuration des membres
		elsif($url_after_login ne "")
		{

			$url_after_login =~ s/@SEP_EXT@/&/g;
			$redirect_url = $url_after_login;
		}
		# Redirection vers la page correspondant au token passé
		elsif($token_page ne '')
		{
			my %migcms_page = sql_line({debug=> 1,debug_results=> 1,table=>'migcms_pages',select=>'id',where=>"token='$token_page'"});
			$redirect_url = $config{baseurl}.'/'.get_url({debug=> 0,nom_table=>'migcms_pages',id_table=>$migcms_page{id}, id_language => $lg});
		}
		# Redirection vers la page d'accueil par défaut du site
		else
		{
			my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
			log_debug('$migcms_setup{id_default_page}:'.$migcms_setup{id_default_page},'','debugmember');

			$redirect_url = $config{baseurl}.'/'.get_url({migcms_setup=>\%migcms_setup,debug=>0,nom_table=>'migcms_pages',id_table=>$migcms_setup{id_default_page}, id_language => $lg});
		}

		my $ajax_call = get_quoted("ajax_call");
		if($ajax_call eq "y")
		{
			# La fonction a été appelée en Ajax
			my %response = (
				error => "",
				redirection => $redirect_url,
			);
			print JSON->new->utf8(0)->encode(\%response);
			exit;
		}
		else
		{
			# Redirection classique
			http_redirect($redirect_url);
		}
		######################
	}
	# AUCUNE MEMBRE TROUVÉ
	else
	{	
		# Connexion via un réseau social => tests supplémentaires
		if($social_email ne "")
		{
			my %response =();
			# On récupère la ligne d'un member en fonction de l'email social
      my %member = sql_line({debug=>0,debug_results=>0,dbh=>$dbh,table=>'migcms_members',where=>"email='$social_email' AND email != ''"});
      # Si on recoit un member c'est que l'adresse existe mais n'est pas associée à un réseau social
      if($member{email}) {
        # see();
        # print("adresse-existe");
        %response = (
					error => "30",
				);
      }
      else {
        # adresse inexistante
        %response = (
					error => "50",
				);
      }

      see();
      print JSON->new->utf8(0)->encode(\%response);
			exit;

		}
		else
		{
			# Redirection d'erreur classique 
			cgi_redirect($url_after_error."&error=50");			
		}
	}

	
}

sub member_signup_db
{
  my %d = %{$_[0]};
  
  my $lg = get_quoted("lg") || 1;
	my %eshop_setup = %{eshop::get_setup()};
	my %member_setup = %{member_get_setup({lg=>$lg})};



	my $type = get_quoted("type");
  my $url_after_error = get_quoted("url_after_error") || $d{url_after_error};
  my $url_after_success = get_quoted("url_after_success") || $d{url_after_success};
  my $no_redirect = $d{no_redirect} || "n";
  my $no_after_signup_func = $d{no_after_signup_func} || "n";
  my $no_member_autologin_after_signup = $d{no_member_autologin_after_signup} || "n";

  # Fonction sur-mesure before_signup
	if($member_setup{before_signup_func} ne '')
	{
		my $before_signup_func = 'def_handmade::'.$member_setup{before_signup_func};
		&$before_signup_func();		
	}

	if ($member_setup{use_handmade_member_signup_db_func} ne "") 
	{
		$fct = 'def_handmade::'.$member_setup{use_handmade_member_signup_db_func};
		&$fct();
		exit;
	}

	my $erreur = 0;
	my $page = "";

	my $id_page = get_quoted('id_page');
	my $token = $token2 = create_token(20);
	my $stoken = get_quoted("stoken") || sha1_hex($token);
	
  my %dm_dfl_members = %{members::get_dm_dfl()};

  my %new_member;
  my $string_quoted;
  foreach my $field_line (sort keys %dm_dfl_members)
  {
    if(!($dm_dfl_members{$field_line}{frontend_editable} eq "y"))
    {
      next;
    }

    my ($ordby,$field_name) = split(/\//,$field_line);

    $new_member{$field_name} = trim(get_quoted($field_name));

    # Constructions de la chaine des champs avec leur valeurs à passer en paramètre d'URL en cas d'erreur
    # Cette chaine sert à garder les informations du formulaire
    if($field_name ne "email2" && $field_name ne "password" && $field_name ne "password2")
    {
      $string_quoted .= "&".$field_name."=".$new_member{$field_name};      
    }

    # Si un champ requis est vide
    if($dm_dfl_members{$field_line}{frontend_required} eq 'y' && $new_member{$field_name} eq '')
    {
      $erreur = 1;
    }
  }

  # Récupération des id des réseaux sociaux
	$new_member{social_token} = get_quoted("social_token");
	$new_member{social_id} = get_quoted("social_id");

  #### Si les emails ne correspondent pas #### 
	if($new_member{email2} ne $new_member{email} || $new_member{email2} eq '')
	{
		$erreur = 2;
	}
	delete $new_member{email2};
	
	#### Si les mdps ne correspondent pas #### 
	if($new_member{password2} ne $new_member{password} || $new_member{password2} eq '')
	{
		$erreur = 3;
	}
	delete $new_member{password2};	

	### Test si le membre existe deja ###
	my %test_member = sql_line({table=>'migcms_members',where=>"email != '' AND email = '$new_member{email}'"});
	if($test_member{id} > 0 && $test_member{password} ne "")
	{
		# Si le membre a un mot de passe, on ne met pas à jour
		$erreur = 4;		
	}

	# S'il n'y a pas d'erreur
	if($erreur == 0)
	{		
		#####################################################
    ### CREATION DU TOKEN ET CRYPTAGE DU MOT DE PASSE ###
    ####################################################
		$new_member{token} = $new_member{token2} = $token;
		my $spassword = sha1_hex($new_member{password});
    # Custom crypt
    if($config{custom_crypt_password} eq "y")
    {
      $spassword = get_custom_crypt_password({password=>trim(get_quoted('password'))});
    }

		$new_member{password} = $spassword;
		$new_member{stoken} = $stoken;

		$new_member{delivery_email} = $new_member{email};

		$new_member{migcms_moment_create} = 'NOW()';

    ####################################
    ### AJOUT DES TAGS PAYS + LANGUE ###
    ####################################
    my %country = sql_line({dbh=>$dbh, table=>"countries", where=>"iso = '$new_member{delivery_country}'"});
    $new_member{tags} = $test_member{tags};
    $new_member{tags} = ",".$lg.",".$country{id}.",";

    ########################################
    ### ACTIVATION AUTOMATIQUE DU MEMBRE ###
    ########################################
    if($member_setup{disable_member_autoactivation_after_signup} ne "y")
    {
      # On lui donne le statut "valide"
      $new_member{actif} = "y";
    } 

    ##################################
    ### AJOUT AUTO A LA NEWSLETTER ###
    ##################################
	 	if($member_setup{auto_email_optin_after_signup} eq "y")
  	{
      # On l'ajoute au membres newsletter
      $new_member{email_optin} = "y";
    }    

		######################################
    ### AJOUT OU MISE A JOUR DU MEMBRE ###
    ######################################
		$new_member{id} = sql_set_data({dbh=>$dbh, table=>"migcms_members", where=>"email = '$new_member{email}'", data=>\%new_member});
		member_add_event({member=>\%new_member,type=>'signup_insert',name=>"Le membre s'est inscrit",detail=>'',erreur=>''});
    
    #############################################
    ### ENVOI DU MAIL DE VALIDATION DE COMPTE ###
    #############################################
    if($member_setup{member_signup_mail_activation} eq "y")
    {
      member_mail_activation({stoken=>$new_member{stoken}});      
    } 

    ###################################################
    ### ENVOI DU MAIL DE CONFIRMATION D'INSCRIPTION ###
    ###################################################
    if($member_setup{disabled_mailing_after_signup} ne "y")
    {
      member_mail_after_signup({stoken=>$new_member{stoken}});      
    } 
 		
 		###############################################
    ### ACTIONS SUPPLEMENTAIRES SI ESHOP ACTIVE ###
    ###############################################
    if($eshop_setup{shop_disabled} ne "y")
		{
			# Actions supplémentaires propres à la boutique lors de la création d'un membre
			eshop::eshop_signup_member({member=>\%new_member, type=>$type});
		}

		########################################
    ### FONCTION AFTER SIGNUP SUR-MESURE ###
    ########################################
		if($member_setup{after_signup_func} ne '' && $no_after_signup_func ne "y")
		{
			my $after_signup_func = 'def_handmade::'.$member_setup{after_signup_func};
			&$after_signup_func({member=>\%new_member});		
		}
		
		#################
		### AUTOLOGIN ###
		#################
		if($member_setup{member_autologin_after_signup} eq "y" && $type ne "revendeur" && $no_member_autologin_after_signup ne "y") 
		{ 
			# Connexion et Redirection vers une page de contenu
			if($id_page > 0)
			{
				member_login_db({debug=>1,stoken=>$new_member{stoken}, id_page=>$id_page});
			}
			# connexion et redirection vers une url
			else
			{
				my $url_after_login = "$config{baseurl}/cgi-bin/members.pl";
				if($member_setup{member_autologin_after_signup_url} ne '' && $type ne "revendeur") 
				{
					$url_after_login = $member_setup{member_autologin_after_signup_url}.'&lg='.$lg;
				}
				if($url_after_success ne '')
				{
					$url_after_login = $url_after_success;
				}
				
				member_login_db({debug=>1,stoken=>$new_member{stoken}, url_after_login=>$url_after_login});        
			}
			exit;
		}



    ####################
    ### REDIRECTIONS ###
    ####################
    # Si le paramètre "no_redirect=>'y'" a été passé
    if($no_redirect eq "y")
    {
      return $new_member{id};
    }
    # Sinon, si une URL de redirection a été passée 
		elsif($url_after_success ne "")
		{
			cgi_redirect("$url_after_success");
			exit;
		}
    # Sinon affichage d'une confirmation
    else
    {


  		### Message de confirmation ###		
  		$page =<<"EOH";			
  			<div class="alert alert-success">
  				<h1><span class="glyphicon glyphicon-ok" aria-hidden="true"></span> 
  				$sitetxt{'members_signup_confirmation_display_title'}</h1>
  				$sitetxt{'members_signup_confirmation_display_txt'}
  			</div>
EOH
  	 
    	# Affichage de la confirmation
    	if(!($id_page >0))
    	{
    		$id_page = $member_setup{id_page};
    	}
		
		if($member_setup{force_login_register_page} eq 'y') {
			$id_page = $member_setup{id_page};		
		}


    	my $page_html = migcrender::render_page({force_content=>$page,debug=>0,id=>$id_page,lg=>$lg});
    	see();
    	print $page_html;
    	exit;		 

    } 
  }
  else
  {
    # Si le paramètre "no_redirect=>'y'" a été passé
    if($no_redirect eq "y")
    {
      return -1;
    }
    else
    {
    	my $stoken = get_quoted("stoken");    	
      cgi_redirect("$url_after_error&type=$type&error=$erreur&stoken=$stoken&".$string_quoted);
      exit;      
    }
  }



}

sub member_mail_after_signup
{

  my %d = %{$_[0]};

  my $stoken = $d{stoken} || get_quoted("stoken");

  my %member_setup = %{member_get_setup({lg=>$lg})};
  my %member = sql_line({dbh=>$dbh, table=>"migcms_members", where=>"stoken = '$stoken' AND stoken != ''"});


  if(!($member{mailing_after_signup_send} > 0))
  {
    # Récupération du contenu du mail
    my $mail_content = $member_setup{id_textid_mailing_after_signup};

    $member{delivery_firstname} = $member{firstname} || $member{delivery_firstname};
    $member{delivery_lastname}  = $member{lastname} || $member{delivery_lastname};
    $member{delivery_email}     = $member{email} || $member{delivery_email};

    $mail_content =~ s/{prenom}/$member{delivery_firstname}/g;
    $mail_content =~ s/{nom}/$member{delivery_lastname}/g;
    $mail_content =~ s/{email}/$member{delivery_email}/g;
    

    if($config{custom_mailing_signup_content} eq "y")
    {
      $mail_content = def_handmade::custom_mailing_signup_content({content=>$mail_content, member=>\%member, lg=>$lg}); 
    }

    my %members_sitetxt = %{get_members_txt($lg)};

    my $sender_mail = $member_setup{email_from}.' <'.$member_setup{email_from}.'>';

    # Ajout du Header et Footer global au mail
		my %site_setup = %{setup::get_site_setup()};
    if($site_setup{use_site_email_template} eq "y")
    {
			my $header    = setup::get_migcms_site_emails_header({title=>$members_sitetxt{email_signup_object}, lg=>$lg});
			my $footer    = setup::get_migcms_site_emails_footer({lg=>$lg});
			$mail_content = setup::get_migcms_site_email_content({content=>$mail_content});
    	$mail_content = $header . $mail_content . $footer;
    }

    send_mail($sender_mail,$member{email},$members_sitetxt{email_signup_object}, $mail_content);
    send_mail($sender_mail,'dev@bugiweb.com','COPIE BUGIWEB '.$members_sitetxt{email_signup_object}, $mail_content);

    my $stmt = <<"SQL";
    UPDATE migcms_members
      SET email_after_signup_sent = 'y'
      WHERE id = '$member{id}'
SQL

    execstmt($dbh, $stmt);

    member_add_event({member=>\%member,type=>'Inscription_email',name=>"Envoie du mail de confirmation d'inscription",detail=>'',erreur=>''});

  }
}


sub member_mail_activation
{

  my %d = %{$_[0]};
  my %site_setup = %{get_site_setup()};

  my $stoken = $d{stoken} || get_quoted("stoken");

  my %member = sql_line({dbh=>$dbh, table=>"migcms_members", where=>"stoken = '$stoken' AND stoken != ''"});

  if($member{id} > 0 && ($member{email_actif} eq "n" || $member{password} eq ""))
  {
    my $link_activation = $config{fullurl}.'/cgi-bin/members.pl?sw=member_mail_activation_db&stoken='.$member{stoken};

    my $link = <<"HTML";
      <!-- <tr>
        <td colspcan="2" valign="middle" class="fullmaxbutton" align="center">
          <br /><br /><br />
          <table style="height:50px;background-color: $site_setup{color_bandeau};" border="0" cellspacing="0" cellpadding="0" align="center">
            <tr>
              <td width="45" style="border-left:2px solid #07cfd1;border-top:2px solid #07cfd1;border-bottom:2px solid #07cfd1;">&nbsp;</td>
              <td style="border-top:2px solid #07cfd1;border-bottom:2px solid #07cfd1;" align="center"><a style="color:#07cfd1;text-decoration:none;font-size:18px;" href="$link_activation"><font face="'Roboto',arial,sans-serif;">$sitetxt{activer_mon_compte}</font></a></td>
              <td width="45" style="border-right:2px solid #07cfd1;border-top:2px solid #07cfd1;border-bottom:2px solid #07cfd1;">&nbsp;</td>
            </tr>
          </table>        
        </td>
      </tr> -->

     	<table style="height:50px;" border="0" cellspacing="0" cellpadding="0" align="center">
        <tr>
          <td width="45" style="border-left:2px solid $site_setup{color_bandeau_bg};border-top:2px solid $site_setup{color_bandeau_bg};border-bottom:2px solid $site_setup{color_bandeau_bg};">&nbsp;</td>
          <td style="border-top:2px solid $site_setup{color_bandeau_bg};border-bottom:2px solid $site_setup{color_bandeau_bg};" align="center"><a style="color:$site_setup{color_bandeau_bg};" href="$link_activation">$sitetxt{activer_mon_compte}</a></td>
          <td width="45" style="border-right:2px solid $site_setup{color_bandeau_bg};border-top:2px solid $site_setup{color_bandeau_bg};border-bottom:2px solid $site_setup{color_bandeau_bg};">&nbsp;</td>
        </tr>
      </table>

HTML

    my $object = $sitetxt{email_object_activation};

    my $body = <<"HTML";

  	$sitetxt{member_bonjour} $member{delivery_firstname} $member{delivery_lastname},<br/><br/>
    $sitetxt{email_activation_content} : <br/><br/>
  
    $link
HTML
    
    member_add_event({member=>\%member,type=>'activation_email',name=>"Envoit du mail d'activation de l'adresse email",detail=>'',erreur=>''});

    

    # Ajout du Header et Footer global au mail
		my %site_setup = %{setup::get_site_setup()};
    if($site_setup{use_site_email_template} eq "y")
    {
	    my $header = setup::get_migcms_site_emails_header({title=>$object, lg=>$lg});
			my $footer = setup::get_migcms_site_emails_footer({lg=>$lg});
			$body = setup::get_migcms_site_email_content({content=>$body});
    	$body = $header . $body . $footer;
    }
    
    send_mail_commercial({object=>$object,body=>$body,member=>\%member,id_template=>$config{id_template_mail_commercial}});
  }
}

sub member_mail_activation_db
{
  my $stoken = get_quoted("stoken");

  my %member = sql_line({dbh=>$dbh, table=>"migcms_members", where=>"stoken = '$stoken' AND stoken != ''"});

  if($member{id} > 0 && ($member{email_actif} eq "n" || $member{password} eq ""))
  {
    $stmt = <<"SQL";
    UPDATE migcms_members
    SET email_actif = 'y'
    WHERE id = '$member{id}'
SQL

    execstmt($dbh, $stmt);

    member_add_event({member=>\%member,type=>'activation_email',name=>"Le membre valide son adresse email",detail=>'',erreur=>''});

    # Redirection sur-mesure
    if($config{custom_member_mail_activation_db_redirect_func} ne "")
    {
    	my $custom_member_mail_activation_db_redirect_func = 'def_handmade::'.$config{custom_member_mail_activation_db_redirect_func};
			&$custom_member_mail_activation_db_redirect_func({member=>\%member});		
    }
    else
    {
	    ### Message de confirmation ###   
	    $content =<<"HTML";     
	      <div class="alert alert-success">
	        <h1><span class="glyphicon glyphicon-ok" aria-hidden="true"></span> 
	       $sitetxt{email_object_activation}</h1>
	       $sitetxt{email_validation_confirmation}
	       <br/><br/>
	       <a href="$self" class="btn btn-success">Mon compte</a> 
	      </div>
HTML
    	
    }
       
  }
  else
  {
  	if($member{email_actif} eq "n")
  	{
	    ### Message de confirmation ###   
	    $content =<<"HTML";     
	      <div class="alert alert-info">
	        <h1><span class="glyphicon glyphicon-ok" aria-hidden="true"></span> 
	       $sitetxt{email_object_activation}</h1>
	       $sitetxt{email_validation_confirmation_already}
	      </div>
HTML
	  }
	  else
	  {
	  	### Message de confirmation ###   
	    $content =<<"HTML";     
	      <div class="alert alert-warning">
	        <h1><span class="glyphicon glyphicon-ok" aria-hidden="true"></span> 
	       $sitetxt{email_object_activation}</h1>
	       $sitetxt{email_validation_confirmation_ko}
	      </div>
HTML
	  }
  		
	}

  my $id_page = $member_setup{id_page};


  my $page_html = migcrender::render_page({force_content=>$content,debug=>0,id=>$id_page,lg=>$lg});
  see();
  print $page_html;
  exit;


}


sub create_identities
{
	my %d = %{$_[0]};


}


#MEMBER LOGOUT DB*********************************************************
sub member_logout_db
{
  my $url_after_logout = get_quoted("url_after_logout");

	my %member = %{members::members_get()};
	my $lg = get_quoted('lg');
	
	#changer token en db
	my $new_token = create_token(100); 
	$stmt = "UPDATE migcms_members SET token = '$new_token' WHERE id = '$member{id}'";
	$cursor = $dbh->prepare($stmt);
	$cursor->execute || suicide($stmt);
	
	#vider cookie
	my $exp = "";
	my $cook = $cgi->cookie(-domain=>$config{cookie_dns},-name=>$config{front_cookie_name},-value=>'',-path=>$config{rewrite_directory},-expires=>'');

	print $cgi->header(-cookie=>[$cook],-charset => 'utf-8');
	
	member_add_event({member=>\%member,type=>'logout',name=>"Le membre se déconnecte",detail=>'',erreur=>''});

  # REDIRECTION
  my $link;
  if($url_after_logout ne "")
  {
    $link = $url_after_logout;
  }
  else
  {
  	#redirect to first page
    if($config{multi_language} eq "y")
    {
    	my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
    	$link = '/'.get_url({debug=>0,nom_table=>'migcms_pages',id_table=>$migcms_setup{id_default_page}, id_language => $lg});      
    }
    else
    {
      $link = '/';
    }
    
  }

	http_redirect($link);
  exit;
}

sub member_html_login_form
{
	my %d = %{$_[0]};
	my %members_setup = select_table($dbh,"members_setup");

	my $email = $d{email};

	my $infos_suppl = $member_setup{id_textid_login_form_infos_suppl};

  my $class_label = $d{class_label} || "col-sm-4 control-label";
  my $class_input_group = $d{class_input_group} || "col-sm-8";
  my $class_submit = $d{class_submit} || "col-sm-4";
  my $class_lost_pwd = $d{class_additionnal_links} || "col-md-8 col-sm-12";

  my $placeholder_login = "$sitetxt{members_login}";
  my $placeholder_password = "$sitetxt{members_password}";

  if($d{placeholder_enable} eq "n")
  {
  	$placeholder_login = "";
  	$placeholder_password = "";
  }


	my $recaptcha = "";
	if($member_setup{disabled_login_recaptcha} ne "y")
	{
		$recaptcha = <<"EOH";
			<div class="form-group">
				<div class="col-sm-8 col-sm-offset-4">
					<div class="g-recaptcha" data-sitekey="$captcha_public_key" ></div>
					<script src="https://www.google.com/recaptcha/api.js?hl=$lg_api" async defer></script>
				</div>
			</div>
EOH
	}

	my $field_email = <<"HTML";
		<div class="form-group">
			<label class="$class_label" for="inputEmail">$sitetxt{members_login} <span class="member_mandatory">*</span></label>
			<div class="$class_input_group">
				<input type="email" name="email" class="required email form-control" required id="inputEmail" placeholder="$placeholder_login" />
				<span class="help-block">($sitetxt{'members_obligatoire'})</span>
			</div>
		</div>
HTML
	if($email ne "")
	{
		$field_email = "<input type='hidden' value=$email name='email'/>"
	}

	#formulaire standard
	my $form = <<"HTML";
<div class="login-form">
	<h1 class="maintitle"><span>$sitetxt{members_title_login}</span></h1>
	$infos_suppl
	<form class="form-horizontal" id="member-login" method="post" action="$self">
		<input type="hidden" name="sw" value="member_login_db" />
		<input type="hidden" name="lg" value="$d{lg}" />
		<input type="hidden" name="gt" value="$d{got}" />
		<input type="hidden" name="url_after_login" value="$d{url_after_login}">
		<input type="hidden" name="url_after_error" value="$d{url_after_error}">
		<input type="hidden" name="id_page" value="$d{id_page}" />

		$field_email
		
		<div class="form-group">
			<label class="$class_label" for="inputPassword">$sitetxt{members_password} <span class="member_mandatory">*</span></label>
			<div class="$class_input_group">
				<input type="password" name="password" class="required form-control" required id="inputPassword" placeholder="$placeholder_password" />
				<span class="help-block">($sitetxt{'members_obligatoire'})</span>
			</div>
		</div>
		$recaptcha
		<div class="login-button">
		  <button type="submit" class="btn btn-info">$sitetxt{members_login_submit}</button>
		</div>
		<div class="lost-password">
		  <a href="$self&sw=lost_password">$sitetxt{members_lost_pasword_title}</a>
		</div>
	</form>
</div>
HTML
	return $form;
}

sub member_html_lost_password_form
{
	my %d = %{$_[0]};
	my %members_setup = select_table($dbh,"members_setup");

	my $form = <<"EOH";
<div class="login-form">
	<h1>$sitetxt{members_lost_pasword_title}</h1>
	<form class="form-horizontal" id="member-lostpassword" method="post" action="$self">
		<input type="hidden" name="sw" value="lost_password_db" />
		<input type="hidden" name="id_page" value="$d{id_page}" />

		<div class="form-group">
			<label class="col-sm-4 control-label" for="inputEmail">$sitetxt{members_login}</label>
			<div class="col-sm-8">
				<input type="email" name="email" class="required email form-control" required id="inputEmail" placeholder="$sitetxt{eshop_identification_input_deja_client_login}" />
				<span class="help-block">($sitetxt{'members_obligatoire'})</span>
			</div>
		</div>			
		
		<div class="form-group">
			<div class="col-md-3 col-md-offset-4 col-sm-4 col-sm-offset-4">
				<button type="submit" class="btn btn-info">$sitetxt{members_lost_password_submit}</button>
			</div>
			<div class="col-md-5 col-sm-4 text-right">
				
			</div>
		</div>
	</form>
</div>	
		
EOH

	return $form;
}

sub member_html_signup_form
{
	my %d = %{$_[0]};
	my %members_setup = select_table($dbh,"members_setup");

	my %valeurs_connues = %{$d{valeurs_connues}};

  my $class_label = $d{class_label} || "col-sm-4 control-label";
  my $class_input_group = $d{class_input_group};

  my %dm_dfl_members = %{members::get_dm_dfl()};

  my $placeholder_enable = $d{placeholder_enable} || "n";

  my $url_after_error = $d{url_after_error} || get_quoted("url_after_error");
  my $url_after_success = $d{url_after_success} || get_quoted("url_after_success");

  my $stoken = $d{stoken};

  # Si fonction sur-mesure renseignée
  if($members_setup{use_handmade_member_html_signup_form_func} ne "")
  {
  	my $fct = 'def_handmade::'.$members_setup{use_handmade_member_html_signup_form_func};
		return &$fct(\%d);
		exit;
  }
  
  my $form = get_frontend_form_from_dm_dfl({class_label=>$class_label, dm_dfl=>\%dm_dfl_members, valeurs_connues=>\%valeurs_connues, class_input_group=>$class_input_group, placeholder_enable=>$placeholder_enable});

  my $infos_suppl = $member_setup{id_textid_signup_form_infos_suppl};

  # On check si le compte existe
  my $title = $sitetxt{create_account};
  if($stoken ne "")
  {
	  my %member = sql_line({table=>"migcms_members", where=>"stoken = '$stoken' AND stoken != ''"});
	  if($member{id} > 0)
	  {
	  	$title = $sitetxt{edit_existing_account};
	  }
  	
  }

	my $form = <<"EOH";
<div class="customer-form">
	<h1 class="maintitle"><span>$title</span></h1>
	<div class="infos-suppl">
		$infos_suppl
	</div>
	<form id="member-signup" method="post" class="form-horizontal" action="$self"  enctype="multipart/form-data">
    <input type="hidden" name="sw" value = "member_signup_db" />     
    <input type="hidden" name="lg" value = "$d{lg}" />
    <input type="hidden" name="url_after_error" value="$url_after_error">    
    <input type="hidden" name="url_after_success" value="$url_after_success">  
    <input type="hidden" name="id_page" value = "$d{id_page}" />
    <input type="hidden" name="stoken" value = "$d{stoken}" />
		$form
		<div class="form-group">
			<div class="col-sm-12 text-right">
				<button type="submit" class="btn btn-info">$sitetxt{members_signup_submit}</button>
			</div>
		</div>
	</form>
</div>
EOH

	return $form;
}


#MEMBER HTML LOGIN LOST-PASSWORD & SIGNUP FORM*********************************************************
sub member_html_login_lost_signup_form
{
	my %d = %{$_[0]};
	my %members_setup = select_table($dbh,"members_setup");   

	#si fonction sur mesure configurée pour remplacer le password
	if ($members_setup{use_handmade_member_login_form_func} ne "") 
	{
		$fct = 'def_handmade::'.$members_setup{use_handmade_member_login_form_func};
		return &$fct(\%d);
		exit;
	}

  # Récupération d'un éventuel message d'erreur
  my $error = get_quoted('error');
  my $error_msg = get_member_error_message({error=>$error});


	my $login_form         = member_html_login_form({id_page=>$d{id_page}, url_after_login=>$d{url_after_login}, url_after_error=>$d{url_after_error}});
	#my $lost_password_form = member_html_lost_password_form({id_page=>$d{id_page}});
	my $form = "";
	
	if($members_setup{disable_member_signup} ne "y")
	{    
		my $signup_form        = member_html_signup_form({id_page=>$d{id_page}, url_after_error=>$d{url_after_error}});
		
		#formulaire standard
		$form = <<"EOH";
<div id="members" class="clearfix">
	<div class="row">
    $error_msg
		<div class="col-md-6">
			$login_form
		</div>
		<div class="col-md-6">
			$signup_form
		</div>
	</div>
</div>
EOH
	}
	else
	{
		#formulaire standard
		$form = <<"EOH";
<div id="members" class="clearfix">
	<div class="row">
		$error_msg
		<div class="col-md-8 col-md-offset-2">
			$login_form
		</div>
	</div>
</div>
EOH
	}

	return $form;
}


#*******************************************************************************
#LOST PASSWORD DB
#*******************************************************************************
sub lost_password_db
{
    #renvoit un email avec lien de modification mdp à partir du token.
	
	my $email = get_quoted('email') || $_[0];
	my $id_page = get_quoted('id_page') || $_[1];
    my $force_id_tpl_page = get_quoted('force_id_tpl_page');
	
	if(!($id_page >0))
	{
		$id_page = $member_setup{id_page};
	}
	
    $email = trim($email);

	my %acces = sql_line({dbh=>$dbh,debug=>1,debug_results=>1,table=>'migcms_members',where=>"UPPER(email) = UPPER('$email') && email != ''"});

  if($acces{id} > 0 && $acces{email} ne '')
  {
  	# Ajout d'un token si le membre n'en possède pas
  	if($acces{token} eq "")
		{
			my $token = create_token(14);

			my $stmt = <<"SQL";
				UPDATE migcms_members
				SET token = '$token'
				WHERE id = '$acces{id}'
SQL
			execstmt($dbh, $stmt);

			$acces{token} = $token;
		}

		# Lien de réinitialisation de MDP
		my $link = "$self_env_full&sw=edit_password&token=$acces{token}&id_page=".$id_page."&force_id_tpl_page=".$force_id_tpl_page;
			
		my $object = $sitetxt{members_lost_password_object};
		my $body = $sitetxt{members_lost_password_body};
		
		member_add_event({member=>\%member,type=>'lost_password',name=>"Le membre demande un changement de mot de passe",detail=>'',erreur=>''});
		
		my $email_from = $member_setup{email_from};
		if($config{'lost_password_db_email_from_tpl_'.$force_id_tpl_page} ne '')
		{
			$email_from = $config{'lost_password_db_email_from_tpl_'.$force_id_tpl_page};
			$object     = $sitetxt{'members_lost_password_object_'.$force_id_tpl_page};
			$body       = $sitetxt{'members_lost_password_body_'.$force_id_tpl_page};
		}
		$body =~ s/{link}/$link/g;
		
		# Ajout du Header et Footer global au mail
		my %site_setup = %{setup::get_site_setup()};
    if($site_setup{use_site_email_template} eq "y")
    {
	    my $header = setup::get_migcms_site_emails_header({title=>$object, lg=>$lg});
			my $footer = setup::get_migcms_site_emails_footer({lg=>$lg});
    	$body = $header . $body . $footer;
    }

		send_mail($email_from,$acces{email},$object,$body,"html");
    if($_[0] eq '')
		{
		  cgi_redirect("$self&sw=lost_password_ok&id_page=".$id_page."&force_id_tpl_page=".$force_id_tpl_page);
		}
  }
  else
  {
   if($_[0] eq '')
	  {
	  cgi_redirect("$self&sw=lost_password_ko&id_page=".$id_page."&force_id_tpl_page=".$force_id_tpl_page);
	  }
  }
}

################################################################################
# lost_password_ok
################################################################################
sub lost_password_ok
{
    see();
	
	my $id_page = get_quoted('id_page');
	my $force_id_tpl_page = get_quoted('force_id_tpl_page');
    my $lg = get_quoted('lg');
	

	
  my %member_setup = %{member_get_setup({lg=>$lg})};
	
	my $page =<<"EOH";

  <div id="members" class="clearfix">
    <div class="alert alert-success">
  		<h1><span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span> 
  		$sitetxt{'members_password_lost'}</h1>
  		$sitetxt{'members_password_ok_txt'}
  	</div>
  </div>
EOH
	
	if($id_page > 0)
	{
		#si une page est passée, on remplace le contenu de la page par le formulaire de login-form
		my $page_html = migcrender::render_page({force_id_tpl_page=>$force_id_tpl_page,force_content=>$page,debug=>0,id=>$id_page,lg=>$lg,preview=>'y',edit=>$edit});
		print $page_html;
		exit;
	}
	else
	{
	  $id_page = $member_setup{id_tpl_page};

    my $page_html =  migcrender::render_page({force_id_tpl_page=>$force_id_tpl_page,content=>$page,id_tpl_page=>$id_page,lg=>$config{current_language}});
    print $page_html;
    exit;
	}
	print '';
	exit;
}

################################################################################
# lost_password_ko
################################################################################
sub lost_password_ko
{
    my $id_page = get_quoted('id_page');
		my $force_id_tpl_page = get_quoted('force_id_tpl_page');

	my $page =<<"EOH";
	
	

	<div class="alert alert-warning">
		<h1><span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span> 
		$sitetxt{'members_password_lost'}</h1>
		$sitetxt{'members_password_ko_txt'}
	</div>
	
	
EOH
    see();
   if($id_page > 0)
	{
		#si une page est passée, on remplace le contenu de la page par le formulaire de login-form
		my $page_html = migcrender::render_page({force_id_tpl_page=>$force_id_tpl_page,force_content=>$page,debug=>0,id=>$id_page,lg=>$lg,preview=>'y',edit=>$edit});
		print $page_html;
		exit;
	}
	print '';
	exit;
}

################################################################################
# edit_password
################################################################################
sub edit_password
{
    my $token = get_quoted('token');
    my $id_page = get_quoted('id_page');
    my $force_id_tpl_page = get_quoted('force_id_tpl_page');
	
	
    my %member = sql_line({table=>'migcms_members',where=>"token='$token'"});
    
   my $error_msg = '';
   my $error = get_quoted('error');
   if($error == 1)
   {
        $error_msg = <<"EOH";
                  <div class="alert alert-block alert-error alert-danger">
                    <p>$sitetxt{edit_password_error}</p>
                  </div>
EOH
   } 
   
   my $page = <<"EOH";
	  <div id="eshop_alert">$error_msg</div>
      <div id="eshop" class="clearfix">
            <div class="lostpassword-form">
				<h3>$sitetxt{edit_password_title}</h3><br>
				<form class="form-horizontal" method="post" id="edit_password_form" action="$self">
				<input type="hidden" name="sw" value = "edit_password_db" />
				<input type="hidden" name="lg" value = "$lg" />
				<input type="hidden" name="force_id_tpl_page" value = "$force_id_tpl_page" />
				<input type="hidden" name="id_page" value = "$id_page" />
				<input type="hidden" name="t" value = "$type" />
				<input type="hidden" name="token" value = "$member{token}" />
				
				  <div class="form-group">
						<label class="control-label col-sm-4">$sitetxt{edit_password_new} *</label>
						<div class="col-sm-8">
							<input type="password" name="new_password" required class="required form-control" />
						</div>
					</div>
					<div class="form-group">
						<label class="control-label col-sm-4">$sitetxt{edit_password_new2} *</label>
						<div class="col-sm-8">
							<input type="password" name="new_password2" required class="required form-control" />
						</div>
					</div>
					<div class="form-group">
						<div class="col-sm-4"></div>
						<div class="col-sm-8">
							<button type="submit" class="btn btn-info">$sitetxt{edit_password_new3}</button>
						</div>
					</div>
				</form>
            </div>
      </div>
EOH
   
  if(!($id_page >0))
  {
    $id_page = $member_setup{id_page};
  }
 	$lg=1;
  see();
  if($id_page > 0)
	{
		my $page_html = migcrender::render_page({force_id_tpl_page=>$force_id_tpl_page,force_content=>$page,debug=>0,id=>$id_page,lg=>$lg,preview=>'y',edit=>$edit});
		print $page_html;
		exit;
	}
	print '';
	exit;
}
################################################################################
# edit_password_db
################################################################################
sub edit_password_db
{
	my $id_page = get_quoted('id_page');
	my $token = get_quoted('token');
    my $force_id_tpl_page = get_quoted('force_id_tpl_page');
	
    my %member = sql_line({table=>'migcms_members',where=>"token='$token'"});
    if($member{id} eq "")
    {
		 see();
		 print "Le lien a expiré, veuillez recommencer la procédure de récupération de mot de passe svp";
		 exit;
    }

    my $url_after_edit = get_quoted("url_after_edit") || "$self&sw=edit_password_ok&id_page=".$id_page."&force_id_tpl_page=".$force_id_tpl_page;
    my $url_after_error = get_quoted("url_after_error") || "$self&sw=edit_password&token=$token&error=1&id_page=".$id_page."&force_id_tpl_page=".$force_id_tpl_page;

    if($member{id} > 0)
    {
        my $password = get_quoted('new_password');
        my $verif_password = get_quoted('new_password2');
        my $spassword = sha1_hex($password);
		
        if($password ne '' && $password eq $verif_password)
        {        
            $stmt = "UPDATE migcms_members SET password='$spassword' where id=$member{id}";
            execstmt($dbh,$stmt);
            member_add_event({member=>\%member,type=>'edit_pasword',name=>"Le membre change son mot de passe",detail=>'',erreur=>''});
            cgi_redirect($url_after_edit);
        }
        else
        {
            member_add_event({member=>\%member,type=>'edit_pasword_error',name=>"Les nouveaux mots de passe ne correspondent pas",detail=>'',erreur=>''});
			cgi_redirect($url_after_error);
        }
    }
    else
    {
         cgi_redirect("$self&sw=edit_password_ko&id_page=".$id_page."&force_id_tpl_page=".$force_id_tpl_page);
    }
}

################################################################################
# edit_password_ok
################################################################################
sub edit_password_ok
{
	my $id_page = get_quoted('id_page');
	my $force_id_tpl_page = get_quoted('force_id_tpl_page');
	
	my $page =<<"EOH";			
<div class="alert alert-success">
		<h1><span class="glyphicon glyphicon-ok" aria-hidden="true"></span> 
		$sitetxt{'edit_password_ok_title'}</h1>
		$sitetxt{'edit_password_ok_content'}
</div>

	
EOH
    see();
    if($id_page > 0)
	{
		my $page_html = migcrender::render_page({force_id_tpl_page=>$force_id_tpl_page,force_content=>$page,debug=>0,id=>$id_page,lg=>$lg,preview=>'y',edit=>$edit});
		print $page_html;
		exit;
	}
	print '';
	exit;
}


################################################################################
# edit_password_ko
################################################################################
sub edit_password_ko
{
    my $id_page = get_quoted('id_page');
	my $force_id_tpl_page = get_quoted('force_id_tpl_page');	
	
	my $page =<<"EOH";	
Erreur inconnue (bad token member)	
EOH
    see();
    if($id_page > 0)
	{
		my $page_html = migcrender::render_page({force_id_tpl_page=>$force_id_tpl_page,force_content=>$page,debug=>0,id=>$id_page,lg=>$lg,preview=>'y',edit=>$edit});
		print $page_html;
		exit;
	}
	print '';
	exit;
}

##################################################
################## get_members_txt ###############
##################################################
# Renvoit un hash des textes des membres dans 
# la langue spécifiée
# 
# params: 1 => Le numéro de la langue voulue
#        
##################################################
sub get_members_txt
{
  my $lg = $_[0] || 1;

  # Création d'un nouveau hash sitetxt pour avoir la langue de la commande lorsqu'on appelle le hash
  my @sitetxt_members = sql_lines({debug_results=> 0, dbh=>$dbh,table=>"members_txts"});
  my %sitetxt=();
  foreach $sitetxt_members (@sitetxt_members)
  {
    my %sitetxt_members = %{$sitetxt_members};
    my $value = $sitetxt_members{"lg".$lg};
    if($value eq "")
    {
      $value = $sitetxt_members{"lg1"};
    }

    $sitetxt{$sitetxt_members{keyword}} = $value;

  }

  return \%sitetxt;

}

# sub reset_password
# {
# 	my $id_exposant = get_quoted('id_exposant') || "0";

# 	print "ok";
# 	exit;
#   my @chars = ("a" .. "z");
#   my $new_password = join("", @chars[ map { rand @chars } ( 1 .. 5 ) ]);
  
#   my $stmt = "UPDATE migcms_members SET password='".sha1_hex($new_password)."' where id = '".$id_exposant."'";
  
#   my $cursor = $dbh_data->prepare($stmt);
# }


sub members_migcms_history
{
	my $dbh = $_[0];
	my $id = $_[1];
	
	my $sel = get_quoted('sel');
	
	my %migcms_member = sql_line({table=>'migcms_members',where=>"$id"});
	
	my $history = '';
	
	
	
	

	
	#INSCRIPTION
	my %ev = sql_line({debug=>0,debug_results=>0,table=>'migcms_members_events',where=>"id_member='$id' AND type_evt IN ('signup_insert','signup_update')",ordby=>"moment desc"});
	if($ev{id}>0)
	{
		$dateheure = to_ddmmyyyy($ev{moment},'withtime');
		$history .=<<"EOH";
		<strong>Date de l'inscription :</strong> $dateheure<br />
EOH
	}
	else
	{
		$dateheure = to_ddmmyyyy($migcms_member{migcms_moment_create},'withouttime');
		$history .=<<"EOH";
		<strong>Date de l'inscription :</strong> $dateheure<br />
EOH

	}
	
	#CONNEXION
	my %ev = sql_line({debug=>0,debug_results=>0,table=>'migcms_members_events',where=>"id_member='$id' AND type_evt IN ('login')",ordby=>"moment desc"});
	if($ev{id}>0)
	{
		$dateheure = to_ddmmyyyy($ev{moment},'withtime');
		$history .=<<"EOH";
		<strong>Dernière connexion :</strong> $dateheure<br />
EOH
	}
	
	my %total_pages = sql_line({debug=>0,debug_results=>0,select=>"id,detail_evt,count(*) as nb",table=>'migcms_members_events',where=>"id_member='$id' AND `type_evt` ='view_page'"});
	$history .= <<"EOH";
	<br />
	<strong>Nombre de pages consultées :</strong> $total_pages{nb}<br />
EOH

	my %total_mailing = sql_line({debug=>0,debug_results=>0,select=>"id,detail_evt,count(*) as nb",table=>'migcms_members_events',where=>"id_member='$id' AND `group_type_event`='mailing' AND `type_evt` ='sent_mailing'"});
	$history .= <<"EOH";
	<strong>Nombre d'e-mailing envoyés :</strong> $total_mailing{nb}<br />
EOH

	my %total_mailing_read = sql_line({debug=>0,debug_results=>0,select=>"id,detail_evt,count(*) as nb",table=>'migcms_members_events',where=>"id_member='$id' AND `group_type_event`='mailing' AND `type_evt` ='open_mailing'"});
	$history .= <<"EOH";
	<strong>Nombre d'e-mailing ouverts :</strong> $total_mailing_read{nb}<br />
EOH

	my %total_mailing_clics = sql_line({debug=>0,debug_results=>0,select=>"id,detail_evt,count(*) as nb",table=>'migcms_members_events',where=>"id_member='$id' AND `group_type_event`='mailing' AND `type_evt` ='click_mailing'"});
	$history .= <<"EOH";
	<strong>Nombre de clics dans les e-mailings :</strong> $total_mailing_clics{nb}<br /><br />
	<a target="_blank" href="adm_migcms_members_events.pl?id_member=$id&sel=$sel" class="btn btn-primary">Voir l'historique complet des actions du membre</a>
EOH

	return $history;
}

#####################################################################
# member_mailing_subscribe_db
#####################################################################
sub member_mailing_subscribe_db
{
  my $email   = get_quoted("email");
  my $tags    = get_quoted("tags");
  my $groups  = get_quoted("groups");
  my $lg      = get_quoted("lg") || 1;
  my $id_page = get_quoted("id_page") || "";
  my $page    = "";
  
  @groups_ids = split /\,/, $groups;
  
  $tags = $groups.$tags;

  my $erreur = "n";
  if($email eq "" || $tags eq "")
  {
    $erreur = "y";
    $page =<<"EOH";
      <div class="alert alert-danger">
        <h1><span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span> 
        $sitetxt{members_erreur_required_field_title}</h1>
        $sitetxt{members_erreur_required_field_txt}
        <br><br>
        <input type="button" class="btn btn-danger" value="$sitetxt{retour}" onclick="window.history.back()" /> 
      </div>
EOH
  }

  ### Test si le membre existe deja ###
  my %test_member = sql_line({table=>'migcms_members',where=>"email != '' AND email = '$email'"});

  # COLONNE DE VALIDATION NEWSLETTER
  my $col_email_optin = "email_optin";
  if($config{email_optin_multisite} eq "y")
  {
    $col_email_optin = $config{'col_email_optin_'.$ENV{HTTP_HOST}};
  }

  my $id_member;
  if($test_member{id} > 0)
  {
    # MEMBRE EXISTANT
    $tags .= $test_member{tags} . ",$lg,2003,";

    

    %update_member = (
      $col_email_optin        => 'y',
      tags                    => $tags,
      migcms_moment_last_edit => "NOW()",
    );


    ### Update du membre ###
    $id_member = sql_set_data({dbh=>$dbh, table=>'migcms_members',data=>\%update_member, where=>"id = $test_member{id}"});
    member_add_event({member=>\%update_member,type=>'signup_insert',name=>"Le membre s'inscrit à la newsletter",detail=>'',erreur=>''});
  }
  else
  {
    # PAS DE MEMBRE EXISTANT

    # On rajoute le tag de langue de l'utilisateur
    $tags .= ",$lg,2003,";

    my %new_member = (
      $col_email_optin             => 'y',
      email_validation_statut_sent => 'y',
      email                        => $email,
      tags                         => $tags,
      migcms_moment_create         => "NOW()",
    );

    ### Ajout du membre ###
    $id_member = inserth_db($dbh,"migcms_members",\%new_member);
    member_add_event({member=>\%new_member,type=>'signup_insert',name=>"Nouveau membre newsletter",detail=>'',erreur=>''});
  }
  
	# ASSOCIATION D'UN GROUP AU MEMBRE
	foreach my $group (@groups_ids)
	{				
		my $group_value = get_quoted('group_'.$group);
		
		if($group_value eq 'y') {
		
			my %addgroup = (
			  id_migcms_member_tag		   	=> $group,
			  id_migcms_member		   		=> $id_member,
			  migcms_moment_last_edit 		=> "NOW()",
			);
			
			sql_set_data({dbh=>$dbh, table=>"migcms_member_tag_emails", where=>"id_migcms_member='$memberid' AND id_migcms_member_tag='$group'", data=>\%addgroup});
		
		}
		else {
			$stmt = <<"EOH";
			DELETE FROM migcms_member_tag_emails WHERE id_migcms_member='$memberid' AND id_migcms_member_tag='$group'
EOH
			my $cursor = $dbh->prepare($stmt);
			my $rc = $cursor->execute;
			if (!defined $rc) {suicide($stmt);}
		}
	
	}

	if($config{after_mailing_subscribe_func} ne "")
  {
    my $after_mailing_subscribe_func = 'def_handmade::'.$member_setup{after_mailing_subscribe_func};
		&$after_mailing_subscribe_func({id_member=>$id_member});		
  }
  
  

  if($erreur eq "n")
  {
    # S'il n'y a pas eu d'erreur et que le membre a bien été inscrit à la newsletter 
  	# Redirection vers la page de confirmation 
		cgi_redirect($config{baseurl}."/".$sitetxt{member_url_mailing_subscribe_ok});
  }

  # Affichage de la confirmation ou de l'erreur
  if(!($id_page >0))
  {
    $id_page = $member_setup{id_page};
  }

  my $page_html = migcrender::render_page({force_content=>$page,debug=>0,id=>$id_page,lg=>$lg});
  see();
  print $page_html;
  exit; 
}


#####################################################################
# member_mailing_unsubscribe_db
#####################################################################
sub member_mailing_unsubscribe_db
{
  log_debug('member_mailing_unsubscribe_db','','member_mailing_unsubscribe_db');
  my $email   = trim(get_quoted("email"));
  my $lg      = get_quoted("lg") || 1;
  my $id_mailing = get_quoted("id_mailing") || "";
  my $id_sending = get_quoted("id_sending") || "";
  my $optout = get_quoted("optout") || "";
    see();
  my $page = "";
    my $id_page = $member_setup{id_page};

  #TOUCHE PAS A CA PETIT CON
  #$stmt = "INSERT INTO mailing_blacklist (id_mailing,id_sending,email,moment,reason) VALUES ($id_mailing,$id_sending,'$email','NOW()','unsubscribe')";
  #execstmt($dbh,$stmt);

  my $erreur = "n";
  if($email eq "")
  {
    log_debug('Erreur: email vide','','member_mailing_unsubscribe_db');
	$erreur = "y";
    $page =<<"EOH";
      <div class="alert alert-danger">
        <h1><span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span> 
        $sitetxt{members_erreur_required_field_title}</h1>
        $sitetxt{members_erreur_required_field_txt}
        <br><br>
        <input type="button" class="btn btn-danger" value="$sitetxt{retour}" onclick="window.history.back()" /> 
      </div>
EOH
  }

  ### Retrouve le membre existe deja ###
  my %migcms_member = sql_line({table=>'migcms_members',where=>"email != '' AND email = '$email'"});
  if($migcms_member{id} > 0)
  {
    #OK
	log_debug('Ok: membre '.$migcms_member{id},'','member_mailing_unsubscribe_db');
EOH
  }
  else
  {
	  log_debug('Erreur: membre par trouve pour email:'.$email,'','member_mailing_unsubscribe_db');
	  $erreur = "y";
		$page =<<"EOH";
		  <div class="alert alert-danger">
			<h1><span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span> 
			$sitetxt{members_erreur_required_field_title}</h1>
			$sitetxt{members_erreur_required_field_txt}
			<br><br>
			<input type="button" class="btn btn-danger" value="$sitetxt{retour}" onclick="window.history.back()" /> 
		  </div>
EOH
  
  }

  if($erreur eq "n")
  {
    my $field_optout = 'email_optin';
	if($optout == 2)
	{
		$field_optout = 'email_optin_2';
		$id_page = $config{id_unsubscrible_mailing_page2};
	}
	
	 log_debug('Optout:'.$field_optout,'','member_mailing_unsubscribe_db');

	
	my %update_member = (
      $field_optout      					 => 'n',
      tags             					 => $migcms_member{tags}.',2004,',
      migcms_moment_last_edit    => "NOW()",
    );

    ### Maj du membre ###
    updateh_db($dbh,"migcms_members",\%update_member,'id',$migcms_member{id});

	 
	
    member_add_event({member=>\%migcms_member,type=>'optout',name=>"Désinscription mailing $optout",detail=>'',erreur=>''});

    ### Message de confirmation ###   
    $page =<<"EOH";     
      <div class="alert alert-success">
        <h1><span class="glyphicon glyphicon-ok" aria-hidden="true"></span> 
        $sitetxt{members_mailing_unsubscribre_confirmation_title}</h1>
      </div>
EOH
  }


  # Id page BIS (dans le cas d'un backoffice gérant plusieurs site. Ex : E+ et maconstruction)
  # my $id_page_bis = get_quoted("id_page_bis");
  # if($id_page_bis ne "")
  # {
  	# $id_page = $id_page_bis;
  # }

  my $page_html = migcrender::render_page({force_content=>$page,debug=>0,id=>$id_page,lg=>$lg});

  print $page_html;
  exit; 
}





sub get_member_status_value
{
  my $id = $_[0];

  my %member_status = sql_line({select=>"value", table=>"migcms_members_status", where=>"id = '$id'"});

  return $member_status{value};
}

sub get_dm_dfl
{
  my %d = %{$_[0]};
  
  my %migctrad = %{$d{migctrad}};

  my %members_setup = %{member_get_setup({lg=>$lg})};

  my %dm_dfl;
  if($members_setup{use_handmade_members} eq 'y')
  {
    %dm_dfl = %{def_handmade::get_members_handmade_dm_dfl({migctrad=>\%migctrad})};
  }
  else
  {
    my $lang;
    
    if($lg == 2)
    {
      $lang = "en";
    }
    elsif($lg == 3)
    {
      $lang = "nl";
    }
  	else
  	{
  	  $lang = "fr";
  	}

    %dm_dfl = 
    (    
       
      '01/delivery_lastname'=> 
      {
      'title'     => 'Nom',
      'fieldtype' => 'text',
      'search'    => 'y',
      'tab'       => 'client',
      'mandatory' => {"type" => ''},

      'frontend_editable' => 'y',
      'frontend_title'    => "$sitetxt{members_lastname}",
      'frontend_required' => "y",      
      } 
      ,
      '02/delivery_firstname'=> 
      {
        'title'=>'Prénom',
        'fieldtype'=>'text',
        'search' => 'y',
        'tab'=>'client',
        'mandatory'=>{"type" => ''},

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_firstname}",
        'frontend_required' => "y",           
      } 
      ,
      '10/delivery_enseigne'=> 
      {
        'title'=>'Enseigne',
        'fieldtype'=>'text',
        'search' => 'y',
        'tab'=>'client',
        'mandatory'=>{"type" => ''},

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_enseigne}",
        'frontend_required' => "",              
      } 
      ,
      '14/delivery_company'=> 
      {
        'title'=>'Société',
        'fieldtype'=>'text',
        'search' => 'y',
        'tab'=>'client',
        'mandatory'=>{"type" => ''},

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_company}",
        'frontend_required' => "",              
      } 
      ,
      '15/delivery_vat'=> 
      {
        'title'=>'N° TVA',
        'fieldtype'=>'text',
        'search' => 'y',
        'tab'=>'client',
        'mandatory'=>{"type" => ''},

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_vat}",
        'frontend_required' => "",              
      } 
      ,
      
      '16/delivery_street'=> 
      {
        'title'=>"Adresse",
        'fieldtype'=>'text',
        'search' => 'y',
        'tab'=>'client',

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_street}",
        'frontend_required' => "y",
      }
      ,
      '17/delivery_number'=> 
      {
        'title'=>"N°",
        'fieldtype'=>'text',
        'search' => 'y',
        'tab'=>'client',

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_number}",
        'frontend_required' => "y",
      }
      ,
      '18/delivery_box'=> 
      {
        'title'     =>"Boite",
        'fieldtype' =>'text',
        'search'    => 'y',
        'tab'       =>'client',

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_box}",
        'frontend_required' => "",
      }
      ,
      '19/delivery_zip'=> 
      {
        'title'=>"Code postal",
        'fieldtype'=>'text',
        'search' => 'y',
        'tab'=>'client',

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_zip}",
        'frontend_required' => "y",
      }
      , 
      '20/delivery_city'=> 
      {
        'title'=>"Ville",
        'fieldtype'=>'text',
        'search' => 'y',
        'tab'=>'client',

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_city}",
        'frontend_required' => "y",
      } 
      , 
      '21/delivery_country'=> 
      {                        
        'title'     => "Pays (ISO)",
        'fieldtype' => 'listboxtable',
        'lbtable'   => 'shop_delcost_countries dc, countries c',
        'lbwhere'     => 'dc.isocode=c.iso',
         'lbkey'     => 'c.id',
        'lbdisplay' => 'c.'.$lang,
        'lbordby'   => 'c.'.$lang,
        'key_default' => 19, # id du pays par défaut à sélectionner
        'search'    => 'n',
        'tab'       => 'client',

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_country}",
        'frontend_required' => "y",
      } 
      ,
      '22/delivery_phone'=>
      {
        'title'=>"Téléphone",
        'fieldtype'=>'text',
        'data_type'=>'phone',
        'search' => 'n',
        'tab'=>'client',

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_tel}",
        'frontend_required' => "y",
      }
      ,
      '25/email'=> 
      {
        'title'=>'Email (Identifiant)',
        'fieldtype'=>'text',
        'data_type'=>'email',
        'search' => 'y',
        'tab'=>'connexion',
        'mandatory'=>{"type" => ''},

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_email}",
        'frontend_required' => "y", 
      }
      ,
      '25/email2'=> 
      {
        'title'=>'',
        'fieldtype'=>'text',
        'data_type'=>'email',
        'search' => 'n',
        'tab'=>'connexion',
        'mandatory'=>{"type" => ''},

        'frontend_only'=>'y',

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_confirme_email}",
        'frontend_required' => "y", 
      }
      ,
      '26/password'=> 
      {
        'title'=>'Mot de passe',
        'data_type'=>'password',
        'fieldtype'=>'text',
        'search' => 'n',
        'tab'=>'connexion',

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_password}",
        'frontend_required' => "y", 
      }
      ,
      '26/password2'=> 
      {
        'title'=>'Confirmer le mot de passe',
        'data_type'=>'password',
        'fieldtype'=>'text',
        'search' => 'n',
        'tab'=>'connexion',

        'frontend_only'=>'y',

        'frontend_editable' => 'y',
        'frontend_title'    => "$sitetxt{members_confirme_password}",
        'frontend_required' => "y",
      }
      ,
      '30/are_same'=> 
      {
        'title'=>'Adresse facturation = Coordonnées',
        'fieldtype'=>'checkbox',
        'default_value'=>'y',
        'checkedval' => 'y',
        'tab'=>'client'
      }
      ,
     # '33/billing_firstname'=> 
     #  {
     #    'title'=>'Prénom',
     #    'fieldtype'=>'text',
     #    'search' => 'y',
     #    'tab'=>'financier',
     #  }
     #  ,
     #  '34/billing_lastname'=> 
     #  {
     #    'title'=>'Nom',
     #    'fieldtype'=>'text',
     #    'search' => 'y',
     #    'tab'=>'financier'
     #  }
     #  ,
     #  '35/billing_company'=> 
     #  {
     #    'title'=>'Enseigne',
     #    'fieldtype'=>'text',
     #    'search' => 'y',
     #    'tab'=>'financier'
     #  }    
     #  ,
     #  '35/billing_vat'=> 
     #  {
     #    'title'=>'N° TVA',
     #    'fieldtype'=>'text',
     #    'search' => 'y',
     #    'tab'=>'client',
     #    'mandatory'=>{"type" => ''},

     #    'frontend_editable' => 'y',
     #    'frontend_title'    => "$sitetxt{members_vat}",
     #    'frontend_required' => "",              
     #  } 
     #  ,
     # '36/billing_street'=> 
     #  {
     #    'title'=>'Adresse',
     #    'fieldtype'=>'text',
     #    'search' => 'n',
     #    'tab'=>'financier'
     #  }
     #  ,
     #  '37/billing_number'=> 
     #   {
     #    'title'=>'N°',
     #    'fieldtype'=>'text',
     #    'search' => 'n',
     #    'tab'=>'financier'
     #  }
     #  ,
     #  '38/billing_box'=> 
     #  {
     #    'title'=>'Boite',
     #    'fieldtype'=>'text',
     #    'search' => 'n',
     #    'tab'=>'financier'
     #  }
     #  ,
     #  '39/billing_zip'=> 
     #  {
     #    'title'=>'Code postal',
     #    'fieldtype'=>'text',
     #    'search' => 'n',
     #    'tab'=>'financier'
     #  }
     #  ,
     #  '40/billing_city'=> 
     #   {
     #      'title'=>'Ville',
     #      'fieldtype'=>'text',
     #      'search' => 'n',
     #      'tab'=>'financier'
     #  }
     #  , 
     #  '42/billing_country'=> 
     #  {
     #    'title'=>"Pays (ISO)",
     #   'fieldtype'=>'text',
     #    'search' => 'n',
     #    'tab'=>'financier'
     #  }
     #  ,
     #  '41/billing_phone'=> 
     #  {
     #    'title'=>"Téléphone",
     #   'fieldtype'=>'text',
     #    'search' => 'n',
     #    'tab'=>'financier'
     #  }     
     #  ,
     #  '42/billing_email'=> 
     #  {
     #    'title'=>"Email",
     #   'fieldtype'=>'text',
     #    'search' => 'n',
     #    'tab'=>'financier'
     #  }         
      # ,
      # '55/member_type'=> 
      # {
        # 'title'=>"Type de membre",
        # 'fieldtype'=>'listbox',
        # 'tab'=>'commercial',
        # 'fieldvalues'=>\%member_types,
      # }
      ,
      '56/remarque'=> 
      {
        'title'=>'Note interne',
        'fieldtype'=>'textarea',
        'tab'=>'notes'
      },
      '57/actif'  =>{'title'=>'Validation',legend=>'Le membre peut-il se connecter sur le site ?','fieldtype'=>'listbox','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>'connexion','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','fieldvalues'=>\%email_optin,'hidden'=>0},
      '58/email_actif'  =>{'title'=>'Email validé',legend=>'Le membre a-t-il validé son adresse email ?','fieldtype'=>'listbox','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>'connexion','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','fieldvalues'=>\%email_optin,'hidden'=>0},
      '59/email_optin'  =>{'title'=>'Opt-in '.$config{col_email_optin_label},'fieldtype'=>'listbox','data_type'=>'',legend=>'Le membre a-t-il autorisé un contact commercial par email ?','search' => 'n','mandatory'=>{"type" => ''},'tab'=>'commercial','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','fieldvalues'=>\%email_optin,'hidden'=>0,
        'frontend_addonly' => 'y',
        'frontend_editable' => 'n',
        'frontend_title'    => "$sitetxt{edit_optin_txt}",
        'frontend_required' => "y",
      },
	  '60/email_optin_2'  =>{'title'=>'Opt-in '.$config{col_email_optin_2_label},'fieldtype'=>'listbox','data_type'=>'',legend=>'Le membre a-t-il autorisé un contact commercial par email ?','search' => 'n','mandatory'=>{"type" => ''},'tab'=>'commercial','default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>'','fieldvalues'=>\%email_optin,'hidden'=>0,
        'frontend_addonly' => 'y',
        'frontend_editable' => 'n',
        'frontend_title'    => "$sitetxt{edit_optin_txt}",
        'frontend_required' => "y",
      },
      '75/id_tarif'=> 
       {
          'title'=>"Tarif",
          'fieldtype'=>'listboxtable',
           'lbtable'=>'eshop_tarifs',
           'lbkey'=>'id',
           'lbdisplay'=>"name",
           'lbwhere'=>"visible='y'" ,
           'search' => 'n',
           'tab'=>'eshop'
        }
      ,
      '61/tags'=> 
      {
        'title'=>"Segments",
        'fieldtype'=>'listboxtable',
        'lbtable'=>'migcms_members_tags',
        'data_type'=>'button',
        'multiple'=>1,
			'data_split'=>'type',
		
        'lbkey'=>'id',
        'lbdisplay'=>"name",
        'lbwhere'=>"visible='y'" ,
        'lbordby'=>"ordby" ,
        'search' => 'n',
        'tab'=>'commercial'
      },
      '70/id_member_group'=>{'title'=>'Groupes de membres','fieldtype'=>'listboxtable','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'tab'=>'group','default_value'=>'','lbtable'=>'migcms_member_groups','lbkey'=>'id','lbdisplay'=>'id_textid_name','lbwhere'=>'','fieldvalues'=>'','hidden'=>0, "translate"=>1,},

    );
  }
  
	if($config{email_optin_multisite} ne 'y')
	{
	delete $dm_dfl{'60/email_optin_2'};
	}

  return \%dm_dfl;
}

################################################################################
# get_menu
################################################################################
sub get_menu
{
  my %eshop_setup = %{eshop::get_setup()};
  my %members_menu;

  if($member_setup{custom_menu} eq "y")
  {
    %members_menu = %{def_handmade::get_member_custom_menu()};
  }
  else
  {
    %members_menu =
    (
      "01/$sitetxt{member_my_account}"=> 
      {
        "01" =>
        {
          title => "$sitetxt{member_mes_coordonnees}",
          link  => $config{baseurl}.'/'.'cgi-bin/members.pl?lg='.$lg.'&extlink='.$extlink . "&sw=member_edit_coordonnees",
          visible => "y",
        }
        ,
        "02" =>
        {
          title => "$sitetxt{member_update_password}",
          link  => $config{baseurl}.'/'.'cgi-bin/members.pl?lg='.$lg.'&extlink='.$extlink . "&sw=member_edit_password",
          visible => "y",
        }
		,
        "03" =>
        {
          title => "$sitetxt{member_update_optin}",
          link  => $config{baseurl}.'/'.'cgi-bin/members.pl?lg='.$lg.'&extlink='.$extlink . "&sw=member_edit_optin",
          visible => "y",
        }
        ,
        # "04" =>
        # {
        #   title => "$sitetxt{member_social_networks}",
        #   link  => $config{fullurl}.'/'.'cgi-bin/members.pl?lg='.$lg.'&extlink='.$extlink . "&sw=member_social_network_link",
        #   visible => "y",
        # }
        # ,
        "50" =>
        {
          title => "$sitetxt{members_logout}",
          link  => $config{baseurl}.'/'.'cgi-bin/members.pl?lg='.$lg.'&extlink='.$extlink . "&sw=member_logout_db",
          visible => "y",
        }
        ,
      }
      ,
    );

    # Si la boutique est activée
    if($eshop_setup{shop_disabled} ne "y")
    {
      my %eshop_menu =  %{get_eshop_menu({lg=>$lg, extlink=>$extlink})};
      %members_menu = (%members_menu, %eshop_menu);
    }
  
  }

  
  

  


  
  my $menu = '<div id="members-menu">';

  foreach $key (sort keys %members_menu)
  {
    my ($ordby,$menu_name) = split(/\//,$key);
	my $id = clean_url($menu_name);

    $menu .= <<"EOH";
      <div class='members-submenu' id="$id">
        <h1 class='menu_title_lvl_1'>$menu_name</h1>
        <ul>
EOH
    foreach my $submenu (sort keys %{$members_menu{$key}})
    {
      if($members_menu{$key}{$submenu}{visible} eq "y")
      {
        my $migc_selitem;
        if($extlink_member eq "$ordby\-$submenu")
        {
          $migc_selitem = "migc_selitem";
        }
        $menu .= "<li><a class='$migc_selitem $members_menu{$key}{$submenu}{class}' $migc_selitem $members_menu{$key}{$submenu}{attr} style='$members_menu{$key}{$submenu}{style}' href='$members_menu{$key}{$submenu}{link}&extlink_member=$ordby\-$submenu'>$members_menu{$key}{$submenu}{title}</a></li>";        
      }
    }
    $menu .= "</ul></div>";

  }
  $menu .= '</div>';

  return $menu;
}

################################################################################
# get_eshop_menu
################################################################################
sub get_eshop_menu
{
  my %eshop_menu;

  %eshop_menu =
  (
    "02/$sitetxt{eshop_menu}"=> 
    {
      "01" =>
      {
        title => "<i class='glyphicon glyphicon-road'></i> $sitetxt{eshop_ad_liv}",
        link  => $config{baseurl}.'/'.'cgi-bin/members.pl?lg='.$lg.'&extlink='.$extlink . "&sw=member_edit_identity&type=delivery",
        visible => "y",
      }
      ,
      "02" =>
      {
        title => "<i class='glyphicon glyphicon-euro'></i> $sitetxt{eshop_ad_fac}",
        link  => $config{baseurl}.'/'.'cgi-bin/members.pl?lg='.$lg.'&extlink='.$extlink . "&sw=member_edit_identity&type=billing",
        visible => "y",
      }
      ,
      "03" =>
      {
        title => "<i class='glyphicon glyphicon-list-alt'></i> $sitetxt{eshop_metatitle_history}",
        link  => $config{baseurl}.'/'.'cgi-bin/members.pl?lg='.$lg.'&extlink='.$extlink . "&sw=member_orders_history",
        visible => "y",
      }
      ,
      "04" =>
      {
        title => "<i class='glyphicon glyphicon-heart'></i> $sitetxt{eshop_metatitle_wishlist}",
        link  => $config{baseurl}.'/'.'cgi-bin/members.pl?lg='.$lg.'&extlink='.$extlink . "&sw=member_wishlist",
        visible => "y",
      }
      ,

    }
    ,
  );
  
  return \%eshop_menu;
}

sub get_frontend_form_from_dm_dfl
{
  my %d = %{$_[0]};

  my %dm_dfl = %{$d{dm_dfl}};
  my %member = %{members_get()};
  my @fields_to_exclude = @{$d{fields_to_exclude}};
  my %fields_to_exclude = map { $_ => 1 } @fields_to_exclude;
  my %valeurs_connues = %{$d{valeurs_connues}};

  if($valeurs_connues{email} ne "" && $valeurs_connues{email2} eq "")
  {
  	$valeurs_connues{email2} = $valeurs_connues{email};
  }

  my $class_input_group = $d{class_input_group} || "col-sm-8";

  my $form_content;
  foreach my $field_line (sort keys %dm_dfl)
  {
    my ($ordby,$field_name) = split(/\//,$field_line);

    if(!($dm_dfl{$field_line}{frontend_editable} eq "y") || exists($fields_to_exclude{$field_name}) || ($member{id} > 0 && $dm_dfl{$field_line}{frontend_insert_only} eq "y"))
    {
      next;
    }
	

    $dm_dfl{$field_line}{title} = ucfirst($dm_dfl{$field_line}{title});

    # Récupération de la valeur du champ
    $dm_dfl{$field_line}{value} = $member{$field_name} || get_quoted($field_name) || $valeurs_connues{$field_name};
    $dm_dfl{$field_line}{value} =~ s/\\//g;

    my $type =  $dm_dfl{$field_line}{fieldtype};
    
    my $data_type =  $dm_dfl{$field_line}{data_type};

    # Gestion des champs obligatoire
    my $required;
    my $mandatory;
    if($dm_dfl{$field_line}{frontend_required} eq "y")
    {
      $required = "required";
      $mandatory = "*";
    }
	

    # Génération du champ (input, select, checkbox, etc)
    my $field;
    if($type eq "text" || $type eq "text_id")
    {
      my $field_value = $dm_dfl{$field_line}{value};
      if($type eq "text_id")
      {
        $field_value = get_traduction({id_traduction=>$lg, id=>$dm_dfl{$field_line}{value}})
      }

      my $input_type = "text";
      if($data_type eq "password")
      {
        $input_type = "password";
      }
      elsif($dm_dfl{$field_line}{frontend_hidden} == 1)
      {
      	$input_type = "hidden";
      }

      my $placeholder = "";
      if($d{placeholder_enable} eq "y")
      {
      	$placeholder = $dm_dfl{$field_line}{frontend_title}." ".$mandatory;
      }

      $field = <<"EOH";
        <input name="$field_name" id="$field_name" value="$field_value" class="form-control $required" $required type="$input_type" placeholder="$placeholder">
EOH
    
		
		if($dm_dfl{$field_line}{frontend_addonly} eq 'y' && $member{id} > 0)
		{
			 $field = <<"EOH";
        <input name="$field_name" disabled id="$field_name" value="$field_value" class="form-control disabled $required" $required type="$input_type">
EOH
		}
	
	}
    elsif($type eq "listboxtable" || $type eq "listbox")
    {
      my @lines;

      #  Récupération du contenu
      if($type eq "listboxtable")
      {
        @lines = sql_lines({
          debug  => 1,
          table  => $dm_dfl{$field_line}{lbtable},
          select => "$dm_dfl{$field_line}{lbkey} as value, $dm_dfl{$field_line}{lbdisplay} as display",
          where  => $dm_dfl{$field_line}{lbwhere},
          ordby  => $dm_dfl{$field_line}{lbordby},
        });
      }
      elsif($type eq "listbox")
      {
        foreach $key (sort keys %{$dm_dfl{$field_line}{fieldvalues}})
        {
          my %new_line = (
            value   => $key,
            display => $dm_dfl{$field_line}{fieldvalues}{$key},
          );

          push @lines, \%new_line;
        }
      }

      # Rendu du contenu
      my $content;
      my $i = 1;
      foreach my $line (@lines)
      {
        my %line = %{$line};

        if($dm_dfl{$field_line}{lbdisplay} eq "id_textid_name")
        {
        	$line{display} = get_traduction({id=>$line{display}, id_language=>$config{current_language}});
        }     

        if( $data_type eq 'button' )
        {
          my @splitted = split("/", $line{value});
          $line{value} = $splitted[1];

          my $active;
          my $check;
          if($dm_dfl{$field_line}{value} eq $line{value})
          {
            $active = "active";
            $check = "checked";
          }

          $content .= <<"EOH";
          <label class="btn btn-default $active">
            <input type="radio" name="$field_name" id="$field_name\_$i" autocomplete="off" value="$line{value}" $check>$line{display} $mandatory
          </label>
EOH

        }
        else
        {
          my $select;      
          if($dm_dfl{$field_line}{value} eq $line{value})
          {
            $select = "selected";
          }

          # Si aucune valeur, on fixe celle par défaut
          if($dm_dfl{$field_line}{key_default} eq $line{value} && $select eq "")
          {
          	$select = "selected";
          }

          $content .= <<"EOH";
            <option $select value="$line{value}">$line{display}</option>
EOH

        }
        $i++;
      }

  	  my $disabled = "";
  	  if($dm_dfl{$field_line}{frontend_addonly} eq 'y' && $member{id} > 0)
  		{
  		  $disabled = "disabled";
		  }
      if( $data_type eq 'button' )
      {
        $field = <<"EOH";
        <div class="btn-group" data-toggle="buttons">
          $content
        </div>
EOH
      }
      else
      {
        $field = <<"EOH";
        <select id="$field_name" $disabled name="$field_name" class="form-control $disabled $required" $required>
          $content
        </select>
EOH
      }

    
	
		#LISTBOX ou BOUTTONS --------------------------------------------------------------------------
    # ???? 
		  if($type eq "listboxtable" && ( $data_type eq 'btn-group' || $data_type eq 'button'))
		  {
  		  my %field_line_rec = %{$dm_dfl{$field_line}};
			  # see(\%field_line_rec);
			  ($field,$list_btns) = edit_lines_listboxes_member({debug=>0,translate=>$dm_dfl{$field_line}{translate},multiple=>$dm_dfl{$field_line}{multiple},list_btns=>1,class=>$select_class,default_value=>$txtvalue,rec=>\%rec,type=>$type,field_name=>$field_name,field_line=>\%field_line_rec,required_value=>$required_value,required_info=>$required_info});

			  $field =<<"EOH"
					<div class="multiple_$dm_dfl{$field_line}{multiple}">
						 $list_btns 
					</div>
					<div style="display:none;">
						<input type="hidden" name="$field_name" rel="$txtvalue" value="$rec{$field_name}" id="field_$field_name" class="field_$field_name form-control saveme saveme_txt $data_type_class" $required_value  placeholder="$dm_dfl{$field_line}{tip}" />
					</div>
EOH
		  }
	
	}
    elsif($type eq "display")
    {
      $field = <<"EOH";
       <p class="form-control-static">$line{display}</p>
EOH
    }
    elsif($type eq "password")
    {
      next;
    }

    my $class_label = $d{class_label} || "col-sm-4 control-label";
	
	my $legend = $dm_dfl{$field_line}{legend};
	if($legend ne "") {
		$legend = '<div class="legend"><span>'.$legend.'</span></div>';
	}

	if($dm_dfl{$field_line}{frontend_hidden} == 1)
	{
		 $form_content .= $field;
	}
	else
	{
    $form_content .= <<"EOH";
      <div class="form-group name-$field_name type-$type$data_type">
        <label class="$class_label">$dm_dfl{$field_line}{frontend_title} <span class="member_mandatory">$mandatory</span></label>
        <div class="$class_input_group">
          $field
        </div>
        $legend
      </div>
EOH
		
	}


  }

  return $form_content;
}

################################################################################
# edit_lines_listboxes_member
################################################################################
sub edit_lines_listboxes_member
{
   my %d = %{$_[0]};
   my $list_btns = '<div class="btn-group" role="group" aria-label="...">';
   if($d{debug})
   {
      see(\%d);
   }
   my %option_values = ();
   if($d{type} eq 'listbox')
   {
		%option_values = %{$dm_dfl{$d{field_line}}{fieldvalues}};
   }
   elsif($d{type} eq 'listboxtable' && $d{field_line}{lbtable} ne '' && $d{field_line}{lbkey} ne '' && $d{field_line}{lbdisplay} ne '')
   {
       $dbh_rec = $dm_cfg{dbh} || $dbh;
	   my $where_filtrer_non_valides = '';

	   if($d{field_line}{lbwhere} ne '')
	   {
			$d{field_line}{lbwhere} .= " AND migcms_deleted != 'y' ";
	   }
	   else
	   {
			$$d{field_line}{lbwhere} = " migcms_deleted != 'y' ";
	   }

	   if($config{filtrer_non_valides} == 1)
	   {
		   if($d{field_line}{lbwhere} ne '')
		   {
				$where_filtrer_non_valides = ' AND ';
		   }
		   $where_filtrer_non_valides .= " id NOT IN (select id_record from migcms_valides where nom_table='$d{field_line}{lbtable}')";
	   }
	   my $where_option_values = trim("$d{field_line}{lbwhere} $d{field_line}{frontend_lbwhere} $where_filtrer_non_valides");
       my $ordby = 'valeur';
	   if($d{field_line}{lbordby} ne '')
	   {
			$ordby = $d{field_line}{lbordby};
	   }
	   
	   my $nom_champs_data_split='id';
	   if($d{field_line}{data_split} ne '')
	   {
			$nom_champs_data_split = $d{field_line}{data_split};
			$ordby = $nom_champs_data_split.','.$d{field_line}{lbdisplay};
	   }
	   
	   my @option_values = sql_lines(
	   {
		   debug=>0,
		   debug_results=>0,
		   dbh=>$dbh_rec,
		   table=>$d{field_line}{lbtable},
		   select => "$d{field_line}{lbkey} as cle, $d{field_line}{lbdisplay} as valeur, $nom_champs_data_split as data_split",
		   where => $where_option_values,
		   ordby => $ordby,
       }
	   );
	   my $i=1;
	  
       foreach my $option_value (@option_values)
       {
          my %option_value = %{$option_value};
		   my $i_opt=$i+100000000;
		   $i++;
		  
          $option_values{$i_opt.'/'.$option_value{cle}.'/'.$option_value{data_split}} =  $option_value{valeur};
       }
   }
   else
   {
        print "Il manque des données:<br />type:[$d{type}]lbtable:[$d{field_line}{lbtable}]lbkey:[$d{field_line}{lbkey}]lbdisplay[$d{field_line}{lbdisplay}]field_line:[$d{field_line}]<br />$d{type}]<br />lbtable:[$dm_dfl{$d{field_line}}{lbtable}]<br />lbkey:[$dm_dfl{$d{field_line}}{lbkey}]<br />lbdisplay:[$dm_dfl{$d{field_line}}{lbdisplay}]"
   }

   $d{field_name} = trim($d{field_name});
   my $sel_value = $d{rec}{$d{field_name}} || $dm_dfl{$d{field_line}}{default_value} || $d{default_value};
   my $action = 'insert_'.$d{field_name};
   if($d{rec}{id} > 0)
   {
		$action = 'update_'.$d{field_name};
   }

   $special_class = 'migselect';

   $field = <<"EOH";
<select rel="$sel_value" id="field_$d{field_name}" $d{required_value}  $dm_dfl{$d{field_line}}{disabled} name="$d{field_name}" class="$d{class} saveme migcms_field_$action $special_class">
	<option value="">$sitetxt{veuillez_selectionner}</option>
EOH
        # see(\%option_values);
		my $new_split = $old_split = '';
		foreach my $option_id (sort keys %option_values)
        {
            if($option_id ne '')
            {
				my $selected = '';
                my $sel_class = "btn-default";
				my $option_value = $option_id;
				my $option_display = trim($option_values{$option_id});
				if($d{translate} == 1)
				{
					$option_display = get_traduction({debug=>0,id_language=>$colg,id=>$option_display});
				}
				my $option_default_value = get_quoted($d{field_name}) || $dm_dfl{$d{field_line}}{default_value};
				my $record_value = $d{rec}{$d{field_name}};

				my ($ordby,$option_value_id,$valeur_data_split) = split(/\//,$option_value);
				if
				(
					(
						 $record_value ne ''
						 &&
						 (
							 $option_value eq $record_value
							||
							$option_value_id eq $record_value
						 )
					)
					||
					(
						$option_default_value ne ''
						&&
						$record_value eq ''
						&&
						(
							$option_value eq $option_default_value
							||
							$option_value_id eq $option_default_value
						)
					)
				)
                {
                    $selected = ' selected="selected" ';
                    $sel_class = "btn-default active";
                }
                $field .= <<"EOH";
	<option value="$option_value" $selected>$option_display</option>
EOH
				if($d{list_btns})
                {
					 if($d{multiple})
                     {
						$sel_class = "btn-default";
						 if($d{debug})
						 {
							   print "------------------------------------ [$d{selected_only}]";
						 }
						 if($d{selected_only} == 1)
						 {
							$sel_class = " hide ";
						 }
                         my @sel_vals = split(/\,/,$d{rec}{$d{field_name}});
                         foreach my $sel_val (@sel_vals)
                         {
                              if($sel_val ne '' && $sel_val eq $option_value_id)
                              {
                                  $sel_class = " btn-info ";
                                  last;
                              }
                         }
                     }
                     my $label = $option_display;
                     if($label =~ m/\*/)
                     {
                        ($dum,$label) = split(/\*/,$label);
                     }
					 
					 if($d{from} eq 'list' && $dm_dfl{$d{field_line}}{translate} == 1)
					 {
					 	$label = get_traduction({debug=>0,id_language=>$colg,id=>$label});
					}
					
					if($valeur_data_split > 0)
					{
						$valeur_data_split = "";
					}
					$new_data_split = $valeur_data_split;
					
					#si on est en édition, si on a précisé une valeur de groupement et qu'on change de groupe
					if($d{disabled} ne 'disabled="disabled"' && $valeur_data_split ne '' && $old_data_split ne $new_data_split)
					{
						 if($old_data_split ne '')
						 {
							$list_btns .= "<br><br>";
						 }
						 $list_btns .=<<"EOH";
							<b class="valeur_tag">$valeur_data_split: </b><br>
EOH
						 
						 
					}
					
					if($d{disabled} eq 'disabled="disabled"')
					{
						$sel_class .=<<"EOH";
							btn-xs 
EOH
					}
					$old_data_split = $new_data_split;
					
                     $list_btns .=<<"EOH";
					
	<a class="btn $sel_class btn_change_listbox" $d{disabled} rel="field_$d{field_name}" id="$option_value_id">$label</a>
EOH
                }
            }
        }
    $field .= <<"EOH";
</select>
EOH
	  $list_btns .= '</div>';
	  return ($field,$list_btns);
}

################################################################################
# member_signup_fields
################################################################################
sub member_signup_fields
{
  my @champs;


  if($config{custom_signup_fields} eq "y")
  {
    @champs = @{def_handmade::get_custom_signup_fields()}; 
  }
  else
  {
    my %eshop_setup = %{eshop::get_setup()};

    # Si la boutique est activée, on ajoute le bouton de TVA intracom
    my $do_not_add_intracom = "n";
    if($eshop_setup{shop_disabled} eq "y")
    {
      $do_not_add_intracom = "y";
    }

    my $conditions_txt = $member_setup{id_textid_conditions};

    @champs = 
    (
      {
        name => 'delivery_firstname',
        label => $sitetxt{members_firstname},
        required => 'required',
      }
      ,
      {
        name => 'delivery_lastname',
        label => $sitetxt{members_lastname},
        required => 'required',
      }
      ,
      {
        name => 'delivery_company',
        label => $sitetxt{members_company},
      }
      ,
      {
        name => 'delivery_vat',
        label => $sitetxt{members_vat},
        hint => "($sitetxt{members_exemple}: BE123456789)",
      }
      ,
      {
        name => 'delivery_street',
        label => $sitetxt{members_street},
        required => 'required',
        class =>  'google_map_route',
      }
      ,
      {
        name => 'delivery_number',
        label => $sitetxt{members_number},
        class =>  'google_map_street_number',
        required => 'required',
      }
      ,
      {
        name => 'delivery_box',
        label => $sitetxt{members_box},
        class => '',
      }
      ,
      {
        name => 'delivery_zip',
        label => $sitetxt{members_zip},
        required => 'required',
        class =>  'google_map_postal_code',
      }
      ,
      {
        name => 'delivery_city',
        label => $sitetxt{members_city},
        required => 'required',
        class =>  'google_map_locality',
      }
      ,
      {
        name => 'delivery_country',
        type => 'countries_list',
        label => $sitetxt{members_country},
        required => 'required',
        class =>  'google_map_country',
      }
      ,
      {
        name => 'delivery_phone',
        label => $sitetxt{members_tel},
        required => 'required',
      }
      ,
      {
        name => 'email',
        type => 'email',
        label => $sitetxt{members_email},
        required => 'required',
      },
      {
        name => 'email2',
        type => 'email',
        label => $sitetxt{members_confirme_email},
        required => 'required',
      },
      {
        name => 'password',
        type => 'password',
        label => $sitetxt{members_password},
        required => 'required',
      },
      {
        name => 'password2',
        type => 'password',
        label => $sitetxt{members_confirme_password},
        required => 'required',
      },
      {
        name => 'do_intracom',
        type => 'checkbox',
        label => "$sitetxt{'members_do_intracom_label'} ( <i class='eshop_tooltip' data-toggle='tooltip' data-placement='right' data-placement='bottom' title='$sitetxt{members_do_intracom_txt}'>?</i> )",
        required => '',
        value => "y",
        do_not_add => $do_not_add_intracom,
      },
      {
        name => 'email_optin',
        type => 'checkbox',
        label => "$sitetxt{email_optin_label}",
        required => '',
        value => "y",
      },
      {
        name => 'conditions_ok',
        type => 'checkbox',
        label => "$conditions_txt",
        required => 'required',
        value => "y",
      },
    );
  }

  return \@champs;
}

################################################################################
# create_member_from_order
################################################################################  
sub create_member_from_order
{
  my %d = %{$_[0]};
  my %member_setup = %{member_get_setup({lg=>$lg})};

  my $tags = $d{tags} || get_quoted("tags");

  # Récupération de la commande
  my $eshop_token = get_quoted("token") || $d{token};
  my %order = sql_line({debug=>0,debug_results=>0,table=>"eshop_orders",where=>"token='$eshop_token'"});


    
  # Récupération de l'email et du mot de passe
  my $email = $order{billing_email};
  my $password = get_quoted('password') || create_token(20);






  my %existing_email_account = sql_line({table=>'migcms_members',where=>"email = '$order{billing_email}' AND email != '' "});


  if($email ne '' && $password ne '')
  {
    # Récupération des champs du membres
    my @champs_member = @{members::member_signup_fields()};



    my %new_member = ();
    foreach my $champ_member (@champs_member)
    {
      %champ_member = %{$champ_member};
      # Récup coordonnées de livraison
      $new_member{$champ_member{name}} = $order{$champ_member{name}} || "";
      $new_member{$champ_member{name}} =~ s/\'/\\\'/g;

      $champ_member{name} =~ s/delivery/billing/g;
      # Récup coordonnées de facturation
      $new_member{$champ_member{name}} = $order{$champ_member{name}} || "";
      $new_member{$champ_member{name}} =~ s/\'/\\\'/g;
    }

    my $token  = $token2 = create_token(20);
    my $stoken = sha1_hex($token);

    $new_member{email} = $email;
    ### Creation du token et cryptage du mot de passe ###
    $new_member{token}    = $new_member{token2} = $token;
    my $spassword         = sha1_hex($password);
    $new_member{password} = $spassword;
    $new_member{stoken}   = $stoken;

    # AJOUT DES TAGS
    # Pays + langue
    my %country = sql_line({dbh=>$dbh, table=>"countries", where=>"id = '$order{billing_country}'"});
    $new_member{tags} = $existing_email_account{tags};
    $new_member{tags} = ",".$lg.",".$country{id}.",";
    $new_member{tags} .= $tags;


    delete $new_member{email2};
    delete $new_member{password2};
    delete $new_member{do_intracom};

    if($order{same_identities} eq "y")
    {
      $new_member{are_same} = "y";
    }

    $new_member{email_optin} = "n";
    if($d{email_optin} eq "y" || get_quoted("email_optin") eq "y")
    {
      $new_member{email_optin} = "y";
    }

    $new_member{creation_time} = 'NOW()';

    if($d{commande_invite} eq "y")
	  {
	  	$new_member{password} = "";
	  }

    $new_member{actif} = $d{actif} || 'y'; 
    
    $new_member{delivery_email} = $order{delivery_email};
    $new_member{billing_email} = $order{billing_email};
      
    $new_member{id} = sql_set_data({dbh=>$dbh, table=>"migcms_members", where=>"email = '$new_member{email}'", data=>\%new_member});


      
    # if($new_member{id} > 0)
    # {

      # Actions supplémentaires concernant la boutique
      eshop::eshop_signup_member({member=>\%new_member});        
        
      my %update_order = 
      (
        id_member => $new_member{id}
      );

      updateh_db($dbh,"eshop_orders",\%update_order,'id',$order{id});

      # AUTOLOGIN && REDIRECTION
      # Si ce n'est pas une commande invité
      # Si on a activé l'autologin
      # Si ce n'est pas une inscription revendeur
      if($d{commande_invite} ne "y" && $member_setup{member_autologin_after_signup} eq "y" && $type ne "revendeur") 
      {
        my $url_after_login = "$config{fullurl}/cgi-bin/members.pl";
        if($member_setup{member_autologin_after_signup_url} ne '' && $type ne "revendeur") 
        {
          $url_after_login = $member_setup{member_autologin_after_signup_url}.'&lg='.$lg;
        }
        member_login_db({debug=>1,stoken=>$new_member{stoken}, url_after_login=>$url_after_login});
        exit;
      }
      # Si c'est une commande en tant qu'invité, on ne renvoie rien pour continuer le processus de commande
      elsif ($d{commande_invite} eq "y")
      {
      	return "";
      }

      ### Message de confirmation ###   
      $page =<<"EOH";     
        <div class="alert alert-success">
          <h1><span class="glyphicon glyphicon-ok" aria-hidden="true"></span> 
          $sitetxt{'members_signup_confirmation_display_title'}</h1>
          $sitetxt{'members_signup_confirmation_display_txt'}
        </div>
EOH
     
      # Affichage de la confirmation
      if(!($id_page >0))
      {
        $id_page = $member_setup{id_page};
      }

      my $page_html = migcrender::render_page({force_content=>$page,debug=>0,id=>$id_page,lg=>$lg});
      see();
      print $page_html;
      exit;   
    # } 

  }
  else
  {
    see();
    print "champs requis manquant";
    exit;
  }
}

################################################################################
# get_member_error_message
################################################################################
sub get_member_error_message
{
 my %d = %{$_[0]};


 my $error_msg = "";
 # GESTION DES MESSAGES D'ERREUR
  use Switch;
  switch ($d{error}) {
    # Un champ requis est manquant
    case 1 
    {
      $error_msg = <<"EOH";
<div class="alert alert-block alert-error alert-danger">
  <h1><span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span> $sitetxt{members_erreur_required_field_title}</h1>
  $sitetxt{members_erreur_required_field_txt}
</div>
EOH

    }
    # Les E-mails ne correspondent pas
    case 2
    {
      $error_msg = <<"EOH";
<div class="alert alert-block alert-error alert-danger">
  <h1><span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span> $sitetxt{members_erreur_email_match_title}</h1>
  $sitetxt{members_erreur_email_match_txt}
</div>
EOH
    }
    # Les mots de passes ne correspondent pas
    case 3
    {
      $error_msg = <<"EOH";
<div class="alert alert-block alert-error alert-danger">
  <h1><span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span> $sitetxt{members_erreur_password_match_title}</h1>
  $sitetxt{members_erreur_password_match_txt}
</div>
EOH
    }
    # Le membre existe déjà
    case 4
    {
      $error_msg = <<"EOH";
<div class="alert alert-block alert-error alert-danger">
  <h1><span class="glyphicon glyphicon-exclamation-sign" aria-hidden="true"></span> $sitetxt{'members_already_existes_title'}</h1>
  $sitetxt{'members_already_existes_txt'}
</div>
EOH
    }
    # Le member n'existe pas, est inactif ou le mot de passe est incorrect
    case 50
    {
      $error_msg = <<"EOH";
<div class="alert alert-block alert-error alert-danger">
  <p>$sitetxt{login_error_msg}</p>
</div>
EOH

    }
    else
    {}
  }


  return $error_msg;

}


sub after_save_create_token
{
	#create token for all members
    my @members = sql_lines({dbh=>$dbh, table=>"migcms_members", where=>"token = '' OR token2 = ''"});
	foreach $member (@members)
	{
		my %member = %{$member};
		if($member{token} eq "")
		{
			my $new_token = create_token(50);
			my $stmt = <<"SQL";
				UPDATE migcms_members
					SET token = '$new_token'
					WHERE id = '$member{id}'
SQL
			execstmt($dbh, $stmt);
		}
		if($member{token2} eq "")
		{
			my $new_token = create_token(50);
			my $stmt = <<"SQL";
				UPDATE migcms_members
					SET token2 = '$new_token'
					WHERE id = '$member{id}'
SQL
			execstmt($dbh, $stmt);
		}
	}
	
	#create stoken for all members
    my @members = sql_lines({dbh=>$dbh, table=>"migcms_members", where=>"stoken = '' AND token != ''"});
	foreach $member (@members)
	{
		my %member = %{$member};
		if($member{stoken} eq "")
		{
			my $stoken = sha1_hex($member{token});
			my $stmt = <<"SQL";
				UPDATE migcms_members
					SET stoken = '$stoken'
					WHERE id = '$member{id}'
SQL
			execstmt($dbh, $stmt);
		}
	}
}

################################################################################
# get_buttons_social_medias
################################################################################
sub get_buttons_social_medias
{
	my $button_google;
	my $button_facebook;
	my $script;
	
	# Si les réseaux sociaux sont activés
	if($member_setup{enable_social_medias} eq "y")
	{
		### SCRIPT JS ###
		$script = get_script_social_medias();

		### FACEBOOK ###
		$button_facebook = get_button_social_facebook();

		### GOOGLE ###		
		$button_google = get_button_social_google();		
	}

	my $content = <<"EOH";
		<div class="col-sm-12">
			<div class="social-container">
				$script
				$button_facebook
				$button_google
			</div>
		</div>
EOH

	return $content;
}

sub get_button_social_facebook
{
	my $button;
	if($member_setup{enable_social_facebook} eq "y")
	{
		$button = <<"EOH";
			<a class="connect connect-facebook" href="#">Se connecter avec facebook</a>
EOH
	}

	return $button;
}

sub get_button_social_google
{
	my $button;
	if($member_setup{enable_social_google} eq "y")
	{
		$button = <<"EOH";
			<a class="connect connect-google" href="#">Se connecter avec facebook</a>
EOH
	}

	return $button;
}

sub get_script_social_medias
{
	my $code_google = $member_setup{social_google_code};
	my $code_facebook = $member_setup{social_facebook_code};
	my $baseurl = $config{baseurl};

	my $script = <<"HTML";
		<script>
			// CONFIG GLOBALE
			var apps_config = {
			  "google-clientID" :  "$code_google",
			  "facebook-appID"  :  "$code_facebook",
			};

			// GOOGLE + 
			(function() {
			var po = document.createElement('script'); po.type = 'text/javascript'; po.async = true;
			po.src = 'https://apis.google.com/js/client:plusone.js?onload=init_google_behavior';
			var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(po, s);
			})();
			
			function init_google_behavior()
			{
				jQuery(".connect-google").click(function(){
			    gapi.auth.signIn(
			      {
			        'clientid' : apps_config["google-clientID"],
			        'cookiepolicy' : 'single_host_origin',
			        'callback' : 'google_signinCallback',
			        'requestvisibleactions': 'http://schemas.google.com/AddActivity',
			        // 'scope': 'https://www.googleapis.com/auth/plus.login https://www.googleapis.com/auth/userinfo.email',
			      }
			    ) 
			    return false;
				});
			}

			function connexion(infos) 
			{  
			  var social_id        = infos["id"];
			  var social_token     = infos["token"];
			  var social_email     = infos["email"];
			  var social_lastname  = infos["lastname"];
			  var social_firstname = infos["firstname"];
			  var social_city      = infos["city"];
			  var social_country   = infos["country"];
			  var social_birthdate = infos["birthdate"];
			  var social_type      = infos["type"];


			  var request = jQuery.ajax(
			  {
			      url: $baseurl+'/cgi-bin/members.pl?lg='+$lg,
			      type: "POST",
			      data: 
			      {
			        sw : 'login_or_signup_social_media',
			        social_id : social_id,
			        social_token : social_token,
			        social_email: social_email,
			        social_lastname: social_lastname,
			        social_firstname: social_firstname,
			        social_city: social_city,
			        social_country: social_country,
			        social_birthdate: social_birthdate,
			        social_type: social_type,       
			      },
			      dataType: "html"
			  });

			  request.done(function(msg) 
			  {
			    // On récupère l'url de redirection
			    // var link = $(".newaccount-form a").attr("href");
			    // window.location = link;
			  });
			  request.fail(function(jqXHR, textStatus) 
			  {
			      
			  });
			}

			// FONCTION CALLBACK APRES AUTHENTIFICATION GOOGLE+
			function google_signinCallback(authResult) 
			{
				if (authResult['access_token']) {

				gapi.client.load('oauth2', 'v2', function()
				{
				  gapi.client.oauth2.userinfo.get()
				    .execute(function(resp)
				    {
				      // Shows user email
				      // console.log(resp);
				      var lastname  = typeof resp.family_name != "undefined" ? resp.family_name : "";
				      var firstname = typeof resp.given_name != "undefined" ? resp.given_name : "";
				      var email     = typeof resp.email != "undefined" ? resp.email : "";
				      var token     = authResult.access_token;
				      var id        = typeof resp.id != "undefined" ? resp.id : "";

				      var infos = {
				        "lastname"      :  lastname,
				        "firstname"     :  firstname,
				        "email"         :  email,
				        "token"         : token,
				        "id"            : id,
				        "type"          : "google_signup",
				      }

				      connexion(infos);         
				    });
				});

				} 
				else if (authResult['error']) 
				{
				// Une erreur s'est produite.
				// Codes d'erreur possibles :
				//   "access_denied" - L'utilisateur a refusé l'accès à votre application
				//   "immediate_failed" - La connexion automatique de l'utilisateur a échoué
				// console.log('Une erreur s'est produite : ' + authResult['error']);
				}
			}
		</script>
HTML
}

sub get_member_backend_identities_form
{
	my %d = %{$_[0]};

	my %identity = %{$d{identity}};
	my $type = $d{type};

	my @fields = @{eshop::get_identities_fields({valeurs=>\%identity})};

	my $fields_group;
	
	foreach $field (@fields)
	{
		my %field = %{$field};
		# see(\%field);
		# exit;
		my $field_html;
		$field{custom_name} = "identity_".$type."_".$field{name};

		if($field{type} eq '')
		{
			$field{type} = 'text';
		}

		#construction formulaire-------------------------------------------------------------
    if($field{type} eq 'text' || $field{type} eq 'email')
    {
			$fields_html = << "HTML";				
			<input autocomplete="off" name="$type_$field{custom_name}" value="$field{valeurs}{$field{name}}" id="field_$type_$field{custom_name}" class="clear_field form-control saveme saveme_txt " placeholder="" type="text"><span class="add-clear-x form-control-feedback fa fa-times" style="display: none; color: rgb(204, 204, 204); cursor: pointer; text-decoration: none; overflow: hidden; position: absolute; pointer-events: auto; right: 0px; top: 0px;"></span>			
HTML
			
    }
    elsif($field{type} eq "countries_list")
    {
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
		
			my $country = $field{valeurs}{$field{name}};
			if(!($country > 0))
			{
				$country = $setup{cart_default_id_country};
			}

    	my $listbox_countries = sql_listbox(
       {
          dbh       =>  $dbh,
          name      => $field{custom_name},
          select    => "c.id,$col",
          table     => 'shop_delcost_countries dc, countries c',
          where     => 'dc.isocode=c.iso',
          ordby     => $col,
          show_empty=> 'y',
          empty_txt =>  $sitetxt{eshop_veuillez},
          value     => 'id',
          current_value     => $country,
          display    => $col,
          required => '',
          id       => '',
          class    => 'input-xlarge form-control saveme saveme_txt',
          debug    => 0,
       }
      );

      $fields_html = $listbox_countries;
    }

    $fields_group .= << "HTML";
			<div class="form-group item  row_edit_$field{custom_name}  migcms_group_data_type_ hidden_">
			 	<label for="field_$field{custom_name}" class="col-sm-2 control-label ">$field{label}</label>
	   		<div class="col-sm-10 mig_cms_value_col">
		   		<div class="add-clear-span has-feedback">
						$fields_html						
					</div>
					<span class="help-block text-left"></span>
			 	</div>
			</div>
HTML
	}

	my $content = <<"HTML";
		$fields_group
HTML

	return $content;
}


1;