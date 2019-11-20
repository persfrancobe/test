#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#Package de la librairie
package tools;
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
@ISA = qw(Exporter);	#Permet l'export
@EXPORT = qw(
get_url
       sql_line
       sql_lines
       sql_radios
       sql_listbox       
       sql_set_data
       suicide
	   log_debug
	   debug_log
	   log_debut
			 insert_file
			 to_ddmmyyyy
			 to_ansi_date
			 http_redirect
			 get_quoted
			 upload_image
			 upload_file
			 thumbnailize
			 thumbnailize_fixed
			 get_describe
			 sql_update_or_insert
			 split_date
       split_time
			 get_file
       clean_url
			 send_mail
			 send_mail_with_attachment
			 inserth_db
			 updateh_db
			 execstmt
			 makeselecth	       
			 make_error
			 makebool
			 gethash
			 log_to
			 get_datecontrol
			 makeyearslist
			 dow
			 checkdate
			 getmaxday
			 is_bissextile
			 copy_image
			 makesortedselecth
			 makenumsortedselecth
			 remove_accents_from		 
			 make_url
			 make_pic
			 is_in
			 get_obj_hash_from_db
			 get_script
			 get_hidden_params
			 wfw_exception
			 
			 wfw_no_access
			 pdf_text
			 trim
			 ltrim
			 rtrim
			 make_xhtml
			 unmake_xhtml
			 clean_filename
       read_table
       select_table
       get_table
       get_table_hash
       get_var
       ajax_get_var
       ajax_get_last
       insert_table
       update_table
       truncate_table
       get_textcontent
       see
       dumper
       get_listbox_from_table
       split_datetime
       get_hash_from_config
       encode_html 
       is_int
       get_quoted_deutf8
       get_param_deutf8
       create_token

       get_shopcattypes
       get_shopcattypes_display
       is_shopobj_linked
       shop_lvls_assoc

       remove_param_from_url
       
       serialize_hash_params
       
       sql_get_row_from_id
       sql_get_row_from_params
       sql_get_rows_array
       
       str_replace       
       see_array
       get_param_name
       cgi_redirect
       ajax_redirect
       
       get_next_ordby
       
       get_languages_ids
       
       %GLOBAL_TEMPLATES
       $global_templates_loaded 
       $use_global_templates

       %GLOBAL_TEXTCONTENTS
       $global_textcontents_loaded
       $use_global_textcontents

       %GLOBAL_SITETXT
       $global_sitetxt_loaded
       $use_global_sitetxt


       %shop_lvls_assoc
       get_hash_from_fields
       write_file
       reset_file
       write_htaccess
       
       create_manifest
	   fb_timeout
	   delete_text

	   get_alert
	   is_human_recaptcha
	   get_sql_listbox
	   get_traduction
	   is_page_protected
	   %urlrew 
	   
	   incremente_ordby
	   quoteh
	   build_form
	   add_denomination
	   compute_sql_date
	   
);
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use def;            

use Data::Dumper;
use JSON::XS; 
use Mail::Sender;
use Encode qw/encode decode/;
use CGI::Carp qw(fatalsToBrowser set_message);
use MIME::Lite;
use Encode;
use HTML::Entities;

%urlrew = 
(
	'member_logout_db' 
	=> 
	{
		1 => 'fr/membres/deconnexion',
		3 => 'nl/members/uitloggen'
	}
	,
	'member_login_token_page' 
	=> 
	{
		1 => 'fr/membres/acces-page/',
		3 => 'nl/members/page-access/'
	}
);

%GLOBAL_TEMPLATES = ();
$global_templates_loaded = 0;
%GLOBAL_TEXTCONTENTS = ();
$global_textcontents_loaded = 0;
%shop_lvls_assoc = ();
$use_global_textcontents = 1;
$use_global_templates = 1;
%GLOBAL_SITETXT = ();
$global_sitetxt_loaded = 0;
$use_global_sitetxt = 1;
sub get_param_name
{
    my $value=$_[0];
    
    my @methodes=get_table($dbh,"methodes");
#     see_array(\@methodes);
    for($i=0;$i<$#methodes+1;$i++)
    {
        my %cfg = eval("%cfg = ($methodes[$i]{params});");
#         see(\%cfg);
        if($cfg{name} eq $value)
        {
            return $methodes[$i];
        }
    }
    return ();
}

#*******************************************************************************
# SERIALIZE HASH PARAMS
#*******************************************************************************
sub serialize_hash_params
{
    my %params_r=%{$_[0]};
    
    
    my $valeur=trim(Dumper(\%params_r));
    $valeur =~ s/\'/\\\'/g;	
	  $valeur =~ s/\ÃÂÃÂ/\\\'/g;
    
    
    $valeur=~s/\$VAR1 =//g;
    $valeur=~s/\{//g;
    $valeur=~s/\}//g;
    $valeur=~s/;//g;
    $valeur =~ s/\r*\n//g;	
    
#    print "[$valeur]"; 
#     print "<br />valeur avant: $valeur";
    $valeur =~ s/\'\s+/\'/g;
    
#     print "[$valeur]";
    return $valeur;
}

#=============================================================================================================================================
# GET_FILE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub get_file
{
	my $filename = $_[0];	
	my $content = "";		
	open(FILE, $filename) or suicide ("GET_FILE : cannot open $filename");	
	while (<FILE>)		
	{	
	   $content.= $_;
	}
	close(FILE);	
	return $content	
}

#==============================================================================================================================================
# PRINT_FILE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub insert_file
{
	my $content = get_file($_[0]); 
	print "$content";}


#==============================================================================================================================================
# TO_DDMMYYY
sub to_ddmmyyyy
{
	my $datetime = $_[0] || ""; 
	my $notime = $_[1] || ""; 
  my ($date,$time) = split(/ /,$datetime);
  my ($yyyy,$mm,$dd) = split (/-/,$date); 
  my ($h,$min,$sec) = split (/:/,$time); 
  my $result="";
  
  if ($notime eq "withtime") 
  {
      $result = "$dd/$mm/$yyyy, ".$h."h".$min;
  }
  elsif ($notime eq "withtimeandbr") 
  {
      $result = "$dd/$mm/$yyyy, <br />".$h."h".$min;
  }
  else
  {
	   $result = "$dd/$mm/$yyyy";	
  }
  return $result;	
}


#==============================================================================================================================================
# TO_ANSI_DATE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# convert european format (DD/MM/YYYY) to ISO date (YYYY-MM-DD)
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : string containing the date in the european format (DD/MM/YYYY)
# OUTPUT PARAMETERS
#  0 : a tring in the ANSI format (YYYY-MM-DD)
#==============================================================================================================================================
	sub to_ansi_date
{
	my $date = $_[0];	#Date ÃÂÃÂ convertir
	
	my ($dd,$mm,$yyyy) = split (/\//,$date);	#SÃÂÃÂparation de la date
	
	$date = "$yyyy-$mm-$dd";	#Reformattage de la date
	
	return $date;	#Renvoit de la date au bon format
}

#==============================================================================================================================================
# SUICIDE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# when an error occurs, display a nice message to the users
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : string containing the error message
# OUTPUT PARAMETERS
#  none (exit of the program)
#==============================================================================================================================================
sub suicide
{
	my $msg = $_[0]; 
	
	
use Carp;	
my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller();
my $stack = Carp::longmess("Stack backtrace :");
$stack =~ s/\r*\n/<br>/g;		
# $package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask
# <hr />
# $stack	
  
  
	
	#Construction du message d'erreur
	print <<"EOM";
<!DOCTYPE html>
<html lang="fr,en" id="mig-error-html">
<head>
	<meta charset="utf-8">
	<title>Error</title>
	<meta name="robots" content="none">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<meta name="viewport" content="width=device-width, initial-scale=1">

<style type="text/css">
* {
margin : 0px;
padding : 0px;
}

html#mig-error-html {
min-height : 100%;
height : auto;
height : 100%;
}

body#mig-error {
height : 100%;
font-family : arial;
color : black;
background : url('../mig_skin/img/error_help.jpg') no-repeat;
background-size: 100% 100%;
}

div#mig-error-page {
position : relative;
padding : 20px;
}

div#mig-error-page-content {
width : auto;
max-width : 570px;
background : white;
background : rgba(255,255,255,0.8);
border-radius : 15px;
padding : 20px;
}

div#mig-error-page-content p {
font-size : 8pt;
padding : 0px 0px 12px 0px;
margin : 0px 0px 12px 0px;
color : #272727;
background : url('../mig_skin/img/error_help_separator.png') no-repeat bottom left;
font-weight:bold;
}

div#mig-error-page-content p#mig-error-en {
background : none;
margin : 0px;
}

div#mig-error-page-content p a {
color :#d7031c;
}

div#mig-error-page-content p a:hover {
text-decoration : none;
}

div#mig-error-msg {
width : auto;
max-width : 570px;
background : white;
background : rgba(255,255,255,0.8);
border-radius : 15px;
padding : 20px;
margin-top : 20px;
display : none;
}

#mig-error-page-content h1 {
font-size : 13pt;
}

#mig-error-page-content hr {
border : 0px;
border-top : 1px solid black;
margin : 10px 0px;
}
</style>
		
</head>

<body id="mig-error">

	<div id="mig-error-page">
	
		<div id="mig-error-page-content">
		
			<h1>Le système a détecté un problème technique, et ne peut continuer.</h1>
		
			<p id="mig-error-fr">Un problème technique est survenu, veuillez nous en excuser.<br />Nous vous invitons à réessayer un peu plus tard.<br />Si le problème persiste, contactez le <a HREF="mailto:support\@bugiweb.com">support technique</a>.<br />Merci !</p>
		
			<h1>The system has detected a technical problem, and cannot continue.</h1>
		
			<p id="mig-error-en">A technical problem occurred, we are sorry for the inconvenience.<br />Please try again later.<br />If the problem occurs again, please contact the <a HREF="mailto:support\@bugiweb.com">technical support</a>.<br />Thank you !</p>
		
		</div>
EOM

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);	

	my $moment =  sprintf("[%04d-%02d-%02d:%02d:%02d:%02d]",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	
	#Construction du message d'erreur
	my $errormsg = <<"EOT";
		<div id="mig-error-msg">
			<strong>Site : </strong>$config{baseurl}<br />
			<strong>Moment : </strong>$moment<br />
			<hr />
			$msg
			<hr />
			$package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask
			<hr />
			$stack
		</div>
		
	</div>
		
</body>

</html>
EOT
	my $out_file = "../syslogs/mig_error.log";
	my $out_log = "$moment\n$msg\n$package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask\n$stack\n";
	# log_debug($out_log);

	open OUTPAGE, ">>$out_file";
	print OUTPAGE $out_log;
	close (OUTPAGE);
	
	print "$errormsg";
	
	exit();
}



sub log_debug
{
	my $commande = $_[1];
	my $filename = $_[2] || 'mig_log.log';
	my $out_file = "../syslogs/$filename";
	if($commande eq 'vide')
	{
		open OUTPAGE, ">$out_file";
		print OUTPAGE 'Début';
		close (OUTPAGE);
	}
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);	
	my $moment =  sprintf("[%04d-%02d-%02d:%02d:%02d:%02d]",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	my $out_log = "$moment\t".$_[0]."\n";
	open OUTPAGE, ">>$out_file";
	print OUTPAGE $out_log;
	close (OUTPAGE);
}	


#==============================================================================================================================================
# HTTP_REDIRECT
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# redirect to a given url
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : url to redirect to
# OUTPUT PARAMETERS
#  none
#==============================================================================================================================================
sub http_redirect
{
	 my $url = $_[0];	#url de redirection
	 
#	 print <<"EOH";
#			<script type="text/javascript">
#			function ffredirect(){ 
#				window.location="$url";
#			}
#			setTimeout("ffredirect()",10);
#			</script>
#EOH

print "<META HTTP-EQUIV=\"Refresh\" CONTENT=\"0; URL=$url\">";

}

#==============================================================================================================================================
# UPLOAD_IMAGE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# get a file from HTTP header and store it in a file
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : name of the file (generally the value of the CGI field)
#  1 : path to store the picture
# OUTPUT PARAMETERS
#  0 : name of the created file (without path)
#  1 : size of the created file      
#==============================================================================================================================================
sub upload_image
{
	my $in_filename = $_[0] || "";	#Nom du fichier
	my $upload_path = $_[1];		#Chemin absolu du fichier
	my ($size, $buff, $bytes_read, $file_url);	#DÃÂÃÂfinition variables

	if ($in_filename eq "" || $in_filename =~ /(php|js|pl|asp|cgi|swf)$/) { return ""; }	#Si pas de fichier alors retour de rien
	
	my @splitted = split(/\./,$in_filename);	#DÃÂÃÂcoupage de la chaine et mise dans le tableau @splitted
	my $ext = lc($splitted[$#splitted]);	#Copie du dernier ÃÂÃÂlÃÂÃÂment --> extension du fichier
  my $filename = $splitted[0];
  $filename = clean_filename($filename);
  
  
  
	# build unique filename from current timestamp
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time); 	#RÃÂÃÂcupÃÂÃÂration du temps actuel
	
  $year+=1900;	#Ajout de 1900 car la fonction localtime renvoit un nombre compris entre 0 et 99
	$mon++;			#Ajout de 1 car la fonction localtime renvoit un nombre compris entre 0 et 11
	
	my @chars = ( "A" .. "Z", "a" .. "z");	#DÃÂÃÂclaration d'un tableau contenant tous les caractÃÂÃÂres minuscules et majuscules entre A et Z
#	my $string = join("", @chars[ map { rand @chars } ( 1 .. 3 ) ]);	#RÃÂÃÂcupÃÂÃÂration de 3 caractÃÂÃÂres tirÃÂÃÂes au hasard dans le tableau @char

	$file_url = "$filename\_$year$mon$mday$hour$min$sec".".".$ext;	#ConcatÃÂÃÂnation pour formÃÂÃÂ le nom du fichier


	# add the target directory
	my $out_filename = $upload_path."/".$file_url;

	# upload the file contained in the CGI buffer
	if (!open(WFD,">$out_filename"))
	{
		suicide("cannot create file $out_filename $!");	#Appel ÃÂÃÂ la fonction suicide
	}

	# $in_filename = "define::$in_filename";
	while ($bytes_read = read($in_filename,$buff,2096))	#Tant qu'on peut lire le fichier
	{
	    $size += $bytes_read;	#Ajout des bytes lu
	    binmode WFD;	#DÃÂÃÂfinition du mode d'enregistrement --> binaire
	    print WFD $buff;	#Enregistrement
	}
	
	close(WFD);	#Fermeture

#	if ((stat $out_filename)[7] <= 0)	#Test pour savoir si le tÃÂÃÂlÃÂÃÂchargement ne s'est pas bien passÃÂÃÂ
#	{
#	    unlink($out_filename);	#Suppression du fichier
#	    suicide("Could not upload file: $in_filename --> $out_filename / ".$cgi->cgi_error);	#Appel ÃÂÃÂ la fonction suicide
#	}

	return ($file_url,$size);	#Retourne le nom du fichier downloader sur le serveur ainsi que sa taille
}

#==============================================================================================================================================
# UPLOAD_FILE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# alias of the "upload_image" function  
#==============================================================================================================================================
sub upload_file;
*upload_file = \&upload_image;	

#==============================================================================================================================================
# THUMBNAILIZE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# create a thumbnail of a picture  
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : name of the picture
#  1 : path of the picture
#  2 : maximum width
#  3 : maximum height
# OUTPUT PARAMETERS
#  0 : value of the parameter, with ' quoted
#==============================================================================================================================================
sub thumbnailize
{
	use GD;	
	GD::Image->trueColor(1);	

	my $filename = $_[0];	
	my $upload_path = $_[1];	
	my $th_width = $_[2];	
	my $th_height = $_[3];	
	my $th_suffix = $_[4] || "_thumb";
	if ($th_suffix eq " ") {$th_suffix = "";}
	my $other_dir = $_[5] || "";
	my $initial_th_height=$th_height;
	my $fullname = $upload_path."/".$filename;	

	my @splitted = split(/\./,$filename);	
	my $ext = pop @splitted;	
	
	my $thumb_url = join(".",@splitted)."$th_suffix.".$ext;	
    if ($other_dir ne "") {$upload_path=$other_dir;}
	my $thumb_filename = $upload_path."/".$thumb_url;	#
	
	#open new pic 
	# log_debug('thumbnailize full new: '.$fullname);
	# log_debug('thumbnailize full thumb: '.$thumb_filename);
	my $full = GD::Image->new($fullname) || log_debug("GD cannot open $fullname : [$!]");	
	my ($fu_width,$fu_height) = $full->getBounds();		
	my ($transparent) = $full->transparent();		

	my $prop = 1;	#Proportion de l'image

	if ($th_width > $fu_width) {$th_width = $fu_width;} 
	if ($th_height > $fu_height) {$th_height = $fu_height;}	

	if ($fu_width >= $th_width && $fu_height >= $th_height) 
	{
	    if ($fu_width > $fu_height) 
		{
	        $prop = $fu_width / $th_width;
	        $th_height = int ($fu_height / $prop);	
	        if($th_height > $initial_th_height)
	        {
	             my $prop2=$initial_th_height/$th_height;
	             $th_width*=$prop2;
	             $th_height=$initial_th_height;
			}	
	    } 
		else 
		{
	        $prop = $fu_height / $th_height;
	        $th_width = int ($fu_width / $prop);
	    }
	}
	
	my $thumb = GD::Image->new($th_width,$th_height,1);
	



	$thumb->saveAlpha(1);
	$thumb->alphaBlending(0);
#	$thumb->transparent($transparent);
 	$thumb->copyResampled($full,0,0,0,0,$th_width,$th_height,$fu_width,$fu_height);	#Copie de l'image
	

	my $data;
	
	if ($ext =~ /[Jj][Pp][Ee]*[Gg]/) #Test de l'extension
	{
	    $data = $thumb->jpeg(100); 
	} 
	elsif ($ext =~ /[Pp][Nn][Gg]/) 
	{

	    $data = $thumb->png; 
	}
	# log_debug("open (THUMB,>$thumb_filename);");
	open (THUMB,">$thumb_filename");	#Ouverture du fichier
	binmode THUMB;	#Mode binaire
	print THUMB $data;	#Enregistrement du fichier
	close THUMB;	#Fermeture


	return ($thumb_url,$th_width,$th_height,$fu_width,$fu_height);	#Retourne le nouveau nom du fichier et les informations sur la taille
}



#==============================================================================================================================================
# THUMBNAILIZE FIXED
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# create a thumbnail of a picture  
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : name of the picture
#  1 : path of the picture
#  2 : maximum width
#  3 : maximum height
#  4 : fix a dimension
# OUTPUT PARAMETERS
#  0 : value of the parameter, with ' quoted
#==============================================================================================================================================
sub thumbnailize_fixed
{
	use GD;		#Interface ÃÂÃÂ la librairie graphique GD
	GD::Image->trueColor(1);	#Dois utiliser les couleurs vrai. Chaque pixels de l'image sera codÃÂÃÂ sur 3 bytes et non 1.

	my $filename = $_[0];	#Nom de l'image
	my $upload_path = $_[1];	#Chemin absolu de cette image
	my $th_width = $_[2];	#Longeur maximum dÃÂÃÂsirÃÂÃÂ
	my $th_height = $_[3];	#Hauteur maximum dÃÂÃÂsirÃÂÃÂ
  my $th_suffix = $_[4] || "_thumb";
  my $fixed_dimension = $_[5] || "fixed_height";
  my $from_path = $_[6] || $filename;
  
#   print "<br />[$th_suffix][$fixed_dimension][$th_width][$th_height]";
  
  
	my $fullname = $from_path."/".$filename;	#Nom complet du fichier

	my @splitted = split(/\./,$filename);	#DÃÂÃÂcoupage du nom du fichier
	my $ext = pop @splitted;	#Copie du dernier ÃÂÃÂlÃÂÃÂment qui est l'extension du fichier
	
	my $thumb_url = join(".",@splitted)."$th_suffix.".$ext;	#Reformation du nom du fichier qui sera enregistrer sur le serveur
	my $thumb_filename = $upload_path."/".$thumb_url;	#Formation de l'adresse absolue de l'image

	my $full = GD::Image->new($fullname) || suicide("GD cannot open $fullname : [$!]");		#CrÃÂÃÂation d'une nouvelle image
	my ($fu_width,$fu_height) = $full->getBounds();		#RÃÂÃÂcupÃÂÃÂration de la longueur et de la hauteur de l'image reÃÂÃÂ¾ue en paramÃÂÃÂtre
#  my ($transparent) = $full->transparent();		#RÃÂÃÂcupÃÂÃÂration de la couleur transparente





	my $prop = 1;	#Proportion de l'image

	if($th_width > $fu_width) {$th_width = $fu_width;} #Si la longueur dÃÂÃÂsirÃÂÃÂ > grande que la longueur rÃÂÃÂelle
	if($th_height > $fu_height) {$th_height = $fu_height;}	#Si la hauteur dÃÂÃÂsirÃÂÃÂ > grande que la hauteur rÃÂÃÂelle
  
  my $decallage_x=0;
  my $decallage_y=0;
  my $thumb = GD::Image->new($th_height,$th_height);	#CrÃÂÃÂation d'une image avec les nouvelles valeurs proportionnelle
#   print "----> $fixed_dimension";
	if($fixed_dimension eq "fixed_height") 
	{
# 	  print "fu_width: $fu_width, fu_height: $fu_height";
    if($fu_width > $fu_height) 
		{
# 	        $prop = $fu_width / $fu_height;
          $prop = $fu_height / $fu_width ;		
	        $th_height = int ($prop * $th_height);
# 	        print " th width: $th_width";
	  } 
		else 
		{
	        $prop = $fu_height / $fu_width;	
	        $th_width = int ($th_height/$prop);
# 	        print " th width2: $th_width";
	  }
# 	  print "th_width: $th_width, th_height: $th_height";
	  
    $thumb = GD::Image->new($th_width,$th_height);	#CrÃÂÃÂation d'une image avec les nouvelles valeurs proportionnelle
#  	$thumb->transparent($transparent);
	$thumb->saveAlpha(1);
	$thumb->alphaBlending(0);
	  $thumb->copyResampled($full,0,0,0,0,$th_width,$th_height,$fu_width,$fu_height);
	}
	elsif($fixed_dimension eq "fixed_height_width") 
	{
    if($fu_width > $fu_height) 
		{
	        
# 	        print "[$fu_width][$fu_height][$th_width][$th_height]";
# 	        exit;
          
          $prop = $fu_width / $fu_height;	
	        $th_width = int ($prop * $th_height);
	        $thumb = GD::Image->new($th_height,$th_height);	#CrÃÂÃÂation d'une image avec les nouvelles valeurs proportionnelle
    #    	$thumb->transparent($transparent);
    	$thumb->saveAlpha(1);
	$thumb->alphaBlending(0);
	        $thumb->copyResampled($full,0,0,0,0,$th_width,$th_height,$fu_width,$fu_height);
	  } 
		else 
		{
	        $prop =  $fu_height / $fu_width;	
          $th_width=$th_height;
	        my $th_height_debordant=$prop * $th_height;
	        $thumb = GD::Image->new($th_width,$th_height);	#CrÃÂÃÂation d'une image avec les nouvelles valeurs proportionnelle
     #    	$thumb->transparent($transparent);
     	$thumb->saveAlpha(1);
	$thumb->alphaBlending(0);
	        $thumb->copyResampled($full,0,0,0,0,$th_width,$th_height_debordant,$fu_width,$fu_height);
	  }
  }
  
#   see();
#   print "fin";
#   exit;

	#Copie de l'image

	my $data;
	
	if ($ext =~ /[Jj][Pp][Ee]*[Gg]/) #Test de l'extension
	{
	    $data = $thumb->jpeg(100); 
	} 
	elsif ($ext =~ /[Pp][Nn][Gg]/) 
	{
#     $thumb->transparent($transparent);		#RÃÂÃÂcupÃÂÃÂration de la couleur transparente
	    $data = $thumb->png; 
	}

	open (THUMB,">$thumb_filename");	#Ouverture du fichier
	binmode THUMB;	#Mode binaire
	print THUMB $data;	#Enregistrement du fichier
	close THUMB;	#Fermeture

	return ($thumb_url,$th_width,$th_height,$fu_width,$fu_height);	#Retourne le nouveau nom du fichier et les informations sur la taille
}

#==============================================================================================================================================
# GET QUOTED
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# get a CGI param already "quoted" for use in SQL statements 
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : CGI parameter name
# OUTPUT PARAMETERS
#  0 : value of the parameter, with ' quoted
#==============================================================================================================================================
sub get_quoted
{
	my $var = $_[0];	
	my $val = $cgi->param($var);	
       if (ref($cgi->upload($var)) eq "IO") {
           return $cgi->upload($var);
       }
  
	my $utf8 = $_[1];
	if ($utf8 eq "utf8") {
  	  use Encode;
	    $val = decode("utf8",$val);
  }
	
	my $dontsanitize = $_[2];
  
  
  my $quote = $_[3] || 'y';

	if ($dontsanitize eq "dontsanitize") {
      $val = $val;
  } else {
      $val = sanitize_input($val);
  }
	
	if($quote eq 'y')
  {
	 $val =~ s/\'/\\\'/g;	#Traitement de la valeur
  }
  
	
	return $val;	#Retourne la valeur du paramÃÂÃÂtre citÃÂÃÂ
}

sub get_hash_from_fields
{
    my @fields_web = @{$_[0]};
    my @fields_sql = @{$_[1]};
    my %d = %{$_[2]};
    
    my %new_hash = ();
    my $counter = 0;
    foreach $field (@fields_web)
    {
        $new_hash{$fields_sql[$counter]} = get_quoted($field) || $d{$field} || "";
        $counter++;
    }
    return \%new_hash;
}


#*******************************************************************************
# sql_set_data
#*******************************************************************************
#*******************************************************************************
# sql_set_data
#*******************************************************************************
sub sql_set_data
{
	 my %d = %{$_[0]};
   $d{col_id} = $d{col_id} || 'id';
   my %data = %{$d{data}};
   
   if($d{where} ne '')
   {
        my @check_if_data_exists = sql_lines({dbh=>$d{dbh},select=>$d{select},table=>$d{table},where=>$d{where},debug=>$d{debug},debug_results=>$d{debug_results}});
        if($#check_if_data_exists > -1)
        {
              my %first_elt = %{$check_if_data_exists[0]};
              my @columns = keys(%data);
            	my ($upd,$stmt,$rc);
            
            	foreach $v (@columns) 
              {
            	    $upd.="$v = '$data{$v}',";
            	}
            	chop($upd);
            
            	$stmt = "UPDATE $d{table} SET $upd WHERE $d{col_id} = '$first_elt{$d{col_id}}'";
            	$stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
            	$stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;
            
              if($d{debug} > 0)
              {
                if($d{debug_to_log} == 1)
				{
					# log_debug($stmt);
				}
				else
				{
					see();
					print $stmt;
				}
              }
              $rc = $d{dbh}->do($stmt) || suicide("$DBI::errstr [$stmt]\n");
              return $first_elt{$d{col_id}}; 
        }
        else
        {
               my @columns = keys(%data);
            	 my ($cols,$vals,$stmt,$rc);
            
            	 foreach $v (@columns)
            	 {
            	    $cols.="$v,";
            	    $vals.="'$data{$v}',";
            	 }
            	 chop($cols);
            	 chop($vals);
            
            	 $stmt = "INSERT into $d{table} ($cols) VALUES ($vals)";
            	 $stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
            	 $stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;
            	 
            	 if($d{debug})
            	 {
                  see();
                  print $stmt;
               }
               
               $rc = $d{dbh}->do($stmt) || suicide("$DBI::errstr [$stmt]\n");
                
            	 return $d{dbh}->{mysql_insertid};
        }
   }
	 my @columns = keys(%data);
	 my ($cols,$vals,$stmt,$rc);

	 foreach $v (@columns)
	 {
	    $cols.="$v,";
	    $vals.="'$data{$v}',";
	 }
	 chop($cols);
	 chop($vals);

	 $stmt = "INSERT into $d{table} ($cols) VALUES ($vals)";
	 $stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
	 $stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;
	 
	 if($d{debug})
	 {
      see();
      print $stmt;
   }
   
   $rc = $d{dbh}->do($stmt) || suicide("$DBI::errstr [$stmt]\n");
    
	 return $d{dbh}->{mysql_insertid};
}


#send_mail (nouvelle version reprise du MAILER)
sub send_mail
{
	# get parameters
	my $adr_from = $_[0];
	my $adr_to = $_[1];
	my $subject = $_[2];
	my $body_html = $_[3];
	my $sending_id = $_[4];
	my $url_unsub = $_[5];
	my $real_from = $_[6];
	my @pjs = @{$_[7]};
	my $mailing_headers = $_[8];
	my $cc = $_[9];
	my $cci = $_[10];
 
	my $body_text = get_txt_from_html_body($body_html);

	$body_html = minify_html_body($body_html);

	#my $email = $adr_from;
	#$email=~s/[<>]//g;

	#$name = encode("MIME-B",decode_utf8($name));
	#$adr_from = $name.' <'.$email.'>'; 

	$msg = MIME::Lite->new(
		From    =>$adr_from,
		To      =>$adr_to,
		Cc      =>$cc,
		Bcc      =>$cci,
		Subject =>encode("MIME-B", decode_utf8($subject)),
		Type    =>'multipart/alternative',
	);  

	my $text = MIME::Lite->new(
		Type => 'text/plain;charset=UTF-8',
		Encoding => 'quoted-printable',
		Data => $body_text,
	);
	$text->delete("X-Mailer");
	$text->delete("Date");

	my $html = MIME::Lite->new(
		Type => 'multipart/related',		 
	);
   
	$html->attach(
		Type => 'text/html;charset=UTF-8',
		Data => $body_html,
		Encoding => 'quoted-printable',
	);
	$html->delete("X-Mailer");
	$html->delete("Date");	
	$html->attr('content-type.charset' => 'UTF-8');
   
   foreach my $pj (@pjs) {
    
        my %pj = %{$pj};
                    
        $html->attach(
            Type => $pj{type},
            Id   => $pj{id},
            Path => $pj{path},
            Filename => $pj{Filename},
        );
        
    }

	$msg->attach($text);   
	$msg->attach($html);   

	$msg->delete("X-Mailer");
	
	#my $real_from = 'migc@fw.be';
	#$msg->add("Sender" => $real_from);

	# $msg->send_by_smtp('localhost',Port=>587,SetSender=>1);   
	$msg->send_by_smtp('localhost');
}


sub send_mail_with_attachment
{
	my $adr_from = $_[0];
	my $adr_to = $_[1];
	my $subject = $_[2];
	my $body = $_[3];
	my @pjs = @{$_[4]};
	my $type = $_[5];
	my $priority = $_[6];
	my $cc = $_[7];
	my $cci = $_[8];
	my $tracking = $_[9];
	
	# my @pjs = ();
	
	# my $filename = LCS0000009999_SYS0000000006_NE00000002_000_20160613164529.pdf';
	# my $tmpfile = $config{directory_path};
	
	
	
	    

	
	
	send_mail(
				$adr_from, #email sender
				$adr_to,                                                   #email to
				$subject,                                            #subject
				$body,                                            #content
				$tracking,                                                 #mailingid + queue id
				'', #unsub url
				$adr_from,  #fake from ex: noreply@selion.be
				\@pjs,                                                  # array of attachments
				'',
				$cc,
				$cci
			);
	
	
	# use Mail::Sender;
	
	# if ($type eq "html") {$type = "Content-type:text/html";}	
	# else {$type = "Content-type:text/plain";}
	
	# my $from = $adr_from;
	# my $fake_from = '';
	
	# variables selon securisation
	# my $port = 25;
	# if($config{return_path_email} ne '')
	# {
		# $port = 587;
		# if($config{email_port} ne '')
		# {
			# $port = $config{email_port};
		# }
		# $from = $config{return_path_email};
		# $fake_from = $adr_from;
	# }
	
	# hash config email
	# my %config_email = 
	# (
	   # fake_from=>$fake_from,
	   # from=>$from,
	   # port=>$port,
	   # to =>$adr_to,
	   # cc =>$cc,
	   # bcc =>$cci,
	   # subject => $subject,
	   # headers => $type,
	   # b_ctype => 'text/html; charset=utf-8',
	   # msg => $body,
	   # file => $attachment,
	   # priority => 1
	# );
	
	# retirer variables inutiles si pas securisé ou pas prioritaire
	# if($config{return_path_email} eq '')
	# {
		# delete $config_email{fake_from};
		# delete $config_email{port};
	# }
	# if($priority ne '1')
	# {
		# delete $config_email{priority};
	# }
	
	# my $id_mail = 1;
    # my $loginname = $config{email_sitename}.' '.$user{id};
	# *Mail::Sender::SITE_HEADERS = \"X-Sender: $loginname\nMailID: $id_mail\nSiteID: $config{projectname}\nX-MAILER: MIGC";
	# $Mail::Sender::NO_X_MAILER = 1;
 
    # $sender = new Mail::Sender;
	# (
		# ref 
		# (
			# $sender->MailFile
			# (
			  # \%config_email
			# )
		# )
	# )
	# or die "$Mail::Sender::Error\n";
}

#==============================================================================================================================================
# INSERTH_DB
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# make an insert on a table 
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : connection handle
#  1 : SQL table to update
#  2 : hash ref to the data
# OUTPUT PARAMETERS
#  0 : the newly inserted row primary key value
#==============================================================================================================================================
sub inserth_db
{
	 my $dbh = $_[0];
	 my $table = $_[1];
	 my %row = %{$_[2]};
	 my @columns = keys(%row);
	 my ($cols,$vals,$stmt,$rc);

#    return 0 if ($#columns == -1);

	 foreach $v (@columns)
	 {
	    $cols.="$v,";
	    $vals.="'$row{$v}',";
	 }
	 chop($cols);
	 chop($vals);

	 $stmt = "INSERT into $table ($cols) VALUES ($vals)";
	 $stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
	 $stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;
   #see();
 #  print "\nSQL : [$stmt]";

# log_to("inserth_db : [$stmt]");
	 $rc = $dbh->do($stmt) || suicide("$DBI::errstr [$stmt]\n");

	 return $dbh->{mysql_insertid};
}

# sub sql_update_or_insert
# {
# 	 my $dbh = $_[0];
# 	 my $table = $_[1];
# 	 my %row = %{$_[2]};
# 	 my $key = $_[3];
# 	 my $value = $_[4];
# 
# 	 
# 	 
# 	 
# 	 #1.check if record exists
# 	 my %check=select_table($dbh,$table,"","$key='$value'");
# 	 
# # 	 see(\%check);
# # 	 print "table: $table, key: $key, value: $value"; 
#    
#    #2a. UPDATE if exists
#    if($check{$key} ne "")
# 	 {
# #          print "UPDATE";
#          
#          my @columns = keys(%row);
#       	 my ($upd,$stmt,$rc);
#       
#       	 foreach $v (@columns) {
#       	    $upd.="$v = '$row{$v}',";
#       	 }
#       	 chop($upd);
#       
#       	 $stmt = "UPDATE $table SET $upd WHERE $key = '$value'";
#       	 $stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
#       	 $stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;
#       
# #          print $stmt;
# #          exit;
#          
#       	 $dbh->do($stmt) || suicide("$DBI::errstr [$stmt]\n");
#       	 
#       	 return "update";
#    }
#    else
#    {
#          #2b. else INSERT
#          
# #          print "INSERT";
#     
#       	 my @columns = keys(%row);
#       	 my ($cols,$vals,$stmt,$rc);
#       
#       	 foreach $v (@columns)
#       	 {
#       	    $cols.="$v,";
#       	    $vals.="'$row{$v}',";
#       	 }
#       	 chop($cols);
#       	 chop($vals);
#       
#       	 $stmt = "INSERT into $table ($cols) VALUES ($vals)";
#       	 $stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
#       	 $stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;
#       	 
# #          print $stmt;
# #          exit;
#          
#          $rc = $dbh->do($stmt) || suicide("$DBI::errstr [$stmt]\n");
#           
#       	 return $dbh->{mysql_insertid};
#    }
#    
# }
sub sql_update_or_insert
{
	 my $dbh = $_[0];
	 my $table = $_[1];
	 my %row = %{$_[2]};
	 my $key = $_[3];
	 my $value = $_[4];
   my $alt_where = $_[5] || "";
   my $return_id_on_update = $_[6] || "";
   my $debug = $_[7] || 0;
	 
	 if($alt_where eq "")
	 {
      $alt_where=$key."='$value'";
   }
   else
   {
      $key='id';
   }
	 
# 	  see();
	 #1.check if record exists
	 my %check=select_table($dbh,$table,"","$alt_where","","",0);
# 	 
#  	 see(\%check);
#  	 print "table: $table, key: $key, value: $value, alt_where: $alt_where"; 
   
   
   
   
   #2a. UPDATE if exists
   if($check{$key} ne "")
	 {
#          print "UPDATE";
         
         my @columns = keys(%row);
      	 my ($upd,$stmt,$rc);
      
      	 foreach $v (@columns) {
      	    $upd.="$v = '$row{$v}',";
      	 }
      	 chop($upd);
      
      	 $stmt = "UPDATE $table SET $upd WHERE $alt_where";
      	 $stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
      	 $stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;
      
         if($debug > 0)
         {
          see();
          print $stmt;
         }
#          exit;
         
      	 $dbh->do($stmt) || suicide("$DBI::errstr [$stmt]\n");
      	 
      	 if($return_id_on_update eq 'return_id_on_update')
      	 {
      	    return $check{$key};
      	 }
      	 else
      	 {
      	   return "update";
      	 }
   }
   else
   {
         #2b. else INSERT
         
#          print "INSERT";
    
      	 my @columns = keys(%row);
      	 my ($cols,$vals,$stmt,$rc);
      
      	 foreach $v (@columns)
      	 {
      	    $cols.="$v,";
      	    $vals.="'$row{$v}',";
      	 }
      	 chop($cols);
      	 chop($vals);
      
      	 $stmt = "INSERT into $table ($cols) VALUES ($vals)";
      	 $stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
      	 $stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;
      	 
      	 if($debug)
      	 {
          see();
          print $stmt;
         }
         
         $rc = $dbh->do($stmt) || suicide("$DBI::errstr [$stmt]\n");
          
      	 return $dbh->{mysql_insertid};
   }
}

#==============================================================================================================================================
# UPDATEH_DB
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# make an update on a table row given an id
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : connection handle
#  1 : SQL table to update
#  2 : hash ref to the data
#  3 : name of the key field
#  4 : value of the key field
# OUTPUT PARAMETERS
#  none
#==============================================================================================================================================
sub updateh_db
{
	 my $dbh = $_[0];
	 my $table = $_[1];
	 my %row = %{$_[2]};
	 my $key = $_[3];
	 my $value = $_[4];

	 my @columns = keys(%row);
	 my ($upd,$stmt,$rc);

   return if ($#columns == -1);
   
    
	 foreach $v (@columns) {
	    $upd.="$v = '$row{$v}',";
	 }
	 chop($upd);

	 $stmt = "UPDATE $table SET $upd WHERE $key = '$value'";
	 $stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
	 $stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;

	 
	 $dbh->do($stmt) || suicide("$DBI::errstr [$stmt]\n");
	 
	 return $value;
}

#==============================================================================================================================================
# EXECSTMT
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# execute a SQL statement
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : connection handle
#  1 : SQL statement to execute
# OUTPUT PARAMETERS
#  none
#==============================================================================================================================================
sub execstmt
{
	 my $dbh = $_[0];
	 my $stmt = $_[1];

	 $dbh->do($stmt) || suicide ("$DBI::errstr [$stmt]\n");
}

#==============================================================================================================================================
# MAKESELECTH
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# create a listbox from a hash (unsorted)
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : hash ref to names/values
#  1 : pre-selected name/value
# OUTPUT PARAMETERS
#==============================================================================================================================================
sub makeselecth
{
	 my %list=%{$_[0]};
	 my $already = $_[1];

	 my $options = "";
	 my $selected = "";

	 my @list = sort keys(%list);

	foreach $v (@list)
	{
		if ($already eq $v)
		{
	        $selected = "selected=\"selected\"";
	    }
	    else
	    {
			$selected = "";
	    }
	    
		$options .= "<option value=\"$v\" $selected>$list{$v}</option>\n";
	}

	 return $options;
}


#==============================================================================================================================================
# MAKESORTEDSELECTH
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# create a listbox from a hash (sorted)
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : hash ref to names/values
#  1 : pre-selected name/value
# OUTPUT PARAMETERS
#  0 : the <option> tags with values
#==============================================================================================================================================
sub makesortedselecth
{
	 my %list=%{$_[0]};
	 my $already = $_[1];

	 my $options = "";
	 my $selected = "";

	 my @list = (sort { $list{$a} cmp $list{$b} } keys %list) ;

	 foreach $v (@list)
	 {
	    if ($already eq $v) 
		{
	        $selected = "selected=\"selected\"";
	    } 
		else 
		{
	        $selected = "";
	    }
	    
		$options .= "<option value=\"$v\" $selected>$list{$v}</option>\n";
	 }

	 return $options;
}


#==============================================================================================================================================
# MAKENUMSORTEDSELECTH
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# create a listbox from a hash (numerically sorted)
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : hash ref to names/values
#  1 : pre-selected name/value
# OUTPUT PARAMETERS
#  0 : the <option> tags with values
#==============================================================================================================================================
sub makenumsortedselecth
{
	 my %list=%{$_[0]};
	 my $already = $_[1];

	 my $options = "";
	 my $selected = "";

	 my @list = (sort { $a <=> $b } keys %list) ;

	 foreach $v (@list)
	 {
	    if ($already eq $v) 
		{
	        $selected = "selected=\"selected\"";
	    } 
		else 
		{
	        $selected = "";
	    }
	    
		$options .= "<option value=\"$v\" $selected>$list{$v}</option>\n";
	 }

	 return $options;
}

#==============================================================================================================================================
# MAKEDAYSLIST
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# create a listbox containing a list of days (1 to 31)
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : pre-selected day 
# OUTPUT PARAMETERS
#  0 : the <option> tags with values
#==============================================================================================================================================
sub makedayslist
{
	 my $already = $_[0];
	 my $list = "";

	 for ($i = 1; $i <= 31; $i++)
	 {
	     if ($i <10) {$j = "0".$i;}
	     else {$j=$i;}
		 
	     if ($already eq $j) 
		 {
	         $selected = "SELECTED";
	     } 
		 else 
		 {
	         $selected = "";
	     }
	     
		 $list .= "<OPTION VALUE=\"$j\" $selected>$i\n";
	 }
	 
	 return $list;
}

#==============================================================================================================================================
# MAKEYEARSLIST
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# create a listbox containing a list of years
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : pre-selected year (the start and end year are configured in global cfg)
# OUTPUT PARAMETERS
#  0 : the <option> tags with values
#==============================================================================================================================================
sub makeyearslist
{
	 my $already = $_[0];

	 if ($config{start_year} eq "") {$config{start_year} = 1900;}
	 if ($config{end_year} eq "") {$config{end_year} = 2010;}
	 
	 my $list ="";
	 for ($i = $config{start_year}; $i <= $config{end_year}; $i++) 
	 {
	     if ($already eq $i) 
		 {
	         $selected = "SELECTED";
	     } 
		 else 
		 {
	         $selected = "";
	     }
	     
		 $list .= "<OPTION VALUE=\"$i\" $selected>$i\n";
	 }
	 
	 return $list;
}

#==============================================================================================================================================
# MAKE_ERROR
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# function to display a JS alert box and then going back in browser history
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : error message to display
#  1 : nof if CGI header need to be sent before JS
# OUTPUT PARAMETERS
#  none (exit the program)
#==============================================================================================================================================
sub make_error
{
	 my $msg = $_[0];
	 my $noh = $_[1] || "";
	 my $url = $_[2];
	 
	 $msg=~s/\"/\\\"/g;
	 
	 if ($noh eq "noh") {print $cgi->header();}
	 
	 if($url ne "")
	 {
  	 	print<<"EOH";
  		<script language="javascript">
     window.location = "$url";
     		</script>
EOH
      exit;
   }
	
	print<<"EOH";
		<script language="javascript">
		alert("$msg");
		history.go(-1);
		</script>
EOH
	exit;
}

#==============================================================================================================================================
# MAKEBOOL
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# create a boolean control with checkbox
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : title to display after the checkbox
#  1 : name of the field
#  2 : y if the box is pre-checked
# OUTPUT PARAMETERS
#  0: string containing HTML field
#==============================================================================================================================================
sub makebool
{
	 my $title = $_[0];
	 my $name = $_[1];
	 my $already = $_[2];
	 my $checked = "";
	 
	 if ($already eq 'y') 
	 {
	     $checked = "CHECKED";
	 } 
	 else 
	 {
	     $checked = "";
	 }
	 
	 my $list = "<input type=\"checkbox\" name=\"$name\" value=\"y\" $checked>$title\n";

	 return $list;
}

#==============================================================================================================================================
# GET_DATACONTROL
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# create a 3-listbox control for selecting a date
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : pre-selected date (ANSI format YYYY-MM-DD). If none, take current date
#  1 : unique ID representing the control (generally incremental number)
#  2 : name of the hidden field containing the selected date for later use
# OUTPUT PARAMETERS
#  0: string containing HTML fields and JS code
#==============================================================================================================================================
sub get_datecontrol
{
	 my $origdate = $_[0] || "";	#la date prÃÂÃÂsÃÂÃÂlectionner
	 my $id = $_[1];	#id reprÃÂÃÂsentant le control
	 my $fieldname = $_[2];	#le nom du champ cachÃÂÃÂ contenant la date sÃÂÃÂlectionner pour une utilisation aprÃÂÃÂs

	 if ($origdate eq "") 
	 {
	     my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);	#prise de la date actuelle
	     $origdate = sprintf("%04d-%02d-%02d",$year+1900,$mon+1,$mday);	#Formatage de la date
	 }
	 
	 my ($yyyy,$mm,$dd) = split(/\-/,$origdate);	#DÃÂÃÂcoupage de la date
	 my $dayslist = makedayslist($dd);	#Appel ÃÂÃÂ la fonction makedayslist
	 my $monthlist = makenumsortedselecth(\%{$fwtrad{monthlist}},$mm);	#Appel ÃÂÃÂ la fonction makeselecth
	 my $yearslist = makeyearslist($yyyy); #Appel ÃÂÃÂ la fonction makeyearslist
	 
	 
	 #CrÃÂÃÂation du code html et javascript insÃÂÃÂrer dans la page
	 my $control = <<"EOH";
			<script type="text/javascript">
			<!--
			function sethiddendate$id()
			{
				 lyyyy = document.getElementsByName("yyyy_$id");
				 lmm = document.getElementsByName("mm_$id");
				 ldd = document.getElementsByName("dd_$id");

				 mydate =
				 lyyyy.item(0).options[lyyyy.item(0).options.selectedIndex].value + "-" +
				 lmm.item(0).options[lmm.item(0).options.selectedIndex].value + "-" +
				 ldd.item(0).options[ldd.item(0).options.selectedIndex].value;
				 
				 
				 document.getElementsByName("$fieldname").item(0).value = mydate;
			}
			//-->
			</script>
			<select name="dd_$id" onchange="sethiddendate$id();">$dayslist</select>
			<select name="mm_$id" onchange="sethiddendate$id();">$monthlist</select>
			<select name="yyyy_$id" onchange="sethiddendate$id();">$yearslist</select>
			<input type="hidden" name="$fieldname" value="$origdate" />
EOH

	 return $control;	#Retourne le code html
}


#==============================================================================================================================================
# GETHASH (nothing to do with marijuana :-))
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# make readable the content of any given perl hash
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : hash ref to display
# OUTPUT PARAMETERS
#  0: human readable string
#==============================================================================================================================================
sub gethash
{
	 my %hash = %{$_[0]};
	 my $txt = "";
	 my ($k,$v);
	 while ( ($k,$v) = each %hash ) { 
	 
	 if (ref($v) eq "HASH") 
	 {
		$v = gethash($v);
	 }
	 elsif (ref($v) eq "ARRAY") 
	 {
		$v = join(',',@{$v});
	 }
	 
	 $txt.= "[$k]=>[$v]<BR>";}
	 
	 return $txt;
}

#==============================================================================================================================================
# log_to
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# write any given string to the log file with current timestamp
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : text to write
# OUTPUT PARAMETERS
#  none
#==============================================================================================================================================
sub log_to
{
	 my $txt = $_[0];
	 
	 if ($config{debug_mode} eq "y") 
	 {
	     my $file = $config{logfile} || "default.log";
	     my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

	     open (LOGFILE,">>$file");
	     print LOGFILE sprintf("[%04d-%02d-%02d:%02d:%02d:%02d]",$year+1900,$mon+1,$mday,$hour,$min,$sec)."[$txt]\n";
		 close (LOGFILE);
	 }
}


#==============================================================================================================================================
# DOW
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# tells the day of week of a given date
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : day to test
#  1 : month to test
#  2 : year  to test
# OUTPUT PARAMETERS
#  0 : day of the week
#==============================================================================================================================================
sub dow
{
	 my $jour=$_[0], $mois=$_[1], $annee=$_[2];

	 my $a = int((14 - $mois) / 12);

	 my $y = $annee - $a;

	 my $m = $mois + (12*$a) - 2;

	 my $d = int( $jour + $y + int($y/4) - int($y/100) + int($y/400) + int((31*$m)/12))%7;

	 return $d;
}


#==============================================================================================================================================
# CHECKDATE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# check validity of a given date
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : day to test
#  1 : month to test
#  2 : year  to test
# OUTPUT PARAMETERS
#  0 : 1 if date is valid, otherwise 0
#==============================================================================================================================================
sub checkdate
{
	 my $jour=$_[0];
	 my $mois=$_[1];
	 my $annee=$_[2];
	 my $nbjour = "";

	 if ($annee<1600 || $annee>3000) 
	 {
	     return 0;
	 }
	 else 
	 {
	     if ($mois<1 || $mois>12) 
		 {
			 return 0;
		 } 
		 else 
		 {
	         $nbjour = getmaxday($mois,$annee);
	         
		    if ($jour<1 || $jour>$nbjour) 
			{
				 return 0;
			} 
			else 
			{
				 return 1;
			}
		 }
	 }
}

#==============================================================================================================================================
# GETMAXDAY
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# get the number of days in a month
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : month to test
#  1 : year of the month to test
# OUTPUT PARAMETERS
#  0 : number of days of the given month
#==============================================================================================================================================
sub getmaxday
{
	 my $mois = $_[0];
	 my $annee = $_[1];
	 my $nbjour = "";

	 if ($mois==4 || $mois==6 || $mois==9 || $mois==11) {
	     $nbjour=30;
	 } else {
	     if ($mois!=2) {
	         $nbjour=31;
	     } else {
		       if (is_bissextile($annee)) {
					     $nbjour=29;
					 } else {
	          	 $nbjour=28;
					 }
	     }
	 }
	 
	 return $nbjour;
}

#==============================================================================================================================================
# IS_BISSEXTILE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# tell if the given year is leap or not (bissextile = leap in french)
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : year to test
# OUTPUT PARAMETERS
#  0 : 1 if year if leap, otherwise 0
#==============================================================================================================================================
sub is_bissextile
{
	 my $annee = $_[0];

	 if (($annee%400)==0) {return 1;}
	 if (($annee%100)==0) {return 0;}
	 if (($annee%4)==0) {return 1;}
	 return 0;
}

#==============================================================================================================================================
# COPY_IMAGE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# copy a picture (= cp command), renaming it with current timestamp
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : filename to copy
#  1 : new path of the file
# OUTPUT PARAMETERS
#  0 : path to new file
#==============================================================================================================================================
sub copy_image
{
	 my $in_filename = $_[0];
	 my $upload_path = $_[1];

	 my ($file_url);

	 if ($in_filename eq "") { return ""; }
	 
	 my @splitted = split(/\./,$in_filename);
	 my $ext = $splitted[$#splitted];

	 # build unique filename from current timestamp
	 my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	 $year+=1900;
	 $mon++;
	 
	 my @chars = ( "A" .. "Z", "a" .. "z");
	 my $string = join("", @chars[ map { rand @chars } ( 1 .. 3 ) ]);

	 $file_url = "$year$mon$mday$hour$min$sec$string".".".$ext;

	 # add the target directory
	 my $out_filename = $upload_path."/".$file_url;

	 system ("cp $in_filename $out_filename");

	 return ($file_url);
}


#==============================================================================================================================================
# REMOVE_ACCENTS_FROM
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# transform a string to delete all accentuated chars (ex : ÃÂÃÂ => e)
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : string to modify
# OUTPUT PARAMETERS
#  0 : modified string
#==============================================================================================================================================
sub remove_accents_from
{
	 my $str = $_[0];
	 
	 my %accents = ("¥" => "Y", "µ" => "u", "À" => "A", "Á" => "A", 
	                "Â" => "A", "Ã" => "A", "Ä" => "A", "Å" => "A", 
	                "Æ" => "A", "Ç" => "C", "È" => "E", "É" => "E", 
	                "Ê" => "E", "Ë" => "E", "Ì" => "I", "Í" => "I", 
	                "Î" => "I", "Ï" => "I", "Ð" => "D", "Ñ" => "N", 
	                "Ò" => "O", "Ó" => "O", "Ô" => "O", "Õ" => "O", 
	                "Ö" => "O", "Ø" => "O", "Ù" => "U", "Ú" => "U", 
	                "Û" => "U", "Ü" => "U", "Ý" => "Y", "ß" => "s", 
	                "à" => "a", "á" => "a", "â" => "a", "ã" => "a", 
	                "ä" => "a", "å" => "a", "æ" => "a", "ç" => "c", 
	                "è" => "e", "é" => "e", "ê" => "e", "ë" => "e", 
	                "ì" => "i", "í" => "i", "î" => "i", "ï" => "i", 
	                "ð" => "o", "ñ" => "n", "ò" => "o", "ó" => "o", 
	                "ô" => "o", "õ" => "o", "ö" => "o", "ø" => "o", 
	                "ù" => "u", "ú" => "u", "û" => "u", "ü" => "u", 
	                "ý" => "y", "ÿ" => "y"
				);

	 foreach $char (keys(%accents)) {
	     $str =~ s/$char/$accents{$char}/g;
	 }

	return $str;
}

#==============================================================================================================================================
# MAKE_URL
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# transform the url and a text in a <A> tag
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : url
#  1 : text to display
# OUTPUT PARAMETERS
#  0 : string containing the a element
#==============================================================================================================================================
sub make_url
{
	 my $url = $_[0];
	 my $name = $_[1];
	 
	 return "<a href=\"$url\">$name</a>";
}

#==============================================================================================================================================
# MAKE_PIC
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# transform the url of a picture in a <IMG> tag
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : url
# OUTPUT PARAMETERS
#  0 : string containing the img element
#==============================================================================================================================================
sub make_pic
{
	 my $url = $_[0];
	 
	 return "<img src=\"$url\" />";
}

sub is_int
{
  my $value=$_[0];
  if($value =~ /^\d+$/)
  {
    return 1;
  }
  else
  {
    return 0;
  }
}
#==============================================================================================================================================
# IS_IN
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# find value in an array
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : array ref
#  1 : value to find
# OUTPUT PARAMETERS
#  0 : index of the found value in the array, otherwise -1
#==============================================================================================================================================
sub is_in
{
	 my @a = @{$_[0]};
	 my $id = $_[1];
	 my $k;

	 
	 my $found = -1;
	 
	 for ($k=0; $k<=$#a; $k++) 
	 {
	     if ($a[$k] eq $id) {$found=$k;last;}
	 }
		
	 return $found;
}


#==============================================================================================================================================
# GET_OBJ_HASH_FROM_DB
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# find any tuple (hash) from any table given the primary key
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : connection handle
#  1 : SQL table
#  2 : primary key (id)
# OUTPUT PARAMETERS
#  0 : hash ref to the tuple
#==============================================================================================================================================
sub get_obj_hash_from_db
{
	 my $dbh = $_[0] || 0;
	 my $table = $_[1] || "";
	 my $id = $_[2] || 0;
	 my %obj;
	 
	 my ($stmt,$cursor,$rc);
	 $stmt = "SELECT * FROM $table where id = $id";

	 if ($id !~ /^\d*$/) {suicide("ERROR in ID not NUMERIC : [$stmt]");}
	 
	 $cursor = $dbh->prepare($stmt);
	 $rc = $cursor->execute || suicide("SQL ERROR : $DBI::errstr [$stmt]");
	 %obj = %{$cursor->fetchrow_hashref};
	 $cursor->finish; 

	 return \%obj; 
}

#==============================================================================================================================================
# GET_SCRIPT
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# get script name from url
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : url to analyze
# OUTPUT PARAMETERS
#  0 : string containing the script's name
#==============================================================================================================================================
sub get_script
{
	 my $url = $_[0];

	 my @t1 = split(/\?/,$url);
	 my @t2 = split (/\//,$t1[0]);
	 
	 return $t2[$#t2];
}

#==============================================================================================================================================
# GET_HIDDEN_PARAMS
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# transform url parameters into hidden params for form excepted certain values
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : url to analyze
#  1 : exception list (comma separated values)
# OUTPUT PARAMETERS
#  0 : string containing <hidden> fields
#==============================================================================================================================================
sub get_hidden_params
{
	 my $url = $_[0];
	 my $except = $_[1];
	 
	 my @t1 = split(/\?/,$url);
	 my @t2 = split (/&/,$t1[1]);
	 my @texc = split (/,/,$except);

	 my ($pair,$key,$value,$hidden,$put);
	 
	 foreach $pair (@t2)
	 {
		   ($key,$value) = split(/=/,$pair);
		   foreach $except (@texc)
		   {
				if ($key eq $except) {$put = 0; last;}
				else {$put = 1;}
		   }
		   if ($put) {$hidden.="<input type=\"hidden\" name=\"$key\" value=\"$value\"/>";}
	 } 
	  
	 return $hidden; 
}

#==============================================================================================================================================
# GET_USER_INFO
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# get global config for the current user
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : connection handle
#  1 : user ID
# OUTPUT PARAMETERS
#  0 : hash ref to user
#==============================================================================================================================================
# sub get_user_info
# {
 # my $dbh=$_[0];
 # my $user = $_[1] || 0;

 # return undef if ($user < 1);
 
 # my %user = ();
 
 # my $stmt = "SELECT identity, email, id_role, id_tree_home 
             # FROM users 
            # WHERE id = $user";

 # my $cursor = $dbh->prepare($stmt);
 # $cursor->execute || wfw_exception("SQL_ERROR","error execute : $DBI::errstr [$stmt]\n");


 # my ($identity,$email,$role,$home) = $cursor->fetchrow_array;
 # $cursor->finish;
 
 # $user{id} = $user;
 # $user{identity} = $identity;
 # $user{email} = $email;
 # $user{role} = $role;
 # $user{home} = $home;
 # $user{ispro} = ($user{role}<3);
 
 # return (\%user);
# }


#==============================================================================================================================================
# PDF_TEXT
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# print text in the given PDF handle
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : PDF handle
#  1 : text
#  2 : font
#  3 : font size
#  4 : x position (0,0 is bottom left) 
#  5 : y position (0,0 is bottom left) 
#  6 : color
#  7 : align (0=left,1=center,2=right)
# OUTPUT PARAMETERS
#  none
#==============================================================================================================================================
sub pdf_text
{
 my $pdf_h = $_[0];
 my $txt = $_[1];
 
 $txt = decode("utf8",$txt);
 
 my $font = $_[2];
 my $fontsize = $_[3];
 my $x = $_[4];
 my $y = $_[5];
 my $color = $_[6];
 my $align = $_[7];
 
 if ($align) { 
     my $w = $pdf_h->getFontWidth($txt,$font,$fontsize);
     if ($align == 1) {
         $decay = int ($w/2);
     } elsif ($align == 2) {
         $decay = $w;
     }
  $x -= $decay;
 } 

 $pdf_h->drawText($txt,$font,$fontsize,$x,$y,$color);
 
}

sub trim
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
# Left trim function to remove leading whitespace
sub ltrim
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}
# Right trim function to remove trailing whitespace
sub rtrim
{
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

###############################################################################
# MAKE_XHTML
###############################################################################

sub make_xhtml
{
 my $str = $_[0];
 #return $str;
 
 $str =~ s/<STRONG>/<strong>/g;
 $str =~ s/<\/STRONG>/<\/strong>/g;
 $str =~ s/<B>/<strong>/g;
 $str =~ s/<\/B>/<\/strong>/g;
 $str =~ s/<EM>/<em>/g;
 $str =~ s/<\/EM>/<\/em>/g;
 $str =~ s/<I>/<em>/g;
 $str =~ s/<\/I>/<\/em>/g;
 $str =~ s/<UL>/<ul>/g;
 $str =~ s/<\/UL>/<\/ul>/g;
 $str =~ s/<OL>/<ol>/g;
 $str =~ s/<\/OL>/<\/ol>/g;
 $str =~ s/<LI>/<li>/g;
 $str =~ s/<\/LI>/<\/li>/g;
 $str =~ s/<P>/<p>/g;
 $str =~ s/<P align=right>/<p style="text-align:right;">/g;
 $str =~ s/<P align=center>/<p style="text-align:center;">/g;
 $str =~ s/<\/P>/<\/p>/g;
 $str =~ s/<BR>/<br \/>/g;
 $str =~ s/<U>/<u>/g;
 $str =~ s/<\/U>/<\/u>/g;

 if ($str =~ /PRIVATE/) {
 
 $str =~ s/href=\"\[(.*?)\]\">/href=\"cgi-bin\/wrapper.pl\?f\=$1\"}/g;
 
 }
 return $str;
}

sub unmake_xhtml
{
 my $str = $_[0];
 #return $str;
 
 $str =~ s/<STRONG>/<b>/g;
 $str =~ s/<\/STRONG>/<\/b>/g;
 $str =~ s/<strong>/<b>/g;
 $str =~ s/<\/strong>/<\/b>/g;
 $str =~ s/<EM>/<i>/g;
 $str =~ s/<\/EM>/<\/i>/g;
 $str =~ s/<em>/<i>/g;
 $str =~ s/<\/em>/<\/i>/g;
 
 
 $str =~ s/<p \/>/<br \/><br \/>/g;
 
 $str=~ s/\r*\n//g;
# $str =~ s/?eacute;/g;
# $str =~ s/?egrave;/g;
# $str =~ s/?agrave;/g;
# $str =~ s/?\#281;/g;
# $str =~ s//&ocirc;/g;
# $str =~ s/?icirc;/g;
# $str =~ s/?acirc;/g;
# $str =~ s//&\#367;/g;

 return $str;
}

sub clean_url
{
  my $url = $_[0];
  my $allow_slashes = $_[1] || "n";
  
  $url = trim ($url);
  if ($allow_slashes ne "y") { $url =~ s/\//-/g; }
  $url =~ s/\@/a/g;
  $url =~ s/\€/eur/g;
  $url =~ s/\#//g;
  $url =~ s/\.//g;
  $url =~ s/\™//g;
  $url =~ s/\*//g;
  
  $url = lc(clean_filename($url,'n',$allow_slashes));
  
  return $url;

}

sub clean_filename
{
 my $filename = $_[0];
 my $cut = $_[1] || 'y';
 my $allow_slashes = $_[2] || "n";
 
 if ($allow_slashes ne "y") {
     my @filepath = split(/[\/|\\]/,$filename);
     $filename = $filepath[$#filepath]; 
 }

 
 
 $filename =~ s/\'//g;
 $filename =~ s/\,//g;
 $filename =~ s/\"//g;
 $filename =~ s/\?//g;
 $filename =~ s/\(//g;
 $filename =~ s/\)//g;
# $filename =~ s/\.//g;
 $filename =~ s/\;//g;
 $filename =~ s/\&//g;
 $filename =~ s/\+//g;
 $filename =~ s/\s+/-/g;
 
 $filename = remove_accents_from($filename);

 $filename =~ s/%/-/g;
 if($cut eq 'y')
 {
    $filename = substr($filename,0,75);
 }
 return $filename;
}



#*******************************************************************************
#LIRE TABLE
#*****************************************************************************
sub read_table
{
  my $dbh_dbf     = $_[0];
  my $table       = $_[1] || "";
  my $id          = $_[2] || 0;
  my $debug       = $_[3] || 0;
  my %ligne=();
  
	my $stmt = "select * FROM $table where id='$id'";
  
  if($debug>0)
  {
    see();
    print "<br /><br />".$stmt;
  }
  if($id ne "")
  { 
   #print "\n$stmt";print "\n".join('/',caller);
  
      my $cursor = $dbh_dbf->prepare($stmt);
    	my $rc = $cursor->execute;
    	
    	if (!defined $rc) 
    	{
    		  see();
    		  print "[$stmt]";
    	    exit;   
    	}
    	 while ($ref_rec = $cursor->fetchrow_hashref()) 
    	 {
    	    %ligne = %{$ref_rec};
    	 } 
    	 $cursor->finish;
    	 return %ligne;
    }
    else
    {
        see();
        print "id non fourni";
        return "id non fourni";
    }
}

sub sql_get_row_from_id;
*sql_get_row_from_id = \&read_table;

sub debug_log;
*debug_log = \&log_debug;

sub log_debut;
*log_debut = \&log_debug;

sub get_traduction
{
	my %d = %{$_[0]};
	if(!($d{id_language} > 0 && $d{id_language} <= 10))
	{
		$d{id_language} = get_quoted('lg')
	}
	if(!($d{id_language} > 0 && $d{id_language} <= 10))
	{
		$d{id_language} = 1;
	}
	
	if($d{id} > 0)
	{
		my %txt = sql_line({debug=>$d{debug},debug_results=>$d{debug},dbh=>$dbh,table=>'txtcontents',select=>"id, lg$d{id_language} as content, lg1",where=>"id='$d{id}'"});
		if($txt{id} > 0)
		{
			if($txt{content} ne '')
			{
				return $txt{content};
			}
			else
			{
				return $txt{lg1};
			}
			
		}
	}
}

################################################################################
# GET_TEXTCONTENT
################################################################################
sub get_textcontent
{
 my $dbh = $_[0];
 my $textid = $_[1];
 my $id_language = $_[2] || $config{current_language} || 1;
 my $txt_src = $_[3];

 
	if (!defined $textid || !$textid) {return ("",1);}
 
    my $table_txt_src = 'txtcontents';
    if($txt_src ne '')
    {
        $table_txt_src = $txt_src.'_'.$table_txt_src;
    }

	my %txt = sql_line({debug=>0,debug_results=>0,dbh=>$dbh,table=>$table_txt_src,select=>"id, lg$id_language as content",where=>"id=$textid"});
	my $empty = 0;
	if($txt{id} > 0) { $empty = 1; }
	return ($txt{content},$empty); 
}


#*******************************************************************************
#SELECT TABLE
#*****************************************************************************
sub select_table
{
  my $dbh_dbf        = $_[0];
  my $table          = $_[1];
  my $selector       = $_[2] || '*';
  my $where          = $_[3];
  my $order          = $_[4];
  my $limit          = $_[5];
  my $debug          = $_[6] || 0;
  my %ligne;
  my $where_cond="";
  
  
  $where =~ s/\s+union\s*//ig;
  
  if($where ne "")
  {
      $where_cond="where $where";
  }
  
  if($order ne "")
  {
      $order="order by $order";
  }
  
  if($limit ne "")
  {
      $limit="limit $limit";
  }
  
	my $stmt = "select $selector FROM $table $where_cond $order $limit";
	
	if($debug == 1)
	{
     see();
     print "<br /><br />(( $stmt ))";
  }
  
  my $cursor = $dbh_dbf->prepare($stmt);
	$cursor->execute || suicide($stmt);
	
# 	if (!defined $rc) 
# 	{
# # 		  see();
# # 		  print join('/',caller)."[$stmt]";
# # 	    exit;
#         suicide($stmt);   
# 	}

# 	 while ($ref_rec = $cursor->fetchrow_hashref()) 
# 	 {
# 	    %ligne = %{$ref_rec};
# 	 }
   my %ligne = %{$cursor->fetchrow_hashref()}; 

   $cursor->finish; 
   
	 return %ligne;
}

sub sql_get_row_from_params;
*sql_get_row_from_params = \&select_table;


#-------------------------------------------------------------------------------
# GET_LISTBOX_FROM_TABLE
#-------------------------------------------------------------------------------
sub get_listbox_from_table
{
 my $dbh = $_[0]; 
 my $table = $_[1]; 
 my $key = $_[2]; 
 my $display = $_[3]; 
 my $where = $_[4]; 

 %hlb = ();
 if ($where ne "") {$where = "WHERE ".$where};
 
 my ($stmt,$cursor,$rc);
 
 $stmt = "select DISTINCT $key,$display FROM $table $where";
 $cursor = $dbh->prepare($stmt);
 $rc = $cursor->execute;
 if (!defined $rc) {die("error execute : $DBI::errstr [$stmt]\n");}

  my ($name,$value);
 
  $cursor->bind_columns(\$id,\$value);
  while ($cursor->fetch())
       {
  	    $hlb{$id} = $value; 
       }
      $cursor->finish;

 #$hlb{0} = "";
 return (\%hlb);
}
#*******************************************************************************
#GET TABLE
#*****************************************************************************
sub get_table
{
    my $dbh_dbf     = $_[0];
    my $table_name=$_[1];
    my $selector=$_[2] || "*";
    my $where=$_[3] || "1";
    if($where ne "")  {     $where="where $where";       }
    my $ordby=$_[4] || "";
    if($ordby ne "")  {     $ordby="order by $ordby";       }
    my $groupby=$_[5] || "";
    if($groupby ne "")  {     $groupby="group by $groupby";       }
    my $limit          = $_[6];
    if($limit ne "")    {      $limit="limit $limit";       }
    
    my $debug          = $_[7] || 0;
    
    my @table =();
    
 
    
     
  	my $stmt = "SELECT $selector FROM $table_name $where $groupby $ordby $limit";        

  	if(0 ||$debug)
  	{
  	   see();
        print "<br /><br />[".$stmt."]<br /><br />";
   	}
   	
#   	exit;
  	my $cursor = $dbh_dbf->prepare($stmt) || die("CANNOT PREPARE $stmt");
  	$cursor->execute || suicide($stmt);
#   	if (!defined $rc) 
#   	{
#   		  see();
#   		  print "[$stmt]";
#   	    exit;   
#   	}
  	 while ($ref_rec = $cursor->fetchrow_hashref()) 
  	 {
  	    
#        my %rec = %{$ref_rec}; 
#         see(\%rec);
  		  push @table,\%{$ref_rec};
  	 }
  	 $cursor->finish;
  	 return @table;
}
sub sql_get_rows_array;
*sql_get_rows_array = \&get_table;


sub encode_html
{
    my $str=$_[0];
   
#    see();
   
#    print "<br />chaine avant: $str";
    
    $str =~ s/ÃÂÃÂ/&eacute;/g;
    $str =~ s/ÃÂÃÂ/&ecirc;/g;
    $str =~ s/ÃÂÃÂ/&egrave;/g;
    $str =~ s/ÃÂÃÂ/&agrave;/g;
    $str =~ s/ÃÂÃÂ´/&iuml;/g;
    
#     print "<br />chaine apres: $str";
#       exit;
    return $str;
}

#*******************************************************************************
#GET TABLE HASH
#*******************************************************************************
sub get_table_hash
{
  my %hash=();
  my $dbh_dbf     = $_[0];
  my $table_name=$_[1];
  my $selector=$_[2] || "*";
 
  my $where=$_[3] || "1";
  if($where ne "")  {     $where="where $where";       }
  my $ordby=$_[4] || "";
  if($ordby ne "")  {     $ordby="order by $ordby";       }
  
  my $key=$_[5];
  my $value1=$_[6];
  my $value2=$_[7];
  my $value3=$_[8];
 

  my $stmt = "SELECT $selector FROM $table_name $where $ordby ";
 	#see();
  #print "<br /><br />".$stmt;
  #exit;
	
  my $cursor = $dbh_dbf->prepare($stmt);
	my $rc = $cursor->execute;
  my $type_badge,$url_pdf="";;
	if (!defined $rc) 
	{
	  see();
	  print "[$stmt]";
	  exit;   
	}	
	
	while ($ref_rec = $cursor->fetchrow_hashref()) 
	{
	   my %rec = %{$ref_rec};
     
     $hash{$rec{$key}}=$rec{$value1};
     #print $rec{$key};
     #print $rec{$value1};
     #print "<br />".$rec{id};
     
     if($value2 ne "")
     {
        $hash{$rec{$key}}.="_".$rec{$value2};
     } 
     if($value3 ne "")
     {
        $hash{$rec{$key}}.="_".$rec{$value3};
     }
         
  } 
  return %hash;
}

sub ajax_get_var
{
  my $table=get_quoted('table');
  my $var=get_quoted('var1') || get_quoted('var');
  my $var2=get_quoted('var2');
  my $id=get_quoted('id');
  
  $id=int($id);  
  my %hash=read_table($table,$id);
  
  
  if($var2 eq "") {         print($hash{$var});                   }
  else            {         print($hash{$var}." ".$hash{$var2});  }
  exit;
}


sub insert_table
{
 my $dbh_dbf     = $_[0];
 my $table = $_[1];
 my %row = %{$_[2]};
 my @columns = keys(%row);
 my ($cols,$vals,$stmt,$rc);

 foreach $v (@columns)
  {
   $cols.="$v,";
   $vals.="'$row{$v}',";
  }
 chop($cols);
 chop($vals);

 $stmt = "INSERT into $table ($cols) VALUES ($vals)";
 $stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
 $stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;
 #see();
 #print $stmt;
 #exit;
 
 $rc = $dbh_dbf->do($stmt) || die "cant execute function do";
 return $dbh_dbf->{mysql_insertid};
}

sub update_table
{
 my $dbh_dbf     = $_[0];
 my $table = $_[1];
 my %row = %{$_[2]};
 my $where          = $_[3];
 my $where_cond="";
  
  if($where ne "" )
  {
      $where="where $where";
  }

 my @columns = keys(%row);
 my ($upd,$stmt,$rc);

 foreach $v (@columns)
 {
   $upd.="$v = '$row{$v}',";
 }
 chop($upd);

 $stmt = "UPDATE $table SET $upd $where";
 $stmt =~ s/\'CURRENT_DATE\'/CURRENT_DATE/g;
 $stmt =~ s/\'NOW\(\)\'/NOW\(\)/g;
 
# log_to($stmt);
 $rc = $dbh_dbf->do($stmt);
 if (!defined $rc) {
 
see();
        print "[$stmt]";
        exit; 
 
 }
}

sub truncate_table
{
    my $dbh_dbf     = $_[0];
    my $table=$_[1];
    my $stmt = "TRUNCATE TABLE `$table` ";
    my $cursor = $dbh_dbf->prepare($stmt);
    my $rc = $cursor->execute;
    if (!defined $rc) 
    {
        see();
        print "[$stmt]";
        exit;   
    }
}
sub see
{
  print $cgi->header(-expires=>'-1d',-charset => 'utf-8');
# 
#   	my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller();
#   print "package $package,file $filename, line $line";
  
  my %hash=%{$_[0]};
  if($_[0] ne "")
  { 
      dumper(\%hash);
  }
}
                
sub dumper
{
  my %hash=%{$_[0]};
  see();
  print "<br /><br />{<pre>".Dumper(\%hash)."</pre>}<br /><br />";
}
sub see_array
{
  my @array=@{$_[0]};
  see();
  print "<br /><br />{<pre>".Dumper(\@array)."</pre>}<br /><br />";
}



sub split_datetime
{
    my $date_time=$_[0];
    my ($date1,$time1) = split(/ /,$date_time);
    my ($year1,$month1,$day1) = split(/-/,$date1);
    return ($day1,$month1,$year1);
}

sub split_date
{
    my $date_time=$_[0];
    my ($date1,$time1) = split(/ /,$date_time);
    my ($year1,$month1,$day1) = split(/\-/,$date1);
    return ($day1,$month1,$year1);
}

sub split_time
{
    my $date_time=$_[0];
    my ($date1,$time1) = split(/ /,$date_time);
    my ($heures,$minutes,$secondes) = split(/\:/,$time1);
    return ($heures,$minutes,$secondes);
}

sub get_hash_from_config
{
 my $dbh_dbf = $_[0];
 my $param = $_[1];
# my $stmt = "select varvalue FROM config where varname='$param'";
 

# my $cursor = $dbh_dbf->prepare($stmt);
# $cursor->execute || die("error execute : $DBI::errstr [$stmt]\n");
# my $hash = $cursor->fetchrow_array();
# $cursor->finish;

$hash = $config{$param};

$hash =~ s/<APOSTROPHE>/\\\'/g;




my %hash = eval ("%hash = ($hash)");  die "$@ ($param)" if $@;
#  exit;
 return %hash;
}


#==============================================================================================================================================
# GET QUOTED DEUTF8
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# get a CGI param already "quoted" for use in SQL statements 
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : CGI parameter name
# OUTPUT PARAMETERS
#  0 : value of the parameter, with ' quoted
#==============================================================================================================================================
sub get_quoted_deutf8
{
	my $var = $_[0];	#RÃÂÃÂcupÃÂÃÂration de la variable
	my $val = get_quoted($var,"utf8");	#Copie de la valeur du paramÃÂÃÂtre citÃÂÃÂ
	
	return $val;	#Retourne la valeur du paramÃÂÃÂtre citÃÂÃÂ
}


#==============================================================================================================================================
# GET PARAM DEUTF8
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# get a CGI param already "quoted" for use in SQL statements 
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : CGI parameter name
# OUTPUT PARAMETERS
#  0 : value of the parameter, with ' quoted
#==============================================================================================================================================
sub get_param_deutf8
{
	my $var = $_[0];	#RÃÂÃÂcupÃÂÃÂration de la variable
	my $val = $cgi->param($var);	#Copie de la valeur du paramÃÂÃÂtre citÃÂÃÂ
	use Encode;
	$val = decode("utf8",$val);

	$val = sanitize_input($val);
	
#	$val =~ s/\'/\\\'/g;	#Traitement de la valeur
#	$val =~ s/\ÃÂÃÂ/\\\'/g;
	
	return $val;	#Retourne la valeur du paramÃÂÃÂtre citÃÂÃÂ
}


#-------------------------------------------------------------------------------
# CREATE_TOKEN
#-------------------------------------------------------------------------------

sub create_token
{
	my $length_of_randomstring= $_[0];
  my $whatchars= $_[1] || 'aA0';
  my @chars = (); 
  if($whatchars eq 'aA0')
  {
	   @chars=('a'..'z','A'..'Z','0'..'9');
  }
  elsif($whatchars eq 'a0')
  {
	   @chars=('a'..'z','0'..'9');
  }
  elsif($whatchars eq 'a')
  {
	   @chars=('a'..'z');
  }
  elsif($whatchars eq '0')
  {
	   @chars=('0'..'9');
  }
	my $random_string;
	foreach (1..$length_of_randomstring) 
	{
		# rand @chars will generate a random 
		# number between 0 and scalar @chars
		$random_string.=$chars[rand @chars];
	}
	return $random_string;
}



###############################################################################
# GET_SHOPCATTYPES
###############################################################################
sub get_shopcattypes
{
 my $dbh=$_[0];
 my $shop = $_[1];
 my $type = $_[2];
 my $obj = $_[3];
 my $name = $_[4];
 my $table= $_[5] || "product_crit_listvalues";
 my $where=$_[6] || "id_product_crit";
 my $table_lnk_sheets_listvalues= $_[7] || "lnk_sheets_listvalues";
 my $id_sheet=$_[8] || "id_product_sheet"; 
 
 
 my ($id,$id_name);
 
  
 
 my $stmt = "SELECT id,id_textid_name FROM $table where $where='$type' ORDER BY ordby";
# print "$stmt<br>";
 my $cursor = $dbh->prepare($stmt);
 my $rc = $cursor->execute;
 if (!defined $rc) {suicide($stmt);}

 my $cpt=0;
 my $list = "";
 while (($id,$id_name) = $cursor->fetchrow_array)
  {
   my ($name,$dum) = get_textcontent($dbh,$id_name);
	 my $checked=""; my $debug = "";
	 if (is_shopobj_linked($dbh,$id,$obj,$table_lnk_sheets_listvalues,$id_sheet))
	     {
        $checked = "checked=\"checked\"";			 
        $debug = "coché";
			 }
   $list.="<li><input type=checkbox name=\"$type"."_$cpt\" id=\"$type"."_$cpt\" VALUE=\"$id\" $checked /><label for=\"$type"."_$cpt\">$name</label></li> ";
	 $cpt++;
  }
   $list.="<input type=hidden name=\"cpt_$type\" VALUE=\"$cpt\" />";
 $cursor->finish;

 return $list;
}

###############################################################################
# GET_SHOPCATTYPES
###############################################################################

sub get_shopcattypes_display
{
 my $dbh=$_[0];
 my $type = $_[1];
 my $obj = $_[2];
 my $name = $_[3];
 my $table= $_[4] || "product_crit_listvalues";
 my $where=$_[5] || "id_product_crit";
 my $table_lnk_sheets_listvalues= $_[6] || "lnk_sheets_listvalues";
 my $id_sheet=$_[7] || "id_product_sheet"; 
 
 
 my ($id,$id_name);
 my %products_cfg =get_hash_from_config($dbh,'products_cfg');
 my $tpl_display_cl=migcrender::get_template($dbh,$products_cfg{product_crits_display_line});

 
 my $stmt = "SELECT id,id_textid_name FROM $table where $where='$type' ORDER BY ordby";
# print "$stmt<br>";
 my $cursor = $dbh->prepare($stmt);
 my $rc = $cursor->execute;
 if (!defined $rc) {suicide($stmt);}

 my $cpt=0;
 my $list = "";
 ###############################################################################
 #=============================================================================#
 ###############################################################################

 if ($table_lnk_sheets_listvalues eq "lnk_sheets_listvalues") {
 
     unless (keys %shop_lvls_assoc) {
         %shop_lvls_assoc = shop_lvls_assoc($dbh);
     }  
 }
 ###############################################################################
 #=============================================================================#
 ###############################################################################

 while (($id,$id_name) = $cursor->fetchrow_array)
 {
   my ($name,$dum) = get_textcontent($dbh,$id_name);
	 my $checked=""; 
	 
   if (is_shopobj_linked($dbh,$id,$obj,$table_lnk_sheets_listvalues,$id_sheet))
	 {
      $tpl_display_cl=migcrender::get_template($dbh,$products_cfg{product_crits_display_line});
      $tpl_display_cl=~ s/<MIGC_PRODUCTS_CRIT_NAME_HERE>/$name/;
      $list.=$tpl_display_cl; 
	 }
	 $cpt++;
 }
 $cursor->finish;

 return $list;
}

###############################################################################
# IS_SHOPOBJ_LINKED
###############################################################################

sub is_shopobj_linked
{
 my $dbh=$_[0];
 my $type = $_[1];
 my $prod = $_[2];
 my $table = $_[3] || "lnk_sheets_listvalues";
 my $where = $_[4] || "id_product_sheet";


 ###############################################################################
 #=============================================================================#
 ###############################################################################
  if (keys %shop_lvls_assoc) {  
      return is_in($shop_lvls_assoc{$type},$prod);      
  } 
 ###############################################################################
 #=============================================================================#
 ###############################################################################

 my ($stmt,$cursor,$rc);
 
 $stmt = "SELECT id FROM $table where id_crit_listvalue='$type' AND  $where= '$prod'";
 #print "$stmt";
 $cursor = $dbh->prepare($stmt);
 $rc = $cursor->execute;
 if (!defined $rc) {die("error execute : $DBI::errstr [$stmt]\n");}
 my $nbres = $cursor->rows();
 return ($nbres);
}

sub shop_lvls_assoc 
{
 my $dbh = $_[0];
 my %shop_lvls_assoc = ();
 
 my @lnks = get_table($dbh,"lnk_sheets_listvalues","id_crit_listvalue,id_product_sheet");
 
 foreach $lnk (@crits) 
 {
  push (@{$shop_lvls_assoc{$lnk->{id_crit_listvalue}}},$lnk->{id_product_sheet});
 }
 	
 return %shop_lvls_assoc;
}



sub remove_param_from_url
{
 my $url = $_[0];
 my $param = $_[1];
 
 my @newparts = ();
 my @parts = split(/&/,$url);
 foreach $part (@parts) {
  if ($part !~ /^$param/) {
      push @newparts, $part;
  }
 }
 
 return join("&",@newparts);
}

#*******************************************************************************
#GET DESCRIBE
#*****************************************************************************
sub get_describe
{
    my $dbh_dbf     = $_[0];
    my $table_name=$_[1];
    my @table =();
  	my $stmt = "DESCRIBE $table_name";
  	if($debug)
  	{
        see();
   	    print "<br /><br />".$stmt."<br /><br />";
   	}
  	my $cursor = $dbh_dbf->prepare($stmt);
  	my $rc = $cursor->execute;
  	if (!defined $rc) 
  	{
  		  see();
  		  print "[$stmt]";
  	    exit;   
  	}
  	 while ($ref_rec = $cursor->fetchrow_hashref()) 
  	 {
  	    my %rec = %{$ref_rec};
  		  push @table,\%{$ref_rec};
  	 }
  	 $cursor->finish;
  	 return @table;
}


sub sanitize_input
{
 my $val = $_[0];
 
  $val =~ s/\a*//g;	#Traitement de la valeur
	$val =~ s/\e*//g;	#Traitement de la valeur
	$val =~ s/\x00*//g;	#Traitement de la valeur
	$val =~ s/\x0d*//g;	#Traitement de la valeur
	$val =~ s/\x04*//g;	#Traitement de la valeur
  
# 	$val =~ s/--//g;	#Traitement de la valeur
#	$val =~ s/\|//g;	#Traitement de la valeur
	$val =~ s/\/etc\/passwd//g;	#Traitement de la valeur
	$val =~ s/\/tmp//g;	#Traitement de la valeur
	$val =~ s/%00//g;	#Traitement de la valeur
	$val =~ s/%04//g;	#Traitement de la valeur
	$val =~ s/%0d//g;	#Traitement de la valeur
#	$val =~ s/\.\.\///g;	#Traitement de la valeur
	$val =~ s/1=1//g;	#Traitement de la valeur
	$val =~ s/\/\*//g;	#Traitement de la valeur
	$val =~ s/\*\///g;	#Traitement de la valeur
	$val =~ s/null\,//ig;	#Traitement de la valeur
	$val =~ s/select\s+//ig;	#Traitement de la valeur
	$val =~ s/delete\s+//ig;	#Traitement de la valeur
	$val =~ s/update\s+//ig;	#Traitement de la valeur
#	$val =~ s/select\(//ig;	#Traitement de la valeur
	$val =~ s/\(select//ig;	#Traitement de la valeur

#	$val =~ s/union\s+//ig;	#Traitement de la valeur
#	$val =~ s/\s+union//ig;	#Traitement de la valeur
	$val =~ s/describe\s+//ig;	#Traitement de la valeur
	
 return $val;
}

sub str_replace {
	my $replace_this = shift;
	my $with_this  = shift; 
	my $string   = shift;
	
	my $length = length($string);
	my $target = length($replace_this);
	
	for(my $i=0; $i<$length - $target + 1; $i++) {
		if(substr($string,$i,$target) eq $replace_this) {
			$string = substr($string,0,$i) . $with_this . substr($string,$i+$target);
			return $string; #Comment this if you what a global replace
		}
	}
	return $string;
}
#==============================================================================================================================================
# CGI_REDIRECT
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# redirect to a given url
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : url to redirect to
# OUTPUT PARAMETERS
#  none
#==============================================================================================================================================
sub cgi_redirect
{
    my $url = $_[0];	#url de redirection
    print $cgi->redirect("$url");
    exit;
}

#==============================================================================================================================================
# AJAX_REDIRECT
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# redirect to a given url in a div
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : url to redirect to
#  1 : id to redirect in
# OUTPUT PARAMETERS
#  none
#==============================================================================================================================================

sub ajax_redirect 
{
 my $url = $_[0];
 my $div_id = $_[1];
 
 print <<"EOH";
<script type="text/javascript" src="mig_skin/js/jquery-1.6.2.min.js"></script>
		<script type="text/javascript" src="mig_skin/js/ajaxfileupload.js"></script>
		<script type="text/javascript" src="mig_skin/js/tiny_mce/tiny_mce_popup.js"></script>

<script type="text/javascript">
\$(document).ready(function() {

//alert('[$url] in [$div_id]');

\$("#$div_id").load('$url');
});
</script>

EOH


exit;
}

sub get_next_ordby
{
    my %params = @_;
    
    my $where = $params{where} || 1;
    my %next = select_table($params{dbh},$params{table},'ordby',$where.' order by ordby desc');
    
    return $next{ordby} + 1;
}


################################################################################
# GET_LANGUAGES_IDS
################################################################################

sub get_languages_ids
{
 my $dbh = $_[0];
 my $stmt = "SELECT id FROM migcms_languages where visible = 'y' ORDER BY id";
 my $cursor = $dbh->prepare($stmt);
 my $rc = $cursor->execute;
 if (!defined $rc) {suicide($stmt);}

 my @idarray = ();
 while (($id) = $cursor->fetchrow_array)
  {
    if($id > 0)
    {
        push (@idarray,$id);
    }
  }
 $cursor->finish;

 return (@idarray);
}

sub write_file
{
 my $filename = $_[0] || "";
 my $content = $_[1] || "";
 
 open (FILE,">>$filename") || suicide("cannot open $filename : $!");
 print FILE $content;
 close FILE;
}

sub reset_file
{
 my $filename = $_[0] || "";
 
 open (FILE,">$filename") || die "cannot create $filename : $!";
 close FILE;
}

sub write_htaccess
{
 my $content = $_[0];
 my $htaccess = $config{htaccess_tmp};
 
 write_file($htaccess,$content);
 
}


sub create_manifest
{
 my $cfg_file = $config{root_path}."/skin/manifest.txt";
 my $manifest = $config{root_path}."/site.manifest";
 
 open (IN,$cfg_file) || ajax_die("cannot read $cfg_file : $!");
 open (OUT,">$manifest") || ajax_die("cannot write $manifest : $!");
 
print OUT <<"EOF";
CACHE MANIFEST

CACHE:
EOF
 
 while (<IN>) {
     my $path = $_;
     $path =~ s/\r*\n//g;
     
  
     next if ($path eq "");
     
     my @files = get_manifest_recurse_filenames($config{root_path},$path);
     
#     print Dumper(@files);
     
     foreach my $file (@files) {
         print OUT $file."\n";
     }
 }
  
 close OUT;
 close IN;
}

sub get_manifest_recurse_filenames
{
 my $root = $_[0];
 my $currdir = $_[1];
 
 my @files = ();
 
 my $fulldir = $root."/".$currdir;

 opendir(my $dh, $fulldir) || ajax_die("cannot open dir $fulldir : $!");
 my @file_list = readdir($dh);
 closedir $dh;

 foreach my $f (@file_list) { 
    if ($f ne "." && $f ne "..") {
        if (-d $fulldir."/".$f) {
            my @rec_files = get_manifest_recurse_filenames($root,$currdir."/".$f);
#            print Dumper(@rec_files); 
            push @files, @rec_files;
            
        } elsif (-f $fulldir."/".$f) {
            push @files, $currdir."/".$f;        
        }
    }
 }

 return @files; 
}


sub ajax_die
{
 my $msg = $_[0];
 
 print "ERROR : ".$msg;
 exit;
}


#*******************************************************************************
#SQL_LINES
#*******************************************************************************
sub sql_line
{
    my %d = %{$_[0]};
    $d{one_line} = 'y';
    return sql_lines(\%d);
}




#*******************************************************************************
#SQL_LINES
#*******************************************************************************
sub sql_lines
{
    my %d = %{$_[0]};
	
    my $dbh_line = $dbh;
    $d{where} = trim($d{where});
    
    $d{where} =~ s/^WHERE//g;
    $d{where} =~ s/^where//g;
    if($d{where} eq "")    {    $d{where} = " 1 ";         }
    if($d{where} ne "")    {    $d{where} = "WHERE $d{where} ";         }
    
    $d{ordby} =~ s/ORDER BY//g;
    $d{ordby} =~ s/order by//g;
    if($d{ordby} ne "")    {    $d{ordby} = "ORDER BY $d{ordby} ";      }
    
    $d{groupby} =~ s/GROUP BY//g;
    $d{groupby} =~ s/group by//g;
    if($d{groupby} ne "")  {    $d{groupby} = "GROUP BY $d{groupby} ";    }
    
    $d{limit} =~ s/LIMIT//g;
    $d{limit} =~ s/limit//g;
    if($d{limit} ne "")    {    $d{limit} = "LIMIT $d{limit} ";         }
    
    if($d{select} eq "")   {    $d{select} = "*";                       }
    if($d{dbh} ne '')      {    $dbh_line = $d{dbh};                         } 
    
    if($d{table} eq '' || $d{select} eq '' || $d{where} eq '')
    {
        see();
        print "MISSING PARAMS: table[$d{table}]select[$d{select}]where[$d{where}]";
        exit;
    }
    
    my @table =();
  	my $stmt = "SELECT $d{select} FROM $d{table} $d{where} $d{groupby} $d{ordby} $d{limit}";        
  	if($d{debug})        	
	{    
		if(1)
		{
			log_debug($stmt);
		}
		else
		{
			see();
			print $stmt;
		}          	
	
	}
   	
	#-----------------------------------------------------------------------------------
	# my $log = $stmt;
	# $log =~ s/\'/\\\'/g;
	# my %debug_log = 
	# (
		# log => $log,
		# log_table => $d{table},
		# log_where => "$d{$where}",
		# log_ordby => "$d{ordby}",
		# moment => "NOW()",
	# );
	# inserth_db($dbh,'debug_logs',\%debug_log);   
    #-----------------------------------------------------------------------------------
	
  	my $cursor = $dbh_line->prepare($stmt) || die("CANNOT PREPARE $stmt");
  	$cursor->execute || suicide($stmt);
  	
    if($d{one_line} eq 'y')
    {
        my %ligne = %{$cursor->fetchrow_hashref()};
        $cursor->finish;
        if($d{debug_results})        	
		{    
			if(1)
			{
				log_debug(Dumper(\%ligne));
			}
			else
			{
				see(\%ligne);
			}          	
		
		}
        return %ligne;
    } 
    
    while ($ref_rec = $cursor->fetchrow_hashref()) 
  	{
		push @table,\%{$ref_rec};
		if($d{debug_results})        	
		{    
			if(1)
			{
				log_debug(Dumper($ref_rec));
			}
			else
			{
				see($ref_rec);
			}          	
		
		}
  	}
  	$cursor->finish;
  	return @table;
}



#*****************************************************************************************
sub sql_radios
{
    my %d = %{$_[0]};
        
    if($d{table} ne "" && $d{value} ne "" && $d{display} ne "" && $d{name} ne "")
    {
          my $cbs=<<"EOH";
EOH
          my @records=get_table($d{dbh},$d{table},$d{select},$d{where},$d{ordby},"","",$d{debug});
          foreach my $rec (@records)
          {
              my $checked="";
              if($d{current_value} eq $rec->{$d{value}})
              {
                  $checked=<<"EOH";
                   checked = "checked"                
EOH
              }
              $cbs.=<<"EOH";
                <label>   
                  <input type="radio" name="$d{name}" $checked value="$rec->{$d{value}}" $d{required} class="$d{class}"> 
                  $rec->{$d{display}}
                </label>
EOH
          }    
          
          $cbs.=<<"EOH";
EOH
          return $cbs;
          exit;
    }
    else
    {
        return "missing mandatory data: [table:$d{table}][value:$d{value}][display:$d{display}][name:$d{name}]";
    }  
}
#*****************************************************************************************
sub sql_listbox
{
    my %d = %{$_[0]};

    my $empty_option=<<"EOH";
      <option value="">$d{empty_txt}</option>
EOH
    if($d{show_empty} ne 'y')
    {
        $empty_option="";
    }
    
    if($d{table} ne "" && $d{value} ne "" && $d{display} ne "" && $d{name} ne "")
    {
          my $listbox=<<"EOH";
              <select name="$d{name}" $d{required} id="$d{id}" class="$d{class}">
                  $empty_option             
EOH
         
          my @records=get_table($d{dbh},$d{table},$d{select},$d{where},$d{ordby},"","",$d{debug});
          
          foreach my $rec (@records)
          {
              my $selected="";
              if($d{current_value} eq $rec->{$d{value}})
              {
                  $selected=<<"EOH";
                   selected = "selected"                
EOH
              }
              if($d{translate} eq 'y')
              {
                  ($rec->{$d{display}},$dum) = get_textcontent($dbh,$rec->{$d{display}},$d{lg});
              }
              $listbox.=<<"EOH";
                  <option value="$rec->{$d{value}}" $selected>
                    $rec->{$d{display}}
                  </option>
EOH
          }    
          
          $listbox.=<<"EOH";
              </select>       
EOH
          return $listbox;
          exit;
    }
    else
    {
        return "missing mandatory data: [table:$d{table}][value:$d{value}][display:$d{display}][name:$d{name}]";
    }  
}

sub get_url
{
	my %d = %{$_[0]};
	if(!($d{id_language} > 0))
	{
		$d{id_language} = 1;
	}
	
	# if($d{nom_table} eq 'migcms_pages')
	# {
		# if(is_page_protected({debug=>0,id_page=>$d{id_table}}) ne 'page_not_protected')
		# {
			# return $config{baseurl}.'/cgi-bin/migcms_view.pl?lg='.$d{id_language}.'&id_page='.$d{id_table};
		# }
	# }	

	my %url = sql_line({dbh=>$dbh,debug=>$d{debug},debug_results=>$d{debug_results},table=>'migcms_urls',where=>"nom_table='$d{nom_table}' AND id_table='$d{id_table}' AND id_lg='$d{id_language}'"});
	return $url{url_rewriting};
}

sub fb_timeout
{
    my $FB_TIMEOUT = 5.0;
    my $timefile = "../fb.time";
    
    if ($ENV{HTTP_USER_AGENT} =~ /^facebookexternalhit/) 
    {
        if (!-e $timefile) {open (TF,">$timefile") || die("cannot create $timefile : $!");close TF;}
        open (TF,$timefile) || die("cannot read $timefile : $!");
        my @t = <TF>;
        close TF;
    
        my $t_old = $t[0];
        $t_old =~ s/\D//g;
        my $t_now = time();
    
        if ($t_now - $t_old < $FB_TIMEOUT) {
           print "Status: 503 Service Temporarily Unavailable\n";
           print "Content-Type: text/html; charset=UTF-8;\n";
           print "Retry-After: 5\r\n\r\n";
           die();
        } else {
          open (TF,">$timefile") || die("cannot write $timefile : $!");
          print TF $t_now;
          close TF; 
        }
    } 
}

sub delete_text
{
 my $dbh = $_[0];
 my $id = $_[1];
 my $table = $_[2];
 my $field = $_[3] || "id_textid_name";
 
 $stmt = "SELECT $field FROM $table WHERE id = '$id'";
 $cursor = $dbh->prepare($stmt);
 $rc = $cursor->execute;
 if (!defined $rc) {die("error execute : $DBI::errstr [$stmt]\n");}
 $cursor->bind_columns(\$id_textid_name);
 $cursor->fetch();

 $stmt = "DELETE FROM textids WHERE id = '$id_textid_name'";
 execstmt($dbh,$stmt);

 $stmt = "DELETE FROM textcontents WHERE id_textid = '$id_textid_name'";
 execstmt($dbh,$stmt);
}


##########################################################
################### is_human_recaptcha ###################
##########################################################
# Renvoit "y" si l'utilisateur est humain sinon "n"
##########################################################
sub is_human_recaptcha {

	my %d = %{$_[0]};

    my $secret_key = $d{secret_key};
    my $g_recaptcha_response = $d{g_recaptcha_response};

    # On considère que l'utilisateur est un bot
    my $i_am_human = "n";
    # Si on reçoit une valeur de recaptcha et que la secret key n'est pas vide
    if($g_recaptcha_response ne "" && $secret_key ne "")
    {
        # Requête vers Google pour savoir si la valeur est valide
        my $url = "https://www.google.com/recaptcha/api/siteverify?secret=".$secret_key."&response=".$g_recaptcha_response;

        use LWP::UserAgent 6;
        my $ua = LWP::UserAgent->new((ssl_opts => { verify_hostname => 0}));
        my $response = $ua->get($url);

        $content = decode_json ($response->decoded_content);
        %content = %{$content};
        # Si on reçoit true, le captcha est bon
        if($content{success} == 1)
        {
            # L'utilisateur est un humain
            $i_am_human = "y";
        }
        
    }

    return $i_am_human;
}


#################################################
################### get_alert ###################
#################################################
# Params : \%d
#################################################
# type : Type d'alert
# title : Titre de l'alert
# message : Contenu de l'alert
#################################################
sub get_alert 
{
    
    my %d = %{$_[0]};

    my $alert;

    if($d{display} eq "sweet")
    {
        $alert = get_alert_sweetAlert(\%d);
    }
    else
    {
        $alert = get_alert_default(\%d);
    }

    return $alert;
}

############################################################
################### get_alert_sweetAlert ###################
############################################################
# Renvoit une sweetAlert
############################################################
sub get_alert_sweetAlert
{
    my %d = %{$_[0]};

    $d{title} =~ s/\"/\\\"/g;
    $d{message} =~ s/\"/\\\"/g;

    my $content=<<"EOH";
<!DOCTYPE html>
<html lang="fr">
<head>

    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
	<meta name="robots" content="noindex, nofollow">
    <meta name="author" content="Bugiweb.com">
    
	<link rel="apple-touch-icon" sizes="57x57" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-57x57.png">
	<link rel="apple-touch-icon" sizes="60x60" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-60x60.png">
	<link rel="apple-touch-icon" sizes="72x72" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-72x72.png">
	<link rel="apple-touch-icon" sizes="76x76" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-76x76.png">
	<link rel="apple-touch-icon" sizes="114x114" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-114x114.png">
	<link rel="apple-touch-icon" sizes="120x120" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-120x120.png">
	<link rel="apple-touch-icon" sizes="144x144" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-144x144.png">
	<link rel="apple-touch-icon" sizes="152x152" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-152x152.png">
	<link rel="apple-touch-icon" sizes="180x180" href="$config{baseurl}/mig_skin/ico/apple-touch-icon-180x180.png">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-32x32.png" sizes="32x32">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-194x194.png" sizes="194x194">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-96x96.png" sizes="96x96">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/android-chrome-192x192.png" sizes="192x192">
	<link rel="icon" type="image/png" href="$config{baseurl}/mig_skin/ico/favicon-16x16.png" sizes="16x16">
	<link rel="manifest" href="$config{baseurl}/mig_skin/ico/manifest.json">
	<meta name="msapplication-TileColor" content="#ffffff">
	<meta name="msapplication-TileImage" content="$config{baseurl}/mig_skin/ico/mstile-144x144.png">
	<meta name="theme-color" content="#ffffff">
	<meta name="application-name" content="$migcms_setup{site_name}">	

    <title>Alert</title>
    
	<link href="//maxcdn.bootstrapcdn.com/font-awesome/4.1.0/css/font-awesome.min.css" rel="stylesheet">
    <link href="$config{baseurl}/html/css/style.css" rel="stylesheet">
    <link href="$config{baseurl}/html/css/style-responsive.css" rel="stylesheet">
	<link rel="stylesheet" href="$config{baseurl}/mig_skin/css/sweet-alert.css">

    <!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
    <script src="$config{baseurl}/html/js/html5shiv.js"></script>
    <script src="$config{baseurl}/html/js/respond.min.js"></script>
    <![endif]-->
</head>

<body class="login-body">

<!-- Placed js at the end of the document so the pages load faster -->
<script src="$config{baseurl}/html/js/jquery-1.10.2.min.js"></script>
<script src="$config{baseurl}/html/js/bootstrap.min.js"></script>
<script src="$config{baseurl}/html/js/modernizr.min.js"></script>
<script src="$config{baseurl}/mig_skin/js/sweet-alert.min.js"></script>

<script language="javascript">

	jQuery(document).ready(function()
	{
		sweetAlert({
			title :"$d{title}",
			text : "$d{message}",
			type : "$d{type}",
		},
		function(isConfirm)
		{			
			if('$d{goto}' == 'login')
			{
				window.location.href="$config{baseurl}/admin";
			}
			else
			{
				history.go(-1);
			}
		});
		return false;
	});
		  
</script>

</body>
</html>

EOH

    return $content;

}

#########################################################
################### get_alert_default ###################
#########################################################
# Renvoit une alert normale
#########################################################
sub get_alert_default
{

}

#=============================================================================================================================================
	# WFW_EXCEPTION
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# exception handler "ÃÂ  la Java"
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# INPUT PARAMETERS 
#  0 : return code
#  1 : information about the error
# OUTPUT PARAMETERS
#  none (exit the program)
#=============================================================================================================================================
sub wfw_exception
{
	my $rc = $_[0];	#Code de retour
	my $txt = $_[1];	#Information sur l'erreur
	
	my %errors = ( "SQL_ERROR"=>"exec_error", 
				);
	
	suicide("$rc $errors{$rc} --> $txt");	#Appel a la fonction suicide (fwtrad.pm) 
}

#-------------------------------------------------------------------------------
# get_sql_listbox
#-------------------------------------------------------------------------------
sub get_sql_listbox
{
	my %d = %{$_[0]};
	if($d{col_id} eq '')
	{
		$d{col_id} = 'id';
	}
	
	my $selected_id = $d{selected_id} || $d{selected_value};
	
	my $required = '';
	if($d{required} eq 'y' || $d{required} eq 'required')
	{
		$required = ' required ';
	}
	
	my $select = '<select class="form-control '.$d{class}.' '.$required.'" '.$required.' id="'.$d{id}.'" name="'.$d{name}.'">';
	if($d{with_blank} eq 'y')
	{
		$select .= '<option value="">'.$sitetxt{veuillez_selectionner}.'</option>';
	}
	if($d{col_rel} eq '')
	{
		$d{col_rel} = $d{col_id};
	}
	if($d{col_display} eq '')
	{
		$d{col_display} = $d{col_id};
	}
	my @lignes = sql_lines({table=>$d{table},select=>"$d{col_rel} as col_rel, $d{col_id} as col_id, $d{col_display} as col_display",where=>"$d{where}",ordby=>$d{ordby},limit=>"$d{limit}",groupby=>$d{groupby}});
	foreach $ligne (@lignes)
	{
		my %ligne = %{$ligne};
		my $selected = "";
		if($selected_id eq $ligne{col_id})
		{
			$selected = ' selected = "selected" ';
		}
		if($d{translate} == 1)
		{
			($ligne{col_display},$dum) = get_textcontent($dbh,$ligne{col_display});
		}
		$select .= '<option '.$selected.' rel="'.$ligne{col_rel}.'" value="'.$ligne{col_id}.'">'.$ligne{col_display}.'</option>';
	}
	$select .= '</select>';	
	
	return $select;
}

sub is_page_protected
{
	my %d = %{$_[0]};
	my $page_protegee = 1;
	
	if($d{id_page} > 0)
	{
		my %page = sql_line({debug=>$d{debug},debug_results=>$d{debug},table=>"migcms_pages",where=>"id='$d{id_page}'"});
		my %migcms_lnk_page_group = sql_line({debug=>$d{debug},debug_results=>$d{debug},table=>'migcms_lnk_page_groups',where=>"is_linked='y' AND id_migcms_page='$page{id}' "});
		if($migcms_lnk_page_group{id} > 0)
		{
			return 1;
		}
		else
		{
			return 'page_not_protected';
		}
	}
	else
	{
		return 0;
	}
}


sub quoteh
{
	my %hash_r = %{$_[0]};
	foreach $key (keys %hash_r)
	{
		$hash_r{$key} =~ s/\\//g;
		$hash_r{$key} =~ s/\\//g;
		$hash_r{$key} =~ s/\\//g;
		$hash_r{$key} =~ s/\'/\\\'/g;
	}
	return \%hash_r;
}

sub incremente_ordby
{
	my %d = %{$_[0]};
	my %rec =  %{$d{rec}};
	if($rec{ordby} == 0)
	{
		my $new_ordby = 1;
		my %max_ordby = sql_line({select=>"MAX(ordby) as max_ordby",table=>$d{table},where=>$d{where}});
		if($max_ordby{max_ordby} >= 1)
		{
			$new_ordby = $max_ordby{max_ordby} + 1;
		}
		$stmt = "update $d{table} set ordby = $new_ordby where id = ".$rec{id};
		execstmt($dbh,$stmt);					
	}
}

################################################################################
# build_form
################################################################################
# PARAMS : [0] => Array des champs
# 
# 	@champs = (
# 	{
# 		name     => 'country',
# 		type     => 'countries_list',
# 		label    => $sitetxt{eshop_country},
# 		required => 'required',
# 		class    =>  'google_map_country',
# 		hints    => '(BE0123456789)',
# 	},
# 
# RETURN : Champs du formulaires (String)
# ################################################################################
sub build_form
{
	my %d = %{$_[0]};

	my @champs = @{$d{fields}};
	my $lg = $d{lg};

	my $form = '';

	
	my %optionnel_txt = 
	(
		''         => ucfirst($sitetxt{eshop_optionnel}),
		'required' => '',
	);
	
	foreach my $champ (@champs)
	{
		my %champ = %{$champ};

		if($champ{do_not_add} eq "y")
		{
			next;
		}

		#valeurs par défaut--------------------------------------------
		if($champ{type} eq '')
		{
			$champ{type} = 'text';
		}
		#construction formulaire-------------------------------------------------------------
    if($champ{type} eq 'text' || $champ{type} eq 'email' || $champ{type} eq 'password')
    {
			$form .=<< "EOH";
				<div class="form-group">
						 <label class="control-label col-sm-4" for="$champs[$i]">$champ{label}: </label>
							   <div class="col-sm-8">
								<input type="$champ{type}" name="$champ{name}" $champ{required} value="$champ{valeurs}{$champ{name}}" class="$champ{class} $champ{required} form-control" /> 
								<span class="help-block">
									$optionnel_txt{$champ{required}}
									<em>$champ{hint}</em>
									$champ{suppl}
								</span>
						 </div>
				</div>
EOH
			
    }
		elsif($champ{type} eq 'delivery_google_search')
    {
			$form .=<< "EOH";
				<div class="form-group  ">
						 <label class="control-label col-sm-4" for="$champs[$i]"> </label>
							   <div class="col-sm-8">
									<small>Retrouvez votre adresse sur Google map (Facultatif):</small>
									<input type="text" class="input-xlarge  form-control" value="" name="delivery_google_autocomplete" id="delivery_google_autocomplete" />
									<span class="help-block">
								</span>
						 </div>
				</div>
EOH
			
    }
		elsif($champ{type} eq 'billing_google_search')
    {
			$form .=<< "EOH";
				<div class="form-group   ">
						 <label class="control-label col-sm-4" for="$champs[$i]"> </label>
							   <div class="col-sm-8">
									<small>Retrouvez votre adresse sur Google map (Facultatif):</small>
									<input type="text" class="input-xlarge  form-control" value=""  name="billing_google_autocomplete" id="billing_google_autocomplete" />
									<span class="help-block">
								</span>
						 </div>
				</div>
EOH
			
    }
    elsif($champ{type} eq 'countries_list')
    {
      # see(\%champ);
			#liste des pays (FR, NL, ANGLAIS sinon)
			my $col = 'en';
      if($lg == 1)
      {
        $col = "fr";
      }
      elsif($lg == 3)
      {
        $col = "nl";
      }
		
			my $country = $champ{valeurs}{$champ{name}};
			if(!($country > 0))
			{
				$country = $setup{cart_default_id_country};
			}
		
      my $listbox_countries = sql_listbox(
       {
          dbh       =>  $dbh,
          name      => $champ{name},
          select    => "c.id,$col",
          table     => 'shop_delcost_countries dc, countries c',
          where     => 'dc.isocode=c.iso',
          ordby     => $col,
          show_empty=> 'y',
          empty_txt =>  $sitetxt{eshop_veuillez},
          value     => 'id',
          current_value     => $country,
          display    => $col,
          required => 'required',
          id       => '',
          class    => 'input-xlarge required form-control',
          debug    => 0,
       }
      );
		
			$form .=<< "EOH";
				<div class="form-group">
					<label class="control-label col-sm-4">$champ{label} : </label>
					<div class="col-sm-8">
						$listbox_countries
					</div>
				</div>
EOH
			
    }
    elsif($champ{type} eq "checkbox")
    {
    	$form .=<< "EOH";
				<div class="form-group">
	        <div class="col-sm-4"></div>
					<div class="col-sm-8">
						<label class="checkbox">
							<input type="checkbox" value="$champ{value}" $champ{required} name="$champ{name}" />
							$champ{label} 
						</label>
					</div>
	      </div>
EOH
    }
    $i++;
	}

	return $form;
}


sub add_denomination
{
	my $denomination = $_[0];
	my $elt = $_[1];
	
	if($denomination ne '' && $elt ne '')
	{
		$denomination = $denomination.' ';
	}
	$denomination .= $elt;
	
	return $denomination;
}


sub compute_sql_date
{
	my $raw_date = $_[0];
	
	#03-05-2016
	#2016-05-03
	#03/05/2016
	my ($dd,$mm,$yyyy) = split (/\//,$raw_date);
	if($dd > 0 && $mm > 0 && $yyyy > 0)
	{
		if($yyyy < 100)
		{
			$yyyy += 2000;
		}
		return $yyyy.'-'.$mm.'-'.$dd;
	}
	my ($dd,$mm,$yyyy) = split (/-/,$raw_date);
	if($dd > 0 && $mm > 0 && $yyyy > 0)
	{
		my $sav_yyyy = $yyyy;
		my $sav_dd = $dd;
		if($dd > 31 && $yyyy <= 31)
		{
			$dd = $sav_yyyy;
			$yyyy = $sav_dd;
		}
		return $yyyy.'-'.$mm.'-'.$dd;
	}
	return '0000-00-00';
}

sub get_txt_from_html_body
{
	my $body_html = $_[0];

	$body_html = decode("utf8", $body_html);

	$body_html = decode_entities($body_html,'<>&');

	# use HTML::FormatText::WithLinks;

	# my $f = HTML::FormatText::WithLinks->new(
		# leftmargin => 0,
		# before_link => '',
		# after_link => ' (%l)',
		# footnote => ''
	# );

	# my $body_text = $f->parse($body_html);
	my $body_text = $body_html;

	$body_text = encode("utf8", $body_text);

	return $body_text;
}

################################################################################
# MINIFY_HTML_BODY
################################################################################

sub minify_html_body
{
	my $body_html = $_[0];
	# $body_html =~ s/ISO-8859-1/UTF-8/ig;

	# use HTML::Packer;
	# my $packer = HTML::Packer->init(); 
	# my $minified_body_html = $packer->minify( \$body_html);
	my $minified_body_html = $body_html;
	
	return $minified_body_html;
}

1;