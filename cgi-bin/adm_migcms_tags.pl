#!/usr/bin/perl -I../lib 

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use members;
use dm;
use Encode;
use HTML::Entities;
my $id_migcms_member_dir = get_quoted('id_migcms_member_dir');
$dm_cfg{add_title} = "";
$dm_cfg{table_name} = "migcms_members_tags";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_tags.pl?id_migcms_member_dir=$id_migcms_member_dir";
$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 1;
$dm_cfg{sort_opt} = 0;
$dm_cfg{autocreation} = 1;
$dm_cfg{delete} = 1;
$dm_cfg{duplicate} = 1;
$dm_cfg{trad} = 0;
$dm_cfg{dbh} = $dbh;

if($id_migcms_member_dir > 0)
{
$dm_cfg{wherel} = $dm_cfg{wherep} = "id_migcms_member_dir='$id_migcms_member_dir'";
}
$dm_cfg{migcrender} = 0;
$dm_cfg{def_handmade} = 0;
$dm_cfg{operations} = 0;
$dm_cfg{excel} = 0;
$dm_cfg{default_ordby}='name';
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{breadcrumb_func}= \&breadcrumb_func;

$dm_cfg{file_prefixe} = 'tags';
$cpt = 9;
	
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
%dm_dfl = (    
		
		sprintf("%05d", $cpt++).'/name' => {'title'=>"Nom",'fieldtype'=>'text',"type" => 'not_empty',search=>'y'},
		sprintf("%05d", $cpt++).'/id_migcms_member_dir'=>{'title'=>'Groupe','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'lbtable'=>'migcms_member_dirs','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
		# sprintf("%05d", $cpt++).'/type'=>{'title'=>'Ancien type','translate'=>0,'fieldtype'=>'text','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'lbtable'=>'migcms_member_dirs','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
		sprintf("%05d", $cpt++).'/import_emails'=>{'title'=>'Importer des emails (copier coller)','legend'=>'Séparateurs: <b>,</b> ou <b>;</b> ou retour à la ligne.','translate'=>0,'fieldtype'=>'textarea','data_type'=>'','search' => 'n','mandatory'=>{"type" => ''},'lbtable'=>'migcms_member_dirs','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
		# sprintf("%05d", $cpt++).'/fichiers'=>{'title'=>'Importer des emails','translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'','search' => 'n','mandatory'=>{"type" => 'not_empty'},'lbtable'=>'migcms_member_dirs','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},
,	
	'50/fichiers'=> 
	{
		'title'=>"Importer des emails (Fichier .XLS)",
		'fieldtype'=>'files_admin',
		'disable_add'=>1,
		'msg'=>'Cliquez <b>ici</b> pour parcourir votre ordinateur et deposer un fichier .XLS en utilisant le modèle détaillé ci-dessous.',
		'legend'=>'Comment ajouter des emails à ce groupe ? Le plus simple est de télécharger et compléter <a href="../mig_skin/import_emails.xls">ce fichier Excel modèle</a> puis de le déposer dans la zone ci-dessus et cliquer sur <b>Sauvegarder</b>.<br><br>Format requis: .xls<br>Colonne A: Nom<br>Colonne B: Prénom<br>Colonne C: Email.<br>NB: La colonne email est obligatoire',
	}	   
	);
  
%dm_display_fields = (
 "02/Nom"=>"name",
 "03/Dossier"=>"id_migcms_member_dir",
);



%dm_lnk_fields = 
(

);

%dm_mapping_list = (

);



%dm_filters = (
  
);


$sw = $cgi->param('sw') || "list";

see();

$dm_cfg{'list_custom_action_19_func'} = \&tag_emails;


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

	my $suppl_js=<<"EOH";
    
     <style>
	 
      </style>
    
   	<script type="text/javascript">
      jQuery(document).ready(function() 
      {
          
		  
		 
		  
            
      });
    </script> 
EOH
    
    print migc_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}




sub after_save
{
	my $new_id = $_[1];
	
	my %rec = read_table($dbh,$dm_cfg{table_name},$new_id);
	
	compute_denomination($new_id);
	see();
	$rec{import_emails} = trim($rec{import_emails});
	
	#importe les emails via copier coller
	if($rec{import_emails} ne '')
	{
		import_emails_tag_field($rec{import_emails},$new_id);
	}
	

	#importe les emails via fichier .XLS
	my @migcms_linked_files = sql_lines({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_field='fichiers' AND ext='.xls' AND table_name='$dm_cfg{table_name}' AND token='$new_id'"});
	foreach $migcms_linked_file (@migcms_linked_files)
	{
		my %migcms_linked_file = %{$migcms_linked_file};
		my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};

		if(-e $file_url)
		{
			import_emails_tag_xls($file_url,$new_id);
			unlink($file_url);
			$stmt = "DELETE FROM migcms_linked_files where id = $migcms_linked_file{id}";		
			execstmt($dbh,$stmt);	
		}		
    }
}


sub import_emails_tag_field
{
    my $emails_field = $_[0];
    my $id_tag = $_[1];
	my @emails = ();
	
	if($emails_field =~ /\,/)
	{
		@emails = split(/\,/,$emails_field);
	}
	elsif($emails_field =~ /\;/)
	{
		@emails = split(/\;/,$emails_field);
	}
	elsif($emails_field =~ /\r*\n/)
	{
		@emails = split(/\r*\n/,$emails_field);
	}
	else
	{
		push @emails, $emails_field;
	}
	
	my %rec = read_table($dbh,$dm_cfg{table_name},$id_tag);

	my $rapport_tags = '';
	my %cache_email_id = ();
	my %cache_email_tags = ();
	my %cache_insertion = ();
	my %cache_membre_tag = ();
	
	#CACHES****************************************************
    my @migcms_members = sql_lines({table=>"migcms_members",select=>"id,tags,email",where=>"email != ''"});
    foreach $migcms_member (@migcms_members)
    {
        my %migcms_member = %{$migcms_member};
		$cache_email_id{$migcms_member{email}} = $migcms_member{id};
		$cache_email_tags{$migcms_member{email}} = $migcms_member{tags};		
    }
	 my @migcms_members_tag = sql_lines({table=>"migcms_member_tag_emails",select=>"",where=>"id_migcms_member_tag = '$id_tag' and id_migcms_member > 0"});
    foreach $migcms_member_tag (@migcms_members_tag)
    {
        my %migcms_member_tag = %{$migcms_member_tag};
		$cache_membre_tag{$migcms_member_tag{id_migcms_member}} = 1;
    }

	#TRAITEMENT*************************************************
	
	#boucle
	$rapport_tags .= '<table>';
	
	foreach my $email (@emails)
	{
		$email = trim($email);
		if($email eq '')
		{
			next;		
		}	
		
		my %update_record = ();
	
		my $import_email = $email;
		
		if($import_email ne '')
		{
			$rapport_tags .= '<tr><td>'.$import_email."".'</td>';
			log_debug($import_email,'','after_save_tags');
			
			if($import_email =~ /^[^@]+@([-\w]+\.)+[A-Za-z]{2,4}$/ && $import_email !~ /^\-/) 
			{
				my %existing_member_email = sql_line({table=>'migcms_members',where=>"email='$import_email'"});
				if($existing_member_email{id} > 0)
				{
					#membre existant
					my $new_id_tag = "',".($rec{id}).",'";
					log_debug('Membre existant -> maj:  Membre ID #'.$existing_member_email{id}.' avec le tag:'.$new_id_tag,'','after_save_tags');
					$rapport_tags .= '<td style="color:green">Le membre existait déjà (#'.$existing_member_email{id}.')</td>';
					
					if($existing_member_email{tags} =~ /\,$rec{id}\,/)
					{
						$rapport_tags .= '<td style="color:green">  Le tag <b>'.$rec{name}.' (#'.$rec{id}.'</b>) était déjà lié au membre</td>';
					}
					else
					{
						$stmt = "UPDATE migcms_members SET tags=CONCAT(tags,$new_id_tag) where id = $existing_member_email{id}";
						execstmt($dbh,$stmt);	
						$rapport_tags .= '<td style="color:blue">  Ajout du tag <b>'.$rec{name}.' (#'.$rec{id}.'</b>) au membre</td>';
					}
					
					$count_emails_maj++;
					
					if($cache_membre_tag{$existing_member_email{id}} != 1)
					{
						my %new_migcms_member_tag_emails = 
						(
							id_migcms_member_tag => $id_tag,
							id_migcms_member => $existing_member_email{id},
						);	
						%new_member = %{quoteh(\%new_migcms_member_tag_emails)};
						inserth_db($dbh,"migcms_member_tag_emails",\%new_migcms_member_tag_emails);
						$cache_membre_tag{$existing_member_email{id}} = 1;
					}
					
					if($config{member_events_to_mailing_tags_after_func} ne '')
					{
						my $func = 'def_handmade::'.$config{member_events_to_mailing_tags_after_func};
						&$func($existing_member_email{id});
					}
				}				
				else
				{
					#nouveau membre
					my %new_member = 
					(
						email => $import_email,
						actif => 'y',
						email_optin => 'y',
						email_optin_2 => 'y',
						tags => ','.$rec{id}.',',
						
					);	
					%new_member = %{quoteh(\%new_member)};
					my $new_id_member = inserth_db($dbh,"migcms_members",\%new_member);				
					$count_emails_creation++;
					$rapport_tags .= '<td style="color:blue">Le membre a été ajouté (#'.$new_id_member.')</td><td style="color:blue">et lié au tag <b>'.$rec{name}.' (#'.$rec{id}.'</b>)</td>';
					log_debug('<td style="color:blue">Ajout du membre: '.$new_id_member.'</td><td style="color:blue">Ajout du tag:'.$rec{id}.'</td>','','after_save_tags');
					
					if($cache_membre_tag{$new_id_member} != 1)
					{
						my %new_migcms_member_tag_emails = 
						(
							id_migcms_member_tag => $id_tag,
							id_migcms_member => $new_id_member,
						);	
						%new_member = %{quoteh(\%new_migcms_member_tag_emails)};
						inserth_db($dbh,"migcms_member_tag_emails",\%new_migcms_member_tag_emails);
						$cache_membre_tag{$new_id_member} = 1;
					}
					
					if($config{member_events_to_mailing_tags_after_func} ne '')
					{
						my $func = 'def_handmade::'.$config{member_events_to_mailing_tags_after_func};
						&$func($new_id_member);
					}					
				}
			}
			else
			{
					log_debug('Format invalide:'.$import_email,'','after_save_tags');

					$rapport_tags .= '<td style="color:red" colspan="2">Le format de l\'email est invalide</td>';
					$count_emails_error++;
			}
			$rapport_tags .= '</tr>';
				log_debug($rapport_tags,'','after_save_tags');
		}
		else
		{
			$vide = 1;
			log_debug('->vide:'.$vide,'','after_save_tags');
		}
	}
	$rapport_tags .= '</table>';	
	
	if(0 && $config{tags_import_mail_debug} ne '')
	{
		log_debug('Email envoyé:'.$config{tags_import_mail_debug},'','after_save_tags');
		send_mail($config{tags_import_mail_debug},$config{tags_import_mail_debug},"Rapport d'association au tag $rec{name}",$rapport_tags,"html");
	}
	send_mail('dev@bugiweb.com','dev@bugiweb.com',"COPIE BUGIWEB: Rapport d'association au tag $rec{name}",$rapport_tags,"html");
	log_debug($rapport_tags,'','after_save_tags');
	members::after_save_create_token;
	log_debug('Terminé','','after_save_tags');
	
	$stmt = "UPDATE $dm_cfg{table_name} SET import_emails = '' WHERE id = '$id_tag'";
	execstmt($dbh,$stmt);	
}

 
sub tag_emails
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};

my $sel = get_quoted('sel');
	my $acces = <<"EOH";
		<a class="btn btn-default" href="adm_migcms_member_tag_emails.pl?id_migcms_member_tag=$id&sel=$sel" data-original-title="Voir les emails liés à ce groupe" target="" data-placement="bottom">
		@
		</a>
EOH

	return $acces;
}

sub compute_denomination
{
	my $id = $_[0];
	my %rec = sql_line({table=>$dm_cfg{table_name},where=>"id='$id'"});
	my %migcms_member_dir = sql_line({table=>'migcms_member_dirs',where=>"id='$rec{id_migcms_member_dir}'"});
	$migcms_member_dir{name} =~ s/\'/\\\'/g;
	$rec{name} =~ s/\'/\\\'/g;
	
	if($migcms_member_dir{name} eq '')
	{
		$migcms_member_dir{name} = 'Aucun dossier attribué';
	}

	$fusion = $migcms_member_dir{name}.' > '.$rec{name};
	
	my $stmt = <<"EOH";
		UPDATE $dm_cfg{table_name} SET fusion = '$fusion', type='$migcms_member_dir{name}' WHERE id = '$rec{id}'
EOH
	execstmt($dbh,$stmt);
	
}

sub compute_denomination_all
{
	see();
	my @recs = sql_lines({debug=>0,debug_results=>0,table=>$dm_cfg{table_name},where=>""});
	foreach $recs (@recs)
	{
		my %rec = %{$recs};
		compute_denomination($rec{id});
	}
	exit;
}

sub import_emails_tag_xls
{
    my $outfile = $_[0];
    my $id_tag = $_[1];
	my %rec = read_table($dbh,$dm_cfg{table_name},$id_tag);

	my $rapport_tags = '';
	my %cache_email_id = ();
	my %cache_email_tags = ();
	my %cache_insertion = ();
	my %cache_membre_tag = ();
	
	#CACHES****************************************************
    my @migcms_members = sql_lines({table=>"migcms_members",select=>"id,tags,email",where=>"email != ''"});
    foreach $migcms_member (@migcms_members)
    {
        my %migcms_member = %{$migcms_member};
		$cache_email_id{$migcms_member{email}} = $migcms_member{id};
		$cache_email_tags{$migcms_member{email}} = $migcms_member{tags};		
    }
	 my @migcms_members_tag = sql_lines({table=>"migcms_member_tag_emails",select=>"",where=>"id_migcms_member_tag = '$id_tag' and id_migcms_member > 0"});
    foreach $migcms_member_tag (@migcms_members_tag)
    {
        my %migcms_member_tag = %{$migcms_member_tag};
		$cache_membre_tag{$migcms_member_tag{id_migcms_member}} = 1;
    }

	#TRAITEMENT*************************************************
	
	#ouverture fichier
	my $parser   = Spreadsheet::ParseExcel->new();
	my $workbook = $parser->parse($outfile) || die 'cannont open '.$outfile;
	if ( !defined $workbook )
	{
		die $parser->error(), ".\n";
	}
	my $worksheet = $workbook->worksheet(0);
	my $vide = 0;
	#boucle
	$rapport_tags .= '<table>';
	
	foreach my $row (1 .. 10000)
	{
		my %update_record = ();
	
		if(($debug_limit > 0 && $debug_limit < $row) || $vide == 1)
		{
			last;
		}
		
		my $import_lastname = tags_import_excel_cell($row,0,$worksheet);
		my $import_firstname = tags_import_excel_cell($row,1,$worksheet);
		my $import_email = tags_import_excel_cell($row,2,$worksheet);

		$import_firstname =~ s/\'/\\\'/g;
		$import_lastname =~ s/\'/\\\'/g;
		
		if($import_email ne '')
		{
			$rapport_tags .= '<tr><td>'.$import_email." ($import_lastname $import_firstname)".'</td>';
			log_debug($import_email.':'.$import_firstname.':'.$import_firstname,'','after_save_tags');

			
			if($import_email =~ /^[^@]+@([-\w]+\.)+[A-Za-z]{2,4}$/ && $import_email !~ /^\-/) 
			{
				my %existing_member_email = sql_line({table=>'migcms_members',where=>"email='$import_email'"});
				# my %existing_tag_member_email = sql_line({table=>'migcms_members',where=>"tags LIKE '%,$rec{id},%'"});
				if($existing_member_email{id} > 0)
				{
					#membre existant
					my $new_id_tag = "',".($rec{id}).",'";
					log_debug('Membre existant -> maj:  Membre ID #'.$existing_member_email{id}.' avec le tag:'.$new_id_tag,'','after_save_tags');
					$rapport_tags .= '<td style="color:green">Le membre existait déjà (#'.$existing_member_email{id}.')</td>';
					
					if($existing_member_email{tags} =~ /\,$rec{id}\,/)
					{
						$rapport_tags .= '<td style="color:green">  Le tag <b>'.$rec{name}.' (#'.$rec{id}.'</b>) était déjà lié au membre</td>';
					}
					else
					{
						$stmt = "UPDATE migcms_members SET tags=CONCAT(tags,$new_id_tag) where id = $existing_member_email{id}";
						execstmt($dbh,$stmt);	
						$rapport_tags .= '<td style="color:blue">  Ajout du tag <b>'.$rec{name}.' (#'.$rec{id}.'</b>) au membre</td>';
					}
					
					if($import_firstname ne '')
					{
						$stmt = "UPDATE migcms_members SET delivery_firstname='$import_firstname' where id = $existing_member_email{id}";
						execstmt($dbh,$stmt);
					}
					if($import_lastname ne '')
					{
						$stmt = "UPDATE migcms_members SET delivery_lastname='$import_lasttname' where id = $existing_member_email{id}";
						execstmt($dbh,$stmt);
					}
					
					$count_emails_maj++;
					
					if($cache_membre_tag{$existing_member_email{id}} != 1)
					{
						my %new_migcms_member_tag_emails = 
						(
							id_migcms_member_tag => $id_tag,
							id_migcms_member => $existing_member_email{id},
						);	
						%new_member = %{quoteh(\%new_migcms_member_tag_emails)};
						inserth_db($dbh,"migcms_member_tag_emails",\%new_migcms_member_tag_emails);
						$cache_membre_tag{$existing_member_email{id}} = 1;
					}
					
					if($config{member_events_to_mailing_tags_after_func} ne '')
					{
						my $func = 'def_handmade::'.$config{member_events_to_mailing_tags_after_func};
						&$func($existing_member_email{id});
					}
				}				
				else
				{
					#nouveau membre
					my %new_member = 
					(
						email => $import_email,
						actif => 'y',
						email_optin => 'y',
						email_optin_2 => 'y',
						tags => ','.$rec{id}.',',
						
					);	
					%new_member = %{quoteh(\%new_member)};
					my $new_id_member = inserth_db($dbh,"migcms_members",\%new_member);				
					$count_emails_creation++;
					$rapport_tags .= '<td style="color:blue">Le membre a été ajouté (#'.$new_id_member.')</td><td style="color:blue">et lié au tag <b>'.$rec{name}.' (#'.$rec{id}.'</b>)</td>';
					log_debug('<td style="color:blue">Ajout du membre: '.$new_id_member.'</td><td style="color:blue">Ajout du tag:'.$rec{id}.'</td>','','after_save_tags');
					
					if($cache_membre_tag{$new_id_member} != 1)
					{
						my %new_migcms_member_tag_emails = 
						(
							id_migcms_member_tag => $id_tag,
							id_migcms_member => $new_id_member,
						);	
						%new_member = %{quoteh(\%new_migcms_member_tag_emails)};
						inserth_db($dbh,"migcms_member_tag_emails",\%new_migcms_member_tag_emails);
						$cache_membre_tag{$new_id_member} = 1;
					}
					
					if($config{member_events_to_mailing_tags_after_func} ne '')
					{
						my $func = 'def_handmade::'.$config{member_events_to_mailing_tags_after_func};
						&$func($new_id_member);
					}					
				}
			}
			else
			{
					log_debug('Format invalide:'.$import_email,'','after_save_tags');

					$rapport_tags .= '<td style="color:red" colspan="2">Le format de l\'email est invalide</td>';
					$count_emails_error++;
			}
			$rapport_tags .= '</tr>';
				log_debug($rapport_tags,'','after_save_tags');
		}
		else
		{
			$vide = 1;
			log_debug('->vide:'.$vide,'','after_save_tags');
		}
	}
	$rapport_tags .= '</table>';	
	
	if(0 && $config{tags_import_mail_debug} ne '')
	{
		log_debug('Email envoyé:'.$config{tags_import_mail_debug},'','after_save_tags');
		send_mail($config{tags_import_mail_debug},$config{tags_import_mail_debug},"Rapport d'association au tag $rec{name}",$rapport_tags,"html");
	}
	send_mail('dev@bugiweb.com','dev@bugiweb.com',"COPIE BUGIWEB: Rapport d'association au tag $rec{name}",$rapport_tags,"html");
	log_debug($rapport_tags,'','after_save_tags');
	members::after_save_create_token;
	log_debug('Terminé','','after_save_tags');
}


sub tag_emails
{
	my $id = $_[0];
	my $colg = $_[1];
	my %record = %{$_[2]};

my $sel = get_quoted('sel');
	my $acces = <<"EOH";
		<a class="btn btn-default" href="adm_migcms_member_tag_emails.pl?id_migcms_member_tag=$id&sel=$sel" data-original-title="Voir les emails attachés à ce tag" target="" data-placement="bottom">
		@
		</a>
EOH

	return $acces;
}


sub tags_import_excel_cell
{
	my $row = $_[0];
	my $excel_col = $_[1];
	my $worksheet = $_[2];
	
	my $cell = $worksheet->get_cell($row, $excel_col);
	if($cell ne "")
	{
		my $excel_value = trim(encode("utf8",$cell->value()));
		my $excel_value = $cell->value();
		$excel_value = decode_entities($excel_value);
		$excel_value = encode_entities($excel_value);
		return $excel_value;
	}
	else
	{
	
		return "";
	}
}


sub breadcrumb_func
{
    # my $dbh=$_[0];
    my $id=$_[1];
		my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
	my $url_home = $migcms_setup{admin_first_page_url};

	my $id_migcms_member_dir = get_quoted('id_migcms_member_dir');
	my %migcms_member_dirs = read_table($dbh,'migcms_member_dirs',$id_migcms_member_dir);
	my %sel = sql_line({select=>"id", table=>"scripts", where=>"url LIKE '%adm_migcms_member_dirs.pl%'"});

	
	my $breadcrumb = <<"EOH";
	<ul class="breadcrumb panel">
	<li><a href="$config{baseurl}/cgi-bin/$url_home" data-original-title="$migctrad{backtohome}"><i class="fa fa-home"></i> $migctrad{home}</a></li>
			<li><a href="adm_migcms_member_dirs.pl?&sel=$sel{id}">Groupes</a></li>			
			<li>$migcms_member_dirs{name}</li>			
	</ul>
EOH
	
	return $breadcrumb;
	
}

sub recover_tags_eplus
{
	see();
	# exit;
	
	#boucler sur tous les tags du parent sources
	my @migcms_members_tags = sql_lines({table=>'migcms_members_tags',where=>"migcms_deleted != 'y' AND traite = 0 AND id_migcms_member_dir='6'",limit=>"0,2"});
	foreach $migcms_members_tag (@migcms_members_tags)
	{
		my %rec = %{$migcms_members_tag};
		see(\%rec);
		my $id_tag = $rec{id};
		
		#lire les membres liés (tags like %,ID TAG,%)
		my @migcms_members_old = sql_lines({table=>'migcms_members_20171010',where=>"tags LIKE '%,$rec{id},%'"});
		foreach $migcms_member_old (@migcms_members_old)
		{
			my %migcms_member_old = %{$migcms_member_old};
			my %existing_member_email = sql_line({table=>'migcms_members',where=>"email='$migcms_member_old{email}' AND id='$migcms_member_old{id}'"});
			
			if($existing_member_email{id} > 0)
			{
				#boucler sur les emails des membres liés faire le traitement de laison + recalcul
				my $new_id_tag = "',".($rec{id}).",'";
				log_debug('Membre existant -> maj:  Membre ID #'.$existing_member_email{id}.' avec le tag:'.$new_id_tag,'','after_save_tags');
				$rapport_tags .= '<td style="color:green">Le membre existait déjà (#'.$existing_member_email{id}.')</td>';
				
				if($existing_member_email{tags} =~ /\,$rec{id}\,/)
				{
					$rapport_tags .= '<td style="color:green">  Le tag <b>'.$rec{name}.' (#'.$rec{id}.'</b>) était déjà lié au membre</td>';
				}
				else
				{
					$stmt = "UPDATE migcms_members SET tags=CONCAT(tags,$new_id_tag) where id = $existing_member_email{id}";
					execstmt($dbh,$stmt);	
					$rapport_tags .= '<td style="color:blue">  Ajout du tag <b>'.$rec{name}.' (#'.$rec{id}.'</b>) au membre</td>';
				}
				
				my %new_migcms_member_tag_emails = 
				(
					id_migcms_member_tag => $id_tag,
					id_migcms_member => $existing_member_email{id},
				);	

				sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_member_tag_emails',data=>\%new_migcms_member_tag_emails, where=>"id_migcms_member_tag='$new_migcms_member_tag_emails{id_migcms_member_tag}' AND id_migcms_member='$new_migcms_member_tag_emails{id_migcms_member}'"});
		
				if($config{member_events_to_mailing_tags_after_func} ne '')
				{
					my $func = 'def_handmade::'.$config{member_events_to_mailing_tags_after_func};
					&$func($existing_member_email{id});
				}
			}
		}
		print '<br>'.($#migcms_members_old+1).' members';
		$stmt = "UPDATE migcms_members_tags SET traite=1 where id = $rec{id}";
		execstmt($dbh,$stmt);	
	}
    print '<br>'.($#migcms_members_tags+1).' tags';
	
	exit;
}

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------