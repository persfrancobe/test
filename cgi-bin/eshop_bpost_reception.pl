#!/usr/bin/perl -I../lib 

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use migcrender;
use Data::Dumper;
use members;
use eshop;
use Encode;
use JSON::XS;
use URI::Escape;
use sitetxt;

$cgi = new CGI;
$sw = get_quoted('sw') || "eshop_bpost_reception";
my $extlink = get_quoted('extlink');
$config{current_language} = get_quoted('lg') || 1;


my $lg=get_quoted('lg') || "1";
my $self ='$htaccess_protocol_rewrite://'.$config{rewrite_default_url}."/cgi-bin/eshop_bpost_reception.pl?&amp;lg=$config{current_language}&amp;extlink=$extlink";

my @fcts = qw(
    eshop_bpost_reception
    );
    
if (is_in(@fcts,$sw)) 
{ 
    &$sw();
}

sub eshop_bpost_reception
{
  my %order = %{get_eshop_order()};
  log_debug('bpost','vide','eshop_bpost_callback');
  member_add_event({group=>'eshop',type=>"eshop_bpost_callback",name=>"Début du retour de Bpost",detail=> $order{id}});
  
  # Récupération des données de BPOST
  $order{tier_lastname}  = uri_unescape(get_quoted('customerLastName'));
  $order{tier_firstname} = uri_unescape(get_quoted('customerFirstName'));
  $order{tier_street}    = uri_unescape(get_quoted('customerStreet'));
  $order{tier_number}    = uri_unescape(get_quoted('customerStreetNumber'));
  $order{tier_city}      = uri_unescape(get_quoted('customerCity'));
  $order{tier_zip}       = uri_unescape(get_quoted('customerPostalCode'));
  $order{tier_country}   = get_quoted('customerCountry');
  my %country            =  select_table($dbh,"countries","id,iso","iso ='$order{tier_country}'");
  $order{tier_country}   = $country{id};
  $order{tier_email}     = uri_unescape(get_quoted('customerEmail'));
  $order{tier_phone}      = uri_unescape(get_quoted('customerPhoneNumber'));
  
  #Numero de compte BPACK 24/7
  my $num             = $cgi->param('customerMemberId');
  my $nom_point_poste = $cgi->param('customerPostalLocation');
  my $rc_point_poste  = $cgi->param('customerRcCode');
  my $methode         = $cgi->param('deliveryMethod');
  if($methode eq 'Pugo')  
  {     
      $methode = 'Point Poste'; 
  }
  elsif($methode eq 'Parcels depot')  
  {     
      $methode = 'Distributeur'; 
  }
  else  
  {     
      $methode = 'A domicile ou au travail'; 
  }  
  
  my $remarque = "";
  if($methode ne "") {  $remarque .= "Méthode de livraison: $methode, ";    }
  if($num ne "") {  $remarque .= "numero de compte BPACK 24/7:  $num, ";    }
  if($nom_point_poste ne "") {  $remarque .= "nom du point poste: $nom_point_poste, ";    }
  if($rc_point_poste ne "") {  $remarque .= "REC du point poste: $rc_point_poste, ";    }
  
  if($nom_point_poste ne "")
  {
     $order{tier_company} = $nom_point_poste;
  }
  
  $order{commentaire} = $remarque;     
  $order{total_delivery_tvac} =  $cgi->param('deliveryMethodPriceTotal') /100;
  $order{total_delivery_htva} =  $order{total_delivery_tvac} / 1.21;
  $order{total_delivery_tva} =  $order{total_delivery_tvac} - $order{total_delivery_htva}; 

  # On indique que les frais bpost ont été comptabilisés
  $order{identity_tier} = "y";
  $order{bpost_total_delivery_computed} = "y";

  

  # Mise à jour de l'order
  %order = %{quoteh(\%order)};
  sql_set_data({dbh=>$dbh, table=>"eshop_orders", data=>\%order, where=>"id = $order{id}"});

  member_add_event({group=>'eshop',type=>"eshop_bpost_callback",name=>"Retour Bpost effectué",detail=> $order{id}});

  #recompute order & order_details
  recompute_order();

  # Redirection vers le récap en JS pour sortir de la frame
  see();
  my $url_recap = $config{baseurl}."/".$sitetxt{eshop_url_recap};
  print <<"EOH";
      <script language="Javascript" type="text/javascript">
      parent.location.href = "$url_recap";
      </script>
EOH
  exit;
      
}