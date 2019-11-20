#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use members;
use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset);

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "users";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_user_data.pl?";

use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
if($config{current_language} eq "")
{
   $config{current_language}=get_quoted('lg') || 1;
}


$dm_cfg{hiddp}=<<"EOH";

EOH

@dm_nav = (
  {
    'tab'=>'infos',
    'type'=>'tab',
    'title'=>'Informations',
  },
  {
    'tab'=>'tab_prix',
    'type'=>'cgi_func',
    'cgi_func'=>\&authentification_google,
    'title'=>'Authentification Google',
  },


);

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    
      '01/identity'=> {
	        'title'=>'Identité',
	        'fieldtype'=>'text',
	        'search' => 'y',

	    },
	    '02/email'=> {
	        'title'=>'Email',
	        'fieldtype'=>'text',
	        'search' => 'y',
	    }
      ,
	    '02/passwd'=> {
	        'title'=>'Mot de passe',
	        'fieldtype'=>'text',
	        'search' => 'y',
	    }
	);
%dm_display_fields =  
      (
	      
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

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
      edit_db_ajax
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
    
    my $js = <<"EOH";
   
EOH
    
    print migc_app_layout($js.$migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}

sub list
{
   # see();
    
   # my $number = 174.075 ;
   # print "<br />".$number;
   # $number = sprintf("%0.0f",$number*100);
   # print "<br />".$number/100;
   
      # $number = sprintf("%0.2f",$number);
   # print "<br />".$number;
   # exit;
   
   my $page = "";
   my $action = get_quoted('action');
   # my $identity = get_quoted('identity') || $user{identity};
   # 
   
   
   
   my $firstname = get_quoted('firstname');
   my $lastname = get_quoted('lastname');   
   my $email = get_quoted('email');
   my $password = get_quoted('password');
   my $password2 = get_quoted('password2');  
   my $id_language = get_quoted('id_language');  
   
   my $sha1_password = sha1_hex($password);
   if($action eq 'save_me')
   {
	   if($sha1_password ne '' &&  $firstname ne '' && $lastname ne '' && $email ne '' && $password ne '')
	   {
		   if($password eq $password2)
		   {
			   my $stmt = "UPDATE users SET firstname='$firstname',id_language='$id_language', lastname = '$lastname', email='$email',password='$sha1_password' WHERE id='$user{id}'";
			   execstmt($dbh,$stmt);
			   
			   add_history({action=>'modifie son mot de passe',id_user=>"$user{id}"});
			   my $alert = tools::get_alert({type=>"success",display=>'sweet',title=>"Modifié", message=>"Vos informations ont bien été enregistrées"});
			   # see();
			   print $alert;
			   exit;
		   }
		   else		   
		   {
			   my $alert = tools::get_alert({type=>"error",display=>'sweet',title=>"Erreur", message=>"Les mots de passe ne correspondent pas."});
			   # see();
			   print $alert;
			   exit;
		   }
	   }
	   else
	   {
		   my $alert = tools::get_alert({type=>"error",display=>'sweet',title=>"Erreur", message=>"Merci de compléter tous les champs obligatoires svp"});
		   # see();
		   print $alert;
		   exit;
	   }
   }
   
    my $select_language = '<select name="id_language" class="form-control">';
    my @languages = sql_lines({dbh=>$dbh,table=>"migcms_languages",where=>"",ordby=>"id"});
    foreach $language (@languages)
    {
        my %language = %{$language};
		if($user{id_language} == $language{id})
		{
			$select_language .= '<option value="'.$language{id}.'" selected="selected">'.$language{name}.'</option>';
		}
		else
		{
			$select_language .= '<option value="'.$language{id}.'">'.$language{name}.'</option>';
		}
    }
	$select_language .= '</select>';


	my %user = %{get_user_info()};	
	my $authentification_google = get_authentification_google({id_user=>$user{id}});
	
	my $cluf_box = '';
	if($config{use_cluf} eq 'y' && $user{cluf_accepte} eq 'y')
	{
		my %txt = sql_line({debug=>0,debug_results=>0,table=>'migcms_textes_emails',where=>"id='16'"});
		my $cluf = get_traduction({debug=>0,id_language=>1,id=>$txt{id_textid_texte}});
		
		my $box = <<"EOH";
		
		<div class="row">
		<div class="col-md-12">
		<h5>Conditions générales d'utilisation:</h5>
		<div class="alert alert-default" role="alert" style="height:300px;overflow:auto;text-align:justify;">$cluf</div>
		
		
		</div>
		</div>
		
EOH
		my $date_cluf = to_ddmmyyyy($user{date_cluf_accepte});
		$cluf_box = <<"EOH";
			<h2>Acceptation des conditions générales :</h2>
			<div class="alert alert-success" role="alert">
				Les conditions générales ont été acceptées le <b>$date_cluf</b>
			 </div>
			$box
EOH
	}
   
   my $edit =<<"EOH";
   
	<div class="wrapper">
		<div class="row">
			<div class="col-md-6">
				<h1 class="maintitle">$migctrad{infos_titre}</h1>
			</div>
			<div class="col-md-6 text-right"></div>
		</div>
		<section class="panel">
			<div class="panel-body">
				<form class="form-horizontal adminex-form" role="form" action="$dm_cfg{self}" method="post">
					<input type="hidden" name="self" id="self" value="$dm_cfg{self}" />
					<input type="hidden" name="edit_id" class="edit_id" value="$user{id}" />
					<input type="hidden" name="action" value="save_me" />
					<input type="hidden" name="sw" value="list" /> 
											   
					<div class="row">
						<div class="col-md-12 text-left">
							<div class="widget-box">
								<div class="widget-content"> 
									<div class="well">
									
										<div class="form-group item">
										  <label for="field_identity" class="col-sm-3 control-label">
											 $migctrad{adm_interface_langue} *
										  </label>
										  <div class="col-sm-9">
											$select_language
										  </div>                   
										</div>
									
										<div class="form-group item">
										  <label for="field_identity" class="col-sm-3 control-label">
											  $migctrad{adm_firstname} * 
										  </label>
										  <div class="col-sm-9">
											<input type="text" name="firstname"  value="$user{firstname}" id="field_firstname" class="form-control"  required  />
										  </div>                   
										</div>
									
										<div class="form-group item">
										  <label for="field_identity" class="col-sm-3 control-label">
											  $migctrad{adm_lastname} * 
										  </label>
										  <div class="col-sm-9">
											<input type="text" name="lastname"  value="$user{lastname}" id="field_lastname" class="form-control"  required  />
										  </div>                   
										</div>
										
									</div>
									<h2>Identification avec une adresse email et un mot de passe :</h2>
									<div class="well">	
										<div class="form-group item">
										  <label for="field_identity" class="col-sm-3 control-label">
											  $migctrad{adm_email}  * 
										  </label>
										  <div class="col-sm-9">
											<div class="input-group">
												<span class="input-group-addon">
													<i class="fa fa-envelope-o fa-fw"></i>
												</span>
												<input id="field_email" class="form-control" type="email" required name="email" autocomplete="off" value="$user{email}">
											</div>
										  </div>                   
										</div> 
									  
										<div class="form-group item">
										  <label for="field_identity" class="col-sm-3 control-label">
											  $migctrad{adm_pwd}  * 
										  </label>
										  <div class="col-sm-9">


											<div class="input-group">
												<span class="input-group-addon">
													<i class="fa fa-key fa-fw"></i>
												</span>
												<input id="field_password" class="form-control required" type="password" name="password" autocomplete="off" required value="">
											</div>	
											
										  </div>                   
										</div> 
									  
										<div class="form-group item">
										  <label for="field_identity" class="col-sm-3 control-label">
											  $migctrad{validation_field_text_password_confirmation}  * 
										  </label>
										  <div class="col-sm-9">
											<div class="input-group">
												<span class="input-group-addon">
													<i class="fa fa-key fa-fw"></i>
												</span>
												<input id="field_password2" class="form-control required" type="password" required name="password2" autocomplete="off" value="">
											</div>
										  </div>                   
										</div> 
									</div>
									<h2>Identification avec un compte Google :</h2>
									<div class="well">	
										$authentification_google
									</div>
									$cluf_box
								</div>
							</div>
						</div>
					</div>					
				   <div class="row">
						<div class="col-md-12 text-right">
							<div class="btn-group">
						   
								<button type="sumit"  class="btn btn-lg btn-success ">
								  $migctrad{save}
								</button>
							  
							</div>
						</div> 
					</div>  
				</form> 
			</div>
		</section>
	</div>

EOH
   
   
    my $confirm =<<"EOH";
    <div class="row">
            <div class="col-md-4 text-center">
                <img alt="300x200" src="mig_skin/4.0/img/profile.png">
            </div>
            <div class="col-md-7 text-center">
                  <div class="panel panel-primary">
                    <div class="panel-heading">
                      <h3 class="panel-title">Vos informations ont été modifées</h3>
                    </div>
                    <div class="panel-body">
                          <form class="form-horizontal" role="form">
                             
                               <input type="hidden" name="self" id="self" value="$dm_cfg{self}" />
                               <input type="hidden" name="edit_id" class="edit_id" value="$user{id}" />
                               <input type="hidden" name="action" value="save_me" />
                               
                              <div class="form-group">
                              <label for="field_identity" class="col-lg-2 control-label">
                              Identité: 
                              </label>
                              <div class="col-lg-9 text-left">
                              $identity
                              </div>
                              </div>
                              
                              <div class="form-group">
                              <label for="field_email" class="col-lg-2 control-label">
                              Email: 
                              </label>
                              <div class="col-lg-9 text-left">
                              $email
                              </div>
                              </div>
                              
                             
                              
                              <div class="form-group">
                                   <label for="" class="col-lg-2 control-label">
                                     
                                    </label>
                                    <div class="col-lg-10">
                                    <a href="cgi-bin/adm_user_data.pl?" class="btn btn-default">Recommencer</a>
                                  </div>
                              </div>
                          </form>
                       </div>
                       <div class="col-md-1 text-center"></div>
                 </div>
            </div>
      </div>
EOH
   
   if($action eq 'save_me')
   {
      display($confirm);
   }
   else
   {
      display($edit);
   }
}


# <h5>
#                               Informations publiques
#                             </h5>
#                             <hr>
#                             
#                                                  <div class="control-group">
#                               <label class="control-label">
#                                 Prénom
#                               </label>
#                               <div class="controls">
#                                 <a href="#" id="firstname" data-type="text" data-pk="1" data-original-title="Cliquez ici pour modifer votre prénom" class="inputText editable editable-click">
#                                   $user{firstname}
#                                 </a>
#                               </div>
#                             </div>
#                             <div class="control-group">
#                               <label class="control-label">
#                                 Nom
#                               </label>
#                               <div class="controls">
#                                 <a href="#" id="lastname" data-type="text" data-pk="1" data-original-title="Cliquez ici pour modifer votre nom" class="inputText editable editable-click">
#                                   $user{lastname}
#                                 </a>
#                               </div>
#                             </div>
#                             
#                             <div class="control-group">
#                               <label class="control-label">
#                                 Société
#                               </label>
#                               <div class="controls">
#                                 <a href="#" id="company" data-type="text" data-pk="1" data-original-title="Cliquez ici pour modifer le nom commercial de votre société" class="inputText editable editable-click">
#                                   $user{company}
#                                 </a>
#                               </div>
#                             </div>
#                             <div class="control-group">
#                               <label class="control-label">
#                                 TVA
#                               </label>
#                               <div class="controls">
#                                 <a href="#" id="tva" data-type="text" data-pk="1" data-original-title="Cliquez ici pour modifer le numéro de TVA de votre société" class="inputText editable editable-click">
#                                   $user{tva}
#                                 </a>
#                               </div>
#                             </div>
#        
#                                   <div class="control-group">
#                               <label class="control-label">
#                                 Adresse
#                               </label>
#                               <div class="controls">
#                                 <a href="#" id="firstname" data-type="text" data-pk="1" data-original-title="Cliquez ici pour modifer votre adresse" class="inputText editable editable-click">
#                                   $user{street}
#                                 </a>
#                               </div>
#                             </div>
#                             <div class="control-group">
#                               <label class="control-label">
#                                 Code Postal
#                               </label>
#                               <div class="controls">
#                                 <a href="#" id="lastname" data-type="text" data-pk="1" data-original-title="Cliquez ici pour modifer votre code postal" class="inputText editable editable-click">
#                                   $user{zip}
#                                 </a>
#                               </div>
#                             </div>
#                             <div class="control-group">
#                               <label class="control-label">
#                                 Ville
#                               </label>
#                               <div class="controls">
#                                 <a href="#" id="lastname" data-type="text" data-pk="1" data-original-title="Cliquez ici pour modifer votre ville" class="inputText editable editable-click">
#                                   $user{city}
#                                 </a>
#                               </div>
#                             </div>
#                             <div class="control-group">
#                               <label class="control-label">
#                                 Pays
#                               </label>
#                               <div class="controls">
#                                 <a href="#" id="country" data-type="text" data-pk="1" data-original-title="Cliquez ici pour modifer votre pays" class="inputText editable editable-click">
#                                   $user{country}
#                                 </a>
#                               </div>
#                             </div>
#                          
#                          
#                           <div class="control-group">
#                               <label class="control-label">
#                                 Tel/GSM
#                               </label>
#                               <div class="controls">
#                                 <a href="#" id="phone" data-type="text" data-pk="1" data-original-title="Cliquez ici pour modifer votre ville" class="inputText editable editable-click">
#                                   $user{phone}
#                                 </a>
#                               </div>
#                             </div>
#                             <div class="control-group">
#                               <label class="control-label">
#                                 FAX
#                               </label>
#                               <div class="controls">
#                                 <a href="#" id="fax" data-type="text" data-pk="1" data-original-title="Cliquez ici pour modifer votre pays" class="inputText editable editable-click">
#                                   $user{fax}
#                                 </a>
#                               </div>
#                             </div>
#                              <div class="control-group">
#                               <label class="control-label">
#                                 Site internet
#                               </label>
#                               <div class="controls">
#                                 <a href="#" id="website" data-type="text" data-pk="1" data-original-title="Cliquez ici pour modifer votre site internet" class="inputText editable editable-click">
#                                   $user{website}
#                                 </a>
#                               </div>
#                             </div>
#                             
#                             <div class="control-group">
#                               <label class="control-label">
#                                 Nom de votre banque
#                               </label>
#                               <div class="controls">
#                                 <a href="#" id="bank" data-type="text" data-pk="1" data-original-title="Cliquez ici pour modifer votre banque" class="inputText editable editable-click">
#                                   $user{bank}
#                                 </a>
#                               </div>
#                             </div>
#                             <div class="control-group">
#                               <label class="control-label">
#                                 N°Compte/IBAN
#                               </label>
#                               <div class="controls">
#                                 <a href="#" id="iban" data-type="text" data-pk="1" data-original-title="Cliquez ici pour modifer votre IBAN" class="inputText editable editable-click">
#                                   $user{iban}
#                                 </a>
#                               </div>
#                             </div>
#                                <div class="control-group">
#                               <label class="control-label">
#                                 BIC
#                               </label>
#                               <div class="controls">
#                                 <a href="#" id="bic" data-type="text" data-pk="1" data-original-title="Cliquez ici pour modifer votre BIC" class="inputText editable editable-click">
#                                   $user{bic}
#                                 </a>
#                               </div>
#                             </div>

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
#   
#   my $stmt = "DELETE FROM identities WHERE id_member='$id'";
#   execstmt($dbh,$stmt);
#   
# #  $stmt = "DELETE FROM lnk_member_groups WHERE id_member='$id'";
# #  execstmt($dbh,$stmt);
}




#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------