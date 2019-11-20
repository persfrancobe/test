#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

use fwlayout;
use fwlib;
# migc modules

         # migc translations


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();

my $id_member=get_quoted('id_member2');

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherep} = "id_member='$id_member'";
$dm_cfg{table_name} = "identities";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;

$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_$dm_cfg{table_name}.pl?id_member2=$id_member";
$dm_cfg{hiddp} = <<"EOH";
  <input type="hidden" name="id_member2" value="$id_member" />
EOH

$dm_cfg{duplicate}='y';


%identity_types = 
(
	'delivery'        =>"Livraison",
	'billing' =>"Facturation"
);

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    '01/profil_name'=> {
	        'title'=>$migctrad{adm_profil_name},
	       'fieldtype'=>'text',
	       'search' => 'y',
        'fieldsize'=>'40'
     
	    },
	    
	    '02/civility'=> {
	        'title'=>$migctrad{adm_civility},
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%civilities, 
	    },
	    
	    '03/lastname'=> {
	        'title'=>$migctrad{adm_lastname},
	        'fieldtype'=>'text',
	       'search' => 'y',
        'fieldsize'=>'40',
        
	    },

	    '04/firstname'=> {
	        'title'=>$migctrad{adm_firstname},
	        'fieldtype'=>'text',
	       'search' => 'y',

	    },
	    
	    '05/street'=> {
	        'title'=>$migctrad{adm_street},
	        'fieldtype'=>'text',
	       'search' => 'y',
        'fieldsize'=>'40',

	    },
	    
	    '06/number'=> {
	        'title'=>$migctrad{adm_num_box},
	        'fieldtype'=>'text',
	       'search' => 'y',
        'fieldsize'=>'40',

	    },
	    
	    '07/zip'=> {
	        'title'=>$migctrad{adm_zip},
	       'fieldtype'=>'text',
	       'search' => 'y',
        'fieldsize'=>'40',

	    },
	    
	    '08/city'=> {
	        'title'=>$migctrad{adm_city},
	        'fieldtype'=>'text',
	       'search' => 'y',
        'fieldsize'=>'40',

	    },
	    
	    '09/state'=> {
	        'title'=>$migctrad{adm_state},
	         'fieldtype'=>'text',
	       'search' => 'y',
        'fieldsize'=>'40',

	    },
	    
	    '10/country'=> {
	        'title'=>$migctrad{adm_country},
	        'fieldtype'=>'listboxtable',
	        'lbtable'=> 'countries',
          'lbkey'=> 'id',
          'lbdisplay'=> 'fr',

	    },
	    
	    '11/tel1'=> {
	        'title'=>$migctrad{adm_phone},
	         'fieldtype'=>'text',
	       'search' => 'y',
        'fieldsize'=>'40',

	    },
	    
	    
	    '12/fax'=> {
	        'title'=>$migctrad{adm_fax},
	       'fieldtype'=>'text',
	       'search' => 'y',
        'fieldsize'=>'40',

	    },
	    
	    
	    '13/email'=> {
	        'title'=>$migctrad{adm_email},
	         'fieldtype'=>'text',
	       'search' => 'y',
        'fieldsize'=>'40',

	    },
	    
	    '14/company'=> {
	        'title'=>$migctrad{adm_company},
	        'fieldtype'=>'text',
	       'search' => 'y',
        'fieldsize'=>'40',

	    },
	    
	    '15/vat'=> {
	        'title'=>$migctrad{adm_vat},
	         'fieldtype'=>'text',
	       'search' => 'y',
        'fieldsize'=>'40',

	    },
      
      '16/vat_app'=> {
	        'title'=>$migctrad{adm_vat_app},
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y',
	    },
      
      '17/newsletter'=> {
	        'title'=>$migctrad{adm_newsletter},
	        'fieldtype'=>'checkbox',
	        'checkedval' => 'y',
	    }
   
	   ,
      '20/identity_type'=> 
       {
	        'title'=>"Type de profil",
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%identity_types,
		    'mandatory'=>{"type" => 'not_empty'}    

	    }
	    
	);

	%dm_display_fields = (
		);

%dm_lnk_fields = (
    "01/$migctrad{adm_order_identities}"=>"identities*"
		);

%dm_mapping_list = (
    "identities"=>\&get_identities
);

%dm_filters = (
		);

$dm_cfg{help_url} = "http://www.bugiweb.com";

# this script's name

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
    
    my $suppl_js=<<"EOH";
   	<script type="text/javascript">
      jQuery(document).ready(function() 
      {
      
        //jQuery("#field_civility").attr("disabled","disabled");
        //jQuery("#field_country").attr("disabled","disabled");
        //jQuery("#field_newsletter").attr("disabled","disabled");
        //jQuery("#field_vat_app").attr("disabled","disabled");
       
      })
    </script> 
EOH
    
    print wfw_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}

sub get_identities
{
  my $dbh = $_[0];
  my $id = $_[1];
  
  
  # on récupère les infos du profil par défaut
  my %dlv = %{get_obj_hash_from_db($dbh,"identities",$id)};

  my $dlv_name = "Livraison:";
  if($dlv{identity_type} eq "billing")
  {
  	$dlv_name = "Facturation:";
  }

  my $class="identity_cartevisite";

  
  my $display = <<"EOH";
  <style>
.identity_cartevisite
{
background-color:white;
border:1px solid black;
color:black;
margin:6px;
padding:5px;
text-align:left;
vertical-align:top;
width:100%;
} 
.identity_cartevisite_double
{
  width:314px;
  background-color:white;
  color:black;
  padding:10px 10px;
  margin:10px;
  border:1px solid black;
  text-align:left;
  vertical-align:top;
}  
  </style>
<table><tr><td class="$class">
   <b>$dlv_name</b><br />
   $dlv{firstname} $dlv{lastname} $dlv{company} $dlv{vat}<br />
  $dlv{street} $dlv{number} $dlv{box} $dlv{zip} $dlv{city} $dlv{state} $dlv{countrycode}<br /> 
  $dlv{tel1} $dlv{tel2} <a href="mailto:$dlv{email}" title="">$dlv{email}</a> $dlv{rem}</td> 
EOH
  
  if (1) 
  {
      $display .="</tr></table>";
  } 
  else 
  {
   
  
  }
  
  
  return $display;
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
 
  if ($id_member ne "") {$item{id_member} = $id_member;}
 
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


sub after_save
{
    my $dbh=$_[0];
    my $id_rec =$_[1];
	
	my %rec = read_table($dbh,'identities',$id_rec);
	
	if($rec{token} eq '')
	{
		my $token = create_token(50);
		my $stmt = "UPDATE identities SET token='$token' WHERE id='$id_rec'";
		execstmt($dbh,$stmt);
	}
	
	if($rec{identity_type} eq 'billing')
	{
		my $stmt = "UPDATE migcms_members SET id_bill_identity='$rec{id}' WHERE id='$rec{id_member}'";
		execstmt($dbh,$stmt);
	}
	
	if($rec{identity_type} eq 'delivery')
	{
		my $stmt = "UPDATE migcms_members SET id_delivery_identity='$rec{id}' WHERE id='$rec{id_member}'";
		execstmt($dbh,$stmt);
	}
	
	
	
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------