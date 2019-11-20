#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

use Data::Dumper;
# migc modules

         # migc translations



#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{customtitle} = 'Remises sur les produits';
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 1;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "eshop_discounts";
$dm_cfg{list_table_name} = $dm_cfg{table_name};
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;

$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_eshop_discounts.pl?";
$dm_cfg{after_mod_ref} = \&after_save;

$dm_cfg{page_title} = 'Remises';
$dm_cfg{add_title} = "Ajouter une remise";

my %cible_tarifs = (
                 '1'=>'Tarif 1',
                 '2'=>'Tarif 2'
                );
my %types = (
                 'eur'=>'Remise en € TVAC',
                 'perc'=>'Remise en %'
                );                
  
$dm_cfg{hiddp}=<<"EOH";
EOH

my %data_cfg = get_hash_from_config($dbh,"data_cfg");
my %famille_par_defaut = read_table($dbh,"data_families",$data_cfg{default_family});
my $id_field_name = $famille_par_defaut{id_field_name};
my %data_field = read_table($dbh,"data_fields",$id_field_name);


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    '01/nom'=> 
      {
	        'title'=>'Nom',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
      ,
	    '02/id_tarif'=> 
      {
	        'title'=>"S'applique au tarif",
	        'fieldtype'=>'listboxtable',
	        'lbtable'=>'eshop_tarifs',
	        'lbkey'=>'id',
	        'lbdisplay'=>'name',
          'lbwhere'=>'visible="y"',
          'mandatory'=>{"type" => 'not_empty'}          
	    }
      ,
	    '03/target_all'=> 
      {
	        'title'=>"Concerne tous les produits",
	        'fieldtype'=>'checkbox',
          'checkedval'=>'y',
	    }      
      ,
	   '04/target_categories'=> 
      {
          'title'=>"Concerne seulement une catégorie",
          'fieldtype'=>'listboxtable',              
          'lbtable'=>'data_categories c',
          'lbkey'=>'c.id',
          'lbdisplay'=>'c.id_textid_name',
          'lbwhere'=>'c.id_data_family = 2',
          'translate' => 1,
      }
      ,
      '05/target_not_discounted'=> 
      {
	        'title'=>"Concerne les prix sans remise (soldes, prix ronds)",
	        'fieldtype'=>'checkbox',
          'checkedval'=>'y',
	    } 
      ,
	    '06/target_sheets'=> 
      {
	        'title'=>"Concerne seulement un produit (#ID)",
	        'fieldtype'=>'text'
	    }
      ,
      '07/discount_coupon'=> 
      {
	        'title'=>'Coupon déclencheur',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
	        'search' => 'y',
	    }
      ,
      '10/begin_date'=> 
      {
	        'title'=>'Date de début (facultatif)',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50'
	    }
      ,
      '20/end_date'=> 
      {
	        'title'=>'Date de fin (facultatif)',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50'
	    }
       ,
      '25/minimum_qty'=> 
      {
	        'title'=>'Quantité minimum dans le panier',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50'
	    }
      ,
	    '30/discount_type_on_total'=> {
	        'title'=>'Type de remise',
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%types,
          'mandatory'=>{"type" => 'not_empty'}
	        }
      ,
      '40/discount_value_on_total'=> 
      {
	        'title'=>'Valeur',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50'
	    }
	);

%dm_display_fields = 
(
	"01/Nom"=>"nom",
  "03/Valeur"=>"discount_value_on_total",
  "04/Type"=>"discount_type_on_total",
  "05/Coupon"=>"discount_coupon"
);

%dm_lnk_fields = (
"02/Conditions"=>"conditions*",
		);

%dm_mapping_list = (
"conditions"=>\&get_conditions,
);


# my %target_sheets = ();
# my @sheets = sql_lines({dbh=>$dbh,table=>"data_sheets",select=>"id,f1,f2",ordby=>'ORDER BY f1,f2'});
# foreach $sheet (@sheets)
# {
    # my %sheet = %{$sheet};
    # $target_sheets{$sheet{id}}="$sheet{f1} $sheet{f2}";
# } 

# my %liste_tarifs = ();
# my @tarifs = sql_lines({dbh=>$dbh,table=>"eshop_tarifs",select=>"",ordby=>'ORDER BY id'});
# foreach $tarif (@tarifs)
# {
    # my %tarif = %{$tarif};
    # $liste_tarifs{$tarif{id}}=$tarif{name};
# } 
         
%dm_filters = (
"2/Produit"=>
{
      'type'=>'hash',
	     'ref'=>\%target_sheets,
	     'col'=>'target_sheets'
}
,
"3/Tarif"=>
{
      'type'=>'hash',
	     'ref'=>\%liste_tarifs,
	     'col'=>'id_tarif'
}
);

$dm_cfg{help_url} = "http://www.bugiweb.com";

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

    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    
    $dm_output{content} .=<<"EOH";
    
    <script>
	jQuery(function() 
  {
		function sql_date_to_human_date(date)
    {
              var star_date_infos = String(date).split('-');
              var jour=star_date_infos[2];
              var mois=star_date_infos[1];
              var annee=star_date_infos[0];
              var date_str='';
              
              if(jour > 0 && mois > 0 && annee > 0)
              {
                  date_str=jour+'/'+mois+'/'+annee;
                  return date_str;
              }
              else
              {
                  return date;
              }
    }
    jQuery( "#field_begin_date" ).val(sql_date_to_human_date(jQuery( "#field_begin_date" ).val()));
    jQuery( "#field_end_date" ).val(sql_date_to_human_date(jQuery( "#field_end_date" ).val()));
    
    jQuery.datepicker.setDefaults( jQuery.datepicker.regional[ "" ] );
    jQuery.datepicker.regional['fr'] = {
		closeText: 'Fermer',
		prevText: '&#x3c;Préc',
		nextText: 'Suiv&#x3e;',
		currentText: 'Courant',
		monthNames: ['Janvier','Février','Mars','Avril','Mai','Juin',
		'Juillet','Août','Septembre','Octobre','Novembre','Décembre'],
		monthNamesShort: ['Jan','Fév','Mar','Avr','Mai','Jun',
		'Jul','Aoû','Sep','Oct','Nov','Déc'],
		dayNames: ['Dimanche','Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi'],
		dayNamesShort: ['Dim','Lun','Mar','Mer','Jeu','Ven','Sam'],
		dayNamesMin: ['Di','Lu','Ma','Me','Je','Ve','Sa'],
		weekHeader: 'Sm',
		dateFormat: 'dd/mm/yy',
		firstDay: 1,
		isRTL: false,
		showMonthAfterYear: false,
		yearSuffix: ''};
	  jQuery.datepicker.setDefaults(jQuery.datepicker.regional['fr']);
  
		jQuery( "#field_begin_date" ).datepicker( jQuery.datepicker.regional[ "fr" ] );
    jQuery( "#field_end_date" ).datepicker( jQuery.datepicker.regional[ "fr" ] );
	});
  
  
  
  
	</script>
    
EOH
    
    print wfw_app_layout($dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}

sub after_save
{
    my $dbh=$_[0];
    my $id=$_[1];

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
      elsif ($dm_dfl{$key}{fieldtype} eq "file")
      { 
             
             if($datadir_config{upload_path} eq "")
             {
                $datadir_config{upload_path}=$config{root_path}.'/usr/';
             }
             
             
             
             %item = %{update_file_field_admin($dbh,$field,$op,\%item,$datadir_config{upload_path})};

            
             
             if ($item{$field} eq "") {delete $item{$field};} elsif ($item{$field} eq " "){$item{$field}="";} 
      }
      elsif ($dm_dfl{$key}{fieldtype} eq "pic")
      { 
           %item = %{update_pic_field_admin($dbh,$field,$op,\%item,$datadir_config{upload_path})};
           if ($item{$field} eq "") {delete $item{$field};}
      }
      
		if (defined $dm_dfl{$key}{mandatory})
		{
			if (!check_field_value($item{$field}, $dm_dfl{$key}{mandatory}{type}, \@{$dm_dfl{$key}{mandatory}{params}}))
			{
				dm_check_error($dm_dfl{$key}{title});
			}
		}
  }

  if($item{begin_date} ne "")
  {
     my ($dd,$mm,$yyyy) = split (/\//,$item{begin_date});
     $item{begin_date} = "$yyyy-$mm-$dd";
  }
  if($item{end_date} ne "")
  {
     my ($dd,$mm,$yyyy) = split (/\//,$item{end_date});
     $item{end_date} = "$yyyy-$mm-$dd";
  }
  
#   @coupons = split(/\,/,$item{coupons});
#   foreach $coupon (@coupons)
#   {
#       my %coup = ();
#       $coup{code}=lc($coupon);
#       $coup{type}='generic';
#       $coup{visible}='y';
#       sql_update_or_insert($dbh,"coupons",\%coup,'code',$coup{code});                
#   } 

  if($item{discount_value_on_total} < 0)
  {
      $item{discount_value_on_total} *= -1;
  }
  $item{discount_coupon} = simplifier_ce_coupon($item{discount_coupon});
  my %set_coupon = 
  (
      nom => $item{discount_coupon},
      coupons => $item{discount_coupon},
      nb_uses_total => 1000000,
      nb_uses_email => 1000000,
      visible => 'y'
  );
  sql_set_data({debug=>0,dbh=>$dbh,table=>'eshop_coupons',data=>\%set_coupon,cold_id=>'id',where=>"nom ='$item{discount_coupon}' AND coupons='$item{discount_coupon}'"});
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
sub get_conditions
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  my %eshop_discount = sql_line({table=>"eshop_discounts",where=>"id='$id'"});
  my %eshop_tarif = sql_line({table=>"eshop_tarifs",where=>"id='$eshop_discount{id_tarif}'"});
  my $conditions ="";
  
  if($eshop_discount{begin_date} ne '0000-00-00')
  {
     my ($yyyy,$mm,$dd) = split(/\-/,$eshop_discount{begin_date});
     $conditions .= "A partir du $dd/$mm/$yyyy"; 
  }
  if($eshop_discount{end_date} ne '0000-00-00')
  {
     my ($yyyy,$mm,$dd) = split(/\-/,$eshop_discount{end_date});
     $conditions .= "<br />Juqu'au $dd/$mm/$yyyy"; 
  }
  if($eshop_discount{target_all} eq 'y')
  {
    $conditions .= "<br />Tous les produits"; 
  }
  elsif($eshop_discount{target_categories} > 0)
  {
      $conditions .= "<br />Tous les produits de la catégorie $eshop_discount{target_categories}";
  }
  elsif($eshop_discount{target_sheets} > 0)
  {
      my %ds = read_table($dbh,"data_sheets",$eshop_discount{target_sheets});
      $conditions .= "<br />Le produit $ds{f1}"; 
  }
  if($eshop_discount{minimum_qty} > 0)
  {
    $conditions .= "<br />A partir de $eshop_discount{minimum_qty} unités"; 
  }
  
  $conditions .="<br />TARIF: $eshop_tarif{name}";
  return $conditions;
}

sub simplifier_ce_coupon
{
    my $nom = $_[0];
    $nom =~ s/[^0-9a-zA-Z\s\-]+//g;
    return $nom;
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------