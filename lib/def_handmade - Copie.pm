#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
package def_handmade;  
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@ISA = qw(Exporter);	
@EXPORT = qw(                                                       
				denom
				denom_commande
				get_denom_style_et_js
				custom_deverrouiller
				custom_facturer
				confirm_nc
				get_products
				certigreen_edit_document_lines
				ajax_make_pdf_documents_pj
				map_document
				save_doc
				save_doc_facture_cree_pdf

				%doc_prefixes
				%doc_names
				%doc_tables
				%doc_scripts

				get_html_document_facture

				copy_document_to_invoice
				copy_invoice_to_nc 
				
				confirm_invoicing
				confirm_nc
				factures_client
				factures_reglements
				
				commande_col_adresse	
				commande_col_client
				
				action_globale_rappel1
				action_globale_rappel2
				action_globale_rappel3
				
				set_statut_facture_from_reglements
				ajax_infos_rec
            );
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use def;
use tools;
use Data::Dumper;
use DateTime;
use dm_publish_pdf;
use File::Copy;
use Math::Round;

 %doc_prefixes = 
(
		'commandes'=>'cmd',
		'intranet_factures'=>'fc0',
		'intranet_nc'=>'ne0',
);

 %doc_names = 
(
		'commandes'=>'Pro forma N°',
		'intranet_factures'=>'Facture N°',
		'intranet_nc'=>'Note de crédit N°',
);

 %doc_tables = 
(
		'cmd'=>'commandes',
		'commande'=>'commandes',
		'fc0'=>'intranet_factures',
		'ne0'=>'intranet_nc',
);


$htaccess_protocol_rewrite = 'https';
 
 
my $ICONCANCEL = '<i class="fa fa-fw fa-times-circle-o"></i>';
# my $ICONSAVE = $migctrad{save_action};
my $ICONSAVE = '<i class="fa-fw fa fa-floppy-o"></i>';
my $ICONETAPEFINALE = '<i class="fa-fw fa fa-paperclip "></i>';
my $TXTETAPEFINALE = 'Sauvegarder et accéder aux Pièce(s) jointe(s)';
my $nb_lignes_facture_details = 75;

$dbh_data = $dbh2 = $dbh;
 
 %doc_scripts = 
(
		'cmd'=>"$htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/adm_handmade_certigreen_commandes.pl?&sel=".get_sel_from_script('adm_handmade_certigreen_commandes.pl?'),
		'fc0'=>"$htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/adm_handmade_certigreen_factures.pl?&sel=".get_sel_from_script('adm_handmade_certigreen_factures.pl?'),
		'nc0'=>"$htaccess_protocol_rewrite://$config{rewrite_default_url}/cgi-bin/adm_handmade_certigreen_ncs.pl?&sel=".get_sel_from_script('adm_handmade_certigreen_ncs.pl?'),
);

sub denom
{
	my $dbh = $_[0];
	my $id = $_[1];
	my $type = $_[2] || 'long';
	my $from = $_[3] || '';
	
	my $hide_class = 'hide';
	my $fa_class = 'fa-plus-square-o';
	if(trim(get_quoted('list_keyword')) ne '' )
	{
	$hide_class = '';
	$fa_class = 'fa-minus-square-o';
	}

	
	if($id > 0)
	{
		my %member = sql_line({table=>'members',where=>"id='$id'"});
		my %agence = sql_line({table=>'members',where=>"id='$member{id_agence}'"});

		my $fusion = '';
		
		if($member{firstname} ne '' || $member{lastname} ne '')
		{
			if($type ne 'short')
			{
				$fusion .= '<span class="member_title"><span class="member_deplie"><i class="fa '.$fa_class.'" aria-hidden="true"></i></span><b> ';
			}
			
			$fusion .= trim($member{firstname}.' '.$member{lastname});
			
			if($type ne 'short')
			{
				$fusion .= '</b></span><div class="row member_info '.$hide_class.'"><div style="'.$style.'" class=" col-md-12"><div class="societe panel panel-default">';
				if($from ne 'commandes')
				{
					$fusion .= '<a href="/cgi-bin/adm_handmade_certigreen_members.pl?sel=1000282&id_father=0&sel='.$sel.'&sw=add_form&id='.$member{id}.'" data-placement="bottom" data_original-title="Modifier le client" id="'.$member{id}.'" class="migedit_'.$member{id}.' migedit">';
				}
			}
			
			my $rue = trim($member{street}.' '.$member{number});
			if($rue ne '' && $type ne 'short')
			{
				$fusion .= "$rue<br />";
			}
			if($rue ne '' && $type eq 'short')
			{
				$fusion .= " $rue ";
			}
			
			my $ville = trim($member{zip}.' '.$member{city});
			if($rue eq '' && $ville eq '')
			{
				$ville = '';
			}
			if($ville ne '' && $type ne 'short')
			{
				$fusion .= "$ville<br />";
			}
			if($ville ne '' && $type eq 'short')
			{
				$fusion .= " $ville ";
			}
			
			if($type ne 'short' && $from ne 'commandes')
			{
				$fusion .= '</a>';
			}
			
			my $tel = trim($member{tel});
			if($tel ne '' && $type ne 'short')
			{
				$fusion .= "<a href=\"tel:$tel\"> $tel</a><br />";
			}
			my $mail = trim($member{email});
			if($mail ne '' && $type ne 'short')
			{
				$fusion .= "<a href=\"mailto:$mail\"> $mail</a><br />";
			}
			
			if($type eq 'short' && $agence{fusion_short} ne '')
			{
				$fusion .= " (Client de $agence{fusion_short}) ";
			}
			
			
			$fusion =~s/\<br \/\>$//g;
			
		}
		
		return $fusion;
	}
	else
	{
		return '';
	}
}


sub commande_col_client
{
	my $dbh = $_[0];
	my $id = $_[1];
	my $type = $_[2] || 'long';
	my $from = $_[3] || 'commandes';

	if($id > 0)
	{
		my %commande = sql_line({table=>'intranet_factures',where=>"id='$id'"});
		
		my $fusion = '';
		
		my $nom = trim(uc($commande{lastname}).' '.ucfirst(lc($commande{firstname})));
		if($nom ne '')
		{
			$fusion .= "<b>$nom</b><br />";
		}
		my $rue = trim($commande{street}.' '.$commande{number});
		if($rue ne '')
		{
			$fusion .= "$rue<br />";
		}
		my $ville = trim($commande{zip}.' '.$commande{city});
		if($ville ne '')
		{
			$fusion .= "$ville<br />";
		}
		my $email = trim($commande{email}.' '.$commande{tel});
		if($email ne '')
		{
			if($commande{email} ne '')
			{
				$fusion .= '<a href="mailto:'.$commande{email}.'">'.$commande{email}.'</a> ';
			}
			if($commande{tel} ne '')
			{
				$fusion .= '<a href="tel:'.$commande{tel}.'">'.$commande{tel}.'</a> ';
			}
		}
		
		return $fusion;
	}
	else
	{
		return '';
	}
}

sub commande_col_adresse
{
	# my $dbh = $_[0];
	my $id = $_[1];
	my $type = $_[2] || 'long';
	my $from = $_[3] || 'intranet_factures';

	if($id > 0)
	{
		my %commande = sql_line({table=>'intranet_factures',where=>"id='$id'"});
		
		my $fusion = '';
		
		my $rue = trim($commande{adresse_rue}.' '.$commande{adresse_numero});
		if($rue ne '')
		{
			$fusion .= "$rue<br />";
		}
		my $ville = trim($commande{adresse_cp}.' '.$commande{adresse_ville});
		if($ville ne '')
		{
			$fusion .= "$ville<br />";
		}
		
		return $fusion;
	}
	else
	{
		return '';
	}
}


sub denom_commande
{
	my $dbh = $_[0];
	my $id = $_[1];
	my $type = $_[2] || 'long';
	my $from = $_[3] || 'intranet_factures';

	my $hide_class = 'hide';
	my $fa_class = 'fa-plus-square-o';
	if(trim(get_quoted('list_keyword')) ne '' )
	{
	$hide_class = '';
	$fa_class = 'fa-minus-square-o';
	}

	
	if($id > 0)
	{
		my %commande = sql_line({table=>'intranet_factures',where=>"id='$id'"});
		my %corr = 
		(
			1 => 'Studio/flat',
			2 => 'Appartement',
			3 => 'Maison',
			4 => 'Villa',
			5 => 'Immeuble à appartement',
		);
		my $type_bien = $corr{$commande{id_type_bien}};


		my $fusion = '';
		
		if($type ne 'short')
		{
			$fusion .= '<span class="member_title"><span class="member_deplie"><i class="fa '.$fa_class.'" aria-hidden="true"></i></span><b> ';
		}
		
		# my $city_short =  substr $commande{adresse_ville}, 0, 15;
		# $city_short .='...'; 
		
		# $fusion .= trim($type_bien.' '.$city_short);
		
		
		if($type ne 'short')
		{
			$fusion .= '</b></span><div class="row member_info '.$hide_class.'"><div style="'.$style.'" class=" col-md-12"><div class="societe panel panel-default">';
			if($from ne 'intranet_factures')
			{
			# $fusion .= '<a href="/cgi-bin/adm_handmade_certigreen_intranet_factures.pl?sel=1000278&sw=add_form&id='.$commande{id}.'" data-placement="bottom" data_original-title="Modifier la commande" id="'.$commande{id}.'" class="migedit_'.$commande{id}.' migedit">';
			}
		}
		
		my $rue = trim($commande{adresse_rue}.' '.$commande{adresse_numero});
		if($rue ne '' && $type ne 'short')
		{
			$fusion .= "$rue<br />";
		}
		my $ville = trim($commande{adresse_cp}.' '.$commande{adresse_ville});
		if($rue eq '' && $ville eq '')
		{
			$ville = '';
		}
		if($ville ne '' && $type ne 'short')
		{
			$fusion .= "$ville<br />";
		}
		if($ville ne '' && $type eq 'short')
		{
			$fusion .= " $commande{facture_nom} $commande{facture_prenom} $commande{adresse_rue} $commande{adresse_numero} $commande{adresse_cp} ".uc($commande{adresse_ville});
		}
		if($type ne 'short' && $from ne 'intranet_factures')
		{
			# $fusion .= '</a>';
		}
		# my $contact = trim($commande{contact_nom}.' '.$commande{contact_prenom});
		# if($contact ne '' && $type ne 'short')
		# {
			# $fusion .= "<u>Contacter:</u> $contact<br />";
		# }
		# if($contact ne '' && $type eq 'short')
		# {
			# $fusion .= " $contact ";
		# }
	
		
		my $tel = trim($commande{contact_tel});
		if($tel ne '' && $type ne 'short')
		{
			$fusion .= "<a href=\"tel:$tel\"> $tel</a><br />";
		}
		my $mail = trim($commande{contact_email});
		if($mail ne '' && $type ne 'short')
		{
			$fusion .= "<a href=\"mailto:$mail\"> $mail</a><br />";
		}
		
	
		
		
		$fusion =~s/\<br \/\>$//g;
			
		
		return $fusion;
	}
	else
	{
		return '';
	}
}



sub get_denom_style_et_js
{

my $style_et_js = <<"EOH";
<style>
.societe, .societe td
{
	color:black;
	padding:5px;
}
.contact, .contact td
{
	/*background-color:#ccc!important;*/
	/*border:1px solid #ddd;*/
	color:black;
	padding:5px;
	margin: 5px 5px 5px 0px;
	height:100px;	
}
.societe a,.contact a
{
	color:black;
	/*height:100px;*/
	/*margin: 5px;*/
	/*padding:5px;*/
}
.member_info
{
}
.member_title
{
 cursor:pointer;
}
.col_statut
{
	width:195px;
}
</style>
<script type="text/javascript">
	var self = '$config{baseurl}/cgi-bin/adm_handmade_certigreen_members.pl?';
	jQuery(document).ready(function() 
	{		
		jQuery(document).on("click", ".member_title", click_member_title);
	});
	
	function click_member_title()
	{
		var me = jQuery(this);
		var member_info = me.parent().children('.member_info');
		member_info.toggleClass('hide');

		var deplie = me.children('.member_deplie').children('i');

		deplie.toggleClass('fa-plus-square-o');
		deplie.toggleClass('fa-minus-square-o');
		return false;
	}
</script>
EOH
	
	return $style_et_js;
}

sub confirm_nc
{
	my $id_facture = get_quoted('id');
	my $tdoc = get_quoted('tdoc');
	
	my $table_name = 'intranet_factures';
	my %rec = ();
	if($table_name ne '' && $id_facture > 0)
	{
		%rec = sql_line({debug=>0,debug_results=>0,table=>$table_name,where=>"id='$id_facture'"});
	}
	
	

	my $new_id_nc = copy_invoice_to_nc($rec{id},$tdoc);
	
	
	
	
	$stmt = "update intranet_nc SET migcms_id = CONCAT('NC',LPAD( id, 7, '0' )) WHERE id = '".$new_id_nc."' ";
	execstmt($dbh,$stmt);

	

	my $filename = make_pdf_nc($new_id_nc);	
	
	$stmt = "update intranet_nc SET migcms_last_published_file = '$filename',migcms_id = CONCAT('NC',LPAD( id, 7, '0' )) WHERE id = '".$new_id_nc."' ";
	execstmt($dbh,$stmt);
	
	#Si facture créditée -> statut de la facture = créditée. (Changement manuel du statut de la facture si nécessaire pour partiellement créditée)
	$stmt = "update intranet_factures SET statut = 5 WHERE id = '".$id_facture."' ";
	execstmt($dbh,$stmt);
	
	

	
	# print $config{baseurl}.'/usr/documents/'.$filename;
	print $new_id_nc;
	exit;	
}


sub custom_facturer
{
	my $id = $_[0];
	my $colg = $_[1];
	
	# log_debug('custom_facturer','','custom_facturer');
	my %rec = %{$_[2]};
		my $table_name = $_[3];
		my $file_prefixe = $_[4];


	my %document = sql_line({table=>'intranet_documents',where=>"table_record='$table_name' AND id_record='$id'"});
	my %facture = sql_line({table=>'intranet_factures',where=>"table_record='$table_name' AND id_record='$id'"});

	if(1 || $dm_permissions{facturer})
	{
	
	if(!($document{id} > 0))
	{
	my $apercu = <<"EOH";
			
			<a href="#" data-funcpublish="" target="" download="" 
				data-placement="top" data-original-title="Ajouter des produits à la pro-forma" id="" role="button" 
				class="pull-right btn btn-default disabled ">
			<i class="fa fa-eur fa-fw" data-original-title="" title=""></i>
			</a>
			
EOH
		return $apercu;
	}
	
	#on peut facturer plusieurs fois.
	if(1 && $facture{id} > 0)
	{
		my $pj_name = dm::getcode($dbh,$facture{numero},'fa');
		my $apercu = <<"EOH";
			<a href="../usr/documents/$facture{migcms_last_published_file}" data-funcpublish="ajax_make_pdf_facture" target="_blank" download="" 
				data-placement="top" data-original-title="Télécharger la facture $pj_name" id="$facture{id}" role="button" 
				class="btn btn-success show_only_after_document_ready telecharger">
				<i class="fa fa-download fa-fw" data-original-title="" title=""></i>
			</a>
EOH
		return $apercu;
	}
	else
	{
		my $pj_name = dm::getcode($dbh,$id,$dm_cfg{file_prefixe});
		my $apercu = <<"EOH";
		<a title="" data-original-title="Facturer $pj_name" href="#" class=" btn-danger show_only_after_document_ready btn confirm_invoicing" id="$id">
			<i class="fa fa-eur fa-fw" data-original-title="" title=""></i>
		</a>
EOH
	
		return $apercu;
	}
	
	}
	else
	{
		return <<"EOH";
		<a title="" disabled data-original-title="Facturer $pj_name" href="#" class="  btn-danger show_only_after_document_ready btn disabled" id="">
			<i class="fa fa-eur fa-fw" data-original-title="" title=""></i>
		</a>

EOH
	}
}

sub custom_deverrouiller
{
	my $id = $_[0];
	my $colg = $_[1];
	my %rec = %{$_[2]};
	
	my %facture = sql_line({table=>'intranet_factures',where=>"table_record='$dm_cfg{table_name}' AND id_record='$id'"});
	
	my $pj_name = dm::getcode($dbh,$id,$dm_cfg{file_prefixe});

	
	if($facture{id} > 0 ||  $rec{migcms_lock} ne 'y' || $rec{migcms_deleted} eq 'y')
	{
		my $pj_name = dm::getcode($dbh,$id,'fc0');
		my $apercu = <<"EOH";
			
EOH
		if($facture{id} > 0)
		{
			return <<"EOH";
			<span data-toggle="tooltip" data-placement="top"  data-original-title="Déverrrouillage de $pj_name impossible car déjà facturé" class="label">
			<a  class="btn disabled btn-link show_only_after_document_ready "
		role="button" disabled id="$id" data-original-title="Déverrrouillage de $pj_name impossible car déjà facturé"
		data-placement="top" href="#"><i class="fa fa-unlock-alt fa-fw" 
		data-original-title="" title=""></i></a>
		</span>
EOH
		}
		elsif($rec{migcms_lock} ne 'y')
		{
			return <<"EOH";
			<span data-original-title="Déverrrouillage de $pj_name impossible car non verrouillé" 		data-placement="top">

			<a class="btn disabled btn-link show_only_after_document_ready "
		role="button" disabled id="$id" data-original-title="Déverrrouillage de $pj_name impossible car non verrouillé"
		data-placement="top" href="#"><i class="fa fa-unlock-alt fa-fw" 
		data-original-title="" title=""></i></a>
		</span>
EOH
		}
		elsif($rec{migcms_deleted} eq 'y')
		{
			return <<"EOH";
			<span data-original-title="Déverrrouillage de $pj_name impossible car déjà archivé"		data-placement="top">
			<a class="btn disabled btn-link show_only_after_document_ready "
		role="button" disabled id="$id"  href="#"><i class="fa fa-unlock-alt fa-fw" 
		data-original-title="" title=""></i></a>
		</span>
EOH
		}
	}
	else
	{
		my $pj_name = dm::getcode($dbh,$id,$dm_cfg{file_prefixe});
		my $apercu = <<"EOH";
		<a class="btn btn-default show_only_after_document_ready lock_off"
		role="button" id="$id" data-original-title="Déverrouiller $pj_name"
		data-placement="top" href="#"><i class="fa fa-unlock-alt fa-fw" 
		data-original-title="" title=""></i></a>
EOH
	
		return $apercu;
	}

}

sub get_products
{
	my $keywords = get_quoted('query');
	my $prefixe = get_quoted('prefixe');
	my $id_record = get_quoted('id_record') || get_quoted('id_document');
	
	my $table_name = 'intranet_factures';
	my %rec = ();
	if($table_name ne '' && $id_record > 0)
	{
		%rec = sql_line({debug=>0,debug_results=>0,table=>$table_name,where=>"id='$id_record'"});
	}
	
	# print $table_name;
	# print $id_record;
		
	$keywords =~ s/\// /g;
	$keywords =~ s/\'/ /g;
	$keywords =~ s/\\/ /g;
	$keywords =~ s/\(/ /g;
	$keywords =~ s/\)/ /g;
	$keywords =~ s/\]/ /g;
	$keywords =~ s/\[/ /g;
	$keywords =~ s/\*/ /g;
	$keywords =~ s/\./ /g;
	$keywords =~ s/\|/ /g;
	$keywords =~ s/\+/ /g;
	
	my $list_products = '';
	
	
	
	my @keywords = split('\s',$keywords);
	my @where_keyword = ();
	my @where_fields = 'INVDESCRIPTION';
	foreach my $keyword (@keywords)
	{
		# push @where_keyword, " ( LOWER(INVDESCRIPTION) LIKE '%$keyword%' ) OR ( LOWER(code) LIKE '%$keyword%' )";
		$keyword = trim($keyword);
		if($keyword ne '')
		{		
			push @where_keyword, " ( INVDESCRIPTION LIKE '%$keyword%' OR reference LIKE '%$keyword%' )";
		}
	}
	my $where = join(" AND ",@where_keyword);
	my @products = sql_lines({debug=>0,debug_results=>0,table=>'handmade_inv',where=>$where, limit => "0,20",ordby=>"reference,INVDESCRIPTION"});
	foreach $product (@products)
	{
		my %product = %{$product};
		   
			my $price_htva = $product{prix_htva};
			my $product_display = $product{INVDESCRIPTION}.' ('.$price_htva.'€ HTVA)';
			# my $product_display = $product{reference}.' '.$product{INVDESCRIPTION}.' ('.$price_htva.'€ HTVA)';
			
			my $raw_value = $product_display;
			foreach my $keyword (@keywords)
			{
				$keyword = trim($keyword);
				if($keyword eq '' || $keyword eq '/' || $keyword eq '(' || $keyword eq ')' || $keyword eq '-' || $keyword eq '+')
				{
					next;
				}
				
				my $to = "<k>".$keyword.'</k>';
				if($keyword eq '' || $keyword eq '/' || $keyword eq '(' || $keyword eq ')' || $keyword eq '-' || $keyword eq '+')
				{
					next;
				}
				
				if($raw_value=~ /$keyword/)
				{
					$product_display =~ s/$keyword/$to/g;
				}
			}
			foreach my $keyword (@keywords)
			{
				$keyword = uc($keyword);
				$keyword = trim($keyword);
				if($keyword eq '' || $keyword eq '/' || $keyword eq '(' || $keyword eq ')' || $keyword eq '-' || $keyword eq '+')
				{
					next;
				}
				
				# $raw_value = uc($raw_value);
				my $to = "<k>".$keyword.'</k>';
				if($raw_value=~ /$keyword/)
				{
					$product_display =~ s/$keyword/$to/g;
				}
			}

			
				# my $title = $product{reference}.' '.$product{INVDESCRIPTION};
				my $title = $product{INVDESCRIPTION};
			
			
			my $id_taux_tva = $product{taux_tva};
			   $list_products .= <<"EOH";
				<li style="cursor:pointer;cursor:hand;" class="list-group-item list-group-item-info invoice_product" data-achat="$achat" data-tva="$id_taux_tva" data-price="$price_htva" id="$product{id}" title="$title">$product_display</li>
EOH

	}
	
	my $products = <<"EOH";
		<!--<a class="btn btn-block btn-danger zap_products" style="color:white!important"> <i class="fa fa-times"></i></a>-->
		<ul class="list-group">
			$list_products
		</ul>
		<style>
		.invoice_product:hover,.list-group-item-info:hover
		{
			background-color: #333333!important;
			color:white!important;
		}
		</style>
EOH
	
	print $products;
	exit;
}


sub certigreen_edit_document_lines
{
	my $id = get_quoted('id');
	my $id_facture = $id;
	my $type = 'facture';
	my $table = 'intranet_factures';
	my $func_save = 'save_fac';
	my %facture = read_table($dbh,$table,$id);
	my $nb_lignes_facture_details = 75;
	my $lines = <<"EOH";
<div class="row row-listing2">
<div class="col-md-12 text-left">
	<section id="no-more-tables">
		<table id="migc4_main_table" class="table table-bordered table-striped table-condensed cf table-hover">
			<thead class="cf ">
				<tr>
					<th class="facture_articles" colspan="3">Articles</th>
					<th class="facture_remise text-right">Quantité</th>
					<th class="facture_remise text-right">Prix HTVA</th>
					<th class="facture_remise text-right hide">Remise</th>
					<th class="facture_pt text-right">Prix total HTVA</th>
				</tr>
			</thead>
EOH

	#BOUCLE LIGNES (1 à X)
	foreach my $num (1 .. $nb_lignes_facture_details)
	{
		my $num_ligne = $num ;
		my %facture_detail = sql_line({debug=>0,debug_results=>0,dbh=>$dbh2,table=>'intranet_facture_lignes',where=>"id_invoice='$facture{id}' AND ordby='$num_ligne'"});
		my $reference = $facture_detail{ref};
		my $label = $facture_detail{label};
		my $remarque = $facture_detail{remarque};
		my $pu_htva = $facture_detail{pu_htva};
		my $qty = $facture_detail{qty};
		if($qty eq '')
		{
			$qty = 1;
		}
		my $total_htva = $facture_detail{tot_htva};
		if($pu_htva ne '')
		{
			$pu_htva = sprintf("%.2f",$pu_htva);
		}
		else
		{
			$pu_htva = '';
		}
		if($total_htva ne '')
		{
			$total_htva = sprintf("%.2f",$total_htva);
		}
		else
		{
			$total_htva = '';
		}
		my $one_more_line = ' hide ';
		if($facture_detail{label} ne '' || $num_ligne == 1)
		{
			$one_more_line = '';
		}
		if(!($facture_detail{id_taux_tva} > 0))
		{
			$facture_detail{id_taux_tva} = 21;
		}
		my $listbox_tvas = get_sql_listbox({with_blank=>'n',col_rel=>"tva_value",selected_id=>$facture_detail{id_taux_tva},col_display=>"tva_reference",table=>"eshop_tvas",ordby=>"id",name=>'id_taux_tva_'.$num,class=>"id_taux_tva saveme saveme_txt form-control recalcul form-control"});

		my %sel = ();
		$sel{$facture_detail{type}} = ' selected="selected" ';
		my $nouvelle_ligne = <<"EOH";
		
			<tbody class="migc4_main_table_tbody $one_more_line">
			
			<tr class="line_product">
					
					<!-- ARTICLE -->
					<td colspan="3" class="facture_articles" data-title="Articles"><div class="cell-value-input">
						<input type="text" id="label_line_$num_ligne" name="line_$num" value="$label" class="recalcul form-control label_line saveme saveme_txt " 
						rel="$num_ligne" placeholder="Ligne n°$num_ligne" />
						<input type="hidden" id="ref_line_$num_ligne" name="ref_$num" value="$reference" class="form-control ref_line saveme saveme_txt " 
						rel="$num_ligne" placeholder="Référence produit" />
						<div class="facture_propositions"></div>
						</div>
					</td>
					
					<!-- TAUX TVA -->
					
					<!--
					<td class="facture_type" data-title="Type">
						$listbox_tvas
					</td>
					-->

					<!-- QTE -->
					<td class="facture_qty" data-title="Qté"><div class="cell-value-input"><input type="text" name="qty_$num" placeholder="Quantité" value="$qty" id="qty_line_$num_ligne"  rel="$num_ligne" class="recalcul text-right form-control saveme qty_line saveme_txt " placeholder="Quantité" /></div></td>

					<!-- PRIX HTVA -->
					<td class="facture_pu" data-title="Prix HTVA">
						<div class="cell-value-input facture_pu_prix">
							<input type="text" name="pu_$num" value="$pu_htva" id="pu_line_$num_ligne" class="text-right recalcul form-control saveme pu_line saveme_txt " placeholder="HTVA" />
						</div>
						<div class="cell-value-input facture_pu_tva">
						$listbox_tvas
						<div>
					</td>
				
					<!-- TOTAL-->
					<td class="facture_pt" data-title="Prix total" ><div class="cell-value-input"><input type="text" name="total_$num" value="$total_htva" id="total_line_$num_ligne" rel="$num_ligne"   class="form-control saveme text-right total_line saveme_txt " disabled="disabled" placeholder="HTVA" /></div></td>

					
				</tr>
				<tr class=" line_product line_product2">
					
					<!-- ORDRE -->
					<td class="facture_nbr" data-title="Ordre"><div class="cell-value-input"><input type="text" class="form-control ordby_line saveme saveme_txt" name="ordby_$num" id="ordby_line_$num_ligne"  value="$num" disabled="disabled" /></div></td>

					<!-- REMARQUE -->					
					<td class="facture_2eline" colspan="4">
						<div class="line_remarque">
							<textarea class="form-control saveme" placeholder="Remarque" name="remarque_$num" style="margin: 2px 0px 2px 0px;">$remarque</textarea>
						</div>
					</td>
					
					<!-- FONCTION --> 
					<td class="facture_del">
						<div class="btn-group" role="group" aria-label="...">

							<a class="btn clear_line btn-danger" data-placement="top" data-original-title="Supprimer définitivement">
								<i class="fa fa-trash fa-fw">
								</i>
							</a>
						</div>
					</td>

			
				</tr>
			</tbody>
EOH

		$lines.= $nouvelle_ligne;
	}

		$lines.= <<"EOH";
		</table>
	</section>
</div>
</div>

			<input type="hidden" name="id_facture" class="id_facture saveme" value="$id_facture" />

<div class="row">
	<div class="col-md-12 text-right">
		<div class="col-md-12 text-right">
					<a data-placement="bottom" data-original-title="$migctrad{back}" class="btn btn-lg btn-default show_only_after_document_ready cancel_edit c22" aria-hidden="true">$ICONCANCEL</a>

		<a  class="btn btn-lg btn-default add_line_product pull-left" data-placement="bottom" data-original-title="Ajouter une ligne">
			<i class="fa fa-plus"></i> 
		</a>

	 	<a data-placement="bottom" data-original-title="$migctrad{save_action}" class="btn btn-lg btn-success $func_save show_only_after_document_ready ">$ICONSAVE</a>

	</div>
</div>
EOH
	print $lines;
	exit;
}

sub make_pdf_documents_pj
{
	my $id = $_[0];
	
	my $table = 'commande_documents';
	my %check_pdf = sql_line({debug=>0,debug_results=>0,select=>'id,migcms_last_published_file',table=>$table ,where=>"id='$id'"});
	return $check_pdf{migcms_last_published_file}.'.pdf';
}

sub ajax_make_pdf_documents_pj
{
	my $id = get_quoted('id') || $_[0];
	my $url = make_pdf_documents_pj($id);	
	
	my $table_name = 'commande_documents';
	$stmt = "update $table_name SET migcms_last_published_file = '$url' WHERE id = '".$id ."' ";
	
 	execstmt($dbh,$stmt);
	
	if($_[0] > 0)
	{
		return '../usr/documents/'.$url;
	}
	else
	{
		print '../usr/documents/'.$url;
		exit;
	}
}

sub map_document
{
	my $doc = $_[0];
	my $table_record = $_[1];
	my $id_record = $_[2];
	my $prefixe = $_[3];
	
	my $select = '';
	if($table_record eq 'intranet_factures' || $table_record eq 'intranet_nc')
	{
	  $select = "$table_record.*, YEAR(date_creation) as annee";
	}
	
	my %record = sql_line({debug=>0,debug_results=>0,select=>$select,table=>$table_record ,where=>"id='$id_record'"});
	my %sys = %{get_migcms_sys({nom_table=>$table_record,id_table=>$id_record})};
	
	# my $code_verif_document = get_document_name({date=>0,sys=>\%sys,prefixe=>$prefixe,id=>$record{id},type=>'document'});		
	
	# $doc =~ s/{code_verif_document}/$code_verif_document/g;
	# $doc =~ s/{code_document}/$code_verif_document/g;
	
	my $numero_document = dm::getcode($dbh,$id_record,$prefixe);	
	$doc =~ s/{numero_document}/$numero_document/g;

	#date du jour
	# my $today = DateTime->today(time_zone=>'local');
	if($record{date_creation} eq '0000-00-00')
	{
		$record{date_creation} = $record{date_facturation};
	}
	  my ($yyyy,$mm,$dd) = split (/-/,$record{date_creation});  
	  
	  
	  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		$year+=1900;	
		$mon++;	
		
	
	if($yyyy > 2000 && $mm > 0 && $dd >0 && length $yyyy > 0 && length $mm > 0 && length $dd > 0)
	{
	}
	else
	{
		$yyyy = $year;
		$mm = $mon;
		$dd = $mday;
	}
	  
	  
	my $today = DateTime-> new (
                     year =>$yyyy,
                     month =>$mm,,
                     day   =>$dd,
                     hour  =>12,
                     time_zone =>'local'
                     );

	
	$today = $today->dmy();
	my @today = split('\-',$today);	
	my $today = $today[0].'/'.$today[1].'/'.$today[2];
	$today = <<"EOH";
	<span style="position:absolute; top:291px">$today</span>
EOH
	$doc =~ s/{today}/$today/g;

	my %ouinon = 
	(
		'y'=>'Oui',
		'n'=>'Non',
	);
	
	my @balises = qw(
						type_intervention
						date_intervention
						date_creation
						technicien
						services
						materiel
						heure_arrivee
						heure_depart
						duree_pause
						temps_reel
						contrat_maintenance
						intervention_distante
						date_echeance
					);
					
	
					
	foreach my $balise (@balises)
	{
		if($balise eq 'contrat_maintenance' || $balise eq 'intervention_distante')
		{
			$record{$balise} = $ouinon{$record{$balise}};
		}
		if($balise eq 'date_echeance')
		{
			$record{$balise} = to_ddmmyyyy($record{$balise});
		}
		
		
		$doc =~ s/{$balise}/$record{$balise}/g;
	}
	
	$doc =~ s/{concerne}/$record{objet}/g;
	$doc =~ s/{date_creation_documentaire}/$record{date_creation}/g;
	
	
	
	my $document_phrase = 'PHRASE';
	
	$doc =~ s/{document_phrase}/$document_phrase/g;
	
	# my $barcode = get_document_name({barcode=>1,date=>0,sys=>\%sys,prefixe=>$doc_prefixes{$table_record},id=>$id_record,type=>'document'});
	
	# $doc =~ s/{barcode}/$barcode/g;

	$doc =~ s/{js}//g;
	
	return $doc;
}

sub save_doc
{
	see();
	log_debug('save_doc','vide','save_doc');

	save_doc_facture();

	log_debug('save_doc ok','','save_doc');
}


sub intranet_factures_get_next_number
{
	my %last_invoice = sql_line({debug=>0,debug_results=>0,table=>'intranet_factures',select => 'MAX(numero_facture) as last_number', where=>""});

	my $next_number = $last_invoice{last_number};
	if($next_number > 0)
	{
		$next_number++;
	}
	else
	{
		$next_number = '20180001';
	}

	# $next_number = sprintf("%.04d",$next_number);
	# print $next_number;
	return $next_number;
}

sub save_doc_facture_fill_numero_facture
{
	my $id = $_[0];

	log_debug('save_doc_facture_fill_numero_facture','','save_doc_facture_fill_numero_facture');
	log_debug($id,'','save_doc_facture_fill_numero_facture');

	my %facture = read_table($dbh,'intranet_factures',$id);
	log_debug($facture{numero_facture},'','save_doc_facture_fill_numero_facture');

	if(!($facture{numero_facture} > 0))
	{
		log_debug('vide','','save_doc_facture_fill_numero_facture');

		$next_number_invoice = intranet_factures_get_next_number();
		log_debug($next_number_invoice,'','save_doc_facture_fill_numero_facture');
		my $stmt = <<"EOH";
			UPDATE intranet_factures SET numero_facture = '$next_number_invoice' WHERE id = '$id'
EOH
		execstmt($dbh,$stmt);
		log_debug($stmt,'','save_doc_facture_fill_numero_facture');
	}
	log_debug('save_doc_facture_fill_numero_facture OK','','save_doc_facture_fill_numero_facture');
}

sub save_doc_facture_calcule_echeance
{
	my %facture = %{$_[0]};
	log_debug('save_doc_facture_calcule_echeance','','save_doc_facture_calcule_echeance');

	#CALCUL ECHEANCE----------------------------------------------------------------------------------------------
	my $delai_j = 0;
	my %delais_j =
		(
			'J+07'=>7,
			'J+15'=>15,
			'J+30'=>30,
			'J+30 fin de mois'=>45
		);
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year+=1900;
	$mon++;

	my ($yyyy,$mm,$dd) = split (/-/,$facture{date_facturation});
	if($yyyy > 2000 && $mm > 0 && $dd >0 && length $yyyy > 0 && length $mm > 0 && length $dd > 0)
	{
	}
	else
	{
		$yyyy = $year;
		$mm = $mon;
		$dd = $mday;
	}
	my $today = DateTime-> new (
		year =>$yyyy,
		month =>$mm,,
		day   =>$dd,
		hour  =>12,
		time_zone =>'local'
	);
	my $sql_date_limite = '';
	$delai_j = $facture{delai_autre};
	if(!($delai_j > 0))
	{
		$delai_j = 8;
	}
	if($delai_j ne '' && $delai_j >=0 )
	{
		$today->add( days => $delai_j);
		$sql_date_limite = $today->ymd;
	}
	log_debug($delai_j,'','save_doc_facture_calcule_echeance');


	$stmt = "update intranet_factures SET date_echeance='$sql_date_limite' WHERE id = '".$facture{id} ."' ";
	log_debug($stmt,'','save_doc_facture_calcule_echeance');
	execstmt($dbh,$stmt);

	log_debug('save_doc_facture_calcule_echeance OK','','save_doc_facture_calcule_echeance');
}

sub save_doc_facture_save_lines {
	my %facture = %{$_[0]};

	#SAVE DOCUMENT LINES------------------------------------------------------------------------------
	foreach my $num_ligne (1 .. $nb_lignes_facture_details)
	{
		my $ref = get_quoted('ref_'.$num_ligne);
		my $line = get_quoted('line_'.$num_ligne);
		my $remarque = get_quoted('remarque_'.$num_ligne);
		my $qty = get_quoted('qty_'.$num_ligne);
		my $id_taux_tva = get_quoted('id_taux_tva_'.$num_ligne);
		if($id_taux_tva eq '')
		{
			$id_taux_tva = 21; #force à 21% si vide
		}
		my %eshop_tvas = sql_line({table=>'eshop_tvas',where=>"id='$id_taux_tva'"});
		my $taux_tva = $eshop_tvas{tva_value};

		if(!($qty >= 0))
		{
			$qty = 0;
		}
		my $pu_htva = get_quoted('pu_'.$num_ligne);
		my $type = get_quoted('type_'.$num_ligne);
		my $ordby = get_quoted('ordby_'.$num_ligne);
		if(!($ordby > 0))
		{
			$ordby = $num_ligne;
		}

		my $pu_tva = $pu_htva  * $taux_tva;
		my $pu_tvac = $pu_htva  * (1 + $taux_tva);

		my %update_document_ligne =
			(
				id_invoice => $facture{id},
				ordby => $ordby,
				pu_htva => $pu_htva,
				ref => $ref,
				qty => $qty,
				type=>$type,
				label => $line,
				remarque => $remarque,
				id_taux_tva => $id_taux_tva,
			);
		%update_document_ligne = %{dm::quoteh(\%update_document_ligne)};

		if($qty > 0 && $pu_htva > 0)
		{
			log_debug('qty:'.$qty,'','save_doc');
			log_debug('pu_htva:'.$pu_htva,'','save_doc');
			log_debug('type:'.$type,'','save_doc');
			log_debug('type:'.$type,'','save_doc');
			log_debug('label:'.$label,'','save_doc');
			log_debug('remarque:'.$remarque,'','save_doc');
			log_debug('id_taux_tva:'.$id_taux_tva,'','save_doc');
		}

		my $id_document_ligne = sql_set_data({dbh=>$dbh,debug=>0,table=>'intranet_facture_lignes',data=>\%update_document_ligne, where=>"id_invoice = '$facture{id}' AND ordby='$update_document_ligne{ordby}'"});

		intranet_totalize_line_document({id_document_ligne=>$id_document_ligne});
	}
}

sub save_doc_facture_reglement_auto {
	my %facture = %{$_[0]};

	#reglement auto au montant total si coché dans facture et si pas encore de reglement
	if($facture{id_type_reglement} > 0 && $facture{id_type_reglement} < 5 && $facture{montant_a_payer_tvac} > 0 )
	{
		my %check_reglement = sql_line({debug=>1,debug_results=>1,table=>'handmade_certigreen_reglements',where=>"id_facture='$facture{id}'"});
		if(!($check_reglement{id} > 0))
		{
			my %nouveau_reglement = (
				date_reglement =>'NOW()',
				id_facture =>$facture{id},
				montant =>$facture{montant_a_payer_tvac},
				id_type_reglement =>$facture{id_type_reglement},
			);
			inserth_db($dbh,'handmade_certigreen_reglements',\%nouveau_reglement);
		}
	}
}


sub save_doc_facture
{
	my $id = get_quoted('id_facture');

	log_debug('save_doc_facture','','save_doc_facture');
	log_debug($id,'','save_doc_facture');

	#rempli N° facture si necessaire
	save_doc_facture_fill_numero_facture($id);
	log_debug('save_doc_facture_fill_numero_facture ok','','save_doc_facture');

	#lecture facture
	my %facture = read_table($dbh,'intranet_factures',$id);

	#calcule date échéance
	save_doc_facture_calcule_echeance(\%facture);
	log_debug('save_doc_facture_calcule_echeance ok','','save_doc_facture');

	#sauvegarde les lignes
	save_doc_facture_save_lines(\%facture);
	log_debug('save_doc_facture_save_lines ok','','save_doc_facture');

	#totalise la facture
	intranet_totalize_doc_facture({id_document=>$facture{id}});
	log_debug('intranet_totalize_doc_facture ok','','save_doc_facture');

	#lecture facture
	%facture = read_table($dbh,'intranet_factures',$id);

	#ajout un reglement si necessaire
	save_doc_facture_reglement_auto(\%facture);
	log_debug('save_doc_facture_reglement_auto ok','','save_doc_facture');

	#change statut facture si necessaire
	def_handmade::set_statut_facture_from_reglements($facture{id});
	log_debug('save_doc_facture_fill_numero_facture ok','','save_doc_facture');

	save_doc_facture_cree_pdf(\%facture);
	log_debug('facture_cree_pdf ok','','save_doc_facture');

	log_debug('save_doc_facture OK','','save_doc_facture');
}

sub save_doc_facture_cree_pdf
{
	my %facture = %{$_[0]};

	my $filename = get_document_name({date=>0,prefixe=>'fa',id=>$facture{id},type=>'document'});
	my $url = $doc_scripts{cmd}.'&&sw=get_html_document_facture&id='.$facture{id}.'';

	my $dir = $config{directory_path}.'/usr/files/FA';
	my $path_new = $config{directory_path}.'/usr/documents/'.$filename.'.pdf';

	dm::write_pdf_from_url($path_new,$url);

	$stmt = "update intranet_factures SET migcms_last_published_file = '$filename' WHERE id = '".$facture{id} ."' ";
	execstmt($dbh,$stmt);
}

sub intranet_totalize_doc_document
{
	log_debug("intranet_totalize_document","","save_doc");

	my %d = %{$_[0]};
	my $id = $d{id_document};
	log_debug("id:$id","","save_doc");
	log_debug("save_fac:$d{save_fac}","","save_doc");
	
	my $table_save = 'intranet_documents';
	my $table_save_ligne = 'intranet_documents_lignes';
	my $where_save = "id_record='$id_record' AND table_record='$table_record'";
	my $where_id_doc_col = 'id_document';
	my $table_save_frais = 'intranet_documents_frais',
	my $col_parent_frais = 'id_facture';
	
	my %intranet_document = read_table($dbh,$table_save,$d{id_document});
	
	my $stmt = <<"EOH";
      UPDATE $table_save
      SET
		 montant_a_payer_htva = (select SUM(tot_htva) FROM $table_save_ligne WHERE $where_id_doc_col = '$id'),
		 montant_a_payer_tva = (select SUM(tot_tva) FROM $table_save_ligne WHERE $where_id_doc_col = '$id'),
		 montant_a_payer_tvac = (select SUM(tot_tvac) FROM $table_save_ligne WHERE $where_id_doc_col = '$id')
	  WHERE
          id = $id
EOH

	log_debug("$stmt","","save_doc");
	execstmt($dbh,$stmt);
	%intranet_document = read_table($dbh,$table_save,$d{id_document});
	
	#report au document
	$stmt = "UPDATE intranet_factures SET montant_a_payer_tvac = '$intranet_document{montant_a_payer_tvac}' WHERE id='$intranet_document{id_record}'";
	log_debug("$stmt","","save_doc");
	execstmt($dbh,$stmt);
	
	#nettoyage
	$stmt = "DELETE FROM intranet_documents_lignes WHERE label='' AND tot_htva = 0 AND remarque = '' AND remise = 0";
	log_debug("$stmt","","save_doc");
	execstmt($dbh,$stmt);
}

sub intranet_totalize_doc_facture
{
	log_debug("intranet_totalize_doc_facture","","save_doc");

	my %d = %{$_[0]};
	my $id = $d{id_document};
	log_debug("id:$id","","save_doc");
	log_debug("save_fac:$d{save_fac}","","save_doc");
	
	my $table_save = 'intranet_factures';
	my $table_save_ligne = 'intranet_facture_lignes';
	my $where_id_doc_col = 'id_invoice';
	
	my %intranet_document = read_table($dbh,$table_save,$d{id_document});
	
	my $stmt = <<"EOH";
      UPDATE $table_save
      SET
		 montant_a_payer_htva = (select SUM(tot_htva) FROM $table_save_ligne WHERE $where_id_doc_col = '$id'),
		 montant_a_payer_tva = (select SUM(tot_tva) FROM $table_save_ligne WHERE $where_id_doc_col = '$id'),
		 montant_a_payer_tvac = (select SUM(tot_tvac) FROM $table_save_ligne WHERE $where_id_doc_col = '$id')
	  WHERE
          id = $id
EOH

	log_debug("$stmt","","save_doc");
	execstmt($dbh,$stmt);
	%intranet_document = read_table($dbh,$table_save,$d{id_document});
	
	#nettoyage
	$stmt = "DELETE FROM $table_save_ligne WHERE label='' AND tot_htva = 0 AND remarque = '' AND remise = 0";
	log_debug("$stmt","","save_doc");
	execstmt($dbh,$stmt);
}

sub intranet_totalize_doc_nc
{
	log_debug("intranet_totalize_doc_nc","","save_doc");

	my %d = %{$_[0]};
	my $id = $d{id_document};
	log_debug("id:$id","","save_doc");
	log_debug("save_fac:$d{save_fac}","","save_doc");
	
	my $table_save = 'intranet_nc';
	my $table_save_ligne = 'intranet_nc_lignes';
	my $where_id_doc_col = 'id_nc';
	
	my %intranet_document = read_table($dbh,$table_save,$d{id_document});
	
	my $stmt = <<"EOH";
      UPDATE $table_save
      SET
		 montant_a_payer_htva = (select SUM(tot_htva) FROM $table_save_ligne WHERE $where_id_doc_col = '$id'),
		 montant_a_payer_tva = (select SUM(tot_tva) FROM $table_save_ligne WHERE $where_id_doc_col = '$id'),
		 montant_a_payer_tvac = (select SUM(tot_tvac) FROM $table_save_ligne WHERE $where_id_doc_col = '$id')
	  WHERE
          id = $id
EOH

	log_debug("$stmt","","save_doc");
	execstmt($dbh,$stmt);
	%intranet_document = read_table($dbh,$table_save,$d{id_document});
	
	#nettoyage
	$stmt = "DELETE FROM $table_save_ligne WHERE label='' AND tot_htva = 0 AND remarque = '' AND remise = 0";
	log_debug("$stmt","","save_doc");
	execstmt($dbh,$stmt);
}

sub intranet_totalize_document
{
	log_debug("intranet_totalize_document","","save_doc");

	my %d = %{$_[0]};
	my $id = $d{id_document};
	log_debug("id:$id","","save_doc");
	log_debug("save_fac:$d{save_fac}","","save_doc");
	
	my $table_save = 'intranet_factures';
	my $table_save_ligne = 'intranet_facture_lignes';
	my $where_save = "id='$id'";

	my %intranet_document = read_table($dbh,$table_save,$d{id_document});
	my $taux_remise_globale = (100 - $intranet_document{remise_globale}) / 100;
	my $remise_globale = ($intranet_document{remise_globale}) / 100;
	
	my $stmt = <<"EOH";
      UPDATE $table_save
      SET
		 montant_total_htva = (select SUM(tot_htva) FROM $table_save_ligne WHERE $where_id_doc_col = '$id'),
		 montant_total_htva_discount = (select SUM(tot_htva * $remise_globale) FROM $table_save_ligne WHERE $where_id_doc_col = '$id'),
         montant_total_htva_discounted = (select SUM(tot_htva * $taux_remise_globale) FROM $table_save_ligne WHERE $where_id_doc_col = '$id')
	  WHERE
          id = $id
EOH

	log_debug("$stmt","","save_doc");

	execstmt($dbh,$stmt);
	
	my $ordby = 1;
	if($intranet_document{table_record} ne '' && $intranet_document{id_record} > 0)
	{
		#DOCUMENT
		my %doc = read_table($dbh,$intranet_document{table_record},$intranet_document{id_record});
		my %document = read_table($dbh,$table_save,$d{id_document});
		my %ctm = sql_line({debug=>0,debug_results=>0,table=>'members',where=>"id=$doc{id_member}"});

		$stmt = "UPDATE $table_save SET montant_total_discounted_avec_frais_htva=montant_total_htva_discounted,montant_a_payer_htva = montant_total_htva_discounted where id='$document{id}'";
		log_debug($stmt,'','debugdoc');
		execstmt($dbh,$stmt); 
	}
	elsif($table_save eq 'intranet_factures')
	{
		$stmt = "UPDATE $table_save SET montant_total_discounted_avec_frais_htva=montant_total_htva_discounted,montant_a_payer_htva = montant_total_htva_discounted where id='$id'";
		log_debug($stmt,'','debugdoc');
		execstmt($dbh,$stmt); 	}
	else
	{
		log_debug("table_record: $intranet_document{table_record}","","debugdoc");
		log_debug("id_record: $intranet_document{id_record}","","debugdoc");
	}
	
	$stmt = "DELETE FROM intranet_documents_lignes WHERE label='' AND tot_htva = 0 AND remarque = '' AND remise = 0";
	execstmt($dbh,$stmt);
}

sub intranet_totalize_line_document
{
	my %d = %{$_[0]};
	
	my %intranet_document_lignes = read_table($dbh,'intranet_facture_lignes',$d{id_document_ligne});
	my %eshop_tvas = sql_line({table=>'eshop_tvas',where=>"id='$intranet_document_lignes{id_taux_tva}'"});
	my $taux_tva = $eshop_tvas{tva_value};

	my $pu_tva = $intranet_document_lignes{pu_htva} * $taux_tva;
	my $pu_tvac = $intranet_document_lignes{pu_htva} * ( 1 + $taux_tva);
	my $pu_htva = $intranet_document_lignes{pu_htva};

	my $tot_htva = $intranet_document_lignes{qty} * $intranet_document_lignes{pu_htva};
	my $tot_tva =  $intranet_document_lignes{qty} * $pu_tva;
	my $tot_tvac =  $intranet_document_lignes{qty} * $pu_tvac;

	my %update_document_ligne = 
	(
		pu_tva =>  $pu_tva,
		pu_tvac => $pu_tvac,
		tot_htva => $tot_htva,
		tot_tva => $tot_tva,
		tot_tvac => $tot_tvac,
	);
	sql_set_data({dbh=>$dbh,debug=>1,table=>'intranet_facture_lignes',data=>\%update_document_ligne, where=>"id='$d{id_document_ligne}'"});
}




sub copy_document_to_invoice
{
	my $id_document = $_[0];
	my %document = read_table($dbh,'intranet_documents',$id_document);
	my %ctm = read_table($dbh,'members',$document{id_member});
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); 
    $year+=1900;
	$mon++;

	#vérifie si le document est déja facturé-> on peut facturer plusieurs fois le meme document, demande du client  du 17/07/17
	#le client décide que finalement on ne peut plus facturer plusieurs fois
	my %check_existing_facture = sql_line({debug=>0,debug_results=>0,table=>'intranet_factures',where=>"id_document='$document{id}'"});
	if($check_existing_facture{id} > 0)
	{
		print "deja_facture";
		exit;
	}
	#numero et année de la nouvelle facture
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); 
    $year+=1900;
	$mon++;
	my $prochain_numero =  intranet_factures_get_next_number();
			log_debug('confirm_invoicing2c','','confirm_invoicing');
	$document{id_document} = $document{id};
	$document{annee} = $year;
	$document{statut} = 'emise';
	$document{date_facturation} = 'NOW()';
	$document{numero} = $prochain_numero;
	$document{pdf_filename} = '';
	if($document{table_record} ne '' && $document{id_record} > 0)
	{
		my %record = sql_line({table=>$document{table_record},where=>"id='$document{id_record}'"});
		$document{reference_client_facture} = $record{reference_client};
		$document{facture_civilite_id} = $record{facture_civilite_id};

	}
	delete $document{id};

	#crée une facture à partir du document
	%document = %{dm::quoteh(\%document)};
	my $id_facture = inserth_db($dbh_data,'intranet_factures',\%document);
	
	add_history({action=>'insert',page=>'intranet_factures',id=>"$id_facture"});
	
	#recopie les lignes de facture
	my @intranet_documents_lignes = sql_lines({debug=>0,debug_results=>0,table=>'intranet_documents_lignes',where=>"id_document='$document{id_document}'"});
	foreach $ligne (@intranet_documents_lignes)
	{
		my %ligne = %{$ligne};
		$ligne{id_invoice} = $id_facture;
		$ligne{id_document_ligne} = $ligne{id};
		delete $ligne{id};
		%ligne = %{dm::quoteh(\%ligne)};
		my $id_facture_ligne = sql_set_data({dbh=>$dbh,debug=>0,table=>'intranet_facture_lignes',data=>\%ligne, where=>"id_invoice='$ligne{id_invoice}' AND ordby='$ligne{ordby}'"});      		
		add_history({action=>'insert',page=>'intranet_facture_lignes',id=>"$id_facture_ligne"});
	}
	
	#recopie les totaux de facture
	my @intranet_documents_bas = sql_lines({debug=>0,debug_results=>0,table=>'intranet_documents_bas',where=>"id_facture='$document{id_document}'"});
	foreach $ba (@intranet_documents_bas)
	{
		my %ba = %{$ba};
		$ba{id_facture} = $id_facture;
		delete $ba{id};
		%ba = %{dm::quoteh(\%ba)};
		my $id_facture_ba = sql_set_data({dbh=>$dbh,debug=>0,table=>'intranet_factures_bas',data=>\%ba, where=>"id_facture='$ba{id_facture}' AND ordby='$ba{ordby}'"});      		
		add_history({action=>'insert',page=>'intranet_factures_bas',id=>"$id_facture_ba"});
	}
			
	return $id_facture;
}

sub copy_invoice_to_nc
{
	my $id_facture = $_[0];# get_quoted('id_document');
	my %facture = read_table($dbh,'intranet_factures',$id_facture);
	
	#numero et année de la nouvelle facture
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); 
    $year+=1900;
	$mon++;
	my $prochain_numero =  intranet_nc_get_next_number();
	
	$facture{id_facture} = $facture{id};
	$facture{annee} = $year;
	$facture{statut} = 'brouillon';
	$facture{date_facturation} = 'NOW()';
	$facture{numero} = $prochain_numero;
	$facture{pdf_filename} = '';
	$facture{migcms_last_published_file} = '';
	
	delete $facture{id};
	delete $facture{id_document};
	# delete $facture{date_facturation};	

	#crée une facture à partir du document
	my %nc = %{dm::quoteh(\%facture)};
	my $id_nc = sql_set_data({dbh=>$dbh,debug=>0,table=>'intranet_nc',data=>\%nc, where=>""});      		
	add_history({action=>'insert',page=>'intranet_nc',id=>"$id_facture"});
	
	# my %sys = 
	# (
		# nom_table => 'intranet_nc',
		# id_table => $id_nc,
		# id_user => $user{id},
		# moment => 'NOW()'				
	# );
	# inserth_db($dbh_data,'migcms_sys',\%sys);
	
	#recopie les lignes de facture
	my @intranet_facture_lignes = sql_lines({debug=>0,debug_results=>0,table=>'intranet_facture_lignes',where=>"id_invoice='$nc{id_facture}'"});
	foreach $ligne (@intranet_facture_lignes)
	{
		my %ligne = %{$ligne};
		$ligne{id_nc} = $id_nc;
		$ligne{id_facture_ligne} = $ligne{id};
		delete $ligne{id};
		delete $ba{id_facture};
		%ligne = %{dm::quoteh(\%ligne)};
		my $id_nc_ligne = sql_set_data({dbh=>$dbh,debug=>0,table=>'intranet_nc_lignes',data=>\%ligne, where=>"id_nc='$ligne{id_invoice}' AND ordby='$ligne{ordby}'"});      		
		add_history({action=>'insert',page=>'intranet_facture_lignes',id=>"$id_nc_ligne"});
	}
	
	#recopie les totaux de facture
	my @intranet_factures_bas = sql_lines({debug=>0,debug_results=>0,table=>'intranet_factures_bas',where=>"id_facture='$nc{id_facture}'"});
	foreach $ba (@intranet_factures_bas)
	{
		my %ba = %{$ba};
		$ba{id_nc} = $id_nc;
		delete $ba{id};
		delete $ba{id_facture};
		%ba = %{dm::quoteh(\%ba)};
		my $id_nc_ba = sql_set_data({dbh=>$dbh,debug=>0,table=>'intranet_nc_bas',data=>\%ba, where=>"id_nc='$ba{id_nc}' AND ordby='$ba{ordby}'"});      		
		add_history({action=>'insert',page=>'intranet_nc_bas',id=>"$id_nc_ba"});
	}
	
	return $id_nc;
}

sub cut_last_page
{
	use PDF::API2;
	
	my $path_temp = $_[0];
	my $path_new = $_[1];
	my $nocut = $_[2];
	
	my $big_pdf = PDF::API2->new(-file => $path_new);
	
	my $pds;
	if(-e $path_temp)
	{
		eval { $pds = PDF::API2->open( $path_temp ) };
		
		my $pn = $pds->pages;
		if($nocut eq 'nocut')
		{
			$big_pdf->importpage($pds,$_) for 1..$pn;
		}
		else
		{
			$big_pdf->importpage($pds,$_) for 1..$pn-1;
		}
		unlink($path_temp);		
	}
	
	$big_pdf->saveas;
	$big_pdf->end;
}

sub get_html_document_facture
{
	my $id = get_quoted('id');
	my %license = sql_line({debug=>0,debug_results=>0,table=>'handmade_certigreen_licenses'});
	my $pj_name = dm::getcode($dbh,$id,'FA');
	my $titre_annexe_doc = dm::getcode($dbh,$id,$prefixe);
	my %facture = sql_line({debug=>0,debug_results=>0,table=>'intranet_factures',where=>"id='$id'"});
	my %cg = sql_line({debug=>0,debug_results=>0,table=>'handmade_certigreen_licenses'});
	my $body = "";
	my $prefixe = "fa";
	my $head = "";
	my $number = 1;

	($head,$body,$number) = add_page({type=>'resume_document',number=>$number, prefixe=>$prefixe,id=>$id,facture=>\%facture, license=>\%license,head=>$head,body=>$body});

	#habillage document
	my $html_document = get_html_document_set_canvas({head=>$head,body=>$body,facture=>\%facture,license=>\%license});

	print $html_document;
	exit;
}

sub add_page
{
	my %d = %{$_[0]};
	
	my %license = %{$d{license}};
	my %facture = %{$d{facture}};
	my $nouvelle_page = '';
	$facture{date_facturation} = sql_to_human_date($facture{date_facturation});

	my %html = sql_line({table=>'migcms_textes_emails',where=>"table_name='bloc client'"});
	my $bloc_client = get_traduction({debug=>0,id=>$html{id_textid_raw_texte},id_language=>$config{current_language}});
	
	my %html = sql_line({table=>'migcms_textes_emails',where=>"table_name='bloc client 3col'"});
	my $bloc_client_3col = get_traduction({debug=>0,id=>$html{id_textid_raw_texte},id_language=>$config{current_language}});
	
	if($pdi{id} > 0)
	{
		$bloc_client = $bloc_client_3col;
	}
	
	my %html = sql_line({table=>'migcms_textes_emails',where=>"table_name='page content'"});
	my $bloc_page = get_traduction({debug=>0,id=>$html{id_textid_raw_texte},id_language=>$config{current_language}});
	my $pj_name = dm::getcode($dbh,$d{id_record},$d{prefixe});
	
	
	$facture_ligne_bas{html} = <<"EOH";
			<tr class="{hide_class}">
					<td class="facture-table-col2" colspan="3"><b>{libelle} </b></td>
					<td class="facture-table-col5 text-right"><b>{ligne_total_htva}</b></td>
			</tr>
EOH

	$facture_ligne_bas_1col{html} = <<"EOH";
					<tr class="{hide_class}" style="border:0px!important; text-transform:none!important;">
							<td class="facture-table-col2  text-center" colspan="4"  style="border:0px!important; text-transform:none!important;"><b style="text-transform:none!important;">{libelle} </b></td>
					</tr>
EOH

	$facture_ligne_tableau{html} = <<"EOH";
		<tr class="{hide_class}">
			<td class="facture-table-col2">{libelle} <i>{remarque}</i></td>
			<td class="facture-table-col3" style="width:30px;">{qte}</td>
			<td class="facture-table-col4 text-right" style="width:80px;text-align:right!important;">{puhtva}</td>
			<td class="facture-table-col5 text-right" style="width:80px;text-align:right!important;">{ligne_total_htva}</td>
			<td class="facture-table-col5 text-right" style="width:80px;text-align:right!important;">{ligne_taux_tva}</td>
		</tr>	
EOH

	if($d{type} eq 'resume_document')
	{
		$d{head} .= add_bloc_head({size=>'858',number=>$d{number}});
		$nouvelle_page = add_page_resume_document({bloc_page=>$bloc_page,bloc_client=>$bloc_client,license=>\%license,facture=>\%facture,number=>$d{number}++,prefixe=>$d{prefixe},pj_name=>$pj_name});
	}
	elsif($d{type} eq 'content')
	{
		$d{head} .= add_bloc_head({size=>'858',number=>$d{number}});
		$nouvelle_page = add_page_content({bloc_page=>$bloc_page,bloc_client=>$bloc_client,license=>\%license,facture=>\%facture,number=>$d{number}++,prefixe=>$d{prefixe},pj_name=>$pj_name});
	}

	$d{body} .= $nouvelle_page;
	
	return ($d{head},$d{body},$d{number});
}

sub add_page_resume_document
{
	my %d = %{$_[0]};

	my $bloc_page = $d{bloc_page};
	my $bloc_client = $d{bloc_client};
	
	my %license = %{$d{license}};
	my %facture = %{$d{facture}};

	my $txt_date_limite = '';
	if($facture{date_echeance} ne '0000-00-00' && $facture{date_echeance} ne '')
	{
		$facture{date_echeance} = sql_to_human_date($facture{date_echeance});
		$txt_date_limite = " Echéance de paiement: <strong>$facture{date_echeance}</strong> ";
	}
	my $payment_info = "Numéro de compte: <strong>$license{iban}</strong> $txt_date_limite. Numero de document en communication.";
	if($d{prefixe} eq 'cmd')
	{
		$payment_info = "";
	}

	my @lignes_bas_complet = sql_lines({debug=>1,debug_results=>1,table=>'intranet_factures_bas',where=>"id_facture='$facture{id}'",ordby=>'ordby'});

	my $adresse_bien = "$facture{adresse_rue} $facture{adresse_numero} $facture{adresse_cp} $facture{adresse_ville}";
	my $nom_client = "$facture{firstname} $facture{lastname}";
	
	my $page_content .= <<"EOH";
	Adresse de contrôle: <b>$adresse_bien</b><br />
	Dossier: <b>$nom_client</b><br /><br />
		<table class="table table-bordered"> 
			<thead>
				<tr>
					<th style="width:65%">
						Description
					</th>
					<th style="width:5%">
						Qté
					</th>
					<th style="width:10%">
						P.U.&nbsp;hTVA
					</th>
					<th style="width:10%">
						Montant&nbsp;hTVA
					</th>
					<th style="width:10%">
						TVA
					</th>
			</thead>
			<tbody>
EOH
	
	my @document_details = sql_lines({debug=>0,debug_results=>0,table=>'intranet_facture_lignes',where=>"id_invoice='$facture{id}' AND (label != '' OR ref != '')",ordby=>'ordby'});

	$facture{montant_a_payer_htva} = display_price($facture{montant_a_payer_htva});
	$facture{montant_a_payer_tva} = display_price($facture{montant_a_payer_tva});
	$facture{montant_a_payer_tvac} = display_price($facture{montant_a_payer_tvac});
	my $code = dm::getcode($dbh,$facture{id_record},$d{prefixe});
	
	my $total_qty = 0;
	my $total_pu_htva = 0;
	my $total_pu_tva = 0;
	my $total_pu_tvac = 0;
	foreach $facture_detail (@document_details)
	{
		my %facture_detail = %{$facture_detail};
		
		$facture_detail{pu_htva} = display_price($facture_detail{pu_htva});
		$facture_detail{tot_htva} = display_price($facture_detail{tot_htva});
		$facture_detail{tot_tva} = display_price($facture_detail{tot_tva});
		
		$total_qty += $facture_detail{qty};
		$total_pu_htva += $facture_detail{pu_htva};
		$total_pu_tva += $facture_detail{pu_tva};
		$total_pu_tvac += $facture_detail{pu_tvac};
		
		$page_content .= <<"EOH";	
			<tr>
					<td style="width:65%">
						<span style="font-size:10px">$facture_detail{label}</span>
					</td>
					<td style="width:5%">
						$facture_detail{qty}
					</td>
					<td style="width:10%">
						$facture_detail{pu_htva}
					</td>
					<td style="width:10%">
						$facture_detail{tot_htva}
					</td>
					<td style="width:10%">
						$facture_detail{tot_tva}
					</td>
			</tr>
EOH
	}
	
	my %handmade_certigreen_license = sql_line({table=>'handmade_certigreen_licenses'});

	$total_pu_htva = display_price($total_pu_htva);
	$total_pu_tva = display_price($total_pu_tva);
	

	$page_content .= <<"EOH";
	
		<tr>
					<td style="width:65%">
						<b>Totaux</b>
					</td>
					<td style="width:5%">
						<b>$total_qty</b>
					</td>
					<td style="width:10%">
						<b>&nbsp;</b>
					</td>
					<td style="width:10%">
						<b>$total_pu_htva</b>
					</td>
					<td style="width:10%">
						<b>$total_pu_tva</b>
					</td>
				
				
				</tr>
	
			</tbody> 
			<tfoot>
	
				<tr>
					<th colspan="6">
						Informations de paiement<br />
						Numéro de compte Fortis: <b>$handmade_certigreen_license{iban}</b> | BIC <b>$handmade_certigreen_license{bic}</b><br />
						Communication du virement: FA$facture{numero}
						
					</th>
				</tr>
			</tfoot>
		</table> 
		<div class="row">
			<div class="col-md-6">
			
			</div>
			<div class="col-md-6">
				<div class="row">

					<div class="col-md-6 text-right">
						<b style="font-size:13pt">Montant net à payer: </b>
					</div>
					<div class="col-md-6 text-right ">
					<b style="font-size:13pt">	$facture{montant_a_payer_tvac}</b>
					</div>
				</div>
			</div>
		</div>
		<div class="footer_certigreen" style="position:absolute;bottom:0px;">
		
		<span style="font-size:10px">
$handmade_certigreen_license{cg}
</span>
		
		<br />
		<h4 class="text-right hide">www.certigreen.be</h4>
		<span style="font-size:12px">
		<b>$handmade_certigreen_license{license_name}</b> | 
		<b>$handmade_certigreen_license{street}, $handmade_certigreen_license{number}</b> | 
		<b>$handmade_certigreen_license{zip} $handmade_certigreen_license{city}</b> | 
		GSM <b>$handmade_certigreen_license{gsm}</b> | 
		Tél. <b>$handmade_certigreen_license{tel}</b> |
		Mail <b>$handmade_certigreen_license{email}</b>
		</span>
		<table class="table"><thead><tr><th>
		RPM LIÈGE TVA $handmade_certigreen_license{vat} 
		
		</th>
		<th class="text-right">
		Fortis $handmade_certigreen_license{iban} I BIC $handmade_certigreen_license{bic}
		</th></tr></thead></table>



		</div>
EOH
	
	my $ss_titre = "";

	$page_content = tags_document(
	{
		titre => "Facture N° $d{pj_name}",
		phrase => $payment_info,
		numero_document => $d{pj_name},
		date => $facture{date_facturation},
		document => $bloc_page,
		number => $d{number},
		bloc_client => $bloc_client,
		license=>\%license,
		facture=>\%facture,
		page_content => $page_content,
	});

	return $page_content;
}

sub tags_document
{
	my %d = %{$_[0]};
	my %license = %{$d{license}};

	my %facture = %{$d{facture}};

	my %user = ();
	if($facture{migcms_id_user_last_edit} > 0)
	{
		%user = read_table($dbh,'users',$facture{migcms_id_user_last_edit});
	}

	my $phrase_classe = '';
	if(trim($d{phrase}) eq '')
	{
		$phrase_classe = " hide ";
	}
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year+=1900;	
	$mon++;	
	$license{tel} = format_tel($license{tel});
	$license{fax} = format_tel($license{fax});
	$license{gsm} = format_tel($license{gsm});
	# see(\%document);
	my $type = 'facture';

	my $date = to_ddmmyyyy($facture{date_mission});
	if($date eq '//' || $date eq '00/00/0000')
	{
		$date = to_ddmmyyyy($facture{date_facturation});
	}
	if($date eq '00/00/0000' && $type eq 'facture')
	{
		$stmt = "UPDATE `intranet_factures` SET `date_facturation` = NOW() WHERE `intranet_factures`.`id` = $facture{id};";
		execstmt($dbh,$stmt);
		$date = $mday.'/'.$mon.'/'.$year;
	}

	my $pjname = dm::getcode($dbh,$facture{id},$doc_prefixes{$facture{table_record}});
	
	my $date_echeance = '';
	my $type_document = '<b style="font-size:14pt">Facture N° FA'.$facture{numero_facture}.'</b><br/><br/>';
	if($facture{date_echeance} ne '')
	{
		$date_echeance = "Date d'échéance : $facture{date_echeance}";
	}

	my $civilite = '';
	if($facture{facture_civilite_id} > 0)
	{
		my %r = read_table($dbh,'migcms_codes',$facture{facture_civilite_id});
		$civilite = $r{v1};		
	}
			
	$d{document} =~ s/\-\-\-number\-\-\-/$d{number}/g;
	$d{document} =~ s/\-\-\-pjname\-\-\-/$pjname/g;
	$d{document} =~ s/\-\-\-initiales\-\-\-/$user{initiales}/g;
	$d{document} =~ s/\-\-\-bloc_client\-\-\-/$d{bloc_client}/g;
	$d{document} =~ s/\-\-\-year\-\-\-/$year/g;
	$d{document} =~ s/\-\-\-month\-\-\-/$mon/g;
	$d{document} =~ s/\-\-\-day\-\-\-/$mday/g;
	
	$d{document} =~ s/\-\-\-titre\-\-\-/$d{titre}/g;
	$d{document} =~ s/\-\-\-phrase\-\-\-/$d{phrase}/g;
	$d{document} =~ s/\-\-\-phrase_classe\-\-\-/$phrase_classe/g;
	$d{document} =~ s/\-\-\-date\-\-\-/$date/g;
	$d{document} =~ s/\-\-\-refclient\-\-\-/$facture{reference_client}$facture{reference_client_facture}/g;
	$d{document} =~ s/\-\-\-page_content\-\-\-/$d{page_content}/g;
	
	$d{document} =~ s/\-\-\-dateecheance\-\-\-/$date_echeance/g;
	$d{document} =~ s/\-\-\-typedocument\-\-\-/$type_document/g;
	
	
	
	
	my $license_name = "$license{license_name} $license{license_type_company}";
	my $signature_ligne1 = $license{titre_document1};
	my $signature_ligne1_color = $license{titre_document1_color};
	my $signature_ligne2 = $license{titre_document2};
	my $signature_ligne2_color = $license{titre_document2_color};
	my $signature_ligne3 = $license{titre_document3};
	my $signature_ligne3_color = $license{titre_document3_color};	
	
	my $tva_client = "";
	if($ctm{tva} ne "") {
		$tva_client = 'TVA : <span class="light">'.$ctm{tva}.'</span>';
	}
	
	
	# see(\%pdi);
	if($pdi{id} > 0)
	{
	
	$d{document} =~ s/\-\-\-pdi_company\-\-\-/$pdi{nom}/g;
	$d{document} =~ s/\-\-\-pdi_street\-\-\-/$pdi{street} $pdi{number} $pdi{box}/g;
	$d{document} =~ s/\-\-\-pdi_number\-\-\-/$pdi{number} $pdi{box}/g;
	$d{document} =~ s/\-\-\-pdi_city\-\-\-/$pdi{city}/g;
	$d{document} =~ s/\-\-\-pdi_zip\-\-\-/$pdi{zip}/g;
	$d{document} =~ s/\-\-\-pdi_country\-\-\-/$pdi{country}/g;
	$d{document} =~ s/\-\-\-pdi_tva\-\-\-//g;
	
	}
	$d{document} =~ s/\-\-\-license_company_header\-\-\-/$license_name/g;
	$d{document} =~ s/\-\-\-license_company\-\-\-/$license{license_name} $license{license_type_company}/g;
	$d{document} =~ s/\-\-\-license_street\-\-\-/$license{street} $license{street2}/g;
	$d{document} =~ s/\-\-\-license_number\-\-\-/$license{number}/g;
	$d{document} =~ s/\-\-\-license_city\-\-\-/$license{city}/g;
	$d{document} =~ s/\-\-\-license_zip\-\-\-/$license{zip}/g;
	$d{document} =~ s/\-\-\-license_country\-\-\-/$license{country}/g;
	$d{document} =~ s/\-\-\-license_tel\-\-\-/$license{tel}/g;
	$d{document} =~ s/\-\-\-license_fax\-\-\-/$license{fax}/g;
	$d{document} =~ s/\-\-\-license_gsm\-\-\-/$license{gsm}/g;
	$d{document} =~ s/\-\-\-license_mail\-\-\-/$license{email}/g;
	$d{document} =~ s/\-\-\-license_iban\-\-\-/$license{iban}/g;
	$d{document} =~ s/\-\-\-license_bic\-\-\-/$license{bic}/g;
	$d{document} =~ s/\-\-\-license_rpm\-\-\-/$license{rpm}/g;
	$d{document} =~ s/\-\-\-license_division\-\-\-/$license{division}/g;
	$d{document} =~ s/\-\-\-license_siteweb_url\-\-\-/http\:\/\/$license{domaine}/g;
	$d{document} =~ s/\-\-\-license_siteweb\-\-\-/$license{domaine}/g;
	$d{document} =~ s/\-\-\-license_tva\-\-\-/$license{vat}/g;
	$d{document} =~ s/\-\-\-signature document\-\-\-/<br>$license{signature_document}/g;
	
	$d{document} =~ s/\-\-\-signature_ligne1\-\-\-/$signature_ligne1/g;
	$d{document} =~ s/\-\-\-signature_ligne1_color\-\-\-/$signature_ligne1_color/g;
	$d{document} =~ s/\-\-\-signature_ligne2\-\-\-/$signature_ligne2/g;
	$d{document} =~ s/\-\-\-signature_ligne2_color\-\-\-/$signature_ligne2_color/g;
	$d{document} =~ s/\-\-\-signature_ligne3\-\-\-/$signature_ligne3/g;
	$d{document} =~ s/\-\-\-signature_ligne3_color\-\-\-/$signature_ligne3_color/g;
	
	
	
	# $d{document} =~ s/\-\-\-client_name\-\-\-/$ctm{firstname} $ctm{lastname}/g;
	# $d{document} =~ s/\-\-\-client_adres1\-\-\-/$ctm{street} $ctm{number} $ctm{box}/g;
	# $d{document} =~ s/\-\-\-client_adres2\-\-\-/$ctm{zip} $ctm{city}/g;
	# $d{document} =~ s/\-\-\-client_adres3\-\-\-/$ctm{country}/g;
	# $d{document} =~ s/\-\-\-client_vat\-\-\-/$tva_client/g;
	# $d{document} =~ s/\-\-\-client_tel\-\-\-/$ctm{tel}/g;
	# $d{document} =~ s/\-\-\-client_email\-\-\-/$ctm{email}/g;
	
	
	# $d{document} =~ s/\-\-\-client_name\-\-\-/$facture{facture_prenom} $facture{facture_nom}/g;
	# $d{document} =~ s/\-\-\-client_adres1\-\-\-/$facture{facture_street} $facture{facture_number}/g;
	# $d{document} =~ s/\-\-\-client_adres2\-\-\-/$facture{facture_zip} $facture{facture_city}/g;
	# $d{document} =~ s/\-\-\-client_adres3\-\-\-/Belgique/g;
	# $d{document} =~ s/\-\-\-client_vat\-\-\-/$facture{facture_societe_tva}/g;
	# $d{document} =~ s/\-\-\-client_tel\-\-\-/$facture{tel}/g;
	# $d{document} =~ s/\-\-\-client_email\-\-\-/$facture{facture_email}/g;
	
	$d{document} =~ s/\-\-\-client_name\-\-\-/$civilite $facture{nom_f}/g;
	$d{document} =~ s/\-\-\-client_adres1\-\-\-/$facture{adresse_f}/g;
	$d{document} =~ s/\-\-\-client_adres2\-\-\-/$facture{ville_f}/g;
	$d{document} =~ s/\-\-\-client_adres3\-\-\-/$facture{pays_f}/g;
	$d{document} =~ s/\-\-\-client_vat\-\-\-/$facture{societe_f}/g;
	$d{document} =~ s/\-\-\-client_tel\-\-\-/$facture{tva_f}/g;
	$d{document} =~ s/\-\-\-client_email\-\-\-/$facture{facture_email}/g;


	$d{document} =~ s/\-\-\-numero_facture_raw\-\-\-/$facture{numero}/g;
	


	
	if($sys{id} > 0)
	{
		my $barcode = get_document_name({barcode=>1,date=>0,sys=>\%sys,prefixe=>$doc_prefixes{$facture{table_record}},id=>$facture{id_record},type=>'document'});
		$d{document} =~ s/\-\-\-barcode\-\-\-/$barcode/g;
	}
	
	
	my %migcms_setup = sql_line({debug=>0,table=>"migcms_setup",select=>'',where=>"",limit=>'0,1'});
	
	
	
	
	my %logo_facture = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='handmade_certigreen_licenses' and token='1'",limit=>'',ordby=>''});
	
	$logo_facture{file_dir} =~ s/\.\.\///g;
	my $url_logo_facture = $config{fullurl}.'/'.$logo_facture{file_dir}.'/'.$logo_facture{full}.$logo_facture{ext};
	my $img = "<img src=\"$url_logo_facture\" width=\"$license{logo_width}\" height=\"$license{logo_height}\">";
	if($logo_facture{full} eq '')
	{
		$img = "$license{license_name}"
	}
	
	
	my $banner = <<"EOH";
	<a href="http://$license{domaine}">$img</a>
EOH
	$d{document} =~ s/\-\-\-banner\-\-\-/$banner/g;

	
	return $d{document};
}

sub add_bloc_head
{
	my %d = %{$_[0]};
	
	my $number = $d{number};
	
	return <<"EOH";
		if(jQuery('#pagescontent$number').contents().length > 0)
		{
			// when we need to add a new page, use a jq object for a template
			// or use a long HTML string, whatever your preference
			jQuerypage = jQuery("#page_template2").clone().addClass("document").css("display", "block");
			
			// fun stuff, like adding page numbers to the footer
			//jQuerypage.find(".footer span").append(page);
			jQuery("body").append(jQuerypage);
			page++;
			
			// here is the columnizer magic
			jQuery('#pagescontent$number').columnize({
				columns: 1,
				target: ".document:last .document-texte",
				manualBreaks : true,
				overflow: {
					height: $d{size},
					id: "#pagescontent$number",
					doneFunc: function(){
						buildPages();
					}
				}
			});
		}
EOH
}

sub get_html_document_set_canvas
{
	my %d = %{$_[0]};
	
	my %html = sql_line({table=>'migcms_textes_emails',where=>"table_name='PAGE - Autres documents'"});

	my $page_container = get_traduction({debug=>0,id=>$html{id_textid_raw_texte},id_language=>$config{current_language}});
	
		# see(\%html);
		# print $page_container;
	# exit;
	
	$page_container =~ s/\-\-\-body\-\-\-/$d{body}/g;
	$page_container =~ s/\-\-\-head\-\-\-/$d{head}/g;
	
	my %record = %{$d{record}};
	my %pdi = %{$d{pdi}};
	my %document = %{$d{document}};
	my %ctm = %{$d{ctm}};
	my %sys = %{$d{sys}};

	
	my %license = sql_line({debug=>0,debug_results=>0,table=>'handmade_certigreen_licenses'});
	$page_container = tags_document({document=>$page_container,license=>\%license,ctm=>\%ctm,
										sys=>\%sys,
										rec_document=>\%document,
										record=>\%record, pdi =>\%pdi,});

	return $page_container;
}

sub confirm_invoicing
{
	my $id_record = get_quoted('id');
	my $prefixe = get_quoted('tdoc');
	my $table_name = $doc_tables{$prefixe};
	
	# log_debug('confirm_invoicing1','vide','confirm_invoicing');
	# log_debug('confirm_invoicing1','','confirm_invoicing');
	
	#récupere le document pour cette table et cet id
	my %document = sql_line({debug=>1,debug_results=>1,table=>'intranet_documents',where=>"table_record='$table_name' AND id_record='$id_record'"});

	# log_debug('confirm_invoicing2','','confirm_invoicing');
		
	#copie le document dans une facture
	my $new_id_facture = copy_document_to_invoice($document{id},'fc0');
	
	# log_debug('confirm_invoicing3','','confirm_invoicing');
	
	$stmt = "update intranet_factures SET migcms_id = CONCAT('FC',LPAD( id, 7, '0' )) WHERE id = '".$new_id_facture."' ";
	execstmt($dbh,$stmt);

	
	my $filename = make_pdf_facture($new_id_facture,$prefixe);	
	
	# log_debug('confirm_invoicing4','','confirm_invoicing');
	my %record = read_table($dbh,'intranet_factures',$document{id_record});
	my %agence = sql_line({table=>'members',where=>"id='$record{id_member_agence}'"});
	my $nom_agence = "$agence{firstname} $agence{lastname}";
	$nom_agence =~ s/\'/\\\'/g;	
	$stmt = "update intranet_factures SET migcms_last_published_file = '$filename',nom_agence='$nom_agence' WHERE id = '".$new_id_facture."' ";
	execstmt($dbh,$stmt);
	
	
	
	
	
	
	log_debug($stmt,'','confirm_invoicing');
	log_debug($filename,'','confirm_invoicing');
	
	print $config{baseurl}.'/usr/documents/'.$filename;
	exit;	
}

sub get_sel_from_script
{
	my $script = $_[0];
	my %url = sql_line({select=>'id',table=>'scripts',where=>"url='$script'"});
	return $url{id};
}


sub get_fw_facture
{
	use POSIX qw/ceil/;
	my $prefixe = $_[0];
	my $table_record = $_[1];
	my $id_record = $_[2];
	my $print = $_[3];
	my $type = $_[4];
	my $id_nc = $_[5];
	my $limitea = $_[6];
	
	#FACTURE, REGIE OU VENTE----------------------------------------------------
	my $nb_lignes_facture_details = 50;
	my $nb_lignes_par_page = 35;
	# my $nb_char_par_ligne = 40;
	my $nb_char_par_ligne_label = 50;
	my $nb_char_par_ligne_remarque = 70;
	
	
	my $fac = '';

	my %facture = ();
	my %record = ();
	
	my %record = read_table($dbh,$table_record,$id_record); #lecture du record (ex: handmade_selion_documents_devis, 3)
	my %ctm = sql_line({debug=>0,debug_results=>0,table=>'handmade_selion_ctm',where=>"id='$record{id_member}'"});
	my %license = sql_line({table=>'handmade_certigreen_licenses'});
	my %document = sql_line({table=>'intranet_documents',where=>"id_record='$id_record' AND table_record='$table_record'"});
	my @lignes_bas_general = sql_lines({debug=>0,debug_results=>0,table=>'intranet_documents_bas',where=>"type_frais LIKE 'general%' AND id_facture='$document{id}'",ordby=>'ordby'});
	my @lignes_bas_complet = sql_lines({table=>'intranet_documents_bas',where=>"id_facture='$document{id}'",ordby=>'ordby'});
	
	if($type eq 'facture')
	{
		my $where_facture = "id_record='$id_record' AND table_record='$table_record'";
		if($table_record eq 'intranet_factures' && $id_record > 0)
		{
			$where_facture = "id='$id_record'";
		}
		%document = sql_line({debug=>0,debug_results=>0,table=>'intranet_factures',where=>$where_facture});
		@lignes_bas_general = sql_lines({debug=>0,debug_results=>0,table=>'intranet_factures_bas',where=>"type_frais LIKE 'general%' AND id_facture='$document{id}'",ordby=>'ordby'});
		@lignes_bas_complet = sql_lines({debug=>0,table=>'intranet_factures_bas',where=>"id_facture='$document{id}'",ordby=>'ordby'});
	}
	elsif($type eq 'nc')
	{
		%document = sql_line({debug=>0,debug_results=>0,table=>'intranet_nc',where=>"id='$id_nc'"});
		@lignes_bas_general = sql_lines({table=>'intranet_nc_bas',where=>"type_frais LIKE 'general%' AND id_nc='$id_nc'",ordby=>'ordby'});
		@lignes_bas_complet = sql_lines({table=>'intranet_nc_bas',where=>"id_nc='$id_nc'",ordby=>'ordby'});
	}

	my $numero = $document{numero};
	if(!($document{id}>0))
	{
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		$year+=1900;	
		$mon++;	
		$document{numero} = $doc_prefixes{$table_record}.$year.sprintf("%.07d",$record{id});
		$document{annee} = $year;
	}
	
	my %facture_header = read_table($dbh,'handmade_templates',1);
	
	# my %facture_adresse_client = read_table($dbh,'handmade_templates',2);
	my %facture_adresse_client = ();
	$facture_adresse_client{html} = <<"EOH";
		<section class="document-adresses" class="clearfix">
			<div class="document-adresse-left">
				{license_company}<br />
				{license_street}<br />
				{license_street2}<br />
				{license_zip} - {license_city} | {license_country}<br />
				{license_vat}<br />
				{license_responsable}<br />
				<span class="document-invisible">{code_document}</span>
			</div>
			<div class="document-adresse-right">
				{ctm_denomination_systeme_short}<br />
				{ctm_adressel1}<br />
				{ctm_adressel2}<br />
				{ctm_cp} {ctm_ville} | {ctm_pays}<br />
				{ctm_numero_national} {ctm_tva}
			</div>
		</section>
EOH
	
	# my %facture_haut_tableau = read_table($dbh,'handmade_templates',3);
	my %facture_haut_tableau = ();
	$facture_haut_tableau{html} = <<"EOH";
		{today}
			<section class="facture-nr">{numero_facture} <span>{ss_titre}</span></section>
					<section class="facture-payment-info">{payment_info}</section>
					<section class="facture-table">
						<table class="table table-bordered">
							<tr>
								
								<th class="facture-table-col2" style="width:62%!important">Désignation</th>
								<th class="facture-table-col3" style="width:5%!important">Qté</th>
								<th class="facture-table-col4" style="width:11%!important">P.U. HTVA</th>
								<th class="facture-table-col5" style="width:11%!important">T.T. HTVA</th>
								<th class="facture-table-col5" style="width:11%!important">Taux TVA</th>
							</tr>
EOH
	
	
	# my %facture_haut_tableau_ventilation_tva = read_table($dbh,'handmade_templates',28);
	my %facture_haut_tableau_ventilation_tva = ();
	$facture_haut_tableau_ventilation_tva{html} = <<"EOH";
			{today}
			<section class="facture-nr">
				{numero_facture} 
				<span>
					{ss_titre}
				</span>
			</section> 
			<section class="facture-payment-info">
				{payment_info}
			</section> 
			<section class="facture-table"> 
				<table class="table table-bordered"> 
EOH

	# my %facture_ligne_tableau = read_table($dbh,'handmade_templates',4);
	my %facture_ligne_tableau = ();
	$facture_ligne_tableau{html} = <<"EOH";
			<tr class="{hide_class}">
				<td class="facture-table-col2">{libelle} <i>{remarque}</i></td>
				<td class="facture-table-col3 text-right">{qte}</td>
				<td class="facture-table-col4 text-right">{puhtva}</td>
				<td class="facture-table-col5 text-right">{ligne_total_htva}</td>
				<td class="facture-table-col5 text-right">{ligne_taux_tva}</td>
			</tr>
EOH
				
	
	# my %facture_ligne_bas = read_table($dbh,'handmade_templates',18);
	my %facture_ligne_bas = ();
	$facture_ligne_bas{html} = <<"EOH";
			<tr class="{hide_class}">
					<td class="facture-table-col2" colspan="3"><b>{libelle} </b></td>
					<td class="facture-table-col5 text-right"><b>{ligne_total_htva}</b></td>
			</tr>
EOH

	my %facture_ligne_bas_1col = ();
		$facture_ligne_bas_1col{html} = <<"EOH";
				<tr class="{hide_class}" style="border:0px!important; text-transform:none!important;">
						<td class="facture-table-col2  text-center" colspan="4"  style="border:0px!important; text-transform:none!important;"><b style="text-transform:none!important;">{libelle} </b></td>
				</tr>
EOH
	
	# my %facture_bas_tableau_avec_totaux = read_table($dbh,'handmade_templates',5);
	my %facture_bas_tableau_avec_totaux = ();
	$facture_bas_tableau_avec_totaux{html} = <<"EOH";
							<tr>
					<td colspan="1" class="facture-table-col6">
						<table class="table facture-rem">
							<tr>
								<td>{remarque}</td>
							</tr>
						</table>
						<table class="table facture-tva hide">
							<tr>
								<td class="text-center" colspan="2">ventilation tva</td>
								<td rowspan="5"></td>
							</tr>
							<tr>
								<td class="facture-table-col1">0%</td>
								<td class="facture-table-col4" class="text-right">{ventilation_0}</td>
							</tr>
							<tr>
								<td class="facture-table-col1">6%</td>
								<td class="facture-table-col4" class="text-right">{ventilation_6}</td>
							</tr>
							<tr>
								<td class="facture-table-col1">12%</td>
								<td class="facture-table-col4" class="text-right">{ventilation_12}</td>
							</tr>
							<tr>
								<td class="facture-table-col1">21%</td>
								<td class="facture-table-col4" class="text-right">{ventilation_21}</td>
							</tr>
						</table>
					</td>
					<td colspan="3" class="facture-table-col7">
						<table class="table facture-totals">
							<tr>
								<td>total htva</td>
								<td class="facture-table-col4">{montant_total_htva}</td>
							</tr>
							<tr>
								<td>remise globale (%)</td>
								<td class="facture-table-col4">{remise_globale}</td>
							</tr>
							<tr>
								<td>total htva remise deduite</td>
								<td class="facture-table-col4">{montant_total_htva_discounted}</td>
							</tr>
							<tr>
								<td>financement {info_financement}</td>
								<td class="facture-table-col4 financement" id="{taux_financement}">{financement}</td>
							</tr>
							<tr>
								<td>frais administratifs</td>
								<td class="facture-table-col4 frais_administratifs">{frais_administratifs}</td>
							</tr>
							<tr>
								<td>dossier d’achat</td>
								<td class="facture-table-col4 dossier_achat">{dossier_achat}</td>
							</tr>
							<tr>
								<td>envoi postal</td>
								<td class="facture-table-col4 envoi_postal">{envoi_postal}</td>
							</tr>
							<tr>
								<td>frais de facturation</td>
								<td class="facture-table-col4">{frais_facturation}</td>
							</tr>
							<tr>
								<td>delai de paiement</td>
								<td class="facture-table-col4">{delai_paiement}</td>
							</tr>
							<tr>
								<td>total htva</td>
								<td class="facture-table-col4">{montant_a_payer_htva}</td>
							</tr>
							<tr>
								<td>total tva</td>
								<td class="facture-table-col4">{montant_a_payer_tva}</td>
							</tr>
							<tr>
								<td>total tvac a payer</td>
								<td class="facture-table-col4">{montant_a_payer_tvac}</td>
							</tr>
						</table>
					</td>
				</tr>
			</table>
		</section>
EOH
	
	
	# my %facture_bas_tableau_sans_totaux = read_table($dbh,'handmade_templates',16);
	my %facture_bas_tableau_sans_totaux = ();
	$facture_bas_tableau_sans_totaux{html} = <<"EOH";
			</table>
		</section>
EOH
	
	# my %facture_footer = read_table($dbh,'handmade_templates',6);
	my %facture_footer = ();
	$facture_footer{html} = <<"EOH";
		<footer class="clearfix">
		<div class="document-barcode"><span class="barcode">{barcode}</span></div>
		<!--<div class="document-pages">page <span class="current_page"></span> sur  <span class="total_pages"></span></div>-->
		<div class="document-footer-infos">{license_company} | {license_street} {license_street2} à {license_zip} {license_city}, {license_country}<br /> Tél : {license_tel} | M@il : <a href="mailto:{license_email}" target="_blank">{license_email}</a><br /> IBAN : {license_iban} | BIC : {license_bic} | TVA: {license_vat} | RPM: {license_rpm} – Division : {license_division}<br /> Web : <a href="{license_web}">{license_web}</a> - Confidentiel © {license_company} {year}</div>
		</footer>

		<!-- div rajouté pour fermer le document ouvert -->
		</div>
EOH
	 
	
		my @document_details = sql_lines({debug=>0,debug_results=>0,table=>'intranet_documents_lignes',where=>"id_document='$document{id}' AND (label != '' OR ref != '')",ordby=>'ordby'});
	
		if($type eq 'facture')
		{
		   @document_details = sql_lines({debug=>0,debug_results=>0,table=>'intranet_facture_lignes',where=>"id_invoice='$document{id}' AND (label != '' OR ref != '')",ordby=>'ordby'});
		}
		elsif($type eq 'nc')
		{
		   @document_details = sql_lines({debug=>0,debug_results=>0,table=>'intranet_nc_lignes',where=>"id_nc='$id_nc' AND (label != '' OR ref != '')",ordby=>'ordby'});
		}
		
		
		#page 2 ventilation comptable (maintenant en page 1)
		$fac .= $facture_header{html};
		$fac .= $facture_adresse_client{html};
		$fac .=<<"EOH";
		<br />
EOH
		$fac .= $facture_haut_tableau_ventilation_tva{html};	
		
			my ($numero,$ss_titre,$payment_info,$raw_numero) = get_document_commercial_numero($document{numero},$type,$id_nc,$table_record,\%record,\%document,$id_record);

		
		
				
		my $current_type = $past_type = '';
		foreach $ligne_bas_complet (@lignes_bas_complet)
		{
			my %ligne_bas_complet = %{$ligne_bas_complet};
			
			my $nouvelle_ligne = $facture_ligne_bas{html};
			$nouvelle_ligne =~ s/{libelle}/$ligne_bas_complet{nom}/g;	

			$ligne_bas_complet{valeur} = sprintf("%.2f",$ligne_bas_complet{valeur});
			$nouvelle_ligne =~ s/{ligne_total_htva}/$ligne_bas_complet{valeur} €/g;	
			
			$current_type = $ligne_bas_complet{type_frais};
			if($current_type ne $past_type && $current_type ne 'general' || $ligne_bas_complet{nom} eq 'Total HTVA remise déduite')
			{
				#ligne d'espacement entre les groupes
				my $nouvelle_ligne = $facture_ligne_bas{html};
				$nouvelle_ligne =~ s/{libelle}/&nbsp;/g;	
				$nouvelle_ligne =~ s/{ligne_total_htva}//g;	
				$fac .= $nouvelle_ligne;
				
				
				
				
			}
			
			$fac .= $nouvelle_ligne;
			$past_type = $current_type;
		}
			
		if($type ne 'nc')
		{
			
		#ESPACEMENT
		my $nouvelle_ligne = $facture_ligne_bas_1col{html};
		$nouvelle_ligne =~ s/{libelle}/&nbsp;/g;	
		$nouvelle_ligne =~ s/{ligne_total_htva}//g;	
		$fac .= $nouvelle_ligne;		
			
		#PHRASE 1
		my $nouvelle_ligne = $facture_ligne_bas_1col{html};
		$nouvelle_ligne =~ s/{libelle}/Le détail des éléments facturés est repris ci-après./g;	
		$nouvelle_ligne =~ s/{ligne_total_htva}//g;	
		$fac .= $nouvelle_ligne;	
		
		
		#ESPACEMENT
		my $nouvelle_ligne = $facture_ligne_bas_1col{html};
		$nouvelle_ligne =~ s/{libelle}/&nbsp;/g;	
		$nouvelle_ligne =~ s/{ligne_total_htva}//g;	
		$fac .= $nouvelle_ligne;
		
		#PHRASE 2
		my $nouvelle_ligne = $facture_ligne_bas_1col{html};
		$nouvelle_ligne =~ s/{libelle}/Merci de respecter scrupuleusement le numéro de la facture ( {numero_facture_raw} ) lors de votre paiement. A défaut, votre balance sera imputée chronologiquement\./g;	
		$nouvelle_ligne =~ s/{ligne_total_htva}//g;	
		$fac .= $nouvelle_ligne;	
		
		}
		
		$fac =~ s/{numero_facture}/$numero/g;
		$fac =~ s/{numero_facture_raw}/$raw_numero/g;
		$fac =~ s/{ss_titre}/$ss_titre/g;
		$fac =~ s/{payment_info}/$payment_info/g;
		
		
		# BAS TABLEAU
		$fac .= $facture_bas_tableau_sans_totaux{html};
		
		
		
		# FOOTER
		my $new_footer = $facture_footer{html};
		# $new_footer =~ s/{current_page}/$num_page/g;
		$fac .= $new_footer;
		
		
		
		#NOUVELLE PAGE
		$fac .= $facture_header{html};
		$fac .= $facture_adresse_client{html};
		$fac .= $facture_haut_tableau{html};
		
		my $total_lignes = $#document_details + 1;
		my $count_lignes = 0;
		
		
		if($#document_details == -1)
		{
			$fac .= "<div style='height:100%'>Aucune ligne produit</div>";
		}		
		
		my $nb_lignes_avant_nouvelle_page = $nb_lignes_par_page;
		foreach $document_detail (@document_details)
		{
			my %document_detail = %{$document_detail};
			
			$count_lignes++; 
			my $num_ligne = $document_detail{ordby};
			
			if($nb_lignes_avant_nouvelle_page < 1)
			{
				# BAS TABLEAU
				$fac .= $facture_bas_tableau_sans_totaux{html};
				
				#FOOTER
				my $new_footer = $facture_footer{html};
				$fac .= $new_footer;
				
				#NOUVELLE PAGE
				$fac .= $facture_header{html};
				$fac .= $facture_adresse_client{html};
				$fac .= $facture_haut_tableau{html};	
				
				$nb_lignes_avant_nouvelle_page = $nb_lignes_par_page;
			}
			
			#LIGNE
			my $nouvelle_ligne = $facture_ligne_tableau{html};
			$nouvelle_ligne = map_ligne_facture($nouvelle_ligne,\%record,\%ctm,\%license,\%document,\%document_detail,$num_ligne,$print,$type,$table_record,'nc');
			$fac .= $nouvelle_ligne;
			
			
			
			if($count_lignes >= $total_lignes)
			{
				#affichage du tableau des totaux: à la page si il reste moins d'une demi page
				if($nb_lignes_avant_nouvelle_page < ($nb_lignes_par_page/2))
				{
					# BAS TABLEAU
					$fac .= $facture_bas_tableau_sans_totaux{html};
					
					#FOOTER
					my $new_footer = $facture_footer{html};
					# $new_footer =~ s/{current_page}/$num_page/g;
					$fac .= $new_footer;
					
					#NOUVELLE PAGE
					$fac .= $facture_header{html};
					$fac .= $facture_adresse_client{html};
					$fac .= $facture_haut_tableau{html};	
				}			
				
				#fin de la page 1 facture
				# foreach $ligne_bas_general (@lignes_bas_general)
				# {
					# my %ligne_bas_general = %{$ligne_bas_general};
					
					# my $nouvelle_ligne = $facture_ligne_bas{html};
					# $nouvelle_ligne =~ s/{libelle}/$ligne_bas_general{nom}/g;	

					# $ligne_bas_general{valeur} = sprintf("%.2f",$ligne_bas_general{valeur});
					# $nouvelle_ligne =~ s/{ligne_total_htva}/$ligne_bas_general{valeur} €/g;		
					# $fac .= $nouvelle_ligne;
				# }		
				
				# BAS TABLEAU
				$fac .= $facture_bas_tableau_sans_totaux{html};
				
				
				
				# FOOTER
				my $new_footer = $facture_footer{html};
				# $new_footer =~ s/{current_page}/$num_page/g;
				$fac .= $new_footer;
				
				
				
				last;
			}
			
			my %handmade_selion_inv = sql_line({table=>'handmade_inv',where=>"id='$document_detail{ref}'"});
			# my %handmade_selion_inv_categorie = sql_line({table=>'handmade_selion_inv_categories',where=>"id='$handmade_selion_inv{inv_category_0}'"});
			
			# my $taille_categorie = ceil(length($handmade_selion_inv_categorie{category_fusion} / $nb_char_par_ligne_remarque));
			my $taille_remarque = ceil(length($document_detail{remarque}) / $nb_char_par_ligne_remarque);
			my $taille_label = ceil(length($document_detail{label}) / $nb_char_par_ligne_label);
			my $taille_pour_cette_page = ( $taille_remarque + $taille_label ); 
			$nb_lignes_avant_nouvelle_page -= (1 + $taille_pour_cette_page);
		}
	
	
	#MAPPING
	# $fac =~ s/{total_pages}/$num_page/g;
	$fac = map_license_fields($fac,\%license);
	$fac = map_ctm_fields($fac,\%ctm);
	# see(\%document);exit;
	$fac = map_facture_fields($fac,\%record,\%ctm,\%license,\%document,$print,$type,$table_record,$id_nc);
	
	
	return $fac;
}


sub get_fw_document_simple
{
	my $prefixe = $_[0];
	my $table_record = $_[1];
	my $id_record = $_[2];
	my $print = $_[3];
	my $type = $_[4];
	my $limitea = $_[5];
	my $page = '';

	my %record = read_table($dbh,$table_record,$id_record);
	
	#Document initial
	$page .= get_fw_facture($prefixe,$table_record,$id_record,$print,'document','',$limitea);
		
	return $page;
}

sub get_fw_cgs
{
	
	#MISSION----------------------------------------------------
	my $page = '';

	my %cg = sql_line({debug=>0,debug_results=>0,table=>'handmade_certigreen_licenses'});

	my %license = sql_line({table=>'handmade_certigreen_licenses'});
	
	my %tpl_header = read_table($dbh,'handmade_templates',1);
	my %tpl_footer = read_table($dbh,'handmade_templates',6);
	my %tpl_titre_content = read_table($dbh,'handmade_templates',27);
	
	my $cgs = $cg{cg};
	# $cgs =~ s/<br \/>/\|/g;
	# $cgs =~ s/\r*\n/\|/g;
	# $cgs =~ s|<.+?>||g;
	
	#CONDITIONS GENERALES
	# $page .= multipages_titre_content({txtid=>"cgs",nb_chars_per_line=>999999999,nb_lines_per_page=>999999999,title=>'Conditions générales de vente',content=>$cgs,header=>$tpl_header{html},footer=>$tpl_footer{html},template=>$tpl_titre_content{html}});
	# $page .= '<div style="text-align:justify">'.multipages_titre_content({txtid=>"cgs",nb_chars_per_line=>100,nb_lines_per_page=>22,title=>'Conditions générales de vente',content=>$cgs,header=>$tpl_header{html},footer=>$tpl_footer{html},template=>$tpl_titre_content{html}}).'</div>';
	$page .= multipages_titre_content({nb_char_for_new_line=>190,txtid=>"cgs",nb_chars_per_line=>10000,nb_lines_per_page=>1,title=>'Conditions générales de vente',content=>$cgs,header=>$tpl_header{html},footer=>$tpl_footer{html},template=>$tpl_titre_content{html}});

	#MAPPING
	$page = map_license_fields($page,\%license);
	
	
	
	return $page;
}

sub get_document_name
{
	my %d = %{$_[0]};
	my $document_name = '';
	my %handmade_certigreen_license = sql_line({debug=>0,debug_results=>0,select=>'license_id',table=>'handmade_certigreen_licenses'});
	$d{id_site} = dm::getcode($dbh,$handmade_certigreen_license{license_id},'LCS');
	$document_name = get_document_filename(\%d);
	return $document_name;
}

sub map_ligne_facture
{
	my $nouvelle_ligne = $_[0];
	my %doc = %{$_[1]};
	my %ctm = %{$_[2]};
	my %license = %{$_[3]};
	my %facture = %{$_[4]};
	my %facture_detail = %{$_[5]};
	my $num_ligne = $num = $_[6];
	my $print = $_[7];
	my $type = $_[8];
	my $nc = $_[9];
	
	my $ref = $facture_detail{ref};
	# my %inv = sql_line({table=>'handmade_inv',select=>'',where=>"id='$ref'"});
	my $achat = 0;
    	
	if($facture_detail{remarque} ne '')
	{
		$facture_detail{remarque} = '<br>'.$facture_detail{remarque};
	}
	
	#$id,with_code,with_name,with_description,with_category,with_details,do_inv_update
	my $label = '<div style="text-align:justify;">'.compute_inv_name($ref,'y','y','y','n','y','n').'</div>';
	my $remarque = '<div style="text-align:justify;">'.compute_inv_name($ref,'n','n','n','y','n','n').$facture_detail{remarque}.'</div>';
	if($ref eq '' || $ref !~/^[0-9]+$/)
	{
		$label = $facture_detail{label};
	}
	
	# my %handmade_selion_inv_categorie = sql_line({table=>'handmade_selion_inv_categories',where=>"id='$inv{inv_category_0}'"});
	
	
	# my $label = '<div style="text-align:justify;">'.$facture_detail{label}.'</div>';
	
	
	# my $remarque = '<div style="text-align:justify;">'.$facture_detail{remarque}.'</div>';
	my $pu_htva = $facture_detail{pu_htva};
	my $qty = $facture_detail{qty};
	if($qty eq '')
	{
		$qty = 1;
	}
	my $total_htva = $facture_detail{tot_htva};
	my $remise = $facture_detail{remise};
	
	
	# && $pu_htva > 0
	if($pu_htva ne '' )
	{
		$pu_htva = sprintf("%.2f",$pu_htva);
	}
	else
	{
		$pu_htva = '';
	}
	if($total_htva ne '')
	{
		$total_htva = sprintf("%.2f",$total_htva);
		$total_htva = display_price($total_htva);
	}
	else
	{
		$total_htva = '';
	}
	$remise = sprintf("%.2f",$remise);
	$achat = sprintf("%.2f",$achat);
	
	
	my %corr_types = 
	(
		'perc'=>'%',
		'euro'=>'€',
	);
	
	if($remise > 0)
	{
		$total_htva .= "<br /><span style='color:red'>Remise: <br>- $remise ".$corr_types{$facture_detail{type}}.'</span>';
	}
	
	$pu_htva = "$pu_htva €";
	$total_htva = "$total_htva";
	
	# $remarque .= '<br>'.$handmade_selion_inv_categorie{category_fusion};
	
	my %taux_tva = read_table($dbh,'eshop_tvas',$facture_detail{id_taux_tva});
	my $prix_tva = display_price($pu_htva * $qty * ($taux_tva{tva_value} ));
	my $pu_htva = display_price($pu_htva);
	
	# my $taux_tva =  $prix_tva.'<br>('.$taux_tva{tva_reference}.')';
	my $taux_tva =  $prix_tva;
	
	$nouvelle_ligne =~ s/{reference}/$ref/g;
	$nouvelle_ligne =~ s/{libelle}/$label/g;
	$nouvelle_ligne =~ s/{remarque}/$remarque/g;
	$nouvelle_ligne =~ s/{qte}/$qty<br>&nbsp;/g;
	$nouvelle_ligne =~ s/{puhtva}/$pu_htva<br>&nbsp;/g;
	$nouvelle_ligne =~ s/{ligne_total_htva}/$total_htva/g;
	$nouvelle_ligne =~ s/{ligne_taux_tva}/$taux_tva/g;
	
	
	
	my $hide_class = '';
	if($num_ligne > 5 && ($facture_detail{label} eq '' && $facture_detail{reference} eq ''))
	{
		if($one_more_line == 0)
		{
			$hide_class = 'hide';
		}
		else
		{
			$one_more_line = 0;
		}
	}
	$nouvelle_ligne =~ s/{hide_class}/$hide_class/g;
	
	
	return $nouvelle_ligne;
}

sub compute_inv_name
{
	my $id = $_[0];
	my $with_code = $_[1] || 'y';
	my $with_name= $_[2] || 'y';
	my $with_description = $_[3] || 'y';
	my $with_category = $_[4] || 'y';
	my $with_details = $_[5] || 'y';
	my $do_inv_update = $_[6] || 'y';
	
	
	
	my %inv = sql_line({table=>'handmade_inv',where=>"id='$id'"});


	my $inv_fusion = '';
	
	if($with_code eq 'y')
	{
		#INV0000406
		# $inv_fusion = add_denomination($inv_fusion,getcode($dbh,$inv{id},'INV'));
	}

	if($with_name eq 'y')
	{
		#GOOGLE UNLIMITED
		# $inv_fusion = add_denomination($inv_fusion,uc($inv{reference}));
	}
	
	if($with_details eq 'y')
	{
		#( /utilisateur /mensuel )
		$inv_fusion = add_denomination($inv_fusion,$inv{INVUNITE});
	}
	

	
	if($inv{INVDESCRIPTION} ne '' && $with_description eq 'y') 
	{
		#retour à la ligne
		$inv_fusion = add_denomination($inv_fusion,'<br>');
		
		# L'intégralité des outils dont n'importe quel indépendant, PME ou Grande Entreprise a besoin, assorti à un stockage illimité.
		$inv_fusion = add_denomination($inv_fusion,$inv{INVDESCRIPTION});
	}
	
	if($inv{inv_category_0} > 0 && $with_category eq 'y')
	{
		#retour à la ligne
		# $inv_fusion = add_denomination($inv_fusion,'<br>');
		
		my %cat = read_table($dbh,'handmade_selion_inv_categories',$inv{inv_category_0});
		
		#catégorie
		$inv_fusion = add_denomination($inv_fusion,$cat{category_fusion});
	}
	
	if($with_details eq 'y')
	{
	
	#retour à la ligne
	$inv_fusion = add_denomination($inv_fusion,'<br>');
	
	#EAN
	$inv_fusion = add_denomination($inv_fusion,$inv{reference_ean});
	
	#Constructeur
	$inv_fusion = add_denomination($inv_fusion,$inv{constructeur});
	
	#Référence C/D constructeur
	$inv_fusion = add_denomination($inv_fusion,$inv{reference_constructeur});
	
	
	
	#Vendeur
	# $inv_fusion = add_denomination($inv_fusion,$inv{vendeur});
	
	#Référence vendeur
	# $inv_fusion = add_denomination($inv_fusion,$inv{reference_vendeur});
	
	#retour à la ligne
	# $inv_fusion = add_denomination($inv_fusion,'<br>');
	
	# 1 Boîte = colisage X 5 = unités contenues (500 gr. = Poids total, 1750 mm = Hauteur, 2500 mm = Longueur, 2000 mm = Largeur)
	
	
	
	$inv_fusion = add_denomination($inv_fusion,$inv{colisage});
	
	#X 5
	if($inv{quantite} ne '' && $inv{quantite} > 0)
	{
		$inv{quantite} = 'X '.$inv{quantite};
	}
	$inv_fusion = add_denomination($inv_fusion,$inv{quantite});
	
	if($inv{poids} ne '' || $inv{hauteur} != 0 || $inv{longueur} != 0 || $inv{largeur} != 0)
	{
		$inv_fusion = add_denomination($inv_fusion,'(');
	}
		if($inv{poids} ne '')
		{
			$inv{poids} = $inv{poids}.' gr.';
			if($inv{hauteur} != 0 || $inv{longueur} != 0 || $inv{largeur} != 0)
			{
				$inv{poids} .=  ',';
			}
		}
		
		
		
		$inv_fusion = add_denomination($inv_fusion,$inv{poids});
		if($inv{hauteur} != 0)
		{
			$inv{hauteur} = $inv{hauteur}.' mm, ';
		}
		else
		{
			$inv{hauteur} = '';
		}
		$inv_fusion = add_denomination($inv_fusion,$inv{hauteur});
		
		if($inv{longueur} != 0)
		{
			$inv{longueur} = $inv{longueur}.' mm, ';
		}
		else
		{
			$inv{longueur} = '';
		}
		$inv_fusion = add_denomination($inv_fusion,$inv{hauteur});
		
		if($inv{largeur} != 0)
		{
			$inv{largeur} = $inv{largeur}.' mm';
		}
		else
		{
			$inv{largeur} = '';
		}
		$inv_fusion = add_denomination($inv_fusion,$inv{largeur});

				
	if($inv{poids} ne '' || $inv{hauteur} != 0 || $inv{longueur} != 0 || $inv{largeur} != 0)
	{
		$inv_fusion = add_denomination($inv_fusion,')');
	}
	
	}
	

	if($do_inv_update eq 'y')
	{
		$inv_fusion =~ s/\'/\\\'/g;

	#calcule la liste des parents de la catégorie associée, lui meme compris
	my $liste_parents = '0,'.$inv{inv_category_0};
	$liste_parents = find_handmade_selion_inv_categories_parents_list($inv{inv_category_0},$liste_parents).',';
	
	
	
	$stmt = "UPDATE handmade_inv SET INVFUSION= '$inv_fusion',inv_category_parents='$liste_parents' WHERE id = $inv{id}";
	execstmt($dbh,$stmt);
	}

	return $inv_fusion;
}



sub factures_client
{
	my $dbh = $_[0];
	my $id = $_[1];
	my %commande = read_table($dbh,'intranet_factures',$id);
	my %member = sql_line({table=>'members',where=>"id='$commande{id_member}'"});
	
	
	my $sel = get_quoted('sel');
	# my @factures = sql_lines({table=>'intranet_factures',where=>"id_member='$member{id}' and migcms_deleted != 'y' "});
	my @factures = sql_lines({table=>'intranet_factures',where=>"table_record='intranet_factures' AND id_record='$id'"});
	
	
	my $ecran = "";
	$ecran .= <<"EOH";

	<h3>Factures pour la commande</h3>
		
	<table class="table table-hover table-border table-striped">
		<thead>
			<tr>
				<th>
					N°
				</th>
				<th>
					Date
				</th>
				<th>
					Echéance
				</th>
				<th>
					Total HTVA
				</th>
				<th>
					Total TVAC
				</th>
				<th>
					Référence
				</th>
				<th>
					Statut
				</th>
				<th>
					Remarque
				</th>
			</tr>
		</thead>
		<tbody>
		

EOH
	foreach $facture (@factures)
	{
		my %facture = %{$facture};
		# my %handmade_codes_contacts_niveaux_pouvoirs_decisions = sql_line({table=>'handmade_codes_contacts_niveaux_pouvoirs_decisions',where=>"id='$contact{contact_id_niveau_pouvoir_decisions}'"});
		
		$facture{date_facturation} = to_ddmmyyyy($facture{date_facturation});
		$facture{date_echeance} = to_ddmmyyyy($facture{date_echeance});
		
		
		my $numero_document = dm::getcode($dbh,$facture{id},'FC0');	
		my %handmade_certigreen_statuts_facturation = sql_line({table=>'handmade_certigreen_statuts_facturation',where=>"id='$facture{statut}'"});
		
		$ecran .= <<"EOH";
				<tr>
					<td>
						<a class="btn btn-link" target="_blank" href="adm_handmade_certigreen_factures.pl?sel=1000273&sw=add_form&id=$facture{id}"><i class="fa fa-user" aria-hidden="true"></i> <i class="fa fa-external-link" aria-hidden="true"></i> 
							$numero_document
						</a>
					</td>
					<td>
						$facture{date_facturation}
					</td>
					<td>
						$facture{date_echeance}
					</td>
					<td class="text-right">
						$facture{montant_a_payer_htva} €
					</td>
					<td class="text-right">
						$facture{montant_a_payer_tvac} €
					</td>
					<td>
						$facture{reference}
					</td>
					<td>
						$handmade_certigreen_statuts_facturation{nom}
					</td>
					<td>
						$facture{remarque}
					</td>
				</tr>
EOH
	}
		$ecran .= <<"EOH";
		</tbody>
	</table>
		<a class="btn btn-default" target="_blank" href="adm_handmade_certigreen_factures.pl?id_member=$member{id}&amp;sel=1000273" data-original-title="Factures" target="" data-placement="bottom">
		<i class="fa fa-external-link" aria-hidden="true"></i> Factures du client
		</a>
		<a class="btn btn-default" target="_blank" href="adm_handmade_certigreen_factures.pl?commande_id=$commande{id}&amp;sel=1000273" data-original-title="Factures" target="" data-placement="bottom">
		<i class="fa fa-external-link" aria-hidden="true"></i> Factures de la commande
		</a>
	<script>
	jQuery(document).ready(function() 
	{

	});
	</script>
EOH
	return $ecran;
} 

sub factures_reglements
{
	my $dbh = $_[0];
	my $id = $_[1];

	
	my $sel = get_quoted('sel');
	my @handmade_certigreen_reglements = sql_lines({table=>'handmade_certigreen_reglements',where=>" id_facture='$id'"});
	
	
	my $ecran = "";
	$ecran .= <<"EOH";

	<h3>Reglements pour la facture</h3>
		
	<table class="table table-hover table-border table-striped">
		<thead>
			<tr>
				<th>
					Date
				</th>
				<th>
					Montant
				</th>
				<th>
					Type
				</th>
			</tr>
		</thead>
		<tbody>
		

EOH
	foreach $handmade_certigreen_reglement (@handmade_certigreen_reglements)
	{
		my %handmade_certigreen_reglement = %{$handmade_certigreen_reglement};
		my %handmade_certigreen_statuts_reglement = sql_line({table=>'handmade_certigreen_statuts_reglement',where=>"id='$handmade_certigreen_reglement{id_type_reglement}'"});
		
		$handmade_certigreen_reglement{date_reglement} = to_ddmmyyyy($handmade_certigreen_reglement{date_reglement});
		
		
		my $numero_document = dm::getcode($dbh,$facture{id},'FC0');	
		
		$ecran .= <<"EOH";
				<tr>
					<td>
						$handmade_certigreen_reglement{date_reglement}
					</td>
					<td class="">
						$handmade_certigreen_reglement{montant} €
					</td>
					<td>
						$handmade_certigreen_statuts_reglement{nom}
					</td>
				</tr>
EOH
	}
		$ecran .= <<"EOH";
		</tbody>
	</table>
		<a class="btn btn-default" target="_blank" href="adm_handmade_certigreen_reglements.pl?&amp;sel=1000279" data-original-title="Reglements" target="" data-placement="bottom">
		<i class="fa fa-external-link" aria-hidden="true"></i> Accéder aux reglements
		</a>
	<script>
	jQuery(document).ready(function() 
	{

	});
	</script>
EOH
	return $ecran;
}

sub action_globale_rappel1
{
	my $ids = get_quoted('ids');
	action_globale_rappel($ids,'1');
}

sub action_globale_rappel2
{
	my $ids = get_quoted('ids');
	action_globale_rappel($ids,'2');
}

sub action_globale_rappel3
{
	my $ids = get_quoted('ids');
	action_globale_rappel($ids,'3');
}

sub action_globale_rappel
{
	my $ids = $_[0];
	my $type_rappel = $_[1];
	
	my $id_email_template = 21;
	if($type_rappel == 2)
	{
		$id_email_template = 22;
	}
	elsif($type_rappel == 3)
	{
		$id_email_template = 23;
	}
	my %license = sql_line({debug=>0,debug_results=>0,table=>'handmade_certigreen_licenses'});
	my %handmade_template = sql_line({table=>'handmade_templates',where=>"id='$id_email_template'"});
	my $txt_template = $handmade_template{html};
	
	# Madame, Monsieur,

# Il résulte de notre comptabilité que nous n’avons pas encore reçu le paiement complet de notre facture ---numero_document--- du ---facture_date---
# Nous vous prions de bien vouloir vérifier et de nous verser le montant de ---montant--- sur notre compte ---license_iban--- (BIC ---license_bic---) en mentionnant la référence ---numero_document---. Merci de nous faire parvenir la preuve de paiement par email via ---license_email---. 

# Cordialement

# ---license_company--- - Service facturation
	

	my @ids = split (/,/,$ids);
	
	foreach $id (@ids)
    {
		if($id > 0)
        {
			my %facture = sql_line({table=>'intranet_factures',where=>"id='$id'"});
			my %membre = sql_line({table=>'members',where=>"id='$facture{id_member}'"});
			if($membre{email} ne '')
			{
				my $body = $txt_template;
				$body =~ s/\r*\n/\<br \>/g;
				my $num = $facture{numero};
				
				$facture{montant_a_payer_tvac} = display_price($facture{montant_a_payer_tvac});
				$facture{date_facturation} = to_ddmmyyyy($facture{date_facturation});
				
				$license{license_name} = '<b>'.$license{license_name}.'</b>';
				$license{license_type_company} = '<b>'.$license{license_type_company}.'</b>';
				$license{iban} = '<b>'.$license{iban}.'</b>';
				$license{bic} = '<b>'.$license{bic}.'</b>';
				$license{email} = '<b>'.$license{email}.'</b>';
				$facture{montant_a_payer_tvac} = '<b>'.$facture{montant_a_payer_tvac}.'</b>';
				$facture{numero} = '<b>'.$facture{numero}.'</b>';
				$facture{date_facturation} = '<b>'.$facture{date_facturation}.'</b>';
				
				$body =~ s/\-\-\-license_company\-\-\-/$license{license_name} $license{license_type_company}/g;
				$body =~ s/\-\-\-license_iban\-\-\-/$license{iban}/g;
				$body =~ s/\-\-\-license_bic\-\-\-/$license{bic}/g;
				$body =~ s/\-\-\-license_email\-\-\-/$license{email}/g;
				$body =~ s/\-\-\-montant\-\-\-/$facture{montant_a_payer_tvac}/g;
				$body =~ s/\-\-\-numero_document\-\-\-/$facture{numero}/g;
				$body =~ s/\-\-\-facture_date\-\-\-/$facture{date_facturation}/g;
				
				send_mail('info@certigreen.be',$member{email},'Rappel concernant votre Facture N°'.$num,$body,"html");
				send_mail('info@certigreen.be','info@certigreen.be','Rappel concernant votre Facture N°'.$num,$body,"html");
			}		
		}
	}
}


sub display_price
{
  my $value = $_[0];

  my $devise = "€";

  if($config{devise} ne "")
  {
    $devise = $config{devise};
  }

  $value = round($value*100)/100;
  $value = sprintf("%.2f",$value);
  
   $value =~ s/\.00$//g;
  
  return $value."&nbsp;$devise";
}


sub set_statut_facture_from_reglements
{
	my $id_facture = $_[0];
	my %facture = sql_line({debug=>0,debug_results=>0,select=>"id,montant_a_payer_tvac",table=>'intranet_factures',where=>"id='$id_facture'"});
	my %check_sum_reglement = sql_line({debug=>0,debug_results=>0,select=>"SUM(montant) as total_reglements",table=>'handmade_certigreen_reglements',where=>"id_facture='$facture{id}'"});

	$check_sum_reglement{total_reglements} = round($check_sum_reglement{total_reglements}*100)/100;
	$check_sum_reglement{total_reglements} = sprintf("%.2f",$check_sum_reglement{total_reglements});
	
	$facture{montant_a_payer_tvac} = round($facture{montant_a_payer_tvac}*100)/100;
	$facture{montant_a_payer_tvac} = sprintf("%.2f",$facture{montant_a_payer_tvac});

	
	
	log_debug(" TEST REGLEMENTS $facture{montant_a_payer_tvac} <= $check_sum_reglement{total_reglements} && $check_sum_reglement{total_reglements} > 0","","save_doc");
	log_debug(" TEST REGLEMENTS 2 $facture{montant_a_payer_tvac} > $check_sum_reglement{total_reglements} && $check_sum_reglement{total_reglements} > 0","","save_doc");

	if($facture{montant_a_payer_tvac} <= $check_sum_reglement{total_reglements} && $check_sum_reglement{total_reglements} > 0)
	{
		#payee
		$stmt = "update intranet_factures SET statut = '4' WHERE statut IN('1','2','3') AND id = '".$facture{id}."' ";
		log_debug($stmt,'','set_statut_facture_from_reglements');
		execstmt($dbh,$stmt);	
	}
	elsif($facture{montant_a_payer_tvac} > $check_sum_reglement{total_reglements} && $check_sum_reglement{total_reglements} > 0)
	{
		#partiellement payée
		$stmt = "update intranet_factures SET statut = '3' WHERE statut IN('1','2') AND id = '".$facture{id}."' ";
		log_debug($stmt,'','set_statut_facture_from_reglements');
		execstmt($dbh,$stmt);	
	}
	else
	{
		log_debug($facture{montant_a_payer_tvac},'','set_statut_facture_from_reglements');
		log_debug($check_sum_reglement{total_reglements},'','set_statut_facture_from_reglements');
	}
}


sub ajax_infos_rec
{
	# Nom du client, Adresse du bien, N° Facture ou N° NC ou N° Cmd Employé lié à la commande.
	my $id = get_quoted('id') || $_[0];
	my $t = get_quoted('t') || $_[1];
	my $client = '';
	
	my $table = '';
	if($t eq 'intranet_factures' || $t eq 'intranet_factures' || $t eq 'intranet_nc' || $t eq 'commande_documents')
	{
		$table = $t;
	}
	else
	{
		see();
		print $t;
		exit;
	}
	
	if($id > 0)
	{
		
		my %rec = sql_line({table=>$table,where=>"id='$id'"});
		my %user_rec = sql_line({table=>'users',where=>"id='$rec{id_employe}'"});
		
		if($t eq 'intranet_factures')
		{
			$client = <<"EOH";
				<b>Commande N°: </b> $rec{id} | <b>Client:</b> $rec{firstname} $rec{lastname} | <b>Bien:</b> $rec{adresse_rue} $rec{adresse_numero} $rec{adresse_cp} $rec{adresse_ville} | <b>Employé:</b> $user_rec{firstname} $user_rec{lastname}
EOH
		}
		elsif($t eq 'intranet_factures')
		{
			my %record = sql_line({table=>$rec{table_record},where=>"id='$rec{id_record}'"});
			my %user_rec = sql_line({table=>'users',where=>"id='$record{id_employe}'"});

			$client = <<"EOH";
				<b>Facture N°: </b> FA$rec{numero} | <b>Client:</b> $rec{nom_f}  | <b>Bien:</b> $record{adresse_rue} $record{adresse_numero} $record{adresse_cp} $record{adresse_ville} | <b>Employé:</b> $user_rec{firstname} $user_rec{lastname}
EOH
		}
		elsif($t eq 'intranet_nc')
		{
			my %record = sql_line({table=>$rec{table_record},where=>"id='$rec{id_record}'"});
			my %user_rec = sql_line({table=>'users',where=>"id='$record{id_employe}'"});

			$client = <<"EOH";
				<b>NC N°: </b> NC$rec{id} | <b>Client:</b> $rec{nom_f}  | <b>Bien:</b> $record{adresse_rue} $record{adresse_numero} $record{adresse_cp} $record{adresse_ville} | <b>Employé:</b> $user_rec{firstname} $user_rec{lastname}
EOH
		}
		elsif($t eq 'commande_documents')
		{
			my %commande = sql_line({table=>'intranet_factures',where=>"id='$rec{commande_id}'"});
			my %user_rec = sql_line({table=>'users',where=>"id='$commande{id_employe}'"});

			$client = <<"EOH";
				<b>Commande N°: </b> $commande{id} | <b>Client:</b> $commande{firstname} $commande{lastname}  | <b>Bien:</b> $commande{adresse_rue} $commande{adresse_numero} $commande{adresse_cp} $commande{adresse_ville} | <b>Employé:</b> $user_rec{firstname} $user_rec{lastname}
EOH
		}
	}
	
	if( $_[0]>0)
	{
		return <<"EOH";
		<div style="position:absolute;">
			$client
		</div>
EOH
	}
	else
	{
	print <<"EOH";
		<div style="position:absolute;">
			$client
		</div>
EOH
	exit;
	}
}

1;