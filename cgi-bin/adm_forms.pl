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


# use migccms;
use migcrender;
use Spreadsheet::ParseExcel;
use Spreadsheet::WriteExcel;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();
$colg = get_quoted('colg') || $config{default_colg};



$dm_cfg{customtitle} = $migctrad{products_management}.' > '.$migctrad{product_families_list};
$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{duplicate} = 'y';
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "forms";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{before_del_ref} = \&before_del;
$dm_cfg{table_width} = 850;
$dm_cfg{fieldset_width} = 850;
my $self=$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_forms.pl?";

$dm_cfg{after_mod_ref} = \&up;
$dm_cfg{after_add_ref} = \&up;

$dm_cfg{page_title} = 'Formulaires';
$dm_cfg{add_title} = "Ajouter un formulaire";

$config{logfile} = "trace.log";
my $id = get_quoted('id');
%etapes = (
			"1"=>"1",
			"2"=>"2",
			"3"=>"3",
			"4"=>"4",
			"5"=>"5"
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
	    }
      ,
      '06/id_textid_url_rewriting'=> 
      {
	        'title'=>"Réécriture d'URL",
	        'fieldtype'=>'text_id',
	        'fieldsize'=>'50',
	        'search' => 'y',
	        'mandatory'=>{"type" => 'not_empty'},
	    }
      ,
	    '10/id_textid_email_dest'=> 
      {'title'=>"Adresse email de l'administrateur",
       'fieldtype'=>'text_id',
       'fieldsize'=>'40',
      }
      ,
	    '11/id_field_email_exp'=> 
      {'title'=>"Champ contenant l'email du visiteur",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'forms_fields',
     'lbkey'=>'id',
     'lbdisplay'=>'code',
     'lbwhere'=>"id_form='$id'"
      }
	  ,
	    '15/link_to_newsletter_group'=> 
      {'title'=>"Lien vers le groupe newsletter",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'mailing_groups',
     'lbkey'=>'id',
     'lbdisplay'=>'title',
     'lbwhere'=>""
      }
      	  ,
	    '16/link_to_data_family'=> 
      {'title'=>"Lien vers un annuaire",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'data_families',
     'lbkey'=>'id',
     'lbdisplay'=>'CONCAT("FAMILLE ",id)',
     'lbwhere'=>""
      }
        
      ,
	    '25/nb_steps'=> {
	        'title'=>"Nb d'étapes",
	        'fieldtype'=>'listbox',
	        'fieldvalues'=>\%etapes
	        }  
    ,
	  '30/id_template_page_1' =>{
    'title'=>"ETAPE1: Template de page",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="page"'
    }  
     ,
	  '35/id_template_page_2' =>{
    'title'=>"ETAPE2: Template de page",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="page"'
    } 
     ,
	  '40/id_template_page_3' =>{
    'title'=>"ETAPE3: Template de page",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="page"'
    } 
     ,
	  '45/id_template_page_4' =>{
    'title'=>"ETAPE4: Template de page",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="page"'
    } 
     ,
	  '50/id_template_page_5' =>{
    'title'=>"ETAPE5: Template de page",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="page"'
    } 
     ,
	  '55/id_template_page_end' =>{
    'title'=>"APRES ENVOI: Template de page",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="page"'
    } 
     ,
	  '60/id_template_formulaire_1' =>{
    'title'=>"ETAPE1: Template de formulaire",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="dataform"'
    } 
    ,
	  '65/id_template_formulaire_2' =>{
    'title'=>"ETAPE2: Template de formulaire",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="dataform"'
    } 
     ,
	  '70/id_template_formulaire_3' =>{
    'title'=>"ETAPE3: Template de formulaire",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="dataform"'
    }
     ,
	  '75/id_template_formulaire_4' =>{
    'title'=>"ETAPE4: Template de formulaire",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="dataform"'
    }
     ,
	  '80/id_template_formulaire_5' =>{
    'title'=>"ETAPE5: Template de formulaire",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="dataform"'
    }
      ,
	  '85/id_template_formulaire_end' =>{
    'title'=>"PRES ENVOI: Template de formulaire",
     'fieldtype'=>'listboxtable',
     'lbtable'=>'templates',
     'lbkey'=>'templates.id',
     'lbdisplay'=>'templates.name',
     'lbwhere'=>'type="dataform"'
    }
     
      ,
	    '93/id_textid_txt_confirmation'=> {
	        'title'=>'Texte de confirmation affiché au visiteur après envoi',
	        'fieldtype'=>'textarea_id_editor',
	        'fieldparams'=>''
	    }
       ,
	    '94/post_forms_func'=> {
	        'title'=>'Fonction appelée après envoi',
	        'fieldtype'=>'text',
	        'fieldparams'=>''
	    }
	    ,
	    '95/config'=> {
	        'title'=>$migctrad{dataforms_form_config},
	        'fieldtype'=>'textarea',
	        'fieldparams'=>''
	    }
          
	);

#    ,
# 	  '15/id_template_email_dest' =>{
#     'title'=>"Email envoyé à l'administrateur",
#      'fieldtype'=>'listboxtable',
#      'lbtable'=>'templates',
#      'lbkey'=>'templates.id',
#      'lbdisplay'=>'templates.name',
#      'lbwhere'=>'type="dataform"'
#     }   
#       ,
# 	  '20/id_template_email_exp' =>{
#     'title'=>"Email envoyé au visiteur",
#      'fieldtype'=>'listboxtable',
#      'lbtable'=>'templates',
#      'lbkey'=>'templates.id',
#      'lbdisplay'=>'templates.name',
#      'lbwhere'=>'type="dataform"'
#     } 

%dm_display_fields = (
		);

%dm_lnk_fields = (
"01/Nom"=>"get_form_name*",
"02//$migctrad{dataforms_fields}"=>"$config{baseurl}/cgi-bin/adm_forms_fields.pl?colg=$colg&id_form=",
"03//$migctrad{dataforms_data_received}"=>"$config{baseurl}/cgi-bin/adm_forms_data.pl?colg=$colg&id_form="
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
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_and_check
{
	my %item; 
  my $op = $_[0];
  
	foreach $key (keys(%dm_dfl))
	{ 
		my ($num,$field) = split(/\//,$key);
		
		$item{$field} = get_quoted($field);

		 if ($dm_dfl{$key}{fieldtype} eq "text_id" || $dm_dfl{$key}{fieldtype} eq "textarea_id" || $dm_dfl{$key}{fieldtype} eq "textarea_id_editor")
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
  
  #$item{id_dataform}=$id_dataform;

 
	return (\%item);	
}

sub up
{
    my $dbh=$_[0];
    my $id=$_[1];
   
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
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub before_del
{
  my $dbh = $_[0];
  my $id = $_[1];
}


sub get_form_name
{
  my $dbh = $_[0];
  my $id = $_[1];
  my %form=read_table($dbh,"forms",$id);
  my ($traduit,$dum) = get_textcontent($dbh,$form{id_textid_name},$colg);
  return $traduit;
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------