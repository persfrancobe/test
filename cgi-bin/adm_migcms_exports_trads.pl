#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;



use sitetxt;
use HTML::Entities;


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


my $payment_status=get_quoted('payment_status');

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

# CONFIG GENERALE export excel#
my $col_reference = "f1"; 
my $col_titre = "f1",
my $col_fournisseur = "f3";
my $id_data_field = 42;
my $id_data_family = 2;

$dm_cfg{enable_search} = 1;
$dm_cfg{enable_multipage} = 1;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{hide_id} = 1;
$dm_cfg{table_name} = "txtcontents";
$dm_cfg{default_ordby} = "";
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";

my $filter_1 = get_quoted('filter_1') || '';
my $filter_2 = get_quoted('filter_2') || '';
my $filter_3 = get_quoted('filter_3') || '';
my $filter_4 = get_quoted('filter_4') || '';
my $filter_5 = get_quoted('filter_5') || '';
my $dm_search = get_quoted('dm_search') || '';

$dm_cfg{get_form_ref} = \&get_form;
$dm_cfg{get_view_ref} = \&get_view;
$dm_cfg{get_and_check_ref} = \&get_and_check;
$dm_cfg{table_width} = 1100;
$dm_cfg{fieldset_width} = 1100;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_migcms_exports_trads.pl?";
$dm_cfg{hiddp} = <<"EOH";

EOH

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{howmany} = 50;

$config{logfile} = "trace.log";


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Description des champs qui vont être récupérer de la bdd
%dm_dfl = (    
 	    
       
      
       '01/content'=> 
       {
	        'title'=>"Txt",
	        'fieldtype'=>'text',
	        'fieldsize'=>'60',
	        'search' => 'y',
	        
	    }	    
	);
 

%dm_display_fields = (
"12/content"=>"content",
);

%dm_lnk_fields = (
);

%dm_mapping_list = (
"numero"=>\&numero,
"identite"=>\&identite,
"order_moment"=>\&get_order_moment,
"status"=>\&get_status,
"delivery_status"=>\&get_delivery_status,
"payment_status"=>\&get_payment_status,
"infos"=>\&get_infos,
"bon"=>\&get_bon,
);

%cmd_fourns = (
"y"=>'Oui',
"n"=>'Non',
);

%dm_filters = (

);


$dm_cfg{help_url} = "http://www.bugiweb.com";


$sw = $cgi->param('sw') || "export_trads";


my @fcts = qw(
			add_form
			mod_form
			list
			add_db
			mod_db
			del_db
			heal_xls
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);

    my $suppl_js=<<"EOH";
    
EOH
    
    print migc_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
}

sub heal_xls
{
	use Spreadsheet::ParseExcel;
	use Spreadsheet::ParseExcel::FmtUnicode;
	use Spreadsheet::WriteExcel;
	use Encode;
	use HTML::Entities;
	
	
	
	my $parser_good   = Spreadsheet::ParseExcel->new();
	my $parser_bad  = Spreadsheet::ParseExcel->new();
		
		
	
	
	see();
	
	my $feuille = 1;

	
	
	
	my $outfile = "../usr/correction_".$feuille.".xls";
	my $good_xls = '../usr/casalea_good.xls';
	my $bad_xls = '../usr/casalea_bad.xls';
	my $good_workbook = $parser_good->parse($good_xls);
	my $bad_workbook = $parser_bad->parse($bad_xls);
	my $workbook = Spreadsheet::WriteExcel->new($outfile); 
	my $good_worksheet = $good_workbook->worksheet($feuille);
	my $bad_worksheet = $bad_workbook->worksheet($feuille);
	my $worksheet = $workbook->add_worksheet('Correction feuille '.$feuille);
	
	
		
		print <<"EOH";
			 <table>
			 <tr>
				<th>
					ligne
				</th>
				<th>
					id_textid
				</th>
				<th>
					GOOD FR
				</th>
				<th>
					BAD FR 
				</th>
				<th>
					BAD NL
				</th>
				<th>
					BAD EN
				</th>
				<th>
					BAD DE
				</th>
				<th>
					BAD ES
				</th>
			</tr>
EOH
	
	
	my $ligne_bad = 1;
	my $corr_col_valeur = 1;
	
	foreach $ligne (2 .. 500)
	{
		my $good_cell_id = $good_worksheet->get_cell($ligne, 1);
		my $good_cell_fr = $good_worksheet->get_cell($ligne, 2);
		if($good_cell_id ne '')
		{
			$good_cell_id = trim(encode("utf8",$good_cell_id->value()));
		}
		
		if(!($good_cell_id > 0))
		{
			next;
		}
		
		if($good_cell_fr ne '')
		{
			$good_cell_fr = trim(encode("utf8",$good_cell_fr->value()));
		}
		
		my $bad_cell_fr = '';
		my $bad_cell_nl = '';
		my $bad_cell_en = '';
		my $bad_cell_de = '';
		my $bad_cell_es = '';
		
		if($good_cell_fr ne '')
		{
			$ligne_bad++;
			$bad_cell_fr = $bad_worksheet->get_cell($ligne_bad, 2);
			if($bad_cell_fr ne '')
			{
				$bad_cell_fr = trim(encode("utf8",$bad_cell_fr->value()));
			}
			else
			{
				if($feuille==1)
				{
					$ligne_bad++;
				}
			}
			
			my $colcorr = $corr_col_valeur;
			$bad_cell_nl = $bad_worksheet->get_cell($ligne_bad, $colcorr++);
			if($bad_cell_nl ne '')
			{
				$bad_cell_nl = trim(encode("utf8",$bad_cell_nl->value()));
			}
			$bad_cell_en = $bad_worksheet->get_cell($ligne_bad, $colcorr++);
			if($bad_cell_en ne '')
			{
				$bad_cell_en = trim(encode("utf8",$bad_cell_en->value()));
			}
			$bad_cell_de = $bad_worksheet->get_cell($ligne_bad, $colcorr++);
			if($bad_cell_de ne '')
			{
				$bad_cell_de = trim(encode("utf8",$bad_cell_de->value()));
			}
			$bad_cell_es = $bad_worksheet->get_cell($ligne_bad, $colcorr++);
			if($bad_cell_es ne '')
			{
				$bad_cell_es = trim(encode("utf8",$bad_cell_es->value()));
			}
			
		}
		
		$worksheet->write($ligne,1,decode("utf8",$good_cell_id),$format);
		$worksheet->write($ligne,1,decode("utf8",$good_cell_fr),$format);
		
		my $colcorr = $corr_col_valeur;
		$worksheet->write($ligne,$colcorr++,decode("utf8",$bad_cell_nl),$format);
		$worksheet->write($ligne,$colcorr++,decode("utf8",$bad_cell_en),$format);
		$worksheet->write($ligne,$colcorr++,decode("utf8",$bad_cell_de),$format);
		$worksheet->write($ligne,$colcorr++,decode("utf8",$bad_cell_es),$format);
		
		
		print <<"EOH";
			<tr >
				<td style="border-bottom:1px solid grey">$ligne</td>
				<td style="border-bottom:1px solid grey"><span style="color:green">$good_cell_id</span></td>
				<td style="border-bottom:1px solid grey"><span style="color:green">$good_cell_fr</span></td>
				<td style="border-bottom:1px solid grey"><span style="color:grey">$bad_cell_fr</span></td>
				<td  style="border-bottom:1px solid grey"><span style="color:red">$bad_cell_nl</span></td>
				<td  style="border-bottom:1px solid grey"><span style="color:red">$bad_cell_en</span></td>
				<td  style="border-bottom:1px solid grey"><span style="color:red">$bad_cell_de</span></td>
				<td  style="border-bottom:1px solid grey"><span style="color:red">$bad_cell_es</span></td>
			</tr>
EOH
	
	}
	
		$workbook->close();

    # open (FILE,$outfile);
    # binmode FILE;
    # binmode STDOUT;
    # while (read(FILE,$buff,2096))
    # {
         # print $cgi->redirect(-location=>$outfile,-content-type=>'application/octet-stream');
         # print STDOUT $buff;
    # }
    # close (FILE); 
	# exit;
	
	exit;
}

sub export_trads
{
    use Spreadsheet::ParseExcel;
    use Spreadsheet::WriteExcel;
    use Encode;  

	my @languages = sql_lines({table=>'migcms_languages',where=>"visible='y' OR encode_ok = 'y'"});
	my $outfile = "../usr/export_trads.xls";
	my $workbook = Spreadsheet::WriteExcel->new($outfile); 
	my @worksheets;
	my $curr_ws = 0;
	my $row=0,$col=0;
	
	#export des pages + parag 
	$worksheets[++$curr_ws] = $workbook->add_worksheet('Pages et paragraphes');

	export_trads_write_headers($worksheets[$curr_ws],'Nom de la page');
	my $row=2,$col=0;
	# my @pages = sql_lines({debug=>0,debug_results=>0,table=>'pages p, tree t',where=>"t.type_obj = 'pages' AND t.id_obj = p.id",ordby=>'t.id_father asc, t.ordby'});
	my @pages = sql_lines({debug=>0,debug_results=>0,table=>'migcms_pages',where=>"id NOT IN (select id_page from mailings)",ordby=>''});
	foreach $page (@pages)
	{
		my %page = %{$page};
		
		my @page_fields = qw(
			id_textid_name
			id_textid_meta_title
			id_textid_meta_keywords
			id_textid_meta_description
			id_textid_meta_url
			id_textid_url
		);
		
		my $i = 0;
		foreach my $page_field (@page_fields)
		{
			$col=0;
			# $row++;
			
			#nom de la page pour se situer
			if($i == 0)
			{
				my ($pagename,$dum) = get_textcontent($dbh,$page{id_textid_name},1);
				$worksheets[$curr_ws]->write($row,$col,decode("utf8",$pagename),$format);
			}
			$col++;
			
			#boucle sur les champs traductibles de la PAGE
			my $no_data = 1;
			if($page{$page_field} > 0)
			{
				#id
				$worksheets[$curr_ws]->write($row,$col++,$page{$page_field},$format);
				
				
				#boucle sur le contenu des langues
				my $longueur = 0;
				foreach $language (@languages)
				{
					my %language = %{$language};
					$longueur += export_trads_write_cell($page{$page_field},$language{id},$worksheets[$curr_ws],$row,$col++,$is_data);
				}
				
				# if($longueur > 0)
				# {
					$row++;
				# }
			}
			$i++;
		}
		
		#boucle sur les champs traductibles du PARAG
		my @parags = sql_lines({debug=>0,debug_results=>0,table=>'parag',where=>"id_page = '$page{id}'",ordby=>'ordby'});
		foreach $parag (@parags)
		{
			my %parag = %{$parag};
			
			my @parag_fields = qw(
				id_textid_title
				id_textid_parag	
			);
			
			foreach my $parag_field (@parag_fields)
			{
				$col=0;
				$col++;
				
				#boucle sur les champs traductibles
				my $is_data = 0;
				if($parag{$parag_field} > 0)
				{
					
					$worksheets[$curr_ws]->write($row,$col++,$parag{$parag_field},$format);
					
					#boucle sur les langues
					my $longueur = 0;
					foreach $language (@languages)
					{
						my %language = %{$language};
						$longueur += export_trads_write_cell($parag{$parag_field},$language{id},$worksheets[$curr_ws],$row,$col++,$is_data);
					}
					# if($longueur > 0)
					# {
						$row++;
					# }
				}
				
			}
		}
	}
	
	
	
	# see();
	#export des blocs
	$worksheets[++$curr_ws] = $workbook->add_worksheet(decode("utf8",'Blocs'));
	export_trads_write_headers($worksheets[$curr_ws],'Nom du bloc');
	my $row=2,$col=0;
	my @pages = sql_lines({debug=>0,debug_results=>0,table=>'migc_blocktypes',where=>"id IN ( select distinct(id_blocktype) from migcms_blocks where id_blocktype > 0) ",ordby=>'id'});
	foreach $page (@pages)
	{
		my %page = %{$page};

			$col=0;
			$row++;
			
			#nom du bloc pour se situer
			if($i == 0)
			{
				$worksheets[$curr_ws]->write($row,$col,decode("utf8",$page{name}),$format);
			}
			$col++;
			
		
		#boucle sur les champs traductibles du PARAG
		my @parags = sql_lines({debug=>0,debug_results=>0,table=>'migcms_blocks b',where=>"id_blocktype = '$page{id}'",ordby=>'b.ordby'});
		foreach $parag (@parags)
		{
			my %parag = %{$parag};
			# see(\%parag);
			my @parag_fields = qw(
				id_textid_title
				id_textid_content	
			);
			
			foreach my $parag_field (@parag_fields)
			{
				$col=0;
				$col++;
				
				#boucle sur les champs traductibles
				my $is_data = 0;
				if($parag{$parag_field} > 0)
				{
					# print "write($row,$col++,$parag{$parag_field},$format);";
					$worksheets[$curr_ws]->write($row,$col++,$parag{$parag_field},$format);
					# print "<br />row : $row ID $parag_field: $parag{$parag_field}";
					
					#boucle sur les langues
					my $longueur = 0;
					foreach $language (@languages)
					{
						my %language = %{$language};
						$longueur += export_trads_write_cell($parag{$parag_field},$language{id},$worksheets[$curr_ws],$row,$col++,$is_data);
						# print "<br />longueur LG $language{id}: $longueur";
						
					}
					
					# if($longueur > 0)
					# {
						# print '<hr /><b>row++</b>';
						$row++;
					# }
				}
			}
		}
	}
	
	
	
	#export des liens
	$worksheets[++$curr_ws] = $workbook->add_worksheet('Liens');
	export_trads_write_headers($worksheets[$curr_ws],'');
	my $row=2,$col=0;
	# my @pages = sql_lines({debug=>0,debug_results=>0,table=>'pages p, tree t',where=>"t.type_obj = 'pages' AND t.id_obj = p.id",ordby=>'t.id_father asc, t.ordby'});
	if(0)
	{
	my @pages = sql_lines({debug=>0,debug_results=>0,table=>'links',where=>"",ordby=>''});
	foreach $page (@pages)
	{
		my %page = %{$page};
		
		my @page_fields = qw(
			id_textid_name
		);
		
		my $i = 0;
		foreach my $page_field (@page_fields)
		{
			$col=0;
			# $row++;
			
			# $col++;
			
			#boucle sur les champs traductibles de la PAGE
			my $no_data = 1;
			if($page{$page_field} > 0)
			{
				#id
				$worksheets[$curr_ws]->write($row,$col++,$page{$page_field},$format);
				
				
				#boucle sur le contenu des langues
				my $longueur = 0;
				foreach $language (@languages)
				{
					my %language = %{$language};
					$longueur += export_trads_write_cell($page{$page_field},$language{id},$worksheets[$curr_ws],$row,$col++,$is_data);
				}
				
				# if($longueur > 0)
				# {
					$row++;
				# }
			}
			$i++;
		}
	}
	}
	
	# exit;
	#export des sitetxt
	$worksheets[++$curr_ws] = $workbook->add_worksheet(decode("utf8",'Textes spécifiques'));
	export_trads_write_headers($worksheets[$curr_ws],'Mot clé');
	my $row=2,$col=0;
	my @pages = sql_lines({debug=>0,debug_results=>0,table=>'sitetxt',where=>"",ordby=>'keyword'});
	foreach $page (@pages)
	{
		my %page = %{$page};

			$col=0;
			$row++;
			
			#mot cle
			$worksheets[$curr_ws]->write($row,$col,decode("utf8",$page{keyword}),$format);
			$col++;
			
			#id
			$worksheets[$curr_ws]->write($row,$col,decode("utf8",$page{id}),$format);
			$col++;
								
			#boucle sur les langues
			foreach $language (@languages)
			{
				my %language = %{$language};
				
				my $traduction = $page{'lg'.$language{id}};
				$traduction =~ s|<.+?>||g;
				$traduction = decode("utf8",$traduction);
				$traduction = decode_entities($traduction);
				$worksheets[$curr_ws]->write($row,$col++,$traduction,$format);
			}
	}
	
	#export des eshop_txt
	$worksheets[++$curr_ws] = $workbook->add_worksheet(decode("utf8",'Textes pour la boutique'));
	export_trads_write_headers($worksheets[$curr_ws],'Mot clé');
	my $row=2,$col=0;
	my @pages = sql_lines({debug=>0,debug_results=>0,table=>'eshop_txts',where=>"",ordby=>'keyword'});
	foreach $page (@pages)
	{
		my %page = %{$page};

			$col=0;
			$row++;
			
			#mot cle
			$worksheets[$curr_ws]->write($row,$col,decode("utf8",$page{keyword}),$format);
			$col++;
			
			#id
			$worksheets[$curr_ws]->write($row,$col,decode("utf8",$page{id}),$format);
			$col++;
								
			#boucle sur les langues
			foreach $language (@languages)
			{
				my %language = %{$language};
				
				my $traduction = $page{'lg'.$language{id}};
				$traduction =~ s|<.+?>||g;
				$traduction = decode("utf8",$traduction);
				$traduction = decode_entities($traduction);
				$worksheets[$curr_ws]->write($row,$col++,$traduction,$format);
			}
	}

	#export des textes des mails automatiques
	$worksheets[++$curr_ws] = $workbook->add_worksheet(decode("utf8",'Textes des emails'));
	export_trads_write_headers($worksheets[$curr_ws],'Mot clé');
	my $row=2,$col=0;
	# my @pages = sql_lines({debug=>0,debug_results=>0,table=>'eshop_txts',where=>"",ordby=>'keyword'});
	# Récupération de la config 
	my %emails_config = select_table($dbh,"eshop_emails_setup");

	foreach $champ (keys %emails_config)
	{	
		# Si le nom de la colonne contient "_textid"
		if ($champ =~ /_textid/)
		{
			$col=0;
			
			#mot cle
			$worksheets[$curr_ws]->write($row,$col,decode("utf8",$champ),$format);
			$col++;
			
			#id
			$worksheets[$curr_ws]->write($row,$col,decode("utf8",$emails_config{$champ}),$format);
			$col++;
								
			#boucle sur les langues
			foreach $language (@languages)
			{
				my %language = %{$language};
				$longueur += export_trads_write_cell($emails_config{$champ},$language{id},$worksheets[$curr_ws],$row,$col++,$is_data);

			}
			$row++;
		}
	}
	# foreach $page (@pages)
	# {
	# 	my %page = %{$page};

	# 		$col=0;
	# 		$row++;
			
	# 		#mot cle
	# 		$worksheets[$curr_ws]->write($row,$col,decode("utf8",$page{keyword}),$format);
	# 		$col++;
			
	# 		#id
	# 		$worksheets[$curr_ws]->write($row,$col,decode("utf8",$page{id}),$format);
	# 		$col++;
								
	# 		#boucle sur les langues
	# 		foreach $language (@languages)
	# 		{
	# 			my %language = %{$language};
				
	# 			my $traduction = $page{'lg'.$language{id}};
	# 			$traduction =~ s|<.+?>||g;
	# 			$traduction = decode("utf8",$traduction);
	# 			$traduction = decode_entities($traduction);
	# 			$worksheets[$curr_ws]->write($row,$col++,$traduction,$format);
	# 		}
	# }
	
	#Champs des formulaires
	$worksheets[++$curr_ws] = $workbook->add_worksheet(decode("utf8",'Champs des formulaires'));
	export_trads_write_headers($worksheets[$curr_ws],'');
	my $row=2,$col=0;
	my @pages = sql_lines({debug=>0,debug_results=>0,table=>'forms_fields',where=>"",ordby=>'ordby'});
	foreach $page (@pages)
	{
		my %page = %{$page};
		
		my @forms_fields = qw(
			id_textid_name
			id_textid_msg
			id_textid_infobulle
		);
		
		my $i = 0;
		foreach my $forms_field (@forms_fields)
		{
			$col=0;
			
			#boucle sur les champs traductibles 
			my $no_data = 1;
			if($page{$forms_field} > 0)
			{
				#id
				$worksheets[$curr_ws]->write($row,$col++,$page{$forms_field},$format);
				
				
				#boucle sur le contenu des langues
				my $longueur = 0;
				foreach $language (@languages)
				{
					my %language = %{$language};
					$longueur += export_trads_write_cell($page{$forms_field},$language{id},$worksheets[$curr_ws],$row,$col++,$is_data);
				}
				# if($longueur > 0)
				# {
					$row++;
				# }
			}
			$i++;
		}
	}
	
	my @family_fields = qw(
			id_textid_meta_title
			id_textid_meta_description
			id_textid_meta_keywords
			id_textid_url_rewriting
			id_textid_default_name_title
			id_textid_fiche
		);
		
	my @category_fields = qw(
			id_textid_name
			id_textid_description
			id_textid_url
			id_textid_meta_title
			id_textid_meta_description
			id_textid_meta_keywords
			id_textid_url_rewriting
		);	
		
	my @crit_fields = qw(
			id_textid_name
		);	
		
	
	#contenu des familles
	my @data_families = sql_lines({table=>'data_families',ordby=>'id'});
	foreach $data_family (@data_families)
	{
		my %data_family = %{$data_family};
		$row = 0;
		
		my @trad_fields = ();
		
		my @data_fields = sql_lines({debug=>0,debug_results=>0,table=>'data_fields',where=>"id_data_family='$data_family{id}'",ordby=>'ordby'});
		foreach $data_field (@data_fields)
		{
			my %data_field = %{$data_field};
			
			if($data_field{field_type} eq 'text_id' || $data_field{field_type} eq 'textarea_id' || $data_field{field_type} eq 'textarea_id_editor')
			{
				push @trad_fields , 'f'.$data_field{ordby};
			}
		}
		
		#ajoute une feuille pour la famille ...
		
		my $data_family_name = 'Contenu de '.decode("utf8",$data_family{name});		
		$worksheets[++$curr_ws] = $workbook->add_worksheet($data_family_name);
		$row = 0;
		export_trads_write_headers($worksheets[$curr_ws],'');
		
		
		
		foreach my $fam_field (@family_fields)
		{
			$col = 0;
			$worksheets[$curr_ws]->write(++$row,$col++,$data_family{$fam_field},$format);
			foreach $language (@languages)
			{
				my %language = %{$language};
				export_trads_write_cell($data_family{$fam_field},$language{id},$worksheets[$curr_ws],$row,$col++,$is_data);
			}
		}			
		
		$col=0;
		$row++;
		$row++;
		$row++;
		
		
		my @data_sheets = sql_lines({table=>'data_sheets',where=>"id_data_family='$data_family{id}'",ordby=>'ordby'});
		foreach $data_sheet (@data_sheets)
		{
			my %data_sheet = %{$data_sheet};
			
			foreach my $trad_field (@trad_fields)
			{
				$col=0;

				if($data_sheet{$trad_field} > 0)
				{
					#id
					$worksheets[$curr_ws]->write($row,$col++,$data_sheet{$trad_field},$format);
					
					#boucle sur le contenu des langues
					my $longueur = 0;
					foreach $language (@languages)
					{
						my %language = %{$language};
						$longueur += export_trads_write_cell($data_sheet{$trad_field},$language{id},$worksheets[$curr_ws],$row,$col++,$is_data);
					}
					
					# if($longueur > 0)
					# {
						$row++;
					# }
				}
			}
		}
		
		#categories
		my @data_categories = sql_lines({debug=>0,debug_results=>0,table=>'data_categories',where=>"id_data_family='$data_family{id}'",ordby=>'ordby'});
		if($#data_categories > -1)
		{
			#ajoute une feuille pour les categories de la famille ...
			my $data_family_name = decode("utf8",$data_family{name});		
			$worksheets[++$curr_ws] = $workbook->add_worksheet(decode("utf8",'Catégories de '.$data_family_name));
			$row = 0;
			export_trads_write_headers($worksheets[$curr_ws],'');
			foreach $data_category (@data_categories)
			{
				my %data_category = %{$data_category};
				
				foreach my $category_field (@category_fields)
				{
					$col=0;

					if($data_category{$category_field} > 0)
					{
						#id
						$worksheets[$curr_ws]->write($row,$col++,$data_category{$category_field},$format);
						
						#boucle sur le contenu des langues
						my $longueur = 0;
						foreach $language (@languages)
						{
							my %language = %{$language};
							$longueur += export_trads_write_cell($data_category{$category_field},$language{id},$worksheets[$curr_ws],$row,$col++,$is_data);
						}
						# if($longueur > 0)
						# {
							$row++;
						# }
						
						
						
					}
				}
			}
		
		}
		
		#crits
		my @data_crits = sql_lines({debug=>0,debug_results=>0,table=>'data_crit_listvalues',where=>"id_data_family='$data_family{id}'",ordby=>'ordby'});
		if($#data_crits > -1)
		{
			#ajoute une feuille pour les categories de la famille ...
			my $data_family_name = decode("utf8",$data_family{name});		
			$worksheets[++$curr_ws] = $workbook->add_worksheet(decode("utf8",'Critères de '.$data_family_name));
			$row = 0;
			export_trads_write_headers($worksheets[$curr_ws],'');
			foreach $data_crit (@data_crits)
			{
				my %data_crit = %{$data_crit};
				
				foreach my $crit_field (@crit_fields)
				{
					$col=0;

					if($data_crit{$crit_field} > 0)
					{
						#id
						$worksheets[$curr_ws]->write($row,$col++,$data_crit{$crit_field},$format);
						
						#boucle sur le contenu des langues
						foreach $language (@languages)
						{
							my %language = %{$language};
							export_trads_write_cell($data_crit{$crit_field},$language{id},$worksheets[$curr_ws],$row,$col++,$is_data);
						}
						$row++;
					}
				}
			}
		
		}
	}
	
	 
	$workbook->close();

    open (FILE,$outfile);
    binmode FILE;
    binmode STDOUT;
    while (read(FILE,$buff,2096))
    {
         print $cgi->redirect(-location=>$outfile,-content-type=>'application/octet-stream');
         print STDOUT $buff;
    }
    close (FILE); 
	exit;
}

sub export_trads_write_cell
{
	my $id_textid = $_[0];
	my $id_language = $_[1];
	my $ws = $_[2];
	my $row = $_[3];
	my $col = $_[4];
	
	my ($traduction,$dum) = get_textcontent($dbh,$id_textid,$id_language);
	
	$traduction =~ s|<.+?>| |g;
	if($traduction eq '' && $is_data_r != 1)
	{
		$is_data = 0;
	}
	# print '<hr>'.$traduction;
	
	$traduction = decode("utf8",$traduction);
	$traduction = decode_entities($traduction);
	$traduction = trim($traduction);
	$ws->write($row,$col,$traduction,$format);

	return length($traduction);
}

sub export_trads_write_headers
{
	my $ws = $_[0];
	my $title_supp = $_[1];
	my $row = 0;
	my $col = 0;
	my @languages = sql_lines({debug=>0,debug_results=>0,table=>'migcms_languages',where=>"visible='y' OR encode_ok = 'y'"});

	$ws->set_column(0,1,20); 
	$ws->set_column(1,2,20); 
	$ws->set_column(2,10,50); 
	
	if($title_supp ne '')
	{
		$ws->write($row,$col++,decode("utf8",$title_supp),$format);
	}
	$ws->write($row,$col++,decode("utf8",'Ne pas effacer'),$format);
	foreach $language (@languages)
	{
		my %language = %{$language};
		$ws->write($row,$col++,$language{name},$format);
	}
	return $ws;
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

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------