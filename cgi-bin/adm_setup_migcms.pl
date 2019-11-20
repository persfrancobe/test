#!/usr/bin/perl -I../lib

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Librairies utilisées
use CGI::Carp 'fatalsToBrowser';
use CGI;   # standard package for easy CGI scripting
use DBI;   # standard package for Database access
use def; # home-made package for defines
use tools; # home-made package for tools
use dm;
use setup;

my $htaccess_ssl = $config{rewrite_ssl};
my $htaccess_protocol_rewrite = "http";
if($htaccess_ssl eq 'y') {
  $htaccess_protocol_rewrite = "https";
}

$dm_cfg{customtitle}=<<"EOH";
EOH

$dm_cfg{trad} = 1;
$dm_cfg{enable_search} = 0;
$dm_cfg{vis_opt} = 0;
$dm_cfg{sort_opt} = 0;
$dm_cfg{wherel} = "";
$dm_cfg{wherep} = "";
$dm_cfg{table_name} = "migcms_setup";
$dm_cfg{list_table_name} = "migcms_setup";
$dm_cfg{self} = "$config{baseurl}/cgi-bin/adm_setup_migcms.pl?";

$dm_cfg{after_mod_ref} = \&after_save;
$dm_cfg{after_add_ref} = \&after_save;
$dm_cfg{after_ordby_ref} = '';
$dm_cfg{after_upload_ref} = \&after_upload;

$dm_cfg{hiddp}=<<"EOH";
EOH

$dm_cfg{file_prefixe} = 'SSI';

###############################################################################
# Config de la taille des images à uploader
################################################################################

%upload_config = (
  # Pour l'image du mail de remerciement
  mini_height => "331",  
  mini_width  =>  "272",
  # Pour le logo
  medium_height => "218",
  medium_width  => "218",
  # Pour les blocs publicitaire
  large_height => "700",
  large_width  => "700",

);


@dm_nav =
(
  {
    'tab'   =>'site',
    'type'  =>'tab',
    'title' =>'Site'
  }
	,
  {
    'tab'   =>'balises',
    'type'  =>'tab',
    'title' =>'Balises'
  }
  ,
  {
    'tab'   =>'seo',
    'type'  =>'tab',
    'title' =>'Référencement'
  }
  ,
  {
    'tab'   =>'email',
    'type'  =>'tab',
    'title' =>'Emails'
  }
  ,
);
$dm_cfg{default_tab} = 'site';


%dm_dfl = %{setup::get_setup_dm_dfl()};


%dm_display_fields = (
"01/Nom du framework"=>"site_name"
);

%dm_lnk_fields = (
		);

%dm_mapping_list = (
);

%dm_filters = (
		);


$sw = $cgi->param('sw') || "list";

see();

my @fcts = qw(
			add_form
			mod_form
			list
		);

if (is_in(@fcts,$sw)) 
{ 
    dm_init();
    &$sw();

    if($sw ne "dum")
    {
      $migc_output{content} .= $dm_output{content};
      $migc_output{title} = $dm_output{title}.$migc_output{title};
      print migc_app_layout($suppl_js.$dm_output{content},$dm_output{title},"",$gen_bar,$spec_bar);
    }
}

sub after_save
{
    my $dbh=$_[0];
    my $id =$_[1];
	
	# my %rec = read_table($dbh,'migcms_setup',$id);
}


sub after_upload
{
  my $dbh=$_[0];
  my $id=$_[1];
  my %parag = sql_line({table=>'parag',where=>"id='$id'"});
  my %template = sql_line({table=>'templates',where=>"id='$parag{id_template}'"});
  my %parag_setup = sql_line({table=>'parag_setup',where=>""});
  
  my @sizes = ('mini','small','medium','large','og');
  
  #boucle sur les images du paragraphes
  my @migcms_linked_files = sql_lines({debug=>1,debug_results=>1,table=>'migcms_linked_files',where=>"ext IN ('.jpg','.jpeg','.png') AND table_name='$dm_cfg{table_name}' AND table_field='id_pic_logo_email' AND token='$id'",ordby=>'ordby'});
  foreach $migcms_linked_file (@migcms_linked_files)
  {
      #appelle la fonction de redimensionnement
      my %migcms_linked_file = %{$migcms_linked_file};
      my $file_url = $migcms_linked_file{file_dir}.'/'.$migcms_linked_file{full}.$migcms_linked_file{ext};
      my %params = (
          migcms_linked_file=>\%migcms_linked_file,
          do_not_resize=>$parag{do_not_resize}
      );
      foreach my $size (@sizes)
      {
          $params{'size_'.$size} = $upload_config{$size."_width"};
      }
      dm::resize_pic(\%params);
  }   
}