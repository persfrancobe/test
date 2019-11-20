#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;

use fwlayout;
use fwlib;
# migc modules

         # migc translations


use migc_fb;
use data;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

###############################################################################################
####################################	CODE DU PROGRAMME		######################################
###############################################################################################
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

my %user = %{get_user_info($dbh, $config{current_user})} or wfw_no_access();
$dm_cfg{customtitle} = "Facebook";



$dm_cfg{table_width} = 800;
$dm_cfg{fieldset_width} = 950;
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_fb_publish.pl?";

$config{logfile} = "trace.log";


$dm_cfg{help_url} = "http://www.bugiweb.com";

# this script's name

$sw = $cgi->param('sw') || "default_fct";


my @fcts = qw(
    publish_data_sheet_form
    publish_data_sheet_fb
    publish_data_sheet_ok
    default_fct
		);

if (is_in(@fcts,$sw)) { 
    dm_init();
    &$sw();
    $gen_bar = get_gen_buttonbar();
    $spec_bar = get_spec_buttonbar($sw);
    $migc_output{content} .= $dm_output{content};
    $migc_output{title} = $dm_output{title}.$migc_output{title};
    
    see();
    print migc_app_layout($migc_output{content},$migc_output{title},"",$gen_bar,$spec_bar);
}
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


sub publish_data_sheet_form
{
 my $id_data_sheet = get_quoted('id_data_sheet');
 
 
 my %sheet = select_table($dbh,"data_sheets","*","id=$id_data_sheet");
 my %family = select_table($dbh,"data_families","*","id=$sheet{id_data_family}"); 

 my %f_name = select_table($dbh,"data_fields","*","id=$family{id_field_name}");  
 my %f_descr = select_table($dbh,"data_fields","*","id=$family{id_field_description}");

 my $link = "$htaccess_protocol_rewrite://".$config{rewrite_default_url}.'/'.get_data_detail_url($dbh,\%sheet);
 
 my ($name,$descr) = ();
 
 if ($f_name{field_type} eq "textarea_id" ||
     $f_name{field_type} eq "textarea_id_editor" ||
     $f_name{field_type} eq "text_id") {
     
        ($name,$dummy) = get_textcontent($dbh,$sheet{"f".$f_name{ordby}});
     } else {
         $name = $sheet{"f".$f_name{ordby}}; 
     }

 if ($f_descr{field_type} eq "textarea_id" ||
     $f_descr{field_type} eq "textarea_id_editor" ||
     $f_descr{field_type} eq "text_id") {
     
        ($descr,$dummy) = get_textcontent($dbh,$sheet{"f".$f_descr{ordby}});
     } else {
         $descr = $sheet{"f".$f_descr{ordby}}; 
     }
 
   
 my $display = <<"EOH";

<form action="$dm_cfg{self}" method="post">
<input type="hidden" name="sw" value="publish_data_sheet_fb" />
<table>
<tr><td>Message :</td><td><textarea name="fb_message" id="fb_message" cols="50" rows="20">$descr</textarea></td></tr>
<tr><td>Lien (url) :</td><td><input type="text" name="fb_link" id="fb_link" value="$link" /></td></tr>
<tr><td>Titre du lien :</td><td><input type="text" name="fb_name" id="fb_name" value="$name" /></td></tr>
</table>
<button type="submit">Poster sur mon mur Facebook !</button>
</form>
EOH

 $migc_output{content} = $display;
}

sub publish_data_sheet_fb
{
 

 my $fb_name = get_quoted('fb_name');
 $fb_name = s/\\//g;
 my $fb_link = get_quoted('fb_link');
 my $fb_message = get_quoted('fb_message');
 $fb_message = s/\\//g;
 
 fb_wall_post($fb_link,$fb_name,$fb_message);
 
 
 
 see();
 http_redirect("$dm_cfg{self}&sw=publish_data_sheet_ok"); 
}

sub publish_data_sheet_ok
{
 
 my $display = <<"EOH";

<h1>Commentaire posté sur Facebook !</h1>
EOH

 $migc_output{content} = $display;
  
}
