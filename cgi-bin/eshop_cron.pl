#!/usr/bin/perl -I../lib 
# -d:NYTProf

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use Crypt::OpenSSL::RSA;
use migcrender;
use Data::Dumper;
use JSON::XS;
use sitetxt;
use members;
use Encode;
use URI::Escape;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);
use eshop;
# use Devel::NYTProf;

my $lg = $ARGV[1] || 1;
$lg =~ s/undefined//g;
$config{current_language} = $config{default_colg} = $lg;
my $sw = $ARGV[0] || 'relances_email';
my $extlink = get_quoted('extlink') || $shop_cfg{extlink};
my $htaccess_protocol_rewrite = "http";
if($config{rewrite_ssl} eq 'y') 
{
  $htaccess_protocol_rewrite = "https";
}
# see();
&$sw();

sub relances_email
{
    see();
    # if($config{eshop_email_relance} eq 'y')
    # {
        # send_email_relance(5);
        # send_email_relance(10);
    # }
	
    eshop_relances_panier();
	eshop_relances_paiement();
} 

sub send_email_relance
{
    my $delai = $_[0] || 5;
    
    my $where = <<"EOH";
            DATE_SUB(DATE(NOW()),INTERVAL $delai DAY) = DATE(order_begin_moment) 
            AND payment = 'virement'
            AND email_sent = 1
            AND email_sent_$delai = 0
            AND payment_status != 'cancelled'
            AND payment_status != 'paid'
            AND payment_status != 'captured'
EOH

    my @eshop_orders = sql_lines({table=>'eshop_orders', where=>$where});
   
    foreach $order (@eshop_orders)
    {
        my %order = %{$order};
        my $txt_email = $sitetxt{relance_virement};
        $txt_email =~ s/NUMCOMMANDE/$order{id}/g;
        my $email_confirmation = get_order_summary(\%order,$lg,$txt_email);
         
        if($order{billing_email} ne '')
        {
            send_mail($setup{email_from},$order{billing_email},"$sitetxt{eshop_relance_object}",$email_confirmation,"html");
            send_mail($setup{email_from},'alexis@bugiweb.com',"COPIE ALEXIS: RELANCE: $sitetxt{eshop_relance_object}",$email_confirmation,"html");
            $stmt = "UPDATE eshop_orders SET email_sent_$delai = 1 WHERE id = '$order{id}'";
            execstmt($dbh,$stmt);
        }
        eshop_log({id_order=>'CRON',txt=>"$order{id} : Relance: Email envoyé De $setup{email_from} à $order{billing_email}"});
    }
}

sub eshop_relances_panier
{
    # Récupération de la config des emails
    my %eshop_emails_setup = %{get_eshop_emails_setup()};

    if($eshop_emails_setup{disabled_emailing} ne "y" && $eshop_emails_setup{disabled_relance_panier} ne "y")
    {
        if($eshop_emails_setup{relance_panier_first} > 0)
        {
            send_email_relance_panier($eshop_emails_setup{relance_panier_first});
        }
        
        if($eshop_emails_setup{relance_panier_second} > 0)
        {
            send_email_relance_panier($eshop_emails_setup{relance_panier_second});
        }
    }

}

sub send_email_relance_panier
{
    my $delai = $_[0] || 5;

    my $where = <<"EOH";
        DATE_SUB(DATE(NOW()),INTERVAL $delai DAY) = DATE(order_begin_moment) 
        AND email_relance_panier_sent < 2
        AND status = 'begin'
        AND payment_status = 'wait_payment'

EOH

    my @eshop_orders = sql_lines({debug=>0, debug_results=>0,table=>'eshop_orders', where=>$where});

    foreach $order (@eshop_orders)
    {
        my %order = %{$order};

        # On vérifie que la commande possède au moins un élément dans son panier
        my %order_details = sql_line({
            debug=>1,
            dbh=>$dbh,
            table=>"eshop_orders as orders, eshop_order_details as details",
            where =>"orders.id = details.id_eshop_order
                        AND orders.id = '$order{id}'",
            limit=>1,
        });



        if($order_details{id} > 0 && $order{billing_email} ne '')
        {
            print "relance $order{id}";
            print "<br/>";

            # Envoi du mail de relance panier
            eshop_mailing_relance_panier(\%order);      
            
            $stmt = "UPDATE eshop_orders SET email_relance_panier_sent = email_relance_panier_sent + 1 WHERE id = $order{id}";
            execstmt($dbh,$stmt);
            
            eshop_log({id_order=>'CRON',txt=>"$order{id} : Relance Panier: Email envoyé De $setup{email_from} à $order{billing_email}"});
        }
       
    }
}

sub eshop_relances_paiement
{
    # Récupération de la config des emails
    my %eshop_emails_setup = %{get_eshop_emails_setup()};

    if($eshop_emails_setup{disabled_emailing} ne "y" && $eshop_emails_setup{disabled_relance_paiement} ne "y")
    {
        if($eshop_emails_setup{relance_paiement_first} > 0)
        {
            send_email_relance_paiement($eshop_emails_setup{relance_paiement_first});
        }
        
        if($eshop_emails_setup{relance_paiement_second} > 0)
        {
            send_email_relance_paiement($eshop_emails_setup{relance_paiement_second});
        }
    }

}

sub send_email_relance_paiement
{
    my $delai = $_[0] || 5;

    my $where = <<"EOH";
        DATE_SUB(DATE(NOW()),INTERVAL $delai DAY) = DATE(order_begin_moment) 
        AND payment = 'virement'
        AND email_relance_paiement_sent < 2
        AND payment_status = 'wait_payment'
        AND (status = 'current'
        OR status = 'unfinished'
        OR status = 'new')
EOH

    my @eshop_orders = sql_lines({debug=>0, debug_results=>0,table=>'eshop_orders', where=>$where});
    
    foreach $order (@eshop_orders)
    {
        my %order = %{$order};

        if($order{billing_email} ne '')
        {
            # Envoi du mail de relance paiement
            eshop_mailing_relance_paiement(\%order);      
            
            
            $stmt = "UPDATE eshop_orders SET email_relance_paiement_sent = email_relance_paiement_sent + 1 WHERE id = $order{id}";
            execstmt($dbh,$stmt);
            
            eshop_log({id_order=>'CRON',txt=>"$order{id} : Relance Paiement: Email envoyé De $setup{email_from} à $order{billing_email}"});
        }
       
    }
}


