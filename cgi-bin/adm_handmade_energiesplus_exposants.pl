#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use def_handmade;

my $y = get_quoted('y');
$dm_cfg{enable_search} = 1;
$dm_cfg{vis_opt} = 1;
$dm_cfg{table_name} = "exposants";
$dm_cfg{wherel} = "";
if($y > 0)
{
	my $id_code_annee = ','.($y-2008).',';
	$dm_cfg{wherep} = $dm_cfg{wherel} = " annees LIKE '%$id_code_annee%' ";
}
$dm_cfg{list_table_name} = "$dm_cfg{table_name}";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_handmade_energiesplus_exposants.pl?&y=$y";
$dm_cfg{file_prefixe} = 'EXP';
# $dm_cfg{default_ordby} = 'nom_commercial';
$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{tag_search} = 1;
$dm_cfg{autocreation} = 1;

# $dm_cfg{upload_file_type_only} = 'image/jpeg,image/pjpeg,image/jpeg,image/pjpeg,image/png';
$dm_cfg{upload_file_size_min} = 600;
$dm_cfg{after_upload_ref} = \&after_upload;


$dm_cfg{tag_table} = 'migcms_members_tags';
$dm_cfg{tag_col} = 'tags';
%truefalse = 
(
	'01/true'        =>"Oui",
	'02/false' =>"Non"
);	

@dm_nav =
	(
		 {
			'tab'=>'info',
			'type'=>'tab',
			'title'=>'Informations'
		}
		,
		{
			'tab'=>'contact',
			'type'=>'tab',
			'title'=>'Personnes de contact'
		}
		,
		{
			'tab'=>'adr',
			'type'=>'tab',
			'title'=>'Adresses'
		}
		,
		{
			'tab'=>'conn',
			'type'=>'tab',
			'title'=>'Connexion'
		}
		,
		{
			'tab'=>'produits',
			'type'=>'tab',
			'title'=>'Produits'
		}
		,
		{
			'tab'=>'marques',
			'type'=>'tab',
			'title'=>'Marques'
		}
		,
		{
			'tab'=> 'dtresume',
			'type'=>'tab',
			'title'=>'Résumé DT',
		}
		,
		{
			'tab'=> 'dt',
			'type'=>'tab',
			'title'=>'Détail DT',
			'cgi_func'=>\&dossier_technique,
		}
		,
		{
			'tab'=>'notes',
			'type'=>'tab',
			'title'=>'Notes',
			'cgi_func'=>\&notes,
		}
		# ,
		# {
			# 'tab'=>'tags',
			# 'type'=>'tab',
			# 'title'=>'Tags automatiques'
		# }
);


my $cpt = 1;
my $tab = 1;
my $prefixe = '';
my $fn=0;

$tab = 'info';
my $class = 'col-md-6';
my $input_style = 'width:120px;display:inline;';

%ouinon = 
	(
		'01/y' =>"Oui",
		'02/n' =>"Non",
	);

%dm_dfl = 
(

#INFORMATIONS *************************************************************************************

sprintf("%03d", $cpt++).'/nom_commercial'		=> {search=>'y','title'=>"Nom commercial",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/raison_sociale'		=> {search=>'y','title'=>"Raison sociale",'fieldtype'=>'text',tab=>$tab},
sprintf("%03d", $cpt++).'/est_actif'		=> {'title'=>"Est actif",'fieldtype'=>'checkbox',tab=>$tab,},
sprintf("%03d", $cpt++).'/is_linked_to_bob'		=> {'title'=>"Lié à BOB",'fieldtype'=>'listbox','data_type'=>'button',fieldvalues=>\%ouinon,tab=>$tab,},
sprintf("%03d", $cpt++).'/bob_id_customer'		=> {'title'=>"Référence BOB",'fieldtype'=>'text',tab=>$tab,},	
sprintf("%03d", $cpt++).'/num_stand'	=> {'title'=>"Numéro de stand",'fieldtype'=>'text',data_type=>'',tab=>$tab},	
# sprintf("%03d", $cpt++).'/xguest'	=> {search=>'y','title'=>"Guestcode",'fieldtype'=>'text',data_type=>'',tab=>$tab},	
sprintf("%03d", $cpt++).'/url_banniere'	=> {'title'=>"URL promotionnelle",'fieldtype'=>'text',data_type=>'',tab=>$tab},	
sprintf("%03d", $cpt++).'/meta_title'	=> {'title'=>"META Title",'fieldtype'=>'text',data_type=>'',tab=>$tab},	
sprintf("%03d", $cpt++).'/meta_description'	=> {'title'=>"META Description",'fieldtype'=>'text',data_type=>'',tab=>$tab},	
sprintf("%03d", $cpt++).'/facebook'	=> {'title'=>"Facebook",'fieldtype'=>'text',data_type=>'',tab=>$tab},	
,	
sprintf("%03d", $cpt++).'/fichiers'=> 
{
	'title'=>"Logo",
	'tab'=>'photos',
	'fieldtype'=>'files_admin',
	'disable_add'=>1,
	'tab'=>$tab,
	'msg'=>'Cliquez <b>ici</b> pour parcourir votre ordinateur ou déposez directement une image dans ce cadre. <b>Format requis:</b> <u>jpg</u> Taille minimum: <u>600 pixels</u>, RVB.',
}
,	
sprintf("%03d", $cpt++).'/fichiers2'=> 
{
	'title'=>"Fichiers",
	'tab'=>'photos',
	'fieldtype'=>'files_admin',
	'disable_add'=>1,
	'tab'=>$tab,
	'msg'=>'Cliquez <b>ici</b> pour parcourir votre ordinateur ou déposez directement une image dans ce cadre.',
}
,
sprintf("%03d", $cpt++).'/annees/'=>{'btn_style'=>' style="width:400px" ','title'=>'Années','multiple'=>1,'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},tab=>$tab,'lbtable'=>'handmade_codes_annees','lbkey'=>'id','lbdisplay'=>'name','lbwhere'=>"visible='y'",'lbordby'=>"ordby",'fieldvalues'=>'','hidden'=>0},

#PERSONNES DE CONTACT *************************************************************************************

#Responsable marketing*************************************************************************************
sprintf("%03d", $cpt++).'/titre' => {'title'=>'Responsable marketing','fieldtype'=>'titre',data_type=>'',tab=>$tab='contact'},

sprintf("%03d", $cpt++).'/magazine_lastname'		=> {search=>'y','title'=>"Nom",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/magazine_firstname'		=> {search=>'y','title'=>"Prénom",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/magazine_fonction'		=> {search=>'y','title'=>"Fonction",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/magazine_tel'		=> {search=>'y','title'=>"Téléphone",'fieldtype'=>'text','data_type'=>'phone',tab=>$tab},	
sprintf("%03d", $cpt++).'/magazine_gsm'		=> {search=>'y','title'=>"GSM",'fieldtype'=>'text','data_type'=>'gsm',tab=>$tab},	
sprintf("%03d", $cpt++).'/magazine_email'		=> {search=>'y','title'=>"Email",'fieldtype'=>'text','data_type'=>'email',tab=>$tab},	

#Responsable commercial*************************************************************************************
sprintf("%03d", $cpt++).'/titre' => {'title'=>'Responsable commercial','fieldtype'=>'titre',data_type=>'',tab=>$tab='contact'},

sprintf("%03d", $cpt++).'/livraison_lastname'		=> {search=>'y','title'=>"Nom",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/livraison_firstname'		=> {search=>'y','title'=>"Prénom",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/livraison_fonction'		=> {search=>'y','title'=>"Fonction",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/livraison_tel'		=> {search=>'y','title'=>"Téléphone",'fieldtype'=>'text','data_type'=>'phone',tab=>$tab},	
sprintf("%03d", $cpt++).'/livraison_gsm'		=> {search=>'y','title'=>"GSM",'fieldtype'=>'text','data_type'=>'gsm',tab=>$tab},	
sprintf("%03d", $cpt++).'/livraison_email'		=> {search=>'y','title'=>"Email",'fieldtype'=>'text','data_type'=>'email',tab=>$tab},	

#Responsable facturation*************************************************************************************
sprintf("%03d", $cpt++).'/titre' => {'title'=>'Responsable facturation','fieldtype'=>'titre',data_type=>'',tab=>$tab='contact'},

sprintf("%03d", $cpt++).'/facturatio_lastname'		=> {search=>'y','title'=>"Nom",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/facturatio_firstname'		=> {search=>'y','title'=>"Prénom",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/facturatio_fonction'		=> {search=>'y','title'=>"Fonction",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/facturatio_email'		=> {search=>'y','title'=>"Email de facturation",'fieldtype'=>'text','data_type'=>'email',tab=>$tab},	
sprintf("%03d", $cpt++).'/facturatio_tel'		=> {search=>'y','title'=>"Téléphone",'fieldtype'=>'text','data_type'=>'phone',tab=>$tab},	
sprintf("%03d", $cpt++).'/facturatio_gsm'		=> {search=>'y','title'=>"GSM",'fieldtype'=>'text','data_type'=>'gsm',tab=>$tab},	


#PERSONNES DE CONTACT *************************************************************************************

#Coordonnées pour le site et le magazine E+C*************************************************************************************
sprintf("%03d", $cpt++).'/titre' => {'title'=>'Coordonnées pour le site et le magazine E+C','fieldtype'=>'titre',data_type=>'',tab=>$tab='adr'},

sprintf("%03d", $cpt++).'/ad_name'		=> {search=>'y','title'=>"Nom de la firme",'legend'=>"Nom Commercial",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/ad_street'		=> {search=>'y','title'=>"Rue",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/ad_number'		=> {search=>'y','title'=>"N°",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/ad_zip'		=> {search=>'y','title'=>"Code postal",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/ad_city'		=> {search=>'y','title'=>"Ville",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/ad_country'		=> {search=>'y','title'=>"Pays",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/ad_tel'		=> {search=>'y',data_type=>'tel','title'=>"Téléphone",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/ad_fax'		=> {search=>'y',data_type=>'tel','title'=>"FAX",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/ad_web'		=> {search=>'y','title'=>"Site web",'fieldtype'=>'text',tab=>$tab},	

#Responsable marketing*************************************************************************************

sprintf("%03d", $cpt++).'/titre' => {'title'=>'Coordonnées de facturation (via BOB)','fieldtype'=>'titre',data_type=>'',tab=>$tab},
sprintf("%03d", $cpt++).'/fa_name'		=> {search=>'y','title'=>"Nom de la firme",'legend'=>"Raison sociale",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/fa_forme_juridique'		=> {search=>'y','title'=>"Forme juridique",'legend'=>"",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/fa_email'		=> {search=>'y','title'=>"Email envoi facture",'legend'=>"",'fieldtype'=>'text','data_type'=>'email',tab=>$tab},	
sprintf("%03d", $cpt++).'/fa_street'		=> {search=>'y','title'=>"Rue",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/fa_number'		=> {search=>'y','title'=>"N°",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/fa_zip'		=> {search=>'y','title'=>"Code postal",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/fa_city'		=> {search=>'y','title'=>"Ville",'fieldtype'=>'text',tab=>$tab},	
sprintf("%03d", $cpt++).'/fa_country'		=> {search=>'y','title'=>"Pays",'fieldtype'=>'text',tab=>$tab},	

#CONNEXION *************************************************************************************

#Responsable marketing*************************************************************************************
sprintf("%03d", $cpt++).'/titre' => {'title'=>'Accès N°1','fieldtype'=>'titre',data_type=>'',tab=>$tab='conn'},
sprintf("%03d", $cpt++).'/acces_1_email'		=> {search=>'y','title'=>"Email",'fieldtype'=>'text','data_type'=>'email',tab=>$tab},	
sprintf("%03d", $cpt++).'/acces_1_password'		=> {search=>'y','title'=>"Mot de passe",'fieldtype'=>'text','data_type'=>'',tab=>$tab},	
sprintf("%03d", $cpt++).'/titre' => {'title'=>'Accès N°2','fieldtype'=>'titre',data_type=>'',tab=>$tab},
sprintf("%03d", $cpt++).'/acces_2_email'		=> {search=>'y','title'=>"Email",'fieldtype'=>'text','data_type'=>'email',tab=>$tab},	
sprintf("%03d", $cpt++).'/acces_2_password'		=> {search=>'y','title'=>"Mot de passe",'fieldtype'=>'text','data_type'=>'',tab=>$tab},	
sprintf("%03d", $cpt++).'/titre' => {'title'=>'Accès N°3','fieldtype'=>'titre',data_type=>'',tab=>$tab},
sprintf("%03d", $cpt++).'/acces_3_email'		=> {search=>'y','title'=>"Email",'fieldtype'=>'text','data_type'=>'email',tab=>$tab},	
sprintf("%03d", $cpt++).'/acces_3_password'		=> {search=>'y','title'=>"Mot de passe",'fieldtype'=>'text','data_type'=>'',tab=>$tab},	
sprintf("%03d", $cpt++).'/titre' => {'title'=>'Accès N°4','fieldtype'=>'titre',data_type=>'',tab=>$tab},
sprintf("%03d", $cpt++).'/acces_4_email'		=> {search=>'y','title'=>"Email",'fieldtype'=>'text','data_type'=>'email',tab=>$tab},	
sprintf("%03d", $cpt++).'/acces_4_password'		=> {search=>'y','title'=>"Mot de passe",'fieldtype'=>'text','data_type'=>'',tab=>$tab},	
sprintf("%03d", $cpt++).'/titre' => {'title'=>'Accès N°5','fieldtype'=>'titre',data_type=>'',tab=>$tab},
sprintf("%03d", $cpt++).'/acces_5_email'		=> {search=>'y','title'=>"Email",'fieldtype'=>'text','data_type'=>'email',tab=>$tab},	
sprintf("%03d", $cpt++).'/acces_5_password'		=> {search=>'y','title'=>"Mot de passe",'fieldtype'=>'text','data_type'=>'',tab=>$tab},	

#PRODUITS*************************************************************************************
sprintf("%03d", $cpt++).'/produits_magazine' => 
{
   'title'=>'Produit magazine',
   'fieldtype'=>'listboxtable',
   'data_type'=>'treeview',
   'lbtable'=>'handmade_energiesplus_produits',
   'multiple'=>'',
   'translate'=>0,
   'lbkey'=>'id',
   'legend'=>'',
   'lbdisplay'=>'name',
   'summary'=>0,
   'tree_col'=>'id_father',
   'lbwhere'=>"",
   'tab'=>'produits'
},
sprintf("%03d", $cpt++).'/produits_web' => 
{
   'title'=>'Produit web',
   'fieldtype'=>'listboxtable',
   'data_type'=>'treeview',
   'lbtable'=>'handmade_energiesplus_produits',
   'multiple'=>'',
   'translate'=>0,
   'lbkey'=>'id',
   'lbdisplay'=>'name',
   'summary'=>0,
   'tree_col'=>'id_father',
   'legend'=>'Ces produits seront utilisés pour calculer les leads visiteurs',
   'lbwhere'=>"",
   'tab'=>'produits'
},

#MARQUES*************************************************************************************
sprintf("%03d", $cpt++).'/marques'=>{'title'=>'Marques','multiple'=>1,'translate'=>0,'fieldtype'=>'listboxtable','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},tab=>'marques','lbtable'=>'marques','lbkey'=>'id','lbdisplay'=>'nom_marque','lbwhere'=>"",'lbordby'=>"nom_marque",'fieldvalues'=>'','hidden'=>0},


#Résumé DT *************************************************************************************
sprintf("%03d", $cpt++).'/titre' => {'title'=>'Résumé du dossier','fieldtype'=>'titre',data_type=>'',tab=>$tab='dtresume'},

sprintf("%03d", $cpt++).'/xplanstand'	=>	{'title'=>"Plan reçu",'translate'=>0,'fieldtype'=>'listbox','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>\%truefalse,'hidden'=>0},
sprintf("%03d", $cpt++).'/xplaneauele'	=>	{'title'=>"Plan eau, électricité reçu",'translate'=>0,'fieldtype'=>'listbox','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>\%truefalse,'hidden'=>0},
sprintf("%03d", $cpt++).'/xrecudocume'	=>	{'title'=>"Recu document",'translate'=>0,'fieldtype'=>'listbox','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>\%truefalse,'hidden'=>0},
sprintf("%03d", $cpt++).'/xstandmodul'	=>	{'title'=>"Stand modulaire",'translate'=>0,'fieldtype'=>'listbox','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>\%truefalse,'hidden'=>0},
sprintf("%03d", $cpt++).'/xstandperso'	=>	{'title'=>"Stand personnalisé",'translate'=>0,'fieldtype'=>'listbox','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>\%truefalse,'hidden'=>0},
sprintf("%03d", $cpt++).'/xdttermine'	=>	{'title'=>"DT terminé",'translate'=>0,'fieldtype'=>'listbox','data_type'=>'button','search' => 'n','mandatory'=>{"type" => ''},'tab'=>$tab,'default_value'=>'','lbtable'=>'','lbkey'=>'','lbdisplay'=>'','lbwhere'=>"",'lbordby'=>"",'fieldvalues'=>\%truefalse,'hidden'=>0},

sprintf("%03d", $cpt++).'/titre' => {'title'=>'Solde (via BOB)','fieldtype'=>'titre',data_type=>'',tab=>$tab},

sprintf("%03d", $cpt++).'/total_amount'		=> {'title'=>"Total à payer",'fieldtype'=>'text',data_type=>'euros',tab=>$tab},	
sprintf("%03d", $cpt++).'/total_paid'		=> {'title'=>"Total payé",'fieldtype'=>'text',data_type=>'euros',tab=>$tab},	

# sprintf("%03d", $cpt++).'/tags'=> 
		# {
			# 'title'=>"Tags (ne pas modifier)",
			# 'fieldtype'=>'listboxtable',
			# 'lbtable'=>'migcms_members_tags',
			# 'data_type'=>'button',
			# 'multiple'=>1,
			# 'lbkey'=>'id',
			# 'hidden'=>0,
			# 'lbdisplay'=>"name",
			# 'lbwhere'=>"visible='y'" ,
			# 'lbordby'=>"ordby" ,
			# 'search' => 'n',
			# 'tab'=>'tags',
			# 'data_split'=>'type',
		# },
);

%dm_display_fields =  
(
"01/Nom commercial"=>"nom_commercial",
"06/Années"=>"annees",		
"07/N° Stand"=>"num_stand",		
"08/Est actif"=>"est_actif",		
); 

if($y>0)
{
	delete $dm_display_fields{'99/Tags'};
}

%dm_lnk_fields = 
(
"01/Logo" =>"logo*",
);

%dm_mapping_list = 
(
"logo"=>\&logo,
);

%dm_filters = (
);

		
$dm_cfg{list_html_top} = <<"EOH";	
<style>
.cms_mig_cell_magazine_xlettre,.cms_mig_cell_bob_id_customer
{
	width:50px;
}
.cms_mig_cell_annees
{
	width:150px;
}
.mig_cell_func_1
{
	width:80px!important;
}
</style>
EOH


$sw = $cgi->param('sw') || "list";

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
    see();
    dm_init();
    
    
    &$sw();
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}



sub after_upload
{
	my $dbh=$_[0];
	my $id=$_[1];
	my %exposant = sql_line({table=>'exposants',where=>"id='$id'"});
	
	#calcul les tailles des images: d'abord celles du templates sinon les valeurs par défaut
	my $i_size = 0;
	my @sizes = ('mini','small','medium');
	my @sizes_pixels = (150,300,600);
	
	#boucle sur les images 
	my @migcms_linked_files = sql_lines({debug=>1,debug_results=>1,table=>'migcms_linked_files',where=>"ext IN ('.jpg','.jpeg','.png') AND table_name='$dm_cfg{table_name}' AND table_field='fichiers' AND token='$id'",ordby=>'ordby'});
	foreach $migcms_linked_file (@migcms_linked_files)
	{
		#appelle la fonction de redimensionnement
		$i_size = 0;
		
		my %migcms_linked_file = %{$migcms_linked_file};
		my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
		my %params = (
			migcms_linked_file=>\%migcms_linked_file,
			do_not_resize=>'n',
		);
		foreach my $size (@sizes)
		{
			$params{'size_'.$size} = $sizes_pixels[$i_size];
			$i_size++;
		}
		dm::resize_pic(\%params);
		
		
	}	
}

sub dossier_technique
{
	my $id_rec = $_[1];
	
	my %exposant = sql_line({table=>'exposants',where=>"id='$id_rec'"});
	my $disabled_dt = '';
	my $info_dt = '';
	if($exposant{is_linked_to_bob} eq 'y')
	{
		$disabled_dt = ' disabled ';
		$info_dt = '<span class="help-block text-left"><i class="fa fa-info-circle" data-original-title="" title=""></i> Cet exposant est lié à BOB. L\'édition du dossier technique est donc désactivé.</span><br />';
	}
	else
	{
		$info_dt = '<span class="help-block text-left"><i class="fa fa-check" data-original-title="" title=""></i> Cet exposant n\'est pas lié à BOB. L\'édition du dossier technique est autorisé.</span><br />';
	}
	
	my $dossier_technique = '';
	my $active = 'active';

	$dossier_technique .= <<"EOH";
		<style>
		.tabs-left,.tabs-right{border-bottom:none;padding-top:2px}.tabs-left{border-right:1px solid #ddd}.tabs-right{border-left:1px solid #ddd}.tabs-left>li,.tabs-right>li{float:none;margin-bottom:2px}.tabs-left>li{margin-right:-1px}.tabs-right>li{margin-left:-1px}.tabs-left>li.active>a,.tabs-left>li.active>a:focus,.tabs-left>li.active>a:hover{border-bottom-color:#ddd;border-right-color:transparent}.tabs-right>li.active>a,.tabs-right>li.active>a:focus,.tabs-right>li.active>a:hover{border-bottom:1px solid #ddd;border-left-color:transparent}.tabs-left>li>a{border-radius:4px 0 0 4px;margin-right:0;display:block}.tabs-right>li>a{border-radius:0 4px 4px 0;margin-right:0}.sideways{margin-top:50px;border:none;position:relative}.sideways>li{height:20px;width:120px;margin-bottom:100px}.sideways>li>a{border-bottom:1px solid #ddd;border-right-color:transparent;text-align:center;border-radius:4px 4px 0 0}.sideways>li.active>a,.sideways>li.active>a:focus,.sideways>li.active>a:hover{border-bottom-color:transparent;border-right-color:#ddd;border-left-color:#ddd}.sideways.tabs-left{left:-50px}.sideways.tabs-right{right:-50px}.sideways.tabs-right>li{-webkit-transform:rotate(90deg);-moz-transform:rotate(90deg);-ms-transform:rotate(90deg);-o-transform:rotate(90deg);transform:rotate(90deg)}.sideways.tabs-left>li{-webkit-transform:rotate(-90deg);-moz-transform:rotate(-90deg);-ms-transform:rotate(-90deg);-o-transform:rotate(-90deg);transform:rotate(-90deg)}
		.linktab
		{
			color:black!important;
		}
		.linktab:hover
		{
			color:white!important;
		}
		</style>
		$info_dt
	<div class="row">	
		<div class="col-xs-5"> <!-- required for floating -->
		<!-- Nav tabs -->
		  <ul class="nav nav-tabs tabs-left" role="tablist">
EOH
		  
	my @dt_ref_tabs = sql_lines({table=>"dt_ref",where=>"visible='y'",select=>'distinct(tab) as tab',ordby=>'tab',limit=>""});
	foreach $dt_ref_tab (@dt_ref_tabs)
    {
       
	   my %dt_ref_tab = %{$dt_ref_tab};
	   my $cle = clean_url($dt_ref_tab{tab});
	    $cle =~ s/[^a-z]//g;

		$dossier_technique .= <<"EOH";
			<li role="presentation" class="$active"><a href="#$cle" class="linktab" aria-controls="$cle" role="tab" data-toggle="tab">$dt_ref_tab{tab}</a></li>
EOH
		$active = '';	
    }
	
		$dossier_technique .= <<"EOH";
		  </ul>
		  </div>
		  <div class="col-xs-7">
		  
		  <!-- Tab panes -->
		  <div class="tab-content" >
EOH
	$active = 'active';
	foreach $dt_ref_tab (@dt_ref_tabs)
    {
	   my %dt_ref_tab = %{$dt_ref_tab};
	   my $cle = clean_url($dt_ref_tab{tab});
		$cle =~ s/[^a-z]//g;
		$dossier_technique .= <<"EOH";
			<div role="tabpanel" class="tab-pane $active" id="$cle">
EOH
		my @dt_refs = sql_lines({table=>"dt_ref",where=>"visible='y'",where=>"tab='$dt_ref_tab{tab}'",ordby=>'ordby',limit=>""});
		foreach $dt_ref (@dt_refs)
		{
			my %dt_ref = %{$dt_ref};
			my %dt = sql_line({table=>"dt",where=>"bob_id_customer='$exposant{bob_id_customer}' and bob_id_customer != '' and tag = '$dt_ref{tag}'"});

			if($dt{qty} eq '')
			{
			  $dt{qty}=0;
			}
			if($dt{pu} eq '')
			{
			  $dt{pu}=0;
			}
			if($dt{base_amount} eq '')
			{
			  $dt{base_amount}=0;
			}
			if($dt{total_amount} eq '')
			{
			  $dt{total_amount}=0;
			}
			$dossier_technique .= <<"EOH";
			
			<h4>$dt_ref{description}:</h4>
			<table class="table">
				<tr>
					<td style="text-align:left; padding:2px; margin:2px; $color1 width:100%;">
						<input type="text" $disabled_dt style="width:100px;display:inline!important;"  name="$dt_ref{tag}___qty" class="saveme qty dt_qty form-control" id="" value="$dt{qty}" /> 
						x 
						<input type="text" $disabled_dt style="width:100px;display:inline!important;" name="$dt_ref{tag}___pu" class="saveme pu dt_pu form-control" id="" value="$dt{pu}" />  
						= 
						<input type="text" $disabled_dt style="width:100px;display:inline!important;" name="$dt_ref{tag}___base_amount" class="saveme base_amount dt_ba form-control" id="" value="$dt{base_amount}" /> 
						€ 
						htva 
						(
						<input type="text" $disabled_dt style="width:100px;display:inline!important;" name="$dt_ref{tag}___total_amount" class="saveme total_amount dt_ta form-control" id="" value="$dt{total_amount}" /> 
						€ tvac
						)     
					</td>
				</tr> 
			</table>  
EOH
		}
		$dossier_technique .= <<"EOH";
			</div>
EOH
		$active = '';
    }
		$dossier_technique .= <<"EOH";
		  </div>
		</div>
	  </div>
EOH
	
	return $dossier_technique;
}

# sub dossier_technique
# {
	# my $id_rec = $_[1];
	# my $dossier_technique = 'dt';
	
	

	# $dossier_technique = <<"EOH";
		# <div>
		  # <!-- Nav tabs -->
		  # <ul class="nav nav-tabs" role="tablist">
			# <li role="presentation" class="active"><a href="#home" aria-controls="home" role="tab" data-toggle="tab">Home</a></li>
			# <li role="presentation"><a href="#profile" aria-controls="profile" role="tab" data-toggle="tab">Profile</a></li>
			# <li role="presentation"><a href="#messages" aria-controls="messages" role="tab" data-toggle="tab">Messages</a></li>
			# <li role="presentation"><a href="#settings" aria-controls="settings" role="tab" data-toggle="tab">Settings</a></li>
		  # </ul>

		  # <!-- Tab panes -->
		  # <div class="tab-content">
			# <div role="tabpanel" class="tab-pane active" id="home">A</div>
			# <div role="tabpanel" class="tab-pane" id="profile">B</div>
			# <div role="tabpanel" class="tab-pane" id="messages">...</div>
			# <div role="tabpanel" class="tab-pane" id="settings">...</div>
		  # </div>
		# </div>
# EOH
	
	# return $dossier_technique;
	
# }

sub notes
{
	my $id_rec = $_[1];
	
	my $notes = '';

	my @notes_fields = sql_lines({table=>"exposants_notes_fields",where=>"visible='y'",ordby=>"ordby"});
	foreach $note_field (@notes_fields)
	{
		my %note_field = %{$note_field};
		$note_field{name} = ucfirst(lc($note_field{name}));
		
		my %lnk_note = sql_line({table=>"exposants_notes",where=>"id_note='$note_field{id}' AND id_exposant = '$id_rec'"});
			
		my $champ = '';
		
		if($note_field{type} eq 'bloc')
		{
			$champ =<<"EOH";
			<textarea name="note_$note_field{id}" $required_value id="note_$note_field{id}" rows="3" class="form-control saveme" placeholder="$placeholder">$lnk_note{note}</textarea>

EOH
		}
		elsif($note_field{type} eq 'line')
		{
			$champ =<<"EOH";
			<input autocomplete="off" data-domask="" rel="" name="note_$note_field{id}" value="$lnk_note{note}" id="note_$note_field{id}" class="clear_field form-control saveme saveme_txt " placeholder="" type="text">
EOH
		}
		elsif($note_field{type} eq 'list')
		{
			my @valeurs= split(/\,/,$note_field{valeurs});
			$champ =<<"EOH";
				<select id="note_$note_field{id}" class="note_$note_field{id} form-control saveme" name="note_$note_field{id}">
EOH
			$sel_val{$lnk_note{note}} = ' selected="selected" ';
			foreach my $valeur (@valeurs)
			{
				$champ .=<<"EOH";
					<option $sel_val{$valeur} value="$valeur">$valeur</option>
EOH
			}
			$champ .=<<"EOH";
				</select>
EOH
		}
		
        $notes .=<<"EOH";
        
    
		   
		   
		   <div class="form-group item  row_edit_id_note_$n migcms_group_data_type_ hidden_ ">
					<label for="field_id_note_$note_field{id}" class="col-sm-2 control-label">
					 $note_field{name}
				</label>
				<div class="col-sm-10 mig_cms_value_col">
$champ
					<span class="help-block text-left"></span>
				</div>

</div>
EOH
    }


	return $notes;
}

sub after_save
{
	my $new_id = $_[1];
	
	save_notes($new_id); 
	
	my %exposant = read_table($dbh,'exposants',$new_id);
	
	#membres lies à l'exposant
	my @migcms_members = sql_lines({select=>"id",table=>'migcms_members',where=>"id_exposant = '$exposant{id}' AND id_exposant > 0"});
	foreach $migcms_member(@migcms_members)
	{
		my %migcms_member = %{$migcms_member};
		def_handmade::recompute_member_tags_and_lnks($migcms_member{id});	
	}	
}

sub save_notes
{
	my $new_id = $_[0];
	
	my @notes_fields = sql_lines({table=>"exposants_notes_fields",where=>"visible='y'",ordby=>"ordby"});
	foreach $note_field (@notes_fields)
	{
		my %note_field = %{$note_field};
		
		my $note_txt = get_quoted('note_'.$note_field{id});
		$note_txt = quote($note_txt);
		my %rec = 
		(
			id_exposant => $new_id,
			id_note => $note_field{id},
			note => $note_txt,
			migcms_moment_last_edit => 'NOW()',
			migcms_id_user_last_edit => $user{id},	
		);
		my $where = " id_note = $rec{id_note} AND id_exposant = $rec{id_exposant}";
		my $id = sql_set_data({dbh=>$dbh,debug=>0,table=>'exposants_notes',data=>\%rec, where=>$where});  
	}
}

sub logo
{
	my $dbh = $_[0];
	my $id = $_[1];
	my %d = %{$_[3]};
  
	my %migcms_linked_file = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='exposants' and token='$id'",limit=>'0,1',ordby=>'ordby'});
	my $url_pic_preview = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
	my $img = "<img style=\"width:75px\" src='$url_pic_preview' />";
	my $img_default = "<img style=\"width:75px\" src='/usr/files/EXP/fichiers/201600035/EXP201600035_001_20170102151539.png' />";
	
	my $link = '';
	
	if($migcms_linked_file{id} > 0)
	{
		$link = $img;
	}
	else
	{
		$link = $img_default;
	}
	
	return '<a id ="'.$id.'" href="#" class="show_only_after_document_ready migedit_'.$id.' migedit dm_migedit">'.$link.'</a>';
	
}

sub link_exposant_to_members
{
	see();
	exit;
	my @migcms_members = sql_lines({table=>'migcms_members',where=>"id_exposant > 0",ordby=>"id_exposant"});
	foreach $migcms_member(@migcms_members)
	{
		my %migcms_member = %{$migcms_member};
		my %exposant = read_table($dbh,'exposants',$migcms_member{id_exposant});
		print "<br />$exposant{nom_commercial}: $migcms_member{email}";
		foreach my $num (1 .. 5)
		{
			my $col = 'acces_'.$num.'_email';
			if($exposant{$col} eq '')
			{
				print "-> COL $col";
				my $stmt = <<"EOH";
				UPDATE exposants SET $col = '$migcms_member{email}' WHERE id = '$migcms_member{id_exposant}'
EOH
				execstmt($dbh,$stmt);
				last;
			}
		}
	}
	exit;
}