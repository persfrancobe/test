#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
   

$dm_cfg{customtitle} = <<"EOH";
<a href="$config{baseurl}/cgi-bin/adm_data_families.pl?colg=$colg">$migctrad{data_title_families}</a>   
EOH
$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "eshop_tarifs";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?";

$dm_cfg{after_mod_ref} = \&up;
$dm_cfg{after_add_ref} = \&up;

$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="colg" value="$colg" />
EOH


my $id_data_family = get_quoted('id') || 0;

%dm_dfl = 
(
'01/name'=> 
{
'title'=>'Nom',
'fieldtype'=>'text',
'search' => 'y',
'mandatory'=>{"type" => 'not_empty'},
}
,
'02/id_textid_name'=> 
{
'title'=>'Libellé',
'fieldtype'=>'text_id',
'search' => 'y',
}
,
'82/has_no_prices'=> 
{
'title'=>'Pas de prix',
'fieldtype'=>'checkbox',
'checkedval' => 'y'
},
'83/is_tvac'=> 
{
'title'=>'Afficher TVAC',
'fieldtype'=>'checkbox',
}
,
'84/pay_tvac'=> 
{
'title'=>'Payer TVAC',
'fieldtype'=>'checkbox',
}
 ,
      '94/id_payment_default'=> 
      {
      'title'=>'Méthode de paiement par défaut',
           'fieldtype'=>'listboxtable',
           'lbwhere'=>"",			
           'lbtable'=>'eshop_payments',
           'lbkey'=>'id',
		   'legend'=>"",

           'lbdisplay'=>'id_textid_name',
          	'translate' => 1,
		   'multiple'=>0,
		   'summary'=>0,
      }
);

%dm_display_fields = 
(
	"01/Nom"=>"name",
  "02/Pas de prix"=>"has_no_prices",
  "03/Affichage TVAC"=>"is_tvac",
  "04/Paiement TVAC"=>"pay_tvac",
  "05/Méthode de paiement"=>"id_payment_default",
);

%dm_lnk_fields = 
    (
    );



%dm_mapping_list = (
);

sub up
{
    my $dbh=$_[0];
    my $id=$_[1];
    
}




%dm_filters = (
		);


$sw = $cgi->param('sw') || "list";

see();

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
	$migc_output{content} .= $dm_output{content};
	$migc_output{title} = $dm_output{title}.$migc_output{title};

	print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}

