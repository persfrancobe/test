#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm_cms;
use sitetxt;
use migcrender;
use members;
use data;
use Unicode::MapUTF8 qw(to_utf8 from_utf8 utf8_supported_charset);
use dm;
use dm_cms;
use Net::FTP;
use Digest::SHA1  qw(sha1 sha1_hex sha1_base64);

use File::Copy;
use File::Path qw(remove_tree rmtree);

my $sw = $ARGV[0];
if($sw eq '')
{
	$sw = get_quoted('sw');
}
if($sw eq '')
{
	$sw = 'import_form';
}
my $sel = get_quoted('sel');
my $self = "$config{baseurl}/cgi-bin/adm_handmade_migration36_certi.pl?&sel=".$sel;

#connexion site sous migc36
$config{import36_host} = 'certigreen.fw.be';
#$config{import36_host} = 'localhost';
$config{import36_db} = 'certigreen';
$config{import36_login} = 'dbcertigreen';
$config{import36_pw} = 'muI15d?8';


my $dbh36 = DBI->connect("DBI:mysql:$config{import36_db};host=$config{import36_host}",$config{import36_login},$config{import36_pw}) or die("cannot connect to [$config{import36_db}] host: [$config{import36_host}] login:[$config{import36_login}] pw:[$config{import36_pw}]");
$stmt = " SET NAMES UTF8";	
$cursor = $dbh36->prepare($stmt);		
$rc = $cursor->execute;
my $dbh36_handmade = DBI->connect("DBI:mysql:$config{import36_db}_handmade;host=$config{import36_host}",$config{import36_login},$config{import36_pw}) or die("cannot connect to [$config{import36_db}] host: [$config{import36_host}] login:[$config{import36_login}] pw:[$config{import36_pw}]");
$stmt = " SET NAMES UTF8";
$cursor = $dbh36_handmade->prepare($stmt);
$rc = $cursor->execute;

my %pages_types = 
(
	'menus'=>'directory',
	'links'=>'link',
	'pages'=>'page',
);

# if($sw eq 'import_form' || $sw eq 'import_db')
# {
	&$sw(); 
# }
# exit;

sub check_session_validity
{
see();
exit;
}

sub import_form
{
	my $msg = '';
	if(get_quoted('ko') == 1)
	{
		$msg = '<div class="alert alert-danger" role="alert"> <strong>Erreur</strong> </div>';
	}
	elsif(get_quoted('ok') == 1)
	{
		$msg = '<div class="alert alert-success" role="alert"> <strong>OK:</strong> Les tâches cochées ont été traitées </div>';
	}



	my $page = <<"EOH";
<div class="wrapper">
	<div class="row">
		<div class="col-sm-12">
			<section class="panel text-center">
				<header class="panel-heading">
					Importer un site MIGC36  vers le MIGC4 local
				</header>
				$msg
				<div class="panel-body">
					<form method="post" action="$self">
					<input type="hidden" name="sw" value="import_db" />
					<input type="hidden" name="sel" value="$sel" />
					
					<div class="well text-left">
					<br /><label style="color:"><input type="checkbox" name="certi" value="y"  /> clients,commandes,factures,nc,documents,reglements?</a></label>

					
					<br /><br />
					Code de sécurité: <input class="form-control" type="text" autocomplete="off" name="pw" value="" />
					</div>

					
					<button type="submit" class="btn btn-lg btn-success"><i class="fa fa-check"></i> Confirmer</a>
					
					</form>
				</div>
			</section>
		</div>
	</div>
	<br />
</div>
EOH

	see();
	$migc_output{content} = $page;
	print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
	exit;

}

sub import_db
{
		log_debug('debut','vide','import');
		
		my $code_securite = get_quoted('pw');
		if($code_securite ne 'a')
		{
			cgi_redirect($self.'&ko=1');		
		}
		else
		{
			see();
			log_debug("",'vide','ftp');
			log_debug("",'vide','stmt');

			if(get_quoted('certi') eq 'y')
			{
				import_certi_clients();
				import_certi_commandes_documents();
				import_certi_commandes_documents_files();
			}

			
			log_debug('Fin','','import');
			http_redirect($self.'&ok=1');			
		}
}

sub import_certi_clients
{
	my @members = sql_lines({dbh=>$dbh36_handmade,table=>'members',where=>"", ordby=>"id desc"});

	foreach $member(@members)
	{
		my %member = %{$member};
		%member = %{quoteh(\%member)};

		if($member{token2} eq '') {
			$member{token2} = $member{token};
		}
		if($member{lastname} eq '') {
			next;
		}

		my %update_member = (
			id => $member{id},
			token => $member{token},
			token2 => $member{token2},
			password =>  sha1_hex($member{password}),
			email =>  $member{email},
			type_member =>  $member{type_member},
			type_agence =>  $member{type_agence},
			id_agence =>  $member{id_agence},
			id_agence2 =>  $member{id_agence2},
			firstname =>  ucfirst(lc($member{firstname})),
			lastname =>  uc($member{lastname}),
			fusion =>  ucfirst(lc($member{firstname})).' '.uc($member{lastname}),
			fusion_short =>  ucfirst(lc($member{firstname})).' '.uc($member{lastname}),
			vat =>  $member{vat},
			street =>  $member{street},
			number =>  $member{number},
			zip =>  $member{zip},
			city =>  $member{city},
			tel =>  $member{tel},
			last_login =>  $member{last_login},
			id_employe =>  25, #certigreen
			roles =>  '["ROLE_USER"]',
			username => ucfirst(lc($member{firstname})).' '.uc($member{lastname}).' '.$member{id},
		);
		%update_member = %{quoteh(\%update_member)};
		my %check_member = sql_line({select=>"id",table=>'members',where=>"email = '$update_member{email}' AND id != '$update_member{id}'"});
		if($check_member{id} > 0)
		{
			$update_member{email} = $update_member{email}.'_'.$update_member{id};
		}
		my $id_migcms_member = sql_set_data({debug=>0,dbh=>$dbh,table=>'members',data=>\%update_member, where=>"id='$update_member{id}'"});
	}
}

sub import_certi_commandes_documents
{
	my $ftp = $_[0];

	my @commandes = sql_lines({dbh=>$dbh36_handmade,table=>'commandes',where=>"",ordby=>"id desc",limit=>""});
#	my @commandes = sql_lines({dbh=>$dbh36_handmade,table=>'commandes',where=>"",ordby=>"id desc",limit=>"0,15"});
#	my @commandes = sql_lines({dbh=>$dbh36_handmade,table=>'commandes',where=>"id='9485'",ordby=>"id desc",limit=>"0,15"});
	foreach $commande(@commandes)
	{
		my %commande = %{$commande};
		%commande = %{quoteh(\%commande)};

		my %member = ();
		if($commande{id_member} > 0){
			%member  = sql_line({dbh=>$dbh36_handmade,table=>'members',where=>"id='$commande{id_member}'"});
		}
		my %agence = ();
		if($commande{id_agence} > 0){
			%agence  = sql_line({dbh=>$dbh36_handmade,table=>'members',where=>"id='$commande{id_agence}'"});
		}

		$commande{remarque_facturation} =~ s/\r*\n//g;
		$commande{remarque_facturation} = trim($commande{remarque_facturation});


		my $statut_paiement = 2; #attente_paiement
		if(0)
		{
			$statut_paiement = 3; #part pay
		}
		elsif($commande{remarque_facturation}  eq 'Offert' || $commande{remarque_facturation}  eq 'Facture payée' || $commande{remarque_facturation}  eq 'Factures payées' || $commande{remarque_facturation}  eq 'Payé' || $commande{remarque_facturation}  =~ m/Facture PEB payée/)
		{
			$statut_paiement = 4; #pay
		}
		elsif($commande{remarque_facturation}  =~ m/acte/)
		{
			$statut_paiement = 7; #paiement  à l'acte
		}





#		print "[$commande{remarque_facturation}]";
#		print "[$statut_paiement]";
#		exit;

		my $email = "";
		if(0)
		{
			$email = "";
		}

		my $type_member = 'Particulier';
		if($member{type_member} eq 'Agence')
		{
			$type_member = 'Notaire';
			if($member{type_agence} eq 'agence')
			{
				$type_member = 'Agence';
			}
		}



		my %update_intranet_facture = (
			id => $commande{id},
			id_facture_liaison => $commande{id},
			token => $commande{token},
			id_member => $commande{id_member},
			date_mission => $commande{date_commande},
			type_member => $type_member,
			statut => $statut_paiement,
			type_facture => '',
			envoye_au_comptable => 1,

			validation =>$commande{validation},
			type_bien_id =>$commande{id_type_bien},

			adresse_rue =>$commande{adresse_rue},
			adresse_numero =>$commande{adresse_numero},
			adresse_cp =>$commande{adresse_cp},
			adresse_ville =>$commande{adresse_ville},

			alt_facture_url =>$commande{alt_facture_url},

			id_member =>  $member{id},

			firstname =>  ucfirst(lc($member{firstname})),
			lastname =>  uc($member{lastname}),
			street =>  $member{street},
			number =>  $member{number},
			zip =>  $member{zip},
			city =>  $member{city},
			tel =>  $member{tel},
			migcms_lock =>  'n',

			facture_id_member =>  $member{id},
			facture_nom => uc($member{lastname}),
			facture_prenom =>ucfirst(lc($member{firstname})),
			facture_street => $member{street},
			facture_number => $member{number},
			facture_zip => $member{zip},
			facture_city => $member{city},

			remarque_facturation =>$commande{remarque_facturation},
			facture_email =>$email,
			statut => $statut_paiement,
			password =>  sha1_hex($member{password}),
			email =>  $member{email},

			type_member =>  $member{type_member},
			type_agence =>  $member{type_agence},

			nom_agence =>  $agence{lastname},

			id_member_agence =>  $member{id_agence},
			id_agence2 =>  $member{id_agence2},

			facture_societe_tva =>  $member{vat},

			remarque =>trim("$commande{contact_nom} $commande{contact_prenom} $commande{contact_tel} $commande{contact_email}"),

			id_employe =>  25, #certigreen
		);

		if($commande{alt_facture_url} ne '')
		{
			$update_intranet_facture{migcms_lock} = 'y' ;
		}

		%update_intranet_facture = %{quoteh(\%update_intranet_facture)};

		sql_set_data({debug=>0,dbh=>$dbh,table=>'intranet_factures',data=>\%update_intranet_facture, where=>"id='$update_intranet_facture{id}'"});
	}
}



sub import_certi_commandes_documents_files
{
	my $ftp = $_[0];

#	my @commande_documents = sql_lines({dbh=>$dbh36_handmade,select=>"*",table=>"commande_documents",where=>"commande_id IN (SELECT id FROM commandes) and commande_id='9485'",ordby=>""});
	my @commande_documents = sql_lines({dbh=>$dbh36_handmade,select=>"*",table=>"commande_documents",where=>"id_commande IN (SELECT id FROM commandes)",ordby=>""});
	foreach $commande_document(@commande_documents)
	{
		my %commande_document = %{$commande_document};
		
		#creation répertoire cible
		my $dirname = '/usr/files/DOC/pj/'.$commande_document{id};
		my $dir = $config{directory_path}.$dirname;
		unless (-d $dir) {mkdir($dir.'/') or log_debug("cannot create ".$dir.": $!");}

		my $pic_dir = $config{directory_path}.'/usr';

		my $import_path = $pic_dir.'/'.$commande_document{url};
		my $download_path = $dir.'/'.$commande_document{url};

		my $heure_prevue = '00:00';
		my ($hh,$mm) = split('\h',$commande_document{heure_prevue});
		if($hh > 0 || $mm > 0)
		{
			$heure_prevue = $hh.':'.$mm;
		}

		#création ligne document
        my %update_document = (
			'id'=>$commande_document{id},
			'commande_id'=>$commande_document{id_commande},
			'type_document_id'=>$commande_document{id_type_document},
			'date_prevue'=>to_sql_date($commande_document{date_prevue}),
			'heure_prevue'=>$heure_prevue,
			'date_realisee'=>$commande_document{date_realisee},
			'id_code_cible'=>7,
			'id_texte_email'=>9,
			'migcms_last_published_file'=>'../files/DOC/pj/'.$commande_document{id}.'/'.$commande_document{url},
        );
		%update_document = %{quoteh(\%update_document)};
		sql_set_data({debug=>0,dbh=>$dbh,table=>'commande_documents',data=>\%update_document, where=>"id='$update_document{id}'"});


		my ($name,$ext) = split('\.',$commande_document{url});
		#création ligne linked file
		my %update_linked_file = (
			'file'=>$commande_document{url},
			'file_dir'=>'..'.$dirname,
			'ordby'=>'1',
			'visible'=>'y',
			'table_name'=>'commande_documents',
			'table_field'=>'pj',
			'token'=>$commande_document{id},
			'full'=>$name,
			'ext'=>'.'.$ext,
		);
		%update_linked_file = %{quoteh(\%update_linked_file)};
		my $id_migcms_linked_file = sql_set_data({debug=>0,dbh=>$dbh,table=>'migcms_linked_files',data=>\%update_linked_file, where=>"table_name='commande_documents' AND token='$update_linked_file{token}'"});


		if($commande_document{url} ne '') {
			log_debug("ftp get: $import_path,$download_path",'','ftp sheets');

			if (-e ($import_path)) {
				if (!(-e $download_path)) {
					copy("$import_path", $download_path);
				}
				else {
					log_debug("deja la: $download_path", '', 'ftp sheets');
				}
			}
			else {
				log_debug("fichier non dispo: $import_path", '', 'ftp sheets error');
			}
		}
	}
}