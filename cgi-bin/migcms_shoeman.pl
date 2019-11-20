#!/usr/bin/perl -I../lib 
#-------------------------------------------------------------------------------
use def;
use def_handmade;
use tools;
use data;
use File::Copy;
use File::Path qw(remove_tree rmtree);
use dm_cms;

see();
my $self = "cgi-bin/migcms_shoeman.pl?";

my %codes = tools::get_codes();

#connexion Shoeman et config
my @languages = sql_lines({table=>'migcms_languages',where=>"visible='y' OR encode_ok = 'y' "});
my $dbh_dirmacom = DBI->connect("DBI:mysql:$codes{shoeman_config}{db}{v1};host=$codes{shoeman_config}{host}{v1}","$codes{shoeman_config}{login}{v1}","$codes{shoeman_config}{password}{v1}") or print("cannot connect to DB $codes{shoeman_config}{db}{v1}");
$cursor = $dbh_dirmacom->prepare(" SET NAMES UTF8");		
$rc = $cursor->execute;
my $taux_tva = $codes{shoeman_config}{taux_tva}{v1};
my $colonne_log = $codes{shoeman_config}{colonne_log}{v1};
my $colonne_log_temp = $codes{shoeman_config}{colonne_log_temp}{v1};
my $id_data_family = $codes{shoeman_config}{id_data_family}{v1};
my $sheets_where = $codes{shoeman_config}{sheets_where}{v1};
my $path_dirmacom = $codes{shoeman_config}{path_dirmacom}{v1};
my $path_pics = $codes{shoeman_config}{path_pics}{v1};
my $path_dossier_photos = $codes{shoeman_config}{path_dossier_photos}{v1};
my $sitename = $codes{shoeman_config}{sitename}{v1};
my %id_father_cat_tailles = sql_line({table=>'migcms_codes',where=>"v7='tailles'"});

my $sw = get_quoted('sw') || 'cron_start';
if(is_in(@fcts,$sw)) 
{ 
    &$sw();
}

sub cron_start
{
	#débloque automatiquement la synchro si on est le lendemain de la dernière exécution
	$stmt = "update bugiweb_synchros set $sitename = '0' WHERE DATE(".$sitename."_beginmoment) < CURRENT_DATE()";
	execstmt($dbh_dirmacom,$stmt);
	
	#vérifie si une autre synchro n'est pas en cours
	my %bugiweb_synchro = sql_line({debug=>0,debug_results=>0,dbh=>$dbh_dirmacom,table=>'bugiweb_synchros',where=>"id='1'",limit=>'',ordby=>''});
	if($bugiweb_synchro{$sitename} == 1)
	{
		print 'synchro en cours';
		send_mail('debug@bugiweb.com','debug@bugiweb.com','La synchro est arretee sur '.$sitename,'La synchro est arretee sur '.$sitename,"html");
		log_debug("$sitename: $bugiweb_synchro{$sitename}",'','migcms_shoeman_verrouille');
		exit;
	}	
	
	log_debug('Début','vide','migcms_shoeman');
	log_debug('Début','vide','migcms_shoeman_sheets');
	log_debug('Début','vide','migcms_shoeman_stock');
	log_debug('Début','vide','migcms_shoeman_photos');
	log_debug('Début','vide','migcms_shoeman_visible');
	log_debug('Début','vide','migcms_shoeman_trans');
	log_debug('Début','vide','migcms_shoeman_cats');
	log_debug('cron_start','','migcms_shoeman');
	
	#verrouille la synchro
	$stmt = "update bugiweb_synchros set $sitename = '1', ".$sitename."_beginmoment = NOW() WHERE id = '1'";
	execstmt($dbh_dirmacom,$stmt);	
	
	#Etape 1: Création des sheets, catégories, seo, gestion des trans, parametres
	shoeman_gere_trans();
	shoeman_update_params();
	shoeman_sheets();
	
	#Etape 2: Tailles, stock, prix
	shoeman_gere_trans();
	shoeman_stock();
	set_stock_activable();	
	set_sheets_prix_reduits();
	
	compute_id_data_categories();	#résumé des catégories pour chaque fiche pour l'admin
	compute_id_data_categories_filters();	#desactive: arborescence apercu filtres
	fill_categories_name();			#champs fusion des nouvelles catégories pour l'admin
	categories_visibility();		#Category_visibilité: Catégories visibles si fiches liées
		
	# Etape 3: Photos pour les produits avec fiche et stock OK.
	shoeman_photos();
	
	#Etape 4: Produit visible si fiche,stock et photos ok.	
	shoeman_visibility();
	
	$stmt = "update bugiweb_synchros set $sitename = '0', ".$sitename."_endmoment = NOW() WHERE id = '1'";
	execstmt($dbh_dirmacom,$stmt);	
	
	#vider cache à chaque synchro car pb de prix ok en admin dont le cache ne se rafraichit pas 
	remove_tree( '../cache/site/data/list', {keep_root => 1} );
	remove_tree( '../cache/site/data/detail', {keep_root => 1} );
	
	log_debug('dm_cms::do_build_pages','','migcms_shoeman');
	dm_cms::do_build_pages();
	log_debug('dm_cms::do_build_pages OK','','migcms_shoeman');
	
	log_debug('cron_start OK','','migcms_shoeman');
}

sub shoeman_gere_trans
{
	log_debug('shoeman_gere_trans','','migcms_shoeman');

	#si ce site gère les trans centralisés et si les champs sont précisés
	if($codes{shoeman_config}{gere_trans}{v1} == 1 && $codes{shoeman_config}{gere_trans_fields}{v1} ne '')
	{
		#crée les lignes manquantes pour dirmaweb et dirmawebsize(trans = 0)
		my @dirmawebs = sql_lines({dbh=>$dbh_dirmacom,select=>"Article",table=>'dirmaweb',where=>"Article NOT IN (SELECT Article FROM bugiweb_dirmaweb_trans)"});		
		log_debug("Nb de lignes manquantes dans bugiweb_dirmaweb_tran: ".($#dirmawebs+1),'','migcms_shoeman_trans');
		foreach $dirmaweb (@dirmawebs)
		{
			my %dirmaweb = %{$dirmaweb};
			
			my %bugiweb_dirmaweb_trans = (
				'Article' => $dirmaweb{Article},
			);
			log_debug('Ligne manquante dans bugiweb_dirmaweb_trans:'.$dirmaweb{Article},'','migcms_shoeman_trans');
			inserth_db($dbh_dirmacom,'bugiweb_dirmaweb_trans',\%bugiweb_dirmaweb_trans);			
		}
		log_debug('lignes manquantes dans bugiweb_dirmaweb_trans OK','','migcms_shoeman');
		log_debug('lignes manquantes dans bugiweb_dirmaweb_trans OK','','migcms_shoeman_trans');
		
		my @dirmawebs = sql_lines({dbh=>$dbh_dirmacom,select=>"Articlesize",table=>'dirmawebsize',where=>"Articlesize NOT IN (SELECT Articlesize FROM bugiweb_dirmawebsize_trans)"});		
		log_debug("Nb de lignes manquantes dans bugiweb_dirmawebsize_trans: ".($#dirmawebs+1),'','migcms_shoeman_trans');
		foreach $dirmaweb (@dirmawebs)
		{
			my %dirmaweb = %{$dirmaweb};
			
			my %bugiweb_dirmawebsize_trans = (
				'Articlesize' => $dirmaweb{Articlesize},
			);
			log_debug('Ligne manquante dans bugiweb_dirmawebsize_trans:'.$dirmaweb{Articlesize},'','migcms_shoeman_trans');
			inserth_db($dbh_dirmacom,'bugiweb_dirmawebsize_trans',\%bugiweb_dirmawebsize_trans);			
		}
		log_debug('lignes manquantes dans bugiweb_dirmawebsize_trans OK','','migcms_shoeman');
		log_debug('lignes manquantes dans bugiweb_dirmawebsize_trans OK','','migcms_shoeman_trans');
		
		
		#pour les Trans = 1, met toutes les colonnes configurées = 1, change trans = 0
		my @trans_fields = split (/\,/,$codes{shoeman_config}{gere_trans_fields}{v1});
		#récupère les produits modifiés et qui ont besoin d'être écrits.
		my @dirmawebs = sql_lines({dbh=>$dbh_dirmacom,select=>"Article",table=>'dirmaweb',where=>"Trans = 1 AND Article NOT IN (select Article from bugiweb_dirmaweb_trans where trans = 1)"});		
		log_debug("Nb de trans dans bugiweb_dirmaweb_trans: ".($#dirmawebs+1),'','migcms_shoeman_trans');
		foreach $dirmaweb (@dirmawebs)
		{
			my %dirmaweb = %{$dirmaweb};
			
			my %bugiweb_dirmaweb_trans = ();
			foreach my $trans_field (@trans_fields)
			{
				$bugiweb_dirmaweb_trans{$trans_field} = 1;
			}	
			$bugiweb_dirmaweb_trans{trans} = 1;
			$bugiweb_dirmaweb_trans{migcms_moment_last_edit} = 'NOW()';
			updateh_db($dbh_dirmacom,"bugiweb_dirmaweb_trans",\%bugiweb_dirmaweb_trans,"Article",$dirmaweb{Article});
			
			$stmt = "UPDATE dirmaweb SET Trans = 0 WHERE Article = '$dirmaweb{Article}'";
			log_debug($stmt,'','migcms_shoeman_trans');
			execstmt($dbh_dirmacom,$stmt);
		}
		log_debug('trans dans bugiweb_dirmaweb_trans OK','','migcms_shoeman');		
		log_debug('trans dans bugiweb_dirmaweb_trans OK','','migcms_shoeman_trans');		

		# récupère les tailles modifiées et qui ont besoin d'être écrites.
		my @dirmawebs = sql_lines({dbh=>$dbh_dirmacom,select=>"Articlesize",table=>'dirmawebsize',where=>"Trans = 1 AND Articlesize NOT IN (select Articlesize from bugiweb_dirmawebsize_trans where trans = 1)"});		
		log_debug("Nb de tailles modifiées et qui ont besoin d'être écrites.: ".($#dirmawebs+1),'','migcms_shoeman_trans');
		foreach $dirmaweb (@dirmawebs)
		{
			my %dirmaweb = %{$dirmaweb};
			
			my %bugiweb_dirmawebsize_trans = ();
			foreach my $trans_field (@trans_fields)
			{
				$bugiweb_dirmawebsize_trans{$trans_field} = 1;
			}	
			$bugiweb_dirmawebsize_trans{trans} = 1;
			$bugiweb_dirmawebsize_trans{migcms_moment_last_edit} = 'NOW()';
			updateh_db($dbh_dirmacom,"bugiweb_dirmawebsize_trans",\%bugiweb_dirmawebsize_trans,"Articlesize",$dirmaweb{Articlesize});
			
			$stmt = "UPDATE dirmawebsize SET Trans = 0 WHERE Articlesize = '$dirmaweb{Articlesize}'";
			log_debug($stmt,'','migcms_shoeman_trans');
			execstmt($dbh_dirmacom,$stmt);
		}
		log_debug('trans dans bugiweb_dirmawebsize_trans OK','','migcms_shoeman');				
	}
	
	log_debug('shoeman_gere_trans OK','','migcms_shoeman_trans');
	log_debug('shoeman_gere_trans OK','','migcms_shoeman');
}

sub shoeman_update_params
{
	log_debug('shoeman_update_params','','migcms_shoeman');
	
	#maj marques
	my @brands = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh_dirmacom,table=>'brand',where=>'TRANS = 1',limit=>'',ordby=>''});
	foreach $brand (@brands)
	{
		my %brand = %{$brand};
		
		#maj articles liés à cette marque (trans = 1)
		$stmt = "update dirmaweb set Trans = 1 where Brandid = '$brand{BrandNumber}'";
		execstmt($dbh_dirmacom,$stmt);	
		
		#maj marque (trans = 0)
		$stmt = "update brand set TRANS = 0 where idBrand = '$brand{idBrand}'";
		execstmt($dbh_dirmacom,$stmt);	
	}
	
	#maj params types: vérifier si ParamGroup 02 est bien standard pr types?
	my @params = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh_dirmacom,table=>'dirmawebparam',where=>"Trans = 1 AND ParamGroup='02'",limit=>'',ordby=>''});
	foreach $param (@params)
	{
		my %param = %{$param};
		
		#maj articles liés à cette marque (trans = 1)
		$stmt = "update dirmaweb set Trans = 1 where Par01id = '$param{ParamType}'";
		execstmt($dbh_dirmacom,$stmt);	
		
		#maj marque (trans = 0)
		$stmt = "update dirmawebparam set Trans = 0 where idDirmaWebParam = '$param{idDirmaWebParam}'";
		execstmt($dbh_dirmacom,$stmt);	
	}
	
	#maj params couleurs: vérifier si ParamGroup 10 est bien standard pr couleurs ?
	my @params = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh_dirmacom,table=>'dirmawebparam',where=>"Trans = 1 AND ParamGroup='10'",limit=>'',ordby=>''});
	foreach $param (@params)
	{
		my %param = %{$param};
		
		#maj articles liés à cette marque (trans = 1)
		$stmt = "update dirmaweb set Trans = 1 where Colorid = '$param{ParamType}'";
		execstmt($dbh_dirmacom,$stmt);	
		
		#maj marque (trans = 0)
		$stmt = "update dirmawebparam set Trans = 0 where idDirmaWebParam = '$param{idDirmaWebParam}'";
		execstmt($dbh_dirmacom,$stmt);	
	}	
	
	log_debug('shoeman_update_params OK','','migcms_shoeman');
}

sub shoeman_sheets
{
	log_debug('shoeman_sheets','','migcms_shoeman');

	my %code_type_shoeman_field = sql_line({select=>"t.id,t.code",table=>'migcms_code_types t',where=>"visible='y' AND code='shoeman_fields'"});
	my @shoeman_fields = sql_lines({select=>"code,id_textid_name,ordby,condition_where,v1,v2,v3,v4,v5,v6,v7",ordby=>'id',table=>'migcms_codes ',where=>"visible='y' AND id_code_type = '$code_type_shoeman_field{id}'"});

	my @dirmawebs = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh_dirmacom,table=>'dirmaweb',where=>$codes{shoeman_config}{dirmaweb_where}{v1},limit=>'',ordby=>'id desc'});
	log_debug("Nb de produits recus: ".($#dirmawebs+1),'','migcms_shoeman');

	my $nb = 1;
	foreach $dirmaweb (@dirmawebs)
	{
		my %dirmaweb = %{$dirmaweb};
		my $full_article = $dirmaweb{Article};
		
		log_debug("Traitement produit $dirmaweb{Article} : $nb / ".($#dirmawebs+1),'','migcms_shoeman_sheets');
		
		#simplifie le code Article pour certains produits (regroupement)
		if($codes{shoeman_config}{crop_all_article}{v1} == 1)
		{
			$dirmaweb{Article} = substr($dirmaweb{Article}, 0, -3);
		}
		
		#teste si la fiche existe déjà
		my %data_sheet = sql_line({table=>'data_sheets',where=>"f1='$dirmaweb{Article}'"});
		if($data_sheet{id} > 0)
		{
		}
		else
		{
			$data_sheet{visible} = 'n';
		}
		$data_sheet{taux_tva} = $codes{shoeman_config}{id_taux_tva}{v1};
		
		#crée la data_sheet
		my %data_sheet = %{shoeman_mill_data_sheet({dirmaweb=>\%dirmaweb,data_sheet=>\%data_sheet,code_type_shoeman_field=>\%code_type_shoeman_field,shoeman_fields=>\@shoeman_fields})};	
		$data_sheet{do_synchro_pics} =  1;	# -> do upload pics = 1
		$data_sheet{after_save_sheet} = 1;
		$data_sheet{modifie}='y';
		$data_sheet{migcms_moment_last_edit}='NOW()';
		%data_sheet = %{quoteh(\%data_sheet)};
				
		if($data_sheet{id} > 0)
		{
			#update	
			updateh_db($dbh,"data_sheets",\%data_sheet,"id",$data_sheet{id});
			log_debug("Maj $data_sheet{id}",'','migcms_shoeman_sheets');
		}
		else
		{
			#insert
			$data_sheet{visible} = 'n';	# -> le produit est invisible s'il n'existait pas
			$data_sheet{id} = inserth_db($dbh,'data_sheets',\%data_sheet);
			log_debug("Ajout $data_sheet{id}",'','migcms_shoeman_sheets');
		}
		
		migcms_build_data_searchs_keyword({id_data_sheet=>$data_sheet{id}});
			
		# Mettre Trans = 0 pour le produit
		$stmt = "update bugiweb_dirmaweb_trans set $sitename = 0, trans = 0 where Article = '$full_article'";
		log_debug("$stmt",'','migcms_shoeman_sheets');
		execstmt($dbh_dirmacom,$stmt);	
		
		# update trans = 1 pour les lignes stock
		$stmt = "update dirmawebsize set Trans = 1 where Articlesize LIKE '$dirmaweb{Article}%'";
		log_debug("$stmt",'','migcms_shoeman_sheets');	
		execstmt($dbh_dirmacom,$stmt);	
		
		$nb++;
	}
	
	#calcule les sheets activables qui ont changé
	set_sheet_activable();
	
	#pour les sheets activables, traite les liens catégories/seo 
	after_save_sheets();
	
	#recalcule l'ordby sur mesure
	def_handmade::shoeman_sheets_ordby();	
	
	log_debug('shoeman_sheets OK','','migcms_shoeman');
}

sub shoeman_stock
{
	log_debug('shoeman_stock','','migcms_shoeman');
	log_debug('shoeman_stock','','migcms_shoeman_stock');
	
	my %tailles = %{get_shoeman_tailles()};
	my %sheets = %{get_shoeman_sheets()};
	my %stocks = %{get_shoeman_stocks()};
	my %stocks_tarifs = %{get_shoeman_stocks_tarifs()};
	
	#liaison dirmaweb + dirmawebsize pour obtenir groupeid
	my @dirmawebsizes = sql_lines({debug=>0,debug_results=>0,dbh=>$dbh_dirmacom,select=>"dirmawebsize.*,dirmaweb.Groupeid",where=>"$codes{shoeman_config}{dirmawebsize_where}{v1} $codes{shoeman_config}{dirmawebsize_where}{v2}",table=>'dirmawebsize,dirmaweb',limit=>'',ordby=>'Articlesize ASC'});
	log_debug("Nb de stock recus: ".($#dirmawebsizes+1),'','migcms_shoeman_stock');
	
	#boucle sur DIRMAWEB+DIRMAWEBSIZE
	my $c = 0;
	
	foreach $dirmawebsize (@dirmawebsizes)
	{
		my %dirmawebsize = %{$dirmawebsize};
		$c++;
		my $full_article = $dirmawebsize{Article};
		
		#simplifie le code Article pour certains produits (regroupement)
		if($codes{shoeman_config}{crop_all_article}{v1} == 1)
		{
			$dirmawebsize{Article} = substr($dirmawebsize{Article}, 0, -3);
		}

		#créer catégorie taille si elle n'existe pas
		$dirmawebsize{Size} = mill_crit($dirmawebsize{Size});
		log_debug("Stock $c / ".($#dirmawebsizes+1).":".$dirmawebsize{Articlesize}.':'.$dirmawebsize{Size},'','migcms_shoeman_stock');	
		if($dirmawebsize{Size} eq '')
		{
			log_debug("Taille vide -> suivant",'','migcms_shoeman_stock');	
			$stmt = "update bugiweb_dirmawebsize_trans set $sitename = 0, trans = 0 where Articlesize = '$dirmawebsize{Articlesize}'";
			log_debug("$stmt",'','migcms_shoeman_stock');		
			execstmt($dbh_dirmacom,$stmt);
			next;
		}
		
		#lit la sheet liée à l'article
		my $id_data_sheet = $sheets{lc($dirmawebsize{Article})};
		if(!($id_data_sheet > 0))
		{
			log_debug("Pas de sheet pour f1 = $dirmawebsize{Article}",'','migcms_shoeman_stock');
			$stmt = "update bugiweb_dirmawebsize_trans set $sitename = 0, trans = 0 where Articlesize LIKE '$dirmawebsize{Article}%'";
			log_debug("$stmt",'','migcms_shoeman_stock');		
			execstmt($dbh_dirmacom,$stmt);
			next;
		}
			
		#lit la catégorie liée à la taille
		my $id_data_category = $tailles{$dirmawebsize{Size}};
		if(!($id_data_category > 0))
		{
			log_debug("Pas de catégorie pour f1 = $dirmawebsize{Size}",'','migcms_shoeman_stock');
			 
			$id_data_category = sync_category({variante=>'y',id_data_family=>$id_data_family,id_father=>$id_father_cat_tailles{v1},lg1=>$dirmawebsize{Size},lg2=>$dirmawebsize{Size},lg3=>$dirmawebsize{Size},lg4=>$dirmawebsize{Size},type_cat=>'pointure'});
			
			#recharge les tailles depuis l'ajout
			%tailles = %{get_shoeman_tailles()};
		}
	
		# recreer les liaisons supprimées précédemment
		my %data_sheet = ();
		$data_sheet{id} = $id_data_sheet;
		add_lnk_category_for_sheet({data_sheet=>\%data_sheet,id_data_category=>$id_data_category});
		
		#créer data_stock s'il n'existe pas: id_data_category + id_data_sheet 
		my $id_data_stock = $stocks{$dirmawebsize{Articlesize}};
		if(!($id_data_stock > 0))
		{
			log_debug("Pas de stock pour reference = $dirmawebsize{Articlesize}",'','migcms_shoeman_stock');
			my %new_data_stock = 
			(
				id_data_sheet => $id_data_sheet,
				id_data_category => $id_data_category,
				stock => $dirmawebsize{Stock},
				reference => $dirmawebsize{Articlesize},
			);
			$id_data_stock = inserth_db($dbh,'data_stock',\%new_data_stock);			
		}
		else
		{
			log_debug("Maj du stock $id_data_stock trouve pour reference $dirmawebsize{Articlesize}",'','migcms_shoeman_stock');
			my %update_data_stock = 
			(
				id_data_sheet => $id_data_sheet,
				id_data_category => $id_data_category,
				stock => $dirmawebsize{Stock},
				reference => $dirmawebsize{Articlesize},
			);
			updateh_db($dbh,"data_stock",\%update_data_stock,"id",$id_data_stock);
		}

		#créer data_stock_tarif s'il n'existe pas id data_stock, id _tarif (1) id _data_sheet
		my $id_data_stock_tarif = $stocks_tarifs{$id_data_stock};
		
		#si prix lu = prix tvac
		my $st_pu_htva = $dirmawebsize{Price} / (1 + $taux_tva);
		my $st_pu_tva = ($dirmawebsize{Price} / (1 + $taux_tva)) * $taux_tva;
		my $st_pu_tvac = $dirmawebsize{Price};
		
		my $st_pu_htva_discounted = $dirmawebsize{PriceSale} / (1 + $taux_tva);
		my $st_pu_tva_discounted = ($dirmawebsize{PriceSale} / (1 + $taux_tva)) * $taux_tva;
		my $st_pu_tvac_discounted = $dirmawebsize{PriceSale};
		
		#si prix lu = prix htva
		if($codes{shoeman_config}{import_htva}{v1} == 1)
		{
			$st_pu_htva = $dirmawebsize{Price};
			$st_pu_tva = $dirmawebsize{Price} * $taux_tva;
			$st_pu_tvac =  $st_pu_htva + $st_pu_tva;

			$st_pu_htva_discounted = $dirmawebsize{PriceSale};
			$st_pu_tva_discounted = $dirmawebsize{PriceSale} * $taux_tva;
			$st_pu_tvac_discounted = $st_pu_htva_discounted + $st_pu_tva_discounted;
		}
		
		my $taux = 0;

		if($dirmawebsize{PriceSale} > 0 && $dirmawebsize{Price} > 0)
		{
			if($codes{shoeman_config}{taux_arrond}{v1} eq 'y')
			{
				$taux = 100 * abs(1 - ($dirmawebsize{PriceSale} / $dirmawebsize{Price}));
				$taux   = int($taux + 0.5);
			}
			else
			{
				$taux = 100 * abs(1 - ($dirmawebsize{PriceSale} / $dirmawebsize{Price}));
			}
			
			#associe la sheet aux bonnes affaires et soldes
			# if($codes{shoeman_config}{cat_soldes}{v1} > 0)
			# {
				# add_lnk_category_for_sheet({data_sheet=>\%data_sheet,id_data_category=>$codes{shoeman_config}{cat_soldes}{v1}});
			# }
			# if($codes{shoeman_config}{cat_prix_ronds}{v1} > 0)
			# {
				# add_lnk_category_for_sheet({data_sheet=>\%data_sheet,id_data_category=>$codes{shoeman_config}{cat_soldes}{v1}});
			# }
		}
		
		if(!($id_data_stock_tarif > 0))
		{
			log_debug("Pas de stock tarif pour id_data_stock = $id_data_stock",'','migcms_shoeman_stock');
			my %new_data_stock_tarif = 
			(
				id_data_sheet => $id_data_sheet,
				id_data_stock => $id_data_stock,
				id_tarif => 1,
				st_pu_htva => $st_pu_htva,
				st_pu_tva => $st_pu_tva,
				st_pu_tvac => $st_pu_tvac,
				st_pu_htva_discounted => $st_pu_htva_discounted,
				st_pu_tva_discounted => $st_pu_tva_discounted,
				st_pu_tvac_discounted => $st_pu_tvac_discounted,
				taux => $taux,
				taux_tva => $taux_tva,
			);
			$id_data_stock_tarif = inserth_db($dbh,'data_stock_tarif',\%new_data_stock_tarif);			
		}
		else
		{
			log_debug("Maj du stock tarif $id_data_stock_tarif trouve pour stock $id_data_stock",'','migcms_shoeman_stock');
			my %update_data_stock_tarif = 
			(
				id_data_sheet => $id_data_sheet,
				id_data_stock => $id_data_stock,
				id_tarif => 1,
				st_pu_htva => $st_pu_htva,
				st_pu_tva => $st_pu_tva,
				st_pu_tvac => $st_pu_tvac,
				st_pu_htva_discounted => $st_pu_htva_discounted,
				st_pu_tva_discounted => $st_pu_tva_discounted,
				st_pu_tvac_discounted => $st_pu_tvac_discounted,
				taux => $taux,
				taux_tva => $taux_tva,
			);
			updateh_db($dbh,"data_stock_tarif",\%update_data_stock_tarif,"id",$id_data_stock_tarif);
		}
		
		$stmt = "update bugiweb_dirmawebsize_trans set $sitename = 0, trans = 0 where Articlesize = '$dirmawebsize{Articlesize}'";
		log_debug("$stmt",'','migcms_shoeman_stock');		
		execstmt($dbh_dirmacom,$stmt);
		
		#nettoyer le cache detail
		my $detail_cache_path = $codes{shoeman_config}{cache_detail_path}{v1};
		log_debug("nettoyage $detail_cache_path",'','migcms_shoeman_stock');	
		if(-e $detail_cache_path)
		{
			opendir (MYDIR, $detail_cache_path) || die ("cannot LS $detail_cache_path");
			my @files_array = readdir(MYDIR);
			closedir (MYDIR);
			log_debug("nettoyage $detail_cache_path OK",'','migcms_shoeman_stock');	
		}
		else
		{
			# log_debug("nettoyage KO: $detail_cache_path n'existe pas",'','migcms_shoeman_stock');	
		}
		
		foreach my $file (@files_array) 
		{
			my $full_name = "$detail_cache_path/$file";
			my $reg = $id_data_sheet.'-1.html';
			# print '<br />fullname'.$full_name;
			# print '<br />reg:'.$reg;
			
			log_debug("nettoyage FILE $full_name",'','migcms_shoeman_stock');	
			log_debug("REG $reg",'','migcms_shoeman_stock');	

			if($file =~ /$reg/ && $detail_cache_path ne '' && $file ne '' && $file ne '.' && $file ne '..' && -e $full_name)
			{
				unlink($full_name);
				log_debug("nettoyage FILE $full_name OK",'','migcms_shoeman_stock');	
			}
		}
	}
	
	log_debug('shoeman_stock OK','','migcms_shoeman');
	log_debug('shoeman_stock OK','','migcms_shoeman_stock');
}


sub set_stock_activable
{
	log_debug('set_stock_activable','','migcms_shoeman');
	
	my @data_sheets = sql_lines({select=>"id",table=>'data_sheets',where=>"sheet_activable = '1'"});
	log_debug("set_stock_activable: Nb de sheets traitées: ".($#data_sheets+1),'','migcms_shoeman');
	
	foreach $data_sheet (@data_sheets)
	{
		my %data_sheet = %{$data_sheet};
		
		my $stock_activable = 0;
		my $raison = '';

		my %nb_prix = sql_line({debug=>0,debug_results=>0,dhb=>$dbh,table=>'data_stock_tarif',select=>"count(*) as nb",where=>"st_pu_tvac > 0.5 AND id_data_sheet = '$data_sheet{id}'"});
		if($nb_prix{nb} > 0)
		{
			#SI STOCK
			my %total_stock = sql_line({debug=>0,dhb=>$dbh,table=>'data_stock',select=>"sum(stock) as total",where=>"id_data_sheet = '$data_sheet{id}'"});
			if($total_stock{total} > 0)
			{
				$raison = '';
				$stock_activable = 1;
				
				shoeman_compute_col_price(1,$data_sheet{id});
			}
			else
			{
				$raison = 'Pas de stock';
			}							
		}
		else
		{
			$raison = 'Pas de prix';
		}		
		
		$stmt = "update data_sheets SET stock_activable = '$stock_activable', $colonne_log = '$raison' where id = '$data_sheet{id}'";
		log_debug($stmt,'','migcms_shoeman_sheets');
		execstmt($dbh,$stmt);
	}	
	
	log_debug('set_stock_activable OK','','migcms_shoeman');
}


sub set_sheets_prix_reduits
{
	log_debug('set_sheets_prix_reduits','','migcms_shoeman');
	my $id_cat_prix_reduit = 0;
	if($codes{shoeman_config}{cat_soldes}{v1} > 0)
	{
		$id_cat_prix_reduit = $codes{shoeman_config}{cat_soldes}{v1};
		my $stmt = "DELETE FROM `data_lnk_sheets_categories` WHERE id_data_category = '$id_cat_prix_reduit'";  
		log_debug($stmt,'','set_sheets_prix_reduits');
		execstmt($dbh,$stmt);
		
		my @data_sheets = sql_lines({select=>"sh.id,sh.id_data_family",table=>'data_sheets sh, data_stock_tarif dst',where=>"dst.id_data_sheet = sh.id AND dst.taux > 0",groupby=>"id_data_sheet"});
		foreach $data_sheet (@data_sheets)
		{
			my %data_sheet = %{$data_sheet};
			add_lnk_category_for_sheet({data_sheet=>\%data_sheet,id_data_category=>$id_cat_prix_reduit});	
			log_debug("ADD lnk solde: $data_sheet{id},$id_cat_prix_reduit",'','set_sheets_prix_reduits');
		}
	}
	my $id_cat_pas_prix_reduit = 0;
	if($codes{shoeman_config}{cat_pas_soldes}{v1} > 0)
	{
		$id_cat_pas_prix_reduit = $codes{shoeman_config}{cat_pas_soldes}{v1};
		my $stmt = "DELETE FROM `data_lnk_sheets_categories` WHERE id_data_category = '$id_cat_pas_prix_reduit'";
		log_debug($stmt,'','set_sheets_prix_reduits');
		execstmt($dbh,$stmt);


		my @data_sheets = sql_lines({select=>"sh.id,sh.id_data_family",table=>'data_sheets sh, data_stock_tarif dst',where=>"dst.id_data_sheet = sh.id AND dst.taux = 0",groupby=>"id_data_sheet"});
		foreach $data_sheet (@data_sheets)
		{
			my %data_sheet = %{$data_sheet};
			add_lnk_category_for_sheet({data_sheet=>\%data_sheet,id_data_category=>$id_cat_pas_prix_reduit});
			log_debug("ADD lnk pas solde: $data_sheet{id},$id_cat_pas_prix_reduit",'','set_sheets_prix_reduits');
		}
	}
	log_debug('set_sheets_prix_reduits OK','','migcms_shoeman');
}

sub compute_id_data_categories
{
	log_debug('compute_id_data_categories','','migcms_shoeman_sheets');
	
	# my @data_lnk_sheets_categories = sql_lines({select=>"lnk.id_data_sheet,lnk.id_data_category",table=>'data_lnk_sheets_categories lnk, data_categories c',where=>"lnk.id_data_category = c.id AND c.f19 != '1'"});
	my @data_lnk_sheets_categories = sql_lines({select=>"id_data_sheet,id_data_category",table=>'data_lnk_sheets_categories',where=>""});
	
	my %hash_data_sheets_categories = ();
	
	foreach $data_lnk_sheets_category (@data_lnk_sheets_categories)
	{
		my %data_lnk_sheets_category = %{$data_lnk_sheets_category};	
		$hash_data_sheets_categories{$data_lnk_sheets_category{id_data_sheet}} .= ','.$data_lnk_sheets_category{id_data_category}.',';		
	}
	
	foreach $id_data_sheet (keys %hash_data_sheets_categories)
	{
		$stmt = "update data_sheets set id_data_categories = '$hash_data_sheets_categories{$id_data_sheet}' where id = '$id_data_sheet'";
		log_debug($stmt,'','compute_id_data_categories');

		execstmt($dbh,$stmt);					
	}
	
	$stmt = "update data_stock set ordby = id";
	execstmt($dbh,$stmt);					

	log_debug('compute_id_data_categories OK','','migcms_shoeman_sheets');
}

sub compute_id_data_categories_filters
{
	if($codes{shoeman_config}{create_filter_categories}{v1} eq 'y')
	{
		log_debug('compute_id_data_categories_filters','','migcms_shoeman_sheets');
		
		my @data_categories_filters = sql_lines({select=>"id,f13,id_father",table=>'data_categories',where=>"f19='1'"});
		
		my @data_sheets = sql_lines({select=>"id,id_data_categories,id_data_family",table=>'data_sheets',where=>"$sheets_where AND visible='y'"});
		
		foreach $data_categories_filter (@data_categories_filters)
		{
			my %data_categories_filter = %{$data_categories_filter};
			
			#f13 = categorie testée (ex: noir)
			#id_father = parent (ex: dame)
			
			#trouver une sheet qui correspond et l'associer à la catégorie
			foreach $data_sheet (@data_sheets)
			{
				my %data_sheet = %{$data_sheet};
				# log_debug("$data_sheet{id_data_categories} =~ /\,$data_categories_filter{f13}\,/ && $data_sheet{id_data_categories} =~ /\,$data_categories_filter{id_father}\,/",'','compute_id_data_categories_filters');

				if($data_sheet{id_data_categories} =~ /,$data_categories_filter{f13},/ && $data_sheet{id_data_categories} =~ /,$data_categories_filter{id_father}\,/)
				{
					#trouve
					log_debug("TROUVE: shid: $data_sheet{id} f13: $data_categories_filter{f13}, id_father: $data_categories_filter{id_father}",'','compute_id_data_categories_filters');
					
					add_lnk_category_for_sheet({data_sheet=>\%data_sheet,id_data_category=>$data_categories_filter{id}});
					last; #pas besoin de continuer, une suffit
				}			
			}		
		}
		log_debug('compute_id_data_categories_filters OK','','migcms_shoeman_sheets');
	}
}



sub fill_categories_name
{
	log_debug('fill_categories_name','','migcms_shoeman');	
    
	compute_cat_denomination(0,'');
	# edit_db_sort_tree_recurse(0); 
	
	log_debug('fill_categories_name OK','','migcms_shoeman');	
}

sub shoeman_photos
{
	log_debug('shoeman_photos','','migcms_shoeman');
	
	my @sheet_pic_fields = ();
	foreach my $num (1 .. 8)
	{
		my %picture_field = sql_line({table=>'migcms_codes',where=>"code='Picture$num'"});
		push @sheet_pic_fields, $picture_field{v2};
	}
	
	my @data_sheets = sql_lines({table=>'data_sheets',where=>"do_synchro_pics = '1' AND sheet_activable = '1' AND stock_activable = '1'"});
	log_debug("shoeman_photos: Nb de sheets traitées: ".($#data_sheets+1),'','migcms_shoeman');
	
	foreach $data_sheet (@data_sheets)
	{
		my %data_sheet = %{$data_sheet};
		my $nb_photos = 0;
		my $photos_activable = 0;
		my $raison = 'Pas assez de photos';
		
		#creation répertoire cible si necessaire
		my $dir = $config{directory_path}.$path_dossier_photos .$data_sheet{id};
		unless (-d $dir) {mkdir($dir.'/') or log_debug("cannot create ".$dir.": $!");}
		
		#nettoyage photos précédentes
		shoeman_clean_linked_files('data_sheets',$data_sheet{id});
		
		my $ordby = 1;
		foreach my $sheet_pic_field (@sheet_pic_fields)
		{	
			#pour chaquephoto
			if($data_sheet{$sheet_pic_field} eq '')
			{
				log_debug("$data_sheet{f1}: $sheet_pic_field : VIDE",'','migcms_shoeman_photos');
				next;
			}
			my @tabext = split(/\./,$data_sheet{$sheet_pic_field});
			my $ext = '.'.$tabext[$#tabext];
			pop @tabext;
			my $filename_without_ext = join(",",@tabext);

			#ajout du linked_files
			my %new = (
			'table_name'=>'data_sheets',
			'table_field'=>'photos',
			'do_not_resize'=>'n',
			'token'=>$data_sheet{id},
			'full'=>$filename_without_ext,
			'ordby'=>$ordby++,			
			'visible'=>'y',
			'ext'=>$ext,
			'file_dir'=>'..'.$path_dossier_photos.$data_sheet{id},
			);
			
			%new = %{quoteh(\%new)};
			my $id_migcms_linked_file = sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_linked_files',data=>\%new, where=>"id='$new{id}'"});
			my %migcms_linked_file = read_table($dbh,'migcms_linked_files',$id_migcms_linked_file);
			log_debug("$data_sheet{f1}: $sheet_pic_field : $data_sheet{$sheet_pic_field} : ajouter sur $id_migcms_linked_file",'','migcms_shoeman_photos');
			
			#copie l'originale dans le dossier photo du produit
			my $full = $data_sheet{$sheet_pic_field};
			log_debug("$path_dirmacom / $full -> ".$path_pics.$path_dossier_photos.$data_sheet{id}.'/'.$full,'','migcms_shoeman_photos');
			
			copy("$path_dirmacom/$full",$path_pics.$path_dossier_photos .$data_sheet{id}.'/'.$full);
			
			#resize l'image
			shoeman_resize_sheet_pics({id_data_family=>$data_sheet{id_data_family},id_data_sheet=>$data_sheet{id}});
			
			$nb_photos++;
        }
		
		if($nb_photos > 1)
		{
			$photos_activable = 1;
			$raison = '';
		}
		
		$stmt = "update data_sheets SET do_synchro_pics = '0', photos_activable = '$photos_activable', $colonne_log = '$raison' where id = '$data_sheet{id}'";
		log_debug($stmt,'','migcms_shoeman_sheets');
		execstmt($dbh,$stmt);
	}
	
	if($#data_sheets > -1)
	{
		#cas de la photo d'un produit qui change...
		remove_tree( '../cache/site/data/list', {keep_root => 1} );
		remove_tree( '../cache/site/data/detail', {keep_root => 1} );
	}
	
	log_debug('shoeman_photos OK','','migcms_shoeman');
}

sub shoeman_visibility
{
	log_debug('shoeman_visibility','','migcms_shoeman');
	
	my $changement = 0;
	
	#cachees mais affichables (sheet,stock,photo ok)	
	my @data_sheets = sql_lines({select=>"id",table=>'data_sheets',where=>"visible='n' AND (sheet_activable = '1' AND stock_activable = '1' AND photos_activable='1')"});
	foreach $data_sheet (@data_sheets)
	{
		my %data_sheet = %{$data_sheet};

		$stmt = "update data_sheets SET visible = 'y' where id = '$data_sheet{id}'";		
		log_debug($stmt,'','migcms_shoeman_visible');
		execstmt($dbh,$stmt);
		
		$changement = 1;
	}
	
	#affichées mais à cacher (!sheet,stock,photo ok)	
	my @data_sheets = sql_lines({select=>"id",table=>'data_sheets',where=>"visible='y' AND (sheet_activable != '1' OR stock_activable != '1' OR photos_activable != '1')"});
	foreach $data_sheet (@data_sheets)
	{
		my %data_sheet = %{$data_sheet};
		$stmt = "update data_sheets SET visible = 'n' where id = '$data_sheet{id}'";
		log_debug($stmt,'','migcms_shoeman_visible');
		execstmt($dbh,$stmt);
		
		$changement = 1;
	}
	if($changement == 1)
	{
		#supprimer cache listing + detail
		remove_tree( '../cache/site/data/list', {keep_root => 1} );
		remove_tree( '../cache/site/data/detail', {keep_root => 1} );
	}

	#reporte les prix minimum pour les sheets visibles (pr le tri)
	$stmt = "update data_sheets sh SET price = (select MIN(st_pu_tvac_discounted) from data_stock_tarif where id_data_sheet = sh.id AND st_pu_tvac_discounted > 0) WHERE visible='y'";
	log_debug($stmt,'','migcms_shoeman_visible');
	execstmt($dbh,$stmt);
	$stmt = "update data_sheets sh SET price = (select MIN(st_pu_tvac) from data_stock_tarif where id_data_sheet = sh.id AND st_pu_tvac > 0) WHERE price = 0 AND visible='y'";
	log_debug($stmt,'','migcms_shoeman_visible');
	execstmt($dbh,$stmt);
	
	log_debug('shoeman_visibility OK','','migcms_shoeman');
}

sub shoeman_resize_sheet_pics
{
	log_debug('shoeman_resize_sheet_pics','','migcms_shoeman_photos');
	
	my %d = %{$_[0]};
	if($d{table_field} eq '')
	{
		$d{table_field} = 'photos';
	}
	my %data_family = read_table($dbh,"data_families",$d{id_data_family});

	my @sizes = ('large','small','medium','mini','og');
	
	#boucle sur les images du paragraphes
	my @migcms_linked_files = sql_lines({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='data_sheets' AND table_field='$d{table_field}' AND token='$d{id_data_sheet}'",ordby=>'ordby'});
	foreach $migcms_linked_file (@migcms_linked_files)
	{
		#appelle la fonction de redimensionnement
		my %migcms_linked_file = %{$migcms_linked_file};
		my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
		my %params = (
			migcms_linked_file=>\%migcms_linked_file,
			do_not_resize=>'n',
		);
		foreach my $size (@sizes)
		{
			$params{'size_'.$size} = $data_family{$size.'_width'};
		}
		shoeman_resize_pic(\%params);
	}

	log_debug('shoeman_resize_sheet_pics OK','','migcms_shoeman_photos');
}

sub shoeman_resize_pic
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

sub get_shoeman_tailles
{
	log_debug('get_shoeman_tailles','','migcms_shoeman_stock');
	
	my %tailles = ();
	
	my @data_categories = sql_lines({table=>'data_categories',where=>"id_father='$id_father_cat_tailles{v1}'"});
	foreach my $data_category (@data_categories)
	{
		my %data_category = %{$data_category};
		$tailles{$data_category{f1}} = $data_category{id};		
	}

	log_debug('get_shoeman_tailles OK','','migcms_shoeman_stock');
	
	return \%tailles;
}

sub get_shoeman_sheets
{
	my %sheets = ();
	
	log_debug('get_shoeman_sheets','','migcms_shoeman_stock');
	
	my @data_sheets = sql_lines({table=>'data_sheets',where=>"f1 != ''"});
	foreach my $data_sheet (@data_sheets)
	{
		my %data_sheet = %{$data_sheet};
		$sheets{lc($data_sheet{f1})} = $data_sheet{id};		
	}
	
	log_debug('get_shoeman_sheets OK','','migcms_shoeman_stock');

	return \%sheets;
}

sub get_shoeman_stocks
{
	my %stocks = ();
	
	log_debug('get_shoeman_stocks','','migcms_shoeman_stock');
	
	my @data_stocks = sql_lines({table=>'data_stock',where=>"reference != ''"});
	foreach my $data_stock (@data_stocks)
	{
		my %data_stock = %{$data_stock};
		$stocks{$data_stock{reference}} = $data_stock{id};		
	}
	
	log_debug('get_shoeman_stocks OK','','migcms_shoeman_stock');

	return \%stocks;
}

sub get_shoeman_stocks_tarifs
{
	my %stocks_tarifs = ();
	
	log_debug('get_shoeman_stocks_tarifs','','migcms_shoeman_stock');
	
	my @data_stocks_tarifs = sql_lines({table=>'data_stock_tarif',where=>"id_data_stock > 0"});
	foreach my $data_stocks_tarif (@data_stocks_tarifs)
	{
		my %data_stocks_tarif = %{$data_stocks_tarif};
		$stocks_tarifs{$data_stocks_tarif{id_data_stock}} = $data_stocks_tarif{id};		
	}
	
	log_debug('get_shoeman_stocks_tarifs OK','','migcms_shoeman_stock');

	return \%stocks_tarifs;
}

sub shoeman_compute_col_price
{
	log_debug('shoeman_compute_col_price','','migcms_shoeman_sheets');

	my $id_tarif = $_[0];
	my $id_data_sheet = $_[1];
	
	# %lowest_data_stock_tarif = sql_line({debug=>0,debug_results=>0,table=>"data_stock_tarif dst, data_stock ds",select=>"",ordby=>"st_pu_tvac asc",limit=>'0,1',where=>"st_pu_tvac >0 AND dst.id_data_stock = ds.id AND dst.id_tarif = '1' AND dst.id_data_sheet = '$data_sheet{id}' AND stock > 0"});
	%lowest_data_stock_tarif = sql_line({debug=>0,debug_results=>0,table=>"data_stock_tarif",select=>"st_pu_htva,st_pu_tva,st_pu_tvac",ordby=>"st_pu_tvac asc",limit=>'0,1',where=>"st_pu_tvac >0 AND id_tarif = '$id_tarif' AND id_data_sheet = '$id_data_sheet'"});
	%sheet_prices = %{eshop::get_product_prices({from=>'data',debug=>0,generation=>'n',data_sheet=>\%data_sheet,data_stock_tarif=>\%lowest_data_stock_tarif})};
	$total_discount_tvac = $sheet_prices{price_discounted_tvac};
	$stmt = "update data_sheets SET price = '$total_discount_tvac' where id = '$id_data_sheet'";
	log_debug($stmt,'','migcms_shoeman_stock');	
	execstmt($dbh,$stmt);
	
	log_debug('shoeman_compute_col_price OK','','migcms_shoeman_sheets');
}


sub shoeman_mill_data_sheet
{
	log_debug('shoeman_mill_data_sheet','','migcms_shoeman_sheets');
	
	my %d = %{$_[0]};
	my %dirmaweb = %{$d{dirmaweb}};
	my %data_sheet =  %{$d{data_sheet}};
	my %code_type_shoeman_field = %{$d{code_type_shoeman_field}};
	my @shoeman_fields = @{$d{shoeman_fields}};

	#boucle sur les champs shoeman encodés
	foreach $shoeman_field (@shoeman_fields)
	{
		my %shoeman_field = %{$shoeman_field};
		

		my @actions = split (/\+/,$shoeman_field{v3});
		foreach my $action_elt (@actions)
		{
		   	my ($action,$precision) = split('\*', $action_elt);
			
			#actions sur chaque champps
			if($action eq 'valeur')
			{
				#recopier la valeur de dirmaweb
				if($shoeman_field{v1} =~ /Picture/)
				{
					$data_sheet{$shoeman_field{v2}} = $dirmaweb{$shoeman_field{v1}};
				}
				else
				{
					$data_sheet{$shoeman_field{v2}} = ucfirst(lc($dirmaweb{$shoeman_field{v1}}));
				}
			}
			elsif($action eq 'default')
			{		
				#valeur par défaut du code
				$data_sheet{$shoeman_field{v2}} = $shoeman_field{v1};

			}
			elsif($action eq 'liens')
			{
				#génére des hyperliens si necessaire
				if ($data_sheet{$shoeman_field{v2}} =~ /http:/) 
				{
					$data_sheet{$shoeman_field{v2}} =~ s/(http:[^\s]*)/<a href="$1">$1<\/a>/gis;
				}
			}
			elsif($action eq 'saison')
			{
				if($data_sheet{$shoeman_field{v2}} =~ /01$/)
				{
					$data_sheet{$shoeman_field{v1}} = 'Printemps-été';
					$data_sheet{$shoeman_field{v4}} = 'Printemps-été|Printemps-été|Printemps-été|Printemps-été';
				}
				elsif($data_sheet{$shoeman_field{v2}} =~ /02$/)
				{
					$data_sheet{$shoeman_field{v1}} = 'Automne-hiver';
					$data_sheet{$shoeman_field{v4}} = 'Automne-hiver|Automne-hiver|Automne-hiver|Automne-hiver';
				}
			}
			elsif($action eq '10ouinon')
			{
				if($data_sheet{$shoeman_field{v2}} == 1)
				{
					$data_sheet{$shoeman_field{v2}} = 'Oui';
				}
				elsif($data_sheet{$shoeman_field{v2}} == 0)
				{
					$data_sheet{$shoeman_field{v2}} = 'Non';
				}
			}
			elsif($action eq 'condition')
			{
				#valeur selon condition (precision)
				#attention: avec une valeur de data_sheet précédemment encodée et avec une valeur chiffrée seulement sinon prévoir extension logique...
				#ex: condition*f27=0900001:chaussure,f27=0900023:chaussure,f27=0900022:chaussure,f27=0900021:vetement non gérée !
				my $trouve = 0;
				
				my @conditions = split('\,', $precision);
				foreach my $condition (@conditions)
				{
					# f27=0900023:chaussure
					my ($champ_referent,$retour) = split('\=', $condition);
					my ($retour_condition,$retour_resultat) = split('\:', $retour);
					
					if($data_sheet{$champ_referent} == $retour_condition)
					{
						$data_sheet{$shoeman_field{v2}} = ucfirst(lc($retour_resultat));
						$trouve = 1;
					}
				}
			}
			elsif($action eq 'table')
			{
				my %shoeman_rec = sql_line({dbh=>$dbh_dirmacom,debug=>0,debug_results=>0,table=>$shoeman_field{v4},where=>"$shoeman_field{v5}='$dirmaweb{$shoeman_field{v1}}'"});
				$data_sheet{$shoeman_field{v2}} = ucfirst(lc($shoeman_rec{$shoeman_field{v6}}));
			}
			elsif($action eq '4x')
			{
				my ($field4x1,$field4x2,$field4x3,$field4x4) = split('\+', $shoeman_field{v7});
				if($field4x1 eq '' || $field4x2 eq '' || $field4x3 eq '' || $field4x4 eq '')
				{
					print "<b>précider les 4 champs ! pour $shoeman_field{code}</b>";
				}
				else
				{				
					if($shoeman_field{v4} ne '')
					{
						my %shoeman_rec = sql_line({debug=>1,debug_results=>1,dbh=>$dbh_dirmacom,table=>$shoeman_field{v4},where=>"$shoeman_field{v5}='$dirmaweb{$shoeman_field{v1}}'"});
						$data_sheet{$shoeman_field{v2}} = ucfirst(lc($shoeman_rec{$field4x1})).'|'.ucfirst(lc($shoeman_rec{$field4x2})).'|'.ucfirst(lc($shoeman_rec{$field4x3})).'|'.ucfirst(lc($shoeman_rec{$field4x4}));	
					}
					else
					{
						$data_sheet{$shoeman_field{v2}} = ucfirst(lc($dirmaweb{$field4x1})).'|'.ucfirst(lc($dirmaweb{$field4x2})).'|'.ucfirst(lc($dirmaweb{$field4x3})).'|'.ucfirst(lc($dirmaweb{$field4x4}));	
					}
				}
			}
			elsif($action eq 'dusart_genre')
			{
				if($data_sheet{f38} eq '0900007' || $data_sheet{f38} eq '0900024')
				{
					$data_sheet{f5} = 'Accessoire';
					$data_sheet{f6} = 'Accessoire|Accessoire|Accessoire|Accessoire';
				}
			}
			else
			{
				print "<hr />";
				print '<pre>';
				see(\%shoeman_field);
				print '</pre>';
				print "<br><b>$action non gérée !</b>";
			}
		}
	}
	
	log_debug('shoeman_mill_data_sheet OK','','migcms_shoeman_sheets');
	
	return \%data_sheet;
}

sub clean_lnk_categories_for_sheet
{
	log_debug('clean_lnk_categories_for_sheet','','migcms_shoeman_sheets');
	
	my %d = %{$_[0]};
	my %data_sheet =  %{$d{data_sheet}};
	
	
	my $stmt = "DELETE FROM `data_lnk_sheets_categories` WHERE id_data_sheet = '$data_sheet{id}'";  
	log_debug($stmt,'','migcms_shoeman_cats');
	my $cursor = $dbh->prepare($stmt) || die("CANNOT PREPARE $stmt");
	$cursor->execute || suicide($stmt);
	
	log_debug('clean_lnk_categories_for_sheet OK','','migcms_shoeman_sheets');

}

sub sync_category
{
	log_debug('sync_category','','migcms_shoeman_sheets');
	
	my %d = %{$_[0]};
	
	my $variante = 'n';
	if($d{variante} eq 'y')
	{
		$variante = 'y';
	}
	
	my  %update_category = 
	(
		visible => 'y',
		id_father => $d{id_father},
		id_data_family => $d{id_data_family},
		variante => $variante,
	);
	my %update_category_url = ();
	my $id_data_category = 0;
	
	#boucler sur les langues actives
	foreach $language (@languages)
	{
		my %language = %{$language};
		
		if($d{'lg'.$language{id}} eq '')
		{
			log_debug('Catégorie vide en '.$language{id}.'('.$d{lg1}.') -> suivant','','migcms_shoeman_cats');
			next;
		}
		
		#placer la traduction dans la colonne fx
		$update_category{'f'.$language{id}} = ucfirst($d{'lg'.$language{id}});
		$d{'lg'.$language{id}} =~ s/\\\'/\'/g;
		if($language{id} == 1)
		{
			$d{'lg'.$language{id}} =~ s/\./point/g;
			$d{'lg'.$language{id}} =~ s/\,/virgule/g;
		}
		else
		{
			$d{'lg'.$language{id}} =~ s/\./dot/g;
			$d{'lg'.$language{id}} =~ s/\,/comma/g;
		}		
		$update_category_url{'f'.$language{id}} = clean_url($d{'lg'.$language{id}});
		$update_category_url{'f'.$language{id}} =~ s/\'//g;
		$update_category{f10} = $d{type_cat};		
		
		%update_category = %{quoteh(\%update_category)};
		%update_category_url = %{quoteh(\%update_category_url)};
		
		log_debug('Catégorie:'.$update_category{'f'.$language{id}},'','migcms_shoeman_cats');
		log_debug('URL:'.$update_category_url{'f'.$language{id}},'','migcms_shoeman_cats');
		log_debug('Father:'.$update_category{'id_father'},'','migcms_shoeman_cats');
		log_debug('f1:'.$update_category{'f1'},'','migcms_shoeman_cats');

		#ajout/update de la catégorie
		$id_data_category = sql_set_data({dbh=>$dbh,debug=>0,debug_results=>0,table=>'data_categories',data=>\%update_category,where=>"id_father='$update_category{id_father}' AND f1='$update_category{f1}'"});	
		my %data_category = read_table($dbh,'data_categories',$id_data_category);
		log_debug('id_data_category:'.$id_data_category,'','migcms_shoeman_cats');
		
		set_traduction({id_language=>$language{id},traduction=>$update_category{'f'.$language{id}},id_traduction=>$data_category{id_textid_name},table_record=>'data_categories',col_record=>'id_textid_name',id_record=>$data_category{id}});
		set_traduction({id_language=>$language{id},traduction=>$update_category{'f'.$language{id}},id_traduction=>$data_category{id_textid_meta_title},table_record=>'data_categories',col_record=>'id_textid_meta_title',id_record=>$data_category{id}});
		set_traduction({id_language=>$language{id},traduction=>$update_category{'f'.$language{id}},id_traduction=>$data_category{id_textid_meta_description},table_record=>'data_categories',col_record=>'id_textid_meta_description',id_record=>$data_category{id}});
		set_traduction({id_language=>$language{id},traduction=>$update_category_url{'f'.$language{id}},id_traduction=>$data_category{id_textid_url_rewriting},table_record=>'data_categories',col_record=>'id_textid_url_rewriting',id_record=>$data_category{id}});
		incremente_ordby({table=>'data_categories',where=>"id_father = '$d{id_father}'",rec=>\%data_category});		
	}

	log_debug('sync_category OK','','migcms_shoeman_sheets');
	
	return $id_data_category;
}	

sub incremente_ordby
{
	log_debug('incremente_ordby','','migcms_shoeman_sheets');
	
	my %d = %{$_[0]};
	my %rec =  %{$d{rec}};
	if($rec{ordby} == 0)
	{
		my $new_ordby = 1;
		my %max_ordby = sql_line({debug=>0,debug_results=>0,select=>"MAX(ordby) as max_ordby",table=>$d{table},where=>$d{where}});
		if($max_ordby{max_ordby} >= 1)
		{
			$new_ordby = $max_ordby{max_ordby} + 1;
		}
		$stmt = "update $d{table} set ordby = $new_ordby where id = ".$rec{id};
		execstmt($dbh,$stmt);					
	}
	
	log_debug('incremente_ordby OK','','migcms_shoeman_sheets');
}

sub add_lnk_category_for_sheet
{
	log_debug('add_lnk_category_for_sheet','','migcms_shoeman_sheets');
	
	my %d = %{$_[0]};
	my %data_sheet = %{$d{data_sheet}};
	
	if($data_sheet{id} > 0 && $d{id_data_category} > 0)
	{
		my %data_lnk_sheets_categorie = 
		(
			id_data_sheet => $data_sheet{id},
			id_data_category => $d{id_data_category},
			id_data_family => $data_sheet{id_data_family},
			ordby => 0,
		);
		log_debug('Liaison: sheet,cat:'.$data_sheet{id}.','.$d{id_data_category},'','migcms_shoeman_cats');

		$data_lnk_sheets_categorie{id} = inserth_db($dbh,'data_lnk_sheets_categories',\%data_lnk_sheets_categorie);
		incremente_ordby({table=>'data_lnk_sheets_categories',where=>"id_data_sheet = '$data_lnk_sheets_categorie{id_data_sheet}' AND id_data_category = '$data_lnk_sheets_categorie{id_data_category}'",rec=>\%data_lnk_sheets_categorie});
		
		#cas mixte -> homme femme
		my $id_cat_propage_mixte = $codes{shoeman_config}{propage_mixte}{v1};
		if($id_cat_propage_mixte > 0 && $id_cat_propage_mixte == $d{id_data_category})
		{
			if($codes{shoeman_config}{propage_mixte}{v2} > 0)
			{
				my %data_lnk_sheets_categorie = 
				(
					id_data_sheet => $data_sheet{id},
					id_data_category => $codes{shoeman_config}{propage_mixte}{v2},
					id_data_family => $data_sheet{id_data_family},
					ordby => 0,
				);
				log_debug('Liaison: sheet,cat:'.$data_sheet{id}.','.$d{id_data_category},'','migcms_shoeman_cats');

				$data_lnk_sheets_categorie{id} = inserth_db($dbh,'data_lnk_sheets_categories',\%data_lnk_sheets_categorie);
				incremente_ordby({table=>'data_lnk_sheets_categories',where=>"id_data_sheet = '$data_lnk_sheets_categorie{id_data_sheet}' AND id_data_category = '$data_lnk_sheets_categorie{id_data_category}'",rec=>\%data_lnk_sheets_categorie});
			}

			if($codes{shoeman_config}{propage_mixte}{v3} > 0)
			{
				my %data_lnk_sheets_categorie = 
				(
					id_data_sheet => $data_sheet{id},
					id_data_category => $codes{shoeman_config}{propage_mixte}{v3},
					id_data_family => $data_sheet{id_data_family},
					ordby => 0,
				);
				log_debug('Liaison: sheet,cat:'.$data_sheet{id}.','.$d{id_data_category},'','migcms_shoeman_cats');

				$data_lnk_sheets_categorie{id} = inserth_db($dbh,'data_lnk_sheets_categories',\%data_lnk_sheets_categorie);
				incremente_ordby({table=>'data_lnk_sheets_categories',where=>"id_data_sheet = '$data_lnk_sheets_categorie{id_data_sheet}' AND id_data_category = '$data_lnk_sheets_categorie{id_data_category}'",rec=>\%data_lnk_sheets_categorie});
			}		
		}
	}
	else
	{
		log_debug('Pas de liaison car id manquant: sheet,cat:'.$data_sheet{id}.','.$d{id_data_category},'','migcms_shoeman_cats');
	}
	
	log_debug('add_lnk_category_for_sheet OK','','migcms_shoeman_sheets');
}	

sub mill_crit
{
	my $crit_txt = $_[0];
	
	my $virgule5 = ',5';
	$crit_txt =~ s/\xbd/$virgule5/g;

	$crit_txt =~ s/[^\x00-\x7F]//g;
	$crit_txt =~ s/[^A-Za-z0-9\-\.\,\:\/\\ ]//g;
	$crit_txt =~ s/\s+$//g;
	
	return $crit_txt;
}


sub after_save_sheets
{
	log_debug('after_save_sheets','','migcms_shoeman');
	
	my @data_sheets = sql_lines({table=>'data_sheets',where=>"after_save_sheet = '1' AND sheet_activable = '1'"});
	foreach $data_sheet (@data_sheets)
	{
		my %data_sheet = %{$data_sheet};

   	    # Catégories
		shoeman_link_categories({data_sheet=>\%data_sheet});	
		
		#crée une arborescence de catégories en dessous de genre pour précalculer les filtres (catégories manquantes seulement)
		# create_filter_categories(); 
		
		#lie la sheet aux filtres
		# shoeman_link_categories_filters({data_sheet=>\%data_sheet});			
		
		#set seo 
		def_handmade::shoeman_set_sheet_seo({data_sheet=>\%data_sheet});
		
		$stmt = "update data_sheets SET after_save_sheet = '0' where id = '$data_sheet{id}'";
		log_debug($stmt,'','migcms_shoeman_sheets');
		execstmt($dbh,$stmt);
	}
	
	log_debug('after_save_sheets OK','','migcms_shoeman');
}


sub set_sheet_activable
{
	log_debug('set_sheet_activable','','migcms_shoeman');
	
	my %field_artdelete = sql_line({table=>'migcms_codes',where=>"code='supprime'"});
	my %field_par17id = sql_line({table=>'migcms_codes',where=>"code='Par17id'"});
	my %field_par18id = sql_line({table=>'migcms_codes',where=>"code='Par18id'"});

	my @data_sheets = sql_lines({select=>"id,$field_artdelete{v2},$field_par17id{v2},$field_par18id{v2}",table=>'data_sheets',where=>"after_save_sheet = '1'"});
	log_debug("set_sheet_activable: Nb de sheets traitées: ".($#data_sheets+1),'','migcms_shoeman');
	
	foreach $data_sheet (@data_sheets)
	{
		my %data_sheet = %{$data_sheet};
		
		my $sheet_activable = 0;
		my $raison = '';
		
		# Artdelete
		if($data_sheet{$field_artdelete{v2}} ne 'X')
		{
			# (dw.Par17id = 1 OR dw.Par18id = 1)
			if($data_sheet{$field_par17id{v2}} == 1 || $data_sheet{$field_par18id{v2}} == 1)
			{
				$raison = '';
				$sheet_activable = 1;
			}
			else
			{
				$raison = 'Saison désactivée';
			}
		}
		else
		{
			$raison = 'Produit supprimé';
		}
		
		$stmt = "update data_sheets SET sheet_activable = '$sheet_activable', $colonne_log = '$raison' where id = '$data_sheet{id}'";
		log_debug($stmt,'','migcms_shoeman_sheets');
		execstmt($dbh,$stmt);
	}
	
	log_debug('set_sheet_activable OK','','migcms_shoeman');
}



sub compute_cat_denomination
{
	my $id_father = $_[0];
	my $category_fusion_r = $_[1];
	
	my @cats = sql_lines({debug=>0,table=>'data_categories',where=>"fusion = '' AND id_father='$id_father'"});

	foreach $cat (@cats)
	{
		my %cat = %{$cat};
		
		my $nom_module = get_traduction({debug=>0,id=>$cat{id_textid_name},id_language=>1});

		
		my $category_fusion = $category_fusion_r.' > '.$nom_module;
		
		compute_cat_denomination($cat{id},$category_fusion);	
		
		$category_fusion = trim($category_fusion);
		$category_fusion =~ s/^\>//g;
		$category_fusion = trim($category_fusion);
		$category_fusion =~ s/\'/\\\'/g;
		
		my $id_avec_prefixe = getcode($dbh,$cat{id},'CAT');

		$stmt = "UPDATE data_categories SET fusion= '$category_fusion' WHERE id = $cat{id}";
		execstmt($dbh,$stmt);
	}	
}

sub shoeman_link_categories
{
	log_debug('shoeman_link_categories','','migcms_shoeman_sheets');

	my %d = %{$_[0]};
	my %data_sheet =  %{$d{data_sheet}};
	
	# vider toutes les liaisons des catégories pour ce produit 
	clean_lnk_categories_for_sheet({data_sheet=>\%data_sheet});
	
	my %field_id_father_categories = ();
	my %migcms_code_type = sql_line({select=>"t.id,t.code",table=>'migcms_code_types t',where=>"visible='y' AND code='shoeman_categories'"});
	my @migcms_codes = sql_lines({select=>"code,id_textid_name,ordby,condition_where,v1,v2,v3,v4,v5,v6,v7",table=>'migcms_codes',where=>"visible='y' AND id_code_type = '$migcms_code_type{id}'"});
	foreach $migcms_code (@migcms_codes)
	{
		my %migcms_code = %{$migcms_code};
		$field_id_father_categories{$migcms_code{code}} = $migcms_code{v1};
	}
	
	foreach my $field_id_father_category (keys %field_id_father_categories)
	{
		my @traductions = split(/\|/,$data_sheet{$field_id_father_category});
		log_debug("Catégorie FR: $traductions[0]",'','migcms_shoeman_sheets');
		log_debug("Catégorie EN: $traductions[1]",'','migcms_shoeman_sheets');
		log_debug("Catégorie NL: $traductions[2]",'','migcms_shoeman_sheets');
		log_debug("Catégorie DE: $traductions[3]",'','migcms_shoeman_sheets');

		my $id_data_category = sync_category({id_data_family=>$data_sheet{id_data_family},id_father=>$field_id_father_categories{$field_id_father_category},lg1=>$traductions[0],lg2=>$traductions[1],lg3=>$traductions[2],lg4=>$traductions[3],type_cat=>$field_id_father_category});
		log_debug("Liaison cat: $id_data_category avec $data_sheet{id}",'','migcms_shoeman_sheets');
		
		# recreer les liaisons
		add_lnk_category_for_sheet({data_sheet=>\%data_sheet,id_data_category=>$id_data_category});
	}
	
	log_debug('shoeman_link_categories OK','','migcms_shoeman_sheets');
}



sub shoeman_clean_linked_files
{
	my $table_r = $_[0];
	my $id_r = $_[1];

	my @migcms_linked_files = sql_lines({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='$table_r' AND token='$id_r'"});
	foreach $migcms_linked_file (@migcms_linked_files)
	{
		my %migcms_linked_file = %{$migcms_linked_file};

		#unlink file and thumbs
		my @cols = ('full','name_mini','name_small','name_medium','name_large','name_og');
		foreach my $col (@cols)
		{
			my $url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{$col};
			if($col eq 'full')
			{
				$url .= $migcms_linked_file{ext};
			}

			if(-e $url)
			{
				unlink($url);
			}
			else
			{
				#cant find
			}
		}

	    $stmt = "delete FROM migcms_linked_files WHERE id = '$migcms_linked_file{id}' ";
		execstmt($dbh,$stmt);
	}
}

sub categories_visibility
{
	log_debug('categories_visibility','','migcms_shoeman');
	$stmt = "update data_categories c SET visible='y' where id IN ( select id_data_category from data_lnk_sheets_categories lnk, data_sheets sh where lnk.id_data_sheet = sh.id and sh.visible='y' )";
	execstmt($dbh,$stmt);
	$stmt = "update data_categories c SET visible='n' where id NOT IN ( select id_data_category from data_lnk_sheets_categories lnk, data_sheets sh where lnk.id_data_sheet = sh.id and sh.visible='y' )";
	execstmt($dbh,$stmt);
	log_debug('categories_visibility OK','','migcms_shoeman');
}

sub create_filter_categories
{
	if($codes{shoeman_config}{create_filter_categories}{v1} eq 'y')
	{
		log_debug('create_filter_categories','','migcms_shoeman');
		
		#crer arborescence de catégories pour précalculer les filtres
		
		#créer catégories manquantes
		my %migcms_code_type = sql_line({select=>"t.id,t.code",table=>'migcms_code_types t',where=>"visible='y' AND code='shoeman_categories'"});
		my %code_parent = sql_line({select=>"v1 as genre, v2 as liste_enfants",table=>'migcms_codes',where=>"visible='y' AND id_code_type = '$migcms_code_type{id}' AND v2 != ''"});
		log_debug("code_parent:$code_parent{id}",'','create_filter_categories');

		my %cat_genre = sql_line({table=>'data_categories',where=>"id='$code_parent{genre}'"});
		log_debug("cat_genre:$cat_genre{id}",'','create_filter_categories');
		
		my $where_genres = "id_father='$cat_genre{id}' AND visible='y'";
		log_debug("where_genres:$where_genres",'','create_filter_categories');
		
		my @genres = sql_lines({table=>'data_categories',where=>"$where_genres"});
		foreach my $cat_genre (@genres)
		{
			my %cat_genre = %{$cat_genre}; 
		
			my $nom_genre = get_traduction({debug=>0,id=>$cat_genre{id_textid_name},id_language=>1}); #ex: homme
			
			#24(type),25(marque),26(couleur)
			my @liste_enfants = split (/\,/,$code_parent{liste_enfants});
			foreach my $id_cat_enfant (@liste_enfants)
			{
				#prendre les catégories visibles de chaque parent et le créer dans le genre si nécessaire 
				my $where = "id_father='$id_cat_enfant' AND visible='y' AND id NOT IN (select f13 from data_categories where id_father='$cat_genre{id}')";
				log_debug("where:$where",'','create_filter_categories');
				
				my @data_categories = sql_lines({table=>'data_categories',where=>"$where"});
				log_debug("NB CATS TRAITEES: :$#data_categories+1",'','create_filter_categories');
				foreach my $data_category (@data_categories)
				{
					my %data_category = %{$data_category};
					log_debug("data_category:$data_category{id}",'','create_filter_categories');				
					
					my $nom_enfant = get_traduction({debug=>0,id=>$data_category{id_textid_name},id_language=>1});
					my $nom = "$nom_genre,$nom_enfant";
					$nom =~ s/\'/\\\'/g;
					
					my %new_category = 
					(
						id_father => $cat_genre{id},#parent: ex: homme
						f12 => $id_cat_enfant, #parent bouclé: exemple type 3
						f13 => $data_category{id}, #valeur recopiée: exemple : basket 56
						f14 => $id_cat_enfant.','.$data_category{id}, #list ids: 3,56
						f15 => $nom,#list noms: homme,basket
						f19 => 1,
						id_data_family=>$id_data_family,
						visible=>'y',
					);
					my $new_id_cat = inserth_db($dbh,'data_categories',\%new_category);
					log_debug("Ajoute $nom ($new_id_cat)",'','create_filter_categories');
					set_traduction({id_language=>1,traduction=>$nom,id_traduction=>0,table_record=>'data_categories',col_record=>'id_textid_name',id_record=>$new_id_cat});			
				}		
			}
		}
		
		log_debug('create_filter_categories OK','','migcms_shoeman');
	}
}