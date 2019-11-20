#!/usr/bin/perl -I../lib

use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools

$dm_cfg{customtitle}=<<"EOH";
EOH

$dm_cfg{enable_search} = 0;
$dm_cfg{enable_multipage} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "migcms_setup";
$dm_cfg{list_table_name} = "migcms_setup";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/update_dbs.pl?";
$dm_cfg{after_ordby_ref} = '';
$dm_cfg{file_prefixe} = 'CFG';

$config{db_migc4} = "DBI:mysql:migc4;host=www.bugiweb.net";
$config{login_migc4} = "dbupdate";
$config{password_migc4} = "jsUGtsPzSZ7Af9eA";
my $dbh_migc4 = DBI->connect($config{db_migc4},$config{login_migc4},$config{password_migc4}) or die("cannot connect to DB [$config{db_migc4}]");

$stmt = " SET NAMES utf8mb4";	
$cursor = $dbh_migc4->prepare($stmt);		
$rc = $cursor->execute;	


%dm_dfl = 
(
      '10/view_edit_on'=> 
      {
      'title'=>'Activer retouches rapides',
      'fieldtype'=>'checkbox',
      'checkedval' => 'y'
      }
      ,
      '20/id_default_page'=> 
      {
      'title'=>'Première page',
       'fieldtype'=>'listboxtable',
      'lbtable'=>'migcms_pages c, txtcontents txt',
      'lbkey'=>'c.id',
      'lbdisplay'=>'lg1',
      'lbwhere'=>"visible = 'y' and migcms_pages_type='page' and txt.id=id_textid_name",
      'mandatory'=>{"type" => 'not_empty'}
      }
	  ,
      '21/id_notfound_page'=> 
      {
      'title'=>'Page 404',
       'fieldtype'=>'listboxtable',
      'lbtable'=>'migcms_pages c, txtcontents txt',
      'lbkey'=>'c.id',
      'lbdisplay'=>'lg1',
      'lbwhere'=>"visible = 'y' and migcms_pages_type='page' and txt.id=id_textid_name",
      'mandatory'=>{"type" => 'not_empty'}
      }
      ,
      '30/admin_first_page_url'=> 
      {
      'title'=>"Première page de l'admin",
      'fieldtype'=>'text',
      }
	  ,
      '31/site_name'=> 
      {
      'title'=>"Nom du site",
      'fieldtype'=>'text',
      }
	  ,
	'62/Logos'=> 
	{
        'title'=>"Fichiers",
        'fieldtype'=>'files_admin',
		'disable_add'=>1,
		'legend'=>'<u>Ordre des images:</u><br><br>Grand logo (Largeur: 200px) puis petit logo (Largeur: 40px)'
    }
      
);


%dm_display_fields = (
"01/Première page de l'admin"=>"admin_first_page_url"
		);

%dm_lnk_fields = (
		);

%dm_mapping_list = (
);

%dm_filters = (
		);

$sw =  "update_dbs";
if(get_quoted('sw') ne '')
{
	$sw = get_quoted('sw');
}

# see();

my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
			update_dbs
			synchro_menus
		);

if (is_in(@fcts,$sw)) 
{ 
    # dm_init();
	see();
    &$sw();
	exit;

    if($sw ne "dum")
    {
      $migc_output{content} .= $dm_output{content};
      $migc_output{title} = $dm_output{title}.$migc_output{title};
      print migc_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
    }
}


sub update_dbs
{
	my $reference_db_name = 'migc4';
	my $current_db_name = $config{db_name};
	my $remove = 'DBI:mysql:';
	$current_db_name =~ s/$remove//g;
    
    my %conv_types =
    (
          'int' => 'int',
          'date' => 'date',
          'time' => 'time',
          'varchar' => 'varchar',
          'datetime' => 'datetime',
          'bigint' => 'int',
          'float' => 'float',
          'timestamp' => 'datetime',
          'char' => 'varchar',
          'text' => 'text',
          'smallint' => 'int',
          'enum' => 'enum_y_n',  
          'longtext' => 'longtext',  
     );
        
     my $msg = '<h1>Mise à niveau de la base de données</h1>';

     #CREATION AUTO DES TABLES MANQUANTES 
    my @list_of_tables_demozone = get_list_of_tables($reference_db_name,$dbh_migc4);
    my @list_of_tables_site = get_list_of_tables($current_db_name,$dbh);
        
    foreach my $table_demozone (@list_of_tables_demozone)
    {
         if($table_demozone ne '')
         {
             my $existe = 0;
             foreach my $table_site (@list_of_tables_site)
             {
                  if($table_demozone eq $table_site)
                  {
                     $existe = 1;
					# Conversion des tables en UTF8MB4
					#my $stmt = <<"EOH";
					#ALTER TABLE `$table_site` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
#EOH
					#execstmt($dbh,$stmt);
                  }
             } 
             if($existe == 0)
             {
                 #creer la table qui n'existe pas et la convertir en UTF8MB4
                 $msg .= '<hr />Ajout de la table <b>'.$table_demozone.'</b>';
                 my $stmt = <<"EOH";
                 CREATE TABLE IF NOT EXISTS `$table_demozone` (
                    `id` int(11) NOT NULL AUTO_INCREMENT,
                    PRIMARY KEY (`id`)
                  ) ENGINE=MyISAM DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;
				  
EOH
                  execstmt($dbh,$stmt);
                  # ALTER TABLE `$table_demozone` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
             }
			 else
			 {
				if($debug)
				{
					$msg .= '<br /> <span style="color:green">Table <b>'.$table_demozone.'</b> existe</span>';
				}
			 }
         }   
    }

    #CREATION AUTO DES CHAMPS MANQUANTS 
    my @list_of_tables_demozone = get_list_of_tables($reference_db_name,$dbh_migc4);
    my @list_of_tables_site = get_list_of_tables($current_db_name,$dbh);    
    my %cas = ();
    foreach my $table (@list_of_tables_demozone)
    {    
		my @list_of_cols_demozone = get_list_of_cols($reference_db_name,$table,$dbh_migc4);
        my @list_of_cols_site = get_list_of_cols($current_db_name,$table,$dbh);   
               
        foreach my $col_demozone (@list_of_cols_demozone)
        {
            my %col_demozone = %{$col_demozone};
            my $existe = 0;
            foreach my $col_site (@list_of_cols_site)
            {
                my %col_site = %{$col_site}; 
                if($col_demozone{COLUMN_NAME} eq $col_site{COLUMN_NAME})
                {
                    $existe = 1;
                }
            }
           
             if($existe == 0)
             {
                
				
				$conv_type = $col_demozone{DATA_TYPE};
				if($conv_types{$col_demozone{DATA_TYPE}} ne '')
				{
					$conv_type = $conv_types{$col_demozone{DATA_TYPE}};
				}
				
				$msg .= '<br />Ajout de la colonne <b>'.$col_demozone{COLUMN_NAME}.'</b> dans la table <b>'.$table.'</b>';
                create_col_in_table($dbh,$table,$col_demozone{COLUMN_NAME},$conv_type); 
             }
			 else
			 {
				if($debug)
				{
					$msg .= '<br /> <span style="color:green">Colonne <b>'.$col_demozone{COLUMN_NAME}.'</b> trouvée dans la table '.$table.'</span>';
				}
			 }
        }
		
		#index du site
		my @indexs_for_table_site = sql_lines({dbh=>$dbh,stmt=>"show index from $table where Non_unique = 1"});
		
		#index de migc4
		my @indexs_for_table_migc4 = sql_lines({dbh=>$dbh_migc4,stmt=>"show index from $table where Non_unique = 1"});

		
		
		#verifie si les champs en autoindex ont bien un index
		#my @autoindex_for_names = ('migcms_deleted','tags','visible','migcms_id','code');
		my @autoindex_for_names = ('migcms_deleted','visible','migcms_id','code');
		
		#boucler sur les colonnes de migc4
        my @list_of_cols_site = get_list_of_cols($current_db_name,$table,$dbh);   
		foreach my $col_demozone (@list_of_cols_site)
		{
			#boucler sur les colonnes de la table migc4 pour voir s'il s'agit d'un champs autoindex
			my %col_demozone = %{$col_demozone}; 
			
			foreach my $champs_autoindex (@autoindex_for_names)
			{
				if($col_demozone{COLUMN_NAME} eq $champs_autoindex)
				{

					#si c'est un champs auto index, a t il deja un index ? 
					my $existe = 0;
					
					#boucler sur les indexs de la db migc4
					foreach $index_for_table_migc4 (@indexs_for_table_site)
					{
						my %index_for_table_migc4 = %{$index_for_table_migc4};
						# $msg .= "<br /><span style='color:purple'>$index_for_table_migc4{Column_name} eq $champs_autoindex".'</span>';
						if($index_for_table_migc4{Column_name} eq $champs_autoindex)
						{
							# $msg .= "<br /><span style='color:red'>$index_for_table_migc4{Column_name} eq $champs_autoindex".'</span>';
							$existe = 1;
							last;						
						}				
					}
					
					if($existe == 0)
					{
						$msg .= "<br /><span style='color:purple'>Ajout automatique d'index sur la table <b>$table</b> pour le champs <b>$champs_autoindex</b>".'</span>';
						
						my $stmt = "CREATE INDEX $champs_autoindex ON $table ($champs_autoindex);";
						execstmt($dbh,$stmt);
					}
					
					# $msg .= "<br /><span style='color:purple'>$table (migc4) $conv_type $type_text $col_demozone{COLUMN_NAME} eq $index_for_table_migc4{Column_name}".'</span>';

					last;
				}	
				
			}

					
		}
		
		
		my @indexs_for_table_site = sql_lines({dbh=>$dbh,stmt=>"show index from $table where Non_unique = 1"});

		
		
		

		#boucler sur les indexs de la db migc4
		foreach $index_for_table_migc4 (@indexs_for_table_migc4)
		{
			my %index_for_table_migc4 = %{$index_for_table_migc4};
			if($index_for_table_migc4{Column_name} eq 'id')
			{
				next;
			}
			
			#verifie si le champs est de type texte car alors il faut définir une taille à l'index
			my $type_text = 0;
			my @list_of_cols_demozone = get_list_of_cols($reference_db_name,$table,$dbh_migc4);   
			foreach my $col_demozone (@list_of_cols_demozone)
			{
                #boucler sur les colonnes de la table migc4 pour identifier le type
				my %col_demozone = %{$col_demozone}; 
				
				#si c'est la colonne

				if($col_demozone{COLUMN_NAME} eq $index_for_table_migc4{Column_name})
				{
					my $conv_type = $col_demozone{DATA_TYPE};
					if($conv_types{$col_demozone{DATA_TYPE}} ne '')
					{
						$conv_type = $conv_types{$col_demozone{DATA_TYPE}};
					}

					if($conv_type eq 'text')
					{
						$type_text = 1;
					}
					
					# $msg .= "<br /><span style='color:purple'>$table (migc4) $conv_type $type_text $col_demozone{COLUMN_NAME} eq $index_for_table_migc4{Column_name}".'</span>';

					last;
				}			
			}
			
			#Table, Key_name, Column_name
			my $existe = 0;
			foreach $index_for_table_site (@indexs_for_table_site)
			{
				my %index_for_table_site = %{$index_for_table_site};
				if($index_for_table_migc4{Column_name} eq $index_for_table_site{Column_name})
				{
					$existe = 1;
					last;
				}			
			}
			
			if($existe == 0)
			{
				$msg .= "<br /><span style='color:red'> AJout de l'index <b>$table</b> $type_text:"."$index_for_table_migc4{Key_name} - <b>$index_for_table_migc4{Column_name}</b>".'</span>';
				
				my $stmt = "CREATE INDEX $index_for_table_migc4{Column_name} ON $table ($index_for_table_migc4{Column_name});";
				if($type_text == 1)
				{
					$stmt = "CREATE INDEX $index_for_table_migc4{Column_name} ON $table ($index_for_table_migc4{Column_name}(190));";
				}
				execstmt($dbh,$stmt);
			}
			elsif($existe == 1)
			{
				# $msg .= '<br /><span style="color:green">'."$index_for_table_migc4{Key_name} - $index_for_table_migc4{Column_name}".'</span>';
			}
			else
			{
				# $msg .= '<br /><span style="color:blue">'."$index_for_table_migc4{Key_name} - $index_for_table_migc4{Column_name}".'</span>';
			}
		}
    }	 
             
    
    	
	DOINDEX :
	
	#ajoute des indexes sur l'annuaire pour les colonnes cochées
	my @indexs_for_table_site = sql_lines({dbh=>$dbh,stmt=>"show index from data_sheets where Non_unique = 1"});
	my @data_searchs = sql_lines({dbh=>$dbh,table=>'data_searchs',where=>"cols != ''"});
	foreach $data_search (@data_searchs)
	{
		my %data_search = %{$data_search};
		my @cols = split(/\,/,$data_search{cols});
		foreach my $id_data_field (@cols)
		{
			if($id_data_field > 0)
			{
				my %data_field = read_table($dbh,'data_fields',$id_data_field);
				if($data_field{ordby} > 0)
				{
					my $col_candidate_for_index = 'f'.$data_field{ordby};
					my $existe = 0;

					#boucler sur les indexes de data_sheets pour vérifier que la colonne est déja indexée
					foreach $index_for_table_site (@indexs_for_table_site)
					{
						my %index_for_table_site = %{$index_for_table_site};
						if($col_candidate_for_index eq $index_for_table_site{Column_name})
						{
							$existe = 1;
							last;
						}	
					}
					
					if($existe == 0)
					{
						$msg .= "<br /><span style='color:orange'> Ajout de l'index de recherche <b>ANNUAIRE</b>:"."$col_candidate_for_index".'</span>';
						
						my $stmt = "CREATE INDEX $col_candidate_for_index ON data_sheets ($col_candidate_for_index(190));";
						execstmt($dbh,$stmt);
						
						#relecture des index pour éviter erreurs duplicate key si plusieurs annuaires avec la meme clé...
						goto DOINDEX; 
					}
				}
			}
		}
	}
	
	#ajoute la colonne migcms_deleted à toutes les tables
	my @list_of_tables_site = get_list_of_tables($current_db_name,$dbh);
	# see();
	foreach my $table (@list_of_tables_site)
	{
		 # $msg .= '<br /> <span style="color:orange">Table <b>'.$table.'</span>';
		 # print  '<br /> <span style="color:orange">Table <b>'.$table.'</span>';
		 create_col_in_table($dbh,$table,'migcms_last_published_file','varchar'); 
		 create_col_in_table($dbh,$table,'migcms_id','varchar'); 
		 create_col_in_table($dbh,$table,'migcms_deleted','enum_y_n'); 
		 create_col_in_table($dbh,$table,'migcms_lock','enum_y_n'); 
		 create_col_in_table($dbh,$table,'migcms_id_user_create','int'); 
		 create_col_in_table($dbh,$table,'migcms_id_user_last_edit','int'); 
		 create_col_in_table($dbh,$table,'migcms_id_user_view','int'); 
		 create_col_in_table($dbh,$table,'migcms_moment_create','datetime'); 
		 create_col_in_table($dbh,$table,'migcms_moment_last_edit','datetime'); 
		 create_col_in_table($dbh,$table,'migcms_moment_view','datetime'); 
		 
		 #remplir les valeurs manquantes
		 
		my $stmt = "update `$table` set migcms_moment_create = migcms_moment_last_edit where (migcms_moment_create = '000-00-00 00:00:00' OR migcms_moment_create IS NULL) AND migcms_moment_last_edit !=  '000-00-00 00:00:00'";
		execstmt($dbh,$stmt);
		my $stmt = "update `$table` set migcms_moment_view = migcms_moment_last_edit where (migcms_moment_view = '000-00-00 00:00:00' OR migcms_moment_view IS NULL) AND migcms_moment_last_edit !=  '000-00-00 00:00:00'";
		execstmt($dbh,$stmt);
		my $stmt = "update `$table` set migcms_id_user_create = migcms_id_user_last_edit where migcms_id_user_create = '0'AND migcms_id_user_last_edit !=  '0'";
		execstmt($dbh,$stmt);
		my $stmt = "update `$table` set migcms_id_user_view = migcms_id_user_last_edit where migcms_id_user_view = '0' AND migcms_id_user_last_edit !=  '0'";
		execstmt($dbh,$stmt);
	}
	# use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset);
	
	#synchro migcs_trad
	my @trads = sql_lines({dbh=>$dbh_migc4,table=>'migcms_trads'});
	foreach $trad (@trads)
	{
		my %trad = %{$trad};
		my %new_trad = ();
		delete $trad{id};
		foreach my $col (keys %trad)
		{
			$new_trad{$col} = $trad{$col};		
		}
		%new_trad = %{quoteh(\%new_trad)};
		
		my %test_trad = sql_line({table=>'migcms_trads',where=>"keyword='$new_trad{keyword}'"});
		if($test_trad{id} >  0)
		{
			if($config{disable_update_migc_txt} ne 'y')
			{
				updateh_db($dbh,"migcms_trads",\%new_trad,'id',$test_trad{id});
			}
		}
		else
		{
			# $new_trad{lg1} = to_utf8({ -string =>  $new_trad{lg1}, -charset => 'ISO-8859-15' });
			inserth_db($dbh,'migcms_trads',\%new_trad);
			$msg .= '<br />Ajout du texte migctrad: '.$new_trad{keyword};
		}
	}
	
	#synchro eshop_txts
	my @trads = sql_lines({dbh=>$dbh_migc4,table=>'eshop_txts'});
	foreach $trad (@trads)
	{
		my %trad = %{$trad};
		my %new_trad = ();
		delete $trad{id};
		foreach my $col (keys %trad)
		{
			$new_trad{$col} = $trad{$col};		
		}
		%new_trad = %{quoteh(\%new_trad)};
		
		# $new_trad{lg1} = to_utf8({ -string =>  $new_trad{lg1}, -charset => 'ISO-8859-15' });
		$new_trad{lg1} = $new_trad{lg1};
		my %test_trad = sql_line({table=>'eshop_txts',where=>"keyword='$new_trad{keyword}'"});
		if($test_trad{id} >  0)
		{
			if($config{disable_update_eshop_txt} ne 'y')
			{
				updateh_db($dbh,"eshop_txts",\%new_trad,'id',$test_trad{id});
			}
		}
		else
		{
			inserth_db($dbh,'eshop_txts',\%new_trad);
			$msg .= '<br />Ajout du texte eshop_txts: '.$new_trad{keyword};
		}
	}
    
    $msg .= '<br /><br />Copie de eshop_txts terminée';
	
	#members_txts
	my @trads = sql_lines({dbh=>$dbh_migc4,table=>'members_txts'});
	foreach $trad (@trads)
	{
		my %trad = %{$trad};
		my %new_trad = ();
		delete $trad{id};
		foreach my $col (keys %trad)
		{
			$new_trad{$col} = $trad{$col};		
		}
		%new_trad = %{quoteh(\%new_trad)};
		
		# $new_trad{lg1} = to_utf8({ -string =>  $new_trad{lg1}, -charset => 'ISO-8859-15' });
		my %test_trad = sql_line({table=>'members_txts',where=>"keyword='$new_trad{keyword}'"});
		if($test_trad{id} >  0)
		{
			if($config{disable_update_members} ne 'y')
			{
				updateh_db($dbh,"members_txts",\%new_trad,'id',$test_trad{id});
			}
		}
		else
		{
			inserth_db($dbh,'members_txts',\%new_trad);
			$msg .= '<br />Ajout du texte members_txts: '.$new_trad{keyword};
		}
	}
    
    $msg .= '<br /><br />Copie de members_txts terminée';

	
	my @trads = sql_lines({dbh=>$dbh_migc4,table=>'migcms_members_tags'});
	foreach $trad (@trads)
	{
		my %trad = %{$trad};
		my %new_trad = ();
		foreach my $col (keys %trad)
		{
			$new_trad{$col} = $trad{$col};		
		}
		%new_trad = %{quoteh(\%new_trad)};
		
		# $new_trad{name} = to_utf8({ -string =>  $new_trad{name}, -charset => 'ISO-8859-15' });
		my %test_trad = sql_line({table=>'migcms_members_tags',where=>"id='$new_trad{id}'"});
		if($test_trad{id} >  0)
		{
		}
		else
		{
			# inserth_db($dbh,'migcms_members_tags',\%new_trad);
			$msg .= '<br />PAS d\'ajout du tag automatique !: '.$new_trad{name};
		}
	}
	
	
	#migcms_languages
	my @migcms_languages = sql_lines({dbh=>$dbh_migc4,table=>'migcms_languages'});
	foreach $migcms_languages (@migcms_languages)
	{
		my %migcms_languages = %{$migcms_languages};
		my %new_migcms_language = ();
		foreach my $col (keys %migcms_languages)
		{
			$new_migcms_language{$col} = $migcms_languages{$col};		
		}
		%new_migcms_language = %{quoteh(\%new_migcms_language)};
		
		# $new_migcms_language{lg1} = to_utf8({ -string =>  $new_trad{lg1}, -charset => 'ISO-8859-15' });
		my %test_language = sql_line({table=>'migcms_languages',where=>"id='$new_migcms_language{id}'"});
		if($test_language{id} >  0)
		{
		
		}
		else
		{
			inserth_db($dbh,'migcms_languages',\%new_migcms_language);
			$msg .= '<br />Ajout de la langue : '.$new_migcms_language{display_name};
		}
	}
	
	
	#js
	my @migcms_page_js = sql_lines({dbh=>$dbh_migc4,table=>'migcms_page_js'});
	foreach $migcms_page_js (@migcms_page_js)
	{
		my %migcms_page_js = %{$migcms_page_js};
		my %new_migcms_page_js = ();
		foreach my $col (keys %migcms_page_js)
		{
			$new_migcms_page_js{$col} = $migcms_page_js{$col};		
		}
		%new_migcms_page_js = %{quoteh(\%new_migcms_page_js)};
		
		my %test_migcms_page_js = sql_line({table=>'migcms_page_js',where=>"id='$new_migcms_page_js{id}'"});
		if($test_migcms_page_js{id} >  0)
		{
			updateh_db($dbh,"migcms_page_js",\%new_migcms_page_js,'id',$test_migcms_page_js{id});
		}
		else
		{
			inserth_db($dbh,'migcms_page_js',\%new_migcms_page_js);
			$msg .= '<br />Ajout du JS : '.$new_migcms_page_js{filename};
		}
	}
    
	#css
	my @migcms_page_css = sql_lines({dbh=>$dbh_migc4,table=>'migcms_page_css'});
	foreach $migcms_page_css (@migcms_page_css)
	{
		my %migcms_page_css = %{$migcms_page_css};
		my %new_migcms_page_css = ();
		foreach my $col (keys %migcms_page_css)
		{
			$new_migcms_page_css{$col} = $migcms_page_css{$col};		
		}
		%new_migcms_page_css = %{quoteh(\%new_migcms_page_css)};
		
		my %test_migcms_page_css = sql_line({table=>'migcms_page_css',where=>"id='$new_migcms_page_css{id}'"});
		if($test_migcms_page_css{id} >  0)
		{
			updateh_db($dbh,"migcms_page_css",\%new_migcms_page_css,'id',$test_migcms_page_css{id});
		}
		else
		{
			inserth_db($dbh,'migcms_page_css',\%new_migcms_page_css);
			$msg .= '<br />Ajout du CSS : '.$new_migcms_page_css{filename};
		}
	}
	
	
	#migcms_urls_common
	my @migcms_urls_common = sql_lines({dbh=>$dbh_migc4,table=>'migcms_urls_common'});
	foreach $migcms_urls_common (@migcms_urls_common)
	{
		my %migcms_urls_common = %{$migcms_urls_common};
		my %new_migcms_urls_common = ();
		foreach my $col (keys %migcms_urls_common)
		{
			$new_migcms_urls_common{$col} = $migcms_urls_common{$col};		
		}
		%new_migcms_urls_common = %{quoteh(\%new_migcms_urls_common)};
		
		my %test_new_migcms_urls_common = sql_line({table=>'migcms_urls_common',where=>"id='$migcms_urls_common{id}'"});
		if($test_new_migcms_urls_common{id} >  0)
		{
			updateh_db($dbh,"migcms_urls_common",\%new_migcms_urls_common,'id',$new_migcms_urls_common{id});

		}
		else
		{
			inserth_db($dbh,'migcms_urls_common',\%new_migcms_urls_common);
			$msg .= '<br />Ajout de la réécriture URL : '.$new_migcms_urls_common{url_rewriting};
		}
	}
	
    $msg .= '<br /><br />Terminé';
	
	
	
	
	
	create_page_minimized('css');
	create_page_minimized('js');
	
	fill_sys();
	
	#met les champs titre, description et photos à visibles si aucun n'est cochés (anciens migcs4): à supprimer plus tard...
	my %test_active_title_template = sql_line({table=>'templates',where=>"active_title='y'"});
	if($test_active_title_template{id} > 0)
	{
	}
	else
	{
		my $stmt = <<"EOH";
        UPDATE templates SET active_title = 'y', active_content='y', active_pics='y'
EOH
        execstmt($dbh,$stmt);	
	
	}	
	
	my @test_unique_url_rew = sql_lines({dbh=>$dbh,stmt=>"show index from migcms_urls where Column_name = 'url_rewriting'"});

	if($#test_unique_url_rew > -1)
	{
	
	my $stmt = <<"EOH";
        ALTER TABLE migcms_urls DROP INDEX url_rewriting
EOH
        execstmt($dbh,$stmt);
	}
	
     print $msg;
    exit;
}

sub create_page_minimized
{
	my $type = $_[0];
	
	log_debug("create_page_minimized$type","vide","create_page_minimized$type");
	
	my $filename = "../mig_skin/$type/migcms_all.$type";
	my $filename_min = "../mig_skin/$type/migcms_all_min.$type";
	log_debug("$filename","","create_page_minimized$type");
	log_debug("$filename_min","","create_page_minimized$type");
	
	reset_file($filename);
	my @files = sql_lines({debug=>1,debug_results=>1,table=>'migcms_page_'.$type,ordby=>'ordby',where=>"visible='y'"});
	
	foreach $file (@files)
	{
		my %file = %{$file};
		my $src_file = '../'.$file{filename};
			log_debug("$src_file","","create_page_minimized$type");

		my $content = get_file($src_file) or die ("cannont find $src_file");
		
		
		write_file($filename,$content);
	}
	
	# if($type eq 'js')
	# {
		 # use JavaScript::Minifier qw(minify);
	 
		 # open(my $in, $filename) or die;
		 # open(my $out, '>', $filename_min) or die;
		 
		 # minify(input => $in, outfile => $out);
		 
		 # close($in);
		 # close($out);
	# }
	# elsif($type eq 'css')
	# {
		 # use CSS::Minifier qw(minify);
		
		 # open(my $in, $filename) or die;
		 # open(my $out, '>', $filename_min) or die ("cannot open $out > $filename_min");
		
		 # minify(input => $in, outfile => $out);
		
		 # close(INFILE);
		 # close(OUTFILE);
	# }
}



sub create_col_in_table
{
  my $dbh=$_[0];
  my $table=$_[1];
  my $col=$_[2];
  my $type=$_[3];
  my $action=$_[4] || "ADD";
  
  my $type_stmt = "";
  # print "<br>[$col][$type]";
  if($type eq 'enum_y_n')
  {
     $type_stmt=" ENUM( 'y', 'n' ) NOT NULL DEFAULT 'n' ";
  }
  elsif($type eq 'enum_n_y')
  {
     $type_stmt=" ENUM( 'y', 'n' ) NOT NULL DEFAULT 'y' ";
  }
  elsif($type eq 'text')
  {
     $type_stmt=" TEXT NOT NULL ";
  }
  elsif($type eq 'change_text')
  {
     $type_stmt=" TEXT CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL  ";
  }
  elsif($type eq 'datetime')
  {
     $type_stmt=" DATETIME";
  }
  elsif($type eq 'date')
  {
     $type_stmt="  DATE NULL DEFAULT NULL ";
  }
  elsif($type eq 'time')
  {
     $type_stmt=" TIME NOT NULL ";
  }
  elsif($type eq 'int')
  {
     $type_stmt=" INT NOT NULL ";
  }
  elsif($type eq 'int_1')
  {
     $type_stmt=" INT NOT NULL  DEFAULT '1'  ";  
  }
  elsif($type eq 'varchar')
  {
     $type_stmt=" VARCHAR( 190 ) NOT NULL  ";
  }
  elsif($type eq 'float')
  {
     $type_stmt=" FLOAT NOT NULL  ";  
  }
  elsif($type eq 'float_0.21')
  {
     $type_stmt=" FLOAT NOT NULL DEFAULT '0.21'  ";  
  }
  elsif($type eq 'shop_order_status')
  {
     $type_stmt=" ENUM( 'new', 'begin', 'current', 'finished', 'unfinished', 'cancelled' ) NOT NULL DEFAULT 'new' AFTER `id`  ";  
  }
  elsif($type eq 'shop_payment_status')
  {
     $type_stmt=" ENUM( 'wait_payment', 'captured', 'paid', 'repaid', 'cancelled' ) NOT NULL DEFAULT 'wait_payment' AFTER `shop_order_status`  ";  
  }
  elsif($type eq 'shop_delivery_status')
  {
     $type_stmt=" ENUM( 'current', 'ready', 'partial_sent', 'full_sent', 'cancelled','ready_to_take' ) NOT NULL DEFAULT 'current' AFTER `shop_payment_status`   ";  
  }
  elsif($type eq 'longtext')
  {
	$type_stmt =" longtext NOT NULL ";
  }
  else
  {
	$type_stmt = $type;
  }
  my @test=get_describe($dbh,$table);
  if($#test == -1)
  {
      return 0;
  }
  for($t=0;$t<$#test+1;$t++)
  {
      my %line=%{$test[$t]};
      if($line{Field} eq $col)
      {
        return 0;
      }
  }
  my $stmt = "ALTER TABLE `$table` $action `$col` $type_stmt";
  my $cursor = $dbh->prepare($stmt);
  my $rc = $cursor->execute;
  if (!defined $rc) 
  {
      see();
      print "[$stmt]";
      exit;   
  }
  return 1; 
}

sub synchro_menus
{
	my $reference_db_name = 'migc4';
	my $current_db_name = $config{db_name};
	my $remove = 'DBI:mysql:';
	$current_db_name =~ s/$remove//g;
    
    my $msg = '<h1>Synchro des menus et permissions</h1>';   
             
    recuse_synchro_menus({id_father=>0,dbh_online=>$dbh_migc4,dbh_local=>$dbh});

    print $msg;
    exit;
}

sub recuse_synchro_menus
{
	my %d = %{$_[0]};	

	#reprend les élements menu de migc4 sans les élements de codes et d'aide
	my @scripts_online = sql_lines({dbh=>$d{dbh_online},debug=>0,debug_results=>0,table=>'scripts',where=>"id_father = '$d{id_father}' AND id_father NOT IN ('1000251','1000252','1000254') AND id != 1000251"});
	foreach $script_online (@scripts_online)
	{
		my %script_online = %{$script_online};

		#ajout/maj des infos
		my %update_script_local = 
		(
			'id'=>$script_online{id},
			'visible'=>$script_online{visible},
			'short'=>$script_online{short},
			'icon'=>$script_online{icon},
			'url'=>$script_online{url},
			'cacher_menu'=>$script_online{cacher_menu},			
			'id_father'=>$script_online{id_father},			
			'ordby'=>$script_online{ordby},			
		);

		%update_script_local = %{quoteh(\%update_script_local)};
		
		my %check_id_local = sql_line({table=>'scripts',where=>"id='$script_online{id}'"});
		if($check_id_local{id} > 0)
		{
			
		}
		else
		{
			#ajout du script
			my $id_script_local = inserth_db($dbh,'scripts',\%update_script_local);		
			my %script_local = sql_line({debug=>0,debug_results=>0,dbh=>$d{dbh_local},table=>'scripts',where=>"id='$script_online{id}'"});

			#maj du nom
			foreach my $idlg (1 .. 3)
			{
				%script_local = sql_line({debug=>0,debug_results=>0,dbh=>$d{dbh_local},table=>'scripts',where=>"id='$script_online{id}'"});
				my $traduction_script_online = get_traduction({id=>$script_online{id_textid_name},dbh=>$d{dbh_online},id_language=>$idlg});
				log_debug("lg $idlg :".$script_online{id_textid_name}.":".$traduction_script_online,'','syncmenu');
				set_traduction({dbh=>$d{dbh_local},table_record=>'scripts',col_record=>'id_textid_name',id_record=>$script_local{id},id_language=>$idlg,id_traduction=>$script_local{id_textid_name},traduction=>$traduction_script_online});
			}
			
			#ajout des permissions
			my @permissions_online = sql_lines({dbh=>$d{dbh_online},table=>'migcms_roles_scripts_permissions',where=>"id_script = '$id_script_local'"});
			
			foreach $permission_online (@permissions_online)
			{
				my %permission_online = %{$permission_online};
				delete $permission_online{id};
				%permission_online = %{quoteh(\%permission_online)};
				
				inserth_db($dbh,'migcms_roles_scripts_permissions',\%permission_online);		
			}
		}
		recuse_synchro_menus({id_father=>$script_online{id},dbh_local=>$d{dbh_local},dbh_online=>$d{dbh_online}});
	}
}