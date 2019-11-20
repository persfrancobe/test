#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use sitetxt;
use eshop;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


my $payment_status=get_quoted('payment_status');


$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{corbeille} = 0;
$dm_cfg{delete} = 0;
$dm_cfg{hide_id} = 1;
$dm_cfg{add} = 0;
$dm_cfg{restauration} = 0;
$dm_cfg{table_name} = "eshop_orders";
$dm_cfg{default_ordby} = "order_begin_moment desc";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{'list_custom_action_20_func'} = \&custom_icons;
$dm_cfg{visualiser} = 1;

my $filter_1 = get_quoted('filter_1') || '';
my $filter_2 = get_quoted('filter_2') || '';
my $filter_3 = get_quoted('filter_3') || '';
my $filter_4 = get_quoted('filter_4') || '';
my $filter_5 = get_quoted('filter_5') || '';
my $dm_search = get_quoted('dm_search') || '';

$dm_cfg{javascript_custom_func_listing} = 'custom_func_list';

# $dm_cfg{wherep} = $dm_cfg{wherel} = "recap_validate = 'y' AND (payment_status = 'repaid' || payment_status = 'paid' || payment_status = 'captured' || payment = 'virement' || payment = 'commande_fournisseur') AND total_tvac > 0";
# $dm_cfg{wherep} = $dm_cfg{wherel} = "recap_validate = 'y' AND (payment_status = 'repaid' || payment_status = 'paid' || payment_status = 'captured' || payment = 'virement' || payment = 'commande_fournisseur') AND total_tvac > 0";
$dm_cfg{wherep} = $dm_cfg{wherel} = "recap_validate = 'y' AND total_tvac > 0 AND status IN('new','current','finished','cancelled')";
# $dm_cfg{wherep} = $dm_cfg{wherel} = "status = 'new' OR status = 'current'";



$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?";
$dm_cfg{hiddp} = <<"EOH";

EOH

$dm_cfg{after_mod_ref} = \&after_save;


%status = (
	'01/unfinished' =>"1. Interrompue au paiement",
	'02/new'        =>"2. $migctrad{adm_order_status_new}",
	'03/current'    =>"3. $migctrad{adm_order_status_current}",
	'04/finished'   =>"4. $migctrad{adm_order_status_finished}",
	'05/cancelled'  =>"5. $migctrad{adm_order_status_cancelled}",
);

%status_conv = (
	'unfinished' =>"INTERROMPUE AU PAIEMENT",
	'new'        =>"NOUVELLE COMMANDE",
	'current'    =>"$migctrad{adm_order_status_current}",
	'finished'   =>"$migctrad{adm_order_status_finished}",
	'cancelled'  =>"$migctrad{adm_order_status_cancelled}",
);

%payment_status = (
	'01/wait_payment'   =>"1. $migctrad{adm_payment_status_wait}",
	'02/captured'       =>"2. $migctrad{adm_payment_status_captured}",
	'03/paid'           =>"3. $migctrad{adm_payment_status_paid}",
	'04/partial_repaid' =>"4. $migctrad{adm_payment_status_partial_repaid}",
	'05/repaid'         =>"5. $migctrad{adm_payment_status_repaid}",
	'06/cancelled'      =>"6. $migctrad{adm_payment_status_cancelled}",
);

%payment_status_conv = (
	'wait_payment'   =>"PAIEMENT EN ATTENTE",
	'captured'       =>"ARGENT CAPTURE",
	'paid'           =>"PAYEE",
	'partial_repaid' =>"PAIEMENT PARTIEL",
	'repaid'         =>"REMBOURSEE",
	'cancelled'      =>"PAIEMENT ANNULE",
);

%delivery_status = (
	'01/current'        =>"$migctrad{adm_delivery_status_current}",
	'02/ready'          =>"$migctrad{adm_delivery_status_ready}",
	'03/partial_sent'   =>"$migctrad{adm_delivery_status_partial_sent}",
	'04/full_sent'      =>"$migctrad{adm_delivery_status_full_sent}",
	'05/removed'        =>"$migctrad{adm_delivery_status_removed}",
	'06/cancelled'      =>"$migctrad{adm_delivery_status_cancelled}",
	'07/ready_to_take'  =>"$migctrad{adm_delivery_status_ready_to_take}",
	'08/retour'         =>"$migctrad{adm_delivery_status_return}",
	'09/partial_retour' =>"$migctrad{adm_delivery_status_partial_return}",
);

%delivery_status_conv = (
	'current'        =>"$migctrad{adm_delivery_status_current}",
	'ready'          =>"$migctrad{adm_delivery_status_ready}",
	'partial_sent'   =>"$migctrad{adm_delivery_status_partial_sent}",
	'full_sent'      =>"$migctrad{adm_delivery_status_full_sent}",
	'removed'        =>"$migctrad{adm_delivery_status_removed}",
	'cancelled'      =>"$migctrad{adm_delivery_status_cancelled}",
	'ready_to_take'  =>"$migctrad{adm_delivery_status_ready_to_take}",
	'retour'         =>"$migctrad{adm_delivery_status_return}",
	'partial_retour' =>"$migctrad{adm_delivery_status_partial_return}",
);

@dm_nav =
(
    {
      'tab'=>'resume',
			'type'=>'tab',
      'title'=>'Résumé de la commande'
    },
    {
      'tab'=>'chiffres',
			'type'=>'tab',
      'title'=>'Chiffres'
    },
    {
      'tab'=>'livraison',
			'type'=>'tab',
      'title'=>'Adresse de livraison'
    },
    {
      'tab'=>'facturation',
			'type'=>'tab',
      'title'=>'Adresse de facturation'
    },
    {
      'tab'=>'tracking',
			'type'=>'tab',
      'title'=>'Tracking'
    },
    {
      'tab'=>'admin',
			'type'=>'tab',
      'title'=>'Admin'
    }
	,
	 {
		'tab'=>'historique',
		'type'=>'tab',
		'title'=>'Historique',
		'cgi_func' => 'eshop::historique',
		'disable_add' => 1
	}
);


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (    
 	    
       ############ RESUME ############
     #   '02/id'=> 
     #   {
	    #     'title'=>"Numéro de commande",
	    #      'fieldtype'=>'display',
	    #     'fieldsize'=>'50',
	    #     'search' => 'y',
					# 'hidden'=>1,
					# 'tab' => "resume",
	    # }
     #  ,
      '03/id_member'=> 
       {
            'title'=>"$migctrad{adm_member}",
            'fieldtype'=>'listboxtable',
            'lbtable'=>'migcms_members',
            'lbkey'=>'migcms_members.id',
            'lbdisplay'=>('UPPER(CONCAT(migcms_members.delivery_firstname," ",migcms_members.delivery_lastname," ",migcms_members.delivery_company))'),
            'lbwhere'=>"",
            'tab' => "resume",
	    }
      ,
      '04/status'=> 
       {
	        'title'=>"$migctrad{adm_order_status}",
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%status,
          'mandatory'=>{"type" => 'not_empty'},
          'tab' => "resume",
	    }
      ,
 	    '06/delivery_status'=> 
       {
	        'title'=>"$migctrad{adm_delivery_status}",
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%delivery_status,
          'mandatory'=>{"type" => 'not_empty'},
          'tab' => "resume",
	    }
      ,
 	    '08/payment_status'=> 
       {
	        'title'=>"$migctrad{adm_payment_status}",
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%payment_status,
          'mandatory'=>{"type" => 'not_empty'},
          'tab' => "resume",
	    }
      ,
      '10/delivery'=> 
       {
            'title'=>"$migctrad{adm_method_delivery}",
            'fieldtype'=>'listboxtable',
            'lbtable'=>'eshop_deliveries',
            'lbkey'=>'name',
            'lbdisplay'=>'name',
            'lbwhere'=>"",
            'tab' => "resume",
	    }
      ,
      '12/payment'=> 
       {
			'title'=>"$migctrad{meth_billing}",
			'fieldtype'=>'listboxtable',
			'lbtable'=>'eshop_payments',
			'lbkey'=>'name',
			'lbdisplay'=>'name',
			'lbwhere'=>"",
			'tab' => "resume",
	    }
           ,
      '17/commentaire'=> 
       {
	        'title'=>"$migctrad{adm_comment}",
	         'fieldtype'=>'textarea',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "resume",
	    }
       ,
      '18/notifier_client'=> 
      {
        'title'=>"$migctrad{adm_auto_notify}",
        'fieldtype'=>'checkbox',
        'checkedval' => 'y',
        'tab' => "resume",
      }
       ,
       ############ CHIFFRES ############
      '19/total_qty'=> 
       {
	        'title'=>"$migctrad{adm_nbr_articles}",
	         'fieldtype'=>'display',
	        'fieldsize'=>'50',
	        'tab' => "chiffres",
	    }
      ,
      '20/total_weight'=> 
       {
	        'title'=>"Poids total",
	         'fieldtype'=>'display',
	        'fieldsize'=>'50',
	        'tab' => "chiffres",
	    }
      ,
      '21/total_tvac'=> 
       {
	        'title'=>"$migctrad{adm_subtotal}",
	        'fieldtype'=>'display',
	        'fieldsize'=>'50',
	        'tab' => "chiffres",
	    }
      ,
      '22/total_delivery_tvac'=> 
       {
	        'title'=>"$migctrad{adm_shipping_costs}",
	         'fieldtype'=>'display',
	        'fieldsize'=>'50',
	        'tab' => "chiffres",
	    }
       ,
      '23/total_discount_tvac'=> 
       {
	        'title'=>"$migctrad{adm_total_discounts}",
	         'fieldtype'=>'display',
	        'fieldsize'=>'50',
	        'tab' => "chiffres",
	    }
       ,
      '24/total_coupons_tvac'=> 
       {
	        'title'=>"$migctrad{adm_total_coupons}",
	         'fieldtype'=>'display',
	        'fieldsize'=>'50',
	        'tab' => "chiffres",
	    }
       ,
      '25/total_discounted_tvac'=> 
       {
	        'title'=>"$migctrad{adm_total_to_pay}",
	         'fieldtype'=>'display',
	        'fieldsize'=>'50',
	        'tab' => "chiffres",
	    }
      
      ,
      ############ ADRESSE DE LIVRAISON ############
       '32/delivery_firstname'=> 
       {
	        'title'=>"$migctrad{adm_firstname} (pour la livraison)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "livraison",
	    } 
      ,
       '34/delivery_lastname'=> 
       {
	        'title'=>"$migctrad{adm_lastname} (pour la livraison)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "livraison",
	    }
      ,
      '36/delivery_company'=> 
       {
	        'title'=>"$migctrad{adm_company} (pour la livraison)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "livraison",
	        
	    },
      '37/delivery_email'=> 
       {
	        'title'=>"$migctrad{adm_email} (pour la livraison)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "livraison",
	        
	    }
      ,
      '38/delivery_street'=> 
       {
	        'title'=>"$migctrad{adm_street} (pour la livraison)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "livraison",
	        
	    }
      ,
      '40/delivery_number'=> 
       {
	        'title'=>"$migctrad{adm_number} (pour la livraison)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "livraison",
	    }
      ,
      '42/delivery_box'=> 
       {
	        'title'=>"$migctrad{adm_box} (pour la livraison)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "livraison",
	        
	    }
      ,
      '44/delivery_city'=> 
       {
	        'title'=>"$migctrad{adm_city} (pour la livraison)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "livraison",
	    }
      ,
      '46/delivery_zip'=> 
       {
	        'title'=>"$migctrad{adm_zip} (pour la livraison)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "livraison",
	        
	    }
      ,
      '48/delivery_country'=> 
       {
            'title'=>"$migctrad{adm_country} (pour la livraison)",
            'fieldtype'=>'listboxtable',
            'lbtable'=>'countries',
            'lbkey'=>'countries.id',
            'lbdisplay'=>'countries.fr',
            'lbwhere'=>"",
            'tab' => "livraison",
	    }
      ,
      '50/delivery_phone'=> 
       {
	        'title'=>"$migctrad{adm_phone} 1 (pour la livraison)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "livraison",
	        
	    }
       ,
      '54/delivery_vat'=> 
       {
	        'title'=>"$migctrad{adm_vat} (pour la livraison)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "livraison",
	        
	    }
      ,
      ############ ADRESSE DE FACTURATION ############
       '64/billing_firstname'=> 
       {
	        'title'=>"$migctrad{adm_firstname} (pour la facturation)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "facturation",
	    } 
      ,
       '66/billing_lastname'=> 
       {
	        'title'=>"$migctrad{adm_lastname} (pour la facturation)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "facturation",
	    }
      ,
      '68/billing_company'=> 
       {
	        'title'=>"$migctrad{adm_company} (pour la facturation)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "facturation",
	        
	    }
      ,
      '69/billing_email'=> 
       {
	        'title'=>"$migctrad{adm_email} (pour la facturation)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "facturation",
	        
	    }
      ,
      '70/billing_street'=> 
       {
	        'title'=>"$migctrad{adm_street} (pour la facturation)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "facturation",
	        
	    }
      ,
      '72/billing_number'=> 
       {
	        'title'=>"$migctrad{adm_number} (pour la facturation)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "facturation",
	    }
      ,
      '74/billing_box'=> 
       {
	        'title'=>"$migctrad{adm_box} (pour la facturation)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "facturation",
	        
	    }
      ,
      '76/billing_city'=> 
       {
	        'title'=>"$migctrad{adm_city} (pour la facturation)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "facturation",
	    }
      ,
      '78/billing_zip'=> 
       {
	        'title'=>"$migctrad{adm_zip} (pour la facturation)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "facturation",
	        
	    }
      ,
      '80/billing_country'=> 
       {
            'title'=>"$migctrad{adm_country} (pour la facturation)",
            'fieldtype'=>'listboxtable',
            'lbtable'=>'countries',
            'lbkey'=>'countries.id',
            'lbdisplay'=>'countries.fr',
            'lbwhere'=>"",
            'tab' => "facturation",
	    }
      ,
      '82/billing_phone'=> 
       {
	        'title'=>"$migctrad{adm_phone} 1 (pour la facturation)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "facturation",
	        
	    }
       ,
      '86/billing_vat'=> 
       {
	        'title'=>"$migctrad{adm_vat} (pour la facturation)",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'tab' => "facturation",
	        
	    }
      ,
      ########### TRACKING COLIS ############
       '92/tracking'=> 
       {
	        'title'=>"$migctrad{adm_tracking}",
	        'fieldtype'=>'text',
	        'fieldsize'=>'60',
	        'search' => 'y',
	        'tab' => "tracking",
	        
	    } 
      ,
	    '93/tracking_num'=> {
	        'title'=>"$migctrad{adm_tracking_number}",
	        'fieldtype'=>'text',
	        'fieldsize'=>'70',
	        'search' => 'y',
	        'tab' => "tracking",
	    }
	     ########### ADMIN ############
	     , 
       '94/email_sent'=> 
       {
	        'title'=>"$migctrad{adm_confirm_email_sent}",
	        'fieldtype'=>'text',
	        'fieldsize'=>'60',
	        'search' => 'y',
	        'tab' => "admin",
	        
	    }
       ,
       '95/email_billing_sent'=> 
       {
	        'title'=>"$migctrad{adm_billing_sent}",
	        'fieldtype'=>'text',
	        'fieldsize'=>'60',
	        'search' => 'y',
	        'tab' => "admin",
	        
	    }
       , 
       '96/email_delivery_sent'=> 
       {
	        'title'=>"$migctrad{adm_delivery_sent}",
	        'fieldtype'=>'text',
	        'fieldsize'=>'60',
	        'search' => 'y',
	        'tab' => "admin",
	        
	    }
       , 
       '97/email_finished_sent'=> 
       {
	        'title'=>"$migctrad{adm_thanking_sent}",
	        'fieldtype'=>'text',
	        'fieldsize'=>'60',
	        'search' => 'y',
	        'tab' => "admin",
	        
	    }
       ,
       '98/email_relance_panier_sent'=> 
       {
	        'title'=>"$migctrad{adm_relance_sent}",
	        'fieldtype'=>'text',
	        'fieldsize'=>'60',
	        'search' => 'y',
	        'tab' => "admin",
	        
	    }
       ,
       '98/email_relance_paiement_sent'=> 
       {
	        'title'=>"$migctrad{adm_relance_payment_sent}",
	        'fieldtype'=>'text',
	        'fieldsize'=>'60',
	        'search' => 'y',
	        'tab' => "admin",
	        
	    }
       ,
       '98/stock_updated'=> 
       {
	        'title'=>"$migctrad{adm_stock_impacted}",
	        'fieldtype'=>'text',
	        'fieldsize'=>'60',
	        'search' => 'y',
	        'tab' => "admin",
	        
	    }
      , 
       '99/post_order_ok'=> 
       {
	        'title'=>"$migctrad{adm_auto_process_called}",
	        'fieldtype'=>'text',
	        'fieldsize'=>'60',
	        'search' => 'y',
	        'tab' => "admin",
	        
	    }
	    , 
       'a120/email_facture_pdf_sent'=> 
       {
	        'title'=>"Email de facture PDF envoyé",
	        'fieldtype'=>'text',
	        'fieldsize'=>'60',
	        'search' => 'y',
	        'tab' => "admin",
	        
	    }	    
	);
 
 
%dm_display_fields = (
);

%dm_lnk_fields = (
"05/$migctrad{adm_number}"   =>"get_numero*",
"11/Livraison" =>"get_livraison*",
"15/$migctrad{adm_payment}"  =>"get_payment*",
"20/Remarque"  =>"get_remarque*",
# "75/"    =>"get_infos*"
);

%dm_mapping_list = (
"get_numero"=>\&get_numero,
"get_livraison"=>\&get_livraison,
"get_payment"=>\&get_payment,
"get_remarque"=>\&get_remarque,
# "get_infos"=>\&get_infos,
);



%dm_filters = (
"1/$migctrad{adm_order_status}"=>
{
      'type'=>'hash',
	     'ref'=>\%status,
	     'col'=>'status'
}
,
"3/$migctrad{adm_payment_status}"=>
{
             'type'=>'hash',
	     'ref'=>\%payment_status,
	     'col'=>'payment_status'
}
,
"4/$migctrad{adm_delivery_status}"=>
{
             'type'=>'hash',
	     'ref'=>\%delivery_status,
	     'col'=>'delivery_status'
}

,
"5/$migctrad{adm_delivery}"=>{
                         'type'=>'lbtable',
                         'table'=>'eshop_deliveries',
                         'key'=>'name',
                         'display'=>'name',
                         'col'=>'delivery',
                         'where'=>''
                        }
,
"6/$migctrad{adm_payment}"=>{
                         'type'=>'lbtable',
                         'table'=>'eshop_payments',
                         'key'=>'name',
                         'display'=>'name',
                         'col'=>'payment',
                         'where'=>''
                        }
,
"7/Membre"=>{
 'type'=>'lbtable',
 'table'=>'migcms_members',
 'key'=>'id',
 'display'=>('UPPER(CONCAT(migcms_members.delivery_firstname," ",migcms_members.delivery_lastname," ",migcms_members.delivery_company))'),,
 'col'=>'id_member',
 'where'=>'actif="y" AND delivery_firstname != "" AND delivery_lastname != ""'
}
,
"2/Dates"=>{
                         'type'=>'fulldaterange',
                         'col'=>'order_begin_moment',
                        }						
);

my $montant = '';

 my $where = dm::list_get_where({wherel =>$dm_cfg{wherel},wherep =>$dm_cfg{wherep}, keyword => $keyword, specific_col => $specific_col, filters => $filters});
 my %total = sql_line({select=>"SUM(total_discounted_tvac) as total",table=>"eshop_orders",where=>$where});
$montant = eshop::display_price($total{total});



$dm_cfg{list_html_bottom} = <<"EOH";
<style>
.mig_cb_col,.td-input
{
	display:none;
}
.list_actions_4 div.btn-group_dis 
{
	padding: 10px 0px 0px 10px;
}
.list_action a.disabled
{
	color:grey;
}
.mig_cell_func_1
{
	width:230px;
}
.mig_cell_func_2
{
	width:230px;
}
.mig_cell_func_3
{
	width:210px;
}
.list_actions_4
{
	width:145px!important;
}
.cmdnumero_box_status
{
	background-color:#0389c6;
	color:white;
	padding:3px 4px 3px 4px;
	font-weight:bold;
}
.cmdnumero_box_methode_livraison
{
	color:#0389c6;
	padding:3px 4px 3px 0px;
	font-weight:bold;
}
.cmdnumero_box_date
{
	position:absolute;
	right:20px;
}
.cmdnumero_box_number
{
	font-weight:bold;
	padding: 10px 0px 10px 0px;
}
.cmdnumero_box_name
{
	font-weight:bold;
	padding: 10px 0px 10px 0px;
}
.cmdnumero_box_elt
{
	padding:2px 10px;
	position:relative;
}
.cmdnumero_box_date_commande
{
	margin:19px 0px 10px 10px;
}
.cmdnumero_box_phone a
{
	text-decoration:underline!important;
}


</style>
<div class="panel">
<div class="panel-footer ">
                            <h3>
									<span class="">Chiffre d'affaire: <b class="eshop_montant">$montant</b> TVAC</span>
									</span>
							</h3>
							
                        </div>
</div>
<script>
jQuery(document).ready(function() 
{
    jQuery(".search_element").change(function()
	{
		get_request_body();
	});
	 jQuery("#list_keyword").keypress(function()
	{
		get_request_body();
	});
	 jQuery("#list_keyword").blur(function()
	{
		get_request_body();
	});
});

function custom_func_list()
{
	jQuery('.list_actions_2').removeClass('list_actions_2').addClass('list_actions_6');
}

function get_request_body()
{
    jQuery(".admin_list_pageloader").show();
    jQuery("#sorting_box").hide();
	custom_func_list();
    
    var page = jQuery("#page").val();
	var colg = jQuery(".colg").val();
    var nr = jQuery("#nr").val();
    var list_keyword = jQuery("#list_keyword").val();
	var list_tags_vals = jQuery("#list_tags_vals").val();
    var list_specific_col = jQuery("#list_specific_col").val();
    var list_count_filters = parseInt(jQuery("#list_count_filters").val());
    var filters = '';
    var sort_field_name = jQuery("#sort_field_name").val();
    var sort_field_sens = jQuery("#sort_field_sens").val();
        
    for(var i = 1;i<list_count_filters;i++)
    {
        var name = jQuery("#list_filter_"+i).attr('name');
        var value = jQuery("#list_filter_"+i).val();
        filters += name+'---'+value+'___';    
    }
    
    var nb_col = jQuery("#migc4_main_table thead tr th").length;
    jQuery(".admin_list_pageloader img").fadeIn();
    
	var report_range_name = jQuery('.report_range').attr('name');
	var report_range_value = jQuery('.report_range').val();
	
    var list_func = jQuery("#list_func").val();
	//alert(list_func);
	var render = 'html';
    var request = jQuery.ajax(
    {
        url: self,
        type: "GET",
        data: 
        {
           sw : list_func,
		   selection : 'sum(total_discounted_tvac) as result',
           page : page,
           nr : nr,
           list_keyword : list_keyword,
		   list_tags_vals : list_tags_vals,
           list_specific_col : list_specific_col,
           filters : filters,
		   lg : colg,
           render : render,
		   report_range_name : report_range_name,
           report_range_value : report_range_value,
           sort_field_name : sort_field_name,
           sort_field_sens : sort_field_sens,
		   restauration_active: jQuery("#restauration_active").val()
        },
        dataType: "html"
    });
    
    request.done(function(msg) 
    {
			
			var montant = msg;
			montant *= 100;
			montant = parseInt(montant);
			montant /= 100;
			montant = montant+'€';
			jQuery('.eshop_montant').html(montant);
			jQuery('.admin_list_pageloader').hide();
	});      
        
  request.fail(function(jqXHR, textStatus) 
  {
  });
}
</script>


EOH


$sw = $cgi->param('sw') || "list";

if($sw ne 'export_commandes' && $sw ne 'export_orders_pdf')
{
	see();
}

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);

    my $suppl_js=<<"EOH";
    <link href="//netdna.bootstrapcdn.com/font-awesome/4.1.0/css/font-awesome.min.css" rel="stylesheet">

    <style>
    
    #dm_button_del
    {
        display:none;
    }
    
    </style>
EOH
    
    print migc_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}


################################################################################
# Création du formulaire d'export
################################################################################
sub export_form
{
	
	my @fournisseurs = sql_lines({
		dbh=>$dbh,
	 	table=>"data_field_listvalues",
	 	where=>"id_data_family='$id_data_family' AND id_data_field = '$id_data_field'"
	 });

	my $options;
	foreach $fournisseur (@fournisseurs)
	{
		%fournisseur = %{$fournisseur};

		my ($fournisseur_nom, $empty) = get_textcontent($dbh, $fournisseur{id_textid_name});

		$options .= "<option value='$fournisseur{id}'>$fournisseur_nom</option>";
	}

	my $content = <<"HTML";
		<link rel="stylesheet" href="//code.jquery.com/ui/1.11.2/themes/smoothness/jquery-ui.css">
		<script type="text/javascript">
			jQuery(function(){

				jQuery(".datepicker").datepicker({
					altField: "#datepicker",
					closeText: 'Fermer',
					prevText: 'Précédent',
					nextText: 'Suivant',
					currentText: 'Aujourd hui',
					monthNames: ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'],
					monthNamesShort: ['Janv.', 'Févr.', 'Mars', 'Avril', 'Mai', 'Juin', 'Juil.', 'Août', 'Sept.', 'Oct.', 'Nov.', 'Déc.'],
					dayNames: ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'],
					dayNamesShort: ['Dim.', 'Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.'],
					dayNamesMin: ['D', 'L', 'M', 'M', 'J', 'V', 'S'],
					weekHeader: 'Sem.',
					dateFormat: 'dd/mm/yy',
					});

			});
		</script>

		<div class="mig_add_update_form">
			<fieldset class="mig_fieldset2">
				<h2 class="mig_legend">Export Excel</h2>
				<div class="mig_add_update_form_content">
					<form method="post" name="export_commandes" action="$dm_cfg{self}">
						<input type="hidden" name="sw" value="export_commandes">

						<div class="mig_search_filter">
							<p>
								<label>
									<span>Date de début :</span>
									<input class="mig_input_txt datepicker" type="text" name="date_debut">
								</label>
							</p>
						</div>
						<div class="mig_search_filter">
							<p>
								<label>
									<span>Date de fin :</span>
									<input class="mig_input_txt datepicker" type="text" name="date_fin">
								</label>
							</p>
						</div>
						
						<button id="dm_button_export" class="mig_button mig_search_filter_button" type="submit" style="width:auto">Export Excel</button>
					</form>
				</div>
			</fieldset>
			
			<fieldset class="mig_fieldset2">
				<h2 class="mig_legend">Export PDF</h2>
				<div class="mig_add_update_form_content">
					<form method="post" action="$dm_cfg{self}">
						<input type="hidden" name="sw" value="export_orders_pdf">

						<div class="mig_search_filter">
							<p>
								<label>
									<span>Date de début :</span>
									<input class="mig_input_txt datepicker" type="text" name="date_debut">
								</label>
							</p>
						</div>
						<div class="mig_search_filter">
							<p>
								<label>
									<span>Date de fin :</span>
									<input class="mig_input_txt datepicker" type="text" name="date_fin">
								</label>
							</p>
						</div>
						<div class="mig_search_filter">
							<p>
								<label>
									<span>Type :</span>
									<select class="mig_select" name="type">
										<option value="commande">Facture Pro Forma</option>
										<option value="facture">Facture</option>
										<option value="note">Note de crédit</option>
									</select>
								</label>
							</p>
						</div>
						
						<button id="dm_button_export" class="mig_button mig_search_filter_button" type="submit" style="width:auto">Export PDF</button>
					</form>
				</div>
			</fieldset>
		</div>
		
HTML

	$dm_output{content} = $content;
}

sub export_orders_pdf
{
  my $date_debut = get_quoted("date_debut");
  my $date_fin   = get_quoted("date_fin");
  my $type       = get_quoted("type") || "commande";
  my $file = '';

  # Convertion des dates au format sql
  my $date_debut = to_ansi_date($date_debut) . " 00:00:00";
  my $date_fin = to_ansi_date($date_fin) . " 23:59:59"; 

  my $where_dates = '';
  if($date_debut ne '')
  {
    $where_dates .= "AND order_begin_moment >= '$date_debut'";
  }
  if($date_fin ne '')
  {
    $where_dates .= " AND order_begin_moment <= '$date_fin'";
  }

  my $where_types = "";
  if($type eq "note")
  {
    $where_types = " AND invoice_nc != ''";
  }
  elsif($type eq "facture")
  {
    $where_types = " AND invoice_num != ''";
  }

  my $ordby_type="";
  if($type eq "facture")
  {
    $ordby_type = "invoice_num desc";
  }
  elsif($type eq "note")
  {
    $ordby_type = "invoice_nc desc";
  }
  else
  {
    $ordby_type = "id desc";
  }

  # On récupère toutes les commandes terminée et payée de cet interval
  my @orders = sql_lines({
      dbh=>$dbh,
      table=>"eshop_orders",
      where=> "(eshop_orders.payment_status = 'paid' || eshop_orders.payment_status = 'captured' || eshop_orders.payment_status = 'repaid' )".$where_dates.$where_types,
      ordby=>$ordby_type,
  });

  my $size = @orders;
  if($size > 0)
  {
    my @pdfs;
    foreach $order (@orders)
    {
       %order = %{$order};

      $file =  generate_facture($order{token}, $type);
      push @pdfs, $file;
    }

    use PDF::API2;

    my $file_type = "order";
    if($type eq "facture")
    {
      $file_type = "invoice";
    }
    elsif($type eq "note")
    {
      $file_type = "nc";
    }

    my @date_debut_lines = split(/ /,$date_debut);
    my $date_debut_output = $date_debut_lines[0];
    my @date_fin_lines = split(/ /,$date_fin);
    my $date_fin_output = $date_fin_lines[0];

    my $output_file = "../inv/" . $file_type ."_". $date_debut_output ."_". $date_fin_output.".pdf";
    # the output file
    my $output_pdf = PDF::API2->new(-file => $output_file);
    
    foreach my $pdf (@pdfs) 
    {
      my $input_pdf = PDF::API2->open($pdf);
      my @numpages = (1..$input_pdf->pages());
      foreach my $numpage (@numpages)
      {
          # add page number $numpage from $pdfs to the end of 
          # the file $output_file
          $output_pdf->importpage($input_pdf,$numpage,0);        
      }
    }

	$output_pdf->save(); 
	# exit;

    my @tmp = split(/\//,$output_file);
    my $file_display = $tmp[$#tmp];
    print $cgi->header(-attachment=>$file_display,-type=>'application/pdf');
    open (FILE,$output_file);
    binmode FILE;
    binmode STDOUT;
    while (read(FILE,$buff,2096)){
      print STDOUT $buff;
    }
    close (FILE);
    exit;
  }
  else
  {
  	see();
    my $content = <<"HTML";
      <script type="text/javascript">
        alert("Aucune commande n'a été trouvée");
        window.history.back()
      </script>

HTML
	$dm_output{content} = $content;
  }  

  
}



sub export_commandes 
{
	my $date_debut = get_quoted("date_debut");
	my $date_fin = get_quoted("date_fin");



		# Suppression des / dans les dates pour écritures du fichier excel
		my $date_debut_output = $date_debut;
		$date_debut_output =~ s/\///g ;
		my $date_fin_output = $date_fin;
		$date_fin_output =~ s/\///g ;

		# Convertion des dates au format sql
		my $date_debut = to_ansi_date($date_debut) . " 00:00:00";
		my $date_fin = to_ansi_date($date_fin) . " 23:59:59";
		
		my $where_dates = '';
		if(get_quoted("date_debut") ne '')
		{
			$where_dates .= "AND order_begin_moment >= '$date_debut'";
		}
		if(get_quoted("date_fin") ne '')
		{
			$where_dates .= "AND order_begin_moment <= '$date_fin'";
		}
	
		my @orders = sql_lines({
			debug=>0,
			dbh=>$dbh,
			select=> "eshop_orders.id as 01_commande_numero,
								details.detail_reference as 02_produit_reference,
								details.detail_label as 03_produit_nom,
								details.detail_qty as 06_detail_qty,
								details.detail_total_discounted_tvac as 08_detail_total_discounted_tvac,
								eshop_orders.delivery_firstname as 09_delivery_firstname,
								eshop_orders.delivery_lastname as 10_delivery_lastname,
								eshop_orders.delivery_company as 11_delivery_company,
								eshop_orders.delivery_street as 12_delivery_street,
								eshop_orders.delivery_number as 13_delivery_number,
								eshop_orders.delivery_city as 16_delivery_city,
								eshop_orders.delivery_zip as 17_delivery_zip,
								eshop_orders.delivery_country as 18_delivery_country,
								eshop_orders.delivery_email as 21_delivery_email,
								eshop_orders.billing_firstname as 23_billing_firstname,
								eshop_orders.billing_lastname as 24_billing_lastname,
								eshop_orders.billing_company as 25_billing_company,
								eshop_orders.billing_street as 26_billing_street,
								eshop_orders.billing_number as 27_billing_number,
								eshop_orders.billing_city as 30_billing_city,
								eshop_orders.billing_zip as 31_billing_zip,
								eshop_orders.billing_country as 32_billing_country,
								eshop_orders.billing_email as 35_billing_email,
								eshop_orders.order_begin_moment as 37_order_begin_moment,
								eshop_orders.total_discounted_tvac as 42_total_discounted_tvac
								",
			table=>"eshop_orders, eshop_order_details as details",
			where=> "(eshop_orders.payment_status = 'paid' || eshop_orders.payment_status = 'captured' )
							AND eshop_orders.id = details.id_eshop_order
							".$where_dates,
			ordby=>"order_begin_moment asc"
		});
		
	



		my $outfile = "../usr/export_orders.xls";

		# Si on récupère des commandes
		if(@orders)
		{
			# On écrit l'entete
	    my @header = 
	    (
								"Numéro commande",
								"Référence",
								"Nom",
								"Qté",
								"Total produit TVAC",
								"Livraison: prénom",
								"Livraison: nom",
								"Livraison: société",
								"Livraison: rue",
								"Livraison: numéro",
								"Livraison: ville",
								"Livraison: CP",
								"Livraison: pays",
								"Livraison: email",
								"Facturation: prénom",
								"Facturation: nom",
								"Facturation: société",
								"Facturation: rue",
								"Facturation: numéro",
								"Facturation: ville",
								"Facturation: CP",
								"Facturation: pays",
								"Facturation: email",
								"Date commande",
								"Total commande TVAC",
	    );
	   
			# Export excel des données
			export_xls($outfile, \@orders, \@header);
			# http_redirect("$self?sw=export_form");
		}
		else
		{
			$dm_output{content} = "Aucune commande n'a été trouvée avec cet interval de date";
		}
	
	
}

sub export_xls
{

	my $outfile = $_[0];
	my @orders = @{$_[1]}; 
	my @header = @{$_[2]};

    use Spreadsheet::ParseExcel;
    use Spreadsheet::WriteExcel;
    use Encode;  

    my $workbook = Spreadsheet::WriteExcel->new($outfile); 
    my $worksheet = $workbook->add_worksheet("");

    $row = 0;
    $col= 0;

    my $bleu = $workbook->set_custom_color(63, 63, 107, 155);

    my $format_entete  = $workbook->add_format(
                        bg_color => $bleu,
                        align => "center",
                        color => "white",
                        pattern  => 1,
                        border   => 2
                      ); 

    my $format_corps =  $workbook->add_format(
                        bg_color => "white",
                        pattern  => 1,
                        border   => 1
                      ); 

    $worksheet->set_column('A:AP', 30);


    foreach $header (@header)
    {
        $header = decode("utf8", $header);
        $worksheet->write($row,$col++,$header, $format_entete);

    }

    # Retour première colonne et on descend d'une ligne
    $row++;
    $col = 0;

        
    foreach $order (@orders)
    {
        %order = %{$order};

        foreach $infos (sort keys %order)
        {
            $infos = decode("utf8",$order{$infos});
            $worksheet->write($row,$col,$infos,$format_corps);
            $col++;
        }

        $col = 0;
        $row++;
        
    } 

    $workbook->close();

    open (FILE,$outfile);
    binmode FILE;
    binmode STDOUT;
    while (read(FILE,$buff,2096))
    {
         print $cgi->redirect(-location=>$outfile,-content-type=>'application/octet-stream');
         print STDOUT $buff;
    }
    close (FILE); 
       
}

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
 
   #MOD-------------------------------------------------------------------------
   my $id=get_quoted('id') || 0;
   if($id > 0)
   {
        #check previous record--------------------------------------------------
        my %previous_item=read_table($dbh,"eshop_orders",$id);
        
        #check if delivery status has changed-----------------------------------
        if($previous_item{delivery_status} ne $item{delivery_status} && $item{delivery_status} ne '')
        {
            # eshop_log({id_order=>$id,txt=>"Changement manuel du statut de la livraison de la commande: $item{delivery_status}"});
        }
        #check if payment status has changed-----------------------------------
        if($previous_item{payment_status} ne $item{payment_status} && $item{payment_status} ne '')
        {
            # eshop_log({id_order=>$id,txt=>"Changement manuel du statut de la paiement de la commande: $item{payment_status}"});
        }
        #check if order status has changed-----------------------------------
        if($previous_item{status} ne $item{status} && $item{status} ne '')
        {
            # eshop_log({id_order=>$id,txt=>"Changement manuel du statut de la commande: $item{status}"});
        }
   }

	return (\%item);	
}

sub after_save
{
	# my $dbh = $_[0];
	log_debug('order_after_save','vide','order_after_save');
	my $id = $_[1];
	log_debug($id,'','order_after_save');
	my %order = sql_line({table=>"eshop_orders",where=>"id='$id'"});
	log_debug($order{id},'','order_after_save');
	my %setup = %{eshop::get_setup()};
	 
	 
	#update delivery link if empty and bpost
	  if($order{delivery} eq 'bpost' && $order{tracking} eq '' && $order{tracking_num} eq '')
	  {
		 my $tracking_num = $setup{code}.'O'.$order{id};
		 my $tracking = 'http://track.bpost.be/etr/light/performSearch.do?searchByCustomerReference=true&oss_language=fr&customerReference='.$tracking_num;
		 my $stmt = <<"EOH";
             UPDATE eshop_orders SET tracking_num='Bpost Track and Trace', tracking='$tracking' WHERE id = '$order{id}'
EOH
          execstmt($dbh,$stmt);
		  %order = sql_line({table=>"eshop_orders",where=>"id='$order{id}'"});
	  }
     log_debug($order{id},'','order_after_save');
     #EXECUTION DE LA POST FONCTION
     exec_post_order({order=>\%order,payment_status=>$order{payment_status}});
	  log_debug('exec_post_order ok','','order_after_save');

	 log_debug($order{id},'','order_after_save');
     #UPDATE STOCK
     eshop::update_stock({order=>\%order});
	 log_debug('update_stock ok','','order_after_save');
     
     #EMAIL CONFIRMATION
     eshop_mailing_confirmation(\%order);
	  log_debug('eshop_mailing_confirmation ok','','order_after_save');
    
     my $use_backorder = get_quoted('use_backorder') || 'n';
     if($use_backorder eq 'y')
     {
     my @order_details = sql_lines({table=>'eshop_order_details',where=>"id_eshop_order='$order{id}'",ordby=>"detail_qty_restant desc,detail_label"});
     foreach $detail (@order_details)
     {
         my %detail = %{$detail};
         my $qty = get_quoted('detail_'.$detail{id});
         my $qty_restant = get_quoted('restant_'.$detail{id});
         if(!($qty>0))
         {
            $qty = 0;
         }
         if($qty_restant < $qty)
         {
            $qty = $qty_restant;
         }
         
         my %eshop_order_details_expeditions = (
            id_eshop_order => $order{id},
            id_eshop_order_detail => $detail{id},
            expedition_moment => 'NOW()',
            expedition_detail_label => $detail{detail_label} ,
            expedition_detail_reference => $detail{detail_reference},
            prenom => $order{delivery_firstname},
            nom => $order{delivery_lastname},
            qty => $qty,
         );
         inserth_db($dbh,"eshop_order_details_expeditions",\%eshop_order_details_expeditions);
       
        my $nom_commande = "$order{delivery_firstname} $order{delivery_lastname}";
        $nom_commande =~ s/\'/\\\'/g; 
        
         #UPDATE QTY EXPEDIE FOR DETAIL 
         my $stmt = <<"EOH";
            UPDATE eshop_order_details SET nom_commande = '$nom_commande', detail_qty_expedie = (select SUM(qty) FROM eshop_order_details_expeditions WHERE id_eshop_order_detail = '$detail{id}')  WHERE id = '$detail{id}' 
EOH
         execstmt($dbh,$stmt);
         
         #UPDATE QTY RESTANT FOR DETAIL 
         my $stmt = <<"EOH";
            UPDATE eshop_order_details SET detail_qty_restant = detail_qty - detail_qty_expedie  WHERE id = '$detail{id}'
EOH
         execstmt($dbh,$stmt);
     }
     #UPDATE TOTAL QTY EXPEDIE FOR ORDER 
      my $stmt = <<"EOH";
         UPDATE eshop_orders SET use_backorder= '$use_backorder', total_qty_expedie = (select SUM(detail_qty_expedie) FROM eshop_order_details WHERE id_eshop_order = '$order{id}') WHERE id = '$order{id}'
EOH
      execstmt($dbh,$stmt);
      
      #UPDATE TOTAL QTY RESTANT FOR ORDER 
      my $stmt = <<"EOH";
         UPDATE eshop_orders SET use_backorder= '$use_backorder',  total_qty_restant = (select SUM(detail_qty_restant) FROM eshop_order_details WHERE id_eshop_order = '$order{id}') WHERE id = '$order{id}'
EOH
      execstmt($dbh,$stmt);
      
          #SET FLAG "cmd fourn" for filters
          my %order_updated = read_table($dbh,"eshop_orders",$order{id});
          if($order_updated{total_qty_restant} > 0)
          {
               my $stmt = <<"EOH";
             UPDATE eshop_orders SET cmd_fourn='y' WHERE id = '$order{id}'
EOH
          execstmt($dbh,$stmt);
          }
          else
          {
               my $stmt = <<"EOH";
             UPDATE eshop_orders SET cmd_fourn='n' WHERE id = '$order{id}'
EOH
          execstmt($dbh,$stmt);
          }
      }
     else
        {
             my $stmt = <<"EOH";
           UPDATE eshop_orders SET use_backorder='n' WHERE id = '$order{id}'
EOH
        # print $stmt;
        execstmt($dbh,$stmt);
        }
      
      
      
      if($order{delivery_status} eq '' || $order{delivery_status} eq 'current' || $order{delivery_status} eq 'partial_sent')
      {
          #envois partiels en cours: cmd fournisseurs ok
          #vide current partial_sent
      } 
      else
      {
          #envois terminés ou annulés: pas de cmd fournisseurs
          #cancelled full_sent ready_to_take  ready retour
           my $stmt = <<"EOH";
             UPDATE eshop_order_details SET detail_qty_restant = 0,  detail_qty_expedie = detail_qty WHERE id_eshop_order = '$order{id}'
EOH
          execstmt($dbh,$stmt);
          
          my $stmt = <<"EOH";
             UPDATE eshop_orders SET cmd_fourn='n', use_backorder= 'n',  total_qty_restant = 0, total_qty_expedie = total_qty WHERE id = '$order{id}'
EOH
          execstmt($dbh,$stmt);
      } 
      
	

	# Génération d'un numéro senquentiel de facture
	# - Si la commande est payée ET terminée
	# - Si la commande est payée et qu'on a activé la config de génération dès paiement
	if(($order{status} eq "finished" || $setup{generate_bill_number_if_paid} eq "y") && $order{payment_status} eq "paid" && $order{total_tvac} > 0)
	{	
		# Génération séquentielle classique du numéro de facture
		if($order{invoice_num} eq "")
		{
			my $invoice_num = eshop::generate_sequential_num_db({id=>$order{id}, table=>"eshop_orders", col=>"invoice_num"});			

		}

		# Génération sur-mesure du numéro de facture
		if($setup{generate_custom_inv_number} ne '' && $order{invoice_num_handmade} eq "")
		{
			my $generate_custom_inv_number = 'def_handmade::'.$setup{generate_custom_inv_number};
			&$generate_custom_inv_number({order_id => $order{id}});		
		}
		
		%order = sql_line({table=>"eshop_orders",where=>"id='$id'"});	

		# Envoie de la facture PDF
		eshop::eshop_mailing_facture_pdf(\%order);
	}


	# Génération d'un numéro séquentiel de Note de crédit si la commande est remboursée
	if($order{status} eq "finished" && $order{payment_status} eq "repaid" && $order{invoice_num} ne "")
	{
		if($order{invoice_nc} eq "")
		{
			my $invoice_num = eshop::generate_sequential_num_db({id=>$order{id}, table=>"eshop_orders", col=>"invoice_nc"});	
		}

		# Génération sur-mesure du numéro de facture
		if($setup{generate_custom_nc_number} ne '' && $order{invoice_nc_handmade} eq "")
		{
			log_debug("GENERATION", "vide", "numero_facture");
			my $generate_custom_nc_number = 'def_handmade::'.$setup{generate_custom_nc_number};
			&$generate_custom_nc_number({order_id => $order{id}});		
		}

		%order = sql_line({table=>"eshop_orders",where=>"id='$id'"});
	}      

 	#Envoi de la facture si le status passe à payé
 	if($order{payment_status} eq "paid" && $order{email_billing_sent} eq "n")
  {
  	eshop_mailing_facture(\%order);   	
  } 

  

  # Envoi du mail d'expédition de commande si envoyé ou partiellement envoyé
  if(($order{delivery_status} eq "full_sent" || $order{delivery_status} eq "partial_sent") && $order{email_delivery_sent} eq "n")
  {
  	eshop_mailing_order_send(\%order);            	       		
  }

  #Envoi du mail de remerciement si la commande est terminée
 	if($order{status} eq "finished" && $order{email_finished_sent} eq "n")
  {
  	eshop_mailing_order_finished(\%order);            	
  }    
      
    # Envoi du mail de changement de status 
	if($order{notifier_client} eq 'y' && $order{billing_email} ne '')
	{

		eshop_mailing_update_status(\%order, $payment_status{$order{payment_status}}, $delivery_status{$order{delivery_status}});
	   
		my $stmt = <<"EOH";
		    UPDATE eshop_orders
		    SET
		       notifier_client = 'n'
		    WHERE
		        id = $id
EOH

		execstmt($dbh,$stmt);        
	    
	}
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
  
}



sub get_delivery_status
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %order = sql_line({table=>"eshop_orders",where=>"id='$id'"});
  return <<"EOH";
  $delivery_status{$order{delivery_status}}
EOH
}

sub get_status
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %order = sql_line({table=>"eshop_orders",where=>"id='$id'"});
  
  return <<"EOH";
  $status{$order{status}}
EOH
}


 #--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


 #--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_bon
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  my %order = sql_line({table=>"eshop_orders",where=>"id='$id'"});
  return <<"EOH";
   <div style="text-align:center;">
   	<a target="_blank" title="Voir la confirmation" href="$config{baseurl}/fr/boutique/confirmation/$order{token}" style="font-size:14px; margin:5px;"><i class="fa fa-eye"></i></a>
   </div>
EOH
}

# 
# 
# 
# "77/Coupon"=>"total_coupons_tvac",
# "88/Email"=>"email_sent",
# "89/Stock"=>"stock_updated",
# "90/Post-tr"=>"post_order_ok"
# 
# 



#*****************************************************************************************
#SQL TO HUMAN TIME
#*****************************************************************************************
sub sql_to_human_date
{
   my $content = trim($_[0]);
   my ($year,$month,$day) = split (/-/,$content);
   return <<"EOH";
$day/$month/$year
EOH
}

#*****************************************************************************************
#SQL TO HUMAN TIME
#*****************************************************************************************
sub sql_to_human_time
{
   my $content = trim($_[0]);
   my $separator = $_[1] || 'h';
   my ($hour,$min,$sec) = split (/:/,$content);
   return $hour.$separator.$min;
EOH
}

sub get_numero
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  my %order = sql_line({table=>"eshop_orders",where=>"id='$id'"});
  $id = sprintf("%08d",$id);
  $order{invoice_num} = sprintf("%08d",$order{invoice_num});
  $order{invoice_nc} = sprintf("%08d",$order{invoice_nc});
  my $order_moment = eshop::get_order_moment(\%order);
  
  my $date=to_ddmmyyyy($order_moment,"withtime");

  my $status_name = uc($status_conv{$order{status}});
  $status_name = uc(remove_accents_from($status_name));

  if($status_name eq '')
  {
	$status_name = "[$order{status}]";
  }
  
  my $info = <<"EOH";
<div class="cmdnumero_box">
	<div class=" cmdnumero_box_elt">
		<span class="cmdnumero_box_status">
			$status_name
		</span>
	</div>
	
	<div class=" cmdnumero_box_elt ">
		<span class="cmdnumero_box_number">
			$id
		</span>

		<span class="cmdnumero_box_date">
			$date
		</span>
	</div>
	

	<a href="$config{fullurl}/$sitetxt{eshop_url_facture_pro_forma}/$order{token}" target="_blank" 
	class="cmdnumero_box_date_commande btn btn-default">
		Commande
	</a>

EOH

  if($order{invoice_num_handmade} > 0)
  {
	$info .= <<"EOH";
	<a class=" btn  btn-default " 
	href="$config{baseurl}/cgi-bin/eshop.pl?sw=get_facture&token=$order{token}&type=facture">
	Facture <b>$order{invoice_num_handmade}</b>
	</a>
EOH
  }
  elsif($order{invoice_num} > 0)
  {
  	$info .= <<"EOH";
	<a class=" btn  btn-default " 
	href="$config{baseurl}/cgi-bin/eshop.pl?sw=get_facture&token=$order{token}&type=facture">
	Facture <b>$order{invoice_num}</b>
	</a>
EOH
  }

  
  if($order{invoice_nc_handmade} > 0)
  {
  $info .= <<"EOH";
	<a class=" btn   btn-default " 
	href="$config{baseurl}/cgi-bin/eshop.pl?sw=get_facture&token=$order{token}&type=note" >
	N.C. <b>$order{invoice_nc_handmade}</b>
	</a>
EOH
	}
	elsif($order{invoice_nc} > 0)
  {
  $info .= <<"EOH";
	<a class=" btn   btn-default " 
	href="$config{baseurl}/cgi-bin/eshop.pl?sw=get_facture&token=$order{token}&type=note" >
	N.C. <b>$order{invoice_nc}</b>
	</a>
EOH
	}

  $info .= <<"EOH";  
  </div>
EOH
  return $info; 
}

sub get_livraison
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  my %order = sql_line({table=>"eshop_orders",where=>"id='$id'"});
	my %delivery = sql_line({table=>'eshop_deliveries',where=>"name='$order{delivery}'"});
	my %country = sql_line({table=>'countries',where=>"id='$order{delivery_country}'"});
	my ($nom_methode_livraison,$dum) = get_textcontent($dbh,$delivery{id_textid_name});
	
	$nom_methode_livraison = remove_accents_from($nom_methode_livraison);
	$nom_methode_livraison = uc($nom_methode_livraison);

  my $info = '';
  
  if($order{delivery_company} ne '')
  {
    $info .= '<b>'..'</b>, ';
  }
  $info .= "<b></b>";
  $info .= "<br>";
  $info .= "<br>";
  $info .= '<br><i class="fa fa-phone"></i>'.$order{delivery_phone}.'<i class="fa fa-email"></i><a href="mailto:'.$order{delivery_email}.'">'.$order{delivery_email}.'</a>';

  

  
  # return '<span class="label label-primary">'.$traduit.'</span>'.'<br/>'.$info; 
  $nom_methode_livraison = trim($nom_methode_livraison);
my $case = <<"EOH";  
  <div class="cmdnumero_box">
	<div class=" cmdnumero_box_elt">
		<span class="cmdnumero_box_methode_livraison">$nom_methode_livraison
		</span>
	</div>
	
	<div class=" cmdnumero_box_elt ">
		<span class="cmdnumero_box_name">
			$order{delivery_firstname} $order{delivery_lastname} $order{delivery_company}
		</span>
	</div>
	<div class=" cmdnumero_box_elt ">
		<span class="cmdnumero_box_adres">
			$order{delivery_street} $order{delivery_number} $order{delivery_box} - $order{delivery_zip} $order{delivery_city} $country{fr}
		</span>
	</div>
	<div class=" cmdnumero_box_elt ">	
		<span class="cmdnumero_box_phone">
			<i class="fa fa-phone"></i>&nbsp;&nbsp;<a href="tel:$order{delivery_phone}">$order{delivery_phone}</a><br />@&nbsp;&nbsp;<a href="mailto:$order{delivery_email}">$order{delivery_email}</a>
		</span>
	</div>
   </div>
EOH

	return $case;
  
}

sub get_remarque
{
	my $dbh = $_[0];
	my $id = $_[1];
	my %order = sql_line({table=>"eshop_orders",where=>"id='$id'"});

	if($order{do_fact} eq 'y')
	{
		$$order{commentaire}='<b>Le client souhaite une facture</b><br />'.$order{commentaire};  
	}
	return $order{commentaire};
}

sub get_payment
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %order = sql_line({table=>"eshop_orders",where=>"id='$id'"});
  my $color = '#ff0000';
  
   if($order{payment_status} eq 'paid' || $order{payment_status} eq 'captured')
  {
    $color = 'green';
  }
 
  my $donnees = '';
  my %eshop_payment = sql_line({table=>'eshop_payments',where=>"name='$order{payment}'"});
  my ($moyen_paiement,$dum) = get_textcontent($dbh,$eshop_payment{id_textid_name});

   # $donnees .= '<span class="label label-primary" style="background-color:'.$color.'">'.$traduit.'</span><br/>';

  
  my $prix = display_price($order{total_discounted_tvac});
  $donnees .= 'Total TTC: <b style="color:black">'.$prix.'</b><br>';
  my $coupon='';
  my $remise='';

      
	if(0 || $order{coupon_txt} ne '')
	{
		# my %eshop_order_coupons = sql_line({table=>'eshop_order_coupons',where=>"id_eshop_order='$order{id}'"});
		$coupon = " | Coupon: <i>$order{coupon_txt}</i><br />";  
	}
	if(0 || $order{total_discount_tvac}>0)
	{
		$order{total_discount_tvac} = display_price($order{total_discount_tvac});
		$remise = " | Remise: $order{total_discount_tvac}<br />";
	} 


 
  


  
  # $donnees .= $coupon.$remise;
  # $order{total_delivery_tvac} = display_price($order{total_delivery_tvac});

  # $donnees .= <<"EOH";  
    # Dont frais de port: $order{total_delivery_tvac}</span>
# EOH
   $donnees .= <<"EOH";  
    <br>Moyen de paiement: $moyen_paiement<br>
EOH
  $donnees .= <<"EOH";  
   Statut de paiement: <span style="color:$color">$payment_status_conv{$order{payment_status}}</span>
EOH


 
	my $do_fact = '';
	if($order{do_fact} eq 'y')
	{
		$do_fact='<br/><span class="badge">Le client souhaite une facture</span>';  
	}
	$donnees .= $do_fact;
	
	# return $donnees;
	
	
	# $moyen_paiement = uc($moyen_paiement);
	$moyen_paiement = trim($moyen_paiement);
	
my $case = <<"EOH";  
  <div class="cmdnumero_box">
	<div class=" cmdnumero_box_elt">
		<span class="cmdnumero_box_methode_livraison" style="color:$color!important;">
			$payment_status_conv{$order{payment_status}}
		</span>
	</div>
	
	<div class=" cmdnumero_box_elt ">
		<span class="cmdnumero_box_name">
			$prix TTC
		</span>
		<span class="cmdnumero_box_remise">
			$coupon $remise
		</span>
	</div>
	<div class=" cmdnumero_box_elt ">
		<span class="cmdnumero_box_adres">
			$moyen_paiement
		</span>
	</div>
   </div>
EOH

	return $case;

}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_infos
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  my %order = sql_line({table=>"eshop_orders",where=>"id='$id'"});
  
  
  # my $envoi = '';
  # if($order{email_sent} == 1)
  # {
     # $envoi = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Email de confirmation envoyé" style="color:green"><i class="fa fa-envelope fa-stack-1x"></i></a>';
  # }
  # else
  # {
     # $envoi = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Email de confirmation non envoyé"><i class="fa fa-envelope fa-stack-1x"></i></a>';
  # }

  # my $envoi_livraison;
  # if($order{email_delivery_sent} eq "y")
  # {
     # $envoi_livraison = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Email de livraison envoyé" style="color:green"><i class="fa fa-truck fa-stack-1x"></i></a>';
  # }
  # else
  # {
     # $envoi_livraison = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Email de livraison non envoyé"><i class="fa fa-truck fa-stack-1x"></i></a>';
  # }

  # my $envoi_facture;
  # if($order{email_billing_sent} eq "y")
  # {
     # $envoi_facture = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Facture envoyée" style="color:green"><i class="fa fa-file-text fa-stack-1x"></i></a>';
  # }
  # else
  # {
     # $envoi_facture = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Facture non envoyée"><i class="fa fa-file-text fa-stack-1x"></i></a>';
  # }

  # my $envoi_facture_pdf;
  # if($order{email_facture_pdf_sent} eq "y")
  # {
     # $envoi_facture_pdf = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Facture PDF envoyée" style="color:green"><i class="fa fa-file-pdf-o fa-stack-1x"></i></a>';
  # }
  # else
  # {
     # $envoi_facture_pdf = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Facture PDF non envoyée"><i class="fa fa-file-pdf-o fa-stack-1x"></i></a>';
  # }

  # my $envoi_finished;
  # if($order{email_finished_sent} eq "y")
  # {
     # $envoi_finished = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Email de remerciement envoyé" style="color:green"><i class="fa fa-check-square fa-stack-1x"></i></a>';
  # }
  # else
  # {
     # $envoi_finished = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Email de remerciement non envoyé"><i class="fa fa-check-square fa-stack-1x"></i></a>';
  # }

  # my $stock = '';
  # if($order{stock_updated} == 1)
  # {
     # $stock = '<span class="fa-stack " title="Stock mis à jour" style="color:green"><i class="fa fa-cubes fa-stack-1x"></i></a>';
  # }
  # else
  # {
     # $stock = '<span class="fa-stack " title="Stock pas mis à jour"><i class="fa fa-cubes fa-stack-1x"></i></a>';
  # }
  # my $ptr = '';
  # if($order{post_order_ok} eq 'y')
  # {
     # $ptr = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Traitement après commande appelé" style="color:green"><i class="fa fa-gears fa-stack-1x" ></i></a>';
  # }
  # else
  # {
     # $ptr = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Traitement après commande pas appelé"><i class="fa fa-gears fa-stack-1x"></i></a>';
  # }
  # my $coupon='';
  # my $remise='';
  # my $do_fact='';
      
# if($order{total_coupons_tvac}>0)
# {
    # my %eshop_order_coupons = sql_line({table=>'eshop_order_coupons',where=>"id_eshop_order='$order{id}'"});
    # $coupon="<br/>$eshop_order_coupons{coupon_reference} ($eshop_order_coupons{coupon_value}€)";  
# }
# if($order{total_discount_tvac}>0)
# {
    # $order{total_discount_tvac} = display_price($order{total_discount_tvac});
    # $remise="<br/>Remise: $order{total_discount_tvac}";
# }  

  
  # my $ext_id = '';
  
  # if($order{ext_id} > 0)
  # {
	# $ext_id = $order{ext_id};
	# if($order{ext_id} < 10)
	# {
		# $ext_id = '0'.$order{ext_id};
	# }
  # }
  # else
  # {
	# $ext_id = '';
  # }
  
  
  # return <<"EOH";
    # $envoi $envoi_facture $envoi_facture_pdf $envoi_livraison $envoi_finished $stock $ptr $remise <span style="color:blue">$ext_id</span> 
# EOH
}

sub custom_icons
{
	my $id = $_[0];
	my $colg = $_[1];
	my %order = %{$_[2]};
	
	
	 my $envoi = '';
  if($order{email_sent} == 1)
  {
     $envoi = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Email de confirmation envoyé" style="color:green"><i class="fa fa-envelope fa-stack-1x"></i></a>';
  }
  else
  {
     $envoi = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Email de confirmation non envoyé"><i class="fa fa-envelope fa-stack-1x"></i></a>';
  }

  my $envoi_livraison;
  if($order{email_delivery_sent} eq "y")
  {
     $envoi_livraison = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Email de livraison envoyé" style="color:green"><i class="fa fa-truck fa-stack-1x"></i></a>';
  }
  else
  {
     $envoi_livraison = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Email de livraison non envoyé"><i class="fa fa-truck fa-stack-1x"></i></a>';
  }

  my $envoi_facture;
  if($order{email_billing_sent} eq "y")
  {
     $envoi_facture = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Facture envoyée" style="color:green"><i class="fa fa-file-text fa-stack-1x"></i></a>';
  }
  else
  {
     $envoi_facture = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Facture non envoyée"><i class="fa fa-file-text fa-stack-1x"></i></a>';
  }

  my $envoi_facture_pdf;
  if($order{email_facture_pdf_sent} eq "y")
  {
     $envoi_facture_pdf = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Facture PDF envoyée" style="color:green"><i class="fa fa-file-pdf-o fa-stack-1x"></i></a>';
  }
  else
  {
     $envoi_facture_pdf = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Facture PDF non envoyée"><i class="fa fa-file-pdf-o fa-stack-1x"></i></a>';
  }

  my $envoi_finished;
  if($order{email_finished_sent} eq "y")
  {
     $envoi_finished = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Email de remerciement envoyé" style="color:green"><i class="fa fa-check-square fa-stack-1x"></i></a>';
  }
  else
  {
     $envoi_finished = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Email de remerciement non envoyé"><i class="fa fa-check-square fa-stack-1x"></i></a>';
  }

  my $stock = '';
  if($order{stock_updated} == 1)
  {
     $stock = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Stock mis à jour" style="color:green"><i class="fa fa-cubes fa-stack-1x"></i></a>';
  }
  else
  {
     $stock = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Stock pas mis à jour"><i class="fa fa-cubes fa-stack-1x"></i></a>';
  }
  my $ptr = '';
  if($order{post_order_ok} eq 'y')
  {
     $ptr = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Traitement après commande appelé" style="color:green"><i class="fa fa-gears fa-stack-1x" ></i></a>';
  }
  else
  {
     $ptr = '<a class="fa-stack disabled" disabled data-placement="bottom" data-original-title="Traitement après commande pas appelé"><i class="fa fa-gears fa-stack-1x"></i></a>';
  }
  my $coupon='';
  my $remise='';
  my $fp='';
  my $do_fact='';
      
if( $order{coupon_txt} ne '')
{
    # my %eshop_order_coupons = sql_line({table=>'eshop_order_coupons',where=>"id_eshop_order='$order{id}'"});
    $coupon="<br/> $order{coupon_txt}";  
}
if($order{total_discount_tvac}>0)
{
    $order{total_discount_tvac} = display_price($order{total_discount_tvac});
    $remise="<br/>Remise: $order{total_discount_tvac}";
}  
if($order{total_delivery_tvac}>0)
{
    $order{total_delivery_tvac} = display_price($order{total_delivery_tvac});
    #$fp="<br/>Frais de port: $order{total_delivery_tvac}";
}  


  my $ext_id = '';
  
  if($order{ext_id} > 0)
  {
	$ext_id = $order{ext_id};
	if($order{ext_id} < 10)
	{
		$ext_id = '0'.$order{ext_id};
	}
  }
  else
  {
	$ext_id = '';
  }
  
  
  return <<"EOH";
  <br /> <br />$envoi $envoi_facture $envoi_facture_pdf $envoi_livraison $envoi_finished $stock $ptr $remise $fp <span style="color:blue">$ext_id</span> 
EOH
		
	
}

sub dashboard_nombre_commandes
{
	my %rec = sql_line({table=>'eshop_orders',select=>"COUNT(*) as nb",where=>"payment_status = 'paid'"});
	

	print <<"EOH";
	<h1 class="" style="margin-top:0px;"><i class="fa fa-shopping-basket" aria-hidden="true"></i> <strong class="pull-right">$rec{nb}</strong></h1>
	<h4 class="" style="margin-bottom:0px;">Nombre de commandes</h4>	
EOH
	exit;
}

sub dashboard_nombre_clients
{
	my %rec = sql_line({table=>'eshop_orders',select=>"COUNT(DISTINCT(billing_email)) as nb",where=>"billing_email != '' AND payment_status = 'paid'"});

	print <<"EOH";
	<h1 class="" style="margin-top:0px;"><i class="fa fa-users" aria-hidden="true"></i> <strong class="pull-right">$rec{nb}</strong></h1>
	<h4 class="" style="margin-bottom:0px;">Nombre d'acheteurs</h4>	
EOH
	exit;
}

sub dashboard_chiffre_affaire
{
# 	my %rec = sql_line({table=>'eshop_orders',select=>"SUM(total_discounted_tvac) as nb",where=>"payment_status = 'paid'"});
# 	use Number::Format 'format_number';
# 	$nb = format_number($rec{nb});
# 	$nb =~ s/\,/ /g;
# 	$nb =~ s/\./\,/g;
	
# 	print <<"EOH";
# 	<h1 class="" style="margin-top:0px;"><i class="fa fa-line-chart" aria-hidden="true"></i> <strong class="pull-right">$nb €</strong></h1>
# 	<h4 class="" style="margin-bottom:0px;">Total des ventes</h4>
# EOH
# 	exit;
}



sub dashboard_soldes_box
{
	my %setup = sql_line({table=>"eshop_setup"});
	my $debut = to_ddmmyyyy($setup{soldes_debut1});
	my $fin = to_ddmmyyyy($setup{soldes_fin1});
	if($debut eq '00/00/0000')
	{
		$debut = '';
	}
	if($fin eq '00/00/0000')
	{
		$fin = '';
	}
	print <<"EOH";
	<form method="post">
	<h2>Soldes</h2>
Début des prix barrés à 0h01 le:
<div class="input-group">
	<span class="input-group-addon"><i class="fa fa-calendar"></i></span>
	<input autocomplete="off" type="text" data-domask="99/99/9999" name="soldes_debut1" value="$debut" id="soldes_debut1" class="form-control edit_datepicker"  placeholder="" />
</div>
Fin des prix barrés à 0h01 le:
<div class="input-group">
	<span class="input-group-addon"><i class="fa fa-calendar"></i></span>
	<input autocomplete="off" type="text" data-domask="99/99/9999" name="soldes_fin1" value="$fin" id="soldes_fin1" class="form-control edit_datepicker"  placeholder="" />
</div>
<i class="fa fa-info"></i> Le reste du temps, les prix réduits seront affichés sous forme de prix ronds.
<script type="text/javascript">
jQuery(document).ready(function() 
{
	 jQuery('.edit_datepicker').datepicker({
			format: "dd/mm/yyyy",
			weekStart: 1,
			todayBtn: "linked",
			language: "fr",
			keyboardNavigation: false,
			todayHighlight: true,
			autoclose:true
		});
		var url = 'adm_eshop_orders.pl?';
		
		jQuery("#soldes_debut1,#soldes_fin1").change(function()
		{
			jQuery.ajax(
			{
			   type: "POST",
			   url: url,
			   data: "sw=dashboard_soldes_box_db&d="+jQuery('#soldes_debut1').val()+"&f="+jQuery('#soldes_fin1').val(),
			   success: function(msg)
			   {
					jQuery.bootstrapGrowl('<h4><i class="fa fa-check"></i> Dates sauvegardées</h4>', { type: 'success',align: 'center',
                     width: 'auto',offset: {from: 'top', amount: 20}, delay: 1000});
			   }
			});		
		});
		
});
</script>

	
	</form>
EOH
	exit;
}

sub dashboard_soldes_box_db
{
	see();
	my $debut = get_quoted('d');
	my $fin = get_quoted('f');
	$debut = to_sql_date($debut);
	$fin = to_sql_date($fin);
	
	$stmt = "UPDATE eshop_setup SET soldes_debut1 = '$debut', soldes_fin1 = '$fin'  ";
	execstmt($dbh,$stmt);	
	exit;
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------