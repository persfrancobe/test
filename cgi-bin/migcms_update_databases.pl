#!/usr/bin/perl -I../lib 
# -d:NYTProf


# CPAN modules
use CGI::Carp 'fatalsToBrowser';
use CGI;              # standard package for easy CGI scripting
use DBI;              # standard package for Database access

use def;              # home-made package for defines
use tools;            # home-made package for tools
use dm;

          # migc layout library

           # framework translations
         # migc translations
use migcrender;
use IO::Handle;
          # migc adm engine
use sitetxt;          # website trads
use IO::Handle;
use data;
use HTML::Entities;
use fwlib;
# use Devel::NYTProf;





    use Data::Dumper;
    
#     $use_global_textcontents=0;
#     $use_global_templates=0;
    $config{viewer} = "html";
    
    $self = "$config{baseurl}/cgi-bin/build_ajax.pl?";
    my $self_build = "$config{baseurl}/cgi-bin/build.pl?";
 
    my $sw = get_quoted('sw') || "build";
    
$token = init_build_tokens();

    $gen_bar = '';
    $spec_bar = '';

    my $content = &$sw();
    if ($sw eq "build" || $sw eq "ok") 
    {
        dm_init();
        $gen_bar = get_gen_buttonbar();
        $spec_bar = get_spec_buttonbar($sw);
        
        if ($sw eq "ok") {
            $dm_output{content} = <<"END_OF_HTML";
<div class="mig_add_update_form" style="width:350px;margin:20px auto auto auto;">

			<fieldset class="mig_fieldset2">
				<h2 class="mig_legend">$fwtrad{build_title}</h2>
				<div class="mig_add_update_form_content" style="text-align:center;">$fwtrad{build_text_end1}.<br /><br /><a href=\"$config{baseurl}/pages\" target=\"_blank\">$fwtrad{build_text_end2}</a></div>
			</fieldset>
			


      
      
</div>

<style type="text/css">
#mig_content_navigation { display:none;}
</style>

END_OF_HTML
        
        }
        
        $migc_output{content} .= $dm_output{content};
        $migc_output{title} = $dm_output{title}.$migc_output{title};
        see();
        print migc_app_layout($content,'',"",$gen_bar,$spec_bar);     
    }




sub build
{
    my $choix = '<br /><label><input type="checkbox" value="y" checked="checked" id="tous"> Tous</label><br />';
    my @steps = ('build_xml','build_urls','build_missing_urls','build_recherches','build_new','build_promo','build_pics','build_sheets','build_pages','build_index');
    my @steps_display = ('Générer le sitemap XML','Générer le HTACCESS','Vérifier et compléter les règles de réécriture des URLs manquantes',' Optimiser les recherches multilingues','Calculer les nouveautés','Calculer les remises',"Optimiser les images",'Publier les tuiles multicontenus','Publier les pages du site','Initialisation des index pour le navigateur');
    my $i = 0;
    foreach $step (@steps)
    {
        if($config{'disable_'.$step} ne 'y')
        {
            $choix .=<<"EOH";  
           <br /><label><input type="checkbox" class="select_step" value="y" checked="checked" id="$step"> $steps_display[$i]</label> 
EOH
        }
        else
        {
            $choix .=<<"EOH";  
           <br /><label><input type="checkbox" disabled="disabled" value="y" id="disabled_$step" /> $steps_display[$i]</label> 
EOH
        }
        $i++;
    }

    return <<"END_OF_HTML";
  
  <style>
	.ui-progressbar .ui-progressbar-value { background-image: url(mig_skin/images/pbar-ani.gif); }
	</style>  
  <script type="text/javascript">

        jQuery(document).ready(function()
        {
            jQuery( "#progressbar" ).progressbar(
            {
        			value: 0
        		});
            
            jQuery('#tous').click(function()
            {
               var tous_checked = jQuery(this).attr('checked');
               if(tous_checked != 'checked')  { jQuery('.select_step').attr('checked',false); } else { jQuery('.select_step').attr('checked',true); }
            });
            
            set_bar('Début du processus de génération MIGC',0);
            var cont = true;
            jQuery("#build_start_form").submit(function()
            {
                  build_start(cont);
                  return false;
            });
        });
        
        function build_start(cont)
         {
             
             if(jQuery('#build_xml').attr('checked')) {    cont = ajax_exec('init_sitemap','Initialisation du Sitemap XML',2,cont); } else {  set_bar('',2);     }
             if(jQuery('#build_urls').attr('checked')) {    cont = ajax_exec('init_htaccess','Initialisation des régles de réécriture des URLs',2,cont); } else {  set_bar('',2);  }
             if(jQuery('#build_recherches').attr('checked')) {    cont = ajax_exec('fill_fulltext','Optimisation des recherches multilingues sur plusieurs termes',10,cont); } else {  set_bar('',5);  }
             if(jQuery('#build_recherches').attr('checked')) {    cont = ajax_exec('fill_search_content','Optimisation des recherches multilingues',10,cont); } else {  set_bar('',5);  }
             
             if(jQuery('#build_new').attr('checked')) {    cont = ajax_exec('data_apply_new','Recherche et création des nouveautés',8,cont); } else {  set_bar('',8);  }

             if(jQuery('#build_promo').attr('checked')) {    cont = ajax_exec('fill_prices_in_data_sheets','Actualiser les prix',5,cont); } else {  set_bar('',5);  }
             if(jQuery('#build_promo').attr('checked')) {    cont = ajax_exec('data_compute_discounts','Recherche et création des remises',5,cont); } else {  set_bar('',5);  }
            
             if(jQuery('#build_missing_urls').attr('checked')) {    cont = ajax_exec('fill_data_lexique','Préparation et complétion du lexique des URLS',2,cont); } else {  set_bar('',1);  }
             if(jQuery('#build_missing_urls').attr('checked')) {    cont = ajax_exec('fill_url_rewriting_holes','Préparation et complétion automatique des URLs réécrites',2,cont); } else {  set_bar('',1);  }
             
             if(jQuery('#build_pics').attr('checked')) {    cont = ajax_exec('data_pics_generation','Optimiser les images',5,cont); } else {  set_bar('',5);  }
             if(jQuery('#build_sheets').attr('checked')) {    cont = ajax_exec('data_sheet_generation','Initialisation des tuiles multicontenu',5,cont); } else {  set_bar('',10);  }
             
             if(jQuery('#build_pages').attr('checked')) {    cont = ajax_exec('pages_cleanup','Suppression des anciennes pages',2,cont); } else {  set_bar('',2);  }
             if(jQuery('#build_pages').attr('checked')) {    cont = ajax_exec('pages_generation','Génération des nouvelles pages',10,cont); } else {  set_bar('',5);  }
             if(jQuery('#build_pages').attr('checked')) {    cont = ajax_exec('css_generation','Création de la feuille de styles CSS',5,cont); } else {  set_bar('',5);  }
             if(jQuery('#build_xml').attr('checked')) {    cont = ajax_exec('data_sitemap','Incrémentation du sitemap XML avec les données calculées',10,cont); } else {  set_bar('',10);  }
             if(jQuery('#build_urls').attr('checked')) {    cont = ajax_exec('data_htaccess','Incrémentation des règles de réécriture des URLs avec les données calculées',8,cont); } else {  set_bar('',10);  }
             if(jQuery('#build_index').attr('checked')) {    cont = ajax_exec('site_index','Initialisation des index pour le navigateur',10,cont); } else {  set_bar('',8);  }
             if(jQuery('#build_xml').attr('checked')) {    cont = ajax_exec('end_sitemap','Finalisation du Sitemap XML',2,cont); } else {  set_bar('',2);  }
             if(jQuery('#build_urls').attr('checked')) {    cont = ajax_exec('end_htaccess','Finalisation des régles de réécriture des URLs',2,cont); } else {  set_bar('',2);  }

             if (cont) {window.location = '$self_build'+'sw=ok';}
         }
        
        
        function ajax_exec(func,txt,pourc,cont)
        {
          //alert("ajax_exec: func:"+func+" txt:"+txt+" cont:"+cont);
         var rc = 0;

         if (cont) 
         {

             set_bar(txt,pourc);
             
             jQuery.ajax(
                 {
                  type: "POST",
                  url: "cgi-bin/build_ajax.pl",
                  data: "token=$token&sw="+func,
                  async: false,
                  error: function(jqXHR,textStatus,errorThrown) 
                  {
                          jQuery( "#step_title" ).html('Erreur: '+txt);
                          jQuery( "#log" ).html(textStatus+':'+errorThrown);
                          rc = 0;
                       
                  }, 
                  success: function(msg) 
                  {
             
                      if (msg != "OK") {
                          jQuery( "#step_title" ).html('Erreur: '+txt); 
                          jQuery( "#log" ).html(msg);
                          rc = 0;
                      }
                      else
                      {
                          rc = 1;
                      }
                       
                  }
                });      
         } 
         
         return rc;
        }
        
         
         
         
        function set_bar(texte,progression)
        {
         var pourcent = parseInt(progression);
         var pourcent_orig = jQuery( "#progressbar" ).progressbar( "option", "value");
         pourcent += pourcent_orig;
         jQuery( "#step_title" ).html(texte); 
         jQuery( "#step" ).html( pourcent+'%');
         jQuery( "#progressbar" ).progressbar( "option", "value", pourcent );
         return true;
        }
  </script>
    
  <form id="build_start_form" method="post" action="#">     
$choix
  <br /><table id="mig_button_content">
				<tbody><tr>
				<td><button class="mig_button" type="submit">Commencer la publication</button></td></tr>
			</tbody></table>   <br /><br />
</form>
  
  
  <div id="step"></div> 
  <div id="step_title"></div>
  <div id="progressbar"></div>
  <div id="log" style="width:90; height:90%; background-color:#dddddd; border: 1px solid #cccccc; margin:10px; padding:10px;"></div>  
    

END_OF_HTML
}



sub fill_data_lexique
{ 
 my @lglist = get_languages_ids($dbh);
 my $i = 0;
 my $lg = $config{default_colg};
 
    see();
    
    $stmt = " TRUNCATE TABLE data_lexique";
    $cursor = $dbh->prepare($stmt);
    $cursor->execute || suicide($stmt);
    
    
    if($config{lexique} eq 'y')
    {
        my @searchs=get_table($dbh,"data_search_forms","","","","","",0);
        foreach my $search (@searchs)
        {
            my %search=%{$search};
            
            my @fields=get_table($dbh,"data_searchs","","id_data_search_form='$search{id}' order by ordby","","","",0);
            foreach my $field (@fields)
            {
                my %field=%{$field};
                
                $stmt = " delete FROM data_lexique WHERE sf = $search{id} AND ordby= $field{ordby}";
                $cursor = $dbh->prepare($stmt);
                $cursor->execute || suicide($stmt);
                
                my ($field_type,$infos)= split(/\:/,$field{targets});
                my ($field,$id_data_family,$valeur_forcee)= split(/\_/,$infos);
                
                
#                print "\n<BR />[$field_type][$field][$id_data_family]";
                
                if($field_type eq 'id_father_cat' || $field_type eq 'id_father_cat_custom_ordby')
                {
                     if($field ne "")
                     {
                         my @data_categories = get_table($dbh,"data_categories","");
                         foreach my $data_categorie (@data_categories)
                         {
                          for ($i = 0; $i <= $#lglist; $i ++) {
                              $config{current_language} = $lglist[$i];
                              %sitetxt = %{get_sitetxt($dbh,$config{current_language})};
                          
                              my ($txt,$empty) = get_textcontent($dbh,$data_categorie->{id_textid_url_rewriting},$config{current_language});

                                  if($txt ne '')
                                  {
                                      my $value = trim($txt);
                                      my $value_mill = data_url_mill($value,'no_uri_escape');
                                      $value =~ s/\'/\\\'/g;
                                      my %new = 
                                      (
                                        sf=>$search{id},
                                        ordby=>$field{ordby},
                                        lg=>$lg,
                                        value=>$data_categorie->{id},
                                        value_mill=>$value_mill
                                      );
                                     inserth_db($dbh,"data_lexique",\%new);
                                 }
                            }
                         } 
                     }
                }
                elsif($field_type eq 'txt')
                {
                     if($valeur_forcee ne "")
                     {
                          my $value = trim($valeur_forcee);
                          $value =~ s/\'//g;
                          my $value_mill = data_url_mill($value);
                          my %new = 
                          (
                             sf=>$search{id},
                             ordby=>$field{ordby},
                             lg=>$lg,
                             value=>$value,
                             value_mill=>$value_mill
                          );
                          inserth_db($dbh,"data_lexique",\%new); 
                     }
                }
                elsif($field_type eq 'col')
                {
                    
                    my $ordby_field = $field;
                    $ordby_field =~ s/^F//g;
                    $ordby_field =~ s/^f//g;
                    my %field_rec=select_table($dbh,"data_fields","","id_data_family='$id_data_family' AND ordby = '$ordby_field'");
                     
                    if($field eq 'discountyes' || $field eq 'discountproyes' || $field_rec{field_type} eq "text" || $field_rec{field_type} eq "checkbox" || $field_rec{field_type} eq "textarea_editor" || $field_rec{field_type} eq "textarea")
                    {
                            if($field ne "")
                             {
                                 my @array = ();
                                 my $count = 0;
                                 if($field eq 'discountyes') { $field = 'discount_yes'; }
                                 if($field eq 'discountproyes') { $field = 'discount_pro_yes'; }
         
             #                      
                                 my @data_sheets = get_table($dbh,"data_sheets","distinct($field) ","visible='y' AND id_data_family = '$id_data_family' ",'','','',0);
                                 foreach $data_sheet (@data_sheets)
                                 {
                                      my %data_sheet = %{$data_sheet};
                                      if($data_sheet{$field} ne '')
                                      {
                                          my $value = trim($data_sheet{$field});
                                          my $value_mill = data_url_mill($value,'no_uri_escape');
                                          $value =~ s/\'/\\\'/g;
                                          my %new = 
                                          (
                                             sf=>$search{id},
                                             ordby=>$field{ordby},
                                             lg=>$lg,
                                             value=>$value,
                                             value_mill=>$value_mill
                                          );
                                          inserth_db($dbh,"data_lexique",\%new);
                                      }
                                 } 
                             }
                    }
                    elsif($field_rec{field_type} eq "text_id" || $field_rec{field_type} eq "textarea_id" || $field_rec{field_type} eq "textarea_id_editor")
                    {
                             if($field ne "")
                             {
                                 my @array = ();
                                 my $count = 0;
                
                                 my @data_sheets = get_table($dbh,"data_sheets ds, textcontents txt","distinct(content)","txt.id_textid = $field AND txt.id_language = 1 AND ds.visible='y' AND ds.id_data_family = '$id_data_family' ",'','','',0);
                                 foreach $data_sheet (@data_sheets)
                                 {
                                      my %data_sheet = %{$data_sheet};
                                      
                                      if($field_rec{field_type} eq "textarea_id_editor")
                                      {
                                          $data_sheet{content} =~ s/usr\/\//usr\//g;
                                          $data_sheet{content} =~ s/$htaccess_protocol_rewrite:\/\/usr/usr/g;
                                      }
             
                                      
                                      if($data_sheet{content} ne '')
                                      {
                                          my $value = trim($data_sheet{content});
                                          my $value_mill = data_url_mill($value,'no_uri_escape');
                                          $value =~ s/\'/\\\'/g;
                                          my %new = 
                                          (
                                             sf=>$search{id},
                                             ordby=>$field{ordby},
                                             lg=>$lg,
                                             value=>$value,
                                             value_mill=>$value_mill
                                          );
                                          inserth_db($dbh,"data_lexique",\%new);
                                      }
                                 } 
                             }
                    }
                    elsif($field{field_type} eq "listbox")
                    {

                    }
                     
                     
                     
                     
                }
                elsif($field_type eq 'fieldvalues')
                {
                     if($field ne "")
                     {
                         my @array = ();
                         my $count = 0;

                         my $field_ordby = $field;
                         $field_ordby =~ s/^f//g;

                         my %f = select_table($dbh,"data_fields","","ordby=$field_ordby and id_data_family = $id_data_family");
                         
                         for ($i = 0; $i <= $#lglist; $i ++) {
                              $config{current_language} = $lglist[$i];
                              %sitetxt = %{get_sitetxt($dbh,$config{current_language})};
                          
                              my @field_values_array = get_table($dbh,"data_field_listvalues c,textcontents txt","c.id as lv_id, txt.content AS txt_content","id_data_field = '$f{id}' AND txt.id_textid = c.id_textid_name and id_language = $config{current_language}",'','','',0);

                              foreach my $data_flv (@field_values_array)
                              {
                                  if($data_flv->{txt_content} ne '')
                                  {
                                      my $value = trim($data_flv->{txt_content});
                                      my $value_mill = data_url_mill($value,'no_uri_escape');
                                      $value =~ s/\'/\\\'/g;
                                      my %new = 
                                      (
                                        sf=>$search{id},
                                        ordby=>$field{ordby},
                                        lg=>$lg,
                                        value=>$data_flv->{lv_id},
                                        value_mill=>$value_mill
                                      );
                                     inserth_db($dbh,"data_lexique",\%new);
                                 }
                            }
                         } 
                     }
                }
                elsif($field_type eq 'crit')
                {
                     if($field ne "")
                     {
                     
                      for ($i = 0; $i <= $#lglist; $i ++) {
                              $config{current_language} = $lglist[$i];
                              %sitetxt = %{get_sitetxt($dbh,$config{current_language})};
                     
                         my @crit_values_array = get_table($dbh,"data_crit_listvalues c,textcontents txt","content","id_data_crit = '$field' AND txt.id_textid = c.id_textid_name and id_language = $lg",'','','',0);
                         foreach $crit_value_ref (@crit_values_array)
                         {
                              my %crit_value = %{$crit_value_ref};
                              if($crit_value{content} ne '')
                              {
                                  my $value = trim($crit_value{content});
                                  $value =~ s/\'//g;
                                  my $value_mill = data_url_mill($value);
                                  my %new = 
                                  (
                                     sf=>$search{id},
                                     ordby=>$field{ordby},
                                     lg=>$lg,
                                     value=>$value,
                                     value_mill=>$value_mill
                                  );
                                  inserth_db($dbh,"data_lexique",\%new);
                              }
                         } 
                     }
                     
                    } 
                }
           }
        }
    }
    print 'OK';
    exit;
}


sub init_sitemap
{

   see();
 reset_sitemap();

     my $xmlsitemap_header = <<"EOX";
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
EOX

    write_sitemap($xmlsitemap_header);

   print "OK";
 exit;  
}

sub end_sitemap
{
   see();
 my $xmlsitemap_footer = "\n</urlset>";
 write_sitemap($xmlsitemap_footer);
 
 publish_sitemap();
   print "OK";
 exit;  
}
   	 



sub pages_generation
{
 migcrender::pages_generation();
 
}



sub publish_sitemap
{
 `rm -f $config{sitemap_ok}`;
 `mv $config{sitemap_tmp} $config{sitemap_ok}`;  
}





sub reset_sitemap
{
 my $xmlsitemap = $config{sitemap_tmp};

 reset_file($xmlsitemap);
}


sub data_sitemap
{
 see();

$use_global_textcontents=0;
$use_global_templates=0;
$config{viewer} = "html";

 my %data_cfg = get_hash_from_config($dbh,'data_cfg');

 my $xmlsitemap_content = "";
 if($data_cfg{add_data_to_sitemap} eq 'y') 
 {
 
    my @lglist = get_languages_ids($dbh);
 
    foreach my $lg (@lglist) 
    {
#         print "<br />BEGIN SITEMAP $lg";
        $xmlsitemap_content .= data_get_sitemap($dbh,$lg);    
    }
 } 
 
 write_sitemap($xmlsitemap_content);
 
   print "OK";
 exit;  
} 



sub css_generation
{
 see();
# $use_global_textcontents=0;
# $use_global_templates=0;
$config{viewer} = "html";

 my $todel = $config{pages_dir}."/*.css";
 `rm -f $todel`;

 my %list_css = ();
 my @list_templates = get_table($dbh,"pages","distinct id_template");
 foreach my $tp (@list_templates) {
   my ($tpl,$id_css) = get_template_and_css($dbh,$tp->{id_template});
     if ($id_css ne "") {
         $list_css{$id_css}++;
     }
 }
 

 foreach my $id_css (keys %list_css) {

     my %css = select_table($dbh,"css","css","id=$id_css");     
     my $out_name = $config{pages_dir}."/".$id_css.".css";
     reset_file($out_name);
     write_file($out_name,$css{css});
     

 }
   print "OK";
 exit;  
}



sub site_index
{
 see();
# $use_global_textcontents=0;
# $use_global_templates=0;
$config{viewer} = "html";
 if ($config{file_ext} eq "") {
     $config{file_ext} = "html";
 }
my $index_redirect = get_obj_url($dbh,get_first_page_id($dbh),$config{viewer},"pages",1);

 my $indexfile = $config{pages_dir}."/index.$config{file_ext}";
  my $index_pre = "../";
  my $content = "<meta http-equiv=\"Refresh\" content=\"0; URL=$index_pre$index_redirect\">"; 

 reset_file($indexfile);
 write_file($indexfile,$content);
   print "OK";
 exit;  
}

 
 
sub fill_fulltext
{
      my $lg = 1;
      see();
      my @data_sheets = get_table($dbh,"data_sheets","","visible='y' ");
      my @data_searchs = get_table($dbh,"data_searchs","targets","targets LIKE 'fulltext:%' AND visible='y'");
      foreach $data_sheet (@data_sheets)
      {
          my %data_sheet = %{$data_sheet};
          my $fulltext = '';
          
          #ON CONSTRUIT LA VARIABLE FULL TXT QUI REPREND TOUS LES TEXTES CHERCHABLES. Les champs différent selon les familles ex: 1_f2,f3 = f2f3 de famille 1
          
          foreach $data_search (@data_searchs)
          {
              my %data_search = %{$data_search};
              my ($field_type_family,$liste_des_f)= split(/\_/,$data_search{targets});
              my ($field_type,$id_data_family)= split(/\:/,$field_type_family);
              if($field_type eq 'fulltext' && $id_data_family > 0 && $id_data_family == $data_sheet{id_data_family})
              {
                    my @fields = split(/\,/,$liste_des_f);
                    foreach my $field (@fields)
                    {
                        my $ordby_field = $field;
                        $ordby_field =~ s/^F//g;
                        $ordby_field =~ s/^f//g;
                        my %field_rec=select_table($dbh,"data_fields","","id_data_family='$id_data_family' AND ordby = '$ordby_field'");
                        if($field_rec{field_type} eq "text" || $field_rec{field_type} eq "checkbox" || $field_rec{field_type} eq "textarea_editor" || $field_rec{field_type} eq "textarea")
                        {
                            my $name = $data_sheet{$field};
                            $name =~ s/\'/\\\'/g;
                            
                            $name =~ s/(^ *)||( *$)//g;
                  					$name =~ s/<br \/>/\n/g;
                  					$name =~ s/<[^>]*>//g;
                  					$name =~ s/\r*\n/\n/g;
                  					$name =~ s/(^\n*)||(\n*$)//g;
                            
                            $name = decode_entities($name);
                            
                            $fulltext .= " ".$name;
                        }
                        elsif($field_rec{field_type} eq "text_id" || $field_rec{field_type} eq "textarea_id" || $field_rec{field_type} eq "textarea_id_editor")
                        {
                            my ($name,$dum) = get_textcontent($dbh,$data_sheet{$field},$lg);
                            $name =~ s/\'/\\\'/g;
                            
                            $name =~ s/(^ *)||( *$)//g;
                  					$name =~ s/<br \/>/\n/g;
                  					$name =~ s/<[^>]*>//g;
                  					$name =~ s/\r*\n/\n/g;
                  					$name =~ s/(^\n*)||(\n*$)//g;
                            
                            $name = decode_entities($name);
                            
                            $fulltext .= " ".$name;
                        }
                        elsif($field{field_type} eq "listbox")
                        {
                            #A COMPLETER
                        }
                    }           
              }
          }
          
          if($data_sheet{id_textid_fulltext} > 0)
          {
              update_text($dbh,$data_sheet{id_textid_fulltext},$fulltext,$lg);
          }
          else
          {
              my $id_textid_fulltext = insert_text($dbh,$fulltext,$lg);
              my $stmt = "UPDATE data_sheets SET id_textid_fulltext = '$id_textid_fulltext' WHERE id = $data_sheet{id}";
              my $cursor = $dbh->prepare($stmt);
              $cursor->execute || suicide($stmt);
          }
      }
      print "OK";
      exit;
}
 
sub fill_search_content 
{
 see();
#$use_global_textcontents=0;
# $use_global_templates=0;
$config{viewer} = "html";

 #FILL SEARCH CONTENT---------------------------------------------------------
 my @textcontents=get_table($dbh,"textcontents","*");
 my $i = 0;
 for ($i ; $i<$#textcontents ; $i++)  {
      my $content = $textcontents[$i]{content};
      my $search_content = $content;
     
      $search_content =~ s/&rsquo;/'/g;
      $search_content =~ s/&ugrave;/u/g;
      $search_content =~ s/&oelig;/oe/g;
     
      $search_content = decode_entities($search_content);
      $search_content = remove_accents_from($search_content);
     
      if ($textcontents[$i]{id} > 0 && $search_content ne "") {
          $search_content =~ s/\'/\\\'/g;         
          my $stmt = "UPDATE textcontents SET search_content = '$search_content' WHERE id = $textcontents[$i]{id}";
          my $cursor = $dbh->prepare($stmt);
          $cursor->execute || suicide($stmt);
      }
 }
   print "OK";
 exit;  
}







