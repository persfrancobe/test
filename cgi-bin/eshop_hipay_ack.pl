#!/usr/bin/perl -I../lib 

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use migcrender;
use Data::Dumper;
use eshop;

$cgi = new CGI;
$sw = get_quoted('sw') || "ack";
my $extlink = get_quoted('extlink');
$config{current_language} = get_quoted('lg') || 1;
my $self = "../cgi-bin/hipay_eshop_ack.pl?";

my @fcts = qw(
    ack
    );
    
if (is_in(@fcts,$sw)) 
{ 
    &$sw();
}

sub ack
{
  see();
  my $xml =$cgi->param('xml') || '';
  my %cfg = get_hash_from_config($dbh,"data_shop_cfg");
  use XML::Simple;
  use Data::Dumper;
 
  my $ref = XMLin($xml);
  my %data=%{$ref};
  my $status=$data{mapi}{result}{status};
  my $id_order=$data{result}{idForMerchant};
  $id_order =~ s/\D//g;
  eshop_log({id_order=>$id_order,txt=>"HIPAY: Retour XML hipay ($id_order)",data=>$xml});
  
  my %order=select_table($dbh,"eshop_orders","","id='$id_order'",'','',0);
  eshop_log({id_order=>$order{id},txt=>"HIPAY: Commande lue ($id_order)",data=>Dumper(\%order)});
  
  eshop_log({id_order=>$order{id},txt=>"HIPAY: Données XML décodées",data=>Dumper(\%data)});
    
  my $hipay_amount=$data{result}{origAmount};
  my $order_amount=$order{total_discounted_tvac};
   
  $order_amount=sprintf("%.0f", $order_amount);
  $hipay_amount=sprintf("%.0f", $hipay_amount);
  
  eshop_log({id_order=>$order{id},txt=>"Opération: $data{result}{operation}"});
  eshop_log({id_order=>$order{id},txt=>"HIPAY: Montant: $hipay_amount"});
  eshop_log({id_order=>$order{id},txt=>"Statut: $data{result}{status}"});
  eshop_log({id_order=>$order{id},txt=>"PM: $data{result}{paymentMethod}"});
  
  my $continue = 0;
  if($data{result}{status} eq 'ok')
  {
       my $payment_status = '';
       if($data{result}{operation} eq 'authorization')
       {
          $payment_status = 'wait_payment';
          $continue = 0;
       }
       elsif($data{result}{operation} eq 'capture')
       {
          $payment_status = 'captured';
          $continue = 1;
       }
       elsif($data{result}{operation} eq 'refund')
       {
          $payment_status = 'repaid';
          $continue = 0;
       }
       elsif($data{result}{operation} eq 'cancellation')
       {
          $payment_status = 'cancelled';
          $continue = 0;
       }
       elsif($data{result}{operation} eq 'rejet')
       {
          $payment_status = 'cancelled';
          $continue = 0;
       }
       change_status({payment_status=>$payment_status,order=>\%order});
       if($continue)
       {
           change_status({status=>'new',payment_status=>$payment_status,order=>\%order});
           eshop_log({id_order=>$id_order,txt=>"HIPAY: Exécution de la post fonction..."});
           exec_post_order(\%order,'',$payment_status);
                      
           eshop_log({id_order=>$id_order,txt=>"HIPAY: Maj du stock..."});
           update_stock(\%order,'',$payment_status);
           
           eshop_log({id_order=>$id_order,txt=>"HIPAY: Envoi de l'email de confirmation...($payment_status)"});
           send_email_confirmation(\%order,'',$payment_status);
        }
        else
        {
           eshop_log({id_order=>$id_order,txt=>"HIPAY: Aucune suite donnée à la commande"});
        }
  }
  else
  {
       eshop_log({id_order=>$id_order,txt=>"HIPAY: Statut n'est pas OK"});
       change_status({payment_status=>'wait_payment',order=>\%order});
  }   
}