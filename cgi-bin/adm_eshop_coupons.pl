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

$dm_cfg{customtitle} = 'Coupons';
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 1;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "eshop_coupons";
$dm_cfg{list_table_name} = $dm_cfg{table_name};
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;

$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_eshop_coupons.pl?";
$dm_cfg{after_mod_ref} = \&after_save;


my %cible_tarifs = (
                 '1'=>'Tarif 1',
                 '2'=>'Tarif 2'
                );
my %types = (
                 'eur'=>' €',
                 'perc'=>' %'
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
      '05/begin_date'=> 
      {
	        'title'=>'Date de début',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
          'data_type'=>'date',
	    }
      ,
      '06/end_date'=> 
      {
	        'title'=>'Date de fin',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
          'data_type'=>'date',
	    }
      ,
      '08/minimum'=> 
      {
	        'title'=>'Montant min.',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
          'data_type'=>'euros',
          'data_rules'=>'int,positive',          
	    }
      ,
      '09/coupons'=> 
      {
	        'title'=>'Coupons',
	        'fieldtype'=>'textarea',
	        'fieldsize'=>'50',
          'tip'=>'Entrez un ou plusieurs coupons séparés pas des espaces',
	    }
      ,
	    '10/discount_type_on_total'=> {
	        'title'=>'Type de remise',
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%types,
          'mandatory'=>{"type" => 'not_empty'}
	        }
      ,
      '12/discount_value_on_total'=> 
      {
	        'title'=>'Valeur',
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
          'data_rules'=>'float,positive',             
	    }
      ,
      '14/nb_uses_total'=> 
      {
	        'title'=>"Quantité totale",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
          'data_rules'=>'int,positive',
	    }
      ,
      '18/nb_uses_email'=> 
      {
	        'title'=>"Quantité total / pers",
	        'fieldtype'=>'text',
	        'fieldsize'=>'50',
          'data_rules'=>'int,positive',
	    }
      ,
      '19/free_ship'=> 
      {
	        'title'=>"Livraison gratuite",
	        'fieldtype'=>'checkbox',
	        'checkedval'=>'y',
	    }
		,
      '20/auto_pay'=> 
      {
	        'title'=>"Paiement automatique",
	        'fieldtype'=>'checkbox',
	        'checkedval'=>'y',
	    }
	);

%dm_display_fields = 
(
	"01/Nom"=>"nom",
  "02/Coupons"=>"coupons",
  "03/"=>"discount_value_on_total",
  "04/"=>"discount_type_on_total",
  "05/Livraison gratuite"=>"free_ship",	
);

%dm_lnk_fields = (

		);

%dm_mapping_list = (

);

%dm_filters = (
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
  
  $item{coupons} = simplifier(trim(uc($item{coupons})));

  if($item{discount_value_on_total} < 0)
  {
      $item{discount_value_on_total} *= -1;
  }
 
	return (\%item);	
}

sub simplifier
{
    my $nom = $_[0];
    $nom =~ s/[^0-9a-zA-Z\s\-]+//g;
    return $nom;
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_form
{
	my %item = %{$_[0]};
	my $form = build_form(\%dm_dfl,\%item);
	return $form;
}




#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------