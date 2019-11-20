#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use sitetxt;
use migcrender;
use Data::Dumper;
use members;

use Digest::MD5::File qw(dir_md5_hex file_md5_hex url_md5_hex);
use File::Copy::Vigilant qw(copy move);




my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}
my $lg=$config{current_language} = get_quoted('lg') || 1;
my %check_language = read_table($dbh,"migcms_languages",$config{current_language});
if($check_language{visible} ne 'y')
{
    $config{current_language} = $lg = 1;
}
%sitetxt = %{get_sitetxt($dbh,$config{current_language})};
$extlink = get_quoted('extlink') || $cfg{extlink};
$cgi->param(extlink,$extlink); 

my $sw = get_quoted('sw') || "form";
if ($config{current_language} eq "") {$config{current_language} = $config{default_language};}

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

my $id_form = get_quoted('id_form');

if ($id_form eq "" || $id_form !~ /^\d+$/) 
{
	 see();
	 print "id form manquant ($id_form)";
	 exit;
}

# my $self = "$htaccess_protocol_rewrite://".$config{rewrite_default_url}."/cgi-bin/forms.pl?&amp;lg=$config{current_language}&amp;extlink=$extlink&id_form=$id_form";
my $self = "/cgi-bin/forms.pl?&amp;lg=$config{current_language}&amp;extlink=$extlink&id_form=$id_form";

&$sw();

################################################################################
#form
################################################################################
sub form
{
    see();
    
    my $step = get_quoted('step') || 1;
    my $token = get_quoted('token') || '';
    my $id_form = get_quoted('id_form') || 0;
    
    
    if($id_form > 0 && ($step > 0  || $step eq 'end'))
    {
        my ($form_name,$page,$id_template_page) = forms::form_get(
        {
            id_form => $id_form,
            token => $token,
            step  => $step,
        });
        display($page,$id_template_page);
    }
    else
    {
        print "erreur valeur de donnees: $id_form, $step";
    }
    
}

#*******************************************************************************
#form_db
#*******************************************************************************
sub form_db
{
#   see();  
    my $token = get_quoted('token');
    my $id_form = get_quoted('id_form');
    my $step = get_quoted('step');

    my %form = sql_line({
      dbh   =>$dbh,
      table =>"forms",
      where =>"id = $id_form",
    });

    #####################################
    ### Vérification Recaptcha Google ###
    ##################################### 
    # Si la vérification captcha est activée, on check si c'est un humain
    if($form{captcha_active} eq "y")
    {
      my $secret_key = $config{captcha_secret_key} || "6LebNAATAAAAABrhItqdIIU_Gt3DPMtUYVrPivSv";
      my $i_am_human = tools::is_human_recaptcha({g_recaptcha_response=>get_quoted("g-recaptcha-response"), secret_key=>$secret_key});
      if($i_am_human ne "y")
      {
        my $alert = tools::get_alert({type=>"error",display=>'sweet',title=>$sitetxt{captcha_error_title}, message=>$sitetxt{captcha_error_message}});

        see();
        print $alert;
        exit;
      }
    }
    
    my %form_data = sql_line({dbh=>$dbh,table=>"forms_data",select=>"",where=>"token='$token'",debug=>0});
    if(!($form_data{id}>0))
    {
        $token = create_token(100);
        
        my %new_form_data = ();
        $new_form_data{token} = $token;
        $new_form_data{moment} = 'NOW()';
        $new_form_data{id_form} = $id_form;
        $form_data{id} = inserth_db($dbh,"forms_data",\%new_form_data);
        $form_data{token} = $token;
    }
    else
    {
    }
    if(!($form_data{id}>0 && $step > 0))
    {
#         see();
#         print "id form manquant ($form_data{id} ou étape erronée ($step)";
#         cgi_redirect("$self");
    }
    my @fields = sql_lines({table=>'forms_fields',where=>"step = '$step' AND id_form = $id_form"});
    my %update_data = ();
    foreach $field (@fields)
    {
        my %field = %{$field};
        $update_data{'f'.$field{ordby}} = get_quoted('field_'.$field{id});
        $update_data{'f'.$field{ordby}} =~ s/\n/<br>/g;
        
        my $file_to_upload = $cgi->param('field_'.$field{id});
        
        $update_data{'f'.$field{ordby}.'v'} = $update_data{'f'.$field{ordby}};
        if($field{type} eq 'listbox' || $field{type} eq 'radio')
        {
           my $id = $update_data{'f'.$field{ordby}};
           my %listvalue =  sql_line({table=>'forms_fields_listvalues',where=>"id = '$id'",debug=>0});
           my ($value_name,$dum) = get_textcontent($dbh,$listvalue{id_textid_name});
           $update_data{'f'.$field{ordby}} = $value_name;
           $update_data{'f'.$field{ordby}} =~ s/\'/\\\'/g;
        }
        
        if($field{type} eq 'file' && $update_data{'f'.$field{ordby}} ne '')
        {
          my ($fileurl,$size) = upload_file($file_to_upload,'../usr/');
          $update_data{'f'.$field{ordby}} = $fileurl;
        } 
    }
    $update_data{id_language} = get_quoted("lg") || 1;
    updateh_db($dbh,"forms_data",\%update_data,'id',$form_data{id});
    $step++;
    
    if($step > $form{nb_steps})
    {
        $step = 'end';
        my $receive_copy = get_quoted('receive_copy') || 'n';



        ######################
        ### Envoie du mail ###
        ######################
        if($form{custom_email_form_func} ne "")
        {
          $fct = 'def_handmade::'.$form{custom_email_form_func};
          &$fct({id_form=>$form{id}, id_form_data=>$form_data{id}});
        }
        else
        {
          send_email_confirmation({receive_copy=>$receive_copy,token=>$token,form=>\%form});                    
        }


        
        ##########################################
        ### Création d'une sheet d'un annuaire ###
        ##########################################
        if($form{link_to_data_family} > 0)
        {
          link_to_data_family({id_form_data=>$form_data{id}, id_form=>$id_form});                   
        }


        
        ############################
        ### Création d'un membre ###
        ############################
        if($form{member_create_disabled} ne "y")
        {
          # On récupère le contenu du formulaire
          my %form_data = sql_line({dbh=>$dbh, table=>"forms_data", where=>"id = $form_data{id}"});  

          # Récupération des champs du formulaire
          my @form_fields = sql_lines({table=>"forms_fields",where=>"id_form='$form{id}'",debug=>0}); 

          # Récupération des champs du module membre
          my @champs_member = @{members::member_signup_fields()};
          # On parcourt tous les champs disponibles pour la création d'un membre
          my %new_member = ();
          foreach my $champ_member (@champs_member)
          {
            %champ_member = %{$champ_member};

            my $name_without_delivery = $champ_member{name};
            $name_without_delivery =~ s/delivery_//g;

            # On parcourt les champs du formulaires
            foreach $form_field (@form_fields)
            {
              # Si pour le formulaire, il y a un champ renseigné correspondant à
              if($form{"id_field_".$name_without_delivery."_exp"} > 0)
              {
                my %form_field = %{$form_field};

                if($form{"id_field_".$name_without_delivery."_exp"} == $form_field{id})
                {
                  $new_member{$champ_member{name}} = $form_data{"f".$form_field{ordby}};
                  last;
                 
                }            
              }
            }            
          }

          my %test_member = sql_line({table=>'migcms_members',where=>"email != '' AND email = '$new_member{email}'"});
          # S'il n'y a pas de membre existant
          if(!($test_member{id} > 0) && $new_member{email} ne "")
          {
            $new_member{tags} = $lg.',102,2002,';
            $new_member{id_language} = $lg;
            $new_member{email_optin} = "y";

            ### Ajout du membre ###
            $new_member{id} = inserth_db($dbh,"migcms_members",\%new_member);

            members::member_add_event({member=>\%new_member,type=>'signup_insert',name=>"Création du membre via le formulaire de contact",detail=>'',erreur=>''});
          }
    		}
        ############################################################
        ### Fonction sur-mesure d'après soumission du formulaire ###
        ############################################################
        if($form{post_forms_func} ne "")
        {
          # On récupère le contenu du formulaire
          my %form_data = sql_line({dbh=>$dbh, table=>"forms_data", where=>"token = '$token' AND token != ''"});  


          my $func = 'def_handmade::'.$form{post_forms_func};
          &$func(\%form,\%form_data,$lg);
        }
	   }	


 

  cgi_redirect("$self&step=$step&token=$token&id_form=$id_form");


}


################################################################################
# link_to_data_family
################################################################################
sub link_to_data_family
{
  my %d = %{$_[0]};

  my %form = sql_line({dbh=>$dbh, table=>"forms", where=>"id = $d{id_form}"});
  my %form_data = sql_line({dbh=>$dbh, table=>"forms_data", where=>"id = $d{id_form_data}"});

  my %data_family = sql_line({table=>"data_families", where=>"id = '$form{link_to_data_family}'"});

  #data sheet: destination
  my %copy_data_sheet = ();

  # On créée la sheet sans les données
  my %max_ordby = sql_line({dbh=>$dbh, select=>"MAX(ordby) as max_ordby", table=>"data_sheets", where=>"id_data_family = '$copy_data_sheet{id_data_family}'"});
  if($max_ordby{max_ordby} > 0)
  {
    $copy_data_sheet{ordby} = $max_ordby{max_ordby} + 1;
  }
  else
  {
    $copy_data_sheet{ordby} = 1;
  }

  my $id_member = members::get_id_member();

  $copy_data_sheet{id_data_family}       = $form{link_to_data_family};
  $copy_data_sheet{f70}                  = $form_data{id};
  $copy_data_sheet{visible}              = 'n';
  $copy_data_sheet{id_member}            = $id_member;
  $copy_data_sheet{migcms_moment_create} = 'NOW()';


  $copy_data_sheet{id} = sql_set_data({
    dbh => $dbh,
    table => 'data_sheets',
    data => \%copy_data_sheet,
    where => "f70='$copy_data_sheet{f70}' AND id_data_family = '$copy_data_sheet{id_data_family}'",
  });

  my @languages = sql_lines({table=>"migcms_languages", where=>"visible='y' OR encode_ok = 'y'"});
  
  # Champs à copier forms_fields -> data_fields
  my @all_forms_fields = sql_lines({debug=>0,debug_results=>0,table=>'forms_fields',where=>"id_form='$form{id}'"});
  foreach $one_form_field(@all_forms_fields)
  {
    #champ form: source
    my %one_form_field = %{$one_form_field};

    # Si le champ est lié à un champ de l'annuaire
    if($one_form_field{id_data_field} > 0)
    {
      #champ data: destination
      my %copy_data_field = sql_line({debug=>0,debug_results=>0,table=>'data_fields',where=>"id='$one_form_field{id_data_field}'"});

      # Si le champs de la sheet est traductible, on créé un textid
      my $value = $form_data{'f'.$one_form_field{ordby}};
      if($copy_data_field{field_type} eq "text_id" || $copy_data_field{field_type} eq "text_id_editor" || $copy_data_field{field_type} eq "textarea_id" || $copy_data_field{field_type} eq "textarea_id_editor")
      {
        # Insertion du texte dans toutes les langues
        my $id_textid;
        foreach $language (@languages)
        {
          my %language = %{$language};

          $id_textid = set_traduction({id_traduction=>$id_textid, id_language=>$language{id}, traduction=>$value});
          
        }

        $value = $id_textid;
      }
      
      #nouvelle data_sheet  
      $copy_data_sheet{'f'.$copy_data_field{ordby}} = $value;
      $copy_data_sheet{'f'.$copy_data_field{ordby}} =~ s/\'/\\\'/g;

      sql_set_data({debug=>0,dbh=>$dbh,table=>'data_sheets',data=>\%copy_data_sheet,where=>"id = '$copy_data_sheet{id}'"});
    }
    # Si le champ correspond à la catégorie de la fiche
    elsif($one_form_field{sheet_category} eq "y")
    {
      my $id_data_category = $form_data{'f'.$one_form_field{ordby}."v"};

      # Récupération de la catégorie
      my %category = sql_line({table=>"data_categories", where=>"id = '$id_data_category'"});

      if($category{id} > 0)
      {
        #------------ Liaison avec sheet et categorie ------------#
        #---------------------------------------------------------#
        my %lnk_sheets_categories = (
          id_data_sheet    => $copy_data_sheet{id},
          id_data_category => $category{id},
          id_data_family   => $copy_data_sheet{id_data_family},
          visible          => "y",
        );

        my $id_lnk_sheets_categories = sql_set_data({dbh=>$dbh, table=>"data_lnk_sheets_categories", where=>"id_data_sheet = '$copy_data_sheet{id}' AND id_data_category = '$category{id}'", data=>\%lnk_sheets_categories});

        my $stmt = <<"EOH";
          UPDATE data_sheets
          SET id_data_categories = CONCAT(id_data_categories,',$category{id},')
          WHERE id = $copy_data_sheet{id}
EOH
        execstmt($dbh, $stmt);
      }
    }
    # Si le champ correspond à une photo de la fiche
    elsif($one_form_field{sheet_pic} eq "y")
    {
      my $dir_sheet_pics = "../usr/files/SHEETS/photos/" . $copy_data_sheet{id};
      # Si le dossier photos de la sheet n'existe pas on le créé
      unless (-d $dir_sheet_pics) {mkdir($dir_sheet_pics.'/') or die ("cannot create ".$dir.": $!");}

      my $pic_name = $form_data{'f'.$one_form_field{ordby}};

      # Si la photo n'existe pas
      if(!(-e $dir_sheet_pics."/".$pic_name))
      {
        my @splitted = split(/\./,$pic_name);
        my $ext = ".". lc($splitted[$#splitted]);
        my $filename = $splitted[0];

        if($filename ne "")
        {
          # On déplace la photo dans le dossier photos de la sheet
          copy("../usr/$pic_name", $dir_sheet_pics."/".$pic_name) or die "The move operation failed: $!";

          #insert linked file in database
          my %migcms_linked_file =
          (
            file        => $pic_name,
            file_dir    => $dir_sheet_pics,
            file_path   => "",            
            moment      => 'NOW()',
            table_name  => "data_sheets",
            table_field => "photos",
            token       => $copy_data_sheet{id},
            full        => $filename,
            ext         => $ext,
            size_mini   => $data_family{mini_width},
            size_small  => $data_family{small_width},
            size_medium => $data_family{medium_width},
            size_large  => $data_family{large_width},
            size_og     => $data_family{og_width},
            visible     => "y",
          );

          sql_set_data({dbh=>$dbh,table=>"migcms_linked_files",data=>\%migcms_linked_file, where=>"file != '' AND file = '$pic_name' AND table_name = 'data_sheets' AND token = '$copy_data_sheet{id}' AND token != ''"}); 
        }
      }
    }   
      
  }

  # Une fois les photos ajoutées, on recrée les miniatures
  #boucle sur les images du paragraphes
  my @sizes = ('mini','small','medium','large','og');
  my @migcms_linked_files = sql_lines({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"ext IN ('.jpg','.jpeg','.png') AND table_name='data_sheets' AND table_field='photos' AND token='$copy_data_sheet{id}'",ordby=>'ordby'});
  foreach $migcms_linked_file (@migcms_linked_files)
  {

    #appelle la fonction de redimensionnement
    my %migcms_linked_file = %{$migcms_linked_file};
    my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
    my %params = (
      migcms_linked_file=>\%migcms_linked_file,
    );
    foreach my $size (@sizes)
    {
      $params{'size_'.$size} = $data_family{$size."_width"};
    }
    resize_pic(\%params);
  }
 
}

sub resize_pic
{
  my %d = %{$_[0]};
  my %update_migcms_linked_file = ();
  my @sizes = ('mini','small','medium','large','og');
  $update_migcms_linked_file{do_not_resize} = $d{do_not_resize};
  my $full_pic = $d{migcms_linked_file}{'full'}.$d{migcms_linked_file}{'ext'};
  foreach my $size (@sizes)
  {
    #supprimer le fichier miniature existante s'il existe
    if(trim($d{migcms_linked_file}{'name_'.$size}) ne '' && $d{migcms_linked_file}{'name_'.$size} ne '.' && $d{migcms_linked_file}{'name_'.$size} ne '..' && $d{migcms_linked_file}{'name_'.$size} ne '/')
    {
      my $existing_file_url = $d{migcms_linked_file}{file_dir}.'/'.$d{migcms_linked_file}{'name_'.$size};
      
      if(-e $existing_file_url)
      {
        unlink($existing_file_url);
        log_debug("unlink($existing_file_url)");
      }
      else
      {
        log_debug('existe pas');
      }
    }
    
    if
    (
      $d{do_not_resize} eq 'y'
    )
    {
      #ne pas redimensionner: nettoyer données existantes
      $update_migcms_linked_file{'size_'.$size} = 0;
      $update_migcms_linked_file{'width_'.$size} = 0;
      $update_migcms_linked_file{'height_'.$size} = 0;
      $update_migcms_linked_file{'name_'.$size} = '';
    }
    else
    {
      #créer une nouvelle miniature
      
      if($d{'size_'.$size} > 0)
      {
        log_debug('2size_'.$size.':'.$d{'size_'.$size});
        ($thumb,$thumb_width,$thumb_height,$full_width,$full_height) = thumbnailize($full_pic,$d{migcms_linked_file}{file_dir},$d{'size_'.$size},$d{'size_'.$size},'_'.$size);
        $update_migcms_linked_file{'size_'.$size} = $d{'size_'.$size};
        $update_migcms_linked_file{'width_'.$size} = $thumb_width;
        $update_migcms_linked_file{'height_'.$size} = $thumb_height;
        $update_migcms_linked_file{'name_'.$size} = $thumb;
      }
    }
    updateh_db($dbh,"migcms_linked_files",\%update_migcms_linked_file,'id',$d{migcms_linked_file}{id});
  }
}

################################################################################
# send_email_confirmation
################################################################################
sub send_email_confirmation
{
    my %d = %{$_[0]};
    my %form = %{$d{form}};
    my $email = ''; 
#     my $template_email_dest = get_template($dbh,$form{'id_template_email_dest'});
#     my $template_email_exp = get_template($dbh,$form{'id_template_email_exp'});
    my %form_data = sql_line({table=>"forms_data",where=>"token='$d{token}'",debug=>0});
    my @fields = sql_lines({table=>'forms_fields',where=>"id_form = $form{id}", ordby=>'ordby' });
#     AND in_list='y'
    
    $email .=<<"EOH";
    <table id="form" border="1" cellpadding="5" width="100%">
EOH
    foreach $field (@fields)
    {
        my %field = %{$field};
        my $value = $form_data{'f'.$field{ordby}};
#         if($field{type} eq 'listbox')
#         {
#             my %form_field_listvalue = sql_line({table=>"forms_fields_listvalues",where=>"id='$value'",debug=>0});
#             my ($value_name,$dum) = get_textcontent($dbh,$form_field_listvalue{id_textid_name});
#             $value = $value_name; 
#         }
        my ($libelle,$dum) = get_textcontent($dbh,$field{id_textid_name});
        
        if($field{type} eq 'file')
        {
            $value = <<"EOH";
            <a href="$config{default_fm_url}/$value">$value</a>
EOH
        }
        
        $email .=<<"EOH";
        <tr><td width="200"><strong>$libelle :</strong></td><td>$value</td></tr>   
EOH
    }
    $email .=<<"EOH";
    </table>
EOH
    
    my ($form_name,$dum) = get_textcontent($dbh,$form{id_textid_name},$lg);
    
    my ($email_administrateur,$dum) = get_textcontent($dbh,$form{id_textid_email_dest},$lg);
    if($email_administrateur eq '')
    {
       ($email_administrateur,$dum) = get_textcontent($dbh,$form{id_textid_email_dest},1);   
    }
    
    my $email_visiteur = $email_administrateur;
    my %form_field = sql_line({table=>"forms_fields",where=>"id='$form{id_field_email_exp}'",debug=>0});
    if($form_data{'f'.$form_field{ordby}} ne '')
    {
        $email_visiteur = $form_data{'f'.$form_field{ordby}};
    }
    
    if($email_administrateur ne '')
    {
        #send_mail($email_visiteur,$email_administrateur,$form_name,$email,"html");
		send_mail($email_administrateur,$email_administrateur,$form_name,$email,"html",'','','','','','','',$email_visiteur);
		
		
        if($d{receive_copy} eq 'y')
        {
            send_mail($email_administrateur,$email_visiteur,$form_name,$email,"html");
        }
    }

}
# 
# #*******************************************************************************
# #SQL_LINES
# #*******************************************************************************
# sub sql_line
# {
#     my %d = %{$_[0]};
#     $d{one_line} = 'y';
#     return sql_lines(\%d);
# }
# 

# #*****************************************************************************************
# sub sql_radios
# {
#     my %d = %{$_[0]};
#         
#     if($d{table} ne "" && $d{value} ne "" && $d{display} ne "" && $d{name} ne "")
#     {
#           my $cbs=<<"EOH";
# EOH
#           my @records=get_table($d{dbh},$d{table},$d{select},$d{where},$d{ordby},"","",$d{debug});
#           foreach my $rec (@records)
#           {
#               my $checked="";
#               if($d{current_value} eq $rec->{$d{value}})
#               {
#                   $checked=<<"EOH";
#                    checked = "checked"                
# EOH
#               }
#               $cbs.=<<"EOH";
#                 <label>   
#                   <input type="radio" name="$d{name}" $checked value="$rec->{$d{value}}" $d{required} class="$d{class}"> 
#                   $rec->{$d{display}}
#                 </label>
# EOH
#           }    
#           
#           $cbs.=<<"EOH";
# EOH
#           return $cbs;
#           exit;
#     }
#     else
#     {
#         return "missing mandatory data: [table:$d{table}][value:$d{value}][display:$d{display}][name:$d{name}]";
#     }  
# }
# #*****************************************************************************************
# sub sql_listbox
# {
#     my %d = %{$_[0]};
#     my $empty_option=<<"EOH";
#       <option value="">$d{empty_txt}</option>
# EOH
#     if($d{show_empty} ne 'y')
#     {
#         $empty_option="";
#     }
#     
#     if($d{table} ne "" && $d{value} ne "" && $d{display} ne "" && $d{name} ne "")
#     {
#           my $listbox=<<"EOH";
#               <select name="$d{name}" $d{required} id="$d{id}" class="$d{class}">
#                   $empty_option             
# EOH
#          
#           my @records=get_table($d{dbh},$d{table},$d{select},$d{where},$d{ordby},"","",$d{debug});
#           foreach my $rec (@records)
#           {
#               my $selected="";
#               if($d{current_value} eq $rec->{$d{value}})
#               {
#                   $selected=<<"EOH";
#                    selected = "selected"                
# EOH
#               }
#               $listbox.=<<"EOH";
#                   <option value="$rec->{$d{value}}" $selected>
#                     $rec->{$d{display}}
#                   </option>
# EOH
#           }    
#           
#           $listbox.=<<"EOH";
#               </select>       
# EOH
#           return $listbox;
#           exit;
#     }
#     else
#     {
#         return "missing mandatory data: [table:$d{table}][value:$d{value}][display:$d{display}][name:$d{name}]";
#     }  
# }

################################################################################
#DISPLAY
################################################################################
sub display
{
  my $content = $_[0];
  my $id_template_page = $_[1];
    
  my $template_page=migcrender::get_template($dbh,$id_template_page,$config{current_language},"","html");
  # my $page_content = get_link_canvas($dbh,$extlink,$template_page,"html",$content,$id_template_page,$config{current_language});     
  
    my $page_content = render_page({debug=>0,content=>$content,id_tpl_page=>$id_template_page,extlink=>$extlink,lg=>$config{current_language}});

  
  
  print $page_content;
}