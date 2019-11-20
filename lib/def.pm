#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Package de la librairie
package def;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@ISA = qw(Exporter);	#Permet l'export
@EXPORT = qw(
             %config
             $cgi
             $dbh
             $dbh2
            );
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Variables globales
$config{rewrite_ssl} 		= "y";
if ($config{rewrite_ssl} eq "y") { $config{rewrite_protocol} = "https" }
else {
	$config{rewrite_protocol} = "http"
}
$config{rewrite_redir_301}	= "y";

$config{use_http}		   = "y";

############# REWRITE #############
$config{rewrite_dns}       = "www.certigreen.be";
$config{rewrite_subdns}    = "";
$config{rewrite_directory} = "";
$config{directory_path}    = "/var/www/vhosts/certigreen.fw.be/httpdocs2";
$config{rewrite_host}      = $config{rewrite_subdns}.$config{rewrite_dns};
$config{rewrite_base}      = $config{rewrite_directory}."/";

############# DATABASE #############
$config{projectname}       = "certigreen_2018";
$config{db_name}           = "DBI:mysql:$config{projectname}";
$config{db_user}           = "dbcertigreen";
$config{db_passwd}         = "aTri952poldajjda-";

############# PATH #############
$config{root_path}           = $config{directory_path};
$config{baseurl}             = $config{rewrite_directory};
$config{fullurl}             = $config{rewrite_protocol}."://".$config{rewrite_subdns}.$config{rewrite_dns}.$config{baseurl};
$config{default_fm_root}     = $config{directory_path}."/usr";
$config{default_fm_url}      = $config{rewrite_protocol}."://".$config{rewrite_host}.$config{rewrite_base}."usr";
$config{default_url}         = $config{rewrite_host}."/".$config{rewrite_directory}; 
$config{rewrite_default_url} = $config{rewrite_host}.$config{rewrite_directory};

############# CACHE #############
$config{cache_prefix}     = "../cache_";
$config{dir_cache_object} = $config{cache_prefix}."object";
$config{dir_cache_detail} = $config{cache_prefix}."detail";
$config{dir_cache_search} = $config{cache_prefix}."search";
$config{cache_ext}        = "dat";

############# COOKIES #############
$config{migc4_cookie}      = $config{projectname};
$config{cookie_name}       = $config{projectname};
$config{front_cookie_name} = 'migcms_member_'.$config{projectname};

############# RECAPTCHA #############
$config{captcha_public_key} = "6Lct3R0TAAAAAC1Z3ac29FE6Vd3_h5j5LA97x-hi";
$config{captcha_secret_key} = "6Lct3R0TAAAAAEsUavVa9NCRY_jzAl_2UXpiTkr4";

############# OTHERS #############
$config{maplg}                     = (1=>lg1);
$config{filtrer_non_valides}       = 0;
$config{do_not_upload_pic_in_pics} = 'y';
$config{use_sys}                   = 'n';
$config{use_securepwd}             = 'y';



my $version = '';
open(FILE, $config{directory_path}.'/cgi-bin/version.txt');
while (<FILE>)
{	$version.= $_; }
close(FILE);
if($version eq '')
{
    $version = '3.6.1.0';
}
$config{version}          = $version;
$config{version_num}      = $config{version};
$config{version_num}      =~ s/\D//g;

$cgi = new CGI;
$dbh = DBI->connect($config{db_name},$config{db_user},$config{db_passwd}) or die("cannot connect to $config{db_name}");	#Connexion ÃÂ  la bdd
$dbh2 = $dbh;

$stmt = " SET NAMES UTF8";	
$cursor = $dbh->prepare($stmt);		
$rc = $cursor->execute;	
$stmt = " SET NAMES UTF8";	
$cursor = $dbh2->prepare($stmt);		
$rc = $cursor->execute;	

%config = %{upload_config($dbh,\%config)};	#Appel ÃÂ  la fonction upload config

$config{current_language} = $cgi->param('lg') || 1;	#RÃÂ©cupÃÂ©ration de la langue sÃÂ©lectionner sinon, affichage en franÃÂ§ais par dÃÂ©faut (table languages, le 1 reprÃÂ©sente l'id)

my %myCookie = $cgi->cookie($config{cookie_name}); 	#DÃÂ©claration d'un tableau associatif

$config{current_user} = $myCookie{userid} || 0;		#DÃÂ©claration d

$self = "";	#DÃÂ©claration de la variable self

#=============================================================================================================================================
# UPLOAD_CONFIG
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Va chercher les paramÃÂ¨tres de configurations
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# PARAMETRES :
# 1) la base de donnÃÂ©es
# 2) le tableau de configuration dans lequel les ÃÂ©lÃÂ©ments de la bdd seront enregistrÃÂ©s
#==============================================================================================================================================
sub upload_config
{
	my $dbh = $_[0]; 		#La bdd
	my %config = %{$_[1]};	#Le tableau de configuration

	if ($dbh)
	{
	    my ($stmt,$cursor,$rc);	#DÃÂ©claration
	 
	    $stmt = "select DISTINCT varname, varvalue FROM config";	#RequÃÂªte
	    $cursor = $dbh->prepare($stmt);		#Initialisation de la requÃÂªte
	    $rc = $cursor->execute;		#RÃÂ©cupÃÂ©ration du rÃÂ©sultat de la requÃÂªte
		
	    if (!defined $rc) { die("error execute : $DBI::errstr [$stmt]\n"); }	#Si pas de rÃÂ©sultat, affichage de l'erreur
	 
	    my ($name, $value);		#DÃÂ©claration
	 
	    $cursor->bind_columns(\$name,\$value);	#Association des colonnes aux variables $name et $value
		
	    while ($cursor->fetch())
	    {
       $name =~ s/\s*//g;
			$config{$name} = $value; 	#Association de la valeur ÃÂ  son nom
	    }
	    
		$cursor->finish();
	}



	return (\%config);	#Retour de la rÃÂ©fÃÂ©rence du tableau
}

1;		#Retourne 1 pour dÃÂ©finir le fichier en tant que librairie

