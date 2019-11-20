#!/usr/bin/perl -I../lib 
# -d:NYTProf

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use Data::Dumper;
use JSON::XS;
use sitetxt;
use members;
use Encode;
use URI::Escape;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use eshop;

# use Devel::NYTProf;

$lg =~ s/undefined//g;
$config{current_language} = $config{default_colg} = $lg;
my $htaccess_protocol_rewrite = "http";
if($config{rewrite_ssl} eq 'y') 
{
  $htaccess_protocol_rewrite = "https";
}

my $payplug_data_json;
# RECUPERATION ID ORDER
my $id_order;

see();
log_debug("Retour Payment");

# Paypal
$id_order = get_quoted('invoice');
log_debug("ID_ORDER : ". $id_order);


  if($id_order eq "")
  {
    # Payplug
    $payplug_data_json = get_quoted("POSTDATA");
    log_debug("Payplug json : ". $payplug_data_json);

    if($payplug_data_json ne "")
    {

      $payplug_data = decode_json($payplug_data_json);
      %payplug_data = %{$payplug_data};


      $id_order = $payplug_data{order};
      log_debug("ID_ORDER : ". $id_order);


    } 
  }


# Si on a récupéré un ID
if($id_order > 0)
{
  my %eshop_order = sql_line({table=>"eshop_orders",where=>"id='$id_order'"});
  if($eshop_order{id} > 0)
  { 
    my $postsale_code;
    log_debug("Payment : ". $eshop_order{payment});
    #PAYMENT**********************************************************
    if($eshop_order{payment} eq 'payplug')
    {
      $postsale_code = postsale_billing_payplug({dbh=>$dbh, order=>\%eshop_order, payplug_data_json=>$payplug_data_json, headers=>\%ENV});
      log_debug("Postsale_code : " . $postsale_code);                         
    }
    elsif($payment_type eq 'paypal')
    {
      $postsale_code = postsale_billing_paypal({dbh=>$dbh, order=>\%eshop_order});
    }

    #TRAITEMENTS APRES RETOUR**********************************************************
    
    # Paiement accepté
    if($postsale_code == 1)
    {
      eval
      {
        change_status({status=>'new',payment_status=>"paid",order=>\%eshop_order});
        log_debug("change_status");
        my %setup = %{eshop::get_setup()};
        if($setup{generate_bill_number_if_paid} eq "y")
        {
          # Génération d'un numéro séquentiel de facture
          my $invoice_num = eshop::generate_sequential_num_db({id=>$eshop_order{id}, table=>"eshop_orders", col=>"invoice_num"});
          %eshop_order = sql_line({table=>"eshop_orders", where=>"id = '$eshop_order{id}'"});
        }      
        # Envoi du mail de confirmation
        eshop_mailing_confirmation(\%eshop_order);
        log_debug("eshop_mailing_confirmation");

        # Envoi de la facture pro forma
        eshop_mailing_facture(\%eshop_order);
        log_debug("eshop_mailing_facture");

        # Envoi de la facture PDF
        eshop_mailing_facture_pdf(\%eshop_order);
        log_debug("eshop_mailing_facture_pdf");
        
        # Mise à jour du stock
        update_stock({order=>\%eshop_order,payment_status=>"paid"});
        log_debug("update_stock");
        
        # Fonction d'après commande
        exec_post_order({order=>\%eshop_order,payment_status=>"paid"});
        log_debug("exec_post_order");
      }
      or do
      {
        my $e = $@;
        log_debug("Error captured : $e\n");
      }
    }
    # Paiement refusé
    elsif($postsale_code == 2)
    {
      change_status({status=>'finished',delivery_status=>'cancelled',payment_status=>"repaid",order=>\%eshop_order});
    }  
    # Paiement en attente 
    else 
    {
      change_status({payment_status=>"wait_payment",order=>\%eshop_order});
    }
  }
} 

################################################################################
# postsale_billing_payplug
################################################################################  
sub postsale_billing_payplug
{
  use MIME::Base64;

  my %d = %{$_[0]};

  my $dbh               = $d{dbh};
  my %eshop_order       = %{$d{order}};
  my $payplug_data_json = $d{payplug_data_json};
  my %headers           = %{$d{headers}};

  my $payplug_data = decode_json($payplug_data_json);
  my %payplug_data = %{$payplug_data};

  my $postsale_code = 0;

  eval
  {
    use Crypt::OpenSSL::RSA;
    my $signature = decode_base64($headers{'HTTP_PAYPLUG_SIGNATURE'});

    my %setup = %{get_setup()};

    my $public_key = Crypt::OpenSSL::RSA->new_public_key($setup{payplug_public_key});

    $public_key->use_sha1_hash();


    if($public_key->verify($payplug_data_json, $signature))
    {
      # La signature est valide 
      if($payplug_data{'state'} eq 'paid')
      {
        $postsale_code = 1;
      } 
      elsif($payplug_data{'state'} eq 'refunded')
      {
        $postsale_code = 2;
      } 

    }

    return $postsale_code;
  }
  or do
  {
    # my $e = $@;
    # log_debug("Error captured : $e\n");
  }

  

}

################################################################################
# postsale_billing_paypal
################################################################################
sub postsale_billing_paypal
{
  my %d = %{$_[0]};

   my $dbh = $_[0];
   my %order = %{$_[1]};
   my %method = %{$_[2]};
   my %method_cfg = %{$_[3]};
   my $lg = $_[4];
   my $extlink = $_[5];
   my $prefixe = $_[6];
   
   my %paypal = select_table($dbh,"eshop_payments","","name='paypal'");
   my %params = eval("%params = ($paypal{params});");

   my $postsale_code = 0;
   
  
#  my $query = '';       
  #read post from PayPal system and add 'cmd'
# read (STDIN, $query, $ENV{'CONTENT_LENGTH'});

  my %cgi_params = $cgi->Vars;
  foreach my $k (keys %cgi_params) {
      $query .= $k."=".$cgi_params{$k}."&";
  }

   $query .= 'cmd=_notify-validate';

   # post back to PayPal system to validate
   my $ua = new LWP::UserAgent;
   my $req = new HTTP::Request 'POST','https://www.paypal.com/cgi-bin/webscr';
   $req->content_type('application/x-www-form-urlencoded');
   $req->content($query);
   my $res = $ua->request($req);

  # split posted variables into pairs
  @pairs = split(/&/, $query);
  $count = 0;

  foreach $pair (@pairs) 
  {
    ($name, $value) = split(/=/, $pair);
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
    $variable{$name} = $value;
    $count++;
  }

  my %paypal=%variable;

  if ($res->is_error) 
  {
      # eshop_log({id_order=>$order{id},txt=>'ERREUR INTERNE PAYPAL : '.Dumper($res).' HAS : '.Dumper(\%paypal)});
      exit;   
  }
  elsif ($paypal{'payment_status'} eq 'Completed' || $paypal{'payment_status'} eq 'Refunded') 
  {
    if(uc($paypal{'receiver_email'}) eq uc($params{paypal_id}))
    {  
      # PAIEMENT ACCEPTE
      if($paypal{'payment_status'} eq 'Completed')
      {
        $postsale_code = 1;

      } 
      # PAIEMENT REFUSE
      elsif($paypal{'payment_status'} eq 'Refunded')
      {
        $postsale_code = 2;

      } 
      # PAIEMENT EN ATTENTE
      else 
      {
        $postsale_code = 3;
      }

    }
    else
    {
       # eshop_log({id_order=>$order{id},txt=>'Email du receveur != Email Paypal Bugi :'.uc($paypal{'receiver_email'}).' != '.uc($params{paypal_id})});
    }
  }
  elsif ($paypal{'payment_status'} eq 'Invalid') {
       # eshop_log({id_order=>$order{id},txt=>'payment status = invalid '});

  }
  else 
  {
       # eshop_log({id_order=>$order{id},txt=>'Payment status unknown : '.$paypal{'payment_status'}});

  }

  return $postsale_code;

}