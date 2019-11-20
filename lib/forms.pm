#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Package de la librairie
package forms;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@ISA = qw(Exporter);  #Permet l'export
@EXPORT = qw(
               form_get
            );
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use def;
use tools;
use migcrender;
use sitetxt;
use data;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


###############################################################################
# GET_DATAFORM
###############################################################################

sub form_get
{ 
    my %d = %{$_[0]};
        
    my $htaccess_ssl = $config{rewrite_ssl};
    my $htaccess_protocol_rewrite = "http";
    if($htaccess_ssl eq 'y') 
    {
        $htaccess_protocol_rewrite = "https";
    }
    my $id_form = $d{id_form};
    # my $self = "$htaccess_protocol_rewrite://".$config{rewrite_default_url}."/cgi-bin/forms.pl?&amp;lg=$config{current_language}&amp;extlink=$extlink&id_form=$id_form";
    my $self = "/cgi-bin/forms.pl?&amp;lg=$config{current_language}&amp;extlink=$extlink&id_form=$id_form";
    my ($form_name,$dum) = get_textcontent($dbh,$id_form);
    my $step = $d{step};
    my $token = $d{token} || 1;
    my $lg = $d{colg} || $lg || $config{current_language} || $config{default_language} || 1;
#     see();
#     print "$lg: $d{colg} || $lg || $config{current_language} || $config{default_language} || 1;"; 
    
    if(!($id_form>0))
    {
        print "ID formulaire non précisé";
        exit;
    }
    my %form = sql_line({debug=>0,table=>"forms",where=>"id=$id_form"});
    
    if(!($form{'id_template_page_'.$step} > 0 && $form{'id_template_formulaire_'.$step} > 0))
    {
        see();
        print "Template de page $step non configuré: ".$form{'id_template_page_'.$step};
        print "<br />ou<br />Template de formulaire $step non configuré: ".$form{'id_template_formulaire_'.$step};
#         return ('','',$form{'id_template_page_'.$step});
#         exit;
    }
    my %form_data = sql_line({table=>"forms_data",where=>"token='$token'"});
    
   
    my $tpl_formulaire = migcrender::get_template($dbh,$form{'id_template_formulaire_'.$step},$lg);
    
    my $page = $tpl_formulaire;
    $_ = $tpl_formulaire;
    
    my @balises = (/<MIGC_FIELD_INPUT_(\w+)_HERE>/g);
    foreach $balise (@balises)
    {
        my %field = sql_line({dbh=>$dbh, table=>"forms_fields", where=>"id_form=$id_form AND code='$balise'", debug=>0, debug_results=>0});
        my $balise_a_remplacer='<MIGC_FIELD_INPUT_'.$balise.'_HERE>';
        my $balise_a_remplacer2='<MIGC_FIELD_INPUT_'.lc($balise).'_HERE>';
        my $balise_a_remplacer3='<MIGC_FIELD_INPUT_'.uc($balise).'_HERE>';
        
        #VALEUR*****************************************************************
        my $valeur = "Type de champ non supporté ou ($field{type}) pour $balise OU champ non défini pour ce formulaire";
        my $required = '';
        
        if($field{mandatory} eq 'y')
        {
           $required = 'required'; 
        }
        if($field{type} eq 'text' || $field{type} =~ m/text_.*/)
        {
              my $email = '';
              if($field{type} eq 'text_email' || $field{type} eq 'text_email_confirmation')
              {
                  $email = ' email ';
              }
              my $current_value = $form_data{'f'.$field{ordby}};
              if($field{id_data_field} > 0)
              {
                  my %data_field = sql_line({table=>"data_fields",where=>"id=$field{id_data_field}"});
                  my %form_linked_sheet = %{$d{data_sheet}};

                  if($form_linked_sheet{id} > 0)
                  {
                    $current_value = data::data_get_html_object_col
                    (
                        {
                            dbh=>$dbh,
                            type=>'COL',
                            element=>$data_field{ordby},
                            precision=>'VALUE',
                            lg=>$lg,
                            sheet=>\%form_linked_sheet,
                        }
                    );
                    
                  }                
                                 
                  
              }
              $valeur = <<"EOH";
                  <input type="text" $required name="field_$field{id}" id="field_$field{id}" $required value="$current_value" class="$required $email form-control" />
EOH
        }
        elsif($field{type} eq 'textarea')
        {
             my $current_value = $form_data{'f'.$field{ordby}};
             $valeur = <<"EOH";   
                <textarea $required name="field_$field{id}" id="field_$field{id}" class="$required form-control">$current_value</textarea>
EOH
        }
        elsif($field{type} eq "file")
        {
             my $fieldname = 'field_'.$field{id};
             $valeur = <<"EOH";   
             <input type="file" id="field_$field{id}" name="field_$field{id}" class="$required $class" />
EOH
        }
        elsif($field{type} =~ m/listbox_categories/)
        {
          my $id_category_father = $field{id_data_category_father};
          my %category_father = sql_line({table=>"data_categories", where=>"id = '$id_category_father'"});
          
          $valeur = "<select id='field_$field{id}' name='field_$field{id}' class='$required form-control'>";
          $valeur .= "<option disabled></option>";
          $valeur .= data::recurse_categories($id_category_father,1,$category_father{id_data_family},'','','','',$lg); 
          $valeur .= "</select>";
        }
        elsif($field{type} =~ m/listbox/)
        {
             my $current_value = $field{'f'.$field{ordby}.'v'};

             my ($libelle,$dum) = get_textcontent($dbh,$field{id_textid_name});

             $valeur = sql_listbox(
             {
                dbh       =>  $dbh,
                name      => 'field_'.$field{id},
                select    => 'f.id as id_value,lg'.$config{current_language},
                table     => 'forms_fields_listvalues f, txtcontents txt',
                where     => "f.id_textid_name = txt.id AND id_field = $field{id}",
                ordby     => 'ordby',
                show_empty=> 'y',
                empty_txt =>  $libelle,
                value     => 'id_value',
                current_value     => $current_value,
                display    => 'lg'.$config{current_language},
                required => $required,
                id       => 'field_'.$field{id},
                class    => $required ." form-control",
                debug    => 0,
             }
            ); 
        }
        elsif($field{type} eq 'radio')
        {
            my $current_value = $form_data{'f'.$field{ordby}.'v'};
            $valeur = sql_radios(
             {
                dbh       =>  $dbh,
                name      => 'field_'.$field{id},
                select    => 'f.id as id_value,lg'.$config{current_language},
                table     => 'forms_fields_listvalues f, txtcontents txt',
                where     => "f.id_textid_name = txt.id AND id_field = $field{id}",
                ordby     => 'ordby',
                show_empty=> 'y',
                empty_txt =>  'Veuillez sélectionner',
                value     => 'id_value',
                current_value     => $current_value,
                display    =>'lg'.$config{current_language},
                required => $required,
                id       => 'field_'.$field{id},
                class    => $required ." form-control",
                debug    => 0,
             }
            );  
        }
        elsif($field{type} eq 'checkbox')
        {
            $valeur = <<"EOH";
                <input type="checkbox" name="field_$field{id}" value="y" class="" />
EOH
        }
        elsif($field{type} eq 'handmade')
        { 
          if($field{handmade_field_func} ne "")
          {
            $fct = 'def_handmade::'.$field{handmade_field_func};
            $valeur = &$fct({data_field=>\%field});                      
          }
          else
          {
            $valeur = "Pas de fonction sur-mesure renseignée";
          }
        }

        $page =~ s/$balise_a_remplacer/$valeur/g; 
        $page =~ s/$balise_a_remplacer2/$valeur/g;
        $page =~ s/$balise_a_remplacer3/$valeur/g;
        
        #TITLE******************************************************************
        my ($libelle,$dum) = get_textcontent($dbh,$field{id_textid_name});
        my $balise_a_remplacer='<MIGC_FIELD_TITLE_'.$balise.'_HERE>';
        $page =~ s/$balise_a_remplacer/$libelle/g; 
        my $balise_a_remplacer='<MIGC_FIELD_TITLE_'.uc($balise).'_HERE>';
        $page =~ s/$balise_a_remplacer/$libelle/g;
        my $balise_a_remplacer='<MIGC_FIELD_TITLE_'.lc($balise).'_HERE>';
        $page =~ s/$balise_a_remplacer/$libelle/g;
        
        #MANDATORY**************************************************************
        my $balise_a_remplacer='<MIGC_FIELD_MANDATORY_'.$balise.'_HERE>';
        my $valeur = '<span>*</span>';
        if($field{mandatory} ne 'y')
        {
           $valeur = '';
        }
        $page =~ s/$balise_a_remplacer/$valeur/g;
    }
    
    my $balise_a_remplacer='<MIGC_DATAFORM_HIDDEN_HERE>';
    my $valeur = <<"EOH";
      <input type="hidden" name="lg" value = "$lg" />
      <input type="hidden" name="extlink" value = "$extlink" />
      <input type="hidden" name="id_form" value = "$form{id}" />
      <input type="hidden" name="token" value = "$token" />
      <input type="hidden" name="step" value = "$step" />
      <input type="hidden" name="sw" value = "form_db" />
EOH
    
    $page =~ s/$balise_a_remplacer/$valeur/g;  
    
    my $balise_a_remplacer='<MIGC_DATAFORM_ACTION_HERE>';
    my $valeur = $self;
    $page =~ s/$balise_a_remplacer/$valeur/g; 
    
    my $balise_a_remplacer='<MIGC_DATAFORM_ID_HERE>';
    my $valeur = $form{id};
    $page =~ s/$balise_a_remplacer/$valeur/g; 
    
    my $balise_a_remplacer='<MIGC_FORMS_LINK_PREVIOUS_STEP_HERE>';
    my $previous_step = $step-1;
    my $valeur = <<"EOH";
     <a href="$self&step=$previous_step&token=$token" class="btn">Etape précédente</a>
EOH
    $page =~ s/$balise_a_remplacer/$valeur/g;   
    
    my $balise_a_remplacer='<MIGC_FORMS_END_TXT_HERE>';
    my ($txt,$dum) = get_textcontent($dbh,$form{id_textid_txt_confirmation});
    my $valeur = $txt;
    $page =~ s/$balise_a_remplacer/$valeur/g;       
           
    my $balise_a_remplacer='<MIGC_FORMS_CB_RECEIVE_COPY_HERE>';
    my $checked = '';
    if($form_data{receive_copy} eq 'y')
    {
        $checked = ' checked = "checked" ';
    }
    
    my $valeur = <<"EOH";
        <input type="checkbox" name="receive_copy" id="receive_copy" value="y" $checked />
EOH
    $page =~ s/$balise_a_remplacer/$valeur/g; 
    

    ############# RECAPTCHA #############
    if($form{captcha_active} eq "y")
    {

      my $lg_captcha;
      use Switch;
      switch ($lg) 
      {
        case 1 {
          $lg_captcha = "fr";
        } 
        case 2 {
          $lg_captcha = "en";
        }
        case 3 {
          $lg_captcha = "nl";
        }
        case 4 {
          $lg_captcha = "de";
        }
        case 5 {
          $lg_captcha = "it";
        }
        case 6 {
          $lg_captcha = "es";
        }
      }

      my $error_title = $sitetxt{captcha_error_title};
      my $error_message = $sitetxt{captcha_error_message};
      $error_title =~ s/\"/\\\"/g;
      $error_message =~ s/\"/\\\"/g;

      my $balise_a_remplacer = '<MIGC_FORMS_CAPTCHA_HERE>';
      my $valeur = content_balise_recaptcha();

        $page =~ s/$balise_a_remplacer/$valeur/g;
   
    }

    ############# GOOGLE ADWORDS CONVERSION #############
    if($step eq "end" && $form{google_adwords_account} ne "")
     {
      my $google_adwords_label = $form{'google_adwords_label_'.$lg};
        $page .=<<"EOH";
            <!-- Google Code for Contact formulaire Conversion Page -->
            <script type="text/javascript">
            /* <![CDATA[ */
            var google_conversion_id = $form{google_adwords_account};
            var google_conversion_language = "$form{google_adwords_code_language}";
            var google_conversion_format = "3";
            var google_conversion_color = "ffffff";
            var google_conversion_label = $google_adwords_label;
             var google_remarketing_only = false;
            /* ]]> */
            </script>
            <script type="text/javascript"  
            src="//www.googleadservices.com/pagead/conversion.js">
            </script>
            <noscript>
            <div style="display:inline;">
            <img height="1" width="1" style="border-style:none;" alt="" src="//www.googleadservices.com/pagead/conversion/$form{google_adwords_account}/?label=$google_adwords_label&amp;guid=ON&amp;script=0"/>
            </div>
            </noscript>
EOH
     }


    return ($form_name,$page,$form{'id_template_page_'.$step});
}

sub content_balise_recaptcha
{
  my $content = <<"HTML";
      <link type="text/css" rel="stylesheet" href="$config{baseurl}/mig_skin/css/sweet-alert.css">
      <script src="$config{baseurl}/mig_skin/js/sweet-alert.min.js"></script>       

        <script>

          // var captcha_public_key = "$config{captcha_public_key}";
          var doSubmit = false;

          

          function onloadCallback () 
          {
            jQuery(".g-recaptcha").each(function(i) {
              jQuery(this).attr("id","recaptcha-"+i);
            })
            
            var recaptchas = document.querySelectorAll('div[class=g-recaptcha]');

            for( i = 0; i < recaptchas.length; i++) {
                grecaptcha.render( recaptchas[i].id, {
                'sitekey' : '$config{captcha_public_key}',
                'callback': reCaptchaVerify,
                'expired-callback': reCaptchaExpired,
                });
            }
          }

          function reCaptchaVerify(response)
          {
            // On check si l'utilisateur a coché la case
            if (response !== undefined && response != "")
            {
              doSubmit = true;
            }
          }

          function reCaptchaExpired ()
          {
            // Faire quelque chose si ça expire
          }

          jQuery("#form_validate_1").on('submit',function(e)
          {
            if (doSubmit)
            {
            }
            else
            {
              sweetAlert({
                  title :"$error_title",
                  text : "$error_message",
                  type : "error",
              });
              e.preventDefault();
            }
          });
     
         
        </script>


        <script src="https://www.google.com/recaptcha/api.js?onload=onloadCallback&render=explicit" async defer></script>

        <div class="g-recaptcha"></div>
HTML

    return $content;
}
1;