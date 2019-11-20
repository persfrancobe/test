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


use migcrender;
use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Variables globales
my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();
$colg = get_quoted('colg') || $config{default_colg};


$dm_cfg{trad}             = 1;
$dm_cfg{customtitle}      = $migctrad{products_management}.' > '.$migctrad{product_families_list};
$dm_cfg{enable_search}    = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt}          = 0;
$dm_cfg{sort_opt}         = 0;
$dm_cfg{wherel}           = "";
$dm_cfg{wherep}           = "";
$dm_cfg{table_name}       = "forms";
$dm_cfg{list_table_name}  = "$dm_cfg{table_name}";
$dm_cfg{table_width}      = 850;
$dm_cfg{fieldset_width}   = 850;
my $self                  =$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_forms.pl?";



$config{logfile} = "trace.log";
my $id = get_quoted('id');
%etapes = (
			"1"=>"1",
			"2"=>"2",
			"3"=>"3",
			"4"=>"4",
			"5"=>"5"
		);


@dm_nav =
(
  {
      'tab'=>'form',
      'type'=>'tab',
      'title'=>'Formulaire',
  }
  ,
   {
      'tab'=>'integration',
      'type'=>'tab',
      'title'=>'Integration',
  } 
  ,
  {
      'tab'=>'adwords',
      'type'=>'tab',
      'title'=>'Adwords Conversion',
  } 
  ,
  {
      'tab'=>'member',
      'type'=>'tab',
      'title'=>'Création de membres',
  } 
  ,
);

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (
	    
      '05/id_textid_name'=> {
	        'title'=>$migctrad{dataforms_form_name},
	        'fieldtype'=>'text_id',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
            'tab'=>'form',
	    }
      ,
      '06/id_textid_url_rewriting'=> 
      {
	        'title'=>"Réécriture d'URL",
	        'fieldtype'=>'text_id',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
            'tab'=>'integration',

	    }
      ,
	    '10/id_textid_email_dest'=> 
      {'title'=>"Adresse email de l'administrateur",
       'fieldtype'=>'text_id',
       'fieldsize'=>'40',
       'tab'=>'form',
      }
      ,
	    '11/id_field_email_exp'=> 
      {'title'=>"Champ contenant l'email du visiteur",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'forms_fields',
     'lbkey'=>'id',
     'lbdisplay'=>'code',
     'lbwhere'=>"id_form='$id'",
     'tab'=>'integration',
      }
       ,
	  '15/id_template_email_dest' =>{
    'title'=>"Email envoyé à l'administrateur",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="dataform"',
     'tab'=>'form',
    }   
    ,
	  '20/id_template_email_exp' => 
    {
      'title'=>"Email envoyé au visiteur",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'templates',
      'lbkey'=>'templates.id',
      'lbdisplay'=>'templates.name',
      'lbwhere'=>'type="dataform"',
      'tab'=>'form',
    }   
    ,
    '22/custom_email_form_func' =>{
      'title'=>"Fonction d'email sur-mesure",
      'fieldtype'=>'text',
      'tab'=>'form',
    }   
    ,
    '23/post_forms_func'=> 
    {'title'=>"Fonction appelée après envoi",
     'fieldtype'=>'text',
     'fieldsize'=>'40',
     'tab'=>'form',
    }
    ,
    '24/link_to_data_family' =>{
      'title'=>"Liaison à un annuaire",
      'fieldtype'=>'listboxtable',
      'lbtable'=>'data_families',
       'lbkey'=>'data_families.id',
       'lbdisplay'=>'data_families.name',
       'lbwhere'=>'',
      'tab'=>'form',
    }   
    ,
    '25/nb_steps'=> {
      'title'=>"Nb d'étapes",
      'fieldtype'=>'listbox',
      'fieldvalues'=>\%etapes,
      'tab'=>'integration',
    }  
    ,
	  '30/id_template_page_1' =>{
    'title'=>"ETAPE1: Template de page",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="page"',
     'tab'=>'integration',
    }  
     ,
	  '35/id_template_page_2' =>{
    'title'=>"ETAPE2: Template de page",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="page"',
     'tab'=>'integration',
    } 
     ,
	  '40/id_template_page_3' =>{
    'title'=>"ETAPE3: Template de page",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="page"',
     'tab'=>'integration',
    } 
     ,
	  '45/id_template_page_4' =>{
    'title'=>"ETAPE4: Template de page",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="page"',
     'tab'=>'integration',
    } 
     ,
	  '50/id_template_page_5' =>{
    'title'=>"ETAPE5: Template de page",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="page"',
     'tab'=>'integration',
    } 
     ,
	  '55/id_template_page_end' =>{
    'title'=>"APRES ENVOI: Template de page",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="page"',
     'tab'=>'integration',
    } 
     ,
	  '60/id_template_formulaire_1' =>{
    'title'=>"ETAPE1: Template de formulaire",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="dataform"',
     'tab'=>'integration',
    } 
    ,
	  '65/id_template_formulaire_2' =>{
    'title'=>"ETAPE2: Template de formulaire",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="dataform"',
     'tab'=>'integration',
    } 
     ,
	  '70/id_template_formulaire_3' =>{
    'title'=>"ETAPE3: Template de formulaire",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="dataform"',
     'tab'=>'integration',
    }
     ,
	  '75/id_template_formulaire_4' =>{
    'title'=>"ETAPE4: Template de formulaire",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="dataform"',
     'tab'=>'integration',
    }
     ,
	  '80/id_template_formulaire_5' =>{
    'title'=>"ETAPE5: Template de formulaire",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="dataform"',
     'tab'=>'integration',
    }
      ,
	  '85/id_template_formulaire_end' =>{
    'title'=>"PRES ENVOI: Template de formulaire",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="dataform"',
     'tab'=>'integration',
    }
     
    ,
    '94/id_textid_txt_confirmation'=> {
        'title'=>'Texte de confirmation affiché au visiteur après envoi',
        'fieldtype'=>'textarea_id_editor',
        'fieldparams'=>'',
        'tab'=>'form',
    }
    ,
    '95/config'=> {
        'title'=>$migctrad{dataforms_form_config},
        'fieldtype'=>'textarea',
        'fieldparams'=>'',
        'tab'=>'integration',
    },
    '98/captcha_active'=> {
      'title'=>"Activer reCaptcha",
      'fieldtype'=>'checkbox',
      'checkedval' => 'y',
      'tab'=>'integration',
  },
  ,
  '100/google_adwords_account'=> 
  {
  'title'=>"Compte Google Adwords (conversion ID)",
  'fieldtype'=>'text',
  'tab'=>'adwords',
  }
  ,
  '101/google_adwords_code_language'=> 
  {
  'title'     =>"Adwords: code language (conversion language)",
  'fieldtype' =>'text',
  'tab'       =>'adwords',
  }
  ,
  '102/google_adwords_label'=> 
  {
  'title'     =>"Adwords: campagne cible en FR (Conversion label)",
  'fieldtype' =>'text_id',
  'tab'       =>'adwords',
  }
  ,
  '110/member_create_disabled' =>
  {
    'title'      => "Désactiver la création de membre",
    'fieldtype'  => 'checkbox',
    'checkedval' => 'y',
    'tab'        => 'member',
  }
  ,
  '114/id_field_lastname_exp'=> 
  {
    'title'     =>"Champ du nom",
    'fieldtype' =>'listboxtable',
    'lbtable'   =>'forms_fields',
    'lbkey'     =>'id',
    'lbdisplay' =>'code',
    'lbwhere'   =>"id_form='$id'",
    'tab'       =>'member',
  }
  ,
  '116/id_field_firstname_exp'=> 
  {
    'title'     =>"Champ du prénom",
    'fieldtype' =>'listboxtable',
    'lbtable'   =>'forms_fields',
    'lbkey'     =>'id',
    'lbdisplay' =>'code',
    'lbwhere'   =>"id_form='$id'",
    'tab'       =>'member',
  }
  ,
  '116/id_field_phone_exp'=> 
  {
    'title'     =>"Champ du n° de tel",
    'fieldtype' =>'listboxtable',
    'lbtable'   =>'forms_fields',
    'lbkey'     =>'id',
    'lbdisplay' =>'code',
    'lbwhere'   =>"id_form='$id'",
    'tab'       =>'member',
  }
  ,
  '118/id_field_street_exp'=> 
  {
    'title'     =>"Champ de l'adresse",
    'fieldtype' =>'listboxtable',
    'lbtable'   =>'forms_fields',
    'lbkey'     =>'id',
    'lbdisplay' =>'code',
    'lbwhere'   =>"id_form='$id'",
    'tab'       =>'member',
  }
  ,
  '120/id_field_zip_exp'=> 
  {
    'title'     =>"Champ du code postal",
    'fieldtype' =>'listboxtable',
    'lbtable'   =>'forms_fields',
    'lbkey'     =>'id',
    'lbdisplay' =>'code',
    'lbwhere'   =>"id_form='$id'",
    'tab'       =>'member',
  }
  ,
  '122/id_field_city_exp'=> 
  {
    'title'     =>"Champ de la ville",
    'fieldtype' =>'listboxtable',
    'lbtable'   =>'forms_fields',
    'lbkey'     =>'id',
    'lbdisplay' =>'code',
    'lbwhere'   =>"id_form='$id'",
    'tab'       =>'member',
  }
  ,
  '124/id_field_company_exp'=> 
  {
    'title'     =>"Champ de la société",
    'fieldtype' =>'listboxtable',
    'lbtable'   =>'forms_fields',
    'lbkey'     =>'id',
    'lbdisplay' =>'code',
    'lbwhere'   =>"id_form='$id'",
    'tab'       =>'member',
  }
  ,
  '126/id_field_vat_exp'=> 
  {
    'title'     =>"Champ du n° de tva",
    'fieldtype' =>'listboxtable',
    'lbtable'   =>'forms_fields',
    'lbkey'     =>'id',
    'lbdisplay' =>'code',
    'lbwhere'   =>"id_form='$id'",
    'tab'       =>'member',
  }
  ,
);

%dm_display_fields = (
	"01/$migctrad{id_textid_name}"=>"id_textid_name",
);

%dm_lnk_fields = (

"02//$migctrad{dataforms_fields}"=>"$config{baseurl}/cgi-bin/adm_migcms_forms_fields.pl?colg=$colg&id_form=",
"03//$migctrad{dataforms_data_received}"=>"$config{baseurl}/cgi-bin/adm_migcms_forms_data.pl?colg=$colg&id_form="
		);

%dm_mapping_list = (
"get_form_name"=>\&get_form_name,
);

%dm_filters = (
		);

$dm_cfg{help_url} = "http://www.bugiweb.com";


# this script's name

$sw = $cgi->param('sw') || "list";
my $selfcolg=$self.'&sw='.$sw.'&id='.get_quoted('id');       

$dm_cfg{hiddp}=<<"EOH";
<input type="hidden" name="colg" value="$colg" />
<input type="hidden" value="$id_dataform" name="id_dataform" />
EOH

see();

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
			up
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $spec_bar = get_spec_buttonbar($sw);
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);;
}



sub get_form_name
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %form=read_table($dbh,"forms",$id);
  my ($traduit,$dum) = get_textcontent($dbh,$form{id_textid_name});
  return $traduit;
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------