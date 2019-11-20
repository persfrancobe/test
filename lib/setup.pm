#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
package setup;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@ISA = qw(Exporter);	
@EXPORT = qw(
					%balises
					get_balises

					get_site_setup

					get_migcms_site_emails_header
					get_migcms_site_emails_footer
					get_migcms_site_email_content
					
            );
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use def;
use tools;

%balises = ();
if(!($config{current_language} > 0))
{
	$config{current_language} = 1;
}


%balises = %{get_balises($dbh,$config{current_language})};

sub get_balises
{
	my %dm_dfl = %{get_setup_dm_dfl()};

	my $lg = $_[1] || $config{current_language} || 1;

	my %balises = ();

	foreach $key (keys %dm_dfl)
	{
		@splitted = split("/", $key);
		my $name = $splitted[1];		

		$lg =~ s/\D//g;
	
		if(!($lg > 0 && $lg <= 10))
		{
			$lg = 1;
		}
		
		$_ = $name; 
		if(/_balise_/)
		{
			my %balise = sql_line({debug=>0, dbh=>$dbh, table=>"migcms_setup, txtcontents as txt", select=>"txt.lg$lg as content", where=>"txt.id = migcms_setup.$name"});

			if($dm_dfl{$key}{"balise_name"} ne "")
			{
				$balises{$dm_dfl{$key}{"balise_name"}} = $balise{content};				
			}
		}
	}

	return \%balises;
}


sub get_setup_dm_dfl
{
	my %dm_dfl = 
	(
	'22/view_edit_on'=> 
	{
		'title'=>'Activer la retouche rapide WYSIWYG',
		'fieldtype'=>'checkbox',
		'checkedval' => 'y',
		'tab' => 'site'
	}
	,
	'20/id_default_page'=> 
	{
		'title'=>'Page d\'accueil du site',
		'fieldtype'=>'listboxtable',
		'data_type'=>'treeview',
		'lbwhere'=>"migcms_pages_type!='newsletter' AND migcms_pages_type!='block' AND migcms_pages_type!='handmade'",			
		'lbtable'=>'migcms_pages',
		'lbkey'=>'id',
		'legend'=>"",
		'lbdisplay'=>'id_textid_name',
		'tab'    => 'site',
		'translate' => 1,
		'multiple'=>0,
		'summary'=>0,
		'tree_col'=>'id_father',
	}
	,
	'21/id_notfound_page'=> 
	{
		'title'=>'Page erreur 404',
		'fieldtype'=>'listboxtable',
		'data_type'=>'treeview',
		'lbwhere'=>"migcms_pages_type!='newsletter' AND migcms_pages_type!='block' AND migcms_pages_type!='handmade'",
		'lbtable'=>'migcms_pages',
		'lbkey'=>'id',
		'legend'=>"",
		'lbdisplay'=>'id_textid_name',
		'tab'    => 'site',
		'translate' => 1,
		'multiple'=>0,
		'summary'=>0,
		'tree_col'=>'id_father',
	}
		# ,
		# '70/cache_template'=> 
	      # {
	      # 'title'=>'Activer le cache template',
	      # 'fieldtype'=>'checkbox',
	      # 'checkedval' => 'y',
	      # 'tab' => 'admin'
	      # }
	      # ,
		# '71/cache_sitetxt'=> 
	      # {
	      # 'title'=>'Activer le cache sitetxt',
	      # 'fieldtype'=>'checkbox',
	      # 'checkedval' => 'y',
	      # 'tab' => 'admin'
	      # }
	     ,
	'72/cache_txtcontent'=> 
    {
		'title'=>'Activer le cache "txtcontent"',
		'fieldtype'=>'checkbox',
		'checkedval' => 'y',
		'tab' => 'site'
    },
    '80/compile_js'=> 
    {
		'title'=>'Compiler le javascript',
		'fieldtype'=>'checkbox',
		'checkedval' => 'y',
		'tab' => 'site'
    }
	,
    #### BALISES ####
    #################
    '300/id_textid_balise_company'=> 
    {
			'title'     => 'Société & forme juridique',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "company",
			'legend' => 'MIGC_BALISES_[company]_HERE',
    },
    '301/id_textid_balise_address'=> 
    {
			'title'     => 'Adresse',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "address",
			'legend' => 'MIGC_BALISES_[address]_HERE',
    },
    '302/id_textid_balise_number'=> 
    {
			'title'     => 'Numéro',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "number",
			'legend' => 'MIGC_BALISES_[number]_HERE',
    },
    '303/id_textid_balise_zip'=> 
    {
			'title'     => 'Code postal',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "zip",
			'legend' => 'MIGC_BALISES_[zip]_HERE',
    },
    '304/id_textid_balise_city'=> 
    {
			'title'     => 'Ville',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "city",
			'legend' => 'MIGC_BALISES_[city]_HERE',
    },
    '305/id_textid_balise_country'=> 
    {
			'title'     => 'Pays',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "country",
			'legend' => 'MIGC_BALISES_[country]_HERE',
    },
    '306/id_textid_balise_vat'=> 
    {
			'title'     => 'TVA',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "vat",
			'legend' => 'MIGC_BALISES_[vat]_HERE',
    },
    '307/id_textid_balise_gps'=> 
    {
			'title'     => 'GPS',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "gps",
			'legend' => 'MIGC_BALISES_[gps]_HERE',
    },
    '308/id_textid_balise_phone'=> 
    {
			'title'     => 'Téléphone',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "phone",
			'legend' => 'MIGC_BALISES_[phone]_HERE',
    },
    '309/id_textid_balise_fax'=> 
    {
			'title'     => 'Fax',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "fax",
			'legend' => 'MIGC_BALISES_[fax]_HERE',
    },
    '310/id_textid_balise_email_1_title'=> 
    {
			'title'     => 'Titre email 1',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "email_1_title",
			'legend' => 'MIGC_BALISES_[email_1_title]_HERE',
    },
    '311/id_textid_balise_email_1'=> 
    {
			'title'     => 'Email 1',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "email_1",
			'legend' => 'MIGC_BALISES_[email_1]_HERE',
    },
    '312/id_textid_balise_email_2_title'=> 
    {
			'title'     => 'Titre email 2',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "email_2_title",
			'legend' => 'MIGC_BALISES_[email_2_title]_HERE',
    },
    '313/id_textid_balise_email_2'=> 
    {
			'title'     => 'Email 2',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "email_2",
			'legend' => 'MIGC_BALISES_[email_2]_HERE',
    },
    '314/id_textid_balise_banque'=> 
    {
			'title'     => 'Banque',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "banque",
			'legend' => 'MIGC_BALISES_[banque]_HERE',
    },
    '315/id_textid_balise_iban'=> 
    {
			'title'     => 'IBAN',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "iban",
			'legend' => 'MIGC_BALISES_[iban]_HERE',
    },
    '316/id_textid_balise_bic'=> 
    {
			'title'     => 'BIC',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "bic",
			'legend' => 'MIGC_BALISES_[bic]_HERE',
    },
    '317/id_textid_balise_web'=> 
    {
			'title'     => 'URL site web',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "web",
			'legend' => 'MIGC_BALISES_[web]_HERE',
    },
    '330/id_textid_balise_url_facebook'=> 
    {
			'title'     => 'URL Facebook',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "url_facebook",
			'legend' => 'MIGC_BALISES_[url_facebook]_HERE',
    },
    '331/id_textid_balise_url_twitter'=> 
    {
			'title'     => 'URL Twitter',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "url_twitter",
			'legend' => 'MIGC_BALISES_[url_twitter]_HERE',
    },
    '332/id_textid_balise_url_googleplus'=> 
    {
			'title'     => 'URL Google+',
			'fieldtype' => 'text_id',
			'tab'       => 'balises',
			'balise_name' => "url_googleplus",
			'legend' => 'MIGC_BALISES_[url_googleplus]_HERE',
    },
    #### REFERENCEMENT ####
    #######################
    '400/id_textid_balise_seo_site_name'=> 
    {
			'title'     => 'Nom du site web',
			'fieldtype' => 'text_id',
			'tab'       => 'seo',
			'balise_name' => "seo_site_name",
			'legend' => 'MIGC_BALISES_[seo_site_name]_HERE',

    },
    ##### EMAIL #####
    #################
    '498/use_site_email_template'=> 
	  {
	    'title'      => "Activer le template général pour les mails",
	    'fieldtype'  => 'checkbox',
	    'checkedval' => 'y',
	    'tab'        => 'email', 
	  }
	  , 
	  '499/custom_site_email_header_func'=> 
	  {
	    'title'      => "Fonction de header sur-mesure",
	    'fieldtype'  => 'text',
	    'tab'        => 'email', 
	  }
	  ,
	  '500/custom_site_email_content_func'=> 
	  {
	    'title'      => "Fonction de content sur-mesure",
	    'fieldtype'  => 'text',
	    'tab'        => 'email', 
	  }
	  ,
	  '501/custom_site_email_footer_func'=> 
	  {
	    'title'      => "Fonction de footer sur-mesure",
	    'fieldtype'  => 'text',
	    'tab'        => 'email', 
	  }
	  ,
    '502/id_pic_logo_email'=> 
    {
        'title'=>"Logo",
        'fieldtype'=>'files_admin',
        'disable_add'=>0,
        'msg'=>'Cliquez <b>ici</b> pour parcourir votre ordinateur ou déposez directement des photos dans ce cadre.',
        'tab' => "email",
    }
    ,
    '503/color_bandeau'=> 
    {
			'title'     => 'Couleur du contenu des bandeaux (#)',
			'fieldtype' => 'text',
			'tab'       => 'email',
    },
    '504/color_bandeau_bg'=> 
    {
			'title'     => 'Couleur de fond des bandeaux (#)',
			'fieldtype' => 'text',
			'tab'       => 'email',
    },
    '505/color_content'=> 
    {
			'title'     => 'Couleur du contenu (#)',
			'fieldtype' => 'text',
			'tab'       => 'email',
    },
    '506/color_content_link'=> 
    {
			'title'     => 'Couleur des liens du contenu (#)',
			'fieldtype' => 'text',
			'tab'       => 'email',
    },
    '510/color_entete_link'=> 
    {
			'title'     => 'Couleur des liens de l\'entête (#)',
			'fieldtype' => 'text',
			'tab'       => 'email',
    },
    '530/id_textid_balise_header_1_txt'=> 
    {
			'title'     => 'Texte lien entete 1',
			'fieldtype' => 'text_id',
			'tab'       => 'email',
			'balise_name' => "header_1_txt",
			'legend' => 'MIGC_BALISES_[header_1_txt]_HERE',
    },
    '531/id_textid_balise_header_1_link'=> 
    {
			'title'     => 'Lien entete 1',
			'fieldtype' => 'text_id',
			'tab'       => 'email',
			'balise_name' => "header_1_link",
			'legend' => 'MIGC_BALISES_[header_1_link]_HERE',
    },
    '532/id_textid_balise_header_2_txt'=> 
    {
			'title'     => 'Texte lien entete 2',
			'fieldtype' => 'text_id',
			'tab'       => 'email',
			'balise_name' => "header_2_txt",
			'legend' => 'MIGC_BALISES_[header_2_txt]_HERE',
    },
    '533/id_textid_balise_header_2_link'=> 
    {
			'title'     => 'Lien entete 2',
			'fieldtype' => 'text_id',
			'tab'       => 'email',
			'balise_name' => "header_2_link",
			'legend' => 'MIGC_BALISES_[header_2_link]_HERE',
    },
    '534/id_textid_balise_header_3_txt'=> 
    {
			'title'     => 'Texte lien entete 3',
			'fieldtype' => 'text_id',
			'tab'       => 'email',
			'balise_name' => "header_3_txt",
			'legend' => 'MIGC_BALISES_[header_3_txt]_HERE',
    },
    '535/id_textid_balise_header_3_link'=> 
    {
			'title'     => 'Lien entete 3',
			'fieldtype' => 'text_id',
			'tab'       => 'email',
			'balise_name' => "header_3_link",
			'legend' => 'MIGC_BALISES_[header_3_link]_HERE',
    },
    '536/id_textid_balise_header_4_txt'=> 
    {
			'title'     => 'Texte lien entete 4',
			'fieldtype' => 'text_id',
			'tab'       => 'email',
			'balise_name' => "header_4_txt",
			'legend' => 'MIGC_BALISES_[header_4_txt]_HERE',
    },
    '537/id_textid_balise_header_4_link'=> 
    {
			'title'     => 'Lien entete 4',
			'fieldtype' => 'text_id',
			'tab'       => 'email',
			'balise_name' => "header_4_link",
			'legend' => 'MIGC_BALISES_[header_4_link]_HERE',
    },
    '538/id_textid_balise_header_5_txt'=> 
    {
			'title'     => 'Texte lien entete 5',
			'fieldtype' => 'text_id',
			'tab'       => 'email',
			'balise_name' => "header_5_txt",
			'legend' => 'MIGC_BALISES_[header_5_txt]_HERE',
    },
    '539/id_textid_balise_header_5_link'=> 
    {
			'title'     => 'Lien entete 5',
			'fieldtype' => 'text_id',
			'tab'       => 'email',
			'balise_name' => "header_5_link",
			'legend' => 'MIGC_BALISES_[header_5_link]_HERE',
    },


	);


	return \%dm_dfl;
	
}

##################################################################################
# get_migcms_site_setup
##################################################################################
sub get_site_setup
{
    my %migcms_site_setup = select_table($dbh,"migcms_setup");
    if($migcms_site_setup{id} > 0)
    {
        return \%migcms_site_setup;
    }

}

##################################################################
################## get_migcms_site_emails_header #################
##################################################################
# Params: title => Titre du mail
# 				lg => lg
#              
# Return: Le header des mails envoyé via le site
##################################################################
sub get_migcms_site_emails_header
{
	my %d = %{$_[0]};

  my $title = $d{title};
 	my $lg = $d{lg};

  my %balises = %{get_balises($dbh,$lg)};
  my %site_setup = %{get_site_setup()};

  if($site_setup{custom_site_email_header_func} ne "")
  {
  	my $func =  'def_handmade::'.$site_setup{custom_site_email_header_func};
  	return &$func();
  }

   # Récupération de l'image du logo
    # Récupération de l'image du logo
    # my %logo = sql_line({dbh=>$dbh, table=>"migcms_linked_files", where=>"token = '$site_setup{id_pic_logo_header}'"});
  	my %logo = sql_line({debug=>0,debug_results=>0,table=>'migcms_linked_files',where=>"table_name='migcms_setup' AND token='$site_setup{id}' AND table_field='id_pic_logo_email' ",limit=>"1",ordby=>"ordby"});

   	my $logo_path = $logo{file_dir};
   	$logo_path =~ s/\.\.\///g;
   	$logo_path = $config{fullurl}."/".$logo_path."/".$logo{full}.$logo{ext};


  my $charset = $_[3] || "iso-8859-1";

  my $social_links;
  if($balises{url_facebook} ne "")
  {
    $social_links .= <<"HTML";
      &nbsp;<a href="$balises{url_facebook}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$site_setup{color_bandeau};"><img src="$config{fullurl}/skin/newsletter/facebook.png" alt="Facebook" width="13" height="23" /></a>&nbsp;
HTML
  }
  if($balises{url_twitter} ne "")
  {
    $social_links .= <<"HTML";
      &nbsp;<a href="$balises{url_twitter}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$site_setup{color_bandeau};"><img src="$config{fullurl}/skin/newsletter/twitter.png" alt="Twitter" width="20" height="23" /></a>&nbsp;
HTML
  }
  if($balises{url_googleplus} ne "")
  {
    $social_links .= <<"HTML";
      &nbsp;<a href="$balises{url_googleplus}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$site_setup{color_bandeau};"><img src="$config{fullurl}/skin/newsletter/googleplus.png" alt="Google+" width="23" height="23" /></a>&nbsp;
HTML
  }

  my $entete;
  if($balises{header_1_textid} ne "" || $balises{header_2_textid} ne "" || $balises{header_3_textid} ne "" || $balises{header_4_textid} ne "" || $balises{header_5_textid} ne "")
  {
	  $entete = <<"HTML";
	  	<table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800 linkcategory" style="border-top:1px solid #e5e5e5;border-bottom:1px solid #e5e5e5;">
	      <tr>
	        <td width="45" align="center" class="td45"></td>
	        <td width="710" height="32" align="center" class="td710">
	          &nbsp;&nbsp;<a href="$balises{header_1_link_textid}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$balises{color_entete_links};">$balises{header_1_textid}</a>&nbsp;&nbsp;
	          &nbsp;&nbsp;<a href="$balises{header_2_link_textid}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$balises{color_entete_links};">$balises{header_2_textid}</a>&nbsp;&nbsp;
	          &nbsp;&nbsp;<a href="$balises{header_3_link_textid}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$balises{color_entete_links};">$balises{header_3_textid}</a>&nbsp;&nbsp;
	          &nbsp;&nbsp;<a href="$balises{header_4_link_textid}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$balises{color_entete_links};">$balises{header_4_textid}</a>&nbsp;&nbsp;
	          &nbsp;&nbsp;<a href="$balises{header_5_link_textid}" target="_blank" style="text-decoration:none;text-transform:uppercase;color:$balises{color_entete_links};">$balises{header_5_textid}</a>&nbsp;&nbsp;
	        </td>
	        <td width="45" align="center" class="td45"></td>
	      </tr>
	    </table>
HTML

  }



  my $header = <<"HTML";
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title>$title</title>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="Content-Type" content="text/html; charset=$charset" />
    </head>
    <body bgcolor="#ffffff" style="font-family:arial,sans-serif;color:$site_setup{color_content};font-size:14px;line-height:20px;background:#e5e5e5;-webkit-text-size-adjust:none;">

    <style type="text/css">
    * {
    padding : 0px;
    margin : 0px;
    }

    body {
    font-family : arial,sans-serif;
    color : $site_setup{color_content};
    font-size : 14px;
    line-height : 20px;
    background : #e5e5e5;
    -webkit-text-size-adjust : none;
    }

    a {
    border : 0px;
    color : $site_setup{color_content_link};
    }

    a:hover {
    color : $site_setup{color_content_link};
    }

    img {
    border : 0px;
    }

    a img {
    border  :0px;
    }

    .td25pc {
    padding : 5px;
    }

    .td25pc img {
    max-width : 100%;
    height : auto;
    }

    \@media only screen and (max-width: 600px) { 

      *[class].table800, *[class].td800, *[class].img800, *[class].pub { width:100% !important; height:auto; }
      *[class].td45 { width:5% !important; }
      *[class].td710 { width:90% !important; }
      *[class].table710 { width:100% !important; height:auto; }
      *[class].tdleftcontent { width : 100% !important; display: table-header-group !important; }
      *[class].td40 { width : 100% !important; display: table-header-group !important; }
      *[class].tdrightcontent { width : 100% !important; display: table-header-group !important; }
      *[class].fancybox { width : 100%; height : auto; }
      *[class].table100pc { width:100% !important; height:auto; }
      *[class].td25pc { width : 100% !important; display: table-header-group !important; }
      *[class].menulink { display : block !important; }
      *[class].maintitle { font-size:25px !important; line-height:30px !important; margin:0px; }
      *[class].linkcategory { display : none !important; }
      *[class].hidden-sm  { display : none !important; }
    } 

    </style>

    <table width="100%" border="0" cellpadding="0" cellspacing="0"><tr><td align="center">
      <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800" bgcolor="white">
        <tr>
          <td width="800" align="center" class="td800">
          
            <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800" bgcolor="$site_setup{color_bandeau_bg}">
              <tr>
                <td width="45" align="center" class="td45"></td>
                <td align="center" class="tdleftcontent" valign="middle" height="52" height="52">
                  <span style="color:$site_setup{color_bandeau};">Service client : $balises{phone} - <a href="mailto:$balises{email_1}" style="color:$site_setup{color_bandeau};">$balises{email_1}</a></span>
                </td>
                <td width="40" align="center" class="td40 hidden-sm" valign="top">&nbsp;</td>
                <td align="right" class="tdrightcontent hidden-sm" valign="middle" height="52">
                  $social_links                
                </td>
                <td width="45" align="center" class="td45"></td>
              </tr>
            </table>
            <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
              <tr>
                <td width="800" height="32" align="left" colspan="3">&nbsp;</td>
              </tr>
            </table>
            
            $entete

            <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
            <tr>
              <td class="td40" height="40" valign="top" colspan="3">&nbsp;</td>
            </tr>
            <tr>
            	 	<td width="45" align="center" class="td45"></td>
	              <td width="710" align="left" class="tdleftcontent" valign="top">
	                <a href="$config{fullurl}" target="_blank"><img src="$logo_path" width="$logo{width_medium}" height="$logo{height_medium}" alt="$balises{company}" /></a>
	              </td>
               	<td width="45" align="center" class="td45"></td>              
            </tr>
          </table>
HTML

  return $header;
}

##################################################################
################## get_migcms_site_emails_footer #################
##################################################################
# Params: lg => $lg
#              
# Return: Le footer des mails du site
##################################################################
sub get_migcms_site_emails_footer
{

	my %d = %{$_[0]};

 	my $lg = $d{lg};

  my %balises = %{get_balises($dbh,$lg)};
  my %site_setup = %{get_site_setup()};

  if($site_setup{custom_site_email_footer_func} ne "")
  {
  	my $func =  'def_handmade::'.$site_setup{custom_site_email_footer_func};
  	return &$func();
  }

  %emails_config = %{$_[0]};
  my %eshop_setup = %{$_[1]};

  my $footer = <<"HTML";
    <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800">
      <tr>
        <td width="800" height="32" align="left" colspan="3">&nbsp;</td>
      </tr>
    </table>

    <table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table800" bgcolor="$site_setup{color_bandeau_bg}">
      <tr>
        <td width="45" align="center" class="td45"></td>
        <td width="710" height="52" align="center" class="td710">
          <span style="color:$site_setup{color_bandeau};">$balises{company} - $balises{address} $balises{number}, $balises{zip} $balises{city} ($balises{country})</span>
        </td>
        <td width="45" align="center" class="td45"></td>
      </tr>
    </table>
          
          </td>
        </tr>
      </table>


      </body>
      </html>
HTML
}

sub get_migcms_site_email_content
{
	my %d = %{$_[0]};

	my %site_setup = %{get_site_setup()};


	my $content = $d{content};

	if($site_setup{custom_site_email_content_func} ne "")
  {
  	my $func =  'def_handmade::'.$site_setup{custom_site_email_content_func};
  	return &$func({content=>$content});
  }

	my $content = <<"HTML";
		<table width="800" border="0" cellpadding="0" cellspacing="0" align="center" class="table710">
			<tr>
        <td class="td40" height="40" valign="top">&nbsp;</td>
      </tr>
      <tr>
        <td width="45" align="center" class="td45"></td>
        <td align="left" class="tdcentercontent" valign="top">
          $content
        </td>
        <td width="45" align="center" class="td45"></td>
      </tr>
      <tr>
        <td class="td40" height="40" valign="top">&nbsp;</td>
      </tr>
    </table>
HTML

  return $content;
}

1;


