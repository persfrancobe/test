#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Package de la librairie
package certigreen;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DÃÂ©finition de ce qui est public
@ISA = qw(Exporter);	#Permet l'export
#DÃÂ©finit ce qui est exportable de cette librairire
@EXPORT = qw(
                 ajax_save_date
                 delete_time_commande
                 ajax_save_time
                 ajax_save_dossier
                 login_db
                 logout_db
                 avertir_client_doc
                 
                 
                 
                 
                 get_form_line
                 get_btns_list
                 get_detail_content
                 thousands_sep 
                 detail_array_to_html_tab
                 langues_de_site
                 hash_remove_order
                 signup_db
                 get_memberes
                 get_member_box
                 get_map_search
                 lost_password_db
                 display
                  contact_db
                  sql_to_human_date
                  pageContact
				          picform_db
                  $m2
                  $devise
                  go_to_detail
                  %constantes
            );
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Librairies utilisÃÂ©es
use def;
use tools;
# use fwlib;
use Data::Dumper;
# use migctrad; 
# use migclib;
use sitetxt;
use JSON::XS;
use migcrender;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);

#use migcadm;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

if ($config{current_language} eq "") {$config{current_language} = $config{default_language};}
my $lg=$config{current_language} = get_quoted('lg') || 1;

my $self = "../cgi-bin/certigreen.pl?id_type=$id_type&lg=$lg&extlink=$extlink";
my $htaccess_protocol_rewrite = 'http';
my $full_self = "$htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/certigreen.pl?lg=$lg&extlink=$extlink";
my $self_path = "$htaccess_protocol_rewrite://$config{rewrite_default_url}";
$m2 = 'm²';
$devise = '€';

my $dbh_data = $dbh2 = $dbh;


################################################################################
# ajax_save_dossier
################################################################################
sub ajax_save_dossier       
{
    see();         
    my $token_member = get_quoted('token_member');      
    my $token_commande = get_quoted('token_commande');     
    my %commande = sql_line({dbh=>$dbh2,table=>'commandes',where=>"token='$token_commande'"});
    my %member = sql_line({dbh=>$dbh2,table=>'members',where=>"token='$token_member'"});    
    
    my %new_client = ();     
        $new_client{id_agence} = $member{id};         
        $new_client{lastname} = get_quoted('lastname'); 
        $new_client{firstname} = get_quoted('firstname'); 
        $new_client{tel} = get_quoted('tel');       
        $new_client{street} = get_quoted('street'); 
        $new_client{number} = get_quoted('number'); 
        $new_client{zip} = get_quoted('zip'); 
        $new_client{city} = get_quoted('city');   
        $new_client{email} = get_quoted('email'); 
        $new_client{token} = create_token(100); 
        
    my %new_dossier = ();
        $new_dossier{nom_dossier} = get_quoted('nomDossier');   
        
#         print Dumper(\%new_client);
#         print Dumper(\%new_dossier);
#         exit;
   
    #verification des champs vides    
    # my $champs_vide = 0;
    # while ( ($key, $value) = each(%new_client) ) {
        # if ( ($key ne 'tel') && ($value eq '') )
        # {
             # $champs_vide ++; 
        # }
    # }    
    # if ($new_dossier{nom_dossier} eq '')
    # {
        # $champs_vide ++; 
    # }
       
    #si les champs sont remplis  
    # if ($champs_vide == 0)
    # {
        #on ajout le nouveau client dans la BD
        my $id_new_client = sql_set_data({debug=>0,dbh=>$dbh2,table=>'members',data=>\%new_client});      
        
        
        $new_dossier{id_member} = $id_new_client; 
        #on ajout le nouveau client dans la BD
        sql_set_data({debug=>0,dbh=>$dbh2,table=>'commandes',data=>\%new_dossier, where=>"token='$token_commande'"});
        
        #et retourne la liste des touts les clients d'agence
        my @all_clients_intranet_factures = sql_lines({dbh=>$dbh2,debug=>0,debug_results=>0,table=>'members m, intranet_factures c',where=>"c.id_member=m.id AND m.id_member_agence='$member{id}'"});

        my %vals = ();
        my $lines_clients = '';
        #si les clients d'agence existent
        if(scalar(@all_clients_commandes) != 0)
        {
            foreach $one_client_dossier(@all_clients_commandes)
            {
               my %one_dossier = %{$one_client_dossier};
               $vals{$one_dossier{id}.'/'.$one_dossier{id}} = "<b>".$one_dossier{nom_dossier}."</b><br> <span style='font-size:12px;'>( ".$one_dossier{lastname}." ".$one_dossier{firstname}." )</span>";
            }
            $liste_clients = '<p>Sélectionnez un dossier et cliquez sur une étape suivante.</p>';
            $lines_clients = get_form_line(
                                              {
                                                  type => 'btns-group',
                                                  name =>'agence_client',
                                                  label => '',
                                                  checked_val=> $commande{id},
                                                   style=>'margin-bottom:10px; height:auto!important;',
                                                  vals => \%vals,
                                                  size_col_field => 12,
                                              }
                                          );
            $script_active = '<script> init_form(); </script>';
        }


        my @data;
        $data[0] = $liste_clients;
        $data[1] = $lines_clients;
        $data[2] = $script_active;
        print @data;
        exit;
    # }
}

################################################################################
# ajax_save_time
################################################################################
sub ajax_save_time
{
    see();
    my $token_commande = get_quoted('token_commande');
    my $id_time = get_quoted('id_time');
    my $time_val = get_quoted('time_val');

    my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});

    my $reponse = 1;

    if(($commande{id} > 0)  && ($id_time > 0))
    {
         my %update_time = ();
            $update_time{commande_time} = $time_val;

         sql_set_data({debug=>0,dbh=>$dbh2,table=>'commande_dates',data=>\%update_time,where=>"id='$id_time' AND commande_id='$commande{id}'"});
    }
    else
    {
         $reponse = 0;
    }
    print $reponse;
    exit;
}

################################################################################
# avertir_client_doc
################################################################################
sub avertir_client_doc
{
    see();
    my $id_document = get_quoted('id_doc');
    print $id_document;
    exit;
}

################################################################################
# ajax_save_date
################################################################################
sub ajax_save_date
{
    see();
    my $token_commande = get_quoted('token_commande');
    my $date_commande = get_quoted('date');

    my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});
#     my $regex_date = '^[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}$';

    if($commande{id} > 0 && ($date_commande =~ m/^[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}$/ ))
    {
        my %commande_date =(
                               commande_id => $commande{id},
                               commande_date => $date_commande,
                               commande_time => 'nimporte',
                            );

        #efface la date de cette commande si elle a été déjà enregistrée
        $stmt = "DELETE FROM commande_dates WHERE commande_id='$commande{id}' AND commande_date='$date_commande'";
        execstmt($dbh2,$stmt);

        # met une nouvelle date pour la commande
        sql_set_data({debug=>0,dbh=>$dbh2,table=>'commande_dates',data=>\%commande_date,where=>"commande_id=$commande{id} AND commande_date=$date_commande"});
    }
    else
    {
      print "data n'est pas correcte -> dd/mm/yyyy";
    }

    #TABLEAU DES DATES--------------------------------------------------------------
    my $recap_dates = '';
    my $table_days = '';
    my %noms_mois = ();
       $noms_mois{'01'} = 'janvier';
       $noms_mois{'02'} = 'février';
       $noms_mois{'03'} = 'mars';
       $noms_mois{'04'} = 'avril';
       $noms_mois{'05'} = 'mai';
       $noms_mois{'06'} = 'juin';
       $noms_mois{'07'} = 'juillet';
       $noms_mois{'08'} = 'août';
       $noms_mois{'09'} = 'septembre';
       $noms_mois{'10'} = 'octobre';
       $noms_mois{'11'} = 'novembre';
       $noms_mois{'12'} = 'décembre';

    my @dispo_dates = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'commande_dates',where=>"commande_id=$commande{id}",ordby=>"commande_date ASC"});
    if ($#dispo_dates != -1)
    {

        $recap_dates = '<p><b>RÉCAPITULATIF DE VOS DATES</b></p>';

        $table_days = '<div class="row" id="table_days_container">';
        foreach my $dispo_date (@dispo_dates)
        {
            my %dispo_date = %{$dispo_date};

            my ($jour,$mois,$annee) = split (/\//,$dispo_date{commande_date});
            my $arrange_date =  $jour." ".$noms_mois{$mois}." ".$annee;

            my $btns_time = get_form_line(
                          {
                              type => 'btns-group',
                              name =>'time_commande',
                              label =>'',
                              size_col_label => 12,
                              checked_val=> $dispo_date{commande_time}, #'apresmidi',
                              style=>"",
                              vals =>
                              {
                                  '01/matin'=>"Matin",
                                  '02/apresmidi'=>"Après-midi",
                                  '03/nimporte'=>"Peu importe",
                              }
                          }
                      );

            $table_days .= << "EOH";
            <div class="col-md-12">
                <span style="font-weight: bold;font-size: 14px; text-transform: capitalize;">$arrange_date</span>
                <button id="$dispo_date{id}" type="button" class="btn-link supprim_date"><span style="color:red;">X</span></button>
            </div>

            <div id="$dispo_date{id}" class="col-md-12 one_day" style="">
                $btns_time
            </div>
            <hr style="margin-top: 10px;">
EOH
        }
        $table_days .= "</div>";
        $table_days .= "<script> init_dates_disponibles(); init_form(); </script>";
    }
    else
    {
        $recap_dates =  "<p>Aucune date n'est pas enrégistrée.</p>";
    }
    my $all_dates = $recap_dates .= $table_days;
    print $all_dates;
    exit;
}

################################################################################
# delete_time_commande
################################################################################
sub delete_time_commande
{
   see();
   my $token_commande = get_quoted('token');
   my $id_time = get_quoted('id_time');

   my %commande = sql_line({dbh=>$dbh2,table=>'intranet_factures',where=>"token='$token_commande'"});

   $stmt = "DELETE FROM commande_dates WHERE id='$id_time'";
   execstmt($dbh2,$stmt);


   #TABLEAU DES DATES--------------------------------------------------------------
    my $recap_dates = '';
    my $table_days = '';
    my $all_dates = '';
    my %noms_mois = ();
       $noms_mois{'01'} = 'janvier';
       $noms_mois{'02'} = 'février';
       $noms_mois{'03'} = 'mars';
       $noms_mois{'04'} = 'avril';
       $noms_mois{'05'} = 'mai';
       $noms_mois{'06'} = 'juin';
       $noms_mois{'07'} = 'juillet';
       $noms_mois{'08'} = 'août';
       $noms_mois{'09'} = 'septembre';
       $noms_mois{'10'} = 'octobre';
       $noms_mois{'11'} = 'novembre';
       $noms_mois{'12'} = 'décembre';

    my @dispo_dates = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'commande_dates',where=>"commande_id=$commande{id}",ordby=>"commande_date ASC"});

    if ($#dispo_dates != -1)
    {
        $recap_dates = '<p><b>RÉCAPITULATIF DE VOS DATES</b></p>';

        $table_days = '<div class="row" id="table_days_container">';
        foreach my $dispo_date (@dispo_dates)
        {
            my %dispo_date = %{$dispo_date};

            my ($jour,$mois,$annee) = split (/\//,$dispo_date{commande_date});
            my $arrange_date =  $jour." ".$noms_mois{$mois}." ".$annee;

            my $btns_time = get_form_line(
                          {
                              type => 'btns-group',
                              name =>'time_commande',
                              label =>'',
                              size_col_label => 12,
                              checked_val=> $dispo_date{commande_time}, #'apresmidi',
                              style=>"",
                              vals =>
                              {
                                  '01/matin'=>"Matin",
                                  '02/apresmidi'=>"Après-midi",
                                  '03/nimporte'=>"Peu importe",
                              }
                          }
                      );

            $table_days .= << "EOH";
            <div class="col-md-12">
                <span style="font-weight: bold;font-size: 14px; text-transform: capitalize;">$arrange_date</span>
                <button id="$dispo_date{id}" type="button" class="btn-link supprim_date"><span style="color:red;">X</span></button>
            </div>

            <div id="$dispo_date{id}" class="col-md-12 one_day" style="">
                $btns_time
            </div>
            <hr style="margin-top: 10px;">
EOH
        }
        $table_days .= "</div>";
        $table_days .= "<script> init_dates_disponibles(); init_form(); </script>";

        $all_dates = $recap_dates .= $table_days;

    }
    ####################         S'IL N'Y A PAS DES DATES SOUHAITEES : RENDS LA VALEUR - '' - A UN INPUT REQUIRED name="date_valable"          #########################
    else
    {
        $all_dates =  '';
    }

    print $all_dates;
    exit;
}

################################################################################
# thousands_sep
################################################################################
sub thousands_sep
{
    my $val = $_[0];
    $val =~ s/(?<=\d)(?=(?:\d\d\d)+(?!\d))/\./g;
    return $val;
}

################################################################################
# get_form_line
################################################################################
sub get_form_line
{
    my %d = %{$_[0]};

    $d{size_col_label} = $d{size_col_label} || 5;
    $d{size_col_field} = $d{size_col_field} || 7;

    my $btns  = "";

    if($d{type} eq 'btns-group')
    {
        if($d{sublabel} ne '')
        {
           $d{sublabel} = "<label>$d{sublabel}</label>";
        }
        my $btns_list = get_btns_list(\%d);
        my $return_after_label = '';
        if($d{return_after_label})
        {
            $btns = <<"EOH";
               <div class="form-group form-group-immostage immostage_btn_group_$d{name} $d{class}">
                  <label for="$d{name}" class="col-md-12 control-label">$d{label}</label>
                  <div class="col-md-12">
                      $d{sublabel}
                      $return_after_label
                      $btns_list
                  </div>
                </div>
EOH
        }
		    elsif($d{level} == 2)
        {
        $btns = <<"EOH";
  			<div class="row">
  			<div class="col-md-offset-$d{size_col_label} col-md-$d{size_col_field}">
  				<div class="form-inline immostage_btn_group_$d{name} $d{class}">
  					<label for="$d{name}" class="control-label">$d{label}</label>
  					$d{sublabel}
  					$return_after_label
  					$btns_list
  				</div>
  			</div>
  			</div>
EOH
        }
        elsif($d{label} eq '')
        {
            $btns = <<"EOH";
            <div class="form-group form-group-immostage immostage_btn_group_$d{name} $d{class}">
                <div class="col-md-12">
                    $d{sublabel}
                    $return_after_label
                    $btns_list
                </div>
            </div>
EOH
        }
        else
        {
            $btns = <<"EOH";
             <div class="form-group form-group-immostage immostage_btn_group_$d{name} $d{class}">
                <label for="$d{name}" class="col-md-$d{size_col_label} control-label">$d{label}</label>
                <div class="col-md-$d{size_col_field}">
                    $d{sublabel}
                    $return_after_label
                    $btns_list
                </div>
              </div>
EOH
        }
    }
    elsif($d{type} eq 'interval')
    {
    		if($d{level} == 2)
            {
                $btns = <<"EOH";
    			<div class="row">
    			<div class="col-md-offset-$d{size_col_label} col-md-$d{size_col_field}">

    				<div class="form-inline immostage_btn_group_$d{name} $d{class}">
    					<label for="$d{name}" class="control-label">$d{label}</label>
    					<input style="$d{style}" name="$d{name}" type="text" class="form-control" id="" value="$d{val1}" placeholder="">
    					<span class="form-inline-txt">$sitetxt{im_rechercheSimple_a}</span>
    					<input style="$d{style}" name="$d{name}_2" type="text" class="form-control" id="" value="$d{val2}" placeholder="">
    					<span class="form-inline-txt">$d{suffix}</span>
    				</div>

    			</div>
    			</div>
EOH
        }
    		else
        {
            my $btns_list = get_btns_list(\%d);
            $btns = <<"EOH";
              <div class="form-group form-group-immostage immostage_btn_group_$d{name} $d{class}">
                <label for="$d{name}" class="col-md-$d{size_col_label} control-label">$d{label}</label>
                <div class="col-md-$d{size_col_field}">
                    <div class="form-inline">
    					<input style="$d{style}" name="$d{name}" type="text" class="form-control" id="" value="$d{val1}" placeholder="">
    					<span class="form-inline-txt">$sitetxt{im_rechercheSimple_a}</span>
    					<input style="$d{style}" name="$d{name}_2" type="text" class="form-control" id="" value="$d{val2}" placeholder="">
    					<span class="form-inline-txt">$d{suffix}</span>
    				</div>
                </div>
              </div>
EOH
		    }
    }
    elsif($d{type} eq 'input')
    {
        my $type = 'text';
        if($d{name} eq 'password' || $d{name} eq 'password2')
        {
            $type='password';
        }
        if($d{name} eq 'email' || $d{name} eq 'email2')
        {
            $type='email';
        }

        if($d{return_after_label})
        {
            $btns = <<"EOH";
            <div class="form-group form-group-immostage immostage_btn_group_$d{name} $d{class}">
                <label for="$d{name}" class="col-md-12 control-label">$d{label}</label>
                <div class="col-md-12">
                     <input type="$type" $d{required} data-role="" name="$d{name}" value="$d{value}" style="$d{style}" class="$d{class} form-control" />
                      $d{suffix}
                </div>
            </div>
EOH
        }
        elsif($d{label} eq '')
        {
            $btns = <<"EOH";
            <div class="form-group form-group-immostage immostage_btn_group_$d{name} $d{class}">
                <div class="col-md-12">
                     <input type="$type" $d{required} data-role="" name="$d{name}" value="$d{value}" style="$d{style}" class="$d{class} form-control" />
                </div>
            </div>
EOH
        }
        else
        {
            if(defined $d{prefix} && $d{prefix} ne '' && $d{label} eq '')
              {
                  $btns = <<"EOH";
                <div class="form-group form-group-immostage immostage_btn_group_$d{name} $d{class}">
                      <div class="col-md-$d{size_col_prefix}">
                          <span style="padding-left:20px;">$d{prefix}</span>
                      </div>
                      <div class="col-md-$d{size_col_field}">
                          <input type="$type" $d{required} data-role="" name="$d{name}" value="$d{value}" style="$d{style}" class="$d{class} form-control" />
                          $d{suffix}
                      </div>
                </div>
EOH
              } else{

             $btns = <<"EOH";
              <div class="form-group form-group-immostage immostage_btn_group_$d{name} $d{class}">
                  <label for="$d{name}" class="col-md-$d{size_col_label} control-label">$d{label}</label>
                  <div class="col-md-$d{size_col_field}">
                       <input type="$type"  $d{required}   data-role="" name="$d{name}" value="$d{value}" style="$d{style}" class="$d{class} form-control" />
                        $d{suffix}
                  </div>
              </div>
EOH
              }
         }
    }
    elsif($d{type} eq 'textarea')
    {

         $d{size_col_label} = $d{size_col_label} || 4;
         $d{size_col_field} = $d{size_col_field} || 8;
         $d{size_col_prefix} = $d{size_col_prefix} || 0;

          if(defined $d{prefix})
          {
              $btns = <<"EOH";
          <div class="form-group form-group-immostage immostage_btn_group_$d{name} $d{class}">
                <label for="$d{name}" class="col-md-$d{size_col_label} control-label">$d{label}</label>
                <div class="col-md-$d{size_col_prefix}">
                    <span style="padding-left:20px;">$d{prefix}</span>
                </div>
                <div class="col-md-$d{size_col_field}">
                    <textarea $d{required} data-role="" name="$d{name}" value="$d{checked_vals}{$d{name}}" style="$d{style}" class="$d{class} form-control" cols="$d{cols}" rows="$d{rows}">$d{value}</textarea>
                    $d{suffix}
                </div>
          </div>
EOH
          }
          else
          {
             $btns = <<"EOH";
          <div class="form-group form-group-immostage immostage_btn_group_$d{name} $d{class}">
                <label for="$d{name}" class="col-md-$d{size_col_label} control-label">$d{label}</label>
                <div class="col-md-$d{size_col_field}">
                    <textarea $d{required} data-role="" name="$d{name}" style="$d{style}" class="$d{class} form-control" cols="$d{cols}" rows="$d{rows}">$d{value}</textarea>
                    $d{suffix}
                </div>
              </div>
          </div>

EOH
          }
    }
    elsif($d{type} eq 'file')
    {
         $d{size_col_label} = $d{size_col_label} || 4;
         $d{size_col_field} = $d{size_col_field} || 8;
         $d{size_col_prefix} = $d{size_col_prefix} || 0;

          $type = "file";
            $btns = <<"EOH";
          <div class="form-group form-group-immostage immostage_btn_group_$d{name} $d{class}">
                <div class="col-md-$d{size_col_label}">
                    <span style="padding-left:20px;">$d{prefix}</span>
                </div>
                <div class="col-md-$d{size_col_field}">
                    <input type="$type" name="$d{name}" data-role="" style="$d{style}" value="Choisissez un fichier" />
                    $d{suffix}
                </div>
          </div>
EOH

    }
    elsif($d{type} eq 'list_inputs')
    {
        my @field_names = split (/\,/,$d{name});
        my @field_labels = split (/\,/,$d{label});
        my @field_suffixes = split (/\,/,$d{suffix});
        my @field_classes = split (/\,/,$d{class});
        my @field_required = split (/\,/,$d{required});

        my $i = 0;

		my %valeurs = %{hash_remove_order($d{vals})};
		if($d{no_clean_order} == 1)
		{
			%valeurs = %{$d{vals}};
		}

#          see($d{vals});
#         see(\%valeurs);

        foreach my $field_name (@field_names)
        {
              my $type = 'text';
              if($field_name eq 'password' || $field_name eq 'password2')
              {
                  $type='password';
              }
              if($field_name eq 'email' || $field_name eq 'email2')
              {
                  $type='email';
              }

              if($d{return_after_label})
              {
                  $btns .= <<"EOH";
                      <div class="">
                          <div class="form-group form-group-immostage immostage_btn_group_$field_name $d{class}">
                              <label for="$field_name" class="col-md-12 control-label">$field_labels[$i] <span>$field_suffixes[$i]</span></label>
                              <div class="col-md-12">
                                   <input type="$type" $field_required[$i] data-role="" name="$field_name" value="$d{checked_vals}{$field_name}" style="" class="$field_classes[$i] form-control" />
                              </div>
                          </div>
                      </div>
EOH
              }
              else
              {
                   $btns .= <<"EOH";
                      <div class="">
                          <div class="form-group form-group-immostage immostage_btn_group_$field_name $d{class}">
                              <label for="$field_name" class="col-md-$d{size_col_label} control-label">$field_labels[$i] <span>$field_suffixes[$i]</span></label>
                              <div class="col-md-$d{size_col_field}">
                                   <input type="$type" $field_required[$i] data-role="" name="$field_name" value="$valeurs{$field_name}" style="$d{style}" class="$field_classes[$i] form-control" />
                              </div>
                          </div>
                      </div>
EOH
              }
              $i++;
        }

    }

    return $btns;
}


################################################################################
# get_btns_list
################################################################################
sub get_btns_list
{
    my %d = %{$_[0]};
    my %q = %{$_[0]};

    $d{input_type} = $d{input_type} || 'radio';

    my %bts = ();
    my $required = $q{required} || '';


    my $btns = <<"EOH";
    <div class="immostage_btn_container">
EOH
      foreach my $valeur (sort keys %{$d{vals}})
      {
         my $bclass = ' btn-default ';
         my ($ord,$val,$id_father,$is_checked) = split(/\//,$valeur);
         if(!$id_father>0)
         {
            $id_father = 1;
         }
         my $checked = "";
         if($d{all_checked} eq 'y' || $d{checked_val} eq $val || "$d{value}" eq "$val" || $is_checked)
         {
            $checked = " checked ";
            $bclass = " btn-info ";
         }
         my $father_class = '';
         if($id_father > 0)
         {
            $father_class = $d{name}.'_'.$id_father;
         }

    		  if($d{id_father_is_name} eq 'y')
    		  {
    			$bts{1} .= <<"EOH";
                <a id="$val" style="$d{style}" class="btn $bclass immostage_btn_option $d{name} $d{name}_$val $father_class">$d{vals}{$valeur}</a>
                <input $checked $required class="immostage_btn_option_hidden hide" type="$d{input_type}" name="$id_father" value="$val" />
EOH
    		  }
    		  else
    		  {
    			$bts{$id_father} .= <<"EOH";
                <a id="$val" style="$d{style}" class="btn $bclass immostage_btn_option $d{name} $d{name}_$val $father_class">$d{vals}{$valeur}</a>
                <input $checked $required class="immostage_btn_option_hidden hide" type="$d{input_type}" name="$d{name}" value="$val" />
EOH
			    }
      }

      foreach my $id_father (sort keys %bts)
      {
         $btns .= <<"EOH";
         <div class="btn_group_id_father_$id_father btn_group_id_father_for_$d{name}" >
           $bts{$id_father}
         </div>
EOH
      }
      $btns .= <<"EOH";
    </div>
EOH

    return $btns;
}



sub detail_array_to_html_tab
{
    my @array = @{$_[0]};
    my $debug = $_[1];
    my $html_tab = '<table class="table table-bordered">';
    foreach my $line (@array)
    {
        my @line_info = split(/\|/,$line);
        if($line_info[4] eq 'one_col')
        {
             $html_tab .=<<"EOH";
                <tr>
                    <td colspan="2" class="$line_info[2]">
                        $line_info[0]
                    </th>
                </tr>
EOH
        }
        else
        {
            $html_tab .=<<"EOH";
                <tr>
                    <th class="$line_info[2]">
                        $line_info[0]
                    </th>
                    <td class="$line_info[3]">
                        $line_info[1]
                    </td>
                </tr>
EOH
        }
    }
    $html_tab .= '</table>';

    if($debug)
    {
       print Dumper \@array;
    }

    return $html_tab;
}



sub upload_pics
{
     my $field_name = $_[0];
     my $num_photo = $_[1];
     my $id_annonce = $_[2];
     my $file_path = $_[3];
     my $ext = '';

     if ($file_path eq "") {
          $pic=$cgi->param($field_name);
     } else {
          $pic = $file_path;
     }



     my $pic_dir = '../pics';

      if ($pic =~ /[jJ][pP][eE]*[gG]$/)
    	{
          $ext = 'jpg';
    	}
    	elsif ($pic =~ /[pP][nN][gG]$/)
    	{
          $ext = 'png';
    	}
      else
    	{
    	    return '';
    	}

      my $filename = '';
     ($full,$fullname,$orig_size) = cp_upload_image($pic,$pic_dir,$num_photo,$id_annonce,$file_path);
     ($mini,$mini_width,$mini_height,$full_width,$full_height) = thumbnailize($full,$pic_dir,90,68,"_mini");
     ($small,$small_width,$small_height,$small_width,$small_height) = thumbnailize($full,$pic_dir,500,375,"_small");
     ($medium,$medium_width,$medium_height,$full_width,$full_height) = thumbnailize($full,$pic_dir,1200,900,"_medium");
     ($og,$og_width,$og_height,$big_width,$big_height) = thumbnailize($full,$pic_dir,130,130,"_og");
     ($og,$og_width,$og_height,$big_width,$big_height) = thumbnailize($full,$pic_dir,290,387,"_listing");



     my $url=$pic_dir.'/'.$pic;
     my $thumbnail_pic=$mini;
     my $thumbnail_url=$pic_dir.'/'.$thumbnail_pic;

      return ($full,$fullname,$ext);
}

sub ajax_upload_pics
{
     my $pic=$cgi->param('files[]');
     my $pic_dir = 'pics';
     my $id_annonce = $cgi->param('id_annonce') || 0;

     see();
     my $filename = '';
     my $token = create_token(2);
     ($full,$fullname,$size,$ext) = cp_upload_image($pic,$pic_dir,$token,$id_annonce);
     ($mini,$mini_width,$mini_height,$full_width,$full_height) = thumbnailize($full,$pic_dir,90,68,"_mini");
     ($small,$small_width,$small_height,$small_width,$small_height) = thumbnailize($full,$pic_dir,500,375,"_small");
     ($medium,$medium_width,$medium_height,$full_width,$full_height) = thumbnailize($full,$pic_dir,1200,900,"_medium");
     ($og,$og_width,$og_height,$big_width,$big_height) = thumbnailize($full,$pic_dir,130,130,"_og");
     ($og,$og_width,$og_height,$big_width,$big_height) = thumbnailize($full,$pic_dir,290,387,"_listing");

     my $url=$pic_dir.'/'.$pic;
     my $thumbnail_pic=$mini;
     my $thumbnail_url=$pic_dir.'/'.$thumbnail_pic;
    my %lnk_pic = ();
    $lnk_pic{url_full} = $full;
    $lnk_pic{file} = $fullname;
    $lnk_pic{ext} = $ext;
    $lnk_pic{id_annonce} = $id_annonce;
    inserth_db($dbh2,'photos',\%lnk_pic);

     print <<"EOH";
     [{"name":"$pic","size":$orig_size,"url":"$url","thumbnail_url":"$thumbnail_url","delete_url":"\/\/example.org\/upload-handler?file=picture1.jpg","delete_type":"DELETE"}]
EOH
exit;
}

################################################################################
# push_where_valeur
################################################################################
sub push_where_valeur
{
    my @tab_where = @{$_[0]};
    my $hidden = $_[1];
    my $table = $_[2];
    my $name = $_[3];
    my $type = $_[4] || 'text';
    my $nom_db = $_[5];

    if($name ne '')
    {
        if($type eq 'interval')
        {
            my $db_name = $name;
            if($nom_db ne '')
            {
                $db_name = $nom_db;
            }

            my $valeur = get_quoted($name);
            if($valeur > 0)
            {
                push @tab_where,"$table.$db_name>= $valeur";
                $hidden .= '<input type="hidden" class="search_data" name="'.$name.'" value="'.$valeur.'" />';
            }
            my $valeur_2 = get_quoted($name.'_2');
            if($valeur_2 > 0)
            {
               push @tab_where,"$table.$db_name <= $valeur_2";
               $hidden .= '<input type="hidden" class="search_data" name="'.$name.'_2" value="'.$valeur_2.'" />';
            }
        }
        else
        {
            my $db_name = $name;
            if($nom_db ne '')
            {
                $db_name = $nom_db;
            }
            my $valeur = get_quoted($name);
            if($valeur > 0)
            {
                push @tab_where,"$table.$db_name='$valeur'";
                $hidden .= '<input type="hidden" class="search_data" name="'.$name.'" value="'.$valeur.'" />';
            }
        }
    }

    return ($hidden,@tab_where);
}


sub cp_upload_image
{
	my $in_filename = $_[0] || "";	#Nom du fichier
	my $upload_path = $_[1];		#Chemin absolu du fichier
  my $num_photo = $_[2];
  my $id_doss = $_[3];
  my $file_path = $_[4];
	my ($size, $buff, $bytes_read, $file_url);

  if ($file_path ne "") {
      my @path = split(/\//,$file_path);
      $in_filename = $path[$#path];
  }

	if ($in_filename eq "" || $in_filename =~ /(php|js|pl|asp|cgi|swf)$/) {  return ""; }	#Si pas de fichier alors retour de rien

	my @splitted = split(/\./,$in_filename);
	my $ext = lc($splitted[$#splitted]);
  my $filename = $splitted[0];
  $filename = clean_filename($filename);



	# build unique filename from current timestamp
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

  $year+=1900;	#Ajout de 1900 car la fonction localtime renvoit un nombre compris entre 0 et 99
	$mon++;			#Ajout de 1 car la fonction localtime renvoit un nombre compris entre 0 et 11

	my @chars = ( "A" .. "Z", "a" .. "z");


# 	$file_url = "$filename\_$year$mon$mday$hour$min$sec".".".$ext;
  $file_url = $id_doss.'_'.$num_photo.'_'."$year$mon$mday$hour$min$sec".".".$ext;
  $finame = $id_doss.'_'.$num_photo.'_'."$year$mon$mday$hour$min$sec";


	# add the target directory
	my $out_filename = $upload_path."/".$file_url;
  if ($file_path eq "") {

    	# upload the file contained in the CGI buffer
    	if (!open(WFD,">$out_filename"))
    	{
    		suicide("cannot create file $out_filename $!");	#Appel Ã?Â?Ã?Â? la fonction suicide
    	}

    	# $in_filename = "define::$in_filename";
    	while ($bytes_read = read($in_filename,$buff,2096))	#Tant qu'on peut lire le fichier
    	{
    	    $size += $bytes_read;	#Ajout des bytes lu
    	    binmode WFD;
    	    print WFD $buff;	#Enregistrement
    	}

    	close(WFD);	#Fermeture
	} else {
	    use File::Copy;
#	    $file_path =~ s/ /\\ /g;
#	    if ($out_filename !~ /(\/|\.)/) {$out_filename = "../".$out_filename;}
      copy($file_path,$out_filename) || die "cannot copy $file_path to $out_filename : $!";
      $size = -s $out_filename;
  }


	return ($file_url,$finame,$size,$ext);	#Retourne le nom du fichier downloader sur le serveur ainsi que sa taille
}



sub get_member
{
     my %d = %{$_[0]};

     #read cookie MEMBER
     my $cookie_member = $cgi->cookie('immostage_handmade');
     if($cookie_member ne "")
     {
           $cookie_member_ref=decode_json $cookie_member;
           %hash_member=%{$cookie_member_ref};

           my %member = sql_line({dbh=>$dbh2,debug=>$d{debug},debug_results=>$d{debug},table=>"members",select=>"*",where=>"token='$hash_member{token_member}'"});
           return\%member;
     }
     else
     {
          return ();
     }
}

################################################################################
# get_member_box
################################################################################
sub get_member_box
{
   my %member = %{get_member()};

   if($member{id} > 0)
   {
      return <<"EOH";
         <div class="member_box_on">
            <div id="">
                My immostage
                <ul class="" id="immostage_menu_on">
                    <li><a href="$self&sw=favoris">Favoris <span>(NB FAVORIS)</span></a></li>
                    <li><a href="$self&sw=favoris">Mes annonces <span>(NB ANNONCES)</span></a></li>
                    <li><a href="$self&sw=logout_db">Se déconnecter</a></li>
                </ul>
            </div>
         </div>
EOH
    }
    else
    {
      return <<"EOH";
         <div class="member_box_off">
            <div id="">
                   My immostage
                  <ul class="" id="immostage_menu_off">
                      <li><a href="$self&sw=signup_form" class="btn">Inscription</a></li>
                      <li><a href="$self&sw=login_form">Connexion</a></li>
                  </ul>
            </div>
         </div>
EOH
    }
}

sub get_map_search
{
    my $map_search = <<"EOH";
	<script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false"></script>
	<script type="text/javascript" src="skin/js/polygon.min.js"></script>

	<div class="map_search_container" style="display:none;">
		<div class="row">
			<div class="col-md-4">
				<span id="map_search_title">Tracer une zone sur la carte</span>
			</div>
			<div class="col-md-4">
				<a href="#" id="hide_map_search">Enlever la carte</a>
			</div>
			<div class="col-md-4">
				<a href="#" id="reset">Effacer les points</a>
			</div>
		</div>
		<div id="main-map"></div>
<!--
<input id="showData"  value="Show Paths (class function) " type="button" class="navi"/>
<input id="showColor"  value="Show Color (class function) " type="button" class="navi"/>
<div   id="dataPanel">
</div>
-->
    </div>
EOH

  return $map_search;
}

sub login_db
{
	#DONNEES GET POST (colonne droite -> connexion )
    my $email = get_quoted('email') || '';
    # my $password = get_quoted('password') || '';
      my $password = sha1_hex(trim(get_quoted('password')));

    my $token_commande = get_quoted('token') || '';
    my $retour = get_quoted('ret') || '';
    my $retourerr = get_quoted('errret') || '';
	my $sw_retour_si_erreur = get_quoted('sw_retour_si_erreur') || 'connexion';


log_debug('login_db','','login_db');

    #PARAMETRE DE FONCTION (apres insciption, token passé en parametre)
    my $token_member = $_[0] || get_quoted('token_member') || '';

    #on retrouve le membre
    my %membre = ();
    if($token_member ne '')
    {
       %membre = select_table($dbh_data,"members",'',"token='$token_member'",,'','',1);
       log_debug('MA:'.$membre{id},'','login_db');
    }
    elsif($email ne '' && $password ne '')
    {
       %membre = select_table($dbh_data,"members",'',"email = '$email' AND password = '$password'",,'','',1);
              log_debug('MA2:'.$membre{id},'','login_db');

       if($membre{password} eq "")  # si le client n'a pas d'accès password
       {
         log_debug('MA3:'.$membre{id},'','login_db');
		 my $retpass = 'espace_perso';
		 if($retourerr ne '')
		 {
			$retpass = $retourerr;
		 }
		# cgi_redirect($self.'&sw=commande_etape&go_to_step=2&token='.$token_commande.'&mess=pass');
		cgi_redirect($self.'&sw=connexion&ret='.$retpass.'&mess=pass');
	   }

       if($membre{visible} eq "n")  # si le client est invisible
       {
          log_debug('MA4:'.$membre{id},'','login_db');
         # see();  print $self.'&sw=connexion&ret='.$retour.'&mess=invis';    exit;
      	   cgi_redirect($full_self.'&sw='.$sw_retour_si_erreur.'&mess=invis');
       }
    }
	elsif($retour ne '')
    {
       # cgi_redirect($self.'&sw=connexion&ret='.$retour);
    }
    else
    {
  	    log_debug('MA5:'.$membre{id},'','login_db');
       cgi_redirect($self.'&sw=commande_etape&go_to_step=2&token='.$token_commande.'&mess=pass');
    }

	 log_debug('MA6:'.$membre{id},'','login_db');
	# see(\%membre);

   # && ($membre{visible} ne "n")

    if(($membre{id} > 0) )
    {
		$stmt = "UPDATE members SET last_login=NOW() where id='$membre{id}'";
		# see();
		# print $stmt;
		execstmt($dbh2,$stmt);
# exit;
		 log_debug('MA7:'.$membre{id},'','certi');
		my %tableau_membre = ();
        $tableau_membre{token_member} = $membre{token};
        # see(\%tableau_membre);
        #on crée une variable texte json à parti du tableau associatif
        $tableau_membre_utf8_encoded_json_text = encode_json \%tableau_membre;

        #on crée le cookie à partir de la variable texte json
        my $cook = $cgi->cookie(-name=>'certigreen_handmade',-value=>$tableau_membre_utf8_encoded_json_text,-path=>'/');
        print $cgi->header(-cookie=>$cook,-charset => 'utf-8');

        # if($retour ne '')
        # {
      			 # print 'retour : '.$retour;
              # log_debug('MA9:'.$membre{id},'','certi');
				 # http_redirect($self."&sw=$retour");

        # }
        # else
        # {
            if(($email ne '' && $password ne '') || ($token_member ne ''))
            {
               # if($membre{type_member} eq 'Agence')
               # {
# see();
				# print 'agence: go to 2';
				# exit;
				  # http_redirect($self."&sw=commande_etape&go_to_step3&token=$token_commande");
				   # http_redirect($self."&sw=commande_etape&go_to_step=2bis&token=$token_commande");

               # }
               # else
               # {
                  my %commande_update = ();

				    if($membre{type_member} eq 'Agence')
					{
						#si agence, on remplit l'id agence
						$commande_update{id_member_agence} = $membre{id};
					}
					else
					{
						#si particulier, on remplit l'id_member
						$commande_update{id_member} = $membre{id};
					}


                  # $commande_update{id_member} = $membre{id};

				  # see(\%commande_update);
				  # exit;
				  # print 'not agence: go to 3';

				  # exit;
				  sql_set_data({debug=>0,dbh=>$dbh2,table=>'intranet_factures',data=>\%commande_update, where=>"token='$token_commande'"});
					http_redirect($self."&sw=commande_etape&go_to_step=3&token=$token_commande");
               # }
            }
        # }
    }
    else
	{
			# print 'membre non trouvé';
#           print $cgi->header(-cookie=>$cook,-charset => 'utf-8');
#           print "err";
			# see();
    		http_redirect($self.'&sw='.$sw_retour_si_erreur.'&go_to_step=2&token='.$token_commande.'&err=pass');
    		# exit;
    }
	# exit;
}



sub lost_password_db
{
    my $email = get_quoted('email');
    $email = trim($email);
    my %acces = sql_line({dbh=>$dbh2,debug=>0,table=>"members",where=>"UPPER(email) = UPPER('$email')"});
    
    if($acces{id} > 0 && $acces{email} ne '')
    {
          #SET NEW TOKEN AND send SECURE LINK*****************************************
          my $new_token = create_token(50);
          $stmt = "UPDATE members SET token='$new_token' where id=$acces{id}";
          execstmt($dbh2,$stmt);
          
          my $link = "$self&sw=edit_password_db&token=$new_token";
          
          my $email_body = <<"EOH";
              Bonjour $acces{firstname} $acces{lastname},
              <br />
              <br />
              TXT CHANGEMENT MDP 1
              <br />
              <a href="$link">TXT CHANGEMENT MDP 2</a>  TXT CHANGEMENT MDP 3.<br />
              <br />
              $TXT CHANGEMENT MDP 4.
EOH
          
          send_mail('alexis@bugiweb.com',$acces{email},'Changement de votre mot de passe',$email_body,"html");
          cgi_redirect("$self&sw=lost_password_ok");
    }
    else
    {
          cgi_redirect("$self&sw=lost_password_ko");
    }
}

 
sub logout_db
{
   my $cook = $cgi->cookie(-name=>'certigreen_handmade',-value=>'',-path=>'/');
   print $cgi->header(-cookie=>$cook,-charset => 'utf-8');
   http_redirect($self.'&sw=""');
#    cgi_redirect("$full_self&sw=commande_etape&go_to_step=2&token=$token&member=''");
}







################################################################################
# display
################################################################################
sub display
{
    my $content = '<div class="container">'.$_[0].'</div>';
    my $view = get_quoted('view');
 
    my $id_template_page = '';
    my $tpl_page = $_[1] || $id_template_page ;
    if(!($tpl_page > 0)) {
      $tpl_page = 6;
    }
    my $type_affichage = $_[2] || 'avec_col';
#     if($type_afficgage ne 'avec_col')
#     {
#         $tpl_page = 406;
#     }
    
    my $member_box = get_member_box();
    
    
    my $page_content = '';
    if($tpl_page > 0)
    {
        # $template = get_template($dbh,$tpl_page);
        # $page_content = get_link_canvas($dbh,$extlink,$template,"html",$content,$tpl_page,$lg);
        $page_content = migcrender::render_page({debug=>0,content=>$content,id_tpl_page=>$tpl_page,extlink=>$extlink,lg=>$config{current_language}});

    }
    
    
    my $from = '<MIGC_LANGUAGE_CODE_HERE> ';
    my %codes = (1=>'FR',2=>'EN',3=>'NL',4=>'DE');
    my $to = $lg;
    $page_content =~ s/$from/$codes{$to}/g;
    print $page_content;
}




################################################################################
# contact_db
###############################################################################
sub contact_db
{
    my @fields = ('nom','prenom','email','telephone','message');
    my @mandatory_fields = ('nom','prenom','email','message');
    
    foreach my $f (@mandatory_fields)
    {
        my $value = get_quoted($f);
        if(trim($value) eq '')
        {
            print "$sitetxt{im_contact_champManquant}($f)";
            exit;
        }
    }
    
    my %contact = ();
    foreach my $f (@fields)
    {
        my $value = get_quoted($f);
        $contact{$f} = trim($value);
    }
    
    my $id_contact = inserth_db($dbh_data,'contacts',\%contact);
    cgi_redirect($full_self.'&sw=contact_ok');
   
}


sub langues_de_site()
{        
see();
    my $langue = get_quoted('langue');
    my @languages = sql_lines({table=>'languages',ordby=>'id ASC'});
    my @langues_immo;
    my $compteur = 1;
    
    foreach $language (@languages)
    {
       my %language = %{$language};
       my %langue_immo;
       $langue_immo{id} = $language{id};
       $langue_immo{name} = $language{name};  
       $langue_immo{display_name} = $language{display_name};
       push(@langues_immo,%langue_immo);
       $compteur++;
       if($compteur == 4){
            last;
       }
    }
   print $langue;
   exit;
}

################################################################################
# signup_db
###############################################################################
sub signup_db
{
    my @fields  = ('type','firstname','lastname','company','vat','gender','street','number','box','id_city','zip','city','tel','gsm','fax','email','email2','password','password2');
    my @mandatory_fields = ('type','firstname','lastname','email','email2');
    
    my $token = get_quoted('token');
    if($token eq '')
    {
        push @mandatory_fields, 'password';
        push @mandatory_fields, 'password2';
    }
    
    #vérifie les champs obligatoires
    foreach my $f (@mandatory_fields)
    {
        my $value = get_quoted($f);
        if(trim($value) eq '')
        {
            see();
              print<<"EOH";
            		<script language="javascript">
            		alert("Champs obligatoire manquant ($f)");
            		history.go(-1);
            		</script>
EOH
            exit;
        }
    }
    
    #receive data
    my %member = ();
    foreach my $f (@fields)
    {
        my $value = get_quoted($f);
        $member{$f} = trim($value);
    }
    if($member{email} ne $member{email2})
    {
         see();
              print<<"EOH";
            		<script language="javascript">
            		alert("$sitetxt{mail_correspond_pas}");
            		history.go(-1);
            		</script>
EOH
            exit;
    }
    if($member{password} ne $member{password2})
    {
        see();
        print<<"EOH";
      		<script language="javascript">
      		alert("$sitetxt{mdp_correspondent_pas}");
      		history.go(-1);
      		</script>
EOH
        exit;
    }
    delete $member{email2};
    delete $member{password2};
    
    if($token eq '')
    {
        #SIGNUP
        
        #check email not exists
        my %check = sql_line({dbh=>$dbh_data,table=>"members",where=>"LOWER(email)='$member{email}'"});
        if($check{id} > 0)
        {
            see();
            print<<"EOH";
          		<script language="javascript">
          		alert("$sitetxt{mail_deja_enregistre}");
          		history.go(-1);
          		</script>
EOH
            exit;
        }
        
        $member{token} = create_token(100);
        $member{token2} = create_token(100);
        $member{dt_inscription} = 'NOW()';
        inserth_db($dbh_data,'members',\%member);
        cgi_redirect($full_self.'&sw=signup_ok&token='.$member{token});
    }
    else
    {
        #UPDATE
        
        #check email not exists for someone else
        my %check = sql_line({dbh=>$dbh_data,table=>"members",where=>"LOWER(email)='$member{email}' and token != '$token' "});
        if($check{id} > 0)
        {
            see();
            print<<"EOH";
          		<script language="javascript">
          		alert("$sitetxt{mail_deja_enregistre}");
          		history.go(-1);
          		</script>
EOH
            exit;
        }
        $member{dt_modification} = 'NOW()';
        updateh_db($dbh_data,"members",\%member,'token',$token);
        cgi_redirect($full_self.'&sw=edit_ok&token='.$member{token});
    }
}


################################################################################
# hash_remove_order
################################################################################
sub hash_remove_order
{
    my %hash_with_order = %{$_[0]};
    my %hash_without_order =();
    
    foreach my $key_hash_with_order (keys %hash_with_order)
    {
        my ($ordre,$valeur) = split (/\//,$key_hash_with_order); #01/1 
        $hash_without_order{$valeur} =  $hash_with_order{$key_hash_with_order};
        
      
    }
    return \%hash_without_order;
}

sub to_sql_date
{
	my $date = $_[0];	#Date ÃÂÃÂ  convertir
	my $date_only=$_[1] || "all";
	
	my ($dd,$mm,$yyyy) = split (/\//,$date);	#Séparation de la date
	
	if($date_only eq 'date_only')
	{
      $date = "$yyyy-$mm-$dd";	#Reformattage de la date
  }
  else
  {
      $date = "$yyyy-$mm-$dd 00:00:00";	#Reformattage de la date
	}
	return $date;	#Renvoit de la date au bon format

}

#*****************************************************************************************
#DATE time TO HUMAN time
#*****************************************************************************************
sub datetime_to_human_time
{
   my $content = trim($_[0]);
   my $separator = $_[1] || 'h';
   my ($dum,$content) = split (/ /,$content);
   my ($heure,$min,$sec) = split (/:/,$content);
   return $heure.$separator.$min;
}

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

sub go_to_detail
{
    my $searchid = get_quoted('searchid');
    if($searchid > 0)
    {
        my %annonce = read_table($dbh2,'annonces',int($searchid));
        cgi_redirect($full_self.'&sw=detail&token='.$annonce{token});    
    }
    else
    {
        cgi_redirect($full_self);
    }
}


1;    