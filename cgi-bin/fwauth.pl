#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;     # standard package for easy CGI scripting
use DBI;     # standard package for Database access
use def;     # definitions & configurations
use tools;   # handy tools
use JSON;
use JSON::XS;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);

my %securite_setup = sql_line({table=>'securite_setup'});

$self = $config{baseurl}."/cgi-bin/fwauth.pl?";

# call the correct function
$sw = $cgi->param('sw') || "login_form";

my @switches = qw(
login_form
login_db
logout
);



if (is_in(@switches,$sw)) { &$sw(); }      

#==============================================================================

sub lock_form
{
    #see();
	my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
	if($migcms_setup{site_name} eq '')
	{
		$migcms_setup{site_name} = 'Bugiweb';
	}
	my $token = $_[0];
	my $env = "$ENV{REMOTE_ADDR} $ENV{HTTP_USER_AGENT}";
	
 my $where_env = " AND env = '$env' ";
		if($securite_setup{disable_env} eq 'y')
		{
			$where_env = " ";
		}		
	
    my %user = sql_line({debug=>0,debug_results=>0,table=>"users",select=>'*',where=>"token='$token' $where_env and visible='y'"});

    if(!($user{id}>0))
    {
				
		$hash_order{token} = '';
		my $order_utf8_encoded_json_text = encode_json \%hash_order;
		my $cook = $cgi->cookie(-name=>$config{migc4_cookie}.'_lock',-value=>$order_utf8_encoded_json_text2,-path=>'/');
		print $cgi->header(-cookie=>[$cook],-charset => 'utf-8');
	
        cgi_redirect($self);
	
        exit;
    }

    my $script_google_auth = get_script_google_auth();

 see();
    print <<"EOH";
<!DOCTYPE html>
<html lang="fr">
<head>

    <meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
	<meta name="robots" content="noindex, nofollow">
    <meta name="author" content="Bugiweb.com">
    
	<link rel="apple-touch-icon" sizes="57x57" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-57x57.png">
	<link rel="apple-touch-icon" sizes="60x60" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-60x60.png">
	<link rel="apple-touch-icon" sizes="72x72" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-72x72.png">
	<link rel="apple-touch-icon" sizes="76x76" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-76x76.png">
	<link rel="apple-touch-icon" sizes="114x114" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-114x114.png">
	<link rel="apple-touch-icon" sizes="120x120" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-120x120.png">
	<link rel="apple-touch-icon" sizes="144x144" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-144x144.png">
	<link rel="apple-touch-icon" sizes="152x152" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-152x152.png">
	<link rel="apple-touch-icon" sizes="180x180" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-180x180.png">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-32x32.png" sizes="32x32">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-194x194.png" sizes="194x194">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-96x96.png" sizes="96x96">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/android-chrome-192x192.png" sizes="192x192">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-16x16.png" sizes="16x16">
	<link rel="manifest" href="$config{baseurl}/mig_skin/ico/manifest.json">
	<meta name="msapplication-TileColor" content="#ffffff">
	<meta name="msapplication-TileImage" content="$config{baseurl}/mig_skin/ico/mstile-144x144.png">
	<meta name="theme-color" content="#ffffff">
	<meta name="application-name" content="$migcms_setup{site_name}">

    <title>$migcms_setup{site_name} - Compte verrouillé</title>
    
	<link href="$config{baseurl}/mig_skin/css/font-awesome.min.css" rel="stylesheet">
    <link href="$config{baseurl}/html/css/style.css" rel="stylesheet">
    <link href="$config{baseurl}/html/css/style-responsive.css" rel="stylesheet">

    <!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
    <script src="$config{baseurl}/html/js/html5shiv.js"></script>
    <script src="$config{baseurl}/html/js/respond.min.js"></script>
    <![endif]-->
</head>

<body class="lock-screen">
<div class="se-pre-con"></div>

    <div class="lock-wrapper">
        <div class="panel lock-box text-center">
            <img alt="lock avatar" src="$config{baseurl}/html/images/photos/user1.png">
            <div class="locked">
                <i class="fa fa-lock"></i>
            </div>
            <h1>Session verouillée <span>$user{firstname} $user{lastname}</span></h1>
            <div class="row">
                <form action="$self" class="form-inline clearfix" method="post">
                        <input type="hidden" name="sw" value="login_db" />
						<input type="hidden" name="lg" value="1" />
                        <input type="hidden" name="email" value="$user{email}" />
                        <input type="hidden" name="type_form" value="locked_form" />
            
                    <div class="form-group col-md-12 col-sm-12 col-xs-12 clearfix">
					    <input type="password" name="password" class="form-control lock-input" placeholder="Mot de passe" required autofocus >
                        <button type="submit" class="btn btn-lock pull-left"><i class="fa fa-check"></i></button>
						<a class="btn btn-google pull-right" href="#"><i class="fa fa-google"></i></a>
						<div class="error_message"></div>
                    </div>
                </form>
            </div>
             
        </div> 
        <div class="panel">
              <a href="$self&sw=logout&all=y" class="btn btn-block btn-link">Changer d'utilisateur</a>
        </div>
    </div>

<!-- Placed js at the end of the document so the pages load faster -->
<script src="$config{baseurl}/html/js/jquery-1.10.2.min.js"></script>
<script src="$config{baseurl}/html/js/bootstrap.min.js"></script>
<script src="$config{baseurl}/html/js/modernizr.min.js"></script>
$script_google_auth

</body>
</html>
 
EOH
exit;

}

###############################################################################
# LOGIN_FORM
###############################################################################

sub login_form
{
 	 my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
	 if($migcms_setup{site_name} eq '')
	 {
		$migcms_setup{site_name} = 'Bugiweb';
	 }
	 
	 my $cookie_order = $cgi->cookie($config{migc4_cookie});
	 my $cookie_order2 = $cgi->cookie($config{migc4_cookie}.'_lock');
	 my %login_data = ();
	 my %lock_data = ();
	 
	 if($cookie_order ne "")
	 {
			$cookie_order_ref = decode_json $cookie_order;
			%login_data=%{$cookie_order_ref};
	 }
	 if($cookie_order2 ne "")
	 {
			$cookie_order_ref = decode_json $cookie_order2;
			%lock_data=%{$cookie_order_ref};
	 }
	 
	 my $env = "$ENV{REMOTE_ADDR} $ENV{HTTP_USER_AGENT}";
	 
	 my $where_env = " AND env = '$env' ";
		if($securite_setup{disable_env} eq 'y')
		{
			$where_env = " ";
		}
	 
	 #si on est deja connecte: on est connecte automatiquement
 	 my %check_token_login = sql_line({debug=>0,debug_results=>0,table=>'users',where=>"token='$login_data{token}' $where_env and visible='y'"});
	 if($login_data{token} ne '' && $env ne '' && $check_token_login{id} > 0 && $check_token_login{token} ne '')
	 {
		log_debug('login db token');
		login_db($check_token_login{token}, "autologin_form");			
		exit;
	 }
	 
	 #si on n'est pas connecte mais verrouille, on affiche le lock form
     my %check_token_lock = sql_line({debug=>0,debug_results=>0,table=>'users',where=>"token='$lock_data{token}' $where_env and visible='y'"});
	 if($lock_data{token} ne '' && $check_token_lock{id} > 0 && $check_token_lock{token} ne '')
	 {
		log_debug('lock form token');
		lock_form($check_token_lock{token});
		exit;
	 }
	
 
     #si on est pas connecte et qu'on n'a pas de lock form, on affiche le formulaire de login

	my %logo_big = sql_line({table=>'migcms_linked_files',where=>"table_name='migcms_setup'",limit=>'0,1',ordby=>'ordby'});
	my %logo_small = sql_line({table=>'migcms_linked_files',where=>"table_name='migcms_setup'",limit=>'1,1',ordby=>'ordby'});
	my $url_logo_big = "$config{baseurl}/mig_skin/img/logo.svg";
	my $url_logo_small = "$config{baseurl}/mig_skin/img/logo-small.svg";
	if($logo_big{file} ne '' && $logo_big{file_dir} ne '')
	{
		$url_logo_big = $logo_big{file_dir}.'/'.$logo_big{full}.$logo_big{ext};
	}
	if($logo_small{file} ne '' && $logo_small{file_dir} ne '')
	{
		$url_logo_small = $logo_small{file_dir}.'/'.$logo_small{full}.$logo_small{ext};
	}

    my $captcha_public_key = $config{captcha_public_key} || "6LebNAATAAAAAPCtNCI_GeyRA8n7W1LnL6LqiSL3";

    my $script_google_auth = get_script_google_auth();
	
	see();
   my $page = <<"EOH";
<!DOCTYPE html>
<html lang="fr">
<head>

    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
	<meta name="robots" content="noindex, nofollow">
    <meta name="author" content="Bugiweb.com">
    
	<link rel="apple-touch-icon" sizes="57x57" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-57x57.png">
	<link rel="apple-touch-icon" sizes="60x60" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-60x60.png">
	<link rel="apple-touch-icon" sizes="72x72" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-72x72.png">
	<link rel="apple-touch-icon" sizes="76x76" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-76x76.png">
	<link rel="apple-touch-icon" sizes="114x114" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-114x114.png">
	<link rel="apple-touch-icon" sizes="120x120" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-120x120.png">
	<link rel="apple-touch-icon" sizes="144x144" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-144x144.png">
	<link rel="apple-touch-icon" sizes="152x152" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-152x152.png">
	<link rel="apple-touch-icon" sizes="180x180" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-180x180.png">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-32x32.png" sizes="32x32">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-194x194.png" sizes="194x194">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-96x96.png" sizes="96x96">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/android-chrome-192x192.png" sizes="192x192">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-16x16.png" sizes="16x16">
	<link rel="manifest" href="$config{baseurl}/mig_skin/ico/manifest.json">
	<meta name="msapplication-TileColor" content="#ffffff">
	<meta name="msapplication-TileImage" content="$config{baseurl}/mig_skin/ico/mstile-144x144.png">
	<meta name="theme-color" content="#ffffff">
	<meta name="application-name" content="$migcms_setup{site_name}">	

    <title>$migcms_setup{site_name} - Zone sécurisée</title>
    
	<link href="$config{baseurl}/mig_skin/css/font-awesome.min.css" rel="stylesheet">
    <link href="$config{baseurl}/html/css/style.css" rel="stylesheet">
    <link href="$config{baseurl}/html/css/style-responsive.css" rel="stylesheet">

    <!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
    <script src="$config{baseurl}/html/js/html5shiv.js"></script>
    <script src="$config{baseurl}/html/js/respond.min.js"></script>
    <![endif]-->
</head>

<body class="login-body">
<div class="se-pre-con"></div>

<div class="login-content">
	<h1 class="sign-title">Zone sécurisée</h1>
    <form action="$self" class="form-signin" method="post">
		<input type="hidden" name="sw" value="login_db" />
		<input type="hidden" name="lg" value="1" />
        <div class="form-signin-heading text-center">
            <img src="$url_logo_big" />
        </div>
        <div class="login-wrap">		
			<div class="input-group">
				<span class="input-group-addon"><i class="fa fa-user"></i></span>
				<input type="email" name="email" class="form-control" placeholder="Email" autofocus required>
			</div>
			
			<div class="input-group">
				<span class="input-group-addon"><i class="fa fa-key"></i></span>
				<input type="password" name="password" class="form-control" placeholder="Mot de passe" required>
			</div>
EOH

if($securite_setup{disable_google_captcha} ne 'y')
{
	$page .= <<"EOH";
            <div class="input-group">
                <div class="g-recaptcha" data-sitekey="$captcha_public_key" ></div>
                <script src="https://www.google.com/recaptcha/api.js?hl=fr"></script>
            </div>
EOH
}

	$page .= <<"HTML";
            <button class="btn btn-lg btn-login btn-block pull-left" type="submit">
                <i class="fa fa-check"></i>
            </button>
			<a class="btn btn-lg btn-google btn-block pull-right" href="#"><i class="fa fa-google"></i></a>
	        <div class="error_message"></div>

            <!--<label class="checkbox">
                <input type="checkbox" name="remember_me" value="y"> Rester connecté (sur votre ordinateur privé)
            </label>-->

        </div>

    </form>

</div>




<!-- Placed js at the end of the document so the pages load faster -->
<script src="$config{baseurl}/html/js/jquery-1.10.2.min.js"></script>
<script src="$config{baseurl}/html/js/bootstrap.min.js"></script>
<script src="$config{baseurl}/html/js/modernizr.min.js"></script>

$script_google_auth



</body>
</html>
HTML

print $page;
}


###############################################################################
# LOGIN_DB
###############################################################################
sub login_db
{
    my $type_form = $_[1] || get_quoted("type_form") || '';
    my $type = get_quoted("type");

    my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});

    if($type eq "social")
    {
      ###############################
      ### AUTHENTIFICATION GOOGLE ###
      ###############################      
      my $social_id = get_quoted("social_id");
		  my $social_token = get_quoted("social_token");
		  my $social_email = get_quoted("social_email");

		  my %response; 

		  if($social_id eq "" || $social_token eq "" || social_email eq "")
		  { 
		    %response = (
		      status => "ko",
		      message => "Une ou plusieurs informations fournies par Google sont manquantes",
		    );
		    see();
		    print JSON->new->utf8(0)->encode(\%response);
		    exit; 
		  }

		  # On récupère un user
  		my %user = sql_line({dbh=>$dbh,table=>'users',where=>"social_id='$social_id' && google_linked = 'y'"});

  		if($user{id} > 0)
  		{
  			# On met à jour le token du user
  			my %update_user = (
		      social_token => $social_token,
		    );
		    sql_set_data({dbh=>$dbh, table=>"users", where=>"id = $user{id}", data=>\%update_user});

		    my $env = "$ENV{REMOTE_ADDR} $ENV{HTTP_USER_AGENT}"; 

		    my %hash_order = ();
			my $cookie_order = $cgi->cookie($config{migc4_cookie});
			if($cookie_order ne "")
			{
				  $cookie_order_ref = decode_json $cookie_order;
				  %hash_order=%{$cookie_order_ref};
			}
			my $token = create_token(100); 
			$hash_order{token} = $token;
			$hash_order{social_connect} = "y";
			
			#write updated cookie
			$order_utf8_encoded_json_text = encode_json \%hash_order;
			my $exp = "";
			if($remember_me eq 'y')
			{
				$exp = "+30d";
			}
			my $cook = $cgi->cookie(-name=>$config{migc4_cookie},-value=>$order_utf8_encoded_json_text,-path=>'/',-expires=>$exp);
			
			
			my %hash_order2 = ();
			my $cookie_order2 = $cgi->cookie($config{migc4_cookie}.'_lock');
			if($cookie_order2 ne "")
			{
				  $cookie_order_ref2 = decode_json $cookie_order2;
				  %hash_order2=%{$cookie_order_ref2};
			}
			$hash_order{token} = $token;
			$hash_order2{token} = $token;
			$order_utf8_encoded_json_text2 = encode_json \%hash_order2;
			
			my $exp = "";
			if($remember_me eq 'y')
			{
				$exp = "+30d";
			}
			my $cook = $cgi->cookie(-name=>$config{migc4_cookie},-value=>$order_utf8_encoded_json_text,-path=>'/',-expires=>$exp);
			my $cook2 = $cgi->cookie(-name=>$config{migc4_cookie}.'_lock',-value=>$order_utf8_encoded_json_text2,-path=>'/',-expires=>"+30d");
			print $cgi->header(-cookie=>[$cook,$cook2],-charset => 'utf-8');
			# print $cgi->header(-cookie=>[$cook],-charset => 'utf-8');
			
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);	
			my $moment =  sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec); #Formatage du temps dans une chaine de caractÃÂÃÂres
							
			$stmt = "UPDATE users SET token = '$token', env = '$env', last_login = '$moment' WHERE id = '$user{id}'";
			$cursor = $dbh->prepare($stmt);
			$cursor->execute || suicide($stmt);
			
			my $url = '$config{baseurl}/cgi-bin/adm_dashboard.pl?sel=106';

			if($migcms_setup{admin_first_page_url} ne '')
			{
				$url = $config{baseurl}.'/cgi-bin/'.$migcms_setup{admin_first_page_url};
			}
				
			if($user{first_page_url} ne '')
			{
				$url = $config{baseurl}.'/cgi-bin/'.$user{first_page_url};
			}
				
			add_history({action=>'Google connecte',id_user=>"$user{id}"});
			
			%response = (
				status => "ok",
			url => $url,
			);
			print JSON->new->utf8(0)->encode(\%response);
			exit; 
				
  		} 
  		else
  		{
  			add_history({action=>'erreur connexion google : $social_email'});
	   		%response = (
		      status => "ko",
		      message => "Ce compte Google n'est pas autorisé à se connecter",
		    );
		    see();
		    print JSON->new->utf8(0)->encode(\%response);
		    exit; 
  		}
  		exit;
      
      ###############################
    }

    if($securite_setup{disable_google_captcha} ne 'y' && $type_form ne "locked_form" && $type_form ne "autologin_form")
    {
        #####################################
        ### Vérification Recaptcha Google ###
        #####################################
        my $secret_key = $config{captcha_secret_key} || "6LebNAATAAAAABrhItqdIIU_Gt3DPMtUYVrPivSv";
        my $i_am_human = tools::is_human_recaptcha({g_recaptcha_response=>get_quoted("g-recaptcha-response"), secret_key=>$secret_key});

        # Affichage d'une erreur si pas Humain
        if($i_am_human ne "y")
        {
           my $alert = tools::get_alert({type=>"error",display=>'sweet',title=>"Attention", message=>"Veuillez cocher la case \"Je ne suis pas un robot\""});		   
           see();
           print $alert;
           exit;
        }
        #####################################
    }

  ##################################
  ### AUTHENTIFICATION CLASSIQUE ###
  ##################################     
	
	my %hash_order = ();
	my $cookie_order = $cgi->cookie($config{migc4_cookie});
	if($cookie_order ne "")
	{
		  $cookie_order_ref = decode_json $cookie_order;
		  %hash_order=%{$cookie_order_ref};
	}

	my $token = '';
    my $token_autologin = $_[0];
	my $autologin = $_[1];
	my $token_cookie = $hash_order{token};
	
	if($token_autologin eq $token_cookie) {
		$token = $token_autologin;
	}
	
		
	my $env = "$ENV{REMOTE_ADDR} $ENV{HTTP_USER_AGENT}"; 
	
 my $where_env = " AND env = '$env' ";
		if($securite_setup{disable_env} eq 'y')
		{
			$where_env = " ";
		}	
	
    my %user = sql_line({debug=>0,debug_results=>0,table=>"users",where=>"token='$token' $where_env and token != '' and visible='y'"});


    my $email = get_quoted('email') || '';
    my $password = sha1_hex(get_quoted('password')) || '';
    if ($config{auth_dont_crypt} eq "y") {
        $password = get_quoted('password') || '';
    }
	# my $passwordnocrypt = get_quoted('password') || '';
    my $remember_me = get_quoted('remember_me') || 'n';
	
	
	 my %user_email = sql_line({debug=>0,table=>"users",where=>"LOWER(email) = LOWER('$email')"});
	 my %count_tentatives = sql_line({debug=>0,select=>"COUNT(*) as nb",table=>"migcms_history",select=>'COUNT(*) as nb',where=>"date = DATE(NOW()) AND action='erreur connexion' AND id_user='$user_email{id}'"});
	 if($count_tentatives{nb} > 25)
	 {
		add_history({action=>'erreur connexion',id_user=>"$user_email{id}"});
		my $alert = tools::get_alert({type=>"error",display=>'sweet',title=>"Attention", message=>"Trop de tentatives de connexion ce jour. Le compte a été bloqué temporairement."});
		see();
		print $alert;
		exit;
	 }
	
		
	if($email ne '' && $password ne '' && !($user{id} > 0))
	{
		%user = sql_line({debug=>0,table=>"users",where=>"LOWER(email) = LOWER('$email') AND LOWER(password) = LOWER('$password')"});
	}
	
	if($user{id} > 0)
    {	
	    if($autologin eq 'autologin_form')
	    {	
				if($migcms_setup{admin_first_page_url} ne '')
				{
					$url = $config{baseurl}.'/cgi-bin/'.$migcms_setup{admin_first_page_url};
				}
					
				if($user{first_page_url} ne '')
				{
					$url = $config{baseurl}.'/cgi-bin/'.$user{first_page_url};
				}
				
			add_history({action=>'auto connecte',id_user=>"$user{id}"});
			
			see();			
			http_redirect($url);
			exit;
	    }
	    elsif($email ne '' && $password ne '' && $user{id} > 0)
	    {		
		
			my %hash_order = ();
			my $cookie_order = $cgi->cookie($config{migc4_cookie});
			if($cookie_order ne "")
			{
				  $cookie_order_ref = decode_json $cookie_order;
				  %hash_order=%{$cookie_order_ref};
			}
			my $token = create_token(100); 
			$hash_order{token} = $token;
			
			#write updated cookie
			$order_utf8_encoded_json_text = encode_json \%hash_order;
			my $exp = "";
			if($remember_me eq 'y')
			{
				$exp = "+30d";
			}
			my $cook = $cgi->cookie(-name=>$config{migc4_cookie},-value=>$order_utf8_encoded_json_text,-path=>'/',-expires=>$exp);
			
			
			my %hash_order2 = ();
			my $cookie_order2 = $cgi->cookie($config{migc4_cookie}.'_lock');
			if($cookie_order2 ne "")
			{
				  $cookie_order_ref2 = decode_json $cookie_order2;
				  %hash_order2=%{$cookie_order_ref2};
			}
			$hash_order{token} = $token;
			$hash_order2{token} = $token;
			$order_utf8_encoded_json_text2 = encode_json \%hash_order2;
			
			my $exp = "";
			if($remember_me eq 'y')
			{
				$exp = "+30d";
			}
			my $cook = $cgi->cookie(-name=>$config{migc4_cookie},-value=>$order_utf8_encoded_json_text,-path=>'/',-expires=>$exp);
			my $cook2 = $cgi->cookie(-name=>$config{migc4_cookie}.'_lock',-value=>$order_utf8_encoded_json_text2,-path=>'/',-expires=>"+30d");
			print $cgi->header(-cookie=>[$cook,$cook2],-charset => 'utf-8');
			# print $cgi->header(-cookie=>[$cook],-charset => 'utf-8');
			
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);	
			my $moment =  sprintf("%04d-%02d-%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec); #Formatage du temps dans une chaine de caractÃÂÃÂres
							
			$stmt = "UPDATE users SET token = '$token', env = '$env', last_login = '$moment' WHERE id = '$user{id}'";
			$cursor = $dbh->prepare($stmt);
			$cursor->execute || suicide($stmt);
			
			my $url = '$config{baseurl}/cgi-bin/adm_dashboard.pl?sel=106';
			
			if($migcms_setup{admin_first_page_url} ne '')
			{
				$url = $config{baseurl}.'/cgi-bin/'.$migcms_setup{admin_first_page_url};
			}
			
			if($user{first_page_url} ne '')
			{
				$url = $config{baseurl}.'/cgi-bin/'.$user{first_page_url};
			}
							
			add_history({action=>'se connecte',id_user=>"$user{id}"});
			
			http_redirect($url);   
	    }
	    else
	    {
		    add_history({action=>'erreur connexion',id_user=>"$user{id}"});
		    my $alert = tools::get_alert({type=>"error",display=>'sweet',title=>"Attention", message=>"Mot de passe incorrect"});
		   
			my $ip = $ENV{REMOTE_ADDR};
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);	
			my $moment =  sprintf("[%04d-%02d-%02d:%02d:%02d:%02d]",$year+1900,$mon+1,$mday,$hour,$min,$sec); 
			my $out_file = "../syslogs/auth_error.log";
			my $msg = "erreur connexion";
			my $out_log = "$moment		[$ip]		[$email/$password]		Error:$msg\n";
			open OUTPAGE, ">>$out_file";
			print OUTPAGE $out_log;
			close (OUTPAGE);
		   
		    see();
		    print $alert;
		    exit;
        }
    }
    else
    {
	   my %user_email = sql_line({debug=>0,table=>"users",select=>'id,token',where=>"LOWER(email) = LOWER('$email')"});
	   add_history({action=>'erreur connexion',id_user=>"$user_email{id}"});
	   my $alert = tools::get_alert({type=>"error",display=>'sweet',title=>"Attention", message=>"Mot de passe incorrect"});
	    
		my $ip = $ENV{REMOTE_ADDR};
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);	
		my $moment =  sprintf("[%04d-%02d-%02d:%02d:%02d:%02d]",$year+1900,$mon+1,$mday,$hour,$min,$sec); 
		my $out_file = "../syslogs/auth_error.log";
		my $msg = "erreur connexion";
		my $out_log = "$moment		[$ip]		[$email/$password]		Error:$msg\n";
		open OUTPAGE, ">>$out_file";
		print OUTPAGE $out_log;
		close (OUTPAGE);
	   
	   see();
	   print $alert;
	   exit;
    }
}

#-------------------------------------------------------------------------------
# GENERATE_TOKEN
#-------------------------------------------------------------------------------

sub generate_token
{
	my $length_of_randomstring=shift;# the length of 
	#the random string to generate

	my @chars=('a'..'z','A'..'Z','0'..'9');
	my $random_string;
	foreach (1..$length_of_randomstring) 
	{
		# rand @chars will generate a random 
		# number between 0 and scalar @chars
		$random_string.=$chars[rand @chars];
	}
	return $random_string;
}

###############################################################################
# LOGOUT
###############################################################################

sub logout
{
   my $all = get_quoted('all');
   if($all eq 'y')
   {
       my $cookie = $cgi->cookie(-name=>$config{migc4_cookie},-value=>"",-path=>'/',-expires=>'-1d');
       my $cookie2 = $cgi->cookie(-name=>$config{migc4_cookie}.'_lock',-value=>"",-path=>'/',-expires=>'-1d');
       print $cgi->header(-cookie=>[$cookie,$cookie2]); 
   }   
  else
  {
      my $cookie = $cgi->cookie(-name=>$config{migc4_cookie},-value=>"",-path=>'/',-expires=>'-1d');
      print $cgi->header(-cookie=>$cookie); 
  }
   
   
   # see();
   # print $self;
   # exit;
   http_redirect($self);
}

 sub add_history
{
	my %d = %{$_[0]};
	
	my $id_user = $d{id_user};
	if($id_user eq '')
	{
		$id_user = $user{id};
	}
	if(!($id_user>0))
	{
		# %user = %{get_user_info($dbh, $config{current_user})};
		$id_user = $user{id};
	}
	
	my %history = 
	(
		action => $d{action},
		id_user => $id_user,
		date => 'NOW()',
		time => 'NOW()',
		moment => 'NOW()',
		infos => "$ENV{REMOTE_ADDR} $ENV{HTTP_USER_AGENT}",
		page_record => $d{page},
		id_record => $d{id},
	);
	
	%history = %{quoteh(\%history)};
	
	inserth_db($dbh,'migcms_history',\%history);
}

sub quoteh
{
	my %hash_r = %{$_[0]};
	foreach $key (keys %hash_r)
	{
		$hash_r{$key} =~ s/\\//g;
		$hash_r{$key} =~ s/\\//g;
		$hash_r{$key} =~ s/\\//g;
		$hash_r{$key} =~ s/\'/\\\'/g;
	}
	return \%hash_r;
}

sub get_script_google_auth
{
	my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
	my $clientid = $migcms_setup{google_clientid} || "759361789094-8bb1m8593ms24pcasofq9adfgd2784c7.apps.googleusercontent.com";
	my $script = <<HTML;
		<script>
		jQuery(document).ready(function(){
			jQuery(".se-pre-con").hide();

			jQuery(".btn-google").click(function(){
					jQuery(".se-pre-con").show();
	        // Envoi de la requête d'authentification google
	        gapi.auth.signIn(
	          {
	            'clientid' : "$clientid",
	            'cookiepolicy' : 'single_host_origin',
	            'callback' : 'signinCallback',
	            'requestvisibleactions': 'http://schemas.google.com/AddActivity',
	            'scope': 'https://www.googleapis.com/auth/plus.login https://www.googleapis.com/auth/userinfo.email',
	          }
	        ) 
	        return false;
	    });
	  });

	  // Chargement de l'API gapi
	  (function() {
	  var po = document.createElement('script'); po.type = 'text/javascript'; po.async = true;
	  po.src = 'https://apis.google.com/js/client:plusone.js';
	  var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(po, s);
	  })();

	  // Retour de google pour la liaison à l'utilisateur
	  function signinCallback(authResult) {
	    // Si la connexion est réussie et que c'est la méthode PROMPT (et non la méthode AUTO. Permet d'empêcher 2 callbacks)
	    if (authResult['status']['method'] == 'PROMPT' && authResult['status']['signed_in'] == true)
	    {

	      gapi.client.load('oauth2', 'v2', function()
	      {
	        gapi.client.oauth2.userinfo.get()
	          .execute(function(resp)
	          {
	            // console.log(resp);
	            var email     = typeof resp.email != "undefined" ? resp.email : "";
	            var token     = authResult.access_token;
	            var id        = typeof resp.id != "undefined" ? resp.id : "";

	            var infos = {
	              "email"         :  email,
	              "token"         : token,
	              "id"            : id,
	            }

	            connexion(infos);         
	          });
	      });

	    } 
	    else if
	    (authResult['error'])
	    {
	    // Une erreur s'est produite.
	    // Codes d'erreur possibles :
	    //   "access_denied" - L'utilisateur a refusé l'accès à l'application
	    //   "immediate_failed" - La connexion automatique de l'utilisateur a échoué
	    	console.log("Une erreur s\'est produite : " + authResult['error']);
	    }
	  }

	  // Assocation du compte en DB via une requête Ajax
	  function connexion(infos)
	  {

	    var social_id        = infos["id"];
	    var social_token     = infos["token"];
	    var social_email     = infos["email"];

	    var request = jQuery.ajax(
	    {
	        url: '$config{baseurl}/cgi-bin/fwauth.pl?',
	        type: "GET",
	        data: 
	        {
						sw : 'login_db',
						social_id : social_id,
						social_token : social_token,  
						social_email : social_email,
						type : "social",
	        },
	        dataType: "json"
	    });

	    request.done(function(response) 
	    {
	    	jQuery(".se-pre-con").hide();
	      if(response.status == "ok" && response.url != '')
	      {
	        window.location = response.url;
	      }
	      else
	      {
	        jQuery(".error_message").empty().append("<div class='alert alert-danger'>"+response.message+"</div>");
	      }

	    });
	    request.fail(function(jqXHR, textStatus) 
	    {
	        
	    });

	  }
	</script>
HTML

	return $script;
}