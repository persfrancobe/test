#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use migcrender;
use Data::Dumper;
use JSON::XS;
use sitetxt;
use def_handmade;       
use certigreen;       
use DateTime;
use HTML::Entities;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);


my $email_from = 'info@certigreen.be';
my $email_to_debug = 'alexis@bugiweb.com';

# $email_from = $email_to_debug;

my $sw = get_quoted('sw') || "commande_etape";
my $extlink = get_quoted('extlink') || "1";
my $dbh_data = $dbh2;

if ($config{current_language} eq "") {$config{current_language} = $config{default_language};}
my $lg=$config{current_language} = get_quoted('lg') || 1;

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
# if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
# }
                                                      
# my $htaccess_protocol_rewrite = 'http';            
my $self = "../cgi-bin/certigreen.pl?id_type=$id_type&lg=$lg&extlink=$extlink";
my $full_self = "$htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/certigreen.pl?lg=$lg&extlink=$extlink";
my $self_path = "$htaccess_protocol_rewrite://$config{rewrite_default_url}";

my $EMAILDEBUG = 'alexis@bugiweb.com';
my $EMAILSITE = 'alexis@bugiweb.com';

see();
http_redirect("http://www.certigreen.be/public");
exit;

$self = $full_self;
&$sw();


################################################################################
# commande_etape
################################################################################
sub commande_etape
{
   #STEPS***********************************************************************
   my $go_to_step = get_quoted('go_to_step') || 1;
   my $token = get_quoted('token') || '';
   
   my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token'"});
   
   if(!($commande{id} > 0 && $commande{token} ne ''))
   {
      %commande = ();
      $commande{token} = create_token(19);
	  $commande{visible} = 'y';
      $commande{id} = inserth_db($dbh2,'intranet_factures',\%commande);
	  see();
	  http_redirect("$self&sw=commande_etape&go_to_step=1&token=$commande{token}");
	  exit;
   }
   
   my $err = get_quoted('err');
   my $error_msg = '';
   if($err eq 'pass')
   {
        $error_msg = <<"EOH";
                  <div class="alert alert-block alert-error alert-danger">
                    <h4 class="alert-heading">Erreur de mots de passe</h4>
                    <p>Les mots de passes ne correspondent pas ou ne sont pas validez,reessayez svp.</p>
                  </div>
EOH
   }
   
   
   #LISTE DES ETAPES************************************************************
   my %steps_names = ();        
   my $steps = '<ul id="certigreen_steps" class="clearfix">';    
   my $connexion = '';
   my $espace_perso .=<< "EOH";
					   <a class="btn-custom3" href ="$self&sw=espace_perso">Mon espace Certigreen</a>
EOH
       
   my $cookie_order = $cgi->cookie('certigreen_handmade');
   
   #####################        SI USER EST CONNECTE         #######################   
   if($cookie_order ne "")       
   {                  
       my %hash_member;  
       
       $cookie_order_ref=decode_json $cookie_order;
       %hash_member=%{$cookie_order_ref};   
       
       my %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});   
       
                ############        SI USER EST UNE AGENCE         #############       
       if( ($hash_member{token_member} ne '') && ($member{type_member} eq 'Agence') )
       {
            %steps_names = (
                      '1'=>"Choix de l'expertise",                                      
                      '2'=>'Coordonnées du bien',                      
                      '3'=>'Coordonnées',
                      '4'=>'Récapitulatif',
                  );                  
       }
                 ############        SI USER EST UN PARTICULIER         #############       
       elsif( ($hash_member{token_member} ne '') && ($member{type_member} eq 'Particulier') )
       {
            %steps_names = (
                      '1'=>"Choix de l'expertise",
                    '2'=>'Coordonnées',      
                      '3'=>'Coordonnées',
                      '4'=>'Récapitulatif',
                  );
        }   
        
        $connexion .=<< "EOH";
					   <a class="btn-custom3" href="$self&sw=logout_db">Déconnexion</a>
EOH
   }
   #####################        SI USER N'EST PAS CONNECTE         #######################   
   else
   { 
       %steps_names = (
                      '1'=>"Choix de l'expertise",
                      '2'=>'Coordonnées',      
                      '3'=>'Coordonnées ',
                      '4'=>'Récapitulatif',
                      );
   }   
   
   #####################        GENERATION DU MENU         #######################  
   foreach my $step (sort keys %steps_names)
   {
      if($step == 2)
	  {
		next;
	  }
	  my $sel = '';
      if($step == $go_to_step || ($go_to_step == 2 && $step == 3))
      {
          $sel = 'sel_step';
      }
      
      $steps .=<< "EOH";
        <li class="certigreen_step_$step $sel">
            <a href="$self&sw=commande_etape&go_to_step=$step&token=$token" class="$sel"> 
                $steps_names{$step}
            </a>
        </li>
EOH
    }

   $steps .= '</ul>';
   
   #CURRENT_STEP_FORM***********************************************************
   my $current_step_form = '';
   if( ($go_to_step > 0 && $go_to_step < 6 ) || 'immeub_apparte')
   {
      my $func = 'commande_etape_'.$go_to_step;
      $current_step_form = &$func({commande=>\%commande});
   }
   
   #MAIN PAGE*******************************************************************
   my $page = <<"EOH";
   
		<section class="parag_content parag_form">
        <div class="row">
			<div class="col-lg-12 col-sm-12 col-xs-12 members_form"> 
				<h1 class="text-center">Commander une expertise</h1> 
				$steps
				$error_msg
				$current_step_form    

				<div class="text-center">
					<br /><br /><br /><br />
					<hr />
					$espace_perso
					$connexion
				</div>
          </div>
		</div>
		</section>
EOH
    
    display($page);
}


################################################################################
# commande_etape_1
################################################################################
sub commande_etape_1
{
   see();
   my %d = %{$_[0]};                 
   my $commande_id = $d{commande}{id};
   my $token_commande = $d{commande}{token};
   
   my $cookie_order = $cgi->cookie('certigreen_handmade');
         
    my %member = ();       
    #si user est connecté
    if($cookie_order ne "")       
    {                  
        my %hash_member;  
        
        $cookie_order_ref=decode_json $cookie_order;
        %hash_member=%{$cookie_order_ref};    
        
        if($hash_member{token_member} ne '')
        {
            %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});  
        }
    }
                           
  #TYPES BIEN--------------------------------------------------------------
   my %vals = ();
   my @sql_type_bien = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'types_bien',select=>"id,type_$lg as name",ordby=>"name",where=>"id NOT IN ('4','5')"});
   foreach $bien_type(@sql_type_bien)
   {
      my %bien_type = %{$bien_type};
      
      $vals{$bien_type{id}.'/'.$bien_type{id}} = $bien_type{name};             
   }
   
   my $val_bien = 3;
   my %if_commande_exist = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
   if($if_commande_exist{id_type_bien} > 0)
   {
        $val_bien = $if_commande_exist{id_type_bien};     #si type du bien exist déjà, le bouton sera checked; si non => 1 par defaut 
   }
   
   my $type_bien = get_form_line(
                                  {
                                      type => 'btns-group',
                                      name =>'id_type_bien', 
                                      label =>'Type de bien à experiser',
                                      checked_val=> $val_bien,
                                      style=>"",
                                      vals => \%vals,
                                      size_col_label=>"4",
                                      size_col_field=>"8",
                                  }
                              );          
                              
                         
  #TYPES DOCUMENT--------------------------------------------------------------
   
   ############################   N'UTILISONS PAS touts les 5 types DE BD; JUSTE LES SUIVANTS     ##############################   
   
   my %docs = (                        
                '1'=>"Certificat PEB",
                '2'=>"Contrôle électrique",  
                '6'=>"Les deux",
              );
              
   my %vals = ();
   
   my @if_documents_exists = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'commande_documents',where=>"commande_id='$commande_id'"});
   
   my @doc_compte = ();
   
   foreach my $doc (sort keys %docs)
   {
       my %if_doc_exist = sql_line({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'commande_documents',where=>"commande_id='$commande_id' AND type_document_id='$doc'"});
       if( $if_doc_exist{id} > 0 )
       {
            push(@doc_compte, $doc);
       }
   }                         
     
   #si il y a les deux documents : certificat PEB et Controle electrique
   if (scalar(@doc_compte) == 2 )
   {    
        $vals{'1/1/0/0'} = $docs{1};
        $vals{'2/2/0/0'} = $docs{2};
        # $vals{'6/6/0/1'} = $docs{6};
   }
   #si il y a un des deux
   elsif (scalar(@doc_compte) == 1)
   {    
        foreach my $id_doc (sort keys %docs)
       {
           my %if_doc_exist = sql_line({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'commande_documents',where=>"commande_id='$commande_id' AND type_document_id='$id_doc'"});
           if( $if_doc_exist{id} > 0 )
           {
                $vals{$id_doc.'/'.$id_doc.'/0/1'} = $docs{$id_doc};
           }
           else
           {
                $vals{$id_doc.'/'.$id_doc.'/0/0'} = $docs{$id_doc};
           }
       }
   }
   else
   {
        $vals{'1/1/0/0'} = $docs{1};
        $vals{'2/2/0/0'} = $docs{2};
        # $vals{'6/6/0/0'} = $docs{6};
   }
   
   
#    my $check_type = 2;
            
   ######################   UTILISONS JUSTE 2 TYPE D'EXPERTISE    ####################################
   my $types_document = get_form_line(
                                  {
                                      type => 'btns-group',
                                      name =>'type_document_id', 
                                      label =>'Expertise souhaitée',
                                      required=>'',                      
                                      input_type=>"checkbox",   
#                                       checked_val=> $check_type,
                                      style=>"",
                                      vals =>\%vals,
                                      size_col_label=>"4",
                                      size_col_field=>"8",
                                  }
                              );     
                              
  ######################   AUTRE TYPES D'EXPERTISE    ####################################
   my %autre_docs = (                        
                '3'=>"Citerne",
                '4'=>"Amiante", 
                '5'=>"Pollution des sols",
              );
              
  my %autre_vals = ();
  
  foreach my $id_document(sort keys %autre_docs)
   {
       my %if_document_exist = sql_line({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'commande_documents',where=>"commande_id='$commande_id' AND type_document_id='$id_document'"});       
       
       if( $if_document_exist{id} > 0 )
       {
            $autre_vals{$id_document.'/'.$id_document.'/0/1'} = $autre_docs{$id_document};
       }
       else
       {
            $autre_vals{$id_document.'/'.$id_document.'/0/0'} = $autre_docs{$id_document};  
       }
    }
  
   my $autre_types_document = get_form_line(
                                  {
                                      type => 'btns-group',
                                      name =>'id_autre_type_document', 
                                      label =>'Autres expertises',         
                                      input_type=>"checkbox",     
                                      required=>'',    
                                      style=>"",
                                      vals =>\%autre_vals,
                                      size_col_label=>"4",
                                      size_col_field=>"8",
                                  }
                              );                                   
                              
    my $page_1 = <<"EOH";
    	<script type="text/javascript">
    		jQuery(document).ready( function () 
    		{                   
        			//alert('init_form');
					init_form();
			});
		</script>
      
      
        <hr />  
    	<form method="post"  action="$full_self" class="form-horizontal" role="form" style="padding-top:0px;">
    		<input type="hidden" name="lg" value="$lg" />
    		<input type="hidden" name="from" value="$sw" />
			<input type="hidden" name="sw" value="commande_etape_1_db" />
			<input type="hidden" name="token" value="$token_commande" />  
        
			<h2 class="text-center">Choix de l\'expertise <span>(étape 1/4)</span></h2>    
            $types_document  
            $autre_types_document
            $type_bien    
       
                              
    		<div class="text-center"><button type="submit" class="btn-custom3">Étape suivante</button></div>
    	</form>
EOH
      # $commande_id
      # $token_commande         
      # id_member - $member{id}   <br>
      # type_member - $member{type_member}    
    return $page_1;            
}

#############################################################################
# commande_etape_1_db
#############################################################################
sub commande_etape_1_db
{   
    my $is_immeuble = $cgi->param('id_type_bien'); 
    my $token_commande = get_quoted('token');
    
    if($is_immeuble != 5)
    {
        #tableau des data de la commande   
        my %commande_update = ();             
        my %commande_doc_update = ();                



		
        #verification des cookie  
        my %hash_order = ();
        my $cookie_order = $cgi->cookie('certigreen_handmade');
        my %member = ();
        
        #si cookie existe on trouve ID d'user pour le mettre dans la commande
        if($cookie_order ne "")
        {
            $cookie_order_ref=decode_json $cookie_order;
            %hash_order=%{$cookie_order_ref};
            
            #on trouve id du member 
            %member = sql_line({dbh=>$dbh2,table=>'members',where=>"token='$hash_order{token_member}'"}); 
            #on met id du membre dans le tableau de la commande
            
			if($member{type_member} eq 'Agence')
			{
				#si agence, on remplit l'id agence
				$commande_update{id_member_agence} = $member{id};
			}
			else
			{
				#si particulier, on remplit l'id_member
				$commande_update{id_member} = $member{id};
			}
        } 

        $commande_update{type_bien_id} = $cgi->param('id_type_bien');
        sql_set_data({debug=>0,dbh=>$dbh2,table=>'intranet_factures',data=>\%commande_update, where=>"token='$token_commande'"});
        my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});

        #verifie s'il y a déjà des enregistrements  
        $stmt = "DELETE FROM commande_documents WHERE commande_id='$commande{id}'";
        execstmt($dbh2,$stmt);
                       
        
        $commande_doc_update{commande_id} = $commande{id};
				
		#enregistrement des documents
        my @autre_type_documents = $cgi->param('type_document_id');
        my %commande_autre_doc_update = (); 
        $commande_autre_doc_update{commande_id} = $commande{id};
        foreach $id_doc (@autre_type_documents)
        {
             $commande_autre_doc_update{type_document_id} = $id_doc;
             sql_set_data({debug=>0,dbh=>$dbh2,table=>'commande_documents',data=>\%commande_autre_doc_update}); 
        }
        
        #enregistrement des autres documents
        my @autre_type_documents = $cgi->param('id_autre_type_document');
        my %commande_autre_doc_update = (); 
        $commande_autre_doc_update{commande_id} = $commande{id};
        foreach $id_doc (@autre_type_documents)
        {
             $commande_autre_doc_update{type_document_id} = $id_doc;
             sql_set_data({debug=>0,dbh=>$dbh2,table=>'commande_documents',data=>\%commande_autre_doc_update}); 
        }
                
        #si user est connecté
        if($hash_order{token_member} ne "")
        {
           #si user est une Agence il choisie un client
           if($member{type_member} eq 'Agence')
           {    #print "Agence";
              cgi_redirect("$full_self&sw=commande_etape&go_to_step=3&token=$token_commande");
           }
           else
           {       #   print "Part";
              cgi_redirect("$full_self&sw=commande_etape&go_to_step=3&token=$token_commande");
           }
           
        }
        #si user n'est pas connecté
        else
        {     
           cgi_redirect("$full_self&sw=commande_etape&go_to_step=2&token=$token_commande");
        }
    }
    else
    {
#        see(); print "Immeuble";
        cgi_redirect("$full_self&sw=commande_etape&go_to_step=immeub_apparte&token=$token_commande");
    }
    
}

#############################################################################
# get_detail_commande
#############################################################################
sub get_detail_commande
{
    see();  
	my $cookie_order = $cgi->cookie('certigreen_handmade');  		
	
	#si pas cookie
	if($cookie_order eq '')       
    { 
		http_redirect("$full_self&sw=connexion&ret=espace_perso"); 
		exit;
	}
	$cookie_order_ref=decode_json $cookie_order;
    my %hash_member=%{$cookie_order_ref}; 
	
	my %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});  
	
	#si pas connecte
	if(!($member{id} > 0))       
    { 
		http_redirect("$full_self&sw=connexion&ret=espace_perso"); 
		exit;
	}
	
           
    #si user est connecté
    if($cookie_order ne "")       
    {                  
        my %hash_member;       
        my %member = ();
        
        $cookie_order_ref=decode_json $cookie_order;
        %hash_member=%{$cookie_order_ref};    
        
        if($hash_member{token_member} ne '')
        {
            %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});  
            
            my $token_commande = get_quoted('token');                                   
            my %commande = sql_line({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
              
            
            ####################   DETAILS D'EXPERTISE      #########################                        
            my $table_details = '<table class="table table-bordered table-striped" id="table_details">';
            
            #EXPERTISES-------------------------------
            my @commande_documents = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'commande_documents',where=>"commande_id='$commande{id}'"});   
            my @types_document = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'types_document'});
            my $list_documents = '';
            
            foreach my $document (@commande_documents)
            {
                 my %document = %{$document};
                 foreach my $one_type (@types_document)
                 {
                      my %one_type = %{$one_type};
                      if($one_type{id} == $document{type_document_id})
                      {
                           $list_documents .= $one_type{type_1}."<br>"; 
                      }
                 }
            }
            
            $table_details .= << "EOH";
               	<tr>
                     <td style="width:50%;"><b>Expertise(s) souhaitée(s)</b></td> 
                     <td style="width:50%;">$list_documents</td>
                </tr>
EOH
            
            #TYPE BIEN-------------------------------
            my @types_bien = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'types_bien'});
            my $nom_type_bien = '';             
            foreach my $type_bien_commande (@types_bien)
            {
                my %type_bien_commande = %{$type_bien_commande};
                if($commande{id_type_bien} == $type_bien_commande{id})
                {
                     $nom_type_bien .= $type_bien_commande{type_1}; 
                }
            }
            $table_details .= << "EOH";
               	<tr>
                     <td style="width:50%;"><b>Type de bien</b></td>
                     <td style="width:50%;">$nom_type_bien</td>
                </tr>
EOH
            #ADRESSE-------------------------------                
            $table_details .= << "EOH";
               	<tr>
                     <td style="width:50%;"><b>Adresse</b></td>
                     <td style="width:50%;">$commande{adresse_rue} $commande{adresse_numero} </td>
                </tr>
EOH
            #CODE POSTAL-------------------------------                
            $table_details .= << "EOH";
               	<tr>
                     <td style="width:50%;"><b>Code postal</b></td>
                     <td style="width:50%;">$commande{adresse_cp}</td>
                </tr>
EOH
            #VILLE-------------------------------                
            $table_details .= << "EOH";
               	<tr>
                     <td style="width:50%;"><b>Ville</b></td>
                     <td style="width:50%;">$commande{adresse_ville}</td>
                </tr>
EOH
            #CLE DISPONIBLE-------------------------------  
            my $cle = 'Non';
            if($commande{cle_disponible} eq 'y')
            {
                $cle = 'Oui';
            }              
            $table_details .= << "EOH";
               	<tr>
                     <td style="width:50%;"><b>Clés disponibles</b></td>
                     <td style="width:50%;">$cle</td>
                </tr>
EOH
            $table_details .= "</table>"; 
                    
            
        ####################   DATES SOUHAITEES      #########################                        
            # my $table_dates = '<table class="table table-bordered" id="table_details">';
            
            # my @dates_commande = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'commande_dates',where=>"commande_id=$commande{id}"});   
            
            # $table_dates .= << "EOH";
               	# <tr>
                     # <th>Date</th> 
                     # <th>Moment de visite</th>
                # </tr>
# EOH
            
            # foreach my $date (@dates_commande)
            # {
                 # my %date = %{$date};
                 # my $time = "Matin";
                 
                 # if($date{commande_time} eq 'nimporte')
                 # {
                    # $time = "Peu importe"; 
                 # }
                 # elsif($date{commande_time} eq 'apresmidi')
                 # {        
                    # $time = "Après-midi"; 
                 # } 
                 
                 # $table_dates .= << "EOH";
               	# <tr>
                     # <td>$date{commande_date}</td> 
                     # <td>$time</td>
                # </tr>
# EOH
            # }
            
            # $table_dates .= "</table>";   
            
        ####################   COORDONNEES FACTURATION    #########################                        
            my $table_facturation = '<table class="table table-bordered table-striped" id="table_details">';
            my %coord_facture = ();
            
            %coord_facture = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"id='$commande{id}'"});
            # see(\%coord_facture);
            $table_facturation .= << "EOH";
               	<tr>
                     <td style="width:50%;"><b>Nom</b></td> 
                     <td style="width:50%;">$coord_facture{facture_nom}</td>
                </tr>
                <tr>
                     <td style="width:50%;"><b>Prénom</b></td> 
                     <td style="width:50%;">$coord_facture{facture_prenom}</td>
                </tr>
                <tr>
                     <td style="width:50%;"><b>Adresse</b></td> 
                     <td style="width:50%;">$coord_facture{facture_street} $coord_facture{facture_number} </td>
                </tr>
                <tr>
                     <td style="width:50%;"><b>Code postal</b></td> 
                     <td style="width:50%;">$coord_facture{facture_zip}</td>
                </tr>      
                <tr>
                     <td style="width:50%;"><b>Ville</b></td> 
                     <td style="width:50%;">$coord_facture{facture_city}</td>
                </tr>
                
EOH
            $table_facturation .= "</table>"; 
            
             
            
            
            
            my $page = <<"EOH";
		<script type="text/javascript">
			jQuery(document).ready( function () 
			{                   
					
				init_form();
		  
		   });
		</script>
			
		<section class="parag_content parag_form">
        <div class="row">
			<div class="col-md-8 col-sm-12 col-xs-12 col-md-offset-2 members_form"> 
				<h1 class="text-center">Détail sur l\'expertise</h1> 
				$table_details
				<h1 class="text-center">Coordonnées de facturation</h1> 
				$table_facturation		
				<div class="text-center"><a href="$self&sw=espace_perso" class="btn-custom3">Retour</a></div>
          </div>
		</div>
		</section>
EOH
            
              #print $page; exit;
            display($page);
        }
    }
    else
    {
       #cgi_redirect("$full_self&sw=commande_etape&go_to_step=2&token=$token");
    }
}

################################################################################
# commande_etape_immeub_apparte
################################################################################
sub commande_etape_immeub_apparte
{
     see();
     my $page = <<"EOH";
      	<script type="text/javascript">
      		jQuery(document).ready( function () 
      		{                   
          			
                init_form();
          
      	   });
        </script>
        
        <div class="row">
    			<div class="col-md-12">
				<br>
              <p>Pour une demande qui concerne un immeuble à appartements, 
                  
				  <br><br>veuillez nous contacter: <br>
                  <br>Par téléphone : +32 (0)4 388 12 94
                  <br>ou par email : <a href="mailto:info\@certigreen.be">info\@certigreen.be</a>
              </p>
          </div>
    		</div>
EOH
      return $page; 
     
     
}


sub edit_infos
{
	see();
	my $token = get_quoted('token') || '';
   
	my %client = sql_line({dbh=>$dbh2,table=>'members',where=>"token='$token' and token != ''"});
	# exit;
	delete $client{password};
	delete $client{token};
	
	
	my $info_personnel = get_form_line
	(
		{
			type => 'list_inputs',
			name => 'firstname,lastname,tel,street,number,zip,city,email,email2,password,password2', 
			label =>'Prenom,Nom,Téléphone,Rue,Numero,Code postal,Ville,Email,Confirmez votre email,Mot de passe,Confirmez votre mot de passe',
			required=>'required,required',
			suffix=>'*,*,,,,,,*,*,*,*',
			vals => \%client,
			no_clean_order=>1,
		}   
	);
	
	my $form = <<"EOH";
		<section class="parag_content parag_form">
        <div class="row">
			<div class="col-md-8 col-sm-8 col-xs-12 col-md-offset-2 col-sm-offset-2 members_form"> 
              <h1 class="text-center">Vos coordonnées</h1> 
			  <form method="post" id="loginform"  action="$full_self" class="form-horizontal" role="form" style="padding-top:0px;">
              		<input type="hidden" name="lg" value="$lg" />
              		<input type="hidden" name="from" value="$sw" />
					<input type="hidden" name="token" value="$token" />
					<input type="hidden" name="sw" value="edit_infos_db" />  
					
					$info_personnel 
					<div class="form-group text-right">
						<div class="col-md-12">
							<button type="submit" class="btn-custom3 add_expertise">Valider</button>
						</div>
            		 </div>
            	</form>                          
          </div>
		</div>
		</section>   
EOH

	display($form);
}

sub edit_infos_db
{
	my @fields = ('lastname','firstname','tel','street','number','zip','city','email','email2','password','password2','token');  
    my %update_member = ();  
	
	foreach my $f (@fields)
    {
        my $value = get_quoted($f);
        $update_member{$f} = trim($value);
    }  
	
	if($update_member{email} ne $update_member{email2} && $update_member{email} ne '')
	{
		delete $update_member{email};
	}
	delete $update_member{email2};
	
	if($update_member{password} ne $update_member{password2} && $update_member{password} ne '')
	{
		delete $update_member{password};
	}
	delete $update_member{password2};

    my $token = $update_member{token};
	delete $update_member{token};
	
	updateh_db($dbh_data,"members",\%update_member,'token',$token);
	
	cgi_redirect($full_self.'&sw=edit_infos_ok');
}

################################################################################
# commande_etape_2
################################################################################
sub commande_etape_2
{
    see();
    
    my $token_commande = get_quoted('token');   
    my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
    
    my $cookie_order = $cgi->cookie('certigreen_handmade');
         
    my %member = ();       
    #si user est connecté
    if($cookie_order ne "")       
    {                  
        my %hash_member;  
        
        $cookie_order_ref=decode_json $cookie_order;
        %hash_member=%{$cookie_order_ref};    
        
        if($hash_member{token_member} ne '')
        {
            %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});  
        }
    }
                        
    #INFO PERSONNELLE------------------------------------------------------------
    my @vals_name = ('firstname','lastname','tel','street','number','zip','city','email','email2','password','password2');  
    my %vals =();
                            
    if($member{id}>0)
    {
        my $i = 1; 
        foreach my $name (@vals_name)
        {
            my $y = sprintf("%02d",$i++);
            
            while (($key, $value) = each (%member))
            {
                if($name eq $key)
                {   
                    $vals{$y.'/'.$name} = $value;
                }
            } 
            
            if($name eq 'email2' || $name eq 'password2')
            {
                $vals{$y.'/'.$name} = '';
            }           
        }
    }   
     
    my $info_personnel = get_form_line(
                            {
                                type => 'list_inputs',
                                name => 'firstname,lastname,tel,street,number,zip,city,email,email2,password,password2', 
                                label =>'Nom,Prenom,Téléphone,Rue,Numero,Code postal,Ville,Email,Confirmez votre email,Mot de passe,Confirmez votre mot de passe',
                                required=>',required',
                                suffix=>',*,,,,,,*,*,*,*',
                                vals => \%vals,
                            }   
                        );
                        
    
    
    #MAIL_PASS------------------------------------------------------------                    
    my $mail_pass = get_form_line(
                            {
                                type => 'list_inputs',
                                name =>'email,password', 
                                label =>'Email,Mot de passe',
                                required=>'required,required',
                                suffix=>'',
                            }   
                        );
                        
    #TYPE AGENCE------------------------------------------------------------                        
    my $type_membre = get_form_line(
                            {
                                type => 'btns-group',
                                name =>'type_member', 
                                label =>'',
                                checked_val=> 'Particulier',
                                style=>"",
                                vals =>
                                {                           
                                    '02/Particulier'=>"Non",
                                    '01/Agence'=>"Oui",
                                },
                            }
                        );                               
                              
                                      
    my $page = <<"EOH";
      	<script type="text/javascript">
      		jQuery(document).ready( function () 
      		{                   
          			
                init_form();
          
      	   });
        </script>
		
          
    	      
        <hr />
        <div class="row">
			<div class="col-md-6 col-sm-12 col-xs-12">
				<h2 class="text-center" style="font-size:25px;">Vos coordonnées</h2>
				<p class="text-center">Vous n\'avez pas encore de compte ? <br> Créer en un dès maintenant:</p>
				<form method="post"  action="$full_self" class="form-horizontal" role="form">
              		<input type="hidden" name="lg" value="$lg" />
              		<input type="hidden" name="from" value="$sw" />
					<input type="hidden" name="sw" value="membre_db" />            
              		<input type="hidden" name="token" value="$token_commande" />

                    $info_personnel
					
                    <small><p id="explain" class="text-center">Cette adresse e-mail vous servira d\'identifiant pour vous connecter</p></small>                                 
                     
					<div class="type_agence">
							<label for="type_agence" class="col-md-12 control-label" style="text-align:center;">Êtes-vous une agence ou un notaire ?</label>
							<div class="text-center">$type_membre</div>
					</div>
                     
					<div class="text-center"><button type="submit" class="btn-custom3 add_expertise">Inscription</button></div>
            	</form>
			</div>     
			<div class="col-md-6 col-sm-12 col-xs-12">
				<h2 class="text-center" style="font-size:25px;">Connexion <span>(étape 2/4)</span></h2>
				<p class="text-center">Vous avez déjà un compte ? <br> Connectez-vous ci-dessous:</p> 
				<form method="post"  action="$full_self" class="form-horizontal" role="form">
              		<input type="hidden" name="lg" value="$lg" />
              		<input type="hidden" name="from" value="$sw" />
					<input type="hidden" name="ret" value="commande_etape&go_to_step=3&token=$token_commande" />   
					<input type="hidden" name="errret" value="commande_etape&go_to_step=2&token=$token_commande" />   
					<input type="hidden" name="sw" value="login_db" />   
              		<input type="hidden" name="token" value="$token_commande" />
                  
                    $mail_pass      
					<!--<p><a href="#" class="disabled btn btn-link">Mot de passe perdu ?</a></p>-->
                      
					<div class="text-center"><button type="submit" class="btn-custom3 add_expertise">Connexion</button></div>
            			
            	</form>
                        
			</div>
		</div>
EOH
      return $page; 
}


################################################################################
# connexion
################################################################################
sub connexion
{
    see();
    my $retour = get_quoted('ret');
    my $message = get_quoted('mess');
    my $avertir_invisible = "";
    if($message eq 'invis')
    {
		my $dest = "info\@certigreen.be";
        $avertir_invisible=<<"EOH";
            <div id="err_champs" class="alert alert-warning text-center" role="alert">
				<small><strong>Vous n'avez pas le droit d'accès.</Strong><br />Veuillez contacter l'administrateur du site :
                <a href="mailto:$dest" target="_blank" tabindex="0" rel="noreferrer">$dest</a></small>
            </div>  
			
EOH
    }  
	if($message eq 'pass')
    {
		my $dest = "info\@certigreen.be";
        $avertir_invisible=<<"EOH";
            <div id="err_champs" class="alert alert-warning text-center" role="alert">
				<small><strong>Votre mot de passe n'est pas correct.</Strong><br />Veuillez contacter l'administrateur du site :
                <a href="mailto:$dest" target="_blank" tabindex="0" rel="noreferrer">$dest</a></small>
            </div>  
			
EOH
    }  
    #MAIL_PASS------------------------------------------------------------                    
    my $mail_pass = get_form_line(
                            {
                                type => 'list_inputs',
                                name =>'email,password', 
                                label =>'Email,Mot de passe',
                                required=>'required,required',
                                suffix=>'',
                            }   
                        );
                        
    my $page = <<"EOH";
      	<script type="text/javascript">
      		jQuery(document).ready( function () 
      		{                
                init_form();
      	  });
        </script>
        
		<section class="parag_content parag_form">
        <div class="row">
			<div class="col-md-6 col-sm-8 col-xs-12 col-md-offset-3 col-sm-offset-2 members_form"> 
              <h1 class="text-center">Connectez-vous pour accéder à Certigreen</h1> 
              <form method="post" id="loginform"  action="$full_self" class="form-horizontal" role="form" style="padding-top:0px;">
              		<input type="hidden" name="lg" value="$lg" />
              		<input type="hidden" name="from" value="$sw" />
					<input type="hidden" name="sw" value="login_db" />   
              		<input type="hidden" name="token" value="$token_commande" />
              		<input type="hidden" name="ret" value="$retour" />
					<input type="hidden" name="sw_retour_si_erreur" value="connexion" />
					
					$avertir_invisible
					$mail_pass 
					<div class="form-group text-right">
						<div class="col-md-12">
							<button type="submit" class="btn-custom3 add_expertise">Connexion</button>
							<br />
							<small><a href="$full_self&sw=lost_password_form">Mot de passe perdu ?</a></small>
						</div>
            		 </div>
            	</form>                          
          </div>
		</div>
		</section>
EOH
      display($page);
     exit;  
}



################################################################################
# membre_db
################################################################################
sub membre_db
{
    my @fields = ('firstname','lastname','tel','street','number','zip','city','email','password','type_member'); 
    my $token_commande = get_quoted('token');  
    my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
    my $commande_id = $commande{id};
    
    my %membre = ();    

	my %check_email = sql_line({select=>"id",table=>"members",where=>"email='$item{email}'"});
	if($check_email{id} > 0)
	{
		 see();
		 print <<"EOH";
                      		<script language="javascript">
                      		alert("Un compte existe déjà pour cette adresse email. Vous pouvez vous connecter directement sur celui-ci ou récupérer le mot de passe si vous l'avez oublié.");
                      		history.go(-1);
                      		</script>
EOH
                  exit;
	
	
	}
	
    
    foreach my $f (@fields)
    {
        my $value = get_quoted($f);
        $membre{$f} = trim($value);   
    }      
    
    #creation du token
    $membre{token} = create_token(100);
    #enregistrement du membre dans la DB
    $membre{id} = inserth_db($dbh2,'members',\%membre);
    
    #mise des cookies dans browser
    login_db($membre{token});
}

           
################################################################################
# commande_etape_2bis
################################################################################
sub commande_etape_2bis
{
    see(); 
    my $token_commande = get_quoted('token');        
    
    my $cookie_order = $cgi->cookie('certigreen_handmade');
           
    #si user est connecté
    if($cookie_order ne "")       
    {                    
        my %hash_member;       
        my %member = ();
        
        $cookie_order_ref=decode_json $cookie_order;
        %hash_member=%{$cookie_order_ref};
        
        my %commande = sql_line({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
        my %member = sql_line({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'members',where=>"token='$hash_member{token_member}'"});
                                                                                                 
        #INFO PERSONNELLE------------------------------------------------------------
        my $info_personnel = get_form_line(
                              {
                                  type => 'list_inputs',
                                  name =>'nom_dossier,lastname,firstname,tel,street,number,zip,city,email', 
                                  label =>'Info dossier,Nom,Prenom,Téléphone,Rue,Numero,Code postal,Ville,Email',
                                  required=>'required,required,',
                                  suffix=>'*,*,,,,,,,',   
                                  size_col_label => 3,
                                  size_col_field => 9,    
                                  style=>'margin-bottom:10px;',   
                              }   
                          ); 
        
        
        #LISTE CLIENTS------------------------------------------------------------                  
        my $liste_clients = '<p>Aucun client enregistré.</p>';                           
		# c.id='$commande{id}' AND
		
      #  my @agence_clients = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'members',where=>"id_agence='$member{id}'",ordby=>"lastname",});
        my @all_clients_commandes = sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members m, intranet_factures c',where=>" ((c.visible='y' and c.validation = 1) OR '$commande{id}' = c.id ) AND c.id_member=m.id AND m.id_agence='$member{id}'"});
      
        my %vals = ();
        my $lines_clients = '';
        foreach $one_client_dossier(@all_clients_commandes)
        {
           my %one_dossier = %{$one_client_dossier};            
           $vals{$one_dossier{id}.'/'.$one_dossier{id}} = "<b>".$one_dossier{lastname}."</b> ".$one_dossier{firstname}." (".$one_dossier{nom_dossier}.")</span>";  
            
        } 
          # print $one_dossier{id_member}." ".$one_dossier{id}." ".$one_dossier{nom_dossier}."<br>";  
         # print Dumper(@all_clients_commandes); exit;                                   
        #si les dossiers des clients d'agence existent
        if(scalar(@all_clients_commandes) != 0)
        {
            $liste_dossiers = '<p>Sélectionnez un dossier et cliquez sur étape suivante.</p>';
            $lines_dossiers = get_form_line(
                                              {
                                                  type => 'btns-group',
                                                  name =>'agence_client', 
                                                  label => '',
                                                  checked_val=> $commande{id},
                                                  style=>'margin-bottom:10px; height:auto!important;',        
                                                  vals => \%vals,
                                                  size_col_field => 12,
                                              }
                                          );           
        }
        
                         
                        
          my $page = <<"EOH";
          	<script type="text/javascript">
          		jQuery(document).ready( function () 
          		{     
                    init_form();
                    init_step_2bis();
          	   });
          </script>
          
          <div class="">                           
              <div id="err_champs" class="alert alert-warning" role="alert">Veuillez compléter les champs avec une *</div>    
              
              <div class="left">      
                  <h3>Ajouter un dossier client</h3>
                  <div id="new_client">
                      $info_personnel
                  </div>  
                  <input type="hidden" id="token_member" value="$member{token}" />           
                  <input type="hidden" id="token" name="token" value="$token_commande" />     
                  <button type="button" class="btn btn-primary add_dossier">Ajouter </button> 
              </div> 
              
            	<div class="right">  
                  <form method="post"  action="$full_self" class="form-horizontal" role="form">
                  		<input type="hidden" name="lg" value="$lg" />
                  		<input type="hidden" name="from" value="$sw" />
                      <input type="hidden" name="sw" value="commande_etape_2bis_db" />            
                  		<input type="hidden" name="token" value="$token_commande" />     
                      
                    
                      <h3>Liste de vos dossiers client</h3>  
                      <div id="table_clients_agence">   
                          <div id="avertir_dossier_cree"></div> 
                          $liste_dossiers 
                           $lines_dossiers
                      </div>  
					
				
                      
                      <button type="button" class="btn btn-primary btn-lg averti_choix_client">Étape suivante</button>
                	</form>		
               </div>  
      		</div>
EOH
        return $page;    
    }
    else
    {
      print 'pas connecte';
    }      
}   

################################################################################
# ajout_client
################################################################################
sub ajout_client
{
    see();             
    my $token_commande = get_quoted('token');   
    my $envoie_facture = get_quoted('envoie_facture');       
    
    my $cookie_order = $cgi->cookie('certigreen_handmade');
    
    my %commande = sql_line({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
    my %member = sql_line({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'members',where=>"id='$commande{id_member}'"});
    
    my @fields = ('lastname','firstname','tel','street','number','zip','city','email');  
    
    my %new_member = ();  
      
    foreach my $f (@fields)
    {
        my $value = get_quoted($f);
        $new_member{$f} = trim($value);
    }      
    
    $new_member{id_agence} = $member{id}; 
    $new_member{token} = create_token(100);; 
           
    sql_set_data({debug=>0,dbh=>$dbh2,table=>'members',data=>\%new_member});     
   
#     print $envoie_facture;  

    http_redirect("$full_self&sw=commande_etape&go_to_step=2bis&token=$token_commande&member=$member{token}&env_fact=$envoie_facture");
   
}

#############################################################################
# commande_etape_2bis_db
#############################################################################
sub commande_etape_2bis_db
{
    see();
    my $cookie_order = $cgi->cookie('certigreen_handmade');
           
    #si user est connecté
    if($cookie_order ne "")       
    {                  
        my %hash_member;       
        my %member = ();
        
        $cookie_order_ref=decode_json $cookie_order;
        %hash_member=%{$cookie_order_ref};    
        
        if($hash_member{token_member} ne '')
        {
            %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});  
            
            my $token_commande = get_quoted('token_commande'); 
            my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
            
            #si c'est un Agence
            if ($member{type_member} eq "Agence")
            {
                 my $commande_id_choisi =  $cgi->param('agence_client');   
                 my $token_commande =  $cgi->param('token_commande'); 
#                  print  $commande_id_choisi;
#                  print  $token_commande;    exit;
                 #si le dossier n'a pas été choisi on retourne à la page 
                 if($commande_id_choisi eq '' )
                 {     
                      print 'sw=commande_etape&go_to_step=2bis&token='.$token_commande;
                     # cgi_redirect("$full_self&sw=commande_etape&go_to_step=2bis&token=$token_commande");
                 }
                 else
                 {    
                     my %update_commande = (); 
                     my %dossier_choisi = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"id='$commande_id_choisi'"});
                     
                     if($dossier_choisi{token} eq $token_commande)  # c'est signifie que on crée la novelle commande (dossier)
                     {
#                         print "eqal";    exit;
                        print 'sw=commande_etape&go_to_step=3&token='.$token_commande; 
                      #   cgi_redirect("$full_self&sw=commande_etape&go_to_step=3&token=$token_commande");
                     }
                     else     # c'est signifie que on fait un ajout dans la commande (dossier) qui déjà exist
                     {
                        print "not equal";   # exit;
                        #alors on cherche dans la commande vient d'enregistrée des documents désirés 
#                         my @docs_new_commande = sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',where=>"commande_id='$commande{id}'"});
# #                          print Dumper(@docs_new_commande); exit;        
#                         foreach my $one_doc (@docs_new_commande)
#                         {
#                             my %one_doc = %{$one_doc};    
#                             
#                             #on verifie si le type_document_id n'exist pas déjà dans la commande qui a été créee avant: s'il n'exist pas => on fait update : change id de la commande 
#                             my %doc_exist = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',where=>"commande_id='$commande_id_choisi' AND type_document_id='$one_doc{type_document_id}'"});
#                             if ($doc_exist{id} == 0 )
#                             {
# #                                 print "n'exist pas "; 
#                                 $update_commande{commande_id} = $commande_id_choisi;   
#                                 $update_commande{type_document_id} = $one_doc{type_document_id};
# #                                 print $one_doc{type_document_id}." ".$commande{id};  
#                                 sql_set_data({debug=>0,dbh=>$dbh2,table=>'commande_documents',data=>\%update_commande});
#                             }
#                             else
#                             {
# #                                 print "document exist "; 
# #                                 $stmt = "DELETE FROM commande_documents WHERE commande_id='$commande{id}' AND type_document_id='$one_doc{type_document_id}'";
# #                                 execstmt($dbh2,$stmt);
#                             }
#                         }                                                                                               
# #                             exit;
#                             $token_commande = $dossier_choisi{token};
                            
                     }      
#                         exit;
                     
                              
                   # cgi_redirect("$full_self&sw=commande_etape&go_to_step=3&token=$token_commande");   
                }                   
            }
        }
    }            
}


#############################################################################
# commande_etape_3
#############################################################################
sub commande_etape_3
{
    see();
    
    my $cookie_order = $cgi->cookie('certigreen_handmade');
           
    #si user est connecté
    if($cookie_order ne "")       
    {                  
        my %hash_member;       
        my %member = ();
        
        $cookie_order_ref=decode_json $cookie_order;
        %hash_member=%{$cookie_order_ref};    
        
        if($hash_member{token_member} ne '')
        {
            %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"}); 

            
            my $token_commande = get_quoted('token');                                   
            my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
            # see(\%commande);
            #COORDONNEES DU BIEN------------------------------------------------------------
            my @names_fields = ('adresse_rue','adresse_numero','adresse_cp','adresse_ville');
            my %vals = ();
            my $i = 1;
            foreach my $name (@names_fields)
            {                  
                my $y = sprintf("%02d",$i++);
                while (($key, $value) = each (%commande))
                {
                     if($name eq $key)
                     {
                          $vals{ $y.'/'.$name } = $value;
                     }
                }
            }
            
            my $coordonnees_bien = get_form_line(
                                  {
                                      type => 'list_inputs',
                                      name =>'adresse_rue,adresse_numero,adresse_cp,adresse_ville', 
                                      label =>'Rue,Numero,Code postal,Ville',
                                      required=>'required,required,required,required',
                                      suffix=>'*,*,*,*',
                                      vals => \%vals,
                                  }   
                              );
            
            #TYPE AGENCE------------------------------------------------------------                   
            my $cles_disponibles = "";
            
            if ($member{type_member} eq 'Agence')
            {
                $cles_disponibles = get_form_line(
                                  {
                                      type => 'btns-group',
                                      name =>'cle_disponible', 
                                      label =>"Clés disponible à l'étude/agence ?",
                                      size_col_label => 5,
                                      checked_val=> $commande{cle_disponbile},
                                      style=>"",
                                      vals =>
                                      {
                                          '01/y'=>"Oui",
                                          '00/n'=>"Non",
                                      }
                                  }
                              );     
            }                     
            
            #PERSONNE DE CONTACT------------------------------------------------------------
            my @names_fields = ('contact_nom');
            # my @names_fields = ('contact_nom','contact_prenom','contact_tel','contact_email');
            my %vals = ();
            my $i = 1;
            foreach my $name (@names_fields)
            {                  
                my $y = sprintf("%02d",$i++);
                while (($key, $value) = each (%commande))
                {
                     if($name eq $key)
                     {
                          $vals{ $y.'/'.$name } = $value;
                     }
                }
            }
            # my $personne_contact = get_form_line(
                                  # {
                                      # type => 'list_inputs',
                                      # name =>'contact_nom,contact_prenom,contact_tel,contact_email', 
                                      # label =>'Nom / Téléphone,Prenom,Téléphone,E-mail',
                                      # vals => \%vals,
                                  # }   
                              # );
    my $personne_contact = get_form_line(
                                  {
                                      type => 'list_inputs',
                                      name =>'remarque', 
                                      label =>'Nom / Téléphone / Remarque',
                                      vals => \%vals,
                                  }   
                              );							  
                              
                              
            #DEFINISSION DATE--------------------------------------------------------------
            my $definissez_date = get_form_line(
                                  {
                                      type => 'input',
                                      name => 'disponibilite_date', 
                                      label => '',
                                      value => 'Cliquez ici pour sélectionner des dates',     
                                      size_col_field => 12,
                                      class => "avec_datepicker",
                                  }   
                              );           
                              
            #TABLEAU DES DATES--------------------------------------------------------------        
            my $recap_dates = '';       
            my $table_days = '';
            my $verif_date = '';
            my %noms_mois = ();
               $noms_mois{'01'} = 'janvier';
               $noms_mois{'02'} = 'février';
               $noms_mois{'03'} = 'mars';
               $noms_mois{'04'} = 'avril';
               $noms_mois{'05'} = 'mai';
               $noms_mois{'06'} = 'juin';
               $noms_mois{'07'} = 'juillet';
               $noms_mois{'08'} = 'août';
               $noms_mois{'09'} = 'septembre';
               $noms_mois{'10'} = 'octobre';
               $noms_mois{'11'} = 'novembre';
               $noms_mois{'12'} = 'décembre';
                      
            # my @dispo_dates = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'commande_dates',where=>"commande_id=$commande{id}",ordby=>"commande_date ASC"});
            # if ($#dispo_dates != -1)
            # {
                   
                # $recap_dates = '<p><b>RÉCAPITULATIF DE VOS DATES</b></p>';
                                                  
                # $table_days = '<div id="table_days_container">';    
                # foreach my $dispo_date (@dispo_dates)
                # {   
                    # my %dispo_date = %{$dispo_date};
                    
                    # my ($jour,$mois,$annee) = split (/\//,$dispo_date{commande_date}); 
                    # my $arrange_date =  $jour." ".$noms_mois{$mois}." ".$annee;
                    
                    # my $btns_time = get_form_line(
                                  # {
                                      # type => 'btns-group',
                                      # name =>'time_commande', 
                                      # label =>'',
                                      # size_col_label => 12,
                                      # checked_val=> $dispo_date{commande_time}, #'apresmidi',
                                      # style=>"",
                                      # vals =>
                                      # {
                                          # '01/matin'=>"Matin",
                                          # '02/apresmidi'=>"Après-midi",  
                                          # '03/nimporte'=>"Peu importe",
                                      # }
                                  # }
                              # );
                              
                    # $table_days .= << "EOH";
                        # <div class="col-xs-11">
                            # <span style="font-weight: bold;font-size: 14px; text-transform: capitalize;">$arrange_date</span>
                            # <button id="$dispo_date{id}" type="button" class="btn-link supprim_date"><span style="color:red;">X</span></button>
                        # </div>
                        
                        # <div id="$dispo_date{id}" class="col-md-12 one_day" style="">
                            # $btns_time
                        # </div>
                    # <hr style="margin-top: 10px;">
# EOH
                # }
                # $table_days .= "</div>";     
                # $verif_date = "<input type='text' name='date_valable' value='' />";                              
            # }
            # else
            # {
                # $recap_dates =  "<p>Aucune date n'est pas enrégistrée.</p>";
                # $verif_date = "<input type='text' name='date_valable'  value='' />"; 
                
            # }     
            
            #REMARQUE------------------------------------------------------------
#             print $commande{remarque};
            # my $remarque = get_form_line(
                                  # {
                                      # type => 'textarea',
                                      # name => 'remarque', 
                                      # label =>'Remarque', 
                                      # size_col_label => 5,    
                                      # style => '',    
                                      # size_col_field =>7,
                                      rows => 5,
									                    # value=> $commande{remarque},
                                  # }
                              # );
            
                                
                #COORDONNEES DU BIEN------------------------------------------------------------
			my %cmember = sql_line({dbh=>$dbh2,table=>'members',where=>"id='$commande{id_member}'"});
			
			my $email_bloc = <<"EOH";
			 <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_email ">
                              <label class="col-md-5 control-label" for="email">Email <span></span></label>
                              <div class="col-md-7">
                                   <input type="email" class=" form-control" style="margin-bottom:10px;" value="$cmember{email}" name="email" data-role="">
                              </div>
                          </div>
                      </div>
EOH
	
			if ($member{type_member} ne 'Agence')
            {
			
$email_bloc = <<"EOH";
			 <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_email ">
                              <label class="col-md-5 control-label" for="email">Email <span></span></label>
                              <div class="col-md-7">
                                   <input type="email" class=" form-control" style="margin-bottom:10px;" value="$cmember{email}" name="dum" disabled = "disabled" data-role="">
                              </div>
                          </div>
                      </div>
EOH
			}
			
			
			my $coordonnees_client =  <<"EOH";
			<div id="new_client">
                                            <!--
											<div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_nom_dossier ">
                              <label class="col-md-5 control-label" for="nom_dossier">Info dossier <span>*</span></label>
                              <div class="col-md-7">
                                   <input type="text" class=" form-control" style="margin-bottom:10px;" value="$cmember{lastname} $cmember{firstname}" name="nom_dossier" data-role="" required="">
                              </div>
                          </div>
                      </div>
					  -->
                      <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_lastname ">
                              <label class="col-md-5 control-label" for="lastname">Nom <span>*</span></label>
                              <div class="col-md-7">
                                   <input type="text" class=" form-control" style="margin-bottom:10px;" value="$cmember{lastname}" name="lastname" data-role="" required="">
                              </div>
                          </div>
                      </div>
                      <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_firstname ">
                              <label class="col-md-5 control-label" for="firstname">Prenom <span></span></label>
                              <div class="col-md-7">
                                   <input type="text" class=" form-control" style="margin-bottom:10px;" value="$cmember{firstname}" name="firstname" data-role="" >
                              </div>
                          </div>
                      </div>
                      <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_tel ">
                              <label class="col-md-5 control-label" for="tel">Téléphone <span></span></label>
                              <div class="col-md-7">
                                   <input type="text" class=" form-control" style="margin-bottom:10px;" value="$cmember{tel}" name="tel" data-role="">
                              </div>
                          </div>
                      </div>
                      <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_street ">
                              <label class="col-md-5 control-label" for="street">Rue <span></span></label>
                              <div class="col-md-7">
                                   <input type="text" class=" form-control" style="margin-bottom:10px;" value="$cmember{street}" name="street" data-role="">
                              </div>
                          </div>
                      </div>
                      <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_number ">
                              <label class="col-md-5 control-label" for="number">Numero <span></span></label>
                              <div class="col-md-7">
                                   <input type="text" class=" form-control" style="margin-bottom:10px;" value="$cmember{number}" name="number" data-role="">
                              </div>
                          </div>
                      </div>
                      <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_zip ">
                              <label class="col-md-5 control-label" for="zip">Code postal <span></span></label>
                              <div class="col-md-7">
                                   <input type="text" class=" form-control" style="margin-bottom:10px;" value="$cmember{zip}" name="zip" data-role="">
                              </div>
                          </div>
                      </div>
                      <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_city ">
                              <label class="col-md-5 control-label" for="city">Ville <span></span></label>
                              <div class="col-md-7">
                                   <input type="text" class=" form-control" style="margin-bottom:10px;" value="$cmember{city}" name="city" data-role="">
                              </div>
                          </div>
                      </div>
                     $email_bloc

                  </div>
EOH
               
            my $page = <<"EOH";
          	<script type="text/javascript">
          		jQuery(document).ready( function () 
          		{                   
                    init_form();
                    init_datepicker();
                    init_dates_disponibles();              
          	   });
            </script>
            
			<form method="post"  action="$full_self" class="form-horizontal loginform" role="form" style="padding-top:0px;">
				<input type="hidden" name="lg" value="$lg" />
				<input type="hidden" name="from" value="$sw" />
				<input type="hidden" name="sw" value="commande_etape_3_db" />           
				<input type="hidden" name="token" value="$commande{token}" id="token_commande" />
			
			  
				<div id="err_champs" class="alert alert-warning text-center" role="alert">Veuillez compléter les champs avec une *</div>
				
				<div class="left">
					<hr />
					<h2 class="text-center">Coordonnées du bien</h2>
					<p class="text-center">Veuillez remplir les informations concernant le bien à expertiser.</p>                        
					$coordonnees_bien
					$cles_disponibles                           
					<hr />
					<h2 class="text-center">Personne de contact</h2>
					<p class="text-center">Si besoin, renseignez une personne de contact pour ce bien.</p>
					$personne_contact                       
				</div>     
				
		  
				<div class="right"> 
					<hr />
					<h2 class="text-center">Coordonnées du client</h2>
					$coordonnees_client
							
<!--
<h3>Date(s) souhaitée(s)</h3>
<p>Sélectionnez la ou les dates souhaitées pour faire expertiser le bien.</p> 
<div class="col-xs-12" style="padding-left: 0px; padding-right: 0px;position:relative;">
$definissez_date
<img id="calendar" src="../skin/img/calendar.png">
</div>

<div class="left"  style="text-align: left; padding-right: 0px;">
<button type="button" class="btn btn-primary add_day_disponible" style="">Ajouter une date</button>
</div>                             				      

<div class="datepicker-days">   </div>

<div class="clearfix"></div>

<div id="recap-days">   
$recap_dates
$table_days       
</div>          

<div style="display:none;">
$verif_date
</div>  
v
-->
                            
                          
<!--
<div class="pull-right">
<br /><br />Code promo: 
<input type="text" class="form-control" name="code_promo" value="" />		<br /><br />		
</div>-->
							
							
							<div class="text-center"><button type="submit" class="btn-custom3 date_verif">Étape suivante</button></div>
							<hr />
						</div>
				</form>
				
EOH
            return $page;             
        }
    }
    #si user n'est pas connecté
    else
    {
       cgi_redirect("$full_self&sw=commande_etape&go_to_step=2&token=$token");
    }
}

#############################################################################
# commande_etape_3
#############################################################################
sub commande_etape_3fact
{
    see();
    
    my $cookie_order = $cgi->cookie('certigreen_handmade');
           
    #si user est connecté
    if($cookie_order ne "")       
    {                  
        my %hash_member;       
        my %member = ();
        
        $cookie_order_ref=decode_json $cookie_order;
        %hash_member=%{$cookie_order_ref};    
        
        if($hash_member{token_member} ne '')
        {
            %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});  
            
            my $token_commande = get_quoted('token');                                   
            my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
			# see(\%commande);
            if($commande{facture_nom} eq '') { 
				$commande{facture_nom} = $commande{lastname};
			}
			if($commande{facture_nom} eq '') { 
				$commande{facture_nom} = $member{lastname};
			}
			if($commande{facture_prenom} eq '') { 
				$commande{facture_prenom} = $commande{firstname};
			}
			if($commande{facture_prenom} eq '') { 
				$commande{facture_prenom} = $member{firstname};
			}
		    if($commande{facture_street} eq '') { 
				$commande{facture_street} = $commande{street};
			}
			if($commande{facture_street} eq '') { 
				$commande{facture_street} = $member{street};
			}
			if($commande{facture_number} eq '') { 
				$commande{facture_number} = $commande{number};
			}
			if($commande{facture_number} eq '') { 
				$commande{facture_number} = $member{number};
			}
			if($commande{facture_zip} eq '') { 
				$commande{facture_zip} = $commande{zip};
			}
			if($commande{facture_zip} eq '') { 
				$commande{facture_zip} = $member{zip};
			}
			if($commande{facture_city} eq '') { 
				$commande{facture_city} = $commande{city};
			}
			if($commande{facture_city} eq '') { 
				$commande{facture_city} = $member{city};
			}
			if($commande{facture_country} eq '') { 
				$commande{facture_country} = $commande{country};
			}
			if($commande{facture_country} eq '') { 
				$commande{facture_country} = $member{country};
			}
			# if($commande{facture_email} eq '') { 
				# $commande{facture_email} = $commande{country};
			# }
			# if($commande{facture_email} eq '') { 
				# $commande{facture_email} = $member{email};
			# }
			
			
			
            #COORDONNEES DE FACTURATION------------------------------------------------------------
			
			
			 my $facture_civilite_id = sql_listbox(
       {
          dbh       =>  $dbh,
          name      => 'facture_civilite_id',
          select    => "id,v1",
          table     => 'migcms_codes',
          where     => '',
          ordby     => 'v1',
          show_empty=> 'y',
          empty_txt =>  '',
          value     => 'id',
          current_value     => '',
          display    => 'v1',
          required => '',
          id       => '',
          class    => 'input-xlarge required form-control',
          debug    => 0,
       }
      );
			
			my %cmember = sql_line({dbh=>$dbh2,table=>'members',where=>"id='$commande{id_member}'"});
			my $coordonnees_fact =  <<"EOH";
			<div id="new_client">
						<div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_civilite ">
                              <label class="col-md-5 control-label" for="civilite">Civilité <span>*</span></label>
                              <div class="col-md-7">
                                   $facture_civilite_id
                              </div>
                          </div>
                      </div>
                      <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_lastname ">
                              <label class="col-md-5 control-label" for="lastname">Nom <span>*</span></label>
                              <div class="col-md-7">
                                   <input type="text" class=" form-control" style="margin-bottom:10px;" value="$commande{facture_nom}" name="lastname" data-role="" required="">
                              </div>
                          </div>
                      </div>
                      <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_firstname ">
                              <label class="col-md-5 control-label" for="firstname">Prenom <span>*</span></label>
                              <div class="col-md-7">
                                   <input type="text" class=" form-control" style="margin-bottom:10px;" value="$commande{facture_prenom}" name="firstname" data-role="" required="">
                              </div>
                          </div>
                      </div>
                      <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_street ">
                              <label class="col-md-5 control-label" for="street">Rue <span></span></label>
                              <div class="col-md-7">
                                   <input type="text" class=" form-control" style="margin-bottom:10px;" value="$commande{facture_street}" name="street" data-role="">
                              </div>
                          </div>
                      </div>
                      <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_number ">
                              <label class="col-md-5 control-label" for="number">Numero <span></span></label>
                              <div class="col-md-7">
                                   <input type="text" class=" form-control" style="margin-bottom:10px;" value="$commande{facture_number}" name="number" data-role="">
                              </div>
                          </div>
                      </div>
                      <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_zip ">
                              <label class="col-md-5 control-label" for="zip">Code postal <span></span></label>
                              <div class="col-md-7">
                                   <input type="text" class=" form-control" style="margin-bottom:10px;" value="$commande{facture_zip}" name="zip" data-role="">
                              </div>
                          </div>
                      </div>
                      <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_city ">
                              <label class="col-md-5 control-label" for="city">Ville <span></span></label>
                              <div class="col-md-7">
                                   <input type="text" class=" form-control" style="margin-bottom:10px;" value="$commande{facture_city}" name="city" data-role="">
                              </div>
                          </div>
                      </div>
                      <div class="">
                          <div class="form-group form-group-clproj clproj_btn_group_email ">
                              <label class="col-md-5 control-label" for="email">Email <span></span></label>
                              <div class="col-md-7">
                                   <input type="email" class=" form-control" style="margin-bottom:10px;" value="" name="email" data-role="">
                              </div>
                          </div>
                      </div>

                  </div>
EOH
               
            my $page = <<"EOH";
          	<script type="text/javascript">
          		jQuery(document).ready( function () 
          		{                   
                    init_form();
                    init_datepicker();
                    init_dates_disponibles();              
          	   });
            </script>
			
			<div id="err_champs" class="alert alert-warning text-center" role="alert">Veuillez compléter les champs avec une *</div>
			
			<hr />
            
			<form method="post"  action="$full_self" class="form-horizontal loginform" role="form" style="padding-top:0px;">
				<input type="hidden" name="lg" value="$lg" />
				<input type="hidden" name="from" value="$sw" />
				<input type="hidden" name="sw" value="commande_etape_3fact_db" />           
				<input type="hidden" name="token" value="$commande{token}" id="token_commande" />

				<div class="right">  
					<h2 class="text-center">Coordonnées de facturation</h2>
					$coordonnees_fact
                    <div class="text-center"><button class="btn-custom3 date_verif" type="submit">Étape suivante</button></div>
				</div>
			</form>
EOH
            return $page;             
        }
    }
    #si user n'est pas connecté
    else
    {
       cgi_redirect("$full_self&sw=commande_etape&go_to_step=2&token=$token");
    }
}

#############################################################################
# commande_etape_3_db
#############################################################################
sub commande_etape_3_db
{
    see();
    
    my $cookie_order = $cgi->cookie('certigreen_handmade');
     
	my %hash_member; 
    my %member = ();
	my @fields = ('lastname','firstname','tel','street','number','zip','city','email');  
	
	#si user est connecté
    if($cookie_order ne "")       
    { 
		$cookie_order_ref=decode_json $cookie_order;
		%hash_member=%{$cookie_order_ref};  
		if($hash_member{token_member} ne '')
		{
			%member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});		
		}
	}
	
	my $token_commande = get_quoted('token');                          
	 
    if($member{id} > 0 && $token_commande ne '')   
	{                
        my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
		
		my %update_commande = ();	
		#bien
		$update_commande{adresse_rue} = get_quoted('adresse_rue');
		$update_commande{adresse_numero} = get_quoted('adresse_numero');
		$update_commande{adresse_cp} = get_quoted('adresse_cp');
		$update_commande{adresse_ville} = get_quoted('adresse_ville');
        #contact
		$update_commande{cle_disponible} = get_quoted('cle_disponible');
        $update_commande{remarque} = get_quoted('remarque');
		#client
		$update_commande{lastname} = get_quoted('lastname');
		$update_commande{firstname} = get_quoted('firstname');
		$update_commande{tel} = get_quoted('tel');
		$update_commande{street} = get_quoted('street');
		$update_commande{number} = get_quoted('number');
		$update_commande{zip} = get_quoted('zip');
		$update_commande{city} = get_quoted('city');
		$update_commande{email} = get_quoted('email');
		
		my %update_member = ();	
		$update_member{lastname} = get_quoted('lastname');
		$update_member{firstname} = get_quoted('firstname');
		$update_member{tel} = get_quoted('tel');
		$update_member{street} = get_quoted('street');
		$update_member{number} = get_quoted('number');
		$update_member{zip} = get_quoted('zip');
		$update_member{city} = get_quoted('city');

		if($member{type_member} eq 'Agence')
		{
			#AGENCE
			
			#affectation commande.id_member_agence
			$update_commande{id_member_agence} = $member{id};
						
			#ajout/maj du client et affectaction de commande.id_member et member.id_agence
			my $email_client = get_quoted('email');
			
			#email client = email agence
			if($email_client eq $member{email})
			{
				 print <<"EOH";
									<script language="javascript">
									alert("En tant qu'agence ou notaire, vous ne pouvez pas utiliser votre adresse email à la place de celle du client");
									history.go(-1);
                      		</script>
EOH
                  exit;
			}
			
			#email client pas vide et ok
			if($email_client ne '')
			{
				#trouver le client correspondant à l'email
				my %client_agence = sql_line({select=>"id",table=>"members",where=>"email='$email_client'"});
				$update_member{id_agence} = $member{id};

				if($client_agence{id} > 0)
				{
					#si le client existe déjà: maj du membre
					updateh_db($dbh,"members",\%update_member,'id',$client_agence{id});
					$update_commande{id_member} = $client_agence{id};
				}
				else
				{
					#ajout du membre
					$update_member{token} = create_token(10);
					$update_member{email} = $email_client;
					my $new_id_member_client = inserth_db($dbh,'members',\%update_member);
					$update_commande{id_member} = $new_id_member_client;
				}
			}
		}
		else
		{
			#PARTICULIER
			$update_commande{email} = $member{email};
			updateh_db($dbh,"members",\%update_member,'id',$member{id});
		}
		updateh_db($dbh_data,"intranet_factures",\%update_commande,'token',$token_commande);

        http_redirect("$full_self&sw=commande_etape&go_to_step=3fact&token=$token_commande");                                      
    }
    else
    {
        #si user n'est pas connecté
	    cgi_redirect("$full_self&sw=commande_etape&go_to_step=2&token=$token&member=''");
    }
}




################################################################################
# commande_etape_3fact_old
################################################################################
sub commande_etape_3fact_old
{
see();
my $cookie_order = $cgi->cookie('certigreen_handmade');
           
    #si user est connecté
    if($cookie_order ne "")       
    {                  
        my %hash_member;       
        my %member = ();
        
        $cookie_order_ref=decode_json $cookie_order;
        %hash_member=%{$cookie_order_ref};    
        
        if($hash_member{token_member} ne '')
        {
            $token_commande = get_quoted("token");
            my %commande = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"token='$token_commande'"});
            #my %facture = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"commande_id='$commande{id}'"}); 
            
            %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});
            
            my $remarque =<<"EOH";
              <div class="form-group">
                <label class="col-xs-8" for="remarque">Remarque</label>
                <div class="col-xs-8">
                    <textarea rows="" cols="" class=" form-control" style="" name="facture_remarque" data-role="">$commande{facture_remarque}</textarea>
                </div>
              </div>
EOH
            
            my $agence_eventuelle = '';                                                                                              
            my %vals = (                        
                        '00/0'=>"Au nom du propriétaire à <b>l'adresse du bien</b>",     
						'03/3'=>"Au nom du propriétaire à <b>ses coordonnées</b>",     
                        '04/2'=>"Autre adresse de facturation",
              );
            
            # si c'est une agence
            if($member{type_member} eq "Agence")
            {
                $vals{'01/1'}="Au nom de du notaire ou de l'agence",  
            }
			#à <b>l'adresse de l'agence ou du notaire</b>
            # si c'est un particulier  
            else
            {
                # si c'est un particulier et il est enregistré chez une agence
                if($member{id_agence} != 0)
                {
                    $vals{'01/1'}="Au nom de l'agence ou de notaire <b>l'adresse de votre agence ou notaire</b>",  
                } 
                # si c'est un particulier et il n'est pas enregistré chez une agence
                else
                {          
                    $agence_eventuelle =<<"EOH";
                        <div class="form-group form-group-clproj clproj_btn_group_agence_eventuelle ">
                            <label class="col-xs-8" for="agence_eventuelle">Nom de votre notaire ou de votre agence immobilière éventuelle</label>
                            <div class="col-xs-8">
                                <textarea rows="" cols="" class=" form-control" style="" name="agence_eventuelle" data-role="">$commande{agence_eventuelle}</textarea>
                            </div>
                        </div>
EOH
                }
                                    
            } 
             # print $facture{adresse_facturation} ;       
            #ENVOYER FACTURE------------------------------------------------------------                        
            my $envoie_facture = get_form_line(
                                    {
                                        type => 'btns-group',
                                        name =>'envoie_facture', 
                                        label =>'',           
                                        checked_val=>$commande{adresse_facturation},
                                        style=>"width:450px; margin-bottom:10px;",      
                                        vals => \%vals,
                                    }
                                );
                                
          #################      FORMULAIRE POUR AUTRE ADRESSE       ####################
            my %vals = (
                             '01/societe_nom'=> $commande{societe_nom},  
                             '02/societe_tva'=> $commande{societe_tva},
                             '03/facture_nom'=> $commande{facture_nom},
                             '04/facture_prenom'=> $commande{facture_prenom},
                             '05/facture_street'=> $commande{facture_street},    
                             '06/facture_number'=> $commande{facture_number},
                             '07/facture_zip'=> $commande{facture_zip},       
                             '08/facture_city'=> $commande{facture_city},
                        );
                        
                        
            my $autre_adresse = get_form_line(
                              {
                                  type => 'list_inputs',
                                  name =>'societe_nom,societe_tva,facture_nom,facture_prenom,facture_street,facture_number,facture_zip,facture_city', 
                                  label =>'Nom de la société (optionnel),Numéro de TVA (optionnel),Nom,Prenom,Rue,Numero,Code postal,Ville',
                                  required=>'',                                                 
                                  size_col_field => 6,
                                  suffix=>',,*,*,*,*,*,*',
                                  vals=> \%vals,
                              }   
                          );                  
                          	
                            
            my $page = <<"EOH";
                  	<script type="text/javascript">
                  		jQuery(document).ready( function () 
                  		{     
                            init_form();
                            envoie_facture();
                  	   });
                  </script>
                  
                  <div class="">                           
                         
                      
                    	<div class="col-xs-11">  
                          <form method="post"  action="$full_self" class="form-horizontal" role="form">
                          		<input type="hidden" name="lg" value="$lg" />
                          		<input type="hidden" name="from" value="$sw" />
                              <input type="hidden" name="sw" value="commande_etape_3fact_db" />            
                          		<input type="hidden" name="token" value="$token_commande" />
                              
							  
							  
							  
                              <h3>Quelle adresse renseigner dans la facture ?</h3>  
                              
                              <div class="type_agence">
                                  $envoie_facture          
                                  <div id="autre_adresse">
                                      $autre_adresse
                      					  </div> 
                                  $agence_eventuelle
                                  $remarque
                  					  </div>   
                              <h3>A quelle adresse envoyer la facture ?</h3>  
							  <select name="envoyer_a" class="form-control">
								<option value="Agence/Notaire">Adresse du notaire ou de l'agence</option>
								<option value="Adresse du bien">Adresse du bien</option>
								<option value="Coordonnées du client">Adresse du client</option>
							  </select>
							  
							  <br /><br /><br />
                              <button type="submit" class="btn btn-primary btn-lg adresse_facture_submit">Étape suivante</button>
                        	</form>		
                       </div>
              		</div>
EOH
            return $page;
        }
    }
}



#############################################################################
# commande_etape_3_db
#############################################################################
sub commande_etape_3fact_db
{
    see();
    
    my $cookie_order = $cgi->cookie('certigreen_handmade');
           
    #si user est connecté
    if($cookie_order ne "")       
    {                  
        my %hash_member;       
        my %member = ();
        
        $cookie_order_ref=decode_json $cookie_order;
        %hash_member=%{$cookie_order_ref};    
        
        if($hash_member{token_member} ne '')
        {
            #particuler ou agence ?
			%member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});  
            
            my $token_commande = get_quoted('token');                                   
            my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
			
			
			my $where_member = '';
			my %check_member = ();
			if($commande{facture_id_member} > 0)
			{
				$where_member = " id = '$commande{facture_id_member}' ";
				%check_member = read_table($dbh2,'members',$commande{facture_id_member});
			}
			 my %update_commande = ();	
			 
			 
			#coordonnées client génère un compte client, on recopie coord dans coord fact mais on ne genere pas de membre avec coord fact 
			#INSERT OR UPDATE MEMBER
			# my @fields = ('lastname','firstname','street','number','zip','city','email');  
			# my @fields_labels = ('facture_nom','facture_prenom','facture_street','facture_number','facture_zip','facture_city','facture_email');  
			# my %update_member = ();  
			# my $if = 0;
			# foreach my $f (@fields)
			# {
				# my $value = get_quoted($f);
				# $update_member{$fields[$if]} = trim($value);
				# $if++;
			# }      
			# if($check_member{token} eq '')
			# {
				# $update_member{token} = create_token(100);
			# }
			# my $id_member = sql_set_data({debug=>0,dbh=>$dbh2,table=>'members',data=>\%update_member,where=>$where_member});     
			# $update_commande{facture_id_member} = $id_member;
			
			#UPDATE commande
			my @fields = ('facture_civilite_id','lastname','firstname','street','number','zip','city','email');  
			my @fields_labels = ('facture_civilite_id','facture_nom','facture_prenom','facture_street','facture_number','facture_zip','facture_city','facture_email');  
			my $if = 0;
			foreach my $f (@fields)
			{
				my $value = get_quoted($f);
				$update_commande{$fields_labels[$if]} = trim($value);
				$if++;
			}      
	
            my $champ_vide = '';    
            foreach $update (values %update_commande)
            {
                if($update == '')
                {
                     $champ_vide+=' '.$update.' ';
                }
            }
            
            if($champ_vide == '')
            {
                sql_set_data({debug=>0,dbh=>$dbh2,table=>'intranet_factures',data=>\%update_commande, where=>"token='$token_commande'"});
                http_redirect("$full_self&sw=commande_etape&go_to_step=4&token=$token_commande");                                      
#                 print $champ_vide." ok";
            }
            else
            {
                http_redirect("$full_self&sw=commande_etape&go_to_step=3fact&token=$token_commande");  
            }
            
        }
    }
    #si user n'est pas connecté
    else
    {
       cgi_redirect("$full_self&sw=commande_etape&go_to_step=2&token=$token&member=''");
    }
}


#############################################################################
# commande_etape_3fact_db
#############################################################################
sub commande_etape_3fact_db_old
{
    see();   
    
    my $envoie_facture = $cgi->param('envoie_facture');                                                                 
    my @champs_requis = ('facture_nom','facture_prenom','facture_street','facture_number','facture_zip','facture_city','envoyer_a');
    
	#AUTRE ADRESSE DE FACTURATION
	if ($envoie_facture == 2 )
    {
         foreach my $champ(@champs_requis)
         {
              my $val = $cgi->param($champ);
              if ($val eq '')
              {
                  print <<"EOH";
                      		<script language="javascript">
                      		alert("Merci de remplir tous les champs requis (*)");
                      		history.go(-1);
                      		</script>
EOH
                  exit;                
              }
         }     
    }  
  

    my $cookie_order = $cgi->cookie('certigreen_handmade');
      
           
    #si user est connecté
    if($cookie_order ne "")       
    {                  
        my %hash_member;       
        my %member = ();
        
        $cookie_order_ref=decode_json $cookie_order;
        %hash_member=%{$cookie_order_ref};    
        
        if($hash_member{token_member} ne '')
        {
            %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});  
            
            my $token_commande = $cgi->param('token');                                   
            my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
            my %proprietaire = sql_line({dbh=>$dbh2,table=>'members',where=>"id='$commande{id_member}'"});  
             
            my %adresse_facture_update = ();          
            
			
            if($envoie_facture == 3)
            {
                #AU NOM DU PROPRIETAIRE A L'ADRESSE DU BIEN
				$adresse_facture_update{adresse_facturation} = "0"; 
                $adresse_facture_update{facture_nom} = $proprietaire{lastname}; 
                $adresse_facture_update{facture_prenom} = $proprietaire{firstname};
                $adresse_facture_update{facture_street} = $proprietaire{street}; 
                $adresse_facture_update{facture_number} = $proprietaire{number};
                $adresse_facture_update{facture_zip} = $proprietaire{zip}; 
                $adresse_facture_update{facture_city} = $proprietaire{city};   
                
            }
			elsif($envoie_facture  == 0)
            {
                #AU NOM DU PROPRIETAIRE A SES COORDONNEES
				$adresse_facture_update{adresse_facturation} = "0"; 
                $adresse_facture_update{facture_nom} = $proprietaire{lastname}; 
                $adresse_facture_update{facture_prenom} = $proprietaire{firstname};
                $adresse_facture_update{facture_street} = $commande{adresse_rue}; 
                $adresse_facture_update{facture_number} = $commande{adresse_numero};
                $adresse_facture_update{facture_zip} = $commande{adresse_cp}; 
                $adresse_facture_update{facture_city} = $commande{adresse_ville};   
            }
            elsif($envoie_facture  == 1)
            {
                #AU NOM De AGENCE
				$adresse_facture_update{adresse_facturation} = "1";
                if( ($member{id_agence} != 0) && ($member{type_member} eq "Particulier"))
                {
                    
                    my %agence = sql_line({dbh=>$dbh2,table=>'members',where=>"id='$proprietaire{id_agence}'"}); 
                    
                    $adresse_facture_update{facture_nom} = $agence{lastname}; 
                    $adresse_facture_update{facture_prenom} = $agence{firstname};
                    $adresse_facture_update{facture_street} = $agence{street};
                    $adresse_facture_update{facture_number} = $agence{number};
                    $adresse_facture_update{facture_zip} = $agence{zip}; 
                    $adresse_facture_update{facture_city} = $agence{city};  
                    
                } 
                elsif(($member{type_member} eq "Agence"))
                {                             
                    $adresse_facture_update{facture_nom} = $member{lastname}; 
                    $adresse_facture_update{facture_prenom} = $member{firstname};
                    $adresse_facture_update{facture_street} = $member{street}; 
                    $adresse_facture_update{facture_number} = $member{number};
                    $adresse_facture_update{facture_zip} = $member{zip}; 
                    $adresse_facture_update{facture_city} = $member{city}; 
                }
            }
            else
            {
                $adresse_facture_update{adresse_facturation} = "2"; 
                
                my @champs_autre_adresse = ('societe_nom','societe_tva','facture_nom','facture_prenom','facture_street','facture_number','facture_zip','facture_city');
                                
                foreach $champ (@champs_autre_adresse)
                {
                      $adresse_facture_update{$champ} = $cgi->param($champ);
                }
                
            }
            
                $adresse_facture_update{facture_remarque} = $cgi->param('facture_remarque');
				$adresse_facture_update{envoyer_a} = $cgi->param('envoyer_a');
                
                #AGENCE EVENTUELLE :  
                #si le client appartient à l'agence
                if($member{id_agence} != 0 && $member{type_member} eq "Particulier") 
                {     
                    $adresse_facture_update{agence_eventuelle} = $member{id_agence}; 
                } 
                #si c'est l'agence qui est connecté
                elsif ($member{type_member} eq "Agence")
                {
                    $adresse_facture_update{agence_eventuelle} = $member{id}; 
                }
                #si c'est un Particulier independant 
                elsif($member{id_agence} == 0 && $member{type_member} eq "Particulier")
                {
                    $adresse_facture_update{agence_eventuelle} = $cgi->param("agence_eventuelle"); 
                }
                
            #  print Dumper(\%adresse_facture_update); exit;
                 
 #              my %facture = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"commande_id='$commande{id}'"});  
#           
#             if(scalar(keys %facture) != 0)
#             {
#                 $stmt = "DELETE FROM factures WHERE commande_id = '$commande{id}'";
#               	$cursor = $dbh2->prepare($stmt);
#               	$cursor->execute || suicide($stmt);
#             }
            
            #NUMERO DE LA FACTURE
#             my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
#             my $yearNow =  1900+$year; 
#             $n = sprintf("%08d", $commande{id});
#         		$adresse_facture_update{numero} = $yearNow.$n; 
#         		$adresse_facture_update{token} = create_token(50);  
#         		$adresse_facture_update{annee} = $yearNow;

            #ecraniser des quotes
            foreach my $champ (@champs_requis)
            {
      
				 # $adresse_facture_update{$champ} =~ s/\\//g;

				 $adresse_facture_update{$champ} =~ s/\'/\\\'/g;
            } 
			
			$adresse_facture_update{facture_remarque} =~ s/\'/\\\'/g;
			$adresse_facture_update{societe_tva} =~ s/\'/\\\'/g;
			$adresse_facture_update{societe_nom} =~ s/\'/\\\'/g;
			
			# see(\%adresse_facture_update);
			# exit;
            sql_set_data({debug=>0,dbh=>$dbh2,table=>'intranet_factures',data=>\%adresse_facture_update,where=>"id='$commande{id}'"});
            http_redirect("$full_self&sw=commande_etape&go_to_step=4&token=$token_commande");
        }
    } 
    else
    {
       cgi_redirect("$full_self&sw=commande_etape&go_to_step=2&token=$token");
    }
            
     
}


#############################################################################
# commande_etape_4
#############################################################################
sub commande_etape_4
{
    see();
    
    my $cookie_order = $cgi->cookie('certigreen_handmade');
           
    #si user est connecté
    if($cookie_order ne "")       
    {                  
        my %hash_member;       
        my %member = ();
        
        $cookie_order_ref=decode_json $cookie_order;
        %hash_member=%{$cookie_order_ref};    
        
        if($hash_member{token_member} ne '')
        {
            %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});  
            
            my $token_commande = get_quoted('token');                                   
            my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
             # see(\%commande);
         ####################   DETAILS D'EXPERTISE      #########################                        
            my $table_details = '<table class="table table-bordered table-striped" id="table_details">';
            
            #EXPERTISES-------------------------------
            my @commande_documents = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'commande_documents',where=>"commande_id=$commande{id}"});   
            my @types_document = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'types_document'});
            my $list_documents = '';
            
            foreach my $document (@commande_documents)
            {
                 my %document = %{$document};
                 foreach my $one_type (@types_document)
                 {
                      my %one_type = %{$one_type};
                      if($one_type{id} == $document{type_document_id})
                      {
                           $list_documents .= $one_type{type_1}."<br>"; 
                      }
                 }
            }
            
            $table_details .= << "EOH";
               	<tr>
                     <td style="width:50%;"><b>Expertise(s) souhaitée(s)</b></td> 
                     <td style="width:50%;">$list_documents</td>
                </tr>
EOH
            #TYPE BIEN-------------------------------
            my @types_bien = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'types_bien'});
            my $nom_type_bien = '';
            foreach my $type_bien_commande (@types_bien)
            {
                my %type_bien_commande = %{$type_bien_commande};
                if($commande{id_type_bien} == $type_bien_commande{id})
                {
                     $nom_type_bien .= $type_bien_commande{type_1}; 
                }
            }
            $table_details .= << "EOH";
               	<tr>
                     <td style="width:50%;"><b>Type de bien</b></td>
                     <td style="width:50%;">$nom_type_bien</td>
                </tr>
EOH
            #ADRESSE-------------------------------                
            $table_details .= << "EOH";
               	<tr>
                     <td style="width:50%;"><b>Adresse</b></td>
                     <td style="width:50%;">$commande{adresse_rue} $commande{adresse_numero} </td>
                </tr>
EOH
            #CODE POSTAL-------------------------------                
            $table_details .= << "EOH";
               	<tr>
                     <td style="width:50%;"><b>Code postal</b></td>
                     <td style="width:50%;">$commande{adresse_cp}</td>
                </tr>
EOH
            #VILLE-------------------------------                
            $table_details .= << "EOH";
               	<tr>
                     <td style="width:50%;"><b>Ville</b></td>
                     <td style="width:50%;">$commande{adresse_ville}</td>
                </tr>
EOH
            #CLE DISPONIBLE-------------------------------  
            my $cle = 'Non';
            if($commande{cle_disponible} eq 'y')
            {
                $cle = 'Oui';
            }              
            $table_details .= << "EOH";
               	<tr>
                     <td style="width:50%;"><b>Clés disponibles</b></td>
                     <td style="width:50%;">$cle</td>
                </tr>
EOH
            $table_details .= "</table>"; 
            
        ####################   DATES SOUHAITEES      #########################                        
            # my $table_dates = '<table class="table table-bordered" id="table_details">';
            
            # my @dates_commande = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'commande_dates',where=>"commande_id=$commande{id}"});   
            
            # $table_dates .= << "EOH";
               	# <tr>
                     # <th>Date</th> 
                     # <th>Moment de visite</th>
                # </tr>
# EOH
            
            # foreach my $date (@dates_commande)
            # {
                 # my %date = %{$date};
                 # my $time = "Matin";
                 
                 # if($date{commande_time} eq 'nimporte')
                 # {
                    # $time = "Peu importe"; 
                 # }
                 # elsif($date{commande_time} eq 'apresmidi')
                 # {        
                    # $time = "Après-midi"; 
                 # } 
                 
                 # $table_dates .= << "EOH";
               	# <tr>
                     # <td>$date{commande_date}</td> 
                     # <td>$time</td>
                # </tr>
# EOH
            # }
            
            # $table_dates .= "</table>"; 
            
        ####################   COORDONNEES FACTURATION    #########################                        
            my $table_facturation = '<table class="table table-bordered table-striped" id="table_details">';
            my %coord_facture = ();
            
            %coord_facture = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"id='$commande{id}'"});
            
			my %civ = sql_line({table=>'migcms_codes',where=>"id='$coord_facture{facture_civilite_id}'"});
			 
			
            $table_facturation .= << "EOH";
               	<tr>
                     <td style="width:50%;"><b>Civilité</b></td> 
                     <td style="width:50%;">$civ{v1}</td>
                </tr>	
				<tr>
                     <td style="width:50%;"><b>Nom</b></td> 
                     <td style="width:50%;">$coord_facture{facture_nom}</td>
                </tr>
                <tr>
                     <td style="width:50%;"><b>Prénom</b></td> 
                     <td style="width:50%;">$coord_facture{facture_prenom}</td>
                </tr>
                <tr>
                     <td style="width:50%;"><b>Adresse</b></td> 
                     <td style="width:50%;">$coord_facture{facture_street} $coord_facture{facture_number} </td>
                </tr>
                <tr>
                     <td style="width:50%;"><b>Code postal</b></td> 
                     <td style="width:50%;">$coord_facture{facture_zip}</td>
                </tr>      
                <tr>
                     <td style="width:50%;"><b>Ville</b></td> 
                     <td style="width:50%;">$coord_facture{facture_city}</td>
                </tr>
				 <tr>
                     <td style="width:50%;"><b>Email: </b></td> 
                     <td style="width:50%;">$coord_facture{facture_email}</td>
                </tr>
                
EOH
            $table_facturation .= "</table>"; 
            
            
            my $resume_html = <<"EOH";
	
				<h3>Expertise:</h3>
                  $table_details      
                  <br /><br />
                  
                 <!-- <h3>Date(s):</h3>
                  $table_dates -->
				<br /><br />
              
        		
                  <h3>Facturation:</h3>
                  $table_facturation	
				  
				
			
EOH
            
            my $encoded = encode_entities($resume_html,'<>&"');
			# my $encoded = $resume_html;
			$encoded =~ s/\"/\\\"/g;
			
            my $page = <<"EOH";
          	<script type="text/javascript">
          		jQuery(document).ready( function () 
          		{                   
              			
                    init_form();
              
          	   });
            </script>
              
        	<hr />
            
			<div class="left">
				<h2 class="text-center">Détail sur l\'expertise</h2>
				$table_details      
                  
                  
                  <!--<h3>Date(s) souhaitée(s)</h3>
                  $table_dates-->
			</div>     
              
			<div class="right">  
				<h2>Coordonnées de facturation</h2>
				$table_facturation
				<p>En validant, j\'accepte les <a href="#">condition générales</a></p>
                  
				<form method="post"  action="$full_self" class="form-horizontal" role="form" style="padding-top:0px;">
					<input type="hidden" name="lg" value="$lg" />
					<input type="hidden" name="from" value="$sw" />
					<input type="hidden" name="sw" value="commande_etape_4_db" />   
					<input type="hidden" name="token" value="$token_commande" />
					<input type="hidden" name="validation" value="1" />
					<input type="hidden" name="html_content" value="$encoded" />
					  
                      
					<div class="text-center"><button type="submit" class="btn-custom3">Valider</button></div>
				</form>
                            
			</div>
EOH
      return $page;
        }
    }
    else
    {
       cgi_redirect("$full_self&sw=commande_etape&go_to_step=2&token=$token");
    }
}

#############################################################################
# commande_etape_4_db
#############################################################################
sub commande_etape_4_db
{
    see();
    
    my $cookie_order = $cgi->cookie('certigreen_handmade');
           
    #si user est connecté
    if($cookie_order ne "")       
    {                  
        my %hash_member;       
        my %member = ();
        
        $cookie_order_ref=decode_json $cookie_order;
        %hash_member=%{$cookie_order_ref};    
        
        if($hash_member{token_member} ne '')
        {
            %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});  
            
            my $token_commande = get_quoted('token');                                   
            my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
            
            my %update_commande = ();
                $update_commande{validation} = get_quoted('validation');
                $update_commande{date_commande} = 'NOW()';  

			my $html_content = get_quoted('html_content');
			# HTML::Entities::decode($html_content);
			 # use utf8;
			 # utf8::decode($html_content);
			   $html_content .= <<"EOH";
			   <br /><br />
				  
				  <a href="http://certigreen.fw.be/cgi-bin/adm_handmade_commandes.pl?">Admin de gestion des commandes</a> (Si connecté à l'admin du site web)
EOH
	
	
	
	
#nb documents demandes
$stmt = <<"EOH";
	UPDATE intranet_factures c
SET 
nb_doc = 
(
    SELECT COUNT(*) FROM commande_documents doc
    WHERE
    doc.commande_id = c.id
)
WHERE id = '$commande{id}'
EOH

	execstmt($dbh,$stmt);
			
			send_mail($member{email},$EMAILDEBUG,"COPIE ALEXIS: CERTIGREEN: Demande d'expertise N $commande{id}",$html_content,'html');
			send_mail($member{email},$EMAILSITE,"CERTIGREEN: Demande d'expertise N $commande{id}",$html_content,'html');

				
                
            sql_set_data({debug=>0,dbh=>$dbh2,table=>'intranet_factures',data=>\%update_commande, where=>"token='$token_commande'"});
			
			
			
			
			
			
			
			my $fusion = def_handmade::denom_commande($dbh,$id,'','commades');
			my $fusion_short = def_handmade::denom_commande($dbh,$id,'short','commandes'); 
	
			$fusion =~ s/\'/\\\'/g;
			$fusion_short =~ s/\'/\\\'/g;
	

	
			my $stmt = <<"EOH";
			UPDATE intranet_factures SET fusion = '$fusion',fusion_short='$fusion_short' WHERE token='$token_commande'
EOH
			log_debug($stmt,'','after_save_commande');
			execstmt($dbh,$stmt);
			
			
			
			
			
			
#           print "ok 4db";
            http_redirect("$full_self&sw=commande_etape&go_to_step=5&token=$token_commande");
        }
        
    }
    else
    {
       cgi_redirect("$full_self&sw=commande_etape&go_to_step=2&token=$token_commande");
    }
}



#############################################################################
# commande_etape_5
#############################################################################
sub commande_etape_5
{
    see();
    
    my $cookie_order = $cgi->cookie('certigreen_handmade');
           
    #si user est connecté
    if($cookie_order ne "")       
    {                  
        my %hash_member;       
        my %member = ();
        
        $cookie_order_ref=decode_json $cookie_order;
        %hash_member=%{$cookie_order_ref};    
        
        if($hash_member{token_member} ne '')
        {
            %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});  
            
            my $token_commande = get_quoted('token');                                   
            my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
           
            #EXPERTISES-------------------------------
            my @commande_documents = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'commande_documents',where=>"commande_id=$commande{id}"});   
            my @types_document = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'types_document'});
            my $list_documents = '<table class="table-bordered table" id="table_details">';
            
            foreach my $document (@commande_documents)
            {
                 my %document = %{$document};
                 foreach my $one_type (@types_document)
                 {
                      my %one_type = %{$one_type};
                      if($one_type{id} == $document{type_document_id})
                      {
                          $list_documents .= << "EOH";
                         	<tr>
                               <td>$one_type{type_1}</td>
                          </tr>
EOH
                      }
                 }
            }
            

            $list_documents .= "</table>"; 
                        
            my $page = <<"EOH";
          	<script type="text/javascript">
          		jQuery(document).ready( function () 
          		{                   
              			
                    init_form();
              
          	   });
            </script>
              
        	      
            <hr />
            <div id="step5">
				<h2 class="text-center">Votre demande d\'expertise a bien été enrégistrée</h2>
				$list_documents     
			</div>
            <div class="text-center"><a class="btn-custom3 btn-step5" href ="$full_self&sw=commande_etape&go_to_step=1&token=">Effectuer une nouvelle demande</a></div>
EOH
      return $page;

        }
        
    }
    else
    {
       cgi_redirect("$full_self&sw=commande_etape&go_to_step=2&token=$token");
    }
}

sub espace_perso
{
	see();
	my $cookie_order = $cgi->cookie('certigreen_handmade');  	

	my @commandes_sans_tokens = sql_lines({select=>"id",dbh=>$dbh, table=>"intranet_factures", where=>"token = ''"});
	foreach $commandes_sans_token (@commandes_sans_tokens)
	{
		my %commandes_sans_token=%{$commandes_sans_token}; 
		my $new_token = create_token(20);
		
		my $stmt = <<"SQL";
			UPDATE intranet_factures
				SET token = '$new_token'
				WHERE id = '$commandes_sans_token{id}'
SQL
		execstmt($dbh, $stmt);
	}	
	my @members_sans_tokens = sql_lines({select=>"id",dbh=>$dbh, table=>"members", where=>"token = ''"});
	foreach $members_sans_token (@members_sans_tokens)
	{
		my %members_sans_token=%{$members_sans_token}; 
		my $new_token = create_token(20);
		
		my $stmt = <<"SQL";
			UPDATE members
				SET token = '$new_token'
				WHERE id = '$members_sans_token{id}'
SQL
		execstmt($dbh, $stmt);
	}	
	my @members_sans_tokens = sql_lines({select=>"id",dbh=>$dbh, table=>"members", where=>"token2 = ''"});
	foreach $members_sans_token (@members_sans_tokens)
	{
		my %members_sans_token=%{$members_sans_token}; 
		my $new_token = create_token(20);
		
		my $stmt = <<"SQL";
			UPDATE members
				SET token2 = '$new_token'
				WHERE id = '$members_sans_token{id}'
SQL
		execstmt($dbh, $stmt);
	}
	
	#si pas cookie
	if($cookie_order eq '')       
    { 
		http_redirect("$full_self&sw=connexion&ret=espace_perso"); 
		exit;
	}
	$cookie_order_ref=decode_json $cookie_order;
    my %hash_member=%{$cookie_order_ref}; 
	my %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});  
	
	#si pas connecte
	if(!($member{id} > 0))       
    { 
		http_redirect("$full_self&sw=connexion&ret=espace_perso"); 
		exit;
	}
	
	#valeurs de recherche
	my $nom_client = get_quoted('nom_client');
	my $numero_commande = get_quoted('numero_commande');
	my $numero_facture = get_quoted('numero_facture');
	my $adr = get_quoted('adr');
	
	
	my $page = <<"EOH";
	
		<section class="parag_content parag_form">
        <div class="row">
			<div class="col-md-12" style="position:relative;">
				<h1>Mon espace Certigreen</h1> 
				<div>
					<a class="btn-custom3" href ="$self&sw=edit_infos&token=$member{token}">Mes informations</a>
					<a class="btn-custom3" href ="$self&sw=commande_etape&go_to_step=1&token=">Effectuer une nouvelle demande</a>
					<a class="btn-custom3" href="$self&sw=logout_db">Déconnexion</a>
				</div>
				<br />

EOH
	
	
	if($member{type_member} eq "Agence")
    {               
		$page .= <<"EOH";
			
			<div class="well">
				<!-- FORMULAIRE DE RECHERCHE -->
				<form method="post" action="$self" style="padding:0px;">
					<input type="hidden" name="sw" value="espace_perso" />
					<h4>Recherches :</h4>
					<div class="row">
						<div class="col-md-3 col-sm-6 col-xs-12">
							<input type="text" placeholder="Nom du client" name="nom_client" value="$nom_client" class="form-control input-sm">
						</div>
						<div class="col-md-3 col-sm-6 col-xs-12">
							<input placeholder="N° commande" type="text" name="numero_commande" value="$numero_commande" class="form-control input-sm">
						</div>
						<div class="col-md-3 col-sm-6 col-xs-12">
							<input  placeholder="N° facture" type="text" name="numero_facture" value="$numero_facture" class="form-control input-sm">
						</div>
						<div class="col-md-3 col-sm-6 col-xs-12">
							<input  placeholder="Adresse du bien" type="text" name="adr" value="$adr" class="form-control input-sm">
						</div>
						<div class="col-md-12 text-right">
							<br />
							<button type="submit" class="btn-custom3">Rechercher</button>
						</div>
					</div>
				</form>
				
				<form method="post" action="$self" class="text-right" style="padding-top:0px;">
					<input type="hidden" name="sw" value="espace_perso" />
					<button type="submit" class="btn btn-link"><small>Afficher tout</small></button>					
				</form>
			</div>
EOH
	}
	
	$page .= <<"EOH";
		<script>
			jQuery(function () {
			  jQuery('[data-toggle="tooltip"]').tooltip();
			})
		</script>
		
		<!-- Liste des demandes -->
		<table class="table table-bordered table-striped" id="table_espace">
			<tr>
				<th>Coordonnées</th>
				<th class="text-center">Date des visites & rapports</th>
				<th class="text-center">Facture</th>
				<th class="text-center" style="width:210px;">Détails</th>
			</tr>
EOH

	my @commandes = ();
	if ($member{type_member} eq "Agence")
	{
		my $nom_client = get_quoted('nom_client');
		my $numero_commande = get_quoted('numero_commande');
		my $numero_facture = get_quoted('numero_facture');
		my $adr = get_quoted('adr');
		
		my @where = ();
		
		# push @where, " c.id_member = m.id  ";
		push @where, " (c.id_member_agence='$member{id}' || c.id_agence2='$member{id}'   || c.id_member_agence='$member{id}') ";
		push @where, " validation='1'  ";
		# $commande{adresse_rue} $commande{adresse_numero} $commande{adresse_cp} $commande{adresse_ville}
		if($adr ne '')
		{
			push @where, "( adresse_rue LIKE '%$adr%' OR adresse_numero LIKE '%$adr%' OR adresse_cp LIKE '%$adr%' OR adresse_ville LIKE '%$adr%' )";
		}	
		if($nom_client ne '')
		{
			push @where, "( lastname LIKE '%$nom_client%' OR firstname LIKE '%$nom_client%' )";
		}	
		if($numero_commande ne '')
		{
			push @where, " c.id = '$numero_commande' ";
		}
		if($numero_facture ne '')
		{
			push @where, " c.id IN (select id_record from intranet_factures where numero = '$numero_facture') ";
		}
		my $supp_where = join(" AND ",@where);
		
		@commandes = sql_lines({debug=>1,debug_results=>1,dbh=>$dbh2,select=>"c.*,c.id as commande_id, c.token as token_commande",table=>'intranet_factures c',where=> $supp_where,ordby=>'c.id desc'});
	}
	else
	{
		@commandes = sql_lines({debug=>1,debug_results=>1,dbh=>$dbh2,select=>"c.*,c.id as commande_id, c.token as token_commande",table=>'intranet_factures c',where=>"validation = 1 AND id_member='$member{id}'",ordby=>'c.id desc'});
	}

	foreach my $commande (@commandes)
    { 
		my %commande = %{$commande};
		my %client = sql_line({dbh=>$dbh2,table=>'members',where=>"id='$commande{id_member}'"});
		
		#membre
		$client{lastname} = uc($commande{lastname});
		$client{firstname} = ucfirst(lc($commande{firstname}));
		
		#lien facture
#		my %facture = sql_line({table=>'intranet_factures', dbh=>$dbh2, where=>"table_record='intranet_factures' AND id_record = '$commande{commande_id}'" });
#		my $links_to_facture = get_facture_links($commande{commande_id});
		# if($facture{total_tvac} > 0)
		# {
			# $link_to_facture .= '<br />€ '.$facture{total_tvac}.' TVAC';
		# }
		
		#liste documents
		
		my %docs = ();
		my %docs_date = ();
		my @commande_types_documents =  sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',select=>"distinct(type_document_id) as type_document_id",where=>"commande_id='$commande{commande_id}'",ordby=>'type_document_id'});
		foreach $ctd (@commande_types_documents)
		{
			my %ctd = %{$ctd};
			my @commande_documents =  sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',where=>"type_document_id = '$ctd{type_document_id}' AND commande_id='$commande{commande_id}'"});
			foreach my $document (@commande_documents)
			{
				my %document = %{$document};
				my %type_document = sql_line({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'types_document',where=>"id='$document{type_document_id}'"}); 
				
				my $date_prevue = '';
				
				#UNE date par type de document
				if ($document{date_prevue} ne "")
				{
				   $date_prevue = << "EOH";
				   le $document{date_prevue}
EOH
					if($document{heure_prevue} ne "")
					{
					   $date_prevue .= " à ".$document{heure_prevue};
					}
				}
				else
				{
					$date_prevue = "";
				}
				$docs_date{$type_document{short_1}} = $date_prevue;
				
				#ajout à la liste des documents du meme type
				
				
					
				
				
				my %corr = 
				(
					1 => 'Certificat PEB',
					2 => 'Electricité',
					3 => 'Citerne',
					4 => 'Amiante',
					5 => 'Pollution des sols',
				);
				
				my %corr_img = 
				(
					1 => '../skin/img/peb.png',
					2 => '../skin/img/elec.png',
					3 => '../skin/img/citerne.png',
					4 => '../skin/img/amiante.png',
					5 => '../skin/img/symbole_pollution.png',
				);
				
				my $document = $corr{$type_document{id}};
				my $img = $corr_img{$type_document{id}};
				
				
				my %migcms_linked_file = sql_line({table=>"migcms_linked_files",where=>"table_name='commande_documents' AND token='$document{id}'"});
				my $pdf = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full};
				# $pdf =~ s/\.\.\/usr/\.\.\//g;
				$pdf = $pdf.$migcms_linked_file{ext};
				$pdf =~ s/\/\//\//g;

				# my $migcms_last_published_file = '../files/'.$dm_cfg{file_prefixe}.'/pj/'.$commande_document{id}.'/'.$commande_document{url};
				my $migcms_last_published_file = $pdf;

				
				if($migcms_linked_file{id} > 0)
				{
					$docs{$type_document{short_1}} .= << "EOH";
						<a href="$migcms_last_published_file" data-toggle="tooltip" data-placement="right" title="$type_document{type_1}" target="_blank"><img  src="$img" /></a>
EOH
				}
				
			}
		}

		# my $dates_documents = Dumper(\%docs_date);
		# my $liste_documents = Dumper(\%docs);
		
		
		my $dates_documents = '<table class="table table-striped table-bordered" style="margin:0px;">';
		# my $liste_documents = '<table class="table table-striped">';
		
		foreach my $elt (sort keys %docs_date)
		{
			$elt_d = $elt;
			if($elt_d eq 'ELE')
			{
				$elt_d = 'ELEC';
			}
			$dates_documents .= <<"EOH";
				<tr>
					<td style="line-height:25px;"><b>$elt_d</b> $docs_date{$elt}</td>
					<td style="width:25px;">$docs{$elt}</td>
				</tr>
EOH
			# $liste_documents .= <<"EOH";
			
# EOH
		}
		
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        my $yyyy =  1900+$year; 
		my $mm = sprintf("%02d",$mon);
		my $dd = sprintf("%02d",$mday);
		my $num = sprintf("%02d",$commande{id});
		my $numcomm = $yyyy.$mm.$dd.$num;
		 
		
		$dates_documents .= '</table>';
		# $liste_documents .= '</table>';
# <td>$liste_documents</td>
		$page .= <<"EOH";	
			<tr>
				<td data-th="Coordonnées">
					<b>COMMANDE N° $commande{id}</b><br />
					<b>Bien:</b><br />
					$commande{adresse_rue} $commande{adresse_numero} <br />
					$commande{adresse_cp} $commande{adresse_ville} <br />
					<b>Client:</b><br />
					$commande{street} $commande{number} <br />
					$commande{zip} $commande{city} <br />
					<b>Facturation:</b><br />
					$commande{facture_prenom} $commande{facture_nom} <br />
					$commande{facture_street} $commande{facture_number} <br />
					$commande{facture_zip} $commande{facture_city} <br />
					$commande{facture_societe_nom} $commande{facture_societe_tva}
				</td>      
				<td data-th="Date des visites & rapports"><small>$dates_documents</small></td>
				<td data-th="Facture"><small>$links_to_facture $commande{remarque_facturation}</small></td>
				<td data-th="Détails" class="text-center"><small><a href="$self&sw=get_detail_commande&amp;token=$commande{token_commande}">Détails</a></small></td>
			</tr>
EOH
	}	
	$page .= <<"EOH";
				</table>
				<br />
				<div class="text-center"><a class="btn-custom3" href ="$full_self&sw=commande_etape&go_to_step=1">Effectuer une nouvelle demande</a></div>

			</div>
		</div>
		</section>
EOH

	display($page);
}


sub espace_perso_old2
{
	see();
	my $cookie_order = $cgi->cookie('certigreen_handmade');  		
	
	#si pas cookie
	if($cookie_order eq '')       
    { 
		http_redirect("$full_self&sw=connexion&ret=espace_perso"); 
		exit;
	}
	$cookie_order_ref=decode_json $cookie_order;
    my %hash_member=%{$cookie_order_ref}; 
	my %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});  
	
	#si pas connecte
	if(!($member{id} > 0))       
    { 
		http_redirect("$full_self&sw=connexion&ret=espace_perso"); 
		exit;
	}
	
	#valeurs de recherche
	my $nom_client = get_quoted('nom_client');
	my $numero_commande = get_quoted('numero_commande');
	my $numero_facture = get_quoted('numero_facture');
	my $page = <<"EOH";
	<div id="deconnect-btn"><a class="btn btn-primary btn-md deco" href="$self&sw=logout_db" data-original-title="" title="">Déconnexion</a></div>
			<h2>Mon espace Certigreen</h2>
			<br />
EOH
	
	
	if($member{type_member} eq "Agence")
    {               
		$page .= <<"EOH";
			
			<!-- FORMULAIRE DE RECHERCHE -->
			<form method="post" action="$self">
				<input type="hidden" name="sw" value="espace_perso" />
				<div class="container">
					<div class="row">
						<div class="col-md-5">
							<input type="text" placeholder="Nom du client" name="nom_client" value="$nom_client" class="form-control input-sm">
						</div>
						<div class="col-md-5">
							<input placeholder="N° commande" type="text" name="numero_commande" value="$numero_commande" class="form-control input-sm">
						</div>
						<div class="col-md-5">
							<input  placeholder="N° facture" type="text" name="numero_facture" value="$numero_facture" class="form-control input-sm">
						</div>
						<div class="col-md-5">
							<button type="submit" class="btn btn-info btn-block">Rechercher</button>
						</div>
					</div>
				</div>
				<br/>
				<br/>				
			</form>
EOH
	}
	
	$page .= <<"EOH";
		<!-- Liste des demandes -->
		<table class="table table-bordered" id="table_espace">
			<tr>
				<th>Client</th>
				<th>Adresse</th>      
				<th>Factures</th>
				<th>Type d\'expertise</th>
				<th>Détails</th>
			</tr>
EOH

	my @commandes = ();
	if ($member{type_member} eq "Agence")
	{
		my $nom_client = get_quoted('nom_client');
		my $numero_commande = get_quoted('numero_commande');
		my $numero_facture = get_quoted('numero_facture');
		my @where = ();
		
		push @where, " c.id_member = m.id  ";
		push @where, " id_agence='$member{id}'  ";
		push @where, " validation='1'  ";
		
		if($nom_client ne '')
		{
			push @where, " lastname LIKE '%$nom_client%' ";
		}	
		if($numero_commande ne '')
		{
			push @where, " c.id = '$numero_commande' ";
		}
		if($numero_facture ne '')
		{
			push @where, " c.id IN (select commande_id from factures where numero = '$numero_facture') ";
		}
		my $supp_where = join(" AND ",@where);
		
		@commandes = sql_lines({dbh=>$dbh2,select=>"c.*,m.*,c.id as commande_id",debug=>0,debug_results=>0,table=>'intranet_factures c, members m',where=> $supp_where});
	}
	else
	{
		@commandes = sql_lines({dbh=>$dbh2,select=>"c.*,c.id as commande_id",debug=>0,debug_results=>0,table=>'intranet_factures c',where=>"id_member='$member{id}'"});
	}

	foreach my $commande (@commandes)
    { 
		my %commande = %{$commande};
		my %client = sql_line({dbh=>$dbh2,table=>'members',where=>"id='$commande{id_member}'"});
		
		#membre
		$client{lastname} = uc($client{lastname});
		$client{firstname} = ucfirst(lc($client{firstname}));
		
		#lien facture
		# my %facture = sql_line({table=>'intranet_factures', dbh=>$dbh2, where=>"commande_id = '$commande{commande_id}'" });
		my %facture = sql_line({table=>'intranet_factures', dbh=>$dbh2, where=>"table_record='intranet_factures' AND id_record = '$commande{commande_id}'" });

		my $link_to_facture = get_facture_link($commande{commande_id});	
		if($facture{total_tvac} > 0)
		{
			$link_to_facture .= '<br />€ '.$facture{total_tvac}.' TVAC';
		}
		
		#liste documents
		my @commande_documents =  sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',where=>"commande_id='$commande{commande_id}'"});
		
		my $liste_documents = '<table class="">';
		foreach my $document (@commande_documents)
		{
			my %document = %{$document};
			see(\%document);
			
			#liste des documents
			my %type_document = sql_line({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'types_document',where=>"id='$document{type_document_id}'"}); 
			$liste_documents .= << "EOH";
				<tr>
					<td>
						$type_document{type_1} 
					</td>
EOH
		    
			#liste des dates
			if ($document{date_prevue} ne "")
		    {
			   $liste_documents .= << "EOH";
			   <td>			   
			   Prévu le $document{date_prevue}
EOH
			    if($document{heure_prevue} ne "")
			    {
				   $liste_documents .= " à ".$document{heure_prevue};
				}
				$liste_documents .= '</td>';
		    }
			else
			{
				$liste_documents .= "<td><span style='color:grey;'>Date non fixée</span></td>";
			}
			$liste_documents .= << "EOH";
					</tr>
EOH
		}
		$liste_documents .= << "EOH";
				</table>
EOH
			
		$page .= <<"EOH";
			<tr>
				<td><b>$client{lastname}</b> $client{firstname}</td>
				<td>$client{street} $client{number} $client{box}<br />$client{zip} $client{city}</td>      
				<td>$link_to_facture</td>
				<td>$liste_documents</td>
				<td><a href="$self&sw=get_detail_commande&amp;token=$commande{token}">Détails <br>commande N°$commande{commande_id}</a></td>
			</tr>
EOH
	}	
	$page .= <<"EOH";
			</table>
			<br /><br />
			<a class="btn btn-primary btn-md btn-step5" href ="$full_self&sw=commande_etape&go_to_step=1&token=">Effectuer une nouvelle demande</a>
EOH

	display($page);
}
################################################################################
# espace_perso 
################################################################################
sub espace_perso_old
{
#    see();
   my $cookie_order = $cgi->cookie('certigreen_handmade');  
  
           
    #si user est connecté
    if($cookie_order ne "")       
    {                  
        my %hash_member;       
        my %member = ();
        
        $cookie_order_ref=decode_json $cookie_order;
        %hash_member=%{$cookie_order_ref};    
        
        if($hash_member{token_member} ne '')
        {
           %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"token='$hash_member{token_member}'"});  
           
           my $table_espace = <<"EOH";
                <table class="table table-bordered" id="table_espace">
                    <tr>
                        <th>Client</th>
                        <th>Adresse</th>      
                        <th>Factures TVAC</th>
                        <th>Type d\'expertise</th>
                        <th>État</th>
                        <th>Détails</th>
                    </tr>
EOH
            
           #############   si c'est un Agence   #############
           if ($member{type_member} eq "Agence")
           {    
#                 see(); print "Agence"; exit;  
                my @all_clients_commandes = sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members m, intranet_factures c',where=>"c.id_member=m.id AND m.id_member_agence='$member{id}' AND c.validation='1'"});

                ######    boucle des clients   ########
                if($#all_clients_commandes != -1)
                {               
  #                 see(); print scalar(@all_clients_commandes);    #ok  
                    foreach my $one_client_commande (@all_clients_commandes)
                    {                                         
                        my $nom_adresse = '';
                        my $doc = ''; 
                        my $etat = '';
                        my $paye = '';
                        my $detail = '';
                        
                        my %commande = %{$one_client_commande};
                         
                        ########## combient des DOCUMENTS par une commande 
                        my @types_doc_commande =  sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',where=>"commande_id='$commande{id}'"});
                        my $nombre_lignes = scalar(@types_doc_commande);  
#                         see(); print $nombre_lignes;           exit;
                        
                        if($nombre_lignes != 0)
                        {
                             my $adresse = $commande{adresse_rue}." ".$commande{adresse_numero}.", ". $commande{adresse_cp}.", ". $commande{adresse_ville};     
                             
                             $table_espace .= <<"EOH";
                                  <tr>
                                      <td rowspan="$nombre_lignes">$commande{id}<b><span style = "text-transform: uppercase;"> $commande{lastname}</span></b> $commande{firstname} </td>  
                                      <td rowspan="$nombre_lignes">$adresse</td>
EOH
                             
                             #verifie s'il ya des doc pas facturés                             
                             my @docs_pas_facture = sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',where=>"commande_id='$commande{id}' AND id_facture='0'"}); 
                             my $nombre_docs_pas_facture = scalar(@docs_pas_facture);      
                             
                             #combient des factures et pour quels documents                                                                                 
                             # my @factures =  sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"commande_id='$commande{id}'"});
					 		my @factures = sql_line({table=>'intranet_factures', dbh=>$dbh2, where=>"table_record='intranet_factures' AND id_record = '$commande{commande_id}'" });

                             my $nombre_factures = scalar(@factures); 
							 if($commande{alt_facture_url} ne '')
							 {
							 }
                             
#                              see(); print $nombre_docs_pas_facture;    print " - ".$nombre_factures;        exit;
                             
                             my $i = 1;     #compteur pour mettre "Detail" juste une fois
                             
                             #si il y a des factures
                             if($nombre_factures > 0)
                             {
                                  foreach my $une_facture (@factures)
                                  {                                         
                                       my %facture = %{$une_facture};         
                                       
                                       my @one_facture_docs =  sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',where=>"commande_id='$commande{id}' AND id_facture='$facture{id}'"});
                                       my $nombre_docs_facture = scalar(@one_facture_docs);      #pour rowspan
                                                                                
                                       #print $facture{id}."<br>";  #ok   
                                       my $href_facture = '';
                                       my $infobulle = "";
                                       if($facture{visible} eq 'y')
									   {
										   if(($facture{id} ne '') && ($facture{statut} eq 'pending'))
										   {
												$infobulle = "<span>Paiement non effectué. Merci de régler la facture afin de débloque le certificat signé et l'envoi des originaux par courrier.</span>";
												$href_facture = "<a class='info_red' href ='#'><i style='font-size:40px;' class='fa fa-file-text-o'></i>".$infobulle."</i> </a> <a class='info_red' href ='".$full_self."&sw=get_facture&token=".$facture{token}."'>Facture (non payée) </a>";     
										   }
										   elsif(($facture{id} ne '') && ($facture{statut} eq 'partiel'))
										   {
												$infobulle = "<span>Paiement est partiellement effectué. <br>La somme payée est ".$facture{montant_paye}."€.<br>Le reste à payer est ".$facture{montant_restant}."€. </span>";
												$href_facture = "<a class='info_orange' href ='#'><i style='font-size:40px;' class='fa fa-file-text-o'></i>".$infobulle."</i> </a> <a class='info_orange' href ='".$full_self."&sw=get_facture&token=".$facture{token}."'>Facture (partiellement payée) </a>";
										   } 
										   elsif(($facture{id} ne '') && ($facture{statut} eq 'paid'))
										   {
												$href_facture = "<a class='info_green' href ='#'><i style='font-size:40px;' class='fa fa-file-text-o'>".$infobulle."</i></a> <a class='info_green' href ='".$full_self."&sw=get_facture&token=".$facture{token}."'>Facture (payée) </a>";
										   }
									   }
									   else
									   {
											$href_facture = "Facture non disponible";
									   }
                                       
                                       
                                       $table_espace .= <<"EOH";
                                          <td rowspan="$nombre_docs_facture">
                                              $facture{total_tvac} €  <br>
                                              $href_facture 
                                          </td>
EOH
                                       my $href_detail_commande = "<a href ='".$full_self."&sw=get_detail_commande&token=".$commande{id}."' > Detail </a>"; 
                                       
                                       foreach my $one_doc_facture (@one_facture_docs)
                                       {
                                           my %one_doc_fact = %{$one_doc_facture};
										   
                                           my %name_type = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'types_document',where=>"id='$one_doc_fact{type_document_id}'"});
                                           my ($annee,$mois,$jour) = split (/\-/,$one_doc_fact{date_realisee}); 
                                           my $date_realisee =  $jour."/".$mois."/".$annee;   
                                           
                                           my $date_prevu = "<span style='color:grey;'>Date non fixee</span>";
                                           if ($one_doc_fact{date_prevue} ne "")
                                           {
                                               $date_prevu = "Prévu le ".$one_doc_fact{date_prevue};
                                           }
                                           
                                           if(($one_doc_fact{url} ne "") && ($one_doc_fact{disponible} eq "y"))
                                           {
                                               $date_prevu = "<a href ='".$full_self."&sw=get_document&token=".$commande{token}."&id_document=$one_doc_fact{id}'>Réalisé le ".$date_realisee."</a>";
                                           }
                                           elsif(($one_doc_fact{url} ne "") && ($one_doc_fact{disponible} ne "y"))
                                           {
                                               $date_prevu = "Réalisé le ".$date_realisee."";
                                           }
                                           
                                           $table_espace .= <<"EOH"; 
                                              <td class="cell_document"><img src="../skin/img/$name_type{icon}" alt="" /> $name_type{type_1}</td>  
                                              <td>$date_prevu</td>
EOH

                                              if ($i == 1)
                                              {
#                                                    see(); print $i; exit;
                                                   $table_espace .= <<"EOH"; 
                                                   <td rowspan="$nombre_lignes">
                                                         <a href="$full_self&sw=get_detail_commande&token=$commande{token}">
                                                                Détails
                                                         </a>
                                                   </td>
EOH
                                                  $i++;
                                              }
                                              
                                           $table_espace .= "</tr>";     
                                           
                                       }
  
                                  } 
                             }    # FIN : if($nombre_factures > 0)   
                             
                             
                             if($nombre_docs_pas_facture > 0)    #s'il y a des documents pas encore facturés
                             {
                                   
                                   $table_espace .= <<"EOH";
                                        <td rowspan="$nombre_docs_pas_facture">
                                            pas facturé
                                        </td>
EOH
                                 
                                  foreach my $doc (@docs_pas_facture)
                                  {
                                        %doc = %{$doc};
										
										my %appartement = ();
										 if($doc{id_appartement} > 0)
										 {
											%appartement = read_table($dbh2,'commande_appartements',$doc{id_appartement});
										 }
										
										# see(\%doc);
                                        my %name_type = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'types_document',where=>"id='$doc{type_document_id}'"});
                                        my ($annee,$mois,$jour) = split (/\-/,$doc{date_realisee}); 
                                        my $date_realisee =  $jour."/".$mois."/".$annee; 
                                        
#                                           print Dumper(\%doc);        
                                        my $date_prevu = "<span style='color:grey;'>Aucune date fixee</span>";
                                         if ($doc{date_prevue} ne "")
                                         {
                                             $date_prevu = "Prévu le ".$doc{date_prevue};
                                         }
                                         
                                         if($doc{url} ne "" && $doc{disponible} eq 'y')
                                         {
                                             $date_prevu = "<a href ='".$full_self."&sw=get_document&token=".$commande{token}."&id_document=$doc{id}'>Réalisé le ".$date_realisee."</a>";
                                         }
										 elsif ($doc{date_prevue} ne "")
                                         {
                                             $date_prevu = "Prévu le ".$doc{date_prevue};
                                         }
                                         # <img src="../skin/img/$name_type{icon}" alt="" />
                                         $table_espace .= <<"EOH"; 
                                            <td class="cell_document2"> $name_type{type_1} <i>$appartement{nom}</i></td>  
                                            <td>$date_prevu</td>
EOH
                                            if ($i == 1)
                                            {
                                                 $table_espace .= <<"EOH"; 
                                                 <td rowspan="$nombre_lignes"><a href="$full_self&sw=get_detail_commande&token=$commande{token}">Détails</a></td>
EOH
                                                 $i++;
                                            } 
                                                                                        
                                         $table_espace .= "</tr>";                     
                                  }                                              
                             }                                                          
                             
                        }
                    }                 
                }
                else
                {
                    $table_espace .= <<"EOH";
                    <tr>
                        <td colspan="6"> Il n'y a pas des clients enrégistrés.</td>
                    </tr>
EOH
                }                                        
#                  exit; 
           } #if ($member{type_member} eq "Agence")    
           #############   si c'est un Particulier   #############
           else
           {
                my @all_commandes = sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures c',where=>"c.id_member='$member{id}'"});
#                 print Dumper(@all_commandes);
                
                if($#all_commandes != -1)
                {                    
                    foreach my $one_commande (@all_commandes)
                    {
                        my $nom_adresse = '';
                        my $doc = ''; 
                        my $etat = '';
                        my $paye = '';
                        my $detail = '';
                        
                        my %commande = %{$one_commande};
                        
                        ########## combient des DOCUMENTS par commande 
                        my @types_doc_commande =  sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',where=>"commande_id='$commande{id}'"});
                        my $nombre_lignes = scalar(@types_doc_commande);                                        
#                         print Dumper(@types_doc_commande)."<br>";  #ok 

                        my $i = 1;
                        if($nombre_lignes != 0)
                        {
                             my $adresse = $commande{adresse_rue}." ".$commande{adresse_numero}.", ". $commande{adresse_cp}.", ". $commande{adresse_ville};     
                             
                             $table_espace .= <<"EOH";
                                  <tr>
                                      <td rowspan="$nombre_lignes">$commande{id}<b><span style = "text-transform: uppercase;"> $member{lastname}</span></b> $member{firstname} </td>  
                                      <td rowspan="$nombre_lignes">$adresse</td>
EOH
                             
                             #verifie s'il ya des doc pas facturés                             
                             my @docs_pas_facture = sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',where=>"commande_id='$commande{id}' AND id_facture='0'"}); 
                             my $nombre_docs_pas_facture = scalar(@docs_pas_facture);  
                             
                             #combient des factures et pour quels documents                                                                                 
                             my @factures =  sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"commande_id='$commande{id}'"});
                             my $nombre_factures = scalar(@factures);
                             
#                              see(); print $nombre_factures; exit; 
                             
                             #si il y a des factures
                             if($nombre_factures > 0)
                             {
                                  foreach my $une_facture (@factures)
                                  {                                         
                                       my %facture = %{$une_facture};         
                                       
                                       my @one_facture_docs =  sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',where=>"commande_id='$commande{id}' AND id_facture='$facture{id}'"});
                                       my $nombre_docs_facture = scalar(@one_facture_docs);      #pour rowspan
                                                                                
                                       #print $facture{id}."<br>";  #ok   
                                       my $href_facture = '';
                                       my $infobulle = "";
                                       if(($facture{id} ne '') && ($facture{statut} eq 'pending'))
                                       {
                                            $infobulle = "<span>Paiement non effectué. Merci de régler la facture afin de débloque le certificat signé et l'envoi des originaux par courrier.</span>";
                                            $href_facture = "<a class='info_red' href ='#'><i style='font-size:40px;' class='fa fa-file-text-o'></i>".$infobulle."</i> </a> <a href ='".$full_self."&sw=get_facture&token=".$facture{token}."'>Facture </a>";     
                                       }
                                       elsif(($facture{id} ne '') && ($facture{statut} eq 'partiel'))
                                       {
                                            $infobulle = "<span>Paiement est partiellement effectué. <br>La somme payée est ".$facture{montant_paye}."€.<br>Le reste à payer est ".$facture{montant_restant}."€. </span>";
                                            $href_facture = "<a class='info_orange' href ='#'><i style='font-size:40px;' class='fa fa-file-text-o'></i>".$infobulle."</i> </a> <a href ='".$full_self."&sw=get_facture&token=".$facture{token}."'>Facture </a>";
                                       } 
                                       elsif(($facture{id} ne '') && ($facture{statut} eq 'paid'))
                                       {
                                            $href_facture = "<i style='font-size:40px;' class='fa fa-file-text-o'>".$infobulle."</i> <a href ='".$full_self."&sw=get_facture&token=".$facture{token}."'>Facture </a>";
                                       }
                                       
                                       
                                       $table_espace .= <<"EOH";
                                          <td rowspan="$nombre_docs_facture">
                                              $facture{total_tvac} €  <br>
                                              $href_facture 
                                          </td>
EOH
                                       my $href_detail_commande = "<a href ='".$full_self."&sw=get_detail_commande&token=".$commande{id}."' > Detail </a>"; 
                                       
                                       foreach my $one_doc_facture (@one_facture_docs)
                                       {
                                           my %one_doc_fact = %{$one_doc_facture};
                                           my %name_type = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'types_document',where=>"id='$one_doc_fact{type_document_id}'"});
                                           my ($annee,$mois,$jour) = split (/\-/,$one_doc_fact{date_realisee}); 
                                           my $date_realisee =  $jour."/".$mois."/".$annee;   
                                           
                                           my $date_prevu = "<span style='color:grey;'>Date n'est pas prévue</span>";
                                           if ($one_doc_fact{date_prevue} ne "")
                                           {
                                               $date_prevu = "Prévu le ".$one_doc_fact{date_prevue};
                                           }
                                           
                                           if(($one_doc_fact{url} ne "") && ($one_doc_fact{disponible} eq "y"))
                                           {
                                               $date_prevu = "<a href ='".$full_self."&sw=get_document&token=".$commande{token}."&id_document=$one_doc_fact{id}'>Réalisé le ".$date_realisee."</a>";
                                           }
                                           elsif(($one_doc_fact{url} ne "") && ($one_doc_fact{disponible} ne "y"))
                                           {
                                               $date_prevu = "Réalisé le ".$date_realisee."";
                                           }
                                           
                                           $table_espace .= <<"EOH"; 
                                              <td class="cell_document3"><img src="../skin/img/$name_type{icon}" alt="" /> $name_type{type_1}</td>  
                                              <td>$date_prevu</td>
EOH

                                              if ($i == 1)
                                              {
#                                                    see(); print $i; exit;
                                                   $table_espace .= <<"EOH"; 
                                                   <td rowspan="$nombre_lignes">
                                                         <a href="$full_self&sw=get_detail_commande&token=$commande{token}">
                                                                Détails
                                                         </a>
                                                   </td>
EOH
                                                  $i++;
                                              }
                                              
                                           $table_espace .= "</tr>";     
                                           
                                       }
  
                                  }
                             }
                             
                             if($nombre_docs_pas_facture > 0)    #s'il y a des documents pas encore facturés
                             {
                                   
                                   $table_espace .= <<"EOH";
                                        <td rowspan="$nombre_docs_pas_facture">
                                            pas facturé
                                        </td>
EOH
                                 
                                  foreach my $doc (@docs_pas_facture)
                                  {
                                        %doc = %{$doc};
                                        my %name_type = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'types_document',where=>"id='$doc{type_document_id}'"});
                                        my ($annee,$mois,$jour) = split (/\-/,$doc{date_realisee}); 
                                        my $date_realisee =  $jour."/".$mois."/".$annee; 
                                        
#                                           print Dumper(\%doc);        
                                        my $date_prevu = "<span style='color:grey;'>Date n'est pas prévue</span>";
                                         if ($doc{date_prevue} ne "")
                                         {
                                             $date_prevu = "Prévu le ".$doc{date_prevue};
                                         }
                                         
                                         if($doc{url} ne "")
                                         {
                                             $date_prevu = "<a href ='".$full_self."&sw=get_document&token=".$commande{token}."&id_document=$doc{id}'>Réalisé le ".$date_realisee."</a>";
                                              
                                         }
										 my %appartement = ();
										 if($doc{id_appartement} > 0)
										 {
											%appartement = read_table($dbh2,'commande_appartements',$doc{id_appartement});
										 }
                                         
                                         $table_espace .= <<"EOH"; 
                                            <td class="cell_document4"><img src="../skin/img/$name_type{icon}" alt="" /> $name_type{type_1} <i>$appartement{nom}</i></td>  
                                            <td>$date_prevu</td>
EOH
                                            if ($i == 1)
                                            {
                                                 $table_espace .= <<"EOH"; 
                                                 <td rowspan="$nombre_lignes"><a href="$full_self&sw=get_detail_commande&token=$commande{token}">Détails</a></td>
EOH
                                                 $i++;
                                            } 
                                                                                        
                                         $table_espace .= "</tr>";                     
                                  }                                              
                             }
                        }
                    }
                }
                else
                {
                    $table_espace .= <<"EOH";
                    <tr>
                        <td colspan="6"> Il n'y a pas des commandes enrégistrés.</td>
                    </tr>
EOH
                }
           }
           
           
            $table_espace .= '</table>';     
                                                       
            my $page = <<"EOH";
          	<script type="text/javascript">
          		jQuery(document).ready( function () 
          		{                
                    init_form();

                    jQuery(".contenu").css("width", "920px");
                    jQuery(".contenu").css("margin", "0 auto");
          	  });
            </script>
            
            <style>
                a.info_red{
                    position:relative;
                    z-index:24;
                    color:red;
                    text-decoration:none
                }
                
                a.info_red:hover{
                    z-index:25;
                }
                
                a.info_red span{
                    display: none
                }
                
                a.info_red:hover span{
                    display:block;
                    position:absolute;
                    top:2em; left:-12em; width:15em;
                    border:1px solid red;
                    border-radius:5px;
                    font-family: "Helvetica Neue",Helvetica,Arial,sans-serif;
                    background-color:#FFF;
                    color:#5F5F5F;
                    text-align: justify;
                    font-weight:none;
                    padding:10px;
                    line-height: 115%;
                    box-shadow: 2px 2px 5px 2px #CECECE ;
                }
                
                a.info_orange{
                    position:relative;
                    z-index:24;
                    color: #FF8D00;
                    text-decoration:none
                }
                
                a.info_orange:hover{
                    z-index:25;
                }
                
                a.info_orange span{
                    display: none
                }
                
                a.info_orange:hover span{
                    display:block;
                    position:absolute;
                    top:2em; left:-12em; width:15em;
                    border:1px solid #FF8D00;
                    border-radius:5px;
                    font-family: "Helvetica Neue",Helvetica,Arial,sans-serif;
                    background-color:#FFF;
                    color:#5F5F5F;
                    text-align: justify;
                    font-weight:none;
                    padding:10px;
                    line-height: 115%;
                    box-shadow: 2px 2px 5px 2px #CECECE ;
                }               
                
                .info_green{
                    color: #299804;
                }
                
                
            </style>
            
             
            <div id="deconnect-btn-espace"><a href="$self&sw=logout_db" data-original-title="" title="" class="btn btn-primary btn-md">Déconnexion</a></div>
            
                <h2>Mon espace Certigreen</h2> 
          			<div class="col-md-12 col-md-offset-"> 
                      
                 $table_espace       
              		                       
                </div>
                <div id="new_demande"><a class="btn btn-primary btn-md" href="$full_self&sw=commande_etape&go_to_step=1&token=">Effectuer une nouvelle demande</a></div>
EOH
            see();
			      display($page);
        } #if($hash_member{token_member} ne '')
     }
     #si user n'est pas connecté
     else
     {
         see();
  		 # print 'no cookie';
  		 http_redirect("$full_self&sw=connexion&ret=espace_perso"); 
     } 
   
   
}                


























    

###############################################################################
# signup_ok
###############################################################################
# sub signup_ok
# {
    # see();
    # $token = get_quoted('token');
    # my %member = sql_line({dbh=>$dbh2,table=>'members',where=>"token='$token'"});  

    # my $page =<<"EOH";
       # <br /><br />
      # <div class="panel panel-success">
  # <div class="panel-heading">
    # <h3 class="panel-title">Inscription terminÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©e</h3>
  # </div>
  # <div class="panel-body">
    # Bienvenue sur clproj, votre inscription est terminÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©e !
    # <br />Vous pouvez dÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©sormais vous connecter avec votre adresse email et le mot de passe que vous avez choisi.
  # </div>
# </div>
# EOH
    # display($page);
# }


################################################################################
# edit_ok
################################################################################
sub edit_ok
{
    see();
    $token = get_quoted('token');
    my %member = sql_line({dbh=>$dbh2,table=>'members',where=>"token='$token'"});  

    my $page =<<"EOH";
       <br /><br />
      <div class="panel panel-success">
  <div class="panel-heading">
    <h3 class="panel-title">Profil mis ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â  jour</h3>
  </div>
  <div class="panel-body">
   Merci ! Vos donnÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©es ont ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©tÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©s adaptÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©es.
  </div>
</div>
EOH
    display($page);
}
       




################################################################################
# detail_get_ajax
################################################################################ 
sub detail_get_ajax
{
    my $token = get_quoted('token') || 1;
    see();
    print detail($token,'ajax');
    exit;
} 



#detail_get_content_lightbox_ajouter_favori***************************************
sub detail_get_content_lightbox_ajouter_favori
{
    my %d = %{$_[0]};
    my $commentaires = get_form_line(
                                  {
                                      type => 'textarea',
                                      name =>'commentaires', 
                                      prefix => '',
                                      rows => 6,
                                      label=>$sitetxt{im_ajouterFavoris_commentaires}, 
                                      style=>'',
                                      size_col_label => 12,     
                                      size_col_field => 12,
                                  }
                              );
                              
  return <<"EOH";
      <div id="annonce_ajouter_favori" style="display:none;">
            <h1>Ajouter ce bien a vos favoris</h1>
            <hr />
            <div class="row">
                  <div class="col-md-4">
                      <img src="pics/$d{photo}{file}_medium.$d{photo}{ext}" style="width:250px;" />
                          <br />$d{type_bien}{type_1} 
                          <br />$d{annonce}{situation_ville}
                          <br />$d{prix} $devise
                  </div>
                  <div class="col-md-8">
                      <form class="form-horizontal" method="post" action="$full_self">
                            <fieldset>
                            
                            $commentaires
                            
                             <button class="btn btn-primary btn-block" type="submit">$sitetxt{im_favori_button}</button>
                            
                            </fieldset>
                            </form>
                  </div>
            </div>
        </div>                    
EOH
}
 

sub detail_get_content_lightbox_signaler_erreur
{
    my %d = %{$_[0]};
    
    my $commentaires = get_form_line(
                                  {
                                      type => 'textarea',
                                      name =>'commentaires', 
                                      prefix => '',
                                      rows => 6,
                                      label=>'Votre Message', 
                                      style=>'',
                                      size_col_label => 12,     
                                      size_col_field => 12,
                                  }
                              );
    
     return  <<"EOH";
           <div id="annonce_signaler_erreur" style="display:none;">
            <h1>$sitetxt{lightbox_signaler_erreur_title}</h1>
            <hr />
            <div class="row">
                  <div class="col-md-4">
                      <img src="pics/$d{photo}{file}_medium.$d{photo}{ext}" style="width:250px;" />
                          <br />$d{type_bien}{type_1} 
                          <br />$d{annonce}{situation_ville}
                          <br />$d{prix} $devise
                  </div>
                  <div class="col-md-8">
                      <form class="form-horizontal" method="post" action="$full_self">
                            <fieldset>
                            
                            <div class="form-group">
                              <label class="col-md-4 control-label" for="lastname">Nom</label>  
                              <div class="col-md-4">
                              <input id="lastname" name="lastname" placeholder="" class="form-control input-md" required="" type="text">
                                
                              </div>
                            </div>
                            <div class="form-group">
                              <label class="col-md-4 control-label" for="email">$sitetxt{im_contact_AdresEmail} *</label>  
                              <div class="col-md-4">
                              <input id="email" name="email" required placeholder="" class="form-control input-md" type="text">
                              <span class="help-block">($sitext{optionnel})</span>  
                              </div>
                            </div>
                            
                            $commentaires
                            
                             <button class="btn btn-primary btn-block" type="submit">$sitetxt{im_contact_Envoyer}</button>
                            
                            </fieldset>
                            </form>
                  </div>
            </div>
        </div>
EOH
}


sub detail_get_content_lightbox_contact_form
{
    my %d = %{$_[0]};
    
    #nom--------------------------------------------------------------
      my $nom = get_form_line(
                                  {
                                      type => 'input',
                                      name =>'nom', 
                                      label=>$sitetxt{im_contact_nom}, 
                                      style=>'',
                                      size_col_label => 12,     
                                      size_col_field => 12,
                                  }
                              );
     #prenom--------------------------------------------------------------
      my $prenom = get_form_line(
                                  {
                                      type => 'input',
                                      name =>'prenom', 
                                      label=>$sitetxt{im_contact_prenom}, 
                                      style=>'',
                                      size_col_label => 12,     
                                      size_col_field => 12,
                                  }
                              );
      #telephone--------------------------------------------------------------
      my $telephone = get_form_line(
                                  {
                                      type => 'input',
                                      name =>'telephone', 
                                      label=>$sitetxt{im_contact_Telephone}, 
                                      style=>'',
                                      size_col_label => 12,     
                                      size_col_field => 12,
                                  }
                              );
       #email--------------------------------------------------------------
      my $email = get_form_line(
                                  {
                                      type => 'input',
                                      name =>'email', 
                                      label=>$sitetxt{im_contact_AdresEmail}, 
                                      style=>'',
                                      size_col_label => 12,     
                                      size_col_field => 12,
                                  }
                              );
      #commentaires--------------------------------------------------------------
      my $commentaires = get_form_line(
                                  {
                                      type => 'textarea',
                                      name =>'commentaires', 
                                      prefix => '',
                                      rows => 6,
                                      label=>$sitetxt{im_sauvegarde_step5_commentaires}."<span style='font-weight:normal;'>".$sitetxt{im_sauvegarde_step5_optionnel}."</span>", 
                                      style=>'',
                                      size_col_label => 12,     
                                      size_col_field => 12,
                                  }
                              );
    
     return <<"EOH";
            <div id="annonce_contact_form" style="display:none;">
            <h1>$sitetxt{im_bien_Interesse_ceBien}</h1>
            <hr />
            <div class="row">
                  <div class="col-md-4">
                      <img src="pics/$d{photo}{file}_medium.$d{photo}{ext}" style="width:250px;" />
                          <br />$d{type_bien}{type_1} 
                          <br />$d{annonce}{situation_ville}
                          <br />$d{prix} $devise
                  </div>
                  <div class="col-md-8">
                      
                      <form method="post" action="$full_self">
                      <input type="hidden" name="annonce_contact_db" />
                      
                      $nom
                      $prenom
                      $telephone
                      $email
                      $commentaires 
                      
                      <div class="control-group">
                         <label class="control-label"></label>
                         <div class="controls">
                            <button type="submit" class="btn btn-primary">$sitetxt{im_bien_Interesse_envoyer}</button>
                         </div>
                      </div>
                     
                  </div>
            </div>
        </div>
EOH
}



# sub login_form
# {
      # see();
      # my %member = %{get_member({debug=>0})};
      # if($member{token} ne '')
      # {
          # http_redirect($self."&sw=signup_form&token_member=$member{token}");
          # exit;
      # }
      
      # my $page =<<"EOH";
      # $error_msg
      # <div id="eshop" class="clearfix">
            # <div class="login-form">
				# <h1>$sitetxt{login_form_1}</h1>
				# <form class="form-horizontal" id="form_deja_client" method="post" id="$self">
				# <input type="hidden" name="sw" value="login_db" />
				# <input type="hidden" name="lg" value="$lg" />

				  # <div class="form-group">
					  # <label class="col-sm-4 control-label" for="inputEmail">Email</label>
					  # <div class="col-sm-8">
						  # <input type="text" name="email" required class="required form-control" id="inputEmail" placeholder="Adresse email" />
						  # <span class="help-block">($sitetxt{'obligatoire'})</span>
					  # </div>
				  # </div>
				  # <div class="form-group">
					  # <label class="col-sm-4 control-label" for="inputPassword">Mot de passe</label>
					  # <div class="col-sm-8">
						  # <input type="password" name="password" required class="required form-control" id="inputPassword" placeholder="" />
						  # <span class="help-block">($sitetxt{'obligatoire'})</span>
					  # </div>
				 # </div>
				 # <div class="form-group">
					  # <div class="col-sm-4"></div>
					  # <div class="col-sm-8">
						  # <a href="$self&sw=lost_password_form" class="">$sitetxt{login_form_2}</a>
					  # </div>
				  # </div>
				  # <div class="form-group">
					  # <div class="col-sm-4"></div>
					  # <div class="col-sm-8">
						  # <button type="submit" class="btn btn-info">Connexion</button>
					  # </div>
				  # </div>
				# </form>
            # </div>
           
            # <div class="newaccount-form">
				# <h1>Devenir membre</h1>
        # <p>$sitetxt{login_form_3}.
				# <br /><a class="btn btn-info" href="$self&sw=signup_form">Je m'inscris</a>
        # </div>
      # </div>
	 
	  
	
# EOH
    # display($page);
# }


################################################################################
# lost_password
################################################################################
# sub lost_password_form
# {
    # my $page =<<"EOH";
	
      # <div id="eshop" class="clearfix">
            # <div class="lostpassword-form">
				# <h1>Mot de passe perdu</h1>
				# <p>Entrez votre adresse Email et nous vous enverrons un lien pour changer votre mot de passe.</p>
				# <form class="form-horizontal" method="post" id="lost_password_form">
				# <input type="hidden" name="sw" value = "lost_password_db" />
				# <input type="hidden" name="lg" value = "$lg" />

				  # <div class="form-group">
					# <label class="control-label col-sm-4" for="inputEmail">Email</label>
					# <div class="col-sm-8">
						# <input type="text" name="email" required id="inputEmail" placeholder="" class="required form-control" />
					# </div>
				  # </div>
				  # <div class="form-group">
					  # <div class="col-sm-4"></div>
					  # <div class="col-sm-8">
						  # <button type="submit" class="btn btn-info">Récupérer mon mot de passe</button>
					  # </div>
				  # </div>
				# </form>
            # </div>
      # </div>
# EOH
	
	
    # see();
    # display($page);
# }

################################################################################
# lost_password_ok
################################################################################
sub lost_password_ok
{
    my $page =<<"EOH";
	
      <div id="eshop" class="clearfix">
            <div class="lostpassword-form">
				<h1>Mot de passe perdu</h1>
				<p>Nous vous avons envoye un email vous permettant de changer votre mot de passe.</p>
            </div>
      </div>
EOH
    see();
    display($page);
}

################################################################################
# lost_password_ko
################################################################################
sub lost_password_ko
{
    my $page =<<"EOH";
	
      <div id="eshop" class="clearfix">
            <div class="lostpassword-form">
				<h1>Adresse email erronee</h1>
				<p>L'adresse email n'a pas ete trouve dans notre base de donnees.<p>
				<p>
				  <a class="btn btn-info" href="$self&sw=lost_password_form">Reessayer</a>
				</p>
            </div>
      </div>	
EOH
    see();
    display($page);
}

################################################################################
# edit_password
################################################################################
# sub edit_password
# {
    # my %order = %{get_order()};
    # my $token_member = get_quoted('token_member');
    # my %member = select_table($dbh,"members","","token='$token_member'",'','',0);

    # if(!($order{id_member} > 0) && !($member{id} > 0) )
    # {
        # print "[$order{id_member}][$member{id}]";
        # http_redirect("$self$sws{login}{$lg}");
        # exit;
    # }
    
   # my $error_msg = '';
   # my $error = get_quoted('error');
   # if($error == 1)
   # {
        # $error_msg = <<"EOH";
                  # <div class="alert alert-block alert-error alert-danger">
                    # <h4 class="alert-heading">Erreur de mots de passe</h4>
                    # <p>Les mots de passes ne correspondent pas ou ne sont pas validez, rÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©essayez svp.</p>
                  # </div>
# EOH
   # } 
   
   # my $page = <<"EOH";
	  # <div id="eshop_alert">$error_msg</div>
      # <div id="eshop" class="clearfix">
            # <div class="lostpassword-form">
				# <h1>Modifier votre mot de passe</h1>
				# <form class="form-horizontal" method="post" id="edit_password_form">
				# <input type="hidden" name="sw" value = "edit_password_db" />
				# <input type="hidden" name="lg" value = "$lg" />
				# <input type="hidden" name="token_member" value = "$member{token}" />
				# <input type="hidden" name="token_order" value = "$order{token}" />
				
				# $old_password_bloc

				  # <div class="form-group">
						# <label class="control-label col-sm-4">Nouveau mot de passe</label>
						# <div class="col-sm-8">
							# <input type="password" name="new_password1" required class="required form-control" />
						# </div>
					# </div>
					# <div class="form-group">
						# <label class="control-label col-sm-4">Retapez le mot de passe</label>
						# <div class="col-sm-8">
							# <input type="password" name="new_password2" required class="required form-control" />
						# </div>
					# </div>
					# <div class="form-group">
						# <div class="col-sm-4"></div>
						# <div class="col-sm-8">
							# <button type="submit" class="btn btn-info">Sauvegarder le mot de passe</button>
						# </div>
					# </div>
				# </form>
            # </div>
      # </div>
# EOH
   

 

    # display($page,'',$setup{id_tpl_page2});
# }

################################################################################
# edit_password_ok
################################################################################
sub edit_password_ok
{
    my $page =<<"EOH";
		<div id="eshop" class="clearfix">
            <div class="lostpassword-form">
					<h1>Mot de passe modifie</h1>
				<p>Votre mot de passe a ete modifie avec succes, vous pouvez vous connecter en utilisant vos nouveaux acces.</p>
            </div>
		</div>
	
EOH
    see();
    display($page,'',$setup{id_tpl_page2});
}


#############################################################################
#get_lists_onglets
############################################################################# 
sub get_lists_onglets
{
    my $selitem = $_[0];
    
    my %sels = ();
    $sels{$selitem} = 'active';
        
    return  <<"EOH";
     <ul class="nav nav-tabs">
            <li class="$sels{agence}"><a href="$full_self&sw=list_agences">$sitetxt{im_listingParticuliers_agences}</a></li>
            <li class="$sels{particulier}"><a href="$full_self&sw=list_particuliers">$sitetxt{im_listingParticuliers_particuliers}</a></li>            
            <li class="$sels{notaire}"><a href="$full_self&sw=list_agences&s=notaire">$sitetxt{im_listingParticuliers_notaires}</a></li>
            <li class="$sels{promoteur}"><a href="$full_self&sw=list_agences&s=promoteur">$sitetxt{im_listingParticuliers_promoteurs}</a></li>
            <li class="$sels{expert}"><a href="$full_self&sw=list_agences&s=expert">$sitetxt{im_listingParticuliers_experts}</a></li>
     </ul>
EOH
}

 
 
################################################################################
# contact_form
################################################################################
sub contact_form
{
   see();
   
   my $form = <<"EOH";
      <div>
        <h2 class="clproj_title">$sitetxt{im_contact_CoordonImmo}</h2>
      </div>
      
      <hr/>
      
      <div class="row">
        <div class="col-xs-5">
          <p>$sitetxt{im_contact_rueExemple}</p>
        </div>
        <div class="col-xs-3">
          <p>+32/$sitetxt{im_contact_tel}</p>
        </div>
        <div class="col-xs-4">
          <p>$sitetxt{im_contact_email}</p>  
        </div>
      </div>
      
      <br/>
      
      <div> 
        <h2 class="clproj_title">$sitetxt{im_contact_FormContact}</h2>
        <hr/>
        <p>$sitetxt{im_contact_nEsitez} </p>
        <p><span>*</span>$sitetxt{im_contact_champObligat} </p>
      </div>  
          
      
      <form action="http://192.168.2.21/MIGC/clproj/cgi-bin/clproj.pl" class="form-horizontal" role="form">
          <input type="hidden" name="sw" value="contact_db" />
          <div class="form-group">
            <label for="inputEmail3" class="col-sm-4 control-label">$sitetxt{im_contact_nom}<span>*</span></label>
            <div class="col-sm-8">
              <input type="text" class="form-control" id="inputEmail3" required name="nom" placeholder="">
            </div>
          </div>
          
          <div class="form-group">
            <label for="inputPassword3" class="col-sm-4 control-label">$sitetxt{im_contact_prenom}<span>*</span></label>
            <div class="col-sm-8">
              <input type="text" class="form-control" id="inputPassword3" name="prenom" placeholder="">
            </div>
          </div>
          
          <div class="form-group">
            <label for="inputEmail3" class="col-sm-4 control-label">$sitetxt{im_contact_AdresEmail} <span>*</span></label>
            <div class="col-sm-8">
              <input type="email" class="form-control" id="inputEmail3" name="email" placeholder="">
            </div>
          </div>
          
          <div class="form-group">
            <label for="inputPassword3" class="col-sm-4 control-label">$sitetxt{im_contact_Telephone} </label>
            <div class="col-sm-8">
              <input type="text" class="form-control" id="inputPassword3" name="telephone" placeholder="">
            </div>
          </div>
          
          <div class="form-group">
            <label for="inputPassword3" class="col-sm-4 control-label">$sitetxt{im_contact_VotreMessage} <span>*</span></label>
            <div class="col-sm-8">
              <textarea type="text" class="form-control" id="inputPassword3" name="message" placeholder=""></textarea>
            </div>
          </div>
                  
          <div class="form-group">
            <div class="col-sm-offset-2 col-sm-10">
              <button class="btn btn-primary" type="submit">$sitetxt{im_contact_Envoyer} </button>
            </div>
          </div>
        </form>


EOH
   display($form);
}

sub contact_ok
{
    see();
    $token = get_quoted('token');
    my %member = sql_line({dbh=>$dbh2,table=>'members',where=>"token='$token'"});  

    my $page =<<"EOH";
       <br /><br />
      <div class="panel panel-success">
  <div class="panel-heading">
    <h3 class="panel-title">Message envoyÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©</h3>
  </div>
  <div class="panel-body">
    Votre message a bien ete envoye, merci !
  </div>
</div>
EOH
    display($page);
    
}

   
   
sub to_sql_date
{
	my $date = $_[0];	#Date ÃƒÂƒÃ‚ÂƒÃƒÂ‚Ã‚Â  convertir
	my $date_only=$_[1] || "all";
	
	my ($dd,$mm,$yyyy) = split (/\//,$date);	#SÃ©paration de la date
	
	if($date_only eq 'date_only')
	{
      $date = "$yyyy-$mm-$dd";	#Reformattage de la date
  }
  else
  {
      $date = "$yyyy-$mm-$dd 00:00:00";	#Reformattage de la date
	}
	return $date;	#Renvoit de la date au bon format
}   

sub make_invoice
{
    #see();
    my $token_facture = $_[0];
                                                                                                                           
    my %facture = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"token='$token_facture'"});     
    my %commande = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"id='$facture{commande_id}'"});
    my %type_bien = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'types_bien',where=>"id='$commande{id_type_bien}'"});     
    my %member = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"id='$commande{id_member}'"});                   
    #print Dumper(@one_facture_docs); die; 
    
    
    my $pdf_file = '../inv/invoice_'.$commande{id}.'.pdf';  
    my @pdf = ();
        
    
    my %newpage = 
    (
          type=>"new_page",
          model=>'../skin/cg_modele_facture.pdf',
          content=>''
    );
    push @pdf,\%newpage;     
     
    my $col1 = 50;
    my $y = 755;  
    my $interligne = 12;
    my $ligne = 1;  
    
    ###################        COORDONNES DE CERTIGREEN         ###############################
    my @info_certigreen = (
        'CERTIGREEN – SPRL FABIEN DEVILLERS',
        "Rue de la Vecquée, 170",
        '4100 Seraing',
        'Belgique',
        'TVA : BE0451.912.904',
        'Tel.: +32 (0)4 388 12 94',  
        'info@certigreen.be',
        'www.certigreen.be',
    );
                                                
    foreach $elt (@info_certigreen)
    {
         my @coordonnees1 = 
         (
            {
               type=>"data",
               value=>"$elt",
               font_size=>"8",
               x=>$col1,
               y=>$y - $ligne++ * $interligne,
               font_color=>"#023b06",
            }
         );
         push @pdf,@coordonnees1;
    }     
    
    
    ###################        FACTURE : reference et date         ###############################    
    my @info_facture = (
        "Référence: ".$facture{numero},
        "Date: ".$facture{date_facturation},
    );
    
    my @titre_facture = 
    (
       {
          type=>"data",
          value=>"Facture",
          font_size=>"20",
          x=>$col1*7,
          y=>800,
          font_color=>"#023b06",    
          text_align=>0,
       }
    );
    push @pdf,@titre_facture;
   
    $ligne = 1;
    $interligne = 14;
    foreach $elt (@info_facture)
    {
         my @coordonnees = 
         (
            {
               type=>"data",
               value=>"$elt",
               font_size=>"10",
               x=>$col1*7,
               y=>790 - $ligne++ * $interligne,
               font_color=>"#023b06",
               text_align=>0,
            }
         );
         push @pdf,@coordonnees;
    }
    
    ###################        COORDONNES DU CLIENT         ###############################
    my @info_client = ();
    
	#REPRENDRE INFOS TABLE FACTURES
	
    #client de l'agence   et  facture à l'agence
    # if (($member{id_agence} != 0) && ($commande{envoie_facture} == 0))   
    # {     
        # my %agence =  sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"id='$member{id_agence}'"}); 
        
        # @info_client = (
            # $agence{lastname}." ".$agence{firstname},
            # $agence{street}." ".$agence{number}.",",
            # $agence{zip}." ".$agence{city},
        # );
        
    # }                       
    # client de l'agence   et  facture au client     OU  client particulier
    # elsif((($member{id_agence} != 0) && ($commande{envoie_facture} == 1)) || ())      
    # {       
        # @info_client = (
            # $member{lastname}." ".$member{firstname},
            # $member{street}." ".$member{number}.",",
            # $member{zip}." ".$member{city},
        # );      
    # }
	@info_client = (
            $facture{societe_f},
			$facture{tva_f},
			$facture{nom_f},
            $facture{adresse_f},
            $facture{ville_f}
        );            

			
    $ligne = 1;
    $y = 715;
    $interligne = 18;
    foreach $elt (@info_client)
    {
         if($elt ne '')
		 {
			 my @coordonnees2 = 
			 (
				{
				   type=>"data",
				   value=>"$elt",
				   font_size=>"12",
				   x=>$col1*7,
				   y=>$y - $ligne++ * $interligne,
				   font_color=>"#023b06",
				   text_align=>0,
				}
			 );
			 push @pdf,@coordonnees2;
		 }
    }
    
    ##############        TYPE DU BIEN         #################
    # my $bien = $type_bien{type_1};
    # my $adresse_bien = $commande{adresse_rue}." ".$commande{adresse_numero}.", ".$commande{adresse_cp}.", ".$commande{adresse_ville};
    
    # my @titles = (
          # "Type du bien: ",
          # "Adresse du bien: ",
    # );          
    # $ligne = 1;
    # $y = 600;
    # $interligne = 14;
    # foreach $elt (@titles)
    # {
         # my @coordonnees2 = 
         # (
            # {
               # type=>"data",
               # value=>"$elt",
               # font_size=>"10",
               # x=>$col1,
               # y=>$y - $ligne++ * $interligne,
               # font_color=>"#023b06",
               # text_align=>0,
               # font_weight=>'bold',
            # }
         # );
         # push @pdf,@coordonnees2;
    # }
    
    #########################         ADRESSE DU BIEN          ########################################
    # my @info_client = (
            # $bien,
            # $adresse_bien,
        # ); 
    # $ligne = 1;
    # $y = 600;
    # foreach $elt (@info_client)
    # {
         # my @coordonnees2 = 
         # (
            # {
               # type=>"data",
               # value=>"$elt",
               # font_size=>"10",
               # x=>$col1*3+3,
               # y=>$y - $ligne++ * $interligne,
               # font_color=>"#023b06",
               # text_align=>0,
            # }
         # );
         # push @pdf,@coordonnees2;
    # }
    
    #####################        LINES       ######################
     $y = 520;
     $x = 50;
     my @lines = 
     (
        {
           type=>"grossline",
           x1=>$x,
           y1=>$y,
           x2=>$x+500,
           y2=>$y,
           font_color=>"#b8d1ba",
           weight=>30,
        }
        ,
        {
           type=>"grossline",
           x1=>$x,
           y1=>$y+15,
           x2=>$x,
           y2=>$y-230,
           font_color=>"#b8d1ba",  
           weight=>1,
        }      
        ,
        {
           type=>"grossline",
           x1=>$x+340,
           y1=>$y+15,
           x2=>$x+340,
           y2=>$y-200,
           font_color=>"#b8d1ba",  
           weight=>1,
        }      
        ,
        {
           type=>"grossline",
           x1=>$x+340,
           y1=>$y+15,
           x2=>$x+340,
           y2=>$y-15,
           font_color=>"#ffffff",  
           weight=>1,
        } 
        ,
        {
           type=>"grossline",
           x1=>$x+420,
           y1=>$y+15,
           x2=>$x+420,
           y2=>$y-230,
           font_color=>"#b8d1ba",  
           weight=>1,
        }     
        ,
        {
           type=>"grossline",
           x1=>$x+420,
           y1=>$y+15,
           x2=>$x+420,
           y2=>$y-15,
           font_color=>"#ffffff",  
           weight=>1,
        }   
        ,
        {
           type=>"grossline",
           x1=>$x+500,
           y1=>$y+15,
           x2=>$x+500,
           y2=>$y-230,
           font_color=>"#b8d1ba",  
           weight=>1,
        }             
        ,
        {
           type=>"grossline",
           x1=>$x,
           y1=>$y-170,
           x2=>$x+500,
           y2=>$y-170,
           font_color=>"#b8d1ba",  
           weight=>1,
        }
        ,
        {
           type=>"grossline",
           x1=>$x,
           y1=>$y-200,
           x2=>$x+500,
           y2=>$y-200,
           font_color=>"#b8d1ba",  
           weight=>1,
        }   
        ,
        {
           type=>"grossline",
           x1=>$x,
           y1=>$y-230,
           x2=>$x+500,
           y2=>$y-230,
           font_color=>"#b8d1ba",  
           weight=>1,
        }
        
    );
    push @pdf,@lines;      
    
    #####################        TITLES       ######################
     $y = 516;
     $x = 60;
     my @titles = 
     (
        {
            type=>"data",
            value=>"Type d'expertise",
            font_size=>"10",
            x=>$x+120,
            y=>$y,
            font_color=>"#000000",
            text_align=>0,       
            font_weight=>'bold',
         }  
         ,
         {
            type=>"data",
            value=>"HTVA",
            font_size=>"10",
            x=>$x+360,
            y=>$y,
            font_color=>"#000000",
            text_align=>0,       
            font_weight=>'bold',
         } 
         ,
         {
            type=>"data",
            value=>"TVA",
            font_size=>"10",
            x=>$x+440,
            y=>$y,
            font_color=>"#000000",
            text_align=>0,       
            font_weight=>'bold',
         }
     ); 
     push @pdf,@titles;
     
     #####################       EXPERTISES      ######################   
     # my @documents = sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',where=>"id_facture='$facture{id}'"});
     # my @docs = (); 
     # my @htva = ();
     # my @tva = ();
     # my $total_htva = 0;
     # my $total_tva = 0;
     # my $total_tvac = 0;
     # if ($#documents != -1)
     # {
          # foreach $doc (@documents)
          # {
               # my %one_doc = %{$doc};
               # my %type_doc = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'types_document',where=>"id='$one_doc{type_document_id}'"}); 
               # push @docs,$type_doc{type_1};   
               # push @htva,$one_doc{prix};      
               # my $one_tva = $one_doc{prix}*0.21; 
               # push @tva,$one_tva;    
               # $total_htva += $one_doc{prix};
               # $total_tva += $one_tva;        
          # }
          # $total_tvac = $total_htva + $total_tva;
     # }
	 
	 my @facture_details = sql_lines({dbh=>$dbh2,table=>'facture_details',where=>"id_facture='$facture{id}'",ordby=>'ordby'});
     
     $ligne = 1;
     $y = 500;
     $interligne = 18;
     foreach $fd (@facture_details)
     {
		my %fd = %{$fd};
        if($fd{label} ne '')
		{
		my @coord = 
           (
              {
                 type=>"data",
                 value=>"$fd{label}",
                 font_size=>"10",
                 x=>$x,
                 y=>$y - $ligne++ * $interligne,
                 font_color=>"#000000",
                 text_align=>0,
              }
         );
		 push @pdf,@coord;
		 }
         
     }
     
     ########################         HTVA         #############################
     $ligne = 1;
     foreach $fd (@facture_details)
     {
		my %fd = %{$fd};
 if($fd{label} ne '')
		{       
	   my @coord = 
           (
              {
                 type=>"data",
                 value=>"$fd{total_htva} €",
                 font_size=>"10",
                 x=>$x+400,
                 y=>$y - $ligne++ * $interligne,
                 font_color=>"#000000",
                 text_align=>2,
              }
         );
		 push @pdf,@coord;
		 }
         
     }
     
     ########################         TVA         #############################
     $ligne = 1;
     foreach $fd (@facture_details)
     {
		my %fd = %{$fd};
         if($fd{label} ne '')
		{
		my @coord = 
           (
              {
                 type=>"data",
                 value=>$fd{total_tvac} - $fd{total_htva} ." €",
                 font_size=>"10",
                 x=>$x+480,
                 y=>$y - $ligne++ * $interligne,
                 font_color=>"#000000",
                 text_align=>2,
              }
         );
		 push @pdf,@coord;
		 }
         
     }
     
     ###########################         TOTAUX, MONTANT A PAYER          ##################################
     $y = 332;
     my @total_details = 
    (
        {
           type=>"data",
           value=>"TOTAUX: ",
           font_size=>"10",
           x=>$x,
           y=>$y,
           font_color=>"#000000",   
           font_weight=>'bold',
           text_align=>0,
        }
        ,
        {
           type=>"data",
           value=>"$facture{total_htva} €",
           font_size=>"10",
           x=>$x+400,
           y=>$y,
           font_color=>"#000000",   
           font_weight=>'bold',
           text_align=>2,
        }    
        ,
        {
           type=>"data",
           value=>"$facture{total_tva} €",
           font_size=>"10",
           x=>$x+480,
           y=>$y,
           font_color=>"#000000",   
           font_weight=>'bold',
           text_align=>2,
        }   
        ,
        {
           type=>"data",
           value=>"Montant à payer TTC au plus tard le $facture{date_echeance}",
           font_size=>"10",
           x=>$x,
           y=>$y-30,
           font_color=>"#000000",   
           font_weight=>'bold',
           text_align=>0,
        }   
        ,
        {
           type=>"data",
           value=>"$facture{total_tvac} €",
           font_size=>"10",
           x=>$x+480,
           y=>$y-30,
           font_color=>"#000000",   
           font_weight=>'bold',
           text_align=>2,
        }
     );
     push @pdf,@total_details;
     
     ############################        INSTRUCTION       ################################
     $y = 250;
     $x = 50;
     my @instruction = 
    (
        {
           type=>"data",
           value=>"Instructions de paiement",
           font_size=>"10",
           x=>$x,
           y=>$y,
           font_color=>"#000000",   
           font_weight=>'bold',
           text_align=>0,
        }
        ,
        {
           type=>"data",
           value=> $facture{remarque_f},
           font_size=>"10",
           x=>$x,
           y=>$y-20,
           font_color=>"#000000",   
           font_weight=>'normal',
           text_align=>0,
        }     
     );
     push @pdf,@instruction;
     
     ############################        COORDONNEES BANQUAIRES       ################################
     my @banquaires = 
     (
        {
           type=>"data",
           value=>"Banque :",
           font_size=>"10",
           x=>$x,
           y=>$y-40-14,
           font_color=>"#000000",   
           font_weight=>'bold',
           text_align=>0,
        }
        ,
        {
           type=>"data",
           value=>"ING: 363-0294498-46",
           font_size=>"10",
           x=>$x+47,
           y=>$y-40-14,
           font_color=>"#000000",   
           font_weight=>'normal',
           text_align=>0,
        }
        ,
        {
           type=>"data",
           value=>"IBAN :",
           font_size=>"10",
           x=>$x,
           y=>$y-40-14*2,
           font_color=>"#000000",   
           font_weight=>'bold',
           text_align=>0,
        }
        ,
        {
           type=>"data",
           value=>"BE33 3630 2944 9846",
           font_size=>"10",
           x=>$x+35,
           y=>$y-40-14*2,
           font_color=>"#000000",   
           font_weight=>'normal',
           text_align=>0,
        }    
        ,
        {
           type=>"data",
           value=>"BIC :",
           font_size=>"10",
           x=>$x,
           y=>$y-40-14*3,
           font_color=>"#000000",   
           font_weight=>'bold',
           text_align=>0,
        }
        ,
        {
           type=>"data",
           value=>"BBRUBEBB",
           font_size=>"10",
           x=>$x+30,
           y=>$y-40-14*3,
           font_color=>"#000000",   
           font_weight=>'normal',
           text_align=>0,
        } 
        ,
        {
           type=>"data",
           value=>"Communication :",
           font_size=>"10",
           x=>$x,
           y=>$y-40-14*4,
           font_color=>"#000000",   
           font_weight=>'bold',
           text_align=>0,
        }
        ,
        {
           type=>"data",
           value=>"Certigreen commande $commande{id}",
           font_size=>"10",
           x=>$x+86,
           y=>$y-40-14*4,
           font_color=>"#000000",   
           font_weight=>'normal',
           text_align=>0,
        }
        
     );  
     push @pdf,@banquaires;
     
         
    eshop::create_pdf_pages($pdf_file,\@pdf,'Arial',10);
    return $pdf_file;
#     print $pdf_file;
}

sub get_facture
{
    my $token = get_quoted('token');
    my $file =  make_invoice($token);
  
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

sub get_document
{
    my $token = get_quoted('token');
    my $id_document = get_quoted('id_document');
#     see(); print $id_document; exit;

    my %doc = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'commande_documents',where=>"id='$id_document'"}); 
     use File::MimeInfo;
     $file = $config{root_path}.'/usr/'.$doc{url}; 
     my $mime_type = mimetype($file);
    print $cgi->header(-attachment=>$doc{url},-type=>$mime_type);
    open (FILE,$file);
    binmode FILE;
    binmode STDOUT;
    while (read(FILE,$buff,2096)){
        print STDOUT $buff;
    }
    close (FILE);
  
    exit;
}

sub get_facture_links
{
	my $id = $_[0];
	my $list_factures = '';
	my %commande = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"id='$id'"});
	my @factures = sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"table_record='intranet_factures' AND id_record = '$id'"});
	foreach $facture (@factures)
	{
		my %facture = %{$facture};
		$list_factures .= get_facture_link($id,\%facture);
		
	}
	# if($#factures == -1 && $commande{alt_facture_url} ne '')
	# {
		# $list_factures = '<a href ="usr/documents/'.$commande{alt_facture_url}.'" target="_blank"><i style="font-size:40px;" class="fa fa-file-text-o"></i></a>';
	# }
	$list_factures = '<div style="text-align:center;">'.$list_factures.'</div>';
	return $list_factures;
		
}

sub get_facture_link
{
	my $id = $_[0];
	my %facture = %{$_[1]};
	
	# my %facture = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"table_record='intranet_factures' AND id_record = '$id'"});
	my %commande = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'intranet_factures',where=>"id='$id'"});
	
	my $exist_facture = "";
	my $link = '';
	my $download_link = '';
	
	
	
	my $statut = "";
	my $txtstatus = '';
	my $text = "<span style=''><i class='fa fa-file-text-o' style='font-size:28px; '></i></span>";
	if($facture{id} > 0)
	{
		if($facture{statut} == 4)
		{
		  $txtstatus = 'Payée';
		  $statut =<<"EOH";
			<span style="color:green!important; text-align: center;">$text</span>
EOH
		}
		elsif($facture{statut} == 5)
		{
			$txtstatus = 'Remboursée';
			$statut=<<"EOH";
				<span style="color:black!important; text-align: center;">$text</span>
EOH
		}
		elsif($facture{statut} == 3)
		{
			$txtstatus = 'Paiement partiel';
			$statut=<<"EOH";
				<span style="color:orange!important; text-align: center;">$text</span>
EOH
		}
		else
		{
			$txtstatus = 'Non payée';
			$statut=<<"EOH";
				<span style="color:red!important; text-align: center;">$text</span>
EOH
		}
	}
		# see(\%commande);
	# if($commande{alt_facture_url} ne '')
	# {
		# $exist_facture = 'Facture ext';
	
		# $download_link = '<a href ="http://certigreen.fw.be/usr/'.$commande{alt_facture_url}.'" target="_blank"><i style="font-size:20px;" class="fa fa-download"></i></a>';
		
	# }
	# els
	if($facture{id} > 0)
	{
		$exist_facture = 'Facture N°'.$facture{numero}.': '.$txtstatus;
		$download_link = '<a data-toggle="tooltip" data-placement="right" title="'.$exist_facture.'" href ="../usr/documents/'.$facture{migcms_last_published_file}.'" target="_blank">'.$statut.'</a>';
	}
	else
	{
		$exist_facture = '';
	}

	# my $link_to_facture = <<"EOH";
		# <a data-toggle="tooltip" data-placement="right" title="$exist_facture" class="mig_lnk" href="$htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/adm_handmade_factures.pl?$link&commande_id=$id">
			
		# </a>
# EOH

	# if($commande{alt_facture_url} ne '')
	# {
		# $link_to_facture = <<"EOH";
		
# EOH
	# }
	
	my $commande_facture =<< "EOH";
			
			$download_link
				
EOH
	return $commande_facture;
}


################################################################################
# lost_password
################################################################################
sub lost_password_form
{
    #FORMULAIRE envoyant un lien de reset mdp par email.
	#identique visiteur et exposant (le type change dans champs caché)
		
	my $page =<<"EOH";
	
		<section class="parag_content parag_form">
        <div class="row">
			<div class="col-md-8 col-sm-8 col-xs-12 col-md-offset-2 col-sm-offset-2 members_form"> 
              <h1 class="text-center">Mot de passe perdu</h1> 
			  <div class="parag_text_content text-center">Entrez votre adresse email et nous vous enverrons un lien pour changer votre mot de passe.</div>
              <form method="post" id="loginform"  action="$full_self" class="form-horizontal" role="form">
              		<input type="hidden" name="sw" value = "lost_password_db" />
					<input type="hidden" name="lg" value = "$lg" />
					<input type="hidden" name="t" value = "$type" />
					
					<div class="form-group">
						<label class="col-sm-4 control-label" for="inputEmail">Email <span>*</span></label>
						<div class="col-sm-8">
							<input type="text" name="email" required id="inputEmail" placeholder="" class="required form-control" />
						</div>
					</div>
		
					<div class="form-group text-right">
						<div class="col-md-12">
							<button type="submit" class="btn-custom3 add_expertise">Récupérer mon mot de passe</button>
						</div>
            		 </div>
            	</form>                          
          </div>
		</div>
		</section>

EOH
	
	
    see();
    display($page);
}

#*******************************************************************************
#LOST PASSWORD DB
#*******************************************************************************
sub lost_password_db
{
    #renvoit un email avec lien de modification mdp à partir du token. Table différente selon exposant, visiteur
	
	my $email = get_quoted('email');
    $email = trim($email);

	my %acces = sql_line({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members',where=>"UPPER(email) = UPPER('$email')"});

    if($acces{id} > 0 && $acces{email} ne '')
    {
		my $link = "$full_self&sw=edit_password&token=$acces{token}";
			
		my $object = 'Récupération de votre mot de passe Certigreen';
		my $body = <<"EOH";
			Bonjour,
			<br />
			<br />
			Une demande de changement de mot de passe a été soumise sur votre espace Certigreen.
			<br />
			Si vous n’êtes pas à l’origine de cette demande, vous pouvez simplement ignorer cet email.
			<br />
			Si vous souhaitez changer votre mot de passe, cliquez sur le lien ci-dessous :
			<br /><a href="$link">$link</a>
			<br /><br />
			Cordialement,
			<br />
			L’équipe Certigreen
EOH
			

			send_mail('info@certigreen.be',$acces{email},$object,$body,"html");
          
          cgi_redirect("$full_self&sw=lost_password_ok");
    }
    else
    {
          cgi_redirect("$full_self&sw=lost_password_ko");
    }
}

################################################################################
# lost_password_ok
################################################################################
sub lost_password_ok
{
    my $page =<<"EOH";
<div class="panel panel-warning">
	<div class="panel-heading">
		<h3 class="panel-title">Mot de passe perdu</h3>
	</div>
	<div class="panel-body">
		Nous vous avons envoyé un email vous permettant de changer votre mot de passe.
	</div>
</div>	
EOH
    see();
    display($page);
}

################################################################################
# lost_password_ko
################################################################################
sub lost_password_ko
{
    my $page =<<"EOH";
<div class="panel panel-warning">
	<div class="panel-heading">
		<h3 class="panel-title">Adresse email erronée</h3>
	</div>
	<div class="panel-body">
		L'adresse email n'a pas été trouvée dans notre base de données.<br />
		<a class="btn btn-info" href="$full_self&sw=lost_password_form">Réessayer</a>
	</div>
</div>	
EOH
    see();
    display($page);
}

################################################################################
# edit_password
################################################################################
sub edit_password
{
    my $token = get_quoted('token');
	my $table = 'members';
	
    my %member = select_table($dbh2,$table,"","token='$token'",'','',0);

    if($member{id} eq "")
    {
        see();
		http_redirect("$full_self&sw=connexion&ret=espace_perso");
        exit;
    }
    
   my $error_msg = '';
   my $error = get_quoted('error');
   if($error == 1)
   {
        $error_msg = <<"EOH";
                  <div class="alert alert-block alert-error alert-danger">
                    <h4 class="alert-heading">Erreur de mots de passe</h4>
                    <p>Les mots de passes ne correspondent pas ou ne sont pas valides, réessayez svp.</p>
                  </div>
EOH
   } 
   
   my $page = <<"EOH";
	  <div id="eshop_alert">$error_msg</div>
      <div id="eshop" class="clearfix">
            <div class="lostpassword-form">
				<h1>Modifier votre mot de passe</h1>
				<form class="form-horizontal" method="post" id="edit_password_form" action="$full_self">
				<input type="hidden" name="sw" value = "edit_password_db" />
				<input type="hidden" name="lg" value = "$lg" />
				<input type="hidden" name="t" value = "$type" />
				<input type="hidden" name="token" value = "$member{token}" />
				
				  <div class="form-group">
						<label class="control-label col-sm-4">Nouveau mot de passe</label>
						<div class="col-sm-8">
							<input type="password" name="new_password" required class="required form-control" />
						</div>
					</div>
					<div class="form-group">
						<label class="control-label col-sm-4">Retapez le mot de passe</label>
						<div class="col-sm-8">
							<input type="password" name="new_password2" required class="required form-control" />
						</div>
					</div>
					<div class="form-group">
						<div class="col-sm-4"></div>
						<div class="col-sm-8">
							<button type="submit" class="btn btn-default">Sauvegarder le mot de passe</button>
						</div>
					</div>
				</form>
            </div>
      </div>
EOH
   

 
    see();
    display($page);
}
################################################################################
# edit_password_db
################################################################################
sub edit_password_db
{

    my $token = get_quoted('token');
    my $table = 'members';
    my %member = select_table($dbh2,$table,"","token='$token'",'','',0);
    if($member{id} eq "")
    {
     make_error("Bad token !");
    }

    if($member{id} > 0)
    {
#         my $old_password = get_quoted('old_password');
        my $password = get_quoted('new_password');
		my $sha1_password = sha1_hex($password);
        my $verif_password = get_quoted('new_password2');
        
        if($password ne '' && $password eq $verif_password)
        {        
            $stmt = "UPDATE $table SET password='$sha1_password' where id=$member{id}";
            execstmt($dbh2,$stmt);

            cgi_redirect("$full_self&sw=edit_password_ok");
        }
        else
        {
            cgi_redirect("$full_self&sw=edit_password&token=$token&error=1");
        }
    }
    else
    {
         cgi_redirect("$full_self&sw=edit_password_ko");

    }

    
}

################################################################################
# edit_password_ok
################################################################################
sub edit_password_ok
{
    my $page =<<"EOH";
<br />
<div class="panel panel-success">
	<div class="panel-heading">
		<h3 class="panel-title">Mot de passe modifié</h3>
	</div>
	<div class="panel-body">
		Votre mot de passe a été modifié avec succès, vous pouvez vous connecter en utilisant vos nouveaux accès.
	</div>
</div>
	
EOH
    see();
    display($page,'',$setup{id_tpl_page2});
}

################################################################################
# edit_password_ok
################################################################################
sub edit_infos_ok
{
    my $page =<<"EOH";	
<br />	
<div class="panel panel-success">
	<div class="panel-heading">
		<h3 class="panel-title">Infos modifiées</h3>
	</div>
	<div class="panel-body">
		Vos informations ont été modifiées avec succès.
		<br /><br />
		<a class="btn-custom3" title="" data-original-title="" href="/cgi-bin/certigreen.pl?lg=1&amp;extlink=1&amp;sw=espace_perso">Mon espace Certigreen</a>
	</div>
</div>
	
EOH
    see();
    display($page,'',$setup{id_tpl_page2});
}

################################################################################
# edit_password_ko
################################################################################
sub edit_password_ko
{
    my $page =<<"EOH";			

	
EOH
    see();
    display($page);
}


sub reset_all
{
	see();
	exit;
	# commandes

	my @tables = qw(
	intranet_documents
	intranet_documents_bas
	intranet_documents_frais
	intranet_documents_lignes
	intranet_factures
	intranet_factures_bas
	intranet_facture_lignes
	intranet_nc
	intranet_nc_bas
	intranet_nc_lignes
	commande_documents
	);
	
	foreach my $table (@tables)
	{
		my $stmt = 'DELETE FROM `migcms_linked_files` where table_name = "$table"';
		execstmt($dbh,$stmt);
		
		$stmt = "TRUNCATE `$table`";
		execstmt($dbh,$stmt);
	}
	exit;
}