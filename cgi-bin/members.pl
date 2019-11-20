#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;     # standard package for easy CGI scripting
use DBI;     # standard package for Database access
use def;     # definitions & configurations
use tools;   # handy tools
use JSON::XS;
use sitetxt;
use sws;
use migcrender;
use members;
use def_handmade;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use setup;


my $lg = get_quoted('lg') || 1;
my $extlink = get_quoted('extlink');
my $extlink_member = get_quoted("extlink_member");

$lg =~ s/undefined//g;
$config{current_language} = $config{default_colg} = $lg;

$self = $config{baseurl}.'/'.'cgi-bin/members.pl?lg='.$lg.'&extlink='.$extlink.'&extlink_member='.$extlink_member;
#my $self_env_full = 'http://';
#if($ENV{HTTP} eq 'on' || $config{force_https} eq 'y')
#{
#	$self_env_full = 'https://';
#}
#$self_env_full .= $ENV{HTTP_HOST}.$config{baseurl}.'/'.'cgi-bin/members.pl?lg='.$lg.'&extlink='.$extlink.'extlink_member='.$extlink_member;

$sw = $cgi->param('sw') || 'account';
my $cookie_member_name = 'migcms_member_'.$config{projectname};

my @switches = qw(
member_logout_db
);

if (is_in(@switches,$sw)) { &$sw(); }  


################################################################################
# account
################################################################################
sub account
{
  # Si pas connecté, redirection vers le formulaire de connexion
  my %member = %{members::members_get()};
  if(!($member{id} > 0))
  {
    if($member_setup{enable_simplify_connect} eq "y")
    {
      cgi_redirect($config{fullurl}."/".$sitetxt{member_url_signup_or_login});
    }
    else
    {
      cgi_redirect("$self&sw=login_form");      
    }
    exit;
  }


  my $menu = get_menu();

  my $firstname = $member{delivery_firstname} || $member{firstname};
  my $lastname = $member{delivery_lastname} || $member{lastname};
# $lastname
  my $content_account = <<"EOH";
<h1 class="page_title"><span>$sitetxt{member_bonjour} $firstname $lastname,</span></h1>
<div class="parag_content">
	<div class="parag_text_content">
		$member_setup{id_textid_account_content}   
	</div>
</div>
EOH

  my $content = <<"EOH";
<div id="members" class="clearfix">
	<div class="row">
		<div class="$member_setup{class_col_left_member_zone}">
			$menu
		</div>
		<div class="$member_setup{class_col_right_member_zone}">
			$content_account
		</div>
	</div>
</div>
EOH

  display({content=>$content, id_tpl_page=>$member_setup{id_tpl_page}});
}

################################################################################
# member_edit
################################################################################
sub member_edit_coordonnees
{
  # Si pas connecté, redirection vers le formulaire de connexion
  my %member = %{members::members_get()};
  if(!($member{id} > 0))
  {
    cgi_redirect($self);
  }

  my $menu = members::get_menu();

  my %dm_dfl_members = %{members::get_dm_dfl()};

  my @fields_to_exclude = ("email", "email2", "password", "password2");
  
  my $form_content = get_frontend_form_from_dm_dfl({dm_dfl=>\%dm_dfl_members, fields_to_exclude=>\@fields_to_exclude});

  my $msg = '';
  if(get_quoted('msg') == 1)
  {
  $msg = <<"EOH";
<div class="alert alert-success fade in" role="alert"> 
	$sitetxt{saved} 
</div>
EOH
  }

  my $content = <<"EOH";
<div id="members" class="clearfix">
	<div class="row">
		<div class="$member_setup{class_col_left_member_zone}">
			$menu
		</div>
		<div class="$member_setup{class_col_right_member_zone}">
			<h1 class="page_title"><span>$sitetxt{member_mes_coordonnees}</span></h1>
			<div class="parag_text_content">$sitetxt{member_mes_coordonnees_txt}</div>
			$msg
			<div class="form-horizontal">
				<form novalidate="novalidate" action="$self" class="member_form" id="edit_member_form" method="post">
					<input type="hidden" name="sw" value="member_edit_db">
					<input type="hidden" name="url_after_edit" value="$self&sw=member_edit_coordonnees&msg=1">
					<input type="hidden" name="lg" value="$lg">
					<div class="form-group">
						<label class="col-sm-4 control-label">$sitetxt{members_email}</label>
						<div class="col-sm-8">
							<p class="form-control-static">$member{email}</p>
						</div>
					</div>
					$form_content
					$sitetxt{member_edit_coordonnees}
					<div class="form-group">
						<div class="col-sm-12 text-right">
							<button type="submit" class="btn btn-default">$sitetxt{members_modify}</button>
						</div>
					</div>
				</form>
			</div>
		</div>
	</div>
</div>
EOH

  display({content=>$content, id_tpl_page=>$member_setup{id_tpl_page}});
}

sub edit_optin_db
{
 #	 Si pas connecté, redirection vers le formulaire de connexion
  my %member = %{members::members_get()};
  my $force_id_tpl_page = get_quoted("force_id_tpl_page");
  
  $self .= '&force_id_tpl_page='.$force_id_tpl_page;
  
  if(!($member{id} > 0))
  {
    cgi_redirect($self);
  }
  my $email_optin = get_quoted('email_optin');
  my $url_after_edit = get_quoted('url_after_edit');
	$stmt = "UPDATE migcms_members SET email_optin='$email_optin' where id=$member{id}";
	execstmt($dbh,$stmt);	

	cgi_redirect($url_after_edit);
}

sub member_edit_db
{
  # Si pas connecté, redirection vers le formulaire de connexion
  my %member = %{members::members_get()};
  if(!($member{id} > 0))
  {
    cgi_redirect($self);
  }

  my %dm_dfl_members = %{members::get_dm_dfl()};

  my @fields_to_exclude = ("email", "email2", "password", "password2");
  my %fields_to_exclude = map { $_ => 1 } @fields_to_exclude;

  my %update_member;
  foreach my $field_line (sort keys %dm_dfl_members)
  {
    my ($ordby,$field_name) = split(/\//,$field_line);
    if(!($dm_dfl_members{$field_line}{frontend_editable} eq "y") || exists($fields_to_exclude{$field_name}))
    {
      next;
    }
    if($dm_dfl_members{$field_line}{frontend_addonly} eq 'y' && $member{id} > 0)
    {
      next;
    }

    $update_member{$field_name} = trim(get_quoted($field_name));

    # Si un champ requis est vide
    if($dm_dfl_members{$field_line}{frontend_required} eq 'y' && $update_member{$field_name} eq '')
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
  }
   
  $update_member{migcms_moment_last_edit} = 'NOW()';

  ### Update du membre ###
  $update_member{id} = sql_set_data({dbh=>$dbh, table=>'migcms_members',data=>\%update_member,where=>"id = '$member{id}'"});

  member_add_event({member=>\%update_member,type=>'signup_insert',name=>"Le membre modifie ses coordonnées",detail=>'',erreur=>''});

  # Redirection 
  my $url_after_edit = get_quoted("url_after_edit") || $self;
  cgi_redirect($url_after_edit);

}

################################################################################
# edit_password
################################################################################
sub member_edit_password
{
  # Si pas connecté, redirection vers le formulaire de connexion
  my %member = %{members::members_get()};  
  if(!($member{id} > 0))
  {
    cgi_redirect($self);
  }

  my $menu = get_menu(); 

  my $error = get_quoted('error');
  if($error == 1)
  {
    $error_msg = <<"EOH";
<div class="alert alert-block alert-error alert-danger">
	<p>$sitetxt{edit_password_error}</p>
</div>
EOH
  } 

  my $msg = '';
  if(get_quoted('msg') == 1)
  {
  $msg = <<"EOH";
<div class="alert alert-success fade in" role="alert"> 
	$sitetxt{saved} 
</div>
EOH
  }

   
  my $content = <<"EOH";
<div id="members" class="clearfix">
	<div id="members_alert">$error_msg</div>
	<div class="row">
		<div class="$member_setup{class_col_left_member_zone}">
			$menu
		</div>
		<div class="$member_setup{class_col_right_member_zone}">
			<h1 class="page_title"><span>$sitetxt{member_update_password}</span></h1>
			<div class="parag_text_content">$sitetxt{member_update_password_txt}</div>
			$msg
			<div class="form-horizontal">
				<form class="member_form" method="post" id="edit_password_form" action="$self">
					<input type="hidden" name="sw" value = "edit_password_db" />
					<input type="hidden" name="lg" value = "$lg" />
					<input type="hidden" name="id_page" value = "$id_page" />
					<input type="hidden" name="t" value = "$type" />
					<input type="hidden" name="token" value = "$member{token}" />
					<input type="hidden" name="url_after_edit" value = "$self&sw=member_edit_password&msg=1" />
					<input type="hidden" name="url_after_error" value = "$self&sw=member_edit_password&error=1" />
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
						<div class="col-sm-8 text-right">
							<button type="submit" class="btn btn-default">$sitetxt{edit_password_new3}</button>
						</div>
					</div>
				</form>
			</div>
		</div>
	</div>
</div>
EOH

  display({content=>$content, id_tpl_page=>$member_setup{id_tpl_page}});
}

################################################################################
# member_edit_optin
################################################################################
sub member_edit_optin
{
  # Si pas connecté, redirection vers le formulaire de connexion
  my %member = %{members::members_get()};
  if(!($member{id} > 0))
  {
    cgi_redirect($self);
  }
  my $force_id_tpl_page = get_quoted('force_id_tpl_page');

  my $menu = get_menu(); 

  my $checked_y = $checked_n = '';
  if($member{email_optin} eq 'y')
  {
	$checked_y = ' checked ';
  }
  else
  {
	$checked_n = ' checked ';
  }

  
  my $msg = '';
  if(get_quoted('msg') == 1)
  {
	$msg = <<"EOH";
<div class="alert alert-success fade in" role="alert"> 
	$sitetxt{saved} 
</div>
EOH
  }
  
   
  my $content = <<"EOH";
<div id="members" class="clearfix">
	<div id="members_alert">$error_msg</div>
	<div class="row">
		<div class="$member_setup{class_col_left_member_zone}">
			$menu
		</div>
		<div class="$member_setup{class_col_right_member_zone}">
			<h1 class="page_title"><span>$sitetxt{member_update_optin}</span></h1>
			<div class="parag_text_content">$sitetxt{member_update_optin_txt}</div>
			$msg
			<div class="form-horizontal">
				<form class="member_form" method="post" id="edit_optin_form" action="">
					<input type="hidden" name="sw" value = "edit_optin_db" />
					<input type="hidden" name="lg" value = "$lg" />
					<input type="hidden" name="id_page" value = "$id_page" />
					<input type="hidden" name="t" value = "$type" />
					<input type="hidden" name="force_id_tpl_page" value = "$force_id_tpl_page" />
					
					<input type="hidden" name="token" value = "$member{token}" />
					<input type="hidden" name="url_after_edit" value = "$self&sw=member_edit_optin&force_id_tpl_page=$force_id_tpl_page&msg=1" />
					<input type="hidden" name="url_after_error" value = "$self&sw=member_edit_optin&force_id_tpl_page=$force_id_tpl_page&error=1" />
					<div class="form-group">
						<div class="col-sm-12">
							<label><input type="radio" $checked_y name="email_optin" class="email_optin" value="y" /> $sitetxt{edit_optin_txt} </label>
						</div>
					</div>
					<div class="form-group">
						<div class="col-sm-12">
							<label><input type="radio" $checked_n name="email_optin" class="email_optin" value="n" /> $sitetxt{edit_optout_txt} </label>
						</div>
					</div>
					<div class="form-group">
						<div class="col-sm-12">
							<button type="submit" class="btn btn-default">$sitetxt{member_confirm}</button>
						</div>
					</div>
				</form>
			</div>
		</div>
	</div>
</div>
EOH

  display({content=>$content, id_tpl_page=>$member_setup{id_tpl_page},force_id_tpl_page=>$force_id_tpl_page});
}

################################################################################
# login_form
################################################################################
sub login_form
{
  my $url_after_login = get_quoted("url_after_login") || $member_setup{member_url_after_login} || $config{fullurl}."/".$sitetxt{member_url_account};
  # Si connecté, redirection vers la page correspondant au compte de l'utilisateur
  my %member = %{members::members_get()};
  if($member{id} > 0)
  {    
    cgi_redirect($url_after_login);
  }


  # Récupération d'un éventuel message d'erreur
  my $error = get_quoted('error');
  my $error_msg = members::get_member_error_message({error=>$error});

  my $content;

  if($member_setup{use_handmade_member_login_form_func} ne "")
  {
    my $fct = 'def_handmade::'.$member_setup{use_handmade_member_login_form_func};
    $content = &$fct({lg=>$lg, url_after_login=>$url_after_login});
  }
  elsif($member_setup{enable_simplify_connect} eq "y")
  {
    my $email = get_quoted("email");

    ##### FORMULAIRE DE CONNEXION #####  
    my $login_form  = members::member_html_login_form({url_after_login=>$url_after_login, url_after_error=>"$self&sw=login_form", email=>$email});
    $login_form = "<div class='row'><div class='col-md-8 col-md-offset-2'>$login_form</div></div>";

    $content = <<"EOH";
    <div id="members" class="clearfix">
      $error_msg
      <div class="row">
        $login_form
      </div>
    </div>
EOH
  }
  else
  {  
    ##### CONNEXION RESEAUX SOCIAUX ##### 
    my $social_medias = members::get_buttons_social_medias();

    ##### FORMULAIRE D'INSCRIPTION ##### 
    # Formulaire classique
    my $signup_form = "";
    if($member_setup{disable_member_signup} ne "y")
    {
      $signup_form = member_html_signup_form({lg=>$lg,url_after_error=>"$self&sw=member_signup"});
      $signup_form = "<div class='col-md-6'>$signup_form</div>";
    }

    if($type eq "revendeur")
    { 
      # Formulaire revendeur
      $signup_form = member_html_signup_form_revendeur({lg=>$lg, url_after_error=>"$self&sw=login_form"});
    }  

    ##### FORMULAIRE DE CONNEXION #####  
    my $login_form  = members::member_html_login_form({url_after_login=>$url_after_login, url_after_error=>"$self&sw=login_form"});
    if($member_setup{disable_member_signup} ne "y")
    {    
      $login_form = "<div class='col-md-6'>$login_form</div>";
    }
    else
    {
      $login_form = "<div class='row'><div class='col-md-8 col-md-offset-2'>$login_form</div></div>";
    }

    $content = <<"EOH";
  <div id="members" class="clearfix">
  	$error_msg
  	<div class="row">
      $social_medias
  		$login_form
  		$signup_form
  	</div>
  </div>
EOH
  }

  

  if($config{member_custom_login_form_tpl_page} ne "")
  {
    $member_setup{id_tpl_page} = $config{member_custom_login_form_tpl_page};
  }
  
  if(!($member_setup{id_tpl_page_notconnected} > 0)) {
	$member_setup{id_tpl_page_notconnected} = $member_setup{id_tpl_page};
  }

  display({content=>$content, id_tpl_page=>$member_setup{id_tpl_page_notconnected}});
}


################################################################################
# signup
################################################################################
sub member_signup
{
  my $type = get_quoted("type");
  my $stoken = get_quoted("stoken");
  
  my $url_after_success = get_quoted("url_after_success") || $member_setup{url_after_success} || $config{fullurl}."/".$sitetxt{member_url_account};
  # Si connecté, redirection vers la page correspondant au compte de l'utilisateur
  my %member = %{members::members_get()};
  if($member{id} > 0)
  {    
    cgi_redirect($url_after_success);
  }

  # Récupération d'un éventuel message d'erreur
  my $error = get_quoted('error');
  my $error_msg = get_member_error_message({error=>$error});  

  # Récupération des valeurs connues en DB sur base du STOKEN pour pré-remplir les champs
  my %valeurs_connues = ();
  if($stoken ne "")
  {
    my %member = sql_line({dbh=>$dbh, table=>"migcms_members", where=>"stoken != '' AND stoken = '$stoken'"});
    if($member{id} > 0)
    {
      foreach $key (keys %member)
      {
        $valeurs_connues{$key} = $member{$key};
      }
      delete $valeurs_connues{password};

    }
  }


  # Formulaire classique
  my $form = member_html_signup_form({lg=>$lg,url_after_error=>"$self&sw=member_signup", url_after_success=>$url_after_success, valeurs_connues=>\%valeurs_connues, stoken=>$stoken});

  if($type eq "revendeur")
  { 
    # Formulaire revendeur
    $form = member_html_signup_form_revendeur({lg=>$lg, url_after_error=>"$self&sw=member_signup", disabled_intro_revendeur=>"y"});
  }  


  my $form = <<"EOH";
<div id="members" class="clearfix">
	$error_msg
	<div class="row">
		<div class="col-md-8 col-md-offset-2">
			$form
		</div>
	</div>
</div>
EOH

  # Fonction sur-mesure si nécessaire
  if($member_setup{use_handmade_member_signup_form_func} ne "")
  {
    my $fct = 'def_handmade::'.$member_setup{use_handmade_member_signup_form_func};
    $form = &$fct({lg=>$lg, type=>$type});
  }

  display({content=>$form, id_tpl_page=>$member_setup{id_tpl_page}});

}


################################################################################
# lost_password
################################################################################
sub lost_password
{
    my $id_page = get_quoted('force_id_tpl_page');

	my $page =<<"HTML";
<div id="members" class="clearfix">
	<div class="row">
		<div class="col-md-8 col-md-offset-2">
			<div class="lostpassword-form">
				<h1 class="maintitle"><span>$sitetxt{eshop_passwordlost}</span></h1>
				<div class="parag_text_content">$sitetxt{eshop_passwordlost_txt}</div>
				<form class="form-horizontal" method="post" id="lost_password_form">
					<input type="hidden" name="sw" value = "lost_password_db" />
					<input type="hidden" name="lg" value = "$lg" />
					<input type="hidden" name="force_id_tpl_page" value = "$force_id_tpl_page" />
					<div class="form-group">
						<label class="control-label col-sm-4" for="inputEmail">$sitetxt{eshop_passwordlost_login}</label>
						<div class="col-sm-8">
							<input type="text" name="email" required id="inputEmail" placeholder="$sitetxt{eshop_passwordlost_login}" class="required form-control" />
						</div>
					</div>
					<div class="form-group">
						<div class="col-sm-4"></div>
						<div class="col-sm-8 text-right">
							<button type="submit" class="btn btn-info">$sitetxt{eshop_passwordlost_txt_ok}</button>
						</div>
					</div>
				</form>
			</div>
		</div>
	</div>
</div>
HTML

  # Affichage de la confirmation ou de l'erreur
  # if(!($id_page >0))
  # {
  #   $id_page = $member_setup{id_page};
  # }
  
  # if($member_setup{id_tpl_page_notconnected} eq "") {
	 # $member_setup{id_tpl_page_notconnected} = $member_setup{id_tpl_page};
  # }

 display({content=>$page, id_tpl_page=>$member_setup{id_tpl_page}});

}



################################################################################
#DISPLAY
################################################################################
sub display
{
  see();
  my %d = %{$_[0]};

  # Redirection à la racine si le module membre est désactivé
  if($member_setup{member_disabled} eq 'y')
  {
      http_redirect($config{baseurl});
      exit;     
  }

  if(!($d{id_tpl_page} > 0) && $d{id_tpl_page} ne 'blank' )
  {
    $d{id_tpl_page} = $member_setup{id_tpl_page1};
  }

  # Si un id tpl page est passé en param
  if(get_quoted("force_id_tpl_page") ne "")
  {
    $d{id_tpl_page} = get_quoted("force_id_tpl_page");
  }
 
  if($id_tpl_page ne 'blank')
  {      
    my $page_content = render_page({debug=>0,content=>$d{content},id_tpl_page=>$d{id_tpl_page},extlink=>$extlink,lg=>$config{current_language}});

    my $meta_title = $sitetxt{'member_metatitle_'.$sw};
    my $tag = '<MIGC_METATITLE_HERE>';
    $page_content =~ s/$tag/$meta_title/g;
    print <<"EOH";
	$page_content 
EOH
  } 
  else
  {
    print $content;
  }

  exit;
}

sub member_edit_identity {

  my %member = %{members::members_get()};
  if(!($member{id} > 0))
  {
    cgi_redirect($self);
  }


  my $type= get_quoted('type');
  my $url_after_edit = "$self&sw=member_edit_identity&type=$type&msg=1";

  my $msg = '';
  if(get_quoted('msg') == 1)
  {
  $msg = <<"EOH";
<div class="alert alert-success fade in" role="alert"> 
	$sitetxt{saved} 
</div>
EOH
  }

  my $content = eshop::get_edit_identity_content({type=>$type, member=>\%member, url_after_edit=>$url_after_edit, msg=>$msg});
  
  my $menu = members::get_menu();

  my $page = <<"EOH";
<div id="members" class="clearfix">
	<div class="row">
		<div class="$member_setup{class_col_left_member_zone}">
			$menu
		</div>
		<div class="$member_setup{class_col_right_member_zone}">
			$content
		</div>
	</div>
</div>
EOH
  
  display({content=>$page, id_tpl_page=>$member_setup{id_tpl_page}});

}

################################################################################
# member_wishlist
################################################################################
sub member_wishlist
{
  # Si pas connecté, redirection vers le formulaire de connexion
  my %member = %{members::members_get()};
  if(!($member{id} > 0))
  {
    cgi_redirect($self);
  }

  my $content = eshop::get_wishlist_content({member=>\%member});

  my $menu = get_menu();

  my $page = <<"EOH";
<div id="members" class="clearfix">
  <div class="row">
    <div class="$member_setup{class_col_left_member_zone}">
      $menu
    </div>
    <div class="$member_setup{class_col_right_member_zone}">
      $content
    </div>
  </div>
</div>
EOH
  
  display({content=>$page, id_tpl_page=>$member_setup{id_tpl_page}});
}


################################################################################
# member_orders_history
################################################################################
sub member_orders_history
{
  # Si pas connecté, redirection vers le formulaire de connexion
  my %member = %{members::members_get()};
  if(!($member{id} > 0))
  {
    cgi_redirect($self);
  }

  my $content = eshop::get_orders_history_content({member=>\%member});

  my $menu = get_menu();

  my $page = <<"EOH";
<div id="members" class="clearfix">
	<div class="row">
		<div class="$member_setup{class_col_left_member_zone}">
			$menu
		</div>
		<div class="$member_setup{class_col_right_member_zone}">
			$content
		</div>
	</div>
</div>
EOH
  
  display({content=>$page, id_tpl_page=>$member_setup{id_tpl_page}});
}

################################################################################
# member_order_retour
################################################################################
sub member_order_retour
{
  # Si pas connecté, redirection vers le formulaire de connexion
  my %member = %{members::members_get()};
  if(!($member{id} > 0))
  {
    cgi_redirect($self);
  }

  my $order_token = get_quoted("token");
  my $content = eshop::get_order_retour_content({token=>$order_token, member=>\%member});

  my $menu = get_menu();

  my $page = <<"EOH";
<div id="members" class="clearfix">
	<div class="row">
		<div class="$member_setup{class_col_left_member_zone}">
			$menu
		</div>
		<div class="$member_setup{class_col_right_member_zone}">
			$content
		</div>
	</div>
</div>
EOH
  
  display({content=>$page, id_tpl_page=>$member_setup{id_tpl_page}});
}

################################################################################
# member_mailing_subscribe_ok
################################################################################
sub member_mailing_subscribe_ok
{
  ### Message de confirmation ###   
  my $page =<<"EOH";   
  <div id="members" class="clearfix">  
    <div class="alert alert-success">
    	<h1><span class="glyphicon glyphicon-ok" aria-hidden="true"></span> $sitetxt{'members_mailing_subscribre_confirmation_title'}</h1>
    	
    	<input type="button" class="btn btn-success"  value="$sitetxt{retour}" onclick="window.history.back()" /> 
    </div>
  </div>
EOH

 # Affichage de la confirmation ou de l'erreur
  my $id_page = get_quoted("id_page");
  if(!($id_page >0))
  {
    $id_page = $member_setup{id_page};
  }

  my $page_html = migcrender::render_page({force_content=>$page,debug=>0,id=>$id_page,lg=>$lg});
  see();
  print $page_html;
  exit; 
}


################################################################################
# ajax_connect_facebook_token
################################################################################
sub ajax_connect_social_token
{
  my $social_id = get_quoted("social_id");
  my $social_token = get_quoted("social_token");
  my $social_email = get_quoted("social_email");

  if($social_id ne "") 
  {
    # see();
    $stmt = "UPDATE migcms_members SET social_token='$social_token' where social_id = '$social_id'";
    execstmt($dbh,$stmt);
    
    # On récupère la ligne d'un member en fonction de l'id social
    my %member = sql_line({debug=>0,debug_results=>0,dbh=>$dbh,table=>'migcms_members',where=>"social_id='$social_id'"});

    # Si on en récupère bien un
    if($member{social_id}) {
      #on écrit le cookie
      # $cookie{'token_member'} = $member{token};
      # $utf8_encoded_json_text = encode_json \%cookie;
      # my $expires = '';
      # my $cook = $cgi->cookie(-name=>'eplus',-value=>$utf8_encoded_json_text,-path=>'/',-expires=>$expires);
      # print $cgi->header(-cookie=>$cook,-charset => 'utf-8');
      my $url_redirect = member_login_db({stoken=>$member{stoken}, ajax=>"y"});

      see();
      print $url_redirect;
      exit;
      # print "ok";
      # print "test";
      # see(\%member);
    }
    # Sinon, la personne n'est pas associée à un compte social
    else {

      # On récupère la ligne d'un member en fonction de l'email social
      my %member = sql_line({debug=>0,debug_results=>0,dbh=>$dbh,table=>'migcms_members',where=>"email='$social_email'"});
      # Si on recoit un member c'est que l'adresse existe mais n'est pas associée à un réseau social
      if($member{email}) {
        see();
        print("adresse-existe");
      }
      else {
        # adresse inexistante
        see();
        print "ko";
      }
      
    }
    
  }
  else
   {

    see();
    print "ko";

   }
}

################################################################################
# member_signup_or_login
################################################################################
sub member_signup_or_login
{
  # Si connecté, redirection vers la page correspondant au compte de l'utilisateur
  my %member = %{members::members_get()};
  if($member{id} > 0)
  {  
    cgi_redirect($config{full_url}."/".$sitetxt{member_url_account});
  }

  my $url_from = get_quoted("url_from");

  my $form = get_member_signup_or_login_form({lg=>$lg, url_from=>$url_from, class_label=>"", class_input_group=>"", class_submit=>""});

  my $content = <<"EOH";
    <div id="members" class="clearfix">
      $error_msg
      <div class="row">
        <div class="col-md-8 col-md-offset-2">
          $form
        </div>
      </div>
    </div>
EOH

  display({content=>$content, id_tpl_page=>$member_setup{id_tpl_page}});

}

################################################################################
# member_signup_or_login_db
################################################################################
sub member_signup_or_login_db
{
  my $email = get_quoted("email");
  my $lg = get_quoted("lg");
  # récupération de l'URL d'où vient l'utilisateur
  my $url_from = get_quoted("url_from");

  # Recherche d'un membre avec cette adresse email
  my %member = sql_line({dbh=>$dbh, table=>"migcms_members", where=>"email != '' AND email = '$email'"});

  ###############################################
  # CAS 1 : L'adresse e-mail n'existe pas
  ###############################################
  if(!($member{id} > 0))
  {
    # Si la validation du mail est demandée
    if($member_setup{member_signup_mail_activation} eq "y")
    {
      # Création d'un membre avec cet adresse e-mail      
      my $token = $token2 = create_token(20);
      my $stoken = sha1_hex($token);

      my %new_member = (
        email       => $email,
        actif       => "n",
        email_actif => "n",
        id_language => $lg,
        token       => $token,
        token2      => $token2,
        stoken      => $stoken,
        url_from    => $url_from,
      );

      # Ajout du membre en DB
      inserth_db($dbh, "migcms_members", \%new_member);

      # Envoi du mail de validation
      member_mail_activation({stoken=>$new_member{stoken}});

      my $content = <<"HTML";
        <div id="members" class="clearfix">
          <div class="row">
            <div class="alert alert-success fade in" role="alert"> 
              <h1>Votre adresse email n’est pas connue par Alias Consult</h1>
              Un email vous a été envoyé pour vérifier votre identité et recevoir un mot de passe pour accéder au formulaire d'inscription.
            </div>
          </div>
        </div>
HTML
      display({content=>$content, id_tpl_page=>$member_setup{id_tpl_page}});

    }
    else
    {
      # Redirection vers le formulaire d'inscription
      cgi_redirect($self."&sw=member_signup&email=$email");      
    }
  }
  ###############################################################################################
  # CAS 2 : L'adresse e-mail existe mais pas de password
  # Redirection vers le formulaire d'inscription pré-rempli avec les données connues du membre
  ###############################################################################################
  elsif($member{id} > 0 && $member{password} eq "")
  {

    # Si la validation du mail est demandée
    if($member_setup{member_signup_mail_activation} eq "y")
    {
      # Mise à jour du membre avec l'url_from
      if($url_from ne "")
      {
        my $stmt = <<"SQL";
          UPDATE migcms_members
          SET url_from = '$url_from'
          WHERE id = '$member{id}'
SQL
        execstmt($dbh,$stmt);      
      }
      # Envoi du mail de validation
      member_mail_activation({stoken=>$member{stoken}});

      my $content = <<"HTML";
       <div id="members" class="clearfix">
          <div class="row">
            <div class="alert alert-success fade in" role="alert"> 
              <h1>Votre adresse email est connue par Alias Consult</h1>
              Un email vous a été envoyé pour vérifier votre identité et recevoir un mot de passe pour accéder au formulaire d'inscription.
            </div>
          </div>
        </div>
HTML
      # Affichage de la confirmation d'envoi
      display({content=>$content, id_tpl_page=>$member_setup{id_tpl_page}});
      exit;
    }
    else
    {
      # Redirection vers le formulaire d'inscription
      cgi_redirect($self."&sw=member_signup&url_after_success=".$url_from);      
    }
  }
  #######################################################################################
  # CAS 3 : L'adresse e-mail existe et un password existe
  # Redirection vers le formulaire de connexion avec le champ email pré-rempli et caché
  #######################################################################################
  elsif($member{id} > 0 && $member{password} ne "")
  {
    cgi_redirect($self."&sw=login_form&email=$email&url_after_login=".$url_from);
  }
  
}

sub get_member_signup_or_login_form
{
  my %d = %{$_[0]};

  my $lg = $d{lg} || 1;

  my $class_label       = $d{class_label} || "col-sm-4 control-label";
  my $class_input_group = $d{class_input_group} || "col-sm-8";
  my $class_submit      = $d{class_submit} || "col-sm-4";
  my $url_from = $d{url_from};

  #formulaire standard
  my $form = <<"EOH";
    <div class="email-form">
      <h1 class="maintitle"><span>$sitetxt{members_title_signup_or_login}</span></h1>
      $infos_suppl
      <form class="form-horizontal" id="member-login" method="post" action="$self">
        <input type="hidden" name="sw" value="member_signup_or_login_db" />
        <input type="hidden" name="lg" value="$d{lg}" />
        <input type="hidden" name="url_from" value="$d{url_from}" />


        <div class="form-group">
          <label class="$class_label" for="inputEmail">$sitetxt{members_login} <span class="member_mandatory">*</span></label>
          <div class="$class_input_group">
            <input type="email" name="email" class="required email form-control" required id="inputEmail" placeholder="$sitetxt{members_login}" />
            <span class="help-block">($sitetxt{'members_obligatoire'})</span>
          </div>
        </div>        
        
        <div class="login-button">
          <button type="submit" class="btn btn-info">$sitetxt{members_next}</button>
        </div>
        
      </form>
    </div>
EOH
  return $form;
}

sub login_or_signup_social_media_db
{
  my @data = qw(
    social_id
    social_token
    social_email
    social_lastname
    social_firstname
    social_city
    social_country
    social_birthdate
    social_type
  )

  # On cherche un client 
}

sub ajax_validate_vat
{
  use Business::Tax::VAT::Validation;  
  # use boolean;  

  my $vat = get_quoted("delivery_vat");

  # my %response = (
  #   status => 
  # )
  my $status = "false";

  if($vat ne "")
  {

    $vat =~ s/ //g;
    $vat =~ s/\.//g;
    $vat =~ s/\-//g;

    my $hvatn = Business::Tax::VAT::Validation->new();
    
    if($hvatn->check($vat))
    {
      $status = "true";
    }
  }

  see();
  # use boolean -truth;
  # print JSON->new->allow_nonref->convert_blessed->encode({true => (1 == 1)});
  print $status;
  exit;

    
   
} 